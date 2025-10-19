defmodule Aurora.ColorTest do
  use ExUnit.Case
  doctest Aurora.Color

  alias Aurora.Color
  alias Aurora.Structs.ColorInfo

  describe "to_color_info/1" do
    test "converts atom to ColorInfo" do
      color_info = Color.to_color_info(:primary)

      assert %ColorInfo{} = color_info
      assert color_info.name == :primary
      assert color_info.hex == "#A1E7FA"
    end

    test "converts hex string to ColorInfo" do
      color_info = Color.to_color_info("#FF0000")

      assert %ColorInfo{} = color_info
      assert color_info.hex == "#FF0000"
      assert color_info.name == nil
    end

    test "returns default color for invalid input" do
      color_info = Color.to_color_info("invalid")

      assert %ColorInfo{} = color_info
      assert color_info.name == :no_color
    end

    test "handles ColorInfo input" do
      input = %ColorInfo{name: :custom, hex: "#123456"}
      color_info = Color.to_color_info(input)

      assert color_info == input
    end
  end

  describe "find_by_name/1" do
    test "finds color by name" do
      color_info = Color.find_by_name(:primary)
      assert %ColorInfo{} = color_info
      assert color_info.name == :primary
      assert color_info.hex == "#A1E7FA"
    end

    test "returns nil for non-existent color" do
      assert Color.find_by_name(:non_existent) == nil
    end
  end

  describe "aclarar/2 and oscurecer/2" do
    test "aclarar lightens color" do
      original = Color.to_color_info("#336699")
      aclarado = Color.aclarar(original, 2)

      assert aclarado.hsl != original.hsl
      assert aclarado.hex != original.hex
    end

    test "oscurecer darkens color" do
      original = Color.to_color_info("#336699")
      oscurecido = Color.oscurecer(original, 2)

      assert oscurecido.hsl != original.hsl
      assert oscurecido.hex != original.hex
    end

    test "handles edge cases for aclarar/oscurecer" do
      color = Color.to_color_info(:primary)

      # Zero tonos no cambia el color
      assert Color.aclarar(color, 0) == color
      assert Color.oscurecer(color, 0) == color
    end
  end

  describe "color_info_to_ansi/1" do
    test "converts ColorInfo to ANSI code" do
      color_info = Color.to_color_info(:primary)
      ansi = Color.color_info_to_ansi(color_info)

      assert is_binary(ansi)
      assert String.starts_with?(ansi, "\e[")
    end

    test "includes inversion for inverted colors" do
      base_color = Color.to_color_info(:primary)
      color_info = %ColorInfo{base_color | inverted: true}
      ansi = Color.color_info_to_ansi(color_info)

      assert String.contains?(ansi, "\e[7m")
    end
  end

  describe "get_all_colors/0" do
    test "returns map of all colors and gradients" do
      all_colors = Color.get_all_colors()

      assert is_map(all_colors)
      assert Map.has_key?(all_colors, :primary)
      assert Map.has_key?(all_colors, :gradient_1)
    end
  end
end
