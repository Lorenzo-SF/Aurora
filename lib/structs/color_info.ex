defmodule Aurora.Structs.ColorInfo do
  @moduledoc """
  Represents color information in multiple formats.

  The ColorInfo struct provides a unified way to represent colors in multiple
  formats simultaneously. It contains the same color data in various color
  space representations (HEX, RGB, ARGB, HSV, HSL, CMYK), allowing for easy
  conversion and manipulation.

  ## Fields

  - `hex` - Hexadecimal representation (e.g., "#FF0000")
  - `rgb` - RGB tuple {red, green, blue} (e.g., {255, 0, 0})
  - `argb` - ARGB tuple {alpha, red, green, blue} (e.g., {255, 255, 0, 0})
  - `hsv` - HSV tuple {hue, saturation, value} (e.g., {0.0, 1.0, 1.0})
  - `hsl` - HSL tuple {hue, saturation, lightness} (e.g., {0.0, 1.0, 0.5})
  - `cmyk` - CMYK tuple {cyan, magenta, yellow, black} (e.g., {0.0, 1.0, 1.0, 0.0})
  - `name` - Symbolic name of the color (e.g., :primary, :error)
  - `inverted` - Boolean indicating if the color should be inverted

  ## Examples

      # Creating a color from hex
      color = Aurora.Color.to_color_info("#FF5733")

      # Creating from RGB
      color = Aurora.Color.to_color_info({255, 87, 51})

      # Creating from color name
      color = Aurora.Color.to_color_info(:primary)

      # Accessing different color formats
      color = Aurora.Color.to_color_info("#FF0000")
      color.hex   # "#FF0000"
      color.rgb   # {255, 0, 0}
      color.hsv   # {0.0, 1.0, 1.0}
      color.name  # :red or nil if not a named color

      # Creating with inversion
      inverted_color = %Aurora.Structs.ColorInfo{
        hex: "#FFFFFF",
        inverted: true
      }

  ## Features

  - All color formats are kept in sync automatically
  - Conversion between formats happens internally
  - Named colors are preserved when available
  - Inversion flag allows for background/text color swapping
  - Used internally by Aurora's formatting system
  - Supports advanced color manipulation (lighten/darken)
  """

  @default_color Application.compile_env(:aurora, :colors)[:colors][:no_color]

  defstruct hex: @default_color.hex,
            rgb: @default_color.rgb,
            argb: @default_color.argb,
            hsv: @default_color.hsv,
            hsl: @default_color.hsl,
            cmyk: @default_color.cmyk,
            name: @default_color.name,
            inverted: @default_color.inverted

  @type rgb_tuple :: {integer(), integer(), integer()}
  @type argb_tuple :: {integer(), integer(), integer(), integer()}
  @type hsv_tuple :: {number(), number(), number()}
  @type hsl_tuple :: {number(), number(), number()}
  @type cmyk_tuple :: {number(), number(), number(), number()}

  @type t :: %__MODULE__{
          hex: String.t(),
          rgb: rgb_tuple,
          argb: argb_tuple,
          hsv: hsv_tuple,
          hsl: hsl_tuple,
          cmyk: cmyk_tuple,
          name: atom(),
          inverted: boolean()
        }
end
