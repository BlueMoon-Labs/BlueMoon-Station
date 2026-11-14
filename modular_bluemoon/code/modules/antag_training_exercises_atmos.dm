/// Открытые клетки комнаты от start внутри границ сектора: стены, двери и окна - её край. null - комната не замкнута.
/proc/antag_training_room_turfs(turf/open/start, datum/antag_training_sector/place)
	if(!istype(start) || isspaceturf(start) || !place?.bounds)
		return null
	var/list/turf/open/room = list(start)
	var/list/seen = list()
	seen[start] = TRUE
	for(var/index = 1; index <= length(room); index++)
		for(var/direction in GLOB.cardinals)
			var/turf/open/next = get_step(room[index], direction)
			if(!istype(next) || seen[next])
				continue
			seen[next] = TRUE
			if(isspaceturf(next) || !place.arena.inside_bounds(next, place.bounds) || (locate(/obj/machinery/door) in next) || (locate(/obj/structure/window) in next))
				continue
			room += next
			if(length(room) > ANTAG_TRAINING_ROOM_LIMIT)
				return null
	return room

/// Клетка комнаты ближе всего к её середине, по возможности свободная.
/proc/antag_training_room_center(list/turf/open/room)
	var/sum_x = 0
	var/sum_y = 0
	for(var/turf/open/tile as anything in room)
		sum_x += tile.x
		sum_y += tile.y
	var/center_x = sum_x / length(room)
	var/center_y = sum_y / length(room)
	var/turf/open/best
	var/best_score
	for(var/turf/open/tile as anything in room)
		var/score = (tile.x - center_x) ** 2 + (tile.y - center_y) ** 2 + (tile.is_blocked_turf() ? ANTAG_TRAINING_ROOM_LIMIT : 0)
		if(!best || score < best_score)
			best = tile
			best_score = score
	return best

/proc/antag_training_restore_room_air(list/turf/open/room)
	for(var/turf/open/tile as anything in room)
		if(tile.active_hotspot)
			qdel(tile.active_hotspot)
		tile.air.copy_from_turf(tile)
		tile.air_update_turf(FALSE, FALSE)

/datum/antag_training_exercise/systems/mix
	id = "atmos_mix"
	name = "Смесь для дыхания"
	sector = "atmos"
	difficulty = 2
	par_time = 2 MINUTES
	steps = list(/datum/antag_training_exercise_step/checked/systems/mix_connect, /datum/antag_training_exercise_step/checked/systems/mix_tune, /datum/antag_training_exercise_step/checked/systems/mix_fill)

/datum/antag_training_exercise/systems/mix/New()
	. = ..()
	desc = "Стенд смесителя: кислород и азот на входы, смесь в пустую канистру на выходе. Засчитывается [ANTAG_TRAINING_MIX_OXYGEN - ANTAG_TRAINING_MIX_TOLERANCE]-[ANTAG_TRAINING_MIX_OXYGEN + ANTAG_TRAINING_MIX_TOLERANCE]% кислорода при давлении от [ANTAG_TRAINING_MIX_PRESSURE] кПа, проверка - когда канистру отсоединяют от порта или выключают смеситель."

/datum/antag_training_exercise/systems/mix/proc/mixer(datum/antag_training_sector/place)
	return locate(/obj/machinery/atmospherics/components/trinary/mixer) in place?.sector_area

/// Порт канистры на трубе узла смесителя: 1 и 2 - входы, 3 - выход.
/datum/antag_training_exercise/systems/mix/proc/port(obj/machinery/atmospherics/components/trinary/mixer/mixer, node)
	if(!mixer)
		return null
	var/datum/pipeline/line = mixer.parents[node]
	for(var/obj/machinery/atmospherics/components/unary/portables_connector/connector in line?.other_atmosmch)
		return connector

/datum/antag_training_exercise/systems/mix/proc/oxygen_node(obj/machinery/atmospherics/components/trinary/mixer/mixer)
	for(var/node in 1 to 2)
		var/obj/machinery/atmospherics/components/unary/portables_connector/connector = port(mixer, node)
		if(gas_share(connector?.connected_device?.air_contents, GAS_O2) >= 0.9)
			return node

/datum/antag_training_exercise/systems/mix/proc/gas_share(datum/gas_mixture/mixture, gas_id)
	var/total = mixture?.total_moles()
	return total > 0 ? mixture.get_moles(gas_id) / total : 0

