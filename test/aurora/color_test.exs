defmodule Aurora.ColorTest do
  use ExUnit.Case
  doctest Aurora.Color

  alias Aurora.Color
  alias Aurora.Structs.ColorInfo

  # ========== TESTS DE CONVERSIÓN BÁSICA ==========

  describe "to_color_info/1" do
    test "converts atom to ColorInfo" do
      color_info = Color.to_color_info(:primary)

      assert %ColorInfo{} = color_info
      assert color_info.name == :primary
      assert color_info.hex == "#A1E7FA"
      assert color_info.rgb == {161, 231, 250}
    end

    test "converts hex string to ColorInfo" do
      color_info = Color.to_color_info("#FF0000")

      assert %ColorInfo{} = color_info
      assert color_info.hex == "#FF0000"
      assert color_info.rgb == {255, 0, 0}
      assert color_info.name == nil
    end

    test "converts RGB tuple to ColorInfo" do
      color_info = Color.to_color_info({255, 128, 64})

      assert %ColorInfo{} = color_info
      assert color_info.hex == "#FF8040"
      assert color_info.rgb == {255, 128, 64}
    end

    test "converts ARGB tuple to ColorInfo" do
      color_info = Color.to_color_info({128, 255, 0, 0})

      assert %ColorInfo{} = color_info
      assert color_info.argb == {128, 255, 0, 0}
      assert color_info.rgb == {255, 0, 0}
      assert color_info.hex == "#FF0000"
    end

    test "handles ColorInfo input" do
      input = %ColorInfo{name: :custom, hex: "#123456"}
      color_info = Color.to_color_info(input)

      assert color_info == input
    end

    test "returns default color for invalid input" do
      color_info = Color.to_color_info("invalid")
      assert %ColorInfo{} = color_info
    end
  end

  # ========== TESTS DE CONVERSIÓN ENTRE FORMATOS ==========

  describe "hex_to_rgb/1" do
    test "converts valid hex to RGB" do
      assert Color.hex_to_rgb("#FF0000") == {255, 0, 0}
      assert Color.hex_to_rgb("#00FF00") == {0, 255, 0}
      assert Color.hex_to_rgb("#0000FF") == {0, 0, 255}
      assert Color.hex_to_rgb("#A1E7FA") == {161, 231, 250}
    end

    test "handles invalid hex" do
      assert Color.hex_to_rgb("invalid") == {0, 0, 0}
      assert Color.hex_to_rgb("#123") == {0, 0, 0}
    end
  end

  describe "rgb_to_hex/1" do
    test "converts RGB to hex" do
      assert Color.rgb_to_hex({255, 0, 0}) == "#FF0000"
      assert Color.rgb_to_hex({0, 255, 0}) == "#00FF00"
      assert Color.rgb_to_hex({0, 0, 255}) == "#0000FF"
      assert Color.rgb_to_hex({161, 231, 250}) == "#A1E7FA"
    end
  end

  describe "rgb_to_hsv/1 and hsv_to_rgb/1" do
    test "converts RGB to HSV and back" do
      test_colors = [
        # Red
        {255, 0, 0},
        # Green
        {0, 255, 0},
        # Blue
        {0, 0, 255},
        # Yellow
        {255, 255, 0},
        # Gray
        {128, 128, 128}
      ]

      for rgb <- test_colors do
        hsv = Color.rgb_to_hsv(rgb)
        assert is_tuple(hsv)
        assert tuple_size(hsv) == 3

        # Convert back to RGB
        rgb_back = Color.hsv_to_rgb(hsv)

        # Allow small rounding differences
        assert_in_delta(elem(rgb, 0), elem(rgb_back, 0), 1)
        assert_in_delta(elem(rgb, 1), elem(rgb_back, 1), 1)
        assert_in_delta(elem(rgb, 2), elem(rgb_back, 2), 1)
      end
    end

    test "specific HSV conversions" do
      # Red
      assert Color.rgb_to_hsv({255, 0, 0}) == {0.0, 1.0, 1.0}

      # Green
      {h, s, v} = Color.rgb_to_hsv({0, 255, 0})
      assert_in_delta(h, 120.0, 0.1)
      assert s == 1.0
      assert v == 1.0
    end
  end

  describe "rgb_to_hsl/1 and hsl_to_rgb/1" do
    test "converts RGB to HSL and back" do
      test_colors = [
        # Red
        {255, 0, 0},
        # Green
        {0, 255, 0},
        # Blue
        {0, 0, 255},
        # White
        {255, 255, 255}
      ]

      for rgb <- test_colors do
        hsl = Color.rgb_to_hsl(rgb)
        assert is_tuple(hsl)
        assert tuple_size(hsl) == 3

        # Convert back to RGB
        rgb_back = Color.hsl_to_rgb(hsl)

        # Allow small rounding differences
        assert_in_delta(elem(rgb, 0), elem(rgb_back, 0), 1)
        assert_in_delta(elem(rgb, 1), elem(rgb_back, 1), 1)
        assert_in_delta(elem(rgb, 2), elem(rgb_back, 2), 1)
      end
    end
  end

  describe "rgb_to_cmyk/1 and cmyk_to_rgb/1" do
    test "converts RGB to CMYK and back" do
      test_colors = [
        # Red
        {255, 0, 0},
        # Green
        {0, 255, 0},
        # Blue
        {0, 0, 255},
        # Black
        {0, 0, 0}
      ]

      for rgb <- test_colors do
        cmyk = Color.rgb_to_cmyk(rgb)
        assert is_tuple(cmyk)
        assert tuple_size(cmyk) == 4

        # Convert back to RGB
        rgb_back = Color.cmyk_to_rgb(cmyk)

        # Allow small rounding differences
        assert_in_delta(elem(rgb, 0), elem(rgb_back, 0), 1)
        assert_in_delta(elem(rgb, 1), elem(rgb_back, 1), 1)
        assert_in_delta(elem(rgb, 2), elem(rgb_back, 2), 1)
      end
    end

    test "black converts to CMYK correctly" do
      cmyk = Color.rgb_to_cmyk({0, 0, 0})
      assert cmyk == {0.0, 0.0, 0.0, 1.0}
    end
  end

  describe "rgb_to_argb/1 and argb_to_rgb/1" do
    test "converts between RGB and ARGB" do
      rgb = {255, 128, 64}
      argb = Color.rgb_to_argb(rgb)
      assert argb == {255, 255, 128, 64}

      rgb_back = Color.argb_to_rgb(argb)
      assert rgb_back == rgb
    end
  end

  # ========== TESTS DE CONVERSIÓN DIRECTA ==========

  describe "direct conversion functions" do
    test "to_hex/1 converts any format to hex" do
      assert Color.to_hex(:primary) == "#A1E7FA"
      assert Color.to_hex("#FF0000") == "#FF0000"
      assert Color.to_hex({255, 0, 0}) == "#FF0000"
    end

    test "to_rgb/1 converts any format to RGB" do
      assert Color.to_rgb(:primary) == {161, 231, 250}
      assert Color.to_rgb("#FF0000") == {255, 0, 0}
      assert Color.to_rgb({255, 0, 0}) == {255, 0, 0}
    end

    test "to_hsv/1 converts any format to HSV" do
      hsv = Color.to_hsv("#FF0000")
      assert is_tuple(hsv)
      assert tuple_size(hsv) == 3
      assert elem(hsv, 0) == 0.0
      assert elem(hsv, 1) == 1.0
      assert elem(hsv, 2) == 1.0
    end

    test "to_hsl/1 converts any format to HSL" do
      hsl = Color.to_hsl("#FF0000")
      assert is_tuple(hsl)
      assert tuple_size(hsl) == 3
    end

    test "to_cmyk/1 converts any format to CMYK" do
      cmyk = Color.to_cmyk("#FF0000")
      assert is_tuple(cmyk)
      assert tuple_size(cmyk) == 4
    end

    test "to_argb/1 converts any format to ARGB" do
      argb = Color.to_argb("#FF0000")
      assert argb == {255, 255, 0, 0}
    end
  end

  # ========== TESTS DE FORMATOS ESPECÍFICOS ==========

  describe "from_hsv/1" do
    test "creates ColorInfo from HSV" do
      # Red
      color_info = Color.from_hsv({0.0, 1.0, 1.0})

      assert %ColorInfo{} = color_info
      assert color_info.hsv == {0.0, 1.0, 1.0}
      assert color_info.rgb == {255, 0, 0}
      assert color_info.hex == "#FF0000"
    end
  end

  describe "from_hsl/1" do
    test "creates ColorInfo from HSL" do
      # Red
      color_info = Color.from_hsl({0.0, 1.0, 0.5})

      assert %ColorInfo{} = color_info
      assert color_info.hsl == {0.0, 1.0, 0.5}
      assert color_info.rgb == {255, 0, 0}
      assert color_info.hex == "#FF0000"
    end
  end

  describe "from_cmyk/1" do
    test "creates ColorInfo from CMYK" do
      # Red
      color_info = Color.from_cmyk({0.0, 1.0, 1.0, 0.0})

      assert %ColorInfo{} = color_info
      assert color_info.cmyk == {0.0, 1.0, 1.0, 0.0}
      assert color_info.rgb == {255, 0, 0}
      assert color_info.hex == "#FF0000"
    end
  end

  # ========== TESTS DE CÓDIGOS ANSI ==========

  describe "color_info_to_ansi/1" do
    test "converts ColorInfo to ANSI code" do
      color_info = Color.to_color_info(:primary)
      ansi = Color.color_info_to_ansi(color_info)

      assert is_binary(ansi)
      assert String.starts_with?(ansi, "\e[")
      assert String.contains?(ansi, "38;2")
      assert String.contains?(ansi, "161;231;250")
    end

    test "includes inversion for inverted colors" do
      base_color = Color.to_color_info(:primary)
      color_info = %ColorInfo{base_color | inverted: true}
      ansi = Color.color_info_to_ansi(color_info)

      assert String.contains?(ansi, "\e[7m")
      assert String.contains?(ansi, "38;2")
    end
  end

  describe "color_info_to_background_ansi/1" do
    test "converts ColorInfo to background ANSI code" do
      color_info = Color.to_color_info(:primary)
      ansi = Color.color_info_to_background_ansi(color_info)

      assert is_binary(ansi)
      assert String.starts_with?(ansi, "\e[")
      assert String.contains?(ansi, "48;2")
      assert String.contains?(ansi, "161;231;250")
    end
  end

  describe "apply_color/3" do
    test "applies color to text" do
      colored_text = Color.apply_color("Hello", :primary)

      assert is_binary(colored_text)
      assert String.starts_with?(colored_text, "\e[")
      assert String.ends_with?(colored_text, "Hello\e[0m")
    end

    test "applies inverted color" do
      colored_text = Color.apply_color("Hello", :primary, inverted: true)

      assert String.contains?(colored_text, "\e[7m")
      assert String.ends_with?(colored_text, "Hello\e[0m")
    end

    test "applies background color" do
      colored_text = Color.apply_color("Hello", :primary, background: true)

      assert String.contains?(colored_text, "48;2")
      assert String.ends_with?(colored_text, "Hello\e[0m")
    end
  end

  describe "apply_background_color/3" do
    test "applies background color specifically" do
      colored_text = Color.apply_background_color("Hello", :primary)

      assert String.contains?(colored_text, "48;2")
      assert String.ends_with?(colored_text, "Hello\e[0m")
    end
  end

  describe "apply_inverted_color/2" do
    test "applies inverted color specifically" do
      colored_text = Color.apply_inverted_color("Hello", :primary)

      assert String.contains?(colored_text, "\e[7m")
      assert String.ends_with?(colored_text, "Hello\e[0m")
    end
  end

  # ========== TESTS DE GESTIÓN DE CONFIGURACIÓN ==========

  describe "get_all_colors/0" do
    test "returns map of all colors and gradients" do
      all_colors = Color.get_all_colors()

      assert is_map(all_colors)
      assert Map.has_key?(all_colors, :primary)
      assert Map.has_key?(all_colors, :gradient_1)
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

  describe "get_gradient/1" do
    test "gets gradient by name" do
      gradient = Color.get_gradient(:gradient_1)

      assert is_list(gradient) or gradient == nil
      if gradient, do: assert(Enum.all?(gradient, &(%ColorInfo{} = &1)))
    end
  end

  # ========== TESTS DE MANIPULACIÓN DE COLORES ==========

  describe "aclarar/2 and oscurecer/2" do
    test "aclarar lightens color" do
      original = Color.to_color_info("#336699")
      aclarado = Color.aclarar(original, 2)

      assert aclarado.hsl != original.hsl
      assert aclarado.hex != original.hex

      # El color aclarado debería tener mayor luminosidad
      {_, _, l_original} = original.hsl
      {_, _, l_aclarado} = aclarado.hsl
      assert l_aclarado > l_original
    end

    test "oscurecer darkens color" do
      original = Color.to_color_info("#336699")
      oscurecido = Color.oscurecer(original, 2)

      assert oscurecido.hsl != original.hsl
      assert oscurecido.hex != original.hex

      # El color oscurecido debería tener menor luminosidad
      {_, _, l_original} = original.hsl
      {_, _, l_oscurecido} = oscurecido.hsl
      assert l_oscurecido < l_original
    end

    test "handles edge cases for aclarar/oscurecer" do
      color = Color.to_color_info(:primary)

      # Zero tonos no cambia el color
      assert Color.aclarar(color, 0) == color
      assert Color.oscurecer(color, 0) == color

      # No excede los límites de luminosidad
      # Más del máximo
      max_aclarado = Color.aclarar(color, 20)
      {_, _, l_max} = max_aclarado.hsl
      assert l_max <= 1.0

      # Más del mínimo
      min_oscurecido = Color.oscurecer(color, 20)
      {_, _, l_min} = min_oscurecido.hsl
      assert l_min >= 0.0
    end
  end

  # ========== TESTS DE GRADIENTES ==========

  describe "expand_gradient/1" do
    test "expands gradient colors" do
      colors = [Color.to_color_info("#FF0000"), Color.to_color_info("#0000FF")]
      expanded = Color.expand_gradient(colors)

      assert is_list(expanded)
      assert length(expanded) == 6
      assert Enum.all?(expanded, &(%ColorInfo{} = &1))
    end

    test "handles single color" do
      colors = [Color.to_color_info("#FF0000")]
      expanded = Color.expand_gradient(colors)

      assert length(expanded) == 6
      assert Enum.all?(expanded, &(&1.hex == "#FF0000"))
    end
  end

  describe "apply_gradient/2" do
    test "applies gradient to text" do
      text = "Hello World"
      colors = [:primary, :secondary]

      gradient_text = Color.apply_gradient(text, colors)

      assert is_binary(gradient_text)
      assert String.length(gradient_text) > String.length(text)
    end

    test "handles short text" do
      text = "Hi"
      colors = [:primary, :secondary]

      gradient_text = Color.apply_gradient(text, colors)
      assert is_binary(gradient_text)
    end
  end

  # ========== TESTS DE COMPATIBILIDAD ==========

  describe "get_color_info/1" do
    test "alias of to_color_info/1" do
      color1 = Color.get_color_info(:primary)
      color2 = Color.to_color_info(:primary)

      assert color1 == color2
    end
  end

  describe "gradients/0" do
    test "returns gradients configuration" do
      gradients = Color.gradients()
      assert is_map(gradients)
    end
  end

  # ========== TESTS DE RENDIMIENTO Y ESTABILIDAD ==========

  describe "performance and stability" do
    test "handles large number of conversions quickly" do
      colors = [
        :primary,
        :secondary,
        :success,
        :error,
        :warning,
        "#FF0000",
        "#00FF00",
        "#0000FF",
        {255, 0, 0},
        {0, 255, 0},
        {0, 0, 255}
      ]

      for color <- colors do
        color_info = Color.to_color_info(color)
        assert %ColorInfo{} = color_info

        # Test all conversion methods
        assert is_binary(Color.to_hex(color))
        assert is_tuple(Color.to_rgb(color))
        assert is_tuple(Color.to_hsv(color))
        assert is_tuple(Color.to_hsl(color))
        assert is_tuple(Color.to_cmyk(color))
        assert is_tuple(Color.to_argb(color))
      end
    end

    test "ansi codes are properly formatted" do
      color_info = Color.to_color_info(:primary)
      ansi = Color.color_info_to_ansi(color_info)

      # Should start with escape sequence and end with reset
      assert String.starts_with?(ansi, "\e[")
      # The reset is added by apply_color
      refute String.ends_with?(ansi, "\e[0m")
    end
  end
end
