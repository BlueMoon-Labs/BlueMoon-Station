#define TRAM_JUNCTION_NORTHEAST (1<<4)
#define TRAM_JUNCTION_SOUTHEAST (1<<5)
#define TRAM_JUNCTION_SOUTHWEST (1<<6)
#define TRAM_JUNCTION_NORTHWEST (1<<7)

/obj/structure/tram
	name = "tram wall"
	desc = "Лёгкая конструкция из титанового композита с панелями из титанового силиката."
	icon = 'modular_bluemoon/icons/obj/tram/tram_structure.dmi'
	icon_state = "tram-part-0"
	base_icon_state = "tram-part"
	max_integrity = 150
	layer = TRAM_WALL_LAYER
	density = TRUE
	opacity = FALSE
	anchored = TRUE
	flags_1 = PREVENT_CLICK_UNDER_1
	pass_flags_self = PASSGLASS
	armor = list(MELEE = 40, BULLET = 10, LASER = 10, ENERGY = 0, BOMB = 45, BIO = 0, RAD = 0, FIRE = 90, ACID = 100)
	CanAtmosPass = ATMOS_PASS_DENSITY
	explosion_block = 3
	ricochet_chance_mod = 1.2
	rad_insulation = RAD_MEDIUM_INSULATION
	/// What state of de/construction it's in
	var/state = TRAM_SCREWED_TO_FRAME
	/// Mineral to return when deconstructed
	var/mineral = /obj/item/stack/sheet/titaniumglass
	/// Amount of mineral to return when deconstructed
	var/mineral_amount = 2
	/// Type of girder made when deconstructed
	var/girder_type = /obj/structure/girder/tram
	/// Whether this piece joins its neighbours into one smoothed wall
	var/smooths = TRUE
	/// Junction directions this piece has icon states for
	var/allowed_junctions = ALL
	var/mutable_appearance/damage_overlay
	/// Sound when hit without combat mode
	var/knock_sound = 'sound/effects/glassknock.ogg'
	/// Sound when hit with combat mode
	var/bash_sound = 'sound/effects/Glasshit.ogg'

/obj/structure/tram/split
	base_icon_state = "tram-split"
	allowed_junctions = EAST|WEST

/obj/structure/tram/Initialize(mapload)
	. = ..()
	var/obj/item/stack/initialized_mineral = new mineral
	set_custom_materials(initialized_mineral.mats_per_unit, mineral_amount)
	qdel(initialized_mineral)
	air_update_turf(TRUE)
	register_context()
	if(!smooths)
		return
	if(mapload)
		return INITIALIZE_HINT_LATELOAD
	smooth_with_neighbours()

/obj/structure/tram/LateInitialize()
	. = ..()
	update_tram_junction()

/obj/structure/tram/Destroy()
	var/list/neighbours = smooths ? get_tram_neighbours() : null
	. = ..()
	for(var/obj/structure/tram/neighbour as anything in neighbours)
		neighbour.update_tram_junction()

/// Whether this piece of tram counts as part of a continuous wall for smoothing
/obj/structure/tram/proc/joins_tram_wall()
	return smooths && !QDELETED(src)

/obj/structure/tram/proc/get_tram_neighbours()
	. = list()
	for(var/direction in GLOB.alldirs)
		for(var/obj/structure/tram/neighbour in get_step(src, direction))
			if(neighbour != src && neighbour.joins_tram_wall())
				. += neighbour

/obj/structure/tram/proc/has_tram_neighbour(direction)
	for(var/obj/structure/tram/neighbour in get_step(src, direction))
		if(neighbour != src && neighbour.joins_tram_wall())
			return TRUE
	return FALSE

/obj/structure/tram/proc/smooth_with_neighbours()
	update_tram_junction()
	for(var/obj/structure/tram/neighbour as anything in get_tram_neighbours())
		neighbour.update_tram_junction()

/// Picks the bitmask icon state from the surrounding tram pieces. The whole tram moves at once, so this only changes on construction.
/obj/structure/tram/proc/update_tram_junction()
	if(!smooths || QDELETED(src))
		return
	var/junction = NONE
	for(var/direction in GLOB.cardinals)
		if(has_tram_neighbour(direction))
			junction |= direction
	junction &= allowed_junctions
	if((junction & NORTH) && (junction & EAST) && has_tram_neighbour(NORTHEAST))
		junction |= TRAM_JUNCTION_NORTHEAST
	if((junction & SOUTH) && (junction & EAST) && has_tram_neighbour(SOUTHEAST))
		junction |= TRAM_JUNCTION_SOUTHEAST
	if((junction & SOUTH) && (junction & WEST) && has_tram_neighbour(SOUTHWEST))
		junction |= TRAM_JUNCTION_SOUTHWEST
	if((junction & NORTH) && (junction & WEST) && has_tram_neighbour(NORTHWEST))
		junction |= TRAM_JUNCTION_NORTHWEST
	icon_state = "[base_icon_state]-[junction]"

