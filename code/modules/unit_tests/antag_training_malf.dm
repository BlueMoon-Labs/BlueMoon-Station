/datum/unit_test/proc/antag_training_malf_session()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/creature/malf_ai)
	return session.prepare() && istype(session.current_body, /mob/living/silicon/ai/training) ? session : null

/datum/unit_test/proc/antag_training_malf_buy(mob/living/silicon/ai/core, module_type)
	var/datum/module_picker/picker = core.malf_picker
	var/datum/AI_Module/module = locate(module_type) in picker.possible_modules
	if(!module)
		return FALSE
	var/datum/tgui/picker_ui = allocate(/datum/tgui, core, picker, "MalfunctionModulePicker")
	picker_ui.status = UI_INTERACTIVE
	usr = core
	picker.ui_act("buy", list("ref" = REF(module)), picker_ui)
	usr = null
	return TRUE

/// Учебный ИИ в зале ядра макета: не вызывает шаттл и не принимает станционных киборгов, взлом APC через окно даёт процессорное время, модули только учебные и действуют в макете, Судный день распыляет только манекены макета без тревоги.
/datum/unit_test/antag_training_malf/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/creature/malf_ai)
	TEST_ASSERT(session.prepare(), "Полигон готовит учебный ИИ.")
	var/datum/antag_training_arena/arena = session.arena
	var/datum/antag_training_sector/station = arena.sectors["station"]
	var/datum/antag_training_program/creature/malf_ai/program = session.program
	var/mob/living/silicon/ai/training/core = session.current_body
	TEST_ASSERT(istype(core) && core.mind == session.avatar_mind, "Разум участника в учебном ИИ.")
	TEST_ASSERT_EQUAL(station.state, ANTAG_TRAINING_SECTOR_READY, "Станционный макет загружен.")
	TEST_ASSERT_EQUAL(get_turf(core), station.landmark_turf("ai_core"), "ИИ стоит в зале ядра макета.")
	TEST_ASSERT_EQUAL(core.eyeobj?.training_origin?.resolve(), arena, "Глаз ИИ принадлежит полигону.")
	TEST_ASSERT(!(core in GLOB.shuttle_caller_list), "Учебный ИИ не в списке вызывающих шаттл.")
	TEST_ASSERT(!(core in active_ais()), "Учебный ИИ не среди активных ИИ станции.")
	TEST_ASSERT_NULL(core.aiPDA, "У учебного ИИ нет PDA в мессенджере станции.")
	var/datum/antagonist/traitor/malf_training/role = program.role(session)
	TEST_ASSERT(istype(role) && role.training == session && !length(role.objectives), "Учебный датум сбоя привязан к сеансу и без целей.")
	var/datum/module_picker/training/picker = core.malf_picker
	TEST_ASSERT(istype(picker) && core.hack_software, "ИИ получил учебный выбор модулей.")
	for(var/option in program.options)
		TEST_ASSERT(length(program.option_hints[option]), "У кнопки «[option]» есть подсказка.")

	var/datum/module_picker/station_picker = new
	for(var/datum/AI_Module/module as anything in station_picker.possible_modules)
		TEST_ASSERT(!module.training_only, "В выборе настоящего малфа нет учебного модуля [module.type].")
	QDEL_LIST(station_picker.possible_modules)
	qdel(station_picker)
	TEST_ASSERT(!(locate(/datum/AI_Module/large/place_cyborg_transformer) in picker.possible_modules), "Роботизированной фабрики в учебном выборе нет.")
	for(var/datum/AI_Module/module as anything in picker.possible_modules)
		TEST_ASSERT(module.training_only || istype(module, /datum/AI_Module/large/mecha_domination) || istype(module, /datum/AI_Module/large/eavesdrop), "Станционный модуль [module.type] не попадает в учебный выбор.")

	var/mob/living/silicon/robot/station_borg = allocate(/mob/living/silicon/robot, run_loc_floor_bottom_left)
	TEST_ASSERT(station_borg.connected_ai != core && !(station_borg in core.connected_robots), "Новый киборг станции не привязывается к учебному ИИ.")
	var/mob/living/carbon/human/linked_human = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/obj/item/organ/cyberimp/brain/ai_link/neurolink = new
	neurolink.Insert(linked_human)
	TEST_ASSERT(neurolink.linked_ai != core && !(linked_human in core.linked_humans), "Нейролинк станции не связывается с учебным ИИ.")

	var/unique_name = "Training Unit Test AI"
	core.fully_replace_character_name(core.real_name, unique_name)
	TEST_ASSERT(!findtext(SSticker.law_report(), unique_name), "Итог раунда не показывает учебный ИИ.")

	var/datum/tgui/console = allocate(/datum/tgui, core, session, "AntagTraining")
	var/obj/machinery/power/apc/apc = station.sector_area.power_apc
	TEST_ASSERT_NOTNULL(apc, "У макета есть APC.")
	var/time_before_hack = picker.processing_time
	var/datum/tgui/apc_ui = allocate(/datum/tgui, core, apc, "Apc")
	apc_ui.status = UI_INTERACTIVE
	usr = core
	apc.ui_act("hack", list(), apc_ui)
	usr = null
	TEST_ASSERT(core.malfhacking && core.malfhack == apc, "Кнопка взлома в окне APC запускает взлом.")
	var/hack_timer_id = core.malfhacking
	var/datum/timedevent/hack_timer = SStimer.timer_id_dict[hack_timer_id]
	TEST_ASSERT_NOTNULL(hack_timer, "Взлом ждёт таймера.")
	hack_timer.callBack.Invoke()
	deltimer(hack_timer_id)
	TEST_ASSERT_EQUAL(picker.processing_time, time_before_hack + 10, "Взломанный APC макета даёт процессорное время.")
	TEST_ASSERT(apc.malfhack && apc.malfai == core, "APC макета под учебным ИИ.")

	antag_training_console_act(session, console, "program_option", list("option" = "Процессорное время"))
	var/datum/AI_Module/large/nuke_station/training/doomsday_module = locate() in picker.possible_modules
	TEST_ASSERT(picker.processing_time >= doomsday_module.cost, "Кнопка даёт процессорное время на Судный день.")

	var/list/station_overloads = list()
	for(var/obj/machinery/power/apc/station_apc as anything in GLOB.apcs_list)
		if(!is_antag_training_atom(station_apc))
			station_overloads[station_apc] = station_apc.overload
	apc.overload = 0
	TEST_ASSERT(antag_training_malf_buy(core, /datum/AI_Module/small/blackout/training), "Блэкаут есть в учебном выборе.")
	var/datum/action/innate/ai/blackout/training/blackout = locate() in core.actions
	TEST_ASSERT_NOTNULL(blackout, "Покупка выдаёт учебный блэкаут.")
	blackout.Trigger()
	TEST_ASSERT_EQUAL(apc.overload, 1, "Блэкаут перегружает APC макета.")
	for(var/obj/machinery/power/apc/station_apc as anything in station_overloads)
		TEST_ASSERT_EQUAL(station_apc.overload, station_overloads[station_apc], "Блэкаут не трогает APC станции [station_apc].")
	TEST_ASSERT_EQUAL(blackout.uses, initial(blackout.uses) - 1, "Блэкаут тратит заряд.")
	antag_training_console_act(session, console, "program_option", list("option" = "Перезарядить модули"))
	TEST_ASSERT_EQUAL(blackout.uses, initial(blackout.uses), "Перезарядка возвращает заряды.")

	antag_training_console_act(session, console, "program_option", list("option" = "Учебный киборг"))
	var/mob/living/silicon/robot/training/minion = locate() in arena.targets
	TEST_ASSERT_NOTNULL(minion, "Кнопка ставит учебного киборга в лимит целей.")
	TEST_ASSERT(minion.connected_ai == core && (minion in core.connected_robots) && minion.lawupdate, "Учебный киборг подключён к учебному ИИ и синхронизирует законы.")
	TEST_ASSERT(arena.inside_bounds(get_turf(minion), station.bounds), "Учебный киборг стоит в макете.")

	var/mob/living/carbon/human/dummy = arena.spawn_creature("human", "station", FALSE, session, station.landmark_turf("ai_core"))
	TEST_ASSERT_NOTNULL(dummy, "В макете стоит манекен.")
	var/mob/living/carbon/human/bystander = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/turf/station_tile = get_turf(bystander)
	var/station_tile_type = station_tile.type
	var/security_before = GLOB.security_level
	var/force_ending_before = SSticker.force_ending
	var/hostile_before = length(SSshuttle.hostileEnvironments)
	var/threats_before = length(SSmapping.nuke_threats)
	TEST_ASSERT(antag_training_malf_buy(core, /datum/AI_Module/large/nuke_station/training), "Судный день есть в учебном выборе.")
	var/datum/action/innate/ai/nuke_station/training/doomsday = locate() in core.actions
	TEST_ASSERT_NOTNULL(doomsday, "Покупка выдаёт учебный Судный день.")
	doomsday.Trigger()
	var/obj/machinery/doomsday_device/training/device = core.doomsday_device
	TEST_ASSERT(istype(device) && device.timing, "Устройство запущено.")
	TEST_ASSERT(abs(device.seconds_remaining() - 60) <= 1, "Отсчёт учебного устройства - минута, а не [device.seconds_remaining()] с.")
	TEST_ASSERT(!core.nuking, "Учебный ИИ не помечен взводящим бомбу.")
	TEST_ASSERT_EQUAL(length(SSshuttle.hostileEnvironments), hostile_before, "Устройство не держит шаттл.")
	TEST_ASSERT_EQUAL(length(SSmapping.nuke_threats), threats_before, "Устройство не красит полы станции.")
	TEST_ASSERT_EQUAL(GLOB.security_level, security_before, "Запуск не меняет уровень тревоги.")
	device.detonation_timer = world.time - 1
	device.process()
	TEST_ASSERT(QDELETED(device) && !core.doomsday_device, "Устройство убирается после взрыва.")
	TEST_ASSERT(QDELETED(dummy) || dummy.stat == DEAD, "Манекен макета распылён.")
	TEST_ASSERT(!QDELETED(bystander) && bystander.stat != DEAD, "Человек вне полигона цел.")
	TEST_ASSERT_EQUAL(station_tile.type, station_tile_type, "Клетка вне полигона не меняется.")
	TEST_ASSERT_EQUAL(GLOB.security_level, security_before, "Взрыв не меняет уровень тревоги.")
	TEST_ASSERT_EQUAL(SSticker.force_ending, force_ending_before, "Взрыв не заканчивает раунд.")
	TEST_ASSERT(!QDELETED(core) && core.stat != DEAD, "ИИ переживает учебный взрыв.")
	antag_training_console_act(session, console, "program_option", list("option" = "Перезарядить модули"))
	TEST_ASSERT_NOTNULL(locate(/datum/action/innate/ai/nuke_station/training) in core.actions, "Перезарядка возвращает Судный день.")

	core.death()
	TEST_ASSERT(antag_training_wait_new_body(session, core, "новое ядро после смерти"), "Ядро пересоздаётся после смерти.")
	var/mob/living/silicon/ai/training/rebuilt = session.current_body
	TEST_ASSERT(istype(rebuilt) && minion.connected_ai == rebuilt, "Учебный киборг подключается к пересозданному ядру.")
	core = rebuilt

	GLOB.unit_test_chat_capture = list()
	core.ai_call_shuttle()
	var/refused = antag_training_chat_heard(core, "вызов эвакуационного шаттла")
	GLOB.unit_test_chat_capture = null
	TEST_ASSERT(refused, "Вызов шаттла учебным ИИ отклоняется с объяснением.")

