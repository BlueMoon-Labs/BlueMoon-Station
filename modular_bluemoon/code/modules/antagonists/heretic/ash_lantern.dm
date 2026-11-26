#define HERETIC_ASH_LANTERN_LIGHT_RANGE 4
#define HERETIC_ASH_LANTERN_LIGHT_POWER 1.5
#define HERETIC_ASH_LANTERN_EMBER_RATE 0.3
#define HERETIC_ASH_LANTERN_VOLUME 50
#define HERETIC_ASH_LANTERN_DOUSE_SOUND 'modular_bluemoon/sound/heretic/ash_quench.ogg'
#define HERETIC_ASH_LANTERN_BREAK_SOUND 'modular_bluemoon/sound/heretic/ash_lantern_break.ogg'
#define HERETIC_ASH_LANTERN_SHAKE 2
#define HERETIC_ASH_LANTERN_SHAKE_STEP (0.05 SECONDS)

/datum/eldritch_knowledge/final_eldritch/ash_final
	/// Пепельный фонарь на месте обряда: пока горит, пламя владыки в полной силе.
	var/obj/structure/heretic_ash_lantern/lantern
	var/datum/weakref/lantern_master

/datum/eldritch_knowledge/final_eldritch/ash_final/Destroy()
	if(lantern)
		UnregisterSignal(lantern, COMSIG_PARENT_QDELETING)
		QDEL_NULL(lantern)
	lantern_master = null
	return ..()

/datum/eldritch_knowledge/final_eldritch/ash_final/proc/lantern_lit()
	return !QDELETED(lantern) && lantern.lit

/datum/eldritch_knowledge/final_eldritch/ash_final/proc/plant_lantern(turf/ritual_turf, mob/living/user)
	var/turf/lantern_turf = get_turf(ritual_turf)
	if(!isopenturf(lantern_turf) || isspaceturf(lantern_turf) || isgroundlessturf(lantern_turf) || lantern_turf.is_blocked_turf(TRUE))
		lantern_turf = get_turf(user)
	if(!lantern_turf)
		return
	if(lantern)
		UnregisterSignal(lantern, COMSIG_PARENT_QDELETING)
		QDEL_NULL(lantern)
	lantern_master = WEAKREF(user.mind)
	lantern = new(lantern_turf, user.mind, src)
	RegisterSignal(lantern, COMSIG_PARENT_QDELETING, PROC_REF(on_lantern_destroyed))
	lantern_changed()
	to_chat(user, span_notice("На месте обряда разгорается Пепельный фонарь. Пока он горит, ваше пламя в полной силе; вода его гасит, оружие разбивает."))

/datum/eldritch_knowledge/final_eldritch/ash_final/proc/on_lantern_destroyed(datum/source)
	SIGNAL_HANDLER
	UnregisterSignal(source, COMSIG_PARENT_QDELETING)
	var/atom/broken = source
	log_game("Пепельный фонарь разбит в [AREACOORD(broken)], последним его трогал [broken.fingerprintslast || "никто"].")
	lantern = null
	lantern_changed()
	var/datum/mind/master = lantern_master?.resolve()
	if(master?.current)
		to_chat(master.current, span_userdanger("Пепельный фонарь разбит! Пламя на вас лечит слабее, а след гаснет быстрее, и вернуть фонарь нельзя."))

/datum/eldritch_knowledge/final_eldritch/ash_final/proc/lantern_changed()
	var/datum/component/heretic_ash_lord/lord = applied_body?.GetComponent(/datum/component/heretic_ash_lord)
	lord?.update_lantern_alert()

/// Пепельный фонарь вознёсшегося: якорь его пламени и цель для экипажа.
/obj/structure/heretic_ash_lantern
	name = "ashen lantern"
	desc = "Чёрный железный фонарь на треноге, вросший в пепел на месте вознесения. Пока в нём горит пламя, огонь Пепельного Лорда в полной силе: лечит его и оставляет за ним долгий след. Вода или пена из огнетушителя гасят фонарь, обычным оружием его можно разбить."
	icon = 'modular_bluemoon/icons/obj/heretic_ash_lantern.dmi'
	icon_state = "ash_lantern"
	anchored = TRUE
	density = FALSE
	max_integrity = HERETIC_ASH_LANTERN_INTEGRITY
	resistance_flags = FIRE_PROOF | LAVA_PROOF
	appearance_flags = PIXEL_SCALE
	var/lit = TRUE
	/// До этого времени мокрый фитиль не разжечь.
	var/soaked_until = 0
	var/relighting = FALSE
	var/datum/weakref/master_mind
	var/datum/weakref/knowledge_ref
	var/obj/effect/abstract/heretic_particle_holder/embers

