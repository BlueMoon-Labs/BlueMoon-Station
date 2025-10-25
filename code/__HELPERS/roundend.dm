
#define POPCOUNT_SURVIVORS "survivors"					//Not dead at roundend
#define POPCOUNT_DEADS "deads"							//Dead at roundend
#define POPCOUNT_ESCAPEES "escapees"					//Not dead and on centcom/shuttles marked as escaped
#define POPCOUNT_SHUTTLE_ESCAPEES "shuttle_escapees" 	//Emergency shuttle only
#define POPCOUNT_ANOTHER_ESCAPEES "another_escapees" 	//Another way than shuttle to escape
#define PERSONAL_LAST_ROUND "personal last round"
#define SERVER_LAST_ROUND "server last round"

/datum/controller/subsystem/ticker/proc/gather_roundend_feedback()
	gather_antag_data()
	record_nuke_disk_location()
	var/json_file = file("[GLOB.log_directory]/round_end_data.json")
	// All but npcs sublists and ghost category contain only mobs with minds
	var/list/file_data = list("escapees" = list("humans" = list(), "silicons" = list(), "others" = list(), "npcs" = list()), "abandoned" = list("humans" = list(), "silicons" = list(), "others" = list(), "npcs" = list()), "ghosts" = list(), "additional data" = list())
	var/num_survivors = 0 //Count of non-brain non-camera mobs with mind that are alive
	var/num_deads = 0 //Count of non-brain non-camera mobs with mind that are dead
	var/num_escapees = 0 //Above and on centcom z
	var/num_shuttle_escapees = 0 //Above and on escape shuttle
	var/num_another_escapees = 0 //Above and on escape pod or anothers ways
	var/list/area/shuttle_areas
	if(SSshuttle?.emergency)
		shuttle_areas = SSshuttle.emergency.shuttle_areas

	for(var/mob/M in GLOB.mob_list)
		var/list/mob_data = list()
		if(isnewplayer(M))
			continue

		var/escape_status = "abandoned" //default to abandoned
		var/category = "npcs" //Default to simple count only bracket
		var/count_only = TRUE //Count by name only or full info

		mob_data["name"] = M.name
		if(M.mind)
			count_only = FALSE
			mob_data["ckey"] = M.mind.key
			if(M.stat != DEAD && !isbrain(M) && !iscameramob(M))
				num_survivors++
				if(EMERGENCY_ESCAPED_OR_ENDGAMED && (M.onCentCom() || M.onSyndieBase()))
					num_escapees++
					escape_status = "escapees"
					if(shuttle_areas[get_area(M)])
						num_shuttle_escapees++
					else
						num_another_escapees++ // Костыль, не проверяет зоны, как у "shuttle_areas". В идеале, нужно считать и поды, и тех, кто уже был на цк, имхо
			else
				num_deads++
			if(isliving(M))
				var/mob/living/L = M
				mob_data["location"] = get_area(L)
				mob_data["health"] = L.health
				if(ishuman(L))
					var/mob/living/carbon/human/H = L
					category = "humans"
					if(H.mind)
						mob_data["job"] = H.mind.assigned_role
					else
						mob_data["job"] = "Неизвестный"
					mob_data["species"] = H.dna.species.name
				else if(issilicon(L))
					category = "silicons"
					if(isAI(L))
						mob_data["module"] = AI_JF
					else if(ispAI(L))
						mob_data["module"] = "pAI"
					else if(iscyborg(L))
						var/mob/living/silicon/robot/R = L
						mob_data["module"] = R.module.name
				else
					category = "others"
					mob_data["typepath"] = M.type
		//Ghosts don't care about minds, but we want to retain ckey data etc
		if(isobserver(M))
			count_only = FALSE
			escape_status = "ghosts"
			if(!M.mind)
				mob_data["ckey"] = M.key
			category = null //ghosts are one list deep
		//All other mindless stuff just gets counts by name
		if(count_only)
			var/list/npc_nest = file_data["[escape_status]"]["npcs"]
			var/name_to_use = initial(M.name)
			if(ishuman(M))
				name_to_use = "Unknown Human" //Monkeymen and other mindless corpses
			if(npc_nest.Find(name_to_use))
				file_data["[escape_status]"]["npcs"][name_to_use] += 1
			else
				file_data["[escape_status]"]["npcs"][name_to_use] = 1
		else
			//Mobs with minds and ghosts get detailed data
			if(category)
				var/pos = length(file_data["[escape_status]"]["[category]"]) + 1
				file_data["[escape_status]"]["[category]"]["[pos]"] = mob_data
			else
				var/pos = length(file_data["[escape_status]"]) + 1
				file_data["[escape_status]"]["[pos]"] = mob_data

	var/datum/station_state/end_state = new /datum/station_state()
	end_state.count()
	var/station_integrity = min(PERCENT(GLOB.start_state.score(end_state)), 100)
	file_data["additional data"]["station integrity"] = station_integrity
	WRITE_FILE(json_file, json_encode(file_data))

	SSblackbox.record_feedback("nested tally", "round_end_stats", num_survivors, list("survivors", "total"))
	SSblackbox.record_feedback("nested tally", "round_end_stats", num_deads, list("deads", "total"))
	SSblackbox.record_feedback("nested tally", "round_end_stats", num_escapees, list("escapees", "total"))
	SSblackbox.record_feedback("nested tally", "round_end_stats", GLOB.joined_player_list.len, list("players", "total"))
	SSblackbox.record_feedback("nested tally", "round_end_stats", GLOB.joined_player_list.len - num_survivors, list("players", "dead"))
	. = list()
	.[POPCOUNT_SURVIVORS] = num_survivors
	.[POPCOUNT_DEADS] = num_deads
	.[POPCOUNT_ESCAPEES] = num_escapees
	.[POPCOUNT_SHUTTLE_ESCAPEES] = num_shuttle_escapees
	.[POPCOUNT_ANOTHER_ESCAPEES] = num_another_escapees
	.["station_integrity"] = station_integrity

