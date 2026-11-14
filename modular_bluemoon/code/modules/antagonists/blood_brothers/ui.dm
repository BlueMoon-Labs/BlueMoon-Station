/datum/antagonist/brother
	ui_intro = FALSE
	/// Был в команде до клятвы: предыстория команды - его собственная
	var/founder = FALSE

/datum/antagonist/brother/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, ui_name, "Кровная клятва")
		ui.open()

/datum/antagonist/brother/ui_static_data(mob/user)
	var/list/data = ..()
	data["antag_name"] = name
	data["backstory"] = team?.backstory
	data["backstory_owner"] = founder
	var/list/brothers = list()
	for(var/datum/mind/member as anything in team?.window_minds())
		brothers += list(list(
			"name" = member.name,
			"job" = member.assigned_role,
			"self" = member == owner,
		))
	data["brothers"] = brothers
	data["bond_ladder"] = bond_ladder_data()
	data["rules"] = list(
		"Кровь клятвы оставила шрам на ладони: его видно при осмотре, если руки без перчаток, а медицинский анализатор находит его и под перчатками. На протезе и на руке КПБ шрама нет.",
		"Майндшилд или тело без крови, вроде борга, глушат связь: способности, Чутьё и печати не работают, а голосовать за клятву нельзя.",
		"Обряд священника или операция по иссечению шрама рвут клятву навсегда.",
		"Исполнив клятву, можно дать следующую: венцы исполненных клятв остаются за вами.",
		"Если обет цел к третьей печати, перезарядки связи до конца смены на [round((1 - BROTHER_FLAWLESS_COOLDOWN_MULT) * 100)]% короче.",
		"Вы - малые антагонисты: действуйте по клятве, без лишнего вреда экипажу. Убийство - только если его требует клятва, и только разовое: тело не уничтожать, из раунда не выводить.",
	)
	var/list/offer_texts = list()
	for(var/datum/blood_oath/candidate as anything in team?.offered)
		offer_texts += list(candidate.ui_texts())
	data["offer_texts"] = offer_texts
	data["oath_texts"] = team?.oath?.ui_texts()
	var/list/fulfilled_names = list()
	for(var/datum/blood_oath/fulfilled as anything in team?.all_fulfilled_oaths())
		fulfilled_names += fulfilled.name
	data["fulfilled"] = fulfilled_names
	return data

/datum/antagonist/brother/ui_data(mob/user)
	var/list/data = list()
	if(!team)
		return data
	var/datum/blood_oath/oath = team.oath
	var/muted = is_muted()
	if(!oath)
		data["state"] = "choosing"
	else
		data["state"] = team.choosing_oath() ? "next" : "sworn"
	var/list/offered_keys = list()
	for(var/datum/blood_oath/candidate as anything in team.offered)
		offered_keys += candidate.key
	data["offered"] = offered_keys
	data["proposed_key"] = team.proposed?.key
	data["proposed_by"] = team.proposed_by?.name
	data["i_proposed"] = team.proposed_by == owner
	data["i_signed"] = (owner in team.signed)
	data["unsigned"] = team.proposed ? team.unsigned_names() : list()
	data["deadline_left"] = oath ? 0 : max(0, team.oath_deadline - world.time) / (1 SECONDS)
	var/datum/blood_oath_step/current = oath?.current_step()
	var/step_verdict = current?.can_seal(owner.current)
	data["oath"] = oath?.ui_progress(current, owner.current, step_verdict)
	data["current_step"] = current ? oath.steps.Find(current) : 0
	data["can_seal"] = current ? team.seal_refusal(owner, step_verdict) : FALSE
	data["finale_check"] = (oath && !current) ? finale_check_data(muted) : null
	data["tier"] = team.bond_tier
	data["tier_max"] = BLOOD_BOND_TIER_MAX
	var/list/earned_names = list()
	for(var/capstone_type in team.earned_capstones())
		var/list/capstone_data = blood_bond_ability_data(capstone_type)
		earned_names += capstone_data["name"]
	data["earned_capstones"] = earned_names
	data["cooldown_mult"] = team.cooldown_multiplier
	var/datum/blood_vow/vow = team.vow
	data["vow"] = vow ? list(
		"name" = vow.name,
		"desc" = vow.desc,
		"broken" = vow.broken,
		"broken_reason" = vow.broken_reason,
	) : null
	data["brother_states"] = brother_states_data()
	var/list/abilities = list()
	for(var/action_type in bond_actions)
		var/datum/action/bond_action = bond_actions[action_type]
		abilities += list(list(
			"name" = bond_action.name,
			"desc" = bond_action.desc,
		))
	data["abilities"] = abilities
	var/datum/action/cooldown/blood_bond/recruit/recruit_type = /datum/action/cooldown/blood_bond/recruit
	data["recruit"] = list("name" = initial(recruit_type.name), "slot" = team.recruit_slot_text())
	data["muted"] = muted
	data["whispers"] = muted ? list() : team.whispers_heard_by(owner)
	data["bond_pulse"] = muted ? null : team.bond_pulse
	return data

