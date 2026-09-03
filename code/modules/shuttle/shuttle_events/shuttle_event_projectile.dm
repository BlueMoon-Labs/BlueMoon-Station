/// Fires projectiles along the hyperspace flow toward the shuttle.
/datum/shuttle_event/simple_spawner/projectile
	event_probability = 0
	var/angle_spread = 0

/datum/shuttle_event/simple_spawner/projectile/post_spawn(atom/movable/spawnee)
	. = ..()
	ADD_TRAIT(spawnee, TRAIT_FREE_HYPERSPACE_MOVEMENT, INNATE_TRAIT)
	if(isprojectile(spawnee))
		var/obj/item/projectile/pew = spawnee
		var/angle = dir2angle(REVERSE_DIR(port.preferred_direction)) + rand(-angle_spread, angle_spread)
		pew.fire(angle)

/datum/shuttle_event/simple_spawner/projectile/fireball
	name = "Залп огненных шаров"
	event_probability = 20
	activation_fraction = 0.5
	spawning_list = list(/obj/item/projectile/magic/aoe/fireball = 1)
	angle_spread = 10
	spawns_per_spawn = 10
	spawning_flags = SHUTTLE_EVENT_HIT_SHUTTLE
	spawn_probability_per_process = 2
	self_destruct_when_empty = TRUE

/// 7.12x82mm SAW — dense stream through the shuttle hull line.
/datum/shuttle_event/simple_spawner/projectile/lmg_barrage
	name = "Обстрел из пулемёта"
	event_probability = 12
	activation_fraction = 0.35
	spawning_list = list(
		/obj/item/projectile/bullet/mm712x82 = 6,
		/obj/item/projectile/bullet/mm712x82_ap = 3,
		/obj/item/projectile/bullet/incendiary/mm712x82 = 2,
	)
	angle_spread = 18
	spawns_per_spawn = 20
	spawning_flags = SHUTTLE_EVENT_HIT_SHUTTLE
	spawn_probability_per_process = 6
	self_destruct_when_empty = TRUE

/// Syndicate turret sweep plus ricocheting shrapnel pellets.
/datum/shuttle_event/simple_spawner/projectile/syndicate_strafe
	name = "Синдикатский зачисточный огонь"
	event_probability = 8
	activation_fraction = 0.45
	spawning_list = list(
		/obj/item/projectile/bullet/syndicate_turret = 5,
		/obj/item/projectile/bullet/pellet/stingball/shred = 2,
		/obj/item/projectile/bullet/pellet/stingball/breaker = 1,
	)
	angle_spread = 25
	spawns_per_spawn = 18
	spawning_flags = SHUTTLE_EVENT_HIT_SHUTTLE | SHUTTLE_EVENT_MISS_SHUTTLE
	spawn_probability_per_process = 4
	self_destruct_when_empty = TRUE

/// Standard laser sweep along the shuttle transit corridor.
/datum/shuttle_event/simple_spawner/projectile/laser_barrage
	name = "Обстрел лазером"
	event_probability = 14
	activation_fraction = 0.35
	spawning_list = list(
		/obj/item/projectile/beam/laser = 10,
		/obj/item/projectile/beam/laser/heavylaser = 2,
		/obj/item/projectile/beam/scatter = 3,
	)
	angle_spread = 12
	spawns_per_spawn = 16
	spawning_flags = SHUTTLE_EVENT_HIT_SHUTTLE
	spawn_probability_per_process = 5
	self_destruct_when_empty = TRUE

/// Piercing x-ray beam — passes through bodies and walls, reflects off laser defenses.
/datum/shuttle_event/simple_spawner/projectile/xray_barrage
	name = "Обстрел рентгеновским лазером"
	event_probability = 6
	activation_fraction = 0.45
	spawning_list = list(/obj/item/projectile/beam/xray = 1)
	angle_spread = 8
	spawns_per_spawn = 14
	spawning_flags = SHUTTLE_EVENT_HIT_SHUTTLE | SHUTTLE_EVENT_MISS_SHUTTLE
	spawn_probability_per_process = 3
	self_destruct_when_empty = TRUE
