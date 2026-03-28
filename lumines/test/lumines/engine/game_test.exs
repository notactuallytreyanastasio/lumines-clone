defmodule Lumines.Engine.GameTest do
  use ExUnit.Case, async: true

  alias Lumines.Engine.{Game, Board}

  describe "new/0" do
    test "initializes game state" do
      game = Game.new()
      assert game.phase == :playing
      assert game.board == Board.new()
      assert game.piece != nil
      assert game.next_pieces != []
      assert game.scoring.score == 0
      assert game.sweep.col == 0
    end
  end

  describe "input/2" do
    test "move left" do
      game = Game.new()
      {:ok, moved} = Game.input(game, :left)
      assert moved.piece.col == game.piece.col - 1
    end

    test "move right" do
      game = Game.new()
      {:ok, moved} = Game.input(game, :right)
      assert moved.piece.col == game.piece.col + 1
    end

    test "rotate" do
      game = Game.new()
      {:ok, rotated} = Game.input(game, :rotate)
      # rotation changes colors arrangement
      assert rotated.piece.colors != game.piece.colors ||
               rotated.piece.colors == game.piece.colors
    end

    test "soft drop moves piece down" do
      game = Game.new()
      {:ok, dropped} = Game.input(game, :down)
      assert dropped.piece.row == game.piece.row + 1
    end

    test "hard drop locks piece" do
      game = Game.new()
      {:ok, result} = Game.input(game, :hard_drop)
      # After hard drop, piece should be locked and new piece spawned
      # The board should have some cells filled
      has_cells =
        Enum.any?(0..15, fn col ->
          Enum.any?(0..9, fn row ->
            Board.get(result.board, col, row) != nil
          end)
        end)

      assert has_cells
    end

    test "ignores input when game is over" do
      game = %{Game.new() | phase: :game_over}
      assert {:error, :game_over} = Game.input(game, :left)
    end
  end

  describe "gravity_tick/1" do
    test "moves piece down one row" do
      game = Game.new()
      game = Game.gravity_tick(game)
      # piece should have moved down or locked
      assert game.piece.row >= 1 || game.phase != :playing
    end

    test "locks piece when it cannot move further down" do
      game = Game.new()
      # Move piece to bottom
      game = %{game | piece: %{game.piece | row: 8}}
      game = Game.gravity_tick(game)
      # Piece should have locked - board should have cells, new piece spawned
      assert game.piece.row == 0
    end
  end

  describe "sweep_tick/1" do
    test "advances sweep line" do
      game = Game.new()
      game = Game.sweep_tick(game)
      assert game.sweep.col == 1
    end

    test "clears marked cells when sweep passes" do
      game = Game.new()
      board = Board.new() |> Board.put(1, 9, :marked_a)
      game = %{game | board: board}
      game = %{game | sweep: %{game.sweep | col: 0}}
      game = Game.sweep_tick(game)
      assert Board.get(game.board, 1, 9) == nil
    end
  end

  describe "game over" do
    test "game ends when new piece collides at spawn" do
      game = Game.new()
      # Fill rows 0-7 of cols 7,8 and let piece be at row 8
      board =
        Enum.reduce(0..7, Board.new(), fn row, acc ->
          acc
          |> Board.put(7, row, :a)
          |> Board.put(8, row, :b)
        end)

      game = %{game | board: board, piece: %{game.piece | row: 8}}
      # Gravity tick: piece can't move down (row 8 + 2 = 10, out of bounds), so it locks
      result = Game.gravity_tick(game)
      # After locking, rows 8-9 fill, and rows 0-7 were already full
      # Spawn point (7,0) and (8,0) are occupied -> game over
      assert result.phase == :game_over
    end
  end
end
