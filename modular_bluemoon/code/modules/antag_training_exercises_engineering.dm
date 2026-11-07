/// Упражнения на машинах сектора: обстановка общая, поэтому в секторе одновременно идёт одно такое упражнение.
/datum/antag_training_exercise/systems

/datum/antag_training_exercise/systems/setup(datum/antag_training_session/session)
	var/datum/antag_training_exercise_run/busy = sector_run_of_other(session)
	if(busy)
		return "в секторе уже идёт упражнение «[busy.exercise.name]» другого участника, обстановка у вас общая"
	var/datum/antag_training_sector/place = loaded_sector(session)
	if(!place)
		return FALSE
	return prepare(session, place)

/datum/antag_training_exercise/systems/teardown(datum/antag_training_session/session)
	var/datum/antag_training_exercise_run/finished = session.exercise_run
	var/datum/antag_training_sector/place = loaded_sector(session)
	if(isnull(finished?.started_at) || !place || sector_run_of_other(session))
		return
	restore(session, place)

/// Готовит машины сектора к упражнению; FALSE или текст причины - не подготовить.
/datum/antag_training_exercise/systems/proc/prepare(datum/antag_training_session/session, datum/antag_training_sector/place)
	SHOULD_NOT_SLEEP(TRUE)
	return TRUE

/// Возвращает машины сектора в обычное состояние после прогона.
/datum/antag_training_exercise/systems/proc/restore(datum/antag_training_session/session, datum/antag_training_sector/place)
	SHOULD_NOT_SLEEP(TRUE)
	return

/datum/antag_training_exercise/systems/proc/loaded_sector(datum/antag_training_session/session)
	if(!session?.arena)
		return null
	var/datum/antag_training_sector/found = session.arena.sectors[sector]
	return found?.state == ANTAG_TRAINING_SECTOR_READY ? found : null

/datum/antag_training_exercise/systems/proc/sector_run_of_other(datum/antag_training_session/session)
	for(var/datum/antag_training_session/member as anything in session.arena?.members)
		var/datum/antag_training_exercise_run/other = member.exercise_run
		var/datum/antag_training_exercise/systems/other_exercise = other?.exercise
		if(member != session && istype(other_exercise) && other_exercise.sector == sector && !other.ended)
			return other
	return null

/datum/antag_training_exercise_step/checked/systems

/datum/antag_training_exercise_step/checked/systems/proc/current_sector()
	var/datum/antag_training_exercise/systems/owner_exercise = run?.exercise
	return istype(owner_exercise) ? owner_exercise.loaded_sector(run.session) : null

/datum/antag_training_exercise_step/checked/systems/proc/sector_area()
	var/datum/antag_training_sector/place = current_sector()
	return place?.sector_area

/datum/antag_training_exercise/systems/generator
	id = "engineering_generator"
	name = "Запусти генератор"
	sector = "engineering"
	difficulty = 1
	steps = list(/datum/antag_training_exercise_step/checked/systems/generator_fuel, /datum/antag_training_exercise_step/checked/systems/generator_start, /datum/antag_training_exercise_step/checked/systems/generator_smes)

/datum/antag_training_exercise/systems/generator/New()
	. = ..()
	desc = "Аварийное питание: заправить P.A.C.M.A.N. в машинной плазмой, запустить его и увидеть, что SMES принимает заряд. Рядом с генератором кладётся [ANTAG_TRAINING_GENERATOR_FUEL] листов плазмы, если их там нет."

/datum/antag_training_exercise/systems/generator/proc/pacman(datum/antag_training_sector/place)
	return locate(/obj/machinery/power/port_gen/pacman) in place?.sector_area

/datum/antag_training_exercise/systems/generator/proc/smes(datum/antag_training_sector/place)
	return locate(/obj/machinery/power/smes) in place?.sector_area

