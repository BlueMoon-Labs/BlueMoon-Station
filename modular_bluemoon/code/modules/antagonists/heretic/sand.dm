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
#define HERETIC_SAND_FINAL_DAMAGE 40
#define HERETIC_SAND_RECALL_RANGE 3
#define HERETIC_SAND_EXTRA_DELAY (1.5 SECONDS)
#define HERETIC_SAND_SLOW_COLOR "#d6ad70"
#define HERETIC_SAND_INK "#c8a66c"
#define HERETIC_SAND_SUN_LIGHT "#ffd98a"
#define HERETIC_SAND_RING_ICON_SIZE 256
#define HERETIC_SAND_RING_ICON_RADIUS 118
#define HERETIC_SAND_FIELD_SPREAD 6
#define HERETIC_SAND_FIELD_ALPHA 50
#define HERETIC_SAND_FIELD_BREATH 1.04
#define HERETIC_SAND_FIELD_BREATH_TIME (2 SECONDS)
#define HERETIC_SAND_FIELD_SPIN (24 SECONDS)
#define HERETIC_SAND_FIELD_SEGMENTS 12
#define HERETIC_SAND_FIELD_CANVAS 320
#define HERETIC_SAND_TRAIL_DRAG 0.6
#define HERETIC_SAND_SUN_TIME (0.7 SECONDS)
#define HERETIC_SAND_SUN_RISE (0.12 SECONDS)
#define HERETIC_SAND_SUN_START 0.3
#define HERETIC_SAND_SUN_PEAK 1.6
#define HERETIC_SAND_SUN_END 2
#define HERETIC_SAND_SUN_HEIGHT 12
#define HERETIC_SAND_NOON_WAVE_RADIUS 3
#define HERETIC_SAND_NOON_WAVE_TIME (0.8 SECONDS)
#define HERETIC_SAND_NOON_FLASH_RANGE 5
#define HERETIC_SAND_NOON_FLASH_POWER 2
#define HERETIC_SAND_NOON_FLASH_TIME (0.5 SECONDS)
#define HERETIC_SAND_NOON_QUAKE 0.12
#define HERETIC_SAND_NOON_QUAKE_TIME (0.35 SECONDS)
#define HERETIC_SAND_NOON_QUAKE_RADIUS 7
#define HERETIC_SAND_NOON_PULSE_TIME (0.5 SECONDS)
#define HERETIC_SAND_ANCHOR_CRAFT "sand_anchor"
#define HERETIC_SAND_ANCHOR_CLUE "Песок в часах течёт вверх."
#define HERETIC_SAND_CAPTURE "sand"
#define HERETIC_SAND_DROUGHT_SLOWDOWN 0.5
#define HERETIC_SAND_STASIS_RANGE 3
#define HERETIC_SAND_STASIS_COST 2
#define HERETIC_SAND_STASIS_TELEGRAPH (1 SECONDS)
#define HERETIC_SAND_STASIS_COOLDOWN (40 SECONDS)
#define HERETIC_SAND_STASIS_CHECK (0.5 SECONDS)
#define HERETIC_SAND_REWIND_TIME (3 SECONDS)
#define HERETIC_SAND_REWIND_COOLDOWN (30 SECONDS)
#define HERETIC_SAND_REWIND_GRACE (2 SECONDS)
#define HERETIC_SAND_REWIND_SLOWDOWN 1
#define HERETIC_SAND_REWIND_ALPHA 200
#define HERETIC_SAND_EFFECT_SHIFT -16
#define HERETIC_SAND_HASTE_MULTIPLIER 0.5

