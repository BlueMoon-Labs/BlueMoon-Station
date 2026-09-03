// Проверки вокруг холостой активации турфов, лестницы отката сердцебиения и
// грязного списка пайпнетов - трёх мест, где раунд 9868 показал постоянную
// нагрузку, которую подсистема создавала себе сама.

#define TEST_CHURN_EPSILON 0.001

/// Активация, которая не двигала газ, не выдаёт турфу свежий запас простоя.
///
/// atmos_cooldown - единственный выход осевшего члена возбуждённой группы,
/// которую держит живой один-единственный бурлящий сосед: групповой
/// reset_cooldowns() тот сосед взводит каждый фаер, поэтому ни брейкдауна, ни
/// размонтирования группа не дожидается никогда. Раунд 9868: тычки эквалайзера и
/// пересчёта смежности обнуляли счётчик двум с половиной тысячам станционных
/// турфов, и те не засыпали часами при разбросе ровно 72.0-72.0 кПа.
/datum/unit_test/atmos_poke_keeps_stall_counter/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")
	var/turf/open/subject = run_loc_floor_bottom_left
	TEST_ASSERT(istype(subject), "test location is not an open turf")

	subject.atmos_cooldown = EXCITED_GROUP_INDIVIDUAL_REST_CYCLES + 3
	SSair.add_to_active(subject, FALSE, reset_stall = FALSE)
	TEST_ASSERT_EQUAL(subject.atmos_cooldown, EXCITED_GROUP_INDIVIDUAL_REST_CYCLES + 3, "a poke handed the turf a fresh stall budget")
	TEST_ASSERT(subject.excited, "a poke must still put the turf back in the active list")

	// Активация, которая ПРИНЕСЛА газ, обязана давать полный запас: без этого
	// труп, капающий миазмой, не вытолкнул бы её из своего кармана.
	SSair.add_to_active(subject, FALSE)
	TEST_ASSERT_EQUAL(subject.atmos_cooldown, 0, "a real air change did not refresh the stall budget")

	subject.atmos_cooldown = 0
	SSair.remove_from_active(subject)

/// Зональный эквалайзер будит только тех членов зоны, чей газ он реально сдвинул.
///
/// Он сам делает всю зону ОДИНАКОВОЙ, то есть гарантирует, что шерить её членам
/// между собой больше нечего, - и при этом будил всю зону целиком, до двух тысяч
/// турфов за вызов. Получалась вечная нагрузка, которую он же и создавал.
/datum/unit_test/atmos_equalize_wakes_only_changed/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")
	var/turf/open/origin = run_loc_floor_bottom_left
	var/turf/open/left = locate(origin.x + 1, origin.y + 1, origin.z)
	var/turf/open/middle = locate(origin.x + 2, origin.y + 1, origin.z)
	var/turf/open/right = locate(origin.x + 3, origin.y + 1, origin.z)
	TEST_ASSERT(istype(left), "left test location is not an open turf")
	TEST_ASSERT(istype(middle), "middle test location is not an open turf")
	TEST_ASSERT(istype(right), "right test location is not an open turf")

	var/cycle = SSair.times_fired + 1
	// Зона ограничивается тем же счётчиком, которым эквалайзер защищается от
	// повторного обхода: заранее проштампованный турф выпадает из обхода и не
	// раскрывает своих соседей. Так зона получается ровно из трёх наших клеток,
	// а не из всей резервации.
	var/list/turf/open/stamped = list()
	var/turf/corner_low = locate(max(1, origin.x - 1), max(1, origin.y - 1), origin.z)
	var/turf/corner_high = locate(min(world.maxx, origin.x + 5), min(world.maxy, origin.y + 5), origin.z)
	for(var/turf/open/T in block(corner_low, corner_high))
		if(T == left || T == middle || T == right)
			continue
		stamped += T
		T.equalize_cycle = cycle

	// Равные объёмы и равная температура: после сведения у каждого окажется
	// среднее, то есть ровно то, что уже держит середина.
	for(var/turf/open/T as anything in list(left, middle, right))
		T.air.clear()
		T.air.set_temperature(T20C)
		SSair.remove_from_active(T)
	left.air.set_moles(GAS_O2, 80)
	middle.air.set_moles(GAS_O2, 100)
	right.air.set_moles(GAS_O2, 120)

	var/middle_moles_before = middle.air.total_moles()
	TEST_ASSERT(middle.equalize_pressure_in_zone(cycle), "the zone walk did not run")

	TEST_ASSERT(abs(middle.air.total_moles() - middle_moles_before) < TEST_CHURN_EPSILON, "the middle turf was expected to already sit on the zone average")
	TEST_ASSERT(!middle.excited, "the equalizer woke a zone member whose air it left where it was")
	TEST_ASSERT(left.excited, "the equalizer failed to wake a zone member it drained")
	TEST_ASSERT(right.excited, "the equalizer failed to wake a zone member it filled")

	for(var/turf/open/T as anything in stamped)
		T.equalize_cycle = 0
	for(var/turf/open/T as anything in list(left, middle, right))
		T.equalize_cycle = 0
		T.atmos_cooldown = 0
		T.air.copy_from_turf(T)
		if(T.excited_group)
			T.excited_group.garbage_collect()
		SSair.remove_from_active(T)

