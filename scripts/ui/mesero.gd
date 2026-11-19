class_name Mesero
extends CharacterBody2D

signal destino_alcanzado(accion_pendiente: Dictionary)

enum EstadoVisual { LIBRE, CON_COMIDA, SUCIOS_1, SUCIOS_2, SUCIOS_3 }

@export var velocidad: float = 360.0
@export var factor_escala_caminar: float = 0.55
@export var factor_escala_caminar_cargando: float = 1.0

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
var pos_base_sprite: Vector2 = Vector2.ZERO
var escala_base: Vector2 = Vector2.ONE

func _ready() -> void:
	destino = global_position
	escala_base = animacion.scale
	pos_base_sprite = animacion.position
	offset_x_platos = plato_comida.position.x
	cambiar_estado_visual(EstadoVisual.LIBRE, "Manos libres")
	_reproducir_animacion("quieto")
	
func ir_a(punto: Vector2, accion: Dictionary = {}) -> void:
	destino = punto
	accion_pendiente = accion
	moviendose = true

func _physics_process(_delta: float) -> void:
	if not moviendose:
		animacion.position = pos_base_sprite
		_reproducir_animacion("quieto")
		return
		
	var distancia := global_position.distance_to(destino)
	if distancia <= 8.0:
		global_position = destino
		velocity = Vector2.ZERO
		moviendose = false
		animacion.position = pos_base_sprite
		_reproducir_animacion("quieto")
		var accion_ejecutar := accion_pendiente.duplicate()
		accion_pendiente.clear()
		if not accion_ejecutar.is_empty():
			destino_alcanzado.emit(accion_ejecutar)
	else:
		var direccion := global_position.direction_to(destino)
		velocity = direccion * velocidad
		_actualizar_orientacion_y_animacion(direccion)
		# Eleva 2 px el sprite en el fotograma 1 para marcar el paso
		animacion.position.y = pos_base_sprite.y - (2.0 if animacion.frame == 1 else 0.0)
		move_and_slide()

func _actualizar_orientacion_y_animacion(direccion: Vector2) -> void:
	if direccion.x < -0.05:
		animacion.flip_h = true
		_actualizar_lado_platos(-1.0)
	elif direccion.x > 0.05:
		animacion.flip_h = false
		_actualizar_lado_platos(1.0)
		
	if abs(direccion.x) >= abs(direccion.y):
		_reproducir_animacion("caminar")
	else:
		if direccion.y < 0:
			_reproducir_animacion("caminar_arriba")
		else:
			_reproducir_animacion("caminar_abajo")

func _reproducir_animacion(base: String) -> void:
	if not animacion.sprite_frames:
		return
		
	var es_movimiento := base.begins_with("caminar")
	var objetivo := base + "_cargando" if esta_cargando else base
	var respaldo_mov := "caminar_cargando" if esta_cargando else "caminar"
	var respaldo_quieto := "quieto_cargando" if esta_cargando else "quieto"
	
	var anim_final := ""
	if animacion.sprite_frames.has_animation(objetivo):
		anim_final = objetivo
	elif animacion.sprite_frames.has_animation(base):
		anim_final = base
	elif es_movimiento and animacion.sprite_frames.has_animation(respaldo_mov):
		anim_final = respaldo_mov
	elif es_movimiento and animacion.sprite_frames.has_animation("caminar"):
		anim_final = "caminar"
	elif animacion.sprite_frames.has_animation(respaldo_quieto):
		anim_final = respaldo_quieto
	elif animacion.sprite_frames.has_animation("quieto"):
		anim_final = "quieto"
		
	if anim_final != "":
		if anim_final == "caminar":
			animacion.scale = escala_base * factor_escala_caminar
		elif anim_final == "caminar_cargando":
			animacion.scale = escala_base * factor_escala_caminar_cargando
		else:
			animacion.scale = escala_base
			
		if animacion.animation != anim_final or not animacion.is_playing():
			animacion.play(anim_final)

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
			
	_reproducir_animacion("caminar" if moviendose else "quieto")
