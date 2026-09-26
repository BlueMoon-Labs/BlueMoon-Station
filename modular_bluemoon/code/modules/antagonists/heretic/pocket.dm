#define HERETIC_POCKET_CENTER_OFFSET ((HERETIC_POCKET_SIZE - 1) / 2)
#define HERETIC_POCKET_FLOOR_RADIUS (HERETIC_POCKET_CENTER_OFFSET - 1)
#define HERETIC_POCKET_ENTRY_EXIT "Туда, откуда пришли"
#define HERETIC_POCKET_ORIGIN_EXIT "Туда, где вы стояли"

GLOBAL_LIST_EMPTY(heretic_pockets)
GLOBAL_LIST_EMPTY(heretic_runes)

/area/heretic_pocket
	name = "Mansus: Underside"
	requires_power = FALSE
	has_gravity = STANDARD_GRAVITY
	dynamic_lighting = DYNAMIC_LIGHTING_DISABLED
	area_flags = UNIQUE_AREA | NOTELEPORT | RADIO_BLACKOUT

/turf/open/indestructible/heretic_pocket
	icon = 'modular_bluemoon/icons/obj/heretic_mansus.dmi'
	icon_state = "ash_floor0"
	name = "underside floor"
	desc = "Пол по ту сторону завесы. Шаги здесь не слышны никому снаружи."
	flags_1 = CAN_BE_DIRTY_1 | NOJAUNT_1
	initial_gas_mix = OPENTURF_DEFAULT_ATMOS
	baseturfs = /turf/open/indestructible/heretic_pocket

/turf/closed/indestructible/heretic_pocket
	icon = 'modular_bluemoon/icons/obj/heretic_mansus.dmi'
	icon_state = "ash_wall0"
	name = "underside wall"
	desc = "Изнанка станции. За стеной нет ничего, даже темноты."
	flags_1 = CAN_BE_DIRTY_1 | NOJAUNT_1
	baseturfs = /turf/closed/indestructible/heretic_pocket

/// Карманная комната еретика: резервирование живёт до снятия роли, вход и выход - на станции.
/datum/heretic_pocket
	var/datum/antagonist/heretic/owner
	var/datum/turf_reservation/reservation
	var/turf/center
	var/turf/entry_turf
	/// Где еретик стоял перед входом: у дверей издалека это не клетка цели.
	var/turf/origin_turf
	/// Ближе этого к входу на том же уровне выход при силовом закрытии считается местом, где уже ждут.
	var/escape_distance = HERETIC_POCKET_ESCAPE_DISTANCE
	var/obj/effect/heretic_pocket_rift/rift
	var/obj/effect/heretic_pocket_rift/inner/inner_rift
	var/mob/living/heretic
	var/mob/living/victim
	var/datum/action/innate/heretic_pocket_leave/leave_action
	var/active = FALSE
	var/closes_at = 0
	var/collapse_timer
	var/warning_timer
	var/datum/status_effect/incapacitating/paralyzed/heretic_ritual/entry_hold
	var/entry_hold_timer
	var/entry_holding = FALSE
	COOLDOWN_DECLARE(reopen_cooldown)

/datum/heretic_pocket/New(datum/antagonist/heretic/new_owner)
	. = ..()
	owner = new_owner
	GLOB.heretic_pockets += src

/datum/heretic_pocket/Destroy()
	collapse("роль еретика снята")
	GLOB.heretic_pockets -= src
	release()
	owner = null
	return ..()

/// Резервирует комнату при первом входе; RequestBlockReservation может уступить тик.
/datum/heretic_pocket/proc/prepare()
	if(reservation)
		return TRUE
	var/datum/turf_reservation/new_reservation = SSmapping.RequestBlockReservation(HERETIC_POCKET_SIZE, HERETIC_POCKET_SIZE)
	if(QDELETED(src) || QDELETED(new_reservation) || reservation)
		qdel(new_reservation)
		return !QDELETED(src) && !isnull(reservation)
	reservation = new_reservation
	RegisterSignal(reservation, COMSIG_PARENT_QDELETING, PROC_REF(on_reservation_deleted))
	var/area/heretic_pocket/room = GLOB.areas_by_type[/area/heretic_pocket] || new /area/heretic_pocket
	var/left = reservation.bottom_left_coords[1]
	var/bottom = reservation.bottom_left_coords[2]
	var/right = reservation.top_right_coords[1]
	var/top = reservation.top_right_coords[2]
	for(var/turf/reserved as anything in reservation.reserved_turfs)
		room.contents += reserved
		var/edge = reserved.x == left || reserved.x == right || reserved.y == bottom || reserved.y == top
		reserved.ChangeTurf(edge ? /turf/closed/indestructible/heretic_pocket : /turf/open/indestructible/heretic_pocket)
	center = locate(left + HERETIC_POCKET_CENTER_OFFSET, bottom + HERETIC_POCKET_CENTER_OFFSET, reservation.bottom_left_coords[3])
	return TRUE

/// Стены и пол берут стейты Мансуса пути владельца.
/datum/heretic_pocket/proc/style()
	var/list/theme = GLOB.heretic_mansus_themes[owner?.selected_path] || GLOB.heretic_mansus_themes[PATH_ASH]
	var/theme_id = theme["id"]
	for(var/turf/tile as anything in reservation.reserved_turfs)
		if(istype(tile, /turf/open/indestructible/heretic_pocket))
			tile.icon_state = "[theme_id]_floor[pick(0, 0, 0, 1, 2)]"
			continue
		var/edge_mask = NONE
		for(var/direction in GLOB.cardinals)
			if(istype(get_step(tile, direction), /turf/open/indestructible/heretic_pocket))
				edge_mask |= direction
		tile.icon_state = "[theme_id]_wall[edge_mask]"

