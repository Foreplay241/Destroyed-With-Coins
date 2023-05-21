extends Node2D

func _ready():
	$VBoxContainer/lblScore.text = String(Globals.score) + " score"
	$VBoxContainer/lblCoins.text = String(Globals.coins_caught) + " coins"
	$VBoxContainer/lblAnvils.text = String(Globals.anvils_caught) + " anvils"
	if Globals.score > Globals.score_dict["Most Score"][0]:
		Globals.score_dict["Most Score"] = [Globals.score, Globals.anvils_caught, Globals.coins_caught]
		Globals.save_score()
	if Globals.anvils_caught > Globals.score_dict["Most Anvils"][1]:
		Globals.score_dict["Most Anvils"] = [Globals.score, Globals.anvils_caught, Globals.coins_caught]
		Globals.save_score()
	if Globals.coins_caught > Globals.score_dict["Most Coins"][2]:
		Globals.score_dict["Most Coins"] = [Globals.score, Globals.anvils_caught, Globals.coins_caught]
		Globals.save_score()
#	Globals.load_score()
	var most_score_0 = "Score: " + String(Globals.score_dict["Most Score"][0])
	var most_score_1 = "Anvils: " + String(Globals.score_dict["Most Score"][1])
	var most_score_2 = "Coins: " + String(Globals.score_dict["Most Score"][2])
	var most_anvils_0 = "Score: " + String(Globals.score_dict["Most Anvils"][0])
	var most_anvils_1 = "Anvils: " + String(Globals.score_dict["Most Anvils"][1])
	var most_anvils_2 = "Coins: " + String(Globals.score_dict["Most Anvils"][2])
	var most_coins_0 = "Score: " + String(Globals.score_dict["Most Coins"][0])
	var most_coins_1 = "Anvils: " + String(Globals.score_dict["Most Coins"][1])
	var most_coins_2 = "Coins: " + String(Globals.score_dict["Most Coins"][2])
	
	$VBoxContainer/lblHiScore.text = most_score_0 + " " + most_score_1 + " " + most_score_2
	$VBoxContainer/lblHiAnvil.text = most_anvils_0 + " " + most_anvils_1 + " " + most_anvils_2
	$VBoxContainer/lblHiCoin.text = most_coins_0 + " " + most_coins_1 + " " + most_coins_2
	Globals.score = 0
	Globals.coins_caught = 0
	Globals.anvils_caught = 0



func _on_btnTryAgain_pressed():
	get_tree().change_scene("res://PlatformerExample/PlatformerScene.tscn")
	
func _on_btnChangeBoy_pressed():
	get_tree().change_scene("res://UI/CharacterSelectScreen.tscn")
