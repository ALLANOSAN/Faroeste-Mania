extends Node

var current_user = null
var current_user_name = null
const USER_DATA_KEY = "user_id"
const USER_NAME_KEY = "user_name"
var API_KEY = "AIzaSyCgzX43gWy7bGNHxqTC_TAHWeobJww2Il0" # Sua Firebase API key
var DATABASE_URL = "https://faroeste-mania-default-rtdb.firebaseio.com/" # URL do Firebase Realtime Database

# Sinais
signal auth_state_changed(is_logged_in)
signal scores_updated(scores_list) # Emitido quando as pontuações são atualizadas

func _ready():
	# Primeiro tentamos carregar a sessão local
	var has_local_session = load_local_session()
	
	if has_local_session:
		# Se temos dados locais, emitimos o sinal de autenticado
		print("Sessão local detectada para: ", current_user)
		emit_signal("auth_state_changed", true)
	else:
		# Tenta verificar se há um token salvo no Firebase
		check_firebase_session()
		
	print("AuthManager inicializado")

# Carrega a sessão local salva
func load_local_session() -> bool:
	if ProjectSettings.has_setting("auth/" + USER_DATA_KEY):
		var user_id = ProjectSettings.get_setting("auth/" + USER_DATA_KEY)
		if user_id != null and user_id != "":
			current_user = user_id
			print("Sessão carregada para usuário ID: ", user_id)
			return true
	return false

# Verifica se existe uma sessão válida no Firebase
func check_firebase_session():
	# Verificamos se há um token ID guardado
	var saved_token = get_stored_token()
	if saved_token == null or saved_token.is_empty():
		print("Nenhum token de autenticação encontrado")
		emit_signal("auth_state_changed", false)
		return
		
	# Verificamos se o token é válido
	verify_firebase_token(saved_token)

# Obtém o token armazenado localmente
func get_stored_token() -> String:
	if ProjectSettings.has_setting("auth/id_token"):
		return ProjectSettings.get_setting("auth/id_token")
	return ""

# Verifica se o token do Firebase é válido
func verify_firebase_token(token):
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(self._on_token_verification_completed)
	
	# Criamos a URL para verificação do token
	var url = "https://identitytoolkit.googleapis.com/v1/accounts:lookup?key=" + API_KEY
	
	# Preparamos os cabeçalhos da requisição
	var headers = ["Content-Type: application/json"]
	
	# Preparamos o corpo da requisição com o token
	var body = JSON.stringify({"idToken": token})
	
	# Fazemos a requisição para o Firebase
	http_request.request(url, headers, HTTPClient.METHOD_POST, body)

# Callback para quando a verificação do token for concluída
func _on_token_verification_completed(_result, response_code, _headers, body):
	var json = JSON.new()
	json.parse(body.get_string_from_utf8())
	var response = json.get_data()
	
	if response_code == 200 and response.has("users") and response["users"].size() > 0:
		# Token válido, usuário autenticado
		current_user = response["users"][0]["localId"]
		save_user_session(current_user)
		print("Sessão do Firebase verificada com sucesso para: ", current_user)
		emit_signal("auth_state_changed", true)
	else:
		# Token inválido ou expirado
		print("Sessão do Firebase inválida ou expirada")
		clear_session()
		emit_signal("auth_state_changed", false)

func is_logged_in():
	return current_user != null

# Salva a sessão do usuário com ID e token
func save_user_session(user_id, id_token = null, user_name = null):
	ProjectSettings.set_setting("auth/" + USER_DATA_KEY, user_id)
	
	# Se tivermos um token, salvamos também
	if id_token != null and !id_token.is_empty():
		ProjectSettings.set_setting("auth/id_token", id_token)
	
	# Se tivermos um nome de usuário, salvamos também
	if user_name != null and !user_name.is_empty():
		ProjectSettings.set_setting("auth/" + USER_NAME_KEY, user_name)
		current_user_name = user_name
	
	ProjectSettings.save()
	current_user = user_id
	emit_signal("auth_state_changed", true)

# Faz login com Firebase
func login_with_email(email, password):
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(self._on_login_completed)
	
	# URL para autenticação com email/senha
	var url = "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=" + API_KEY
	
	# Cabeçalhos da requisição
	var headers = ["Content-Type: application/json"]
	
	# Corpo da requisição
	var body = JSON.stringify({
		"email": email,
		"password": password,
		"returnSecureToken": true
	})
	
	# Requisição para o Firebase
	http_request.request(url, headers, HTTPClient.METHOD_POST, body)

# Registra um novo usuário no Firebase
func register_with_email(email, password):
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(self._on_register_completed)
	
	# URL para criação de conta
	var url = "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=" + API_KEY
	
	# Cabeçalhos da requisição
	var headers = ["Content-Type: application/json"]
	
	# Corpo da requisição
	var body = JSON.stringify({
		"email": email,
		"password": password,
		"returnSecureToken": true
	})
	
	# Requisição para o Firebase
	http_request.request(url, headers, HTTPClient.METHOD_POST, body)

