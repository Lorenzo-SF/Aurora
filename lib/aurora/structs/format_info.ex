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

  ### Configuraciones adicionales
  - `add_line` - Añadir saltos de línea (:before, :after, :both, :none)
  - `animation` - Prefijo de animación
  - `mode` - Modo de renderizado (:normal, :table, :raw)

  ## Tipos de alineación

  - `:left` - Alineación izquierda (predeterminada)
  - `:right` - Alineación derecha
  - `:center` - Centrado
  - `:justify` - Justificado
  - `:center_block` - Centrado en bloque (para tablas)

  ## Modos de renderizado

  - `:normal` - Renderizado estándar con formateo completo
  - `:table` - Optimizado para renderizado de tablas
  - `:raw` - Renderizado mínimo sin procesamiento adicional

  ## Uso básico

      iex> chunk = %Aurora.Structs.ChunkText{text: "Hola"}
      iex> format_info = %Aurora.Structs.FormatInfo{
      ...>   chunks: [chunk],
      ...>   align: :center,
      ...>   mode: :table,
      ...>   add_line: :both
      ...> }

  ## Características

  - El campo `chunks` es obligatorio
  - La indentación puede ser manual o automática basada en colores
  - Soporta múltiples modos de renderizado para diferentes contextos
  - Permite animaciones y prefijos personalizados
  - Flexible configuración de saltos de línea
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
