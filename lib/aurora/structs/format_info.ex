defmodule Aurora.Structs.FormatInfo do
  @moduledoc """
  Estructura de configuración global para formateo de texto compuesto.

  `FormatInfo` contiene toda la información necesaria para formatear un conjunto
  de fragmentos de texto (chunks) con opciones de alineación, efectos, indentación
  y configuraciones adicionales.

  ## Campos

  ### Contenido
  - `chunks` - Lista de ChunkText a formatear (requerido)
  - `default_color` - Color por defecto para chunks sin color

  ### Alineación e indentación
  - `align` - Tipo de alineación (:left, :right, :center, :justify, :center_block)
  - `manual_tabs` - Número de tabs manuales (-1 para automático)

  ### Efectos de texto
  - `effects` - Estructura EffectInfo con efectos de texto (opcional)

  ### Configuraciones adicionales
  - `add_line` - Añadir saltos de línea (:before, :after, :both, :none)
  - `animation` - Prefijo de animación

  ## Tipos de alineación

  - `:left` - Alineación izquierda (predeterminada)
  - `:right` - Alineación derecha
  - `:center` - Centrado
  - `:justify` - Justificado
  - `:center_block` - Centrado en bloque (para tablas)

  ## Uso básico

      iex> chunk = %Aurora.Structs.ChunkText{text: "Hola"}
      iex> effects = %Aurora.Structs.EffectInfo{bold: true, italic: true}
      iex> format_info = %Aurora.Structs.FormatInfo{
      ...>   chunks: [chunk],
      ...>   align: :center,
      ...>   effects: effects
      ...> }

  ## Características

  - El campo `chunks` es obligatorio
  - La indentación puede ser manual o automática basada en colores
  - Los efectos se aplican a todo el texto formateado
  - Soporta animaciones y prefijos personalizados
  """

  @enforce_keys [:chunks]
  defstruct chunks: [],
            default_color: nil,
            align: :left,
            manual_tabs: -1,
            add_line: :none,
            animation: ""

  @type t :: %__MODULE__{
          chunks: [Aurora.Structs.ChunkText.t()],
          default_color: Aurora.Structs.ColorInfo.t() | nil,
          align: :left | :right | :center | :center_block | :justify,
          manual_tabs: non_neg_integer(),
          add_line: :before | :after | :both | :none,
          animation: String.t()
        }
end
