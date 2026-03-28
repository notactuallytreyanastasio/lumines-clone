defmodule Lumines.Engine.Piece do
  @moduledoc """
  2x2 piece for Lumines. Colors stored as {top_left, top_right, bottom_left, bottom_right}.
  """

  use Ecto.Schema

  alias Lumines.Engine.Board

  @type t :: %__MODULE__{}

  @primary_key false
  embedded_schema do
    field :colors, :any, virtual: true
    field :col, :integer
    field :row, :integer
  end

  @spec new([Board.color()]) :: t()
  def new([tl, tr, bl, br]) do
    %__MODULE__{colors: {tl, tr, bl, br}, col: nil, row: nil}
  end

  @spec random() :: t()
  def random do
    colors = for _ <- 1..4, do: Enum.random([:a, :b])
    new(colors)
  end

  @spec spawn(t()) :: t()
  def spawn(piece) do
    %{piece | col: 7, row: 0}
  end

  @spec rotate(t()) :: t()
  def rotate(%{colors: {tl, tr, bl, br}} = piece) do
    # Clockwise rotation:
    # TL TR    BL TL
    # BL BR -> BR TR
    %{piece | colors: {bl, tl, br, tr}}
  end

  @spec cells(t()) :: [{integer(), integer(), Board.color()}]
  def cells(%{colors: {tl, tr, bl, br}, col: col, row: row}) do
    [
      {col, row, tl},
      {col + 1, row, tr},
      {col, row + 1, bl},
      {col + 1, row + 1, br}
    ]
  end

  @spec move_left(t(), Board.t()) :: {:ok, t()} | :error
  def move_left(piece, board) do
    moved = %{piece | col: piece.col - 1}
    if valid_position?(moved, board), do: {:ok, moved}, else: :error
  end

  @spec move_right(t(), Board.t()) :: {:ok, t()} | :error
  def move_right(piece, board) do
    moved = %{piece | col: piece.col + 1}
    if valid_position?(moved, board), do: {:ok, moved}, else: :error
  end

  @spec move_down(t(), Board.t()) :: {:ok, t()} | :error
  def move_down(piece, board) do
    moved = %{piece | row: piece.row + 1}
    if valid_position?(moved, board), do: {:ok, moved}, else: :error
  end

  @spec hard_drop(t(), Board.t()) :: t()
  def hard_drop(piece, board) do
    case move_down(piece, board) do
      {:ok, moved} -> hard_drop(moved, board)
      :error -> piece
    end
  end

  @spec lock(t(), Board.t()) :: Board.t()
  def lock(piece, board) do
    Enum.reduce(cells(piece), board, fn {col, row, color}, acc ->
      Board.put(acc, col, row, color)
    end)
  end

  @spec collides?(t(), Board.t()) :: boolean()
  def collides?(piece, board) do
    Enum.any?(cells(piece), fn {col, row, _color} ->
      Board.occupied?(board, col, row)
    end)
  end

  @spec valid_position?(t(), Board.t()) :: boolean()
  defp valid_position?(piece, board) do
    Enum.all?(cells(piece), fn {col, row, _color} ->
      Board.in_bounds?(col, row) and not Board.occupied?(board, col, row)
    end)
  end
end
