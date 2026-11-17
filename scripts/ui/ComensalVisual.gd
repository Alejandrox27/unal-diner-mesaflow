class_name ComensalVisual
extends Control

signal fila_clickeada

@onready var fondo: ColorRect = $Fondo
@onready var avatar: ColorRect = $Avatar
@onready var label_nombre: Label = $LabelNombre
@onready var barra_paciencia: ProgressBar = $BarraPaciencia

func _ready() -> void:
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label_nombre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	barra_paciencia.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		fila_clickeada.emit()
		accept_event()

func actualizar_vista(comensal: Comensal, es_primero: bool) -> void:
	var es_vip := (comensal.prioridad == 0)
	
	# Color del muñequito: Morado/Dorado para VIP, Azul para Regular
	avatar.color = Color(0.75, 0.35, 0.95) if es_vip else Color(0.22, 0.55, 0.90)
	
	# Resaltar al que encabeza la Cola FIFO (el único que pierde paciencia y entra primero)
	if es_primero:
		fondo.color = Color(0.28, 0.25, 0.14)
		label_nombre.text = "▶ " + comensal.nombre + (" ★" if es_vip else "")
	else:
		fondo.color = Color(0.15, 0.16, 0.20)
		label_nombre.text = comensal.nombre + (" ★" if es_vip else "")
		
	barra_paciencia.max_value = comensal.paciencia_max
	barra_paciencia.value = comensal.paciencia_actual
