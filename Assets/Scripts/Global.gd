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
	# Verifica no Firebase
	if Firebase and Firebase.Auth and Firebase.Auth.check_auth_file():
		return true
	return false

# Função para obter o ID do usuário atual
func get_current_user_id():
	"""Retorna o ID do usuário atualmente logado no Firebase"""
	if not Firebase or not Firebase.Auth:
		return ""
	var auth_data = Firebase.Auth.get_user_data()
	if auth_data and auth_data.has("localid"):
		return auth_data.localid
	return ""

# Função para obter o nome do usuário atual
func get_player_name():
	"""Retorna o nome do usuário atual do Firestore"""
	if not is_user_logged_in():
		return "Visitante"
		
	var user_id = get_current_user_id()
	if user_id.is_empty():
		return "Visitante"
		
	# Primeiro, verifica se já temos o nome em cache
	if player_data.name and not player_data.name.is_empty():
		return player_data.name
		
	# Se não temos em cache, busca do Firestore (isso será assíncrono)
	# Nota: Como essa função não é async, o nome será atualizado depois
	# e estará disponível apenas na próxima chamada
	var user_collection = Firebase.Firestore.collection("users")
	
	user_collection.get_doc(user_id).then(func(doc):
		if doc and doc.has_field("display_name"):
			player_data.name = doc.get_value("display_name")
			# Notifica que os dados do usuário foram atualizados
			user_data_updated.emit(player_data)
	).catch(func(error):
		print("Erro ao buscar nome do usuário: " + str(error))
	)
	
	# Retorna o valor atual (que pode ser atualizado posteriormente)
	return player_data.name if not player_data.name.is_empty() else "Jogador " + user_id.substr(0, 5)

# Função para obter a pontuação máxima do jogador
func get_player_high_score():
	# Busca e retorna a pontuação máxima do jogador, cacheando em player_data.high_score
	if not is_user_logged_in():
		return 0
	var user_id = get_current_user_id()
	if user_id.is_empty():
		return 0
	# Se já está em cache, retorna
	if player_data.high_score > 0:
		return player_data.high_score
	# Busca do Firestore (assíncrono, mas retorna cache imediato)
	var user_collection = Firebase.Firestore.collection("users")
	user_collection.get_doc(user_id).then(func(doc):
		if doc and doc.has_field("score"):
			player_data.high_score = doc.get_value("score")
			user_data_updated.emit(player_data)
	).catch(func(error):
		print("Erro ao buscar score do usuário: " + str(error))
	)
	return player_data.high_score

# Função para atualizar o nome do usuário centralizadamente
func set_player_name(new_name: String, callback: Callable):
	if not is_user_logged_in():
		callback.call(false, "Usuário não está logado!")
		return
	var user_id = get_current_user_id()
	if user_id.is_empty():
		callback.call(false, "ID de usuário inválido!")
		return
	var user_collection = Firebase.Firestore.collection("users")
	user_collection.get_doc(user_id).then(func(doc):
		if doc:
			# Documento existe, atualiza o nome
			doc.add_or_update_field("display_name", new_name)
			doc.add_or_update_field("updated_at", Time.get_unix_time_from_system())
			Firebase.Firestore.update(doc.doc_name, {"display_name": new_name, "updated_at": Time.get_unix_time_from_system()}, "users").then(func(_result):
				player_data.name = new_name
				user_data_updated.emit(player_data)
				callback.call(true, "Nome atualizado com sucesso!")
			).catch(func(error):
				callback.call(false, "Erro ao atualizar nome: " + str(error))
			)
		else:
			# Documento não existe, cria um novo
			var user_data = {
				"display_name": new_name,
				"score": 0,
				"created_at": Time.get_unix_time_from_system(),
				"updated_at": Time.get_unix_time_from_system()
			}
			Firebase.Firestore.add("users", user_id, user_data).then(func(_result):
				player_data.name = new_name
				user_data_updated.emit(player_data)
				callback.call(true, "Nome criado com sucesso!")
			).catch(func(error):
				callback.call(false, "Erro ao criar perfil: " + str(error))
			)
	).catch(func(error):
		callback.call(false, "Erro ao verificar perfil: " + str(error))
	)
	
# Função para obter o rank do jogador atual
func get_player_rank() -> Dictionary:
	"""Retorna o rank do jogador baseado no leaderboard"""
	if not is_user_logged_in():
		return {"rank": 0, "total": 0}
		
	var user_id = get_current_user_id()
	if user_id.is_empty():
		return {"rank": 0, "total": 0}
		
	# Consulta o Firestore para obter todos os usuários ordenados por pontuação
	var query = FirestoreQuery.new()
	query.from("users")
	query.order_by("score", FirestoreQuery.DIRECTION.DESCENDING)
	
	var result = await Firebase.Firestore.query(query)
	var rank = 0
	var total = result.size()
	
	# Procura o usuário na lista para determinar o rank
	for i in range(total):
		if result[i].doc_name == user_id:
			rank = i + 1 # +1 porque o índice começa em 0 mas o rank começa em 1
			break
	
	return {"rank": rank, "total": total}

