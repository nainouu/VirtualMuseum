extends Node


var randomNumber = RandomNumberGenerator.new()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print_debug(randomNumber)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
