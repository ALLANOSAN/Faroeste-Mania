extends Control

@onready var back_button = %BackButton
@onready var player_id_value = %PlayerIDValue # exibe ID do jogador
@onready var username_value = %NomeJogadorValue # exibe nome atual
@onready var username_input = %UsernameInput # input para novo nome
@onready var save_username_button = %SaveUsernameButton # botão “SALVAR”
@onready var status_label = %StatusLabel # feedback de sucesso/erro
@onready var logout_button = %LogoutButton # botão “LOGOUT”
@onready var player_rank_label = %PlayerRankLabel # exibe rank
@onready var player_score_label = %PlayerScoreLabel # exibe maior pontuação

@onready var delete_account_button = %DeleteAccountButton
@onready var global = get_node("/root/Global")

func _ready() -> void:
    back_button.pressed.connect(_on_back)
    logout_button.pressed.connect(_on_logout)
    save_username_button.pressed.connect(_on_save_username)
    delete_account_button.pressed.connect(_on_delete_account)

    global.user_data_updated.connect(_on_user_data_updated)

    # dispara carga inicial
    global.load_user_data()
    global.load_leaderboard()
func _on_delete_account() -> void:
    status_label.text = "Excluindo conta..."
    await global.delete_account()
    status_label.text = "Conta excluída com sucesso."
    await get_tree().create_timer(1.0).timeout
    get_tree().change_scene_to_file("res://Assets/Scenes/MainMenuLogin.tscn")

func _on_user_data_updated(data: Dictionary) -> void:
    if data.has("id"):
        player_id_value.text = "ID: " + data["id"]
    if data.has("high_score"):
        player_score_label.text = "Sua maior pontuação: %d" % data["high_score"]
    if data.has("name"):
        username_value.text = data["name"]
        username_input.text = data["name"]
        status_label.text = "Dados atualizados"
    if data.has("rank"):
        var rank = int(data["rank"])
        if rank > 0:
            player_rank_label.text = "%dº lugar" % rank
        else:
            player_rank_label.text = "Sem classificação"


func _on_logout() -> void:
    global.logout()
    get_tree().change_scene_to_file("res://Assets/Scenes/MainMenuLogin.tscn")

func _on_back() -> void:
    get_tree().change_scene_to_file("res://Assets/Scenes/MenuOpções.tscn")