/datum/heretic_pocket/proc/contains(atom/thing)
	var/turf/spot = get_turf(thing)
	return !isnull(spot) && !isnull(reservation) && (spot in reservation.reserved_turfs)

/datum/heretic_pocket/proc/enter(mob/living/user, mob/living/target, turf/entry, hold_on_entry = TRUE, duration = HERETIC_POCKET_DURATION, intro = TRUE)
	if(active || !reservation)
		return FALSE
	active = TRUE
	heretic = user
	victim = target
	entry_turf = entry
	origin_turf = get_turf(user)
	reset_room()
	for(var/mob/living/traveller as anything in list(target, user))
		traveller.pulledby?.stop_pulling()
		traveller.stop_pulling()
		traveller.buckled?.unbuckle_mob(traveller, TRUE)
		traveller.unbuckle_all_mobs(TRUE)
	heretic_pocket_vanish_fx(list(target, user), entry, owner?.selected_path)
	target.forceMove(center)
	user.forceMove(get_step(center, WEST))
	if(hold_on_entry)
		entry_hold = new(list(target, -1, TRUE))
		entry_holding = TRUE
		heretic_capture_hold(target, HERETIC_POCKET_CAPTURE)
		RegisterSignal(entry_hold, COMSIG_PARENT_QDELETING, PROC_REF(on_entry_hold_deleted))
		RegisterSignal(target, COMSIG_LIVING_HERETIC_SACRIFICE_STARTING, PROC_REF(on_victim_sacrifice))
		entry_hold_timer = addtimer(CALLBACK(src, PROC_REF(end_entry_hold)), HERETIC_POCKET_ENTRY_HOLD, TIMER_STOPPABLE)
	rift = new(entry, src)
	inner_rift = new(locate(center.x, center.y + HERETIC_POCKET_FLOOR_RADIUS, center.z), src)
	RegisterSignal(user, COMSIG_MOB_STATCHANGE, PROC_REF(on_heretic_stat))
	RegisterSignal(user, COMSIG_PARENT_QDELETING, PROC_REF(on_heretic_deleted))
	RegisterSignal(target, COMSIG_PARENT_QDELETING, PROC_REF(on_victim_deleted))
	restart_timer(duration)
	leave_action = new(src)
	leave_action.Grant(user)
	if(intro)
		to_chat(user, span_notice("Вы в изнанке. Она продержится [duration / (1 SECONDS)] с, за [HERETIC_POCKET_WARNING / (1 SECONDS)] с до конца придёт предупреждение. [hold_on_entry ? "Первые [HERETIC_POCKET_ENTRY_HOLD / (1 SECONDS)] с цель не сможет двинуться: начинайте обряд сердцем. " : ""]«Покинуть изнанку» выведет вас ко входу, своей руне или ремеслу пути. Снаружи остался разрыв: экипаж может закрыть его жезлом или разорвать руками. Если разрыв закроют или время выйдет, вас вынесет к одному из ваших выходов подальше от входа, а цель выпадет у входа."))
		to_chat(target, span_userdanger("Вас утянуло в изнанку, тесную комнату по ту сторону завесы. У стены дрожит разрыв: если вас не держат, разорвите его руками за [HERETIC_POCKET_TEAR_TIME / (1 SECONDS)] с. Через [duration / (1 SECONDS)] с изнанка схлопнется сама.[hold_on_entry ? " Первые [HERETIC_POCKET_ENTRY_HOLD / (1 SECONDS)] с переход держит вас на месте." : ""]"))
	log_game("[key_name(user)] уводит [key_name(target)] в изнанку; разрыв открыт в [AREACOORD(entry)].")
	return TRUE

/// Изнанка закроется через duration от этого момента; shown - срок, который видят игроки, если изнанку раньше закроет своё событие.
/datum/heretic_pocket/proc/restart_timer(duration, shown = duration)
	if(!active)
		return FALSE
	deltimer(collapse_timer)
	deltimer(warning_timer)
	closes_at = world.time + shown
	collapse_timer = addtimer(CALLBACK(src, PROC_REF(on_timeout)), duration, TIMER_STOPPABLE)
	warning_timer = addtimer(CALLBACK(src, PROC_REF(warn)), duration - HERETIC_POCKET_WARNING, TIMER_STOPPABLE)
	return TRUE

