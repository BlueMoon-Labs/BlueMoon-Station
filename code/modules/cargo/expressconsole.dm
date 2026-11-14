#define COOLDOWN_EXPRESSPOD_CONSOLE "expresspod_console"
#define MAX_EMAG_ROCKETS 5
/// Скидка взломанной консоли на содержимое пака; ящик-залог идёт по полной цене
#define EMAG_ROCKETS_DISCOUNT 0.72
#define SP_LINKED 1
#define SP_READY 2
#define SP_LAUNCH 3
#define SP_UNLINK 4
#define SP_UNREADY 5

/obj/machinery/computer/cargo/express
	name = "express supply console"
	desc = "Консоль экспресс-доставки: пак прилетает капсулой почти сразу, а его цена у партнёра списывается в момент заказа - с бюджета снабжения или, в режиме частного заказа, с личного счёта карты. Частные малые кейсы покупаются только с личного счёта."
	icon_screen = "supply_express"
	circuit = /obj/item/circuitboard/computer/cargo/express
	blockade_warning = "Bluespace instability detected. Delivery impossible."
	req_access = list(ACCESS_QM)
	is_express = TRUE
	can_send = FALSE
	can_approve_requests = FALSE
	icon_screen = "supply_express"

	var/message
	/// Версия цен, по которой собран meme_pack_data
	var/prices_version = 0
	var/printed_beacons = 0 //number of beacons printed. Used to determine beacon names.
	var/list/meme_pack_data
	var/obj/item/supplypod_beacon/beacon //the linked supplypod beacon
	var/area/landingzone = /area/cargo/storage //where we droppin boys
	var/podType = /obj/structure/closet/supplypod
	var/cooldown = 0 //cooldown to prevent printing supplypod beacon spam
	var/locked = TRUE //is the console locked? unlock with ID
	var/usingBeacon = FALSE //is the console in beacon mode? exists to let beacon know when a pod may come in
	var/department_account = ACCOUNT_CAR // BLUEMOON ADD - какой ведомственный счёт использует консоль
	var/exclusive_pack_pool = FALSE // BLUEMOON ADD - если TRUE, консоль видит ТОЛЬКО паки, в чьём exclusive_consoles есть её тип
	var/access_hint = "a Quartermaster ID card" // BLUEMOON ADD
	var/show_landing_location = TRUE
	var/beacon_only = FALSE // если TRUE, консоль не может доставлять в станционный Cargo Bay, только через маячок
	var/station_only = TRUE // BLUEMOON ADD - если TRUE, консоль работает только на Z-уровне станции (ZTRAIT_STATION)

/obj/machinery/computer/cargo/express/Initialize(mapload)
	. = ..()
	if(beacon_only)
		usingBeacon = TRUE
	packin_up()

/obj/machinery/computer/cargo/express/on_construction(mob/user)
	. = ..()
	packin_up()

/obj/machinery/computer/cargo/express/Destroy()
	if(beacon)
		beacon.unlink_console()
	return ..()

/obj/machinery/computer/cargo/express/attackby(obj/item/W, mob/living/user, params)
	if(W.GetID() && allowed(user))
		locked = !locked
		to_chat(user, span_notice("You [locked ? "lock" : "unlock"] the interface."))
		return
	else if(istype(W, /obj/item/disk/cargo/bluespace_pod))
		podType = /obj/structure/closet/supplypod/bluespacepod//doesnt effect circuit board, making reversal possible
		to_chat(user, span_notice("You insert the disk into [src], allowing for advanced supply delivery vehicles."))
		qdel(W)
		return TRUE
	else if(istype(W, /obj/item/supplypod_beacon))
		var/obj/item/supplypod_beacon/sb = W
		if (sb.express_console != src)
			sb.link_console(src, user)
			return TRUE
		else
			to_chat(user, span_alert("[src] is already linked to [sb]."))
	..()

/obj/machinery/computer/cargo/express/emag_act(mob/user, obj/item/card/emag/emag_card)
	if(obj_flags & EMAGGED)
		return FALSE
	if(user)
		if (emag_card)
			user.visible_message(span_warning("[user] swipes [emag_card] through [src]!"))
		to_chat(user, span_notice("You change the routing protocols, allowing the Supply Pod to land anywhere on the station."))
	obj_flags |= EMAGGED
	contraband = TRUE
	// This also sets this on the circuit board
	var/obj/item/circuitboard/computer/cargo/board = circuit
	board.obj_flags |= EMAGGED
	board.contraband = TRUE
	packin_up()
	update_static_data_for_all_viewers()
	return TRUE

