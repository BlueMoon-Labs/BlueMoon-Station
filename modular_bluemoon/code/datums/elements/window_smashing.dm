/**
 * # Window Smashing
 * An element you put on mobs to let them smash through windows on movement
 * For example, throwing someone through a glass window
 */
/datum/element/window_smashing
	element_flags = ELEMENT_DETACH
	/// Pass flags this element granted to each target, so Detach only removes its own
	var/list/granted_pass_flags = list()

/datum/element/window_smashing/Attach(datum/target, duration = 1.5 SECONDS)
	. = ..()
	if(!isliving(target))
		return ELEMENT_INCOMPATIBLE
	var/mob/living/living_target = target
	RegisterSignal(living_target, COMSIG_MOVABLE_MOVED, PROC_REF(flying_window_smash), override = TRUE)
	if(isnull(granted_pass_flags[living_target]))
		var/new_flags = (PASSGLASS|PASSGRILLE) & ~living_target.pass_flags
		granted_pass_flags[living_target] = new_flags
		living_target.pass_flags |= new_flags
	addtimer(CALLBACK(src, PROC_REF(Detach), living_target), duration, TIMER_UNIQUE|TIMER_OVERRIDE)

/// Smash any windows that the mob is flying through
/datum/element/window_smashing/proc/flying_window_smash(mob/living/flying_mob, atom/old_loc, direction)
	SIGNAL_HANDLER
	var/turf/target_turf = get_turf(flying_mob)
	for(var/obj/structure/tram/tram_wall in target_turf)
		smash_and_injure(tram_wall, flying_mob, old_loc)

	for(var/obj/structure/window/window in target_turf)
		smash_and_injure(window, flying_mob, old_loc)

	for(var/obj/structure/grille/grille in target_turf)
		smash_and_injure(grille, flying_mob, old_loc)

/// For when a mob comes flying through the window, smash it and damage the mob
/datum/element/window_smashing/proc/smash_and_injure(obj/structure/smashed, mob/living/flying_mob, atom/old_loc)
	flying_mob.visible_message(span_danger("[flying_mob] пролетает сквозь [smashed]!"))
	flying_mob.apply_damage(rand(5, 15), BRUTE, wound_bonus = 15, bare_wound_bonus = 25, sharpness = SHARP_EDGED)
	new /obj/effect/decal/cleanable/glass(get_step(flying_mob, flying_mob.dir))
	INVOKE_ASYNC(smashed, TYPE_PROC_REF(/obj, deconstruct), FALSE)

/datum/element/window_smashing/Detach(datum/source)
	if(isliving(source))
		var/mob/living/living_source = source
		UnregisterSignal(living_source, COMSIG_MOVABLE_MOVED)
		living_source.pass_flags &= ~granted_pass_flags[living_source]
	granted_pass_flags -= source
	return ..()
