// =============================================================================
// FORWARD DECLARATIONS
// =============================================================================
/datum/ai_director/zombie_mission

/obj/effect/landmark/awaymission/blackmesa
	name = "Black Mesa Landmark"
	icon = 'icons/effects/landmarks_static.dmi'
	icon_state = "x2"

/obj/effect/landmark/awaymission/blackmesa/blackops_spawn
	name = "Black Ops Spawn Landmark"

/obj/effect/landmark/awaymission/blackmesa/hecu_spawn
	name = "HECU Spawn Landmark"

/obj/effect/landmark/awaymission/blackmesa/hecu_ghost_spawn
	name = "HECU Ghost Squad Spawn Landmark"

/obj/effect/landmark/awaymission/blackmesa/portal_spawn
	name = "Portal Storm Spawn Landmark"

/datum/round_event_control/blackmesa
	name = "Black Mesa: Base"
	typepath = /datum/round_event/blackmesa
	description = "Base control for Black Mesa events."
	weight = 0
	max_occurrences = 0
	category = EVENT_CATEGORY_INVASION
	var/min_difficulty_level = 0 // Minimum difficulty level required for this event

/datum/round_event/blackmesa
	var/list/excluded_areas = list(
		/area/awaymission/ihategordon/hecu_abandoned_camp,
		/area/awaymission/ihategordon/rocks,
		/area/awaymission/ihategordon/outsideofmesa,
		/area/awaymission/ihategordon/secret_rooms,
		/area/awaymission/ihategordon/tram_tunnel,
		/area/awaymission/ihategordon/entrance
	)

/datum/round_event/blackmesa/setup()
	. = ..()
	// Check if ihategordon is even loaded
	var/list/mission_areas = get_areas(/area/awaymission/ihategordon, TRUE)
	if(!mission_areas.len)
		return EVENT_CANCELLED

/datum/round_event/blackmesa/proc/get_mesa_areas()
	var/list/source_areas = get_areas(/area/awaymission/ihategordon, TRUE)
	var/list/areas = list()

	for(var/area/A in source_areas)
		if(!A || !A.contents.len)
			continue
		var/valid = TRUE
		for(var/EA in excluded_areas)
			if(ispath(A.type, EA))
				valid = FALSE
				break
		if(valid)
			areas += A
	return areas

/datum/round_event/blackmesa/proc/get_random_mesa_turf()
	var/list/areas = get_mesa_areas()
	if(!areas.len)
		return null
	var/list/turfs = list()
	for(var/area/A in areas)
		turfs += get_area_turfs(A)
	if(!turfs.len)
		return null
	for(var/i in 1 to 30)
		var/turf/T = pick(turfs)
		if(T && istype(T, /turf/open) && !is_blocked_turf(T))
			return T
	return null

/datum/round_event/blackmesa/proc/get_player_mesa_turf(ignore_hecu = FALSE, radius_min = 5, radius_max = 12)
	var/list/valid_players = list()
	var/list/valid_areas = get_mesa_areas()

	for(var/mob/living/L in GLOB.player_list)
		if(!L.client || L.stat == DEAD)
			continue
		var/area/A = get_area(L)
		if(!(A in valid_areas))
			continue
		if(ignore_hecu && (FACTION_HECU in L.faction))
			continue
		valid_players += L

	if(!valid_players.len)
		return get_random_mesa_turf()

	for(var/i in 1 to 10)
		var/mob/living/target = pick(valid_players)
		var/turf/center = get_turf(target)
		var/list/nearby_turfs = RANGE_TURFS(rand(radius_min, radius_max), center)
		if(!nearby_turfs.len)
			continue
		var/turf/T = pick(nearby_turfs)
		if(T && istype(T, /turf/open) && !is_blocked_turf(T) && (get_area(T) in valid_areas))
			return T

	return get_random_mesa_turf()

/datum/round_event/blackmesa/proc/get_safe_spawn_turf(turf/T)
	if(!T)
		return null
	if(istype(T, /turf/open) && !is_blocked_turf(T))
		return T
	for(var/dir in GLOB.alldirs)
		var/turf/neighbor = get_step(T, dir)
		if(neighbor && istype(neighbor, /turf/open) && !is_blocked_turf(neighbor))
			return neighbor
	return null

