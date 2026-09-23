#define HERETIC_LOCK_RANGE 5
#define HERETIC_LOCK_COURT_RADIUS 1
#define HERETIC_LOCK_SEAL_LIFETIME (30 SECONDS)
#define HERETIC_LOCK_BASE_LIMIT 4
#define HERETIC_LOCK_UPGRADED_LIMIT 10
#define HERETIC_LOCK_ASCENDED_LIMIT 16
#define HERETIC_LOCK_THRESHOLD_RANGE 20
#define HERETIC_LOCK_THRESHOLD_LIFETIME (3 MINUTES)
#define HERETIC_LOCK_THRESHOLD_LIMIT 2
#define HERETIC_LOCK_THRESHOLD_COOLDOWN (15 SECONDS)
#define HERETIC_LOCK_SELECTIVE_RELEASE_COOLDOWN (15 SECONDS)
#define HERETIC_LOCK_GRASP_BOLT_TIME (20 SECONDS)
#define HERETIC_LOCK_HARVEST_COOLDOWN (20 SECONDS)
#define HERETIC_LOCK_KEEPER_SEAL_DELAY (0.2 SECONDS)
#define HERETIC_LOCK_KEEPER_CLOSE_WAIT (1 SECONDS)
#define HERETIC_LOCK_PORTAL_OPEN (0.3 SECONDS)
#define HERETIC_LOCK_PORTAL_CLOSE (0.35 SECONDS)
#define HERETIC_LOCK_PORTAL_FAILSAFE (5 SECONDS)
#define HERETIC_LOCK_PORTAL_START 0.2
#define HERETIC_LOCK_PORTAL_FLARE 1.25
#define HERETIC_LOCK_PORTAL_FLARE_SHARE 0.3
#define HERETIC_LOCK_PORTAL_TEETH 8
#define HERETIC_LOCK_PORTAL_NOTCH (0.25 SECONDS)
#define HERETIC_LOCK_PORTAL_CLICK (0.08 SECONDS)
#define HERETIC_LOCK_PORTAL_LIGHT_RANGE 2
#define HERETIC_LOCK_PORTAL_LIGHT_POWER 1.2
#define HERETIC_LOCK_THREAD_SNAP (0.3 SECONDS)
#define HERETIC_LOCK_DISSOLVE_TIME (0.35 SECONDS)
#define HERETIC_LOCK_DISSOLVE_SQUEEZE 0.55
#define HERETIC_LOCK_DISSOLVE_STRETCH 1.3
#define HERETIC_LOCK_DISSOLVE_RISE 8
#define HERETIC_LOCK_REFORM_TIME (0.4 SECONDS)
#define HERETIC_LOCK_REFORM_WIDE 1.5
#define HERETIC_LOCK_REFORM_FLAT 0.6
#define HERETIC_LOCK_REFORM_RADIUS 40
#define HERETIC_LOCK_REFORM_ARMS 5
#define HERETIC_LOCK_REFORM_SWIRL 0.5
#define HERETIC_LOCK_GHOST_ALPHA 200
#define HERETIC_LOCK_STREAM_TIME (0.2 SECONDS)
#define HERETIC_LOCK_ARRIVAL_FLASH_RANGE 3
#define HERETIC_LOCK_ARRIVAL_FLASH_POWER 1
#define HERETIC_LOCK_ARRIVAL_FLASH_TIME (0.4 SECONDS)
#define HERETIC_LOCK_CLICK_TIME (0.65 SECONDS)
#define HERETIC_LOCK_KEY_HEIGHT 24
#define HERETIC_LOCK_KEY_SINK 6
#define HERETIC_LOCK_KEY_APPEAR (0.25 SECONDS)
#define HERETIC_LOCK_KEY_HOLD (0.42 SECONDS)
#define HERETIC_LOCK_KEY_RELEASE (0.35 SECONDS)
#define HERETIC_LOCK_KEY_FAILSAFE (4 SECONDS)
#define HERETIC_LOCK_KEY_START 0.5
#define HERETIC_LOCK_KEY_SINK_SCALE 0.6
#define HERETIC_LOCK_HOUSE_WAVE_RADIUS 3
#define HERETIC_LOCK_HOUSE_WAVE_TIME (0.8 SECONDS)
#define HERETIC_LOCK_HOUSE_FLASH_RANGE 4
#define HERETIC_LOCK_HOUSE_FLASH_POWER 2
#define HERETIC_LOCK_HOUSE_FLASH_TIME (0.5 SECONDS)
#define HERETIC_LOCK_HOUSE_QUAKE 0.12
#define HERETIC_LOCK_HOUSE_QUAKE_RADIUS 7
#define HERETIC_LOCK_HOUSE_QUAKE_TIME (0.35 SECONDS)
#define HERETIC_LOCK_HOUSE_RISE (0.25 SECONDS)
#define HERETIC_LOCK_HOUSE_RISE_SWEEP (0.3 SECONDS)
#define HERETIC_LOCK_HOUSE_GLINT_SWEEP (0.6 SECONDS)
#define HERETIC_LOCK_HOUSE_GLINT_TIME (0.3 SECONDS)
#define HERETIC_LOCK_SEAL_SQUASH 0.15

/datum/heretic_path/lock
	id = PATH_LOCK
	deed_type = /datum/heretic_deed/lock
	name = "Замок"
	desc = "Перестраивайте поле боя печатями и соединяйте шлюзы тайными переходами для себя."
	strengths = "Разделение противников, выстрелы через свои печати и переходы между подготовленными порогами. Вознёсшийся выходит из любого шлюза в пятнадцати клетках, а запитанные шлюзы за его спиной сами закрываются на болты на 8 секунд."
	weaknesses = "Печати и пороги можно разбить. Переход требует подготовки, свободного выхода и ключа; антимагия пропускает сквозь печати. Против вознёсшегося работает инженерия: болты за ним поднимают ИИ, пульт шлюзов или мультитул, обесточенный шлюз за ним не запирается, а заваренный или сломанный шлюз ему не выход. Нулевой жезл сразу разбивает печати и пороги."
	knowledge = list(
		/datum/eldritch_knowledge/base_lock,
		/datum/eldritch_knowledge/lock_grasp,
		/datum/eldritch_knowledge/spell/lock_bolt,
		/datum/eldritch_knowledge/lock_mark,
		/datum/eldritch_knowledge/lock_key,
		/datum/eldritch_knowledge/lock_blade_upgrade,
		/datum/eldritch_knowledge/spell/lock_release,
		/datum/eldritch_knowledge/lock_hinges,
		/datum/eldritch_knowledge/spell/lock_court,
		/datum/eldritch_knowledge/final_eldritch/lock_final,
	)

/datum/eldritch_knowledge/base_lock
	name = "Тайна привратника"
	desc = "Открывает Путь Замка: отрезайте противникам путь разрушаемыми печатями, через которые сами проходите свободно. «Запечатать проход» создаёт преграду на 30 секунд за один ключ; снятие рукой на намерении помощи возвращает ключ. Вы начинаете с двумя ключами, а нож и лом создают клинок-ключ, работающий как лом."
	gain_text = "Любая стена однажды была дверью. Любая дверь помнит свой ключ."
	route = PATH_LOCK
	required_atoms = list(/obj/item/kitchen/knife, /obj/item/crowbar)
	result_atoms = list(/obj/item/melee/sickly_blade/lock)
	combat_resource = 2
	combat_resource_max = 4
	combat_resource_name = "Ключи"
	combat_resource_desc = "Метка даёт ключ при ударе клинком. Открытая ладонь раз в 20 секунд добывает ключ, открывая закрытый шлюз или запертый шкаф либо запирая шлюз на намерении вреда. Одиночная печать стоит 1 ключ: снимите её рукой на намерении помощи, чтобы вернуть его. Бесплатные печати ключей не дают. Переход ритуальным ключом между связанными порогами стоит 1 ключ; Замкнутый двор — 2."
	grasp_visual = /obj/effect/temp_visual/heretic_lock
	grasp_sound = 'modular_bluemoon/sound/heretic/lock_knock.ogg'
	grasp_catchphrase = "SPY'NA UZ'SIDARO"
	var/mob/living/lock_body
	var/list/seals = list()
	var/list/marks = list()
	var/list/obj/structure/heretic_lock_threshold/thresholds = list()
	var/obj/effect/proc_holder/spell/pointed/heretic_lock/seal/seal_spell
	var/ascension_active = FALSE
	var/court_busy = FALSE
	var/court_generation = 0
	/// Шлюзы, закрытые хваткой: шлюз -> таймер снятия болтов.
	var/list/grasp_bolts = list()

/datum/eldritch_knowledge/base_lock/on_body_gain(mob/living/user)
	if(!user?.mind || lock_body == user)
		return
	if(lock_body)
		on_body_lose(lock_body)
	lock_body = user
	RegisterSignal(user, COMSIG_PARENT_QDELETING, PROC_REF(on_body_deleted))
	seal_spell = new
	user.mind.AddSpell(seal_spell)

/datum/eldritch_knowledge/base_lock/on_body_lose(mob/living/user)
	if(lock_body)
		UnregisterSignal(lock_body, COMSIG_PARENT_QDELETING)
	lock_body = null
	QDEL_NULL(seal_spell)
	clear_lock_effects()

/datum/eldritch_knowledge/base_lock/on_death(mob/user)
	clear_lock_effects()

/datum/eldritch_knowledge/base_lock/Destroy()
	on_body_lose(lock_body)
	for(var/obj/machinery/door/airlock/door as anything in grasp_bolts.Copy())
		release_grasp_bolt(door)
	return ..()

/datum/eldritch_knowledge/base_lock/proc/on_body_deleted(datum/source)
	SIGNAL_HANDLER
	on_body_lose(lock_body)

/datum/eldritch_knowledge/base_lock/proc/clear_lock_effects()
	court_generation++
	court_busy = FALSE
	for(var/obj/structure/heretic_lock_seal/seal as anything in seals.Copy())
		qdel(seal)
	for(var/datum/status_effect/eldritch/lock/mark as anything in marks.Copy())
		qdel(mark)
	seals.Cut()
	marks.Cut()
	clear_thresholds()

/datum/eldritch_knowledge/base_lock/proc/clear_thresholds()
	for(var/obj/structure/heretic_lock_threshold/threshold as anything in thresholds.Copy())
		qdel(threshold)
	thresholds.Cut()

/datum/eldritch_knowledge/base_lock/proc/valid_threshold_door(obj/machinery/door/airlock/door)
	return istype(door) && !QDELETED(door) && isturf(door.loc) && !door.welded && !door.operating && !(door.resistance_flags & INDESTRUCTIBLE)

/datum/eldritch_knowledge/base_lock/proc/bind_threshold(mob/living/user, obj/machinery/door/airlock/door)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/turf/place = get_turf(user)
	if(!valid_user(user) || heretic.role_removed || heretic.selected_path != PATH_LOCK || !heretic.get_knowledge(/datum/eldritch_knowledge/lock_key) || !valid_threshold_door(door) || !user.Adjacent(door) || !(get_dir(door, user) in GLOB.cardinals) || !istype(place, /turf/open/floor) || place.is_blocked_turf(source_atom = user))
		return FALSE
	var/area/place_area = get_area(place)
	if(place_area.area_flags & NOTELEPORT)
		return FALSE
	for(var/obj/structure/heretic_lock_threshold/threshold as anything in thresholds)
		if(threshold.door_ref?.resolve() == door)
			qdel(threshold)
			to_chat(user, span_notice("Метка у этого шлюза снята. Для перехода нужны две метки; используйте намерение вреда, чтобы перейти, а не снять метку."))
			return TRUE
	if(length(thresholds) == 1)
		var/obj/structure/heretic_lock_threshold/first = thresholds[1]
		if(first.z != user.z || get_dist(first, user) > HERETIC_LOCK_THRESHOLD_RANGE || first.loc == user.loc)
			return FALSE
	if(length(thresholds) >= HERETIC_LOCK_THRESHOLD_LIMIT)
		clear_thresholds()
	var/obj/structure/heretic_lock_threshold/created = new(place, src, door)
	thresholds += created
	to_chat(user, span_eldritch((length(thresholds) == HERETIC_LOCK_THRESHOLD_LIMIT ? "Две метки связаны. Встаньте на золотую скважину на полу, включите намерение вреда и нажмите ключом на шлюз рядом с этой меткой. Стойте неподвижно 2 секунды; переход стоит 1 ключ." : "Первая метка появилась на полу под вами. Встаньте рядом с другим шлюзом, не по диагонали, и нажмите на него ключом на намерении помощи. Второй шлюз должен быть в пределах двадцати клеток.")))
	return TRUE