/datum/antag_training_exercise/systems/generator/prepare(datum/antag_training_session/session, datum/antag_training_sector/place)
	var/obj/machinery/power/port_gen/pacman/generator = pacman(place)
	var/obj/machinery/power/smes/storage = smes(place)
	if(QDELETED(generator) || QDELETED(storage) || (generator.machine_stat & BROKEN))
		return "в машинной нет исправного P.A.C.M.A.N. или SMES, сбросьте инженерный сектор"
	var/fuel = 0
	var/turf/open/fuel_spot
	for(var/turf/near as anything in RANGE_TURFS(1, generator))
		for(var/obj/item/stack/sheet/mineral/plasma/sheets in near)
			fuel += sheets.amount
		if(!fuel_spot && isopenturf(near) && !near.is_blocked_turf())
			fuel_spot = near
	if(fuel < ANTAG_TRAINING_GENERATOR_FUEL)
		if(!fuel_spot)
			return "рядом с генератором нет места для плазмы, уберите вещи вокруг него"
		if(!session.arena.issue_item(/obj/item/stack/sheet/mineral/plasma, fuel_spot, ANTAG_TRAINING_GENERATOR_FUEL, session))
			return "плазму не выдать: общий лимит предметов полигона исчерпан, уберите свои ненужные вещи"
	if(generator.active)
		generator.TogglePower()
	generator.sheets = 0
	generator.sheet_left = 0
	generator.current_heat = 0
	generator.power_output = 1
	if(!generator.anchored)
		generator.anchored = TRUE
		generator.connect_to_network()
	storage.input_attempt = TRUE
	storage.update_appearance()
	return TRUE

/datum/antag_training_exercise/systems/generator/restore(datum/antag_training_session/session, datum/antag_training_sector/place)
	var/obj/machinery/power/port_gen/pacman/generator = pacman(place)
	if(generator?.active)
		generator.TogglePower()

/datum/antag_training_exercise_step/checked/systems/generator_fuel
	name = "Заправьте P.A.C.M.A.N. плазмой"
	hint = "Генератор стоит в машинной. Возьмите листы плазмы и нажмите ими по генератору."

/datum/antag_training_exercise_step/checked/systems/generator_fuel/check()
	var/datum/antag_training_exercise/systems/generator/owner_exercise = run.exercise
	var/obj/machinery/power/port_gen/pacman/generator = owner_exercise.pacman(current_sector())
	return generator?.sheets > 0

/datum/antag_training_exercise_step/checked/systems/generator_start
	name = "Включите генератор"
	hint = "Нажмите по генератору рукой и в его окне включите питание. Генератор работает, только если прикручен к полу над узлом кабеля."

/datum/antag_training_exercise_step/checked/systems/generator_start/check()
	var/datum/antag_training_exercise/systems/generator/owner_exercise = run.exercise
	var/obj/machinery/power/port_gen/pacman/generator = owner_exercise.pacman(current_sector())
	return generator?.active

/datum/antag_training_exercise_step/checked/systems/generator_smes
	name = "Убедитесь, что SMES принимает заряд"
	hint = "Генератор и солнечные панели питают вход SMES. В окне SMES должен быть включён приём заряда (Input), индикатор зарядки на корпусе загорается сам."

/datum/antag_training_exercise_step/checked/systems/generator_smes/check()
	var/datum/antag_training_exercise/systems/generator/owner_exercise = run.exercise
	var/datum/antag_training_sector/place = current_sector()
	var/obj/machinery/power/port_gen/pacman/generator = owner_exercise.pacman(place)
	var/obj/machinery/power/smes/storage = owner_exercise.smes(place)
	return generator?.active && storage?.inputting && storage.input_available > 0

/datum/antag_training_exercise/systems/cable
	id = "engineering_cable"
	name = "Проложи питание"
	desc = "Комната под прокладку питается от своего щитка, но он не подключён к сети. Кабель от конца под дверью комнаты до терминала щитка - и лампы загорятся."
	sector = "engineering"
	difficulty = 2
	par_time = 2 MINUTES
	steps = list(/datum/antag_training_exercise_step/checked/systems/cable_route, /datum/antag_training_exercise_step/checked/systems/cable_light)

/datum/antag_training_exercise/systems/cable/proc/room(datum/antag_training_sector/place)
	var/datum/antag_training_sector/engineering/engineering = place
	return istype(engineering) ? engineering.cable_room : null

/datum/antag_training_exercise/systems/cable/proc/room_apc(datum/antag_training_sector/place)
	return locate(/obj/machinery/power/apc) in room(place)

/datum/antag_training_exercise/systems/cable/proc/live_net(datum/antag_training_sector/place)
	var/obj/machinery/power/smes/storage = locate() in place?.sector_area
	return storage?.powernet

