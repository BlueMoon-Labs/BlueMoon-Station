// =============================================================================
// BLACK MESA TRIGGER ZONES
// Progressive difficulty system for ihategordon mission
// =============================================================================

// Trigger zone object - when a living player crosses it, difficulty increases
// Changed from landmark to effect because landmarks don't support Crossed()
/obj/effect/awaymission/blackmesa/difficulty_trigger
	name = "Difficulty Trigger Zone"
	icon = 'icons/effects/landmarks_static.dmi'
	icon_state = "x4"
	invisibility = INVISIBILITY_ABSTRACT // Completely invisible to players
	anchored = TRUE
	density = FALSE
	layer = TURF_LAYER // Changed from FLY_LAYER to TURF_LAYER for better collision detection
	var/trigger_id = 1 // 1-8 for progressive difficulty
	var/triggered = FALSE

/obj/effect/awaymission/blackmesa/difficulty_trigger/Initialize(mapload)
	. = ..()
	if(trigger_id < 1 || trigger_id > 8)
		trigger_id = 1

/obj/effect/awaymission/blackmesa/difficulty_trigger/Crossed(atom/movable/AM)
	. = ..()
	if(!src)
		return
	if(triggered)
		return
	if(!AM)
		return
	// Only trigger for living players (not mobs or ghosts)
	if(!isliving(AM))
		return
	var/mob/living/L = AM
	if(!L)
		return
	if(!L.client)
		return
	if(L.stat == DEAD)
		return


	// Check if previous trigger was activated (sequential progression)
	if(!GLOB.zombie_director)
		to_chat(L, "<span class='warning'>ERROR: Zombie director not initialized!</span>")
		return
	var/datum/ai_director/zombie_mission/D = GLOB.zombie_director
	if(!D)
		return


	// Trigger level N can only activate if current difficulty is N-1
	// Exception: trigger 1 can always activate (current difficulty 0)
	if(D.difficulty_level != (trigger_id - 1))
		to_chat(L, "<span class='warning'>Необходимо сначала активировать предыдущую триггер зону!</span>")
		return

	// Trigger the difficulty increase - mark as triggered first
	triggered = TRUE
	increase_difficulty(trigger_id)
	// Delete ALL triggers of this level
	remove_all_triggers_of_level(trigger_id)

/obj/effect/awaymission/blackmesa/difficulty_trigger/proc/increase_difficulty(trigger_level)
	if(!trigger_level)
		return
	if(!GLOB.zombie_director)
		return

	var/datum/ai_director/zombie_mission/D = GLOB.zombie_director
	if(!D)
		return
	if(!SSblackmesa_events)
		return

	// Increase difficulty level in director
	D.difficulty_level = trigger_level

	// Update zombie HP multiplier based on difficulty level
	switch(trigger_level)
		if(3)
			D.zombie_hp_multiplier = 1.5
		if(5)
			D.zombie_hp_multiplier = 2.0
		if(7)
			D.zombie_hp_multiplier = 2.5
		if(8)
			D.zombie_hp_multiplier = 3.0


	// Notify all players in the mission using mesa_announce for consistent styling
	var/announce_text = "Внимание! Зафиксировано повышение уровня опасности до уровня [trigger_level]. Ожидается усиление враждебной активности в секторе."
	var/announce_title = "DANGER LEVEL INCREASED"
	SSblackmesa_events.mesa_announce(announce_text, announce_title, 'sound/misc/alerts/alert.ogg')

/obj/effect/awaymission/blackmesa/difficulty_trigger/proc/remove_all_triggers_of_level(trigger_level)
	if(!trigger_level)
		return
	// Find and delete all triggers with the same trigger_id
	var/list/triggers_to_remove = list()
	for(var/obj/effect/awaymission/blackmesa/difficulty_trigger/T in world)
		if(T && T.trigger_id == trigger_level)
			triggers_to_remove += T

	for(var/obj/effect/awaymission/blackmesa/difficulty_trigger/T in triggers_to_remove)
		qdel(T)

// Define 8 trigger zones
/obj/effect/awaymission/blackmesa/difficulty_trigger/trigger1
	name = "Difficulty Trigger 1"
	trigger_id = 1

/obj/effect/awaymission/blackmesa/difficulty_trigger/trigger2
	name = "Difficulty Trigger 2"
	trigger_id = 2

