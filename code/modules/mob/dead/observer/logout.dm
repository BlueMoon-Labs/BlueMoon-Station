/mob/dead/observer/Logout()
	update_z(null)
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
	if(!QDELING(src))
		spawn(0)
			if(src && !key)	//we've transferred to another mob. This ghost should be deleted.
				qdel(src)
