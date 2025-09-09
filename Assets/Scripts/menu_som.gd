extends Control

# Referência ao botão de voltar
@onready var botao_voltar = %BotaoVoltar

func _ready():
	# Conecta o botão de voltar ao método correspondente
	botao_voltar.pressed.connect(_on_botao_voltar_pressed)

# Função para voltar ao menu de opções
func _on_botao_voltar_pressed():
	# Navega de volta para o menu de opções
	get_tree().change_scene_to_file("res://Assets/Scenes/MenuOpções.tscn")
