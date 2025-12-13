extends Control

# Nós da UI
@onready var options_menu_button = %MenuPrincipalBTOpcoes
@onready var blinking_text = %TextoAnimado
@onready var animation_player = %AnimacaoTexto
@onready var background = %MenuPrincipalFundo

func _ready():
	print("🔄 MainMenu._ready() iniciado")
	
	# Inicia música ambiente
	AudioManager.play_ambience()
	
	# Mostra os elementos da UI
	if options_menu_button != null:
		options_menu_button.show()
		if not options_menu_button.pressed.is_connected(_on_options_menu_button_pressed):
			options_menu_button.pressed.connect(_on_options_menu_button_pressed)
	
	if blinking_text != null:
		blinking_text.show()
		if animation_player != null:
			animation_player.play("TextoAnimado")
	
	# Conecta detecção de toque no background para entrar no jogo
	if background != null and not background.gui_input.is_connected(_on_background_gui_input):
		background.gui_input.connect(_on_background_gui_input)


# Callback de toque no background - entra no jogo
func _on_background_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		print("🎮 Entrando no jogo...")
		get_tree().change_scene_to_file("res://Assets/Scenes/MapadoJogo.tscn")


func _on_options_menu_button_pressed() -> void:
	print("⚙️ Abrindo menu de opções...")
	get_tree().change_scene_to_file("res://Assets/Scenes/MenuOpções.tscn")