/datum/antag_training_exercise/systems/mix/prepare(datum/antag_training_session/session, datum/antag_training_sector/place)
	var/obj/machinery/atmospherics/components/trinary/mixer/mixer = mixer(place)
	var/obj/machinery/atmospherics/components/unary/portables_connector/oxygen_port = port(mixer, 1)
	var/obj/machinery/atmospherics/components/unary/portables_connector/nitrogen_port = port(mixer, 2)
	var/obj/machinery/atmospherics/components/unary/portables_connector/output_port = port(mixer, 3)
	if(!oxygen_port || !nitrogen_port || !output_port)
		return "стенд смесителя разобран, сбросьте атмос-сектор"
	mixer.on = FALSE
	mixer.target_pressure = ONE_ATMOSPHERE
	mixer.adjust_node1_value(50)
	mixer.update_appearance()
	var/datum/antag_training_exercise_run/current = session.exercise_run
	if(!(locate(/obj/machinery/portable_atmospherics) in get_turf(oxygen_port)))
		current.add_prop(new /obj/machinery/portable_atmospherics/canister/oxygen(get_turf(oxygen_port)))
	if(!(locate(/obj/machinery/portable_atmospherics) in get_turf(nitrogen_port)))
		current.add_prop(new /obj/machinery/portable_atmospherics/canister/nitrogen(get_turf(nitrogen_port)))
	if(!(locate(/obj/machinery/portable_atmospherics/canister) in get_turf(output_port)))
		current.add_prop(new /obj/machinery/portable_atmospherics/canister/proto/training(get_turf(output_port)))
	for(var/obj/machinery/portable_atmospherics/canister/receiver in get_turf(output_port))
		receiver.air_contents.clear()
	var/datum/pipeline/line = mixer.parents[3]
	for(var/datum/gas_mixture/part as anything in line.get_all_connected_airs())
		part.clear()
	line.mark_dirty()
	return TRUE

/datum/antag_training_exercise/systems/mix/restore(datum/antag_training_session/session, datum/antag_training_sector/place)
	var/obj/machinery/atmospherics/components/trinary/mixer/mixer = mixer(place)
	if(mixer?.on)
		mixer.on = FALSE
		mixer.update_appearance()

/datum/antag_training_exercise_step/checked/systems/mix_connect
	name = "Подключите кислород и азот к входам смесителя"
	hint = "Стенд смесителя - за пожарными заслонками зала канистр. Порты входа подписаны на полу: сверху кислород на голубой трубе, снизу азот на бурой. На них стоят канистры этих газов: нажмите по каждой ключом, чтобы прикрутить её к порту."

/datum/antag_training_exercise_step/checked/systems/mix_connect/check()
	var/datum/antag_training_exercise/systems/mix/owner_exercise = run.exercise
	var/obj/machinery/atmospherics/components/trinary/mixer/mixer = owner_exercise.mixer(current_sector())
	var/oxygen_node = owner_exercise.oxygen_node(mixer)
	if(!oxygen_node)
		return FALSE
	var/obj/machinery/atmospherics/components/unary/portables_connector/other = owner_exercise.port(mixer, 3 - oxygen_node)
	return owner_exercise.gas_share(other?.connected_device?.air_contents, GAS_N2) >= 0.9

/datum/antag_training_exercise_step/checked/systems/mix_tune
	name = "Настройте и включите смеситель"
	hint = "Нажмите по смесителю рукой, задайте долю входа с кислородом и включите его."

/datum/antag_training_exercise_step/checked/systems/mix_tune/New()
	. = ..()
	hint = "Нажмите по смесителю рукой: входу с кислородом поставьте [ANTAG_TRAINING_MIX_OXYGEN]%, входу с азотом - [100 - ANTAG_TRAINING_MIX_OXYGEN]%, и включите. Выходного давления по умолчанию, [round(ONE_ATMOSPHERE)] кПа, хватит."

/datum/antag_training_exercise_step/checked/systems/mix_tune/check()
	var/datum/antag_training_exercise/systems/mix/owner_exercise = run.exercise
	var/obj/machinery/atmospherics/components/trinary/mixer/mixer = owner_exercise.mixer(current_sector())
	var/oxygen_node = owner_exercise.oxygen_node(mixer)
	if(!mixer?.on || !oxygen_node)
		return FALSE
	var/share = (oxygen_node == 1 ? mixer.node1_concentration : mixer.node2_concentration) * 100
	return abs(share - ANTAG_TRAINING_MIX_OXYGEN) <= ANTAG_TRAINING_MIX_TOLERANCE

