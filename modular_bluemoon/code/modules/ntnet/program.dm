#define NTNET_SEARCH_MAX_QUERY 80
#define NTNET_MAX_TABS 6

/datum/ntnet_tab
	var/id
	var/site_id
	var/slug
	var/view = "home"
	var/query
	var/list/results = list()
	var/error
	var/pending = FALSE
	var/request = 0
	var/generation = 0
	var/list/back = list()
	var/list/forward = list()

/datum/ntnet_tab/proc/snapshot()
	return list("site_id" = site_id, "slug" = slug, "view" = view, "query" = query, "results" = results.Copy())

/datum/ntnet_tab/proc/restore(list/entry)
	site_id = entry["site_id"]
	slug = entry["slug"]
	view = entry["view"]
	query = entry["query"]
	results = entry["results"]
	error = null

/datum/computer_file/program/ntnet
	filename = "ntnet"
	filedesc = "NTnet"
	category = PROGRAM_CATEGORY_MISC
	program_icon_state = "generic"
	program_icon = "globe"
	extended_desc = "Браузер общедоступных страниц NTnet."
	size = 6
	requires_ntnet = TRUE
	usage_flags = PROGRAM_ALL
	tgui_id = "NtosNTnet"

	var/list/tabs = list()
	var/active_tab
	var/next_tab_id = 0

/datum/computer_file/program/ntnet/Destroy()
	QDEL_LIST(tabs)
	return ..()

/datum/computer_file/program/ntnet/proc/open_tab()
	if(length(tabs) >= NTNET_MAX_TABS)
		return
	var/datum/ntnet_tab/tab = new
	tab.id = ++next_tab_id
	tabs += tab
	active_tab = tab.id
	return tab

/datum/computer_file/program/ntnet/proc/current_tab()
	for(var/datum/ntnet_tab/tab as anything in tabs)
		if(tab.id == active_tab)
			return tab
	if(!length(tabs))
		return open_tab()
	var/datum/ntnet_tab/last = tabs[length(tabs)]
	active_tab = last.id
	return last

/datum/computer_file/program/ntnet/proc/tab_title(datum/ntnet_tab/tab)
	if(tab.site_id)
		var/list/cached = SSntnet.pages[json_encode(list(tab.site_id, tab.slug))]
		if(cached)
			return cached["title"]
		var/list/site = SSntnet.sites[tab.site_id]
		return site ? site["title"] : "Загрузка…"
	if(tab.query)
		return "Поиск"
	switch(tab.view)
		if("catalog")
			return "Список сайтов"
		if("create")
			return "Создать сайт"
	return "Новая вкладка"

/datum/computer_file/program/ntnet/proc/address_of(datum/ntnet_tab/tab)
	if(!tab.site_id)
		return tab.query ? "ntnet://search" : "ntnet://[tab.view]"
	var/list/site = SSntnet.sites[tab.site_id]
	if(!site)
		return ""
	return tab.slug == "index" ? site["domain"] : "[site["domain"]]/[tab.slug]"

/datum/computer_file/program/ntnet/ui_data(mob/user)
	var/list/data = get_header_data()
	SSntnet.last_used = world.time
	SSntnet.refresh_index()
	var/datum/ntnet_tab/tab = current_tab()
	if(length(tab.results) && tab.generation != SSntnet.generation)
		tab.generation = SSntnet.generation
		for(var/list/entry as anything in tab.results.Copy())
			if(!SSntnet.has_page(entry["site_id"], entry["slug"]))
				tab.results -= list(entry)
	if(tab.site_id && !SSntnet.has_page(tab.site_id, tab.slug))
		tab.site_id = null
		tab.slug = null
	var/cache_key = json_encode(list(tab.site_id, tab.slug))
	if(tab.site_id)
		SSntnet.request_page(tab.site_id, tab.slug)
	var/list/strip = list()
	for(var/datum/ntnet_tab/entry as anything in tabs)
		strip += list(list("id" = entry.id, "title" = tab_title(entry), "active" = entry.id == active_tab))
	var/client/viewer = user.client
	data["tabs"] = strip
	data["can_open_tab"] = length(tabs) < NTNET_MAX_TABS
	data["available"] = SSntnet.available
	data["loading"] = tab.site_id ? !SSntnet.pages[cache_key] && !SSntnet.page_failed(tab.site_id, tab.slug) : SSntnet.index_pending
	data["failed"] = tab.site_id && SSntnet.page_failed(tab.site_id, tab.slug)
	data["catalog"] = SSntnet.catalog
	data["site"] = SSntnet.sites[tab.site_id]
	data["page"] = SSntnet.pages[cache_key]
	data["view"] = tab.view
	data["address"] = address_of(tab)
	data["has_back"] = !!length(tab.back)
	data["has_forward"] = !!length(tab.forward)
	data["theme"] = viewer?.ntnet_light_theme ? "light" : "dark"
	var/list/viewer_entry = tab.site_id && viewer ? viewer.ntnet_viewer_tokens[tab.site_id] : null
	data["viewer"] = list(
		"token" = tab.site_id ? SSntnet.viewer_token(viewer, tab.site_id) : null,
		"error" = LAZYACCESS(viewer_entry, "error"),
	)
	data["search"] = list(
		"query" = tab.query,
		"results" = tab.results,
		"pending" = tab.pending,
		"error" = tab.error,
	)
	data["login"] = list(
		"code" = viewer && viewer.ntnet_code_expires > world.time ? viewer.ntnet_code : null,
		"pending" = viewer?.ntnet_login_pending,
		"retry_seconds" = viewer ? max(0, CEILING((viewer.ntnet_login_retry - world.time) / (1 SECONDS), 1)) : 0,
		"error" = viewer?.ntnet_login_error,
	)
	return data

