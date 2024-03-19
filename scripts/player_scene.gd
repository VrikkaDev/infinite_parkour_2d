extends CharacterBody2D


const SPEED = 250.0
const MAX_SPEED = 100000

const DAMAGE_COOLDOWN = 0.5 # in seconds
const HEAL_TIME = 4 # time it takes for the player to heal when not damaged in seconds
const JUMP_VELOCITY = -400.0

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# player vars
var looking_dir = 1 # 1: right, -1: left
var health = 100
var is_alive = true

var since_last_damage = 0 # in seconds

var touching_tilemap: TileMap = null
var parkour_tilescene

# for animations
var _is_anim_falling = false
var _is_anim_death = false

func _ready():
	parkour_tilescene = get_parent().get_node("ParkourTileScene")
	pass

func _enter_tree():
	set_multiplayer_authority(name.to_int())
	if not is_multiplayer_authority():
		remove_child($Camera2D)

func _damage(damage = 25):

	if since_last_damage <= DAMAGE_COOLDOWN:
		return

	var bounce = 500
	var damage_x_momentum = ((randi() % 2)*2-1)*bounce # -bounce or bounce

	# make it so if touching sideways. you bounce away
	var right = move_and_collide(Vector2i.RIGHT, true)
	var left = move_and_collide(Vector2i.LEFT, true)

	if right:
		damage_x_momentum = -bounce
	elif left:
		damage_x_momentum = bounce

	velocity.y = JUMP_VELOCITY / 1.25  # laava upwards momentum
	velocity.x = damage_x_momentum # sideways

	health -= damage

	# cap it so health doesnt go under 0
	health = max(0, health)

	_update_healthbar()

	since_last_damage = 0

	if health <= 0:
		if is_alive:
			# start respawinng timer
			var timer = $RespawnTimer
			timer.start()
		is_alive = false
		return

	move_and_slide()

func _update_healthbar():
	# set healthbar
	$Hud/HealthBar.set_frame(floor(float(health)/25))

func _process_touching_tiledata(tiledata: TileData):
	if tiledata.get_custom_data("is_lava"):
		_damage()

func _check_touching_tiledata():
	# check all directions
	var directions = [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]

	for direction in directions:
		var collision = move_and_collide(direction, true)
		if collision:
			var tile_pos = touching_tilemap.local_to_map(position/2) + direction
			var tile_data = touching_tilemap.get_cell_tile_data(0, tile_pos)
			if tile_data != null:
				_process_touching_tiledata(tile_data)
	
	# check corners
	var corners = [Vector2(13, 30), Vector2(-13, 30), Vector2(13, -35), Vector2(-13, -35)]

	for corner in corners:
		var collision = move_and_collide(corner, true)
		if collision:
			var pos = (position+corner)/2
			var tile_pos = touching_tilemap.local_to_map(pos)
			var tile_data = touching_tilemap.get_cell_tile_data(0, tile_pos)
			if tile_data != null:
				_process_touching_tiledata(tile_data)

func _physics_process(delta):

	if not is_multiplayer_authority():
		return

	since_last_damage += delta

	var vel = Vector2.ZERO

	# tilemapdata touchinglogic
	if touching_tilemap != null:
		_check_touching_tiledata()

	parkour_tilescene.update_with_position(position)

	# heal
	if since_last_damage >= HEAL_TIME and health < 100:
		health = 100
		_update_healthbar()

	# jumping
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# gravity
	if not is_on_floor():
		if Input.is_action_pressed("jump") and velocity.y <= 0:
			velocity.y += gravity / 2 * delta
		else: 
			velocity.y += gravity * delta
	else:
		_is_anim_falling = false

	# moving and slowing down
	var direction = Input.get_axis("left", "right")
	if direction and since_last_damage >= DAMAGE_COOLDOWN/2:
		vel.x = direction * SPEED
		looking_dir = direction
	else:
		vel.x = move_toward(velocity.x, 0, SPEED*8*delta)

	# Animationns

	# flip spritt
	$Sprite2D.flip_h = looking_dir == -1

	# Idle and walking
	if velocity.y == 0 and since_last_damage > 1 and is_alive:
		if velocity.x == 0 and is_on_floor():
			$AnimationPlayer.play("Idle")
		elif is_alive:
			$AnimationPlayer.play("Moving")
	
	# Falling and jumping
	if velocity.y >= 0 and is_alive and not is_on_floor():
		if $AnimationPlayer.current_animation != "Falling" and not _is_anim_falling:
			_is_anim_falling = true
			$AnimationPlayer.play("Falling")
	elif not is_on_floor() and is_alive:
		$AnimationPlayer.play("Jumping")
	
	# DEATH
	if not is_alive and $AnimationPlayer.current_animation != "Death" and not _is_anim_death:
		_is_anim_death = true
		$AnimationPlayer.play("Death")

	var zoom_in = Input.is_action_just_pressed("zoom_in")
	var zoom_out = Input.is_action_just_pressed("zoom_out")
	if zoom_in:
		$Camera2D.zoom += Vector2(0.2, 0.2)
	elif zoom_out:
		$Camera2D.zoom -= Vector2(0.2, 0.2)

	velocity.x = vel.x
	var delta_max_speed = MAX_SPEED * delta
	velocity.x = clamp(velocity.x, -delta_max_speed, delta_max_speed)
	if is_alive:
		move_and_slide()

func spawn_player():
	print("Spawning player")

	_is_anim_death = false
	is_alive = true
	health = 100
	since_last_damage = 0
	_update_healthbar()

	position = Vector2.ZERO
	velocity = Vector2.ZERO
	move_and_slide()


func _on_area_2d_body_entered(body: Node2D):
	if is_instance_of(body, TileMap):
		touching_tilemap = body



func _on_area_2d_body_exited(body: Node2D):
	if is_instance_of(body, TileMap):
		touching_tilemap = null

func _on_respawn_timer_timeout():
	spawn_player()
