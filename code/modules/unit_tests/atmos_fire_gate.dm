/// react() skips assembling the fire reactions as candidates when the mixture
/// holds no gas that has reached its own ignition temperature. That is only safe
/// while the gate is a strict over-approximation of what get_fuel_amount() would
/// find: it may say "maybe" where the real answer is zero, but it must never say
/// "no" where the reaction would have had fuel to work with.
///
/// This matters because the gate sits one degree away from ordinary room air.
/// genericfire has no gas requirement, so its TEMP requirement sets the floor for
/// every temperature-gated reaction, and that requirement resolves to the lowest
/// fire_temperature in the game - phlogiston's T20C+1 = 294.15 K, against station
/// air at 293.15 K. Everything warmer than 21 C used to fall through into the
/// full candidate assembly plus two whole-gas-list scans, to conclude nothing.
/datum/unit_test/atmos_fire_gate

/// Returns TRUE when this sample actually exercised the property under test, i.e.
/// get_fuel_amount() found something for the gate to be wrong about. The caller
/// counts those: a sweep where the branch is never taken proves nothing, and
/// without the count it would still report green.
/datum/unit_test/atmos_fire_gate/proc/assert_gate_covers(datum/gas_mixture/mix, temperature, description)
	mix.set_temperature(temperature)
	var/fuel = mix.get_fuel_amount(temperature)
	var/gate = mix.has_ignitable_fuel(temperature)
	if(fuel <= 0)
		return FALSE
	TEST_ASSERT(gate, "[description]: get_fuel_amount() found [fuel] but the gate said there is no fuel - the fire reaction would have been skipped wrongly")
	return TRUE

