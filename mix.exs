defmodule Liveness.MixProject do
  use Mix.Project

  def project do
    [
      app: :liveness,
      deps: [],
      description: "A declarative busy wait",
      docs: docs(),
      elixir: "~> 1.7",
      package: package(),
      start_permanent: Mix.env() == :prod,
      version: "1.0.0"
    ]
  end

  def application, do: []

  defp docs do
    [
      main: "readme",
      extras: ["README.md"]
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/well-ironed/liveness"}
    ]
  end
end
