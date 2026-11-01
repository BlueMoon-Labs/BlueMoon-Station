// MARK: Звуковые источники
//
// Сетевые сущности сами по себе ничего не слышат. Речь доходит до сети только через
// узлы-источники звука (интерком с включённым микрофоном и т.п.): такой узел пишет
// реплики в свой журнал, транслирует их сущностям внутри и консолям-слушателям.

/datum/component/netrun_node
	/// Последние услышанные реплики (только у источников звука)
	var/list/audio_log
	/// Консоли, подписанные на живой поток
	var/list/datum/netrun_console/listeners
	/// Скрытая запись при выключенном микрофоне - до этого времени
	var/tapped_until = 0

/datum/component/netrun_node/Destroy()
	for(var/datum/netrun_console/console as anything in listeners)
		console.listening -= src
	listeners = null
	return ..()

/datum/component/netrun_node/proc/hear_line(atom/movable/speaker, raw_message)
	var/speaker_name = speaker ? speaker.GetVoice() : "неизвестный"
	var/line = "[speaker_name]: «[raw_message]»"
	LAZYADD(audio_log, "[STATION_TIME_TIMESTAMP("hh:mm:ss", world.time)] [line]")
	if(length(audio_log) > 20)
		audio_log.Cut(1, length(audio_log) - 19)
	touch()
	for(var/mob/camera/netrun_entity/entity as anything in entities)
		to_chat(entity, span_radio("\[[get_name()]\] [span_name(speaker_name)] говорит, «[raw_message]»"))
	for(var/datum/netrun_console/console as anything in listeners)
		if(console.node_level(src) < NETRUN_ACCESS_USER)
			stop_listening(console)
			continue
		console.log_line("\[МИК [address]\] [line]", "label")

/datum/component/netrun_node/proc/stop_listening(datum/netrun_console/console)
	LAZYREMOVE(listeners, console)
	console.listening -= src

/datum/netrun_console
	/// Узлы-источники звука, на которые подписана консоль
	var/list/datum/component/netrun_node/listening = list()

/datum/netrun_console/Destroy()
	for(var/datum/component/netrun_node/node as anything in listening)
		LAZYREMOVE(node.listeners, src)
	listening = null
	return ..()

// MARK: Интерком

/obj/item/radio/intercom/Initialize(mapload, ndir, building)
	. = ..()
	AddComponent(/datum/component/netrun_audio_transceiver/intercom)
	AddComponent(/datum/component/netrun_node, NETRUN_NODE_INTERCOM, list("mic_toggle", "audio_log", "listen", "audio_tap"), 1, list(ACCESS_TCOMSAT))

/obj/item/radio/intercom/netrun_online(remote = TRUE)
	return on && !emped

/obj/item/radio/intercom/netrun_status()
	. = list()
	. += "Микрофон: [broadcasting ? "включён" : "выключен"]"
	. += "Динамик: [listening ? "включён" : "выключен"], частота [format_frequency(frequency)]"

/obj/item/radio/intercom/Hear(message, atom/movable/speaker, message_langs, raw_message, radio_freq, list/spans, message_mode, atom/movable/source)
	. = ..()
	if(message_mode == MODE_INTERCOM || !on || emped || speaker == src)
		return
	var/datum/component/netrun_node/node = GetComponent(/datum/component/netrun_node)
	if(!node || (!LAZYLEN(node.entities) && !LAZYLEN(node.listeners)))
		return
	if(radio_freq)
		// Пришло по радио - слышно, если включён динамик (приём)
		if(!listening)
			return
	else
		// Местная речь рядом - ловит только включённый микрофон (или скрытая запись)
		if(!broadcasting && world.time >= node.tapped_until)
			return
		if(!speaker || get_dist(src, speaker) > canhear_range)
			return
		if(message_mode == MODE_WHISPER || message_mode == MODE_WHISPER_CRIT)
			raw_message = stars(raw_message)
	node.hear_line(speaker, raw_message)

/datum/netrun_command/mic_toggle
	id = "mic_toggle"
	name = "Микрофон"
	desc = "Включить или выключить микрофон интеркома. Заметно со стороны."
	icon = "microphone"
	trace = 4

/datum/netrun_command/mic_toggle/execute(datum/component/netrun_node/node, datum/netrun_console/console)
	var/obj/item/radio/intercom/intercom = node.parent
	intercom.broadcasting = !intercom.broadcasting
	return "Микрофон [intercom.broadcasting ? "включён" : "выключен"]."

/datum/netrun_command/audio_log
	id = "audio_log"
	read_only = TRUE
	name = "Журнал записи"
	desc = "Вывести последние реплики, записанные источником."
	icon = "list"
	trace = 2

/datum/netrun_command/audio_log/execute(datum/component/netrun_node/node, datum/netrun_console/console)
	if(!LAZYLEN(node.audio_log))
		return "Журнал записи пуст."
	return "Журнал записи [node.address]:\n[jointext(node.audio_log.Copy(max(1, length(node.audio_log) - 9)), "\n")]"

/datum/netrun_command/listen
	id = "listen"
	name = "Слушать поток"
	desc = "Подписать консоль на живой поток реплик этого источника (пока микрофон включён)."
	icon = "headphones"
	trace = 3

/datum/netrun_command/listen/execute(datum/component/netrun_node/node, datum/netrun_console/console)
	if(node in console.listening)
		node.stop_listening(console)
		return "Подписка на поток [node.address] снята."
	LAZYADD(node.listeners, console)
	console.listening += node
	return "Консоль подписана на поток [node.address]."

/datum/netrun_command/audio_tap
	id = "audio_tap"
	name = "Скрытая запись"
	desc = "Писать звук при выключенном микрофоне в течение двух минут. Индикатор не загорается."
	access = NETRUN_ACCESS_ROOT
	icon = "user-secret"
	trace = 10
	danger = TRUE

/datum/netrun_command/audio_tap/execute(datum/component/netrun_node/node, datum/netrun_console/console)
	node.tapped_until = world.time + 2 MINUTES
	return "Скрытая запись активна на 2 минуты."
