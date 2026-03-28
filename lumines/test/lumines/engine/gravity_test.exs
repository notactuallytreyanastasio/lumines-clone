defmodule Lumines.Engine.GravityTest do
  use ExUnit.Case, async: true

  alias Lumines.Engine.{Board, Gravity}

  describe "apply/1" do
    test "cells fall down to fill gaps" do
      board =
        Board.new()
        |> Board.put(3, 5, :a)
        # gap at row 6-8
        |> Board.put(3, 9, :b)

      result = Gravity.apply(board)
      # :a should fall to row 8 (above :b at row 9)
      assert Board.get(result, 3, 8) == :a
      assert Board.get(result, 3, 9) == :b
      assert Board.get(result, 3, 5) == nil
    end

    test "multiple cells stack correctly" do
      board =
        Board.new()
        |> Board.put(0, 0, :a)
        |> Board.put(0, 2, :b)
        |> Board.put(0, 5, :a)

      result = Gravity.apply(board)
      assert Board.get(result, 0, 7) == :a
      assert Board.get(result, 0, 8) == :b
      assert Board.get(result, 0, 9) == :a
    end

    test "already settled board is unchanged" do
      board =
        Board.new()
        |> Board.put(5, 8, :a)
        |> Board.put(5, 9, :b)

      result = Gravity.apply(board)
      assert Board.get(result, 5, 8) == :a
      assert Board.get(result, 5, 9) == :b
    end

    test "empty board is unchanged" do
      board = Board.new()
      assert Gravity.apply(board) == board
    end

    test "handles multiple columns independently" do
      board =
        Board.new()
        |> Board.put(0, 0, :a)
        |> Board.put(1, 3, :b)

      result = Gravity.apply(board)
      assert Board.get(result, 0, 9) == :a
      assert Board.get(result, 1, 9) == :b
    end

    test "marked cells also fall" do
      board =
        Board.new()
        |> Board.put(2, 3, :marked_a)

      result = Gravity.apply(board)
      assert Board.get(result, 2, 9) == :marked_a
      assert Board.get(result, 2, 3) == nil
    end
  end
end
