defmodule Aurora.Format do
  @moduledoc """
  Módulo principal de formateo de texto con soporte para alineación, indentación y efectos.

  Este módulo proporciona las funcionalidades principales para formatear texto
  con colores ANSI, alineación, indentación automática basada en colores y
  efectos de terminal.

  ## Características principales

  - Formateo de texto con estructura FormatInfo
  - Alineación de texto (left, right, center, justify, center_block)
  - Indentación automática basada en tipos de color
  - Indentación manual configurable
  - Soporte para tablas y datos estructurados
  - Limpieza de códigos ANSI
  - Formateo de JSON

  ## Uso básico

      iex> chunk = %Aurora.Structs.ChunkText{text: "Hola mundo"}
      iex> format_info = %Aurora.Structs.FormatInfo{chunks: [chunk]}
      iex> Aurora.Format.format(format_info)

  ## Indentación automática

  El sistema utiliza una indentación automática basada en el tipo de color:

  - `:primary` - 1 nivel (4 espacios)
  - `:secondary`, `:info` - 2 niveles (8 espacios)
  - `:ternary` - 3 niveles (12 espacios)
  - `:quaternary`, `:menu` - 4 niveles (16 espacios)
  - `:success`, `:warning`, `:error` - 5 niveles (20 espacios)
  - `:debug` - 1 nivel (4 espacios)
  - `:no_color` - 0 niveles

  ## Alineación

  Soporta múltiples tipos de alineación:

  - `:left` - Alineación izquierda (predeterminada)
  - `:right` - Alineación derecha
  - `:center` - Centrado
  - `:justify` - Justificado
  - `:center_block` - Centrado en bloque para tablas
  """

  alias Aurora.{Color, Convert, Ensure}
  alias Aurora.Structs.{ChunkText, FormatInfo}

  @tab_size 4

  @color_tabs %{
    primary: 1,
    secondary: 2,
    ternary: 3,
    quaternary: 4,
    success: 5,
    warning: 5,
    error: 5,
    info: 2,
    debug: 1,
    menu: 4,
    no_color: 0
  }

  @doc """
  Formatea un `%FormatInfo{}` aplicando indentación, alineación y color.

  Si `chunks` es lista de listas (tabla), usa `center_block`.
  """
  @spec format(FormatInfo.t()) :: String.t()
  def format(%FormatInfo{chunks: chunks} = fmt) do
    manual_tabs = fmt.manual_tabs
    align = fmt.align || :left
    add_line = fmt.add_line || :none
    animation = fmt.animation || ""

    formatted_chunks =
      if Convert.table?(chunks) do
        center_block_align(chunks)
      else
        chunks
        |> apply_indentation(manual_tabs)
        |> align_text(align)
      end

    colored_chunks = Color.apply_to_chunk(formatted_chunks)

    output =
      colored_chunks
      |> Enum.map_join("", & &1.text)
      |> add_new_lines(add_line)

    animation <> output
  end

  @spec apply_indentation([ChunkText.t()], integer()) :: [ChunkText.t()]
  defp apply_indentation(chunks, manual_tabs) when is_integer(manual_tabs) and manual_tabs >= 0 do
    Enum.map(chunks, &indent_chunk(&1, manual_tabs))
  end

  defp apply_indentation(chunks, _manual_tabs) do
    Enum.map(chunks, fn chunk ->
      chunk = Ensure.ensure_chunk_text(chunk)

      color_name =
        case chunk.color do
          %{name: name} when is_atom(name) -> name
          _ -> :no_color
        end

      tabs = Map.get(@color_tabs, color_name, 0)
      indent_chunk(chunk, tabs)
    end)
  end

  defp indent_chunk(%ChunkText{text: text} = chunk, tabs) when is_integer(tabs) and tabs >= 0 do
    indent = String.duplicate(" ", tabs * @tab_size)
    %{chunk | text: indent <> text}
  end

  @spec align_text([ChunkText.t()], atom()) :: [ChunkText.t()]
  defp align_text(chunks, :left), do: chunks

  defp align_text(chunks, :right) do
    line = Enum.map_join(chunks, "", & &1.text)
    pad = max(terminal_width() - String.length(line), 0)

    pad_chunk = %ChunkText{
      text: String.duplicate(" ", pad),
      color: Color.get_color_info(:no_color)
    }

    [pad_chunk | chunks]
  end

  defp align_text(chunks, :center) do
    line = Enum.map_join(chunks, "", & &1.text)
    total_width = terminal_width()
    pad = max(total_width - String.length(line), 0)
    left_pad = div(pad, 2)
    right_pad = pad - left_pad

    left_chunk = %ChunkText{
      text: String.duplicate(" ", left_pad),
      color: Color.get_color_info(:no_color)
    }

    right_chunk = %ChunkText{
      text: String.duplicate(" ", right_pad),
      color: Color.get_color_info(:no_color)
    }

    [left_chunk | chunks] ++ [right_chunk]
  end

  defp align_text(chunks, :justify) do
    words = Enum.map(chunks, & &1.text)
    line = Enum.join(words, " ")
    total_width = terminal_width()
    spaces_to_add = max(total_width - String.length(line), 0)

    if spaces_to_add == 0 or length(words) == 1 do
      chunks
    else
      gaps = length(words) - 1
      space_per_gap = div(spaces_to_add, gaps)
      extra_spaces = rem(spaces_to_add, gaps)

      new_chunks =
        words
        |> Enum.with_index()
        |> Enum.map(&create_justified_chunk(&1, {space_per_gap, extra_spaces, gaps, chunks}))

      new_chunks
    end
  end

  defp create_justified_chunk({word, i}, {space_per_gap, extra_spaces, gaps, chunks}) do
    extra = if i <= extra_spaces, do: 1, else: 0
    space_count = if i < gaps, do: 1 + space_per_gap + extra, else: 0
    spaces = String.duplicate(" ", space_count)
    %ChunkText{text: word <> spaces, color: Enum.at(chunks, i).color}
  end

  @spec center_block_align([[ChunkText.t()]]) :: [[ChunkText.t()]]
  defp center_block_align(rows) when is_list(rows) do
    col_count = rows |> Enum.map(&length/1) |> Enum.max()

    col_widths =
      0..(col_count - 1)
      |> Enum.map(&calculate_column_width(rows, &1))

    Enum.map(rows, fn row ->
      Enum.with_index(row)
      |> Enum.map(fn {chunk, col} ->
        pad = col_widths |> Enum.at(col) |> Kernel.-(String.length(chunk.text))
        %{chunk | text: chunk.text <> String.duplicate(" ", pad)}
      end)
    end)
  end

  defp calculate_column_width(rows, col) do
    rows
    |> Enum.map(fn row ->
      case Enum.at(row, col) do
        %ChunkText{text: text} -> String.length(text)
        _ -> 0
      end
    end)
    |> Enum.max()
  end

  @doc """
  Limpia todos los códigos de escape ANSI de una cadena de texto.

  ## Parámetros

  - `str` - Cadena de texto que puede contener códigos ANSI

  ## Ejemplos

      iex> Aurora.Format.clean_ansi("\\e[31mRojo\\e[0m")
      "Rojo"

      iex> Aurora.Format.clean_ansi("Texto normal")
      "Texto normal"
  """
  @spec clean_ansi(String.t()) :: String.t()
  def clean_ansi(str) do
    Regex.replace(~r/\e\[[\d;?]*[a-zA-Z]/, str, "")
    |> String.replace(~r/\eP.*?\e\\/, "")
  end

  def visible_length(str) when is_binary(str) do
    str
    |> String.replace(~r/\e\[[0-9;]*m/, "")
    |> String.length()
  end

  def remove_diacritics(text) do
    text
    |> String.normalize(:nfd)
    |> String.replace(~r/\p{Mn}/u, "")
  end

  @doc """
  Formatea una cadena JSON para hacerla más legible.

  ## Parámetros

  - `str` - Cadena JSON a formatear

  ## Ejemplos

      iex> json = ~s({"name":"Juan","age":25})
      iex> Aurora.Format.pretty_json(json)

  ## Retorna

  - JSON formateado si la cadena es válida
  - La cadena original si no es JSON válido
  """
  @spec pretty_json(String.t()) :: String.t()
  def pretty_json(str) do
    case Jason.decode(str) do
      {:ok, data} -> Jason.encode_to_iodata!(data, pretty: true) |> IO.iodata_to_binary()
      _ -> str
    end
  end

  defp add_new_lines(text, :none), do: text
  defp add_new_lines(text, :before), do: "\n" <> text
  defp add_new_lines(text, :after), do: text <> "\n"
  defp add_new_lines(text, :both), do: "\n" <> text <> "\n"

  defp terminal_width do
    case :io.columns() do
      {:ok, cols} -> cols
      _ -> 80
    end
  end
end
