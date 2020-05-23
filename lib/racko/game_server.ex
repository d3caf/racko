defmodule Racko.GameServer do
  use GenServer

  require Logger

  alias Racko.{Game, Player}

  @timeout :timer.hours(1)

  # Client -----
  def start_link(name, owner) do
    GenServer.start_link(__MODULE__, {name, owner}, name: via_tuple(name))
  end

  def valid_game?(name) do
    case :ets.lookup(:games_table, name) do
      [] -> false
      _ -> true
    end
  end

  defp via_tuple(name) do
    {:via, Registry, {Racko.GameRegistry, name}}
  end

  def add_player(name, %Player{} = player) do
    GenServer.call(via_tuple(name), {:add_player, player})
  end

  def get_player(name, player_name) do
    GenServer.call(via_tuple(name), {:get_player, player_name})
  end

  def get_owner(name) do
    GenServer.call(via_tuple(name), {:get_owner})
  end

  def start_game(name) do
    GenServer.call(via_tuple(name), {:start_game})
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

  def discard_hand(name, %Player{} = player) do
    GenServer.call(via_tuple(name), {:discard_hand, player})
  end

  def end_turn(name) do
    GenServer.call(via_tuple(name), {:end_turn})
  end

  def get_game(name) do
    GenServer.call(via_tuple(name), {:get_game})
  end

  # Server -----
  def init({name, owner}) do
    game =
      case :ets.lookup(:games_table, name) do
        [] ->
          game = Game.new(owner)
          :ets.insert(:games_table, {name, game})
          game

        [{^name, game}] ->
          game
      end

    Logger.info("Started a new Racko game called #{name}.")

    {:ok, game, @timeout}
  end

  def game_pid(name) do
    name
    |> via_tuple
    |> GenServer.whereis()
  end

  def handle_call(
        {:add_player, %Player{name: name} = player},
        _from,
        %Game{players: players} = game
      ) do
    case joinable?(game) do
      {:error, message} ->
        {:reply, {:error, :unjoinable, message}, game}

      true ->
        if Map.has_key?(players, name) do
          {:reply, {:error, :player_exists, "A player already exists named #{name}"}, game, @timeout}
        else
          {:reply, :ok, game |> Game.add_player(player), @timeout}
        end
    end
  end

  def handle_call({:get_player, player_name}, _from, game) do
    {:reply, game.players[player_name], game}
  end

  def handle_call({:get_owner}, _from, game) do
    {:reply, game.owner, game}
  end

  def handle_call({:start_game}, _from, game) do
    {:reply, :ok, game |> Game.start(), @timeout}
  end

  def handle_call({:get_game}, _from, game) do
    {:reply, game, game}
  end

  def handle_call({:draw_revealed_card, %Player{} = player}, _from, game) do
    {card, new_game} = Game.draw_revealed(game)

    new_player = Player.put_card_in_hand(player, card)
    new_game = Player.update(new_game, new_player)

    {:reply, new_game, new_game, @timeout}
  end

  def handle_call({:draw_from_deck, %Player{} = player}, _from, game) do
    {[card | _], new_game} = Game.draw_from_deck(game)

    new_player = Player.put_card_in_hand(player, card)
    new_game = Player.update(new_game, new_player)

    {:reply, new_game, new_game, @timeout}
  end

  def handle_call({:put_hand_in_rack, %Player{} = player, index}, _from, game) do
    new_game =
      Player.put_hand_in_rack(game, player, index)
      |> Game.assign_winner_if_racko(player)

    {:reply, new_game, new_game, @timeout}
  end

  def handle_call({:discard_hand, %Player{} = player}, _from, game) do
    new_game = Player.discard_hand(game, player)

    {:reply, new_game, new_game, @timeout}
  end

  def handle_call({:end_turn}, _from, game) do
    new_game = Game.end_turn(game)
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
    Registry.keys(Racko.GameRegistry, self()) |> List.first()
  end

  defp joinable?(%Game{players: players, started: started}) do
    cond do
      started -> {:error, "Game is already started!"}
      Enum.count(players) > 3 -> {:error, "Table is full!"}
      true -> true
    end
  end
end
