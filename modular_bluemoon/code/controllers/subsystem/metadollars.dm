SUBSYSTEM_DEF(metadollars)
	name = "Metadollars"
	flags = SS_NO_FIRE
	var/list/round_earnings = list()
	var/metadollar_burn_round_notice = null

/datum/controller/subsystem/metadollars/Initialize()
	. = ..()
	RegisterSignal(SSticker, COMSIG_TICKER_ROUND_STARTING, PROC_REF(round_begin_reset))
	return SS_INIT_SUCCESS

/datum/controller/subsystem/metadollars/proc/round_begin_reset()
	SIGNAL_HANDLER
	round_earnings = list()
	metadollar_burn_round_notice = null

/proc/metadollar_living_multiplier(mob/living/L)
	if(!L?.mind)
		return 1
	var/datum/mind/M = L.mind
	if(M.assigned_role && (M.assigned_role in GLOB.command_positions))
		return 2
	return 1

/datum/controller/subsystem/metadollars/proc/on_living_tick(client/C, minutes)
	if(!C?.ckey || !C.prefs || minutes <= 0)
		return
	if(!isliving(C.mob) || C.mob.stat == DEAD)
		return
	// Только персонаж под управлением этого клиента (не NPC / не чужое тело без привязки).
	if(C.mob.key != C.ckey)
		return
	var/mult = metadollar_living_multiplier(C.mob)
	var/old_living = 0
	if(C.prefs.exp)
		old_living = text2num(C.prefs.exp[EXP_TYPE_LIVING])
	var/newbie_mult = (old_living < 6000) ? 2 : 1
	C.prefs.metadollar_minute_pool += minutes * mult * newbie_mult
	var/granted = 0
	while(C.prefs.metadollar_minute_pool >= 60)
		C.prefs.metadollar_minute_pool -= 60
		granted++
	if(!granted)
		return
	add_amount(C, granted, "living")

/datum/controller/subsystem/metadollars/proc/add_amount(client/C, amount, category)
	if(!istype(C, /client) || !C.ckey || !C.prefs || amount <= 0)
		return
	C.prefs.metadollars += amount
	var/ck = C.ckey
	LAZYINITLIST(round_earnings[ck])
	if(!round_earnings[ck][category])
		round_earnings[ck][category] = 0
	round_earnings[ck][category] += amount
	round_earnings[ck]["total"] = (round_earnings[ck]["total"] || 0) + amount
	C.prefs.save_preferences()
	if(category == "living" && isliving(C.mob))
		to_chat(C.mob, span_purple("Вы получили [amount] М$ за работу."))
		SEND_SOUND(C.mob, sound('sound/machines/terminal_success.ogg', volume = 35))

/// Сколько целей смены выполнено (для бонуса ЦК и отчёта).
/datum/controller/subsystem/metadollars/proc/count_completed_station_goals()
	. = 0
	if(!SSticker?.mode?.station_goals?.len)
		return
	for(var/datum/station_goal/G in SSticker.mode.station_goals)
		if(G.check_completion())
			.++

/// М$ всем выжившим на ЦК за выполненные цели смены (0, если целей нет).
/datum/controller/subsystem/metadollars/proc/cc_station_goals_metadollars(completed_goals)
	if(completed_goals > 0)
		return 2 * completed_goals
	return 0

/// Полная выплата за ЦК для моба: цели смены + надбавка за роль (как metadollar_living_multiplier: 2 — командование, 1 — остальные).
/datum/controller/subsystem/metadollars/proc/cc_total_payout_for_mob(mob/M, completed_goals)
	var/goals_part = cc_station_goals_metadollars(completed_goals)
	var/role_part = isliving(M) ? metadollar_living_multiplier(M) : 1
	return goals_part + role_part

/// Потенциальная выплата за выполненные цели антагониста (2 М$ за цель), по данным разума.
/datum/controller/subsystem/metadollars/proc/potential_antag_metadollars(datum/mind/M)
	. = 0
	if(!M)
		return
	for(var/datum/antagonist/A in GLOB.antagonists)
		if(A.owner != M)
			continue
		if(!A.objectives.len)
			continue
		for(var/datum/objective/O in A.objectives)
			if(O.check_completion())
				. += 2

