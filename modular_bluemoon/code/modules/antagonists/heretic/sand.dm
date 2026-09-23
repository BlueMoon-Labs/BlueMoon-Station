#define HERETIC_SAND_RANGE 5
#define HERETIC_SAND_DELAY (1.5 SECONDS)
#define HERETIC_SAND_LIMIT 13
#define HERETIC_SAND_HIT_INTERVAL (0.8 SECONDS)
#define HERETIC_SAND_ANCHOR_TIME (5 SECONDS)
#define HERETIC_SAND_CLOCK_DAMAGE 32
#define HERETIC_SAND_HARVEST (6 SECONDS)
#define HERETIC_SAND_BLADE_DELAY (0.6 SECONDS)
#define HERETIC_SAND_STEP_RANGE 4
#define HERETIC_SAND_RELEASE_DAMAGE 20
#define HERETIC_SAND_RELEASE_STAMINA 10
#define HERETIC_SAND_WIND_DAMAGE 28
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

/datum/heretic_path/sand
	id = PATH_SAND
	deed_type = /datum/heretic_deed/sand
	name = "Песок"
	desc = "Украдите у врага секунду: часы запоминают его позицию и возвращают туда перед взрывом. Оборвите отсчёт клинком, пересыпьтесь вперёд и вернитесь к собственному оставленному мгновению."
	strengths = "Возврат противника на отмеченную клетку, ускорение отсчёта клинком и смена собственной позиции. Сквозняк наносит урон сразу и готовит временную ловушку. Вокруг вознёсшегося вражеские пули и заряды в радиусе четырёх клеток летят втрое медленнее: от них успеваешь уйти."
	weaknesses = "Часы можно разбить, а возврата избежать, уйдя дальше трёх клеток от них или закрыв путь преградой. Антимагия и запрет телепортации защищают от возврата. Собственная реликвия не лечит. Замедление вознёсшегося не касается ближнего боя и брошенных предметов."
	knowledge = list(
		/datum/eldritch_knowledge/base_sand,
		/datum/eldritch_knowledge/sand_grasp,
		/datum/eldritch_knowledge/spell/sand_wind,
		/datum/eldritch_knowledge/sand_mark,
		/datum/eldritch_knowledge/sand_relic,
		/datum/eldritch_knowledge/sand_upgrade,
		/datum/eldritch_knowledge/spell/sand_step,
		/datum/eldritch_knowledge/sand_sustain,
		/datum/eldritch_knowledge/spell/sand_burial,
		/datum/eldritch_knowledge/final_eldritch/sand_final,
	)

/datum/eldritch_knowledge/base_sand
	name = "Между двумя песчинками"
	desc = "Нож и стекло создают клинок истёкшего часа. Осыпь за единицу песка сразу наносит соседним врагам 20 ушибов и 10 урона выносливости, затем ставит часы на четырёх соседних клетках. Через 1,5 секунды каждые часы наносят 32 ушиба и 20 урона выносливости только на своей клетке. Часы можно разбить: 15 прочности."
	gain_text = "Я перевернул часы. Сверху осталось столько же песка. Снизу появилась моя тень."
	route = PATH_SAND
	required_atoms = list(/obj/item/kitchen/knife, /obj/item/stack/sheet/glass)
	result_atoms = list(/obj/item/melee/sickly_blade/sand)
	combat_resource = 2
	combat_resource_name = "Песок"
	combat_resource_desc = "Клинок или заклинание возвращает единицу раз в 6 секунд (с Глубокой колбой — раз в 5 / 4 / 3 секунды); хватка даёт две раз в 6 секунд, метка — одну. Пустой запас восстанавливается до единицы за 8 секунд. Осыпь и Пересыпание стоят единицу, Погребение — две. Часы не складывают урон чаще раза в 0,8 секунды на цель. Смена тела обрывает часы и возврат."
	combat_resource_action = /obj/effect/proc_holder/spell/self/heretic_sand/release
	grasp_visual = /obj/effect/temp_visual/heretic_sand/grasp
	grasp_sound = 'modular_bluemoon/sound/heretic/sand_grasp.ogg'
	grasp_catchphrase = "SME'LIS BE'GA"
	var/mob/living/sand_body
	var/list/obj/structure/heretic_sand_hourglass/hourglasses = list()
	var/list/datum/status_effect/eldritch/sand/marks = list()
	var/list/last_clock_hits = list()
	var/obj/structure/heretic_sand_anchor/anchor
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
	return ..()

