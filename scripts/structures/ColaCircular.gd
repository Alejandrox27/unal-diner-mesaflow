class_name ColaCircular
extends RefCounted

var _arreglo: Array = []
var _capacidad: int
var _frente: int = 0
var _rear: int = 0
var _tamanio: int = 0

func _init(capacidad: int) -> void:
	_capacidad = capacidad
	_arreglo.resize(capacidad)
	_arreglo.fill(null)

func encolar(elemento: Variant) -> bool:
	if _tamanio == _capacidad:
		return false
	_arreglo[_rear] = elemento
	_rear = (_rear + 1) % _capacidad
	_tamanio += 1
	return true

func avanzar_round_robin() -> Variant:
	if _tamanio == 0:
		return null
	var elemento = _arreglo[_frente]
	_frente = (_frente + 1) % _capacidad
	return elemento

func tamanio() -> int:
	return _tamanio
