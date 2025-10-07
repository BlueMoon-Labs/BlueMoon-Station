#define VOTE_COOLDOWN 10

SUBSYSTEM_DEF(vote)
	name = "Vote"
	wait = 10

	flags = SS_KEEP_TIMING|SS_NO_INIT

	runlevels = RUNLEVEL_LOBBY | RUNLEVELS_DEFAULT

	var/initiator = null
	var/started_time = null
	var/end_time = 0
	var/mode = null
	var/vote_system = PLURALITY_VOTING
	var/question = null
	var/list/choices = list()
	/// List of choice = object for statclick objects for statpanel voting
	/// statclick rework? 2: list("name"="id")
	var/list/choice_statclicks = list()
	var/list/scores = list()
	var/list/choice_descs = list() // optional descriptions
	var/list/voted = list()
	var/list/voting = list()
	var/list/saved = list()
	var/list/generated_actions = list()
	var/next_pop = 0

	var/display_votes = SHOW_RESULTS|SHOW_VOTES|SHOW_WINNER|SHOW_ABSTENTION //CIT CHANGE - adds obfuscated/admin-only votes

	var/list/stored_gamemode_votes = list() //Basically the last voted gamemode is stored here for end-of-round use.

	var/list/stored_modetier_results = list() // The aggregated tier list of the modes available in secret.

	// BLUEMOON ADD START - перевод режимов
	var/static/list/ru_votemodes = list(
	"restart" = "за рестарт сервера",
	"map" = "за выбор карты",
	"gamemode" = "за выбор режима игры",
	"transfer" = "за окончание раунда",
	"roundtype" = "за выбор режима игры",
	"custom" = "" // за упокой
	)
	// BLUEMOON ADD END

/datum/controller/subsystem/vote/fire()	//called by master_controller
	if(mode)
//BLUEMOON ADD START
		if(mode == "roundtype" && SSticker.timeLeft - ROUNDTYPE_VOTE_END_PENALTY <= 0)
			result()
			for(var/client/C in voting)
				C << browse(null, "window=vote;can_close=0")
			reset()
//BLUEMOON ADD END
		else if(end_time < world.time) //BLUEMOON CHANGES
			result()
			SSpersistence.SaveSavedVotes()
			for(var/client/C in voting)
				C << browse(null, "window=vote;can_close=0")
			if(end_time < world.time) // result() can change this
				reset()
		else if(next_pop < world.time)
			var/datum/browser/client_popup
			for(var/client/C in voting)
				client_popup = new(C, "vote", "Voting Panel", nwidth=600,nheight=700)
				client_popup.set_window_options("can_close=0")
				client_popup.set_content(interface(C))
				client_popup.open(0)
			next_pop = world.time+VOTE_COOLDOWN

/datum/controller/subsystem/vote/proc/reset()
	initiator = null
	end_time = 0
	mode = null
	question = null
	choices.Cut()
	choice_descs.Cut()
	voted.Cut()
	voting.Cut()
	scores.Cut()
	choice_statclicks = list()
	display_votes = initial(display_votes) //CIT CHANGE - obfuscated votes
	remove_action_buttons()

/datum/controller/subsystem/vote/proc/get_result()
	//get the highest number of votes
	var/greatest_votes = 0
	var/total_votes = 0
//BLUEMOON ADD START - голоса за некоторые режимы (динамик и тимбаза, лёгкий динамик и экста) должны считаться вместе.
	var/dynamic_votes = 0
	var/extended_votes = 0
//BLUEMOON ADD END
	if((mode == "gamemode" || mode == "roundtype") && CONFIG_GET(flag/must_be_readied_to_vote_gamemode))
		for(var/mob/dead/new_player/P in GLOB.player_list)
			if(P.ready != PLAYER_READY_TO_PLAY && voted[P.ckey])
				choices[choices[voted[P.ckey]]]--
	for(var/option in choices)
		var/votes = choices[option]
		total_votes += votes
//BLUEMOON ADD START - голоса за некоторые режимы (динамик и тимбаза, лёгкий динамик и экста) должны считаться вместе.
		if(option == ROUNDTYPE_EXTENDED || option == ROUNDTYPE_DYNAMIC_LIGHT)
			extended_votes += votes
		if(option == ROUNDTYPE_DYNAMIC_TEAMBASED || option == ROUNDTYPE_DYNAMIC)
			dynamic_votes += votes
//BLUEMOON ADD END
		if(votes > greatest_votes)
			greatest_votes = votes
//BLUEMOON ADD START - пропуск эксты, если у неё голосов меньше, чем у остальных вариантов (чтобы голоса динамиков считались вместе)
//Повторный ролл вариантов нужен, чтобы голоса за вариации динамика и эксты успели сформироваться
	if(mode == "roundtype" || mode == "dynamic")
		var/second_round_votes = 0 //голоса между вариациями
		for(var/option in choices)
			var/votes = choices[option]
			if(extended_votes <= dynamic_votes)
				if(option == ROUNDTYPE_EXTENDED || option ==  ROUNDTYPE_DYNAMIC_LIGHT) //экста и лёгкий динамик всегда должны быть в конце списка, чтобы это работало
					continue
				if(votes > second_round_votes)
					greatest_votes = votes
				second_round_votes += votes
			else
				if(option == ROUNDTYPE_DYNAMIC || option == ROUNDTYPE_DYNAMIC_TEAMBASED) //экста и лёгкий динамик всегда должны быть в конце списка, чтобы это работало
					continue
				if(votes > second_round_votes)
					greatest_votes = votes
				second_round_votes += votes
