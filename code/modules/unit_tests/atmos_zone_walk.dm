// Возобновляемый обход зоны эквалайзером: /datum/atmos_zone_walk.
//
// Прежде это был один атомарный прок на две тысячи турфов - раунд 9869 намерил
// им 259 мс фазы и 1225% тика одним куском. Теперь обход режется на срезы, и
// проверять надо ровно то, что разрез не изменил: результат сведения, момент
// первой записи в газ, гард "одна зона на турф за фаер" и устойчивость к тому,
// что член зоны исчез между сбором и сведением.

/// Моли считаются суммой по списку газов, а world.time и объёмы турфов уже
/// пятизначные: сравнивать с допуском, а не бит в бит.
#define TEST_ZONE_WALK_EPSILON 0.01
/// Потолок числа срезов в тестах: страховка от зацикливания машины состояний.
#define TEST_ZONE_WALK_MAX_SLICES 64

/// Готовит зону ровно из трёх турфов: всё остальное в округе штампуется тем же
/// счётчиком, которым обход защищается от повторного захода, поэтому такие
/// турфы выпадают из обхода и не раскрывают своих соседей.
/proc/stamp_zone_walk_surroundings(turf/open/origin, list/turf/open/keep, cycle)
	var/list/turf/open/stamped = list()
	var/turf/corner_low = locate(max(1, origin.x - 1), max(1, origin.y - 1), origin.z)
	var/turf/corner_high = locate(min(world.maxx, origin.x + 5), min(world.maxy, origin.y + 5), origin.z)
	for(var/turf/open/candidate in block(corner_low, corner_high))
		if(candidate in keep)
			continue
		stamped += candidate
		candidate.equalize_cycle = cycle
	return stamped

/// Обход, порезанный на срезы по одному турфу, приходит туда же, куда пришёл бы
/// атомарный: три равных объёма с 60/100/140 молями обязаны стать по 100.
/// Заодно проверяем, что резать действительно есть что - один вызов зону не
/// закрывает.
/datum/unit_test/atmos_zone_walk_sliced_matches_atomic/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")
	var/turf/open/origin = run_loc_floor_bottom_left
	var/turf/open/left = locate(origin.x + 1, origin.y + 1, origin.z)
	var/turf/open/middle = locate(origin.x + 2, origin.y + 1, origin.z)
	var/turf/open/right = locate(origin.x + 3, origin.y + 1, origin.z)
	TEST_ASSERT(istype(left) && istype(middle) && istype(right), "the three test locations are not all open turfs")

	var/cycle = SSair.times_fired + 1
	var/list/turf/open/zone = list(left, middle, right)
	var/list/turf/open/stamped = stamp_zone_walk_surroundings(origin, zone, cycle)

	for(var/turf/open/member as anything in zone)
		member.air.clear()
		member.air.set_temperature(T20C)
		SSair.remove_from_active(member)
	left.air.set_moles(GAS_O2, 60)
	middle.air.set_moles(GAS_O2, 100)
	right.air.set_moles(GAS_O2, 140)

	var/datum/atmos_zone_walk/walk = new
	var/started = walk.begin(middle, cycle)
	var/slices = 0
	var/finished = FALSE
	if(started)
		while(slices < TEST_ZONE_WALK_MAX_SLICES)
			slices++
			if(walk.advance(1))
				finished = TRUE
				break
	var/left_moles = left.air.total_moles()
	var/middle_moles = middle.air.total_moles()
	var/right_moles = right.air.total_moles()
	restore_zone_walk_turfs(zone, stamped)

	TEST_ASSERT(started, "the walk refused a valid seed turf")
	TEST_ASSERT(finished, "the sliced walk did not finish within [TEST_ZONE_WALK_MAX_SLICES] slices")
	TEST_ASSERT(slices > 1, "a three-turf zone closed in one slice: the walk never actually yielded")
	TEST_ASSERT(abs(left_moles - 100) < TEST_ZONE_WALK_EPSILON, "the drained member did not land on the zone average: [left_moles]")
	TEST_ASSERT(abs(middle_moles - 100) < TEST_ZONE_WALK_EPSILON, "the middle member did not stay on the zone average: [middle_moles]")
	TEST_ASSERT(abs(right_moles - 100) < TEST_ZONE_WALK_EPSILON, "the filled member did not land on the zone average: [right_moles]")

