defmodule Aurora.Color do
  @moduledoc """
  Módulo para manejo de colores en terminal con soporte ANSI.

  Este módulo proporciona funcionalidades completas para trabajar con colores
  en terminal, incluyendo colores predefinidos, colores personalizados en formato
  hexadecimal, conversiones RGB y generación de gradientes.

  ## Características principales

  - Colores predefinidos del sistema
  - Soporte para colores hexadecimales
  - Conversión RGB a códigos ANSI
  - Generación de gradientes de color
  - Inversión de colores
  - Aplicación de colores a texto

  ## Colores predefinidos

  El sistema incluye los siguientes colores predefinidos:

  - `:primary` - Azul principal
  - `:secondary` - Cian secundario
  - `:ternary` - Magenta terciario
  - `:quaternary` - Amarillo cuaternario
  - `:success` - Verde para éxito
  - `:warning` - Amarillo para advertencias
  - `:error` - Rojo para errores
  - `:info` - Azul para información
  - `:debug` - Gris para debug
  - `:menu` - Color para menús
  - `:no_color` - Sin color

  ## Uso básico

      iex> color = Aurora.Color.resolve_color(:primary)
      iex> Aurora.Color.apply_color("Texto", color)

      iex> custom_color = Aurora.Color.resolve_color("#FF0000")
      iex> Aurora.Color.apply_color("Rojo", custom_color)

  ## Gradientes

      iex> gradient = Aurora.Color.generate_gradient_between("#FF0000", "#00FF00")
      iex> length(gradient)
      6
  """

  alias Aurora.Structs.{ChunkText, ColorInfo}

  @colors Application.compile_env(:aurora, :colors)[:colors]
  @gradients Application.compile_env(:aurora, :colors)[:gradients]

  @doc """
  Devuelve el mapa de colores configurados (name => ColorInfo struct).
  """
  def all_colors_availables do
    Map.merge(colors(), gradients())
  end

  def get_default_color, do: %ColorInfo{}

  def colors do
    colors_config = @colors || %{}

    colors_config
    |> Enum.map(fn {name, %{hex: hex}} ->
      {name, %ColorInfo{name: name, hex: normalize_hex(hex), inverted: false}}
    end)
    |> Map.new()
  end

  def gradients do
    gradients_config = @gradients || %{}

    gradients_config
    |> Enum.map(fn {name, %{hex: hex}} ->
      {name, %ColorInfo{name: name, hex: normalize_hex(hex), inverted: false}}
    end)
    |> Map.new()
  end

  def get_all_colors do
    Map.merge(colors(), gradients())
  end

  @doc """
  Dado un atom o hex string, devuelve el ColorInfo si está o es válido.
  """
  def get_color_info(atom) when is_atom(atom) do
    case Map.get(get_all_colors(), atom) do
      nil -> get_color_info(:no_color)
      %ColorInfo{} = ci -> ci
    end
  end

  def get_color_info(hex) when is_binary(hex) do
    if valid_hex?(hex) do
      %ColorInfo{name: nil, hex: normalize_hex(hex), inverted: false}
    else
      get_color_info(:no_color)
    end
  end

  def get_color_info(_), do: get_color_info(:no_color)

  def expand_gradient_colors(colors) when is_list(colors) and length(colors) == 1,
    do: List.duplicate(Enum.at(colors, 0), 6)

  def expand_gradient_colors(colors) when is_list(colors) and length(colors) == 2,
    do: List.duplicate(Enum.at(colors, 0), 3) ++ List.duplicate(Enum.at(colors, 1), 3)

  def expand_gradient_colors(colors) when is_list(colors) and length(colors) == 3,
    do:
      List.duplicate(Enum.at(colors, 0), 2) ++
        List.duplicate(Enum.at(colors, 1), 2) ++ List.duplicate(Enum.at(colors, 2), 2)

  def expand_gradient_colors(colors) when is_list(colors) and length(colors) == 4,
    do: [
      Enum.at(colors, 0),
      Enum.at(colors, 0),
      Enum.at(colors, 1),
      Enum.at(colors, 2),
      Enum.at(colors, 3),
      Enum.at(colors, 3)
    ]

  def expand_gradient_colors(colors) when is_list(colors) and length(colors) == 5,
    do: [
      Enum.at(colors, 0),
      Enum.at(colors, 1),
      Enum.at(colors, 2),
      Enum.at(colors, 2),
      Enum.at(colors, 3),
      Enum.at(colors, 4)
    ]

  def expand_gradient_colors(colors) when is_list(colors) and length(colors) == 6,
    do: colors

  def expand_gradient_colors(_), do: List.duplicate(get_color_info(:no_color), 6)

  def apply_color(text, %ColorInfo{hex: hex, inverted: inverted}) when is_binary(hex) do
    {r, g, b} = hex_to_rgb(hex)
    colored = "\e[38;2;#{r};#{g};#{b}m#{text}\e[0m"

    if inverted do
      "\e[7m#{colored}\e[27m"
    else
      colored
    end
  end

  def apply_color(text, _), do: text

  @doc """
  Aplica colores a una lista de ChunkText.
  """
  def apply_to_chunk(chunks) when is_list(chunks) do
    Enum.map(chunks, &apply_to_chunk/1)
  end

  def apply_to_chunk(%ChunkText{text: text, color: color} = chunk) do
    ci = resolve_color(color)
    %ChunkText{chunk | text: apply_color(text, ci)}
  end

  def resolve_color(nil), do: get_color_info(:no_color)
  def resolve_color(%ColorInfo{} = ci), do: ci
  def resolve_color({_, hex}), do: get_color_info(hex)
  def resolve_color(atom) when is_atom(atom), do: get_color_info(atom)
  def resolve_color(bin) when is_binary(bin), do: get_color_info(bin)
  def resolve_color(_), do: get_color_info(:no_color)

  @doc """
  Normaliza un hexadecimal para que tenga formato `#XXXXXX` en mayúsculas.
  """
  def normalize_hex(hex) when is_binary(hex) do
    hex
    |> String.trim()
    |> String.replace_prefix("#", "")
    |> String.upcase()
    |> then(&"##{&1}")
  end

  def valid_hex?(hex) when is_binary(hex) do
    String.match?(hex, ~r/^#([A-F0-9]{6})$/i)
  end

  def valid_hex?(_), do: false

  def rgb_to_ansi256({r, g, b}) when r in 0..255 and g in 0..255 and b in 0..255 do
    # Mapeamos 0..255 a 0..5
    r6 = div(r * 6, 256) |> clamp6()
    g6 = div(g * 6, 256) |> clamp6()
    b6 = div(b * 6, 256) |> clamp6()
    16 + r6 * 36 + g6 * 6 + b6
  end

  defp clamp6(n) when n < 0, do: 0
  defp clamp6(n) when n > 5, do: 5
  defp clamp6(n), do: n

  @doc """
  Convierte hex #RRGGBB a {r,g,b} tuple con valores 0..255.
  """
  def hex_to_rgb("#" <> hex) when byte_size(hex) == 6 do
    <<r::binary-size(2), g::binary-size(2), b::binary-size(2)>> = hex
    {String.to_integer(r, 16), String.to_integer(g, 16), String.to_integer(b, 16)}
  end

  def hex_to_rgb(_), do: {0, 0, 0}

  @doc """
  Genera un gradiente de 6 colores a partir de un color central en la posición `pos`.
  Los colores hacia la izquierda son más oscuros y hacia la derecha más claros.
  """
  def generate_gradient_from_color(hex, pos) do
    if valid_hex?(hex) and pos in 0..5 do
      {r, g, b} = hex_to_rgb(hex)

      left =
        for i <- (pos - 1)..0, reduce: [] do
          acc ->
            factor = (pos - i) / pos * 0.5
            dark_rgb = {round(r * (1 - factor)), round(g * (1 - factor)), round(b * (1 - factor))}
            [rgb_to_hex(dark_rgb) | acc]
        end

      right =
        for i <- (pos + 1)..5 do
          factor = (i - pos) / (5 - pos) * 0.5

          light_rgb =
            {round(r + (255 - r) * factor), round(g + (255 - g) * factor),
             round(b + (255 - b) * factor)}

          rgb_to_hex(light_rgb)
        end

      Enum.concat(left, [hex | right])
      |> Enum.map(&normalize_hex/1)
    else
      [hex, hex, hex, hex, hex]
    end
  end

  @doc """
  Genera un gradiente de 6 colores entre `first_hex` y `last_hex`.
  Calcula los colores intermedios de forma lineal.
  """
  def generate_gradient_between(first_hex, last_hex) do
    if valid_hex?(first_hex) and valid_hex?(last_hex) do
      {r1, g1, b1} = hex_to_rgb(first_hex)
      {r2, g2, b2} = hex_to_rgb(last_hex)

      0..5
      |> Enum.map(fn i ->
        r = round(r1 + (r2 - r1) * i / 5)
        g = round(g1 + (g2 - g1) * i / 5)
        b = round(b1 + (b2 - b1) * i / 5)
        rgb_to_hex({r, g, b})
      end)
      |> Enum.map(&normalize_hex/1)
    else
      get_default_color().hex
    end
  end

  def darken_rgb({r, g, b}, amount) do
    {max(r - amount, 0), max(g - amount, 0), max(b - amount, 0)}
  end

  def lighten_rgb({r, g, b}, amount) do
    {min(r + amount, 255), min(g + amount, 255), min(b + amount, 255)}
  end

  def rgb_to_hex({r, g, b}),
    do:
      "#" <>
        Enum.map_join([r, g, b], "", fn x ->
          Integer.to_string(x, 16) |> String.pad_leading(2, "0")
        end)
end
