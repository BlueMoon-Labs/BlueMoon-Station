#define SPAWN_ALWAYS 100
#define SPAWN_LIKELY 85
#define SPAWN_UNLIKELY 35
#define SPAWN_RARE 10

/obj/effect/landmark/bitrunning/mob_segment/proc/spawn_mobs(turf/origin, datum/modular_mob_segment/segment)
	var/list/mob/living/spawned_mobs = list()

	spawned_mobs += segment.spawn_mobs(origin)

	SEND_SIGNAL(src, COMSIG_BITRUNNING_MOB_SEGMENT_SPAWNED, spawned_mobs)

	var/list/datum/weakref/mob_refs = list()
	for(var/mob/living/spawned as anything in spawned_mobs)
		if(QDELETED(spawned))
			continue

		mob_refs += WEAKREF(spawned)

	return mob_refs

/datum/modular_mob_segment
	var/exact = FALSE
	var/list/mobs = list()
	var/max = 4
	var/probability = SPAWN_LIKELY

// Мобы модульных сегментов спавнятся по кругу на свободных клетках.
/datum/modular_mob_segment/proc/spawn_mobs(turf/origin)
	if(!prob(probability))
		return

	var/list/mob/living/spawned_mobs = list()

	var/total_amount = exact ? length(mobs) : rand(1, max)

	shuffle_inplace(mobs)

	var/list/turf/nearby = list()
	for(var/turf/tile as anything in RANGE_TURFS(2, origin))
		if(!tile.is_blocked_turf())
			nearby += tile

	if(!length(nearby))
		stack_trace("Не удалось найти подходящие клетки для спавна")
		return

	for(var/index in 1 to total_amount)
		var/turf/destination = pick(nearby)

		var/path
		if(exact)
			path = mobs[index]
		else
			path = pick(mobs)

		var/mob/living/mob = new path(destination)
		nearby -= destination
		spawned_mobs += mob

	return spawned_mobs

/datum/modular_mob_segment/gondolas
	mobs = list(
		/mob/living/simple_animal/pet/gondola,
	)

/datum/modular_mob_segment/corgis
	max = 2
	mobs = list(
		/mob/living/simple_animal/pet/dog/corgi,
	)

/datum/modular_mob_segment/monkeys
	mobs = list(
		/mob/living/carbon/monkey,
	)

/datum/modular_mob_segment/syndicate_team
	mobs = list(
		/mob/living/simple_animal/hostile/syndicate/ranged,
		/mob/living/simple_animal/hostile/syndicate/melee,
	)

/datum/modular_mob_segment/syndicate_elite
	mobs = list(
		/mob/living/simple_animal/hostile/syndicate/melee,
		/mob/living/simple_animal/hostile/syndicate/ranged,
	)

/datum/modular_mob_segment/bears
	max = 2
	mobs = list(
		/mob/living/simple_animal/hostile/bear,
	)

/datum/modular_mob_segment/bees
	exact = TRUE
	mobs = list(
		/mob/living/simple_animal/hostile/poison/bees,
		/mob/living/simple_animal/hostile/poison/bees,
		/mob/living/simple_animal/hostile/poison/bees,
		/mob/living/simple_animal/hostile/poison/bees,
		/mob/living/simple_animal/hostile/poison/bees,
	)

/datum/modular_mob_segment/bees_toxic
	mobs = list(
		/mob/living/simple_animal/hostile/poison/bees,
	)

/datum/modular_mob_segment/blob_spores
	mobs = list(
		/mob/living/simple_animal/hostile/blob,
	)

/datum/modular_mob_segment/carps
	mobs = list(
		/mob/living/simple_animal/hostile/carp,
	)

/datum/modular_mob_segment/hivebots
	mobs = list(
		/mob/living/simple_animal/hostile/hivebot,
		/mob/living/simple_animal/hostile/hivebot/range,
	)

/datum/modular_mob_segment/hivebots_strong
	mobs = list(
		/mob/living/simple_animal/hostile/hivebot/strong,
		/mob/living/simple_animal/hostile/hivebot/range,
	)

/datum/modular_mob_segment/lavaland_assorted
	mobs = list(
		/mob/living/simple_animal/hostile/asteroid/basilisk,
		/mob/living/simple_animal/hostile/asteroid/goliath,
		/mob/living/simple_animal/hostile/asteroid/lobstrosity,
	)

/datum/modular_mob_segment/spiders
	mobs = list(
		/mob/living/simple_animal/hostile/poison/giant_spider,
		/mob/living/simple_animal/hostile/poison/giant_spider/hunter,
		/mob/living/simple_animal/hostile/poison/giant_spider/nurse,
		/mob/living/simple_animal/hostile/poison/giant_spider/tarantula,
		/mob/living/simple_animal/hostile/poison/giant_spider/nurse/midwife,
	)

/datum/modular_mob_segment/venus_trap
	mobs = list(
		/mob/living/simple_animal/hostile/venus_human_trap,
	)

/datum/modular_mob_segment/xenos
	mobs = list(
		/mob/living/simple_animal/hostile/alien,
		/mob/living/simple_animal/hostile/alien/sentinel,
		/mob/living/simple_animal/hostile/alien/drone,
	)

