extends Node

# As classes do SDK LootLocker já são carregadas automaticamente pelo Godot
# como classes globais, então não precisamos carregá-las explicitamente

# Funções para criar implementações simuladas (serão usadas apenas se o SDK não for encontrado)
func _create_simulated_white_label():
	var cls = {}
	cls.SignUp = _create_simulated_signup_class()
	cls.Login = _create_simulated_login_class()
	return cls
	
func _create_simulated_signup_class():
	var cls = {}
	cls.new = func(email, password):
		var obj = {}
		obj.email = email
		obj.password = password
		obj.send = func():
			# Simulação de resposta
			return {"success": true}
		return obj
	return cls
	
func _create_simulated_login_class():
	var cls = {}
	cls.new = func(email, password, remember_me_arg = true):
		var obj = {}
		obj.email = email
		obj.password = password
		obj.remember_me = remember_me_arg
		obj.send = func():
			# Simulação de resposta
			return {"success": true}
		return obj
	return cls
	
func _create_simulated_authentication():
	var cls = {}
	cls.GuestSession = _create_simulated_guest_session_class()
	cls.EndSession = _create_simulated_end_session_class()
	return cls
	
func _create_simulated_guest_session_class():
	var cls = {}
	cls.new = func():
		var obj = {}
		obj.send = func():
			# Simulação de resposta
			return {
				"success": true,
				"player_id": "123456",
				"player_identifier": "guest",
				"player_name": "Jogador Convidado"
			}
		return obj
	return cls
	
func _create_simulated_end_session_class():
	var cls = {}
	cls.new = func():
		var obj = {}
		obj.send = func():
			# Simulação de resposta
			return {"success": true}
		return obj
	return cls
	
func _create_simulated_leaderboards():
	var cls = {}
	cls.SubmitScore = _create_simulated_submit_score_class()
	cls.GetScoreList = _create_simulated_get_score_list_class()
	return cls
	
func _create_simulated_submit_score_class():
	var cls = {}
	cls.new = func(key, score, id = ""):
		var obj = {}
		obj.leaderboard_key = key
		obj.score = score
		obj.player_id = id
		obj.send = func():
			# Simulação de resposta
			return {"success": true, "rank": 1}
		return obj
	return cls
	
func _create_simulated_get_score_list_class():
	var cls = {}
	cls.new = func(key, limit = 10):
		var obj = {}
		obj.leaderboard_key = key
		obj.limit = limit
		obj.send = func():
			# Simulação de resposta
			return {"success": true, "items": []}
		return obj
	return cls
	
func _create_simulated_players():
	var cls = {}
	cls.SetPlayerName = _create_simulated_set_player_name_class()
	return cls
	
func _create_simulated_set_player_name_class():
	var cls = {}
	cls.new = func(name_arg):
		var obj = {}
		obj.name = name_arg
		obj.send = func():
			# Simulação de resposta
			return {"success": true}
		return obj
	return cls

signal login_success(player_data)
signal login_failed(error)
signal register_success(player_data)
signal register_failed(error)
signal auth_state_changed(is_logged_in)
signal scores_updated(scores)
signal score_submitted(success, rank)

# Variáveis para o estado do usuário
var player_id := ""
var player_identifier := ""
var player_name := ""
var is_logged_in := false
var player_high_score := 0

# Configurações do jogo
var leaderboard_key := "faroeste_leaderboard"
var remember_me := true # Define se o jogo deve "lembrar" do usuário entre sessões
var remember_me_duration_days := 30 # Duração do "lembrar" em dias

func _ready():
	# Verifica se o SDK do LootLocker está disponível
	print("Inicializando LootLocker Manager")
	
	# Verifica se o arquivo de configuração LootLockerSettings.cfg existe na raiz
	var file = FileAccess.open("res://LootLockerSettings.cfg", FileAccess.READ)
	if file:
		print("Arquivo de configuração LootLocker encontrado")
		file.close()
	else:
		print("AVISO: Arquivo LootLockerSettings.cfg não encontrado! Crie este arquivo na raiz do projeto.")
	
	# Verifica se existe uma sessão salva anteriormente
	check_existing_session()
	
