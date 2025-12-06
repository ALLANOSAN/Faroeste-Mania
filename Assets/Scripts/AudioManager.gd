extends Node

# Sinais para notificar mudanças
signal volume_changed(value)
signal mute_changed(is_muted)

# Nodes de áudio
var music_player: AudioStreamPlayer
var ambience_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer

# Recursos de áudio
# Usamos preload para garantir que o Godot inclua os arquivos na exportação
var ambience_stream = preload("res://Assets/Audio/Ambiente.mp3")
var music_stream = preload("res://Assets/Audio/Duelo.mp3")
var sfx_stream = preload("res://Assets/Audio/tiro.mp3")

# Estado atual
var current_volume: float = 100.0
var is_muted: bool = false

func _ready():
	# Configurar players
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Master"
	# Configura loop para a música
	music_player.finished.connect(func(): music_player.play())
	add_child(music_player)
	
	ambience_player = AudioStreamPlayer.new()
	ambience_player.bus = "Master"
	# Configura loop para o som ambiente
	ambience_player.finished.connect(func(): ambience_player.play())
	add_child(ambience_player)
	
	sfx_player = AudioStreamPlayer.new()
	sfx_player.bus = "Master"
	add_child(sfx_player)
	
	# Configurar volume inicial
	update_volume()

# --- Controle de Reprodução ---

func play_ambience():
	# Para a música do mapa se estiver tocando
	stop_music_map()
	
	if ambience_stream:
		if not ambience_player.playing:
			ambience_player.stream = ambience_stream
			ambience_player.play()

func stop_ambience():
	ambience_player.stop()

func play_music_map():
	# Para o ambiente
	stop_ambience()
	
	if music_stream:
		if not music_player.playing:
			music_player.stream = music_stream
			music_player.play()

func stop_music_map():
	music_player.stop()

func play_sfx_shoot():
	if sfx_stream:
		sfx_player.stream = sfx_stream
		sfx_player.play()

# --- Controle de Volume e Mute ---

func set_volume(value: float):
	current_volume = clamp(value, 0, 100)
	update_volume()
	volume_changed.emit(current_volume)

func toggle_mute(mute: bool):
	is_muted = mute
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), is_muted)
	mute_changed.emit(is_muted)

func update_volume():
	# Converte 0-100 para dB (escala logarítmica aproximada ou linear mapeada)
	# AudioServer usa dB. 0dB é volume normal. -80dB é silêncio.
	var db_volume = linear_to_db(current_volume / 100.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db_volume)

# Função auxiliar para converter linear (0-1) para dB
func linear_to_db(linear):
	if linear == 0:
		return -80.0
	return 20.0 * log(linear) / log(10.0)
