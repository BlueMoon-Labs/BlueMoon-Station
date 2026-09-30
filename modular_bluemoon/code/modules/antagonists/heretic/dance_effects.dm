#define DANCE_EARWORM_SLEEP_CURE (10 SECONDS)
#define DANCE_INVITE_CAPTURE "dance_invite"
#define DANCE_LEAD_CAPTURE "dance_lead"
#define DANCE_MASK_NAME "танцор в маске"

/// Всё, что держит человека в танце еретика: музыка звучит ему, эффекты снимаются вместе с танцем.
/datum/status_effect/heretic_dance
	id = "heretic_dance"
	status_type = STATUS_EFFECT_UNIQUE
	on_remove_on_mob_delete = TRUE
	var/datum/weakref/dance_ref
	/// Эффект открывает дверь в изнанку еретику вплотную.
	var/opens_door = FALSE
	var/applied = FALSE

/datum/status_effect/heretic_dance/on_creation(mob/living/new_owner, datum/eldritch_knowledge/base_dance/dance)
	dance_ref = WEAKREF(dance)
	return ..()

/datum/status_effect/heretic_dance/on_apply()
	. = ..()
	var/datum/eldritch_knowledge/base_dance/dance = dance_ref?.resolve()
	if(!. || !dance?.dance_body)
		return FALSE
	applied = TRUE
	dance.add_dancer(owner)
	RegisterSignal(dance, COMSIG_HERETIC_DANCE_BEAT, PROC_REF(on_dance_beat))
	return TRUE

/datum/status_effect/heretic_dance/on_remove()
	var/datum/eldritch_knowledge/base_dance/dance = dance_ref?.resolve()
	if(applied && dance)
		UnregisterSignal(dance, COMSIG_HERETIC_DANCE_BEAT)
		// Остальные эффекты танца ещё держат моба: remove_dancer проверит их сам.
		applied = FALSE
		dance.remove_dancer(owner)
	return ..()

/datum/status_effect/heretic_dance/proc/on_dance_beat(datum/source, index, strong)
	SIGNAL_HANDLER
	heretic_dance_hop(owner, strong)

/datum/status_effect/heretic_dance/proc/dance()
	return dance_ref?.resolve()

/datum/status_effect/heretic_dance/proc/leader()
	var/datum/eldritch_knowledge/base_dance/dance = dance_ref?.resolve()
	return dance?.dance_body

/// Ноги сделали шаг сами: в случайную безопасную сторону.
/proc/heretic_dance_stagger(mob/living/walker)
	if(!isturf(walker.loc) || walker.buckled || walker.anchored || walker.pulledby || walker.stat != CONSCIOUS || walker.resting)
		return FALSE
	for(var/direction in shuffle(GLOB.alldirs.Copy()))
		var/turf/next = get_step(walker, direction)
		if(!next || isgroundlessturf(next) || next.is_blocked_turf(exclude_mobs = TRUE))
			continue
		if(walker.Move(next, direction))
			return TRUE
	return FALSE

/proc/heretic_dance_break_fx(mob/living/dancer)
	var/turf/place = get_turf(dancer)
	if(!place)
		return
	new /obj/effect/temp_visual/heretic_dance/ribbons(place)
	playsound(place, 'modular_bluemoon/sound/heretic/dance/false_note.ogg', 35, TRUE)

/// Кто-то вырвал танцора из чужого танца: лента рвётся на глазах у всех, спасатель и спасённый это слышат и видят.
/proc/heretic_dance_rescue_fx(mob/living/dancer, mob/living/helper)
	var/turf/place = get_turf(dancer)
	if(!place)
		return
	new /obj/effect/temp_visual/heretic_dance/rescue(place)
	playsound(place, 'modular_bluemoon/sound/heretic/dance/rescue.ogg', 60, FALSE)
	dancer.visible_message(span_notice("[helper] рывком выдёргивает [dancer] из чужого танца - алая лента лопается!"), span_notice("[helper] вырывает вас из танца. Ноги снова ваши."), ignored_mobs = helper)
	if(helper)
		to_chat(helper, span_notice("Вы вырвали [dancer] из чужого танца."))
		helper.balloon_alert(helper, "танец сорван!")

/proc/heretic_dance_ribbon(mob/living/leader, mob/living/dancer, time)
	if(!leader || !dancer)
		return null
	return leader.Beam(dancer, icon_state = "dance_ribbon_beam", icon = 'modular_bluemoon/icons/obj/heretic_dance_marks.dmi', time = time, maxdistance = HERETIC_DANCE_INVITE_BREAK_RANGE)

/proc/heretic_dance_combat_deed(mob/living/user, mob/living/victim)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	heretic?.advance_combat_deed(victim, PATH_DANCE)

/proc/heretic_dance_move(mob/living/walker, turf/next, direction)
	if(!QDELETED(walker) && isturf(walker.loc))
		walker.Move(next, direction)

/// Можно ли втянуть моба в хоровод или пляску: лежачих, сидящих, пристёгнутых, схваченных и глухих танец не берёт.
/proc/heretic_dance_can_sway(mob/living/user, mob/living/victim)
	if(!iscarbon(victim) || victim.stat != CONSCIOUS || victim.resting || victim.buckled || victim.pulledby || !isturf(victim.loc))
		return FALSE
	if(!heretic_dance_can_hear(victim))
		return FALSE
	return heretic_can_affect(user, victim, chargecost = 0, notify = FALSE)

/datum/status_effect/heretic_dance_earworm
	id = "heretic_dance_earworm"
	duration = HERETIC_DANCE_EARWORM_DURATION
	tick_interval = 2 SECONDS
	status_type = STATUS_EFFECT_UNIQUE
	on_remove_on_mob_delete = TRUE
	alert_type = /atom/movable/screen/alert/status_effect/heretic_dance_earworm
	examine_text = span_notice("SUBJECTPRONOUN постукивает пальцами в такт музыке, которой нет.")
	var/datum/weakref/dance_ref
	var/next_symptom = 0
	var/slept_for = 0
	var/datum/atom_hud/alternate_appearance/basic/onePerson/mark
	var/applied = FALSE

