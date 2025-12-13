extends Node

# Singleton para armazenar dados do jogo entre cenas e gerenciar ranking local

const SCORES_FILE = "user://scores.json"
const MAX_SCORES = 10 # Máximo de pontuações no ranking

# Pontuação atual (entre cenas)
var ultima_pontuacao: int = 0

# Define a pontuação atual
func set_pontuacao(pontos: int):
	ultima_pontuacao = pontos
	print("📊 GameData: Pontuação armazenada: %d" % pontos)

# Retorna a pontuação atual
func get_pontuacao() -> int:
	return ultima_pontuacao


# =========================
# Sistema de Ranking Local
# =========================

# Salva uma nova pontuação no ranking local
func salvar_pontuacao(nome: String, pontos: int) -> void:
	var scores = carregar_todas_pontuacoes()
	
	# Adiciona nova pontuação
	scores.append({
		"nome": nome,
		"pontos": pontos,
		"data": Time.get_datetime_string_from_system()
	})
	
	# Ordena por pontuação (maior primeiro)
	scores.sort_custom(func(a, b): return a.pontos > b.pontos)
	
	# Mantém apenas as top N pontuações
	if scores.size() > MAX_SCORES:
		scores.resize(MAX_SCORES)
	
	# Salva no arquivo
	var file = FileAccess.open(SCORES_FILE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(scores))
		file.close()
		print("💾 Pontuação salva localmente: %s - %d pontos" % [nome, pontos])
	else:
		push_error("Erro ao salvar pontuações locais")


# Carrega todas as pontuações do arquivo local
func carregar_todas_pontuacoes() -> Array:
	if not FileAccess.file_exists(SCORES_FILE):
		return []
	
	var file = FileAccess.open(SCORES_FILE, FileAccess.READ)
	if file == null:
		return []
	
	var json = JSON.new()
	var parse_result = json.parse(file.get_as_text())
	file.close()
	
	if parse_result != OK:
		return []
	
	return json.data if json.data is Array else []


# Retorna o ranking ordenado (para exibição no leaderboard)
func get_ranking() -> Array:
	var scores = carregar_todas_pontuacoes()
	# Garante que está ordenado
	scores.sort_custom(func(a, b): return a.pontos > b.pontos)
	return scores


# Verifica se a pontuação entra no top 10
func eh_top_score(pontos: int) -> bool:
	var scores = carregar_todas_pontuacoes()
	if scores.size() < MAX_SCORES:
		return true
	# Verifica se a pontuação é maior que a menor do ranking
	var menor = scores[-1].pontos if scores.size() > 0 else 0
	return pontos > menor


# Limpa o ranking (para testes ou reset)
func limpar_ranking() -> void:
	if FileAccess.file_exists(SCORES_FILE):
		DirAccess.remove_absolute(SCORES_FILE)
		print("🗑️ Ranking local limpo")