/// Всех живых и вещи с пола - на вход, разрыв убирается, изнанка затягивается; heretic_escapes уводит еретика к своему выходу (escape_turf), culprit - кто закрыл разрыв.
/datum/heretic_pocket/proc/collapse(reason, heretic_escapes = FALSE, mob/living/culprit)
	if(!active)
		return FALSE
	active = FALSE
	SEND_SIGNAL(src, COMSIG_HERETIC_POCKET_COLLAPSING, reason, culprit)
	deltimer(collapse_timer)
	deltimer(warning_timer)
	collapse_timer = null
	warning_timer = null
	closes_at = 0
	end_entry_hold()
	QDEL_NULL(leave_action)
	var/turf/exit = exit_turf()
	var/turf/escape = heretic_escapes ? escape_turf() : null
	var/victim_inside = contains(victim)
	if(escape && contains(heretic))
		var/atom/movable/carrier = get_atom_on_turf(heretic)
		carrier.forceMove(escape)
		escape.visible_message(span_warning("Воздух расходится, и из ниоткуда выступает [heretic]."))
		heretic_pocket_exit_fx(heretic, escape, owner?.selected_path)
	for(var/mob/living/participant in list(heretic, victim))
		var/turf/spot = get_turf(participant)
		if(spot && !contains(spot) && SSmapping.level_trait(spot.z, ZTRAIT_RESERVED) && !SSmapping.used_turfs[spot])
			var/atom/movable/holder = get_atom_on_turf(participant)
			holder.forceMove(exit)
	var/stashed = FALSE
	for(var/turf/tile as anything in reservation?.reserved_turfs)
		for(var/obj/effect/eldritch/rune in tile)
			if(rune.is_in_use)
				rune.ritual_interrupt_reason ||= "Изнанка схлопнулась."
				rune.ritual_interrupted = TRUE
				rune.release_atoms()
	for(var/turf/tile as anything in reservation?.reserved_turfs)
		for(var/atom/movable/thing as anything in tile.contents.Copy())
			if(QDELETED(thing))
				continue
			if(owner?.stash_behind_veil(thing))
				stashed = TRUE
				continue
			if(escape && istype(thing, /obj/item/melee/sickly_blade))
				thing.forceMove(escape)
				continue
			if(isliving(thing) || (isobj(thing) && (!iseffect(thing) || length(thing.contents))))
				thing.forceMove(exit)
	QDEL_NULL(rift)
	QDEL_NULL(inner_rift)
	COOLDOWN_START(src, reopen_cooldown, HERETIC_POCKET_COOLDOWN)
	heretic_pocket_collapse_fx(exit)
	if(victim_inside)
		heretic_pocket_drop_fx(exit, owner?.selected_path)
	if(heretic)
		UnregisterSignal(heretic, list(COMSIG_MOB_STATCHANGE, COMSIG_PARENT_QDELETING))
		to_chat(heretic, span_warning("Изнанка схлопнулась ([reason])[escape ? ", и вас вынесло к своему выходу: [get_area_name(escape, TRUE)]" : ""]. Снова открыть её можно через [HERETIC_POCKET_COOLDOWN / (1 SECONDS)] с.[stashed ? " Ваше сердце или кодекс с пола ушли за завесу: призовите их." : ""]"))
	if(victim)
		UnregisterSignal(victim, COMSIG_PARENT_QDELETING)
		heretic_capture_release(victim, HERETIC_POCKET_CAPTURE)
		if(victim_inside)
			to_chat(victim, span_notice("Изнанка схлопывается, и вас выбрасывает обратно."))
	log_game("Изнанка [key_name(owner?.owner)] закрыта у [AREACOORD(exit)]: [reason].[escape ? " Еретик вынесен к [AREACOORD(escape)]." : ""]")
	heretic = null
	victim = null
	entry_turf = null
	origin_turf = null
	return TRUE

/datum/heretic_pocket/proc/exit_turf()
	if(heretic_pocket_landable(entry_turf))
		return entry_turf
	if(entry_turf)
		var/area/entry_area = get_area(entry_turf)
		for(var/direction in GLOB.alldirs)
			var/turf/nearby = get_step(entry_turf, direction)
			if(!is_safe_turf(nearby) || !entry_turf.Adjacent(nearby))
				continue
			if(get_area(nearby) == entry_area || heretic_pocket_exit_allowed(nearby))
				return nearby
	return owner?.get_hunt_return_turf() || entry_turf || get_turf(GET_ERROR_ROOM)

/// Свой выход подальше от входа: ближайший из тех, что на уровне входа не ближе escape_distance, иначе выход на другом уровне, иначе самый дальний из близких.
/datum/heretic_pocket/proc/escape_turf()
	if(!heretic || heretic.stat >= SOFT_CRIT || !entry_turf || !owner)
		return null
	var/list/exits = owner.pocket_exits(heretic)
	var/turf/drop = exit_turf()
	var/turf/far
	var/turf/elsewhere
	var/turf/close
	for(var/label in exits)
		if(label == HERETIC_POCKET_ENTRY_EXIT)
			continue
		var/turf/landing = heretic_pocket_landing(exits[label])
		if(!landing || landing == drop)
			continue
		if(landing.z != entry_turf.z)
			elsewhere ||= landing
			continue
		var/distance = get_dist(landing, entry_turf)
		if(distance <= 1)
			continue
		if(distance >= escape_distance)
			if(!far || distance < get_dist(far, entry_turf))
				far = landing
		else if(!close || distance > get_dist(close, entry_turf))
			close = landing
	return far || elsewhere || close

/datum/heretic_pocket/proc/leave(mob/living/user, turf/exit)
	if(!active || user != heretic || !contains(user))
		return FALSE
	var/turf/landing = heretic_pocket_exit_allowed(exit) ? heretic_pocket_landing(exit) : null
	if(!landing)
		to_chat(user, span_warning("Этот выход закрыт: он вне станции, там запрещены телепорты или всё вокруг загорожено."))
		return FALSE
	user.forceMove(landing)
	heretic_pocket_exit_fx(user, landing, owner?.selected_path)
	landing.visible_message(span_warning("Воздух расходится, и из ниоткуда выступает [user]."))
	log_game("[key_name(user)] покидает изнанку к [AREACOORD(landing)].")
	collapse("еретик вышел")
	return TRUE

/datum/heretic_pocket/proc/release()
	if(!reservation)
		return
	UnregisterSignal(reservation, COMSIG_PARENT_QDELETING)
	clear_effects()
	qdel(reservation)
	reservation = null
	center = null

/// Прошлый вход не оставляет в комнате газа, огня, крови и рун.
/datum/heretic_pocket/proc/reset_room()
	clear_effects()
	for(var/turf/open/floor in reservation.reserved_turfs)
		floor.air?.copy_from_turf(floor)
		floor.air_update_turf()
	style()

/datum/heretic_pocket/proc/clear_effects()
	for(var/turf/tile as anything in reservation.reserved_turfs)
		for(var/atom/movable/leftover as anything in tile.contents.Copy())
			if(iseffect(leftover) && !length(leftover.contents))
				qdel(leftover)