/datum/status_effect/heretic_dance_earworm/on_creation(mob/living/new_owner, datum/eldritch_knowledge/base_dance/dance)
	dance_ref = WEAKREF(dance)
	return ..()

/datum/status_effect/heretic_dance_earworm/on_apply()
	. = ..()
	var/datum/eldritch_knowledge/base_dance/dance = dance_ref?.resolve()
	if(!. || !dance)
		return FALSE
	applied = TRUE
	dance.earworms += src
	next_symptom = world.time + rand(20 SECONDS, 40 SECONDS)
	RegisterSignal(owner, COMSIG_LIVING_ELECTROCUTE_ACT, PROC_REF(on_shocked))
	RegisterSignal(owner, COMSIG_PARENT_ATTACKBY, PROC_REF(on_attackby))
	update_mark()
	dance.skeleton?.update_viewer(owner)
	playsound(owner, pick('modular_bluemoon/sound/heretic/dance/infect_1.ogg', 'modular_bluemoon/sound/heretic/dance/infect_2.ogg', 'modular_bluemoon/sound/heretic/dance/infect_3.ogg'), 20, TRUE, SILENCED_SOUND_EXTRARANGE)
	return TRUE

/datum/status_effect/heretic_dance_earworm/proc/refresh_duration()
	duration = world.time + HERETIC_DANCE_EARWORM_DURATION
	update_mark()

/// Нота над заражённым видна только еретику: экипаж узнаёт заражённых по симптомам и анализатору.
/datum/status_effect/heretic_dance_earworm/proc/update_mark()
	var/datum/eldritch_knowledge/base_dance/dance = dance_ref?.resolve()
	var/mob/living/viewer = dance?.dance_body
	if(mark && mark.target == owner && (viewer in mark.hudusers))
		return
	QDEL_NULL(mark)
	if(!viewer)
		return
	var/image/note = image('modular_bluemoon/icons/obj/heretic_dance_marks.dmi', owner, "dance_note", ABOVE_MOB_LAYER)
	note.pixel_y = 20
	note.override = FALSE
	note.appearance_flags = RESET_COLOR | RESET_TRANSFORM | KEEP_APART
	mark = owner.add_alt_appearance(/datum/atom_hud/alternate_appearance/basic/onePerson, "heretic_dance_note_[REF(src)]", note, viewer)

/datum/status_effect/heretic_dance_earworm/tick()
	var/datum/eldritch_knowledge/base_dance/dance = dance_ref?.resolve()
	if(!dance || owner.stat == DEAD)
		qdel(src)
		return
	if(owner.reagents?.has_reagent(/datum/reagent/water/holywater))
		cure("Святая вода смывает мелодию из головы [owner].")
		return
	if(owner.IsSleeping())
		slept_for += tick_interval
		if(slept_for >= DANCE_EARWORM_SLEEP_CURE)
			cure()
			return
	else
		slept_for = 0
	if(dance.dance_body && !heretic_can_affect(dance.dance_body, owner, chargecost = 0, notify = FALSE))
		cure()
		return
	update_mark()
	if(world.time < next_symptom || owner.stat != CONSCIOUS)
		return
	next_symptom = world.time + rand(40 SECONDS, 70 SECONDS)
	var/datum/heretic_dance_style/style = dance.current_style()
	switch(rand(1, 3))
		if(1)
			owner.visible_message(span_notice("[owner] притопывает в странном рваном ритме."), span_notice("Ноги сами отбивают такт мелодии, которую вы не можете вспомнить."))
		if(2)
			owner.visible_message(span_notice("[owner] вполголоса напевает что-то похожее на [lowertext(style.name)]."), span_notice("Вы ловите себя на том, что напеваете. Откуда вы знаете эту мелодию?"))
		if(3)
			to_chat(owner, span_warning("Сердце на миг сбивается и подстраивается под далёкий барабан."))

/datum/status_effect/heretic_dance_earworm/proc/cure(message)
	if(QDELETED(src))
		return
	if(message)
		owner.visible_message(span_notice(message))
	to_chat(owner, span_notice("Мелодия в голове обрывается. Наконец-то тишина."))
	qdel(src)

/datum/status_effect/heretic_dance_earworm/proc/on_shocked(datum/source, shock_damage, shock_source, siemens_coeff, flags)
	SIGNAL_HANDLER
	if(shock_damage > 0)
		cure()

/datum/status_effect/heretic_dance_earworm/proc/on_attackby(datum/source, obj/item/item, mob/living/user, params)
	SIGNAL_HANDLER
	if(!istype(item, /obj/item/nullrod))
		return NONE
	cure("[user] касается [owner] нулевым жезлом, и навязчивая мелодия стихает.")
	return NONE

/datum/status_effect/heretic_dance_earworm/on_remove()
	var/datum/eldritch_knowledge/base_dance/dance = dance_ref?.resolve()
	if(applied)
		UnregisterSignal(owner, list(COMSIG_LIVING_ELECTROCUTE_ACT, COMSIG_PARENT_ATTACKBY))
		if(dance)
			dance.earworms -= src
			dance.notify_resource_changed()
		for(var/datum/status_effect/heretic_dance/invited/invite in owner.status_effects)
			if(invite.dance_ref?.resolve() == dance)
				invite.stop("мелодия оборвалась")
	QDEL_NULL(mark)
	dance?.skeleton?.update_viewer(owner, TRUE)
	dance_ref = null
	return ..()

/atom/movable/screen/alert/status_effect/heretic_dance_earworm
	name = "Навязчивая мелодия"
	desc = "В голове крутится мелодия, и сердце бьётся в её ритме. Говорят, от такого помогает крепкий сон, святая вода или разряд дефибриллятора."
	icon = 'modular_bluemoon/icons/obj/heretic_alerts.dmi'
	icon_state = "dance_earworm"