/datum/unit_test/atmos_fire_gate/Run()
	var/list/fire_temperatures = GLOB.gas_data.fire_temperatures
	TEST_ASSERT(length(fire_temperatures), "gas_data.fire_temperatures must be populated before this test runs")

	// The floor itself: whatever the lowest ignition temperature in the game is,
	// genericfire's TEMP requirement must not sit below it, or the gate would be
	// reached at temperatures where no gas can burn anyway.
	var/lowest_fire_temp = INFINITY
	for(var/gas_id in fire_temperatures)
		lowest_fire_temp = min(lowest_fire_temp, fire_temperatures[gas_id])
	var/datum/gas_reaction/generic_fire = unit_test_find_gas_reaction("genericfire")
	TEST_ASSERT_NOTNULL(generic_fire, "genericfire must be registered - the whole fuel gate hangs off its TEMP requirement")
	var/generic_fire_temp = generic_fire.min_requirements["TEMP"]
	TEST_ASSERT(generic_fire_temp >= lowest_fire_temp, "genericfire's TEMP requirement ([generic_fire_temp]) sits below the lowest ignition temperature in the game ([lowest_fire_temp]): the gate would be reached where nothing can burn at all")
	TEST_ASSERT(!isnull(generic_fire.min_requirements["FIRE_REAGENTS"]), "genericfire lost its FIRE_REAGENTS requirement - temp_gated_needs_fuel would stop listing it and the gate would go dead")

	// Plain station air, warmer than the gate. This is the case the optimisation
	// exists for, and the one that must come out with no fuel.
	var/datum/gas_mixture/station_air = new(CELL_VOLUME)
	station_air.set_moles(GAS_O2, MOLES_O2STANDARD)
	station_air.set_moles(GAS_N2, MOLES_N2STANDARD)
	station_air.set_moles(GAS_CO2, 0.4)
	station_air.set_temperature(T20C + 5)
	TEST_ASSERT(!station_air.has_ignitable_fuel(T20C + 5), "warm O2/N2/CO2 holds no fuel gas, so the gate must close")
	TEST_ASSERT_EQUAL(station_air.get_fuel_amount(T20C + 5), 0, "warm O2/N2/CO2 must genuinely have no fuel - if this fails the gate is not the problem, the premise is")
	TEST_ASSERT_EQUAL(station_air.react(), NO_REACTION, "warm station air must not react")

	// A real fire mixture must still be let through, and must still burn.
	var/datum/gas_mixture/fire_mix = new(CELL_VOLUME)
	fire_mix.set_moles(GAS_PLASMA, 30)
	fire_mix.set_moles(GAS_O2, 60)
	fire_mix.set_temperature(FIRE_MINIMUM_TEMPERATURE_TO_EXIST + 200)
	TEST_ASSERT(fire_mix.has_ignitable_fuel(fire_mix.return_temperature()), "a hot plasma/oxygen mixture must pass the fuel gate")
	TEST_ASSERT(fire_mix.react() & REACTING, "a hot plasma/oxygen mixture must still ignite through react()")

	// Fuel present but cold: the gate is allowed to close here, and so is the
	// reaction. Checked so a future change cannot make the gate temperature-blind
	// without this saying something.
	var/datum/gas_mixture/cold_fuel = new(CELL_VOLUME)
	cold_fuel.set_moles(GAS_PLASMA, 30)
	cold_fuel.set_moles(GAS_O2, 60)
	cold_fuel.set_temperature(TCMB + 10)
	TEST_ASSERT(!cold_fuel.has_ignitable_fuel(TCMB + 10), "plasma below its ignition temperature must not open the gate")

	// The safety property, swept across the temperature range the gate operates
	// in and across every gas that declares an ignition point. An oxidiser goes in
	// alongside so the mixture is a plausible fire; get_fuel_amount() itself never
	// looks at oxidisers, and a gas cannot be both - auxgm puts a gas into
	// fire_temperatures only when it has no oxidation_temperature - so no gas in
	// this loop is its own oxidiser.
	//
	// Below and at the ignition point get_fuel_amount() returns exactly zero
	// (its temperature_scale is 1 - t_f/temp, which is 0 at temp == t_f), so half
	// the offsets below are deliberately non-events. fuel_cases counts the samples
	// that did land on the property; without it a get_fuel_amount() that returned
	// zero unconditionally would empty this sweep and still report green.
	var/fuel_cases = 0
	for(var/gas_id in fire_temperatures)
		var/datum/gas_mixture/probe = new(CELL_VOLUME)
		probe.set_moles(gas_id, 20)
		probe.set_moles(GAS_O2, 40)
		var/ignition = fire_temperatures[gas_id]
		for(var/offset in list(-50, -1, 0, 1, 50, 500))
			if(assert_gate_covers(probe, max(TCMB, ignition + offset), "[gas_id] at ignition[offset >= 0 ? "+" : ""][offset]"))
				fuel_cases++
		qdel(probe)
	TEST_ASSERT(fuel_cases > 0, "the sweep never reached a mixture with fuel in it - it asserted nothing at all")

	qdel(station_air)
	qdel(fire_mix)
	qdel(cold_fuel)

// ===== Клеймо прохода у свежего очага =====
//
// perform_exposure() пропускается ровно один раз - за тот проход, в котором её
// уже отработал Initialize(). Булев флаг этого не выражал: очаг, рождённый
// распространением ВНУТРИ фазы хотспотов, в снимок currentrun не попадал, а флаг
// всё равно сгорал на первом же вызове process(), то есть глушил экспозицию и в
// следующем проходе тоже. Фронт огня терял на этом полсекунды за шаг.
//
// Оба случая - рождение фазой турфов и рождение распространением - неотличимы по
// клейму: очаг помнит проход, а не то, кто его создал. Различает их только то,
// какому проходу принадлежит текущий process(), и обе половины этого контракта
// проверяются ниже.
//
// Наблюдаем не за газом, а за содержимым турфа: perform_exposure() зовёт
// fire_act() по нему на ЛЮБОЙ ветке, а реакция идёт только у не-bypassing очага,
// и завязка на моли сделала бы тест заложником того, каким объёмом очаг родился.

/obj/effect/atmos_fire_probe
	name = "atmos fire probe"
	resistance_flags = FIRE_PROOF | INDESTRUCTIBLE
	/// Сколько раз по пробнику прошлась экспозиция очага.
	var/fire_acts = 0

/obj/effect/atmos_fire_probe/fire_act(exposed_temperature, exposed_volume)
	fire_acts++
	return ..()

/datum/unit_test/hotspot_spawn_skip_is_one_pass_only
	priority = TEST_LONGER

