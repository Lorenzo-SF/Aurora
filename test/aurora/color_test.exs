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

  describe "hex_to_rgb/1" do
    test "converts valid hex to RGB tuple" do
      assert Color.hex_to_rgb("#FF0000") == {255, 0, 0}
      assert Color.hex_to_rgb("#00FF00") == {0, 255, 0}
      assert Color.hex_to_rgb("#0000FF") == {0, 0, 255}
    end

    test "converts white and black" do
      assert Color.hex_to_rgb("#FFFFFF") == {255, 255, 255}
      assert Color.hex_to_rgb("#000000") == {0, 0, 0}
    end

    test "handles lowercase hex" do
      assert Color.hex_to_rgb("#ff0000") == {255, 0, 0}
      assert Color.hex_to_rgb("#abc123") == {171, 193, 35}
    end

    test "returns {0,0,0} for invalid input" do
      assert Color.hex_to_rgb("invalid") == {0, 0, 0}
      assert Color.hex_to_rgb("") == {0, 0, 0}
      assert Color.hex_to_rgb("#FFF") == {0, 0, 0}
    end
  end

  describe "rgb_to_hex/1" do
    test "converts RGB tuple to hex" do
      assert Color.rgb_to_hex({255, 0, 0}) == "#FF0000"
      assert Color.rgb_to_hex({0, 255, 0}) == "#00FF00"
      assert Color.rgb_to_hex({0, 0, 255}) == "#0000FF"
    end

    test "converts with padding for small values" do
      assert Color.rgb_to_hex({1, 2, 3}) == "#010203"
      assert Color.rgb_to_hex({0, 0, 0}) == "#000000"
    end

    test "converts intermediate values" do
      assert Color.rgb_to_hex({128, 64, 192}) == "#8040C0"
    end
  end

  describe "normalize_hex/1" do
    test "adds # prefix if missing" do
      assert Color.normalize_hex("FF0000") == "#FF0000"
    end

    test "converts to uppercase" do
      assert Color.normalize_hex("#ff0000") == "#FF0000"
      assert Color.normalize_hex("abc123") == "#ABC123"
    end

    test "trims whitespace" do
      assert Color.normalize_hex("  #FF0000  ") == "#FF0000"
      assert Color.normalize_hex("  FF0000  ") == "#FF0000"
    end

    test "handles already normalized hex" do
      assert Color.normalize_hex("#FF0000") == "#FF0000"
    end
  end

  describe "valid_hex?/1" do
    test "validates correct hex colors" do
      assert Color.valid_hex?("#FF0000")
      assert Color.valid_hex?("#00FF00")
      assert Color.valid_hex?("#ABC123")
      assert Color.valid_hex?("#ffffff")
    end

    test "rejects invalid hex colors" do
      refute Color.valid_hex?("FF0000")
      refute Color.valid_hex?("#FFF")
      refute Color.valid_hex?("#GGGGGG")
      refute Color.valid_hex?("invalid")
      refute Color.valid_hex?("")
    end

    test "rejects non-string input" do
      refute Color.valid_hex?(nil)
      refute Color.valid_hex?(123)
      refute Color.valid_hex?(%{})
    end
  end

  describe "apply_color/2" do
    test "applies color to text" do
      color = %ColorInfo{hex: "#FF0000", inverted: false}
      result = Color.apply_color("Test", color)

      assert result =~ "Test"
      assert result =~ "\e[38;2;"
      assert result =~ "\e[0m"
    end

    test "applies inverted color" do
      color = %ColorInfo{hex: "#FF0000", inverted: true}
      result = Color.apply_color("Test", color)

      assert result =~ "\e[7m"
      assert result =~ "\e[27m"
    end

    test "handles empty text" do
      color = %ColorInfo{hex: "#FF0000", inverted: false}
      result = Color.apply_color("", color)

      assert is_binary(result)
    end

    test "returns text unchanged for invalid color" do
      result = Color.apply_color("Test", %{})
      assert result == "Test"
    end
  end

  describe "rgb_to_ansi256/1" do
    test "converts RGB to ANSI 256 color code" do
      result = Color.rgb_to_ansi256({255, 0, 0})
      assert is_integer(result)
      assert result >= 16
      assert result <= 255
    end

    test "converts black" do
      result = Color.rgb_to_ansi256({0, 0, 0})
      assert result == 16
    end

    test "converts white" do
      result = Color.rgb_to_ansi256({255, 255, 255})
      assert is_integer(result)
    end

    test "handles intermediate values" do
      result = Color.rgb_to_ansi256({128, 128, 128})
      assert is_integer(result)
      assert result >= 16
    end
  end

  describe "generate_gradient_between/2" do
    test "generates gradient between two colors" do
      gradient = Color.generate_gradient_between("#FF0000", "#0000FF")

      assert length(gradient) == 6
      assert Enum.at(gradient, 0) == "#FF0000"
      assert Enum.at(gradient, 5) == "#0000FF"
    end

    test "intermediate colors are transitions" do
      gradient = Color.generate_gradient_between("#000000", "#FFFFFF")

      assert length(gradient) == 6
      assert Enum.at(gradient, 0) == "#000000"
      assert Enum.at(gradient, 5) == "#FFFFFF"

      # Intermediate values should be progressive
      assert Enum.all?(gradient, &Color.valid_hex?/1)
    end

    test "handles same start and end color" do
      gradient = Color.generate_gradient_between("#FF0000", "#FF0000")

      assert length(gradient) == 6
      assert Enum.all?(gradient, &(&1 == "#FF0000"))
    end

    test "handles invalid colors" do
      gradient = Color.generate_gradient_between("invalid", "#FF0000")

      assert is_list(gradient)
      assert length(gradient) == 6
    end
  end

  describe "lighten_rgb/2" do
    test "lightens RGB color" do
      result = Color.lighten_rgb({100, 100, 100}, 50)
      assert result == {150, 150, 150}
    end

    test "caps at 255" do
      result = Color.lighten_rgb({240, 240, 240}, 50)
      assert result == {255, 255, 255}
    end

    test "handles zero amount" do
      result = Color.lighten_rgb({100, 100, 100}, 0)
      assert result == {100, 100, 100}
    end

    test "lightens individual channels" do
      result = Color.lighten_rgb({0, 100, 200}, 50)
      assert result == {50, 150, 250}
    end
  end

  describe "darken_rgb/2" do
    test "darkens RGB color" do
      result = Color.darken_rgb({150, 150, 150}, 50)
      assert result == {100, 100, 100}
    end

    test "floors at 0" do
      result = Color.darken_rgb({30, 30, 30}, 50)
      assert result == {0, 0, 0}
    end

    test "handles zero amount" do
      result = Color.darken_rgb({100, 100, 100}, 0)
      assert result == {100, 100, 100}
    end

    test "darkens individual channels" do
      result = Color.darken_rgb({255, 150, 50}, 25)
      assert result == {230, 125, 25}
    end
  end

  describe "extract_hexes/1" do
    test "extracts hex from list of ColorInfo" do
      colors = [
        %ColorInfo{hex: "#FF0000"},
        %ColorInfo{hex: "#00FF00"}
      ]

      result = Color.extract_hexes(colors)
      assert result == ["#FF0000", "#00FF00"]
    end

    test "extracts hex from map" do
      colors = %{
        red: %ColorInfo{hex: "#FF0000"},
        green: %ColorInfo{hex: "#00FF00"}
      }

      result = Color.extract_hexes(colors)
      assert is_list(result)
      assert "#FF0000" in result
      assert "#00FF00" in result
    end

    test "extracts from single ColorInfo" do
      color = %ColorInfo{hex: "#FF0000", name: :red, inverted: false}
      result = Color.extract_hexes(color)

      # extract_hexes with non-list input calls extract_hex and wraps in list
      assert is_list(result)
      assert "#FF0000" in result
    end

    test "handles string input" do
      result = Color.extract_hexes("#FF0000")
      assert result == ["#FF0000"]
    end
  end

  describe "extract_hex/1" do
    test "extracts from ColorInfo" do
      assert Color.extract_hex(%ColorInfo{hex: "#FF0000"}) == "#FF0000"
    end

    test "extracts from tuple" do
      assert Color.extract_hex({:red, %ColorInfo{hex: "#FF0000"}}) == "#FF0000"
      assert Color.extract_hex({:any, "#00FF00"}) == "#00FF00"
    end

    test "extracts from map" do
      assert Color.extract_hex(%{hex: "#FF0000"}) == "#FF0000"
      assert Color.extract_hex(%{other: "value"}) == ""
    end

    test "handles string directly" do
      assert Color.extract_hex("#FF0000") == "#FF0000"
    end

    test "converts other types to string" do
      assert Color.extract_hex(123) == "123"
      assert Color.extract_hex(:atom) == "atom"
    end
  end

  describe "get_default_color/0" do
    test "returns ColorInfo struct" do
      result = Color.get_default_color()
      assert %ColorInfo{} = result
    end

    test "has expected default values" do
      result = Color.get_default_color()
      assert is_struct(result, ColorInfo)
    end
  end

  describe "colors/0" do
    test "returns map of colors" do
      result = Color.colors()
      assert is_map(result)
    end

    test "contains expected color keys" do
      result = Color.colors()
      assert Map.has_key?(result, :primary)
      assert Map.has_key?(result, :secondary)
      assert Map.has_key?(result, :error)
      assert Map.has_key?(result, :success)
    end

    test "all values are ColorInfo structs" do
      result = Color.colors()
      assert Enum.all?(Map.values(result), &match?(%ColorInfo{}, &1))
    end
  end

  describe "gradients/0" do
    test "returns map of gradients" do
      result = Color.gradients()
      assert is_map(result)
    end

    test "all values are ColorInfo structs" do
      result = Color.gradients()
      assert Enum.all?(Map.values(result), &match?(%ColorInfo{}, &1))
    end
  end

  describe "get_color_info/1 edge cases" do
    test "handles nil input" do
      result = Color.get_color_info(nil)
      assert %ColorInfo{} = result
      assert result.name == :no_color
    end

    test "handles invalid atom" do
      result = Color.get_color_info(:nonexistent_color)
      assert result.name == :no_color
    end

    test "handles invalid hex string" do
      result = Color.get_color_info("notahex")
      assert result.name == :no_color
    end

    test "handles valid hex string" do
      result = Color.get_color_info("#ABCDEF")
      assert result.hex == "#ABCDEF"
      assert result.name == nil
    end

    test "handles other types" do
      assert Color.get_color_info(123).name == :no_color
      assert Color.get_color_info([]).name == :no_color
      assert Color.get_color_info(%{}).name == :no_color
    end
  end

  describe "apply_to_chunk/1" do
    test "applies color to single chunk" do
      color = %ColorInfo{hex: "#FF0000"}
      chunk = %Aurora.Structs.ChunkText{text: "Test", color: color}

      result = Color.apply_to_chunk(chunk)

      assert %Aurora.Structs.ChunkText{} = result
      assert result.text =~ "Test"
      assert result.text =~ "\e["
    end

    test "applies color to list of chunks" do
      color = %ColorInfo{hex: "#FF0000"}
      chunks = [
        %Aurora.Structs.ChunkText{text: "First", color: color},
        %Aurora.Structs.ChunkText{text: "Second", color: color}
      ]

      result = Color.apply_to_chunk(chunks)

      assert is_list(result)
      assert length(result) == 2
      assert Enum.all?(result, &match?(%Aurora.Structs.ChunkText{}, &1))
    end
  end
end