// Event 1: Power Outage
/datum/round_event_control/blackmesa/power_outage
	name = "Black Mesa: Power Outage"
	typepath = /datum/round_event/blackmesa/power_outage
	description = "Causes a temporary power failure in Sector H."
	weight = 5
	max_occurrences = 3
	category = EVENT_CATEGORY_INVASION
	min_difficulty_level = 1

/datum/round_event/blackmesa/power_outage/start()
	var/list/areas = get_mesa_areas()
	if(!areas.len)
		return

	SSblackmesa_events.mesa_announce("Внимание! Зафиксирован критический сбой в энергосети Сектора H. Ожидаемое время восстановления: 60 секунд.", "Power Grid Failure", 'modular_bluemoon/sound/ambience/mesa/lightoff.ogg')

	for(var/area/A in areas)
		A.power_light = FALSE
		A.power_equip = FALSE
		A.power_environ = FALSE
		A.lightswitch = FALSE
		A.power_change()
		addtimer(CALLBACK(src, .proc/restore_power, A), 600)

	addtimer(CALLBACK(src, .proc/announce_restoration), 600)

/datum/round_event/blackmesa/power_outage/proc/announce_restoration()
	SSblackmesa_events.mesa_announce("Внимание! Энергоснабжение Сектора H восстановлено. Все системы функционируют в штатном режиме.", "Power Restored", 'modular_bluemoon/sound/ambience/mesa/BMAS1.ogg')

/datum/round_event/blackmesa/power_outage/proc/restore_power(area/A)
	if(!A)
		return
	A.power_light = TRUE
	A.power_equip = TRUE
	A.power_environ = TRUE
	A.lightswitch = TRUE
	A.power_change()

// Event 2: Portal Storm
/datum/round_event_control/blackmesa/portal_storm
	name = "Black Mesa: Portal Storm (Light)"
	typepath = /datum/round_event/blackmesa/portal_storm/light
	weight = 6
	max_occurrences = 3
	category = EVENT_CATEGORY_INVASION
	min_difficulty_level = 2

/datum/round_event_control/blackmesa/portal_storm/medium
	name = "Black Mesa: Portal Storm (Medium)"
	typepath = /datum/round_event/blackmesa/portal_storm/medium
	weight = 6
	max_occurrences = 2
	category = EVENT_CATEGORY_INVASION
	min_difficulty_level = 4

/datum/round_event_control/blackmesa/portal_storm/dangerous
	name = "Black Mesa: Portal Storm (Dangerous)"
	typepath = /datum/round_event/blackmesa/portal_storm/dangerous
	weight = 6
	max_occurrences = 1
	category = EVENT_CATEGORY_INVASION
	min_difficulty_level = 7

/datum/round_event/blackmesa/portal_storm
	var/spawn_count = 3

/datum/round_event/blackmesa/portal_storm/light
	spawn_count = 4

/datum/round_event/blackmesa/portal_storm/medium
	spawn_count = 8

/datum/round_event/blackmesa/portal_storm/dangerous
	spawn_count = 15

/datum/round_event/blackmesa/portal_storm/start()
	var/warning_text = ""
	var/warning_title = "Portal Storm Warning"
	var/warning_sound = 'modular_bluemoon/sound/ambience/mesa/BMAS2.ogg'
	if(istype(src, /datum/round_event/blackmesa/portal_storm/light))
		warning_text = "Внимание! Зафиксированы незначительные портальные колебания в Секторе H. Сохраняйте спокойствие."
	else if(istype(src, /datum/round_event/blackmesa/portal_storm/medium))
		warning_text = "Внимание! Обнаружены локальные портальные штормы по всему комплексу. Рекомендуется немедленно найти укрытие."
	else if(istype(src, /datum/round_event/blackmesa/portal_storm/dangerous))
		warning_text = "КРИТИЧЕСКАЯ ОПАСНОСТЬ! Зафиксированы множественные портальные прорывы. Сдерживание невозможно. Всем сотрудникам укрыться в безопасных зонах!"
		warning_title = "CRITICAL PORTAL STORM"
		warning_sound = 'modular_bluemoon/sound/ambience/mesa/portalstormalarm.ogg'

	SSblackmesa_events.mesa_announce(warning_text, warning_title, warning_sound)

	var/actual_count = spawn_count
	if(istype(src, /datum/round_event/blackmesa/portal_storm/light))
		actual_count = rand(3, 5)
	else if(istype(src, /datum/round_event/blackmesa/portal_storm/medium))
		actual_count = rand(7, 10)
	else if(istype(src, /datum/round_event/blackmesa/portal_storm/dangerous))
		actual_count = rand(15, 20)

	var/list/landmarks = list()
	for(var/obj/effect/landmark/awaymission/blackmesa/portal_spawn/L in GLOB.landmarks_list)
		landmarks += L

	for(var/i in 1 to actual_count)
		var/turf/T
		if(landmarks.len && prob(70))
			var/obj/effect/landmark/L = pick(landmarks)
			T = get_safe_spawn_turf(get_turf(L))
		else
			T = get_random_mesa_turf()

		if(T)
			spawn_xen(T)

