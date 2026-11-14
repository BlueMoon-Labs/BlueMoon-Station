/// Встроенные торговые партнёры: на них SSmarket откатывается, если секция market.partners в economy.json битая.
GLOBAL_LIST_INIT(market_default_partners, list(
	"nt_logistics" = list("name" = "НТ Логистика", "desc" = "Логистическое крыло Нанотрейзен: возит всё, но с логистической наценкой 10%; покупает всё по базовой цене, без премий.", "buys" = list(PARTNER_ANY = 1), "sells_groups" = list(PARTNER_ANY), "markup" = 1.1, "wealth" = 50000, "base_income" = 5000, "unlocked" = TRUE, "company" = "NTRN", "offer_items" = list()),
	"prospectors" = list("name" = "Гильдия старателей", "desc" = "Шахтёрские артели пояса астероидов.", "buys" = list(COMMODITY_METALS = 1.05, COMMODITY_PRECIOUS = 1.25, COMMODITY_PLASMA = 1.2, COMMODITY_CRYSTALS = 1.3, COMMODITY_FUEL = 1), "sells_groups" = list("Canisters & Materials"), "markup" = 0.95, "wealth" = 15000, "base_income" = 2000, "unlocked" = TRUE, "company" = "PRSP", "offer_items" = list(list("path" = "/obj/item/stack/sheet/mineral/gold", "name" = "слитки золота", "min" = 5, "max" = 20, "unit_price" = 60), list("path" = "/obj/item/stack/sheet/mineral/silver", "name" = "слитки серебра", "min" = 10, "max" = 30, "unit_price" = 25), list("path" = "/obj/item/stack/sheet/mineral/uranium", "name" = "листы урана", "min" = 5, "max" = 20, "unit_price" = 50), list("path" = "/obj/item/stack/sheet/mineral/titanium", "name" = "листы титана", "min" = 5, "max" = 20, "unit_price" = 60), list("path" = "/obj/item/stack/sheet/mineral/diamond", "name" = "алмазы", "min" = 2, "max" = 6, "unit_price" = 250))),
	"vey_med" = list("name" = "Вей-Мед", "desc" = "Медицинский концерн.", "buys" = list(COMMODITY_MEDICINE = 1.25, COMMODITY_CHEMICALS = 1.15, COMMODITY_BIOMATERIALS = 1.2), "sells_groups" = list("Medical", "Emergency"), "markup" = 0.95, "wealth" = 15000, "base_income" = 2000, "unlocked" = TRUE, "company" = "VYMD", "offer_items" = list(list("path" = "/obj/item/stack/sheet/animalhide/goliath_hide", "name" = "шкуры голиафа", "min" = 2, "max" = 6, "unit_price" = 160), list("path" = "/obj/item/stack/sheet/bone", "name" = "кости", "min" = 5, "max" = 15, "unit_price" = 20), list("path" = "/obj/item/slime_extract/gold", "name" = "золотые экстракты слаймов", "min" = 1, "max" = 3, "unit_price" = 150), list("path" = "/obj/item/slime_extract/adamantine", "name" = "адамантиновые экстракты слаймов", "min" = 1, "max" = 3, "unit_price" = 150))),
	"nakamura" = list("name" = "Накамура Инжиниринг", "desc" = "Двигатели, энергетика и станционные системы.", "buys" = list(COMMODITY_ENERGY = 1.3, COMMODITY_MACHINERY = 1.2, COMMODITY_ELECTRONICS = 1.2, COMMODITY_GASES = 1.15), "sells_groups" = list("Engineering", "Engine Construction"), "markup" = 0.95, "wealth" = 15000, "base_income" = 2000, "unlock" = list("partner" = "nt_logistics", "tier" = 2), "company" = "NKMR", "offer_items" = list(list("path" = "/obj/item/stock_parts/cell/high/slime", "name" = "слаймовые батареи", "min" = 1, "max" = 3, "unit_price" = 150), list("path" = "/obj/item/stack/sheet/mineral/plastitanium", "name" = "листы пластитана", "min" = 5, "max" = 15, "unit_price" = 165), list("path" = "/obj/item/stack/sheet/plastitaniumglass", "name" = "листы пластитанового стекла", "min" = 5, "max" = 15, "unit_price" = 120))),
	"agrarian" = list("name" = "Аграрный союз", "desc" = "Фермерские колонии сектора.", "buys" = list(COMMODITY_FOOD = 1.25, COMMODITY_DRINKS = 1.25, COMMODITY_SEEDS = 1.3), "sells_groups" = list("Food & Hydroponics", "Livestock"), "markup" = 0.9, "wealth" = 12000, "base_income" = 1500, "unlock" = list("partner" = "vey_med", "tier" = 1), "company" = "AGRO", "offer_items" = list(list("path" = "/obj/item/reagent_containers/food/snacks/pizza/margherita", "name" = "пиццы \"Маргарита\"", "min" = 2, "max" = 6, "unit_price" = 100), list("path" = "/obj/item/reagent_containers/food/snacks/store/bread/plain", "name" = "буханки хлеба", "min" = 3, "max" = 10, "unit_price" = 15), list("path" = "/obj/item/reagent_containers/food/snacks/grown/ambrosia/gaia", "name" = "амброзия гайя", "min" = 5, "max" = 15, "unit_price" = 10), list("path" = "/obj/item/reagent_containers/food/snacks/grown/bluecherries", "name" = "синие вишни", "min" = 10, "max" = 30, "unit_price" = 6))),
	"sol_federation" = list("name" = "Солнечная Федерация", "desc" = "Торговые палаты Солнечной Федерации.", "buys" = list(COMMODITY_CULTURE = 1.4, COMMODITY_LUXURY = 1.3, COMMODITY_ARTIFACTS = 1.4), "sells_groups" = list("Service", "Goodies", "Costumes & Toys"), "markup" = 1, "wealth" = 30000, "base_income" = 3000, "unlock" = list("any_two_tier" = 2), "company" = "SOLX", "offer_items" = list(list("path" = "/obj/item/tea_cup", "name" = "стеклянные чашки", "min" = 1, "max" = 3, "unit_price" = 1200), list("path" = "/obj/item/glasswork/glass_base/lens", "name" = "стеклянные линзы", "min" = 1, "max" = 3, "unit_price" = 1200), list("path" = "/obj/item/reagent_containers/glass/beaker/flask", "name" = "стеклянные колбы", "min" = 1, "max" = 3, "unit_price" = 500))),
	"collectors" = list("name" = "Коллекционеры сектора", "desc" = "Частные коллекционеры сектора: изредка просят одну редкую вещь со станции и платят за неё много. Сами ничего не продают и не покупают.", "buys" = list(), "sells_groups" = list(), "markup" = 1, "wealth" = 0, "base_income" = 0, "unlocked" = TRUE, "offer_items" = list(list("path" = "/obj/item/slime_extract/rainbow", "name" = "радужные экстракты слаймов", "min" = 1, "max" = 1, "unit_price" = 1500), list("path" = "/obj/item/slime_extract/bluespace", "name" = "блюспейс-экстракты слаймов", "min" = 1, "max" = 2, "unit_price" = 400), list("path" = "/obj/item/organ/regenerative_core/legion", "name" = "ядра легиона", "min" = 1, "max" = 2, "unit_price" = 400), list("path" = "/obj/item/stack/sheet/bluespace_crystal", "name" = "блюспейс-кристаллы", "min" = 2, "max" = 5, "unit_price" = 150), list("path" = "/obj/item/assembly/signaler/anomaly", "name" = "ядра аномалий", "min" = 1, "max" = 1, "unit_price" = 3000, "subtypes" = TRUE), list("path" = "/obj/item/stack/sheet/animalhide/ashdrake", "name" = "шкура пепельного дракона", "min" = 1, "max" = 1, "unit_price" = 1200), list("path" = "/obj/item/crusher_trophy", "name" = "трофеи крашера", "min" = 1, "max" = 1, "unit_price" = 1500, "subtypes" = TRUE), list("path" = "/obj/item/reagent_containers/food/snacks/grown/shell/gatfruit", "name" = "ганфрукты", "min" = 1, "max" = 2, "unit_price" = 900))),
	"free_traders" = list("name" = "Вольные торговцы", "desc" = "Серые торговцы без лишних вопросов.", "buys" = list(COMMODITY_CONTRABAND = 1.5, PARTNER_ANY = 0.9), "sells_groups" = list("Security", "Armory"), "markup" = 1.3, "wealth" = 10000, "base_income" = 1500, "contraband" = TRUE, "company" = "CYBS", "offer_items" = list(list("path" = "/obj/item/reagent_containers/crack", "name" = "крэк", "min" = 3, "max" = 10, "unit_price" = 100), list("path" = "/obj/item/reagent_containers/cocaine", "name" = "кокаин", "min" = 3, "max" = 10, "unit_price" = 100), list("path" = "/obj/item/reagent_containers/crackbrick", "name" = "брикеты крэка", "min" = 1, "max" = 3, "unit_price" = 600))),
))

