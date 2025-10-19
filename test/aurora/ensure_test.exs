defmodule Aurora.EnsureTest do
  use ExUnit.Case
  doctest Aurora.Ensure

  alias Aurora.Ensure
  alias Aurora.Structs.{ChunkText, ColorInfo, EffectInfo, FormatInfo}

  describe "type/2" do
    test "ensures native types with safe defaults" do
      assert Ensure.type(nil, :string) == ""
      assert Ensure.type("invalid", :integer) == 0
      assert Ensure.type(nil, :float) == 0.0
      assert Ensure.type("invalid", :boolean) == false
      assert Ensure.type(nil, :atom) == :ok
      assert Ensure.type(nil, :list) == []
      assert Ensure.type(nil, :map) == %{}
    end

    test "ensures Aurora structs with safe defaults" do
      assert %ChunkText{text: ""} = Ensure.type(nil, ChunkText)
      assert %ColorInfo{} = Ensure.type(nil, ColorInfo)
      assert %FormatInfo{chunks: []} = Ensure.type(nil, FormatInfo)
      assert %EffectInfo{} = Ensure.type(nil, EffectInfo)
    end

    test "handles external types with defaults" do
      default_date = ~D[2000-01-01]
      assert Ensure.type(nil, {:external, Date, default_date}) == default_date
    end
  end

  describe "specific type functions" do
    test "string/1" do
      assert Ensure.string(nil) == ""
      assert Ensure.string(123) == "123"
      assert Ensure.string(:atom) == "atom"
    end

    test "integer/1" do
      assert Ensure.integer(nil) == 0
      assert Ensure.integer("123") == 123
      assert Ensure.integer("invalid") == 0
    end

    test "boolean/1" do
      assert Ensure.boolean(nil) == false
      assert Ensure.boolean("true") == true
      assert Ensure.boolean("false") == false
      assert Ensure.boolean("anything") == false
    end

    test "list/1" do
      assert Ensure.list(nil) == []
      assert Ensure.list("single") == ["single"]
      assert Ensure.list([1, 2, 3]) == [1, 2, 3]
    end

    test "map/1" do
      assert Ensure.map(nil) == %{}
      assert Ensure.map(a: 1, b: 2) == %{a: 1, b: 2}
      assert Ensure.map("value") == %{value: "value"}
    end
  end

  describe "normalized/3" do
    test "ensures normalized values" do
      assert Ensure.normalized("  HELLO  ", :string, :lower) == "hello"
      assert Ensure.normalized("café", :string, :upper) == "CAFE"
    end
  end

  describe "list_of/2" do
    test "converts value to list of specified type" do
      assert Ensure.list_of(["1", "2", "3"], :integer) == [1, 2, 3]
      assert Ensure.list_of("hello", :string) == ["hello"]
    end
  end

  describe "utility functions" do
    test "deep_merge/2" do
      map1 = %{a: %{x: 1, y: 2}, b: 3}
      map2 = %{a: %{y: 20, z: 30}, c: 4}
      result = %{a: %{x: 1, y: 20, z: 30}, b: 3, c: 4}

      assert Ensure.deep_merge(map1, map2) == result
    end

    test "clean_nil_values/1" do
      map = %{a: 1, b: nil, c: 3}
      result = %{a: 1, c: 3}

      assert Ensure.clean_nil_values(map) == result
    end
  end
end
