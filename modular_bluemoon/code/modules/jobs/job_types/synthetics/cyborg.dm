/datum/job/cyborg/after_spawn(mob/living/silicon/robot/R, client/player_client)
	. = ..()
	if(!istype(R))
		return

	if(!player_client?.prefs?.silicon_lawset || !R.laws)
		return
	var/list/laws = CONFIG_GET(keyed_list/choosable_laws)
	var/law_path = text2path(laws[player_client.prefs.silicon_lawset])
	if(!ispath(law_path, /obj/item/ai_module))
		return
	var/obj/item/ai_module/chosenboard = new law_path
	chosenboard.install(R.laws, R)
	qdel(chosenboard)
