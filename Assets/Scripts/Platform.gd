extends Node

# Tipos de plataforma que o jogo suporta
enum PlatformType {
	DESKTOP, # PC (Windows, Mac, Linux)
	MOBILE, # Dispositivos móveis (Android, iOS)
	WEB # Navegador Web
}

# A plataforma atual detectada
var current_platform: PlatformType = PlatformType.DESKTOP

# Variável para fácil verificação
var is_mobile: bool = false
var is_desktop: bool = false
var is_web: bool = false

func _ready():
	detect_platform()

# Detecta a plataforma atual e configura as variáveis
func detect_platform() -> void:
	var platform_name = OS.get_name().to_lower()
	
	# Mostra a plataforma atual no console para depuração
	print("Sistema Operacional detectado: " + platform_name)
	
	# Detecta o tipo de plataforma
	if platform_name in ["android", "ios"]:
		current_platform = PlatformType.MOBILE
		is_mobile = true
		print("Plataforma detectada: MOBILE")
	elif platform_name == "web":
		current_platform = PlatformType.WEB
		is_web = true
		print("Plataforma detectada: WEB")
	else: # windows, macos, linux, etc
		current_platform = PlatformType.DESKTOP
		is_desktop = true
		print("Plataforma detectada: DESKTOP")
	
	# Configura otimizações específicas para cada plataforma
	configure_platform_optimizations()

# Configura otimizações específicas para cada plataforma
func configure_platform_optimizations() -> void:
	match current_platform:
		PlatformType.MOBILE:
			# Otimizações para dispositivos móveis
			print("Aplicando otimizações para dispositivos móveis...")
			# Exemplo: Reduzir qualidade de texturas, desativar efeitos pesados
			# Baixa prioridade para eventos de mouse já que estamos no mobile
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			
		PlatformType.DESKTOP:
			# Otimizações para desktop
			print("Aplicando otimizações para desktop...")
			# Exemplo: Habilitar recursos visuais adicionais
			# Alta prioridade para eventos de mouse
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			
		PlatformType.WEB:
			# Otimizações para web
			print("Aplicando otimizações para web...")
			# Exemplo: Otimizações específicas para navegadores
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

# Verifica se o dispositivo suporta toque
func has_touchscreen() -> bool:
	return DisplayServer.is_touchscreen_available()

# Retorna o tipo de input recomendado para a plataforma atual
func get_recommended_input_type() -> String:
	if is_mobile or (has_touchscreen() and is_web):
		return "touch"
	else:
		return "mouse"

# Verifica se um evento é um clique válido (mouse ou toque) com base na plataforma
func is_valid_click(event) -> bool:
	if is_mobile:
		# Em dispositivos móveis, prioriza eventos de toque
		return event is InputEventScreenTouch and event.pressed
	else:
		# Em desktop, aceita tanto mouse quanto toque (se disponível)
		return (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed) or \
		       (event is InputEventScreenTouch and event.pressed)
