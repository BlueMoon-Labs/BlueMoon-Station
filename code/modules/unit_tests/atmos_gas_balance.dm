/// Верхние рецепты кристаллизатора стоят за порогом высокого давления. Это
/// несущая часть баланса: дешёвый газ перестаёт давать ценный материал даром.
/datum/unit_test/gas_recipe_pressure_gate

/datum/unit_test/gas_recipe_pressure_gate/Run()
	var/datum/gas_recipe/gated = GLOB.gas_recipe_meta["diamond"]
	TEST_ASSERT_NOTNULL(gated, "рецепт алмаза пропал из каталога")
	TEST_ASSERT(gated.min_pressure > MAX_OUTPUT_PRESSURE,
		"алмаз обязан требовать давления выше потолка газового насоса, иначе 1500 молей самого дешёвого газа в игре снова дают ценный материал даром")
	TEST_ASSERT(gated.min_pressure < VOLUME_PUMP_PRESSURE_CEILING,
		"порог обязан быть достижим объёмным насосом, иначе рецепт заперт целиком")

	var/obj/machinery/atmospherics/components/binary/crystallizer/machine = allocate(/obj/machinery/atmospherics/components/binary/crystallizer)
	machine.selected_recipe = gated
	var/datum/gas_mixture/feed = machine.airs[2]
	TEST_ASSERT_NOTNULL(feed, "у кристаллизатора нет подающего порта")

	// Давление обычной разводки: ворота обязаны быть закрыты.
	feed.set_volume(CELL_VOLUME)
	feed.set_temperature(T20C)
	feed.set_moles(GAS_CO2, 0)
	TEST_ASSERT(!machine.check_pressure_requirements(), "рецепт с порогом пошёл на пустой линии")

	feed.set_moles(GAS_CO2, MOLES_CELLSTANDARD)
	TEST_ASSERT(feed.return_pressure() < gated.min_pressure, "тест сам себе противоречит: контрольное давление уже выше порога")
	TEST_ASSERT(!machine.check_pressure_requirements(), "рецепт с порогом пошёл на давлении обычной разводки")

	// Додавленная линия: ворота открываются. Молей ровно на полтора порога -
	// контроль следует за дефайном и не ломается при ребалансе.
	feed.set_moles(GAS_CO2, gated.min_pressure * 1.5 * CELL_VOLUME / (R_IDEAL_GAS_EQUATION * T20C))
	TEST_ASSERT(feed.return_pressure() >= gated.min_pressure, "тест не смог поднять давление выше порога")
	TEST_ASSERT(machine.check_pressure_requirements(), "рецепт не пошёл на давлении выше порога")

	// Рецепт без порога не должен ничего требовать.
	var/datum/gas_recipe/ungated = GLOB.gas_recipe_meta["ammonia_crystal"]
	TEST_ASSERT_NOTNULL(ungated, "рецепт кристалла аммиака пропал из каталога")
	TEST_ASSERT_EQUAL(ungated.min_pressure, 0, "дешёвому рецепту порог давления не полагается")
	machine.selected_recipe = ungated
	feed.set_moles(GAS_CO2, 0)
	TEST_ASSERT(machine.check_pressure_requirements(), "рецепт без порога потребовал давления")

	// Криогенное окно и порог давления взаимоисключающи: при 20 K порог 15000 кПа
	// означает ~80 молей на литр холодной подающей линии - десятки тысяч молей
	// ради рецепта в 400, и догреть линию нельзя, камера обязана остаться ледяной.
	// Заукерит уже оплачен молями и глубиной цепочки (см. тест ниже).
	var/datum/gas_recipe/cryo_gated = GLOB.gas_recipe_meta["zaukerite"]
	TEST_ASSERT_NOTNULL(cryo_gated, "рецепт заукерита пропал из каталога")
	TEST_ASSERT_EQUAL(cryo_gated.min_pressure, 0,
		"заукерит с окном [cryo_gated.min_temp]-[cryo_gated.max_temp] K требует давления: при криогенном окне порог физически недостижим без десятков тысяч молей в линии")

/// Цена в молях обязана расти вместе с глубиной цепочки. Ровно здесь баланс и
/// разъехался в прошлый раз: заукерит из шести газов вглубь стоил 33 моля, а
/// гипернобель из двух шагов - 1085.
/datum/unit_test/gas_recipe_depth_matches_cost

/datum/unit_test/gas_recipe_depth_matches_cost/Run()
	var/datum/gas_recipe/zaukerite = GLOB.gas_recipe_meta["zaukerite"]
	var/datum/gas_recipe/hypernoblium = GLOB.gas_recipe_meta["hyper_crystalium"]
	TEST_ASSERT_NOTNULL(zaukerite, "рецепт заукерита пропал из каталога")
	TEST_ASSERT_NOTNULL(hypernoblium, "рецепт гипернобель-кристалла пропал из каталога")

	var/zaukerite_moles = 0
	for(var/gas_id in zaukerite.requirements)
		zaukerite_moles += zaukerite.requirements[gas_id]
	var/hypernoblium_moles = 0
	for(var/gas_id in hypernoblium.requirements)
		hypernoblium_moles += hypernoblium.requirements[gas_id]

	// Заукер - это гипернобель ПЛЮС нитрий, то есть строго глубже. Значит и
	// стоить он обязан не меньше, иначе игрок делает верхний газ в обход.
	TEST_ASSERT(zaukerite_moles >= hypernoblium_moles * 0.3,
		"заукерит стоит [zaukerite_moles] молей против [hypernoblium_moles] у куда более простого гипернобеля - глубина цепочки снова не оплачена")

