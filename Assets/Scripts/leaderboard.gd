extends Control

@onready var pontuacoes_container = $ScrollContainer/VBoxContainer
@onready var http_request = $HTTPRequest
@onready var voltar_button = $BotaoVoltar

# Template para item de pontuação
const PONTUACAO_ITEM = """
[center]%s - %s pontos (%s)[/center]
"""

func _ready():
	# Conecta botão de voltar
	voltar_button.pressed.connect(_on_voltar_pressed)
	
	# Carrega pontuações do Firebase
	carregar_pontuacoes()

func _on_voltar_pressed():
	get_tree().change_scene_to_file("res://Assets/Scenes/MenuOpções.tscn")

func carregar_pontuacoes():
	# URL do Firebase Realtime Database
	# URL específica do seu banco de dados Firebase
	var firebase_db_url = "https://seu-projeto-default-rtdb.firebaseio.com" # Substitua esta URL pela mesma que você usou no mapa_jogo.gd
	var endpoint = "/pontuacoes.json"
	
	# Faz a requisição para buscar todas as pontuações
	http_request.request_completed.connect(_on_pontuacoes_carregadas)
	http_request.request(firebase_db_url + endpoint, [], HTTPClient.METHOD_GET)

func _on_pontuacoes_carregadas(result, response_code, _headers, body):
	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
		var json = JSON.new()
		var parse_result = json.parse(body.get_string_from_utf8())
		
		if parse_result == OK:
			var pontuacoes_data = json.data
			exibir_pontuacoes(pontuacoes_data)
		else:
			print("Erro ao analisar dados JSON")
	else:
		print("Erro ao carregar pontuações. Código:", response_code)

func exibir_pontuacoes(pontuacoes_data):
	# Limpa os itens existentes
	for child in pontuacoes_container.get_children():
		child.queue_free()
		
	# Se não houver pontuações
	if pontuacoes_data == null:
		var label = RichTextLabel.new()
		label.bbcode_enabled = true
		label.fit_content = true
		label.text = "[center]Nenhuma pontuação registrada ainda![/center]"
		pontuacoes_container.add_child(label)
		return
		
	# Cria uma lista para organizar as pontuações
	var lista_pontuacoes = []
	
	# Processa os dados
	for user_id in pontuacoes_data.keys():
		var pontuacao_info = pontuacoes_data[user_id]
		lista_pontuacoes.append({
			"user_id": user_id.substr(0, 8) + "...", # Trunca o ID para exibição
			"pontuacao": pontuacao_info.pontuacao,
			"data": pontuacao_info.data
		})
	
	# Ordena por pontuação (maior primeiro)
	lista_pontuacoes.sort_custom(func(a, b): return a.pontuacao > b.pontuacao)
	
	# Adiciona as pontuações ordenadas à UI
	var posicao = 1
	for info in lista_pontuacoes:
		var label = RichTextLabel.new()
		label.bbcode_enabled = true
		label.fit_content = true
		
		# Formata o texto com posição, ID truncado, pontuação e data
		var texto = PONTUACAO_ITEM % [
			"%d. %s" % [posicao, info.user_id],
			info.pontuacao,
			info.data
		]
		
		label.text = texto
		pontuacoes_container.add_child(label)
		posicao += 1
