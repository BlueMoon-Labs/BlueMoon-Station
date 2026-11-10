/mob/dead/observer/Logout()
	update_z(null)
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
	if(!QDELING(src) && !key)
		qdel(src)