/datum/eldritch_knowledge/base_lock/proc/reject_threshold(mob/living/user, reason, silent)
	if(!silent)
		to_chat(user, span_warning("Переход не открылся. [reason]"))
	return null

/datum/eldritch_knowledge/base_lock/proc/threshold_destination(mob/living/user, obj/machinery/door/airlock/door, silent = TRUE)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(!valid_user(user) || heretic.role_removed || heretic.selected_path != PATH_LOCK)
		return reject_threshold(user, "Вы сейчас не можете пользоваться силой Замка.", silent)
	if(user.buckled || user.anchored || HAS_TRAIT(user, TRAIT_NO_TELEPORT))
		return reject_threshold(user, "Вас удерживает крепление или запрет телепортации.", silent)
	if(length(thresholds) != HERETIC_LOCK_THRESHOLD_LIMIT)
		return reject_threshold(user, "Связано меток: [length(thresholds)]/2. На намерении помощи нажмите ключом на два разных шлюза, стоя рядом с каждым. Метки живут 3 минуты.", silent)
	if(!valid_threshold_door(door))
		return reject_threshold(user, "Выбранный шлюз заварен, движется или не допускает переход.", silent)
	if(!user.Adjacent(door))
		return reject_threshold(user, "Встаньте на свою метку рядом с выбранным шлюзом.", silent)
	var/obj/structure/heretic_lock_threshold/entrance
	var/obj/structure/heretic_lock_threshold/destination
	for(var/obj/structure/heretic_lock_threshold/threshold as anything in thresholds)
		if(threshold.door_ref?.resolve() == door)
			entrance = threshold
		else
			destination = threshold
	if(QDELETED(entrance) || QDELETED(destination))
		return reject_threshold(user, "Этот шлюз не связан с вашей парой меток. Нажмите на шлюз у золотой скважины.", silent)
	if(user.loc != entrance.loc)
		return reject_threshold(user, "Встаньте точно на золотую скважину на полу с той стороны шлюза, где вы оставили метку, затем нажмите ключом на шлюз на намерении вреда.", silent)
	if(door.loc != entrance.door_place || !valid_threshold_door(destination.door_ref?.resolve()))
		return reject_threshold(user, "Входной шлюз перемещён либо выходной шлюз заварен, движется или разрушен.", silent)
	var/obj/machinery/door/airlock/exit_door = destination.door_ref.resolve()
	if(exit_door.loc != destination.door_place || !exit_door.Adjacent(destination) || !(get_dir(exit_door, destination) in GLOB.cardinals))
		return reject_threshold(user, "Выходной шлюз перемещён. Создайте пару меток заново.", silent)
	var/turf/landing = get_turf(destination)
	if(!istype(landing, /turf/open/floor) || landing.z != user.z || get_dist(user, landing) > HERETIC_LOCK_THRESHOLD_RANGE || landing == user.loc)
		return reject_threshold(user, "Метки должны стоять на разных клетках пола, на одном уровне и не дальше двадцати клеток друг от друга.", silent)
	if(landing.is_blocked_turf(source_atom = user))
		return reject_threshold(user, "Клетка выходной метки занята существом или преградой. Освободите выход.", silent)
	var/area/origin_area = get_area(user)
	var/area/destination_area = get_area(landing)
	if(origin_area.area_flags & NOTELEPORT || destination_area.area_flags & NOTELEPORT)
		return reject_threshold(user, "В помещении входа или выхода запрещена телепортация.", silent)
	return destination

/obj/structure/heretic_lock_threshold
	name = "linked threshold"
	desc = "Золотая скважина у шлюза связана с другим порогом. Владелец ритуального ключа может перейти между ними. Разбейте скважину, коснитесь нулевым жезлом, заварите шлюз или перекройте выход, чтобы помешать переходу. Порог исчезнет через три минуты."
	icon = 'modular_bluemoon/icons/obj/heretic_lock_effects.dmi'
	icon_state = "lock_warning"
	anchored = TRUE
	density = FALSE
	max_integrity = 30
	layer = ABOVE_OPEN_TURF_LAYER
	var/datum/weakref/knowledge_ref
	var/datum/weakref/door_ref
	var/turf/door_place
	var/expiry_timer

/obj/structure/heretic_lock_threshold/Initialize(mapload, datum/eldritch_knowledge/base_lock/knowledge, obj/machinery/door/airlock/door)
	. = ..()
	if(QDELETED(knowledge) || QDELETED(door))
		return INITIALIZE_HINT_QDEL
	knowledge_ref = WEAKREF(knowledge)
	door_ref = WEAKREF(door)
	door_place = get_turf(door)
	RegisterSignal(door, COMSIG_PARENT_QDELETING, PROC_REF(on_door_deleted))
	expiry_timer = QDEL_IN_STOPPABLE(src, HERETIC_LOCK_THRESHOLD_LIFETIME)
	playsound(src, 'modular_bluemoon/sound/heretic/lock_knock.ogg', 35, TRUE)

