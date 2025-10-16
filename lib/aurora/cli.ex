defmodule Aurora.CLI do
  @moduledoc """
  Command-line interface for Aurora formatting library.
  
  Provides functionality to format text with colors, effects, and other formatting
  options directly from the command line.
  """

  @doc """
  Main entry point for Aurora CLI commands.
  """
  def main(argv) do
    argv
    |> parse_args()
    |> process_args()
  end

  defp parse_args(argv) do
    case OptionParser.parse(argv, 
      strict: [
        color: :string,
        align: :string,
        bold: :boolean,
        effects: :string,
        compact: :boolean,
        indent: :boolean
      ],
      aliases: [
        c: :color,
        a: :align,
        b: :bold
      ]
    ) do
      {opts, args, _errors} ->
        {opts, args}
    end
  end

  defp process_args({opts, args}) do
    command = List.first(args)

    case command do
      "format" ->
        format_command(opts, args)

      "colorize" ->
        colorize_command(opts, args)

      "stylize" ->
        stylize_command(opts, args)

      "json" ->
        json_command(opts, args)

      "clean" ->
        clean_command(opts, args)

      "colors" ->
        colors_command()

      "effects" ->
        effects_command()

      nil ->
        show_help()

      _ ->
        show_help()
    end
  end

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

  defp colors_command() do
    available_colors = colors()
    result = Enum.join(available_colors, "\n")
    IO.puts(result)
  end

  defp effects_command() do
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
    
    # Get color info if color is specified
    color_info = 
      if color do
        Aurora.Color.get_color_info(color)
      else
        nil
      end
    
    # Apply color if specified
    colored_text = 
      if color_info do
        Aurora.Color.apply_color(text, color_info)
      else
        text
      end
    
    # Apply bold effect if needed
    bold_text = 
      if bold do
        "\e[1m#{colored_text}\e[22m"
      else
        colored_text
      end
    
    # Apply alignment
    aligned_text = 
      case align do
        :center -> 
          width = case :io.columns() do
            {:ok, cols} -> cols
            _ -> 80
          end
          padding = div(width - String.length(bold_text), 2)
          String.duplicate(" ", max(padding, 0)) <> bold_text
        :right -> 
          width = case :io.columns() do
            {:ok, cols} -> cols
            _ -> 80
          end
          padding = width - String.length(bold_text)
          String.duplicate(" ", max(padding, 0)) <> bold_text
        :justify ->
          # Simple justify implementation
          bold_text
        :center_block ->
          # Simple center_block implementation
          bold_text
        _ -> 
          bold_text
      end
    
    aligned_text
  end

  # Colorize function - equivalent to Aurora.colorize/2
  def colorize(text, color) when is_binary(text) and is_atom(color) do
    color_info = Aurora.Color.get_color_info(color)
    Aurora.Color.apply_color(text, color_info)
  end

  def colorize(text, color) when is_binary(text) and is_binary(color) do
    color_info = Aurora.Color.get_color_info(String.to_atom(color))
    Aurora.Color.apply_color(text, color_info)
  end

  # Stylize function - equivalent to Aurora.stylize/2
  def stylize(text, effects) when is_binary(text) and is_list(effects) do
    # Apply each effect sequentially
    Enum.reduce(effects, text, fn effect, acc ->
      case effect do
        :bold -> "\e[1m#{acc}\e[22m"
        :dim -> "\e[2m#{acc}\e[22m"
        :italic -> "\e[3m#{acc}\e[23m"
        :underline -> "\e[4m#{acc}\e[24m"
        :blink -> "\e[5m#{acc}\e[25m"
        :reverse -> "\e[7m#{acc}\e[27m"
        :strikethrough -> "\e[9m#{acc}\e[29m"
        :hidden -> "\e[8m#{acc}\e[28m"
        _ -> acc
      end
    end)
  end

  # JSON function - equivalent to Aurora.json/2
  def json(data, opts \\ []) do
    color = Keyword.get(opts, :color, :info)
    compact = Keyword.get(opts, :compact, false)
    indent = Keyword.get(opts, :indent, false)
    
    # Convert data to JSON string
    json_string = 
      case data do
        binary when is_binary(binary) -> binary
        _ -> Jason.encode!(data, pretty: not compact)
      end
    
    # Apply color
    color_info = Aurora.Color.get_color_info(color)
    colored_json = Aurora.Color.apply_color(json_string, color_info)
    
    # Apply indentation if requested
    if indent do
      colored_json
      |> String.split("\n")
      |> Enum.map(fn line -> if String.length(line) > 0, do: "  #{line}", else: line end)
      |> Enum.join("\n")
    else
      colored_json
    end
  end

  # Clean function - equivalent to Aurora.clean/1
  def clean(text) when is_binary(text) do
    Aurora.Format.clean_ansi(text)
  end

  # Colors function - equivalent to Aurora.colors/0
  def colors() do
    Aurora.Color.get_all_colors()
    |> Enum.map(&elem(&1, 0))
  end

  # Effects function - equivalent to Aurora.effects/0
  def effects() do
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

  defp show_help() do
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
end