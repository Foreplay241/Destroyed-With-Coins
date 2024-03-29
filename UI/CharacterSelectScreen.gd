extends Node2D

const MetaBoyDisplay = preload("res://MetaBoy/MetaBoyDisplay.tscn")

onready var tab_container = $UI/TabContainer

onready var metaboy_tab = $"UI/TabContainer/OG Collection"
onready var metaboy_grid = $"%MetaBoyGrid"
onready var no_metaboy_label = $"%NoMetaBoyLabel"

onready var metaboy_stx_tab = $"UI/TabContainer/STX Collection"
onready var metaboy_stx_grid = $"%MetaBoySTXGrid"
onready var no_metaboy_stx_label = $"%NoMetaBoySTXLabel"

onready var loading_bg = $FrontLayer/LoadingBg
onready var loading_label = $FrontLayer/LoadingLabel

var account_object : Dictionary = {}
onready var num_metaboys = 0
onready var num_stx_metaboys = 0

func _ready():
	no_metaboy_label.hide()
	no_metaboy_stx_label.show()
	
	if not LoopringGlobals.wallet.empty():
		if MetaBoyGlobals.user_nfts_loopring.empty():
			# Attempt to fetch user's NFTs
			yield(get_loopring_account(), "completed")
			yield(get_metaboy_tokens(), "completed")
		else:
			_parse_metaboy_nfts(MetaBoyGlobals.user_nfts_loopring)
	
	if not StacksGlobals.wallet.empty():
		if MetaBoyGlobals.user_nfts_stacks.empty():
			# Attempt to fetch user's NFTs
			yield(get_stx_metaboy_tokens(), "completed")
		else:
			_parse_stx_metaboy_nfts(MetaBoyGlobals.user_nfts_stacks)
	
	if num_metaboys == 0:
		no_metaboy_label.show()
	else:
		no_metaboy_label.queue_free()
	
	loading_bg.hide()
	loading_label.hide()
	
	_focus_first_grid_element()

func _process(delta):
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().change_scene("res://UI/LoginScreen.tscn")
	
	if loading_bg.visible:
		# No navigation handling while loading data
		return
	
	if Input.is_action_just_pressed("ui_focus_prev"):
		if tab_container.current_tab > 0:
			tab_container.current_tab -= 1
	elif Input.is_action_just_pressed("ui_focus_next"):
		if tab_container.current_tab < tab_container.get_tab_count() - 1:
			tab_container.current_tab += 1

func _on_metaboy_selected(metaboy: MetaBoyData) -> void:
	MetaBoyGlobals.selected_metaboy = metaboy
	get_tree().change_scene("res://UI/CharacterDisplayScreen.tscn")

func get_loopring_account() -> void:
	var json = Loopring.get_account_object(LoopringGlobals.wallet)
	if json is GDScriptFunctionState:
		json = yield(json, "completed")
	account_object = json.result

func get_metaboy_tokens() -> void:
	var token_address = MetaBoyGlobals.CONTRACT_OG
	var account_id = str(account_object.get("accountId"))
	# To avoid triggering the API limits, fetch 50 tokens at a time.
	var json = Loopring.get_token_balance(account_id, Globals.loopring_api_key, token_address, false, 50)
	
	if json is GDScriptFunctionState:
		json = yield(json, "completed")
	
	var response_object = json.result
	if response_object.has("data"):
		var tokens : Array = response_object.get("data")
		
		var total_tokens : int = response_object.get("totalNum", 0)
		if tokens.empty():
			# No MetaBoys found
			MetaBoyGlobals.user_nfts_loopring = []
			return
		elif total_tokens > 50:
			var num_calls = int(floor(total_tokens / 50))
			for i in range(1, num_calls + 1):
				var json_next_batch = Loopring.get_token_balance(account_id, Globals.loopring_api_key, token_address, false, 50, i * 50)
				if json_next_batch is GDScriptFunctionState:
					json_next_batch = yield(json_next_batch, "completed")
				var response_object_next_batch = json_next_batch.result
				if response_object_next_batch.has("data"):
					var tokens_next_batch : Array = response_object_next_batch.get("data")
					for token in tokens_next_batch:
						tokens.append({"nftId": token.get("nftId")})
		
		MetaBoyGlobals.user_nfts_loopring = tokens
		_parse_metaboy_nfts(tokens)
	else:
		# No MetaBoys found
		MetaBoyGlobals.user_nfts_loopring = []

