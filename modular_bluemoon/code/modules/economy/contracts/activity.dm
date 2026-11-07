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
	progress += contract_units(amount, paid)
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
	desc = "Продать энергии на указанную сумму в кредитах через узлы экспорта."
	work_type = WORK_ENG_POWER_EXPORT
	target = 1500
	takeable = FALSE

/datum/econ_contract/activity/engineering_export/contract_units(amount, paid)
	return paid

/datum/econ_contract/activity/engineering_export/work_value()
	return target

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

/datum/econ_contract/activity/security_contraband
	title = "Рейд на контрабанду"
	desc = "Передать NT изъятую контрабанду."
	work_type = WORK_SEC_CONTRABAND
	target = 2

/datum/econ_contract/activity/security_contraband/work_value()
	return target * SSeconomy.settings.contraband_value_default * (SSeconomy.settings.work_prices[work_type] || 0)

/datum/econ_contract/activity/cargo_ore
	title = "Норма переработки"
	desc = "Переработать руды на указанную сумму в кредитах."
	work_type = WORK_MINING_ORE
	target = 1200
	takeable = FALSE

/datum/econ_contract/activity/cargo_ore/contract_units(amount, paid)
	return paid

/datum/econ_contract/activity/cargo_ore/work_value()
	return target
