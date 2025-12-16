defmodule GiocciEngine.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    engine_name = Application.fetch_env!(:giocci_engine, :engine_name)
    key_prefix = Application.get_env(:giocci_engine, :key_prefix, "")

    children = [
      {GiocciEngine.Worker, [engine_name: engine_name, key_prefix: key_prefix]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: GiocciEngine.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
