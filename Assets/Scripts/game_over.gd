extends Control

# =========================
# Variáveis
# =========================
var score: int = 0 # Pontuação recebida do jogo

# =========================
# Nós da UI
# =========================
@onready var video_player = $VideoStreamPlayer
@onready var botao_tela_inicial = $Botao_Tela_Inicial
@onready var botao_tentar_novamente = $Botao_Tentar_Novamente
@onready var botao_classificacao = $Botao_Classificacao
@onready var nomes_label = $NomesLabel

func _ready():
	# Inicialmente esconde os botões e label
	botao_tela_inicial.hide()
	botao_tentar_novamente.hide()
	botao_classificacao.hide()
	nomes_label.hide()

	# Conecta sinal de fim do vídeo
	video_player.finished.connect(_on_video_finished)
	
	# Roda o vídeo de Game Over
	video_player.stream = preload("res://Assets/Videos/Game-Over.ogv")
	video_player.play()

# Quando o vídeo termina, mostra os botões e o label
func _on_video_finished():
	botao_tela_inicial.show()
	botao_tentar_novamente.show()
	botao_classificacao.show()
	nomes_label.show()

	# Conecta sinais dos botões
	botao_tela_inicial.pressed.connect(_on_tela_inicial_pressed)
	botao_tentar_novamente.pressed.connect(_on_tentar_novamente_pressed)
	botao_classificacao.pressed.connect(_on_classificacao_pressed)

	# Aqui já pode salvar a pontuação no Firestore
	save_score_to_firestore()

# =========================
# Define a pontuação que veio da cena do jogo
# =========================
func set_score(value: int):
	score = value

# =========================
# Salva a pontuação no Firestore
# =========================
func save_score_to_firestore():
	if Firebase.Auth.check_auth_file():
		Firebase.Auth.load_auth()
		var user_id = Firebase.Auth.get_current_user_uid()
		var display_name = Firebase.Auth.get_current_user_display_name()
		
		var scores_collection = Firebase.Firestore.collection("scores")
		var score_data = {
			"display_name": display_name,
			"score": score,
			"timestamp": Time.get_unix_time_from_system()
		}
		
		await scores_collection.add(user_id, score_data)
		print("Pontuação salva com sucesso! -> %s" % score)
	else:
		print("Usuário não autenticado. Pontuação não salva.")

# Botão que volta para o menu inicial
func _on_tela_inicial_pressed():
	get_tree().change_scene_to_file("res://Assets/Scenes/MainMenuLogin.tscn")

# Botão que reinicia a partida
func _on_tentar_novamente_pressed():
	get_tree().change_scene_to_file("res://Assets/Scenes/MapadoJogo.tscn")

# Botão que vai para leaderboard
func _on_classificacao_pressed():
	get_tree().change_scene_to_file("res://Assets/Scenes/Leaderboard.tscn")