/obj/structure/tram/examine(mob/user)
	. = ..()
	switch(state)
		if(TRAM_SCREWED_TO_FRAME)
			. += span_notice("Панель [EXAMINE_HINT("прикручена")] к раме. Чтобы разобрать, нужна [EXAMINE_HINT("отвёртка")].")
		if(TRAM_IN_FRAME)
			. += span_notice("Панель [EXAMINE_HINT("откручена")], но всё ещё [EXAMINE_HINT("вставлена")] в раму. Дальше нужен [EXAMINE_HINT("лом")].")
		if(TRAM_OUT_OF_FRAME)
			. += span_notice("Панель [EXAMINE_HINT("вынута")] из рамы, но всё ещё держится на [EXAMINE_HINT("проводах")]. Их перекусывают [EXAMINE_HINT("кусачками")].")

/obj/structure/tram/add_context(atom/source, list/context, obj/item/held_item, mob/living/user)
	if(held_item?.tool_behaviour == TOOL_WELDER && obj_integrity < max_integrity)
		context[SCREENTIP_CONTEXT_LMB] = "Починить"
	if(held_item?.tool_behaviour == TOOL_SCREWDRIVER && state != TRAM_OUT_OF_FRAME)
		context[SCREENTIP_CONTEXT_LMB] = state == TRAM_SCREWED_TO_FRAME ? "Открутить панель" : "Прикрутить панель"
	if(held_item?.tool_behaviour == TOOL_CROWBAR && state != TRAM_SCREWED_TO_FRAME)
		context[SCREENTIP_CONTEXT_LMB] = state == TRAM_IN_FRAME ? "Вынуть панель" : "Вставить панель"
	if(held_item?.tool_behaviour == TOOL_WIRECUTTER && state == TRAM_OUT_OF_FRAME)
		context[SCREENTIP_CONTEXT_LMB] = "Отсоединить панель"

	return CONTEXTUAL_SCREENTIP_SET

/obj/structure/tram/update_overlays()
	. = ..()
	var/ratio = obj_integrity / max_integrity
	ratio = CEILING(ratio * 4, 1) * 25
	if(ratio > 75)
		return

	damage_overlay = mutable_appearance('icons/obj/structures.dmi', "damage[ratio]", -(layer + 0.1))
	. += damage_overlay

/obj/structure/tram/on_attack_hand(mob/user, act_intent = user?.a_intent, unarmed_attack_flags)
	. = ..()
	if(.)
		return

	if(act_intent != INTENT_HARM)
		user.visible_message(span_notice("[user] стучит по [src]."), \
			span_notice("Вы стучите по [src]."))
		playsound(src, knock_sound, 50, TRUE)
	else
		user.visible_message(span_warning("[user] колотит по [src]!"), \
			span_warning("Вы колотите по [src]!"))
		playsound(src, bash_sound, 100, TRUE)

/obj/structure/tram/rcd_vals(mob/user, obj/item/construction/rcd/the_rcd)
	if(the_rcd.mode == RCD_DECONSTRUCT)
		return list("mode" = RCD_DECONSTRUCT, "delay" = 3 SECONDS, "cost" = 10)
	return FALSE

/obj/structure/tram/rcd_act(mob/user, obj/item/construction/rcd/the_rcd, passed_mode)
	if(passed_mode == RCD_DECONSTRUCT)
		qdel(src)
		return TRUE
	return FALSE

/obj/structure/tram/take_damage(damage_amount, damage_type = BRUTE, damage_flag = 0, sound_effect = 1, attack_dir, armour_penetration = 0)
	. = ..()
	if(.)
		update_appearance()

/obj/structure/tram/narsie_act()
	add_atom_colour(NARSIE_WINDOW_COLOUR, FIXED_COLOUR_PRIORITY)

/obj/structure/tram/singularity_pull(S, current_size)
	..()
	if(current_size >= STAGE_FIVE)
		deconstruct(disassembled = FALSE)

/obj/structure/tram/welder_act(mob/living/user, obj/item/tool)
	if(obj_integrity >= max_integrity)
		to_chat(user, span_warning("[capitalize(src.name)] и так в порядке!"))
		return TRUE
	if(!tool.tool_start_check(user, amount = 0))
		return TRUE
	to_chat(user, span_notice("Вы начинаете чинить [src]..."))
	if(tool.use_tool(src, user, 4 SECONDS, volume = 50))
		obj_integrity = max_integrity
		to_chat(user, span_notice("Вы чините [src]."))
		update_appearance()
	return TRUE

