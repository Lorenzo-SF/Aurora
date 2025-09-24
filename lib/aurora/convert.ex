defmodule Aurora.Convert do
  @moduledoc """
  Módulo de utilidades para conversión y transformación de datos.

  Este módulo proporciona funciones para convertir diferentes tipos de datos
  a las estructuras utilizadas por Aurora, así como utilidades para manipular
  y transformar texto, chunks y otros tipos de datos.

  ## Características principales

  - Conversión de datos a ChunkText
  - Transformación de tipos de datos
  - Manipulación de estructuras anidadas
  - Utilidades para texto y medición
  - Normalización de datos

  ## Conversiones soportadas

  - String → ChunkText
  - Atom → ChunkText
  - Number → ChunkText
  - Tuple {text, color} → ChunkText
  - Lista de datos → Lista de ChunkText
  - Estructuras anidadas → Estructuras planas

  ## Uso básico

      iex> chunk = Aurora.Convert.to_chunk("Hola")
      iex> chunk.text
      "Hola"

      iex> chunk = Aurora.Convert.to_chunk("Hola")
      iex> chunk.text
      "Hola"
  """

  alias Aurora.{Color, Ensure}
  alias Aurora.Structs.ChunkText

  def atomize_keys(nil), do: nil
  def atomize_keys(%{__struct__: _} = struct), do: struct

  def atomize_keys(%{} = map),
    do: Enum.into(map, %{}, fn {k, v} -> {String.to_atom(k), atomize_keys(v)} end)

  def atomize_keys([head | rest]), do: [atomize_keys(head) | atomize_keys(rest)]
  def atomize_keys(not_a_map), do: not_a_map

  def stringify_keys(nil), do: nil

  def stringify_keys(%{} = map) do
    Enum.into(map, %{}, fn {k, v} ->
      key = if is_atom(k), do: Atom.to_string(k), else: k
      {key, stringify_keys(v)}
    end)
  end

  def stringify_keys([head | rest]), do: [stringify_keys(head) | stringify_keys(rest)]
  def stringify_keys(not_a_map), do: not_a_map

  def underscore_keys(nil), do: nil

  def underscore_keys(%{} = map) do
    map
    |> Enum.map(fn {k, v} -> {Macro.underscore(k), underscore_keys(v)} end)
    |> Enum.into(%{}, fn {k, v} -> {String.replace(String.replace(k, "-", "_"), "__", "_"), v} end)
  end

  def underscore_keys([head | rest]), do: [underscore_keys(head) | underscore_keys(rest)]
  def underscore_keys(not_a_map), do: not_a_map

  def deep_merge(%{} = map1, %{} = map2) do
    Map.merge(map1, map2, fn _k, v1, v2 ->
      if is_map(v1) and is_map(v2), do: deep_merge(v1, v2), else: v2
    end)
  end

  def clean_nil_values(%{} = map) do
    map
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Enum.into(%{})
  end

  def cast(value, :string), do: Ensure.ensure_string(value)
  def cast(value, :integer), do: Ensure.ensure_integer(value)
  def cast(value, :float), do: Ensure.ensure_float(value)
  def cast(value, :boolean), do: Ensure.ensure_boolean(value)
  def cast(value, :atom), do: Ensure.ensure_atom(value)
  def cast(value, :list), do: Ensure.ensure_list(value)
  def cast(value, :map), do: Ensure.ensure_map(value)
  def cast(value, _), do: value

  def table?([]), do: false
  def table?([first | _]) when is_list(first), do: true
  def table?(_), do: false

  def to_chunk(text) when is_binary(text) do
    %ChunkText{text: text, color: Color.get_color_info(:no_color)}
  end

  def to_chunk({text, color}) when is_binary(text) do
    %ChunkText{text: text, color: Color.resolve_color(color)}
  end

  def to_chunk(value),
    do: %ChunkText{text: to_string(value), color: Color.get_color_info(:no_color)}

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
end
