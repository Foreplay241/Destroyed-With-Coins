extends Node

const API_ENV_PATH = "res://Configs/env.cfg"
var loopring_api_key = ""
var score = 0
var anvils_caught = 0
var coins_caught = 0
var score_dict = {
	"Most Score": [0, 0, 0],
	"Most Anvils": [0, 0, 0],
	"Most Coins": [0, 0, 0],
}

# Called when the node enters the scene tree for the first time.
func _ready():
	# Read Loopring API key
	var env_config = ConfigFile.new()
	var err = env_config.load(API_ENV_PATH)
	if err == ERR_FILE_NOT_FOUND:
		printerr("env.cfg file is missing")
	elif err != OK:
		printerr("Error when attempting to load env.cfg")
	else:
		loopring_api_key = env_config.get_value("API_KEYS", "loopring")

func save_score():
	var file = File.new()
	file.open("user://hiscores.json", File.WRITE)
	file.store_var(score_dict)
	print(score_dict)
	file.close()

func load_score():
	var file = File.new()
	var err = file.open("user://hiscores.json", File.READ)
	if err != OK:
		print("error loading scores")
	else:
		score_dict = file.get_var()
	print(score_dict)
	file.close()
