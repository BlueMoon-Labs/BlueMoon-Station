// ===== Vacuum edge: перегретый почти-вакуум у пробоины не имеет права зависнуть =====
//
// Историческая ловушка (урок Baystation vacuum_exception): перегретый тайл на
// долях моля держит "выживаемое" давление, при экспоненциальном сливе вентился
// подпороговыми крохами и десятки циклов не мог ни стечь, ни уснуть - оба
// мольных гейта сброса кулдаунов его не видели. С полным сбросом (tg-паритет
// share_end) окно исчезает по построению: кромка отдаёт космосу всё за один
// фаер. Тест держит фикстуру той ловушки и утверждает новую семантику:
//   1. один процесс-цикл опустошает тайл целиком и приводит его к TCMB;
//   2. тайл не спит, пока давил на космос, - и свободен уснуть после;
//   3. группа не разваливается посреди сброса (dismantle_cooldown обнулён).

/datum/unit_test/atmos_vacuum_exception
	priority = TEST_LONGER

/datum/unit_test/atmos_vacuum_exception/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")

	var/turf/base = run_loc_floor_bottom_left

	// Wall off a pocket; subject at +1,+1 with a single space tile at +1,+2.
	for(var/dx in 0 to 2)
		for(var/dy in 0 to 3)
			var/turf/T = locate(base.x + dx, base.y + dy, base.z)
			TEST_ASSERT_NOTNULL(T, "test zone turf missing at offset [dx],[dy]")
			if(dx == 0 || dx == 2 || dy == 0 || dy == 3)
				T.ChangeTurf(/turf/closed/wall)

	var/turf/open/subject = locate(base.x + 1, base.y + 1, base.z)
	var/turf/space_side = locate(base.x + 1, base.y + 2, base.z)
	space_side.ChangeTurf(/turf/open/space)
	var/turf/open/space/vacuum = locate(base.x + 1, base.y + 2, base.z)
	TEST_ASSERT(istype(vacuum), "space tile fixture did not become /turf/open/space")

	subject.ImmediateCalculateAdjacentTurfs()
	vacuum.ImmediateCalculateAdjacentTurfs()
	TEST_ASSERT(vacuum in subject.atmos_adjacent_turfs, "subject must be adjacent to the space tile")

	// Перегретый почти-вакуум: 0.19 моль при 45000K читается как ~28 кПа. При
	// экспоненциальном сливе фикстура попадала ровно в слепое окно мольных
	// гейтов; полный сброс обязан снять её одним циклом.
	var/datum/gas_mixture/saved_air = subject.air.copy()
	subject.air.clear()
	subject.air.set_moles(GAS_O2, 0.19)
	subject.air.set_temperature(45000)
	var/pressure_start = subject.air.return_pressure()
	TEST_ASSERT(pressure_start > HAZARD_LOW_PRESSURE, "fixture must read survivable pressure on wisp content (got [pressure_start])")

	subject.atmos_cooldown = 0
	SSair.add_to_active(subject, FALSE)
	TEST_ASSERT(subject.excited, "subject must start excited")

	// Группа с почти истёкшим dismantle-отсчётом: сброс должен обнулить его,
	// а не позволить dismantle() снять тайл с актива посреди стравливания.
	var/datum/excited_group/drain_group = new
	drain_group.add_turf(subject) // resets cooldowns
	drain_group.dismantle_cooldown = EXCITED_GROUP_DISMANTLE_CYCLES - 1

	var/fire_base = SSair.times_fired + 2000
	subject.process_cell(fire_base + 1)
	TEST_ASSERT(subject.air.total_moles() < 0.001, "superheated wisp survived a full-dump cycle: [subject.air.total_moles()] mol")
	TEST_ASSERT(abs(subject.air.return_temperature() - TCMB) < 0.01, "vented tile did not match space temperature (got [subject.air.return_temperature()]K)")
	TEST_ASSERT_EQUAL(drain_group.dismantle_cooldown, 0, "full dump must zero the group's dismantle countdown")
	TEST_ASSERT_EQUAL(subject.atmos_cooldown, 0, "full dump must reset the tile's stall cooldown")
	TEST_ASSERT(subject.excited, "tile must stay excited through the dump cycle - neighbors may still be feeding it")

	// Второй цикл: терять нечего, кулдауны свободны накапливаться - пустой тайл
	// у дыры не обязан крутиться вечно.
	subject.process_cell(fire_base + 2)
	TEST_ASSERT(subject.air.total_moles() < 0.001, "emptied tile regained gas from nowhere")

	// Cleanup: restore air and deactivate; the reservation releases the turfs.
	subject.air.copy_from(saved_air)
	SSair.high_pressure_delta -= subject
	subject.high_pressure_queued = FALSE
	subject.pressure_vector_x = 0
	subject.pressure_vector_y = 0
	if(subject.excited_group)
		subject.excited_group.dismantle()
	SSair.remove_from_active(subject)
