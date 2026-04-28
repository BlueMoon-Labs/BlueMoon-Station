/// Fires projectiles along the hyperspace flow toward the shuttle.
/datum/shuttle_event/simple_spawner/projectile
	var/angle_spread = 0

/datum/shuttle_event/simple_spawner/projectile/post_spawn(atom/movable/spawnee)
	. = ..()
	if(isprojectile(spawnee))
		var/obj/item/projectile/pew = spawnee
		var/angle = dir2angle(REVERSE_DIR(port.preferred_direction)) + rand(-angle_spread, angle_spread)
		pew.fire(angle)

/datum/shuttle_event/simple_spawner/projectile/fireball
	name = "Залп огненных шаров"
	activation_fraction = 0.5
	spawning_list = list(/obj/item/projectile/magic/aoe/fireball = 1)
	angle_spread = 10
	spawns_per_spawn = 10
	spawning_flags = SHUTTLE_EVENT_HIT_SHUTTLE
	spawn_probability_per_process = 2
	self_destruct_when_empty = TRUE
