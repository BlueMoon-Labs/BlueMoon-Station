/**
 * Статистика меню действий за раунд: что выбрали игроки и как пользуются меню, чтобы подбирать дефолты по большинству.
 *
 * Пишется в [GLOB.log_directory]/context_menu.json, файл перезаписывается целиком не чаще раза в CONTEXT_MENU_STATS_EXPORT_DELAY.
 * players: ckey -> раскладка ПКМ, набор, вид (только то, что не по умолчанию), зум карты, открытия, выборы, брошенные меню.
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

/datum/context_menu_stats/proc/record_open(mob/user, list/modifiers)
	var/list/record = player_record(user?.client)
	if(!record)
		return
	record["opens"]++
	if(modifiers["shift"])
		record["opens_shift"]++
	if(user.right_click_needs_clicks())
		record["opens_combat"]++
	queue_export()

/// Выбор пункта: kind - тип пункта (click, verb_call, pick, page...), name - текст пункта
/datum/context_menu_stats/proc/record_choice(mob/user, kind, name)
	var/list/record = player_record(user?.client)
	if(!record)
		return
	record["choices"]++
	var/list/kinds = record["choice_kinds"]
	kinds[kind]++
	// имена предметов в списке клетки уникальны и раздувают таблицу, считаются только действия
	if(kind != "pick" && kind != "pick_group" && name && (entries[name] || length(entries) < CONTEXT_MENU_STATS_MAX_ENTRIES))
		entries[name]++
	queue_export()

/datum/context_menu_stats/proc/record_abandon(mob/user)
	var/list/record = player_record(user?.client)
	if(!record)
		return
	record["abandoned"]++
	queue_export()

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
	var/list/summary = list("right_click" = list(), "shift_right_click" = list(), "preset" = list(), "style" = list())
	for(var/ckey in players)
		var/list/record = players[ckey]
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

/// Вид пункта для статистики: последняя часть типа
/proc/context_menu_entry_kind(datum/context_menu_entry/entry)
	var/type_text = "[entry.type]"
	return copytext(type_text, findlasttext(type_text, "/") + 1)