/datum/controller/subsystem/metadollars/proc/apply_round_end_rewards()
	var/completed_station_goals = count_completed_station_goals()

	for(var/ckey in GLOB.joined_player_list)
		var/client/C = GLOB.directory[ckey]
		if(!C?.prefs)
			continue
		var/mob/M = C.mob
		if(!M?.mind)
			continue
		if(EMERGENCY_ESCAPED_OR_ENDGAMED && M.stat != DEAD && !isbrain(M) && M.onCentCom())
			add_amount(C, cc_total_payout_for_mob(M, completed_station_goals), "cc")

	for(var/datum/antagonist/A in GLOB.antagonists)
		if(!A.owner)
			continue
		var/client/C = GLOB.directory[ckey(A.owner.key)]
		if(!C?.prefs)
			continue
		if(!A.objectives.len)
			continue
		for(var/datum/objective/O in A.objectives)
			if(O.check_completion())
				add_amount(C, 2, "antag")

/// Блок HTML: почему игрок недополучил бонус ЦК / антага (после apply_round_end_rewards).
/datum/controller/subsystem/metadollars/proc/metadollar_roundend_missed_html(client/C, mob/M, list/E)
	if(!C?.prefs || !M?.mind || isnewplayer(M))
		return ""
	var/list/missed = list()
	var/completed_goals = count_completed_station_goals()
	var/cc_pay = cc_total_payout_for_mob(M, completed_goals)
	var/goals_part = cc_station_goals_metadollars(completed_goals)
	var/got_cc = E["cc"] || 0
	var/esc_ok = EMERGENCY_ESCAPED_OR_ENDGAMED

	if(esc_ok)
		var/missed_cc = max(0, cc_pay - got_cc)
		if(missed_cc > 0)
			var/list/reasons = list()
			if(!(C.ckey in GLOB.joined_player_list))
				reasons += "вы не входили в список экипажа этого раунда"
			if(M.stat == DEAD || isbrain(M))
				reasons += "персонаж не жив или остался только мозг"
			else if(!M.onCentCom())
				reasons += "персонаж не на площадке Центрального Командования в конце раунда"
			if(length(reasons))
				missed += "Недополучено <b>[missed_cc] М$</b> за эвакуацию на ЦК (из <b>[cc_pay] М$</b> для вашей роли: цели смены + надбавка по роли 1–2 М$). Причина: [reasons.Join("; ")]."
			else
				missed += "Недополучено <b>[missed_cc] М$</b> за эвакуацию на ЦК при том, что условия, казалось бы, выполнены — если это ошибка, сообщите администрации."
	else if(!esc_ok)
		if(completed_goals > 0)
			var/cc_min = goals_part + 1
			var/cc_max = goals_part + 2
			missed += "Бонус за ЦК (цели смены + 1–2 М$ по роли: командование — 2; остальные — 1), всего от <b>[cc_min]</b> до <b>[cc_max] М$</b>, <b>не начислялся</b>: эвакуация не в режиме успешного побега (шаттл не ушёл как «побег» / не конец игры по эвакуации)."
		else if(M.stat != DEAD && !isbrain(M) && M.onCentCom())
			var/role_only = isliving(M) ? metadollar_living_multiplier(M) : 1
			missed += "Бонус <b>[role_only] М$</b> за прибытие живым на ЦК (по роли: командование — 2; остальные — 1) <b>не начислён</b>: эвакуация не в режиме успешного побега, поэтому выплата не производилась."

	var/potential_antag = potential_antag_metadollars(M.mind)
	var/got_antag = E["antag"] || 0
	var/missed_antag = max(0, potential_antag - got_antag)
	if(missed_antag > 0)
		missed += "Недополучено <b>[missed_antag] М$</b> за выполненные цели антагониста (ожидалось до <b>[potential_antag] М$</b>; начислено <b>[got_antag] М$</b>)."

	if(!length(missed))
		return ""
	return "<div class='panel clockborder'><span class='header'>Метадоллары: недополучено</span><br><small>[missed.Join("<br>")]</small></div>"

