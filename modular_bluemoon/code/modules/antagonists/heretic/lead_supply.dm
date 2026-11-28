#define LEAD_UNDER_FIRE_ANGLE 30
#define LEAD_UNDER_FIRE_PRUNE 32
#define LEAD_DRUM_GAIN_TINT "#ffc46a"
#define LEAD_DRUM_FLASH_TIME (0.4 SECONDS)
#define LEAD_FINGER_TRACE (0.4 SECONDS)
#define LEAD_FINGER_HINT (2 SECONDS)

/// Свои источники Свинца: Палец-ствол, свои гильзы, Переплавка, Тлеющий запас и патронташ.
/datum/eldritch_knowledge/base_lead
	var/reserve_timer
	var/last_combat_at = -INFINITY
	/// Свинец на поясе сверх барабана: из него сам дозаряжается опустевший барабан.
	var/bandolier = 0
	var/reload_timer
	/// Стрелки, уже пополнившие патронташ: REF(стрелка) => когда снова можно.
	var/list/fire_heard = list()
	COOLDOWN_DECLARE(finger_hint)
	/// Свинец в барабане и патронташе на прошлом обновлении значка: прибавка вспыхивает янтарём.
	var/drum_shown = 0
	var/bandolier_shown = 0
	var/gain_flashes = 0

/datum/eldritch_knowledge/base_lead/notify_resource_changed()
	check_reload()
	. = ..()
	schedule_reserve()
	var/atom/movable/screen/alert/heretic_resource/indicator = update_drum_hud()
	if(indicator && (combat_resource > drum_shown || bandolier > bandolier_shown))
		flash_drum(indicator)
	drum_shown = combat_resource
	bandolier_shown = bandolier

/// Прибавка Свинца в барабан или патронташ: значок вспыхивает янтарём, а не общим зелёным.
/datum/eldritch_knowledge/base_lead/proc/flash_drum(atom/movable/screen/alert/heretic_resource/indicator)
	gain_flashes++
	animate(indicator)
	indicator.color = LEAD_DRUM_GAIN_TINT
	indicator.transform = matrix() * 1.12
	animate(indicator, color = null, transform = matrix(), time = LEAD_DRUM_FLASH_TIME)

/datum/eldritch_knowledge/base_lead/proc/lead_total()
	return combat_resource + bandolier

/datum/eldritch_knowledge/base_lead/proc/lead_capacity()
	return combat_resource_max + HERETIC_LEAD_BANDOLIER

/datum/eldritch_knowledge/base_lead/proc/lead_count_text()
	return "Свинец: [combat_resource] из [combat_resource_max], в патронташе [bandolier] из [HERETIC_LEAD_BANDOLIER]."

/// Барабан полон - лишний Свинец ложится в патронташ.
/datum/eldritch_knowledge/base_lead/gain_combat_resource(amount = 1)
	var/overflow = clamp(combat_resource + amount - combat_resource_max, 0, max(amount, 0))
	..(amount - overflow)
	if(overflow)
		fill_bandolier(overflow)

/// Способности добирают недостающий Свинец из патронташа; выстрел ждёт дозарядки.
/datum/eldritch_knowledge/base_lead/spend_combat_resource(amount = 1)
	if(amount > 0 && combat_resource < amount && lead_total() >= amount)
		var/drawn = amount - combat_resource
		bandolier -= drawn
		combat_resource += drawn
	return ..()

/datum/eldritch_knowledge/base_lead/proc/fill_bandolier(amount = 1)
	var/previous = bandolier
	bandolier = clamp(bandolier + amount, 0, HERETIC_LEAD_BANDOLIER)
	. = bandolier - previous
	if(.)
		notify_resource_changed()

/// Опустевший барабан за секунду дозаряжается из патронташа.
/datum/eldritch_knowledge/base_lead/proc/check_reload()
	if(combat_resource > 0 || bandolier <= 0 || reload_timer || QDELETED(src) || QDELETED(lead_body) || lead_body.stat == DEAD)
		return FALSE
	reload_timer = addtimer(CALLBACK(src, PROC_REF(finish_reload)), HERETIC_LEAD_RELOAD_TIME, TIMER_STOPPABLE)
	heretic_lead_sound(lead_body, "drum_spin", 35, TRUE, SILENCED_SOUND_EXTRARANGE)
	lead_body.balloon_alert(lead_body, "дозарядка")
	return TRUE