/* BLUEMOON CHANGE выносим переписанный  текст "Oh shit. I'm sorry" отдельным комментарием чтобы не засирать код
oh shit, I'm sorry
sorry for what?
our quartermaster taught us not to be ashamed of our supply packs
specially since they're such a good price and all
yeah, I see that, your quartermaster gave you good advice
it gets cheaper when I return it
mmhm
sometimes, I return it so much, I rip the manifest
see, my quartermaster taught me a few things too
like, how not to rip the manifest
by using someone else's crate
will you show me?
i'd be right happy to */

/obj/machinery/computer/cargo/express/proc/packin_up(forced = FALSE)
	meme_pack_data = list()
	catalog_ids = list()
	// BLUEMOON ADD TG UPSTREAM PULL
	if(!forced && !SSshuttle.initialized)
		SSshuttle.express_consoles += src
		return
	// BLUEMOON ADD END
	GLOB.econ_cargo_prices.refresh()
	prices_version = GLOB.econ_cargo_prices.version
	for(var/pack in SSshuttle.supply_packs)
		var/datum/supply_pack/P = SSshuttle.supply_packs[pack]

		// BLUEMOON ADD - эксклюзивные паки видны только своим консолям, остальным консолям недоступны
		if(P.exclusive_consoles && !is_type_in_list(src, P.exclusive_consoles))
			continue
		// BLUEMOON ADD END

		if(P.department_catalog)
			continue
		if(!meme_pack_data[P.group])
			meme_pack_data[P.group] = list(
				"name" = P.group,
				"packs" = list()
			)
		if(!offers_pack(P))
			continue
		var/list/entry = econ_cargo_pack_entry(P, FALSE)
		entry["name"] = P.name
		entry["id"] = pack
		meme_pack_data[P.group]["packs"] += list(entry)
		catalog_ids[pack] = TRUE

/// Пак есть в каталоге этой консоли и заказывается с неё.
/obj/machinery/computer/cargo/express/proc/offers_pack(datum/supply_pack/pack)
	if(pack.department_catalog || pack.hidden || pack.special)
		return FALSE
	if(pack.exclusive_consoles && !is_type_in_list(src, pack.exclusive_consoles))
		return FALSE
	return !pack.contraband || contraband

/// Консоль платит бюджетом станции, а не Deep Space или Тарков: только её закупки дают партнёрам репутацию.
/obj/machinery/computer/cargo/express/proc/station_budget()
	return !(department_account in list(ACCOUNT_DS, ACCOUNT_TAR))

/// Цена содержимого пака во взломе: со скидкой, но не ниже дна рынка, иначе выкуп купленного окупал бы заказ.
/obj/machinery/computer/cargo/express/proc/emag_contents_price(datum/supply_pack/pack, datum/bank_account/paying_account)
	var/unit_cost = pack.get_cost(paying_account)
	var/packaging = min(pack.market_packaging(paying_account, pack.market_total()), unit_cost)
	var/contents = unit_cost - packaging
	return max(round(contents * EMAG_ROCKETS_DISCOUNT), min(round((pack.market_total() - packaging) * MARKET_PRICE_MIN), contents))

/// Взломанная консоль бросает капсулы в случайную зону станции.
/obj/machinery/computer/cargo/express/proc/emag_landing_area()
	return GLOB.areas_by_type[pick(GLOB.the_station_areas)]

/obj/machinery/computer/cargo/express/ui_interact(mob/user, datum/tgui/ui)
	if(station_only && !is_station_level(z)) // BLUEMOON ADD - работает только на Z-уровне станции
		to_chat(user, span_warning("[src] shows no connection to the supply network: you are outside the station's orbit."))
		return
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CargoExpress", name)
		ui.open()