/datum/round_event/blackmesa/portal_storm/proc/spawn_xen(turf/T)
	var/mob_type = pick(list(
		/mob/living/simple_animal/hostile/blackmesa/xen/bullsquid,
		/mob/living/simple_animal/hostile/blackmesa/xen/houndeye,
		/mob/living/simple_animal/hostile/blackmesa/xen/snark,
		/mob/living/simple_animal/hostile/blackmesa/xen/vortigaunt,
		/mob/living/simple_animal/hostile/headcrab/mesa
	))
	var/mob/living/L = new mob_type(T)
	new /obj/effect/temp_visual/dir_setting/ninja/phase(T)
	playsound(T, 'sound/magic/Teleport_app.ogg', 50, TRUE)
	return L

/datum/round_event/blackmesa/portal_storm/tick()
	return

// Event 3: Supply Drop
/datum/round_event_control/blackmesa/supply_drop
	name = "Black Mesa: HECU Supply Drop"
	typepath = /datum/round_event/blackmesa/supply_drop
	weight = 4
	max_occurrences = 2
	category = EVENT_CATEGORY_INVASION
	min_difficulty_level = 1

/datum/round_event/blackmesa/supply_drop
	excluded_areas = list(
		/area/awaymission/ihategordon/hecu_abandoned_camp,
		/area/awaymission/ihategordon/rocks,
		/area/awaymission/ihategordon/outsideofmesa,
		/area/awaymission/ihategordon/secret_rooms,
		/area/awaymission/ihategordon/underground_tunnels,
		/area/awaymission/ihategordon/sectorhnorthoffices,
		/area/awaymission/ihategordon/opposing/end,
		/area/awaymission/ihategordon/opposing/comlpex,
		/area/awaymission/ihategordon/opposing,
		/area/awaymission/ihategordon/outsideofmesa/restricted_zone,
		/area/awaymission/ihategordon/science_tunnel,
		/area/awaymission/ihategordon/gonome,
		/area/awaymission/ihategordon/sec_armory,
		/area/awaymission/ihategordon/tram_tunnel,
		/area/awaymission/ihategordon/entrance,
		/area/awaymission/ihategordon/hecu_camp_hall
	)

/datum/round_event/blackmesa/supply_drop/start()
	SSblackmesa_events.mesa_announce("Внимание! Отправлены капсулы с припасами для сил HECU в Сектор H. Ожидайте прибытия в нескольких точках комплекса.", "Supply Drop", 'modular_bluemoon/sound/ambience/mesa/BMAS3.ogg')

	for(var/i in 1 to 3)
		var/turf/T = get_player_mesa_turf(ignore_hecu = TRUE, radius_min = 15, radius_max = 25)
		if(!T)
			continue

		var/obj/structure/closet/supplypod/pod = new /obj/structure/closet/supplypod/centcompod()
		pod.explosionSize = list(0, 0, 1, 2)
		var/weapon_type = pick(list(
			/obj/item/gun/ballistic/automatic/mp5,
			/obj/item/gun/ballistic/shotgun/spas,
			/obj/item/gun/ballistic/automatic/mp7,
			/obj/item/gun/ballistic/automatic/scar,
			/obj/item/gun/ballistic/automatic/p90
		))
		new weapon_type(pod)
		if(weapon_type == /obj/item/gun/ballistic/automatic/mp5)
			new /obj/item/ammo_box/magazine/mp5(pod)
			new /obj/item/ammo_box/magazine/mp5(pod)
		else if(weapon_type == /obj/item/gun/ballistic/shotgun/spas)
			new /obj/item/ammo_box/shotgun/loaded/buckshot(pod)
		else if(weapon_type == /obj/item/gun/ballistic/automatic/mp7)
			new /obj/item/ammo_box/magazine/mp7(pod)
			new /obj/item/ammo_box/magazine/mp7(pod)
		else if(weapon_type == /obj/item/gun/ballistic/automatic/scar)
			new /obj/item/ammo_box/magazine/scar(pod)
			new /obj/item/ammo_box/magazine/scar(pod)
		else if(weapon_type == /obj/item/gun/ballistic/automatic/p90)
			new /obj/item/ammo_box/magazine/p90(pod)
			new /obj/item/ammo_box/magazine/p90(pod)

		var/obj/item/gps/G = new(pod)
		var/datum/component/gps/item/C = G.GetComponent(/datum/component/gps/item)
		if(C)
			C.gpstag = "HECU Pod [i]"
			G.name = "global positioning system ([C.gpstag])"

		new /obj/effect/pod_landingzone(T, pod)