/datum/eldritch_knowledge/base_lead/proc/finish_reload()
	reload_timer = null
	if(QDELETED(src) || QDELETED(lead_body) || lead_body.stat == DEAD || bandolier <= 0)
		return 0
	var/moved = min(bandolier, combat_resource_max - combat_resource)
	if(moved <= 0)
		return 0
	bandolier -= moved
	combat_resource += moved
	heretic_lead_sound(lead_body, "cock", 40, TRUE, SILENCED_SOUND_EXTRARANGE)
	notify_resource_changed()
	SEND_SIGNAL(src, COMSIG_HERETIC_LEAD_EVENT, "reload", lead_body, moved)
	return moved

/datum/eldritch_knowledge/base_lead/proc/stop_reload()
	deltimer(reload_timer)
	reload_timer = null

/// Выстрел живого стрелка в 7 клетках целит в еретика, рядом с ним или конусом в его сторону.
/datum/eldritch_knowledge/base_lead/proc/shot_toward_body(mob/living/shooter, atom/target)
	if(!isliving(shooter) || QDELETED(lead_body) || lead_body.stat == DEAD || !owner_heretic())
		return FALSE
	var/turf/here = get_turf(lead_body)
	var/turf/from = get_turf(shooter)
	var/turf/aim = get_turf(target)
	if(!here || !from || !aim || from == here || from.z != here.z || get_dist(from, here) > HERETIC_LEAD_UNDER_FIRE_RANGE)
		return FALSE
	return get_dist(aim, here) <= 1 || (aim != from && abs(closer_angle_difference(Get_Angle(from, aim), Get_Angle(from, here))) <= LEAD_UNDER_FIRE_ANGLE)

/// Под огнём: выстрел из огнестрела в вашу сторону в 7 клетках кладёт единицу в патронташ, от каждого стрелка не чаще раза в секунду.
/datum/eldritch_knowledge/base_lead/proc/under_fire(mob/living/shooter, atom/target)
	if(!shot_toward_body(shooter, target))
		return 0
	var/key = REF(shooter)
	if(fire_heard[key] > world.time)
		return 0
	if(length(fire_heard) >= LEAD_UNDER_FIRE_PRUNE)
		fire_heard.Cut()
	fire_heard[key] = world.time + HERETIC_LEAD_UNDER_FIRE_COOLDOWN
	. = fill_bandolier()
	if(.)
		SEND_SIGNAL(src, COMSIG_HERETIC_LEAD_EVENT, "under_fire", shooter, bandolier)

/datum/eldritch_knowledge/base_lead/proc/mark_combat()
	last_combat_at = world.time

/datum/eldritch_knowledge/base_lead/proc/calm_left()
	return last_combat_at + HERETIC_LEAD_RESERVE_CALM - world.time

/datum/eldritch_knowledge/base_lead/proc/schedule_reserve()
	if(reserve_timer || QDELETED(src) || QDELETED(lead_body) || combat_resource >= HERETIC_LEAD_RESERVE_CAP)
		return
	reserve_timer = addtimer(CALLBACK(src, PROC_REF(reserve_tick)), max(HERETIC_LEAD_RESERVE_PERIOD, calm_left()), TIMER_STOPPABLE)

/datum/eldritch_knowledge/base_lead/proc/stop_reserve()
	deltimer(reserve_timer)
	reserve_timer = null

/// Тлеющий запас: без боя Свинец сам копится до трёх, бой откладывает следующую единицу.
/datum/eldritch_knowledge/base_lead/proc/reserve_tick()
	stop_reserve()
	if(QDELETED(src) || QDELETED(lead_body) || combat_resource >= HERETIC_LEAD_RESERVE_CAP)
		return FALSE
	var/wait = calm_left()
	if(wait > 0 || lead_body.stat == DEAD || !owner_heretic())
		reserve_timer = addtimer(CALLBACK(src, PROC_REF(reserve_tick)), wait > 0 ? wait : HERETIC_LEAD_RESERVE_PERIOD, TIMER_STOPPABLE)
		return FALSE
	gain_combat_resource()
	SEND_SIGNAL(src, COMSIG_HERETIC_LEAD_EVENT, "reserve", lead_body, combat_resource)
	return TRUE