/obj/structure/tram/screwdriver_act(mob/living/user, obj/item/tool)
	switch(state)
		if(TRAM_SCREWED_TO_FRAME)
			user.visible_message(span_notice("[user] начинает откручивать панель трамвая от рамы..."),
				span_notice("Вы начинаете откручивать панель трамвая от рамы..."))
			if(!tool.use_tool(src, user, 1 SECONDS, volume = 50) || state != TRAM_SCREWED_TO_FRAME)
				return TRUE
			state = TRAM_IN_FRAME
			to_chat(user, span_notice("Винты выкручены, вокруг панели появился зазор."))
			return TRUE

		if(TRAM_IN_FRAME)
			user.visible_message(span_notice("[user] прикручивает панель трамвая обратно к раме..."),
				span_notice("Вы прикручиваете панель трамвая обратно к раме."))
			state = TRAM_SCREWED_TO_FRAME
			return TRUE

	to_chat(user, span_warning("Сначала нужно перекусить провода!"))
	return TRUE

/obj/structure/tram/crowbar_act(mob/living/user, obj/item/tool)
	switch(state)
		if(TRAM_IN_FRAME)
			user.visible_message(span_notice("[user] просовывает [tool] в зазор между панелью и рамой и начинает поддевать..."),
				span_notice("Вы просовываете [tool] в зазор между панелью и рамой и начинаете поддевать..."))
			if(!tool.use_tool(src, user, 1 SECONDS, volume = 50) || state != TRAM_IN_FRAME)
				return TRUE
			state = TRAM_OUT_OF_FRAME
			to_chat(user, span_notice("Панель выскакивает из рамы, обнажая провода, которые можно перекусить."))
			return TRUE

		if(TRAM_OUT_OF_FRAME)
			user.visible_message(span_notice("[user] защёлкивает панель трамвая на место."),
				span_notice("Вы защёлкиваете панель трамвая на место."))
			state = TRAM_IN_FRAME
			return TRUE

	to_chat(user, span_warning("Сначала нужно выкрутить защитные винты!"))
	return TRUE

/obj/structure/tram/wirecutter_act(mob/living/user, obj/item/tool)
	if(state != TRAM_OUT_OF_FRAME)
		to_chat(user, span_warning("Сначала нужно вынуть панель из рамы!"))
		return TRUE
	user.visible_message(span_notice("[user] начинает перекусывать соединительные провода [src]..."),
		span_notice("Вы начинаете перекусывать соединительные провода [src]..."))
	if(!tool.use_tool(src, user, 1 SECONDS, volume = 50) || state != TRAM_OUT_OF_FRAME)
		return TRUE
	to_chat(user, span_notice("Панель отваливается, открывая заднюю часть рамы."))
	deconstruct(disassembled = TRUE)
	return TRUE

/obj/structure/tram/attackby(obj/item/attacking_item, mob/user, params)
	if(istype(attacking_item, /obj/item/wallframe/tram))
		var/obj/item/wallframe/tram/frame = attacking_item
		if(!(locate(/obj/structure/thermoplastic) in get_turf(user)))
			balloon_alert(user, "нужен пол трамвая!")
			return STOP_ATTACK_PROC_CHAIN
		if(get_dist(src, user) > 1 || !(get_dir(user, src) in GLOB.cardinals))
			return STOP_ATTACK_PROC_CHAIN
		frame.attach(get_turf(src), user, params)
		return STOP_ATTACK_PROC_CHAIN
	return ..()

/obj/structure/tram/deconstruct(disassembled = TRUE)
	if(!(flags_1 & NODECONSTRUCT_1))
		if(disassembled && girder_type)
			new girder_type(loc)
		if(mineral_amount)
			new mineral(loc, mineral_amount)
	qdel(src)

/obj/structure/tram/get_dumping_location(obj/item/storage/source, mob/user)
	return null

/obj/structure/tram/spoiler
	name = "tram spoiler"
	icon = 'modular_bluemoon/icons/obj/tram/tram_structure.dmi'
	desc = "Нанотрейзен купила люксовый пакет, решив, что титановые спойлеры ускоряют трамвай. Они просто для красоты. Ну, или чтобы проткнуть того, кто встанет на пути."
	icon_state = "tram-spoiler-retracted"
	max_integrity = 400
	obj_flags = CAN_BE_HIT
	mineral = /obj/item/stack/sheet/mineral/titanium
	girder_type = /obj/structure/girder/tram/corner
	smooths = FALSE
	/// Position of the spoiler
	var/deployed = FALSE
	/// Locked in position
	var/locked = FALSE