/// Удержание переносит захват сквозь завесу: паралич без срока снимает свой таймер, а не «Помощь».
/datum/heretic_pocket/proc/end_entry_hold()
	deltimer(entry_hold_timer)
	entry_hold_timer = null
	if(entry_hold)
		UnregisterSignal(entry_hold, COMSIG_PARENT_QDELETING)
		QDEL_NULL(entry_hold)
	if(entry_holding)
		entry_holding = FALSE
		if(victim)
			UnregisterSignal(victim, COMSIG_LIVING_HERETIC_SACRIFICE_STARTING)
		heretic_capture_unhold(victim, HERETIC_POCKET_CAPTURE)

/// Удержание снимают и снаружи: лечение до конца или SetParalyzed(0).
/datum/heretic_pocket/proc/on_entry_hold_deleted(datum/source)
	SIGNAL_HANDLER
	entry_hold = null
	end_entry_hold()

/datum/heretic_pocket/proc/on_victim_sacrifice(datum/source)
	SIGNAL_HANDLER
	end_entry_hold()

/datum/heretic_pocket/proc/warn()
	warning_timer = null
	heretic_pocket_warning_fx(src)
	if(!active || !heretic)
		return
	to_chat(heretic, span_boldwarning("Изнанка истончается: через [HERETIC_POCKET_WARNING / (1 SECONDS)] с она схлопнется. Цель и вещи выпадут у входа, а вас вынесет к одному из ваших выходов подальше от входа."))
	heretic.balloon_alert(heretic, "изнанка истончается")

/datum/heretic_pocket/proc/on_timeout()
	collapse_timer = null
	collapse("время вышло", heretic_escapes = TRUE)

/datum/heretic_pocket/proc/on_heretic_stat(mob/living/source, new_stat, old_stat)
	SIGNAL_HANDLER
	if(new_stat >= SOFT_CRIT)
		collapse("еретик без сознания")

/datum/heretic_pocket/proc/on_heretic_deleted(datum/source)
	SIGNAL_HANDLER
	collapse("еретик исчез")

/datum/heretic_pocket/proc/on_victim_deleted(datum/source)
	SIGNAL_HANDLER
	UnregisterSignal(victim, list(COMSIG_PARENT_QDELETING, COMSIG_LIVING_HERETIC_SACRIFICE_STARTING))
	victim = null

/datum/heretic_pocket/proc/on_reservation_deleted(datum/source)
	SIGNAL_HANDLER
	collapse("комнату снесло")
	UnregisterSignal(reservation, COMSIG_PARENT_QDELETING)
	reservation = null
	center = null

/proc/heretic_pocket_landable(turf/spot)
	return isopenturf(spot) && !isgroundlessturf(spot) && !spot.is_blocked_turf(exclude_mobs = TRUE)

/proc/heretic_pocket_exit_allowed(turf/spot)
	var/area/spot_area = get_area(spot)
	// Учебная арена изолирована от станции: там изнанка нужна, чтобы двери путей можно было попробовать.
	if(istype(spot_area, /area/antag_training))
		return TRUE
	return !isnull(spot) && is_station_level(spot.z) && spot_area && !(spot_area.area_flags & NOTELEPORT)

/// Клетка выхода или соседний свободный пол: окно или стол ремесла загораживают свою клетку.
/proc/heretic_pocket_landing(turf/spot)
	if(heretic_pocket_landable(spot))
		return spot
	for(var/direction in GLOB.alldirs)
		var/turf/nearby = get_step(spot, direction)
		if(heretic_pocket_landable(nearby) && heretic_pocket_exit_allowed(nearby))
			return nearby
	return null

/// Свободный пол рядом с телом или копией-выходом, а не под ними; без такого пола - обычная посадка у их клетки.
/proc/heretic_pocket_beside(atom/thing)
	var/turf/spot = get_turf(thing)
	if(!spot)
		return null
	for(var/direction in GLOB.alldirs)
		var/turf/nearby = get_step(spot, direction)
		if(heretic_pocket_landable(nearby) && heretic_pocket_exit_allowed(nearby) && spot.Adjacent(nearby) && !(locate(/mob/living) in nearby))
			return nearby
	return heretic_pocket_landing(spot)

/// Для охоты и Мансуса клетка изнанки считается клеткой её входа на станции.
/proc/heretic_pocket_anchor(turf/spot)
	if(!istype(spot?.loc, /area/heretic_pocket))
		return spot
	for(var/datum/heretic_pocket/pocket as anything in GLOB.heretic_pockets)
		if(pocket.entry_turf && pocket.contains(spot))
			return pocket.entry_turf
	return spot

/// В клетках вокруг цели нет другого человека в сознании, кроме самой цели и еретика.
/proc/heretic_pocket_alone(mob/living/victim, mob/living/user, range)
	for(var/mob/living/carbon/human/witness in range(range, victim))
		if(witness != victim && witness != user && witness.stat < UNCONSCIOUS)
			return FALSE
	return TRUE

/proc/heretic_add_pocket_exit(list/exits, label, turf/spot)
	if(!heretic_pocket_exit_allowed(spot))
		return
	exits[heretic_unique_label(exits, label)] = spot

/// Подпись без повторов для списка выбора: вторая такая же получает номер.
/proc/heretic_unique_label(list/choices, label)
	. = label
	var/index = 1
	while(choices[.])
		index++
		. = "[label] ([index])"

/obj/effect/heretic_pocket_rift
	name = "torn air"
	desc = "Воздух здесь надорван, будто кто-то шагнул в никуда. Нулевой жезл или Библия закроют разрыв, руками его можно разорвать."
	icon = 'modular_bluemoon/icons/obj/heretic_pocket_rift.dmi'
	icon_state = "rift"
	anchored = TRUE
	layer = BELOW_MOB_LAYER
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	var/datum/heretic_pocket/pocket
	var/tear_time = HERETIC_POCKET_TEAR_TIME
	/// Стейт покоя; раскрытие - тот же с суффиксом _open.
	var/rift_state = "rift"
	var/tear_crackle_timer