/// Машина, которую сердцебиение раз за разом будит впустую, уходит на ступень
/// отката: период удваивается, и ротация очереди перестаёт быть постоянной
/// долей фазы машинерии. База в 15 секунд при каденсе SSair в 5 децисекунд
/// возвращала к обработке одну тридцатую ВСЕЙ машинерии карты каждый проход.
/datum/unit_test/atmos_idle_heartbeat_backoff/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")
	var/turf/open/room = run_loc_floor_bottom_left
	TEST_ASSERT(istype(room), "test location is not an open turf")
	var/obj/machinery/atmospherics/components/unary/vent_scrubber/scrubber = allocate(/obj/machinery/atmospherics/components/unary/vent_scrubber, room)

	for(var/i in 1 to ATMOS_MACHINE_IDLE_STREAK)
		scrubber.atmos_consider_idle()
	TEST_ASSERT(SSair.idle_machine_queued(scrubber), "scrubber did not enter the idle queue")
	TEST_ASSERT_EQUAL(scrubber.atmos_idle_tier, 1, "the first sleep did not land on the base heartbeat tier")
	// Дедлайн - это сумма с world.time, а world.time на живом раунде уже
	// пятизначный: разность в 32-битном float возвращается с точностью до
	// последнего разряда мантиссы, а не бит в бит. Сравниваем с допуском -
	// ступени лестницы разнесены на сотни децисекунд, спутать их невозможно.
	var/base_wait = scrubber.atmos_idle_until - world.time
	TEST_ASSERT(abs(base_wait - ATMOS_MACHINE_IDLE_HEARTBEAT) < 1, "the base tier did not wait one heartbeat: [base_wait] instead of [ATMOS_MACHINE_IDLE_HEARTBEAT]")

	// Каждое следующее холостое сердцебиение - ступень выше. wake_expired не
	// трогает atmos_idle_streak именно ради этого счёта.
	for(var/step in 1 to ATMOS_MACHINE_IDLE_BACKOFF_STEPS)
		TEST_ASSERT(SSair.expire_idle_machine_for_test(scrubber), "could not expire the queued scrubber on step [step]")
		SSair.wake_expired_idle_machines()
		TEST_ASSERT(scrubber.atmos_processing, "expired heartbeat did not return the machine to processing on step [step]")
		scrubber.atmos_consider_idle()
		TEST_ASSERT(SSair.idle_machine_queued(scrubber), "the machine did not go back to sleep on step [step]")
		TEST_ASSERT_EQUAL(scrubber.atmos_idle_tier, step + 1, "backoff step [step] did not advance the tier")
		var/expected_wait = ATMOS_MACHINE_IDLE_HEARTBEAT * (2 ** step)
		var/actual_wait = scrubber.atmos_idle_until - world.time
		TEST_ASSERT(abs(actual_wait - expected_wait) < 1, "backoff step [step] did not double the heartbeat: [actual_wait] instead of [expected_wait]")

	// Потолок: дальше ступеней нет, период держится.
	TEST_ASSERT(SSair.expire_idle_machine_for_test(scrubber), "could not expire the queued scrubber at the ceiling")
	SSair.wake_expired_idle_machines()
	scrubber.atmos_consider_idle()
	TEST_ASSERT_EQUAL(scrubber.atmos_idle_tier, ATMOS_MACHINE_IDLE_BACKOFF_STEPS + 1, "the backoff ladder ran past its last step")

	// Событие возвращает машину на нулевую ступень: откат наказывает только тех,
	// кого будили зря, и обязан отпускать при первом же реальном поводе. Запись
	// в очереди при этом обязана сняться, иначе следующее засыпание вышло бы по
	// флагу и оставило машину на старой ступени.
	scrubber.atmos_wake()
	TEST_ASSERT_EQUAL(scrubber.atmos_idle_streak, 0, "an event wake did not clear the idle streak")
	TEST_ASSERT(!SSair.idle_machine_queued(scrubber), "an event wake left the machine in the heartbeat queue")
	for(var/i in 1 to ATMOS_MACHINE_IDLE_STREAK)
		scrubber.atmos_consider_idle()
	TEST_ASSERT_EQUAL(scrubber.atmos_idle_tier, 1, "an event wake did not reset the backoff ladder")

