defmodule Aurora.Structs.ColorInfo do
  @moduledoc """
  Estructura que representa información de color para texto en terminal.

  `ColorInfo` encapsula toda la información necesaria para aplicar color a texto,
  incluyendo colores predefinidos, colores personalizados en formato hexadecimal
  y configuraciones especiales como inversión.

  ## Campos

  - `hex` - Código de color hexadecimal (ej: "#FF0000")
  - `name` - Nombre del color predefinido (átomo como :primary, :error, etc.)
  - `inverted` - Indica si se debe invertir el color (boolean)

  ## Colores predefinidos

  El sistema incluye varios colores predefinidos:

  - `:primary` - Color principal del sistema
  - `:secondary` - Color secundario
  - `:success` - Verde para éxito
  - `:warning` - Amarillo para advertencias
  - `:error` - Rojo para errores
  - `:info` - Azul para información
  - `:no_color` - Sin color

  ## Uso básico

      iex> # Color predefinido
      iex> primary = %Aurora.Structs.ColorInfo{name: :primary}

      iex> # Color personalizado
      iex> custom = %Aurora.Structs.ColorInfo{hex: "#FF5733"}

      iex> # Color invertido
      iex> inverted = %Aurora.Structs.ColorInfo{name: :error, inverted: true}

  ## Características

  - Soporta tanto colores predefinidos como personalizados
  - Los colores hexadecimales se convierten automáticamente a códigos ANSI
  - La inversión aplica el efecto reverse de ANSI
  - Los valores por defecto se obtienen de la configuración de la aplicación
  """

  defstruct hex: Application.compile_env(:aurora, :colors)[:colors][:no_color][:hex],
            name: Application.compile_env(:aurora, :colors)[:colors][:no_color][:name],
            inverted: false

  @type t :: %__MODULE__{
          hex: String.t(),
          name: atom() | nil,
          inverted: boolean()
        }
end
