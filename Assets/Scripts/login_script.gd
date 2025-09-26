extends Control

@onready var feedback_text  = %FeedbackText
@onready var email_field    = %email
@onready var password_field = %password
@onready var login_button   = %button
@onready var signup_button  = %signup_button

@onready var auth   = get_node("/root/Auth")
@onready var global = get_node("/root/Global")

func _ready() -> void:
	auth.login_failed.connect(_on_auth_login_failed)
	auth.login_succeeded.connect(_on_auth_login_succeeded)
	login_button.pressed.connect(_on_login_pressed)
	signup_button.pressed.connect(_on_signup_pressed)

func _on_login_pressed() -> void:
	var email    = email_field.text.strip_edges()
	var password = password_field.text.strip_edges()
	if email == "" or password == "":
		feedback_text.text = "Preencha email e senha"
		return
	feedback_text.text = "Fazendo login..."
	auth.login(email, password)

func _on_auth_login_succeeded(auth_data: Dictionary) -> void:
	print("Login bem-sucedido:", auth_data)
	global.load_user_data()
	global.load_leaderboard()
	get_tree().change_scene_to_file("res://Assets/Scenes/MainMenuLogin.tscn")

func _on_auth_login_failed(code, msg) -> void:
	feedback_text.text = "Falha ao logar:\n%s (Code %s)" % [msg, code]

func _on_signup_pressed() -> void:
	get_tree().change_scene_to_file("res://Assets/Scenes/RegisterScreen.tscn")
