#define HERETIC_SAND_RANGE 5
#define HERETIC_SAND_DELAY (1.5 SECONDS)
#define HERETIC_SAND_LIMIT 13
#define HERETIC_SAND_HIT_INTERVAL (0.8 SECONDS)
#define HERETIC_SAND_ANCHOR_TIME (5 SECONDS)
#define HERETIC_SAND_CLOCK_DAMAGE 32
#define HERETIC_SAND_HARVEST (6 SECONDS)
#define HERETIC_SAND_STEP_RANGE 4
#define HERETIC_SAND_RELEASE_DAMAGE 20
#define HERETIC_SAND_RELEASE_STAMINA 10
#define HERETIC_SAND_BURIAL_DAMAGE 28
#define HERETIC_SAND_BURIAL_RADIUS 2
#define HERETIC_SAND_EXTRA_DELAY (1.5 SECONDS)
#define HERETIC_SAND_COUNTDOWN (0.5 SECONDS)
#define HERETIC_SAND_COUNTDOWN_VOLUME 35
#define HERETIC_SAND_IMPACT_VOLUME 60
#define HERETIC_SAND_DROUGHT_GRAINS 10
#define HERETIC_SAND_LEVEL_FILTER "heretic_sand_level"
#define HERETIC_SAND_UPPER_TRAVEL 10
#define HERETIC_SAND_LOWER_TRAVEL 9
#define HERETIC_SAND_TETHER_DROP -11
#define HERETIC_SAND_TETHER_SNAP (0.3 SECONDS)
#define HERETIC_SAND_TETHER_MAX_GLIDE (0.5 SECONDS)
#define HERETIC_SAND_SLOW_COLOR "#d6ad70"
#define HERETIC_SAND_INK "#c8a66c"
#define HERETIC_SAND_SUN_LIGHT "#ffd98a"
#define HERETIC_SAND_RING_ICON_SIZE 320
#define HERETIC_SAND_FIELD_SPREAD 6
#define HERETIC_SAND_FIELD_SPIN (24 SECONDS)
#define HERETIC_SAND_FIELD_SEGMENTS 12
#define HERETIC_SAND_FIELD_CANVAS 320
#define HERETIC_SAND_TRAIL_DRAG 0.6
#define HERETIC_SAND_SUN_TIME (0.7 SECONDS)
#define HERETIC_SAND_SUN_RISE (0.12 SECONDS)
#define HERETIC_SAND_SUN_START 0.3
#define HERETIC_SAND_SUN_PEAK 1.6
#define HERETIC_SAND_SUN_END 2
#define HERETIC_SAND_SUN_HEIGHT 42
#define HERETIC_SAND_NOON_WAVE_RADIUS 3
#define HERETIC_SAND_NOON_WAVE_TIME (0.8 SECONDS)
#define HERETIC_SAND_NOON_FLASH_RANGE 5
#define HERETIC_SAND_NOON_FLASH_POWER 2
#define HERETIC_SAND_NOON_FLASH_TIME (0.5 SECONDS)
#define HERETIC_SAND_NOON_QUAKE 0.12
#define HERETIC_SAND_NOON_QUAKE_TIME (0.35 SECONDS)
#define HERETIC_SAND_NOON_QUAKE_RADIUS 7
#define HERETIC_SAND_NOON_PULSE_TIME (0.5 SECONDS)
#define HERETIC_SAND_NOON_TRAINING_RANGE 6
#define HERETIC_SAND_NOON_SPREAD 15
#define HERETIC_SAND_NOON_NEAR 3
#define HERETIC_SAND_ANCHOR_CRAFT "sand_anchor"
#define HERETIC_SAND_ANCHOR_CLUE "Песок в часах течёт вверх."
#define HERETIC_SAND_CAPTURE "sand"
#define HERETIC_SAND_DROUGHT_SLOWDOWN 0.5
#define HERETIC_SAND_STASIS_RANGE 3
#define HERETIC_SAND_STASIS_COST 2
#define HERETIC_SAND_STASIS_TELEGRAPH (1 SECONDS)
#define HERETIC_SAND_STASIS_COOLDOWN (40 SECONDS)
#define HERETIC_SAND_STASIS_CHECK (0.5 SECONDS)
#define HERETIC_SAND_REWIND_COOLDOWN (30 SECONDS)
#define HERETIC_SAND_REWIND_GRACE (2 SECONDS)
#define HERETIC_SAND_REWIND_SLOWDOWN 1
#define HERETIC_SAND_REWIND_ALPHA 200
#define HERETIC_SAND_EFFECT_SHIFT -16
#define HERETIC_SAND_HASTE_MULTIPLIER 0.5
#define HERETIC_SAND_DROUGHT_STEP 0.3
#define HERETIC_SAND_TRIP_COOLDOWN (4 SECONDS)
#define HERETIC_SAND_MIRE_FADE (0.8 SECONDS)
#define HERETIC_SAND_MIRE_APPEAR (0.3 SECONDS)
#define HERETIC_SAND_MIRE_PER_LEVEL (1 SECONDS)
#define HERETIC_SAND_STILL_GRAINS 26
#define HERETIC_SAND_SEAL_REACH 40
#define HERETIC_SAND_SEAL_SWIRL 120
#define HERETIC_SAND_SEAL_ARMS 5
#define HERETIC_SAND_SEAL_TRAVEL (0.8 SECONDS)
#define HERETIC_SAND_SEAL_EMIT (0.3 SECONDS)

GLOBAL_LIST_INIT(heretic_sand_sounds, list(
	"scatter" = list('modular_bluemoon/sound/heretic/sand_scatter_1.ogg', 'modular_bluemoon/sound/heretic/sand_scatter_2.ogg', 'modular_bluemoon/sound/heretic/sand_scatter_3.ogg'),
	"trip" = list('modular_bluemoon/sound/heretic/sand_trip_1.ogg', 'modular_bluemoon/sound/heretic/sand_trip_2.ogg'),
	"mire" = list('modular_bluemoon/sound/heretic/sand_mire_1.ogg', 'modular_bluemoon/sound/heretic/sand_mire_2.ogg'),
	"step" = list('modular_bluemoon/sound/heretic/sand_step_1.ogg', 'modular_bluemoon/sound/heretic/sand_step_2.ogg'),
	"recall" = list('modular_bluemoon/sound/heretic/sand_recall.ogg'),
	"seal" = list('modular_bluemoon/sound/heretic/sand_seal.ogg'),
	"unseal" = list('modular_bluemoon/sound/heretic/sand_unseal.ogg'),
	"rewind" = list('modular_bluemoon/sound/heretic/sand_rewind.ogg'),
	"arrive" = list('modular_bluemoon/sound/heretic/sand_arrive.ogg'),
	"point" = list('modular_bluemoon/sound/heretic/sand_point.ogg'),
	"burial" = list('modular_bluemoon/sound/heretic/sand_burial.ogg'),
	"noon" = list('modular_bluemoon/sound/heretic/sand_noon.ogg'),
))

/// Играет звук события Песка из его набора и возвращает выбранный файл.
/proc/heretic_sand_sound(atom/source, kind, volume, vary = FALSE)
	. = pick(GLOB.heretic_sand_sounds[kind])
	if(volume > 0)
		playsound(source, ., volume, vary)

/datum/heretic_path/sand
	id = PATH_SAND
	deed_type = /datum/heretic_deed/sand
	name = "Песок"
	tagline = "Ставит часы, которые бьют в свой срок, останавливает время врага и отматывает себя назад."
	craft_summary = "Хватка в «Помощи» по полу ставит до 3 засечек: к ним ведёт Откат, с Течением часа у них обряд вдвое быстрее."
	capture_summary = "Осыпь вплотную или Хватка - Засуха, Стазис держит цель 10 с, хоть стоящую; сердце уводит её в изнанку."
	escape_summary = "Откат реликвией за 3 с к засечке в 25 клетках, на соседний этаж за 5 с; из изнанки - к засечке."
	strength_points = list(
		"С Течением часа ритуалы, руна и обряд сердцем у засечки идут вдвое быстрее, в изнанке - если её вход рядом.",
		"Осыпь и Хватка насылают Засуху: шаг медленнее, наручники и лечение дольше, удар часов валит с ног.",
		"Часы метки и Погребения отматывают цель на свою клетку из 9 клеток, хоть из-за угла.",
		"Клетка удара часов на 4,5 секунды становится Зыбуном: вошедший враг вязнет на полторы секунды.",
		"Стазис держит цель 10 секунд без урона и кровотечения; начатый Откат не срывают урон и оглушение.",
		"Вознесение поднимает 3 Полуденных часа: раз в минуту они лечат вас и ведут к себе сквозь этажи.",
	)
	weakness_points = list(
		"Засечку выдаёт песок, текущий вверх; у неё 30 прочности, нулевой жезл снимает её сразу.",
		"Стазис спадает от нулевого жезла, святой воды в крови или если растолкать за 2 секунды; антимагия защищает.",
		"Откат 3 секунды на виду, на другой этаж - 5; его срывают смерть, наручники и щит разума.",
		"Крепкая чужая хватка не даёт начать Откат и Пересыпание; из простого волочения можно.",
		"От часов спасает разбить их, уйти дальше 9 клеток или на другой этаж; антимагия и запрет телепортации тоже.",
		"Полуденные часы объявлены станции: разбитые не лечат и не принимают Последний полдень.",
	)
	knowledge = list(
		/datum/eldritch_knowledge/base_sand,
		/datum/eldritch_knowledge/sand_grasp,
		/datum/eldritch_knowledge/spell/sand_stasis,
		/datum/eldritch_knowledge/sand_mark,
		/datum/eldritch_knowledge/sand_relic,
		/datum/eldritch_knowledge/sand_haste,
		/datum/eldritch_knowledge/spell/sand_step,
		/datum/eldritch_knowledge/sand_sustain,
		/datum/eldritch_knowledge/spell/sand_burial,
		/datum/eldritch_knowledge/final_eldritch/sand_final,
	)

/datum/eldritch_knowledge/base_sand
	name = "Между двумя песчинками"
	summary = "Осыпь бьёт соседей и ставит часы; Хватка в «Помощи» по полу ставит засечки."
	details = list(
		"Нож и стекло создают клинок истёкшего часа.",
		"Осыпь за единицу песка: соседям 20 ушибов, 10 выносливости и Засуха, затем часы на 4 соседних клетках.",
		"Часы бьют свою клетку, когда пустеет верхняя колба, через 1,5 секунды: 32 ушиба, 20 выносливости; прочность 15.",
		"Клетка удара 4,5 секунды остаётся Зыбуном: вошедший враг вязнет на 1,5 секунды, одна воронка - один раз.",
		"Хватка в «Помощи» по свободному полу ставит засечку; до 3, новая вытесняет старую.",
		"У засечки 30 прочности, песок в ней течёт вверх, нулевой жезл её снимает; смерть её не трогает.",
		"Засечка в новом отделе станции продвигает дело пути; из изнанки можно выйти к своей засечке на станции.",
	)
	role = HERETIC_ROLE_CRAFT
	gain_text = "Я перевернул часы. Сверху осталось столько же песка. Снизу появилась моя тень."
	route = PATH_SAND
	required_atoms = list(/obj/item/kitchen/knife, /obj/item/stack/sheet/glass)
	result_atoms = list(/obj/item/melee/sickly_blade/sand)
	combat_resource = 2
	combat_resource_name = "Песок"
	resource_rules = list(
		"Начальный запас 2 из 4; пустой запас восстанавливается до единицы за 8 секунд.",
		"Клинок или заклинание возвращают единицу раз в 6 секунд, с Глубокой колбой раз в 5 / 4 / 3 секунды.",
		"Хватка даёт две единицы раз в 6 секунд, взрыв метки - одну.",
		"Осыпь и Пересыпание стоят единицу, Стазис и Погребение - две; при 13 часах Осыпь убирает старые часы без цели.",
		"Одну и ту же цель часы бьют не чаще раза в 0,8 секунды.",
		"Смена тела обрывает часы, Стазис и точку возврата; засечки и Полуденные часы остаются.",
	)
	combat_resource_action = /obj/effect/proc_holder/spell/self/heretic_sand/release
	grasp_visual = /obj/effect/temp_visual/heretic_sand/grasp
	grasp_sound = 'modular_bluemoon/sound/heretic/sand_grasp.ogg'
	grasp_catchphrase = "SME'LIS BE'GA"
	var/mob/living/sand_body
	var/list/obj/structure/heretic_sand_hourglass/hourglasses = list()
	var/list/datum/status_effect/eldritch/sand/marks = list()
	var/list/last_clock_hits = list()
	var/obj/structure/heretic_sand_anchor/anchor
	/// Засечки ремесла, старейшая первой; точка возврата реликвии сюда не входит.
	var/list/obj/structure/heretic_sand_anchor/anchors = list()
	var/list/datum/status_effect/heretic_sand_stasis/stases = list()
	var/list/obj/effect/heretic_sand_mire/mires = list()
	var/sand_failure
	var/ascension_active = FALSE
	var/harvest_interval = HERETIC_SAND_HARVEST
	/// Когда в последний раз звучал звук каждого вида часов: поле из 13 часов бьёт разом, а слышно один удар.
	var/list/sounds_heard_at = list()
	/// Шаги основного цикла, о которых уже подсказали: каждая подсказка звучит один раз.
	var/list/taught = list()
	var/list/obj/structure/heretic_sand_noon/noon_clocks = list()
	var/noon_raised = FALSE
	/// Часы полигона: их подъём и распад станции не объявляют.
	var/noon_silent = FALSE
	var/noon_timer
	var/next_noon_at = 0
	COOLDOWN_DECLARE(grasp_harvest)
	COOLDOWN_DECLARE(recovery)

/datum/eldritch_knowledge/base_sand/on_gain(mob/user)
	. = ..()
	var/datum/antag_training_session/session = GLOB.antag_training_sessions[user?.ckey]
	if(session?.current_body == user && !session.sand_lesson)
		to_chat(user, span_notice("Для Песка на полигоне есть пошаговый урок: панель полигона, вкладка «Начать», раздел «2. Упражнение», кнопка «Урок Песка»."))

/datum/eldritch_knowledge/base_sand/on_body_gain(mob/living/user)
	if(!user?.mind || sand_body == user)
		return
	if(sand_body)
		on_body_lose(sand_body)
	sand_body = user
	RegisterSignal(user, COMSIG_PARENT_QDELETING, PROC_REF(on_body_deleted))
	grant_combat_power(user)
	update_capacity()
	COOLDOWN_START(src, recovery, 8 SECONDS)

/datum/eldritch_knowledge/base_sand/on_body_lose(mob/living/user)
	if(sand_body)
		UnregisterSignal(sand_body, COMSIG_PARENT_QDELETING)
	sand_body = null
	ascension_active = FALSE
	remove_combat_power()
	clear_sand(keep_noon = TRUE)

/datum/eldritch_knowledge/base_sand/proc/on_body_deleted(datum/source)
	SIGNAL_HANDLER
	on_body_lose(sand_body)

/datum/eldritch_knowledge/base_sand/on_death(mob/user)
	clear_sand(noon_reason = "еретик Песка погиб")
	combat_resource = 0
	notify_resource_changed()

/datum/eldritch_knowledge/base_sand/Destroy()
	clear_noon("еретик Песка лишился своей силы")
	on_body_lose(sand_body)
	for(var/obj/structure/heretic_sand_anchor/craft_anchor as anything in anchors.Copy())
		qdel(craft_anchor)
	anchors.Cut()
	return ..()

/// Полуденные часы переживают смену тела: вознесение переходит в новое тело вместе с ними.
/datum/eldritch_knowledge/base_sand/proc/clear_sand(keep_noon = FALSE, noon_reason)
	QDEL_LIST(hourglasses)
	QDEL_LIST(marks)
	QDEL_LIST(stases)
	QDEL_LIST(mires)
	QDEL_NULL(anchor)
	if(!keep_noon)
		clear_noon(noon_reason)
	last_clock_hits.Cut()

/// Подсказка шага основного цикла звучит один раз за раунд.
/datum/eldritch_knowledge/base_sand/proc/teach(step, message)
	if(QDELETED(sand_body) || (step in taught))
		return FALSE
	taught += step
	to_chat(sand_body, span_notice("Подсказка Песка: [message]"))
	return TRUE

/datum/eldritch_knowledge/base_sand/combat_resource_state()
	return "Засечек: [length(anchors)] из [HERETIC_SAND_ANCHOR_LIMIT]."

/datum/eldritch_knowledge/base_sand/proc/clear_knowledge(datum/eldritch_knowledge/required)
	for(var/obj/structure/heretic_sand_hourglass/hourglass as anything in hourglasses.Copy())
		if(hourglass.knowledge_ref?.resolve() == required)
			qdel(hourglass)

