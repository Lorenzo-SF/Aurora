defmodule Aurora.StructsTest do
  use ExUnit.Case

  alias Aurora.Structs.{ChunkText, ColorInfo, EffectInfo, FormatInfo}

  describe "ChunkText" do
    test "creates ChunkText struct" do
      chunk = %ChunkText{text: "Hello"}

      assert %ChunkText{
               text: "Hello",
               color: nil,
               effects: nil
             } = chunk
    end

    test "creates ChunkText with color" do
      color = %ColorInfo{name: :primary, hex: "#0000FF"}
      chunk = %ChunkText{text: "Hello", color: color}

      assert %ChunkText{
               text: "Hello",
               color: %ColorInfo{name: :primary}
             } = chunk
    end

    test "creates ChunkText with effects" do
      effects = %EffectInfo{bold: true}
      chunk = %ChunkText{text: "Hello", effects: effects}

      assert %ChunkText{
               text: "Hello",
               effects: %EffectInfo{bold: true}
             } = chunk
    end

    test "handles empty text" do
      chunk = %ChunkText{text: ""}
      assert %ChunkText{text: ""} = chunk
    end

    test "requires text field" do
      assert_raise ArgumentError, fn ->
        struct!(ChunkText, %{})
      end
    end
  end

  describe "ColorInfo" do
    test "creates ColorInfo with defaults" do
      color = %ColorInfo{}

      assert %ColorInfo{
               hex: _,
               name: _,
               inverted: false
             } = color
    end

    test "creates ColorInfo with custom values" do
      color = %ColorInfo{name: :primary, hex: "#0000FF", inverted: true}

      assert %ColorInfo{
               name: :primary,
               hex: "#0000FF",
               inverted: true
             } = color
    end

    test "creates ColorInfo with hex only" do
      color = %ColorInfo{hex: "#FF0000"}
      assert %ColorInfo{hex: "#FF0000"} = color
    end

    test "creates ColorInfo with name only" do
      color = %ColorInfo{name: :success}
      assert %ColorInfo{name: :success} = color
    end

    test "handles inverted colors" do
      color = %ColorInfo{name: :primary, inverted: true}
      assert color.inverted == true
    end
  end

  describe "FormatInfo" do
    test "creates FormatInfo with defaults" do
      chunks = [%ChunkText{text: "test"}]
      format = %FormatInfo{chunks: chunks}

      assert %FormatInfo{
               chunks: [%ChunkText{text: "test"}],
               default_color: nil,
               align: :left,
               manual_tabs: -1,
               add_line: :none,
               animation: ""
             } = format
    end

    test "creates FormatInfo with all options" do
      chunks = [%ChunkText{text: "test"}]
      color = %ColorInfo{name: :primary}

      format = %FormatInfo{
        chunks: chunks,
        default_color: color,
        align: :center,
        manual_tabs: 2,
        add_line: :both,
        animation: "⏳ "
      }

      assert %FormatInfo{
               chunks: ^chunks,
               default_color: %ColorInfo{name: :primary},
               align: :center,
               manual_tabs: 2,
               add_line: :both,
               animation: "⏳ "
             } = format
    end

    test "requires chunks field" do
      assert_raise ArgumentError, fn ->
        struct!(FormatInfo, %{})
      end
    end

    test "handles different alignment options" do
      chunks = [%ChunkText{text: "test"}]
      alignments = [:left, :right, :center, :justify, :center_block]

      for align <- alignments do
        format = %FormatInfo{chunks: chunks, align: align}
        assert %FormatInfo{align: ^align} = format
      end
    end

    test "handles line break options" do
      chunks = [%ChunkText{text: "test"}]
      line_options = [:before, :after, :both, :none]

      for option <- line_options do
        format = %FormatInfo{chunks: chunks, add_line: option}
        assert %FormatInfo{add_line: ^option} = format
      end
    end
  end

  describe "struct updates" do
    test "updates ChunkText fields" do
      chunk = %ChunkText{text: "Hello"}
      effects = %EffectInfo{bold: true}
      updated = %{chunk | text: "Updated", effects: effects}

      assert updated.text == "Updated"
      assert updated.effects.bold == true
      assert updated.color == chunk.color
    end

    test "updates ColorInfo fields" do
      color = %ColorInfo{name: :primary}
      updated = %{color | name: :secondary, inverted: true}

      assert updated.name == :secondary
      assert updated.inverted == true
    end

    test "updates FormatInfo fields" do
      chunks = [%ChunkText{text: "test"}]
      format = %FormatInfo{chunks: chunks}
      updated = %{format | align: :center, manual_tabs: 2}

      assert updated.align == :center
      assert updated.manual_tabs == 2
      assert updated.chunks == chunks
    end
  end

  describe "EffectInfo" do
    test "creates EffectInfo with defaults" do
      effects = %EffectInfo{}

      assert %EffectInfo{
               bold: false,
               dim: false,
               italic: false,
               underline: false,
               blink: false,
               reverse: false,
               hidden: false,
               strikethrough: false,
               link: false
             } = effects
    end

    test "creates EffectInfo with custom values" do
      effects = %EffectInfo{bold: true, italic: true, underline: true}

      assert %EffectInfo{
               bold: true,
               italic: true,
               underline: true,
               dim: false,
               blink: false,
               link: false
             } = effects
    end

    test "creates EffectInfo with all effects enabled" do
      effects = %EffectInfo{
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

      assert effects.bold == true
      assert effects.dim == true
      assert effects.italic == true
      assert effects.underline == true
      assert effects.blink == true
      assert effects.reverse == true
      assert effects.hidden == true
      assert effects.strikethrough == true
      assert effects.link == true
    end

    test "updates EffectInfo fields" do
      effects = %EffectInfo{}
      updated = %{effects | bold: true, italic: true}

      assert updated.bold == true
      assert updated.italic == true
      assert updated.dim == false
    end
  end
end