/datum/controller/subsystem/ticker/proc/gather_antag_data()
	var/team_gid = 1
	var/list/team_ids = list()

	var/list/greentexters = list()
	var/list/antag_coins = list()
	var/list/client_antags = list() //amount of antags a client had
	var/max_antags = 5 //if a client has more than this it will not reward him with metacoins

	for(var/datum/antagonist/A in GLOB.antagonists)
		if(!A.owner)
			continue
		var/ckey = ckey(A.owner?.key)
		var/client/C = GLOB.directory[ckey]
		if(!(C in client_antags))
			client_antags[C] = 1
		else
			client_antags[C]++
		if(!(C in antag_coins))
			antag_coins[C] = list("reward"=5, "completed"=0)

		var/list/antag_info = list()
		antag_info["key"] = A.owner.key
		antag_info["name"] = A.owner.name
		antag_info["antagonist_type"] = A.type
		antag_info["antagonist_name"] = A.name //For auto and custom roles
		antag_info["objectives"] = list()
		antag_info["team"] = list()
		var/datum/team/T = A.get_team()
		if(T)
			antag_info["team"]["type"] = T.type
			antag_info["team"]["name"] = T.name
			if(!team_ids[T])
				team_ids[T] = team_gid++
			antag_info["team"]["id"] = team_ids[T]

		var/greentexted = TRUE

		if(A.objectives.len)
			for(var/datum/objective/O in A.objectives)
				var/result = O.check_completion() ? "SUCCESS" : "FAIL"
				if (result == "FAIL")
					greentexted = FALSE
				else if(client_antags[C] <= max_antags)
					antag_coins[C]["reward"]+=O.reward
					antag_coins[C]["completed"]++
				antag_info["objectives"] += list(list("objective_type"=O.type,"text"=O.explanation_text,"result"=result))
		SSblackbox.record_feedback("associative", "antagonists", 1, antag_info)

		if (greentexted)
			if(client_antags[C] <= max_antags)
				antag_coins[C]["reward"]+=A.greentext_reward
			if (A.owner && A.owner.key)
				if (A.type != /datum/antagonist/custom)
					if (C)
						greentexters |= C

/datum/controller/subsystem/ticker/proc/record_nuke_disk_location()
	var/obj/item/disk/nuclear/N = locate() in GLOB.poi_list
	if(N)
		var/list/data = list()
		var/turf/T = get_turf(N)
		if(T)
			data["x"] = T.x
			data["y"] = T.y
			data["z"] = T.z
		var/atom/outer = get_atom_on_turf(N,/mob/living)
		if(outer != N)
			if(isliving(outer))
				var/mob/living/L = outer
				data["holder"] = L.real_name
			else
				data["holder"] = outer.name

		SSblackbox.record_feedback("associative", "roundend_nukedisk", 1 , data)

/datum/controller/subsystem/ticker/proc/gather_newscaster()
	var/json_file = file("[GLOB.log_directory]/newscaster.json")
	var/list/file_data = list()
	var/pos = 1
	for(var/V in GLOB.news_network.network_channels)
		var/datum/news/feed_channel/channel = V
		if(!istype(channel))
			stack_trace("Non-channel in newscaster channel list")
			continue
		file_data["[pos]"] = list("channel name" = "[channel.channel_name]", "author" = "[channel.author]", "censored" = channel.censored ? 1 : 0, "author censored" = channel.authorCensor ? 1 : 0, "messages" = list())
		for(var/M in channel.messages)
			var/datum/news/feed_message/message = M
			if(!istype(message))
				stack_trace("Non-message in newscaster channel messages list")
				continue
			var/list/comment_data = list()
			for(var/C in message.comments)
				var/datum/news/feed_comment/comment = C
				if(!istype(comment))
					stack_trace("Non-message in newscaster message comments list")
					continue
				comment_data += list(list("author" = "[comment.author]", "time stamp" = "[comment.time_stamp]", "body" = "[comment.body]"))
			file_data["[pos]"]["messages"] += list(list("author" = "[message.author]", "time stamp" = "[message.time_stamp]", "censored" = message.bodyCensor ? 1 : 0, "author censored" = message.authorCensor ? 1 : 0, "photo file" = "[message.photo_file]", "photo caption" = "[message.caption]", "body" = "[message.body]", "comments" = comment_data))
		pos++
	if(GLOB.news_network.wanted_issue.active)
		file_data["wanted"] = list("author" = "[GLOB.news_network.wanted_issue.scannedUser]", "criminal" = "[GLOB.news_network.wanted_issue.criminal]", "description" = "[GLOB.news_network.wanted_issue.body]", "photo file" = "[GLOB.news_network.wanted_issue.photo_file]")
	WRITE_FILE(json_file, json_encode(file_data))

