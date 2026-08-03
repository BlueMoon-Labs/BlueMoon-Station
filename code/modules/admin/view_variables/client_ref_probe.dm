/// Поиск держателей датума в клиентских структурах, невидимых обычному скану:
/// /image не датум (for(var/datum) его не перечисляет), а client.images/screen/eye
/// живут на стороне клиента. Классический кейс - обсервер, которого держит
/// image с loc=обсервер в чьём-то client.images (орбит-поинтеры, HUD-иконки).
/// НЕ итерирует client.vars (краш живого сервера) - только явные чтения, поэтому
/// список переменных ниже надо расширять руками при появлении новых держателей.
/// target нетипизирован: целью может быть и /image.
/**
 * Собирает описания держателей target из уже прочитанных структур одного клиента.
 * Вынесено отдельным проком: /client не датум и в CI не существует, поэтому
 * покрытие переменных проверяется только через эту чистую часть.
 * direct_vars: имя переменной -> значение. container_vars: имя -> список (в т.ч. ассоц).
 */
/proc/collect_client_ref_hits(target, client_label, list/direct_vars, list/container_vars, list/assoc_value_vars)
	var/list/hits = list()
	if(isnull(target))
		return hits
	for(var/var_name in direct_vars)
		if(direct_vars[var_name] == target)
			hits += "client [client_label]: [var_name]"
	for(var/var_name in container_vars)
		var/list/container = container_vars[var_name]
		if(islist(container) && (target in container))
			hits += "client [client_label]: [var_name] (запись списка)"
	for(var/var_name in assoc_value_vars)
		var/list/container = assoc_value_vars[var_name]
		if(!islist(container))
			continue
		for(var/entry_key in container)
			var/entry_value = container[entry_key]
			if(entry_value == target)
				hits += "client [client_label]: [var_name]\[[entry_key]\]"
				break
			if(islist(entry_value) && (target in entry_value))
				hits += "client [client_label]: [var_name]\[[entry_key]\] (вложенный список)"
				break
	return hits

/proc/find_client_references(target, quiet = FALSE)
	var/list/results = list()
	if(isnull(target))
		return results
	for(var/client/game_client in GLOB.clients)
		results += collect_client_ref_hits(target, game_client.ckey,
			list(
				"mob" = game_client.mob,
				"eye" = game_client.eye,
				"statobj" = game_client.statobj,
				"click_intercept" = game_client.click_intercept,
				"selected_target" = game_client.selected_target?[1],
				"active_mousedown_item" = game_client.active_mousedown_item,
				"listed_turf_watched" = game_client.listed_turf_watched,
				"click_catcher" = game_client.click_catcher,
				"void" = game_client.void,
				"void_right" = game_client.void_right,
				"void_bottom" = game_client.void_bottom,
				"parallax_holder" = game_client.parallax_holder,
				"holder" = game_client.holder,
				"prefs" = game_client.prefs,
				"player_details" = game_client.player_details,
				"tooltips" = game_client.tooltips,
			),
			list(
				"screen" = game_client.screen,
				"recent_examines" = game_client.recent_examines,
				"seen_messages" = game_client.seen_messages,
				// Держать сами атомы здесь нельзя (см. register_moused_over) - проб ловит регресс.
				"moused_over_objects" = game_client.moused_over_objects,
			),
			list(
				"char_render_holders" = game_client.char_render_holders,
				"screen_maps" = game_client.screen_maps,
				"seen_messages" = game_client.seen_messages,
			))
		var/direct_hits = 0
		var/attached_hits = 0
		for(var/image/held_image in game_client.images)
			if(held_image == target)
				direct_hits++
			else if(held_image.loc == target)
				attached_hits++
		if(direct_hits)
			results += "client [game_client.ckey]: images x[direct_hits] (сам объект в images)"
		if(attached_hits)
			results += "client [game_client.ckey]: images x[attached_hits] с loc=цель (прикреплённые image держат объект)"
		CHECK_TICK
	if(!quiet)
		for(var/line in results)
			log_reftracker("CLIENT PROBE: [line]")
		if(!length(results))
			log_reftracker("CLIENT PROBE: держателей в клиентских структурах не найдено")
	return results
