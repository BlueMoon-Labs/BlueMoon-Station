/datum/unit_test/economy_market/proc/set_all_commodities(price_factor, hot_mult, demand)
	for(var/id in SSmarket.commodities)
		var/datum/commodity/commodity = SSmarket.commodities[id]
		commodity.price_factor = price_factor
		commodity.hot_mult = hot_mult
		commodity.demand = demand

/// Помечает предмет так же, как отгрузка помечает содержимое ящика, и выкладывает его на пол.
/datum/unit_test/economy_market/proc/import_item(obj/item/thing)
	var/obj/structure/closet/crate/crate = allocate(/obj/structure/closet/crate, thing.loc)
	thing.forceMove(crate)
	econ_mark_imported(crate)
	thing.forceMove(crate.loc)
	TEST_ASSERT(thing.econ_imported && !crate.econ_imported, "Метится содержимое ящика, а не сам ящик")
	qdel(crate)

/datum/unit_test/economy_market/proc/export_value(atom/movable/thing, dry_run = TRUE, apply_market = TRUE)
	var/datum/export_report/report = export_item_and_contents(thing, EXPORT_CARGO | EXPORT_CONTRABAND | EXPORT_EMAG, apply_elastic = apply_market, delete_unsold = FALSE, dry_run = dry_run)
	return econ_export_report_value(report)

/// Продажа металла идёт по фактору продажи товара «металлы», реальная продажа выбивает его спрос.
/datum/unit_test/economy_market/export_follows_market/Run()
	var/obj/item/stack/sheet/metal/sheets = allocate(/obj/item/stack/sheet/metal, run_loc_floor_bottom_left, 10)
	var/datum/export/metal_export
	for(var/datum/export/candidate as anything in GLOB.exports_list)
		if(candidate.applies_to(sheets, EXPORT_CARGO))
			metal_export = candidate
			break
	TEST_ASSERT_NOTNULL(metal_export, "Есть экспорт металла")
	TEST_ASSERT_EQUAL(metal_export.commodity, COMMODITY_METALS, "Экспорт металла привязан к металлам")
	var/datum/commodity/metals = SSmarket.get_commodity(COMMODITY_METALS)
	var/base = export_value(sheets)
	TEST_ASSERT(base > 0, "Металл продаётся")
	metals.price_factor = 2
	TEST_ASSERT(abs(export_value(sheets) - base * 2) <= 1, "Цена не удвоилась вслед за рынком: [export_value(sheets)] при [base]")
	TEST_ASSERT(abs(export_value(sheets, apply_market = FALSE) * econ_buyer_factor(COMMODITY_METALS) - base) <= 1, "Цена без рынка (пиратский выкуп) не зависит ни от рынка, ни от покупателя")
	metals.price_factor = 1
	metals.hot_mult = MARKET_HOT_MULT_MAX
	TEST_ASSERT(abs(export_value(sheets) - base * MARKET_HOT_MULT_MAX) <= 1, "Горячий металл не дороже в [MARKET_HOT_MULT_MAX] раза")
	metals.hot_mult = 1
	var/sold = export_value(sheets, dry_run = FALSE)
	TEST_ASSERT_EQUAL(sold, base, "Продано по текущей цене")
	TEST_ASSERT(abs(metals.demand - (1 - sold / metals.demand_capacity)) < 0.001, "Продажа на [sold] кр. не выбила спрос: [metals.demand]")
	var/obj/item/stack/sheet/metal/more_sheets = allocate(/obj/item/stack/sheet/metal, run_loc_floor_bottom_left, 10)
	metals.demand = 0
	TEST_ASSERT(abs(export_value(more_sheets) - base * MARKET_DEMAND_FLOOR) <= 1, "При выбитом спросе металл не дешевле в [1 / MARKET_DEMAND_FLOOR] раз")

/// Реагенты продаются по рынку химреактивов, медицинские - по рынку медикаментов.
/datum/unit_test/economy_market/reagents_follow_market/Run()
	var/obj/item/reagent_containers/glass/beaker/medicine_beaker = allocate(/obj/item/reagent_containers/glass/beaker)
	medicine_beaker.reagents.add_reagent(/datum/reagent/medicine/adminordrazine, 10)
	var/obj/item/reagent_containers/glass/beaker/chemical_beaker = allocate(/obj/item/reagent_containers/glass/beaker)
	chemical_beaker.reagents.add_reagent(/datum/reagent/hellwater, 10)
	var/medicine_base = export_value(medicine_beaker)
	var/chemical_base = export_value(chemical_beaker)
	TEST_ASSERT(medicine_base > 100 && chemical_base > 10, "Реагенты дешевле ожидаемого: [medicine_base], [chemical_base]")
	var/datum/commodity/chemicals = SSmarket.get_commodity(COMMODITY_CHEMICALS)
	chemicals.price_factor = 3
	TEST_ASSERT(abs(export_value(chemical_beaker) - chemical_base * 3) <= 2, "Химреактив не по рынку химреактивов: [export_value(chemical_beaker)] при [chemical_base]")
	TEST_ASSERT_EQUAL(export_value(medicine_beaker), medicine_base, "Медицинский реагент пошёл по рынку химреактивов")
	var/datum/commodity/medicine = SSmarket.get_commodity(COMMODITY_MEDICINE)
	medicine.price_factor = 2
	TEST_ASSERT(abs(export_value(medicine_beaker) - medicine_base * 2) <= 2, "Медицинский реагент не по рынку медикаментов: [export_value(medicine_beaker)] при [medicine_base]")

/// Купленное через снабжение NT выкупает не дороже нижней границы рынка, даже горячим.
/datum/unit_test/economy_market/imported_resale_capped/Run()
	var/obj/item/stack/sheet/metal/imported = allocate(/obj/item/stack/sheet/metal, run_loc_floor_bottom_left, 50)
	import_item(imported)
	var/obj/item/stack/sheet/metal/local = allocate(/obj/item/stack/sheet/metal, run_loc_floor_top_right, 50)
	set_all_commodities(1, MARKET_HOT_MULT_MAX, 1)
	var/base = export_value(local, apply_market = FALSE)
	var/buyer = econ_buyer_factor(COMMODITY_METALS)
	TEST_ASSERT(abs(export_value(local) - base * MARKET_HOT_MULT_MAX * buyer) <= 1, "Свой металл продаётся горячим лучшему покупателю")
	TEST_ASSERT(abs(export_value(imported) - base * econ_import_resale_factor()) <= 1, "Купленный металл продан по [export_value(imported)] вместо [base * econ_import_resale_factor()]")
	set_all_commodities(1, 1, 0)
	TEST_ASSERT(abs(export_value(imported) - base * MARKET_DEMAND_FLOOR * buyer) <= 1, "Выбитый спрос не снижает цену купленного")

