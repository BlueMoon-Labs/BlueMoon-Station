// Возобновляемое построение пайпнетов. Раунд 9884: бомба на прибытии срезала
// дистро, и один фаер SSair строил сеть станции целиком - 700-850мс фриза на
// каждый большой взрыв. Теперь BFS-обход живёт пакетом в SSair.expansion_queue
// и уступает тик внутри обхода; эти тесты покрывают оба пути (блокирующий и
// отложенный), паузу посреди обхода и синхронный доезд через merge/addMember.

///Кладёт горизонтальную линию простых труб от run_loc и возвращает список.
///Только размещение и направления: atmosinit по всем - отдельным проходом,
///чтобы соседи уже стояли на месте.
/datum/unit_test/proc/lay_pipe_row(turf/open/origin, count)
	var/list/pipes = list()
	for(var/i in 0 to count - 1)
		var/turf/open/spot = locate(origin.x + i, origin.y, origin.z)
		TEST_ASSERT(istype(spot), "test reservation has no open turf at column [i]")
		var/obj/machinery/atmospherics/pipe/simple/segment = allocate(/obj/machinery/atmospherics/pipe/simple, spot)
		segment.setDir(EAST)
		segment.SetInitDirections()
		pipes += segment
	for(var/obj/machinery/atmospherics/pipe/simple/segment as anything in pipes)
		segment.atmosinit()
	return pipes

/// Блокирующий путь: сеть обязана быть готова сразу по возвращении.
/datum/unit_test/atmos_pipenet_blocking_build/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")
	var/list/obj/machinery/atmospherics/pipe/simple/pipes = lay_pipe_row(run_loc_floor_bottom_left, 4)

	var/obj/machinery/atmospherics/pipe/simple/first = pipes[1]
	first.build_network(blocking = TRUE)
	var/datum/pipeline/net = first.parent
	TEST_ASSERT_NOTNULL(net, "blocking build_network left the base pipe without a parent")
	TEST_ASSERT(!net.building, "blocking build left the pipeline in the building state")
	TEST_ASSERT_EQUAL(length(net.members), 4, "blocking build collected [length(net.members)] members instead of 4")
	for(var/obj/machinery/atmospherics/pipe/simple/segment as anything in pipes)
		TEST_ASSERT(segment.parent == net, "a pipe of the row ended up outside the blocking-built pipeline")
	var/expected_volume = 4 * first.volume
	TEST_ASSERT_EQUAL(net.air.return_volume(), expected_volume, "blocking build volume is [net.air.return_volume()] instead of [expected_volume]")

/// Разрыв сети: соседи разрушенной трубы встают в очередь ребилда по флагу
/// (без линейного скана и без дублей), фаза достраивает оба осколка.
/datum/unit_test/atmos_pipenet_deferred_rebuild/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")
	var/list/obj/machinery/atmospherics/pipe/simple/pipes = lay_pipe_row(run_loc_floor_bottom_left, 4)
	var/obj/machinery/atmospherics/pipe/simple/first = pipes[1]
	first.build_network(blocking = TRUE)

	var/obj/machinery/atmospherics/pipe/simple/left = pipes[1]
	var/obj/machinery/atmospherics/pipe/simple/casualty = pipes[2]
	var/obj/machinery/atmospherics/pipe/simple/right = pipes[3]
	var/obj/machinery/atmospherics/pipe/simple/far_right = pipes[4]

	qdel(casualty)
	TEST_ASSERT(left.rebuild_queued, "the west neighbour of a destroyed pipe was not queued for rebuild")
	TEST_ASSERT(right.rebuild_queued, "the east neighbour of a destroyed pipe was not queued for rebuild")

	// Повторное добавление обязано быть no-op: флаг заменил `in`-скан.
	var/queued_before = length(SSair.pipenets_needing_rebuilt)
	SSair.add_to_rebuild_queue(left)
	TEST_ASSERT_EQUAL(length(SSair.pipenets_needing_rebuilt), queued_before, "add_to_rebuild_queue double-queued a flagged machine")

	// MC_TICK_CHECK внутри фазы зовёт pause() при state != SS_RUNNING, поэтому
	// состояние подсистемы подкладывается на время прямого вызова и ВОЗВРАЩАЕТСЯ
	// КАК БЫЛО: SSair в этот момент может быть SS_QUEUED или SS_PAUSED в очереди
	// МК, и слепая запись ломает его бухгалтерию до конца прогона (см.
	// measure_passes в ai_benchmark.dm).
	var/saved_ticklimit = Master.current_ticklimit
	var/saved_state = SSair.state
	Master.current_ticklimit = INFINITY
	SSair.state = SS_RUNNING
	SSair.process_rebuild_queue()
	Master.current_ticklimit = saved_ticklimit
	SSair.state = saved_state

	TEST_ASSERT_EQUAL(length(SSair.expansion_queue), 0, "the expansion queue was not drained")
	TEST_ASSERT(!left.rebuild_queued && !right.rebuild_queued, "rebuild flags were not cleared by the rebuild phase")
	TEST_ASSERT_NOTNULL(left.parent, "the west shard was not rebuilt")
	TEST_ASSERT_NOTNULL(right.parent, "the east shard was not rebuilt")
	TEST_ASSERT(!left.parent.building && !right.parent.building, "a rebuilt shard is still marked as building")
	TEST_ASSERT(left.parent != right.parent, "severed shards were rebuilt into a single pipeline")
	TEST_ASSERT(far_right.parent == right.parent, "the far east pipe fell out of its shard")
	TEST_ASSERT_EQUAL(left.parent.air.return_volume(), left.volume, "west shard volume is wrong")
	TEST_ASSERT_EQUAL(right.parent.air.return_volume(), 2 * right.volume, "east shard volume is wrong")