/datum/heretic_path/sand
	id = PATH_SAND
	deed_type = /datum/heretic_deed/sand
	name = "Песок"
	tagline = "Засечки ускоряют обряды, к ним переносит Откат, а Стазис останавливает время врага."
	craft_summary = "Хватка в «Помощи» по полу ставит до 3 засечек: к ним ведёт Откат, с Течением часа у них обряд вдвое быстрее."
	capture_summary = "Сбитая цель под Засухой застывает в Стазисе на 10 секунд, тащит её только еретик; сердце уводит её в изнанку."
	escape_summary = "Откат реликвией за 3 секунды переносит к засечке в 25 клетках; из изнанки выходите к своей засечке."
	strength_points = list(
		"С Течением часа ритуалы, руна и обряд сердцем у засечки идут вдвое быстрее, в изнанке - если её вход рядом.",
		"Засуха в полтора раза растягивает наручники, обыск, лечение и снятие оков.",
		"Стазис держит цель 10 секунд без урона и кровотечения: убить её нельзя, только забрать.",
		"Часы Погребения и взрыва метки запоминают стоявшего на них и перед взрывом возвращают его из 3 клеток.",
		"Начатый Откат не срывают урон, оглушение и чужая хватка.",
		"Вокруг вознёсшегося пули и заряды в 4 клетках летят втрое медленнее.",
	)
	weakness_points = list(
		"Засечку выдаёт песок, текущий вверх; у неё 30 прочности, нулевой жезл снимает её сразу.",
		"Стазис спадает от нулевого жезла, святой воды в крови или если растолкать за 2 секунды; антимагия защищает.",
		"Откат 3 секунды на виду, его срывают смерть, наручники и щит разума.",
		"От часов спасает отойти дальше 3 клеток, встать за преграду или разбить их.",
		"Урон пути ближний: Осыпь бьёт соседей, Стазис достаёт на 3 клетки.",
		"Замедление вознёсшегося не касается лучей, ближнего боя и брошенных предметов.",
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
		"Осыпь за единицу песка: соседям 20 ушибов и 10 выносливости, затем часы на 4 соседних клетках.",
		"Через 1,5 секунды каждые часы бьют свою клетку: 32 ушиба и 20 выносливости; у часов 15 прочности.",
		"Хватка в «Помощи» по свободному полу станции ставит засечку; до 3, новая вытесняет старую.",
		"У засечки 30 прочности, песок в ней течёт вверх, нулевой жезл её снимает; смерть её не трогает.",
		"Засечка в новом отделе продвигает дело пути; из изнанки можно выйти к своей засечке.",
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
		"Осыпь и Пересыпание стоят единицу, Стазис и Погребение - две.",
		"Одну и ту же цель часы бьют не чаще раза в 0,8 секунды.",
		"Смена тела обрывает часы, Стазис и точку возврата; засечки остаются.",
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
	var/sand_failure
	var/ascension_active = FALSE
	var/harvest_interval = HERETIC_SAND_HARVEST
	COOLDOWN_DECLARE(grasp_harvest)
	COOLDOWN_DECLARE(recovery)

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
	clear_sand()

/datum/eldritch_knowledge/base_sand/proc/on_body_deleted(datum/source)
	SIGNAL_HANDLER
	on_body_lose(sand_body)

/datum/eldritch_knowledge/base_sand/on_death(mob/user)
	clear_sand()
	combat_resource = 0
	notify_resource_changed()

/datum/eldritch_knowledge/base_sand/Destroy()
	on_body_lose(sand_body)
	for(var/obj/structure/heretic_sand_anchor/craft_anchor as anything in anchors.Copy())
		qdel(craft_anchor)
	anchors.Cut()
	return ..()

/datum/eldritch_knowledge/base_sand/proc/clear_sand()
	QDEL_LIST(hourglasses)
	QDEL_LIST(marks)
	QDEL_LIST(stases)
	QDEL_NULL(anchor)
	last_clock_hits.Cut()

/datum/eldritch_knowledge/base_sand/combat_resource_state()
	return "Засечек: [length(anchors)] из [HERETIC_SAND_ANCHOR_LIMIT]."

/datum/eldritch_knowledge/base_sand/proc/clear_knowledge(datum/eldritch_knowledge/required)
	for(var/obj/structure/heretic_sand_hourglass/hourglass as anything in hourglasses.Copy())
		if(hourglass.knowledge_ref?.resolve() == required)
			qdel(hourglass)

/datum/eldritch_knowledge/base_sand/proc/can_use(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	return !QDELETED(src) && isliving(user) && user == sand_body && !user.incapacitated() && isturf(user.loc) && heretic?.selected_path == PATH_SAND && !heretic.role_removed && heretic.get_knowledge(type) == src

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
	harvest(sand_body)
	return TRUE

/datum/eldritch_knowledge/base_sand/proc/create_hourglass(turf/tile, datum/eldritch_knowledge/required, damage = HERETIC_SAND_CLOCK_DAMAGE, distance = HERETIC_SAND_RANGE)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(sand_body)
	if(!can_use(sand_body) || QDELETED(required) || heretic.get_knowledge(required.type) != required || !line_clear(sand_body, tile, distance) || length(hourglasses) >= HERETIC_SAND_LIMIT)
		return null
	for(var/obj/structure/heretic_sand_hourglass/hourglass as anything in hourglasses)
		if(get_turf(hourglass) == tile)
			return null
	return new /obj/structure/heretic_sand_hourglass(tile, src, required, damage)

/// Старые часы вне нового поля уступают место, чтобы рисунок не упирался в предел.
/datum/eldritch_knowledge/base_sand/proc/make_room_for_hourglasses(needed, list/kept)
	var/overflow = length(hourglasses) + needed - HERETIC_SAND_LIMIT
	for(var/obj/structure/heretic_sand_hourglass/hourglass as anything in hourglasses.Copy())
		if(overflow <= 0)
			return
		if(hourglass in kept)
			continue
		qdel(hourglass)
		overflow--

/datum/eldritch_knowledge/base_sand/proc/release(mob/living/user)
	if(!can_use(user) || length(hourglasses) > HERETIC_SAND_LIMIT - 4 || !spend_combat_resource())
		return FALSE
	for(var/mob/living/victim in range(1, user))
		hit(victim, HERETIC_SAND_RELEASE_DAMAGE, HERETIC_SAND_RELEASE_STAMINA)
		if(!can_use(user))
			return TRUE
	for(var/direction in GLOB.cardinals)
		create_hourglass(get_step(user, direction), src)
	new /obj/effect/temp_visual/heretic_sand/cast(get_turf(user))
	playsound(user, 'modular_bluemoon/sound/heretic/sand_cast.ogg', 65, FALSE)
	return TRUE

/datum/eldritch_knowledge/base_sand/proc/place_anchor(mob/living/user, turf/place)
	grasp_failure_reason = null
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(!heretic || !can_use(user) || !istype(place))
		return FALSE
	if(locate(/obj/structure/heretic_sand_anchor) in place)
		grasp_failure_reason = "Здесь уже стоят песочные часы."
		return FALSE
	if(!isopenturf(place) || isgroundlessturf(place) || !is_station_level(place.z) || place.is_blocked_turf(exclude_mobs = TRUE))
		grasp_failure_reason = "Засечка встаёт только на свободном полу станции, не в космосе."
		return FALSE
	grasp_failure_reason = heretic.deed_wait_reason(heretic.deed_key_for(place))
	if(grasp_failure_reason)
		return FALSE
	while(length(anchors) >= HERETIC_SAND_ANCHOR_LIMIT)
		var/obj/structure/heretic_sand_anchor/oldest = anchors[1]
		log_game("[key_name(user)] теряет засечку Песка в [AREACOORD(oldest)]: её вытеснила новая.")
		anchors -= oldest
		qdel(oldest)
	new /obj/structure/heretic_sand_anchor/craft(place, src)
	new /obj/effect/temp_visual/heretic_sand/cast(place)
	playsound(place, 'modular_bluemoon/sound/heretic/sand_grasp.ogg', 40, FALSE)
	to_chat(user, span_eldritch("Песок в часах потёк вверх: засечка поставлена. Засечек: [length(anchors)] из [HERETIC_SAND_ANCHOR_LIMIT]."))
	log_game("[key_name(user)] ставит засечку Песка в [AREACOORD(place)].")
	heretic.advance_deed(heretic.deed_key_for(place), place)
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

/datum/eldritch_knowledge/base_sand/proc/nearest_anchor(atom/origin, range = HERETIC_SAND_REWIND_RANGE)
	var/turf/center = get_turf(origin)
	var/best_distance = INFINITY
	for(var/obj/structure/heretic_sand_anchor/craft_anchor as anything in anchors)
		var/turf/place = get_turf(craft_anchor)
		var/area/place_area = get_area(place)
		if(!center || !place || place.z != center.z || (place_area.area_flags & NOTELEPORT) || place.is_blocked_turf(exclude_mobs = TRUE))
			continue
		var/distance = get_dist(center, place)
		if(!distance || distance > range || distance >= best_distance)
			continue
		best_distance = distance
		. = craft_anchor

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
	if(check_ready && !victim.has_status_effect(/datum/status_effect/heretic_sand_drought))
		return "Стазис берёт только цель под Засухой: сначала коснитесь её Хваткой."
	if(check_ready && !heretic_capture_downed(victim))
		return "Застывает только сбитая с ног или обессиленная цель: сон и добровольный отдых сами по себе не в счёт."
	if(check_cost && combat_resource < HERETIC_SAND_STASIS_COST)
		return "Для Стазиса нужно [HERETIC_SAND_STASIS_COST] единицы песка."
	return null

/datum/eldritch_knowledge/base_sand/proc/stasis(mob/living/user, mob/living/victim)
	sand_failure = stasis_block_reason(user, victim)
	if(sand_failure || !spend_combat_resource(HERETIC_SAND_STASIS_COST))
		return FALSE
	var/turf/place = get_turf(victim)
	new /obj/effect/temp_visual/heretic_sand/stasis(place)
	addtimer(CALLBACK(src, PROC_REF(seal_stasis), user, victim, place), HERETIC_SAND_STASIS_TELEGRAPH)
	user.visible_message(span_danger("Вокруг [victim] закручивается песок, и движения становятся вязкими!"), span_notice("Песок смыкается вокруг [victim]."))
	playsound(place, 'modular_bluemoon/sound/heretic/sand_cast.ogg', 50, FALSE)
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
	return TRUE

/datum/eldritch_knowledge/base_sand/proc/step_through(mob/living/user, turf/target)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/required = heretic?.get_knowledge(/datum/eldritch_knowledge/spell/sand_step)
	if(!can_use(user) || QDELETED(required) || combat_resource < 1 || user.buckled || user.anchored || HAS_TRAIT(user, TRAIT_NO_TELEPORT) || !line_clear(user, target, HERETIC_SAND_STEP_RANGE) || target == get_turf(user) || target.is_blocked_turf())
		return FALSE
	var/turf/origin = get_turf(user)
	if(!do_teleport(user, target, channel = TELEPORT_CHANNEL_MAGIC) || get_turf(user) != target)
		return FALSE
	if(!can_use(user) || QDELETED(required) || heretic.get_knowledge(required.type) != required)
		return TRUE
	spend_combat_resource()
	create_hourglass(origin, required)
	new /obj/effect/temp_visual/heretic_sand/cast(origin)
	new /obj/effect/temp_visual/heretic_sand/cast(target)
	playsound(target, 'modular_bluemoon/sound/heretic/sand_cast.ogg', 60, FALSE)
	return TRUE

/datum/eldritch_knowledge/base_sand/proc/burial(mob/living/user, turf/target, final_cast = FALSE)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/required_type = final_cast ? /datum/eldritch_knowledge/final_eldritch/sand_final : /datum/eldritch_knowledge/spell/sand_burial
	var/datum/eldritch_knowledge/required = heretic?.get_knowledge(required_type)
	if(!can_use(user) || QDELETED(required) || !line_clear(user, target) || (final_cast && (!ascension_active || !heretic.ascended)))
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
	if(!length(tiles) || (!final_cast && !spend_combat_resource(2)))
		return FALSE
	make_room_for_hourglasses(length(tiles), field_hourglasses)
	for(var/mob/living/victim in range(1, target))
		if(line_clear(target, victim, 1))
			if(hit(victim, final_cast ? HERETIC_SAND_FINAL_DAMAGE : HERETIC_SAND_BURIAL_DAMAGE, 15) && !final_cast && !QDELETED(victim))
				victim.apply_status_effect(/datum/status_effect/heretic_sand_drought)
			if(!can_use(user))
				return TRUE
	for(var/turf/tile as anything in tiles)
		var/obj/structure/heretic_sand_hourglass/hourglass = create_hourglass(tile, required, final_cast ? 44 : HERETIC_SAND_CLOCK_DAMAGE, distance = area_reach)
		for(var/mob/living/victim in tile)
			if(hourglass?.record_target(victim))
				break
	if(final_cast)
		last_noon(user, target)
	new /obj/effect/temp_visual/heretic_sand/ascend(target)
	playsound(target, final_cast ? 'modular_bluemoon/sound/heretic/sand_ascend.ogg' : 'modular_bluemoon/sound/heretic/sand_cast.ogg', 75, FALSE)
	return TRUE

/// Последний полдень: над целью вспыхивает солнце, по песку идёт волна, взлетают песчинки, пол дрожит.
/datum/eldritch_knowledge/base_sand/proc/last_noon(mob/living/user, turf/target)
	new /obj/effect/temp_visual/heretic_sand_sun(target)
	heretic_vfx_shockwave(target, HERETIC_SAND_INK, HERETIC_SAND_NOON_WAVE_RADIUS, HERETIC_SAND_NOON_WAVE_TIME)
	heretic_vfx_burst(target, /particles/heretic_ascension/sand)
	heretic_vfx_flash(target, HERETIC_SAND_SUN_LIGHT, HERETIC_SAND_NOON_FLASH_RANGE, HERETIC_SAND_NOON_FLASH_POWER, HERETIC_SAND_NOON_FLASH_TIME)
	heretic_vfx_quake(target, HERETIC_SAND_NOON_QUAKE_RADIUS, HERETIC_SAND_NOON_QUAKE, HERETIC_SAND_NOON_QUAKE_TIME)
	heretic_vfx_pulse(user, HERETIC_SAND_SUN_LIGHT, 2, HERETIC_SAND_NOON_PULSE_TIME)

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
	add_overlay(emissive_appearance(icon, icon_state))
	transform = matrix(HERETIC_SAND_SUN_START, 0, 0, 0, HERETIC_SAND_SUN_START, 0)
	animate(src, transform = matrix(HERETIC_SAND_SUN_PEAK, 0, 0, 0, HERETIC_SAND_SUN_PEAK, 0), time = HERETIC_SAND_SUN_RISE, easing = BACK_EASING | EASE_OUT)
	animate(transform = matrix(HERETIC_SAND_SUN_END, 0, 0, 0, HERETIC_SAND_SUN_END, 0), alpha = 0, time = HERETIC_SAND_SUN_TIME - HERETIC_SAND_SUN_RISE, easing = SINE_EASING | EASE_IN)
	heretic_vfx_rays(src, HERETIC_SAND_SUN_LIGHT, HERETIC_SAND_SUN_TIME)

/obj/structure/heretic_sand_hourglass
	name = "borrowed second"
	desc = "Песок стремительно пересыпается сквозь невидимое горлышко. Через 1,5 секунды ударит только по этой клетке. Отойдите, разбейте часы или коснитесь их нулевым жезлом."
	icon = 'modular_bluemoon/icons/obj/heretic_sand.dmi'
	icon_state = "sand_hourglass"
	anchored = TRUE
	density = FALSE
	max_integrity = 15
	var/datum/weakref/sand_ref
	var/datum/weakref/knowledge_ref
	var/expiry_timer
	var/impact_damage
	var/expires_at
	var/delayed = FALSE
	var/datum/status_effect/heretic_sand_recall/recorded_second

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

/obj/structure/heretic_sand_hourglass/proc/source_deleted(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/obj/structure/heretic_sand_hourglass/proc/record_target(mob/living/victim)
	var/datum/eldritch_knowledge/base_sand/sand = sand_ref?.resolve()
	if(recorded_second || !sand?.can_use(sand.sand_body) || !isturf(victim?.loc) || get_turf(victim) != get_turf(src) || !heretic_can_affect(sand.sand_body, victim, chargecost = 0))
		return FALSE
	recorded_second = victim.apply_status_effect(/datum/status_effect/heretic_sand_recall, src)
	if(recorded_second)
		desc = "[initial(desc)] Эти часы запомнили [victim]: перед взрывом вернут жертву, если она останется в трёх клетках без преград."
	return !!recorded_second

/obj/structure/heretic_sand_hourglass/proc/resolve()
	var/datum/eldritch_knowledge/base_sand/sand = sand_ref?.resolve()
	var/datum/eldritch_knowledge/required = knowledge_ref?.resolve()
	var/datum/antagonist/heretic/heretic = IS_HERETIC(sand?.sand_body)
	if(sand?.can_use(sand.sand_body) && required && heretic.get_knowledge(required.type) == required && isturf(loc) && sand.line_clear(sand.sand_body, src, HERETIC_SAND_RANGE + 2))
		var/mob/living/recorded_target = recorded_second?.owner
		var/turf/destination = get_turf(src)
		if(recorded_target && get_turf(recorded_target) != destination && isturf(recorded_target.loc) && !recorded_target.buckled && !recorded_target.anchored && !HAS_TRAIT(recorded_target, TRAIT_NO_TELEPORT) && !destination.is_blocked_turf() && sand.line_clear(src, recorded_target, HERETIC_SAND_RECALL_RANGE) && sand.line_clear(sand.sand_body, recorded_target, HERETIC_SAND_RANGE + 2) && heretic_can_affect(sand.sand_body, recorded_target))
			new /obj/effect/temp_visual/heretic_sand/cast(get_turf(recorded_target))
			do_teleport(recorded_target, destination, channel = TELEPORT_CHANNEL_MAGIC)
		if(QDELETED(src) || !sand.can_use(sand.sand_body))
			return
		for(var/mob/living/victim in loc)
			sand.hit(victim, impact_damage, 20, clock_hit = TRUE)
			if(QDELETED(src) || !sand.can_use(sand.sand_body))
				return
		new /obj/effect/temp_visual/heretic_sand/impact(get_turf(src))
		playsound(src, 'modular_bluemoon/sound/heretic/sand_impact.ogg', 60, FALSE)
	qdel(src)

/obj/structure/heretic_sand_hourglass/proc/delay_impact(mob/living/user)
	var/datum/eldritch_knowledge/base_sand/sand = sand_ref?.resolve()
	if(QDELETED(src) || delayed || world.time >= expires_at || !sand?.can_use(user) || !sand.line_clear(user, src) || !sand.spend_combat_resource())
		return FALSE
	delayed = TRUE
	expires_at += HERETIC_SAND_EXTRA_DELAY
	deltimer(expiry_timer)
	expiry_timer = addtimer(CALLBACK(src, PROC_REF(resolve)), expires_at - world.time, TIMER_STOPPABLE)
	color = "#d6ad70"
	desc = "Песок пересыпается медленнее: создатель продлил отсчёт на 1,5 секунды. Часы ударят только по своей клетке; сохранённая ими цель вернётся перед ударом, если останется в трёх клетках без преград. Часы можно разбить или коснуться их нулевым жезлом."
	visible_message(span_warning("[src] вспыхивают бронзовым светом. Падение песчинок замедляется!"))
	if(recorded_second?.owner)
		to_chat(recorded_second.owner, span_userdanger("Часы удерживают ваш шаг ещё на 1,5 секунды. Успейте уйти дальше трёх клеток или разбейте их!"))
	return TRUE

/obj/structure/heretic_sand_hourglass/attackby(obj/item/item, mob/living/user)
	if(istype(item, /obj/item/nullrod))
		qdel(src)
		return
	return ..()

/obj/structure/heretic_sand_hourglass/Destroy()
	deltimer(expiry_timer)
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

/datum/status_effect/heretic_sand_recall/on_creation(mob/living/new_owner, obj/structure/heretic_sand_hourglass/hourglass)
	hourglass_ref = WEAKREF(hourglass)
	return ..()

/datum/status_effect/heretic_sand_recall/on_apply()
	if(!..())
		return FALSE
	to_chat(owner, span_userdanger("Часы запомнили ваш шаг! Через 1,5 секунды они вернут вас к себе. Отойдите дальше трёх клеток, скройтесь за преградой или разбейте часы!"))
	return TRUE

/datum/status_effect/heretic_sand_recall/be_replaced()
	on_remove()
	return ..()

/datum/status_effect/heretic_sand_recall/on_remove()
	var/obj/structure/heretic_sand_hourglass/hourglass = hourglass_ref?.resolve()
	if(hourglass?.recorded_second == src)
		hourglass.recorded_second = null
	return ..()

/atom/movable/screen/alert/status_effect/heretic_sand_recall
	name = "Украденная секунда"
	desc = "Песочные часы вернут вас на отмеченную клетку перед взрывом. Отойдите дальше трёх клеток от часов, перекройте путь преградой или разбейте их. Антимагия и запрет телепортации защищают от возврата."
	icon = 'modular_bluemoon/icons/obj/heretic_alerts.dmi'
	icon_state = "sand_recall"

/obj/structure/heretic_sand_anchor
	name = "unspent hour"
	desc = "Неподвижные песочные часы отмечают место возврата на пять секунд. Разбейте их или коснитесь нулевым жезлом, чтобы закрыть обратный путь."
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
	desc = "Песочные часы стоят на полу вверх дном. Хрупкие: их можно разбить или коснуться нулевым жезлом."
	max_integrity = HERETIC_SAND_ANCHOR_INTEGRITY

/obj/structure/heretic_sand_anchor/craft/bind_to(datum/eldritch_knowledge/base_sand/sand)
	transform = matrix(1, 0, 0, 0, -1, 0)
	sand.anchors += src
	AddComponent(/datum/component/heretic_craft, sand, HERETIC_SAND_ANCHOR_CRAFT, HERETIC_SAND_ANCHOR_CLUE)

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
	desc = "Песочные часы, которые удобно держать в ладони. Если в 25 клетках на вашем уровне стоит ваша засечка, применение начинает Откат: 3 секунды вокруг вас кружит песок, вы замедлены, затем переноситесь к ближайшей засечке вне зон, закрытых для телепортации; смерть, наручники и щит разума срывают перенос, перезарядка 30 секунд. Без засечек рядом первое применение оставляет на пять секунд разрушаемую точку возврата, повторное возвращает к ней через открытую линию не длиннее пяти клеток; перезарядка 20 секунд с установки. В зоне, закрытой для телепортации, точка не ставится и не возвращает; часы называют причину отказа. Раны и эффекты сохраняются. Щелчок реликвией по своим боевым часам в пяти клетках за единицу песка однократно продлевает отсчёт на 1,5 секунды."
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
	if(!sand.anchor && sand.nearest_anchor(user))
		return begin_rewind(user, sand)
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
	playsound(user, 'modular_bluemoon/sound/heretic/sand_cast.ogg', 50, FALSE)
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

/obj/item/heretic_path_relic/sand_relic/proc/begin_rewind(mob/living/user, datum/eldritch_knowledge/base_sand/sand)
	sand.sand_failure = rewind_block_reason(user)
	if(!sand.sand_failure && !user.apply_status_effect(/datum/status_effect/heretic_sand_rewind, sand))
		sand.sand_failure = "Откат уже идёт."
	if(sand.sand_failure)
		to_chat(user, span_warning(sand.sand_failure))
		return FALSE
	COOLDOWN_START(src, relic_cooldown, HERETIC_SAND_REWIND_COOLDOWN)
	log_game("[key_name(user)] начинает Откат Песка в [AREACOORD(user)].")
	return TRUE

/obj/item/heretic_path_relic/sand_relic/proc/rewind_block_reason(mob/living/user)
	if(!COOLDOWN_FINISHED(src, relic_cooldown))
		return "Песок в часах ещё не осел: до Отката осталось [DisplayTimeText(COOLDOWN_TIMELEFT(src, relic_cooldown))]."
	var/containment = heretic_containment_reason(user)
	if(containment)
		return containment
	if(user.buckled || user.anchored || HAS_TRAIT(user, TRAIT_NO_TELEPORT))
		return "Что-то держит вас на месте: Откат не начнётся."
	var/area/origin_area = get_area(user)
	if(origin_area.area_flags & NOTELEPORT)
		return "Здесь время не течёт вспять: из этой зоны Откат недоступен."
	return null

/datum/status_effect/heretic_sand_rewind
	id = "heretic_sand_rewind"
	duration = HERETIC_SAND_REWIND_TIME + HERETIC_SAND_REWIND_GRACE
	tick_interval = -1
	status_type = STATUS_EFFECT_UNIQUE
	on_remove_on_mob_delete = TRUE
	alert_type = /atom/movable/screen/alert/status_effect/heretic_sand_rewind
	var/datum/weakref/sand_ref
	var/obj/effect/abstract/heretic_vfx_attached/vortex
	var/rewind_timer

/datum/status_effect/heretic_sand_rewind/on_creation(mob/living/new_owner, datum/eldritch_knowledge/base_sand/sand)
	sand_ref = WEAKREF(sand)
	return ..()

/datum/status_effect/heretic_sand_rewind/on_apply()
	. = ..()
	if(!.)
		return
	owner.add_movespeed_modifier(/datum/movespeed_modifier/heretic_sand_rewind)
	vortex = heretic_vfx_attach(owner, 'modular_bluemoon/icons/obj/heretic_sand_effects.dmi', "sand_ascend", HERETIC_SAND_REWIND_ALPHA)
	if(vortex)
		vortex.pixel_x = HERETIC_SAND_EFFECT_SHIFT
		vortex.pixel_y = HERETIC_SAND_EFFECT_SHIFT
	RegisterSignal(owner, COMSIG_LIVING_DEATH, PROC_REF(on_owner_death))
	rewind_timer = addtimer(CALLBACK(src, PROC_REF(complete)), HERETIC_SAND_REWIND_TIME, TIMER_STOPPABLE)
	owner.visible_message(span_danger("Вокруг [owner] закручивается песок: время вокруг течёт вспять!"), span_notice("Песок подхватывает вас. Через [DisplayTimeText(HERETIC_SAND_REWIND_TIME)] вы окажетесь у засечки."))
	playsound(owner, 'modular_bluemoon/sound/heretic/sand_cast.ogg', 50, FALSE)

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
	if(!sand.nearest_anchor(owner))
		return "рядом не осталось свободной засечки."
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
	var/turf/destination = get_turf(sand.nearest_anchor(owner))
	if(!do_teleport(owner, destination, channel = TELEPORT_CHANNEL_MAGIC) || get_turf(owner) != destination)
		to_chat(owner, span_warning("Откат сорвался: песок не нашёл пути к засечке."))
		qdel(src)
		return FALSE
	new /obj/effect/temp_visual/heretic_sand/cast(origin)
	new /obj/effect/temp_visual/heretic_sand/cast(destination)
	playsound(destination, 'modular_bluemoon/sound/heretic/sand_cast.ogg', 60, FALSE)
	log_game("[key_name(owner)] откатывается к засечке Песка из [AREACOORD(origin)] в [AREACOORD(destination)].")
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

/datum/movespeed_modifier/heretic_sand_rewind
	multiplicative_slowdown = HERETIC_SAND_REWIND_SLOWDOWN

/atom/movable/screen/alert/status_effect/heretic_sand_rewind
	name = "Откат"
	desc = "Песок уносит вас к ближайшей засечке. Смерть, наручники и щит разума сорвут перенос."
	icon = 'modular_bluemoon/icons/obj/heretic_sand.dmi'
	icon_state = "sand_anchor"

/datum/status_effect/heretic_sand_drought
	id = "heretic_sand_drought"
	duration = HERETIC_SAND_DROUGHT_DURATION
	tick_interval = -1
	status_type = STATUS_EFFECT_REFRESH
	alert_type = /atom/movable/screen/alert/status_effect/heretic_sand_drought

/datum/status_effect/heretic_sand_drought/on_apply()
	. = ..()
	if(!.)
		return
	owner.add_actionspeed_modifier(/datum/actionspeed_modifier/heretic_sand_drought)

/datum/status_effect/heretic_sand_drought/on_remove()
	owner.remove_actionspeed_modifier(/datum/actionspeed_modifier/heretic_sand_drought)
	return ..()

/datum/actionspeed_modifier/heretic_sand_drought
	multiplicative_slowdown = HERETIC_SAND_DROUGHT_SLOWDOWN

/atom/movable/screen/alert/status_effect/heretic_sand_drought
	name = "Засуха"
	desc = "Руки пересохли: всё, что вы делаете с задержкой, - надеваете наручники, обыскиваете, лечите, снимаете оковы - идёт в полтора раза дольше."
	icon = 'modular_bluemoon/icons/obj/heretic_sand.dmi'
	icon_state = "sand_grasp"

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
	var/datum/eldritch_knowledge/base_sand/sand = sand_ref?.resolve()
	sand?.stases -= src
	sand_ref = null
	heretic_capture_release(owner, HERETIC_SAND_CAPTURE, held_for = heretic_capture_held_for(held_since))
	return ..()

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
	effect_sprite_icon = 'modular_bluemoon/icons/obj/heretic_sand.dmi'
	effect_sprite = "sand_mark"
	detonation_sound = 'modular_bluemoon/sound/heretic/sand_grasp.ogg'
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
	icon_state = "sand_ascend"
	duration = HERETIC_SAND_STASIS_TELEGRAPH

/datum/heretic_deed/sand
	next_step = "В намерении «Помощь» коснитесь Хваткой Мансуса свободного пола в ещё не зачтённом отделе: там встанет засечка."
	name = "Засечки"
	desc = "Ставьте Хваткой Мансуса в намерении «Помощь» засечки - песочные часы на свободном полу станции - в разных отделах. Каждый отдел засчитывается один раз."
	craft_wait = "засечка не встаёт"
	hint = "Держатся три засечки, новая вытесняет самую старую. Песок в них течёт вверх, и экипаж это заметит; засечка ломается обычными ударами (30 прочности), нулевой жезл снимает её сразу. У засечки реликвия принимает вас при Откате, а Течение часа ускоряет обряды."
	trace_name = "sand of the spent hour"
	trace_desc = "Мелкий золотой песок лежит кольцом, будто высыпался из перевёрнутых часов."
	trace_state = "sigil_sand"

/datum/eldritch_knowledge/base_sand/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	grasp_failure_reason = null
	if(!proximity_flag || !isturf(target) || user.a_intent != INTENT_HELP)
		return FALSE
	return place_anchor(user, target)

/datum/eldritch_knowledge/sand_grasp
	name = "Сухая ладонь"
	summary = "Хватка насылает на врага Засуху на 8 секунд и даёт 2 песка."
	details = list(
		"Под Засухой наручники, обыск, лечение и снятие оков у цели идут в полтора раза дольше.",
		"Цель под Засухой можно остановить Стазисом.",
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
	var/mob/living/victim = target
	victim.apply_status_effect(/datum/status_effect/heretic_sand_drought)
	if(COOLDOWN_FINISHED(sand, grasp_harvest))
		sand.gain_combat_resource(2)
		COOLDOWN_START(sand, grasp_harvest, HERETIC_SAND_HARVEST)
	return TRUE

/datum/eldritch_knowledge/spell/sand_stasis
	name = "Стазис"
	summary = "За 2 песка останавливает время поверженной цели под Засухой на 10 секунд."
	details = list(
		"Цель в 3 клетках по открытой линии, под Засухой и сбита с ног или обессилена; сон и отдых не в счёт.",
		"Секунду песок смыкается: если цель увели с клетки или Засуха спала, Стазис рассыпается.",
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
		"Через 1,5 секунды часы возвращают цель на эту клетку и взрываются.",
		"Спастись можно, разбив часы, отойдя дальше 3 клеток или встав за преграду; защищают и антимагия, и запрет телепортации.",
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
		"Откат работает, если засечка в 25 клетках на вашем уровне: 3 секунды вас кружит песок и замедляет, затем вы у засечки.",
		"Засечки в зонах без телепортации не подходят; смерть, наручники и щит разума срывают Откат.",
		"Перезарядка Отката 30 секунд; раны и эффекты сохраняются. Реликвия одна.",
		"Без засечек рядом часы ставят точку возврата на 5 секунд; второе применение возвращает к ней, если она в 5 клетках.",
		"У точки 25 прочности, перезарядка 20 секунд; преграды и запрет телепортации мешают возврату.",
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
		"После вознесения запас 8.",
	)
	role = HERETIC_ROLE_PASSIVE
	gain_text = "Я увидел дно колбы. Оно отступило в темноту."
	cost = 2
	route = PATH_SAND
	passive_values = list(5, 6, 7)
	passive_desc = "Предел песка — 5 / 6 / 7, получение песка клинком и заклинаниями — раз в 5 / 4 / 3 секунды. После вознесения вместимость — 8."

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
		"13 часов в шахматном порядке запоминают врага на своей клетке и через 1,5 секунды возвращают его перед взрывом.",
		"Между часами есть проходы; спастись можно, отойдя дальше 3 клеток, встав за преграду или разбив часы.",
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
	summary = "Время вокруг вас замедляет чужие пули, запас песка растёт, открывается Последний полдень."
	details = list(
		"Нужны 3 назначенные души и 3 человеческих трупа на руне; станция узнаёт место обряда, он длится 30 секунд.",
		"Общая стойкость вознесения, запас песка 8, единица восстанавливается каждые 4 секунды.",
		"Пули и заряды врагов в 4 клетках летят втрое медленнее; лучи, ближний бой и броски - нет.",
		"В шкафу или мехе поле не действует.",
		"Последний полдень - бесплатное Погребение: первый удар наносит 40 ушибов, а часы бьют на 44.",
		"Перезарядка Последнего полудня 30 секунд.",
	)
	role = HERETIC_ROLE_ASCENSION
	gain_text = "Все часы остановились. Я услышал, как станция сделала следующий вдох без их разрешения."
	route = PATH_SAND
	required_atoms = list(/mob/living/carbon/human, /mob/living/carbon/human, /mob/living/carbon/human)
	ascension_spells = list(/obj/effect/proc_holder/spell/pointed/heretic_sand/final)
	var/datum/weakref/sand_knowledge_ref

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

/// Граница поля видна: бледное песчаное кольцо дышит, по нему медленно кружат и осыпаются песчинки.
/datum/component/heretic_sand_slowtime/proc/show_field()
	var/mob/living/owner = parent
	var/radius = HERETIC_SAND_FIELD_REACH * world.icon_size
	field_ring = heretic_vfx_attach(owner, 'modular_bluemoon/icons/effects/heretic_shockwave.dmi', "ring", HERETIC_SAND_FIELD_ALPHA)
	if(field_ring)
		var/scale = radius / HERETIC_SAND_RING_ICON_RADIUS
		field_ring.layer = BELOW_MOB_LAYER
		field_ring.appearance_flags &= ~PIXEL_SCALE
		field_ring.color = heretic_vfx_ink_ramp(HERETIC_SAND_INK)
		field_ring.pixel_x = (world.icon_size - HERETIC_SAND_RING_ICON_SIZE) / 2
		field_ring.pixel_y = field_ring.pixel_x
		field_ring.transform = matrix(scale, 0, 0, 0, scale, 0)
		animate(field_ring, transform = matrix(scale * HERETIC_SAND_FIELD_BREATH, 0, 0, 0, scale * HERETIC_SAND_FIELD_BREATH, 0), time = HERETIC_SAND_FIELD_BREATH_TIME, loop = -1, easing = SINE_EASING, flags = ANIMATION_PARALLEL)
		animate(transform = matrix(scale, 0, 0, 0, scale, 0), time = HERETIC_SAND_FIELD_BREATH_TIME, easing = SINE_EASING)
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
	desc = "За единицу песка нанесите соседним врагам 20 ушибов и 10 урона выносливости, затем поставьте часы на четырёх соседних клетках. Они взорвутся через 1,5 секунды только на своей клетке: 32 ушиба и 20 урона выносливости."
	summary = "Соседям 20 ушибов и 10 выносливости, затем часы на 4 клетках: 32 ушиба через 1,5 секунды."
	charge_max = 12 SECONDS
	action_icon_state = "sand_release"

/obj/effect/proc_holder/spell/self/heretic_sand/release/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_sand/sand = heretic?.get_knowledge(/datum/eldritch_knowledge/base_sand)
	if(!sand?.release(user))
		heretic_revert_cast(user)

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
	desc = "Остановите время цели в 3 клетках под Засухой, сбитой с ног или обессиленной: 10 секунд она не действует и не получает урона. Стазис развеется от нулевого жезла, святой воды или если растолкать цель за 2 секунды. Стоит 2 песка, перезарядка 40 секунд."
	summary = "10 секунд застывшего времени для цели под Засухой, сбитой или обессиленной; 2 песка."
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
		heretic_revert_cast(user)

/obj/effect/proc_holder/spell/pointed/heretic_sand/burial
	name = "Погребение"
	desc = "За 2 песка область 3×3 получает 28 ушибов, 15 выносливости и Засуху на 8 секунд. 13 часов на поле 5×5 запоминают врагов на своих клетках и через 1,5 секунды возвращают их перед взрывом."
	summary = "Область 3×3: 28 ушибов и Засуха, затем 13 часов на поле 5×5 возвращают врагов перед взрывом."
	charge_max = 35 SECONDS
	action_icon_state = "sand_burial"

/obj/effect/proc_holder/spell/pointed/heretic_sand/burial/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_sand/sand = heretic?.get_knowledge(/datum/eldritch_knowledge/base_sand)
	if(!length(targets) || !sand?.burial(user, get_turf(targets[1])))
		heretic_revert_cast(user)

/obj/effect/proc_holder/spell/pointed/heretic_sand/final
	name = "Последний полдень"
	desc = "Бесплатное Погребение: первый удар наносит 40 ушибов, часы — 44. Требует вознесения."
	summary = "Бесплатное Погребение: первый удар 40 ушибов, часы - 44."
	charge_max = 30 SECONDS
	action_icon_state = "sand_final"

/obj/effect/proc_holder/spell/pointed/heretic_sand/final/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_sand/sand = heretic?.get_knowledge(/datum/eldritch_knowledge/base_sand)
	if(!length(targets) || !sand?.burial(user, get_turf(targets[1]), final_cast = TRUE))
		heretic_revert_cast(user)

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
#undef HERETIC_SAND_FINAL_DAMAGE
#undef HERETIC_SAND_RECALL_RANGE
#undef HERETIC_SAND_EXTRA_DELAY
#undef HERETIC_SAND_SLOW_COLOR
#undef HERETIC_SAND_INK
#undef HERETIC_SAND_SUN_LIGHT
#undef HERETIC_SAND_RING_ICON_SIZE
#undef HERETIC_SAND_RING_ICON_RADIUS
#undef HERETIC_SAND_FIELD_SPREAD
#undef HERETIC_SAND_FIELD_ALPHA
#undef HERETIC_SAND_FIELD_BREATH
#undef HERETIC_SAND_FIELD_BREATH_TIME
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
#undef HERETIC_SAND_ANCHOR_CRAFT
#undef HERETIC_SAND_ANCHOR_CLUE
#undef HERETIC_SAND_CAPTURE
#undef HERETIC_SAND_DROUGHT_SLOWDOWN
#undef HERETIC_SAND_STASIS_RANGE
#undef HERETIC_SAND_STASIS_COST
#undef HERETIC_SAND_STASIS_TELEGRAPH
#undef HERETIC_SAND_STASIS_COOLDOWN
#undef HERETIC_SAND_STASIS_CHECK
#undef HERETIC_SAND_REWIND_TIME
#undef HERETIC_SAND_REWIND_COOLDOWN
#undef HERETIC_SAND_REWIND_GRACE
#undef HERETIC_SAND_REWIND_SLOWDOWN
#undef HERETIC_SAND_REWIND_ALPHA
#undef HERETIC_SAND_EFFECT_SHIFT
#undef HERETIC_SAND_HASTE_MULTIPLIER
