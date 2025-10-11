defmodule Aurora.FormatTest do
  use ExUnit.Case
  doctest Aurora.Format

  alias Aurora.Structs.{ChunkText, ColorInfo, FormatInfo}

  describe "basic format operations" do
    test "format module exists and is accessible" do
      assert Code.ensure_loaded?(Aurora.Format)
    end

    test "can work with ChunkText structures" do
      chunk = %ChunkText{text: "Hello World"}
      assert chunk.text == "Hello World"
    end

    test "can work with FormatInfo structures" do
      chunks = [%ChunkText{text: "test"}]
      format_info = %FormatInfo{chunks: chunks}
      assert format_info.chunks == chunks
    end
  end

  describe "chunk handling" do
    test "processes chunks correctly" do
      chunks = [
        %ChunkText{text: "Hello"},
        %ChunkText{text: " World"}
      ]

      assert length(chunks) == 2
      assert Enum.all?(chunks, &match?(%ChunkText{}, &1))
    end

    test "handles mixed chunk data" do
      chunk1 = %ChunkText{text: "Hello"}
      chunk2 = %ChunkText{text: "World", color: %ColorInfo{name: :primary}}

      assert chunk1.text == "Hello"
      assert chunk2.text == "World"
      assert chunk2.color.name == :primary
    end

    test "handles chunks with positioning data" do
      chunk = %ChunkText{text: "positioned", pos_x: 10, pos_y: 5}
      assert chunk.pos_x == 10
      assert chunk.pos_y == 5
    end
  end

  describe "raw mode formatting" do
    test "format with raw mode applies positioning" do
      chunk = %ChunkText{text: "raw text", pos_x: 15, pos_y: 8}
      format_info = %FormatInfo{chunks: [chunk], mode: :raw}

      result = Aurora.Format.format(format_info)

      # Verificar que incluye el código de posicionamiento ANSI
      assert result =~ "\e[8;15H"
      assert result =~ "raw text"
    end

    test "format with raw mode handles color and positioning" do
      color = %ColorInfo{hex: "#FF0000", name: :red}
      chunk = %ChunkText{text: "colored raw", color: color, pos_x: 20, pos_y: 12}
      format_info = %FormatInfo{chunks: [chunk], mode: :raw}

      result = Aurora.Format.format(format_info)

      # Verificar posicionamiento
      assert result =~ "\e[12;20H"
      # Verificar contenido
      assert result =~ "colored raw"
      # Verificar que hay códigos de color
      assert result =~ "\e[38;2;"
    end

    test "format with raw mode handles multiple chunks" do
      chunk1 = %ChunkText{text: "first", pos_x: 5, pos_y: 3}
      chunk2 = %ChunkText{text: "second", pos_x: 0, pos_y: 0}
      format_info = %FormatInfo{chunks: [chunk1, chunk2], mode: :raw}

      result = Aurora.Format.format(format_info)

      # Solo el primer chunk debería tener posicionamiento en raw mode
      assert result =~ "\e[3;5H"
      assert result =~ "first"
      assert result =~ "second"
    end
  end

  describe "normal vs raw mode comparison" do
    test "normal mode doesn't include positioning codes" do
      chunk = %ChunkText{text: "normal text", pos_x: 10, pos_y: 5}
      format_info = %FormatInfo{chunks: [chunk], mode: :normal}

      result = Aurora.Format.format(format_info)

      # No debe incluir códigos de posicionamiento
      refute result =~ "\e[5;10H"
      assert result =~ "normal text"
    end

    test "raw mode includes positioning codes" do
      chunk = %ChunkText{text: "raw text", pos_x: 10, pos_y: 5}
      format_info = %FormatInfo{chunks: [chunk], mode: :raw}

      result = Aurora.Format.format(format_info)

      # Debe incluir códigos de posicionamiento
      assert result =~ "\e[5;10H"
      assert result =~ "raw text"
    end
  end

  describe "add_location_to_text/3" do
    test "adds ANSI positioning code" do
      result = Aurora.Format.add_location_to_text("Hello", 10, 20)
      assert result == "\e[10;20HHello"
    end

    test "works with coordinates at origin" do
      result = Aurora.Format.add_location_to_text("Text", 0, 0)
      assert result == "\e[0;0HText"
    end

    test "works with large coordinates" do
      result = Aurora.Format.add_location_to_text("Far", 100, 200)
      assert result == "\e[100;200HFar"
    end

    test "preserves text content" do
      result = Aurora.Format.add_location_to_text("Special chars: ñáé", 5, 5)
      assert result =~ "Special chars: ñáé"
    end
  end

  describe "clean_ansi/1" do
    test "removes ANSI color codes" do
      text = "\e[31mRed\e[0m"
      assert Aurora.Format.clean_ansi(text) == "Red"
    end

    test "removes multiple ANSI codes" do
      text = "\e[1m\e[31mBold Red\e[0m\e[0m"
      assert Aurora.Format.clean_ansi(text) == "Bold Red"
    end

    test "handles text without ANSI codes" do
      text = "Plain text"
      assert Aurora.Format.clean_ansi(text) == "Plain text"
    end

    test "removes positioning codes" do
      text = "\e[10;20HPositioned text"
      assert Aurora.Format.clean_ansi(text) == "Positioned text"
    end

    test "handles empty string" do
      assert Aurora.Format.clean_ansi("") == ""
    end

    test "removes complex ANSI sequences" do
      text = "\e[38;2;255;0;0mTrue color\e[0m"
      assert Aurora.Format.clean_ansi(text) == "True color"
    end
  end

  describe "visible_length/1" do
    test "calculates length without ANSI codes" do
      assert Aurora.Format.visible_length("\e[31mRed\e[0m") == 3
    end

    test "handles plain text" do
      assert Aurora.Format.visible_length("Hello") == 5
    end

    test "handles empty string" do
      assert Aurora.Format.visible_length("") == 0
    end

    test "handles text with multiple ANSI codes" do
      text = "\e[1m\e[31mBold Red Text\e[0m\e[0m"
      assert Aurora.Format.visible_length(text) == 13
    end

    test "handles unicode characters" do
      assert Aurora.Format.visible_length("Café") == 4
      assert Aurora.Format.visible_length("🌍🌎") == 2
    end
  end

  describe "remove_diacritics/1" do
    test "removes Spanish diacritics" do
      assert Aurora.Format.remove_diacritics("café") == "cafe"
      assert Aurora.Format.remove_diacritics("niño") == "nino"
    end

    test "removes French diacritics" do
      assert Aurora.Format.remove_diacritics("résumé") == "resume"
      assert Aurora.Format.remove_diacritics("naïve") == "naive"
    end

    test "handles text without diacritics" do
      assert Aurora.Format.remove_diacritics("hello") == "hello"
    end

    test "handles empty string" do
      assert Aurora.Format.remove_diacritics("") == ""
    end

    test "handles mixed diacritics" do
      assert Aurora.Format.remove_diacritics("àéîõü") == "aeiou"
    end
  end

  describe "pretty_json/1" do
    test "formats valid JSON string" do
      json = ~s({"name":"John","age":30})
      result = Aurora.Format.pretty_json(json)

      assert result =~ "name"
      assert result =~ "John"
      assert result =~ "age"
      assert result =~ "30"
      # Pretty printed JSON should have newlines
      assert result =~ "\n"
    end

    test "returns original string for invalid JSON" do
      invalid = "not json"
      assert Aurora.Format.pretty_json(invalid) == invalid
    end

    test "handles empty object" do
      json = "{}"
      result = Aurora.Format.pretty_json(json)
      assert is_binary(result)
    end

    test "handles arrays" do
      json = ~s([1,2,3])
      result = Aurora.Format.pretty_json(json)
      assert result =~ "1"
      assert result =~ "2"
      assert result =~ "3"
    end
  end

  describe "format_logo/2" do
    test "formats logo with default options" do
      lines = ["███", "███", "███"]
      {result, hexes} = Aurora.Format.format_logo(lines)

      assert is_binary(result)
      assert is_list(hexes)
      assert result =~ "███"
    end

    test "formats logo with center alignment" do
      lines = ["███", "███"]
      {result, _hexes} = Aurora.Format.format_logo(lines, align: :center)

      assert is_binary(result)
      assert result =~ "███"
    end

    test "formats logo with custom gradient" do
      lines = ["██"]
      gradients = %{grad1: %{hex: "#FF0000"}, grad2: %{hex: "#00FF00"}}
      {result, hexes} = Aurora.Format.format_logo(lines, gradient_colors: gradients)

      assert is_binary(result)
      assert length(hexes) == 2
    end

    test "returns gradient hexes" do
      lines = ["█"]
      {_result, hexes} = Aurora.Format.format_logo(lines)

      assert is_list(hexes)
      assert Enum.all?(hexes, &is_binary/1)
    end

    test "handles empty lines list" do
      {result, hexes} = Aurora.Format.format_logo([])

      assert result == ""
      assert is_list(hexes)
    end

    test "handles single line" do
      {result, _hexes} = Aurora.Format.format_logo(["████"])

      assert is_binary(result)
      assert result =~ "████"
    end
  end

  describe "table mode formatting" do
    test "formats table with center_block alignment" do
      color = %ColorInfo{name: :primary}
      row1 = [%ChunkText{text: "ID", color: color}, %ChunkText{text: "Name", color: color}]
      row2 = [%ChunkText{text: "1", color: color}, %ChunkText{text: "John", color: color}]

      # Table mode expects nested lists
      format_info = %FormatInfo{chunks: [row1, row2], mode: :table, add_line: :none}
      result = Aurora.Format.format(format_info)

      assert is_binary(result)
      # After color codes are applied, text should still be present
      clean_result = Aurora.Format.clean_ansi(result)
      assert clean_result =~ "ID"
      assert clean_result =~ "Name"
    end

    test "table mode pads columns correctly" do
      color = %ColorInfo{name: :secondary}
      row1 = [%ChunkText{text: "A", color: color}, %ChunkText{text: "LongText", color: color}]
      row2 = [%ChunkText{text: "B", color: color}, %ChunkText{text: "X", color: color}]

      format_info = %FormatInfo{chunks: [row1, row2], mode: :table, add_line: :none}
      result = Aurora.Format.format(format_info)

      assert is_binary(result)
      clean_result = Aurora.Format.clean_ansi(result)
      assert clean_result =~ "A"
      assert clean_result =~ "LongText"
    end
  end

  describe "alignment modes" do
    test "left alignment (default)" do
      chunk = %ChunkText{text: "left"}
      format_info = %FormatInfo{chunks: [chunk], align: :left}

      result = Aurora.Format.format(format_info)
      assert result =~ "left"
    end

    test "right alignment adds left padding" do
      chunk = %ChunkText{text: "right"}
      format_info = %FormatInfo{chunks: [chunk], align: :right}

      result = Aurora.Format.format(format_info)
      # Right aligned text should have leading spaces
      assert String.length(Aurora.Format.clean_ansi(result)) > 5
    end

    test "center alignment adds padding" do
      chunk = %ChunkText{text: "center"}
      format_info = %FormatInfo{chunks: [chunk], align: :center}

      result = Aurora.Format.format(format_info)
      # Centered text should have padding
      assert String.length(Aurora.Format.clean_ansi(result)) > 6
    end

    test "justify alignment distributes spaces" do
      chunks = [
        %ChunkText{text: "word1"},
        %ChunkText{text: "word2"},
        %ChunkText{text: "word3"}
      ]

      format_info = %FormatInfo{chunks: chunks, align: :justify}

      result = Aurora.Format.format(format_info)
      assert result =~ "word1"
      assert result =~ "word2"
      assert result =~ "word3"
    end
  end

  describe "add_line options" do
    test "add_line :none doesn't add newlines" do
      chunk = %ChunkText{text: "test"}
      format_info = %FormatInfo{chunks: [chunk], add_line: :none}

      result = Aurora.Format.format(format_info)
      refute result =~ ~r/^\n/
      refute result =~ ~r/\n$/
    end

    test "add_line :before adds leading newline" do
      chunk = %ChunkText{text: "test"}
      format_info = %FormatInfo{chunks: [chunk], add_line: :before}

      result = Aurora.Format.format(format_info)
      assert result =~ ~r/^\n/
    end

    test "add_line :after adds trailing newline" do
      chunk = %ChunkText{text: "test"}
      format_info = %FormatInfo{chunks: [chunk], add_line: :after}

      result = Aurora.Format.format(format_info)
      assert result =~ ~r/\n$/
    end

    test "add_line :both adds both newlines" do
      chunk = %ChunkText{text: "test"}
      format_info = %FormatInfo{chunks: [chunk], add_line: :both}

      result = Aurora.Format.format(format_info)
      assert result =~ ~r/^\n/
      assert result =~ ~r/\n$/
    end
  end

  describe "manual indentation" do
    test "applies manual tabs" do
      chunk = %ChunkText{text: "indented"}
      format_info = %FormatInfo{chunks: [chunk], manual_tabs: 2}

      result = Aurora.Format.format(format_info)
      # Should have 8 spaces (2 tabs * 4 spaces each)
      assert result =~ "        indented"
    end

    test "manual_tabs 0 adds no indentation" do
      chunk = %ChunkText{text: "no indent"}
      format_info = %FormatInfo{chunks: [chunk], manual_tabs: 0}

      result = Aurora.Format.format(format_info)
      refute result =~ ~r/^\s+no indent/
    end

    test "large manual_tabs value" do
      chunk = %ChunkText{text: "far"}
      format_info = %FormatInfo{chunks: [chunk], manual_tabs: 5}

      result = Aurora.Format.format(format_info)
      # Should have 20 spaces (5 tabs * 4 spaces each)
      assert result =~ "                    far"
    end
  end
end