/obj/effect/awaymission/blackmesa/difficulty_trigger/trigger3
	name = "Difficulty Trigger 3"
	trigger_id = 3

/obj/effect/awaymission/blackmesa/difficulty_trigger/trigger4
	name = "Difficulty Trigger 4"
	trigger_id = 4

/obj/effect/awaymission/blackmesa/difficulty_trigger/trigger5
	name = "Difficulty Trigger 5"
	trigger_id = 5

/obj/effect/awaymission/blackmesa/difficulty_trigger/trigger6
	name = "Difficulty Trigger 6"
	trigger_id = 6

/obj/effect/awaymission/blackmesa/difficulty_trigger/trigger7
	name = "Difficulty Trigger 7"
	trigger_id = 7

/obj/effect/awaymission/blackmesa/difficulty_trigger/trigger8
	name = "Difficulty Trigger 8"
	trigger_id = 8

// =============================================================================
// JET FLYBY TRIGGER ZONES
// Progressive flyby system for ihategordon mission
// =============================================================================

// Trigger zone object - when a living player crosses it, jet flies by (screen shake + sounds)
/obj/effect/awaymission/blackmesa/shake_trigger
	name = "Jet Flyby Trigger Zone"
	icon = 'icons/effects/landmarks_static.dmi'
	icon_state = "x3"
	invisibility = INVISIBILITY_ABSTRACT
	anchored = TRUE
	density = FALSE
	layer = TURF_LAYER
	var/trigger_id = 1 // 1-5 for progressive flyby waves
	var/triggered = FALSE
	var/shake_duration = 2 SECONDS
	var/shake_strength = 3
	var/sound_volume = 75

/obj/effect/awaymission/blackmesa/shake_trigger/Initialize(mapload)
	. = ..()
	if(trigger_id < 1 || trigger_id > 5)
		trigger_id = 1

/obj/effect/awaymission/blackmesa/shake_trigger/Crossed(atom/movable/AM)
	. = ..()
	if(!src)
		return
	if(triggered)
		return
	if(!AM)
		return
	if(!isliving(AM))
		return
	var/mob/living/L = AM
	if(!L)
		return
	if(!L.client)
		return
	if(L.stat == DEAD)
		return

	// Check if previous trigger was activated (sequential progression)
	if(!GLOB.zombie_director)
		to_chat(L, "<span class='warning'>ERROR: Zombie director not initialized!</span>")
		return
	var/datum/ai_director/zombie_mission/D = GLOB.zombie_director
	if(!D)
		return

	// Trigger level N can only activate if current difficulty is N-1
	// Exception: trigger 1 can always activate (current difficulty 0)
	if(D.difficulty_level != (trigger_id - 1))
		to_chat(L, "<span class='warning'>Необходимо сначала активировать предыдущую триггер зону пролёта истребителя!</span>")
		return

	// Trigger the shake effect - mark as triggered first
	triggered = TRUE
	trigger_shake_wave(trigger_id)
	// Delete ALL triggers of this level
	remove_all_shake_triggers_of_level(trigger_id)

/obj/effect/awaymission/blackmesa/shake_trigger/proc/trigger_shake_wave(trigger_level)
	if(!trigger_level)
		return

	// Get all living mobs in 5x5 range around the trigger
	var/list/affected_mobs = list()
	for(var/mob/living/L in range(5, src))
		if(L.client && L.stat != DEAD)
			affected_mobs += L

	// Apply screen shake to all affected mobs
	for(var/mob/living/L in affected_mobs)
		shake_camera(L, shake_duration, shake_strength)

	// Play random jet sound to all affected mobs
	if(affected_mobs.len > 0)
		var/jet_sounds = list(
			'modular_bluemoon/sound/ambience/mesa/jet/jetfly.ogg',
			'modular_bluemoon/sound/ambience/mesa/jet/jetfly2.ogg',
			'modular_bluemoon/sound/ambience/mesa/jet/jetfly3.ogg',
			'modular_bluemoon/sound/ambience/mesa/jet/jetfly4.ogg',
			'modular_bluemoon/sound/ambience/mesa/jet/jetfly5.ogg',
			'modular_bluemoon/sound/ambience/mesa/jet/jetfly6.ogg'
		)
		var/picked_sound = pick(jet_sounds)
		for(var/mob/living/L in affected_mobs)
			L.playsound_local(get_turf(src), picked_sound, sound_volume, FALSE)

