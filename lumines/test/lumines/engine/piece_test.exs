defmodule Lumines.Engine.PieceTest do
  use ExUnit.Case, async: true

  alias Lumines.Engine.Piece
  alias Lumines.Engine.Board

  describe "new/1" do
    test "creates a 2x2 piece with given colors" do
      piece = Piece.new([:a, :b, :a, :b])
      # colors stored as {top_left, top_right, bottom_left, bottom_right}
      assert piece.colors == {:a, :b, :a, :b}
    end
  end

  describe "spawn/1" do
    test "places piece at top-center of board" do
      piece = Piece.new([:a, :b, :a, :b])
      spawned = Piece.spawn(piece)
      # top-center: col 7, row 0 (for 16-wide board, center is cols 7-8)
      assert spawned.col == 7
      assert spawned.row == 0
    end
  end

  describe "rotate/1" do
    test "rotates clockwise" do
      # TL TR    BL TL
      # BL BR -> BR TR
      piece = Piece.new([:a, :b, :a, :b]) |> Piece.spawn()
      rotated = Piece.rotate(piece)
      assert rotated.colors == {:a, :a, :b, :b}
    end

    test "four rotations return to original" do
      piece = Piece.new([:a, :b, :b, :a]) |> Piece.spawn()
      result = piece |> Piece.rotate() |> Piece.rotate() |> Piece.rotate() |> Piece.rotate()
      assert result.colors == piece.colors
    end
  end

  describe "move_left/2" do
    test "decrements column" do
      piece = Piece.new([:a, :a, :a, :a]) |> Piece.spawn()
      board = Board.new()
      {:ok, moved} = Piece.move_left(piece, board)
      assert moved.col == piece.col - 1
    end

    test "cannot move past left wall" do
      piece = %{Piece.new([:a, :a, :a, :a]) |> Piece.spawn() | col: 0}
      board = Board.new()
      assert :error = Piece.move_left(piece, board)
    end

    test "cannot move into occupied cell" do
      piece = Piece.new([:a, :a, :a, :a]) |> Piece.spawn()
      board = Board.new() |> Board.put(piece.col - 1, piece.row, :b)
      assert :error = Piece.move_left(piece, board)
    end
  end

  describe "move_right/2" do
    test "increments column" do
      piece = Piece.new([:a, :a, :a, :a]) |> Piece.spawn()
      board = Board.new()
      {:ok, moved} = Piece.move_right(piece, board)
      assert moved.col == piece.col + 1
    end

    test "cannot move past right wall" do
      piece = %{Piece.new([:a, :a, :a, :a]) |> Piece.spawn() | col: 14}
      board = Board.new()
      assert :error = Piece.move_right(piece, board)
    end
  end

  describe "move_down/2" do
    test "increments row" do
      piece = Piece.new([:a, :a, :a, :a]) |> Piece.spawn()
      board = Board.new()
      {:ok, moved} = Piece.move_down(piece, board)
      assert moved.row == piece.row + 1
    end

    test "cannot move below bottom" do
      piece = %{Piece.new([:a, :a, :a, :a]) |> Piece.spawn() | row: 8}
      board = Board.new()
      assert :error = Piece.move_down(piece, board)
    end

    test "cannot move into occupied cell below" do
      piece = %{Piece.new([:a, :a, :a, :a]) |> Piece.spawn() | row: 5}
      board = Board.new() |> Board.put(7, 7, :b)
      assert :error = Piece.move_down(piece, board)
    end
  end

  describe "hard_drop/2" do
    test "drops piece to lowest valid position" do
      piece = Piece.new([:a, :a, :a, :a]) |> Piece.spawn()
      board = Board.new()
      dropped = Piece.hard_drop(piece, board)
      # Should be at row 8 (bottom row for 2x2 piece in 10-row board)
      assert dropped.row == 8
    end

    test "drops piece onto existing blocks" do
      piece = Piece.new([:a, :a, :a, :a]) |> Piece.spawn()
      board = Board.new() |> Board.put(7, 5, :b)
      dropped = Piece.hard_drop(piece, board)
      # Piece bottom row would be at row 4 (so row 3 for piece origin)
      assert dropped.row == 3
    end
  end

  describe "lock/2" do
    test "places piece colors onto the board" do
      piece = %{Piece.new([:a, :b, :b, :a]) |> Piece.spawn() | row: 8}
      board = Board.new()
      new_board = Piece.lock(piece, board)
      assert Board.get(new_board, 7, 8) == :a
      assert Board.get(new_board, 8, 8) == :b
      assert Board.get(new_board, 7, 9) == :b
      assert Board.get(new_board, 8, 9) == :a
    end
  end

  describe "cells/1" do
    test "returns the four cell positions and colors" do
      piece = %{Piece.new([:a, :b, :b, :a]) |> Piece.spawn() | col: 3, row: 2}
      cells = Piece.cells(piece)
      assert {3, 2, :a} in cells
      assert {4, 2, :b} in cells
      assert {3, 3, :b} in cells
      assert {4, 3, :a} in cells
      assert length(cells) == 4
    end
  end

  describe "random/0" do
    test "generates a piece with valid colors" do
      piece = Piece.random()
      {tl, tr, bl, br} = piece.colors
      assert tl in [:a, :b]
      assert tr in [:a, :b]
      assert bl in [:a, :b]
      assert br in [:a, :b]
    end
  end

  describe "collides?/2" do
    test "returns false when spawn area is clear" do
      piece = Piece.new([:a, :a, :a, :a]) |> Piece.spawn()
      board = Board.new()
      refute Piece.collides?(piece, board)
    end

    test "returns true when spawn area has blocks" do
      piece = Piece.new([:a, :a, :a, :a]) |> Piece.spawn()
      board = Board.new() |> Board.put(7, 0, :b)
      assert Piece.collides?(piece, board)
    end
  end
end
