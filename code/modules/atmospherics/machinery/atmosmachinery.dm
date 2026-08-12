// Quick overview:
//
// Pipes combine to form pipelines
// Pipelines and other atmospheric objects combine to form pipe_networks
//   Note: A single pipe_network represents a completely open space
//
// Pipes -> Pipelines
// Pipelines + Other Objects -> Pipe network

#define PIPE_VISIBLE_LEVEL 2
#define PIPE_HIDDEN_LEVEL 1

/obj/machinery/atmospherics
	anchored = TRUE
	move_resist = INFINITY				//Moving a connected machine without actually doing the normal (dis)connection things will probably cause a LOT of issues.
	idle_power_usage = 0
	active_power_usage = 0
	power_channel = ENVIRON
	layer = GAS_PIPE_HIDDEN_LAYER //under wires
	plane = ABOVE_WALL_PLANE
	resistance_flags = FIRE_PROOF
	max_integrity = 200
	obj_flags = CAN_BE_HIT | ON_BLUEPRINTS
	var/nodealert = 0
	var/can_unwrench = 0
	var/initialize_directions = 0
	var/pipe_color
	var/piping_layer = PIPING_LAYER_DEFAULT
	var/pipe_flags = NONE

	var/static/list/iconsetids = list()
	var/static/list/pipeimages = list()

	var/image/pipe_vision_img = null

	var/device_type = 0
	var/list/obj/machinery/atmospherics/nodes

	var/construction_type
	var/pipe_state //icon_state as a pipe item
	var/on = FALSE

	///world.time until which this machine may skip full atmos processing (idle heartbeat for vents/scrubbers)
	var/atmos_idle_until = 0
	///consecutive SSair fires that did no work; drives atmos_idle_until
	var/atmos_idle_streak = 0
	///TRUE while this machine has an entry in one of SSair.atmos_idle_queues
	///(sleeping machines leave atmos_machinery entirely; the queue is their heartbeat)
	var/atmos_idle_queued = FALSE
	///Which backoff tier of SSair.atmos_idle_queues holds our entry, 1-based.
	///Each tier is FIFO only because every entry in it waits the SAME period, so
	///the tier has to be remembered rather than recomputed from the streak (the
	///streak keeps growing while we sleep).
	var/atmos_idle_tier = 0
	///the turf whose atmos_wake_machines list we are registered in
	var/turf/open/registered_wake_turf
	///TRUE, пока машина ждёт в SSair.pipenets_needing_rebuilt. Ставится и
	///снимается только самой очередью - флаг заменяет линейный поиск по списку
	///на каждое добавление (взрыв сыплет их сотнями за тик).
	var/rebuild_queued = FALSE

/obj/machinery/atmospherics/Initialize(mapload)
	. = ..()
	register_context()

/obj/machinery/atmospherics/examine(mob/user)
	. = ..()
	. += pipe_layer_examine()
	if(is_type_in_list(src, GLOB.ventcrawl_machinery) && isliving(user))
		var/mob/living/L = user
		if(SEND_SIGNAL(L, COMSIG_CHECK_VENTCRAWL))
			. += "<span class='notice'>Alt-click to crawl through it.</span>"

/// Five pipes can share a tile and only the paint tells you which of them will
/// ever meet, so examine has to spell out both. Layer manifolds sit on every
/// layer at once and colour adapters ignore paint, hence the flag branches.
/obj/machinery/atmospherics/proc/pipe_layer_examine()
	var/list/lines = list()
	if(pipe_flags & PIPING_ALL_LAYER)
		lines += "<span class='notice'>Соединяется со <b>всеми</b> слоями прокладки.</span>"
	else
		lines += "<span class='notice'>Слой прокладки: <b>[piping_layer]</b> из [PIPING_LAYER_MAX].</span>"
		if(pipe_flags & PIPING_INNER_LAYERS_ONLY)
			lines += "<span class='notice'>Широкая: встаёт только с [PIPING_LAYER_MIN + 1]-го по [PIPING_LAYER_MAX - 1]-й слой.</span>"
	if(pipe_flags & PIPING_ALL_COLORS)
		lines += "<span class='notice'>Стыкуется с трубами <b>любого</b> цвета.</span>"
	else if(IS_OMNI_PIPE_COLOR(pipe_color))
		lines += "<span class='notice'>Окраска серая - стыкуется с трубами любого цвета.</span>"
	else
		lines += "<span class='notice'>Окраска <b>[pipe_paint_color_name(pipe_color)]</b> - стыкуется только с такими же и с серыми.</span>"
	return lines

