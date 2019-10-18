defmodule Liveness.MixProject do
  use Mix.Project

  def project do
    [
      app: :liveness,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: []
    ]
  end

  def application, do: []
end