/datum/eldritch_knowledge/base_lead/proc/on_body_damaged(datum/source, damage, damagetype)
	SIGNAL_HANDLER
	if(damage > 0 && (damagetype == BRUTE || damagetype == BURN || damagetype == STAMINA))
		mark_combat()

/datum/eldritch_knowledge/base_lead/proc/on_body_item_attack(mob/living/source, mob/living/target, mob/living/user)
	SIGNAL_HANDLER
	var/obj/item/weapon = source.get_active_held_item()
	if(target != source && isliving(target) && weapon?.force > 0)
		mark_combat()

/datum/eldritch_knowledge/base_lead/proc/on_body_unarmed(mob/living/source, atom/target)
	SIGNAL_HANDLER
	if(target != source && isliving(target) && source.a_intent != INTENT_HELP)
		mark_combat()

/// Палец-ствол целит в живых, турели и мехи: клик по полу, стене или двери оставляет Хватку с зарядом.
/datum/eldritch_knowledge/base_lead/on_mansus_grasp_ranged(atom/target, mob/user, click_parameters)
	if(user.a_intent == INTENT_HELP || !can_use(user))
		return FALSE
	var/atom/victim = heretic_lead_finger_target(target, user)
	if(!victim)
		if(COOLDOWN_FINISHED(src, finger_hint))
			COOLDOWN_START(src, finger_hint, LEAD_FINGER_HINT)
			user.balloon_alert(user, "только по живой цели, турели или меху")
			to_chat(user, span_notice("Палец-ствол стреляет только в живую цель, поднятую турель или мех в [HERETIC_LEAD_FINGER_RANGE] клетках. Заряд Хватки сохранён."))
		return FALSE
	return !isnull(finger_gun(user, victim, click_parameters))

/// Цель Пальца-ствола, которую стрелок видит: живой, поднятая турель или мех, кликнутые сами или стоящие на клетке.
/proc/heretic_lead_finger_target(atom/target, mob/living/user)
	if(istype(target, /obj/machinery/porta_turret_cover))
		var/obj/machinery/porta_turret_cover/cover = target
		target = cover.parent_turret
	if(heretic_lead_finger_valid(target, user))
		return target
	if(!isturf(target))
		return null
	for(var/atom/movable/candidate as anything in target)
		if(heretic_lead_finger_valid(candidate, user))
			return candidate
	return null

/proc/heretic_lead_finger_valid(atom/movable/candidate, mob/living/user)
	if(!istype(candidate) || candidate == user || candidate.invisibility > user.see_invisible)
		return FALSE
	if(isliving(candidate))
		var/mob/living/victim = candidate
		return victim.stat != DEAD
	if(istype(candidate, /obj/machinery/porta_turret))
		var/obj/machinery/porta_turret/turret = candidate
		return !(turret.machine_stat & BROKEN)
	return istype(candidate, /obj/vehicle/sealed/mecha)

/datum/eldritch_knowledge/base_lead/proc/finger_block_reason(mob/living/user, atom/target)
	var/turf/origin = get_turf(user)
	var/turf/aim = get_turf(target)
	if(!origin || !aim || aim.z != origin.z)
		return "Палец-ствол стреляет только на своём этаже."
	if(get_dist(origin, aim) > HERETIC_LEAD_FINGER_RANGE)
		return "Палец-ствол бьёт не дальше [HERETIC_LEAD_FINGER_RANGE] клеток."
	if(HAS_TRAIT(user, TRAIT_PACIFISM))
		return "Вы не хотите никого ранить."
	var/mob/living/victim = target
	if(istype(victim))
		if(victim.alerts["antag_training_safe"])
			return "Цель в безопасном центре полигона: стрельба отключена. Перейдите на боевую площадку."
		if(IS_HERETIC(victim) || IS_HERETIC_MONSTER(victim))
			return "Это союзник Мансуса: в него Палец-ствол не стреляет."
	if(istype(target, /obj/vehicle/sealed/mecha))
		var/obj/vehicle/sealed/mecha/mech = target
		for(var/mob/living/pilot in mech.occupants)
			if(IS_HERETIC(pilot) || IS_HERETIC_MONSTER(pilot))
				return "В мехе сидит союзник Мансуса: в него Палец-ствол не стреляет."
	return null