/// Сбор зоны обязан оставаться read-only: единственное, что он пишет, - штамп
/// equalize_cycle на захваченном турфе. Если бы газ двигался уже на сборе,
/// разрезать обход между фаерами было бы нельзя вовсе - зона стояла бы
/// полусведённой на глазах у игроков.
/datum/unit_test/atmos_zone_walk_holds_gas_until_mix/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")
	var/turf/open/origin = run_loc_floor_bottom_left
	var/turf/open/left = locate(origin.x + 1, origin.y + 1, origin.z)
	var/turf/open/middle = locate(origin.x + 2, origin.y + 1, origin.z)
	var/turf/open/right = locate(origin.x + 3, origin.y + 1, origin.z)
	TEST_ASSERT(istype(left) && istype(middle) && istype(right), "the three test locations are not all open turfs")

	var/cycle = SSair.times_fired + 1
	var/list/turf/open/zone = list(left, middle, right)
	var/list/turf/open/stamped = stamp_zone_walk_surroundings(origin, zone, cycle)

	for(var/turf/open/member as anything in zone)
		member.air.clear()
		member.air.set_temperature(T20C)
		SSair.remove_from_active(member)
	left.air.set_moles(GAS_O2, 60)
	middle.air.set_moles(GAS_O2, 100)
	right.air.set_moles(GAS_O2, 140)

	var/datum/atmos_zone_walk/walk = new
	var/started = walk.begin(middle, cycle)
	// Ровно один срез сбора: захвачена только затравка, соседи лежат в стеке.
	if(started)
		walk.advance(1)
	var/left_after_collect = left.air.total_moles()
	var/right_after_collect = right.air.total_moles()
	var/left_excited = left.excited
	// Довести обход до конца, чтобы не оставить за собой полузону.
	if(started)
		walk.advance(0)
	restore_zone_walk_turfs(zone, stamped)

	TEST_ASSERT(started, "the walk refused a valid seed turf")
	TEST_ASSERT(abs(left_after_collect - 60) < TEST_ZONE_WALK_EPSILON, "the collect stage moved gas: [left_after_collect]")
	TEST_ASSERT(abs(right_after_collect - 140) < TEST_ZONE_WALK_EPSILON, "the collect stage moved gas: [right_after_collect]")
	TEST_ASSERT(!left_excited, "the collect stage woke a zone member before any gas moved")

/// Гард "одна зона на турф за фаер" держится на equalize_cycle. Обход,
/// растянувшийся на несколько фаеров, оставил бы своих членов со штампом фаера
/// ЗАХВАТА, и в фаере завершения любой из них снова прошёл бы гейт фазы - то
/// есть та же зона стравила бы свою кромку в космос второй раз за проход.
/datum/unit_test/atmos_zone_walk_restamps_after_fire_boundary/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")
	var/turf/open/origin = run_loc_floor_bottom_left
	var/turf/open/left = locate(origin.x + 1, origin.y + 1, origin.z)
	var/turf/open/middle = locate(origin.x + 2, origin.y + 1, origin.z)
	var/turf/open/right = locate(origin.x + 3, origin.y + 1, origin.z)
	TEST_ASSERT(istype(left) && istype(middle) && istype(right), "the three test locations are not all open turfs")
	// Обход заводится ПРОШЛЫМ фаером: так его завершение приходится на фаер
	// строго больший, ровно как у обхода, пережившего границу фаера вживую.
	var/cycle = SSair.times_fired - 1
	TEST_ASSERT(cycle > 0, "SSair has not fired enough times to model a cross-fire walk")

	var/list/turf/open/zone = list(left, middle, right)
	var/list/turf/open/stamped = stamp_zone_walk_surroundings(origin, zone, cycle)

	for(var/turf/open/member as anything in zone)
		member.air.clear()
		member.air.set_temperature(T20C)
		member.equalize_cycle = 0
		SSair.remove_from_active(member)
	left.air.set_moles(GAS_O2, 60)
	middle.air.set_moles(GAS_O2, 100)
	right.air.set_moles(GAS_O2, 140)

	var/datum/atmos_zone_walk/walk = new
	var/started = walk.begin(middle, cycle)
	if(started)
		walk.advance(0)
	var/list/stamps = list()
	for(var/turf/open/member as anything in zone)
		stamps += member.equalize_cycle
	restore_zone_walk_turfs(zone, stamped)

	TEST_ASSERT(started, "the walk refused a valid seed turf")
	for(var/index in 1 to length(stamps))
		TEST_ASSERT(stamps[index] > cycle, "zone member [index] kept the claim-fire stamp [stamps[index]] and could seed the same zone again")