/obj/structure/heretic_lock_threshold/proc/on_door_deleted(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/obj/structure/heretic_lock_threshold/Destroy()
	deltimer(expiry_timer)
	var/obj/machinery/door/airlock/door = door_ref?.resolve()
	if(door)
		UnregisterSignal(door, COMSIG_PARENT_QDELETING)
	var/datum/eldritch_knowledge/base_lock/knowledge = knowledge_ref?.resolve()
	knowledge?.thresholds.Remove(src)
	door_ref = null
	door_place = null
	knowledge_ref = null
	return ..()

/obj/structure/heretic_lock_threshold/attackby(obj/item/item, mob/living/user)
	if(istype(item, /obj/item/nullrod))
		qdel(src)
		return
	return ..()

/datum/eldritch_knowledge/base_lock/proc/keeper_area_open(turf/place)
	var/area/place_area = get_area(place)
	if(!place_area || (place_area.area_flags & NOTELEPORT) || istype(place_area, /area/centcom) || istype(place_area, /area/shuttle/transit))
		return FALSE
	if(!istype(place_area, /area/shuttle))
		return TRUE
	var/obj/docking_port/mobile/shuttle = SSshuttle.get_containing_shuttle(place)
	return !istype(shuttle?.get_docked(), /obj/docking_port/stationary/transit)

/datum/eldritch_knowledge/base_lock/proc/valid_keeper_door(obj/machinery/door/airlock/door)
	return istype(door) && !QDELETED(door) && isturf(door.loc) && !door.welded && !(door.machine_stat & BROKEN) && !(door.resistance_flags & INDESTRUCTIBLE) && keeper_area_open(door.loc)

/datum/eldritch_knowledge/base_lock/proc/keeper_entry(mob/living/user)
	if(!ascension_active || !valid_user(user) || !keeper_area_open(user.loc))
		return null
	for(var/obj/machinery/door/airlock/door in range(1, user))
		if(valid_keeper_door(door) && (door.loc == user.loc || user.Adjacent(door)))
			return door
	return null

/// Подпись -> шлюз, ближние первыми; вторая створка того же проёма не повторяется.
/datum/eldritch_knowledge/base_lock/proc/keeper_destinations(mob/living/user, range = HERETIC_LOCK_KEEPER_RANGE)
	var/list/destinations = list()
	if(!keeper_entry(user))
		return destinations
	var/turf/origin = get_turf(user)
	var/list/by_distance = new /list(range)
	for(var/obj/machinery/door/airlock/door in GLOB.airlocks)
		if(door.z != origin.z)
			continue
		var/distance = get_dist(origin, door)
		if(distance < HERETIC_LOCK_KEEPER_MIN_DISTANCE || distance > range || !valid_keeper_door(door))
			continue
		LAZYADD(by_distance[distance], door)
	var/list/chosen = list()
	for(var/list/bucket as anything in by_distance)
		for(var/obj/machinery/door/airlock/door as anything in bucket)
			var/twin = FALSE
			for(var/obj/machinery/door/airlock/other as anything in chosen)
				if(get_dist(door, other) <= 1)
					twin = TRUE
					break
			if(twin)
				continue
			chosen += door
			var/label = "[get_area_name(door, TRUE)] - [dir2text_ru(get_dir(origin, door))], [get_dist(origin, door)] кл."
			var/unique_label = label
			var/copy = 1
			while(destinations[unique_label])
				copy++
				unique_label = "[label] ([copy])"
			destinations[unique_label] = door
	return destinations

/datum/eldritch_knowledge/base_lock/proc/can_keeper_travel(mob/living/user, obj/machinery/door/airlock/exit)
	return valid_keeper_door(exit) && exit.z == user.z && exit.loc != user.loc && get_dist(user, exit) <= HERETIC_LOCK_KEEPER_RANGE && keeper_entry(user)

/datum/eldritch_knowledge/base_lock/proc/keeper_travel(mob/living/user, obj/machinery/door/airlock/exit, channel = HERETIC_LOCK_KEEPER_CHANNEL)
	if(!can_keeper_travel(user, exit))
		return FALSE
	var/obj/machinery/door/airlock/entry = keeper_entry(user)
	var/obj/effect/temp_visual/heretic_lock_portal/entry_portal = new(get_turf(entry || user))
	var/obj/effect/temp_visual/heretic_lock_portal/exit_portal = new(get_turf(exit))
	var/obj/effect/temp_visual/heretic_vfx/thread/thread = heretic_vfx_thread(entry_portal, exit_portal, heretic_path_ink(PATH_LOCK), HERETIC_LOCK_PORTAL_FAILSAFE)
	thread?.grow(max(channel, HERETIC_LOCK_PORTAL_OPEN))
	playsound(exit, 'modular_bluemoon/sound/heretic/lock_knock.ogg', 50, TRUE)
	user.visible_message(span_warning("[user] поворачивает невидимый ключ в шлюзе. В другом шлюзе неподалёку вспыхивает золотая скважина!"))
	var/travelled = FALSE
	if(!channel || do_after(user, channel, target = user, extra_checks = CALLBACK(src, PROC_REF(can_keeper_travel), user, exit)))
		travelled = keeper_teleport(user, exit)
	entry_portal.close(travelled)
	exit_portal.close(travelled)
	if(travelled)
		thread?.snap(HERETIC_LOCK_THREAD_SNAP)
	else
		thread?.fizzle(HERETIC_LOCK_THREAD_SNAP)
	return travelled

/datum/eldritch_knowledge/base_lock/proc/keeper_teleport(mob/living/user, obj/machinery/door/airlock/exit)
	if(!can_keeper_travel(user, exit))
		return FALSE
	var/turf/origin = get_turf(user)
	var/turf/landing = get_turf(exit)
	if(!do_teleport(user, landing, channel = TELEPORT_CHANNEL_MAGIC) || get_turf(user) != landing)
		return FALSE
	keeper_passage_fx(user, origin, landing)
	playsound(landing, 'modular_bluemoon/sound/heretic/lock_release.ogg', 50, TRUE)
	log_game("[key_name(user)] проходит Ключником из [AREACOORD(origin)] в [AREACOORD(landing)].")
	return TRUE

/// Ключник: герой рассыпается ключами у входа, искры летят по нити, у выхода он собирается из золота.
/datum/eldritch_knowledge/base_lock/proc/keeper_passage_fx(mob/living/user, turf/origin, turf/landing)
	var/ink = heretic_path_ink(PATH_LOCK)
	var/list/tint = heretic_vfx_ink_tint(ink)
	var/obj/effect/temp_visual/heretic_vfx/ghost/dissolve = heretic_vfx_ghost(user, origin, tint, HERETIC_LOCK_DISSOLVE_TIME, TRUE)
	if(dissolve)
		var/matrix/stretched = matrix(dissolve.transform)
		stretched.Scale(HERETIC_LOCK_DISSOLVE_SQUEEZE, HERETIC_LOCK_DISSOLVE_STRETCH)
		animate(dissolve, transform = stretched, alpha = 0, pixel_y = dissolve.pixel_y + HERETIC_LOCK_DISSOLVE_RISE, time = HERETIC_LOCK_DISSOLVE_TIME, easing = QUAD_EASING | EASE_IN)
	heretic_vfx_burst(origin, /particles/heretic_ascension/lock)
	heretic_vfx_stream(origin, landing, /particles/heretic_ascension/lock/passage, HERETIC_LOCK_STREAM_TIME)
	var/obj/effect/temp_visual/heretic_vfx/ghost/reform = heretic_vfx_ghost(user, landing, tint, HERETIC_LOCK_REFORM_TIME, TRUE)
	if(reform)
		var/matrix/natural = matrix(reform.transform)
		var/matrix/spread = matrix(natural)
		spread.Scale(HERETIC_LOCK_REFORM_WIDE, HERETIC_LOCK_REFORM_FLAT)
		reform.transform = spread
		reform.alpha = 0
		animate(reform, transform = natural, alpha = reform.model_share(HERETIC_LOCK_GHOST_ALPHA), time = HERETIC_LOCK_REFORM_TIME / 2, easing = CUBIC_EASING | EASE_OUT)
		animate(alpha = 0, time = HERETIC_LOCK_REFORM_TIME / 2, easing = SINE_EASING | EASE_IN)
	heretic_vfx_converge(landing, /particles/heretic_ascension/lock/passage, HERETIC_LOCK_REFORM_RADIUS, HERETIC_LOCK_REFORM_TIME, HERETIC_LOCK_STREAM_TIME, HERETIC_LOCK_REFORM_ARMS, HERETIC_LOCK_REFORM_SWIRL)
	heretic_vfx_pulse(user, ink, 2, HERETIC_LOCK_REFORM_TIME)
	heretic_vfx_flash(landing, ink, HERETIC_LOCK_ARRIVAL_FLASH_RANGE, HERETIC_LOCK_ARRIVAL_FLASH_POWER, HERETIC_LOCK_ARRIVAL_FLASH_TIME)
	playsound(landing, 'sound/machines/locktoggle.ogg', 40, TRUE)

/// Замок-глиф щёлкает над запертым шлюзом, из-под дужки брызжут золотые искры.
/proc/heretic_lock_click_fx(atom/door)
	var/turf/place = get_turf(door)
	if(!place)
		return
	new /obj/effect/temp_visual/heretic_lock_click(place)
	heretic_vfx_burst(place, /particles/heretic_ascension/lock/click, HERETIC_VFX_BURST_TIME / 2)

/// Скважина-портал Ключника: зубчатое колесо щёлкает по зубцу вокруг дышащей скважины; сходится поворотом ключа или гаснет.
/obj/effect/temp_visual/heretic_lock_portal
	icon = 'modular_bluemoon/icons/effects/heretic_vfx.dmi'
	icon_state = "lock_portal_core"
	layer = ABOVE_OBJ_LAYER
	randomdir = FALSE
	duration = HERETIC_LOCK_PORTAL_FAILSAFE
	var/obj/effect/abstract/heretic_lock_portal_ring/ring
	var/closing = FALSE

/obj/effect/temp_visual/heretic_lock_portal/Initialize(mapload)
	. = ..()
	add_overlay(emissive_appearance(icon, icon_state))
	ring = new(null)
	vis_contents += ring
	transform = matrix(HERETIC_LOCK_PORTAL_START, 0, 0, 0, HERETIC_LOCK_PORTAL_START, 0)
	alpha = 0
	animate(src, transform = matrix(), alpha = 255, time = HERETIC_LOCK_PORTAL_OPEN, easing = BACK_EASING | EASE_OUT)
	set_light(HERETIC_LOCK_PORTAL_LIGHT_RANGE, HERETIC_LOCK_PORTAL_LIGHT_POWER, heretic_path_ink(PATH_LOCK))

/obj/effect/temp_visual/heretic_lock_portal/proc/close(unlocked)
	if(closing || QDELETED(src))
		return
	closing = TRUE
	deltimer(timerid)
	timerid = QDEL_IN_STOPPABLE(src, HERETIC_LOCK_PORTAL_CLOSE)
	if(!unlocked)
		animate(src, alpha = 0, time = HERETIC_LOCK_PORTAL_CLOSE, easing = SINE_EASING | EASE_IN)
		return
	ring?.unlock()
	animate(src, transform = matrix(HERETIC_LOCK_PORTAL_FLARE, 0, 0, 0, HERETIC_LOCK_PORTAL_FLARE, 0), time = HERETIC_LOCK_PORTAL_CLOSE * HERETIC_LOCK_PORTAL_FLARE_SHARE, easing = CUBIC_EASING | EASE_OUT)
	animate(transform = matrix(HERETIC_LOCK_PORTAL_START, 0, 0, 0, HERETIC_LOCK_PORTAL_START, 0), alpha = 0, time = HERETIC_LOCK_PORTAL_CLOSE * (1 - HERETIC_LOCK_PORTAL_FLARE_SHARE), easing = QUAD_EASING | EASE_IN)

/obj/effect/temp_visual/heretic_lock_portal/Destroy()
	vis_contents -= ring
	QDEL_NULL(ring)
	return ..()

/// Колесо щёлкает по зубцу полный оборот и лишь затем возвращается в исходный поворот, совпадающий с ним до пикселя.
/obj/effect/abstract/heretic_lock_portal_ring
	icon = 'modular_bluemoon/icons/effects/heretic_vfx.dmi'
	icon_state = "lock_portal"
	layer = FLOAT_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	vis_flags = VIS_INHERIT_PLANE
	var/spun_at

/obj/effect/abstract/heretic_lock_portal_ring/Initialize(mapload)
	. = ..()
	add_overlay(emissive_appearance(icon, icon_state))
	spun_at = world.time
	for(var/tooth in 1 to HERETIC_LOCK_PORTAL_TEETH)
		var/matrix/notch = matrix()
		notch.Turn(tooth * 360 / HERETIC_LOCK_PORTAL_TEETH)
		if(tooth == 1)
			animate(src, transform = notch, time = HERETIC_LOCK_PORTAL_CLICK, easing = BACK_EASING | EASE_OUT, loop = -1)
		else
			animate(transform = notch, time = HERETIC_LOCK_PORTAL_CLICK, easing = BACK_EASING | EASE_OUT)
		animate(transform = notch, time = HERETIC_LOCK_PORTAL_NOTCH - HERETIC_LOCK_PORTAL_CLICK)
	animate(transform = matrix(), time = 0)

/// Зубец, на котором колесо стоит сейчас: щелчок каждого такта идёт в его начале.
/obj/effect/abstract/heretic_lock_portal_ring/proc/current_tooth()
	return (round((world.time - spun_at) / HERETIC_LOCK_PORTAL_NOTCH) + 1) % HERETIC_LOCK_PORTAL_TEETH

/// Последний поворот ключа: колесо проворачивается вперёд на два зубца разом.
/obj/effect/abstract/heretic_lock_portal_ring/proc/unlock()
	var/matrix/turned = matrix()
	turned.Turn((current_tooth() + 2) * 360 / HERETIC_LOCK_PORTAL_TEETH)
	animate(src, transform = turned, time = HERETIC_LOCK_PORTAL_CLICK * 2, easing = BACK_EASING | EASE_OUT)

/// Замок: ключи и искры переходящего героя, быстрые и без разлёта.
/particles/heretic_ascension/lock/passage
	count = 20
	spawning = 8
	position = generator("circle", 0, 6)
	velocity = generator("circle", 0, 1)
	gravity = list(0, 0)
	friction = 0
	lifespan = 0.4 SECONDS
	fade = 0.15 SECONDS

/// Замок: короткий веер искр из-под щёлкнувшей дужки.
/particles/heretic_ascension/lock/click
	icon_state = list("gold_spark" = 1)
	count = 10
	spawning = 10
	position = generator("box", list(-6, 2, 0), list(6, 6, 0))
	velocity = generator("box", list(-3, 1, 0), list(3, 4, 0))
	gravity = list(0, -0.35)
	friction = 0.08
	lifespan = 0.7 SECONDS
	fade = 0.3 SECONDS

/obj/effect/temp_visual/heretic_lock_click
	icon = 'modular_bluemoon/icons/effects/heretic_vfx.dmi'
	icon_state = "lock_click"
	randomdir = FALSE
	duration = HERETIC_LOCK_CLICK_TIME

/obj/effect/temp_visual/heretic_lock_click/Initialize(mapload)
	. = ..()
	add_overlay(emissive_appearance(icon, icon_state))

/// Ключ Дома над героем: проворачивается по щелчку за время подготовки, затем уходит в героя или гаснет.
/obj/effect/temp_visual/heretic_lock_house_key
	icon = 'modular_bluemoon/icons/effects/heretic_vfx.dmi'
	icon_state = "lock_house_key"
	randomdir = FALSE
	duration = HERETIC_LOCK_KEY_FAILSAFE
	pixel_y = HERETIC_LOCK_KEY_HEIGHT
	var/released = FALSE
	var/static/list/turn_steps = list(0.45, -0.45, -1)

/obj/effect/temp_visual/heretic_lock_house_key/Initialize(mapload)
	. = ..()
	add_overlay(emissive_appearance(icon, icon_state))
	alpha = 0
	transform = matrix(HERETIC_LOCK_KEY_START, 0, 0, 0, HERETIC_LOCK_KEY_START, 0)
	animate(src, alpha = 255, transform = matrix(), time = HERETIC_LOCK_KEY_APPEAR, easing = BACK_EASING | EASE_OUT)
	var/matrix/held = matrix()
	for(var/width_share in turn_steps)
		animate(transform = held, time = HERETIC_LOCK_KEY_HOLD)
		var/matrix/turned = matrix(width_share, 0, 0, 0, 1, 0)
		animate(transform = turned, time = HERETIC_LOCK_PORTAL_CLICK, easing = BACK_EASING | EASE_OUT, flags = ANIMATION_LINEAR_TRANSFORM)
		held = turned

/obj/effect/temp_visual/heretic_lock_house_key/proc/release(unlocked)
	if(released || QDELETED(src))
		return
	released = TRUE
	deltimer(timerid)
	timerid = QDEL_IN_STOPPABLE(src, HERETIC_LOCK_KEY_RELEASE)
	if(!unlocked)
		animate(src, alpha = 0, time = HERETIC_LOCK_KEY_RELEASE, easing = SINE_EASING | EASE_IN)
		return
	animate(src, transform = matrix(), time = HERETIC_LOCK_PORTAL_CLICK, easing = BACK_EASING | EASE_OUT, flags = ANIMATION_LINEAR_TRANSFORM)
	animate(pixel_y = HERETIC_LOCK_KEY_SINK, transform = matrix(HERETIC_LOCK_KEY_SINK_SCALE, 0, 0, 0, HERETIC_LOCK_KEY_SINK_SCALE, 0), alpha = 0, time = HERETIC_LOCK_KEY_RELEASE - HERETIC_LOCK_PORTAL_CLICK, easing = QUAD_EASING | EASE_IN)

/// Ключник: шлюз за спиной вознёсшегося закрывается и опускает болты.
/datum/component/heretic_lock_keeper
	dupe_mode = COMPONENT_DUPE_UNIQUE
	/// Шлюз -> таймер подъёма; запись снимается, как только болты поднимает кто угодно.
	var/list/obj/machinery/door/airlock/bolted = list()

/datum/component/heretic_lock_keeper/Initialize()
	if(!isliving(parent))
		return COMPONENT_INCOMPATIBLE

/datum/component/heretic_lock_keeper/RegisterWithParent()
	RegisterSignal(parent, COMSIG_MOVABLE_MOVED, PROC_REF(on_moved))
	RegisterSignal(parent, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine))

/datum/component/heretic_lock_keeper/UnregisterFromParent()
	UnregisterSignal(parent, list(COMSIG_MOVABLE_MOVED, COMSIG_PARENT_EXAMINE))

/datum/component/heretic_lock_keeper/Destroy()
	for(var/obj/machinery/door/airlock/door as anything in bolted.Copy())
		release_bolt(door)
	return ..()

