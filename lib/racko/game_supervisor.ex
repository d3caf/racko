defmodule Racko.GameSupervisor do
  use DynamicSupervisor
  alias Racko.GameServer

  def start_link(_arg) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def new_game(name, owner) do
    child_spec = %{
      id: GameServer,
      start: {GameServer, :start_link, [name, owner]},
      restart: :transient
    }

    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  def stop_game(name) do
    :ets.delete(:games_table, name)

    child_pid = GameServer.game_pid(name)
    DynamicSupervisor.terminate_child(__MODULE__, child_pid)
  end
end
