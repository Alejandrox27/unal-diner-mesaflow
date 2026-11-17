class_name PilaLIFO
extends RefCounted

var _datos: Array = []

func apilar(elemento: Variant) -> void:
	_datos.push_back(elemento)

func desapilar() -> Variant:
	if esta_vacia():
		return null
	return _datos.pop_back()

func cima() -> Variant:
	return null if esta_vacia() else _datos[-1]

func esta_vacia() -> bool:
	return _datos.is_empty()

func tamanio() -> int:
	return _datos.size()