//BLUEMOON ADD END
	//default-vote for everyone who didn't vote
	if(!CONFIG_GET(flag/default_no_vote) && choices.len)
		var/list/non_voters = GLOB.directory.Copy()
		non_voters -= voted
		for (var/non_voter_ckey in non_voters)
			var/client/C = non_voters[non_voter_ckey]
			if (!C || C.is_afk())
				non_voters -= non_voter_ckey
		if(non_voters.len > 0)
			if(mode == "restart")
				choices["Continue Playing"] += non_voters.len
				if(choices["Continue Playing"] >= greatest_votes)
					greatest_votes = choices["Continue Playing"]
			else if(mode == "gamemode")
				if(GLOB.master_mode in choices)
					choices[GLOB.master_mode] += non_voters.len
					if(choices[GLOB.master_mode] >= greatest_votes)
						greatest_votes = choices[GLOB.master_mode]
	//get all options with that many votes and return them in a list
	. = list()
	if(greatest_votes)
		for(var/option in choices)
//BLUEMOON ADD START - костыль, чтобы вариации эксты не была победителем, если у неё голосов больше, чем у одного из других вариантов
//экста и лёгкий динамик всегда должны быть в конце списка, чтобы это работало
			if(mode == "roundtype" || mode == "dynamic")
				if(extended_votes <= dynamic_votes)
					if(option == ROUNDTYPE_EXTENDED || option ==  ROUNDTYPE_DYNAMIC_LIGHT) //экста и лёгкий динамик всегда должны быть в конце списка, чтобы это работало
						continue
				else
					if(option == ROUNDTYPE_DYNAMIC || option ==  ROUNDTYPE_DYNAMIC_TEAMBASED) //экста и лёгкий динамик всегда должны быть в конце списка, чтобы это работало
						continue
//BLUEMOON ADD END
			if(choices[option] == greatest_votes)
				. += option
	return .

/datum/controller/subsystem/vote/proc/calculate_condorcet_votes(var/blackbox_text)
	if((mode == "gamemode" || mode == "dynamic" || mode == "roundtype") && CONFIG_GET(flag/must_be_readied_to_vote_gamemode))
		for(var/mob/dead/new_player/P in GLOB.player_list)
			if(P.ready != PLAYER_READY_TO_PLAY && voted[P.ckey])
				voted -= P.ckey
	var/list/d[][] = new/list(choices.len,choices.len) // the basic vote matrix, how many times a beats b
	for(var/ckey in voted)
		var/list/this_vote = voted[ckey]
		if(islist(this_vote))
			for(var/a in 1 to choices.len)
				for(var/b in a+1 to choices.len)
					var/a_rank = this_vote.Find(a)
					var/b_rank = this_vote.Find(b)
					a_rank = a_rank ? a_rank : choices.len+1
					b_rank = b_rank ? b_rank : choices.len+1
					if(a_rank<b_rank)
						d[a][b]++
					else if(b_rank<a_rank)
						d[b][a]++
					//if equal, do nothing
	var/list/p[][] = new/list(choices.len,choices.len) //matrix of shortest path from a to b
	for(var/i in 1 to choices.len)
		for(var/j in 1 to choices.len)
			if(i != j)
				var/pref_number = d[i][j]
				var/opposite_pref = d[j][i]
				if(pref_number>opposite_pref)
					p[i][j] = d[i][j]
				else
					p[i][j] = 0
	for(var/i in 1 to choices.len)
		for(var/j in 1 to choices.len)
			if(i != j)
				for(var/k in 1 to choices.len) // YEAH O(n^3) !!
					if(i != k && j != k)
						p[j][k] = max(p[j][k],min(p[j][i], p[i][k]))
	//one last pass, now that we've done the math
	for(var/i in 1 to choices.len)
		for(var/j in 1 to choices.len)
			if(i != j)
				SSblackbox.record_feedback("nested tally","voting",p[i][j],list(blackbox_text,"Shortest Paths",choices[i],choices[j]))
				if(p[i][j] >= p[j][i])
					choices[choices[i]]++ // higher shortest path = better candidate, so we add to choices here
					// choices[choices[i]] is the schulze ranking, here, rather than raw vote numbers

/datum/controller/subsystem/vote/proc/calculate_highest_median(var/blackbox_text)
	// https://en.wikipedia.org/wiki/Highest_median_voting_rules
	var/list/scores_by_choice = list()
	for(var/choice in choices)
		scores_by_choice += "[choice]"
		scores_by_choice["[choice]"] = list()
	if((mode == "gamemode" || mode == "dynamic" || mode == "roundtype") && CONFIG_GET(flag/must_be_readied_to_vote_gamemode))
		for(var/mob/dead/new_player/P in GLOB.player_list)
			if(P.ready != PLAYER_READY_TO_PLAY && voted[P.ckey])
				voted -= P.ckey
	for(var/ckey in voted)
		var/list/this_vote = voted[ckey]
		var/list/pretty_vote = list()
		for(var/choice in choices)
			if(("[choice]" in this_vote) && ("[choice]" in scores_by_choice))
				sorted_insert(scores_by_choice["[choice]"],this_vote["[choice]"],GLOBAL_PROC_REF(cmp_numeric_asc))
				// START BALLOT GATHERING
				pretty_vote += "[choice]"
				if(this_vote["[choice]"] in GLOB.vote_score_options)
					pretty_vote["[choice]"] = GLOB.vote_score_options[this_vote["[choice]"]]
		SSblackbox.record_feedback("associative","voting_ballots",1,pretty_vote)
		// END BALLOT GATHERING
	for(var/score_name in scores_by_choice)
		var/list/score = scores_by_choice[score_name]
		if(!score.len)
			choices[score_name] = 0
		else
			var/median = score[max(1,round(score.len/2))]
			var/p = 0 // proponents (those with higher than median)
			var/q = 0 // opponents (lower than median)
			var/list/this_score_list = scores_by_choice[score_name]
			for(var/indiv_score in score)
				SSblackbox.record_feedback("nested tally","voting",1,list(blackbox_text,"Scores",score_name,GLOB.vote_score_options[indiv_score]))
				if(indiv_score < median) // this is possible to do in O(logn) but n is never more than 200 so this is fine
					q += 1
				else if(indiv_score > median)
					p += 1
			p /= this_score_list.len
			q /= this_score_list.len
			choices[score_name] = median + (((p - q) / (1 - p - q)) * 0.5) // usual judgement
			// choices[score_name] = median + p - q // typical judgement
			// choices[score_name] = median + (((p - q) / (p + q)) * 0.5) // central judgement