/obj/structure/heretic_ash_lantern/Initialize(mapload, datum/mind/master, datum/eldritch_knowledge/final_eldritch/ash_final/knowledge)
	. = ..()
	master_mind = WEAKREF(master)
	knowledge_ref = WEAKREF(knowledge)
	RegisterSignal(src, COMSIG_ATOM_EXPOSE_REAGENTS, PROC_REF(on_exposed))
	embers = heretic_vfx_attach_particles(src, /particles/heretic_ascension/ash/lord_embers)
	update_lantern()
	heretic_vfx_burst(src, /particles/heretic_ascension/ash)
	heretic_vfx_flash(src, LIGHT_COLOR_FIRE, HERETIC_ASH_LANTERN_LIGHT_RANGE, HERETIC_ASH_LANTERN_LIGHT_POWER * 2)

/obj/structure/heretic_ash_lantern/Destroy()
	var/turf/place = get_turf(src)
	if(place)
		visible_message(span_danger("[src] разлетается чёрными осколками, пламя в нём гаснет!"))
		heretic_vfx_burst(place, /particles/heretic_ascension/ash)
		new /obj/effect/temp_visual/heretic_ash_quench(place)
		playsound(place, HERETIC_ASH_LANTERN_BREAK_SOUND, HERETIC_ASH_LANTERN_VOLUME, TRUE)
	heretic_vfx_release_particles(src, embers)
	embers = null
	master_mind = null
	knowledge_ref = null
	return ..()

/obj/structure/heretic_ash_lantern/proc/update_lantern()
	cut_overlays()
	icon_state = lit ? "ash_lantern" : "ash_lantern_out"
	if(lit)
		add_overlay(emissive_appearance(icon, "ash_lantern_glow", offset_spokesman = src))
		set_light(HERETIC_ASH_LANTERN_LIGHT_RANGE, HERETIC_ASH_LANTERN_LIGHT_POWER, LIGHT_COLOR_FIRE)
	else
		set_light(0)
	if(embers?.particles)
		embers.particles.spawning = lit ? HERETIC_ASH_LANTERN_EMBER_RATE : 0

/obj/structure/heretic_ash_lantern/proc/notify_knowledge()
	var/datum/eldritch_knowledge/final_eldritch/ash_final/knowledge = knowledge_ref?.resolve()
	knowledge?.lantern_changed()

/obj/structure/heretic_ash_lantern/proc/on_exposed(atom/source, list/reagents, datum/reagents/holder)
	SIGNAL_HANDLER
	for(var/datum/reagent/reagent as anything in reagents)
		if(istype(reagent, /datum/reagent/water) || istype(reagent, /datum/reagent/firefighting_foam))
			douse(holder?.my_atom)
			return

/// Срок сырости ставит только первая заливка: вода по погасшему фонарю его не продлевает.
/obj/structure/heretic_ash_lantern/proc/douse(atom/carrier)
	if(!lit)
		return FALSE
	soaked_until = world.time + HERETIC_ASH_LANTERN_SOAK
	lit = FALSE
	update_lantern()
	heretic_vfx_burst(src, /particles/heretic_ascension/steam)
	playsound(src, HERETIC_ASH_LANTERN_DOUSE_SOUND, HERETIC_ASH_LANTERN_VOLUME, TRUE)
	visible_message(span_notice("Пламя в [src] шипит и гаснет."))
	var/mob/wielder = carrier && get(carrier, /mob)
	var/sprayer = wielder ? " в руках [key_name(wielder)]" : carrier?.fingerprintslast ? ", распылил [carrier.fingerprintslast]" : ""
	log_game("Пепельный фонарь погашен в [AREACOORD(src)] ([carrier || "вода"][sprayer]), последним его трогал [fingerprintslast || "никто"].")
	notify_knowledge()
	var/datum/mind/master = master_mind?.resolve()
	if(master?.current)
		to_chat(master.current, span_userdanger("Пепельный фонарь залит! Пламя на вас слабеет. Разожгите фонарь рукой, когда фитиль просохнет через [HERETIC_ASH_LANTERN_SOAK / (1 SECONDS)] секунд."))
	return TRUE

/obj/structure/heretic_ash_lantern/proc/can_relight(mob/living/user)
	if(lit || QDELETED(src) || world.time < soaked_until || !istype(user) || !user.mind)
		return FALSE
	if(master_mind?.resolve() != user.mind || !IS_HERETIC(user))
		return FALSE
	return user.stat == CONSCIOUS && !heretic_incapacitated(user) && user.Adjacent(src)

/// Почему кадильница не разожжёт фонарь, или null.
/obj/structure/heretic_ash_lantern/proc/censer_block_reason(mob/living/user)
	if(lit)
		return "Фонарь и так горит."
	if(master_mind?.resolve() != user?.mind)
		return "Это чужой фонарь: разжечь его может только тот, кто вознёсся."
	if(world.time < soaked_until)
		return "Фитиль ещё сырой: подождите [round((soaked_until - world.time) / (1 SECONDS)) + 1] с."
	return null

