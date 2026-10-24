#define HERETIC_ASH_PRINT_CLUE "Угли под отпечатком тлеют без всякого топлива. Тряпка, швабра или нулевой жезл их погасят."
#define HERETIC_ASH_PRINT_FLARE_RANGE 1
#define HERETIC_ASH_PRINT_FLARE_POWER 1
#define HERETIC_ASH_PRINT_FLARE_TIME (0.5 SECONDS)
#define HERETIC_ASH_PRINT_FLARE_VOLUME 25

/datum/eldritch_knowledge/base_ash
	var/list/obj/effect/decal/cleanable/heretic_trace/ash_print/ember_prints = list()
	/// Свой огонь засчитывается в дело и оставляет отпечаток один раз за раунд.
	var/own_flame_spent = FALSE
	COOLDOWN_DECLARE(print_harvest)

/datum/eldritch_knowledge/base_ash/Destroy()
	QDEL_LIST(shrouds)
	for(var/obj/effect/decal/cleanable/heretic_trace/ash_print/print as anything in ember_prints.Copy())
		print.cool_down()
	return ..()

/// Огонь у ног последним трогал сам еретик: свою зажигалку, свечу или спичку он принёс сам.
/datum/eldritch_knowledge/base_ash/proc/own_flame(mob/living/user, atom/target)
	return isitem(target) && user?.ckey && target.fingerprintslast == user.ckey

/// Погашенный огонь на полу идёт в дело и оставляет тлеющий отпечаток; свой огонь - только первый раз за раунд.
/datum/eldritch_knowledge/base_ash/proc/floor_flame_put_out(mob/living/user, turf/place, own)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(own && own_flame_spent)
		to_chat(user, span_notice("Свой огонь Мансус уже видел: для дела и отпечатков гасите огонь станции. Уголёк вы всё равно получаете."))
		return FALSE
	var/counted = heretic.advance_deed(heretic.deed_key_for(place), place)
	if(own)
		if(!counted)
			return FALSE
		own_flame_spent = TRUE
		to_chat(user, span_notice("Свой огонь засчитан один раз за раунд: дальше дело продвигает только огонь станции."))
	leave_print(place)
	return counted

/datum/eldritch_knowledge/base_ash/proc/leave_print(turf/place)
	if(!isopenturf(place) || isgroundlessturf(place))
		return null
	for(var/obj/effect/decal/cleanable/heretic_trace/trace in place)
		if(trace.type == /obj/effect/decal/cleanable/heretic_trace && trace.icon_state == "trace_ash")
			qdel(trace)
	var/obj/effect/decal/cleanable/heretic_trace/ash_print/print = locate() in place
	if(print?.smouldering && (print in ember_prints))
		print.rekindle()
		return print
	if(print)
		qdel(print)
	print = new(place, src)
	return QDELETED(print) ? null : print

/datum/eldritch_knowledge/base_ash/proc/add_print(obj/effect/decal/cleanable/heretic_trace/ash_print/print)
	ember_prints += print
	while(length(ember_prints) > HERETIC_ASH_PRINT_LIMIT)
		var/obj/effect/decal/cleanable/heretic_trace/ash_print/oldest = ember_prints[1]
		ember_prints -= oldest
		oldest.cool_down()
	notify_resource_changed()

/datum/eldritch_knowledge/base_ash/on_craft_removed(atom/crafted, craft_id)
	if(craft_id != HERETIC_ASH_PRINT_CRAFT)
		return
	ember_prints -= crafted
	var/obj/effect/decal/cleanable/heretic_trace/ash_print/print = crafted
	if(!QDELETED(print) && print.smouldering)
		qdel(print)
	notify_resource_changed()

/datum/eldritch_knowledge/base_ash/combat_resource_state()
	return length(ember_prints) ? "Тлеющих отпечатков: [length(ember_prints)] из [HERETIC_ASH_PRINT_LIMIT]." : ""

/datum/eldritch_knowledge/base_ash/pocket_exits(mob/living/user)
	for(var/obj/effect/decal/cleanable/heretic_trace/ash_print/print as anything in ember_prints)
		if(!.)
			. = list()
		heretic_add_pocket_exit(., "Угли - [get_area_name(print, TRUE)]", heretic_pocket_landing(get_turf(print)))

