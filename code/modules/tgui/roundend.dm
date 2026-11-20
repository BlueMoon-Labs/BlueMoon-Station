/**
 * tgui-отчёт о конце раунда.
 *
 * Хранит неизменяемый снимок данных раунда для одного клиента и отдаёт его
 * интерфейсу `Roundend`. HTML-отчёт (для логов и старых сохранений) по-прежнему
 * собирается в code/__HELPERS/roundend.dm — здесь строятся только
 * структурированные данные для tgui и фасад, который открывает окно.
 */

/client/var/datum/roundend_report/roundend_report_ui

/// Файл с tgui-снимком последнего раунда сервера.
/proc/server_roundend_tgui_file()
	return "data/server_last_roundend_report_tgui.json"

/**
 * Фасад tgui для отчёта о конце раунда. Один датум на клиента, чтобы повторное
 * открытие обновляло уже существующее окно, а не плодило новые.
 */
/datum/roundend_report
	/// Клиент-владелец отчёта.
	var/client/owner
	/// Снимок данных, который получает frontend.
	var/list/report_data
	/// Неизменяемый снимок текущего раунда. Не перезаписывается при просмотре старых отчётов.
	var/list/current_round_data

/datum/roundend_report/New(client/C, list/data = null)
	owner = C
	report_data = data

/datum/roundend_report/Destroy(force = FALSE)
	if(owner?.roundend_report_ui == src)
		owner.roundend_report_ui = null
	owner = null
	report_data = null
	current_round_data = null
	return ..()

/datum/roundend_report/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Roundend", "Конец раунда")
		ui.set_autoupdate(FALSE) // Данные раунда не меняются после его завершения.
		ui.open()

/datum/roundend_report/ui_state(mob/user)
	return GLOB.always_state

/datum/roundend_report/ui_data(mob/user)
	return report_data

/datum/roundend_report/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	switch(action)
		if("close")
			ui.close()
			return TRUE

/**
 * Строит структурированные данные для tgui-отчёта.
 *
 * Аргументы:
 * * client/C - клиент, для которого собирается персональная сводка (может быть null).
 * * popcount - результат gather_roundend_feedback().
 */
