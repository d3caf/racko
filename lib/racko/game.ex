defmodule Racko.Game do
    defstruct deck: [], revealed: nil, players: [], winner: nil

    alias Racko.{Player, Game}

    @rack_size 10

    def new(players) do
        %Game{players: players}
        |> generate_deck
        |> init_racks(players)
    end

    def generate_deck(%Game{players: players} = game) do
        deck = 1..Enum.count(players) * 10 + 20
        |> Enum.shuffle

        %Game{game | deck: deck}
    end

    def init_racks(game, [player | tail]) do
        updated_game = deal_cards_to_player(game, player.name)
        init_racks(updated_game, tail)
    end

    def init_racks(game, []), do: game

    def deal_cards_to_player(%Game{deck: deck, players: players} = game, name, amount \\ @rack_size) do
        {player_cards, new_deck} = Enum.split(deck, amount)

        player_index = Enum.find_index(players, fn p -> p.name == name end)
        new_players = List.update_at(players, player_index, &(%Racko.Player{&1 | rack: player_cards})) 

        %Game{game | deck: new_deck, players: new_players}
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