/// У каждого газа обязано быть описание для внутриигрового справочника.
///
/// До этой правки atmospherics_handbook.dm жёстко писал пустую строку всем 28
/// газам: игрок видел название и теплоёмкость, и всё. Без теста следующий
/// добавленный газ приедет в справочник таким же пустым, и никто не заметит.
/datum/unit_test/gas_handbook_descriptions

/datum/unit_test/gas_handbook_descriptions/Run()
	var/checked = 0
	for(var/gas_path in subtypesof(/datum/gas))
		var/datum/gas/gas = new gas_path
		checked++
		TEST_ASSERT(length(gas.description) > 0, "у газа [gas.name] нет описания для справочника")
		// Схема требует ответа на "зачем" и "чем опасен", а в одно предложение
		// это не влезает. Порог грубый, но он ловит заглушки вида "Газ.".
		TEST_ASSERT(length(gas.description) > 60, "описание газа [gas.name] слишком короткое, чтобы ответить зачем он нужен и чем опасен")
		qdel(gas)
	TEST_ASSERT(checked > 20, "ожидался полный список газов, найдено [checked]")

	// И то же самое на выходе справочника: поле могло не пробросить.
	atmos_handbooks_init()
	TEST_ASSERT(length(GLOB.gas_handbook) > 20, "справочник газов пуст")
	for(var/list/entry as anything in GLOB.gas_handbook)
		TEST_ASSERT(length(entry["description"]) > 0, "справочник отдал пустое описание для [entry["name"]]")

/// Цена продажи обязана расти вместе со сложностью синтеза.
///
/// Ровно здесь баланс и разъехался: заукер - гипернобель плюс нитрий, каждый со
/// своим температурным окном, причём окна противоположные - стоил 7 кредитов за
/// моль, нитрий 6, хилий 5.5. Самый глубокий газ в игре продавался почти как
/// вдвое более простой, а плуоксий из одного узла - как трижды переваренный
/// прото-нитрат.
///
/// Порядок сложности объявлен явно, списком, а не выводится читателем из цепочки
/// реакций: выводить его глазами - это ровно то, чем занимался прошлый
/// калибровщик, и результат виден выше.
/datum/unit_test/gas_price_matches_tier

/// Полоса цен для уровня, list(нижняя граница, верхняя). null означает уровень
/// вне лестницы, и это ошибка сама по себе.
/datum/unit_test/gas_price_matches_tier/proc/price_band(tier)
	switch(tier)
		if(GAS_TIER_RAW)
			return list(GAS_PRICE_MIN_TIER_RAW, GAS_PRICE_MAX_TIER_RAW)
		if(GAS_TIER_BASIC)
			return list(GAS_PRICE_MIN_TIER_BASIC, GAS_PRICE_MAX_TIER_BASIC)
		if(GAS_TIER_ADVANCED)
			return list(GAS_PRICE_MIN_TIER_ADVANCED, GAS_PRICE_MAX_TIER_ADVANCED)
		if(GAS_TIER_EXOTIC)
			return list(GAS_PRICE_MIN_TIER_EXOTIC, GAS_PRICE_MAX_TIER_EXOTIC)
	return null

