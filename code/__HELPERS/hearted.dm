/// Returns mobs whose real_name / mind name matches words in text (same rules as adminhelp keyword scan, without HTML).
/proc/heart_nominee_lookup(text)
	var/list/adminhelp_ignored_words = list("unknown", "the", "a", "an", "of", "monkey", "alien", "as", "i")
	var/list/msglist = splittext(text, " ")
	var/list/surnames = list()
	var/list/forenames = list()
	var/list/ckeys = list()
	for(var/mob/M in GLOB.mob_list)
		var/list/indexing = list(M.real_name, M.name)
		if(M.mind)
			indexing += M.mind.name
		for(var/string in indexing)
			var/list/L = splittext(string, " ")
			var/surname_found = 0
			for(var/i = L.len, i >= 1, i--)
				var/word = ckey(L[i])
				if(word)
					surnames[word] = M
					surname_found = i
					break
			for(var/i = 1, i < surname_found, i++)
				var/word = ckey(L[i])
				if(word)
					forenames[word] = M
		if(M.ckey)
			ckeys[M.ckey] = M
	var/ai_found = 0
	var/list/mobs_found = list()
	for(var/original_word in msglist)
		var/word = ckey(original_word)
		if(!word || (word in adminhelp_ignored_words))
			continue
		if(word == "ai")
			ai_found = 1
			continue
		var/mob/found = ckeys[word]
		if(!found)
			found = surnames[word]
		if(!found)
			found = forenames[word]
		if(!found)
			continue
		if(found in mobs_found)
			continue
		mobs_found += found
		if(!ai_found && isAI(found))
			ai_found = 1
	return mobs_found

/// Called when the shuttle starts launching back to centcom, polls a few random players who joined the round for commendations
/datum/controller/subsystem/ticker/proc/poll_hearts()
	if(!CONFIG_GET(number/commendation_percent_poll))
		return

	var/number_to_ask = round(LAZYLEN(GLOB.joined_player_list) * CONFIG_GET(number/commendation_percent_poll)) + rand(0, 1)
	var/list/eligible = list()
	for(var/player_ckey in GLOB.joined_player_list)
		var/mob/check_mob = get_mob_by_ckey(player_ckey)
		if(!check_mob?.mind || !check_mob.client)
			continue
		eligible += check_mob
	if(!length(eligible) || number_to_ask <= 0)
		message_admins("Not enough eligible players to poll for commendations.")
		return
	shuffle_inplace(eligible)
	number_to_ask = min(number_to_ask, length(eligible))
	message_admins("Polling [number_to_ask] players for commendations.")
	for(var/i in 1 to number_to_ask)
		var/mob/check_mob = eligible[i]
		INVOKE_ASYNC(check_mob, TYPE_PROC_REF(/mob, query_heart), 1)

/// Once the round is actually over, cycle through the commendations in the hearts list and give them the hearted status
/datum/controller/subsystem/ticker/proc/handle_hearts()
	if(!LAZYLEN(hearts))
		return
	var/list/commended = list()
	for(var/hearted_ckey in hearts)
		var/mob/hearted_mob = get_mob_by_ckey(hearted_ckey)
		if(!hearted_mob?.client)
			continue
		hearted_mob.client.adjust_heart()
		commended += hearted_ckey
	if(length(commended))
		message_admins("The following players were commended this round: [commended.Join(", ")]")
	LAZYCLEARLIST(hearts)

///Gives someone hearted status for OOC, from behavior commendations
/client/proc/adjust_heart(duration = 24 HOURS)
	var/new_duration = world.realtime + duration
	if(prefs.hearted_until > new_duration)
		return
	tgui_alert(src, "Кто-то поблагодарил меня за прошлый раунд!", "<3!", list("Лан"))
	prefs.hearted_until = new_duration
	prefs.hearted = TRUE
	prefs.save_preferences()

/// Ask someone if they'd like to award a commendation for the round, 3 tries to get the name they want before we give up
/mob/proc/query_heart(attempt=1)
	if(!client || attempt > 3)
		return
	if(attempt == 1 && tgui_alert(src, "Понравился ли тебе кто-то в этом раунде?", "<3?", list("Да", "Нет"), timeout = 30 SECONDS) != "Да")
		return

	var/heart_nominee
	switch(attempt)
		if(1)
			heart_nominee = tgui_input_text(src, "Как его зовут? Можешь ввести имя или фамилию. (оставь пустым для отмены)", "<3?")
		if(2)
			heart_nominee = tgui_input_text(src, "Погоди, как там зовут? Можешь ввести имя или фамилию. (оставь пустым для отмены)", "<3?")
		if(3)
			heart_nominee = tgui_input_text(src, "Давай попробуем ещё, как зовут душку? Можешь ввести имя или фамилию. (оставь пустым для отмены)", "<3?")

	if(isnull(heart_nominee) || heart_nominee == "")
		return

	heart_nominee = lowertext(heart_nominee)
	var/list/name_checks = heart_nominee_lookup(heart_nominee)
	if(!length(name_checks))
		query_heart(attempt + 1)
		return
	name_checks = shuffle(name_checks)

	for(var/i in name_checks)
		var/mob/heart_contender = i
		if(heart_contender == src)
			continue

		switch(tgui_alert(src, "Это нужный господин/госпожа: [heart_contender.real_name]?", "<3?", list("Да!", "Не", "Отмена"), timeout = 15 SECONDS))
			if("Да!")
				heart_contender.receive_heart(src)
				return
			if("Не")
				continue
			if("Отмена")
				return

	query_heart(attempt + 1)

/*
* Once we've confirmed who we're commending, either set their status now or log it for the end of the round
*
* This used to be reversed, being named nominate_heart and being called on the mob sending the commendation and the first argument being
* the heart_recepient, but that was confusing and unintuitive, so now src is the person being commended and the sender is now the first argument.
*
* Arguments:
* * heart_sender: The reference to the mob who sent the commendation, just for the purposes of logging
* * duration: How long from the moment it's applied the heart will last
* * instant: If TRUE (or if the round is already over), we'll give them the heart status now, if FALSE, we wait until the end of the round (which is the standard behavior)
*/
/mob/proc/receive_heart(mob/heart_sender, duration = 24 HOURS, instant = FALSE)
	if(!client)
		return
	to_chat(heart_sender, span_nicegreen("Отправлено!"))
	message_admins("[key_name(heart_sender)] commended [key_name(src)] [instant ? "(instant)" : ""]")
	log_admin("[key_name(heart_sender)] commended [key_name(src)] [instant ? "(instant)" : ""]")
	if(instant || SSticker.current_state == GAME_STATE_FINISHED)
		client.adjust_heart(duration)
	else
		var/recipient_ckey = client.ckey
		if(recipient_ckey && (!SSticker.hearts || !(recipient_ckey in SSticker.hearts)))
			LAZYADD(SSticker.hearts, recipient_ckey)