/// Семена из снабжения не приносят ни премию за новый вид, ни за потенцию: NT их уже знает. Оценка сканером открытие не записывает.
/datum/unit_test/economy_market/imported_seed_no_discovery
	var/list/saved_discovered

/datum/unit_test/economy_market/imported_seed_no_discovery/New()
	. = ..()
	if(!length(GLOB.exports_list))
		setupExports()
	var/datum/export/seed/seed_export = locate() in GLOB.exports_list
	saved_discovered = seed_export.discoveredPlants.Copy()

/datum/unit_test/economy_market/imported_seed_no_discovery/Destroy()
	var/datum/export/seed/seed_export = locate() in GLOB.exports_list
	seed_export.discoveredPlants.Cut()
	for(var/plant in saved_discovered)
		seed_export.discoveredPlants[plant] = saved_discovered[plant]
	return ..()

/datum/unit_test/economy_market/imported_seed_no_discovery/Run()
	var/datum/export/seed/seed_export = locate() in GLOB.exports_list
	seed_export.discoveredPlants -= /obj/item/seeds/ambrosia/deus
	var/obj/item/seeds/ambrosia/deus/grown = allocate(/obj/item/seeds/ambrosia/deus)
	var/obj/item/seeds/ambrosia/deus/imported = allocate(/obj/item/seeds/ambrosia/deus)
	import_item(imported)
	TEST_ASSERT_EQUAL(export_value(imported), 0, "Купленный сорт оплачен как новый вид")
	TEST_ASSERT(export_value(grown) > 0, "Свой образец нового вида не оплачен")
	TEST_ASSERT(!(/obj/item/seeds/ambrosia/deus in seed_export.discoveredPlants), "Оценка без продажи записала открытие вида")
	TEST_ASSERT(export_value(grown, dry_run = FALSE) > 0, "Новый вид не продан")
	TEST_ASSERT(/obj/item/seeds/ambrosia/deus in seed_export.discoveredPlants, "Продажа не записала открытие вида")
	imported.potency = seed_export.discoveredPlants[/obj/item/seeds/ambrosia/deus] + 50
	TEST_ASSERT_EQUAL(export_value(imported), 0, "Купленный сорт оплачен за потенцию")
	var/obj/item/seeds/ambrosia/deus/improved = allocate(/obj/item/seeds/ambrosia/deus)
	improved.potency = imported.potency
	TEST_ASSERT(export_value(improved) > 0, "Свой улучшенный образец не оплачен")

/// Ящик из отгрузки - залог: не помечен, NT принимает его за полную цену при любом рынке.
/datum/unit_test/economy_market/packaging_is_deposit/Run()
	var/datum/supply_pack/pack = SSshuttle.supply_packs[/datum/supply_pack/materials/license50]
	var/datum/supply_order/order = new(pack, "Тест", "Тест", null, "Тест")
	var/obj/structure/closet/crate/crate = order.generate(run_loc_floor_bottom_left)
	qdel(order)
	allocated += crate
	var/list/generated = crate.GetAllContents()
	for(var/atom/movable/thing as anything in generated - crate)
		allocated += thing
		thing.forceMove(run_loc_floor_top_right)
	TEST_ASSERT(!crate.econ_imported && !islist(crate.econ_print_cap), "Ящик отгрузки помечен купленным или собранным")
	var/packaging = econ_packaging_value(pack.crate_type)
	TEST_ASSERT(packaging > 0, "Ящик пака ничего не стоит")
	set_all_commodities(MARKET_PRICE_MIN, MARKET_HOT_MULT_MAX, 0)
	TEST_ASSERT_EQUAL(export_value(crate), packaging, "Залог за ящик зависит от рынка")
	TEST_ASSERT_EQUAL(pack.get_cost(), round(packaging + (pack.cost * SSeconomy.pack_price_modifier - packaging) * MARKET_PRICE_MIN), "Цена пака на дне рынка - не залог плюс подешевевшее содержимое")

/// Ценник получает долю от рыночной выручки, а не от базовой цены: купленное и под ценником не дороже потолка выкупа.
/datum/unit_test/economy_market/pricetag_follows_market/Run()
	var/datum/bank_account/tag_owner = new("Тест ценника")
	allocated += tag_owner
	var/obj/item/stack/sheet/metal/local = allocate(/obj/item/stack/sheet/metal, run_loc_floor_bottom_left, 50)
	var/obj/item/stack/sheet/metal/imported = allocate(/obj/item/stack/sheet/metal, run_loc_floor_top_right, 50)
	import_item(imported)
	var/base = export_value(local, apply_market = FALSE)
	var/datum/commodity/metals = SSmarket.get_commodity(COMMODITY_METALS)
	metals.price_factor = 2
	local.AddComponent(/datum/component/pricetag, tag_owner, 0.5)
	var/before = tag_owner.account_balance
	var/cargo_share = export_value(local, dry_run = FALSE)
	var/tag_share = tag_owner.account_balance - before
	var/market_price = base * 2 * econ_buyer_factor(COMMODITY_METALS)
	TEST_ASSERT(abs(tag_share - market_price / 2) <= 1, "Ценник получил [tag_share] кр. вместо половины рыночной цены [market_price]")
	TEST_ASSERT(abs(cargo_share + tag_share - market_price) <= 2, "Вместе с ценником продано за [cargo_share + tag_share] вместо [market_price]")
	imported.AddComponent(/datum/component/pricetag, tag_owner, 0.5)
	before = tag_owner.account_balance
	var/imported_cargo = export_value(imported, dry_run = FALSE)
	var/imported_tag = tag_owner.account_balance - before
	TEST_ASSERT(imported_cargo + imported_tag <= round(base * econ_import_resale_factor()) + 1, "Купленное под ценником продано за [imported_cargo + imported_tag] при потолке [base * econ_import_resale_factor()]")