/datum/controller/subsystem/vote/proc/calculate_scores(var/blackbox_text)
	for(var/choice in choices)
		scores += "[choice]"
		scores["[choice]"] = 0
	for(var/ckey in voted)
		var/list/this_vote = voted[ckey]
		for(var/choice in this_vote)
			scores["[choice]"] += this_vote["[choice]"]
	var/min_score = 100
	var/max_score = -100
	for(var/score_name in scores) // normalize the scores from 0-1
		max_score=max(max_score,scores[score_name])
		min_score=min(min_score,scores[score_name])
	for(var/score_name in scores)
		if(max_score == min_score)
			scores[score_name] = 1
		else
			scores[score_name] = (scores[score_name]-min_score)/(max_score-min_score)
		SSblackbox.record_feedback("nested tally","voting",scores[score_name],list(blackbox_text,"Total scores",score_name))

/datum/controller/subsystem/vote/proc/get_runoff_results(var/blackbox_text)
	var/already_lost_runoff = list()
	var/list/cur_choices = choices.Copy()
	for(var/ckey in voted)
		choices["[choices[voted[ckey][1]]]"]++ // jesus christ how horrifying
	for(var/_this_var_unused_ignore_it in 1 to choices.len) // if it takes more than this something REALLY wrong happened
		for(var/ckey in voted)
			cur_choices["[cur_choices[voted[ckey][1]]]]"]++ // jesus christ how horrifying
		var/least_vote = 100000
		var/least_voted = 1
		for(var/i in 1 to cur_choices.len)
			var/option = cur_choices[i]
			if(cur_choices["[option]"] > voted.len/2)
				return list("[option]")
			else if(cur_choices["[option]"] < least_vote && !("[option]" in already_lost_runoff))
				least_vote = cur_choices["[option]"]
				least_voted = i
		already_lost_runoff += cur_choices[least_voted]
		for(var/ckey in voted)
			voted[ckey] -= least_voted
		for(var/i in 1 to cur_choices.len)
			cur_choices["[cur_choices[i]]"] = 0

/datum/controller/subsystem/vote/proc/announce_result()
	var/vote_title_text
	var/text
	if(question)
		vote_title_text = "[question]"
	else
		vote_title_text = "[capitalize(mode)] Vote"
	if(vote_system == SCHULZE_VOTING)
		calculate_condorcet_votes(vote_title_text)
	if(vote_system == SCORE_VOTING)
		calculate_scores(vote_title_text)
	if(vote_system == HIGHEST_MEDIAN_VOTING)
		calculate_highest_median(vote_title_text) // nothing uses this at the moment
	var/list/winners = vote_system == INSTANT_RUNOFF_VOTING ? get_runoff_results() : get_result()
	var/was_roundtype_vote = mode == "roundtype" || mode == "dynamic"
	text += "Результаты [mode == "custom" ? "кастомного " : ""]голосования[mode != "custom" ? " [ru_votemodes[mode]]" : ""]: \n" // BLUEMOON EDIT
	if(question)
		text += "\n<b>[question]</b>\n"
	if(winners.len > 0)
		if(was_roundtype_vote)
			stored_gamemode_votes = list()
		if(display_votes & SHOW_RESULTS)
			if(vote_system == SCHULZE_VOTING)
				text += "\nIt should be noted that this is not a raw tally of votes (impossible in ranked choice) but the score determined by the schulze method of voting, so the numbers will look weird!"
			if(vote_system == HIGHEST_MEDIAN_VOTING)
				text += "\nThis is the highest median score plus the tiebreaker!"
		// BLUEMOON EDIT START - отрисовка результатов голосования
		var/total_votes = 0
		var/votes_left = "<div class='left-column'>"
		var/votes_right = "<div class='right-column' id='results-container'>"
		for(var/i = 1, i <= choices.len, i++)
			var/votes_amount = choices[choices[i]]
			if(!votes_amount)
				votes_amount = 0
			if(was_roundtype_vote)
				stored_gamemode_votes[choices[i]] = votes_amount
			total_votes += votes_amount
			votes_left += "<div class='vote_variant'>[choices[i]]: <b>[display_votes & SHOW_RESULTS ? votes_amount : "???"]</b></div>"
		for(var/i = 1, i <= choices.len, i++)
			if (display_votes & SHOW_RESULTS)
				if (length(choices) == 1)
					votes_right += "<div class='votewrap'><div class='voteresult' style='width: calc(100% + 2px);'><span>1984%</span></div></div>";
				else
					var/votes_amount = choices[choices[i]]
					var/percent = total_votes > 0 ? round((votes_amount / total_votes) * 100, 1) : 0
					if (percent > 0)
						votes_right += "<div class='votewrap'><div class='voteresult' style='width: calc([percent]% + 2px);'><span>[percent]%</span></div></div>"
					else
						votes_right += "<div class='votewrap'><div class='voteresult' style='background-color: rgba(0, 0, 0, 0);'><span>[percent]%</span></div></div>";
		votes_left += "</div>"
		votes_right += "</div>"
		text += "<div class='voteresults'>[votes_left][votes_right]</div>"
		// BLUEMOON EDIT END
		if(mode != "custom")
			if(winners.len > 1 && display_votes & SHOW_WINNER) //CIT CHANGE - adds obfuscated votes
				text = "\n<b>ничья между...</b>"
				for(var/option in winners)
					text += "\n\t[option]"
			. = pick(winners)
			text += "Победитель голосования: <b>[display_votes & SHOW_WINNER ? . : "???"]</b>\n" //CIT CHANGE - adds obfuscated votes
		if(display_votes & SHOW_ABSTENTION)
			text += "\nВоздержались: <b>[GLOB.clients.len-voted.len]</b>"
	else if(vote_system == SCORE_VOTING)
		for(var/score_name in scores)
			var/score = scores[score_name]
			if(!score)
				score = 0
			if(was_roundtype_vote)
				stored_gamemode_votes[score_name] = score
			text = "\n<b>[score_name]:</b> [display_votes & SHOW_RESULTS ? score : "???"]"
			. = 1
	else
		text += "<b>\nГолосование не удалось – голосов не было!</b>"
	log_vote(text)
	remove_action_buttons()
	SEND_SOUND(world, sound('sound/misc/notice2.ogg'))
	to_chat(world, vote_block(text))
	switch(vote_system)
		if(APPROVAL_VOTING,PLURALITY_VOTING)
			for(var/i=1,i<=choices.len,i++)
				SSblackbox.record_feedback("nested tally","voting",choices[choices[i]],list(vote_title_text,choices[i]))
		if(SCHULZE_VOTING,INSTANT_RUNOFF_VOTING)
			for(var/i=1,i<=voted.len,i++)
				var/list/myvote = voted[voted[i]]
				if(islist(myvote))
					for(var/j=1,j<=myvote.len,j++)
						SSblackbox.record_feedback("nested tally","voting",1,list(vote_title_text,"[j]\th",choices[myvote[j]]))
	if(!(display_votes & SHOW_RESULTS)) //CIT CHANGE - adds obfuscated votes. this messages admins with the vote's true results
		var/admintext = "Obfuscated results"
		if(vote_system != SCORE_VOTING)
			if(vote_system == SCHULZE_VOTING)
				admintext += "\nIt should be noted that this is not a raw tally of votes (impossible in ranked choice) but the score determined by the schulze method of voting, so the numbers will look weird!"
			else if(vote_system == HIGHEST_MEDIAN_VOTING)
				admintext += "\nIt should be noted that this is not a raw tally of votes but the number of runoffs done by majority judgement!"
			for(var/i=1,i<=choices.len,i++)
				var/votes = choices[choices[i]]
				admintext += "\n<b>[choices[i]]:</b> [votes ? votes : "0"]" //This is raw data, but the raw data is null by default. If ya don't compensate for it, then it'll look weird!
		else
			for(var/i=1,i<=scores.len,i++)
				var/score = scores[scores[i]]
				admintext += "\n<b>[scores[i]]:</b> [score ? score : "0"]"
		message_admins(admintext)
	return .

