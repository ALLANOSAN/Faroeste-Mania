extends Control

# Nós da cena
@onready var vbox_scores = %VBoxContainer
@onready var loading_label = %LoadingLabel
@onready var botao_voltar = %BotaoVoltar
@onready var botao_reiniciar = %BotaoReiniciar

# Medalhas
var medal_gold = preload("res://Assets/Art/medalhaouro.png")
var medal_silver = preload("res://Assets/Art/medalhaprata.png")
var medal_bronze = preload("res://Assets/Art/medalhabronze.png")

func _ready():
	# Inicia música ambiente
	AudioManager.play_ambience()

	# Conecta os botões
	botao_reiniciar.pressed.connect(_on_botao_reiniciar_pressed)
	botao_voltar.pressed.connect(_on_botao_voltar_pressed)

	# Carrega os scores locais
	carregar_scores()


# Função para carregar os scores do arquivo local
func carregar_scores() -> void:
	loading_label.text = "Carregando pontuações..."
	loading_label.show()

	# Limpa linhas anteriores (mantém apenas o cabeçalho e separador)
	limpar_linhas()

	print("🏆 Carregando ranking local...")

	# Pega o ranking do GameData
	var scores = GameData.get_ranking()
	
	if scores.is_empty():
		loading_label.text = "Nenhuma pontuação ainda!\nJogue para aparecer no ranking."
		return
	
	# Esconde o loading
	loading_label.hide()
	
	# Exibe as pontuações
	exibir_scores(scores)


# Função para exibir os scores na tela
func exibir_scores(scores: Array) -> void:
	var posicao = 1
	
	for score_data in scores:
		var nome = score_data.get("nome", "Jogador")
		var pontos = score_data.get("pontos", 0)
		
		# Cria linha do ranking
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 20)
		
		# Medalha ou posição
		var medal_rect = TextureRect.new()
		medal_rect.custom_minimum_size = Vector2(50, 50)
		medal_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		medal_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		
		match posicao:
			1:
				medal_rect.texture = medal_gold
			2:
				medal_rect.texture = medal_silver
			3:
				medal_rect.texture = medal_bronze
			_:
				# Para posições sem medalha, mostra o número
				var pos_label = Label.new()
				pos_label.text = str(posicao) + "º"
				pos_label.custom_minimum_size = Vector2(50, 50)
				pos_label.add_theme_font_size_override("font_size", 30)
				pos_label.add_theme_color_override("font_color", Color.WHITE)
				pos_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				pos_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				hbox.add_child(pos_label)
				medal_rect.queue_free()
				medal_rect = null
		
		if medal_rect:
			hbox.add_child(medal_rect)
		
		# Nome do jogador
		var nome_label = Label.new()
		nome_label.text = nome
		nome_label.custom_minimum_size = Vector2(400, 50)
		nome_label.add_theme_font_size_override("font_size", 35)
		nome_label.add_theme_color_override("font_color", Color.WHITE)
		nome_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hbox.add_child(nome_label)
		
		# Pontuação
		var pontos_label = Label.new()
		pontos_label.text = str(pontos)
		pontos_label.custom_minimum_size = Vector2(150, 50)
		pontos_label.add_theme_font_size_override("font_size", 35)
		pontos_label.add_theme_color_override("font_color", Color.YELLOW)
		pontos_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		pontos_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hbox.add_child(pontos_label)
		
		vbox_scores.add_child(hbox)
		posicao += 1


# Remove todas as linhas de score (mantém cabeçalho)
func limpar_linhas() -> void:
	# Remove todos os filhos exceto os dois primeiros (cabeçalho e separador)
	var children = vbox_scores.get_children()
	for i in range(2, children.size()):
		children[i].queue_free()


# Botão recarregar ranking
func _on_botao_reiniciar_pressed():
	print("🔄 Recarregando ranking...")
	carregar_scores()


# Botão voltar
func _on_botao_voltar_pressed():
	get_tree().change_scene_to_file("res://Assets/Scenes/MainMenuLogin.tscn")
