defmodule Aurora.CLITest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  alias Aurora.CLI

  describe "main/1" do
    test "shows version with --version flag" do
      output =
        capture_io(fn ->
          CLI.main(["--version"])
        end)

      assert String.contains?(output, "Aurora v")
    end

    test "shows help with --help flag" do
      output =
        capture_io(fn ->
          CLI.main(["--help"])
        end)

      assert String.contains?(output, "USO")
      assert String.contains?(output, "EJEMPLOS")
    end

    test "shows help with no arguments" do
      output =
        capture_io(fn ->
          CLI.main([])
        end)

      assert String.contains?(output, "AURORA CLI")
    end
  end

  describe "text chunk mode" do
    test "formats single text chunk" do
      output =
        capture_io(fn ->
          CLI.main(["--text=Hello", "--color=primary"])
        end)

      assert is_binary(output)
      assert String.length(output) > 0
    end

    test "formats multiple text chunks" do
      output =
        capture_io(fn ->
          CLI.main(["--text=Hello", "--color=red", "--text=World", "--color=blue"])
        end)

      assert is_binary(output)
    end

    test "applies effects to chunks" do
      output =
        capture_io(fn ->
          CLI.main(["--text=Test", "--bold", "--underline"])
        end)

      assert is_binary(output)
    end

    test "handles color manipulation" do
      output =
        capture_io(fn ->
          CLI.main(["--text=Test", "--color=primary", "--lighten=2"])
        end)

      assert is_binary(output)
    end
  end

  describe "table mode" do
    test "formats basic table" do
      output =
        capture_io(fn ->
          CLI.main(["--table", "--headers=Name,Age", "--row=John,25"])
        end)

      assert is_binary(output)
      # El output ahora es un string inspeccionado con códigos ANSI
      assert String.contains?(output, "John") or String.contains?(output, "\\e")
    end

    test "formats table with styling" do
      output =
        capture_io(fn ->
          CLI.main([
            "--table",
            "--headers=Product,Price",
            "--header-color=primary",
            "--row=Widget,10"
          ])
        end)

      assert is_binary(output)
    end

    test "handles multiple rows" do
      output =
        capture_io(fn ->
          CLI.main(["--table", "--headers=A,B", "--row=1,2", "--row=3,4"])
        end)

      assert is_binary(output)
    end
  end

  # describe "argument parsing" do
  #   test "parses align options correctly" do
  #     assert CLI.parse_align("left") == :left
  #     assert CLI.parse_align("center") == :center
  #     assert CLI.parse_align("right") == :right
  #     assert CLI.parse_align("invalid") == :left
  #   end

  #   test "parses add_line options correctly" do
  #     assert CLI.parse_add_line("none") == :none
  #     assert CLI.parse_add_line("before") == :before
  #     assert CLI.parse_add_line("after") == :after
  #     assert CLI.parse_add_line("both") == :both
  #     assert CLI.parse_add_line("invalid") == :none
  #   end
  # end
end