/// Turns a stored hex back into the paint name the RPD offers. Anything not on
/// the palette (custom varedits, admin spawns) falls back to the raw hex.
/proc/pipe_paint_color_name(hex)
	if(IS_OMNI_PIPE_COLOR(hex))
		return GLOB.pipe_paint_color_names["grey"]
	for(var/color_key in GLOB.pipe_paint_colors)
		if(lowertext(GLOB.pipe_paint_colors[color_key]) == lowertext(hex))
			return GLOB.pipe_paint_color_names[color_key] || color_key
	return hex

/obj/machinery/atmospherics/add_context(atom/source, list/context, obj/item/held_item, mob/living/user)
	. = ..()

	if(can_unwrench && held_item?.tool_behaviour == TOOL_WRENCH)
		LAZYSET(context[SCREENTIP_CONTEXT_LMB], INTENT_ANY, "Unfasten")
		. = CONTEXTUAL_SCREENTIP_SET

	if(is_type_in_list(src, GLOB.ventcrawl_machinery) && isliving(user) && SEND_SIGNAL(user, COMSIG_CHECK_VENTCRAWL))
		LAZYSET(context[SCREENTIP_CONTEXT_ALT_LMB], INTENT_ANY, "Crawl into")
		. = CONTEXTUAL_SCREENTIP_SET

/obj/machinery/atmospherics/New(loc, process = TRUE, setdir)
	if(!isnull(setdir))
		setDir(setdir)
	if(pipe_flags & PIPING_CARDINAL_AUTONORMALIZE)
		normalize_cardinal_directions()
	nodes = new(device_type)
	if (!armor)
		armor = list(MELEE = 25, BULLET = 10, LASER = 10, ENERGY = 100, BOMB = 0, BIO = 100, RAD = 100, FIRE = 100, ACID = 70)
	..()
	if(process)
		SSair.start_processing_machine(src)
	SetInitDirections()

/obj/machinery/atmospherics/Destroy()
	for(var/i in 1 to device_type)
		nullifyNode(i)
	// Break any residual reference cycles between connected atmos machines.
	nodes = null


	SSair.stop_processing_machine(src)
	SSair.dequeue_idle_machine(src)
	if(rebuild_queued)
		SSair.pipenets_needing_rebuilt -= src
		rebuild_queued = FALSE
	// Every idling machine registers itself in turf.atmos_wake_machines (a strong
	// ref); without this the turf pins the deleted machine forever.
	unregister_turf_wake()

	dropContents()
	if(pipe_vision_img)
		qdel(pipe_vision_img)

	return ..()
	//return QDEL_HINT_FINDREFERENCE

/// Instantly pulls an idle-heartbeat machine (vent/scrubber) back to full processing.
/obj/machinery/atmospherics/proc/atmos_wake()
	// Sleeping machines are out of atmos_machinery entirely; rejoin first.
	// The queued flag limits this to machines that left via their idle streak,
	// so a stray wake never adds things SSair does not process (plain pipes,
	// internal pumps of portables).
	if(atmos_idle_queued)
		if(!atmos_processing)
			SSair.start_processing_machine(src)
		// Запись из очереди снимается здесь, а не оставляется протухать.
		// Раньше протухшая запись была безобидна: периоды у всех совпадали, и
		// она лишь давала машине лишнюю раннюю проверку. С лестницей отката она
		// вредна - sleep_processing_machine выходит по этому же флагу первой
		// строкой, то есть машина, разбуженная событием и снова уснувшая,
		// осталась бы висеть на СТАРОЙ ступени со старым дедлайном. Снятие
		// стоит хеш-лукап и только для реально спавшей машины: у бодрствующей
		// флаг уже FALSE и dequeue выходит сразу.
		SSair.dequeue_idle_machine(src)
	atmos_idle_until = 0
	atmos_idle_streak = 0

