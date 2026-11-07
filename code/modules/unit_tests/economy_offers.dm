/// Спецзаказы на свежих партнёрах из конфига репозитория; рынок, контракты, бюджеты и сообщение ЦК возвращаются.
/datum/unit_test/economy_offers
	abstract_type = /datum/unit_test/economy_offers
	var/list/saved_market
	var/list/stashed_contracts
	var/saved_centcom_message
	var/saved_export_categories
	var/datum/bank_account/department/cargo
	var/saved_cargo
	var/datum/economy_department/medical
	var/saved_medical
	/// list(offer, success) на каждый COMSIG_MARKET_OFFER_RESOLVED
	var/list/resolved = list()

/datum/unit_test/economy_offers/New()
	..()
	saved_market = econ_test_swap_market()
	SSmarket.next_shift = world.time + 1 HOURS
	SSmarket.next_restock = world.time + 1 HOURS
	SSmarket.next_offers = world.time + 1 HOURS
	stashed_contracts = econ_test_stash_contracts()
	saved_centcom_message = SSshuttle.centcom_message
	saved_export_categories = SSshuttle.supply.export_categories
	cargo = SSeconomy.get_dep_account(ACCOUNT_CAR)
	saved_cargo = cargo.account_balance
	medical = SSeconomy.get_department(ACCOUNT_MED)
	saved_medical = medical.account.account_balance
	RegisterSignal(SSmarket, COMSIG_MARKET_OFFER_RESOLVED, PROC_REF(on_resolved))

/datum/unit_test/economy_offers/Destroy()
	UnregisterSignal(SSmarket, COMSIG_MARKET_OFFER_RESOLVED)
	SSshuttle.centcom_message = saved_centcom_message
	SSshuttle.supply.export_categories = saved_export_categories
	econ_test_restore_contracts(stashed_contracts)
	econ_test_set_balance(cargo, saved_cargo)
	econ_test_set_balance(medical.account, saved_medical)
	cargo = null
	medical = null
	econ_test_restore_market(saved_market)
	return ..()

/datum/unit_test/economy_offers/proc/on_resolved(datum/source, datum/market_offer/offer, success)
	SIGNAL_HANDLER
	resolved += list(list(offer, success))

/datum/unit_test/economy_offers/proc/add_offer(partner_id, wanted_type, quantity, multiplier, unit_price, reagent, volume)
	var/datum/trade_partner/partner = SSmarket.get_partner(partner_id)
	var/datum/market_offer/offer = new(partner_id, wanted_type, "тест", quantity, multiplier, unit_price, reagent, volume)
	partner.offers += offer
	return offer

/datum/unit_test/economy_offers/proc/shuttle_floor()
	for(var/area/shuttle/shuttle_area as anything in SSshuttle.supply.shuttle_areas)
		for(var/turf/open/floor in shuttle_area)
			if(!floor.is_blocked_turf())
				return floor

/datum/unit_test/economy_offers/proc/shuttle_crate()
	var/turf/open/floor = shuttle_floor()
	TEST_ASSERT_NOTNULL(floor, "Есть пол шаттла снабжения")
	return allocate(/obj/structure/closet/crate, floor)

/datum/unit_test/economy_offers/proc/make_technician(turf/where)
	var/mob/living/carbon/human/technician = allocate(/mob/living/carbon/human, where)
	var/datum/bank_account/account = new("econ_test_offer_technician")
	account.department_id = ACCOUNT_CAR
	technician.account_id = account.account_id
	allocated += account
	return technician

/// Окно консоли снабжения для act от лица user; uid - то, что консоль отдала в ui_data.
/datum/unit_test/economy_offers/proc/console_act(obj/machinery/computer/cargo/console, mob/living/carbon/human/user, action, uid)
	var/datum/tgui/window = allocate(/datum/tgui, user, console, "Cargo")
	window.status = UI_INTERACTIVE
	usr = user
	. = console.ui_act(action, list("uid" = uid), window)
	usr = null

/datum/unit_test/economy_offers/proc/sale_value(atom/movable/thing)
	return econ_export_report_value(export_item_and_contents(thing, EXPORT_CARGO, delete_unsold = FALSE, dry_run = TRUE))

/// Взятый в станционной консоли спецзаказ выполняется отгрузкой ящика с его накладной: за штуку база при отгрузке, маржа снабжению при выполнении, лишнее продано обычным порядком, партнёру репутация.
/datum/unit_test/economy_offers/fulfilled/Run()
	var/datum/trade_partner/prospectors = SSmarket.get_partner("prospectors")
	var/datum/market_offer/offer = add_offer("prospectors", /obj/item/stack/sheet/mineral/plasma, 10, 2, 100)
	var/turf/station_turf = find_walkable_station_turf()
	TEST_ASSERT_NOTNULL(station_turf, "Есть станционный турф")
	var/obj/machinery/computer/cargo/console = allocate(/obj/machinery/computer/cargo, station_turf)
	var/obj/machinery/computer/cargo/other_console = allocate(/obj/machinery/computer/cargo, station_turf)
	var/mob/living/carbon/human/technician = make_technician(station_turf)
	var/list/entries = console.ui_data(technician)["special_offers"]
	TEST_ASSERT_EQUAL(length(entries), 1, "Спецзаказ в данных консоли")
	TEST_ASSERT_EQUAL(entries[1]["reward"], 2000, "Награда в данных консоли")
	TEST_ASSERT_EQUAL(entries[1]["premium"], 1000, "Маржа в данных консоли")
	var/uid = entries[1]["uid"]
	TEST_ASSERT(isnum(uid), "uid в данных консоли - число")
	console_act(console, technician, "print_offer_manifest", uid)
	TEST_ASSERT(!(locate(/obj/item/export_manifest) in technician.held_items), "Накладная невзятого спецзаказа напечатана")
	console_act(console, technician, "accept_offer", uid)
	TEST_ASSERT(offer.accepted, "Спецзаказ не взят")
	TEST_ASSERT(abs(offer.deadline - (world.time + SSmarket.offer_deadline_minutes MINUTES)) < 1, "Срок от взятия")
	console_act(console, technician, "print_offer_manifest", "[uid]")
	var/obj/item/export_manifest/manifest = locate() in technician.held_items
	TEST_ASSERT_NOTNULL(manifest, "Накладная спецзаказа не в руках")
	TEST_ASSERT_EQUAL(manifest.special_offer_id, offer.uid, "Накладная привязана к спецзаказу")
	technician.dropItemToGround(manifest)
	console_act(other_console, technician, "print_offer_manifest", uid)
	TEST_ASSERT(!(locate(/obj/item/export_manifest) in technician.held_items), "Кулдаун печати не на счёте сотрудника")
	TEST_ASSERT(findtext(jointext(manifest.examine(technician), "\n"), "принято 0 из 10, 100 кр. за штуку при отгрузке и 100 кр. за штуку маржи"), "Осмотр накладной не описывает спецзаказ")
	var/obj/structure/closet/crate/crate = shuttle_crate()
	var/obj/item/stack/sheet/mineral/plasma/extra = allocate(/obj/item/stack/sheet/mineral/plasma, run_loc_floor_bottom_left, 5)
	var/extra_value = sale_value(extra)
	TEST_ASSERT(extra_value > 0, "Плазма продаётся")
	qdel(extra)
	new /obj/item/stack/sheet/mineral/plasma(crate, 15)
	manifest.forceMove(crate)
	var/cargo_before = cargo.account_balance
	var/reputation_before = prospectors.reputation
	SSshuttle.supply.sell()
	TEST_ASSERT(QDELETED(offer), "Спецзаказ не закрыт")
	TEST_ASSERT(length(resolved) == 1 && resolved[1][1] == offer && resolved[1][2], "Нет сигнала выполнения")
	var/gain = cargo.account_balance - cargo_before
	var/deposit = econ_packaging_value(/obj/structure/closet/crate)
	TEST_ASSERT(abs(gain - (2000 + extra_value + deposit)) <= 1, "Карго получило [gain] вместо 2000 за спецзаказ, [extra_value] за лишнее и [deposit] за ящик")
	TEST_ASSERT(prospectors.reputation >= reputation_before + MARKET_OFFER_REPUTATION_SUCCESS, "Репутация за выполнение: [prospectors.reputation - reputation_before]")
	TEST_ASSERT(findtext(SSshuttle.centcom_message, "принято 10 шт. «тест» (10 из 10), 1000 кр.") && findtext(SSshuttle.centcom_message, "маржа снабжению 1000 кр."), "Сообщение ЦК не описывает спецзаказ: [SSshuttle.centcom_message]")
	TEST_ASSERT(findtext(SSshuttle.centcom_message, "Выручка: [gain] кр."), "Выручка в сообщении ЦК не сходится: [SSshuttle.centcom_message]")