/// Палец-ствол: Хватка издали выпускает свинцовую дробину, вблизи остаётся обычной Хваткой.
/datum/eldritch_knowledge/base_lead/proc/finger_gun(mob/living/user, atom/target, params)
	lead_failure = finger_block_reason(user, target)
	if(lead_failure)
		to_chat(user, span_warning("[lead_failure] Заряд Хватки сохранён."))
		return null
	var/turf/origin = get_turf(user)
	var/obj/item/projectile/bullet/heretic_lead_pellet/pellet = new(origin)
	pellet.firer = user
	pellet.lead_ref = WEAKREF(src)
	pellet.def_zone = check_zone(user.zone_selected)
	pellet.range = CEILING(get_dist_euclidian(origin, get_turf(target)), 1) + 1
	pellet.preparePixelProjectile(target, user, user.client ? params : null)
	if(QDELETED(pellet))
		return null
	school_tracer(pellet)
	log_combat(user, target, "стреляет Пальцем-стволом в", null, "из [AREACOORD(origin)]")
	pellet.fire()
	var/obj/effect/temp_visual/heretic_lead/muzzle/flash = new(origin)
	flash.setDir(get_dir(user, target))
	heretic_lead_sound(user, "shot", 35, TRUE, -2)
	user.visible_message(span_danger("[user] наставляет палец, и из него с хлопком вылетает свинцовая дробина!"), span_notice("Палец-ствол: дробина ушла."), null, COMBAT_MESSAGE_RANGE)
	user.changeNext_move(CLICK_CD_RANGE)
	mark_combat()
	return pellet

/// Попадание Шестизарядника в живого врага возвращает единицу Свинца, убитый им человек - ещё три.
/datum/eldritch_knowledge/base_lead/proc/revolver_hit(mob/living/victim, was_alive = TRUE)
	mark_combat()
	if(!was_alive || IS_HERETIC(victim) || IS_HERETIC_MONSTER(victim) || QDELETED(lead_body) || lead_body.stat == DEAD)
		return 0
	. = 1
	note_spree(victim)
	if(victim.stat == DEAD && ishuman(victim))
		. += HERETIC_LEAD_KILL_LEAD
		to_chat(lead_body, span_eldritch("Пуля Шестизарядника оборвала жизнь [victim.name]: +[HERETIC_LEAD_KILL_LEAD] Свинца сверх возврата."))
		log_game("[key_name(lead_body)] получает Свинец за убийство [key_name(victim)] из Шестизарядника в [AREACOORD(victim)].")
	gain_combat_resource(.)

/// Последний патрон не возвращает Свинец за попадание, но убитый им человек отдаёт те же три.
/datum/eldritch_knowledge/base_lead/proc/last_round_kill(mob/living/victim, was_alive)
	if(!was_alive || QDELETED(victim) || victim.stat != DEAD || !ishuman(victim) || IS_HERETIC(victim) || IS_HERETIC_MONSTER(victim) || QDELETED(lead_body) || lead_body.stat == DEAD)
		return 0
	gain_combat_resource(HERETIC_LEAD_KILL_LEAD)
	to_chat(lead_body, span_eldritch("Последний патрон оборвал жизнь [victim.name]: +[HERETIC_LEAD_KILL_LEAD] Свинца, барабан снова наполняется."))
	log_game("[key_name(lead_body)] получает Свинец за убийство [key_name(victim)] Последним патроном в [AREACOORD(victim)].")
	return HERETIC_LEAD_KILL_LEAD

/datum/eldritch_knowledge/base_lead/proc/smeltable(atom/target)
	if(istype(target, /obj/item/stack/sheet/metal) || istype(target, /obj/item/stack/rods))
		var/obj/item/stack/stack = target
		return !stack.is_cyborg
	return istype(target, /obj/item/ammo_box) && heretic_lead_curseable(target)

