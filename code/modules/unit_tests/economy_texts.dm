/datum/unit_test/economy_texts
	abstract_type = /datum/unit_test/economy_texts
	var/datum/economy_settings/saved_settings
	var/saved_tax_rate
	var/saved_pack_price_modifier

/datum/unit_test/economy_texts/New()
	. = ..()
	saved_settings = SSeconomy.settings
	saved_tax_rate = SSeconomy.tax_rate
	saved_pack_price_modifier = SSeconomy.pack_price_modifier
	SSeconomy.settings = new
	SSeconomy.settings.work_prices = saved_settings.work_prices.Copy()

/datum/unit_test/economy_texts/Destroy()
	if(saved_settings)
		SSeconomy.settings = saved_settings
		SSeconomy.tax_rate = saved_tax_rate
		SSeconomy.pack_price_modifier = saved_pack_price_modifier
	saved_settings = null
	return ..()

/// Памятка, накладная и справки снабжения берут числа из настроек: настройки сдвинуты - сдвинулся и текст.
/datum/unit_test/economy_texts/match_settings

/datum/unit_test/economy_texts/match_settings/Run()
	var/datum/economy_settings/settings = SSeconomy.settings
	settings.cargo_handling_fee += 5
	settings.tax_max += 5
	settings.wage_floor += 11
	settings.cleaning_cap_per_tick += 7
	settings.work_prices[WORK_MED_REVIVE] += 33
	var/mob/living/carbon/human/viewer = allocate(/mob/living/carbon/human)

	var/obj/item/paper/guides/economy/guide = allocate(/obj/item/paper/guides/economy)
	var/text = guide.get_info_text()
	var/datum/paper_input/written = LAZYACCESS(guide.raw_text_inputs, 1)
	TEST_ASSERT(written?.raw_text == text, "Памятка не записала свой текст на бумагу")
	TEST_ASSERT(findtext(text, "[settings.cargo_handling_fee]%"), "Сбор снабжения в памятке не из настроек")
	TEST_ASSERT(findtext(text, "[settings.tax_max]%"), "Потолок налога в памятке не из настроек")
	TEST_ASSERT(findtext(text, "[settings.wage_floor] кр."), "Минимум NT в памятке не из настроек")
	TEST_ASSERT(findtext(text, "[settings.work_prices[WORK_MED_REVIVE]] кр."), "Цена реанимации в памятке не из настроек")
	TEST_ASSERT(findtext(text, "не больше [settings.cleaning_cap_per_tick] плиток"), "Памятка не называет потолок уборки на уборщика")
	TEST_ASSERT(findtext(text, "в \"Кошельке\" - до [settings.transfer_max] кр."), "Памятка не называет потолок перевода из кошелька")
	TEST_ASSERT(findtext(text, "на кассе - до [min(REGISTER_PRICE_MAX, settings.transfer_max)] кр."), "Памятка не называет потолок чаевых на кассе")
	TEST_ASSERT(findtext(text, "[CRATE_TAX] кр."), "Памятка не называет сбор за малые кейсы")
	TEST_ASSERT(findtext(text, SSeconomy.audit_rights_text()), "Памятка не называет, кто ведёт аудит")

	var/obj/item/export_manifest/manifest = allocate(/obj/item/export_manifest)
	manifest.department_id = ACCOUNT_MED
	TEST_ASSERT(findtext(jointext(manifest.examine(viewer), " "), "[settings.cargo_handling_fee]%"), "Сбор снабжения в осмотре накладной не из настроек")
	var/cargo_help = econ_cargo_market_help()
	TEST_ASSERT(findtext(cargo_help, "даже в ящике снабжения"), "Справка снабжения не говорит, что накладная забирает выручку любого ящика")
	TEST_ASSERT(findtext(cargo_help, "[settings.cargo_handling_fee]%"), "Сбор снабжения в справке консоли не из настроек")
	TEST_ASSERT(findtext(cargo_help, "больше [GOODY_FREE_SHIPPING_MAX] за отгрузку") && findtext(cargo_help, "[CRATE_TAX] кр."), "Справка снабжения не объясняет бесплатную доставку малых кейсов и сбор")
	var/obj/machinery/computer/cargo/express/express = allocate(/obj/machinery/computer/cargo/express)
	var/list/express_static = express.ui_static_data(viewer)
	var/list/express_topics = express_static["help_topics"]
	TEST_ASSERT(length(express_topics) && express_topics[1]["title"] == "Экспресс-заказ", "Экспресс-консоль не объясняет, как списывает деньги")

	var/datum/outfit/job/hop/hop_outfit = allocate(/datum/outfit/job/hop)
	var/datum/outfit/job/quartermaster/qm_outfit = allocate(/datum/outfit/job/quartermaster)
	TEST_ASSERT(hop_outfit.backpack_contents[/obj/item/paper/guides/economy], "Памятки нет в наборе ГП")
	TEST_ASSERT(qm_outfit.backpack_contents[/obj/item/paper/guides/economy], "Памятки нет в наборе квартирмейстера")

