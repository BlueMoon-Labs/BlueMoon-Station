/datum/antagonist/brother
	name = "Blood Brother"
	roundend_category = "blood brothers"
	antagpanel_category = "Brother"
	job_rank = ROLE_BROTHER
	antag_hud_type = ANTAG_HUD_BROTHER
	antag_hud_name = "blood_brother"
	ui_name = "AntagInfoBloodBrother"
	antag_moodlet = /datum/mood_event/focused
	threat = 3
	var/datum/team/brother_team/team
	/// type -> экземпляр выданных способностей связи
	var/list/bond_actions = list()
	var/next_fury_at = 0
	/// Глушение, о котором брат и команда уже знают
	var/bond_muted = FALSE

/datum/antagonist/brother/Destroy()
	QDEL_LIST_ASSOC_VAL(bond_actions)
	// Из команды разум убирает родительский Destroy() через get_team()
	. = ..()
	team = null

/datum/antagonist/brother/create_team(datum/team/brother_team/new_team)
	if(new_team && !istype(new_team))
		stack_trace("Wrong team type passed to [type] initialization.")
		new_team = null
	team = new_team || new /datum/team/brother_team

/datum/antagonist/brother/get_team()
	return team

/datum/antagonist/brother/on_gain()
	objectives = team.objectives
	owner.special_role = ROLE_BROTHER
	if(!team.started && team.backstory)
		antag_memory += "<b>Предыстория</b>: [team.backstory]<br>"
	founder = !team.started
	. = ..()
	info_button.name = "Кровная клятва"
	info_button.UpdateButtons()
	SEND_SIGNAL(team, COMSIG_BROTHER_TEAM_MEMBER_JOINED, owner)

/datum/antagonist/brother/on_removal()
	owner.special_role = null
	objectives = list()
	return ..()

/datum/antagonist/brother/apply_innate_effects(mob/living/mob_override)
	var/mob/living/current = mob_override || owner.current
	add_antag_hud(antag_hud_type, hud_state_for(current), current)
	ADD_TRAIT(current, TRAIT_BLOOD_OATH_SCAR, BLOOD_OATH_TRAIT)
	RegisterSignals(current, list(SIGNAL_TRAIT(TRAIT_MINDSHIELD), SIGNAL_REMOVETRAIT(TRAIT_MINDSHIELD)), PROC_REF(on_mindshield_trait))
	RegisterSignal(current, COMSIG_MOB_STATCHANGE, PROC_REF(on_stat_change))
	RegisterSignal(current, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine))
	RegisterSignal(current, COMSIG_PARENT_QDELETING, PROC_REF(on_body_deleted))
	refresh_bond_actions(current)
	on_mute_changed()

/datum/antagonist/brother/remove_innate_effects(mob/living/mob_override)
	var/mob/living/current = mob_override || owner.current
	remove_antag_hud(antag_hud_type, current)
	REMOVE_TRAIT(current, TRAIT_BLOOD_OATH_SCAR, BLOOD_OATH_TRAIT)
	UnregisterSignal(current, list(SIGNAL_TRAIT(TRAIT_MINDSHIELD), SIGNAL_REMOVETRAIT(TRAIT_MINDSHIELD), COMSIG_MOB_STATCHANGE, COMSIG_PARENT_EXAMINE, COMSIG_PARENT_QDELETING))
	for(var/action_type in bond_actions)
		var/datum/action/bond_action = bond_actions[action_type]
		bond_action.Remove(current)
	if(isliving(current))
		current.remove_status_effect(/datum/status_effect/brother_sense)
		current.remove_status_effect(/datum/status_effect/brother_sense/blood_mark)
		clear_grief(current)
	end_bond_effects(current)
	team?.close_stash(current)

/datum/antagonist/brother/greet()
	var/mob/living/current = owner.current
	var/list/lines = greeting_lines()
	to_chat(current, lines.Join("<br>"))
	current.playsound_local(get_turf(current), 'modular_bluemoon/sound/blood_brothers/brother_stinger.ogg', BROTHER_STINGER_VOLUME, FALSE, pressure_affected = FALSE)

