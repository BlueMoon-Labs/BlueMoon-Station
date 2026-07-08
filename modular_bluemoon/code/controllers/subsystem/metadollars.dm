#define METASHOP_TRAITOR_TOKEN_ROUND_LIMIT 3
#define METASHOP_TRAITOR_TOKEN_REFUND_COST 250
#define METASHOP_ANTAG_TOKEN_TRAITOR_LIMIT_KEY "traitor_token"

SUBSYSTEM_DEF(metadollars)
	name = "Metadollars"
	flags = SS_NO_FIRE
	var/list/round_earnings = list()
	var/metadollar_burn_round_notice = null
	var/list/metadollar_amount_cache = list()
	var/list/metadollar_leaderboard = list()
	var/metadollar_leaderboard_positions_tracked = 5
	var/list/metashop_round_limited_purchases = list()

/proc/bm_metadollar_json_path(target_ckey)
	return "data/player_saves/[target_ckey[1]]/[target_ckey]/metadollars.json"

/proc/bm_ckey_from_prefs_path(prefs_path)
	if(!prefs_path)
		return null
	var/list/parts = splittext(prefs_path, "/")
	if(parts.len < 2)
		return null
	return parts[parts.len - 1]

/datum/controller/subsystem/metadollars/Initialize()
	. = ..()
	prep_metadollar_leaderboard()
	var/recovered = recover_all_legacy_balances()
	if(recovered)
		log_world("Metadollars: restored legacy balances for [recovered] player(s) from preferences.sav backups.")
	RegisterSignal(SSticker, COMSIG_TICKER_ROUND_STARTING, PROC_REF(round_begin_reset))
	return SS_INIT_SUCCESS

/datum/controller/subsystem/metadollars/proc/round_begin_reset()
	SIGNAL_HANDLER
	round_earnings = list()
	metadollar_burn_round_notice = null
	metashop_round_limited_purchases = list()

/datum/controller/subsystem/metadollars/proc/get_round_limited_purchase_count(limit_key)
	if(!limit_key)
		return 0
	return metashop_round_limited_purchases[limit_key] || 0

/datum/controller/subsystem/metadollars/proc/get_round_limited_purchase_remaining(limit_key, limit_amount)
	if(!limit_key || limit_amount <= 0)
		return 0
	return max(0, limit_amount - get_round_limited_purchase_count(limit_key))

/datum/controller/subsystem/metadollars/proc/can_purchase_round_limited_item(limit_key, limit_amount)
	if(!limit_key || limit_amount <= 0)
		return TRUE
	return get_round_limited_purchase_count(limit_key) < limit_amount

/datum/controller/subsystem/metadollars/proc/register_round_limited_purchase(limit_key)
	if(!limit_key)
		return
	metashop_round_limited_purchases[limit_key] = get_round_limited_purchase_count(limit_key) + 1

/datum/controller/subsystem/metadollars/proc/unregister_round_limited_purchase(limit_key)
	if(!limit_key)
		return
	var/current_count = get_round_limited_purchase_count(limit_key)
	if(current_count <= 0)
		return
	current_count--
	if(current_count)
		metashop_round_limited_purchases[limit_key] = current_count
	else
		metashop_round_limited_purchases -= limit_key

/datum/controller/subsystem/metadollars/proc/metadollar_save(target_ckey)
	if(!target_ckey || !(target_ckey in metadollar_amount_cache))
		return
	var/list/saving_data = list("metadollar_count" = metadollar_amount_cache[target_ckey])
	var/target_file = file(bm_metadollar_json_path(target_ckey))
	var/backup_file = file("[bm_metadollar_json_path(target_ckey)].backup")
	if(fexists(backup_file))
		fdel(backup_file)
	WRITE_FILE(backup_file, json_encode(saving_data))
	fcopy("[backup_file]", "[target_file]")
	fdel(backup_file)

/proc/bm_read_metadollars_from_savefile_path(prefs_path)
	if(!prefs_path || !fexists(prefs_path))
		return 0
	var/savefile/S = new(prefs_path)
	var/amount = 0
	S["metadollars"] >> amount
	return isnum(amount) ? max(0, round(amount)) : 0

/proc/bm_read_legacy_metadollars_from_prefs_sav(target_ckey)
	if(!target_ckey)
		return 0
	var/base = "data/player_saves/[target_ckey[1]]/[target_ckey]"
	var/best = 0
	for(var/suffix in list("/preferences.sav", "/preferences.sav.updatebac"))
		best = max(best, bm_read_metadollars_from_savefile_path("[base][suffix]"))
	return best

