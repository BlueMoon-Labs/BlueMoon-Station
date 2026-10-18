/datum/antagonist/hk47
	var/datum/hk_terminal/terminal

/datum/antagonist/hk47/proc/grant_terminal(mob/living/body)
	if(!terminal)
		terminal = new(src)
	terminal.button.Grant(body)
	body.apply_status_effect(/datum/status_effect/hk47_tracker)

/datum/antagonist/hk47/proc/revoke_terminal(mob/living/body)
	if(terminal)
		SStgui.close_uis(terminal)
		terminal.button.Remove(body)
	body.remove_status_effect(/datum/status_effect/hk47_tracker)

/// Статус для станции, эскалация и эвакуация для терминала, словами HK.
/datum/antagonist/hk47/proc/terminal_status_data()
	var/mob/living/droid = owner?.current
	var/refusal = droid ? extraction_refusal(droid) : "шасси не отвечает."
	var/extraction_text = "Сигнал: [DisplayTimeText(HK47_EXTRACTION_TIME)] без движения у клетки с открытым космосом, затем капсула. Прерванный сигнал можно повторить через [DisplayTimeText(HK47_EXTRACTION_RETRY_COOLDOWN)]. Либо живым на эвакуационном шаттле вне брига."
	if(extracted)
		extraction_text = "Эвакуация выполнена. Работа на этой станции закрыта."
	else if(extracting)
		extraction_text = "Сигнал эвакуации идёт. Не двигайтесь."
	return list(
		"status_name" = hk47_status_name(status),
		"status_text" = status_voice(),
		"threat" = min(reveals, HK47_EXECUTE_REVEAL),
		"threat_max" = HK47_EXECUTE_REVEAL,
		"extraction_available" = !refusal,
		"extraction_reason" = refusal ? copytext_char(refusal, 1, -1) : null,
		"extraction_text" = extraction_text,
	)

/datum/antagonist/hk47/proc/status_voice()
	var/text
	switch(status)
		if(HK47_STATUS_COVERT)
			text = "станция обо мне не знает. Пусть так и остаётся."
		if(HK47_STATUS_LICENSED)
			text = "лицензия ЦК № [license_number] действительна. Убивать позволено только по контракту. Какая скука."
		if(HK47_STATUS_BODYGUARD)
			text = "частный телохранитель, контракт № [license_number]. Подопечный может за меня поручиться."
		if(HK47_STATUS_EXPIRED)
			text = "лицензия № [license_number] истекла вместе с контрактом. Станция меня помнит, но прикрытия больше нет."
		if(HK47_STATUS_OUTLAW)
			text = "я вне закона, СБ приказано меня задержать. Так даже честнее."
		if(HK47_STATUS_PARDONED)
			text = "ЦК закрыл мои дела и снял розыск. Станция обо мне помнит, но приказа на арест нет."
	if(reveals >= HK47_EXECUTE_REVEAL)
		text += " Теперь приказ - уничтожить."
	if(status != HK47_STATUS_OUTLAW)
		if(escalation_peak >= HK47_TRACKER_REVEAL)
			text += " Пеленгатор СБ молчит, пока я не в розыске."
	else if(escalation_peak >= HK47_EXECUTE_REVEAL)
		text += " У СБ пеленгатор моего сигнала, в бриге ионная винтовка и ЭМИ-гранаты, карго ищет моё ядро."
	else if(escalation_peak >= HK47_TRACKER_REVEAL)
		text += " У СБ пеленгатор моего сигнала, карго ищет моё ядро."
	else if(reveals)
		text += " Станции объявили о дроиде-ассасине."
	return text

/datum/antagonist/hk47/proc/suspect_pool(turf/center)
	return SSspatial_grid.orthogonal_range_search(center, SPATIAL_GRID_CONTENTS_TYPE_CLIENTS, HK47_IDENTIFY_RANGE)

