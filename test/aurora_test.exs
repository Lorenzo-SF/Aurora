defmodule AuroraTest do
  use ExUnit.Case
  doctest Aurora

  alias Aurora.{Color, Convert, Format}
  alias Aurora.Structs.{ChunkText, FormatInfo}

  describe "basic formatting" do
    test "format with FormatInfo and chunks" do
      chunks = [
        %ChunkText{text: "Hello", color: Color.resolve_color(:primary)},
        %ChunkText{text: " World", color: Color.resolve_color(:secondary)}
      ]

      format_info = %FormatInfo{chunks: chunks}

      result = Format.format(format_info)
      assert is_binary(result)
      assert String.contains?(result, "Hello")
      assert String.contains?(result, "World")
    end
  end

  describe "chunk operations" do
    test "can create ChunkText directly" do
      chunk = %ChunkText{text: "test"}
      assert %ChunkText{text: "test"} = chunk
    end

    test "can create ChunkText with color" do
      color = Color.resolve_color(:primary)
      chunk = %ChunkText{text: "test", color: color}
      assert %ChunkText{text: "test"} = chunk
      assert chunk.color.name == :primary
    end

    test "can convert to chunks using Convert module" do
      chunk1 = Convert.to_chunk("Hello")
      chunk2 = Convert.to_chunk({"World", :primary})
      chunk3 = Convert.to_chunk("Plain text")

      chunks = [chunk1, chunk2, chunk3]
      assert length(chunks) == 3
      assert Enum.all?(chunks, &match?(%ChunkText{}, &1))
    end
  end

  describe "color operations" do
    test "can apply color to text using Color.apply_color" do
      color_info = Color.resolve_color(:primary)
      result = Color.apply_color("test", color_info)
      assert is_binary(result)
      assert String.contains?(result, "test")
    end

    test "can apply hex color to text" do
      color_info = Color.resolve_color("#FF0000")
      result = Color.apply_color("test", color_info)
      assert is_binary(result)
      assert String.contains?(result, "test")
    end
  end

  describe "effects operations" do
    test "can apply single effect using Effects module" do
      result = Aurora.Effects.apply_effect("test", :bold)
      assert is_binary(result)
      assert String.contains?(result, "test")
      assert String.contains?(result, "\e[1m")
    end

    test "can apply multiple effects using Effects module" do
      result = Aurora.Effects.apply_multiple_effects("test", [:bold, :underline])
      assert is_binary(result)
      assert String.contains?(result, "test")
      assert String.contains?(result, "\e[1m")
      assert String.contains?(result, "\e[4m")
    end
  end

  describe "utility functions" do
    test "clean removes ANSI codes using Format module" do
      colored_text = "\e[31mRed text\e[0m"
      result = Format.clean_ansi(colored_text)
      assert result == "Red text"
    end

    test "can generate gradient using Color module" do
      colors = Color.generate_gradient_between("#FF0000", "#00FF00")
      assert is_list(colors)
      assert length(colors) == 6
    end

    test "can get available colors" do
      colors = Color.colors()
      assert is_map(colors)
    end
  end

  describe "color and effects lists" do
    test "can get effects from Effects module" do
      effects = Aurora.Effects.available_effects()
      assert is_list(effects)
      assert :bold in effects
      assert :italic in effects
    end
  end

  describe "table formatting" do
    test "can format table data using Convert" do
      table_data = [
        [%ChunkText{text: "ID"}, %ChunkText{text: "Name"}],
        [%ChunkText{text: "1"}, %ChunkText{text: "John"}],
        [%ChunkText{text: "2"}, %ChunkText{text: "Jane"}]
      ]

      assert Convert.table?(table_data) == true

      normalized = Convert.normalize_table(table_data)
      assert is_list(normalized)
    end
  end

  describe "JSON formatting" do
    test "can format JSON using Format module" do
      json_string = ~s({"name":"John","age":30})
      result = Format.pretty_json(json_string)
      assert is_binary(result)
      assert String.contains?(result, "name")
      assert String.contains?(result, "John")
    end

    test "invalid JSON returns original using Format module" do
      invalid_json = "not json"
      result = Format.pretty_json(invalid_json)
      assert result == invalid_json
    end
  end

  describe "Aurora.json/2 function" do
    test "formats JSON from string" do
      json_string = ~s({"name":"John","age":30})
      result = Aurora.json(json_string)
      assert is_binary(result)
      assert String.contains?(result, "name")
      assert String.contains?(result, "John")
    end

    test "formats JSON from map" do
      data = %{name: "John", age: 30}
      result = Aurora.json(data)
      assert is_binary(result)
      assert String.contains?(result, "name")
      assert String.contains?(result, "John")
    end

    test "formats JSON with color option" do
      data = %{status: "ok"}
      result = Aurora.json(data, color: :success)
      assert is_binary(result)
      assert String.contains?(result, "status")
    end

    test "formats JSON with compact option" do
      data = %{a: 1, b: 2}
      result = Aurora.json(data, compact: true)
      assert is_binary(result)
      # Compact format should not have pretty printing
      refute String.contains?(result, "\n  ")
    end

    test "formats JSON with indent option" do
      data = %{a: 1}
      result = Aurora.json(data, indent: true)
      assert is_binary(result)
      # Should have extra indentation
      assert String.contains?(result, "  ")
    end
  end

  describe "Aurora.format/2 with different input types" do
    test "formats single string text" do
      result = Aurora.format("Hello", color: :primary)
      assert is_binary(result)
      assert String.contains?(result, "Hello")
    end

    test "formats list of strings" do
      result = Aurora.format(["Hello", "World"], color: :primary)
      assert is_binary(result)
      assert String.contains?(result, "Hello")
      assert String.contains?(result, "World")
    end

    test "formats with alignment options" do
      result = Aurora.format("Test", align: :center)
      assert is_binary(result)
      assert String.contains?(result, "Test")
    end

    test "formats with bold effect" do
      result = Aurora.format("Bold", bold: true)
      assert is_binary(result)
      assert String.contains?(result, "Bold")
      # Bold ANSI code
      assert String.contains?(result, "\e[1m")
    end
  end

  describe "gradient function optimization" do
    test "gradient function uses Enum.take correctly" do
      result = Aurora.gradient("#FF0000", "#00FF00", 3)
      assert length(result) == 3
      assert is_list(result)
    end

    test "gradient function with default 6 steps" do
      result = Aurora.gradient("#FF0000", "#00FF00")
      assert length(result) == 6
    end
  end
end
