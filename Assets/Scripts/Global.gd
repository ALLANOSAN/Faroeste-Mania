extends Node

signal auth_state_changed(is_logged_in)

var player_data = {
	"id": "",
	"name": "",
	"high_score": 0
}

func _ready() -> void:
	print("Global initialized")
	# Opcional: ao carregar (editor ou runtime), notifique estado
	auth_state_changed.emit(false)
