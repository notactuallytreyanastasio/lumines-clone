defmodule Lumines.Engine.Scanner do
  @moduledoc """
  Scans the board for 2x2 same-color squares and marks them for clearing.
  Only unmarked cells form new squares.
  """

  alias Lumines.Engine.Board

  @spec scan(Board.t()) :: Board.t()
  def scan(board) do
    {board, _count} = scan_with_count(board)
    board
  end

  @spec scan_with_count(Board.t()) :: {Board.t(), non_neg_integer()}
  def scan_with_count(board) do
    # Find all 2x2 squares of same color (only considering unmarked cells)
    squares = find_squares(board)
    count = length(squares)

    # Mark all cells in found squares
    board =
      Enum.reduce(squares, board, fn {col, row, color}, acc ->
        marked = if color == :a, do: :marked_a, else: :marked_b

        acc
        |> Board.put(col, row, marked)
        |> Board.put(col + 1, row, marked)
        |> Board.put(col, row + 1, marked)
        |> Board.put(col + 1, row + 1, marked)
      end)

    {board, count}
  end

  defp find_squares(board) do
    for col <- 0..(Board.cols() - 2),
        row <- 0..(Board.rows() - 2),
        square?(board, col, row),
        do: {col, row, Board.get(board, col, row)}
  end

  defp square?(board, col, row) do
    tl = Board.get(board, col, row)
    tr = Board.get(board, col + 1, row)
    bl = Board.get(board, col, row + 1)
    br = Board.get(board, col + 1, row + 1)

    # All must be the same base color and none can be nil or already marked
    tl != nil and
      not Board.marked?(tl) and
      not Board.marked?(tr) and
      not Board.marked?(bl) and
      not Board.marked?(br) and
      tl == tr and tl == bl and tl == br
  end
end
