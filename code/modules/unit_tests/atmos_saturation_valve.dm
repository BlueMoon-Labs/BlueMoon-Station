// ===== SSair saturation: the valve, the active list, the conduction exit =====
//
// Round 9860 (station-wide plasma flood, ~90 minutes) had SSair resumed on
// almost every tick, eating 40-80% of each one, while the adaptive lag valve
// never opened: time dilation peaked at 8.95% against a 20% threshold. That is
// structural, not bad luck - MC_TICK_CHECK makes a background subsystem yield
// exactly at the tick budget, so the MC keeps its frame rate and the dilation
// counters stay clean no matter how saturated atmos is. These tests pin the
// replacement signal (the subsystem's own full-pass length) and the two list
// invariants that made the pass expensive in the first place.

/// The saturation valve must engage on a sustained overrun, refuse to react to a
/// single long pass, hold inside its hysteresis band, and release symmetrically.
/datum/unit_test/atmos_saturation_valve/Run()
	var/saved_speed = SSair.atmos_speed
	var/saved_lag_scale = SSair.lag_scale
	var/saved_saturation_scale = SSair.saturation_scale
	var/saved_votes = SSair.saturation_votes
	var/saved_ratio = SSair.saturation_ratio
	var/saved_wait = SSair.wait
	var/base_wait = initial(SSair.wait)

	SSair.atmos_speed = 1
	SSair.lag_scale = 1
	SSair.saturation_scale = 1
	SSair.saturation_votes = 0
	SSair.apply_atmos_cadence()
	TEST_ASSERT_EQUAL(SSair.wait, base_wait, "premise: the valve test must start on the compiled cadence")

	// Проход, который перерос свой слот, но ещё короче следующей ступени каденса.
	// Именно в этой вилке замедление вообще имеет смысл: новый интервал длиннее
	// прохода, значит между проходами появится настоящий простой.
	var/overrun_ds = base_wait * 1.2
	// Процессорное время прохода. Клапан на него больше не опирается, но нулевое
	// значение означает "прохода не было" и обязано глушить клапан целиком.
	var/some_cpu_ms = 100

	// --- Без завершённого прохода клапану нечего мерить ---
	TEST_ASSERT(!SSair.apply_saturation_valve(overrun_ds, 0), "клапан принял решение по несуществующему проходу")
	TEST_ASSERT_EQUAL(SSair.wait, base_wait, "решение по несуществующему проходу сдвинуло каденс")

	// --- Отношение считается по РЕАЛЬНОМУ времени и от НОМИНАЛЬНОГО интервала ---
	SSair.apply_saturation_valve(overrun_ds, some_cpu_ms)
	TEST_ASSERT(abs(SSair.saturation_ratio - 1.2) < 0.001, "отношение насыщения должно быть длиной прохода к номинальному интервалу (получено [SSair.saturation_ratio])")

	// --- Одиночный длинный проход не вправе переставить каденс ---
	TEST_ASSERT_EQUAL(SSair.wait, base_wait, "один длинный проход изменил интервал до закрытия окна голосования")

	// --- Устойчивая перегрузка открывает клапан на ступень ---
	// Один голос уже подан замером выше, добираем до ATMOS_SATURATION_VOTES.
	for(var/i in 1 to ATMOS_SATURATION_VOTES - 2)
		TEST_ASSERT(!SSair.apply_saturation_valve(overrun_ds, some_cpu_ms), "клапан двинулся, не добрав голосов")
	TEST_ASSERT(SSair.apply_saturation_valve(overrun_ds, some_cpu_ms), "устойчивая перегрузка не сдвинула каденс")
	TEST_ASSERT_EQUAL(SSair.wait, base_wait / ATMOS_LAG_VALVE_SCALE, "первый шаг клапана попал не на первую ступень лестницы ([SSair.wait])")

	// --- Перегрузка держится: ещё ступень, затем пол лестницы ---
	for(var/i in 1 to ATMOS_SATURATION_VOTES)
		SSair.apply_saturation_valve(overrun_ds, some_cpu_ms)
	TEST_ASSERT_EQUAL(SSair.wait, base_wait / ATMOS_LAG_VALVE_SEVERE_SCALE, "второй шаг клапана попал не на вторую ступень лестницы ([SSair.wait])")
	for(var/i in 1 to ATMOS_SATURATION_VOTES * 3)
		SSair.apply_saturation_valve(overrun_ds, some_cpu_ms)
	TEST_ASSERT_EQUAL(SSair.wait, base_wait / ATMOS_LAG_VALVE_SEVERE_SCALE, "клапан ушёл за нижний край лестницы ([SSair.wait])")
	// Требование владельца: адаптивное замедление не более чем вдвое от текущей
	// скорости. Проверяем именно потолок автоматики, а не общий зажим каденции.
	TEST_ASSERT(SSair.wait <= base_wait * ATMOS_VALVE_SLOWEST_FACTOR, "клапан замедлил газ больше чем вдвое ([SSair.wait] против потолка [base_wait * ATMOS_VALVE_SLOWEST_FACTOR])")

	// --- Пробитая лестница не должна пробивать потолок ---
	var/saved_lag_scale_probe = SSair.lag_scale
	SSair.lag_scale = 0.1
	SSair.apply_atmos_cadence()
	TEST_ASSERT(SSair.wait <= base_wait * ATMOS_VALVE_SLOWEST_FACTOR, "зажим потолка не удержал каденцию при заниженной ступени ([SSair.wait])")
	SSair.lag_scale = saved_lag_scale_probe
	SSair.apply_atmos_cadence()

	// --- Замедляться некуда: клапан обязан отступить, а не удерживать бесполезное ---
	// Проход длиннее самого медленного интервала, который клапану разрешено
	// выставить. В этом режиме правка каденса не создаёт простоя вообще: газ едет
	// медленнее, процессор не освобождается, инцидент растягивается. Клапан обязан
	// это распознать и отдать ступень назад, а не давить дальше.
	var/inert_ds = base_wait * ATMOS_VALVE_SLOWEST_FACTOR * 2
	var/wait_before_inert = SSair.wait
	TEST_ASSERT(SSair.saturation_scale < 1, "предпосылка: проверка бесполезного замедления начинается с открытого клапана")
	for(var/i in 1 to ATMOS_SATURATION_VOTES)
		SSair.apply_saturation_valve(inert_ds, some_cpu_ms)
	TEST_ASSERT(SSair.wait < wait_before_inert, "клапан удержал замедление, которое уже не создаёт простоя ([SSair.wait] против [wait_before_inert])")

	// --- Полоса гистерезиса: каденс стоит, а накопленный голос гаснет по единице ---
	SSair.saturation_scale = 1
	SSair.saturation_votes = 0
	SSair.apply_atmos_cadence()
	var/held_wait = SSair.wait
	var/band_ds = base_wait * (ATMOS_SATURATION_ENGAGE_RATIO + ATMOS_SATURATION_RELEASE_RATIO) * 0.5
	SSair.apply_saturation_valve(overrun_ds, some_cpu_ms)
	SSair.apply_saturation_valve(overrun_ds, some_cpu_ms)
	TEST_ASSERT_EQUAL(SSair.saturation_votes, -2, "два перегруженных прохода подряд не накопили два голоса ([SSair.saturation_votes])")
	SSair.apply_saturation_valve(band_ds, some_cpu_ms)
	TEST_ASSERT_EQUAL(SSair.wait, held_wait, "проход внутри полосы гистерезиса сдвинул каденс ([SSair.wait])")
	TEST_ASSERT_EQUAL(SSair.saturation_votes, -1, "проход внутри полосы обнулил накопленный голос вместо затухания на единицу ([SSair.saturation_votes])")

	// --- Пожар потушен: клапан обязан вернуть каждую ступень ---
	SSair.saturation_scale = ATMOS_LAG_VALVE_SEVERE_SCALE
	SSair.saturation_votes = 0
	SSair.apply_atmos_cadence()
	for(var/i in 1 to ATMOS_SATURATION_VOTES * 3)
		SSair.apply_saturation_valve(0, some_cpu_ms)
	TEST_ASSERT_EQUAL(SSair.saturation_scale, 1, "клапан не отпустил, когда проходы снова стали короткими")
	TEST_ASSERT_EQUAL(SSair.wait, base_wait, "каденс не вернулся к скомпилированному значению ([SSair.wait])")

	// --- The two valves take the more conservative of the pair, they do not compound ---
	SSair.lag_scale = ATMOS_LAG_VALVE_SEVERE_SCALE
	SSair.saturation_scale = ATMOS_LAG_VALVE_SCALE
	SSair.apply_atmos_cadence()
	TEST_ASSERT_EQUAL(SSair.wait, base_wait / ATMOS_LAG_VALVE_SEVERE_SCALE, "the dilation and saturation valves did not combine with min() ([SSair.wait])")

	// --- Рычаг оператора входит в знаменатель ---
	// Номинальный слот задаёт не только скомпилированный wait, но и atmos_speed:
	// при четырёхкратном ускорении он равен base_wait/4, и тот же проход насыщает
	// подсистему вчетверо сильнее. Знаменатель initial(wait) занижал насыщение
	// ровно во столько раз, во сколько был ускорен атмос - в раунде 9872 событие
	// Atmospheric Flux выставило speed = 4, проход стабильно был втрое длиннее
	// своего слота, а клапан не сработал ни разу за 97 замеров.
	SSair.lag_scale = 1
	SSair.saturation_scale = 1
	SSair.saturation_votes = 0
	SSair.atmos_speed = 4
	SSair.apply_atmos_cadence()
	TEST_ASSERT(SSair.wait > world.tick_lag, "предпосылка: ускоренный каденс не должен упираться в зажим по tick_lag ([SSair.wait])")
	SSair.apply_saturation_valve(overrun_ds, some_cpu_ms)
	TEST_ASSERT(abs(SSair.saturation_ratio - 4.8) < 0.001, "знаменатель клапана не учёл ускорение атмоса: слот при speed = 4 вчетверо короче (получено [SSair.saturation_ratio], ожидалось 4.8)")

	SSair.atmos_speed = saved_speed
	SSair.lag_scale = saved_lag_scale
	SSair.saturation_scale = saved_saturation_scale
	SSair.saturation_votes = saved_votes
	SSair.saturation_ratio = saved_ratio
	SSair.wait = saved_wait