/// Купленное через снабжение не засчитывается и продаётся по потолку выкупа; частичная поставка платит базу, маржа - при выполнении; напечатанное оплачивается по потолку материалов.
/datum/unit_test/economy_offers/imported_and_printed/Run()
	var/datum/market_offer/metal_offer = add_offer("nt_logistics", /obj/item/stack/sheet/metal, 20, 2, 5)
	TEST_ASSERT(metal_offer.accept(), "Спецзаказ на металл взят")
	var/obj/structure/closet/crate/crate = shuttle_crate()
	var/obj/item/storage/box/box = new(crate)
	var/obj/item/stack/sheet/metal/imported = new(box, 10)
	econ_mark_imported(crate)
	TEST_ASSERT(imported.econ_imported, "Металл помечен купленным")
	var/imported_value = sale_value(box)
	new /obj/item/stack/sheet/metal(crate, 15)
	print_offer_manifest(metal_offer, crate)
	var/cargo_before = cargo.account_balance
	SSshuttle.supply.sell()
	TEST_ASSERT_EQUAL(metal_offer.delivered, 15, "Засчитано не своё или не всё своё")
	TEST_ASSERT(!QDELETED(metal_offer), "Неполная поставка закрыла спецзаказ")
	var/deposit = econ_packaging_value(/obj/structure/closet/crate)
	var/gain = cargo.account_balance - cargo_before
	TEST_ASSERT(abs(gain - (15 * 5 + imported_value + deposit)) <= 1, "Карго получило [gain]: база спецзаказа 75, коробка купленного металла по выкупу [imported_value], ящик [deposit]")
	TEST_ASSERT(findtext(SSshuttle.centcom_message, "(15 из 20)"), "Сообщение ЦК о частичной поставке: [SSshuttle.centcom_message]")
	crate = shuttle_crate()
	new /obj/item/stack/sheet/metal(crate, 10)
	print_offer_manifest(metal_offer, crate)
	cargo_before = cargo.account_balance
	SSshuttle.supply.sell()
	TEST_ASSERT(QDELETED(metal_offer), "Остаток поставки не закрыл спецзаказ")
	var/rest_value = cargo.account_balance - cargo_before - 5 * 5 - 20 * 5 - deposit
	TEST_ASSERT(rest_value >= 0, "Маржа за весь спецзаказ не выплачена при выполнении: [cargo.account_balance - cargo_before]")
	var/datum/market_offer/shovel_offer = add_offer("nt_logistics", /obj/item/shovel, 2, 2, 50)
	shovel_offer.accept()
	var/obj/machinery/autolathe/lathe = allocate(/obj/machinery/autolathe)
	lathe.being_built = SSresearch.techweb_designs["shovel"]
	lathe.make_item(0, list(), list(), 1, 1, FALSE, null)
	var/obj/item/shovel/printed = locate() in lathe.drop_location()
	TEST_ASSERT_NOTNULL(printed, "Автолейт напечатал лопату")
	var/cap = econ_cap_value(printed.econ_print_cap)
	TEST_ASSERT(cap < 100, "Потолок лопаты [cap] не ниже награды")
	crate = shuttle_crate()
	printed.forceMove(crate)
	new /obj/item/shovel(crate)
	print_offer_manifest(shovel_offer, crate)
	cargo_before = cargo.account_balance
	SSshuttle.supply.sell()
	TEST_ASSERT(QDELETED(shovel_offer), "Лопаты не закрыли спецзаказ")
	TEST_ASSERT_EQUAL(cargo.account_balance - cargo_before, 100 + cap + deposit, "Напечатанная лопата оплачена выше материалов")

