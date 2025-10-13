extends Control

# Nós da UI
@onready var login_button = %MenuPrincipalBTLogin
@onready var options_menu_button = %MenuPrincipalBTOpcoes
@onready var blinking_text = %TextoAnimado
@onready var animation_player = %AnimacaoTexto
@onready var background = %MenuPrincipalFundo

var _auth_retry_count = 0
const MAX_AUTH_RETRIES = 3

func _ready():
	# Configurar UI inicial - começamos assumindo que está deslogado
	# Isso garante que os botões estejam no estado correto desde o início
	setup_ui_logged_out()
	
	# Atribui sinal para capturar erros de token refresh antes de qualquer operação
	Firebase.Auth.login_failed.connect(on_login_failed)
	
	# Verificamos se temos informações de login salvas
	if Firebase.Auth.check_auth_file():
		print("Arquivo de autenticação encontrado, tentando carregar...")
		# Iniciamos o processo de carregamento com um atraso para dar tempo ao sistema
		_start_auth_load_process()
	else:
		print("Usuário não logado")

# Função para iniciar o processo de carregamento da autenticação
func _start_auth_load_process():
	# Resetamos contador de tentativas
	_auth_retry_count = 0
	# Aguardamos para garantir que o sistema esteja pronto
	await get_tree().create_timer(2.0).timeout
	# Tentamos carregar a autenticação com retry
	_try_load_auth()

# Função que tenta carregar autenticação com retry
func _try_load_auth():
	print("Tentativa de autenticação %d/%d..." % [_auth_retry_count + 1, MAX_AUTH_RETRIES])
	
	# Antes de tentar carregar, verificamos novamente se o arquivo existe
	if not Firebase.Auth.check_auth_file():
		print("Arquivo de autenticação não encontrado mais. Configurando como não logado.")
		setup_ui_logged_out()
		return
	
	# Tentamos carregar a autenticação
	print("Chamando load_auth...")
	await Firebase.Auth.load_auth()
	
	# Verificamos se após carregar, o usuário está autenticado
	if Firebase.Auth.auth != null and Firebase.Auth.auth.has("localid"):
		print("Autenticação carregada com sucesso! ID do usuário: ", Firebase.Auth.auth.localid)
		setup_ui_logged_in()
	elif _auth_retry_count < MAX_AUTH_RETRIES:
		# Aumentamos o contador de tentativas
		_auth_retry_count += 1
		# Esperamos mais tempo antes da próxima tentativa (tempo exponencial)
		var wait_time = 1.0 + _auth_retry_count * 0.5
		print("Autenticação falhou. Aguardando %f segundos para tentar novamente..." % wait_time)
		await get_tree().create_timer(wait_time).timeout
		# Tentamos novamente
		_try_load_auth()
	else:
		print("Número máximo de tentativas atingido. Fazendo logout.")
		# Como não conseguimos autenticar após várias tentativas, fazemos logout
		Firebase.Auth.logout()
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
		print("Tela tocada/clicada")
		get_tree().change_scene_to_file("res://Assets/Scenes/MapadoJogo.tscn")
		

func _on_menu_principal_bt_login_pressed() -> void:
	get_tree().change_scene_to_file("res://Assets/Scenes/login.tscn")
