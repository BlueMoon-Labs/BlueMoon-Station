#define SAUNA_H2O_TEMP (T20C + 50)
#define SAUNA_LOG_FUEL 150
#define SAUNA_PAPER_FUEL 5
#define SAUNA_MAXIMUM_FUEL 3000
#define SAUNA_WATER_PER_WATER_UNIT 5

/obj/structure/sauna_oven
	name = "Sauna Oven"
	desc = "Скромная банная печь с камнями, созданная благодаря удивительным нано-обитателям окружающего пространства. Добавьте немного топлива, налейте воды и наслаждайтесь моментом."
	icon = 'modular_bluemoon/icons/obj/aesthetics/sauna/sauna_oven.dmi'
	icon_state = "sauna_oven"
	density = TRUE
	anchored = TRUE
	resistance_flags = FIRE_PROOF
	var/lit = FALSE
	var/fuel_amount = 0
	var/water_amount = 0

/obj/structure/sauna_oven/examine(mob/user)
	. = ..()
	. += span_notice("Камни выглядят [water_amount ? "влажными" : "суховатыми"].")
	. += span_notice("Вы наблюдаете [fuel_amount ? "горящие материалы" : "кучу тлеющей золы"] внутри топки печи.")

/obj/structure/sauna_oven/Destroy()
	if(lit)
		STOP_PROCESSING(SSobj, src)
	QDEL_NULL(particles)
	return ..()

/obj/structure/sauna_oven/attack_hand(mob/user)
	. = ..()
	if(.)
		return
	if(lit)
		lit = FALSE
		STOP_PROCESSING(SSobj, src)
		user.visible_message(span_notice("[user] перекрывает воздух в [src]."), span_notice("Вы перекрываете воздух в [src]."))
	else if (fuel_amount)
		lit = TRUE
		START_PROCESSING(SSobj, src)
		user.visible_message(span_notice("[user] активирует [src] соответственным образом."), span_notice("Вы активировали [src] соответственным образом."))
	update_icon()

/obj/structure/sauna_oven/update_overlays()
	. = ..()
	if(lit)
		. += "sauna_oven_on_overlay"

/obj/structure/sauna_oven/update_icon()
	..()
	icon_state = "[lit ? "sauna_oven_on" : initial(icon_state)]"

/obj/structure/sauna_oven/attackby(obj/item/used_item, mob/user)
	if(used_item.tool_behaviour == TOOL_WRENCH)
		balloon_alert(user, "Разбираю...")
		if(used_item.use_tool(src, user, 60, volume = 50))
			balloon_alert(user, "Разобрал!")
			new /obj/item/stack/sheet/mineral/wood(get_turf(src), 30)
			qdel(src)

	else if(istype(used_item, /obj/item/reagent_containers))
		var/obj/item/reagent_containers/reagent_container = used_item
		if(!reagent_container.is_open_container())
			return ..()
		if(reagent_container.reagents.has_reagent(/datum/reagent/water))
			reagent_container.reagents.remove_reagent(/datum/reagent/water, 5)
			user.visible_message(span_notice("[user] подливает немного \
			воды в [src]."), span_notice("Вы подлили немного \
			воды в [src]."))
			water_amount += 5 * SAUNA_WATER_PER_WATER_UNIT
		else
			balloon_alert(user, "Нет воды!")

	else if(istype(used_item, /obj/item/stack/sheet/mineral/wood))
		var/obj/item/stack/sheet/mineral/wood/wood = used_item
		if(fuel_amount > SAUNA_MAXIMUM_FUEL)
			balloon_alert(user, "В топке нет места!")
			return
		fuel_amount += SAUNA_LOG_FUEL * wood.amount
		wood.use(wood.amount)
		user.visible_message(span_notice("[user] бросает щепки \
			в топку [src]."), span_notice("Вы бросаете щепки \
			в топку [src]."))
	else if(istype(used_item, /obj/item/paper_bin))
		var/obj/item/paper_bin/paper_bin = used_item
		user.visible_message(span_notice("[user] бросает [used_item] в топку \
			[src]."), span_notice("Вы добавляете немного [used_item] в топку [src].\
			"))
		fuel_amount += SAUNA_PAPER_FUEL * paper_bin.total_paper
		qdel(paper_bin)
	else if(istype(used_item, /obj/item/paper))
		user.visible_message(span_notice("[user] бросает немного [used_item] в топку \
			[src]."), span_notice("Вы добавляете немного [used_item] в топку [src].\
			"))
		fuel_amount += SAUNA_PAPER_FUEL
		qdel(used_item)
	return ..()

/obj/structure/sauna_oven/process()
	if(water_amount)
		water_amount--
		update_steam_particles()
		var/turf/open/pos = get_turf(src)
		if(istype(pos) && pos.air.return_pressure() < 2*ONE_ATMOSPHERE)
			pos.atmos_spawn_air("water_vapor=25;TEMP=[SAUNA_H2O_TEMP]")
	fuel_amount--
	if(fuel_amount <= 0)
		lit = FALSE
		update_steam_particles()
		STOP_PROCESSING(SSobj, src)
		update_icon()

/obj/structure/sauna_oven/proc/update_steam_particles()
	new /obj/effect/temp_visual/small_smoke/halfsecond(get_turf(src))

#undef SAUNA_H2O_TEMP
#undef SAUNA_LOG_FUEL
#undef SAUNA_PAPER_FUEL
#undef SAUNA_MAXIMUM_FUEL
#undef SAUNA_WATER_PER_WATER_UNIT
