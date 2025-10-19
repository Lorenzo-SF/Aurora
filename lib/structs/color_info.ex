defmodule Aurora.Structs.ColorInfo do
  @moduledoc """
  Representa información de color en múltiples formatos.
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