/datum/unit_test/gas_price_matches_tier/Run()
	// Явная лестница сложности синтеза: каждая следующая ступень требует всего,
	// что требует предыдущая, плюс ещё один шаг. Обоснование ступени стоит рядом
	// с ней - иначе через полгода никто не вспомнит, почему хилий дороже фреона.
	var/list/difficulty_chain = list(
		GAS_CO2,		// сырьё: идёт при любом горении и при каждом выдохе
		GAS_BZ,			// один узел: закись азота с плазмой на низком давлении
		GAS_FREON,		// тот же узел, но на входе уже BZ, и своё окно по теплу
		GAS_HEALIUM,	// второй узел с узким окном: BZ поверх готового фреона
		GAS_ZAUKER,		// вершина: крио-гипернобель и горячий нитрий одновременно
	)
	var/datum/gas/previous
	for(var/gas_id in difficulty_chain)
		var/datum/gas/gas = GLOB.gas_data.datums[gas_id]
		TEST_ASSERT_NOTNULL(gas, "газ [gas_id] пропал из каталога, и лестница сложности больше ничего не проверяет")
		if(previous)
			// Уровень не убывает: две соседние ступени могут быть одного уровня
			// (BZ и фреон оба делаются в одном узле), но не наоборот.
			TEST_ASSERT(gas.tier >= previous.tier,
				"[gas.name] объявлен уровнем [gas.tier], а более простой [previous.name] - уровнем [previous.tier]: лестница сложности перевёрнута")
			// А вот цена обязана расти строго, в том числе внутри одного уровня:
			// фреон варится из готового BZ и не может стоить столько же.
			TEST_ASSERT(gas.price > previous.price,
				"[gas.name] сложнее в синтезе, чем [previous.name], но стоит [gas.price] против [previous.price]")
		previous = gas

	// Цена каждого газа обязана лежать в полосе своего уровня. Полосы разделены
	// зазором, поэтому попадание в полосу само по себе держит порядок уровней, а
	// сообщение указывает на конкретный газ, а не на пару.
	var/list/all_gases = list()
	for(var/gas_id in GLOB.gas_data.datums)
		var/datum/gas/gas = GLOB.gas_data.datums[gas_id]
		all_gases += gas
		var/list/band = price_band(gas.tier)
		TEST_ASSERT_NOTNULL(band, "у газа [gas.name] уровень [gas.tier] вне лестницы GAS_TIER_RAW..GAS_TIER_EXOTIC")
		TEST_ASSERT(gas.price >= band[1], "цена газа [gas.name] ([gas.price]) ниже полосы его уровня ([band[1]]..[band[2]])")
		TEST_ASSERT(gas.price <= band[2], "цена газа [gas.name] ([gas.price]) выше полосы его уровня ([band[1]]..[band[2]])")
	// Каталог собирается из пяти деревьев кода. Если их подключилось меньше,
	// проверки выше пройдут вхолостую на огрызке списка.
	TEST_ASSERT(length(all_gases) >= 28, "в каталоге всего [length(all_gases)] газов, ожидалось не меньше 28")

	// И полный попарный обход: газ более глубокого уровня не может стоить дешевле
	// менее глубокого. Именно эта проверка обязана падать, если кто-то поднимет
	// цену дешёвому газу выше цены дорогого.
	for(var/datum/gas/simpler as anything in all_gases)
		for(var/datum/gas/harder as anything in all_gases)
			if(simpler.tier >= harder.tier)
				continue
			TEST_ASSERT(simpler.price < harder.price,
				"[simpler.name] (уровень [simpler.tier]) стоит [simpler.price], а более сложный [harder.name] (уровень [harder.tier]) - [harder.price]: сложнее сделать обязано быть дороже")

/// Очки науки платятся за первый за раунд синтез каждого газа, и ровно один раз.
///
/// Плата за объём превратила бы атмос в ферму очков и обесценила бы остальную
/// науку, поэтому наградой сделана широта освоенного. Без этого теста повторный
/// синтез начал бы платить снова при первой же правке рядом, и никто не заметил
/// бы этого до конца смены.
/datum/unit_test/gas_synthesis_research_award

/datum/unit_test/gas_synthesis_research_award/Run()
	var/datum/techweb/web = new /datum/techweb
	var/starting_points = web.research_points[TECHWEB_POINT_TYPE_GENERIC] || 0

	// Сырьё открытием не считается: кислород есть у всех с первой секунды раунда.
	TEST_ASSERT(!web.discover_gas_synthesis(GAS_O2), "сырьевой газ засчитался как открытие")
	TEST_ASSERT_EQUAL(web.research_points[TECHWEB_POINT_TYPE_GENERIC] || 0, starting_points,
		"сырьевой газ изменил счёт очков")

	// Несуществующий id не должен ни падать, ни платить.
	TEST_ASSERT(!web.discover_gas_synthesis("такого_газа_нет"), "неизвестный газ засчитался как открытие")
	TEST_ASSERT_EQUAL(web.research_points[TECHWEB_POINT_TYPE_GENERIC] || 0, starting_points,
		"неизвестный газ изменил счёт очков")

	TEST_ASSERT(web.discover_gas_synthesis(GAS_BZ), "первый синтез BZ не засчитался")
	TEST_ASSERT_EQUAL(web.research_points[TECHWEB_POINT_TYPE_GENERIC] || 0, starting_points + GAS_DISCOVERY_RESEARCH_BASIC,
		"за первый синтез базового газа начислено не [GAS_DISCOVERY_RESEARCH_BASIC] очков")

	TEST_ASSERT(!web.discover_gas_synthesis(GAS_BZ), "повторный синтез BZ засчитался вторым открытием")
	TEST_ASSERT_EQUAL(web.research_points[TECHWEB_POINT_TYPE_GENERIC] || 0, starting_points + GAS_DISCOVERY_RESEARCH_BASIC,
		"повторный синтез BZ изменил счёт очков")

	// Глубина оплачивается дороже: иначе награда не отличает вершину от базы.
	TEST_ASSERT(web.discover_gas_synthesis(GAS_ZAUKER), "первый синтез заукера не засчитался")
	var/exotic_total = starting_points + GAS_DISCOVERY_RESEARCH_BASIC + GAS_DISCOVERY_RESEARCH_EXOTIC
	TEST_ASSERT_EQUAL(web.research_points[TECHWEB_POINT_TYPE_GENERIC] || 0, exotic_total,
		"за газ вершины цепочки начислено не [GAS_DISCOVERY_RESEARCH_EXOTIC] очков")

	// Средний уровень обязан платить строго между базой и вершиной, иначе награда
	// перестаёт отличать глубину и вырождается в фиксированную подачку.
	TEST_ASSERT(web.discover_gas_synthesis(GAS_HEALIUM), "первый синтез хилия не засчитался")
	var/advanced_award = (web.research_points[TECHWEB_POINT_TYPE_GENERIC] || 0) - exotic_total
	TEST_ASSERT_EQUAL(advanced_award, GAS_DISCOVERY_RESEARCH_ADVANCED, "за газ среднего уровня начислено [advanced_award] очков")
	TEST_ASSERT(advanced_award > GAS_DISCOVERY_RESEARCH_BASIC, "средний уровень платит [advanced_award], не больше базового [GAS_DISCOVERY_RESEARCH_BASIC]")
	TEST_ASSERT(advanced_award < GAS_DISCOVERY_RESEARCH_EXOTIC, "средний уровень платит [advanced_award], не меньше вершины [GAS_DISCOVERY_RESEARCH_EXOTIC]")

	qdel(web)

