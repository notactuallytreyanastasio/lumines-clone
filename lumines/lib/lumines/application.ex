defmodule Lumines.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      LuminesWeb.Telemetry,
      Lumines.Repo,
      {DNSCluster, query: Application.get_env(:lumines, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Lumines.PubSub},
      # Start a worker by calling: Lumines.Worker.start_link(arg)
      # {Lumines.Worker, arg},
      # Start to serve requests, typically the last entry
      LuminesWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Lumines.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    LuminesWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
