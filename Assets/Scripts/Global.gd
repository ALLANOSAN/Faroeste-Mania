extends Node

# Variáveis globais do jogo
var current_user_id: String = ""
var is_logged_in: bool = false
var player_high_score: int = 0

# Sinais para comunicação entre cenas
signal auth_state_changed(is_logged_in: bool)
signal scores_updated(scores: Array)

# Called when the node enters the scene tree for the first time.
func _ready():
	# Configurar Silent Wolf
	SilentWolf.configure({
		"api_key": "Your API key here", # Substitua pela sua API key
		"game_id": "Your Game ID here", # Substitua pelo seu Game ID
		"log_level": 1
	})

	SilentWolf.configure_scores({
		"open_scene_on_close": "res://Assets/Scenes/MainMenuLogin.tscn"
	})
	
	SilentWolf.configure_auth({
		"redirect_to_scene": "res://Assets/Scenes/MainMenuLogin.tscn",
		"login_scene": "res://addons/silent_wolf/Auth/Login.tscn",
		"email_confirmation_scene": "res://addons/silent_wolf/Auth/ConfirmEmail.tscn",
		"reset_password_scene": "res://addons/silent_wolf/Auth/ResetPassword.tscn",
		"session_duration_seconds": 0,
		"saved_session_expiration_days": 30
	})
	
	# Conectar diretamente aos sinais do SilentWolf
	SilentWolf.Auth.sw_login_complete.connect(_on_sw_login_complete)
	SilentWolf.Auth.sw_logout_complete.connect(_on_sw_logout_complete)
	SilentWolf.Auth.sw_registration_complete.connect(_on_sw_registration_complete)
	SilentWolf.Auth.sw_email_verif_complete.connect(_on_sw_email_verification_complete)
	SilentWolf.Auth.sw_reset_password_complete.connect(_on_sw_reset_password_complete)
	SilentWolf.Auth.sw_session_check_complete.connect(_on_sw_session_check_complete)
	
	# Conexão com o sinal de scores para o leaderboard
	SilentWolf.Scores.sw_scores_complete.connect(_on_sw_scores_complete)
	
	# Verificar sessão existente para autologin
	check_session()

# Funções de autenticação
func login_player(username: String, password: String, remember_me: bool = false):
	SilentWolf.Auth.login_player(username, password, remember_me)

func register_player(username: String, email: String, password: String, confirm_password: String):
	SilentWolf.Auth.register_player(username, email, password, confirm_password)

func verify_email(username: String, code: String):
	SilentWolf.Auth.verify_email(username, code)

func resend_confirmation_code(username: String):
	SilentWolf.Auth.resend_conf_code(username)

func request_password_reset(username: String):
	SilentWolf.Auth.request_player_password_reset(username)

func reset_password(username: String, code: String, new_password: String, confirm_password: String):
	SilentWolf.Auth.reset_player_password(username, code, new_password, confirm_password)

func check_session():
	SilentWolf.Auth.auto_login_player()

func logout():
	SilentWolf.Auth.logout_player()

func is_user_logged_in() -> bool:
	return is_logged_in

func get_current_user_id() -> String:
	return current_user_id

func clear_session():
	logout()

# Callbacks para os sinais do SilentWolf Auth
func _on_sw_login_complete(sw_result: Dictionary):
	if sw_result.success:
		print("Login realizado com sucesso!")
		is_logged_in = true
		current_user_id = SilentWolf.Auth.logged_in_player
		auth_state_changed.emit(true)
	else:
		print("Erro no login: " + ("%s" % sw_result.error))
		is_logged_in = false
		current_user_id = ""
		auth_state_changed.emit(false)

func _on_sw_logout_complete():
	print("Logout realizado com sucesso!")
	is_logged_in = false
	current_user_id = ""
	player_high_score = 0
	auth_state_changed.emit(false)

func _on_sw_registration_complete(sw_result: Dictionary):
	if sw_result.success:
		print("Registro bem-sucedido!")
		# O login só acontece após a verificação de email, se habilitada
	else:
		print("Erro no registro: " + ("%s" % sw_result.error))

func _on_sw_email_verification_complete(sw_result: Dictionary):
	if sw_result.success:
		print("E-mail verificado com sucesso!")
		is_logged_in = true
		current_user_id = SilentWolf.Auth.logged_in_player
		auth_state_changed.emit(true)
	else:
		print("Erro na verificação de e-mail: " + ("%s" % sw_result.error))

func _on_sw_reset_password_complete(sw_result: Dictionary):
	if sw_result.success:
		print("Senha redefinida com sucesso!")
	else:
		print("Erro na redefinição de senha: " + ("%s" % sw_result.error))

func _on_sw_session_check_complete(sw_result: Dictionary):
	if sw_result and sw_result.success:
		print("Sessão válida encontrada!")
		is_logged_in = true
		current_user_id = sw_result.logged_in_player
		auth_state_changed.emit(true)
	else:
		print("Nenhuma sessão válida encontrada ou sessão expirada.")
		is_logged_in = false
		current_user_id = ""

# Funções específicas para o jogo Faroeste Mania
func save_score(score: int):
	"""Salva a pontuação do jogo usando Silent Wolf Scores (100% online)"""
	if is_logged_in and current_user_id != "":
		SilentWolf.Scores.save_score(current_user_id, score)
		print("Pontuação salva no leaderboard: " + ("%d" % score))
		
		# Atualiza a pontuação máxima local
		if score > player_high_score:
			player_high_score = score
			print("Nova pontuação máxima: " + ("%d" % score))
	else:
		print("Usuário não está logado. Pontuação não foi salva.")

func load_scores():
	"""Carrega as pontuações do leaderboard (100% online)"""
	SilentWolf.Scores.get_scores()

func get_player_high_score() -> int:
	"""Retorna a pontuação máxima do jogador"""
	return player_high_score

func get_player_rank() -> Dictionary:
	"""Retorna o rank do jogador e a pontuação total na classificação global"""
	var player_rank = 0
	var total_players = 0
	
	# Verifica se o jogador está logado
	if not is_logged_in or current_user_id == "":
		return {"rank": 0, "total": 0}
	
	# Verifica se temos as pontuações carregadas
	if SilentWolf.Scores.scores.size() > 0:
		total_players = SilentWolf.Scores.scores.size()
		
		# Procura o jogador na lista de pontuações
		for i in range(SilentWolf.Scores.scores.size()):
			if SilentWolf.Scores.scores[i].get("name", "") == current_user_id:
				player_rank = i + 1
				break
	
	return {"rank": player_rank, "total": total_players}

# Callback do Silent Wolf Scores
func _on_sw_scores_complete():
	print("Scores carregados com sucesso!")
	scores_updated.emit(SilentWolf.Scores.scores)

# Funções para gerenciamento de perfil do jogador
func update_username(new_username: String):
	"""Atualiza o nome de usuário do jogador"""
	if is_logged_in and new_username != "":
		# Aqui você implementaria a lógica real para alterar o nome de usuário
		# Por enquanto, apenas atualiza localmente
		current_user_id = new_username
		print("Nome de usuário atualizado para: " + new_username)
		return true
	else:
		print("Erro: Usuário não está logado ou nome inválido")
		return false

func delete_account():
	"""Exclui a conta do jogador"""
	if is_logged_in:
		# Aqui você implementaria a lógica real para excluir a conta
		# Por enquanto, apenas faz logout
		logout()
		print("Conta excluída com sucesso")
		return true
	else:
		print("Erro: Usuário não está logado")
		return false
