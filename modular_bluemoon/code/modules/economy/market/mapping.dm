/// Группа пака снабжения -> товар рынка, по которому он закупается
GLOBAL_LIST_INIT(econ_pack_group_commodity, list(
	"Medical" = COMMODITY_MEDICINE,
	"Emergency" = COMMODITY_MEDICINE,
	"Engineering" = COMMODITY_MACHINERY,
	"Engine Construction" = COMMODITY_MACHINERY,
	"Canisters & Materials" = COMMODITY_CONSTRUCTION,
	"Miscellaneous Supplies" = COMMODITY_CONSTRUCTION,
	"Science" = COMMODITY_ELECTRONICS,
	"Security" = COMMODITY_WEAPONS,
	"Armory" = COMMODITY_WEAPONS,
	"Food & Hydroponics" = COMMODITY_FOOD,
	"Vending" = COMMODITY_FOOD,
	"Service" = COMMODITY_LUXURY,
	"Goodies" = COMMODITY_LUXURY,
	"Costumes & Toys" = COMMODITY_TEXTILES,
	"Livestock" = COMMODITY_BIOMATERIALS,
	"Каталог отдела" = COMMODITY_MACHINERY,
))

GLOBAL_LIST_EMPTY(econ_packaging_values)

/// Сколько NT платит за пустую упаковку этого типа: первый подходящий экспорт, как при продаже.
/proc/econ_packaging_value(container_type)
	if(!ispath(container_type))
		return 0
	if(!isnull(GLOB.econ_packaging_values[container_type]))
		return GLOB.econ_packaging_values[container_type]
	if(!length(GLOB.exports_list))
		setupExports()
	. = 0
	for(var/datum/export/export as anything in GLOB.exports_list)
		if((EXPORT_CARGO & export.export_category) != export.export_category)
			continue
		var/matches = export.include_subtypes ? (export.export_types[container_type] && !export.exclude_types[container_type]) : (container_type in export.export_types)
		if(matches)
			. = export.init_cost
			break
	GLOB.econ_packaging_values[container_type] = .

/atom/movable
	/// Собрано на станции: id товара рынка -> базовая цена материалов; NT платит не больше их рыночной цены
	var/list/econ_print_cap
	/// Реагенты, с которыми предмет вышел из лейта: тип -> объём, они часть отпечатка и не продаются
	var/list/econ_print_reagents

GLOBAL_LIST_EMPTY(econ_material_exports)

/// Экспорт, по которому NT покупает материал как сырьё: экспорт материала, а без него - экспорт его листа.
/proc/econ_material_export(datum/material/material)
	if(!isnull(GLOB.econ_material_exports[material]))
		return GLOB.econ_material_exports[material] || null
	if(!length(GLOB.exports_list))
		setupExports()
	var/datum/export/found
	for(var/datum/export/material/export in GLOB.exports_list)
		if(export.material_id == material.type)
			found = export
			break
	if(!found && material.sheet_type)
		for(var/datum/export/export as anything in GLOB.exports_list)
			if(istype(export, /datum/export/material) || (EXPORT_CARGO & export.export_category) != export.export_category)
				continue
			if(export.include_subtypes ? (export.export_types[material.sheet_type] && !export.exclude_types[material.sheet_type]) : (material.sheet_type in export.export_types))
				found = export
				break
	GLOB.econ_material_exports[material] = found || FALSE
	return found

/// Материалы -> id товара рынка -> базовая цена этих материалов как сырья.
/proc/econ_materials_value(list/materials)
	. = list()
	for(var/datum/material/material as anything in materials)
		if(!istype(material))
			continue
		var/datum/export/export = econ_material_export(material)
		if(export)
			.["[export.commodity]"] += materials[material] * export.init_cost / MINERAL_MATERIAL_AMOUNT

/// Цена потолка по текущему рынку товаров сырья.
/proc/econ_cap_value(list/cap)
	. = 0
	for(var/commodity_id in cap)
		. += cap[commodity_id] * econ_sale_factor(commodity_id)
	. = round(.)

