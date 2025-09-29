extends Control

# Called when the node enters the scene tree for the first time.
func _ready():
	Firebase.Auth.signup_succeeded.connect(on_signup_succeeded)
	Firebase.Auth.signup_failed.connect(on_signup_failed)

func _on_signup_button_pressed():
	var email = %email.text
	var password = %password.text
	Firebase.Auth.signup_with_email_and_password(email, password)
	%FeedbackText2.text = "Conta criada com sucesso!"

func on_signup_succeeded(auth):
	var uid = auth["uid"]              # aqui usa 'auth', não 'auth_data'
	var display_name = $%display_name.text

	var users_collection = Firebase.Firestore.collection("users")
	await users_collection.add(uid, {"display_name": display_name})

	$%FeedbackText2.text = "Conta criada com sucesso!"
	get_tree().change_scene_to_file("res://Assets/Scenes/login.tscn")

func on_signup_failed(error_code, message):
	print(error_code)
	print(message)
	%FeedbackText2.text = "Erro ao fazer o cadastro. Error: %s" % message