/// В спецзаказ идёт только точный тип: с реагентом - где реагента не меньше нужного, подтип не годится.
/datum/unit_test/economy_offers/exact_match/Run()
	var/datum/market_offer/offer = add_offer("vey_med", /obj/item/reagent_containers/pill, 3, 2, 40, /datum/reagent/medicine/bicaridine, 10)
	offer.accept()
	var/obj/structure/closet/crate/crate = shuttle_crate()
	var/obj/item/reagent_containers/pill/full = new(crate)
	full.reagents.add_reagent(/datum/reagent/medicine/bicaridine, 15)
	var/obj/item/reagent_containers/pill/weak = new(crate)
	weak.reagents.add_reagent(/datum/reagent/medicine/bicaridine, 5)
	var/obj/item/reagent_containers/pill/other = new(crate)
	other.reagents.add_reagent(/datum/reagent/medicine/kelotane, 15)
	var/obj/item/reagent_containers/pill/patch/patch = new(crate)
	patch.reagents.add_reagent(/datum/reagent/medicine/bicaridine, 15)
	print_offer_manifest(offer, crate)
	SSshuttle.supply.sell()
	TEST_ASSERT_EQUAL(offer.delivered, 1, "Засчитано таблеток")
	TEST_ASSERT_EQUAL(offer.paid, 40, "База за таблетку")
	TEST_ASSERT_EQUAL(offer.premium_due, 40, "Маржа за таблетку копится до выполнения")
	TEST_ASSERT(findtext(offer.manifest_text(), "не меньше 10 ед."), "Накладная не называет объём реагента")
	var/datum/market_offer/pizza_offer = add_offer("prospectors", /obj/item/reagent_containers/food/snacks/pizza/margherita, 2, 2, 100)
	pizza_offer.accept()
	crate = shuttle_crate()
	new /obj/item/reagent_containers/food/snacks/pizza/margherita/robo(crate)
	print_offer_manifest(pizza_offer, crate)
	SSshuttle.supply.sell()
	TEST_ASSERT_EQUAL(pizza_offer.delivered, 0, "Подтип засчитан как точный тип")

/// С накладной отдела в том же ящике база спецзаказа делится, как выручка ящика, а маржа уходит снабжению; товар без покупателя спецзаказ забирает, остальное возвращается.
/datum/unit_test/economy_offers/department_and_embargo/Run()
	for(var/id in SSmarket.partners)
		var/datum/trade_partner/partner = SSmarket.partners[id]
		partner.buys -= COMMODITY_METALS
		partner.buys -= PARTNER_ANY
	var/datum/market_offer/offer = add_offer("prospectors", /obj/item/stack/sheet/metal, 5, 2, 10)
	offer.accept()
	var/obj/structure/closet/crate/crate = shuttle_crate()
	var/obj/item/stack/sheet/metal/sheets = new(crate, 8)
	allocated += sheets
	print_offer_manifest(offer, crate)
	medical.print_manifest(crate)
	var/cargo_before = cargo.account_balance
	var/medical_before = medical.account.account_balance
	SSshuttle.supply.sell()
	TEST_ASSERT(QDELETED(offer), "Спецзаказ не выполнен")
	var/fee = round(50 * SSeconomy.settings.cargo_handling_fee / 100)
	var/deposit = econ_packaging_value(/obj/structure/closet/crate)
	var/deposit_fee = round(deposit * SSeconomy.settings.cargo_handling_fee / 100)
	var/medical_share = 50 - fee + deposit - deposit_fee
	TEST_ASSERT_EQUAL(medical.account.account_balance - medical_before, medical_share, "Доля отдела от базы спецзаказа и ящика")
	TEST_ASSERT_EQUAL(cargo.account_balance - cargo_before, fee + deposit_fee + 50, "Карго получило сборы и маржу")
	TEST_ASSERT(!QDELETED(sheets) && sheets.amount == 3 && isturf(sheets.loc), "Непроданный остаток металла не вернулся на шаттл")
	TEST_ASSERT(findtext(SSshuttle.centcom_message, "Не нашлось покупателя: 1 шт. возвращено."), "Сообщение ЦК о возвращённом: [SSshuttle.centcom_message]")
	TEST_ASSERT(findtext(SSshuttle.centcom_message, "[medical.name] - [medical_share] кр."), "Сообщение ЦК о доле отдела: [SSshuttle.centcom_message]")

/// Спецзаказ контрабандного партнёра принимает только отгрузка с допуском контрабанды; в ящике учитывается один спецзаказ.
/datum/unit_test/economy_offers/contraband_and_second_manifest/Run()
	var/datum/trade_partner/free_traders = SSmarket.get_partner("free_traders")
	free_traders.unlocked = TRUE
	var/datum/market_offer/offer = add_offer("free_traders", /obj/item/stack/sheet/bone, 5, 2, 20)
	offer.accept()
	var/datum/market_offer/second = add_offer("vey_med", /obj/item/stack/sheet/bone, 5, 2, 20)
	second.accept()
	SSshuttle.supply.export_categories = EXPORT_CARGO
	var/obj/structure/closet/crate/crate = shuttle_crate()
	new /obj/item/stack/sheet/bone(crate, 5)
	print_offer_manifest(offer, crate)
	SSshuttle.supply.sell()
	TEST_ASSERT_EQUAL(offer.delivered, 0, "Контрабандный спецзаказ принят без допуска")
	TEST_ASSERT(findtext(econ_cargo_message("", TRUE), "только отгрузка с допуском контрабанды"), "Взломанная консоль не видит отказ: [econ_cargo_message("", TRUE)]")
	TEST_ASSERT(!findtext(econ_cargo_message("", FALSE), "допуском контрабанды"), "Отказ контрабандного спецзаказа в общем сообщении ЦК: [SSshuttle.centcom_message]")
	SSshuttle.supply.export_categories = EXPORT_CARGO | EXPORT_CONTRABAND
	crate = shuttle_crate()
	new /obj/item/stack/sheet/bone(crate, 5)
	print_offer_manifest(offer, crate)
	print_offer_manifest(second, crate)
	SSshuttle.supply.sell()
	TEST_ASSERT(QDELETED(offer), "Контрабандный спецзаказ не принят с допуском")
	TEST_ASSERT_EQUAL(second.delivered, 0, "Второй спецзаказ в ящике засчитан")
	TEST_ASSERT(findtext(SSshuttle.centcom_message, "В ящике учитывается только один спецзаказ"), "Сообщение ЦК о второй накладной: [SSshuttle.centcom_message]")

/// Купленное в автомате спецзаказ не засчитывает, а NT выкупает не дороже доли уплаченного.
/datum/unit_test/economy_offers/vended_goods/Run()
	var/obj/machinery/vending/snack/machine = allocate(/obj/machinery/vending/snack)
	var/datum/data/vending_product/record = machine.product_records[1]
	var/price = record.custom_price || machine.default_price
	var/mob/living/carbon/human/buyer = allocate(/mob/living/carbon/human)
	var/obj/item/card/id/card = allocate(/obj/item/card/id)
	var/datum/bank_account/account = new("econ_test_offer_buyer")
	allocated += account
	account.credit(1000, ECON_ADMIN)
	card.registered_account = account
	buyer.put_in_active_hand(card)
	var/datum/tgui/window = allocate(/datum/tgui, buyer, machine, "Vending")
	window.status = UI_INTERACTIVE
	usr = buyer
	machine.ui_act("vend", list("ref" = REF(record)), window)
	usr = null
	card.registered_account = null
	var/obj/item/bought
	for(var/obj/item/candidate in buyer.contents + machine.loc.contents)
		if(candidate.type == record.product_path)
			bought = candidate
	TEST_ASSERT_NOTNULL(bought, "Автомат не выдал товар")
	allocated += bought
	TEST_ASSERT(bought.econ_vended && bought.econ_imported, "Товар автомата не помечен купленным")
	TEST_ASSERT(sale_value(bought) <= round(price * econ_import_resale_factor()), "Товар автомата выкуплен за [sale_value(bought)] при цене [price]")
	var/datum/market_offer/offer = add_offer("agrarian", record.product_path, 1, 2, 50)
	TEST_ASSERT(!offer.matches(bought), "Спецзаказ засчитал товар автомата")
	qdel(offer)
	TEST_ASSERT(findtext(jointext(machine.examine(buyer), "\n"), "уплаченного"), "Осмотр автомата не объясняет выкуп")

