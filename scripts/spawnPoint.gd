@tool
extends Node3D

@onready var SpawnpointName: Label3D = $"SpawnpointName"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#update_label_name()
	if !Engine.is_editor_hint():
		self.visible = false

func _notification(what):
	if !Engine.is_editor_hint():
		return

	if what == NOTIFICATION_EDITOR_POST_SAVE:
		if SpawnpointName and SpawnpointName.text != name:
			SpawnpointName.text = name

#func update_label_name():
	#if SpawnpointName:
		#SpawnpointName.text = self.name