/datum/status_effect/heretic_dance/invited
	id = "heretic_dance_invited"
	duration = -1
	tick_interval = -1
	alert_type = /atom/movable/screen/alert/status_effect/heretic_dance_invited
	examine_text = span_warning("SUBJECTPRONOUN танцует против воли, ноги сами несут SUBJECTOBJECT. Можно схватить, повалить, пристегнуть, растолкать за 2 секунды или коснуться нулевым жезлом.")
	var/style_id
	var/beats_left = HERETIC_DANCE_INVITE_BEATS
	var/started = FALSE
	var/held_since = 0
	var/list/turf/route
	var/planning = FALSE
	var/route_misses = 0
	var/stopped = FALSE
	var/completed = FALSE
	var/telegraph_beats = 0
	var/rescued = FALSE

/datum/status_effect/heretic_dance/invited/on_creation(mob/living/new_owner, datum/eldritch_knowledge/base_dance/dance, style_id)
	src.style_id = style_id
	if(style_id == HERETIC_DANCE_STYLE_MACABRE)
		beats_left = HERETIC_DANCE_INVITE_BEATS + 2
	return ..()

/datum/status_effect/heretic_dance/invited/on_apply()
	. = ..()
	if(!.)
		return FALSE
	var/datum/eldritch_knowledge/base_dance/dance = dance()
	dance.invites += src
	heretic_capture_hold(owner, DANCE_INVITE_CAPTURE)
	RegisterSignal(owner, COMSIG_LIVING_HERETIC_CAPTURE_SHAKEN, PROC_REF(on_shaken))
	RegisterSignal(owner, COMSIG_PARENT_ATTACKBY, PROC_REF(on_attackby))
	RegisterSignal(owner, COMSIG_LIVING_HERETIC_SACRIFICE_STARTING, PROC_REF(on_interrupt))
	RegisterSignal(owner, COMSIG_MOB_STATCHANGE, PROC_REF(on_stat_change))
	var/turf/place = get_turf(owner)
	if(place)
		new /obj/effect/temp_visual/heretic_dance_note(place)
	playsound(owner, 'modular_bluemoon/sound/heretic/dance/invite.ogg', 60, TRUE)
	owner.visible_message(span_warning("Над [owner] звучит далёкая мелодия, и ноги [owner] вздрагивают в такт."), span_userdanger("Музыка зовёт вас танцевать! Ноги больше не слушаются: вас ведут к тому, кто пригласил. Если вас схватят, повалят или растолкают, танец оборвётся."))
	owner.balloon_alert(owner, "зовите на помощь: пусть растолкают")
	return TRUE

/datum/status_effect/heretic_dance/invited/on_dance_beat(datum/source, index, strong)
	heretic_dance_hop(owner, strong)
	var/reason = hold_reason()
	if(reason)
		stop(reason)
		return
	if(!started)
		if(style_id == HERETIC_DANCE_STYLE_TANGO && ++telegraph_beats < 2)
			return
		start()
		return
	var/mob/living/user = leader()
	if(get_dist(owner, user) <= 1)
		complete()
		return
	if(--beats_left < 0)
		stop("танец выдохся, не дойдя до вас")
		return
	if(linked_alert)
		linked_alert.desc = "[initial(linked_alert.desc)] Шаг на каждой доле, осталось долей: [beats_left]."
	INVOKE_ASYNC(src, PROC_REF(dance_step), user)

/datum/status_effect/heretic_dance/invited/proc/start()
	var/datum/eldritch_knowledge/base_dance/dance = dance()
	var/mob/living/user = dance.dance_body
	started = TRUE
	held_since = world.time
	log_combat(user, owner, "приглашает на танец ([style_id])")
	if(style_id == HERETIC_DANCE_STYLE_TANGO)
		for(var/step_index in 1 to HERETIC_DANCE_INVITE_TANGO_RANGE)
			if(get_dist(owner, user) <= 1 || !heretic_dance_step_toward(owner, user))
				break
		if(get_dist(owner, user) > 1)
			stop("путь к вам перекрыт")
			return
		owner.Knockdown(1 SECONDS)
		complete()

/datum/status_effect/heretic_dance/invited/proc/dance_step(mob/living/user)
	if(QDELETED(src) || QDELETED(user))
		return
	var/turf/goal = get_turf(user)
	if(!planning && (isnull(route) || !length(route) || route[length(route)] != goal))
		planning = TRUE
		route = get_path_to(owner, goal, HERETIC_DANCE_INVITE_BREAK_RANGE + 2, 1, owner.get_idcard(), TRUE, null, TRUE, src)
		planning = FALSE
		if(QDELETED(src))
			return
	var/turf/here = get_turf(owner)
	if(length(route))
		var/turf/next = route[1]
		if(next.z == here.z && get_dist(here, next) == 1 && !isgroundlessturf(next) && owner.Move(next, get_dir(here, next)))
			route.Cut(1, 2)
			route_misses = 0
			return
	if(heretic_dance_step_toward(owner, user))
		return
	if(++route_misses >= 3)
		stop("путь к вам перекрыт")

/datum/status_effect/heretic_dance/invited/proc/hold_reason()
	var/datum/eldritch_knowledge/base_dance/dance = dance()
	var/mob/living/user = dance?.dance_body
	if(!dance?.can_use(user, allow_incapacitated = TRUE) || user.stat != CONSCIOUS)
		return "вы не удержали танец"
	if(owner.stat != CONSCIOUS)
		return "цель без сознания"
	if(!heretic_dance_can_hear(owner))
		return "цель больше не слышит музыку"
	if(!heretic_can_affect(user, owner, chargecost = 0, notify = FALSE))
		return "цель защищена от магии"
	if(owner.buckled || (owner.pulledby && owner.pulledby != user) || !isturf(owner.loc))
		return "цель удержали"
	if(started && heretic_capture_downed(owner) && style_id != HERETIC_DANCE_STYLE_TANGO)
		return "цель повалили"
	if(owner.z != user.z || get_dist(owner, user) > HERETIC_DANCE_INVITE_BREAK_RANGE + (style_id == HERETIC_DANCE_STYLE_MACABRE ? 4 : 0))
		return "цель слишком далеко"
	if(owner.reagents?.has_reagent(/datum/reagent/water/holywater))
		return "святая вода смыла мелодию"
	return null

