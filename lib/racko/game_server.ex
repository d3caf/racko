defmodule Racko.GameServer do
  use GenServer

  require Logger

  alias Racko.{Game, Player}

  @timeout :timer.hours(1)

  # Client -----
  def start_link(name, players) do
    GenServer.start_link(__MODULE__, {name, players}, name: via_tuple(name))
  end

  def via_tuple(game_name) do
    {:via, Registry, {Racko.GameRegistry, game_name}}
  end

  def draw_revealed_card(name, player, target_index) do
    GenServer.call(via_tuple(name), {:draw_revealed_card, player, target_index})
  end

  # Server -----
  def init({name, players}) do
    game =
      case :ets.lookup(:games_table, name) do
        [] ->
          game = Game.new(players)
          :ets.insert(:games_table, {name, players})
          game

        [{^name, game}] -> game
      end

    Logger.info("Started a new Racko game called #{name}.")

    {:ok, game, @timeout}
  end

  def game_pid(name) do
    name
    |> via_tuple
    |> GenServer.whereis
  end

  def handle_call({:draw_revealed_card, player, target_index}, _from, game) do
      {new_player, replaced_card} = Game.place_card_in_rack(player, target_index, game.revealed)

      new_game = game
        |> Game.update_player(player, new_player)
        |> Game.replace_revealed_card(replaced_card)

      {:reply, new_game, new_game, @timeout}
  end

  def handle_info(:timeout, game) do
    {:stop, {:shutdown, :timeout}, game}
  end

  def terminate({:shutdown, :timeout}, _game) do
    :ets.delete(:games_table, my_game_name())
    :ok
  end

  def terminate(_reason, _game) do
    :ok
  end

  defp my_game_name() do
    Registry.keys(Racko.GameRegistry, self()) |> List.first
  end

end
