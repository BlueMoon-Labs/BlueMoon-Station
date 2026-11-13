/// Экспорт отдельных предметов и петли переработки купленного на свежем рынке из конфига репозитория.
/datum/unit_test/economy_exports
	abstract_type = /datum/unit_test/economy_exports
	var/list/saved_market

/datum/unit_test/economy_exports/New()
	..()
	saved_market = econ_test_swap_market()
	SSmarket.next_shift = world.time + 1 HOURS

/datum/unit_test/economy_exports/Destroy()
	econ_test_restore_market(saved_market)
	return ..()

/datum/unit_test/economy_exports/proc/set_all_commodities(price_factor)
	for(var/id in SSmarket.commodities)
		var/datum/commodity/commodity = SSmarket.commodities[id]
		commodity.price_factor = price_factor
		commodity.hot_mult = 1
		commodity.demand = 1

/datum/unit_test/economy_exports/proc/base_value(atom/movable/thing)
	return econ_export_report_value(export_item_and_contents(thing, EXPORT_CARGO, apply_elastic = FALSE, delete_unsold = FALSE, dry_run = TRUE))

/datum/unit_test/economy_exports/proc/sale_value(atom/movable/thing)
	return econ_export_report_value(export_item_and_contents(thing, EXPORT_CARGO, delete_unsold = FALSE, dry_run = TRUE))

/// Цена материалов предмета, если переработать его в листы и продать их лучшему покупателю на обычном рынке.
/datum/unit_test/economy_exports/proc/recycled_value(atom/movable/thing)
	. = 0
	for(var/datum/material/material as anything in thing.custom_materials)
		var/datum/export/export = econ_material_export(material)
		if(export)
			. += thing.custom_materials[material] / MINERAL_MATERIAL_AMOUNT * export.init_cost * econ_sale_factor(export.commodity) * econ_buyer_factor(export.commodity)

/// Каждая батарея продаётся по своему экспорту, слаймовая - не как обычная.
/datum/unit_test/economy_exports/cells/Run()
	var/list/expected = list(
		/obj/item/stock_parts/cell = 5,
		/obj/item/stock_parts/cell/upgraded = 10,
		/obj/item/stock_parts/cell/high = 15,
		/obj/item/stock_parts/cell/hyper = 20,
		/obj/item/stock_parts/cell/bluespace = 25,
		/obj/item/stock_parts/cell/high/slime = 200,
		/obj/item/stock_parts/cell/high/slime/hypercharged = 1200,
	)
	for(var/cell_type in expected)
		var/obj/item/stock_parts/cell/cell = allocate(cell_type)
		TEST_ASSERT_EQUAL(base_value(cell), expected[cell_type], "Цена [cell_type]")

/// Пластитан и стёкла-сплавы продаются по цене своих материалов, а не по одной плазме или за 0.
/datum/unit_test/economy_exports/alloy_sheets/Run()
	for(var/sheet_type in list(/obj/item/stack/sheet/mineral/plastitanium, /obj/item/stack/sheet/plasmaglass, /obj/item/stack/sheet/plasmarglass, /obj/item/stack/sheet/titaniumglass, /obj/item/stack/sheet/plastitaniumglass))
		var/obj/item/stack/sheet/sheets = allocate(sheet_type, run_loc_floor_bottom_left, 10)
		var/list/materials = econ_materials_value(sheets.custom_materials)
		var/materials_value = 0
		for(var/commodity_id in materials)
			materials_value += materials[commodity_id]
		TEST_ASSERT(materials_value > 0, "У [sheet_type] нет цены материалов")
		TEST_ASSERT(abs(base_value(sheets) - materials_value) <= 1, "[sheet_type]: [base_value(sheets)] кр. за 10 листов против материалов [materials_value]")

