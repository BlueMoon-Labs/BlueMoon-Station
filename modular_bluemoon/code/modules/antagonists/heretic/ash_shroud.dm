#define HERETIC_ASH_FX 'modular_bluemoon/icons/obj/heretic_ash_fx.dmi'
#define HERETIC_ASH_SHROUD_FORM_VOLUME 45
#define HERETIC_ASH_SHROUD_BREAK_VOLUME 50
#define HERETIC_ASH_SHROUD_FADE (0.4 SECONDS)
#define HERETIC_ASH_SHROUD_SHATTER_TIME (1.2 SECONDS)
#define HERETIC_ASH_SHROUD_WASHED "washed"
#define HERETIC_ASH_SHROUD_CRACKED "cracked"

/datum/eldritch_knowledge/base_ash
	var/list/datum/status_effect/heretic_ash_shroud/shrouds = list()
	/// Почему последний саван не лёг или осыпался.
	var/shroud_failure
	COOLDOWN_DECLARE(shroud_cooldown)

/datum/eldritch_knowledge/ash_mark/on_mark_detonated(mob/living/user, mob/living/target)
	. = ..()
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_ash/ash = heretic?.get_knowledge(/datum/eldritch_knowledge/base_ash)
	ash?.try_shroud(user, target)

/datum/eldritch_knowledge/ash_mark/on_body_lose(mob/living/user)
	. = ..()
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_ash/ash = heretic?.get_knowledge(/datum/eldritch_knowledge/base_ash)
	if(ash)
		QDEL_LIST(ash.shrouds)

/datum/eldritch_knowledge/base_ash/on_death(mob/user)
	. = ..()
	QDEL_LIST(shrouds)

/datum/eldritch_knowledge/base_ash/proc/shroud_on(mob/living/victim)
	for(var/datum/status_effect/heretic_ash_shroud/shroud as anything in shrouds)
		if(shroud.owner == victim)
			return shroud
	return null

/datum/eldritch_knowledge/base_ash/proc/shroud_block_reason(mob/living/user, mob/living/victim, check_ready = TRUE)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(!heretic || heretic.get_knowledge(type) != src || !heretic.get_knowledge(/datum/eldritch_knowledge/ash_mark) || user.stat == DEAD)
		return "Саван недоступен вашему пути или телу."
	if(!ishuman(victim))
		return "Саван запекается только на людях."
	var/reason = heretic_capture_block_reason(user, victim, HERETIC_ASH_SHROUD_CAPTURE)
	if(reason)
		return reason
	if(victim.has_status_effect(/datum/status_effect/heretic_ash_shroud))
		return "Цель уже в саване."
	if(!isturf(victim.loc))
		return "Цель должна лежать на полу."
	if(check_ready && !COOLDOWN_FINISHED(src, shroud_cooldown))
		return "Пепел ещё не остыл после прошлого савана: осталось [heretic_capture_seconds_left(shroud_cooldown)] с."
	return null

/// Взрыв метки по горящей сбитой цели запекает огонь на ней в саван; по стоящей или негорящей цели он молчит.
/datum/eldritch_knowledge/base_ash/proc/try_shroud(mob/living/user, mob/living/victim)
	if(!isliving(victim) || !victim.on_fire || !heretic_capture_downed(victim))
		return FALSE
	shroud_failure = shroud_block_reason(user, victim)
	if(shroud_failure)
		to_chat(user, span_warning("Пепельный саван: [shroud_failure]"))
		return FALSE
	COOLDOWN_START(src, shroud_cooldown, HERETIC_ASH_SHROUD_COOLDOWN)
	var/turf/place = get_turf(victim)
	var/obj/effect/abstract/heretic_vfx_attached/ash_crust/forming = new(null, victim, "shroud_forming")
	addtimer(CALLBACK(src, PROC_REF(seal_shroud), user, victim, place, forming), HERETIC_ASH_SHROUD_TELEGRAPH)
	victim.visible_message(span_danger("Пламя на [victim] оседает и спекается серой коркой пепла!"), span_userdanger("Огонь на вас оседает пеплом и стягивает тело коркой! Вода ещё может его смыть."))
	playsound(place, HERETIC_ASH_BAKE_SOUND, HERETIC_ASH_SHROUD_FORM_VOLUME, TRUE, SHORT_RANGE_SOUND_EXTRARANGE)
	return TRUE