/datum/antag_training_exercise/systems/cable/proc/room_lit(datum/antag_training_sector/place)
	for(var/obj/machinery/light/lamp in room(place))
		if(lamp.status == LIGHT_OK && lamp.on)
			return TRUE
	return FALSE

/datum/antag_training_exercise/systems/cable/prepare(datum/antag_training_session/session, datum/antag_training_sector/place)
	var/area/room_area = room(place)
	var/obj/machinery/power/apc/room_apc = room_apc(place)
	if(!room_area || QDELETED(room_apc) || !room_apc.cell || !room_apc.terminal || !live_net(place))
		return "щиток комнаты под прокладку или SMES сектора разобраны, сбросьте инженерный сектор"
	for(var/obj/structure/cable/wire in room_area)
		qdel(wire)
	// Пустая батарея: каналы гасит сам щиток на ближайшем такте, как на станции.
	room_apc.cell.charge = 0
	room_apc.operating = TRUE
	room_apc.update_appearance()
	return TRUE

/datum/antag_training_exercise_step/checked/systems/cable_route
	name = "Проложите кабель к щитку комнаты"
	hint = "Конец кабеля под дверью комнаты под прокладку под током: наденьте изолированные перчатки. Встаньте на клетку с кабелем, повернитесь к щитку и нажмите мотком по своей клетке, затем по соседней - так кабель тянется шаг за шагом до клетки под щитком на дальней стене."

/datum/antag_training_exercise_step/checked/systems/cable_route/check()
	var/datum/antag_training_exercise/systems/cable/owner_exercise = run.exercise
	var/datum/antag_training_sector/place = current_sector()
	var/obj/machinery/power/apc/room_apc = owner_exercise.room_apc(place)
	var/datum/powernet/net = owner_exercise.live_net(place)
	return net && room_apc?.terminal?.powernet == net

/datum/antag_training_exercise_step/checked/systems/cable_light
	name = "Дождитесь света в комнате"
	polling = FALSE
	hint = "Щиток сначала копит заряд в батарее и включает каналы не сразу, а меньше чем через минуту. Не разбирайте кабель, пока лампы не загорятся."

/datum/antag_training_exercise_step/checked/systems/cable_light/attach(datum/antag_training_exercise_run/owner)
	. = ..()
	var/datum/antag_training_exercise/systems/cable/owner_exercise = run.exercise
	var/area/room_area = owner_exercise.room(current_sector())
	if(room_area)
		RegisterSignal(room_area, COMSIG_AREA_POWER_CHANGE, PROC_REF(recheck))

/datum/antag_training_exercise_step/checked/systems/cable_light/check()
	var/datum/antag_training_exercise/systems/cable/owner_exercise = run.exercise
	return owner_exercise.room_lit(current_sector())

/datum/antag_training_exercise/systems/hack
	id = "engineering_hack"
	name = "Взломай шлюз"
	desc = "Запертый на болты шлюз склада с инженерным доступом: панель, болты, проверка ID и импульс провода открытия. Провода полигона раскладываются заново при каждой загрузке сектора."
	sector = "engineering"
	difficulty = 2
	par_time = 90 SECONDS
	steps = list(/datum/antag_training_exercise_step/checked/systems/hack_panel, /datum/antag_training_exercise_step/checked/systems/hack_bolts, /datum/antag_training_exercise_step/checked/systems/hack_idscan, /datum/antag_training_exercise_step/checked/systems/hack_open)

/// Шлюз под доступ, ближайший к коридору: дверь склада.
/datum/antag_training_exercise/systems/hack/proc/target(datum/antag_training_sector/place)
	var/obj/machinery/door/airlock/best
	for(var/obj/machinery/door/airlock/door in place?.sector_area)
		if(door.check_access(null))
			continue
		if(!best || door.y < best.y || (door.y == best.y && door.x < best.x))
			best = door
	return best

/datum/antag_training_exercise/systems/hack/prepare(datum/antag_training_session/session, datum/antag_training_sector/place)
	var/obj/machinery/door/airlock/door = target(place)
	if(QDELETED(door) || door.welded || (door.machine_stat & BROKEN))
		return "шлюз склада сломан или заварен, сбросьте инженерный сектор"
	reset_door(door)
	if(!door.density)
		INVOKE_ASYNC(door, TYPE_PROC_REF(/obj/machinery/door/airlock, close))
	door.bolt()
	return TRUE

