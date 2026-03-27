extends CharacterBody3D

# Lấy các node cần thiết
@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var weapon_holder = $Head/Camera3D/Node3D/weapon_holder
@onready var the_heart = $Head/Camera3D/the_heart
@onready var raycast = $Head/Camera3D/RayCast3D

# Load hiệu ứng máu
const BLOOD_PARTICLES = preload("res://scenes/effect/BloodParticles/blood_particles.tscn")

const SWAY_AMOUNT = 0.1
const SWAY_LERP = 5.0
const SPEED = 8.0
const JUMP_VELOCITY = 4.5
const SENSITIVITY = 0.003 # Độ nhạy chuột

# Biến trọng lực
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-80), deg_to_rad(80))

func _physics_process(delta):
	# Trọng lực
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Nhảy
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Di chuyển WASD
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		
	# Weapon Sway
	var mouse_mov = Input.get_last_mouse_velocity()
	weapon_holder.position.x = lerp(weapon_holder.position.x, -mouse_mov.x * SWAY_AMOUNT / 1000, SWAY_LERP * delta)
	weapon_holder.position.y = lerp(weapon_holder.position.y, mouse_mov.y * SWAY_AMOUNT / 1000, SWAY_LERP * delta)

	# XỬ LÝ CHẶT CHÉM
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		# Rung máy cưa
		weapon_holder.position.x += randf_range(-0.01, 0.01)
		weapon_holder.position.y += randf_range(-0.01, 0.01)
		
		if raycast.is_colliding():
			var target = raycast.get_collider()
			if target.is_in_group("enemies"):
				# 1. Bắn máu tung tóe tại điểm va chạm
				var blood = BLOOD_PARTICLES.instantiate()
				get_tree().current_scene.add_child(blood)
				blood.global_position = raycast.get_collision_point()
				
				# 2. Rung màn hình (Screen Shake)
				camera.h_offset = randf_range(-0.02, 0.02)
				camera.v_offset = randf_range(-0.02, 0.02)
				
				# 3. Đẩy lùi quái
				var push_direction = -raycast.get_collision_normal()
				if target is CharacterBody3D:
					target.velocity = push_direction * 5.0
					target.move_and_slide()
				
				print("ĐANG CƯA THỊT QUÁI!")
		
		# Nhịp đập trái tim khi chiến đấu
		var fast_pulse = 1.0 + sin(Time.get_ticks_msec() * 0.02) * 0.15
		the_heart.scale = Vector3(fast_pulse, fast_pulse, fast_pulse)
		if the_heart.get_active_material(0):
			the_heart.get_active_material(0).albedo_color = Color(1, 0, 0)
	else:
		# Trạng thái Idle
		camera.h_offset = 0
		camera.v_offset = 0
		weapon_holder.position.y += sin(Time.get_ticks_msec() * 0.05) * 0.0005
		weapon_holder.position.x += cos(Time.get_ticks_msec() * 0.05) * 0.0005
		
		var slow_pulse = 1.0 + sin(Time.get_ticks_msec() * 0.005) * 0.05
		the_heart.scale = Vector3(slow_pulse, slow_pulse, slow_pulse)
		if the_heart.get_active_material(0):
			the_heart.get_active_material(0).albedo_color = Color(0.5, 0, 0)

	move_and_slide()
