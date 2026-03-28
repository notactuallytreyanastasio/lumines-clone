defmodule Lumines.Engine.Sweep do
  @moduledoc """
  The sweep line moves left-to-right across the board, clearing marked cells.
  """

  use Ecto.Schema

  alias Lumines.Engine.Board

  @type t :: %__MODULE__{}

  @primary_key false
  embedded_schema do
    field :col, :integer, default: 0
  end

  @spec new() :: t()
  def new, do: %__MODULE__{col: 0}

  @spec advance(t()) :: t()
  def advance(%__MODULE__{col: col}) do
    %__MODULE__{col: rem(col + 1, Board.cols())}
  end

  @spec clear_column(Board.t(), non_neg_integer()) :: Board.t()
  def clear_column(board, col) do
    Enum.reduce(0..(Board.rows() - 1), board, fn row, acc ->
      case Board.get(acc, col, row) do
        v when v in [:marked_a, :marked_b] -> Board.put(acc, col, row, nil)
        _ -> acc
      end
    end)
  end

  @spec process_tick(Board.t(), t()) :: {Board.t(), t()}
  def process_tick(board, sweep) do
    new_sweep = advance(sweep)
    new_board = clear_column(board, new_sweep.col)
    {new_board, new_sweep}
  end
end
