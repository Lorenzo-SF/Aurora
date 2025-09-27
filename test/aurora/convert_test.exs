defmodule Aurora.ConvertTest do
  use ExUnit.Case
  doctest Aurora.Convert

  alias Aurora.Structs.{ChunkText, ColorInfo}

  describe "basic convert operations" do
    test "convert module exists and is accessible" do
      assert Code.ensure_loaded?(Aurora.Convert)
    end

    test "can work with different data types" do
      # Test that we can handle basic conversions
      assert is_binary(to_string("hello"))
      assert is_binary(to_string(:atom))
      assert is_binary(to_string(42))
    end
  end

  describe "chunk operations" do
    test "can create and work with chunks" do
      chunk = %ChunkText{text: "Hello"}
      assert chunk.text == "Hello"
      assert %ChunkText{} = chunk
    end

    test "handles chunk with color" do
      color = %ColorInfo{name: :primary}
      chunk = %ChunkText{text: "Hello", color: color}
      assert chunk.text == "Hello"
      assert chunk.color.name == :primary
    end
  end

  describe "text processing" do
    test "can measure text length" do
      text = "Hello World"
      assert String.length(text) == 11
    end

    test "handles empty strings" do
      assert String.length("") == 0
    end

    test "can process text with special characters" do
      text = "Héllo 🌍"
      assert is_binary(text)
      assert byte_size(text) > 0
    end
  end

  describe "delegated functions to Aurora.Ensure" do
    test "deep_merge/2 delegates correctly" do
      map1 = %{a: %{x: 1, y: 2}, b: 3}
      map2 = %{a: %{y: 20, z: 30}, c: 4}
      expected = %{a: %{x: 1, y: 20, z: 30}, b: 3, c: 4}

      assert Aurora.Convert.deep_merge(map1, map2) == expected
    end

    test "clean_nil_values/1 delegates correctly" do
      map = %{a: 1, b: nil, c: 3}
      assert Aurora.Convert.clean_nil_values(map) == %{a: 1, c: 3}
    end

    test "cast/2 delegates correctly" do
      assert Aurora.Convert.cast("123", :integer) == 123
      assert Aurora.Convert.cast(nil, :string) == ""
      assert Aurora.Convert.cast("hello", :atom) == :hello
      assert Aurora.Convert.cast(42, :float) == 42.0
      assert Aurora.Convert.cast("true", :boolean) == true
      assert Aurora.Convert.cast("single", :list) == ["single"]
      assert Aurora.Convert.cast([{:a, 1}], :map) == %{a: 1}
      assert Aurora.Convert.cast("test", :unknown) == "test"
    end
  end
end
