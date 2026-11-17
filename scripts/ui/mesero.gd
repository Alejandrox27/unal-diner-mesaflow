class_name Mesero
extends CharacterBody2D

signal destino_alcanzado(accion_pendiente: Dictionary)

enum EstadoVisual { LIBRE, CON_COMIDA, SUCIOS_1, SUCIOS_2, SUCIOS_3 }

@export var velocidad: float = 360.0

# Ranuras listas para arrastrar los sprites reales (.png) en el Inspector cuando los tengan
@export_group("Sprites del Mesero")
@export var textura_libre: Texture2D
@export var textura_con_comida: Texture2D
@export var textura_1_plato_sucio: Texture2D
@export var textura_2_platos_sucios: Texture2D
@export var textura_3_platos_sucios: Texture2D

@onready var cuerpo_visual: ColorRect = $Cuerpo
@onready var sprite_personaje: Sprite2D = $SpritePersonaje
@onready var plato_1: ColorRect = $Plato1
@onready var plato_2: ColorRect = $Plato2
@onready var plato_3: ColorRect = $Plato3
@onready var etiqueta_mano: Label = $EtiquetaMano

var destino: Vector2
var moviendose: bool = false
var accion_pendiente: Dictionary = {}

func _ready() -> void:
	destino = global_position
	cambiar_estado_visual(EstadoVisual.LIBRE, "Manos libres")

func ir_a(punto: Vector2, accion: Dictionary = {}) -> void:
	destino = punto
	accion_pendiente = accion
	moviendose = true

func _physics_process(_delta: float) -> void:
	if not moviendose:
		return
		
	var distancia := global_position.distance_to(destino)
	if distancia <= 8.0:
		global_position = destino
		velocity = Vector2.ZERO
		moviendose = false
		var accion_ejecutar := accion_pendiente.duplicate()
		accion_pendiente.clear()
		if not accion_ejecutar.is_empty():
			destino_alcanzado.emit(accion_ejecutar)
	else:
		var direccion := global_position.direction_to(destino)
		velocity = direccion * velocidad
		move_and_slide()

func cambiar_estado_visual(estado: EstadoVisual, texto: String) -> void:
	etiqueta_mano.text = texto
	
	var usa_sprites := (textura_libre != null)
	cuerpo_visual.visible = not usa_sprites
	sprite_personaje.visible = usa_sprites
	
	match estado:
		EstadoVisual.LIBRE:
			cuerpo_visual.color = Color(0.95, 0.80, 0.20)
			plato_1.visible = false
			plato_2.visible = false
			plato_3.visible = false
			if textura_libre: sprite_personaje.texture = textura_libre
			
		EstadoVisual.CON_COMIDA:
			cuerpo_visual.color = Color(0.95, 0.45, 0.15)
			plato_1.visible = not usa_sprites
			plato_1.color = Color(0.20, 0.85, 0.40)
			plato_2.visible = false
			plato_3.visible = false
			if textura_con_comida: sprite_personaje.texture = textura_con_comida
			
		EstadoVisual.SUCIOS_1:
			cuerpo_visual.color = Color(0.60, 0.45, 0.32)
			plato_1.visible = not usa_sprites
			plato_1.color = Color(0.88, 0.88, 0.88)
			plato_2.visible = false
			plato_3.visible = false
			if textura_1_plato_sucio: sprite_personaje.texture = textura_1_plato_sucio
			
		EstadoVisual.SUCIOS_2:
			cuerpo_visual.color = Color(0.48, 0.34, 0.22)
			plato_1.visible = not usa_sprites
			plato_1.color = Color(0.88, 0.88, 0.88)
			plato_2.visible = not usa_sprites
			plato_2.color = Color(0.78, 0.78, 0.78)
			plato_3.visible = false
			if textura_2_platos_sucios: sprite_personaje.texture = textura_2_platos_sucios
			
		EstadoVisual.SUCIOS_3:
			cuerpo_visual.color = Color(0.35, 0.22, 0.14) # Café oscuro: pila llena (3/3)
			plato_1.visible = not usa_sprites
			plato_1.color = Color(0.88, 0.88, 0.88)
			plato_2.visible = not usa_sprites
			plato_2.color = Color(0.78, 0.78, 0.78)
			plato_3.visible = not usa_sprites
			plato_3.color = Color(0.68, 0.68, 0.68)
			if textura_3_platos_sucios: sprite_personaje.texture = textura_3_platos_sucios
