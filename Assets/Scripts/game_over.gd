extends Control

@onready var video_player       = %VideoStreamPlayer
@onready var button_menu        = %botao_tela_inicial
@onready var button_retry       = %botao_tentar_novamente
@onready var button_leaderboard = %botao_classificacao
@onready var pontuacao_label    = %PontuacaoLabel
@onready var global             = get_node("/root/Global")

var pontuacao_final = 0

func _ready() -> void:
	button_menu.hide()
	button_retry.hide()
	button_leaderboard.hide()
	pontuacao_label.hide()
	video_player.finished.connect(_on_video_finished)
	carregar_pontuacao_atual()

func _on_video_finished() -> void:
	# Atualiza high_score se ultrapassou o recorde
	if global.is_user_logged_in() and pontuacao_final > global.get_player_high_score():
		global.update_player_high_score(pontuacao_final)
	_mostrar_interface_pos_video()

func _mostrar_interface_pos_video() -> void:
	button_menu.show()
	button_retry.show()
	button_leaderboard.show()
	pontuacao_label.show()

func _on_button_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://Assets/Scenes/MainMenuLogin.tscn")

func _on_button_retry_pressed() -> void:
	get_tree().change_scene_to_file("res://Assets/Scenes/MapadoJogo.tscn")

func _on_button_leaderboard_pressed() -> void:
	global.load_leaderboard()
	get_tree().change_scene_to_file("res://Assets/Scenes/Leaderboard.tscn")

func carregar_pontuacao_atual() -> void:
	var path = "user://temp_game_data.save"
	if not FileAccess.file_exists(path):
		print("Arquivo de dados do jogo não encontrado")
		return

	var file = FileAccess.open(path, FileAccess.READ)
	var text = file.get_as_text()
	file.close()

	# Cria instância de JSON e faz o parse
	var json = JSON.new()
	var err = json.parse(text)
	if err != OK:
		print("Erro ao analisar JSON:", json.error_string)
		return

	# Recupera o dicionário resultante
	var data = json.get_data()
	pontuacao_final = int(data.get("pontuacao", 0))
	pontuacao_label.text = "Pontuação: %d" % pontuacao_final
