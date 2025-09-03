extends Control

# Variáveis para os botões e o texto
@onready var login_button = $Panel/BTLogin
@onready var options_menu_button = $Panel/BTOpcoes
@onready var blinking_text = $Panel/TextoAnimado

func _ready():
	# Esconde o texto e o botão de opções no início
	blinking_text.hide()
	options_menu_button.hide()
	
	# Conecta o botão de login para navegar para a próxima cena
	login_button.pressed.connect(_on_login_button_pressed)

func _on_login_button_pressed():
	print("Botão de Login pressionado!")
	# Código para mudar para a cena de login na pasta correta
	get_tree().change_scene_to_file("res://Assets/Scenes/login.tscn")