/datum/antag_training_exercise/systems/hack/restore(datum/antag_training_session/session, datum/antag_training_sector/place)
	var/obj/machinery/door/airlock/door = target(place)
	if(QDELETED(door))
		return
	reset_door(door)
	door.unbolt()
	if(!door.density)
		INVOKE_ASYNC(door, TYPE_PROC_REF(/obj/machinery/door/airlock, close))

/datum/antag_training_exercise/systems/hack/proc/reset_door(obj/machinery/door/airlock/door)
	door.wires.repair()
	door.regainMainPower()
	door.regainBackupPower()
	door.set_electrified(0)
	door.panel_open = FALSE
	door.aiDisabledIdScanner = FALSE
	door.safe = TRUE
	door.autoclose = TRUE
	door.update_icon()

/datum/antag_training_exercise_step/checked/systems/hack_panel
	name = "Снимите панель шлюза"
	hint = "Шлюз склада выходит в коридор. Нажмите по нему отвёрткой - откроется панель с проводами."

/datum/antag_training_exercise_step/checked/systems/hack_panel/check()
	var/datum/antag_training_exercise/systems/hack/owner_exercise = run.exercise
	var/obj/machinery/door/airlock/door = owner_exercise.target(current_sector())
	return door?.panel_open

/datum/antag_training_exercise_step/checked/systems/hack_bolts
	name = "Поднимите болты импульсом"
	polling = FALSE
	hint = "Возьмите мультитул и нажмите им по шлюзу. В окне проводов посылайте импульс по проводам по очереди: провод болтов поднимает их со щелчком. Провода питания и удара током лучше не трогать без изолированных перчаток."

/datum/antag_training_exercise_step/checked/systems/hack_bolts/attach(datum/antag_training_exercise_run/owner)
	. = ..()
	var/datum/antag_training_exercise/systems/hack/owner_exercise = run.exercise
	var/obj/machinery/door/airlock/door = owner_exercise.target(current_sector())
	if(door)
		RegisterSignal(door, COMSIG_AIRLOCK_UNBOLTED, PROC_REF(recheck))

/datum/antag_training_exercise_step/checked/systems/hack_bolts/check()
	var/datum/antag_training_exercise/systems/hack/owner_exercise = run.exercise
	var/obj/machinery/door/airlock/door = owner_exercise.target(current_sector())
	return door && !door.locked

/datum/antag_training_exercise_step/checked/systems/hack_idscan
	name = "Отключите проверку ID"
	hint = "Импульс по проводу проверки ID мигает красным огнём на шлюзе. Перережьте этот провод кусачками - шлюз перестанет требовать доступ."

/datum/antag_training_exercise_step/checked/systems/hack_idscan/check()
	var/datum/antag_training_exercise/systems/hack/owner_exercise = run.exercise
	var/obj/machinery/door/airlock/door = owner_exercise.target(current_sector())
	return door && !door.requiresID()

/datum/antag_training_exercise_step/checked/systems/hack_open
	name = "Откройте шлюз импульсом"
	hint = "Найдите провод открытия: импульс мультитулом по нему открывает и закрывает шлюз без доступа. Шлюз, открытый иначе, например ломом без питания, не засчитывается - закройте его и откройте импульсом."
	polling = FALSE
	/// Шлюз начал открываться сразу после импульса мультитулом, то есть по проводу открытия.
	var/pulse_opening = FALSE

/datum/antag_training_exercise_step/checked/systems/hack_open/attach(datum/antag_training_exercise_run/owner)
	. = ..()
	var/datum/antag_training_exercise/systems/hack/owner_exercise = run.exercise
	var/obj/machinery/door/airlock/door = owner_exercise.target(current_sector())
	if(door?.wires)
		RegisterSignal(door.wires, COMSIG_UI_ACT, PROC_REF(on_wires_act))

/datum/antag_training_exercise_step/checked/systems/hack_open/proc/on_wires_act(datum/wires/source, mob/living/user, action)
	SIGNAL_HANDLER
	var/obj/machinery/door/airlock/door = source.holder
	var/obj/item/tool = user?.get_active_held_item()
	if(action != "pulse" || user != participant() || !istype(door) || !door.density || !door.panel_open || tool?.tool_behaviour != TOOL_MULTITOOL)
		return
	deltimer(check_timer)
	check_timer = addtimer(CALLBACK(src, PROC_REF(after_pulse), door), 0, TIMER_STOPPABLE)