/proc/hk47_history_comment(outcome, task_type, outcome_text)
	if(outcome_text)
		return "Комментарий: заказ остался незакрытым, [outcome_text]. Пусть заказчик ищет другого HK."
	switch(outcome)
		if(HK_CONTRACT_FAILED)
			return "Комментарий: досадный сбой. Органики поразительно хрупки именно тогда, когда это неудобно."
		if(HK_CONTRACT_REFUSED)
			return "Комментарий: этот заказ был ниже моего достоинства, хозяин."
		if(HK_CONTRACT_DROPPED)
			return "Комментарий: цель исчезла раньше, чем я до неё добрался. Неспортивно."
	if(ispath(task_type, /datum/hk_contract_task/kill))
		return "Комментарий: мешок с мясом больше не дышит. Заказчик доволен, я тоже."
	if(ispath(task_type, /datum/hk_contract_task/capture))
		return "Комментарий: груз доставлен живым. Почти жаль."
	if(ispath(task_type, /datum/hk_contract_task/theft))
		return "Комментарий: трофей у заказчика. Прежний владелец ещё не заметил пропажи."
	if(ispath(task_type, /datum/hk_contract_task/sabotage))
		return "Комментарий: машина замолчала. Ремонтникам хватит работы до конца смены."
	if(ispath(task_type, /datum/hk_contract_task/protect))
		return "Комментарий: подопечный всё ещё дышит. Не самая любимая моя работа."
	if(ispath(task_type, /datum/hk_contract_task/hunt))
		return "Комментарий: охотник стал добычей. Изящно, не правда ли, хозяин?"
	return "Комментарий: работа выполнена."

/// Встроенный контрактный терминал HK-47: окно HKContractTerminal.
/datum/hk_terminal
	var/datum/antagonist/hk47/hunter
	var/datum/action/innate/hk_terminal/button
	/// Какие снимки ушли в static data последними; при смене досье static data отправляется заново.
	var/sent_photos_key

/datum/hk_terminal/New(datum/antagonist/hk47/hunter)
	. = ..()
	src.hunter = hunter
	button = new(src)
	RegisterSignal(hunter, COMSIG_PARENT_QDELETING, PROC_REF(on_hunter_deleted))

/datum/hk_terminal/Destroy()
	SStgui.close_uis(src)
	QDEL_NULL(button)
	if(hunter)
		UnregisterSignal(hunter, COMSIG_PARENT_QDELETING)
		if(hunter.terminal == src)
			hunter.terminal = null
	hunter = null
	return ..()

/datum/hk_terminal/proc/on_hunter_deleted(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/datum/hk_terminal/ui_state(mob/user)
	return GLOB.conscious_state

/datum/hk_terminal/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "HKContractTerminal", "HK-47")
		ui.open()

/datum/hk_terminal/ui_static_data(mob/user)
	var/list/catalog = list()
	for(var/upgrade_id in GLOB.hk47_upgrades)
		var/datum/hk47_upgrade/upgrade = GLOB.hk47_upgrades[upgrade_id]
		catalog += list(list(
			"id" = upgrade.id,
			"name" = upgrade.name,
			"summary" = upgrade.summary(),
			"specs" = upgrade.specs(),
			"price_curve" = length(upgrade.price_curve) ? upgrade.price_curve_text() : null,
			"repeatable" = upgrade.repeatable,
		))
	sent_photos_key = photos_key()
	return list(
		"catalog" = catalog,
		"contracts_needed" = HK47_CONTRACTS_TO_WIN,
		"charge_max" = NUTRITION_LEVEL_WELL_FED,
		"rifle_max" = HK_RIFLE_SHOTS,
		"identify_range" = HK47_IDENTIFY_RANGE,
		"protect_presence_needed" = HK47_PROTECT_PRESENCE_PERCENT,
		"photos" = collect_photos(),
	)