/datum/controller/subsystem/metadollars/proc/reconcile_legacy_balance(target_ckey, legacy_hint = null)
	if(!target_ckey)
		return FALSE
	// metadollars.json — единственный источник правды после миграции; TGS set/add/remove пишет сюда.
	// Иначе старый ключ metadollars в preferences.sav перезаписывает админские правки.
	if(fexists(bm_metadollar_json_path(target_ckey)))
		return FALSE
	var/legacy = legacy_hint
	if(!isnum(legacy) || legacy < 0)
		legacy = bm_read_legacy_metadollars_from_prefs_sav(target_ckey)
	legacy = max(0, round(legacy))
	if(legacy <= 0)
		return FALSE
	var/current = 0
	if(target_ckey in metadollar_amount_cache)
		current = metadollar_amount_cache[target_ckey]
	else if(fexists(bm_metadollar_json_path(target_ckey)))
		var/list/loaded = json_decode(file2text(file(bm_metadollar_json_path(target_ckey))))
		if(islist(loaded) && isnum(loaded["metadollar_count"]))
			current = max(0, round(loaded["metadollar_count"]))
	if(legacy <= current)
		return FALSE
	metadollar_amount_cache[target_ckey] = legacy
	metadollar_save(target_ckey)
	log_game("Metadollars: restored [legacy] M$ for [target_ckey] (was [current] M$).")
	return TRUE

/datum/controller/subsystem/metadollars/proc/recover_all_legacy_balances()
	if(!fexists("data/player_saves"))
		return 0
	var/recovered = 0
	for(var/letterdir in flist("data/player_saves/"))
		var/prefix = "data/player_saves/[letterdir]"
		if(!fexists(prefix))
			continue
		for(var/sub in flist(prefix))
			var/ck = ckey(sub)
			if(!ck)
				continue
			if(reconcile_legacy_balance(ck))
				recovered++
	return recovered

/datum/controller/subsystem/metadollars/proc/import_legacy_balance(target_ckey, amount)
	reconcile_legacy_balance(target_ckey, amount)

/datum/controller/subsystem/metadollars/proc/get_metadollars(target_ckey)
	if(!target_ckey)
		return 0
	if(target_ckey in metadollar_amount_cache)
		return metadollar_amount_cache[target_ckey]
	var/json_path = bm_metadollar_json_path(target_ckey)
	var/target_file = file(json_path)
	var/amount = 0
	if(fexists(target_file))
		var/list/loaded = json_decode(file2text(target_file))
		if(islist(loaded) && isnum(loaded["metadollar_count"]))
			amount = max(0, round(loaded["metadollar_count"]))
		metadollar_amount_cache[target_ckey] = amount
		return amount
	amount = bm_read_legacy_metadollars_from_prefs_sav(target_ckey)
	reconcile_legacy_balance(target_ckey, amount)
	if(target_ckey in metadollar_amount_cache)
		return metadollar_amount_cache[target_ckey]
	metadollar_amount_cache[target_ckey] = amount
	metadollar_save(target_ckey)
	return amount

/datum/controller/subsystem/metadollars/proc/set_metadollars(target_ckey, amount, client_key = null)
	if(!target_ckey)
		return
	get_metadollars(target_ckey)
	metadollar_amount_cache[target_ckey] = max(0, round(amount))
	metadollar_save(target_ckey)
	if(!client_key)
		var/client/C = GLOB.directory[target_ckey]
		client_key = C?.key
	if(client_key)
		adjust_leaderboard(client_key)

/datum/controller/subsystem/metadollars/proc/metadollar_adjust(amt, target_ckey, client_key = null)
	if(!target_ckey || !amt)
		return
	get_metadollars(target_ckey)
	metadollar_amount_cache[target_ckey] = max(0, round(metadollar_amount_cache[target_ckey] + amt))
	metadollar_save(target_ckey)
	var/display_key = client_key
	if(!display_key)
		var/client/C = GLOB.directory[target_ckey]
		display_key = C?.key
	if(display_key)
		adjust_leaderboard(display_key)

/datum/controller/subsystem/metadollars/proc/prep_metadollar_leaderboard()
	var/json_file = file("data/metadollar_leaderboard.json")
	if(!fexists(json_file))
		return
	metadollar_leaderboard = json_decode(file2text(json_file))
	sort_metadollar_leaderboard()

/datum/controller/subsystem/metadollars/proc/save_metadollar_leaderboard()
	var/leaderboard_file = file("data/metadollar_leaderboard.json")
	if(fexists(leaderboard_file))
		fdel(leaderboard_file)
	WRITE_FILE(leaderboard_file, json_encode(metadollar_leaderboard))

/datum/controller/subsystem/metadollars/proc/adjust_leaderboard(client_key)
	if(!client_key)
		return
	var/target_ckey = ckey(client_key)
	var/metadollar_total = metadollar_amount_cache[target_ckey]
	if(!isnum(metadollar_total) || metadollar_total < 1)
		return
	if(metadollar_leaderboard_positions_tracked > metadollar_leaderboard.len)
		metadollar_leaderboard[client_key] = metadollar_total
	else
		if(metadollar_leaderboard[metadollar_leaderboard[metadollar_leaderboard.len]] > metadollar_total)
			return
		metadollar_leaderboard.Cut(metadollar_leaderboard.len)
		metadollar_leaderboard[client_key] = metadollar_total
	sort_metadollar_leaderboard()
	save_metadollar_leaderboard()

