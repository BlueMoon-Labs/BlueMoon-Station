/*!
 * Copyright (c) 2020 Aleksej Komarov
 * SPDX-License-Identifier: MIT
 */

/**
 * tgui subsystem
 *
 * Contains all tgui state and subsystem code.
 *
 */

SUBSYSTEM_DEF(tgui)
	name = "tgui"
	wait = 9
	flags = SS_NO_INIT
	priority = FIRE_PRIORITY_TGUI
	runlevels = RUNLEVEL_LOBBY | RUNLEVELS_DEFAULT

	/// A list of UIs scheduled to process
	var/list/current_run = list()
	/// A list of open UIs
	var/list/open_uis = list()
	/// A list of open UIs, grouped by src_object.
	var/list/open_uis_by_src = list()
	/// The HTML base used for all UIs.
	var/basehtml

/datum/controller/subsystem/tgui/PreInit()
	basehtml = file2text('tgui/public/tgui.html')
	if(CONFIG_GET(flag/emergency_tgui_logging))
		var/has_version_marker = findtext(basehtml, "bridge-localhost-fallback-v2") ? "present" : "missing"
		var/has_host_fallback = findtext(basehtml, "hasKnownBridge || hostLooksLocal") ? "present" : "missing"
		log_tgui(null,
			"PreInit basehtml_md5=[md5(basehtml)] version_marker=[has_version_marker] host_fallback=[has_host_fallback]",
			context = "SStgui/PreInit")

/datum/controller/subsystem/tgui/Shutdown()
	close_all_uis()

/datum/controller/subsystem/tgui/stat_entry(msg)
	msg = "P:[length(open_uis)]"
	return ..()

/datum/controller/subsystem/tgui/fire(resumed = FALSE)
	// Инструментация адаптивного профиля (см. базовый subsystem.dm): прогон SStgui
	// в проде стабильно занимал 20-26мс, а разбить его по конкретным окнам было
	// нечем - ui_data одного интерфейса может рисовать флэт-икону человека, и в
	// общем времени подсистемы это никак не видно.
	var/slice_start_usage = TICK_USAGE
	if(!resumed)
		src.current_run = open_uis.Copy()
		current_pass_cost_ms = 0
	// Cache for sanic speed (lists are references anyways)
	var/list/current_run = src.current_run
	var/profiling = profile_armed
	while(current_run.len)
		var/datum/tgui/ui = current_run[current_run.len]
		current_run.len--
		// TODO: Move user/src_object check to process()
		if(ui?.user && ui.src_object)
			if(profiling)
				var/item_start_usage = TICK_USAGE
				//тип интерфейса, а не датума tgui: все окна - один /datum/tgui.
				//Держателя запоминаем до process(): он умеет закрыть окно и обнулить src_object.
				var/datum/profiled_object = ui.src_object
				var/item_type = profiled_object.type
				ui.process(wait * 0.1)
				profile_note(item_type, max(0, TICK_DELTA_TO_MS(TICK_USAGE - item_start_usage)), profiled_object)
			else
				ui.process(wait * 0.1)
		else
			//чистка одного open_uis оставляла интерфейс в open_uis_by_src и в
			//user.tgui_open_uis: снимаем с учёта целиком
			unregister_ui(ui)
		if(MC_TICK_CHECK)
			current_pass_cost_ms += max(0, TICK_DELTA_TO_MS(TICK_USAGE - slice_start_usage))
			return

	current_pass_cost_ms += max(0, TICK_DELTA_TO_MS(TICK_USAGE - slice_start_usage))
	on_pass_finished(length(open_uis))

/**
 * public
 *
 * Requests a usable tgui window from the pool.
 * Returns null if pool was exhausted.
 *
 * required user mob
 * return datum/tgui
 */
/datum/controller/subsystem/tgui/proc/request_pooled_window(mob/user)
	if(!user.client)
		return null
	var/list/windows = user.client.tgui_windows
	var/window_id
	var/datum/tgui_window/window
	var/window_found = FALSE
	// Find a usable window
	for(var/i in 1 to TGUI_WINDOW_HARD_LIMIT)
		window_id = TGUI_WINDOW_ID(i)
		window = windows[window_id]
		// As we are looping, create missing window datums
		if(!window)
			window = new(user.client, window_id, pooled = TRUE)
		// Skip windows with acquired locks
		if(window.locked)
			continue
		if(window.status == TGUI_WINDOW_READY)
			return window
		if(window.status == TGUI_WINDOW_CLOSED)
			window.status = TGUI_WINDOW_LOADING
			window_found = TRUE
			break
	if(!window_found)
		log_tgui(user, "Error: Pool exhausted",
			context = "SStgui/request_pooled_window")
		return null
	return window

