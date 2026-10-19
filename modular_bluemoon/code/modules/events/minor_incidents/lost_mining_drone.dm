#define LOST_DRONE_MIN_DIST 15
#define LOST_DRONE_MAX_DIST 50
#define LOST_DRONE_SITE_ATTEMPTS 200
#define LOST_DRONE_GPS_TAG "MD-7"
#define LOST_DRONE_PRY_TIME (5 SECONDS)
#define LOST_DRONE_REPAIR_STEP_TIME (4 SECONDS)
#define LOST_DRONE_REPAIR_CABLE 5
#define LOST_DRONE_REPAIR_SHEETS 5
#define LOST_DRONE_LURE_MINUTES 4
#define LOST_DRONE_LURE_DELAY (LOST_DRONE_LURE_MINUTES MINUTES)
#define LOST_DRONE_LURE_MIN_DIST 3
#define LOST_DRONE_LURE_MAX_DIST 6
#define LOST_DRONE_LURE_MAX_MOBS 2
#define LOST_DRONE_MINER_JOB "Shaft Miner"
#define LOST_DRONE_MINING_DOCK "mining_away"
#define LOST_DRONE_STAGE_WRECKED 0
#define LOST_DRONE_STAGE_WIRED 1
#define LOST_DRONE_STAGE_PLATED 2

/datum/round_event_control/minor_outside/lost_mining_drone
	name = "Lost Mining Drone"
	typepath = /datum/round_event/minor_outside/lost_mining_drone
	disruption = DIRECTOR_DISRUPTION_AMBIENT
	min_players = 8
	family = "lost_mining_drone"
	announcement_title = "Служба телеметрии горнодобывающего отдела NanoTrasen"

/datum/round_event_control/minor_outside/lost_mining_drone/New()
	description = "Шахтёрский дрон-разведчик MD-7 разбивается в диких пустошах шахтёрского уровня, где водится фауна, в стороне от базы. Шахтёры выбирают: вскрыть грузовой отсек ломом (мешок руды и карта шахтёрских очков) или починить дрона кабелем, листами металла и мультитулом - тогда он станет шахтёрским дроном-компаньоном. Через [LOST_DRONE_LURE_MINUTES] минуты дым от обломков приманивает 1-[LOST_DRONE_LURE_MAX_MOBS] местных существ с открытой поверхности в прямой видимости от обломков, не из помещений."
	announcement_text = "Шахтёрскому отделу: дрон-разведчик MD-7 потерял связь и совершил жёсткую посадку на поверхности в стороне от шахтёрской базы, метка в GPS «MD-7». Заклинивший грузовой отсек с пробами руды и картой шахтёрских очков вскрывается ломом, но после этого дрона уже не починить. Можно и вернуть его в строй: [LOST_DRONE_REPAIR_CABLE] отрезков кабеля, [LOST_DRONE_REPAIR_SHEETS] листов металла и мультитул - и MD-7 станет вашим дроном-компаньоном, а груз останется заперт. Поторопитесь: примерно через [LOST_DRONE_LURE_MINUTES] минуты дым от обломков привлечёт местную фауну."
	return ..()

/datum/round_event_control/minor_outside/lost_mining_drone/director_preflight()
	if(!director_has_living_role(list(LOST_DRONE_MINER_JOB)))
		director_preflight_detail = "На смене нет живых шахтёров."
		director_preflight_failure = director_preflight_detail
		return FALSE
	return ..()

/datum/round_event_control/minor_outside/lost_mining_drone/find_site(first_only = FALSE)
	for(var/turf/anchor as anything in lost_drone_base_anchors())
		for(var/attempt in 1 to LOST_DRONE_SITE_ATTEMPTS)
			var/distance = rand(LOST_DRONE_MIN_DIST, LOST_DRONE_MAX_DIST)
			var/angle = rand(0, 359)
			var/turf/candidate = locate(clamp(round(anchor.x + distance * cos(angle)), 1, world.maxx), clamp(round(anchor.y + distance * sin(angle)), 1, world.maxy), anchor.z)
			if(lost_drone_valid_site(candidate))
				return candidate
	return null

/datum/round_event/minor_outside/lost_mining_drone/spawn_at(turf/site)
	return new /obj/structure/crashed_mining_drone(site)

