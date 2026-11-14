/// ckey зрителя -> list("pack" = тип открытого пака, "search" = строка поиска, "hits" = id найденных паков, "total" = сколько найдено). Описания и описи каталога не уходят статикой: карточку и поиск каждый зритель запрашивает сам.
GLOBAL_LIST_EMPTY(econ_cargo_viewers)
/// Тип пака -> имя, описание и опись одной строкой для поиска
GLOBAL_LIST_EMPTY(econ_cargo_search_text)

/proc/econ_cargo_pack_search_text(datum/supply_pack/pack)
	. = GLOB.econ_cargo_search_text[pack.type]
	if(isnull(.))
		. = "[pack.name] [pack.desc] [jointext(econ_pack_contents(pack), " ")]"
		GLOB.econ_cargo_search_text[pack.type] = .

/proc/econ_cargo_viewer_state(mob/user)
	if(!user)
		return null
	var/key = user.ckey || REF(user)
	. = GLOB.econ_cargo_viewers[key]
	if(!.)
		. = list("pack" = null, "search" = "", "hits" = list(), "total" = 0)
		GLOB.econ_cargo_viewers[key] = .

/// Паки каталога catalog_ids (тип -> TRUE), в имени, описании или описи которых есть text; не больше ECON_CARGO_SEARCH_HITS_MAX, в .["total"] - сколько всего.
/proc/econ_cargo_search(text, list/catalog_ids)
	. = list("hits" = list(), "total" = 0)
	if(length_char(text) < ECON_CARGO_SEARCH_MIN)
		return
	var/list/hits = .["hits"]
	for(var/pack_type in catalog_ids)
		var/datum/supply_pack/pack = SSshuttle.supply_packs[pack_type]
		if(!pack || !findtext(econ_cargo_pack_search_text(pack), text))
			continue
		.["total"]++
		if(length(hits) < ECON_CARGO_SEARCH_HITS_MAX)
			hits += "[pack_type]"

/// Действия окна снабжения, общие для всех консолей с каталогом: карточка пака и полнотекстовый поиск. TRUE - действие обработано.
/proc/econ_cargo_viewer_act(mob/user, action, list/params, list/catalog_ids)
	if(action != "pack_info" && action != "search")
		return FALSE
	var/list/state = econ_cargo_viewer_state(user)
	if(!state)
		return TRUE
	if(action == "pack_info")
		var/pack_type = text2path("[params["id"]]")
		state["pack"] = (pack_type && catalog_ids?[pack_type]) ? pack_type : null
		return TRUE
	var/text = trim(copytext_char("[params["text"]]", 1, ECON_CARGO_SEARCH_MAX + 1))
	var/list/found = econ_cargo_search(text, catalog_ids)
	state["search"] = text
	state["hits"] = found["hits"]
	state["total"] = found["total"]
	return TRUE

/// Карточка открытого пака и итог поиска зрителя для ui_data окна снабжения.
/proc/econ_cargo_viewer_data(mob/user)
	var/list/state = econ_cargo_viewer_state(user)
	if(!state)
		return list()
	var/list/pack_info
	var/datum/supply_pack/pack = state["pack"] ? SSshuttle.supply_packs[state["pack"]] : null
	if(pack)
		pack_info = list(
			"id" = "[pack.type]",
			"desc" = pack.desc || pack.name,
			"contents" = econ_pack_contents(pack),
		)
	return list(
		"pack_info" = pack_info,
		"search" = state["search"],
		"search_hits" = state["hits"],
		"search_total" = state["total"],
	)
