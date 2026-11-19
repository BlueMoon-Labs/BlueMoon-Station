/datum/economy_department/engineering
	id = ACCOUNT_ENG
	name = "Инженерия"
	budget_name = "бюджет инженерии"
	head_access = list(ACCESS_CE)
	/// Доход экспорта энергии со всех машин, ещё не выплаченный бюджету
	var/export_pending = 0
	var/export_payout_due = 0

/datum/economy_department/engineering/on_economy_tick()
	pay_power_export()
	var/list/damage = station_damage()
	SSeconomy.record_work(id, WORK_ENG_INTEGRITY, integrity_score(damage))
	check_incidents(damage)

/// Копит доход экспорта энергии и платит его бюджету не чаще раза в ECON_POWER_EXPORT_PAYOUT_INTERVAL или крупной суммой. Проданное сразу сбивает спрос рынка энергии.
/datum/economy_department/engineering/proc/accrue_power_export(credits)
	if(!isnum(credits) || credits <= 0)
		return
	var/datum/commodity/energy = SSmarket.get_commodity(COMMODITY_ENERGY)
	energy?.note_sale(credits)
	if(!export_payout_due)
		export_payout_due = world.time + ECON_POWER_EXPORT_PAYOUT_INTERVAL
	export_pending += credits
	if(export_pending >= ECON_POWER_EXPORT_PAYOUT_BULK || world.time >= export_payout_due)
		pay_power_export()

/datum/economy_department/engineering/proc/pay_power_export()
	var/whole = round(export_pending)
	if(whole < 1)
		return
	export_pending -= whole
	export_payout_due = world.time + ECON_POWER_EXPORT_PAYOUT_INTERVAL
	SSeconomy.record_work(id, WORK_ENG_POWER_EXPORT, whole)

/// 0..100: половина - доля APC станции под питанием, половина - доля исправных воздушных тревог без опасности вне техтоннелей.
/datum/economy_department/engineering/proc/integrity_score(list/damage)
	if(!damage)
		damage = station_damage()
	var/apcs = damage["apcs"]
	var/alarms = damage["alarms"]
	return round((apcs ? (apcs - damage["dark_apcs"]) / apcs : 0) * 50 + (alarms ? (alarms - damage["bad_alarms"]) / alarms : 0) * 50)

/// APC станции и сколько из них без питания; воздушные тревоги вне техтоннелей и сколько из них в опасности или сломаны.
/datum/economy_department/engineering/proc/station_damage()
	. = list("apcs" = 0, "dark_apcs" = 0, "alarms" = 0, "bad_alarms" = 0)
	for(var/obj/machinery/power/apc/apc as anything in GLOB.apcs_list)
		if(!is_station_level(apc.z))
			continue
		.["apcs"]++
		if(!apc.operating || !apc.cell || apc.cell.charge <= 0 || (apc.machine_stat & (BROKEN|MAINT)))
			.["dark_apcs"]++
	for(var/obj/machinery/airalarm/alarm as anything in SSmachines.get_machines_by_type_and_subtypes(/obj/machinery/airalarm))
		if(!is_station_level(alarm.z) || istype(get_area(alarm), /area/maintenance))
			continue
		.["alarms"]++
		if(alarm.danger_level || (alarm.machine_stat & (BROKEN|NOPOWER)))
			.["bad_alarms"]++

/datum/economy_department/engineering/spending_advice()
	return list(
		"Металл, стекло и пласталь латают пробоины: после метеоров и взрывов они нужны сразу.",
		"Батареи и баллоны держат свет и воздух, а исправность станции и экспорт энергии платят отделу каждый цикл.",
	)

/datum/economy_department/engineering/situational_needs()
	. = list()
	var/list/damage = station_damage()
	if(damage["bad_alarms"])
		var/why = "Отсеков с тревогой по воздуху или без контроля воздуха: [damage["bad_alarms"]]"
		.[/datum/supply_pack/materials/glass50] = why
		.[/datum/supply_pack/materials/metal50] = why
		.[/datum/supply_pack/materials/plasteel20] = why
		.[/datum/supply_pack/materials/oxygen] = "Восполнить воздух после пробоин"
	if(damage["dark_apcs"])
		.[/datum/supply_pack/engineering/power] = "Щитков без питания: [damage["dark_apcs"]]"

/datum/economy_department/engineering/everyday_needs()
	return list(
		/datum/supply_pack/materials/metal50 = "Металл на ремонт и стройку",
		/datum/supply_pack/materials/glass50 = "Стекло на окна и платы",
		/datum/supply_pack/engineering/power = "Батареи для щитков",
	)
