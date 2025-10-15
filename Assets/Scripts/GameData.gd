extends Node

# Singleton para armazenar dados do jogo entre cenas
var ultima_pontuacao: int = 0
var user_id: String = ""
var user_name: String = ""

func set_game_over_data(pontos: int, id: String, nome: String):
	ultima_pontuacao = pontos
	user_id = id
	user_name = nome
	print("📊 GameData: Pontuação armazenada: %d (Usuário: %s)" % [pontos, nome])

func get_pontuacao() -> int:
	return ultima_pontuacao

func get_user_id() -> String:
	return user_id

func get_user_name() -> String:
	return user_name
