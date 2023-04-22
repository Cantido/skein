defmodule SkeinTest do
  use ExUnit.Case
  doctest Skein

  test "greets the world" do
    assert Skein.hello() == :world
  end
end
