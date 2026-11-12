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
	/// Работа всего отдела без исполнителя: контракт не берут, долю награды делят участники
	var/takeable = TRUE
	/// Особый заказ ЦК: не сменяется ротацией и не занимает место на доске отдела
	var/pinned = FALSE
	/// Личный заказ: виден и доступен только этому счёту
	var/datum/bank_account/owner
	/// Номер счёта -> вклад в контракт, пока у него нет исполнителя
	var/list/contributions

/datum/econ_contract/New(department_id)
	uid = ++GLOB.econ_contract_uid
	src.department_id = department_id
	created = world.time

/datum/econ_contract/Destroy()
	release_taker()
	set_owner(null)
	SSeconomy.loose_contracts -= src
	var/datum/economy_department/department = SSeconomy.get_department(department_id)
	department?.contracts -= src
	return ..()

/datum/econ_contract/proc/payout()
	return round(reward * (urgent ? SSeconomy.settings.contract_urgent_mult : 1))

/// "department", "personal", "chain" или "crew": как контракт показан на доске.
/datum/econ_contract/proc/kind()
	return owner ? "personal" : "department"

/datum/econ_contract/proc/visible_to(datum/bank_account/account)
	return !owner || owner == account

/// Процент награды, который получает взявший контракт.
/datum/econ_contract/proc/performer_share()
	return owner ? SSeconomy.settings.contract_personal_share : SSeconomy.settings.contract_performer_share

/datum/econ_contract/proc/set_owner(datum/bank_account/account)
	if(owner)
		UnregisterSignal(owner, COMSIG_PARENT_QDELETING)
	owner = account
	if(owner)
		RegisterSignal(owner, COMSIG_PARENT_QDELETING, PROC_REF(on_owner_deleted))

/datum/econ_contract/proc/on_owner_deleted(datum/source)
	SIGNAL_HANDLER
	qdel(src)

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
	if(owner && owner != account)
		return "Это чужой личный заказ."
	if(taker)
		return "Контракт уже взят."
	var/slots = account.contract_slots()
	if(length(SSeconomy.contracts_taken_by(account)) >= slots)
		return "У вас уже взято контрактов: [slots] из [slots]. Больше одновременно позволяет репутация подрядчика."
	if(!COOLDOWN_FINISHED(account, contract_drop_cooldown))
		return "После отказа от контракта новый можно взять через [DisplayTimeText(COOLDOWN_TIMELEFT(account, contract_drop_cooldown), 1)]."

/datum/econ_contract/proc/take(datum/bank_account/account)
	if(take_refusal(account))
		return FALSE
	taker = account
	contributions = null
	// Личный заказ и так уходит вместе со счётом владельца
	if(taker != owner)
		RegisterSignal(taker, COMSIG_PARENT_QDELETING, PROC_REF(on_taker_deleted))
	if(!deadline)
		set_deadline(world.time + ECON_CONTRACT_TAKEN_TIME)
	log_econ("[account.account_holder] ([account.account_id]) взял контракт #[uid] \"[title]\"[department_id ? " отдела [department_id]" : ""]")
	return TRUE

/// Исполнитель отказывается: неначатый контракт уходит с доски, начатый снова свободен. Срок от взятия снимается, у срочного остаётся свой.
/datum/econ_contract/proc/drop(datum/bank_account/account)
	if(completed || !account || taker != account)
		return FALSE
	log_econ("[account.account_holder] ([account.account_id]) отказался от контракта #[uid] \"[title]\"[department_id ? " отдела [department_id]" : ""]")
	release_taker()
	COOLDOWN_START(account, contract_drop_cooldown, ECON_CONTRACT_DROP_COOLDOWN)
	account.adjust_contract_rep(-ECON_CONTRACT_REP_DROP)
	after_drop()
	return TRUE

/datum/econ_contract/proc/after_drop()
	if(!urgent)
		deadline = 0
	if(!has_progress())
		qdel(src)

/datum/econ_contract/proc/release_taker()
	if(!taker)
		return
	if(taker != owner)
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
	if(taker)
		taker.bank_card_talk("Срок контракта \"[title]\" истёк, контракт снят.")
		taker.adjust_contract_rep(-ECON_CONTRACT_REP_EXPIRED)
	qdel(src)

/// Вклад в контракт без исполнителя: по нему участники делят свою долю награды.
/datum/econ_contract/proc/note_contribution(mob/performer, units = 1)
	if(taker || units <= 0)
		return
	var/datum/bank_account/account = econ_account_of(performer)
	if(!account || account.offstation || !(account in SSeconomy.bank_accounts))
		return
	LAZYINITLIST(contributions)
	contributions["[account.account_id]"] += units