/**
 * public
 *
 * Force closes all tgui windows.
 *
 * required user mob
 */
/datum/controller/subsystem/tgui/proc/force_close_all_windows(mob/user)
	if(!user?.client)
		return
	log_tgui(user, context = "SStgui/force_close_all_windows")
	force_close_client_windows(user.client)

/**
 * public
 *
 * Гасит окна tgui в скине и сбрасывает реестр окон клиента.
 *
 * Нужно на подключении: реестр tgui_windows живёт на /client, у нового клиента он
 * пуст, а окна прошлого подключения переживают реконнект внутри скина и продолжают
 * слать ready. На каждый такой ready сервер отвечает "нет такого датума" и шлёт
 * browse(null) в окно, которого для него не существует - клиент ретраит тридцать
 * секунд, игрок видит сломанный интерфейс и идёт жать Fix chat.
 *
 * required user_client client
 */
/datum/controller/subsystem/tgui/proc/force_close_client_windows(client/user_client)
	if(!user_client)
		return
	user_client.tgui_windows = list()
	for(var/i in 1 to TGUI_WINDOW_HARD_LIMIT)
		user_client << browse(null, "window=[TGUI_WINDOW_ID(i)]")

/**
 * public
 *
 * Force closes the tgui window by window_id.
 *
 * required user mob
 * required window_id string
 */
/datum/controller/subsystem/tgui/proc/force_close_window(mob/user, window_id)
	var/closed_uis = 0
	// Close all tgui datums based on window_id.
	for(var/datum/tgui/ui in user.tgui_open_uis)
		if(ui.window && ui.window.id == window_id)
			ui.close(can_be_suspended = FALSE)
			closed_uis++
	// Игрок закрыл окно крестиком - это штатное событие, а не происшествие: за
	// прод-раунд сюда приходило 500 строк, и ни одна ничего не диагностировала.
	// Интересен только случай, когда окно закрылось, а датума под него не нашлось.
	if(!closed_uis)
		log_tgui(user, "no matching tgui datum for window_id=[window_id]", context = "SStgui/force_close_window")
	// Unset machine just to be sure.
	user.unset_machine()
	// Close window directly just to be sure.
	user << browse(null, "window=[window_id]")

/**
 * public
 *
 * Try to find an instance of a UI, and push an update to it.
 *
 * required user mob The mob who opened/is using the UI.
 * required src_object datum The object/datum which owns the UI.
 * optional ui datum/tgui The UI to be updated, if it exists.
 * optional force_open bool If the UI should be re-opened instead of updated.
 *
 * return datum/tgui The found UI.
 */
/datum/controller/subsystem/tgui/proc/try_update_ui(
		mob/user,
		datum/src_object,
		datum/tgui/ui)
	// Look up a UI if it wasn't passed
	if(isnull(ui))
		ui = get_open_ui(user, src_object)
	// Couldn't find a UI.
	if(isnull(ui))
		return null
	ui.process_status()
	// UI ended up with the closed status
	// or is actively trying to close itself.
	// FIXME: Doesn't actually fix the paper bug.
	if(ui.status <= UI_CLOSE)
		ui.close()
		return null
	ui.send_update()
	return ui

/**
 * public
 *
 * Get a open UI given a user and src_object.
 *
 * required user mob The mob who opened/is using the UI.
 * required src_object datum The object/datum which owns the UI.
 *
 * return datum/tgui The found UI.
 */
/datum/controller/subsystem/tgui/proc/get_open_ui(mob/user, datum/src_object)
	var/key = "[REF(src_object)]"
	// No UIs opened for this src_object
	if(isnull(open_uis_by_src[key]) || !istype(open_uis_by_src[key], /list))
		return null
	for(var/datum/tgui/ui in open_uis_by_src[key])
		// Make sure we have the right user
		if(ui.user == user)
			return ui
	return null

/**
 * public
 *
 * Gets all open UIs on a src object
 */
/datum/controller/subsystem/tgui/proc/get_all_open_uis(datum/src_object)
	var/key = "[REF(src_object)]"
	// No UIs opened for this src_object
	if(isnull(open_uis_by_src[key]) || !istype(open_uis_by_src[key], /list))
		return list()
	return open_uis_by_src[key]

