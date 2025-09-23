# Aurora 🎨

> _"Porque la vida es muy corta para terminales en blanco y negro"_

🌈 **La biblioteca más simpática para hacer que tu terminal se vea increíble**

¿Cansado de ver texto aburrido en tu terminal? ¿Quieres que tus logs tengan más estilo que un influencer en Instagram? **Aurora** es tu nuevo mejor amigo. Convierte tu terminal del equivalente digital de una pared gris en un festival de colores y efectos que hasta tu gato querrá ver.

## ✨ Filosofía de Aurora

Aurora está diseñado con **simplicidad en mente**:

- 🚀 **Uso básico ultra-simple** - `Aurora.format/2` con opciones básicas para el 90% de casos
- 🔧 **Módulos especializados** - Para casos avanzados que requieren control total
- 📚 **Documentación clara** - Con ejemplos que hasta tu abuela entendería

## 🚀 Instalación (más fácil que hacer café)

```elixir
# En tu mix.exs, agrega esta línea mágica:
def deps do
  [
    {:aurora, "~> 1.0"}
  ]
end
```

```bash
mix deps.get  # ¡Y ya está! 🎉
```

### 🎨 Configuración Opcional

Si quieres personalizar los colores, crea un archivo `config/config.exs` en tu proyecto:

```elixir
# config/config.exs
import Config

config :aurora, :colors,
  colors: %{
    primary: %{hex: "#0066CC"},     # Tu color principal
    error: %{hex: "#DC3545"},       # Tu color de error
    # ... más colores personalizados
  }
```

