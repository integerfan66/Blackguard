## SolverScene.gd
## Attach this to the root node of your SolverScene.tscn.
## It wraps MinesweeperSolver and exposes a clean signal-based API
## so your game board can call it and receive results without coupling.
##
## ── How to use from your game ──────────────────────────────────────────────
##
##   # 1. Instance the scene (or add it as an AutoLoad / child node)
##   var solver_scene = preload("res://SolverScene.tscn").instantiate()
##   add_child(solver_scene)
##
##   # 2. Connect to the result signal
##   solver_scene.solve_completed.connect(_on_solve_completed)
##
##   # 3. Run the solver
##   solver_scene.solve(board_data)
##
##   # 4. Handle the result
##   func _on_solve_completed(result: MinesweeperSolver.SolveResult) -> void:
##       if result.is_solvable:
##           print("Board is solvable with no guesses!")
##       else:
##           print("Needs %d guess(es)" % result.guesses_needed)
##
## ── board_data format ──────────────────────────────────────────────────────
##   {
##     "width":    int,               # columns
##     "height":   int,               # rows
##     "mines":    Array[Vector2i],   # mine positions (0-indexed)
##     "revealed": Array[Vector2i],   # cells revealed at game start
##   }

class_name SolverScene
extends Node


# ── Signals ───────────────────────────────────────────────────────────────────

## Emitted when analysis finishes. result contains all solve information.
signal solve_completed(result: MinesweeperSolver.SolveResult)

## Emitted with progress updates (useful for large boards that take time).
signal solve_progress(message: String)


# ── Exports (tweak in the Inspector) ─────────────────────────────────────────

## When true, the solver runs on a background thread so it won't freeze the game.
@export var use_thread: bool = true

## Maximum recursion depth for guess search (limits solve time on hard boards).
## Raise this for thorough analysis; lower for faster (but less precise) results.
@export var max_guess_depth: int = 3


# ── Private ───────────────────────────────────────────────────────────────────

var _solver: MinesweeperSolver
var _thread: Thread
var _mutex: Mutex
var _pending_result: MinesweeperSolver.SolveResult


func _ready() -> void:
	_solver = MinesweeperSolver.new()
	_solver.max_guess_depth = max_guess_depth
	_mutex = Mutex.new()


func _process(_delta: float) -> void:
	# Flush thread result on main thread
	if _pending_result != null:
		_mutex.lock()
		var result := _pending_result
		_pending_result = null
		_mutex.unlock()
		solve_completed.emit(result)
		if _thread and _thread.is_started():
			_thread.wait_to_finish()


func _exit_tree() -> void:
	if _thread and _thread.is_started():
		_thread.wait_to_finish()


# ── Public API ────────────────────────────────────────────────────────────────

## Analyse the given board. Emits solve_completed when done.
## Safe to call multiple times; cancels any running analysis first.
func solve(board_data: Dictionary) -> void:
	_validate_board(board_data)

	if use_thread:
		if _thread and _thread.is_started():
			_thread.wait_to_finish()
		_thread = Thread.new()
		_thread.start(_thread_solve.bind(board_data))
	else:
		var result := _solver.analyze(board_data)
		solve_completed.emit(result)


## Synchronous version — blocks until done and returns the result directly.
## Use this in editor tooling or when threading is not desired.
func solve_sync(board_data: Dictionary) -> MinesweeperSolver.SolveResult:
	_validate_board(board_data)
	return _solver.analyze(board_data)


# ── Helpers ───────────────────────────────────────────────────────────────────

func _thread_solve(board_data: Dictionary) -> void:
	var result := _solver.analyze(board_data)
	_mutex.lock()
	_pending_result = result
	_mutex.unlock()


func _validate_board(board_data: Dictionary) -> void:
	assert(board_data.has("width"),    "board_data missing 'width'")
	assert(board_data.has("height"),   "board_data missing 'height'")
	assert(board_data.has("mines"),    "board_data missing 'mines'")
	assert(board_data.has("revealed"), "board_data missing 'revealed'")
	assert(board_data["width"]  > 0,   "board width must be > 0")
	assert(board_data["height"] > 0,   "board height must be > 0")