// Event 9: Sandstorm (Cosmetic)
/datum/round_event_control/blackmesa/sandstorm
	name = "Black Mesa: Sandstorm"
	typepath = /datum/round_event/blackmesa/sandstorm
	weight = 3
	max_occurrences = 2
	category = EVENT_CATEGORY_INVASION
	min_difficulty_level = 0

/datum/round_event/blackmesa/sandstorm/start()
	var/turf/T = get_random_mesa_turf()
	if(!T)
		return

	SSweather.run_weather(/datum/weather/ash_storm/mesa_sandstorm, list(T.z))

/datum/round_event_control/blackmesa/blackops_incursion
	name = "Black Mesa: Black Ops Incursion (Light)"
	typepath = /datum/round_event/blackmesa/blackops_incursion/light
	weight = 7
	max_occurrences = 3
	category = EVENT_CATEGORY_INVASION
	min_difficulty_level = 3

/datum/round_event_control/blackmesa/blackops_incursion/medium
	name = "Black Mesa: Black Ops Incursion (Medium)"
	typepath = /datum/round_event/blackmesa/blackops_incursion/medium
	weight = 7
	max_occurrences = 2
	category = EVENT_CATEGORY_INVASION
	min_difficulty_level = 5

/datum/round_event_control/blackmesa/blackops_incursion/dangerous
	name = "Black Mesa: Black Ops Incursion (Dangerous)"
	typepath = /datum/round_event/blackmesa/blackops_incursion/dangerous
	weight = 7
	max_occurrences = 1
	category = EVENT_CATEGORY_INVASION
	min_difficulty_level = 8

/datum/round_event/blackmesa/blackops_incursion
	var/spawn_count = 3

/datum/round_event/blackmesa/blackops_incursion/light
	spawn_count = 3

/datum/round_event/blackmesa/blackops_incursion/medium
	spawn_count = 6

/datum/round_event/blackmesa/blackops_incursion/dangerous
	spawn_count = 12

/datum/round_event/blackmesa/blackops_incursion/start()
	var/warning_text = ""
	var/warning_title = "Tactical Incursion"
	if(istype(src, /datum/round_event/blackmesa/blackops_incursion/light))
		warning_text = "Внимание! Зафиксирована подозрительная активность в пределах Сектора H. Сохраняйте бдительность."
	else if(istype(src, /datum/round_event/blackmesa/blackops_incursion/medium))
		warning_text = "Внимание! Обнаружены неопознанные тактические группы в Секторе H. Всем сотрудникам службы безопасности доложить о готовности."
	else if(istype(src, /datum/round_event/blackmesa/blackops_incursion/dangerous))
		warning_text = "КРИТИЧЕСКАЯ ОПАСНОСТЬ! Зафиксировано крупномасштабное проникновение оперативников. Всем оставшимся силам HECU сложить оружие и не припятствовать зачистке!"
	warning_title = "BLACK OPS PENETRATION"

	SSblackmesa_events.mesa_announce(warning_text, warning_title, 'modular_bluemoon/sound/ambience/mesa/BMAS2.ogg')

	var/actual_count = spawn_count
	if(istype(src, /datum/round_event/blackmesa/blackops_incursion/light))
		actual_count = rand(2, 3)
	else if(istype(src, /datum/round_event/blackmesa/blackops_incursion/medium))
		actual_count = rand(5, 7)
	else if(istype(src, /datum/round_event/blackmesa/blackops_incursion/dangerous))
		actual_count = rand(10, 14)

	var/list/landmarks = list()
	for(var/obj/effect/landmark/awaymission/blackmesa/blackops_spawn/L in GLOB.landmarks_list)
		landmarks += L

	for(var/i in 1 to actual_count)
		var/turf/T
		if(landmarks.len && prob(80))
			var/obj/effect/landmark/L = pick(landmarks)
			T = get_safe_spawn_turf(get_turf(L))
		else
			T = get_random_mesa_turf()

		if(T)
			spawn_blackops(T)