/datum/trade_partner
	var/id
	var/name = "партнёр"
	var/desc = ""
	/// id товара или PARTNER_ANY -> множитель цены, с которым партнёр его покупает
	var/list/buys = list()
	/// Группы паков, которые партнёр продаёт, или PARTNER_ANY
	var/list/sells_groups = list()
	var/markup = 1
	var/wealth = 0
	/// Капитал из конфига: к нему капитал затухает между раундами
	var/start_wealth = 0
	var/base_income = 0
	var/reputation = 0
	var/unlocked = FALSE
	/// Открыт с начала раунда
	var/start_unlocked = FALSE
	/// list("partner" = id, "tier" = N) или list("any_two_tier" = N)
	var/list/unlock
	/// Тикер компании на бирже
	var/company
	var/contraband = FALSE
	/// Тип пака -> штук на складе; пак, которого здесь нет, лежит на складе в полном запасе
	var/list/stock = list()
	var/list/offers = list()
	/// Из чего партнёр выбирает спецзаказы: path, name, min, max, unit_price, а также reagent и volume, subtypes
	var/list/offer_items = list()
	/// До этого world.time партнёр под эмбарго: не покупает и не продаёт
	var/embargo_until = 0

/datum/trade_partner/Destroy()
	QDEL_LIST(offers)
	return ..()