/// Точка отсчёта - стоянка шахтёрского шаттла, без неё - помещения шахтёрской базы.
/proc/lost_drone_base_anchors()
	var/list/anchors = list()
	var/obj/docking_port/stationary/dock = SSshuttle.getDock(LOST_DRONE_MINING_DOCK)
	if(dock && is_mining_level(dock.z))
		anchors += get_turf(dock)
		return anchors
	var/static/list/base_areas = typecacheof(list(/area/mine/lobby, /area/mine/production, /area/mine/living_quarters, /area/mine/storage, /area/mine/eva))
	for(var/area/base_area as anything in GLOB.sortedAreas)
		if(!is_type_in_typecache(base_area, base_areas) || !base_area.z || !is_mining_level(base_area.z))
			continue
		var/turf/corner = locate(base_area.x, base_area.y, base_area.z)
		if(corner)
			anchors += corner
	return anchors

/// Открытая поверхность под небом, где водится фауна, без лавы, пропастей и руин рядом.
/proc/lost_drone_valid_site(turf/candidate)
	if(!lost_drone_open_ground(candidate))
		return FALSE
	var/area/site_area = candidate.loc
	if(!lost_drone_wild_area(site_area) || istype(site_area, /area/ruin))
		return FALSE
	for(var/turf/nearby as anything in RANGE_TURFS(1, candidate))
		if(islava(nearby) || ischasm(nearby))
			return FALSE
	return TRUE

/// Поверхность под небом, где сама карта расселяет местную фауну; база и её окрестности сюда не входят.
/proc/lost_drone_wild_area(area/location)
	return location?.outdoors && (location.area_flags & MOB_SPAWN_ALLOWED)

/proc/lost_drone_open_ground(turf/candidate)
	if(!isopenturf(candidate) || isspaceturf(candidate) || islava(candidate) || ischasm(candidate) || istype(candidate, /turf/open/water) || isopenspaceturf(candidate))
		return FALSE
	return !candidate.is_blocked_turf()

/proc/lost_drone_fauna_type(z_level)
	if(SSmapping.level_trait(z_level, ZTRAIT_ICE_RUINS) || SSmapping.level_trait(z_level, ZTRAIT_ICE_RUINS_UNDERGROUND))
		return /mob/living/simple_animal/hostile/asteroid/wolf
	if(SSmapping.level_trait(z_level, ZTRAIT_LAVA_RUINS))
		return /mob/living/simple_animal/hostile/asteroid/basilisk/watcher
	return /mob/living/simple_animal/hostile/asteroid/basilisk

/particles/crashed_drone_smoke
	icon = 'icons/effects/particles/smoke.dmi'
	icon_state = list("smoke_1" = 1, "smoke_2" = 1, "smoke_3" = 1)
	width = 96
	height = 128
	count = 18
	spawning = 0.4
	lifespan = 24
	fade = 14
	fadein = 4
	color = "#6b6661"
	position = generator("box", list(-5, 2, 0), list(3, 6, 0))
	velocity = generator("vector", list(-0.1, 0.55, 0), list(0.15, 0.85, 0))
	drift = generator("vector", list(-0.03, 0, 0), list(0.05, 0.02, 0))
	scale = generator("vector", list(0.25, 0.25), list(0.4, 0.4), NORMAL_RAND)
	grow = list(0.02, 0.02)
	spin = generator("num", -3, 3)

/obj/structure/crashed_mining_drone
	name = "crashed survey drone"
	desc = "Обломки шахтёрского дрона-разведчика MD-7. Корпус смят при посадке, из пробитого бока тянется дым, но грузовой отсек и ходовая уцелели."
	icon = 'modular_bluemoon/icons/obj/minor_incidents/lost_mining_drone.dmi'
	icon_state = "drone_wreck"
	density = TRUE
	anchored = TRUE
	max_integrity = 200
	var/cargo_open = FALSE
	var/repair_stage = LOST_DRONE_STAGE_WRECKED
	var/busy = FALSE
	var/lure_timer
	var/static/list/cargo_ore = list(
		/obj/item/stack/ore/iron = 20,
		/obj/item/stack/ore/silver = 6,
		/obj/item/stack/ore/gold = 4,
		/obj/item/stack/ore/plasma = 5,
		/obj/item/stack/ore/titanium = 3,
	)

/obj/structure/crashed_mining_drone/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/gps, LOST_DRONE_GPS_TAG)
	particles = new /particles/crashed_drone_smoke
	lure_timer = addtimer(CALLBACK(src, PROC_REF(lure_fauna)), LOST_DRONE_LURE_DELAY, TIMER_STOPPABLE)

/obj/structure/crashed_mining_drone/Destroy()
	deltimer(lure_timer)
	lure_timer = null
	particles = null
	return ..()