/// Цена пака следует фактору закупки его товара; паки ДС и Таркова от рынка не зависят.
/datum/unit_test/economy_market/pack_follows_market/Run()
	var/datum/supply_pack/medical_pack
	var/datum/supply_pack/faction_pack
	for(var/pack_id in SSshuttle.supply_packs)
		var/datum/supply_pack/candidate = SSshuttle.supply_packs[pack_id]
		if(!medical_pack && candidate.group == "Medical" && !candidate.commodity)
			medical_pack = candidate
		if(!faction_pack && candidate.group == "Deep Space")
			faction_pack = candidate
	TEST_ASSERT_NOTNULL(medical_pack, "Есть медицинский пак")
	TEST_ASSERT_NOTNULL(faction_pack, "Есть пак ДС")
	TEST_ASSERT_EQUAL(econ_pack_commodity(medical_pack), SSmarket.get_commodity(COMMODITY_MEDICINE), "Медицинский пак закупается по медикаментам")
	var/total = medical_pack.cost * SSeconomy.pack_price_modifier
	var/packaging = econ_packaging_value(medical_pack.crate_type)
	TEST_ASSERT(packaging > 0 && packaging < total, "Ящик медицинского пака стоит [packaging] кр. при цене пака [total]")
	var/faction_base = faction_pack.get_cost()
	TEST_ASSERT_EQUAL(medical_pack.market_cost(), round(total), "Цена пака при нейтральном рынке")
	set_all_commodities(1.5, MARKET_HOT_MULT_MAX, 1)
	TEST_ASSERT_EQUAL(medical_pack.market_cost(), round(packaging + (total - packaging) * 1.5), "Рынок двигает не только содержимое пака")
	TEST_ASSERT_EQUAL(faction_pack.get_cost(), faction_base, "Пак ДС подорожал с рынком")

/// Каждый товарный экспорт и каждый пак станции привязаны к товару рынка.
/datum/unit_test/economy_market/mapping_complete/Run()
	if(!length(GLOB.exports_list))
		setupExports()
	var/list/service_exports = typecacheof(list(
		/datum/export/manifest_correct,
		/datum/export/manifest_correct_denied,
		/datum/export/manifest_error,
		/datum/export/manifest_error_denied,
		/datum/export/pirate,
		/datum/export/large/crate,
	))
	var/list/unmapped = list()
	for(var/datum/export/export as anything in GLOB.exports_list)
		if(!is_type_in_typecache(export, service_exports) && !econ_export_commodity(export))
			unmapped += "[export.type]"
	TEST_ASSERT(!length(unmapped), "Экспорт без товара: [jointext(unmapped, ", ")]")
	var/list/unmapped_packs = list()
	for(var/pack_id in SSshuttle.supply_packs)
		var/datum/supply_pack/pack = SSshuttle.supply_packs[pack_id]
		if(pack.group in list("Deep Space", "Tarkov"))
			continue
		if(!econ_pack_commodity(pack))
			unmapped_packs += "[pack.type] ([pack.group])"
	TEST_ASSERT(!length(unmapped_packs), "Пак без товара: [jointext(unmapped_packs, ", ")]")

/// Индекс цен сектора - индекс рынка с поправкой на обвал; автоматы пересчитывают цены при сдвиге индекса больше порога.
/datum/unit_test/economy_market/vending_follow_index
	var/saved_surge

/datum/unit_test/economy_market/vending_follow_index/New()
	. = ..()
	saved_surge = SSeconomy.price_surge_mult

/datum/unit_test/economy_market/vending_follow_index/Destroy()
	SSeconomy.price_surge_mult = saved_surge
	return ..()

/datum/unit_test/economy_market/vending_follow_index/Run()
	SSeconomy.price_surge_mult = 2
	SSmarket.price_index = 1.2
	TEST_ASSERT(abs(SSeconomy.price_index() - 2.4) < 0.001, "Индекс сектора [SSeconomy.price_index()] вместо 2.4")
	SSeconomy.price_surge_mult = 1
	SSmarket.price_index = 1
	var/obj/machinery/vending/snack/machine = allocate(/obj/machinery/vending/snack)
	machine.refresh_prices()
	TEST_ASSERT(abs(machine.last_price_index - 1) < 0.001, "Автомат собран по индексу 1")
	rand_seed(1)
	SSmarket.hot_chance = 0
	for(var/id in SSmarket.commodities)
		var/datum/commodity/commodity = SSmarket.commodities[id]
		commodity.volatility = 0
		commodity.links = list()
		if(commodity.consumer)
			commodity.trend = 1.5
	SSmarket.market_shift()
	var/raised_index = SSeconomy.price_index()
	TEST_ASSERT(raised_index > 1 + MARKET_VENDING_REFRESH_SHARE, "Сдвиг поднял индекс только до [raised_index]")
	TEST_ASSERT(abs(machine.last_price_index - raised_index) < 0.001, "Автомат не пересчитал цены за сдвигом индекса: [machine.last_price_index]")
	TEST_ASSERT_EQUAL(machine.default_price, round(initial(machine.default_price) * raised_index), "Цена автомата не по новому индексу")
	var/target = raised_index * (1 + MARKET_VENDING_REFRESH_SHARE / 2 / MARKET_INDEX_SMOOTHING)
	for(var/id in SSmarket.commodities)
		var/datum/commodity/commodity = SSmarket.commodities[id]
		if(commodity.consumer)
			commodity.trend = 1 + (target - 1) / MARKET_TREND_REVERSION
	SSmarket.market_shift()
	var/small_index = SSeconomy.price_index()
	TEST_ASSERT(small_index > raised_index && (small_index - raised_index) / raised_index < MARKET_VENDING_REFRESH_SHARE, "Второй сдвиг вышел не малым: [raised_index] -> [small_index]")
	TEST_ASSERT(abs(machine.last_price_index - raised_index) < 0.001, "Автомат пересчитал цены за малым сдвигом индекса")

/// Энергия, контрабанда и руда в ORM оплачиваются по рынку своего товара.
/datum/unit_test/economy_market/hooks_follow_market/Run()
	econ_test_contraband_ready()
	var/obj/item/card/id/syndicate/agent_card = allocate(/obj/item/card/id/syndicate)
	var/base_card = econ_contraband_value(agent_card)
	TEST_ASSERT(base_card > 0, "Агентская карта оплачивается")
	TEST_ASSERT(isnull(GLOB.econ_contraband_market_price[agent_card.type]), "У агентской карты есть потолок чёрного рынка")
	var/datum/commodity/contraband = SSmarket.get_commodity(COMMODITY_CONTRABAND)
	contraband.price_factor = MARKET_PRICE_MIN
	TEST_ASSERT_EQUAL(econ_contraband_value(agent_card), round(base_card * MARKET_PRICE_MIN), "Изъятие не подешевело с рынком контрабанды")
	var/datum/commodity/energy = SSmarket.get_commodity(COMMODITY_ENERGY)
	energy.price_factor = 2
	var/datum/economy_department/engineering/engineering = SSeconomy.get_department(ACCOUNT_ENG)
	var/saved_pending = engineering.export_pending
	var/saved_due = engineering.export_payout_due
	engineering.export_pending = 0
	engineering.export_payout_due = world.time + 1 HOURS
	var/obj/machinery/power/export_node/node = allocate(/obj/machinery/power/export_node)
	node.accrue_power_export(10)
	var/pending = engineering.export_pending
	engineering.export_pending = saved_pending
	engineering.export_payout_due = saved_due
	TEST_ASSERT(abs(pending - 20) < 0.01, "Экспорт энергии не по рынку: [pending] кр. вместо 20")
	TEST_ASSERT(findtext(jointext(node.examine(allocate(/mob/living/carbon/human)), "\n"), "Цена по рынку энергии: [SSeconomy.settings.power_export_credits_per_mj * 2] кр."), "Осмотр узла называет цену по рынку")