/datum/antag_training_exercise_step/checked/systems/mix_fill
	name = "Наполните канистру и отсоедините её"
	hint = "Прикрутите пустую канистру к порту выхода смесителя ключом. Когда её давление дойдёт до нужного, открутите её ключом или выключите смеситель."
	var/datum/weakref/docked_ref
	/// null до первой проверки: тогда шаг запоминает, что стоит на порту, и ждёт перемен.
	var/mixer_was_on

/datum/antag_training_exercise_step/checked/systems/mix_fill/New()
	. = ..()
	hint = "Прикрутите пустую канистру к порту выхода смесителя ключом. Когда её давление дойдёт до [ANTAG_TRAINING_MIX_PRESSURE] кПа, открутите её ключом или выключите смеситель: тогда смесь и проверяется."

/datum/antag_training_exercise_step/checked/systems/mix_fill/check()
	var/datum/antag_training_exercise/systems/mix/owner_exercise = run.exercise
	var/obj/machinery/atmospherics/components/trinary/mixer/mixer = owner_exercise.mixer(current_sector())
	var/obj/machinery/atmospherics/components/unary/portables_connector/output_port = owner_exercise.port(mixer, 3)
	var/obj/machinery/portable_atmospherics/docked = output_port?.connected_device
	var/obj/machinery/portable_atmospherics/released = docked_ref?.resolve()
	var/switched_off = mixer_was_on && !mixer?.on
	var/first_look = isnull(mixer_was_on)
	mixer_was_on = !!mixer?.on
	if(first_look)
		docked_ref = docked ? WEAKREF(docked) : null
		return FALSE
	if(docked)
		docked_ref = WEAKREF(docked)
		return switched_off && accept(owner_exercise, docked)
	docked_ref = null
	return released && accept(owner_exercise, released)

/datum/antag_training_exercise_step/checked/systems/mix_fill/proc/accept(datum/antag_training_exercise/systems/mix/owner_exercise, obj/machinery/portable_atmospherics/canister)
	var/datum/gas_mixture/contents = canister.air_contents
	var/pressure = contents.return_pressure()
	var/oxygen = owner_exercise.gas_share(contents, GAS_O2) * 100
	if(pressure >= ANTAG_TRAINING_MIX_PRESSURE && abs(oxygen - ANTAG_TRAINING_MIX_OXYGEN) <= ANTAG_TRAINING_MIX_TOLERANCE)
		return TRUE
	to_chat(participant(), span_warning("В канистре [round(oxygen, 0.1)]% кислорода при [round(pressure)] кПа. Нужно [ANTAG_TRAINING_MIX_OXYGEN - ANTAG_TRAINING_MIX_TOLERANCE]-[ANTAG_TRAINING_MIX_OXYGEN + ANTAG_TRAINING_MIX_TOLERANCE]% и не меньше [ANTAG_TRAINING_MIX_PRESSURE] кПа: прикрутите её снова или возьмите другую пустую."))
	return FALSE

/datum/antag_training_exercise/systems/breach
	id = "atmos_breach"
	name = "Заделай пробой"
	sector = "atmos"
	difficulty = 2
	par_time = 2 MINUTES
	steps = list(/datum/antag_training_exercise_step/checked/systems/breach_window, /datum/antag_training_exercise_step/checked/systems/breach_pressure)

/datum/antag_training_exercise/systems/breach/New()
	. = ..()
	desc = "В зале пробоев разбивается окно вакуумной камеры, и пробой закрывает аварийная заслонка. Поставить новое окно, открыть заслонку и держать в зале не меньше [ANTAG_TRAINING_BREACH_PRESSURE] кПа."

/datum/antag_training_exercise/systems/breach/proc/chamber(datum/antag_training_sector/place)
	. = list()
	for(var/turf/open/floor/engine/vacuum/tile in place?.turfs)
		.[tile] = TRUE

/// Окно камеры с аварийной заслонкой: list(клетка окна, клетка зала за ним).
/datum/antag_training_exercise/systems/breach/proc/breach(datum/antag_training_sector/place)
	var/list/chamber = chamber(place)
	for(var/turf/open/tile as anything in chamber)
		for(var/direction in GLOB.cardinals)
			var/turf/open/edge = get_step(tile, direction)
			var/turf/open/hall = get_step(edge, direction)
			if(!istype(edge) || chamber[edge] || !istype(hall) || chamber[hall] || isspaceturf(hall))
				continue
			if((locate(/obj/machinery/door/firedoor) in edge) && !(locate(/obj/machinery/door/airlock) in edge))
				return list(edge, hall)