/datum/unit_test/hotspot_spawn_skip_is_one_pass_only/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")
	var/turf/open/subject = run_loc_floor_bottom_left
	TEST_ASSERT(istype(subject), "test needs an open turf under it")
	TEST_ASSERT_NOTNULL(subject.air, "test turf must carry a gas mixture")

	var/datum/gas_mixture/saved_air = subject.air.copy()
	subject.air.clear()
	subject.air.set_moles(GAS_PLASMA, 50)
	subject.air.set_moles(GAS_O2, 50)
	subject.air.set_temperature(PLASMA_MINIMUM_BURN_TEMPERATURE + 500)

	var/obj/effect/atmos_fire_probe/probe = new(subject)

	// Ровно то, что делает фаза турфов: реакция смеси зажигает плитку через
	// hotspot_expose и заполняет reaction_results, из которых очаг берёт объём.
	subject.air.react(subject)
	var/obj/effect/hotspot/fire = subject.active_hotspot
	TEST_ASSERT_NOTNULL(fire, "премиса: горящая смесь плазмы с кислородом обязана зажечь плитку")
	TEST_ASSERT_EQUAL(fire.spawned_pass, SSair.times_fired, "свежий очаг обязан помнить проход своего рождения")
	var/acts_at_spawn = probe.fire_acts
	TEST_ASSERT(acts_at_spawn > 0, "премиса: рождение очага обязано экспонировать содержимое турфа")

	// Тот же проход: экспозицию уже отработал Initialize(), второй раз нельзя.
	// Так выглядит очаг, рождённый фазой турфов, - он попал в снимок currentrun.
	TEST_ASSERT(fire.process(), "премиса: очаг не должен умереть на богатой смеси")
	TEST_ASSERT_EQUAL(probe.fire_acts, acts_at_spawn, "экспозиция в проходе рождения обязана быть пропущена")

	// Следующим проходом экспозиция обязана состояться.
	SSair.times_fired++
	TEST_ASSERT(fire.process(), "премиса: очаг не должен умереть на богатой смеси")
	TEST_ASSERT_EQUAL(probe.fire_acts, acts_at_spawn + 1, "в следующем проходе очаг обязан экспонировать турф")

	// А теперь то, ради чего тест и написан: очаг, рождённый распространением уже
	// ВНУТРИ фазы хотспотов. Снимок списка снят до его рождения, поэтому первый
	// process() наступает у него только СЛЕДУЮЩИМ проходом - и глушить там нечего,
	// свою экспозицию он отработал проходом раньше. Булев флаг этого не различал:
	// он доживал до чужого прохода и съедал его экспозицию.
	subject.to_be_destroyed = FALSE
	subject.max_fire_temperature_sustained = 0
	qdel(fire)
	SSair.times_fired++
	subject.air.set_moles(GAS_PLASMA, 50)
	subject.air.set_moles(GAS_O2, 50)
	subject.air.set_temperature(PLASMA_MINIMUM_BURN_TEMPERATURE + 500)
	subject.air.react(subject)
	var/obj/effect/hotspot/spread_fire = subject.active_hotspot
	TEST_ASSERT_NOTNULL(spread_fire, "премиса: плитку обязано зажечь повторно")
	var/acts_at_spread_spawn = probe.fire_acts
	// Проход рождения кончился, а process() в нём так и не пришёл.
	SSair.times_fired++
	TEST_ASSERT(spread_fire.process(), "премиса: очаг не должен умереть на богатой смеси")
	TEST_ASSERT_EQUAL(probe.fire_acts, acts_at_spread_spawn + 1, "очаг, не попавший в снимок своего прохода, обязан экспонировать турф на первом же своём process()")
	fire = spread_fire

	// Cleanup. Снимаем приговор турфу до qdel очага: hotspot/Destroy зовёт
	// DestroyTurf(), а тот по накопленной температуре может расплавить пол.
	subject.to_be_destroyed = FALSE
	subject.max_fire_temperature_sustained = 0
	qdel(fire)
	qdel(probe)
	subject.air.copy_from(saved_air)
	qdel(saved_air)
	SSair.remove_from_active(subject)