/datum/controller/subsystem/vote/proc/result()
	. = announce_result()
	var/restart = 0
	if(.)
		switch(mode)
			if("roundtype")
				if(SSticker.current_state > GAME_STATE_PREGAME)
					return message_admins("A vote has tried to change the gamemode, but the game has already started. Aborting.")
				if(. != ROUNDTYPE_EXTENDED)
					// Если прошлой вариацией была тимбаза или хард, то они не могут выпасть повторно
					// var/last_dynamic_type = SSpersistence.last_dynamic_gamemode
					// if(SSpersistence.last_dynamic_gamemode in list(ROUNDTYPE_DYNAMIC_TEAMBASED, ROUNDTYPE_DYNAMIC_HARD))
					// 	last_dynamic_type = list(ROUNDTYPE_DYNAMIC_TEAMBASED, ROUNDTYPE_DYNAMIC_HARD)

					. = pick_dynamic_type_by_chaos(GLOB.player_list)
					SSpersistence.RecordDynamicType(.)
					GLOB.round_type = .
					GLOB.master_mode = .
				else
					SSpersistence.RecordDynamicType(.)
					GLOB.round_type = .
					GLOB.master_mode = .

			if("restart")
				if(. == "Restart Round")
					restart = 1

			if("map")
				// BLUEMOON ADD START - перезагрузка сервера с ротацией карты в случае краша прошлого раунда
				if(. == "Не менять карту") // Вариант доступен только если воут выскочил в результате краша
					message_admins("Смена карты была отменена игроками.")
					log_admin("Смена карты была отменена игроками.")
					if(SSticker.mapvote_restarter_in_progress)
						to_chat(world, "<span class='boldannounce'>Смена карты была отменена игроками.</span>")
						SSticker.mapvote_restarter_in_progress = FALSE
						SSpersistence.RecordGracefulEnding()
						SSticker.start_immediately = FALSE
						SSticker.SetTimeLeft(2400)
					return .

				var/datum/map_config/VM = config.maplist[.]
				message_admins("The map has been voted for and will change to: [VM.map_name]")
				log_admin("The map has been voted for and will change to: [VM.map_name]")
				if(SSmapping.changemap(config.maplist[.]))
					to_chat(world, "<span class='boldannounce'>The map vote has chosen [VM.map_name] for next round!</span>")
				if(SSticker.mapvote_restarter_in_progress)
					SSticker.Reboot("Map rotation was requested due to ungraceful ending of the last round.", null, 10)
				// BLUEMOON ADD END
			if("transfer") // austation begin -- Crew autotransfer vote
				if(. == VOTE_TRANSFER)
					SSshuttle.autoEnd()
					var/obj/machinery/computer/communications/C = locate() in GLOB.machines
					if(C)
						C.post_status("shuttle") // austation end
	// BLUEMOON ADD START - воут на карту провалился из-за отсутствия голосов
	else if (mode == "map")
		message_admins("Голосование за карту провалилось из-за отсутствия голосов.")
		log_admin("Голосование за карту провалилось из-за отсутствия голосов.")
		if(SSticker.mapvote_restarter_in_progress)
			to_chat(world, "<span class='boldannounce'>Перезагрузка отменена в связи с отсутствием голосов. Очередное поражение демократии...</span>")
			SSticker.mapvote_restarter_in_progress = FALSE
			SSpersistence.RecordGracefulEnding()
			SSticker.start_immediately = FALSE
			SSticker.SetTimeLeft(2400)
	// BLUEMOON ADD END
	if(restart)
		var/active_admins = 0
		for(var/client/C in GLOB.admins)
			if(!C.is_afk() && check_rights_for(C, R_SERVER))
				active_admins = 1
				break
		if(!active_admins)
			SSticker.Reboot("Restart vote successful.", "restart vote")
		else
			to_chat(world, "<span style='boldannounce'>Notice:Restart vote will not restart the server automatically because there are active admins on.</span>")
			message_admins("A restart vote has passed, but there are active admins on with +server, so it has been canceled. If you wish, you may restart the server.")

	return .