/datum/unit_test/antag_training_malf/Destroy()
	GLOB.unit_test_chat_capture = null
	return ..()

/// Окно мультикамеры учебного ИИ получает глаз полигона и не выводит его на станцию.
/datum/unit_test/antag_training_malf_multicam/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/creature/malf_ai)
	TEST_ASSERT(session.prepare(), "Полигон готовит учебный ИИ.")
	var/mob/living/silicon/ai/training/core = session.current_body
	var/allowed = CONFIG_GET(flag/allow_ai_multicam)
	CONFIG_SET(flag/allow_ai_multicam, TRUE)
	var/atom/movable/screen/movable/pic_in_pic/ai/window = core.drop_new_multicam(TRUE)
	CONFIG_SET(flag/allow_ai_multicam, allowed)
	TEST_ASSERT_NOTNULL(window, "Окно мультикамеры создаётся.")
	allocated += window
	TEST_ASSERT_EQUAL(window.aiEye.training_origin?.resolve(), session.arena, "Глаз мультикамеры принадлежит полигону.")
	TEST_ASSERT_EQUAL(get_turf(window.aiEye), get_turf(core.eyeobj), "Глаз мультикамеры встаёт на камеру ИИ.")
	window.aiEye.setLoc(run_loc_floor_bottom_left)
	TEST_ASSERT_EQUAL(get_turf(window.aiEye), get_turf(core.eyeobj), "Глаз мультикамеры не выходит на станцию.")

