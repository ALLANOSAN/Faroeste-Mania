extends Control

# Nós da cena
@onready var vbox_scores = $VBoxContainer
@onready var loading_label = $LoadingLabel
@onready var botao_voltar = $BotaoVoltar
@onready var botao_reiniciar = $BotaoReiniciar

# Nó modelo de linha (HBoxContainer)
@onready var linha_modelo = $HBoxContainerModel
@onready var posicao_label_modelo = linha_modelo.get_node("PosicaoLabel")
@onready var nome_label_modelo = linha_modelo.get_node("NomeLabel")
@onready var pontuacao_label_modelo = linha_modelo.get_node("PontuacaoLabel")
@onready var posicao_sprite_modelo = linha_modelo.get_node("PosicaoSprite") # Sprite para medalha

# Medalhas
@onready var medal_gold = preload("res://Assets/Art/medalhaouro.png")
@onready var medal_silver = preload("res://Assets/Art/medalhaprata.png")
@onready var medal_bronze = preload("res://Assets/Art/medalhabronze.png")

func _ready():
	linha_modelo.visible = false # Esconde o modelo
	botao_reiniciar.connect("pressed", Callable(self, "_on_botao_reiniciar_pressed"))
	botao_voltar.connect("pressed", Callable(self, "_on_botao_voltar_pressed"))

	carregar_scores()

# Função para carregar os scores do Firestore
func carregar_scores() -> void:
	loading_label.text = "Carregando pontuações..."
	vbox_scores.clear() # limpa as linhas anteriores

	# Cria a query Firestore
	var query: FirestoreQuery = FirestoreQuery.new()
	query.from("scores")
	query.order_by("pontuacao", FirestoreQuery.DIRECTION.DESCENDING)
	query.limit(10)

	# Await para buscar os resultados
	var results: Array = await Firebase.Firestore.query(query)

	# Verifica se retornou algo válido
	if typeof(results) != TYPE_ARRAY:
		loading_label.text = "Erro ao carregar pontuações"
		print("Erro Firestore: resultado inválido")
		return

	if results.is_empty():
		loading_label.text = "Nenhuma pontuação encontrada"
		return

	# Limpa o LoadingLabel para exibir as linhas
	loading_label.text = ""

	# Cria as linhas da leaderboard
	for i in range(results.size()):
		criar_linha(i, results[i])

# Cria uma linha da leaderboard
func criar_linha(index: int, score: Dictionary) -> void:
	var linha = linha_modelo.duplicate()
	linha.visible = true

	var pos_label = linha.get_node("PosicaoLabel")
	var nome_label = linha.get_node("NomeLabel")
	var pont_label = linha.get_node("PontuacaoLabel")
	var pos_sprite = linha.get_node("PosicaoSprite")

	# Define medalhas ou posição numérica
	match index:
		0:
			pos_sprite.texture = medal_gold
			pos_sprite.visible = true
			pos_label.visible = false
		1:
			pos_sprite.texture = medal_silver
			pos_sprite.visible = true
			pos_label.visible = false
		2:
			pos_sprite.texture = medal_bronze
			pos_sprite.visible = true
			pos_label.visible = false
		_:
			pos_label.text = str(index + 1)
			pos_label.visible = true
			pos_sprite.visible = false

	# Preenche nome e pontuação
	nome_label.text = score.get("nome", "Anon")
	pont_label.text = str(score.get("pontuacao", 0))

	# Adiciona à VBox
	vbox_scores.add_child(linha)

# Botão de recarregar rankings
func _on_botao_reiniciar_pressed():
	carregar_scores() # Recarrega o rank atualizado

# Botão de voltar
func _on_botao_voltar_pressed():
	get_tree().change_scene("res://Scenes/MenuOpções.tscn")
