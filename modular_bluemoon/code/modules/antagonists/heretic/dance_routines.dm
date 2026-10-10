#define DANCE_INVITE_CAPTURE "dance_invite"
#define DANCE_ROUTINE_TIME (8 SECONDS)
#define DANCE_ROUTINE_COOLDOWN (30 SECONDS)
#define DANCE_ROUTINE_HOROVOD_TIME (6 SECONDS)
#define DANCE_ROUTINE_HOROVOD_LIMIT 6
#define DANCE_ROUTINE_HOROVOD_RANGE 4
#define DANCE_ROUTINE_PARTNER_TIME (3 SECONDS)
#define DANCE_ROUTINE_FRENZY_TIME (6 SECONDS)
#define DANCE_ROUTINE_BITE_BURST 32
#define DANCE_ROUTINE_DASH 6
#define DANCE_ROUTINE_MASK_TIME (4 SECONDS)
#define DANCE_ROUTINE_GLIDE_TIME (3 SECONDS)

GLOBAL_LIST_INIT(heretic_dance_routines, init_heretic_dance_routines())

/proc/init_heretic_dance_routines()
	. = list()
	for(var/routine_type in list(/datum/heretic_dance_routine/pas_de_deux, /datum/heretic_dance_routine/death_tango, /datum/heretic_dance_routine/danse_macabre, /datum/heretic_dance_routine/vanishing))
		var/datum/heretic_dance_routine/routine = new routine_type
		.[routine.id] = routine

/// Номер: фигура, связка в другой стиль и его фигура подряд.
/datum/heretic_dance_routine
	var/id
	var/name
	var/from_style
	var/to_style
	var/sound

/datum/heretic_dance_routine/proc/can_arm(datum/eldritch_knowledge/base_dance/dance, mob/living/user)
	return TRUE

/datum/heretic_dance_routine/proc/on_armed(datum/eldritch_knowledge/base_dance/dance, mob/living/user)
	return

/// Вторая фигура номера; FALSE - номер не сложился, и фигура срабатывает как обычно.
/datum/heretic_dance_routine/proc/perform(datum/eldritch_knowledge/base_dance/dance, mob/living/user, mob/living/focus)
	return FALSE

/datum/heretic_dance_routine/pas_de_deux
	id = "pas_de_deux"
	sound = 'modular_bluemoon/sound/heretic/dance/routine_pas_de_deux.ogg'
	name = "Па-де-де"
	from_style = HERETIC_DANCE_STYLE_WALTZ
	to_style = HERETIC_DANCE_STYLE_TANGO

/datum/heretic_dance_routine/pas_de_deux/can_arm(datum/eldritch_knowledge/base_dance/dance, mob/living/user)
	return !isnull(dance.led_partner())

/datum/heretic_dance_routine/pas_de_deux/on_armed(datum/eldritch_knowledge/base_dance/dance, mob/living/user)
	var/mob/living/partner = dance.led_partner()
	var/datum/status_effect/heretic_dance/lead/lead = partner?.has_status_effect(/datum/status_effect/heretic_dance/lead)
	lead?.extend_until(dance.routine_until)

/datum/heretic_dance_routine/pas_de_deux/perform(datum/eldritch_knowledge/base_dance/dance, mob/living/user, mob/living/focus)
	var/mob/living/partner = dance.led_partner()
	if(!partner || get_dist(user, partner) > 1 || heretic_capture_block_reason(user, partner, DANCE_INVITE_CAPTURE, ignore_shared = TRUE))
		return FALSE
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/time = heretic?.hunt_target && heretic.hunt_target == partner.mind ? HERETIC_DANCE_PARTNER_TIME : DANCE_ROUTINE_PARTNER_TIME
	partner.remove_status_effect(/datum/status_effect/heretic_dance/lead)
	if(!partner.apply_status_effect(/datum/status_effect/heretic_dance/partner, dance, time))
		return FALSE
	heretic_dance_lunge(user, partner)
	heretic_dance_dip(partner, user)
	partner.visible_message(span_danger("[user] опрокидывает [partner] в кортэ, и [partner] застывает в чужих руках!"), span_userdanger("Вас опрокинули в кортэ: вы застыли в чужих руках!"))
	log_combat(user, partner, "опрокидывает в па-де-де")
	dance.announce_partner(user, partner, time)
	return TRUE

