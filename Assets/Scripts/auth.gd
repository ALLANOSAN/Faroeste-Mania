extends Control

signal login_failed(error_code, message)
signal login_succeeded(auth)
signal signup_failed(error_code, message)
signal signup_succeeded(auth)

func _ready():
	Firebase.Auth.login_succeeded.connect(on_login_succeeded)
	Firebase.Auth.login_failed.connect(on_login_failed)
	Firebase.Auth.signup_succeeded.connect(on_signup_succeeded)
	Firebase.Auth.signup_failed.connect(on_signup_failed)

func login(email: String, password: String) -> void:
	Firebase.Auth.sign_in_with_email_and_password(email, password)

func signup(email: String, password: String) -> void:
	Firebase.Auth.create_user_with_email_and_password(email, password)

func on_login_succeeded(auth: Dictionary) -> void:
	Firebase.Auth.save_auth(auth)
	Firebase.Auth.load_auth()
	login_succeeded.emit(auth)

func on_login_failed(code, msg) -> void:
	login_failed.emit(code, msg)

func on_signup_succeeded(auth: Dictionary) -> void:
	Firebase.Auth.save_auth(auth)
	Firebase.Auth.load_auth()
	signup_succeeded.emit(auth)

func on_signup_failed(code, msg) -> void:
	signup_failed.emit(code, msg)

func logout() -> void:
	Firebase.Auth.logout()
