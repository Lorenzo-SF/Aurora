defmodule Aurora.Color do
  @moduledoc """
  Complete color management system with support for multiple formats.

  Provides conversion between color formats (HEX, RGB, HSV, HSL, CMYK, ARGB),
  application of ANSI colors in terminal, and color manipulation (lighten/darken).

  ## Features

  - Automatic conversion between color formats
  - ANSI color application for terminal
  - Brightness manipulation (lighten/darken)
  - Support for inverted colors
  - Configurable color palettes
  - Expandable gradient system

  ## Supported Formats

  - **HEX**: `"#FF0000"`, `"#A1E7FA"`
  - **RGB**: `{255, 0, 0}`
  - **ARGB**: `{255, 255, 0, 0}`
  - **HSV**: `{0.0, 1.0, 1.0}` (Hue, Saturation, Value)
  - **HSL**: `{0.0, 1.0, 0.5}` (Hue, Saturation, Lightness)
  - **CMYK**: `{0.0, 1.0, 1.0, 0.0}` (Cyan, Magenta, Yellow, Key/Black)
  - **Atom**: `:primary`, `:error`, `:success`, etc.
  - **Struct**: `%ColorInfo{}`

  ## Examples

      # Automatic format conversion
      color = Aurora.Color.to_color_info("#FF0000")
      color = Aurora.Color.to_color_info({255, 0, 0})
      color = Aurora.Color.to_color_info(:primary)

      # Apply color to text
      colored_text = Aurora.Color.apply_color("Hello!", :primary)

      # Manipulate brightness
      lighter_color = Aurora.Color.aclarar(color, 2)   # 2 tones lighter
      darker_color = Aurora.Color.oscurecer(color, 3)  # 3 tones darker

      # Convert between formats
      rgb = Aurora.Color.hex_to_rgb("#FF0000")      # {255, 0, 0}
      hex = Aurora.Color.rgb_to_hex({255, 0, 0})    # "#FF0000"
      hsv = Aurora.Color.rgb_to_hsv({255, 0, 0})    # {0.0, 1.0, 1.0}

      # Get all configured colors
      colors = Aurora.Color.get_all_colors()

      # Find color by name
      primary_color = Aurora.Color.find_by_name(:primary)

  ## Configuration

  Colors are configured in `config/config.exs`:

      config :aurora, :colors,
        colors: %{
          primary: %{hex: "#A1E7FA", ...},
          error: %{hex: "#FF5555", ...}
        },
        gradients: %{
          fire: [...],
          ocean: [...]
        }

  ## ColorInfo Struct

  All conversions return a `%ColorInfo{}` struct containing:

  - `hex` - Hexadecimal representation
  - `rgb` - RGB tuple
  - `argb` - ARGB tuple (with alpha)
  - `hsv` - HSV tuple
  - `hsl` - HSL tuple
  - `cmyk` - CMYK tuple
  - `name` - Color name (if applicable)
  - `inverted` - Boolean indicating if inverted
  """

  alias Aurora.Structs.{ChunkText, ColorInfo}

  @colors_config Application.compile_env(:aurora, :colors)[:colors]
  @gradients_config Application.compile_env(:aurora, :colors)[:gradients]

  # ========== CONVERSIONES ENTRE FORMATOS ==========

  @doc """
  Convierte hexadecimal a RGB.
  """
  @spec hex_to_rgb(String.t()) :: ColorInfo.rgb_tuple()
  def hex_to_rgb("#" <> hex) when byte_size(hex) == 6 do
    <<r::binary-2, g::binary-2, b::binary-2>> = hex
    {String.to_integer(r, 16), String.to_integer(g, 16), String.to_integer(b, 16)}
  end

  def hex_to_rgb(_), do: {0, 0, 0}

  @doc """
  Convierte RGB a hexadecimal.
  """
  @spec rgb_to_hex(ColorInfo.rgb_tuple()) :: String.t()
  def rgb_to_hex({r, g, b}) do
    "#" <>
      Enum.map_join(
        [r, g, b],
        "",
        &(Integer.to_string(&1, 16) |> String.pad_leading(2, "0") |> String.upcase())
      )
  end

  @doc """
  Convierte RGB a HSV.
  """
  @spec rgb_to_hsv(ColorInfo.rgb_tuple()) :: ColorInfo.hsv_tuple()
  def rgb_to_hsv({r, g, b}) do
    {r, g, b} = {r / 255, g / 255, b / 255}
    max = Enum.max([r, g, b])
    min = Enum.min([r, g, b])
    delta = max - min

    {h, s, v} =
      if delta == 0 do
        {0, 0, max}
      else
        h =
          case max do
            ^r -> (60 * ((g - b) / delta)) |> rem_float(360.0)
            ^g -> 60 * ((b - r) / delta + 2)
            ^b -> 60 * ((r - g) / delta + 4)
          end

        {if(h < 0, do: h + 360, else: h), delta / max, max}
      end

    {h, s, v}
  end

  @doc """
  Convierte HSV a RGB.
  """
  @spec hsv_to_rgb(ColorInfo.hsv_tuple()) :: ColorInfo.rgb_tuple()
  def hsv_to_rgb({h, s, v}) do
    c = v * s
    x = c * (1 - abs(rem_float(h / 60, 2) - 1))
    m = v - c

    {r1, g1, b1} = get_hue_sector(h, c, x)

    {
      round((r1 + m) * 255),
      round((g1 + m) * 255),
      round((b1 + m) * 255)
    }
  end

  defp get_hue_sector(h, c, x) when h >= 0 and h < 60, do: {c, x, 0}
  defp get_hue_sector(h, c, x) when h >= 60 and h < 120, do: {x, c, 0}
  defp get_hue_sector(h, c, x) when h >= 120 and h < 180, do: {0, c, x}
  defp get_hue_sector(h, c, x) when h >= 180 and h < 240, do: {0, x, c}
  defp get_hue_sector(h, c, x) when h >= 240 and h < 300, do: {x, 0, c}
  defp get_hue_sector(h, c, x) when h >= 300 and h < 360, do: {c, 0, x}

  @doc """
  Convierte RGB a HSL.
  """
  @spec rgb_to_hsl(ColorInfo.rgb_tuple()) :: ColorInfo.hsl_tuple()
  def rgb_to_hsl({r, g, b}) do
    {r, g, b} = {r / 255, g / 255, b / 255}
    max = Enum.max([r, g, b])
    min = Enum.min([r, g, b])
    delta = max - min

    l = (max + min) / 2

    {h, s} =
      if delta == 0 do
        {0, 0}
      else
        s = delta / (1 - abs(2 * l - 1))

        h =
          case max do
            ^r -> (60 * ((g - b) / delta)) |> rem_float(360.0)
            ^g -> 60 * ((b - r) / delta + 2)
            ^b -> 60 * ((r - g) / delta + 4)
          end

        {if(h < 0, do: h + 360, else: h), s}
      end

    {h, s, l}
  end

  @doc """
  Convierte HSL a RGB.
  """
  @spec hsl_to_rgb(ColorInfo.hsl_tuple()) :: ColorInfo.rgb_tuple()
  def hsl_to_rgb({h, s, l}) do
    c = (1 - abs(2 * l - 1)) * s
    x = c * (1 - abs(rem_float(h / 60, 2) - 1))
    m = l - c / 2

    {r1, g1, b1} = get_hue_sector(h, c, x)

    {
      round((r1 + m) * 255),
      round((g1 + m) * 255),
      round((b1 + m) * 255)
    }
  end

  @doc """
  Convierte RGB a CMYK.
  """
  @spec rgb_to_cmyk(ColorInfo.rgb_tuple()) :: ColorInfo.cmyk_tuple()
  def rgb_to_cmyk({r, g, b}) do
    {r, g, b} = {r / 255, g / 255, b / 255}
    k = 1 - Enum.max([r, g, b])

    if k == 1 do
      {0, 0, 0, 1}
    else
      c = (1 - r - k) / (1 - k)
      m = (1 - g - k) / (1 - k)
      y = (1 - b - k) / (1 - k)
      {c, m, y, k}
    end
  end

  @doc """
  Convierte CMYK a RGB.
  """
  @spec cmyk_to_rgb(ColorInfo.cmyk_tuple()) :: ColorInfo.rgb_tuple()
  def cmyk_to_rgb({c, m, y, k}) do
    r = 255 * (1 - c) * (1 - k)
    g = 255 * (1 - m) * (1 - k)
    b = 255 * (1 - y) * (1 - k)
    {round(r), round(g), round(b)}
  end

  @doc """
  Convierte RGB a ARGB.
  """
  @spec rgb_to_argb(ColorInfo.rgb_tuple()) :: ColorInfo.argb_tuple()
  def rgb_to_argb({r, g, b}), do: {255, r, g, b}

  @doc """
  Convierte ARGB a RGB.
  """
  @spec argb_to_rgb(ColorInfo.argb_tuple()) :: ColorInfo.rgb_tuple()
  def argb_to_rgb({_a, r, g, b}), do: {r, g, b}

  # Función auxiliar para módulo flotante
  defp rem_float(a, b) do
    a - b * Float.floor(a / b)
  end

  # ========== DETECCIÓN Y CREACIÓN DE COLORINFO ==========

  @doc """
  Convierte cualquier formato de color a ColorInfo detectando automáticamente el tipo.

  Aurora.Color es un conversor universal que puede recibir cualquier formato de color
  y convertirlo a un ColorInfo completo con todos los formatos calculados.

  ## Formatos soportados automáticamente:
    - Átomo: `:primary`, `:error`, etc.
    - Hexadecimal: `"#FF0000"`, `"#A1E7FA"`
    - RGB: `{255, 0, 0}` (valores enteros 0-255)
    - ARGB: `{255, 255, 0, 0}` (valores enteros 0-255)
    - ColorInfo: `%ColorInfo{}`

  Para formatos ambiguos (HSV, HSL, CMYK), usa las funciones específicas:
  - `from_hsv/1` para colores HSV
  - `from_hsl/1` para colores HSL
  - `from_cmyk/1` para colores CMYK

  ## Ejemplos:
      iex> result = Aurora.Color.to_color_info(:primary)
      iex> result.name
      :primary

      iex> result = Aurora.Color.to_color_info("#FF0000")
      iex> result.hex
      "#FF0000"

      iex> result = Aurora.Color.to_color_info({255, 0, 0})
      iex> result.hex
      "#FF0000"
  """
  @spec to_color_info(any()) :: ColorInfo.t()
  def to_color_info(%ColorInfo{} = color_info), do: color_info

  def to_color_info(atom) when is_atom(atom) do
    case Map.get(get_all_colors(), atom) do
      nil -> get_default_color()
      %ColorInfo{} = color_info -> color_info
      color_map when is_map(color_map) -> struct(ColorInfo, color_map)
    end
  end

  def to_color_info(hex) when is_binary(hex) do
    if String.starts_with?(hex, "#") do
      rgb = hex_to_rgb(hex)
      create_color_info_from_rgb(rgb, hex: hex)
    else
      get_default_color()
    end
  end

  def to_color_info({r, g, b}) when is_integer(r) and is_integer(g) and is_integer(b) do
    create_color_info_from_rgb({r, g, b})
  end

  def to_color_info({a, r, g, b})
      when is_integer(a) and is_integer(r) and is_integer(g) and is_integer(b) do
    rgb = {r, g, b}
    hex = rgb_to_hex(rgb)
    create_color_info_from_rgb(rgb, hex: hex, argb: {a, r, g, b})
  end

  def to_color_info(_), do: get_default_color()

  @doc """
  Crea ColorInfo específicamente desde formato HSV.

  ## Parámetros:
    - h: Hue (0.0-360.0)
    - s: Saturation (0.0-1.0)
    - v: Value (0.0-1.0)
  """
  @spec from_hsv({number(), number(), number()}) :: ColorInfo.t()
  def from_hsv({h, s, v}) when is_number(h) and is_number(s) and is_number(v) do
    rgb = hsv_to_rgb({h, s, v})
    create_color_info_from_rgb(rgb, hsv: {h, s, v})
  end

  @doc """
  Crea ColorInfo específicamente desde formato HSL.

  ## Parámetros:
    - h: Hue (0.0-360.0)
    - s: Saturation (0.0-1.0)
    - l: Lightness (0.0-1.0)
  """
  @spec from_hsl({number(), number(), number()}) :: ColorInfo.t()
  def from_hsl({h, s, l}) when is_number(h) and is_number(s) and is_number(l) do
    rgb = hsl_to_rgb({h, s, l})
    create_color_info_from_rgb(rgb, hsl: {h, s, l})
  end

  @doc """
  Crea ColorInfo específicamente desde formato CMYK.

  ## Parámetros:
    - c: Cyan (0.0-1.0)
    - m: Magenta (0.0-1.0)
    - y: Yellow (0.0-1.0)
    - k: Key/Black (0.0-1.0)
  """
  @spec from_cmyk({number(), number(), number(), number()}) :: ColorInfo.t()
  def from_cmyk({c, m, y, k})
      when is_number(c) and is_number(m) and is_number(y) and is_number(k) do
    rgb = cmyk_to_rgb({c, m, y, k})
    create_color_info_from_rgb(rgb, cmyk: {c, m, y, k})
  end

  # ========== CONVERSIONES DIRECTAS ENTRE FORMATOS ==========

  @doc """
  Convierte cualquier formato de color a hexadecimal.
  """
  @spec to_hex(any()) :: String.t()
  def to_hex(color) do
    color |> to_color_info() |> Map.get(:hex)
  end

  @doc """
  Convierte cualquier formato de color a RGB.
  """
  @spec to_rgb(any()) :: ColorInfo.rgb_tuple()
  def to_rgb(color) do
    color |> to_color_info() |> Map.get(:rgb)
  end

  @doc """
  Convierte cualquier formato de color a ARGB.
  """
  @spec to_argb(any()) :: ColorInfo.argb_tuple()
  def to_argb(color) do
    color |> to_color_info() |> Map.get(:argb)
  end

  @doc """
  Convierte cualquier formato de color a HSV.
  """
  @spec to_hsv(any()) :: ColorInfo.hsv_tuple()
  def to_hsv(color) do
    color |> to_color_info() |> Map.get(:hsv)
  end

  @doc """
  Convierte cualquier formato de color a HSL.
  """
  @spec to_hsl(any()) :: ColorInfo.hsl_tuple()
  def to_hsl(color) do
    color |> to_color_info() |> Map.get(:hsl)
  end

  @doc """
  Convierte cualquier formato de color a CMYK.
  """
  @spec to_cmyk(any()) :: ColorInfo.cmyk_tuple()
  def to_cmyk(color) do
    color |> to_color_info() |> Map.get(:cmyk)
  end

  defp create_color_info_from_rgb(rgb, opts \\ []) do
    hex = Keyword.get(opts, :hex, rgb_to_hex(rgb))
    argb = Keyword.get(opts, :argb, rgb_to_argb(rgb))
    hsv = Keyword.get(opts, :hsv, rgb_to_hsv(rgb))
    hsl = Keyword.get(opts, :hsl, rgb_to_hsl(rgb))
    cmyk = Keyword.get(opts, :cmyk, rgb_to_cmyk(rgb))

    %ColorInfo{
      hex: hex,
      rgb: rgb,
      argb: argb,
      hsv: hsv,
      hsl: hsl,
      cmyk: cmyk,
      name: nil,
      inverted: false
    }
  end

  # ========== APLICACIÓN A ANSI ==========

  @doc """
  Convierte ColorInfo a código ANSI para terminal.
  """
  @spec color_info_to_ansi(ColorInfo.t()) :: String.t()
  def color_info_to_ansi(%ColorInfo{hex: hex, inverted: inverted}) do
    {r, g, b} = hex_to_rgb(hex)
    color_code = "\e[38;2;#{r};#{g};#{b}m"

    if inverted do
      "\e[7m#{color_code}"
    else
      color_code
    end
  end

  @doc """
  Aplica color ANSI a texto.

  ## Parámetros:
    - text: Texto al que aplicar el color
    - color: Cualquier formato de color soportado
    - opts: Opciones adicionales

  ## Opciones:
    - `:inverted` - boolean, invierte el color (solo funciona en ANSI)
    - `:background` - boolean, aplica como color de fondo

  ## Ejemplos:
      iex> Aurora.Color.apply_color("Hola", :primary)
      "\\e[38;2;161;231;250mHola\\e[0m"

      iex> Aurora.Color.apply_color("Hola", "#FF0000", inverted: true)
      "\\e[7m\\e[38;2;255;0;0mHola\\e[0m"
  """
  @spec apply_color(String.t(), any(), keyword()) :: String.t()
  def apply_color(text, color, opts \\ []) do
    color_info = to_color_info(color)

    # Aplicar inversión si se solicita
    color_info =
      if Keyword.get(opts, :inverted, false) do
        %{color_info | inverted: true}
      else
        color_info
      end

    ansi_code =
      if Keyword.get(opts, :background, false) do
        color_info_to_background_ansi(color_info)
      else
        color_info_to_ansi(color_info)
      end

    "#{ansi_code}#{text}\e[0m"
  end

  @doc """
  Aplica color de fondo ANSI a texto.
  """
  @spec apply_background_color(String.t(), any(), keyword()) :: String.t()
  def apply_background_color(text, color, opts \\ []) do
    apply_color(text, color, Keyword.put(opts, :background, true))
  end

  @doc """
  Aplica color invertido ANSI a texto.
  """
  @spec apply_inverted_color(String.t(), any()) :: String.t()
  def apply_inverted_color(text, color) do
    apply_color(text, color, inverted: true)
  end

  @doc """
  Convierte ColorInfo a código ANSI para color de fondo.
  """
  @spec color_info_to_background_ansi(ColorInfo.t()) :: String.t()
  def color_info_to_background_ansi(%ColorInfo{hex: hex, inverted: inverted}) do
    {r, g, b} = hex_to_rgb(hex)
    color_code = "\e[48;2;#{r};#{g};#{b}m"

    if inverted do
      "\e[7m#{color_code}"
    else
      color_code
    end
  end

  # ========== GESTIÓN DE CONFIGURACIÓN ==========

  @doc """
  Devuelve el color por defecto.
  """
  @spec get_default_color() :: ColorInfo.t()
  def get_default_color, do: %ColorInfo{}

  @doc """
  Devuelve todos los colores del config.
  """
  @spec get_all_colors() :: %{atom() => ColorInfo.t() | map()}
  def get_all_colors, do: Map.merge(@colors_config, @gradients_config)

  @doc """
  Obtiene información de color (alias de to_color_info/1 para compatibilidad).
  """
  @spec get_color_info(any()) :: ColorInfo.t()
  def get_color_info(color), do: to_color_info(color)

  @doc """
  Devuelve los gradientes configurados.
  """
  @spec gradients() :: %{atom() => ColorInfo.t() | map()}
  def gradients do
    # Asegurar que devolvemos el mapa de gradientes directamente
    @gradients_config
  end

  @doc """
  Obtiene un gradiente específico por nombre.
  """
  @spec get_gradient(atom()) :: [ColorInfo.t()] | nil
  def get_gradient(name) do
    case Map.get(@gradients_config, name) do
      nil ->
        nil

      colors when is_list(colors) ->
        Enum.map(colors, &to_color_info/1)

      _ ->
        nil
    end
  end

  @doc """
  Busca color por nombre.
  """
  @spec find_by_name(atom()) :: ColorInfo.t() | nil
  def find_by_name(name) do
    case Map.get(get_all_colors(), name) do
      nil -> nil
      %ColorInfo{} = color_info -> color_info
      color_map when is_map(color_map) -> struct(ColorInfo, color_map)
    end
  end

  # ========== GRADIENTES ==========

  @doc """
  Expande lista de colores a exactamente 6 posiciones.
  """
  @spec expand_gradient([any()]) :: [ColorInfo.t()]
  def expand_gradient(colors) when is_list(colors) do
    colors = Enum.map(colors, &to_color_info/1)

    case length(colors) do
      1 ->
        List.duplicate(hd(colors), 6)

      2 ->
        [c1, c2] = colors
        [c1, c1, c1, c2, c2, c2]

      3 ->
        [c1, c2, c3] = colors
        [c1, c1, c2, c2, c3, c3]

      4 ->
        [c1, c2, c3, c4] = colors
        [c1, c1, c2, c3, c4, c4]

      5 ->
        [c1, c2, c3, c4, c5] = colors
        [c1, c2, c3, c3, c4, c5]

      6 ->
        colors

      _ ->
        List.duplicate(get_default_color(), 6)
    end
  end

  def expand_gradient(_), do: List.duplicate(get_default_color(), 6)

  @doc """
  Aplica un gradiente horizontal a un texto, similar a gterm.

  Calcula colores intermedios entre los colores proporcionados y los distribuye
  proporcionalmente a lo largo del texto.

  ## Parámetros
    - `text`: Texto al que aplicar el gradiente
    - `colors`: Lista de 2 a 6 colores para el gradiente

  ## Ejemplos
      Aurora.Color.apply_gradient("Hello World", [:red, :blue])
      Aurora.Color.apply_gradient("Gradient", ["#FF0000", "#00FF00", "#0000FF"])
  """
  @spec apply_gradient(String.t(), [any()]) :: String.t()
  def apply_gradient(text, colors)
      when is_binary(text) and is_list(colors) and length(colors) >= 2 do
    # Validar y limitar a máximo 6 colores como gterm
    valid_colors = Enum.take(colors, 6)
    color_infos = Enum.map(valid_colors, &to_color_info/1)

    # Calcular colores del gradiente
    gradient_colors = calculate_gradient_colors(color_infos, String.length(text))

    # Aplicar colores carácter por carácter
    apply_gradient_to_chars(text, gradient_colors)
  end

  def apply_gradient(text, _colors), do: text

  @doc """
  Aplica gradiente a un ChunkText, creando múltiples chunks con el gradiente aplicado.
  """
  @spec apply_gradient_to_chunk(ChunkText.t(), [any()]) :: [ChunkText.t()]
  def apply_gradient_to_chunk(%ChunkText{} = chunk, colors)
      when is_list(colors) and length(colors) >= 2 do
    text = chunk.text
    valid_colors = Enum.take(colors, 6)
    color_infos = Enum.map(valid_colors, &to_color_info/1)
    gradient_colors = calculate_gradient_colors(color_infos, String.length(text))

    # Crear chunks individuales para cada carácter con su color del gradiente
    text
    |> String.graphemes()
    |> Enum.with_index()
    |> Enum.map(fn {char, index} ->
      color = Enum.at(gradient_colors, index)

      %ChunkText{
        text: char,
        color: color,
        pos_x: chunk.pos_x,
        pos_y: chunk.pos_y,
        effects: chunk.effects
      }
    end)
  end

  @doc """
  Aplica gradiente a múltiples ChunkText.
  """
  @spec apply_gradient_to_chunks([ChunkText.t()], [any()]) :: [ChunkText.t()]
  def apply_gradient_to_chunks(chunks, colors) when is_list(chunks) and is_list(colors) do
    Enum.flat_map(chunks, fn chunk ->
      if String.length(chunk.text) > 0 do
        apply_gradient_to_chunk(chunk, colors)
      else
        [chunk]
      end
    end)
  end

  # ========== ALGORITMO DE GRADIENTE ==========

  defp calculate_gradient_colors(color_infos, text_length) when length(color_infos) == 1 do
    # Caso especial: un solo color
    List.duplicate(hd(color_infos), text_length)
  end

  defp calculate_gradient_colors(color_infos, text_length) do
    # Calcular segmentos del gradiente (similar a gterm)
    segments = length(color_infos) - 1
    segment_length = Float.ceil(text_length / segments)

    # Generar colores para cada posición del texto
    Enum.map(0..(text_length - 1), fn position ->
      calculate_color_at_position(position, color_infos, segment_length, segments)
    end)
  end

  defp calculate_color_at_position(position, color_infos, segment_length, segments) do
    # Determinar en qué segmento estamos
    segment_index = min(floor(position / segment_length), segments - 1)

    # Colores de inicio y fin del segmento
    start_color = Enum.at(color_infos, segment_index)
    end_color = Enum.at(color_infos, segment_index + 1)

    # Posición relativa dentro del segmento
    segment_start = segment_index * segment_length
    segment_position = position - segment_start
    ratio = segment_position / segment_length

    # Interpolar entre los dos colores
    interpolate_colors(start_color, end_color, ratio)
  end

  defp interpolate_colors(start_color, end_color, ratio) do
    {start_r, start_g, start_b} = start_color.rgb
    {end_r, end_g, end_b} = end_color.rgb

    r = round(start_r + (end_r - start_r) * ratio)
    g = round(start_g + (end_g - start_g) * ratio)
    b = round(start_b + (end_b - start_b) * ratio)

    to_color_info({r, g, b})
  end

  defp apply_gradient_to_chars(text, gradient_colors) do
    text
    |> String.graphemes()
    |> Enum.with_index()
    |> Enum.map_join(fn {char, index} ->
      color = Enum.at(gradient_colors, index)
      apply_color(char, color)
    end)
  end

  # ========== COMPATIBILIDAD CON CHUNKTEXT ==========

  @doc """
  Aplica color a ChunkText.
  """
  @spec apply_to_chunk(ChunkText.t() | [ChunkText.t()]) :: ChunkText.t() | [ChunkText.t()]
  def apply_to_chunk(chunks) when is_list(chunks), do: Enum.map(chunks, &apply_to_chunk/1)

  def apply_to_chunk(%ChunkText{text: text, color: color} = chunk) do
    colored_text = apply_color(text, color)
    %ChunkText{chunk | text: colored_text}
  end

  # ========== MANIPULACIÓN DE COLORES ==========

  @doc """
  Aclara un color aumentando su luminosidad en HSL.

  ## Parámetros:
    - `color_info`: ColorInfo a aclarar
    - `tonos`: Número entero positivo de tonos a aclarar (cada tono = +8.33% de luminosidad)

  ## Ejemplos:
      iex> color = Aurora.Color.to_color_info("#336699")
      iex> aclarado = Aurora.Color.aclarar(color, 2)
      iex> aclarado.hex  # 2 tonos más claro
      "#5990C8"
  """
  @spec aclarar(ColorInfo.t(), non_neg_integer()) :: ColorInfo.t()
  def aclarar(color_info, 0), do: color_info

  def aclarar(%ColorInfo{hsl: {h, s, l}} = color_info, tonos) when tonos > 0 do
    # Cada tono = ~8.33% de luminosidad
    incremento = tonos * 0.0833
    new_l = min(l + incremento, 1.0)
    new_rgb = hsl_to_rgb({h, s, new_l})
    update_color_info(color_info, new_rgb)
  end

  def aclarar(color_info, _tonos), do: color_info

  @doc """
  Oscurece un color disminuyendo su luminosidad en HSL.

  ## Parámetros:
    - `color_info`: ColorInfo a oscurecer
    - `tonos`: Número entero positivo de tonos a oscurecer (cada tono = -8.33% de luminosidad)

  ## Ejemplos:
      iex> color = Aurora.Color.to_color_info("#336699")
      iex> oscurecido = Aurora.Color.oscurecer(color, 2)
      iex> oscurecido.hex  # 2 tonos más oscuro
      "#1E3C59"
  """
  @spec oscurecer(ColorInfo.t(), non_neg_integer()) :: ColorInfo.t()
  def oscurecer(color_info, 0), do: color_info

  def oscurecer(%ColorInfo{hsl: {h, s, l}} = color_info, tonos) when tonos > 0 do
    # Cada tono = ~8.33% de luminosidad
    decremento = tonos * 0.0833
    new_l = max(l - decremento, 0.0)
    new_rgb = hsl_to_rgb({h, s, new_l})
    update_color_info(color_info, new_rgb)
  end

  def oscurecer(color_info, _tonos), do: color_info

  defp update_color_info(%ColorInfo{} = original, new_rgb) do
    %ColorInfo{
      original
      | hex: rgb_to_hex(new_rgb),
        rgb: new_rgb,
        argb: rgb_to_argb(new_rgb),
        hsv: rgb_to_hsv(new_rgb),
        hsl: rgb_to_hsl(new_rgb),
        cmyk: rgb_to_cmyk(new_rgb)
    }
  end
end