/obj/structure/tram/spoiler/Initialize(mapload)
	. = ..()
	return INITIALIZE_HINT_LATELOAD

/obj/structure/tram/spoiler/LateInitialize()
	. = ..()
	RegisterSignal(SStransport, COMSIG_TRANSPORT_UPDATED, PROC_REF(set_spoiler))

/obj/structure/tram/spoiler/add_context(atom/source, list/context, obj/item/held_item, mob/living/user)
	. = ..()
	if(held_item?.tool_behaviour == TOOL_MULTITOOL && (obj_flags & EMAGGED))
		context[SCREENTIP_CONTEXT_LMB] = "Починить"

	if(held_item?.tool_behaviour == TOOL_WELDER && obj_integrity >= max_integrity)
		context[SCREENTIP_CONTEXT_LMB] = locked ? "Освободить" : "Заварить"

	return CONTEXTUAL_SCREENTIP_SET

/obj/structure/tram/spoiler/examine(mob/user)
	. = ..()
	if(obj_flags & EMAGGED)
		. += span_warning("Панель электроники время от времени искрит. Её можно сбросить [EXAMINE_HINT("мультитулом")].")

	if(locked)
		. += span_warning("Спойлер [EXAMINE_HINT("заварен")] в выдвинутом положении!")
	else
		. += span_notice("Спойлер можно заварить на месте [EXAMINE_HINT("сваркой")].")

/obj/structure/tram/spoiler/proc/set_spoiler(datum/source, controller, controller_active, controller_status, travel_direction)
	SIGNAL_HANDLER

	if(locked || controller_status & COMM_ERROR || obj_flags & EMAGGED)
		if(!deployed)
			if(locked)
				visible_message(span_danger("[capitalize(src.name)] клинит: сервопривод перегрелся!"))
			do_sparks(3, FALSE, src)
			deploy_spoiler()
		return

	if(!controller_active)
		return

	switch(travel_direction)
		if(SOUTH, EAST)
			switch(dir)
				if(NORTH, EAST)
					retract_spoiler()
				if(SOUTH, WEST)
					deploy_spoiler()

		if(NORTH, WEST)
			switch(dir)
				if(NORTH, EAST)
					deploy_spoiler()
				if(SOUTH, WEST)
					retract_spoiler()

/obj/structure/tram/spoiler/proc/deploy_spoiler()
	if(deployed)
		return
	flick("tram-spoiler-deploying", src)
	icon_state = "tram-spoiler-deployed"
	deployed = TRUE
	update_appearance()

/obj/structure/tram/spoiler/proc/retract_spoiler()
	if(!deployed)
		return
	flick("tram-spoiler-retracting", src)
	icon_state = "tram-spoiler-retracted"
	deployed = FALSE
	update_appearance()

/obj/structure/tram/spoiler/emag_act(mob/user)
	. = ..()
	if(obj_flags & EMAGGED)
		return FALSE
	to_chat(user, span_warning("Вы закорачиваете сервопривод [src], и он начинает перегреваться!"))
	playsound(src, "sparks", 100, vary = TRUE, extrarange = SHORT_RANGE_SOUND_EXTRARANGE)
	do_sparks(5, FALSE, src)
	obj_flags |= EMAGGED
	return TRUE

/obj/structure/tram/spoiler/multitool_act(mob/living/user, obj/item/tool)
	if(user.a_intent == INTENT_HARM)
		return FALSE

	if(obj_flags & EMAGGED)
		balloon_alert(user, "электроника сброшена!")
		obj_flags &= ~EMAGGED
		return TRUE

	return FALSE

/obj/structure/tram/spoiler/welder_act(mob/living/user, obj/item/tool)
	if(!tool.tool_start_check(user, amount = 1))
		return TRUE

	if(obj_integrity >= max_integrity)
		to_chat(user, span_warning("Вы начинаете заваривать [src], [locked ? "исправляя повреждения" : "чтобы он не убирался"]."))
		if(!tool.use_tool(src, user, 4 SECONDS, volume = 50))
			return TRUE
		locked = !locked
		user.visible_message(span_warning("[user] [locked ? "заваривает [src] на месте" : "освобождает [src]"] с помощью [tool]."), \
			span_warning("Вы заканчиваете работу с [src]: [locked ? "теперь он заварен на месте." : "теперь он снова двигается свободно!"]"), null, COMBAT_MESSAGE_RANGE)

		if(locked)
			deploy_spoiler()

		update_appearance()
		return TRUE

	return ..()

