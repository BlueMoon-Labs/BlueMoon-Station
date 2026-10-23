/obj/item/mod/module/demoralizer
	name = "MOD psi-echo demoralizer module"
	desc = "Пси-излучатель вызывает тревогу у экипажа и усиливает паранойю командования. Противникам станции его сигнал, напротив, придаёт уверенность."
	icon = 'icons/obj/clothing/modsuit/mod_modules_whitemoon.dmi'
	icon_state = "brain_hurties"
	removable = FALSE
	idle_power_cost = DEFAULT_CHARGE_DRAIN * 0.1
	incompatible_modules = list(/obj/item/mod/module/demoralizer)
	var/datum/proximity_monitor/mod_demoralizer/demoralizer

/obj/item/mod/module/demoralizer/on_suit_activation()
	clear_demoralizer()
	demoralizer = new(mod.wearer, MOD_DEMORALIZER_RANGE)

/obj/item/mod/module/demoralizer/on_suit_deactivation()
	clear_demoralizer()

/obj/item/mod/module/demoralizer/on_unequip()
	clear_demoralizer()

/obj/item/mod/module/demoralizer/on_uninstall(deleting = FALSE, user)
	clear_demoralizer()
	return ..()

/obj/item/mod/module/demoralizer/Destroy()
	clear_demoralizer()
	return ..()

/obj/item/mod/module/demoralizer/proc/clear_demoralizer()
	QDEL_NULL(demoralizer)

/datum/proximity_monitor/mod_demoralizer/New(atom/host, range)
	..(host, range)
	RegisterSignal(host, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine))

/datum/proximity_monitor/mod_demoralizer/Destroy()
	UnregisterSignal(host, COMSIG_PARENT_EXAMINE)
	return ..()

/datum/proximity_monitor/mod_demoralizer/on_entered(atom/source, atom/movable/arrived)
	if(isliving(arrived) && (host in view(current_range, arrived)))
		apply_mood(arrived)

/datum/proximity_monitor/mod_demoralizer/on_moved(atom/movable/source, atom/old_loc)
	last_host_loc = host?.loc
	for(var/mob/living/viewer in view(current_range, host))
		apply_mood(viewer)

/datum/proximity_monitor/mod_demoralizer/proc/on_examine(datum/source, mob/viewer)
	SIGNAL_HANDLER
	if(isliving(viewer))
		apply_mood(viewer)

/datum/proximity_monitor/mod_demoralizer/proc/apply_mood(mob/living/viewer)
	if(!viewer.mind || viewer.stat != CONSCIOUS || viewer.is_blind())
		return FALSE
	var/datum/component/mood/mood = viewer.GetComponent(/datum/component/mood)
	if(!mood || mood.mood_events[MOD_DEMORALIZER_MOOD])
		return FALSE
	if(length(viewer.mind.antag_datums))
		to_chat(viewer, span_notice("Вы чувствуете неожиданный прилив уверенности."))
		SEND_SIGNAL(viewer, COMSIG_ADD_MOOD_EVENT, MOD_DEMORALIZER_MOOD, /datum/mood_event/mod_demoralized/antag)
	else if(viewer.mind.assigned_role in GLOB.command_positions + GLOB.security_positions)
		to_chat(viewer, span_warning("Голова кружится. Враг уже здесь, и доверять некому..."))
		SEND_SIGNAL(viewer, COMSIG_ADD_MOOD_EVENT, MOD_DEMORALIZER_MOOD, /datum/mood_event/mod_demoralized/authority)
	else
		to_chat(viewer, span_warning("Голова раскалывается, словно в неё забивают гвозди!"))
		SEND_SIGNAL(viewer, COMSIG_ADD_MOOD_EVENT, MOD_DEMORALIZER_MOOD, /datum/mood_event/mod_demoralized)
	return TRUE

/datum/mood_event/mod_demoralized
	description = "Они на станции! Я знаю! Они идут за мной!"
	mood_change = -4
	timeout = 2 MINUTES
	hidden = TRUE

/datum/mood_event/mod_demoralized/antag
	description = "Самое время доставить неприятности."
	mood_change = 1

/datum/mood_event/mod_demoralized/authority
	description = "Здесь никто не на моей стороне, а врагом может оказаться кто угодно. Нужно действовать решительнее!"
	mood_change = -5
