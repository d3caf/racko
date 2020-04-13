defmodule Racko.Lobby do
  defstruct [players: []]

  alias Racko.{Lobby, Player, Game}

  @doc """
  Creates a new Lobby
  """
  def new(starting_player = %Player{}) do
    %Lobby{players: [starting_player]}
  end

  def add_player(%Lobby{players: players} = lobby, %Player{} = player) do
    %Lobby{lobby | players: players ++ [player]}
  end

  def remove_player(%Lobby{players: players} = lobby, %Player{name: name}) do
    player_index = Enum.find_index(players, fn p -> p.name == name end)
    %Lobby{lobby | players: List.delete_at(players, player_index)}
  end
end
