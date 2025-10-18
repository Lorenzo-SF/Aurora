defmodule Aurora.CLI do
  @moduledoc """
  Command-line interface for Aurora formatting library.

  Provides functionality to format text with colors, effects, and other formatting
  options directly from the command line.
  """

  @doc """
  Main entry point for Aurora CLI commands.
  """
  alias Aurora.{Color, Format}

  @app_name "Aurora"
  @app_version "1.0.5"

  def main(argv) do
    argv
    |> parse_args()
    |> process_args()
  end

  defp parse_args(argv) do
    case OptionParser.parse(argv,
           strict: [
             align: :string,
             color: :string,
             bold: :boolean,
             effects: :string,
             compact: :boolean,
             indent: :boolean,
             version: :boolean
           ],
           aliases: [
             a: :align,
             b: :bold,
             c: :color,
             e: :effects,
             v: :version
           ]
         ) do
      {opts, args, _errors} ->
        {opts, args}
    end
  end

  defp process_args({opts, args}) do
    command = List.first(args)
    execute_command(command, opts, args)
  end

  defp execute_command("format", opts, args), do: format_command(opts, args)
  defp execute_command("colorize", opts, args), do: colorize_command(opts, args)
  defp execute_command("stylize", opts, args), do: stylize_command(opts, args)
  defp execute_command("json", opts, args), do: json_command(opts, args)
  defp execute_command("clean", opts, args), do: clean_command(opts, args)
  defp execute_command("colors", _opts, _args), do: colors_command()
  defp execute_command("effects", _opts, _args), do: effects_command()
  defp execute_command("version", _opts, _args), do: version()
  defp execute_command(nil, _opts, _args), do: show_help()
  defp execute_command(_, _opts, _args), do: show_help()

  # Command functions that handle CLI commands
  defp format_command(opts, args) do
    text = Enum.at(args, 1) || ""
    result = format(text, opts)
    IO.puts(result)
  end

  defp colorize_command(opts, args) do
    text = Enum.at(args, 1) || ""
    color = Keyword.get(opts, :color, :primary)
    result = colorize(text, color)
    IO.puts(result)
  end

  defp stylize_command(opts, args) do
    text = Enum.at(args, 1) || ""
    effects = Keyword.get(opts, :effects, "")

    effect_list =
      if effects != "" do
        effects
        |> String.split(",")
        |> Enum.map(&String.to_atom/1)
      else
        []
      end

    result = stylize(text, effect_list)
    IO.puts(result)
  end

  defp json_command(opts, args) do
    # Get JSON data from args or read from a file
    json_input = Enum.at(args, 1) || ""
    result = json(json_input, opts)
    IO.puts(result)
  end

  defp clean_command(_opts, args) do
    text = Enum.at(args, 1) || ""
    result = clean(text)
    IO.puts(result)
  end

  defp colors_command do
    available_colors = colors()
    result = Enum.join(available_colors, "\n")
    IO.puts(result)
  end

  defp effects_command do
    available_effects = effects()
    result = Enum.join(available_effects, "\n")
    IO.puts(result)
  end

  # Public API functions - these are the functions that the CLI commands expect to call
  # We implement them directly in the CLI module to avoid needing a main Aurora module

  # Format function - equivalent to Aurora.format/2
  def format(text, opts \\ []) when is_binary(text) do
    color = Keyword.get(opts, :color)
    align = Keyword.get(opts, :align, :left)
    bold = Keyword.get(opts, :bold, false)

    text
    |> apply_color_to_text(color)
    |> apply_bold_to_text(bold)
    |> apply_alignment_to_text(align)
  end

  defp apply_color_to_text(text, nil), do: text

  defp apply_color_to_text(text, color) do
    color_info = Color.get_color_info(color)
    Color.apply_color(text, color_info)
  end

  defp apply_bold_to_text(text, false), do: text
  defp apply_bold_to_text(text, true), do: "\e[1m#{text}\e[22m"

  defp apply_alignment_to_text(text, :left), do: text

  defp apply_alignment_to_text(text, :center) do
    width = get_terminal_width()
    padding = div(width - String.length(text), 2)
    String.duplicate(" ", max(padding, 0)) <> text
  end

  defp apply_alignment_to_text(text, :right) do
    width = get_terminal_width()
    padding = width - String.length(text)
    String.duplicate(" ", max(padding, 0)) <> text
  end

  defp apply_alignment_to_text(text, _), do: text

  defp get_terminal_width do
    case :io.columns() do
      {:ok, cols} -> cols
      _ -> 80
    end
  end

  # Colorize function - equivalent to Aurora.colorize/2
  def colorize(text, color) when is_binary(text) and is_atom(color) do
    color_info = Color.get_color_info(color)
    Color.apply_color(text, color_info)
  end

  def colorize(text, color) when is_binary(text) and is_binary(color) do
    color_info = Color.get_color_info(String.to_atom(color))
    Color.apply_color(text, color_info)
  end

  # Stylize function - equivalent to Aurora.stylize/2
  def stylize(text, effects) when is_binary(text) and is_list(effects) do
    Enum.reduce(effects, text, &apply_single_effect/2)
  end

  defp apply_single_effect(:bold, text), do: "\e[1m#{text}\e[22m"
  defp apply_single_effect(:dim, text), do: "\e[2m#{text}\e[22m"
  defp apply_single_effect(:italic, text), do: "\e[3m#{text}\e[23m"
  defp apply_single_effect(:underline, text), do: "\e[4m#{text}\e[24m"
  defp apply_single_effect(:blink, text), do: "\e[5m#{text}\e[25m"
  defp apply_single_effect(:reverse, text), do: "\e[7m#{text}\e[27m"
  defp apply_single_effect(:strikethrough, text), do: "\e[9m#{text}\e[29m"
  defp apply_single_effect(:hidden, text), do: "\e[8m#{text}\e[28m"
  defp apply_single_effect(_, text), do: text

  # JSON function - equivalent to Aurora.json/2
  def json(data, opts \\ []) do
    color = Keyword.get(opts, :color, :info)
    compact = Keyword.get(opts, :compact, false)
    indent = Keyword.get(opts, :indent, false)

    data
    |> convert_to_json_string(compact)
    |> apply_json_color(color)
    |> apply_json_indentation(indent)
  end

  defp convert_to_json_string(binary, _compact) when is_binary(binary), do: binary
  defp convert_to_json_string(data, compact), do: Jason.encode!(data, pretty: not compact)

  defp apply_json_color(json_string, color) do
    color_info = Color.get_color_info(color)
    Color.apply_color(json_string, color_info)
  end

  defp apply_json_indentation(colored_json, false), do: colored_json

  defp apply_json_indentation(colored_json, true) do
    colored_json
    |> String.split("\n")
    |> Enum.map_join("\n", &indent_json_line/1)
  end

  defp indent_json_line(""), do: ""
  defp indent_json_line(line), do: "  #{line}"

  # Clean function - equivalent to Aurora.clean/1
  def clean(text) when is_binary(text) do
    Format.clean_ansi(text)
  end

  # Colors function - equivalent to Aurora.colors/0
  def colors do
    Color.get_all_colors()
    |> Enum.map(&elem(&1, 0))
  end

  # Effects function - equivalent to Aurora.effects/0
  def effects do
    [
      :bold,
      :dim,
      :italic,
      :underline,
      :blink,
      :reverse,
      :strikethrough,
      :hidden
    ]
  end

  defp show_help do
    help_text = """
    Aurora CLI - Terminal text formatting tool

    Usage:
      aurora [COMMAND] [OPTIONS] [ARGUMENTS]

    Commands:
      format    Format text with colors and alignment
                Usage: aurora format "text" --color primary --align center --bold

      colorize  Apply color to text
                Usage: aurora colorize "text" --color error

      stylize   Apply effects to text
                Usage: aurora stylize "text" --effects bold,underline

      json      Format JSON with colors
                Usage: aurora json "file.json" --color info

      clean     Remove ANSI codes from text
                Usage: aurora clean "text_with_ansi_codes"

      colors    List available colors
                Usage: aurora colors

      effects   List available effects
                Usage: aurora effects

    Options:
      -c, --color COLOR     Color name (primary, error, success, etc.)
      -a, --align ALIGN     Alignment (left, right, center, justify, center_block)
      -b, --bold            Make text bold
          --effects EFFECTS Comma-separated list of effects (bold,italic,underline,dim,blink,reverse,strikethrough)
          --compact         Compact JSON format
          --indent          Add extra indentation to JSON
    """

    IO.puts(help_text)
  end

  def version do
    IO.puts("#{@app_name} v#{@app_version}")
  end
end