/// Закрытие отложено: иначе шлюз захлопнется перед тем, кого герой тащит за собой.
/datum/component/heretic_lock_keeper/proc/on_moved(mob/living/source, atom/old_loc, dir, forced)
	SIGNAL_HANDLER
	if(!isturf(old_loc) || old_loc == source.loc)
		return
	var/obj/machinery/door/airlock/door = locate() in old_loc
	if(door)
		addtimer(CALLBACK(src, PROC_REF(seal_behind), door), HERETIC_LOCK_KEEPER_SEAL_DELAY)

/datum/component/heretic_lock_keeper/proc/can_seal(obj/machinery/door/airlock/door)
	return !QDELETED(src) && !QDELETED(door) && isturf(door.loc) && door.hasPower() && !door.locked && !door.welded && !(door.resistance_flags & INDESTRUCTIBLE) && !(locate(/mob/living) in door.loc)

/datum/component/heretic_lock_keeper/proc/seal_behind(obj/machinery/door/airlock/door)
	if(!can_seal(door))
		return FALSE
	var/give_up_at = world.time + HERETIC_LOCK_KEEPER_CLOSE_WAIT
	while(door.operating && world.time < give_up_at)
		sleep(world.tick_lag)
		if(!can_seal(door))
			return FALSE
	if(!door.density && !door.close(TRUE))
		return FALSE
	if(!can_seal(door) || !door.density)
		return FALSE
	if(door in bolted)
		forget_bolt(door)
	door.bolt()
	RegisterSignals(door, list(COMSIG_AIRLOCK_UNBOLTED, COMSIG_PARENT_QDELETING), PROC_REF(forget_bolt))
	bolted[door] = addtimer(CALLBACK(src, PROC_REF(release_bolt), door), HERETIC_LOCK_KEEPER_BOLT_TIME, TIMER_STOPPABLE)
	heretic_lock_click_fx(door)
	return TRUE

/datum/component/heretic_lock_keeper/proc/release_bolt(obj/machinery/door/airlock/door)
	if(!(door in bolted))
		return FALSE
	forget_bolt(door)
	if(!QDELETED(door) && door.locked)
		door.unbolt()
	return TRUE

/datum/component/heretic_lock_keeper/proc/forget_bolt(obj/machinery/door/airlock/source)
	SIGNAL_HANDLER
	deltimer(bolted[source])
	bolted -= source
	UnregisterSignal(source, list(COMSIG_AIRLOCK_UNBOLTED, COMSIG_PARENT_QDELETING))

/datum/component/heretic_lock_keeper/proc/on_examine(mob/living/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	examine_list += span_warning("Запитанные шлюзы за его спиной сами захлопываются и на 8 секунд опускают болты: поднимите их через ИИ, пульт шлюзов или мультитулом. Заваренный или сломанный шлюз ему не выход, а нулевой жезл разбивает его печати.")

/datum/eldritch_knowledge/base_lock/proc/valid_user(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	return user && user == lock_body && heretic?.get_knowledge(type) == src && user.stat == CONSCIOUS && !user.incapacitated() && isturf(user.loc)

/datum/eldritch_knowledge/base_lock/proc/seal_limit()
	if(ascension_active)
		return HERETIC_LOCK_ASCENDED_LIMIT
	var/datum/antagonist/heretic/heretic = IS_HERETIC(lock_body)
	return heretic?.get_knowledge(/datum/eldritch_knowledge/lock_hinges) ? HERETIC_LOCK_UPGRADED_LIMIT : HERETIC_LOCK_BASE_LIMIT

/datum/eldritch_knowledge/base_lock/proc/seal_integrity()
	var/datum/antagonist/heretic/heretic = IS_HERETIC(lock_body)
	var/datum/eldritch_knowledge/lock_hinges/hinges = heretic?.get_knowledge(/datum/eldritch_knowledge/lock_hinges)
	return hinges ? hinges.passive_values[hinges.passive_level] : 60

/datum/eldritch_knowledge/base_lock/proc/valid_seal_turf(turf/place, mob/living/user, list/visible, distance = HERETIC_LOCK_RANGE)
	if(!valid_user(user) || !istype(place, /turf/open/floor) || place.z != user.z || get_dist(user, place) > distance)
		return FALSE
	if(!visible)
		visible = view(distance, user)
	if(!(place in visible) || place.is_blocked_turf())
		return FALSE
	for(var/obj/structure/heretic_lock_seal/seal in place)
		return FALSE
	return TRUE

/datum/eldritch_knowledge/base_lock/proc/create_seal(turf/place, mob/living/user, key_cost = 1, lifetime = HERETIC_LOCK_SEAL_LIFETIME, list/visible, distance = HERETIC_LOCK_RANGE)
	if(length(seals) >= seal_limit() || combat_resource < key_cost || !valid_seal_turf(place, user, visible, distance))
		return null
	if(key_cost && !spend_combat_resource(key_cost))
		return null
	var/obj/structure/heretic_lock_seal/seal = new(place, src, lifetime)
	seal.reclaimable_key = key_cost > 0
	seals += seal
	return seal

/// Дом без стен: от героя идёт золотая волна, печати поднимаются из пола по кругу, как поворот ключа, по ним пробегает блик.
/datum/eldritch_knowledge/base_lock/proc/house_raised_fx(mob/living/user, list/positions)
	var/ink = heretic_path_ink(PATH_LOCK)
	var/turf/center = get_turf(user)
	heretic_vfx_shockwave(center, ink, HERETIC_LOCK_HOUSE_WAVE_RADIUS, HERETIC_LOCK_HOUSE_WAVE_TIME)
	heretic_vfx_burst(center, /particles/heretic_ascension/lock)
	heretic_vfx_flash(center, ink, HERETIC_LOCK_HOUSE_FLASH_RANGE, HERETIC_LOCK_HOUSE_FLASH_POWER, HERETIC_LOCK_HOUSE_FLASH_TIME)
	heretic_vfx_quake(center, HERETIC_LOCK_HOUSE_QUAKE_RADIUS, HERETIC_LOCK_HOUSE_QUAKE, HERETIC_LOCK_HOUSE_QUAKE_TIME)
	playsound(center, 'sound/machines/locktoggle.ogg', 50, TRUE)
	for(var/turf/place as anything in positions)
		for(var/obj/structure/heretic_lock_seal/seal in place)
			if(seal.knowledge_ref?.resolve() != src)
				continue
			var/sweep = Get_Angle(center, place) / 360
			seal.rise_from_floor(HERETIC_LOCK_HOUSE_RISE + HERETIC_LOCK_HOUSE_RISE_SWEEP * sweep)
			addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(heretic_vfx_pulse), seal, ink, 1, HERETIC_LOCK_HOUSE_GLINT_TIME), HERETIC_LOCK_HOUSE_GLINT_SWEEP * sweep)

/datum/eldritch_knowledge/base_lock/proc/can_open_lock(atom/target, mob/living/user)
	if(!valid_user(user) || QDELETED(target) || !isturf(target.loc) || target.z != user.z || get_dist(target, user) > HERETIC_LOCK_RANGE || !(target in view(HERETIC_LOCK_RANGE, user)))
		return FALSE
	if(istype(target, /obj/machinery/door/airlock))
		var/obj/machinery/door/airlock/door = target
		return door.density && !door.welded && !door.operating && !(door.resistance_flags & INDESTRUCTIBLE)
	if(istype(target, /obj/structure/closet))
		var/obj/structure/closet/closet = target
		return !closet.opened && closet.locked && !closet.welded && !(closet.resistance_flags & INDESTRUCTIBLE)
	return FALSE

/datum/eldritch_knowledge/base_lock/proc/open_lock(atom/target, mob/living/user, harvest = FALSE)
	if(!can_open_lock(target, user))
		return FALSE
	var/generation = court_generation
	var/opened = FALSE
	if(istype(target, /obj/machinery/door/airlock))
		var/obj/machinery/door/airlock/door = target
		var/was_locked = door.locked
		door.unbolt()
		opened = door.open(2)
		if(!opened && was_locked && !QDELETED(door))
			door.bolt()
	else
		var/obj/structure/closet/closet = target
		var/was_locked = closet.locked
		closet.locked = FALSE
		opened = closet.open(user)
		if(!QDELETED(closet))
			if(!opened)
				closet.locked = was_locked
			closet.update_icon()
	if(!opened)
		return FALSE
	if(QDELETED(src) || !valid_user(user) || generation != court_generation)
		return TRUE
	if(harvest)
		harvest_key()
		var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
		if(heretic)
			heretic.advance_deed(heretic.deed_key_for(target), get_turf(target), silent = TRUE)
	new /obj/effect/temp_visual/heretic_lock(get_turf(target))
	playsound(target, 'modular_bluemoon/sound/heretic/lock_knock.ogg', 45, TRUE)
	log_game("[key_name(user)] отпирает [target] силой Замка в [AREACOORD(target)].")
	return TRUE

/datum/eldritch_knowledge/base_lock/proc/harvest_key()
	if(!COOLDOWN_FINISHED(src, resource_harvest))
		return FALSE
	gain_combat_resource()
	COOLDOWN_START(src, resource_harvest, HERETIC_LOCK_HARVEST_COOLDOWN)
	return TRUE

/datum/eldritch_knowledge/base_lock/proc/can_bolt_door(obj/machinery/door/airlock/door, mob/living/user)
	return valid_user(user) && istype(door) && !QDELETED(door) && isturf(door.loc) && user.Adjacent(door) && door.density && !door.locked && !door.welded && !door.operating && !(door.resistance_flags & INDESTRUCTIBLE)

/// Хватка на вреде запирает шлюз на 20 секунд; ключ идёт из общего с отпиранием отката.
/datum/eldritch_knowledge/base_lock/proc/bolt_door(obj/machinery/door/airlock/door, mob/living/user)
	if(!can_bolt_door(door, user))
		return FALSE
	door.bolt()
	if(!door.locked)
		return FALSE
	RegisterSignal(door, COMSIG_PARENT_QDELETING, PROC_REF(on_bolted_door_deleted), override = TRUE)
	deltimer(grasp_bolts[door])
	grasp_bolts[door] = addtimer(CALLBACK(src, PROC_REF(release_grasp_bolt), door), HERETIC_LOCK_GRASP_BOLT_TIME, TIMER_STOPPABLE)
	harvest_key()
	heretic_lock_click_fx(door)
	playsound(door, 'modular_bluemoon/sound/heretic/lock_knock.ogg', 45, TRUE)
	door.visible_message(span_warning("Засовы [door] с лязгом опускаются сами собой!"))
	log_game("[key_name(user)] запирает [door] силой Замка на [HERETIC_LOCK_GRASP_BOLT_TIME / (1 SECONDS)] с в [AREACOORD(door)].")
	return TRUE

/datum/eldritch_knowledge/base_lock/proc/release_grasp_bolt(obj/machinery/door/airlock/door)
	if(!(door in grasp_bolts))
		return
	deltimer(grasp_bolts[door])
	grasp_bolts -= door
	UnregisterSignal(door, COMSIG_PARENT_QDELETING)
	if(!QDELETED(door) && door.locked)
		door.unbolt()

/datum/eldritch_knowledge/base_lock/proc/on_bolted_door_deleted(obj/machinery/door/airlock/source)
	SIGNAL_HANDLER
	deltimer(grasp_bolts[source])
	grasp_bolts -= source
	UnregisterSignal(source, COMSIG_PARENT_QDELETING)