/datum/controller/subsystem/metadollars/proc/personal_roundend_html(client/C)
	if(!C?.ckey)
		return ""
	var/list/chunks = list()
	if(metadollar_burn_round_notice)
		chunks += "<div class='panel redborder'><span class='header'>Сжигание метадолларов</span><br>[html_encode(metadollar_burn_round_notice)]</div>"
	var/list/E = round_earnings[C.ckey]
	if(!E)
		E = list()
	var/total = E["total"] || 0
	if(total > 0)
		var/list/lines = list()
		if(E["living"])
			lines += "За время на станции: <b>[E["living"]]</b> М$"
		if(E["cc"])
			lines += "Эвакуация на ЦК (цели смены + роль): <b>[E["cc"]]</b> М$"
		if(E["antag"])
			lines += "Цели антагониста: <b>[E["antag"]]</b> М$"
		if(E["voucher"])
			lines += "Получено обменом: <b>[E["voucher"]]</b> М$"
		chunks += "<div class='panel stationborder'><span class='header'>Метадоллары за раунд</span><br>Всего начислено: <b>[total] М$</b>.<br><small>[lines.Join("<br>")]</small><br>Текущий баланс: <b>[C.prefs.metadollars] М$</b>.</div>"
	var/missed_block = metadollar_roundend_missed_html(C, C.mob, E)
	if(missed_block)
		if(total <= 0 && C.prefs)
			missed_block += "<br><small>Текущий баланс: <b>[C.prefs.metadollars] М$</b>.</small>"
		chunks += missed_block
	if(!length(chunks))
		return ""
	return chunks.Join("")

/proc/bm_metadollar_global_burn(mob/initiator)
	if(SSmetadollars)
		SSmetadollars.round_earnings = list()
	if(!fexists("data/player_saves"))
		return
	var/notice = "В этом раунде активирован протокол «Пепелище»: обнулены все метадолларовые балансы."
	if(initiator)
		notice += " Инициатор: [initiator.real_name] ([initiator.ckey])."
	if(SSmetadollars)
		SSmetadollars.metadollar_burn_round_notice = notice
	var/list/done = list()
	for(var/letterdir in flist("data/player_saves/"))
		var/prefix = "data/player_saves/[letterdir]"
		if(!fexists(prefix))
			continue
		for(var/sub in flist(prefix))
			var/sav = "[prefix]/[sub]/preferences.sav"
			if(!fexists(sav))
				continue
			var/ck = ckey(sub)
			if(!ck || done[ck])
				continue
			done[ck] = TRUE
			var/client/online = GLOB.directory[ck]
			if(online?.prefs)
				online.prefs.metadollars = 0
				online.prefs.save_preferences(TRUE, TRUE)
				continue
			var/datum/preferences/P = new
			P.load_path(ck)
			if(!P.load_preferences(TRUE))
				qdel(P)
				continue
			P.metadollars = 0
			P.save_preferences(TRUE, TRUE)
			qdel(P)

/proc/bm_deliver_metadollar_purchases(mob/living/carbon/human/H, client/C)
	if(!H || !C?.prefs)
		return
	if(!LAZYLEN(C.prefs.metadollar_pending_items))
		return
	var/obj/item/storage/backpack = H.get_item_by_slot(ITEM_SLOT_BACK)
	var/did_any = FALSE
	for(var/path_text in C.prefs.metadollar_pending_items)
		var/path = text2path(path_text)
		if(!ispath(path, /obj/item))
			continue
		var/turf/T = get_turf(H)
		var/list/before_on_turf = list()
		for(var/obj/item/pre_existing in T)
			before_on_turf[pre_existing] = TRUE
		var/obj/item/I = new path(T)
		if(QDELETED(I))
			for(var/obj/item/candidate in T)
				if(before_on_turf[candidate] || QDELETED(candidate))
					continue
				I = candidate
				break
		if(QDELETED(I) || !istype(I, /obj/item))
			continue
		did_any = TRUE
		if(istype(backpack))
			if(!SEND_SIGNAL(backpack, COMSIG_TRY_STORAGE_INSERT, I, null, TRUE, TRUE))
				if(!H.put_in_hands(I))
					I.forceMove(get_turf(H))
		else if(!H.put_in_hands(I))
			I.forceMove(get_turf(H))
	if(did_any)
		C.prefs.metadollar_pending_items.Cut()
		C.prefs.save_preferences()
		to_chat(H, span_notice("В рюкзаке оказались предметы, заказанные в метамагазине."))