/datum/status_effect/heretic_dance/invited/proc/complete()
	if(QDELETED(src))
		return
	var/datum/eldritch_knowledge/base_dance/dance = dance()
	var/mob/living/user = dance?.dance_body
	completed = TRUE
	var/held = heretic_capture_held_for(held_since)
	if(user)
		heretic_dance_combat_deed(user, owner)
		owner.apply_status_effect(/datum/status_effect/heretic_dance/partner, dance)
		owner.visible_message(span_danger("[owner] в последнем па оказывается в руках [user]."), span_userdanger("Танец приводит вас прямо в руки [user]!"))
		var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
		if(heretic?.hunt_target && heretic.hunt_target == owner.mind)
			to_chat(user, span_eldritch("[owner] - ваш партнёр на [DisplayTimeText(HERETIC_DANCE_PARTNER_TIME)]. Коснитесь партнёра живым сердцем: пока вы выбираете дверь, танец держит цель."))
			user.balloon_alert(user, "сердцем - в изнанку!")
		else
			to_chat(user, span_eldritch("[owner] - ваш партнёр на [DisplayTimeText(HERETIC_DANCE_PARTNER_TIME)]. Это не цель охоты: в изнанку не увести, но фигура Вальса поведёт партнёра за собой."))
		SEND_SIGNAL(dance, COMSIG_HERETIC_DANCE_EVENT, "partner", owner, null)
	held_since = world.time - held
	qdel(src)

/datum/status_effect/heretic_dance/invited/proc/stop(reason)
	if(QDELETED(src) || stopped)
		return
	stopped = TRUE
	var/datum/eldritch_knowledge/base_dance/dance = dance()
	var/mob/living/user = dance?.dance_body
	if(!started && user)
		heretic_refund_capture(user, /obj/effect/proc_holder/spell/pointed/heretic_dance/invite, "Приглашение сорвалось: [reason].")
	else if(user && reason)
		to_chat(user, span_warning("Приглашение оборвалось: [reason]."))
	if(dance)
		SEND_SIGNAL(dance, COMSIG_HERETIC_DANCE_EVENT, "invite_stopped", owner, reason)
	owner.visible_message(span_notice("[owner] сбивается с шага, и чужая мелодия стихает."), span_notice("Музыка обрывается, ноги снова ваши."))
	if(started && !rescued)
		heretic_dance_break_fx(owner)
	qdel(src)

/datum/status_effect/heretic_dance/invited/proc/on_shaken(datum/source, mob/living/helper)
	SIGNAL_HANDLER
	rescued = TRUE
	heretic_dance_rescue_fx(owner, helper)
	stop("[helper] растолкал цель")

/datum/status_effect/heretic_dance/invited/proc/on_attackby(datum/source, obj/item/item, mob/living/user, params)
	SIGNAL_HANDLER
	if(!istype(item, /obj/item/nullrod))
		return NONE
	stop("нулевой жезл оборвал мелодию")
	return COMPONENT_NO_AFTERATTACK

/datum/status_effect/heretic_dance/invited/proc/on_interrupt(datum/source)
	SIGNAL_HANDLER
	stopped = TRUE
	qdel(src)

/datum/status_effect/heretic_dance/invited/proc/on_stat_change(datum/source, new_stat)
	SIGNAL_HANDLER
	if(new_stat != CONSCIOUS)
		stop("цель без сознания")

/datum/status_effect/heretic_dance/invited/on_remove()
	var/datum/eldritch_knowledge/base_dance/dance = dance()
	if(applied)
		UnregisterSignal(owner, list(COMSIG_LIVING_HERETIC_CAPTURE_SHAKEN, COMSIG_PARENT_ATTACKBY, COMSIG_LIVING_HERETIC_SACRIFICE_STARTING, COMSIG_MOB_STATCHANGE))
		heretic_capture_unhold(owner, DANCE_INVITE_CAPTURE)
		dance?.invites -= src
		if(!completed)
			heretic_capture_release(owner, DANCE_INVITE_CAPTURE, held_for = heretic_capture_held_for(held_since))
	route = null
	return ..()

/atom/movable/screen/alert/status_effect/heretic_dance_invited
	name = "Приглашение на танец"
	desc = "Ноги сами идут в такт чужой музыке к тому, кто вас пригласил. Если вас схватят, повалят, пристегнут или растолкают за 2 секунды, танец оборвётся. Наушники-заглушки тоже помогут."
	icon = 'modular_bluemoon/icons/obj/heretic_alerts.dmi'
	icon_state = "dance_invited"

/obj/effect/temp_visual/heretic_dance_note
	icon = 'modular_bluemoon/icons/obj/heretic_dance_marks.dmi'
	icon_state = "dance_invite_note"
	duration = 1.2 SECONDS
	randomdir = FALSE
	pixel_y = 18
	layer = ABOVE_MOB_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/datum/status_effect/heretic_dance/partner
	id = "heretic_dance_partner"
	duration = HERETIC_DANCE_PARTNER_TIME
	alert_type = /atom/movable/screen/alert/status_effect/heretic_dance_partner
	examine_text = span_warning("SUBJECTPRONOUN застыл в танцевальной позе, будто ждёт следующего такта. Можно растолкать за 2 секунды или коснуться нулевым жезлом.")
	opens_door = TRUE
	var/held_since = 0
	var/datum/status_effect/incapacitating/paralyzed/heretic_ritual/restraint

/datum/status_effect/heretic_dance/partner/on_apply()
	. = ..()
	if(!.)
		return FALSE
	held_since = world.time
	heretic_capture_hold(owner, DANCE_INVITE_CAPTURE)
	ADD_TRAIT(owner, TRAIT_IMMOBILIZED, id)
	restraint = new(list(owner, -1, TRUE))
	RegisterSignal(owner, COMSIG_LIVING_HERETIC_CAPTURE_SHAKEN, PROC_REF(on_shaken))
	RegisterSignal(owner, COMSIG_PARENT_ATTACKBY, PROC_REF(on_attackby))
	owner.update_mobility()
	return TRUE