/obj/machinery/atmospherics/power_change()
	..()
	// Power flips must instantly pull idle-heartbeat machines back to work.
	atmos_wake()

/// Counts a no-op processing pass; after ATMOS_MACHINE_IDLE_STREAK of those the
/// machine leaves the machinery list entirely and only rechecks on the idle
/// heartbeat (SSair.atmos_idle_queues) until an event wakes it. Каждое холостое
/// сердцебиение поднимает машину на ступень отката: период удваивается.
/obj/machinery/atmospherics/proc/atmos_consider_idle()
	atmos_idle_streak++
	if(atmos_idle_streak >= ATMOS_MACHINE_IDLE_STREAK)
		// Каждое сердцебиение, закончившееся ничем, поднимает машину на ступень
		// выше: сама ротация очереди - постоянная доля фазы машинерии, и платить
		// её в полном объёме за трубу, которая не шелохнулась час, незачем.
		// wake_expired_idle_machines НЕ трогает atmos_idle_streak, поэтому
		// счётчик честно копит холостые проверки поверх начальной серии, а любой
		// atmos_wake() сбрасывает его в ноль вместе со ступенью.
		var/tier = clamp(atmos_idle_streak - ATMOS_MACHINE_IDLE_STREAK, 0, ATMOS_MACHINE_IDLE_BACKOFF_STEPS)
		atmos_idle_until = world.time + ATMOS_MACHINE_IDLE_HEARTBEAT * (2 ** tier)
		// Re-registering on every idle transition self-heals lost registrations
		// (ChangeTurf under the machine replaces the turf and drops its list).
		register_turf_wake()
		// Only machines SSair is actually iterating may enter the wake queue:
		// internal pumps of portables call this too but are processed by their
		// holder, and must never be added to atmos_machinery by the heartbeat.
		if(atmos_processing)
			SSair.sleep_processing_machine(src, tier + 1)

/// Subscribes this machine to instant wake-ups when air changes on its turf
/// (air-changing SSair.add_to_active calls and breakdown write-backs clear the
/// idle state of everything registered here; activations that leave the air
/// untouched, like boundary pokes, skip the wake).
/// Idempotent; call again freely after the machine or its turf changed.
/obj/machinery/atmospherics/proc/register_turf_wake()
	var/turf/open/wake_turf = loc
	if(!istype(wake_turf))
		// Still drop any old registration so a stale ref never lingers.
		unregister_turf_wake()
		return
	if(registered_wake_turf != wake_turf)
		unregister_turf_wake()
	LAZYOR(wake_turf.atmos_wake_machines, src)
	registered_wake_turf = wake_turf

/obj/machinery/atmospherics/proc/unregister_turf_wake()
	var/turf/open/wake_turf = registered_wake_turf
	registered_wake_turf = null
	// ChangeTurf replaces the turf in place, retargeting our ref to the new
	// instance: a /turf/closed has no atmos_wake_machines (the list died with
	// the old turf), so there is nothing to remove ourselves from.
	if(!istype(wake_turf))
		return
	LAZYREMOVE(wake_turf.atmos_wake_machines, src)

/obj/machinery/atmospherics/proc/destroy_network()
	return

/obj/machinery/atmospherics/proc/build_network(blocking = FALSE)
	// Called to build a network from this node. With blocking unset the BFS
	// runs in SSair's rebuild phase and may span several fires; blocking is for
	// callers that need the net complete before they return (init, templates).
	return

/obj/machinery/atmospherics/proc/nullifyNode(i)
	if(nodes[i])
		var/obj/machinery/atmospherics/N = nodes[i]
		N.disconnect(src)
		nodes[i] = null

