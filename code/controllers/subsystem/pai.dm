SUBSYSTEM_DEF(pai)
	name = "pAI"

	flags = SS_NO_FIRE

	var/list/candidates = list()
	var/list/pai_card_list = list()
	var/list/restricted_areas = list()
	var/last_device_ref

/datum/controller/subsystem/pai/Initialize(var/time_of_day)
	restricted_areas += typesof(/area/command/heads_quarters, /area/ai_monitored) // heads quarters and AI monitored places (like the armory)
	initialized = TRUE
	return ..()

/datum/controller/subsystem/pai/proc/recruitWindow(mob/M, obj/item/paicard/card)
	if(isobserver(M))
		var/mob/dead/observer/O = M
		if(!O.can_reenter_round())
			return
	var/datum/paiCandidate/candidate
	for(var/datum/paiCandidate/c in candidates)
		if(c.key == M.key)
			candidate = c
	if(!candidate)
		candidate = new /datum/paiCandidate()
		candidate.key = M.key
		candidates.Add(candidate)
	candidate.card_ref = REF(card)
	var/datum/tgui/ui = SStgui.try_update_ui(M, src, null, "pai_submit")
	if(!ui)
		ui = new(M, src, "PaiSubmit", "Меню кандидатов ПИИ")
		ui.set_autoupdate(TRUE)
		ui.open()

/datum/controller/subsystem/pai/proc/check_ready(var/datum/paiCandidate/C)
	if(!C.ready)
		return FALSE
	for(var/mob/dead/observer/O in GLOB.player_list)
		if(O.key == C.key)
			return C
	return FALSE



/datum/controller/subsystem/pai/ui_data(mob/user)
	var/list/data = list()
	for(var/datum/paiCandidate/c in candidates)
		if(c.key == user.key)
			data["name"] = c.name
			data["description"] = c.description
			data["comments"] = c.comments
			data["has_candidate"] = TRUE
			data["card_ref"] = c.card_ref
			data["load_version"] = c.load_version
			if(c.card_ref)
				var/obj/item/paicard/pai_card = locate(c.card_ref) in pai_card_list
				if(pai_card)
					data["is_inteq"] = istype(pai_card, /obj/item/paicard/inteq)
			break
	if(!data["has_candidate"])
		data["has_candidate"] = FALSE
	return data

/datum/controller/subsystem/pai/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if(..())
		return TRUE
	switch(action)
		if("submit")
			var/datum/paiCandidate/candidate
			for(var/datum/paiCandidate/c in candidates)
				if(c.key == usr.key)
					candidate = c
					break
			if(!candidate)
				candidate = new /datum/paiCandidate()
				candidate.key = usr.key
				candidates.Add(candidate)
			if(isobserver(usr))
				var/mob/dead/observer/O = usr
				if(!O.can_reenter_round())
					return TRUE
			if(params["name"])
				candidate.name = copytext_char(sanitize(params["name"]), 1, MAX_NAME_LEN)
			if(params["description"])
				candidate.description = copytext_char(sanitize(params["description"]), 1, MAX_MESSAGE_LEN)
			if(params["comments"])
				candidate.comments = copytext_char(sanitize(params["comments"]), 1, MAX_MESSAGE_LEN)
			candidate.ready = TRUE
			if(candidate.card_ref)
				var/obj/item/paicard/pai_card = locate(candidate.card_ref) in pai_card_list
				if(!pai_card)
					to_chat(usr, "<span class='warning'>Устройство ПИИ больше недоступно.</span>")
				else if(pai_card.pai)
					to_chat(usr, "<span class='warning'>Это устройство ПИИ уже занято другой личностью.</span>")
				else
					download_candidate_card(candidate.key, pai_card, usr)
				if(ui)
					ui.close()
				return TRUE
			for(var/obj/item/paicard/p in pai_card_list)
				if(!p.pai)
					SStgui.update_uis(p)
			if(ui)
				ui.close()
			return TRUE
		if("save")
			for(var/datum/paiCandidate/c in candidates)
				if(c.key == usr.key)
					if(params["name"])
						c.name = copytext_char(sanitize(params["name"]), 1, MAX_NAME_LEN)
					if(params["description"])
						c.description = copytext_char(sanitize(params["description"]), 1, MAX_MESSAGE_LEN)
					if(params["comments"])
						c.comments = copytext_char(sanitize(params["comments"]), 1, MAX_MESSAGE_LEN)
					c.savefile_save(usr)
					return TRUE
			return TRUE
		if("load")
			for(var/datum/paiCandidate/c in candidates)
				if(c.key == usr.key)
					c.savefile_load(usr)
					c.load_version++
					if(c.name)
						c.name = copytext_char(sanitize(c.name), 1, MAX_NAME_LEN)
					if(c.description)
						c.description = copytext_char(sanitize(c.description), 1, MAX_MESSAGE_LEN)
					c.comments = copytext_char(sanitize(c.comments), 1, MAX_MESSAGE_LEN)
					return TRUE
			return TRUE
		if("withdraw")
			for(var/datum/paiCandidate/c in candidates)
				if(c.key == usr.key)
					candidates -= c
					if(ui)
						ui.close()
					return TRUE
			return TRUE

/datum/controller/subsystem/pai/proc/download_candidate_card(ckey, obj/item/paicard/card, mob/user)
	if(!istype(card, /obj/item/paicard))
		return FALSE
	if(card.pai)
		return FALSE
	for(var/datum/paiCandidate/candidate in candidates)
		if(candidate.key != ckey)
			continue
		if(check_ready(candidate) != candidate)
			return FALSE
		var/mob/living/silicon/pai/pai
		if(istype(card, /obj/item/paicard/inteq))
			pai = new /mob/living/silicon/pai/inteq(card)
		else
			pai = new(card)
		if(!candidate.name)
			pai.name = pick(GLOB.ninja_names)
		else
			pai.name = candidate.name
		pai.real_name = pai.name
		if(pai.pda)
			pai.pda.saved_identification = pai.name
			pai.pda.owner = pai.name
			pai.pda.name = "[pai.name] (Мессенджер ПИИ)"
		pai.key = candidate.key
		if(istype(pai, /mob/living/silicon/pai/inteq))
			var/mob/living/silicon/pai/inteq/SP = pai
			SP.apply_inteq_antag()
		card.setPersonality(pai)
		SSticker.mode?.update_cult_icons_removed(card.pai.mind)
		candidates -= candidate
		SStgui.update_uis(card)
		var/atom/holder = card.loc
		while(holder && !ismob(holder))
			holder = holder.loc
		if(holder && ismob(holder))
			var/message = "ПИИ [pai.name] загружен в ваше устройство."
			if(candidate.comments)
				message += " Заметки кандидата: [candidate.comments]"
			to_chat(holder, span_notice(message))
		return TRUE
	return FALSE

/datum/controller/subsystem/pai/ui_state(mob/user)
	return GLOB.always_state

/datum/paiCandidate
	var/name
	var/key
	var/description
	var/comments
	var/ready = 0
	var/card_ref
	var/load_version = 0