/// Основатели видят общую предысторию, принятый позже - чью клятву он принял
/datum/antagonist/brother/proc/greeting_lines()
	var/list/kin = list()
	for(var/datum/mind/other as anything in team.members - team.departed_minds)
		if(other != owner)
			kin += other.assigned_role ? "[other.name] ([other.assigned_role])" : other.name
	var/list/lines = list(span_userdanger("Вы - кровный брат."))
	if(team.started)
		if(length(kin))
			lines += span_boldnotice("Вы приняли клятву [length(kin) == 1 ? "брата" : "братьев"] [english_list(kin)].")
	else
		if(length(kin))
			lines += span_boldnotice("[length(kin) == 1 ? "Ваш брат по крови" : "Ваши братья по крови"]: [english_list(kin)].")
		if(team.backstory)
			lines += span_notice(team.backstory)
	lines += span_notice("Клятва, её шаги и ваши братья - в окне «Кровная клятва», его открывает кнопка в левом верхнем углу. Чутьё брата подскажет, где он и что с ним.")
	return lines

/datum/antagonist/brother/farewell()
	to_chat(owner.current, span_userdanger("Клятва больше не держит вас."))

/datum/antagonist/brother/admin_add(datum/mind/new_owner, mob/admin)
	var/list/candidates = list()
	for(var/mob/living/candidate_mob as anything in GLOB.alive_mob_list)
		var/datum/mind/candidate_mind = candidate_mob.mind
		if(!candidate_mind || candidate_mind == new_owner || candidate_mind.current != candidate_mob || !can_be_owned(candidate_mind))
			continue
		candidates["[candidate_mind.name] ([candidate_mind.key || "без игрока"])"] = candidate_mind
	if(!length(candidates))
		to_chat(admin, span_warning("Некого связать клятвой с [new_owner.name]."))
		return
	var/choice = tgui_input_list(admin, "С кем связать [new_owner.name] кровной клятвой?", "Кровные братья", sort_list(candidates))
	var/datum/mind/partner = candidates[choice]
	if(!partner || QDELETED(new_owner.current) || QDELETED(partner.current) || !can_be_owned(new_owner) || !can_be_owned(partner))
		return
	var/datum/team/brother_team/new_team = new
	new_team.add_member(new_owner)
	new_team.add_member(partner)
	new_owner.add_antag_datum(/datum/antagonist/brother, new_team)
	partner.add_antag_datum(/datum/antagonist/brother, new_team)
	new_team.start()
	message_admins("[key_name_admin(admin)] связал [key_name_admin(new_owner)] и [key_name_admin(partner)] кровной клятвой.")
	log_admin("[key_name(admin)] made [key_name(new_owner)] and [key_name(partner)] into blood brothers.")

/datum/antagonist/brother/get_admin_commands()
	. = ..()
	.["Разорвать клятву"] = CALLBACK(src, PROC_REF(admin_sever))
	.["Сменить клятву"] = CALLBACK(src, PROC_REF(admin_change_oath))
	.["Ступень связи"] = CALLBACK(src, PROC_REF(admin_set_tier))
	.["Скрепить или снять шаг"] = CALLBACK(src, PROC_REF(admin_toggle_step))
	.["Вернуть слоты"] = CALLBACK(src, PROC_REF(admin_restore_slots))

/datum/antagonist/brother/admin_remove(mob/user)
	if(!user)
		return
	if(!team || !(owner in team.members))
		return ..()
	admin_sever(user)

/datum/antagonist/brother/proc/admin_sever(mob/admin)
	log_admin("[key_name(admin)] severed the blood oath of [key_name(owner)] in [team.name].")
	team.sever(owner, "администратор [key_name(admin)]", BROTHER_SEVER_ADMIN)

/datum/antagonist/brother/proc/admin_change_oath(mob/admin)
	var/list/choices = list()
	for(var/oath_type in GLOB.blood_oath_types)
		var/datum/blood_oath/probe = new oath_type
		choices["[probe.name]: [probe.summary][probe.available(team) ? "" : " (недоступна в этом раунде)"]"] = oath_type
		qdel(probe)
	var/choice = tgui_input_list(admin, "Новая клятва команды [team.name]. Ступень и обет сохранятся, печати начнутся заново. Исполненная клятва останется в зачёте вместе с венцом.", "Кровные братья", choices)
	var/oath_type = choices[choice]
	if(!oath_type || QDELETED(src) || QDELETED(team))
		return
	admin_apply_oath(admin, oath_type)

