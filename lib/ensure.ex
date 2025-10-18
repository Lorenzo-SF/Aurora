defmodule Aurora.Ensure do
  @moduledoc """
  Módulo para garantizar tipos de datos específicos con valores seguros por defecto.

  Este módulo proporciona funciones que siempre retornan un valor del tipo esperado,
  convirtiendo automáticamente valores de entrada o proporcionando valores por defecto
  seguros cuando la conversión no es posible.

  A diferencia de las funciones de conversión normales que pueden fallar, las funciones
  de este módulo nunca lanzan excepciones y siempre retornan un valor válido.

  ## Características principales

  - Conversión segura de tipos primitivos (string, integer, float, boolean, atom)
  - Conversión de estructuras (list, map, tuple)
  - Conversión a tipos específicos de Aurora (ChunkText)
  - Valores por defecto seguros para tipos no convertibles
  - Funciones de utilidad para estructuras complejas

  ## Garantías de tipo

  - `string/1` → Siempre retorna string válido (nunca nil)
  - `integer/1` → Siempre retorna entero (0 por defecto)
  - `float/1` → Siempre retorna float (0.0 por defecto)
  - `boolean/1` → Siempre retorna boolean (false por defecto)
  - `atom/1` → Siempre retorna atom (:ok por defecto)
  - `list/1` → Siempre retorna lista ([] por defecto)
  - `map/1` → Siempre retorna mapa ({} por defecto)

  ## Uso básico

      iex> Aurora.Ensure.string(nil)
      ""

      iex> Aurora.Ensure.string(123)
      "123"

      iex> Aurora.Ensure.integer("42")
      42

      iex> Aurora.Ensure.integer("invalid")
      0

      iex> Aurora.Ensure.list("single_item")
      ["single_item"]
  """

  alias Aurora.Color
  alias Aurora.Structs.{ChunkText, ColorInfo, FormatInfo}

  @doc """
  Asegura que el valor sea una lista.

  ## Parámetros

  - `value` - Valor a convertir en lista

  ## Ejemplos

      iex> Aurora.Ensure.list(nil)
      []

      iex> Aurora.Ensure.list([1, 2, 3])
      [1, 2, 3]

      iex> Aurora.Ensure.list("single")
      ["single"]
  """
  @spec list(any()) :: list()
  def list(nil), do: []
  def list(value) when is_list(value), do: value
  def list(value), do: [value]

  @doc """
  Asegura que el valor sea una tupla o proporciona un valor por defecto.

  ## Parámetros

  - `value` - Valor a convertir en tupla
  - `default_value` - Valor por defecto si no se puede convertir (default: {})

  ## Ejemplos

      iex> Aurora.Ensure.tuple({:ok, "data"})
      {:ok, "data"}

      iex> Aurora.Ensure.tuple(nil)
      {}

      iex> Aurora.Ensure.tuple("text")
      {"text", :no_data}
  """
  @spec tuple(any(), tuple()) :: tuple()
  def tuple(value, default_value \\ {})
  def tuple(value, _default_value) when is_tuple(value), do: value
  def tuple(nil, default_value), do: default_value
  def tuple("", default_value), do: default_value
  def tuple([], default_value), do: default_value
  def tuple(%{} = map, default_value) when map_size(map) == 0, do: default_value
  def tuple(value, _default_value) when is_binary(value), do: {value, :no_data}
  def tuple(value, _default_value) when is_list(value), do: {value, :no_data}
  def tuple(%{} = value, _default_value), do: {value, :no_data}
  def tuple(value, _default_value), do: {value, :no_data}

  @doc """
  Asegura que el valor sea un mapa.

  ## Parámetros

  - `value` - Valor a convertir en mapa

  ## Ejemplos

      iex> Aurora.Ensure.map(nil)
      %{}

      iex> Aurora.Ensure.map(%{a: 1})
      %{a: 1}

      iex> Aurora.Ensure.map([{:a, 1}, {:b, 2}])
      %{a: 1, b: 2}

      iex> Aurora.Ensure.map("text")
      %{value: "text"}
  """
  @spec map(any()) :: map()
  def map(nil), do: %{}
  def map(%{} = value), do: value
  def map(value) when is_list(value), do: Map.new(value)
  def map(value), do: %{value: value}

  @doc """
  Asegura que el valor sea un entero.

  ## Parámetros

  - `value` - Valor a convertir en entero

  ## Ejemplos

      iex> Aurora.Ensure.integer(42)
      42

      iex> Aurora.Ensure.integer("123")
      123

      iex> Aurora.Ensure.integer("invalid")
      0

      iex> Aurora.Ensure.integer(nil)
      0
  """
  @spec integer(any()) :: integer()
  def integer(value) when is_integer(value), do: value

  def integer(value) when is_binary(value) do
    case Integer.parse(value) do
      {int, ""} -> int
      _ -> 0
    end
  end

  def integer(_), do: 0

  @doc """
  Asegura que el valor sea un float.

  ## Parámetros

  - `value` - Valor a convertir en float

  ## Ejemplos

      iex> Aurora.Ensure.float(3.14)
      3.14

      iex> Aurora.Ensure.float(42)
      42.0

      iex> Aurora.Ensure.float("3.14")
      3.14

      iex> Aurora.Ensure.float("invalid")
      0.0
  """
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

  @doc """
  Asegura que el valor sea un atom.

  ## Parámetros

  - `value` - Valor a convertir en atom

  ## Ejemplos

      iex> Aurora.Ensure.atom(:hello)
      :hello

      iex> Aurora.Ensure.atom("world")
      :world

      iex> Aurora.Ensure.atom(123)
      :ok
  """
  @spec atom(any()) :: atom()
  def atom(value) when is_atom(value), do: value
  def atom(value) when is_binary(value), do: to_atom_safe(value)
  def atom(_), do: :ok

  @doc """
  Asegura que el valor sea un string.

  ## Parámetros

  - `value` - Valor a convertir en string

  ## Ejemplos

      iex> Aurora.Ensure.string(nil)
      ""

      iex> Aurora.Ensure.string("hello")
      "hello"

      iex> Aurora.Ensure.string(123)
      "123"

      iex> Aurora.Ensure.string(:atom)
      "atom"
  """
  @spec string(any()) :: String.t()
  def string(nil), do: ""
  def string(value) when is_binary(value), do: value

  def string(value) when is_atom(value) or is_integer(value) or is_float(value),
    do: to_string(value)

  def string(value), do: inspect(value)

  @doc """
  Asegura que el valor sea un boolean.

  ## Parámetros

  - `value` - Valor a convertir en boolean

  ## Ejemplos

      iex> Aurora.Ensure.boolean(true)
      true

      iex> Aurora.Ensure.boolean("true")
      true

      iex> Aurora.Ensure.boolean("false")
      false

      iex> Aurora.Ensure.boolean("anything")
      false
  """
  @spec boolean(any()) :: boolean()
  def boolean(value) when is_boolean(value), do: value
  def boolean("true"), do: true
  def boolean("false"), do: false
  def boolean(_), do: false

  @doc """
  Asegura que el valor sea un ChunkText válido.

  ## Parámetros

  - `value` - Valor a convertir en ChunkText

  ## Ejemplos

      iex> chunk = %Aurora.Structs.ChunkText{text: "hello"}
      iex> Aurora.Ensure.chunk_text(chunk).text
      "hello"

      iex> Aurora.Ensure.chunk_text("hello").text
      "hello"

      iex> Aurora.Ensure.chunk_text({"error", "red"}).text
      "error"
  """
  @spec chunk_text(any()) :: ChunkText.t()
  def chunk_text(%ChunkText{} = chunk), do: chunk

  def chunk_text(%FormatInfo{} = fmt_info) do
    create_chunk(inspect(fmt_info), Color.resolve_color(:no_color))
  end

  def chunk_text(%ColorInfo{} = color_info) do
    create_chunk(to_string(color_info.name), color_info)
  end

  def chunk_text({text, color}) when is_binary(text) and is_binary(color) do
    create_chunk(text, Color.resolve_color(:no_color))
  end

  def chunk_text(str) when is_binary(str) do
    create_chunk(str, Color.resolve_color(:no_color))
  end

  def chunk_text(_), do: %ChunkText{text: ""}

  defp create_chunk(text, color) do
    %ChunkText{text: text, color: color}
  end

  @doc """
  Verifica que un valor sea un struct del módulo esperado.

  ## Parámetros

  - `value` - Valor a verificar
  - `module` - Módulo esperado del struct

  ## Ejemplos

      iex> color = %Aurora.Structs.ColorInfo{name: :primary}
      iex> Aurora.Ensure.struct(color, Aurora.Structs.ColorInfo)
      %Aurora.Structs.ColorInfo{name: :primary}

      iex> Aurora.Ensure.struct("not_struct", Aurora.Structs.ColorInfo)
      nil
  """
  @spec struct(any(), module()) :: struct() | nil
  def struct(%mod{} = struct, mod), do: struct
  def struct(_, _mod), do: nil

  @doc """
  Combina dos mapas de manera profunda (deep merge).

  ## Parámetros

  - `map1` - Mapa base
  - `map2` - Mapa a fusionar (tiene precedencia)

  ## Ejemplos

      iex> map1 = %{a: %{x: 1, y: 2}, b: 3}
      iex> map2 = %{a: %{y: 20, z: 30}, c: 4}
      iex> Aurora.Ensure.deep_merge(map1, map2)
      %{a: %{x: 1, y: 20, z: 30}, b: 3, c: 4}
  """
  @spec deep_merge(map(), map()) :: map()
  def deep_merge(%{} = map1, %{} = map2) do
    Map.merge(map1, map2, fn _k, v1, v2 ->
      if is_map(v1) and is_map(v2), do: deep_merge(v1, v2), else: v2
    end)
  end

  @doc """
  Elimina todas las claves con valores nil de un mapa.

  ## Parámetros

  - `map` - Mapa del que eliminar valores nil

  ## Ejemplos

      iex> Aurora.Ensure.clean_nil_values(%{a: 1, b: nil, c: 3})
      %{a: 1, c: 3}
  """
  @spec clean_nil_values(map()) :: map()
  def clean_nil_values(%{} = map) do
    map
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Enum.into(%{})
  end

  @doc """
  Convierte un valor a un tipo específico usando las funciones de este módulo.

  ## Parámetros

  - `value` - Valor a convertir
  - `type` - Tipo objetivo (:string, :integer, :float, :boolean, :atom, :list, :map)

  ## Ejemplos

      iex> Aurora.Ensure.cast("123", :integer)
      123

      iex> Aurora.Ensure.cast(nil, :string)
      ""

      iex> Aurora.Ensure.cast("hello", :atom)
      :hello
  """
  @spec cast(any(), atom()) :: any()
  def cast(value, :string), do: string(value)
  def cast(value, :integer), do: integer(value)
  def cast(value, :float), do: float(value)
  def cast(value, :boolean), do: boolean(value)
  def cast(value, :atom), do: atom(value)
  def cast(value, :list), do: list(value)
  def cast(value, :map), do: map(value)
  def cast(value, _), do: value

  @doc """
  Convierte un valor a lista y aplica una función de tipo a cada elemento.

  ## Parámetros

  - `value` - Valor a convertir en lista tipada
  - `type_fun` - Función de tipo a aplicar (como :integer, :string, etc.)

  ## Ejemplos

      iex> Aurora.Ensure.list_of(["1", "2", "3"], :integer)
      [1, 2, 3]

      iex> Aurora.Ensure.list_of("hello", :string)
      ["hello"]

      iex> Aurora.Ensure.list_of([1, 2.5, "3"], :float)
      [1.0, 2.5, 3.0]
  """
  @spec list_of(any(), atom()) :: list()
  def list_of(value, type_fun) do
    value
    |> list()
    |> Enum.map(&apply(__MODULE__, type_fun, [&1]))
  end

  defp to_atom_safe(string) do
    String.to_existing_atom(string)
  rescue
    ArgumentError -> String.to_atom(string)
  end
end
