/*!
 * Copyright (c) 2020 Aleksej Komarov
 * SPDX-License-Identifier: MIT
 */

/client/var/datum/tgui_panel/tgui_panel
/// When TRUE, the tgui panel will not auto-switch to new UI on load.
/// Set when the user explicitly chooses "switch to old ui" via Fix Chat.
/client/var/use_legacy_chat = FALSE
/// Сколько вопросов Fix chat открыто: пока игрок решает, не перейти ли на старый чат, сообщения идут и туда.
/client/var/chat_fix_pending = 0
/// world.time последнего .update_ping: молчит ли вместе с панелью и DS-путь.
/client/var/ping_reply_at = 0
/// Кольцо сообщений, ушедших только в панель: при переходе на старый чат они проигрываются туда.
/client/var/list/chat_replay
/client/var/chat_replay_next = 1
/client/var/chat_replay_count = 0

#if defined(UNIT_TESTS) || defined(SPACEMAN_DMM)
/// Пока тест держит здесь список, копии в старый output пишутся в него парами (получатель, html), а не клиенту.
GLOBAL_LIST(unit_test_legacy_chat_capture)
#endif

/**
 * Нужно ли слать сообщение ещё и в старый output. Пока панель работает, он скрыт,
 * и копия каждой строки - лишний пакет клиенту. Не готова, упала или замолчала - шлём.
 * Молчание панели при молчащем DS-пути - очередь у клиента, а не мёртвая панель.
 */
/proc/chat_needs_legacy_output(legacy_chosen, datum/tgui_panel/panel, ds_alive)
	return legacy_chosen || !panel?.delivers_chat(ds_alive)

/**
 * Копия сообщений в старый output, а пока она не нужна - в кольцо повтора.
 * html - готовый текст, когда сообщение одно.
 */
/proc/legacy_chat_output(client/target, list/messages, html)
	var/datum/tgui_panel/panel = target.tgui_panel
	// DS-путь нужен, только пока панель молчит: тогда и считаем поток, он дороже прочего.
	var/silent_ds_alive = panel?.silent() && legacy_chat_ds_alive(target)
	if(!chat_needs_legacy_output(target.use_legacy_chat || target.chat_fix_pending, panel, silent_ds_alive))
		if(!target.chat_replay)
			target.chat_replay = new /list(CHAT_LEGACY_REPLAY_LIMIT)
		var/list/ring = target.chat_replay
		for(var/list/message as anything in messages)
			ring[target.chat_replay_next] = message
			target.chat_replay_next = target.chat_replay_next % CHAT_LEGACY_REPLAY_LIMIT + 1
		target.chat_replay_count = min(target.chat_replay_count + length(messages), CHAT_LEGACY_REPLAY_LIMIT)
		return
	legacy_chat_replay(target)
	if(html)
		legacy_chat_send(target, html)
		return
	for(var/list/message as anything in messages)
		legacy_chat_send(target, message_to_html(message))

/**
 * Отвечает ли DS-путь, пока панель молчит. Неактивному пинги не шлются - судим по одной панели.
 * Под потоком чата молчат оба пути: это очередь у клиента, а не мёртвая панель.
 */
/proc/legacy_chat_ds_alive(client/target)
	if(target.ping_diag?.flooded(REALTIMEOFDAY))
		return FALSE
	return ping_skips_inactive(target.last_activity) || world.time - target.ping_reply_at <= TGUI_PANEL_SILENT_LIMIT

/// Проиграть в старый output всё, что ушло только в панель, от старого к новому.
/proc/legacy_chat_replay(client/target)
	var/count = target.chat_replay_count
	var/list/ring = target.chat_replay
	var/next = target.chat_replay_next
	target.chat_replay = null
	target.chat_replay_next = 1
	target.chat_replay_count = 0
	if(!count)
		return
	for(var/i in 0 to count - 1)
		legacy_chat_send(target, message_to_html(ring[(next - 1 - count + i + CHAT_LEGACY_REPLAY_LIMIT) % CHAT_LEGACY_REPLAY_LIMIT + 1]))

/proc/legacy_chat_send(client/target, html)
#if defined(UNIT_TESTS) || defined(SPACEMAN_DMM)
	if(GLOB.unit_test_legacy_chat_capture)
		GLOB.unit_test_legacy_chat_capture += list(list(target, html))
		return
#endif
	SEND_TEXT(target, html)

/**
 * tgui panel / chat troubleshooting verb
 */
/client/verb/fix_tgui_panel()
	set name = "Fix chat"
	set category = "OOC"
	var/action
	log_tgui(src, "Started fixing.", context = "verb/fix_tgui_panel")

	chat_fix_pending++
	nuke_chat()

	// Failed to fix, using tgalert as fallback
	action = tgalert(src, "Did that work?", "", "Yes", "No, switch to old ui")
	chat_fix_pending = max(chat_fix_pending - 1, 0)
	if (action == "No, switch to old ui")
		use_legacy_chat = TRUE
		winset(src, "legacy_output_selector", "left=output_legacy")
		log_tgui(src, "Failed to fix.", context = "verb/fix_tgui_panel")

/client/proc/nuke_chat()
	legacy_chat_replay(src)
	// Reset legacy chat flag — user is attempting to use new UI
	use_legacy_chat = FALSE
	// Catch all solution (kick the whole thing in the pants)
	winset(src, "legacy_output_selector", "left=output_legacy")
	if(!tgui_panel || !istype(tgui_panel))
		log_tgui(src, "tgui_panel datum is missing",
			context = "verb/fix_tgui_panel")
		tgui_panel = new(src)
	tgui_panel.initialize(force = TRUE)
	// The on_message("ready") handler will switch to output_browser
	// when the panel is actually loaded, respecting use_legacy_chat.

/mob/verb/fix_overlays()
	set name = "Fix Overlays"
	set category = "OOC"

	cut_overlays()
	regenerate_icons()