/// Тик round_event - это проход SSdirector, а не секунда (см. комментарий к
/// activeFor в _event.dm), поэтому end_when надо читать вместе с каденсом
/// подсистемы. 600 тиков давали двадцать минут учетверённого SSair вместо
/// заявленной в description минуты, и раунд 9872 закончился раньше события.
/datum/unit_test/atmos_flux_event_duration/Run()
	TEST_ASSERT(SSdirector?.wait > 0, "предпосылка: у SSdirector должен быть положительный каденс")
	var/datum/round_event/atmos_flux/flux_type = /datum/round_event/atmos_flux
	var/duration = initial(flux_type.end_when) * SSdirector.wait
	TEST_ASSERT(duration <= 2 MINUTES, "Atmospheric Flux держит SSair ускоренным [duration / (1 MINUTES)] минут вместо заявленной в description одной")

/// `excited` is the membership flag add_to_active() trusts so it can skip the
/// linear rescan of active_turfs (which runs into five figures under a fire).
/// The flag and the list therefore have to agree in both directions: an
/// already-listed turf must not be listed twice, and nothing may mark a turf
/// awake without listing it.
/datum/unit_test/atmos_active_turf_membership/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")
	var/turf/open/origin = run_loc_floor_bottom_left
	var/turf/open/subject = locate(origin.x + 1, origin.y + 1, origin.z)
	TEST_ASSERT(istype(subject), "test location is not an open turf")

	SSair.remove_from_active(subject)
	TEST_ASSERT(!subject.excited, "premise: the subject must start out of the active list")
	var/baseline = length(SSair.active_turfs)

	SSair.add_to_active(subject, FALSE)
	TEST_ASSERT(subject.excited, "add_to_active did not mark the turf excited")
	TEST_ASSERT_EQUAL(length(SSair.active_turfs), baseline + 1, "add_to_active did not list the turf")

	// The fast path skips the rescan for an already-excited turf; it must skip
	// the append with it, or every poke at a burning tile appends a duplicate.
	SSair.add_to_active(subject, FALSE)
	SSair.add_to_active(subject, FALSE)
	TEST_ASSERT_EQUAL(length(SSair.active_turfs), baseline + 1, "repeated add_to_active duplicated the turf in the active list")

	SSair.sleep_active_turf(subject)
	TEST_ASSERT(!subject.excited, "sleep_active_turf left the membership flag set")
	TEST_ASSERT_EQUAL(length(SSair.active_turfs), baseline, "sleep_active_turf did not drop the turf from the list")

	// add_turf marks its member awake, so it owes the list an entry: without one
	// the flag would lie and add_to_active could never list this turf again.
	var/datum/excited_group/group = new
	group.add_turf(subject)
	TEST_ASSERT(subject.excited, "add_turf did not mark its member awake")
	TEST_ASSERT(subject in SSair.active_turfs, "a turf marked awake by add_turf never reached the active list")
	TEST_ASSERT_EQUAL(length(SSair.active_turfs), baseline + 1, "add_turf listed the turf more than once")
	SSair.add_to_active(subject, FALSE)
	TEST_ASSERT_EQUAL(length(SSair.active_turfs), baseline + 1, "add_to_active after add_turf duplicated the entry")

	group.dismantle()
	TEST_ASSERT(!subject.excited, "dismantle left the membership flag set")
	TEST_ASSERT_EQUAL(length(SSair.active_turfs), baseline, "dismantle left the member listed")

	subject.atmos_cooldown = 0
	SSair.remove_from_active(subject)

