defmodule Bioskop.Application do
  # See https://elixir.hexdocs.pm/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      BioskopWeb.Telemetry,
      Bioskop.Repo,
      {DNSCluster, query: Application.get_env(:bioskop, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Bioskop.PubSub},
      Bioskop.SeatLock,
      # Start to serve requests, typically the last entry
      BioskopWeb.Endpoint
    ]

    # See https://elixir.hexdocs.pm/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Bioskop.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    BioskopWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
