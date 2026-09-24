extends CharacterBody2D

var movespeed = 500
var bullet = preload("res://scenes/minigameScenes/bullet.tscn")

func _physics_process(delta: float) -> void:
	var motion = Vector2.ZERO

	if Input.is_action_pressed("up"):
		motion.y -= 1
	if Input.is_action_pressed("down"):
		motion.y += 1
	if Input.is_action_pressed("right"):
		motion.x += 1
	if Input.is_action_pressed("left"):
		motion.x -= 1

	motion = motion.normalized()
	velocity = motion * movespeed
	move_and_slide()
	look_at(get_global_mouse_position())
	
	if Input.is_action_just_pressed("click"):
		fire()
	
func fire() -> void:
	var bullet_instance = bullet.instantiate()
	bullet_instance.global_position = global_position
	bullet_instance.direction = Vector2.RIGHT.rotated(rotation)
	bullet_instance.shooter = self
	get_parent().add_child(bullet_instance)
	
func kill() -> void:
	# Restartujemy tylko lokalny świat shootera (get_parent()), nie całą grę —
	# ważne, gdy ta scena jest osadzona jako minigierka wewnątrz innej sceny.
	var world = get_parent()
	var world_parent = world.get_parent()
	var fresh_world = load("res://scenes/minigameScenes/shooter_game.tscn").instantiate()
	world.call_deferred("queue_free")
	world_parent.call_deferred("add_child", fresh_world)


func _on_area_2d_body_entered(body: Node2D) -> void:
	if "Enemy" in body.name:
		kill()
