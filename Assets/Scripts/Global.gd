extends Node

signal auth_state_changed(is_logged_in)
signal user_data_updated(user_data)
signal scores_updated(scores_data)

var player_data = {
	"id": "",
	"name": "",
	"high_score": 0
}

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

# Funções de autenticação
@onready var auth = get_node("/root/Auth")

func login_guest():
	print("Função login_guest não implementada")

func logout():
	if is_instance_valid(auth):
		auth._on_logout_button_pressed()
	else:
		print("Logout realizado (fallback)")
	auth_state_changed.emit(false)
	print("Logout realizado")

# Função para verificar se o usuário está logado
func is_user_logged_in():
	return Firebase and Firebase.Auth and Firebase.Auth.check_auth_file()

# Função para obter o ID do usuário atual
func get_current_user_id():
	if not Firebase or not Firebase.Auth:
		return ""
	var auth_data = Firebase.Auth.get_user_data()
	if auth_data and auth_data.has("localid"):
		return auth_data.localid
	return ""

# Função para obter o nome do usuário atual
func get_player_name():
	if not is_user_logged_in():
		return "Visitante"
	return player_data.name if not player_data.name.is_empty() else "Jogador " + get_current_user_id().substr(0, 5)

# CORRIGIDO: Adicionada a função get_player_high_score()
func get_player_high_score():
	return player_data.high_score

# CORRIGIDO: Adicionada a função set_player_high_score()
func set_player_high_score(score: int):
	player_data.high_score = score

# Função para criar o perfil do usuário
func create_user_profile_document(user_id, display_name):
	var user_data = {
		"display_name": display_name,
		"high_score": 0
	}
	
	var user_collection = Firebase.Firestore.collection("users")
	var result = await user_collection.add(user_id, user_data)
	if result:
		print("Documento de perfil de usuário criado com sucesso para o ID: ", user_id)
		update_user_data(result)
	else:
		print("Erro ao criar o documento de perfil do usuário: ", result.get_error())

# Função para atualizar o nome do jogador
func update_player_name(new_name):
	var user_id = get_current_user_id()
	if user_id.is_empty():
		print("Erro: ID do usuário não encontrado.")
		return
	
	var users_collection = Firebase.Firestore.collection("users")
	var user_doc = await users_collection.get_doc(user_id)
	
	if user_doc:
		var updated_doc = await users_collection.update(user_doc.doc_name, {"display_name": new_name})
		if updated_doc:
			print("Nome de usuário atualizado com sucesso!")
			update_user_data(updated_doc)
		else:
			print("Erro ao atualizar nome de usuário: ", updated_doc.get_error())
	else:
		print("Erro: Documento do usuário não encontrado.")

func load_user_data():
	var user_id = get_current_user_id()
	if user_id.is_empty():
		print("Não há usuário logado.")
		return
	
	var user_doc_ref = Firebase.Firestore.collection("users")
	var doc = await user_doc_ref.get_doc(user_id)
	
	if doc:
		update_user_data(doc)
	else:
		print("Documento de usuário não encontrado para o ID: ", user_id)
		
# Funções do placar
func save_player_score(score: int):
	var user_id = get_current_user_id()
	if user_id.is_empty():
		print("Usuário não logado. Pontuação não será salva.")
		return
	
	print("Tentando salvar pontuação para o usuário ", user_id, " com pontuação ", score)
	
	var user_doc = await Firebase.Firestore.collection("users").get_doc(user_id)
	if user_doc:
		var current_high_score = user_doc.get_field("high_score") if user_doc.has_field("high_score") else 0
		
		if score > current_high_score:
			print("Nova pontuação ", score, " é maior que a pontuação máxima atual ", current_high_score, ". Atualizando...")
			var updated_doc = await Firebase.Firestore.collection("users").update(user_doc.doc_name, {"high_score": score})
			if updated_doc:
				print("Pontuação máxima atualizada com sucesso para: ", score)
				set_player_high_score(score)
				user_data_updated.emit(updated_doc)
			else:
				print("Erro ao atualizar a pontuação máxima: ", updated_doc.get_error())
		else:
			print("Nova pontuação ", score, " não é maior que a pontuação máxima atual ", current_high_score, ". Nenhuma atualização necessária.")
	else:
		print("Documento do usuário não encontrado. Não é possível salvar a pontuação.")
	
func load_leaderboard():
	var query = FirestoreQuery.new()
	query.from("users")
	query.select(["display_name", "high_score"])
	query.order_by("high_score", FirestoreQuery.DIRECTION.DESCENDING)
	query.limit(100)
	
	var query_results = await Firebase.Firestore.query(query)
	if query_results:
		var results = []
		for doc in query_results:
			var leaderboard_entry = {
				"user_id": doc.doc_name,
				"name": doc.get_value("display_name") if doc.has_field("display_name") else "Jogador Anônimo",
				"score": doc.get_value("high_score") if doc.has_field("high_score") else 0
			}
			results.append(leaderboard_entry)
		
		scores_updated.emit(results)
		print("Leaderboard carregado com sucesso: " + str(results.size()) + " jogadores")
	else:
		print("Nenhum resultado encontrado no leaderboard")
		scores_updated.emit([])
	
# Funções de autenticação com email e senha
func register_user(_email: String, _password: String):
	if not is_instance_valid(auth):
		print("Erro: Auth.gd não encontrado!")
		return
	auth._on_sign_up_button_pressed()

func login_user(_email: String, _password: String):
	if not is_instance_valid(auth):
		print("Erro: Auth.gd não encontrado!")
		return
	auth._on_login_button_pressed()

# Callbacks
func _on_auth_state_changed(is_logged_in):
	# Repassa o sinal
	auth_state_changed.emit(is_logged_in)

func update_user_data(user_data):
	if user_data != null:
		player_data.id = user_data.get("id", "")
		player_data.name = user_data.get("display_name", "")
		# CORRIGIDO: Utiliza a função para atualizar a pontuação
		set_player_high_score(user_data.get("high_score", 0))
		user_data_updated.emit(player_data)
	else:
		print("AVISO: user_data é nulo em update_user_data")

func clear_session():
	logout()
	player_data = {
		"id": "",
		"name": "",
		"high_score": 0
	}
	print("Sessão e dados do usuário removidos")
	user_data_updated.emit(player_data)