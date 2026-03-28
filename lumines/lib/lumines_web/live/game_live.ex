defmodule LuminesWeb.GameLive do
  use LuminesWeb, :live_view

  alias Lumines.Engine.{Game, Board}

  @gravity_interval 500
  @sweep_interval 150

  @impl true
  def mount(_params, _session, socket) do
    game = Game.new()

    if connected?(socket) do
      Process.send_after(self(), :gravity_tick, @gravity_interval)
      Process.send_after(self(), :sweep_tick, @sweep_interval)
    end

    {:ok, assign(socket, game: game)}
  end

  @impl true
  def handle_event("keydown", %{"key" => key}, socket) do
    action = key_to_action(key)

    if action do
      case Game.input(socket.assigns.game, action) do
        {:ok, game} -> {:noreply, assign(socket, game: game)}
        {:error, :game_over} -> {:noreply, socket}
      end
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info(:gravity_tick, socket) do
    Process.send_after(self(), :gravity_tick, @gravity_interval)

    game = Game.gravity_tick(socket.assigns.game)
    {:noreply, assign(socket, game: game)}
  end

  @impl true
  def handle_info(:sweep_tick, socket) do
    Process.send_after(self(), :sweep_tick, @sweep_interval)

    game = Game.sweep_tick(socket.assigns.game)
    {:noreply, assign(socket, game: game)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id="lumines-game" phx-window-keydown="keydown" class="lumines-game" style="flex-direction: column; align-items: center; padding: 1rem;">
      <%!-- Header with title and score summary --%>
      <div style="display: flex; align-items: center; gap: 2rem; margin-bottom: 0.5rem;">
        <div style="font-size: 1.25rem; font-weight: 700; color: var(--color-text-score);">LUMINES</div>
        <div style="font-size: 0.875rem; color: var(--color-text-secondary);">
          Combo: <%= @game.scoring.combo %> | Chain: <%= @game.scoring.chain %>
        </div>
      </div>

      <div style="display: flex; align-items: flex-start; gap: var(--layout-gap);">
        <%!-- Main board --%>
        <div class="lumines-board-area">
          <div class="lumines-board">
            <%= for row <- 0..(Board.rows() - 1), col <- 0..(Board.cols() - 1) do %>
              <div
                class={cell_classes(Board.get(@game.board, col, row))}
                data-col={col}
                data-row={row}
              />
            <% end %>

            <%!-- Active piece cells overlaid on board grid --%>
            <%= if @game.phase == :playing do %>
              <%= for {col, row, color} <- Lumines.Engine.Piece.cells(@game.piece) do %>
                <div
                  class={active_piece_classes(color)}
                  style={"position: absolute; left: calc(#{col} * (var(--cell-size) + var(--cell-gap))); top: calc(#{row} * (var(--cell-size) + var(--cell-gap))); width: var(--cell-size); height: var(--cell-size);"}
                />
              <% end %>
            <% end %>
          </div>

          <%!-- Sweep line (JS-controlled via style) --%>
          <div
            class="lumines-sweep-line lumines-sweep-line--manual"
            style={"left: calc(8px + #{@game.sweep.col} * (var(--cell-size) + var(--cell-gap)));"}
          />

          <%!-- Game over overlay --%>
          <%= if @game.phase == :game_over do %>
            <div class="lumines-game-over">
              <div class="lumines-game-over-text">Game Over</div>
              <div class="lumines-game-over-score">Score: <%= @game.scoring.score %></div>
            </div>
          <% end %>
        </div>

        <%!-- Sidebar --%>
        <div class="lumines-sidebar">
          <div class="lumines-score-panel">
            <div class="lumines-score-label">Score</div>
            <div class="lumines-score-value"><%= @game.scoring.score %></div>
          </div>

          <div class="lumines-queue-panel">
            <div class="lumines-queue-label">Next</div>
            <div class="lumines-queue-pieces">
              <%= for piece <- @game.next_pieces do %>
                <div class="lumines-queue-piece">
                  <% {tl, tr, bl, br} = piece.colors %>
                  <div class={queue_cell_classes(tl)} />
                  <div class={queue_cell_classes(tr)} />
                  <div class={queue_cell_classes(bl)} />
                  <div class={queue_cell_classes(br)} />
                </div>
              <% end %>
            </div>
          </div>

          <div class="lumines-level-panel">
            <div class="lumines-level-label">Level</div>
            <div class="lumines-level-value">1</div>
          </div>
        </div>
      </div>

      <div style="font-size: 0.75rem; color: var(--color-text-secondary); margin-top: 0.5rem;">
        Arrow keys: Move | Up/Z: Rotate | Space: Hard Drop
      </div>
    </div>
    """
  end

  defp key_to_action("ArrowLeft"), do: :left
  defp key_to_action("ArrowRight"), do: :right
  defp key_to_action("ArrowDown"), do: :down
  defp key_to_action("ArrowUp"), do: :rotate
  defp key_to_action("z"), do: :rotate
  defp key_to_action("Z"), do: :rotate
  defp key_to_action(" "), do: :hard_drop
  defp key_to_action(_), do: nil

  defp cell_classes(nil), do: "lumines-cell lumines-cell--empty"
  defp cell_classes(:a), do: "lumines-cell lumines-cell--a"
  defp cell_classes(:b), do: "lumines-cell lumines-cell--b"
  defp cell_classes(:marked_a), do: "lumines-cell lumines-cell--a lumines-cell--marked"
  defp cell_classes(:marked_b), do: "lumines-cell lumines-cell--b lumines-cell--marked"

  defp active_piece_classes(:a), do: "lumines-cell lumines-cell--a lumines-cell--active"
  defp active_piece_classes(:b), do: "lumines-cell lumines-cell--b lumines-cell--active"

  defp queue_cell_classes(:a), do: "lumines-cell lumines-cell--a"
  defp queue_cell_classes(:b), do: "lumines-cell lumines-cell--b"
end
