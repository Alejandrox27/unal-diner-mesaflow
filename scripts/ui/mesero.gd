class_name Mesero
extends CharacterBody2D

signal destino_alcanzado(accion_pendiente: Dictionary)

enum EstadoVisual { LIBRE, CON_COMIDA, SUCIOS_1, SUCIOS_2, SUCIOS_3 }

@export var velocidad: float = 360.0

@onready var animacion: AnimatedSprite2D = $AnimatedSprite2D
@onready var plato_comida: Sprite2D = $AnimatedSprite2D/PlatoComida
@onready var plato_sucio_1: Sprite2D = $AnimatedSprite2D/PlatoSucio1
@onready var plato_sucio_2: Sprite2D = $AnimatedSprite2D/PlatoSucio2
@onready var plato_sucio_3: Sprite2D = $AnimatedSprite2D/PlatoSucio3
@onready var etiqueta_mano: Label = $EtiquetaMano

var destino: Vector2
var moviendose: bool = false
var accion_pendiente: Dictionary = {}
var offset_x_platos: float = 0.0
var esta_cargando: bool = false

func _ready() -> void:
	destino = global_position
	offset_x_platos = plato_comida.position.x
	cambiar_estado_visual(EstadoVisual.LIBRE, "Manos libres")
	_reproducir_animacion("quieto")

func ir_a(punto: Vector2, accion: Dictionary = {}) -> void:
	destino = punto
	accion_pendiente = accion
	moviendose = true

func _physics_process(_delta: float) -> void:
	if not moviendose:
		_reproducir_animacion("quieto")
		return
		
	var distancia := global_position.distance_to(destino)
	if distancia <= 8.0:
		global_position = destino
		velocity = Vector2.ZERO
		moviendose = false
		_reproducir_animacion("quieto")
		var accion_ejecutar := accion_pendiente.duplicate()
		accion_pendiente.clear()
		if not accion_ejecutar.is_empty():
			destino_alcanzado.emit(accion_ejecutar)
	else:
		var direccion := global_position.direction_to(destino)
		velocity = direccion * velocidad
		_actualizar_orientacion_y_animacion(direccion)
		move_and_slide()

func _actualizar_orientacion_y_animacion(direccion: Vector2) -> void:
	if abs(direccion.x) >= abs(direccion.y):
		if direccion.x < 0:
			animacion.flip_h = true
			_actualizar_lado_platos(-1.0)
		elif direccion.x > 0:
			animacion.flip_h = false
			_actualizar_lado_platos(1.0)
		_reproducir_animacion("caminar")
	else:
		if direccion.y < 0:
			_reproducir_animacion("caminar_arriba")
		else:
			_reproducir_animacion("caminar_abajo")

func _reproducir_animacion(base: String) -> void:
	if not animacion.sprite_frames:
		return
		
	# Si lleva platos, busca primero la versión "_cargando" (ej. "quieto_cargando")
	var nombre_objetivo := base + "_cargando" if esta_cargando else base
	
	if animacion.sprite_frames.has_animation(nombre_objetivo):
		if animacion.animation != nombre_objetivo or not animacion.is_playing():
			animacion.play(nombre_objetivo)
	elif animacion.sprite_frames.has_animation(base):
		if animacion.animation != base or not animacion.is_playing():
			animacion.play(base)
	else:
		var fallback := "quieto_cargando" if (esta_cargando and animacion.sprite_frames.has_animation("quieto_cargando")) else "quieto"
		if animacion.sprite_frames.has_animation(fallback) and animacion.animation != fallback:
			animacion.play(fallback)

func _actualizar_lado_platos(signo: float) -> void:
	var pos_x := absf(offset_x_platos) * signo
	plato_comida.position.x = pos_x
	plato_sucio_1.position.x = pos_x
	plato_sucio_2.position.x = pos_x
	plato_sucio_3.position.x = pos_x

func cambiar_estado_visual(estado: EstadoVisual, texto: String = "") -> void:
	if etiqueta_mano:
		etiqueta_mano.text = texto
	
	plato_comida.visible = false
	plato_sucio_1.visible = false
	plato_sucio_2.visible = false
	plato_sucio_3.visible = false
	
	match estado:
		EstadoVisual.LIBRE:
			esta_cargando = false
		EstadoVisual.CON_COMIDA:
			esta_cargando = true
			plato_comida.visible = true
		EstadoVisual.SUCIOS_1:
			esta_cargando = true
			plato_sucio_1.visible = true
		EstadoVisual.SUCIOS_2:
			esta_cargando = true
			plato_sucio_1.visible = true
			plato_sucio_2.visible = true
		EstadoVisual.SUCIOS_3:
			esta_cargando = true
			plato_sucio_1.visible = true
			plato_sucio_2.visible = true
			plato_sucio_3.visible = true
			
	# Actualiza la pose al instante aunque el mesero esté quieto frente a la cocina o mesa
	_reproducir_animacion("caminar" if moviendose else "quieto")