///Handles random hardcore point rewarding if it applies.
/datum/controller/subsystem/ticker/proc/HandleRandomHardcoreScore(client/player_client)
	if(!ishuman(player_client.mob))
		return FALSE
	var/mob/living/carbon/human/human_mob = player_client.mob
	if(!human_mob.hardcore_survival_score) ///no score no glory
		return FALSE

	if(human_mob.mind && (human_mob.mind.special_role || length(human_mob.mind.antag_datums) > 0))
		var/didthegamerwin = TRUE
		for(var/a in human_mob.mind.antag_datums)
			var/datum/antagonist/antag_datum = a
			for(var/i in antag_datum.objectives)
				var/datum/objective/objective_datum = i
				if(!objective_datum.check_completion())
					didthegamerwin = FALSE
		if(!didthegamerwin)
			return FALSE
		player_client.give_award(/datum/award/score/hardcore_random, human_mob, round(human_mob.hardcore_survival_score))
	else if(human_mob.onCentCom())
		player_client.give_award(/datum/award/score/hardcore_random, human_mob, round(human_mob.hardcore_survival_score))


/datum/controller/subsystem/ticker/proc/declare_completion()
	set waitfor = FALSE

	to_chat(world, "<BR><BR><BR><span class='big bold'>The round has ended.</span>")
	log_game("The round has ended.")

	CONFIG_SET(flag/suicide_allowed,TRUE) // EORG suicides allowed

	for(var/I in round_end_events)
		var/datum/callback/cb = I
		cb.InvokeAsync()
	LAZYCLEARLIST(round_end_events)

	var/speed_round = FALSE
	if(world.time - SSticker.round_start_time <= 300 SECONDS)
		speed_round = TRUE

	for(var/client/C in GLOB.clients)
		if(!C.credits)
			C.RollCredits()
		C.playtitlemusic(40)
		if(speed_round)
			C.give_award(/datum/award/achievement/misc/speed_round, C.mob)
		HandleRandomHardcoreScore(C)

	var/popcount = gather_roundend_feedback()
	display_report(popcount)

	CHECK_TICK

	// Add AntagHUD to everyone, see who was really evil the whole time!
	if(CONFIG_GET(flag/reveal_everything))
		for(var/datum/atom_hud/antag/H in GLOB.huds)
			for(var/m in GLOB.player_list)
				var/mob/M = m
				H.add_hud_to(M)
		CHECK_TICK

	//Set news report and mode result
	mode.set_round_result()

	var/survival_rate = GLOB.joined_player_list.len ? "[PERCENT(popcount[POPCOUNT_SURVIVORS]/GLOB.joined_player_list.len)]%" : "there's literally no player"

	send2chat("Server", "A round of [mode.name] just ended[mode_result == "undefined" ? "." : " with a [mode_result]."] Survival rate: [survival_rate]")

	if(length(CONFIG_GET(keyed_list/cross_server)))
		send_news_report()

	//tell the nice people on discord what went on before the salt cannon happens.
	if(CONFIG_GET(string/chat_roundend_notice_tag))
		var/broadcastmessage = ""

		if(LAZYLEN(GLOB.round_end_notifiees))
			broadcastmessage += "[GLOB.round_end_notifiees.Join(", ")], "


		broadcastmessage += "[((broadcastmessage == "") ? "The" : "the")] current round has ended. Please standby for your shift interlude Nanotrasen News Network's report!\n"
		broadcastmessage += "```\n[send_news_report()]\n```"

		if(CONFIG_GET(string/chat_reboot_role))
			broadcastmessage += "\n\n<@&[CONFIG_GET(string/chat_reboot_role)]>, the server will reboot shortly!"

		send2chat(new /datum/tgs_message_content(broadcastmessage), CONFIG_GET(string/chat_roundend_notice_tag))

	CHECK_TICK

	handle_hearts()

	if(CONFIG_GET(flag/reveal_everything))
		set_observer_default_invisibility(0, "<span class='warning'>The round is over! You are now visible to the living.</span>")
		CHECK_TICK

	//These need update to actually reflect the real antagonists
	//Print a list of antagonists to the server log
	var/list/total_antagonists = list()
	//Look into all mobs in world, dead or alive
	for(var/datum/antagonist/A in GLOB.antagonists)
		if(!A.owner)
			continue
		if(!(A.name in total_antagonists))
			total_antagonists[A.name] = list()
		total_antagonists[A.name] += "[key_name(A.owner)]"

	CHECK_TICK

	//Now print them all into the log!
	log_game("Antagonists at round end were...")
	for(var/antag_name in total_antagonists)
		var/list/L = total_antagonists[antag_name]
		log_game("[antag_name]s :[L.Join(", ")].")

	send_roundend_stats_tgs_message(popcount) //BLUEMOON EDIT: TGS ROUND END STATS

	CHECK_TICK
	SSdbcore.SetRoundEnd()
	//Collects persistence features
	if(mode.allow_persistence_save)
		SSpersistence.SaveTCGCards()
		SSpersistence.CollectData()

	//stop collecting feedback during grifftime
	SSblackbox.Seal()

	sleep(50)
	ready_for_reboot = TRUE
	standard_reboot()

/datum/controller/subsystem/ticker/proc/standard_reboot()
	if(ready_for_reboot)
		if(mode.station_was_nuked)
			Reboot("Станция уничтожена Ядерной бомбой.", "nuke")
		else
			Reboot("КОНЕЦ РАУНДА! ЕОРГ ТОЛЬКО НА ЕОРГ-АРЕНЕ!!", "proper completion")
	else
		CRASH("Attempted standard reboot without ticker roundend completion")

//Common part of the report
/datum/controller/subsystem/ticker/proc/build_roundend_report()
	var/list/parts = list()

	//Gamemode specific things. Should be empty most of the time.
	parts += mode.special_report()

	CHECK_TICK

	//AI laws
	parts += law_report()

	CHECK_TICK

	//Antagonists
	parts += antag_report()

	parts += hardcore_random_report()

	CHECK_TICK
	//Medals
	parts += medal_report()
	//Station Goals
	parts += goal_report()
	//Economy & Money
