/obj/machinery/atmospherics/pipe/layer_manifold
	name = "layer adaptor"
	icon = 'icons/obj/atmospherics/pipes/manifold.dmi'
	icon_state = "manifoldlayer"
	desc = "A special pipe to bridge pipe layers with."
	dir = SOUTH
	initialize_directions = NORTH|SOUTH
	pipe_flags = PIPING_ALL_LAYER | PIPING_DEFAULT_LAYER_ONLY | PIPING_CARDINAL_AUTONORMALIZE
	piping_layer = PIPING_LAYER_DEFAULT
	device_type = 0
	volume = 260
	construction_type = /obj/item/pipe/binary
	pipe_state = "manifoldlayer"
	paintable = FALSE
	var/list/front_nodes
	var/list/back_nodes

/obj/machinery/atmospherics/pipe/layer_manifold/Initialize(mapload)
	// Один слот на слой с самого начала: update_icon() зовут раньше, чем
	// findAllConnections(), и по пустому списку он бы упал на индексе.
	front_nodes = new /list(PIPING_LAYER_MAX)
	back_nodes = new /list(PIPING_LAYER_MAX)
	icon_state = "manifoldlayer_center"
	return ..()

/obj/machinery/atmospherics/pipe/layer_manifold/Destroy()
	nullifyAllNodes()
	return ..()

/obj/machinery/atmospherics/pipe/layer_manifold/proc/nullifyAllNodes()
	var/list/obj/machinery/atmospherics/needs_nullifying = get_all_connected_nodes()
	front_nodes = null
	back_nodes = null
	nodes = list()
	for(var/obj/machinery/atmospherics/A in needs_nullifying)
		A.disconnect(src)
		SSair.add_to_rebuild_queue(A)

/obj/machinery/atmospherics/pipe/layer_manifold/proc/get_all_connected_nodes()
	return front_nodes + back_nodes + nodes

/obj/machinery/atmospherics/pipe/layer_manifold/update_icon()
	cut_overlays()
	layer = initial(layer) + (PIPING_LAYER_MAX * PIPING_LAYER_LCHANGE)	//This is above everything else.

	// Слот знает свой слой, сосед - только свой цвет. Раньше слой брали у соседа,
	// а у соседнего адаптера собственного слоя нет: он сидит во всех слотах
	// сразу, и стык двух адаптеров рисовал одну трубу вместо пяти.
	// nullifyAllNodes() обнуляет оба списка перед смертью, а disconnect() соседа
	// может докатиться сюда уже после.
	for(var/piping in PIPING_LAYER_MIN to PIPING_LAYER_MAX)
		if(piping <= length(front_nodes))
			add_attached_image(front_nodes[piping], piping)
		if(piping <= length(back_nodes))
			add_attached_image(back_nodes[piping], piping)

	update_alpha()

/obj/machinery/atmospherics/pipe/layer_manifold/proc/add_attached_image(obj/machinery/atmospherics/neighbour, piping)
	if(!neighbour)
		return
	// Слой входит в ключ кэша getpipeimage(), так что у каждого слоя свой образ
	// со своим смещением. Раньше все патрубки брали один кэшированный образ и по
	// очереди переписывали ему pixel_x - чужой кэш уезжал следом.
	var/image/attached
	if(neighbour.pipe_color)
		attached = getpipeimage(icon, "pipe", get_dir(src, neighbour), neighbour.pipe_color, piping)
	else
		attached = getpipeimage(icon, "pipe", get_dir(src, neighbour), piping_layer = piping)

	attached.layer = layer - 0.01
	add_overlay(attached)

/obj/machinery/atmospherics/pipe/layer_manifold/SetInitDirections()
	switch(dir)
		if(NORTH, SOUTH)
			initialize_directions = NORTH|SOUTH
		if(EAST, WEST)
			initialize_directions = EAST|WEST

/obj/machinery/atmospherics/pipe/layer_manifold/isConnectable(obj/machinery/atmospherics/target, given_layer)
	if(!given_layer)
		return TRUE
	. = ..()

/obj/machinery/atmospherics/pipe/layer_manifold/proc/findAllConnections()
	// Слот с номером слоя, а не "сколько нашлось": у промаха обязан остаться
	// пустой слот, иначе update_icon() и disconnect() считают слои по позиции в
	// списке и уезжают на один вниз с первого же несоединённого слоя.
	front_nodes = new /list(PIPING_LAYER_MAX)
	back_nodes = new /list(PIPING_LAYER_MAX)
	var/list/new_nodes = list()
	for(var/piping in PIPING_LAYER_MIN to PIPING_LAYER_MAX)
		var/obj/machinery/atmospherics/found_front = findConnecting(dir, piping)
		var/obj/machinery/atmospherics/found_back = findConnecting(turn(dir, 180), piping)
		front_nodes[piping] = found_front
		back_nodes[piping] = found_back
		if(found_front && !QDELETED(found_front))
			new_nodes += found_front
		if(found_back && !QDELETED(found_back))
			new_nodes += found_back
	update_icon()
	return new_nodes

/obj/machinery/atmospherics/pipe/layer_manifold/atmosinit()
	normalize_cardinal_directions()
	findAllConnections()
	var/turf/T = loc			// hide if turf is not intact
	hide(T.intact)

/obj/machinery/atmospherics/pipe/layer_manifold/setPipingLayer()
	piping_layer = PIPING_LAYER_DEFAULT

/obj/machinery/atmospherics/pipe/layer_manifold/pipeline_expansion()
	return get_all_connected_nodes()

/obj/machinery/atmospherics/pipe/layer_manifold/disconnect(obj/machinery/atmospherics/reference)
	if(istype(reference, /obj/machinery/atmospherics/pipe))
		var/obj/machinery/atmospherics/pipe/P = reference
		P.destroy_network()
	while(reference in get_all_connected_nodes())
		if(reference in nodes)
			var/i = nodes.Find(reference)
			nodes[i] = null
		if(reference in front_nodes)
			var/i = front_nodes.Find(reference)
			front_nodes[i] = null
		if(reference in back_nodes)
			var/i = back_nodes.Find(reference)
			back_nodes[i] = null
	update_icon()

/obj/machinery/atmospherics/pipe/layer_manifold/relaymove(mob/living/user, dir)
	if(initialize_directions & dir)
		return ..()
	if((NORTH|EAST) & dir)
		user.ventcrawl_layer = clamp(user.ventcrawl_layer + 1, PIPING_LAYER_MIN, PIPING_LAYER_MAX)
	if((SOUTH|WEST) & dir)
		user.ventcrawl_layer = clamp(user.ventcrawl_layer - 1, PIPING_LAYER_MIN, PIPING_LAYER_MAX)
	// Слоёв стало пять, так что "какой-то там выход" больше не ориентир: внутри
	// адаптера видно только номер, на который ты перестроился.
	to_chat(user, span_notice("Ты перестраиваешься на [user.ventcrawl_layer]-й слой из [PIPING_LAYER_MAX]."))