/// Клятва oath_type вместо нынешней; нынешняя остаётся, если новую не принять, а исполненная уходит в зачёт
/datum/antagonist/brother/proc/admin_apply_oath(mob/admin, oath_type)
	var/datum/blood_oath/new_oath = new oath_type
	if(!new_oath.prepare(team))
		to_chat(admin, span_warning("Клятве «[new_oath.name]» не нашлось целей."))
		qdel(new_oath)
		return FALSE
	var/datum/blood_oath/old_oath = team.oath
	var/discard_old = old_oath?.current_step()
	if(discard_old)
		team.oath = null
	team.swear_oath(new_oath, keep_vow = TRUE)
	if(team.oath != new_oath)
		if(!QDELETED(new_oath))
			qdel(new_oath)
		if(discard_old)
			if(team.oath)
				qdel(old_oath)
			else
				team.oath = old_oath
		to_chat(admin, span_warning("Клятва не принята."))
		return FALSE
	if(discard_old)
		qdel(old_oath)
	admin_bond_changed()
	message_admins("[key_name_admin(admin)] сменил клятву команды братьев [team.name] на «[new_oath.name]».")
	log_admin("[key_name(admin)] changed the oath of blood brothers [team.name] to [new_oath.key].")
	return TRUE

/datum/antagonist/brother/proc/admin_set_tier(mob/admin)
	var/new_tier = tgui_input_number(admin, "Ступень связи команды [team.name], от 0 до [BLOOD_BOND_TIER_MAX]", "Кровные братья", team.bond_tier, BLOOD_BOND_TIER_MAX, 0)
	if(isnull(new_tier) || QDELETED(src) || !team.set_bond_tier(new_tier))
		return
	admin_bond_changed()
	message_admins("[key_name_admin(admin)] выставил команде братьев [team.name] ступень связи [team.bond_tier].")
	log_admin("[key_name(admin)] set bond tier of blood brothers [team.name] to [team.bond_tier].")

/datum/antagonist/brother/proc/admin_toggle_step(mob/admin)
	var/datum/blood_oath/oath = team.oath
	if(!oath)
		to_chat(admin, span_warning("Команда [team.name] ещё не дала клятву."))
		return
	var/list/choices = list()
	for(var/step_index in 1 to length(oath.steps))
		var/datum/blood_oath_step/oath_step = oath.steps[step_index]
		choices["[step_index]. [oath_step.name] ([oath_step.sealed ? "скреплён" : "не скреплён"])"] = step_index
	var/choice = tgui_input_list(admin, "Какой шаг клятвы «[oath.name]» скрепить или снять?", "Кровные братья", choices)
	var/step_index = choices[choice]
	if(!step_index || QDELETED(src) || team.oath != oath)
		return
	admin_flip_step(admin, step_index)

/// Ступень связи после переключения - по числу печатей; после исполненной клятвы она уже высшая
/datum/antagonist/brother/proc/admin_flip_step(mob/admin, step_index)
	var/datum/blood_oath/oath = team.oath
	if(!oath || step_index < 1 || step_index > length(oath.steps))
		return FALSE
	var/datum/blood_oath_step/flipped = oath.steps[step_index]
	flipped.sealed = !flipped.sealed
	flipped.sealed_by = flipped.sealed ? "администратор" : null
	team.set_bond_tier(length(team.fulfilled_oaths) ? BLOOD_BOND_TIER_MAX : oath.sealed_count())
	if(oath.current_step())
		team.clear_offers()
		for(var/datum/antagonist/brother/brother as anything in team.brother_antags())
			brother.refresh_bond_actions()
	else
		team.oath_fulfilled()
	admin_bond_changed()
	team.refresh_brother_uis(static_data = TRUE)
	message_admins("[key_name_admin(admin)] [flipped.sealed ? "скрепил" : "снял"] шаг [step_index] клятвы команды братьев [team.name].")
	log_admin("[key_name(admin)] [flipped.sealed ? "sealed" : "unsealed"] step [step_index] of the oath of blood brothers [team.name].")
	return TRUE