/datum/eldritch_knowledge/base_ash/proc/seal_shroud(mob/living/user, mob/living/victim, turf/place, obj/effect/abstract/heretic_vfx_attached/ash_crust/forming)
	if(!QDELETED(forming))
		forming.fade_out(HERETIC_ASH_SHROUD_FADE)
	if(QDELETED(src) || QDELETED(user))
		return FALSE
	if(QDELETED(victim) || victim.loc != place)
		return refund_shroud(user, "Цель ушла с места, и пепел осыпался.")
	if(!victim.on_fire)
		return refund_shroud(user, "Огонь на цели сбили раньше, чем он запёкся.")
	var/reason = shroud_block_reason(user, victim, check_ready = FALSE)
	if(reason)
		return refund_shroud(user, "Саван осыпался: [reason]")
	if(!victim.apply_status_effect(/datum/status_effect/heretic_ash_shroud, src, user))
		return refund_shroud(user, "Саван не лёг.")
	log_combat(user, victim, "запекает в пепельный саван")
	return TRUE

/datum/eldritch_knowledge/base_ash/proc/refund_shroud(mob/living/user, reason)
	shroud_failure = reason
	COOLDOWN_RESET(src, shroud_cooldown)
	to_chat(user, span_warning("[reason] Перезарядка савана возвращена."))
	return FALSE

/datum/status_effect/heretic_ash_shroud
	id = "heretic_ash_shroud"
	duration = HERETIC_ASH_SHROUD_DURATION
	tick_interval = -1
	status_type = STATUS_EFFECT_UNIQUE
	on_remove_on_mob_delete = TRUE
	alert_type = /atom/movable/screen/alert/status_effect/heretic_ash_shroud
	examine_text = span_warning("SUBJECTPRONOUN скован коркой пепла, в трещинах тлеют угли. Корку смоет вода или пена, рассеет нулевой жезл, расколет любой удар, а ещё её можно растолкать за 2 секунды.")
	var/held_since = 0
	var/datum/weakref/ash_ref
	var/datum/weakref/heretic_ref
	var/datum/status_effect/incapacitating/paralyzed/heretic_ritual/restraint
	var/obj/effect/abstract/heretic_vfx_attached/ash_crust/crust
	var/obj/effect/abstract/heretic_particle_holder/flakes
	var/release_cause
	var/static/list/ash_tint = list(0.17, 0.16, 0.15, 0.33, 0.31, 0.29, 0.07, 0.06, 0.06, 0.1, 0.09, 0.08)

/datum/status_effect/heretic_ash_shroud/on_creation(mob/living/new_owner, datum/eldritch_knowledge/base_ash/ash, mob/living/heretic_body)
	ash_ref = WEAKREF(ash)
	heretic_ref = WEAKREF(heretic_body)
	return ..()