/obj/structure/heretic_ash_lantern/proc/relight(mob/living/user)
	if(!can_relight(user))
		return FALSE
	lit = TRUE
	update_lantern()
	heretic_vfx_burst(src, /particles/heretic_ascension/ash)
	heretic_vfx_flash(src, LIGHT_COLOR_FIRE, HERETIC_ASH_LANTERN_LIGHT_RANGE, HERETIC_ASH_LANTERN_LIGHT_POWER * 2)
	playsound(src, HERETIC_ASH_REKINDLE_SOUND, HERETIC_ASH_LANTERN_VOLUME, TRUE)
	visible_message(span_warning("В [src] снова разгорается пламя!"))
	log_game("[key_name(user)] разжигает Пепельный фонарь в [AREACOORD(src)].")
	notify_knowledge()
	return TRUE

/obj/structure/heretic_ash_lantern/attack_hand(mob/user, act_intent = user?.a_intent, attackchain_flags)
	if(lit || master_mind?.resolve() != user?.mind || !IS_HERETIC(user))
		return ..()
	if(world.time < soaked_until)
		to_chat(user, span_warning("Фитиль ещё сырой: подождите [round((soaked_until - world.time) / (1 SECONDS)) + 1] с."))
		return TRUE
	if(!relighting)
		INVOKE_ASYNC(src, PROC_REF(try_relight), user)
	return TRUE

/obj/structure/heretic_ash_lantern/proc/try_relight(mob/living/user)
	relighting = TRUE
	user.visible_message(span_warning("[user] склоняется над [src] и раздувает угли."))
	if(do_after(user, HERETIC_ASH_LANTERN_RELIGHT, target = src))
		relight(user)
	if(!QDELETED(src))
		relighting = FALSE

/obj/structure/heretic_ash_lantern/take_damage(damage_amount, damage_type = BRUTE, damage_flag = 0, sound_effect = 1, attack_dir, armour_penetration = 0)
	. = ..()
	if(!. || QDELETED(src))
		return
	animate(src, pixel_x = HERETIC_ASH_LANTERN_SHAKE, time = HERETIC_ASH_LANTERN_SHAKE_STEP, flags = ANIMATION_PARALLEL)
	animate(pixel_x = -HERETIC_ASH_LANTERN_SHAKE, time = HERETIC_ASH_LANTERN_SHAKE_STEP * 2)
	animate(pixel_x = 0, time = HERETIC_ASH_LANTERN_SHAKE_STEP)

/obj/structure/heretic_ash_lantern/examine(mob/user)
	. = ..()
	if(lit)
		. += span_warning("Внутри ровно горит пепельное пламя.")
	else if(world.time < soaked_until)
		. += span_notice("Фонарь залит водой, фитиль ещё сырой.")
	else
		. += span_notice("Фонарь погас, но фитиль уже просох: хозяин может разжечь его снова.")
	if(master_mind?.resolve() == user?.mind && IS_HERETIC(user))
		. += span_notice("Погасший фонарь разжигается касанием за [HERETIC_ASH_LANTERN_RELIGHT / (1 SECONDS)] секунды, кадильница с зарядом - сразу. Залитый фитиль сохнет [HERETIC_ASH_LANTERN_SOAK / (1 SECONDS)] секунд.")

/atom/movable/screen/alert/heretic_ash_lantern
	name = "Пепельный фонарь"
	desc = "Фонарь на месте обряда горит: пламя на вас лечит в полную силу, а след держится долго."
	icon = 'modular_bluemoon/icons/obj/heretic_ash_lantern.dmi'
	icon_state = "ash_lantern_alert"

/atom/movable/screen/alert/heretic_ash_lantern/proc/show_state(lit, exists)
	icon_state = lit ? "ash_lantern_alert" : "ash_lantern_alert_out"
	if(lit)
		desc = initial(desc)
	else if(exists)
		desc = "Фонарь залит водой: пламя на вас лечит слабее, а след гаснет быстрее. Разожгите его рукой, когда фитиль просохнет."
	else
		desc = "Фонарь разбит: пламя на вас навсегда лечит слабее, а след гаснет быстрее."

#undef HERETIC_ASH_LANTERN_LIGHT_RANGE
#undef HERETIC_ASH_LANTERN_LIGHT_POWER
#undef HERETIC_ASH_LANTERN_EMBER_RATE
#undef HERETIC_ASH_LANTERN_VOLUME
#undef HERETIC_ASH_LANTERN_DOUSE_SOUND
#undef HERETIC_ASH_LANTERN_BREAK_SOUND
#undef HERETIC_ASH_LANTERN_SHAKE
#undef HERETIC_ASH_LANTERN_SHAKE_STEP