# Verifica se existe uma sessão persistente salva
func check_existing_session():
	print("Verificando se existe uma sessão salva...")
	if not ClassDB.class_exists("LL_Authentication"):
		print("AVISO: SDK LootLocker não encontrado, verificação de sessão ignorada")
		return false
	
	# Como não estamos usando login de convidado, vamos tentar verificar
	# se o usuário já estava logado anteriormente pela existência de dados salvos localmente
	
	# Verificamos se temos os dados do usuário salvos nas preferências do usuário
	var config = ConfigFile.new()
	var err = config.load("user://lootlocker_session.cfg")
	if err == OK:
		var email = config.get_value("auth", "email", "")
		var password = config.get_value("auth", "password", "")
		
		if email != "" and password != "":
			print("Dados de login encontrados, tentando autenticar...")
			# Tentamos fazer login com os dados salvos
			await login_user(email, password)
			return is_logged_in # Retorna o resultado do login
	
	print("Nenhuma sessão salva encontrada")
	return false

# Registro de novo usuário (White Label)
func register_user(email: String, password: String):
	print("Registrando novo usuário no LootLocker...")
	
	# Verifica formato de email básico
	if not _is_valid_email(email):
		print("Erro: formato de email inválido")
		register_failed.emit("Formato de email inválido")
		return
		
	# Verifica tamanho da senha
	if password.length() < 8:
		print("Erro: senha muito curta (mínimo 8 caracteres)")
		register_failed.emit("Senha muito curta (mínimo 8 caracteres)")
		return
	
	# Chama a API de registro
	var response = await LL_WhiteLabel.SignUp.new(email, password).send()
	
	if not response.success:
		var error_message = "Erro desconhecido"
		if response.has("error_data") and response.error_data.has("message"):
			error_message = response.error_data.message
		print("Erro no registro LootLocker: ", error_message)
		register_failed.emit(error_message)
		return
		
	print("Usuário registrado com sucesso! Email: ", email)
	
	# Faz login automático após o registro
	login_user(email, password)
	
	# Emite sinal de registro bem-sucedido
	var player_data = {
		"email": email
	}
	register_success.emit(player_data)

# Login com usuário/senha (White Label)
func login_user(email: String, password: String):
	print("Fazendo login no LootLocker com email/senha...")
	
	# Primeiro autenticamos com White Label
	var login_response = await LL_WhiteLabel.Login.new(email, password, remember_me).send()
	if not login_response.success:
		var error_message = "Erro desconhecido"
		if login_response.has("error_data") and login_response.error_data.has("message"):
			error_message = login_response.error_data.message
		print("Erro no login White Label: ", error_message)
		login_failed.emit(error_message)
		return
	
	# Agora temos que iniciar uma sessão no LootLocker
	print("Iniciando sessão LootLocker após autenticação White Label...")
	
	# Usamos GuestSession para iniciar a sessão
	var response = await LL_Authentication.GuestSession.new().send()
	
	if not response or not response.success:
		print("Erro ao iniciar sessão LootLocker")
		var error_msg = "Erro desconhecido"
		if response and response.has("error_data") and response.error_data.has("message"):
			error_msg = response.error_data.message
		login_failed.emit(error_msg)
		return
		
	# Login bem sucedido - substituímos os dados de convidado pelos dados do usuário White Label
	response.player_identifier = email # Usamos o email como identificador
	_handle_successful_login(response)
	
	# Se marcou "lembrar-me", salvamos as credenciais localmente
	if remember_me:
		_save_credentials(email, password)

# Função para salvar credenciais localmente
func _save_credentials(email: String, password: String):
	print("Salvando credenciais para login automático futuro...")
	var config = ConfigFile.new()
	config.set_value("auth", "email", email)
	config.set_value("auth", "password", password)
	var err = config.save("user://lootlocker_session.cfg")
	if err != OK:
		print("Erro ao salvar credenciais: ", err)
	else:
		print("Credenciais salvas com sucesso")
	
# Autenticação como convidado (Guest) - NÃO USAR
func login_guest():
	print("AVISO: Login de convidado não é permitido neste aplicativo")
	print("Por favor, use o login com email e senha em vez disso")
	
	# Emitir erro
	login_failed.emit("Login de convidado não é permitido. Por favor, crie uma conta ou faça login com suas credenciais.")

# Função de processamento de login bem-sucedido
func _handle_successful_login(response):
	print("Login LootLocker bem-sucedido")
	is_logged_in = true
	player_id = str(response.player_id)
	player_identifier = response.player_identifier
	player_name = response.player_name if response.player_name else "Jogador " + player_id
	
	var player_data = {
		"player_id": player_id,
		"player_name": player_name,
	}
	
	# Emite sinais de estado
	auth_state_changed.emit(true)
	login_success.emit(player_data)
	
	# Carrega as pontuações após o login
	load_scores()

