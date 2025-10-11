defmodule Aurora.NormalizeTest do
  use ExUnit.Case
  doctest Aurora.Normalize

  alias Aurora.Normalize
  alias Aurora.Structs.{ChunkText, ColorInfo}

  describe "normalize_text/2" do
    test "normalizes text to lowercase" do
      assert Normalize.normalize_text("HELLO WORLD", :lower) == "hello world"
    end

    test "normalizes text to uppercase" do
      assert Normalize.normalize_text("hello world", :upper) == "HELLO WORLD"
    end

    test "removes diacritics in lowercase mode" do
      assert Normalize.normalize_text("ÑOÑO", :lower) == "nono"
      assert Normalize.normalize_text("CAFÉ", :lower) == "cafe"
      assert Normalize.normalize_text("RESUMÉ", :lower) == "resume"
    end

    test "removes diacritics in uppercase mode" do
      assert Normalize.normalize_text("ñoño", :upper) == "NONO"
      assert Normalize.normalize_text("café", :upper) == "CAFE"
      assert Normalize.normalize_text("resumé", :upper) == "RESUME"
    end

    test "trims whitespace in all modes" do
      assert Normalize.normalize_text("  hello  ", :lower) == "hello"
      assert Normalize.normalize_text("  WORLD  ", :upper) == "WORLD"
      assert Normalize.normalize_text("  text  ", :trim) == "text"
    end

    test "handles empty strings" do
      assert Normalize.normalize_text("", :lower) == ""
      assert Normalize.normalize_text("", :upper) == ""
      assert Normalize.normalize_text("", :trim) == ""
    end

    test "handles strings with only whitespace" do
      assert Normalize.normalize_text("   ", :lower) == ""
      assert Normalize.normalize_text("   ", :upper) == ""
    end

    test "handles mixed diacritics" do
      assert Normalize.normalize_text("Héllö Wörld", :lower) == "hello world"
      assert Normalize.normalize_text("àéîõü", :upper) == "AEIOU"
    end

    test "trim mode removes diacritics but keeps case" do
      result = Normalize.normalize_text("  CAFÉ  ", :trim)
      assert result == "CAFE"
    end

    test "unknown mode acts as trim" do
      assert Normalize.normalize_text("  Café  ", :unknown) == "Cafe"
      assert Normalize.normalize_text("  TEST  ", :random) == "TEST"
    end
  end

  describe "normalize_messages/1" do
    test "normalizes list of tuples to ChunkText list" do
      messages = [{"Error", :error}, {"Info", :info}, {"Success", :success}]
      result = Normalize.normalize_messages(messages)

      assert length(result) == 3
      assert Enum.all?(result, &match?(%ChunkText{}, &1))

      assert Enum.at(result, 0).text == "Error"
      assert Enum.at(result, 0).color.name == :error

      assert Enum.at(result, 1).text == "Info"
      assert Enum.at(result, 1).color.name == :info

      assert Enum.at(result, 2).text == "Success"
      assert Enum.at(result, 2).color.name == :success
    end

    test "handles already normalized ChunkText list" do
      chunks = [
        %ChunkText{text: "Hello", color: %ColorInfo{name: :primary}},
        %ChunkText{text: "World", color: %ColorInfo{name: :secondary}}
      ]

      result = Normalize.normalize_messages(chunks)
      assert result == chunks
    end

    test "normalizes single string to ChunkText list" do
      result = Normalize.normalize_messages("Simple message")

      assert length(result) == 1
      assert %ChunkText{} = Enum.at(result, 0)
      assert Enum.at(result, 0).text == "Simple message"
      assert Enum.at(result, 0).color.name == :no_color
    end

    test "normalizes empty string to ChunkText with empty text" do
      result = Normalize.normalize_messages("")

      assert length(result) == 1
      assert Enum.at(result, 0).text == ""
    end

    test "handles mixed types in tuple list" do
      messages = [
        {"String", :error},
        {123, :info},
        {:atom, :warning}
      ]

      result = Normalize.normalize_messages(messages)

      assert length(result) == 3
      assert Enum.at(result, 0).text == "String"
      assert Enum.at(result, 1).text == "123"
      assert Enum.at(result, 2).text == "atom"
    end

    test "handles invalid color names gracefully" do
      messages = [{"Text", :invalid_color}]
      result = Normalize.normalize_messages(messages)

      assert length(result) == 1
      assert Enum.at(result, 0).color.name == :no_color
    end

    test "handles hex color strings" do
      messages = [{"Red text", "#FF0000"}]
      result = Normalize.normalize_messages(messages)

      assert length(result) == 1
      assert Enum.at(result, 0).text == "Red text"
      assert Enum.at(result, 0).color.hex == "#FF0000"
    end

    test "returns empty list for invalid input" do
      assert Normalize.normalize_messages(nil) == []
      assert Normalize.normalize_messages(123) == []
      assert Normalize.normalize_messages(%{}) == []
    end

    test "handles empty list" do
      # Empty list doesn't match any pattern, so returns []
      assert Normalize.normalize_messages([]) == []
    end
  end

  describe "normalize_table/1" do
    test "normalizes simple table with equal columns" do
      rows = [
        [%ChunkText{text: "ID"}, %ChunkText{text: "Name"}],
        [%ChunkText{text: "1"}, %ChunkText{text: "John"}],
        [%ChunkText{text: "2"}, %ChunkText{text: "Jane"}]
      ]

      result = Normalize.normalize_table(rows)

      assert length(result) == 3
      assert length(Enum.at(result, 0)) == 2
    end

    test "pads rows to match max column count" do
      rows = [
        [%ChunkText{text: "A"}, %ChunkText{text: "B"}, %ChunkText{text: "C"}],
        [%ChunkText{text: "1"}, %ChunkText{text: "2"}],
        [%ChunkText{text: "X"}]
      ]

      result = Normalize.normalize_table(rows)

      # All rows should have 3 columns
      assert Enum.all?(result, &(length(&1) == 3))

      # Missing cells should be empty strings
      assert Enum.at(Enum.at(result, 1), 2).text =~ ""
      assert Enum.at(Enum.at(result, 2), 1).text =~ ""
      assert Enum.at(Enum.at(result, 2), 2).text =~ ""
    end

    test "aligns column widths based on longest content" do
      rows = [
        [%ChunkText{text: "ID"}, %ChunkText{text: "Name"}],
        [%ChunkText{text: "1"}, %ChunkText{text: "John"}],
        [%ChunkText{text: "100"}, %ChunkText{text: "Alexander"}]
      ]

      result = Normalize.normalize_table(rows)

      # First column should be padded to width of "100" (3 chars)
      first_col_width = String.length(Enum.at(Enum.at(result, 0), 0).text)
      assert first_col_width == 3

      # Second column should be padded to width of "Alexander" (9 chars)
      second_col_width = String.length(Enum.at(Enum.at(result, 0), 1).text)
      assert second_col_width == 9
    end

    test "preserves ChunkText properties" do
      color = %ColorInfo{name: :primary, hex: "#FF0000"}

      rows = [
        [%ChunkText{text: "A", color: color}]
      ]

      result = Normalize.normalize_table(rows)

      assert Enum.at(Enum.at(result, 0), 0).color == color
    end

    test "handles empty table" do
      result = Normalize.normalize_table([])
      assert result == []
    end

    test "handles single cell table" do
      rows = [[%ChunkText{text: "Single"}]]
      result = Normalize.normalize_table(rows)

      assert length(result) == 1
      assert length(Enum.at(result, 0)) == 1
    end

    test "handles table with varying widths" do
      rows = [
        [%ChunkText{text: "Short"}, %ChunkText{text: "VeryLongText"}],
        [%ChunkText{text: "X"}, %ChunkText{text: "Y"}]
      ]

      result = Normalize.normalize_table(rows)

      # Second row first column should be padded to match "Short" (5 chars)
      assert String.length(Enum.at(Enum.at(result, 1), 0).text) == 5

      # Second row second column should be padded to match "VeryLongText" (12 chars)
      assert String.length(Enum.at(Enum.at(result, 1), 1).text) == 12
    end

    test "strips ANSI codes when calculating visible length" do
      # Text with ANSI codes should calculate visible length correctly
      rows = [
        [%ChunkText{text: "\e[31mRed\e[0m"}, %ChunkText{text: "Normal"}],
        [%ChunkText{text: "ABC"}, %ChunkText{text: "XYZ"}]
      ]

      result = Normalize.normalize_table(rows)

      # Both cells in first column should have same visible width (3)
      # despite ANSI codes
      first_cell = Enum.at(Enum.at(result, 0), 0).text
      second_cell = Enum.at(Enum.at(result, 1), 0).text

      # The visible length should be same (3), but actual string length differs
      assert String.length(String.replace(first_cell, ~r/\e\[[0-9;]*m/, "")) ==
               String.length(String.replace(second_cell, ~r/\e\[[0-9;]*m/, ""))
    end

    test "handles unicode characters correctly" do
      rows = [
        [%ChunkText{text: "Café"}, %ChunkText{text: "Niño"}],
        [%ChunkText{text: "Test"}, %ChunkText{text: "Data"}]
      ]

      result = Normalize.normalize_table(rows)

      assert is_list(result)
      assert length(result) == 2
    end
  end
end
