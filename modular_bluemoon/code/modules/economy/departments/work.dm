GLOBAL_LIST_INIT(econ_work_names, list(
	WORK_MED_DISCHARGE_LIGHT = "Выписка пациента (лёгкая травма)",
	WORK_MED_DISCHARGE_HEAVY = "Выписка пациента (тяжёлая травма)",
	WORK_MED_DISCHARGE_CRIT = "Выписка пациента (из крита)",
	WORK_MED_REVIVE = "Реанимация",
	WORK_MED_SURGERY = "Операция",
	WORK_ENG_POWER_EXPORT = "Экспорт энергии",
	WORK_ENG_INTEGRITY = "Исправность станции",
	WORK_SCI_NODE = "Исследование",
	WORK_SCI_SLIME_DISCOVERY = "Новый экстракт слайма",
	WORK_SCI_ARTIFACT = "Артефакт",
	WORK_MINING_ORE = "Переработка руды",
	WORK_SRV_DISH = "Блюдо",
	WORK_SRV_DRINK = "Напиток",
	WORK_SRV_NEW_PLANT = "Новый урожай",
	WORK_SRV_CLEANING = "Уборка",
	WORK_SEC_CONTRABAND = "Изъятая контрабанда",
))

GLOBAL_LIST_INIT(econ_work_cooldown_groups, list(
	WORK_MED_DISCHARGE_LIGHT = WORK_GROUP_MED_DISCHARGE,
	WORK_MED_DISCHARGE_HEAVY = WORK_GROUP_MED_DISCHARGE,
	WORK_MED_DISCHARGE_CRIT = WORK_GROUP_MED_DISCHARGE,
))

/proc/econ_work_name(work_type)
	return GLOB.econ_work_names[work_type] || work_type

/proc/econ_ckey_of(mob/user)
	var/user_key = user?.mind?.key || user?.key
	return user_key ? ckey(user_key) : null

/proc/econ_account_of(mob/living/user)
	if(!isliving(user))
		return null
	if(ishuman(user))
		var/mob/living/carbon/human/human_user = user
		var/datum/bank_account/own = SSeconomy.find_account(human_user.account_id)
		if(own)
			return own
	return user.get_bank_account()

/datum/bank_account
	var/premium_window_start = 0
	var/premium_in_window = 0
	/// Дробная часть премий, ещё не выплаченная
	var/premium_remainder = 0

/datum/economy_department
	/// Тип работы -> дробная часть оплаты, ещё не выплаченная: мелкие работы копятся, а не теряются при округлении
	var/list/work_remainder = list()

/datum/controller/subsystem/economy
	/// "тип или группа из econ_work_cooldown_groups|REF субъекта" -> world.time последней оплаты
	var/list/work_cooldowns = list()
	var/next_work_cooldown_prune = 0

/// Платит отделу цену работы из work_prices и премию исполнителю. Возвращает сумму отделу, 0 при отказе.
/datum/controller/subsystem/economy/proc/record_work(department_id, work_type, amount = 1, mob/performer, atom/subject, memo)
	SHOULD_NOT_SLEEP(TRUE)
	if(!istext(department_id) || !istext(work_type) || !isnum(amount) || amount <= 0)
		return 0
	var/datum/economy_department/department = get_department(department_id)
	var/price = settings.work_prices[work_type]
	if(!department || !isnum(price))
		return 0
	if(subject && !work_subject_allowed(work_type, performer, subject))
		return 0
	var/exact = price * amount + (department.work_remainder[work_type] || 0)
	var/total = round(exact)
	if(total > 0 && !department.account.credit(total, ECON_WORK, performer, memo || econ_work_name(work_type)))
		return 0
	department.work_remainder[work_type] = exact - total
	if(total <= 0)
		return 0
	if(subject)
		note_work_subject(work_type, subject)
	department.note_work(work_type, total, performer)
	pay_work_premium(performer, total, work_type)
	SEND_SIGNAL(src, COMSIG_ECONOMY_WORK_RECORDED, department_id, work_type, amount, performer, total, subject)
	return total

/// Живой субъект ключуется разумом: новое тело того же игрока остаётся на кулдауне.
/datum/controller/subsystem/economy/proc/work_cooldown_key(work_type, atom/subject)
	var/datum/holder = subject
	if(isliving(subject))
		var/mob/living/living_subject = subject
		holder = living_subject.mind || subject
	return "[GLOB.econ_work_cooldown_groups[work_type] || work_type]|[REF(holder)]"

/datum/controller/subsystem/economy/proc/note_work_subject(work_type, atom/subject)
	var/cooldown = settings.work_subject_cooldown_minutes MINUTES
	if(world.time >= next_work_cooldown_prune)
		next_work_cooldown_prune = world.time + cooldown
		for(var/key in work_cooldowns)
			if(world.time - work_cooldowns[key] >= cooldown)
				work_cooldowns -= key
	work_cooldowns[work_cooldown_key(work_type, subject)] = world.time

/datum/controller/subsystem/economy/proc/work_subject_allowed(work_type, mob/performer, atom/subject)
	var/cooldown = settings.work_subject_cooldown_minutes MINUTES
	if(ismob(subject))
		if(!isliving(subject) || !performer)
			return FALSE
		var/mob/living/patient = subject
		var/patient_key = patient.mind?.key
		if(!patient_key || patient == performer)
			return FALSE
		var/performer_ckey = econ_ckey_of(performer)
		if(performer_ckey)
			if(ckey(patient_key) == performer_ckey)
				return FALSE
			if(patient.lastattackerckey == performer_ckey && world.time - patient.lastattacker_time < cooldown)
				return FALSE
	var/last = work_cooldowns[work_cooldown_key(work_type, subject)]
	return isnull(last) || world.time - last >= cooldown

/datum/controller/subsystem/economy/proc/pay_work_premium(mob/performer, total, work_type)
	var/datum/bank_account/account = econ_account_of(performer)
	if(!account)
		return
	if(world.time - account.premium_window_start > WORK_PREMIUM_WINDOW)
		account.premium_window_start = world.time
		account.premium_in_window = 0
	var/exact = total * settings.work_personal_share / 100 + account.premium_remainder
	var/premium = min(round(exact), settings.work_personal_cap_hour - account.premium_in_window)
	account.premium_remainder = exact - round(exact)
	if(premium <= 0)
		return
	account.premium_in_window += premium
	pay_personal(null, account, premium, ECON_WORK_PREMIUM, performer, "Премия: [econ_work_name(work_type)]")