#define IMPORT_FARM_SEED 4242
#define IMPORT_FARM_RANDOM_SAMPLES 20

/// Ни один пак не окупается в среднем перепродажей своего ящика, даже когда все товары горячие, а закупка на нижней границе рынка со скидкой высшей ступени у всех открытых партнёров.
/datum/unit_test/economy_market/no_import_farm
	var/list/saved_discovered
	var/datum/bank_account/tag_owner

/datum/unit_test/economy_market/no_import_farm/New()
	. = ..()
	if(!length(GLOB.exports_list))
		setupExports()
	var/datum/export/seed/seed_export = locate() in GLOB.exports_list
	saved_discovered = seed_export.discoveredPlants.Copy()

/datum/unit_test/economy_market/no_import_farm/Destroy()
	var/datum/export/seed/seed_export = locate() in GLOB.exports_list
	seed_export.discoveredPlants.Cut()
	for(var/plant in saved_discovered)
		seed_export.discoveredPlants[plant] = saved_discovered[plant]
	return ..()

/datum/unit_test/economy_market/no_import_farm/Run()
	rand_seed(IMPORT_FARM_SEED)
	var/datum/bank_account/buyer = new("Тест")
	allocated += buyer
	tag_owner = new("Тест ценника")
	allocated += tag_owner
	econ_test_partner_extremes()
	var/list/farms = list()
	for(var/pack_id in SSshuttle.supply_packs)
		var/datum/supply_pack/pack = SSshuttle.supply_packs[pack_id]
		if(pack.admin_spawned || (pack.special && !pack.special_enabled) || econ_test_explodes_on_delete(pack))
			continue
		var/list/buyers = list(null)
		if(pack.can_private_buy && pack.goody == PACK_GOODY_NONE)
			buyers += buyer
		for(var/datum/bank_account/paying_account as anything in buyers)
			set_all_commodities(MARKET_PRICE_MIN, MARKET_HOT_MULT_MAX, 1)
			var/price = pack.get_cost(paying_account)
			var/value = mean_resale(pack, paying_account, MARKET_PRICE_MIN, MARKET_HOT_MULT_MAX)
			if(value >= price)
				farms += "[pack.name] ([pack.type][paying_account ? ", частный заказ" : ""]): [value] кр. при цене [price]"
	TEST_ASSERT(!length(farms), "Перепродажа окупает закупку: [jointext(farms, "; ")]")

/// Средняя выручка перепродажи; пак, у которого две выборки разошлись, оценивается по IMPORT_FARM_RANDOM_SAMPLES выборкам.
/datum/unit_test/economy_market/no_import_farm/proc/mean_resale(datum/supply_pack/pack, datum/bank_account/paying_account, price_factor, hot_mult)
	var/list/samples = list()
	for(var/index in 1 to 2)
		set_all_commodities(price_factor, hot_mult, 1)
		samples += resale_value(pack, paying_account)
	if(samples[1] != samples[2])
		for(var/index in 3 to IMPORT_FARM_RANDOM_SAMPLES)
			set_all_commodities(price_factor, hot_mult, 1)
			samples += resale_value(pack, paying_account)
	. = 0
	for(var/value in samples)
		. += value / length(samples)

/// Упаковка как в отгрузке шаттла: малый пак в кейсе, частный заказ в именном ящике, остальное в ящике пака. Всё под ценником на половину выручки.
/datum/unit_test/economy_market/no_import_farm/proc/resale_value(datum/supply_pack/pack, datum/bank_account/paying_account)
	var/atom/movable/container
	if(pack.goody != PACK_GOODY_NONE)
		container = new /obj/item/storage/lockbox/order(run_loc_floor_bottom_left)
		for(var/item in pack.contains)
			new item(container)
	else
		container = pack.generate(run_loc_floor_bottom_left, paying_account)
	econ_mark_imported(container)
	var/list/generated = container.GetAllContents()
	for(var/obj/thing in generated)
		thing.AddComponent(/datum/component/pricetag, tag_owner, 0.5)
	var/tag_before = tag_owner.account_balance
	. = export_value(container, dry_run = FALSE) + tag_owner.account_balance - tag_before
	for(var/atom/movable/thing as anything in generated)
		if(!QDELETED(thing))
			qdel(thing)
	econ_test_clear_turf(run_loc_floor_bottom_left)

#undef IMPORT_FARM_SEED
#undef IMPORT_FARM_RANDOM_SAMPLES

