defmodule Aurora.Effects do
  @moduledoc """
  Module for applying ANSI effects to text.

  This module provides functionality to apply different types of effects like
  bold, italic, underline, etc. using ANSI escape codes.

  It can work with simple text and apply effects based on EffectInfo,
  or process ChunkText that already contains effects.

  ## Supported Effects

  - `:bold` - Bold text
  - `:dim` - Dim/faint text
  - `:italic` - Italic text
  - `:underline` - Underlined text
  - `:blink` - Blinking text
  - `:reverse` - Inverted colors
  - `:hidden` - Hidden text
  - `:strikethrough` - Strikethrough text
  - `:link` - Link text (underline)

  ## Examples

      # Apply single effect to text
      Aurora.Effects.apply_effect("Hello", :bold)
      # "\\e[1mHello\\e[0m"

      # Apply multiple effects
      Aurora.Effects.apply_multiple_effects("Hello", [:bold, :underline])
      # "\\e[1m\\e[4mHello\\e[0m"

      # Apply effects from EffectInfo struct
      effects = %Aurora.Structs.EffectInfo{bold: true, italic: true}
      Aurora.Effects.apply_effect_info("Hello", effects)
      # "\\e[3m\\e[1mHello\\e[0m"

      # Apply effects to ChunkText
      chunk = %Aurora.Structs.ChunkText{
        text: "Hello",
        effects: %Aurora.Structs.EffectInfo{bold: true}
      }
      result = Aurora.Effects.apply_chunk_effects(chunk)

      # Apply effects using keyword options
      Aurora.Effects.apply_effects("Hello", [bold: true, underline: true])

      # Get available effects
      effects = Aurora.Effects.available_effects()
  """

  alias Aurora.Ensure
  alias Aurora.Structs.{ChunkText, EffectInfo}

  @reset "\e[0m"

  @effects %{
    bold: "\e[1m",
    dim: "\e[2m",
    italic: "\e[3m",
    underline: "\e[4m",
    blink: "\e[5m",
    reverse: "\e[7m",
    hidden: "\e[8m",
    strikethrough: "\e[9m",
    # Mismo código que underline para enlaces
    link: "\e[4m"
  }

  @doc """
  Aplica un efecto específico a un texto.

  ## Parámetros

  - `text` - El texto al que aplicar el efecto
  - `effect` - El efecto a aplicar (átomo)

  ## Ejemplos

      iex> Aurora.Effects.apply_effect("Hola", :bold)
      "\\e[1mHola\\e[0m"

      iex> Aurora.Effects.apply_effect("Mundo", :underline)
      "\\e[4mMundo\\e[0m"

      iex> Aurora.Effects.apply_effect("Texto", :invalid)
      "Texto"
  """
  @spec apply_effect(String.t(), atom()) :: String.t()
  def apply_effect(text, effect) when is_atom(effect) do
    text = Ensure.string(text)

    case Map.get(@effects, effect) do
      nil -> text
      code -> "#{code}#{text}#{@reset}"
    end
  end

  @doc """
  Aplica múltiples efectos a un texto.

  ## Parámetros

  - `text` - El texto al que aplicar los efectos
  - `effects` - Lista de efectos a aplicar

  ## Ejemplos

      iex> Aurora.Effects.apply_multiple_effects("texto", [:bold, :underline])
      "\\e[1m\\e[4mtexto\\e[0m"

      iex> Aurora.Effects.apply_multiple_effects("texto", [])
      "texto"

      iex> Aurora.Effects.apply_multiple_effects("texto", [:bold, :invalid])
      "\\e[1mtexto\\e[0m"
  """
  @spec apply_multiple_effects(String.t(), [atom()]) :: String.t()
  def apply_multiple_effects(text, effects) when is_list(effects) do
    text = Ensure.string(text)

    codes =
      effects
      |> Enum.map(&Map.get(@effects, &1))
      |> Enum.filter(& &1)
      |> Enum.join("")

    if codes != "", do: "#{codes}#{text}#{@reset}", else: text
  end

  @doc """
  Aplica efectos a un texto basado en una lista de opciones.

  ## Parámetros

  - `text` - El texto al que aplicar los efectos
  - `opts` - Lista de opciones con efectos (ej: [bold: true, italic: true])

  ## Ejemplos

      iex> Aurora.Effects.apply_effects("texto", [bold: true, italic: true])
      "\\e[1m\\e[3mtexto\\e[0m"

      iex> Aurora.Effects.apply_effects("texto", [bold: false, italic: true])
      "\\e[3mtexto\\e[0m"

      iex> Aurora.Effects.apply_effects("texto", [])
      "texto"
  """
  @spec apply_effects(String.t(), keyword() | list()) :: String.t()
  def apply_effects(text, opts) when is_list(opts) do
    text = Ensure.string(text)

    effects_to_apply =
      opts
      |> Enum.filter(fn {_key, value} -> value == true end)
      |> Enum.map(fn {key, _value} -> key end)
      |> Enum.filter(&valid_effect?/1)

    apply_multiple_effects(text, effects_to_apply)
  end

  @doc """
  Lista todos los efectos disponibles.

  ## Ejemplos

    iex> Aurora.Effects.available_effects()
    [:blink, :bold, :dim, :hidden, :italic, :link, :reverse, :strikethrough, :underline]
  """
  @spec available_effects() :: [atom()]
  def available_effects do
    Map.keys(@effects) |> Enum.sort()
  end

  @doc """
  Verifica si un efecto está disponible.

  ## Ejemplos

      iex> Aurora.Effects.valid_effect?(:bold)
      true

      iex> Aurora.Effects.valid_effect?(:underline)
      true

      iex> Aurora.Effects.valid_effect?(:invalid)
      false
  """
  @spec valid_effect?(atom()) :: boolean()
  def valid_effect?(effect) do
    Map.has_key?(@effects, effect)
  end

  @doc """
  Obtiene el código ANSI para un efecto específico.

  ## Parámetros

  - `effect` - El efecto del que obtener el código

  ## Ejemplos

      iex> Aurora.Effects.get_effect_code(:bold)
      "\\e[1m"

      iex> Aurora.Effects.get_effect_code(:underline)
      "\\e[4m"

      iex> Aurora.Effects.get_effect_code(:invalid)
      nil
  """
  @spec get_effect_code(atom()) :: String.t() | nil
  def get_effect_code(effect) do
    Map.get(@effects, effect)
  end

  @doc """
  Aplica efectos a un texto basado en una estructura EffectInfo.

  ## Parámetros

  - `text` - El texto al que aplicar los efectos
  - `effect_info` - Estructura EffectInfo con los efectos activados

  ## Ejemplos

      iex> effects = %Aurora.Structs.EffectInfo{bold: true}
      iex> Aurora.Effects.apply_effect_info("texto", effects)
      "\\e[1mtexto\\e[0m"

      iex> no_effects = %Aurora.Structs.EffectInfo{}
      iex> Aurora.Effects.apply_effect_info("texto", no_effects)
      "texto"

      iex> multiple_effects = %Aurora.Structs.EffectInfo{bold: true, italic: true, underline: true}
      iex> result = Aurora.Effects.apply_effect_info("texto", multiple_effects)
      iex> String.contains?(result, "\\e[1m")
      true
      iex> String.contains?(result, "\\e[3m")
      true
      iex> String.contains?(result, "\\e[4m")
      true
  """
  @spec apply_effect_info(String.t(), EffectInfo.t() | nil) :: String.t()
  def apply_effect_info(text, %EffectInfo{} = effect_info) do
    text = Ensure.string(text)
    effects_to_apply = extract_active_effects(effect_info)
    apply_multiple_effects(text, effects_to_apply)
  end

  def apply_effect_info(text, nil), do: Ensure.string(text)

  @doc """
  Aplica efectos a un ChunkText que ya contiene información de efectos.

  Retorna un ChunkText actualizado con el texto formateado.

  ## Parámetros

  - `chunk` - ChunkText con texto y efectos

  ## Ejemplos

      iex> effects = %Aurora.Structs.EffectInfo{bold: true}
      iex> chunk = %Aurora.Structs.ChunkText{text: "texto", effects: effects}
      iex> result = Aurora.Effects.apply_chunk_effects(chunk)
      iex> String.contains?(result.text, "\\e[1m")
      true

      iex> chunk = %Aurora.Structs.ChunkText{text: "texto", effects: nil}
      iex> result = Aurora.Effects.apply_chunk_effects(chunk)
      iex> result.text
      "texto"
  """
  @spec apply_chunk_effects(ChunkText.t()) :: ChunkText.t()
  def apply_chunk_effects(%ChunkText{effects: nil} = chunk) do
    # Sin efectos, devolver el chunk sin modificar
    chunk
  end

  def apply_chunk_effects(%ChunkText{text: text, effects: effect_info} = chunk) do
    formatted_text = apply_effect_info(text, effect_info)
    %{chunk | text: formatted_text}
  end

  def apply_chunk_effects(chunk) do
    # Handle non-ChunkText input by converting first
    chunk = Ensure.chunk_text(chunk)
    apply_chunk_effects(chunk)
  end

  @doc """
  Aplica efectos a una lista de ChunkText.

  ## Parámetros

  - `chunks` - Lista de ChunkText a procesar

  ## Ejemplos

      iex> effects = %Aurora.Structs.EffectInfo{bold: true}
      iex> chunks = [
      ...>   %Aurora.Structs.ChunkText{text: "uno", effects: effects},
      ...>   %Aurora.Structs.ChunkText{text: "dos", effects: nil}
      ...> ]
      iex> result = Aurora.Effects.apply_chunks_effects(chunks)
      iex> length(result)
      2
      iex> String.contains?(hd(result).text, "\\e[1m")
      true
  """
  @spec apply_chunks_effects([ChunkText.t()]) :: [ChunkText.t()]
  def apply_chunks_effects(chunks) when is_list(chunks) do
    Enum.map(chunks, &apply_chunk_effects/1)
  end

  @doc """
  Remueve todos los efectos ANSI de un texto.

  ## Parámetros

  - `text` - Texto que puede contener códigos ANSI

  ## Ejemplos

      iex> Aurora.Effects.remove_effects("\\e[1mtexto\\e[0m")
      "texto"

      iex> Aurora.Effects.remove_effects("\\e[1m\\e[3mtexto\\e[0m")
      "texto"

      iex> Aurora.Effects.remove_effects("texto normal")
      "texto normal"
  """
  @spec remove_effects(String.t()) :: String.t()
  def remove_effects(text) do
    text
    |> Ensure.string()
    |> String.replace(~r/\e\[[0-9;]*m/, "")
  end

  @doc """
  Convierte una lista de efectos a EffectInfo.

  ## Parámetros

  - `effects` - Lista de átomos representando efectos

  ## Ejemplos

      iex> Aurora.Effects.to_effect_info([:bold, :italic])
      %Aurora.Structs.EffectInfo{bold: true, italic: true}

      iex> Aurora.Effects.to_effect_info([])
      %Aurora.Structs.EffectInfo{}

      iex> Aurora.Effects.to_effect_info([:bold, :invalid])
      %Aurora.Structs.EffectInfo{bold: true}
  """
  @spec to_effect_info([atom()]) :: EffectInfo.t()
  def to_effect_info(effects) when is_list(effects) do
    # Crear EffectInfo base
    base_effect_info = %EffectInfo{}

    # Filtrar efectos válidos y aplicarlos
    valid_effects = Enum.filter(effects, &valid_effect?/1)

    # Convertir lista de efectos a keyword list con valores true
    effect_updates = Enum.map(valid_effects, fn effect -> {effect, true} end)

    # Aplicar las actualizaciones al struct
    struct(base_effect_info, effect_updates)
  end

  def to_effect_info(_), do: %EffectInfo{}

  # Función privada para extraer efectos activos de EffectInfo
  @spec extract_active_effects(EffectInfo.t()) :: [atom()]
  defp extract_active_effects(%EffectInfo{} = effect_info) do
    effect_info
    |> Map.from_struct()
    |> Enum.filter(fn {_key, value} -> value == true end)
    |> Enum.map(fn {key, _value} -> key end)
    |> Enum.filter(&valid_effect?/1)
  end
end
