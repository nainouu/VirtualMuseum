extends Node3D

const maxDecals : int = 100
var decalCount : int = 0
@onready var impactRay: RayCast3D = $impactRay
@onready var gunModel = $gunModel
@onready var b_decal = preload("res://scence/splat.tscn")
var LineDrawer = preload("res://scripts/drawLine3D.gd").new() #In 'global' scope
var gunshot = preload("res://sounds/gunshot.ogg")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$gunPlayer.stream = gunshot
	add_child(LineDrawer) #At some point before calling the desired draw function(s) e.g. in '_ready()'


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func shoot():
	print("pew")
	
	if impactRay.is_colliding() and decalCount < maxDecals:
		decalCount += 1
		var collision = impactRay.get_collision_point()
		LineDrawer.DrawLine(gunModel.global_position, collision, Color(0.941176, 1, 0.941176, 1), 0.1)
		$gunPlayer.play()
		#spawnDecal(collision, collision.normalized())
		spawnDecal2(impactRay)
	
func spawnDecal(pos: Vector3, normal: Vector3):
	# TODO: fix: spawned decal gets squished on vertical surfaces
	
	
	var decal = Decal.new()
	var texture = preload("res://assets/textures/splat.png") as Texture2D
	decal.texture_albedo = texture
	decal.size = Vector3(0.3, 0.3, 0.3)


	# center decal (scaling not working)
	#pos.x -= texture.get_size().x * 0.5
	#pos.z -= texture.get_size().y * 0.5
	
	decal.global_transform.origin = pos
	decal.look_at(position + normal)
	
	get_tree().current_scene.add_child(decal)
	
func spawnDecal2(raycast: RayCast3D):
	var splat = b_decal.instantiate()
	if raycast:
		raycast.get_collider().add_child(splat)
		splat.global_transform.origin = raycast.get_collision_point()
		splat.look_at(raycast.get_collision_point() + raycast.get_collision_normal(), Vector3.UP)
		splat.rotate_object_local(Vector3(0, 0, 1), randf() * TAU)
		
		var min = 0.3
		var max = 1.0
		
		# Modify material color
		var r = randf_range(min, max)
		var g = randf_range(min, max)
		var b = randf_range(min, max)
		splat.get_child(0).modulate = Color(r, g, b)
	