/// A tile that shares its last gas away while hot keeps that temperature in an
/// empty mixture, and an empty mixture has no heat capacity - it can never cool.
/// Reading the conduction exit off it pinned the tile in
/// SSair.active_super_conductivity for the rest of the round, and every pass
/// over it also re-registered its neighbours.
/datum/unit_test/atmos_superconduction_empty_air_exit/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")
	var/turf/open/origin = run_loc_floor_bottom_left
	var/turf/open/subject = locate(origin.x + 2, origin.y + 2, origin.z)
	TEST_ASSERT(istype(subject), "test location is not an open turf")

	var/saved_heat_enabled = SSair.heat_enabled
	var/saved_turf_temperature = subject.temperature
	var/datum/gas_mixture/saved_air = subject.air.copy()
	var/was_listed = (subject in SSair.active_super_conductivity)

	SSair.heat_enabled = TRUE
	subject.air.clear()
	subject.air.set_moles(GAS_N2, 300)
	subject.air.set_temperature(1200)
	subject.air.archive()
	subject.temperature = T20C
	TEST_ASSERT(subject.consider_superconductivity(starting = TRUE), "premise: a hot dense tile must register for conduction")
	TEST_ASSERT(subject in SSair.active_super_conductivity, "premise: the registered tile is missing from the conduction list")

	// Still hot, still holding gas: it stays.
	subject.finish_superconduction()
	TEST_ASSERT(subject in SSair.active_super_conductivity, "a tile still holding hot gas left the conduction list")

	// Gas gone, stale hot temperature left in the mixture, tile itself cool.
	subject.air.clear()
	subject.air.archive()
	subject.air.set_temperature(1200)
	subject.temperature = T20C
	subject.finish_superconduction()
	TEST_ASSERT(!(subject in SSair.active_super_conductivity), "an emptied tile stayed pinned in the conduction list ([subject.air.return_temperature()] K of nothing)")

	SSair.active_super_conductivity -= subject
	if(was_listed)
		SSair.active_super_conductivity[subject] = TRUE
	subject.air.copy_from(saved_air)
	subject.air.archive()
	subject.temperature = saved_turf_temperature
	SSair.heat_enabled = saved_heat_enabled
	SSair.remove_from_active(subject)

