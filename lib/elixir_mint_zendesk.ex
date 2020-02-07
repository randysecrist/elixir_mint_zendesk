defmodule ElixirMintZendesk do
  use Application

  def start do
    :application.start(:inquisitor)
  end

  def stop do
    :application.stop(:inquisitor)
  end

  def start(_type, _argv) do
    start_link()
  end

  def stop(_state) do
    :ok
  end

  def start_link do
    import Supervisor.Spec, warn: false

    children = [
    ]

    opts = [strategy: :one_for_one, name: :inquisitor_sup]
    Supervisor.start_link(children, opts)
  end
end