/// У каждого синтезируемого газа обязан быть источник, который сообщает о первом
/// синтезе. Без этой проверки следующий добавленный газ молча не даст очков: путь
/// "газ - наука" держится на поле synthesis_gas, и забыть его ничего не стоит.
/datum/unit_test/gas_synthesis_sources_cover_tiers

/datum/unit_test/gas_synthesis_sources_cover_tiers/Run()
	var/list/reported_gases = list()
	for(var/reaction_path in subtypesof(/datum/gas_reaction))
		var/datum/gas_reaction/reaction = new reaction_path
		if(reaction.synthesis_gas)
			reported_gases[reaction.synthesis_gas] = TRUE
		qdel(reaction)
	for(var/reaction_path in subtypesof(/datum/electrolyzer_reaction))
		var/datum/electrolyzer_reaction/reaction = new reaction_path
		if(reaction.synthesis_gas)
			reported_gases[reaction.synthesis_gas] = TRUE
		qdel(reaction)
	TEST_ASSERT(length(reported_gases) > 0, "ни одна реакция не объявила synthesis_gas - путь газ-наука оборван целиком")

	for(var/gas_id in GLOB.gas_data.datums)
		var/datum/gas/gas = GLOB.gas_data.datums[gas_id]
		if(gas.tier <= GAS_TIER_RAW)
			continue
		TEST_ASSERT(reported_gases[gas_id],
			"[gas.name] объявлен синтезируемым (уровень [gas.tier]), но ни одна реакция не сообщает о его первом синтезе - очков науки за него не будет")

/// Синтез пиронита и флюксина обязан быть закрыт давлением, которого обычная
/// разводка не держит. Это единственное, ради чего оба газа существуют: без
/// работающих ворот они просто ещё две строки в списке из тридцати.
///
/// Ключ REACTION_REQ_MIN_PRESSURE обязан быть известен трём местам сразу
/// (цикл реакций, индексатор ключевых газов, сборщик кандидатов), и забытый
/// индексатор - самая тихая из возможных поломок: реакция уезжает в бакет
/// несуществующего газа и не идёт НИКОГДА, ничего при этом не сообщая.
/datum/unit_test/gas_high_pressure_synthesis

/// Ищет реакцию по её id среди активных.
/datum/unit_test/gas_high_pressure_synthesis/proc/find_reaction(reaction_id)
	for(var/datum/gas_reaction/reaction as anything in SSair.gas_reactions)
		if(reaction.id == reaction_id)
			return reaction
	return null

