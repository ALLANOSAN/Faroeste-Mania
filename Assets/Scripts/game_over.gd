extends Control

# =========================
# Variáveis
# =========================
var score: int = 0 # Pontuação do jogo
var user_id: String = ""
var user_name: String = ""

# =========================
# Nós da UI
# =========================
@onready var video_player = $VideoStreamPlayer
@onready var botao_tela_inicial = $botao_tela_inicial
@onready var botao_tentar_novamente = $botao_tentar_novamente
@onready var botao_classificacao = $botao_classificacao
@onready var pontuacao_label = $PontuacaoLabel

func _ready():
	# Busca os dados do jogo que foram armazenados
	score = GameData.get_pontuacao()
	user_id = GameData.get_user_id()
	user_name = GameData.get_user_name()
	
	print("🎮 Game Over carregado - Pontuação: %d, Usuário: %s" % [score, user_name])
	
	# Inicialmente esconde os botões e label de pontuação
	botao_tela_inicial.hide()
	botao_tentar_novamente.hide()
	botao_classificacao.hide()
	pontuacao_label.hide()

	# Conecta sinal de fim do vídeo
	video_player.finished.connect(_on_video_finished)
	
	# Roda o vídeo de Game Over
	video_player.stream = preload("res://Assets/Videos/Game-Over.ogv")
	video_player.play()

# Quando o vídeo termina, mostra os botões e a pontuação
func _on_video_finished():
	# Atualiza o texto da pontuação
	pontuacao_label.text = "Pontuação: %d" % score
	
	# Mostra todos os elementos
	pontuacao_label.show()
	botao_tela_inicial.show()
	botao_tentar_novamente.show()
	botao_classificacao.show()

	# Conecta sinais dos botões
	botao_tela_inicial.pressed.connect(_on_tela_inicial_pressed)
	botao_tentar_novamente.pressed.connect(_on_tentar_novamente_pressed)
	botao_classificacao.pressed.connect(_on_classificacao_pressed)

# Botão que volta para o menu inicial
func _on_tela_inicial_pressed():
	get_tree().change_scene_to_file("res://Assets/Scenes/MainMenuLogin.tscn")

# Botão que reinicia a partida
func _on_tentar_novamente_pressed():
	get_tree().change_scene_to_file("res://Assets/Scenes/MapadoJogo.tscn")

# Botão que vai para leaderboard
func _on_classificacao_pressed():
	get_tree().change_scene_to_file("res://Assets/Scenes/Leaderboard.tscn")
