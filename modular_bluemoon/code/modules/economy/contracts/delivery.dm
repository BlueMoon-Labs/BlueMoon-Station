/datum/econ_contract/delivery
	var/datum/bounty/bounty

/datum/econ_contract/delivery/New(department_id, datum/bounty/bounty)
	..()
	set_bounty(bounty)

/datum/econ_contract/delivery/proc/set_bounty(datum/bounty/new_bounty)
	bounty = new_bounty
	title = bounty.name
	desc = bounty.description
	reward = bounty.reward

/datum/econ_contract/delivery/Destroy()
	QDEL_NULL(bounty)
	return ..()

/// Награда заказа с учётом спроса: особые заказы ЦК от повторов не дешевеют.
/datum/econ_contract/delivery/payout()
	. = ..() * SSeconomy.bounty_modifier * SSeconomy.settings.contract_delivery_mult
	if(owner)
		. *= SSeconomy.settings.contract_personal_reward / 100
	if(!pinned && bounty)
		. *= SSeconomy.contract_demand_mult(bounty.type)
	return round(.)

/datum/econ_contract/delivery/complete(mob/performer)
	if(completed)
		return
	var/bounty_type = bounty.type
	var/repeats = !pinned
	..()
	if(repeats)
		SSeconomy.note_contract_demand(bounty_type)

/datum/econ_contract/delivery/ui_entry()
	. = ..()
	.["demand"] = pinned ? 100 : round(SSeconomy.contract_demand_mult(bounty.type) * 100)

/datum/econ_contract/delivery/has_progress()
	var/datum/bounty/item/item_bounty = bounty
	if(istype(item_bounty))
		return item_bounty.shipped_count > 0
	var/datum/bounty/reagent/reagent_bounty = bounty
	if(istype(reagent_bounty))
		return reagent_bounty.shipped_volume > 0
	var/datum/bounty/virus/virus_bounty = bounty
	if(istype(virus_bounty))
		return virus_bounty.shipped
	var/datum/bounty/lewd/lewd_bounty = bounty
	if(istype(lewd_bounty))
		return lewd_bounty.shipped_volume > 0
	return FALSE

/datum/econ_contract/delivery/proc/wants(atom/movable/thing)
	if(owner && !taker)
		return FALSE
	return !completed && !is_expired() && !thing.econ_imported && bounty.applies_to(thing)

/datum/econ_contract/delivery/proc/ship(atom/movable/thing, mob/performer)
	note_contribution(performer)
	bounty.ship(thing)
	if(bounty.can_claim())
		complete(performer)

/datum/econ_contract/delivery/progress_text()
	return bounty.completion_string()

/atom/movable
	/// Куплено через снабжение: контракты поставки такое не засчитывают
	var/econ_imported = FALSE

/// Метит содержимое отгрузки; сама упаковка - залог и не метится.
/proc/econ_mark_imported(atom/movable/shipment)
	for(var/atom/movable/thing as anything in shipment.GetAllContents() - shipment)
		thing.econ_imported = TRUE

/atom/movable
	/// Куплено в торговом автомате
	var/econ_vended = FALSE

/// Товар автомата или чёрного рынка куплен: NT выкупает его не дороже доли уплаченного, вложенное и реагенты из покупки не оплачивает.
/proc/econ_mark_vended(atom/movable/product, price)
	for(var/atom/movable/part as anything in product.GetAllContents())
		part.econ_imported = TRUE
		part.econ_vended = TRUE
		part.econ_print_cap = list("" = part == product ? price * econ_import_resale_factor() : 0)
		if(!part.reagents?.total_volume)
			continue
		part.econ_print_reagents = list()
		for(var/datum/reagent/reagent as anything in part.reagents.reagent_list)
			part.econ_print_reagents[reagent.type] += reagent.volume

/obj/machinery/vending/examine(mob/user)
	. = ..()
	. += econ_price_examine()
	. += span_notice("Купленное здесь NT выкупает не дороже [round(econ_import_resale_factor() * 100)]% уплаченного, реагенты из автомата не оплачивает, контракты и спецзаказы такое не засчитывают.")

/// Цены по индексу и куда уходит выручка; у кастомного автомата свои правила в rent_examine().
/obj/machinery/vending/proc/econ_price_examine()
	. = list()
	if(!onstation)
		return
	. += span_notice("Цены автомата следуют индексу цен сектора, сейчас ×[round(last_price_index, 0.01)]. Автомат пересчитывает их, когда индекс уходит больше чем на [MARKET_VENDING_REFRESH_SHARE * 100]%.")
	var/datum/bank_account/owner = SSeconomy.get_dep_account(payment_department)
	var/wholesale = SSeconomy.settings.vend_wholesale_share
	if(!owner)
		. += span_notice("Вся выручка автомата уходит NT как оптовая себестоимость.")
		return
	. += span_notice("[wholesale]% выручки - оптовая себестоимость NT, [100 - wholesale]% получает [econ_budget_name(owner)]. Сотрудники этого отдела платят [DEPARTMENT_DISCOUNT * 100]% цены, кроме премиальных позиций.")
	var/premium_sink = SSeconomy.settings.vend_premium_sink_share
	. += span_notice("Премиальные позиции - наценка NT: [premium_sink]% их цены уходит NT, [econ_budget_name(owner)] получает [100 - premium_sink]%.")

/obj/machinery/vending/custom/econ_price_examine()
	return list()

/// Сколько вещей в thing подошло бы под контракт поставки, если бы не было куплено через снабжение.
/proc/econ_contracts_imported_matches(atom/movable/thing)
	. = 0
	var/list/contracts = econ_delivery_contracts_for(null)
	for(var/atom/movable/item as anything in econ_contract_candidates(thing))
		if(!item.econ_imported)
			continue
		for(var/datum/econ_contract/delivery/contract as anything in contracts)
			if(!contract.completed && contract.bounty.applies_to(item))
				.++
				break

/// Контракты поставки в порядке, в котором им достаются предметы: свои взятые, ничьи, чужие взятые.
/proc/econ_delivery_contracts_for(datum/bank_account/shipper)
	var/list/own = list()
	var/list/free = list()
	var/list/others = list()
	for(var/datum/econ_contract/delivery/contract in SSeconomy.all_contracts())
		if(!contract.taker)
			free += contract
		else if(contract.taker == shipper)
			own += contract
		else
			others += contract
	return own + free + others

/// Предмет и всё внутри него, вложенное раньше вложившего; игроков и их вещи не трогает.
/proc/econ_contract_candidates(atom/movable/thing, list/found = list())
	if(ismob(thing))
		var/mob/shipped_mob = thing
		if(shipped_mob.mind || shipped_mob.key)
			return found
	for(var/atom/movable/inner as anything in thing.contents)
		econ_contract_candidates(inner, found)
	found += thing
	return found

/// Засчитывает предмет и его содержимое по контрактам поставки и удаляет засчитанное. TRUE, если засчитано хоть что-то.
/proc/econ_contracts_ship(atom/movable/thing, mob/shipper)
	. = FALSE
	var/list/contracts = econ_delivery_contracts_for(econ_account_of(shipper))
	if(!length(contracts))
		return
	for(var/atom/movable/item as anything in econ_contract_candidates(thing))
		for(var/datum/econ_contract/delivery/contract as anything in contracts)
			if(QDELETED(contract) || !contract.wants(item))
				continue
			contract.ship(item, shipper)
			. = TRUE
			if(!QDELETED(item))
				qdel(item)
			break