/obj/machinery/atmospherics/proc/getNodeConnects()
	var/list/node_connects = list()
	node_connects.len = device_type

	for(var/i in 1 to device_type)
		for(var/D in GLOB.cardinals)
			if(D & GetInitDirections())
				if(D in node_connects)
					continue
				node_connects[i] = D
				break
	return node_connects

/obj/machinery/atmospherics/proc/normalize_cardinal_directions()
	switch(dir)
		if(SOUTH)
			setDir(NORTH)
		if(WEST)
			setDir(EAST)

//this is called just after the air controller sets up turfs
/obj/machinery/atmospherics/proc/atmosinit(list/node_connects)
	if(!node_connects) //for pipes where order of nodes doesn't matter
		node_connects = getNodeConnects()

	for(var/i in 1 to device_type)
		for(var/obj/machinery/atmospherics/target in get_step(src,node_connects[i]))
			if(can_be_node(target, i))
				nodes[i] = target
				break
	update_icon()

/obj/machinery/atmospherics/proc/setPipingLayer(new_layer)
	piping_layer = clamp_piping_layer(pipe_flags, new_layer)
	update_icon()

/// Единая точка, где флаги слоя решают, на каком слое вещь вообще может стоять.
/// Живёт глобальным проком, потому что то же решение принимает и заготовка трубы
/// в руках, у которой нет ни pipe_flags, ни общего родителя с машиной.
/proc/clamp_piping_layer(flags, new_layer)
	if(flags & PIPING_DEFAULT_LAYER_ONLY)
		return PIPING_LAYER_DEFAULT
	if(flags & PIPING_INNER_LAYERS_ONLY)
		return clamp(new_layer, PIPING_LAYER_MIN + 1, PIPING_LAYER_MAX - 1)
	return new_layer

/obj/machinery/atmospherics/proc/can_be_node(obj/machinery/atmospherics/target, iteration)
	return connection_check(target, piping_layer)

//Find a connecting /obj/machinery/atmospherics in specified direction
// BLUEMOON CHANGE перенос проков с ново тг
/obj/machinery/atmospherics/proc/findConnecting(direction, prompted_layer)
	for(var/obj/machinery/atmospherics/target in get_step(src, direction))
		if(!(target.initialize_directions & get_dir(target,src)) && !istype(target, /obj/machinery/atmospherics/pipe/simple/multiz))
			continue
		if(connection_check(target, prompted_layer))
			return target

/obj/machinery/atmospherics/proc/connection_check(obj/machinery/atmospherics/target, given_layer)
	if(src == target)
		return FALSE
	//if target is not multiz then we have to check if the target & src connect in the same direction
	if(!istype(target, /obj/machinery/atmospherics/pipe/simple/multiz) && !((initialize_directions & get_dir(src, target)) && (target.initialize_directions & get_dir(target, src))))
		return FALSE

	// Both sides must agree on the connection (layer, flags, etc.)
	if(!isConnectable(target, given_layer) || !target.isConnectable(src, given_layer))
		return FALSE

	return TRUE
// BLUEMOON CHANGE END

/obj/machinery/atmospherics/proc/isConnectable(obj/machinery/atmospherics/target, given_layer)
	if(isnull(given_layer))
		given_layer = piping_layer
	if(target.loc == loc)
		return FALSE
	if((target.piping_layer != given_layer) && !(target.pipe_flags & PIPING_ALL_LAYER))
		return FALSE
	return colors_connectable(target)

/// Paint is a real boundary, not decoration: two differently painted pipes ignore
/// each other completely. Grey and unpainted stay universal, so the RPD default
/// and every uncoloured device still join whatever they are laid against, and
/// PIPING_ALL_COLORS opts a machine out of the rule from either side.
/obj/machinery/atmospherics/proc/colors_connectable(obj/machinery/atmospherics/target)
	// Matching paint is the overwhelmingly common case and covers both pipes
	// being unpainted, so it goes first and keeps the rebuild path cheap.
	if(pipe_color == target.pipe_color)
		return TRUE
	if((pipe_flags | target.pipe_flags) & PIPING_ALL_COLORS)
		return TRUE
	return IS_OMNI_PIPE_COLOR(pipe_color) || IS_OMNI_PIPE_COLOR(target.pipe_color)

