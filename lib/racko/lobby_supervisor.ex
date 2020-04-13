defmodule Racko.LobbySupervisor do
  use DynamicSupervisor
  alias Racko.LobbyServer

  def start_link(_arg) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_lobby(name, player) do
    child_spec = %{
      id: LobbyServer,
      start: {LobbyServer, :start_link, [name, player]},
      restart: :transient
    }

    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  def stop_lobby(name) do
    :ets.delete(:lobbies_table, name)

    child_pid = LobbyServer.lobby_pid(name)
    DynamicSupervisor.terminate_child(__MODULE__, child_pid)
  end
end
