defmodule Aurora.Structs.EffectInfo do
  @moduledoc """
  Estructura que representa información de efectos para texto en terminal.

  `EffectInfo` encapsula todos los efectos de texto que se pueden aplicar,
  incluyendo negrita, cursiva, subrayado y otros efectos ANSI.

  ## Campos

  - `bold` - Texto en negrita
  - `dim` - Texto atenuado/tenue
  - `italic` - Texto en cursiva
  - `underline` - Texto subrayado
  - `blink` - Texto parpadeante
  - `reverse` - Colores invertidos
  - `hidden` - Texto oculto
  - `strikethrough` - Texto tachado

  ## Uso básico

      iex> # Efectos básicos
      iex> effects = %Aurora.Structs.EffectInfo{bold: true, italic: true}

      iex> # Todos los efectos activados
      iex> all_effects = %Aurora.Structs.EffectInfo{
      ...>   bold: true,
      ...>   italic: true,
      ...>   underline: true,
      ...>   blink: true
      ...> }

  ## Características

  - Todos los campos son opcionales y por defecto están en `false`
  - Se puede combinar cualquier número de efectos
  - Los efectos se aplican usando códigos de escape ANSI
  - Algunos efectos pueden no ser soportados en todos los terminales
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