/datum/status_effect/heretic_ash_shroud/on_apply()
	. = ..()
	if(!.)
		return
	var/datum/eldritch_knowledge/base_ash/ash = ash_ref?.resolve()
	ash?.shrouds += src
	held_since = world.time
	owner.ExtinguishMob()
	restraint = new(list(owner, HERETIC_ASH_SHROUD_DURATION, TRUE))
	ADD_TRAIT(owner, TRAIT_MUTE, HERETIC_ASH_SHROUD_CAPTURE)
	owner.add_atom_colour(ash_tint, TEMPORARY_COLOUR_PRIORITY)
	crust = new(null, owner, "shroud_crust")
	flakes = heretic_vfx_attach_particles(owner, /particles/heretic_ascension/ash/shroud_flakes, FALSE)
	RegisterSignal(owner, COMSIG_ATOM_EXPOSE_REAGENTS, PROC_REF(on_exposed))
	RegisterSignal(owner, COMSIG_PARENT_ATTACKBY, PROC_REF(on_attackby))
	RegisterSignal(owner, COMSIG_MOB_APPLY_DAMAGE, PROC_REF(on_damaged))
	RegisterSignal(owner, COMSIG_MOVABLE_MOVED, PROC_REF(on_moved))
	RegisterSignals(owner, list(COMSIG_MOVABLE_Z_CHANGED, COMSIG_LIVING_HERETIC_SACRIFICE_STARTING, COMSIG_LIVING_HERETIC_CAPTURE_SHAKEN), PROC_REF(end_shroud))
	heretic_capture_hold(owner, HERETIC_ASH_SHROUD_CAPTURE)
	heretic_capture_lock_pull(owner, heretic_ref?.resolve(), REF(src))
	owner.visible_message(span_warning("Огонь на [owner] спекается в корку пепла, в трещинах тлеют угли."), span_userdanger("Пепел запёкся на вас коркой: не пошевелиться и не крикнуть!"))

/datum/status_effect/heretic_ash_shroud/proc/on_exposed(atom/source, list/reagents)
	SIGNAL_HANDLER
	for(var/datum/reagent/reagent as anything in reagents)
		if(istype(reagent, /datum/reagent/water) || istype(reagent, /datum/reagent/firefighting_foam))
			release_cause = HERETIC_ASH_SHROUD_WASHED
			owner.visible_message(span_notice("Вода смывает пепел с [owner], угли в трещинах шипят и гаснут."))
			qdel(src)
			return

/datum/status_effect/heretic_ash_shroud/proc/on_attackby(mob/living/source, obj/item/item, mob/living/user, params)
	SIGNAL_HANDLER
	if(!istype(item, /obj/item/nullrod))
		return NONE
	user.visible_message(span_warning("[user] касается [source] нулевым жезлом, и пепельная корка осыпается."), span_notice("Вы касаетесь [source] нулевым жезлом, и корка осыпается."))
	log_game("[key_name(user)] снимает пепельный саван с [key_name(source)] нулевым жезлом в [AREACOORD(source)].")
	qdel(src)
	return COMPONENT_NO_AFTERATTACK

/datum/status_effect/heretic_ash_shroud/proc/on_damaged(datum/source, damage, damagetype)
	SIGNAL_HANDLER
	if(damage < HERETIC_ASH_SHROUD_CRACK_DAMAGE || (damagetype != BRUTE && damagetype != BURN))
		return
	release_cause = HERETIC_ASH_SHROUD_CRACKED
	owner.visible_message(span_warning("Пепельная корка на [owner] раскалывается от удара!"))
	qdel(src)

/// Тащить цель шагами можно, переход сквозь завесу или телепорт срывают корку.
/datum/status_effect/heretic_ash_shroud/proc/on_moved(datum/source, atom/old_loc)
	SIGNAL_HANDLER
	if(!isturf(owner.loc) || !isturf(old_loc) || old_loc.z != owner.z || get_dist(old_loc, owner.loc) > 1)
		qdel(src)

