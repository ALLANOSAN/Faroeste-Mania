extends Control

@onready var display_name_input = %display_name
@onready var email_input        = %email
@onready var password_input     = %password
@onready var feedback_text      = %FeedbackText2
@onready var back_button        = %back_button
@onready var register_button    = %register_button

@onready var auth   = get_node("/root/Auth")
@onready var global = get_node("/root/Global")

func _ready() -> void:
	auth.signup_failed.connect(_on_auth_signup_failed)
	auth.signup_succeeded.connect(_on_auth_signup_succeeded)
	register_button.pressed.connect(_on_register_pressed)
	back_button.pressed.connect(_on_back_pressed)

func _on_register_pressed() -> void:
	var user_name = display_name_input.text.strip_edges()
	var email     = email_input.text.strip_edges()
	var password  = password_input.text

	if user_name == "":
		feedback_text.text = "Digite seu nome de usuário"
		return
	if email == "" or password == "":
		feedback_text.text = "Preencha email e senha"
		return
	if password.length() < 8:
		feedback_text.text = "Senha precisa ter ≥8 caracteres"
		return

	feedback_text.text = "Registrando..."
	auth.signup(email, password)

func _on_auth_signup_succeeded(auth_data: Dictionary) -> void:
	# Corrige o uso de localId
	var uid = auth_data.localId
	global.create_user_profile_document(uid, display_name_input.text.strip_edges())
	global.load_user_data()
	global.load_leaderboard()
	get_tree().change_scene_to_file("res://Assets/Scenes/MainMenuLogin.tscn")

func _on_auth_signup_failed(code, msg) -> void:
	feedback_text.text = "Falha no cadastro:\n%s (Code %s)" % [msg, code]

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://Assets/Scenes/LoginScreen.tscn")