/// hotspot_expose() walks the whole gas list twice (oxidation power, then fuel)
/// before it decides anything. Every fire reaction ends by calling it on its own
/// tile, where an active hotspot and no sustain flag make it a guaranteed no-op,
/// so the early out has to come first - without changing what the sustain path
/// does when it IS asked to keep the fire alive.
/datum/unit_test/atmos_hotspot_expose_sustain_gate/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")
	var/turf/open/origin = run_loc_floor_bottom_left
	var/turf/open/subject = locate(origin.x + 3, origin.y + 1, origin.z)
	TEST_ASSERT(istype(subject), "test location is not an open turf")

	var/datum/gas_mixture/saved_air = subject.air.copy()
	subject.air.clear()
	subject.air.set_moles(GAS_PLASMA, 50)
	subject.air.set_moles(GAS_O2, 50)
	subject.air.set_temperature(FIRE_MINIMUM_TEMPERATURE_TO_EXIST + 400)
	subject.air.archive()

	var/obj/effect/hotspot/burning = new(subject, CELL_VOLUME * 0.1, FIRE_MINIMUM_TEMPERATURE_TO_EXIST + 400)
	TEST_ASSERT_EQUAL(subject.active_hotspot, burning, "premise: the tile must own the hotspot we just built")
	// The fixture has to be able to sustain a fire, or both branches below would
	// bail out on the fuel check and the test would prove nothing.
	TEST_ASSERT(turf_has_fire_fuel(subject.air, burning.temperature, subject.z), "premise: the fixture tile must hold burnable fuel")
	TEST_ASSERT(subject.air.get_oxidation_power(burning.temperature) >= 0.5, "premise: the fixture tile must hold an oxidiser")

	var/temperature_before = burning.temperature
	var/volume_before = burning.volume

	// No sustain flag: the reaction feedback path, and a guaranteed no-op.
	subject.hotspot_expose(temperature_before + 500, volume_before + 500)
	TEST_ASSERT_EQUAL(burning.temperature, temperature_before, "an unsustained expose raised the hotspot temperature")
	TEST_ASSERT_EQUAL(burning.volume, volume_before, "an unsustained expose raised the hotspot volume")

	// With the sustain flag the hotspot must still take the hotter, bigger fire.
	subject.hotspot_expose(temperature_before + 500, volume_before + 500, 1)
	TEST_ASSERT_EQUAL(burning.temperature, temperature_before + 500, "a sustaining expose did not raise the hotspot temperature")
	TEST_ASSERT_EQUAL(burning.volume, volume_before + 500, "a sustaining expose did not raise the hotspot volume")

	// A sustaining expose colder and smaller than the fire must not shrink it.
	subject.hotspot_expose(temperature_before, volume_before, 1)
	TEST_ASSERT_EQUAL(burning.temperature, temperature_before + 500, "a weaker sustaining expose cooled the hotspot")
	TEST_ASSERT_EQUAL(burning.volume, volume_before + 500, "a weaker sustaining expose shrank the hotspot")

	// Cleared before the qdel: /obj/effect/hotspot/DestroyTurf() reads the flag
	// and would Melt() the reservation floor out from under the next test.
	subject.to_be_destroyed = FALSE
	subject.max_fire_temperature_sustained = 0
	qdel(burning)
	TEST_ASSERT_NULL(subject.active_hotspot, "the hotspot survived its own qdel on the tile")
	subject.air.copy_from(saved_air)
	subject.air.archive()
	unit_test_normalize_exposure_window(subject)
	SSair.remove_from_active(subject)