/// Еретик на своём тлеющем отпечатке раздувает угли быстрее, чем хваткой.
/datum/eldritch_knowledge/base_ash/on_life(mob/user)
	if(combat_resource >= combat_resource_max || !COOLDOWN_FINISHED(src, print_harvest) || !isturf(user?.loc))
		return
	var/obj/effect/decal/cleanable/heretic_trace/ash_print/print = locate() in user.loc
	if(!print?.smouldering || !(print in ember_prints))
		return
	COOLDOWN_START(src, print_harvest, HERETIC_ASH_PRINT_HARVEST)
	gain_combat_resource()
	print.flare()

/obj/effect/decal/cleanable/heretic_trace/ash_print
	name = "smouldering handprint"
	desc = "На полу выжжен отпечаток ладони, в нём тлеют угли."
	icon = 'modular_bluemoon/icons/obj/heretic_ash_fx.dmi'
	icon_state = "ember_print"
	alpha = 255
	var/smouldering = FALSE
	var/cool_timer
	var/mutable_appearance/glow

/obj/effect/decal/cleanable/heretic_trace/ash_print/Initialize(mapload, datum/eldritch_knowledge/base_ash/ash)
	. = ..(mapload)
	if(. == INITIALIZE_HINT_QDEL)
		return
	if(!istype(ash))
		cool_down()
		return
	smouldering = TRUE
	glow = emissive_appearance(icon, "ember_print_glow", offset_spokesman = src)
	add_overlay(glow)
	ash.add_print(src)
	AddComponent(/datum/component/heretic_craft, ash, HERETIC_ASH_PRINT_CRAFT, HERETIC_ASH_PRINT_CLUE)
	cool_timer = addtimer(CALLBACK(src, PROC_REF(cool_down)), HERETIC_ASH_PRINT_LIFETIME, TIMER_STOPPABLE)

/obj/effect/decal/cleanable/heretic_trace/ash_print/Destroy()
	deltimer(cool_timer)
	cool_timer = null
	return ..()

/obj/effect/decal/cleanable/heretic_trace/ash_print/proc/rekindle()
	deltimer(cool_timer)
	cool_timer = addtimer(CALLBACK(src, PROC_REF(cool_down)), HERETIC_ASH_PRINT_LIFETIME, TIMER_STOPPABLE)
	flare()

/// Угли гаснут: остаётся холодный выжженный след, уже не выход и не запас.
/obj/effect/decal/cleanable/heretic_trace/ash_print/proc/cool_down()
	smouldering = FALSE
	deltimer(cool_timer)
	cool_timer = null
	if(glow)
		cut_overlay(glow)
		glow = null
	icon_state = "ember_print_cold"
	name = "scorched handprint"
	desc = "На полу выжжен отпечаток ладони. Металл вокруг него давно остыл."
	qdel(GetComponent(/datum/component/heretic_craft))

/obj/effect/decal/cleanable/heretic_trace/ash_print/proc/flare()
	if(!smouldering)
		return
	heretic_vfx_flash(src, LIGHT_COLOR_FIRE, HERETIC_ASH_PRINT_FLARE_RANGE, HERETIC_ASH_PRINT_FLARE_POWER, HERETIC_ASH_PRINT_FLARE_TIME)
	if(heretic_vfx_watched(src))
		heretic_vfx_burst(src, /particles/heretic_ascension/ash, HERETIC_VFX_BURST_TIME / 2)
	playsound(src, 'sound/effects/wounds/sizzle1.ogg', HERETIC_ASH_PRINT_FLARE_VOLUME, TRUE, SILENCED_SOUND_EXTRARANGE)

#undef HERETIC_ASH_PRINT_CLUE
#undef HERETIC_ASH_PRINT_FLARE_RANGE
#undef HERETIC_ASH_PRINT_FLARE_POWER
#undef HERETIC_ASH_PRINT_FLARE_TIME
#undef HERETIC_ASH_PRINT_FLARE_VOLUME