//	parts += market_report()
	//Ambitions
	parts += ambitions_report()

	listclearnulls(parts)

	return parts.Join()

/datum/controller/subsystem/ticker/proc/survivor_report(popcount)
	var/list/parts = list()
	var/station_evacuated = EMERGENCY_ESCAPED_OR_ENDGAMED

	parts += "<hr><b><font color=\"#60b6ff\">ИНФОРМАЦИЯ О РАУНДЕ //</font></b>"
	if(GLOB.round_id)
		var/statspage = CONFIG_GET(string/roundstatsurl)
		var/info = statspage ? "<a href='?action=openLink&link=[url_encode(statspage)][GLOB.round_id]'>[GLOB.round_id]</a>" : GLOB.round_id
		parts += "[FOURSPACES]├ ID раунда: <b>[info]</b>"
	else
		parts += "[FOURSPACES]├ ID раунда: <b>(<i>недоступно</i>)</b>"
	parts += "[FOURSPACES]└ Длительность смены: <b>[DisplayTimeText(world.time - SSticker.round_start_time)]</b>"
	// --- BLUEMOON ADD: узлирования ---
	if(GLOB.knottings)
		parts += "[FOURSPACES] Узлирований членов экипажа за раунд: <b>[GLOB.knottings]</b>"

	parts += "<hr><b><font color=\"#60b6ff\">ИНФОРМАЦИЯ О СТАНЦИИ //</font></b>"
	parts += "[FOURSPACES]└ Состояние станции: <b>[mode.station_was_nuked ? span_redtext("уничтожена системой ядерного самоуничтожения")  : "[popcount["station_integrity"] == 100 ? span_greentext("нетронута")  : "[popcount["station_integrity"]]%"]"]</b>"

	parts += "<hr><b><font color=\"#60b6ff\">ИНФОРМАЦИЯ О ПЕРСОНАЛЕ //</font></b>"
	var/total_players = GLOB.joined_player_list.len
	if(total_players)
		parts += "[FOURSPACES]├ За всю смену на станцию прибыло: <b>[total_players]</b>" // суммарно
		parts += "[FOURSPACES]├ Из прибывших погибло: <b>[popcount[POPCOUNT_DEADS]]</b> (или <b>[PERCENT(popcount[POPCOUNT_DEADS]/total_players)]%</b> от прибывших)"
		parts += "[FOURSPACES]├ Из прибывших выжило: <b>[popcount[POPCOUNT_SURVIVORS]]</b> (или <b>[PERCENT(popcount[POPCOUNT_SURVIVORS]/total_players)]%</b> от прибывших)"
		parts += "[FOURSPACES]└ <b><font color=\"#60b6ff\">ИНФОРМАЦИЯ ОБ ЭВАКУИРОВАВШИХСЯ //</font></b>"
		if(station_evacuated)
			parts += "[FOURSPACES][FOURSPACES]├ Эвакуировались: <b>[popcount[POPCOUNT_ESCAPEES]]</b> (или <b>[PERCENT(popcount[POPCOUNT_ESCAPEES]/total_players)]%</b> от выживших)"
			parts += "[FOURSPACES][FOURSPACES]├ На шаттле: <b>[popcount[POPCOUNT_SHUTTLE_ESCAPEES]]</b> (или <b>[PERCENT(popcount[POPCOUNT_SHUTTLE_ESCAPEES]/total_players)]%</b> от выживших)"
			parts += "[FOURSPACES][FOURSPACES]└ На подах <small>(или иными способами)</small>: <b>[popcount[POPCOUNT_ANOTHER_ESCAPEES]]</b> (или <b>[PERCENT(popcount[POPCOUNT_ANOTHER_ESCAPEES]/total_players)]%</b> от выживших)" // КОСТЫЛЬ: на самом деле все, кто не на шаттле, то есть на подах или кто уже был на ЦК
		else
			parts += "[FOURSPACES][FOURSPACES]└ <i><span class='redtext'>Из выживших никто не эвакуировался, ни на шаттле, ни на поде, ни любым другим способом</span>.</i>"
		parts += "<hr><b><font color=\"#60b6ff\">ИНФОРМАЦИЯ О ПЕРВОЙ СМЕРТИ //</font></b>"
		if(SSblackbox.first_death)
			var/list/first_death = SSblackbox.first_death
			if(first_death.len)
				parts += "[FOURSPACES]├ Имя: <b>[first_death["name"]]</b>"
				parts += "[FOURSPACES]├ Должность: <b>[first_death["role"]]</b>"
				parts += "[FOURSPACES]├ Локация: <b>[first_death["area"]]</b>"
				parts += "[FOURSPACES]├ Повреждения: <b>[first_death["damage"]]</b>"
				parts += "[FOURSPACES]└ Его последние слова: <b>[first_death["last_words"] ? "[first_death["last_words"]]" : "<i>отсутствовали</i>"]</b>"
				// ignore this comment, it fixes the broken sytax parsing caused by the " above
			else
				parts += "[FOURSPACES]└ <span class='greentext'>Никто не умер за смену</span>!"
	else
		parts += "[FOURSPACES]└ <i><span class='redtext'>Персонал станции отсутствует. Кто вызвал шаттл и закончил раунд</span>?</i>"

	if(istype(SSticker.mode, /datum/game_mode/dynamic))
		parts += "<hr><b><font color=\"#60b6ff\">ИНФОРМАЦИЯ О ДИНАМИЧЕСКОМ РЕЖИМЕ //</font></b>"
		var/datum/game_mode/dynamic/mode = SSticker.mode
		parts += "[FOURSPACES]├ Уровень угрозы: [mode.threat_level]"
		parts += "[FOURSPACES]├ Оставшаяся угроза: [mode.mid_round_budget]"
		parts += "[FOURSPACES]└ Правила:"
		for(var/datum/dynamic_ruleset/rule in mode.executed_rules)
			parts += "[FOURSPACES]─ [rule.ruletype] - <b>[rule.name]</b>: -[rule.cost + rule.scaled_times * rule.scaling_cost] очков угрозы"
		if(!mode.executed_rules.len)
			parts += "[FOURSPACES]└ <i>Вычиты очков угрозы отсутствуют</i>."
	return parts.Join("<br>")