func _parse_metaboy_nfts(tokens: Array) -> void:
	if tokens.empty():
		return
	
	# Loop through each dictionary of attributes for each MetaBoy and set
	# the corresponding values.

	# Mapping from token address to ID is saved locally
	var metadata_mapping = null
	if MetaBoyGlobals.og_token_id_map_json.empty():
		metadata_mapping = MetaBoyGlobals.load_og_token_id_map_json()
		if metadata_mapping is GDScriptFunctionState:
			metadata_mapping = yield(metadata_mapping, "completed")
	else:
		metadata_mapping = MetaBoyGlobals.og_token_id_map_json
	
	# Metadata is saved locally
	var metadata = null
	if MetaBoyGlobals.og_metadata_json.empty():
		metadata = MetaBoyGlobals.load_og_metadata_json()
		if metadata is GDScriptFunctionState:
			metadata = yield(metadata, "completed")
	else:
		metadata = MetaBoyGlobals.og_metadata_json
	
	var first = true
	for token in tokens:
		# Read the NFT metadata
		var nft_id_address = token.get("nftId") # Hex address of NFT
		var nft_id = MetaBoyGlobals.get_og_id_from_token(nft_id_address)
		
		if nft_id == -1:
			# Not part of the collection
			continue
		elif MetaBoyGlobals.is_iconic_og(nft_id):
			# TODO: iconics are unique and must be handled differently
			continue
		
		if metadata != null and metadata_mapping != null:
			var formatted_name = "MetaBoy\n#"
			
			var nft_properties = {}
			var nft_json_obj = MetaBoyGlobals.get_og_metadata_for_token(nft_id_address)
			if !nft_json_obj.empty():
				if nft_json_obj.has("Id") and nft_json_obj.has("Traits"):
					formatted_name += str(nft_json_obj["Id"])
					var attributes : Array = nft_json_obj["Traits"]
					for attribute in attributes:
						var trait = attribute["TraitType"]
						var value = attribute["TraitValue"]
						nft_properties[trait] = value
					var metaboy_display = _add_metaboy_entry(formatted_name, nft_properties, MetaBoyGlobals.Collection.OG)
					if first:
						first = false
						metaboy_display.select()
					num_metaboys += 1

func get_stx_metaboy_tokens() -> void:
	var json = Stacks.get_account_balance(StacksGlobals.wallet)
	
	if json is GDScriptFunctionState:
		json = yield(json, "completed")
	
	var account_balance = json.result
	
	# Fetch the user's NFTs
	if account_balance.has("non_fungible_tokens"):
		var token_collections : Dictionary = account_balance.get("non_fungible_tokens")
		
		if token_collections.empty():
			# No STX collections found
			MetaBoyGlobals.user_nfts_stacks = []
			return
		
		var token_address = MetaBoyGlobals.CONTRACT_STX
		for key in token_collections:
			var collection_address = key.split(".")[0]
			if collection_address == token_address:
				var asset_identifiers = [key]
				# To avoid triggering the API limits, fetch 50 tokens at a time.
				var nft_holdings_json = Stacks.get_nft_holdings(StacksGlobals.wallet, asset_identifiers, 50)
				if nft_holdings_json is GDScriptFunctionState:
					nft_holdings_json = yield(nft_holdings_json, "completed")
				var nft_holdings = nft_holdings_json.result
				if nft_holdings.has("results"):
					var tokens = nft_holdings.get("results")
					
					var total_tokens : int = nft_holdings.get("total", 0)
					if tokens.empty():
						# No MetaBoys found
						MetaBoyGlobals.user_nfts_loopring = []
						return
					elif total_tokens > 50:
						var num_calls = int(floor(total_tokens / 50))
						for i in range(1, num_calls + 1):
							var json_next_batch = Stacks.get_nft_holdings(StacksGlobals.wallet, asset_identifiers, 50, i * 50)
							if json_next_batch is GDScriptFunctionState:
								json_next_batch = yield(json_next_batch, "completed")
							var response_object_next_batch = json_next_batch.result
							if response_object_next_batch.has("results"):
								var tokens_next_batch : Array = response_object_next_batch.get("results")
								for token in tokens_next_batch:
									tokens.append({
										"value": {
											"repr": token.get("value").get("repr")
										}
									})
					
					MetaBoyGlobals.user_nfts_stacks = tokens
					_parse_stx_metaboy_nfts(tokens)
	else:
		# No STX MetaBoys found
		MetaBoyGlobals.user_nfts_stacks.clear()