/datum/trade_partner/proc/reset_params()
	name = initial(name)
	desc = initial(desc)
	buys = list()
	sells_groups = list()
	markup = initial(markup)
	base_income = initial(base_income)
	start_wealth = initial(start_wealth)
	start_unlocked = initial(start_unlocked)
	unlock = null
	company = initial(company)
	contraband = initial(contraband)
	offer_items = list()

/// Накладывает запись конфига и возвращает ошибки "id.ключ: ..."; неверное значение параметр не меняет.
/datum/trade_partner/proc/configure(list/entry, list/commodity_ids, list/partner_ids, initial_state = FALSE)
	. = list()
	for(var/key in entry)
		var/value = entry[key]
		switch(key)
			if("name")
				if(istext(value) && length(value))
					name = value
				else
					. += "[id].name: нужна непустая строка"
			if("desc")
				if(istext(value))
					desc = value
				else
					. += "[id].desc: нужна строка"
			if("buys")
				if(!islist(value))
					. += "[id].buys: не объект"
					continue
				var/list/accepted = list()
				for(var/commodity_id in value)
					var/multiplier = value[commodity_id]
					if(commodity_id != PARTNER_ANY && !(commodity_id in commodity_ids))
						. += "[id].buys.[commodity_id]: нет такого товара"
					else if(!isnum(multiplier) || multiplier < 0 || multiplier > PARTNER_BUY_MULT_MAX)
						. += "[id].buys.[commodity_id]: нужно число 0..[PARTNER_BUY_MULT_MAX]"
					else
						accepted[commodity_id] = multiplier
				buys = accepted
			if("sells_groups")
				var/valid = islist(value)
				for(var/group in value)
					if(!istext(group))
						valid = FALSE
				if(valid)
					var/list/groups = value
					sells_groups = groups.Copy()
				else
					. += "[id].sells_groups: нужен список строк"
			if("markup")
				if(isnum(value) && value >= PARTNER_MARKUP_MIN && value <= PARTNER_MARKUP_MAX)
					markup = value
				else
					. += "[id].markup: нужно число [PARTNER_MARKUP_MIN]..[PARTNER_MARKUP_MAX]"
			if("wealth")
				if(isnum(value) && value >= 0)
					start_wealth = value
					if(initial_state)
						wealth = value
				else
					. += "[id].wealth: нужно число не меньше 0"
			if("base_income")
				if(isnum(value) && value >= 0)
					base_income = value
				else
					. += "[id].base_income: нужно число не меньше 0"
			if("unlocked")
				if(isnum(value) && (value == TRUE || value == FALSE))
					start_unlocked = value
				else
					. += "[id].unlocked: нужно true или false"
			if("unlock")
				var/error = check_unlock_rule(value, partner_ids)
				if(error)
					. += "[id].unlock: [error]"
				else
					var/list/rule = value
					unlock = rule.Copy()
			if("company")
				if(istext(value) && length(value))
					company = value
				else
					. += "[id].company: нужна непустая строка"
			if("contraband")
				if(isnum(value) && (value == TRUE || value == FALSE))
					contraband = value
				else
					. += "[id].contraband: нужно true или false"
			if("offer_items")
				if(!islist(value))
					. += "[id].offer_items: нужен список"
					continue
				var/list/accepted_items = list()
				var/list/item_errors = list()
				var/index = 0
				for(var/item_entry in value)
					index++
					var/list/parsed = parse_offer_item(item_entry)
					if(istext(parsed))
						item_errors += "[id].offer_items[index]: [parsed]"
					else
						accepted_items += list(parsed)
				if(length(item_errors))
					. += item_errors
				else
					offer_items = accepted_items
			else
				if(!ECON_CONFIG_COMMENT_KEY(key))
					. += "[id]: неизвестный ключ [key]"