/obj/effect/heretic_pocket_rift/Initialize(mapload, datum/heretic_pocket/new_pocket)
	. = ..()
	pocket = new_pocket
	heretic_pocket_rift_open_fx(src, pocket?.owner?.selected_path)

/obj/effect/heretic_pocket_rift/Destroy()
	heretic_pocket_rift_close_fx(src, pocket?.owner?.selected_path)
	pocket = null
	return ..()

/obj/effect/heretic_pocket_rift/examine(mob/user)
	. = ..()
	if(pocket?.active && user.mind && user.mind == pocket.owner?.owner)
		. += span_notice("Ваш разрыв: изнанка закроется через [heretic_capture_seconds_left(pocket.closes_at)] с.")

/obj/effect/heretic_pocket_rift/attackby(obj/item/item, mob/living/user, params)
	if(!istype(item, /obj/item/nullrod) && !istype(item, /obj/item/storage/book/bible))
		return ..()
	user.visible_message(span_warning("[user] касается разрыва [item], и края воздуха срастаются."), span_notice("Вы касаетесь разрыва [item], и он затягивается."))
	heretic_pocket_breach_fx(src, holy = TRUE)
	log_game("[key_name(user)] закрывает разрыв изнанки [item] в [AREACOORD(src)].")
	pocket?.collapse("разрыв закрыт святым оружием", heretic_escapes = TRUE, culprit = user)
	return STOP_ATTACK_PROC_CHAIN

/obj/effect/heretic_pocket_rift/on_attack_hand(mob/user, act_intent, unarmed_attack_flags)
	tear(user)

/obj/effect/heretic_pocket_rift/attack_robot(mob/user)
	if(!user.Adjacent(src))
		return ..()
	INVOKE_ASYNC(src, PROC_REF(tear), user)

/obj/effect/heretic_pocket_rift/attack_animal(mob/user)
	. = ..()
	if(user.client)
		INVOKE_ASYNC(src, PROC_REF(tear), user)

/obj/effect/heretic_pocket_rift/proc/tear(mob/living/user)
	if(!pocket?.active || !isliving(user) || IS_HERETIC(user) || IS_HERETIC_MONSTER(user) || !user.Adjacent(src))
		return FALSE
	if(user.pulledby)
		to_chat(user, span_warning("Вас держат: сначала вырвитесь из хватки."))
		return FALSE
	if(user.incapacitated())
		to_chat(user, span_warning("Скованными или обессиленными руками разрыв не разорвать."))
		return FALSE
	user.visible_message(span_warning("[user] вцепляется в надорванный воздух и тянет края в стороны!"), span_notice("Вы тянете края разрыва в стороны. Не отходите [DisplayTimeText(tear_time)]."))
	if(pocket.heretic)
		to_chat(pocket.heretic, span_boldwarning("Кто-то рвёт разрыв изнанки!"))
	heretic_pocket_tear_fx(src, tear_time)
	if(!do_after(user, tear_time, src) || QDELETED(src) || !pocket?.active || user.pulledby)
		if(!QDELETED(src) && pocket?.active)
			heretic_pocket_tear_stop_fx(src)
			to_chat(user, span_warning("Вы выпускаете края разрыва, и он снова стягивается."))
		return FALSE
	user.visible_message(span_warning("[user] разрывает надорванный воздух, и изнанка выворачивается наружу!"))
	heretic_pocket_breach_fx(src)
	log_game("[key_name(user)] разрывает разрыв изнанки руками в [AREACOORD(src)].")
	pocket.collapse("разрыв порвали руками", heretic_escapes = TRUE, culprit = user)
	return TRUE

/obj/effect/heretic_pocket_rift/inner
	name = "tear in the wall"
	desc = "Сквозь надрыв в стене проглядывает станция."
	icon_state = "rift_inner"
	rift_state = "rift_inner"

/obj/effect/heretic_pocket_rift/inner/examine(mob/user)
	. = ..()
	if(!pocket?.active || IS_HERETIC(user))
		return
	. += span_notice("Это выход из изнанки. Если вас не держат и на руках нет наручников, разрыв можно разорвать руками за [DisplayTimeText(tear_time)]. Нулевой жезл или Библия закроют его сразу. Первые [HERETIC_POCKET_ENTRY_HOLD / (1 SECONDS)] с после входа переход может держать вас на месте. Через [heretic_capture_seconds_left(pocket.closes_at)] с изнанка схлопнется сама, и вас выбросит обратно.")

/datum/action/innate/heretic_pocket_leave
	name = "Покинуть изнанку"
	desc = "Выйти ко входу, своей руне или ремеслу пути на станции. Цель, если она ещё внутри, выпадет у входа, и изнанка закроется."
	icon_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	button_icon_state = "pocket_leave"
	background_icon_state = "bg_ecult"
	var/datum/heretic_pocket/pocket

/datum/action/innate/heretic_pocket_leave/New(datum/heretic_pocket/new_pocket)
	. = ..()
	pocket = new_pocket

/datum/action/innate/heretic_pocket_leave/Destroy()
	pocket = null
	return ..()

/datum/action/innate/heretic_pocket_leave/Activate()
	var/datum/heretic_pocket/current = pocket
	var/mob/living/user = owner
	if(!current?.active || user != current.heretic)
		return
	var/list/exits = current.owner?.pocket_exits(user)
	if(!length(exits))
		return
	var/choice = choose_exit(exits)
	if(!choice || QDELETED(src) || QDELETED(user) || pocket != current || !current.active || user != current.heretic)
		return
	var/list/fresh_exits = current.owner?.pocket_exits(user)
	var/turf/exit = length(fresh_exits) ? fresh_exits[choice] : null
	if(!exit)
		to_chat(user, span_warning("Этого выхода больше нет: выберите другой."))
		return
	current.leave(user, exit)

