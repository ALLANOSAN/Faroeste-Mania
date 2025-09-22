extends Control

@onready var placar_container = %VBoxContainer
@onready var loading_label = %LoadingLabel
@onready var voltar_button = %BotaoVoltar
@onready var global = get_node("/root/Global")

# Referências para as texturas de medalhas
@onready var medal_gold = preload("res://Assets/Art/medalhaouro.png")
@onready var medal_silver = preload("res://Assets/Art/medalhaprata.png")
@onready var medal_bronze = preload("res://Assets/Art/medalhabronze.png")
@onready var background_texture = preload("res://Assets/Art/Sem título-1.png")

func _ready():
	# Conecta botão de voltar
	voltar_button.pressed.connect(_on_voltar_pressed)
	
	# Conecta o sinal de scores_updated
	global.scores_updated.connect(_on_scores_updated)
	
	# Carrega as pontuações
	loading_label.text = "Carregando pontuações..."
	global.load_leaderboard()
	
	# Aplica configurações específicas para a plataforma atual
	_apply_platform_specific_settings()

func _on_voltar_pressed():
	get_tree().change_scene_to_file("res://Assets/Scenes/MainMenuLogin.tscn")

# Callback quando as pontuações forem atualizadas
func _on_scores_updated(scores):
	loading_label.hide()
	
	# Limpa o conteúdo atual, mas preserva os dois primeiros itens (cabeçalho e separador)
	var children = placar_container.get_children()
	for i in range(children.size()):
		if i > 1: # Pula o cabeçalho (0) e o separador (1)
			children[i].queue_free()
	
	# Se não tiver pontuações, mostra mensagem
	if scores.size() == 0:
		var label = Label.new()
		label.text = "Nenhuma pontuação encontrada"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		label.add_theme_font_size_override("font_size", 26)
		label.add_theme_color_override("font_color", Color(1, 0.8, 0.2)) # Amarelo dourado
		label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
		label.add_theme_constant_override("outline_size", 3)
		
		# Adiciona botão para tentar novamente se não há pontuações
		var retry_button = Button.new()
		retry_button.text = "Atualizar Pontuações"
		retry_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		retry_button.custom_minimum_size = Vector2(200, 50)
		retry_button.pressed.connect(func(): global.load_leaderboard())
		
		var vbox = VBoxContainer.new()
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_theme_constant_override("separation", 20)
		
		vbox.add_child(label)
		vbox.add_child(retry_button)
		placar_container.add_child(vbox)
		return
	
	# Ordenar as pontuações (do maior para o menor score)
	scores.sort_custom(func(a, b): return a.score > b.score)

	# Pegar apenas os 10 melhores jogadores (ou menos se houver menos jogadores)
	var top_scores = []
	var max_entries = min(scores.size(), 10)
	for i in range(max_entries):
		top_scores.append(scores[i])

	# Adiciona as linhas de pontuação para os top 10
	for i in range(top_scores.size()):
		add_score_row(i + 1, top_scores[i])

# Adiciona uma linha de pontuação
func add_score_row(pos_rank, score_data):
	var row = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Configura o espaçamento entre elementos
	row.add_theme_constant_override("separation", 10)
	
	# Posição (com medalha para os 3 primeiros)
	var pos_container = HBoxContainer.new()
	pos_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pos_container.size_flags_stretch_ratio = 0.8
	pos_container.alignment = BoxContainer.ALIGNMENT_CENTER # Centralizar o conteúdo
	
	if pos_rank <= 3:
		var medal_texture = TextureRect.new()
		medal_texture.texture = get_medal_texture(pos_rank)
		medal_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		medal_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		medal_texture.custom_minimum_size = Vector2(50, 50) # Aumentei um pouco o tamanho
		medal_texture.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		pos_container.add_child(medal_texture)
	else:
		# Para posições acima de 3, mostra o número da posição
		var pos_label = Label.new()
		pos_label.text = str(pos_rank) + "º"
		pos_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pos_label.add_theme_font_size_override("font_size", 22)
		pos_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2)) # Amarelo dourado
		pos_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
		pos_label.add_theme_constant_override("outline_size", 2)
		pos_container.add_child(pos_label)
	
	row.add_child(pos_container)
	
	# Nome do jogador
	var name_label = Label.new()
	name_label.text = score_data.name # Nome do jogador
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.size_flags_stretch_ratio = 2.5
	name_label.clip_text = true # Corta o texto se for muito longo
	name_label.add_theme_font_size_override("font_size", 22)
	name_label.add_theme_color_override("font_color", Color(1, 1, 1))
	name_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	name_label.add_theme_constant_override("outline_size", 2)
	
	# Destaca o jogador atual
	if score_data.user_id == global.get_current_user_id():
		name_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3)) # Verde para destacar o jogador atual
		
	row.add_child(name_label)
	
	# Pontuação
	var score_label = Label.new()
	score_label.text = str(score_data.score)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	score_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	score_label.size_flags_stretch_ratio = 1
	score_label.add_theme_font_size_override("font_size", 22)
	score_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2)) # Amarelo dourado
	score_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	score_label.add_theme_constant_override("outline_size", 2)
	row.add_child(score_label)
	
	# Adiciona um separador
	var separator = HSeparator.new()
	separator.theme_type_variation = "ThinHSeparator"
	
	# Adiciona a linha e o separador ao container principal
	placar_container.add_child(row)
	placar_container.add_child(separator)

# Retorna a textura da medalha baseada na posição
# 1º lugar: medalha de ouro
# 2º lugar: medalha de prata
# 3º lugar: medalha de bronze
func get_medal_texture(pos):
	match pos:
		1: return medal_gold
		2: return medal_silver
		3: return medal_bronze
		_: return null

# Função para ajustar a interface com base na plataforma
func _apply_platform_specific_settings():
	if global.Platform.is_mobile:
		# Em dispositivos móveis, podemos querer ajustar tamanhos de fonte, etc.
		pass
	else:
		# Em desktop, podemos ter outros ajustes
		pass
