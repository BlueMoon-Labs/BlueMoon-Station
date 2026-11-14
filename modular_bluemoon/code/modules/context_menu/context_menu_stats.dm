/**
 * Статистика меню действий за раунд: что выбрали игроки и как пользуются меню, чтобы подбирать дефолты по большинству.
 *
 * Пишется в [GLOB.log_directory]/context_menu.json, файл перезаписывается целиком не чаще раза в CONTEXT_MENU_STATS_EXPORT_DELAY.
 * players: ckey -> раскладка ПКМ, набор, вид (только то, что не по умолчанию), зум карты, открытия, выборы, брошенные меню и почему их закрыли.
 * По чему открывали и бросали (mob, item, structure, turf, tile - список клетки), через сколько секунд бросили
 * и сколько закрывающих кликов пришлось по тому же, по чему открыто меню, - по причинам.
 * changes: кто, когда и что поменял в раскладке и виде - видно, от каких дефолтов уходят.
 * entries: сколько раз выбран каждый пункт меню по всем игрокам.
 */
GLOBAL_DATUM_INIT(context_menu_stats, /datum/context_menu_stats, new)

/datum/context_menu_stats
	var/list/players = list()
	var/list/changes = list()
	var/list/entries = list()
	/// Выгрузка уже запланирована
	var/export_queued = FALSE

/datum/context_menu_stats/proc/player_record(client/player)
	if(!player?.ckey)
		return null
	return record_for(player.ckey, player.prefs, player.context_menu_zoom)

/// Запись игрока с его нынешними настройками
/datum/context_menu_stats/proc/record_for(ckey, datum/preferences/prefs, zoom)
	var/list/record = players[ckey]
	if(!record)
		record = list(
			"opens" = 0,
			"opens_shift" = 0,
			"opens_combat" = 0,
			"choices" = 0,
			"abandoned" = 0,
			"choice_kinds" = list(),
			"abandon_reasons" = list(),
			"open_kinds" = list(),
			"abandon_kinds" = list(),
			"abandon_after" = list(),
			"on_target" = list(),
		)
		players[ckey] = record
	// настройки - на момент последнего действия: игрок мог их сменить по ходу раунда
	if(prefs)
		record["right_click"] = right_click_action_name(prefs.right_click_mode())
		record["shift_right_click"] = right_click_action_name(prefs.shift_right_click_mode())
		record["right_click_chosen"] = !isnull(prefs.right_click_choice)
		record["preset"] = prefs.current_context_menu_preset() || "custom"
		record["style"] = prefs.context_menu_style?.Copy() || list()
	record["zoom"] = zoom
	return record

/datum/context_menu_stats/proc/record_open(mob/user, list/modifiers, kind)
	var/list/record = player_record(user?.client)
	if(!record)
		return
	record_open_in(record, modifiers, kind)
	if(user.right_click_needs_clicks())
		record["opens_combat"]++
	queue_export()

/datum/context_menu_stats/proc/record_open_in(list/record, list/modifiers, kind)
	record["opens"]++
	var/list/kinds = record["open_kinds"]
	kinds[kind || "other"]++
	if(modifiers["shift"])
		record["opens_shift"]++

/// Выбор пункта: kind - тип пункта (click, verb_call, pick, page...), name - текст пункта
/datum/context_menu_stats/proc/record_choice(mob/user, kind, name)
	var/list/record = player_record(user?.client)
	if(!record)
		return
	record["choices"]++
	var/list/kinds = record["choice_kinds"]
	kinds[kind]++
	count_entry(kind, name)
	queue_export()

/// Счёт пункта по имени. Имена предметов в списке клетки и шапка с именем цели уникальны и раздувают таблицу, считаются только действия
/datum/context_menu_stats/proc/count_entry(kind, name)
	if(!name || (kind in list("pick", "pick_group", "mode_choice")))
		return
	if(entries[name] || length(entries) < CONTEXT_MENU_STATS_MAX_ENTRIES)
		entries[name]++

