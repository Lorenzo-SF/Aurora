defmodule Aurora.Structs.ChunkText do
  @moduledoc """
  Estructura que representa un fragmento de texto con formato propio.

  Un `ChunkText` es la unidad básica de texto formateado en Aurora. Cada chunk
  contiene texto, información de color opcional y configuraciones adicionales
  como enlaces.

  ## Campos

  - `text` - El contenido de texto (requerido)
  - `color` - Información de color (opcional, %ColorInfo{})
  - `link` - Indica si el texto es un enlace (boolean)

  ## Uso básico

      iex> chunk = %Aurora.Structs.ChunkText{text: "Hola mundo"}
      iex> chunk.text
      "Hola mundo"

      iex> color = %Aurora.Structs.ColorInfo{name: :primary}
      iex> chunk_colored = %Aurora.Structs.ChunkText{text: "Azul", color: color}

  ## Características

  - El campo `text` es obligatorio
  - El color es opcional y utiliza la estructura ColorInfo
  - Soporta configuración como enlace para formateo especial
  """

  @enforce_keys [:text]
  defstruct text: "",
            color: nil,
            effects: nil

  @type t :: %__MODULE__{
          text: String.t(),
          color: Aurora.Structs.ColorInfo.t() | nil,
          effects: Aurora.Structs.EffectInfo.t() | nil
        }
end