/// Пласталь из пака, перемолотая в утилизаторе на плазму и железо, не окупает пак, купленный на дне рынка со скидкой высшей ступени.
/datum/unit_test/economy_exports/plasteel_recycling/Run()
	econ_test_partner_extremes()
	set_all_commodities(MARKET_PRICE_MIN)
	var/datum/supply_pack/pack = SSshuttle.supply_packs[/datum/supply_pack/materials/plasteel20]
	var/contents_price = pack.get_cost() - econ_packaging_value(pack.packaging_type())
	set_all_commodities(1)
	var/obj/structure/closet/crate = pack.generate(run_loc_floor_bottom_left)
	allocated += crate
	econ_mark_imported(crate)
	var/obj/item/stack/sheet/plasteel/plasteel = locate() in crate
	TEST_ASSERT(plasteel?.econ_imported, "Пласталь из пака помечена купленной")
	var/obj/machinery/recycler/recycler = allocate(/obj/machinery/recycler, run_loc_floor_top_right)
	recycler.machine_stat = NONE
	recycler.safety_mode = FALSE
	recycler.amount_produced = 100
	plasteel.forceMove(recycler.loc)
	recycler.eat(plasteel)
	var/obj/item/stack/sheet/mineral/plasma/plasma = locate() in recycler.loc
	var/obj/item/stack/sheet/metal/iron = locate() in recycler.loc
	TEST_ASSERT(plasma && iron, "Утилизатор не выдал плазму и железо")
	allocated += plasma
	allocated += iron
	TEST_ASSERT(!plasma.econ_imported, "Плазма из переработки помечена купленной")
	var/revenue = sale_value(plasma) + sale_value(iron)
	TEST_ASSERT(revenue <= contents_price, "Плазма и железо из пласталя проданы за [revenue] кр. при цене пака [contents_price]")

/// Органы обезьяны из купленного кубика NT не покупает, свои органы - покупает; осмотр это объясняет.
/datum/unit_test/economy_exports/cube_organs/Run()
	var/datum/supply_pack/pack = SSshuttle.supply_packs[/datum/supply_pack/science/monkey]
	var/obj/structure/closet/crate = pack.generate(run_loc_floor_bottom_left)
	allocated += crate
	econ_mark_imported(crate)
	var/obj/item/reagent_containers/food/snacks/cube/monkey/cube = locate() in crate.GetAllContents()
	TEST_ASSERT_NOTNULL(cube, "В паке есть кубик")
	var/mob/living/carbon/human/viewer = allocate(/mob/living/carbon/human)
	TEST_ASSERT(findtext(jointext(cube.examine(viewer), "\n"), "NT не покупает"), "Осмотр кубика не предупреждает")
	cube.forceMove(run_loc_floor_top_right)
	var/datum/reagents/water = new(10)
	water.add_reagent(/datum/reagent/water, 10)
	water.reaction(cube, TOUCH)
	qdel(water)
	var/mob/living/carbon/monkey/monkey = locate() in run_loc_floor_top_right
	TEST_ASSERT_NOTNULL(monkey, "Кубик не вырос в обезьяну")
	allocated += monkey
	var/total = 0
	for(var/obj/item/organ/organ as anything in monkey.internal_organs.Copy())
		organ.Remove()
		organ.forceMove(run_loc_floor_top_right)
		allocated += organ
		total += sale_value(organ)
	TEST_ASSERT_EQUAL(total, 0, "Органы обезьяны из кубика проданы")
	var/obj/item/organ/heart/heart = locate() in run_loc_floor_top_right
	TEST_ASSERT(findtext(jointext(heart.examine(viewer), "\n"), "NT такие органы не покупает"), "Осмотр органа не объясняет")
	var/obj/item/organ/heart/own_heart = allocate(/obj/item/organ/heart, run_loc_floor_bottom_left)
	TEST_ASSERT(sale_value(own_heart) > 0, "Обычное сердце не продаётся")

