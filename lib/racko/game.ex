defmodule Racko.Game do
    defstruct [
        deck: [],
        revealed: nil,
        players: %{},
        winner: nil,
        active_player: nil
    ]

    alias Racko.{Player, Game}

    @rack_size 10

    @spec new([Racko.Player.t()]) :: Racko.Game.t()
    def new(players) do
        players_to_struct = fn p, acc ->
            Map.put(acc, p.name, p)
        end

        %Game{players: List.foldl(players, %{}, players_to_struct)}
        |> generate_deck
        |> init_racks(players)
        |> init_revealed
        |> select_starter
    end

    ## Game Init -----------
    defp generate_deck(%Game{players: players} = game) do
        deck = 1..Enum.count(players) * 10 + 20
        |> Enum.shuffle

        %Game{game | deck: deck}
    end

    defp init_racks(game, [player | tail]) do
        updated_game = deal_cards_to_player(game, player.name)
        init_racks(updated_game, tail)
    end

    defp init_racks(game, []), do: game

    defp init_revealed(game) do
        {[new_revealed | _], %Game{deck: new_deck}} = draw_from_deck(game)

        %Game{game | revealed: new_revealed, deck: new_deck}
    end

    defp select_starter(%Game{players: players} = game) do
        %Game{game | active_player: Enum.random(0..Enum.count(players) - 1)}
    end

    defp deal_cards_to_player(%Game{players: players} = game, name, amount \\ @rack_size) do
        {player_cards, %Game{deck: new_deck}} = draw_from_deck(game, amount)
        new_players = Map.update!(players, name, &(%Player{&1 | rack: player_cards}))

        %Game{game | deck: new_deck, players: new_players}
    end

    ## Actions ------------
    @spec draw_from_deck(Racko.Game.t(), integer) :: {[integer], Racko.Game.t()}
    def draw_from_deck(%Game{deck: deck} = game, amount \\ 1) do
        {cards, new_deck} = Enum.split(deck, amount)

        {cards, %Game{game | deck: new_deck}}
    end

    @spec draw_revealed(Racko.Game.t()) :: {integer, Racko.Game.t()}
    def draw_revealed(%Game{revealed: revealed} = game) do
        {revealed, %Game{game | revealed: nil}}
    end

    def replace_revealed_card(game, card) do
        %Game{game | revealed: card}
    end

    def end_turn(%Game{players: players, active_player: active_player} = game) do
        case active_player < Enum.count(players) - 1 do
            true -> %Game{game | active_player: active_player + 1}
            false -> %Game{game | active_player: 0}
        end
    end

    ## End game ---------
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
