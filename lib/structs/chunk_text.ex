defmodule Aurora.Structs.ChunkText do
  @moduledoc """
  Estructura que representa un fragmento de texto con formato y posicionamiento.

  Un `ChunkText` es la unidad básica de texto formateado en Aurora. Cada chunk
  contiene texto, información de color opcional, efectos ANSI y coordenadas
  de posición para renderizado avanzado.

  ## Campos

  - `text` - El contenido de texto (requerido)
  - `color` - Información de color (opcional, %ColorInfo{})
  - `effects` - Efectos ANSI como bold, italic, etc. (opcional, %EffectInfo{})
  - `pos_x` - Posición horizontal para renderizado (integer, default: 0)
  - `pos_y` - Posición vertical para renderizado (integer, default: 0)

  ## Uso básico

      iex> chunk = %Aurora.Structs.ChunkText{text: "Hola mundo"}
      iex> chunk.text
      "Hola mundo"

      iex> color = %Aurora.Structs.ColorInfo{name: :primary}
      iex> effects = %Aurora.Structs.EffectInfo{bold: true, underline: true}
      iex> _chunk_formatted = %Aurora.Structs.ChunkText{
      ...>   text: "Texto formateado",
      ...>   color: color,
      ...>   effects: effects,
      ...>   pos_x: 10,
      ...>   pos_y: 5
      ...> }

  ## Características

  - El campo `text` es obligatorio
  - El color es opcional y utiliza la estructura ColorInfo
  - Los efectos son opcionales y utilizan la estructura EffectInfo
  - Las posiciones permiten renderizado preciso en terminal
  - Soporta múltiples efectos ANSI simultáneos
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