/datum/controller/subsystem/vote/proc/submit_vote(vote, score = 0)
	if(mode)
		if(CONFIG_GET(flag/no_dead_vote) && usr.stat == DEAD && !usr.client.holder)
			return FALSE
		if(use_vote_power)
			if(!users_vote_power[usr.ckey])
				users_vote_power[usr.ckey] = get_vote_power_by_role(usr.client)
			vote_power = users_vote_power[usr.ckey]
		if(vote && ISINRANGE(vote, 1, choices.len))
			switch(vote_system)
				if(PLURALITY_VOTING)
					if(usr.ckey in voted)
						choices[choices[voted[usr.ckey]]] -= vote_power
						voted[usr.ckey] = vote
						choices[choices[vote]] += vote_power
						return vote
					else
						voted += usr.ckey
						voted[usr.ckey] = vote
						choices[choices[vote]] += vote_power	//check this
						return vote
				if(APPROVAL_VOTING)
					if(usr.ckey in voted)
						if(vote in voted[usr.ckey])
							voted[usr.ckey] -= vote
							choices[choices[vote]] -= vote_power
						else
							voted[usr.ckey] += vote
							choices[choices[vote]] += vote_power
					else
						voted += usr.ckey
						voted[usr.ckey] = list(vote)
						choices[choices[vote]] += vote_power
						return vote
				if(SCHULZE_VOTING,INSTANT_RUNOFF_VOTING)
					if(usr.ckey in voted)
						if(vote in voted[usr.ckey])
							voted[usr.ckey] -= vote
					else
						voted += usr.ckey
						voted[usr.ckey] = list()
					voted[usr.ckey] += vote
					saved -= usr.ckey
				if(SCORE_VOTING,HIGHEST_MEDIAN_VOTING)
					if(!(usr.ckey in voted))
						voted += usr.ckey
						voted[usr.ckey] = list()
					voted[usr.ckey][choices[vote]] = score
					saved -= usr.ckey
	return FALSE

/datum/controller/subsystem/vote/proc/initiate_vote(vote_type, initiator_key, display = display_votes, votesystem = PLURALITY_VOTING, forced = FALSE,vote_time = -1)//CIT CHANGE - adds display argument to votes to allow for obfuscated votes
	vote_system = votesystem
	if(!mode)
		if(started_time)
			var/next_allowed_time = (started_time + CONFIG_GET(number/vote_delay))
			if(mode)
				to_chat(usr, "<span class='warning'>There is already a vote in progress! please wait for it to finish.</span>")
				return FALSE

			var/admin = FALSE
			var/ckey = ckey(initiator_key)
			if(GLOB.admin_datums[ckey] || initiator_key == "server")
				admin = TRUE

			if(next_allowed_time > world.time && !admin)
				to_chat(usr, "<span class='warning'>A vote was initiated recently, you must wait [DisplayTimeText(next_allowed_time-world.time)] before a new vote can be started!</span>")
				return FALSE

		SEND_SOUND(world, sound('sound/misc/notice2.ogg'))
		reset()
