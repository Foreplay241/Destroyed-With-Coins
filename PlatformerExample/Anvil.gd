extends Node2D

func _ready():
	pass

func _process(delta):
	position.y += 2
	if position.y >= 500:
		queue_free()
	
func _on_Anvil_body_entered(body):
	if body.name == "MetaBoyPlatformer":
		$catch.play()

func _on_catch_finished():
	var anvil_size = randi() % 5 + 3
	var anvil_value = randi() % 6 + 2
	get_parent().increase_score(anvil_size * anvil_value)
	get_parent().change_health(-anvil_size * anvil_value)
	Globals.anvils_caught += 1
	queue_free()
