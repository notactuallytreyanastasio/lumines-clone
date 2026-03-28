defmodule Lumines.Engine.Board do
  @moduledoc """
  16x10 grid for the Lumines game board.
  Each cell can be :a, :b, :marked_a, :marked_b, or nil (empty).
  """

  @cols 16
  @rows 10

  @type color :: :a | :b | :marked_a | :marked_b | nil
  @type t :: %{optional({non_neg_integer(), non_neg_integer()}) => color()}

  def cols, do: @cols
  def rows, do: @rows

  @spec new() :: t()
  def new do
    %{}
  end

  @spec get(t(), integer(), integer()) :: color()
  def get(board, col, row) do
    if in_bounds?(col, row) do
      Map.get(board, {col, row})
    else
      nil
    end
  end

  @spec put(t(), integer(), integer(), color()) :: t()
  def put(board, col, row, value) do
    if in_bounds?(col, row) do
      if value == nil do
        Map.delete(board, {col, row})
      else
        Map.put(board, {col, row}, value)
      end
    else
      board
    end
  end

  @spec in_bounds?(integer(), integer()) :: boolean()
  def in_bounds?(col, row) do
    col >= 0 and col < @cols and row >= 0 and row < @rows
  end

  @spec occupied?(t(), integer(), integer()) :: boolean()
  def occupied?(board, col, row) do
    get(board, col, row) != nil
  end

  @spec clear_marked(t(), Range.t()) :: t()
  def clear_marked(board, col_range) do
    Enum.reduce(col_range, board, fn col, acc ->
      Enum.reduce(0..(@rows - 1), acc, fn row, acc2 ->
        case get(acc2, col, row) do
          v when v in [:marked_a, :marked_b] -> put(acc2, col, row, nil)
          _ -> acc2
        end
      end)
    end)
  end

  @doc "Returns the base color for a cell (strips marked prefix)"
  @spec base_color(color()) :: :a | :b | nil
  def base_color(:a), do: :a
  def base_color(:b), do: :b
  def base_color(:marked_a), do: :a
  def base_color(:marked_b), do: :b
  def base_color(nil), do: nil

  @spec marked?(color()) :: boolean()
  def marked?(:marked_a), do: true
  def marked?(:marked_b), do: true
  def marked?(_), do: false
end
