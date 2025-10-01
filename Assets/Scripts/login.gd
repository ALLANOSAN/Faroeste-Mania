extends Control

func _ready():
	Firebase.Auth.login_succeeded.connect(on_login_succeeded)
	Firebase.Auth.login_failed.connect(on_login_failed)

	if Firebase.Auth.check_auth_file():
		%FeedbackText.text = "Logged in"
		get_tree().change_scene_to_file("res://Assets/Scenes/MainMenuLogin.tscn")


func _on_login_button_pressed():
	var email = %email.text
	var password = %password.text
	Firebase.Auth.login_with_email_and_password(email, password)
	%FeedbackText.text = "Logging in"


func on_login_succeeded(auth):
	print(auth)
	%FeedbackText.text = "Login success!"
	Firebase.Auth.save_auth(auth)
	get_tree().change_scene_to_file("res://Assets/Scenes/MainMenuLogin.tscn")

func on_login_failed(error_code, message):
	print(error_code)
	print(message)
	%FeedbackText.text = "Login failed. Error: %s" % message
	
	


func _on_signup_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Assets/Scenes/signup.tscn")
