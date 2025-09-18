extends Node

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
	
	# Se não tivermos o SDK de LootLocker, simulamos localmente para testes
	if not ClassDB.class_exists("LL_WhiteLabel"):
		print("AVISO: SDK LootLocker não encontrado, usando simulação local")
		_mock_register_user(email)
		return
		
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
	
	# Chama a API de registro - verifica os métodos disponíveis
	var response = null
	
	# Tenta o método SignUp do LL_WhiteLabel (nome usado nas versões mais recentes)
	response = await LL_WhiteLabel.SignUp.new(email, password).send()
	
	if not response.success:
		print("Erro no registro LootLocker: ", response.error_data.message)
		register_failed.emit(response.error_data.message)
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
	
	# Se não tivermos o SDK de LootLocker, simulamos localmente para testes
	if not ClassDB.class_exists("LL_WhiteLabel") or not ClassDB.class_exists("LL_Authentication"):
		print("AVISO: SDK LootLocker não encontrado, usando simulação local")
		_mock_login_user(email)
		return
	
	# Primeiro autenticamos com White Label
	var login_response = await LL_WhiteLabel.Login.new(email, password, remember_me).send()
	if not login_response.success:
		print("Erro no login White Label: ", login_response.error_data.message)
		login_failed.emit(login_response.error_data.message)
		return
	
	# Agora temos que iniciar uma sessão no LootLocker
	print("Iniciando sessão LootLocker após autenticação White Label...")
	
	# Usamos GuestSession para iniciar a sessão (temporário até termos o método correto)
	# Importante: Isso NÃO é um login de convidado real, estamos apenas
	# usando este método para obter uma sessão válida após a autenticação White Label
	var response = await LL_Authentication.GuestSession.new().send()
	
	if not response or not response.success:
		print("Erro ao iniciar sessão LootLocker")
		var error_msg = response.error_data.message if response and response.has("error_data") else "Erro desconhecido"
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
func submit_score(score, _username = ""):
	print("Enviando pontuação ", score, " para o LootLocker...")
	if not is_logged_in:
		print("Não é possível enviar pontuação: usuário não está logado")
		score_submitted.emit(false, 0)
		return
	
	if not ClassDB.class_exists("LL_Leaderboards"):
		print("AVISO: SDK LootLocker não encontrado, usando simulação local")
		_mock_submit_score(score)
		return
	
	# Envia a pontuação para o LootLocker
	# O segundo parâmetro vazio "" usa o player_id atual automaticamente
	var response = await LL_Leaderboards.SubmitScore.new(leaderboard_key, score, "").send()
	if not response.success:
		print("Erro ao enviar pontuação: ", response.error_data.message)
		score_submitted.emit(false, 0)
		return
	
	print("Pontuação enviada com sucesso! Rank: ", response.rank)
	
	# Atualiza a pontuação máxima do jogador se necessário
	if score > player_high_score:
		player_high_score = score
	
	score_submitted.emit(true, response.rank)
	
	# Atualiza a lista de pontuações
	load_scores()

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
	if not ClassDB.class_exists("LL_Leaderboards"):
		print("AVISO: SDK LootLocker não encontrado, usando simulação local")
		_mock_load_scores()
		return
	
	# Carrega as pontuações do leaderboard (máximo 10)
	var response = await LL_Leaderboards.GetScoreList.new(leaderboard_key, 10).send()
	if not response.success:
		print("Erro ao carregar pontuações: ", response.error_data.message)
		scores_updated.emit([]) # Lista vazia em caso de erro
		return
	
	# Formata as pontuações em um formato comum para o resto do jogo
	var formatted_scores = []
	for item in response.items:
		formatted_scores.append({
			"rank": item.rank,
			"score": item.score,
			"name": item.player.name if item.player.name else "Jogador " + str(item.player.id),
			"user_id": str(item.player.id)
		})
	
	print("Pontuações carregadas com sucesso: ", formatted_scores.size(), " entradas")
	scores_updated.emit(formatted_scores)
	
	# Atualiza a pontuação máxima do jogador atual
	for score_entry in formatted_scores:
		if score_entry.user_id == player_id and score_entry.score > player_high_score:
			player_high_score = score_entry.score

# Simulação para teste quando o SDK não está disponível
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
	if not ClassDB.class_exists("LL_Authentication"):
		_mock_logout()
		return
	
	# Tenta encerrar a sessão no LootLocker
	var _response = null
	
	# Tenta com o método EndSession - este é o método na versão recente da API
	_response = await LL_Authentication.EndSession.new().send()
	
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
	# No mundo real, isso deveria pegar todos os rankings em lotes, mas para simplicidade,
	# vamos buscar os primeiros 100 e verificar se o jogador está lá
	if not ClassDB.class_exists("LL_Leaderboards"):
		return 0
	
	# Busca os primeiros 100 jogadores no leaderboard
	var response = await LL_Leaderboards.GetScoreList.new(leaderboard_key, 100).send()
	if not response.success:
		print("Erro ao carregar ranking completo: ", response.error_data.message)
		return 0
		
	# Procura pelo jogador atual na lista
	for item in response.items:
		if str(item.player.id) == player_id:
			return item.rank
	
	# Se não encontrou o jogador nos primeiros 100, retorna 0 (sem classificação)
	return 0

func set_player_name(new_name: String):
	player_name = new_name
	# Implementação usando Player Names API:
	if ClassDB.class_exists("LL_Players") and is_logged_in:
		var response = await LL_Players.SetPlayerName.new(new_name).send()
		if not response.success:
			print("Erro ao definir nome do jogador: ", response.error_data.message)
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
