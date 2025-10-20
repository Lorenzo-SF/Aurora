defmodule Aurora.Ensure do
  @moduledoc """
  Module to ensure specific data types with safe default values.

  Supports native Elixir types, Aurora structs, and external types.

  ## Features

  - Type guarantee with safe default values
  - Conversion to native Elixir types
  - Conversion to Aurora structs
  - Safe type conversion with error handling
  - List operations with type conversion

  ## Examples

      # Ensure native types with safe defaults
      Aurora.Ensure.string(nil)        # ""
      Aurora.Ensure.integer("123")     # 123
      Aurora.Ensure.integer("invalid") # 0
      Aurora.Ensure.list(nil)          # []
      Aurora.Ensure.list("text")       # ["text"]
      Aurora.Ensure.map(nil)           # %{}
      Aurora.Ensure.boolean("true")    # true
      Aurora.Ensure.boolean("false")   # false

      # Ensure Aurora structs with defaults
      chunk = Aurora.Ensure.chunk_text(nil)        # %Aurora.Structs.ChunkText{text: ""}
      chunk = Aurora.Ensure.chunk_text("hello")    # %Aurora.Structs.ChunkText{text: "hello"}
      color = Aurora.Ensure.color_info(:primary)   # %Aurora.Structs.ColorInfo{...}
      format = Aurora.Ensure.format_info([])       # %Aurora.Structs.FormatInfo{chunks: []}
      effects = Aurora.Ensure.effect_info(nil)     # %Aurora.Structs.EffectInfo{...}

      # Convert list of values to specific type
      chunks = Aurora.Ensure.list_of(["text1", "text2"], Aurora.Structs.ChunkText)

      # Normalize text
      normalized = Aurora.Ensure.normalized_text("café", :lower)  # "cafe"

      # Ensure with external types (with default value)
      date = Aurora.Ensure.type(nil, {:external, Date, ~D[2000-01-01]})
  """

  alias Aurora.{Color, Convert}
  alias Aurora.Structs.{ChunkText, ColorInfo, EffectInfo, FormatInfo}

  @doc """
  Asegura que un valor sea del tipo especificado, con valor por defecto seguro.

  ## Tipos soportados

  ### Tipos nativos:
    - `:string`, `:integer`, `:float`, `:boolean`, `:atom`, `:list`, `:map`

  ### Structs de Aurora:
    - `ChunkText`, `ColorInfo`, `FormatInfo`, `EffectInfo`

  ### Tipos externos:
    - `{:external, module, default}` - Tipo externo con valor por defecto

  ## Ejemplos

      iex> Aurora.Ensure.type(nil, :string)
      ""

      iex> Aurora.Ensure.type("invalid", :integer)
      0

      iex> Aurora.Ensure.type(nil, Aurora.Structs.ChunkText)
      %Aurora.Structs.ChunkText{text: ""}

      iex> Aurora.Ensure.type(nil, {:external, Date, ~D[2000-01-01]})
      ~D[2000-01-01]
  """
  @spec type(any(), atom() | module() | tuple()) :: any()
  def type(value, :string), do: string(value)
  def type(value, :integer), do: integer(value)
  def type(value, :float), do: float(value)
  def type(value, :boolean), do: boolean(value)
  def type(value, :atom), do: atom(value)
  def type(value, :list), do: list(value)
  def type(value, :map), do: map(value)

  # Structs de Aurora
  def type(value, Aurora.Structs.ChunkText), do: chunk_text(value)
  def type(value, Aurora.Structs.ColorInfo), do: color_info(value)
  def type(value, Aurora.Structs.FormatInfo), do: format_info(value)
  def type(value, Aurora.Structs.EffectInfo), do: effect_info(value)

  # Tipos externos
  def type(value, {:external, module, default}) do
    Convert.to(value, {:external, module, :from_value!})
  rescue
    _ -> default
  end

  def type(value, _type), do: value

  @doc """
  Asegura que el valor esté normalizado según tipo y modo.
  """
  @spec normalized(any(), atom() | module() | tuple(), atom()) :: any()
  def normalized(value, type, mode \\ :default) do
    Convert.normalize(value, type, mode)
  end

  # Funciones específicas para tipos nativos
  @spec list(any()) :: list()
  def list(nil), do: []
  def list(value) when is_list(value), do: value
  def list(value), do: [value]

  @spec tuple(any(), tuple()) :: tuple()
  def tuple(value, default_value \\ {})
  def tuple(value, _default_value) when is_tuple(value), do: value
  def tuple(nil, default_value), do: default_value
  def tuple(value, _default_value), do: {value, :no_data}

  @spec map(any()) :: map()
  def map(nil), do: %{}
  def map(%{} = value), do: value
  def map(value) when is_list(value), do: Map.new(value)
  def map(value), do: %{value: value}

  @spec integer(any()) :: integer()
  def integer(value) when is_integer(value), do: value

  def integer(value) when is_binary(value) do
    case Integer.parse(value) do
      {int, ""} -> int
      _ -> 0
    end
  end

  def integer(_), do: 0

  @spec float(any()) :: float()
  def float(value) when is_float(value), do: value
  def float(value) when is_integer(value), do: value * 1.0

  def float(value) when is_binary(value) do
    case Float.parse(value) do
      {f, ""} -> f
      _ -> 0.0
    end
  end

  def float(_), do: 0.0

  @spec atom(any()) :: atom()
  def atom(nil), do: :ok
  def atom(value) when is_atom(value), do: value
  def atom(value) when is_binary(value), do: to_atom_safe(value)
  def atom(_), do: :ok

  @spec string(any()) :: String.t()
  def string(nil), do: ""
  def string(value) when is_binary(value), do: value
  def string(value), do: to_string(value)

  @spec boolean(any()) :: boolean()
  def boolean(value) when is_boolean(value), do: value
  def boolean("true"), do: true
  def boolean("false"), do: false
  def boolean(_), do: false

  @doc """
  Asegura que el texto esté normalizado según el modo especificado.
  """
  @spec normalized_text(String.t(), atom()) :: String.t()
  def normalized_text(text, mode \\ :clean), do: Convert.normalize_text(text, mode)

  # Funciones específicas para structs de Aurora
  @spec chunk_text(any()) :: ChunkText.t()
  def chunk_text(%ChunkText{} = chunk), do: chunk
  def chunk_text(nil), do: %ChunkText{text: ""}
  def chunk_text(value), do: Convert.to_chunk(value)

  @spec color_info(any()) :: ColorInfo.t()
  def color_info(%ColorInfo{} = color), do: color
  def color_info(value), do: Color.to_color_info(value)

  @spec format_info(any()) :: FormatInfo.t()
  def format_info(%FormatInfo{} = format), do: format
  def format_info(value), do: Convert.to_format_info(value)

  @spec effect_info(any()) :: EffectInfo.t()
  def effect_info(%EffectInfo{} = effect), do: effect
  def effect_info(value), do: Convert.to_effect_info(value)

  # Funciones de utilidad
  @spec deep_merge(map(), map()) :: map()
  def deep_merge(%{} = map1, %{} = map2) do
    Map.merge(map1, map2, fn _k, v1, v2 ->
      if is_map(v1) and is_map(v2), do: deep_merge(v1, v2), else: v2
    end)
  end

  @spec clean_nil_values(map()) :: map()
  def clean_nil_values(%{} = map) do
    map
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Enum.into(%{})
  end

  @spec cast(any(), atom() | module() | tuple()) :: any()
  def cast(value, type), do: type(value, type)

  @spec list_of(any(), atom() | module() | tuple()) :: list()
  def list_of(value, type) do
    value
    |> list()
    |> Enum.map(&type(&1, type))
  end

  defp to_atom_safe(string) do
    String.to_existing_atom(string)
  rescue
    ArgumentError -> String.to_atom(string)
  end
end