/client/proc/roundend_report_file()
	return "data/roundend_reports/[ckey].html"

/**
 * Log the round-end report as an HTML file
 *
 * Composits the roundend report, and saves it in two locations.
 * The report is first saved along with the round's logs
 * Then, the report is copied to a fixed directory specifically for
 * housing the server's last roundend report. In this location,
 * the file will be overwritten at the end of each shift.
 */
/datum/controller/subsystem/ticker/proc/log_roundend_report()
	var/filename = "[GLOB.log_directory]/round_end_data.html"
	var/list/parts = list()
	parts += GLOB.survivor_report
	parts += "</div>"
	parts += GLOB.common_report
	var/content = parts.Join()
	//Log the rendered HTML in the round log directory
	fdel(filename)
	text2file(content, filename)
	//Place a copy in the root folder, to be overwritten each round.
	filename = "data/server_last_roundend_report.html"
	fdel(filename)
	text2file(content, filename)

/datum/controller/subsystem/ticker/proc/show_roundend_report(client/C, report_type = null)
	var/datum/browser/roundend_report = new(C, "roundend")
	roundend_report.width = 800
	roundend_report.height = 600
	var/content
	var/filename = C.roundend_report_file()
	if(report_type == PERSONAL_LAST_ROUND) //Look at this player's last round
		content = file2text(filename)
	else if (report_type == SERVER_LAST_ROUND) //Look at the last round that this server has seen
		content = file2text("data/server_last_roundend_report.html")
	else //report_type is null, so make a new report based on the current round and show that to the player
		var/list/report_parts = list(personal_report(C), GLOB.common_report)
		content = report_parts.Join()
		remove_verb(C, /client/proc/show_previous_roundend_report)
		fdel(filename)
		text2file(content, filename)

	roundend_report.set_content(content)
	roundend_report.stylesheets = list()
	roundend_report.add_stylesheet("roundend", 'html/browser/roundend.css')
	roundend_report.add_stylesheet("font-awesome", 'html/font-awesome/css/all.min.css')
	roundend_report.open(FALSE)

/datum/controller/subsystem/ticker/proc/personal_report(client/C, popcount)
	var/list/parts = list()
	var/mob/M = C.mob
	parts += "<br><center><span class='big bold'>Конец раунда</span></center>"
	parts += "<center>Подсчитываем выживших…</center><br>"
	if(M.mind && !isnewplayer(M))
		if(M.stat != DEAD && !isbrain(M))
			if(EMERGENCY_ESCAPED_OR_ENDGAMED)
				if(!M.onCentCom() && !M.onSyndieBase())
					parts += "<div class='panel stationborder'>"
					parts += span_marooned("Тебе удалось пережить события, будучи [M.real_name], но пришлось остаться на станции [station_name()]...")
				else
					parts += "<div class='panel greenborder'>"
					parts += span_greentext("Тебе удалось пережить события, произошедшие на станции [station_name()], будучи [M.real_name]!")
			else
				parts += "<div class='panel greenborder'>"
				parts += span_greentext("Тебе удалось пережить события, произошедшие на станции [station_name()], будучи [M.real_name]!")

		else
			parts += "<div class='panel redborder'>"
			parts += span_redtext("Будучи [M.real_name], тебе не удалось пережить события, произошедшие на станции [station_name()]...")
	else
		parts += "<div class='panel stationborder'>"
	parts += "<br>"
	parts += GLOB.survivor_report
	parts += "</div>"

	return parts.Join()

/datum/controller/subsystem/ticker/proc/display_report(popcount)
	GLOB.common_report = build_roundend_report()
	GLOB.survivor_report = survivor_report(popcount)
	log_roundend_report()
	for(var/client/C in GLOB.clients)
		show_roundend_report(C)
		give_show_report_button(C)
		CHECK_TICK

