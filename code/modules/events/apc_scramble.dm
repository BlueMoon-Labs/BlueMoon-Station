/// Сколько щитков зацепит скрамблер
#define APC_SCRAMBLE_MIN 3
#define APC_SCRAMBLE_MAX 6

/// Скрамблер APC (идея goonstation): у нескольких щитков по станции тихо отщёлкиваются
/// случайные каналы - где-то гаснет свет, где-то умолкают автолампы и консоли. Ничего
/// не ломается: достаточно открыть интерфейс щитка и вернуть тумблер. Вся соль в
/// маленькой загадке "почему в этом отсеке темно".
/datum/round_event_control/apc_scramble
	name = "APC Scramble"
	typepath = /datum/round_event/apc_scramble
	weight = 30
	max_occurrences = 4
	earliest_start = 10 MINUTES
	alert_observers = FALSE
	category = EVENT_CATEGORY_ENGINEERING
	// Категория ENGINEERING по умолчанию даёт MODERATE; пара погасших отсеков - мелочь
	severity = DIRECTOR_SEVERITY_MINOR
	family = "petty_power" // с Wire Feast: две тихие электро-неприятности подряд - перебор
	description = "A few APCs quietly flip random power channels off until someone resets them."

/datum/round_event/apc_scramble
	fakeable = FALSE
	/// Сколько щитков скрамблить в этот раз
	var/scramble_count = 0

/datum/round_event/apc_scramble/setup()
	scramble_count = rand(APC_SCRAMBLE_MIN, APC_SCRAMBLE_MAX)

/datum/round_event/apc_scramble/start()
	var/list/obj/machinery/power/apc/candidates = list()
	for(var/obj/machinery/power/apc/target as anything in GLOB.apcs_list)
		var/turf/apc_turf = get_turf(target)
		if(!apc_turf || !is_station_level(apc_turf.z))
			continue
		// Обесточенный или закороченный щиток и так не работает - соль в тихом щелчке на живом
		if(target.machine_stat & (NOPOWER|BROKEN))
			continue
		if(!target.cell || target.shorted || !target.operating)
			continue
		candidates += target
		CHECK_TICK
	if(!length(candidates))
		return kill()
	for(var/i in 1 to min(scramble_count, length(candidates)))
		var/obj/machinery/power/apc/victim = pick_n_take(candidates)
		victim.scramble_channel()
		CHECK_TICK

#undef APC_SCRAMBLE_MIN
#undef APC_SCRAMBLE_MAX