/datum/eldritch_knowledge/base_lock/proc/release_seals(mob/living/user, obj/structure/heretic_lock_seal/only_seal)
	if(!valid_user(user))
		return FALSE
	if(only_seal && (QDELETED(only_seal) || !(only_seal in seals) || only_seal.knowledge_ref?.resolve() != src))
		return FALSE
	var/list/selected = list()
	var/list/victims = list()
	var/list/visible = view(HERETIC_LOCK_RANGE, user)
	for(var/obj/structure/heretic_lock_seal/seal as anything in seals)
		if(only_seal && seal != only_seal)
			continue
		if(!(seal in visible) || seal.z != user.z || get_dist(user, seal) > HERETIC_LOCK_RANGE)
			continue
		selected += seal
		for(var/mob/living/victim in view(1, seal))
			if(isturf(victim.loc) && seal.Adjacent(victim))
				victims |= victim
	if(!length(selected))
		return FALSE
	for(var/obj/structure/heretic_lock_seal/seal as anything in selected)
		new /obj/effect/temp_visual/heretic_lock/release(get_turf(seal))
		qdel(seal)
	for(var/mob/living/victim as anything in victims)
		if(!heretic_can_affect(user, victim))
			continue
		var/damage_before = victim.getBruteLoss()
		victim.adjustBruteLoss(ascension_active ? 45 : 30)
		if(victim.getBruteLoss() > damage_before)
			var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
			heretic?.advance_combat_deed(victim, PATH_LOCK)
		log_combat(user, victim, "разомкнул печати вокруг")
	playsound(user, 'modular_bluemoon/sound/heretic/lock_release.ogg', 55, TRUE)
	return TRUE

/datum/eldritch_knowledge/base_lock/proc/court_turfs(turf/center, mob/living/user, radius = HERETIC_LOCK_COURT_RADIUS)
	var/list/positions = list()
	if(!valid_user(user) || !istype(center, /turf/open/floor) || center.z != user.z || get_dist(user, center) > HERETIC_LOCK_RANGE)
		return positions
	var/area_reach = HERETIC_LOCK_RANGE + radius
	var/list/visible = view(area_reach, user)
	if(!(center in visible))
		return positions
	for(var/turf/open/floor/place in range(radius, center))
		if(get_dist(place, center) == radius && valid_seal_turf(place, user, visible, distance = area_reach))
			positions += place
	return positions

/datum/eldritch_knowledge/base_lock/proc/raise_court(mob/living/user, list/positions, key_cost = 2, expected_generation, radius = HERETIC_LOCK_COURT_RADIUS)
	if(!valid_user(user) || combat_resource < key_cost || (!isnull(expected_generation) && court_generation != expected_generation))
		return FALSE
	var/list/available = list()
	var/area_reach = HERETIC_LOCK_RANGE + radius
	var/list/visible = view(area_reach, user)
	for(var/turf/place as anything in positions)
		if(valid_seal_turf(place, user, visible, distance = area_reach))
			available += place
	if(length(available) < 3 || length(seals) + length(available) > seal_limit())
		return FALSE
	if(key_cost && !spend_combat_resource(key_cost))
		return FALSE
	for(var/turf/place as anything in available)
		create_seal(place, user, key_cost = 0, visible = visible, distance = area_reach)
	return TRUE

/obj/structure/heretic_lock_seal
	var/reclaimable_key = FALSE
	name = "labyrinth seal"
	desc = "Золотые зубья перекрывают проход. Печать можно разбить кулаками, оружием или снарядами; нуль-жезл снимает её сразу. Еретики, их слуги и защищённые от магии проходят свободно. Газ и свет проходят сквозь печать."
	icon = 'modular_bluemoon/icons/obj/heretic_lock_gate.dmi'
	icon_state = "lock_barrier"
	density = TRUE
	anchored = TRUE
	max_integrity = 60
	obj_integrity = 60
	CanAtmosPass = ATMOS_PASS_YES
	var/datum/weakref/knowledge_ref
	var/expiry_timer
	var/expires_at

/obj/structure/heretic_lock_seal/Initialize(mapload, datum/eldritch_knowledge/base_lock/knowledge, lifetime = HERETIC_LOCK_SEAL_LIFETIME)
	. = ..()
	if(!knowledge)
		return INITIALIZE_HINT_QDEL
	knowledge_ref = WEAKREF(knowledge)
	max_integrity = knowledge.seal_integrity()
	obj_integrity = max_integrity
	alpha = 0
	animate(src, alpha = 220, time = 0.3 SECONDS)
	flick("lock_closing", src)
	expires_at = world.time + lifetime
	expiry_timer = QDEL_IN_STOPPABLE(src, lifetime)
	new /obj/effect/temp_visual/heretic_lock(get_turf(src))
	playsound(src, 'modular_bluemoon/sound/heretic/lock_knock.ogg', 30, TRUE)

/// Печать Дома поднимается из пола: сплющенная у пола, она вырастает с отскоком за rise_time.
/obj/structure/heretic_lock_seal/proc/rise_from_floor(rise_time)
	transform = matrix(1, 0, 0, 0, HERETIC_LOCK_SEAL_SQUASH, -world.icon_size * (1 - HERETIC_LOCK_SEAL_SQUASH) / 2)
	animate(src, transform = matrix(), time = rise_time, easing = BACK_EASING | EASE_OUT, flags = ANIMATION_PARALLEL)

/obj/structure/heretic_lock_seal/Destroy()
	deltimer(expiry_timer)
	var/datum/eldritch_knowledge/base_lock/knowledge = knowledge_ref?.resolve()
	knowledge?.seals -= src
	knowledge_ref = null
	return ..()

/obj/structure/heretic_lock_seal/CanAllowThrough(atom/movable/mover, turf/target)
	if(..())
		return TRUE
	if(!isliving(mover))
		return FALSE
	var/datum/eldritch_knowledge/base_lock/knowledge = knowledge_ref?.resolve()
	return !knowledge || !heretic_can_affect(knowledge.lock_body, mover, chargecost = 0)

/obj/structure/heretic_lock_seal/on_attack_hand(mob/living/user, act_intent = user.a_intent, unarmed_attack_flags)
	. = ..()
	if(.)
		return
	var/datum/eldritch_knowledge/base_lock/knowledge = knowledge_ref?.resolve()
	if(user == knowledge?.lock_body && act_intent == INTENT_HELP)
		if(reclaimable_key)
			reclaimable_key = FALSE
			knowledge.gain_combat_resource()
		qdel(src)
		return
	user.do_attack_animation(src, ATTACK_EFFECT_PUNCH)
	user.changeNext_move(CLICK_CD_MELEE)
	take_damage(5, BRUTE, MELEE, TRUE)

/obj/structure/heretic_lock_seal/attackby(obj/item/item, mob/living/user)
	if(istype(item, /obj/item/nullrod))
		qdel(src)
		return
	return ..()

/obj/effect/temp_visual/heretic_lock
	icon = 'modular_bluemoon/icons/obj/heretic_lock_effects.dmi'
	icon_state = "lock_grasp"
	randomdir = FALSE
	duration = 0.8 SECONDS

/obj/effect/temp_visual/heretic_lock/release
	icon_state = "lock_open"
	duration = 1.2 SECONDS

/obj/effect/temp_visual/heretic_lock/warning
	icon_state = "lock_warning"
	duration = 2 SECONDS
	alpha = 160

/obj/item/melee/sickly_blade/lock
	name = "key blade"
	desc = "Клинок с зубцами старого ключа. Он отпирает плоть и служит ломом; метка Замка превращает его удар в новый запертый проход."
	icon = 'modular_bluemoon/icons/obj/heretic_lock.dmi'
	icon_state = "key_blade"
	item_state = "key_blade"
	route = PATH_LOCK
	mark_type = /datum/status_effect/eldritch/lock
	tool_behaviour = TOOL_CROWBAR
	toolspeed = 0.8

/datum/eldritch_knowledge/lock_grasp
	name = "Открытая ладонь"
	gain_text = "Привратник показал мне пустую ладонь. По ту сторону стены кто-то отодвинул засов."
	desc = "Хватка открывает соседний закрытый шлюз, поднимая болты, или запертый шкаф. Питание и доступ не нужны, сварка и неразрушимые преграды мешают. Успешное открытие даёт 1 ключ не чаще раза в 20 секунд. На намерении вреда хватка, наоборот, опускает болты закрытого шлюза на 20 секунд, после чего они поднимаются сами. Запирание тоже даёт ключ, но делит с открытием ту же задержку в 20 секунд. На живой цели сохраняется обычный эффект хватки."
	cost = 1
	route = PATH_LOCK

/datum/eldritch_knowledge/lock_grasp/on_mansus_grasp(atom/target, mob/living/user, proximity_flag, click_parameters)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_lock/knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/base_lock)
	if(!proximity_flag || !target || !knowledge?.valid_user(user) || !user.Adjacent(target))
		return FALSE
	if(user.a_intent == INTENT_HARM && istype(target, /obj/machinery/door/airlock) && knowledge.bolt_door(target, user))
		return TRUE
	return knowledge.open_lock(target, user, harvest = TRUE)

/datum/eldritch_knowledge/spell/lock_bolt
	name = "Открывающий удар"
	gain_text = "Я спросил, где кончается дверь. «Там, где кончается твоя рука», — ответил он и протянул её через зал."
	desc = "Направленный удар в пяти клетках наносит 25 ожогов и 20 урона выносливости или открывает шлюз либо запертый шкаф. Проходит через ваши печати: проведённый через них удар также накладывает изученную метку Замка. Остальные плотные преграды останавливают удар; сварка и неразрушимые двери сохраняются. При выборе своей печати размыкает только её после секунды неподвижной подготовки: 30 ушибов врагам в соседних клетках, печать расходуется без возврата ключа. Не требует ключей, перезарядка 18 секунд."
	cost = 1
	route = PATH_LOCK
	spell_to_add = /obj/effect/proc_holder/spell/pointed/heretic_lock/bolt

/datum/eldritch_knowledge/lock_mark
	name = "Метка Замка"
	gain_text = "Гостям не полагались ключи. Их имена становились замочными скважинами."
	desc = "Хватка и Открывающий удар, проведённый через вашу печать, накладывают метку на 15 секунд. Клинок активирует её: 15 урона выносливости, 1 ключ и бесплатная печать позади противника на 8 секунд, если там свободный пол и не достигнут предел печатей."
	cost = 2
	route = PATH_LOCK

/datum/eldritch_knowledge/lock_mark/on_mansus_grasp(atom/target, mob/living/user, proximity_flag, click_parameters)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_lock/knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/base_lock)
	if(!proximity_flag || !knowledge?.valid_user(user) || !heretic_can_affect(user, target))
		return FALSE
	var/mob/living/victim = target
	victim.apply_status_effect(/datum/status_effect/eldritch/lock, knowledge)
	return TRUE

/datum/status_effect/eldritch/lock
	id = "lock_mark"
	mark_name = "Метка Замка"
	effect_sprite_icon = 'modular_bluemoon/icons/obj/heretic_alerts.dmi'
	effect_sprite = "sigil_lock"
	mark_alert_state = "sigil_lock"
	detonation_visual = /obj/effect/temp_visual/heretic_lock/release
	detonation_sound = 'modular_bluemoon/sound/heretic/lock_release.ogg'
	var/datum/weakref/knowledge_ref

/datum/status_effect/eldritch/lock/on_creation(mob/living/new_owner, datum/eldritch_knowledge/base_lock/knowledge)
	if(knowledge)
		knowledge_ref = WEAKREF(knowledge)
	return ..()

/datum/status_effect/eldritch/lock/on_apply()
	if(!..())
		return FALSE
	var/datum/eldritch_knowledge/base_lock/knowledge = knowledge_ref?.resolve()
	if(!knowledge)
		return FALSE
	knowledge.marks += src
	return TRUE

/datum/status_effect/eldritch/lock/on_remove()
	var/datum/eldritch_knowledge/base_lock/knowledge = knowledge_ref?.resolve()
	knowledge?.marks -= src
	return ..()

/datum/status_effect/eldritch/lock/on_effect()
	var/datum/eldritch_knowledge/base_lock/knowledge = knowledge_ref?.resolve()
	var/mob/living/user = knowledge?.lock_body
	if(knowledge?.valid_user(user) && heretic_can_affect(user, owner, chargecost = 0))
		owner.adjustStaminaLoss(15)
		if(isturf(owner.loc))
			knowledge.create_seal(get_step(owner, get_dir(user, owner)), user, key_cost = 0, lifetime = 8 SECONDS)
	return ..()

