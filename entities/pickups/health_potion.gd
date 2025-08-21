extends PickupEntity
class_name HealthPotion

@export var healing_amount: float = 25.0

func _ready():
	"""HealthPotion-specific initialization"""
	item_type = "health_potion"
	pickup_value = healing_amount
	
	# Call parent initialization
	super._ready()

func configure_pickup(config_data: Dictionary):
	"""Configure health potion with spawn data"""
	if config_data.has("healing_amount"):
		healing_amount = config_data["healing_amount"]
		pickup_value = healing_amount
	
	# Call parent configuration
	super.configure_pickup(config_data)
	
	print("HealthPotion configured: healing=", healing_amount)

func _can_be_picked_up(player: PlayerEntity) -> bool:
	"""Only allow pickup if player is injured"""
	return player.current_health < player.max_health

func _apply_pickup_effect(player: PlayerEntity):
	"""Heal the player"""
	var old_health = player.current_health
	player.heal(healing_amount)
	var actual_healing = player.current_health - old_health
	
	print("HealthPotion healed player ", player.player_id, " for ", actual_healing, " HP (", old_health, " -> ", player.current_health, ")")
	
	# Could add visual/audio effects here
	_play_healing_effect(player)

func _play_healing_effect(player: PlayerEntity):
	"""Play healing effect (placeholder for future audio/visual)"""
	# Future: particle effects, healing sound, etc.
	print("*Healing sparkles and restoration sound*")

func get_save_data() -> Dictionary:
	"""Return data needed to save this health potion's state"""
	var base_data = super.get_save_data()
	base_data["healing_amount"] = healing_amount
	return base_data

func restore_save_data(data: Dictionary):
	"""Restore health potion state from saved data"""
	if data.has("healing_amount"):
		healing_amount = data["healing_amount"]
		pickup_value = healing_amount
	
	super.restore_save_data(data)