/datum/heretic_dance_routine/death_tango
	id = "death_tango"
	sound = 'modular_bluemoon/sound/heretic/dance/routine_death_tango.ogg'
	name = "Танго смерти"
	from_style = HERETIC_DANCE_STYLE_TANGO
	to_style = HERETIC_DANCE_STYLE_TARANTELLA

/datum/heretic_dance_routine/death_tango/perform(datum/eldritch_knowledge/base_dance/dance, mob/living/user, mob/living/focus)
	if(QDELETED(focus))
		return FALSE
	focus.adjustBruteLoss(DANCE_ROUTINE_BITE_BURST)
	qdel(focus.has_status_effect(/datum/status_effect/heretic_dance/tarantism))
	var/datum/status_effect/heretic_dance/frenzy/frenzy = focus.has_status_effect(/datum/status_effect/heretic_dance/frenzy)
	if(frenzy)
		frenzy.duration = max(frenzy.duration, world.time + DANCE_ROUTINE_FRENZY_TIME)
	else
		focus.apply_status_effect(/datum/status_effect/heretic_dance/frenzy, dance, DANCE_ROUTINE_FRENZY_TIME)
	return TRUE

/datum/heretic_dance_routine/danse_macabre
	id = "danse_macabre"
	sound = 'modular_bluemoon/sound/heretic/dance/routine_danse_macabre.ogg'
	name = "Пляска мертвецов"
	from_style = HERETIC_DANCE_STYLE_CANCAN
	to_style = HERETIC_DANCE_STYLE_MACABRE

/datum/heretic_dance_routine/danse_macabre/perform(datum/eldritch_knowledge/base_dance/dance, mob/living/user, mob/living/focus)
	return dance.start_horovod(user, DANCE_ROUTINE_HOROVOD_TIME, DANCE_ROUTINE_HOROVOD_LIMIT, DANCE_ROUTINE_HOROVOD_RANGE)

/datum/heretic_dance_routine/vanishing
	id = "vanishing"
	sound = 'modular_bluemoon/sound/heretic/dance/routine_vanishing.ogg'
	name = "Исчезновение"
	from_style = HERETIC_DANCE_STYLE_MACABRE
	to_style = HERETIC_DANCE_STYLE_CANCAN

/datum/heretic_dance_routine/vanishing/perform(datum/eldritch_knowledge/base_dance/dance, mob/living/user, mob/living/focus)
	dance.cancan_dash(user, DANCE_ROUTINE_DASH)
	if(QDELETED(dance.masquerade))
		user.apply_status_effect(/datum/status_effect/heretic_dance/masquerade, dance, DANCE_ROUTINE_MASK_TIME)
	user.apply_status_effect(/datum/status_effect/heretic_dance_glide, DANCE_ROUTINE_GLIDE_TIME)
	return TRUE

/datum/eldritch_knowledge/base_dance
	/// Стиль только что сработавшей фигуры: связка из него до routine_link_until начинает номер.
	var/routine_from
	var/routine_link_until = 0
	var/datum/heretic_dance_routine/armed_routine
	var/routine_until = 0
	var/routine_ready_at = 0

/datum/eldritch_knowledge/base_dance/proc/routine_from_style(from_id)
	for(var/id in GLOB.heretic_dance_routines)
		var/datum/heretic_dance_routine/routine = GLOB.heretic_dance_routines[id]
		if(routine.from_style == from_id && style_known(routine.to_style))
			return routine
	return null

/datum/eldritch_knowledge/base_dance/proc/offered_routine()
	return routine_from && world.time <= routine_link_until ? routine_from_style(routine_from) : null

/datum/eldritch_knowledge/base_dance/proc/led_partner()
	for(var/mob/living/dancer as anything in dancers)
		for(var/datum/status_effect/heretic_dance/lead/lead in dancer.status_effects)
			if(lead.dance_ref?.resolve() == src)
				return dancer
	return null