/datum/controller/subsystem/ticker/proc/law_report()
	var/list/parts = list()
	var/minion_spacer = FALSE //inserts an extra linebreak to seperate AIs from independent borgs, and then multiple independent borgs.

	//Silicon laws report
	parts += span_header("Информация о кремниевых формах жизни")
	parts += "<hr><b><font color=\"#60b6ff\">ИНФОРМАЦИЯ ОБ ИСКУСТВЕННЫХ ИНТЕЛЛЕКТАХ //</font></b>"
	var/count_ai = 0
	var/total_ai = GLOB.ai_list.len
	if(total_ai)
		count_ai = 0
		for(var/i in GLOB.ai_list)
			var/mob/living/silicon/ai/aiPlayer = i
			if(aiPlayer.mind)
				count_ai++
				parts += "▶ \[[count_ai]/[total_ai]\] <b><font color=\"#60b6ff\">[aiPlayer.name]</font></b> (игрок: <b>[aiPlayer.mind.key]</b>)"
				parts += "[FOURSPACES]├ Статус: [aiPlayer.stat != DEAD ? "<b>активен</b>" : span_redtext("деактивирован") ]"
				parts += "[FOURSPACES]├ Суммарное кол-во изменений законов: <b>[aiPlayer.law_change_counter == 0 ? span_greentext("изменения отсутствуют")  : span_redtext("[aiPlayer.law_change_counter]") ]</b>"
				parts += "[FOURSPACES]└ <font color=\"#60b6ff\">ЗАКОНЫ ИИ //</font>"
				var/list/temp_law_list = aiPlayer.laws.get_law_list(include_zeroth = TRUE)
				for(var/law in temp_law_list)
					parts += "[FOURSPACES][FOURSPACES] [law]"

			var/count_minion = 0
			var/total_ai_minion = aiPlayer.connected_robots.len
			parts += "[FOURSPACES] <font color=\"#60b6ff\">МИНЬОНЫ ИИ //</font>"
			if(total_ai_minion)
				count_minion = 0
				var/count_minion_spacer = total_ai_minion
				for(var/mob/living/silicon/robot/connected_minion in aiPlayer.connected_robots)
					count_minion++
					count_minion_spacer--
					if(connected_minion.mind)
						parts += "[FOURSPACES][FOURSPACES] — ([count_minion]/[total_ai_minion]) <b>[connected_minion.name]</b> (игрок: <b>[connected_minion.mind.key]</b>) [connected_minion.stat != DEAD ? "(<span class='greentext'>активен</span>)" : "(<span class='redtext'>деактивирован</span>)"] (законы синхронизируются)[count_minion_spacer ? ", " : "."]"
			else
				parts += "[FOURSPACES][FOURSPACES] — \[0/0\] <i>Миньоны отсутствуют</i>."

			if(!minion_spacer)
				minion_spacer = TRUE

	parts += "<hr><b><font color=\"#60b6ff\">ИНФОРМАЦИЯ О САМОСТОЯТЕЛЬНЫХ КИБОРГАХ //</font></b>"
	var/count_silicon = 0
	var/total_silicon = GLOB.silicon_mobs.len
	if(total_silicon)
		count_silicon = 0
		for(var/mob/living/silicon/robot/standalone_silicon in GLOB.silicon_mobs)
			count_silicon++
			if (!standalone_silicon.connected_ai && standalone_silicon.mind)
				parts += "▶ ([count_silicon]/[total_silicon]) [minion_spacer ? "<br>" : ""]<b><font color=\"#60b6ff\">[standalone_silicon.name]</font></b> (игрок: <b>[standalone_silicon.mind.key]</b>)"
				parts += "[FOURSPACES]├ Статус: [(standalone_silicon.stat != DEAD) ? "<span class='greentext'>выжил</span> как самостоятельный киборг без связи с ИИ!" : "<span class='redtext'>не смог выжить</span> в суровых условиях, будучи самостоятельным киборгом без связи с ИИ."]"
				parts += "[FOURSPACES]├ Суммарное кол-во изменений законов: <b>[standalone_silicon.law_change_counter == 0 ? span_greentext("изменения отсутствуют")  : span_redtext("[standalone_silicon.law_change_counter]") ]</b>"
				parts += "[FOURSPACES]└ <font color=\"#60b6ff\">ЗАКОНЫ КИБОРГА //</font>"

				if(standalone_silicon) //How the hell do we lose standalone_silicon between here and the world messages directly above this?
					var/list/temp_law_list = standalone_silicon.laws.get_law_list(include_zeroth = TRUE)
					for(var/law in temp_law_list)
						parts += "[FOURSPACES][FOURSPACES] [law]"

				if(!minion_spacer)
					minion_spacer = TRUE

	if(parts.len && (count_silicon || count_ai))
		return "<div class='panel stationborder'>[parts.Join("<br>")]</div>"
	else
		return ""

/datum/controller/subsystem/ticker/proc/goal_report()
	var/list/parts = list()
	if(mode.station_goals.len)
		for(var/V in mode.station_goals)
			var/datum/station_goal/G = V
			parts += G.get_result()
		return "<div class='panel stationborder'><ul>[parts.Join()]</ul></div>"

///Generate a report for how much money is on station, as well as the richest crewmember on the station.
///datum/controller/subsystem/ticker/proc/market_report()
//	var/list/parts = list()
//	///This is the richest account on station at roundend.
//	var/datum/bank_account/mr_moneybags
//	///This is the station's total wealth at the end of the round.
//	var/station_vault = 0
//	///How many players joined the round.
//	var/total_players = GLOB.joined_player_list.len
//	for(var/obj/item/card/id/id in SSeconomy.bank_accounts)
//		var/datum/bank_account/current_acc = SSeconomy.bank_accounts[id]
//		station_vault += current_acc.account_balance
//		if(!mr_moneybags || mr_moneybags.account_balance < current_acc.account_balance)
//			mr_moneybags = current_acc
//	parts += "<div class='panel stationborder'><span class='header'>Экономический отчёт</span><br>"
//	parts += "Всего было заработано [SSeconomy.station_total] кредитов экипажем.<br>"
//	if(total_players > 0)
//		parts += "В среднем каждый заработал [SSeconomy.station_total/total_players] кредитов.<br>"
//		log_econ("Roundend credit total: [station_vault] credits. Average Credits: [station_vault/total_players]")
//	if(mr_moneybags)
//		parts += "Самый богатый член экипажа был <b>[mr_moneybags.account_holder] с [mr_moneybags.account_balance]</b> заработанными кредитами!</div>"
//	else
//		parts += "Чудесным образом никто не заработал кредиты за эту смену! Придётся резать бюджеты...</div>"
//	return parts

