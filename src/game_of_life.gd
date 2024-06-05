## Interactive Conway's "Game of Life" simulation, implemented as an array of cells.
extends Node

## Emitted when the grid's state changes.
signal updated(cells: Array[bool], stats: Dictionary)

## The points of neighbor cells relative to any given cell on the grid.
const NEIGHBORS: Array[Vector2i] = [
	Vector2i.UP + Vector2i.LEFT,
	Vector2i.UP,
	Vector2i.UP + Vector2i.RIGHT,
	Vector2i.LEFT,
	Vector2i.RIGHT,
	Vector2i.DOWN + Vector2i.LEFT,
	Vector2i.DOWN,
	Vector2i.DOWN + Vector2i.RIGHT,
]

## How tall the grid should be.
@export_range(10, 80, 1, "suffix:rows")
var grid_height: int = 10

## How wide the grid should be.
@export_range(10, 144, 1, "suffix:columns")
var grid_width: int = 10

var _cells: Array[bool] = []
var _generation: int = 0
var _rng := RandomNumberGenerator.new()

@onready
var _grid_bounds := Rect2i(0, 0, grid_width, grid_height)


func _ready() -> void:
	_cells.resize(grid_height * grid_width)
	_rng.randomize()


## Clears live cells, leaving the grid blank.
func clear() -> void:
	_cells.fill(false)
	_generation = 1
	_emit_updated()


## Evolves the population to the next generation.
func evolve() -> void:
	var result: Array[bool] = _cells.duplicate()
	for i in grid_height * grid_width:
		# Count neighbor cells.
		var neighbors := 0
		for offset in NEIGHBORS:
			neighbors += int(_cells[posmod(grid_width * offset.y + offset.x + i, grid_height * grid_width)])
		# Apply the Game of Life rules:
		# 1. Any live cell with fewer than 2 live neighbors dies (underpopulation).
		# 2. Any live cell with 2 or 3 live neighbors lives on to the next generation.
		# 3. Any live cell with more than 3 live neighbors dies (overpopulation).
		# 4. Any dead cell with exactly 3 live neighbors becomes a live cell (reproduction).
		result[i] = _cells[i] and neighbors == 2 or neighbors == 3  # It's just that...!
	_cells = result
	_generation += 1
	_emit_updated()


## Returns the point of a given cell, or Vector2i(-1, -1) if [param index] is out-of-bounds.
func get_cell_point(index: int) -> Vector2i:
	@warning_ignore("integer_division")
	return Vector2i(index % grid_width, index / grid_width) if _is_index_within_bounds(index) else -Vector2i.ONE


## Returns the index of a point on the grid, or -1 if [param point] is out-of-bounds.
func get_cell_index(point: Vector2i) -> int:
	return grid_width * point.y + point.x if _grid_bounds.has_point(point) else -1


## Checks whether a [param point] is inside the grid.
func has_point(point: Vector2i) -> bool:
	return _grid_bounds.has_point(point)


## Generates the first generation of cells, with an approximate [param rate] of live cells on the grid.
func populate(rate: float = 0.25) -> void:
	for i in grid_height * grid_width:
		_cells[i] = _rng.randf() <= rate
	_generation = 1
	_emit_updated()


## Alternates the state of any given cell on the grid.
func toggle(index: int) -> void:
	if _is_index_within_bounds(index):
		_cells[index] = not _cells[index]
		_emit_updated()


func _emit_updated() -> void:
	var population: int = _cells.reduce(func(sum: int, cell: bool): return sum + int(cell), 0)
	var population_percent := 1.0 * population / (grid_height * grid_width)
	updated.emit(_cells, {
		generation = _generation,
		population = population,
		population_percent = population_percent,
	})


func _is_index_within_bounds(index: int) -> bool:
	return index >= 0 and index < grid_height * grid_width
