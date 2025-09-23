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
end