/datum/eldritch_knowledge/base_lead/proc/smelt_need(obj/item/stack/stack)
	return istype(stack, /obj/item/stack/rods) ? HERETIC_LEAD_SMELT_RODS : HERETIC_LEAD_SMELT_SHEETS

/datum/eldritch_knowledge/base_lead/proc/smelt_rounds(obj/item/ammo_box/box)
	. = list()
	for(var/obj/item/ammo_casing/round in box.stored_ammo)
		if(round.BB && heretic_lead_casing_lethal(round))
			. += round

/datum/eldritch_knowledge/base_lead/proc/smelt_block_reason(mob/living/user, obj/item/item)
	if(QDELETED(item) || (!isturf(item.loc) && item.loc != user))
		return "Плавить можно то, что лежит на полу или в руке."
	if(lead_total() >= lead_capacity())
		return "Барабан и патронташ полны: Свинца уже [lead_capacity()]."
	if(istype(item, /obj/item/stack))
		var/obj/item/stack/stack = item
		var/need = smelt_need(stack)
		if(stack.get_amount() < need)
			return "Для Переплавки нужно [need] [istype(stack, /obj/item/stack/rods) ? "прутьев" : "листов железа"], а тут [stack.get_amount()]."
		return null
	if(length(smelt_rounds(item)) < HERETIC_LEAD_SMELT_ROUNDS)
		return "В [item] меньше [HERETIC_LEAD_SMELT_ROUNDS] боевых патронов: плавить нечего."
	return null

/datum/eldritch_knowledge/base_lead/proc/smelt_ready(mob/living/user, obj/item/item)
	return can_use(user) && !smelt_block_reason(user, item)

/// Переплавка: секунда в ладони, и железо или патроны магазина уходят в Свинец; заряд Хватки цел.
/datum/eldritch_knowledge/base_lead/proc/smelt(mob/living/user, obj/item/item)
	grasp_failure_reason = smelt_block_reason(user, item)
	if(grasp_failure_reason)
		return FALSE
	var/turf/place = get_turf(item)
	var/item_name = "[item]"
	user.visible_message(span_warning("[user] сжимает в ладони [item]: металл темнеет и оплывает тяжёлыми каплями."), span_notice("Вы плавите [item] в Свинец..."))
	heretic_lead_sound(place, "smelt", 45, TRUE)
	new /obj/effect/temp_visual/heretic_lead/smelt(place)
	heretic_vfx_stream(place, user, /particles/heretic_ascension/lead_smelt, HERETIC_LEAD_SMELT_TIME)
	if(!do_after(user, HERETIC_LEAD_SMELT_TIME, target = item, extra_checks = CALLBACK(src, PROC_REF(smelt_ready), user, item)))
		grasp_failure_reason = "Переплавка прервана."
		return FALSE
	var/gained = 1
	if(istype(item, /obj/item/stack))
		var/obj/item/stack/stack = item
		stack.use(smelt_need(stack))
	else
		var/obj/item/ammo_box/box = item
		var/list/rounds = smelt_rounds(box)
		for(var/index in 1 to HERETIC_LEAD_SMELT_ROUNDS)
			var/obj/item/ammo_casing/round = rounds[index]
			box.stored_ammo -= round
			qdel(round)
		box.update_icon()
		gained = HERETIC_LEAD_SMELT_MAGAZINE_LEAD
	gain_combat_resource(gained)
	mark_smelted(place)
	to_chat(user, span_eldritch("Металл стекает в ладонь и уходит в кровь свинцом. [lead_count_text()]"))
	log_game("[key_name(user)] переплавляет Свинцом [item_name] в [AREACOORD(place)]: +[gained] Свинца.")
	if(istype(item, /obj/item/ammo_box) && !QDELETED(item) && !item.GetComponent(/datum/component/heretic_lead_curse))
		place_curse(user, item)
	SEND_SIGNAL(src, COMSIG_HERETIC_LEAD_EVENT, "smelt", place, gained)
	return TRUE

/datum/eldritch_knowledge/base_lead/proc/mark_smelted(turf/place)
	new /obj/effect/temp_visual/heretic_lead/ricochet(place)
	heretic_lead_sound(place, "quench", 40, TRUE)

