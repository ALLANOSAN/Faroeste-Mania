extends Control

# =========================
# Variáveis
# =========================
var score: int = 0
var nome_digitado: String = ""

# =========================
# Nós da UI
# =========================
@onready var video_player = $VideoStreamPlayer
@onready var botao_tela_inicial = $botao_tela_inicial
@onready var botao_tentar_novamente = $botao_tentar_novamente
@onready var botao_classificacao = $botao_classificacao
@onready var pontuacao_label = $PontuacaoLabel

# Nós do formulário de nome (vamos criar via código)
var nome_container: VBoxContainer
var nome_input: LineEdit
var botao_salvar: Button
var label_instrucao: Label

func _ready():
	# Busca a pontuação armazenada
	score = GameData.get_pontuacao()
	
	print("🎮 Game Over carregado - Pontuação: %d" % score)
	
	# Garante que a música do mapa parou
	AudioManager.stop_music_map()
	
	# Esconde tudo inicialmente
	botao_tela_inicial.hide()
	botao_tentar_novamente.hide()
	botao_classificacao.hide()
	pontuacao_label.hide()

	# Conecta sinal de fim do vídeo
	video_player.finished.connect(_on_video_finished)
	
	# Roda o vídeo de Game Over
	video_player.stream = preload("res://Assets/Videos/Game-Over.ogv")
	video_player.play()


# Quando o vídeo termina, mostra o formulário de nome
func _on_video_finished():
	# Inicia música ambiente
	AudioManager.play_ambience()
	
	# Mostra a pontuação
	pontuacao_label.text = "Pontuação: %d" % score
	pontuacao_label.show()
	
	# Cria e mostra o formulário para digitar o nome
	criar_formulario_nome()


# Cria o formulário para o jogador digitar o nome
func criar_formulario_nome():
	# Container principal
	nome_container = VBoxContainer.new()
	nome_container.set_anchors_preset(Control.PRESET_CENTER)
	nome_container.position = Vector2(-200, 50)
	nome_container.custom_minimum_size = Vector2(400, 200)
	add_child(nome_container)
	
	# Label de instrução
	label_instrucao = Label.new()
	label_instrucao.text = "Digite seu nome:"
	label_instrucao.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_instrucao.add_theme_font_size_override("font_size", 40)
	label_instrucao.add_theme_color_override("font_color", Color.WHITE)
	nome_container.add_child(label_instrucao)
	
	# Espaçador
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	nome_container.add_child(spacer)
	
	# Campo de texto
	nome_input = LineEdit.new()
	nome_input.placeholder_text = "Seu nome aqui..."
	nome_input.max_length = 20
	nome_input.custom_minimum_size = Vector2(400, 60)
	nome_input.add_theme_font_size_override("font_size", 35)
	nome_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	nome_container.add_child(nome_input)
	
	# Espaçador
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 20)
	nome_container.add_child(spacer2)
	
	# Botão de salvar
	botao_salvar = Button.new()
	botao_salvar.text = "SALVAR"
	botao_salvar.custom_minimum_size = Vector2(400, 70)
	botao_salvar.add_theme_font_size_override("font_size", 40)
	botao_salvar.pressed.connect(_on_salvar_nome_pressed)
	nome_container.add_child(botao_salvar)
	
	# Foca no campo de texto
	nome_input.grab_focus()


# Quando o jogador clica em salvar
func _on_salvar_nome_pressed():
	nome_digitado = nome_input.text.strip_edges()
	
	# Valida o nome
	if nome_digitado.is_empty():
		nome_digitado = "Jogador"
	
	# Salva a pontuação localmente
	GameData.salvar_pontuacao(nome_digitado, score)
	
	# Remove o formulário
	nome_container.queue_free()
	
	# Mostra os botões
	mostrar_botoes()


# Mostra os botões após salvar o nome
func mostrar_botoes():
	botao_tela_inicial.show()
	botao_tentar_novamente.show()
	botao_classificacao.show()

	# Conecta sinais dos botões
	if not botao_tela_inicial.pressed.is_connected(_on_tela_inicial_pressed):
		botao_tela_inicial.pressed.connect(_on_tela_inicial_pressed)
	if not botao_tentar_novamente.pressed.is_connected(_on_tentar_novamente_pressed):
		botao_tentar_novamente.pressed.connect(_on_tentar_novamente_pressed)
	if not botao_classificacao.pressed.is_connected(_on_classificacao_pressed):
		botao_classificacao.pressed.connect(_on_classificacao_pressed)


# Botão que volta para o menu inicial
func _on_tela_inicial_pressed():
	get_tree().change_scene_to_file("res://Assets/Scenes/MainMenuLogin.tscn")


# Botão que reinicia a partida
func _on_tentar_novamente_pressed():
	get_tree().change_scene_to_file("res://Assets/Scenes/MapadoJogo.tscn")


# Botão que vai para leaderboard
func _on_classificacao_pressed():
	print("📋 Abrindo leaderboard local...")
	get_tree().change_scene_to_file("res://Assets/Scenes/Leaderboard.tscn")
