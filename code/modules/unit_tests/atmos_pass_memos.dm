/// Замуровывает клетку, чтобы process_cell не делил её газ с соседями и ревизия смеси менялась только от реакций.
/proc/unit_test_seal_turf(turf/open/subject)
	for(var/direction in GLOB.cardinals)
		var/turf/neighbor = get_step(subject, direction)
		if(neighbor && !isclosedturf(neighbor))
			neighbor.ChangeTurf(/turf/closed/wall)
	subject.ImmediateCalculateAdjacentTurfs()

/// Смесь, которая горит при живом индексе реакций.
/proc/unit_test_fill_burning_mix(datum/gas_mixture/mix)
	mix.clear()
	mix.set_moles(GAS_PLASMA, 20)
	mix.set_moles(GAS_O2, 60)
	mix.set_temperature(1000)

/// Пустой вызов react() запоминается по ревизии смеси. Мемо обязано слететь, когда меняется сам индекс реакций, иначе смесь без кандидатов не заметит добавленную реакцию.
/datum/unit_test/atmos_react_idle_memo_follows_reaction_index

/datum/unit_test/atmos_react_idle_memo_follows_reaction_index/Run()
	var/datum/gas_mixture/mix = new(CELL_VOLUME)
	unit_test_fill_burning_mix(mix)
	var/list/saved_reactions = SSair.gas_reactions.Copy()
	SSair.gas_reactions.Cut()
	SSair.auxtools_update_reactions()
	var/without_index = mix.react()
	var/repeated = mix.react()
	SSair.gas_reactions = saved_reactions
	SSair.auxtools_update_reactions()
	var/plasma_before = mix.get_moles(GAS_PLASMA)
	var/with_index = mix.react()
	var/plasma_after = mix.get_moles(GAS_PLASMA)
	qdel(mix)

	TEST_ASSERT_EQUAL(without_index, NO_REACTION, "без реакций в индексе смесь не должна реагировать")
	TEST_ASSERT_EQUAL(repeated, NO_REACTION, "повторный пустой вызов обязан дать тот же пустой результат")
	TEST_ASSERT(with_index & REACTING, "после перестройки индекса та же смесь обязана загореться, мемо пустого вызова пережило смену индекса")
	TEST_ASSERT(plasma_after < plasma_before, "плазма должна гореть: [plasma_before] -> [plasma_after]")

/// Тот же контракт на пути фазы турфов: process_cell берёт мемо react() у смеси турфа.
/datum/unit_test/atmos_process_cell_react_memo_follows_index

/datum/unit_test/atmos_process_cell_react_memo_follows_index/Run()
	var/turf/open/subject = run_loc_floor_bottom_left
	unit_test_seal_turf(subject)
	unit_test_fill_burning_mix(subject.air)
	var/list/saved_reactions = SSair.gas_reactions.Copy()
	SSair.gas_reactions.Cut()
	SSair.auxtools_update_reactions()
	var/fire = SSair.times_fired + 1000
	subject.process_cell(fire)
	var/plasma_idle = subject.air.get_moles(GAS_PLASMA)
	subject.process_cell(fire + 1)
	var/plasma_still = subject.air.get_moles(GAS_PLASMA)
	SSair.gas_reactions = saved_reactions
	SSair.auxtools_update_reactions()
	subject.process_cell(fire + 2)
	var/plasma_burning = subject.air.get_moles(GAS_PLASMA)
	QDEL_NULL(subject.active_hotspot)
	subject.air.copy_from_turf(subject)
	SSair.remove_from_active(subject)

	TEST_ASSERT_EQUAL(plasma_still, plasma_idle, "без реакций плазма не должна убывать")
	TEST_ASSERT(plasma_burning < plasma_idle, "после перестройки индекса горение на турфе обязано пойти: [plasma_idle] -> [plasma_burning]")

/// Предпроверка оверлея в process_cell пропускает update_visuals() только для смеси без видимых газов, а появившийся и исчезнувший газ видно сразу.
/datum/unit_test/atmos_process_cell_overlay_precheck

/datum/unit_test/atmos_process_cell_overlay_precheck/Run()
	var/turf/open/subject = run_loc_floor_bottom_left
	unit_test_seal_turf(subject)
	var/datum/gas_mixture/air = subject.air
	var/fire = SSair.times_fired + 1000
	air.clear()
	air.set_moles(GAS_N2, MOLES_N2STANDARD)
	air.set_moles(GAS_CO2, 1)
	air.set_temperature(T20C)
	subject.process_cell(fire)
	var/list/overlays_invisible = subject.atmos_overlay_types?.Copy()
	var/plasma_visible = GLOB.gas_data.visibility[GAS_PLASMA]
	air.set_moles(GAS_PLASMA, plasma_visible * 20)
	subject.process_cell(fire + 1)
	var/overlays_visible = length(subject.atmos_overlay_types)
	air.set_moles(GAS_PLASMA, plasma_visible * 0.5)
	subject.process_cell(fire + 2)
	var/list/overlays_faded = subject.atmos_overlay_types?.Copy()
	subject.air.copy_from_turf(subject)
	subject.update_visuals()
	SSair.remove_from_active(subject)

	TEST_ASSERT(plasma_visible > 0, "у плазмы должен быть порог видимости")
	TEST_ASSERT(!length(overlays_invisible), "азот с углекислотой не дают оверлея")
	TEST_ASSERT_EQUAL(overlays_visible, 1, "плазма выше порога обязана получить оверлей")
	TEST_ASSERT(!length(overlays_faded), "плазма ниже порога обязана снять оверлей")

/// Выравнивание пайпнета раздаёт смесям копии общего списка: смеси одного объёма не должны делить один список газов.
/datum/unit_test/atmos_pipenet_equalize_independent_lists

/datum/unit_test/atmos_pipenet_equalize_independent_lists/Run()
	var/datum/gas_mixture/first = new(200)
	var/datum/gas_mixture/pipe = new(70)
	var/datum/gas_mixture/second = new(200)
	first.set_moles(GAS_O2, 30)
	first.set_temperature(300)
	pipe.set_moles(GAS_N2, 14)
	pipe.set_temperature(250)
	second.set_moles(GAS_O2, 10)
	second.set_moles(GAS_CO2, 5)
	second.set_temperature(T20C)
	var/list/mixes = list(first, second, pipe)
	equalize_all_gases_in_list(mixes)

	TEST_ASSERT(first.gases != second.gases, "смеси одного объёма получили один и тот же список газов")
	TEST_ASSERT(abs(first.get_moles(GAS_O2) - 40 * 200 / 470) < 0.0001, "кислород в первой смеси [first.get_moles(GAS_O2)]")
	TEST_ASSERT(abs(pipe.get_moles(GAS_N2) - 14 * 70 / 470) < 0.0001, "азот в трубе [pipe.get_moles(GAS_N2)]")
	TEST_ASSERT_EQUAL(first.get_moles(GAS_CO2), second.get_moles(GAS_CO2), "смеси одного объёма обязаны получить равную долю")
	TEST_ASSERT_EQUAL(first.return_temperature(), pipe.return_temperature(), "температура выравнивается по всей сети")
	first.adjust_moles(GAS_O2, 5)
	TEST_ASSERT(abs(second.get_moles(GAS_O2) - 40 * 200 / 470) < 0.0001, "правка одной смеси протекла в соседнюю")
	qdel(first)
	qdel(pipe)
	qdel(second)