/obj/structure/crashed_mining_drone/update_icon_state()
	icon_state = cargo_open ? "drone_wreck_open" : "drone_wreck"
	return ..()

/obj/structure/crashed_mining_drone/examine(mob/user)
	. = ..()
	if(cargo_open)
		. += span_notice("Грузовой отсек вскрыт и пуст, рама смята: дрона уже не починить.")
		return
	. += span_notice("Крышку грузового отсека заклинило. Её можно вскрыть ломом, но после этого дрона уже не починить.")
	. += span_notice("Или почините дрона - он станет шахтёрским компаньоном, а груз останется заперт. Дальше нужно: [next_repair_step()].")
	if(lure_timer)
		. += span_warning("Дым поднимается столбом и скоро привлечёт местную фауну.")

/obj/structure/crashed_mining_drone/proc/next_repair_step()
	switch(repair_stage)
		if(LOST_DRONE_STAGE_WRECKED)
			return "заменить проводку ([LOST_DRONE_REPAIR_CABLE] отрезков кабеля)"
		if(LOST_DRONE_STAGE_WIRED)
			return "залатать корпус ([LOST_DRONE_REPAIR_SHEETS] листов металла)"
	return "перезапустить контроллер мультитулом"

/obj/structure/crashed_mining_drone/crowbar_act(mob/living/user, obj/item/tool)
	if(cargo_open)
		to_chat(user, span_notice("Грузовой отсек [src] уже вскрыт."))
		return TRUE
	if(busy)
		to_chat(user, span_warning("С дроном уже кто-то работает."))
		return TRUE
	busy = TRUE
	user.visible_message(span_notice("[user] поддевает крышку грузового отсека [src]."), span_notice("Вы поддеваете заклинившую крышку грузового отсека..."))
	if(tool.use_tool(src, user, LOST_DRONE_PRY_TIME, volume = 50) && !QDELETED(src))
		open_cargo(user)
	busy = FALSE
	return TRUE

/obj/structure/crashed_mining_drone/attackby(obj/item/item, mob/living/user, params)
	if(cargo_open)
		return ..()
	if(istype(item, /obj/item/stack/cable_coil) && repair_stage == LOST_DRONE_STAGE_WRECKED)
		repair_with(user, item, LOST_DRONE_REPAIR_CABLE, "меняет обгоревшую проводку")
		return TRUE
	if(istype(item, /obj/item/stack/sheet/metal) && repair_stage == LOST_DRONE_STAGE_WIRED)
		repair_with(user, item, LOST_DRONE_REPAIR_SHEETS, "латает пробитый корпус")
		return TRUE
	return ..()

/obj/structure/crashed_mining_drone/proc/repair_with(mob/living/user, obj/item/stack/material, amount, action_text)
	if(busy)
		to_chat(user, span_warning("С дроном уже кто-то работает."))
		return FALSE
	if(material.get_amount() < amount)
		to_chat(user, span_warning("Нужно [amount] шт., а у вас [material.get_amount()]."))
		return FALSE
	var/stage = repair_stage
	busy = TRUE
	user.visible_message(span_notice("[user] [action_text] [src]."), span_notice("Вы начинаете чинить [src]..."))
	var/success = do_after(user, LOST_DRONE_REPAIR_STEP_TIME, src)
	busy = FALSE
	if(!success || QDELETED(src) || cargo_open || repair_stage != stage || !material.use(amount))
		return FALSE
	return advance_repair(user)

/obj/structure/crashed_mining_drone/proc/advance_repair(mob/living/user)
	if(cargo_open || repair_stage >= LOST_DRONE_STAGE_PLATED)
		return FALSE
	repair_stage++
	playsound(src, 'sound/items/deconstruct.ogg', 40, TRUE)
	to_chat(user, span_notice("Готово. Дальше нужно [next_repair_step()]."))
	return TRUE

/obj/structure/crashed_mining_drone/multitool_act(mob/living/user, obj/item/tool)
	if(cargo_open)
		to_chat(user, span_warning("Рама [src] смята при вскрытии отсека: контроллер не запустится."))
		return TRUE
	if(repair_stage < LOST_DRONE_STAGE_PLATED)
		to_chat(user, span_warning("Контроллер не запустится, пока не сделано: [next_repair_step()]."))
		return TRUE
	if(busy)
		to_chat(user, span_warning("С дроном уже кто-то работает."))
		return TRUE
	busy = TRUE
	user.visible_message(span_notice("[user] подключает [tool] к контроллеру [src] и запускает перезагрузку."), span_notice("Вы запускаете перезагрузку контроллера..."))
	var/success = tool.use_tool(src, user, LOST_DRONE_REPAIR_STEP_TIME, volume = 50)
	busy = FALSE
	if(success && !QDELETED(src))
		reboot(user)
	return TRUE

