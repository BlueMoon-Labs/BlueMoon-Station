/datum/economy_department/cargo
	id = ACCOUNT_CAR
	name = "Снабжение"
	budget_name = "бюджет снабжения"
	head_access = list(ACCESS_QM)
	/// Отряд, вызов которого закрыл цель накопления, и её срок: возврат денег за не прилетевший отряд возвращает и цель
	var/ert_goal_paid_id = 0
	var/ert_goal_paid_until = 0

/datum/economy_department/cargo/budget_floor()
	return max(..(), SSeconomy.settings.budget_cap_floor_cargo)

/// Отряд из GLOB.payed_ert по номеру или null.
/proc/econ_payed_ert(ert_id)
	if(!isnum(ert_id) || ert_id != round(ert_id) || ert_id < 1 || ert_id > length(GLOB.payed_ert))
		return null
	return GLOB.payed_ert[ert_id]

/// Пак, который консоль снабжения заказывает за бюджет снабжения: не эксклюзив отдела или консоли, не скрытый, не контрабанда, не админский, особый - только включённый.
/proc/econ_cargo_budget_pack(datum/supply_pack/pack)
	if(!istype(pack) || pack.department_catalog || pack.exclusive_consoles || pack.DropPodOnly || pack.hidden || pack.contraband || pack.admin_spawned || pack.goody == PACK_GOODY_PRIVATE)
		return FALSE
	return !pack.special || pack.special_enabled

/// Дороже самого дорогого отряда ОБР снабжение на пак не копит: шуточные паки за миллионы не отключают возврат излишка.
/proc/econ_cargo_goal_max()
	. = SSeconomy.settings.budget_cap_floor_cargo
	for(var/list/ert as anything in GLOB.payed_ert)
		. = max(., ert["price"])

/datum/economy_department/cargo/can_save_for(datum/supply_pack/pack)
	return ..() || (econ_cargo_budget_pack(pack) && round(econ_pack_price(pack)) <= econ_cargo_goal_max())

/datum/economy_department/cargo/saving_goal_valid()
	if(saving_goal_ert)
		var/list/ert = econ_payed_ert(saving_goal_ert)
		return ert?["available"]
	return (saving_goal in catalog()) || econ_cargo_budget_pack(saving_goal)

/datum/economy_department/cargo/saving_goal_price()
	if(saving_goal_ert)
		var/list/ert = econ_payed_ert(saving_goal_ert)
		return ert["price"]
	if(saving_goal in catalog())
		return ..()
	return min(round(econ_pack_price(saving_goal)), econ_cargo_goal_max())

/datum/economy_department/cargo/saving_goal_scope()
	return " (пак снабжения или отряд ОБР)"

/datum/economy_department/cargo/proc/set_saving_goal_ert(ert_id, mob/living/user)
	var/list/ert = econ_payed_ert(ert_id)
	if(!ert || !ert["available"] || !can_start_saving_goal(user))
		return FALSE
	saving_goal = null
	saving_goal_ert = ert_id
	saving_goal_until = 0
	saving_goal_cache = null
	log_econ("[key_name(user)] назначил цель накопления [name]: отряд [ert["name"]]")
	return TRUE

/// Вызов отряда ОБР за бюджет снабжения; снимает цель накопления на этот отряд.
/datum/economy_department/cargo/proc/pay_ert(ert_id, mob/user)
	var/list/ert = econ_payed_ert(ert_id)
	if(!ert || !ert["available"] || account.account_balance < ert["price"] || !account.debit(ert["price"], ECON_PURCHASE, user, "Вызов: [ert["name"]]"))
		return FALSE
	ert["available"] = FALSE
	if(saving_goal_ert == ert_id)
		ert_goal_paid_id = ert_id
		ert_goal_paid_until = saving_goal_until || (world.time + SSeconomy.settings.saving_goal_minutes MINUTES)
		clear_saving_goal(ordered = TRUE)
	else if(ert_goal_paid_id == ert_id)
		ert_goal_paid_id = 0
	return TRUE

/// Отряд не прилетел: деньги и отряд возвращаются, вместе с целью, если вызов её закрыл.
/datum/economy_department/cargo/proc/refund_ert(ert_id, memo)
	var/list/ert = econ_payed_ert(ert_id)
	if(!ert)
		return
	ert["available"] = TRUE
	account.credit(ert["price"], ECON_REFUND, memo = memo)
	if(ert_goal_paid_id == ert_id)
		ert_goal_paid_id = 0
		restore_saving_goal(null, ert_goal_paid_until, ert_id)

/// Руда платит на станции и на шахтёрских уровнях, кроме руин и чужих шаттлов.
/datum/economy_department/cargo/proc/pays_ore_at(atom/source)
	var/turf/source_turf = get_turf(source)
	if(!source_turf || !(is_station_level(source_turf.z) || is_mining_level(source_turf.z)))
		return FALSE
	var/area/source_area = get_area(source_turf)
	if(istype(source_area, /area/ruin))
		return FALSE
	return !istype(source_area, /area/shuttle) || istype(source_area, /area/shuttle/auxillary_base)

/datum/economy_department/cargo/proc/note_ore(obj/item/stack/ore/ore, amount, atom/source)
	if(!ore.points || amount <= 0 || !pays_ore_at(source))
		return
	SSeconomy.record_work(id, WORK_MINING_ORE, ore.points * amount * econ_sale_factor(COMMODITY_METALS), memo = "Переработка: [ore.name]")
