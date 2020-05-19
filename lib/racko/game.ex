defmodule Racko.Game do
  defstruct deck: [],
            revealed: [],
            players: %{},
            winner: nil,
            active_player: nil,
            owner: nil,
            started: false

  alias Racko.{Player, Game}

  @rack_size 10

  def new(owner) do
    %Game{}
    |> Map.put(:players, %{owner.name => owner})
    |> Map.put(:owner, owner.name)
  end

  def add_player(%Game{players: players} = game, %Player{name: name} = player) do
    new_players = Map.put(players, name, player)

    %Game{game | players: new_players}
  end

  def start(%Game{players: players} = game) do
    game
    |> generate_deck
    |> init_racks(Map.values(players))
    |> init_revealed
    |> select_starter
    |> Map.put(:started, true)
  end

  ## Game Init -----------
  defp generate_deck(%Game{players: players} = game) do
    deck =
      1..(Enum.count(players) * 10 + 20)
      |> Enum.shuffle()

    %Game{game | deck: deck}
  end

  defp init_racks(game, [player | tail]) do
    updated_game = deal_cards_to_player(game, player.name)
    init_racks(updated_game, tail)
  end

  defp init_racks(game, []), do: game

  defp init_revealed(game) do
    {[new_revealed | _], %Game{deck: new_deck}} = draw_from_deck(game)

    %Game{game | revealed: [new_revealed], deck: new_deck}
  end

  defp select_starter(%Game{players: players} = game) do
    %Game{game | active_player: Map.keys(players) |> Enum.random()}
  end

  defp deal_cards_to_player(%Game{players: players} = game, name, amount \\ @rack_size) do
    {player_cards, %Game{deck: new_deck}} = draw_from_deck(game, amount)
    new_players = Map.update!(players, name, &%Player{&1 | rack: player_cards})

    %Game{game | deck: new_deck, players: new_players}
  end

  ## Actions ------------
  def draw_from_deck(%Game{deck: deck} = game, amount \\ 1) do
    {cards, new_deck} = Enum.split(deck, amount)

    {cards, %Game{game | deck: new_deck}}
  end

  def draw_revealed(%Game{revealed: [top | tail]} = game) do
    {top, %Game{game | revealed: tail}}
  end

  def replace_revealed_card(%Game{revealed: revealed} = game, card) do
    %Game{game | revealed: [card | revealed]}
  end

  def end_turn(%Game{} = game) do
    game
    |> maybe_reshuffle_deck
    |> advance_turn
  end

  defp advance_turn(%Game{players: players, active_player: active_player} = game) do
    case Map.keys(players) |> List.last() == active_player do
      true ->
        %Game{game | active_player: Map.keys(players) |> List.first()}

      false ->
        # Ths is ugly. Find the index of the active player and add 1 to it to get the next player.
        new_active_player =
          Enum.at(
            players,
            Enum.find_index(players, fn {name, _} -> name == active_player end) + 1
          )
          |> elem(0)

        %Game{
          game
          | active_player: new_active_player
        }
    end
  end

  defp maybe_reshuffle_deck(%Game{revealed: revealed, deck: []} = game) do
    game
    |> Map.put(:deck, Enum.shuffle(revealed))
    |> init_revealed
  end

  defp maybe_reshuffle_deck(%Game{} = game), do: game

  ## End game ---------
  def racko?(%Player{rack: rack}) do
    compare_fn = fn c, acc ->
      if c > acc, do: {:cont, c}, else: {:halt, false}
    end

    !!Enum.reduce_while(rack, 0, compare_fn)
  end

  def assign_winner_if_racko(game, %Player{name: name}) do
    case !!racko?(Map.get(game.players, name)) do
      true -> %{game | winner: Map.get(game.players, name)}
      false -> game
    end
  end
end
