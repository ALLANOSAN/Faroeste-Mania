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

# Função para diagnosticar problemas de conexão com o Firebase
func test_firebase_connection():
	print("Testando conexão com o Firebase...")
	
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	# Função para processar a resposta
	http_request.request_completed.connect(func(_result, response_code, _headers, body):
		print("Teste de conexão com Firebase - Código: ", response_code)
		if response_code == 200:
			print("Conexão com Firebase OK!")
			var json = JSON.new()
			json.parse(body.get_string_from_utf8())
			var data = json.get_data()
			print("Dados recebidos: ", data)
		else:
			print("Falha na conexão com Firebase! Corpo da resposta:", body.get_string_from_utf8())
			print("AVISO: Configure as regras do Firebase conforme o arquivo firebase_rules_atualizadas.txt")
		http_request.queue_free()
	)
	
	# Tenta acessar o nó "scores" do Firebase (sem auth)
	var url = DATABASE_URL + "scores.json"
	http_request.request(url)
	
	return true

func _ready():
	print("AuthManager inicializando...")
	
	# Teste de conexão com o Firebase
	test_firebase_connection()
	
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
		# O nome do usuário já deve ter sido definido em set_current_user_name
		var user_name = get_current_user_name()
		save_user_session(user_id, id_token, user_name)
		print("Registro realizado com sucesso para: ", user_id, " com nome: ", user_name)
		
		# Salvamos o nome no Firebase Database também
		if user_name != null and !user_name.is_empty():
			var http_request = HTTPRequest.new()
			add_child(http_request)
			
			var url = DATABASE_URL + "users/" + user_id + "/name.json"
			var headers = ["Content-Type: application/json"]
			var request_body = JSON.stringify(user_name)
			
			http_request.request_completed.connect(self._on_user_name_saved)
			http_request.request(url, headers, HTTPClient.METHOD_PUT, request_body)
			
# Callback para quando o nome do usuário for salvo no Firebase
func _on_user_name_saved(_result, response_code, _headers, _body):
	print("Nome de usuário salvo no Firebase: ", response_code == 200)
	var http_request = get_child(get_child_count() - 1)
	if http_request is HTTPRequest:
		http_request.queue_free()
		
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
	
	# URL para salvar no Realtime Database (usamos o caminho scores e pontuacoes para compatibilidade)
	var url = DATABASE_URL + "scores.json"
	
	# Tentaremos também salvar na estrutura "pontuacoes" para compatibilidade com regras existentes
	var url_pontuacoes = DATABASE_URL + "pontuacoes/" + current_user + ".json"
	
	# Cabeçalhos da requisição
	var headers = ["Content-Type: application/json"]
	
	# Corpo da requisição com pontuação e nome
	var body = JSON.stringify({
		"user_id": current_user,
		"score": score,
		"name": user_name,
		"timestamp": Time.get_unix_time_from_system()
	})
	
	# Requisição para salvar em "scores" (usando POST para criar um novo nó)
	http_request.request(url, headers, HTTPClient.METHOD_POST, body)
	
	# Requisição para salvar também em "pontuacoes/user_id" (usando PUT para atualizar nó existente)
	var http_request2 = HTTPRequest.new()
	add_child(http_request2)
	http_request2.request_completed.connect(self._on_pontuacoes_saved)
	http_request2.request(url_pontuacoes, headers, HTTPClient.METHOD_PUT, body)
	
	print("Pontuação %d enviada ao Firebase" % score)
	return true
	
# Callback para quando a pontuação for salva em "pontuacoes"
func _on_pontuacoes_saved(_result, _response_code, _headers, _body):
	# Liberar o HTTPRequest após a conclusão
	var http_request = get_child(get_child_count() - 1)  # Obtém o último filho (que deve ser o HTTPRequest)
	if http_request is HTTPRequest:
		http_request.queue_free()
	print("Pontuação também salva na estrutura 'pontuacoes'")

