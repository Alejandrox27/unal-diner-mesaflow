extends Node2D

const ESCENA_MESA := preload("res://scenes/MesaVisual.tscn")
const ESCENA_COMENSAL := preload("res://scenes/ComensalVisual.tscn")
const MAX_PLATOS_SUCIOS := 3
const MAX_FILA_ENTRADA := 5

# Ahora cada comedor incluye "tiempo" (duración del turno en segundos)
const NIVELES_UNAL := [
	{"nombre": "Nivel 1: Comedor de Agrarias", "meta": 700, "tiempo": 65.0, "mesas": 4, "spawn": 6.5, "paciencia": 35.0, "prob_vip": 0.30},
	{"nombre": "Nivel 2: Comedor del NEA", "meta": 950, "tiempo": 75.0, "mesas": 4, "spawn": 5.5, "paciencia": 30.0, "prob_vip": 0.35},
	{"nombre": "Nivel 3: Comedor de la Hemeroteca", "meta": 1200, "tiempo": 85.0, "mesas": 5, "spawn": 4.5, "paciencia": 26.0, "prob_vip": 0.40},
	{"nombre": "Nivel 4: Comedor del YU", "meta": 1500, "tiempo": 95.0, "mesas": 5, "spawn": 3.8, "paciencia": 24.0, "prob_vip": 0.50},
	{"nombre": "Nivel 5: Comedor Central (Final)", "meta": 2100, "tiempo": 110.0, "mesas": 6, "spawn": 3.0, "paciencia": 22.0, "prob_vip": 0.55}
]

# --- LAS 4 ESTRUCTURAS DE DATOS LINEALES ---
var fila_entrada := ColaFIFO.new()
var pedidos_cocina := ColaPrioridad.new()
var pila_loza_mano := PilaLIFO.new()
var pila_undo := PilaLIFO.new()
var mesas_rr: ColaCircular

@onready var timer_llegadas: Timer = $TimerLlegadas
@onready var contenedor_mesas: Control = $ContenedorMesas
@onready var contenedor_fila: VBoxContainer = $ContenedorFila
@onready var label_estado: Label = $LabelEstado
@onready var btn_reintentar: Button = $BtnReintentar
@onready var mesero: Mesero = $Mesero
@onready var sfx_servir: AudioStreamPlayer = $SfxServir
@onready var sfx_tomar_plato: AudioStreamPlayer = $SfxTomarPlato

var nivel_actual: int = 0
var mesas_datos: Array[Mesa] = []
var mesas_visuales: Array[MesaVisual] = []
var fila_visuales: Array[ComensalVisual] = []
var contador_estudiantes: int = 0
var puntaje: int = 0
var puntaje_total: int = 0
var puntaje_inicio_nivel: int = 0
var atendidos: int = 0
var enojados: int = 0
var tiempo_restante: float = 0.0
var nivel_perdido: bool = false
var juego_completado: bool = false

var plato_en_mano_mesa: Mesa = null
var comensal_escoltado: Comensal = null
var mesa_escolta_destino: Mesa = null

var nombres_unal := ["Camila", "Andrés", "Valentina", "Mateo", "Sofía", "Julián", "Daniela", "Sebastián", "Laura", "David"]

func _ready() -> void:
	timer_llegadas.timeout.connect(_on_nuevo_estudiante_llega)
	mesero.destino_alcanzado.connect(_on_mesero_llego_a_destino)
	
	$ZonaPuerta.pressed.connect(_on_clic_puerta)
	$ZonaCocina.pressed.connect(_on_clic_cocina)
	$ZonaLavaplatos.pressed.connect(_on_clic_lavaplatos)
	$BtnDeshacer.pressed.connect(_on_deshacer_presionado)
	btn_reintentar.pressed.connect(_on_reintentar_presionado)
	
	_cargar_nivel(0)

func _unhandled_input(event: InputEvent) -> void:
	if nivel_perdido or juego_completado or comensal_escoltado != null:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var pos_clic := get_global_mouse_position()
		pos_clic.x = clamp(pos_clic.x, 195.0, 945.0)
		pos_clic.y = clamp(pos_clic.y, 85.0, 595.0)
		mesero.ir_a(pos_clic)