/datum/team/brother_team
	/// Растёт с каждым Шёпотом крови и вестью связи; окно пускает по нити каплю
	var/bond_pulse = 0

/// Капля по нити в окнах братьев; не спит
/datum/team/brother_team/proc/pulse_bond()
	bond_pulse++
	for(var/datum/antagonist/brother/brother as anything in brother_antags())
		var/datum/action/recruit = brother.bond_actions[/datum/action/cooldown/blood_bond/recruit]
		recruit?.UpdateButtons()
		SStgui.update_uis(brother)

/// Шёпоты из журнала, которые дошли до viewer
/datum/team/brother_team/proc/whispers_heard_by(datum/mind/viewer)
	. = list()
	var/datum/weakref/viewer_ref = WEAKREF(viewer)
	for(var/list/entry as anything in whisper_log)
		if(viewer_ref in entry["heard"])
			. += list(list("name" = entry["name"], "text" = entry["text"], "time" = entry["time"]))

/// Братья в шапке окна: разорвавшие клятву из команды выбывают, но нить к ним видна
/datum/team/brother_team/proc/window_minds()
	return members | severed_minds

/// Кто из голосующих ещё не подписал предложенную клятву
/datum/team/brother_team/proc/unsigned_names()
	. = list()
	for(var/datum/mind/member as anything in members)
		if(!is_active_brother(member) || (member in signed))
			continue
		var/datum/antagonist/brother/member_brother = member.has_antag_datum(/datum/antagonist/brother)
		if(!member_brother?.is_muted())
			. += member.name

/datum/team/brother_team/proc/recruit_slot_text()
	if(replacement_available)
		return "открыта замена"
	if(third_oath_used || length(members - departed_minds) >= BROTHER_TEAM_MAX_SIZE)
		return "использована"
	return "свободна"

/datum/action/cooldown/blood_bond/recruit/UpdateButton(atom/movable/screen/movable/action_button/button, status_only = FALSE, force = FALSE)
	. = ..()
	if(!button || status_only || !brother?.team)
		return
	button.desc += "<br>Место в братстве: [brother.team.recruit_slot_text()]."

/// Тексты клятвы для ui_static_data: меняются только при подборе целей и клятве
/datum/blood_oath/proc/ui_texts()
	var/list/step_texts = list()
	for(var/datum/blood_oath_step/oath_step as anything in steps)
		step_texts += list(list(
			"name" = oath_step.name,
			"desc" = oath_step.desc,
		))
	var/datum/blood_vow/shown_vow = team?.oath == src ? team.vow : vow
	return list(
		"key" = key,
		"name" = name,
		"summary" = summary,
		"story" = story,
		"kit" = kit_text(),
		"vow_name" = shown_vow?.name,
		"vow_desc" = shown_vow?.desc,
		"steps" = step_texts,
		"capstone" = capstone_payload(),
		"finale" = finale_text(),
	)

/datum/blood_oath/proc/finale_text()
	var/extra = finale_extra_text()
	return "всем живым братьям - до ЦК, без наручников[extra ? "; [extra]" : ""]"

