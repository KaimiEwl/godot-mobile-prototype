extends SceneTree


func _init() -> void:
	call_deferred("_run_validation")


func _run_validation() -> void:
	var scene: PackedScene = load("res://scenes/Main.tscn")
	var game: Node = scene.instantiate()
	root.add_child(game)
	await process_frame

	for i in range(10):
		game.call("_place_building", i, i)

	await process_frame

	var placed: Dictionary = game.get("placed")
	var income: float = float(game.call("_get_income_per_hour"))
	if placed.size() != 10:
		push_error("Expected 10 placed buildings, got %d." % placed.size())
		quit(1)
		return
	if income <= 0.0:
		push_error("Income did not accumulate.")
		quit(1)
		return

	print("VALIDATION_OK buildings=%d income_per_hour=%s" % [placed.size(), game.call("_format_amount", income)])
	quit(0)
