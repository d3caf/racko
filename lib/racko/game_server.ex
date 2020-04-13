defmodule Racko.GameServer do
  use GenServer

  require Logger

  alias Racko.{Game, Player}

  @timeout :timer.hours(1)

  # Client -----
  def start_link(name, players) do
    GenServer.start_link(__MODULE__, {name, players}, name: via_tuple(name))
  end

  defp via_tuple(name) do
    {:via, Registry, {Racko.GameRegistry, name}}
  end

  def draw_from_deck(name, %Player{} = player) do
    GenServer.call(via_tuple(name), {:draw_from_deck, player})
  end

  def draw_revealed_card(name, %Player{} = player) do
    GenServer.call(via_tuple(name), {:draw_revealed_card, player})
  end

  def put_hand_in_rack(name, %Player{} = player, index) do
    GenServer.call(via_tuple(name), {:put_hand_in_rack, player, index})
  end

  def get_game(name) do
    GenServer.call(via_tuple(name), {:get_game})
  end

  # Server -----
  def init({name, players}) do
    game =
      case :ets.lookup(:games_table, name) do
        [] ->
          game = Game.new(players)
          :ets.insert(:games_table, {name, game})
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

  def handle_call({:get_game}, _from, game) do
    {:reply, game, game}
  end

  # TODO refactor
  # def handle_call({:draw_revealed_card, %Player{name: name}}, _from, game) do
  #   {revealed, %Game{players: players} = game} = Game.draw_revealed(game)

  #   new_game = %Game{game | players: put_in(players, [name, :hand], revealed)}

  #   {:reply, new_game, new_game, @timeout}
  # end

  def handle_call({:draw_from_deck, %Player{} = player}, _from, game) do
    {[card | _], new_game} = Game.draw_from_deck(game)

    new_player = Player.put_card_in_hand(player, card)
    new_game = Player.update(new_game, new_player)

    {:reply, new_game, new_game, @timeout}
  end

  def handle_call({:put_hand_in_rack, %Player{} = player, index}, _from, game) do
    new_game = Player.put_hand_in_rack(game, player, index)
    {:reply, :ok, new_game, @timeout}
  end

  # def handle_call({:draw_revealed_card, player}, _from, game) do
  #     new_player = Game.draw_revealed(game, player)

  #     new_game = game
  #       |> Game.update_player(player, new_player)
  #       |> Game.replace_revealed_card(replaced_card)

  #     {:reply, new_game, new_game, @timeout}
  # end

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