/datum/status_effect/heretic_dance/partner/process()
	if(owner?.has_status_effect(/datum/status_effect/heretic_door_grip))
		duration = max(duration, world.time + 1)
	return ..()

/datum/status_effect/heretic_dance/partner/proc/on_shaken(datum/source, mob/living/helper)
	SIGNAL_HANDLER
	heretic_dance_rescue_fx(owner, helper)
	var/datum/eldritch_knowledge/base_dance/dance = dance()
	if(dance)
		SEND_SIGNAL(dance, COMSIG_HERETIC_DANCE_EVENT, "rescued", owner, helper)
	qdel(src)

/datum/status_effect/heretic_dance/partner/proc/on_attackby(datum/source, obj/item/item, mob/living/user, params)
	SIGNAL_HANDLER
	if(!istype(item, /obj/item/nullrod))
		return NONE
	qdel(src)
	return COMPONENT_NO_AFTERATTACK

/datum/status_effect/heretic_dance/partner/on_remove()
	if(applied)
		UnregisterSignal(owner, list(COMSIG_LIVING_HERETIC_CAPTURE_SHAKEN, COMSIG_PARENT_ATTACKBY))
		REMOVE_TRAIT(owner, TRAIT_IMMOBILIZED, id)
		if(!QDELETED(restraint))
			qdel(restraint)
		restraint = null
		owner.update_mobility()
		heretic_capture_unhold(owner, DANCE_INVITE_CAPTURE)
		heretic_capture_release(owner, DANCE_INVITE_CAPTURE, held_for = heretic_capture_held_for(held_since))
	return ..()

/atom/movable/screen/alert/status_effect/heretic_dance_partner
	name = "Партнёр"
	desc = "Вы замерли в танцевальной позе рядом с тем, кто вас пригласил. Пусть кто-нибудь растолкает вас за 2 секунды или коснётся нулевым жезлом."
	icon = 'modular_bluemoon/icons/obj/heretic_alerts.dmi'
	icon_state = "dance_partner"

/// Фигура Вальса: ведомый повторяет каждый шаг еретика, заходя на его прежнюю клетку.
/datum/status_effect/heretic_dance/lead
	id = "heretic_dance_lead"
	duration = 4 SECONDS
	alert_type = /atom/movable/screen/alert/status_effect/heretic_dance_lead
	examine_text = span_warning("SUBJECTPRONOUN кружится в вальсе, прикованный к партнёру. Можно растолкать за 2 секунды или схватить.")
	opens_door = TRUE
	var/held_since = 0
	var/datum/beam/ribbon

/datum/status_effect/heretic_dance/lead/on_apply()
	. = ..()
	if(!.)
		return FALSE
	held_since = world.time
	ribbon = heretic_dance_ribbon(leader(), owner, duration)
	heretic_capture_hold(owner, DANCE_LEAD_CAPTURE)
	RegisterSignal(leader(), COMSIG_MOVABLE_MOVED, PROC_REF(on_leader_moved))
	RegisterSignal(owner, COMSIG_LIVING_HERETIC_CAPTURE_SHAKEN, PROC_REF(on_shaken))
	return TRUE

/datum/status_effect/heretic_dance/lead/proc/on_leader_moved(atom/movable/source, atom/old_loc, movement_dir, forced)
	SIGNAL_HANDLER
	if(forced || !isturf(old_loc) || owner.buckled || (owner.pulledby && owner.pulledby != source) || owner.stat != CONSCIOUS)
		qdel(src)
		return
	if(get_dist(owner, old_loc) > 1 || !isturf(owner.loc))
		qdel(src)
		return
	if(!owner.Move(old_loc, get_dir(owner, old_loc)))
		qdel(src)

/datum/status_effect/heretic_dance/lead/proc/on_shaken(datum/source, mob/living/helper)
	SIGNAL_HANDLER
	heretic_dance_rescue_fx(owner, helper)
	qdel(src)

/datum/status_effect/heretic_dance/lead/on_remove()
	QDEL_NULL(ribbon)
	if(applied)
		var/mob/living/user = leader()
		if(user)
			UnregisterSignal(user, COMSIG_MOVABLE_MOVED)
		UnregisterSignal(owner, COMSIG_LIVING_HERETIC_CAPTURE_SHAKEN)
		heretic_capture_unhold(owner, DANCE_LEAD_CAPTURE)
		heretic_capture_release(owner, DANCE_LEAD_CAPTURE, held_for = heretic_capture_held_for(held_since))
	return ..()

/atom/movable/screen/alert/status_effect/heretic_dance_lead
	name = "Вас ведут в вальсе"
	desc = "Вы повторяете каждый шаг партнёра и не можете отойти. Пусть вас растолкают или схватят."
	icon = 'modular_bluemoon/icons/obj/heretic_alerts.dmi'
	icon_state = "dance_lead"

/// Хоровод: втянутые повторяют шаги еретика и выматываются с каждым шагом.
/datum/status_effect/heretic_dance/horovod
	id = "heretic_dance_horovod"
	duration = HERETIC_DANCE_HOROVOD_TIME
	alert_type = /atom/movable/screen/alert/status_effect/heretic_dance_horovod
	examine_text = span_warning("SUBJECTPRONOUN движется в чужом хороводе, повторяя каждый шаг. Лечь, сесть, схватить или пристегнуть - и танец отпустит.")
	var/stamina_per_step = HERETIC_DANCE_HOROVOD_STAMINA
	var/stamina_dealt = 0
	var/datum/beam/ribbon
	/// В толпе вскрикивают только первые втянутые, иначе голоса сливаются в шум.
	var/voiced = TRUE

/datum/status_effect/heretic_dance/horovod/on_creation(mob/living/new_owner, datum/eldritch_knowledge/base_dance/dance, time, voiced = TRUE)
	if(time)
		duration = time
	src.voiced = voiced
	return ..()

