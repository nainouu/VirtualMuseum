extends CharacterBody3D


#
# Character Interactivity controller for player input
#
#


@onready var head: Node3D = $head
@onready var camera_3d: Camera3D = $head/Camera3D
@onready var raycastHead: RayCast3D = $head/Camera3D/RayCastHead
@onready var raycastFeet: RayCast3D = $RayCastFeet
@onready var gun: Node3D = $head/Camera3D/Gun
@onready var gunmodel = $"../player/head/Camera3D/Gun/Blaster"
@onready var cameraGUI = $"../player/CanvasLayer/Cameraframe" # prev: $"../stage/misc/Cameraframe"
@onready var jetpackInfoLabel: Label = $"../player/CanvasLayer/jetpackInfo" # this is a placeholder for jetpack firstperson model

var currentSpeed = 5.0
var lookRotation = Vector2()
var cameraRotation : bool = true
var captureMouse : bool = true
var enableMovement : bool = true
const WALK_SPEED = 5.0
const SPRINT_SPEED = 20.0
const JUMP_VELOCITY = 4.5
const MOUSE_SENS = 0.003
const CAMERA_NORMAL = 70
const CAMERA_ZOOM = 20
const JETPACK_VELOCITY = 5.0
var JETPACK_ACCELERATION = 1.3

var equippedItem = null #currently equipped item eg: jetpack

# Adding new footstep sounds:
#	- add new metadata to a surface:
#	- name: "surfaceType" value: string
#	- values are taken from below
#	- add the sound effect to res/sounds
var footstepSounds = {
	"grass": preload("res://sounds/footstep_grass.ogg"),
	"dirt": preload("res://sounds/footstep_dirt.ogg"),
	"stone": preload("res://sounds/footstep_stone.ogg"),
	"default": preload("res://sounds/footstep_default.ogg")
	#"wood": preload("res://sounds/footstep_wood1.ogg"),
}

# Timers
var footstepTimer = 0.0
var footstepInterval = 0.4
var gunTimer = 0.0
var shootInterval = 0.1


func _ready() -> void:
	
	print("Player.gd init")
	
	assert(cameraGUI, "cameraGUI null")
	assert(gunmodel, "gunModel null")
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	 #Set camera FOV to harmonize with the constants, sanity check the GUI
	#
	cameraGUI.visible = false

	camera_3d.fov = CAMERA_NORMAL
	jetpackInfoLabel.visible = false
	gunmodel.visible = false
	
	#lookRotation.x -= event.relative.x * MOUSE_SENS
	#lookRotation.y -= event.relative.y * MOUSE_SENS
	#lookRotation.y = clamp(lookRotation.y, -1.5, 1.5)  # Prevent flipping
	
	
	



#func _input(event):
#	if event is InputEventMouseMotion:
#		rotation.y += (-event.relative.x * MOUSE_SENS)
#		rotation.x += (-event.relative.y * MOUSE_SENS)
#		rotation.x = clamp(rotation.x, -90, 90)
#	
#	if event.is_action_pressed("ui_cancel"):
#		get_tree().quit()

func _input(event):
	if event is InputEventMouseMotion and cameraRotation:
		rotate_y(-event.relative.x * MOUSE_SENS)
		camera_3d.rotate_x(-event.relative.y * MOUSE_SENS)
		camera_3d.rotation.x = clampf(camera_3d.rotation.x, -deg_to_rad(70), deg_to_rad(70))


	#if event.is_action_pressed("ui_cancel"):
		#get_tree().quit()
		
	# show mouse cursor and lock camera
	if Input.is_key_pressed(KEY_G):
		if captureMouse:
			captureMouse = false
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			cameraRotation = false
		else:
			captureMouse = true
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			cameraRotation = true
		
	# ::shoot
	gunTimer -= get_process_delta_time() # this is delta
	if equippedItem and equippedItem.get_name() == "gun":
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			if gunTimer <= 0.0:
				#TODO: fix: gun audio plays even if game is "paused"
				gun.shoot()
				gunTimer = shootInterval


func _physics_process(delta: float) -> void:
	
	# raycast head  ::interact
	if Input.is_action_just_pressed("interact"):
		if raycastHead.is_colliding():
			var hit = raycastHead.get_collider()
			var parent = hit.get_parent()
			
			# TODO: make this faster
			var current = hit
			var door = null
			while current != null:
				if current.has_method("toggle_door"):
					door = current
					break
				current = current.get_parent()
				
			if door:
				door.toggle_door()
				# TODO: play soundeffect for door
				
			# ::jetpack interact
			if parent.get_name() == "jetpack":
				equippedItem = parent
				#parent.queue_free()
				jetpackInfoLabel.visible = true
				gunmodel.visible = false
				
			# ::gun interact
			elif parent.get_name() == "gun":
				equippedItem = parent
				gunmodel.visible = true
				jetpackInfoLabel.visible = false
				
	# ::unequip all
	if equippedItem and Input.is_key_pressed(KEY_R):
		jetpackInfoLabel.visible = false
		gunmodel.visible = false
		equippedItem = null
	
	if Input.is_action_pressed("sprint"):
		currentSpeed = SPRINT_SPEED
	else:
		currentSpeed = WALK_SPEED
		
	var isMoving = velocity.length() > 0.1
	
	# ::jetpack
	if equippedItem and equippedItem.get_name() == "jetpack":
		if Input.is_action_pressed("ui_accept"):
			velocity.y = JETPACK_VELOCITY * JETPACK_ACCELERATION
			JETPACK_ACCELERATION *= 1.01
			#print(JETPACK_ACCELERATION)
		else:
			JETPACK_ACCELERATION = 1.3
	
	# footstep timer
	if isMoving and is_on_floor():
		footstepTimer -= delta * (currentSpeed * 0.2)
		if footstepTimer <= 0.0:
			play_footstep()
			footstepTimer = footstepInterval
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		
 #Handle camera GUI (#todo Sprite dimensions).
	if Input.is_action_just_pressed("photomode"):
		if cameraGUI.visible:
			camera_3d.fov = CAMERA_NORMAL
			cameraGUI.visible = false 
			
		else:
			camera_3d.fov = CAMERA_ZOOM
			cameraGUI.visible = true
#endregion

	if enableMovement:
		# Get the input direction and handle the movement/deceleration.
		# As good practice, you should replace UI actions with custom gameplay actions.
		var input_dir := Input.get_vector("left", "right", "forward", "backward")
		var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if direction:
			velocity.x = direction.x * currentSpeed
			velocity.z = direction.z * currentSpeed
		else:
			velocity.x = move_toward(velocity.x, 0, currentSpeed)
			velocity.z = move_toward(velocity.z, 0, currentSpeed)

		move_and_slide()

func play_footstep():
	# TODO: fix: footsteps wont play sometimes. Might need to jump
	# to get them working
	
	if raycastFeet and not raycastFeet.is_colliding():
		return
		
	var collider = raycastFeet.get_collider()
	var surface_type = "default"

	if collider and collider.has_meta("surfaceType"):
		surface_type = collider.get_meta("surfaceType")
		
	#print("Playing footstep sound: ", surface_type)

	# get the correct footstep sound based on the surfaceType
	var stream = footstepSounds.get(surface_type, footstepSounds["default"])
	if stream is Array:
		stream = stream[randi() % stream.size()]

	# set and play sound
	$FootstepPlayer.stream = stream
	$FootstepPlayer.play()