/// Базовая цена предмета как список id товара -> цена: его потолок, если он собран на станции, иначе его экспорт.
/proc/econ_value_list(obj/thing)
	if(islist(thing.econ_print_cap))
		return thing.econ_print_cap.Copy()
	. = list()
	if(!length(GLOB.exports_list))
		setupExports()
	for(var/datum/export/export as anything in GLOB.exports_list)
		if(!export.applies_to(thing, EXPORT_CARGO | EXPORT_CONTRABAND | EXPORT_EMAG))
			continue
		if(thing.econ_imported)
			.[""] = export.get_cost(thing) * econ_import_resale_factor()
		else
			.["[export.commodity]"] = export.get_cost(thing)
		break

/// Собранное на станции стоит для NT не дороже своих материалов, из купленных - не дороже их выкупа; вложенное - не дороже своих.
/proc/econ_mark_station_made(atom/movable/product, list/fallback_materials, imported = FALSE)
	if(!istype(product) || isstack(product))
		return
	product.econ_print_cap = econ_materials_value(LAZYLEN(product.custom_materials) ? product.custom_materials : fallback_materials)
	if(imported)
		var/base = 0
		for(var/commodity_id in product.econ_print_cap)
			base += product.econ_print_cap[commodity_id]
		product.econ_print_cap = list("" = base * econ_import_resale_factor())
	for(var/atom/movable/thing as anything in product.GetAllContents())
		if(thing != product && !isstack(thing))
			thing.econ_print_cap = econ_materials_value(thing.custom_materials)
		if(!thing.reagents?.total_volume)
			continue
		thing.econ_print_reagents = list()
		for(var/datum/reagent/reagent as anything in thing.reagents.reagent_list)
			thing.econ_print_reagents[reagent.type] += reagent.volume

/// Доля потолка стопки за amount штук: отнимается у стопки и возвращается, null - если потолка нет.
/proc/econ_take_stack_cap(obj/item/stack/stack, amount)
	if(!islist(stack.econ_print_cap) || stack.amount <= 0)
		return null
	var/share = min(amount / stack.amount, 1)
	. = list()
	for(var/commodity_id in stack.econ_print_cap)
		.[commodity_id] = stack.econ_print_cap[commodity_id] * share
		stack.econ_print_cap[commodity_id] -= .[commodity_id]

/// Слияние стопок: потолок переходит вместе со штуками, у стопки без потолка он начинается с её собственной цены.
/proc/econ_merge_stack_cap(obj/item/stack/source, obj/item/stack/target, amount)
	var/list/moved = econ_take_stack_cap(source, amount)
	if(!moved)
		return
	if(!islist(target.econ_print_cap))
		target.econ_print_cap = econ_value_list(target)
	for(var/commodity_id in moved)
		target.econ_print_cap[commodity_id] += moved[commodity_id]
	target.econ_vended = target.econ_vended || source.econ_vended

/// Машина из рамы стоит как рама и плата; детали внутри продаются сами по себе.
/proc/econ_mark_assembled(obj/machinery/machine, obj/structure/frame/frame, obj/item/circuit)
	var/list/cap = islist(frame.econ_print_cap) ? frame.econ_print_cap.Copy() : econ_materials_value(frame.custom_materials)
	var/list/circuit_value = econ_value_list(circuit)
	for(var/commodity_id in circuit_value)
		cap[commodity_id] += circuit_value[commodity_id]
	machine.econ_print_cap = cap

/// Деталь, поглощённая сборкой, переходит в цену собираемого.
/proc/econ_add_part_value(atom/movable/assembly, obj/item/part)
	econ_add_assembly_value(assembly, econ_value_list(part))

/// Добавляет к цене собираемого долю share от цены поглощённого.
/proc/econ_add_assembly_value(atom/movable/assembly, list/value, share = 1)
	if(!islist(assembly.econ_print_cap))
		assembly.econ_print_cap = econ_value_list(assembly)
	for(var/commodity_id in value)
		assembly.econ_print_cap[commodity_id] += value[commodity_id] * share

