defmodule Aurora.Normalize do
  @moduledoc """
  Módulo para normalización de texto y datos en Aurora.

  Este módulo proporciona funciones para normalizar diferentes tipos de datos,
  incluyendo texto, mensajes y tablas, para ser utilizados consistentemente
  en el sistema Aurora.

  ## Características principales

  - Normalización de texto (mayúsculas, minúsculas, eliminación de diacríticos)
  - Normalización de mensajes a estructura ChunkText
  - Normalización de tablas con alineación automática
  - Conversión automática de diferentes tipos de datos

  ## Uso básico

      iex> Aurora.Normalize.normalize_text("HOLA", :lower)
      "hola"

      iex> messages = [{"Error", :error}, {"Info", :info}]
      iex> result = Aurora.Normalize.normalize_messages(messages)
      iex> length(result)
      2
      iex> hd(result).text
      "Error"
  """

  alias Aurora.Color
  alias Aurora.Structs.ChunkText

  @doc """
  Normaliza texto aplicando transformaciones específicas.

  ## Parámetros

  - `text` - Texto a normalizar
  - `mode` - Modo de normalización (:lower, :upper, u otro para solo limpiar)

  ## Ejemplos

      iex> Aurora.Normalize.normalize_text("ÑOÑO", :lower)
      "nono"

      iex> Aurora.Normalize.normalize_text("café", :upper)
      "CAFE"

      iex> Aurora.Normalize.normalize_text(" resumé ", :trim)
      "resume"
  """
  @spec normalize_text(String.t(), atom()) :: String.t()
  def normalize_text(text, :lower),
    do: text |> String.trim() |> String.downcase() |> remove_diacritics()

  def normalize_text(text, :upper),
    do: text |> String.trim() |> String.upcase() |> remove_diacritics()

  def normalize_text(text, _),
    do: text |> String.trim() |> remove_diacritics()

  @doc """
  Normaliza mensajes diversos a una lista de ChunkText.

  ## Parámetros

  - `messages` - Puede ser lista de tuplas {texto, color}, lista de ChunkText, string o cualquier valor

  ## Ejemplos

      iex> messages = [{"Error", :error}, {"Info", :info}]
      iex> chunks = Aurora.Normalize.normalize_messages(messages)
      iex> length(chunks)
      2

      iex> result = Aurora.Normalize.normalize_messages("mensaje")
      iex> length(result)
      1
      iex> hd(result).text
      "mensaje"
  """
  @spec normalize_messages(list() | String.t() | any()) :: [ChunkText.t()]
  def normalize_messages([{_, _} | _] = list) do
    Enum.map(list, fn
      {text, color} ->
        %ChunkText{
          text: to_string(text),
          color: Color.get_color_info(color)
        }
    end)
  end

  def normalize_messages([%ChunkText{} | _] = chunks), do: chunks

  def normalize_messages(message) when is_binary(message) do
    [%ChunkText{text: message, color: Color.get_color_info(:no_color)}]
  end

  def normalize_messages(_), do: []

  @doc """
  Normaliza una tabla ajustando el ancho de las columnas y rellenando filas.

  Asegura que todas las filas tengan el mismo número de columnas y
  aplica padding para alineación uniforme basado en el contenido más ancho de cada columna.

  ## Parámetros

  - `rows` - Lista de listas de ChunkText representando filas de la tabla

  ## Ejemplos

      iex> alias Aurora.Structs.ChunkText
      iex> rows = [
      ...>   [%ChunkText{text: "ID"}, %ChunkText{text: "Nombre"}],
      ...>   [%ChunkText{text: "1"}, %ChunkText{text: "Juan"}],
      ...>   [%ChunkText{text: "10"}, %ChunkText{text: "María"}]
      ...> ]
      iex> result = Aurora.Normalize.normalize_table(rows)
      iex> is_list(result)
      true
  """
  @spec normalize_table([[ChunkText.t()]]) :: [[ChunkText.t()]]
  def normalize_table(rows) when is_list(rows) do
    max_cols =
      rows
      |> Enum.map(&length/1)
      |> Enum.max(fn -> 0 end)

    rows =
      rows
      |> Enum.map(&pad_row(&1, max_cols))

    col_widths =
      rows
      |> transpose()
      |> Enum.map(fn col ->
        col
        |> Enum.map(&visible_length(&1.text))
        |> Enum.max()
      end)

    Enum.map(rows, fn row ->
      Enum.zip(row, col_widths)
      |> Enum.map(fn {%ChunkText{} = chunk, width} ->
        %ChunkText{
          chunk
          | text: String.pad_trailing(chunk.text, width)
        }
      end)
    end)
  end

  defp pad_row(row, max_cols) do
    default_chunk = %ChunkText{text: "", color: Color.get_color_info(:no_color)}
    row ++ List.duplicate(default_chunk, max_cols - length(row))
  end

  defp transpose(rows), do: Enum.zip(rows) |> Enum.map(&Tuple.to_list/1)

  defp visible_length(str) when is_binary(str) do
    str
    |> String.replace(~r/\e\[[0-9;]*m/, "")
    |> String.length()
  end

  defp remove_diacritics(text) do
    text
    |> String.normalize(:nfd)
    |> String.replace(~r/\p{Mn}/u, "")
  end
end
