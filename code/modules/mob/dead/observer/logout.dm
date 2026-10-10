/mob/dead/observer/Logout()
	update_z(null)
	if(ghost_t_ray_timer)
		deltimer(ghost_t_ray_timer)
		ghost_t_ray_timer = null
	if (client)
		client.images -= (GLOB.ghost_images_default+GLOB.ghost_images_simple)
	lastclienttime = world.time //BLUEMOON ADD фиксируем время выхода игрока

	if(observetarget)
		if(ismob(observetarget))
			var/mob/target = observetarget
			if(target.observers)
				target.observers -= src
				UNSETEMPTY(target.observers)
			observetarget = null
	..()
	if(!QDELING(src) && !key && !keep_while_keyless)
		qdel(src)