/mob/living/simple_animal/hostile/deer
	name = "doe"
	desc = "Кроткое лесное животное. Как оно вообще попало в космос?"
	icon_state = "deer-doe"
	icon_living = "deer-doe"
	icon_dead = "deer-doe-dead"
	gender = FEMALE
	mob_biotypes = MOB_ORGANIC|MOB_BEAST
	speak = list("Weeeeeeee?","Weeee","WEOOOOOOOOOO")
	speak_emote = list("grunts","grunts lowly")
	emote_hear = list("brays.")
	emote_see = list("shakes its head.")
	speak_chance = 1
	turns_per_move = 5
	see_in_dark = 6
	butcher_results = list(/obj/item/reagent_containers/food/snacks/meat/slab = 3)
	response_help_continuous = "pets"
	response_help_simple = "pet"
	response_disarm_continuous = "gently nudges"
	response_disarm_simple = "gently nudge"
	response_harm_continuous = "kicks"
	response_harm_simple = "kick"
	faction = list(FACTION_NEUTRAL)
	health = 75
	maxHealth = 75
	blood_volume = BLOOD_VOLUME_NORMAL
	footstep_type = FOOTSTEP_MOB_SHOE
	vocal_bark_id = "mutedc4"
	harm_intent_damage = 0
	obj_damage = 0
	melee_damage_lower = 0
	melee_damage_upper = 0
	attack_verb_continuous = "bucks"
	attack_verb_simple = "buck"
	attack_sound = 'sound/weapons/punch1.ogg'
	ai_profile_type = /datum/ai_controller/hostile_adapter/skittish

/datum/modular_mob_segment/deer
	max = 1
	mobs = list(
		/mob/living/simple_animal/hostile/deer,
	)

/datum/modular_mob_segment/revolutionary
	max = 2
	probability = 50
	mobs = list(
		/mob/living/simple_animal/hostile/nanotrasen/ranged/smg,
		/mob/living/simple_animal/hostile/syndicate/ranged/smg,
	)

#undef SPAWN_ALWAYS
#undef SPAWN_LIKELY
#undef SPAWN_UNLIKELY
#undef SPAWN_RARE

// Виртуальный домен: карта, награда, мобы и модульные сегменты.
/datum/lazy_template/virtual_domain
	map_dir = "_maps/virtual_domains"
	map_name = "None"
	key = "Virtual Domain"
	place_on_top = FALSE
	var/announce_to_ghosts = FALSE
	var/start_time

	var/cost = BITRUNNER_COST_NONE
	var/desc = "Карта."
	var/difficulty = BITRUNNER_DIFFICULTY_NONE
	var/help_text
	var/list/ambient_sounds
	var/name = "Virtual Domain"
	var/reward_points = BITRUNNER_REWARD_MIN
	var/domain_flags = NONE

	var/datum/outfit/forced_outfit

	var/list/completion_loot
	var/list/secondary_loot = list()
	var/secondary_loot_generated
	var/disk_reward_spawned = FALSE

	var/is_modular = FALSE
	var/list/datum/modular_mob_segment/mob_modules = list()
	var/modular_unique_mobs = FALSE

	var/list/custom_spawns = list()
	var/keep_custom_spawns = FALSE
	var/mission_min_candidates = 0
	var/mission_max_candidates = 0
	var/list/obj/effect/mob_spawn/human/virtual_domain/ghost_spawners = list()
	var/list/mob/living/ghost_mobs = list()
	var/spawner_role = "Antagonist"

/datum/lazy_template/virtual_domain/proc/can_view_name(scanner_tier, server_points)
	return difficulty < scanner_tier && cost <= server_points + 5

/datum/lazy_template/virtual_domain/proc/can_view_reward(scanner_tier, server_points)
	return difficulty < (scanner_tier + 1) && cost <= server_points + 3

/datum/lazy_template/virtual_domain/Destroy(force)
	QDEL_LIST(ghost_spawners)
	QDEL_LIST(ghost_mobs)
	. = ..()

/datum/lazy_template/virtual_domain/proc/add_points(points_to_add = 1)
	SEND_SIGNAL(src, COMSIG_BITRUNNER_GOAL_POINT, points_to_add)

/datum/lazy_template/virtual_domain/proc/load_advanced_npcs(list/mob/lucky_ghosts)
	for(var/mob/lucky_ghost as anything in lucky_ghosts)
		var/obj/effect/mob_spawn/human/virtual_domain/ghost_spawner = pick(ghost_spawners)
		LAZYREMOVE(ghost_spawners, ghost_spawner)

		var/mob/new_mob = ghost_spawner.create(lucky_ghost.ckey)
		LAZYADD(ghost_mobs, new_mob)

		var/ghostname = lucky_ghost.name
		notify_ghosts("[ghostname] выбран на роль [ghost_spawner.mob_name]!", source = new_mob, header = "001010110")

/datum/lazy_template/virtual_domain/proc/setup_domain(list/created_atoms)
	return
