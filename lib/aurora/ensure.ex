defmodule Aurora.Ensure do
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

  alias Aurora.Color
  alias Aurora.Structs.{ChunkText, ColorInfo, FormatInfo}

  def ensure_list(nil), do: []
  def ensure_list(value) when is_list(value), do: value
  def ensure_list(value), do: [value]

  def ensure_tuple(value, default_value \\ {})
  def ensure_tuple(value, _default_value) when is_tuple(value), do: value
  def ensure_tuple(nil, default_value), do: default_value
  def ensure_tuple("", default_value), do: default_value
  def ensure_tuple([], default_value), do: default_value
  def ensure_tuple(%{} = map, default_value) when map_size(map) == 0, do: default_value
  def ensure_tuple(value, _default_value) when is_binary(value), do: {value, :no_data}
  def ensure_tuple(value, _default_value) when is_list(value), do: {value, :no_data}
  def ensure_tuple(%{} = value, _default_value), do: {value, :no_data}
  def ensure_tuple(value, _default_value), do: {value, :no_data}

  def ensure_map(nil), do: %{}
  def ensure_map(%{} = value), do: value
  def ensure_map(value) when is_list(value), do: Map.new(value)
  def ensure_map(value), do: %{value: value}

  def ensure_integer(value) when is_integer(value), do: value

  def ensure_integer(value) when is_binary(value) do
    case Integer.parse(value) do
      {int, ""} -> int
      _ -> 0
    end
  end

  def ensure_integer(_), do: 0

  def ensure_float(value) when is_float(value), do: value
  def ensure_float(value) when is_integer(value), do: value * 1.0

  def ensure_float(value) when is_binary(value) do
    case Float.parse(value) do
      {f, ""} -> f
      _ -> 0.0
    end
  end

  def ensure_float(_), do: 0.0

  def ensure_atom(value) when is_atom(value), do: value
  def ensure_atom(value) when is_binary(value), do: to_atom_safe(value)
  def ensure_atom(_), do: :ozu

  def ensure_string(nil), do: ""
  def ensure_string(value) when is_binary(value), do: value

  def ensure_string(value) when is_atom(value) or is_integer(value) or is_float(value),
    do: to_string(value)

  def ensure_string(value), do: inspect(value)

  def ensure_boolean(value) when is_boolean(value), do: value
  def ensure_boolean("true"), do: true
  def ensure_boolean("false"), do: false
  def ensure_boolean(_), do: false

  def ensure_chunk_text(%ChunkText{} = chunk), do: chunk

  def ensure_chunk_text(%FormatInfo{} = fmt_info) do
    %ChunkText{text: inspect(fmt_info), color: Color.resolve_color(:no_color)}
  end

  def ensure_chunk_text(%ColorInfo{} = color_info) do
    %ChunkText{text: to_string(color_info.name), color: color_info}
  end

  def ensure_chunk_text({text, color}) when is_binary(text) and is_binary(color) do
    %ChunkText{text: text, color: Color.resolve_color(:no_color)}
  end

  def ensure_chunk_text(str) when is_binary(str) do
    %ChunkText{text: str, color: Color.resolve_color(:no_color)}
  end

  def ensure_chunk_text(_), do: %ChunkText{text: ""}

  def ensure_struct(%mod{} = struct, mod), do: struct
  def ensure_struct(_, _mod), do: nil

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

  def cast(value, :string), do: ensure_string(value)
  def cast(value, :integer), do: ensure_integer(value)
  def cast(value, :float), do: ensure_float(value)
  def cast(value, :boolean), do: ensure_boolean(value)
  def cast(value, :atom), do: ensure_atom(value)
  def cast(value, :list), do: ensure_list(value)
  def cast(value, :map), do: ensure_map(value)
  def cast(value, _), do: value

  def ensure_list_of(value, type_fun) do
    value
    |> ensure_list()
    |> Enum.map(&apply(__MODULE__, type_fun, [&1]))
  end

  defp to_atom_safe(string) do
    String.to_existing_atom(string)
  rescue
    ArgumentError -> String.to_atom(string)
  end
end
