/datum/econ_request/treasury
	var/amount

/datum/econ_request/treasury/New(department_id, amount, reason, requester, requester_account_id)
	..(department_id, null, requester, requester_account_id, reason)
	src.amount = amount

/datum/econ_request/treasury/ui_entry()
	return list(
		"uid" = uid,
		"department_id" = department_id,
		"amount" = amount,
		"requester" = requester,
		"reason" = reason,
		"status" = status,
	)

/datum/controller/subsystem/economy
	/// Запросы глав отделов о переводе из казны, ожидающие и последние решённые
	var/list/treasury_requests = list()

/datum/economy_department/proc/staff_accounts()
	. = list()
	for(var/datum/bank_account/member as anything in SSeconomy.bank_accounts)
		if(member.department_id == id && !member.offstation)
			. += member

/datum/economy_department/proc/is_staff_account(datum/bank_account/member)
	return member && member.department_id == id && !member.offstation && (member in SSeconomy.bank_accounts)

/datum/economy_department/proc/pay_bonus(datum/bank_account/member, amount, mob/living/user)
	if(!can_manage(user) || !is_staff_account(member) || member.state == ACCOUNT_FROZEN || !isnum(amount) || amount < 1)
		return FALSE
	amount = round(amount)
	var/net = SSeconomy.pay_personal(account, member, amount, ECON_BONUS, user, "Премия: [name]")
	if(net <= 0)
		return FALSE
	log_econ("[key_name(user)] выписал премию [amount] кр. из бюджета [name] счёту [member.account_holder] №[member.account_id]")
	member.bank_card_talk("Премия от главы отдела «[name]»: [amount] кр. до налога, на руки [net] кр.", balloon = "премия +[net] кр")
	return TRUE

/// Счёт пользователя: он владелец или это счёт, на который ему платят.
/proc/econ_own_account(datum/bank_account/account, mob/user)
	return account && (account.owned_by(user) || econ_account_of(user) == account)

/datum/economy_department/proc/set_wage_bonus(datum/bank_account/member, percent, mob/living/user)
	if(!can_manage(user) || !is_staff_account(member) || !isnum(percent) || econ_own_account(member, user))
		return FALSE
	member.wage_bonus = clamp(round(percent), 0, SSeconomy.settings.max_wage_bonus)
	log_econ("[key_name(user)] выставил надбавку [member.wage_bonus]% счёту [member.account_holder] №[member.account_id] отдела [name]")
	member.bank_card_talk("Надбавка к зарплате: [member.wage_bonus]%.")
	return TRUE

/datum/economy_department/proc/pending_treasury_requests()
	. = 0
	for(var/datum/econ_request/treasury/request as anything in SSeconomy.treasury_requests)
		if(request.department_id == id && request.status == ECON_REQUEST_PENDING)
			.++

/datum/economy_department/proc/request_treasury(amount, reason, mob/living/user)
	if(id == ACCOUNT_CMD || !can_manage(user) || !isnum(amount))
		return null
	amount = round(amount)
	if(amount < 1 || amount > SSeconomy.settings.treasury_request_max)
		return null
	if(pending_treasury_requests() >= SSeconomy.settings.treasury_requests_pending_per_department)
		return null
	var/datum/bank_account/requester_account = econ_account_of(user)
	var/datum/econ_request/treasury/request = new(id, amount, reason, econ_public_name(user), requester_account?.account_id)
	SSeconomy.treasury_requests += request
	econ_trim_resolved(SSeconomy.treasury_requests)
	log_econ("[key_name(user)] запросил из казны [amount] кр. для [name] (запрос [request.uid]), причина: [reason]")
	return request

/datum/controller/subsystem/economy/proc/resolve_treasury_request(uid, approve, mob/living/user)
	var/datum/economy_department/command = get_department(ACCOUNT_CMD)
	if(!command?.can_manage(user))
		return FALSE
	for(var/datum/econ_request/treasury/request as anything in treasury_requests)
		if(request.uid != uid)
			continue
		if(request.status != ECON_REQUEST_PENDING)
			return FALSE
		if(approve && !treasury_transfer(get_department(request.department_id), request.amount, user))
			return FALSE
		request.status = approve ? ECON_REQUEST_APPROVED : ECON_REQUEST_DENIED
		log_econ("[key_name(user)] [approve ? "одобрил" : "отклонил"] запрос [request.uid] из казны: [request.amount] кр. для [request.department_id]")
		request.notify_requester("Запрос из казны на [request.amount] кр. [approve ? "одобрен, деньги в бюджете отдела" : "отклонён"].")
		econ_trim_resolved(treasury_requests)
		return TRUE
	return FALSE
