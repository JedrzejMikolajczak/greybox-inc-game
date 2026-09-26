extends CharacterBody2D

func _physics_process(delta: float) -> void:
	var player = get_parent().get_node("Player")

	position += (player.position - position) / 200
	look_at(player.position)

func die() -> void:
	GameState.goon_points += GameState.goon_points_per_kill
	queue_free()