func _cargar_nivel(indice: int) -> void:
	nivel_actual = indice
	var config: Dictionary = NIVELES_UNAL[nivel_actual]
	puntaje = 0
	puntaje_total = puntaje_inicio_nivel
	tiempo_restante = config["tiempo"]
	nivel_perdido = false
	juego_completado = false
	btn_reintentar.visible = false
	
	fila_entrada = ColaFIFO.new()
	pedidos_cocina = ColaPrioridad.new()
	pila_loza_mano = PilaLIFO.new()
	pila_undo = PilaLIFO.new()
	mesas_rr = ColaCircular.new(config["mesas"])
	plato_en_mano_mesa = null
	comensal_escoltado = null
	mesa_escolta_destino = null
	_actualizar_apariencia_mesero()
	
	for hijo in contenedor_mesas.get_children():
		hijo.queue_free()
	mesas_datos.clear()
	mesas_visuales.clear()
	
	var total_mesas: int = config["mesas"]
	var centro_salon := Vector2(565.0, 330.0)
	var radio_x := 265.0
	var radio_y := 180.0
	
	for i in range(1, total_mesas + 1):
		var nueva_mesa := Mesa.new(i)
		mesas_datos.append(nueva_mesa)
		mesas_rr.encolar(nueva_mesa)
		
		var vista_mesa: MesaVisual = ESCENA_MESA.instantiate()
		contenedor_mesas.add_child(vista_mesa)
		
		var angulo := (TAU / total_mesas) * (i - 1) - (PI / 2.0)
		var posicion_mesa := centro_salon + Vector2(cos(angulo) * radio_x, sin(angulo) * radio_y)
		vista_mesa.position = posicion_mesa - (vista_mesa.size * 0.5)
		
		mesas_visuales.append(vista_mesa)
		vista_mesa.mesa_clickeada.connect(_on_clic_mesa)
		vista_mesa.actualizar_vista(nueva_mesa)
	
	timer_llegadas.wait_time = config["spawn"]
	timer_llegadas.start()
	
	_on_nuevo_estudiante_llega()
	_on_nuevo_estudiante_llega()
	_reconstruir_fila_visual()
	_refrescar_hud()

func _process(delta: float) -> void:
	if nivel_perdido or juego_completado:
		return
		
	# 0. Descontar el reloj del turno
	tiempo_restante -= delta
	if tiempo_restante <= 0.0:
		tiempo_restante = 0.0
		_perder_nivel()
		return
		
	# 1. Paciencia de los estudiantes sentados en mesas
	for i in range(mesas_datos.size()):
		var mesa := mesas_datos[i]
		if mesa.estado == Mesa.Estado.OCUPADA and mesa.comensal_actual != null:
			mesa.comensal_actual.paciencia_actual -= delta
			var es_objetivo := (plato_en_mano_mesa == mesa)
			mesas_visuales[i].actualizar_vista(mesa, es_objetivo)
			
			if mesa.comensal_actual.paciencia_actual <= 0:
				enojados += 1
				puntaje = max(0, puntaje - 50)
				puntaje_total = max(0, puntaje_total - 50)
				if plato_en_mano_mesa == mesa:
					plato_en_mano_mesa = null
					_actualizar_apariencia_mesero()
				mesa.comensal_actual = null
				mesa.estado = Mesa.Estado.LIBRE
				mesas_visuales[i].actualizar_vista(mesa)
				
	# 2. Paciencia del estudiante que encabeza la fila en la puerta (Cola FIFO)
	if not fila_entrada.esta_vacia():
		var primero_fila: Comensal = fila_entrada.primero()
		primero_fila.paciencia_actual -= delta * 0.6
		if not fila_visuales.is_empty():
			fila_visuales[0].actualizar_vista(primero_fila, true)
			
		if primero_fila.paciencia_actual <= 0:
			fila_entrada.desencolar()
			enojados += 1
			puntaje = max(0, puntaje - 30)
			puntaje_total = max(0, puntaje_total - 30)
			_reconstruir_fila_visual()
			
	_refrescar_hud()

func _perder_nivel() -> void:
	nivel_perdido = true
	timer_llegadas.stop()
	mesero.moviendose = false
	mesero.velocity = Vector2.ZERO
	btn_reintentar.visible = true
	_refrescar_hud()