/// Отломленный кусок стопки из автомата уносит свою долю потолка выкупа, а слитая с ним своя стопка получает потолок.
/datum/unit_test/economy_offers/vended_stack_split/Run()
	var/obj/machinery/vending/medical/machine = allocate(/obj/machinery/vending/medical)
	var/datum/data/vending_product/record
	for(var/datum/data/vending_product/candidate as anything in machine.product_records)
		if(candidate.product_path == /obj/item/stack/medical/gauze)
			record = candidate
	TEST_ASSERT_NOTNULL(record, "NanoMed продаёт бинты")
	var/mob/living/carbon/human/buyer = allocate(/mob/living/carbon/human)
	var/obj/item/card/id/card = allocate(/obj/item/card/id)
	var/datum/bank_account/account = new("econ_test_offer_stack_buyer")
	allocated += account
	account.credit(1000, ECON_ADMIN)
	card.registered_account = account
	buyer.put_in_active_hand(card)
	var/datum/tgui/window = allocate(/datum/tgui, buyer, machine, "Vending")
	window.status = UI_INTERACTIVE
	usr = buyer
	machine.ui_act("vend", list("ref" = REF(record)), window)
	usr = null
	card.registered_account = null
	var/obj/item/stack/medical/gauze/bought
	for(var/obj/item/stack/medical/gauze/candidate in buyer.contents + machine.loc.contents)
		bought = candidate
	TEST_ASSERT(bought?.amount >= 2 && islist(bought.econ_print_cap), "Автомат не выдал помеченную стопку бинтов")
	allocated += bought
	var/total_cap = econ_cap_value(bought.econ_print_cap)
	var/half = round(bought.amount / 2)
	var/share = half / bought.amount
	var/obj/item/stack/medical/gauze/piece = bought.split_stack(null, half)
	allocated += piece
	TEST_ASSERT(piece.econ_vended && piece.econ_imported && islist(piece.econ_print_cap), "Кусок стопки потерял метки автомата")
	TEST_ASSERT(abs(econ_cap_value(piece.econ_print_cap) - total_cap * share) <= 1, "Потолок куска [econ_cap_value(piece.econ_print_cap)] вместо доли [total_cap * share]")
	TEST_ASSERT(abs(econ_cap_value(bought.econ_print_cap) - total_cap * (1 - share)) <= 1, "Потолок остатка не уменьшился: [econ_cap_value(bought.econ_print_cap)]")
	var/obj/item/stack/medical/gauze/own = allocate(/obj/item/stack/medical/gauze, run_loc_floor_top_right, 1)
	var/own_value = econ_cap_value(econ_value_list(own))
	piece.merge(own)
	TEST_ASSERT(islist(own.econ_print_cap) && own.econ_vended, "Своя стопка после слияния без потолка автомата")
	TEST_ASSERT(abs(econ_cap_value(own.econ_print_cap) - (own_value + total_cap * share)) <= 1, "Потолок слитой стопки [econ_cap_value(own.econ_print_cap)] вместо [own_value + total_cap * share]")
	TEST_ASSERT(sale_value(own) <= econ_cap_value(own.econ_print_cap) + 1, "Слитая стопка продана выше потолка")

/// Срок взятого спецзаказа выходит в fire(): провал без маржи, потеря репутации, строка дописана к сообщению ЦК; невзятый снимается без штрафа; груз после срока продаётся обычным порядком.
/datum/unit_test/economy_offers/expired/Run()
	var/datum/trade_partner/vey = SSmarket.get_partner("vey_med")
	var/datum/market_offer/late = add_offer("vey_med", /obj/item/stack/sheet/bone, 5, 2, 20)
	late.accept()
	late.deadline = world.time - 1
	var/obj/structure/closet/crate/crate = shuttle_crate()
	new /obj/item/stack/sheet/bone(crate, 5)
	print_offer_manifest(late, crate)
	SSshuttle.supply.sell()
	TEST_ASSERT_EQUAL(late.delivered, 0, "Просроченный спецзаказ принял груз")
	TEST_ASSERT(findtext(SSshuttle.centcom_message, "уже не принимает груз"), "Сообщение ЦК о просрочке: [SSshuttle.centcom_message]")
	var/datum/market_offer/untaken = add_offer("vey_med", /obj/item/stack/sheet/leather, 5, 2, 20)
	untaken.deadline = world.time - 1
	vey.reputation = 300
	SSshuttle.centcom_message = "Прежнее сообщение."
	var/cargo_before = cargo.account_balance
	SSmarket.fire()
	TEST_ASSERT(QDELETED(late) && QDELETED(untaken), "Просроченные не сняты")
	TEST_ASSERT_EQUAL(cargo.account_balance, cargo_before, "Провал заплатил маржу")
	TEST_ASSERT(abs(vey.reputation - (300 - MARKET_OFFER_REPUTATION_FAIL)) < 0.01, "Репутация за провал: [vey.reputation]")
	TEST_ASSERT(length(resolved) == 1 && resolved[1][1] == late && !resolved[1][2], "Сигнал провала только для взятого")
	TEST_ASSERT(findtext(SSshuttle.centcom_message, "Прежнее сообщение.") && findtext(SSshuttle.centcom_message, "провален"), "Строка о провале не дописана: [SSshuttle.centcom_message]")
	var/datum/market_offer/fresh = add_offer("vey_med", /obj/item/stack/sheet/bone, 5, 2, 20)
	fresh.deadline = world.time - 1
	TEST_ASSERT(!fresh.accept(), "Снятый по сроку спецзаказ взят")
	qdel(fresh)