//		display_votes = display //CIT CHANGE - adds obfuscated votes
		switch(vote_type)
			if("restart")
				choices.Add("Restart Round","Continue Playing")
			if("gamemode")
				choices.Add(config.votable_modes)
			if("map")
				var/players = GLOB.clients.len
				var/list/lastmaps = SSpersistence.saved_maps?.len ? list("[SSmapping.config.map_name]") | SSpersistence.saved_maps : list("[SSmapping.config.map_name]")
				if(SSticker.mapvote_restarter_in_progress)
					choices |= "Не менять карту"
				for(var/M in config.maplist) //This is a typeless loop due to the finnicky nature of keyed lists in this kind of context
					var/datum/map_config/targetmap = config.maplist[M]
					if(!istype(targetmap))
						continue
					/* SPLURT change */
					if(CONFIG_GET(flag/no_repeats) && targetmap.map_name == SSmapping.config.map_name)	// Second now because I did a stupid with types
						continue
					/* END SPLURT change */
					if(!targetmap.voteweight)
						continue
					if((targetmap.config_min_users && players < targetmap.config_min_users) || (targetmap.config_max_users && players > targetmap.config_max_users))
						continue
					if(targetmap.max_round_search_span && count_occurences_of_value(lastmaps, M, targetmap.max_round_search_span) >= targetmap.max_rounds_played)
						continue
					choices |= M
				shuffle_inplace(choices)
			if("transfer") // austation begin -- Crew autotranfer vote
				choices.Add(VOTE_TRANSFER,VOTE_CONTINUE) // austation end
			if("roundtype")
				var/combo = check_combo()
				switch (combo)
					if ("dynamic")
						choices.Add(ROUNDTYPE_EXTENDED)
					if ("Extended")
						choices.Add(ROUNDTYPE_DYNAMIC)
					else
						choices.Add(ROUNDTYPE_DYNAMIC, ROUNDTYPE_EXTENDED)
			if("custom")
				question = stripped_input(usr,"What is the vote for?")
				if(!question)
					return FALSE
				var/system_string = input(usr,"Which voting type?",GLOB.vote_type_names[1]) in GLOB.vote_type_names
				vote_system = GLOB.vote_type_names[system_string]
				for(var/i=1,i<=10,i++)
					var/option = capitalize(stripped_input(usr,"Please enter an option or hit cancel to finish"))
					if(!option || mode || !usr.client)
						break
					choices.Add(option)
				var/keep_going = TRUE
				var/toggles = SHOW_RESULTS|SHOW_VOTES|SHOW_WINNER|SHOW_ABSTENTION
				while(keep_going)
					var/list/choices = list()
					for(var/A in GLOB.display_vote_settings)
						var/toggletext
						var/bitflag = GLOB.display_vote_settings[A]
						toggletext = "[A] [toggles & bitflag ? "- Shown" : "- Hidden"]"
						choices[toggletext] = bitflag
					var/chosen = input(usr, "Toggle vote display settings. Cancel to finalize.", toggles) as null|anything in choices
					if(!chosen)
						keep_going = FALSE
					else
						toggles ^= choices[chosen]
				display_votes = toggles
			else
				return FALSE
		mode = vote_type
		initiator = initiator_key ? initiator_key : "the Server" // austation -- Crew autotransfer vote
		started_time = world.time
		// BLUEMOON EDIT START - реструктурирование
		var/text = ""

		text += capitalize("[mode == "custom" ? "кастомное " : ""]голосование [mode != "custom" ? "[ru_votemodes[mode]] " : ""]начато [initiator == "server" ? "автоматически" : initiator].\n")
		if(mode == "custom")
			text += "\n<b>[question]</b>\n"
		log_vote(text)
		var/vp = vote_time
		if(vp == -1)
			vp = CONFIG_GET(number/vote_period)
		text += "\nНажмите <b>'Vote'</b> во вкладке OOC или нажмите <a href='?src=[REF(src)]'>сюда</a> чтобы проголосовать."
		text += "\nДо окончания голосования – [DisplayTimeText(vp)]."
		to_chat(world, vote_block(text))
		// BLUEMOON EDIT END
		end_time = started_time+vp
		// generate statclick list
		choice_statclicks = list()
		for(var/i in 1 to choices.len)
			var/choice = choices[i]
			choice_statclicks[choice] = "[i]"
		//
		for(var/c in GLOB.clients)
			SEND_SOUND(c, sound('sound/misc/votestart.ogg'))
			var/client/C = c
			var/datum/action/vote/V = new
			if(question)
				V.name = "Vote: [question]"
			C.player_details.player_actions += V
			V.Grant(C.mob)
			generated_actions += V
			if(forced)
				var/datum/browser/popup = new(C, "vote", "Voting Panel",nwidth=600,nheight=700)
				popup.set_window_options("can_close=0")
				popup.set_content(SSvote.interface(C))
				popup.open(0)
		return TRUE
	return FALSE

/datum/controller/subsystem/vote/proc/check_combo()
	var/list/roundtypes = list()
	var/much_to_check = ROUNDTYPE_MAX_COMBO
	log_world("SSpersistence.saved_modes contents:")
	for (var/mode in SSpersistence.saved_modes)
		log_world("- [mode]: [SSpersistence.saved_modes[mode]]")

	for (var/mode in SSpersistence.saved_modes)
		if(!istext(mode))
			continue
		if(!much_to_check)
			break
		much_to_check--
		if(!(mode in roundtypes))
			roundtypes[mode] = 0
		roundtypes[mode]++
		if(roundtypes[mode] >= ROUNDTYPE_MAX_COMBO)
			return mode
	return FALSE

