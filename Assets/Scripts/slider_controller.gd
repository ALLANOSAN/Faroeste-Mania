extends HSlider

# Referências às texturas
var circle_texture: Texture2D

func _ready():
	# Obter a textura do círculo
	circle_texture = load("res://Assets/Art/Circulo Botão.png")
	
	# Aplicar a textura como ícone do grabber
	add_theme_icon_override("grabber", circle_texture)
	add_theme_icon_override("grabber_highlight", circle_texture)
	add_theme_icon_override("grabber_disabled", circle_texture)
	
	# Conectar sinal de mudança de valor
	value_changed.connect(_on_value_changed)
	
	# Configurar o slider
	min_value = 0
	max_value = 100
	step = 1
	
	# Melhorar a interação
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	# Ajustar o grabber offset para alinhar com a barra
	set("theme_override_constants/grabber_offset", 0)
	set("theme_override_constants/center_grabber", 1)
	
	# Chamada inicial para configurar visual
	_on_value_changed(value)

# Quando o valor muda, garantimos que o slider permaneça com aparência consistente
func _on_value_changed(_new_value):
	# A lógica para manter o slider visualmente correto é gerenciada pelo Godot
	# Não precisamos fazer nada especial aqui, já que a área do grabber
	# é estilizada diretamente na cena
	pass

# Mantemos a interface simples e deixamos o Godot gerenciar o restante
func _process(_delta):
	# Isso força o Godot a sempre usar a textura do círculo
	if not has_theme_icon_override("grabber"):
		add_theme_icon_override("grabber", circle_texture)
		add_theme_icon_override("grabber_highlight", circle_texture)
