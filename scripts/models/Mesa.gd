class_name Mesa
extends RefCounted

enum Estado { LIBRE, OCUPADA, SUCIA }

var numero: int
var capacidad: int
var estado: Estado = Estado.LIBRE
var comensal_actual: Comensal = null

func _init(p_numero: int, p_capacidad: int = 4) -> void:
	numero = p_numero
	capacidad = p_capacidad
