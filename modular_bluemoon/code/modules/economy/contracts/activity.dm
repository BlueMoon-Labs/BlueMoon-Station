/datum/econ_contract/activity
	var/work_type
	var/target = 5
	var/progress = 0
	var/minutes = 30
	/// Обычный объём одной засчитанной работы (сложность блюда, тысячи очков узла)
	var/work_units = 1

/datum/econ_contract/activity/New(department_id)
	..()
	set_deadline(world.time + minutes MINUTES)
	reward = max(round(work_value() * SSeconomy.settings.contract_work_mult, ECON_CONTRACT_REWARD_STEP), ECON_CONTRACT_REWARD_STEP)
	RegisterSignal(SSeconomy, COMSIG_ECONOMY_WORK_RECORDED, PROC_REF(on_work))

/datum/econ_contract/activity/Destroy()
	UnregisterSignal(SSeconomy, COMSIG_ECONOMY_WORK_RECORDED)
	return ..()

/datum/econ_contract/activity/proc/on_work(datum/source, work_department, recorded_type, amount, mob/performer, paid, atom/subject)
	SIGNAL_HANDLER
	if(completed || paid <= 0 || work_department != department_id || !counts_work(recorded_type))
		return
	if(taker && econ_account_of(performer) != taker)
		return
	var/datum/economy_department/department = SSeconomy.get_department(department_id)
	if(!(src in department?.contracts))
		return
	var/units = contract_units(amount, paid)
	note_contribution(performer, units)
	progress += units
	if(progress >= target)
		INVOKE_ASYNC(src, PROC_REF(complete), performer)

/datum/econ_contract/activity/has_progress()
	return progress > 0

/datum/econ_contract/activity/proc/counts_work(recorded_type)
	return recorded_type == work_type

/datum/econ_contract/activity/proc/contract_units(amount, paid)
	return 1

/// Сколько NT заплатил бы за работу, которую просит контракт, по прайсу из настроек.
/datum/econ_contract/activity/proc/work_value()
	return target * work_units * (SSeconomy.settings.work_prices[work_type] || 0)

/datum/econ_contract/activity/progress_text()
	return "[min(progress, target)] / [target]"

/datum/econ_contract/activity/medical_discharges
	title = "Поток пациентов"
	desc = "Выписать пациентов после лечения."
	work_type = WORK_MED_DISCHARGE_LIGHT
	target = 5

/datum/econ_contract/activity/medical_discharges/counts_work(recorded_type)
	return recorded_type in list(WORK_MED_DISCHARGE_LIGHT, WORK_MED_DISCHARGE_HEAVY, WORK_MED_DISCHARGE_CRIT)

/datum/econ_contract/activity/medical_discharges/work_value()
	var/list/prices = SSeconomy.settings.work_prices
	return target * (prices[WORK_MED_DISCHARGE_LIGHT] + prices[WORK_MED_DISCHARGE_HEAVY] + prices[WORK_MED_DISCHARGE_CRIT]) / 3

/datum/econ_contract/activity/medical_surgeries
	title = "Плановые операции"
	desc = "Провести лечебные операции."
	work_type = WORK_MED_SURGERY
	target = 3

/datum/econ_contract/activity/engineering_export
	title = "Поставка энергии в сеть сектора"
	desc = "Продать энергии на указанную сумму в кредитах через узлы экспорта. Бюджет за энергию уже получил, поэтому награда идёт лично инженерам на смене."
	work_type = WORK_ENG_POWER_EXPORT
	target = 1500
	takeable = FALSE
	people_only = TRUE

/datum/econ_contract/activity/engineering_export/contract_units(amount, paid)
	return paid

/datum/econ_contract/activity/engineering_export/work_value()
	return target * SSeconomy.settings.contract_team_share / 100

/datum/econ_contract/activity/science_nodes
	title = "Исследовательский рывок"
	desc = "Исследовать узлы техвеба."
	work_type = WORK_SCI_NODE
	target = 20
	work_units = 6

/datum/econ_contract/activity/service_dishes
	title = "Банкет"
	desc = "Накормить экипаж блюдами повара."
	work_type = WORK_SRV_DISH
	target = 8
	work_units = 3

/datum/econ_contract/activity/service_cleaning
	title = "Генеральная уборка"
	desc = "Убрать грязь в общих зонах."
	work_type = WORK_SRV_CLEANING
	target = 40

/datum/econ_contract/activity/service_drinks
	title = "Вечер в баре"
	desc = "Смешать коктейли, которые выпьют другие члены экипажа."
	work_type = WORK_SRV_DRINK
	target = 10

/datum/econ_contract/activity/service_plants
	title = "Новые сорта"
	desc = "Вырастить и собрать урожай сортов, которых в эту смену ещё не было."
	work_type = WORK_SRV_NEW_PLANT
	target = 2

/datum/econ_contract/activity/science_extracts
	title = "Новые экстракты"
	desc = "Получить экстракты слаймов цветов, которых в эту смену ещё не было. Засчитываются все находки ксенобиологии."
	work_type = WORK_SCI_SLIME_DISCOVERY
	target = 2
	work_units = 50
	takeable = FALSE

/// Новых цветов экстракта за смену конечное число: без двух неоткрытых контракт не выполнить.
/datum/econ_contract/activity/science_extracts/postable()
	var/datum/economy_department/science/science = SSeconomy.get_department(ACCOUNT_SCI)
	return length(GLOB.econ_slime_extract_value) - length(science?.extracts_seen) >= target

/datum/econ_contract/activity/science_mechs
	title = "Заказ на технику"
	desc = "Собрать на станции меха, любого."
	work_type = WORK_SCI_MECH
	target = 1

/datum/econ_contract/activity/security_contraband
	title = "Рейд на контрабанду"
	desc = "Передать NT изъятую контрабанду."
	work_type = WORK_SEC_CONTRABAND
	target = 2

/datum/econ_contract/activity/security_contraband/work_value()
	return target * SSeconomy.settings.contraband_value_default * (SSeconomy.settings.work_prices[work_type] || 0)

/datum/econ_contract/activity/cargo_ore
	title = "Норма переработки"
	desc = "Переработать руды на указанную сумму в кредитах. Бюджет за руду уже получил, поэтому награда идёт лично снабжению на смене."
	work_type = WORK_MINING_ORE
	target = 1200
	takeable = FALSE
	people_only = TRUE

/datum/econ_contract/activity/cargo_ore/contract_units(amount, paid)
	return paid

/datum/econ_contract/activity/cargo_ore/work_value()
	return target * SSeconomy.settings.contract_team_share / 100
