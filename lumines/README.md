# Lumines

A clone of the PSP puzzle game [Lumines](https://en.wikipedia.org/wiki/Lumines), built with Phoenix LiveView. The entire game runs server-side — no JavaScript game logic, just a LiveView that pushes board state over WebSocket.

## Prerequisites

You need Erlang, Elixir, and PostgreSQL. If you have none of these, start here.

### macOS

```bash
# Install Homebrew if you don't have it
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Erlang and Elixir via asdf (recommended)
brew install asdf
asdf plugin add erlang
asdf plugin add elixir

asdf install erlang 27.2
asdf install elixir 1.18.3-otp-27
asdf global erlang 27.2
asdf global elixir 1.18.3-otp-27

# Or install directly via Homebrew (simpler but less flexible)
# brew install elixir

# Install PostgreSQL
brew install postgresql@17
brew services start postgresql@17

# Create the default postgres user if it doesn't exist
createuser -s postgres
```

### Ubuntu / Debian

```bash
# Erlang and Elixir
sudo apt-get update
sudo apt-get install -y erlang elixir

# PostgreSQL
sudo apt-get install -y postgresql postgresql-contrib
sudo systemctl start postgresql

# Create the postgres user (set password to "postgres")
sudo -u postgres createuser -s postgres
sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'postgres';"
```

### Windows

```powershell
# Install Chocolatey if you don't have it (run as admin)
Set-ExecutionPolicy Bypass -Scope Process -Force
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install Erlang and Elixir
choco install elixir

# Install PostgreSQL (interactive installer)
choco install postgresql17
# Default superuser is "postgres" — set password to "postgres" during install
```

### Verify your install

```bash
elixir --version   # Should show Elixir 1.15+
psql --version     # Should show PostgreSQL 14+
```

## Setup

```bash
cd lumines

# Install Elixir dependencies
mix deps.get

# Create and migrate the database
mix ecto.setup

# Install JS tooling (esbuild + tailwind — downloaded automatically)
mix assets.setup
```

## Run the game

```bash
mix phx.server
```

Open [http://localhost:4000/game](http://localhost:4000/game) in your browser.

## Controls

| Key | Action |
|-----|--------|
| Left arrow | Move piece left |
| Right arrow | Move piece right |
| Down arrow | Soft drop (move down one row) |
| Up arrow / Z | Rotate piece clockwise |
| Space | Hard drop (instant drop to bottom) |

## How to play

The board is a 16x10 grid. Pieces are 2x2 blocks, each cell colored one of two colors. Your goal is to form 2x2 squares of the same color anywhere on the board.

A sweep line moves left-to-right across the board. When it passes over matched squares, those cells are cleared. Cleared cells cause the blocks above to fall (gravity), which can trigger chain reactions when new squares form.

The game is over when a new piece can't spawn because the top of the board is blocked.

## Run the tests

```bash
# All tests (72 unit + 27 property-based)
mix test

# Just the property-based tests
mix test test/lumines/engine/property_test.exs

# With verbose output
mix test --trace
```

## Project structure

```
lumines/
├── lib/lumines/engine/      # Game engine (pure functional, no side effects)
│   ├── board.ex             # 16x10 sparse map grid
│   ├── piece.ex             # 2x2 piece: rotation, movement, collision
│   ├── gravity.ex           # Per-column cell compaction
│   ├── scanner.ex           # 2x2 same-color square detection
│   ├── sweep.ex             # Left-to-right sweep line clearing
│   ├── scoring.ex           # Points, combos, chain bonuses
│   └── game.ex              # State machine tying it all together
├── lib/lumines_web/live/
│   └── game_live.ex         # LiveView: renders board, handles input, runs timers
└── test/lumines/engine/     # Tests
    ├── board_test.exs
    ├── piece_test.exs
    ├── gravity_test.exs
    ├── scanner_test.exs
    ├── sweep_test.exs
    ├── scoring_test.exs
    ├── game_test.exs
    └── property_test.exs    # Property-based tests (stream_data)
```

## Engine architecture

The game engine is purely functional — no GenServers, no processes, no side effects. Every function takes state in and returns state out. The LiveView owns the process and drives two independent timers:

- **Gravity timer** (500ms) — moves the active piece down one row
- **Sweep timer** (150ms) — advances the sweep line one column right

The game loop: `spawn piece → gravity ticks → piece lands → lock → apply gravity → scan for squares → mark → sweep clears when it passes → post-clear gravity → rescan for chains → repeat`
