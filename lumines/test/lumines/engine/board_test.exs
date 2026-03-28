defmodule Lumines.Engine.BoardTest do
  use ExUnit.Case, async: true

  alias Lumines.Engine.Board

  describe "new/0" do
    test "creates a 16x10 grid of nil cells" do
      board = Board.new()
      assert Board.cols() == 16
      assert Board.rows() == 10

      for col <- 0..15, row <- 0..9 do
        assert Board.get(board, col, row) == nil
      end
    end
  end

  describe "get/3 and put/4" do
    test "sets and gets a cell value" do
      board = Board.new()
      board = Board.put(board, 3, 5, :a)
      assert Board.get(board, 3, 5) == :a
    end

    test "returns nil for out-of-bounds" do
      board = Board.new()
      assert Board.get(board, -1, 0) == nil
      assert Board.get(board, 16, 0) == nil
      assert Board.get(board, 0, -1) == nil
      assert Board.get(board, 0, 10) == nil
    end
  end

  describe "in_bounds?/2" do
    test "returns true for valid coordinates" do
      assert Board.in_bounds?(0, 0)
      assert Board.in_bounds?(15, 9)
      assert Board.in_bounds?(7, 5)
    end

    test "returns false for invalid coordinates" do
      refute Board.in_bounds?(-1, 0)
      refute Board.in_bounds?(16, 0)
      refute Board.in_bounds?(0, 10)
    end
  end

  describe "occupied?/3" do
    test "returns false for empty cells" do
      board = Board.new()
      refute Board.occupied?(board, 0, 0)
    end

    test "returns true for filled cells" do
      board = Board.new() |> Board.put(0, 0, :a)
      assert Board.occupied?(board, 0, 0)
    end

    test "returns false for marked cells (they are still present)" do
      board = Board.new() |> Board.put(0, 0, :marked_a)
      assert Board.occupied?(board, 0, 0)
    end
  end

  describe "clear_marked/1" do
    test "removes all marked cells in given column range" do
      board =
        Board.new()
        |> Board.put(0, 9, :marked_a)
        |> Board.put(1, 9, :marked_b)
        |> Board.put(2, 9, :a)

      board = Board.clear_marked(board, 0..1)
      assert Board.get(board, 0, 9) == nil
      assert Board.get(board, 1, 9) == nil
      assert Board.get(board, 2, 9) == :a
    end
  end
end
