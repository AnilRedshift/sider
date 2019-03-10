defmodule Sider.MixProject do
  use Mix.Project

  @version "0.1.0"
  @description "In-memory key/value store with expiring keys"
  @github "https://github.com/AnilRedshift/sider"

  def project do
    [
      app: :sider,
      version: @version,
      description: @description,
      docs: [
        source_ref: "v#{@version}",
        main: "Sider"
      ],
      source_url: @github,
      package: [
        name: :sider,
        maintainers: ["Anil Kulkarni"],
        licenses: ["MIT"],
        links: %{"Github" => @github}
      ],
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.19", only: :dev, runtime: false}
    ]
  end
end
