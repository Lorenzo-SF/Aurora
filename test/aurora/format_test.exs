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
end
