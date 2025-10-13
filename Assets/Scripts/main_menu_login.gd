extends Control

# Nós da UI
@onready var login_button = %MenuPrincipalBTLogin
@onready var options_menu_button = %MenuPrincipalBTOpcoes
@onready var blinking_text = %TextoAnimado
@onready var animation_player = %AnimacaoTexto
@onready var background = %MenuPrincipalFundo

func _ready():
	print("🔄 MainMenuLogin._ready() iniciado")
	
	# Conecta sinais do Firebase Auth ANTES de qualquer verificação
	Firebase.Auth.login_succeeded.connect(_on_auth_loaded)
	Firebase.Auth.login_failed.connect(on_login_failed)
	
	# Aguarda o Firebase estar pronto e o sistema de arquivos estabilizar
	print("⏳ Aguardando sistema estar pronto...")
	await get_tree().create_timer(0.5).timeout
	
	# Verifica se tem arquivo de autenticação válido
	print("🔍 Verificando arquivo de autenticação...")
	
	# Verifica a existência do arquivo SEM chamar check_auth_file() que causaria HTTP request
	# Apenas verifica se o arquivo físico existe (nome usado pelo plugin Firebase)
	if FileAccess.file_exists("user://user.auth"):
		print("📁 Arquivo de autenticação encontrado: user://user.auth")
		setup_ui_logged_in()
	else:
		print("❌ Nenhum arquivo de autenticação encontrado")
		setup_ui_logged_out()

# Callback quando faz login com sucesso (novo login, não load_auth)
func _on_auth_loaded(_auth_data):
	print("✅ Login realizado com sucesso!")
	setup_ui_logged_in()

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
# Tratamento de erros de login/token
# =========================
func on_login_failed(error_code, message):
	print("Erro de autenticação: ", error_code, " - ", message)
	
	# Se for erro de token inválido ou expirado
	if error_code == 400 or str(error_code) == "INVALID_LOGIN_CREDENTIALS" or message.contains("token"):
		print("Token inválido ou expirado, fazendo logout...")
		# Chama o método logout que vai remover a autenticação e emitir o sinal logged_out
		Firebase.Auth.logout()
		setup_ui_logged_out()
		
		# Opcional: redirecionar para tela de login
		# get_tree().change_scene_to_file("res://Assets/Scenes/login.tscn")

# =========================
# Callback de toque no background (opcional)
# =========================
func _on_background_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		print("🎮 Tentando entrar no jogo...")
		
		# Verifica se arquivo existe (sem chamar check_auth_file que causa HTTP request)
		if not FileAccess.file_exists("user://user.auth"):
			print("⚠️ Nenhum arquivo de autenticação encontrado! Faça login primeiro.")
			# Volta para tela de login
			get_tree().change_scene_to_file("res://Assets/Scenes/login.tscn")
			return
		
		# Arquivo existe, pode entrar no jogo
		# A validação real do token acontece no mapa_jogo.gd
		print("✅ Arquivo de autenticação presente, entrando no jogo...")
		get_tree().change_scene_to_file("res://Assets/Scenes/MapadoJogo.tscn")
		

func _on_menu_principal_bt_login_pressed() -> void:
	get_tree().change_scene_to_file("res://Assets/Scenes/login.tscn")