/// Запись спецзаказа из конфига с путями-типами или текст ошибки.
/datum/trade_partner/proc/parse_offer_item(list/entry)
	if(!islist(entry))
		return "не объект"
	var/list/parsed = list()
	for(var/key in entry)
		var/value = entry[key]
		switch(key)
			if("path")
				var/obj/item/path = istext(value) ? text2path(value) : null
				if(!ispath(path, /obj/item) || path == /obj/item || !initial(path.icon_state))
					return "path: нет такого предмета или он абстрактный: [value]"
				parsed["path"] = path
			if("subtypes")
				if(!isnum(value) || (value != TRUE && value != FALSE))
					return "subtypes: нужно true или false"
				parsed["subtypes"] = value
			if("reagent")
				var/reagent = istext(value) ? text2path(value) : null
				if(!ispath(reagent, /datum/reagent))
					return "reagent: нет такого реагента [value]"
				parsed["reagent"] = reagent
			if("name")
				if(!istext(value) || !length(value))
					return "name: нужна непустая строка"
				parsed["name"] = value
			if("min", "max")
				if(!isnum(value) || value < 1 || round(value) != value)
					return "[key]: нужно целое не меньше 1"
				parsed[key] = value
			if("unit_price", "volume")
				if(!isnum(value) || value <= 0)
					return "[key]: нужно число больше 0"
				parsed[key] = value
			else
				if(!ECON_CONFIG_COMMENT_KEY(key))
					return "неизвестный ключ [key]"
	for(var/required in list("path", "name", "min", "max", "unit_price"))
		if(isnull(parsed[required]))
			return "нет ключа [required]"
	if(parsed["min"] > parsed["max"])
		return "min больше max"
	if(!isnull(parsed["reagent"]) != !isnull(parsed["volume"]))
		return "reagent и volume задаются вместе"
	if(parsed["reagent"] && !ispath(parsed["path"], /obj/item/reagent_containers))
		return "reagent: [parsed["path"]] не держит реагенты"
	return parsed

/// Новый спецзаказ из offer_items на товар, которого партнёр ещё не ждёт.
/datum/trade_partner/proc/new_offer()
	var/list/candidates = list()
	for(var/list/item_entry as anything in offer_items)
		var/taken = FALSE
		for(var/datum/market_offer/offer as anything in offers)
			if(offer.wanted_type == item_entry["path"] && offer.wanted_reagent == item_entry["reagent"])
				taken = TRUE
				break
		if(!taken)
			candidates += list(item_entry)
	if(!length(candidates))
		return null
	var/list/chosen = pick(candidates)
	var/multiplier = rand(MARKET_OFFER_MULT_MIN * 10, MARKET_OFFER_MULT_MAX * 10) / 10
	var/datum/market_offer/offer = new(id, chosen["path"], chosen["name"], rand(chosen["min"], chosen["max"]), multiplier, chosen["unit_price"], chosen["reagent"], chosen["volume"], !!chosen["subtypes"])
	offers += offer
	log_econ("Партнёр [name] выставил спецзаказ #[offer.uid]: [offer.quantity] x [offer.wanted_name] по [offer.unit_reward()] кр.")
	return offer

