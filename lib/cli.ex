defmodule Aurora.CLI do
  @moduledoc """
  Command-line interface for formatting text with colors and ANSI effects in the terminal.

  Aurora can be used as a command-line tool to generate formatted text with ANSI codes.
  It returns the literal string with escape codes without interpretation, perfect for
  capturing in bash variables or external processing.

  ## Installation

  Build the executable:

      mix escript.build

  This creates the `aurora` file that you can execute directly.

  ## Basic Usage

  ### Text Mode

  Format one or multiple text fragments:

      ./aurora --text="Hello!" --color=primary --bold
      ./aurora --text="Error: " --color=error --text="File not found" --color=warning

  ### Table Mode

  Create formatted tables:

      ./aurora --table --headers="Name,Age" --row="John,25" --row="Ana,30"

  ## Main Options

  **Text:**
  - `--text=<text>` - Text to format (repeatable for multiple fragments)
  - `--color=<color>` - Hex color (#FF0000) or name (primary, error, etc.)
  - `--align=<type>` - Alignment: left, center, right, justify
  - `--add_line=<position>` - Add line breaks: none, before, after, both

  **Effects:**
  - `--bold`, `--dim`, `--italic`, `--underline`
  - `--blink`, `--reverse`, `--hidden`, `--strikethrough`, `--link`

  **Color Manipulation:**
  - `--lighten=N` - Lighten color N tones (1-6)
  - `--darken=N` - Darken color N tones (1-6)
  - `--inverted` - Invert color (swap background/text)

  **Table:**
  - `--table` - Enable table mode
  - `--headers=<csv>` - Headers separated by commas
  - `--row=<csv>` - Data row (repeatable)
  - `--header_color=<color>` - Header color
  - `--row_color=<color>` - Row color
  - `--cell_color=<color>` - Cell color (repeatable)
  - `--header_effects=<csv>` - Header effects (comma separated)
  - `--row_effects=<csv>` - Row effects (comma separated)
  - `--cell_effects=<csv>` - Cell effects (repeatable)

  ## Output

  The CLI returns the string with ANSI codes without interpretation:

      result=$(./aurora --text="Success" --color=success --bold)
      echo "$result"  # Shows the formatted text

  ## Examples

      # Basic text formatting
      ./aurora --text="Hello World" --color=primary --bold

      # Multiple text fragments with different colors
      ./aurora --text="Error: " --color=error --text="File not found" --color=warning

      # Table formatting
      ./aurora --table --headers="Name,Age,Role" --row="John,25,Developer" --row="Ana,30,Designer"

      # Color manipulation
      ./aurora --text="Warning" --color=warning --lighten=2 --italic

      # Custom hex color
      ./aurora --text="Custom" --color=#FF6B35 --bold

      # Get version
      ./aurora --version

      # Show help
      ./aurora --help
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
      text: ~S"""
      🌈 AURORA CLI
      """,
      color: Color.to_color_info(:primary),
      effects: %EffectInfo{bold: true}
    }

    subtitle = %ChunkText{
      text: ~S"""
      Format terminal text with colors and ANSI effects
      """,
      color: Color.to_color_info(:secondary),
      effects: %EffectInfo{italic: true}
    }

    # Description
    description = %ChunkText{
      text: ~S"""
      Transform your boring terminal into a colorful experience
      """,
      color: Color.to_color_info(:info),
      effects: %EffectInfo{dim: true}
    }

    # Usage section
    usage_title = %ChunkText{
      text: ~S"""
      📘 USAGE
      """,
      color: Color.to_color_info(:info),
      effects: %EffectInfo{bold: true, underline: true}
    }

    usage_text = %ChunkText{
      text: ~S"""
      # Basic text formatting
      aurora --text="Hello world" --color=primary --bold
      # Multiple text fragments
      aurora --text="Error: " --color=error --text="File not found" --color=warning
      # Table formatting
      aurora --table --headers="Name,Age" --row="John,25" --row="Jane,30"
      """,
      color: Color.to_color_info(:no_color)
    }

    # Options section
    options_title = %ChunkText{
      text: ~S"""
      ⚙️  OPTIONS
      """,
      color: Color.to_color_info(:success),
      effects: %EffectInfo{bold: true, underline: true}
    }

    # Text mode options
    text_options = %ChunkText{
      text: ~S"""
      TEXT OPTIONS:
        --text=<text>        Text to format (repeatable)
        --color=<color>      Color name (:primary, :error) or hex (#FF0000)
        --align=<align>      left, right, center, justify
        --add-line=<pos>     Add newlines: before, after, both, none
      EFFECTS: --bold, --dim, --italic, --underline, --blink, --reverse, --strikethrough
      """,
      color: Color.to_color_info(:ternary)
    }

    # Color manipulation options
    color_manip_options = %ChunkText{
      text: ~S"""
      COLOR MANIPULATION:
        --lighten=<n>        Lighten color by N tones (1-6)
        --darken=<n>         Darken color by N tones (1-6)
        --inverted           Invert foreground/background colors
      """,
      color: Color.to_color_info(:ternary)
    }

    # Table options
    table_options = %ChunkText{
      text: ~s"""
      TABLE OPTIONS:
        --table              Enable table mode
        --headers=<csv>      Header row (comma-separated)
        --row=<csv>          Data row (comma-separated, repeatable)
        --header-color       Color for headers
        --row-color          Default color for data rows
        --header-effects     Effects for headers (comma-separated)
        --row-effects        Effects for data rows (comma-separated)
        --cell-color         Color for individual cells (repeatable)
        --cell-effects       Effects for individual cells (repeatable)
      """,
      color: Color.to_color_info(:menu)
    }

    # Quick examples
    examples_title = %ChunkText{
      text: ~S"""
      ✨ QUICK EXAMPLES
      """,
      color: Color.to_color_info(:primary),
      effects: %EffectInfo{bold: true, underline: true}
    }

    examples = %ChunkText{
      text: ~S"""
      # Simple colored text
      $ aurora --text="Success!" --color=success --bold
      # Multiple fragments with different colors
      $ aurora --text="Error: " --color=error --text="File missing" --color=warning
      # Custom hex color with effects
      $ aurora --text="Custom" --color=#FF6B35 --italic --underline
      # Lighten a color
      $ aurora --text="Warning" --color=warning --lighten=2 --bold
      # Formatted table
      $ aurora --table --headers="Name,Age,Role" --row="John,25,Dev" --row="Jane,30,Lead"
      # Get version
      $ aurora --version
      # Show this help
      $ aurora --help
      """,
      color: Color.to_color_info(:success),
      effects: %EffectInfo{dim: true}
    }

    # Available colors
    colors_title = %ChunkText{
      text: ~S"""
      🎨 AVAILABLE COLORS
      """,
      color: Color.to_color_info(:warning),
      effects: %EffectInfo{bold: true, underline: true}
    }

    colors = %ChunkText{
      text: ~S"""
      Basic: primary, secondary, ternary, quaternary
      Status: success, warning, error, info, debug
      Special: critical, alert, emergency, happy, notice, menu, no_color
      """,
      color: Color.to_color_info(:secondary)
    }

    # Footer
    footer = %ChunkText{
      text: ~S"""
      💡 Pro tip: Use $(aurora --text="your text" --color=primary) to capture output in variables
      📖 More info: https://github.com/lorenzo-sf/aurora
      """,
      color: Color.to_color_info(:info),
      effects: %EffectInfo{italic: true}
    }

    # Formatear todo
    chunks = [
      title,
      subtitle,
      description,
      usage_title,
      usage_text,
      options_title,
      text_options,
      color_manip_options,
      table_options,
      examples_title,
      examples,
      colors_title,
      colors,
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
