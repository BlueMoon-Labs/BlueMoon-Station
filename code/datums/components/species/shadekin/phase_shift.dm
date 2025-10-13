/////////////////////
///  PHASE SHIFT  ///
/////////////////////



/obj/effect/temp_visual/shadekin
	randomdir = FALSE
	duration = 0.5 SECONDS
	icon = 'icons/effects/shadekin.dmi'

/obj/effect/temp_visual/shadekin/phase_in
	icon_state = "tp_in"

/obj/effect/temp_visual/shadekin/phase_out
	icon_state = "tp_out"

/datum/action/shadekin
	name = "Базовая способность шадекинов"
	var/cost = 50
	var/passive_cost = 0

/datum/action/shadekin/proc/signal_shadekin_del(datum/source)
	SIGNAL_HANDLER
	if(!QDELETED(src))
		qdel(src)
	

/datum/action/shadekin/proc/signal_shadekin_hide(datum/source)
	SIGNAL_HANDLER

/datum/action/shadekin/proc/use_dark_energy(amount)