/datum/controller/subsystem/ticker/proc/ambitions_report()
	var/list/parts = list()
	parts += "<div class='panel stationborder'><span class='header'>Отчёт по амбициям</span></br>"

	for(var/datum/mind/employee in SSticker.minds)

		if(!employee.ambition_objectives.len)//If the employee had no objectives, don't need to process this.
			continue

		if(employee.assigned_role == employee.special_role) //If the character is an offstation character, skip them.
			continue

		parts += "<b>[employee.name]</b> на должности <b>[employee.assigned_role]</b>:</br>"

		var/ambitions_completed = FALSE

		var/count = 1
		for(var/datum/ambition_objective/objective in employee.ambition_objectives)
			if(objective.completed)
				parts += "[FOURSPACES] - <B>Амбиция №[count]</B>: [objective.description] <font color='green'><B> реализована!</B></font></br>"
				SSblackbox.record_feedback("nested tally", "employee_objective", 1, list("[objective.type]", "SUCCESS"))
				ambitions_completed = TRUE
			else
				parts += "[FOURSPACES] - <B>Амбиция №[count]</B>: [objective.description] <font color='red'><b> не осуществлена.</b></font></br>"
				SSblackbox.record_feedback("nested tally", "employee_objective", 1, list("[objective.type]", "FAIL"))
			count++

		if(ambitions_completed)
			parts += "[FOURSPACES] - <font color='green'><B>[employee.name] реализует свои амбиции!</B></font></br>"
			SSblackbox.record_feedback("tally", "employee_success", 1, "SUCCESS")
		else
			SSblackbox.record_feedback("tally", "employee_success", 1, "FAIL")

	return parts

/**
 * Awards the service department an achievement and updates the chef and bartender's highscore for tourists served.
 *
 * Arguments:
 * * award: Achievement to give service department
 */
/datum/controller/subsystem/ticker/proc/award_service(award)
	for(var/mob/living/carbon/human/service_member as anything in GLOB.human_list)
		if(!service_member.mind)
			continue
		var/datum/mind/service_mind = service_member.mind
		if(!service_mind.assigned_role)
			continue
		for(var/job in GLOB.service_food_positions)
			if(service_mind.assigned_role != job)
				continue
			//general awards
			service_member.client?.give_award(award, service_member)

/datum/controller/subsystem/ticker/proc/medal_report()
	if(GLOB.commendations.len)
		var/list/parts = list()
		parts += span_header("Medal Commendations:")
		for (var/com in GLOB.commendations)
			parts += com
		return "<div class='panel stationborder'>[parts.Join("<br>")]</div>"
	return ""

///Generate a report for all players who made it out alive with a hardcore random character and prints their final score
/datum/controller/subsystem/ticker/proc/hardcore_random_report()
	. = list()
	var/list/hardcores = list()
	for(var/i in GLOB.player_list)
		if(!ishuman(i))
			continue
		var/mob/living/carbon/human/human_player = i
		if(!human_player.hardcore_survival_score || !human_player.onCentCom() || human_player.stat == DEAD) ///gotta escape nerd
			continue
		if(!human_player.mind)
			continue
		hardcores += human_player
	if(!length(hardcores))
		return
	. += "<div class='panel stationborder'><span class='header'>The following people made it out as a random hardcore character:</span>"
	. += "<ul class='playerlist'>"
	for(var/mob/living/carbon/human/human_player in hardcores)
		. += "<li>[printplayer(human_player.mind)] with a hardcore random score of [round(human_player.hardcore_survival_score)]</li>"
	. += "</ul></div>"

/datum/controller/subsystem/ticker/proc/antag_report()
	var/list/result = list()
	var/list/all_teams = list()
	var/list/all_antagonists = list()

	for(var/datum/team/A in GLOB.antagonist_teams)
		all_teams |= A

	for(var/datum/antagonist/A in GLOB.antagonists)
		if(!A.owner)
			continue
		all_antagonists |= A

	for(var/datum/team/T in all_teams)
		result += T.roundend_report()
		for(var/datum/antagonist/X in all_antagonists)
			if(X.get_team() == T)
				all_antagonists -= X
		result += " "//newline between teams
		CHECK_TICK

	var/currrent_category
	var/datum/antagonist/previous_category

	sortTim(all_antagonists, GLOBAL_PROC_REF(cmp_antag_category))

	for(var/datum/antagonist/A in all_antagonists)
		if(!A.show_in_roundend)
			continue
		if(A.roundend_category != currrent_category)
			if(previous_category)
				result += previous_category.roundend_report_footer()
				result += "</div>"
			result += "<div class='panel redborder'>"
			result += A.roundend_report_header()
			currrent_category = A.roundend_category
			previous_category = A
		result += A.roundend_report()
		result += "<br><br>"
		CHECK_TICK

	if(all_antagonists.len)
		var/datum/antagonist/last = all_antagonists[all_antagonists.len]
		result += last.roundend_report_footer()
		result += "</div>"

	return result.Join()

/proc/cmp_antag_category(datum/antagonist/A,datum/antagonist/B)
	return sorttext(B.roundend_category,A.roundend_category)


/datum/controller/subsystem/ticker/proc/give_show_report_button(client/C)
	var/datum/action/report/R = new
	C.player_details.player_actions += R
	R.Grant(C.mob)
	to_chat(C,"<a href='?src=[REF(R)];report=1'>Показать результаты раунда снова.</a>")

/datum/action/report
	name = "Показать результаты раунда"
	button_icon_state = "round_end"

/datum/action/report/Trigger(trigger_flags)
	if(owner && GLOB.common_report && SSticker.current_state == GAME_STATE_FINISHED)
		SSticker.show_roundend_report(owner.client)

/datum/action/report/IsAvailable()
	return TRUE