/datum/controller/subsystem/vote/proc/interface(client/C)
	if(!C)
		return
	var/admin = 0
	var/trialmin = 0
	if(C.holder)
		admin = 1
		if(check_rights_for(C, R_ADMIN))
			trialmin = 1
	voting |= C

	if(mode)
		if(question)
			. += "<h2>Голосование: '[question]'</h2>"
		else
			. += "<h2>Голосование: [capitalize(mode)]</h2>"
		switch(vote_system)
			if(PLURALITY_VOTING)
				. += "<h3>Выберите одно.</h3>"
			if(APPROVAL_VOTING)
				. += "<h3>Vote any number of choices.</h3>"
			if(SCHULZE_VOTING,INSTANT_RUNOFF_VOTING)
				. += "<h3>Vote by order of preference. Revoting will demote to the bottom. 1 is your favorite, and higher numbers are worse.</h3>"
			if(SCORE_VOTING,HIGHEST_MEDIAN_VOTING)
				. += "<h3>Grade the candidates by how much you like them.</h3>"
				. += "<h3>No-votes have no power--your opinion is only heard if you vote!</h3>"

		if(mode == "roundtype")
			// BLUEMOON ADD START
			. += "<br>Если побеждает [ROUNDTYPE_DYNAMIC], то берётся одна из вариаций динамика."  // df

			. += "<br><font size=1><small><b>[ROUNDTYPE_DYNAMIC_TEAMBASED]:</b></font></small>"
			. += "<br><font size=1><small>90-100 угрозы, только командные и особые одиночные антагонисты, необходим уровень хаоса больше [CONFIG_GET(number/chaos_for_a_hard_dynamic)] от игроков;</font></small>"

			. += "<br><font size=1><small><b>[ROUNDTYPE_DYNAMIC_HARD]:</b></font></small>"
			. += "<br><font size=1><small>90-100 угрозы, необходим уровень хаоса больше [CONFIG_GET(number/chaos_for_a_hard_dynamic)] от игроков;</font></small>"

			. += "<br><font size=1><small><b>[ROUNDTYPE_DYNAMIC_MEDIUM]:</b></font></small>"
			. += "<br><font size=1><small>50-100 угрозы, необходим уровень хаоса меньше [CONFIG_GET(number/chaos_for_a_hard_dynamic)] от игроков;</font></small>"

			. += "<br><font size=1><small><b>[ROUNDTYPE_DYNAMIC_LIGHT]:</b>:</font></small>"
			. += "<br><font size=1><small>30-70 угрозы, без командных антагонистов, необходимо меньше двадцати игроков;</font></small>"

			. += "<br><font size=1><small><b>[ROUNDTYPE_EXTENDED]</b> (угрозы не спавнятся сами, только администрация может создавать их).</font></small>"
			. += "<h4>Если Режим выпадает [ROUNDTYPE_MAX_COMBO] раза подряд - форсится обратный.</h4>"
			if (length(SSpersistence.saved_modes))
				. += "<br>Последние режимы: <b>[jointext(SSpersistence.saved_modes, ", ")]</b>."
			. += "<br>Осталось времени: [DisplayTimeText((SSticker.timeLeft - ROUNDTYPE_VOTE_END_PENALTY))]<hr><ul>"
		else
			. += "Осталось времени: [DisplayTimeText(end_time-world.time)]<hr><ul>"
		//BLUEMOON ADD END
		switch(vote_system)
			if(PLURALITY_VOTING, APPROVAL_VOTING)
				for(var/i=1,i<=choices.len,i++)
					var/votes = choices[choices[i]]
					var/ivotedforthis = FALSE
					switch(vote_system)
						if(PLURALITY_VOTING)
							ivotedforthis = ((C.ckey in voted) && (voted[C.ckey] == i))
						if(APPROVAL_VOTING)
							ivotedforthis = ((C.ckey in voted) && (i in voted[C.ckey]))
					if(!votes)
						votes = 0
					. += "<li>[ivotedforthis ? "<b>" : ""]<a href='?src=[REF(src)];vote=[i]'>[choices[i]]</a> ([display_votes & SHOW_VOTES ? votes : (admin ? "??? ([votes])" : "???")] votes)[ivotedforthis ? "</b>" : ""]</li>" // CIT CHANGE - adds obfuscated votes
					if(choice_descs.len >= i)
						. += "<li>[choice_descs[i]]</li>"
				. += "</ul><hr>"
			if(SCHULZE_VOTING,INSTANT_RUNOFF_VOTING)
				var/list/myvote = voted[C.ckey]
				for(var/i=1,i<=choices.len,i++)
					var/vote = (islist(myvote) ? (myvote.Find(i)) : 0)
					if(vote)
						. += "<li><b><a href='?src=[REF(src)];vote=[i]'>[choices[i]]</a> ([vote])</b></li>"
					else
						. += "<li><a href='?src=[REF(src)];vote=[i]'>[choices[i]]</a></li>"
					if(choice_descs.len >= i)
						. += "<li>[choice_descs[i]]</li>"
				. += "</ul><hr>"
				if(!(C.ckey in saved))
					. += "(<a href='?src=[REF(src)];vote=save'>Save vote</a>)"
				else
					. += "(Saved!)"
				. += "(<a href='?src=[REF(src)];vote=load'>Load vote from save</a>)"
				. += "(<a href='?src=[REF(src)];vote=reset'>Reset votes</a>)"
			if(SCORE_VOTING,HIGHEST_MEDIAN_VOTING)
				var/list/myvote = voted[C.ckey]
				for(var/i=1,i<=choices.len,i++)
					. += "<li><b>[choices[i]]</b>"
					for(var/r in 1 to GLOB.vote_score_options.len)
						. += " <a href='?src=[REF(src)];vote=[i];score=[r]'>"
						if((choices[i] in myvote) && myvote[choices[i]] == r)
							. +="<b>([GLOB.vote_score_options[r]])</b>"
						else
							. +="[GLOB.vote_score_options[r]]"
						. += "</a>"
					. += "</li>"
					if(choice_descs.len >= i)
						. += "<li>[choice_descs[i]]</li>"
				. += "</ul><hr>"
				if(!(C.ckey in saved))
					. += "(<a href='?src=[REF(src)];vote=save'>Save vote</a>)"
				else
					. += "(Saved!)"
				. += "(<a href='?src=[REF(src)];vote=load'>Load vote from save</a>)"
				. += "(<a href='?src=[REF(src)];vote=reset'>Reset votes</a>)"
		if(admin)
			. += "(<a href='?src=[REF(src)];vote=cancel'>Cancel Vote</a>) "
	else
		. += "<h2>Start a vote:</h2><hr><ul><li>"
		//restart
		var/avr = CONFIG_GET(flag/allow_vote_restart)
		if(trialmin || avr)
			. += "<a href='?src=[REF(src)];vote=restart'>Restart</a>"
		else
			. += "<font color='grey'>Restart (Disallowed)</font>"
		if(trialmin)
			. += "\t(<a href='?src=[REF(src)];vote=toggle_restart'>[avr ? "Allowed" : "Disallowed"]</a>)"
		. += "</li><li>"
		//gamemode
		var/avm = CONFIG_GET(flag/allow_vote_mode)
		if(trialmin || avm)
			. += "<a href='?src=[REF(src)];vote=gamemode'>GameMode</a>"
		else
			. += "<font color='grey'>GameMode (Disallowed)</font>"
		if(trialmin)
			. += "\t(<a href='?src=[REF(src)];vote=toggle_gamemode'>[avm ? "Allowed" : "Disallowed"]</a>)"

		. += "</li>"
		//custom
		if(trialmin)
			. += "<li><a href='?src=[REF(src)];vote=custom'>Custom</a></li>"
		. += "</ul><hr>"
	. += "<a href='?src=[REF(src)];vote=close' style='position:absolute;right:50px'>Close</a>"
	return .


