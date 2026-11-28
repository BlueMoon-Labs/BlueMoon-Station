/datum/eldritch_knowledge/spell/mansus_veil
	name = "Пелена"
	summary = "5 секунд серая пелена гасит до 4 выстрелов в вас: пули, лазеры, дротики и шприцы."
	details = list(
		"Пелена встречает выстрелы со всех сторон и гасит их целиком: ни урона, ни оглушения, ни яда из шприца.",
		"Картечь одного выстрела считается одним выстрелом; после 4 выстрелов или 5 секунд пелена спадает.",
		"Удары, броски, взрывы, огонь и газ пелена не держит; ваши и союзные снаряды проходят сквозь неё.",
		"Серую дымку вокруг вас видят все, а каждый погашенный выстрел слышно.",
		"Даётся любому пути: время уйти из-под огня или сблизиться со стрелком, а не стоять под ним.",
		"Перезарядка 45 секунд; до вознесения не колдуется под оглушением и в стамкрите.",
	)
	role = HERETIC_ROLE_DEFENSE
	gain_text = "Между мной и чужой волей встала завеса, тонкая, как дыхание на стекле."
	cost = 2
	spell_to_add = /obj/effect/proc_holder/spell/self/mansus_veil
	route = PATH_SIDE

/datum/eldritch_knowledge/spell/mansus_veil/on_body_lose(mob/living/user)
	user?.remove_status_effect(/datum/status_effect/heretic_veil)
	return ..()

/obj/effect/proc_holder/spell/self/mansus_veil
	heretic_stun_check = TRUE
	name = "Пелена"
	desc = "На 5 секунд окутайтесь серой пеленой: она гасит до 4 выстрелов в вас - пули, лазеры, дротики и шприцы, вместе с оглушением и ядом. Картечь одного выстрела считается одним. Удары, броски и взрывы пелена не держит. Перезарядка 45 секунд."
	summary = "5 секунд пелена гасит до 4 выстрелов в вас."
	charge_max = HERETIC_VEIL_COOLDOWN
	clothes_req = FALSE
	invocation = "VE'LUM TAC'EAT"
	invocation_type = "whisper"
	sound = HERETIC_VEIL_CAST_SOUND
	action_icon = 'modular_bluemoon/icons/obj/heretic_side_actions.dmi'
	action_icon_state = "mansus_veil"
	action_background_icon_state = "bg_ecult"

/obj/effect/proc_holder/spell/self/mansus_veil/can_cast(mob/user, skipcharge, silent)
	if(!..())
		return FALSE
	var/mob/living/living_user = user
	return heretic_check(user, isliving(user) && !living_user.has_status_effect(/datum/status_effect/heretic_veil), silent, "Пелена уже окутывает вас.")

/obj/effect/proc_holder/spell/self/mansus_veil/cast(list/targets, mob/user)
	var/mob/living/living_user = user
	var/datum/status_effect/heretic_veil/veil = isliving(user) ? living_user.apply_status_effect(/datum/status_effect/heretic_veil) : null
	if(QDELETED(veil))
		heretic_revert_cast(user, "Пелена не легла: мёртвых и уже окутанных она не берёт.")
		return FALSE
	return TRUE

/// Гасит чужие выстрелы, пока есть заряды; дробины одного выстрела тратят один заряд.
/datum/status_effect/heretic_veil
	id = "heretic_veil"
	duration = HERETIC_VEIL_DURATION
	tick_interval = -1
	alert_type = null
	var/charges = HERETIC_VEIL_CHARGES
	var/last_shot_time = -1
	var/datum/weakref/last_shooter_ref
	var/datum/weakref/last_source_ref

/datum/status_effect/heretic_veil/on_apply()
	. = ..()
	if(owner.stat == DEAD)
		return FALSE
	RegisterSignal(owner, COMSIG_LIVING_RUN_BLOCK, PROC_REF(intercept))
	RegisterSignal(owner, COMSIG_LIVING_DEATH, PROC_REF(on_death))
	owner.add_filter(HERETIC_VEIL_FILTER, 2, outline_filter(1, HERETIC_VEIL_COLOR))
	animate(owner.get_filter(HERETIC_VEIL_FILTER), size = 2, time = 4, loop = -1, easing = SINE_EASING)
	animate(size = 1, time = 4, easing = SINE_EASING)
	new /obj/effect/temp_visual/heretic_veil_absorb(get_turf(owner))
	owner.visible_message(span_warning("Вокруг [owner] сгущается серая пелена, воздух дрожит, как над огнём."), span_notice("Пелена окутывает вас: она погасит [HERETIC_VEIL_CHARGES] выстрела за [HERETIC_VEIL_DURATION / (1 SECONDS)] секунд."))
	return TRUE

/datum/status_effect/heretic_veil/on_remove()
	UnregisterSignal(owner, list(COMSIG_LIVING_RUN_BLOCK, COMSIG_LIVING_DEATH))
	owner.remove_filter(HERETIC_VEIL_FILTER)
	if(owner.stat != DEAD)
		to_chat(owner, span_warning("Пелена рассеивается."))
	return ..()

/datum/status_effect/heretic_veil/proc/on_death(mob/living/source)
	SIGNAL_HANDLER
	qdel(src)