/// Печати шагов для ui_data; условие считается только у текущего шага, step_verdict - его can_seal
/datum/blood_oath/proc/ui_progress(datum/blood_oath_step/current, mob/living/viewer, step_verdict)
	var/list/step_data = list()
	for(var/datum/blood_oath_step/oath_step as anything in steps)
		step_data += list(list(
			"sealed" = oath_step.sealed,
			"sealed_by" = oath_step.sealed_by,
			"condition" = oath_step == current ? oath_step.condition_text(viewer, step_verdict) : null,
		))
	return list("key" = key, "steps" = step_data)

/// Финал после третьей печати: где каждый живой брат и выполнено ли условие клятвы; заглушённый видит только себя
/datum/antagonist/brother/proc/finale_check_data(muted)
	var/datum/objective/blood_oath_escape/escape = locate() in team.objectives
	var/list/rows = list()
	for(var/datum/mind/member as anything in team.members - team.severed_minds - team.departed_minds)
		if(muted && member != owner)
			continue
		var/mob/living/carbon/body = member.current
		var/status = "ещё на станции"
		var/done = FALSE
		if(QDELETED(body) || body.stat == DEAD)
			status = "не мешает"
			done = TRUE
		else if(iscarbon(body) && body.handcuffed)
			status = "в наручниках"
		else if(escape?.considered_escaped(member))
			status = "на ЦК"
			done = TRUE
		rows += list(list("name" = member.name, "status" = status, "done" = done))
	var/extra = team.oath.finale_extra_text()
	return list(
		"brothers" = rows,
		"extra" = extra,
		"extra_done" = extra ? team.oath.finale_extra_complete() : TRUE,
	)

/datum/antagonist/brother/proc/brother_states_data()
	var/list/states = list()
	var/viewer_muted = is_muted()
	var/turf/own_turf = get_turf(owner.current)
	for(var/datum/mind/member as anything in team.window_minds())
		var/self = member == owner
		var/mob/living/body = member.current
		var/state
		var/state_text
		if(member in team.severed_minds)
			state = BROTHER_STATE_SEVERED
			state_text = brother_severed_text(team.severed_kinds[member])
		else
			var/datum/antagonist/brother/member_brother = member.has_antag_datum(/datum/antagonist/brother)
			state = member_brother ? member_brother.brother_state() : BROTHER_STATE_GONE
			if(viewer_muted && !self)
				state = BROTHER_STATE_MUTED
			state_text = brother_state_text(state, body)
		var/hidden = self || (state in list(BROTHER_STATE_MUTED, BROTHER_STATE_GONE, BROTHER_STATE_SEVERED))
		states += list(list(
			"name" = member.name,
			"state" = state,
			"state_text" = state_text,
			"critical" = state == BROTHER_STATE_CRIT && isliving(body) && body.InCritical(),
			"direction" = hidden ? null : blood_bond_direction_text(own_turf, get_turf(body)),
			"self" = self,
		))
	return states

/proc/brother_severed_text(kind)
	switch(kind)
		if(BROTHER_SEVER_RITE)
			return "клятву разорвали: обряд"
		if(BROTHER_SEVER_SURGERY)
			return "клятву разорвали: операция"
	return "клятву разорвали"

/datum/antagonist/brother/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(. || !team || ui?.user?.mind != owner)
		return
	switch(action)
		if("propose")
			var/oath_key = params["key"]
			if(!istext(oath_key) || muted_vote_refusal())
				return FALSE
			return team.propose_oath(owner, oath_key)
		if("sign")
			if(muted_vote_refusal())
				return FALSE
			return team.sign_oath(owner)
		if("seal")
			var/result = team.try_seal(owner)
			if(result != TRUE)
				to_chat(owner.current, span_warning("Шаг не скрепить: [result]."))
			return TRUE

/datum/antagonist/brother/proc/muted_vote_refusal()
	if(!is_muted())
		return FALSE
	to_chat(owner.current, span_warning("Связь заглушена: голосовать за клятву нельзя."))
	return TRUE