/// Кому из людей и сколько причитается из награды total: исполнителю его доля, без исполнителя - участникам по вкладу, а у работы всего отдела без записанных участников - поровну отделу на смене.
/datum/econ_contract/proc/reward_shares(total)
	. = list()
	if(taker)
		.[taker] = round(total * performer_share() / 100)
		return
	var/weight = 0
	var/list/accounts = list()
	for(var/number in contributions)
		var/datum/bank_account/account = SSeconomy.find_account(text2num(number))
		if(!account)
			continue
		accounts[account] = contributions[number]
		weight += contributions[number]
	if(!weight && !takeable)
		var/datum/economy_department/department = SSeconomy.get_department(department_id)
		for(var/datum/bank_account/member as anything in department?.staff_accounts())
			if(member.state == ACCOUNT_ACTIVE)
				accounts[member] = 1
				weight++
	if(!weight)
		return
	var/pool = round(total * SSeconomy.settings.contract_team_share / 100)
	for(var/datum/bank_account/account as anything in accounts)
		var/share = round(pool * accounts[account] / weight)
		if(share > 0)
			.[account] = share

/// Выплачивает награду total: людям их доли с налогом, остальное отделу. Исполнителю сверху - надбавка NT за репутацию.
/datum/econ_contract/proc/pay_reward(total, mob/performer)
	var/list/shares = reward_shares(total)
	var/to_people = 0
	for(var/datum/bank_account/account as anything in shares)
		to_people += shares[account]
	var/datum/economy_department/department = SSeconomy.get_department(department_id)
	department?.account.credit(total - to_people, ECON_CONTRACT, performer, "Контракт: [title]")
	for(var/datum/bank_account/account as anything in shares)
		var/share = shares[account]
		var/bonus = account == taker ? round(share * account.contract_rank_bonus() / 100) : 0
		var/net = SSeconomy.pay_personal(null, account, share + bonus, ECON_CONTRACT, performer, "Контракт: [title]")
		account.bank_card_talk("Контракт \"[title]\": [share] кр.[bonus ? " и [bonus] кр. надбавки за репутацию" : ""] до налога, на руки [net] кр.", balloon = net ? "контракт +[net] кр" : null)
	return to_people

/// Сколько репутации подрядчика даёт закрытие контракта.
/datum/econ_contract/proc/rep_value()
	return urgent ? 2 : 1

/datum/econ_contract/proc/complete(mob/performer)
	if(completed)
		return
	completed = TRUE
	var/total = payout()
	var/to_people = pay_reward(total, performer)
	taker?.contract_done(rep_value())
	log_econ("Контракт #[uid] \"[title]\" отдела [department_id] выполнен[performer ? " ([key_name(performer)])" : ""]: [total] кр., исполнителю [to_people]")
	qdel(src)

/datum/econ_contract/proc/progress_text()
	return ""

/datum/econ_contract/proc/ui_entry()
	var/datum/economy_department/department = SSeconomy.get_department(department_id)
	var/due = rotation_due_at()
	return list(
		"uid" = uid,
		"kind" = kind(),
		"department" = department_id,
		"department_name" = department?.name || department_id,
		"title" = title,
		"desc" = desc,
		"reward" = payout(),
		"share" = performer_share(),
		"urgent" = urgent,
		"time_left" = deadline ? max(round((deadline - world.time) / (1 SECONDS)), 0) : null,
		"taken_by" = taker?.account_holder,
		"taker_id" = taker?.account_id,
		"takeable" = takeable,
		"special" = pinned,
		"rotates_in" = isnull(due) ? null : max(round((due - world.time) / (1 SECONDS)), 0),
		"started" = has_progress(),
		"progress" = progress_text(),
		"contributors" = taker ? 0 : length(contributions),
	)

/// Контракты, которые видит счёт: доски отделов, объявления экипажа и свои личные заказы.
/proc/econ_contract_entries(datum/bank_account/account)
	. = list()
	for(var/datum/econ_contract/contract as anything in SSeconomy.all_contracts())
		if(contract.visible_to(account))
			. += list(contract.ui_entry())

/proc/econ_contracts_ui_data(mob/user, datum/bank_account/account)
	if(!account)
		account = econ_account_of(user)
	var/datum/economy_settings/settings = SSeconomy.settings
	SSeconomy.ensure_personal_offers(account)
	return list(
		"contracts" = econ_contract_entries(account),
		"partner_offers" = econ_pad_offers_ui(),
		"my_account" = account?.account_id,
		"my_name" = account?.account_holder,
		"performer_share" = settings.contract_performer_share,
		"team_share" = settings.contract_team_share,
		"drop_cooldown" = round(ECON_CONTRACT_DROP_COOLDOWN / (1 MINUTES)),
		"rank" = account?.contract_rank_data(),
		"reroll_left" = account ? CEILING(COOLDOWN_TIMELEFT(account, contract_reroll_cooldown) / (1 SECONDS), 1) : 0,
		"crew_request" = list(
			"min" = settings.crew_request_min,
			"max" = settings.crew_request_max,
			"title_max" = ECON_CREW_REQUEST_TITLE_MAX,
			"desc_max" = ECON_CREW_REQUEST_DESC_MAX,
			"minutes" = round(ECON_CREW_REQUEST_TIME / (1 MINUTES)),
			"accept_minutes" = round(ECON_CREW_REQUEST_ACCEPT_TIME / (1 MINUTES)),
		),
	)

/proc/econ_contract_uid(uid)
	if(istext(uid))
		uid = text2num(uid)
	return isnum(uid) ? SSeconomy.contract_by_uid(uid) : null

