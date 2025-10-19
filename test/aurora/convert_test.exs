defmodule Aurora.ConvertTest do
  use ExUnit.Case
  doctest Aurora.Convert

  alias Aurora.Convert
  alias Aurora.Structs.{ChunkText, ColorInfo, EffectInfo, FormatInfo}

  describe "to/2" do
    test "converts to native Elixir types" do
      assert Convert.to("hello", :string) == "hello"
      assert Convert.to("123", :integer) == 123
      assert Convert.to("3.14", :float) == 3.14
      assert Convert.to("true", :boolean) == true
      assert Convert.to("hello", :atom) == :hello
      assert Convert.to("single", :list) == ["single"]
      assert Convert.to([a: 1], :map) == %{a: 1}
    end

    test "converts to Aurora structs" do
      assert %ChunkText{} = Convert.to("text", ChunkText)
      assert %ColorInfo{} = Convert.to(:primary, ColorInfo)
      assert %FormatInfo{} = Convert.to([], FormatInfo)
      assert %EffectInfo{} = Convert.to(%{}, EffectInfo)
    end

    test "handles external conversions" do
      assert Convert.to("2023-01-01", {:external, Date, :from_iso8601!}) == ~D[2023-01-01]
    end
  end

  describe "to_chunk/1" do
    test "converts various inputs to ChunkText" do
      assert %ChunkText{text: "hello"} = Convert.to_chunk("hello")
      assert %ChunkText{text: "world"} = Convert.to_chunk(:world)
      assert %ChunkText{text: "42"} = Convert.to_chunk(42)
      assert %ChunkText{text: "test", color: %ColorInfo{}} = Convert.to_chunk({"test", :primary})
    end

    test "preserves existing ChunkText" do
      chunk = %ChunkText{text: "original"}
      assert Convert.to_chunk(chunk) == chunk
    end
  end

  describe "normalize_text/2" do
    test "normalizes text to lowercase" do
      assert Convert.normalize_text("HELLO", :lower) == "hello"
    end

    test "normalizes text to uppercase" do
      assert Convert.normalize_text("hello", :upper) == "HELLO"
    end

    test "removes diacritics" do
      assert Convert.normalize_text("café", :lower) == "cafe"
      assert Convert.normalize_text("ÑOÑO", :upper) == "NONO"
    end
  end

  describe "visible_length/1" do
    test "calculates length without ANSI codes" do
      ansi_text = "\e[31mHello\e[0m"
      assert Convert.visible_length(ansi_text) == 5
    end

    test "handles ChunkText input" do
      chunk = %ChunkText{text: "\e[31mHello\e[0m"}
      assert Convert.visible_length(chunk) == 5
    end
  end

  describe "map_list/2" do
    test "converts list of values to specified type" do
      input = ["1", "2", "3"]
      result = Convert.map_list(input, :integer)

      assert result == [1, 2, 3]
    end

    test "handles single value" do
      assert Convert.map_list("hello", :string) == ["hello"]
    end
  end

  describe "atomize_keys/1 and stringify_keys/1" do
    test "converts map keys between atoms and strings" do
      atom_map = %{hello: "world", nested: %{test: "value"}}
      string_map = %{"hello" => "world", "nested" => %{"test" => "value"}}

      assert Convert.stringify_keys(atom_map) == string_map
      assert Convert.atomize_keys(string_map) == atom_map
    end
  end
end
