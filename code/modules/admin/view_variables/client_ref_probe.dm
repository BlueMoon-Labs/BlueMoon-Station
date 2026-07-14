/// Поиск держателей датума в клиентских структурах, невидимых обычному скану:
/// /image не датум (for(var/datum) его не перечисляет), а client.images/screen/eye
/// живут на стороне клиента. Классический кейс - обсервер, которого держит
/// image с loc=обсервер в чьём-то client.images (орбит-поинтеры, HUD-иконки).
/// НЕ итерирует client.vars (краш живого сервера) - только явные чтения.
/// target нетипизирован: целью может быть и /image.
/proc/find_client_references(target, quiet = FALSE)
	var/list/results = list()
	if(isnull(target))
		return results
	for(var/client/game_client in GLOB.clients)
		if(game_client.mob == target)
			results += "client [game_client.ckey]: mob"
		if(game_client.eye == target)
			results += "client [game_client.ckey]: eye"
		if(game_client.statobj == target)
			results += "client [game_client.ckey]: statobj"
		for(var/screen_entry in game_client.screen)
			if(screen_entry == target)
				results += "client [game_client.ckey]: screen"
				break
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