/datum/antagonist/brother/proc/admin_bond_changed()
	if(!team.has_stash_capstone())
		team.dump_stash()

/datum/antagonist/brother/proc/admin_restore_slots(mob/admin)
	team.third_oath_used = FALSE
	team.replacement_used = FALSE
	if(length(team.departed_minds))
		team.replacement_available = TRUE
	team.refresh_brother_uis()
	message_admins("[key_name_admin(admin)] вернул команде братьев [team.name] слоты клятвы третьего и замены.")
	log_admin("[key_name(admin)] restored recruit slots of blood brothers [team.name].")

/// Майндшилд или тело без крови глушат связь
/datum/antagonist/brother/proc/is_muted()
	var/mob/living/current = owner?.current
	return current && (HAS_TRAIT(current, TRAIT_MINDSHIELD) || issilicon(current))

/datum/antagonist/brother/proc/mute_text()
	return issilicon(owner?.current) ? "в этом теле нет крови для клятвы" : "имплант давит на шрам"

/datum/antagonist/brother/proc/hud_state_for(mob/living/body)
	return (HAS_TRAIT(body, TRAIT_MINDSHIELD) || issilicon(body)) ? "blood_brother_muted" : antag_hud_name

/datum/antagonist/brother/proc/on_mindshield_trait(mob/living/source)
	SIGNAL_HANDLER
	set_antag_hud(source, hud_state_for(source))
	on_mute_changed()

