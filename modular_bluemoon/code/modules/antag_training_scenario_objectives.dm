#define ANTAG_TRAINING_SCENARIO_HEALED 0.9

/// Цель стороны в сценарии: check() раз в ANTAG_TRAINING_SCENARIO_CHECK, выполненная цель остаётся выполненной.
/datum/antag_training_scenario_objective
	var/name = "Цель"
	var/side
	var/datum/antag_training_scenario/scenario
	var/done = FALSE
	var/done_at = 0

/datum/antag_training_scenario_objective/New(datum/antag_training_scenario/owner, side_id, list/params)
	scenario = owner
	side = side_id
	for(var/key in params)
		if(key in vars)
			vars[key] = params[key]

/datum/antag_training_scenario_objective/Destroy()
	scenario = null
	return ..()

/// Готовит обстановку цели на старте. TRUE или текст, почему цель не подготовить.
/datum/antag_training_scenario_objective/proc/bind()
	return bind_problem() || TRUE

/// Почему цель не подготовить, без следов на месте: проверяется до пересборки тел. null - можно.
/datum/antag_training_scenario_objective/proc/bind_problem()
	return null

/// Сколько учебных целей поставит bind(): весь лист сверяется с лимитом полигона заранее.
/datum/antag_training_scenario_objective/proc/targets_needed()
	return 0

/datum/antag_training_scenario_objective/proc/teardown()
	return

/datum/antag_training_scenario_objective/proc/check()
	return FALSE

/// Ход цели в пульте («1 из 3») или null.
/datum/antag_training_scenario_objective/proc/progress()
	return null

/// Все участники стороны target в крите, мертвы, в наручниках или уже выбывали.
/datum/antag_training_scenario_objective/side_down
	name = "Вывести из строя противника"
	var/target

/datum/antag_training_scenario_objective/side_down/check()
	return scenario.side_down(target)

/datum/antag_training_scenario_objective/side_down/progress()
	var/list/members = scenario.side_members(target)
	var/down = 0
	for(var/datum/antag_training_session/member as anything in members)
		if(scenario.member_down(member))
			down++
	return "выведено [down] из [length(members)]"

/// Каждый оставшийся в игре участник стороны target в наручниках внутри зоны; выбывшие (убитые) засчитываются как задержанные.
/datum/antag_training_scenario_objective/detain
	name = "Задержать и доставить в бриг"
	var/target
	var/zone = "brig"
	var/list/zone_turfs

/datum/antag_training_scenario_objective/detain/bind_problem()
	if(!length(scenario.venue.zone_turfs(zone)))
		return "[scenario.venue.where()] у места «[scenario.place_name(zone)]» нет замкнутой комнаты"
	return null

/datum/antag_training_scenario_objective/detain/bind()
	. = ..()
	if(. != TRUE)
		return
	var/list/room = scenario.venue.zone_turfs(zone)
	zone_turfs = list()
	for(var/turf/tile as anything in room)
		zone_turfs[tile] = TRUE
	return TRUE

/datum/antag_training_scenario_objective/detain/teardown()
	zone_turfs = null

/datum/antag_training_scenario_objective/detain/check()
	var/list/members = scenario.side_members(target)
	for(var/datum/antag_training_session/member as anything in members)
		if(scenario.eliminated[member])
			continue
		var/mob/living/carbon/prisoner = member.current_body
		if(!istype(prisoner) || !prisoner.handcuffed || prisoner.stat == DEAD || !zone_turfs?[get_turf(prisoner)])
			return FALSE
	return length(members) > 0

/// Предмет кладётся у метки source; цель - пронести его в зону zone в руках или вещах участника стороны.
/datum/antag_training_scenario_objective/steal
	name = "Вынести предмет"
	var/item_type = /obj/item/documents/nanotrasen
	var/source
	var/zone
	var/list/zone_turfs
	var/datum/weakref/item_ref

/datum/antag_training_scenario_objective/steal/bind_problem()
	if(!scenario.venue.place_turf(source))
		return "[scenario.venue.where()] нет места «[scenario.place_name(source)]» для предмета"
	if(!length(scenario.venue.zone_turfs(zone)))
		return "[scenario.venue.where()] у места «[scenario.place_name(zone)]» нет замкнутой комнаты для выноса"
	return null