func _on_reintentar_presionado() -> void:
	_cargar_nivel(nivel_actual)

func _on_nuevo_estudiante_llega() -> void:
	if nivel_perdido or juego_completado or fila_entrada.tamanio() >= MAX_FILA_ENTRADA:
		return
	var config: Dictionary = NIVELES_UNAL[nivel_actual]
	contador_estudiantes += 1
	var nombre: String = nombres_unal.pick_random() + " #" + str(contador_estudiantes)
	var prioridad := 0 if randf() < config["prob_vip"] else 1
	var nuevo := Comensal.new(contador_estudiantes, nombre, prioridad, config["paciencia"])
	
	fila_entrada.encolar(nuevo)
	_reconstruir_fila_visual()

func _reconstruir_fila_visual() -> void:
	for hijo in contenedor_fila.get_children():
		hijo.queue_free()
	fila_visuales.clear()
	
	var elementos: Array = fila_entrada.obtener_elementos()
	for i in range(elementos.size()):
		var c: Comensal = elementos[i]
		var tarjeta: ComensalVisual = ESCENA_COMENSAL.instantiate()
		contenedor_fila.add_child(tarjeta)
		tarjeta.fila_clickeada.connect(_on_clic_puerta)
		tarjeta.actualizar_vista(c, i == 0)
		fila_visuales.append(tarjeta)

# --- CLICS EN ZONAS DEL MAPA (BLOQUEADOS MIENTRAS SE ESCOLTA UN CLIENTE) ---

func _on_clic_puerta() -> void:
	if nivel_perdido or juego_completado or comensal_escoltado != null:
		return
	if plato_en_mano_mesa != null or not pila_loza_mano.esta_vacia():
		return
	var punto_puerta: Vector2 = $ZonaPuerta.global_position + Vector2(180, 95)
	mesero.ir_a(punto_puerta, {"tipo": "PUERTA"})

func _on_clic_cocina() -> void:
	if nivel_perdido or juego_completado or comensal_escoltado != null:
		return
	if plato_en_mano_mesa != null or not pila_loza_mano.esta_vacia():
		return
	var punto_cocina: Vector2 = $ZonaCocina.global_position + Vector2(-25, 65)
	mesero.ir_a(punto_cocina, {"tipo": "COCINA"})

func _on_clic_lavaplatos() -> void:
	if nivel_perdido or juego_completado or comensal_escoltado != null:
		return
	if pila_loza_mano.esta_vacia():
		return
	var punto_lavaplatos: Vector2 = $ZonaLavaplatos.global_position + Vector2(-25, 65)
	mesero.ir_a(punto_lavaplatos, {"tipo": "LAVAPLATOS"})

func _on_clic_mesa(mesa: Mesa, punto_atencion: Vector2) -> void:
	if nivel_perdido or juego_completado or comensal_escoltado != null:
		return
	mesero.ir_a(punto_atencion, {"tipo": "MESA", "mesa": mesa})

# --- EJECUCIÓN DE ACCIONES AL LLEGAR ---

func _on_mesero_llego_a_destino(accion: Dictionary) -> void:
	if nivel_perdido or juego_completado:
		return
	match accion["tipo"]:
		"PUERTA":
			_ejecutar_recibir_en_puerta()
		"COCINA":
			_ejecutar_tomar_pedido_cocina()
		"MESA":
			_ejecutar_interaccion_mesa(accion["mesa"])
		"ESCOLTAR":
			_ejecutar_sentar_en_mesa(accion["mesa"], accion["comensal"])
		"LAVAPLATOS":
			_ejecutar_lavar_loza()

func _ejecutar_recibir_en_puerta() -> void:
	if comensal_escoltado != null or fila_entrada.esta_vacia():
		return
		
	var mesa_elegida: Mesa = null
	for _intento in range(mesas_rr.tamanio()):
		var candidata: Mesa = mesas_rr.avanzar_round_robin()
		if candidata.estado == Mesa.Estado.LIBRE:
			mesa_elegida = candidata
			break
			
	if mesa_elegida == null:
		return
		
	var estudiante: Comensal = fila_entrada.desencolar()
	_reconstruir_fila_visual()
	
	comensal_escoltado = estudiante
	mesa_escolta_destino = mesa_elegida
	_actualizar_apariencia_mesero()
	
	var idx := mesas_datos.find(mesa_elegida)
	var vista := mesas_visuales[idx]
	var punto_mesa := vista.global_position + Vector2(vista.size.x * 0.5, vista.size.y + 28.0)
	
	mesero.ir_a(punto_mesa, {"tipo": "ESCOLTAR", "mesa": mesa_elegida, "comensal": estudiante})

