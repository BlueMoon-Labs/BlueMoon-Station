/// Отдел -> чем он живёт: ключевая машина, её плата и похожие подтипы, которые не в счёт
GLOBAL_LIST_INIT(brother_discord_targets, list(
	"наука" = list(
		"name" = "научный отдел",
		"machine" = /obj/machinery/rnd/server,
		"machine_name" = "сервер исследований",
		"board" = /obj/item/circuitboard/machine/rdserver,
	),
	"медицина" = list(
		"name" = "медицинский отдел",
		"machine" = /obj/machinery/chem_dispenser,
		"machine_name" = "химический раздатчик",
		"board" = /obj/item/circuitboard/machine/chem_dispenser,
		"exclude" = list(
			/obj/machinery/chem_dispenser/drinks,
			/obj/machinery/chem_dispenser/mutagensaltpeter,
			/obj/item/circuitboard/machine/chem_dispenser/drinks,
			/obj/item/circuitboard/machine/chem_dispenser/mutagensaltpeter,
		),
	),
	"снабжение" = list(
		"name" = "отдел снабжения",
		"machine" = /obj/machinery/computer/cargo,
		"machine_name" = "консоль снабжения",
		"board" = /obj/item/circuitboard/computer/cargo,
		"exclude" = list(/obj/machinery/computer/cargo/request, /obj/item/circuitboard/computer/cargo/request),
	),
	"инженерия" = list(
		"name" = "инженерный отдел",
		"machine" = /obj/machinery/power/smes,
		"machine_name" = "энергонакопитель",
		"board" = /obj/item/circuitboard/machine/smes,
	),
	"сервис" = list(
		"name" = "сервисный отдел",
		"machine" = /obj/machinery/processor,
		"machine_name" = "кухонный процессор",
		"board" = /obj/item/circuitboard/machine/processor,
		"exclude" = list(/obj/machinery/processor/slime),
	),
))

/// Целые ключевые машины отдела на станции
/proc/brother_discord_machines(department)
	. = list()
	var/list/target_info = GLOB.brother_discord_targets[department]
	if(!target_info)
		return
	for(var/obj/machinery/machine as anything in SSmachines.get_machines_by_type_and_subtypes(target_info["machine"]))
		if((machine.machine_stat & BROKEN) || is_type_in_list(machine, target_info["exclude"]))
			continue
		var/turf/machine_turf = get_turf(machine)
		if(machine_turf && is_station_level(machine_turf.z) && brother_area_department(get_area(machine)) == department)
			. += machine

/// Щитки отдела на станции, которые сейчас дают ток
/proc/brother_discord_powered_apcs(department)
	. = list()
	for(var/obj/machinery/power/apc/apc as anything in GLOB.apcs_list)
		var/turf/apc_turf = get_turf(apc)
		if(!apc_turf || !is_station_level(apc_turf.z) || brother_area_department(apc.area) != department)
			continue
		if(!brother_apc_unpowered(apc))
			. += apc

/proc/brother_apc_unpowered(obj/machinery/power/apc/apc)
	return QDELETED(apc) || !apc.operating || apc.shorted || !apc.cell || apc.cell.charge <= 0 || (apc.machine_stat & BROKEN)

/// Ключевая машина словами и так, как её зовёт игра: «энергонакопитель «power storage unit»»
/proc/brother_discord_machine_text(list/target_info)
	var/obj/machinery/machine_type = target_info["machine"]
	return "[target_info["machine_name"]] «[format_text(initial(machine_type.name))]»"

/// Целая ключевая машина отдела стоит на spot
/proc/brother_discord_machine_at(turf/spot, list/target_info)
	for(var/obj/machinery/machine in spot)
		if(istype(machine, target_info["machine"]) && !is_type_in_list(machine, target_info["exclude"]) && !(machine.machine_stat & BROKEN))
			return TRUE
	return FALSE

/// Щиток под током висит на spot
/proc/brother_discord_powered_apc_at(turf/spot)
	for(var/obj/machinery/power/apc/apc in spot)
		if(!brother_apc_unpowered(apc))
			return TRUE
	return FALSE

/datum/blood_oath/discord
	name = "Разлад"
	key = "discord"
	summary = "обесточить отдел, сломать его машину и унести плату"
	weight = 5
	round_types = list(ROUNDTYPE_DYNAMIC_MEDIUM, ROUNDTYPE_DYNAMIC_HARD, ROUNDTYPE_DYNAMIC_TEAMBASED)
	capstone_type = /datum/action/cooldown/blood_bond/capstone/blackout
	kit_items = list(BROTHER_KIT_BREAKIN)
	var/department

/datum/blood_oath/discord/available(datum/team/brother_team/for_team)
	return !for_team.training && ..()

/datum/blood_oath/discord/prepare(datum/team/brother_team/for_team)
	. = ..()
	if(for_team.training)
		return FALSE
	var/list/candidates = discord_candidates()
	if(!length(candidates))
		return FALSE
	set_department(pick(candidates))
	return TRUE

/// Отделы, где есть хоть одна целая ключевая машина
/datum/blood_oath/discord/proc/discord_candidates()
	. = list()
	for(var/candidate in GLOB.brother_discord_targets)
		if(length(brother_discord_machines(candidate)))
			. += candidate

