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

  # Format command
  defp format_command(_opts, args) do
    text = Enum.at(args, 1)
    opts = elem(parse_args(args), 0)

    if text do
      formatted = 
        Aurora.format(text, 
          color: opts[:color] && String.to_atom(opts[:color]),
          align: opts[:align] && String.to_atom(opts[:align]),
          bold: opts[:bold] || false
        )
      IO.puts(formatted)
    else
      IO.puts("Error: Missing text argument for format command")
      show_help()
    end
  end

  # Colorize command
  defp colorize_command(_opts, args) do
    text = Enum.at(args, 1)
    opts = elem(parse_args(args), 0)

    if text && opts[:color] do
      formatted = Aurora.colorize(text, String.to_atom(opts[:color]))
      IO.puts(formatted)
    else
      IO.puts("Error: Missing text or color argument for colorize command")
      show_help()
    end
  end

  # Stylize command
  defp stylize_command(_opts, args) do
    text = Enum.at(args, 1)
    opts = elem(parse_args(args), 0)

    if text && opts[:effects] do
      effects = 
        opts[:effects]
        |> String.split(",")
        |> Enum.map(&String.trim/1)
        |> Enum.map(&String.to_atom/1)
      
      formatted = Aurora.stylize(text, effects)
      IO.puts(formatted)
    else
      IO.puts("Error: Missing text or effects argument for stylize command")
      show_help()
    end
  end

  # JSON command
  defp json_command(_opts, args) do
    input = Enum.at(args, 1)
    opts = elem(parse_args(args), 0)

    if input do
      try do
        data = case File.read(input) do
          {:ok, file_content} -> Jason.decode!(file_content)
          {:error, _} -> 
            # If not a file, treat as JSON string
            case Jason.decode(input) do
              {:ok, parsed} -> parsed
              {:error, _} -> input
            end
        end

        formatted = 
          Aurora.json(data,
            color: opts[:color] && String.to_atom(opts[:color]),
            compact: opts[:compact] || false,
            indent: opts[:indent] || false
          )
        IO.puts(formatted)
      rescue
        e ->
          IO.puts("Error processing JSON: #{inspect(e)}")
          show_help()
      end
    else
      IO.puts("Error: Missing JSON input for json command")
      show_help()
    end
  end

  # Clean command
  defp clean_command(_opts, args) do
    text = Enum.at(args, 1)

    if text do
      cleaned = Aurora.clean(text)
      IO.puts(cleaned)
    else
      IO.puts("Error: Missing text argument for clean command")
      show_help()
    end
  end

  # Colors command
  defp colors_command() do
    colors = Aurora.colors()
    IO.puts("Available colors:")
    Enum.each(colors, fn color -> 
      IO.puts("- #{color}")
    end)
  end

  # Effects command
  defp effects_command() do
    effects = Aurora.effects()
    IO.puts("Available effects:")
    Enum.each(effects, fn effect -> 
      IO.puts("- #{effect}")
    end)
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