/obj/structure/tram/spoiler/update_overlays()
	. = ..()
	if(deployed && locked)
		. += mutable_appearance(icon, "tram-spoiler-welded")

/obj/structure/girder/tram
	name = "tram girder"
	desc = "Титановый каркас для стен трамвая. Обшивается <b>титановым стеклом</b>."
	icon = 'modular_bluemoon/icons/obj/tram/tram_girder.dmi'
	icon_state = "tram"
	can_displace = FALSE
	smooth = NONE
	canSmoothWith = null
	obj_flags = CAN_BE_HIT | BLOCK_Z_OUT_DOWN

/obj/structure/girder/tram/corner
	name = "tram frame corner"

/obj/structure/girder/tram/examine(mob/user)
	. = ..()
	. += span_notice("Этот каркас рассчитан на трамвай и разбирается [EXAMINE_HINT("отвёрткой")].")

/obj/structure/girder/tram/attackby(obj/item/attacking_item, mob/user, params)
	if(istype(attacking_item, /obj/item/stack/sheet/titaniumglass))
		add_fingerprint(user)
		var/obj/item/stack/sheet/titaniumglass/glass = attacking_item
		if(!(locate(/obj/structure/transport/linear/tram) in loc))
			balloon_alert(user, "нужно основание трамвая!")
			return STOP_ATTACK_PROC_CHAIN
		if(locate(/obj/structure/tram) in loc)
			balloon_alert(user, "стена уже есть!")
			return STOP_ATTACK_PROC_CHAIN
		if(glass.get_amount() < 2)
			balloon_alert(user, "нужно два листа!")
			return STOP_ATTACK_PROC_CHAIN
		balloon_alert(user, "обшиваем каркас...")
		if(!do_after(user, 2 SECONDS, target = src) || QDELETED(src) || !glass.use(2))
			return STOP_ATTACK_PROC_CHAIN
		var/obj/structure/tram/new_wall = new /obj/structure/tram(loc)
		transfer_fingerprints_to(new_wall)
		qdel(src)
		return STOP_ATTACK_PROC_CHAIN
	if(istype(attacking_item, /obj/item/stack))
		balloon_alert(user, "нужно титановое стекло!")
		return STOP_ATTACK_PROC_CHAIN
	return ..()

/obj/structure/girder/tram/screwdriver_act(mob/user, obj/item/tool)
	to_chat(user, span_notice("Вы начинаете разбирать [src]..."))
	if(!tool.use_tool(src, user, 4 SECONDS, volume = 100) || QDELETED(src))
		return TRUE
	to_chat(user, span_notice("Вы разбираете [src]."))
	deconstruct(TRUE)
	return TRUE

/obj/structure/girder/tram/wrench_act(mob/user, obj/item/tool)
	return FALSE

/obj/structure/girder/tram/deconstruct(disassembled = TRUE)
	if(!(flags_1 & NODECONSTRUCT_1))
		new /obj/item/stack/sheet/mineral/titanium(loc, 2)
	qdel(src)

/obj/structure/chair/sofa/bench
	name = "bench"
	desc = "Идеально продумана: сидеть удобно, спать - сущий ад."
	icon = 'modular_bluemoon/icons/obj/tram/benches.dmi'
	icon_state = "bench_middle"

/obj/structure/chair/sofa/bench/update_armrest()
	return

/obj/structure/chair/sofa/bench/left
	icon_state = "bench_left"

/obj/structure/chair/sofa/bench/right
	icon_state = "bench_right"

/obj/structure/chair/sofa/bench/corner
	icon_state = "bench_corner"

/obj/structure/chair/sofa/bench/corner/handle_layer()
	return

/obj/structure/chair/sofa/bench/solo
	icon_state = "bench_solo"

/obj/structure/chair/sofa/bench/tram
	icon_state = "tram_bench_middle"

/obj/structure/chair/sofa/bench/tram/left
	icon_state = "tram_bench_left"

/obj/structure/chair/sofa/bench/tram/right
	icon_state = "tram_bench_right"

/obj/structure/chair/sofa/bench/tram/corner
	icon_state = "tram_bench_corner"

/obj/structure/chair/sofa/bench/tram/corner/handle_layer()
	return

/obj/structure/chair/sofa/bench/tram/solo
	icon_state = "tram_bench_solo"

#undef TRAM_JUNCTION_NORTHEAST
#undef TRAM_JUNCTION_SOUTHEAST
#undef TRAM_JUNCTION_SOUTHWEST
#undef TRAM_JUNCTION_NORTHWEST
