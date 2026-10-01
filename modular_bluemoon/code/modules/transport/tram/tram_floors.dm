/turf/open/floor/noslip/tram
	name = "high-traction tram platform"
	icon = 'modular_bluemoon/icons/turf/tram.dmi'
	icon_state = "noslip_tram"
	base_icon_state = "noslip_tram"
	floor_tile = /obj/item/stack/tile/noslip/tram
	broken_states = list("noslip_tram-damaged1")
	burnt_states = list("noslip_tram-damaged1")

/turf/open/floor/tram
	name = "tram guideway"
	icon = 'modular_bluemoon/icons/turf/tram.dmi'
	icon_state = "tram_platform"
	base_icon_state = "tram_platform"
	floor_tile = /obj/item/stack/tile/tram
	footstep = FOOTSTEP_CATWALK
	barefootstep = FOOTSTEP_HARD_BAREFOOT
	clawfootstep = FOOTSTEP_HARD_CLAW
	heavyfootstep = FOOTSTEP_GENERIC_HEAVY
	broken_states = list("tram_platform-damaged1", "tram_platform-damaged2")
	burnt_states = list("tram_platform-damaged1", "tram_platform-damaged2")

/turf/open/floor/tram/examine(mob/user)
	. = ..()
	. += span_notice("Плита крепится [EXAMINE_HINT("болтами")]. Снять её можно [EXAMINE_HINT("гаечным ключом")].")

/turf/open/floor/tram/attackby(obj/item/attacking_item, mob/user, params)
	if(istype(attacking_item, /obj/item/stack/thermoplastic))
		build_with_transport_tiles(attacking_item, user)
		return TRUE
	if(istype(attacking_item, /obj/item/stack/sheet/mineral/titanium))
		build_with_titanium(attacking_item, user)
		return TRUE
	if(istype(attacking_item, /obj/item/stack/tile))
		return TRUE
	return ..()

/turf/open/floor/tram/make_plating(force = FALSE)
	if(force)
		return ..()

/turf/open/floor/tram/crowbar_act(mob/living/user, obj/item/tool)
	return FALSE

/turf/open/floor/tram/wrench_act(mob/living/user, obj/item/tool)
	to_chat(user, span_notice("Вы начинаете снимать плиту..."))
	if(tool.use_tool(src, user, 3 SECONDS, volume = 80))
		if(!istype(src, /turf/open/floor/tram))
			return TRUE
		if(floor_tile)
			new floor_tile(src, 2)
		ScrapeAway(flags = CHANGETURF_INHERIT_AIR)
	return TRUE

/turf/open/floor/tram/plate
	name = "linear induction plate"
	desc = "Плита линейного индукционного привода, на которой ездит трамвай."
	icon_state = "tram_plate"
	base_icon_state = "tram_plate"
	floor_tile = /obj/item/stack/tile/tram/plate
	broken_states = list("tram_plate-damaged1", "tram_plate-damaged2")
	burnt_states = list("tram_plate-damaged1", "tram_plate-damaged2")

/turf/open/floor/tram/plate/energized
	desc = "Плита линейного индукционного привода, на которой ездит трамвай. Сейчас она под напряжением."
	broken_states = list("energized_plate_damaged")
	burnt_states = list("energized_plate_damaged")
	/// Inbound station
	var/inbound
	/// Outbound station
	var/outbound
	/// Transport ID of the tram
	var/specific_transport_id = TRAMSTATION_LINE_1

/turf/open/floor/tram/plate/energized/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/energized, inbound, outbound, specific_transport_id)

/turf/open/floor/tram/plate/energized/examine(mob/user)
	. = ..()
	if(broken || burnt)
		. += span_danger("Плита повреждена, электрика торчит наружу!")
		. += span_notice("Её можно заменить, если приложить [EXAMINE_HINT("лист титана")].")

/turf/open/floor/tram/plate/energized/attackby(obj/item/attacking_item, mob/user, params)
	if((broken || burnt) && istype(attacking_item, /obj/item/stack/sheet/mineral/titanium))
		var/obj/item/stack/sheet/mineral/titanium/titanium = attacking_item
		if(!titanium.use(1))
			return TRUE
		broken = FALSE
		burnt = FALSE
		icon_state = base_icon_state
		update_appearance()
		balloon_alert(user, "плита заменена")
		return TRUE
	return ..()

/turf/open/floor/tram/plate/energized/broken
	broken = TRUE
	icon_state = "energized_plate_damaged"