/obj/machinery/computer/cargo/express/ui_data(mob/user)
	var/canBeacon = beacon && (isturf(beacon.loc) || ismob(beacon.loc))
	var/list/data = list()
	var/datum/bank_account/D = SSeconomy.get_dep_account(department_account)
	if(D)
		data["points"] = D.account_balance
	data["budget_name"] = econ_budget_name(D)
	data["self_paid"] = self_paid
	data["locked"] = locked
	data["siliconUser"] = hasSiliconAccessInArea(user)
	data["beaconzone"] = beacon ? get_area(beacon) : ""
	data["usingBeacon"] = usingBeacon
	data["canBeacon"] = !usingBeacon || canBeacon
	data["canBuyBeacon"] = cooldown <= 0 && D.account_balance >= EXPRESS_BEACON_COST
	data["beaconError"] = usingBeacon && !canBeacon ? "(BEACON ERROR)" : ""
	data["hasBeacon"] = beacon != null
	data["beaconName"] = beacon ? beacon.name : "No Beacon Found"
	data["printMsg"] = cooldown > 0 ? "Напечатать маяк за [EXPRESS_BEACON_COST] кр. ([cooldown])" : "Напечатать маяк за [EXPRESS_BEACON_COST] кр."
	data["department_account"] = department_account // BLUEMOON ADD
	data["access_hint"] = access_hint // BLUEMOON ADD
	data["beacon_only"] = beacon_only
	data += econ_cargo_viewer_data(user)
	message = "Sales are near-instantaneous - please choose carefully."
	if(SSshuttle.supplyBlocked)
		message = blockade_warning
	if(usingBeacon && !beacon)
		message = "BEACON ERROR: BEACON MISSING"//beacon was destroyed
	else if (usingBeacon && !canBeacon)
		message = "BEACON ERROR: MUST BE EXPOSED"//beacon's loc/user's loc must be a turf
	if(obj_flags & EMAGGED)
		message = "(&!#@ERROR: R0UTING_#PRO7O&OL MALF(*CT#ON. $UG%ESTE@ ACT#0N: !^/PULS3-%E)ET CIR*)ITB%ARD."
	data["message"] = message
	GLOB.econ_cargo_prices.refresh()
	if(prices_version != GLOB.econ_cargo_prices.version)
		packin_up()
		INVOKE_ASYNC(src, TYPE_PROC_REF(/datum, update_static_data_for_all_viewers))
	if (cooldown > 0)//cooldown used for printing beacons
		cooldown--
	return data

/// Каталог уходит статикой: он меняется только с ценами, и ui_data пересылает его, когда сменилась их версия.
/obj/machinery/computer/cargo/express/ui_static_data(mob/user)
	if(!meme_pack_data)
		packin_up()
		stack_trace("There was no pack data for [src]")
	. = list("supplies" = meme_pack_data)
	if(station_budget())
		.["help_topics"] = list(econ_express_help_topic()) + econ_cargo_help_topics()

