#define CONTRABAND_CAP_WINDOW (1 HOURS)
/// Столько кредитов изъятий поднимают тренд контрабанды на 1
#define CONTRABAND_SEIZURE_TREND_SCALE 20000

/// Тип предмета -> TRUE; строится один раз на первом тике экономики
GLOBAL_LIST_EMPTY(econ_contraband_typecache)
/// Тип предмета -> цена в аплинке, ТК
GLOBAL_LIST_EMPTY(econ_contraband_tc)
/// Тип предмета -> самая низкая цена на чёрном рынке, кр.
GLOBAL_LIST_EMPTY(econ_contraband_market_price)
GLOBAL_VAR_INIT(econ_contraband_built, FALSE)
GLOBAL_VAR_INIT(econ_contraband_building, FALSE)
/// Здесь контрабанда - и сам тип, и все его подтипы; у остальных аплинк-предметов только точный тип
GLOBAL_LIST_INIT(econ_contraband_families, list(
	/obj/item/card/id/syndicate,
	/obj/item/card/id/inteq,
))
/// Есть в аплинке, но экипаж получает его и так
GLOBAL_LIST_INIT(econ_contraband_station_issued, list(
	/obj/item/melee/classic_baton/telescopic,
))
/// Автоматы только баз Синдиката и ЦК без замка доступа: их ассортимент остаётся контрабандой
GLOBAL_LIST_INIT(econ_contraband_offstation_vendors, list(
	/obj/machinery/vending/ultimateliberation,
	/obj/machinery/vending/wardrobe/syndie_wardrobe,
))

/datum/controller/subsystem/economy
	var/contraband_window_start = 0
	var/contraband_paid_in_window = 0

/datum/economy_department/security/on_economy_tick()
	. = ..()
	if(!GLOB.econ_contraband_built && !GLOB.econ_contraband_building)
		INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(econ_build_contraband_cache))

/// Сбой сборки не выключает изъятия на раунд: флаг сборки снимается всегда, следующий тик СБ пробует снова.
/proc/econ_build_contraband_cache()
	if(GLOB.econ_contraband_building)
		return
	GLOB.econ_contraband_building = TRUE
	try
		econ_collect_contraband_cache()
	catch(var/exception/error)
		log_econ("Сборка кэша контрабанды упала: [error] ([error.file]:[error.line])")
		stack_trace("econ_build_contraband_cache: сборка кэша контрабанды упала: [error] ([error.file]:[error.line])")
	GLOB.econ_contraband_building = FALSE

/proc/econ_collect_contraband_cache()
	var/list/tc_by_type = list()
	for(var/datum/uplink_item/uplink_type as anything in GLOB.uplink_items)
		var/item = initial(uplink_type.item)
		var/cost = initial(uplink_type.cost)
		if(ispath(item, /obj/item) && cost > 0)
			tc_by_type[item] = max(tc_by_type[item] || 0, cost)
	for(var/family in GLOB.econ_contraband_families)
		var/family_tc = tc_by_type[family]
		for(var/subtype in typesof(family))
			tc_by_type[subtype] = max(tc_by_type[subtype] || 0, family_tc || 0)
	var/list/station_made = econ_station_obtainable_types()
	var/list/cache = list()
	for(var/item in tc_by_type)
		if(!station_made[item])
			cache[item] = TRUE
	var/list/market_price = list()
	for(var/datum/blackmarket_item/market_type as anything in subtypesof(/datum/blackmarket_item))
		var/item = initial(market_type.item)
		if(!cache[item])
			continue
		var/price = initial(market_type.price) || initial(market_type.price_min)
		market_price[item] = isnull(market_price[item]) ? price : min(market_price[item], price)
	GLOB.econ_contraband_tc = tc_by_type
	GLOB.econ_contraband_market_price = market_price
	GLOB.econ_contraband_typecache = cache
	GLOB.econ_contraband_built = TRUE