/datum/eldritch_knowledge/lock_key
	name = "Ключница"
	gain_text = "На поясе привратника не осталось места. Последний ключ он носил под кожей."
	desc = "Лом и лист золота создают ритуальный ключ. Возьмите его в активную руку. На намерении помощи нажмите на первый шлюз, стоя рядом, не по диагонали: золотая метка появится под вами. Так же отметьте второй шлюз в пределах 20 клеток на одном уровне. Для перехода встаньте точно на одну из меток, включите намерение вреда и нажмите ключом на шлюз рядом с ней. Не двигайтесь 2 секунды; переход стоит 1 ключ из запаса пути, перезарядка 15 секунд. Метки живут 3 минуты; сварка и занятый выход мешают переходу. При пустом запасе активируйте ключ в руке: за 2 секунды и 8 ушибов получите 1 ключ, перезарядка 30 секунд."
	cost = 1
	route = PATH_LOCK
	required_atoms = list(/obj/item/crowbar, /obj/item/stack/sheet/mineral/gold)
	result_atoms = list(/obj/item/heretic_path_relic/lock_key)

/datum/eldritch_knowledge/lock_key/recipe_snowflake_check(list/atoms, loc, list/selected_atoms, mob/living/user)
	return new_path_relic_available()

/datum/eldritch_knowledge/lock_key/on_finished_recipe(mob/living/user, list/atoms, loc)
	return make_new_path_relic(user, get_turf(loc), /obj/item/heretic_path_relic/lock_key)

/datum/eldritch_knowledge/lock_key/Destroy()
	var/datum/antagonist/heretic/heretic = combat_resource_owner?.resolve()
	var/datum/eldritch_knowledge/base_lock/knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/base_lock)
	knowledge?.clear_thresholds()
	return ..()

/obj/item/heretic_path_relic/lock_key
	name = "steward's key"
	desc = "Ритуальный ключ связывает две золотые метки на полу у шлюзов. Для перехода нужен 1 ключ из запаса пути; сам предмет не расходуется."
	icon_state = "lock_key"
	item_flags = NOBLUDGEON
	var/cutting_time = 2 SECONDS
	var/passage_time = 2 SECONDS
	var/releasing_time = 1 SECONDS
	COOLDOWN_DECLARE(passage_cooldown)

/obj/item/heretic_path_relic/lock_key/examine(mob/user)
	. = ..()
	. += span_notice("<b>Как перейти:</b><br>1. Возьмите ключ в активную руку и включите намерение помощи. Встаньте рядом со шлюзом, не по диагонали, и нажмите ключом на шлюз. Золотая скважина появится на полу под вами.<br>2. Так же отметьте другой шлюз в пределах 20 клеток на одном уровне. Метки живут 3 минуты.<br>3. Встаньте точно на любую из двух меток. Включите намерение вреда и нажмите ключом на шлюз рядом с этой меткой. Не двигайтесь 2 секунды. Переход стоит 1 ключ из запаса пути; перезарядка 15 секунд.")
	. += span_notice("Повторное нажатие на отмеченный шлюз на помощи <b>снимает</b> метку. Третий шлюз начинает новую пару. Заваренный шлюз или занятая клетка выхода блокируют переход.")
	. += span_notice("<b>Получить ключ при пустом запасе:</b> активируйте предмет в руке (по умолчанию Z) и подождите 2 секунды. Цена — 8 ушибов, перезарядка 30 секунд.")
	. += span_notice("<b>После изучения Размыкания:</b> нажмите ключом на свою печать в пределах 5 клеток на намерении вреда. Через секунду она взорвётся; остальные сохранятся. Потраченный ключ не возвращается. Перезарядка 15 секунд, общая с получением ключа из ладони.")
	if(user.mind == creator?.resolve() && !COOLDOWN_FINISHED(src, passage_cooldown))
		. += span_notice("До следующего перехода: [CEILING(COOLDOWN_TIMELEFT(src, passage_cooldown) / (1 SECONDS), 1)] с.")

/obj/item/heretic_path_relic/lock_key/afterattack(atom/target, mob/living/user, proximity_flag, click_parameters)
	. = ..()
	if(busy || !authorized(user))
		return
	if(user.a_intent == INTENT_HARM && istype(target, /obj/structure/heretic_lock_seal))
		release_seal(user, target)
		return
	if(!proximity_flag || !istype(target, /obj/machinery/door/airlock))
		return
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_lock/knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/base_lock)
	if(user.a_intent == INTENT_HELP)
		if(!knowledge?.bind_threshold(user, target))
			to_chat(user, span_warning("Метка не создана. Встаньте на свободный пол рядом с незаваренным шлюзом, не по диагонали, и нажмите ключом на шлюз. Вторую метку ставьте на другой клетке в пределах двадцати клеток; помещение должно разрешать телепортацию."))
	else if(user.a_intent == INTENT_HARM)
		traverse(user, target)

/obj/item/heretic_path_relic/lock_key/proc/can_release_seal(mob/living/user, obj/structure/heretic_lock_seal/seal, turf/expected_place)
	if(!authorized(user) || !COOLDOWN_FINISHED(src, relic_cooldown) || QDELETED(seal) || seal.loc != expected_place)
		return FALSE
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_lock/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/base_lock)
	return knowledge?.valid_user(user) && heretic.get_knowledge(/datum/eldritch_knowledge/spell/lock_release) && (seal in knowledge.seals) && seal.knowledge_ref?.resolve() == knowledge && (seal in view(HERETIC_LOCK_RANGE, user))

/obj/item/heretic_path_relic/lock_key/proc/release_seal(mob/living/user, obj/structure/heretic_lock_seal/seal)
	var/turf/place = get_turf(seal)
	if(busy || !can_release_seal(user, seal, place))
		return FALSE
	busy = TRUE
	new /obj/effect/temp_visual/heretic_lock/warning(place)
	seal.visible_message(span_danger("Зубья печати раздвигаются, готовясь ударить наружу!"))
	playsound(seal, 'modular_bluemoon/sound/heretic/lock_knock.ogg', 40, TRUE)
	var/completed = do_after(user, releasing_time, target = user, extra_checks = CALLBACK(src, PROC_REF(can_release_seal), user, seal, place))
	busy = FALSE
	if(!completed || !can_release_seal(user, seal, place))
		return FALSE
	var/datum/eldritch_knowledge/base_lock/knowledge = seal.knowledge_ref.resolve()
	if(!knowledge.release_seals(user, seal))
		return FALSE
	COOLDOWN_START(src, relic_cooldown, HERETIC_LOCK_SELECTIVE_RELEASE_COOLDOWN)
	return TRUE

/obj/item/heretic_path_relic/lock_key/proc/can_traverse(mob/living/user, obj/machinery/door/airlock/door, obj/structure/heretic_lock_threshold/destination, generation, silent = TRUE)
	if(!authorized(user))
		return FALSE
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_lock/knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/base_lock)
	if(!knowledge)
		return FALSE
	if(!COOLDOWN_FINISHED(src, passage_cooldown))
		return knowledge.reject_threshold(user, "Ключ ещё восстанавливает переход: осталось [CEILING(COOLDOWN_TIMELEFT(src, passage_cooldown) / (1 SECONDS), 1)] с.", silent)
	if(knowledge.combat_resource < 1)
		return knowledge.reject_threshold(user, "В запасе пути нет ключей. Активируйте ритуальный ключ в руке (по умолчанию Z), чтобы получить 1 ключ за 8 ушибов.", silent)
	if(QDELETED(destination) || knowledge.court_generation != generation)
		return knowledge.reject_threshold(user, "Связь меток разорвана. Отметьте два шлюза заново на намерении помощи.", silent)
	return knowledge.threshold_destination(user, door, silent) == destination

/obj/item/heretic_path_relic/lock_key/proc/traverse(mob/living/user, obj/machinery/door/airlock/door)
	if(busy || !authorized(user))
		return FALSE
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_lock/knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/base_lock)
	var/obj/structure/heretic_lock_threshold/destination = knowledge?.threshold_destination(user, door, silent = FALSE)
	if(!destination)
		return FALSE
	var/generation = knowledge?.court_generation
	if(!can_traverse(user, door, destination, generation, silent = FALSE))
		return FALSE
	busy = TRUE
	user.visible_message(span_warning("[user] поворачивает золотой ключ в воздухе перед шлюзом. На полу разгорается скважина!"))
	new /obj/effect/temp_visual/heretic_lock/warning(get_turf(user))
	new /obj/effect/temp_visual/heretic_lock/warning(get_turf(destination))
	playsound(destination, 'modular_bluemoon/sound/heretic/lock_knock.ogg', 50, TRUE)
	var/completed = do_after(user, passage_time, target = door, extra_checks = CALLBACK(src, PROC_REF(can_traverse), user, door, destination, generation))
	busy = FALSE
	if(!completed)
		to_chat(user, span_warning("Переход прерван: оставайтесь на метке, держите ключ в руке и не меняйте условия перехода до конца подготовки. Ключ из запаса не потрачен."))
		return FALSE
	if(!can_traverse(user, door, destination, generation, silent = FALSE) || !knowledge.spend_combat_resource())
		return FALSE
	var/turf/origin = get_turf(user)
	var/turf/landing = get_turf(destination)
	if(!do_teleport(user, landing, channel = TELEPORT_CHANNEL_MAGIC) || get_turf(user) != landing)
		knowledge.gain_combat_resource()
		to_chat(user, span_warning("Телепортация сорвалась. Ключ возвращён в запас пути."))
		return FALSE
	COOLDOWN_START(src, passage_cooldown, HERETIC_LOCK_THRESHOLD_COOLDOWN)
	new /obj/effect/temp_visual/heretic_lock/release(origin)
	new /obj/effect/temp_visual/heretic_lock/release(landing)
	log_game("[key_name(user)] прошёл между порогами Замка из [AREACOORD(origin)] в [AREACOORD(landing)].")
	return TRUE

/obj/item/heretic_path_relic/lock_key/proc/can_cut(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_lock/knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/base_lock)
	return authorized(user) && COOLDOWN_FINISHED(src, relic_cooldown) && knowledge?.valid_user(user) && !knowledge.combat_resource

/obj/item/heretic_path_relic/lock_key/attack_self(mob/living/user)
	return cut_key(user)

/obj/item/heretic_path_relic/lock_key/proc/cut_key(mob/living/user)
	if(busy || !can_cut(user))
		return FALSE
	busy = TRUE
	user.visible_message(span_warning("[user] медленно проворачивает золотой ключ в собственной ладони."))
	var/completed = do_after(user, cutting_time, target = user, extra_checks = CALLBACK(src, PROC_REF(can_cut), user))
	busy = FALSE
	if(!completed || !can_cut(user))
		return FALSE
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_lock/knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/base_lock)
	user.adjustBruteLoss(8)
	knowledge.gain_combat_resource()
	COOLDOWN_START(src, relic_cooldown, 30 SECONDS)
	playsound(user, 'modular_bluemoon/sound/heretic/lock_knock.ogg', 40, TRUE)
	return TRUE

/datum/eldritch_knowledge/lock_blade_upgrade
	name = "Зубья ключа"
	gain_text = "В лабиринте редко точат ножи. Достаточно подобрать правильную скважину."
	desc = "Клинок наносит 5 дополнительных ушибов, если противник находится рядом с вашей печатью. Стена между целью и печатью мешает усилению."
	cost = 2
	route = PATH_LOCK

/datum/eldritch_knowledge/lock_blade_upgrade/on_eldritch_blade(atom/target, mob/living/user, proximity_flag, click_parameters)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_lock/knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/base_lock)
	if(!proximity_flag || !knowledge?.valid_user(user) || !heretic_can_affect(user, target, chargecost = 0))
		return
	var/list/nearby = view(1, target)
	for(var/obj/structure/heretic_lock_seal/seal as anything in knowledge.seals)
		if(!(seal in nearby) || !seal.Adjacent(target))
			continue
		var/mob/living/victim = target
		victim.adjustBruteLoss(5)
		return

/datum/eldritch_knowledge/spell/lock_release
	name = "Размыкание"
	gain_text = "Однажды все засовы отодвинулись разом. Только тогда я услышал, сколько людей стояло у дверей."
	desc = "Разрушает все ваши видимые печати в пяти клетках. Противники рядом с ними получают 30 ушибов, однократно за применение. Стены закрывают от взрыва; союзники и антимагия защищены. Перезарядка 25 секунд. Для одиночного размыкания укажите ритуальным ключом на вреде свою печать до пяти клеток: секунда предупреждения, тот же урон, остальные печати сохраняются. Ключ из печати не возвращается; одиночное размыкание перезаряжается 15 секунд и делит откат с добычей ключа из ладони."
	cost = 1
	route = PATH_LOCK
	spell_to_add = /obj/effect/proc_holder/spell/self/heretic_lock/release