/datum/status_effect/heretic_dance/horovod/on_apply()
	. = ..()
	if(!.)
		return FALSE
	RegisterSignal(leader(), COMSIG_MOVABLE_MOVED, PROC_REF(on_leader_moved))
	ribbon = heretic_dance_ribbon(leader(), owner, duration)
	owner.visible_message(span_danger("[owner] против воли подхватывает чужой хоровод!"), span_userdanger("Вы повторяете каждый шаг танцора и не можете остановиться! Лягте, сядьте или пусть вас схватят."))
	owner.balloon_alert(owner, "лягте - и танец отпустит")
	if(voiced)
		playsound(owner, pick(GLOB.heretic_dance_voices), 45, TRUE)
	owner.add_overlay(mutable_appearance('modular_bluemoon/icons/obj/heretic_dance_marks.dmi', "dance_note", ABOVE_MOB_LAYER))
	heretic_dance_combat_deed(leader(), owner)
	return TRUE

/datum/status_effect/heretic_dance/horovod/proc/on_leader_moved(atom/movable/source, atom/old_loc, movement_dir, forced)
	SIGNAL_HANDLER
	if(forced || !movement_dir)
		return
	var/mob/living/user = source
	if(!heretic_dance_can_sway(user, owner))
		heretic_dance_break_fx(owner)
		qdel(src)
		return
	var/turf/next = get_step(owner, movement_dir)
	if(next && !isgroundlessturf(next))
		new /obj/effect/temp_visual/heretic_dance_bone_steps(get_turf(owner), movement_dir)
		INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(heretic_dance_move), owner, next, movement_dir)
	var/drain = min(stamina_per_step, HERETIC_DANCE_HOROVOD_STAMINA_CAP - stamina_dealt)
	if(drain > 0)
		stamina_dealt += drain
		owner.adjustStaminaLoss(drain)

/datum/status_effect/heretic_dance/horovod/on_remove()
	QDEL_NULL(ribbon)
	if(applied)
		var/mob/living/user = leader()
		if(user)
			UnregisterSignal(user, COMSIG_MOVABLE_MOVED)
		owner.cut_overlay(mutable_appearance('modular_bluemoon/icons/obj/heretic_dance_marks.dmi', "dance_note", ABOVE_MOB_LAYER))
		owner.apply_status_effect(/datum/status_effect/heretic_dance_horovod_rest)
	return ..()

/atom/movable/screen/alert/status_effect/heretic_dance_horovod
	name = "Хоровод"
	desc = "Вы повторяете каждый шаг чужого танца и выматываетесь. Лягте, сядьте или пусть вас схватят - танец отпустит."
	icon = 'modular_bluemoon/icons/obj/heretic_alerts.dmi'
	icon_state = "dance_horovod"

/// После хоровода ноги не поддаются следующему ещё немного.
/datum/status_effect/heretic_dance_horovod_rest
	id = "heretic_dance_horovod_rest"
	duration = 20 SECONDS
	alert_type = null
	status_type = STATUS_EFFECT_REFRESH

/// Неконтролируемая пляска: каждую долю цель делает шаг куда попало.
/datum/status_effect/heretic_dance/frenzy
	id = "heretic_dance_frenzy"
	duration = 3 SECONDS
	alert_type = /atom/movable/screen/alert/status_effect/heretic_dance_frenzy
	examine_text = span_warning("SUBJECTPRONOUN бьётся в безумной пляске, не владея ногами.")

/datum/status_effect/heretic_dance/frenzy/on_creation(mob/living/new_owner, datum/eldritch_knowledge/base_dance/dance, time)
	if(time)
		duration = time
	return ..()

/datum/status_effect/heretic_dance/frenzy/on_apply()
	. = ..()
	if(!.)
		return FALSE
	owner.visible_message(span_danger("[owner] срывается в безумную пляску!"), span_userdanger("Ноги пляшут сами по себе!"))
	owner.Jitter(4)
	heretic_dance_combat_deed(leader(), owner)
	return TRUE

/datum/status_effect/heretic_dance/frenzy/on_dance_beat(datum/source, index, strong)
	heretic_dance_hop(owner, TRUE, TRUE)
	if(heretic_capture_downed(owner))
		return
	INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(heretic_dance_stagger), owner)

/atom/movable/screen/alert/status_effect/heretic_dance_frenzy
	name = "Безумная пляска"
	desc = "Ноги пляшут сами по себе и несут вас куда попало."
	icon = 'modular_bluemoon/icons/obj/heretic_alerts.dmi'
	icon_state = "dance_frenzy"

/// Тарантизм: стаки выматывают на каждой доле еретика, пять стаков срывают цель в пляску.
/datum/status_effect/heretic_dance/tarantism
	id = "heretic_dance_tarantism"
	duration = 6 SECONDS
	status_type = STATUS_EFFECT_REFRESH
	alert_type = /atom/movable/screen/alert/status_effect/heretic_dance_tarantism
	examine_text = span_warning("SUBJECTPRONOUN дёргается мелкой дрожью, будто по коже бегают пауки.")
	var/stacks = 0

/datum/status_effect/heretic_dance/tarantism/on_apply()
	. = ..()
	if(!.)
		return FALSE
	add_stack()
	return TRUE

/datum/status_effect/heretic_dance/tarantism/refresh()
	duration = world.time + initial(duration)
	add_stack()

/datum/status_effect/heretic_dance/tarantism/proc/add_stack()
	owner.cut_overlay(mutable_appearance('modular_bluemoon/icons/obj/heretic_dance_marks.dmi', "dance_tarantism_[clamp(stacks, 1, 5)]", ABOVE_MOB_LAYER))
	stacks++
	if(stacks >= 5)
		var/datum/eldritch_knowledge/base_dance/dance = dance()
		stacks = 0
		owner.apply_status_effect(/datum/status_effect/heretic_dance/frenzy, dance, 3 SECONDS)
		qdel(src)
		return
	owner.add_overlay(mutable_appearance('modular_bluemoon/icons/obj/heretic_dance_marks.dmi', "dance_tarantism_[stacks]", ABOVE_MOB_LAYER))

/datum/status_effect/heretic_dance/tarantism/on_dance_beat(datum/source, index, strong)
	heretic_dance_hop(owner, FALSE, TRUE, stacks)
	if(strong)
		owner.adjustStaminaLoss(4 * stacks)

