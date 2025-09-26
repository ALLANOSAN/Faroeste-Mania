# Deleta a conta do usuário autenticado e remove seus dados do Firestore
func delete_account() -> void:
	var uid = get_current_user_id()
	if uid == "":
		push_error("Usuário não está logado!")
		return

	# 1. Deleta usuário do Auth
	var err = await Firebase.Auth.delete_user()
	if err != null:
		push_error("Erro ao deletar conta do Auth: %s" % err)
		return

	# 2. Remove dados do Firestore (users e scores)
	err = await Firebase.Firestore.collection("users").delete(uid)
	if err != null:
		push_error("Erro ao deletar perfil do Firestore: %s" % err)
	err = await Firebase.Firestore.collection("scores").delete(uid)
	if err != null:
		push_error("Erro ao deletar score do Firestore: %s" % err)

	# 3. Limpa dados locais e emite sinal de logout
	player_data = {"id": "", "name": "", "high_score": 0}
	auth_state_changed.emit(false)
	print("Conta e dados removidos com sucesso!")
extends Node

signal auth_state_changed(is_logged_in)
signal user_data_updated(user_data)
signal scores_updated(scores_data)

var player_data = {
	"id": "",
	"name": "",
	"high_score": 0
}

func _ready() -> void:
	print("Global initialized")
	# Opcional: ao carregar (editor ou runtime), notifique estado
	auth_state_changed.emit(is_user_logged_in())

#
# PROFILE
#
func create_user_profile_document(user_id: String, display_name: String) -> void:
	var data = {
		"display_name": display_name,
		"high_score": 0
	}
	Firebase.Firestore.collection("users").add(user_id, data)

func load_user_data() -> void:
	var uid = get_current_user_id()
	if uid == "": return
	# Busca dados do usuário
	Firebase.Firestore.collection("users").get_doc(uid).then(func(doc):
		if doc and not doc.error:
			var user_data = {
				"id": uid,
				"name": doc.get("display_name", ""),
				"high_score": doc.get("high_score", 0)
			}
			# Agora busca o rank na coleção scores
			Firebase.Firestore.collection("scores").get_doc(uid).then(func(score_doc):
				if score_doc and not score_doc.error:
					user_data["rank"] = score_doc.get("rank", 0)
				else:
					user_data["rank"] = 0
				user_data_updated.emit(user_data)
			)
		else:
			user_data_updated.emit({})
	)

func _on_user_doc_fetched(doc) -> void:
	if doc and not doc.error:
		player_data.id = get_current_user_id()
		player_data.name = doc.get("display_name", "")
		player_data.high_score = doc.get("high_score", 0)
		user_data_updated.emit({
			"id": player_data.id,
			"name": player_data.name,
			"high_score": player_data.high_score
		})

        
func update_player_name(new_name: String) -> void:
	var uid = get_current_user_id()
	# como o jogador sempre está logado, não precisa de if uid == ""
	# chama o update e espera o resultado
	var err = await Firebase.Firestore.collection("users").update(uid, {
		"display_name": new_name
	})
	if err == null:
		# Atualiza também o username na coleção de scores
		var err2 = await Firebase.Firestore.collection("scores").update(uid, {
			"username": new_name
		})
		if err2 != null:
			push_error("Erro ao atualizar username no leaderboard: %s" % err2)
		# sucessão do update: atualiza cache e dispara o sinal
		player_data.name = new_name
		user_data_updated.emit({
			"name": player_data.name
		})
		load_leaderboard() # força refresh do leaderboard após update
	else:
		push_error("Erro ao atualizar nome de usuário: %s" % err)

func update_player_high_score(new_score: int) -> void:
	var uid = get_current_user_id()
	if uid == "" or new_score <= player_data.high_score:
		return
	# Atualiza o high_score do usuário
	var err = await Firebase.Firestore.collection("users").update(uid, {
		"high_score": new_score
	})
	if err == null:
		player_data.high_score = new_score
		# Agora atualiza o rank e username na coleção de scores
		await _update_score_and_rank(uid, new_score, player_data.name)
		load_leaderboard()
	else:
		push_error("Erro ao atualizar high_score: %s" % err)

# Atualiza/insere o score do usuário e recalcula o rank
func _update_score_and_rank(uid: String, score: int, username: String) -> void:
	# Atualiza o score
	var err = await Firebase.Firestore.collection("scores").set(uid, {
		"score": score,
		"username": username
	}, true) # merge = true
	if err != null:
		push_error("Erro ao atualizar score: %s" % err)
		return
	# Busca quantos têm score maior
	var q = FirestoreQuery.new()
	q.from("scores")
	q.where("score", FirestoreQuery.OP.GREATER_THAN, score)
	var res = await Firebase.Firestore.query(q)
	var rank = (res.size() if res else 0) + 1
	# Atualiza o rank no documento de score
	err = await Firebase.Firestore.collection("scores").update(uid, {
		"rank": rank
	})
	if err != null:
		push_error("Erro ao atualizar rank: %s" % err)

#
# LEADERBOARD
#
func load_leaderboard() -> void:
	var q = FirestoreQuery.new()
	q.from("scores")
	q.select(["username", "score", "rank"])
	q.order_by("score", FirestoreQuery.DIRECTION.DESCENDING)
	q.limit(10)
	Firebase.Firestore.query(q).then(_on_leaderboard_fetched)

func _on_leaderboard_fetched(results) -> void:
	var arr := []
	for d in results:
		arr.append({
			"user_id": d.doc_name,
			"name": d.get("username", "—"),
			"score": d.get("score", 0),
			"rank": d.get("rank", 0)
		})
	scores_updated.emit(arr)

#
# AUTH HELPERS
#
func is_user_logged_in() -> bool:
	return Firebase and Firebase.Auth and Firebase.Auth.check_auth_file()

func get_current_user_id() -> String:
	if not is_user_logged_in(): return ""
	return Firebase.Auth.get_user_data().localId

func get_player_name() -> String:
	return player_data.name

func get_player_high_score() -> int:
	return player_data.high_score
