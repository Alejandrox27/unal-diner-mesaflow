class_name ColaFIFO
extends RefCounted

var _datos: Array = []

func encolar(elemento: Variant) -> void:
	_datos.push_back(elemento)

func desencolar() -> Variant:
	if esta_vacia():
		return null
	return _datos.pop_front()

func primero() -> Variant:
	return null if esta_vacia() else _datos[0]

func esta_vacia() -> bool:
	return _datos.is_empty()

func tamanio() -> int:
	return _datos.size()
	
func obtener_elementos() -> Array:
	return _datos.duplicate()