/// Сбор растянут во времени, поэтому член зоны может исчезнуть между захватом и
/// сведением: ChangeTurf в стену, снос пола, потеря смеси. Такой член обязан
/// выпасть из усреднения целиком - и из суммы, и из записи, - иначе зона либо
/// потеряет его моли, либо раздаст их дважды.
/datum/unit_test/atmos_zone_walk_skips_lost_member/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")
	var/turf/open/origin = run_loc_floor_bottom_left
	var/turf/open/left = locate(origin.x + 1, origin.y + 1, origin.z)
	var/turf/open/middle = locate(origin.x + 2, origin.y + 1, origin.z)
	var/turf/open/right = locate(origin.x + 3, origin.y + 1, origin.z)
	TEST_ASSERT(istype(left) && istype(middle) && istype(right), "the three test locations are not all open turfs")

	var/cycle = SSair.times_fired + 1
	var/list/turf/open/zone = list(left, middle, right)
	var/list/turf/open/stamped = stamp_zone_walk_surroundings(origin, zone, cycle)

	for(var/turf/open/member as anything in zone)
		member.air.clear()
		member.air.set_temperature(T20C)
		SSair.remove_from_active(member)
	left.air.set_moles(GAS_O2, 60)
	middle.air.set_moles(GAS_O2, 100)
	right.air.set_moles(GAS_O2, 140)

	var/datum/atmos_zone_walk/walk = new
	var/started = walk.begin(middle, cycle)
	// Бюджет ровно в три турфа закрывает сбор всей зоны и останавливает машину
	// перед сведением: газ ещё не тронут, состав зоны уже зафиксирован.
	if(started)
		walk.advance(3)
	var/datum/gas_mixture/orphaned = right.air
	right.air = null
	if(started)
		walk.advance(0)
	// Смесь возвращается ДО любой проверки: упавший ассерт не должен оставить
	// турф без воздуха для остальных тестов.
	right.air = orphaned
	var/left_moles = left.air.total_moles()
	var/middle_moles = middle.air.total_moles()
	var/right_moles = right.air.total_moles()
	restore_zone_walk_turfs(zone, stamped)

	TEST_ASSERT(started, "the walk refused a valid seed turf")
	TEST_ASSERT(abs(right_moles - 140) < TEST_ZONE_WALK_EPSILON, "the lost member was written to anyway: [right_moles]")
	TEST_ASSERT(abs(left_moles - 80) < TEST_ZONE_WALK_EPSILON, "the surviving members did not average between themselves: [left_moles]")
	TEST_ASSERT(abs(middle_moles - 80) < TEST_ZONE_WALK_EPSILON, "the surviving members did not average between themselves: [middle_moles]")
	TEST_ASSERT(abs((left_moles + middle_moles) - 160) < TEST_ZONE_WALK_EPSILON, "the zone lost or created moles around the missing member")

/// Постановка турфа в active_turfs решает вопрос членства по подсказке позиции,
/// а не сканом всего списка: эквалайзер будит спящих членов зоны сотнями за
/// обход, а список активных турфов под разгерметизацией уходит в пять знаков.
/// Инвариант, на котором это держится, и проверяем: сколько бы раз турф ни
/// уснул и ни проснулся, запись в списке ровно одна.
/datum/unit_test/atmos_active_list_single_entry/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")
	var/turf/open/subject = run_loc_floor_bottom_left
	TEST_ASSERT(istype(subject), "test location is not an open turf")

	SSair.remove_from_active(subject)
	SSair.add_to_active(subject, FALSE)
	SSair.sleep_active_turf(subject)
	SSair.add_to_active(subject, FALSE)
	SSair.remove_from_active(subject)
	SSair.add_to_active(subject, FALSE)
	// Прямой повторный вызов - это ровно та ветка, которую защищает подсказка:
	// add_to_active отсекает её флагом excited, а здесь она вызвана в лоб.
	SSair.list_active_turf(subject)

	var/entries = 0
	for(var/turf/open/listed as anything in SSair.active_turfs)
		if(listed == subject)
			entries++
	var/hint = subject.active_turf_index
	var/hint_valid = hint && hint <= length(SSair.active_turfs) && SSair.active_turfs[hint] == subject

	SSair.remove_from_active(subject)
	subject.atmos_cooldown = 0

	TEST_ASSERT_EQUAL(entries, 1, "wake/sleep churn left a duplicate entry in the active turf list")
	TEST_ASSERT(hint_valid, "the position hint did not point at the turf's own slot")
	TEST_ASSERT(!(subject in SSair.active_turfs), "the turf stayed listed after removal")

/// Возврат резервации в исходное состояние: газ по шаблону турфа, штампы
/// сброшены, группы распущены, ничего не осталось активным.
/proc/restore_zone_walk_turfs(list/turf/open/zone, list/turf/open/stamped)
	for(var/turf/open/member as anything in stamped)
		member.equalize_cycle = 0
	for(var/turf/open/member as anything in zone)
		member.equalize_cycle = 0
		member.atmos_cooldown = 0
		if(member.air)
			member.air.copy_from_turf(member)
		if(member.excited_group)
			member.excited_group.garbage_collect()
		SSair.remove_from_active(member)

#undef TEST_ZONE_WALK_EPSILON
#undef TEST_ZONE_WALK_MAX_SLICES