/obj/effect/awaymission/blackmesa/shake_trigger/proc/remove_all_shake_triggers_of_level(trigger_level)
	if(!trigger_level)
		return
	// Find and delete all triggers with the same trigger_id
	var/list/triggers_to_remove = list()
	for(var/obj/effect/awaymission/blackmesa/shake_trigger/T in world)
		if(T && T.trigger_id == trigger_level)
			triggers_to_remove += T

	for(var/obj/effect/awaymission/blackmesa/shake_trigger/T in triggers_to_remove)
		qdel(T)

// Define 5 jet flyby trigger zones
/obj/effect/awaymission/blackmesa/shake_trigger/shake1
	name = "Jet Flyby Trigger 1"
	trigger_id = 1

/obj/effect/awaymission/blackmesa/shake_trigger/shake2
	name = "Jet Flyby Trigger 2"
	trigger_id = 2
	shake_strength = 4
	shake_duration = 2.5 SECONDS

/obj/effect/awaymission/blackmesa/shake_trigger/shake3
	name = "Jet Flyby Trigger 3"
	trigger_id = 3
	shake_strength = 5
	shake_duration = 3 SECONDS

/obj/effect/awaymission/blackmesa/shake_trigger/shake4
	name = "Jet Flyby Trigger 4"
	trigger_id = 4
	shake_strength = 6
	shake_duration = 3.5 SECONDS

/obj/effect/awaymission/blackmesa/shake_trigger/shake5
	name = "Jet Flyby Trigger 5"
	trigger_id = 5
	shake_strength = 7
	shake_duration = 4 SECONDS

// =============================================================================
// EXPLOSION TRIGGER ZONES
// Progressive bombardment system for ihategordon mission
// Uses sequential bombardment (like door opening) instead of simultaneous explosions
// =============================================================================

// Explosion target landmark - marks where the bombardment will strike
/obj/effect/landmark/awaymission/blackmesa/explosion_target
	name = "Bombardment Target"
	icon = 'icons/effects/landmarks_static.dmi'
	icon_state = "x2"
	invisibility = INVISIBILITY_ABSTRACT
	anchored = TRUE
	density = FALSE
	var/trigger_id = 1 // 1-5 for progressive bombardment waves

/obj/effect/landmark/awaymission/blackmesa/explosion_target/Initialize(mapload)
	. = ..()
	if(trigger_id < 1 || trigger_id > 5)
		trigger_id = 1

// Trigger zone object - when a living player crosses it, triggers sequential bombardment at target landmarks
/obj/effect/awaymission/blackmesa/explosion_trigger
	name = "Bombardment Trigger Zone"
	icon = 'icons/effects/landmarks_static.dmi'
	icon_state = "x1"
	invisibility = INVISIBILITY_ABSTRACT
	anchored = TRUE
	density = FALSE
	layer = TURF_LAYER
	var/trigger_id = 1 // 1-5 for progressive bombardment waves
	var/triggered = FALSE
	var/bombardment_delay = 2 SECONDS // Delay between each bomb
	var/bombardment_interval = 0.5 SECONDS // Delay between strikes

/obj/effect/awaymission/blackmesa/explosion_trigger/Initialize(mapload)
	. = ..()
	if(trigger_id < 1 || trigger_id > 5)
		trigger_id = 1

/obj/effect/awaymission/blackmesa/explosion_trigger/Crossed(atom/movable/AM)
	. = ..()
	if(!src)
		return
	if(triggered)
		return
	if(!AM)
		return
	if(!isliving(AM))
		return
	var/mob/living/L = AM
	if(!L)
		return
	if(!L.client)
		return
	if(L.stat == DEAD)
		return

	// Check if previous trigger was activated (sequential progression)
	if(!GLOB.zombie_director)
		to_chat(L, "<span class='warning'>ERROR: Zombie director not initialized!</span>")
		return
	var/datum/ai_director/zombie_mission/D = GLOB.zombie_director
	if(!D)
		return

	// Trigger level N can only activate if current difficulty is N-1
	// Exception: trigger 1 can always activate (current difficulty 0)
	if(D.difficulty_level != (trigger_id - 1))
		to_chat(L, "<span class='warning'>Необходимо сначала активировать предыдущую триггер зону бомбардировки!</span>")
		return

	// Trigger the bombardment - mark as triggered first
	triggered = TRUE
	trigger_bombardment_wave(trigger_id)
	// Delete ALL triggers of this level
	remove_all_explosion_triggers_of_level(trigger_id)

