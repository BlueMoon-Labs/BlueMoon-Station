/*!
 * Copyright (c) 2020 Aleksej Komarov
 * SPDX-License-Identifier: MIT
 */

/**
 * tgui datum (represents a UI).
 */
/datum/tgui
	/// The mob who opened/is using the UI.
	var/mob/user
	/// The object which owns the UI.
	var/datum/src_object
	/// The title of te UI.
	var/title
	/// The window_id for browse() and onclose().
	var/datum/tgui_window/window
	/// Key that is used for remembering the window geometry.
	var/window_key
	/// Deprecated: Window size.
	var/window_size
	/// The interface (template) to be used for this UI.
	var/interface
	/// Update the UI every MC tick.
	var/autoupdate = TRUE
	/// If the UI has been initialized yet.
	var/initialized = FALSE
	/// Time of opening the window.
	var/opened_at
	/// Stops further updates when close() was called.
	var/closing = FALSE
	/// The status/visibility of the UI.
	var/status = UI_INTERACTIVE
	/// Timed refreshing state
	var/refreshing = FALSE
	/// Topic state used to determine status/interactability.
	var/datum/ui_state/state = null
	/// If the window should update
	var/needs_update = FALSE
	/// Rate limit client refreshes to prevent DoS.
	COOLDOWN_DECLARE(refresh_cooldown)
	/// The Parent UI
	var/datum/tgui/parent_ui
	/// Children of this UI
	var/list/children = list()
	/// The id of any ByondUi elements that we have opened
	var/list/open_byondui_elements
	/// Sequence number of the last processed act (dedup guard for WebView2 double-delivery)
	var/last_act_seq = 0
	/// Ключ, под которым SStgui записал интерфейс в open_uis_by_src. Пересчитывать
	/// его из src_object на снятии с учёта нельзя: к тому моменту поле уже пусто.
	var/registered_src_key

/**
 * public
 *
 * Create a new UI.
 *
 * required user mob The mob who opened/is using the UI.
 * required src_object datum The object or datum which owns the UI.
 * required interface string The interface used to render the UI.
 * optional title string The title of the UI.
 * optional ui_x int Deprecated: Window width.
 * optional ui_y int Deprecated: Window height.
 *
 * return datum/tgui The requested UI.
 */
/datum/tgui/New(mob/user, datum/src_object, interface, title, datum/tgui/parent_ui, ui_x, ui_y)
	src.user = user
	src.src_object = src_object
	src.window_key = "[REF(src_object)]-main"
	src.interface = interface
	if(title)
		src.title = title
	src.state = src_object.ui_state(user)
	src.parent_ui = parent_ui
	if(parent_ui && parent_ui != 500)
		parent_ui.children += src
	// Deprecated
	if(ui_x && ui_y)
		src.window_size = list(ui_x, ui_y)

/datum/tgui/Destroy()
	//close() снимал интерфейс с учёта только когда окно уже было выдано, а
	//любой другой путь к qdel оставлял мертвеца в трёх списках подсистемы
	SStgui.unregister_ui(src)
	if(window?.locked_by == src)
		window.release_lock()
	window = null
	if(parent_ui && parent_ui != 500)
		parent_ui.children -= src
	parent_ui = null
	//дети переживают родителя (их закрывает close, а не Destroy) - иначе каждый
	//остаётся с parent_ui на покойнике
	for(var/datum/tgui/child as anything in children)
		child.parent_ui = null
	children.Cut()
	user = null
	src_object = null
	state = null
	return ..()

/**
 * public
 *
 * Open this UI (and initialize it with data).
 *
 * return bool - TRUE if a new pooled window is opened, FALSE in all other situations including if a new pooled window didn't open because one already exists.
 */
