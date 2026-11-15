/datum/economy_department
	/// world.time, с которого отдел может заказать следующую капсулу
	var/next_express = 0

/datum/economy_department/proc/express_ready_in()
	return max(next_express - world.time, 0)

/datum/economy_department/proc/express_price(datum/supply_pack/pack)
	return round(econ_pack_price(pack) * (100 + SSeconomy.settings.department_express_markup) / 100)

/// Свободный пол для капсулы рядом с заказавшим: станция, то же помещение, не под ним самим.
/proc/econ_express_landing(mob/living/user)
	var/turf/center = get_turf(user)
	if(!center || !is_station_level(center.z))
		return null
	var/area/room = get_area(center)
	if(!room || istype(room, /area/space))
		return null
	var/list/candidates = list()
	for(var/turf/open/floor/floor in RANGE_TURFS(ECON_EXPRESS_LANDING_RANGE, center))
		if(floor == center || get_area(floor) != room || floor.is_blocked_turf())
			continue
		candidates += floor
	return length(candidates) ? pick(candidates) : null

/// Пак из каталога отдела капсулой сразу, мимо шаттла снабжения. Возвращает null при успехе или причину отказа.
/datum/economy_department/proc/express_pack(datum/supply_pack/pack, mob/living/user)
	if(!pack || !(pack in catalog()))
		return "Этого нет в каталоге отдела."
	if(!can_manage(user))
		return "Капсулу заказывает глава отдела, а без него - ГП или капитан."
	if(econ_pack_unavailable(pack))
		return "\"[pack.name]\" сейчас нет на складах партнёров."
	if(express_ready_in())
		return "Следующую капсулу можно заказать через [DisplayTimeText(express_ready_in(), 1)]."
	var/turf/landing = econ_express_landing(user)
	if(!landing)
		return "Капсуле негде сесть: нужен свободный пол рядом с вами, в том же помещении станции."
	var/base_price = round(econ_pack_price(pack))
	var/price = express_price(pack)
	var/datum/trade_partner/supplier = econ_pack_supplier(pack, account)
	if(!account.debit(price, ECON_IMPORT, user, "Экспресс-доставка: [pack.name]"))
		return "В бюджете не хватает денег: капсула стоит [price] кр."
	supplier?.note_purchase(pack, base_price)
	next_express = world.time + SSeconomy.settings.department_express_cooldown_minutes MINUTES
	if(pack == saving_goal)
		clear_saving_goal(ordered = TRUE)
	var/orderer_name = name
	var/orderer_rank = name
	if(ishuman(user))
		var/mob/living/carbon/human/human_user = user
		orderer_name = human_user.get_authentification_name()
		orderer_rank = human_user.get_assignment(hand_first = TRUE)
	var/datum/supply_order/order = new(pack, orderer_name, orderer_rank, user?.ckey, "Экспресс-доставка: [name]")
	order.department_id = id
	new /obj/effect/pod_landingzone(landing, pack.special_pod || /obj/structure/closet/supplypod/bluespacepod, order)
	log_econ("[key_name(user)]: капсула [pack.name] для [name] за [price] кр. в [AREACOORD(landing)]")
	return null