/datum/status_effect/heretic_dance/tarantism/on_remove()
	if(stacks)
		owner.cut_overlay(mutable_appearance('modular_bluemoon/icons/obj/heretic_dance_marks.dmi', "dance_tarantism_[clamp(stacks, 1, 5)]", ABOVE_MOB_LAYER))
	return ..()

/atom/movable/screen/alert/status_effect/heretic_dance_tarantism
	name = "Тарантизм"
	desc = "Под кожей бегает дрожь, и каждый такт чужой музыки выматывает вас. Пять укусов сорвут вас в пляску."
	icon = 'modular_bluemoon/icons/obj/heretic_alerts.dmi'
	icon_state = "dance_tarantism"

/// Маскарад на еретике: он и заражённые рядом выглядят одинаковыми танцорами в масках.
/datum/status_effect/heretic_dance/masquerade
	id = "heretic_dance_masquerade"
	duration = HERETIC_DANCE_MASQUERADE_TIME
	alert_type = /atom/movable/screen/alert/status_effect/heretic_dance_masquerade
	var/list/mob/living/masked = list()

/datum/status_effect/heretic_dance/masquerade/on_creation(mob/living/new_owner, datum/eldritch_knowledge/base_dance/dance, time)
	if(time)
		duration = time
	return ..()

/datum/status_effect/heretic_dance/masquerade/on_apply()
	. = ..()
	if(!.)
		return FALSE
	var/datum/eldritch_knowledge/base_dance/dance = dance()
	dance.masquerade = src
	put_mask(owner)
	var/count = 0
	for(var/datum/status_effect/heretic_dance_earworm/earworm as anything in dance.earworms)
		if(count >= HERETIC_DANCE_MASQUERADE_DANCERS)
			break
		var/mob/living/carbon/human/dancer = earworm.owner
		if(!istype(dancer) || dancer.stat != CONSCIOUS || dancer.z != owner.z || get_dist(dancer, owner) > HERETIC_DANCE_INVITE_RANGE)
			continue
		if(dancer.apply_status_effect(/datum/status_effect/heretic_dance/masked, dance, duration, src))
			count++
	owner.pulledby?.stop_pulling()
	owner.add_movespeed_modifier(/datum/movespeed_modifier/heretic_dance_masquerade)
	playsound(owner, pick('modular_bluemoon/sound/heretic/dance/masquerade_1.ogg', 'modular_bluemoon/sound/heretic/dance/masquerade_2.ogg', 'modular_bluemoon/sound/heretic/dance/masquerade_3.ogg'), 70, TRUE)
	new /obj/effect/temp_visual/heretic_dance/confetti(get_turf(owner))
	return TRUE

/datum/status_effect/heretic_dance/masquerade/proc/put_mask(mob/living/wearer)
	var/image/mask = image('modular_bluemoon/icons/obj/heretic_dance.dmi', wearer, "dance_masked", wearer.layer)
	mask.override = TRUE
	wearer.add_alt_appearance(/datum/atom_hud/alternate_appearance/basic/everyone, "heretic_dance_mask", mask, FALSE)
	masked += wearer
	var/mob/living/carbon/human/human = wearer
	if(istype(human))
		human.name_override = DANCE_MASK_NAME
		human.name = DANCE_MASK_NAME
	RegisterSignal(wearer, COMSIG_MOB_APPLY_DAMAGE, PROC_REF(on_mask_hit))

/datum/status_effect/heretic_dance/masquerade/proc/take_mask(mob/living/wearer, broken = FALSE)
	if(!(wearer in masked))
		return
	masked -= wearer
	UnregisterSignal(wearer, COMSIG_MOB_APPLY_DAMAGE)
	wearer.remove_alt_appearance("heretic_dance_mask")
	var/mob/living/carbon/human/human = wearer
	if(istype(human) && human.name_override == DANCE_MASK_NAME)
		human.name_override = null
		human.name = human.get_visible_name()
	if(broken && isturf(wearer.loc))
		new /obj/effect/temp_visual/heretic_dance_mask_shards(wearer.loc)
		playsound(wearer, 'modular_bluemoon/sound/heretic/dance/mask_break.ogg', 50, TRUE)
		wearer.visible_message(span_warning("Фарфоровая маска на [wearer] трескается и осыпается: это [wearer.real_name]!"))

/datum/status_effect/heretic_dance/masquerade/proc/on_mask_hit(mob/living/source, damage, damagetype)
	SIGNAL_HANDLER
	if(damage <= 0 || !(damagetype in list(BRUTE, BURN)))
		return
	if(source == owner)
		take_mask(source, TRUE)
		return
	for(var/datum/status_effect/heretic_dance/masked/dancer in source.status_effects)
		if(dancer.masquerade == src)
			qdel(dancer)
			return
	take_mask(source, TRUE)

/datum/status_effect/heretic_dance/masquerade/on_remove()
	var/datum/eldritch_knowledge/base_dance/dance = dance()
	if(applied)
		for(var/mob/living/wearer as anything in masked.Copy())
			take_mask(wearer)
			for(var/datum/status_effect/heretic_dance/masked/dancer in wearer.status_effects)
				if(dancer.masquerade == src)
					qdel(dancer)
		owner.remove_movespeed_modifier(/datum/movespeed_modifier/heretic_dance_masquerade)
		if(dance?.masquerade == src)
			dance.masquerade = null
	masked.Cut()
	return ..()

/atom/movable/screen/alert/status_effect/heretic_dance_masquerade
	name = "Маскарад"
	desc = "Вы и заражённые рядом выглядите одинаковыми танцорами в масках. Попадание разбивает маску."
	icon = 'modular_bluemoon/icons/obj/heretic_alerts.dmi'
	icon_state = "dance_masquerade"

/datum/movespeed_modifier/heretic_dance_masquerade
	multiplicative_slowdown = -0.35

/// Танцор под маской: переминается каждую долю, пока маскарад держится.
/datum/status_effect/heretic_dance/masked
	id = "heretic_dance_masked"
	alert_type = /atom/movable/screen/alert/status_effect/heretic_dance_masked
	var/datum/status_effect/heretic_dance/masquerade/masquerade

