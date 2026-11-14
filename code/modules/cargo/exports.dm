/* How it works:
 The shuttle arrives at CentCom dock and calls sell(), which recursively loops through all the shuttle contents that are unanchored.

 Each object in the loop is checked for applies_to() of various export datums, except the invalid ones.
*/

/* The rule in figuring out item export cost:
 Export cost of goods in the shipping crate must be always equal or lower than:
  packcage cost - crate cost - manifest cost
 Crate cost is 500cr for a regular plasteel crate and 100cr for a large wooden one. Manifest cost is always 200cr.
 This is to avoid easy cargo points dupes.

Credit dupes that require a lot of manual work shouldn't be removed, unless they yield too much profit for too little work.
 For example, if some player buys metal and glass sheets and uses them to make and sell reinforced glass:

 100 glass + 50 metal -> 100 reinforced glass
 (1500cr -> 1600cr)

 then the player gets the profit from selling his own wasted time.
*/

// Simple holder datum to pass export results around
/datum/export_report
	var/list/exported_atoms = list()//names of atoms sold/deleted by export
	var/list/total_amount = list()  //export instance => total count of sold objects of its type, only exists if any were sold
	var/list/total_value = list()   //export instance => total value of sold objects
	var/list/reagents_volume = list()//export reagents => into the total volume of the object sold
	var/list/reagents_value = list()//export reagents => into the reagent type total value.
	var/list/exported_atoms_ref = list()	//if they're not deleted they go in here for use.
	/// Товар рынка -> выручка: спрос снимается разом после оценки всей отгрузки
	var/list/market_sales = list()
	/// Партнёр -> выручка, за которую он даёт репутацию; купленное через снабжение сюда не входит
	var/list/partner_sales = list()
	/// Товары без открытого покупателя: при отгрузке не уничтожаются и возвращаются
	var/list/embargoed = list()
	/// Строки сообщения ЦК о спецзаказах, засчитанных в этой отгрузке
	var/list/offer_notes = list()
	/// То же о спецзаказах контрабандного партнёра: их видит только взломанная консоль снабжения
	var/list/contraband_notes = list()
	/// Изъято таможней NT: штук, оценка, имя отдела -> штраф
	var/customs_seized = 0
	var/customs_value = 0
	var/list/customs_fines = list()

/datum/export_report/proc/note_market_sale(datum/commodity/market_commodity, value, atom/movable/thing, allow_contraband = FALSE)
	if(!market_commodity || value <= 0)
		return
	market_sales[market_commodity] += value
	var/datum/trade_partner/buyer = SSmarket.best_buyer(market_commodity.id, allow_contraband)
	if(buyer && !thing?.econ_imported)
		partner_sales[buyer] += value

/datum/export_report/proc/settle_market()
	for(var/datum/commodity/market_commodity as anything in market_sales)
		market_commodity.note_sale(market_sales[market_commodity])
	market_sales.Cut()
	for(var/datum/trade_partner/partner as anything in partner_sales)
		partner.note_sale(partner_sales[partner])
	partner_sales.Cut()

// external_report works as "transaction" object, pass same one in if you're doing more than one export in single go
/// apply_caps без рынка (apply_elastic = FALSE) всё равно ограничивает цену купленного и собранного на станции.
/proc/export_item_and_contents(atom/movable/AM, allowed_categories = EXPORT_CARGO, apply_elastic = TRUE, delete_unsold = TRUE, dry_run=FALSE, datum/export_report/external_report, apply_caps = FALSE)
	if(!GLOB.exports_list.len)
		setupExports()

	var/allow_contraband = allowed_categories & EXPORT_CONTRABAND

	var/list/contents = AM.GetAllContents()

	var/datum/export_report/report = external_report
	if(!report) //If we don't have any longer transaction going on
		report = new

	// We go backwards, so it'll be innermost objects sold first
	for(var/i in reverseRange(contents))
		var/atom/movable/thing = i
		var/sold = FALSE
		for(var/datum/export/E in GLOB.exports_list)
			if(!E)
				continue
			if(E.applies_to(thing, allowed_categories, apply_elastic))
				sold = E.sell_object(thing, report, dry_run, allowed_categories , apply_elastic, apply_caps)
				report.exported_atoms += " [thing.name]"
				break
		if(thing in report.embargoed)
			if(!dry_run && thing != AM)
				thing.forceMove(get_turf(AM))
			continue
		if(thing.reagents?.value_multiplier)
			for(var/A in thing.reagents.reagent_list)
				var/datum/reagent/R = A
				if(!R.value)
					continue
				var/list/print_reagents = thing.econ_print_reagents
				var/reagent_value = max(R.volume - (print_reagents ? print_reagents[R.type] : 0), 0) * R.value * thing.reagents.value_multiplier
				if(apply_elastic)
					reagent_value *= econ_reagent_sale_factor(R, thing, allow_contraband)
					if(!dry_run)
						report.note_market_sale(econ_reagent_commodity(R), reagent_value, thing, allow_contraband)
				else if(apply_caps && thing.econ_imported)
					reagent_value *= min(1, econ_import_resale_factor())
				report.reagents_volume[R.name] += R.volume
				report.reagents_value[R.name] += round(reagent_value)
		if(!dry_run && (sold || delete_unsold))
			if(ismob(thing))
				thing.investigate_log("deleted through cargo export",INVESTIGATE_CARGO)
			if(ismecha(thing))
				var/obj/vehicle/sealed/mecha/mech = thing
				mech.wreckage = null // why a mech left a wreck when sold i will never know
			qdel(thing)

	if(!external_report)
		report.settle_market()
	return report

