/obj/machinery/atmospherics/pipe
	var/datum/gas_mixture/air_temporary //used when reconstructing a pipeline that broke
	var/volume = 0

	/// Рабочее давление. Выше него сеть, в которой лежит труба, копит усталость.
	var/pressure_rating = PIPE_PRESSURE_RATING_STANDARD
	/// Просвет секции на узел: усиленная стенка съедает объём.
	var/volume_per_node = PIPE_VOLUME_PER_NODE_STANDARD
	/// PIPE_DAMAGE_INTACT / LEAK / RUPTURE. Лечится сваркой.
	var/damage_stage = PIPE_DAMAGE_INTACT

	level = 1

	use_power = NO_POWER_USE
	can_unwrench = 1
	///FALSE on the pipes that join every colour by design, where paint would mean nothing.
	var/paintable = TRUE
	var/datum/pipeline/parent = null

	//Buckling
	can_buckle = 1
	buckle_requires_restraints = 1
	buckle_lying = -1

/obj/machinery/atmospherics/pipe/New()
	add_atom_colour(pipe_color, FIXED_COLOUR_PRIORITY)
	volume = volume_per_node * device_type
	..()

/obj/machinery/atmospherics/pipe/nullifyNode(i)
	var/obj/machinery/atmospherics/oldN = nodes[i]
	..()
	if(oldN)
		SSair.add_to_rebuild_queue(oldN)

/obj/machinery/atmospherics/pipe/destroy_network()
	QDEL_NULL(parent)

/obj/machinery/atmospherics/pipe/proc/prune_stale_pipeline_memberships(datum/pipeline/skip_pipeline = null)
	var/list/seen_pipelines = list()
	for(var/list/source as anything in list(SSair.networks, SSair.currentrun))
		if(!islist(source))
			continue
		for(var/thing as anything in source)
			if(!istype(thing, /datum/pipeline))
				continue
			var/datum/pipeline/P = thing
			if(P in seen_pipelines)
				continue
			seen_pipelines += P
			if(P == skip_pipeline)
				continue
			if(src in P.members)
				P.members -= src
				P.mark_dirty()

/obj/machinery/atmospherics/pipe/build_network()
	if(QDELETED(src))
		return // Pipe was destroyed, don't rebuild
	if(QDELETED(parent))
		if(parent && QDESTROYING(parent))
			investigate_log("[type] at [COORD(src)] rebuilding network while parent pipeline is being destroyed", INVESTIGATE_ATMOS)
		parent = new
		parent.build_pipeline(src)

/obj/machinery/atmospherics/pipe/atmosinit()
	var/turf/T = loc			// hide if turf is not intact
	hide(T.intact)
	..()

/obj/machinery/atmospherics/pipe/hide(i)
	if(level == 1 && isturf(loc))
		invisibility = i ? INVISIBILITY_MAXIMUM : 0
	update_icon()

/obj/machinery/atmospherics/pipe/proc/releaseAirToTurf()
	if(air_temporary)
		var/turf/T = loc
		if(!isturf(T))
			return
		T.assume_air(air_temporary)
		air_update_turf()

/obj/machinery/atmospherics/pipe/return_air()
	return parent?.air

/obj/machinery/atmospherics/pipe/return_analyzable_air()
	if(air_temporary)
		return air_temporary
	return parent?.air

/obj/machinery/atmospherics/pipe/remove_air(amount)
	return parent?.air?.remove(amount)

/obj/machinery/atmospherics/pipe/remove_air_ratio(ratio)
	return parent?.air?.remove_ratio(ratio)

/obj/machinery/atmospherics/pipe/attackby(obj/item/W, mob/user, params)
	if(istype(W, /obj/item/pipe_meter))
		var/obj/item/pipe_meter/meter = W
		user.dropItemToGround(meter)
		meter.setAttachLayer(piping_layer)
	else
		return ..()

/obj/machinery/atmospherics/pipe/analyzer_act(mob/living/user, obj/item/I)
	if(!parent?.air)
		to_chat(user, "<span class='warning'>[src] is not connected to a pipenet.</span>")
		return FALSE
	atmosanalyzer_scan(parent.air, user, src)
	for(var/line in pressure_report())
		to_chat(user, line)
	return TRUE

/obj/machinery/atmospherics/pipe/examine(mob/user)
	. = ..()
	. += pressure_report()

/// Единый отчёт о давлении: его показывают осмотр, анализатор и метр, чтобы три
/// поверхности не разъехались в формулировках и числах. Игрок обязан узнавать
/// правила отсюда, а не перебором.
/obj/machinery/atmospherics/pipe/proc/pressure_report()
	. = list("<span class='notice'>Рабочее давление: [pressure_rating] кПа.</span>")
	if(!parent?.air)
		return
	var/pressure = parent.air.return_pressure()
	var/rating = parent.min_rating
	if(rating <= 0)
		return
	var/percent = round(pressure / rating * 100)
	var/verdict = "в норме"
	if(percent >= PIPE_STRESS_RUPTURE_RATIO * 100)
		verdict = "перегружена"
	else if(percent >= 100)
		verdict = "у предела"
	. += "<span class='notice'>Давление в линии: [round(pressure)] кПа ([percent]% номинала), [verdict].</span>"
	// Без этой строки владелец усиленной трубы не поймёт, почему она рвётся:
	// сеть держит столько, сколько держит её слабейшее звено.
	if(rating < pressure_rating)
		. += "<span class='warning'>Слабое звено линии держит только [rating] кПа - по нему линия и порвётся.</span>"
	if(parent.fatigue > PIPE_FATIGUE_MAX * 0.5)
		. += "<span class='warning'>Стенки в испарине, металл отзывается гулом.</span>"
	switch(damage_stage)
		if(PIPE_DAMAGE_LEAK)
			. += "<span class='warning'>Свищ на стыке травит газ. Заварить.</span>"
		if(PIPE_DAMAGE_RUPTURE)
			. += "<span class='warning'>Стык разошёлся. Заварить.</span>"

