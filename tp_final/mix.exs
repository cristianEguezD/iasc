defmodule QueueManager.MixProject do
  use Mix.Project

  def project do
    [
      app: :tp_final,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
			# Para que no rompa los logs
			build_path: "_build"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:bunyan, :logger],
      mod: {QueueManager.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
			{:logger_file_backend, "== 0.0.10"},
      {:libcluster, "~> 3.3"},
      {:horde, "~> 0.8.3"},
			{:bunyan, ">= 0.0.0"}
    ]
  end
end