/// Мех стоит как всё, что поглотили шасси и шаги сборки; батарея и модули внутри продаются сами по себе.
/proc/econ_mark_mech_assembled(obj/vehicle/sealed/mecha/mech, obj/item/chassis)
	mech.econ_print_cap = islist(chassis.econ_print_cap) ? chassis.econ_print_cap.Copy() : econ_value_list(chassis)

/proc/econ_station_made_note()
	return "NT выкупает собранное на станции не дороже его материалов (купленных через снабжение - по цене выкупа), содержимое оплачивается отдельно; мех - по сумме деталей."

/obj/machinery/autolathe/examine(mob/user)
	. = ..()
	. += span_notice(econ_station_made_note())

/obj/machinery/rnd/production/examine(mob/user)
	. = ..()
	. += span_notice(econ_station_made_note())

/obj/machinery/mecha_part_fabricator/examine(mob/user)
	. = ..()
	. += span_notice(econ_station_made_note())

/// Справка консолей снабжения одной строкой: все пункты econ_cargo_help_topics() подряд.
/proc/econ_cargo_market_help(show_contraband = FALSE)
	var/list/lines = list()
	for(var/list/topic as anything in econ_cargo_help_topics(show_contraband))
		lines += topic["lines"]
	return jointext(lines, " ")