/datum/antag_training_exercise/systems/breach/proc/sealed(turf/edge)
	if(isclosedturf(edge))
		return TRUE
	for(var/obj/structure/window/pane in edge)
		if(pane.fulltile && pane.anchored)
			return TRUE
	return FALSE

/datum/antag_training_exercise/systems/breach/prepare(datum/antag_training_session/session, datum/antag_training_sector/place)
	var/list/spot = breach(place)
	if(!spot)
		return "окна вакуумной камеры разобраны, сбросьте атмос-сектор"
	var/turf/open/edge = spot[1]
	for(var/turf/open/tile as anything in chamber(place))
		tile.air.clear()
		tile.air_update_turf(FALSE, FALSE)
	var/obj/structure/grille/grille = locate() in edge
	if(grille?.broken)
		qdel(grille)
		grille = null
	if(!grille)
		new /obj/structure/grille(edge)
	for(var/obj/structure/window/pane in edge)
		pane.deconstruct(FALSE)
	return TRUE

/datum/antag_training_exercise/systems/breach/restore(datum/antag_training_session/session, datum/antag_training_sector/place)
	var/list/spot = breach(place)
	if(!spot || sealed(spot[1]))
		return
	for(var/obj/structure/window/pane in spot[1])
		if(pane.fulltile)
			pane.setAnchored(TRUE)
			return
	new /obj/structure/window/reinforced/fulltile(spot[1])

/datum/antag_training_exercise_step/checked/systems/breach_window
	name = "Поставьте новое окно на место разбитого"
	hint = "Пробой закрыла аварийная заслонка в окне камеры. Откройте её ломом или вручную (Alt+клик, несколько секунд), положите на решётку два листа стекла и прикрутите окно отвёрткой."

/datum/antag_training_exercise_step/checked/systems/breach_window/check()
	var/datum/antag_training_exercise/systems/breach/owner_exercise = run.exercise
	var/list/spot = owner_exercise.breach(current_sector())
	return spot && owner_exercise.sealed(spot[1])

/datum/antag_training_exercise_step/checked/systems/breach_pressure
	name = "Откройте заслонку и верните давление"
	hint = "Откройте заслонку ломом или вручную. Если в зале мало воздуха, откройте его пожарные заслонки в коридор или выпустите воздух из канистры."

/datum/antag_training_exercise_step/checked/systems/breach_pressure/New()
	. = ..()
	hint = "Откройте заслонку ломом или вручную. Если в зале меньше [ANTAG_TRAINING_BREACH_PRESSURE] кПа, откройте его пожарные заслонки в коридор или выпустите воздух из канистры."

/datum/antag_training_exercise_step/checked/systems/breach_pressure/check()
	var/datum/antag_training_exercise/systems/breach/owner_exercise = run.exercise
	return owner_exercise.pressure_restored(current_sector())

/// Окно камеры стоит, заслонка открыта, в зале не меньше ANTAG_TRAINING_BREACH_PRESSURE.
/datum/antag_training_exercise/systems/breach/proc/pressure_restored(datum/antag_training_sector/place)
	var/list/spot = breach(place)
	if(!spot || !sealed(spot[1]))
		return FALSE
	for(var/obj/machinery/door/firedoor/shutter in spot[1])
		if(shutter.density)
			return FALSE
	var/turf/open/hall = spot[2]
	return hall.air.return_pressure() >= ANTAG_TRAINING_BREACH_PRESSURE

/datum/antag_training_exercise/systems/fire
	id = "atmos_fire"
	name = "Потуши пожар"
	sector = "atmos"
	difficulty = 2
	par_time = 30 SECONDS
	steps = list(/datum/antag_training_exercise_step/checked/systems/fire_ready, /datum/antag_training_exercise_step/checked/systems/fire_out)

