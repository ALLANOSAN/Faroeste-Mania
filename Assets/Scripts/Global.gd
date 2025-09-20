extends Node

signal auth_state_changed(is_logged_in)
signal user_data_updated(user_data)

var player_data = {
	"id": "",
	"name": "",
	"high_score": 0
}

# Referência ao gerenciador LootLocker
var loot_locker_manager = null

# Sistema de detecção de plataforma
class PlatformDetector:
	var is_mobile := false
	var is_desktop := false
	var is_web := false
	
	func _init():
		# Detecta a plataforma
		match OS.get_name():
			"Android", "iOS":
				is_mobile = true
			"HTML5":
				is_web = true
			_:
				is_desktop = true
	
	# Função para verificar cliques válidos com base na plataforma
	func is_valid_click(event):
		if is_mobile:
			# No mobile, checamos por toques na tela
			return event is InputEventScreenTouch and event.pressed
		else:
			# No desktop, checamos por cliques do mouse
			return event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT

# Inicializa o detector de plataforma
var Platform = PlatformDetector.new()

func _ready():
	print("Global script inicializado")
	
	# Usa call_deferred para garantir que todos os autoloads estejam carregados
	call_deferred("_connect_to_loot_locker")

func _connect_to_loot_locker():
	# Tenta obter a referência ao LootLockerManager
	loot_locker_manager = get_node_or_null("/root/LootLockerManager")
	
	# Se o LootLockerManager existe, conectamos aos sinais
	if loot_locker_manager:
		loot_locker_manager.auth_state_changed.connect(_on_auth_state_changed)
		loot_locker_manager.login_success.connect(_on_login_success)
		loot_locker_manager.register_success.connect(_on_login_success) # Reutiliza o mesmo callback
		print("Conectado aos sinais do LootLockerManager")
		
		# Verifica se já há uma sessão anterior salva
		# A verificação é feita automaticamente no _ready() do LootLockerManager
	else:
		print("ERRO: LootLockerManager não encontrado!")

# Funções de autenticação
func login_guest():
	if loot_locker_manager:
		loot_locker_manager.login_guest()
	else:
		print("ERRO: Não foi possível fazer login, LootLockerManager não disponível")

func logout():
	if loot_locker_manager:
		loot_locker_manager.logout()
	else:
		print("ERRO: Não foi possível fazer logout, LootLockerManager não disponível")

# Função para verificar se o usuário está logado
func is_user_logged_in():
	if loot_locker_manager:
		return loot_locker_manager.is_logged_in
	return false

# Função para obter o ID do usuário atual
func get_current_user_id():
	if loot_locker_manager:
		return loot_locker_manager.get_user_id()
	return ""

# Função para obter o nome do usuário atual
func get_player_name():
	if loot_locker_manager:
		return loot_locker_manager.get_player_name()
	return "Visitante"

# Função para obter a pontuação máxima do jogador
func get_player_high_score():
	if loot_locker_manager:
		return loot_locker_manager.get_player_high_score()
	return 0
	
# Função para obter o rank do jogador atual
func get_player_rank() -> Dictionary:
	if loot_locker_manager:
		return await loot_locker_manager.get_player_rank()
	return {"rank": 0, "total": 0}

# Funções de pontuação
func submit_score(score):
	if loot_locker_manager:
		loot_locker_manager.submit_score(score)
	else:
		print("ERRO: Não foi possível enviar pontuação, LootLockerManager não disponível")

func load_leaderboard():
	if loot_locker_manager:
		loot_locker_manager.load_scores()
	else:
		print("ERRO: Não foi possível carregar pontuações, LootLockerManager não disponível")

# Funções de autenticação com email e senha
func register_user(email: String, password: String):
	if loot_locker_manager:
		loot_locker_manager.register_user(email, password)
	else:
		print("ERRO: Não foi possível registrar usuário, LootLockerManager não disponível")

func login_user(email: String, password: String):
	if loot_locker_manager:
		loot_locker_manager.login_user(email, password)
	else:
		print("ERRO: Não foi possível fazer login, LootLockerManager não disponível")

# Callbacks
func _on_auth_state_changed(is_logged_in):
	# Repassa o sinal
	auth_state_changed.emit(is_logged_in)

func _on_login_success(user_data):
	# Atualiza os dados do jogador com verificação de segurança
	if user_data != null:
		player_data.id = user_data.get("player_id", "")
		player_data.name = user_data.get("player_name", "")
		
		# Emite o sinal de dados atualizados
		user_data_updated.emit(player_data)
	else:
		print("AVISO: user_data é nulo em _on_login_success")
