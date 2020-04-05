defmodule RackoTest do
  use ExUnit.Case
  doctest Racko

  test "greets the world" do
    assert Racko.hello() == :world
  end
end