Ver [configuración completa](#-configuración-personalizada-de-colores) más abajo.

## 📋 Funciones Disponibles - Referencia Rápida

### 🎯 Funciones Básicas (en Aurora.ex)

| Función             | Descripción                            | Ejemplo                                   |
| ------------------- | -------------------------------------- | ----------------------------------------- |
| `Aurora.format/2`   | Formateo básico con color, align, bold | `Aurora.format("texto", color: :primary)` |
| `Aurora.colorize/2` | Solo aplicar color                     | `Aurora.colorize("texto", :error)`        |
| `Aurora.stylize/2`  | Solo aplicar efectos                   | `Aurora.stylize("texto", :bold)`          |

### 📊 Datos Estructurados (en Aurora.ex)

| Función                  | Descripción               | Ejemplo                              |
| ------------------------ | ------------------------- | ------------------------------------ |
| `Aurora.json/2`          | JSON formateado           | `Aurora.json(data, color: :info)`    |
| `Aurora.chunks/1`        | Crear múltiples chunks    | `Aurora.chunks([{"Error", :error}])` |
| `Aurora.format_chunks/2` | Formatear lista de chunks | `Aurora.format_chunks(chunks)`       |

### 🔧 Utilidades (en Aurora.ex)

| Función                | Descripción         | Ejemplo                                   |
| ---------------------- | ------------------- | ----------------------------------------- |
| `Aurora.clean/1`       | Quitar códigos ANSI | `Aurora.clean("\\e[31mTexto\\e[0m")`      |
| `Aurora.text_length/1` | Longitud sin ANSI   | `Aurora.text_length("\\e[31mHola\\e[0m")` |
| `Aurora.colors/0`      | Listar colores      | `Aurora.colors()`                         |
| `Aurora.effects/0`     | Listar efectos      | `Aurora.effects()`                        |

**💡 Para funciones avanzadas** (tablas, badges, divisores, encabezados, efectos específicos, etc.) usar directamente los módulos especializados: `Aurora.Format`, `Aurora.Color`, `Aurora.Effects`, `Aurora.Convert`.

## 🎯 Uso Básico (para el 90% de casos)

### La función mágica: `Aurora.format/2`

```elixir
# Texto simple con color
Aurora.format("¡Hola mundo!", color: :primary) |> IO.puts()

# Texto con error (rojo y negrita)
Aurora.format("Error crítico", color: :error, bold: true) |> IO.puts()

# Texto centrado
Aurora.format("Título centrado", color: :info, align: :center) |> IO.puts()

# Múltiples líneas con el mismo formato |> IO.puts()
Aurora.format(["Línea 1", "Línea 2", "Línea 3"], color: :success) |> IO.puts()

# Color personalizado con hex
Aurora.format("Color custom", color: "#FF6B35") |> IO.puts()
```

### Opciones básicas de `Aurora.format/2`

| Opción   | Valores                                              | Descripción          |
| -------- | ---------------------------------------------------- | -------------------- |
| `:color` | `:primary`, `:error`, `:success`, etc. o `"#FF0000"` | Color del texto      |
| `:align` | `:left`, `:right`, `:center`                         | Alineación del texto |
| `:bold`  | `true`/`false`                                       | Texto en negrita     |

## 🔧 Funciones Especializadas (para casos avanzados)

### Colorizar texto directamente

```elixir
# Solo aplicar color
Aurora.colorize("texto", :primary) |> IO.puts()
Aurora.colorize("error", "#FF0000") |> IO.puts()
```

### Efectos de texto

```elixir
# Un solo efecto
Aurora.stylize("texto", :bold) |> IO.puts()

# Múltiples efectos
Aurora.stylize("texto", [:bold, :underline, :italic]) |> IO.puts()
```

### Gradientes de color

```elixir
# Generar gradiente de 6 colores
colors = Aurora.gradient("#FF0000", "#00FF00")  # Rojo a verde

# Gradiente personalizado
colors = Aurora.gradient("#FF0000", "#0000FF", 10)  # 10 colores
```

### Trabajar con chunks (piezas de texto)

```elixir
# Crear chunk individual
chunk = Aurora.chunk("texto", :primary)

# Crear múltiples chunks
chunks = Aurora.chunks([
  {"Error:", :error},
  {" Archivo no encontrado", :warning}
])

# Formatear lista de chunks
Aurora.format_chunks(chunks)
```

### Utilidades básicas

```elixir
# Limpiar códigos ANSI de texto formateado
text_limpio = Aurora.clean("\\e[31mTexto\\e[0m")

# Obtener longitud real del texto (sin códigos ANSI)
longitud = Aurora.text_length("\\e[31mHola\\e[0m")  # => 4
```

### Formateo de datos estructurados

```elixir
# JSON (acepta maps, strings, listas)
data = %{name: "Juan", age: 25, active: true}
Aurora.json(data) |> IO.puts()                            # Pretty print con colores
Aurora.json(data, color: :success) |> IO.puts()           # JSON en verde
Aurora.json(data, compact: true) |> IO.puts()             # Formato compacto
Aurora.json(data, indent: true) |> IO.puts()              # Con indentación extra

# Para funciones más avanzadas (tablas, badges, etc.) usar los módulos especializados
# Ver sección "Uso Avanzado con Módulos" más abajo
```

## 📋 Colores Disponibles

### Colores Principales

| Color         | Nombre        | Hex     | Uso típico              |
| ------------- | ------------- | ------- | ----------------------- |
| `:primary`    | Azul claro    | #A1E7FA | Información principal   |
| `:secondary`  | Verde azulado | #3AABA3 | Información secundaria  |
| `:ternary`    | Naranja       | #FF8000 | Información terciaria   |
| `:quaternary` | Púrpura       | #9B42E2 | Información cuaternaria |

### Colores de Estado

| Color      | Nombre     | Hex     | Uso típico           |
| ---------- | ---------- | ------- | -------------------- |
| `:success` | Verde lima | #97C53C | Operaciones exitosas |
| `:warning` | Amarillo   | #FFCC00 | Advertencias         |
| `:error`   | Rojo coral | #FF5B5B | Errores              |
| `:info`    | Cyan       | #00FFFF | Información general  |
| `:debug`   | Gris       | #B0B0B0 | Información de debug |

### Colores Especiales

| Color        | Nombre     | Hex     | Especial             |
| ------------ | ---------- | ------- | -------------------- |
| `:critical`  | Amarillo   | #FBFF00 | ⚠️ Invertido (fondo) |
| `:alert`     | Amarillo   | #FBFF00 | ⚠️ Invertido (fondo) |
| `:emergency` | Rojo       | #FF0000 | ⚠️ Invertido (fondo) |
| `:happy`     | Rosa       | #EE80C3 | Mensajes positivos   |
| `:notice`    | Azul claro | #5FD7FF | Notificaciones       |
| `:menu`      | Azul suave | #ABCDF1 | Elementos de menú    |
| `:no_color`  | Blanco     | #F8F8F2 | Sin color específico |

### 🎨 Configuración Personalizada de Colores

Puedes personalizar los colores predefinidos creando tu propia configuración en `config/config.exs`:

```elixir
# config/config.exs
config :aurora, :colors,
  colors: %{
    no_color: %{name: :no_color, hex: "#F8F8F2"},
    debug: %{name: :debug, hex: "#B0B0B0"},
    primary: %{name: :primary, hex: "#A1E7FA"},
    secondary: %{name: :secondary, hex: "#3AABA3"},
    ternary: %{name: :ternary, hex: "#FF8000"},
    quaternary: %{name: :quaternary, hex: "#9B42E2"},
    success: %{name: :success, hex: "#97C53C"},
    warning: %{name: :warning, hex: "#FFCC00"},
    warn: %{name: :warning, hex: "#FFCC00"},
    error: %{name: :error, hex: "#FF5B5B"},
    info: %{name: :info, hex: "#00ffff"},
    happy: %{name: :happy, hex: "#EE80C3"},
    background: %{name: :background, hex: "#32302f"},
    menu: %{name: :menu, hex: "#abcdf1"},
    notice: %{name: :notice, hex: "#5FD7FF"},
    critical: %{name: :critical, hex: "#fbff00", inverted: true},
    alert: %{name: :alert, hex: "#fbff00", inverted: true},
    emergency: %{name: :emergency, hex: "#FF0000", inverted: true}
  },
  gradients: %{
    gradient_1: %{name: :gradient_1, hex: "#ff8000"},
    gradient_2: %{name: :gradient_2, hex: "#ff9429"},
    gradient_3: %{name: :gradient_3, hex: "#ffa952"},
    gradient_4: %{name: :gradient_4, hex: "#ffbd7a"},
    gradient_5: %{name: :gradient_5, hex: "#ffd2a3"},
    gradient_6: %{name: :gradient_6, hex: "#ffe6cc"}
  }
```

**Uso con colores personalizados:**

```elixir
# Usar colores personalizados
Aurora.format("Mensaje de marca", color: :brand)
Aurora.format("Texto resaltado", color: :highlight)
Aurora.format("Información secundaria", color: :muted)

# Los colores se aplican automáticamente
Aurora.colorize("Gradiente fuego", :fire)
```

**Ejemplos de configuración:** Consulta el archivo [`config/config.exs.example`](config/config.exs.example) para ver un ejemplo completo de configuración con muchos colores personalizados.

**Nota:** Si no se proporciona configuración, Aurora usará los colores predeterminados mostrados en la tabla.

### 🔍 Consultar Colores Disponibles

Puedes obtener dinámicamente todos los colores configurados:

```elixir
# Obtener todos los colores disponibles
colores_disponibles = Aurora.colors()
IO.inspect(colores_disponibles)

# Verificar si un color específico existe
color_existe = Map.has_key?(Aurora.colors(), :brand)

# Obtener información detallada de un color
info_color = Aurora.Color.get_color_info(:primary)
IO.inspect(info_color)
# => %Aurora.Structs.ColorInfo{name: :primary, hex: "#00FFFF", inverted: false}
```

## 🎨 Efectos Disponibles

| Efecto           | Descripción        |
| ---------------- | ------------------ |
| `:bold`          | Texto en negrita   |
| `:italic`        | Texto en cursiva   |
| `:underline`     | Texto subrayado    |
| `:dim`           | Texto atenuado     |
| `:blink`         | Texto parpadeante  |
| `:reverse`       | Colores invertidos |
| `:strikethrough` | Texto tachado      |

## 🏗️ Uso Avanzado con Módulos

Para casos donde necesitas control total, usa los módulos especializados:

### `Aurora.Format` - Control total del formateo

```elixir
# Crear estructura FormatInfo completa
format_info = %Aurora.Structs.FormatInfo{
  chunks: [
    %Aurora.Structs.ChunkText{
      text: "Título importante",
      color: Aurora.Color.get_color_info(:primary),
      effects: %Aurora.Structs.EffectInfo{bold: true, underline: true}
    }
  ],
  align: :center,
  manual_tabs: 2,
  add_line: :both
}

resultado = Aurora.Format.format(format_info)
```

### `Aurora.Color` - Manejo avanzado de colores

```elixir
# Obtener información de color
color_info = Aurora.Color.get_color_info(:primary)

# Trabajar con colores hex
color_custom = Aurora.Color.get_color_info("#FF6B35")

# Generar gradientes entre colores
gradiente = Aurora.Color.generate_gradient_between("#FF0000", "#00FF00")

# Obtener todos los colores disponibles
colores = Aurora.Color.get_all_colors()
```

### `Aurora.Effects` - Control de efectos

```elixir
# Aplicar efecto individual
texto = Aurora.Effects.apply_effect("texto", :bold)

# Aplicar múltiples efectos
texto = Aurora.Effects.apply_multiple_effects("texto", [:bold, :italic])

# Aplicar efectos desde lista de opciones
texto = Aurora.Effects.apply_effects("texto", [bold: true, italic: true])
```

### `Aurora.Convert` - Utilidades de conversión

```elixir
# Convertir datos a chunks
chunk = Aurora.Convert.to_chunk("texto")
chunk = Aurora.Convert.to_chunk({"texto", :primary})

# Verificar si datos forman tabla
es_tabla = Aurora.Convert.table?([[1, 2], [3, 4]])
```

## 🧪 Estructuras de Datos

### `ChunkText` - Fragmento de texto formateado

```elixir
%Aurora.Structs.ChunkText{
  text: "Mi texto",                    # Texto (requerido)
  color: %ColorInfo{},                 # Color opcional
  effects: %EffectInfo{}               # Efectos opcionales
}
```

### `ColorInfo` - Información de color

```elixir
%Aurora.Structs.ColorInfo{
  name: :primary,                      # Nombre del color
  hex: "#00FFFF",                      # Código hexadecimal
  inverted: false                      # Si está invertido
}
```

### `FormatInfo` - Configuración completa de formato

```elixir
%Aurora.Structs.FormatInfo{
  chunks: [%ChunkText{}],              # Lista de chunks (requerido)
  default_color: %ColorInfo{},         # Color por defecto
  align: :left,                        # Alineación
  manual_tabs: -1,                     # Indentación manual (-1 = automática)
  add_line: :none,                     # Saltos de línea (:before, :after, :both, :none)
  animation: ""                        # Prefijo de animación
}
```

### `EffectInfo` - Efectos de texto

```elixir
%Aurora.Structs.EffectInfo{
  bold: false,                         # Negrita
  italic: false,                       # Cursiva
  underline: false,                    # Subrayado
  dim: false,                          # Atenuado
  blink: false,                        # Parpadeante
  reverse: false,                      # Invertido
  hidden: false,                       # Oculto
  strikethrough: false,                # Tachado
  link: false                          # Como enlace
}
```

## 🧪 Testing

```bash
# Ejecutar todos los tests
mix test

# Ejecutar solo doctests
mix test --only doctest

# Ejecutar tests con cobertura
mix test --cover
```

## 📦 Dependencias

- `:jason` - Para formateo de JSON (incluida automáticamente)

## 📄 Licencia

MIT License - ¡Úsalo, mejóralo, compártelo!

---

## 🤝 Contribuir

¿Tienes ideas para hacer Aurora aún más genial? ¡Los PRs son bienvenidos! Asegúrate de:

1. Mantener la filosofía simple
2. Agregar tests para nuevas funcionalidades
3. Actualizar la documentación
4. Hacer que todo sea súper fácil de usar

---

**¡Disfruta haciendo tu terminal hermoso! 🎨✨**