/datum/antag_training_scenario_objective/steal/bind()
	. = ..()
	if(. != TRUE)
		return
	var/turf/start = scenario.venue.place_turf(source)
	var/list/room = scenario.venue.zone_turfs(zone)
	var/obj/item/loot = scenario.venue.arena.issue_item(item_type, start, 1, scenario.squad.leader)
	if(!loot)
		return "на полигоне исчерпан лимит выданных вещей, уберите лишнее очисткой своих объектов"
	item_ref = WEAKREF(loot)
	scenario.add_prop(loot)
	zone_turfs = list()
	for(var/turf/tile as anything in room)
		zone_turfs[tile] = TRUE
	return TRUE

/datum/antag_training_scenario_objective/steal/teardown()
	zone_turfs = null
	item_ref = null

/datum/antag_training_scenario_objective/steal/check()
	var/obj/item/loot = item_ref?.resolve()
	if(QDELETED(loot) || !zone_turfs?[get_turf(loot)])
		return FALSE
	var/mob/living/holder = get(loot.loc, /mob/living)
	if(!holder)
		return FALSE
	for(var/datum/antag_training_session/member as anything in scenario.side_members(side))
		if(member.current_body == holder && !scenario.eliminated[member])
			return TRUE
	return FALSE

/datum/antag_training_scenario_objective/steal/progress()
	return item_ref?.resolve() ? null : "предмет уничтожен"

/// Сторона держится minutes минут, и хотя бы один её участник ни разу не выбыл.
/datum/antag_training_scenario_objective/survive
	var/minutes = 10

/datum/antag_training_scenario_objective/survive/New(datum/antag_training_scenario/owner, side_id, list/params)
	..()
	if(!params?["name"])
		name = "Продержаться [minutes] мин"

/datum/antag_training_scenario_objective/survive/check()
	if(world.time < scenario.started_at + minutes MINUTES)
		return FALSE
	for(var/datum/antag_training_session/member as anything in scenario.side_members(side))
		if(!scenario.eliminated[member])
			return TRUE
	return FALSE

/datum/antag_training_scenario_objective/survive/progress()
	return "осталось [antag_training_clock(scenario.started_at + minutes MINUTES - world.time)]"

/// Щиток места обесточен на старте: рубильник выключен, батареи щитка и SMES пусты.
/datum/antag_training_scenario_objective/restore_power
	name = "Вернуть питание"
	var/datum/weakref/board_ref

/datum/antag_training_scenario_objective/restore_power/proc/board()
	var/area/place = scenario.venue.power_area()
	var/obj/machinery/power/apc/board = place ? (locate(/obj/machinery/power/apc) in place) : null
	return (QDELETED(board) || (board.machine_stat & BROKEN)) ? null : board

/datum/antag_training_scenario_objective/restore_power/bind_problem()
	return board() ? null : "[scenario.venue.where()] нет исправного щитка APC"

/datum/antag_training_scenario_objective/restore_power/bind()
	. = ..()
	if(. != TRUE)
		return
	var/area/place = scenario.venue.power_area()
	var/obj/machinery/power/apc/board = board()
	for(var/obj/machinery/power/smes/storage in place)
		storage.charge = 0
		storage.update_appearance()
	if(board.cell)
		board.cell.charge = 0
	board.operating = FALSE
	board.update()
	board.update_appearance()
	board_ref = WEAKREF(board)
	return TRUE

/datum/antag_training_scenario_objective/restore_power/teardown()
	board_ref = null

/datum/antag_training_scenario_objective/restore_power/check()
	var/obj/machinery/power/apc/board = board_ref?.resolve()
	var/area/place = scenario.venue.power_area()
	return !QDELETED(board) && board.operating && place?.powered(LIGHT) && place.powered(EQUIP)

/datum/antag_training_scenario_objective/restore_power/progress()
	var/obj/machinery/power/apc/board = board_ref?.resolve()
	if(QDELETED(board))
		return "щиток разобран"
	return board.operating ? "рубильник включён, питания нет" : "рубильник выключен"