/// Изнанка не живёт дольше своего срока, поэтому и окно выбора не держит действие дольше.
/datum/action/innate/heretic_pocket_leave/proc/choose_exit(list/exits)
	return tgui_input_list(owner, "Куда выйти из изнанки?", "Изнанка", exits, timeout = HERETIC_POCKET_DURATION)

/// Выходы изнанки от ремесла знания: подпись = турф.
/datum/eldritch_knowledge/proc/pocket_exits(mob/living/user)
	SHOULD_NOT_SLEEP(TRUE)
	return null

/// Дверь знания к цели охоты прямо сейчас: list("name", "text", "time", "check"[, "hold", "remote"]) или null; remote - дверь предлагает и сжатое сердце.
/datum/eldritch_knowledge/proc/pocket_door(mob/living/user, mob/living/victim)
	SHOULD_NOT_SLEEP(TRUE)
	return null

/datum/antagonist/heretic
	var/datum/heretic_pocket/pocket
	var/remote_door_prompt_open = FALSE

/datum/antagonist/heretic/proc/pocket_pull_reason(mob/living/user, mob/living/victim, turf/entry, hunt_only = TRUE)
	if(role_removed || QDELETED(user) || user.mind != owner)
		return "Изнанка слушается только своего еретика."
	if(user.stat != CONSCIOUS)
		return "Завеса не поддаётся тому, кто теряет сознание."
	var/containment = heretic_containment_reason(user)
	if(containment)
		return containment
	if(hunt_only && (!hunt_target || victim?.mind != hunt_target))
		return "Изнанка принимает только назначенную цель охоты."
	if(!isturf(victim?.loc))
		return "Завеса не дотянется до [victim]: цель в шкафу, мехе или машине."
	var/capture = heretic_capture_block_reason(user, victim, HERETIC_POCKET_CAPTURE, ignore_shared = TRUE)
	if(capture)
		return capture
	if(pocket?.active)
		return "Изнанка уже открыта: сначала выйдите из неё."
	if(pocket && !COOLDOWN_FINISHED(pocket, reopen_cooldown))
		return "Изнанка ещё затягивается после прошлого раза: осталось [heretic_capture_seconds_left(pocket.reopen_cooldown)] с."
	if(!isturf(entry) || !heretic_pocket_exit_allowed(entry))
		return "Здесь завесу не прорвать: изнанка открывается только на станции и не там, где запрещены телепорты."
	if(!heretic_pocket_exit_allowed(get_turf(user)))
		return "Отсюда в изнанку не уйти: вы вне станции или там, где запрещены телепорты."
	if(!heretic_pocket_exit_allowed(get_turf(victim)))
		return "Завеса не отпустит [victim]: цель вне станции или там, где запрещены телепорты."
	if(HAS_TRAIT(user, TRAIT_NO_TELEPORT))
		return "Что-то держит вас на месте: сквозь завесу не пройти."
	if(HAS_TRAIT(victim, TRAIT_NO_TELEPORT))
		return "Что-то держит [victim] на месте: сквозь завесу не пройти."
	return null

/datum/antagonist/heretic/proc/pocket_pull_check(mob/living/user, mob/living/victim, turf/entry, datum/callback/door_check, hunt_only, silent = FALSE)
	var/reason = pocket_pull_reason(user, victim, entry, hunt_only)
	if(!reason && door_check && !door_check.Invoke())
		reason = "Дверь больше не держит цель."
	if(reason && !silent)
		to_chat(user, span_warning(reason))
	return !reason

/// door_check без аргументов: условие двери проверяется до канала, каждый тик и после него; hold_on_entry держит цель HERETIC_POCKET_ENTRY_HOLD внутри; victim_text - что видит сама цель вместо door_text; duration - срок изнанки; grip прижимает цель на время канала.
/datum/antagonist/heretic/proc/pocket_pull(mob/living/user, mob/living/victim, turf/entry, pull_time = HERETIC_POCKET_PULL_TIME, datum/callback/door_check, door_text, hunt_only = TRUE, hold_on_entry = TRUE, victim_text, duration = HERETIC_POCKET_DURATION, intro = TRUE, grip = TRUE)
	if(!pocket_pull_check(user, victim, entry, door_check, hunt_only))
		return FALSE
	heretic_pocket_pull_fx(user, victim, entry, pull_time, selected_path)
	victim.visible_message(span_danger("[door_text] Воздух вокруг [victim] надрывается!"), span_userdanger("[victim_text || door_text] Воздух вокруг вас надрывается, и вас тянет по ту сторону завесы!"))
	to_chat(user, span_notice("Вы тянете [victim] в изнанку. Не двигайтесь."))
	if(grip && pull_time > 0)
		heretic_door_grip(victim, pull_time * user.cached_multiplicative_actions_slowdown + HERETIC_POCKET_GRIP_MARGIN)
	if(pull_time > 0 && !do_after(user, pull_time, victim, extra_checks = CALLBACK(src, PROC_REF(pocket_pull_check), user, victim, entry, door_check, hunt_only, TRUE)))
		to_chat(user, span_warning("Завеса сомкнулась: вход в изнанку сорван."))
		if(grip)
			victim.remove_status_effect(/datum/status_effect/heretic_door_grip)
		return FALSE
	if(!pocket_pull_check(user, victim, entry, door_check, hunt_only))
		return FALSE
	pocket ||= new /datum/heretic_pocket(src)
	if(!pocket.prepare())
		to_chat(user, span_warning("Изнанка не открылась: для неё не нашлось места."))
		return FALSE
	if(!pocket_pull_check(user, victim, entry, door_check, hunt_only))
		return FALSE
	return pocket.enter(user, victim, entry, hold_on_entry, duration, intro)

