defmodule Lumines.Engine.Scoring do
  @moduledoc """
  Scoring system for Lumines.
  Base points per square, with multipliers for combos and chains.
  """

  defstruct score: 0, combo: 0, chain: 0

  @type t :: %__MODULE__{
          score: non_neg_integer(),
          combo: non_neg_integer(),
          chain: non_neg_integer()
        }

  @base_points 100

  @spec new() :: t()
  def new, do: %__MODULE__{}

  @spec award_squares(t(), non_neg_integer()) :: t()
  def award_squares(%__MODULE__{} = scoring, num_squares) when num_squares > 0 do
    combo_multiplier = max(1, scoring.combo + 1)
    points = num_squares * @base_points * combo_multiplier

    %{scoring | score: scoring.score + points, combo: scoring.combo + 1}
  end

  def award_squares(scoring, 0), do: scoring

  @spec chain_bonus(t()) :: t()
  def chain_bonus(%__MODULE__{} = scoring) do
    chain_multiplier = scoring.chain + 1
    bonus = 50 * chain_multiplier

    %{scoring | score: scoring.score + bonus, chain: scoring.chain + 1}
  end

  @spec reset_combo(t()) :: t()
  def reset_combo(%__MODULE__{} = scoring) do
    %{scoring | combo: 0, chain: 0}
  end
end
