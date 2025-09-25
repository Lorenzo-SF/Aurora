defmodule Aurora.EffectsTest do
  use ExUnit.Case
  doctest Aurora.Effects

  alias Aurora.Effects
  alias Aurora.Structs.{ChunkText, EffectInfo}

  describe "apply_effect/2" do
    test "applies bold effect" do
      result = Effects.apply_effect("text", :bold)
      assert result == "\e[1mtext\e[0m"
    end

    test "applies italic effect" do
      result = Effects.apply_effect("text", :italic)
      assert result == "\e[3mtext\e[0m"
    end

    test "applies underline effect" do
      result = Effects.apply_effect("text", :underline)
      assert result == "\e[4mtext\e[0m"
    end

    test "applies dim effect" do
      result = Effects.apply_effect("text", :dim)
      assert result == "\e[2mtext\e[0m"
    end

    test "applies blink effect" do
      result = Effects.apply_effect("text", :blink)
      assert result == "\e[5mtext\e[0m"
    end

    test "applies reverse effect" do
      result = Effects.apply_effect("text", :reverse)
      assert result == "\e[7mtext\e[0m"
    end

    test "applies hidden effect" do
      result = Effects.apply_effect("text", :hidden)
      assert result == "\e[8mtext\e[0m"
    end

    test "applies strikethrough effect" do
      result = Effects.apply_effect("text", :strikethrough)
      assert result == "\e[9mtext\e[0m"
    end

    test "returns original text for invalid effect" do
      result = Effects.apply_effect("text", :invalid)
      assert result == "text"
    end

    test "handles empty text" do
      result = Effects.apply_effect("", :bold)
      assert result == "\e[1m\e[0m"
    end
  end

  describe "apply_multiple_effects/2" do
    test "applies multiple effects in sequence" do
      result = Effects.apply_multiple_effects("text", [:bold, :underline])
      assert result == "\e[1m\e[4mtext\e[0m"
    end

    test "applies single effect in list" do
      result = Effects.apply_multiple_effects("text", [:bold])
      assert result == "\e[1mtext\e[0m"
    end

    test "ignores invalid effects" do
      result = Effects.apply_multiple_effects("text", [:bold, :invalid, :italic])
      assert result == "\e[1m\e[3mtext\e[0m"
    end

    test "returns original text for empty effects list" do
      result = Effects.apply_multiple_effects("text", [])
      assert result == "text"
    end

    test "returns original text for all invalid effects" do
      result = Effects.apply_multiple_effects("text", [:invalid1, :invalid2])
      assert result == "text"
    end

    test "combines three effects correctly" do
      result = Effects.apply_multiple_effects("text", [:bold, :italic, :underline])
      assert result == "\e[1m\e[3m\e[4mtext\e[0m"
    end
  end

  describe "apply_effects/2 with options" do
    test "applies no effects when opts is empty" do
      result = Effects.apply_effects("text", [])
      assert result == "text"
    end

    test "applies no effects when all are false" do
      opts = [
        bold: false,
        italic: false,
        underline: false,
        dim: false,
        blink: false,
        reverse: false,
        hidden: false,
        strikethrough: false
      ]

      result = Effects.apply_effects("text", opts)
      assert result == "text"
    end

    test "applies all effects when all are true" do
      opts = [
        bold: true,
        italic: true,
        underline: true,
        dim: true,
        blink: true,
        reverse: true,
        hidden: true,
        strikethrough: true
      ]

      result = Effects.apply_effects("text", opts)
      assert String.contains?(result, "text")
      assert String.contains?(result, "\e[1m")
      assert String.contains?(result, "\e[3m")
      assert String.contains?(result, "\e[4m")
      assert String.ends_with?(result, "\e[0m")
    end
  end

  describe "apply_effects/2 with keyword list" do
    test "applies effects from keyword list" do
      result = Effects.apply_effects("text", bold: true, italic: true)
      assert result == "\e[1m\e[3mtext\e[0m"
    end

    test "ignores false values in keyword list" do
      result = Effects.apply_effects("text", bold: true, italic: false, underline: true)
      assert result == "\e[1m\e[4mtext\e[0m"
    end

    test "ignores non-effect keys" do
      result = Effects.apply_effects("text", bold: true, color: :red, italic: true)
      assert result == "\e[1m\e[3mtext\e[0m"
    end

    test "returns original text for empty keyword list" do
      result = Effects.apply_effects("text", [])
      assert result == "text"
    end
  end

  describe "available_effects/0" do
    test "returns list of all available effects" do
      effects = Effects.available_effects()
      assert is_list(effects)
      assert :bold in effects
      assert :italic in effects
      assert :underline in effects
      assert :dim in effects
      assert :blink in effects
      assert :reverse in effects
      assert :hidden in effects
      assert :strikethrough in effects
      assert length(effects) == 8
    end
  end

  describe "valid_effect?/1" do
    test "returns true for valid effects" do
      assert Effects.valid_effect?(:bold)
      assert Effects.valid_effect?(:italic)
      assert Effects.valid_effect?(:underline)
      assert Effects.valid_effect?(:dim)
      assert Effects.valid_effect?(:blink)
      assert Effects.valid_effect?(:reverse)
      assert Effects.valid_effect?(:hidden)
      assert Effects.valid_effect?(:strikethrough)
    end

    test "returns false for invalid effects" do
      refute Effects.valid_effect?(:invalid)
      refute Effects.valid_effect?(:non_existent)
      refute Effects.valid_effect?(:random)
    end

    test "returns false for non-atom input" do
      refute Effects.valid_effect?("bold")
      refute Effects.valid_effect?(123)
      refute Effects.valid_effect?(nil)
    end
  end

  describe "apply_effect_info/2" do
    test "applies single effect from EffectInfo" do
      effect_info = %EffectInfo{bold: true}
      result = Effects.apply_effect_info("text", effect_info)
      assert result == "\e[1mtext\e[0m"
    end

    test "applies multiple effects from EffectInfo" do
      effect_info = %EffectInfo{bold: true, italic: true, underline: true}
      result = Effects.apply_effect_info("text", effect_info)

      # Verificar que los códigos estén presentes (orden puede variar)
      # bold
      assert String.contains?(result, "\e[1m")
      # italic
      assert String.contains?(result, "\e[3m")
      # underline
      assert String.contains?(result, "\e[4m")
      assert String.ends_with?(result, "text\e[0m")
      assert String.starts_with?(result, "\e[")
    end

    test "applies no effects from EffectInfo with all false" do
      effect_info = %EffectInfo{}
      result = Effects.apply_effect_info("text", effect_info)
      assert result == "text"
    end

    test "ignores unsupported effects" do
      # Test with EffectInfo that has all supported effects
      effect_info = %EffectInfo{
        bold: true,
        dim: false,
        italic: true,
        underline: false,
        blink: false,
        reverse: false,
        hidden: false,
        strikethrough: false
      }

      result = Effects.apply_effect_info("text", effect_info)

      # Verificar que los códigos correctos estén presentes
      # bold
      assert String.contains?(result, "\e[1m")
      # italic
      assert String.contains?(result, "\e[3m")
      assert String.ends_with?(result, "text\e[0m")
      # Verificar que códigos no deseados NO estén presentes
      # dim
      refute String.contains?(result, "\e[2m")
      # underline
      refute String.contains?(result, "\e[4m")
    end

    test "handles all effects enabled" do
      effect_info = %EffectInfo{
        bold: true,
        dim: true,
        italic: true,
        underline: true,
        blink: true,
        reverse: true,
        hidden: true,
        strikethrough: true
      }

      result = Effects.apply_effect_info("text", effect_info)

      # Verify that all effect codes are present
      # bold
      assert String.contains?(result, "\e[1m")
      # dim
      assert String.contains?(result, "\e[2m")
      # italic
      assert String.contains?(result, "\e[3m")
      # underline
      assert String.contains?(result, "\e[4m")
      # blink
      assert String.contains?(result, "\e[5m")
      # reverse
      assert String.contains?(result, "\e[7m")
      # hidden
      assert String.contains?(result, "\e[8m")
      # strikethrough
      assert String.contains?(result, "\e[9m")
      assert String.ends_with?(result, "text\e[0m")
    end
  end

  describe "apply_chunk_effects/1" do
    test "applies effects to ChunkText with effects" do
      effect_info = %EffectInfo{bold: true, italic: true}
      chunk = %ChunkText{text: "test text", effects: effect_info}
      result = Effects.apply_chunk_effects(chunk)

      # Verificar efectos aplicados (orden puede variar)
      # bold
      assert String.contains?(result.text, "\e[1m")
      # italic
      assert String.contains?(result.text, "\e[3m")
      assert String.ends_with?(result.text, "test text\e[0m")
      # Original effects preserved
      assert result.effects == effect_info
    end

    test "returns unchanged ChunkText when no effects" do
      chunk = %ChunkText{text: "test text", effects: nil}
      result = Effects.apply_chunk_effects(chunk)

      assert result.text == "test text"
      assert result.effects == nil
    end

    test "handles ChunkText with empty EffectInfo" do
      effect_info = %EffectInfo{}
      chunk = %ChunkText{text: "test text", effects: effect_info}
      result = Effects.apply_chunk_effects(chunk)

      # No effects applied
      assert result.text == "test text"
      assert result.effects == effect_info
    end

    test "preserves other ChunkText fields" do
      effect_info = %EffectInfo{bold: true}
      color_info = Aurora.Color.get_color_info(:primary)
      chunk = %ChunkText{text: "test", color: color_info, effects: effect_info}
      result = Effects.apply_chunk_effects(chunk)

      # Color preserved
      assert result.color == color_info
      # Effects preserved
      assert result.effects == effect_info
      # Bold effect applied
      assert String.starts_with?(result.text, "\e[1m")
    end

    test "handles empty text with effects" do
      effect_info = %EffectInfo{underline: true}
      chunk = %ChunkText{text: "", effects: effect_info}
      result = Effects.apply_chunk_effects(chunk)

      assert result.text == "\e[4m\e[0m"
    end
  end
end