/// Окно вакуумной камеры атмос-сектора разбито, как в упражнении «Заделай пробой».
/datum/antag_training_scenario_objective/restore_pressure
	name = "Заделать пробой и вернуть давление"
	var/exercise_id = "atmos_breach"

/datum/antag_training_scenario_objective/restore_pressure/proc/breach()
	var/datum/antag_training_exercise/systems/breach/breach = GLOB.antag_training_exercises[exercise_id]
	return istype(breach) ? breach : null

/datum/antag_training_scenario_objective/restore_pressure/bind_problem()
	var/datum/antag_training_exercise/systems/breach/breach = breach()
	var/datum/antag_training_sector/place = scenario.venue.sector()
	return (!breach || place?.id != breach.sector) ? "пробой готовится только в атмос-секторе" : null

/datum/antag_training_scenario_objective/restore_pressure/bind()
	. = ..()
	if(. != TRUE)
		return
	var/datum/antag_training_exercise/systems/breach/breach = breach()
	var/datum/antag_training_sector/place = scenario.venue.sector()
	var/prepared = breach.prepare(null, place)
	return prepared == TRUE ? TRUE : (prepared || "окно камеры не разбить")

/datum/antag_training_scenario_objective/restore_pressure/check()
	var/datum/antag_training_exercise/systems/breach/breach = breach()
	return !!breach?.pressure_restored(scenario.venue.sector())

/// Пострадавшие встают у метки zone; цель - вылечить всех почти до полного здоровья.
/datum/antag_training_scenario_objective/heal
	name = "Вылечить пострадавших"
	var/count = 3
	var/zone
	var/brute = 40
	var/burn = 30
	var/list/datum/weakref/patients = list()

/datum/antag_training_scenario_objective/heal/targets_needed()
	return count

/datum/antag_training_scenario_objective/heal/bind_problem()
	var/datum/antag_training_arena/arena = scenario.venue.arena
	return arena.has_target_room(count) ? null : arena.target_limit_refusal()

/datum/antag_training_scenario_objective/heal/bind()
	. = ..()
	if(. != TRUE)
		return
	var/datum/antag_training_arena/arena = scenario.venue.arena
	var/turf/near = scenario.venue.place_turf(zone)
	for(var/index in 1 to count)
		var/mob/living/carbon/human/patient = arena.spawn_creature("human", scenario.venue.target_zone(), FALSE, scenario.squad.leader, near)
		if(!patient)
			return "пострадавших не поставить"
		patient.real_name = "Пострадавший [index]"
		patient.name = patient.real_name
		patient.apply_damage(brute, BRUTE, BODY_ZONE_CHEST, forced = TRUE, wound_bonus = CANT_WOUND)
		patient.apply_damage(burn, BURN, BODY_ZONE_CHEST, forced = TRUE, wound_bonus = CANT_WOUND)
		patients += WEAKREF(patient)
		scenario.add_prop(patient)
	return TRUE

/datum/antag_training_scenario_objective/heal/teardown()
	patients.Cut()

/datum/antag_training_scenario_objective/heal/proc/healed()
	. = 0
	for(var/datum/weakref/patient_ref as anything in patients)
		var/mob/living/patient = patient_ref.resolve()
		if(!QDELETED(patient) && patient.stat != DEAD && patient.health >= patient.maxHealth * ANTAG_TRAINING_SCENARIO_HEALED)
			.++

/datum/antag_training_scenario_objective/heal/check()
	return length(patients) && healed() >= length(patients)

/datum/antag_training_scenario_objective/heal/progress()
	return "вылечено [healed()] из [length(patients)]"

/// Своя цель программы участника стороны, например взрыв учебной бомбы оперативником.
/datum/antag_training_scenario_objective/program_goal
	name = "Выполнить цель роли"

/datum/antag_training_scenario_objective/program_goal/check()
	for(var/datum/antag_training_session/member as anything in scenario.side_members(side))
		if(member.program?.scenario_goal_reached(member))
			return TRUE
	return FALSE

#undef ANTAG_TRAINING_SCENARIO_HEALED