# Callback para quando o login for concluído
func _on_login_completed(_result, response_code, _headers, body):
	var json = JSON.new()
	json.parse(body.get_string_from_utf8())
	var response = json.get_data()
	
	if response_code == 200:
		# Login bem-sucedido
		var user_id = response["localId"]
		var id_token = response["idToken"]
		save_user_session(user_id, id_token)
		print("Login realizado com sucesso para: ", user_id)
		emit_signal("auth_state_changed", true)
		return true
	else:
		# Falha no login
		var error_message = "Erro de autenticação"
		if response.has("error"):
			error_message = response["error"]["message"]
		print("Falha no login: ", error_message)
		emit_signal("auth_state_changed", false)
		return false

# Callback para quando o registro for concluído
func _on_register_completed(_result, response_code, _headers, body):
	var json = JSON.new()
	json.parse(body.get_string_from_utf8())
	var response = json.get_data()
	
	if response_code == 200:
		# Registro bem-sucedido
		var user_id = response["localId"]
		var id_token = response["idToken"]
		save_user_session(user_id, id_token)
		print("Registro realizado com sucesso para: ", user_id)
		emit_signal("auth_state_changed", true)
		return true
	else:
		# Falha no registro
		var error_message = "Erro no registro"
		if response.has("error"):
			error_message = response["error"]["message"]
		print("Falha no registro: ", error_message)
		emit_signal("auth_state_changed", false)
		return false

func get_current_user_id():
	return current_user

# Limpa todos os dados da sessão
func clear_session():
	ProjectSettings.set_setting("auth/" + USER_DATA_KEY, null)
	ProjectSettings.set_setting("auth/id_token", null)
	ProjectSettings.set_setting("auth/" + USER_NAME_KEY, null)
	ProjectSettings.save()
	current_user = null
	current_user_name = null
	emit_signal("auth_state_changed", false)
	print("Sessão encerrada")

# Salva uma pontuação para o usuário atual
func save_score(score):
	if not is_logged_in():
		print("Não é possível salvar pontuação: usuário não está logado")
		return false
		
	var user_name = get_current_user_name()
	if user_name == null or user_name.is_empty():
		user_name = "Jogador " + current_user.substr(0, 5)
	
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(self._on_score_saved)
	
	# URL para salvar no Realtime Database
	# Salvamos na estrutura scores/USER_ID/{pontuação e nome}
	var url = DATABASE_URL + "scores/" + current_user + ".json"
	
	# Cabeçalhos da requisição
	var headers = ["Content-Type: application/json"]
	
	# Corpo da requisição com pontuação e nome
	var body = JSON.stringify({
		"score": score,
		"name": user_name,
		"timestamp": Time.get_unix_time_from_system()
	})
	
	# Requisição para o Firebase Realtime Database
	http_request.request(url, headers, HTTPClient.METHOD_PUT, body)
	return true

# Carrega todas as pontuações
func load_scores():
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(self._on_scores_loaded)
	
	# URL para ler do Realtime Database
	var url = DATABASE_URL + "scores.json"
	
	# Requisição para o Firebase Realtime Database
	http_request.request(url)

# Callback para quando a pontuação for salva
func _on_score_saved(_result, response_code, _headers, body):
	var json = JSON.new()
	json.parse(body.get_string_from_utf8())
	var _response = json.get_data()
	
	if response_code == 200:
		print("Pontuação salva com sucesso")
		# Após salvar, carregamos novamente todas as pontuações
		load_scores()
	else:
		print("Falha ao salvar pontuação: ", response_code)

# Callback para quando as pontuações forem carregadas
func _on_scores_loaded(_result, response_code, _headers, body):
	if response_code != 200:
		print("Falha ao carregar pontuações: ", response_code)
		return
		
	var json = JSON.new()
	json.parse(body.get_string_from_utf8())
	var raw_scores = json.get_data()
	
	if raw_scores == null:
		print("Nenhuma pontuação encontrada")
		emit_signal("scores_updated", [])
		return
		
	# Convertemos o dicionário em um array para poder ordenar
	var scores_array = []
	for user_id in raw_scores.keys():
		var score_data = raw_scores[user_id]
		scores_array.append({
			"user_id": user_id,
			"name": score_data.get("name", "Jogador Desconhecido"),
			"score": score_data.get("score", 0),
			"timestamp": score_data.get("timestamp", 0)
		})
	
	# Ordenamos por pontuação (do maior para o menor)
	scores_array.sort_custom(func(a, b): return a["score"] > b["score"])
	
	# Emitimos o sinal com as pontuações ordenadas
	emit_signal("scores_updated", scores_array)
	print("Pontuações carregadas e ordenadas")

# Obtém o nome do usuário atual
func get_current_user_name():
	# Se já temos em memória, retornamos
	if current_user_name != null:
		return current_user_name
		
	# Senão, tentamos carregar das configurações
	if ProjectSettings.has_setting("auth/" + USER_NAME_KEY):
		current_user_name = ProjectSettings.get_setting("auth/" + USER_NAME_KEY)
		return current_user_name
	
	return null

# Define o nome do usuário atual
func set_current_user_name(username):
	current_user_name = username
	ProjectSettings.set_setting("auth/" + USER_NAME_KEY, username)
	ProjectSettings.save()
	
	# Se o usuário estiver logado, atualizamos o nome no banco de dados também
	if is_logged_in():
		var http_request = HTTPRequest.new()
		add_child(http_request)
		
		var url = DATABASE_URL + "users/" + current_user + "/name.json"
		var headers = ["Content-Type: application/json"]
		var body = JSON.stringify(username)
		
		http_request.request(url, headers, HTTPClient.METHOD_PUT, body)