/// Где лечь гильзе: на открытом полу у места удара, а не в стене.
/proc/heretic_lead_casing_spot(turf/place, turf/fallback)
	if(isopenturf(place) && !place.density)
		return place
	for(var/direction in GLOB.cardinals)
		var/turf/nearby = get_step(place, direction)
		if(isopenturf(nearby) && !nearby.density)
			return nearby
	return isopenturf(fallback) ? fallback : null

/proc/heretic_lead_drop_casing(turf/place, turf/fallback, volume = 30)
	place = heretic_lead_casing_spot(place, fallback)
	if(!place)
		return null
	. = new /obj/item/ammo_casing/heretic_lead(place)
	heretic_lead_sound(place, "casing", volume, TRUE)

/// Стреляная гильза Пальца-ствола и Шестизарядника: Хватка Свинца впитывает её, как чужую.
/obj/item/ammo_casing/heretic_lead
	name = "tarnished casing"
	desc = "Стреляная гильза из потемневшей латуни, тяжёлая, будто налита свинцом. Калибр не подходит ни к одному стволу на станции, а донце ещё тёплое."
	icon = HERETIC_LEAD_FX_ICON
	icon_state = "lead_casing"
	can_be_printed = FALSE

/obj/item/ammo_casing/heretic_lead/update_icon_state()
	. = ..()
	desc = initial(desc)

/// Дробина Пальца-ствола: обычная пуля, без оглушения и доворота; где она легла, звякает гильза.
/obj/item/projectile/bullet/heretic_lead_pellet
	name = "lead pellet"
	damage = HERETIC_LEAD_FINGER_DAMAGE
	shrapnel_type = null
	embedding = null
	wound_bonus = CANT_WOUND
	log_override = TRUE
	var/datum/weakref/lead_ref
	var/casing_dropped = FALSE

/obj/item/projectile/bullet/heretic_lead_pellet/on_hit(atom/target, blocked = FALSE, pierce_hit)
	var/turf/place = get_turf(src)
	. = ..()
	drop_casing(place)
	var/datum/eldritch_knowledge/base_lead/lead = lead_ref?.resolve()
	lead?.record_impact(place)
	if(lead && isliving(target))
		lead.mark_combat()
		if(blocked < 100)
			lead.note_spree(target)
		SEND_SIGNAL(lead, COMSIG_HERETIC_LEAD_EVENT, "finger", target, blocked)

/obj/item/projectile/bullet/heretic_lead_pellet/on_range()
	drop_casing(get_turf(src))
	return ..()

/obj/item/projectile/bullet/heretic_lead_pellet/proc/drop_casing(turf/place)
	if(casing_dropped)
		return
	casing_dropped = TRUE
	heretic_lead_trace(starting, place, "lead_finger_tracer", LEAD_FINGER_TRACE)
	heretic_lead_drop_casing(place, get_turf(firer))

/obj/item/projectile/bullet/heretic_lead_pellet/Destroy()
	lead_ref = null
	return ..()

/obj/effect/temp_visual/heretic_lead/smelt
	name = "molten lead"
	icon_state = "lead_smelt"
	duration = HERETIC_LEAD_SMELT_TIME + 0.5 SECONDS

/// Искры Переплавки: летят от плавящегося металла к еретику.
/particles/heretic_ascension/lead_smelt
	icon = HERETIC_LEAD_FX_ICON
	icon_state = "lead_p_spark"
	spawning = 2
	lifespan = 0.6 SECONDS
	fade = 0.2 SECONDS

/// След выстрела по прямой: луч от точки к точке гаснет сам.
/proc/heretic_lead_trace(turf/start, turf/finish, state, time)
	if(!isturf(start) || !isturf(finish) || start == finish || start.z != finish.z)
		return null
	return start.Beam(finish, icon_state = state, icon = HERETIC_LEAD_FX_ICON, time = time, maxdistance = INFINITY)

#undef LEAD_UNDER_FIRE_ANGLE
#undef LEAD_UNDER_FIRE_PRUNE
#undef LEAD_DRUM_GAIN_TINT
#undef LEAD_DRUM_FLASH_TIME
#undef LEAD_FINGER_TRACE
#undef LEAD_FINGER_HINT
