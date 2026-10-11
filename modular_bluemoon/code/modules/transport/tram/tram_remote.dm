/obj/item/assembly/control/transport/remote
	icon = 'modular_bluemoon/icons/obj/tram/tram_remote.dmi'
	icon_state = "tramremote_nis"
	item_state = "electronic"
	lefthand_file = 'icons/mob/inhands/misc/devices_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/devices_righthand.dmi'
	name = "tram remote"
	desc = "Пульт, который можно привязать к трамваю. Что может пойти не так?"
	w_class = WEIGHT_CLASS_TINY
	attachable = FALSE
	options = RAPID_MODE
	///desired tram destination
	var/destination
	COOLDOWN_DECLARE(tram_remote)

/obj/item/assembly/control/transport/remote/Initialize(mapload)
	. = ..()
	if(!id_tag)
		id_tag = assign_random_name()
	SStransport.hello(src, name, id_tag)
	update_appearance()

/obj/item/assembly/control/transport/remote/proc/select_destination(mob/user)
	var/list/available_platforms = list()
	for(var/obj/effect/landmark/transport/nav_beacon/tram/platform/platform as anything in SStransport.nav_beacons[specific_transport_id])
		available_platforms |= platform.name

	var/selected_platform = tgui_input_list(user, "Доступные платформы", "Куда едем?", available_platforms)
	if(isnull(selected_platform) || QDELETED(src))
		return
	for(var/obj/effect/landmark/transport/nav_beacon/tram/platform/potential_platform as anything in SStransport.nav_beacons[specific_transport_id])
		if(potential_platform.name == selected_platform)
			destination = potential_platform.platform_code
			break

	balloon_alert(user, "выбрано: [selected_platform]")
	to_chat(user, span_notice("Пульт теперь отправляет трамвай на платформу [selected_platform]."))

/obj/item/assembly/control/transport/remote/AltClick(mob/user)
	if(!user.canUseTopic(src, be_close = TRUE))
		return ..()
	if(!specific_transport_id)
		link_tram(user)
		return TRUE
	select_destination(user)
	return TRUE

/obj/item/assembly/control/transport/remote/CtrlClick(mob/user)
	if(loc != user)
		return ..()
	options ^= RAPID_MODE
	update_appearance()
	balloon_alert(user, "режим: [options & RAPID_MODE ? "быстрый" : "безопасный"]")
	return TRUE

/obj/item/assembly/control/transport/remote/CtrlShiftClick(mob/user)
	. = ..()
	if(!user.canUseTopic(src, be_close = TRUE))
		return
	link_tram(user)

/obj/item/assembly/control/transport/remote/examine(mob/user)
	. = ..()
	if(!specific_transport_id)
		. += span_notice("На экране горит крестик.")
		. += span_notice("Нажмите на пульт в руке, чтобы привязать его к трамваю.")
		return
	. += span_notice("Индикатор быстрого режима [options & RAPID_MODE ? "горит" : "не горит"].")
	if(!COOLDOWN_FINISHED(src, tram_remote))
		. += span_notice("На экране отсчёт: [DisplayTimeText(COOLDOWN_TIMELEFT(src, tram_remote), 1)].")
	else
		. += span_notice("Экран показывает готовность.")
	. += span_notice("Нажмите на пульт в руке, чтобы отправить трамвай.")
	. += span_notice("[EXAMINE_HINT("Alt-клик")] выбирает пункт назначения.")
	. += span_notice("[EXAMINE_HINT("Ctrl-клик")] переключает обход дверных датчиков.")
	. += span_notice("[EXAMINE_HINT("Ctrl-Shift-клик")] перепривязывает пульт к другому трамваю.")

/obj/item/assembly/control/transport/remote/update_icon_state()
	. = ..()
	icon_state = specific_transport_id ? "tramremote_ob" : "tramremote_nis"

/obj/item/assembly/control/transport/remote/update_overlays()
	. = ..()
	if(options & RAPID_MODE)
		. += mutable_appearance(icon, "tramremote_emag")

/obj/item/assembly/control/transport/remote/attack_self(mob/user)
	if(!specific_transport_id)
		link_tram(user)
		return

	if(!destination)
		select_destination(user)
		return

	if(!COOLDOWN_FINISHED(src, tram_remote))
		balloon_alert(user, "перезарядка: [DisplayTimeText(COOLDOWN_TIMELEFT(src, tram_remote), 1)]")
		return

	activate(user)
	COOLDOWN_START(src, tram_remote, 2 MINUTES)

///send our selected commands to the tram
/obj/item/assembly/control/transport/remote/activate(mob/user)
	if(!specific_transport_id)
		balloon_alert(user, "трамвай не привязан!")
		return
	if(!destination)
		balloon_alert(user, "не выбрана платформа!")
		return

	SEND_SIGNAL(src, COMSIG_TRANSPORT_REQUEST, specific_transport_id, destination, options)

/obj/item/assembly/control/transport/remote/proc/link_tram(mob/user)
	specific_transport_id = null
	var/list/transports_available = list()
	for(var/datum/transport_controller/linear/tram/tram as anything in SStransport.transports_by_type[TRANSPORT_TYPE_TRAM])
		transports_available |= tram.specific_transport_id

	specific_transport_id = tgui_input_list(user, "Доступные трамваи", "Выбор трамвая", transports_available)

	if(specific_transport_id)
		balloon_alert(user, "трамвай привязан")
	else
		balloon_alert(user, "привязка не удалась!")

	update_appearance()
