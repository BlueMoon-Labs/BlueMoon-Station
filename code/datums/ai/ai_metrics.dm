/// Глобальные счётчики стоимости AI: дешёвые ++ на горячих путях, снимаются
/// бенчмарком (ai_benchmark.dm) и админ-диагностикой. Всегда скомпилированы:
/// инкремент поля — копеечная операция, ветвлений на горячем пути не добавляем.
GLOBAL_DATUM_INIT(ai_metrics, /datum/ai_metrics, new)

/datum/ai_metrics
	///циклов планирования контроллеров/легаси-пассов принятия решений
	var/planning_cycles = 0
	///кандидатов в цель, рассмотренных фильтрами (CanAttack/targeting_strategy)
	var/candidates_examined = 0
	///проверок прямой видимости (can_see и аналоги) из кода поиска целей
	var/los_checks = 0
	///запросов полного JPS-поиска пути (get_path_to)
	var/jps_requests = 0
	///перепрокладок пути живыми move-лупами (COMSIG_MOVELOOP_JPS_REPATH)
	var/jps_repaths = 0
	///неудавшихся шагов движения AI-мобов
	var/failed_moves = 0
	///успешных шагов movement-loop контроллерных hostile-мобов
	var/successful_moves = 0
	///новых целей, записанных grid-based поиском hostile-контроллеров
	var/targets_acquired = 0
	///вызовов hearers() из поиска целей hostile-мобов
	var/hearers_calls = 0

/// Снимок всех счётчиков одним ассоц-списком (для JSON бенчмарка)
/datum/ai_metrics/proc/snapshot()
	return list(
		"planning_cycles" = planning_cycles,
		"candidates_examined" = candidates_examined,
		"los_checks" = los_checks,
		"jps_requests" = jps_requests,
		"jps_repaths" = jps_repaths,
		"failed_moves" = failed_moves,
		"successful_moves" = successful_moves,
		"targets_acquired" = targets_acquired,
		"hearers_calls" = hearers_calls,
	)

/datum/ai_metrics/proc/reset()
	planning_cycles = 0
	candidates_examined = 0
	los_checks = 0
	jps_requests = 0
	jps_repaths = 0
	failed_moves = 0
	successful_moves = 0
	targets_acquired = 0
	hearers_calls = 0

/// Разница между текущим состоянием и ранее взятым снимком
/datum/ai_metrics/proc/delta_since(list/base_snapshot)
	var/list/current = snapshot()
	var/list/result = list()
	for(var/metric_key in current)
		result[metric_key] = current[metric_key] - base_snapshot[metric_key]
	return result