/datum/round_event/blackmesa/blackops_incursion/proc/spawn_blackops(turf/T)
	var/mob_type = prob(70) ? /mob/living/simple_animal/hostile/blackmesa/blackops/ranged : /mob/living/simple_animal/hostile/blackmesa/blackops
	var/mob/living/L = new mob_type(T)
	new /obj/effect/temp_visual/dir_setting/ninja/phase(T)
	playsound(T, 'sound/magic/blink.ogg', 50, TRUE)
	return L

// Event 5: HECU Reinforcements
/datum/round_event_control/blackmesa/hecu_reinforcements
	name = "Black Mesa: HECU Reinforcements (Light)"
	typepath = /datum/round_event/blackmesa/hecu_reinforcements/light
	weight = 8
	max_occurrences = 3
	category = EVENT_CATEGORY_INVASION
	min_difficulty_level = 1

/datum/round_event_control/blackmesa/hecu_reinforcements/medium
	name = "Black Mesa: HECU Reinforcements (Medium)"
	typepath = /datum/round_event/blackmesa/hecu_reinforcements/medium
	weight = 8
	max_occurrences = 2
	category = EVENT_CATEGORY_INVASION
	min_difficulty_level = 4

/datum/round_event_control/blackmesa/hecu_reinforcements/dangerous
	name = "Black Mesa: HECU Reinforcements (Dangerous)"
	typepath = /datum/round_event/blackmesa/hecu_reinforcements/dangerous
	weight = 8
	max_occurrences = 1
	category = EVENT_CATEGORY_INVASION
	min_difficulty_level = 7

/datum/round_event/blackmesa/hecu_reinforcements
	var/spawn_count = 3

/datum/round_event/blackmesa/hecu_reinforcements/light
	spawn_count = 7

/datum/round_event/blackmesa/hecu_reinforcements/medium
	spawn_count = 10

/datum/round_event/blackmesa/hecu_reinforcements/dangerous
	spawn_count = 17

/datum/round_event/blackmesa/hecu_reinforcements/start()
	var/warning_text = ""
	var/warning_title = "Reinforcements Arriving"
	var/warning_sound = 'modular_bluemoon/sound/ambience/mesa/BMAS3.ogg'
	if(istype(src, /datum/round_event/blackmesa/hecu_reinforcements/light))
		warning_text = "Внимание! Зафиксировано прибытие дополнительного патруля HECU в Сектор H. Всем сотрудникам следовать протоколам безопасности."
	else if(istype(src, /datum/round_event/blackmesa/hecu_reinforcements/medium))
		warning_text = "Внимание! Зафиксировано прибытие тактических подразделений HECU. Соблюдайте осторожность при перемещении по комплексу."
	else if(istype(src, /datum/round_event/blackmesa/hecu_reinforcements/dangerous))
		warning_text = "Внимание! Зафиксировано массированное развертывание сил HECU в Секторе H. Проводится зачистка территории. Всем гражданским лицам оставаться на своих местах до прибытия военных!"
		warning_title = "HECU FULL DEPLOYMENT"
		warning_sound = 'modular_bluemoon/sound/ambience/mesa/hecudanger.ogg'

	SSblackmesa_events.mesa_announce(warning_text, warning_title, warning_sound)

	var/actual_count = spawn_count
	if(istype(src, /datum/round_event/blackmesa/hecu_reinforcements/light))
		actual_count = rand(3, 5)
	else if(istype(src, /datum/round_event/blackmesa/hecu_reinforcements/medium))
		actual_count = rand(7, 10)
	else if(istype(src, /datum/round_event/blackmesa/hecu_reinforcements/dangerous))
		actual_count = rand(15, 20)

	var/list/landmarks = list()
	for(var/obj/effect/landmark/awaymission/blackmesa/hecu_spawn/L in GLOB.landmarks_list)
		landmarks += L

	for(var/i in 1 to actual_count)
		var/turf/T
		if(landmarks.len && prob(80))
			var/obj/effect/landmark/L = pick(landmarks)
			T = get_safe_spawn_turf(get_turf(L))
		else
			T = get_random_mesa_turf()

		if(T)
			spawn_hecu(T)