/// fire() раз в offer_minutes выставляет спецзаказы открытым партнёрам из их offer_items, не больше offers_max и без повторов товара.
/datum/unit_test/economy_offers/generation/Run()
	SSmarket.offer_chance = 100
	for(var/fire_count in 1 to SSmarket.offers_max + 1)
		SSmarket.next_offers = world.time
		SSmarket.fire()
		TEST_ASSERT(SSmarket.next_offers >= world.time + SSmarket.offer_minutes MINUTES - 1, "Следующая генерация не назначена")
	for(var/id in SSmarket.partners)
		var/datum/trade_partner/partner = SSmarket.partners[id]
		if(!partner.unlocked)
			TEST_ASSERT(!length(partner.offers), "Закрытый партнёр [id] выставил спецзаказ")
			continue
		TEST_ASSERT_EQUAL(length(partner.offers), min(SSmarket.offers_max, length(partner.offer_items)), "Спецзаказов у [id]")
		var/list/seen = list()
		for(var/datum/market_offer/offer as anything in partner.offers)
			TEST_ASSERT(SSmarket.offer_by_uid(offer.uid) == offer, "Спецзаказ не находится по uid")
			TEST_ASSERT(!seen["[offer.wanted_type][offer.wanted_reagent]"], "Повтор товара у [id]")
			seen["[offer.wanted_type][offer.wanted_reagent]"] = TRUE
			TEST_ASSERT(offer.multiplier >= MARKET_OFFER_MULT_MIN && offer.multiplier <= MARKET_OFFER_MULT_MAX, "Множитель [offer.multiplier]")
			var/list/source
			for(var/list/item_entry as anything in partner.offer_items)
				if(item_entry["path"] == offer.wanted_type && item_entry["reagent"] == offer.wanted_reagent)
					source = item_entry
			TEST_ASSERT_NOTNULL(source, "Спецзаказ не из offer_items [id]")
			TEST_ASSERT(offer.quantity >= source["min"] && offer.quantity <= source["max"] && offer.unit_price == source["unit_price"], "Количество или цена не из записи [id]")
			TEST_ASSERT(abs(offer.deadline - (world.time + SSmarket.offer_minutes * MARKET_OFFER_UNTAKEN_LIFETIME MINUTES)) < 1, "Срок невзятого")
	TEST_ASSERT(length(SSmarket.all_offers()), "Ни одного спецзаказа")

/// Консоль запросов, экспресс-консоль Deep Space и консоль снабжения вне станции спецзаказы не берут и не печатают; справка снабжения называет правила числами из настроек.
/datum/unit_test/economy_offers/consoles_and_help/Run()
	var/datum/market_offer/offer = add_offer("prospectors", /obj/item/stack/sheet/mineral/gold, 5, 2, 60)
	var/turf/station_turf = find_walkable_station_turf()
	TEST_ASSERT_NOTNULL(station_turf, "Есть станционный турф")
	var/mob/living/carbon/human/user = make_technician(station_turf)
	var/list/refusing = list(
		allocate(/obj/machinery/computer/cargo/request, station_turf),
		allocate(/obj/machinery/computer/cargo/express/ds, station_turf),
		allocate(/obj/machinery/computer/cargo, run_loc_floor_bottom_left),
	)
	for(var/obj/machinery/computer/cargo/console as anything in refusing)
		console_act(console, user, "accept_offer", offer.uid)
		TEST_ASSERT(!offer.accepted, "[console.type] на [console.z] взяла спецзаказ")
		TEST_ASSERT(!console.can_take_offers(), "[console.type] предлагает брать спецзаказы")
	offer.accept()
	for(var/obj/machinery/computer/cargo/console as anything in refusing)
		console_act(console, user, "print_offer_manifest", offer.uid)
		TEST_ASSERT(!(locate(/obj/item/export_manifest) in user.held_items), "[console.type] напечатала накладную спецзаказа")
	var/obj/item/export_manifest/manifest = print_offer_manifest(offer, run_loc_floor_bottom_left)
	allocated += manifest
	qdel(offer)
	TEST_ASSERT(findtext(jointext(manifest.examine(user), "\n"), "Спецзаказ по этой накладной закрыт"), "Осмотр накладной закрытого спецзаказа")
	var/help = econ_cargo_market_help()
	TEST_ASSERT(findtext(help, "до [SSmarket.offers_max], новые выходят раз в [SSmarket.offer_minutes] мин.") && findtext(help, "закрыть за [SSmarket.offer_deadline_minutes] мин.") && findtext(help, "+[MARKET_OFFER_REPUTATION_SUCCESS] репутации") && findtext(help, "маржа"), "Справка не описывает спецзаказы")

/// Настройки спецзаказов и offer_items партнёров из economy.json совпадают со встроенными; любая битая запись оставляет список партнёра встроенным.
/datum/unit_test/economy_offers/config/Run()
	var/list/errors = SSmarket.load_settings(SSeconomy.settings.raw?["market"])
	TEST_ASSERT(!length(errors), "economy.json market: [jointext(errors, "; ")]")
	var/list/configured = snapshot()
	SSmarket.load_settings(list())
	var/list/builtin = snapshot()
	TEST_ASSERT_EQUAL(length(builtin), length(configured), "Число параметров")
	for(var/key in configured)
		TEST_ASSERT_EQUAL(builtin[key], configured[key], "Встроенное [key] расходится с economy.json")
	var/datum/market_offer/kept = add_offer("prospectors", /obj/item/stack/sheet/mineral/gold, 5, 2, 60)
	var/list/bad = list(
		"offer_minutes" = 0,
		"offers_max" = 1.5,
		"offer_chance" = 200,
		"offer_deadline_minutes" = "долго",
		"commodities" = SSeconomy.settings.raw["market"]["commodities"],
		"partners" = list(
			"prospectors" = list("offer_items" = list(
				list("path" = "/obj/item/nonexistent_offer_thing", "name" = "ничто", "min" = 1, "max" = 2, "unit_price" = 10),
				list("path" = "/obj/item/stack/sheet/mineral/gold", "name" = "золото", "min" = 5, "max" = 2, "unit_price" = 10),
				list("path" = "/obj/item/reagent_containers/pill", "name" = "таблетки", "min" = 1, "max" = 2, "unit_price" = 10, "reagent" = "/datum/reagent/medicine/bicaridine"),
				list("path" = "/obj/item", "name" = "что угодно", "min" = 1, "max" = 2, "unit_price" = 10),
				list("path" = "/obj/item/reagent_containers", "name" = "тара", "min" = 1, "max" = 2, "unit_price" = 10),
				list("path" = "/obj/item/stack/sheet/mineral/gold", "name" = "золото", "min" = 1, "max" = 2, "unit_price" = 10, "reagent" = "/datum/reagent/water", "volume" = 5),
				list("path" = "/obj/item/stack/sheet/mineral/gold", "name" = "золото", "min" = 1, "max" = 2, "unit_price" = 10),
			)),
			"vey_med" = list("offer_items" = "таблетки"),
		),
	)
	errors = SSmarket.load_settings(bad)
	TEST_ASSERT_EQUAL(length(errors), 11, "Ошибки: интервал, число, шанс, срок, тип, min/max, реагент без объёма, /obj/item, абстрактный тип, реагент у стопки, не список ([jointext(errors, "; ")])")
	TEST_ASSERT_EQUAL(SSmarket.offer_minutes, initial(SSmarket.offer_minutes), "Нулевой интервал принят")
	var/datum/trade_partner/prospectors = SSmarket.get_partner("prospectors")
	var/list/default_items = GLOB.market_default_partners["prospectors"]["offer_items"]
	TEST_ASSERT_EQUAL(length(prospectors.offer_items), length(default_items), "Битый список спецзаказов принят частично")
	TEST_ASSERT(kept in prospectors.offers, "Перечитывание сняло спецзаказ")
	SSmarket.load_settings(SSeconomy.settings.raw?["market"])