/datum/computer_file/program/ntnet/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	var/datum/ntnet_tab/tab = current_tab()
	switch(action)
		if("login")
			SSntnet.request_login(ui.user.client)
			return TRUE
		if("theme")
			var/client/viewer = ui.user.client
			if(viewer)
				viewer.ntnet_light_theme = !viewer.ntnet_light_theme
			return TRUE
		if("open")
			open_page(params["site_id"], params["slug"])
			return TRUE
		if("go")
			var/list/target = SSntnet.resolve(params["query"])
			if(target)
				open_page(target[1], target[2])
				return TRUE
			search(params["query"])
			return TRUE
		if("home")
			go_to("home")
			return TRUE
		if("view")
			if(!(params["name"] in list("home", "catalog", "create")))
				return TRUE
			go_to(params["name"])
			return TRUE
		if("back")
			step_history(tab.back, tab.forward)
			return TRUE
		if("forward")
			step_history(tab.forward, tab.back)
			return TRUE
		if("refresh")
			SSntnet.force_refresh(tab.site_id, tab.slug)
			return TRUE
		if("token")
			SSntnet.request_viewer_token(ui.user.client, tab.site_id, ui.user.real_name, !!params["renew"])
			return TRUE
		if("tab_open")
			open_tab()
			return TRUE
		if("tab_select")
			var/wanted = text2num("[params["id"]]")
			for(var/datum/ntnet_tab/entry as anything in tabs)
				if(entry.id == wanted)
					active_tab = entry.id
			return TRUE
		if("tab_close")
			close_tab(text2num("[params["id"]]"))
			return TRUE

/datum/computer_file/program/ntnet/proc/close_tab(tab_id)
	for(var/datum/ntnet_tab/entry as anything in tabs)
		if(entry.id != tab_id)
			continue
		tabs -= entry
		qdel(entry)
		if(active_tab == tab_id && length(tabs))
			var/datum/ntnet_tab/last = tabs[length(tabs)]
			active_tab = last.id
		return

/datum/computer_file/program/ntnet/proc/step_history(list/source, list/destination)
	if(!length(source))
		return
	var/datum/ntnet_tab/tab = current_tab()
	destination += list(tab.snapshot())
	var/list/entry = source[length(source)]
	source.Cut(length(source))
	tab.restore(entry)
	if(tab.site_id)
		SSntnet.request_page(tab.site_id, tab.slug)

/datum/computer_file/program/ntnet/proc/remember()
	var/datum/ntnet_tab/tab = current_tab()
	tab.back += list(tab.snapshot())
	tab.forward.Cut()
	return tab

/datum/computer_file/program/ntnet/proc/go_to(name)
	var/datum/ntnet_tab/tab = remember()
	tab.view = name
	tab.site_id = null
	tab.slug = null
	tab.query = null
	tab.results = list()
	tab.error = null

/datum/computer_file/program/ntnet/proc/open_page(target_id, target_slug)
	if(!SSntnet.has_page(target_id, target_slug))
		return
	var/datum/ntnet_tab/tab = remember()
	tab.site_id = target_id
	tab.slug = target_slug
	tab.error = null
	SSntnet.request_page(target_id, target_slug)

/datum/computer_file/program/ntnet/proc/search(raw_query)
	var/datum/ntnet_tab/tab = current_tab()
	if(!istext(raw_query) || tab.pending)
		return
	var/query = trim(raw_query)
	if(length_char(query) < 2 || length_char(query) > NTNET_SEARCH_MAX_QUERY)
		tab.error = "Введите от 2 до [NTNET_SEARCH_MAX_QUERY] символов."
		return
	tab.request++
	if(!SSntnet.search(query, CALLBACK(src, PROC_REF(on_search), tab.id, tab.request)))
		tab.error = "NTnet занят. Попробуйте ещё раз."
		return
	remember()
	tab.site_id = null
	tab.slug = null
	tab.query = query
	tab.results = list()
	tab.error = null
	tab.pending = TRUE

/datum/computer_file/program/ntnet/proc/on_search(tab_id, request_id, list/response)
	if(QDELETED(src))
		return
	for(var/datum/ntnet_tab/tab as anything in tabs)
		if(tab.id != tab_id || !tab.pending || tab.request != request_id)
			continue
		tab.pending = FALSE
		var/list/found = SSntnet.search_results(response)
		if(isnull(found))
			tab.error = "Не удалось выполнить поиск."
		else
			tab.results = found
			tab.generation = SSntnet.generation
			tab.error = null
		break
	push_update()

#undef NTNET_SEARCH_MAX_QUERY
#undef NTNET_MAX_TABS