/// Снятие турфа из active_turfs идёт за O(1): на его место переезжает последний
/// элемент. Проверяем ровно то, чем такая схема опасна - что после снятия из
/// СЕРЕДИНЫ списка все прочие турфы остались ровно по одному разу и их
/// позиции-подсказки продолжают указывать на них самих. Разошедшаяся подсказка
/// либо потеряла бы турф из симуляции молча, либо оставила бы в списке дубль.
/datum/unit_test/atmos_active_turf_swap_remove/proc/assert_indexed(turf/open/subject, hint)
	TEST_ASSERT(subject.active_turf_index, "[hint]: у турфа не выставлена позиция в списке")
	TEST_ASSERT(subject.active_turf_index <= length(SSair.active_turfs), "[hint]: позиция турфа за пределами списка")
	TEST_ASSERT_EQUAL(SSair.active_turfs[subject.active_turf_index], subject, "[hint]: позиция турфа указывает не на него")

/datum/unit_test/atmos_active_turf_swap_remove/Run()
	TEST_ASSERT(SSair?.initialized, "SSair не инициализирован")
	var/turf/open/origin = run_loc_floor_bottom_left
	var/list/turf/open/subjects = list()
	// Верхний ряд резервации: соседний тест (planetary_churn) обносит стенами
	// клетку (+1,+1) вместе с её кардиналами, а это ряд origin.y.
	for(var/offset in 1 to 3)
		var/turf/open/spot = locate(origin.x + offset, origin.y + 4, origin.z)
		TEST_ASSERT(istype(spot), "тестовая клетка [offset] не открытый турф")
		SSair.remove_from_active(spot)
		TEST_ASSERT(!spot.excited, "предпосылка: клетка [offset] должна начинать вне списка")
		subjects += spot

	var/baseline = length(SSair.active_turfs)
	for(var/turf/open/spot as anything in subjects)
		SSair.add_to_active(spot, FALSE)
	TEST_ASSERT_EQUAL(length(SSair.active_turfs), baseline + 3, "не все три клетки попали в список")
	for(var/turf/open/spot as anything in subjects)
		assert_indexed(spot, "после постановки")

	// Снимаем среднюю: последний элемент списка обязан переехать на её место и
	// узнать свою новую позицию.
	var/turf/open/first_turf = subjects[1]
	var/turf/open/middle_turf = subjects[2]
	var/turf/open/last_turf = subjects[3]
	SSair.sleep_active_turf(middle_turf)
	TEST_ASSERT_EQUAL(length(SSair.active_turfs), baseline + 2, "снятие из середины не укоротило список ровно на одну запись")
	TEST_ASSERT(!(middle_turf in SSair.active_turfs), "снятая из середины клетка осталась в списке")
	TEST_ASSERT_EQUAL(middle_turf.active_turf_index, 0, "снятая клетка сохранила позицию")
	assert_indexed(first_turf, "после снятия середины")
	assert_indexed(last_turf, "переехавшая клетка")

	// Переехавшая клетка снимается по новой позиции, а не по старой.
	SSair.sleep_active_turf(last_turf)
	TEST_ASSERT_EQUAL(length(SSair.active_turfs), baseline + 1, "переехавшая клетка снялась не за один раз")
	TEST_ASSERT(!(last_turf in SSair.active_turfs), "переехавшая клетка осталась в списке")
	assert_indexed(first_turf, "после снятия переехавшей")

	// Разошедшаяся подсказка: снятие обязано откатиться на честный поиск, а не
	// оставить запись в списке. Это защита от подмены турфа мимо Destroy.
	first_turf.active_turf_index = 0
	SSair.sleep_active_turf(first_turf)
	TEST_ASSERT_EQUAL(length(SSair.active_turfs), baseline, "снятие с обнулённой подсказкой оставило запись в списке")
	TEST_ASSERT(!(first_turf in SSair.active_turfs), "клетка с обнулённой подсказкой осталась в списке")

	for(var/turf/open/spot as anything in subjects)
		SSair.remove_from_active(spot)

