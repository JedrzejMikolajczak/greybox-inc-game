extends Area2D

const SPEED = 2000.0
const MAX_DISTANCE = 3000.0

var direction := Vector2.RIGHT
var shooter: Node2D = null
var traveled := 0.0

func _physics_process(delta: float) -> void:
	var motion = direction * SPEED * delta
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, global_position + motion)
	if shooter:
		query.exclude = [shooter.get_rid()]
	var result = space_state.intersect_ray(query)

	if result:
		var hit = result.collider
		if hit.has_method("die"):
			hit.die()
		queue_free()
		return

	global_position += motion
	rotation = direction.angle()
	traveled += motion.length()
	if traveled > MAX_DISTANCE:
		queue_free()
