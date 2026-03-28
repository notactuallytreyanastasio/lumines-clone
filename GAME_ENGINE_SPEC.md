# Lumines Game Engine Spec

## Board

- **Grid**: 16 columns x 10 rows (16:10 approximating 16:9 in block units)
- Each cell holds a single color: **A** or **B** (two colors per "skin")
- Empty cells are `nil`

## The Piece (Block)

- Every piece is a **2x2 square** composed of 4 cells, each independently colored A or B
- The piece can be **rotated** clockwise (90 degrees per press)
- The piece spawns at the top-center of the board
- The piece falls at a rate determined by **gravity** (increases with level/time)
- Player can **move left/right**, **soft drop** (accelerate), and **hard drop** (instant)

## Piece Queue

- A **queue of upcoming pieces** is visible (typically 3 next pieces shown)
- Pieces are generated randomly — each of the 4 cells is independently assigned A or B, giving 16 possible patterns (though symmetric rotations reduce effective uniqueness)

## Landing & Gravity

- When a piece lands (hits the floor or rests on existing blocks), it **locks** after a brief delay
- After locking, **gravity applies to all cells individually** — if any cell has empty space below it, it falls down until it rests on something. This means a 2x2 piece landing on an uneven surface can split apart.
- After gravity settles, the next piece spawns

## Square Detection

- After gravity settles, scan the board for **2x2 squares of the same color**
- Squares can **overlap** — a 2x3 area of same color contains two overlapping 2x2 squares
- Matched squares are **marked for clearing** but do NOT disappear yet

## The Timeline (Sweep Line)

- A vertical line sweeps left-to-right across the board at a constant tempo (tied to the music BPM in the original, but we'll make it configurable)
- When the sweep line **passes over** a marked square, those cells are **cleared** (removed)
- After clearing, gravity applies again — cells above cleared areas fall down
- After post-clear gravity, **re-scan for new squares** (chain reactions)
- The sweep line loops: when it reaches the right edge, it resets to the left

## Scoring

- Points are awarded for cleared squares
- **Bonus multipliers** for:
  - Multiple squares cleared in a single sweep pass
  - Chain reactions (new squares formed after gravity from a clear)
- Larger contiguous same-color areas that contain multiple overlapping 2x2 squares score more

## Game Over

- If a newly spawned piece **overlaps** existing blocks at the spawn point, the game is over

## Tick Model

The engine has two independent timers:
1. **Gravity tick** — moves the active piece down one row
2. **Sweep tick** — advances the timeline one column to the right

Both run concurrently. The sweep is continuous and independent of player actions.