/// Объясняет игроку, почему только что поставленная труба не сцепилась ни с чем.
///
/// Покраска стала настоящей границей, но отказа при установке она не даёт: труба
/// молча встаёт мёртвой, и разбираться приходится методом тыка. Раунд 9870,
/// атмосианин посреди работы: "что то с трубами меняли, Рирмах пока не
/// разбирался что".
///
/// Порог намеренно узкий - труба не подключилась ВООБЩЕ. Слой и цвет для того и
/// существуют, чтобы вести линии впритирку не соединяя их, так что ругаться на
/// каждого несоединившегося соседа значило бы спамить по делу работающему
/// инженеру. А вот труба, не сцепившаяся ни с одной стороной, - почти всегда
/// ошибка.
/obj/machinery/atmospherics/proc/warn_if_isolated_by_paint(mob/user)
	if(!user)
		return
	for(var/obj/machinery/atmospherics/node as anything in nodes)
		if(node)
			return
	var/obj/machinery/atmospherics/blocked_by
	for(var/direction in GLOB.cardinals)
		if(!(initialize_directions & direction))
			continue
		for(var/obj/machinery/atmospherics/target in get_step(src, direction))
			if(target == src || !(target.initialize_directions & get_dir(target, src)))
				continue
			// Слой сюда не попадает намеренно: он виден на спрайте сдвигом, и
			// параллельные линии на разных слоях - штатный приём, а не промах.
			if((target.piping_layer != piping_layer) && !((pipe_flags | target.pipe_flags) & PIPING_ALL_LAYER))
				continue
			if(!colors_connectable(target))
				blocked_by = target
				break
		if(blocked_by)
			break
	if(!blocked_by)
		return
	to_chat(user, span_warning("[capitalize(name)] не соединился с [blocked_by.name]: окраска <b>[pipe_paint_color_name(pipe_color)]</b> против <b>[pipe_paint_color_name(blocked_by.pipe_color)]</b>. Разного цвета трубы не стыкуются - перекрасьте одну из них или возьмите серую."))

/obj/machinery/atmospherics/proc/pipeline_expansion()
	return nodes

/obj/machinery/atmospherics/proc/SetInitDirections()
	return

/obj/machinery/atmospherics/proc/GetInitDirections()
	return initialize_directions

/obj/machinery/atmospherics/proc/returnPipenet()
	return

/**
 * Called by addMachineryMember() in datum_pipeline.dm, returns a list of gas_mixtures and assigns them into other_airs (by addMachineryMember) to allow pressure redistribution for the machineries.
 */
/obj/machinery/atmospherics/proc/returnPipenetAirs()
	return

/obj/machinery/atmospherics/proc/setPipenet()
	return

/obj/machinery/atmospherics/proc/replacePipenet()
	return

/obj/machinery/atmospherics/proc/disconnect(obj/machinery/atmospherics/reference)
	if(!nodes)
		return
	if(istype(reference, /obj/machinery/atmospherics/pipe))
		var/obj/machinery/atmospherics/pipe/P = reference
		P.destroy_network()
	var/node_index = nodes.Find(reference)
	if(node_index)
		nodes[node_index] = null
	update_icon()

/obj/machinery/atmospherics/attackby(obj/item/W, mob/user, params)
	if(istype(W, /obj/item/pipe)) //lets you autodrop
		var/obj/item/pipe/pipe = W
		if(user.dropItemToGround(pipe))
			pipe.setPipingLayer(piping_layer) //align it with us
			return TRUE
	else
		return ..()

