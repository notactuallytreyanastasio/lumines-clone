defmodule Lumines.Engine.Gravity do
  @moduledoc """
  Applies gravity to the board — cells fall down to fill gaps.
  Each column is processed independently.
  """

  alias Lumines.Engine.Board

  @spec apply(Board.t()) :: Board.t()
  def apply(board) do
    Enum.reduce(0..(Board.cols() - 1), board, fn col, acc ->
      apply_column(acc, col)
    end)
  end

  defp apply_column(board, col) do
    # Collect non-nil cells from top to bottom
    cells =
      for row <- 0..(Board.rows() - 1),
          val = Board.get(board, col, row),
          val != nil,
          do: val

    # Clear the column
    board =
      Enum.reduce(0..(Board.rows() - 1), board, fn row, acc ->
        Board.put(acc, col, row, nil)
      end)

    # Place cells at bottom
    count = length(cells)

    if count == 0 do
      board
    else
      start_row = Board.rows() - count

      cells
      |> Enum.with_index()
      |> Enum.reduce(board, fn {val, idx}, acc ->
        Board.put(acc, col, start_row + idx, val)
      end)
    end
  end
end