/datum/blood_oath/discord/proc/set_department(new_department)
	department = new_department
	QDEL_LIST(steps)
	add_step(new /datum/blood_oath_step/discord_blackout)
	add_step(new /datum/blood_oath_step/discord_machine)
	add_step(new /datum/blood_oath_step/discord_board)
	var/list/target_info = GLOB.brother_discord_targets[department]
	story = "[capitalize(target_info["name"])] перешёл вам дорогу. Пусть встанет: обесточьте его, сломайте [brother_discord_machine_text(target_info)] и унесите плату, чтобы быстро не починили."

/datum/blood_oath_step/discord_blackout
	name = "Обесточить"
	/// Щитки, что давали ток в момент клятвы: WEAKREF -> турф щитка
	var/list/datum/weakref/watched_apcs = list()

/datum/blood_oath_step/discord_blackout/describe()
	var/datum/blood_oath/discord/discord_oath = oath
	var/list/target_info = GLOB.brother_discord_targets[discord_oath.department]
	name = "Обесточить: [target_info["name"]]"
	desc = "Любой щиток (APC) отдела без тока: выключен рубильник, перерезаны провода, нет батареи или она села, щиток разбит или снят. Щитки, обесточенные ещё до клятвы, не в счёт, как и снятый щиток, на месте которого уже висит новый под током."

/datum/blood_oath_step/discord_blackout/on_sworn()
	var/datum/blood_oath/discord/discord_oath = oath
	watched_apcs.Cut()
	for(var/obj/machinery/power/apc/apc as anything in brother_discord_powered_apcs(discord_oath.department))
		watched_apcs[WEAKREF(apc)] = get_turf(apc)

/datum/blood_oath_step/discord_blackout/can_seal(mob/living/sealer)
	if(!length(watched_apcs))
		return TRUE
	for(var/datum/weakref/apc_ref as anything in watched_apcs)
		var/obj/machinery/power/apc/apc = apc_ref.resolve()
		if(QDELETED(apc) ? !brother_discord_powered_apc_at(watched_apcs[apc_ref]) : brother_apc_unpowered(apc))
			return TRUE
	return "все щитки отдела под током"

/datum/blood_oath_step/discord_blackout/condition_text(mob/living/viewer, sealable)
	return "щиток без тока: [sealable_now(viewer, sealable) ? "да" : "нет"]"

/datum/blood_oath_step/discord_machine
	name = "Сломать"
	/// Ключевые машины, что работали в момент клятвы: WEAKREF -> турф машины
	var/list/datum/weakref/watched_machines = list()

/datum/blood_oath_step/discord_machine/describe()
	var/datum/blood_oath/discord/discord_oath = oath
	var/list/target_info = GLOB.brother_discord_targets[discord_oath.department]
	name = "Сломать: [target_info["machine_name"]]"
	desc = "Сломайте или разберите в отделе [brother_discord_machine_text(target_info)]. Годится любая такая машина, что работала в момент клятвы. Если на месте разобранной уже стоит новая целая, шаг не засчитан."

/datum/blood_oath_step/discord_machine/on_sworn()
	var/datum/blood_oath/discord/discord_oath = oath
	watched_machines.Cut()
	for(var/obj/machinery/machine as anything in brother_discord_machines(discord_oath.department))
		watched_machines[WEAKREF(machine)] = get_turf(machine)

/datum/blood_oath_step/discord_machine/can_seal(mob/living/sealer)
	if(!length(watched_machines))
		return TRUE
	var/datum/blood_oath/discord/discord_oath = oath
	var/list/target_info = GLOB.brother_discord_targets[discord_oath.department]
	for(var/datum/weakref/machine_ref as anything in watched_machines)
		var/obj/machinery/machine = machine_ref.resolve()
		if(QDELETED(machine) ? !brother_discord_machine_at(watched_machines[machine_ref], target_info) : (machine.machine_stat & BROKEN))
			return TRUE
	return "все такие машины отдела целы"

/datum/blood_oath_step/discord_machine/condition_text(mob/living/viewer, sealable)
	return "машина сломана: [sealable_now(viewer, sealable) ? "да" : "нет"]"

/datum/blood_oath_step/discord_board
	name = "Унести плату"
	/// Платы ключевых машин в момент клятвы
	var/list/datum/weakref/watched_boards = list()

/datum/blood_oath_step/discord_board/describe()
	var/datum/blood_oath/discord/discord_oath = oath
	var/list/target_info = GLOB.brother_discord_targets[discord_oath.department]
	name = "Унести плату: [target_info["machine_name"]]"
	desc = "Плата той самой машины у любого из братьев: [brother_discord_machine_text(target_info)] из отдела. Её можно достать из разобранной машины, новая плата не годится."

/datum/blood_oath_step/discord_board/on_sworn()
	var/datum/blood_oath/discord/discord_oath = oath
	watched_boards.Cut()
	for(var/obj/machinery/machine as anything in brother_discord_machines(discord_oath.department))
		if(istype(machine.circuit))
			watched_boards += WEAKREF(machine.circuit)

/datum/blood_oath_step/discord_board/can_seal(mob/living/sealer)
	var/datum/blood_oath/discord/discord_oath = oath
	var/list/target_info = GLOB.brother_discord_targets[discord_oath.department]
	for(var/obj/item/board as anything in brother_team_items(oath.team, target_info["board"]))
		if(is_type_in_list(board, target_info["exclude"]))
			continue
		if(!length(watched_boards) || (WEAKREF(board) in watched_boards))
			return TRUE
	return "на брате нет платы той самой машины: [target_info["machine_name"]]"

/datum/blood_oath_step/discord_board/condition_text(mob/living/viewer, sealable)
	return "на брате: [sealable_now(viewer, sealable) ? "да" : "нет"]"