/obj/machinery/atmospherics/wrench_act(mob/living/user, obj/item/I)
	if(!can_unwrench(user))
		return ..()

	var/turf/T = get_turf(src)
	if (level==1 && isturf(T) && T.intact)
		to_chat(user, "<span class='warning'>You must remove the plating first!</span>")
		return TRUE

	var/datum/gas_mixture/int_air = return_air()
	var/datum/gas_mixture/env_air = loc.return_air()
	add_fingerprint(user)

	var/unsafe_wrenching = FALSE
	var/internal_pressure = 0
	if(int_air && env_air)
		internal_pressure = int_air.return_pressure() - env_air.return_pressure()

	// Laying and pulling pipe is meant to be instant; the only thing still worth
	// waiting on is the gush of air, which exists purely so the warning below has
	// a window in which the player can still let go.
	var/wrench_delay = 0
	if (internal_pressure > 2*ONE_ATMOSPHERE)
		to_chat(user, "<span class='warning'>As you begin unwrenching \the [src] a gush of air blows in your face... maybe you should reconsider?</span>")
		unsafe_wrenching = TRUE //Oh dear oh dear
		wrench_delay = ATMOS_UNSAFE_WRENCH_DELAY

	if(I.use_tool(src, user, wrench_delay, volume=50))
		user.visible_message( \
			"[user] unfastens \the [src].", \
			"<span class='notice'>You unfasten \the [src].</span>", \
			"<span class='italics'>You hear ratchet.</span>")
		investigate_log("was <span class='warning'>REMOVED</span> by [key_name(usr)]", INVESTIGATE_ATMOS)

		//You unwrenched a pipe full of pressure? Let's splat you into the wall, silly.
		if(unsafe_wrenching)
			unsafe_pressure_release(user, internal_pressure)
		deconstruct(TRUE)
	return TRUE

/obj/machinery/atmospherics/proc/can_unwrench(mob/user)
	return can_unwrench

// Throws the user when they unwrench a pipe with a major difference between the internal and environmental pressure.
/obj/machinery/atmospherics/proc/unsafe_pressure_release(mob/user, pressures = null)
	if(!user)
		return
	if(!pressures)
		var/datum/gas_mixture/int_air = return_air()
		var/datum/gas_mixture/env_air = loc.return_air()
		if(int_air && env_air)
			pressures = int_air.return_pressure() - env_air.return_pressure()
		else
			pressures = 0

	user.visible_message("<span class='danger'>[user] is sent flying by pressure!</span>","<span class='userdanger'>The pressure sends you flying!</span>")

	// if get_dir(src, user) is not 0, target is the edge_target_turf on that dir
	// otherwise, edge_target_turf uses a random cardinal direction
	// range is pressures / 250
	// speed is pressures / 1250
	user.throw_at(get_edge_target_turf(user, get_dir(src, user) || pick(GLOB.cardinals)), pressures / 250, pressures / 1250)

/obj/machinery/atmospherics/deconstruct(disassembled = TRUE)
	if(!(flags_1 & NODECONSTRUCT_1))
		if(can_unwrench)
			var/obj/item/pipe/stored = new construction_type(loc, null, dir, src)
			stored.setPipingLayer(piping_layer)
			if(!disassembled)
				stored.obj_integrity = stored.max_integrity * 0.5
			transfer_fingerprints_to(stored)
	..()

/obj/machinery/atmospherics/proc/getpipeimage(iconset, iconstate, direction, col=rgb(255,255,255), piping_layer=PIPING_LAYER_DEFAULT)

	//Add identifiers for the iconset
	if(iconsetids[iconset] == null)
		iconsetids[iconset] = num2text(iconsetids.len + 1)

	//Generate a unique identifier for this image combination
	var/identifier = iconsetids[iconset] + "_[iconstate]_[direction]_[col]_[piping_layer]"

	if((!(. = pipeimages[identifier])))
		var/image/pipe_overlay
		pipe_overlay = . = pipeimages[identifier] = image(iconset, iconstate, dir = direction)
		pipe_overlay.color = col
		PIPING_LAYER_SHIFT(pipe_overlay, piping_layer)