/datum/controller/subsystem/metadollars/proc/sort_metadollar_leaderboard()
	if(metadollar_leaderboard.len <= 1)
		return
	var/list/sorted_list = list()
	for(var/cache_key in metadollar_leaderboard)
		if(!sorted_list.len)
			sorted_list[cache_key] = metadollar_leaderboard[cache_key]
			continue
		var/inserted = FALSE
		for(var/sorted_key in sorted_list)
			if(sorted_list[sorted_key] < metadollar_leaderboard[cache_key])
				sorted_list.Insert(sorted_list.Find(sorted_key), cache_key)
				sorted_list[cache_key] = metadollar_leaderboard[cache_key]
				inserted = TRUE
				break
		if(!inserted)
			sorted_list[cache_key] = metadollar_leaderboard[cache_key]
	metadollar_leaderboard = sorted_list

/datum/controller/subsystem/metadollars/proc/get_leaderboard_ui_data(max_entries = 5)
	var/list/out = list()
	var/position = 0
	for(var/key in metadollar_leaderboard)
		position++
		out += list(list("name" = key, "amount" = metadollar_leaderboard[key]))
		if(position >= max_entries)
			break
	return out

/datum/controller/subsystem/metadollars/proc/wipe_all_metadollars()
	metadollar_amount_cache = list()
	metadollar_leaderboard = list()
	save_metadollar_leaderboard()
	if(!fexists("data/player_saves"))
		return
	for(var/letterdir in flist("data/player_saves/"))
		var/prefix = "data/player_saves/[letterdir]"
		if(!fexists(prefix))
			continue
		for(var/sub in flist(prefix))
			var/json_path = "[prefix]/[sub]/metadollars.json"
			if(fexists(json_path))
				fdel(json_path)

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
	metadollar_adjust(amount, C.ckey, C.key)
	var/ck = C.ckey
	LAZYINITLIST(round_earnings[ck])
	if(!round_earnings[ck][category])
		round_earnings[ck][category] = 0
	round_earnings[ck][category] += amount
	round_earnings[ck]["total"] = (round_earnings[ck]["total"] || 0) + amount
	if(category == "living")
		C.prefs.save_preferences()
	if(category == "living" && isliving(C.mob))
		to_chat(C.mob, span_purple("Вы получили [amount] М$ за работу."))
		SEND_SOUND(C.mob, sound('sound/machines/terminal_success.ogg', volume = 35))

/datum/controller/subsystem/metadollars/proc/count_completed_station_goals()
	. = 0
	if(!SSticker?.mode?.station_goals?.len)
		return
	for(var/datum/station_goal/G in SSticker.mode.station_goals)
		if(G.check_completion())
			.++

/datum/controller/subsystem/metadollars/proc/cc_station_goals_metadollars(completed_goals)
	if(completed_goals > 0)
		return 2 * completed_goals
	return 0

/datum/controller/subsystem/metadollars/proc/cc_total_payout_for_mob(mob/M, completed_goals)
	var/goals_part = cc_station_goals_metadollars(completed_goals)
	var/role_part = isliving(M) ? metadollar_living_multiplier(M) : 1
	return goals_part + role_part

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
	var/balance = get_metadollars(C.ckey)
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
		chunks += "<div class='panel stationborder'><span class='header'>Метадоллары за раунд</span><br>Всего начислено: <b>[total] М$</b>.<br><small>[lines.Join("<br>")]</small><br>Текущий баланс: <b>[balance] М$</b>.</div>"
	var/missed_block = metadollar_roundend_missed_html(C, C.mob, E)
	if(missed_block)
		if(total <= 0)
			missed_block += "<br><small>Текущий баланс: <b>[balance] М$</b>.</small>"
		chunks += missed_block
	if(!length(chunks))
		return ""
	return chunks.Join("")

/proc/bm_metadollar_global_burn(mob/initiator)
	if(SSmetadollars)
		SSmetadollars.wipe_all_metadollars()
		SSmetadollars.round_earnings = list()
	var/notice = "В этом раунде активирован протокол «Пепелище»: обнулены все метадолларовые балансы."
	if(initiator)
		notice += " Инициатор: [initiator.real_name] ([initiator.ckey])."
	if(SSmetadollars)
		SSmetadollars.metadollar_burn_round_notice = notice

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
		if(istype(I, /obj/item/coin/antagtoken/metashop))
			var/obj/item/coin/antagtoken/metashop/MS = I
			MS.metashop_purchaser_ckey = C.ckey
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
