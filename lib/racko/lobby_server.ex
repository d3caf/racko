defmodule Racko.LobbyServer do
  use GenServer
  require Logger

  alias Racko.{Lobby, Player}

  @timeout :timer.minutes(30)

  # Client -----
  def start_link(name, player) do
    GenServer.start_link(__MODULE__, {name, player}, name: via_tuple(name))
  end

  def add_player(name, %Player{} = player) do
    GenServer.call(via_tuple(name), {:add_player, player})
  end

  def remove_player(name, %Player{} = player) do
    GenServer.call(via_tuple(name), {:remove_player, player})
  end

  def get_lobby(name) do
    GenServer.call(via_tuple(name), {:get_lobby})
  end

  defp via_tuple(name) do
    {:via, Registry, {Racko.LobbyRegistry, name}}
  end

  # Server -----
  def init({name, %Player{} = player}) do
    lobby =
      case :ets.lookup(:lobbies_table, name) do
        [] ->
          lobby = Lobby.new(player)
          :ets.insert(:lobbies_table, {name, lobby})
          lobby

        [{^name, lobby}] -> lobby

      end

    Logger.info("Started a new lobby called #{name}")

    {:ok, lobby, @timeout}
  end

  def lobby_pid(name) do
    name
    |> via_tuple
    |> GenServer.whereis
  end

  def handle_call({:add_player, %Player{} = player}, _from, lobby) do
    new_lobby = lobby
      |> Lobby.add_player(player)

    {:reply, new_lobby.players, new_lobby, @timeout}
  end

  def handle_call({:remove_player, %Player{} = player}, _from, lobby) do
    if Enum.count(lobby.players) > 1 do
      new_lobby = lobby
                  |> Lobby.remove_player(player)

      {:reply, new_lobby.players, new_lobby, @timeout}
    else
      {:reply, {:error, "Can't remove only player from lobby"}, lobby, @timeout}
    end
  end

  def handle_call({:get_lobby}, _from, lobby) do
    {:reply, lobby, lobby, @timeout}
  end
end