// Resetting the tram contents to its original state needs the turf to be there
/turf/open/indestructible/tram
	name = "tram guideway"
	icon = 'modular_bluemoon/icons/turf/tram.dmi'
	icon_state = "tram_platform"
	base_icon_state = "tram_platform"
	footstep = FOOTSTEP_CATWALK
	barefootstep = FOOTSTEP_HARD_BAREFOOT
	clawfootstep = FOOTSTEP_HARD_CLAW
	heavyfootstep = FOOTSTEP_GENERIC_HEAVY

/turf/open/indestructible/tram/attackby(obj/item/attacking_item, mob/user, params)
	if(istype(attacking_item, /obj/item/stack/thermoplastic))
		build_with_transport_tiles(attacking_item, user)
		return TRUE
	if(istype(attacking_item, /obj/item/stack/sheet/mineral/titanium))
		build_with_titanium(attacking_item, user)
		return TRUE
	return ..()

/turf/open/indestructible/tram/plate
	name = "linear induction plate"
	desc = "Плита линейного индукционного привода, на которой ездит трамвай."
	icon_state = "tram_plate"
	base_icon_state = "tram_plate"

/turf/open/floor/glass/reinforced/tram
	name = "tram bridge"
	desc = "Слегка пружинит под ногами, зато через него быстро перейти на другую сторону!"

/// Lays a thermoplastic tram floor tile on the transport module standing on this turf
/turf/open/proc/build_with_transport_tiles(obj/item/stack/thermoplastic/used_tiles, mob/user)
	var/obj/structure/transport/linear/platform = locate(/obj/structure/transport/linear) in src
	if(!platform)
		balloon_alert(user, "нет основания трамвая!")
		return
	if(locate(/obj/structure/thermoplastic) in src)
		balloon_alert(user, "пол уже уложен!")
		return
	if(!used_tiles.use(1))
		balloon_alert(user, "нет плитки!")
		return

	playsound(src, 'sound/weapons/genhit.ogg', 50, TRUE)
	new used_tiles.tile_type(src)

/// Very similar to building with rods, this exists to allow building tram girders on the transport module
/turf/open/proc/build_with_titanium(obj/item/stack/sheet/mineral/titanium/used_stack, mob/user)
	var/obj/structure/transport/linear/platform = locate(/obj/structure/transport/linear) in src
	if(!platform)
		to_chat(user, span_warning("Здесь нет основания трамвая, к которому можно прикрепить каркас!"))
		return
	if(locate(/obj/structure/girder) in src)
		balloon_alert(user, "каркас уже есть!")
		return
	if(!used_stack.use(2))
		balloon_alert(user, "нужно два листа титана!")
		return

	playsound(src, 'sound/weapons/genhit.ogg', 50, TRUE)
	new /obj/structure/girder/tram(src)

/obj/structure/thermoplastic
	name = "tram floor"
	desc = "Лёгкое покрытие из термопластика."
	icon = 'modular_bluemoon/icons/turf/tram.dmi'
	icon_state = "tram_dark"
	base_icon_state = "tram_dark"
	density = FALSE
	anchored = TRUE
	max_integrity = 150
	integrity_failure = 0.75
	armor = list(MELEE = 40, BULLET = 10, LASER = 10, ENERGY = 0, BOMB = 45, BIO = 0, RAD = 0, FIRE = 90, ACID = 100)
	layer = TRAM_FLOOR_LAYER
	plane = GAME_PLANE
	obj_flags = CAN_BE_HIT | BLOCK_Z_OUT_DOWN | BLOCK_Z_OUT_UP
	appearance_flags = PIXEL_SCALE|KEEP_TOGETHER
	custom_materials = list(/datum/material/plastic = MINERAL_MATERIAL_AMOUNT / 4)
	var/secured = TRUE
	var/floor_tile = /obj/item/stack/thermoplastic

/obj/structure/thermoplastic/light
	icon_state = "tram_light"
	base_icon_state = "tram_light"
	floor_tile = /obj/item/stack/thermoplastic/light

/obj/structure/thermoplastic/examine(mob/user)
	. = ..()

	if(secured)
		. += span_notice("Плитка закреплена [EXAMINE_HINT("винтами")]. Чтобы снять её, нужна [EXAMINE_HINT("отвёртка")].")
	else
		. += span_notice("Плитку можно поддеть [EXAMINE_HINT("ломом")].")
		. += span_notice("Закрепить её обратно можно [EXAMINE_HINT("отвёрткой")].")

/obj/structure/thermoplastic/take_damage(damage_amount, damage_type = BRUTE, damage_flag = 0, sound_effect = 1, attack_dir, armour_penetration = 0)
	. = ..()
	if(.)
		update_appearance()

/obj/structure/thermoplastic/update_icon_state()
	. = ..()
	var/ratio = obj_integrity / max_integrity
	ratio = CEILING(ratio * 4, 1) * 25
	if(ratio > 75)
		icon_state = base_icon_state
		return

	icon_state = "[base_icon_state]_damage[ratio]"