/// Всё, что экипаж получает без аплинка: фабрикаторы, карго, автоматы и раздатчики очков, призы аркады, лут блюспейс-крана, снаряжение должностей и лоадаут. По типам, не по машинам на карте.
/proc/econ_station_obtainable_types()
	. = list()
	for(var/item in GLOB.econ_contraband_station_issued)
		.[item] = TRUE
	for(var/item in GLOB.arcade_prize_pool)
		.[item] = TRUE
	for(var/design_id in SSresearch.techweb_designs)
		var/datum/design/design = SSresearch.techweb_designs[design_id]
		if(design.build_path)
			.[design.build_path] = TRUE
	for(var/pack_type in SSshuttle.supply_packs)
		var/datum/supply_pack/pack = SSshuttle.supply_packs[pack_type]
		if(!length(pack.exclusive_consoles))
			for(var/item in pack.contains)
				.[item] = TRUE
	for(var/gear_type in subtypesof(/datum/gear))
		var/datum/gear/gear = gear_type
		var/item = initial(gear.path)
		if(item)
			.[item] = TRUE
	for(var/datum/job/job as anything in SSjob.occupations)
		if(job.faction != "Station")
			continue
		for(var/outfit_type in list(job.outfit, job.plasma_outfit))
			if(ispath(outfit_type, /datum/outfit))
				econ_note_outfit_items(outfit_type, .)
	for(var/spawner_type in typesof(/obj/effect/spawner/lootdrop/bluespace_tap))
		econ_note_loot_items(spawner_type, .)
	CHECK_TICK
	for(var/item in collect_vending_product_types(GLOB.econ_contraband_offstation_vendors, ACCESS_SYNDICATE, check_tick = TRUE))
		.[item] = TRUE

/proc/econ_note_outfit_items(outfit_type, list/found)
	var/datum/outfit/outfit = new outfit_type
	for(var/var_name in outfit.vars)
		if(var_name == "vars")
			continue
		var/value = outfit.vars[var_name]
		if(ispath(value, /obj/item))
			found[value] = TRUE
		else if(islist(value))
			for(var/entry in value)
				if(ispath(entry, /obj/item))
					found[entry] = TRUE
	qdel(outfit)

/// Спавнер вне карты не раскладывает лут и сразу удаляется, но его список читается.
/proc/econ_note_loot_items(spawner_type, list/found)
	var/obj/effect/spawner/lootdrop/spawner = new spawner_type(null)
	for(var/item in spawner.loot)
		if(ispath(item, /obj/effect/spawner/lootdrop))
			econ_note_loot_items(item, found)
		else if(ispath(item, /obj/item))
			found[item] = TRUE
	if(!QDELETED(spawner))
		qdel(spawner)

/proc/econ_is_contraband(obj/item/thing)
	if(!istype(thing) || !GLOB.econ_contraband_built)
		return FALSE
	return GLOB.econ_contraband_typecache[thing.type] || FALSE

/// Цена контрабанды без рынка: ТК аплинка по курсу настроек, стопка - по числу штук.
/proc/econ_contraband_base_value(obj/item/thing)
	var/datum/economy_settings/settings = SSeconomy.settings
	var/tc = GLOB.econ_contraband_tc[thing.type]
	if(!tc)
		return settings.contraband_value_default
	if(isstack(thing))
		var/obj/item/stack/stack = thing
		tc = tc * stack.amount / initial(stack.amount)
	return tc * settings.contraband_value_per_tc

/// Больше этого NT и Вольные торговцы за предмет не платят: текущая цена чёрного рынка, а за купленное - потолок выкупа; null - потолка нет.
/proc/econ_contraband_limit(obj/item/thing)
	var/market_price = GLOB.econ_contraband_market_price[thing.type]
	if(!isnull(market_price))
		. = econ_blackmarket_price(market_price)
	if(islist(thing.econ_print_cap))
		var/cap = econ_cap_value(thing.econ_print_cap)
		. = isnull(.) ? cap : min(., cap)