/// Импульс по проводу открытия запускает открытие в том же тике, импульс по другому проводу - нет.
/datum/antag_training_exercise_step/checked/systems/hack_open/proc/after_pulse(obj/machinery/door/airlock/door)
	if(QDELETED(door) || (door.density && !door.operating))
		return
	pulse_opening = TRUE
	check_timer = addtimer(CALLBACK(src, PROC_REF(recheck)), ANTAG_TRAINING_HACK_OPEN_WAIT, TIMER_STOPPABLE)

/datum/antag_training_exercise_step/checked/systems/hack_open/check()
	var/datum/antag_training_exercise/systems/hack/owner_exercise = run.exercise
	var/obj/machinery/door/airlock/door = owner_exercise.target(current_sector())
	. = pulse_opening && door && !door.density
	pulse_opening = FALSE

/datum/antag_training_exercise/systems/blackout
	id = "engineering_blackout"
	name = "Отключи щитовую и верни свет"
	desc = "Щиток APC в щитовой питает весь сектор: выключить свет рубильником или каналом освещения и включить его обратно."
	sector = "engineering"
	difficulty = 1
	par_time = 45 SECONDS
	steps = list(/datum/antag_training_exercise_step/checked/systems/blackout_cut, /datum/antag_training_exercise_step/checked/systems/blackout_restore)

/datum/antag_training_exercise/systems/blackout/prepare(datum/antag_training_session/session, datum/antag_training_sector/place)
	var/obj/machinery/power/apc/switchboard = locate() in place.sector_area
	if(QDELETED(switchboard) || (switchboard.machine_stat & BROKEN))
		return "щиток APC в щитовой разобран, сбросьте инженерный сектор"
	switch_on(switchboard, place.sector_area)
	if(!place.sector_area.powered(LIGHT))
		return "у щитка нет заряда, чтобы включить свет: запустите генератор или сбросьте инженерный сектор"
	return TRUE

/datum/antag_training_exercise/systems/blackout/restore(datum/antag_training_session/session, datum/antag_training_sector/place)
	var/obj/machinery/power/apc/switchboard = locate() in place.sector_area
	if(!QDELETED(switchboard))
		switch_on(switchboard, place.sector_area)

/datum/antag_training_exercise/systems/blackout/proc/switch_on(obj/machinery/power/apc/switchboard, area/sector_area)
	switchboard.operating = TRUE
	switchboard.lighting = switchboard.setsubsystem(3)
	switchboard.update()
	switchboard.update_appearance()
	if(!sector_area.lightswitch)
		sector_area.lightswitch = TRUE
		sector_area.power_change()

/datum/antag_training_exercise_step/checked/systems/blackout_cut
	name = "Обесточьте свет сектора"
	polling = FALSE
	hint = "Щитовая рядом с машинной. Нажмите по APC рукой и выключите рубильник (Main Breaker) или переведите канал освещения в Off."

/datum/antag_training_exercise_step/checked/systems/blackout_cut/attach(datum/antag_training_exercise_run/owner)
	. = ..()
	var/area/sector_area = sector_area()
	if(sector_area)
		RegisterSignal(sector_area, COMSIG_AREA_POWER_CHANGE, PROC_REF(recheck))

/datum/antag_training_exercise_step/checked/systems/blackout_cut/check()
	var/area/sector_area = sector_area()
	return sector_area && !sector_area.powered(LIGHT)

/datum/antag_training_exercise_step/checked/systems/blackout_restore
	name = "Верните свет"
	polling = FALSE
	hint = "Включите рубильник APC и верните каналу освещения режим Auto. Выключатель света на стене щитовой тоже должен быть включён."

/datum/antag_training_exercise_step/checked/systems/blackout_restore/attach(datum/antag_training_exercise_run/owner)
	. = ..()
	var/area/sector_area = sector_area()
	if(sector_area)
		RegisterSignal(sector_area, COMSIG_AREA_POWER_CHANGE, PROC_REF(recheck))

/datum/antag_training_exercise_step/checked/systems/blackout_restore/check()
	var/area/sector_area = sector_area()
	return sector_area?.lightswitch && sector_area.powered(LIGHT)
