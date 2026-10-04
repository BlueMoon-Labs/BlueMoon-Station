// Basic ladder. By default links to the z-level above/below.
/obj/structure/ladder
	name = "ladder"
	desc = "A sturdy metal ladder."
	icon = 'icons/obj/structures.dmi'
	icon_state = "ladder11"
	anchored = TRUE
	var/obj/structure/ladder/down   //the ladder below this one
	var/obj/structure/ladder/up     //the ladder above this one
	/// Называть ли, куда ведёт лестница: у загадочной лестницы весь смысл в том, что это неизвестно.
	var/reveal_destination = TRUE

/obj/structure/ladder/Initialize(mapload, obj/structure/ladder/up, obj/structure/ladder/down)
	..()
	if (up)
		src.up = up
		up.down = src
		up.update_icon()
	if (down)
		src.down = down
		down.up = src
		down.update_icon()
	return INITIALIZE_HINT_LATELOAD

/obj/structure/ladder/Destroy(force)
	if ((resistance_flags & INDESTRUCTIBLE) && !force)
		return QDEL_HINT_LETMELIVE
	disconnect()
	return ..()

/obj/structure/ladder/LateInitialize()
	// By default, discover ladders above and below us vertically
	var/turf/T = get_turf(src)
	var/obj/structure/ladder/L

	if (!down)
		L = locate() in SSmapping.get_turf_below(T)
		if (L)
			down = L
			L.up = src  // Don't waste effort looping the other way
			L.update_icon()
	if (!up)
		L = locate() in SSmapping.get_turf_above(T)
		if (L)
			up = L
			L.down = src  // Don't waste effort looping the other way
			L.update_icon()

	update_icon()

/obj/structure/ladder/proc/disconnect()
	if(up && up.down == src)
		up.down = null
		up.update_icon()
	if(down && down.up == src)
		down.up = null
		down.update_icon()
	up = down = null

/obj/structure/ladder/update_icon_state()
	if(up && down)
		icon_state = "ladder11"

	else if(up)
		icon_state = "ladder10"

	else if(down)
		icon_state = "ladder01"

	else	//wtf make your ladders properly assholes
		icon_state = "ladder00"

/// Название места, куда ведёт этот конец лестницы.
/obj/structure/ladder/proc/describe_link(obj/structure/ladder/target)
	if(!target)
		return null
	if(!reveal_destination)
		return "неизвестно куда"
	var/turf/landing = get_turf(target)
	if(!landing)
		return null
	return get_area_name(landing) || "неизвестно куда"

/obj/structure/ladder/examine(mob/user)
	. = ..()
	var/up_where = describe_link(up)
	var/down_where = describe_link(down)
	if(up_where)
		. += span_notice("Вверху: [up_where].")
	if(down_where)
		. += span_notice("Внизу: [down_where].")
	if(!up_where && !down_where)
		. += span_warning("Не ведёт никуда: соседних лестниц ни сверху, ни снизу нет.")

/obj/structure/ladder/singularity_pull()
	if (!(resistance_flags & INDESTRUCTIBLE))
		visible_message("<span class='danger'>[src] is torn to pieces by the gravitational pull!</span>")
		qdel(src)

/obj/structure/ladder/proc/travel(going_up, mob/user, is_ghost, obj/structure/ladder/ladder)
	if(!is_ghost)
		show_fluff_message(going_up, user, ladder)
		ladder.add_fingerprint(user)

	var/turf/T = get_turf(ladder)
	//Лестница сама решает, куда ставит: проверки полёта и препятствий не нужны, а пристёгнутые и буксируемые едут с мобом.
	user.zMove(null, T, ZMOVE_CHECK_PULLEDBY|ZMOVE_ALLOW_BUCKLED|ZMOVE_INCLUDE_PULLED)

	//reopening ladder radial menu ahead
	T = get_turf(user)
	var/obj/structure/ladder/ladder_structure = locate() in T
	if (ladder_structure && (ladder_structure.up && ladder_structure.down))
		ladder_structure.use(user)

/obj/structure/ladder/proc/use(mob/user, is_ghost=FALSE)
	if (!is_ghost && !in_range(src, user))
		return

	//Подсказка при наведении берётся из ключа списка, см. radial.dm.
	var/up_label = up ? "Вверх: [describe_link(up)]" : "Вверх"
	var/down_label = down ? "Вниз: [describe_link(down)]" : "Вниз"
	var/list/tool_list = list()
	tool_list[up_label] = image(icon = 'icons/Testing/turf_analysis.dmi', icon_state = "red_arrow", dir = NORTH)
	tool_list[down_label] = image(icon = 'icons/Testing/turf_analysis.dmi', icon_state = "red_arrow", dir = SOUTH)

	if (up && down)
		var/result = show_radial_menu(user, src, tool_list, custom_check = CALLBACK(src, PROC_REF(check_menu), user), require_near = TRUE, tooltips = TRUE)
		if (!is_ghost && !in_range(src, user))
			return  // nice try
		if(result == up_label)
			travel(TRUE, user, is_ghost, up)
		else if(result == down_label)
			travel(FALSE, user, is_ghost, down)
		else
			return
	else if(up)
		travel(TRUE, user, is_ghost, up)
	else if(down)
		travel(FALSE, user, is_ghost, down)
	else
		to_chat(user, "<span class='warning'>[src] doesn't seem to lead anywhere!</span>")

	if(!is_ghost)
		add_fingerprint(user)