/// Рассылка пробуждений пайпнета обязана срабатывать и в криоконтуре, где всё
/// рабочее давление лежит ниже абсолютных 5 кПа: порог там берётся долей от
/// давления сети. Раунд 9875 - помпы контура морозилки на 2.7К "отмирали" до
/// двух минут (heartbeat с откатом), потому что сеть молчала о любых скачках.
/datum/unit_test/atmos_pipenet_cryo_wake/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")
	var/turf/open/room = run_loc_floor_bottom_left
	TEST_ASSERT(istype(room), "test location is not an open turf")
	var/obj/machinery/atmospherics/components/unary/vent_scrubber/scrubber = allocate(/obj/machinery/atmospherics/components/unary/vent_scrubber, room)

	var/datum/pipeline/net = new()
	net.air = new(200)
	net.air.set_temperature(T20C)
	net.other_atmosmch += scrubber

	// Свежесобранная сеть на криодавлении (~2 кПа - выше порога 5 кПа она не
	// поднимется НИКОГДА) обязана разбудить участников первым же сведением.
	var/moles_per_kpa = 200 / (R_IDEAL_GAS_EQUATION * T20C)
	net.air.set_moles(GAS_O2, 2 * moles_per_kpa)
	for(var/i in 1 to ATMOS_MACHINE_IDLE_STREAK)
		scrubber.atmos_consider_idle()
	TEST_ASSERT(SSair.idle_machine_queued(scrubber), "scrubber did not enter the idle queue")
	net.process()
	TEST_ASSERT(scrubber.atmos_processing, "a fresh sub-5 kPa pipenet did not wake its sleeping member")
	TEST_ASSERT(!SSair.idle_machine_queued(scrubber), "the woken scrubber was left in the heartbeat queue")

	// Дрожь ниже относительного порога будить не должна.
	for(var/i in 1 to ATMOS_MACHINE_IDLE_STREAK)
		scrubber.atmos_consider_idle()
	net.air.set_moles(GAS_O2, 2.05 * moles_per_kpa)
	net.mark_dirty()
	net.process()
	TEST_ASSERT(SSair.idle_machine_queued(scrubber), "sub-threshold cryo jitter woke the sleeping member")

	// А реальный для криоконтура скачок в полкилопаскаля - обязан.
	net.air.set_moles(GAS_O2, 2.55 * moles_per_kpa)
	net.mark_dirty()
	net.process()
	TEST_ASSERT(scrubber.atmos_processing, "a meaningful cryo-scale pressure jump did not wake the sleeping member")

	// На высоком давлении абсолютный порог остаётся прежним: 3 кПа при 4000 кПа
	// это шум, просыпаться от него нельзя.
	net.air.set_moles(GAS_O2, 4000 * moles_per_kpa)
	net.mark_dirty()
	net.process()
	for(var/i in 1 to ATMOS_MACHINE_IDLE_STREAK)
		scrubber.atmos_consider_idle()
	net.air.set_moles(GAS_O2, 4003 * moles_per_kpa)
	net.mark_dirty()
	net.process()
	TEST_ASSERT(SSair.idle_machine_queued(scrubber), "a 3 kPa ripple on a 4000 kPa pipenet woke the sleeping member")

	scrubber.atmos_wake()
	net.other_atmosmch.Cut()
	qdel(net)