func _ejecutar_sentar_en_mesa(mesa: Mesa, estudiante: Comensal) -> void:
	comensal_escoltado = null
	mesa_escolta_destino = null
	_actualizar_apariencia_mesero()
	
	if mesa.estado != Mesa.Estado.LIBRE:
		fila_entrada.encolar(estudiante)
		_reconstruir_fila_visual()
		return
		
	estudiante.paciencia_actual = estudiante.paciencia_max
	mesa.estado = Mesa.Estado.OCUPADA
	mesa.comensal_actual = estudiante
	pedidos_cocina.encolar(estudiante.prioridad, mesa)
	pila_undo.apilar({"accion": "SENTAR", "mesa": mesa, "comensal": estudiante})
	
	_actualizar_todas_las_mesas()

func _ejecutar_tomar_pedido_cocina() -> void:
	while not pedidos_cocina.esta_vacia():
		var mesa_prioritaria: Mesa = pedidos_cocina.desencolar()
		if mesa_prioritaria.estado == Mesa.Estado.OCUPADA:
			plato_en_mano_mesa = mesa_prioritaria
			sfx_tomar_plato.play()
			_actualizar_apariencia_mesero()
			_actualizar_todas_las_mesas()
			return

func _ejecutar_interaccion_mesa(mesa: Mesa) -> void:
	if plato_en_mano_mesa == mesa and mesa.estado == Mesa.Estado.OCUPADA:
		sfx_servir.play()
		var c: Comensal = mesa.comensal_actual
		var puntos_ganados := 150 if c.prioridad == 0 else 100
		puntaje += puntos_ganados
		puntaje_total += puntos_ganados
		atendidos += 1
		
		mesa.comensal_actual = null
		mesa.estado = Mesa.Estado.SUCIA
		pila_undo.apilar({"accion": "SERVIR", "mesa": mesa, "comensal": c, "puntos": puntos_ganados})
		
		plato_en_mano_mesa = null
		_actualizar_apariencia_mesero()
		_verificar_avance_nivel()
		_actualizar_todas_las_mesas()
		_refrescar_hud()
		return
		
	if mesa.estado == Mesa.Estado.SUCIA:
		if plato_en_mano_mesa != null or pila_loza_mano.tamanio() >= MAX_PLATOS_SUCIOS:
			return
			
		mesa.estado = Mesa.Estado.LIBRE
		pila_loza_mano.apilar(mesa)
		pila_undo.apilar({"accion": "RECOGER_LOZA", "mesa": mesa})
		_actualizar_apariencia_mesero()
		_actualizar_todas_las_mesas()

func _ejecutar_lavar_loza() -> void:
	if pila_loza_mano.esta_vacia():
		return
		
	var cantidad := pila_loza_mano.tamanio()
	var mesas_lavadas: Array[Mesa] = []
	
	while not pila_loza_mano.esta_vacia():
		mesas_lavadas.append(pila_loza_mano.desapilar())
		
	var puntos_lavado := cantidad * 25
	puntaje += puntos_lavado
	puntaje_total += puntos_lavado
	pila_undo.apilar({"accion": "LAVAR", "mesas": mesas_lavadas, "puntos": puntos_lavado})
	
	_actualizar_apariencia_mesero()
	_verificar_avance_nivel()
	_refrescar_hud()