/datum/trade_partner/proc/check_unlock_rule(list/rule, list/partner_ids)
	if(!islist(rule) || length(rule) != (rule["partner"] ? 2 : 1))
		return "нужно {\"partner\": id, \"tier\": N} или {\"any_two_tier\": N}"
	var/tier = rule["partner"] ? rule["tier"] : rule["any_two_tier"]
	if(!isnum(tier) || tier < 1 || tier > PARTNER_TIER_MAX || round(tier) != tier)
		return "ступень - целое 1..[PARTNER_TIER_MAX]"
	if(rule["partner"] && (rule["partner"] == id || !(rule["partner"] in partner_ids)))
		return "нет такого партнёра [rule["partner"]]"

/datum/trade_partner/proc/tier()
	return clamp(round(reputation / PARTNER_TIER_STEP), 0, PARTNER_TIER_MAX)

/datum/trade_partner/proc/discount()
	var/static/list/discounts = list(0, 0.03, 0.07, 0.11, PARTNER_DISCOUNT_MAX)
	return discounts[tier() + 1]

/// Во сколько раз партнёр платит за товар против базовой цены; 0 - не покупает.
/datum/trade_partner/proc/buy_multiplier(commodity_id)
	if(!unlocked || embargoed())
		return 0
	if(isnum(buys[commodity_id]))
		return buys[commodity_id]
	return isnum(buys[PARTNER_ANY]) ? buys[PARTNER_ANY] : 0

/datum/trade_partner/proc/sells_pack(datum/supply_pack/pack)
	if(!unlocked || embargoed() || !econ_pack_traded(pack))
		return FALSE
	return sells_group(pack.group)

/datum/trade_partner/proc/sells_group(group)
	return (PARTNER_ANY in sells_groups) || (group in sells_groups)

/datum/trade_partner/proc/embargoed()
	return embargo_until > world.time

/datum/trade_partner/proc/stock_of(datum/supply_pack/pack)
	if(isnull(stock[pack.type]))
		stock[pack.type] = SSmarket.partner_stock_default
	return stock[pack.type]

/datum/trade_partner/proc/in_stock(datum/supply_pack/pack)
	return (PARTNER_ANY in sells_groups) || stock_of(pack) > 0

/datum/trade_partner/proc/pack_price(datum/supply_pack/pack, datum/bank_account/paying_account)
	return pack.market_cost(paying_account, src)

/// Цена пака по частям market_cost(); discount_mult - уже посчитанное 1 - partner.discount().
/proc/econ_pack_partner_cost(total, packaging, factor, datum/trade_partner/partner, discount_mult)
	if(partner)
		factor = max(factor * partner.markup * (isnull(discount_mult) ? 1 - partner.discount() : discount_mult), MARKET_PRICE_MIN)
	return round(packaging + (total - packaging) * factor)

/// Закупка вне станции (Deep Space, Тарков) берёт склад и платит партнёру, но репутации станции не даёт.
/datum/trade_partner/proc/note_purchase(datum/supply_pack/pack, price, gives_reputation = TRUE)
	if(!(PARTNER_ANY in sells_groups))
		stock[pack.type] = max(stock_of(pack) - 1, 0)
	wealth += price
	if(gives_reputation)
		add_reputation(price * SSmarket.reputation_per_credit / 2)
	SEND_SIGNAL(SSmarket, COMSIG_MARKET_TRADE, src, price, FALSE)

/datum/trade_partner/proc/note_sale(value)
	add_reputation(value * SSmarket.reputation_per_credit)
	SEND_SIGNAL(SSmarket, COMSIG_MARKET_TRADE, src, value, TRUE)

/datum/trade_partner/proc/add_reputation(amount)
	reputation = clamp(reputation + amount, 0, PARTNER_REPUTATION_MAX)
	SSmarket.check_unlocks()

/// Доход партнёра и пополнение склада за его счёт: пак обходится ему в долю своей цены.
/datum/trade_partner/proc/restock()
	wealth += base_income
	for(var/pack_type in stock)
		var/datum/supply_pack/pack = SSshuttle.supply_packs[pack_type]
		if(!pack)
			continue
		var/unit_cost = max(round(pack.market_cost() * PARTNER_PRODUCTION_SHARE), 1)
		while(stock[pack_type] < SSmarket.partner_stock_default && wealth >= unit_cost)
			wealth -= unit_cost
			stock[pack_type]++