/datum/status_effect/heretic_veil/proc/intercept(mob/living/source, real_attack, atom/object, damage, attack_text, attack_type, armour_penetration, mob/living/attacker, def_zone, list/return_list, attack_direction)
	SIGNAL_HANDLER
	if(!real_attack || return_list?[HERETIC_BLOCK_ABSORBED] || !(attack_type & ATTACK_TYPE_PROJECTILE) || !istype(object, /obj/item/projectile))
		return BLOCK_NONE
	if(ismob(attacker) && (attacker == source || IS_HERETIC(attacker) || IS_HERETIC_MONSTER(attacker)))
		return BLOCK_NONE
	var/obj/item/projectile/shot = object
	// Дробины одного выстрела долетают до цели в соседние тики.
	var/same_volley = attacker && last_shot_time >= 0 && world.time - last_shot_time <= world.tick_lag && last_shooter_ref?.resolve() == attacker && last_source_ref?.resolve() == shot.fired_from
	if(!same_volley)
		if(charges <= 0)
			return BLOCK_NONE
		charges--
		last_shot_time = world.time
		last_shooter_ref = attacker ? WEAKREF(attacker) : null
		last_source_ref = shot.fired_from ? WEAKREF(shot.fired_from) : null
		feedback(shot)
	// Спадает на следующем тике, чтобы добрать дробины последнего выстрела.
	if(charges <= 0)
		duration = world.time
	return_list?[HERETIC_BLOCK_ABSORBED] = TRUE
	return BLOCK_SUCCESS

/datum/status_effect/heretic_veil/proc/feedback(obj/item/projectile/shot)
	new /obj/effect/temp_visual/heretic_veil_absorb(get_turf(owner))
	playsound(owner, HERETIC_VEIL_ABSORB_SOUND, 45, TRUE)
	owner.visible_message(span_warning("Серая пелена вокруг [owner] глотает [shot.name]!"), span_notice("Пелена гасит [shot.name]. Осталось выстрелов: [charges]."), vision_distance = COMBAT_MESSAGE_RANGE)

/obj/effect/temp_visual/heretic_veil_absorb
	name = "veil ripple"
	icon = 'modular_bluemoon/icons/obj/heretic_side_actions.dmi'
	icon_state = "veil_absorb"
	duration = 0.8 SECONDS
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	layer = ABOVE_MOB_LAYER
	randomdir = FALSE

/obj/vehicle/sealed/mecha
	/// Снимаем только свой запрет движения, а не чужую остановку времени.
	var/heretic_patron_jammed = FALSE
	var/heretic_patron_jam_ready_at = 0

/// Заряд Длани забивает приводы закрытого меха: он не ходит, не поворачивается и не стреляет.
/obj/vehicle/sealed/mecha/proc/heretic_patron_jam(mob/firer)
	if(QDELETED(src) || completely_disabled || world.time < heretic_patron_jam_ready_at)
		return FALSE
	for(var/mob/occupant as anything in occupants)
		if(IS_HERETIC(occupant) || IS_HERETIC_MONSTER(occupant))
			return FALSE
	heretic_patron_jammed = TRUE
	completely_disabled = TRUE
	heretic_patron_jam_ready_at = world.time + HERETIC_PATRON_MECH_JAM_TIME + HERETIC_PATRON_MECH_JAM_COOLDOWN
	add_atom_colour(HERETIC_PATRON_MECH_JAM_COLOR, TEMPORARY_COLOUR_PRIORITY)
	new /obj/effect/temp_visual/heretic_mark_burst/rust(get_turf(src))
	visible_message(span_warning("Ржавчина вгрызается в суставы [src]: мех скрежещет и замирает!"))
	for(var/mob/occupant as anything in occupants)
		to_chat(occupant, span_userdanger("Ржавчина забила приводы: [HERETIC_PATRON_MECH_JAM_TIME / (1 SECONDS)] секунды мех не ходит, не поворачивается и не стреляет!"))
		SEND_SOUND(occupant, sound('sound/machines/buzz-two.ogg', volume = 50))
	log_message("Приводы забиты Дланью покровителя: [key_name(firer)].", LOG_MECHA, color = "red")
	if(firer)
		log_combat(firer, src, "обездвижил Дланью покровителя")
	addtimer(CALLBACK(src, PROC_REF(heretic_patron_unjam)), HERETIC_PATRON_MECH_JAM_TIME, TIMER_UNIQUE | TIMER_OVERRIDE)
	return TRUE

/obj/vehicle/sealed/mecha/proc/heretic_patron_unjam()
	if(!heretic_patron_jammed)
		return FALSE
	heretic_patron_jammed = FALSE
	remove_atom_colour(TEMPORARY_COLOUR_PRIORITY, HERETIC_PATRON_MECH_JAM_COLOR)
	if(!(src in /datum/proximity_monitor/advanced/timestop::global_frozen_atoms))
		completely_disabled = FALSE
	for(var/mob/occupant as anything in occupants)
		to_chat(occupant, span_notice("Приводы стряхивают ржавчину и снова слушаются."))
		SEND_SOUND(occupant, sound('sound/items/timer.ogg', volume = 50))
	return TRUE