/datum/round_event/blackmesa/hecu_reinforcements/proc/spawn_hecu(turf/T)
	var/mob_type = pick(list(
		/mob/living/simple_animal/hostile/blackmesa/hecu,
		/mob/living/simple_animal/hostile/blackmesa/hecu/ranged,
		/mob/living/simple_animal/hostile/blackmesa/hecu/ranged/smg
	))
	var/mob/living/L = new mob_type(T)
	new /obj/effect/temp_visual/dir_setting/ninja/phase(T)
	playsound(T, 'sound/effects/phasein.ogg', 50, TRUE)
	return L

// Event 6: HECU Ghost Squad
/datum/round_event_control/blackmesa/hecu_ghost_squad
	name = "Black Mesa: HECU Ghost Squad"
	typepath = /datum/round_event/blackmesa/hecu_ghost_squad
	weight = 5
	max_occurrences = 1
	category = EVENT_CATEGORY_INVASION
	min_difficulty_level = 6

/datum/round_event/blackmesa/hecu_ghost_squad
	var/static/occurred = FALSE

/datum/round_event/blackmesa/hecu_ghost_squad/setup()
	if(occurred)
		return EVENT_CANCELLED
	. = ..()
	if(. == EVENT_CANCELLED)
		return
	occurred = TRUE

/datum/round_event/blackmesa/hecu_ghost_squad/start()
	var/list/landmarks = list()
	for(var/obj/effect/landmark/awaymission/blackmesa/hecu_ghost_spawn/L in GLOB.landmarks_list)
		landmarks += L

	if(!landmarks.len)
		return

	var/obj/effect/landmark/L = pick(landmarks)
	var/turf/T = get_safe_spawn_turf(get_turf(L))
	if(!T)
		return

	SSblackmesa_events.mesa_announce("Внимание! Обнаружен входящий сигнал подкрепления HECU. Ожидайте прибытия элитного подразделения.", "Elite Squad Incoming", 'modular_bluemoon/sound/ambience/mesa/BMAS3.ogg')

	notify_ghosts("HECU Ghost Squad is arriving at Black Mesa!", source = L, action = NOTIFY_ORBIT, header = "HECU Reinforcements")

	addtimer(CALLBACK(src, .proc/spawn_squad, T), 300)

/datum/round_event/blackmesa/hecu_ghost_squad/proc/spawn_squad(turf/T)
	var/list/candidates = pollGhostCandidates("Хотите ли вы стать частью элитного подразделения HECU в Чёрной Мезе?", null, null, 0, 300)
	if(!candidates.len)
		return

	var/list/spawner_types = list(
		/obj/effect/mob_spawn/human/black_mesa/hecu,
		/obj/effect/mob_spawn/human/black_mesa/hecu/breacher,
		/obj/effect/mob_spawn/human/black_mesa/hecu/medic,
		/obj/effect/mob_spawn/human/black_mesa/hecu/engineer,
		/obj/effect/mob_spawn/human/black_mesa/hecu/leader
	)

	var/spawned_count = 0
	shuffle_inplace(candidates)

	for(var/mob/dead/observer/G in candidates)
		if(spawned_count >= 3)
			break
		if(!G || !G.client)
			continue

		var/spawner_type = pick(spawner_types)
		var/obj/effect/mob_spawn/human/S = new spawner_type(T)
		S.attack_ghost(G)
		if(QDELETED(S))
			spawned_count++
		else
			qdel(S)

// Event 7: Orbital Bombardment
/datum/round_event_control/blackmesa/bombardment
	name = "Black Mesa: Orbital Bombardment (Light)"
	typepath = /datum/round_event/blackmesa/bombardment/light
	weight = 5
	max_occurrences = 3
	category = EVENT_CATEGORY_INVASION
	min_difficulty_level = 4

/datum/round_event_control/blackmesa/bombardment/medium
	name = "Black Mesa: Orbital Bombardment (Medium)"
	typepath = /datum/round_event/blackmesa/bombardment/medium
	weight = 5
	max_occurrences = 2
	category = EVENT_CATEGORY_INVASION
	min_difficulty_level = 6

/datum/round_event_control/blackmesa/bombardment/dangerous
	name = "Black Mesa: Orbital Bombardment (Dangerous)"
	typepath = /datum/round_event/blackmesa/bombardment/dangerous
	weight = 5
	max_occurrences = 1
	category = EVENT_CATEGORY_INVASION
	min_difficulty_level = 8