/// Цена изъятого в кредитах по рынку контрабанды; при unit_price - в кредитах оценки, которые NT оплачивает по этому прайсу. Вместе с премией офицеру выплата не выше потолка предмета.
/proc/econ_contraband_credits(obj/item/thing, unit_price = 1)
	if(!econ_is_contraband(thing))
		return 0
	var/datum/economy_settings/settings = SSeconomy.settings
	var/value = econ_contraband_base_value(thing) * econ_sale_factor(COMMODITY_CONTRABAND)
	var/limit = econ_contraband_limit(thing)
	if(!isnull(limit))
		value = min(value, limit * 100 / ((100 + settings.work_personal_share) * unit_price))
	return max(round(value), 0)

/// Оценка изъятия для оплаты работы СБ: кредиты оценки по прайсу WORK_SEC_CONTRABAND.
/proc/econ_contraband_value(obj/item/thing)
	return econ_contraband_credits(thing, max(SSeconomy.settings.work_prices[WORK_SEC_CONTRABAND] || 0, 1))

/// Цена лота чёрного рынка по рынку контрабанды.
/proc/econ_blackmarket_price(base)
	var/datum/commodity/contraband = SSmarket.get_commodity(COMMODITY_CONTRABAND)
	return round(base * (contraband ? contraband.buy_factor() : 1), 1)

/// Контрабанду покупает только контрабандный партнёр и только с отгрузкой с допуском контрабанды; иначе она возвращается шаттлом. Вне рынка станции (пиратский пад) - обычные экспорты.
/datum/export/contraband
	cost = 0
	unit_name = "contraband item"
	message = "for the free traders"
	commodity = COMMODITY_CONTRABAND

/datum/export/contraband/applies_to(obj/O, allowed_categories = NONE, apply_elastic = TRUE)
	if(!apply_elastic || (allowed_categories & export_category) != export_category || (O.flags_1 & HOLOGRAM_1))
		return FALSE
	return econ_is_contraband(O)

/// sell_object умножит цену на рыночный множитель, поэтому потолок делится на него заранее.
/datum/export/contraband/get_cost(obj/O, allowed_categories = NONE, apply_elastic = TRUE)
	. = econ_contraband_base_value(O)
	if(!apply_elastic)
		return round(.)
	var/limit = econ_contraband_limit(O)
	var/factor = econ_export_sale_factor(src, O)
	if(!isnull(limit) && factor > 0)
		. = min(., FLOOR(limit / factor, 1))
	return round(.)

/datum/export/contraband/sell_object(obj/O, datum/export_report/report, dry_run = TRUE, allowed_categories = EXPORT_CARGO, apply_elastic = TRUE)
	if(!(allowed_categories & EXPORT_CONTRABAND) || !SSmarket.contraband_buyer())
		report.embargoed |= O
		return FALSE
	var/value_before = report.total_value[src]
	. = ..()
	if(. && !dry_run && O.fingerprintslast)
		SSmarket.contraband_exported_by[O.fingerprintslast] += report.total_value[src] - value_before

/datum/controller/subsystem/market
	/// ckey последнего касавшегося -> сколько кредитов контрабанды продано Вольным торговцам
	var/list/contraband_exported_by = list()

/// Открытый контрабандный партнёр, который покупает контрабанду, или null.
/datum/controller/subsystem/market/proc/contraband_buyer()
	for(var/id in partners)
		var/datum/trade_partner/partner = partners[id]
		if(partner.contraband && partner.buy_multiplier(COMMODITY_CONTRABAND) > 0)
			return partner

/// Взлом консоли снабжения открывает контрабандных партнёров тихо: без новостей и без переноса в следующую смену.
/datum/controller/subsystem/market/proc/open_contraband_partners(mob/user)
	for(var/id in partners)
		var/datum/trade_partner/partner = partners[id]
		if(!partner.contraband || partner.unlocked)
			continue
		partner.unlocked = TRUE
		log_econ("[key_name(user)] открыл контрабандного партнёра [partner.name] ([partner.id]) взломом консоли снабжения")
		SEND_SIGNAL(src, COMSIG_MARKET_PARTNER_UNLOCKED, partner)
		. = TRUE