func _actualizar_apariencia_mesero() -> void:
	if comensal_escoltado != null:
		mesero.cambiar_estado_visual(Mesero.EstadoVisual.LIBRE, "Con: " + comensal_escoltado.nombre)
	elif plato_en_mano_mesa != null:
		mesero.cambiar_estado_visual(Mesero.EstadoVisual.CON_COMIDA, "Plato -> Mesa #%d" % plato_en_mano_mesa.numero)
	elif pila_loza_mano.tamanio() == 1:
		mesero.cambiar_estado_visual(Mesero.EstadoVisual.SUCIOS_1, "Loza sucia (1/3)")
	elif pila_loza_mano.tamanio() == 2:
		mesero.cambiar_estado_visual(Mesero.EstadoVisual.SUCIOS_2, "Loza sucia (2/3)")
	elif pila_loza_mano.tamanio() >= 3:
		mesero.cambiar_estado_visual(Mesero.EstadoVisual.SUCIOS_3, "Loza sucia (3/3)")
	else:
		mesero.cambiar_estado_visual(Mesero.EstadoVisual.LIBRE, "Manos libres")

func _on_deshacer_presionado() -> void:
	if nivel_perdido or juego_completado or pila_undo.esta_vacia() or plato_en_mano_mesa != null or comensal_escoltado != null:
		return
	var ultimo: Dictionary = pila_undo.desapilar()
	
	match ultimo["accion"]:
		"SENTAR":
			var mesa: Mesa = ultimo["mesa"]
			if mesa.estado == Mesa.Estado.OCUPADA and mesa.comensal_actual == ultimo["comensal"]:
				mesa.comensal_actual = null
				mesa.estado = Mesa.Estado.LIBRE
				fila_entrada.encolar(ultimo["comensal"])
				_reconstruir_fila_visual()
		"SERVIR":
			var mesa: Mesa = ultimo["mesa"]
			if mesa.estado == Mesa.Estado.SUCIA:
				mesa.estado = Mesa.Estado.OCUPADA
				mesa.comensal_actual = ultimo["comensal"]
				puntaje = max(0, puntaje - ultimo["puntos"])
				puntaje_total = max(0, puntaje_total - ultimo["puntos"])
				atendidos = max(0, atendidos - 1)
				pedidos_cocina.encolar(ultimo["comensal"].prioridad, mesa)
		"RECOGER_LOZA":
			var mesa: Mesa = ultimo["mesa"]
			if not pila_loza_mano.esta_vacia() and pila_loza_mano.cima() == mesa:
				pila_loza_mano.desapilar()
				mesa.estado = Mesa.Estado.SUCIA
		"LAVAR":
			var mesas_lavadas: Array = ultimo["mesas"]
			for i in range(mesas_lavadas.size() - 1, -1, -1):
				if pila_loza_mano.tamanio() < MAX_PLATOS_SUCIOS:
					pila_loza_mano.apilar(mesas_lavadas[i])
			puntaje = max(0, puntaje - ultimo["puntos"])
			puntaje_total = max(0, puntaje_total - ultimo["puntos"])
			
	_actualizar_apariencia_mesero()
	_actualizar_todas_las_mesas()
	_refrescar_hud()

func _verificar_avance_nivel() -> void:
	var meta_actual: int = NIVELES_UNAL[nivel_actual]["meta"]
	if puntaje >= meta_actual:
		puntaje_inicio_nivel = puntaje_total
		if nivel_actual < NIVELES_UNAL.size() - 1:
			_cargar_nivel(nivel_actual + 1)
		else:
			timer_llegadas.stop()
			juego_completado = true

func _actualizar_todas_las_mesas() -> void:
	for i in range(mesas_datos.size()):
		var es_objetivo := (plato_en_mano_mesa == mesas_datos[i])
		mesas_visuales[i].actualizar_vista(mesas_datos[i], es_objetivo)

func _refrescar_hud() -> void:
	var config: Dictionary = NIVELES_UNAL[nivel_actual]
	var segundos := int(ceil(tiempo_restante))
	
	if juego_completado:
		label_estado.text = "¡GANASTE! Completaste los 5 comedores de la UNAL  |  Puntaje Total: %d pts  |  Atendidos: %d" % [
			puntaje_total, atendidos
		]
	elif nivel_perdido:
		label_estado.text = "¡TURNO CERRADO! Faltaron %d pts para la meta de %s" % [
			config["meta"] - puntaje, config["nombre"]
		]
	else:
		label_estado.text = "%s  |  Tiempo: %ds  |  Meta: %d / %d pts  |  Total: %d  |  Atendidos: %d" % [
			config["nombre"], segundos, puntaje, config["meta"], puntaje_total, atendidos
		]