# Carrega todas as pontuações
func load_scores():
	print("Carregando pontuações do leaderboard...")
	
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(self._on_scores_loaded)
	
	# URL para buscar todos os scores (sem ordenação ou limitação no servidor)
	# Tentando ambos os caminhos: "scores" e "pontuacoes" para compatibilidade
	var url = DATABASE_URL + "scores.json"
	
	print("URL de requisição para pontuações: " + url)
	
	print("URL de requisição: " + url)
	
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
	print("Resposta do servidor recebida (código %d)" % response_code)
	
	# Casos específicos de erros de autenticação
	if response_code == 401:
		print("ERRO 401: Não autorizado. As regras do Firebase estão impedindo o acesso anônimo.")
		print("Consultando estrutura alternativa 'pontuacoes'...")
		
		# Tenta carregar de "pontuacoes" em vez de "scores"
		var http_request = HTTPRequest.new()
		add_child(http_request)
		http_request.request_completed.connect(self._on_backup_scores_loaded)
		var url = DATABASE_URL + "pontuacoes.json"
		http_request.request(url)
		return
	
	if response_code == 403:
		print("ERRO 403: Proibido. Verifique as regras do Firebase.")
		emit_signal("scores_updated", [])
		return
	
	if response_code != 200:
		# Outros erros de requisição
		print("Falha ao carregar pontuações: ", response_code)
		if body:
			print("Resposta do servidor:", body.get_string_from_utf8())
		emit_signal("scores_updated", [])
		return
	
	# Decodifica a resposta JSON
	var json = JSON.new()
	var json_string = body.get_string_from_utf8()
	var error = json.parse(json_string)
	
	if error != OK:
		print("Erro ao decodificar JSON:", json.get_error_message())
		print("Resposta recebida:", json_string)
		emit_signal("scores_updated", [])
		return
	
	var scores_data = json.get_data()
	
	if scores_data == null:
		print("Dados vazios recebidos do Firebase (null)")
		emit_signal("scores_updated", [])
		return
		
	# Se não for um dicionário, pode ser que não tenha dados ainda
	if typeof(scores_data) != TYPE_DICTIONARY:
		print("Formato de dados inválido:", typeof(scores_data))
		emit_signal("scores_updated", [])
		return
		
	# Se for um dicionário vazio, não há pontuações
	if scores_data.is_empty():
		print("Nenhuma pontuação encontrada")
		emit_signal("scores_updated", [])
		return
	
	# Convertemos o dicionário em um array para poder ordenar
	var scores_array = []
	for key in scores_data.keys():
		var score_entry = scores_data[key]
		if not score_entry is Dictionary:
			print("Entrada inválida encontrada:", score_entry)
			continue
			
		# Certifique-se de que o score é um número
		if score_entry.has("score"):
			# Converter para número, mesmo se estiver como string
			if score_entry["score"] is String:
				score_entry["score"] = score_entry["score"].to_int()
			elif score_entry["score"] is float:
				score_entry["score"] = int(score_entry["score"])
		else:
			score_entry["score"] = 0
		
		# Garantir que temos um nome
		if not score_entry.has("name") or score_entry["name"] == null or score_entry["name"] == "":
			score_entry["name"] = "Jogador Anônimo"
			
		scores_array.append(score_entry)
	
	if scores_array.is_empty():
		print("Nenhuma pontuação válida encontrada após processamento")
		emit_signal("scores_updated", [])
		return
	
	# Ordenamos por pontuação (do maior para o menor)
	scores_array.sort_custom(func(a, b): return a["score"] > b["score"])
	
	# Limitar a exatamente 10 registros
	if scores_array.size() > 10:
		scores_array = scores_array.slice(0, 10)
	
	print("Pontuações carregadas: %d registros" % scores_array.size())
	
	# Emitimos o sinal com as pontuações ordenadas
	# Emite o sinal com as pontuações (limitado a 10)
	emit_signal("scores_updated", scores_array)

# Função alternativa para carregar pontuações da estrutura "pontuacoes"
func _on_backup_scores_loaded(_result, response_code, _headers, body):
	print("Resposta do servidor (backup) recebida (código %d)" % response_code)
	
	if response_code != 200:
		print("Falha ao carregar pontuações de backup.")
		# Usando dados de exemplo para que a interface não fique vazia
		var mock_data = [
			{"name": "Jogador Teste 1", "score": 1000},
			{"name": "Jogador Teste 2", "score": 800},
			{"name": "Jogador Teste 3", "score": 600}
		]
		emit_signal("scores_updated", mock_data)
		return
	
	# Decodifica a resposta JSON
	var json = JSON.new()
	var json_string = body.get_string_from_utf8()
	var error = json.parse(json_string)
	
	if error != OK or json.get_data() == null:
		print("Erro ao decodificar JSON de backup ou dados vazios")
		var mock_data = [
			{"name": "Jogador Teste 1", "score": 1000},
			{"name": "Jogador Teste 2", "score": 800},
			{"name": "Jogador Teste 3", "score": 600}
		]
		emit_signal("scores_updated", mock_data)
		return
		
	var scores_data = json.get_data()
	
	# Convertemos o dicionário em um array para poder ordenar
	var scores_array = []
	for user_id in scores_data.keys():
		var score_data = scores_data[user_id]
		if score_data is Dictionary:
			# Certifique-se de que temos os campos necessários
			score_data["user_id"] = user_id
			if not score_data.has("name") or score_data["name"] == null:
				score_data["name"] = "Jogador " + user_id.substr(0, 5)
				
			if score_data.has("score"):
				# Converter para número se estiver como string
				if score_data["score"] is String:
					score_data["score"] = score_data["score"].to_int()
				scores_array.append(score_data)
	
	# Ordenamos por pontuação (do maior para o menor)
	scores_array.sort_custom(func(a, b): return a["score"] > b["score"])
	
	# Limitar a exatamente 10 registros
	if scores_array.size() > 10:
		scores_array = scores_array.slice(0, 10)
	
	print("Pontuações de backup carregadas: %d registros" % scores_array.size())
	
	# Emitimos o sinal com as pontuações ordenadas
	emit_signal("scores_updated", scores_array)

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
