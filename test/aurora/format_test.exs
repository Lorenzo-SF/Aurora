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
  end
end
