defmodule Lumines.Engine.SweepTest do
  use ExUnit.Case, async: true

  alias Lumines.Engine.{Board, Sweep}

  describe "new/0" do
    test "starts at column 0" do
      sweep = Sweep.new()
      assert sweep.col == 0
    end
  end

  describe "advance/1" do
    test "moves sweep line one column to the right" do
      sweep = Sweep.new()
      sweep = Sweep.advance(sweep)
      assert sweep.col == 1
    end

    test "wraps around at column 16" do
      sweep = %Sweep{col: 15}
      sweep = Sweep.advance(sweep)
      assert sweep.col == 0
    end
  end

  describe "clear_column/2" do
    test "clears marked cells in the sweep column" do
      board =
        Board.new()
        |> Board.put(3, 8, :marked_a)
        |> Board.put(3, 9, :marked_b)
        |> Board.put(3, 7, :a)

      result = Sweep.clear_column(board, 3)
      assert Board.get(result, 3, 8) == nil
      assert Board.get(result, 3, 9) == nil
      assert Board.get(result, 3, 7) == :a
    end

    test "does not clear unmarked cells" do
      board =
        Board.new()
        |> Board.put(5, 9, :a)
        |> Board.put(5, 8, :b)

      result = Sweep.clear_column(board, 5)
      assert Board.get(result, 5, 9) == :a
      assert Board.get(result, 5, 8) == :b
    end
  end

  describe "process_tick/2" do
    test "advances sweep and clears marked cells at new position" do
      board =
        Board.new()
        |> Board.put(1, 9, :marked_a)
        |> Board.put(1, 8, :a)

      sweep = Sweep.new()
      {new_board, new_sweep} = Sweep.process_tick(board, sweep)
      assert new_sweep.col == 1
      assert Board.get(new_board, 1, 9) == nil
      assert Board.get(new_board, 1, 8) == :a
    end
  end
end