/// Меню закрыто без выбора; reason - чем: click (клик мимо), reopen (новое меню), escape, moved, auto_close, settings, lost, target.
/// kind - по чему было открыто, seconds - сколько было открыто, on_target - закрыто кликом по тому же
/datum/context_menu_stats/proc/record_abandon(mob/user, reason, kind, seconds, on_target)
	var/list/record = player_record(user?.client)
	if(!record)
		return
	record_abandon_in(record, reason, kind, seconds, on_target)
	queue_export()

/datum/context_menu_stats/proc/record_abandon_in(list/record, reason, kind, seconds, on_target)
	record["abandoned"]++
	var/list/reasons = record["abandon_reasons"]
	reasons[reason]++
	var/list/kinds = record["abandon_kinds"]
	kinds[kind || "other"]++
	if(!isnull(seconds))
		var/list/after = record["abandon_after"]
		after[context_menu_time_bucket(seconds)]++
	if(on_target)
		var/list/on_target_reasons = record["on_target"]
		on_target_reasons[reason]++

/// Смена раскладки или вида: setting - что, value - на что
/datum/context_menu_stats/proc/record_change(client/player, setting, value)
	if(!player?.ckey)
		return
	if(length(changes) < CONTEXT_MENU_STATS_MAX_CHANGES)
		changes += list(list(
			"time" = round(world.time / 10),
			"ckey" = player.ckey,
			"setting" = setting,
			"value" = value,
		))
	// перебор вида и наборов идёт десятками кликов подряд, в лог игры - только раскладка
	if(setting == "раскладку")
		log_game("[key_name(player)] сменил в меню ПКМ [setting]: [value]")
	player_record(player)
	queue_export()

/datum/context_menu_stats/proc/queue_export()
	if(export_queued)
		return
	export_queued = TRUE
	addtimer(CALLBACK(src, PROC_REF(export)), CONTEXT_MENU_STATS_EXPORT_DELAY)

/datum/context_menu_stats/proc/export()
	export_queued = FALSE
	if(!GLOB.log_directory)
		return
	rustg_file_write(json_encode(snapshot()), "[GLOB.log_directory]/context_menu.json")

/// Всё собранное плюс сводка: сколько игроков на каждой раскладке, наборе и значении каждой настройки
/datum/context_menu_stats/proc/snapshot()
	var/list/counters = list("abandon_reasons", "open_kinds", "abandon_kinds", "abandon_after", "on_target")
	var/list/summary = list("right_click" = list(), "shift_right_click" = list(), "preset" = list(), "style" = list())
	for(var/counter in counters)
		summary[counter] = list()
	for(var/ckey in players)
		var/list/record = players[ckey]
		for(var/counter in counters)
			var/list/total = summary[counter]
			var/list/own = record[counter]
			for(var/key in own)
				total[key] += own[key]
		for(var/key in list("right_click", "shift_right_click", "preset"))
			var/list/counts = summary[key]
			counts["[record[key]]"]++
		var/list/style_counts = summary["style"]
		for(var/option in GLOB.context_menu_style_choices + CONTEXT_MENU_FREE_OPTIONS)
			if(!style_counts[option])
				style_counts[option] = list()
			var/list/option_counts = style_counts[option]
			option_counts["[context_menu_style_option(record["style"], option)]"]++
	return list(
		"round_id" = GLOB.round_id,
		"time" = round(world.time / 10),
		"summary" = summary,
		"players" = players,
		"changes" = changes,
		"entries" = entries,
	)

/// Корзина времени, которое меню было открыто, в секундах
/proc/context_menu_time_bucket(seconds)
	if(seconds < 1)
		return "0-1"
	if(seconds < 3)
		return "1-3"
	if(seconds < 10)
		return "3-10"
	return "10+"

/// По чему открыто меню: mob, item, structure, turf; список клетки - tile
/proc/context_menu_target_kind(atom/thing)
	if(ismob(thing))
		return "mob"
	if(isitem(thing))
		return "item"
	if(isobj(thing))
		return "structure"
	if(isturf(thing))
		return "turf"
	return "other"

/// Вид пункта для статистики: последняя часть типа
/proc/context_menu_entry_kind(datum/context_menu_entry/entry)
	var/type_text = "[entry.type]"
	return copytext(type_text, findlasttext(type_text, "/") + 1)