/proc/build_roundend_tgui_data(client/C, popcount)
	var/list/data = list()

	// --- Персональный баннер ---
	var/list/survival = list("status" = "unknown", "message" = "")
	var/mob/M = C?.mob
	if(M?.mind && !isnewplayer(M))
		if(M.stat != DEAD && !isbrain(M))
			if(EMERGENCY_ESCAPED_OR_ENDGAMED && !M.onCentCom() && !M.onSyndieBase())
				survival["status"] = "marooned"
				survival["message"] = "Тебе удалось пережить события, будучи [M.real_name], но пришлось остаться на станции [station_name()]..."
			else
				survival["status"] = "survived"
				survival["message"] = "Тебе удалось пережить события, произошедшие на станции [station_name()], будучи [M.real_name]!"
		else
			survival["status"] = "dead"
			survival["message"] = "Будучи [M.real_name], тебе не удалось пережить события, произошедшие на станции [station_name()]..."
	data["survival"] = survival

	// --- Информация о раунде ---
	var/list/round_info = list()
	round_info["id"] = GLOB.round_id ? "[GLOB.round_id]" : ""
	var/statspage = CONFIG_GET(string/roundstatsurl)
	round_info["stats_url"] = (GLOB.round_id && statspage) ? "[statspage][GLOB.round_id]" : ""
	round_info["duration"] = DisplayTimeText(world.time - SSticker.round_start_time)
	round_info["knottings"] = GLOB.knottings
	data["round_info"] = round_info

	// --- Информация о станции ---
	var/list/station_info = list()
	station_info["nuked"] = SSticker.mode?.station_was_nuked
	station_info["integrity"] = popcount["station_integrity"]
	data["station_info"] = station_info

	// --- Информация о персонале ---
	var/total_players = GLOB.joined_player_list.len
	var/list/personnel = list()
	personnel["total"] = total_players
	personnel["dead"] = popcount[POPCOUNT_DEADS]
	personnel["alive"] = popcount[POPCOUNT_SURVIVORS]
	personnel["dead_percent"] = total_players ? PERCENT(popcount[POPCOUNT_DEADS] / total_players) : 0
	personnel["alive_percent"] = total_players ? PERCENT(popcount[POPCOUNT_SURVIVORS] / total_players) : 0
	personnel["evacuated"] = EMERGENCY_ESCAPED_OR_ENDGAMED
	var/list/evacuation = list()
	if(EMERGENCY_ESCAPED_OR_ENDGAMED)
		evacuation["escaped"] = popcount[POPCOUNT_ESCAPEES]
		evacuation["escaped_percent"] = total_players ? PERCENT(popcount[POPCOUNT_ESCAPEES] / total_players) : 0
		evacuation["shuttle"] = popcount[POPCOUNT_SHUTTLE_ESCAPEES]
		evacuation["shuttle_percent"] = total_players ? PERCENT(popcount[POPCOUNT_SHUTTLE_ESCAPEES] / total_players) : 0
		evacuation["pods"] = popcount[POPCOUNT_ANOTHER_ESCAPEES]
		evacuation["pods_percent"] = total_players ? PERCENT(popcount[POPCOUNT_ANOTHER_ESCAPEES] / total_players) : 0
	personnel["evacuation"] = evacuation
	data["personnel"] = personnel

	// --- Первая смерть ---
	var/list/first_death = SSblackbox.first_death
	if(LAZYLEN(first_death))
		data["first_death"] = list(
			"name" = first_death["name"],
			"role" = first_death["role"],
			"area" = first_death["area"],
			// В blackbox это HTML вида <font color='...'>10</font>/..., а в tgui поле текстовое.
			"damage" = strip_html_tags("[first_death["damage"]]"),
			"last_words" = first_death["last_words"] ? "[first_death["last_words"]]" : "отсутствовали",
		)
	else
		data["first_death"] = null

	// --- Динамический режим ---
	if(istype(SSticker.mode, /datum/game_mode/dynamic))
		var/datum/game_mode/dynamic/dynamic_mode = SSticker.mode
		var/list/rules = list()
		for(var/datum/dynamic_ruleset/rule in dynamic_mode.executed_rules)
			rules += "[FOURSPACES]─ [rule.ruletype] - <b>[rule.name]</b>: -[rule.cost + rule.scaled_times * rule.scaling_cost] очков угрозы"
		if(!length(rules))
			rules += "<i>Вычеты очков угрозы отсутствуют</i>."
		data["dynamic"] = list(
			"threat_level" = dynamic_mode.threat_level,
			"budget" = dynamic_mode.mid_round_budget,
			"rules_html" = rules.Join("<br>"),
		)
	else
		data["dynamic"] = null

	// --- HTML-блоки от остальных подсистем ---
	data["common_report_html"] = GLOB.common_report || ""
	var/extra = ""
	if(C)
		extra += SSmetadollars?.personal_roundend_html(C) || ""
		extra += GLOB.inteq_pact_siege?.personal_roundend_html(C) || ""
	data["personal_extra_html"] = extra

	return data

/client/proc/roundend_report_tgui_file()
	return "data/roundend_reports/[ckey]_tgui.json"

/**
 * Читает сохранённый tgui-отчёт из файла. Возвращает null, если файла нет.
 */
/proc/load_roundend_tgui_data(path)
	if(!fexists(path))
		return null
	var/text = file2text(path)
	if(!text)
		return null
	return json_decode(text)

/**
 * Сохраняет tgui-отчёт в файл, чтобы его можно было посмотреть после рестарта.
 */
/proc/save_roundend_tgui_data(path, list/data)
	if(!data)
		return
	WRITE_FILE(path, json_encode(data))