# Simulação para teste quando o SDK não está disponível
func _mock_register_user(email: String):
	print("Simulando registro de usuário: ", email)
	await get_tree().create_timer(0.5).timeout
	
	# Simula registro bem-sucedido
	var player_data = {
		"email": email
	}
	register_success.emit(player_data)
	
	# Faz login automático após o registro
	_mock_login_user(email)

# Simulação de login de usuário com credenciais
func _mock_login_user(email: String):
	print("Simulando login de usuário: ", email)
	await get_tree().create_timer(0.5).timeout
	
	is_logged_in = true
	player_id = "user_" + email.md5_text().substr(0, 6)
	player_identifier = email
	player_name = email.split("@")[0] # Usa parte do email como nome
	
	var player_data = {
		"player_id": player_id,
		"player_name": player_name,
	}
	
	auth_state_changed.emit(true)
	login_success.emit(player_data)
	
	# Simula carregar pontuações
	_mock_load_scores()
	
# Simulação para teste quando o SDK não está disponível
func _mock_login_guest():
	# Simulação de login para testes
	print("Usando login simulado (mock)")
	await get_tree().create_timer(0.5).timeout
	
	is_logged_in = true
	player_id = "123456"
	player_identifier = "guest-test-user"
	player_name = "Jogador Teste"
	
	var player_data = {
		"player_id": player_id,
		"player_name": player_name,
	}
	
	auth_state_changed.emit(true)
	login_success.emit(player_data)
	
	# Simula carregar pontuações
	_mock_load_scores()

# Envio de pontuação para o leaderboard
# Função para enviar a pontuação do jogador atual
func submit_score(score: int):
	print("Enviando pontuação para o LootLocker: ", score)
	
	# Verifica se o usuário está logado
	if not is_logged_in:
		print("Erro: Usuário não logado. Pontuação não enviada.")
		score_submitted.emit(false, 0)
		return
	
	# Envia a pontuação para o LootLocker
	# O segundo parâmetro vazio "" usa o player_id atual automaticamente
	var response = await LL_Leaderboards.SubmitScore.new(leaderboard_key, score, "").send()
	if not response.success:
		var error_message = "Erro desconhecido"
		if response.has("error_data") and response.error_data.has("message"):
			error_message = response.error_data.message
		print("Erro ao enviar pontuação: ", error_message)
		score_submitted.emit(false, 0)
		return
	
	print("Pontuação enviada com sucesso! Rank: ", response.rank)
	score_submitted.emit(true, response.rank)
	
	# Atualiza a pontuação máxima do jogador se necessário
	if score > player_high_score:
		player_high_score = score

# Simulação para teste quando o SDK não está disponível
func _mock_submit_score(score):
	# Simula o envio de pontuação
	await get_tree().create_timer(0.5).timeout
	
	print("Simulando envio de pontuação: ", score)
	if score > player_high_score:
		player_high_score = score
	
	score_submitted.emit(true, 1)
	_mock_load_scores()

# Carrega as pontuações do leaderboard
func load_scores():
	print("Carregando pontuações do LootLocker...")
	
	# Carrega as pontuações do leaderboard (máximo 10)
	var response = await LL_Leaderboards.GetScoreList.new(leaderboard_key, 10).send()
	if not response.success:
		var error_message = "Erro desconhecido"
		if response.has("error_data") and response.error_data.has("message"):
			error_message = response.error_data.message
		print("Erro ao carregar pontuações: ", error_message)
		scores_updated.emit([]) # Lista vazia em caso de erro
		return
	
	# Formata as pontuações em um formato comum para o resto do jogo
	var formatted_scores = []
	if response.has("items") and response.items.size() > 0:
		for item in response.items:
			formatted_scores.append({
				"rank": item.get("rank", 0),
				"score": item.get("score", 0),
				"name": item.get("player", {}).get("name", "Jogador Anônimo"),
				"user_id": str(item.get("player", {}).get("id", "0"))
			})
	else:
		# Se não temos items, usamos dados simulados
		_mock_load_scores()
		return
	
	print("Pontuações carregadas com sucesso: ", formatted_scores.size(), " entradas")
	scores_updated.emit(formatted_scores)
	
	# Atualiza a pontuação máxima do jogador atual
	for score_entry in formatted_scores:
		if score_entry.user_id == player_id and score_entry.score > player_high_score:
			player_high_score = score_entry.score # Simulação para teste quando o SDK não está disponível
