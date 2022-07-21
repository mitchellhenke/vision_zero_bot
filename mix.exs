defmodule VisionZeroBot.MixProject do
  use Mix.Project

  def project do
    [
      app: :vision_zero_bot,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :oauther]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.0"},
      {:extwitter, ">= 0.0.0"},
      {:finch, "~> 0.12"}
    ]
  end
end
