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

  describe "expand_gradient_colors/1" do
    test "handles single color" do
      result = Color.expand_gradient_colors(["#FF0000"])
      assert length(result) == 6
      assert Enum.all?(result, &(&1 == "#FF0000"))
    end

    test "handles two colors" do
      result = Color.expand_gradient_colors(["#FF0000", "#00FF00"])
      assert length(result) == 6
      assert Enum.take(result, 3) == ["#FF0000", "#FF0000", "#FF0000"]
      assert Enum.drop(result, 3) == ["#00FF00", "#00FF00", "#00FF00"]
    end

    test "handles three colors" do
      result = Color.expand_gradient_colors(["#FF0000", "#00FF00", "#0000FF"])
      assert length(result) == 6
    end

    test "handles six colors unchanged" do
      colors = ["#FF0000", "#00FF00", "#0000FF", "#FFFF00", "#FF00FF", "#00FFFF"]
      assert Color.expand_gradient_colors(colors) == colors
    end

    test "handles invalid input" do
      result = Color.expand_gradient_colors("invalid")
      assert length(result) == 6
    end
  end

  describe "get_all_colors/0" do
    test "returns map with color info structs" do
      result = Color.get_all_colors()
      assert is_map(result)

      # Test that values are ColorInfo structs
      result
      |> Map.values()
      |> Enum.each(fn value -> assert %ColorInfo{} = value end)
    end

    @tag :deprecated
    test "all_colors_availables/0 (deprecated) returns same as get_all_colors/0" do
      assert Color.get_all_colors() == Color.all_colors_availables()
    end
  end
end
