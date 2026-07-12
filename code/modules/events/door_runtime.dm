/datum/round_event_control/door_runtime
	name = "Door Runtime"
	typepath = /datum/round_event/door_runtime
	max_occurrences = 1
	min_players = 10
	weight = 50
	category = EVENT_CATEGORY_AI
	severity = DIRECTOR_SEVERITY_MINOR
	family = "door_malf" // общая пауза с Grey Tide
	disruption = DIRECTOR_DISRUPTION_DISRUPTIVE // полуторминутный локдаун всей станции
	description = "Блокировка шлюзов. Секрет «самосбор» (10% при случайном); в Trigger Event можно выбрать вручную."
	admin_setup = list(/datum/event_admin_setup/door_runtime_secret_mode)

/datum/round_event/door_runtime
	var/force_secret_mode = FALSE
	var/secret_mode = FALSE

/datum/round_event/door_runtime/announce()
	if(secret_mode)
		sound_to_playing_players('modular_bluemoon/sound/effects/samosbor.ogg', volume = 50)
		priority_announce("По шлюзам расходятся ложные клейма: вы в ловушке. Слышны только сирены самосбора. Будьте внимательны - это не учения.", "ВНИМАНИЕ: АНОМАЛИЯ СЕТИ")
	else
		priority_announce("Вредоносное программное обеспечение обнаружено в системе контроля шлюзов. Задействованы протоколы изоляции. Пожалуйста, сохраняйте спокойствие.", "ВНИМАНИЕ: УЯЗВИМОСТЬ СЕТИ.")

/datum/round_event/door_runtime/start()
	secret_mode = force_secret_mode || (triggered_randomly && prob(10))
	for(var/obj/machinery/door/D in GLOB.airlocks)
		if(!is_station_level(D.z))
			continue
		INVOKE_ASYNC(D, TYPE_PROC_REF(/obj/machinery/door, hostile_lockdown))
		addtimer(CALLBACK(D, TYPE_PROC_REF(/obj/machinery/door, disable_lockdown)), 90 SECONDS)
	addtimer(CALLBACK(src, PROC_REF(reboot)), 90 SECONDS)
	var/obj/machinery/computer/communications/C = locate() in GLOB.machines
	if(C)
		C.post_status("alert", "lockdown")

/datum/round_event/door_runtime/proc/reboot()
	priority_announce("Автоматическая перезагрузка системы завершена. Хорошего вам дня.","ПЕРЕЗАГРУЗКА СЕТИ:")

/datum/event_admin_setup/door_runtime_secret_mode
	var/chose_secret = FALSE

/datum/event_admin_setup/door_runtime_secret_mode/prompt_admins()
	var/choice = tgui_alert(usr, "Включить «самосбор»?", "Door Runtime", list("Самосбор", "Обычный", "Отмена"))
	if(choice == "Отмена" || isnull(choice))
		return ADMIN_CANCEL_EVENT
	chose_secret = (choice == "Самосбор")

/datum/event_admin_setup/door_runtime_secret_mode/apply_to_event(datum/round_event/door_runtime/event)
	event.force_secret_mode = chose_secret
