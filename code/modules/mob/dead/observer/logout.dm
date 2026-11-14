/mob/dead/observer/Logout()
	update_z(null)
	if(ghost_t_ray_timer)
		deltimer(ghost_t_ray_timer)
		ghost_t_ray_timer = null
	if (client)
		switch(lastsetting)
			if(GHOST_OTHERS_DEFAULT_SPRITE)
				client.images -= GLOB.ghost_images_default
			if(GHOST_OTHERS_SIMPLE)
				client.images -= GLOB.ghost_images_simple
	lastclienttime = world.time //BLUEMOON ADD фиксируем время выхода игрока

	if(observetarget)
		if(ismob(observetarget))
			var/mob/target = observetarget
			if(target.observers)
				target.observers -= src
				UNSETEMPTY(target.observers)
			observetarget = null
	..()
	mind?.current?.loc?.on_log(FALSE)
	if(!QDELING(src) && !key && !keep_while_keyless)
		qdel(src)