/// Справка консолей снабжения по темам: list(title, icon, lines). Вольных торговцев называет только консоли с допуском контрабанды.
/proc/econ_cargo_help_topics(show_contraband = FALSE)
	var/datum/economy_settings/settings = SSeconomy.settings
	. = list()
	. += list(list("title" = "Заказ и доставка", "icon" = "shopping-cart", "lines" = list(
		"Пак везёт самый дешёвый открытый партнёр, у которого он есть на складе; склад пополняется раз в [SSmarket.partner_restock_minutes] мин. за счёт капитала партнёра. В карточке пака можно выбрать другого партнёра: заказ у него растит его репутацию; если к отгрузке он не сможет везти, повезёт самый дешёвый.",
		"Ящик пака - залог: NT принимает его обратно за полную цену.",
		"Частный заказ с шаттлом дороже пака на [round((ECON_PRIVATE_ORDER_MARKUP - 1) * 100)]%, кроме малых кейсов.",
		"Малые кейсы на один счёт доставляются бесплатно, пока их не больше [GOODY_FREE_SHIPPING_MAX] за отгрузку; если больше, все они едут одним ящиком и снимается сбор [CRATE_TAX] кр. в пользу снабжения.",
		"\"[ECON_PERSONAL_CATALOG_GROUP]\" - питомцы, одежда, украшения и вещи для уюта за свой счёт: по цене партнёра, без наценки частного заказа; всё, кроме залога за ящик, уходит NT.",
	)))
	. += list(list("title" = "Цены", "icon" = "tags", "lines" = list(
		"Цены паков следуют рынку товаров: тренды и горячие товары - на вкладке \"Рынок\".",
		"Наценка партнёра и скидка за его репутацию касаются только содержимого и не опускают его цену ниже [MARKET_PRICE_MIN * 100]% базы; скидка - до [PARTNER_DISCOUNT_MAX * 100]% на ступени [PARTNER_TIER_MAX].",
		"Купленное через снабжение или в торговом автомате NT выкупает не дороже [round(econ_import_resale_factor() * 100)]% базовой цены, партнёр этот потолок не поднимает.",
		econ_station_made_note(),
	)))
	. += list(list("title" = "Продажа и экспорт", "icon" = "truck-loading", "lines" = list(
		"Груз на продажу забирает открытый партнёр, который платит за товар больше всех; товар без покупателя не продаётся и возвращается шаттлом.",
		"Партнёры покупают только грузы снабжения: энергия, руда в ORM и сданные улики оплачиваются по рынку без них.",
		"Экспортная накладная отдела в любом ящике, даже в ящике снабжения, отдаёт выручку этого ящика отделу накладной, снабжению остаётся сбор [settings.cargo_handling_fee]%. Ящик без накладной продаётся в бюджет снабжения.",
	)))
	. += list(list("title" = "Партнёры", "icon" = "users", "lines" = list(
		"Репутация: [SSmarket.reputation_per_credit * 100] очков за 100 кр. продаж и вдвое меньше за закупки; купленное через снабжение и проданное обратно репутации не даёт. Новая ступень и скидка - каждые [PARTNER_TIER_STEP] очков.",
		"Со 2-й ступени у каждого партнёра, кроме НТ Логистики, открываются его эксклюзивные паки: их везёт только он. НТ Логистика везёт всё, но с логистической наценкой - у профильных партнёров их группы дешевле.",
		"Партнёр под эмбарго (обычно на [settings.event_embargo_minutes] мин.) не покупает и не продаёт: на это время груз берут и заказы везут другие партнёры, если могут. Новых спецзаказов он не выставляет, невзятые взять нельзя, а уже взятые можно выполнить.",
	)))
	. += list(list("title" = "Спецзаказы", "icon" = "star", "lines" = list(
		"У открытого партнёра их бывает до [SSmarket.offers_max], новые выходят раз в [SSmarket.offer_minutes] мин., невзятый снимается через [SSmarket.offer_minutes * MARKET_OFFER_UNTAKEN_LIFETIME] мин.",
		"Спецзаказ платит цену заказа с множителем от [MARKET_OFFER_MULT_MIN] до [MARKET_OFFER_MULT_MAX]: за каждую принятую штуку сразу - цену заказа, а всё сверх неё - снабжению одной суммой, как его маржа, при выполнении.",
		"Взятый спецзаказ нужно закрыть за [SSmarket.offer_deadline_minutes] мин.: положите его накладную в ящик с товаром и отгрузите шаттлом. Выполнение даёт партнёру +[MARKET_OFFER_REPUTATION_SUCCESS] репутации, провал отнимает [MARKET_OFFER_REPUTATION_FAIL], оставляет снабжение без маржи и снижает оценку акций компании партнёра на [MARKET_OFFER_FAIL_STOCK_SHOCK * 100]%.[show_contraband ? " Спецзаказы контрабандного партнёра принимает только отгрузка с допуском контрабанды." : ""]",
		"Купленное через снабжение или в автомате спецзаказ не засчитывает, собранное на станции оплачивает не дороже его материалов; лишнее в ящике продаётся обычным порядком. С накладной отдела в том же ящике оплата за штуки делится, как выручка ящика; в ящике учитывается только один спецзаказ.",
	)))
	. += list(list("title" = "Аукцион и коллекционеры", "icon" = "gavel", "lines" = list(
		"Раз в [round(AUCTION_GAP_MIN / (1 MINUTES))]-[round(AUCTION_GAP_MAX / (1 MINUTES))] мин. на аукцион сектора выставляется редкий лот на [round(AUCTION_DURATION / (1 MINUTES))] мин.; против станции торгуются другие станции сектора. Ставка - с личного счёта, замораживается до конца торгов, перебитая возвращается сразу; ставка в последнюю минуту продлевает торги. Выигранный лот прилетает капсулой на склад снабжения, NT выкупает его как импорт.",
		"Коллекционеры сектора иногда просят одну редкую вещь со станции: такой запрос - обычный спецзаказ, только платит намного больше.",
		"Скупка: партнёры иногда выставляют пачку из [BUNDLE_ITEMS_MIN]-[BUNDLE_ITEMS_MAX] разных предметов своего ассортимента со скидкой [BUNDLE_DISCOUNT_MIN]-[BUNDLE_DISCOUNT_MAX]% к сумме по отдельности. Продаётся только целиком, около [round(BUNDLE_LIFETIME / (1 MINUTES))] мин., одной станции; взятая пачка уходит в корзину и из скупки пропадает, даже если её потом снять. За бюджет берёт снабжение, лично - любой.",
	)))
	. += list(list("title" = "Контрабанда и таможня", "icon" = "user-secret", "lines" = list(
		show_contraband ? "Контрабанду Синдиката NT не покупает: её берут только Вольные торговцы и только с шаттла, отправленного с допуском контрабанды, иначе она возвращается. Остальной груз Вольные торговцы тоже покупают только с такого шаттла. Открывает их только взлом консоли снабжения и только до конца смены." : "Контрабанду Синдиката NT не покупает: она возвращается шаттлом.",
		"Отгрузки досматривает таможня NT: ящик с контрабандой проверяется с шансом [settings.customs_chance]% (+[settings.customs_chance_inspection]% во время инспекции Sol, +[settings.customs_chance_alert]% при красном коде и выше). Найденная контрабанда изымается, штраф [settings.customs_fine_share]% её оценки платит отдел, чья накладная лежит в ящике, иначе снабжение; остальной груз продаётся как обычно.",
	)))
	. += list(list("title" = "Новости и смены", "icon" = "newspaper", "lines" = list(
		"Горячие товары, открытие партнёров и события компаний выходят на ньюскастерах в канале \"[MARKET_NEWS_CHANNEL]\" не чаще раза в [SSmarket.news_flash_minutes] мин., сводка рынка со спецзаказами - раз в [SSmarket.digest_minutes] мин. Бывают и фальшивые пресс-релизы: через [settings.press_release_refute_minutes] мин. NT публикует опровержение и возвращает цену.",
		"Между сменами сектор помнит тренды и спрос товаров, цены акций, репутацию и капитал партнёров, но сдвигает их на [SSmarket.persist_decay]% к исходным; открытый партнёр[show_contraband ? ", кроме контрабандного," : ""] остаётся открытым. Спецзаказы, склады партнёров и акции на счетах смену не переживают.",
	)))

