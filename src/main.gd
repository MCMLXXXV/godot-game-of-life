extends MarginContainer


func _ready() -> void:
	$GameOfLife.populate()
	$Timer.paused = true


func _on_actions_action_requested(action_id: StringName, params: Dictionary) -> void:
	match action_id:
		&"animate":
			var animate: bool = params.get("animate", false)
			$Timer.paused = animate
			%Cursor.visible = animate
		&"clear":
			$Timer.paused = true
			$GameOfLife.clear()
		&"interval":
			var interval: float = params.get("interval", 0.1)
			$Timer.start(interval)
		&"populate":
			var bias: float = params.get("bias", 0.2)
			$Timer.paused = true
			$GameOfLife.populate(bias)
		&"step":
			$GameOfLife.evolve()


func _on_game_of_life_updated(cells: Array[bool], stats: Dictionary) -> void:
	for i in len(cells):
		var point: Vector2i = $GameOfLife.get_cell_point(i)
		var tile := Vector2i.RIGHT if cells[i] else Vector2i.ZERO
		%Grid.set_cell(point, 0, tile)
	%Actions.set_generation(stats.generation)
	%Actions.set_population(stats.population, stats.population_percent)


func _on_sub_viewport_container_gui_input(event: InputEvent) -> void:
	if event.is_echo() or not $Timer.paused:
		return
	var point: Vector2i = %Grid.local_to_map(%Grid.get_local_mouse_position())
	if event is InputEventMouseMotion and $GameOfLife.has_point(point):
		%Actions.set_cursor(point)
		%Cursor.position = %Grid.map_to_local(point) * %Grid.scale
	if event is InputEventMouseButton and event.is_action_released("ui_left_mouse_button"):
		$GameOfLife.toggle($GameOfLife.get_cell_index(point))