/datum/status_effect/heretic_ash_shroud/proc/end_shroud(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/datum/status_effect/heretic_ash_shroud/on_remove()
	UnregisterSignal(owner, list(COMSIG_ATOM_EXPOSE_REAGENTS, COMSIG_PARENT_ATTACKBY, COMSIG_MOB_APPLY_DAMAGE, COMSIG_MOVABLE_MOVED, COMSIG_MOVABLE_Z_CHANGED, COMSIG_LIVING_HERETIC_SACRIFICE_STARTING, COMSIG_LIVING_HERETIC_CAPTURE_SHAKEN))
	heretic_capture_unhold(owner, HERETIC_ASH_SHROUD_CAPTURE)
	heretic_capture_unlock_pull(owner, REF(src))
	// Чужой Paralyze мог продлить этот экземпляр: тогда он остаётся.
	if(!QDELETED(restraint) && restraint.duration <= duration)
		qdel(restraint)
	restraint = null
	REMOVE_TRAIT(owner, TRAIT_MUTE, HERETIC_ASH_SHROUD_CAPTURE)
	owner.remove_atom_colour(TEMPORARY_COLOUR_PRIORITY, ash_tint)
	shatter()
	var/datum/eldritch_knowledge/base_ash/ash = ash_ref?.resolve()
	ash?.shrouds -= src
	ash_ref = null
	heretic_ref = null
	heretic_capture_release(owner, HERETIC_ASH_SHROUD_CAPTURE, held_for = heretic_capture_held_for(held_since))
	return ..()

/// Корка трескается и осыпается к ногам; смытая водой уходит паром.
/datum/status_effect/heretic_ash_shroud/proc/shatter()
	QDEL_NULL(crust)
	heretic_vfx_release_particles(owner, flakes)
	flakes = null
	var/turf/place = get_turf(owner)
	if(!place)
		return
	new /obj/effect/temp_visual/heretic_ash_shroud_shatter(place)
	if(release_cause == HERETIC_ASH_SHROUD_WASHED)
		heretic_vfx_burst(place, /particles/heretic_ascension/steam)
	playsound(place, 'modular_bluemoon/sound/heretic/ash_crumble.ogg', HERETIC_ASH_SHROUD_BREAK_VOLUME, TRUE, SHORT_RANGE_SOUND_EXTRARANGE)

/atom/movable/screen/alert/status_effect/heretic_ash_shroud
	name = "Пепельный саван"
	desc = "Огонь на вас запёкся коркой пепла: вы не двигаетесь и не можете говорить. Корку смоет вода или пена из огнетушителя, рассеет нулевой жезл, расколет любой удар, а ещё вас могут растолкать за 2 секунды."
	icon = 'modular_bluemoon/icons/obj/heretic_alerts.dmi'
	icon_state = "ash_shroud"

/// Корка лежит на теле и поворачивается вместе с ним; светятся только трещины.
/obj/effect/abstract/heretic_vfx_attached/ash_crust
	vis_flags = VIS_INHERIT_PLANE | VIS_INHERIT_DIR

/obj/effect/abstract/heretic_vfx_attached/ash_crust/Initialize(mapload, atom/movable/host, state)
	. = ..(mapload, host, HERETIC_ASH_FX, state, 255, HERETIC_ASH_SHROUD_FADE, FALSE, FALSE)
	if(. == INITIALIZE_HINT_QDEL)
		return
	add_overlay(emissive_appearance(icon, "[state]_glow", offset_spokesman = host))

/obj/effect/temp_visual/heretic_ash_shroud_shatter
	icon = HERETIC_ASH_FX
	icon_state = "shroud_shatter"
	duration = HERETIC_ASH_SHROUD_SHATTER_TIME
	randomdir = FALSE
	layer = BELOW_MOB_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	appearance_flags = PIXEL_SCALE

/// Хлопья пепла осыпаются с корки, редкий уголёк вспыхивает и гаснет.
/particles/heretic_ascension/ash/shroud_flakes
	icon_state = list("ash_1" = 3, "ash_2" = 3, "ash_3" = 1)
	count = 10
	spawning = 0.6
	position = generator("box", list(-8, -10, 0), list(8, 10, 0))
	velocity = generator("box", list(-0.2, -0.1, 0), list(0.2, 0.3, 0))
	gravity = list(0, -0.08)
	friction = 0.04
	drift = generator("box", list(-0.1, 0, 0), list(0.1, 0, 0))
	lifespan = 1.6 SECONDS
	fade = 0.7 SECONDS

#undef HERETIC_ASH_FX
#undef HERETIC_ASH_SHROUD_FORM_VOLUME
#undef HERETIC_ASH_SHROUD_BREAK_VOLUME
#undef HERETIC_ASH_SHROUD_FADE
#undef HERETIC_ASH_SHROUD_SHATTER_TIME
#undef HERETIC_ASH_SHROUD_WASHED
#undef HERETIC_ASH_SHROUD_CRACKED
