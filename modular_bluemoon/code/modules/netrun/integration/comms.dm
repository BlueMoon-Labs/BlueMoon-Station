// MARK: Общение в сети
//
// 1. Виртуальный КПК сущности: она видна в контактах NT-мессенджера, сообщения идут через телекомы.
// 2. Канал NTNRC #noosphere: общий чат сущностей и консолей, экипаж может зайти обычным чат-клиентом.

#define NETRUN_ENTITY_JOB "Сетевая сущность"

// MARK: Виртуальный КПК

/obj/item/modular_computer/pda/netrun
	name = "virtual messenger"
	desc = "Программная эмуляция КПК, живущая внутри сетевого процесса."
	has_pda_programs = FALSE
	starting_programs = list(/datum/computer_file/program/messenger)

/obj/item/modular_computer/pda/netrun/Initialize(mapload)
	. = ..()
	enabled = TRUE

/obj/item/modular_computer/pda/netrun/check_power_override()
	return TRUE

/obj/item/modular_computer/pda/netrun/ui_state(mob/user)
	return GLOB.always_state

// Звуки виртуального КПК не должны звучать на клетке, где «стоит» сущность
/obj/item/modular_computer/pda/netrun/send_sound()
	return

/obj/item/modular_computer/pda/netrun/ring(ringtone, list/balloon_alertees)
	return

/obj/item/modular_computer/pda/netrun/alert_call(datum/computer_file/program/caller, alerttext, sound)
	if(alerttext && ismob(loc))
		to_chat(loc, span_notice("[icon2html(src, loc)] [alerttext]"))

/mob/camera/netrun_entity
	var/obj/item/modular_computer/pda/netrun/messenger_pda
	var/datum/action/innate/netrun_messenger/messenger_action

/mob/camera/netrun_entity/Initialize(mapload, datum/component/netrun_node/start)
	. = ..()
	if(. == INITIALIZE_HINT_QDEL || !has_messenger)
		return
	messenger_pda = new(src)
	messenger_action = new
	messenger_action.Grant(src)

/mob/camera/netrun_entity/Destroy()
	QDEL_NULL(messenger_pda)
	QDEL_NULL(messenger_action)
	return ..()

/// Задать имя сущности - и подписать им виртуальный КПК
/mob/camera/netrun_entity/proc/set_net_name(new_name, job = NETRUN_ENTITY_JOB)
	name = new_name
	real_name = new_name
	messenger_pda?.update_label(new_name, job)

/mob/camera/netrun_entity/canUseTopic(atom/movable/M, be_close = FALSE, no_dextery = FALSE, no_tk = FALSE, check_resting = FALSE, silent = FALSE)
	return M == messenger_pda

/mob/camera/netrun_entity/proc/open_messenger()
	if(!messenger_pda)
		return
	var/datum/computer_file/program/messenger/app = locate() in messenger_pda.get_all_files()
	if(!app)
		return
	app.computer = messenger_pda
	messenger_pda.active_program = app
	app.program_state = PROGRAM_STATE_ACTIVE
	messenger_pda.ui_interact(src)

/datum/action/innate/netrun_messenger
	name = "Мессенджер"
	desc = "Открыть виртуальный КПК."
	button_icon_state = "pda"
	icon_icon = 'icons/obj/pda_alt.dmi'
	background_icon_state = "bg_tech_blue"

/datum/action/innate/netrun_messenger/Activate()
	var/mob/camera/netrun_entity/entity = owner
	if(istype(entity))
		entity.open_messenger()

/// Сущность не живая - штатный мессенджер её не уведомляет, делаем это сами
/datum/computer_file/program/messenger/receive_message(datum/signal/subspace/messaging/tablet_message/signal)
	. = ..()
	if(!. || !istype(computer, /obj/item/modular_computer/pda/netrun))
		return
	var/mob/camera/netrun_entity/entity = computer.loc
	if(!istype(entity) || signal.data["rigged"])
		return
	var/sender = signal.format_sender()
	to_chat(entity, span_notice("Входящее сообщение от [span_name(sender)]: «[signal.format_message()]» (кнопка «Мессенджер» — ответить)"))
	SEND_SOUND(entity, sound('sound/machines/twobeep_high.ogg', volume = 40))

// MARK: Канал #noosphere

/datum/controller/subsystem/netrun
	var/datum/ntnet_conversation/net_channel

/datum/controller/subsystem/netrun/proc/get_net_channel()
	if(QDELETED(net_channel))
		net_channel = new
		net_channel.title = "#noosphere"
		net_channel.strong = TRUE
		net_channel.add_status_message("Канал резидентных процессов сети станции.")
	return net_channel

/datum/ntnet_conversation/add_message(message, username)
	. = ..()
	if(src != SSnetrun.net_channel)
		return
	SEND_SIGNAL(SSnetrun, COMSIG_NETRUN_CHAT_CHANGED)
	for(var/mob/camera/netrun_entity/entity as anything in SSnetrun.entities)
		if(entity.client && entity.console?.has_uplink())
			to_chat(entity, span_notice("<b>#noosphere</b> [span_name(username)]: [message]"))

/datum/netrun_console
	/// Псевдоним в канале #noosphere
	var/handle

/datum/netrun_console/proc/get_handle()
	if(!handle)
		handle = "anon-[uppertext(copytext(md5(REF(src)), 1, 5))]"
	return handle

/datum/netrun_console/entity/get_handle()
	var/mob/camera/netrun_entity/entity = host
	return entity?.real_name || ..()

/datum/netrun_console/proc/chat_send(text)
	if(!has_uplink())
		log_line("Нет связи с NTnet.", "bad")
		return
	text = trim(copytext_char(sanitize(text), 1, 300))
	if(!length(text))
		return
	var/datum/ntnet_conversation/channel = SSnetrun.get_net_channel()
	channel.add_message(text, get_handle())
	if(operator)
		operator.log_talk(text, LOG_CHAT, tag = "#noosphere as [get_handle()]")

/datum/netrun_console/proc/chat_data()
	var/datum/ntnet_conversation/channel = SSnetrun.net_channel
	return list(
		"handle" = get_handle(),
		"messages" = channel ? channel.messages.Copy(max(1, length(channel.messages) - 29)) : list(),
	)

#undef NETRUN_ENTITY_JOB