/obj/structure/thermoplastic/screwdriver_act(mob/living/user, obj/item/tool)
	if(secured)
		user.visible_message(span_notice("[user] начинает откручивать плитку..."),
			span_notice("Вы начинаете откручивать плитку..."))
		if(tool.use_tool(src, user, 1 SECONDS, volume = 50))
			secured = FALSE
			to_chat(user, span_notice("Винты выкручены, по краю плитки появился зазор."))
	else
		user.visible_message(span_notice("[user] начинает закреплять плитку..."),
			span_notice("Вы начинаете закреплять плитку..."))
		if(tool.use_tool(src, user, 1 SECONDS, volume = 50))
			secured = TRUE
			to_chat(user, span_notice("Плитка надёжно прикручена."))

	return TRUE

/obj/structure/thermoplastic/crowbar_act(mob/living/user, obj/item/tool)
	if(secured)
		to_chat(user, span_warning("Сначала нужно выкрутить защитные винты!"))
		return TRUE

	user.visible_message(span_notice("[user] просовывает [tool] в зазор у края плитки и начинает поддевать..."),
		span_notice("Вы просовываете [tool] в зазор у края плитки и начинаете поддевать..."))
	if(tool.use_tool(src, user, 1 SECONDS, volume = 50) && !QDELETED(src))
		to_chat(user, span_notice("Плитка выскакивает из рамы."))
		var/obj/item/stack/thermoplastic/pulled_tile = new floor_tile(drop_location())
		user.put_in_hands(pulled_tile)
		qdel(src)

	return TRUE

/obj/structure/thermoplastic/welder_act(mob/living/user, obj/item/tool)
	if(obj_integrity >= max_integrity)
		to_chat(user, span_warning("[capitalize(src.name)] и так в порядке!"))
		return TRUE
	if(!tool.tool_start_check(user, amount = 0))
		return TRUE
	to_chat(user, span_notice("Вы начинаете чинить [src]..."))
	var/integrity_to_repair = max_integrity - obj_integrity
	if(tool.use_tool(src, user, integrity_to_repair * 0.5, volume = 50))
		obj_integrity = max_integrity
		to_chat(user, span_notice("Вы чините [src]."))
		update_appearance()
	return TRUE

/obj/item/stack/thermoplastic
	name = "thermoplastic tram tile"
	singular_name = "thermoplastic tram tile"
	desc = "Плитка с высоким сцеплением. Блестит на свету."
	icon = 'modular_bluemoon/icons/obj/tram/tram_tiles.dmi'
	icon_state = "tile_tram_dark"
	item_state = "tile"
	color = COLOR_TRAM_BLUE
	w_class = WEIGHT_CLASS_NORMAL
	force = 1
	throwforce = 1
	throw_speed = 3
	throw_range = 7
	max_amount = 60
	novariants = TRUE
	merge_type = /obj/item/stack/thermoplastic
	mats_per_unit = list(/datum/material/plastic = MINERAL_MATERIAL_AMOUNT / 4)
	var/tile_type = /obj/structure/thermoplastic

/obj/item/stack/thermoplastic/light
	icon_state = "tile_tram_light"
	color = COLOR_TRAM_LIGHT_BLUE
	merge_type = /obj/item/stack/thermoplastic/light
	tile_type = /obj/structure/thermoplastic/light

/obj/item/stack/thermoplastic/Initialize(mapload, new_amount, merge = TRUE)
	. = ..()
	pixel_x = rand(-3, 3)
	pixel_y = rand(-3, 3)

/obj/item/stack/tile/noslip/tram
	name = "high-traction platform tile"
	singular_name = "high-traction platform tile"
	desc = "Титано-алюминиевая индукционная плита, питающая трамвай."
	icon_state = "tile_noslip"
	turf_type = /turf/open/floor/noslip/tram
	merge_type = /obj/item/stack/tile/noslip/tram

/obj/item/stack/tile/tram
	name = "tram platform tiles"
	singular_name = "tram platform"
	desc = "Плитка для трамвайных платформ."
	icon_state = "darkiron_catwalk"
	turf_type = /turf/open/floor/tram
	merge_type = /obj/item/stack/tile/tram

/obj/item/stack/tile/tram/plate
	name = "linear induction tram tiles"
	singular_name = "linear induction tram tile"
	desc = "Плитка с алюминиевой пластиной для привода трамвая."
	icon = 'modular_bluemoon/icons/obj/tram/tram_tiles.dmi'
	icon_state = "darkiron_plate"
	turf_type = /turf/open/floor/tram/plate
	merge_type = /obj/item/stack/tile/tram/plate
