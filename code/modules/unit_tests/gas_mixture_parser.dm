// Слой данных газоанализатора: контракт gas_mixture_parser() и сбор
// реакций-кандидатов. Поля списка читает интерфейс, менять их состав дорого.

/// Ключ газа, которому заведомо не соответствует ни один /datum/gas.
#define UNIT_TEST_UNREGISTERED_GAS "bluemoon_unit_test_gas"

/// Достаёт запись газа по строковому id из блока "gases".
/proc/unit_test_parsed_gas_entry(list/parsed, gas_id)
	var/list/parsed_gases = parsed["gases"]
	for(var/list/entry as anything in parsed_gases)
		if(entry[1] == gas_id)
			return entry
	return null

/// Достаёт запись реакции по строковому id из блока "reactions".
/proc/unit_test_parsed_reaction_entry(list/parsed, reaction_id)
	var/list/parsed_reactions = parsed["reactions"]
	for(var/list/entry as anything in parsed_reactions)
		if(entry[1] == reaction_id)
			return entry
	return null

/datum/unit_test/gas_mixture_parser/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")

	// Смеси нет: ключи всё равно на месте, иначе интерфейс читает пустоту.
	var/list/null_data = gas_mixture_parser(null, "нет смеси")
	TEST_ASSERT_NOTNULL(null_data, "gas_mixture_parser(null) вернул null вместо заготовки")
	for(var/key in list("name", "reference", "total_moles", "temperature", "volume", "pressure", "gases", "reactions"))
		TEST_ASSERT(key in null_data, "контракт потерял ключ [key] на отсутствующей смеси")
	TEST_ASSERT(isnull(null_data["total_moles"]), "total_moles на отсутствующей смеси не null")
	var/list/null_gases = null_data["gases"]
	TEST_ASSERT_EQUAL(length(null_gases), 0, "отсутствующая смесь дала газы")

	// Пустая смесь.
	var/datum/gas_mixture/empty_mix = new(CELL_VOLUME)
	var/list/empty_data = gas_mixture_parser(empty_mix, "пустая")
	TEST_ASSERT_NOTNULL(empty_data, "gas_mixture_parser() вернул null на пустой смеси")
	TEST_ASSERT_EQUAL(empty_data["name"], "пустая", "подпись смеси потерялась")
	var/list/empty_gases = empty_data["gases"]
	var/list/empty_reactions = empty_data["reactions"]
	TEST_ASSERT_EQUAL(length(empty_gases), 0, "пустая смесь дала газы")
	TEST_ASSERT_EQUAL(empty_data["total_moles"], 0, "пустая смесь дала ненулевые моли")
	TEST_ASSERT(length(empty_data["reference"]), "reference пустой смеси пуст")
	TEST_ASSERT_EQUAL(length(empty_reactions), 0, "пустая смесь дала реакции-кандидаты")
	qdel(empty_mix)

	// Смесь из двух газов: состав и числа должны совпадать с проками смеси.
	var/datum/gas_mixture/air_mix = new(CELL_VOLUME)
	air_mix.set_moles(GAS_O2, 21)
	air_mix.set_moles(GAS_N2, 79)
	air_mix.set_temperature(T20C)
	var/list/air_data = gas_mixture_parser(air_mix, "воздух")
	var/list/air_gases = air_data["gases"]
	TEST_ASSERT_EQUAL(length(air_gases), 2, "двухгазовая смесь дала другое число записей")
	var/list/o2_entry = unit_test_parsed_gas_entry(air_data, GAS_O2)
	var/list/n2_entry = unit_test_parsed_gas_entry(air_data, GAS_N2)
	TEST_ASSERT_NOTNULL(o2_entry, "кислород не попал в разобранный состав")
	TEST_ASSERT_NOTNULL(n2_entry, "азот не попал в разобранный состав")
	TEST_ASSERT_EQUAL(o2_entry[2], GLOB.gas_data.names[GAS_O2], "имя кислорода не из GLOB.gas_data.names")
	TEST_ASSERT_EQUAL(n2_entry[2], GLOB.gas_data.names[GAS_N2], "имя азота не из GLOB.gas_data.names")
	TEST_ASSERT_EQUAL(o2_entry[3], air_mix.get_moles(GAS_O2), "моли кислорода разошлись с get_moles()")
	TEST_ASSERT_EQUAL(n2_entry[3], air_mix.get_moles(GAS_N2), "моли азота разошлись с get_moles()")
	TEST_ASSERT_EQUAL(air_data["total_moles"], air_mix.total_moles(), "total_moles разошлось с total_moles()")
	TEST_ASSERT_EQUAL(air_data["temperature"], air_mix.return_temperature(), "temperature разошлась с return_temperature()")
	TEST_ASSERT_EQUAL(air_data["volume"], air_mix.return_volume(), "volume разошёлся с return_volume()")
	TEST_ASSERT_EQUAL(air_data["pressure"], air_mix.return_pressure(), "pressure разошлось с return_pressure()")
	TEST_ASSERT_EQUAL(air_data["reference"], REF(air_mix), "reference не равен REF(смеси)")
	// Обычный воздух не удовлетворяет ни одной реакции - кандидатов быть не должно.
	var/list/air_reactions = air_data["reactions"]
	TEST_ASSERT_EQUAL(length(air_reactions), 0, "обычный воздух дал реакции-кандидаты")
	// Разбор не имеет права трогать внутренний список смеси, отданный по ссылке.
	TEST_ASSERT_EQUAL(length(air_mix.get_gases()), 2, "разбор изменил состав смеси")
	qdel(air_mix)

	// Газ без записи в GLOB.gas_data.names: set_moles() ключ не валидирует.
	TEST_ASSERT(isnull(GLOB.gas_data.names[UNIT_TEST_UNREGISTERED_GAS]), "тестовый ключ неожиданно зарегистрирован как газ")
	var/datum/gas_mixture/odd_mix = new(CELL_VOLUME)
	odd_mix.set_moles(UNIT_TEST_UNREGISTERED_GAS, 4)
	var/list/odd_data = gas_mixture_parser(odd_mix, "неизвестный газ")
	var/list/odd_entry = unit_test_parsed_gas_entry(odd_data, UNIT_TEST_UNREGISTERED_GAS)
	TEST_ASSERT_NOTNULL(odd_entry, "незарегистрированный газ пропал из состава")
	TEST_ASSERT_EQUAL(odd_entry[2], UNIT_TEST_UNREGISTERED_GAS, "имя незарегистрированного газа не подставилось из ключа")
	TEST_ASSERT(length(odd_entry[2]), "имя незарегистрированного газа пустое")
	qdel(odd_mix)

	// Реакция-кандидат. bzformation требует только моли (N2O и плазма), без порога
	// по температуре, поэтому её условия выполняются предсказуемо.
	var/datum/gas_reaction/bz_reaction
	for(var/datum/gas_reaction/reaction as anything in SSair.gas_reactions)
		if(istype(reaction, /datum/gas_reaction/bzformation))
			bz_reaction = reaction
			break
	TEST_ASSERT_NOTNULL(bz_reaction, "bzformation не зарегистрирована в SSair.gas_reactions")
	var/nitrous_threshold = bz_reaction.min_requirements[GAS_NITROUS]
	var/plasma_threshold = bz_reaction.min_requirements[GAS_PLASMA]
	TEST_ASSERT(nitrous_threshold > 0 && plasma_threshold > 0, "у bzformation больше нет порогов по молям, тест надо переписать")
	var/datum/gas_mixture/bz_mix = new(CELL_VOLUME)
	bz_mix.set_moles(GAS_NITROUS, nitrous_threshold * 2)
	bz_mix.set_moles(GAS_PLASMA, plasma_threshold * 2)
	bz_mix.set_temperature(T20C)
	var/list/bz_data = gas_mixture_parser(bz_mix, "формирование бз")
	var/list/bz_entry = unit_test_parsed_reaction_entry(bz_data, bz_reaction.id)
	TEST_ASSERT_NOTNULL(bz_entry, "смесь по условиям bzformation не дала её в кандидатах")
	TEST_ASSERT_EQUAL(bz_entry[2], bz_reaction.name, "имя реакции-кандидата разошлось с датумом")
	TEST_ASSERT(isnull(bz_entry[3]), "значение реакции-кандидата должно быть null")
	qdel(bz_mix)

	// Тех же газов ниже порога не хватает - реакция обязана исчезнуть из кандидатов.
	var/datum/gas_mixture/thin_mix = new(CELL_VOLUME)
	thin_mix.set_moles(GAS_NITROUS, nitrous_threshold / 4)
	thin_mix.set_moles(GAS_PLASMA, plasma_threshold / 4)
	thin_mix.set_temperature(T20C)
	var/list/thin_data = gas_mixture_parser(thin_mix, "мало газа")
	TEST_ASSERT_NULL(unit_test_parsed_reaction_entry(thin_data, bz_reaction.id), "bzformation осталась в кандидатах ниже порога молей")
	var/list/thin_reactions = thin_data["reactions"]
	TEST_ASSERT_EQUAL(length(thin_reactions), 0, "смесь ниже всех порогов дала реакции-кандидаты")
	qdel(thin_mix)

#undef UNIT_TEST_UNREGISTERED_GAS