/// Фаза пайпнетов ходит по списку грязных сетей, а не по всем подряд. Инвариант:
/// сеть с поднятым `update` обязана лежать в очереди - иначе газ в ней замрёт
/// навсегда. Флаг и список ходят парой только через mark_dirty().
/datum/unit_test/atmos_pipenet_dirty_list/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")

	// Сироты считаются по ВСЕМ сетям станции, поэтому проверяем дельту к базовой
	// линии, а не абсолют: чужой дефект не должен читаться как наш.
	var/orphans_baseline = SSair.count_orphan_dirty_pipenets()

	var/datum/pipeline/net = new()
	TEST_ASSERT(net.update, "a fresh pipenet must start dirty")
	TEST_ASSERT(net in SSair.dirty_networks, "a fresh pipenet did not enter the dirty list")
	TEST_ASSERT_EQUAL(SSair.count_orphan_dirty_pipenets(), orphans_baseline, "a queued dirty pipenet was counted as an orphan")

	// Ручная уборка вместо прогона фазы: process_pipenets перетирает общий слот
	// SSair.currentrun, а подсистема на живой станции может стоять в нём посреди
	// другого этапа.
	net.update = FALSE
	SSair.dirty_networks -= net
	TEST_ASSERT_EQUAL(SSair.count_orphan_dirty_pipenets(), orphans_baseline, "a clean pipenet was counted as an orphan")

	net.mark_dirty()
	TEST_ASSERT(net.update, "mark_dirty did not raise the update flag")
	TEST_ASSERT(net in SSair.dirty_networks, "mark_dirty did not queue the pipenet")
	TEST_ASSERT_EQUAL(SSair.count_orphan_dirty_pipenets(), orphans_baseline, "a re-dirtied pipenet was counted as an orphan")

	// Повторный вызов не должен класть сеть в список дважды: фаза съедает список
	// целиком, и дубль стоил бы лишнего reconcile_air на всю сеть.
	var/queued_before = length(SSair.dirty_networks)
	net.mark_dirty()
	TEST_ASSERT_EQUAL(length(SSair.dirty_networks), queued_before, "mark_dirty queued the same pipenet twice")

	// Рассинхрон, который инвариант и ловит: флаг есть, записи нет. Такая сеть
	// не обсчитается никогда, то есть газ в трубе встанет намертво.
	SSair.dirty_networks -= net
	TEST_ASSERT_EQUAL(SSair.count_orphan_dirty_pipenets(), orphans_baseline + 1, "a flagged pipenet outside the queue was not reported as an orphan")

	net.mark_dirty()
	qdel(net)
	TEST_ASSERT(!(net in SSair.dirty_networks), "Destroy() left the pipenet in the dirty list")
	TEST_ASSERT(!(net in SSair.networks), "Destroy() left the pipenet in the network registry")
	TEST_ASSERT_EQUAL(SSair.count_orphan_dirty_pipenets(), orphans_baseline, "a deleted pipenet was still counted as an orphan")

#undef TEST_CHURN_EPSILON