/**
 * public
 *
 * Update all UIs attached to src_object.
 *
 * required src_object datum The object/datum which owns the UIs.
 *
 * return int The number of UIs updated.
 */
/datum/controller/subsystem/tgui/proc/update_uis(datum/src_object)
	var/count = 0
	var/key = "[REF(src_object)]"
	// No UIs opened for this src_object
	if(isnull(open_uis_by_src[key]) || !istype(open_uis_by_src[key], /list))
		return count
	var/list/uis = open_uis_by_src[key]
	//обходим копию: снятие с учёта правит тот же список
	for(var/datum/tgui/ui in uis.Copy())
		// Check if UI is valid.
		if(ui.src_object && ui.user && ui.src_object.ui_host(ui.user))
			ui.process(wait * 0.1, force = 1)
			count++
			continue
		//пустой ui_host сам по себе может быть временным, а вот интерфейс без
		//src_object или без пользователя мёртв - его запись копилась до конца раунда
		if(ui.src_object && ui.user)
			continue
		unregister_ui(ui)
		qdel(ui)
	return count

/**
 * public
 *
 * Close all UIs attached to src_object.
 *
 * required src_object datum The object/datum which owns the UIs.
 *
 * return int The number of UIs closed.
 */
/datum/controller/subsystem/tgui/proc/close_uis(datum/src_object)
	var/count = 0
	if(!(src_object?.datum_flags & DF_HAS_OPEN_UI))
		return count
	var/key = "[REF(src_object)]"
	// No UIs opened for this src_object
	if(isnull(open_uis_by_src[key]) || !istype(open_uis_by_src[key], /list))
		if(src_object)
			src_object.datum_flags &= ~DF_HAS_OPEN_UI
		return count
	var/list/uis = open_uis_by_src[key]
	//обходим копию: close() снимает интерфейс с учёта прямо из этого списка
	for(var/datum/tgui/ui in uis.Copy())
		// Check if UI is valid.
		if(ui.src_object && ui.user && ui.src_object.ui_host(ui.user))
			ui.close()
			count++
			continue
		//хост уже мёртв - штатный close по нему не пройдёт, но и копить запись в
		//open_uis_by_src до конца раунда незачем: close_uis зовут из /atom/Destroy
		unregister_ui(ui)
		qdel(ui)
	return count

/**
 * public
 *
 * Close all UIs regardless of their attachment to src_object.
 *
 * return int The number of UIs closed.
 */
/datum/controller/subsystem/tgui/proc/close_all_uis()
	var/count = 0
	for(var/key in open_uis_by_src.Copy())
		var/list/uis = open_uis_by_src[key]
		if(!islist(uis))
			continue
		for(var/datum/tgui/ui in uis.Copy())
			// Check if UI is valid.
			if(ui.src_object && ui.user && ui.src_object.ui_host(ui.user))
				ui.close()
				count++
				continue
			unregister_ui(ui)
			qdel(ui)
	return count

/**
 * public
 *
 * Update all UIs belonging to a user.
 *
 * required user mob The mob who opened/is using the UI.
 * optional src_object datum If provided, only update UIs belonging this src_object.
 *
 * return int The number of UIs updated.
 */
/datum/controller/subsystem/tgui/proc/update_user_uis(mob/user, datum/src_object)
	var/count = 0
	if(length(user?.tgui_open_uis) == 0)
		return count
	for(var/datum/tgui/ui in user.tgui_open_uis.Copy())
		if(isnull(src_object) || ui.src_object == src_object)
			ui.process(wait * 0.1, force = 1)
			count++
	return count

/**
 * public
 *
 * Close all UIs belonging to a user.
 *
 * required user mob The mob who opened/is using the UI.
 * optional src_object datum If provided, only close UIs belonging this src_object.
 *
 * return int The number of UIs closed.
 */
/datum/controller/subsystem/tgui/proc/close_user_uis(mob/user, datum/src_object, logout = FALSE)
	var/count = 0
	if(length(user?.tgui_open_uis) == 0)
		return count
	for(var/datum/tgui/ui in user.tgui_open_uis.Copy())
		if(isnull(src_object) || ui.src_object == src_object)
			ui.close(logout = logout)
			count++
	return count