/proc/econ_express_help()
	return "Экспресс-заказ списывает цену пака у партнёра сразу, в момент заказа: с бюджета снабжения или, в режиме частного заказа, с личного счёта карты. Наценки частного заказа и сбора за малые кейсы здесь нет; частные малые кейсы - только с личного счёта. Маяк для доставки капсулой печатается за [EXPRESS_BEACON_COST] кр. из бюджета снабжения."

/// Пак идёт через торговых партнёров: рыночный, не из каталога отдела, не особый, не эмаговый и не контрабанда.
/proc/econ_pack_traded(datum/supply_pack/pack)
	return econ_pack_commodity(pack) && !pack.department_catalog && !pack.special && !pack.hidden && !pack.admin_spawned && !pack.contraband

/// Поставщик пака или null; для пака мимо партнёров - тоже null.
/proc/econ_pack_supplier(datum/supply_pack/pack, datum/bank_account/paying_account, allow_contraband = FALSE)
	return econ_pack_traded(pack) ? SSmarket.supplier_for(pack, paying_account, allow_contraband) : null

/// Пака нет ни у одного открытого партнёра: заказ ждёт пополнения склада.
/proc/econ_pack_unavailable(datum/supply_pack/pack, allow_contraband = FALSE)
	return econ_pack_traded(pack) && !SSmarket.supplier_for(pack, null, allow_contraband)

/// Множитель лучшего покупателя; контрабандный партнёр покупает только отгрузку с допуском контрабанды.
/proc/econ_buyer_factor(commodity_id, allow_contraband = FALSE)
	if(!commodity_id || !SSmarket.get_commodity(commodity_id))
		return 1
	var/datum/trade_partner/buyer = SSmarket.best_buyer(commodity_id, allow_contraband)
	return buyer ? buyer.buy_multiplier(commodity_id) : 0

/proc/econ_sale_factor(commodity_id)
	var/datum/commodity/market_commodity = SSmarket.get_commodity(commodity_id)
	return market_commodity ? market_commodity.sell_factor() : 1

/proc/econ_export_commodity(datum/export/export)
	return SSmarket.get_commodity(export.commodity)

/proc/econ_pack_commodity(datum/supply_pack/pack)
	return SSmarket.get_commodity(pack.commodity || GLOB.econ_pack_group_commodity[pack.group])