/datum/tgui/proc/open()
	if(!user?.client)
		return FALSE
	if(!src_object || QDELETED(src_object))
		return FALSE
	if(window)
		return FALSE
	process_status()
	if(status < UI_UPDATE)
		return FALSE
	window = SStgui.request_pooled_window(user)
	if(!window)
		return FALSE
	// Окно забирает фокус у карты, и отпускание зажатой клавиши уходит уже в
	// него. До BYOND оно не доходит, keys_held остаётся с клавишей внутри, и
	// keyLoop() шагает дальше - персонаж уходит сам, пока клавишу не нажмут
	// второй раз. Клиентский форвардинг (tgui/hotkeys.ts, orphanedKeyUp.ts)
	// ловит это не всегда, а промах стоит дорого: уйти можно и в космос.
	//
	// Поэтому при открытии окна считаем, что игрок отпустил всё - именно это
	// с точки зрения игры и произошло, держать клавиши он больше не может.
	// Если он всё ещё её жмёт, автоповтор ОС дойдёт до окна, и passthrough
	// пришлёт KeyDown заново - но уже по пути, который умеет и отпускать.
	user.client?.ForceAllKeysUp()
	window.acquire_lock(src)
	if(!window.is_ready())
		window.initialize(
			fancy = user.client.prefs.tgui_fancy,
			assets = list(
				get_asset_datum(/datum/asset/simple/tgui),
			))
	else
		window.send_message("ping")
	// initialize() спит на отправке ресурсов: логаут за это время успевает
	// пройти через close() -> qdel(src), и window уже null (клиент, зашедший и
	// сразу вышедший на ченджлоге, раунд 9875). Гард ниже по коду стоит уже
	// ПОСЛЕ этих send_asset и опоздал бы.
	if(QDELETED(src) || !window)
		return FALSE
	var/flush_queue = window.send_asset(get_asset_datum(
		/datum/asset/simple/namespaced/fontawesome))
	flush_queue |= window.send_asset(get_asset_datum(
		/datum/asset/simple/namespaced/tgfont))
	for(var/datum/asset/asset in src_object?.ui_assets(user))
		if(!asset)
			continue
		flush_queue |= window.send_asset(asset)
	//initialize/send_asset спят на отправке ресурсов: за это время датум могли
	//qdel-нуть (логаут, удаление src_object) - Destroy() обнуляет user
	if(QDELETED(src))
		return FALSE
	if(!user?.client)
		close(can_be_suspended = FALSE)
		return FALSE
	if (flush_queue)
		user.client.browse_queue_flush()
	// Отсчёт зомби-таймаута начинаем отсюда, а не с начала open(): выше окно ждало
	// initialize() и доставку ассетов, и на медленном канале весь бюджет уходил на
	// байты, которые ещё едут. Судить окно надо с момента, когда ресурсы уехали.
	opened_at = world.time
	if(QDELETED(src))
		return FALSE
	if(!user?.client)
		close(can_be_suspended = FALSE)
		return FALSE
	var/list/payload = get_payload(
		with_data = TRUE,
		with_static_data = TRUE)
	//сбор нагрузки тоже спит: если за это время окно закрыли, открывать нечего.
	//закрываемся честно, иначе окно останется залоченным за брошенным датумом и
	//пул не отдаст его следующему интерфейсу
	if(!payload || !can_send_update())
		if(!QDELETED(src))
			close(can_be_suspended = FALSE)
		return FALSE
	window.send_message("update", payload)
	SStgui.on_open(src)

	return TRUE

/**
 * public
 *
 * Close the UI.
 *
 * optional can_be_suspended bool
 */
/datum/tgui/proc/close(can_be_suspended = TRUE, logout = FALSE)
	if(closing)
		return
	closing = TRUE
	//Обход строго по копии: child.close() снимает себя из этого же children
	//(и там, и в Destroy), от чего индекс сдвигается и каждый второй ребёнок
	//оставался открытым - с живыми user и src_object в списках подсистемы.
	for(var/datum/tgui/child as anything in children.Copy())
		child.close(can_be_suspended, logout)
	// If we don't have window_id, open proc did not have the opportunity
	// to finish, therefore it's safe to skip this whole block.
	if(window)
		// Windows you want to keep are usually blue screens of death
		// and we want to keep them around, to allow user to read
		// the error message properly.
		//окно могло уехать в пул и достаться другому интерфейсу, пока мы спали в
		//get_payload(): чужой лок снимать нельзя, иначе мы закроем чужое окно
		if(window.locked_by == src)
			window.release_lock()
			window.close(can_be_suspended, logout)
		//src_object мог быть qdel-нут - именно по этому пути сюда и приходят из
		//process(), заметив пропажу владельца. Звать проки трупу нечего
		if(!QDELETED(src_object))
			src_object.ui_close(user)
		SStgui.on_close(src)
		if(user?.client)
			terminate_byondui_elements()
	state = null
	if(parent_ui && parent_ui != 500)
		parent_ui.children -= src
	parent_ui = null
	qdel(src)

/**
 * public
 *
 * Closes all ByondUI elements, left dangling by a forceful TGUI exit,
 * such as via Alt+F4, closing in non-fancy mode, or terminating the process
 */
/datum/tgui/proc/terminate_byondui_elements()
	set waitfor = FALSE

	var/client/owner = user?.client
	if(!owner || !LAZYLEN(open_byondui_elements))
		return

	for(var/byondui_element in open_byondui_elements)
		winset(owner, byondui_element, list("parent" = ""))
	open_byondui_elements = null

/**
 * public
 *
 * Enable/disable auto-updating of the UI.
 *
 * required value bool Enable/disable auto-updating.
 */
