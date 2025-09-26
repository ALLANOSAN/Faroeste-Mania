extends Control

@onready var placar_container = %VBoxContainer
@onready var loading_label = %LoadingLabel
@onready var voltar_button = %BotaoVoltar
@onready var global = get_node("/root/Global")

@onready var medal_gold = preload("res://Assets/Art/medalhaouro.png")
@onready var medal_silver = preload("res://Assets/Art/medalhaprata.png")
@onready var medal_bronze = preload("res://Assets/Art/medalhabronze.png")

func _ready() -> void:
	voltar_button.pressed.connect(_on_voltar)
	global.scores_updated.connect(_on_scores)
	loading_label.text = "Carregando…"
	global.load_leaderboard()

func _on_voltar() -> void:
	get_tree().change_scene_to_file("res://Assets/Scenes/MainMenuLogin.tscn")

func _on_scores(scores: Array) -> void:
	loading_label.hide()
	# Limpa linhas antigas
	for i in range(placar_container.get_child_count() - 1, 1, -1):
		placar_container.get_child(i).queue_free()

	if scores.size() == 0:
		var lbl = Label.new()
		lbl.text = "Nenhuma pontuação"
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		placar_container.add_child(lbl)
		return

	for i in range(scores.size()):
		var data = scores[i]
		_add_row(i + 1, data)

func _add_row(pos: int, data: Dictionary) -> void:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	if pos <= 3:
		var tex: Texture
		if pos == 1:
			tex = medal_gold
		elif pos == 2:
			tex = medal_silver
		else:
			tex = medal_bronze

		var icon = TextureRect.new()
		icon.texture = tex
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		icon.custom_minimum_size = Vector2(40, 40)
		row.add_child(icon)
	else:
		var pos_lbl = Label.new()
		pos_lbl.text = "%dº" % pos
		row.add_child(pos_lbl)

	var name_lbl = Label.new()
	name_lbl.text = data["name"]
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if data["user_id"] == global.get_current_user_id():
		name_lbl.add_theme_color_override("font_color", Color(0.3, 1, 0.3))
	row.add_child(name_lbl)

	var score_lbl = Label.new()
	score_lbl.text = str(data["score"])
	score_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(score_lbl)

	placar_container.add_child(row)
	placar_container.add_child(HSeparator.new())
