#define DANCE_ENTRANCE_COOLDOWN (10 SECONDS)
#define DANCE_MEDLEY_WINDOW (20 SECONDS)
#define DANCE_MEDLEY_STYLES 3
#define DANCE_AURA_FILTER "heretic_dance_aura"

/particles/heretic_dance_aura
	icon = 'modular_bluemoon/icons/effects/heretic_particles.dmi'
	width = 96
	height = 96
	count = 10
	spawning = 0.4
	lifespan = 1.6 SECONDS
	fade = 0.6 SECONDS
	position = generator("circle", 6, 12)
	velocity = generator("circle", 0.5, 1)
	friction = 0.05

/particles/heretic_dance_aura/waltz
	icon_state = "dance_p_note"
	gravity = list(0, 0.08)
	spin = generator("num", -4, 4)

/particles/heretic_dance_aura/tango
	icon_state = "dance_p_petal"
	gravity = list(0, -0.1)
	spin = generator("num", -10, 10)

/particles/heretic_dance_aura/tarantella
	icon_state = "dance_p_spider"
	spawning = 0.7
	lifespan = 1 SECONDS
	velocity = generator("circle", 1.5, 2.5)

/particles/heretic_dance_aura/cancan
	icon_state = list("dance_confetti_1" = 1, "dance_confetti_2" = 1, "dance_confetti_3" = 1)
	spawning = 0.6
	velocity = generator("box", list(-1.5, 1.5, 0), list(1.5, 3, 0))
	gravity = list(0, -0.15)
	spin = generator("num", -12, 12)

/particles/heretic_dance_aura/macabre
	icon_state = "dance_p_bone"
	spawning = 0.3
	lifespan = 2.2 SECONDS
	gravity = list(0, -0.04)

/datum/heretic_dance_style
	var/aura_particles

/datum/heretic_dance_style/waltz
	aura_particles = /particles/heretic_dance_aura/waltz

/datum/heretic_dance_style/tango
	aura_particles = /particles/heretic_dance_aura/tango

/datum/heretic_dance_style/tarantella
	aura_particles = /particles/heretic_dance_aura/tarantella

/datum/heretic_dance_style/cancan
	aura_particles = /particles/heretic_dance_aura/cancan

/datum/heretic_dance_style/macabre
	aura_particles = /particles/heretic_dance_aura/macabre

/datum/heretic_dance_style/proc/entrance_text()
	return ""

/// Вход в стиль связкой посреди боя; power 2 - под Попурри.
/datum/heretic_dance_style/proc/entrance(datum/eldritch_knowledge/base_dance/dance, mob/living/user, power = 1)
	return

/datum/heretic_dance_style/waltz/entrance_text()
	return "3 секунды вы заметно быстрее"

/datum/heretic_dance_style/waltz/entrance(datum/eldritch_knowledge/base_dance/dance, mob/living/user, power = 1)
	user.apply_status_effect(/datum/status_effect/heretic_dance_glide, 3 SECONDS * power)

/datum/heretic_dance_style/tango/entrance_text()
	return "следующий удар клинком в 3 секунды +8 ушибов"

/datum/heretic_dance_style/tango/entrance(datum/eldritch_knowledge/base_dance/dance, mob/living/user, power = 1)
	dance.entrance_strike_until = world.time + 3 SECONDS
	dance.entrance_strike_bonus = 8 * power

/datum/heretic_dance_style/tarantella/entrance_text()
	return "всем врагам вплотную стак тарантизма"

/datum/heretic_dance_style/tarantella/entrance(datum/eldritch_knowledge/base_dance/dance, mob/living/user, power = 1)
	for(var/mob/living/carbon/victim in orange(1, user))
		if(!heretic_can_affect(user, victim, chargecost = 0, notify = FALSE))
			continue
		for(var/bite in 1 to power)
			victim.apply_status_effect(/datum/status_effect/heretic_dance/tarantism, dance)

/datum/heretic_dance_style/cancan/entrance_text()
	return "врагов вплотную отбрасывает на клетку"

/datum/heretic_dance_style/cancan/entrance(datum/eldritch_knowledge/base_dance/dance, mob/living/user, power = 1)
	for(var/mob/living/carbon/victim in orange(1, user))
		if(!heretic_can_affect(user, victim, chargecost = 0, notify = FALSE) || victim.anchored || victim.buckled || !isturf(victim.loc))
			continue
		victim.throw_at(get_ranged_target_turf(victim, get_dir(user, victim), power), power, 1, user, spin = FALSE)

/datum/heretic_dance_style/macabre/entrance_text()
	return "враги в 3 клетках 2 секунды вязнут"

/datum/heretic_dance_style/macabre/entrance(datum/eldritch_knowledge/base_dance/dance, mob/living/user, power = 1)
	for(var/mob/living/carbon/victim in range(3, user))
		if(heretic_can_affect(user, victim, chargecost = 0, notify = FALSE) && heretic_edge_line_clear(user, victim))
			victim.apply_status_effect(/datum/status_effect/heretic_dance_dirge, 2 SECONDS * power)

/datum/eldritch_knowledge/base_dance
	var/obj/effect/abstract/heretic_particle_holder/aura
	var/entrance_strike_until = 0
	var/entrance_strike_bonus = 0
	/// Стиль -> когда в него последний раз входили связкой в бою.
	var/list/medley_entries = list()
	var/list/entrance_ready_at = list()