# Funções de pontuação
func submit_score(score):
	"""Envia a pontuação do jogador para o Firestore"""
	if not is_user_logged_in():
		print("Erro: É necessário estar logado para enviar pontuações")
		return
		
	var user_id = get_current_user_id()
	if user_id.is_empty():
		print("Erro: ID de usuário inválido")
		return
		
	print("Enviando pontuação: " + str(score))
	
	# Primeiro, busca o documento do usuário para verificar se já existe
	var user_collection = Firebase.Firestore.collection("users")
	
	user_collection.get_doc(user_id).then(func(doc):
		if doc:
			# Documento existe, verifica se a nova pontuação é maior
			var current_score = doc.get_value("score") if doc.has_field("score") else 0
			
			if score > current_score:
				# Atualiza a pontuação
				doc.add_or_update_field("score", score)
				doc.add_or_update_field("updated_at", Time.get_unix_time_from_system())
				
				Firebase.Firestore.update(doc.doc_name, {"score": score, "updated_at": Time.get_unix_time_from_system()}, "users").then(func(_result):
					print("Pontuação atualizada com sucesso")
					# Recarrega o leaderboard para atualizar
					load_leaderboard()
				).catch(func(error):
					print("Erro ao atualizar pontuação: " + str(error))
				)
			else:
				print("Pontuação atual (" + str(current_score) + ") é maior que a nova (" + str(score) + "). Não atualizada.")
		else:
			# Documento não existe, cria um novo
			var new_user_data = {
				"display_name": get_player_name(),
				"score": score,
				"created_at": Time.get_unix_time_from_system(),
				"updated_at": Time.get_unix_time_from_system()
			}
			
			Firebase.Firestore.add("users", user_id, new_user_data).then(func(_result):
				print("Novo documento de usuário criado com pontuação")
				# Recarrega o leaderboard para atualizar
				load_leaderboard()
			).catch(func(error):
				print("Erro ao criar documento de usuário: " + str(error))
			)
	).catch(func(error):
		print("Erro ao buscar documento do usuário: " + str(error))
	)

func load_leaderboard():
	"""Carrega o leaderboard do Firestore"""
	if not Firebase or not Firebase.Firestore:
		print("Erro: Firebase ou Firestore não disponível")
		return
	
	print("Carregando leaderboard do Firestore...")
	
	# Cria uma consulta otimizada com os campos que precisamos
	var query = FirestoreQuery.new()
	query.from("users")
	query.select(["display_name", "score"]) # Seleciona apenas os campos necessários
	query.order_by("score", FirestoreQuery.DIRECTION.DESCENDING)
	query.limit(100)
	
	var results = []
	
	# Executa a consulta no Firestore
	Firebase.Firestore.query(query).then(func(query_results):
		if query_results:
			# Processa cada documento nos resultados
			for doc in query_results:
				# Extração otimizada de dados com verificação de nulos
				var display_name = "Jogador Anônimo"
				var score = 0
				
				if doc.has_field("display_name"):
					display_name = doc.get_value("display_name")
					# Garantir que o nome nunca seja nulo
					if display_name == null or display_name.is_empty():
						display_name = "Jogador " + doc.doc_name.substr(0, 5)
				
				if doc.has_field("score"):
					score = doc.get_value("score")
				
				# Cria a entrada do leaderboard com os dados processados
				var leaderboard_entry = {
					"user_id": doc.doc_name,
					"name": display_name,
					"score": score
				}
				results.append(leaderboard_entry)
			
			# Emite o sinal com os resultados
			scores_updated.emit(results)
			print("Leaderboard carregado com sucesso: " + str(results.size()) + " jogadores")
		else:
			print("Nenhum resultado encontrado no leaderboard")
			scores_updated.emit([])
	).catch(func(error):
		print("Erro ao carregar leaderboard: " + str(error))
		scores_updated.emit([])
	)

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

# Esta função será implementada para o Firebase
func update_user_data(user_data):
	# Atualiza os dados do jogador
	if user_data != null:
		player_data.id = user_data.get("id", "")
		player_data.name = user_data.get("name", "")
		
		# Emite o sinal de dados atualizados
		user_data_updated.emit(player_data)
	else:
		print("AVISO: user_data é nulo em update_user_data")

# Função para limpar a sessão (logout + apagar dados)
func clear_session():
	# Primeiro faz logout
	logout()
	
	# Limpa dados do player
	player_data = {
		"id": "",
		"name": "",
		"high_score": 0
	}
	
	print("Sessão e dados do usuário removidos")
	
	# Emite sinal de atualização dos dados
	user_data_updated.emit(player_data)