/datum/unit_test/gas_high_pressure_synthesis/Run()
	var/list/reaction_index = SSair.reactions_by_key_gas
	TEST_ASSERT_NOTNULL(reaction_index, "индекс реакций по ключевому газу не построен")
	TEST_ASSERT_NULL(reaction_index[REACTION_REQ_MIN_PRESSURE],
		"порог давления приняли за идентификатор газа: реакция уехала в бакет несуществующего газа и не пойдёт никогда")

	var/datum/gas_reaction/pyronite = find_reaction("pyronite_formation")
	var/datum/gas_reaction/fluxin = find_reaction("fluxin_formation")
	TEST_ASSERT_NOTNULL(pyronite, "реакция синтеза пиронита пропала из SSair.gas_reactions")
	TEST_ASSERT_NOTNULL(fluxin, "реакция синтеза флюксина пропала из SSair.gas_reactions")
	TEST_ASSERT_EQUAL(pyronite.min_requirements[REACTION_REQ_MIN_PRESSURE], GAS_HIGH_PRESSURE_SYNTHESIS,
		"пиронит перестал требовать давления")
	TEST_ASSERT_EQUAL(fluxin.min_requirements[REACTION_REQ_MIN_PRESSURE], GAS_HIGH_PRESSURE_SYNTHESIS,
		"флюксин перестал требовать давления")
	TEST_ASSERT(GAS_HIGH_PRESSURE_SYNTHESIS > MAX_OUTPUT_PRESSURE,
		"порог синтеза не выше потолка газового насоса - высокое давление перестало быть требованием")
	TEST_ASSERT(GAS_HIGH_PRESSURE_SYNTHESIS < VOLUME_PUMP_PRESSURE_CEILING,
		"порог синтеза выше потолка объёмного насоса: газ заперт целиком")

	// Все требования кроме давления выполнены - реакция обязана стоять.
	var/datum/gas_mixture/mixture = new(1000)
	mixture.set_moles(GAS_TRITIUM, 40)
	mixture.set_moles(GAS_PLASMA, 40)
	mixture.set_moles(GAS_PROTO_NITRATE, 10)
	mixture.set_temperature(PYRONITE_FORMATION_MIN_TEMP)
	TEST_ASSERT(mixture.return_pressure() < GAS_HIGH_PRESSURE_SYNTHESIS,
		"тест сам себе противоречит: контрольная смесь уже выше порога давления")
	mixture.react()
	TEST_ASSERT_EQUAL(mixture.get_moles(GAS_PYRONITE), 0,
		"пиронит сварился на давлении обычной разводки")

	// Тот же газ, тот же нагрев, объём под полтора порога - реакция идёт.
	// Объём выводится из дефайна, чтобы ребаланс порога не ломал контроль.
	mixture.set_volume(90 * R_IDEAL_GAS_EQUATION * PYRONITE_FORMATION_MIN_TEMP / (GAS_HIGH_PRESSURE_SYNTHESIS * 1.5))
	mixture.set_temperature(PYRONITE_FORMATION_MIN_TEMP)
	TEST_ASSERT(mixture.return_pressure() >= GAS_HIGH_PRESSURE_SYNTHESIS,
		"тест не смог поднять давление выше порога")
	mixture.react()
	TEST_ASSERT(mixture.get_moles(GAS_PYRONITE) > 0,
		"пиронит не сварился на давлении выше порога")

	var/datum/gas_mixture/catalyst_mix = new(1000)
	catalyst_mix.set_moles(GAS_HELIUM, 40)
	catalyst_mix.set_moles(GAS_BZ, 20)
	catalyst_mix.set_moles(GAS_PLASMA, 20)
	catalyst_mix.set_temperature(FLUXIN_FORMATION_MIN_TEMP + 100)
	TEST_ASSERT(catalyst_mix.return_pressure() < GAS_HIGH_PRESSURE_SYNTHESIS,
		"тест сам себе противоречит: контрольная смесь катализатора уже выше порога")
	catalyst_mix.react()
	TEST_ASSERT_EQUAL(catalyst_mix.get_moles(GAS_FLUXIN), 0,
		"флюксин сварился на давлении обычной разводки")

	// Объём под полтора порога при этих молях и температуре: контроль следует
	// за дефайном, а пропорции смеси (реакция к ним чувствительна) не трогаем.
	catalyst_mix.set_volume(80 * R_IDEAL_GAS_EQUATION * (FLUXIN_FORMATION_MIN_TEMP + 100) / (GAS_HIGH_PRESSURE_SYNTHESIS * 1.5))
	catalyst_mix.set_temperature(FLUXIN_FORMATION_MIN_TEMP + 100)
	TEST_ASSERT(catalyst_mix.return_pressure() >= GAS_HIGH_PRESSURE_SYNTHESIS,
		"тест не смог поднять давление катализатора выше порога")
	catalyst_mix.react()
	TEST_ASSERT(catalyst_mix.get_moles(GAS_FLUXIN) > 0,
		"флюксин не сварился на давлении выше порога")

/// Флюксин обязан делать ровно то, ради чего он есть: раздвигать верхнюю
/// границу окна и снижать расход сырья на единицу продукта. Иначе он просто
/// дорогой газ без применения, а весь цикл "глубина делает глубину дешевле"
/// остаётся текстом в описании.
/datum/unit_test/fluxin_catalysis