/datum/round_event/blackmesa/bombardment
	var/missile_count = 5
	var/list/explosion_params = list(0, 1, 2, 4)
	var/delay_min = 50
	var/delay_max = 200
	excluded_areas = list(
		/area/awaymission/ihategordon/hecu_abandoned_camp,
		/area/awaymission/ihategordon/rocks,
		/area/awaymission/ihategordon/outsideofmesa,
		/area/awaymission/ihategordon/secret_rooms,
		/area/awaymission/ihategordon/underground_tunnels,
		/area/awaymission/ihategordon/sectorhnorthoffices,
		/area/awaymission/ihategordon/sectorhsecoffices,
		/area/awaymission/ihategordon/opposing/end,
		/area/awaymission/ihategordon/opposing/comlpex,
		/area/awaymission/ihategordon/opposing,
		/area/awaymission/ihategordon/outsideofmesa/restricted_zone,
		/area/awaymission/ihategordon/science_tunnel,
		/area/awaymission/ihategordon/gonome,
		/area/awaymission/ihategordon/sec_armory,
		/area/awaymission/ihategordon/tram_tunnel,
		/area/awaymission/ihategordon/entrance,
		/area/awaymission/ihategordon/dorm_rooms,
		/area/awaymission/ihategordon/hecu_camp_hall,
		/area/awaymission/ihategordon/hecu_camp_medbay,
		/area/awaymission/ihategordon/sci_medbay,
		/area/awaymission/ihategordon/outsideofmesa/hecu_camp
	)

/datum/round_event/blackmesa/bombardment/light
	missile_count = 5
	explosion_params = list(0, 1, 2, 4)

/datum/round_event/blackmesa/bombardment/medium
	missile_count = 12
	explosion_params = list(0, 2, 3, 5)
	delay_min = 30
	delay_max = 100

/datum/round_event/blackmesa/bombardment/dangerous
	missile_count = 25
	explosion_params = list(1, 3, 5, 8)
	delay_min = 20
	delay_max = 60

/datum/round_event/blackmesa/bombardment/start()
	var/warning_text = "Внимание! Зафиксирован запуск тактических ракет класса Воздух-земля. Вероятные точки попадания: Сектор H. Немедленно найти укрытие!"
	var/warning_sound = 'modular_bluemoon/sound/ambience/mesa/BMAS2.ogg'
	if(istype(src, /datum/round_event/blackmesa/bombardment/dangerous))
		warning_text = "КРИТИЧЕСКАЯ ОПАСНОСТЬ! Зафиксирован массированный ракетный удар по Сектору H. Всем сотрудникам немедленно проследовать в укрепленные убежища!"
		warning_sound = 'modular_bluemoon/sound/ambience/mesa/bombardmentalarm.ogg'

	SSblackmesa_events.mesa_announce(warning_text, "Orbital Bombardment Warning", warning_sound)

	var/actual_count = islist(missile_count) ? rand(missile_count[1], missile_count[2]) : missile_count
	if(istype(src, /datum/round_event/blackmesa/bombardment/medium))
		actual_count = rand(10, 15)
	else if(istype(src, /datum/round_event/blackmesa/bombardment/dangerous))
		actual_count = rand(20, 30)
	else
		actual_count = rand(4, 6)

	for(var/i in 1 to actual_count)
		addtimer(CALLBACK(src, .proc/fire_missile), i * rand(delay_min, delay_max))

/datum/round_event/blackmesa/bombardment/proc/fire_missile()
	var/turf/T = get_player_mesa_turf(ignore_hecu = FALSE)
	if(!T)
		return

	var/obj/structure/closet/supplypod/pod = new /obj/structure/closet/supplypod/centcompod(null, STYLE_MISSILE)
	pod.name = "tactical missile"
	pod.desc = "A high-explosive tactical missile."
	pod.explosionSize = explosion_params
	pod.effectMissile = TRUE
	pod.damage = 100
	pod.effectGib = TRUE

	new /obj/effect/pod_landingzone(T, pod)

// Event 8: Medical Supply Drop
/datum/round_event_control/blackmesa/medical_drop
	name = "Black Mesa: HECU Medical Drop"
	typepath = /datum/round_event/blackmesa/medical_drop
	weight = 3
	max_occurrences = 3
	category = EVENT_CATEGORY_INVASION
	min_difficulty_level = 1

