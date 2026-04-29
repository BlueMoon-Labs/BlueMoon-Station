/// Applied to turfs created by heretic rust abilities; debuffs mobs standing on the turf (SPLURT-style).
/datum/element/heretic_rust
	element_flags = ELEMENT_DETACH

/datum/element/heretic_rust/Attach(datum/target)
	. = ..()
	if(!isturf(target))
		return ELEMENT_INCOMPATIBLE
	RegisterSignal(target, COMSIG_ATOM_ENTERED, PROC_REF(on_entered))
	RegisterSignal(target, COMSIG_ATOM_EXITED, PROC_REF(on_exited))
	for(var/atom/movable/mover in target)
		try_affect_mover(mover, target)

/datum/element/heretic_rust/Detach(atom/source, ...)
	. = ..()
	UnregisterSignal(source, list(COMSIG_ATOM_ENTERED, COMSIG_ATOM_EXITED))
	for(var/mob/living/victim in source)
		victim.remove_status_effect(/datum/status_effect/rust_corruption)

/datum/element/heretic_rust/proc/on_entered(turf/source, atom/movable/entering, atom/oldloc)
	SIGNAL_HANDLER
	try_affect_mover(entering, source)

/datum/element/heretic_rust/proc/on_exited(turf/source, atom/movable/gone, atom/newloc)
	SIGNAL_HANDLER
	if(!isliving(gone))
		return
	var/mob/living/leaver = gone
	leaver.remove_status_effect(/datum/status_effect/rust_corruption)

/datum/element/heretic_rust/proc/try_affect_mover(atom/movable/mover, turf/source)
	if(ismecha(mover))
		var/obj/vehicle/sealed/mecha/mech = mover
		mech.take_damage(20, BRUTE, MELEE, 0)
		return
	if(!isliving(mover))
		return
	var/mob/living/victim = mover
	if(victim.stat == DEAD)
		return
	if(IS_HERETIC(victim) || IS_HERETIC_MONSTER(victim))
		return
	if(victim.anti_magic_check(chargecost = 0))
		return
	victim.apply_status_effect(/datum/status_effect/rust_corruption)