/// Обезьяны с консоли ксенобиологии (ctrl-клик и кнопка кормления) - тоже из кубиков: их органы NT не покупает.
/datum/unit_test/economy_exports/xenobio_monkey_organs/Run()
	var/turf/open/spot = find_walkable_station_turf()
	TEST_ASSERT_NOTNULL(spot, "Есть станционный турф")
	allocate(/obj/machinery/camera, spot)
	var/obj/machinery/computer/camera_advanced/xenobio/console = allocate(/obj/machinery/computer/camera_advanced/xenobio, spot)
	var/mob/living/carbon/human/scientist = allocate(/mob/living/carbon/human, spot)
	var/mob/camera/aiEye/remote/xenobio/eye = allocate(/mob/camera/aiEye/remote/xenobio, spot)
	eye.origin = console
	scientist.remote_control = eye
	GLOB.cameranet.getCameraChunk(spot.x, spot.y, spot.z)
	TEST_ASSERT(GLOB.cameranet.checkTurfVis(spot), "Камера не видит турф консоли")
	console.monkeys = 2
	console.XenoTurfClickCtrl(scientist, spot)
	var/datum/action/innate/feed_slime/feed = new(console)
	feed.Grant(scientist)
	feed.Activate()
	qdel(feed)
	scientist.remote_control = null
	var/monkeys = 0
	for(var/mob/living/carbon/monkey/monkey in spot)
		allocated += monkey
		monkeys++
		for(var/obj/item/organ/organ as anything in monkey.internal_organs)
			TEST_ASSERT(organ.econ_cube_grown, "[organ] обезьяны с консоли не помечен выращенным из кубика")
		var/obj/item/organ/heart/heart = monkey.getorganslot(ORGAN_SLOT_HEART)
		heart.Remove()
		heart.forceMove(spot)
		allocated += heart
		TEST_ASSERT_EQUAL(sale_value(heart), 0, "Сердце обезьяны с консоли продано")
	TEST_ASSERT_EQUAL(monkeys, 2, "Консоль выпустила не двух обезьян")

/// Сколько ещё раз генерировать пак со случайным содержимым, чтобы сравнивать среднюю выручку
#define RECYCLE_SCAN_RANDOM_SAMPLES 18

/// Ни один пак не окупается, если купить его на дне рынка со скидкой высшей ступени, в том числе пятёркой со взломанной экспресс-консоли, и переработать всё содержимое в листы, продав их лучшему покупателю на обычном рынке, а то, что выгоднее сдать целиком, - сдать.
/datum/unit_test/economy_exports/no_recycle_farm/Run()
	econ_test_partner_extremes()
	var/datum/bank_account/buyer = new("Тест")
	allocated += buyer
	var/obj/machinery/computer/cargo/express/express = allocate(/obj/machinery/computer/cargo/express)
	express.contraband = TRUE
	var/list/farms = list()
	var/list/emag_farms = list()
	for(var/pack_id in SSshuttle.supply_packs)
		var/datum/supply_pack/pack = SSshuttle.supply_packs[pack_id]
		if(pack.admin_spawned || (pack.special && !pack.special_enabled) || econ_test_explodes_on_delete(pack))
			continue
		set_all_commodities(MARKET_PRICE_MIN)
		var/price = pack.get_cost() - econ_packaging_value(pack.packaging_type())
		var/emag_price = express.offers_pack(pack) ? express.emag_contents_price(pack, null) : null
		if(pack.can_private_buy && pack.goody == PACK_GOODY_NONE)
			price = min(price, pack.get_cost(buyer) - econ_packaging_value(pack.packaging_type(buyer)))
		set_all_commodities(1)
		var/list/samples = list(sample_revenue(pack), sample_revenue(pack))
		if(samples[1][1] != samples[2][1])
			for(var/extra in 1 to RECYCLE_SCAN_RANDOM_SAMPLES)
				samples += list(sample_revenue(pack))
		var/revenue = 0
		var/recycled = 0
		for(var/list/sample as anything in samples)
			revenue += sample[1] / length(samples)
			recycled += sample[2] / length(samples)
		if(recycled && revenue > price)
			farms += "[pack.name] ([pack.type]): [round(revenue)] кр. (переработка [round(recycled)], выборок [length(samples)]) при цене содержимого [price]"
		if(!isnull(emag_price) && revenue > emag_price)
			emag_farms += "[pack.name] ([pack.type]): [round(revenue)] кр. при цене содержимого во взломе [emag_price]"
	TEST_ASSERT(!length(farms), "Переработка купленного окупает пак: [jointext(farms, "; ")]")
	TEST_ASSERT(!length(emag_farms), "Выкуп купленного со взломанной экспресс-консоли окупает пак: [jointext(emag_farms, "; ")]")

