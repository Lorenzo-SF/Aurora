defmodule Aurora.FormatTest do
  use ExUnit.Case
  doctest Aurora.Format

  alias Aurora.Format
  alias Aurora.Structs.{ChunkText, FormatInfo}

  describe "format/1" do
    test "formats FormatInfo struct" do
      chunks = [%ChunkText{text: "Hello"}]
      format_info = %FormatInfo{chunks: chunks}

      result = Format.format(format_info)

      assert is_binary(result)
      assert String.contains?(result, "Hello")
    end

    test "formats list of chunks" do
      chunks = [%ChunkText{text: "Hello"}, %ChunkText{text: "World"}]

      result = Format.format(chunks)

      assert is_binary(result)
      assert String.contains?(result, "Hello")
      assert String.contains?(result, "World")
    end

    test "formats single value" do
      result = Format.format("Hello")

      assert is_binary(result)
      assert String.contains?(result, "Hello")
    end
  end

  describe "format_logo/2" do
    test "formats logo with gradient colors" do
      lines = ["████", "████", "████"]

      {formatted_text, gradient_hexes} = Format.format_logo(lines)

      assert is_binary(formatted_text)
      assert is_list(gradient_hexes)
      assert Enum.all?(gradient_hexes, &String.starts_with?(&1, "#"))
    end

    test "formats logo with custom options" do
      lines = ["TEST"]

      {formatted_text, _} = Format.format_logo(lines, align: :center, animation: ">>> ")

      assert is_binary(formatted_text)
    end
  end

  describe "text utilities" do
    test "clean_ansi/1 removes ANSI codes" do
      ansi_text = "\e[31mRed\e[0m text"
      clean_text = Format.clean_ansi(ansi_text)

      assert clean_text == "Red text"
    end

    test "visible_length/1 calculates length without ANSI" do
      ansi_text = "\e[1mBold\e[0m text"
      length = Format.visible_length(ansi_text)

      assert length == 9
    end

    test "remove_diacritics/1 removes accents" do
      assert Format.remove_diacritics("café") == "cafe"
      assert Format.remove_diacritics("niño") == "nino"
      assert Format.remove_diacritics("résumé") == "resume"
    end

    test "pretty_json/1 formats JSON" do
      json = ~s({"name":"John","age":30})
      pretty = Format.pretty_json(json)

      assert String.contains?(pretty, "\n")
      assert String.contains?(pretty, "name")
      assert String.contains?(pretty, "John")
    end

    test "pretty_json/1 returns original for invalid JSON" do
      invalid_json = "not json"
      result = Format.pretty_json(invalid_json)

      assert result == invalid_json
    end
  end

  describe "add_location_to_text/3" do
    test "adds ANSI location codes" do
      text = "Hello"
      result = Format.add_location_to_text(text, 5, 10)

      assert result == "\e[5;10HHello"
    end
  end
end