/// Купленное через снабжение NT выкупает не дороже нижней границы рынка: так перепродажа ящика не окупает его закупку.
/proc/econ_import_resale_factor()
	return MARKET_PRICE_MIN * min(1, SSeconomy.pack_price_modifier)

/proc/econ_export_sale_factor(datum/export/export, atom/movable/thing, allow_contraband = FALSE)
	if(istype(export, /datum/export/contraband))
		allow_contraband = TRUE
	var/datum/commodity/market_commodity = econ_export_commodity(export)
	. = market_commodity ? market_commodity.sell_factor() * econ_buyer_factor(export.commodity, allow_contraband) : 1
	if(thing.econ_imported)
		. = min(., econ_import_resale_factor())

/proc/econ_reagent_commodity(datum/reagent/reagent)
	return SSmarket.get_commodity(istype(reagent, /datum/reagent/medicine) ? COMMODITY_MEDICINE : COMMODITY_CHEMICALS)

/proc/econ_reagent_sale_factor(datum/reagent/reagent, atom/movable/container, allow_contraband = FALSE)
	var/datum/commodity/market_commodity = econ_reagent_commodity(reagent)
	. = market_commodity ? market_commodity.sell_factor() * econ_buyer_factor(market_commodity.id, allow_contraband) : 1
	if(container.econ_imported)
		. = min(., econ_import_resale_factor())

/datum/supply_pack/organic/exoticseeds
	commodity = COMMODITY_SEEDS

/datum/supply_pack/organic/seeds
	commodity = COMMODITY_SEEDS

/datum/supply_pack/materials/glass50
	commodity = COMMODITY_CONSTRUCTION

/datum/supply_pack/materials/metal50
	commodity = COMMODITY_METALS

/datum/supply_pack/materials/plasteel20
	commodity = COMMODITY_METALS

/datum/supply_pack/materials/bz
	commodity = COMMODITY_GASES

/datum/supply_pack/materials/carbon_dio
	commodity = COMMODITY_GASES

/datum/supply_pack/materials/nitrogen
	commodity = COMMODITY_GASES

/datum/supply_pack/materials/nitrous_oxide_canister
	commodity = COMMODITY_GASES

/datum/supply_pack/materials/oxygen
	commodity = COMMODITY_GASES

/datum/supply_pack/materials/water_vapor
	commodity = COMMODITY_GASES

/datum/supply_pack/materials/fueltank
	commodity = COMMODITY_FUEL

/datum/supply_pack/materials/hightankfuel
	commodity = COMMODITY_FUEL

/datum/supply_pack/department/medical_surgery_kit
	commodity = COMMODITY_MEDICINE

/datum/supply_pack/department/science_xenobio
	commodity = COMMODITY_ELECTRONICS

/datum/export/booze
	commodity = COMMODITY_DRINKS

/datum/export/food
	commodity = COMMODITY_FOOD

/datum/export/gear
	commodity = COMMODITY_TEXTILES

/datum/export/gear/powerdrill
	commodity = COMMODITY_MACHINERY

/datum/export/gear/advtool
	commodity = COMMODITY_MACHINERY

/datum/export/tool
	commodity = COMMODITY_MACHINERY

/datum/export/analyzer
	commodity = COMMODITY_MACHINERY

/datum/export/extinguisher
	commodity = COMMODITY_MACHINERY

/datum/export/singulo
	commodity = COMMODITY_MACHINERY

/datum/export/radio
	commodity = COMMODITY_ELECTRONICS

/datum/export/weapon
	commodity = COMMODITY_WEAPONS

/datum/export/seed
	commodity = COMMODITY_SEEDS

/datum/export/plutonium_rod
	commodity = COMMODITY_FUEL

/datum/export/large
	commodity = COMMODITY_MACHINERY

/datum/export/large/crate
	commodity = null

/datum/export/large/barrier
	commodity = COMMODITY_CONSTRUCTION

/datum/export/large/gas_canister
	commodity = COMMODITY_GASES

/datum/export/large/reagent_dispenser
	commodity = COMMODITY_FUEL

