defmodule Racko.Player do
    @enforce_keys [:name, :color]
    defstruct [:name, :color, rack: []]

    alias Racko.{Player, Game}

    def new(name, color) do
        %Racko.Player{name: name, color: color}
    end

    def update(%Game{players: players} = game, %Player{name: name}, new_player) do
        player_index = get_index_by_name(game, name)
        new_players = List.update_at(players, player_index, new_player)

        %Game{game | players: new_players}
    end

    @spec get_by_name(Racko.Game.t(), String.t()) :: nil | Racko.Player.t()
    def get_by_name(%Game{players: players}, name) do
        Enum.find(players, fn p -> p.name == name end)
    end

    @spec get_index_by_name(Racko.Game.t(), String.t()) :: nil | non_neg_integer
    def get_index_by_name(%Game{players: players}, name) do
        Enum.find_index(players, fn p -> p.name == name end)
    end

end