/datum/eldritch_knowledge/base_dance/proc/show_aura()
	hide_aura()
	var/datum/heretic_dance_style/style = current_style()
	if(!dance_body || !style.aura_particles)
		return
	aura = heretic_vfx_attach_particles(dance_body, style.aura_particles, FALSE)
	dance_body.add_filter(DANCE_AURA_FILTER, 3, drop_shadow_filter(x = 0, y = 0, size = 2, color = "[style.color]66"))

/datum/eldritch_knowledge/base_dance/proc/hide_aura()
	if(aura)
		heretic_vfx_release_particles(dance_body, aura)
		aura = null
	dance_body?.remove_filter(DANCE_AURA_FILTER)

/datum/eldritch_knowledge/base_dance/proc/update_style_status()
	if(QDELETED(dance_body))
		return
	var/datum/status_effect/heretic_dance_style/status = dance_body.has_status_effect(/datum/status_effect/heretic_dance_style)
	if(!status)
		status = dance_body.apply_status_effect(/datum/status_effect/heretic_dance_style, src)
	status?.refresh_style()

/datum/eldritch_knowledge/base_dance/proc/medley_count()
	. = 0
	for(var/id in medley_entries)
		if(world.time - medley_entries[id] <= DANCE_MEDLEY_WINDOW)
			.++

/// Смена стиля связкой в бою: вход нового стиля, три разных стиля за 20 секунд - Попурри.
/datum/eldritch_knowledge/base_dance/proc/style_entrance(mob/living/user)
	if(!in_combat())
		return FALSE
	medley_entries[style_id] = world.time
	if(world.time < (entrance_ready_at[style_id] || 0))
		return FALSE
	entrance_ready_at[style_id] = world.time + DANCE_ENTRANCE_COOLDOWN
	var/medley = medley_count() >= DANCE_MEDLEY_STYLES
	var/datum/heretic_dance_style/style = current_style()
	style.entrance(src, user, medley ? 2 : 1)
	new /obj/effect/temp_visual/heretic_dance/accent(get_turf(user), style.id)
	if(medley)
		new /obj/effect/temp_visual/heretic_dance/potpourri(get_turf(user))
		playsound(user, 'modular_bluemoon/sound/heretic/dance/potpourri.ogg', 60, FALSE)
		user.visible_message(span_danger("[user] сплетает все танцы в одно попурри!"))
		user.balloon_alert(user, "попурри!")
	to_chat(user, span_eldritch("Вход в [lowertext(style.name)]: [style.entrance_text()][medley ? " - вдвойне, Попурри" : ""]."))
	update_style_status()
	return TRUE

/datum/status_effect/heretic_dance_style
	id = "heretic_dance_style"
	duration = -1
	tick_interval = -1
	status_type = STATUS_EFFECT_UNIQUE
	alert_type = /atom/movable/screen/alert/status_effect/heretic_dance_style
	var/datum/weakref/dance_ref

/datum/status_effect/heretic_dance_style/on_creation(mob/living/new_owner, datum/eldritch_knowledge/base_dance/dance)
	dance_ref = WEAKREF(dance)
	return ..()

/datum/status_effect/heretic_dance_style/proc/refresh_style()
	var/datum/eldritch_knowledge/base_dance/dance = dance_ref?.resolve()
	if(!dance || !linked_alert)
		return
	var/datum/heretic_dance_style/style = dance.current_style()
	linked_alert.icon_state = "dance_style_[style.id]"
	linked_alert.name = "Стиль: [style.name]"
	var/medley = dance.medley_count()
	linked_alert.desc = "С 4 Такта: [style.passive_text]. Акцент в сильную долю: [style.accent_text]. Фигура «[style.figure_name]»: [style.figure_text]. Вход связкой в бою: [style.entrance_text()]. Разных стилей за 20 секунд боя: [medley] из [DANCE_MEDLEY_STYLES][medley >= DANCE_MEDLEY_STYLES ? " - Попурри удваивает входы" : ""]."

/atom/movable/screen/alert/status_effect/heretic_dance_style
	name = "Стиль"
	desc = "Текущий танец."
	icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	icon_state = "dance_style_waltz"

/datum/status_effect/heretic_dance_glide
	id = "heretic_dance_glide"
	alert_type = null
	status_type = STATUS_EFFECT_REPLACE

/datum/status_effect/heretic_dance_glide/on_creation(mob/living/new_owner, time)
	duration = time || 3 SECONDS
	return ..()

/datum/status_effect/heretic_dance_glide/on_apply()
	. = ..()
	owner.add_movespeed_modifier(/datum/movespeed_modifier/heretic_dance_glide)

/datum/status_effect/heretic_dance_glide/on_remove()
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/heretic_dance_glide)
	return ..()

/datum/movespeed_modifier/heretic_dance_glide
	multiplicative_slowdown = -0.4

/datum/status_effect/heretic_dance_dirge
	id = "heretic_dance_dirge"
	alert_type = null
	status_type = STATUS_EFFECT_REPLACE

/datum/status_effect/heretic_dance_dirge/on_creation(mob/living/new_owner, time)
	duration = time || 2 SECONDS
	return ..()

/datum/status_effect/heretic_dance_dirge/on_apply()
	. = ..()
	owner.add_movespeed_modifier(/datum/movespeed_modifier/heretic_dance_dread)

/datum/status_effect/heretic_dance_dirge/on_remove()
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/heretic_dance_dread)
	return ..()

#undef DANCE_ENTRANCE_COOLDOWN
#undef DANCE_MEDLEY_WINDOW
#undef DANCE_MEDLEY_STYLES
#undef DANCE_AURA_FILTER