/datum/status_effect/heretic_dance/masked/on_creation(mob/living/new_owner, datum/eldritch_knowledge/base_dance/dance, time, datum/status_effect/heretic_dance/masquerade/masquerade)
	duration = time || HERETIC_DANCE_MASQUERADE_TIME
	src.masquerade = masquerade
	return ..()

/datum/status_effect/heretic_dance/masked/on_apply()
	. = ..()
	if(!. || QDELETED(masquerade))
		return FALSE
	masquerade.put_mask(owner)
	to_chat(owner, span_userdanger("На лицо ложится холодная фарфоровая маска, и ноги пускаются в пляс!"))
	return TRUE

/datum/status_effect/heretic_dance/masked/on_dance_beat(datum/source, index, strong)
	heretic_dance_hop(owner, strong)
	INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(heretic_dance_stagger), owner)

/datum/status_effect/heretic_dance/masked/on_remove()
	if(applied && !QDELETED(masquerade))
		masquerade.take_mask(owner, TRUE)
	masquerade = null
	return ..()

/atom/movable/screen/alert/status_effect/heretic_dance_masked
	name = "Фарфоровая маска"
	desc = "Вы выглядите как безликий танцор в маске, и ноги пляшут сами. Любое попадание разобьёт маску."
	icon = 'modular_bluemoon/icons/obj/heretic_alerts.dmi'
	icon_state = "dance_masked"

/obj/effect/temp_visual/heretic_dance_mask_shards
	icon = 'modular_bluemoon/icons/obj/heretic_dance_marks.dmi'
	icon_state = "dance_mask_shards"
	duration = 0.8 SECONDS
	randomdir = FALSE
	layer = ABOVE_MOB_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/// Кортэ Танго не валит одну цель чаще раза в 6 секунд.
/datum/status_effect/heretic_dance_dipped
	id = "heretic_dance_dipped"
	duration = HERETIC_DANCE_ACCENT_LOCK
	alert_type = null
	status_type = STATUS_EFFECT_UNIQUE

/// Мах Канкана не бросает одну цель чаще раза в 6 секунд: у стены бросок роняет.
/datum/status_effect/heretic_dance_kicked
	id = "heretic_dance_kicked"
	duration = HERETIC_DANCE_ACCENT_LOCK
	alert_type = null
	status_type = STATUS_EFFECT_UNIQUE

/datum/status_effect/heretic_dance_stumble
	id = "heretic_dance_stumble"
	duration = 1 SECONDS
	alert_type = null
	status_type = STATUS_EFFECT_REFRESH

/datum/status_effect/heretic_dance_stumble/on_apply()
	. = ..()
	owner.add_movespeed_modifier(/datum/movespeed_modifier/heretic_dance_stumble)

/datum/status_effect/heretic_dance_stumble/on_remove()
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/heretic_dance_stumble)
	return ..()

/datum/movespeed_modifier/heretic_dance_stumble
	multiplicative_slowdown = 1

/// Пляска смерти: на каждой доле враги рядом вязнут на полсекунды.
/datum/status_effect/heretic_dance_dread
	id = "heretic_dance_dread"
	duration = 0.5 SECONDS
	alert_type = null
	status_type = STATUS_EFFECT_REFRESH

/datum/status_effect/heretic_dance_dread/on_apply()
	. = ..()
	owner.add_movespeed_modifier(/datum/movespeed_modifier/heretic_dance_dread)

/datum/status_effect/heretic_dance_dread/on_remove()
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/heretic_dance_dread)
	return ..()

/datum/movespeed_modifier/heretic_dance_dread
	multiplicative_slowdown = 0.5

/// Скелет вместо еретика для заражённых зрителей в стиле Пляски смерти.
/datum/atom_hud/alternate_appearance/basic/heretic_dance_skeleton
	var/datum/weakref/dance_ref

/datum/atom_hud/alternate_appearance/basic/heretic_dance_skeleton/New(key, image/I, datum/eldritch_knowledge/base_dance/dance)
	dance_ref = WEAKREF(dance)
	..(key, I, FALSE)
	for(var/mob/viewer in GLOB.player_list)
		if(mobShouldSee(viewer))
			add_hud_to(viewer)

/datum/atom_hud/alternate_appearance/basic/heretic_dance_skeleton/mobShouldSee(mob/viewer)
	var/datum/eldritch_knowledge/base_dance/dance = dance_ref?.resolve()
	var/mob/living/living_viewer = viewer
	if(!dance || !istype(living_viewer))
		return FALSE
	for(var/datum/status_effect/heretic_dance_earworm/earworm in living_viewer.status_effects)
		if(earworm.dance_ref?.resolve() == dance)
			return TRUE
	return FALSE

/datum/atom_hud/alternate_appearance/basic/heretic_dance_skeleton/proc/update_viewer(mob/viewer, removing = FALSE)
	if(!removing && mobShouldSee(viewer))
		add_hud_to(viewer)
	else
		remove_hud_from(viewer)

/datum/eldritch_knowledge/base_dance/proc/show_skeleton(mob/living/user)
	if(skeleton)
		return
	var/image/bones = image('modular_bluemoon/icons/obj/heretic_dance.dmi', user, "dance_skeleton", user.layer)
	bones.override = TRUE
	skeleton = user.add_alt_appearance(/datum/atom_hud/alternate_appearance/basic/heretic_dance_skeleton, "heretic_dance_skeleton", bones, src)

/datum/eldritch_knowledge/base_dance/proc/hide_skeleton()
	if(!skeleton)
		return
	var/datum/atom_hud/alternate_appearance/basic/heretic_dance_skeleton/bones = skeleton
	skeleton = null
	bones.target?.remove_alt_appearance("heretic_dance_skeleton")
	if(!QDELETED(bones))
		qdel(bones)

#undef DANCE_EARWORM_SLEEP_CURE
#undef DANCE_INVITE_CAPTURE
#undef DANCE_LEAD_CAPTURE
#undef DANCE_MASK_NAME
