# CHANGELOG

## Versión 1.0.4 (2025-09-27)

### 🔧 Optimizaciones y Refactoring

- **Eliminación de código duplicado**: Removidas implementaciones duplicadas de `deep_merge/2`, `clean_nil_values/1` y `cast/2` entre módulos Aurora.Ensure y Aurora.Convert
- **Aurora.Color**: Mejorada generación de gradientes con mejor manejo de tipos y funciones helper extraídas
- **Aurora.Format**: Extraída función helper `create_pad_chunk/1` para reducir duplicación en funciones de alineación
- **Aurora.Convert**: Delegación de funciones utilitarias a Aurora.Ensure para mejor organización del código
- **Función `visible_length/1`**: Consolidada para reutilizar lógica de `clean_ansi/1`
- **Módulo principal Aurora**: Refactorizado `format/2` con funciones helper para mejor separación de responsabilidades

### 🧪 Mejoras en Tests

- Agregados tests exhaustivos para funciones delegadas en Aurora.Convert
- Nuevos tests para funciones helper de formato
- Tests adicionales para funcionalidad de gradientes optimizada
- Cobertura de tests completa mantenida (65 doctests, 158 tests, 0 fallos)

### 📚 Documentación

- Agregada anotación `@deprecated` para `Aurora.Color.all_colors_availables/0` (usar `get_all_colors/0`)
- Doctests actualizados para reflejar cambios en tipos de retorno
- README revisado y confirmado como preciso

### ⚙️ Compatibilidad

- **Mantiene compatibilidad total hacia atrás**: Todas las APIs públicas permanecen iguales
- **Funcionalidad preservada**: Todos los tests pasan sin cambios
- **Calidad de código**: Cumple con Credo strict mode sin problemas

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
