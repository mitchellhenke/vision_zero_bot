defmodule VisionZeroBotTest do
  use ExUnit.Case
  doctest VisionZeroBot

  test "greets the world" do
    assert VisionZeroBot.hello() == :world
  end
end