/obj/structure/ladder/proc/check_menu(mob/user)
	if(user.incapacitated() || !user.Adjacent(src))
		return FALSE
	return TRUE

/obj/structure/ladder/on_attack_hand(mob/user, act_intent = user.a_intent, unarmed_attack_flags)
	use(user)

/obj/structure/ladder/attack_paw(mob/user)
	return use(user)

/obj/structure/ladder/attackby(obj/item/W, mob/user, params)
	return use(user)

/obj/structure/ladder/attack_robot(mob/living/silicon/robot/R)
	if(R.Adjacent(src))
		return use(R)

//ATTACK GHOST IGNORING PARENT RETURN VALUE
/obj/structure/ladder/attack_ghost(mob/dead/observer/user)
	use(user, TRUE)
	return ..()

/obj/structure/ladder/proc/show_fluff_message(going_up, mob/user, obj/structure/ladder/target)
	var/where = describe_link(target)
	var/suffix = where ? ", [where]" : ""
	if(going_up)
		user.visible_message("[user] забирается вверх по [src].", span_notice("Вы забираетесь вверх по [src][suffix]."))
	else
		user.visible_message("[user] спускается вниз по [src].", span_notice("Вы спускаетесь вниз по [src][suffix]."))


// Indestructible away mission ladders which link based on a mapped ID and height value rather than X/Y/Z.
/obj/structure/ladder/unbreakable
	name = "sturdy ladder"
	desc = "An extremely sturdy metal ladder."
	resistance_flags = INDESTRUCTIBLE
	var/id
	var/height = 0  // higher numbers are considered physically higher

/obj/structure/ladder/unbreakable/Initialize(mapload)
	GLOB.ladders += src
	return ..()

/obj/structure/ladder/unbreakable/Destroy()
	. = ..()
	if (. != QDEL_HINT_LETMELIVE)
		GLOB.ladders -= src

/obj/structure/ladder/unbreakable/LateInitialize()
	// Override the parent to find ladders based on being height-linked
	if (!id || (up && down))
		update_icon()
		return

	for (var/O in GLOB.ladders)
		var/obj/structure/ladder/unbreakable/L = O
		if (L.id != id)
			continue  // not one of our pals
		if (!down && L.height == height - 1)
			down = L
			L.up = src
			L.update_icon()
			if (up)
				break  // break if both our connections are filled
		else if (!up && L.height == height + 1)
			up = L
			L.down = src
			L.update_icon()
			if (down)
				break  // break if both our connections are filled

	update_icon()

/obj/structure/ladder/unbreakable/binary
	name = "mysterious ladder"
	desc = "Where does it go?"
	reveal_destination = FALSE
	height = 0
	id = "lavaland_binary"
	var/area_to_place = /area/lavaland/surface/outdoors
	var/active = FALSE

/obj/structure/ladder/unbreakable/binary/proc/ActivateAlmonds()
	if(area_to_place && !active)
		var/turf/T = getTargetTurf()
		if(T)
			var/obj/structure/ladder/unbreakable/U = new (T)
			U.id = id
			U.height = height+1
			LateInitialize() // LateInit both of these to build the links. It's fine.
			U.LateInitialize()
			for(var/turf/TT in range(2,U))
				TT.TerraformTurf(/turf/open/indestructible/binary, /turf/open/indestructible/binary, CHANGETURF_INHERIT_AIR)
		active = TRUE

/obj/structure/ladder/unbreakable/binary/proc/getTargetTurf()
	var/list/turfList = get_area_turfs(area_to_place)
	while (turfList.len && !.)
		var/i = rand(1, turfList.len)
		var/turf/potentialTurf = turfList[i]
		if (is_centcom_level(potentialTurf.z)) // These ladders don't lead to centcom.
			turfList.Cut(i,i+1)
			continue
		if(!istype(potentialTurf, /turf/open/lava) && !potentialTurf.density)			// Or inside dense turfs or lava
			var/clear = TRUE
			for(var/obj/O in potentialTurf) // Let's not place these on dense objects either. Might be funny though.
				if(O.density)
					clear = FALSE
					break
			if(clear)
				. = potentialTurf
		if (!.)
			turfList.Cut(i,i+1)

/obj/structure/ladder/unbreakable/binary/space
	id = "space_binary"
	area_to_place = /area/space

/obj/structure/ladder/unbreakable/binary/unlinked //Crew gets to complete one
	id = "unlinked_binary"
	area_to_place = null
