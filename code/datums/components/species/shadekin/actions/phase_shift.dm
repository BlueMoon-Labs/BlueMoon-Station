/////////////////////
///  PHASE SHIFT  ///
/////////////////////
#define TRAIT_IN_PHASE_SHIFT "in_phase_shift"


/obj/effect/temp_visual/shadekin
	randomdir = FALSE
	duration = 0.5 SECONDS
	icon = 'icons/effects/shadekin.dmi'

/obj/effect/temp_visual/shadekin/phase_in
	icon_state = "tp_in"

/obj/effect/temp_visual/shadekin/phase_out
	icon_state = "tp_out"

/datum/action/shadekin/phase_shift
	name = "Фазовый переход (100)"
	desc = "Переход в темное пространство для перемещения"
	cost = 100

	var/in_phase = FALSE

/datum/action/shadekin/phase_shift/use()

/datum/action/shadekin/phase_shift/proc/phase_in()
	ADD_TRAIT(owner, TRAIT_IN_PHASE_SHIFT, NONE)

/datum/action/shadekin/phase_shift/proc/phase_out()
	REMOVE_TRAIT(owner, TRAIT_IN_PHASE_SHIFT, NONE)

