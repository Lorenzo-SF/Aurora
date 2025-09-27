defmodule Aurora.EnsureTest do
  use ExUnit.Case
  alias Aurora.Ensure
  alias Aurora.Structs.{ChunkText, ColorInfo}

  describe "list/1" do
    test "returns empty list for nil" do
      assert Ensure.list(nil) == []
    end

    test "returns same list for list input" do
      list = [1, 2, 3]
      assert Ensure.list(list) == list
    end

    test "wraps single value in list" do
      assert Ensure.list("single") == ["single"]
      assert Ensure.list(42) == [42]
    end
  end

  describe "tuple/2" do
    test "returns tuple as-is" do
      tuple = {:ok, "data"}
      assert Ensure.tuple(tuple) == tuple
    end

    test "returns default for nil" do
      assert Ensure.tuple(nil) == {}
      assert Ensure.tuple(nil, {:default}) == {:default}
    end

    test "creates tuple from other values" do
      assert Ensure.tuple("text") == {"text", :no_data}
      assert Ensure.tuple([1, 2]) == {[1, 2], :no_data}
    end
  end

  describe "map/1" do
    test "returns empty map for nil" do
      assert Ensure.map(nil) == %{}
    end

    test "returns map as-is" do
      map = %{a: 1}
      assert Ensure.map(map) == map
    end

    test "converts list to map" do
      assert Ensure.map([{:a, 1}, {:b, 2}]) == %{a: 1, b: 2}
    end

    test "wraps value in map" do
      assert Ensure.map("text") == %{value: "text"}
    end
  end

  describe "integer/1" do
    test "returns integer as-is" do
      assert Ensure.integer(42) == 42
    end

    test "parses valid string" do
      assert Ensure.integer("123") == 123
    end

    test "returns 0 for invalid string" do
      assert Ensure.integer("invalid") == 0
      assert Ensure.integer("123abc") == 0
    end

    test "returns 0 for other types" do
      assert Ensure.integer(nil) == 0
      assert Ensure.integer([]) == 0
    end
  end

  describe "float/1" do
    test "returns float as-is" do
      assert Ensure.float(3.14) == 3.14
    end

    test "converts integer to float" do
      assert Ensure.float(42) == 42.0
    end

    test "parses valid string" do
      assert Ensure.float("3.14") == 3.14
    end

    test "returns 0.0 for invalid input" do
      assert Ensure.float("invalid") == 0.0
      assert Ensure.float(nil) == 0.0
    end
  end

  describe "atom/1" do
    test "returns atom as-is" do
      assert Ensure.atom(:hello) == :hello
    end

    test "converts string to atom" do
      assert Ensure.atom("world") == :world
    end

    test "returns :ok for other types" do
      assert Ensure.atom(123) == :ok
      assert Ensure.atom(nil) == nil  # nil is already an atom
    end
  end

  describe "string/1" do
    test "returns empty string for nil" do
      assert Ensure.string(nil) == ""
    end

    test "returns string as-is" do
      assert Ensure.string("hello") == "hello"
    end

    test "converts various types to string" do
      assert Ensure.string(123) == "123"
      assert Ensure.string(:atom) == "atom"
      assert Ensure.string(3.14) == "3.14"
    end

    test "inspects complex types" do
      assert Ensure.string([1, 2, 3]) == "[1, 2, 3]"
    end
  end

  describe "boolean/1" do
    test "returns boolean as-is" do
      assert Ensure.boolean(true) == true
      assert Ensure.boolean(false) == false
    end

    test "converts string booleans" do
      assert Ensure.boolean("true") == true
      assert Ensure.boolean("false") == false
    end

    test "returns false for other values" do
      assert Ensure.boolean("anything") == false
      assert Ensure.boolean(123) == false
      assert Ensure.boolean(nil) == false
    end
  end

  describe "chunk_text/1" do
    test "returns ChunkText as-is" do
      chunk = %ChunkText{text: "hello"}
      assert Ensure.chunk_text(chunk) == chunk
    end

    test "converts string to ChunkText" do
      result = Ensure.chunk_text("hello")
      assert %ChunkText{text: "hello"} = result
    end

    test "converts tuple to ChunkText" do
      result = Ensure.chunk_text({"error", "red"})
      assert %ChunkText{text: "error"} = result
    end

    test "converts ColorInfo to ChunkText" do
      color_info = %ColorInfo{name: :primary}
      result = Ensure.chunk_text(color_info)
      assert %ChunkText{text: "primary", color: ^color_info} = result
    end

    test "returns empty chunk for invalid input" do
      assert Ensure.chunk_text(nil) == %ChunkText{text: ""}
    end
  end

  describe "struct/2" do
    test "returns struct if module matches" do
      color = %ColorInfo{name: :primary}
      assert Ensure.struct(color, ColorInfo) == color
    end

    test "returns nil if module doesn't match" do
      assert Ensure.struct("not_struct", ColorInfo) == nil
    end
  end

  describe "deep_merge/2" do
    test "merges nested maps" do
      map1 = %{a: %{x: 1, y: 2}, b: 3}
      map2 = %{a: %{y: 20, z: 30}, c: 4}
      expected = %{a: %{x: 1, y: 20, z: 30}, b: 3, c: 4}

      assert Ensure.deep_merge(map1, map2) == expected
    end
  end

  describe "clean_nil_values/1" do
    test "removes nil values from map" do
      map = %{a: 1, b: nil, c: 3}
      assert Ensure.clean_nil_values(map) == %{a: 1, c: 3}
    end
  end

  describe "cast/2" do
    test "casts to different types" do
      assert Ensure.cast("123", :integer) == 123
      assert Ensure.cast(nil, :string) == ""
      assert Ensure.cast("hello", :atom) == :hello
      assert Ensure.cast(42, :float) == 42.0
      assert Ensure.cast("true", :boolean) == true
      assert Ensure.cast("single", :list) == ["single"]
      assert Ensure.cast([{:a, 1}], :map) == %{a: 1}
    end

    test "returns value for unknown type" do
      assert Ensure.cast("test", :unknown) == "test"
    end
  end

  describe "list_of/2" do
    test "converts to list and applies type function" do
      assert Ensure.list_of(["1", "2", "3"], :integer) == [1, 2, 3]
      assert Ensure.list_of("hello", :string) == ["hello"]
      assert Ensure.list_of([1, 2.5, "3"], :float) == [1.0, 2.5, 3.0]
    end
  end
end
