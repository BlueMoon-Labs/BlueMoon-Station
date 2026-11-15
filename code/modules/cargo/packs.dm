/datum/supply_pack
	var/name = "Crate"
	var/group = ""
	var/hidden = FALSE //Aka emag only
	var/contraband = FALSE //Requires a hacked console UNLESS DropPodOnly = TRUE, in which case it requires an emag
	var/cost = 700 // Minimum cost, or infinite points are possible.
	var/access = FALSE //What access does the Crate itself need?
	var/access_any = FALSE //Do we care about access?
	var/list/contains = null //What items are in the crate
	var/crate_name = "crate" //The crate that comes with each order
	var/desc = ""//no desc by default
	var/crate_type = /obj/structure/closet/crate //what kind of crate - Locked crates needed for access locked crates
	var/dangerous = FALSE // Should we message admins?
	var/special = FALSE //Event/Station Goals/Admin enabled packs
	var/special_enabled = FALSE
	var/DropPodOnly = FALSE //only usable by the Bluespace Drop Pod via the express cargo console
	var/admin_spawned = FALSE //Can only an admin spawn this crate?
	// this might be all in all unnecessary with current code if some changes are made
	var/goody = PACK_GOODY_NONE //Small items can be grouped into a single crate.They also come in a closet/lockbox instead of a full crate, so the 700 min doesn't apply
	var/can_private_buy = TRUE //Can it be purchased privately by each crewmember?
	/// If this pack comes shipped in a specific pod when launched from the express console
	var/special_pod
	/// BLUEMOON ADD - если задан, пак виден ТОЛЬКО консолям этих типов (list of /obj/machinery/computer/cargo/express typepaths), и не виден больше нигде
	var/list/exclusive_consoles
	/// ACCOUNT_* отдела: пак продаётся только в каталоге этого отдела и не виден консолям снабжения
	var/department_catalog
	/// id товара рынка, по которому идёт закупка; без него - по группе пака
	var/commodity

/datum/supply_pack/proc/generate(atom/A, datum/bank_account/paying_account)
	var/obj/structure/closet/crate/C
	if(paying_account)
		if(ispath(crate_type, /obj/structure/closet/secure_closet/cargo))	// lets ensure private orders don't come in crates when the original one comes in lockers
			C = new /obj/structure/closet/secure_closet/cargo/owned(A, paying_account)	// that would lead to infinite money exploits
		else
			C = new /obj/structure/closet/crate/secure/owned(A, paying_account)
		C.name = "[crate_name] - Purchased by [paying_account.account_holder]"
	else
		C = new crate_type(A)
		C.name = crate_name
	if(access)
		C.req_access = list(access)
	if(access_any)
		C.req_one_access = access_any

	fill(C)
	return C

/// Цена у текущего поставщика, см. econ_pack_price().
/datum/supply_pack/proc/get_cost(datum/bank_account/paying_account, allow_contraband = FALSE)
	return econ_pack_price(src, paying_account, allow_contraband)

/// Рынок, наценка и скидка партнёра двигают цену содержимого не ниже дна рынка; упаковка - залог и стоит столько, сколько NT за неё вернёт.
/datum/supply_pack/proc/market_cost(datum/bank_account/paying_account, datum/trade_partner/partner)
	var/total = market_total()
	var/datum/commodity/market_commodity = econ_pack_commodity(src)
	if(!market_commodity)
		return round(total)
	return econ_pack_partner_cost(total, market_packaging(paying_account, total), market_commodity.buy_factor(), partner)

/datum/supply_pack/proc/market_total()
	return cost * SSeconomy.pack_price_modifier

/datum/supply_pack/proc/market_packaging(datum/bank_account/paying_account, total)
	return min(econ_packaging_value(packaging_type(paying_account)), total)

/// Во что пак упакует отгрузка шаттла: малый пак - в кейс, частный заказ - в именной ящик или шкаф.
/datum/supply_pack/proc/packaging_type(datum/bank_account/paying_account)
	if(goody != PACK_GOODY_NONE)
		return /obj/item/storage/lockbox/order
	if(!paying_account)
		return crate_type
	if(ispath(crate_type, /obj/structure/closet/secure_closet/cargo))
		return /obj/structure/closet/secure_closet/cargo/owned
	return /obj/structure/closet/crate/secure/owned

/datum/supply_pack/proc/fill(obj/structure/closet/crate/C)
	if (admin_spawned)
		for(var/item in contains)
			var/atom/A = new item(C)
			A.flags_1 |= ADMIN_SPAWNED_1
	else
		for(var/item in contains)
			new item(C)

///Easily send a supplypod to an area
/proc/send_supply_pod_to_area(contents, area_type, pod_type = /obj/structure/closet/supplypod)
	var/list/areas = get_areas(area_type)
	if(!LAZYLEN(areas))
		return FALSE
	var/list/open_turfs = list()
	for(var/turf/open/floor/found_turf in get_area_turfs(pick(areas), subtypes = TRUE))
		open_turfs += found_turf

	if(!length(open_turfs))
		return FALSE

	new /obj/effect/pod_landingzone (pick(open_turfs), new pod_type (), contents)
	return TRUE
