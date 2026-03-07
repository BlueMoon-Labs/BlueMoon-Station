/datum/job/ai/after_spawn(mob/H, client/C, latejoin)
	. = ..()
	var/mob/living/silicon/ai/AI = H
	if(!istype(AI))
		return

	if(C.prefs.silicon_lawset)
		var/list/laws = CONFIG_GET(keyed_list/choosable_laws)
		var/law_path = text2path(laws[C.prefs.silicon_lawset])
		if(ispath(law_path))
			var/obj/item/ai_module/chosenboard = new law_path
			chosenboard.install(AI.laws, usr)
			qdel(chosenboard)