/datum/unit_test/economy_offers/config/proc/snapshot()
	. = list("settings" = "[SSmarket.offer_minutes]|[SSmarket.offers_max]|[SSmarket.offer_chance]|[SSmarket.offer_deadline_minutes]")
	for(var/id in SSmarket.partners)
		var/datum/trade_partner/partner = SSmarket.partners[id]
		var/list/texts = list()
		for(var/list/item_entry as anything in partner.offer_items)
			texts += "[item_entry["path"]],[item_entry["name"]],[item_entry["min"]],[item_entry["max"]],[item_entry["unit_price"]],[item_entry["reagent"]],[item_entry["volume"]],[item_entry["subtypes"]]"
		.[id] = jointext(texts, ";")

/// Сколько раз пересчитывать цены готовки: цепочки вроде мука - тесто - хлеб - ломтик
#define COOK_PRICE_ROUNDS 6
/// Сколько ещё раз генерировать пак со случайным содержимым
#define RANDOM_PACK_SAMPLES 18

/// Ни один спецзаказ не платит за штуку больше самой дешёвой закупки: готового предмета, его материалов, реагента или ингредиентов готовки - из паков на дне рынка со скидкой высшей ступени у всех партнёров и из автоматов станции по нижнему индексу со скидкой отдела; напечатанное - не дороже закупки его материалов. Запись без закупки должна быть объявлена производимой на станции.
/datum/unit_test/economy_offers/no_offer_farm
	/// Тип предмета (у стопок - merge_type) -> list(цена штуки, откуда)
	var/list/item_prices = list()
	/// Материал -> цена единицы материала
	var/list/material_prices = list()
	/// Реагент -> цена единицы объёма
	var/list/reagent_prices = list()
	/// Запись offer_items -> id партнёра
	var/list/entries = list()
	/// "путь|реагент" записи -> чем станция производит её без закупки
	var/list/station_produced = list(
		"/obj/item/stack/sheet/mineral/diamond|" = "шахта",
		"/obj/item/stack/sheet/animalhide/goliath_hide|" = "охота на Лаваленде",
		"/obj/item/stack/sheet/bone|" = "охота и разделка",
		"/obj/item/slime_extract/gold|" = "ксенобиология",
		"/obj/item/slime_extract/adamantine|" = "ксенобиология",
		"/obj/item/stock_parts/cell/high/slime|" = "ксенобиология",
		"/obj/item/tea_cup|" = "стеклодувство",
		"/obj/item/glasswork/glass_base/lens|" = "стеклодувство",
		"/obj/item/reagent_containers/glass/beaker/flask|" = "стеклодувство",
		"/obj/item/reagent_containers/crack|" = "синтез в химии",
		"/obj/item/reagent_containers/cocaine|" = "синтез в химии",
		"/obj/item/reagent_containers/crackbrick|" = "синтез в химии",
		"/obj/item/reagent_containers/food/snacks/grown/ambrosia/gaia|" = "мутация амброзии в ботанике",
		"/obj/item/reagent_containers/food/snacks/grown/bluecherries|" = "мутация вишни в ботанике",
		"/obj/item/slime_extract/rainbow|" = "ксенобиология",
		"/obj/item/slime_extract/bluespace|" = "ксенобиология",
		"/obj/item/organ/regenerative_core/legion|" = "охота на Лаваленде",
		"/obj/item/stack/sheet/bluespace_crystal|" = "шахта",
		"/obj/item/assembly/signaler/anomaly|" = "аномалии на станции",
		"/obj/item/stack/sheet/animalhide/ashdrake|" = "охота на пепельного дракона",
		"/obj/item/crusher_trophy|" = "охота с крашером",
		"/obj/item/reagent_containers/food/snacks/grown/shell/gatfruit|" = "мутация в ботанике",
	)

/datum/unit_test/economy_offers/no_offer_farm/Run()
	for(var/id in SSmarket.partners)
		var/datum/trade_partner/partner = SSmarket.partners[id]
		for(var/list/item_entry as anything in partner.offer_items)
			entries[item_entry] = id
	TEST_ASSERT(length(entries), "У партнёров нет offer_items")
	econ_test_partner_extremes()
	reagent_prices[/datum/reagent/water] = list(0, "кран")
	var/datum/bank_account/buyer = new("Тест")
	allocated += buyer
	for(var/pack_id in SSshuttle.supply_packs)
		var/datum/supply_pack/pack = SSshuttle.supply_packs[pack_id]
		if(pack.admin_spawned || (pack.special && !pack.special_enabled) || econ_test_explodes_on_delete(pack))
			continue
		scan_pack(pack, buyer)
	scan_vending()
	cook_prices()
	var/list/farms = list()
	for(var/list/item_entry as anything in entries)
		var/payout = round(item_entry["unit_price"] * MARKET_OFFER_MULT_MAX)
		var/list/cost = entry_cost(item_entry)
		if(!cost)
			if(!station_produced["[item_entry["path"]]|[item_entry["reagent"]]"])
				farms += "[entries[item_entry]] [item_entry["name"]]: нет ни закупки, ни объявленного производства на станции"
		else if(payout > cost[1])
			farms += "[entries[item_entry]] [item_entry["name"]]: [payout] кр. за штуку против закупки [round(cost[1], 0.1)] ([cost[2]])"
		if(!item_entry["reagent"] && !ispath(item_entry["path"], /obj/item/stack))
			farms += printed_farms(item_entry)
	TEST_ASSERT(!length(farms), "Спецзаказ платит больше закупки: [jointext(farms, "; ")]")

/datum/unit_test/economy_offers/no_offer_farm/proc/set_all_commodities(price_factor)
	for(var/id in SSmarket.commodities)
		var/datum/commodity/commodity = SSmarket.commodities[id]
		commodity.price_factor = price_factor
		commodity.hot_mult = 1
		commodity.demand = 1