/datum/controller/subsystem/vote/Topic(href,href_list[],hsrc)
	if(!usr || !usr.client)
		return	//not necessary but meh...just in-case somebody does something stupid
	switch(href_list["vote"])
		if("close")
			voting -= usr.client
			usr << browse(null, "window=vote")
			return
		if("cancel")
			if(usr.client.holder)
				if(SSticker.mapvote_restarter_in_progress)
					SSticker.mapvote_restarter_in_progress = FALSE
					SSpersistence.RecordGracefulEnding()
					SSticker.start_immediately = FALSE
					SSticker.SetTimeLeft(2400)
					to_chat(world, span_boldwarning("Автоматическая ротация карты была отменена администрацией"))
				reset()
		if("toggle_restart")
			if(usr.client.holder)
				CONFIG_SET(flag/allow_vote_restart, !CONFIG_GET(flag/allow_vote_restart))
		if("toggle_gamemode")
			if(usr.client.holder)
				CONFIG_SET(flag/allow_vote_mode, !CONFIG_GET(flag/allow_vote_mode))
		if("restart")
			if(CONFIG_GET(flag/allow_vote_restart) || usr.client.holder)
				initiate_vote("restart",usr.key)
		if("gamemode")
			if(CONFIG_GET(flag/allow_vote_mode) || usr.client.holder)
				initiate_vote("gamemode",usr.key)
		if("custom")
			if(usr.client.holder)
				initiate_vote("custom",usr.key)
		if("reset")
			if(usr.ckey in voted)
				voted -= usr.ckey
		if("save")
			if(usr.ckey in voted)
				if(!(usr.ckey in SSpersistence.saved_votes))
					SSpersistence.saved_votes[usr.ckey] = list()
				if(islist(voted[usr.ckey]))
					SSpersistence.saved_votes[usr.ckey][mode] = voted[usr.ckey]
					saved += usr.ckey
				else
					voted[usr.ckey] = list()
					to_chat(usr,"Your vote was malformed! Start over!")
		if("load")
			if(!(usr.ckey in SSpersistence.saved_votes))
				SSpersistence.LoadSavedVote(usr.ckey)
				if(!(usr.ckey in SSpersistence.saved_votes))
					SSpersistence.saved_votes[usr.ckey] = list()
					if(usr.ckey in voted)
						SSpersistence.saved_votes[usr.ckey][mode] = voted[usr.ckey]
					else
						SSpersistence.saved_votes[usr.ckey][mode] = list()
			voted[usr.ckey] = SSpersistence.saved_votes[usr.ckey][mode]
			if(islist(voted[usr.ckey]))
				var/malformed = FALSE
				if(vote_system == SCORE_VOTING || vote_system == HIGHEST_MEDIAN_VOTING)
					for(var/thing in voted[usr.ckey])
						if(!(thing in choices))
							malformed = TRUE
				if(!malformed)
					saved += usr.ckey
				else
					to_chat(usr,"Your saved vote was malformed! Start over!")
					SSpersistence.saved_votes[usr.ckey] -= mode
					voted -= usr.ckey
			else
				to_chat(usr,"Your saved vote was malformed! Start over!")
				voted -= usr.ckey
		else
			if(vote_system == SCORE_VOTING || vote_system == HIGHEST_MEDIAN_VOTING)
				submit_vote(round(text2num(href_list["vote"])),round(text2num(href_list["score"])))
			else
				submit_vote(round(text2num(href_list["vote"])))
	if(!href_list["statpannel"])
		usr.vote()

/datum/controller/subsystem/vote/proc/remove_action_buttons()
	for(var/v in generated_actions)
		var/datum/action/vote/V = v
		if(!QDELETED(V))
			V.remove_from_client()
			V.Remove(V.owner)
	generated_actions = list()

/mob/verb/vote()
	set category = "OOC"
	set name = "Vote"

	var/datum/browser/popup = new(src, "vote", "Voting Panel",nwidth=600,nheight=700)
	popup.set_window_options("can_close=0")
	popup.set_content(SSvote.interface(client))
	popup.open(0)

/datum/action/vote
	name = "Vote!"
	button_icon_state = "vote"

/datum/action/vote/Trigger()
	if(owner)
		owner.vote()
		remove_from_client()
		Remove(owner)

/datum/action/vote/IsAvailable(silent = FALSE)
	return TRUE

/datum/action/vote/proc/remove_from_client()
	if(!owner)
		return
	if(owner.client)
		owner.client.player_details.player_actions -= src
	else if(owner.ckey)
		var/datum/player_details/P = GLOB.player_details[owner.ckey]
		if(P)
			P.player_actions -= src

/proc/pick_dynamic_type_by_chaos(list/players, last_dynamic_type)
	var/total_chaos = 0

	for(var/mob/player in players)
		if(!player?.client?.prefs)
			continue
		var/chaos = player.client.prefs.preferred_chaos_level
		if(isnum(chaos))
			total_chaos += chaos

	var/list/available_hard = list(ROUNDTYPE_DYNAMIC_TEAMBASED, ROUNDTYPE_DYNAMIC_HARD)
	var/list/available_medium = list(ROUNDTYPE_DYNAMIC_MEDIUM)
	// var/list/available_medium = list(ROUNDTYPE_DYNAMIC_MEDIUM, ROUNDTYPE_DYNAMIC_LIGHT) - last_dynamic_type

	var/dynamic_type
	if(get_total_player_count() >= 30)
		if(total_chaos >= CONFIG_GET(number/chaos_for_a_hard_dynamic) && length(available_hard))
			dynamic_type = pick(available_hard)
		else
			dynamic_type = pick(available_medium)
	else
		dynamic_type = ROUNDTYPE_DYNAMIC_LIGHT

	// Логируем детали выбора
	message_admins("Выбранный Динамик: [dynamic_type]. Количество игроков - [players.len]. \
	Уровень хаоса от игроков - [total_chaos]. [CONFIG_GET(number/chaos_for_a_hard_dynamic)] было нужно для Хард-Динамика.")
	log_admin("Выбранный Динамик: [dynamic_type]. Количество игроков - [players.len]. \
	Уровень хаоса от игроков - [total_chaos]. [CONFIG_GET(number/chaos_for_a_hard_dynamic)] было нужно для Хард-Динамика.")

	return dynamic_type
