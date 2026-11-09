GLOBAL_VAR_INIT(econ_contract_uid, 0)

/datum/econ_contract
	var/uid
	var/department_id
	var/title = "Контракт"
	var/desc = ""
	var/reward = 1000
	var/urgent = FALSE
	var/deadline = 0
	var/created = 0
	var/datum/bank_account/taker
	var/completed = FALSE
	/// Работа всего отдела без исполнителя: контракт не берут, награда целиком отделу
	var/takeable = TRUE
	/// Особый заказ ЦК: не сменяется ротацией и не занимает место на доске отдела
	var/pinned = FALSE

/datum/econ_contract/New(department_id)
	uid = ++GLOB.econ_contract_uid
	src.department_id = department_id
	created = world.time

/datum/econ_contract/Destroy()
	release_taker()
	var/datum/economy_department/department = SSeconomy.get_department(department_id)
	department?.contracts -= src
	return ..()

/datum/econ_contract/proc/payout()
	return round(reward * (urgent ? SSeconomy.settings.contract_urgent_mult : 1))

/// Почему счёт не может взять контракт, или null.
/datum/econ_contract/proc/take_refusal(datum/bank_account/account)
	if(!account)
		return "Нет банковского счёта."
	if(account.offstation)
		return "Контракты NT берут только счета экипажа станции."
	if(completed || QDELETED(src))
		return "Контракт уже закрыт."
	if(!takeable)
		return "Этот контракт выполняет весь отдел, его не берут."
	if(taker)
		return "Контракт уже взят."
	if(length(SSeconomy.contracts_taken_by(account)) >= ECON_CONTRACTS_PER_TAKER)
		return "У вас уже есть взятый контракт."
	if(!COOLDOWN_FINISHED(account, contract_drop_cooldown))
		return "После отказа от контракта новый можно взять через [DisplayTimeText(COOLDOWN_TIMELEFT(account, contract_drop_cooldown), 1)]."

/datum/econ_contract/proc/take(datum/bank_account/account)
	if(take_refusal(account))
		return FALSE
	taker = account
	RegisterSignal(taker, COMSIG_PARENT_QDELETING, PROC_REF(on_taker_deleted))
	if(!deadline)
		set_deadline(world.time + ECON_CONTRACT_TAKEN_TIME)
	log_econ("[account.account_holder] ([account.account_id]) взял контракт #[uid] \"[title]\" отдела [department_id]")
	return TRUE

/// Исполнитель отказывается: неначатый контракт уходит с доски, начатый снова свободен. Срок от взятия снимается, у срочного остаётся свой.
/datum/econ_contract/proc/drop(datum/bank_account/account)
	if(completed || !account || taker != account)
		return FALSE
	log_econ("[account.account_holder] ([account.account_id]) отказался от контракта #[uid] \"[title]\" отдела [department_id]")
	release_taker()
	COOLDOWN_START(account, contract_drop_cooldown, ECON_CONTRACT_DROP_COOLDOWN)
	if(!urgent)
		deadline = 0
	if(!has_progress())
		qdel(src)
	return TRUE

/datum/econ_contract/proc/release_taker()
	if(!taker)
		return
	UnregisterSignal(taker, COMSIG_PARENT_QDELETING)
	taker = null

/datum/econ_contract/proc/on_taker_deleted(datum/source)
	SIGNAL_HANDLER
	release_taker()

/datum/econ_contract/proc/has_progress()
	return FALSE

/// Когда ротация снимет контракт: ничей и не особый, начатый - через ECON_CONTRACT_STALE_ROTATIONS возрастов. null - не снимет.
/datum/econ_contract/proc/rotation_due_at()
	if(taker || pinned)
		return null
	return created + SSeconomy.contract_rotation_age() * (has_progress() ? ECON_CONTRACT_STALE_ROTATIONS : 1)

/datum/econ_contract/proc/is_expired()
	return deadline && world.time > deadline

/// Срок снимает контракт сразу, а не на ближайшем тике экономики раз в несколько минут.
/datum/econ_contract/proc/set_deadline(time)
	deadline = time
	addtimer(CALLBACK(src, PROC_REF(expire)), max(time - world.time, 0) + 1, TIMER_STOPPABLE)

/datum/econ_contract/proc/expire()
	if(completed || QDELETED(src) || !is_expired())
		return
	taker?.bank_card_talk("Срок контракта \"[title]\" истёк, контракт снят.")
	qdel(src)

/datum/econ_contract/proc/complete(mob/performer)
	if(completed)
		return
	completed = TRUE
	var/datum/economy_department/department = SSeconomy.get_department(department_id)
	var/total = payout()
	var/share = taker ? round(total * SSeconomy.settings.contract_performer_share / 100) : 0
	department?.account.credit(total - share, ECON_CONTRACT, performer, "Контракт: [title]")
	if(share)
		var/net = SSeconomy.pay_personal(null, taker, share, ECON_CONTRACT, performer, "Контракт: [title]")
		taker.bank_card_talk("Контракт \"[title]\" выполнен: [share] кр. до налога, на руки [net] кр.", balloon = net ? "контракт +[net] кр" : null)
	log_econ("Контракт #[uid] \"[title]\" отдела [department_id] выполнен[performer ? " ([key_name(performer)])" : ""]: [total] кр., исполнителю [share]")
	qdel(src)

