defmodule Aurora.CLI do
  @moduledoc """
  CLI para formatear texto con colores y efectos ANSI en la terminal.

  Aurora puede usarse como herramienta de línea de comandos para generar texto
  formateado con códigos ANSI. Devuelve el string literal con los códigos de escape
  sin interpretar, perfecto para capturar en variables bash o procesar externamente.

  ## Instalación

  Compila el ejecutable:

      mix escript.build

  Esto crea el archivo `aurora` que puedes ejecutar directamente.

  ## Uso Básico

  ### Modo Texto

  Formatea uno o varios fragmentos de texto:

      ./aurora --text="¡Hola!" --color=primary --bold
      ./aurora --text="Error: " --color=error --text="Archivo no encontrado" --color=warning

  ### Modo Tabla

  Crea tablas formateadas:

      ./aurora --table --headers="Nombre,Edad" --row="Juan,25" --row="Ana,30"

  ## Opciones Principales

  **Texto:**
  - `--text=<texto>` - Texto a formatear (repetible para múltiples fragmentos)
  - `--color=<color>` - Color hex (#FF0000) o nombre (primary, error, etc.)
  - `--align=<tipo>` - Alineación: left, center, right, justify

  **Efectos:**
  - `--bold`, `--dim`, `--italic`, `--underline`
  - `--blink`, `--reverse`, `--strikethrough`

  **Manipulación de Color:**
  - `--lighten=N` - Aclara el color N tonos (1-6)
  - `--darken=N` - Oscurece el color N tonos (1-6)
  - `--inverted` - Invierte el color (intercambia fondo/texto)

  **Tabla:**
  - `--table` - Activa modo tabla
  - `--headers=<csv>` - Cabeceras separadas por comas
  - `--row=<csv>` - Fila de datos (repetible)
  - `--header-color=<color>` - Color de cabeceras
  - `--row-color=<color>` - Color de filas

  ## Salida

  El CLI devuelve el string con códigos ANSI sin interpretar:

      result=$(./aurora --text="Éxito" --color=success --bold)
      echo "$result"  # Muestra el texto con formato
  """

  # Solo los aliases necesarios
  alias Aurora.{Color, Effects, Format}
  alias Aurora.Structs.{ChunkText, EffectInfo, FormatInfo}

  @app_name "Aurora"
  @app_version "1.0.5"

  @doc """
  Main entry point for Aurora CLI commands.
  """
  def main(argv) do
    argv
    |> parse_args()
    |> execute()
  end

  defp parse_args(argv) do
    {parsed, remaining, _errors} =
      OptionParser.parse(argv,
        strict: [
          # Text chunk mode
          text: :keep,
          color: :keep,
          align: :string,
          add_line: :string,

          # Effects (apply to all chunks)
          bold: :boolean,
          dim: :boolean,
          italic: :boolean,
          underline: :boolean,
          blink: :boolean,
          reverse: :boolean,
          hidden: :boolean,
          strikethrough: :boolean,
          link: :boolean,

          # Table mode
          table: :boolean,
          headers: :string,
          row: :keep,
          header_color: :string,
          row_color: :string,
          cell_color: :keep,
          header_effects: :string,
          row_effects: :string,
          cell_effects: :keep,

          # Color manipulation
          lighten: :integer,
          darken: :integer,
          inverted: :boolean,

          # Global options
          version: :boolean,
          help: :boolean
        ],
        aliases: [
          t: :text,
          c: :color,
          a: :align,
          T: :table,
          H: :headers,
          r: :row,
          v: :version,
          h: :help
        ]
      )

    {parsed, remaining}
  end

  defp execute({opts, _remaining}) do
    result =
      cond do
        Keyword.get(opts, :version, false) ->
          version()

        Keyword.get(opts, :help, false) ->
          show_help()

        Keyword.get(opts, :table, false) ->
          execute_table(opts)

        has_text_flag?(opts) ->
          execute_text_chunks(opts)

        true ->
          show_help()
      end

    # Devolver el string literal con códigos ANSI sin interpretar
    IO.puts(inspect(result))
  end

  defp has_text_flag?(opts) do
    Keyword.has_key?(opts, :text)
  end

  # ========== TEXT CHUNK MODE ==========

  defp execute_text_chunks(opts) do
    # Extract all --text flags
    text_values = Keyword.get_values(opts, :text)
    color_values = Keyword.get_values(opts, :color)

    # Extract global options
    align = parse_align(Keyword.get(opts, :align, "left"))
    add_line = parse_add_line(Keyword.get(opts, :add_line, "none"))

    # Extract effects
    effects_list = extract_effects_from_opts(opts)
    effects = build_effect_info(effects_list)

    # Color manipulation
    lighten_tones = Keyword.get(opts, :lighten)
    darken_tones = Keyword.get(opts, :darken)
    inverted = Keyword.get(opts, :inverted, false)

    # Build ChunkText structs
    chunks =
      build_chunk_texts(text_values, color_values, effects, lighten_tones, darken_tones, inverted)

    # Create FormatInfo and format
    format_info = %FormatInfo{
      chunks: chunks,
      align: align,
      add_line: add_line,
      manual_tabs: 0,
      animation: "",
      mode: :normal
    }

    Format.format(format_info)
  end

  defp build_chunk_texts(
         text_values,
         color_values,
         effects,
         lighten_tones,
         darken_tones,
         inverted
       ) do
    text_values
    |> Enum.with_index()
    |> Enum.map(fn {text, idx} ->
      color_str = Enum.at(color_values, idx, "primary")
      color_info = resolve_chunk_color(color_str, lighten_tones, darken_tones, inverted)

      %ChunkText{
        text: text,
        color: color_info,
        effects: effects
      }
    end)
  end

  defp resolve_chunk_color(color_str, lighten_tones, darken_tones, inverted) do
    color_info =
      if String.starts_with?(color_str, "#") do
        Color.to_color_info(color_str)
      else
        Color.to_color_info(String.to_atom(color_str))
      end

    # Apply color manipulation if specified
    color_info
    |> maybe_lighten(lighten_tones)
    |> maybe_darken(darken_tones)
    |> maybe_invert(inverted)
  end

  defp maybe_lighten(color_info, nil), do: color_info

  defp maybe_lighten(color_info, tones) when is_integer(tones) and tones > 0 do
    Color.aclarar(color_info, tones)
  end

  defp maybe_lighten(color_info, _), do: color_info

  defp maybe_darken(color_info, nil), do: color_info

  defp maybe_darken(color_info, tones) when is_integer(tones) and tones > 0 do
    Color.oscurecer(color_info, tones)
  end

  defp maybe_darken(color_info, _), do: color_info

  defp maybe_invert(color_info, false), do: color_info

  defp maybe_invert(color_info, true) do
    %{color_info | inverted: true}
  end

  # ========== TABLE MODE ==========

  defp execute_table(opts) do
    headers_str = Keyword.get(opts, :headers, "")
    row_values = Keyword.get_values(opts, :row)

    # Table styling
    header_color = Keyword.get(opts, :header_color, "primary")
    row_color = Keyword.get(opts, :row_color, "secondary")
    cell_colors = Keyword.get_values(opts, :cell_color)

    # Effects
    header_effects_str = Keyword.get(opts, :header_effects, "")
    row_effects_str = Keyword.get(opts, :row_effects, "")
    cell_effects_list = Keyword.get_values(opts, :cell_effects)

    align = parse_align(Keyword.get(opts, :align, "left"))
    add_line = parse_add_line(Keyword.get(opts, :add_line, "none"))

    # Parse headers and rows
    headers = parse_csv(headers_str)
    rows = Enum.map(row_values, &parse_csv/1)

    # Build effects
    header_effects = parse_effects(header_effects_str)
    row_effects = parse_effects(row_effects_str)
    cell_effects = Enum.map(cell_effects_list, &parse_effects/1)

    # Build table chunks
    table_chunks =
      build_table_chunks(
        headers,
        rows,
        header_color,
        row_color,
        cell_colors,
        header_effects,
        row_effects,
        cell_effects
      )

    # Create FormatInfo and format as table
    format_info = %FormatInfo{
      chunks: table_chunks,
      align: align,
      add_line: add_line,
      manual_tabs: 0,
      animation: "",
      mode: :table
    }

    Format.format(format_info)
  end

  defp parse_csv(csv_string) do
    csv_string
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp parse_effects(effects_str) when is_binary(effects_str) and effects_str != "" do
    effects_str
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.map(&String.to_atom/1)
    |> Enum.filter(&Effects.valid_effect?/1)
    |> build_effect_info()
  end

  defp parse_effects(_), do: %EffectInfo{}

  defp build_table_chunks(
         headers,
         rows,
         header_color,
         row_color,
         cell_colors,
         header_effects,
         row_effects,
         cell_effects
       ) do
    header_color_atom = String.to_atom(header_color)

    # Función auxiliar para obtener color de celda
    get_color = fn idx, default_color ->
      color_str = Enum.at(cell_colors, idx, default_color)
      String.to_atom(color_str || default_color)
    end

    # Función auxiliar para obtener efectos de celda
    get_effects = fn idx, default_effects ->
      Enum.at(cell_effects, idx, default_effects)
    end

    # Construir cabeceras
    header_chunks =
      Enum.with_index(headers)
      |> Enum.map(fn {header, idx} ->
        %ChunkText{
          text: header,
          color: Color.to_color_info(header_color_atom),
          effects: get_effects.(idx, header_effects)
        }
      end)

    # Construir filas
    row_chunks =
      Enum.map(rows, fn row ->
        Enum.with_index(row)
        |> Enum.map(fn {cell, idx} ->
          %ChunkText{
            text: cell,
            color: Color.to_color_info(get_color.(idx, row_color)),
            effects: get_effects.(idx, row_effects)
          }
        end)
      end)

    [header_chunks | row_chunks]
  end

  # ========== SHARED FUNCTIONS ==========

  defp extract_effects_from_opts(opts) do
    [
      {:bold, Keyword.get(opts, :bold, false)},
      {:dim, Keyword.get(opts, :dim, false)},
      {:italic, Keyword.get(opts, :italic, false)},
      {:underline, Keyword.get(opts, :underline, false)},
      {:blink, Keyword.get(opts, :blink, false)},
      {:reverse, Keyword.get(opts, :reverse, false)},
      {:hidden, Keyword.get(opts, :hidden, false)},
      {:strikethrough, Keyword.get(opts, :strikethrough, false)},
      {:link, Keyword.get(opts, :link, false)}
    ]
    |> Enum.filter(fn {_effect, enabled} -> enabled end)
    |> Enum.map(fn {effect, _} -> effect end)
  end

  defp parse_align("left"), do: :left
  defp parse_align("center"), do: :center
  defp parse_align("right"), do: :right
  defp parse_align("justify"), do: :justify
  defp parse_align(_), do: :left

  defp parse_add_line("none"), do: :none
  defp parse_add_line("before"), do: :before
  defp parse_add_line("after"), do: :after
  defp parse_add_line("both"), do: :both
  defp parse_add_line(_), do: :none

  defp build_effect_info(effect_list) when is_list(effect_list) do
    base_effects = %EffectInfo{}
    Enum.reduce(effect_list, base_effects, &apply_effect/2)
  end

  defp apply_effect(:bold, acc), do: %{acc | bold: true}
  defp apply_effect(:dim, acc), do: %{acc | dim: true}
  defp apply_effect(:italic, acc), do: %{acc | italic: true}
  defp apply_effect(:underline, acc), do: %{acc | underline: true}
  defp apply_effect(:blink, acc), do: %{acc | blink: true}
  defp apply_effect(:reverse, acc), do: %{acc | reverse: true}
  defp apply_effect(:hidden, acc), do: %{acc | hidden: true}
  defp apply_effect(:strikethrough, acc), do: %{acc | strikethrough: true}
  defp apply_effect(:link, acc), do: %{acc | link: true}
  defp apply_effect(_, acc), do: acc

  defp show_help do
    # Banner
    title = %ChunkText{
      text: "⚡ AURORA CLI ⚡",
      color: Color.to_color_info(:primary),
      effects: %EffectInfo{bold: true}
    }

    subtitle = %ChunkText{
      text: "Formatea texto en terminal con colores y efectos ANSI",
      color: Color.to_color_info(:secondary),
      effects: %EffectInfo{italic: true}
    }

    # Secciones
    usage_title = %ChunkText{
      text: "\n📘 USO",
      color: Color.to_color_info(:info),
      effects: %EffectInfo{bold: true, underline: true}
    }

    usage_text = %ChunkText{
      text:
        "  aurora --text=\"tu texto\" --color=#FF0000 --bold\n  aurora --table --headers=\"A,B\" --row=\"1,2\"",
      color: Color.to_color_info(:no_color)
    }

    options_title = %ChunkText{
      text: "\n🎨 OPCIONES",
      color: Color.to_color_info(:success),
      effects: %EffectInfo{bold: true, underline: true}
    }

    text_mode = %ChunkText{
      text:
        "  --text=<texto>       Texto a formatear (repetible)\n" <>
          "  --color=<color>      Color (#HEX o nombre: primary, error, warning, etc.)\n" <>
          "  --align=<tipo>       Alineación (left, center, right, justify)\n" <>
          "  --bold, --italic     Efectos de texto\n" <>
          "  --underline, --dim   Más efectos disponibles\n" <>
          "  --lighten=<n>        Aclara color (1-6 tonos)\n" <>
          "  --darken=<n>         Oscurece color (1-6 tonos)",
      color: Color.to_color_info(:ternary)
    }

    table_mode = %ChunkText{
      text:
        "\n  --table              Activa modo tabla\n" <>
          "  --headers=<csv>      Cabeceras separadas por comas\n" <>
          "  --row=<csv>          Fila de datos (repetible)\n" <>
          "  --header-color       Color de cabeceras\n" <>
          "  --row-color          Color de filas",
      color: Color.to_color_info(:ternary)
    }

    effects_title = %ChunkText{
      text: "\n✨ EFECTOS",
      color: Color.to_color_info(:warning),
      effects: %EffectInfo{bold: true, underline: true}
    }

    effects_list = %ChunkText{
      text:
        "  bold, dim, italic, underline, blink, reverse, strikethrough\n" <>
          "  Usar como: --bold --italic",
      color: Color.to_color_info(:ternary)
    }

    examples_title = %ChunkText{
      text: "\n🚀 EJEMPLOS",
      color: Color.to_color_info(:primary),
      effects: %EffectInfo{bold: true, underline: true}
    }

    example1 = %ChunkText{
      text: "  $ aurora --text=\"¡Hola!\" --color=primary --bold",
      color: Color.to_color_info(:success),
      effects: %EffectInfo{dim: true}
    }

    example2 = %ChunkText{
      text: "\n  $ aurora --text=\"Error: \" --color=error --text=\"Algo falló\" --color=warning",
      color: Color.to_color_info(:success),
      effects: %EffectInfo{dim: true}
    }

    example3 = %ChunkText{
      text: "\n  $ aurora --table --headers=\"Nombre,Edad\" --row=\"Ana,25\" --row=\"Juan,30\"",
      color: Color.to_color_info(:success),
      effects: %EffectInfo{dim: true}
    }

    footer = %ChunkText{
      text: "\n\n✨ Más info: https://github.com/tu-usuario/aurora\n",
      color: Color.to_color_info(:secondary),
      effects: %EffectInfo{italic: true}
    }

    # Formatear todo
    chunks = [
      title,
      subtitle,
      usage_title,
      usage_text,
      options_title,
      text_mode,
      table_mode,
      effects_title,
      effects_list,
      examples_title,
      example1,
      example2,
      example3,
      footer
    ]

    Format.format(%FormatInfo{
      chunks: chunks,
      align: :left,
      add_line: :none
    })
  end

  defp version do
    version_chunks = [
      %ChunkText{
        text: "#{@app_name} v#{@app_version}",
        color: Color.to_color_info(:primary),
        effects: %EffectInfo{bold: true}
      }
    ]

    Format.format(%FormatInfo{chunks: version_chunks, align: :left, add_line: :none}) <> "\n"
  end
end
