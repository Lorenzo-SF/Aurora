defmodule Aurora.Structs.ChunkText do
  @moduledoc """
  Structure representing a text chunk with formatting and positioning.

  A `ChunkText` is the basic unit of formatted text in Aurora. Each chunk
  contains text, optional color information, ANSI effects, and position
  coordinates for advanced rendering.

  ## Fields

  - `text` - The text content (required)
  - `color` - Color information (optional, %ColorInfo{})
  - `effects` - ANSI effects like bold, italic, etc. (optional, %EffectInfo{})
  - `pos_x` - Horizontal position for rendering (integer, default: 0)
  - `pos_y` - Vertical position for rendering (integer, default: 0)

  ## Examples

      # Basic usage
      chunk = %Aurora.Structs.ChunkText{text: "Hello world"}
      chunk.text  # "Hello world"

      # Chunk with color and effects
      color = %Aurora.Structs.ColorInfo{name: :primary}
      effects = %Aurora.Structs.EffectInfo{bold: true, underline: true}
      chunk_formatted = %Aurora.Structs.ChunkText{
        text: "Formatted text",
        color: color,
        effects: effects,
        pos_x: 10,
        pos_y: 5
      }

      # Creating chunks with different approaches
      chunk1 = %Aurora.Structs.ChunkText{text: "Simple text"}
      chunk2 = %Aurora.Structs.ChunkText{text: "With color", color: :primary}
      chunk3 = %Aurora.Structs.ChunkText{text: "With position", pos_x: 20, pos_y: 10}
      chunk4 = %Aurora.Structs.ChunkText{
        text: "Fully formatted",
        color: :success,
        effects: %Aurora.Structs.EffectInfo{bold: true, italic: true},
        pos_x: 5,
        pos_y: 5
      }

  ## Features

  - The `text` field is required
  - Color is optional and uses the ColorInfo structure
  - Effects are optional and use the EffectInfo structure
  - Positions allow for precise terminal rendering
  - Supports multiple simultaneous ANSI effects
  - Can be used in both table and raw rendering modes
  - Works with automatic indentation based on color type
  """

  @enforce_keys [:text]
  defstruct text: "",
            color: nil,
            effects: nil,
            pos_x: 0,
            pos_y: 0

  @type t :: %__MODULE__{
          text: String.t(),
          color: Aurora.Structs.ColorInfo.t() | nil,
          effects: Aurora.Structs.EffectInfo.t() | nil,
          pos_x: integer(),
          pos_y: integer()
        }
end

# Implement String.Chars protocol to convert ChunkText to string
defimpl String.Chars, for: Aurora.Structs.ChunkText do
  @doc """
  Converts a ChunkText struct to its text representation.

  This implementation extracts the text field from the ChunkText struct,
  allowing it to be used in contexts that expect strings.

  ## Examples

      chunk = %Aurora.Structs.ChunkText{text: "Hello world"}
      to_string(chunk)  # "Hello world"

      chunk_with_color = %Aurora.Structs.ChunkText{
        text: "Colored text",
        color: :primary
      }
      to_string(chunk_with_color)  # "Colored text"
  """
  def to_string(%Aurora.Structs.ChunkText{text: text}), do: text
end
