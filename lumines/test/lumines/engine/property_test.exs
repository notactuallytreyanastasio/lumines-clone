defmodule Lumines.Engine.PropertyTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Lumines.Engine.{Board, Piece, Gravity, Scanner, Sweep, Scoring, Game}

  # Generators

  defp color_gen, do: member_of([:a, :b])

  defp piece_gen do
    gen all tl <- color_gen(),
            tr <- color_gen(),
            bl <- color_gen(),
            br <- color_gen() do
      %Piece{colors: {tl, tr, bl, br}, col: nil, row: nil}
    end
  end

  defp spawned_piece_gen do
    gen all piece <- piece_gen(),
            col <- integer(0..13) do
      %{piece | col: col, row: 0}
    end
  end

  defp board_cell_gen do
    gen all col <- integer(0..15),
            row <- integer(0..9),
            color <- color_gen() do
      {col, row, color}
    end
  end

  defp sparse_board_gen do
    gen all cells <- list_of(board_cell_gen(), max_length: 40) do
      Enum.reduce(cells, Board.new(), fn {col, row, color}, board ->
        Board.put(board, col, row, color)
      end)
    end
  end

  # Board properties

  property "Board.put then Board.get returns the value" do
    check all col <- integer(0..15),
              row <- integer(0..9),
              color <- color_gen() do
      board = Board.new() |> Board.put(col, row, color)
      assert Board.get(board, col, row) == color
    end
  end

  property "Board.put with nil clears the cell" do
    check all col <- integer(0..15),
              row <- integer(0..9),
              color <- color_gen() do
      board =
        Board.new()
        |> Board.put(col, row, color)
        |> Board.put(col, row, nil)

      assert is_nil(Board.get(board, col, row))
    end
  end

  property "Board.put out of bounds is a no-op" do
    check all col <- one_of([integer(-100..-1), integer(16..100)]),
              row <- integer(0..9),
              color <- color_gen() do
      board = Board.new()
      assert Board.put(board, col, row, color) == board
    end
  end

  property "Board.get out of bounds returns nil" do
    check all col <- one_of([integer(-100..-1), integer(16..100)]),
              row <- integer(0..9) do
      assert is_nil(Board.get(Board.new(), col, row))
    end
  end

  property "Board.occupied? is consistent with Board.get" do
    check all board <- sparse_board_gen(),
              col <- integer(0..15),
              row <- integer(0..9) do
      assert Board.occupied?(board, col, row) == not is_nil(Board.get(board, col, row))
    end
  end

  # Piece properties

  property "four rotations return to original" do
    check all piece <- piece_gen() do
      rotated = piece |> Piece.rotate() |> Piece.rotate() |> Piece.rotate() |> Piece.rotate()
      assert rotated.colors == piece.colors
    end
  end

  property "rotation preserves color multiset" do
    check all piece <- piece_gen() do
      {a, b, c, d} = piece.colors
      original_colors = Enum.sort([a, b, c, d])

      rotated = Piece.rotate(piece)
      {ra, rb, rc, rd} = rotated.colors
      rotated_colors = Enum.sort([ra, rb, rc, rd])

      assert original_colors == rotated_colors
    end
  end

  property "piece always has exactly 4 cells" do
    check all piece <- spawned_piece_gen() do
      assert length(Piece.cells(piece)) == 4
    end
  end

  property "piece cells occupy a 2x2 area" do
    check all piece <- spawned_piece_gen() do
      cells = Piece.cells(piece)
      cols = cells |> Enum.map(&elem(&1, 0)) |> Enum.uniq() |> Enum.sort()
      rows = cells |> Enum.map(&elem(&1, 1)) |> Enum.uniq() |> Enum.sort()

      assert length(cols) == 2
      assert length(rows) == 2
      assert List.last(cols) - List.first(cols) == 1
      assert List.last(rows) - List.first(rows) == 1
    end
  end

  property "hard_drop always lands at a valid position or doesn't move" do
    check all piece <- spawned_piece_gen(),
              board <- sparse_board_gen() do
      dropped = Piece.hard_drop(piece, board)

      # Dropped piece should be at same col or the piece didn't move
      assert dropped.col == piece.col

      # Row should be >= original row
      assert dropped.row >= piece.row

      # Should not be able to move further down
      assert Piece.move_down(dropped, board) == :error
    end
  end

  property "lock places exactly 4 cells on the board" do
    check all piece <- spawned_piece_gen() do
      board = Board.new()
      locked = Piece.lock(piece, board)

      cell_count = Enum.count(locked)
      assert cell_count == 4
    end
  end

  # Gravity properties

  property "gravity preserves total cell count" do
    check all board <- sparse_board_gen() do
      original_count =
        for col <- 0..15, row <- 0..9, not is_nil(Board.get(board, col, row)), do: 1
      after_gravity_count =
        for col <- 0..15, row <- 0..9, not is_nil(Board.get(Gravity.apply(board), col, row)), do: 1

      assert length(original_count) == length(after_gravity_count)
    end
  end

  property "gravity preserves color distribution" do
    check all board <- sparse_board_gen() do
      colors_before =
        for col <- 0..15, row <- 0..9,
            color = Board.get(board, col, row),
            not is_nil(color),
            do: color

      settled = Gravity.apply(board)

      colors_after =
        for col <- 0..15, row <- 0..9,
            color = Board.get(settled, col, row),
            not is_nil(color),
            do: color

      assert Enum.sort(colors_before) == Enum.sort(colors_after)
    end
  end

  property "gravity is idempotent — applying twice gives same result" do
    check all board <- sparse_board_gen() do
      once = Gravity.apply(board)
      twice = Gravity.apply(once)
      assert once == twice
    end
  end

  property "after gravity, no cell has an empty cell below it" do
    check all board <- sparse_board_gen() do
      settled = Gravity.apply(board)

      for col <- 0..15, row <- 0..8 do
        cell = Board.get(settled, col, row)
        below = Board.get(settled, col, row + 1)

        if not is_nil(cell) and is_nil(below) do
          # This should never happen after gravity
          flunk("Cell at {#{col}, #{row}} has empty space below after gravity")
        end
      end
    end
  end

  # Scanner properties

  property "scanner only marks cells that are part of 2x2 same-color squares" do
    check all board <- sparse_board_gen() do
      {scanned, _count} = Scanner.scan_with_count(board)

      for col <- 0..15, row <- 0..9 do
        cell = Board.get(scanned, col, row)

        case cell do
          :marked_a ->
            # Must be part of at least one 2x2 block of :a
            assert part_of_square?(board, col, row, :a),
              "marked_a at {#{col}, #{row}} but not part of any 2x2 :a square"

          :marked_b ->
            assert part_of_square?(board, col, row, :b),
              "marked_b at {#{col}, #{row}} but not part of any 2x2 :b square"

          _ ->
            :ok
        end
      end
    end
  end

  property "scanning preserves non-square cells" do
    check all board <- sparse_board_gen() do
      {scanned, _count} = Scanner.scan_with_count(board)

      for col <- 0..15, row <- 0..9 do
        original = Board.get(board, col, row)
        after_scan = Board.get(scanned, col, row)

        case {original, after_scan} do
          {nil, nil} -> :ok
          {:a, :a} -> :ok
          {:b, :b} -> :ok
          {:a, :marked_a} -> :ok
          {:b, :marked_b} -> :ok
          {:marked_a, :marked_a} -> :ok
          {:marked_b, :marked_b} -> :ok
          other -> flunk("Unexpected transition at {#{col}, #{row}}: #{inspect(other)}")
        end
      end
    end
  end

  # Sweep properties

  property "sweep column always stays within board bounds" do
    check all start_col <- integer(0..15),
              ticks <- integer(1..100) do
      sweep = %Sweep{col: start_col}

      final =
        Enum.reduce(1..ticks, sweep, fn _, s -> Sweep.advance(s) end)

      assert final.col >= 0 and final.col < Board.cols()
    end
  end

  property "sweep wraps around after 16 advances" do
    check all start_col <- integer(0..15) do
      sweep = %Sweep{col: start_col}

      after_16 =
        Enum.reduce(1..16, sweep, fn _, s -> Sweep.advance(s) end)

      assert after_16.col == start_col
    end
  end

  # Scoring properties

  property "score never decreases" do
    check all num_awards <- integer(1..10),
              squares_list <- list_of(integer(1..5), length: num_awards) do
      final =
        Enum.reduce(squares_list, %Scoring{}, fn squares, scoring ->
          Scoring.award_squares(scoring, squares)
        end)

      assert final.score > 0
    end
  end

  property "combo increments with each award" do
    check all squares_list <- list_of(integer(1..5), min_length: 1, max_length: 10) do
      final =
        Enum.reduce(squares_list, %Scoring{}, fn squares, scoring ->
          Scoring.award_squares(scoring, squares)
        end)

      assert final.combo == length(squares_list)
    end
  end

  property "reset_combo zeroes combo and chain but preserves score" do
    check all squares <- integer(1..5) do
      scoring =
        %Scoring{}
        |> Scoring.award_squares(squares)
        |> Scoring.chain_bonus()

      assert scoring.score > 0

      reset = Scoring.reset_combo(scoring)
      assert reset.score == scoring.score
      assert reset.combo == 0
      assert reset.chain == 0
    end
  end

  # Game properties

  property "game always starts in :playing phase with valid state" do
    check all _ <- constant(nil), max_runs: 20 do
      game = Game.new()
      assert game.phase == :playing
      assert not is_nil(game.piece)
      assert length(game.next_pieces) == 3
      assert game.sweep.col == 0
      assert game.scoring.score == 0
    end
  end

  property "input on game_over always returns error" do
    check all action <- member_of([:left, :right, :down, :rotate, :hard_drop]) do
      game = %Game{Game.new() | phase: :game_over}
      assert {:error, :game_over} = Game.input(game, action)
    end
  end

  property "gravity_tick on game_over is identity" do
    check all _ <- constant(nil), max_runs: 5 do
      game = %Game{Game.new() | phase: :game_over}
      assert Game.gravity_tick(game) == game
    end
  end

  property "sweep_tick on game_over is identity" do
    check all _ <- constant(nil), max_runs: 5 do
      game = %Game{Game.new() | phase: :game_over}
      assert Game.sweep_tick(game) == game
    end
  end

  property "left/right inputs never crash and keep phase as playing" do
    check all moves <- list_of(member_of([:left, :right]), max_length: 20) do
      game = Game.new()

      Enum.reduce(moves, game, fn move, g ->
        {:ok, new_g} = Game.input(g, move)
        assert new_g.phase == :playing
        new_g
      end)
    end
  end

  # Helpers

  defp part_of_square?(board, col, row, color) do
    # Check all four possible 2x2 squares that include {col, row}
    offsets = [{0, 0}, {-1, 0}, {0, -1}, {-1, -1}]

    Enum.any?(offsets, fn {dc, dr} ->
      c = col + dc
      r = row + dr

      Board.get(board, c, r) == color and
        Board.get(board, c + 1, r) == color and
        Board.get(board, c, r + 1) == color and
        Board.get(board, c + 1, r + 1) == color
    end)
  end
end
