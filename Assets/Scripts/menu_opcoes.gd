extends Control

@onready var botao_voltar = %BTVoltarMainMenu
@onready var botao_som = %BTChamarMenuSom
@onready var botao_leaderboard = %BTChamarMenuLeadboard

func _ready():
	# Conectar os sinais dos botões
	botao_voltar.pressed.connect(_on_botao_voltar_pressed)
	botao_som.pressed.connect(_on_botao_som_pressed)
	botao_leaderboard.pressed.connect(_on_botao_leaderboard_pressed)

func _on_botao_voltar_pressed():
	get_tree().change_scene_to_file("res://Assets/Scenes/MainMenuLogin.tscn")

func _on_botao_som_pressed():
	get_tree().change_scene_to_file("res://Assets/Scenes/MenuSOM.tscn")
	
func _on_botao_leaderboard_pressed():
	get_tree().change_scene_to_file("res://Assets/Scenes/Leaderboard.tscn")
