defmodule Mastodon.MixProject do
  use Mix.Project

  # Read from lib/mastodon/version.rb: major 4, minor 6, patch 2. api_versions/0 in that file
  # returns %{mastodon: 11}, which the instance JSON view keeps emitting.
  @version "4.6.2"

  def project do
    [
      app: :mastodon,
      version: @version,
      # Elixir 1.19.x only: `~> 1.19.0` means >= 1.19.0 and < 1.20.0, where `~> 1.19` would have
      # admitted 1.20. .tool-versions pins 1.19.5-otp-28. Decision log: DL-03, DL-15.
      elixir: "~> 1.19.0",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      releases: releases(),
      dialyzer: dialyzer(),
      test_coverage: [tool: ExCoveralls]
    ]
  end

  # Mix 1.19 deprecates the :preferred_cli_env project key in favour of this callback.
  # Decision log: DL-14.
  def cli do
    [
      preferred_envs: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.html": :test,
        "coveralls.json": :test,
        "coveralls.post": :test
      ]
    ]
  end

  # Mastodon.Application supervises the tree that replaces Puma, Sidekiq, and the Node streaming
  # server. Two OTP applications are called directly: Mastodon.Crypto.ActiveRecordEncryption reads
  # Rails AES-256-GCM envelopes through :crypto, and account keypair generation uses :public_key.
  def application do
    [
      mod: {Mastodon.Application, []},
      extra_applications: [:logger, :runtime_tools, :crypto, :public_key]
    ]
  end

  # test/support holds ConnCase, ChannelCase, DataCase, and the ExMachina factories.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_env), do: ["lib"]

  # Versions are pinned exactly. Each comment names what the package replaces in the Gemfile or
  # in streaming/package.json.
  defp deps do
    [
      # HTTP endpoint, router, controllers, and channels. Rails leaves `action_cable/engine`
      # commented out at config/application.rb:L13, so streaming runs as a separate Node process
      # today. Phoenix ships channels with the endpoint.
      {:phoenix, "1.8.11"},
      {:phoenix_pubsub, "2.2.0"},
      {:phoenix_template, "1.0.4"},
      {:phoenix_live_view, "1.2.9"},
      # Request pipeline, replacing Rack middleware.
      {:plug, "1.20.3"},
      {:plug_crypto, "2.2.0"},
      # HTTP and WebSocket server, replacing puma 8.0.2 and the Node ws 8 server.
      {:bandit, "1.12.4"},
      {:thousand_island, "1.5.0"},
      {:websock, "0.5.3"},
      {:websock_adapter, "0.6.0"},
      {:mime, "2.0.7"},
      {:hpax, "1.0.4"},
      # Localization, replacing config/locales lookup.
      {:gettext, "0.26.2"},

      # Schemas, changesets, and query composition, replacing ActiveRecord.
      {:ecto, "3.14.1"},
      {:ecto_sql, "3.14.0"},
      # PostgreSQL driver and pool, replacing the pg and connection_pool gems and Node's pg.
      {:postgrex, "0.22.4"},
      {:db_connection, "2.10.2"},
      {:decimal, "3.1.1"},
      # Database diagnostics, replacing PgHero at /pghero.
      {:ecto_psql_extras, "0.8.8"},

      # Background jobs on PostgreSQL, replacing sidekiq 8.1.6, sidekiq-bulk, sidekiq-scheduler,
      # sidekiq-unique-jobs, and fugit. Decision log: DL-01.
      {:oban, "2.23.1"},
      # Job dashboard, replacing Sidekiq Web at /sidekiq.
      {:oban_web, "2.12.6"},

      # Mail composition and SMTP transport, replacing ActionMailer, mail 2.9.0, and
      # premailer-rails. The SMTP_* variables keep their names.
      {:swoosh, "1.27.0"},
      {:gen_smtp, "1.3.0"},

      # OAuth 2 provider bound to Doorkeeper's existing tables, replacing doorkeeper 5.9.2.
      {:ex_oauth2_provider, "0.5.7"},
      # Reads the bcrypt digests Devise already wrote.
      {:bcrypt_elixir, "3.3.2"},
      # Time-based one-time passwords, replacing rotp 6.3.0.
      {:nimble_totp, "1.0.0"},
      # RFC 8291 payload encryption and VAPID. Stands in for the fork Gemfile:L96 pins:
      # gem 'webpush' from github mastodon/webpush at ref
      # 9631ac63045cfabddacc69fc06e919b4c13eb913, which resolves to 1.1.0. Decision log: DL-13.
      {:web_push_encryption, "0.3.1"},
      # Draft-cavage HTTP signatures for ActivityPub.
      {:http_signatures, "0.1.3"},

      # JSON-LD expansion and compaction, URDNA2015 canonicalization, and RFC 8785 canonical JSON,
      # replacing json-ld 3.3.2 and rdf-normalize 0.7.0.
      {:json_ld, "1.0.1"},
      {:rdf, "3.0.1"},
      {:jcs, "0.2.0"},

      # HTML parsing and sanitization, replacing nokogiri 1.19.4 and sanitize 7.0.0.
      {:floki, "0.38.4"},
      {:fast_html, "2.5.0"},
      {:html_sanitize_ex, "1.5.4"},
      # Markdown rendering, replacing redcarpet 3.6.1. Decision log: DL-10.
      {:mdex, "0.13.5"},
      # JSON schema validation for the contract tests.
      {:ex_json_schema, "0.11.5"},
      # XML parsing for WebFinger and RSS, replacing ox 2.14.27.
      {:sweet_xml, "0.7.5"},

      # Object storage, replacing aws-sdk-s3 1.225.1. Media paths do not change.
      {:ex_aws, "2.6.1"},
      {:ex_aws_s3, "2.5.9"},
      # Image processing over libvips, replacing kt-paperclip 7.3.0 processors.
      {:image, "0.72.0"},
      {:vix, "0.40.0"},
      # Blurhash generation, replacing the blurhash gem 0.1.8.
      {:blurhash, "2.0.0"},

      # Pooled HTTP client for federation, replacing the http gem 5.3.1.
      {:finch, "0.23.0"},
      {:mint, "1.9.3"},
      # High-level client for administrative and FASP calls.
      {:req, "0.7.2"},
      {:castore, "1.0.20"},
      # ExAws's default HTTP backend. web_push_encryption also requires it, through httpoison.
      {:hackney, "1.25.0"},
      {:nimble_pool, "1.1.0"},

      # In-process cache covering part of the Rails cache store.
      {:cachex, "4.1.1"},
      # Request throttling, replacing rack-attack 6.8.0. Limits and headers stay the same.
      {:hammer, "7.4.0"},
      {:plug_attack, "0.4.3"},
      # Cross-origin headers, replacing rack-cors 3.0.0.
      {:cors_plug, "3.0.3"},

      # Redis client for the timeline sorted sets and the idempotency and lock keys, replacing the
      # redis gem and Node's ioredis. Decision log: DL-02.
      {:redix, "1.6.0"},
      # Cross-node event distribution for multi-node deployments. Decision log: DL-02.
      {:phoenix_pubsub_redis, "3.1.1"},
      # Elasticsearch and OpenSearch client, replacing chewy 8.4.1.
      {:snap, "0.17.0"},

      # Observability, required by Rule 3. These reproduce what prometheus_exporter 2.3.1 on port
      # 9394, prom-client 15, lograge 0.14.0, pino 10, and the Ruby OTel group emit today.
      {:telemetry, "1.4.2"},
      {:telemetry_metrics, "1.1.0"},
      {:telemetry_poller, "1.3.0"},
      {:telemetry_metrics_prometheus_core, "1.2.1"},
      {:prom_ex, "1.12.0"},
      {:logger_json, "7.0.4"},
      {:opentelemetry, "1.7.0"},
      {:opentelemetry_api, "1.5.0"},
      {:opentelemetry_exporter, "1.10.0"},
      {:opentelemetry_phoenix, "2.0.1"},
      {:opentelemetry_bandit, "0.3.0"},
      {:opentelemetry_ecto, "1.2.0"},
      {:opentelemetry_oban, "1.2.0"},

      # Static analysis, replacing rubocop and brakeman.
      {:credo, "1.7.19", only: [:dev, :test], runtime: false},
      {:dialyxir, "1.4.7", only: [:dev, :test], runtime: false},
      {:sobelow, "0.15.0", only: [:dev, :test], runtime: false},

      # Test tooling, replacing fabrication, service-object stubbing, and simplecov.
      {:ex_machina, "2.8.2", only: :test},
      {:mox, "1.2.0", only: :test},
      {:excoveralls, "0.18.5", only: :test, runtime: false}
    ]
  end

  # One release replaces the four processes in Procfile.dev, the three application services in
  # docker-compose.yml, and the five unit files in dist/. The name `mastodon` produces
  # _build/prod/rel/mastodon/bin/mastodon, the path dist/mastodon-elixir.service and Procfile
  # invoke. rel/env.sh.eex and rel/vm.args.eex are picked up from rel/ without being listed here.
  defp releases do
    [
      mastodon: [
        include_executables_for: [:unix],
        applications: [runtime_tools: :permanent],
        steps: [:assemble]
      ]
    ]
  end

  # .dialyzer_ignore.exs sits next to this file. The PLT is cached under priv/plts.
  defp dialyzer do
    [
      ignore_warnings: ".dialyzer_ignore.exs",
      plt_add_apps: [:mix, :ex_unit],
      plt_file: {:no_warn, "priv/plts/dialyzer.plt"}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "ecto.setup"],
      # Migrations are additive: this project owns Oban's tables and nothing else. Rails owns
      # db/schema.rb at version 2026_06_11_150940, the 516 files in db/migrate, and the 72 in
      # db/post_migrate. There is no ecto.dump or ecto.load step: Mix never rewrites that schema.
      "ecto.setup": ["ecto.create", "ecto.migrate"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      # The five quality gates, in order.
      quality: [
        "compile --warnings-as-errors",
        "format --check-formatted",
        "credo --strict",
        "sobelow --exit",
        "dialyzer"
      ]
    ]
  end
end