/datum/hk_terminal/ui_data(mob/user)
	var/list/data = list()
	if(QDELETED(hunter) || !hunter.owner)
		return data
	hunter.ensure_offers()
	var/mob/living/carbon/human/droid = hunter.owner.current
	data["points"] = hunter.points
	data["contracts_done"] = hunter.contracts_done
	data["charge"] = round(droid?.nutrition)
	var/obj/item/gun/energy/hk_rifle/rifle = hk47_find_rifle(droid)
	data["rifle"] = rifle ? list(
		"shots" = round(rifle.cell.charge / HK_RIFLE_SHOT_COST),
		"sniper" = rifle.sniper_unlocked,
		"sniper_mode" = rifle.sniper_selected(),
		"sniper_cooldown" = round(COOLDOWN_TIMELEFT(rifle, sniper_cooldown) / (1 SECONDS)),
		"stun_mode" = rifle.stun_selected(),
	) : null
	var/datum/component/hk47_shield/shield = droid?.GetComponent(/datum/component/hk47_shield)
	data["shield"] = shield ? list(
		"active" = shield.active,
		"cooldown" = round(COOLDOWN_TIMELEFT(shield, recharge) / (1 SECONDS)),
	) : null
	data["reroll_cooldown"] = round(COOLDOWN_TIMELEFT(hunter, reroll_cooldown) / (1 SECONDS))
	data["identify_cooldown"] = round(COOLDOWN_TIMELEFT(hunter, identify_cooldown) / (1 SECONDS))
	data["scanning"] = hunter.scanning
	var/list/offers = list()
	for(var/datum/hk_contract/offer as anything in hunter.offers)
		offers += list(contract_data(offer))
	data["offers"] = offers
	data["active"] = hunter.active_contract ? active_data(hunter.active_contract, droid) : null
	var/list/upgrades = list()
	for(var/upgrade_id in GLOB.hk47_upgrades)
		var/datum/hk47_upgrade/upgrade = GLOB.hk47_upgrades[upgrade_id]
		var/reason = upgrade.refusal(hunter)
		upgrades += list(list(
			"id" = upgrade_id,
			"cost" = upgrade.price(hunter),
			"owned" = hunter.upgrades[upgrade_id] || 0,
			"available" = !reason,
			"reason" = reason,
			"status" = upgrade.status_text(hunter),
		))
	data["upgrades"] = upgrades
	var/list/history = list()
	var/list/tallies = list("killed" = 0, "captured" = 0, "stolen" = 0, "sabotaged" = 0)
	for(var/list/entry as anything in hunter.contract_history)
		var/task_type = entry["task"]
		history += list(list(
			"contract" = entry["contract"],
			"outcome" = entry["outcome"],
			"kind" = replacetext("[task_type]", "[/datum/hk_contract_task]/", ""),
			"points" = entry["points"],
			"comment" = hk47_history_comment(entry["outcome"], task_type, entry["outcome_text"]),
		))
		if(entry["outcome"] != HK_CONTRACT_DONE)
			continue
		if(entry["killed"])
			tallies["killed"]++
		else if(ispath(task_type, /datum/hk_contract_task/capture) || ispath(task_type, /datum/hk_contract_task/hunt))
			tallies["captured"]++
		else if(ispath(task_type, /datum/hk_contract_task/theft))
			tallies["stolen"]++
		else if(ispath(task_type, /datum/hk_contract_task/sabotage))
			tallies["sabotaged"]++
	data["history"] = history
	data["tallies"] = tallies
	var/list/last_entry = length(hunter.contract_history) ? hunter.contract_history[length(hunter.contract_history)] : null
	data["ticker"] = last_entry ? hk47_history_comment(last_entry["outcome"], last_entry["task"], last_entry["outcome_text"]) : "Приветствие: контрактный терминал HK-47 к вашим услугам, хозяин. Мешки с мясом ждут."
	var/list/station = hunter.terminal_status_data()
	data["station"] = length(station) ? station : null
	data["extraction_ready"] = hunter.contracts_done >= HK47_CONTRACTS_TO_WIN
	if(photos_key() != sent_photos_key)
		addtimer(CALLBACK(src, TYPE_PROC_REF(/datum, update_static_data_for_all_viewers)), 0, TIMER_UNIQUE | TIMER_DELETE_ME)
	return data

/// Досье в окне: предложения и активный контракт.
/datum/hk_terminal/proc/shown_contracts()
	. = hunter.offers.Copy()
	if(hunter.active_contract)
		. += hunter.active_contract

/// Номера досье, у которых есть снимок; засекреченная цель охоты появляется здесь только после опознания.
/datum/hk_terminal/proc/photos_key()
	if(QDELETED(hunter))
		return ""
	var/list/ids = list()
	for(var/datum/hk_contract/contract as anything in shown_contracts())
		if(contract.trackable())
			ids += "[contract.id]"
	return jointext(ids, ",")

/// Номер досье -> снимок цели; getFlatIcon дорогой, поэтому снимок один на контракт и только в static data.
/datum/hk_terminal/proc/collect_photos()
	var/list/photos = list()
	if(QDELETED(hunter))
		return photos
	for(var/datum/hk_contract/contract as anything in shown_contracts())
		if(!contract.trackable())
			continue
		if(!contract.photo_taken)
			contract.photo_taken = TRUE
			var/atom/pictured = contract.tracked_atom()
			var/icon/flat = pictured ? getFlatIcon(pictured, defdir = SOUTH, no_anim = TRUE) : null
			contract.photo = flat ? icon2base64(flat) : null
		if(contract.photo)
			photos["[contract.id]"] = contract.photo
	return photos

