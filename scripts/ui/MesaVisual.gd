class_name MesaVisual
extends Control

signal mesa_clickeada(mesa: Mesa, punto_atencion: Vector2)

@onready var fondo: ColorRect = $Fondo
@onready var label_info: Label = $LabelInfo
@onready var barra_paciencia: ProgressBar = $BarraPaciencia

var mesa_referencia: Mesa = null

func _ready() -> void:
	# Evitar que los elementos internos bloqueen el clic sobre la mesa
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label_info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	barra_paciencia.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if mesa_referencia != null:
			# El mesero caminará justo frente al borde inferior de esta mesa
			var punto_atencion := global_position + Vector2(size.x * 0.5, size.y + 28.0)
			mesa_clickeada.emit(mesa_referencia, punto_atencion)
			accept_event()

func actualizar_vista(mesa: Mesa, destacada: bool = false) -> void:
	mesa_referencia = mesa
	match mesa.estado:
		Mesa.Estado.LIBRE:
			fondo.color = Color(0.18, 0.55, 0.34) # Verde (Disponible)
			label_info.text = "Mesa #" + str(mesa.numero) + "\n[LIBRE]"
			barra_paciencia.visible = false
			
		Mesa.Estado.OCUPADA:
			var c: Comensal = mesa.comensal_actual
			var tag_vip := "★ VIP" if c.prioridad == 0 else "Regular"
			if destacada:
				fondo.color = Color(0.92, 0.52, 0.12) # Naranja brillante: ¡Tienes su bandeja!
			else:
				fondo.color = Color(0.45, 0.22, 0.65) if c.prioridad == 0 else Color(0.16, 0.38, 0.65)
			label_info.text = "Mesa #" + str(mesa.numero) + "\n" + c.nombre + "\n(" + tag_vip + ")"
			barra_paciencia.visible = true
			barra_paciencia.max_value = c.paciencia_max
			barra_paciencia.value = c.paciencia_actual
			
		Mesa.Estado.SUCIA:
			fondo.color = Color(0.45, 0.32, 0.20) # Café (Loza sucia)
			label_info.text = "Mesa #" + str(mesa.numero) + "\n[SUCIA]\nClic: recoger"
			barra_paciencia.visible = false
