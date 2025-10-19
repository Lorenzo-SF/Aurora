defmodule Aurora.Convert do
  @moduledoc """
  Módulo de utilidades para conversión y transformación de datos.

  Soporta conversión entre tipos nativos de Elixir y structs de Aurora,
  así como conversión a tipos externos específicos.
  """

  alias Aurora.{Color, Ensure}
  alias Aurora.Structs.{ChunkText, EffectInfo, FormatInfo}

  @doc """
  Convierte un valor a un tipo específico.

  ## Tipos soportados

  ### Tipos nativos de Elixir:
    - `:string` - String
    - `:integer` - Integer
    - `:float` - Float
    - `:boolean` - Boolean
    - `:atom` - Atom
    - `:list` - List
    - `:map` - Map

  ### Structs de Aurora:
    - `ChunkText` - Convierte a ChunkText
    - `ColorInfo` - Convierte a ColorInfo
    - `FormatInfo` - Convierte a FormatInfo
    - `EffectInfo` - Convierte a EffectInfo

  ### Tipos externos:
    - `{:external, module, function}` - Usa función externa para conversión

  ## Ejemplos

      iex> Aurora.Convert.to("hello", :string)
      "hello"

      iex> Aurora.Convert.to("123", :integer)
      123

      iex> result = Aurora.Convert.to(:primary, Aurora.Structs.ColorInfo)
      iex> result.name
      :primary

      iex> %Aurora.Structs.ChunkText{text: "text"} = Aurora.Convert.to("text", Aurora.Structs.ChunkText)
      %Aurora.Structs.ChunkText{text: "text"}

      iex> # Conversión externa
      iex> Aurora.Convert.to("2023-01-01", {:external, Date, :from_iso8601!})
      ~D[2023-01-01]
  """
  @spec to(any(), atom() | module() | tuple()) :: any()
  def to(value, :string), do: Ensure.string(value)
  def to(value, :integer), do: Ensure.integer(value)
  def to(value, :float), do: Ensure.float(value)
  def to(value, :boolean), do: Ensure.boolean(value)
  def to(value, :atom), do: Ensure.atom(value)
  def to(value, :list), do: Ensure.list(value)
  def to(value, :map), do: Ensure.map(value)

  # Conversión a structs de Aurora
  def to(value, Aurora.Structs.ChunkText), do: to_chunk(value)
  def to(value, Aurora.Structs.ColorInfo), do: Color.to_color_info(value)
  def to(value, Aurora.Structs.FormatInfo), do: to_format_info(value)
  def to(value, Aurora.Structs.EffectInfo), do: to_effect_info(value)

  # Conversión externa
  def to(value, {:external, module, function}) when is_atom(module) and is_atom(function) do
    apply(module, function, [value])
  end

  def to(value, _type), do: value

  @doc """
  Normaliza un valor según el tipo y modo especificados.
  """
  @spec normalize(any(), atom() | module() | tuple(), atom()) :: any()
  def normalize(value, type, mode \\ :default) do
    case {type, mode} do
      {:string, :lower} -> normalize_text(Ensure.string(value), :lower)
      {:string, :upper} -> normalize_text(Ensure.string(value), :upper)
      {:string, _} -> normalize_text(Ensure.string(value), :clean)
      {_, _} -> to(value, type)
    end
  end

  @doc """
  Convierte diferentes representaciones a ChunkText.
  """
  @spec to_chunk(any()) :: ChunkText.t()
  def to_chunk(%ChunkText{} = chunk), do: chunk
  def to_chunk(nil), do: %ChunkText{text: ""}
  def to_chunk(text) when is_binary(text), do: %ChunkText{text: text}
  def to_chunk(atom) when is_atom(atom), do: %ChunkText{text: Atom.to_string(atom)}
  def to_chunk(number) when is_number(number), do: %ChunkText{text: to_string(number)}

  def to_chunk({text, color}),
    do: %ChunkText{text: Ensure.string(text), color: Color.to_color_info(color)}

  def to_chunk({text, color, pos_x, pos_y}),
    do: %ChunkText{
      text: Ensure.string(text),
      color: Color.to_color_info(color),
      pos_x: pos_x,
      pos_y: pos_y
    }

  def to_chunk(value), do: %ChunkText{text: inspect(value)}

  @doc """
  Convierte diferentes representaciones a ChunkText con posiciones.
  """
  @spec to_chunk(any(), integer(), integer()) :: ChunkText.t()
  def to_chunk(value, pos_x, pos_y) do
    chunk = to_chunk(value)
    %ChunkText{chunk | pos_x: pos_x, pos_y: pos_y}
  end

  @doc """
  Convierte diferentes representaciones a FormatInfo.
  """
  @spec to_format_info(any()) :: FormatInfo.t()
  def to_format_info(%FormatInfo{} = format_info), do: format_info

  def to_format_info(chunks) when is_list(chunks),
    do: %FormatInfo{chunks: Enum.map(chunks, &to_chunk/1)}

  def to_format_info(%{} = map) do
    %FormatInfo{
      chunks: map |> Map.get(:chunks, []) |> Ensure.list() |> Enum.map(&to_chunk/1),
      default_color: Map.get(map, :default_color) |> then(&if(&1, do: Color.to_color_info(&1))),
      align: Map.get(map, :align, :left) |> to_alignment(),
      manual_tabs: Map.get(map, :manual_tabs, -1) |> Ensure.integer(),
      add_line: Map.get(map, :add_line, :none) |> to_line_option(),
      animation: Map.get(map, :animation, "") |> Ensure.string(),
      mode: Map.get(map, :mode, :normal) |> to_mode()
    }
  end

  def to_format_info(_), do: %FormatInfo{chunks: []}

  @doc """
  Convierte diferentes representaciones a EffectInfo.
  """
  @spec to_effect_info(any()) :: EffectInfo.t()
  def to_effect_info(%EffectInfo{} = effect_info), do: effect_info

  def to_effect_info(%{} = map) do
    %EffectInfo{
      bold: Map.get(map, :bold, false) |> Ensure.boolean(),
      dim: Map.get(map, :dim, false) |> Ensure.boolean(),
      italic: Map.get(map, :italic, false) |> Ensure.boolean(),
      underline: Map.get(map, :underline, false) |> Ensure.boolean(),
      blink: Map.get(map, :blink, false) |> Ensure.boolean(),
      reverse: Map.get(map, :reverse, false) |> Ensure.boolean(),
      hidden: Map.get(map, :hidden, false) |> Ensure.boolean(),
      strikethrough: Map.get(map, :strikethrough, false) |> Ensure.boolean(),
      link: Map.get(map, :link, false) |> Ensure.boolean()
    }
  end

  def to_effect_info(list) when is_list(list) do
    effects = Enum.into(list, %{})
    to_effect_info(effects)
  end

  def to_effect_info(_), do: %EffectInfo{}

  # Funciones de utilidad para transformaciones comunes
  @doc """
  Convierte una lista de valores a una lista de un tipo específico.
  """
  @spec map_list([any()], atom() | module() | tuple()) :: [any()]
  def map_list(list, type) when is_list(list) do
    Enum.map(list, &to(&1, type))
  end

  def map_list(value, type), do: [to(value, type)]

  @doc """
  Normaliza texto aplicando transformaciones específicas.
  """
  @spec normalize_text(String.t(), atom()) :: String.t()
  def normalize_text(text, :lower),
    do: text |> String.trim() |> String.downcase() |> remove_diacritics()

  def normalize_text(text, :upper),
    do: text |> String.trim() |> String.upcase() |> remove_diacritics()

  def normalize_text(text, _), do: text |> String.trim() |> remove_diacritics()

  @doc """
  Elimina diacríticos y tildes del texto.
  """
  @spec remove_diacritics(String.t()) :: String.t()
  def remove_diacritics(text) do
    text |> String.normalize(:nfd) |> String.replace(~r/\p{Mn}/u, "")
  end

  @doc """
  Calcula la longitud visible de texto (sin códigos ANSI).
  Acepta strings o ChunkText.
  """
  @spec visible_length(String.t() | ChunkText.t()) :: non_neg_integer()
  def visible_length(str) when is_binary(str) do
    str |> String.replace(~r/\e\[[0-9;]*m/, "") |> String.length()
  end

  def visible_length(%ChunkText{text: text}), do: visible_length(text)
  def visible_length(other), do: other |> Ensure.string() |> visible_length()

  @doc """
  Verifica si los datos tienen formato de tabla (lista de listas).
  """
  @spec table?(any()) :: boolean()
  def table?([]), do: false
  def table?([first | _]) when is_list(first), do: true
  def table?(_), do: false

  @doc """
  Convierte claves de string a atoms en mapas anidados.
  """
  @spec atomize_keys(any()) :: any()
  def atomize_keys(nil), do: nil
  def atomize_keys(%{__struct__: _} = struct), do: struct

  def atomize_keys(%{} = map),
    do: Enum.into(map, %{}, fn {k, v} -> {Ensure.atom(k), atomize_keys(v)} end)

  def atomize_keys([head | rest]), do: [atomize_keys(head) | atomize_keys(rest)]
  def atomize_keys(value), do: value

  @doc """
  Convierte claves de atoms a strings en mapas anidados.
  """
  @spec stringify_keys(any()) :: any()
  def stringify_keys(nil), do: nil
  def stringify_keys(%{__struct__: _} = struct), do: struct

  def stringify_keys(%{} = map),
    do: Enum.into(map, %{}, fn {k, v} -> {Ensure.string(k), stringify_keys(v)} end)

  def stringify_keys([head | rest]), do: [stringify_keys(head) | stringify_keys(rest)]
  def stringify_keys(value), do: value

  @doc """
  Combina dos mapas de manera profunda (deep merge).
  """
  @spec deep_merge(map(), map()) :: map()
  def deep_merge(%{} = map1, %{} = map2) do
    Map.merge(map1, map2, fn _k, v1, v2 ->
      if is_map(v1) and is_map(v2), do: deep_merge(v1, v2), else: v2
    end)
  end

  @doc """
  Elimina todas las claves con valores nil de un mapa.
  """
  @spec clean_nil_values(map()) :: map()
  def clean_nil_values(%{} = map) do
    map
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Enum.into(%{})
  end

  # Funciones privadas de ayuda
  defp to_alignment(:left), do: :left
  defp to_alignment(:right), do: :right
  defp to_alignment(:center), do: :center
  defp to_alignment(:center_block), do: :center_block
  defp to_alignment(:justify), do: :justify
  defp to_alignment(value) when is_binary(value), do: value |> String.to_atom() |> to_alignment()
  defp to_alignment(_), do: :left

  defp to_line_option(:before), do: :before
  defp to_line_option(:after), do: :after
  defp to_line_option(:both), do: :both
  defp to_line_option(:none), do: :none

  defp to_line_option(value) when is_binary(value),
    do: value |> String.to_atom() |> to_line_option()

  defp to_line_option(_), do: :none

  defp to_mode(:normal), do: :normal
  defp to_mode(:table), do: :table
  defp to_mode(:raw), do: :raw
  defp to_mode(value) when is_binary(value), do: value |> String.to_atom() |> to_mode()
  defp to_mode(_), do: :normal
end