/datum/export
	var/unit_name = ""				// Unit name. Only used in "Received [total_amount] [name]s [message]." message
	var/message = ""
	var/cost = 100					// Cost of item, in cargo credits. Must not alow for infinite price dupes, see above.
	/// id товара рынка: от него зависят цена продажи и спрос; без товара цена не меняется
	var/commodity
	var/list/export_types = list()	// Type of the exported object. If none, the export datum is considered base type.
	var/include_subtypes = TRUE		// Set to FALSE to make the datum apply only to a strict type.
	var/list/exclude_types = list()	// Types excluded from export

	var/init_cost

	//All these need to be present in export call parameter for this to apply.
	var/export_category = EXPORT_CARGO

/datum/export/New()
	..()
	init_cost = cost
	export_types = typecacheof(export_types)
	exclude_types = typecacheof(exclude_types)

// Checks the base cost, without the market. 0 cost items are skipped in export.
/datum/export/proc/get_cost(obj/O, allowed_categories = NONE, apply_elastic = TRUE)
	return round(init_cost * get_amount(O))

/// Часть get_cost(), которая приходится на содержимое (газ и подобное), а не на сам предмет.
/datum/export/proc/contents_cost(obj/O)
	return 0

// Checks the amount of exportable in object. Credits in the bill, sheets in the stack, etc.
// Usually acts as a multiplier for a cost, so item that has 0 amount will be skipped in export.
/datum/export/proc/get_amount(obj/O)
	return TRUE

// Checks if the item is fit for export datum.
/datum/export/proc/applies_to(obj/O, allowed_categories = NONE, apply_elastic = TRUE)
	if((allowed_categories & export_category) != export_category)
		return FALSE
	if(!include_subtypes && !(O.type in export_types))
		return FALSE
	if(include_subtypes && (!is_type_in_typecache(O, export_types) || is_type_in_typecache(O, exclude_types)))
		return FALSE
	if(!get_cost(O, allowed_categories , apply_elastic))
		return FALSE
	if(O.flags_1 & HOLOGRAM_1)
		return FALSE
	return TRUE

// Called only once, when the object is actually sold by the datum.
// Adds item's cost and amount to the current export cycle.
// get_cost, get_amount and applies_to do not neccesary mean a successful sale.
/datum/export/proc/sell_object(obj/O, datum/export_report/report, dry_run = TRUE, allowed_categories = EXPORT_CARGO , apply_elastic = TRUE, apply_caps = FALSE)
	var/the_cost = get_cost(O, allowed_categories , apply_elastic)
	var/amount = get_amount(O)

	var/profit_ratio = 0

	if(amount <=0 || the_cost <=0)
		return FALSE

	if(apply_elastic || apply_caps)
		var/allow_contraband = allowed_categories & EXPORT_CONTRABAND
		var/sale_factor
		if(apply_elastic)
			sale_factor = econ_export_sale_factor(src, O, allow_contraband)
		else
			sale_factor = O.econ_imported ? min(1, econ_import_resale_factor()) : 1
		if(!sale_factor)
			report.embargoed |= O
			return FALSE
		the_cost = round(the_cost * sale_factor)
		if(islist(O.econ_print_cap))
			var/contents_part = round(contents_cost(O) * sale_factor)
			the_cost = min(the_cost - contents_part, econ_cap_value(O.econ_print_cap)) + contents_part
		if(apply_elastic && !dry_run)
			report.note_market_sale(econ_export_commodity(src), the_cost, O, allow_contraband)

	if(dry_run == FALSE)
		if(SEND_SIGNAL(O, COMSIG_ITEM_SOLD, item_value = the_cost) & COMSIG_ITEM_SPLIT_VALUE)
			profit_ratio = SEND_SIGNAL(O, COMSIG_ITEM_SPLIT_PROFIT)
			the_cost = the_cost*((100-profit_ratio)/100)
	else
		profit_ratio = SEND_SIGNAL(O, COMSIG_ITEM_SPLIT_PROFIT)
		the_cost = the_cost*((100-profit_ratio)/100)

	report.total_value[src] += the_cost

	if(istype(O, /datum/export/material))
		report.total_amount[src] += amount*MINERAL_MATERIAL_AMOUNT
	else
		report.total_amount[src] += amount

	if(!dry_run)
		SSblackbox.record_feedback("nested tally", "export_sold_cost", 1, list("[O.type]", "[the_cost]"))
	return TRUE

// Total printout for the cargo console.
// Called before the end of current export cycle.
// It must always return something if the datum adds or removes any credts.
/datum/export/proc/total_printout(datum/export_report/ex, notes = TRUE)
	if(!ex.total_amount[src] || !ex.total_value[src])
		return ""

	var/total_value = ex.total_value[src]
	var/total_amount = ex.total_amount[src]

	var/msg = "[total_value] credits: Received [total_amount] "
	if(total_value > 0)
		msg = "+" + msg

	if(unit_name)
		msg += unit_name
		if(total_amount > 1)
			msg += "s"
		if(message)
			msg += " "

	if(message)
		msg += message

	msg += "."
	return msg

GLOBAL_LIST_EMPTY(exports_list)

/proc/setupExports()
	for(var/subtype in subtypesof(/datum/export))
		var/datum/export/E = new subtype
		// Контрабанду первым забирает её экспорт без списка типов: другой экспорт продал бы её NT
		if(istype(E, /datum/export/contraband))
			GLOB.exports_list.Insert(1, E)
			continue
		if(E.export_types && E.export_types.len) // Exports without a type are invalid/base types
			GLOB.exports_list += E
