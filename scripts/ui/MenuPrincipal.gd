extends Control

const ESCENA_JUEGO := "res://scenes/NivelComedor.tscn"

@onready var btn_empezar: Button = $BtnEmpezar

func _ready() -> void:
	btn_empezar.pressed.connect(_on_empezar_presionado)

func _on_empezar_presionado() -> void:
	get_tree().change_scene_to_file(ESCENA_JUEGO)
