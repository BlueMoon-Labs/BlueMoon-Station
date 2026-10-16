#define DERELICT_SATELLITE_MIN_DIST 4
#define DERELICT_SATELLITE_MAX_DIST 10
#define DERELICT_SATELLITE_GPS_TAG "Спутник КС-3"
#define DERELICT_SATELLITE_UNBOLT_TIME (6 SECONDS)
#define DERELICT_SATELLITE_CUT_TIME (8 SECONDS)
#define DERELICT_SATELLITE_METAL 6
#define DERELICT_SATELLITE_RODS 4
#define DERELICT_SATELLITE_EXPORT_VALUE 500
#define DERELICT_SATELLITE_INTACT 0
#define DERELICT_SATELLITE_UNBOLTED 1

/datum/round_event_control/minor_outside/derelict_satellite
	name = "Derelict Satellite"
	description = "У корпуса станции зависает списанный спутник связи. Его разбирают гаечным ключом и сваркой; ядро данных даёт очки исследований в деструктивном анализаторе или продаётся через карго."
	typepath = /datum/round_event/minor_outside/derelict_satellite
	disruption = DIRECTOR_DISRUPTION_AMBIENT
	min_players = 8
	family = "derelict_satellite"
	announcement_title = "Отдел утилизации орбитального имущества NanoTrasen"

/datum/round_event_control/minor_outside/derelict_satellite/find_site(first_only = FALSE)
	return outside_find_hull_space(DERELICT_SATELLITE_MIN_DIST, DERELICT_SATELLITE_MAX_DIST, first_only)

/datum/round_event_control/minor_outside/derelict_satellite/get_announcement_text()
	return "Списанный спутник связи КС-3 сошёл с утилизационной орбиты и завис у корпуса станции, метка в GPS «[DERELICT_SATELLITE_GPS_TAG]». Разберите его на месте: снимите кожух гаечным ключом и срежьте раму сваркой. Утилизационная премия за ядро данных - [SATELLITE_DATA_CORE_POINTS] очков исследований через деструктивный анализатор или [DERELICT_SATELLITE_EXPORT_VALUE] кредитов через экспорт снабжения. Металлолом оставьте себе: на балансе он уже списан."

/datum/round_event/minor_outside/derelict_satellite/spawn_at(turf/site)
	return new /obj/structure/derelict_satellite(site)

/datum/round_event/minor_outside/derelict_satellite/describe_site(turf/site)
	var/area/nearest = outside_nearest_station_area(site, DERELICT_SATELLITE_MAX_DIST + 1)
	return nearest ? "Ближайший отсек: [nearest.name]." : null

/obj/structure/derelict_satellite
	name = "derelict communications satellite"
	desc = "Списанный спутник связи серии КС-3. Тарелка ещё поворачивается на остатках заряда, но передатчик давно молчит."
	icon = 'modular_bluemoon/icons/obj/minor_incidents/derelict_satellite.dmi'
	icon_state = "satellite"
	density = TRUE
	anchored = TRUE
	max_integrity = 200
	var/stage = DERELICT_SATELLITE_INTACT
	var/static/list/salvage_boards = list(
		/obj/item/circuitboard/machine/telecomms/receiver,
		/obj/item/circuitboard/machine/telecomms/relay,
		/obj/item/circuitboard/machine/telecomms/broadcaster,
		/obj/item/circuitboard/computer/comm_monitor,
	)

/obj/structure/derelict_satellite/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/gps, DERELICT_SATELLITE_GPS_TAG)

/obj/structure/derelict_satellite/update_icon_state()
	icon_state = stage == DERELICT_SATELLITE_INTACT ? "satellite" : "satellite_open"
	return ..()

/obj/structure/derelict_satellite/examine(mob/user)
	. = ..()
	if(stage == DERELICT_SATELLITE_INTACT)
		. += span_notice("Кожух держится на болтах: его можно снять гаечным ключом.")
	else
		. += span_notice("Кожух снят, внутри видно ядро данных. Раму можно срезать сваркой.")

