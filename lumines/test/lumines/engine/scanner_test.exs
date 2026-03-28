defmodule Lumines.Engine.ScannerTest do
  use ExUnit.Case, async: true

  alias Lumines.Engine.{Board, Scanner}

  describe "scan/1" do
    test "finds a single 2x2 square of color :a" do
      board =
        Board.new()
        |> Board.put(0, 8, :a)
        |> Board.put(1, 8, :a)
        |> Board.put(0, 9, :a)
        |> Board.put(1, 9, :a)

      result = Scanner.scan(board)
      assert Board.get(result, 0, 8) == :marked_a
      assert Board.get(result, 1, 8) == :marked_a
      assert Board.get(result, 0, 9) == :marked_a
      assert Board.get(result, 1, 9) == :marked_a
    end

    test "finds a single 2x2 square of color :b" do
      board =
        Board.new()
        |> Board.put(3, 4, :b)
        |> Board.put(4, 4, :b)
        |> Board.put(3, 5, :b)
        |> Board.put(4, 5, :b)

      result = Scanner.scan(board)
      assert Board.get(result, 3, 4) == :marked_b
      assert Board.get(result, 4, 4) == :marked_b
      assert Board.get(result, 3, 5) == :marked_b
      assert Board.get(result, 4, 5) == :marked_b
    end

    test "finds overlapping squares in 2x3 area" do
      board =
        Board.new()
        |> Board.put(0, 7, :a)
        |> Board.put(1, 7, :a)
        |> Board.put(0, 8, :a)
        |> Board.put(1, 8, :a)
        |> Board.put(0, 9, :a)
        |> Board.put(1, 9, :a)

      result = Scanner.scan(board)
      # All 6 cells should be marked
      for col <- 0..1, row <- 7..9 do
        assert Board.get(result, col, row) == :marked_a
      end
    end

    test "does not mark incomplete squares" do
      board =
        Board.new()
        |> Board.put(0, 8, :a)
        |> Board.put(1, 8, :a)
        |> Board.put(0, 9, :a)
        |> Board.put(1, 9, :b)

      result = Scanner.scan(board)
      # No square formed - all stay unmarked
      assert Board.get(result, 0, 8) == :a
      assert Board.get(result, 1, 8) == :a
      assert Board.get(result, 0, 9) == :a
      assert Board.get(result, 1, 9) == :b
    end

    test "returns count of squares found" do
      board =
        Board.new()
        |> Board.put(0, 8, :a)
        |> Board.put(1, 8, :a)
        |> Board.put(0, 9, :a)
        |> Board.put(1, 9, :a)

      {_board, count} = Scanner.scan_with_count(board)
      assert count == 1
    end

    test "counts overlapping squares separately" do
      board =
        Board.new()
        |> Board.put(0, 7, :a)
        |> Board.put(1, 7, :a)
        |> Board.put(0, 8, :a)
        |> Board.put(1, 8, :a)
        |> Board.put(0, 9, :a)
        |> Board.put(1, 9, :a)

      {_board, count} = Scanner.scan_with_count(board)
      assert count == 2
    end

    test "empty board has no squares" do
      board = Board.new()
      result = Scanner.scan(board)
      assert result == board
    end

    test "does not re-mark already marked cells unnecessarily" do
      board =
        Board.new()
        |> Board.put(0, 8, :marked_a)
        |> Board.put(1, 8, :marked_a)
        |> Board.put(0, 9, :marked_a)
        |> Board.put(1, 9, :marked_a)

      # Already marked cells should not form new squares
      {_result, count} = Scanner.scan_with_count(board)
      assert count == 0
    end
  end
end
