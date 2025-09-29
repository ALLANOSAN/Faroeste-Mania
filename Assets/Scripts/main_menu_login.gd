extends Control

# Nós da UI
@onready var login_button = %MenuPrincipalBTLogin
@onready var options_menu_button = %MenuPrincipalBTOpcoes
@onready var blinking_text = %TextoAnimado
@onready var animation_player = %AnimacaoTexto
@onready var background = %MenuPrincipalFundo

func _ready():
	# Verifica se o usuário já está logado
	if Firebase.Auth.check_auth_file():
		# Carrega dados de autenticação
		Firebase.Auth.load_auth()
		print("Usuário já logado!")
		setup_ui_logged_in()
	else:
		print("Usuário não logado")
		setup_ui_logged_out()

# =========================
# Configura UI quando está logado
# =========================
func setup_ui_logged_in():
	# Esconde botão de login
	if login_button != null:
		login_button.hide()
	
	# Mostra elementos do jogo
	if options_menu_button != null:
		options_menu_button.show()
	if blinking_text != null:
		blinking_text.show()
		if animation_player != null:
			animation_player.play("TextoAnimado")
	# Conecta detecção de toque
	if background != null and not background.gui_input.is_connected(_on_background_gui_input):
		background.gui_input.connect(_on_background_gui_input)

# =========================
# Configura UI quando não está logado
# =========================
func setup_ui_logged_out():
	if login_button != null:
		login_button.show()
	if options_menu_button != null:
		options_menu_button.hide()
	if blinking_text != null:
		blinking_text.hide()
	if background != null and background.gui_input.is_connected(_on_background_gui_input):
		background.gui_input.disconnect(_on_background_gui_input)

# =========================
# Callback de toque no background (opcional)
# =========================
func _on_background_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		print("Tela tocada/clicada")



func _on_menu_principal_bt_login_pressed() -> void:
	get_tree().change_scene_to_file("res://Assets/Scenes/login.tscn")
