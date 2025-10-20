defmodule Aurora.Structs.EffectInfo do
  @moduledoc """
  Structure representing text effects information for terminal.

  `EffectInfo` encapsulates all text effects that can be applied,
  including bold, italic, underline, and other ANSI effects.

  ## Fields

  - `bold` - Bold text
  - `dim` - Dim/faint text
  - `italic` - Italic text
  - `underline` - Underlined text
  - `blink` - Blinking text
  - `reverse` - Inverted colors
  - `hidden` - Hidden text
  - `strikethrough` - Strikethrough text
  - `link` - Link text (underline)

  ## Examples

      # Basic effects
      effects = %Aurora.Structs.EffectInfo{bold: true, italic: true}

      # All effects activated
      all_effects = %Aurora.Structs.EffectInfo{
        bold: true,
        italic: true,
        underline: true,
        blink: true,
        reverse: true,
        strikethrough: true
      }

      # Combining effects
      emphasized = %Aurora.Structs.EffectInfo{
        bold: true,
        underline: true
      }

      # Using with ChunkText
      chunk = %Aurora.Structs.ChunkText{
        text: "Important text",
        effects: %Aurora.Structs.EffectInfo{bold: true, underline: true}
      }

      # Applying effects to text
      effects = %Aurora.Structs.EffectInfo{bold: true, italic: true}
      result = Aurora.Effects.apply_effect_info("Formatted text", effects)

  ## Features

  - All fields are optional and default to `false`
  - Any number of effects can be combined
  - Effects are applied using ANSI escape codes
  - Some effects may not be supported in all terminals
  - Can be used with Aurora's formatting system
  - Works with both normal and table rendering modes
  - Compatible with color information in ChunkText structs
  """

  defstruct bold: false,
            dim: false,
            italic: false,
            underline: false,
            blink: false,
            reverse: false,
            hidden: false,
            strikethrough: false,
            link: false

  @type t :: %__MODULE__{
          bold: boolean(),
          dim: boolean(),
          italic: boolean(),
          underline: boolean(),
          blink: boolean(),
          reverse: boolean(),
          hidden: boolean(),
          strikethrough: boolean(),
          link: boolean()
        }
end