/datum/action/report/Topic(href,href_list)
	if(usr != owner)
		return
	if(href_list["report"])
		Trigger()
		return


/proc/printplayer(datum/mind/ply, fleecheck)
	var/jobtext = ""
	if(ply.assigned_role)
		jobtext = " the <b>[ply.assigned_role]</b>"
	var/text
	if(ply.hide_ckey)
		text = (
			"<b>[ply.name]</b>[jobtext] and"
			)
	else
		text = (
			"<b>[ply.key]</b> was <b>[ply.name]</b>[jobtext] and"
			)
	if(ply.current)
		if(ply.current.stat == DEAD)
			text += " <span class='redtext'>погиб</span>"
		else
			text += " <span class='greentext'>выжил</span>"
		if(fleecheck)
			var/turf/T = get_turf(ply.current)
			if(!T || !is_station_level(T.z))
				text += " <span class='redtext'>улетев со станции!</span>"
		if(ply.current.real_name != ply.name)
			text += " также известный как <b>[ply.current.real_name]</b>"
	else
		text += "<span class='redtext'>был уничтожен!</span>"
	return text

/proc/printplayerlist(list/players,fleecheck)
	var/list/parts = list()

	parts += "<ul class='playerlist'>"
	for(var/datum/mind/M in players)
		parts += "<li>[printplayer(M,fleecheck)]</li>"
	parts += "</ul>"
	return parts.Join()


/proc/printobjectives(list/objectives)
	if(!objectives || !objectives.len)
		return
	var/list/objective_parts = list()
	var/count = 1
	for(var/datum/objective/objective in objectives)
		if(objective.check_completion())
			objective_parts += "<b>Цель #[count]</b>: [objective.explanation_text] <span class='greentext'>Успех!</span>"
		else
			objective_parts += "<b>Цель #[count]</b>: [objective.explanation_text] <span class='redtext'>Провал.</span>"
		count++
	return objective_parts.Join("<br>")

/datum/controller/subsystem/ticker/proc/save_admin_data()
	if(IsAdminAdvancedProcCall())
		to_chat(usr, "<span class='admin prefix'>Admin rank DB Sync blocked: Advanced ProcCall detected.</span>")
		return
	if(CONFIG_GET(flag/admin_legacy_system)) //we're already using legacy system so there's nothing to save
		return
	else if(load_admins(TRUE)) //returns true if there was a database failure and the backup was loaded from
		return
	sync_ranks_with_db()
	var/list/sql_admins = list()
	for(var/i in GLOB.protected_admins)
		var/datum/admins/A = GLOB.protected_admins[i]
		sql_admins += list(list("ckey" = A.target, "rank" = A.rank.name))
	SSdbcore.MassInsert(format_table_name("admin"), sql_admins, duplicate_key = TRUE)
	var/datum/db_query/query_admin_rank_update = SSdbcore.NewQuery("UPDATE [format_table_name("player")] p INNER JOIN [format_table_name("admin")] a ON p.ckey = a.ckey SET p.lastadminrank = a.rank")
	query_admin_rank_update.Execute()
	qdel(query_admin_rank_update)

	//json format backup file generation stored per server
	var/json_file = file("data/admins_backup.json")
	var/list/file_data = list("ranks" = list(), "admins" = list())
	for(var/datum/admin_rank/R in GLOB.admin_ranks)
		file_data["ranks"]["[R.name]"] = list()
		file_data["ranks"]["[R.name]"]["include rights"] = R.include_rights
		file_data["ranks"]["[R.name]"]["exclude rights"] = R.exclude_rights
		file_data["ranks"]["[R.name]"]["can edit rights"] = R.can_edit_rights
	for(var/i in GLOB.admin_datums+GLOB.deadmins)
		var/datum/admins/A = GLOB.admin_datums[i]
		if(!A)
			A = GLOB.deadmins[i]
			if (!A)
				continue
		file_data["admins"]["[i]"] = A.rank.name
	fdel(json_file)
	WRITE_FILE(json_file, json_encode(file_data))

/datum/controller/subsystem/ticker/proc/update_everything_flag_in_db()
	for(var/datum/admin_rank/R in GLOB.admin_ranks)
		var/list/flags = list()
		if(R.include_rights == R_EVERYTHING)
			flags += "flags"
		if(R.exclude_rights == R_EVERYTHING)
			flags += "exclude_flags"
		if(R.can_edit_rights == R_EVERYTHING)
			flags += "can_edit_flags"
		if(!flags.len)
			continue
		var/flags_to_check = flags.Join(" != [R_EVERYTHING] AND ") + " != [R_EVERYTHING]"
		var/datum/db_query/query_check_everything_ranks = SSdbcore.NewQuery(
			"SELECT flags, exclude_flags, can_edit_flags FROM [format_table_name("admin_ranks")] WHERE rank = :rank AND ([flags_to_check])",
			list("rank" = R.name)
		)
		if(!query_check_everything_ranks.Execute())
			qdel(query_check_everything_ranks)
			return
		if(query_check_everything_ranks.NextRow()) //no row is returned if the rank already has the correct flag value
			var/flags_to_update = flags.Join(" = [R_EVERYTHING], ") + " = [R_EVERYTHING]"
			var/datum/db_query/query_update_everything_ranks = SSdbcore.NewQuery(
				"UPDATE [format_table_name("admin_ranks")] SET [flags_to_update] WHERE rank = :rank",
				list("rank" = R.name)
			)
			if(!query_update_everything_ranks.Execute())
				qdel(query_update_everything_ranks)
				return
			qdel(query_update_everything_ranks)
		qdel(query_check_everything_ranks)
