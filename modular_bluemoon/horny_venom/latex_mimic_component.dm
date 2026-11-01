/datum/component/latex_mimicry
	dupe_mode = COMPONENT_DUPE_UNIQUE
	var/mob/living/simple_animal/latexmob/stored_latexmob
	var/breaking = FALSE
	var/turf/safe_turf

/datum/component/latex_mimicry/Initialize(mob/living/simple_animal/latexmob/latex_mob)
	if(!isobj(parent) || !istype(latex_mob))
		return COMPONENT_INCOMPATIBLE
	stored_latexmob = latex_mob
	safe_turf = get_turf(parent)

/datum/component/latex_mimicry/RegisterWithParent()
	RegisterSignal(parent, COMSIG_PARENT_QDELETING, PROC_REF(shell_deleted))
	RegisterSignal(parent, list(COMSIG_ATOM_ATTACK_HAND, COMSIG_ITEM_PICKUP, COMSIG_ITEM_EQUIPPED), PROC_REF(touched))
	RegisterSignal(parent, COMSIG_PARENT_ATTACKBY, PROC_REF(attacked))
	RegisterSignal(stored_latexmob, COMSIG_LIVING_DEATH, PROC_REF(shell_deleted))
	RegisterSignal(stored_latexmob, COMSIG_MOVABLE_MOVED, PROC_REF(actor_moved))
	RegisterSignal(parent, COMSIG_MOVABLE_MOVED, PROC_REF(shell_moved))

/datum/component/latex_mimicry/UnregisterFromParent()
	UnregisterSignal(parent, list(COMSIG_PARENT_QDELETING, COMSIG_ATOM_ATTACK_HAND, COMSIG_ITEM_PICKUP, COMSIG_ITEM_EQUIPPED, COMSIG_PARENT_ATTACKBY, COMSIG_MOVABLE_MOVED))
	if(stored_latexmob)
		UnregisterSignal(stored_latexmob, list(COMSIG_LIVING_DEATH, COMSIG_MOVABLE_MOVED))

/datum/component/latex_mimicry/proc/touched(datum/source, mob/living/user)
	SIGNAL_HANDLER
	if(ishuman(user) && stored_latexmob?.client)
		to_chat(stored_latexmob, span_notice("[user] касается вашей маскировки. Способность поглощения позволит выбрать цель и раскрыться."))

/datum/component/latex_mimicry/proc/attacked(datum/source, obj/item/weapon, mob/user)
	SIGNAL_HANDLER
	if(weapon.force > 0)
		INVOKE_ASYNC(stored_latexmob, TYPE_PROC_REF(/mob/living/simple_animal/latexmob, go_back))

/datum/component/latex_mimicry/proc/shell_deleted()
	SIGNAL_HANDLER
	if(breaking || !stored_latexmob)
		return
	breaking = TRUE
	var/mob/living/simple_animal/latexmob/latex_mob = stored_latexmob
	latex_mob.mimic_shell = null
	latex_mob.mimicry_in_use = FALSE
	if(latex_mob.loc == parent)
		latex_mob.forceMove(exit_turf())

/datum/component/latex_mimicry/Destroy()
	shell_deleted()
	. = ..()
	stored_latexmob = null
	safe_turf = null

/datum/component/latex_mimicry/proc/exit_turf()
	return get_turf(parent) || safe_turf

/datum/component/latex_mimicry/proc/shell_moved()
	SIGNAL_HANDLER
	safe_turf = get_turf(parent) || safe_turf

/datum/component/latex_mimicry/proc/actor_moved()
	SIGNAL_HANDLER
	if(stored_latexmob?.mimic_shell == parent && stored_latexmob.loc != parent)
		INVOKE_ASYNC(stored_latexmob, TYPE_PROC_REF(/mob/living/simple_animal/latexmob, go_back))