/datum/tgui/proc/set_autoupdate(autoupdate)
	src.autoupdate = autoupdate

/**
 * public
 *
 * Replace current ui.state with a new one.
 *
 * required state datum/ui_state/state Next state
 */
/datum/tgui/proc/set_state(datum/ui_state/state)
	src.state = state

/**
 * public
 *
 * Makes an asset available to use in tgui.
 *
 * required asset datum/asset
 *
 * return bool - true if an asset was actually sent
 */
/datum/tgui/proc/send_asset(datum/asset/asset)
	if(!window)
		CRASH("send_asset() was called either without calling open() first or when open() did not return TRUE.")
	return window.send_asset(asset)

/**
 * public
 *
 * Send a full update to the client (includes static data).
 *
 * optional custom_data list Custom data to send instead of ui_data.
 * optional force bool Send an update even if UI is not interactive.
 */
/datum/tgui/proc/send_full_update(custom_data, force, ignore_cooldown = FALSE)
	if(!user?.client || !initialized || closing)
		return
	if(!ignore_cooldown && !COOLDOWN_FINISHED(src, refresh_cooldown))
		refreshing = TRUE
		addtimer(CALLBACK(src, PROC_REF(send_full_update)), TGUI_REFRESH_FULL_UPDATE_COOLDOWN, TIMER_UNIQUE)
		return
	refreshing = FALSE
	var/should_update_data = force || status >= UI_UPDATE
	var/list/payload = get_payload(
		custom_data,
		with_data = should_update_data,
		with_static_data = TRUE)
	//get_payload() спит внутри ui_data()/ui_static_data(): за это время окно успевают
	//закрыть, а close() отдаёт его обратно в пул через release_lock() - пустая
	//нагрузка приехала бы уже чужому интерфейсу
	if(!payload || !can_send_update())
		return
	window.send_message("update", payload)
	COOLDOWN_START(src, refresh_cooldown, TGUI_REFRESH_FULL_UPDATE_COOLDOWN)

/**
 * public
 *
 * Send a partial update to the client (excludes static data).
 *
 * optional custom_data list Custom data to send instead of ui_data.
 * optional force bool Send an update even if UI is not interactive.
 */
/datum/tgui/proc/send_update(custom_data, force)
	if(!user?.client || !initialized || closing)
		return
	var/should_update_data = force || status >= UI_UPDATE
	var/list/payload = get_payload(
		custom_data,
		with_data = should_update_data)
	//см. send_full_update(): собирать нагрузку можно долго, а окно за это время
	//могло уйти в пул к другому интерфейсу
	if(!payload || !can_send_update())
		return
	window.send_message("update", payload)

/**
 * private
 *
 * Окно ещё наше и его есть кому показать: проверка обязана стоять после каждого
 * потенциально спящего вызова, а не только перед ним.
 */
/datum/tgui/proc/can_send_update()
	if(QDELETED(src) || closing || !window)
		return FALSE
	if(window.locked_by != src)
		return FALSE
	//именно QDELETED, а не проверка на null: qdel-нутый датум читается как живой,
	//пока его не соберёт GC, но Destroy у него уже отработал и звать ему проки нельзя
	return !isnull(user?.client) && !QDELETED(src_object)

/**
 * private
 *
 * Package the data to send to the UI, as JSON.
 *
 * return list
 */
/datum/tgui/proc/get_payload(custom_data, with_data, with_static_data)
	if(!user?.client || QDELETED(src_object))
		return
	var/list/json_data = list()
	json_data["config"] = list(
		"title" = title,
		"status" = status,
		"interface" = interface,
		//"refreshing" = refreshing,
		"refreshing" = FALSE,
		"window" = list(
			"key" = window_key,
			"size" = window_size,
			"fancy" = user.client.prefs.tgui_fancy,
			"locked" = user.client.prefs.tgui_lock,
			"scale" = user.client.get_window_scaling(),
		),
		"client" = list(
			"ckey" = user.client.ckey,
			"address" = user.client.address,
			"computer_id" = user.client.computer_id,
		),
		"user" = list(
			"name" = "[user]",
			"observer" = isobserver(user),
		),
	)
	var/data = custom_data
	if(!data && with_data)
		data = src_object.ui_data(user)
		//ui_data() имеет полное право уснуть - панель антагов, например, уходит в
		//jobban_isbanned() и ждёт ответа базы. Пока прок спит, окно успевают закрыть,
		//а Destroy() обнуляет и user, и src_object: собирать нагрузку больше не для кого
		if(QDELETED(src) || !user?.client || QDELETED(src_object))
			return
	if(data)
		json_data["data"] = data
	var/static_data
	if(with_static_data)
		static_data = src_object.ui_static_data(user)
		//ui_static_data() спит по тем же причинам, что и ui_data()
		if(QDELETED(src) || !user?.client || QDELETED(src_object))
			return
	if(static_data)
		json_data["static_data"] = static_data
	if(src_object.tgui_shared_states)
		json_data["shared"] = src_object.tgui_shared_states
	return json_data

