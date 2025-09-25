defmodule Aurora.Effects do
  @moduledoc """
  Módulo para aplicar efectos ANSI a texto.

  Este módulo proporciona funcionalidades para aplicar diferentes tipos de efectos
  como negrita, cursiva, subrayado, etc. usando códigos de escape ANSI.

  Puede trabajar con texto simple y aplicar efectos basados en EffectInfo,
  o procesar ChunkText que ya contiene efectos.

  ## Efectos soportados

  - `:bold` - Texto en negrita
  - `:dim` - Texto tenue/atenuado
  - `:italic` - Texto en cursiva
  - `:underline` - Texto subrayado
  - `:blink` - Texto parpadeante
  - `:reverse` - Colores invertidos
  - `:hidden` - Texto oculto
  - `:strikethrough` - Texto tachado

  ## Uso básico

      iex> Aurora.Effects.apply_effect("texto", :bold)
      "\\e[1mtexto\\e[0m"

      iex> Aurora.Effects.apply_multiple_effects("texto", [:bold, :underline])
      "\\e[1m\\e[4mtexto\\e[0m"
  """

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
    strikethrough: "\e[9m"
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
  """
  @spec apply_effect(String.t(), atom()) :: String.t()
  def apply_effect(text, effect) when is_atom(effect) do
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
  """
  @spec apply_multiple_effects(String.t(), [atom()]) :: String.t()
  def apply_multiple_effects(text, effects) when is_list(effects) do
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
  """
  @spec apply_effects(String.t(), list()) :: String.t()

  def apply_effects(text, opts) when is_list(opts) do
    effects_to_apply =
      opts
      |> Enum.filter(fn {_key, value} -> value == true end)
      |> Enum.map(fn {key, _value} -> key end)
      |> Enum.filter(fn key -> Map.has_key?(@effects, key) end)

    apply_multiple_effects(text, effects_to_apply)
  end

  @doc """
  Lista todos los efectos disponibles.

  ## Ejemplos

      iex> effects = Aurora.Effects.available_effects()
      iex> Enum.sort(effects)
      [:blink, :bold, :dim, :hidden, :italic, :reverse, :strikethrough, :underline]
  """
  @spec available_effects() :: [atom()]
  def available_effects do
    Map.keys(@effects)
  end

  @doc """
  Verifica si un efecto está disponible.

  ## Ejemplos

      iex> Aurora.Effects.valid_effect?(:bold)
      true

      iex> Aurora.Effects.valid_effect?(:invalid)
      false
  """
  @spec valid_effect?(atom()) :: boolean()
  def valid_effect?(effect) do
    Map.has_key?(@effects, effect)
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
  """
  @spec apply_effect_info(String.t(), EffectInfo.t()) :: String.t()
  def apply_effect_info(text, %EffectInfo{} = effect_info) do
    effects_to_apply = extract_active_effects(effect_info)
    apply_multiple_effects(text, effects_to_apply)
  end

  @doc """
  Aplica efectos a un ChunkText que ya contiene información de efectos.

  Retorna un ChunkText actualizado con el texto formateado.

  ## Parámetros

  - `chunk` - ChunkText con texto y efectos

  ## Ejemplos

      iex> effects = %Aurora.Structs.EffectInfo{bold: true}
      iex> chunk = %Aurora.Structs.ChunkText{text: "texto", effects: effects}
      iex> result = Aurora.Effects.apply_chunk_effects(chunk)
      iex> result.text
      "\\e[1mtexto\\e[0m"
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

  # Función privada para extraer efectos activos de EffectInfo
  @spec extract_active_effects(EffectInfo.t()) :: [atom()]
  defp extract_active_effects(%EffectInfo{} = effect_info) do
    effect_info
    |> Map.from_struct()
    |> Enum.filter(fn {_key, value} -> value == true end)
    |> Enum.map(fn {key, _value} -> key end)
    |> Enum.filter(fn key -> Map.has_key?(@effects, key) end)
  end
end
