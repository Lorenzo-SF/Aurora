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

  alias Aurora.{Color, Convert, Effects, Ensure}
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

  Acepta FormatInfo, lista de chunks, o cualquier valor convertible a FormatInfo.
  """
  @spec format(FormatInfo.t() | [any()] | any()) :: String.t()
  def format(%FormatInfo{} = format_info) do
    %FormatInfo{
      chunks: chunks,
      manual_tabs: manual_tabs,
      align: align,
      add_line: add_line,
      animation: animation,
      mode: mode
    } = format_info

    case mode do
      :table -> format_table(chunks, add_line, animation)
      :raw -> format_raw(chunks, add_line, animation)
      _ -> format_normal(chunks, manual_tabs, align, add_line, animation)
    end
  end

  def format(chunks) when is_list(chunks) do
    format_info = Convert.to_format_info(chunks)
    format(format_info)
  end

  def format(value) do
    chunks = Convert.map_list(Ensure.list(value), ChunkText)
    format_info = %FormatInfo{chunks: chunks}
    format(format_info)
  end

  @doc """
  Agrega códigos ANSI de posicionamiento a un texto para renderizado en coordenadas específicas.

  ## Parámetros

  - `text` - El texto a posicionar
  - `pos_y` - Coordenada Y (fila)
  - `pos_x` - Coordenada X (columna)

  ## Examples

      iex> Aurora.Format.add_location_to_text("Hola", 5, 10)
      "\\e[5;10HHola"
  """
  @spec add_location_to_text(String.t(), non_neg_integer(), non_neg_integer()) :: String.t()
  def add_location_to_text(text, pos_y, pos_x) do
    "\e[#{pos_y};#{pos_x}H#{text}"
  end

  defp format_table(chunks, add_line, animation) do
    # Asegurarnos de que tenemos una estructura de tabla válida
    table_data = ensure_table_structure(chunks)

    formatted_rows =
      table_data
      |> center_block_align()
      |> Enum.map(&format_table_row/1)

    output = Enum.join(formatted_rows, "\n")
    add_new_lines(animation <> output, add_line)
  end

  defp format_table_row(row_chunks) when is_list(row_chunks) do
    row_chunks
    |> Enum.map(&Effects.apply_chunk_effects/1)
    |> Enum.map(&Color.apply_to_chunk/1)
    |> Enum.map_join("  ", &extract_text/1)
  end

  defp format_raw(chunks, add_line, animation) do
    chunks
    |> ensure_chunks_list()
    |> Enum.map(fn
      %ChunkText{text: text, pos_x: pos_x, pos_y: pos_y} = chunk ->
        %ChunkText{chunk | text: add_location_to_text(text, pos_y, pos_x)}

      chunk ->
        chunk
    end)
    |> format_base(add_line, animation)
  end

  defp format_normal(chunks, manual_tabs, align, add_line, animation) do
    chunks
    |> ensure_chunks_list()
    |> apply_indentation(manual_tabs)
    |> align_text(align)
    |> format_base(add_line, animation)
  end

  defp format_base(chunks, add_line, animation) do
    processed_chunks =
      chunks
      |> apply_effects_to_chunks()
      |> Color.apply_to_chunk()

    output = chunks_to_text(processed_chunks)
    add_new_lines(animation <> output, add_line)
  end

  defp ensure_chunks_list(chunks) do
    chunks
    |> Ensure.list()
    |> Enum.map(&Ensure.chunk_text/1)
  end

  defp ensure_table_structure(chunks) when is_list(chunks) do
    # Verificar si ya es una estructura de tabla (lista de listas)
    if Enum.all?(chunks, &is_list/1) do
      chunks
    else
      # Si no, convertir a tabla de una fila
      [chunks]
    end
  end

  defp chunks_to_text(chunks) when is_list(chunks) do
    if Enum.all?(chunks, &match?(%ChunkText{}, &1)) do
      Enum.map_join(chunks, "", &extract_text/1)
    else
      chunks |> Ensure.string()
    end
  end

  defp chunks_to_text(chunks), do: Ensure.string(chunks)

  defp extract_text(%ChunkText{text: text}), do: text
  defp extract_text(other), do: Ensure.string(other)

  defp table?([]), do: false
  defp table?([first | _]) when is_list(first), do: true
  defp table?(_), do: false

  @doc """
  Formatea un logo (lista de líneas de texto) aplicando colores de gradiente y alineación.

  ## Parámetros

  - `lines` - Lista de strings que conforman el logo
  - `opts` - Opciones de formateo (opcional)

  ## Opciones

  - `:align` - Alineación del logo (`:left`, `:center`, `:right`) - default: `:left`
  - `:pos_x` - Posición X para modo raw - default: `0`
  - `:pos_y` - Posición Y para modo raw - default: `0`
  - `:gradient_colors` - Colores del gradiente - default: `Color.gradients()`
  - `:animation` - String de animación opcional - default: `""`

  ## Retorna

  Una tupla `{formatted_text, gradient_hexes}` donde:
  - `formatted_text` - El logo formateado con colores ANSI
  - `gradient_hexes` - Lista de códigos hexadecimales del gradiente aplicado

  ## Examples

      iex> lines = ["████", "████", "████"]
      iex> {text, _hexes} = Aurora.Format.format_logo(lines, align: :center)
      iex> is_binary(text)
      true
  """
  @spec format_logo([String.t()], keyword()) :: {String.t(), [String.t()]}
  def format_logo(lines, opts \\ []) when is_list(lines) do
    align = Keyword.get(opts, :align, :left)
    pos_x = Keyword.get(opts, :pos_x, 0)
    pos_y = Keyword.get(opts, :pos_y, 0)

    # Usar las nuevas funciones de Color
    gradient_colors =
      Keyword.get(opts, :gradient_colors, Color.gradients())
      |> Map.values()

    gradient_hexes = Enum.map(gradient_colors, & &1.hex)

    formatted_lines =
      lines
      |> Enum.with_index(1)
      |> Enum.map(fn {line, idx} ->
        color = Enum.at(gradient_colors, idx - 1, Color.get_default_color())

        chunk = %ChunkText{
          text: line,
          color: color,
          pos_x: pos_x,
          pos_y: pos_y
        }

        fmt_info = %FormatInfo{
          chunks: [chunk],
          align: align,
          manual_tabs: 0,
          add_line: :none,
          animation: Keyword.get(opts, :animation, "")
        }

        format(fmt_info)
      end)

    formatted_text = Enum.join(formatted_lines, "\n")
    {formatted_text, gradient_hexes}
  end

  @spec apply_indentation([ChunkText.t()], integer()) :: [ChunkText.t()]
  defp apply_indentation(chunks, manual_tabs) when is_integer(manual_tabs) and manual_tabs >= 0 do
    Enum.map(chunks, &indent_chunk(&1, manual_tabs))
  end

  defp apply_indentation(chunks, _manual_tabs) do
    Enum.map(chunks, fn chunk ->
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
    pad = max(terminal_width() - Convert.visible_length(line), 0)
    [create_pad_chunk(pad) | chunks]
  end

  defp align_text(chunks, :center) do
    line = Enum.map_join(chunks, "", & &1.text)
    total_width = terminal_width()
    line_length = Convert.visible_length(line)
    pad = max(total_width - line_length, 0)
    left_pad = div(pad, 2)
    right_pad = pad - left_pad

    [create_pad_chunk(left_pad) | chunks] ++ [create_pad_chunk(right_pad)]
  end

  defp align_text(chunks, :justify) do
    words = Enum.map(chunks, & &1.text)
    line = Enum.join(words, " ")
    total_width = terminal_width()
    line_length = Convert.visible_length(line)
    spaces_to_add = max(total_width - line_length, 0)

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
    if table?(rows) do
      col_count = rows |> Enum.map(&length/1) |> Enum.max(fn -> 0 end)

      col_widths =
        0..(col_count - 1)
        |> Enum.map(&calculate_column_width(rows, &1))

      Enum.map(rows, fn row ->
        fill_row(row, col_widths)
      end)
    else
      rows
    end
  end

  defp fill_row(row, col_widths) do
    row
    |> Enum.with_index()
    |> Enum.map(fn {chunk, col} ->
      chunk_length = Convert.visible_length(chunk.text)
      col_width = Enum.at(col_widths, col, 0)
      pad = max(col_width - chunk_length, 0)
      %{chunk | text: chunk.text <> String.duplicate(" ", pad)}
    end)
  end

  defp calculate_column_width(rows, col) do
    rows
    |> Enum.map(fn row ->
      case Enum.at(row, col) do
        %ChunkText{text: text} -> Convert.visible_length(text)
        _ -> 0
      end
    end)
    |> Enum.max(fn -> 0 end)
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
    Regex.replace(~r/\e(\[[\d;?]*[a-zA-Z]|P.*?\e\\)/, str, "")
  end

  @doc """
  Calcula la longitud visible de una cadena eliminando códigos ANSI.

  ## Parámetros

  - `str` - Cadena de texto que puede contener códigos ANSI

  ## Ejemplos

      iex> Aurora.Format.visible_length("\\e[1mHola\\e[0m")
      4

      iex> Aurora.Format.visible_length("texto normal")
      12
  """
  @spec visible_length(String.t()) :: non_neg_integer()
  def visible_length(str) when is_binary(str) do
    Convert.visible_length(str)
  end

  @doc """
  Elimina diacríticos (tildes, acentos) de un texto.

  Utiliza normalización NFD para separar los caracteres base de los diacríticos
  y luego elimina los modificadores diacríticos.

  ## Parámetros

  - `text` - Texto del que eliminar los diacríticos

  ## Ejemplos

      iex> Aurora.Format.remove_diacritics("café")
      "cafe"

      iex> Aurora.Format.remove_diacritics("niño")
      "nino"

      iex> Aurora.Format.remove_diacritics("resumé")
      "resume"
  """
  @spec remove_diacritics(String.t()) :: String.t()
  def remove_diacritics(text) do
    Convert.remove_diacritics(text)
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

  defp create_pad_chunk(size) do
    %ChunkText{
      text: String.duplicate(" ", size),
      color: Color.get_default_color()
    }
  end

  # Aplica efectos a una lista de chunks o tabla de chunks.
  @spec apply_effects_to_chunks([ChunkText.t()] | [[ChunkText.t()]]) ::
          [ChunkText.t()] | [[ChunkText.t()]]
  defp apply_effects_to_chunks(chunks) when is_list(chunks) do
    if table?(chunks) do
      Enum.map(chunks, &apply_effects_to_chunks/1)
    else
      Enum.map(chunks, &Effects.apply_chunk_effects/1)
    end
  end
end
