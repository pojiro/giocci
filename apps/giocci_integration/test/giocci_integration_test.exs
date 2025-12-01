defmodule GiocciIntegrationTest do
  use ExUnit.Case
  doctest GiocciIntegration

  test "greets the world" do
    assert GiocciIntegration.hello() == :world
  end
end