/// list(выручка, из неё переработка) с одного сгенерированного пака: каждый предмет перерабатывается или сдаётся целиком, что выгоднее.
/datum/unit_test/economy_exports/no_recycle_farm/proc/sample_revenue(datum/supply_pack/pack)
	var/atom/movable/container
	if(pack.goody != PACK_GOODY_NONE)
		container = new /obj/item/storage/lockbox/order(run_loc_floor_bottom_left)
		for(var/item in pack.contains)
			new item(container)
	else
		container = pack.generate(run_loc_floor_bottom_left)
	econ_mark_imported(container)
	var/list/generated = container.GetAllContents() - container
	var/revenue = 0
	var/recycled = 0
	for(var/obj/item/thing in generated)
		var/material_value = recycled_value(thing)
		recycled += material_value
		revenue += max(material_value, own_value(thing))
	for(var/atom/movable/thing as anything in generated)
		if(!QDELETED(thing))
			qdel(thing)
	qdel(container)
	econ_test_clear_turf(run_loc_floor_bottom_left)
	return list(revenue, recycled)

/// Выкуп одного предмета без содержимого, как его продаст шаттл.
/datum/unit_test/economy_exports/no_recycle_farm/proc/own_value(obj/item/thing)
	for(var/datum/export/export as anything in GLOB.exports_list)
		if(export.applies_to(thing, EXPORT_CARGO | EXPORT_CONTRABAND | EXPORT_EMAG))
			. = round(export.get_cost(thing) * econ_export_sale_factor(export, thing))
			if(islist(thing.econ_print_cap))
				. = min(., econ_cap_value(thing.econ_print_cap))
			return
	return 0

#undef RECYCLE_SCAN_RANDOM_SAMPLES

/// Сканер Deep Space продаёт купленное через снабжение не дороже потолка выкупа NT.
/datum/unit_test/economy_exports/offstation_scanner_caps
	var/datum/bank_account/ds_budget
	var/saved_ds_balance

/datum/unit_test/economy_exports/offstation_scanner_caps/Destroy()
	if(ds_budget)
		econ_test_set_balance(ds_budget, saved_ds_balance)
	return ..()

/datum/unit_test/economy_exports/offstation_scanner_caps/Run()
	var/mob/living/carbon/human/scavenger = allocate(/mob/living/carbon/human)
	var/obj/item/xenoarch/help/cargo/ds/scanner = allocate(/obj/item/xenoarch/help/cargo/ds)
	scavenger.put_in_hands(scanner)
	var/obj/item/stack/sheet/metal/fifty/sheets = allocate(/obj/item/stack/sheet/metal/fifty)
	sheets.econ_imported = TRUE
	var/base = base_value(sheets)
	var/expected = round(base * min(1, econ_import_resale_factor()))
	TEST_ASSERT(expected > 0 && expected < base, "Потолок выкупа не ниже базовой цены: [expected] из [base]")
	ds_budget = SSeconomy.get_dep_account(ACCOUNT_DS)
	saved_ds_balance = ds_budget.account_balance
	var/before = ds_budget.account_balance
	scanner.afterattack(sheets, scavenger, TRUE)
	TEST_ASSERT(QDELETED(sheets), "Сканер не продал листы")
	TEST_ASSERT_EQUAL(ds_budget.account_balance - before, expected, "Сканер Deep Space выкупил купленное по полной цене")

