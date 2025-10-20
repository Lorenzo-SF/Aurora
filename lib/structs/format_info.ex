defmodule Aurora.Structs.FormatInfo do
  @moduledoc """
  Global configuration structure for compound text formatting.

  `FormatInfo` contains all the information needed to format a set of text chunks
  with alignment options, effects, indentation, and additional configurations.

  ## Fields

  ### Content
  - `chunks` - List of ChunkText to format (required)
  - `default_color` - Default color for chunks without color

  ### Alignment and Indentation
  - `align` - Alignment type (:left, :right, :center, :justify, :center_block)
  - `manual_tabs` - Number of manual tabs (-1 for automatic based on color)

  ### Additional Settings
  - `add_line` - Add line breaks (:before, :after, :both, :none)
  - `animation` - Animation prefix string
  - `mode` - Rendering mode (:normal, :table, :raw)

  ## Alignment Types

  - `:left` - Left alignment (default)
  - `:right` - Right alignment
  - `:center` - Center alignment
  - `:justify` - Justified alignment
  - `:center_block` - Center block alignment (for tables)

  ## Rendering Modes

  - `:normal` - Standard rendering with full formatting
  - `:table` - Optimized for table rendering
  - `:raw` - Minimal rendering with precise coordinate positioning

  ## Examples

      # Basic usage
      chunk = %Aurora.Structs.ChunkText{text: "Hello"}
      format_info = %Aurora.Structs.FormatInfo{
        chunks: [chunk],
        align: :center,
        add_line: :both
      }
      result = Aurora.Format.format(format_info)

      # Table mode
      chunks = [
        [%Aurora.Structs.ChunkText{text: "Name", color: :primary}, %Aurora.Structs.ChunkText{text: "Age", color: :primary}],
        [%Aurora.Structs.ChunkText{text: "John", color: :secondary}, %Aurora.Structs.ChunkText{text: "25", color: :secondary}]
      ]
      format_info = %Aurora.Structs.FormatInfo{
        chunks: chunks,
        mode: :table,
        align: :center_block
      }
      result = Aurora.Format.format(format_info)

      # With automatic indentation based on color
      chunks = [
        %Aurora.Structs.ChunkText{text: "Primary", color: :primary},
        %Aurora.Structs.ChunkText{text: "Secondary", color: :secondary}
      ]
      format_info = %Aurora.Structs.FormatInfo{
        chunks: chunks,
        manual_tabs: -1  # Auto-indent based on color
      }
      result = Aurora.Format.format(format_info)

      # Raw mode with precise positioning
      chunk = %Aurora.Structs.ChunkText{
        text: "Positioned text",
        pos_x: 10,
        pos_y: 5
      }
      format_info = %Aurora.Structs.FormatInfo{
        chunks: [chunk],
        mode: :raw
      }
      result = Aurora.Format.format(format_info)  # Returns: "\\e[5;10HPositioned text"

  ## Features

  - The `chunks` field is required
  - Indentation can be manual or automatic based on color
  - Supports multiple rendering modes for different contexts
  - Allows animations and custom prefixes
  - Flexible line break configuration
  - Compatible with all Aurora formatting functions
  - Works with both simple and complex text structures
  """

  @enforce_keys [:chunks]
  defstruct chunks: [],
            default_color: nil,
            align: :left,
            manual_tabs: -1,
            add_line: :none,
            animation: "",
            mode: :normal

  @type t :: %__MODULE__{
          chunks: [Aurora.Structs.ChunkText.t()],
          default_color: Aurora.Structs.ColorInfo.t() | nil,
          align: :left | :right | :center | :center_block | :justify,
          manual_tabs: non_neg_integer(),
          add_line: :before | :after | :both | :none,
          animation: String.t(),
          mode: :table | :raw | :normal
        }
end
