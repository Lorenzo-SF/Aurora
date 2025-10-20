# Aurora 🎨

> _"Because life is too short for black and white terminals"_ 🌈

**Colorful terminal formatting and rendering library**

Aurora is a dependency-free library for formatting, ANSI colors, and terminal rendering. It transforms your boring terminal output into a colorful experience that even your cat will want to look at.

## Features

- 🎨 **Rich color support** - HEX, RGB, named colors, gradients
- ✨ **Text effects** - Bold, italic, underline, and more ANSI effects
- 📊 **Table rendering** - Formatted tables with color support
- 📝 **Text alignment** - Left, right, center, justify, and block centering
- 🔧 **Struct-based** - Clean `ChunkText`, `ColorInfo`, `EffectInfo`, `FormatInfo` structures
- 🖥️ **CLI support** - Can be used as a command-line tool
- 🗂️ **No dependencies** - Completely self-contained

## Installation

Add Aurora to your `mix.exs` dependencies:

```elixir
def deps do
  [
    {:aurora, "~> 1.0"}
  ]
end
```

Then run:
```bash
mix deps.get
```

## Quick Start

### Basic Text Formatting

```elixir
# Simple colored text
Aurora.format("Hello World!", color: :primary) |> IO.puts()

# Text with effects
Aurora.format("Error occurred", color: :error, bold: true) |> IO.puts()

# Centered text
Aurora.format("Title", color: :info, align: :center) |> IO.puts()

# Multiple lines with same format
Aurora.format(["Line 1", "Line 2", "Line 3"], color: :success) |> IO.puts()
```

### Advanced Formatting

```elixir
# Create individual text chunks
chunks = [
  Aurora.chunk("Error: ", :error),
  Aurora.chunk("File not found", :warning),
  Aurora.chunk(" in ", :no_color),
  Aurora.chunk("/path/to/file", :info)
]

# Format multiple chunks together
Aurora.format_chunks(chunks) |> IO.puts()

# Custom hex color
Aurora.format("Custom color", color: "#FF6B35") |> IO.puts()

# Apply multiple effects
Aurora.stylize("Bold and underlined", [:bold, :underline]) |> IO.puts()
```

### Working with Tables

```elixir
# Create a table with headers
headers = [
  Aurora.chunk("Name", :primary),
  Aurora.chunk("Age", :primary),
  Aurora.chunk("Role", :primary)
]

rows = [
  [
    Aurora.chunk("John", :secondary),
    Aurora.chunk("25", :secondary),
    Aurora.chunk("Developer", :secondary)
  ],
  [
    Aurora.chunk("Jane", :secondary),
    Aurora.chunk("30", :secondary),
    Aurora.chunk("Designer", :secondary)
  ]
]

# Format as table
table_chunks = [headers | rows]
Aurora.format_chunks(table_chunks, mode: :table) |> IO.puts()
```

### Using Structs Directly

```elixir
# Using FormatInfo struct for advanced formatting
format_info = %Aurora.Structs.FormatInfo{
  chunks: [
    %Aurora.Structs.ChunkText{
      text: "Important title",
      color: Aurora.Color.to_color_info(:primary),
      effects: %Aurora.Structs.EffectInfo{bold: true, underline: true}
    }
  ],
  align: :center,
  add_line: :both
}

result = Aurora.Format.format(format_info)
```

### Colors and Effects

#### Available Colors
- Basic: `:primary`, `:secondary`, `:ternary`, `:quaternary`
- Status: `:success`, `:warning`, `:error`, `:info`, `:debug`
- Special: `:critical`, `:alert`, `:emergency`, `:happy`, `:notice`, `:menu`

#### Available Effects
- `:bold`, `:italic`, `:underline`, `:dim`
- `:blink`, `:reverse`, `:hidden`, `:strikethrough`

## API Overview

### Main Functions

- `Aurora.format/2` - Format text with color, alignment, and effects
- `Aurora.colorize/2` - Apply only color to text
- `Aurora.stylize/2` - Apply effects to text
- `Aurora.json/2` - Format JSON data with colors
- `Aurora.chunk/2` - Create a single text chunk
- `Aurora.chunks/1` - Create multiple chunks from a list
- `Aurora.format_chunks/2` - Format a list of chunks

### Key Modules

- `Aurora.Format` - Main formatting functions
- `Aurora.Color` - Color management and conversion
- `Aurora.Effects` - ANSI text effects
- `Aurora.Convert` - Data conversion utilities
- `Aurora.Ensure` - Type safety with defaults
- `Aurora.CLI` - Command-line interface

### Core Structs

- `ChunkText` - A text fragment with formatting
- `ColorInfo` - Color information in multiple formats
- `EffectInfo` - Text effects configuration
- `FormatInfo` - Complete formatting configuration

## Configuration (Optional)

Customize colors by creating `config/config.exs` in your project:

```elixir
# config/config.exs
import Config

config :aurora, :colors,
  colors: %{
    primary: %{hex: "#0066CC"},     # Your primary color
    error: %{hex: "#DC3545"},       # Your error color
    success: %{hex: "#28A745"},     # Your success color
    # ... more custom colors
  },
  gradients: %{
    fire: [%{hex: "#FF0000"}, %{hex: "#FFA500"}, %{hex: "#FFFF00"}],
    # ... more gradients
  }
```

## CLI Usage

Aurora can be used as a command-line tool:

### Build CLI
```bash
mix escript.build
```

### Text Mode Examples
```bash
# Simple colored text
./aurora --text="Hello World!" --color=primary --bold

# Multiple fragments with different colors
./aurora --text="Error: " --color=error --text="File not found" --color=warning

# With custom hex color
./aurora --text="Custom" --color=#FF6B35 --italic
```

### Table Mode Examples
```bash
# Basic table
./aurora --table --headers="Name,Age" --row="John,25" --row="Ana,30"

# Table with custom colors
./aurora --table --headers="ID,Status" --row="1,Active" --row="2,Inactive" --header-color=primary --row-color=success
```

## Utilities

### Text Processing
```elixir
# Clean ANSI codes from formatted text
clean_text = Aurora.clean("\e[31mRed text\e[0m")  # "Red text"

# Get visible length (excluding ANSI codes)
length = Aurora.text_length("\e[31mHello\e[0m")  # 5

# List available colors and effects
colors = Aurora.colors()
effects = Aurora.effects()
```

## Development

### Quality Checks
```bash
# Complete quality pipeline
mix quality

# Quick CI/CD pipeline (without dialyzer)
mix ci
```

### Testing
```bash
# Run all tests
mix test

# Run only doctests
mix test --only doctest

# Run with coverage
mix test --cover
```

## License

Apache 2.0 - See the [LICENSE](LICENSE) file for details.