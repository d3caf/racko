defmodule Racko.Player do
    @enforce_keys [:name, :color]
    defstruct [:name, :color, rack: []]

    def new(name, color) do
        %Racko.Player{name: name, color: color}
    end
end