/obj/structure/derelict_satellite/wrench_act(mob/living/user, obj/item/tool)
	if(stage != DERELICT_SATELLITE_INTACT)
		to_chat(user, span_notice("Кожух уже снят. Осталось срезать раму сваркой."))
		return TRUE
	to_chat(user, span_notice("Вы начинаете откручивать болты кожуха [src]..."))
	if(tool.use_tool(src, user, DERELICT_SATELLITE_UNBOLT_TIME, volume = 50) && !QDELETED(src))
		unbolt_panels(user)
	return TRUE

/obj/structure/derelict_satellite/welder_act(mob/living/user, obj/item/tool)
	if(stage == DERELICT_SATELLITE_INTACT)
		to_chat(user, span_warning("Сначала снимите кожух гаечным ключом, иначе вы срежете ядро данных вместе с ним."))
		return TRUE
	if(!tool.tool_start_check(user, amount = 1))
		return TRUE
	to_chat(user, span_notice("Вы начинаете срезать раму [src]..."))
	if(tool.use_tool(src, user, DERELICT_SATELLITE_CUT_TIME, amount = 1, volume = 50) && !QDELETED(src))
		dismantle(user)
	return TRUE

/obj/structure/derelict_satellite/proc/unbolt_panels(mob/living/user)
	if(stage != DERELICT_SATELLITE_INTACT)
		return FALSE
	stage = DERELICT_SATELLITE_UNBOLTED
	update_appearance()
	visible_message(span_notice("Кожух [src] отходит, открывая раму и ядро данных."))
	return TRUE

/obj/structure/derelict_satellite/proc/dismantle(mob/living/user)
	if(stage != DERELICT_SATELLITE_UNBOLTED)
		return FALSE
	visible_message(span_notice("Рама [src] распадается на части."))
	log_game("DIRECTOR: Derelict Satellite, спутник разобран ([user ? key_name(user) : "без участия игрока"]) в [AREACOORD(src)].")
	drop_salvage(TRUE)
	qdel(src)
	return TRUE

/obj/structure/derelict_satellite/proc/drop_salvage(full)
	var/turf/drop = drop_location()
	if(!drop)
		return
	new /obj/item/stack/sheet/metal(drop, DERELICT_SATELLITE_METAL)
	new /obj/item/satellite_data_core(drop)
	if(!full)
		return
	new /obj/item/stack/rods(drop, DERELICT_SATELLITE_RODS)
	var/board_type = pick(salvage_boards)
	new board_type(drop)

/obj/structure/derelict_satellite/deconstruct(disassembled = TRUE)
	if(!(flags_1 & NODECONSTRUCT_1))
		drop_salvage(FALSE)
	qdel(src)

/obj/item/satellite_data_core
	name = "satellite data core"
	desc = "Защищённый накопитель телеметрии со списанного спутника связи."
	icon = 'modular_bluemoon/icons/obj/minor_incidents/derelict_satellite.dmi'
	icon_state = "data_core"
	lefthand_file = 'icons/mob/inhands/misc/devices_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/devices_righthand.dmi'
	item_state = "electronic"
	w_class = WEIGHT_CLASS_NORMAL
	drop_sound = 'sound/items/handling/component_drop.ogg'
	pickup_sound = 'sound/items/handling/component_pickup.ogg'

/obj/item/satellite_data_core/examine(mob/user)
	. = ..()
	. += span_notice("Научный отдел извлечёт из него [SATELLITE_DATA_CORE_POINTS] очков исследований в деструктивном анализаторе. Снабжение может отправить его на экспорт за [DERELICT_SATELLITE_EXPORT_VALUE] кредитов.")

/datum/export/satellite_data_core
	cost = DERELICT_SATELLITE_EXPORT_VALUE
	k_elasticity = 0
	unit_name = "satellite data core"
	export_types = list(/obj/item/satellite_data_core)

#undef DERELICT_SATELLITE_MIN_DIST
#undef DERELICT_SATELLITE_MAX_DIST
#undef DERELICT_SATELLITE_GPS_TAG
#undef DERELICT_SATELLITE_UNBOLT_TIME
#undef DERELICT_SATELLITE_CUT_TIME
#undef DERELICT_SATELLITE_METAL
#undef DERELICT_SATELLITE_RODS
#undef DERELICT_SATELLITE_EXPORT_VALUE
#undef DERELICT_SATELLITE_INTACT
#undef DERELICT_SATELLITE_UNBOLTED
