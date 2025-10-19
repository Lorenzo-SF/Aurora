defmodule Aurora.Color do
  @moduledoc """
  Sistema completo de gestión de colores con soporte para múltiples formatos.

  Proporciona conversión entre formatos de color (HEX, RGB, HSV, HSL, CMYK, ARGB),
  aplicación de colores ANSI en terminal, y manipulación de colores (aclarar/oscurecer).

  ## Características

  - Conversión automática entre formatos de color
  - Aplicación de colores ANSI para terminal
  - Manipulación de luminosidad (aclarar/oscurecer)
  - Soporte para colores invertidos
  - Gestión de paletas de colores configurables
  - Sistema de gradientes expandibles

  ## Formatos Soportados

  - **HEX**: `"#FF0000"`, `"#A1E7FA"`
  - **RGB**: `{255, 0, 0}`
  - **ARGB**: `{255, 255, 0, 0}`
  - **HSV**: `{0.0, 1.0, 1.0}` (Hue, Saturation, Value)
  - **HSL**: `{0.0, 1.0, 0.5}` (Hue, Saturation, Lightness)
  - **CMYK**: `{0.0, 1.0, 1.0, 0.0}` (Cyan, Magenta, Yellow, Key/Black)
  - **Átomo**: `:primary`, `:error`, `:success`, etc.
  - **Struct**: `%ColorInfo{}`

  ## Uso Básico

      # Conversión automática de formato
      color = Aurora.Color.to_color_info("#FF0000")
      color = Aurora.Color.to_color_info({255, 0, 0})
      color = Aurora.Color.to_color_info(:primary)

      # Aplicar color a texto
      texto_coloreado = Aurora.Color.apply_color("¡Hola!", :primary)

      # Manipular luminosidad
      color_claro = Aurora.Color.aclarar(color, 2)   # 2 tonos más claro
      color_oscuro = Aurora.Color.oscurecer(color, 3) # 3 tonos más oscuro

      # Convertir entre formatos
      rgb = Aurora.Color.hex_to_rgb("#FF0000")      # {255, 0, 0}
      hex = Aurora.Color.rgb_to_hex({255, 0, 0})    # "#FF0000"
      hsv = Aurora.Color.rgb_to_hsv({255, 0, 0})    # {0.0, 1.0, 1.0}

  ## Configuración

  Los colores se configuran en `config/config.exs`:

      config :aurora, :colors,
        colors: %{
          primary: %{hex: "#A1E7FA", ...},
          error: %{hex: "#FF5555", ...}
        },
        gradients: %{
          fire: [...],
          ocean: [...]
        }

  ## Struct ColorInfo

  Todas las conversiones devuelven un struct `%ColorInfo{}` que contiene:

  - `hex` - Representación hexadecimal
  - `rgb` - Tupla RGB
  - `argb` - Tupla ARGB (con alpha)
  - `hsv` - Tupla HSV
  - `hsl` - Tupla HSL
  - `cmyk` - Tupla CMYK
  - `name` - Nombre del color (si aplica)
  - `inverted` - Boolean indicando si está invertido
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

  ## Formatos soportados:
    - Átomo: `:primary`, `:error`, etc.
    - Hexadecimal: `"#FF0000"`, `"#A1E7FA"`
    - RGB: `{255, 0, 0}`
    - ARGB: `{255, 255, 0, 0}`
    - HSV: `{0.0, 1.0, 1.0}`
    - HSL: `{0.0, 1.0, 0.5}`
    - CMYK: `{0.0, 1.0, 1.0, 0.0}`
    - ColorInfo: `%ColorInfo{}`

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

  def to_color_info({h, s, v}) when is_number(h) and is_number(s) and is_number(v) do
    rgb = hsv_to_rgb({h, s, v})
    create_color_info_from_rgb(rgb, hsv: {h, s, v})
  end

  def to_color_info({h, s, l}) when is_number(h) and is_number(s) and is_number(l) do
    rgb = hsl_to_rgb({h, s, l})
    create_color_info_from_rgb(rgb, hsl: {h, s, l})
  end

  def to_color_info({c, m, y, k})
      when is_number(c) and is_number(m) and is_number(y) and is_number(k) do
    rgb = cmyk_to_rgb({c, m, y, k})
    create_color_info_from_rgb(rgb, cmyk: {c, m, y, k})
  end

  def to_color_info(_), do: get_default_color()

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
  """
  @spec apply_color(String.t(), any()) :: String.t()
  def apply_color(text, color) do
    color_info = to_color_info(color)
    ansi_code = color_info_to_ansi(color_info)
    "#{ansi_code}#{text}\e[0m"
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
  def gradients, do: @gradients_config

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
