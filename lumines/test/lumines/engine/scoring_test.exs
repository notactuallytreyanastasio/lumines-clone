defmodule Lumines.Engine.ScoringTest do
  use ExUnit.Case, async: true

  alias Lumines.Engine.Scoring

  describe "new/0" do
    test "starts with zero score and no combo" do
      scoring = Scoring.new()
      assert scoring.score == 0
      assert scoring.combo == 0
      assert scoring.chain == 0
    end
  end

  describe "award_squares/2" do
    test "awards base points for cleared squares" do
      scoring = Scoring.new()
      scoring = Scoring.award_squares(scoring, 1)
      assert scoring.score > 0
    end

    test "more squares = more points" do
      s1 = Scoring.new() |> Scoring.award_squares(1)
      s2 = Scoring.new() |> Scoring.award_squares(3)
      assert s2.score > s1.score
    end

    test "increments combo counter" do
      scoring = Scoring.new() |> Scoring.award_squares(1)
      assert scoring.combo == 1
    end
  end

  describe "chain_bonus/1" do
    test "awards chain bonus and increments chain" do
      scoring = Scoring.new() |> Scoring.award_squares(2) |> Scoring.chain_bonus()
      assert scoring.chain == 1
      assert scoring.score > Scoring.new() |> Scoring.award_squares(2) |> Map.get(:score)
    end
  end

  describe "reset_combo/1" do
    test "resets combo and chain to zero" do
      scoring =
        Scoring.new()
        |> Scoring.award_squares(2)
        |> Scoring.chain_bonus()
        |> Scoring.reset_combo()

      assert scoring.combo == 0
      assert scoring.chain == 0
    end

    test "preserves accumulated score" do
      scoring =
        Scoring.new()
        |> Scoring.award_squares(2)

      score_before = scoring.score
      scoring = Scoring.reset_combo(scoring)
      assert scoring.score == score_before
    end
  end
end