/// Модули сбоя действуют только в станционном макете: блэкаут не трогает APC другого сектора того же полигона.
/datum/unit_test/antag_training_malf_mock_only/Run()
	var/datum/antag_training_session/session = antag_training_malf_session()
	TEST_ASSERT_NOTNULL(session, "Полигон готовит учебный ИИ.")
	var/mob/living/silicon/ai/training/core = session.current_body
	var/datum/antag_training_sector/station = session.arena.sectors["station"]
	var/datum/antag_training_sector/engineering = session.arena.sectors["engineering"]
	TEST_ASSERT(engineering.load(), "Инженерный сектор загружается.")
	var/obj/machinery/power/apc/mock_apc = station.sector_area.power_apc
	var/obj/machinery/power/apc/other_apc = locate() in engineering.sector_area
	TEST_ASSERT(mock_apc && other_apc, "В макете и инженерном секторе есть APC.")
	mock_apc.overload = 0
	other_apc.overload = 0
	TEST_ASSERT(antag_training_malf_buy(core, /datum/AI_Module/small/blackout/training), "Блэкаут есть в учебном выборе.")
	var/datum/action/innate/ai/blackout/training/blackout = locate() in core.actions
	blackout.Trigger()
	TEST_ASSERT_EQUAL(mock_apc.overload, 1, "Блэкаут перегружает APC макета.")
	TEST_ASSERT_EQUAL(other_apc.overload, 0, "Блэкаут не трогает APC инженерного сектора.")