/// Памятка помещается на бумагу и при шестизначных числах во всех настройках.
/datum/unit_test/economy_texts/guide_fits_paper

/datum/unit_test/economy_texts/guide_fits_paper/Run()
	var/datum/economy_settings/settings = SSeconomy.settings
	var/datum/bare = new
	for(var/key in settings.vars)
		if(key in bare.vars)
			continue
		var/value = settings.vars[key]
		if(isnum(value))
			settings.vars[key] = 999999
		else if(islist(value))
			var/list/numbers = value
			for(var/entry in numbers)
				numbers[entry] = 999999
	qdel(bare)
	SSeconomy.tax_rate = 999999
	var/obj/item/paper/guides/economy/guide = allocate(/obj/item/paper/guides/economy)
	var/length = length_char(guide.get_info_text())
	TEST_ASSERT(length <= MAX_PAPER_LENGTH, "Памятка длиной [length] не помещается на бумагу ([MAX_PAPER_LENGTH])")

/// Кратность пишется по-русски при любом множителе.
/datum/unit_test/economy_texts/times_text

/datum/unit_test/economy_texts/times_text/Run()
	TEST_ASSERT_EQUAL(econ_times_text(2), "в 2 раза", "Кратность 2")
	TEST_ASSERT_EQUAL(econ_times_text(5), "в 5 раз", "Кратность 5")
	TEST_ASSERT_EQUAL(econ_times_text(1.5), "в 1.5 раза", "Кратность 1.5")
	TEST_ASSERT_EQUAL(econ_times_text(22), "в 22 раза", "Кратность 22")

/// Осмотр сканера экспорта, узла экспорта, стенда оплаты и торгового автомата объясняет механику числами из настроек.
/datum/unit_test/economy_texts/examine

/datum/unit_test/economy_texts/examine/Run()
	var/mob/living/carbon/human/viewer = allocate(/mob/living/carbon/human)
	SSeconomy.pack_price_modifier = 0.5
	var/obj/item/export_scanner/scanner = allocate(/obj/item/export_scanner)
	TEST_ASSERT(findtext(jointext(scanner.examine(viewer), " "), "не дороже [round(econ_import_resale_factor() * 100)]%"), "Осмотр сканера не называет потолок выкупа купленного")
	SSeconomy.pack_price_modifier = saved_pack_price_modifier

	var/obj/machinery/power/export_node/node = allocate(/obj/machinery/power/export_node)
	node.active = TRUE
	node.target_kw = SSeconomy.settings.power_export_step_kw
	node.overloaded = TRUE
	node.last_export_w = 0
	var/node_text = jointext(node.examine(viewer), " ")
	TEST_ASSERT(findtext(node_text, "ничего не продаёт"), "Осмотр перегруженного узла не говорит, что продажа стоит")
	TEST_ASSERT(findtext(node_text, "всю заданную мощность"), "Осмотр перегруженного узла не говорит, что отбор идёт целиком")

	var/obj/machinery/paystand/stand = allocate(/obj/machinery/paystand)
	TEST_ASSERT(findtext(jointext(stand.examine(viewer), " "), "на личный счёт владельца стенда, без налога"), "Осмотр стенда оплаты не говорит, куда уходят деньги")

	var/datum/economy_settings/settings = SSeconomy.settings
	settings.vend_wholesale_share += 5
	var/obj/machinery/vending/snack/vendor = allocate(/obj/machinery/vending/snack)
	vendor.onstation = TRUE
	var/vend_text = jointext(vendor.examine(viewer), " ")
	var/datum/bank_account/owner = SSeconomy.get_dep_account(vendor.payment_department)
	TEST_ASSERT(findtext(vend_text, "[settings.vend_wholesale_share]%"), "Осмотр автомата не называет оптовую долю из настроек")
	TEST_ASSERT(findtext(vend_text, "[100 - settings.vend_wholesale_share]%"), "Осмотр автомата не называет долю отдела")
	TEST_ASSERT(owner && findtext(vend_text, econ_budget_name(owner)), "Осмотр автомата не называет бюджет-владельца")
	TEST_ASSERT_EQUAL(econ_budget_name(SSeconomy.get_dep_account(ACCOUNT_CAR)), "бюджет снабжения", "Бюджет снабжения назван по-русски")
	TEST_ASSERT(findtext(vend_text, "индекс"), "Осмотр автомата не объясняет индекс цен")
