defmodule Lumines.Engine.Game do
  @moduledoc """
  Game state machine for Lumines.
  Flow: spawn -> fall -> lock -> gravity -> scan -> (sweep clears async) -> spawn
  """

  alias Lumines.Engine.{Board, Piece, Gravity, Scanner, Sweep, Scoring}

  defstruct [
    :board,
    :piece,
    :next_pieces,
    :sweep,
    :scoring,
    :phase
  ]

  @type phase :: :playing | :game_over
  @type t :: %__MODULE__{
          board: Board.t(),
          piece: Piece.t(),
          next_pieces: [Piece.t()],
          sweep: Sweep.t(),
          scoring: Scoring.t(),
          phase: phase()
        }

  @queue_size 3

  @spec new() :: t()
  def new do
    next_pieces = for _ <- 1..@queue_size, do: Piece.random()
    [piece | rest] = [Piece.random() | next_pieces]

    %__MODULE__{
      board: Board.new(),
      piece: Piece.spawn(piece),
      next_pieces: rest,
      sweep: Sweep.new(),
      scoring: Scoring.new(),
      phase: :playing
    }
  end

  @spec input(t(), atom()) :: {:ok, t()} | {:error, :game_over}
  def input(%{phase: :game_over}, _action), do: {:error, :game_over}

  def input(%{piece: piece, board: board} = game, :left) do
    case Piece.move_left(piece, board) do
      {:ok, moved} -> {:ok, %{game | piece: moved}}
      :error -> {:ok, game}
    end
  end

  def input(%{piece: piece, board: board} = game, :right) do
    case Piece.move_right(piece, board) do
      {:ok, moved} -> {:ok, %{game | piece: moved}}
      :error -> {:ok, game}
    end
  end

  def input(%{piece: piece} = game, :rotate) do
    rotated = Piece.rotate(piece)
    # Only rotate if the new position is valid
    if valid_piece_position?(rotated, game.board) do
      {:ok, %{game | piece: rotated}}
    else
      {:ok, game}
    end
  end

  def input(%{piece: piece, board: board} = game, :down) do
    case Piece.move_down(piece, board) do
      {:ok, moved} -> {:ok, %{game | piece: moved}}
      :error -> {:ok, lock_and_advance(game)}
    end
  end

  def input(game, :hard_drop) do
    dropped = Piece.hard_drop(game.piece, game.board)
    {:ok, lock_and_advance(%{game | piece: dropped})}
  end

  @spec gravity_tick(t()) :: t()
  def gravity_tick(%{phase: :game_over} = game), do: game

  def gravity_tick(%{piece: piece, board: board} = game) do
    case Piece.move_down(piece, board) do
      {:ok, moved} -> %{game | piece: moved}
      :error -> lock_and_advance(game)
    end
  end

  @spec sweep_tick(t()) :: t()
  def sweep_tick(%{phase: :game_over} = game), do: game

  def sweep_tick(%{board: board, sweep: sweep, scoring: scoring} = game) do
    {new_board, new_sweep} = Sweep.process_tick(board, sweep)

    # Check if any cells were cleared (board changed)
    cleared = new_board != board

    # Apply gravity after clearing
    new_board = if cleared, do: Gravity.apply(new_board), else: new_board

    # Re-scan for chain reactions after gravity
    {new_board, new_squares} =
      if cleared do
        Scanner.scan_with_count(new_board)
      else
        {new_board, 0}
      end

    # Award chain bonus if new squares formed
    scoring =
      if new_squares > 0 do
        scoring |> Scoring.chain_bonus() |> Scoring.award_squares(new_squares)
      else
        scoring
      end

    # Reset combo if sweep completes a full pass with no activity
    scoring =
      if new_sweep.col == 0 do
        Scoring.reset_combo(scoring)
      else
        scoring
      end

    %{game | board: new_board, sweep: new_sweep, scoring: scoring}
  end

  # Private helpers

  defp lock_and_advance(game) do
    # Lock piece onto board
    board = Piece.lock(game.piece, game.board)

    # Apply gravity
    board = Gravity.apply(board)

    # Scan for squares
    {board, num_squares} = Scanner.scan_with_count(board)

    # Award score
    scoring =
      if num_squares > 0 do
        Scoring.award_squares(game.scoring, num_squares)
      else
        game.scoring
      end

    # Spawn next piece
    [next | rest] = game.next_pieces
    new_next = rest ++ [Piece.random()]
    new_piece = Piece.spawn(next)

    # Check game over
    if Piece.collides?(new_piece, board) do
      %{game | board: board, piece: new_piece, next_pieces: new_next, scoring: scoring, phase: :game_over}
    else
      %{game | board: board, piece: new_piece, next_pieces: new_next, scoring: scoring}
    end
  end

  defp valid_piece_position?(piece, board) do
    Enum.all?(Piece.cells(piece), fn {col, row, _color} ->
      Board.in_bounds?(col, row) and not Board.occupied?(board, col, row)
    end)
  end
end
