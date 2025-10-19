defmodule Aurora.Structs.ColorInfoTest do
  use ExUnit.Case
  doctest Aurora.Structs.ColorInfo

  alias Aurora.Structs.ColorInfo

  describe "ColorInfo struct" do
    test "has correct default values from no_color config" do
      color_info = %ColorInfo{}

      assert color_info.hex == "#F8F8F2"
      assert color_info.rgb == {248, 248, 242}
      assert color_info.argb == {255, 248, 248, 242}
      assert color_info.name == :no_color
      assert color_info.inverted == false
    end

    test "all fields have default values" do
      color_info = %ColorInfo{}

      refute is_nil(color_info.hex)
      refute is_nil(color_info.rgb)
      refute is_nil(color_info.argb)
      refute is_nil(color_info.hsv)
      refute is_nil(color_info.hsl)
      refute is_nil(color_info.cmyk)
      refute is_nil(color_info.name)
      refute is_nil(color_info.inverted)
    end

    test "type specifications are correct" do
      color_info = %ColorInfo{}

      assert is_binary(color_info.hex)
      assert is_tuple(color_info.rgb)
      assert is_tuple(color_info.argb)
      assert is_tuple(color_info.hsv)
      assert is_tuple(color_info.hsl)
      assert is_tuple(color_info.cmyk)
      assert is_atom(color_info.name)
      assert is_boolean(color_info.inverted)
    end
  end
end

defmodule Aurora.Structs.EffectInfoTest do
  use ExUnit.Case
  doctest Aurora.Structs.EffectInfo

  alias Aurora.Structs.EffectInfo

  describe "EffectInfo struct" do
    test "has all boolean fields with false defaults" do
      effect_info = %EffectInfo{}

      assert effect_info.bold == false
      assert effect_info.dim == false
      assert effect_info.italic == false
      assert effect_info.underline == false
      assert effect_info.blink == false
      assert effect_info.reverse == false
      assert effect_info.hidden == false
      assert effect_info.strikethrough == false
      assert effect_info.link == false
    end

    test "can enable specific effects" do
      effect_info = %EffectInfo{
        bold: true,
        italic: true,
        underline: true
      }

      assert effect_info.bold == true
      assert effect_info.italic == true
      assert effect_info.underline == true
      assert effect_info.blink == false
    end

    test "all effects can be enabled" do
      effect_info = %EffectInfo{
        bold: true,
        dim: true,
        italic: true,
        underline: true,
        blink: true,
        reverse: true,
        hidden: true,
        strikethrough: true,
        link: true
      }

      # Verifica que todos los campos de efecto estén en true (ignora el campo __struct__)
      effect_fields = Map.delete(Map.from_struct(effect_info), :__struct__)
      assert Enum.all?(effect_fields, fn {_k, v} -> v == true end)
    end
  end
end

defmodule Aurora.Structs.ChunkTextTest do
  use ExUnit.Case
  doctest Aurora.Structs.ChunkText

  alias Aurora.Structs.{ChunkText, ColorInfo, EffectInfo}

  describe "ChunkText struct" do
    test "requires text field" do
      assert_raise ArgumentError,
                   "the following keys must also be given when building struct Aurora.Structs.ChunkText: [:text]",
                   fn ->
                     struct!(ChunkText, [])
                   end
    end

    test "creates chunk with minimal required fields" do
      chunk = %ChunkText{text: "Hello"}

      assert chunk.text == "Hello"
      assert chunk.color == nil
      assert chunk.effects == nil
      assert chunk.pos_x == 0
      assert chunk.pos_y == 0
    end

    test "creates chunk with all fields" do
      color = %ColorInfo{name: :primary}
      effects = %EffectInfo{bold: true}

      chunk = %ChunkText{
        text: "Hello",
        color: color,
        effects: effects,
        pos_x: 10,
        pos_y: 5
      }

      assert chunk.text == "Hello"
      assert chunk.color == color
      assert chunk.effects == effects
      assert chunk.pos_x == 10
      assert chunk.pos_y == 5
    end

    test "type specifications are correct" do
      chunk = %ChunkText{text: "test"}

      assert is_binary(chunk.text)
      assert chunk.color == nil || match?(%ColorInfo{}, chunk.color)
      assert chunk.effects == nil || match?(%EffectInfo{}, chunk.effects)
      assert is_integer(chunk.pos_x)
      assert is_integer(chunk.pos_y)
    end
  end
end

defmodule Aurora.Structs.FormatInfoTest do
  use ExUnit.Case
  doctest Aurora.Structs.FormatInfo

  alias Aurora.Structs.{ChunkText, ColorInfo, FormatInfo}

  describe "FormatInfo struct" do
    test "requires chunks field" do
      assert_raise ArgumentError,
                   "the following keys must also be given when building struct Aurora.Structs.FormatInfo: [:chunks]",
                   fn ->
                     struct!(FormatInfo, [])
                   end
    end

    test "creates format info with minimal required fields" do
      chunks = [%ChunkText{text: "Hello"}]
      format_info = %FormatInfo{chunks: chunks}

      assert format_info.chunks == chunks
      assert format_info.default_color == nil
      assert format_info.align == :left
      assert format_info.manual_tabs == -1
      assert format_info.add_line == :none
      assert format_info.animation == ""
      assert format_info.mode == :normal
    end

    test "creates format info with all fields" do
      chunks = [%ChunkText{text: "Hello"}]
      default_color = %ColorInfo{name: :primary}

      format_info = %FormatInfo{
        chunks: chunks,
        default_color: default_color,
        align: :center,
        manual_tabs: 2,
        add_line: :both,
        animation: ">>> ",
        mode: :table
      }

      assert format_info.chunks == chunks
      assert format_info.default_color == default_color
      assert format_info.align == :center
      assert format_info.manual_tabs == 2
      assert format_info.add_line == :both
      assert format_info.animation == ">>> "
      assert format_info.mode == :table
    end

    test "validates alignment types" do
      chunks = [%ChunkText{text: "test"}]

      valid_aligns = [:left, :right, :center, :center_block, :justify]

      for align <- valid_aligns do
        format_info = %FormatInfo{chunks: chunks, align: align}
        assert format_info.align == align
      end
    end

    test "validates mode types" do
      chunks = [%ChunkText{text: "test"}]

      valid_modes = [:normal, :table, :raw]

      for mode <- valid_modes do
        format_info = %FormatInfo{chunks: chunks, mode: mode}
        assert format_info.mode == mode
      end
    end
  end
end