/// Сработавшая фигура предлагает номер до конца следующего такта.
/datum/eldritch_knowledge/base_dance/proc/open_routine(mob/living/user, datum/heretic_dance_style/style)
	var/datum/heretic_dance_routine/routine = routine_from_style(style.id)
	if(!routine || (!bolero_active() && world.time < routine_ready_at))
		return
	routine_from = style.id
	routine_link_until = world.time + beat_ds * (meter + 1)
	var/datum/heretic_dance_style/next = GLOB.heretic_dance_styles[routine.to_style]
	user.balloon_alert(user, "номер: связка в [lowertext(next.name)]")
	pulse_hud(FALSE, FALSE)

/// Смена стиля в сильную долю сразу после фигуры начинает номер; allowed - смена не торопливая.
/datum/eldritch_knowledge/base_dance/proc/arm_routine(mob/living/user, allowed)
	var/datum/heretic_dance_routine/routine = allowed ? offered_routine() : null
	routine_from = null
	armed_routine = null
	if(routine?.to_style != style_id || !routine.can_arm(src, user))
		return FALSE
	armed_routine = routine
	routine_until = world.time + DANCE_ROUTINE_TIME
	routine.on_armed(src, user)
	var/datum/heretic_dance_style/style = current_style()
	user.balloon_alert(user, "номер «[routine.name]»: [style.figure_name]!")
	to_chat(user, span_eldritch("Номер «[routine.name]»: соберите фигуру «[style.figure_name]» за [DisplayTimeText(DANCE_ROUTINE_TIME)]."))
	SEND_SIGNAL(src, COMSIG_HERETIC_DANCE_EVENT, "routine_armed", user, routine.id)
	return TRUE

/// Фигура стиля, начатого номером: TRUE - номер исполнен вместо обычной фигуры.
/datum/eldritch_knowledge/base_dance/proc/try_routine(mob/living/user, mob/living/focus)
	if(!armed_routine || armed_routine.to_style != style_id || world.time > routine_until)
		return FALSE
	var/datum/heretic_dance_routine/routine = armed_routine
	var/turf/stage = get_turf(focus || user)
	if(!routine.perform(src, user, focus))
		return FALSE
	armed_routine = null
	if(!bolero_active())
		routine_ready_at = world.time + DANCE_ROUTINE_COOLDOWN
	routine_fx(user, routine, stage)
	SEND_SIGNAL(src, COMSIG_HERETIC_DANCE_EVENT, "routine", user, routine.id)
	return TRUE

/// Кульминация номера на клетке, где он начался: рывок Исчезновения уносит танцора, а сцена остаётся.
/datum/eldritch_knowledge/base_dance/proc/routine_fx(mob/living/user, datum/heretic_dance_routine/routine, turf/stage)
	if(!stage)
		return
	var/datum/heretic_dance_style/style = current_style()
	new /obj/effect/temp_visual/heretic_dance/routine(stage, routine.id, user.dir)
	playsound(stage, routine.sound, 70, FALSE)
	style.figure_pose(src, user)
	user.visible_message(span_danger("[user] исполняет номер «[routine.name]»!"), span_eldritch("Номер «[routine.name]»!"))

/obj/effect/temp_visual/heretic_dance/routine
	duration = 1.3 SECONDS

/obj/effect/temp_visual/heretic_dance/routine/Initialize(mapload, routine_id, facing)
	icon_state = "dance_routine_[routine_id]"
	if(facing)
		dir = facing
	return ..()

/datum/status_effect/heretic_dance/lead/proc/extend_until(until)
	if(until <= duration)
		return
	duration = until
	QDEL_NULL(ribbon)
	ribbon = heretic_dance_ribbon(leader(), owner, until - world.time)

#undef DANCE_INVITE_CAPTURE
#undef DANCE_ROUTINE_TIME
#undef DANCE_ROUTINE_COOLDOWN
#undef DANCE_ROUTINE_HOROVOD_TIME
#undef DANCE_ROUTINE_HOROVOD_LIMIT
#undef DANCE_ROUTINE_HOROVOD_RANGE
#undef DANCE_ROUTINE_FRENZY_TIME
#undef DANCE_ROUTINE_BITE_BURST
#undef DANCE_ROUTINE_PARTNER_TIME
#undef DANCE_ROUTINE_DASH
#undef DANCE_ROUTINE_MASK_TIME
#undef DANCE_ROUTINE_GLIDE_TIME
