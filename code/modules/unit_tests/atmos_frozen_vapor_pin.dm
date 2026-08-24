/// Замёрзший водяной пар не должен держать турф в активной симуляции вечно.
///
/// Морозная ветка `/datum/gas_reaction/water_vapor/react()` (температура ниже
/// WATER_VAPOR_FREEZE) возвращала REACTING, но пар при этом НЕ расходовала - в
/// отличие от тёплой ветки строкой ниже, которая снимает MOLES_GAS_VISIBLE за
/// проход. Порог `GAS_H2O = MOLES_GAS_VISIBLE` из init_reqs() поэтому выполнялся
/// бесконечно, а конец process_cell() при REACTING не снимает турф с актива и не
/// даёт ему уснуть в одиночку:
///
///     if(!active_hotspot && !(reaction_result & (REACTING | STOP_REACTIONS)))
///
/// Итог: любой турф на мороженом покрытии (FROZEN_ATMOS 180K и TCOMMS_ATMOS 80K -
/// обе ниже порога 200K), куда попал пар от огнетушителя, лопнувшей трубы или
/// погоды, оставался активным до конца раунда и платил полную стоимость турф-фазы
/// каждый цикл. Активных турфов в проде медиана 177-1113, а p99 - 5300-8500;
/// такой прибитый турф входит в хвост навсегда.
///
/// Реакция дёргается напрямую, а не через `gas_mixture.react()`: проверяем ветку,
/// а не индексатор кандидатов, у которого своя отдельная пачка тестов.
#define FROZEN_VAPOR_MAX_PASSES 120

/datum/unit_test/frozen_vapor_releases_turf

/datum/unit_test/frozen_vapor_releases_turf/Run()
	var/turf/open/tile = run_loc_floor_bottom_left
	TEST_ASSERT(istype(tile), "тестовый турф не открытый")
	TEST_ASSERT_NOTNULL(tile.air, "у тестового турфа нет смеси")

	var/datum/gas_reaction/water_vapor/reaction
	for(var/datum/gas_reaction/candidate as anything in SSair.gas_reactions)
		if(istype(candidate, /datum/gas_reaction/water_vapor))
			reaction = candidate
			break
	TEST_ASSERT_NOTNULL(reaction, "реакция водяного пара не зарегистрирована в SSair")

	// Морозный карман с видимым паром: ровно та ситуация, что прибивала турф.
	var/datum/gas_mixture/tile_air = tile.air
	tile_air.clear()
	tile_air.set_moles(GAS_H2O, MOLES_GAS_VISIBLE * 4)
	tile_air.set_temperature(WATER_VAPOR_FREEZE - 20)

	TEST_ASSERT(tile_air.return_temperature() <= WATER_VAPOR_FREEZE, \
		"смесь не остыла ниже порога заморозки: [tile_air.return_temperature()] K")
	var/vapor_before = tile_air.get_moles(GAS_H2O)
	TEST_ASSERT(vapor_before > MOLES_GAS_VISIBLE, "стартового пара не хватает, чтобы порог реакции вообще выполнялся")

	// Проход обязан ЗАСЧИТАТЬСЯ как реакция - иначе тест не про то.
	var/first_result = reaction.react(tile_air, tile)
	TEST_ASSERT(first_result & REACTING, "морозная ветка пара не сработала - сценарий не воспроизведён")
	TEST_ASSERT(tile_air.get_moles(GAS_H2O) < vapor_before, \
		"морозная ветка вернула REACTING, но пар не израсходовала - турф останется активным навсегда")

	// Пар обязан сойти НИЖЕ порога `GAS_H2O = MOLES_GAS_VISIBLE` за конечное число
	// проходов: именно этот порог диспетчер react() проверяет перед тем, как
	// выбрать реакцию кандидатом. Пока он выполняется, реакция возвращает REACTING,
	// а турф не может уснуть. Реакция дёргается напрямую, поэтому порог проверяем
	// здесь сами - прямой вызов гейт кандидатов не проходит.
	var/passes = 0
	while(passes < FROZEN_VAPOR_MAX_PASSES && tile_air.get_moles(GAS_H2O) >= MOLES_GAS_VISIBLE)
		passes++
		reaction.react(tile_air, tile)
	TEST_ASSERT(passes < FROZEN_VAPOR_MAX_PASSES, \
		"пар не опустился ниже порога за [FROZEN_VAPOR_MAX_PASSES] проходов: турф не сможет уснуть")
	TEST_ASSERT(tile_air.get_moles(GAS_H2O) < MOLES_GAS_VISIBLE, \
		"цикл вышел, но пара всё ещё хватает на порог реакции")

#undef FROZEN_VAPOR_MAX_PASSES