/obj/machinery/computer/cargo/express/ui_act(action, params, datum/tgui/ui)
	if(station_only && !is_station_level(z)) // BLUEMOON ADD - работает только на Z-уровне станции
		return
	var/static/list/express_actions = list("toggleLock", "toggleprivate", "LZCargo", "LZBeacon", "printBeacon", "add")
	if(econ_cargo_viewer_act(usr, action, params, catalog_ids))
		return TRUE
	if(!(action in express_actions) || (locked && action != "toggleLock"))
		return
	. = ..()
	if(.)
		return

	switch(action)
		// BLUEMOON ADD START
		if("toggleLock")
			if(allowed(usr))
				locked = !locked
		if("toggleprivate")
			self_paid = !self_paid
			. = TRUE
		// BLUEMOON ADD END
		if("LZCargo")
			if(beacon_only) // BLUEMOON ADD - нельзя вернуться в станционный Cargo Bay
				return
			usingBeacon = FALSE
			if (beacon)
				beacon.update_status(SP_UNREADY)
		if("LZBeacon")
			usingBeacon = TRUE
			if (beacon)
				beacon.update_status(SP_READY) //turns on the beacon's ready light
		if("printBeacon")
			var/datum/bank_account/D = SSeconomy.get_dep_account(department_account) // BLUEMOON EDIT (был ACCOUNT_CAR)
			if(D)
				if(D.debit(EXPRESS_BEACON_COST, ECON_PURCHASE, usr, "Печать маяка снабжения"))
					cooldown = 10//a ~ten second cooldown for printing beacons to prevent spam
					var/obj/item/supplypod_beacon/C = new /obj/item/supplypod_beacon(drop_location())
					C.link_console(src, usr)//rather than in beacon's Initialize(), we can assign the computer to the beacon by reusing this proc)
					printed_beacons++//printed_beacons starts at 0, so the first one out will be called beacon # 1
					beacon.name = "Supply Pod Beacon #[printed_beacons]"
					usingBeacon = TRUE
					beacon.update_status(SP_READY) //turns on the beacon's ready light


		if("add")//Generate Supply Order first
			if(TIMER_COOLDOWN_CHECK(src, COOLDOWN_EXPRESSPOD_CONSOLE))
				say("Railgun recalibrating. Stand by.")
				return
			var/id = params["id"]
			id = text2path(id) || id
			var/datum/supply_pack/pack = SSshuttle.supply_packs[id]
			if(!istype(pack))
				CRASH("Unknown supply pack id given by express order console ui. ID: [params["id"]]")
			if(!offers_pack(pack))
				return

			// BLUEMOON ADD - Personal purchase validation
			if(self_paid && !pack.can_private_buy)
				say("Этот пак нельзя купить на личный счёт.")
				return

			if(pack.goody == PACK_GOODY_PRIVATE && !self_paid)
				playsound(src, 'sound/machines/buzz-sigh.ogg', 50, FALSE)
				say("Частные малые кейсы покупаются только с личного счёта: включите частный заказ.")
				return
			if(econ_pack_unavailable(pack))
				say("Нет в наличии у партнёров.")
				return

			var/datum/bank_account/account
			if(self_paid && isliving(usr))
				var/mob/living/L = usr
				var/obj/item/card/id/id_card = L.get_idcard(TRUE)
				if(!istype(id_card))
					say("Для частного заказа нужна ID-карта.")
					return
				if(istype(id_card, /obj/item/card/id/departmental_budget))
					say("Бюджетные карты отделов для частного заказа не принимаются.")
					return
				account = id_card.registered_account
				if(!istype(account))
					say("У карты нет банковского счёта.")
					return
			// BLUEMOON ADD END

			var/name = "*None Provided*"
			var/rank = "*None Provided*"
			var/ckey = usr.ckey
			if(ishuman(usr))
				var/mob/living/carbon/human/H = usr
				name = H.get_authentification_name()
				rank = H.get_assignment(hand_first = TRUE)
			else if(issilicon(usr))
				name = usr.real_name
				rank = "Silicon"
			var/reason = ""
			var/list/empty_turfs
			var/datum/supply_order/SO = new(pack, name, rank, ckey, reason, account)
			var/points_to_check
			var/datum/bank_account/D = SSeconomy.get_dep_account(department_account) // BLUEMOON EDIT (был ACCOUNT_CAR)
			// BLUEMOON EDIT - Use personal account balance when self_paid
			if(self_paid && account)
				points_to_check = account.account_balance
			else if(D)
				points_to_check = D.account_balance
			// BLUEMOON EDIT END
			if(!(obj_flags & EMAGGED))
				if(SO.pack.get_cost(SO.paying_account) <= points_to_check)
					var/LZ
					if (istype(beacon) && usingBeacon)//prioritize beacons over landing in cargobay
						LZ = get_turf(beacon)
						beacon.update_status(SP_LAUNCH)
					else if (!usingBeacon)//find a suitable supplypod landing zone in cargobay
						landingzone = GLOB.areas_by_type[/area/cargo/storage]
						if (!landingzone)
							WARNING("[src] couldnt find a Quartermaster/Storage (aka cargobay) area on the station, and as such it has set the supplypod landingzone to the area it resides in.")
							landingzone = get_area(src)
						for(var/turf/open/floor/T in landingzone.contents)//uses default landing zone
							if(T.is_blocked_turf())
								continue
							LAZYADD(empty_turfs, T)
							CHECK_TICK
						if(empty_turfs?.len)
							LZ = pick(empty_turfs)
					if (SO.pack.get_cost(SO.paying_account) <= points_to_check && LZ)//we need to call the cost check again because of the CHECK_TICK call
						TIMER_COOLDOWN_START(src, COOLDOWN_EXPRESSPOD_CONSOLE, 5 SECONDS)
						// BLUEMOON EDIT - Charge personal or department account
						var/datum/bank_account/payer = (self_paid && account) ? account : D
						var/datum/trade_partner/supplier = econ_pack_supplier(SO.pack, SO.paying_account)
						var/express_cost = SO.pack.get_cost(SO.paying_account)
						if(!payer.debit(express_cost, ECON_IMPORT, usr, "Экспресс-заказ: [SO.pack.name]"))
							say("Оплата не прошла.")
							return
						supplier?.note_purchase(SO.pack, express_cost, station_budget())
						say("Заказ принят: [express_cost] кр. списано, плательщик - [econ_budget_name(payer)].")
						// BLUEMOON EDIT END
						if(pack.special_pod)
							new /obj/effect/pod_landingzone(LZ, pack.special_pod, SO)
						else
							new /obj/effect/pod_landingzone(LZ, podType, SO)
						. = TRUE
						update_appearance()
				// BLUEMOON ADD - Insufficient funds message
				else
					if(self_paid)
						say("На личном счёте не хватает денег: нужно [SO.pack.get_cost(SO.paying_account)] кр.")
					else
						say("Не хватает денег: нужно [SO.pack.get_cost(SO.paying_account)] кр., плательщик - [econ_budget_name(D)].")
				// BLUEMOON ADD END
			else
				var/datum/trade_partner/bulk_supplier = econ_pack_supplier(SO.pack, SO.paying_account)
				if(bulk_supplier && !(PARTNER_ANY in bulk_supplier.sells_groups) && bulk_supplier.stock_of(SO.pack) < MAX_EMAG_ROCKETS)
					say("У партнёра на складе меньше [MAX_EMAG_ROCKETS] таких паков.")
					return
				var/packaging = min(SO.pack.market_packaging(SO.paying_account, SO.pack.market_total()), SO.pack.get_cost(SO.paying_account))
				var/total_cost = MAX_EMAG_ROCKETS * (packaging + emag_contents_price(SO.pack, SO.paying_account))
				if(total_cost <= points_to_check) // bulk discount :^)
					landingzone = emag_landing_area()
					for(var/turf/open/floor/T in landingzone.contents)
						if(T.is_blocked_turf())
							continue
						LAZYADD(empty_turfs, T)
						CHECK_TICK
					if(empty_turfs?.len)
						TIMER_COOLDOWN_START(src, COOLDOWN_EXPRESSPOD_CONSOLE, 10 SECONDS)
						// BLUEMOON EDIT - Charge personal or department account (emagged mode)
						var/datum/bank_account/payer = (self_paid && account) ? account : D
						if(!payer.debit(total_cost, ECON_IMPORT, usr, "Экспресс-заказ: [SO.pack.name]"))
							say("Оплата не прошла.")
							return
						// BLUEMOON EDIT END
						SO.generateRequisition(get_turf(src))
						for(var/i in 1 to MAX_EMAG_ROCKETS)
							bulk_supplier?.note_purchase(SO.pack, total_cost / MAX_EMAG_ROCKETS, station_budget())
							var/LZ = pick(empty_turfs)
							LAZYREMOVE(empty_turfs, LZ)
							if(pack.special_pod)
								new /obj/effect/pod_landingzone(LZ, pack.special_pod, SO)
							else
								new /obj/effect/pod_landingzone(LZ, podType, SO)
							. = TRUE
							update_appearance()
							CHECK_TICK
				// BLUEMOON ADD - Insufficient funds message (emagged mode)
				else
					if(self_paid)
						say("На личном счёте не хватает денег: нужно [total_cost] кр.")
					else
						say("Не хватает денег: нужно [total_cost] кр., плательщик - [econ_budget_name(D)].")
				// BLUEMOON ADD END

