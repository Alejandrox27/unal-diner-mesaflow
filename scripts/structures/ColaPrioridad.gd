class_name ColaPrioridad
extends RefCounted

# Cada nodo será un Array: [prioridad, contador, elemento]
var _monticulo: Array = []
var _contador: int = 0

func encolar(prioridad: int, elemento: Variant) -> void:
	var nodo := [prioridad, _contador, elemento]
	_contador += 1
	_monticulo.push_back(nodo)
	_flotar(_monticulo.size() - 1)

func desencolar() -> Variant:
	if esta_vacia():
		return null
	var minimo = _monticulo[0][2]
	var ultimo = _monticulo.pop_back()
	if not esta_vacia():
		_monticulo[0] = ultimo
		_hundir(0)
	return minimo

func primero() -> Variant:
	return null if esta_vacia() else _monticulo[0][2]

func esta_vacia() -> bool:
	return _monticulo.is_empty()

func tamanio() -> int:
	return _monticulo.size()

func _flotar(indice: int) -> void:
	while indice > 0:
		var padre := int((indice - 1) / 2)
		if _es_menor(_monticulo[indice], _monticulo[padre]):
			var temp = _monticulo[indice]
			_monticulo[indice] = _monticulo[padre]
			_monticulo[padre] = temp
			indice = padre
		else:
			break

func _hundir(indice: int) -> void:
	var n := _monticulo.size()
	while true:
		var menor := indice
		var izq := 2 * indice + 1
		var der := 2 * indice + 2
		if izq < n and _es_menor(_monticulo[izq], _monticulo[menor]):
			menor = izq
		if der < n and _es_menor(_monticulo[der], _monticulo[menor]):
			menor = der
		if menor != indice:
			var temp = _monticulo[indice]
			_monticulo[indice] = _monticulo[menor]
			_monticulo[menor] = temp
			indice = menor
		else:
			break

func _es_menor(a: Array, b: Array) -> bool:
	if a[0] != b[0]:
		return a[0] < b[0] # Compara prioridad (0 gana a 1)
	return a[1] < b[1]     # Empate: gana el contador menor (orden de llegada)