/obj/effect/awaymission/blackmesa/explosion_trigger/proc/trigger_bombardment_wave(trigger_level)
	if(!trigger_level)
		return

	// Find all bombardment targets with the same trigger_id
	var/list/targets = list()
	for(var/obj/effect/landmark/awaymission/blackmesa/explosion_target/T in world)
		if(T && T.trigger_id == trigger_level)
			targets += T

	if(targets.len == 0)
		return

	// Start sequential bombardment with delays
	// First strike after initial delay
	var/delay = bombardment_delay
	for(var/obj/effect/landmark/awaymission/blackmesa/explosion_target/T in targets)
		if(T.loc)
			addtimer(CALLBACK(src, PROC_REF(drop_bombardment_pod), T.loc), delay)
			delay += bombardment_interval

/obj/effect/awaymission/blackmesa/explosion_trigger/proc/drop_bombardment_pod(turf/drop_turf)
	if(!drop_turf)
		return

	// Play incoming sound
	playsound(drop_turf, 'sound/weapons/mortar_long_whistle.ogg', 80, TRUE)

	// Create bombardment pod (similar to negotiations_radio/bombardment system)
	var/obj/structure/closet/supplypod/centcompod/pod = new(null, STYLE_MISSILE)
	pod.name = "tactical bombardment pod"
	pod.desc = "A high-explosive tactical bombardment pod."
	pod.explosionSize = list(0, 2, 2, 4) // Moderate explosion (non-lethal but visual)
	pod.effectMissile = TRUE
	pod.damage = 50
	pod.effectGib = FALSE
	new /obj/effect/pod_landingzone(drop_turf, pod)

/obj/effect/awaymission/blackmesa/explosion_trigger/proc/remove_all_explosion_triggers_of_level(trigger_level)
	if(!trigger_level)
		return
	// Find and delete all triggers with the same trigger_id
	var/list/triggers_to_remove = list()
	for(var/obj/effect/awaymission/blackmesa/explosion_trigger/T in world)
		if(T && T.trigger_id == trigger_level)
			triggers_to_remove += T

	for(var/obj/effect/awaymission/blackmesa/explosion_trigger/T in triggers_to_remove)
		qdel(T)

// Define 5 bombardment trigger zones
/obj/effect/awaymission/blackmesa/explosion_trigger/explosion1
	name = "Bombardment Trigger 1"
	trigger_id = 1

/obj/effect/awaymission/blackmesa/explosion_trigger/explosion2
	name = "Bombardment Trigger 2"
	trigger_id = 2
	bombardment_interval = 0.6 SECONDS

/obj/effect/awaymission/blackmesa/explosion_trigger/explosion3
	name = "Bombardment Trigger 3"
	trigger_id = 3
	bombardment_interval = 0.7 SECONDS

/obj/effect/awaymission/blackmesa/explosion_trigger/explosion4
	name = "Bombardment Trigger 4"
	trigger_id = 4
	bombardment_interval = 0.8 SECONDS

/obj/effect/awaymission/blackmesa/explosion_trigger/explosion5
	name = "Bombardment Trigger 5"
	trigger_id = 5
	bombardment_interval = 1 SECONDS

// Define 5 bombardment target landmarks
/obj/effect/landmark/awaymission/blackmesa/explosion_target/target1
	name = "Bombardment Target 1"
	trigger_id = 1

/obj/effect/landmark/awaymission/blackmesa/explosion_target/target2
	name = "Bombardment Target 2"
	trigger_id = 2

/obj/effect/landmark/awaymission/blackmesa/explosion_target/target3
	name = "Bombardment Target 3"
	trigger_id = 3

/obj/effect/landmark/awaymission/blackmesa/explosion_target/target4
	name = "Bombardment Target 4"
	trigger_id = 4

/obj/effect/landmark/awaymission/blackmesa/explosion_target/target5
	name = "Bombardment Target 5"
	trigger_id = 5
