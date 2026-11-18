extends Control

@export_file("*.tscn") var ruta_escena_juego: String = "res://scenes/NivelComedor.tscn"
@export var diapositivas: Array[Texture2D] = []

@onready var btn_empezar: Button = $ContenedorBotones/BtnEmpezar
@onready var btn_tutorial: Button = $ContenedorBotones/BtnTutorial
@onready var overlay_tutorial: Control = $OverlayTutorial
@onready var imagen_diapositiva: TextureRect = $OverlayTutorial/ImagenDiapositiva
@onready var btn_anterior: Button = $OverlayTutorial/BtnAnterior
@onready var btn_siguiente: Button = $OverlayTutorial/BtnSiguiente
@onready var btn_cerrar: Button = $OverlayTutorial/BtnCerrar
@onready var label_contador: Label = $OverlayTutorial/LabelContador

var indice_actual: int = 0

func _ready() -> void:
	overlay_tutorial.visible = false
	btn_empezar.pressed.connect(_al_presionar_empezar)
	btn_tutorial.pressed.connect(_al_presionar_tutorial)
	btn_anterior.pressed.connect(_al_presionar_anterior)
	btn_siguiente.pressed.connect(_al_presionar_siguiente)
	btn_cerrar.pressed.connect(_al_presionar_cerrar)

func _al_presionar_empezar() -> void:
	get_tree().change_scene_to_file(ruta_escena_juego)

func _al_presionar_tutorial() -> void:
	if diapositivas.is_empty():
		return
	indice_actual = 0
	_actualizar_diapositiva()
	overlay_tutorial.visible = true

func _al_presionar_anterior() -> void:
	if indice_actual > 0:
		indice_actual -= 1
		_actualizar_diapositiva()

func _al_presionar_siguiente() -> void:
	if indice_actual < diapositivas.size() - 1:
		indice_actual += 1
		_actualizar_diapositiva()

func _al_presionar_cerrar() -> void:
	overlay_tutorial.visible = false

func _actualizar_diapositiva() -> void:
	imagen_diapositiva.texture = diapositivas[indice_actual]
	label_contador.text = "%d / %d" % [indice_actual + 1, diapositivas.size()]
	btn_anterior.disabled = (indice_actual == 0)
	btn_siguiente.disabled = (indice_actual == diapositivas.size() - 1)