/datum/eldritch_knowledge/lock_hinges
	name = "Петли лабиринта"
	gain_text = "Дом покоился на петлях. Привратник смазывал их тем, что оставалось от непрошеных гостей."
	desc = "Предел печатей возрастает с четырёх до десяти, прочность — с 60 до 90. Усиление существующих печатей сохраняет полученный урон и оставшееся время."
	cost = 2
	route = PATH_LOCK
	passive_values = list(90, 105, 120)
	passive_desc = "Прочность печатей составляет 90 / 105 / 120. Уже полученный урон и срок жизни сохраняются."

/datum/eldritch_knowledge/lock_hinges/on_body_gain(mob/living/user)
	on_passive_upgrade(user)

/datum/eldritch_knowledge/lock_hinges/on_passive_upgrade(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_lock/knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/base_lock)
	for(var/obj/structure/heretic_lock_seal/seal as anything in knowledge?.seals)
		var/damage = seal.max_integrity - seal.obj_integrity
		seal.max_integrity = passive_values[passive_level]
		seal.obj_integrity = max(0, seal.max_integrity - damage)

/datum/eldritch_knowledge/spell/lock_court
	name = "Замкнутый двор"
	gain_text = "Я вышел во двор. Восемь дверей закрылись за мной, хотя вошёл я только через одну."
	desc = "За 2 ключа воздвигает восемь печатей по краю квадрата 3×3 вокруг видимой точки в пяти клетках. Подготовка длится 2 секунды и отмечает будущие преграды. Занятые клетки пропускаются; нужны хотя бы три свободных места и запас общего лимита. Перезарядка 40 секунд."
	cost = 2
	sacs_needed = HERETIC_PENULTIMATE_SACRIFICES
	route = PATH_LOCK
	spell_to_add = /obj/effect/proc_holder/spell/pointed/heretic_lock/court

/datum/eldritch_knowledge/final_eldritch/lock_final
	parallax_scene = ANTAG_SCENE_HERETIC_LOCK
	name = "Отпереть Лабиринт"
	gain_text = "Привратник поклонился и исчез. Связка ключей осталась у меня, и каждая дверь Дома узнала нового хозяина."
	desc = "После трёх назначенных душ принесите три человеческих трупа. Обряд раскроет своё место станции и даст 30 секунд на вмешательство. После вознесения вы получаете общую стойкость вознесения. Предел увеличивается до 16 печатей и 6 ключей, а урон Размыкания - до 45. «Ключник»: стоя в шлюзе или рядом с ним, выберите другой шлюз в пятнадцати клетках на этом уровне. Оба шлюза вспыхивают золотой скважиной, и после секунды неподвижности вы выходите из выбранного. Заваренные, сломанные и неразрушимые шлюзы и помещения без телепортации не подходят; перезарядка 10 секунд. Шлюз, через который вы прошли, сам закрывается за вами и на 8 секунд опускает болты, если в проёме никого нет и у шлюза есть питание. Поднять их можно как обычно: через ИИ, пульт шлюзов или мультитулом. «Дом без стен» за 2 секунды окружает вас печатями по краю квадрата 5×5 и восполняет ключи; перезарядка 60 секунд."
	route = PATH_LOCK
	required_atoms = list(/mob/living/carbon/human, /mob/living/carbon/human, /mob/living/carbon/human)
	ascension_spells = list(/obj/effect/proc_holder/spell/self/heretic_lock/house, /obj/effect/proc_holder/spell/self/heretic_lock/keeper)
	var/datum/weakref/lock_knowledge_ref

/datum/eldritch_knowledge/final_eldritch/lock_final/on_body_gain(mob/living/user)
	. = ..()
	if(!finished || applied_body != user)
		return
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_lock/knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/base_lock)
	if(!knowledge)
		return
	lock_knowledge_ref = WEAKREF(knowledge)
	knowledge.ascension_active = TRUE
	knowledge.combat_resource_max = 6
	knowledge.notify_resource_changed()
	user.AddComponent(/datum/component/heretic_lock_keeper)

/datum/eldritch_knowledge/final_eldritch/lock_final/on_body_lose(mob/living/user)
	var/mob/living/body = applied_body || user
	qdel(body?.GetComponent(/datum/component/heretic_lock_keeper))
	var/datum/eldritch_knowledge/base_lock/knowledge = lock_knowledge_ref?.resolve()
	lock_knowledge_ref = null
	if(knowledge)
		knowledge.ascension_active = FALSE
		knowledge.combat_resource_max = 4
		knowledge.combat_resource = min(knowledge.combat_resource, knowledge.combat_resource_max)
		knowledge.clear_lock_effects()
		knowledge.notify_resource_changed()
	return ..()

/obj/effect/proc_holder/spell/pointed/heretic_lock
	clothes_req = FALSE
	invocation_type = "none"
	action_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	action_icon_state = "lock_seal"
	action_background_icon_state = "bg_ecult"
	range = HERETIC_LOCK_RANGE
	selection_type = "view"
	aim_assist = FALSE

/obj/effect/proc_holder/spell/pointed/heretic_lock/can_cast(mob/user, skipcharge, silent)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_lock/knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/base_lock)
	return ..() && heretic_check(user, knowledge?.valid_user(user), silent, "Способность недоступна вашему пути или текущему телу.")

/obj/effect/proc_holder/spell/pointed/heretic_lock/seal
	name = "Запечатать проход"
	desc = "За 1 ключ создайте печать на свободном полу в пяти клетках на 30 секунд. Прочность 60, с «Петлями лабиринта» — от 90 до 120. Одновременно до четырёх печатей, после «Петель лабиринта» — до десяти, после вознесения — до шестнадцати. Еретики, слуги и антимагия проходят свободно. Снятие рукой на намерении помощи возвращает ключ. Перезарядка 8 секунд."
	active_msg = "Укажите свободный пол для печати."
	deactive_msg = "Ключ возвращается в ладонь."
	charge_max = 8 SECONDS

/obj/effect/proc_holder/spell/pointed/heretic_lock/seal/can_target(atom/target, mob/user, silent)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_lock/knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/base_lock)
	if(!heretic_require_knowledge(user, silent, /datum/eldritch_knowledge/base_lock, 1))
		return FALSE
	if(!heretic_check(user, length(knowledge.seals) < knowledge.seal_limit(), silent, "Достигнут предел печатей: [length(knowledge.seals)]/[knowledge.seal_limit()]. Снимите свою печать пустой рукой на намерении помощи или дождитесь её исчезновения."))
		return FALSE
	return heretic_check(user, isturf(target) && knowledge.valid_seal_turf(target, user), silent, "Укажите свободный видимый пол в пяти клетках от себя. На занятой клетке печать не появится.")

/obj/effect/proc_holder/spell/pointed/heretic_lock/seal/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_lock/knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/base_lock)
	if(!knowledge?.create_seal(targets[1], user))
		heretic_revert_cast(user)

/obj/effect/proc_holder/spell/pointed/heretic_lock/bolt
	action_icon_state = "lock_bolt"
	name = "Открывающий удар"
	desc = "Наносит 25 ожогов и 20 урона выносливости видимому врагу либо открывает шлюз или запертый шкаф в пяти клетках. Проходит через ваши печати, накладывая за ними изученную метку Замка. Своя печать вместо этого размыкается после секунды неподвижной подготовки: 30 ушибов соседним врагам, без возврата ключа. Перезарядка 18 секунд."
	active_msg = "Выберите противника, замок или свою печать."
	deactive_msg = "Вы отпускаете невидимый ключ."
	charge_max = 18 SECONDS
	aim_assist = TRUE
	var/opening_seal = FALSE

/obj/effect/proc_holder/spell/pointed/heretic_lock/bolt/can_cast(mob/user, skipcharge, silent)
	return heretic_check(user, !opening_seal, silent, "Печать уже размыкается. Не двигайтесь до окончания подготовки.") && ..()

/obj/effect/proc_holder/spell/pointed/heretic_lock/bolt/proc/can_open_seal(mob/living/user, obj/structure/heretic_lock_seal/seal, turf/place)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/spell/lock_bolt/knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/spell/lock_bolt)
	return !QDELETED(src) && knowledge?.granted_spell == src && !QDELETED(seal) && seal.loc == place && can_target(seal, user, TRUE)

/obj/effect/proc_holder/spell/pointed/heretic_lock/bolt/proc/clear_shot(atom/target, mob/living/user)
	if(!target || !isturf(target.loc) || !isturf(user.loc) || target.z != user.z || get_dist(target, user) > range || !(target in view(range, user)))
		return FALSE
	var/turf/target_turf = get_turf(target)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_lock/knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/base_lock)
	for(var/turf/place as anything in get_line(user, target))
		if(place == get_turf(user) || place == target_turf)
			continue
		if(place.density || place.is_blocked_turf(exclude_mobs = TRUE, ignore_atoms = knowledge?.seals))
			return FALSE
	return TRUE

/obj/effect/proc_holder/spell/pointed/heretic_lock/bolt/can_target(atom/target, mob/living/user, silent)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_lock/knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/base_lock)
	if(!knowledge?.valid_user(user) || !clear_shot(target, user))
		return heretic_check(user, FALSE, silent, "Выберите противника, запертый шлюз, шкаф или свою печать на прямой линии.")
	if(istype(target, /obj/structure/heretic_lock_seal))
		var/obj/structure/heretic_lock_seal/seal = target
		return heretic_check(user, (seal in knowledge.seals) && seal.knowledge_ref?.resolve() == knowledge, silent, "Разомкнуть можно только собственную печать.")
	if(!isliving(target))
		return heretic_check(user, knowledge.can_open_lock(target, user), silent, "Выберите противника, запертый шлюз, шкаф или свою печать на прямой линии.")
	var/mob/living/victim = target
	return heretic_check(user, victim != user && victim.stat != DEAD && !IS_HERETIC(victim) && !IS_HERETIC_MONSTER(victim), silent, "Выберите противника, запертый шлюз, шкаф или свою печать на прямой линии.", target = victim)

/obj/effect/proc_holder/spell/pointed/heretic_lock/bolt/cast(list/targets, mob/living/user)
	if(!length(targets) || opening_seal)
		return
	var/atom/target = targets[1]
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_lock/knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/base_lock)
	if(!can_target(target, user, TRUE))
		heretic_revert_cast(user)
		return
	if(istype(target, /obj/structure/heretic_lock_seal))
		var/obj/structure/heretic_lock_seal/seal = target
		var/turf/place = get_turf(seal)
		if(!can_open_seal(user, seal, place))
			heretic_revert_cast(user)
			return
		opening_seal = TRUE
		new /obj/effect/temp_visual/heretic_lock/warning(place)
		seal.visible_message(span_danger("Зубья печати раздвигаются, готовясь ударить наружу!"))
		playsound(seal, 'modular_bluemoon/sound/heretic/lock_knock.ogg', 40, TRUE)
		var/completed = do_after(user, 1 SECONDS, target = user, extra_checks = CALLBACK(src, PROC_REF(can_open_seal), user, seal, place))
		if(QDELETED(src))
			return
		opening_seal = FALSE
		if(!completed || !can_open_seal(user, seal, place) || !knowledge.release_seals(user, seal))
			heretic_revert_cast(user, "Размыкание прервано или печать больше недоступна.")
		return
	if(isliving(target))
		if(!heretic_can_affect(user, target))
			return
		var/mob/living/victim = target
		victim.adjustFireLoss(25)
		victim.adjustStaminaLoss(20)
		if(heretic.get_knowledge(/datum/eldritch_knowledge/lock_mark))
			var/list/trajectory = get_line(user, target)
			for(var/obj/structure/heretic_lock_seal/seal as anything in knowledge.seals)
				if(seal.loc != user.loc && (seal.loc in trajectory))
					victim.apply_status_effect(/datum/status_effect/eldritch/lock, knowledge)
					break
		log_combat(user, victim, "поразил Открывающим ударом")
	else if(!knowledge.open_lock(target, user))
		heretic_revert_cast(user)
		return
	for(var/turf/place as anything in get_line(user, target))
		new /obj/effect/temp_visual/heretic_lock/release(place)
	playsound(user, 'modular_bluemoon/sound/heretic/lock_knock.ogg', 45, TRUE)

