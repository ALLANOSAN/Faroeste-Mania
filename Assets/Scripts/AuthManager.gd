extends Node

var current_user = null
const USER_DATA_KEY = "user_id"

func _ready():
	# Carrega a sessão do usuário no início do jogo, se ela existir.
	load_user_session()

func is_logged_in():
	return current_user != null

func save_user_session(user_id):
	ProjectSettings.set_setting("user_data/" + USER_DATA_KEY, user_id)
	ProjectSettings.save()
	current_user = user_id

func load_user_session():
	var user_id = ProjectSettings.get_setting("user_data/" + USER_DATA_KEY, null)
	if user_id != null and not user_id.empty():
		current_user = user_id

func get_current_user_id():
	return current_user

func clear_session():
	ProjectSettings.set_setting("user_data/" + USER_DATA_KEY, null)
	ProjectSettings.save()
	current_user = null
