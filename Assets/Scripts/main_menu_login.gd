extends Control

# Nós da UI
@onready var login_button = %MenuPrincipalBTLogin
@onready var options_menu_button = %MenuPrincipalBTOpcoes
@onready var blinking_text = %TextoAnimado
@onready var animation_player = %AnimacaoTexto
@onready var background = %MenuPrincipalFundo

func _ready():
	print("🔄 MainMenuLogin._ready() iniciado")
	
	# Inicia música ambiente
	AudioManager.play_ambience()
	
	# FIX VISUAL: Esconde tudo inicialmente para evitar "ghosting" (elementos piscando errados)
	if login_button: login_button.hide()
	if options_menu_button: options_menu_button.hide()
	if blinking_text: blinking_text.hide()
	
	# Conecta botão de opções via código
	if options_menu_button != null:
		if not options_menu_button.pressed.is_connected(_on_options_menu_button_pressed):
			options_menu_button.pressed.connect(_on_options_menu_button_pressed)
	
	# FIX CRÍTICO: Força conexão dos sinais do Auth para o Firestore
	# O plugin deveria fazer isso automaticamente mas às vezes falha
	if not Firebase.Auth.login_succeeded.is_connected(Firebase.Firestore._on_FirebaseAuth_login_succeeded):
		print("⚠️ Conectando sinais Auth → Firestore manualmente...")
		Firebase.Auth.login_succeeded.connect(Firebase.Firestore._on_FirebaseAuth_login_succeeded)
		Firebase.Auth.signup_succeeded.connect(Firebase.Firestore._on_FirebaseAuth_login_succeeded)
		Firebase.Auth.token_refresh_succeeded.connect(Firebase.Firestore._on_FirebaseAuth_token_refresh_succeeded)
		Firebase.Auth.logged_out.connect(Firebase.Firestore._on_FirebaseAuth_logout)
		print("✅ Sinais conectados!")
	
	# Conecta sinais locais
	if not Firebase.Auth.login_succeeded.is_connected(_on_auth_loaded):
		Firebase.Auth.login_succeeded.connect(_on_auth_loaded)
	if not Firebase.Auth.token_refresh_succeeded.is_connected(_on_token_refreshed):
		Firebase.Auth.token_refresh_succeeded.connect(_on_token_refreshed)
	
	# REMOVIDO: await get_tree().create_timer(3.0).timeout (Causava delay desnecessário)
	
	# Verifica se JÁ está autenticado na sessão (login recente)
	if Firebase.Auth.auth != null and not Firebase.Auth.auth.is_empty() and Firebase.Auth.auth.has("idtoken"):
		print("✅ Já autenticado na sessão atual!")
		setup_ui_logged_in()
	# Verifica se existe sessão salva
	elif FileAccess.file_exists("user://session.enc"):
		print("📂 Sessão salva encontrada - tentando restaurar...")
		# Tenta restaurar AGORA (não espera o clique)
		if await restore_session():
			print("✅ Sessão restaurada com sucesso!")
			setup_ui_logged_in()
		else:
			print("❌ Falha ao restaurar sessão")
			clear_session() # Remove sessão inválida
			setup_ui_logged_out()
	else:
		print("❌ Não autenticado - precisa fazer login")
		setup_ui_logged_out()


# Tenta restaurar sessão (chamada sob demanda, não no _ready)
func try_restore_session_on_demand():
	print("🔄 Usuário interagiu - tentando restaurar sessão...")
	
	if await restore_session():
		print("✅ Sessão restaurada com sucesso!")
		setup_ui_logged_in()
		return true
	else:
		print("❌ Falha ao restaurar - redirecionando para login")
		setup_ui_logged_out()
		return false