/datum/export/large/mech
	commodity = COMMODITY_ROBOTICS

/datum/export/large/supermatter
	commodity = COMMODITY_CRYSTALS

/datum/export/large/nice_chair
	commodity = COMMODITY_LUXURY

/datum/export/large/aistatue
	commodity = COMMODITY_CULTURE

/datum/export/large/capstatue
	commodity = COMMODITY_CULTURE

/datum/export/large/cestatue
	commodity = COMMODITY_CULTURE

/datum/export/large/clownstatue
	commodity = COMMODITY_CULTURE

/datum/export/large/cmostatue
	commodity = COMMODITY_CULTURE

/datum/export/large/engstatue
	commodity = COMMODITY_CULTURE

/datum/export/large/hopstatue
	commodity = COMMODITY_CULTURE

/datum/export/large/hosstatue
	commodity = COMMODITY_CULTURE

/datum/export/large/janitorstatue
	commodity = COMMODITY_CULTURE

/datum/export/large/mdstatue
	commodity = COMMODITY_CULTURE

/datum/export/large/medborgstatue
	commodity = COMMODITY_CULTURE

/datum/export/large/nukestatue
	commodity = COMMODITY_CULTURE

/datum/export/large/plasmastatue
	commodity = COMMODITY_CULTURE

/datum/export/large/rdstatue
	commodity = COMMODITY_CULTURE

/datum/export/large/sandstatue
	commodity = COMMODITY_CULTURE

/datum/export/large/secborgstatue
	commodity = COMMODITY_CULTURE

/datum/export/large/secstatue
	commodity = COMMODITY_CULTURE

/datum/export/organs
	commodity = COMMODITY_BIOMATERIALS

/datum/export/organs/cybernetic
	commodity = COMMODITY_ROBOTICS

/datum/export/organs/upgraded
	commodity = COMMODITY_ROBOTICS

/datum/export/implant
	commodity = COMMODITY_ROBOTICS

/datum/export/robotics
	commodity = COMMODITY_ROBOTICS

/datum/export/board
	commodity = COMMODITY_ELECTRONICS

/datum/export/cell
	commodity = COMMODITY_ELECTRONICS

/datum/export/cellbs
	commodity = COMMODITY_ELECTRONICS

/datum/export/cellhigh
	commodity = COMMODITY_ELECTRONICS

/datum/export/cellhyper
	commodity = COMMODITY_ELECTRONICS

/datum/export/cellupgraded
	commodity = COMMODITY_ELECTRONICS

/datum/export/cellyellow
	commodity = COMMODITY_ELECTRONICS

/datum/export/cellyellowhyper
	commodity = COMMODITY_ELECTRONICS

/datum/export/solar
	commodity = COMMODITY_ELECTRONICS

/datum/export/subspace
	commodity = COMMODITY_ELECTRONICS

/datum/export/t1
	commodity = COMMODITY_ELECTRONICS

/datum/export/t2
	commodity = COMMODITY_ELECTRONICS

/datum/export/t3
	commodity = COMMODITY_ELECTRONICS

/datum/export/t4
	commodity = COMMODITY_ELECTRONICS

/datum/export/swarmer
	commodity = COMMODITY_ARTIFACTS

/datum/export/glasswork_dish
	commodity = COMMODITY_LUXURY

/datum/export/glasswork_glasses
	commodity = COMMODITY_LUXURY

/datum/export/glasswork_largeflask
	commodity = COMMODITY_LUXURY

/datum/export/glasswork_laserpointer
	commodity = COMMODITY_LUXURY

/datum/export/glasswork_lens
	commodity = COMMODITY_LUXURY

/datum/export/glasswork_smallflask
	commodity = COMMODITY_LUXURY

/datum/export/glasswork_spouty
	commodity = COMMODITY_LUXURY

/datum/export/glasswork_teacup
	commodity = COMMODITY_LUXURY

/datum/export/glasswork_teaplate
	commodity = COMMODITY_LUXURY

/datum/export/material
	commodity = COMMODITY_METALS

