/// Сколько показывает refcount() клиента из finish_logout_report(), когда держателей не осталось (замер живым клиентом).
#define LOGOUT_CLIENT_REFS_CLEAN 2

/mob
	/// Запись о логауте от /client/Del(): ссылка-текст на клиента, описание, цена Destroy, затем начало Logout.
	var/tmp/list/logout_report

/mob/Logout()
	var/logout_started = TICK_USAGE_REAL
	SEND_SIGNAL(src, COMSIG_MOB_CLIENT_LOGOUT, client)
	SEND_SIGNAL(src, COMSIG_MOB_LOGOUT)
	log_message("[key_name(src)] is no longer owning mob [src]([src.type])", LOG_OWNERSHIP)
	SStgui.on_logout(src)
	unset_machine()
	remove_from_player_list()
	//спатиал-грид: моб без клиента больше не числится в CLIENTS-канале
	clear_important_client_contents()
	..()

	if(loc)
		loc.on_log(FALSE)

	if(client)
		for(var/foo in client.player_details.post_logout_callbacks)
			var/datum/callback/CB = foo
			CB.Invoke()

	if(logout_report)
		logout_report += logout_started
		// Хвост new_player/Logout() после ..() ещё удаляет моба: итог подводит он, иначе счёт ссылок завышен.
		if(!isnewplayer(src))
			finish_logout_report()
	return TRUE

/// Логаут в кольцо медленной работы. Клиента BYOND освободит сразу после Logout: каждую лишнюю ссылку он ищет обходом мира.
/mob/proc/finish_logout_report()
	var/list/report = logout_report
	logout_report = null
	if(!SStick_spikes)
		return
	var/logout_ms = TICK_DELTA_TO_MS(TICK_USAGE_REAL - report[4])
	var/client/leaving = locate(report[1])
	var/leftover = istype(leaving) ? max(refcount(leaving) - LOGOUT_CLIENT_REFS_CLEAN, 0) : "?"
	var/open_windows = ""
	if(leftover && istype(leaving))
		open_windows = ", моб после Logout [type], окна tgui [logout_open_interfaces(leaving)]"
	leaving = null
	SStick_spikes.record_slow_work("логаут", "[report[2]], Logout [round(logout_ms, 0.1)]мс, лишних ссылок после Logout [leftover][open_windows]", report[3] + logout_ms)

/// Интерфейсы, чьи окна ещё заняты у уходящего клиента: подсказка, кто из держателей не отпустил его в ui_close().
/mob/proc/logout_open_interfaces(client/leaving)
	var/list/names = list()
	for(var/window_id in leaving.tgui_windows)
		var/datum/tgui_window/window = leaving.tgui_windows[window_id]
		if(window?.locked_by)
			names += window.locked_by.interface
	return length(names) ? jointext(names, "/") : "нет"

#undef LOGOUT_CLIENT_REFS_CLEAN
