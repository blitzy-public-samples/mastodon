defmodule Mastodon.Media.Geometry do
  @moduledoc """
  Image dimensions and the arithmetic the media styles do with them.

  A geometry is a width and a height in pixels. It optionally carries the
  Paperclip modifier that says how a target box is applied: `#` crops to the
  box, `>` only shrinks. Three jobs live here. Read the dimensions of a file
  that was just uploaded. Work out the dimensions of a style whose limit is a
  pixel count rather than a box. Tell a crop target from a shrink-only one,
  because only the crop path passes `crop: :centre` to libvips.

  The numbers are pinned. A 600x400 source under the `small` budget of 230_400
  pixels comes out as 588x392, with an aspect of exactly 1.5.
  `spec/models/media_attachment_spec.rb` asserts that pair for six image
  formats: JPEG, PNG, monochrome PNG, WebP, AVIF and HEIC. So `from_pixels/2`
  divides as floats and rounds half away from zero, which is what Ruby's
  `Float#round` does. Truncate instead of rounding and the same source gives
  587x391, and all six assertions fail.

  ## Ported from

    * `app/lib/fast_geometry_parser.rb` — reads the size from the file header,
      then raises `Paperclip::Errors::NotIdentifiedByImageMagickError` when the
      width comes back nil. `from_file/1` returns `{:error, :not_identified}`
      rather than raising. Callers must keep that error distinguishable.
      `app/models/concerns/remotable.rb` rescues that one exception class and
      nulls the attachment instead of failing. Fold it into a generic error and
      unreadable remote media stops behaving the way it does today.
    * `lib/paperclip/vips_lazy_thumbnail.rb` — its nested
      `PixelGeometryParser.parse/2` is `from_pixels/2`, its `@crop` flag is
      `crop?/1`, and its choice between a pixel budget and a geometry string
      stays with the caller.
    * `lib/paperclip/lazy_thumbnail.rb` — the same arithmetic in ImageMagick
      form, which writes the result back as the string `"WxH>"`. `parse/1`
      reads that form. Its `square?` call is `square?/1`.
    * `app/models/media_attachment.rb` — the style tables that pass
      `file_geometry_parser: FastGeometryParser`, and the budgets of 8_294_400
      pixels for `original` and 230_400 for `small`. `image_geometry/1` at
      L400-411 builds its `meta` map from a width, a height, `size/1` and
      `aspect/1`.
    * `app/models/concerns/attachmentable.rb` — `check_image_dimension/1`,
      which reads dimensions the same way before enforcing `MAX_MATRIX_LIMIT`
      of 33_177_600 pixels and `GIF_MATRIX_LIMIT` of 921_600. `pixels/1`
      returns the product those two limits are compared against.
    * `spec/models/media_attachment_spec.rb` — the pinned 588x392 and 1.5.

  ## What this module leaves to its callers

  It sets no libvips state. `VIPS_BLOCK_UNTRUSTED` and the loader allowlist in
  `config/initializers/vips.rb` are installed once by
  `Mastodon.Media.Thumbnail`. A blocked loader reaches `from_file/1` as a load
  failure and leaves it as `{:error, :not_identified}`.

  It decides nothing. `from_pixels/2` is arithmetic and does not ask whether
  the source is already inside the budget. `Mastodon.Media.Thumbnail` compares
  `pixels/1` against the budget and calls `from_pixels/2` only when the source
  is over it, which is how `needs_different_geometry?` reads today.

  Rationale for the migration choices behind this module is recorded in
  `docs/architecture/decision-log.md`.

  ## Examples

      iex> alias Mastodon.Media.Geometry
      iex> small = Geometry.from_pixels(Geometry.new(600, 400), 230_400)
      iex> {small.width, small.height, Geometry.aspect(small)}
      {588, 392, 1.5}

      iex> alias Mastodon.Media.Geometry
      iex> {:ok, avatar} = Geometry.parse("400x400#")
      iex> {Geometry.crop?(avatar), Geometry.square?(avatar)}
      {true, true}
  """

  alias Vix.Vips.Image, as: VipsImage

  @enforce_keys [:width, :height]

  # Paperclip's GeometryParser also accepts a half-written "600x", seven other
  # modifiers, and a trailing EXIF orientation. The media styles only ever build
  # "WxH", "WxH>" and "WxH#", so this pattern takes those three and nothing else.
  @geometry_format ~r/\A(?<width>\d+)x(?<height>\d+)(?<modifier>[#>])?\z/

  defstruct [:width, :height, modifier: nil]

  @typedoc """
  How a target box is applied. `:crop` is Paperclip's `#`, `:shrink_only` is
  its `>`, and `nil` is a box with no modifier.
  """
  @type modifier :: nil | :crop | :shrink_only

  @typedoc "A width and a height in pixels, both at least 1."
  @type t :: %__MODULE__{
          width: pos_integer(),
          height: pos_integer(),
          modifier: modifier()
        }

  @doc """
  Builds a geometry from a width, a height, and an optional modifier.

  Both dimensions must be positive integers. This is
  `Paperclip::Geometry.new/3` with the float coercion removed, since every
  dimension in the media styles is a whole number of pixels.

  ## Examples

      iex> Mastodon.Media.Geometry.new(640, 360).width
      640

      iex> Mastodon.Media.Geometry.new(400, 400, :crop).modifier
      :crop
  """
  @spec new(pos_integer(), pos_integer(), modifier()) :: t()
  def new(width, height, modifier \\ nil)
      when is_integer(width) and width > 0 and
             is_integer(height) and height > 0 and
             modifier in [nil, :crop, :shrink_only] do
    %__MODULE__{width: width, height: height, modifier: modifier}
  end

  @doc """
  Reads the dimensions of an image file from its header.

  libvips loads the header and leaves the pixels alone, so the cost does not
  grow with the size of the image. `FastImage.size/1` does the same for the Ruby
  parser.

  A multi-page image reports the dimensions of its first page. An animated GIF
  of 10 frames at 128x128 therefore reads as 128x128, which is the number
  `spec/models/media_attachment_spec.rb` expects for `avatar.gif`.

  Returns `{:error, :not_identified}` for anything libvips will not open: a
  file that is not an image, a truncated image, a missing path, a directory, or
  a loader the allowlist blocks. That one error atom stands in for
  `Paperclip::Errors::NotIdentifiedByImageMagickError`, which
  `app/models/concerns/remotable.rb` rescues on its own to null an attachment.
  Callers that need that behaviour must match on it rather than on a catch-all.
  """
  @spec from_file(Path.t()) :: {:ok, t()} | {:error, :not_identified}
  def from_file(path) when is_binary(path) do
    case read_header(path) do
      {:ok, width, height}
      when is_integer(width) and width > 0 and
             is_integer(height) and height > 0 ->
        {:ok, %__MODULE__{width: width, height: height}}

      _other ->
        {:error, :not_identified}
    end
  end

  # libvips reports load failures as error tuples. Anything the NIF raises is
  # mapped to the same result, so from_file/1 never raises.
  defp read_header(path) do
    case VipsImage.new_from_file(path, []) do
      {:ok, image} -> {:ok, VipsImage.width(image), VipsImage.height(image)}
      {:error, reason} -> {:error, reason}
    end
  rescue
    _exception -> {:error, :not_identified}
  end

  @doc """
  Parses a Paperclip geometry string.

  Three forms are accepted, and they are the three the media styles build:

    * `"640x360"` — a target box with no modifier.
    * `"640x360>"` — shrink only. `lib/paperclip/lazy_thumbnail.rb` builds this
      form after solving a pixel budget.
    * `"400x400#"` — crop to the box. Avatars and site uploads use it.

  Both dimensions are required and both must be positive. Paperclip's regular
  expression is looser. It reads `"600x"` as a width with a height of zero, and
  it accepts seven further modifiers and a trailing EXIF orientation such as
  `"600x400,6"`. No media style builds any of those, so they return
  `{:error, :unparsable}` here rather than a zero-sized target.

  ## Examples

      iex> {:ok, geometry} = Mastodon.Media.Geometry.parse("640x360>")
      iex> {geometry.width, geometry.height, geometry.modifier}
      {640, 360, :shrink_only}

      iex> Mastodon.Media.Geometry.parse("600x")
      {:error, :unparsable}
  """
  @spec parse(String.t()) :: {:ok, t()} | {:error, :unparsable}
  def parse(geometry) when is_binary(geometry) do
    case Regex.named_captures(@geometry_format, geometry) do
      %{"width" => width, "height" => height, "modifier" => modifier} ->
        build(String.to_integer(width), String.to_integer(height), modifier)

      nil ->
        {:error, :unparsable}
    end
  end

  @doc """
  Parses a Paperclip geometry string, or raises `ArgumentError`.

  Use this for the geometry strings written into the style tables, where an
  unparsable value is a mistake in the source rather than user input.

  ## Examples

      iex> Mastodon.Media.Geometry.parse!("1200x630#").height
      630
  """
  @spec parse!(String.t()) :: t()
  def parse!(geometry) do
    case parse(geometry) do
      {:ok, parsed} ->
        parsed

      {:error, :unparsable} ->
        raise ArgumentError, "unparsable geometry: #{inspect(geometry)}"
    end
  end

  defp build(width, height, modifier) when width > 0 and height > 0 do
    {:ok, %__MODULE__{width: width, height: height, modifier: decode_modifier(modifier)}}
  end

  defp build(_width, _height, _modifier), do: {:error, :unparsable}

  defp decode_modifier("#"), do: :crop
  defp decode_modifier(">"), do: :shrink_only
  defp decode_modifier(""), do: nil

  @doc """
  Is this a crop target?

  The string clause is `options[:geometry].to_s[-1, 1] == '#'` from
  `lib/paperclip/vips_lazy_thumbnail.rb`, which reads the raw style option
  before any parsing. `nil` is false, matching `nil.to_s` there. Only a crop
  target passes `crop: :centre` to libvips; everything else passes
  `size: :down`.

  ## Examples

      iex> Mastodon.Media.Geometry.crop?("400x400#")
      true

      iex> Mastodon.Media.Geometry.crop?(Mastodon.Media.Geometry.new(400, 400))
      false

      iex> Mastodon.Media.Geometry.crop?(nil)
      false
  """
  @spec crop?(t() | String.t() | nil) :: boolean()
  def crop?(%__MODULE__{modifier: modifier}), do: modifier == :crop
  def crop?(geometry) when is_binary(geometry), do: String.ends_with?(geometry, "#")
  def crop?(nil), do: false

  @doc """
  Is this a shrink-only target?

  A shrink-only target never enlarges a source that is already smaller than the
  box. `lib/paperclip/lazy_thumbnail.rb` writes the `>` that says so. The
  libvips processor spells the same thing `size: :down`.

  ## Examples

      iex> Mastodon.Media.Geometry.shrink_only?("640x360>")
      true

      iex> Mastodon.Media.Geometry.shrink_only?("400x400#")
      false
  """
  @spec shrink_only?(t() | String.t() | nil) :: boolean()
  def shrink_only?(%__MODULE__{modifier: modifier}), do: modifier == :shrink_only
  def shrink_only?(geometry) when is_binary(geometry), do: String.ends_with?(geometry, ">")
  def shrink_only?(nil), do: false

  @doc """
  Are the width and the height equal?

  `lib/paperclip/lazy_thumbnail.rb` asks this about the target before cropping
  an avatar to the shorter side of its source.

  ## Examples

      iex> Mastodon.Media.Geometry.square?(Mastodon.Media.Geometry.new(100, 100))
      true

      iex> Mastodon.Media.Geometry.square?(Mastodon.Media.Geometry.new(100, 101))
      false
  """
  @spec square?(t()) :: boolean()
  def square?(%__MODULE__{width: width, height: height}), do: width == height

  @doc """
  The number of pixels in the image: width times height.

  This is the product the budgets are compared against. 8_294_400 for the
  `original` image style, 230_400 for `small`, 750_000 for an account header,
  33_177_600 for `MAX_MATRIX_LIMIT` and 921_600 for `GIF_MATRIX_LIMIT`.

  ## Examples

      iex> Mastodon.Media.Geometry.pixels(Mastodon.Media.Geometry.new(600, 400))
      240000
  """
  @spec pixels(t()) :: pos_integer()
  def pixels(%__MODULE__{width: width, height: height}), do: width * height

  @doc """
  The aspect ratio: width divided by height, as a float.

  This is the `aspect` key of the `meta` map that `image_geometry/1` in
  `app/models/media_attachment.rb` writes. Both 600x400 and 588x392 give
  exactly 1.5, which is what the media attachment spec asserts for the
  `original` and `small` styles of the same upload.

  ## Examples

      iex> Mastodon.Media.Geometry.aspect(Mastodon.Media.Geometry.new(588, 392))
      1.5

      iex> Mastodon.Media.Geometry.aspect(Mastodon.Media.Geometry.new(32, 32))
      1.0
  """
  @spec aspect(t()) :: float()
  def aspect(%__MODULE__{width: width, height: height}), do: width / height

  @doc """
  The dimensions as `"WxH"`.

  This is the `size` key of the `meta` map written by `image_geometry/1`. The
  modifier is left out. That key never carried one.

  ## Examples

      iex> Mastodon.Media.Geometry.size(Mastodon.Media.Geometry.new(600, 400, :crop))
      "600x400"
  """
  @spec size(t()) :: String.t()
  def size(%__MODULE__{width: width, height: height}), do: "#{width}x#{height}"

  @doc """
  Solves a pixel budget: the box that keeps the aspect ratio of `geometry` and
  holds `pixels` pixels.

  The width is the square root of the budget times the width over the height.
  The height is the square root of the budget times the height over the width.
  Both are then rounded. The division is float division and the rounding is half
  away from zero, so the result matches `PixelGeometryParser.parse/2` exactly.

  Rounding can leave the area a little over the budget. A 600x400 source under
  230_400 pixels gives 588x392, which is 230_496 pixels. The Ruby rounds the same
  way, so the two agree.

  The result carries no modifier. `PixelGeometryParser.parse/2` returns a bare
  `Paperclip::Geometry` too: the crop flag comes from the style's geometry
  string, not from the solved box.

  Neither dimension is ever less than 1. libvips rejects a zero-sized target,
  and no budget in the media styles can reach that floor.

  ## Examples

      iex> Mastodon.Media.Geometry.from_pixels(Mastodon.Media.Geometry.new(600, 400), 230_400)
      %Mastodon.Media.Geometry{width: 588, height: 392, modifier: nil}

      iex> Mastodon.Media.Geometry.from_pixels(Mastodon.Media.Geometry.new(1500, 500), 750_000)
      %Mastodon.Media.Geometry{width: 1500, height: 500, modifier: nil}

      iex> Mastodon.Media.Geometry.from_pixels(Mastodon.Media.Geometry.new(7680, 4320), 230_400)
      %Mastodon.Media.Geometry{width: 640, height: 360, modifier: nil}
  """
  @spec from_pixels(t(), pos_integer()) :: t()
  def from_pixels(%__MODULE__{width: width, height: height}, pixels)
      when is_integer(pixels) and pixels > 0 do
    %__MODULE__{
      width: solve(pixels, width, height),
      height: solve(pixels, height, width)
    }
  end

  defp solve(pixels, numerator, denominator) do
    max(round(:math.sqrt(pixels * (numerator / denominator))), 1)
  end
end
