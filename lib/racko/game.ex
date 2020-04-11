defmodule Racko.Game do
    defstruct deck: [], revealed: nil, players: [], winner: nil, active_player: nil

    alias Racko.{Player, Game}

    @rack_size 10

    def new(players) do
        %Game{players: players}
        |> generate_deck
        |> init_racks(players)
        |> init_revealed
        |> select_starter
    end

    def select_starter(%Game{players: players} = game) do
        %Game{game | active_player: Enum.random(0..Enum.count(players) - 1)}
    end

    def end_turn(%Game{players: players, active_player: active_player} = game) do
        case active_player < Enum.count(players) - 1 do
            true -> %Game{game | active_player: active_player + 1}
            false -> %Game{game | active_player: 0}
        end
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

    def init_revealed(game) do
        {new_revealed, new_deck} = draw_cards_from_deck(game)

        %Game{game | revealed: List.first(new_revealed), deck: new_deck}
    end

    def draw_cards_from_deck(%Game{deck: deck}, amount \\ 1) do
        Enum.split(deck, amount)
    end

    def deal_cards_to_player(%Game{players: players} = game, name, amount \\ @rack_size) do
        {player_cards, new_deck} = draw_cards_from_deck(game, amount)

        player_index = Player.get_index_by_name(game, name)
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

    def replace_revealed_card(game, card) do
        %Game{game | revealed: card}
    end

    def racko?(%Player{rack: rack}) do
        compare_fn = fn c, acc ->
            if c > acc, do: {:cont, acc = c}, else: {:halt, acc = false}
        end

        !!Enum.reduce_while(rack, 0, compare_fn)
    end

    defp assign_winner_if_racko(game, player) do
        case !!racko?(player) do
            true -> %{game | winner: player}
            false -> game
        end
    end
end