/// Починенный дрон встаёт на ходовую и становится обычным шахтёрским дроном-компаньоном.
/obj/structure/crashed_mining_drone/proc/reboot(mob/living/user)
	if(cargo_open || repair_stage < LOST_DRONE_STAGE_PLATED)
		return null
	var/mob/living/simple_animal/hostile/mining_drone/minebot = new(drop_location())
	minebot.name = "MD-7 minebot"
	minebot.real_name = minebot.name
	do_sparks(3, TRUE, src)
	playsound(minebot, 'sound/machines/ping.ogg', 50, FALSE)
	minebot.visible_message(span_notice("[minebot] со скрежетом поднимается на ходовую, мигает фарами и пищит: «Связь восстановлена. Готов к работе»."))
	log_game("DIRECTOR: Lost Mining Drone, дрон починен и запущен ([user ? key_name(user) : "без участия игрока"]) в [AREACOORD(src)].")
	qdel(src)
	return minebot

/obj/structure/crashed_mining_drone/proc/open_cargo(mob/living/user)
	if(cargo_open)
		return FALSE
	cargo_open = TRUE
	deltimer(lure_timer)
	lure_timer = null
	var/turf/drop = drop_location()
	var/obj/item/storage/bag/ore/satchel = new(drop)
	for(var/ore_type in cargo_ore)
		new ore_type(satchel, cargo_ore[ore_type])
	new /obj/item/card/mining_point_card(drop)
	qdel(GetComponent(/datum/component/gps))
	particles = null
	playsound(src, 'sound/machines/airlockforced.ogg', 40, TRUE)
	visible_message(span_notice("Крышка грузового отсека [src] со скрежетом отходит, сминая раму. Внутри мешок с рудой и карта шахтёрских очков."))
	update_appearance()
	log_game("DIRECTOR: Lost Mining Drone, грузовой отсек вскрыт ([user ? key_name(user) : "без участия игрока"]) в [AREACOORD(src)].")
	return TRUE

/// Дым над нетронутыми обломками приманивает местных существ из округи, которая видна от обломков.
/obj/structure/crashed_mining_drone/proc/lure_fauna()
	lure_timer = null
	if(cargo_open)
		return list()
	var/list/spots = list()
	for(var/turf/candidate as anything in RANGE_TURFS(LOST_DRONE_LURE_MAX_DIST, src))
		if(get_dist(candidate, src) < LOST_DRONE_LURE_MIN_DIST || !lost_drone_open_ground(candidate) || !lost_drone_wild_area(candidate.loc))
			continue
		if(can_see(src, candidate, LOST_DRONE_LURE_MAX_DIST))
			spots += candidate
	var/fauna_type = lost_drone_fauna_type(z)
	var/list/lured = list()
	for(var/lured_number in 1 to rand(1, LOST_DRONE_LURE_MAX_MOBS))
		if(!length(spots))
			break
		lured += new fauna_type(pick_n_take(spots))
	if(length(lured))
		visible_message(span_warning("На дым над [src] из пустошей выходят местные существа."))
	log_game("DIRECTOR: Lost Mining Drone, дым приманил существ: [length(lured)] ([fauna_type]) в [AREACOORD(src)].")
	return lured

#undef LOST_DRONE_MIN_DIST
#undef LOST_DRONE_MAX_DIST
#undef LOST_DRONE_SITE_ATTEMPTS
#undef LOST_DRONE_GPS_TAG
#undef LOST_DRONE_PRY_TIME
#undef LOST_DRONE_REPAIR_STEP_TIME
#undef LOST_DRONE_REPAIR_CABLE
#undef LOST_DRONE_REPAIR_SHEETS
#undef LOST_DRONE_LURE_MINUTES
#undef LOST_DRONE_LURE_DELAY
#undef LOST_DRONE_LURE_MIN_DIST
#undef LOST_DRONE_LURE_MAX_DIST
#undef LOST_DRONE_LURE_MAX_MOBS
#undef LOST_DRONE_MINER_JOB
#undef LOST_DRONE_MINING_DOCK
#undef LOST_DRONE_STAGE_WRECKED
#undef LOST_DRONE_STAGE_WIRED
#undef LOST_DRONE_STAGE_PLATED
