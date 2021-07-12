defmodule GroupherServer.Mixfile do
  use Mix.Project

  def project do
    [
      app: :groupher_server,
      version: "0.1.1",
      elixir: "~> 1.9",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      dialyzer: [plt_add_deps: :transitive, ignore_warnings: ".dialyzer_ignore.exs"],
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {GroupherServer.Application, []},
      extra_applications: [
        :open_graph,
        :corsica,
        :ex_unit,
        :logger,
        :runtime_tools,
        :faker,
        :scrivener_ecto,
        :timex,
        :sentry
      ]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(:mock), do: ["lib", "priv/mock", "test/support"]
  defp elixirc_paths(_), do: ["lib", "test/support"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.5.7"},
      {:phoenix_pubsub, "~> 2.0"},
      {:phoenix_html, "~> 2.14.3"},
      {:ecto_sql, "~> 3.6.1"},
      {:phoenix_ecto, "~> 4.2.1"},
      {:postgrex, "~> 0.15.8"},
      {:gettext, "~> 0.18.0"},
      {:plug_cowboy, "~> 2.5.0"},
      {:plug, "~> 1.11.0"},
      # GraphQl tool
      {:absinthe, "~> 1.6.2"},
      # Plug support for Absinthe
      {:absinthe_plug, "~> 1.5.4"},
      # Password hashing lib
      {:comeonin, "~> 5.3.2"},
      # CORS
      {:corsica, "~> 1.1.2"},
      {:tesla, "~> 1.4.2"},
      # only used for tesla's JSON-encoder
      {:poison, "~> 3.1"},
      # for fake data in test env
      {:faker, "~> 0.9"},
      {:scrivener_ecto,
       git: "https://github.com/mastani-stack/scrivener_ecto", branch: "dev", override: true},
      # {:scrivener_ecto, "~> 2.0.0"},
      {:guardian, "~> 2.0"},
      {:timex, "~> 3.7.5"},
      {:dataloader, "~> 1.0.7"},
      {:mix_test_watch, "~> 1.0.2", only: :dev, runtime: false},
      {:ex_unit_notifier, "~> 1.0", only: :test},
      {:apollo_tracing, "~> 0.4.3"},
      {:pre_commit, "~> 0.3.4"},
      {:inch_ex, "~> 2.0", only: [:dev, :test]},
      {:short_maps, "~> 0.1.1"},
      {:jason, "~> 1.1.1"},
      {:credo, "~> 1.5.5", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.1.0", only: [:dev, :mock], runtime: false},
      {:excoveralls, "~> 0.8", only: :test},
      {:sentry, "~> 7.1"},
      {:recase, "~> 0.7.0"},
      {:nanoid, "~> 2.0.5"},
      # mailer
      {:bamboo, "1.3.0"},
      # mem cache
      {:cachex, "3.3.0"},
      # postgres-backed job queue
      {:rihanna, "1.3.5"},
      # cron-like scheduler job
      {:quantum, "~> 2.3"},
      {:html_sanitize_ex, "~> 1.3"},
      {:open_graph, "~> 0.0.3"},
      {:earmark, "~> 1.4.13"},
      # 遵循中文排版指南
      # https://github.com/cataska/pangu.ex
      {:pangu, "~> 0.1.0"},
      {:accessible, "~> 0.3.0"},
      {:floki, "~> 0.30.1"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"],
      "test.coverage": ["coveralls.html"],
      "test.coverage.short": ["coveralls"],
      "doc.report": ["inch.report"],
      lint: ["credo --strict"],
      "lint.static": ["dialyzer --format dialyxir"],
      "cps.seeds": ["run priv/mock/cps_seeds.exs"]
    ]
  end
end
