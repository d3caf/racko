defmodule Racko.Player do
    @enforce_keys [:name, :color]
    defstruct [:name, :color, :hand, rack: []]

    alias Racko.{Player, Game}

    def new(name, color) do
        %Racko.Player{name: name, color: color}
    end

    def update(%Game{players: players} = game, %Player{name: name} = new_player) do
        IO.inspect Map.replace!(players, name, new_player)
        %Game{game | players: Map.replace!(players, name, new_player)}
    end

    # @spec get_by_name(Racko.Game.t(), String.t()) :: nil | Racko.Player.t()
    # def get_by_name(%Game{players: players}, name) do
    #     Enum.find(players, fn p -> p.name == name end)
    # end

    # @spec get_index_by_name(Racko.Game.t(), String.t()) :: nil | non_neg_integer
    # def get_index_by_name(%Game{players: players}, name) do
    #     Enum.find_index(players, fn p -> p.name == name end)
    # end

    def put_card_in_hand(player, card) do
        %Player{player | hand: card}
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