/// Снятие по РАЗОШЕДШЕЙСЯ подсказке не имеет права портить подсказки соседей.
/// `active_turfs -= T` снимал запись сдвигом всего хвоста влево, то есть разом
/// делал протухшими подсказки КАЖДОГО турфа после снятого. Дальше каждое их
/// снятие проваливалось в тот же линейный откат и сдвигало хвост снова -
/// вырождение O(1) в O(n) с каскадом, который сам себя поддерживает. На проде
/// это стоило роста тяжёлых прогонов SSair (дольше 100 мс) с нуля за час до
/// пятисот за час на одной и той же карте, плюс десятикратного замедления
/// загрузки шаттловых темплейтов - весь резервационный трафик идёт через
/// evict_active_turf.
/datum/unit_test/atmos_active_turf_stale_hint_no_cascade/Run()
	TEST_ASSERT(SSair?.initialized, "SSair не инициализирован")
	var/turf/open/origin = run_loc_floor_bottom_left
	var/list/turf/open/subjects = list()
	for(var/offset in 1 to 4)
		var/turf/open/spot = locate(origin.x + offset, origin.y + 3, origin.z)
		TEST_ASSERT(istype(spot), "тестовая клетка [offset] не открытый турф")
		SSair.remove_from_active(spot)
		TEST_ASSERT(!spot.excited, "предпосылка: клетка [offset] должна начинать вне списка")
		subjects += spot

	var/baseline = length(SSair.active_turfs)
	for(var/turf/open/spot as anything in subjects)
		SSair.add_to_active(spot, FALSE)
	TEST_ASSERT_EQUAL(length(SSair.active_turfs), baseline + 4, "не все четыре клетки попали в список")

	// Ломаем подсказку у второй клетки и снимаем её. Турф остаётся excited, так
	// что ранний выход "не активен - значит и не в списке" не сработает и снятие
	// обязано пойти именно линейным откатом - ровно тем путём, который каскадил.
	var/turf/open/victim = subjects[2]
	victim.active_turf_index = 0
	SSair.sleep_active_turf(victim)
	TEST_ASSERT_EQUAL(length(SSair.active_turfs), baseline + 3, "снятие по разошедшейся подсказке укоротило список не на одну запись")
	TEST_ASSERT(!(victim in SSair.active_turfs), "снятая клетка осталась в списке")

	// Вот она, суть: у всех уцелевших подсказка обязана по-прежнему указывать на
	// них самих. При сдвиге хвоста здесь разъезжались бы третья и четвёртая.
	for(var/turf/open/spot as anything in subjects)
		if(spot == victim)
			continue
		TEST_ASSERT(spot.active_turf_index, "у уцелевшей клетки сбилась позиция после снятия соседа")
		TEST_ASSERT(spot.active_turf_index <= length(SSair.active_turfs), "позиция уцелевшей клетки вышла за пределы списка")
		TEST_ASSERT_EQUAL(SSair.active_turfs[spot.active_turf_index], spot, "позиция уцелевшей клетки указывает не на неё")

	// И снятие каждой из них обязано остаться одношаговым.
	for(var/turf/open/spot as anything in subjects)
		if(spot == victim)
			continue
		var/before = length(SSair.active_turfs)
		SSair.sleep_active_turf(spot)
		TEST_ASSERT_EQUAL(length(SSair.active_turfs), before - 1, "снятие уцелевшей клетки укоротило список не на одну запись")
		TEST_ASSERT(!(spot in SSair.active_turfs), "уцелевшая клетка осталась в списке после снятия")

	TEST_ASSERT_EQUAL(length(SSair.active_turfs), baseline, "список не вернулся к исходной длине")
	for(var/turf/open/spot as anything in subjects)
		SSair.remove_from_active(spot)

