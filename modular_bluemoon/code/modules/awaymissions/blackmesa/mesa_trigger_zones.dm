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
	if(!src)
		return
	if(trigger_id < 1 || trigger_id > 8)
		trigger_id = 1
	log_world("Black Mesa Trigger Zone #[trigger_id] initialized at [src]")

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

	log_world("Crossed() called for trigger #[trigger_id] by [L], GLOB.zombie_director: [GLOB.zombie_director ? "EXISTS" : "NULL"]")

	// Check if previous trigger was activated (sequential progression)
	if(!GLOB.zombie_director)
		log_world("ERROR: GLOB.zombie_director is NULL when crossing trigger #[trigger_id]")
		to_chat(L, "<span class='warning'>ERROR: Zombie director not initialized!</span>")
		return
	var/datum/ai_director/zombie_mission/D = GLOB.zombie_director
	if(!D)
		log_world("ERROR: D is NULL after getting GLOB.zombie_director")
		return

	log_world("Current difficulty_level: [D.difficulty_level], required for trigger #[trigger_id]: [trigger_id - 1]")

	// Trigger level N can only activate if current difficulty is N-1
	// Exception: trigger 1 can always activate (current difficulty 0)
	if(D.difficulty_level != (trigger_id - 1))
		log_world("Difficulty check FAILED: current [D.difficulty_level] != required [trigger_id - 1]")
		to_chat(L, "<span class='warning'>Необходимо сначала активировать предыдущую триггер зону!</span>")
		return

	// Trigger the difficulty increase - mark as triggered first
	triggered = TRUE
	log_world("Black Mesa Trigger Zone #[trigger_id] activated by [L]")
	increase_difficulty(trigger_id)
	// Delete ALL triggers of this level
	remove_all_triggers_of_level(trigger_id)

/obj/effect/awaymission/blackmesa/difficulty_trigger/proc/increase_difficulty(trigger_level)
	if(!src)
		return
	if(!trigger_level)
		return
	if(!GLOB.zombie_director)
		log_world("ERROR: zombie_director is null when triggering difficulty")
		return

	var/datum/ai_director/zombie_mission/D = GLOB.zombie_director
	if(!D)
		return
	if(!SSblackmesa_events)
		log_world("ERROR: SSblackmesa_events is null when triggering difficulty")
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

	log_world("Black Mesa difficulty increased to level [trigger_level], zombie HP multiplier: [D.zombie_hp_multiplier]")

	// Notify all players in the mission using mesa_announce for consistent styling
	var/announce_text = "Внимание! Зафиксировано повышение уровня опасности до уровня [trigger_level]. Ожидается усиление враждебной активности в секторе."
	var/announce_title = "DANGER LEVEL INCREASED"
	SSblackmesa_events.mesa_announce(announce_text, announce_title, 'sound/misc/alerts/alert.ogg')

/obj/effect/awaymission/blackmesa/difficulty_trigger/proc/remove_all_triggers_of_level(trigger_level)
	if(!src)
		return
	if(!trigger_level)
		return
	// Find and delete all triggers with the same trigger_id
	var/list/triggers_to_remove = list()
	var/total_triggers_found = 0
	for(var/obj/effect/awaymission/blackmesa/difficulty_trigger/T in world)
		if(!T)
			continue
		total_triggers_found++
		if(T.trigger_id == trigger_level)
			triggers_to_remove += T
			log_world("Found trigger zone #[T.trigger_id] at [T] - marked for removal")

	log_world("Total triggers in world: [total_triggers_found], Triggers to remove (level [trigger_level]): [triggers_to_remove.len]")

	for(var/obj/effect/awaymission/blackmesa/difficulty_trigger/T in triggers_to_remove)
		if(T)
			log_world("Removing trigger zone #[trigger_level] at [T]")
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
