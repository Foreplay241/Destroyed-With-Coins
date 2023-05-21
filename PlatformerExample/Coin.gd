extends Node2D
onready var audio = $AudioStreamPlayer

func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	position.y += 2
	if position.y >= 500:
		queue_free()


func _on_Coin_body_entered(body):
	if body.name == "MetaBoyPlatformer":
		$catch.play()

func _on_catch_finished():
	var coin_value = randi() % 3 + 1
	var multi_value = randi() % 3 + 1 
	get_parent().increase_score(coin_value * multi_value)
	get_parent().change_health(coin_value * multi_value)
	Globals.coins_caught += 1
	queue_free()