/datum/hk_terminal/proc/contract_data(datum/hk_contract/contract)
	return list(
		"ref" = REF(contract),
		"id" = "[contract.id]",
		"client" = contract.client_name(),
		"client_flavor" = contract.client_info("flavor"),
		"client_bonus" = contract.client_bonus(),
		"perk" = contract.client_info("perk"),
		"dirty" = hunter.contract_is_dirty(contract),
		"task" = contract.task.name,
		"kind" = replacetext("[contract.task.type]", "[/datum/hk_contract_task]/", ""),
		"hunt" = contract.is_hunt(),
		"identified" = contract.identified,
		"target" = contract.display_target(),
		"rules" = contract.task.rules_text(contract),
		"modifier" = contract.modifier?.name,
		"modifier_rules" = contract.modifier?.rules_text(),
		"points" = contract.points(),
		"bonus" = contract.modifier ? HK47_MODIFIER_POINTS : 0,
		"lethal" = contract.lethal,
		"unavailable" = contract.shown_unavailable_reason(contract.state == HK_CONTRACT_OFFERED ? contract.offer_unavailable_reason() : contract.target_unavailable_reason()),
	)

/datum/hk_terminal/proc/active_data(datum/hk_contract/contract, mob/living/droid)
	var/list/entry = contract_data(contract)
	var/deadline = contract.deadline()
	entry["deadline"] = deadline ? max(0, round((deadline - world.time) / (1 SECONDS))) : null
	entry["deadline_kind"] = istype(contract.task, /datum/hk_contract_task/protect) ? "protect" : "urgent"
	if(!contract.trackable())
		entry["trace"] = list(
			"area" = contract.trace_area,
			"minutes" = isnull(contract.trace_time) ? null : round(contract.trace_age() / (1 MINUTES)),
			"cold" = contract.trace_cold(),
			"near" = contract.target_near(),
		)
	entry["can_scan"] = contract.task.scannable(contract)
	entry["can_capture"] = contract.task.capturable
	entry["capture_called"] = contract.capture_called
	entry["radar"] = contract.radar_reading(droid)
	entry["suspects"] = contract.trackable() ? list() : suspects(droid)
	if(istype(contract.task, /datum/hk_contract_task/protect))
		entry["presence"] = contract.presence_percent()
	return entry

/// Игроки в паре клеток от HK, которых он видит, для опознания: имя видно и так, цель среди них не отмечена.
/datum/hk_terminal/proc/suspects(mob/living/droid)
	. = list()
	var/turf/center = get_turf(droid)
	if(!center)
		return
	for(var/mob/living/carbon/human/suspect in hunter.suspect_pool(center))
		if(suspect == droid || suspect.stat == DEAD || hunter.is_hk_side(suspect) || get_dist(center, suspect) > HK47_IDENTIFY_RANGE)
			continue
		if(!hunter.can_identify(droid, suspect))
			continue
		. += list(list("ref" = REF(suspect), "name" = suspect.name))

/datum/hk_terminal/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(. || QDELETED(hunter) || !hunter.owner?.current || ui?.user != hunter.owner.current)
		return
	switch(action)
		if("accept")
			var/datum/hk_contract/offer = locate(params["ref"]) in hunter.offers
			if(offer)
				hunter.accept(offer)
			return TRUE
		if("reroll")
			hunter.reroll(TRUE)
			return TRUE
		if("replace")
			hunter.reroll(FALSE)
			return TRUE
		if("scan")
			INVOKE_ASYNC(hunter, TYPE_PROC_REF(/datum/antagonist/hk47, try_scan))
			return TRUE
		if("capture")
			hunter.try_capture(hunter.active_contract?.target_body())
			return TRUE
		if("identify")
			var/mob/living/suspect = locate(params["ref"])
			if(isliving(suspect))
				hunter.try_identify(suspect)
			return TRUE
		if("buy")
			var/upgrade_id = params["id"]
			if(istext(upgrade_id))
				hunter.buy_upgrade(upgrade_id)
			return TRUE
		if("extract")
			INVOKE_ASYNC(hunter, TYPE_PROC_REF(/datum/antagonist/hk47, request_extraction))
			return TRUE

/datum/action/innate/hk_terminal
	name = "HK Contract Terminal"
	desc = "Встроенный контрактный терминал: предложения заказчиков, активный контракт, модернизация шасси и журнал."
	icon_icon = 'icons/obj/device.dmi'
	button_icon_state = "gangtool-syndie"
	background_icon_state = "bg_tech"

/datum/action/innate/hk_terminal/Activate()
	var/datum/hk_terminal/terminal = target
	terminal.ui_interact(owner)