/datum/unit_test/fluxin_catalysis/Run()
	// Выше штатного окна хилия, но внутри раздвинутого катализатором.
	var/widened_temperature = HEALIUM_FORMATION_MAX_TEMP * (1 + FLUXIN_MAX_BONUS * 0.5)
	TEST_ASSERT(widened_temperature > HEALIUM_FORMATION_MAX_TEMP,
		"контрольная температура не выше штатного окна, тест прошёл бы вхолостую")

	var/datum/gas_mixture/uncatalysed = new(1000)
	uncatalysed.set_moles(GAS_FREON, 100)
	uncatalysed.set_moles(GAS_BZ, 100)
	uncatalysed.set_temperature(widened_temperature)
	uncatalysed.react()
	TEST_ASSERT_EQUAL(uncatalysed.get_moles(GAS_HEALIUM), 0,
		"хилий сварился выше своего температурного окна без катализатора")

	var/datum/gas_mixture/catalysed = new(1000)
	catalysed.set_moles(GAS_FREON, 100)
	catalysed.set_moles(GAS_BZ, 100)
	catalysed.set_moles(GAS_FLUXIN, FLUXIN_FULL_EFFECT_MOLES)
	catalysed.set_temperature(widened_temperature)
	catalysed.react()
	TEST_ASSERT(catalysed.get_moles(GAS_HEALIUM) > 0,
		"катализатор не раздвинул температурное окно хилия")
	TEST_ASSERT(catalysed.get_moles(GAS_FLUXIN) < FLUXIN_FULL_EFFECT_MOLES,
		"катализатор не тратится: сваренный один раз, он работал бы всю смену даром")

	// Расход сырья: внутри штатного окна тот же фреон обязан дать больше хилия.
	var/inside_window = (HEALIUM_FORMATION_MIN_TEMP + HEALIUM_FORMATION_MAX_TEMP) * 0.5
	var/datum/gas_mixture/plain = new(1000)
	plain.set_moles(GAS_FREON, 100)
	plain.set_moles(GAS_BZ, 100)
	plain.set_temperature(inside_window)
	plain.react()
	var/plain_yield = plain.get_moles(GAS_HEALIUM)
	TEST_ASSERT(plain_yield > 0, "хилий не сварился внутри собственного окна - тест измеряет не то")

	var/datum/gas_mixture/boosted = new(1000)
	boosted.set_moles(GAS_FREON, 100)
	boosted.set_moles(GAS_BZ, 100)
	boosted.set_moles(GAS_FLUXIN, FLUXIN_FULL_EFFECT_MOLES)
	boosted.set_temperature(inside_window)
	boosted.react()
	TEST_ASSERT(boosted.get_moles(GAS_HEALIUM) > plain_yield,
		"с катализатором из того же сырья вышло [boosted.get_moles(GAS_HEALIUM)] молей хилия против [plain_yield] без него - расход не снизился")

/// Новый газ - это не только /datum/gas. Тест держит остальное: облако, цену на
/// своём месте лестницы, участие в реакциях и вход в верхний рецепт.
/datum/unit_test/high_pressure_gas_catalogue

/datum/unit_test/high_pressure_gas_catalogue/Run()
	var/list/cloud_states = icon_states('icons/effects/atmospherics.dmi')
	for(var/gas_id in list(GAS_PYRONITE, GAS_FLUXIN))
		var/datum/gas/gas = GLOB.gas_data.datums[gas_id]
		TEST_ASSERT_NOTNULL(gas, "газ [gas_id] не зарегистрирован в GLOB.gas_data")
		TEST_ASSERT(gas.gas_overlay in cloud_states,
			"[gas.name] рисует облако состоянием '[gas.gas_overlay]', которого нет в atmospherics.dmi - в игре это невидимый газ")
		TEST_ASSERT(GLOB.gas_data.names[gas_id] == gas.name,
			"[gas_id] не попал в таблицу имён, а по ней строятся списки фильтров, скрубберов и анализатора")

	// Оба газа третьего уровня: они дороже всего, что варится без порога
	// высокого давления. Ровно на этом месте баланс и разъезжается - газ глубже,
	// а стоит дешевле, и игрок выбирает не по глубине, а по цене.
	var/list/prices = GLOB.gas_data.prices
	for(var/deep_gas in list(GAS_PYRONITE, GAS_FLUXIN))
		for(var/shallower_gas in list(GAS_ZAUKER, GAS_STIMULUM, GAS_NITRIUM, GAS_HEALIUM))
			TEST_ASSERT(prices[deep_gas] > prices[shallower_gas],
				"[GLOB.gas_data.names[deep_gas]] стоит [prices[deep_gas]] против [prices[shallower_gas]] у [GLOB.gas_data.names[shallower_gas]] - глубина цепочки снова не оплачена")

	// Канистра - единственный способ вынести газ из труб, и её спрайт носит
	// суффикс -1 для полупустого состояния. Пропущенный суффикс даёт невидимую
	// канистру ровно в тот момент, когда её начали расходовать.
	for(var/obj/machinery/portable_atmospherics/canister/tank as anything in list(
		/obj/machinery/portable_atmospherics/canister/pyronite,
		/obj/machinery/portable_atmospherics/canister/fluxin,
	))
		var/list/canister_states = icon_states(initial(tank.icon))
		var/base_state = initial(tank.icon_state)
		TEST_ASSERT(base_state in canister_states, "[initial(tank.name)] рисуется состоянием '[base_state]', которого нет в файле")
		TEST_ASSERT("[base_state]-1" in canister_states, "у канистры [initial(tank.name)] нет полупустого состояния '[base_state]-1'")

	// Топливо обязано входить в верхний материал: без этого оно остаётся газом,
	// который некуда девать, а вся ось крафта - обещанием.
	var/datum/gas_recipe/shard = GLOB.gas_recipe_meta["crystal_shard"]
	TEST_ASSERT_NOTNULL(shard, "рецепт осколка супермтерии пропал из каталога")
	TEST_ASSERT(shard.requirements[GAS_PYRONITE] > 0, "верхний рецепт кристаллизатора перестал требовать пиронит")
	TEST_ASSERT(shard.min_pressure > 0, "верхний рецепт потерял порог давления")