/datum/antag_training_exercise/systems/fire/New()
	. = ..()
	desc = "Плазма вспыхивает в вентиляционной комнате, как только вы входите туда с огнетушителем наготове. Пламя нужно сбить огнетушителем: если очаги горят, пока не выгорит [ANTAG_TRAINING_FIRE_BURNOUT * 100]% плазмы, упражнение провалено, а погасшее само пламя не засчитывается. Когда огня нет [ANTAG_TRAINING_FIRE_CALM_CHECKS * ANTAG_TRAINING_EXERCISE_CHECK_INTERVAL / (1 SECONDS)] с, вентиляция комнаты убирает остаток плазмы и жар."

/datum/antag_training_exercise/systems/fire/proc/room(datum/antag_training_sector/place)
	var/obj/machinery/airalarm/alarm = locate() in place?.sector_area
	return antag_training_room_turfs(get_turf(alarm), place)

/// Очаг на расстоянии ANTAG_TRAINING_FIRE_DISTANCE от участника, ближе к середине комнаты.
/datum/antag_training_exercise/systems/fire/proc/ignite(list/turf/open/room, mob/living/trainee)
	var/list/turf/open/candidates = list()
	for(var/turf/open/tile as anything in room)
		if(get_dist(tile, trainee) == ANTAG_TRAINING_FIRE_DISTANCE)
			candidates += tile
	var/turf/open/source = antag_training_room_center(length(candidates) ? candidates : room)
	source.air.adjust_moles(GAS_PLASMA, ANTAG_TRAINING_FIRE_PLASMA)
	source.air_update_turf(FALSE, FALSE)
	source.hotspot_expose(ANTAG_TRAINING_FIRE_IGNITION, CELL_VOLUME)

/datum/antag_training_exercise/systems/fire/prepare(datum/antag_training_session/session, datum/antag_training_sector/place)
	var/list/turf/open/room = room(place)
	if(!length(room))
		return "вентиляционной комнаты с пультом воздуха нет, сбросьте атмос-сектор"
	antag_training_restore_room_air(room)
	return TRUE

/datum/antag_training_exercise/systems/fire/restore(datum/antag_training_session/session, datum/antag_training_sector/place)
	antag_training_restore_room_air(room(place))
	if(place.sector_area.fire)
		place.sector_area.firereset()

/datum/antag_training_exercise_step/checked/systems/fire_ready
	name = "Войдите в вентиляционную комнату с огнетушителем"
	hint = "Огнетушители лежат на стойках поста пожарной безопасности и в пожарных шкафах, есть и в комплекте «Атмосферный техник». Снимите предохранитель, нажав огнетушителем в руке, и войдите в комнату за насосной, где висит пульт воздуха."

/datum/antag_training_exercise_step/checked/systems/fire_ready/check()
	var/mob/living/trainee = participant()
	var/obj/item/extinguisher/extinguisher = locate() in trainee?.held_items
	if(!extinguisher || extinguisher.safety)
		return FALSE
	var/datum/antag_training_exercise/systems/fire/owner_exercise = run.exercise
	var/list/turf/open/room = owner_exercise.room(current_sector())
	if(!(get_turf(trainee) in room))
		return FALSE
	owner_exercise.ignite(room, trainee)
	return TRUE

/datum/antag_training_exercise_step/checked/systems/fire_out
	name = "Потушите пожар"
	hint = "Распыляйте огнетушитель прямо по пламени, пока оно не погаснет: вода гасит и остужает только горящие клетки. Остаток плазмы и жар уберёт вентиляция комнаты."
	var/sprayed = FALSE
	/// Проверок подряд без очагов в комнате.
	var/calm_checks = 0

/datum/antag_training_exercise_step/checked/systems/fire_out/attach(datum/antag_training_exercise_run/owner)
	. = ..()
	var/mob/living/trainee = participant()
	if(trainee)
		RegisterSignal(trainee, COMSIG_MOB_ITEM_AFTERATTACK, PROC_REF(on_item_used))

/datum/antag_training_exercise_step/checked/systems/fire_out/proc/on_item_used(mob/living/source)
	SIGNAL_HANDLER
	var/obj/item/extinguisher/extinguisher = source.get_active_held_item()
	if(istype(extinguisher) && !extinguisher.safety && extinguisher.reagents?.total_volume >= 1)
		sprayed = TRUE

