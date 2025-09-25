defmodule Aurora do
  @moduledoc """
  Aurora - Biblioteca de formateo de texto optimizada para terminal.

  Proporciona funcionalidades avanzadas para formateo de texto con colores ANSI,
  efectos, alineación e indentación optimizada.

  ## Características principales

  - Formateo de texto con colores y efectos ANSI
  - Múltiples opciones de alineación (left, right, center, justify, center_block)
  - Sistema de indentación inteligente basado en colores
  - Soporte para tablas y datos estructurados
  - Generación de gradientes de color
  - Utilidades de conversión y normalización

  ## Uso básico

      iex> result = Aurora.colorize("Hola mundo", :primary)
      iex> String.contains?(result, "Hola mundo")
      true

      iex> Aurora.format_chunks([
      ...>   {"Error:", :error},
      ...>   {" Archivo no encontrado", :warning}
      ...> ])

  ## Módulos principales

  - `Aurora.Format` - Funciones principales de formateo
  - `Aurora.Color` - Procesamiento y aplicación de colores
  - `Aurora.Effects` - Aplicación de efectos ANSI
  - `Aurora.Convert` - Utilidades de conversión y transformación
  - `Aurora.Ensure` - Funciones para garantizar tipos de datos específicos
  - `Aurora.Normalize` - Normalización de texto y estructuras de datos
  """

  alias Aurora.{Color, Convert, Effects, Format}
  alias Aurora.Structs.FormatInfo

  @doc """
  Formatea una lista de chunks de texto creando FormatInfo automáticamente.

  ## Ejemplos

      iex> chunks = [
      ...>   %Aurora.Structs.ChunkText{text: "INFO:"},
      ...>   %Aurora.Structs.ChunkText{text: " Operación completada"}
      ...> ]
      iex> Aurora.format_chunks(chunks)
  """
  @spec format_chunks([Aurora.Structs.ChunkText.t()], keyword()) :: String.t()
  def format_chunks(chunks, opts \\ []) do
    format_info = struct(FormatInfo, [{:chunks, chunks} | opts])
    Format.format(format_info)
  end

  @doc """
  Formatea texto con opciones básicas de color y alineación.

  Función "light" para uso rápido y sencillo. Para opciones avanzadas,
  usar directamente los módulos `Aurora.Format`, `Aurora.Color`, etc.

  ## Parámetros

  - `text` - String o lista de strings
  - `opts` - Opciones básicas (opcional)

  ## Opciones básicas

  - `:color` - Color del texto (átomo como :primary, :error, etc. o hex como "#FF0000")
  - `:align` - Alineación (:left, :right, :center)
  - `:bold` - Texto en negrita (true/false)

  ## Ejemplos

      iex> Aurora.format("Hola mundo", color: :primary)

      iex> Aurora.format("Error importante", color: :error, bold: true)

      iex> Aurora.format("Texto centrado", align: :center)

      iex> Aurora.format(["Línea 1", "Línea 2"], color: :info)
  """
  @spec format(String.t() | [String.t()] | FormatInfo.t(), keyword()) :: String.t()
  def format(text, opts \\ [])

  def format(%FormatInfo{} = format_info, _opts) do
    Format.format(format_info)
  end

  def format(text, opts) when is_binary(text) do
    # Solo extraer opciones básicas
    {color, opts} = Keyword.pop(opts, :color)
    {align, opts} = Keyword.pop(opts, :align, :left)
    {bold, _opts} = Keyword.pop(opts, :bold, false)

    # Crear chunk básico
    chunk_opts = [{:text, text}]

    chunk_opts =
      if color, do: [{:color, Color.get_color_info(color)} | chunk_opts], else: chunk_opts

    # Solo efecto bold si se especifica
    effects = if bold, do: %Aurora.Structs.EffectInfo{bold: true}, else: nil
    chunk_opts = if effects, do: [{:effects, effects} | chunk_opts], else: chunk_opts

    chunk = struct(Aurora.Structs.ChunkText, chunk_opts)

    # FormatInfo simple
    format_info = %FormatInfo{chunks: [chunk], align: align}
    Format.format(format_info)
  end

  def format(texts, opts) when is_list(texts) do
    # Para listas, crear chunks individuales
    {color, opts} = Keyword.pop(opts, :color)
    {align, opts} = Keyword.pop(opts, :align, :left)
    {bold, _opts} = Keyword.pop(opts, :bold, false)

    effects = if bold, do: %Aurora.Structs.EffectInfo{bold: true}, else: nil

    chunks =
      Enum.map(texts, fn text ->
        chunk_opts = [{:text, text}]

        chunk_opts =
          if color, do: [{:color, Color.get_color_info(color)} | chunk_opts], else: chunk_opts

        chunk_opts = if effects, do: [{:effects, effects} | chunk_opts], else: chunk_opts
        struct(Aurora.Structs.ChunkText, chunk_opts)
      end)

    format_info = %FormatInfo{chunks: chunks, align: align}
    Format.format(format_info)
  end

  @doc """
  Crea un nuevo ChunkText con color opcional.

  ## Ejemplos

      iex> Aurora.chunk("texto", :primary)
      iex> Aurora.chunk("mensaje")
  """
  @spec chunk(String.t(), atom() | String.t() | nil) :: Aurora.Structs.ChunkText.t()
  def chunk(text, color \\ nil) do
    if color do
      Convert.to_chunk({text, color})
    else
      Convert.to_chunk(text)
    end
  end

  @doc """
  Crea múltiples chunks desde una lista de tuplas {texto, color}.

  ## Ejemplos

      iex> Aurora.chunks([
      ...>   {"Error:", :error},
      ...>   {" mensaje", :warning}
      ...> ])
  """
  @spec chunks([{String.t(), atom() | String.t()}]) :: [Aurora.Structs.ChunkText.t()]
  def chunks(list) when is_list(list) do
    Enum.map(list, &Convert.to_chunk/1)
  end

  @doc """
  Aplica un color específico a un texto.

  ## Ejemplos

      iex> Aurora.colorize("texto", :primary)
      iex> Aurora.colorize("error", "#FF0000")
  """
  @spec colorize(String.t(), atom() | String.t()) :: String.t()
  def colorize(text, color) do
    color_info = Color.resolve_color(color)
    Color.apply_color(text, color_info)
  end

  @doc """
  Aplica efectos a un texto.

  ## Ejemplos

      iex> Aurora.stylize("texto", [:bold, :underline]) |> IO.puts
      iex> Aurora.stylize("dim", :dim) |> IO.puts
  """
  @spec stylize(String.t(), [atom()] | atom()) :: String.t()
  def stylize(text, effects) when is_list(effects) do
    Effects.apply_multiple_effects(text, effects)
  end

  def stylize(text, effect) do
    Effects.apply_effect(text, effect)
  end

  @doc """
  Genera un gradiente de colores entre dos colores.

  ## Ejemplos

      iex> Aurora.gradient("#FF0000", "#0000FF")
  """
  @spec gradient(String.t(), String.t(), integer()) :: [String.t()]
  def gradient(start_color, end_color, steps \\ 6) do
    if steps == 6 do
      Color.generate_gradient_between(start_color, end_color)
    else
      # Si necesitamos un número diferente de pasos, usamos la función básica
      Color.generate_gradient_between(start_color, end_color)
      |> Enum.take(steps)
    end
  end

  @doc """
  Limpia códigos ANSI de un texto.

  ## Ejemplos

      iex> Aurora.clean("\\e[1mTexto\\e[0m")
      "Texto"
  """
  @spec clean(String.t()) :: String.t()
  defdelegate clean(text), to: Format, as: :clean_ansi

  @doc """
  Obtiene la longitud visible de un texto (sin códigos ANSI).

  ## Ejemplos

      iex> Aurora.text_length("\\e[1mHola\\e[0m")
      4
  """
  @spec text_length(String.t()) :: non_neg_integer()
  def text_length(text) do
    Format.clean_ansi(text) |> String.length()
  end

  @doc """
  Formatea JSON de manera legible con colores y sintaxis resaltada.

  ## Parámetros

  - `data` - Puede ser string JSON, map, list o cualquier estructura serializable
  - `opts` - Opciones de formato (opcional)

  ## Opciones

  - `:color` - Color base para el JSON (default: :info)
  - `:indent` - Agregar indentación extra (default: false)
  - `:compact` - Formato compacto sin pretty print (default: false)

  ## Ejemplos

      iex> # JSON desde string
      iex> json = ~s({"name":"Juan","age":25})
      iex> Aurora.json(json)

      iex> # JSON desde map
      iex> data = %{name: "Juan", age: 25, active: true}
      iex> Aurora.json(data)

      iex> # JSON con color personalizado
      iex> data2 = %{status: "ok"}
      iex> Aurora.json(data2, color: :success)

      iex> # JSON compacto
      iex> data3 = %{test: true}
      iex> Aurora.json(data3, compact: true)

      iex> # JSON con indentación extra
      iex> data4 = %{msg: "hello"}
      iex> Aurora.json(data4, indent: true)
  """
  @spec json(String.t() | map() | list() | any(), keyword()) :: String.t()
  def json(data, opts \\ []) do
    color = Keyword.get(opts, :color, :info)
    compact = Keyword.get(opts, :compact, false)
    indent = Keyword.get(opts, :indent, false)

    # Convertir a JSON string si no lo es ya
    json_string =
      case data do
        str when is_binary(str) -> str
        other -> Jason.encode!(other)
      end

    # Formatear JSON
    formatted_json =
      if compact do
        json_string
      else
        Format.pretty_json(json_string)
      end

    # Aplicar indentación extra si se solicita
    final_json =
      if indent do
        formatted_json
        |> String.split("\n")
        |> Enum.map_join("\n", &("  " <> &1))
      else
        formatted_json
      end

    # Formatear con color
    format(final_json, color: color)
  end

  @doc """
  Lista todos los colores disponibles.
  """
  @spec colors() :: [atom()]
  def colors do
    Color.colors() |> Map.keys()
  end

  @doc """
  Lista todos los efectos disponibles.
  """
  @spec effects() :: [atom()]
  defdelegate effects(), to: Effects, as: :available_effects
end
