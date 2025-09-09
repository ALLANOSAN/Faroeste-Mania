extends CheckBox

# Referência aos frames da animação
var frames_check = [] # Frames 1-11 para marcar
var frames_uncheck = [] # Frames 12-20 para desmarcar
var current_frame = 0
var is_animating = false
var animation_timer = 0.0
var frame_duration = 0.05 # 50ms por frame, 20fps

func _ready():
	# Carregar os frames 1-11 (para marcar)
	for i in range(1, 12):
		var num = str(i).pad_zeros(2)
		var path = "res://Assets/Art/icons8-caixa-de-selecção-seleccionada-2/frame-" + num + ".png"
		frames_check.append(load(path))
	
	# Carregar os frames 12-20 (para desmarcar)
	for i in range(12, 21):
		var num = str(i).pad_zeros(2)
		var path = "res://Assets/Art/icons8-caixa-de-selecção-seleccionada-2/frame-" + num + ".png"
		frames_uncheck.append(load(path))
	
	# Conectar o sinal toggled ao método que manipula a animação
	toggled.connect(_on_checkbox_toggled)
	
	# Definir o ícone inicial
	add_theme_icon_override("unchecked", frames_check[0])

var is_unchecking = false # Flag para indicar se estamos marcando ou desmarcando

func _process(delta):
	if is_animating:
		animation_timer += delta
		
		if animation_timer >= frame_duration:
			animation_timer = 0
			current_frame += 1
			
			if is_unchecking:
				# Usando frames_uncheck para desmarcar
				if current_frame >= frames_uncheck.size():
					current_frame = frames_uncheck.size() - 1
					is_animating = false
				
				# Atualizar o ícone com o frame atual de desmarcação
				add_theme_icon_override("unchecked", frames_uncheck[current_frame])
				add_theme_icon_override("checked", frames_uncheck[current_frame])
			else:
				# Usando frames_check para marcar
				if current_frame >= frames_check.size():
					current_frame = frames_check.size() - 1
					is_animating = false
				
				# Atualizar o ícone com o frame atual de marcação
				add_theme_icon_override("unchecked", frames_check[current_frame])
				add_theme_icon_override("checked", frames_check[current_frame])

# Função para iniciar a animação de desmarcação (frames 12-20)
func play_uncheck_animation():
	current_frame = 0
	is_animating = true
	is_unchecking = true
	animation_timer = 0.0

func _on_checkbox_toggled(_checked):
	if _checked:
		# Iniciar animação do frame 1 ao 11 (checkbox marcando)
		current_frame = 0
		is_animating = true
		is_unchecking = false # Animação de marcação
		animation_timer = 0.0
	else:
		# Iniciar animação de desmarcação com os frames 12 ao 20
		play_uncheck_animation()