/datum/export/material/bananium
	commodity = COMMODITY_PRECIOUS

/datum/export/material/diamond
	commodity = COMMODITY_CRYSTALS

/datum/export/material/bscrystal
	commodity = COMMODITY_CRYSTALS

/datum/export/material/plasma
	commodity = COMMODITY_PLASMA

/datum/export/material/uranium
	commodity = COMMODITY_PRECIOUS

/datum/export/material/gold
	commodity = COMMODITY_PRECIOUS

/datum/export/material/silver
	commodity = COMMODITY_PRECIOUS

/datum/export/material/titanium
	commodity = COMMODITY_PRECIOUS

/datum/export/material/adamantine
	commodity = COMMODITY_PRECIOUS

/datum/export/material/mythril
	commodity = COMMODITY_PRECIOUS

/datum/export/material/runite
	commodity = COMMODITY_PRECIOUS

/datum/export/material/plastic
	commodity = COMMODITY_CONSTRUCTION

/datum/export/material/glass
	commodity = COMMODITY_CONSTRUCTION

/datum/export/stack
	commodity = COMMODITY_CONSTRUCTION

/datum/export/stack/leather
	commodity = COMMODITY_BIOMATERIALS

/datum/export/stack/skin
	commodity = COMMODITY_BIOMATERIALS

/datum/export/stack/skin/human
	commodity = COMMODITY_CONTRABAND

/datum/export/stack/skin/cat
	commodity = COMMODITY_CONTRABAND

/datum/export/stack/skin/corgi
	commodity = COMMODITY_CONTRABAND

/datum/export/stack/bone
	commodity = COMMODITY_BIOMATERIALS

/datum/export/stack/plasteel
	commodity = COMMODITY_METALS

/datum/export/stack/plastitanium
	commodity = COMMODITY_METALS

/datum/export/stack/glass_alloy/plasma
	commodity = COMMODITY_PLASMA

/datum/export/stack/glass_alloy/titanium
	commodity = COMMODITY_METALS

/datum/export/stack/sheet/bronze
	commodity = COMMODITY_METALS

/datum/export/stack/brass
	commodity = COMMODITY_METALS

/datum/export/stack/cable
	commodity = COMMODITY_ELECTRONICS

/datum/export/stack/cloth
	commodity = COMMODITY_TEXTILES

/datum/export/stack/duracloth
	commodity = COMMODITY_TEXTILES

/datum/export/stack/silk
	commodity = COMMODITY_TEXTILES

/datum/export/stack/abductor
	commodity = COMMODITY_ARTIFACTS

/datum/export/stack/telecrystal
	commodity = COMMODITY_CONTRABAND

/datum/export/stack/hot_ice
	commodity = COMMODITY_PLASMA

/datum/export/stack/metal_hydrogen
	commodity = COMMODITY_CRYSTALS

/datum/export/stack/zaukerite
	commodity = COMMODITY_CRYSTALS

/datum/export/stack/ammonia_crystals
	commodity = COMMODITY_CHEMICALS

/datum/export/crystallizer_item
	commodity = COMMODITY_GASES

/datum/export/crystallizer_item/fuel_pellet
	commodity = COMMODITY_FUEL

/datum/export/sweatshop
	commodity = COMMODITY_TEXTILES

/datum/export/lewd
	commodity = COMMODITY_LUXURY

/datum/export/crack
	commodity = COMMODITY_CONTRABAND

/datum/export/cocaine
	commodity = COMMODITY_CONTRABAND

/datum/export/cocainebrick
	commodity = COMMODITY_CONTRABAND

/datum/export/artifacts
	commodity = COMMODITY_ARTIFACTS

/datum/export/alienartifact
	commodity = COMMODITY_ARTIFACTS

/datum/export/xen_crystal
	commodity = COMMODITY_ARTIFACTS

/datum/export/satellite_data_core
	commodity = COMMODITY_ELECTRONICS

/datum/export/minor_manuscript
	commodity = COMMODITY_CULTURE

/datum/export/minor_reliquary
	commodity = COMMODITY_CULTURE