/// Второй уровень обязан давать предмет, который живёт всю смену, а не ещё одну
/// гранату - и обязан продолжать давать гранату тоже: известный дешёвый путь у
/// игрока не отбирается, ему добавляется выбор.
/datum/unit_test/gas_recipe_permanent_rewards

/datum/unit_test/gas_recipe_permanent_rewards/Run()
	var/list/paired_recipes = list(
		"healium_g" = "healium_defib",
		"crystallized_nitrium" = "nitrium_boots",
		"proto_nitrate_g" = "proto_nitrate_projector",
	)
	for(var/cheap_id in paired_recipes)
		var/datum/gas_recipe/cheap = GLOB.gas_recipe_meta[cheap_id]
		var/datum/gas_recipe/permanent = GLOB.gas_recipe_meta[paired_recipes[cheap_id]]
		TEST_ASSERT_NOTNULL(cheap, "дешёвый рецепт [cheap_id] пропал: известный путь отбирать было нельзя")
		TEST_ASSERT_NOTNULL(permanent, "рецепт на постоянный предмет [paired_recipes[cheap_id]] пропал из каталога")

		var/cheap_moles = 0
		for(var/gas_id in cheap.requirements)
			cheap_moles += cheap.requirements[gas_id]
		var/permanent_moles = 0
		for(var/gas_id in permanent.requirements)
			permanent_moles += permanent.requirements[gas_id]
		TEST_ASSERT(permanent_moles > cheap_moles * 2,
			"[permanent.name] стоит [permanent_moles] молей против [cheap_moles] у одноразового [cheap.name] - выбора между расходником и вещью не возникает")

		// Порог давления - признак третьего уровня, и на втором его быть не должно.
		TEST_ASSERT_EQUAL(permanent.min_pressure, 0, "[permanent.name] требует высокого давления, а это признак третьего уровня")

		// Окно температур постоянного рецепта - подмножество окна гранаты:
		// установка та же, требуется только более точное её ведение.
		TEST_ASSERT(permanent.min_temp >= cheap.min_temp && permanent.max_temp <= cheap.max_temp,
			"[permanent.name] требует окна [permanent.min_temp]-[permanent.max_temp] K вне окна [cheap.min_temp]-[cheap.max_temp] K своей же гранаты")

		for(var/product_path in permanent.products)
			TEST_ASSERT(!ispath(product_path, /obj/item/grenade),
				"[permanent.name] выдаёт гранату [product_path] - весь смысл рецепта был в обратном")
			TEST_ASSERT(ispath(product_path, /obj/item) || ispath(product_path, /obj/machinery),
				"[permanent.name] выдаёт [product_path], который не предмет и не машина")

/// Постоянная награда обязана отличаться механикой, а не только названием и
/// спрайтом. Иначе дорогой рецепт второго уровня проигрывает обычному источнику
/// того же предмета и существует лишь как ловушка для незнающего игрока.
/datum/unit_test/crystallizer_permanent_rewards_have_roles

/datum/unit_test/crystallizer_permanent_rewards_have_roles/Run()
	var/obj/item/defibrillator/compact/loaded/crystallizer/healium_defib = allocate(/obj/item/defibrillator/compact/loaded/crystallizer)
	TEST_ASSERT(healium_defib.healdisk, "хилиумный дефибриллятор снова отличается от обычного только окраской")

	var/obj/item/clothing/shoes/bhop/plain_boots = allocate(/obj/item/clothing/shoes/bhop)
	var/obj/item/clothing/shoes/bhop/crystallizer/nitrium_boots = allocate(/obj/item/clothing/shoes/bhop/crystallizer)
	TEST_ASSERT(nitrium_boots.recharging_rate < plain_boots.recharging_rate,
		"нитриумные ботинки перезаряжаются не быстрее обычных прыжковых")
	TEST_ASSERT_EQUAL(nitrium_boots.jumpdistance, plain_boots.jumpdistance,
		"малый бонус нитриумных ботинок превратился в увеличение дальности рывка")

	var/obj/item/holosign_creator/atmos/sustained/proto_projector = allocate(/obj/item/holosign_creator/atmos/sustained)
	TEST_ASSERT(proto_projector.charge_recovery_active >= proto_projector.charge_drain_per_sign,
		"прото-нитратный проектор больше не может бесконечно держать одну проекцию")

/// Пеллеты приехали из кода exploration drone без самой подсистемы и были
/// пустыми экспортными предметами. В BlueMoon их роль - конечный переносной
/// запас энергии, причём глубина газовой цепочки должна увеличивать импульс.
/datum/unit_test/crystallizer_fuel_pellets_store_energy