/**
 * private
 *
 * Add a UI to the list of open UIs.
 *
 * required ui datum/tgui The UI to be added.
 */
/datum/controller/subsystem/tgui/proc/on_open(datum/tgui/ui)
	//open() спит на ассетах: qdel датума за это время обнуляет user через Destroy
	if(QDELETED(ui) || isnull(ui.user))
		return
	var/key = "[REF(ui.src_object)]"
	if(isnull(open_uis_by_src[key]) || !istype(open_uis_by_src[key], /list))
		open_uis_by_src[key] = list()
	if(ui.src_object)
		ui.src_object.datum_flags |= DF_HAS_OPEN_UI
	//ключ запоминаем на самом интерфейсе: к моменту снятия с учёта src_object
	//могли уже обнулить, и пересчёт "[REF(ui.src_object)]" промахивался мимо записи
	ui.registered_src_key = key
	ui.user.tgui_open_uis |= ui
	var/list/uis = open_uis_by_src[key]
	uis |= ui
	open_uis |= ui

/**
 * private
 *
 * Remove a UI from the list of open UIs.
 *
 * required ui datum/tgui The UI to be removed.
 *
 * return bool If the UI was removed or not.
 */
/datum/controller/subsystem/tgui/proc/on_close(datum/tgui/ui)
	return unregister_ui(ui)

/**
 * private
 *
 * Безусловно снимает интерфейс с учёта во всех трёх списках подсистемы.
 *
 * Прежний on_close выходил `return FALSE` ещё до чистки, если запись в
 * open_uis_by_src не нашлась - а close() сразу делал qdel(src), и удалённый
 * датум оставался и в open_uis, и в user.tgui_open_uis (вложенные списки,
 * поэтому реф-сканер их и не видел).
 *
 * required ui datum/tgui The UI to be removed.
 *
 * return bool Нашлась ли запись в open_uis_by_src.
 */
/datum/controller/subsystem/tgui/proc/unregister_ui(datum/tgui/ui)
	// Remove it from the list of processing UIs.
	open_uis.Remove(ui)
	//current_run - копия open_uis на текущий проход. Обычно она рассасывается за
	//пару тиков, но подсистема, вставшая на паузу или споткнувшаяся о рантайм,
	//держала бы закрытый интерфейс со всем его user/src_object до нового прохода.
	current_run.Remove(ui)
	if(isnull(ui))
		return FALSE
	// If the user exists, remove it from them too.
	if(ui.user)
		ui.user.tgui_open_uis.Remove(ui)
	//ключ, под которым интерфейс реально записан; пересчёт по src_object не годится
	var/key = ui.registered_src_key
	ui.registered_src_key = null
	if(isnull(key))
		//интерфейс не регистрировали или уже сняли: у src_object могут быть
		//чужие открытые окна, гасить его флаг за них нельзя
		return FALSE
	var/list/uis = open_uis_by_src[key]
	if(!islist(uis))
		open_uis_by_src.Remove(key)
		if(ui.src_object)
			ui.src_object.datum_flags &= ~DF_HAS_OPEN_UI
		return FALSE
	uis.Remove(ui)
	if(length(uis) == 0)
		open_uis_by_src.Remove(key)
		if(ui.src_object)
			ui.src_object.datum_flags &= ~DF_HAS_OPEN_UI
	return TRUE

/**
 * private
 *
 * Handle client logout, by closing all their UIs.
 *
 * required user mob The mob which logged out.
 *
 * return int The number of UIs closed.
 */
/datum/controller/subsystem/tgui/proc/on_logout(mob/user)
	close_user_uis(user, logout = TRUE)

/**
 * private
 *
 * Handle clients switching mobs, by transferring their UIs.
 *
 * required user source The client's original mob.
 * required user target The client's new mob.
 *
 * return bool If the UIs were transferred.
 */
/datum/controller/subsystem/tgui/proc/on_transfer(mob/source, mob/target)
	// The old mob had no open UIs.
	if(length(source?.tgui_open_uis) == 0)
		return FALSE
	if(isnull(target.tgui_open_uis) || !istype(target.tgui_open_uis, /list))
		target.tgui_open_uis = list()
	// Transfer all the UIs.
	for(var/datum/tgui/ui in source.tgui_open_uis)
		// Inform the UIs of their new owner.
		ui.user = target
		target.tgui_open_uis.Add(ui)
	// Clear the old list.
	source.tgui_open_uis.Cut()
	return TRUE
