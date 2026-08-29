SUBSYSTEM_DEF(nocrash)
	name = "NoCrash Counter"
	flags = SS_NO_FIRE
	init_order = INIT_ORDER_TITLE + 1

	var/count = 0
	var/round_counted = FALSE
	var/file_path = "data/nocrash_counter.json"

/datum/controller/subsystem/nocrash/Initialize(timeofday)
	Load()
	RegisterSignal(SSticker, COMSIG_TICKER_ENTER_SETTING_UP, PROC_REF(on_round_setup))
	return ..()

/datum/controller/subsystem/nocrash/Destroy()
	UnregisterSignal(SSticker, COMSIG_TICKER_ENTER_SETTING_UP)
	return ..()

/datum/controller/subsystem/nocrash/proc/Load()
	if(fexists(file_path))
		var/list/data = json_decode(file2text(file_path))
		if(islist(data) && isnum(data["count"]))
			count = data["count"]
	if(count < 0)
		count = 0

/datum/controller/subsystem/nocrash/proc/Save()
	var/list/data = list("count" = count)
	var/F = file(file_path)
	WRITE_FILE(F, json_encode(data))

/datum/controller/subsystem/nocrash/proc/on_round_setup()
	SIGNAL_HANDLER
	round_counted = FALSE
	if(!SSpersistence.CheckGracefulEnding())
		count = 0
		Save()
		push_all()

/datum/controller/subsystem/nocrash/proc/on_round_end()
	if(round_counted)
		return
	round_counted = TRUE
	count++
	Save()
	push_all()

/datum/controller/subsystem/nocrash/proc/push_to(mob/dead/new_player/player)
	if(!(istype(player) && player.bm_lobby_ready && player.client))
		return
	player.client << output(count, "bm_lobby_browser:bm_update_nocrash")

/datum/controller/subsystem/nocrash/proc/push_all()
	for(var/mob/dead/new_player/player as anything in GLOB.new_player_list)
		push_to(player)