/datum/antag_training_exercise_step/checked/systems/fire_out/check()
	var/datum/antag_training_exercise/systems/fire/owner_exercise = run.exercise
	var/list/turf/open/room = owner_exercise.room(current_sector())
	if(!length(room))
		return FALSE
	var/plasma = 0
	var/burning = FALSE
	for(var/turf/open/tile as anything in room)
		plasma += tile.air.get_moles(GAS_PLASMA)
		burning ||= !QDELETED(tile.active_hotspot)
	if(burning)
		calm_checks = 0
		if(plasma < ANTAG_TRAINING_FIRE_PLASMA * ANTAG_TRAINING_FIRE_BURNOUT)
			run.finish(FALSE, "огонь не сбит вовремя и выжег [ANTAG_TRAINING_FIRE_BURNOUT * 100]% плазмы")
		return FALSE
	if(++calm_checks < ANTAG_TRAINING_FIRE_CALM_CHECKS)
		return FALSE
	if(!sprayed)
		run.finish(FALSE, "пламя погасло само, огнетушитель так и не пошёл в ход")
		return FALSE
	// Вода гасит только видимые очаги; разошедшуюся плазму и жар убирает вентиляция комнаты.
	antag_training_restore_room_air(room)
	return TRUE

/datum/antag_training_exercise/systems/internals
	id = "atmos_internals"
	name = "Разгерметизация: надень маску и баллон"
	sector = "atmos"
	difficulty = 1
	par_time = 30 SECONDS
	steps = list(/datum/antag_training_exercise_step/checked/systems/internals_mask, /datum/antag_training_exercise_step/checked/systems/internals_valve)

/datum/antag_training_exercise/systems/internals/New()
	. = ..()
	desc = "Вы оказываетесь в раздевалке, где давление падает до [round(ONE_ATMOSPHERE * ANTAG_TRAINING_DECOMPRESSION_RATIO)] кПа: дышать уже нечем, но скафандр ещё не нужен. Маска и подача из баллона - и можно дышать."

/datum/antag_training_exercise/systems/internals/proc/room(datum/antag_training_sector/place)
	var/obj/structure/tank_dispenser/dispenser = locate() in place?.sector_area
	return antag_training_room_turfs(get_turf(dispenser), place)

/datum/antag_training_exercise/systems/internals/prepare(datum/antag_training_session/session, datum/antag_training_sector/place)
	if(!ishuman(session.current_body))
		return "маску и баллон надевает только человеческое тело"
	var/list/turf/open/room = room(place)
	if(!length(room))
		return "раздевалки с раздатчиком баллонов нет, сбросьте атмос-сектор"
	if(!(get_turf(session.current_body) in room))
		session.current_body.forceMove(antag_training_room_center(room))
	for(var/turf/open/tile as anything in room)
		tile.air.copy_from_turf(tile)
		tile.air.multiply(ANTAG_TRAINING_DECOMPRESSION_RATIO)
		tile.air_update_turf(FALSE, FALSE)
	to_chat(session.current_body, span_userdanger("В раздевалке разгерметизация: воздуха почти не осталось!"))
	return TRUE

/datum/antag_training_exercise/systems/internals/restore(datum/antag_training_session/session, datum/antag_training_sector/place)
	antag_training_restore_room_air(room(place))

/datum/antag_training_exercise_step/checked/systems/internals_mask
	name = "Наденьте маску"
	hint = "Дыхательные маски и противогазы - на стойках раздевалки и в аварийных шкафах. Наденьте маску на лицо."

/datum/antag_training_exercise_step/checked/systems/internals_mask/attach(datum/antag_training_exercise_run/owner)
	. = ..()
	var/mob/living/trainee = participant()
	if(trainee)
		RegisterSignal(trainee, COMSIG_MOB_EQUIPPED_ITEM, PROC_REF(recheck))

/datum/antag_training_exercise_step/checked/systems/internals_mask/check()
	var/mob/living/carbon/human/trainee = participant()
	if(!istype(trainee))
		return FALSE
	for(var/obj/item/clothing/gear in GET_INTERNAL_SLOTS(trainee))
		if(gear.clothing_flags & ALLOWINTERNALS)
			return TRUE
	return FALSE

/datum/antag_training_exercise_step/checked/systems/internals_valve
	name = "Откройте подачу из баллона"
	hint = "Баллоны - в раздатчике у стены и в аварийных шкафах. Возьмите баллон в руку или на пояс и нажмите его кнопку на панели действий: вентиль откроется, если маска надета."

/datum/antag_training_exercise_step/checked/systems/internals_valve/check()
	var/mob/living/carbon/trainee = participant()
	return istype(trainee) && trainee.internal?.air_contents?.total_moles() > 0
