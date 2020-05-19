defmodule Racko.Player do
  @enforce_keys [:name, :color]
  defstruct [:name, :color, :hand, rack: []]

  alias Racko.{Player, Game}

  def new(name, color) do
    %Player{name: name, color: color}
  end

  def update(%Game{players: players} = game, %Player{name: name} = new_player) do
    %Game{game | players: Map.replace!(players, name, new_player)}
  end

  def put_card_in_hand(player, card) do
    %Player{player | hand: card}
  end

  def put_hand_in_rack(%Game{} = game, %Player{hand: hand} = player, index) do
    {new_player, old_card} = place_card_in_rack(player, index, hand)

    game
    |> update(%Player{new_player | hand: nil})
    |> Game.replace_revealed_card(old_card)
  end

  def discard_hand(%Game{revealed: revealed} = game, %Player{hand: hand} = player) do
    game
    |> Map.put(:revealed, [hand | revealed])
    |> update(%Player{player | hand: nil})
  end

  def get_card_from_deck(%Game{} = game, %Player{} = player) do
    {card, _new_game} = Game.draw_from_deck(game)
    new_player = put_card_in_hand(player, card)

    update(game, new_player)
  end

  @doc """
  Returns a tuple with the new player, and the player's discarded card
  e.g. {%Player{rack: [33, 1, 15], ...}, 22}
  """
  def place_card_in_rack(%Player{rack: rack} = player, index, card) do
    replaced_card = Enum.at(rack, index)

    {%Player{player | rack: List.replace_at(rack, index, card)}, replaced_card}
  end
end