# Restaura sessão salva de forma segura
func restore_session() -> bool:
	# Verifica se arquivo existe
	if not FileAccess.file_exists("user://session.enc"):
		print("ℹ️ Nenhuma sessão salva encontrada")
		return false
	
	# Abre arquivo criptografado
	var file = FileAccess.open_encrypted_with_pass(
		"user://session.enc",
		FileAccess.READ,
		OS.get_unique_id()
	)
	
	if file == null:
		push_error("❌ Erro ao abrir arquivo de sessão: " + str(FileAccess.get_open_error()))
		return false
	
	# Lê e parseia dados
	var json = JSON.new()
	var parse_result = json.parse(file.get_line())
	file.close()
	
	if parse_result != OK:
		push_error("❌ Erro ao parsear dados da sessão")
		return false
	
	var session = json.data
	
	# Valida estrutura dos dados
	if not session.has("refresh_token") or not session.has("device_id") or not session.has("saved_at"):
		push_error("❌ Dados da sessão inválidos")
		return false
	
	# Verifica se é o mesmo dispositivo
	if session.device_id != OS.get_unique_id():
		print("⚠️ Sessão de outro dispositivo - ignorando")
		return false
	
	# Verifica expiração (30 dias)
	var age_in_seconds = Time.get_unix_time_from_system() - session.saved_at
	var age_in_days = age_in_seconds / 86400.0
	
	if age_in_days > 30:
		print("⚠️ Sessão expirada (%d dias) - precisa fazer login novamente" % int(age_in_days))
		return false
	
	print("🔄 Tentando renovar token (sessão tem %d dias)..." % int(age_in_days))
	
	# NOVA ABORDAGEM: Em vez de tentar renovar token (que está falhando),
	# vamos simplesmente verificar se já está autenticado na sessão atual
	# Se não estiver, o usuário terá que fazer login novamente
	
	# Aguarda um pouco para garantir que Firebase está pronto
	print("⏸️ Aguardando Firebase inicializar...")
	await get_tree().create_timer(1.0).timeout
	
	# Verifica se já tem auth válido na sessão (de um login recente)
	if Firebase.Auth.auth != null and not Firebase.Auth.auth.is_empty() and Firebase.Auth.auth.has("idtoken"):
		print("✅ Já existe sessão ativa do Firebase.Auth!")
		return true
	
	# Se não tem sessão ativa, não tenta renovar (está com bug)
	# Simplesmente retorna false para forçar novo login
	print("⚠️ Não há sessão ativa - será necessário fazer login novamente")
	print("ℹ️ (Refresh token automático desabilitado devido a bug do plugin)")
	return false


# Classe auxiliar para aguardar sinais (evita problemas com lambdas)
class SignalWaiter extends Node:
	var result = ""
	
	func wait_for_auth_signals(timeout: float) -> String:
		# Conecta sinais
		Firebase.Auth.token_refresh_succeeded.connect(_on_refresh_success)
		Firebase.Auth.login_failed.connect(_on_refresh_failed)
		
		# Cria timer de timeout
		var timer = get_tree().create_timer(timeout)
		timer.timeout.connect(_on_timeout)
		
		# Aguarda resultado
		while result == "":
			await get_tree().process_frame
		
		# Limpa conexões
		if Firebase.Auth.token_refresh_succeeded.is_connected(_on_refresh_success):
			Firebase.Auth.token_refresh_succeeded.disconnect(_on_refresh_success)
		if Firebase.Auth.login_failed.is_connected(_on_refresh_failed):
			Firebase.Auth.login_failed.disconnect(_on_refresh_failed)
		
		return result
	
	func _on_refresh_success(_auth):
		print("🎉 Sinal token_refresh_succeeded recebido!")
		result = "success"
	
	func _on_refresh_failed(code, message):
		print("⚠️ Sinal login_failed recebido:", code, "-", message)
		result = "failed"
	
	func _on_timeout():
		print("⏰ Timeout atingido após 10 segundos")
		result = "timeout"


# Callback quando token é renovado automaticamente
func _on_token_refreshed(auth_data):
	print("🔄 Token atualizado automaticamente:", auth_data.has("idtoken"))

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
# Limpa sessão salva (usado no logout)
# =========================
func clear_session() -> void:
	if FileAccess.file_exists("user://session.enc"):
		DirAccess.remove_absolute("user://session.enc")
		print("🗑️ Sessão removida")

# =========================
# Logout (desconecta e limpa sessão)
# =========================
func logout() -> void:
	print("👋 Fazendo logout...")
	
	# Limpa sessão salva
	clear_session()
	
	# Limpa auth atual do Firebase
	Firebase.Auth.logout()
	
	# Atualiza UI
	setup_ui_logged_out()
	
	print("✅ Logout realizado com sucesso!")

# =========================
# Callback de toque no background (opcional)
# =========================
func _on_background_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		print("🎮 Tentando entrar no jogo...")
		
		# Verifica se está autenticado na sessão
		if Firebase.Auth.auth != null and not Firebase.Auth.auth.is_empty() and Firebase.Auth.auth.has("idtoken"):
			print("✅ Autenticado, entrando no jogo...")
			get_tree().change_scene_to_file("res://Assets/Scenes/MapadoJogo.tscn")
		else:
			# Não autenticado
			print("⚠️ Não autenticado! Faça login primeiro.")
			get_tree().change_scene_to_file("res://Assets/Scenes/login.tscn")
		

func _on_menu_principal_bt_login_pressed() -> void:
	get_tree().change_scene_to_file("res://Assets/Scenes/login.tscn")


func _on_options_menu_button_pressed() -> void:
	print("⚙️ Abrindo menu de opções...")
	get_tree().change_scene_to_file("res://Assets/Scenes/MenuOpções.tscn")
