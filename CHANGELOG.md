# Changelog

Todos los cambios notables a este proyecto se documentarán en este archivo.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
y este proyecto adhiere a [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.5] - 2025-10-11

### 🎉 Versión Estable Actual

Actualización para integración con Proyecto Ypsilon.

### 🏗️ Arquitectura Base

- **Nivel 1A en Proyecto Ypsilon**
- **LIBRERÍA BASE SIN DEPENDENCIAS**
- **Sin dependencias circulares**
- **Completa independencia de otros niveles**

### 🎨 Sistema de Colores y Formateo

#### Funciones Principales
- `Aurora.format/2` - Formateo con color, align, bold y más
- `Aurora.colorize/2` - Solo aplicar color
- `Aurora.stylize/2` - Aplicar efectos ANSI (individuales/múltiples)

#### Datos Estructurados
- `Aurora.json/2` - JSON formateado
- `Aurora.chunks/1` - Crear múltiples chunks
- `Aurora.format_chunks/2` - Formatear lista de chunks

#### Utilidades
- `Aurora.clean/1` - Quitar códigos ANSI
- `Aurora.text_length/1` - Longitud sin ANSI
- `Aurora.colors/0` - Listar colores
- `Aurora.effects/0` - Listar efectos

### 🔧 Módulos Especializados

#### Formato Avanzado
- `Aurora.Format` - Control total del formateo
- `Aurora.Color` - Manejo avanzado de colores
- `Aurora.Effects` - Control de efectos
- `Aurora.Convert` - Utilidades de conversión
- `Aurora.Ensure` - Garantía de tipos
- `Aurora.Normalize` - Normalización de datos

### 📦 Estructuras de Datos

#### ChunkText
```elixir
%Aurora.Structs.ChunkText{
  text: String.t(),           # Texto (requerido)
  color: %ColorInfo{},        # Color opcional
  effects: %EffectInfo{},     # Efectos opcionales
  pos_x: integer(),           # Posición horizontal
  pos_y: integer()            # Posición vertical
}
```

#### ColorInfo
```elixir
%Aurora.Structs.ColorInfo{
  name: atom(),               # Nombre del color
  hex: String.t(),           # Código hexadecimal
  inverted: boolean()         # Si está invertido
}
```

#### FormatInfo
```elixir
%Aurora.Structs.FormatInfo{
  chunks: [%ChunkText{}],     # Lista de chunks (requerido)
  default_color: %ColorInfo{}, # Color por defecto
  align: atom(),              # Alineación (:left, :right, :center, :justify, :center_block)
  manual_tabs: integer(),    # Indentación manual (-1 = automática)
  add_line: atom(),           # Saltos de línea (:before, :after, :both, :none)
  animation: String.t(),      # Prefijo de animación
  mode: atom()                # Modo de renderizado (:normal, :table, :raw)
}
```

#### EffectInfo
```elixir
%Aurora.Structs.EffectInfo{
  bold: boolean(),            # Negrita
  italic: boolean(),          # Cursiva
  underline: boolean(),       # Subrayado
  dim: boolean(),             # Atenuado
  blink: boolean(),           # Parpadeante
  reverse: boolean(),          # Invertido
  hidden: boolean(),          # Oculto
  strikethrough: boolean()    # Tachado
}
```

### 🧪 Pruebas

- Suite completa de pruebas unitarias
- Cobertura de código > 93%
- Tests de integración para todas las funciones principales
- Tests para casos de borde y errores

### 📚 Documentación

- README.md completo con ejemplos prácticos
- Documentación en línea para todas las funciones públicas
- Guía de uso para diferentes escenarios
- Integración con `mix docs`

## [1.0.4] - 2025-10-10

### 🚀 Versión Anterior Estable

Versión estable anterior que servirá como base para la nueva arquitectura.

### 🛠️ Funcionalidad Principal

- Sistema de colores ANSI completo
- Formateo de texto con alineación
- Efectos de texto (negrita, cursiva, subrayado)
- Gradientes de color
- Soporte para JSON formateado
- Utilidades de limpieza de códigos ANSI

## Versión 1.0.3 (2025-09-26)

### 🔧 Refactoring

- Refactor y fix de Effects. Actualizacion de documentación

## Versión 1.0.2 (2025-09-25)

### 🔧 Refactoring

- Refactor nombres de funciones de "Ensure"

## Versión 1.0.1 (2025-09-24)

### 

- Refactor de "Convert" porque en algunas ocasiones da problemas de compilacion

## Versión 1.0.0 (2025-09-24)

### 

- Publicacion libreria

[Unreleased]: https://github.com/usuario/aurora/compare/v1.0.5...HEAD
[1.0.5]: https://github.com/usuario/aurora/releases/tag/v1.0.5
[1.0.4]: https://github.com/usuario/aurora/releases/tag/v1.0.4