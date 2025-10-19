defmodule Aurora.EffectsTest do
  use ExUnit.Case
  doctest Aurora.Effects

  alias Aurora.Effects
  alias Aurora.Structs.{ChunkText, EffectInfo}

  describe "apply_effect/2" do
    test "applies bold effect" do
      result = Effects.apply_effect("Hello", :bold)
      assert String.contains?(result, "\e[1m")
      assert String.ends_with?(result, "\e[0m")
      assert String.contains?(result, "Hello")
    end

    test "applies underline effect" do
      result = Effects.apply_effect("World", :underline)
      assert String.contains?(result, "\e[4m")
      assert String.ends_with?(result, "\e[0m")
    end

    test "returns original text for invalid effect" do
      result = Effects.apply_effect("Text", :invalid_effect)
      assert result == "Text"
    end

    test "handles nil and non-string input" do
      assert Effects.apply_effect(nil, :bold) == "\e[1m\e[0m"
      assert Effects.apply_effect(123, :bold) == "\e[1m123\e[0m"
    end
  end

  describe "apply_multiple_effects/2" do
    test "applies multiple effects" do
      result = Effects.apply_multiple_effects("Text", [:bold, :italic, :underline])
      assert String.contains?(result, "\e[1m")
      assert String.contains?(result, "\e[3m")
      assert String.contains?(result, "\e[4m")
      assert String.ends_with?(result, "\e[0m")
    end

    test "filters out invalid effects" do
      result = Effects.apply_multiple_effects("Text", [:bold, :invalid, :italic])
      assert String.contains?(result, "\e[1m")
      assert String.contains?(result, "\e[3m")
      refute String.contains?(result, "invalid")
    end

    test "returns original text for empty effects list" do
      result = Effects.apply_multiple_effects("Text", [])
      assert result == "Text"
    end
  end

  describe "apply_effects/2" do
    test "applies effects from keyword list" do
      result = Effects.apply_effects("Text", bold: true, italic: true, underline: false)
      assert String.contains?(result, "\e[1m")
      assert String.contains?(result, "\e[3m")
      # underline was false
      refute String.contains?(result, "\e[4m")
    end

    test "handles empty options" do
      result = Effects.apply_effects("Text", [])
      assert result == "Text"
    end

    test "filters invalid effects in options" do
      result = Effects.apply_effects("Text", bold: true, invalid: true, italic: true)
      assert String.contains?(result, "\e[1m")
      assert String.contains?(result, "\e[3m")
    end
  end

  describe "apply_effect_info/2" do
    test "applies effects from EffectInfo struct" do
      effect_info = %EffectInfo{bold: true, italic: true}
      result = Effects.apply_effect_info("Text", effect_info)

      assert String.contains?(result, "\e[1m")
      assert String.contains?(result, "\e[3m")
      assert String.ends_with?(result, "\e[0m")
    end

    test "handles EffectInfo with no effects enabled" do
      effect_info = %EffectInfo{}
      result = Effects.apply_effect_info("Text", effect_info)
      assert result == "Text"
    end

    test "handles nil EffectInfo" do
      result = Effects.apply_effect_info("Text", nil)
      assert result == "Text"
    end

    test "applies all available effects" do
      effect_info = %EffectInfo{
        bold: true,
        dim: true,
        italic: true,
        underline: true,
        blink: true,
        reverse: true,
        hidden: true,
        strikethrough: true,
        link: true
      }

      result = Effects.apply_effect_info("Text", effect_info)

      # Should contain multiple ANSI codes
      assert String.match?(result, ~r/\e\[1m.*\e\[0m/)
      assert String.length(result) > String.length("Text") + 10
    end
  end

  describe "apply_chunk_effects/1" do
    test "applies effects to ChunkText with effects" do
      effect_info = %EffectInfo{bold: true, italic: true}
      chunk = %ChunkText{text: "Hello", effects: effect_info}

      result = Effects.apply_chunk_effects(chunk)

      assert %ChunkText{} = result
      assert String.contains?(result.text, "\e[1m")
      assert String.contains?(result.text, "\e[3m")
    end

    test "returns unchanged ChunkText when no effects" do
      chunk = %ChunkText{text: "Hello", effects: nil}

      result = Effects.apply_chunk_effects(chunk)

      assert result == chunk
    end

    test "handles non-ChunkText input" do
      result = Effects.apply_chunk_effects("Hello")
      assert %ChunkText{} = result
      assert result.text == "Hello"
    end
  end

  describe "apply_chunks_effects/1" do
    test "applies effects to list of chunks" do
      effect_info = %EffectInfo{bold: true}

      chunks = [
        %ChunkText{text: "One", effects: effect_info},
        %ChunkText{text: "Two", effects: nil},
        %ChunkText{text: "Three", effects: effect_info}
      ]

      result = Effects.apply_chunks_effects(chunks)

      assert is_list(result)
      assert length(result) == 3
      assert String.contains?(hd(result).text, "\e[1m")
      # No effects
      assert Enum.at(result, 1).text == "Two"
      assert String.contains?(Enum.at(result, 2).text, "\e[1m")
    end
  end

  describe "utility functions" do
    test "available_effects/0 returns all effects" do
      effects = Effects.available_effects()

      assert is_list(effects)
      assert length(effects) > 0
      assert :bold in effects
      assert :italic in effects
      assert :underline in effects
    end

    test "valid_effect?/1 checks effect validity" do
      assert Effects.valid_effect?(:bold) == true
      assert Effects.valid_effect?(:underline) == true
      assert Effects.valid_effect?(:invalid) == false
    end

    test "get_effect_code/1 returns ANSI codes" do
      assert Effects.get_effect_code(:bold) == "\e[1m"
      assert Effects.get_effect_code(:underline) == "\e[4m"
      assert Effects.get_effect_code(:invalid) == nil
    end

    test "remove_effects/1 cleans ANSI codes" do
      ansi_text = "\e[1mHello\e[0m \e[3mWorld\e[0m"
      clean_text = Effects.remove_effects(ansi_text)

      assert clean_text == "Hello World"
    end

    test "remove_effects/1 handles text without ANSI" do
      assert Effects.remove_effects("Normal text") == "Normal text"
      assert Effects.remove_effects("") == ""
    end
  end

  describe "edge cases" do
    test "handles empty strings" do
      assert Effects.apply_effect("", :bold) == "\e[1m\e[0m"
      assert Effects.apply_multiple_effects("", [:bold, :italic]) == "\e[1m\e[3m\e[0m"
    end

    test "handles strings with special characters" do
      text = "Text with\nnewline\tand\ttabs"
      result = Effects.apply_effect(text, :bold)

      assert String.contains?(result, "\e[1m")
      assert String.contains?(result, "newline")
      assert String.ends_with?(result, "\e[0m")
    end

    test "link effect uses same code as underline" do
      assert Effects.get_effect_code(:link) == Effects.get_effect_code(:underline)
    end
  end
end
