defmodule ElixirMintZendesk.MixProject do
  use Mix.Project

  def project do
    [
      app: :elixir_mint_zendesk,
      version: "0.0.1",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: [main_module: MintTest.Main]
    ]
  end

  def application do
    [
      applications: [],
      extra_applications: [],
      included_applications: [],
      mod: {ElixirMintZendesk, []}
    ]
  end

  defp deps do
    [
      {:lager, "~> 3.8.0", override: true},
      {:exlager, github: "khia/exlager", branch: "master"},
      {:mint, github: "elixir-mint/mint", branch: "master"},
      {:castore, "~> 0.1.4"}
    ]
  end
end