/obj/effect/proc_holder/spell/pointed/heretic_lock/court
	action_icon_state = "lock_court"
	name = "Замкнутый двор"
	desc = "За 2 ключа после 2 секунд предупреждения поднимает печати по краю квадрата 3×3. Преграды и занятые клетки остаются проходами; нужен запас лимита печатей. Перезарядка 40 секунд."
	active_msg = "Выберите центр двора."
	deactive_msg = "Очертания двора исчезают."
	charge_max = 40 SECONDS
	self_castable = TRUE

/obj/effect/proc_holder/spell/pointed/heretic_lock/court/can_target(atom/target, mob/living/user, silent)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_lock/knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/base_lock)
	if(!isturf(target) || !knowledge || knowledge.court_busy || knowledge.combat_resource < 2)
		return heretic_check(user, FALSE, silent, "Двор требует 2 ключа, минимум три свободных клетки для печатей и место в их общем пределе.")
	var/list/positions = knowledge.court_turfs(target, user)
	return heretic_check(user, length(positions) >= 3 && length(knowledge.seals) + length(positions) <= knowledge.seal_limit(), silent, "Двор требует 2 ключа, минимум три свободных клетки для печатей и место в их общем пределе.")

/obj/effect/proc_holder/spell/pointed/heretic_lock/court/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_lock/knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/base_lock)
	if(!can_target(targets[1], user, TRUE))
		heretic_revert_cast(user)
		return
	var/list/positions = knowledge.court_turfs(targets[1], user)
	var/generation = knowledge.court_generation
	knowledge.court_busy = TRUE
	for(var/turf/place as anything in positions)
		new /obj/effect/temp_visual/heretic_lock/warning(place)
	var/completed = do_after(user, 2 SECONDS, target = user)
	if(QDELETED(knowledge))
		return
	if(generation == knowledge.court_generation)
		knowledge.court_busy = FALSE
	if(QDELETED(src))
		return
	if(!completed || !knowledge.raise_court(user, positions, expected_generation = generation))
		heretic_revert_cast(user)

/obj/effect/proc_holder/spell/self/heretic_lock
	clothes_req = FALSE
	invocation_type = "none"
	action_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	action_icon_state = "lock_release"
	action_background_icon_state = "bg_ecult"

/obj/effect/proc_holder/spell/self/heretic_lock/can_cast(mob/user, skipcharge, silent)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_lock/knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/base_lock)
	return ..() && heretic_check(user, knowledge?.valid_user(user), silent, "Способность недоступна вашему пути или текущему телу.")

/obj/effect/proc_holder/spell/self/heretic_lock/release
	name = "Размыкание"
	desc = "Разрушьте собственные видимые печати в пяти клетках. Враги рядом с ними получают 30 ушибов, один раз за применение. Перезарядка 25 секунд."
	charge_max = 25 SECONDS

/obj/effect/proc_holder/spell/self/heretic_lock/release/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_lock/knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/base_lock)
	if(!knowledge?.release_seals(user))
		heretic_revert_cast(user)

/obj/effect/proc_holder/spell/self/heretic_lock/keeper
	action_icon = 'modular_bluemoon/icons/obj/heretic_relics.dmi'
	action_icon_state = "lock_key"
	name = "Ключник"
	desc = "Стоя в шлюзе или рядом с ним, выберите другой шлюз в пятнадцати клетках на этом уровне. Оба шлюза вспыхивают золотой скважиной, и после секунды неподвижности вы выходите из выбранного. Заваренные, сломанные и неразрушимые шлюзы и помещения без телепортации не подходят. Перезарядка 10 секунд."
	charge_max = HERETIC_LOCK_KEEPER_COOLDOWN
	var/choosing = FALSE

/obj/effect/proc_holder/spell/self/heretic_lock/keeper/can_cast(mob/user, skipcharge, silent)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_lock/knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/base_lock)
	if(!..() || !heretic_check(user, knowledge?.ascension_active, silent, "Сначала завершите вознесение.") || !heretic_check(user, !choosing, silent, "Выход уже выбирается."))
		return FALSE
	return heretic_check(user, knowledge.keeper_entry(user), silent, "Встаньте в шлюзе или рядом с ним. Заваренный, сломанный или неразрушимый шлюз и помещение без телепортации не подходят.")

/obj/effect/proc_holder/spell/self/heretic_lock/keeper/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_lock/knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/base_lock)
	var/list/destinations = knowledge?.keeper_destinations(user)
	if(!length(destinations) || !user.client)
		heretic_revert_cast(user, "В пятнадцати клетках на этом уровне нет другого шлюза, открытого для перехода.")
		return
	choosing = TRUE
	var/choice = tgui_input_list(user, "Из какого шлюза выйти?", name, destinations, timeout = HERETIC_LOCK_KEEPER_COOLDOWN)
	if(QDELETED(src))
		return
	pass_through(user, knowledge, choice ? destinations[choice] : null)

/// Выбор держится до конца подготовки: иначе откат успевает закончиться и открыть второй переход.
/obj/effect/proc_holder/spell/self/heretic_lock/keeper/proc/pass_through(mob/living/user, datum/eldritch_knowledge/base_lock/knowledge, obj/machinery/door/airlock/exit)
	choosing = TRUE
	var/travelled = exit && !QDELETED(knowledge) && knowledge.keeper_travel(user, exit)
	if(QDELETED(src))
		return
	choosing = FALSE
	if(!exit)
		heretic_revert_cast(user, "Выход не выбран.")
		return
	if(!travelled)
		heretic_revert_cast(user, "Переход сорван: вы сошли с места, выход заварен или сломан.")
		return
	charge_counter = 0
	start_recharge()

/obj/effect/proc_holder/spell/self/heretic_lock/house
	action_icon_state = "lock_ascension"
	name = "Дом без стен"
	desc = "После 2 секунд предупреждения окружите себя до 16 печатями по краю квадрата 5×5, бесплатно. Прежние печати занимают общий лимит. Успех восполняет запас до 6 ключей. Перезарядка 60 секунд."
	charge_max = 60 SECONDS

/obj/effect/proc_holder/spell/self/heretic_lock/house/can_cast(mob/user, skipcharge, silent)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_lock/knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/base_lock)
	return ..() && heretic_check(user, knowledge?.ascension_active, silent, "Сначала завершите вознесение.") && heretic_check(user, !knowledge.court_busy, silent, "Предыдущий двор ещё создаётся.")

/obj/effect/proc_holder/spell/self/heretic_lock/house/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_lock/knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/base_lock)
	if(!knowledge?.ascension_active || knowledge.court_busy)
		heretic_revert_cast(user)
		return
	var/list/positions = knowledge.court_turfs(get_turf(user), user, radius = 2)
	var/generation = knowledge.court_generation
	if(length(positions) < 3 || length(positions) + length(knowledge.seals) > knowledge.seal_limit())
		heretic_revert_cast(user)
		return
	knowledge.court_busy = TRUE
	for(var/turf/place as anything in positions)
		new /obj/effect/temp_visual/heretic_lock/warning(place)
	var/obj/effect/temp_visual/heretic_lock_house_key/key = new(get_turf(user))
	var/completed = do_after(user, 2 SECONDS, target = user)
	if(QDELETED(knowledge))
		key.release(FALSE)
		return
	if(generation == knowledge.court_generation)
		knowledge.court_busy = FALSE
	if(QDELETED(src))
		key.release(FALSE)
		return
	if(!completed || !knowledge.ascension_active || !knowledge.raise_court(user, positions, key_cost = 0, expected_generation = generation, radius = 2))
		key.release(FALSE)
		heretic_revert_cast(user)
		return
	key.release(TRUE)
	knowledge.house_raised_fx(user, positions)
	knowledge.gain_combat_resource(knowledge.combat_resource_max)

#undef HERETIC_LOCK_RANGE
#undef HERETIC_LOCK_COURT_RADIUS
#undef HERETIC_LOCK_SEAL_LIFETIME
#undef HERETIC_LOCK_BASE_LIMIT
#undef HERETIC_LOCK_UPGRADED_LIMIT
#undef HERETIC_LOCK_ASCENDED_LIMIT
#undef HERETIC_LOCK_THRESHOLD_RANGE
#undef HERETIC_LOCK_THRESHOLD_LIFETIME
#undef HERETIC_LOCK_THRESHOLD_LIMIT
#undef HERETIC_LOCK_THRESHOLD_COOLDOWN
#undef HERETIC_LOCK_SELECTIVE_RELEASE_COOLDOWN
#undef HERETIC_LOCK_GRASP_BOLT_TIME
#undef HERETIC_LOCK_HARVEST_COOLDOWN
#undef HERETIC_LOCK_KEEPER_SEAL_DELAY
#undef HERETIC_LOCK_KEEPER_CLOSE_WAIT
#undef HERETIC_LOCK_PORTAL_OPEN
#undef HERETIC_LOCK_PORTAL_CLOSE
#undef HERETIC_LOCK_PORTAL_FAILSAFE
#undef HERETIC_LOCK_PORTAL_START
#undef HERETIC_LOCK_PORTAL_FLARE
#undef HERETIC_LOCK_PORTAL_FLARE_SHARE
#undef HERETIC_LOCK_PORTAL_TEETH
#undef HERETIC_LOCK_PORTAL_NOTCH
#undef HERETIC_LOCK_PORTAL_CLICK
#undef HERETIC_LOCK_PORTAL_LIGHT_RANGE
#undef HERETIC_LOCK_PORTAL_LIGHT_POWER
#undef HERETIC_LOCK_THREAD_SNAP
#undef HERETIC_LOCK_DISSOLVE_TIME
#undef HERETIC_LOCK_DISSOLVE_SQUEEZE
#undef HERETIC_LOCK_DISSOLVE_STRETCH
#undef HERETIC_LOCK_DISSOLVE_RISE
#undef HERETIC_LOCK_REFORM_TIME
#undef HERETIC_LOCK_REFORM_WIDE
#undef HERETIC_LOCK_REFORM_FLAT
#undef HERETIC_LOCK_REFORM_RADIUS
#undef HERETIC_LOCK_REFORM_ARMS
#undef HERETIC_LOCK_REFORM_SWIRL
#undef HERETIC_LOCK_GHOST_ALPHA
#undef HERETIC_LOCK_STREAM_TIME
#undef HERETIC_LOCK_ARRIVAL_FLASH_RANGE
#undef HERETIC_LOCK_ARRIVAL_FLASH_POWER
#undef HERETIC_LOCK_ARRIVAL_FLASH_TIME
#undef HERETIC_LOCK_CLICK_TIME
#undef HERETIC_LOCK_KEY_HEIGHT
#undef HERETIC_LOCK_KEY_SINK
#undef HERETIC_LOCK_KEY_APPEAR
#undef HERETIC_LOCK_KEY_HOLD
#undef HERETIC_LOCK_KEY_RELEASE
#undef HERETIC_LOCK_KEY_FAILSAFE
#undef HERETIC_LOCK_KEY_START
#undef HERETIC_LOCK_KEY_SINK_SCALE
#undef HERETIC_LOCK_HOUSE_WAVE_RADIUS
#undef HERETIC_LOCK_HOUSE_WAVE_TIME
#undef HERETIC_LOCK_HOUSE_FLASH_RANGE
#undef HERETIC_LOCK_HOUSE_FLASH_POWER
#undef HERETIC_LOCK_HOUSE_FLASH_TIME
#undef HERETIC_LOCK_HOUSE_QUAKE
#undef HERETIC_LOCK_HOUSE_QUAKE_RADIUS
#undef HERETIC_LOCK_HOUSE_QUAKE_TIME
#undef HERETIC_LOCK_HOUSE_RISE
#undef HERETIC_LOCK_HOUSE_RISE_SWEEP
#undef HERETIC_LOCK_HOUSE_GLINT_SWEEP
#undef HERETIC_LOCK_HOUSE_GLINT_TIME
#undef HERETIC_LOCK_SEAL_SQUASH