/obj/machinery/atmospherics/pipe/welder_act(mob/living/user, obj/item/I)
	if(!damage_stage)
		return
	if(!I.tool_start_check(user, amount=0))
		return TRUE
	// Труба под плиткой сварке недоступна: сначала вскрыть пол. Координаты не
	// выдаются нигде - искать по шипению и пару.
	if(invisibility)
		to_chat(user, "<span class='warning'>Сначала вскройте пол над [src].</span>")
		return TRUE
	to_chat(user, "<span class='notice'>Вы начинаете заваривать [src]...</span>")
	if(!I.use_tool(src, user, damage_stage == PIPE_DAMAGE_RUPTURE ? 60 : 30, volume = 50))
		return TRUE
	user.visible_message(
		"[user] заваривает [src].",
		"<span class='notice'>Вы завариваете [src].</span>",
		"<span class='italics'>Вы слышите сварку.</span>")
	finish_pressure_repair()
	return TRUE

/obj/machinery/atmospherics/pipe/returnPipenet()
	return parent

/obj/machinery/atmospherics/pipe/setPipenet(datum/pipeline/P)
	parent = P

/obj/machinery/atmospherics/pipe/zap_act(power, zap_flags)
	return FALSE // they're not really machines in the normal sense, probably shouldn't explode

/obj/machinery/atmospherics/pipe/Destroy()
	prune_stale_pipeline_memberships(parent)
	QDEL_NULL(parent)

	releaseAirToTurf()
	QDEL_NULL(air_temporary)

	var/turf/T = loc
	for(var/obj/machinery/meter/meter in T)
		if(meter.target == src)
			var/obj/item/pipe_meter/PM = new (T)
			meter.transfer_fingerprints_to(PM)
			qdel(meter)
	. = ..()

/obj/machinery/atmospherics/pipe/update_icon()
	. = ..()
	update_alpha()

/// Общий хвост всех путей отрисовки трубы. Каждое из одиннадцати
/// переопределений update_icon() заканчивается вызовом отсюда - половина из них
/// при этом делает cut_overlays() и не зовёт родителя, так что это
/// единственное место, откуда маркер повреждения ложится на любой тип трубы и
/// переживает любую перерисовку.
/obj/machinery/atmospherics/pipe/proc/update_alpha()
	alpha = invisibility ? 64 : 255
	if(!damage_stage)
		return
	// Маркер кладётся в центр тайла и потому не зависит от dir: через центр
	// проходят все восемь направлений трубы, так что один стейт закрывает весь
	// набор вместо восьми.
	var/mutable_appearance/breach = mutable_appearance(
		'icons/obj/atmospherics/pipes/pipe_damage.dmi',
		damage_stage == PIPE_DAMAGE_RUPTURE ? "breach_rupture" : "breach_leak")
	// Труба красится через add_atom_colour, и это умножение накрыло бы маркер
	// вместе с ней: на синей магистрали свищ стал бы синим и перестал читаться.
	breach.appearance_flags |= RESET_COLOR
	add_overlay(breach)

/obj/machinery/atmospherics/pipe/proc/update_node_icon()
	for(var/i in 1 to device_type)
		if(nodes[i])
			var/obj/machinery/atmospherics/N = nodes[i]
			N.update_icon()

/obj/machinery/atmospherics/pipe/returnPipenets()
	. = list(parent)

/obj/machinery/atmospherics/pipe/run_obj_armor(damage_amount, damage_type, damage_flag = 0, attack_dir)
	if(damage_flag == MELEE && damage_amount < 12)
		return FALSE
	. = ..()

/obj/machinery/atmospherics/pipe/proc/paint(paint_color)
	if(!paintable)
		return FALSE
	if(pipe_color == paint_color)
		return TRUE
	add_atom_colour(paint_color, FIXED_COLOUR_PRIORITY)
	pipe_color = paint_color
	// Paint decides who this pipe is allowed to touch, so a repaint has to cut
	// the connections it no longer qualifies for and look for the ones it just
	// gained. Without this a pipe keeps feeding a network it can no longer
	// reach, right up until something unrelated rebuilds the pipenet.
	reconnect_nodes()
	update_node_icon()
	return TRUE

/// Drops every node this pipe currently holds and runs the search again, the
/// same way construction does. Used when something that decides connections -
/// paint, for now - changes on an already placed pipe.
/obj/machinery/atmospherics/pipe/proc/reconnect_nodes()
	for(var/i in 1 to device_type)
		nullifyNode(i)
	destroy_network()
	if(!SSair.initialized)
		return
	atmosinit()
	for(var/obj/machinery/atmospherics/neighbour in pipeline_expansion())
		neighbour.atmosinit()
		neighbour.addMember(src)
	build_network()

/obj/machinery/atmospherics/pipe/attack_ghost(mob/dead/observer/O)
	. = ..()
	if(parent?.air)
		atmosanalyzer_scan(parent.air, O, src, FALSE)
	else
		to_chat(O, "<span class='warning'>[src] doesn't have a pipenet, which is probably a bug.</span>")