/// Собранное в лейтах и мехфабе не окупает материалы: при обычном рынке продукта с лучшим покупателем и закупке листов на дне рынка со скидкой высшей ступени, а горячий товар продукта не поднимает отпечаток выше сырья. Стопки из лейта по базе не дороже своих материалов и по рынку не окупают их закупку.
/datum/unit_test/economy_market/no_print_farm/Run()
	econ_test_partner_extremes()
	set_all_commodities(MARKET_PRICE_MIN, 1, 1)
	var/list/material_prices = purchasable_material_prices()
	TEST_ASSERT(material_prices[SSmaterials.GetMaterialRef(/datum/material/iron)], "Железо не покупается паками")
	var/list/farms = list()
	var/list/hot_lifts = list()
	var/list/stack_farms = list()
	for(var/design_id in SSresearch.techweb_designs)
		var/datum/design/design = SSresearch.techweb_designs[design_id]
		if(!(design.build_type & (AUTOLATHE | PROTOLATHE | IMPRINTER | MECHFAB)) || !ispath(design.build_path, /obj/item))
			continue
		if(ispath(design.build_path, /obj/item/stack))
			var/obj/item/stack/unit = new design.build_path(run_loc_floor_bottom_left, 1)
			var/stack_value = export_value(unit, apply_market = FALSE)
			set_all_commodities(1, 1, 1)
			var/stack_market_value = export_value(unit)
			set_all_commodities(MARKET_PRICE_MIN, 1, 1)
			var/stack_materials_cost = design_cost(design, material_prices)
			var/list/unit_materials = econ_materials_value(design.materials)
			var/materials_value = 0
			for(var/commodity_id in unit_materials)
				materials_value += unit_materials[commodity_id]
			econ_test_clear_turf(run_loc_floor_bottom_left)
			if(stack_value > materials_value)
				stack_farms += "[design.name] ([design.build_path]): [stack_value] кр. против материалов на [round(materials_value, 0.1)] кр."
			if(!isnull(stack_materials_cost) && stack_market_value > stack_materials_cost)
				stack_farms += "[design.name] ([design.build_path]): по рынку [stack_market_value] кр. против закупки материалов на [round(stack_materials_cost, 0.1)] кр."
			continue
		var/obj/item/product = new design.build_path(run_loc_floor_bottom_left)
		econ_mark_station_made(product, design.materials)
		var/list/generated = product.GetAllContents()
		var/materials_cost = design_cost(design, material_prices)
		set_all_commodities(1, 1, 1)
		var/value = export_value(product)
		if(!isnull(materials_cost) && value > materials_cost)
			farms += "[design.name] ([design.build_path]): [value] кр. против материалов на [round(materials_cost, 0.1)] кр."
		set_all_commodities(1, MARKET_HOT_MULT_MAX, 1)
		var/cap_value = 0
		for(var/atom/movable/thing as anything in generated)
			for(var/commodity_id in thing.econ_print_cap)
				var/datum/commodity/material_commodity = SSmarket.get_commodity(commodity_id)
				material_commodity?.hot_mult = 1
		for(var/atom/movable/thing as anything in generated)
			if(islist(thing.econ_print_cap))
				cap_value += econ_cap_value(thing.econ_print_cap)
		var/hot_value = export_value(product)
		if(hot_value > cap_value)
			hot_lifts += "[design.name] ([design.build_path]): [hot_value] кр. при сырье [cap_value] кр."
		set_all_commodities(MARKET_PRICE_MIN, 1, 1)
		for(var/atom/movable/thing as anything in generated)
			if(!QDELETED(thing))
				qdel(thing)
		econ_test_clear_turf(run_loc_floor_bottom_left)
	TEST_ASSERT(!length(farms), "Печать окупает материалы: [jointext(farms, "; ")]")
	TEST_ASSERT(!length(hot_lifts), "Горячий товар поднял отпечаток выше сырья: [jointext(hot_lifts, "; ")]")
	TEST_ASSERT(!length(stack_farms), "Стопка из лейта дороже материалов: [jointext(stack_farms, "; ")]")

/// Лопата из автолейта продаётся не дороже металла, из которого напечатана.
/datum/unit_test/economy_market/autolathe_print_capped/Run()
	var/obj/machinery/autolathe/lathe = allocate(/obj/machinery/autolathe)
	var/datum/design/shovel_design = SSresearch.techweb_designs["shovel"]
	TEST_ASSERT_NOTNULL(shovel_design, "Есть дизайн лопаты")
	lathe.being_built = shovel_design
	lathe.make_item(0, list(), list(), 1, 1, FALSE, null)
	var/obj/item/shovel/shovel = locate() in lathe.drop_location()
	TEST_ASSERT_NOTNULL(shovel, "Автолейт напечатал лопату")
	allocated += shovel
	TEST_ASSERT(islist(shovel.econ_print_cap), "Лопата из автолейта не помечена собранной на станции")
	var/obj/item/shovel/found = allocate(/obj/item/shovel, run_loc_floor_top_right)
	var/cap = econ_cap_value(shovel.econ_print_cap)
	TEST_ASSERT(export_value(found) > cap, "Найденная лопата [export_value(found)] кр. не дороже металла [cap] кр.")
	TEST_ASSERT_EQUAL(export_value(shovel), cap, "Напечатанная лопата продана дороже металла")
	TEST_ASSERT(findtext(jointext(lathe.examine(allocate(/mob/living/carbon/human)), "\n"), econ_station_made_note()), "Осмотр автолейта не объясняет потолок")

/// Мехфаб выдаёт деталь с потолком по её материалам.
/datum/unit_test/economy_market/mechfab_print_capped/Run()
	var/datum/design/scanner_design
	for(var/design_id in SSresearch.techweb_designs)
		var/datum/design/design = SSresearch.techweb_designs[design_id]
		if((design.build_type & MECHFAB) && design.build_path == /obj/item/mecha_parts/mecha_equipment/mining_scanner)
			scanner_design = design
			break
	TEST_ASSERT_NOTNULL(scanner_design, "Есть дизайн шахтёрского сканера меха")
	var/turf/center = locate(run_loc_floor_bottom_left.x + 2, run_loc_floor_bottom_left.y + 2, run_loc_floor_bottom_left.z)
	var/obj/machinery/mecha_part_fabricator/fab = allocate(/obj/machinery/mecha_part_fabricator, center)
	TEST_ASSERT(fab.dispense_built_part(scanner_design), "Мехфаб не выдал деталь")
	var/obj/item/mecha_parts/mecha_equipment/mining_scanner/scanner = locate() in get_step(fab, fab.dir)
	TEST_ASSERT_NOTNULL(scanner, "Сканер не лежит у выхода")
	allocated += scanner
	TEST_ASSERT(islist(scanner.econ_print_cap), "Деталь мехфаба не помечена собранной на станции")
	TEST_ASSERT(export_value(scanner, apply_market = FALSE) > econ_cap_value(scanner.econ_print_cap), "Сканер по базе не дороже своих материалов")
	TEST_ASSERT_EQUAL(export_value(scanner), econ_cap_value(scanner.econ_print_cap), "Деталь мехфаба продана дороже материалов")