/datum/unit_test/economy_offers/no_offer_farm/proc/price_key(atom/movable/thing)
	var/obj/item/stack/stack = thing
	return istype(stack) ? stack.merge_type : thing.type

/datum/unit_test/economy_offers/no_offer_farm/proc/units_of(atom/movable/thing)
	var/obj/item/stack/stack = thing
	return istype(stack) ? stack.amount : 1

/datum/unit_test/economy_offers/no_offer_farm/proc/note(list/prices, key, unit_cost, source)
	var/list/known = prices[key]
	if(!known || unit_cost < known[1])
		prices[key] = list(unit_cost, source)

/// Выкуп одного предмета без содержимого, как его продаст шаттл; купленное - по потолку выкупа.
/datum/unit_test/economy_offers/no_offer_farm/proc/own_value(atom/movable/thing)
	for(var/datum/export/export as anything in GLOB.exports_list)
		if(export.applies_to(thing, EXPORT_CARGO | EXPORT_CONTRABAND | EXPORT_EMAG))
			. = round(export.get_cost(thing) * econ_export_sale_factor(export, thing))
			if(islist(thing.econ_print_cap))
				. = min(., econ_cap_value(thing.econ_print_cap))
			return
	return 0

/// Цена штуки каждого типа, единицы материала и реагента в закупке; выкуп остального вычитается из цены.
/datum/unit_test/economy_offers/no_offer_farm/proc/note_purchase(list/things, price, source)
	var/list/resale = list()
	var/total_resale = 0
	for(var/atom/movable/thing as anything in things)
		resale[thing] = own_value(thing)
		total_resale += resale[thing]
	var/list/type_units = list()
	var/list/type_resale = list()
	var/list/material_units = list()
	var/list/material_resale = list()
	var/list/reagent_units = list()
	var/list/reagent_resale = list()
	for(var/atom/movable/thing as anything in things)
		var/key = price_key(thing)
		type_units[key] += units_of(thing)
		type_resale[key] += resale[thing]
		for(var/datum/material/material as anything in thing.custom_materials)
			material_units[material] += thing.custom_materials[material]
			material_resale[material] += resale[thing]
		for(var/datum/reagent/reagent as anything in thing.reagents?.reagent_list)
			reagent_units[reagent.type] += reagent.volume
			reagent_resale[reagent.type] += resale[thing]
	for(var/key in type_units)
		if(type_units[key] > 0)
			note(item_prices, key, (price - total_resale + type_resale[key]) / type_units[key], source)
	for(var/material in material_units)
		if(material_units[material] > 0)
			note(material_prices, material, (price - total_resale + material_resale[material]) / material_units[material], source)
	for(var/reagent_type in reagent_units)
		if(reagent_units[reagent_type] > 0)
			note(reagent_prices, reagent_type, (price - total_resale + reagent_resale[reagent_type]) / reagent_units[reagent_type], source)

/// Пак на дне рынка, частный заказ, если дешевле; ящик-залог возвращается полностью. Пак со случайным содержимым оценивается по средней из выборок.
/datum/unit_test/economy_offers/no_offer_farm/proc/scan_pack(datum/supply_pack/pack, datum/bank_account/buyer)
	set_all_commodities(MARKET_PRICE_MIN)
	var/price = pack.get_cost() - econ_packaging_value(pack.packaging_type())
	if(pack.can_private_buy && pack.goody == PACK_GOODY_NONE)
		price = min(price, pack.get_cost(buyer) - econ_packaging_value(pack.packaging_type(buyer)))
	set_all_commodities(1)
	var/list/generated = list()
	var/list/containers = list(generate_pack(pack, generated), generate_pack(pack, generated))
	var/atom/movable/first = containers[1]
	var/atom/movable/second = containers[2]
	var/list/first_types = list()
	var/list/second_types = list()
	for(var/atom/movable/thing as anything in first.GetAllContents())
		first_types += thing.type
	for(var/atom/movable/thing as anything in second.GetAllContents())
		second_types += thing.type
	if(length(first_types ^ second_types) || length(first_types) != length(second_types))
		for(var/extra in 1 to RANDOM_PACK_SAMPLES)
			containers += generate_pack(pack, generated)
	note_purchase(generated, price * length(containers), pack.name)
	for(var/atom/movable/thing as anything in generated + containers)
		if(!QDELETED(thing))
			qdel(thing)
	econ_test_clear_turf(run_loc_floor_bottom_left)

/// Пак в упаковке отгрузки; его содержимое добавляется в generated.
/datum/unit_test/economy_offers/no_offer_farm/proc/generate_pack(datum/supply_pack/pack, list/generated)
	var/atom/movable/container
	if(pack.goody != PACK_GOODY_NONE)
		container = new /obj/item/storage/lockbox/order(run_loc_floor_bottom_left)
		for(var/item in pack.contains)
			new item(container)
	else
		container = pack.generate(run_loc_floor_bottom_left)
	econ_mark_imported(container)
	generated += container.GetAllContents() - container
	return container

/// Автоматы, которые станция может собрать платой торгового автомата или пополнить картриджем из пака, и стоящие на станции.
/datum/unit_test/economy_offers/no_offer_farm/proc/station_vendor_types()
	. = list()
	var/obj/item/circuitboard/machine/vendor/board = new
	for(var/vendor_type in board.vending_names_paths)
		. |= vendor_type
	qdel(board)
	var/list/refills = list()
	for(var/pack_id in SSshuttle.supply_packs)
		var/datum/supply_pack/pack = SSshuttle.supply_packs[pack_id]
		if(pack.admin_spawned || (pack.special && !pack.special_enabled))
			continue
		for(var/item in pack.contains)
			if(ispath(item, /obj/item/vending_refill))
				refills |= item
	for(var/obj/machinery/vending/vendor_type as anything in subtypesof(/obj/machinery/vending))
		if(initial(vendor_type.refill_canister) in refills)
			. |= vendor_type
	for(var/obj/machinery/vending/mapped as anything in SSmachines.get_machines_by_type_and_subtypes(/obj/machinery/vending))
		if(is_station_level(mapped.z))
			. |= mapped.type