/datum/antagonist/brother/proc/on_examine(mob/living/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	if(!blood_oath_palm_organic(source) || source.get_item_by_slot(ITEM_SLOT_GLOVES) || (ITEM_SLOT_GLOVES in source.check_obscured_slots()))
		return
	examine_list += span_warning("Поперёк [source.ru_ego()] ладони тянется шрам от глубокого пореза.")

/// Удаление тела закрывает Схрон; из nullspace так уходит крио, не дожидаясь проверки команды
/datum/antagonist/brother/proc/on_body_deleted(mob/living/source)
	SIGNAL_HANDLER
	if(!team || owner.current != source)
		return
	team.close_stash(source)
	if(!source.loc)
		team.handle_departure(owner, BROTHER_DEPARTURE_CRYO)

/datum/antagonist/brother/proc/on_stat_change(datum/source, new_stat, old_stat)
	SIGNAL_HANDLER
	if(new_stat == DEAD)
		SEND_SIGNAL(team, COMSIG_BROTHER_TEAM_BROTHER_DIED, owner)
		team.on_brother_died(owner)
	else if(old_stat == DEAD)
		team.on_brother_revived(owner)

/datum/antagonist/brother/proc/brother_state()
	var/mob/living/current = owner.current
	if(QDELETED(current) || !current.loc || (owner in team.departed_minds))
		return BROTHER_STATE_GONE
	if(current.stat == DEAD)
		return BROTHER_STATE_DEAD
	if(is_muted())
		return BROTHER_STATE_MUTED
	if(current.stat != CONSCIOUS)
		return BROTHER_STATE_CRIT
	if(iscarbon(current))
		var/mob/living/carbon/carbon_current = current
		if(carbon_current.handcuffed)
			return BROTHER_STATE_CUFFED
	if(current.health < current.maxHealth * BROTHER_HURT_HEALTH_FRACTION)
		return BROTHER_STATE_HURT
	return BROTHER_STATE_OK

/// Выдать и снять способности связи по ступени и клятве команды
/datum/antagonist/brother/proc/refresh_bond_actions(mob/living/current = owner.current)
	if(!team)
		return
	var/list/needed = list()
	for(var/tier in 0 to team.bond_tier)
		var/list/tier_actions = GLOB.blood_bond_tier_actions["[tier]"]
		if(tier_actions)
			needed |= tier_actions
	for(var/capstone_type in team.earned_capstones())
		if(ispath(capstone_type, /datum/action/cooldown/blood_bond))
			needed |= capstone_type
	if(length(team.oath?.extra_actions))
		needed |= team.oath.extra_actions
	for(var/action_type in bond_actions)
		if(action_type in needed)
			continue
		var/datum/action/stale_action = bond_actions[action_type]
		bond_actions -= action_type
		qdel(stale_action)
	for(var/action_type in needed)
		var/datum/action/cooldown/blood_bond/bond_action = bond_actions[action_type]
		if(!bond_action)
			bond_action = new action_type(src)
			bond_action.brother = src
			bond_actions[action_type] = bond_action
		if(current && bond_action.owner != current)
			bond_action.Grant(current)
		bond_action.UpdateButtons()

/// Обновить Чутьё брата; зовётся из обработчиков сигналов и не спит
/datum/antagonist/brother/proc/update_sense()
	var/mob/living/current = owner.current
	if(!team || !isliving(current) || QDELETED(current))
		return
	var/list/wanted = list()
	if(!(owner in team.departed_minds))
		for(var/datum/antagonist/brother/other as anything in team.brother_antags())
			if(other != src && !(other.owner in team.departed_minds))
				wanted += other.owner
	for(var/datum/status_effect/brother_sense/sense as anything in current.has_status_effect_list(/datum/status_effect/brother_sense))
		if(sense.tracked in wanted)
			wanted -= sense.tracked
			sense.refresh()
		else
			qdel(sense)
	for(var/datum/mind/missing as anything in wanted)
		current.apply_status_effect(/datum/status_effect/brother_sense, missing)

/// Разбудить Ярость за брата; force - без учёта перезарядки
/datum/antagonist/brother/proc/trigger_fury(force = FALSE, play_sound = TRUE)
	var/mob/living/body = owner.current
	if(!isliving(body) || body.stat == DEAD || is_muted() || (!force && world.time < next_fury_at))
		return FALSE
	body.apply_status_effect(/datum/status_effect/brother_fury)
	next_fury_at = world.time + BROTHER_FURY_COOLDOWN * (team?.cooldown_multiplier || 1)
	if(play_sound)
		body.playsound_local(get_turf(body), 'modular_bluemoon/sound/blood_brothers/brother_fury.ogg', BROTHER_FURY_VOLUME, TRUE, pressure_affected = FALSE)
	return TRUE

/// Кому можно отдать кровь: брату своей команды или тому, кого разрешает клятва
/datum/antagonist/brother/proc/blood_for_blood_allows(mob/living/target)
	if(!team || !isliving(target) || target == owner.current)
		return FALSE
	var/datum/mind/target_mind = target.mind
	var/datum/antagonist/brother/target_brother = target_mind?.has_antag_datum(/datum/antagonist/brother)
	if(target_brother?.team == team && target_mind.current == target && !(target_mind in team.departed_minds))
		return TRUE
	return team.oath ? team.oath.allows_blood_for_blood(target) : FALSE

/// Майндшилд поставлен или снят, сменилось тело; зовётся из обработчика сигнала и не спит
/datum/antagonist/brother/proc/on_mute_changed()
	for(var/action_type in bond_actions)
		var/datum/action/bond_action = bond_actions[action_type]
		bond_action.UpdateButtons()
	var/datum/atom_hud/antag/brother/hud = GLOB.huds[ANTAG_HUD_BROTHER]
	hud.refresh_viewer(owner.current)
	if(!team)
		return
	var/muted = is_muted()
	if(muted)
		team.close_stash(owner.current)
		end_bond_effects()
	if(muted != bond_muted)
		bond_muted = muted
		announce_mute(muted)
	for(var/datum/antagonist/brother/brother as anything in team.brother_antags())
		brother.update_sense()

/datum/antagonist/brother/proc/announce_mute(muted)
	if(owner in team.departed_minds)
		return
	if(muted)
		to_chat(owner.current, span_boldwarning("Связь заглушена: [mute_text()]."))
		team.notify("Связь с [owner.name] заглушена.", skip = owner)
	else
		to_chat(owner.current, span_boldnotice("Связь вернулась."))
		team.notify("Связь с [owner.name] вернулась.", skip = owner)
