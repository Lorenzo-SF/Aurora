defmodule Aurora.ColorTest do
  use ExUnit.Case
  doctest Aurora.Color

  alias Aurora.Color
  alias Aurora.Structs.ColorInfo

  describe "resolve_color/1" do
    test "returns ColorInfo struct for atom input" do
      color = Color.resolve_color(:primary)
      assert %ColorInfo{} = color
    end

    test "returns ColorInfo struct for hex input" do
      color = Color.resolve_color("#FF0000")
      assert %ColorInfo{} = color
    end

    test "returns ColorInfo struct for nil input" do
      color = Color.resolve_color(nil)
      assert %ColorInfo{} = color
    end
  end

  describe "basic color operations" do
    test "can create and work with color info" do
      color = %ColorInfo{name: :primary, hex: "#0000FF"}
      assert color.name == :primary
      assert color.hex == "#0000FF"
    end

    test "color info has required fields" do
      color = %ColorInfo{}
      assert Map.has_key?(color, :name)
      assert Map.has_key?(color, :hex)
      assert Map.has_key?(color, :inverted)
    end
  end
end