/// Крафтит по рецепту стопки через окно рецептов, как игрок, и возвращает результат на полу.
/datum/unit_test/economy_market/proc/craft(obj/item/stack/material, list/recipes, result_type, multiplier = 1)
	var/mob/living/carbon/human/crafter = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	crafter.put_in_active_hand(material)
	var/datum/stack_recipe/found_recipe
	for(var/entry in recipes)
		var/list/candidates = list(entry)
		if(istype(entry, /datum/stack_recipe_list))
			var/datum/stack_recipe_list/recipe_list = entry
			candidates = recipe_list.recipes
		for(var/datum/stack_recipe/recipe in candidates)
			if(recipe.result_type == result_type)
				found_recipe = recipe
	TEST_ASSERT_NOTNULL(found_recipe, "Нет рецепта [result_type]")
	var/list/before = list()
	for(var/atom/movable/thing in run_loc_floor_bottom_left)
		before += thing
	var/datum/tgui/window = allocate(/datum/tgui, crafter, material, "Stack")
	window.status = UI_INTERACTIVE
	usr = crafter
	material.ui_act("make", list("ref" = REF(found_recipe), "multiplier" = "[multiplier]"), window)
	usr = null
	var/deadline = world.time + found_recipe.time + 5 SECONDS
	while(world.time < deadline)
		for(var/atom/movable/thing in run_loc_floor_bottom_left)
			if(istype(thing, result_type) && (!(thing in before) || isstack(thing)))
				allocated += thing
				return thing
		sleep(world.tick_lag)

/// Ящик из купленного пласталя не помечен купленным, но стоит не дороже выкупа пласталя: пак пласталя не окупается ящиками даже на худшем рынке.
/datum/unit_test/economy_market/crafted_crate_capped/Run()
	var/obj/item/stack/sheet/plasteel/plasteel = allocate(/obj/item/stack/sheet/plasteel, run_loc_floor_bottom_left, 20)
	import_item(plasteel)
	var/list/materials = plasteel.mats_per_unit.Copy()
	var/obj/structure/closet/crate/crate = craft(plasteel, GLOB.plasteel_recipes, /obj/structure/closet/crate)
	TEST_ASSERT_NOTNULL(crate, "Ящик не скрафчен")
	TEST_ASSERT(!crate.econ_imported, "Скрафченный ящик помечен купленным")
	TEST_ASSERT(islist(crate.econ_print_cap), "Скрафченный ящик без потолка")
	var/full_value = 0
	for(var/material in materials)
		materials[material] *= 5
	var/list/base_values = econ_materials_value(materials)
	for(var/commodity_id in base_values)
		full_value += base_values[commodity_id]
	TEST_ASSERT(abs(econ_cap_value(crate.econ_print_cap) - full_value * econ_import_resale_factor()) <= 1, "Потолок ящика из купленного [econ_cap_value(crate.econ_print_cap)] кр. вместо выкупа [full_value * econ_import_resale_factor()]")
	var/datum/supply_pack/pack = SSshuttle.supply_packs[/datum/supply_pack/materials/plasteel20]
	var/datum/commodity/pack_commodity = econ_pack_commodity(pack)
	pack_commodity.price_factor = MARKET_PRICE_MIN
	var/datum/commodity/plasma = SSmarket.get_commodity(COMMODITY_PLASMA)
	plasma.price_factor = MARKET_PRICE_MAX
	plasma.hot_mult = MARKET_HOT_MULT_MAX
	TEST_ASSERT(pack_commodity != plasma, "Пак пласталя и плазма на одном товаре")
	var/crate_value = export_value(crate)
	TEST_ASSERT_EQUAL(crate_value, round(min(econ_packaging_value(crate.type), full_value * econ_import_resale_factor())), "Горячая плазма подняла ящик из купленного пласталя")
	TEST_ASSERT(crate_value * 4 < pack.get_cost(), "4 ящика по [crate_value] кр. окупают пак пласталя за [pack.get_cost()] кр.")

/// Стул из купленного металла - работа станции: контракт на кресла его принимает.
/datum/unit_test/economy_market/crafted_chair_contract/Run()
	var/obj/item/stack/sheet/metal/metal = allocate(/obj/item/stack/sheet/metal, run_loc_floor_bottom_left, 10)
	import_item(metal)
	var/obj/structure/chair/comfy/beige/chair = craft(metal, GLOB.metal_recipes, /obj/structure/chair/comfy/beige)
	TEST_ASSERT_NOTNULL(chair, "Кресло не скрафчено")
	TEST_ASSERT(!chair.econ_imported, "Кресло из купленного металла помечено купленным")
	var/datum/econ_contract/delivery/contract = new(ACCOUNT_SRV, new /datum/bounty/item/assistant/comfy_chair)
	allocated += contract
	TEST_ASSERT(contract.wants(chair), "Контракт на кресла не принимает кресло из купленного металла")

/// Прутья из купленного металла, слитые с кучей на полу, остаются купленными.
/datum/unit_test/economy_market/crafted_stack_keeps_import/Run()
	var/obj/item/stack/rods/pile = allocate(/obj/item/stack/rods, run_loc_floor_bottom_left, 10)
	var/obj/item/stack/sheet/metal/metal = allocate(/obj/item/stack/sheet/metal, run_loc_floor_top_right, 10)
	import_item(metal)
	metal.forceMove(run_loc_floor_bottom_left)
	TEST_ASSERT(!QDELETED(pile) && pile.amount == 10, "Куча прутьев слилась раньше крафта")
	craft(metal, GLOB.metal_recipes, /obj/item/stack/rods)
	var/obj/item/stack/rods/merged = locate() in run_loc_floor_bottom_left
	TEST_ASSERT(merged?.amount > 10, "Прутья не слились с кучей")
	TEST_ASSERT(merged.econ_imported, "Метка купленного потерялась при слиянии крафта")

/// Канистра из листов: газ продаётся по своему экспорту, потолок материалов только на корпус.
/datum/unit_test/economy_market/crafted_canister_gas/Run()
	var/obj/item/stack/sheet/metal/metal = allocate(/obj/item/stack/sheet/metal, run_loc_floor_bottom_left, 10)
	var/obj/machinery/portable_atmospherics/canister/canister = craft(metal, GLOB.metal_recipes, /obj/machinery/portable_atmospherics/canister)
	TEST_ASSERT_NOTNULL(canister, "Канистра не скрафчена")
	TEST_ASSERT(islist(canister.econ_print_cap), "Канистра без потолка")
	canister.air_contents.set_moles(GAS_PLUOXIUM, 100)
	var/datum/export/large/gas_canister/canister_export = locate() in GLOB.exports_list
	var/gas_part = canister_export.contents_cost(canister)
	TEST_ASSERT(gas_part > 100, "Газ в канистре стоит [gas_part] кр.")
	var/buyer = econ_buyer_factor(COMMODITY_GASES)
	var/expected = round(gas_part * buyer) + min(canister_export.init_cost * buyer, econ_cap_value(canister.econ_print_cap))
	TEST_ASSERT(abs(export_value(canister) - expected) <= 1, "Канистра с газом продана за [export_value(canister)] вместо газа и корпуса [expected]")