/datum/eldritch_knowledge/base_sand/proc/clear_sand()
	QDEL_LIST(hourglasses)
	QDEL_LIST(marks)
	QDEL_NULL(anchor)
	last_clock_hits.Cut()

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

/datum/eldritch_knowledge/base_sand/proc/wind(mob/living/user, turf/target)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/required = heretic?.get_knowledge(/datum/eldritch_knowledge/spell/sand_wind)
	if(!can_use(user) || QDELETED(required) || !line_clear(user, target) || target == get_turf(user))
		return FALSE
	var/mob/living/recorded_target
	for(var/turf/tile as anything in get_line(get_turf(user), target))
		for(var/mob/living/victim in tile)
			if(hit(victim, HERETIC_SAND_WIND_DAMAGE, 15) && tile == target && !recorded_target)
				recorded_target = victim
			if(!can_use(user))
				return TRUE
		new /obj/effect/temp_visual/heretic_sand/cast(tile)
	var/obj/structure/heretic_sand_hourglass/hourglass = create_hourglass(target, required)
	hourglass?.record_target(recorded_target)
	playsound(user, 'modular_bluemoon/sound/heretic/sand_cast.ogg', 65, FALSE)
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
			hit(victim, final_cast ? HERETIC_SAND_FINAL_DAMAGE : HERETIC_SAND_BURIAL_DAMAGE, 15)
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
	var/created_at
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
	created_at = world.time
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
	icon = 'modular_bluemoon/icons/obj/heretic_sand.dmi'
	icon_state = "sand_hourglass"

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
	sand.anchor = src
	expires_at = world.time + HERETIC_SAND_ANCHOR_TIME
	expiry_timer = addtimer(CALLBACK(src, PROC_REF(expire)), HERETIC_SAND_ANCHOR_TIME, TIMER_STOPPABLE)

/obj/structure/heretic_sand_anchor/proc/expire()
	qdel(src)

/obj/structure/heretic_sand_anchor/attackby(obj/item/item, mob/living/user)
	if(istype(item, /obj/item/nullrod))
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
	desc = "Песочные часы, которые удобно держать в ладони. Первое применение оставляет на пять секунд разрушаемую точку возврата; повторное возвращает к ней через открытую линию не длиннее пяти клеток. Раны и эффекты сохраняются. Перезарядка — 20 секунд с установки. Щелчок реликвией по своим боевым часам в пяти клетках за единицу песка однократно продлевает отсчёт на 1,5 секунды."
	icon = 'modular_bluemoon/icons/obj/heretic_sand.dmi'
	icon_state = "sand_relic"
	item_state = "sand_relic"
	lefthand_file = 'modular_bluemoon/icons/obj/heretic_relics_sand_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/obj/heretic_relics_sand_righthand.dmi'

/obj/item/heretic_path_relic/sand_relic/attack_self(mob/living/user)
	return turn_hourglass(user)

/obj/item/heretic_path_relic/sand_relic/afterattack(atom/target, mob/living/user, proximity_flag, click_parameters)
	if(istype(target, /obj/structure/heretic_sand_hourglass))
		return delay_hourglass(user, target)
	return ..()

/obj/item/heretic_path_relic/sand_relic/proc/delay_hourglass(mob/living/user, obj/structure/heretic_sand_hourglass/hourglass)
	if(!authorized(user) || QDELETED(hourglass))
		return FALSE
	return hourglass.delay_impact(user)

