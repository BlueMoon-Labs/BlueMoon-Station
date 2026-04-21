/datum/metadollar_shop
	var/client/owner
	var/inteq_mode = FALSE

/datum/metadollar_shop/New(client/owner)
	src.owner = owner

/datum/metadollar_shop/ui_state(mob/user)
	return GLOB.always_state

/datum/metadollar_shop/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "MetadollarShop")
		ui.open()

/datum/metadollar_shop/proc/build_catalog_list(catalog_key)
	var/list/out = list()
	for(var/T in subtypesof(/datum/metadollar_shop_item/item))
		if(T == /datum/metadollar_shop_item/item)
			continue
		var/datum/metadollar_shop_item/item/I = new T()
		if(I.catalog != catalog_key)
			qdel(I)
			continue
		out += list(list(
			"id" = "[T]",
			"name" = I.name,
			"desc" = I.desc,
			"cost" = I.cost,
			"minPlayers" = I.minimum_players,
		))
		qdel(I)
	return out

/datum/metadollar_shop/ui_static_data(mob/user)
	return list(
		"legit" = build_catalog_list("legit"),
		"smuggle" = build_catalog_list("smuggle"),
	)

/datum/metadollar_shop/ui_data(mob/user)
	var/list/data = list()
	data["balance"] = owner?.prefs?.metadollars || 0
	data["inteqMode"] = inteq_mode
	data["onlinePlayers"] = length(GLOB.player_list)
	return data

/datum/metadollar_shop/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	if(!owner?.prefs)
		return TRUE
	switch(action)
		if("topup")
			var/mob/topupper = usr
			if(!istype(topupper))
				return TRUE
			tgui_alert_async(topupper, "Для пополнения счёта напишите \"SmiLeY\"/\"5mi1ey_owo\". Спасибо!", "Пополнение счёта")
			return TRUE
		if("toggle_smuggle")
			inteq_mode = !inteq_mode
			return TRUE
		if("buy")
			var/id = params["id"]
			if(isnull(id))
				return FALSE
			id = "[id]"
			var/path = text2path(id)
			if(!ispath(path, /datum/metadollar_shop_item/item))
				return FALSE
			var/datum/metadollar_shop_item/entry = new path()
			if(inteq_mode && entry.catalog != "smuggle")
				qdel(entry)
				return TRUE
			if(!inteq_mode && entry.catalog != "legit")
				qdel(entry)
				return TRUE
			entry.try_purchase(owner)
			qdel(entry)
			return TRUE
	return FALSE
