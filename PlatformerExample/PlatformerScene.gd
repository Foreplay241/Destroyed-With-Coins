extends Node2D

onready var metaboy_character = $MetaBoyPlatformer
onready var game_bg = $Background
var coin_scene = preload("res://PlatformerExample/Coin.tscn")
var anvil_scene = preload("res://PlatformerExample/Anvil.tscn")
var rng = RandomNumberGenerator.new()
var score = 0


func _ready():
	# Set the MetaBoy character to the one the player selected.
	metaboy_character.set_attributes(MetaBoyGlobals.selected_metaboy.get_attributes_as_dictionary())
	rng.randomize()
	set_bg()
	
func _process(delta):
	if $Control/healthBar.value <= 0:
		get_tree().change_scene("res://PlatformerExample/DeadScene.tscn")
	if Input.is_action_just_pressed("pause"):
		get_tree().paused = true
		$Control/btnResume.show()
	
func set_bg():
	$Background.frame = randi() % 12
	
func _on_ExitButton_pressed():
	get_tree().change_scene("res://UI/LoginScreen.tscn")

func spawn_coin():
	var coin_inst = coin_scene.instance()
	coin_inst.position.x = rng.randi() % 500
	add_child(coin_inst)
	
func spawn_anvil():
	var anvil_inst = anvil_scene.instance()
	anvil_inst.position.x = rng.randi() % 500
	add_child(anvil_inst)
	
func increase_score(amount):
	Globals.score += amount
	if amount >= 6:
		Globals.score += (100 - $Control/healthBar.value) * (randi() % amount + 10)
	$Control/scoreLabel.text = "Score: " + String(Globals.score)
	
func change_health(amount):
	$Control/healthBar.value += amount

func _on_Timer_timeout():
	spawn_anvil()
	spawn_coin()


func _on_btnResume_pressed():
	get_tree().paused = false
	print(get_tree().paused)
	$Control/btnResume.hide()
