extends Control

@onready var auth_manager = get_node("/root/AuthManager")
@onready var placar_container = %VBoxContainer
@onready var loading_label = %LoadingLabel
@onready var voltar_button = %BotaoVoltar

# Referências para as texturas de medalhas
@onready var medal_gold = preload("res://Assets/Art/medalhaouro.png")
@onready var medal_silver = preload("res://Assets/Art/medalhaprata.png")
@onready var medal_bronze = preload("res://Assets/Art/medalhabronze.png")
@onready var background_texture = preload("res://Assets/Art/Sem título-1.png")

func _ready():
	# Conecta ao sinal de pontuações atualizadas
	auth_manager.scores_updated.connect(_on_scores_updated)
	
	# Conecta botão de voltar
	voltar_button.pressed.connect(_on_voltar_pressed)
	
	# Carrega as pontuações
	loading_label.text = "Carregando pontuações..."
	auth_manager.load_scores()

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
		placar_container.add_child(label)
		return
	
	# Garantir que temos apenas as 10 melhores pontuações
	var top_scores = []
	for i in range(min(scores.size(), 10)):
		top_scores.append(scores[i])
	
	# Adiciona as linhas de pontuação
	for i in range(top_scores.size()): 
		add_score_row(i + 1, top_scores[i])

# O método add_header_row foi removido pois o cabeçalho agora é parte permanente da cena

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
		
		# Escolhe a medalha correta
		match pos_rank:
			1: medal_texture.texture = medal_gold
			2: medal_texture.texture = medal_silver
			3: medal_texture.texture = medal_bronze
		
		medal_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		medal_texture.custom_minimum_size = Vector2(32, 32)
		medal_texture.expand = true
		pos_container.add_child(medal_texture)
	else:
		var pos_label = Label.new()
		pos_label.text = str(pos_rank)
		pos_label.add_theme_font_size_override("font_size", 22)
		pos_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pos_label.add_theme_color_override("font_color", Color(1, 1, 1))
		pos_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
		pos_label.add_theme_constant_override("outline_size", 2)
		pos_container.add_child(pos_label)
	
	# Nome do jogador
	var name_label = Label.new()
	name_label.text = score_data.get("name", "???")
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.size_flags_stretch_ratio = 2.0
	name_label.clip_text = true
	name_label.add_theme_font_size_override("font_size", 22)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_color_override("font_color", Color(1, 1, 1))
	name_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	name_label.add_theme_constant_override("outline_size", 2)
	
	# Pontuação
	var score_label = Label.new()
	score_label.text = str(score_data.get("score", 0))
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	score_label.add_theme_font_size_override("font_size", 22)
	score_label.add_theme_color_override("font_color", Color(1, 1, 1))
	score_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	score_label.add_theme_constant_override("outline_size", 2)
	
	row.add_child(pos_container)
	row.add_child(name_label)
	row.add_child(score_label)
	
	placar_container.add_child(row)
	
	# Adiciona um pequeno espaço entre linhas
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	placar_container.add_child(spacer)