func _mock_load_scores():
	# Simula carregar pontuações
	await get_tree().create_timer(0.5).timeout
	
	var mock_scores = [
		{"rank": 1, "score": 100, "name": "Campeão", "user_id": "111"},
		{"rank": 2, "score": 90, "name": "Segundo", "user_id": "222"},
		{"rank": 3, "score": 80, "name": "Terceiro", "user_id": "333"},
		{"rank": 4, "score": 70, "name": "Quarto", "user_id": "444"},
		{"rank": 5, "score": 60, "name": "Quinto", "user_id": player_id} # Este é o jogador atual
	]
	
	print("Simulando carregamento de pontuações")
	scores_updated.emit(mock_scores)

# Fazer logout
func logout():
	print("Fazendo logout do LootLocker...")
	
	# Tenta encerrar a sessão no LootLocker
	var _response = await LL_Authentication.EndSession.new().send()
	
	# Mesmo se falhar, ainda limparemos os dados locais
	
	# Limpa os dados do jogador
	player_id = ""
	player_identifier = ""
	player_name = ""
	is_logged_in = false
	player_high_score = 0
	
	# Remove as credenciais salvas
	var dir = DirAccess.open("user://")
	if dir and dir.file_exists("lootlocker_session.cfg"):
		dir.remove("lootlocker_session.cfg")
		print("Arquivo de sessão removido")
	
	auth_state_changed.emit(false)
	print("Logout concluído")

# Simulação para teste quando o SDK não está disponível
func _mock_logout():
	await get_tree().create_timer(0.3).timeout
	
	player_id = ""
	player_identifier = ""
	player_name = ""
	is_logged_in = false
	player_high_score = 0
	
	auth_state_changed.emit(false)
	print("Simulação de logout concluída")

# Funções auxiliares
func get_user_id() -> String:
	return player_id

func get_player_name() -> String:
	return player_name

func get_player_high_score() -> int:
	return player_high_score
	
# Função para obter o rank específico do jogador atual
func get_player_rank() -> Dictionary:
	# Se não estiver logado, retorna zeros
	if not is_logged_in:
		return {"rank": 0, "total": 0}
	
	# Para buscar o rank específico do jogador, precisamos fazer uma chamada à API do LootLocker
	# que retorna o rank do jogador no leaderboard
	if ClassDB.class_exists("LL_Leaderboards"):
		print("Buscando rank do jogador no leaderboard...")
		# A API não fornece uma função direta para obter o rank do jogador,
		# então precisamos buscar o leaderboard completo
		return {"rank": await _get_player_rank_full(), "total": 100} # 100 é um valor aproximado
	else:
		# Simulação para testes
		return {"rank": 5, "total": 50} # Valores fictícios para testes

# Função interna para buscar o rank do jogador no leaderboard completo
func _get_player_rank_full() -> int:
	print("Buscando rank específico do jogador ID:", player_id)
	
	# Usar a API GetMemberRank que retorna diretamente o rank do jogador, 
	# independentemente de sua posição no ranking
	var response = await LL_Leaderboards.GetMemberRank.new(leaderboard_key, player_id).send()
	
	if not response.success:
		var error_message = "Erro desconhecido"
		if response.has("error_data") and response.error_data.has("message"):
			error_message = response.error_data.message
		print("Erro ao buscar rank do jogador: ", error_message)
		
		# O jogador pode não ter uma pontuação registrada ainda
		if error_message.contains("not found") or error_message.contains("não encontrado"):
			print("Jogador ainda não tem pontuação registrada neste leaderboard")
		
		return 0
		
	# A API retorna diretamente o rank do jogador
	var rank = 0
	if response.has("rank"):
		rank = response.rank
	print("Rank do jogador obtido com sucesso: ", rank)
	
	return rank

func set_player_name(new_name: String):
	player_name = new_name
	# Implementação usando Player Names API
	if is_logged_in:
		var response = await LL_Players.SetPlayerName.new(new_name).send()
		if not response.success:
			var error_message = "Erro desconhecido"
			if response.has("error_data") and response.error_data.has("message"):
				error_message = response.error_data.message
			print("Erro ao definir nome do jogador: ", error_message)
			return
		print("Nome do jogador alterado com sucesso para: ", new_name)
		
# Função auxiliar para validação básica de email
func _is_valid_email(email: String) -> bool:
	# Verifica se contém @ e pelo menos um ponto depois do @
	var at_pos = email.find("@")
	if at_pos <= 0:
		return false
	var domain = email.substr(at_pos + 1)
	if domain.find(".") <= 0:
		return false
	return true