/// Изъятая контрабанда уходит с рынка сектора: её тренд и цены чёрного рынка растут.
/datum/controller/subsystem/market/proc/note_seizure(value)
	var/datum/commodity/contraband = get_commodity(COMMODITY_CONTRABAND)
	if(!contraband || value <= 0)
		return
	contraband.trend += value / CONTRABAND_SEIZURE_TREND_SCALE
	contraband.recompute()

/proc/econ_sol_inspection_active()
	for(var/datum/team/sol_inspection/inspection in GLOB.antagonist_teams)
		if(inspection.visited_station && !inspection.returned_home)
			return TRUE
	return FALSE

/// Шанс таможенного досмотра ящика: базовый, выше во время инспекции Sol и при красном коде и выше.
/proc/econ_customs_chance()
	var/datum/economy_settings/settings = SSeconomy.settings
	. = settings.customs_chance
	if(econ_sol_inspection_active())
		. += settings.customs_chance_inspection
	if(GLOB.security_level >= SEC_LEVEL_RED)
		. += settings.customs_chance_alert
	return clamp(., 0, 100)

/// Таможня NT досматривает отгружаемый ящик: найденная контрабанда изымается, остальное остаётся в грузе, штраф платит отдел накладной ящика или снабжение. Высыпанное из изъятого ящика попадает в released. Возвращает оценку изъятого.
/proc/econ_customs_scan(atom/movable/crate, datum/export_report/report, list/released)
	. = 0
	var/list/found = list()
	for(var/obj/item/thing in crate.GetAllContents())
		if(econ_is_contraband(thing))
			found += thing
	if(!length(found) || !prob(econ_customs_chance()))
		return
	var/obj/item/export_manifest/manifest = econ_crate_manifest(crate)
	var/datum/economy_department/payer = (manifest && SSeconomy.get_department(manifest.department_id)) || SSeconomy.get_department(ACCOUNT_CAR)
	var/list/seized_names = list()
	for(var/obj/item/thing as anything in found)
		. += econ_contraband_credits(thing)
		seized_names += "[thing] ([thing.type], отпечатки [thing.fingerprintslast || "нет"])"
	for(var/obj/item/thing as anything in found)
		if(QDELETED(thing))
			continue
		if(thing == crate)
			econ_release_non_contraband(thing, crate.drop_location(), released)
		else
			econ_release_non_contraband(thing, thing.loc)
		qdel(thing)
	var/fine = round(. * SSeconomy.settings.customs_fine_share / 100)
	var/paid = clamp(payer.account.account_balance, 0, fine)
	if(paid && !payer.account.debit(paid, ECON_FINE_CUSTOMS, memo = "Таможня NT: изъята контрабанда"))
		paid = 0
	payer.add_owed(fine - paid)
	SSmarket.note_seizure(.)
	if(report)
		report.customs_seized += length(found)
		report.customs_value += .
		if(fine)
			report.customs_fines[payer.name] += fine
	log_econ("Таможня NT изъяла из отгрузки: [jointext(seized_names, ", ")]. Оценка [.] кр., штраф отделу [payer.name] [fine] кр.")

/// Из изымаемого контейнера всё, что не контрабанда, высыпается в drop и попадает в released; вложенная контрабанда уходит вместе с ним.
/proc/econ_release_non_contraband(atom/container, atom/drop, list/released)
	for(var/atom/movable/content as anything in container.contents)
		if(econ_is_contraband(content))
			econ_release_non_contraband(content, drop, released)
		else
			content.forceMove(drop)
			released?.Add(content)

/// Сколько NT ещё заплатит СБ за изъятия в текущем часовом окне.
/datum/controller/subsystem/economy/proc/contraband_cap_left()
	if(world.time - contraband_window_start > CONTRABAND_CAP_WINDOW)
		contraband_window_start = world.time
		contraband_paid_in_window = 0
	return max(settings.contraband_cap_hour - contraband_paid_in_window, 0)

/datum/controller/subsystem/economy/proc/note_contraband_paid(amount)
	contraband_cap_left()
	contraband_paid_in_window += amount

#undef CONTRABAND_CAP_WINDOW
#undef CONTRABAND_SEIZURE_TREND_SCALE
