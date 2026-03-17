/datum/dm_modifer
	var/obj/new_belly/host_belly

/datum/dm_modifer/New(obj/new_belly/belly_to_link, post_belly_add = FALSE)
	if((!belly_to_link || QDELING(belly_to_link)) && !post_belly_add)
		qdel(src)
		stack_trace("Не по людски нихуя. [src]")
		return

	host_belly = belly_to_link

/datum/dm_modifer/proc/on_get()

/datum/dm_modifer/proc/modifer_process()

/datum/dm_modifer/proc/on_lose()