/obj/machinery/atmospherics/on_construction(obj_color, set_layer, set_level)
	if(can_unwrench)
		add_atom_colour(obj_color, FIXED_COLOUR_PRIORITY)
		pipe_color = obj_color
	setPipingLayer(set_layer)
	var/turf/T = get_turf(src)
	if(set_level) level = set_level
	else level = T.intact ? 2 : 1
	atmosinit()
	var/list/nodes = pipeline_expansion()
	for(var/obj/machinery/atmospherics/A in nodes)
		A.atmosinit()
		A.addMember(src)
	build_network()

/obj/machinery/atmospherics/Entered(atom/movable/AM)
	if(istype(AM, /mob/living))
		var/mob/living/L = AM
		L.ventcrawl_layer = piping_layer
	return ..()

/obj/machinery/atmospherics/singularity_pull(S, current_size)
	if(current_size >= STAGE_FIVE)
		deconstruct(FALSE)
	return ..()

#define VENT_SOUND_DELAY 30

/obj/machinery/atmospherics/relaymove(mob/living/user, direction)
	direction &= initialize_directions
	if(!direction || !(direction in GLOB.cardinals)) //cant go this way.
		return

	if(user in buckled_mobs)// fixes buckle ventcrawl edgecase fuck bug
		return

	var/obj/machinery/atmospherics/components/unary/vent_found
	var/obj/machinery/atmospherics/target_move = findConnecting(direction, user.ventcrawl_layer)
	if(target_move)
		if(target_move.can_crawl_through())
			if(is_type_in_typecache(target_move, GLOB.ventcrawl_machinery))
				user.visible_message("<span class='notice'>Что-то вылезает из вентиляции...</span>", "<span class='notice'>Ты вылезаешь из вентиляции.")
				if(!do_after(user, 2 SECONDS, target = vent_found))
					return
				user.forceMove(target_move.loc) //handle entering and so on.

			else
				var/list/pipenetdiff = returnPipenets() ^ target_move.returnPipenets()
				if(pipenetdiff.len)
					user.update_pipe_vision(target_move)
				user.forceMove(target_move)
				user.client.eye = target_move  //Byond only updates the eye every tick, This smooths out the movement
				if(world.time - user.last_played_vent > VENT_SOUND_DELAY)
					user.last_played_vent = world.time
					playsound(src, 'sound/machines/ventcrawl.ogg', 50, 1, -3)
	else if(is_type_in_typecache(src, GLOB.ventcrawl_machinery) && can_crawl_through()) //if we move in a way the pipe can connect, but doesn't - or we're in a vent
		user.visible_message("<span class='notice'>Что-то вылезает из вентиляции...</span>", "<span class='notice'>Ты вылезаешь из вентиляции.")
		if(!do_after(user, 2 SECONDS, target = vent_found))
			return
		user.forceMove(target_move.loc) //handle entering and so on.

/obj/machinery/atmospherics/AltClick(mob/living/L)
	if(is_type_in_typecache(src, GLOB.ventcrawl_machinery))
		return SEND_SIGNAL(L, COMSIG_HANDLE_VENTCRAWL, src)
	return ..()

/obj/machinery/atmospherics/proc/can_crawl_through()
	return TRUE

/obj/machinery/atmospherics/proc/returnPipenets()
	return list()

/obj/machinery/atmospherics/update_remote_sight(mob/user)
	user.sight |= (SEE_TURFS|BLIND)

//Used for certain children of obj/machinery/atmospherics to not show pipe vision when mob is inside it.
/obj/machinery/atmospherics/proc/can_see_pipes()
	return TRUE

/obj/machinery/atmospherics/proc/update_layer()
	layer = (level == PIPE_VISIBLE_LEVEL ? GAS_PIPE_VISIBLE_LAYER : GAS_PIPE_HIDDEN_LAYER) + (piping_layer - PIPING_LAYER_DEFAULT) * PIPING_LAYER_LCHANGE
