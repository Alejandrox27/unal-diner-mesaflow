class_name Comensal
extends RefCounted

var id: int
var nombre: String
var prioridad: int # 0 = Subsidio / Monitor / Docente (VIP), 1 = Regular
var paciencia_max: float
var paciencia_actual: float

func _init(p_id: int, p_nombre: String, p_prioridad: int = 1, p_paciencia: float = 30.0) -> void:
	id = p_id
	nombre = p_nombre
	prioridad = p_prioridad
	paciencia_max = p_paciencia
	paciencia_actual = p_paciencia