/datum/antagonist/heretic/proc/pocket_holds(mob/living/target)
	return pocket?.active && target && pocket.victim == target && pocket.contains(target)

/// Двери изученных знаний к цели: подпись кнопки -> дверь; из самой изнанки дверей нет; remote_only - только двери издалека.
/datum/antagonist/heretic/proc/pocket_doors(mob/living/user, mob/living/victim, remote_only = FALSE)
	. = list()
	if(pocket?.active || victim.stat == DEAD)
		return
	for(var/knowledge_type in researched_knowledge)
		var/datum/eldritch_knowledge/knowledge = researched_knowledge[knowledge_type]
		var/list/door = knowledge.pocket_door(user, victim)
		if(!door || (remote_only && !door["remote"]))
			continue
		.["Увести: [door["name"]]"] = door
		if(length(.) >= HERETIC_POCKET_DOOR_CHOICES)
			return

/// Касание сердцем цели охоты: без дверей обряд идёт на месте, с дверью сердце прижимает цель и спрашивает, где провести обряд.
/datum/antagonist/heretic/proc/touch_hunt_target(mob/living/user, mob/living/carbon/human/victim, obj/item/living_heart/heart)
	var/list/doors = pocket_doors(user, victim)
	if(!length(doors))
		return begin_heart_rite(user, victim, heart)
	var/list/choices = list(HERETIC_POCKET_RITE_HERE)
	for(var/label in doors)
		choices += label
	heretic_door_grip(victim, HERETIC_POCKET_DOOR_GRIP)
	. = choose_pocket_door(user, victim, heart, prompt_pocket_door(user, victim, choices))
	if(!. && !QDELETED(victim))
		victim.remove_status_effect(/datum/status_effect/heretic_door_grip)

/// Сжатое сердце с дверью издалека спрашивает: найти цель или увести её; TRUE - сердце занято вопросом, искать не нужно.
/datum/antagonist/heretic/proc/offer_remote_pocket_door(mob/living/user, mob/living/carbon/human/victim, obj/item/living_heart/heart)
	if(remote_door_prompt_open)
		return TRUE
	if(!istype(victim))
		return FALSE
	var/list/doors = pocket_doors(user, victim, remote_only = TRUE)
	if(!length(doors))
		return FALSE
	INVOKE_ASYNC(src, PROC_REF(choose_remote_pocket_door), user, victim, heart, doors)
	return TRUE

/datum/antagonist/heretic/proc/choose_remote_pocket_door(mob/living/user, mob/living/carbon/human/victim, obj/item/living_heart/heart, list/doors)
	var/list/choices = list(HERETIC_POCKET_TRACK_TARGET)
	for(var/label in doors)
		choices += label
	remote_door_prompt_open = TRUE
	var/choice = prompt_pocket_door(user, victim, choices)
	remote_door_prompt_open = FALSE
	if(!heart_answer_holds(user, heart))
		return FALSE
	if(!choice || choice == HERETIC_POCKET_TRACK_TARGET)
		return heart.track(user, src)
	return choose_pocket_door(user, victim, heart, choice, remote_only = TRUE)

/datum/antagonist/heretic/proc/prompt_pocket_door(mob/living/user, mob/living/victim, list/choices)
	var/question = (HERETIC_POCKET_RITE_HERE in choices) ? "Провести обряд над [victim] здесь или увести цель в изнанку?" : "Найти [victim] или увести цель в изнанку издалека?"
	return heart_alert(user, question, choices, HERETIC_RITUAL_CHOICE_TIMEOUT)

/datum/antagonist/heretic/proc/heart_alert(mob/living/user, question, list/choices, timeout)
	return tgui_alert(user, question, "Живое сердце", choices, timeout)

/// Тот же еретик после ответа всё ещё держит своё сердце.
/datum/antagonist/heretic/proc/heart_answer_holds(mob/living/user, obj/item/living_heart/heart)
	return !QDELETED(src) && !role_removed && !QDELETED(user) && user.mind == owner && !QDELETED(heart) && user.is_holding(heart)

/// Ответ мог прийти через минуту: цель, сердце и дверь проверяются заново.
/datum/antagonist/heretic/proc/choose_pocket_door(mob/living/user, mob/living/carbon/human/victim, obj/item/living_heart/heart, choice, remote_only = FALSE)
	if(!choice || !heart_answer_holds(user, heart) || QDELETED(victim) || victim.mind != hunt_target)
		return FALSE
	if(choice == HERETIC_POCKET_RITE_HERE)
		return user.Adjacent(victim) && begin_heart_rite(user, victim, heart)
	var/list/doors = pocket_doors(user, victim, remote_only)
	var/list/door = doors[choice]
	if(!door)
		to_chat(user, span_warning("Эта дверь уже закрылась: цель очнулась или ушла, либо условие двери пропало."))
		return FALSE
	return pocket_pull(user, victim, get_turf(victim), door["time"], door["check"], door["text"], hold_on_entry = isnull(door["hold"]) ? TRUE : door["hold"])

/datum/antagonist/heretic/proc/pocket_exits(mob/living/user)
	. = list()
	if(pocket?.entry_turf)
		heretic_add_pocket_exit(., HERETIC_POCKET_ENTRY_EXIT, pocket.entry_turf)
		var/turf/origin = pocket.origin_turf
		if(origin && (origin.z != pocket.entry_turf.z || get_dist(origin, pocket.entry_turf) > 1))
			heretic_add_pocket_exit(., HERETIC_POCKET_ORIGIN_EXIT, origin)
	for(var/obj/effect/eldritch/rune as anything in GLOB.heretic_runes)
		if(rune.drawn_by?.resolve() == owner)
			heretic_add_pocket_exit(., "Руна: [get_area_name(rune, TRUE)]", get_turf(rune))
	for(var/knowledge_type in researched_knowledge)
		var/datum/eldritch_knowledge/knowledge = researched_knowledge[knowledge_type]
		var/list/extra = knowledge.pocket_exits(user)
		for(var/label in extra)
			heretic_add_pocket_exit(., label, extra[label])