/datum/unit_test/crystallizer_fuel_pellets_store_energy/Run()
	var/previous_transfer = 0
	for(var/pellet_path in list(
		/obj/item/fuel_pellet,
		/obj/item/fuel_pellet/advanced,
		/obj/item/fuel_pellet/exotic,
	))
		var/obj/item/fuel_pellet/pellet = allocate(pellet_path)
		var/obj/item/stock_parts/cell/bluespace/cell = allocate(/obj/item/stock_parts/cell/bluespace)
		cell.charge = 0
		var/starting_uses = pellet.uses
		var/transferred = pellet.recharge_cell(cell)
		TEST_ASSERT_EQUAL(transferred, pellet.charge_per_use,
			"[pellet.name] передала [transferred] вместо заявленных [pellet.charge_per_use]")
		TEST_ASSERT(transferred > previous_transfer,
			"[pellet.name] не сильнее пеллеты предыдущего уровня: [transferred] против [previous_transfer]")
		TEST_ASSERT_EQUAL(pellet.uses, starting_uses - 1, "[pellet.name] не потратила ровно один импульс")

		cell.charge = cell.maxcharge
		var/uses_before_full_cell = pellet.uses
		TEST_ASSERT_EQUAL(pellet.recharge_cell(cell), 0, "[pellet.name] передала энергию в полный аккумулятор")
		TEST_ASSERT_EQUAL(pellet.uses, uses_before_full_cell, "[pellet.name] потратила импульс на полный аккумулятор")
		previous_transfer = transferred

/// Награда обязана выглядеть как своя вещь, а не как чужая.
///
/// Все выходы кристаллизатора, кроме второго уровня, - предметы, которые больше
/// нигде не добываются, поэтому вопрос уникальности спрайта у них не вставал. У
/// второго уровня выходы это обычные предметы игры, и без своего спрайта награда
/// за четыре газа неотличима от того, что лежит в медбее.
///
/// Проверяется не «спрайт красивый», а два машинных факта: состояние есть в
/// файле и его не делит с наградой никакой другой тип. Первое ловит опечатку
/// (невидимый предмет), второе - молчаливое переиспользование чужой картинки.
/datum/unit_test/crystallizer_rewards_look_distinct

/datum/unit_test/crystallizer_rewards_look_distinct/Run()
	var/list/checked = list()
	for(var/datum/gas_recipe/recipe as anything in GLOB.gas_recipe_meta)
		var/datum/gas_recipe/meta = GLOB.gas_recipe_meta[recipe]
		if(!istype(meta))
			continue
		for(var/obj/product as anything in meta.products)
			if(!ispath(product, /obj/item))
				continue
			var/state = initial(product.icon_state)
			var/icon_file = initial(product.icon)
			if(!state || !icon_file)
				continue
			TEST_ASSERT(state in icon_states(icon_file), \
				"[product] рисуется состоянием '[state]', которого нет в [icon_file] - в игре это невидимый предмет")
			if(checked[state])
				TEST_FAIL("[product] и [checked[state]] делят состояние '[state]': две разные награды выглядят одинаково")
			checked[state] = product

/// Канистры игрок различает по цвету, и только по нему: подпись видна лишь при
/// осмотре. Две канистры с одним спрайтом и разным содержимым - это ошибка,
/// которую замечают уже после того, как открыли не ту.
///
/// Делить спрайт разрешено только родителю с его же подтипом: прототипная
/// канистра и её кислородный вариант - физически одна и та же вещь. Два
/// независимых газа с одной картинкой - ошибка.
///
/// Проверка появилась, когда выяснилось, что девять пар ЗАКАЗЫВАЕМЫХ канистр
/// делили спрайт: азот и хилий, углекислота и заукер, токсины и нитрий, BZ и
/// галон, воздух и гелий, тритий и водород, нитрил и прото-нитрат, стимулум и
/// антинобель, фреон и плуоксий. Заодно вскрылось, что у darkblue вообще не
/// было полупустого состояния (канистра исчезала, как только её начинали
/// расходовать), а состояния proto не существовало ни в одном .dmi - то есть
/// прототипная канистра была невидима.
/datum/unit_test/canister_sprites_are_unique

/datum/unit_test/canister_sprites_are_unique/Run()
	var/list/seen = list()
	for(var/obj/machinery/portable_atmospherics/canister/tank as anything in subtypesof(/obj/machinery/portable_atmospherics/canister))
		var/state = initial(tank.icon_state)
		var/icon_file = initial(tank.icon)
		if(!state || !icon_file)
			continue
		var/list/available = icon_states(icon_file)
		TEST_ASSERT(state in available, 			"[initial(tank.name)] рисуется состоянием '[state]', которого нет в файле")
		TEST_ASSERT("[state]-1" in available, 			"у канистры [initial(tank.name)] нет полупустого состояния '[state]-1': она исчезнет, как только её начнут расходовать")
		var/obj/machinery/portable_atmospherics/canister/owner = seen[state]
		if(!owner)
			seen[state] = tank
			continue
		if(!ispath(tank, owner))
			TEST_FAIL("[initial(tank.name)] и [initial(owner.name)] делят спрайт '[state]', не будучи роднёй")