/// Ripley из деталей мехфаба стоит как поглощённые детали: конечности, плата и обшивка, а не как готовый мех.
/datum/unit_test/economy_market/mech_assembly_capped/Run()
	var/mob/living/carbon/human/builder = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/turf/center = locate(run_loc_floor_bottom_left.x + 2, run_loc_floor_bottom_left.y + 2, run_loc_floor_bottom_left.z)
	var/obj/machinery/mecha_part_fabricator/fab = allocate(/obj/machinery/mecha_part_fabricator, center)
	var/obj/item/mecha_parts/chassis/ripley/chassis = print_part(fab, /obj/item/mecha_parts/chassis/ripley)
	TEST_ASSERT(islist(chassis?.econ_print_cap), "Шасси из мехфаба без потолка")
	var/list/expected = chassis.econ_print_cap.Copy()
	for(var/limb_type in list(/obj/item/mecha_parts/part/ripley_torso, /obj/item/mecha_parts/part/ripley_left_arm, /obj/item/mecha_parts/part/ripley_right_arm, /obj/item/mecha_parts/part/ripley_left_leg, /obj/item/mecha_parts/part/ripley_right_leg))
		var/obj/item/limb = print_part(fab, limb_type)
		TEST_ASSERT(islist(limb?.econ_print_cap), "[limb_type] из мехфаба без потолка")
		for(var/commodity_id in limb.econ_print_cap)
			expected[commodity_id] += limb.econ_print_cap[commodity_id]
		builder.put_in_active_hand(limb)
		chassis.attackby(limb, builder)
	var/datum/component/construction/mecha/ripley/construction = chassis.GetComponent(/datum/component/construction/mecha/ripley)
	TEST_ASSERT_NOTNULL(construction, "Шасси не собрано из конечностей")
	var/obj/item/board = new construction.circuit_control(run_loc_floor_bottom_left)
	var/list/board_value = econ_value_list(board)
	for(var/commodity_id in board_value)
		expected[commodity_id] += board_value[commodity_id]
	TEST_ASSERT(run_step(construction, board, builder), "Плата управления не установлена")
	var/obj/item/stack/sheet/metal/plating = new construction.inner_plating(run_loc_floor_bottom_left, construction.inner_plating_amount * 2)
	var/list/plating_value = econ_value_list(plating)
	for(var/commodity_id in plating_value)
		expected[commodity_id] += plating_value[commodity_id] / 2
	TEST_ASSERT(run_step(construction, plating, builder), "Обшивка не установлена")
	var/turf/build_turf = get_turf(chassis)
	construction.spawn_result(builder)
	var/obj/vehicle/sealed/mecha/working/ripley/mech = locate() in build_turf
	TEST_ASSERT_NOTNULL(mech, "Мех не собран")
	allocated += mech
	var/parts_value = econ_cap_value(expected)
	TEST_ASSERT(abs(econ_cap_value(mech.econ_print_cap) - parts_value) <= 1, "Потолок меха [econ_cap_value(mech.econ_print_cap)] кр. вместо поглощённых деталей [parts_value] кр.")
	var/datum/export/large/mech/mech_export
	for(var/datum/export/export as anything in GLOB.exports_list)
		if(istype(export, /datum/export/large/mech) && export.applies_to(mech, EXPORT_CARGO))
			mech_export = export
			break
	TEST_ASSERT_NOTNULL(mech_export, "Нет экспорта Ripley")
	var/datum/export_report/report = new
	mech_export.sell_object(mech, report, TRUE, EXPORT_CARGO, TRUE)
	TEST_ASSERT(report.total_value[mech_export] <= parts_value, "Собранный мех продан за [report.total_value[mech_export]] при деталях [parts_value]")
	TEST_ASSERT(parts_value < mech_export.init_cost, "Детали Ripley [parts_value] кр. не дешевле готового меха [mech_export.init_cost] кр.")

/datum/unit_test/economy_market/mech_assembly_capped/proc/print_part(obj/machinery/mecha_part_fabricator/fab, part_type)
	for(var/design_id in SSresearch.techweb_designs)
		var/datum/design/design = SSresearch.techweb_designs[design_id]
		if(!(design.build_type & MECHFAB) || design.build_path != part_type)
			continue
		var/turf/exit = get_step(fab, fab.dir)
		var/list/before = list()
		for(var/atom/movable/thing in exit)
			before += thing
		if(!fab.dispense_built_part(design))
			return null
		for(var/obj/item/part in exit)
			if(istype(part, part_type) && !(part in before))
				allocated += part
				return part
	return null

/// Ставит шаг сборки на шаг с ключом этого предмета и выполняет его, как клик предметом.
/datum/unit_test/economy_market/mech_assembly_capped/proc/run_step(datum/component/construction/construction, obj/item/part, mob/living/carbon/human/builder)
	for(var/step_index in 1 to length(construction.steps))
		var/list/build_step = construction.steps[step_index]
		if(build_step["key"] == part.type)
			construction.index = step_index
			builder.put_in_active_hand(part)
			return construction.check_step(part, builder)
	return FALSE

/// Машина из рамы стоит как рама и плата, детали внутри продаются сами по себе.
/datum/unit_test/economy_market/frame_machine_capped/Run()
	var/obj/structure/frame/machine/frame = allocate(/obj/structure/frame/machine, run_loc_floor_bottom_left)
	var/obj/item/circuitboard/machine/emitter/board = new(frame)
	var/obj/item/stock_parts/micro_laser/laser = new(frame)
	var/obj/item/stock_parts/manipulator/manipulator = new(frame)
	var/circuit_value = export_value(board, apply_market = FALSE)
	var/parts_value = export_value(laser, apply_market = FALSE) + export_value(manipulator, apply_market = FALSE)
	var/frame_value = econ_cap_value(econ_materials_value(frame.custom_materials))
	frame.circuit = board
	frame.state = 3
	frame.req_components = list()
	var/obj/item/screwdriver/screwdriver = allocate(/obj/item/screwdriver)
	var/mob/living/carbon/human/builder = allocate(/mob/living/carbon/human)
	frame.attackby(screwdriver, builder)
	var/obj/machinery/power/emitter/built = locate() in run_loc_floor_bottom_left
	TEST_ASSERT_NOTNULL(built, "Эмиттер не собран")
	allocated += built
	var/obj/machinery/power/emitter/found = allocate(/obj/machinery/power/emitter, run_loc_floor_top_right)
	var/found_value = export_value(found)
	var/built_value = export_value(built)
	TEST_ASSERT(abs(built_value - (frame_value + circuit_value + parts_value)) <= 2, "Собранный эмиттер продан за [built_value] вместо рамы, платы и деталей [frame_value + circuit_value + parts_value]")
	TEST_ASSERT(built_value < found_value, "Собранный эмиттер [built_value] кр. не дешевле найденного [found_value] кр.")