/datum/econ_contract/proc/progress_text()
	return ""

/datum/econ_contract/proc/ui_entry()
	var/datum/economy_department/department = SSeconomy.get_department(department_id)
	var/due = rotation_due_at()
	return list(
		"uid" = uid,
		"department" = department_id,
		"department_name" = department?.name || department_id,
		"title" = title,
		"desc" = desc,
		"reward" = payout(),
		"urgent" = urgent,
		"time_left" = deadline ? max(round((deadline - world.time) / (1 SECONDS)), 0) : null,
		"taken_by" = taker?.account_holder,
		"taker_id" = taker?.account_id,
		"takeable" = takeable,
		"special" = pinned,
		"rotates_in" = isnull(due) ? null : max(round((due - world.time) / (1 SECONDS)), 0),
		"started" = has_progress(),
		"progress" = progress_text(),
	)

/proc/econ_contracts_ui_data(mob/user)
	var/datum/bank_account/account = econ_account_of(user)
	var/list/contracts = list()
	for(var/datum/econ_contract/contract as anything in SSeconomy.all_contracts())
		contracts += list(contract.ui_entry())
	return list(
		"contracts" = contracts,
		"my_account" = account?.account_id,
		"my_name" = account?.account_holder,
		"performer_share" = SSeconomy.settings.contract_performer_share,
		"drop_cooldown" = round(ECON_CONTRACT_DROP_COOLDOWN / (1 MINUTES)),
	)

/// Берёт контракт uid на account, по умолчанию на счёт пользователя. Возвращает list(взят ли, ответ игроку).
/proc/econ_try_take_contract(mob/user, uid, datum/bank_account/account)
	if(istext(uid))
		uid = text2num(uid)
	var/datum/econ_contract/contract = isnum(uid) ? SSeconomy.contract_by_uid(uid) : null
	if(!account)
		account = econ_account_of(user)
	var/refusal = contract ? contract.take_refusal(account) : "Контракт уже снят с доски."
	if(refusal || !contract.take(account))
		return list(FALSE, refusal || "Контракт не взят.")
	return list(TRUE, "Контракт \"[contract.title]\" закреплён за вами. Ваша доля - [SSeconomy.settings.contract_performer_share]% награды.")

/// Отказ от своего контракта uid. Возвращает list(снят ли, ответ игроку).
/proc/econ_try_drop_contract(mob/user, uid, datum/bank_account/account)
	if(istext(uid))
		uid = text2num(uid)
	var/datum/econ_contract/contract = isnum(uid) ? SSeconomy.contract_by_uid(uid) : null
	if(!account)
		account = econ_account_of(user)
	if(!contract)
		return list(FALSE, "Контракт уже снят с доски.")
	var/title = contract.title
	if(!contract.drop(account))
		return list(FALSE, "Это не ваш контракт.")
	return list(TRUE, "Вы отказались от контракта \"[title]\". Новый контракт можно взять через [DisplayTimeText(ECON_CONTRACT_DROP_COOLDOWN)].")

/// Взятие контракта с консоли: ответ - в чат пользователю, со звуком машины.
/proc/econ_take_contract(mob/user, uid, obj/machinery/machine)
	return econ_contract_answer(user, econ_try_take_contract(user, uid), machine)

/// Отказ от контракта с консоли: ответ - в чат пользователю, со звуком машины.
/proc/econ_drop_contract(mob/user, uid, obj/machinery/machine)
	return econ_contract_answer(user, econ_try_drop_contract(user, uid), machine)

/proc/econ_contract_answer(mob/user, list/result, obj/machinery/machine)
	var/answer = result[2]
	if(!result[1])
		to_chat(user, span_warning(answer))
		playsound(machine, 'sound/machines/synth_no.ogg', 30, TRUE)
		return FALSE
	to_chat(user, span_notice(answer))
	playsound(machine, 'sound/machines/synth_yes.ogg', 30, TRUE)
	return TRUE

/proc/econ_contracts_help()
	var/datum/economy_settings/settings = SSeconomy.settings
	var/rotation_minutes = round(settings.contract_rotation_ticks * SSeconomy.wait / (1 MINUTES))
	return "Контракты NT: поставка - отгрузить нужное шаттлом снабжения или через пункт подработки на станции; деятельность - набрать работу отдела до срока, награда - сверх обычной оплаты этой работы, [settings.contract_work_mult * 100]% её цены по прайсу. \
		Взявший контракт получает [settings.contract_performer_share]% награды (с налогом), остальное - отделу. \
			От взятого контракта можно отказаться: неначатый уйдёт с доски, начатый снова станет свободным, а новый контракт отказавшийся возьмёт через [DisplayTimeText(ECON_CONTRACT_DROP_COOLDOWN)]. \
		Срочные контракты платят [econ_times_text(settings.contract_urgent_mult)] больше, но снимаются через [settings.contract_urgent_minutes] мин. \
		Невзятые контракты сменяются через [rotation_minutes] мин., начатые - через [rotation_minutes * ECON_CONTRACT_STALE_ROTATIONS] мин., отгруженное по ним не возвращается. Купленное в автоматах и через снабжение по контрактам не засчитывается."