/// Загрузка карты не имеет права наполнять очередь активных турфов. Планетарный
/// турф на инициализации совпадает со своим шаблоном по построению, поэтому
/// будить его - чистая холостая работа: прод мерил 93533 записи в очереди, из
/// которых после первого же прохода оставалось около полутора тысяч. Разгребался
/// этот завал ровно в момент старта раунда, давая единственный спайк
/// тайм-дилатации 110-120%.
/datum/unit_test/atmos_map_load_does_not_enqueue/Run()
	TEST_ASSERT(SSair?.initialized, "SSair не инициализирован")
	var/turf/open/origin = run_loc_floor_bottom_left
	// Дальний угол резервации: ряд y+3 занят проверкой каскада, ряд y+4 слева -
	// проверкой снятия обменом, а клетку (+1,+1) с её кардиналами обносит стенами
	// planetary_churn.
	var/turf/open/subject = locate(origin.x + 4, origin.y + 4, origin.z)
	TEST_ASSERT(istype(subject), "тестовая клетка не открытый турф")

	var/saved_planetary = subject.planetary_atmos
	var/saved_map_loading = SSair.map_loading
	SSair.remove_from_active(subject)
	TEST_ASSERT(!subject.excited, "предпосылка: клетка должна начинать вне списка")

	subject.planetary_atmos = TRUE
	var/baseline = length(SSair.active_turfs)

	SSair.map_loading = TRUE
	subject.update_air_ref(AIR_REF_PLANETARY_TURF)
	TEST_ASSERT_EQUAL(length(SSair.active_turfs), baseline, "загрузка карты положила планетарный турф в очередь активных")
	TEST_ASSERT(!subject.excited, "загрузка карты разбудила планетарный турф")
	// Шаблон при этом обязан построиться: его читают напрямую (лёгкие эшуокеров).
	TEST_ASSERT_NOTNULL(SSair.planetary[subject.initial_gas_mix], "шаблон планетарной смеси не построился на загрузке карты")

	// Карта загружена - тот же вызов обязан будить как раньше. Это путь турфа,
	// ставшего планетарным уже в игре, и именно он в симуляции и важен.
	SSair.map_loading = FALSE
	subject.update_air_ref(AIR_REF_PLANETARY_TURF)
	TEST_ASSERT_EQUAL(length(SSair.active_turfs), baseline + 1, "вне загрузки карты планетарный турф не попал в очередь")
	TEST_ASSERT(subject.excited, "вне загрузки карты планетарный турф не проснулся")

	SSair.map_loading = saved_map_loading
	subject.planetary_atmos = saved_planetary
	SSair.remove_from_active(subject)
