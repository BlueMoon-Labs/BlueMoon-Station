/obj/item/assembly/control/transport
	can_change_id = FALSE
	show_id = FALSE
	/// The ID of the tram we're linked to
	var/specific_transport_id = TRAMSTATION_LINE_1
	/// Options to be passed with the requests to the transport subsystem
	var/options = NONE
	/// Unique tag of this device in transport logs
	var/id_tag

/obj/item/assembly/control/transport/multitool_act(mob/living/user, obj/item/tool)
	var/list/available_platforms = list()
	for(var/obj/effect/landmark/transport/nav_beacon/tram/platform/platform as anything in SStransport.nav_beacons[specific_transport_id])
		available_platforms |= platform.name

	var/selected_platform = tgui_input_list(user, "Выберите платформу", "Платформа", available_platforms)
	var/obj/effect/landmark/transport/nav_beacon/tram/platform/change_platform
	for(var/obj/effect/landmark/transport/nav_beacon/tram/platform/destination as anything in SStransport.nav_beacons[specific_transport_id])
		if(destination.name == selected_platform)
			change_platform = destination
			break

	if(!change_platform || QDELETED(user) || QDELETED(src) || !user.canUseTopic(src, be_close = TRUE, no_dextery = FALSE, no_tk = TRUE))
		return TRUE

	if(get_dist(change_platform, src) > 15)
		balloon_alert(user, "слишком далеко!")
		return TRUE

	id = change_platform.platform_code
	balloon_alert(user, "платформа сменена")
	to_chat(user, span_notice("Теперь кнопка вызывает трамвай на платформу [change_platform.name]."))
	return TRUE

/obj/item/assembly/control/transport/proc/call_response(datum/source, list/relevant, response_code, response_info)
	SIGNAL_HANDLER
	if(!LAZYFIND(relevant, src))
		return
	switch(response_code)
		if(REQUEST_SUCCESS)
			say("Трамвай вызван на платформу.")

		if(REQUEST_FAIL)
			switch(response_info)
				if(BROKEN_BEYOND_REPAIR)
					say("Трамвай потерпел катастрофическую аварию. Пожалуйста, воспользуйтесь другим транспортом.")
				if(NOT_IN_SERVICE)
					say("Трамвай не обслуживается из-за отказа питания или неисправности. Обратитесь к ближайшему инженеру, чтобы проверить питание и контроллер.")
				if(INVALID_PLATFORM)
					say("Ошибка настройки кнопки. Пожалуйста, обратитесь к ближайшему инженеру.")
				if(TRANSPORT_IN_USE)
					say("Трамвай сейчас в пути, пожалуйста, подождите.")
				if(NO_CALL_REQUIRED)
					say("Трамвай уже здесь. Садитесь и выберите пункт назначения.")
				else
					say("Ошибка контроллера трамвая. Обратитесь к ближайшему инженеру или к сотруднику с доступом к телекоммуникациям, чтобы перезапустить контроллер.")

/obj/item/assembly/control/transport/call_button
	name = "tram call button"
	desc = "Небольшое устройство, которое подзывает трамвай."
	///ID to link to allow us to link to one specific tram in the world
	id = 0

/obj/item/assembly/control/transport/call_button/Initialize(mapload)
	. = ..()
	return INITIALIZE_HINT_LATELOAD

/obj/item/assembly/control/transport/call_button/LateInitialize()
	. = ..()
	if(!id_tag)
		id_tag = assign_random_name()
	SStransport.hello(src, name, id_tag)
	RegisterSignal(SStransport, COMSIG_TRANSPORT_RESPONSE, PROC_REF(call_response))

/obj/item/assembly/control/transport/call_button/activate()
	if(cooldown)
		return
	cooldown = TRUE
	addtimer(VARSET_CALLBACK(src, cooldown, FALSE), 2 SECONDS)

	SEND_SIGNAL(src, COMSIG_TRANSPORT_REQUEST, specific_transport_id, id)

/obj/machinery/button/transport/tram
	name = "tram request"
	desc = "Кнопка вызова трамвая. Внутри динамик с какой-то начинкой."
	icon = 'modular_bluemoon/icons/obj/machines/tram_button.dmi'
	icon_state = "tram"
	skin = "tram"
	can_alter_skin = FALSE
	device_type = /obj/item/assembly/control/transport/call_button
	req_access = list()
	id = 0
	/// The ID of the tram we're linked to
	var/specific_transport_id = TRAMSTATION_LINE_1

/// We allow borgs to use the button locally, but not the AI remotely
/obj/machinery/button/transport/tram/attack_ai(mob/user)
	if(isAI(user) || panel_open)
		return
	if(IsAdminGhost(user) || in_range(user, src))
		return attack_hand(user)
	to_chat(user, span_warning("Вы слишком далеко, чтобы нажать кнопку!"))

/obj/machinery/button/transport/tram/setup_device()
	. = ..()
	var/obj/item/assembly/control/transport/call_button/tram_device = device
	if(istype(tram_device))
		tram_device.specific_transport_id = specific_transport_id

/obj/machinery/button/transport/tram/examine(mob/user)
	. = ..()
	. += span_notice("На кнопке мелкая надпись...")
	. += span_notice("ЭТА КНОПКА ВЫЗЫВАЕТ ТРАМВАЙ! ОНА ИМ НЕ УПРАВЛЯЕТ! Куда ехать, выбирают на пульте в самом трамвае!")

MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/button/transport/tram, 32)