/// Ссылка «Request AI» станционного голопада не проецирует учебный ИИ на станцию.
/datum/unit_test/antag_training_malf_holopad/Run()
	var/datum/antag_training_session/session = antag_training_malf_session()
	TEST_ASSERT_NOTNULL(session, "Полигон готовит учебный ИИ.")
	var/mob/living/silicon/ai/training/core = session.current_body
	var/obj/machinery/holopad/pad = allocate(/obj/machinery/holopad, run_loc_floor_bottom_left)
	pad.machine_stat = NONE
	usr = core
	core.Topic(null, list("jumptoholopad" = REF(pad)))
	usr = null
	TEST_ASSERT(!LAZYLEN(pad.masters) && core.current != pad, "Учебный ИИ не выходит голограммой на станционный голопад.")

/// Ссылка захвата меха не отдаёт учебному ИИ станционный мех.
/datum/unit_test/antag_training_malf_mech/Run()
	var/datum/antag_training_session/session = antag_training_malf_session()
	TEST_ASSERT_NOTNULL(session, "Полигон готовит учебный ИИ.")
	var/mob/living/silicon/ai/training/core = session.current_body
	TEST_ASSERT(antag_training_malf_buy(core, /datum/AI_Module/large/mecha_domination), "Захват мехов есть в учебном выборе.")
	TEST_ASSERT(core.can_dominate_mechs, "Модуль открывает захват мехов.")
	allocate(/obj/machinery/camera, run_loc_floor_bottom_left)
	var/obj/vehicle/sealed/mecha/working/ripley/mech = allocate(/obj/vehicle/sealed/mecha/working/ripley, run_loc_floor_bottom_left)
	var/datum/camerachunk/chunk = GLOB.cameranet.getCameraChunk(run_loc_floor_bottom_left.x, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	// Чанк иначе пересчитывается таймером, и под нагрузкой проверка обгоняет его.
	chunk.update()
	TEST_ASSERT(GLOB.cameranet.checkCameraVis(mech), "Камера станции видит мех.")
	usr = core
	core.Topic(null, list("ai_take_control" = REF(mech)))
	usr = null
	TEST_ASSERT(!(core in mech.occupants) && core.controlled_equipment != mech && !core.linked_core, "Учебный ИИ не захватывает станционный мех.")

/// Событие патча прошивки не считает учебный ИИ получателем.
/datum/unit_test/antag_training_malf_firmware/Run()
	var/datum/antag_training_session/session = antag_training_malf_session()
	TEST_ASSERT_NOTNULL(session, "Полигон готовит учебный ИИ.")
	var/mob/living/silicon/ai/training/core = session.current_body
	var/datum/round_event_control/silicon_firmware_patch/control = allocate(/datum/round_event_control/silicon_firmware_patch)
	TEST_ASSERT(!control.is_recipient(core, FALSE), "Учебный ИИ не получатель патча.")
	TEST_ASSERT(!(core in control.get_recipients(FALSE)), "Учебного ИИ нет среди получателей патча.")

/// Удалённое управление ботами учебного ИИ не берёт бота станции.
/datum/unit_test/antag_training_malf_bots/Run()
	var/datum/antag_training_session/session = antag_training_malf_session()
	TEST_ASSERT_NOTNULL(session, "Полигон готовит учебный ИИ.")
	var/mob/living/silicon/ai/training/core = session.current_body
	var/mob/living/simple_animal/bot/medbot/station_bot = allocate(/mob/living/simple_animal/bot/medbot, run_loc_floor_bottom_left)
	TEST_ASSERT(!station_bot.remote_disabled, "Бот станции доступен удалённому управлению.")
	core.robot_control = new(core)
	var/datum/tgui/bots_ui = allocate(/datum/tgui, core, core.robot_control, "RemoteRobotControl")
	bots_ui.status = UI_INTERACTIVE
	usr = core
	core.robot_control.ui_act("callbot", list("ref" = REF(station_bot)), bots_ui)
	usr = null
	TEST_ASSERT_NULL(core.bot_ref?.resolve(), "Учебный ИИ не берёт под управление бота станции.")

/// Перегрузка и оживление машин отказывают без траты заряда, если машина вне станционного макета.
/datum/unit_test/antag_training_malf_ranged_reach/Run()
	var/datum/antag_training_session/session = antag_training_malf_session()
	TEST_ASSERT_NOTNULL(session, "Полигон готовит учебный ИИ.")
	var/mob/living/silicon/ai/training/core = session.current_body
	core.malf_picker.processing_time = 100
	TEST_ASSERT(antag_training_malf_buy(core, /datum/AI_Module/small/overload_machine/training), "Перегрузка есть в учебном выборе.")
	TEST_ASSERT(antag_training_malf_buy(core, /datum/AI_Module/small/override_machine/training), "Оживление есть в учебном выборе.")
	var/obj/machinery/computer/hub_machine = allocate(/obj/machinery/computer, session.arena.zones["melee"]["spawn"])
	TEST_ASSERT_EQUAL(hub_machine.training_origin?.resolve(), session.arena, "Машина стоит на полигоне вне макета.")
	for(var/power_type in list(/datum/action/innate/ai/ranged/overload_machine/training, /datum/action/innate/ai/ranged/override_machine/training))
		var/datum/action/innate/ai/ranged/power = locate(power_type) in core.actions
		TEST_ASSERT_NOTNULL(power, "Покупка выдаёт [power_type].")
		var/uses_before = power.uses
		var/obj/effect/proc_holder/ranged_ai/ability = power.linked_ability
		ability.ranged_ability_user = core
		ability.active = TRUE
		core.ranged_ability = ability
		ability.InterceptClickOn(core, "", hub_machine)
		core.ranged_ability = null
		ability.ranged_ability_user = null
		ability.active = FALSE
		TEST_ASSERT_EQUAL(power.uses, uses_before, "[power_type]: клик по машине вне макета не тратит заряд.")
		TEST_ASSERT(!QDELETED(hub_machine), "[power_type]: машина вне макета цела.")

/// Удалённый ИИ забирает с собой модули сбоя: дальнобойный модуль держит ядро циклом со своим proc_holder и иначе не даёт ему собраться.
/datum/unit_test/malf_actions_freed_with_ai/Run()
	var/mob/living/carbon/human/donor = allocate(/mob/living/carbon/human)
	var/mob/living/silicon/ai/station_ai = allocate(/mob/living/silicon/ai, run_loc_floor_bottom_left, null, donor)
	var/list/powers = list(new /datum/action/innate/ai/ranged/overload_machine, new /datum/action/innate/ai/blackout)
	for(var/datum/action/innate/ai/power as anything in powers)
		power.Grant(station_ai)
		TEST_ASSERT_EQUAL(power.owner_AI, station_ai, "[power.type] выдан ИИ.")
	qdel(station_ai)
	for(var/datum/action/innate/ai/power as anything in powers)
		TEST_ASSERT(QDELETED(power), "[power.type] удалён вместе с ИИ.")
		TEST_ASSERT_NULL(power.owner_AI, "[power.type] не держит удалённый ИИ.")
	var/datum/action/innate/ai/ranged/overload_machine/ranged = powers[1]
	TEST_ASSERT_NULL(ranged.linked_ability, "Дальнобойный модуль отпускает свой proc_holder.")
