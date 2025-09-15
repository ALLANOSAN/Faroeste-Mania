extends Control

@onready var back_button = %BackButton
@onready var player_id_value = %PlayerIDValue
@onready var username_input = %UsernameInput
@onready var save_username_button = %SaveUsernameButton
@onready var status_label = %StatusLabel
@onready var logout_button = %LogoutButton
@onready var delete_account_button = %DeleteAccountButton

@onready var global = get_node("/root/Global")

func _ready():
	# Conectar botões
	back_button.pressed.connect(_on_back_button_pressed)
	save_username_button.pressed.connect(_on_save_username_pressed)
	logout_button.pressed.connect(_on_logout_button_pressed)
	delete_account_button.pressed.connect(_on_delete_account_button_pressed)
	
	# Carregar informações do jogador
	load_player_info()

func load_player_info():
	"""Carrega e exibe as informações do jogador"""
	if global.is_user_logged_in():
		# Mostra ID do jogador
		player_id_value.text = global.get_current_user_id()
		
		# Define o nome de usuário atual no campo de input
		username_input.text = global.get_current_user_id()
		
		print("Informações do jogador carregadas:")
		print("ID: " + global.get_current_user_id())
	else:
		# Se não estiver logado, volta para o menu principal
		get_tree().change_scene_to_file("res://Assets/Scenes/MainMenuLogin.tscn")

func _on_back_button_pressed():
	"""Volta para o menu de opções"""
	get_tree().change_scene_to_file("res://Assets/Scenes/MenuOpções.tscn")

func _on_save_username_pressed():
	"""Salva o novo nome de usuário"""
	var new_username = username_input.text.strip_edges()
	
	if new_username == "":
		show_status("Nome de usuário não pode estar vazio!", Color(1, 0, 0))
		return
	
	if new_username == global.get_current_user_id():
		show_status("Este já é seu nome de usuário atual!", Color(1, 1, 0))
		return
	
	# Aqui você pode implementar a lógica para alterar o nome de usuário
	# Por enquanto, vamos simular o salvamento
	show_status("Nome de usuário alterado com sucesso!", Color(0, 1, 0))
	
	# Atualiza o ID local (em um sistema real, isso viria do servidor)
	global.current_user_id = new_username
	player_id_value.text = new_username
	
	print("Nome de usuário alterado para: " + new_username)

func _on_logout_button_pressed():
	"""Faz logout do jogador"""
	global.clear_session()
	show_status("Logout realizado com sucesso!", Color(0, 1, 0))
	
	# Aguarda um pouco e volta para o menu principal
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://Assets/Scenes/MainMenuLogin.tscn")

func _on_delete_account_button_pressed():
	"""Exclui a conta do jogador"""
	# Mostra confirmação
	var confirm_dialog = AcceptDialog.new()
	confirm_dialog.dialog_text = "Tem certeza que deseja excluir sua conta?\nEsta ação não pode ser desfeita!"
	confirm_dialog.title = "Confirmar Exclusão"
	add_child(confirm_dialog)
	
	# Conecta o sinal de confirmação
	confirm_dialog.confirmed.connect(_confirm_delete_account)
	confirm_dialog.canceled.connect(_cancel_delete_account)
	
	confirm_dialog.popup_centered()

func _confirm_delete_account():
	"""Confirma a exclusão da conta"""
	show_status("Conta excluída com sucesso!", Color(0, 1, 0))
	
	# Aqui você implementaria a lógica real de exclusão da conta
	# Por enquanto, apenas faz logout
	global.clear_session()
	
	# Aguarda um pouco e volta para o menu principal
	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file("res://Assets/Scenes/MainMenuLogin.tscn")

func _cancel_delete_account():
	"""Cancela a exclusão da conta"""
	show_status("Exclusão cancelada.", Color(1, 1, 0))

func show_status(message: String, color: Color):
	"""Mostra uma mensagem de status"""
	status_label.text = message
	status_label.modulate = color
	status_label.show()
	
	# Esconde a mensagem após 3 segundos
	await get_tree().create_timer(3.0).timeout
	status_label.hide()

func _input(event):
	"""Detecta tecla Enter para salvar nome de usuário"""
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ENTER and username_input.has_focus():
			_on_save_username_pressed()