/obj/item/heretic_path_relic/sand_relic/proc/turn_hourglass(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_sand/sand = heretic?.get_knowledge(/datum/eldritch_knowledge/base_sand)
	if(!authorized(user) || !sand?.can_use(user))
		return FALSE
	if(sand.anchor)
		var/turf/destination = get_turf(sand.anchor)
		if(world.time >= sand.anchor.expires_at || user.buckled || user.anchored || HAS_TRAIT(user, TRAIT_NO_TELEPORT) || !sand.line_clear(user, destination) || destination.is_blocked_turf())
			return FALSE
		if(!do_teleport(user, destination, channel = TELEPORT_CHANNEL_MAGIC) || get_turf(user) != destination)
			return FALSE
		if(!sand.can_use(user) || !authorized(user))
			return TRUE
		QDEL_NULL(sand.anchor)
	else
		if(!COOLDOWN_FINISHED(src, relic_cooldown) || !sand.tile_open(get_turf(user)))
			return FALSE
		new /obj/structure/heretic_sand_anchor(get_turf(user), sand)
		COOLDOWN_START(src, relic_cooldown, 20 SECONDS)
	new /obj/effect/temp_visual/heretic_sand/cast(get_turf(user))
	playsound(user, 'modular_bluemoon/sound/heretic/sand_cast.ogg', 50, FALSE)
	return TRUE

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

/datum/heretic_deed/sand
	next_step = "Коснитесь Хваткой Мансуса торгового автомата в ещё не зачтённом отделе."
	name = "Просроченное время"
	desc = "Коснитесь Хваткой Мансуса торговых автоматов в разных отделах. Их содержимое на миг стареет на тысячу лет, оставляя песок у основания. Каждый отдел засчитывается один раз."
	hint = "Автомат продолжит работать. Песок выдаст, что вы здесь были."
	trace_name = "sand of the spent hour"
	trace_desc = "Мелкий золотой песок пахнет давно забытым складом."
	trace_state = "sigil_sand"

/datum/eldritch_knowledge/base_sand/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(!proximity_flag || !can_use(user) || !istype(target, /obj/machinery/vending) || !isturf(target.loc) || !user.Adjacent(target))
		return FALSE
	if(!heretic.advance_deed(heretic.deed_key_for(target), get_turf(target)))
		return FALSE
	target.visible_message(span_warning("Из щелей [target] высыпается золотистый песок."))
	new /obj/effect/temp_visual/heretic_sand/cast(get_turf(target))
	playsound(target, 'modular_bluemoon/sound/heretic/sand_grasp.ogg', 45, FALSE)
	return TRUE

/datum/eldritch_knowledge/sand_grasp
	name = "Сухая ладонь"
	desc = "Хватка дополнительно наносит 15 урона выносливости и даёт две единицы песка раз в 6 секунд. Антимагия и союзники не дают ресурса."
	gain_text = "В ладони остался песок. Собеседник забыл, какое слово собирался сказать."
	cost = 1
	route = PATH_SAND

/datum/eldritch_knowledge/sand_grasp/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_sand/sand = heretic?.get_knowledge(/datum/eldritch_knowledge/base_sand)
	if(!proximity_flag || !sand?.can_use(user) || !isturf(target?.loc) || !heretic_can_affect(user, target, chargecost = 0))
		return FALSE
	var/mob/living/victim = target
	victim.adjustStaminaLoss(15)
	if(COOLDOWN_FINISHED(sand, grasp_harvest))
		sand.gain_combat_resource(2)
		COOLDOWN_START(sand, grasp_harvest, HERETIC_SAND_HARVEST)
	return TRUE

/datum/eldritch_knowledge/spell/sand_wind
	name = "Сквозняк"
	desc = "Прорежьте открытую линию длиной до пяти клеток: 28 ушибов и 15 урона выносливости сразу. Часы появляются на выбранной конечной клетке и запоминают только одного врага, поражённого именно на ней; цели по пути не запоминаются. Через 1,5 секунды часы вернут его на свою клетку и взорвутся. Возврат работает в трёх клетках от часов без преград; часы можно разбить. Не требует песка, перезарядка — 12 секунд."
	gain_text = "Щель между мгновениями оказалась достаточно широкой для ножа."
	cost = 1
	route = PATH_SAND
	spell_to_add = /obj/effect/proc_holder/spell/pointed/heretic_sand/wind

/datum/eldritch_knowledge/spell/sand_wind/on_body_lose(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_sand/sand = heretic?.get_knowledge(/datum/eldritch_knowledge/base_sand)
	sand?.clear_knowledge(src)
	return ..()

/datum/eldritch_knowledge/sand_mark
	name = "Метка Песка"
	desc = "Хватка оставляет метку на 15 секунд. Удар клинком возвращает единицу песка, наносит 20 урона выносливости и ставит часы, запоминающие позицию цели. Через 1,5 секунды часы возвращают её на эту клетку и взрываются. От возврата спасают разрушение часов, отход дальше трёх клеток, преграды и защита от магии или телепортации."
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
	desc = "Стекло и лист золота создают карманные часы. Примените их в руке, чтобы на пять секунд оставить точку возврата с 25 прочности. Повторное применение возвращает к ней через открытую линию до пяти клеток. Здоровье не меняется, преграды и запрет телепортации блокируют возврат. Перезарядка — 20 секунд с установки. Щёлкните реликвией по своим боевым часам в пяти клетках: за единицу песка их отсчёт однократно продлится на 1,5 секунды, до трёх секунд от создания. Сохранённая цель и прочность не меняются. Можно иметь одну реликвию."
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

/datum/eldritch_knowledge/sand_upgrade
	name = "Оборванный срок"
	desc = "Клинок наносит ещё 8 ушибов и обрывает отсчёт одних ваших часов, если они существуют хотя бы 0,6 секунды. Подходят часы под врагом или запомнившие его позицию: удар может вернуть врага назад и сразу взорвать ловушку. Общий предел урона часов сохраняется."
	gain_text = "Я перестал ждать последнюю песчинку."
	cost = 2
	route = PATH_SAND

/datum/eldritch_knowledge/sand_upgrade/on_eldritch_blade(atom/target, mob/user, proximity_flag, click_parameters)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_sand/sand = heretic?.get_knowledge(/datum/eldritch_knowledge/base_sand)
	if(!proximity_flag || !sand?.can_use(user) || !isturf(target?.loc) || !heretic_can_affect(user, target, chargecost = 0))
		return
	var/mob/living/victim = target
	victim.adjustBruteLoss(8)
	for(var/obj/structure/heretic_sand_hourglass/hourglass as anything in sand.hourglasses)
		if((get_turf(hourglass) == get_turf(victim) || hourglass.recorded_second?.owner == victim) && world.time >= hourglass.created_at + HERETIC_SAND_BLADE_DELAY)
			hourglass.resolve()
			break

/datum/eldritch_knowledge/spell/sand_step
	name = "Пересыпание"
	desc = "За единицу песка переместитесь на свободную клетку в четырёх клетках по открытой линии, оставив часы на прежнем месте. Не проходит сквозь преграды и запрет телепортации. Перезарядка — 12 секунд."
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
	desc = "Предел песка возрастает до 5, задержка получения песка клинком и заклинаниями сокращается до 5 секунд. Улучшения дают вместимость 6 и 7 и задержку 4 и 3 секунды."
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
	desc = "За две единицы песка выбранная область 3×3 сразу получает 28 ушибов и 15 урона выносливости. На поле 5×5 появляются 13 часов в шахматном порядке, включая выбранную клетку. Каждые часы запоминают одного врага на своей клетке и через 1,5 секунды возвращают его перед взрывом. Между часами есть проходы; от возврата спасают отход дальше трёх клеток, преграды или разрушение часов. Если вместе с уже стоящими часами получится больше 13, самые старые часы вне поля исчезают. Перезарядка — 35 секунд."
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
	desc = "После трёх назначенных душ принесите три человеческих трупа. Обряд раскрывает место станции и длится 30 секунд. Вы получаете общую стойкость вознесения. Предел песка - 8, единица восстанавливается каждые 4 секунды. Замедленное время: вражеские пули и заряды в радиусе четырёх клеток от вас летят втрое медленнее, мгновенные лучи, ближний бой и брошенные предметы не замедляются. Внутри шкафа или меха поле не действует. Последний полдень бесплатно создаёт Погребение: первый удар - 40 ушибов, часы - 44. Перезарядка 30 секунд."
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

/obj/effect/proc_holder/spell/pointed/heretic_sand/wind
	name = "Сквозняк"
	desc = "Бесплатный удар по линии до пяти клеток: 28 ушибов и 15 выносливости. Часы запоминают одного поражённого врага только на выбранной конечной клетке. Через 1,5 секунды возвращают его перед взрывом, если он остался в трёх клетках от часов без преград."
	charge_max = 12 SECONDS
	action_icon_state = "sand_wind"

/obj/effect/proc_holder/spell/pointed/heretic_sand/wind/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_sand/sand = heretic?.get_knowledge(/datum/eldritch_knowledge/base_sand)
	if(!length(targets) || !sand?.wind(user, get_turf(targets[1])))
		heretic_revert_cast(user)

/obj/effect/proc_holder/spell/pointed/heretic_sand/step
	name = "Пересыпание"
	desc = "За единицу песка переместитесь на свободную клетку в четырёх клетках по открытой линии. На прежнем месте остаются часы."
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
	desc = "За две единицы песка нанесите 28 ушибов и 15 выносливости в области 3×3. Тринадцать часов на поле 5×5 запомнят стоящих на них врагов и вернут перед взрывом через 1,5 секунды. Возврат действует в трёх клетках от часов без преград. Лишние старые часы вне поля исчезают, освобождая место."
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
#undef HERETIC_SAND_BLADE_DELAY
#undef HERETIC_SAND_STEP_RANGE
#undef HERETIC_SAND_RELEASE_DAMAGE
#undef HERETIC_SAND_RELEASE_STAMINA
#undef HERETIC_SAND_WIND_DAMAGE
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