/**
 * private
 *
 * Run an update cycle for this UI. Called internally by SStgui
 * every second or so.
 */
/datum/tgui/process(delta_time, force = FALSE)
	if(closing)
		return
	// Порядок важен: src_object мог быть обнулён в Destroy() или хардделнут, и
	// разыменование до проверки давало бы ровно тот же класс рантайма, что мы тут
	// и чиним. Проверка окна включает потерю лока: окно, уехавшее в пул, нам уже
	// не принадлежит - такой интерфейс надо закрыть, а не молча перестать обновлять.
	if(QDELETED(src_object) || !user || !window || window.locked_by != src)
		close(can_be_suspended = FALSE)
		return
	var/datum/host = src_object.ui_host(user)
	if(!host)
		close(can_be_suspended = FALSE)
		return
	// Validate ping. opened_at взводится в самом конце open(), уже после доставки
	// ассетов; пока он пуст, судить окно не по чему - null в арифметике DM это ноль,
	// и без проверки любое такое окно мгновенно считалось бы просроченным.
	if(!initialized && opened_at && world.time - opened_at > TGUI_PING_TIMEOUT)
		log_tgui(user, \
			"Error: Zombie window detected, killing it with fire.\n" \
			+ "window_id: [window.id]\n" \
			+ "opened_at: [opened_at]\n" \
			+ "world.time: [world.time]")
		close(can_be_suspended = FALSE)
		return
	// Update through a normal call to ui_interact
	if(status != UI_DISABLED && (autoupdate || force))
		src_object.ui_interact(user, src)
		return
	// Update status only
	var/needs_update = process_status()
	if(status <= UI_CLOSE)
		close()
		return
	if(needs_update)
		var/list/payload = get_payload()
		if(!payload || !can_send_update())
			return
		window.send_message("update", payload)

/**
 * private
 *
 * Updates the status, and returns TRUE if status has changed.
 */
/datum/tgui/proc/process_status()
	var/prev_status = status
	status = src_object.ui_status(user, state)
	if(parent_ui && parent_ui != 500)
		status = min(status, parent_ui.status)
	return prev_status != status

/**
 * private
 *
 * Callback for handling incoming tgui messages.
 */
/datum/tgui/proc/on_message(type, list/payload, list/href_list)
	// Pass act type messages to ui_act
	if(type && copytext(type, 1, 5) == "act/")
		var/act_type = copytext(type, 5)
		// Dedup: WebView2 can deliver the same Topic() call twice
		var/seq = text2num(href_list["seq"])
		if(seq && seq == last_act_seq)
			return FALSE
		if(seq)
			last_act_seq = seq
		#ifdef TGUI_DEBUGGING
		log_tgui(user, "Action: [act_type] [href_list["payload"]], Window: [window.id], Source: [src_object]")
		#endif
		process_status()
		if(src_object.ui_act(act_type, payload, src, state))
			SStgui.update_uis(src_object)
		return FALSE
	switch(type)
		if("ready")
			// Send a full update when the user manually refreshes the UI
			if(initialized)
				send_full_update()
			initialized = TRUE
		if("pingReply")
			initialized = TRUE
		if("suspend")
			close(can_be_suspended = TRUE)
		if("close")
			close(can_be_suspended = FALSE)
		if("log")
			if(href_list["fatal"])
				close(can_be_suspended = FALSE)
		if("setSharedState")
			if(status != UI_INTERACTIVE)
				return
			LAZYINITLIST(src_object.tgui_shared_states)
			src_object.tgui_shared_states[href_list["key"]] = href_list["value"]
			SStgui.update_uis(src_object)
		if("renderByondUi")
			var/byond_ui_id = payload ? payload["renderByondUi"] : null
			if(!byond_ui_id || LAZYLEN(open_byondui_elements) >= TGUI_MANAGED_BYONDUI_LIMIT)
				return

			LAZYOR(open_byondui_elements, byond_ui_id)
		if("unmountByondUi")
			var/byond_ui_id = payload ? payload["renderByondUi"] : null
			if(!byond_ui_id)
				return

			LAZYREMOVE(open_byondui_elements, byond_ui_id)
		if("fallback")
			#ifdef TGUI_DEBUGGING
			log_tgui(user, "Fallback Triggered: [href_list["payload"]], Window: [window.id], Source: [src_object]")
			#endif
			src_object.ui_fallback(payload)