/datum/eldritch_knowledge/base_sand/proc/can_use(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	return !QDELETED(src) && isliving(user) && user == sand_body && !heretic_incapacitated(user) && isturf(user.loc) && heretic?.selected_path == PATH_SAND && !heretic.role_removed && heretic.get_knowledge(type) == src

/datum/eldritch_knowledge/base_sand/proc/update_capacity(ignore_sustain = FALSE, ignore_ascension = FALSE)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(sand_body)
	var/datum/eldritch_knowledge/sand_sustain/sustain = heretic?.get_knowledge(/datum/eldritch_knowledge/sand_sustain)
	var/datum/eldritch_knowledge/final_eldritch/sand_final/finale = heretic?.get_knowledge(/datum/eldritch_knowledge/final_eldritch/sand_final)
	var/ascended_capacity = !ignore_ascension && !QDELETED(finale) && finale.finished && heretic.ascended
	combat_resource_max = ascended_capacity ? 8 : !ignore_sustain && !QDELETED(sustain) ? sustain.passive_values[sustain.passive_level] : initial(combat_resource_max)
	harvest_interval = HERETIC_SAND_HARVEST - (!ignore_sustain && !QDELETED(sustain) ? sustain.passive_level * 1 SECONDS : 0)
	combat_resource = min(combat_resource, combat_resource_max)
	notify_resource_changed()

/datum/eldritch_knowledge/base_sand/proc/harvest(mob/living/user)
	if(!can_use(user) || !COOLDOWN_FINISHED(src, resource_harvest))
		return
	gain_combat_resource()
	COOLDOWN_START(src, resource_harvest, harvest_interval)

/datum/eldritch_knowledge/base_sand/on_life(mob/user)
	if(!can_use(user) || !COOLDOWN_FINISHED(src, recovery))
		return
	if(ascension_active || combat_resource < 1)
		gain_combat_resource()
	COOLDOWN_START(src, recovery, ascension_active ? 4 SECONDS : 8 SECONDS)

/datum/eldritch_knowledge/base_sand/on_eldritch_blade(atom/target, mob/user, proximity_flag, click_parameters)
	if(proximity_flag && isturf(target?.loc) && heretic_can_affect(user, target, chargecost = 0))
		harvest(user)

/datum/eldritch_knowledge/base_sand/on_mark_detonated(mob/living/user, mob/living/target)
	if(can_use(user) && isturf(target?.loc) && heretic_can_affect(user, target, chargecost = 0))
		gain_combat_resource()

/datum/eldritch_knowledge/base_sand/proc/tile_open(turf/tile)
	return isopenturf(tile) && !tile.is_blocked_turf(exclude_mobs = TRUE)

/datum/eldritch_knowledge/base_sand/proc/line_clear(atom/start, atom/end, distance = HERETIC_SAND_RANGE)
	var/turf/origin = get_turf(start)
	var/turf/destination = get_turf(end)
	if(!origin || !destination || origin.z != destination.z || get_dist(origin, destination) > distance)
		return FALSE
	var/turf/previous
	for(var/turf/tile as anything in get_line(origin, destination))
		if(!heretic_line_tile_open(tile))
			return FALSE
		if(previous && previous.x != tile.x && previous.y != tile.y)
			if(!heretic_line_tile_open(locate(previous.x, tile.y, tile.z)) || !heretic_line_tile_open(locate(tile.x, previous.y, tile.z)))
				return FALSE
		previous = tile
	return TRUE

/datum/eldritch_knowledge/base_sand/proc/hit(mob/living/victim, damage, stamina, clock_hit = FALSE)
	if(!can_use(sand_body) || !isturf(victim?.loc) || !line_clear(sand_body, victim, HERETIC_SAND_RANGE + 2))
		return FALSE
	if(clock_hit)
		for(var/key in last_clock_hits.Copy())
			if(last_clock_hits[key] <= world.time)
				last_clock_hits.Remove(key)
		var/victim_key = REF(victim)
		if(last_clock_hits[victim_key] > world.time)
			return FALSE
		last_clock_hits[victim_key] = world.time + HERETIC_SAND_HIT_INTERVAL
	if(!heretic_can_affect(sand_body, victim))
		return FALSE
	var/damage_before = victim.getBruteLoss()
	victim.adjustBruteLoss(damage)
	if(QDELETED(victim) || !can_use(sand_body))
		return TRUE
	if(clock_hit && victim.getBruteLoss() > damage_before)
		var/datum/antagonist/heretic/heretic = IS_HERETIC(sand_body)
		heretic?.advance_combat_deed(victim, PATH_SAND)
	victim.adjustStaminaLoss(stamina)
	if(clock_hit)
		trip(victim)
	harvest(sand_body)
	return TRUE

/// Песок в суставах: удар часов сбивает с ног цель под Засухой, не чаще раза в HERETIC_SAND_TRIP_COOLDOWN.
/datum/eldritch_knowledge/base_sand/proc/trip(mob/living/victim)
	var/datum/status_effect/heretic_sand_drought/drought = victim?.has_status_effect(/datum/status_effect/heretic_sand_drought)
	if(QDELETED(victim) || !drought || !COOLDOWN_FINISHED(drought, trip_cooldown))
		return FALSE
	if(!victim.Knockdown(HERETIC_SAND_TRIP_TIME))
		return FALSE
	COOLDOWN_START(drought, trip_cooldown, HERETIC_SAND_TRIP_COOLDOWN)
	new /obj/effect/temp_visual/heretic_sand/trip(get_turf(victim))
	heretic_sand_sound(victim, "trip", 55, TRUE)
	victim.visible_message(span_danger("Песок забивается [victim] в суставы, и ноги подкашиваются!"), span_userdanger("Песок скрипит в суставах - ноги подкашиваются!"))
	teach("trip", "часы сбили [victim] с ног. Сбитая или увязшая в Зыбуне цель не успеет шагнуть из смыкающегося песка Стазиса.")
	SEND_SIGNAL(src, COMSIG_HERETIC_SAND_EVENT, "trip", victim)
	return TRUE

/// Засуха на поражённого: с этой секунды Стазис берёт его и стоящим.
/datum/eldritch_knowledge/base_sand/proc/dry_out(mob/living/victim)
	if(QDELETED(victim))
		return FALSE
	victim.apply_status_effect(/datum/status_effect/heretic_sand_drought)
	if(!victim.has_status_effect(/datum/status_effect/heretic_sand_drought))
		return FALSE
	var/datum/antagonist/heretic/heretic = IS_HERETIC(sand_body)
	if(heretic?.get_knowledge(/datum/eldritch_knowledge/spell/sand_stasis))
		teach("drought", "с [victim] сыплется песок - это Засуха на [HERETIC_SAND_DROUGHT_DURATION / (1 SECONDS)] секунд. Сейчас Стазис: цель не дальше [HERETIC_SAND_STASIS_RANGE] клеток, [HERETIC_SAND_STASIS_COST] песка. Стоящая может шагнуть из песка за секунду смыкания, сбитая часами или увязшая - нет.")
	else
		teach("drought", "с [victim] сыплется песок - это Засуха на [HERETIC_SAND_DROUGHT_DURATION / (1 SECONDS)] секунд. Изучите Стазис: он останавливает время цели под Засухой или на Зыбуне.")
	SEND_SIGNAL(src, COMSIG_HERETIC_SAND_EVENT, "drought", victim)
	return TRUE

/// Первый звук вида kind за этот тик: следующие часы того же тика молчат.
/datum/eldritch_knowledge/base_sand/proc/first_this_tick(kind)
	if(sounds_heard_at[kind] == world.time)
		return FALSE
	sounds_heard_at[kind] = world.time
	return TRUE

/// Сколько держится Зыбун: Глубокая колба продлевает его на ступень.
/datum/eldritch_knowledge/base_sand/proc/mire_time()
	var/datum/antagonist/heretic/heretic = IS_HERETIC(sand_body)
	var/datum/eldritch_knowledge/sand_sustain/sustain = heretic?.get_knowledge(/datum/eldritch_knowledge/sand_sustain)
	return HERETIC_SAND_MIRE_TIME + (QDELETED(sustain) ? 0 : sustain.passive_level * HERETIC_SAND_MIRE_PER_LEVEL)

/datum/eldritch_knowledge/base_sand/proc/hourglass_on(turf/tile)
	for(var/obj/structure/heretic_sand_hourglass/hourglass as anything in hourglasses)
		if(get_turf(hourglass) == tile)
			return hourglass
	return null

/datum/eldritch_knowledge/base_sand/proc/create_hourglass(turf/tile, datum/eldritch_knowledge/required, damage = HERETIC_SAND_CLOCK_DAMAGE, distance = HERETIC_SAND_RANGE)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(sand_body)
	if(!can_use(sand_body) || QDELETED(required) || heretic.get_knowledge(required.type) != required || !line_clear(sand_body, tile, distance) || length(hourglasses) >= HERETIC_SAND_LIMIT || hourglass_on(tile))
		return null
	return new /obj/structure/heretic_sand_hourglass(tile, src, required, damage)

/// Старые часы вне нового поля уступают место, чтобы рисунок не упирался в предел; часы с запомненной целью уходят последними.
/datum/eldritch_knowledge/base_sand/proc/make_room_for_hourglasses(needed, list/kept)
	var/overflow = length(hourglasses) + needed - HERETIC_SAND_LIMIT
	for(var/spare_recorded in list(TRUE, FALSE))
		for(var/obj/structure/heretic_sand_hourglass/hourglass as anything in hourglasses.Copy())
			if(overflow <= 0)
				return
			if((hourglass in kept) || (spare_recorded && hourglass.recorded_second))
				continue
			qdel(hourglass)
			overflow--

/datum/eldritch_knowledge/base_sand/proc/release(mob/living/user)
	sand_failure = null
	if(!can_use(user))
		return FALSE
	if(combat_resource < 1)
		sand_failure = "Для Осыпи нужна единица песка."
		return FALSE
	var/list/kept = list()
	var/fresh = 0
	for(var/direction in GLOB.cardinals)
		var/obj/structure/heretic_sand_hourglass/standing = hourglass_on(get_step(user, direction))
		if(standing)
			kept += standing
		else
			fresh++
	if(!spend_combat_resource())
		return FALSE
	make_room_for_hourglasses(fresh, kept)
	for(var/mob/living/victim in range(1, user))
		if(hit(victim, HERETIC_SAND_RELEASE_DAMAGE, HERETIC_SAND_RELEASE_STAMINA))
			dry_out(victim)
		if(!can_use(user))
			return TRUE
	for(var/direction in GLOB.cardinals)
		create_hourglass(get_step(user, direction), src)
	new /obj/effect/temp_visual/heretic_sand/cast(get_turf(user))
	heretic_sand_sound(user, "scatter", 60, TRUE)
	return TRUE

/datum/eldritch_knowledge/base_sand/proc/place_anchor(mob/living/user, turf/place)
	grasp_failure_reason = null
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(!heretic || !can_use(user) || !istype(place))
		return FALSE
	if(locate(/obj/structure/heretic_sand_anchor) in place)
		grasp_failure_reason = "Здесь уже стоят песочные часы."
		return FALSE
	if(!isopenturf(place) || isgroundlessturf(place) || place.is_blocked_turf(exclude_mobs = TRUE))
		grasp_failure_reason = "Засечка встаёт только на свободном полу, не в космосе."
		return FALSE
	var/area/place_area = get_area(place)
	if(place_area.area_flags & NOTELEPORT)
		grasp_failure_reason = "Здесь время не течёт вспять: в зоне, закрытой для телепортации, засечка не удержит Откат."
		return FALSE
	var/deed_key = heretic.deed_key_for(place)
	var/wait = is_station_level(place.z) ? heretic.deed_wait_reason(deed_key) : "Это вне станции: засечка держит Откат, но в дело не идёт и выхода из изнанки к ней нет."
	while(length(anchors) >= HERETIC_SAND_ANCHOR_LIMIT)
		var/obj/structure/heretic_sand_anchor/oldest = anchors[1]
		log_game("[key_name(user)] теряет засечку Песка в [AREACOORD(oldest)]: её вытеснила новая.")
		anchors -= oldest
		qdel(oldest)
	new /obj/structure/heretic_sand_anchor/craft(place, src)
	new /obj/effect/temp_visual/heretic_sand/cast(place)
	heretic_sand_sound(place, "point", 40)
	to_chat(user, span_eldritch("Песок в часах потёк вверх: засечка поставлена. Засечек: [length(anchors)] из [HERETIC_SAND_ANCHOR_LIMIT].[wait ? " [wait]" : ""]"))
	log_game("[key_name(user)] ставит засечку Песка в [AREACOORD(place)].")
	if(!wait)
		heretic.advance_deed(deed_key, place)
	teach("anchor", "засечка держит Откат. Реликвия «Неперевёрнутые часы» (стекло и лист золота на руне) переносит к засечке за [HERETIC_SAND_REWIND_TIME / (1 SECONDS)] секунды из [HERETIC_SAND_REWIND_RANGE] клеток, с этажа выше или ниже - за [HERETIC_SAND_REWIND_FLOOR_TIME / (1 SECONDS)] секунд.")
	SEND_SIGNAL(src, COMSIG_HERETIC_SAND_EVENT, "anchor", place)
	notify_resource_changed()
	return TRUE

/datum/eldritch_knowledge/base_sand/on_craft_removed(atom/crafted, craft_id)
	if(craft_id != HERETIC_SAND_ANCHOR_CRAFT)
		return
	anchors -= crafted
	if(!QDELETED(crafted))
		qdel(crafted)
	notify_resource_changed()

/datum/eldritch_knowledge/base_sand/pocket_exits(mob/living/user)
	. = list()
	for(var/obj/structure/heretic_sand_anchor/craft_anchor as anything in anchors)
		heretic_add_pocket_exit(., "Часы - [get_area_name(craft_anchor, TRUE)]", heretic_pocket_landing(get_turf(craft_anchor)))

/datum/eldritch_knowledge/base_sand/pocket_door(mob/living/user, mob/living/victim)
	if(!door_holds(user, victim))
		return null
	return list("name" = "в песок", "text" = "Песок вокруг [victim] осыпается внутрь себя.", "time" = HERETIC_POCKET_PULL_TIME, "check" = CALLBACK(src, PROC_REF(door_holds), user, victim))

/// Цель застыла в своём Стазисе, еретик рядом с ней.
/datum/eldritch_knowledge/base_sand/proc/door_holds(mob/living/user, mob/living/victim)
	if(!can_use(user) || QDELETED(victim) || !isturf(victim.loc) || victim.z != user.z || get_dist(user, victim) > 1)
		return FALSE
	for(var/datum/status_effect/heretic_sand_stasis/stasis as anything in stases)
		if(stasis.owner == victim)
			return TRUE
	return FALSE

/// Ближайшая засечка для Отката: сначала на своём этаже, затем этажом выше или ниже в тех же 25 клетках.
/datum/eldritch_knowledge/base_sand/proc/nearest_anchor(atom/origin, range = HERETIC_SAND_REWIND_RANGE, other_floors = TRUE)
	var/turf/center = get_turf(origin)
	if(!center)
		return null
	var/list/floors = list(center.z)
	if(other_floors)
		for(var/turf/neighbour in list(GET_TURF_ABOVE(center), GET_TURF_BELOW(center)))
			floors += neighbour.z
	for(var/floor_z in floors)
		var/best_distance = INFINITY
		for(var/obj/structure/heretic_sand_anchor/craft_anchor as anything in anchors)
			var/turf/place = get_turf(craft_anchor)
			if(!place || place.z != floor_z || !anchor_usable(craft_anchor))
				continue
			var/distance = max(abs(place.x - center.x), abs(place.y - center.y))
			if((floor_z == center.z && !distance) || distance > range || distance >= best_distance)
				continue
			best_distance = distance
			. = craft_anchor
		if(.)
			return

/datum/eldritch_knowledge/base_sand/proc/anchor_usable(atom/target)
	var/turf/place = get_turf(target)
	var/area/place_area = get_area(place)
	return !QDELETED(target) && place && !(place_area.area_flags & NOTELEPORT) && !place.is_blocked_turf(exclude_mobs = TRUE)

/// Почему Откат не начнётся отсюда; перезарядку проверяет сам источник.
/datum/eldritch_knowledge/base_sand/proc/rewind_block_reason(mob/living/user)
	var/containment = heretic_containment_reason(user)
	if(containment)
		return containment
	if(user.buckled || user.anchored || HAS_TRAIT(user, TRAIT_NO_TELEPORT))
		return "Что-то держит вас на месте: Откат не начнётся."
	var/area/origin_area = get_area(user)
	if(origin_area.area_flags & NOTELEPORT)
		return "Здесь время не течёт вспять: из этой зоны Откат недоступен."
	return null

/datum/eldritch_knowledge/base_sand/proc/stasis_block_reason(mob/living/user, atom/target, check_cost = TRUE, check_ready = TRUE)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/required = heretic?.get_knowledge(/datum/eldritch_knowledge/spell/sand_stasis)
	if(!can_use(user) || QDELETED(required))
		return "Способность недоступна вашему пути или текущему телу."
	var/reason = heretic_capture_block_reason(user, target, HERETIC_SAND_CAPTURE)
	if(reason)
		return reason
	var/mob/living/victim = target
	if(!isturf(victim.loc) || !line_clear(user, victim, HERETIC_SAND_STASIS_RANGE))
		return "Цель должна быть на полу не дальше трёх клеток по открытой линии."
	if(victim.has_status_effect(/datum/status_effect/heretic_sand_stasis))
		return "Цель уже застыла."
	if(check_ready && !stasis_ready(victim))
		return "Стазис берёт цель под Засухой или на вашем Зыбуне: заденьте её Осыпью вплотную или Хваткой."
	if(check_cost && combat_resource < HERETIC_SAND_STASIS_COST)
		return "Для Стазиса нужно [HERETIC_SAND_STASIS_COST] единицы песка."
	return null

/// Цель под Засухой или в своём Зыбуне; стоит она или лежит, решает только, успеет ли шагнуть из смыкающегося песка.
/datum/eldritch_knowledge/base_sand/proc/stasis_ready(mob/living/victim)
	if(victim.has_status_effect(/datum/status_effect/heretic_sand_drought))
		return TRUE
	var/datum/status_effect/heretic_sand_mired/mired = victim.has_status_effect(/datum/status_effect/heretic_sand_mired)
	if(mired?.sand_ref?.resolve() == src)
		return TRUE
	for(var/obj/effect/heretic_sand_mire/mire in victim.loc)
		if(mire.sand_ref?.resolve() == src)
			return TRUE
	return FALSE

/datum/eldritch_knowledge/base_sand/proc/stasis(mob/living/user, mob/living/victim)
	sand_failure = stasis_block_reason(user, victim)
	if(sand_failure || !spend_combat_resource(HERETIC_SAND_STASIS_COST))
		return FALSE
	var/turf/place = get_turf(victim)
	new /obj/effect/temp_visual/heretic_sand/stasis(place)
	heretic_vfx_converge(place, /particles/heretic_ascension/sand, HERETIC_SAND_SEAL_REACH, HERETIC_SAND_SEAL_TRAVEL, HERETIC_SAND_SEAL_EMIT, HERETIC_SAND_SEAL_ARMS, HERETIC_SAND_SEAL_SWIRL)
	addtimer(CALLBACK(src, PROC_REF(seal_stasis), user, victim, place), HERETIC_SAND_STASIS_TELEGRAPH)
	user.visible_message(span_danger("Вокруг [victim] закручивается песок, и песчинки одна за другой замирают в воздухе!"), span_notice("Песок смыкается вокруг [victim]."))
	heretic_sand_sound(place, "seal", 50)
	return TRUE

/datum/eldritch_knowledge/base_sand/proc/seal_stasis(mob/living/user, mob/living/victim, turf/place)
	if(QDELETED(src) || QDELETED(user))
		return FALSE
	if(QDELETED(victim) || victim.loc != place)
		heretic_refund_capture(user, /obj/effect/proc_holder/spell/pointed/heretic_sand/stasis, "Цель ушла из песка, и Стазис рассыпался.")
		return FALSE
	var/reason = stasis_block_reason(user, victim, check_cost = FALSE, check_ready = FALSE)
	if(reason)
		heretic_refund_capture(user, /obj/effect/proc_holder/spell/pointed/heretic_sand/stasis, "Стазис рассыпался: [reason]")
		return FALSE
	if(!victim.apply_status_effect(/datum/status_effect/heretic_sand_stasis, src))
		return FALSE
	log_combat(user, victim, "погружает в песочный стазис")
	teach("stasis", "время [victim] остановлено на [HERETIC_SAND_STASIS_DURATION / (1 SECONDS)] секунд. Цель охоты сейчас уводит в изнанку живое сердце; экипаж может растолкать цель за [HERETIC_CAPTURE_SHAKE_TIME / (1 SECONDS)] секунды, нулевой жезл и святая вода развеивают песок.")
	SEND_SIGNAL(src, COMSIG_HERETIC_SAND_EVENT, "stasis", victim)
	return TRUE

/datum/eldritch_knowledge/base_sand/proc/step_through(mob/living/user, turf/target)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/required = heretic?.get_knowledge(/datum/eldritch_knowledge/spell/sand_step)
	sand_failure = null
	if(!can_use(user) || QDELETED(required))
		return FALSE
	if(combat_resource < 1)
		sand_failure = "Для Пересыпания нужна единица песка."
	else if(user.buckled || user.anchored || HAS_TRAIT(user, TRAIT_NO_TELEPORT))
		sand_failure = "Что-то держит вас на месте: песок не пересыплется."
	else if(!istype(target) || target == get_turf(user) || !line_clear(user, target, HERETIC_SAND_STEP_RANGE))
		sand_failure = "Нужна клетка не дальше [HERETIC_SAND_STEP_RANGE] клеток по открытой линии: стены, окна и ящики её перекрывают."
	else if(target.is_blocked_turf())
		sand_failure = "Клетка занята: песку некуда пересыпаться."
	if(sand_failure)
		return FALSE
	var/turf/origin = get_turf(user)
	if(!do_teleport(user, target, channel = TELEPORT_CHANNEL_MAGIC) || get_turf(user) != target)
		sand_failure = "Песок не пересыпался: перенос что-то остановило."
		return FALSE
	if(!can_use(user) || QDELETED(required) || heretic.get_knowledge(required.type) != required)
		return TRUE
	spend_combat_resource()
	create_hourglass(origin, required)
	new /obj/effect/temp_visual/heretic_sand/cast(origin)
	new /obj/effect/temp_visual/heretic_sand/cast(target)
	heretic_sand_sound(target, "step", 55, TRUE)
	return TRUE

/datum/eldritch_knowledge/base_sand/proc/burial(mob/living/user, turf/target)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/required = heretic?.get_knowledge(/datum/eldritch_knowledge/spell/sand_burial)
	sand_failure = null
	if(!can_use(user) || QDELETED(required))
		return FALSE
	if(combat_resource < 2)
		sand_failure = "Для Погребения нужно 2 песка: Хватка по врагу даёт 2, удары клинком - по единице."
		return FALSE
	if(!istype(target) || !line_clear(user, target))
		sand_failure = "Центр Погребения - клетка не дальше [HERETIC_SAND_RANGE] клеток по открытой линии."
		return FALSE
	var/list/tiles = list()
	var/list/obj/structure/heretic_sand_hourglass/field_hourglasses = list()
	var/area_reach = HERETIC_SAND_RANGE + HERETIC_SAND_BURIAL_RADIUS
	for(var/turf/tile in range(HERETIC_SAND_BURIAL_RADIUS, target))
		if((abs(tile.x - target.x) + abs(tile.y - target.y)) % 2 || !line_clear(user, tile, area_reach))
			continue
		var/occupied = FALSE
		for(var/obj/structure/heretic_sand_hourglass/hourglass as anything in hourglasses)
			if(get_turf(hourglass) == tile)
				occupied = TRUE
				field_hourglasses += hourglass
		if(!occupied)
			tiles += tile
	if(!length(tiles))
		sand_failure = "Всё поле уже занято вашими часами."
		return FALSE
	if(!spend_combat_resource(2))
		return FALSE
	make_room_for_hourglasses(length(tiles), field_hourglasses)
	for(var/mob/living/victim in range(1, target))
		if(line_clear(target, victim, 1))
			if(hit(victim, HERETIC_SAND_BURIAL_DAMAGE, 15))
				dry_out(victim)
			if(!can_use(user))
				return TRUE
	for(var/turf/tile as anything in tiles)
		var/obj/structure/heretic_sand_hourglass/hourglass = create_hourglass(tile, required, HERETIC_SAND_CLOCK_DAMAGE, distance = area_reach)
		for(var/mob/living/victim in tile)
			if(hourglass?.record_target(victim))
				break
	new /obj/effect/temp_visual/heretic_sand/ascend(target)
	heretic_sand_sound(target, "burial", 70)
	return TRUE

/// Полдень над часами: вспыхивает солнце, по песку идёт волна, взлетают песчинки, пол дрожит.
/datum/eldritch_knowledge/base_sand/proc/last_noon(turf/target)
	new /obj/effect/temp_visual/heretic_sand_sun(target)
	heretic_vfx_shockwave(target, HERETIC_SAND_INK, HERETIC_SAND_NOON_WAVE_RADIUS, HERETIC_SAND_NOON_WAVE_TIME)
	heretic_vfx_burst(target, /particles/heretic_ascension/sand)
	heretic_vfx_flash(target, HERETIC_SAND_SUN_LIGHT, HERETIC_SAND_NOON_FLASH_RANGE, HERETIC_SAND_NOON_FLASH_POWER, HERETIC_SAND_NOON_FLASH_TIME)
	heretic_vfx_quake(target, HERETIC_SAND_NOON_QUAKE_RADIUS, HERETIC_SAND_NOON_QUAKE, HERETIC_SAND_NOON_QUAKE_TIME)
	heretic_sand_sound(target, "noon", 70)

/// Вознесение поднимает Полуденные часы: сначала на засечках, остальные - в случайных отсеках станции.
/datum/eldritch_knowledge/base_sand/proc/raise_noon(mob/living/user)
	if(noon_raised || !can_use(user))
		return FALSE
	noon_raised = TRUE
	var/list/area_names = list()
	for(var/turf/spot as anything in noon_spots(user))
		for(var/obj/structure/heretic_sand_anchor/craft/craft_anchor in spot)
			to_chat(user, span_notice("Засечка в [get_area_name(spot, TRUE)] уходит под Полуденные часы."))
			qdel(craft_anchor)
		var/obj/structure/heretic_sand_noon/clock = new(spot, src)
		area_names += get_area_name(clock, TRUE)
		new /obj/effect/temp_visual/heretic_sand/ascend(spot)
	if(!length(noon_clocks))
		return FALSE
	next_noon_at = world.time + HERETIC_SAND_NOON_PERIOD
	noon_timer = addtimer(CALLBACK(src, PROC_REF(strike_noon)), HERETIC_SAND_NOON_PERIOD, TIMER_STOPPABLE)
	log_game("[key_name(user)] поднимает Полуденные часы Песка: [english_list(area_names)].")
	to_chat(user, span_eldritch("Полуденные часы встали: [english_list(area_names)]. Раз в [HERETIC_SAND_NOON_PERIOD / (1 SECONDS)] секунд каждые стоящие часы залечивают вам [HERETIC_SAND_NOON_HEAL] урона и дают единицу песка, а Последний полдень уносит вас к ним на любой этаж."))
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	noon_silent = heretic?.simulated
	if(!noon_silent)
		priority_announce("Еретик Песка поднял Полуденные часы: [english_list(area_names)]. Раз в минуту они бьют полдень и затягивают его раны, а пока стоят хоть одни, он уходит к ним сквозь этажи. Разбейте их любым оружием; нулевой жезл раскалывает часы за два удара.", "Полуденные часы", 'sound/misc/notice1.ogg')
	return TRUE

/// Клетки для Полуденных часов: засечки на станции, затем случайный пол общих отсеков станции; на полигоне - пол рядом с еретиком.
/datum/eldritch_knowledge/base_sand/proc/noon_spots(mob/living/user)
	. = list()
	var/turf/origin = get_turf(user)
	var/training = istype(get_area(origin), /area/antag_training)
	for(var/index in length(anchors) to 1 step -1)
		var/turf/place = get_turf(anchors[index])
		if(length(.) < HERETIC_SAND_NOON_CLOCKS && noon_spot_valid(place, training) && !(place in .))
			. += place
	var/list/candidates = list()
	if(training)
		for(var/turf/open/place in range(HERETIC_SAND_NOON_TRAINING_RANGE, origin))
			if(get_dist(place, origin) > 1 && noon_spot_valid(place, TRUE))
				candidates += place
	else
		candidates = public_noon_floor()
	for(var/pass in 1 to 2)
		var/list/pool = candidates.Copy()
		while(length(.) < HERETIC_SAND_NOON_CLOCKS && length(pool))
			var/turf/place = pick_n_take(pool)
			if(place in .)
				continue
			var/crowded = FALSE
			for(var/turf/taken as anything in .)
				if(pass == 1 && taken.z == place.z && get_dist(taken, place) < (training ? 2 : HERETIC_SAND_NOON_SPREAD))
					crowded = TRUE
					break
			if(!crowded)
				. += place

/// Весь пол общих отсеков станции, куда встанут часы.
/datum/eldritch_knowledge/base_sand/proc/public_noon_floor()
	. = list()
	for(var/area_type in GLOB.the_station_areas)
		if(!heretic_station_public_area(GLOB.areas_by_type[area_type]))
			continue
		for(var/turf/open/place in get_area_turfs(area_type))
			if(noon_spot_valid(place, FALSE))
				. += place
			CHECK_TICK

/// Часы ростом в две клетки: над их клеткой нужен свободный пол, иначе верх упрётся в стену.
/datum/eldritch_knowledge/base_sand/proc/noon_spot_valid(turf/place, training)
	var/area/place_area = get_area(place)
	if(!isopenturf(place) || isgroundlessturf(place) || !place_area || (place_area.area_flags & NOTELEPORT) || istype(place_area, /area/shuttle) || place.is_blocked_turf(exclude_mobs = TRUE))
		return FALSE
	var/turf/head = get_step(place, NORTH)
	if(!isopenturf(head) || head.is_blocked_turf(exclude_mobs = TRUE) || !heretic_sand_noon_keeps_passage(place))
		return FALSE
	return training ? istype(place_area, /area/antag_training) : is_station_level(place.z)

/// По клетке можно пройти: пол без плотного; двери и люди проходу не мешают.
/proc/heretic_sand_noon_walkable(turf/place)
	if(!isopenturf(place) || isgroundlessturf(place) || place.density)
		return FALSE
	for(var/atom/movable/thing as anything in place.contents)
		if(thing.density && !ismob(thing) && !istype(thing, /obj/machinery/door))
			return FALSE
	return TRUE

/// Часы не перекрывают проход: все проходимые соседи клетки остаются связаны в обход неё, так что коридор в одну клетку не годится.
/proc/heretic_sand_noon_keeps_passage(turf/place)
	var/static/list/ring = list(NORTH, NORTHEAST, EAST, SOUTHEAST, SOUTH, SOUTHWEST, WEST, NORTHWEST)
	var/list/open = list()
	var/start = 0
	for(var/index in 1 to length(ring))
		open += heretic_sand_noon_walkable(get_step(place, ring[index]))
		if(!open[index] && !start)
			start = index
	if(!start)
		return TRUE
	var/groups = 0
	var/has_side = FALSE
	for(var/offset in 1 to length(ring))
		var/index = (start + offset - 1) % length(ring) + 1
		if(open[index])
			if(index % 2)
				has_side = TRUE
			continue
		if(has_side)
			groups++
		has_side = FALSE
	return groups <= 1

/// Полдень: каждые стоящие часы бьют, затягивают раны вознёсшегося и дают ему песок; запертый или скованный полдень пропускает, но часы продолжают отсчёт.
/datum/eldritch_knowledge/base_sand/proc/strike_noon()
	deltimer(noon_timer)
	noon_timer = null
	var/count = length(noon_clocks)
	if(!count)
		return FALSE
	next_noon_at = world.time + HERETIC_SAND_NOON_PERIOD
	noon_timer = addtimer(CALLBACK(src, PROC_REF(strike_noon)), HERETIC_SAND_NOON_PERIOD, TIMER_STOPPABLE)
	for(var/obj/structure/heretic_sand_noon/clock as anything in noon_clocks.Copy())
		clock.strike()
	if(!ascension_active || !can_use(sand_body))
		if(!QDELETED(sand_body))
			to_chat(sand_body, span_warning("Бьёт полдень, но вы не можете его принять: раны не затянулись."))
		return TRUE
	heretic_heal_pool(sand_body, HERETIC_SAND_NOON_HEAL * count)
	gain_combat_resource(count)
	heretic_vfx_pulse(sand_body, HERETIC_SAND_SUN_LIGHT, 2, HERETIC_SAND_NOON_PULSE_TIME)
	to_chat(sand_body, span_eldritch("Бьёт полдень: часов [count] - раны затягиваются, песка прибавилось."))
	var/datum/antagonist/heretic/heretic = IS_HERETIC(sand_body)
	var/datum/eldritch_knowledge/final_eldritch/sand_final/finale = heretic?.get_knowledge(/datum/eldritch_knowledge/final_eldritch/sand_final)
	if(finale)
		GLOB.heretic_sky.event(finale)
	SEND_SIGNAL(src, COMSIG_HERETIC_SAND_EVENT, "noon", sand_body)
	return TRUE

/// Часы рассыпаются не от рук экипажа: еретику и станции говорят, что полдня больше не будет.
/datum/eldritch_knowledge/base_sand/proc/clear_noon(reason)
	deltimer(noon_timer)
	noon_timer = null
	var/had_clocks = length(noon_clocks)
	for(var/obj/structure/heretic_sand_noon/clock as anything in noon_clocks.Copy())
		clock.sand_ref = null
		qdel(clock)
	noon_clocks.Cut()
	if(!had_clocks || !reason)
		return
	log_game("Полуденные часы Песка рассыпаются ([had_clocks] шт.): [reason].")
	if(!QDELETED(sand_body))
		to_chat(sand_body, span_userdanger("Полуденные часы рассыпались: полдень больше не наступит."))
	if(!noon_silent)
		minor_announce("Полуденные часы рассыпались: [reason]. Полдень больше не наступит.", "Полуденные часы")

/datum/eldritch_knowledge/base_sand/proc/noon_clock_broken(obj/structure/heretic_sand_noon/clock)
	noon_clocks -= clock
	var/left = length(noon_clocks)
	log_game("Полуденные часы Песка разбиты в [AREACOORD(clock)], осталось [left].")
	if(!QDELETED(sand_body))
		var/news = left ? "Полуденные часы в [get_area_name(clock, TRUE)] разбиты. Осталось: [left]." : "Последние Полуденные часы разбиты: полдень больше не наступит."
		to_chat(sand_body, span_userdanger(news))
	if(!left)
		deltimer(noon_timer)
		noon_timer = null

/// Ближайшие Полуденные часы не у самых ног: сначала на своём этаже, потом на любом.
/datum/eldritch_knowledge/base_sand/proc/nearest_noon_clock(mob/living/user)
	var/turf/center = get_turf(user)
	var/best_score = INFINITY
	for(var/obj/structure/heretic_sand_noon/clock as anything in noon_clocks)
		var/turf/place = get_turf(clock)
		if(!place || !clock.landing())
			continue
		var/same_floor = place.z == center.z
		var/distance = get_dist(center, place)
		if(same_floor && distance <= HERETIC_SAND_NOON_NEAR)
			continue
		var/score = (same_floor ? 0 : 1000) + (same_floor ? distance : 0)
		if(score >= best_score)
			continue
		best_score = score
		. = clock

/// Последний полдень: Откат к Полуденным часам на любом этаже.
/datum/eldritch_knowledge/base_sand/proc/noon_return(mob/living/user)
	sand_failure = null
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(!can_use(user))
		return FALSE
	if(!ascension_active || !heretic?.ascended)
		sand_failure = "Последний полдень доступен только вознёсшемуся."
		return FALSE
	var/obj/structure/heretic_sand_noon/clock = nearest_noon_clock(user)
	if(!clock)
		sand_failure = length(noon_clocks) ? "Другие Полуденные часы недоступны: их обступили или они рядом с вами." : "Все Полуденные часы разбиты."
		return FALSE
	sand_failure = rewind_block_reason(user)
	if(!sand_failure && !user.apply_status_effect(/datum/status_effect/heretic_sand_rewind/noon, src, clock))
		sand_failure = "Откат уже идёт."
	if(sand_failure)
		return FALSE
	log_game("[key_name(user)] начинает Последний полдень к часам в [AREACOORD(clock)].")
	return TRUE

/// Полуденное солнце над целью: вспыхивает с лучами и тает.
/obj/effect/temp_visual/heretic_sand_sun
	icon = 'modular_bluemoon/icons/effects/heretic_vfx.dmi'
	icon_state = "sun_flare"
	randomdir = FALSE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	layer = ABOVE_MOB_LAYER
	appearance_flags = NONE
	pixel_y = HERETIC_SAND_SUN_HEIGHT
	duration = HERETIC_SAND_SUN_TIME

/obj/effect/temp_visual/heretic_sand_sun/Initialize(mapload)
	. = ..()
	add_overlay(emissive_appearance(icon, icon_state, offset_spokesman = src))
	transform = matrix(HERETIC_SAND_SUN_START, 0, 0, 0, HERETIC_SAND_SUN_START, 0)
	animate(src, transform = matrix(HERETIC_SAND_SUN_PEAK, 0, 0, 0, HERETIC_SAND_SUN_PEAK, 0), time = HERETIC_SAND_SUN_RISE, easing = BACK_EASING | EASE_OUT)
	animate(transform = matrix(HERETIC_SAND_SUN_END, 0, 0, 0, HERETIC_SAND_SUN_END, 0), alpha = 0, time = HERETIC_SAND_SUN_TIME - HERETIC_SAND_SUN_RISE, easing = SINE_EASING | EASE_IN)
	heretic_vfx_rays(src, HERETIC_SAND_SUN_LIGHT, HERETIC_SAND_SUN_TIME)

/obj/structure/heretic_sand_hourglass
	name = "borrowed second"
	desc = "Песок стремительно пересыпается сквозь невидимое горлышко: когда верхняя колба опустеет, через 1,5 секунды, часы ударят только по этой клетке, а песок на ней ненадолго станет зыбучим. За полсекунды до удара латунь раскаляется. Отойдите, разбейте часы или коснитесь их нулевым жезлом."
	icon = 'modular_bluemoon/icons/obj/heretic_sand.dmi'
	icon_state = "sand_hourglass"
	anchored = TRUE
	density = FALSE
	max_integrity = 15
	var/datum/weakref/sand_ref
	var/datum/weakref/knowledge_ref
	var/expiry_timer
	var/countdown_timer
	var/impact_damage
	var/expires_at
	var/delayed = FALSE
	var/datum/status_effect/heretic_sand_recall/recorded_second
	var/obj/effect/abstract/heretic_sand_grains/upper/upper_sand
	var/obj/effect/abstract/heretic_sand_grains/lower/lower_sand
	var/static/list/countdown_sounds = list(
		'modular_bluemoon/sound/heretic/sand_countdown_1.ogg',
		'modular_bluemoon/sound/heretic/sand_countdown_2.ogg',
		'modular_bluemoon/sound/heretic/sand_countdown_3.ogg',
	)

/obj/structure/heretic_sand_hourglass/Initialize(mapload, datum/eldritch_knowledge/base_sand/sand, datum/eldritch_knowledge/required, damage)
	. = ..()
	if(QDELETED(sand) || QDELETED(required))
		return INITIALIZE_HINT_QDEL
	sand_ref = WEAKREF(sand)
	knowledge_ref = WEAKREF(required)
	impact_damage = damage
	expires_at = world.time + HERETIC_SAND_DELAY
	sand.hourglasses += src
	RegisterSignal(required, COMSIG_PARENT_QDELETING, PROC_REF(source_deleted))
	expiry_timer = addtimer(CALLBACK(src, PROC_REF(resolve)), HERETIC_SAND_DELAY, TIMER_STOPPABLE)
	upper_sand = new
	lower_sand = new
	vis_contents += upper_sand
	vis_contents += lower_sand
	pour_sand()

/obj/structure/heretic_sand_hourglass/proc/source_deleted(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/// Доля песка в верхней колбе: 1 - полна, 0 - пора бить.
/obj/structure/heretic_sand_hourglass/proc/sand_left()
	return upper_sand ? upper_sand.current_level() : 0

/// Песок сыплется до срока удара с того уровня, что виден сейчас: продление замедляет его, а не начинает заново.
/obj/structure/heretic_sand_hourglass/proc/pour_sand()
	var/time_left = max(expires_at - world.time, 0)
	var/left = sand_left()
	upper_sand.pour(left, 0, time_left)
	lower_sand.pour(1 - left, 1, time_left)
	icon_state = initial(icon_state)
	deltimer(countdown_timer)
	countdown_timer = addtimer(CALLBACK(src, PROC_REF(count_down)), max(time_left - HERETIC_SAND_COUNTDOWN, 0), TIMER_STOPPABLE)

/// Последние полсекунды: латунь раскаляется и часы тихо отбивают отсчёт. Возвращает сыгранный звук.
/obj/structure/heretic_sand_hourglass/proc/count_down()
	countdown_timer = null
	icon_state = "sand_hourglass_last"
	heretic_vfx_pulse(src, HERETIC_SAND_SUN_LIGHT, 1, HERETIC_SAND_COUNTDOWN)
	var/datum/eldritch_knowledge/base_sand/sand = sand_ref?.resolve()
	if(sand && !sand.first_this_tick("countdown"))
		return null
	. = pick(countdown_sounds)
	playsound(src, ., HERETIC_SAND_COUNTDOWN_VOLUME, FALSE)

/// Удар по клетке: бронза бьёт час. Возвращает сыгранный звук или null, если в этот тик часы уже били.
/obj/structure/heretic_sand_hourglass/proc/impact_sound()
	var/datum/eldritch_knowledge/base_sand/sand = sand_ref?.resolve()
	if(sand && !sand.first_this_tick("impact"))
		return null
	. = 'modular_bluemoon/sound/heretic/sand_impact.ogg'
	playsound(src, ., HERETIC_SAND_IMPACT_VOLUME, TRUE)

/// Дотянутся ли часы до цели: время возвращает её на этом уровне в HERETIC_SAND_RECALL_RANGE клетках, стены не мешают.
/obj/structure/heretic_sand_hourglass/proc/within_recall(mob/living/target)
	var/turf/here = get_turf(src)
	var/turf/there = get_turf(target)
	return sand_ref?.resolve() && isturf(target?.loc) && here && there.z == here.z && get_dist(here, there) <= HERETIC_SAND_RECALL_RANGE

/obj/structure/heretic_sand_hourglass/proc/record_target(mob/living/victim)
	var/datum/eldritch_knowledge/base_sand/sand = sand_ref?.resolve()
	if(recorded_second || !sand?.can_use(sand.sand_body) || !isturf(victim?.loc) || get_turf(victim) != get_turf(src) || !heretic_can_affect(sand.sand_body, victim, chargecost = 0))
		return FALSE
	recorded_second = victim.apply_status_effect(/datum/status_effect/heretic_sand_recall, src)
	if(recorded_second)
		desc = "[initial(desc)] Эти часы запомнили [victim]: пока к жертве тянется песчаная нить - в девяти клетках на этом уровне, хоть из-за стены, - перед ударом часы вернут её сюда."
	return !!recorded_second

/obj/structure/heretic_sand_hourglass/proc/resolve()
	var/datum/eldritch_knowledge/base_sand/sand = sand_ref?.resolve()
	var/datum/eldritch_knowledge/required = knowledge_ref?.resolve()
	var/datum/antagonist/heretic/heretic = IS_HERETIC(sand?.sand_body)
	if(sand?.can_use(sand.sand_body) && required && heretic.get_knowledge(required.type) == required && isturf(loc) && sand.line_clear(sand.sand_body, src, HERETIC_SAND_RANGE + 2))
		var/mob/living/recorded_target = recorded_second?.owner
		var/turf/destination = get_turf(src)
		if(recorded_target && get_turf(recorded_target) != destination && !recorded_target.buckled && !recorded_target.anchored && !HAS_TRAIT(recorded_target, TRAIT_NO_TELEPORT) && !destination.is_blocked_turf() && within_recall(recorded_target) && heretic_can_affect(sand.sand_body, recorded_target))
			steal_second(recorded_target, destination)
		if(QDELETED(src) || !sand.can_use(sand.sand_body))
			return
		for(var/mob/living/victim in loc)
			sand.hit(victim, impact_damage, 20, clock_hit = TRUE)
			if(QDELETED(src) || !sand.can_use(sand.sand_body))
				return
		new /obj/effect/temp_visual/heretic_sand/impact(get_turf(src))
		impact_sound()
		if(isopenturf(loc) && !isgroundlessturf(loc))
			new /obj/effect/heretic_sand_mire(loc, sand)
	qdel(src)

/// Украденная секунда: время отматывает цель на клетку часов, песок течёт за ней обратно.
/obj/structure/heretic_sand_hourglass/proc/steal_second(mob/living/target, turf/destination)
	var/turf/origin = get_turf(target)
	if(!do_teleport(target, destination, channel = TELEPORT_CHANNEL_MAGIC) || get_turf(target) != destination)
		return FALSE
	heretic_vfx_ghost(target, origin, HERETIC_SAND_SLOW_COLOR)
	heretic_vfx_stream(origin, destination, /particles/heretic_ascension/sand)
	new /obj/effect/temp_visual/heretic_sand/cast(origin)
	heretic_sand_sound(destination, "recall", 55)
	to_chat(target, span_userdanger("Секунда отматывается назад: вы снова там, где стояли у часов!"))
	return TRUE

/obj/structure/heretic_sand_hourglass/proc/delay_impact(mob/living/user)
	var/datum/eldritch_knowledge/base_sand/sand = sand_ref?.resolve()
	if(QDELETED(src) || delayed || world.time >= expires_at || !sand?.can_use(user) || !sand.line_clear(user, src) || !sand.spend_combat_resource())
		return FALSE
	delayed = TRUE
	expires_at += HERETIC_SAND_EXTRA_DELAY
	deltimer(expiry_timer)
	expiry_timer = addtimer(CALLBACK(src, PROC_REF(resolve)), expires_at - world.time, TIMER_STOPPABLE)
	pour_sand()
	color = HERETIC_SAND_SLOW_COLOR
	desc = "Песок пересыпается медленнее: создатель продлил отсчёт на 1,5 секунды, и верхняя колба опустеет к новому сроку. Часы ударят только по своей клетке; сохранённая ими цель вернётся перед ударом, если к ней ещё тянется песчаная нить - девять клеток на этом уровне. Часы можно разбить или коснуться их нулевым жезлом."
	visible_message(span_warning("[src] вспыхивают бронзовым светом. Падение песчинок замедляется!"))
	if(recorded_second?.owner)
		to_chat(recorded_second.owner, span_userdanger("Часы удерживают ваш шаг ещё на 1,5 секунды. Успейте уйти дальше девяти клеток или разбейте их!"))
	return TRUE

/obj/structure/heretic_sand_hourglass/attackby(obj/item/item, mob/living/user)
	if(istype(item, /obj/item/nullrod))
		qdel(src)
		return
	return ..()

/obj/structure/heretic_sand_hourglass/Destroy()
	deltimer(expiry_timer)
	deltimer(countdown_timer)
	vis_contents -= upper_sand
	vis_contents -= lower_sand
	QDEL_NULL(upper_sand)
	QDEL_NULL(lower_sand)
	QDEL_NULL(recorded_second)
	var/datum/eldritch_knowledge/base_sand/sand = sand_ref?.resolve()
	sand?.hourglasses.Remove(src)
	var/datum/eldritch_knowledge/required = knowledge_ref?.resolve()
	if(required)
		UnregisterSignal(required, COMSIG_PARENT_QDELETING)
	sand_ref = null
	knowledge_ref = null
	return ..()

/datum/status_effect/heretic_sand_recall
	id = "heretic_sand_recall"
	duration = -1
	tick_interval = -1
	status_type = STATUS_EFFECT_REPLACE
	alert_type = /atom/movable/screen/alert/status_effect/heretic_sand_recall
	on_remove_on_mob_delete = TRUE
	var/datum/weakref/hourglass_ref
	var/obj/effect/abstract/heretic_sand_tether/tether

/datum/status_effect/heretic_sand_recall/on_creation(mob/living/new_owner, obj/structure/heretic_sand_hourglass/hourglass)
	hourglass_ref = WEAKREF(hourglass)
	return ..()

/datum/status_effect/heretic_sand_recall/on_apply()
	if(!..())
		return FALSE
	to_chat(owner, span_userdanger("Часы запомнили ваш шаг! Через 1,5 секунды они вернут вас к себе, даже из-за угла. Разбейте часы или уйдите дальше девяти клеток!"))
	var/turf/hourglass_turf = get_turf(hourglass_ref?.resolve())
	if(hourglass_turf)
		tether = new(hourglass_turf)
		new /obj/effect/temp_visual/heretic_sand/bind(get_turf(owner))
	RegisterSignal(owner, COMSIG_MOVABLE_MOVED, PROC_REF(owner_moved))
	return TRUE

/datum/status_effect/heretic_sand_recall/proc/owner_moved(atom/movable/source)
	SIGNAL_HANDLER
	var/obj/structure/heretic_sand_hourglass/hourglass = hourglass_ref?.resolve()
	if(QDELETED(hourglass) || QDELETED(tether))
		return
	tether.follow(source, hourglass.within_recall(source))

/datum/status_effect/heretic_sand_recall/be_replaced()
	on_remove()
	return ..()

/datum/status_effect/heretic_sand_recall/on_remove()
	UnregisterSignal(owner, COMSIG_MOVABLE_MOVED)
	QDEL_NULL(tether)
	var/obj/structure/heretic_sand_hourglass/hourglass = hourglass_ref?.resolve()
	if(hourglass?.recorded_second == src)
		hourglass.recorded_second = null
	return ..()

/atom/movable/screen/alert/status_effect/heretic_sand_recall
	name = "Украденная секунда"
	desc = "Песочные часы вернут вас на отмеченную клетку перед взрывом, сколько бы вы ни пробежали. Пока от них к вам тянется песчаная нить, вы в их досягаемости - девять клеток на этом уровне, стены не спасают. Разбейте часы, уйдите дальше или сойдите на другой этаж. Антимагия и запрет телепортации защищают от возврата."
	icon = 'modular_bluemoon/icons/obj/heretic_alerts.dmi'
	icon_state = "sand_recall"

/// Песок одной колбы часов. Уровень задаёт маска, её сдвиг ведёт animate() за pour_time - без тиков.
/obj/effect/abstract/heretic_sand_grains
	icon = 'modular_bluemoon/icons/obj/heretic_sand.dmi'
	layer = FLOAT_LAYER
	vis_flags = VIS_INHERIT_ID | VIS_INHERIT_PLANE
	appearance_flags = RESET_COLOR
	var/mask_state
	var/travel = 0
	var/level_from = 0
	var/level_to = 0
	var/pour_time = 0
	var/poured_at = 0
	var/static/list/level_masks = list()

/obj/effect/abstract/heretic_sand_grains/upper
	icon_state = "sand_hourglass_upper"
	layer = FLOAT_LAYER - 1
	mask_state = "sand_hourglass_upper_mask"
	travel = HERETIC_SAND_UPPER_TRAVEL
	level_to = 1

/obj/effect/abstract/heretic_sand_grains/lower
	icon_state = "sand_hourglass_lower"
	mask_state = "sand_hourglass_lower_mask"
	travel = HERETIC_SAND_LOWER_TRAVEL

/obj/effect/abstract/heretic_sand_grains/Initialize(mapload)
	. = ..()
	pour(level_to, level_to, 0)

/obj/effect/abstract/heretic_sand_grains/proc/current_level()
	if(pour_time <= 0)
		return level_to
	return level_from + (level_to - level_from) * clamp((world.time - poured_at) / pour_time, 0, 1)

/obj/effect/abstract/heretic_sand_grains/proc/pour(from_level, to_level, time)
	level_from = from_level
	level_to = to_level
	pour_time = max(time, 0)
	poured_at = world.time
	add_filter(HERETIC_SAND_LEVEL_FILTER, 1, alpha_mask_filter(y = mask_offset(from_level), icon = level_mask()))
	if(!pour_time)
		return
	animate(get_filter(HERETIC_SAND_LEVEL_FILTER), y = mask_offset(to_level), time = pour_time)
	filter_data[HERETIC_SAND_LEVEL_FILTER]["y"] = mask_offset(to_level)

/// Отрицательный y фильтра опускает маску: пустая колба - маска ниже на travel пикселей.
/obj/effect/abstract/heretic_sand_grains/proc/mask_offset(level)
	return -(1 - level) * travel

/obj/effect/abstract/heretic_sand_grains/proc/level_mask()
	if(!level_masks[mask_state])
		level_masks[mask_state] = icon(icon, mask_state)
	return level_masks[mask_state]

/// Песчаная нить от часов к запомненной цели: видна, пока часы до неё дотягиваются, и втягивается обратно, когда цель уходит.
/obj/effect/abstract/heretic_sand_tether
	icon = 'modular_bluemoon/icons/obj/heretic_sand.dmi'
	icon_state = "sand_tether"
	layer = LOW_OBJ_LAYER
	pixel_y = HERETIC_SAND_TETHER_DROP
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	appearance_flags = PIXEL_SCALE
	alpha = 0
	var/taut = FALSE
	var/length = 0
	var/angle = 0

/obj/effect/abstract/heretic_sand_tether/proc/follow(atom/movable/target, holds)
	var/turf/end = get_turf(target)
	if(!holds || !end || end == loc || end.z != z)
		release()
		return
	var/delta_x = (end.x - x) * world.icon_size
	var/delta_y = (end.y - y) * world.icon_size
	length = sqrt(delta_x * delta_x + delta_y * delta_y)
	angle = Get_Angle(loc, end)
	var/glide = target.glide_size ? world.icon_size / target.glide_size * world.tick_lag : 0
	glide = clamp(glide, world.tick_lag, HERETIC_SAND_TETHER_MAX_GLIDE)
	if(!taut)
		transform = span(0)
	taut = TRUE
	animate(src, transform = span(length), alpha = 255, time = glide, flags = ANIMATION_LINEAR_TRANSFORM)

/obj/effect/abstract/heretic_sand_tether/proc/release()
	if(!taut)
		return
	taut = FALSE
	animate(src, transform = span(0), alpha = 0, time = HERETIC_SAND_TETHER_SNAP, easing = QUAD_EASING | EASE_IN, flags = ANIMATION_LINEAR_TRANSFORM)

/obj/effect/abstract/heretic_sand_tether/proc/span(span_length)
	var/matrix/line = matrix()
	line.Scale(1, max(span_length, 1) / world.icon_size)
	line.Translate(0, span_length / 2)
	line.Turn(angle)
	return line

/obj/structure/heretic_sand_anchor
	name = "unspent hour"
	desc = "Песочные часы в песчаном холмике отмечают место возврата на пять секунд: песок в них течёт вверх. Разбейте их или коснитесь нулевым жезлом, чтобы закрыть обратный путь."
	icon = 'modular_bluemoon/icons/obj/heretic_sand.dmi'
	icon_state = "sand_anchor"
	anchored = TRUE
	density = FALSE
	max_integrity = 25
	var/datum/weakref/sand_ref
	var/expiry_timer
	var/expires_at

/obj/structure/heretic_sand_anchor/Initialize(mapload, datum/eldritch_knowledge/base_sand/sand)
	. = ..()
	if(QDELETED(sand))
		return INITIALIZE_HINT_QDEL
	sand_ref = WEAKREF(sand)
	bind_to(sand)

/obj/structure/heretic_sand_anchor/proc/bind_to(datum/eldritch_knowledge/base_sand/sand)
	sand.anchor = src
	expires_at = world.time + HERETIC_SAND_ANCHOR_TIME
	expiry_timer = addtimer(CALLBACK(src, PROC_REF(expire)), HERETIC_SAND_ANCHOR_TIME, TIMER_STOPPABLE)

/obj/structure/heretic_sand_anchor/proc/expire()
	qdel(src)

/obj/structure/heretic_sand_anchor/attackby(obj/item/item, mob/living/user)
	if(istype(item, /obj/item/nullrod) && !heretic_craft_on(src, HERETIC_SAND_ANCHOR_CRAFT))
		qdel(src)
		return
	return ..()

/obj/structure/heretic_sand_anchor/Destroy()
	deltimer(expiry_timer)
	var/datum/eldritch_knowledge/base_sand/sand = sand_ref?.resolve()
	if(sand?.anchor == src)
		sand.anchor = null
	sand_ref = null
	return ..()

/obj/structure/heretic_sand_anchor/craft
	name = "rising hourglass"
	desc = "Песочные часы вросли в песчаный холмик, и песок в них течёт вверх. Хрупкие: их можно разбить или коснуться нулевым жезлом."
	max_integrity = HERETIC_SAND_ANCHOR_INTEGRITY

/obj/structure/heretic_sand_anchor/craft/bind_to(datum/eldritch_knowledge/base_sand/sand)
	sand.anchors += src
	AddComponent(/datum/component/heretic_craft, sand, HERETIC_SAND_ANCHOR_CRAFT, HERETIC_SAND_ANCHOR_CLUE)

/// Полуденные часы вознесения: бьют полдень для вознёсшегося, пока экипаж их не разобьёт.
/obj/structure/heretic_sand_noon
	name = "noon hourglass"
	desc = "Песочные часы в человеческий рост на песчаниковом постаменте, на крышке горит латунное солнце. Раз в минуту они бьют полдень: раны еретика Песка затягиваются, а пока стоят хоть одни такие часы, он уходит к ним сквозь этажи. Разбейте их любым оружием; нулевой жезл раскалывает их за два удара."
	icon = 'modular_bluemoon/icons/obj/heretic_sand_noon.dmi'
	icon_state = "sand_noon"
	anchored = TRUE
	density = TRUE
	max_integrity = HERETIC_SAND_NOON_INTEGRITY
	layer = ABOVE_MOB_LAYER
	light_range = 2
	light_power = 0.8
	light_color = HERETIC_SAND_SUN_LIGHT
	var/datum/weakref/sand_ref

/obj/structure/heretic_sand_noon/Initialize(mapload, datum/eldritch_knowledge/base_sand/sand)
	. = ..()
	if(QDELETED(sand))
		return INITIALIZE_HINT_QDEL
	sand_ref = WEAKREF(sand)
	sand.noon_clocks += src
	add_overlay(emissive_appearance(icon, "sand_noon_glow", offset_spokesman = src))

/obj/structure/heretic_sand_noon/examine(mob/user)
	. = ..()
	var/datum/eldritch_knowledge/base_sand/sand = sand_ref?.resolve()
	if(sand?.noon_timer)
		. += span_warning("До полудня [DisplayTimeText(max(0, sand.next_noon_at - world.time), 1)]. Прочность: [round(obj_integrity / max_integrity * 100)]%.")

/// Клетка у часов, куда принесёт Последний полдень: сами часы занимают свою.
/obj/structure/heretic_sand_noon/proc/landing()
	for(var/direction in list(SOUTH, EAST, WEST, NORTH, SOUTHEAST, SOUTHWEST, NORTHEAST, NORTHWEST))
		var/turf/spot = get_step(src, direction)
		var/area/spot_area = get_area(spot)
		if(isopenturf(spot) && !isgroundlessturf(spot) && !spot.is_blocked_turf(exclude_mobs = TRUE) && !(spot_area.area_flags & NOTELEPORT))
			return spot
	return null

/obj/structure/heretic_sand_noon/proc/strike()
	flick("sand_noon_strike", src)
	var/datum/eldritch_knowledge/base_sand/sand = sand_ref?.resolve()
	sand?.last_noon(get_turf(src))
	visible_message(span_danger("[src] бьют полдень: латунное солнце вспыхивает, песок взлетает и осыпается обратно!"))

/obj/structure/heretic_sand_noon/attackby(obj/item/item, mob/living/user, params)
	if(!istype(item, /obj/item/nullrod))
		return ..()
	user.do_attack_animation(src)
	user.changeNext_move(CLICK_CD_MELEE)
	visible_message(span_warning("[user] бьёт [src] нулевым жезлом, и по стеклу бежит трещина."))
	take_damage(max_integrity / 2, BRUTE, MELEE, FALSE)
	return TRUE

/obj/structure/heretic_sand_noon/deconstruct(disassembled = TRUE)
	var/turf/place = get_turf(src)
	if(place)
		visible_message(span_danger("[src] раскалываются, и песок полудня бесполезно рассыпается по полу."))
		new /obj/effect/temp_visual/heretic_sand/impact(place)
		heretic_sand_sound(place, "unseal", 60)
	return ..()

/// Пропавшие не через clear_noon() часы - разбитые: еретику об этом скажут.
/obj/structure/heretic_sand_noon/Destroy()
	var/datum/eldritch_knowledge/base_sand/sand = sand_ref?.resolve()
	sand_ref = null
	sand?.noon_clock_broken(src)
	return ..()

/obj/item/melee/sickly_blade/sand
	name = "last-hour blade"
	desc = "Вырванный сектор циферблата с заточенными часовыми зубцами. Стрелка мечется внутри разорванного обода, отсекая ещё не наступившие секунды."
	icon = 'modular_bluemoon/icons/obj/heretic_sand.dmi'
	icon_state = "sand_blade"
	item_state = "sand_blade"
	route = PATH_SAND
	mark_type = /datum/status_effect/eldritch/sand

/obj/item/heretic_path_relic/sand_relic
	name = "unturned hourglass"
	desc = "Песочные часы, которые удобно держать в ладони. Если в 25 клетках на вашем этаже стоит ваша засечка, применение начинает Откат: 3 секунды вокруг вас кружит песок, вы замедлены, затем переноситесь к ближайшей засечке вне зон, закрытых для телепортации. Нет засечки на этаже - годится засечка этажом выше или ниже, но Откат длится 5 секунд. Смерть, наручники и щит разума срывают перенос, крепкая чужая хватка не даёт его начать; перезарядка 30 секунд. Без засечек рядом первое применение оставляет на пять секунд разрушаемую точку возврата, повторное возвращает к ней через открытую линию не длиннее пяти клеток; перезарядка 20 секунд с установки. В зоне, закрытой для телепортации, точка не ставится и не возвращает; часы называют причину отказа. Раны и эффекты сохраняются. Щелчок реликвией по своим боевым часам в пяти клетках за единицу песка однократно продлевает отсчёт на 1,5 секунды."
	icon = 'modular_bluemoon/icons/obj/heretic_sand.dmi'
	icon_state = "sand_relic"
	item_state = "sand_relic"
	lefthand_file = 'modular_bluemoon/icons/obj/heretic_relics_sand_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/obj/heretic_relics_sand_righthand.dmi'

/obj/item/heretic_path_relic/sand_relic/attack_self(mob/living/user)
	return turn_hourglass(user)

/obj/item/heretic_path_relic/sand_relic/afterattack(atom/target, mob/living/user, proximity_flag, click_parameters)
	. = ..()
	if(istype(target, /obj/structure/heretic_sand_hourglass))
		return delay_hourglass(user, target)

/obj/item/heretic_path_relic/sand_relic/proc/delay_hourglass(mob/living/user, obj/structure/heretic_sand_hourglass/hourglass)
	if(!authorized(user) || QDELETED(hourglass))
		return FALSE
	return hourglass.delay_impact(user)

/obj/item/heretic_path_relic/sand_relic/proc/turn_hourglass(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_sand/sand = heretic?.get_knowledge(/datum/eldritch_knowledge/base_sand)
	if(!authorized(user) || !sand?.can_use(user))
		return FALSE
	var/obj/structure/heretic_sand_anchor/target = sand.anchor ? null : sand.nearest_anchor(user)
	if(target)
		return begin_rewind(user, sand, target)
	sand.sand_failure = sand.anchor ? point_return_block_reason(user, sand) : point_block_reason(user, sand)
	if(sand.sand_failure)
		to_chat(user, span_warning(sand.sand_failure))
		return FALSE
	if(sand.anchor)
		var/turf/destination = get_turf(sand.anchor)
		if(!do_teleport(user, destination, channel = TELEPORT_CHANNEL_MAGIC) || get_turf(user) != destination)
			sand.sand_failure = "Песок не донёс вас до точки возврата: перенос что-то остановило."
			to_chat(user, span_warning(sand.sand_failure))
			return FALSE
		if(!sand.can_use(user) || !authorized(user))
			return TRUE
		QDEL_NULL(sand.anchor)
	else
		new /obj/structure/heretic_sand_anchor(get_turf(user), sand)
		COOLDOWN_START(src, relic_cooldown, 20 SECONDS)
	new /obj/effect/temp_visual/heretic_sand/cast(get_turf(user))
	heretic_sand_sound(user, "point", 45)
	return TRUE

/obj/item/heretic_path_relic/sand_relic/proc/point_block_reason(mob/living/user, datum/eldritch_knowledge/base_sand/sand)
	if(!COOLDOWN_FINISHED(src, relic_cooldown))
		return "Песок в часах ещё не осел: до новой точки возврата осталось [DisplayTimeText(COOLDOWN_TIMELEFT(src, relic_cooldown))]."
	var/area/place_area = get_area(user)
	if(place_area.area_flags & NOTELEPORT)
		return "Зона закрыта для телепортации: точка возврата здесь не встаёт."
	if(!sand.tile_open(get_turf(user)))
		return "Точка возврата встаёт только на свободном полу."
	return null

/obj/item/heretic_path_relic/sand_relic/proc/point_return_block_reason(mob/living/user, datum/eldritch_knowledge/base_sand/sand)
	if(world.time >= sand.anchor.expires_at)
		return "Точка возврата уже рассыпалась."
	if(user.buckled || user.anchored || HAS_TRAIT(user, TRAIT_NO_TELEPORT))
		return "Что-то держит вас на месте: песок не вернёт вас к точке."
	var/turf/destination = get_turf(sand.anchor)
	var/area/origin_area = get_area(user)
	var/area/destination_area = get_area(destination)
	if((origin_area.area_flags & NOTELEPORT) || (destination_area.area_flags & NOTELEPORT))
		return "Зона закрыта для телепортации: песок не вернёт вас к точке."
	if(!sand.line_clear(user, destination))
		return "До точки возврата нужна открытая линия не длиннее [HERETIC_SAND_RANGE] клеток."
	if(destination.is_blocked_turf())
		return "Клетку точки возврата заняли: вернуться некуда."
	return null

/obj/item/heretic_path_relic/sand_relic/proc/begin_rewind(mob/living/user, datum/eldritch_knowledge/base_sand/sand, obj/structure/heretic_sand_anchor/target)
	sand.sand_failure = COOLDOWN_FINISHED(src, relic_cooldown) ? sand.rewind_block_reason(user) : "Песок в часах ещё не осел: до Отката осталось [DisplayTimeText(COOLDOWN_TIMELEFT(src, relic_cooldown))]."
	target = target || sand.nearest_anchor(user)
	if(!sand.sand_failure && !target)
		sand.sand_failure = "Рядом нет свободной засечки: на своём этаже или этажом выше и ниже - в [HERETIC_SAND_REWIND_RANGE] клетках."
	if(!sand.sand_failure && !user.apply_status_effect(/datum/status_effect/heretic_sand_rewind, sand, target))
		sand.sand_failure = "Откат уже идёт."
	if(sand.sand_failure)
		to_chat(user, span_warning(sand.sand_failure))
		return FALSE
	COOLDOWN_START(src, relic_cooldown, HERETIC_SAND_REWIND_COOLDOWN)
	log_game("[key_name(user)] начинает Откат Песка в [AREACOORD(user)] к засечке в [AREACOORD(target)].")
	return TRUE

/datum/status_effect/heretic_sand_rewind
	id = "heretic_sand_rewind"
	duration = HERETIC_SAND_REWIND_TIME + HERETIC_SAND_REWIND_GRACE
	tick_interval = -1
	status_type = STATUS_EFFECT_UNIQUE
	on_remove_on_mob_delete = TRUE
	alert_type = /atom/movable/screen/alert/status_effect/heretic_sand_rewind
	var/datum/weakref/sand_ref
	var/datum/weakref/target_ref
	var/rewind_time = HERETIC_SAND_REWIND_TIME
	var/obj/effect/abstract/heretic_vfx_attached/vortex
	var/rewind_timer

/datum/status_effect/heretic_sand_rewind/on_creation(mob/living/new_owner, datum/eldritch_knowledge/base_sand/sand, atom/target)
	sand_ref = WEAKREF(sand)
	target_ref = WEAKREF(target)
	var/turf/start = get_turf(new_owner)
	var/turf/finish = get_turf(target)
	rewind_time = travel_time(start, finish)
	duration = rewind_time + HERETIC_SAND_REWIND_GRACE
	return ..()

/// С другого этажа песку дольше нести: Откат на соседний этаж длиннее.
/datum/status_effect/heretic_sand_rewind/proc/travel_time(turf/start, turf/finish)
	return (start && finish && start.z != finish.z) ? HERETIC_SAND_REWIND_FLOOR_TIME : HERETIC_SAND_REWIND_TIME

/// Куда унесёт песок: выбранная засечка, а если её разбили - ближайшая другая.
/datum/status_effect/heretic_sand_rewind/proc/destination(datum/eldritch_knowledge/base_sand/sand)
	var/obj/structure/heretic_sand_anchor/target = target_ref?.resolve()
	if((target in sand.anchors) && sand.anchor_usable(target))
		return get_turf(target)
	return get_turf(sand.nearest_anchor(owner, other_floors = rewind_time >= HERETIC_SAND_REWIND_FLOOR_TIME))

/datum/status_effect/heretic_sand_rewind/proc/lost_reason()
	return "рядом не осталось свободной засечки."

/datum/status_effect/heretic_sand_rewind/proc/start_text()
	return "Песок подхватывает вас. Через [DisplayTimeText(rewind_time)] вы окажетесь у засечки[rewind_time >= HERETIC_SAND_REWIND_FLOOR_TIME ? " на другом этаже" : ""]."

/datum/status_effect/heretic_sand_rewind/proc/arrival_log(turf/origin, turf/destination)
	log_game("[key_name(owner)] откатывается к засечке Песка из [AREACOORD(origin)] в [AREACOORD(destination)].")

/datum/status_effect/heretic_sand_rewind/on_apply()
	. = ..()
	if(!.)
		return
	owner.add_movespeed_modifier(/datum/movespeed_modifier/heretic_sand_rewind)
	vortex = heretic_vfx_attach(owner, 'modular_bluemoon/icons/obj/heretic_sand_effects.dmi', "sand_rewind", HERETIC_SAND_REWIND_ALPHA)
	if(vortex)
		vortex.pixel_x = HERETIC_SAND_EFFECT_SHIFT
		vortex.pixel_y = HERETIC_SAND_EFFECT_SHIFT
	RegisterSignal(owner, COMSIG_LIVING_DEATH, PROC_REF(on_owner_death))
	rewind_timer = addtimer(CALLBACK(src, PROC_REF(complete)), rewind_time, TIMER_STOPPABLE)
	owner.visible_message(span_danger("Вокруг [owner] песок поднимается с пола и течёт вверх: время вокруг течёт вспять!"), span_notice(start_text()))
	heretic_sand_sound(owner, "rewind", 50)

/datum/status_effect/heretic_sand_rewind/proc/on_owner_death(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/datum/status_effect/heretic_sand_rewind/proc/failure_reason(datum/eldritch_knowledge/base_sand/sand)
	if(QDELETED(sand) || sand.sand_body != owner || owner.stat == DEAD)
		return "путь больше не держит это тело."
	var/containment = heretic_containment_reason(owner)
	if(containment)
		return containment
	var/area/origin_area = get_area(owner)
	if(!isturf(owner.loc) || owner.buckled || owner.anchored || HAS_TRAIT(owner, TRAIT_NO_TELEPORT) || (origin_area.area_flags & NOTELEPORT))
		return "что-то держит вас на месте."
	if(!destination(sand))
		return lost_reason()
	return null

/datum/status_effect/heretic_sand_rewind/proc/complete()
	rewind_timer = null
	var/datum/eldritch_knowledge/base_sand/sand = sand_ref?.resolve()
	var/reason = failure_reason(sand)
	if(reason)
		to_chat(owner, span_warning("Откат сорвался: [reason]"))
		qdel(src)
		return FALSE
	var/turf/origin = get_turf(owner)
	var/turf/destination = destination(sand)
	if(!do_teleport(owner, destination, channel = TELEPORT_CHANNEL_MAGIC) || get_turf(owner) != destination)
		to_chat(owner, span_warning("Откат сорвался: песок не нашёл пути."))
		qdel(src)
		return FALSE
	new /obj/effect/temp_visual/heretic_sand/cast(origin)
	new /obj/effect/temp_visual/heretic_sand/cast(destination)
	heretic_sand_sound(destination, "arrive", 55)
	arrival_log(origin, destination)
	SEND_SIGNAL(sand, COMSIG_HERETIC_SAND_EVENT, "rewind", destination)
	qdel(src)
	return TRUE

/datum/status_effect/heretic_sand_rewind/on_remove()
	deltimer(rewind_timer)
	rewind_timer = null
	UnregisterSignal(owner, COMSIG_LIVING_DEATH)
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/heretic_sand_rewind)
	if(QDELETED(owner))
		qdel(vortex)
	else
		vortex?.fade_out()
	vortex = null
	sand_ref = null
	return ..()

/// Последний полдень: тот же Откат, но к Полуденным часам на любом этаже.
/datum/status_effect/heretic_sand_rewind/noon
	alert_type = /atom/movable/screen/alert/status_effect/heretic_sand_rewind/noon

/datum/status_effect/heretic_sand_rewind/noon/travel_time(turf/start, turf/finish)
	return HERETIC_SAND_REWIND_TIME

/datum/status_effect/heretic_sand_rewind/noon/destination(datum/eldritch_knowledge/base_sand/sand)
	var/obj/structure/heretic_sand_noon/clock = target_ref?.resolve()
	if(!sand.ascension_active || !(clock in sand.noon_clocks))
		return null
	return clock.landing()

/datum/status_effect/heretic_sand_rewind/noon/lost_reason()
	return "Полуденные часы разбиты или обступлены."

/datum/status_effect/heretic_sand_rewind/noon/start_text()
	var/obj/structure/heretic_sand_noon/clock = target_ref?.resolve()
	return "Полдень зовёт вас: через [DisplayTimeText(rewind_time)] вы окажетесь у часов в [get_area_name(clock, TRUE)]."

/datum/status_effect/heretic_sand_rewind/noon/arrival_log(turf/origin, turf/destination)
	log_game("[key_name(owner)] уходит Последним полднем из [AREACOORD(origin)] к часам в [AREACOORD(destination)].")

/datum/movespeed_modifier/heretic_sand_rewind
	multiplicative_slowdown = HERETIC_SAND_REWIND_SLOWDOWN

/atom/movable/screen/alert/status_effect/heretic_sand_rewind
	name = "Откат"
	desc = "Песок уносит вас к засечке: на своём этаже за 3 секунды, на соседний за 5. Смерть, наручники и щит разума сорвут перенос, разбитую засечку заменит ближайшая другая."
	icon = 'modular_bluemoon/icons/obj/heretic_sand.dmi'
	icon_state = "sand_rewind_alert"

/atom/movable/screen/alert/status_effect/heretic_sand_rewind/noon
	name = "Последний полдень"
	desc = "Песок уносит вас к Полуденным часам. Смерть, наручники, щит разума и разбитые часы сорвут перенос."

/datum/status_effect/heretic_sand_drought
	id = "heretic_sand_drought"
	duration = HERETIC_SAND_DROUGHT_DURATION
	tick_interval = -1
	status_type = STATUS_EFFECT_REFRESH
	alert_type = /atom/movable/screen/alert/status_effect/heretic_sand_drought
	examine_text = span_warning("SUBJECTPRONOUN осыпается сухим песком: суставы пересохли, удар песочных часов собьёт с ног, а песок Стазиса возьмёт и стоящего.")
	/// Песок, осыпающийся с пересохшего тела.
	var/obj/effect/abstract/heretic_particle_holder/dust
	COOLDOWN_DECLARE(trip_cooldown)

/datum/status_effect/heretic_sand_drought/on_apply()
	. = ..()
	if(!.)
		return
	owner.add_actionspeed_modifier(/datum/actionspeed_modifier/heretic_sand_drought)
	owner.add_movespeed_modifier(/datum/movespeed_modifier/heretic_sand_drought)
	dust = heretic_vfx_attach_particles(owner, /particles/heretic_ascension/sand/drought, FALSE)

/datum/status_effect/heretic_sand_drought/on_remove()
	owner.remove_actionspeed_modifier(/datum/actionspeed_modifier/heretic_sand_drought)
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/heretic_sand_drought)
	heretic_vfx_release_particles(owner, dust)
	dust = null
	return ..()

/datum/actionspeed_modifier/heretic_sand_drought
	multiplicative_slowdown = HERETIC_SAND_DROUGHT_SLOWDOWN

/datum/movespeed_modifier/heretic_sand_drought
	multiplicative_slowdown = HERETIC_SAND_DROUGHT_STEP

/atom/movable/screen/alert/status_effect/heretic_sand_drought
	name = "Засуха"
	desc = "Руки и суставы пересохли: шаг чуть медленнее, а наручники, обыск, лечение и снятие оков идут в полтора раза дольше. Удар песочных часов сейчас собьёт вас с ног на полторы секунды, а Стазис еретика возьмёт и стоящего: когда вокруг смыкается песок, шагните прочь."
	icon = 'modular_bluemoon/icons/obj/heretic_sand.dmi'
	icon_state = "sand_drought"

/datum/status_effect/heretic_sand_stasis
	var/held_since = 0
	id = "heretic_sand_stasis"
	duration = HERETIC_SAND_STASIS_DURATION
	tick_interval = HERETIC_SAND_STASIS_CHECK
	status_type = STATUS_EFFECT_UNIQUE
	on_remove_on_mob_delete = TRUE
	alert_type = /atom/movable/screen/alert/status_effect/heretic_sand_stasis
	examine_text = span_warning("SUBJECTPRONOUN - в песчаном стазисе: время вокруг стоит. Песок развеет нулевой жезл или святая вода в крови, а ещё застывшего можно растолкать за 2 секунды.")
	var/datum/weakref/sand_ref
	var/datum/status_effect/incapacitating/paralyzed/heretic_ritual/restraint
	var/granted_godmode = FALSE
	var/obj/effect/abstract/heretic_particle_holder/still_grains

/datum/status_effect/heretic_sand_stasis/on_creation(mob/living/new_owner, datum/eldritch_knowledge/base_sand/sand)
	sand_ref = WEAKREF(sand)
	return ..()

/datum/status_effect/heretic_sand_stasis/on_apply()
	. = ..()
	if(!.)
		return
	var/datum/eldritch_knowledge/base_sand/sand = sand_ref?.resolve()
	sand?.stases += src
	held_since = world.time
	owner.apply_status_effect(/datum/status_effect/grouped/stasis, REF(src))
	restraint = new(list(owner, HERETIC_SAND_STASIS_DURATION, TRUE))
	if(!(owner.status_flags & GODMODE))
		owner.status_flags |= GODMODE
		granted_godmode = TRUE
	owner.add_atom_colour(HERETIC_SAND_SLOW_COLOR, TEMPORARY_COLOUR_PRIORITY)
	still_grains = heretic_vfx_attach_particles(owner, /particles/heretic_ascension/sand/still)
	RegisterSignal(owner, COMSIG_PARENT_ATTACKBY, PROC_REF(on_attackby))
	RegisterSignals(owner, list(COMSIG_MOVABLE_Z_CHANGED, COMSIG_LIVING_HERETIC_SACRIFICE_STARTING, COMSIG_LIVING_HERETIC_CAPTURE_SHAKEN), PROC_REF(end_stasis))
	heretic_capture_hold(owner, HERETIC_SAND_CAPTURE)
	heretic_capture_lock_pull(owner, sand?.sand_body, REF(src))
	owner.visible_message(span_warning("[owner] застывает в песке: даже пылинки вокруг повисли в воздухе."), span_userdanger("Песок сомкнулся, и ваше время остановилось!"))

/datum/status_effect/heretic_sand_stasis/tick()
	if(!owner.reagents?.has_reagent(/datum/reagent/water/holywater))
		return
	owner.visible_message(span_warning("Святая вода смывает песок с [owner], и время снова идёт."))
	qdel(src)

/datum/status_effect/heretic_sand_stasis/proc/on_attackby(mob/living/source, obj/item/item, mob/living/user, params)
	SIGNAL_HANDLER
	if(!istype(item, /obj/item/nullrod))
		return NONE
	user.visible_message(span_warning("[user] касается [source] нулевым жезлом, и застывший песок осыпается."), span_notice("Вы касаетесь [source] нулевым жезлом, и песок осыпается."))
	log_game("[key_name(user)] развеивает песочный стазис [key_name(source)] нулевым жезлом в [AREACOORD(source)].")
	qdel(src)
	return COMPONENT_NO_AFTERATTACK

/datum/status_effect/heretic_sand_stasis/proc/end_stasis(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/datum/status_effect/heretic_sand_stasis/on_remove()
	UnregisterSignal(owner, list(COMSIG_PARENT_ATTACKBY, COMSIG_MOVABLE_Z_CHANGED, COMSIG_LIVING_HERETIC_SACRIFICE_STARTING, COMSIG_LIVING_HERETIC_CAPTURE_SHAKEN))
	heretic_capture_unhold(owner, HERETIC_SAND_CAPTURE)
	heretic_capture_unlock_pull(owner, REF(src))
	owner.remove_status_effect(/datum/status_effect/grouped/stasis, REF(src))
	// Чужой Paralyze мог продлить этот экземпляр: тогда он остаётся.
	if(!QDELETED(restraint) && restraint.duration <= duration)
		qdel(restraint)
	restraint = null
	if(granted_godmode)
		owner.status_flags &= ~GODMODE
	owner.remove_atom_colour(TEMPORARY_COLOUR_PRIORITY, HERETIC_SAND_SLOW_COLOR)
	shed_grains()
	var/datum/eldritch_knowledge/base_sand/sand = sand_ref?.resolve()
	sand?.stases -= src
	sand_ref = null
	heretic_capture_release(owner, HERETIC_SAND_CAPTURE, held_for = heretic_capture_held_for(held_since))
	return ..()

/// Время пошло: висевшие песчинки разом осыпаются на пол.
/datum/status_effect/heretic_sand_stasis/proc/shed_grains()
	if(!still_grains)
		return
	owner.vis_contents -= still_grains
	QDEL_NULL(still_grains)
	if(QDELETED(owner) || !isturf(owner.loc))
		return
	heretic_vfx_burst(owner, /particles/heretic_ascension/sand/fall, world.tick_lag)
	heretic_sand_sound(owner, "unseal", 40)

/atom/movable/screen/alert/status_effect/heretic_sand_stasis
	name = "Стазис"
	desc = "Ваше время остановлено: вы не действуете, но и урона не получаете. Песок развеется, если вас ударят нулевым жезлом, в крови окажется святая вода или кто-то растолкает вас за 2 секунды."
	icon = 'modular_bluemoon/icons/obj/heretic_alerts.dmi'
	icon_state = "sand_stopped"

/proc/heretic_ritual_speed_multiplier(mob/living/user, atom/place)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_sand/sand = heretic?.get_knowledge(/datum/eldritch_knowledge/base_sand)
	var/turf/center = heretic_pocket_anchor(get_turf(place))
	if(!sand || !center || !heretic.get_knowledge(/datum/eldritch_knowledge/sand_haste))
		return 1
	for(var/obj/structure/heretic_sand_anchor/craft_anchor as anything in sand.anchors)
		if(craft_anchor.z == center.z && get_dist(craft_anchor, center) <= HERETIC_SAND_HASTE_RANGE)
			return HERETIC_SAND_HASTE_MULTIPLIER
	return 1

/datum/status_effect/eldritch/sand
	id = "sand_mark"
	mark_name = "Метка Песка"
	mark_alert_state = "sigil_sand"
	effect_sprite_icon = 'modular_bluemoon/icons/obj/heretic_sand.dmi'
	effect_sprite = "sand_mark"
	effect_sprite_layer = ABOVE_MOB_LAYER
	detonation_sound = 'modular_bluemoon/sound/heretic/sand_mark.ogg'
	detonation_visual = /obj/effect/temp_visual/heretic_sand/impact
	var/datum/weakref/sand_ref
	var/datum/weakref/knowledge_ref

/datum/status_effect/eldritch/sand/on_creation(mob/living/new_owner, datum/eldritch_knowledge/base_sand/sand)
	if(sand)
		sand_ref = WEAKREF(sand)
	return ..()

/datum/status_effect/eldritch/sand/on_apply()
	if(!..())
		return FALSE
	var/datum/eldritch_knowledge/base_sand/sand = sand_ref?.resolve()
	var/datum/antagonist/heretic/heretic = IS_HERETIC(sand?.sand_body)
	var/datum/eldritch_knowledge/required = heretic?.get_knowledge(/datum/eldritch_knowledge/sand_mark)
	if(!sand || QDELETED(required))
		return FALSE
	knowledge_ref = WEAKREF(required)
	RegisterSignal(required, COMSIG_PARENT_QDELETING, PROC_REF(source_deleted))
	sand.marks += src
	return TRUE

/datum/status_effect/eldritch/sand/proc/source_deleted(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/datum/status_effect/eldritch/sand/on_remove()
	var/datum/eldritch_knowledge/base_sand/sand = sand_ref?.resolve()
	sand?.marks.Remove(src)
	var/datum/eldritch_knowledge/required = knowledge_ref?.resolve()
	if(required)
		UnregisterSignal(required, COMSIG_PARENT_QDELETING)
	return ..()

/datum/status_effect/eldritch/sand/on_effect()
	var/datum/eldritch_knowledge/base_sand/sand = sand_ref?.resolve()
	var/datum/antagonist/heretic/heretic = IS_HERETIC(sand?.sand_body)
	if(sand?.can_use(sand.sand_body) && isturf(owner.loc) && sand.line_clear(sand.sand_body, owner) && heretic_can_affect(sand.sand_body, owner, chargecost = 0))
		owner.adjustStaminaLoss(20)
		var/obj/structure/heretic_sand_hourglass/hourglass = sand.create_hourglass(get_turf(owner), heretic.get_knowledge(/datum/eldritch_knowledge/sand_mark))
		hourglass?.record_target(owner)
	return ..()

/obj/effect/temp_visual/heretic_sand
	icon = 'modular_bluemoon/icons/obj/heretic_sand_effects.dmi'
	icon_state = "sand_cast"
	duration = 0.8 SECONDS
	randomdir = FALSE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	layer = ABOVE_MOB_LAYER
	pixel_x = -16
	pixel_y = -16

/obj/effect/temp_visual/heretic_sand/grasp
	icon = 'modular_bluemoon/icons/obj/heretic_sand.dmi'
	icon_state = "sand_grasp"
	pixel_x = 0
	pixel_y = 0

/obj/effect/temp_visual/heretic_sand/cast

/obj/effect/temp_visual/heretic_sand/impact
	icon_state = "sand_impact"

/obj/effect/temp_visual/heretic_sand/ascend
	icon_state = "sand_ascend"
	duration = 2.4 SECONDS

/obj/effect/temp_visual/heretic_sand/stasis
	icon_state = "sand_seal"
	duration = HERETIC_SAND_STASIS_TELEGRAPH

/obj/effect/temp_visual/heretic_sand/bind
	icon_state = "sand_bind"

/obj/effect/temp_visual/heretic_sand/trip
	icon = 'modular_bluemoon/icons/obj/heretic_sand.dmi'
	icon_state = "sand_trip"
	duration = 0.8 SECONDS
	pixel_x = 0
	pixel_y = 0

/// Зыбун: песок на клетке удара часов проворачивается воронкой, ступивший в неё увязает.
/obj/effect/heretic_sand_mire
	name = "shifting sand"
	desc = "Песок на полу медленно проворачивается воронкой. Кто ступит сюда, увязнет на полторы секунды; скоро воронка высохнет."
	icon = 'modular_bluemoon/icons/obj/heretic_sand.dmi'
	icon_state = "sand_mire"
	anchored = TRUE
	layer = ABOVE_NORMAL_TURF_LAYER
	var/datum/weakref/sand_ref
	var/list/caught = list()
	var/expiry_timer
	var/fade_timer

/obj/effect/heretic_sand_mire/Initialize(mapload, datum/eldritch_knowledge/base_sand/sand)
	. = ..()
	if(QDELETED(sand))
		return INITIALIZE_HINT_QDEL
	for(var/obj/effect/heretic_sand_mire/older in loc)
		if(older != src)
			qdel(older)
	sand_ref = WEAKREF(sand)
	sand.mires += src
	var/static/list/loc_connections = list(
		COMSIG_ATOM_ENTERED = PROC_REF(on_entered),
	)
	AddElement(/datum/element/connect_loc, loc_connections)
	var/lifetime = sand.mire_time()
	expiry_timer = QDEL_IN_STOPPABLE(src, lifetime)
	fade_timer = addtimer(CALLBACK(src, PROC_REF(dry_out)), lifetime - HERETIC_SAND_MIRE_FADE, TIMER_STOPPABLE)
	alpha = 0
	animate(src, alpha = 255, time = HERETIC_SAND_MIRE_APPEAR, easing = SINE_EASING | EASE_OUT)

/obj/effect/heretic_sand_mire/proc/dry_out()
	fade_timer = null
	animate(src, alpha = 0, time = HERETIC_SAND_MIRE_FADE, easing = SINE_EASING | EASE_IN)

/obj/effect/heretic_sand_mire/proc/on_entered(datum/source, atom/movable/arrived)
	SIGNAL_HANDLER
	if(isliving(arrived))
		catch_victim(arrived)

/obj/effect/heretic_sand_mire/proc/catch_victim(mob/living/victim)
	var/datum/eldritch_knowledge/base_sand/sand = sand_ref?.resolve()
	var/victim_key = REF(victim)
	if(!sand?.can_use(sand.sand_body) || caught[victim_key] || victim.buckled || victim.throwing || victim.is_flying() || (victim.movement_type & FLOATING))
		return FALSE
	if(!heretic_can_affect(sand.sand_body, victim, chargecost = 0))
		return FALSE
	caught[victim_key] = TRUE
	if(!victim.Immobilize(HERETIC_SAND_MIRE_HOLD))
		return FALSE
	victim.apply_status_effect(/datum/status_effect/heretic_sand_mired, sand)
	return TRUE

/obj/effect/heretic_sand_mire/Destroy()
	deltimer(expiry_timer)
	deltimer(fade_timer)
	var/datum/eldritch_knowledge/base_sand/sand = sand_ref?.resolve()
	sand?.mires -= src
	sand_ref = null
	return ..()

/datum/status_effect/heretic_sand_mired
	id = "heretic_sand_mired"
	duration = HERETIC_SAND_MIRE_HOLD
	tick_interval = -1
	status_type = STATUS_EFFECT_REFRESH
	alert_type = /atom/movable/screen/alert/status_effect/heretic_sand_mired
	var/obj/effect/abstract/heretic_vfx_attached/grip
	/// Чей песок держит: Стазис берёт увязшего только в своём Зыбуне.
	var/datum/weakref/sand_ref

/datum/status_effect/heretic_sand_mired/on_creation(mob/living/new_owner, datum/eldritch_knowledge/base_sand/sand)
	sand_ref = WEAKREF(sand)
	return ..()

/datum/status_effect/heretic_sand_mired/on_apply()
	. = ..()
	if(!.)
		return
	grip = heretic_vfx_attach(owner, 'modular_bluemoon/icons/obj/heretic_sand.dmi', "sand_mire_grip", fade_in = 0, glow = FALSE, upright = FALSE)
	if(grip)
		grip.vis_flags |= VIS_INHERIT_DIR
	heretic_sand_sound(owner, "mire", 50, TRUE)
	owner.visible_message(span_warning("[owner] проваливается в зыбучий песок по щиколотку!"), span_userdanger("Песок хватает вас за ноги - вырывайтесь!"))

/datum/status_effect/heretic_sand_mired/on_remove()
	if(QDELETED(owner))
		qdel(grip)
	else
		grip?.fade_out()
		to_chat(owner, span_notice("Вы вырываете ноги из песка."))
	grip = null
	return ..()

/atom/movable/screen/alert/status_effect/heretic_sand_mired
	name = "Зыбун"
	desc = "Вы увязли в зыбучем песке еретика и вырвете ноги через полторы секунды. Стрелять и драться можно, сойти с места - нет, и песок Стазиса возьмёт вас наверняка. Каждая воронка держит одного человека один раз."
	icon = 'modular_bluemoon/icons/obj/heretic_sand.dmi'
	icon_state = "sand_mired"

/datum/heretic_deed/sand
	next_step = "В намерении «Помощь» коснитесь Хваткой Мансуса свободного пола в ещё не зачтённом отделе: там встанет засечка."
	name = "Засечки"
	desc = "Ставьте Хваткой Мансуса в намерении «Помощь» засечки - песочные часы на свободном полу станции - в разных отделах. Каждый отдел засчитывается один раз."
	craft_wait = "засечка встаёт, но в дело не идёт"
	hint = "Держатся три засечки, новая вытесняет самую старую. Песок в них течёт вверх, и экипаж это заметит; засечка ломается обычными ударами (30 прочности), нулевой жезл снимает её сразу. У засечки реликвия принимает вас при Откате, а Течение часа ускоряет обряды."
	trace_name = "sand of the spent hour"
	trace_desc = "Мелкий золотой песок лежит кольцом, будто высыпался из перевёрнутых часов."
	trace_state = "trace_sand"

/datum/eldritch_knowledge/base_sand/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	grasp_failure_reason = null
	if(!proximity_flag || !isturf(target) || user.a_intent != INTENT_HELP)
		return FALSE
	return place_anchor(user, target)

/datum/eldritch_knowledge/sand_grasp
	name = "Сухая ладонь"
	summary = "Хватка насылает на врага Засуху на 8 секунд и даёт 2 песка."
	details = list(
		"Цикл захвата в два шага: Засуха от Хватки или Осыпи вплотную, затем Стазис - сбивать цель не нужно.",
		"Под Засухой шаг чуть медленнее, а наручники, обыск, лечение и снятие оков идут в полтора раза дольше.",
		"Удар ваших часов сбивает цель под Засухой с ног на 1,5 секунды, не чаще раза в 4 секунды.",
		"Сбитая часами или увязшая в Зыбуне цель не успеет шагнуть из смыкающегося песка Стазиса.",
		"С цели под Засухой сыплется песок - видно, кого часы собьют и кого брать Стазисом.",
		"Песок от Хватки - раз в 6 секунд; антимагия и союзники не дают ни Засухи, ни песка.",
	)
	role = HERETIC_ROLE_GRASP
	gain_text = "В ладони остался песок. Собеседник забыл, какое слово собирался сказать."
	cost = 1
	route = PATH_SAND

/datum/eldritch_knowledge/sand_grasp/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_sand/sand = heretic?.get_knowledge(/datum/eldritch_knowledge/base_sand)
	if(!proximity_flag || !sand?.can_use(user) || !isturf(target?.loc) || !heretic_can_affect(user, target, chargecost = 0))
		return FALSE
	sand.dry_out(target)
	if(COOLDOWN_FINISHED(sand, grasp_harvest))
		sand.gain_combat_resource(2)
		COOLDOWN_START(sand, grasp_harvest, HERETIC_SAND_HARVEST)
	return TRUE

/datum/eldritch_knowledge/spell/sand_stasis
	name = "Стазис"
	summary = "За 2 песка останавливает время цели под Засухой или на вашем Зыбуне на 10 секунд."
	details = list(
		"Цель в 3 клетках по открытой линии, под Засухой или на вашем Зыбуне; сбивать её не нужно.",
		"Секунду песок смыкается: стоящая цель может шагнуть прочь, и Стазис рассыпается; сбитая или увязшая - нет.",
		"10 секунд цель не действует, не получает урона и не истекает кровью; тянуть её может только еретик.",
		"Застывшая цель готова к обряду; сердце уводит её в изнанку, где первые 3 секунды переход держит её на месте.",
		"Стазис спадает от нулевого жезла, святой воды в крови, вашей смерти или если растолкать за 2 секунды; антимагия спасает.",
		"Потом цель до минуты невосприимчива к Стазису, к любому захвату - 15 секунд. Перезарядка 40 секунд.",
	)
	role = HERETIC_ROLE_CAPTURE
	gain_text = "Песчинка повисла в воздухе. Вокруг неё замер весь мир."
	cost = 2
	route = PATH_SAND
	spell_to_add = /obj/effect/proc_holder/spell/pointed/heretic_sand/stasis

/datum/eldritch_knowledge/spell/sand_stasis/on_body_lose(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_sand/sand = heretic?.get_knowledge(/datum/eldritch_knowledge/base_sand)
	if(sand)
		QDEL_LIST(sand.stases)
	return ..()

/datum/eldritch_knowledge/sand_mark
	name = "Метка Песка"
	summary = "Хватка ставит метку на 15 секунд, удар клинком её взрывает и ставит часы-возврат."
	details = list(
		"Взрыв: 20 выносливости и единица песка, часы запоминают клетку цели.",
		"Через 1,5 секунды часы отматывают цель на эту клетку, хоть из-за угла, и взрываются.",
		"Пока цель в 9 клетках на том же уровне, к ней тянется песчаная нить; втянулась - возврата не будет.",
		"Спастись можно, разбив часы, уйдя дальше 9 клеток или на другой этаж; защищают антимагия и запрет телепортации.",
	)
	role = HERETIC_ROLE_MARK
	gain_text = "Я написал его имя на стекле. Песок начал падать быстрее."
	cost = 2
	route = PATH_SAND

/datum/eldritch_knowledge/sand_mark/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_sand/sand = heretic?.get_knowledge(/datum/eldritch_knowledge/base_sand)
	if(!proximity_flag || !sand?.can_use(user) || !isturf(target?.loc) || !heretic_can_affect(user, target, chargecost = 0))
		return FALSE
	var/mob/living/victim = target
	victim.apply_status_effect(/datum/status_effect/eldritch/sand, sand)
	return TRUE

/datum/eldritch_knowledge/sand_mark/on_body_lose(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_sand/sand = heretic?.get_knowledge(/datum/eldritch_knowledge/base_sand)
	if(sand)
		QDEL_LIST(sand.marks)
		sand.clear_knowledge(src)

/datum/eldritch_knowledge/sand_relic
	name = "Неперевёрнутые часы"
	summary = "Стекло и лист золота дают карманные часы: Откат к засечке или точка возврата."
	details = list(
		"Откат ведёт к засечке в 25 клетках на вашем этаже: 3 секунды вас кружит песок и замедляет, затем вы у засечки.",
		"Нет засечки на этаже - годится засечка этажом выше или ниже в тех же 25 клетках, но Откат идёт 5 секунд.",
		"Засечки в зонах без телепортации не подходят; смерть, наручники и щит разума срывают Откат.",
		"Крепкая чужая хватка не даёт начать Откат, из волочения можно; начатый Откат вырывает вас из рук.",
		"Перезарядка Отката 30 секунд; раны и эффекты сохраняются. Реликвия одна.",
		"Без засечек рядом часы ставят точку возврата (25 прочности) на 5 секунд, второе применение - к ней из 5 клеток.",
		"Щелчок по своим часам в 5 клетках за единицу песка один раз продлевает их отсчёт на 1,5 секунды, всего до 3 секунд.",
	)
	role = HERETIC_ROLE_RELIC
	gain_text = "Я оставил одно мгновение нетронутым. Оно дождалось меня."
	cost = 1
	route = PATH_SAND
	required_atoms = list(/obj/item/stack/sheet/glass, /obj/item/stack/sheet/mineral/gold)
	result_atoms = list(/obj/item/heretic_path_relic/sand_relic)

/datum/eldritch_knowledge/sand_relic/recipe_snowflake_check(list/atoms, loc, list/selected_atoms, mob/living/user)
	return new_path_relic_available()

/datum/eldritch_knowledge/sand_relic/on_finished_recipe(mob/living/user, list/atoms, loc)
	return make_new_path_relic(user, get_turf(loc), /obj/item/heretic_path_relic/sand_relic)

/datum/eldritch_knowledge/sand_relic/on_body_lose(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_sand/sand = heretic?.get_knowledge(/datum/eldritch_knowledge/base_sand)
	if(sand)
		QDEL_NULL(sand.anchor)

/datum/eldritch_knowledge/sand_haste
	name = "Течение часа"
	summary = "У вашей засечки ритуалы, черчение руны и обряд сердцем идут вдвое быстрее."
	details = list(
		"Засечка должна стоять не дальше 5 клеток от места обряда.",
		"В изнанке место обряда - её вход: вход в 5 клетках от засечки ускоряет обряд внутри.",
		"Обряд вознесения не ускоряется.",
	)
	role = HERETIC_ROLE_PASSIVE
	gain_text = "Я поставил часы на пол, и песок в них побежал для меня."
	cost = 1
	route = PATH_SAND

/datum/eldritch_knowledge/spell/sand_step
	name = "Пересыпание"
	summary = "За единицу песка переходит на свободную клетку в 4 клетках, оставляя на старом месте часы."
	details = list(
		"Нужна открытая линия: преграды и запрет телепортации не пускают.",
		"Часы на прежнем месте через 1,5 секунды бьют свою клетку, как часы Осыпи.",
		"Перезарядка 12 секунд.",
	)
	role = HERETIC_ROLE_ESCAPE
	gain_text = "Между двумя шагами я успел рассыпаться и собраться заново."
	cost = 1
	route = PATH_SAND
	spell_to_add = /obj/effect/proc_holder/spell/pointed/heretic_sand/step

/datum/eldritch_knowledge/spell/sand_step/on_body_lose(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_sand/sand = heretic?.get_knowledge(/datum/eldritch_knowledge/base_sand)
	sand?.clear_knowledge(src)
	return ..()

/datum/eldritch_knowledge/sand_sustain
	name = "Глубокая колба"
	summary = "Запас песка растёт до 5, клинок и заклинания дают песок раз в 5 секунд."
	details = list(
		"Улучшения: запас 6 и 7, песок раз в 4 и 3 секунды.",
		"Зыбун на клетках ударов держится на 1 / 2 / 3 секунды дольше.",
		"После вознесения запас 8.",
	)
	role = HERETIC_ROLE_PASSIVE
	gain_text = "Я увидел дно колбы. Оно отступило в темноту."
	cost = 2
	route = PATH_SAND
	passive_values = list(5, 6, 7)
	passive_desc = "Предел песка — 5 / 6 / 7, получение песка клинком и заклинаниями — раз в 5 / 4 / 3 секунды, Зыбун дольше на 1 / 2 / 3 секунды. После вознесения вместимость — 8."

/datum/eldritch_knowledge/sand_sustain/on_body_gain(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_sand/sand = heretic?.get_knowledge(/datum/eldritch_knowledge/base_sand)
	sand?.update_capacity()

/datum/eldritch_knowledge/sand_sustain/on_body_lose(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_sand/sand = heretic?.get_knowledge(/datum/eldritch_knowledge/base_sand)
	if(!sand || !user || sand.sand_body != user)
		return FALSE
	sand.update_capacity(ignore_sustain = TRUE)
	return TRUE

/datum/eldritch_knowledge/sand_sustain/on_passive_upgrade(mob/living/user)
	on_body_gain(user)

/datum/eldritch_knowledge/spell/sand_burial
	name = "Погребение"
	summary = "За 2 песка бьёт область 3×3 и расставляет 13 часов-ловушек на поле 5×5."
	details = list(
		"Сразу: 28 ушибов, 15 выносливости и Засуха на 8 секунд в области 3×3.",
		"13 часов в шахматном порядке запоминают врага на своей клетке и через 1,5 секунды отматывают его назад к взрыву.",
		"Засуха первого удара значит, что взрыв часов собьёт цель с ног, а клетки часов станут Зыбуном.",
		"Между часами есть проходы; спастись можно, разбив часы или уйдя дальше 9 клеток.",
		"Если часов больше 13, старые вне поля исчезают. Перезарядка 35 секунд.",
	)
	role = HERETIC_ROLE_ATTACK
	gain_text = "Город исчез под песком. Улицы ещё долго помнили, где ходить."
	cost = 2
	sacs_needed = HERETIC_PENULTIMATE_SACRIFICES
	route = PATH_SAND
	spell_to_add = /obj/effect/proc_holder/spell/pointed/heretic_sand/burial

/datum/eldritch_knowledge/spell/sand_burial/on_body_lose(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_sand/sand = heretic?.get_knowledge(/datum/eldritch_knowledge/base_sand)
	sand?.clear_knowledge(src)
	return ..()

/datum/eldritch_knowledge/final_eldritch/sand_final
	name = "Хранитель Последнего Часа"
	summary = "Встают 3 Полуденных часа: экипаж их бьёт, а вы уходите к ним сквозь этажи; чужие пули вязнут."
	details = list(
		"Нужны 3 назначенные души и 3 человеческих трупа на руне станции; станция узнаёт место обряда, он длится 30 секунд.",
		"Общая стойкость вознесения: станы не глушат приёмы пути; запас песка 8, единица каждые 4 секунды.",
		"Встают 3 Полуденных часа: на засечках, если не перекроют проход, остальные в общих отсеках; станции объявят где.",
		"Раз в 60 секунд бьёт полдень: каждые стоящие часы лечат вам 15 урона и дают единицу песка.",
		"Последний полдень: за 3 секунды Откат к ближайшим часам, хоть на другом этаже; перезарядка 45 секунд.",
		"Часы (120 прочности) разбивают оружием, нулевой жезл - за два удара; со смертью они рассыпаются.",
		"Пули и заряды врагов в 4 клетках летят втрое медленнее; лучи, ближний бой, броски и стрельба в шкафу или мехе - нет.",
	)
	role = HERETIC_ROLE_ASCENSION
	gain_text = "Все часы остановились. Я услышал, как станция сделала следующий вдох без их разрешения."
	route = PATH_SAND
	required_atoms = list(/mob/living/carbon/human, /mob/living/carbon/human, /mob/living/carbon/human)
	ascension_spells = list(/obj/effect/proc_holder/spell/self/heretic_sand/final)
	var/datum/weakref/sand_knowledge_ref

/datum/eldritch_knowledge/final_eldritch/sand_final/on_finished_recipe(mob/living/user, list/atoms, loc)
	. = ..()
	if(!.)
		return
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_sand/sand = heretic?.get_knowledge(/datum/eldritch_knowledge/base_sand)
	sand?.raise_noon(user)

/datum/eldritch_knowledge/final_eldritch/sand_final/on_body_gain(mob/living/user)
	. = ..()
	if(!finished || applied_body != user)
		return
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_sand/sand = heretic?.get_knowledge(/datum/eldritch_knowledge/base_sand)
	if(sand)
		sand_knowledge_ref = WEAKREF(sand)
		sand.ascension_active = TRUE
		sand.update_capacity()
	user.AddComponent(/datum/component/heretic_sand_slowtime)

/datum/eldritch_knowledge/final_eldritch/sand_final/on_body_lose(mob/living/user)
	var/mob/living/body = applied_body || user
	qdel(body?.GetComponent(/datum/component/heretic_sand_slowtime))
	var/datum/eldritch_knowledge/base_sand/sand = sand_knowledge_ref?.resolve()
	sand_knowledge_ref = null
	if(sand)
		sand.ascension_active = FALSE
		sand.clear_knowledge(src)
		if(sand.sand_body == user)
			sand.update_capacity(ignore_ascension = TRUE)
	return ..()

/// Замедленное время вознесения: вражеские снаряды рядом с героем летят медленнее, ближний бой не замедляется.
/datum/component/heretic_sand_slowtime
	dupe_mode = COMPONENT_DUPE_UNIQUE
	var/slow_factor = HERETIC_SAND_SLOW_FACTOR
	var/obj/effect/abstract/heretic_vfx_attached/field_ring
	var/obj/effect/abstract/heretic_particle_holder/field_grains
	var/static/list/turf_connections = list(
		COMSIG_ATOM_ENTERED = PROC_REF(on_entered),
	)

/datum/component/heretic_sand_slowtime/Initialize()
	if(!isliving(parent))
		return COMPONENT_INCOMPATIBLE
	show_field()

/datum/component/heretic_sand_slowtime/Destroy()
	field_ring?.fade_out()
	field_ring = null
	heretic_vfx_release_particles(parent, field_grains)
	field_grains = null
	return ..()

/// Граница поля видна: песчаный вал в родном размере течёт по кругу, по нему кружат и осыпаются песчинки.
/datum/component/heretic_sand_slowtime/proc/show_field()
	var/mob/living/owner = parent
	var/radius = HERETIC_SAND_FIELD_REACH * world.icon_size
	field_ring = heretic_vfx_attach(owner, 'modular_bluemoon/icons/effects/heretic_sand_field.dmi', "sand_field")
	if(field_ring)
		field_ring.layer = BELOW_MOB_LAYER
		field_ring.pixel_x = (world.icon_size - HERETIC_SAND_RING_ICON_SIZE) / 2
		field_ring.pixel_y = field_ring.pixel_x
	field_grains = heretic_vfx_attach_particles(owner, /particles/heretic_ascension/sand/field)
	if(field_grains)
		field_grains.particles.position = generator("circle", radius - HERETIC_SAND_FIELD_SPREAD, radius + HERETIC_SAND_FIELD_SPREAD)
		field_grains.SpinAnimation(HERETIC_SAND_FIELD_SPIN, -1, TRUE, HERETIC_SAND_FIELD_SEGMENTS, parallel = FALSE)

/datum/component/heretic_sand_slowtime/RegisterWithParent()
	AddComponent(/datum/component/connect_range, parent, turf_connections, HERETIC_SAND_SLOW_RADIUS, FALSE)
	RegisterSignal(parent, COMSIG_MOVABLE_MOVED, PROC_REF(on_moved))
	RegisterSignal(parent, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine))

/datum/component/heretic_sand_slowtime/UnregisterFromParent()
	qdel(GetComponent(/datum/component/connect_range))
	UnregisterSignal(parent, list(COMSIG_MOVABLE_MOVED, COMSIG_PARENT_EXAMINE))

/// connect_range не восстанавливает поле, если из шкафа или меха выходят на ту же клетку.
/datum/component/heretic_sand_slowtime/proc/on_moved(atom/movable/source, atom/old_loc)
	SIGNAL_HANDLER
	if(!isturf(source.loc) || isturf(old_loc))
		return
	var/datum/component/connect_range/field = GetComponent(/datum/component/connect_range)
	field?.update_signals(source)

/datum/component/heretic_sand_slowtime/proc/on_entered(turf/source, atom/movable/arrived)
	SIGNAL_HANDLER
	if(!istype(arrived, /obj/item/projectile))
		return
	var/obj/item/projectile/projectile = arrived
	var/mob/living/owner = parent
	if(!projectile.fired || projectile.hitscan || owner.stat == DEAD || HAS_TRAIT(projectile, TRAIT_HERETIC_SAND_SLOWED))
		return
	var/mob/firer = projectile.firer
	if(firer == owner || (ismob(firer) && (IS_HERETIC(firer) || IS_HERETIC_MONSTER(firer))))
		return
	if(get_dist_euclidian(get_turf(owner), source) > HERETIC_SAND_FIELD_REACH)
		return
	ADD_TRAIT(projectile, TRAIT_HERETIC_SAND_SLOWED, REF(src))
	projectile.pixels_per_second /= slow_factor
	projectile.add_atom_colour(HERETIC_SAND_SLOW_COLOR, TEMPORARY_COLOUR_PRIORITY)
	new /obj/effect/abstract/heretic_particle_holder/sand_trail(null, /particles/heretic_ascension/sand/trail, FALSE, projectile)

/datum/component/heretic_sand_slowtime/proc/on_examine(mob/living/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	examine_list += span_warning("Вокруг него вязнет время: пули и заряды в радиусе четырёх клеток летят втрое медленнее. Ближний бой и брошенные предметы это не замедляет.")

/// Песчаный след замедленного снаряда: песчинки срываются назад по курсу и повисают, со смертью снаряда оседают.
/obj/effect/abstract/heretic_particle_holder/sand_trail
	var/datum/weakref/host_ref

/obj/effect/abstract/heretic_particle_holder/sand_trail/Initialize(mapload, particles_type, add_glow = FALSE, obj/item/projectile/host)
	. = ..()
	if(!particles || QDELETED(host))
		return INITIALIZE_HINT_QDEL
	host_ref = WEAKREF(host)
	var/speed = host.pixels_per_second * world.tick_lag / (1 SECONDS) * HERETIC_SAND_TRAIL_DRAG
	particles.velocity = list(-sin(host.Angle) * speed, -cos(host.Angle) * speed, 0)
	host.vis_contents += src
	RegisterSignal(host, COMSIG_PARENT_QDELETING, PROC_REF(host_deleted))

/obj/effect/abstract/heretic_particle_holder/sand_trail/proc/host_deleted(datum/source)
	SIGNAL_HANDLER
	host_ref = null
	UnregisterSignal(source, COMSIG_PARENT_QDELETING)
	heretic_vfx_release_particles(source, src)

/obj/effect/abstract/heretic_particle_holder/sand_trail/Destroy()
	var/atom/movable/host = host_ref?.resolve()
	if(host)
		UnregisterSignal(host, COMSIG_PARENT_QDELETING)
		host.vis_contents -= src
	host_ref = null
	return ..()

/// Песок: песчинки по границе поля замедленного времени, редкие и медленные.
/particles/heretic_ascension/sand/field
	count = 24
	spawning = 0.4
	width = HERETIC_SAND_FIELD_CANVAS
	height = HERETIC_SAND_FIELD_CANVAS
	velocity = generator("circle", 0, 0.15)
	gravity = list(0, -0.04)
	friction = 0
	drift = generator("box", list(-0.03, -0.03, 0), list(0.03, 0.03, 0))
	lifespan = 3 SECONDS
	fadein = 0.8 SECONDS
	fade = 1.2 SECONDS

/// Песок Стазиса: песчинки проступают вокруг застывшего и висят неподвижно, пока время стоит.
/particles/heretic_ascension/sand/still
	count = HERETIC_SAND_STILL_GRAINS
	spawning = 2
	position = generator("box", list(-13, -15, 0), list(13, 17, 0))
	velocity = list(0, 0, 0)
	gravity = list(0, 0, 0)
	friction = 0
	// Эмиттер снимается вместе со Стазисом, срок жизни лишь заведомо длиннее него.
	lifespan = 1 MINUTES
	fadein = 0.6 SECONDS
	fade = 0

/// Песок Стазиса: время пошло, и висевшие песчинки осыпаются разом.
/particles/heretic_ascension/sand/fall
	count = HERETIC_SAND_STILL_GRAINS
	spawning = HERETIC_VFX_MAX_SPAWNING
	position = generator("box", list(-13, -15, 0), list(13, 17, 0))
	velocity = generator("box", list(-0.3, 0, 0), list(0.3, 0.4, 0))
	gravity = list(0, -0.45)
	friction = 0
	lifespan = 0.9 SECONDS
	fadein = 0
	fade = 0.5 SECONDS

/// Засуха: песчинки осыпаются с пересохшего тела к ногам.
/particles/heretic_ascension/sand/drought
	count = HERETIC_SAND_DROUGHT_GRAINS
	spawning = 0.5
	position = generator("box", list(-8, -6, 0), list(8, 10, 0))
	velocity = generator("box", list(-0.15, -0.1, 0), list(0.15, 0.1, 0))
	gravity = list(0, -0.18)
	friction = 0
	lifespan = 1.1 SECONDS
	fadein = 0.1 SECONDS
	fade = 0.4 SECONDS

/// Песок: след замедленного снаряда; скорость задаёт сам снаряд.
/particles/heretic_ascension/sand/trail
	count = 12
	spawning = 1
	position = generator("circle", 0, 2)
	velocity = list(0, 0, 0)
	gravity = list(0, -0.05)
	friction = 0
	lifespan = 0.6 SECONDS
	fade = 0.4 SECONDS

/obj/effect/proc_holder/spell/self/heretic_sand
	clothes_req = FALSE
	invocation_type = "none"
	action_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	action_background_icon_state = "bg_ecult"

/obj/effect/proc_holder/spell/self/heretic_sand/can_cast(mob/user, skipcharge, silent)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_sand/sand = heretic?.get_knowledge(/datum/eldritch_knowledge/base_sand)
	return ..() && heretic_check(user, sand?.can_use(user), silent, "Способность недоступна вашему пути или текущему телу.")

/obj/effect/proc_holder/spell/self/heretic_sand/release
	name = "Осыпь"
	desc = "За единицу песка нанесите соседним врагам 20 ушибов и 10 урона выносливости и нашлите на них Засуху, затем поставьте часы на четырёх соседних клетках. Они взорвутся через 1,5 секунды только на своей клетке: 32 ушиба и 20 урона выносливости; цель под Засухой упадёт, а клетка на 4,5 секунды станет Зыбуном. Если часов слишком много, старые без запомненной цели уступят место."
	summary = "Соседям 20 ушибов, 10 выносливости и Засуха, затем часы на 4 клетках: 32 ушиба через 1,5 секунды."
	charge_max = 12 SECONDS
	action_icon_state = "sand_release"

/obj/effect/proc_holder/spell/self/heretic_sand/release/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_sand/sand = heretic?.get_knowledge(/datum/eldritch_knowledge/base_sand)
	if(!sand?.release(user))
		heretic_revert_cast(user, sand?.sand_failure)

/obj/effect/proc_holder/spell/pointed/heretic_sand
	clothes_req = FALSE
	invocation_type = "none"
	range = HERETIC_SAND_RANGE
	selection_type = "view"
	aim_assist = FALSE
	action_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	action_background_icon_state = "bg_ecult"
	active_msg = "Укажите место, где истечёт чужое время."
	deactive_msg = "Вы удерживаете песок в ладони."

/obj/effect/proc_holder/spell/pointed/heretic_sand/can_cast(mob/user, skipcharge, silent)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_sand/sand = heretic?.get_knowledge(/datum/eldritch_knowledge/base_sand)
	return ..() && heretic_check(user, sand?.can_use(user), silent, "Способность недоступна вашему пути или текущему телу.")

/obj/effect/proc_holder/spell/pointed/heretic_sand/can_target(atom/target, mob/user, silent)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_sand/sand = heretic?.get_knowledge(/datum/eldritch_knowledge/base_sand)
	return heretic_check(user, target && (isturf(target) || isturf(target.loc)) && sand?.can_use(user) && sand.line_clear(user, target, range), silent, "Выберите видимую цель или клетку: стены и контейнеры перекрывают действие.")

/obj/effect/proc_holder/spell/pointed/heretic_sand/stasis
	name = "Стазис"
	desc = "Остановите время цели в 3 клетках под Засухой или на вашем Зыбуне: 10 секунд она не действует и не получает урона. Песок смыкается секунду: стоящая цель может шагнуть прочь, сбитая часами или увязшая - нет. Стазис развеется от нулевого жезла, святой воды или если растолкать цель за 2 секунды. Стоит 2 песка, перезарядка 40 секунд."
	summary = "10 секунд застывшего времени для цели под Засухой или на Зыбуне; 2 песка."
	charge_max = HERETIC_SAND_STASIS_COOLDOWN
	range = HERETIC_SAND_STASIS_RANGE
	action_icon_state = "sand_stasis"

/obj/effect/proc_holder/spell/pointed/heretic_sand/stasis/can_target(atom/target, mob/user, silent)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_sand/sand = heretic?.get_knowledge(/datum/eldritch_knowledge/base_sand)
	if(!heretic_check(user, sand?.can_use(user), silent, "Способность недоступна вашему пути или текущему телу."))
		return FALSE
	var/reason = sand.stasis_block_reason(user, target)
	return heretic_check(user, !reason, silent, reason, target = target)

/obj/effect/proc_holder/spell/pointed/heretic_sand/stasis/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_sand/sand = heretic?.get_knowledge(/datum/eldritch_knowledge/base_sand)
	if(!length(targets) || !sand?.stasis(user, targets[1]))
		heretic_revert_cast(user, sand?.sand_failure)

/obj/effect/proc_holder/spell/pointed/heretic_sand/step
	name = "Пересыпание"
	desc = "За единицу песка переместитесь на свободную клетку в четырёх клетках по открытой линии. На прежнем месте остаются часы."
	summary = "Переход на клетку в 4 клетках по открытой линии за единицу песка; на месте остаются часы."
	charge_max = 12 SECONDS
	range = HERETIC_SAND_STEP_RANGE
	action_icon_state = "sand_step"

/obj/effect/proc_holder/spell/pointed/heretic_sand/step/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_sand/sand = heretic?.get_knowledge(/datum/eldritch_knowledge/base_sand)
	if(!length(targets) || !sand?.step_through(user, get_turf(targets[1])))
		heretic_revert_cast(user, sand?.sand_failure)

/obj/effect/proc_holder/spell/pointed/heretic_sand/burial
	name = "Погребение"
	desc = "За 2 песка область 3×3 получает 28 ушибов, 15 выносливости и Засуху на 8 секунд. 13 часов на поле 5×5 запоминают врагов на своих клетках и через 1,5 секунды отматывают их назад к взрыву, хоть из-за угла; клетки ударов на время становятся Зыбуном."
	summary = "Область 3×3: 28 ушибов и Засуха, затем 13 часов на поле 5×5 отматывают врагов назад к взрыву."
	charge_max = 35 SECONDS
	action_icon_state = "sand_burial"

/obj/effect/proc_holder/spell/pointed/heretic_sand/burial/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_sand/sand = heretic?.get_knowledge(/datum/eldritch_knowledge/base_sand)
	if(!length(targets) || !sand?.burial(user, get_turf(targets[1])))
		heretic_revert_cast(user, sand?.sand_failure)

/obj/effect/proc_holder/spell/self/heretic_sand/final
	name = "Последний полдень"
	desc = "Откат к Полуденным часам: 3 секунды вас кружит песок, затем вы у ближайших стоящих часов, хоть на другом этаже; часы не дальше 3 клеток от вас на своём этаже не в счёт. Смерть, наручники, щит разума и разбитые часы срывают перенос. Перезарядка 45 секунд."
	summary = "Откат к ближайшим Полуденным часам на любом этаже за 3 секунды."
	charge_max = HERETIC_SAND_NOON_COOLDOWN
	action_icon_state = "sand_final"

/obj/effect/proc_holder/spell/self/heretic_sand/final/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_sand/sand = heretic?.get_knowledge(/datum/eldritch_knowledge/base_sand)
	if(!sand?.noon_return(user))
		heretic_revert_cast(user, sand?.sand_failure)

#undef HERETIC_SAND_RANGE
#undef HERETIC_SAND_DELAY
#undef HERETIC_SAND_LIMIT
#undef HERETIC_SAND_HIT_INTERVAL
#undef HERETIC_SAND_ANCHOR_TIME
#undef HERETIC_SAND_CLOCK_DAMAGE
#undef HERETIC_SAND_HARVEST
#undef HERETIC_SAND_STEP_RANGE
#undef HERETIC_SAND_RELEASE_DAMAGE
#undef HERETIC_SAND_RELEASE_STAMINA
#undef HERETIC_SAND_BURIAL_DAMAGE
#undef HERETIC_SAND_BURIAL_RADIUS
#undef HERETIC_SAND_EXTRA_DELAY
#undef HERETIC_SAND_COUNTDOWN
#undef HERETIC_SAND_COUNTDOWN_VOLUME
#undef HERETIC_SAND_LEVEL_FILTER
#undef HERETIC_SAND_UPPER_TRAVEL
#undef HERETIC_SAND_LOWER_TRAVEL
#undef HERETIC_SAND_TETHER_DROP
#undef HERETIC_SAND_TETHER_SNAP
#undef HERETIC_SAND_TETHER_MAX_GLIDE
#undef HERETIC_SAND_SLOW_COLOR
#undef HERETIC_SAND_INK
#undef HERETIC_SAND_SUN_LIGHT
#undef HERETIC_SAND_RING_ICON_SIZE
#undef HERETIC_SAND_FIELD_SPREAD
#undef HERETIC_SAND_FIELD_SPIN
#undef HERETIC_SAND_FIELD_SEGMENTS
#undef HERETIC_SAND_FIELD_CANVAS
#undef HERETIC_SAND_TRAIL_DRAG
#undef HERETIC_SAND_SUN_TIME
#undef HERETIC_SAND_SUN_RISE
#undef HERETIC_SAND_SUN_START
#undef HERETIC_SAND_SUN_PEAK
#undef HERETIC_SAND_SUN_END
#undef HERETIC_SAND_SUN_HEIGHT
#undef HERETIC_SAND_NOON_WAVE_RADIUS
#undef HERETIC_SAND_NOON_WAVE_TIME
#undef HERETIC_SAND_NOON_FLASH_RANGE
#undef HERETIC_SAND_NOON_FLASH_POWER
#undef HERETIC_SAND_NOON_FLASH_TIME
#undef HERETIC_SAND_NOON_QUAKE
#undef HERETIC_SAND_NOON_QUAKE_TIME
#undef HERETIC_SAND_NOON_QUAKE_RADIUS
#undef HERETIC_SAND_NOON_PULSE_TIME
#undef HERETIC_SAND_NOON_TRAINING_RANGE
#undef HERETIC_SAND_NOON_SPREAD
#undef HERETIC_SAND_NOON_NEAR
#undef HERETIC_SAND_ANCHOR_CRAFT
#undef HERETIC_SAND_ANCHOR_CLUE
#undef HERETIC_SAND_CAPTURE
#undef HERETIC_SAND_DROUGHT_SLOWDOWN
#undef HERETIC_SAND_STASIS_RANGE
#undef HERETIC_SAND_STASIS_COST
#undef HERETIC_SAND_STASIS_TELEGRAPH
#undef HERETIC_SAND_STASIS_COOLDOWN
#undef HERETIC_SAND_STASIS_CHECK
#undef HERETIC_SAND_REWIND_COOLDOWN
#undef HERETIC_SAND_REWIND_GRACE
#undef HERETIC_SAND_REWIND_SLOWDOWN
#undef HERETIC_SAND_REWIND_ALPHA
#undef HERETIC_SAND_EFFECT_SHIFT
#undef HERETIC_SAND_HASTE_MULTIPLIER
#undef HERETIC_SAND_DROUGHT_STEP
#undef HERETIC_SAND_TRIP_COOLDOWN
#undef HERETIC_SAND_MIRE_FADE
#undef HERETIC_SAND_MIRE_APPEAR
#undef HERETIC_SAND_MIRE_PER_LEVEL
#undef HERETIC_SAND_STILL_GRAINS
#undef HERETIC_SAND_SEAL_REACH
#undef HERETIC_SAND_SEAL_SWIRL
#undef HERETIC_SAND_SEAL_ARMS
#undef HERETIC_SAND_SEAL_TRAVEL
#undef HERETIC_SAND_SEAL_EMIT
#undef HERETIC_SAND_IMPACT_VOLUME
#undef HERETIC_SAND_DROUGHT_GRAINS
