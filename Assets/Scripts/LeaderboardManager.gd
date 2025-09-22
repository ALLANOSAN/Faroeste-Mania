extends Node

signal leaderboard_updated(scores_data)

# Referência ao listener para poder interrompê-lo quando necessário
var _leaderboard_listener_connection = null
var _top_player_doc = null

func _ready():
	# Inicializa o listener do leaderboard
	if Firebase and Firebase.Firestore:
		_setup_top_player_listener()
		
func _exit_tree():
	# Certifica-se de parar o listener quando o nó é destruído
	_stop_listeners()

# Inicia a escuta do documento do jogador com a maior pontuação
# Isso é útil para notificar quando há um novo campeão
func _setup_top_player_listener():
	# Primeiro, busca o jogador de maior pontuação
	var query = FirestoreQuery.new()
	query.from("users")
	query.order_by("score", FirestoreQuery.DIRECTION.DESCENDING)
	query.limit(1)
	
	Firebase.Firestore.query(query).then(func(results):
		if results.size() > 0:
			# Começa a escutar mudanças no documento do jogador de maior pontuação
			_top_player_doc = results[0]
			_leaderboard_listener_connection = _top_player_doc.on_snapshot(
				func(changes):
					print("Atualização detectada no topo do leaderboard!")
					# Verifica se houve mudanças válidas
					if changes and changes.size() > 0:
						print("Mudanças detectadas: " + str(changes.size()) + " modificações")
					load_full_leaderboard(),
				120.0 # Verifica a cada 2 minutos (tempo mínimo)
			)
	).catch(func(error):
		print("Erro ao configurar listener do leaderboard: " + str(error))
	)

# Carrega o leaderboard completo do Firestore
func load_full_leaderboard():
	var query = FirestoreQuery.new()
	query.from("users")
	query.select(["display_name", "score"])
	query.order_by("score", FirestoreQuery.DIRECTION.DESCENDING)
	query.limit(100)
	
	Firebase.Firestore.query(query).then(func(query_results):
		if query_results:
			var results = []
			# Processa cada documento nos resultados
			for doc in query_results:
				var leaderboard_entry = {
					"user_id": doc.doc_name,
					"name": doc.get_value("display_name") if doc.has_field("display_name") else "Jogador Anônimo",
					"score": doc.get_value("score") if doc.has_field("score") else 0
				}
				results.append(leaderboard_entry)
			
			# Emite o sinal com os resultados
			leaderboard_updated.emit(results)
			print("Leaderboard carregado com sucesso: " + str(results.size()) + " jogadores")
		else:
			print("Nenhum resultado encontrado no leaderboard")
			leaderboard_updated.emit([])
	).catch(func(error):
		print("Erro ao carregar leaderboard: " + str(error))
		leaderboard_updated.emit([])
	)

# Para todos os listeners para economizar recursos
func _stop_listeners():
	if _leaderboard_listener_connection:
		_leaderboard_listener_connection.stop()
		_leaderboard_listener_connection = null
		print("Listener do leaderboard interrompido")