/// Материал -> цена единицы по самому дешёвому паку с листами, без залога за упаковку.
/datum/unit_test/economy_market/no_print_farm/proc/purchasable_material_prices()
	. = list()
	for(var/pack_id in SSshuttle.supply_packs)
		var/datum/supply_pack/pack = SSshuttle.supply_packs[pack_id]
		if(pack.admin_spawned || (pack.special && !pack.special_enabled))
			continue
		var/has_stacks = FALSE
		for(var/item in pack.contains)
			if(ispath(item, /obj/item/stack))
				has_stacks = TRUE
				break
		if(!has_stacks)
			continue
		var/obj/structure/closet/crate/crate = pack.generate(run_loc_floor_bottom_left)
		var/list/generated = crate.GetAllContents()
		var/list/units = list()
		for(var/obj/item/stack/stack in generated)
			for(var/datum/material/material as anything in stack.custom_materials)
				units[material] += stack.custom_materials[material]
		for(var/atom/movable/thing as anything in generated)
			if(!QDELETED(thing))
				qdel(thing)
		econ_test_clear_turf(run_loc_floor_bottom_left)
		var/contents_price = pack.get_cost() - econ_packaging_value(pack.packaging_type())
		for(var/datum/material/material as anything in units)
			var/unit_price = contents_price / units[material]
			if(isnull(.[material]) || unit_price < .[material])
				.[material] = unit_price

/// Стоимость материалов дизайна или null, если какой-то материал паками не купить.
/datum/unit_test/economy_market/no_print_farm/proc/design_cost(datum/design/design, list/material_prices)
	. = 0
	for(var/key in design.materials)
		var/unit_price
		if(istext(key))
			for(var/datum/material/material as anything in material_prices)
				if(material.categories[key] && (isnull(unit_price) || material_prices[material] < unit_price))
					unit_price = material_prices[material]
		else
			unit_price = material_prices[key]
		if(isnull(unit_price))
			return null
		. += unit_price * design.materials[key]

/// Реагенты, с которыми предмет вышел из лейта, не продаются, а залитые потом - продаются по своей цене.
/datum/unit_test/economy_market/printed_reagents/Run()
	var/obj/item/reagent_containers/glass/beaker/beaker = allocate(/obj/item/reagent_containers/glass/beaker)
	beaker.reagents.add_reagent(/datum/reagent/hellwater, 10)
	econ_mark_station_made(beaker, null)
	TEST_ASSERT_EQUAL(reagents_value(beaker), 0, "Реагенты из лейта продаются")
	beaker.reagents.add_reagent(/datum/reagent/hellwater, 10)
	var/obj/item/reagent_containers/glass/beaker/own = allocate(/obj/item/reagent_containers/glass/beaker)
	own.reagents.add_reagent(/datum/reagent/hellwater, 10)
	TEST_ASSERT(reagents_value(own) > 0, "Свой реагент не продаётся")
	TEST_ASSERT_EQUAL(reagents_value(beaker), reagents_value(own), "Залитый после печати реагент продан не по цене")

/datum/unit_test/economy_market/printed_reagents/proc/reagents_value(obj/item/container)
	var/datum/export_report/report = export_item_and_contents(container, EXPORT_CARGO, delete_unsold = FALSE, dry_run = TRUE)
	. = 0
	for(var/reagent_name in report.reagents_value)
		. += report.reagents_value[reagent_name]

/// Газ и реагенты, перекачанные из купленного в своё, теряют метку: при обычном рынке и лучшем покупателе они вместе с выкупом опустевшей тары не окупают пак, купленный на дне рынка со скидкой высшей ступени.
/datum/unit_test/economy_market/no_liquid_farm/Run()
	econ_test_partner_extremes()
	var/list/farms = list()
	for(var/pack_id in SSshuttle.supply_packs)
		var/datum/supply_pack/pack = SSshuttle.supply_packs[pack_id]
		if(pack.admin_spawned || (pack.special && !pack.special_enabled) || econ_test_explodes_on_delete(pack))
			continue
		set_all_commodities(MARKET_PRICE_MIN, 1, 1)
		var/price = pack.get_cost()
		set_all_commodities(1, 1, 1)
		var/atom/movable/container
		if(pack.goody != PACK_GOODY_NONE)
			container = new /obj/item/storage/lockbox/order(run_loc_floor_bottom_left)
			for(var/item in pack.contains)
				new item(container)
		else
			container = pack.generate(run_loc_floor_bottom_left)
		econ_mark_imported(container)
		var/list/generated = container.GetAllContents()
		var/liquid = drain_liquids(generated)
		if(liquid)
			var/value = round(liquid) + export_value(container)
			if(value >= price)
				farms += "[pack.name] ([pack.type]): газ и реагенты [round(liquid)] кр. и тара при цене [price]"
		for(var/atom/movable/thing as anything in generated)
			if(!QDELETED(thing))
				qdel(thing)
		econ_test_clear_turf(run_loc_floor_bottom_left)
	TEST_ASSERT(!length(farms), "Перекачка из купленного окупает закупку: [jointext(farms, "; ")]")

/// Цена газа и реагентов без метки закупки у лучшего покупателя; тара после этого пустая.
/datum/unit_test/economy_market/no_liquid_farm/proc/drain_liquids(list/things)
	. = 0
	for(var/atom/movable/thing as anything in things)
		for(var/datum/export/export as anything in GLOB.exports_list)
			if(!export.applies_to(thing, EXPORT_CARGO | EXPORT_CONTRABAND | EXPORT_EMAG))
				continue
			var/contents = export.contents_cost(thing)
			if(contents > 0 && istype(thing, /obj/machinery/portable_atmospherics/canister))
				. += contents * econ_sale_factor(export.commodity) * econ_buyer_factor(export.commodity)
				var/obj/machinery/portable_atmospherics/canister/canister = thing
				canister.air_contents.clear()
			break
		if(!thing.reagents?.value_multiplier)
			continue
		for(var/datum/reagent/reagent as anything in thing.reagents.reagent_list)
			var/datum/commodity/market_commodity = econ_reagent_commodity(reagent)
			. += reagent.volume * reagent.value * thing.reagents.value_multiplier * market_commodity.sell_factor() * econ_buyer_factor(market_commodity.id)
		thing.reagents.clear_reagents()
