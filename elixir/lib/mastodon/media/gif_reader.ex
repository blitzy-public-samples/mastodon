defmodule Mastodon.Media.GifReader do
  @moduledoc """
  Answers one question about a GIF file: is it animated?

  The answer changes what an upload becomes. Mastodon transcodes an animated GIF to MP4 and stores
  it with type `gifv` and content type `video/mp4`. A static GIF stays type `image` with content
  type `image/gif`. Nothing else makes that decision, so a wrong answer here reaches the client.

  Counting frames is enough, and two frames settle it. `max_frames` defaults to 2, so the parse
  stops at the second frame instead of walking the whole file. On the 85_810 byte `avatar.gif`
  fixture it ends after 16_732 bytes.

  The reader skips over pixel data rather than decoding it. It reads the 6 byte signature, the 7
  byte logical screen descriptor, the colour tables, and the one byte separator that introduces
  each block. Everything else is a seek.

  Ported from:

    * `lib/paperclip/gif_transcoder.rb` lines 1-99 — the `GifReader` class: its `GIF_HEADERS` and
      `EXTENSION_LABELS` constants, the `animated?/1` class method that rescues to `false`, the
      constructor's `max_frames` loop, and the private `skip_extension_block!` and
      `skip_sub_blocks!` helpers.
    * `app/models/media_attachment.rb` lines 337-347 — `file_processors` routes `image/gif` to
      `[:gif_transcoder, :blurhash_transcoder]`, the only path that reaches this code.
    * `spec/models/media_attachment_spec.rb` lines 171-215 — `avatar.gif` becomes type `gifv` with
      content type `video/mp4`, while `attachment.gif` and `mini-static.gif` stay type `image` with
      content type `image/gif`.

  ## Usage

      if Mastodon.Media.GifReader.animated?(upload_path) do
        transcode_to_mp4(upload_path)
      end

  """

  import Bitwise

  # GIF_HEADERS, lib/paperclip/gif_transcoder.rb line 7. Both signatures are 6 bytes.
  @gif_headers ["GIF87a", "GIF89a"]

  # EXTENSION_LABELS, lib/paperclip/gif_transcoder.rb line 6: graphic control, plain text, and
  # application. These three carry a fixed-size block before their sub-blocks.
  @extension_labels [0xF9, 0x01, 0xFF]

  # The max_frames default of GifReader#initialize, lib/paperclip/gif_transcoder.rb line 21.
  @default_max_frames 2

  # Block separators, lib/paperclip/gif_transcoder.rb lines 47, 64, and 66.
  @image_separator ","
  @extension_separator "!"
  @trailer_separator ";"

  defstruct animated: false, frame_count: 0

  @typedoc """
  Result of a successful parse.

  `frame_count` is capped by the `max_frames` argument of `read/2`, so it reports the frames seen,
  not the frames the file holds. `animated` is `frame_count > 1`.
  """
  @type t :: %__MODULE__{animated: boolean(), frame_count: non_neg_integer()}

  @typedoc """
  Why a parse failed.

  The first three name the failures `lib/paperclip/gif_transcoder.rb` checks for. `:truncated` is the
  end of the file, which the Ruby never checks for. A file that cannot be opened yields the reason
  `:file.open/2` returned, such as `:enoent`.
  """
  @type error ::
          :unknown_image_type
          | :cannot_parse_image
          | :invalid_value
          | :truncated
          | File.posix()

  @doc """
  Returns `true` when the GIF at `path` holds more than one frame.

  Every failure returns `false`: a file that is not a GIF, a GIF this reader cannot parse, a file
  that ends mid-parse, and a file that cannot be opened. `GifReader.animated?` in
  `lib/paperclip/gif_transcoder.rb` lines 15-19 rescues its own exception family the same way.

  Two failures return `false` here where the Ruby raises. `read(1)` there returns `nil` at the end
  of the file, and `nil.unpack` raises `NoMethodError`, which the rescue does not cover. The
  `InvalidValue` constant raised at line 60 is never defined, so that raise is a `NameError`, which
  the rescue does not cover either.
  """
  @spec animated?(Path.t()) :: boolean()
  def animated?(path) do
    case read(path) do
      {:ok, %__MODULE__{animated: animated}} -> animated
      {:error, _reason} -> false
    end
  end

  @doc """
  Parses the GIF at `path` and reports how many frames it found.

  Stops once the frame count reaches `max_frames`. The block that carries the last counted frame is
  still skipped in full, matching the Ruby loop, which increments its counter before skipping and
  re-tests the condition afterwards.

  Failure reasons:

    * `:unknown_image_type` — the first 6 bytes are neither `"GIF87a"` nor `"GIF89a"`, or the file
      holds fewer than 6 bytes
    * `:cannot_parse_image` — a block separator is not `","`, `"!"`, or `";"`, or the file ended
      where a separator was due
    * `:invalid_value` — an image block declares an LZW minimum code size below 2
    * `:truncated` — the file ended inside a block, after a valid signature
    * a `File.posix/0` reason such as `:enoent` — the file could not be opened

  `:unknown_image_type` and `:cannot_parse_image` cover the same bytes as the exceptions of those
  names in `lib/paperclip/gif_transcoder.rb`, including the end-of-file cases. `:invalid_value` is
  the check at line 60 of that file. `:truncated` covers the reads where the Ruby raises rather than
  classifies.
  """
  @spec read(Path.t(), pos_integer()) :: {:ok, t()} | {:error, error()}
  def read(path, max_frames \\ @default_max_frames)
      when is_integer(max_frames) and max_frames > 0 do
    case :file.open(path, [:read, :binary, :read_ahead]) do
      {:ok, device} ->
        try do
          parse(device, max_frames)
        after
          :file.close(device)
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Header and logical screen descriptor, lib/paperclip/gif_transcoder.rb lines 26-40.
  defp parse(device, max_frames) do
    with {:ok, header} <- read_bytes(device, 6, :unknown_image_type),
         :ok <- verify_header(header),
         # Canvas width and canvas height, 2 bytes each.
         :ok <- skip(device, 4),
         {:ok, packed_byte} <- read_byte(device),
         # Background colour index, 1 byte, then pixel aspect ratio, 1 byte.
         :ok <- skip(device, 2),
         :ok <- skip_colour_table(device, packed_byte),
         {:ok, frame_count} <- read_blocks(device, max_frames, 0) do
      {:ok, %__MODULE__{animated: frame_count > 1, frame_count: frame_count}}
    end
  end

  defp verify_header(header) when header in @gif_headers, do: :ok
  defp verify_header(_header), do: {:error, :unknown_image_type}

  # The block loop, lib/paperclip/gif_transcoder.rb lines 43-71.
  defp read_blocks(_device, max_frames, frame_count) when frame_count >= max_frames do
    {:ok, frame_count}
  end

  defp read_blocks(device, max_frames, frame_count) do
    case read_bytes(device, 1, :cannot_parse_image) do
      {:ok, @image_separator} ->
        read_next_block(skip_image_block(device), device, max_frames, frame_count + 1)

      {:ok, @extension_separator} ->
        read_next_block(skip_extension_block(device), device, max_frames, frame_count)

      {:ok, @trailer_separator} ->
        {:ok, frame_count}

      {:ok, _separator} ->
        {:error, :cannot_parse_image}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Takes the result of skipping one block back into the loop. An extension block leaves the frame
  # count alone, so both callers pass the count they want the next pass to see.
  defp read_next_block(:ok, device, max_frames, frame_count) do
    read_blocks(device, max_frames, frame_count)
  end

  defp read_next_block({:error, reason}, _device, _max_frames, _frame_count) do
    {:error, reason}
  end

  # Image block, lib/paperclip/gif_transcoder.rb lines 48-63. The first skip covers the image
  # descriptor: left position, top position, width, and height, 2 bytes each.
  defp skip_image_block(device) do
    with :ok <- skip(device, 8),
         {:ok, packed_byte} <- read_byte(device),
         :ok <- skip_colour_table(device, packed_byte),
         {:ok, minimum_code_size} <- read_byte(device),
         :ok <- verify_minimum_code_size(minimum_code_size) do
      skip_sub_blocks(device)
    end
  end

  # LZW minimum code size, lib/paperclip/gif_transcoder.rb line 60.
  defp verify_minimum_code_size(minimum_code_size) when minimum_code_size >= 2, do: :ok
  defp verify_minimum_code_size(_minimum_code_size), do: {:error, :invalid_value}

  # skip_extension_block!, lib/paperclip/gif_transcoder.rb lines 79-87.
  defp skip_extension_block(device) do
    case read_byte(device) do
      {:ok, label} when label in @extension_labels ->
        with {:ok, block_size} <- read_byte(device),
             :ok <- skip(device, block_size) do
          skip_sub_blocks(device)
        end

      {:ok, _label} ->
        skip_sub_blocks(device)

      {:error, reason} ->
        {:error, reason}
    end
  end

  # skip_sub_blocks!, lib/paperclip/gif_transcoder.rb lines 90-98. Each sub-block starts with its
  # own size byte. A size of 0 is the block terminator.
  defp skip_sub_blocks(device) do
    case read_byte(device) do
      {:ok, 0} ->
        :ok

      {:ok, size} ->
        case skip(device, size) do
          :ok -> skip_sub_blocks(device)
          {:error, reason} -> {:error, reason}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Bit 0x80 of a packed byte is the colour table flag. Bits 0x07 hold the size exponent, and each
  # entry is 3 bytes: red, green, blue. Same arithmetic for the global table at
  # lib/paperclip/gif_transcoder.rb line 39 and the local table at line 56.
  defp skip_colour_table(device, packed_byte) do
    if (packed_byte &&& 0x80) != 0 do
      skip(device, 3 * (1 <<< ((packed_byte &&& 0x07) + 1)))
    else
      :ok
    end
  end

  # IO#seek(count, IO::SEEK_CUR) in the Ruby. Seeking past the end of the file is legal; the read
  # that follows reports the truncation.
  defp skip(device, count) do
    case :file.position(device, {:cur, count}) do
      {:ok, _position} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  # Every one byte read below is a site where the Ruby calls unpack on the result. At the end of the
  # file that result is nil, so the Ruby raises NoMethodError; here it is `:truncated`.
  defp read_byte(device) do
    case read_bytes(device, 1, :truncated) do
      {:ok, <<byte>>} -> {:ok, byte}
      {:error, reason} -> {:error, reason}
    end
  end

  # A read that spans the end of the file returns fewer bytes than asked for, so a short read ends
  # the parse the same way an empty read does. `eof_reason` names the outcome the Ruby reaches at
  # that point. A signature it cannot read is not a GIF. A separator it cannot read is nil, which
  # falls through its case to CannotParseImage.
  defp read_bytes(device, count, eof_reason) do
    case :file.read(device, count) do
      {:ok, data} when byte_size(data) == count -> {:ok, data}
      {:ok, _short_read} -> {:error, eof_reason}
      :eof -> {:error, eof_reason}
      {:error, reason} -> {:error, reason}
    end
  end
end