/// Пауза посреди обхода: с нулевым бюджетом тика фаза обязана отдать управление,
/// не потеряв состояние, и доесть сеть на следующем заходе.
/datum/unit_test/atmos_pipenet_expansion_pause/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")
	var/list/obj/machinery/atmospherics/pipe/simple/pipes = lay_pipe_row(run_loc_floor_bottom_left, 4)
	var/obj/machinery/atmospherics/pipe/simple/first = pipes[1]

	first.build_network()
	var/datum/pipeline/net = first.parent
	TEST_ASSERT_NOTNULL(net, "deferred build_network did not seed a pipeline")
	TEST_ASSERT(net.building, "deferred build_network did not enter the building state")
	TEST_ASSERT_EQUAL(length(SSair.expansion_queue), 1, "deferred build_network did not queue an expansion packet")

	// См. комментарий в тесте deferred_rebuild: состояние вернуть КАК БЫЛО.
	var/saved_ticklimit = Master.current_ticklimit
	var/saved_state = SSair.state
	// Нулевой бюджет: первый же MC_TICK_CHECK внутри обхода пасует фазу.
	Master.current_ticklimit = 0
	SSair.state = SS_RUNNING
	SSair.process_rebuild_queue()
	TEST_ASSERT(net.building, "a paused expansion dropped the building flag")
	TEST_ASSERT_EQUAL(length(SSair.expansion_queue), 1, "a paused expansion lost its packet")
	TEST_ASSERT(length(net.members) < 4, "a zero-budget pass somehow completed the whole BFS")

	Master.current_ticklimit = INFINITY
	SSair.state = SS_RUNNING
	SSair.process_rebuild_queue()
	Master.current_ticklimit = saved_ticklimit
	SSair.state = saved_state

	TEST_ASSERT(!net.building, "the resumed expansion never finished")
	TEST_ASSERT_EQUAL(length(SSair.expansion_queue), 0, "the resumed expansion left its packet behind")
	TEST_ASSERT_EQUAL(length(net.members), 4, "the resumed expansion collected [length(net.members)] members instead of 4")
	TEST_ASSERT_EQUAL(net.air.return_volume(), 4 * first.volume, "the resumed expansion volume is wrong")

/// addMember/merge на недостроенной сети обязаны сперва доесть её обход
/// синхронно: иначе труба, добавленная мимо пакета, будет собрана дважды.
/datum/unit_test/atmos_pipenet_ensure_built/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")
	var/turf/open/origin = run_loc_floor_bottom_left
	var/list/obj/machinery/atmospherics/pipe/simple/pipes = lay_pipe_row(origin, 4)
	var/obj/machinery/atmospherics/pipe/simple/first = pipes[1]
	var/obj/machinery/atmospherics/pipe/simple/second = pipes[2]

	first.build_network()
	var/datum/pipeline/net = first.parent
	TEST_ASSERT(net.building, "deferred build_network did not enter the building state")

	// Игрок кидает трубу рядом, пока сеть ещё строится: addMember обязан
	// доесть обход до какого бы то ни было слияния. Вызов идёт через трубу с
	// посеянным parent - у остальных его до конца обхода ещё нет.
	first.addMember(second)
	TEST_ASSERT(!net.building, "addMember touched a building pipeline without finishing its expansion")
	TEST_ASSERT_EQUAL(length(SSair.expansion_queue), 0, "ensure_built left the expansion packet in the queue")
	TEST_ASSERT_EQUAL(length(net.members), 4, "ensure_built collected [length(net.members)] members instead of 4")
	TEST_ASSERT_EQUAL(net.air.return_volume(), 4 * first.volume, "pipeline volume after ensure_built is wrong")
	for(var/obj/machinery/atmospherics/pipe/simple/segment as anything in pipes)
		var/member_count = 0
		for(var/obj/machinery/atmospherics/pipe/member in net.members)
			if(member == segment)
				member_count++
		TEST_ASSERT_EQUAL(member_count, 1, "a pipe is enrolled [member_count] times in the pipeline")