/datum/round_event/blackmesa/medical_drop/start()
	SSblackmesa_events.mesa_announce("Внимание! Отправлены медицинские капсулы для передовых групп HECU. Ожидайте прибытия припасов.", "Medical Support", 'modular_bluemoon/sound/ambience/mesa/BMAS3.ogg')

	for(var/i in 1 to 2)
		var/turf/T = get_player_mesa_turf(ignore_hecu = TRUE, radius_min = 15, radius_max = 25)
		if(!T)
			continue

		var/obj/structure/closet/supplypod/pod = new /obj/structure/closet/supplypod/centcompod()
		pod.explosionSize = list(0, 0, 1, 2)

		// Fill with medical supplies
		new /obj/item/stack/medical/bruise_pack(pod)
		new /obj/item/stack/medical/bruise_pack(pod)
		new /obj/item/stack/medical/ointment(pod)
		new /obj/item/stack/medical/ointment(pod)
		new /obj/item/reagent_containers/hypospray/medipen(pod)
		new /obj/item/reagent_containers/hypospray/medipen(pod)
		new /obj/item/reagent_containers/hypospray/medipen/morphine(pod)
		new /obj/item/storage/firstaid/regular(pod)
		new /obj/item/storage/firstaid/toxin(pod)

		var/obj/item/gps/G = new(pod)
		var/datum/component/gps/item/C = G.GetComponent(/datum/component/gps/item)
		if(C)
			C.gpstag = "Medical Pod [i]"
			G.name = "global positioning system ([C.gpstag])"

		new /obj/effect/pod_landingzone(T, pod)

// Event 9: Lockdown
/datum/round_event_control/blackmesa/lockdown
	name = "Black Mesa: Lockdown"
	typepath = /datum/round_event/blackmesa/lockdown
	description = "Triggers a facility lockdown, bolting all doors."
	weight = 4
	max_occurrences = 2
	category = EVENT_CATEGORY_INVASION
	min_difficulty_level = 2

/datum/round_event/blackmesa/lockdown
	var/list/locked_doors = list()
	var/lockdown_duration = 0

/datum/round_event/blackmesa/lockdown/start()
	lockdown_duration = rand(300, 600)
	SSblackmesa_events.mesa_announce("ВНИМАНИЕ! АКТИВИРОВАНА СИСТЕМА АВАРИЙНОЙ БЛОКИРОВКИ! Все двери заблокированы на время экстренной ситуации!", "LOCKDOWN ACTIVATED", 'modular_bluemoon/sound/ambience/mesa/BMAS2.ogg')

	var/list/areas = get_mesa_areas()
	if(!areas.len)
		return

	for(var/area/A in areas)
		var/list/turfs = get_area_turfs(A)
		if(!turfs.len)
			continue
		for(var/turf/T in turfs)
			for(var/obj/machinery/door/D in T.contents)
				if(!D.locked)
					D.locked = TRUE
					D.update_icon()
					locked_doors += D

	addtimer(CALLBACK(src, PROC_REF(end_lockdown)), lockdown_duration)

/datum/round_event/blackmesa/lockdown/proc/end_lockdown()
	for(var/obj/machinery/door/D in locked_doors)
		if(!QDELETED(D))
			D.locked = FALSE
			D.update_icon()

	locked_doors.Cut()
	SSblackmesa_events.mesa_announce("Система аварийной блокировки отключена. Все двери разблокированы.", "Lockdown Ended", 'modular_bluemoon/sound/ambience/mesa/BMAS1.ogg')

// Event 11: Zombie Horde
/datum/round_event_control/blackmesa/zombie_horde
	name = "Black Mesa: Zombie Horde"
	typepath = /datum/round_event/blackmesa/zombie_horde
	description = "Triggers a zombie horde wave through the AI Director."
	weight = 8
	max_occurrences = 3
	category = EVENT_CATEGORY_INVASION
	min_difficulty_level = 0

/datum/round_event/blackmesa/zombie_horde
	start_when = 1
	end_when = 2

/datum/round_event/blackmesa/zombie_horde/start()
	if(!src)
		return
	if(!GLOB.zombie_director)
		return

	var/datum/ai_director/zombie_mission/D = GLOB.zombie_director
	if(!D)
		return

	var/list/alive_players = D.get_alive_players_in_mission()
	if(!alive_players || !alive_players.len)
		return

	var/threat_level = D.calculate_threat_level(alive_players.len)
	if(threat_level <= 0)
		return

	D.spawn_zombie_wave(threat_level, alive_players)
	D.last_wave_time = world.time
	D.current_wave_number++