// BLUEMOON ADD START - консоли для сторонних бюджетов, размещаются только через маппинг

/obj/machinery/computer/cargo/express/tar
	name = "express supply console (Тарков Индастриз)"
	desc = "Консоль экспресс-доставки Тарков Индастриз: пак прилетает капсулой на маяк почти сразу, а его цена списывается в момент заказа с бюджета Тарков Индастриз или, в режиме частного заказа, с личного счёта карты."
	department_account = ACCOUNT_TAR
	req_access = list(ACCESS_TARKOFF)
	icon_screen = "idce"
	exclusive_pack_pool = TRUE // BLUEMOON ADD
	access_hint = "a Tarkov Industries-issued ID card"
	beacon_only = TRUE // BLUEMOON ADD
	station_only = FALSE // BLUEMOON ADD - размещается в космических руинах, вне станции

/obj/machinery/computer/cargo/express/ds
	name = "express supply console (Deep Space)"
	desc = "Консоль экспресс-доставки Deep Space: пак прилетает капсулой на маяк почти сразу, а его цена списывается в момент заказа с бюджета Deep Space или, в режиме частного заказа, с личного счёта карты."
	department_account = ACCOUNT_DS
	req_access = list(ACCESS_SYNDICATE_LEADER)
	icon_screen = "commsyndie"
	exclusive_pack_pool = TRUE // BLUEMOON ADD
	access_hint = "a Deep Space-issued ID card"
	beacon_only = TRUE // BLUEMOON ADD
	station_only = FALSE // BLUEMOON ADD - размещается в космических руинах, вне станции

// BLUEMOON ADD END
