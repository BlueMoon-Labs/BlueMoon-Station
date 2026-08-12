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
	// Станционных шлюзов тысячи: локдаун всех одним тиком - это секундный фриз,
	// а по персональному таймеру на дверь - залп из тысяч колбеков в один тик через 90с.
	// Поэтому обе волны идут одним списком через чанкованные глобальные проки,
	// не привязанные к времени жизни события.
	var/list/station_doors = list()
	for(var/obj/machinery/door/door in GLOB.airlocks)
		if(!is_station_level(door.z))
			continue
		station_doors += door
	door_runtime_set_lockdown(station_doors, TRUE)
	addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(door_runtime_set_lockdown), station_doors, FALSE), 90 SECONDS)
	addtimer(CALLBACK(src, PROC_REF(reboot)), 90 SECONDS)
	var/obj/machinery/computer/communications/C = locate() in GLOB.machines
	if(C)
		C.post_status("alert", "lockdown")

/// Волна (раз)блокировки шлюзов события Door Runtime. Каждой двери свой INVOKE_ASYNC,
/// потому что close()/open() спят; CHECK_TICK между запусками размазывает волну по тикам.
/proc/door_runtime_set_lockdown(list/doors, lock)
	set waitfor = FALSE
	for(var/obj/machinery/door/door as anything in doors)
		if(QDELETED(door))
			continue
		if(lock)
			INVOKE_ASYNC(door, TYPE_PROC_REF(/obj/machinery/door, hostile_lockdown))
		else
			INVOKE_ASYNC(door, TYPE_PROC_REF(/obj/machinery/door, disable_lockdown))
		CHECK_TICK

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