/// Своё живое сердце или личный кодекс на полу закрывающейся изнанки уходят за завесу, а не к экипажу у входа.
/datum/antagonist/heretic/proc/stash_behind_veil(atom/movable/thing)
	var/obj/item/living_heart/heart = thing
	var/own_heart = istype(heart) && heart.owner_mind == owner
	if(!own_heart && (!istype(thing, /obj/item/forbidden_book) || personal_codex?.resolve() != thing))
		return FALSE
	if(GLOB.heretic_ritual_reservations[thing])
		return FALSE
	thing.moveToNullspace()
	summon_items |= thing
	return TRUE

/proc/heretic_door_grip(mob/living/victim, time)
	if(QDELETED(victim) || victim.stat == DEAD)
		return null
	var/datum/status_effect/heretic_door_grip/grip = victim.has_status_effect(/datum/status_effect/heretic_door_grip)
	if(grip)
		grip.extend(time)
		return grip
	return victim.apply_status_effect(/datum/status_effect/heretic_door_grip, time)

/// Сердце прижимает уже поверженную цель, пока еретик выбирает дверь и тянет её сквозь завесу.
/datum/status_effect/heretic_door_grip
	id = "heretic_door_grip"
	tick_interval = -1
	alert_type = null
	status_type = STATUS_EFFECT_UNIQUE
	on_remove_on_mob_delete = TRUE
	examine_text = span_warning("SUBJECTPRONOUN прижат к полу чужой волей: можно растолкать за 2 секунды, а нулевой жезл снимет её сразу.")
	var/datum/status_effect/incapacitating/paralyzed/heretic_ritual/restraint

/datum/status_effect/heretic_door_grip/on_creation(mob/living/new_owner, time)
	duration = time
	return ..()

/datum/status_effect/heretic_door_grip/on_apply()
	. = ..()
	if(!.)
		return
	restraint = new(list(owner, duration, TRUE))
	heretic_capture_hold(owner, REF(src))
	RegisterSignal(owner, COMSIG_LIVING_HERETIC_CAPTURE_SHAKEN, PROC_REF(on_shaken))
	RegisterSignal(owner, COMSIG_PARENT_ATTACKBY, PROC_REF(on_attackby))
	owner.visible_message(span_danger("Воздух вокруг [owner] густеет и прижимает к полу!"), span_userdanger("Чужая воля прижимает вас к полу!"))
	heretic_door_grip_fx(owner)

/datum/status_effect/heretic_door_grip/proc/extend(time)
	var/ends_at = world.time + time
	if(ends_at <= duration)
		return
	duration = ends_at
	if(QDELETED(restraint))
		restraint = new(list(owner, time, TRUE))
	else
		restraint.duration = max(restraint.duration, ends_at)

/datum/status_effect/heretic_door_grip/proc/on_shaken(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/datum/status_effect/heretic_door_grip/proc/on_attackby(mob/living/source, obj/item/item, mob/living/user, params)
	SIGNAL_HANDLER
	if(!istype(item, /obj/item/nullrod))
		return NONE
	user.visible_message(span_warning("[user] касается [source] нулевым жезлом, и чужая воля отпускает."), span_notice("Вы касаетесь [source] нулевым жезлом, и чужая воля отпускает."))
	heretic_capture_shaken_fx(user, source)
	qdel(src)
	return COMPONENT_NO_AFTERATTACK

/datum/status_effect/heretic_door_grip/on_remove()
	UnregisterSignal(owner, list(COMSIG_LIVING_HERETIC_CAPTURE_SHAKEN, COMSIG_PARENT_ATTACKBY))
	heretic_capture_unhold(owner, REF(src))
	// Чужой Paralyze мог продлить этот экземпляр: тогда он остаётся.
	if(!QDELETED(restraint) && restraint.duration <= duration)
		qdel(restraint)
	restraint = null
	return ..()

/obj/effect/eldritch
	var/datum/weakref/drawn_by

/// Дверь «за руну»: своя руна, намерение «Помощь», готовая живая цель охоты на руне или рядом.
/obj/effect/eldritch/proc/pocket_door_victim(mob/living/user)
	if(user.a_intent != INTENT_HELP)
		return null
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/mob/living/carbon/human/victim = heretic?.hunt_target?.current
	if(!istype(victim) || !pocket_door_holds(user, victim))
		return null
	return victim

/obj/effect/eldritch/proc/pocket_door_holds(mob/living/user, mob/living/carbon/human/victim)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/turf/rune_turf = get_turf(src)
	if(QDELETED(src) || !heretic || !rune_turf || drawn_by?.resolve() != user.mind || QDELETED(victim) || victim.stat == DEAD)
		return FALSE
	if(!isturf(victim.loc) || victim.z != rune_turf.z || get_dist(victim, rune_turf) > 1 || get_dist(user, rune_turf) > 1)
		return FALSE
	return heretic.hunt_target_ready(victim)

/obj/effect/eldritch/proc/pull_behind_rune(mob/living/user, mob/living/carbon/human/victim)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	return heretic?.pocket_pull(user, victim, get_turf(src), door_check = CALLBACK(src, PROC_REF(pocket_door_holds), user, victim), door_text = "Руна под [victim] проваливается внутрь себя.")

#undef HERETIC_POCKET_CENTER_OFFSET
#undef HERETIC_POCKET_FLOOR_RADIUS
#undef HERETIC_POCKET_ENTRY_EXIT
#undef HERETIC_POCKET_ORIGIN_EXIT