func _parse_stx_metaboy_nfts(tokens: Array) -> void:
	var first = true
	
	for nft in tokens:
		var nft_id = nft.get("value").get("repr")
		# NFT ID is an unsigned int, so it starts with "u"
		nft_id = str(nft_id).substr(1)
		# Metadata is saved locally
		var metadata = null
		if MetaBoyGlobals.stx_metadata_json.empty():
			metadata = MetaBoyGlobals.load_stx_metadata_json()
			if metadata is GDScriptFunctionState:
				metadata = yield(metadata, "completed")
		else:
			metadata = MetaBoyGlobals.stx_metadata_json
		if metadata != null:
			var formatted_name = "MetaBoy\n#" + nft_id
			
			var nft_properties = {}
			var nft_json_obj = MetaBoyGlobals.get_stx_metadata_for_id(int(nft_id))
			if !nft_json_obj.empty():
				var attributes : Array = nft_json_obj["attributes"]
				for attribute in attributes:
					var trait = attribute["trait"]
					var value = attribute["value"]
					nft_properties[trait] = value
				var metaboy_display = _add_metaboy_entry(formatted_name, nft_properties, MetaBoyGlobals.Collection.STX)
				if first:
					first = false
					metaboy_display.select()
				num_stx_metaboys += 1
	
	# Update the STX label here so that the label doesn't check the count before
	# the metadata reading is complete.
	if num_stx_metaboys > 0:
		no_metaboy_stx_label.queue_free()
	else:
		no_metaboy_stx_label.show()
	
	_focus_first_grid_element()

func _add_metaboy_entry(mb_name: String, mb_attributes: Dictionary, collection: int) -> Control:
	var metaboy_display = MetaBoyDisplay.instance()
	if collection == MetaBoyGlobals.Collection.OG:
		metaboy_grid.add_child(metaboy_display)
	elif collection == MetaBoyGlobals.Collection.STX:
		metaboy_stx_grid.add_child(metaboy_display)
	metaboy_display.set_metaboy_name(mb_name)
	mb_attributes["Collection"] = collection
	metaboy_display.set_metaboy_attributes(mb_attributes)
	metaboy_display.connect("metaboy_selected", self, "_on_metaboy_selected")
	return metaboy_display

func _on_TabContainer_tab_changed(tab):
	_focus_first_grid_element()

func _focus_first_grid_element() -> void:
	# Focus on the first element in the grid after switching tabs.
	if tab_container.get_current_tab_control() == metaboy_tab and \
			metaboy_grid.get_child_count() > 0:
		for entry in metaboy_grid.get_children():
			if entry.has_method("select"):
				entry.select()
				break
	if tab_container.get_current_tab_control() == metaboy_stx_tab and \
			metaboy_stx_grid.get_child_count() > 0:
		for entry in metaboy_stx_grid.get_children():
			if entry.has_method("select"):
				entry.select()
				break

func _on_BackButton_pressed():
	get_tree().change_scene("res://UI/LoginScreen.tscn")