/// Берёт контракт uid на account, по умолчанию на счёт пользователя. Возвращает list(взят ли, ответ игроку).
/proc/econ_try_take_contract(mob/user, uid, datum/bank_account/account)
	var/datum/econ_contract/contract = econ_contract_uid(uid)
	if(!account)
		account = econ_account_of(user)
	var/refusal = contract ? contract.take_refusal(account) : "Контракт уже снят с доски."
	if(refusal || !contract.take(account))
		return list(FALSE, refusal || "Контракт не взят.")
	return list(TRUE, contract.taken_text())

/datum/econ_contract/proc/taken_text()
	return "Контракт \"[title]\" закреплён за вами. Ваша доля - [performer_share()]% награды."

/// Отказ от своего контракта uid. Возвращает list(снят ли, ответ игроку).
/proc/econ_try_drop_contract(mob/user, uid, datum/bank_account/account)
	var/datum/econ_contract/contract = econ_contract_uid(uid)
	if(!account)
		account = econ_account_of(user)
	if(!contract)
		return list(FALSE, "Контракт уже снят с доски.")
	var/title = contract.title
	if(!contract.drop(account))
		return list(FALSE, "Это не ваш контракт.")
	return list(TRUE, "Вы отказались от контракта \"[title]\". Новый контракт можно взять через [DisplayTimeText(ECON_CONTRACT_DROP_COOLDOWN)], репутация подрядчика снижена.")

/// Любое действие доски контрактов от счёта account (по умолчанию - счёт пользователя). null, если действие не про контракты, иначе list(удалось ли, ответ игроку).
/proc/econ_contract_act(mob/user, action, list/params, datum/bank_account/account)
	if(!account)
		account = econ_account_of(user)
	switch(action)
		if("take")
			return econ_try_take_contract(user, params["uid"], account)
		if("drop")
			return econ_try_drop_contract(user, params["uid"], account)
		if("reroll")
			return SSeconomy.reroll_personal_offers(account)
		if("crew_post")
			return econ_post_crew_request(user, account, params["title"], params["desc"], params["reward"])
		if("crew_report", "crew_accept", "crew_reject", "crew_cancel")
			return econ_crew_request_act(account, action, params["uid"])
	return null

/// Действие доски с консоли: ответ - в чат пользователю, со звуком машины. TRUE, если действие было про контракты.
/proc/econ_contract_console_act(mob/user, action, list/params, obj/machinery/machine)
	var/list/result = econ_contract_act(user, action, params)
	if(!result)
		return FALSE
	econ_contract_answer(user, result, machine)
	return TRUE

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
		Взявший контракт получает [settings.contract_performer_share]% награды (с налогом), остальное - отделу. У контракта без исполнителя [settings.contract_team_share]% награды делят те, кто над ним работал, по вкладу; общую работу отдела вроде продажи энергии или нормы руды - поровну отдел на смене. \
		Личные заказы видите только вы: награда меньше, но вам идёт [settings.contract_personal_share]%, а подборку можно обновить раз в [DisplayTimeText(ECON_CONTRACT_REROLL_COOLDOWN)]. \
		Серия - [ECON_CONTRACT_CHAIN_STAGES] поставки подряд: каждый этап оплачивается сразу, за последний - премия [settings.contract_chain_bonus]% от суммы этапов. \
		Спрос: каждая сдача одного и того же заказа снижает его награду на [settings.contract_repeat_step]% (не ниже [settings.contract_repeat_floor]%), за [rotation_minutes] мин. спрос возвращается на один шаг. \
		Репутация подрядчика растёт с закрытыми контрактами и падает за отказы и сорванные сроки: [econ_contract_ranks_text()]. \
		От взятого контракта можно отказаться: неначатый уйдёт с доски, начатый снова станет свободным, а новый контракт отказавшийся возьмёт через [DisplayTimeText(ECON_CONTRACT_DROP_COOLDOWN)]. \
		Срочные контракты платят [econ_times_text(settings.contract_urgent_mult)] больше, но снимаются через [settings.contract_urgent_minutes] мин. \
		Невзятые контракты сменяются через [rotation_minutes] мин., начатые - через [rotation_minutes * ECON_CONTRACT_STALE_ROTATIONS] мин., отгруженное по ним не возвращается. Купленное в автоматах и через снабжение по контрактам не засчитывается. \
		Спецзаказы партнёров снабжения тоже сдаются на паде подработки: первая сдача берёт спецзаказ, оплата за штуки идёт отделу сдавшего (снабжению - сбор [settings.cargo_handling_fee]%), сдавшему лично - [settings.contract_team_share]% с налогом, маржа при выполнении - тому же отделу. Контрабандные спецзаказы - только шаттлом снабжения. 		Объявления экипажа: любой может заказать работу у других, награда от [settings.crew_request_min] до [settings.crew_request_max] кр. сразу уходит в депозит и достаётся исполнителю, когда заказчик примет работу; сданную работу он принимает или отклоняет за [DisplayTimeText(ECON_CREW_REQUEST_ACCEPT_TIME)], иначе она принята. Налога и доли отдела с объявлений нет."