/// Сканеры Deep Space и Таркова продают на общем рынке сектора: продажа съедает спрос, следующая партия дешевле.
/datum/unit_test/economy_exports/offstation_scanner_elastic
	var/datum/bank_account/budget
	var/saved_balance

/datum/unit_test/economy_exports/offstation_scanner_elastic/Destroy()
	if(budget)
		econ_test_set_balance(budget, saved_balance)
	return ..()

/datum/unit_test/economy_exports/offstation_scanner_elastic/Run()
	set_all_commodities(1)
	var/mob/living/carbon/human/scavenger = allocate(/mob/living/carbon/human)
	var/obj/item/xenoarch/help/cargo/tarkoff/scanner = allocate(/obj/item/xenoarch/help/cargo/tarkoff)
	budget = SSeconomy.get_dep_account(ACCOUNT_TAR)
	saved_balance = budget.account_balance
	var/list/payouts = list()
	for(var/sale in 1 to 2)
		var/obj/item/stack/sheet/mineral/diamond/diamonds = allocate(/obj/item/stack/sheet/mineral/diamond, null, 50)
		var/before = budget.account_balance
		var/expected = sale_value(diamonds)
		TEST_ASSERT_EQUAL(scanner.sell_offstation(diamonds, scavenger, ACCOUNT_TAR), expected, "Сканер продал не по цене рынка")
		TEST_ASSERT(QDELETED(diamonds), "Сканер не продал алмазы")
		payouts += budget.account_balance - before
	TEST_ASSERT(payouts[1] > 0, "Алмазы ничего не стоят")
	TEST_ASSERT(payouts[2] < payouts[1], "Вторая партия не подешевела: [payouts[2]] после [payouts[1]]")

/// Гост-роль аванпоста слышит, откуда доход бюджета, только если на её уровне есть экспресс-консоль этого бюджета.
/datum/unit_test/economy_exports/offstation_income_hint/Run()
	var/mob/living/carbon/human/scavenger = allocate(/mob/living/carbon/human)
	TEST_ASSERT(!econ_offstation_income_hint(scavenger, ACCOUNT_TAR), "Подсказка о бюджете Таркова без его консоли")
	allocate(/obj/machinery/computer/cargo/express/tar, run_loc_floor_top_right)
	TEST_ASSERT(econ_offstation_income_hint(scavenger, ACCOUNT_TAR), "Нет подсказки о бюджете Таркова рядом с его консолью")
	TEST_ASSERT(!econ_offstation_income_hint(scavenger, ACCOUNT_DS), "Подсказка о бюджете Deep Space у консоли Таркова")

/// Пиратский пад продаёт купленное через снабжение не дороже потолка выкупа NT.
/datum/unit_test/economy_exports/pirate_pad_caps/Run()
	var/obj/machinery/piratepad/pad = allocate(/obj/machinery/piratepad, run_loc_floor_top_right)
	pad.warmup_time = 0
	var/obj/machinery/computer/piratepad_control/terminal = allocate(/obj/machinery/computer/piratepad_control, run_loc_floor_bottom_left)
	terminal.pad_ref = WEAKREF(pad)
	var/obj/item/stack/sheet/metal/fifty/sheets = allocate(/obj/item/stack/sheet/metal/fifty, run_loc_floor_top_right)
	sheets.econ_imported = TRUE
	var/base = base_value(sheets)
	var/expected = round(base * min(1, econ_import_resale_factor()))
	TEST_ASSERT(expected > 0 && expected < base, "Потолок выкупа не ниже базовой цены: [expected] из [base]")
	var/mob/living/carbon/human/pirate = allocate(/mob/living/carbon/human)
	econ_ui_press(pirate, terminal, "CargoHoldTerminal", "send")
	TEST_ASSERT(QDELETED(sheets), "Пад не продал листы")
	TEST_ASSERT_EQUAL(terminal.points, expected, "Пиратский пад выкупил купленное по полной цене")