/// Живые автоматы станции по нижнему индексу цен: обычный товар со скидкой отдела, премиум и контрабанда - по своей цене без скидки, как в vend().
/datum/unit_test/economy_offers/no_offer_farm/proc/scan_vending()
	var/saved_index = SSmarket.price_index
	SSmarket.price_index = MARKET_INDEX_MIN
	var/list/cheapest = list()
	var/scanned = 0
	for(var/vendor_type in station_vendor_types())
		var/obj/machinery/vending/vendor = new vendor_type(run_loc_floor_top_right)
		if(QDELETED(vendor))
			continue
		scanned++
		var/discount = vendor.payment_department != NO_FREEBIES
		for(var/datum/data/vending_product/record as anything in vendor.product_records)
			var/price = record.custom_price || vendor.default_price
			if(discount)
				price = max(round(price * DEPARTMENT_DISCOUNT), 1)
			note(cheapest, record.product_path, price, vendor.name)
		for(var/datum/data/vending_product/record as anything in vendor.hidden_records + vendor.coin_records)
			note(cheapest, record.product_path, record.custom_premium_price || vendor.extra_price, vendor.name)
		qdel(vendor)
		econ_test_clear_turf(run_loc_floor_top_right)
	SSmarket.price_index = saved_index
	TEST_ASSERT(scanned && length(cheapest), "Автоматы не просканированы")
	for(var/product_type in cheapest)
		if(!ispath(product_type, /obj/item))
			continue
		var/atom/movable/sample = new product_type(run_loc_floor_bottom_left)
		econ_mark_vended(sample, cheapest[product_type][1])
		var/list/generated = sample.GetAllContents()
		note_purchase(generated, cheapest[product_type][1], "автомат [cheapest[product_type][2]]")
		for(var/atom/movable/thing as anything in generated)
			if(!QDELETED(thing))
				qdel(thing)
		econ_test_clear_turf(run_loc_floor_bottom_left)

/// Готовка из купленного: смеси реагентов, рецепты стола, запекание и нарезка, до установившихся цен.
/datum/unit_test/economy_offers/no_offer_farm/proc/cook_prices()
	var/list/mixtures = list()
	for(var/mixture_type in subtypesof(/datum/chemical_reaction/food))
		var/datum/chemical_reaction/food/mixture = new mixture_type
		if(ispath(mixture.resulting_food_path, /obj/item))
			mixtures += mixture
	var/list/food_steps = list()
	for(var/obj/item/reagent_containers/food/snacks/food_type as anything in typesof(/obj/item/reagent_containers/food/snacks))
		if(initial(food_type.cooked_type) || initial(food_type.slice_path))
			food_steps += food_type
	for(var/round_index in 1 to COOK_PRICE_ROUNDS)
		for(var/datum/chemical_reaction/food/mixture as anything in mixtures)
			var/cost = ingredients_cost(mixture.required_reagents)
			if(!isnull(cost))
				note(item_prices, mixture.resulting_food_path, cost, "смесь [mixture.name]")
		for(var/datum/crafting_recipe/recipe as anything in GLOB.crafting_recipes)
			if(!ispath(recipe.result, /obj/item/reagent_containers/food))
				continue
			var/cost = ingredients_cost(recipe.reqs)
			if(!isnull(cost))
				note(item_prices, recipe.result, cost, "рецепт [recipe.name]")
		for(var/obj/item/reagent_containers/food/snacks/food_type as anything in food_steps)
			var/list/known = item_prices[food_type]
			if(!known)
				continue
			var/cooked = initial(food_type.cooked_type)
			if(cooked)
				note(item_prices, cooked, known[1], "запекание: [known[2]]")
			var/slice = initial(food_type.slice_path)
			if(slice)
				note(item_prices, slice, known[1] / max(initial(food_type.slices_num), 1), "нарезка: [known[2]]")
	QDEL_LIST(mixtures)

/// Цена ингредиентов: предметы и реагенты; null, если что-то не купить.
/datum/unit_test/economy_offers/no_offer_farm/proc/ingredients_cost(list/ingredients)
	. = 0
	for(var/ingredient in ingredients)
		var/list/known = ispath(ingredient, /datum/reagent) ? reagent_prices[ingredient] : item_prices[ingredient]
		if(!known)
			return null
		. += known[1] * ingredients[ingredient]

/// Самая дешёвая штука записи - list(цена, откуда) или null: готовый предмет, его материалы или нужный объём реагента.
/datum/unit_test/economy_offers/no_offer_farm/proc/entry_cost(list/item_entry)
	if(item_entry["reagent"])
		var/list/reagent = reagent_prices[item_entry["reagent"]]
		return reagent ? list(reagent[1] * item_entry["volume"], "реагент: [reagent[2]]") : null
	. = item_prices[item_entry["path"]]
	if(!ispath(item_entry["path"], /obj/item/stack))
		return
	var/stack_type = item_entry["path"]
	var/obj/item/stack/sample = new stack_type(run_loc_floor_bottom_left, 1)
	var/list/materials = materials_cost(sample.custom_materials)
	qdel(sample)
	if(materials && (!. || materials[1] < .[1]))
		. = materials

/// Цена материалов в закупке - list(цена, откуда) или null, если какой-то из них не купить.
/datum/unit_test/economy_offers/no_offer_farm/proc/materials_cost(list/materials)
	if(!length(materials))
		return null
	var/total = 0
	var/list/sources = list()
	for(var/key in materials)
		var/list/known
		if(istext(key))
			for(var/datum/material/material as anything in material_prices)
				var/list/candidate = material_prices[material]
				if(material.categories[key] && (!known || candidate[1] < known[1]))
					known = candidate
		else
			known = material_prices[key]
		if(!known)
			return null
		total += known[1] * materials[key]
		sources |= known[2]
	return list(total, "материалы: [jointext(sources, ", ")]")

/// Напечатанный на лейтах предмет записи: выплата спецзаказа при обычном рынке не выше закупки его материалов.
/datum/unit_test/economy_offers/no_offer_farm/proc/printed_farms(list/item_entry)
	. = list()
	var/datum/market_offer/offer = new(null, item_entry["path"], item_entry["name"], 1, MARKET_OFFER_MULT_MAX, item_entry["unit_price"])
	for(var/design_id in SSresearch.techweb_designs)
		var/datum/design/design = SSresearch.techweb_designs[design_id]
		if(!(design.build_type & (AUTOLATHE | PROTOLATHE | IMPRINTER | MECHFAB)) || !ispath(design.build_path, item_entry["path"]))
			continue
		var/obj/item/product = new design.build_path(run_loc_floor_bottom_left)
		econ_mark_station_made(product, design.materials)
		var/printed_payout = offer.unit_payout(product)
		var/list/cost = materials_cost(design.materials)
		if(cost && printed_payout > cost[1])
			. += "[entries[item_entry]] [item_entry["name"]]: напечатанное [design.name] - [printed_payout] кр. против материалов [round(cost[1], 0.1)]"
		for(var/atom/movable/thing as anything in product.GetAllContents())
			if(!QDELETED(thing))
				qdel(thing)
		econ_test_clear_turf(run_loc_floor_bottom_left)
	qdel(offer)

#undef COOK_PRICE_ROUNDS
#undef RANDOM_PACK_SAMPLES
