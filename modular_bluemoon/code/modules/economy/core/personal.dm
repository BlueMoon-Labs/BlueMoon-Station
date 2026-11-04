#define ECON_CARD_BALLOON_COOLDOWN (2 SECONDS)

/datum/bank_account
	COOLDOWN_DECLARE(personal_payment_cooldown)

/mob
	/// Вид всплывашки карты («зарплата», «чаевые»...) -> world.time, с которого её снова можно показать
	var/list/econ_balloon_ready

/// Доходит ли сообщение карты до держателя: есть клиент и сообщения карты не выключены, если не force.
/datum/bank_account/proc/card_talk_reaches(mob/holder, force)
	return holder.client && (force || (holder.client.prefs.chat_toggles & CHAT_BANKCARD))

/// Всплывашка над держателем карты, видна только ему. Вид - первое слово; один вид не чаще ECON_CARD_BALLOON_COOLDOWN на держателя, force - всегда.
/datum/bank_account/proc/card_balloon(mob/holder, text, force)
	if(!text || !holder)
		return
	var/kind = copytext(text, 1, findtext(text, " "))
	if(!force && world.time < LAZYACCESS(holder.econ_balloon_ready, kind))
		return
	LAZYSET(holder.econ_balloon_ready, kind, world.time + ECON_CARD_BALLOON_COOLDOWN)
	show_card_balloon(holder, text)

/datum/bank_account/proc/show_card_balloon(mob/holder, text)
	holder.balloon_alert(holder, text)

/// Личный счёт экипажа или гост-роли: не бюджет, не системный, не внешний.
/datum/controller/subsystem/economy/proc/is_personal_account(datum/bank_account/account)
	return account && !QDELETED(account) && account.transferable && (account in bank_accounts)

/// Почему счёт не может платить (payer) или получать личные деньги; null - может.
/datum/controller/subsystem/economy/proc/personal_account_problem(datum/bank_account/account, payer)
	if(!account || QDELETED(account) || !(account in bank_accounts))
		return payer ? "Платить можно только с личного счёта." : "Получать деньги можно только на личный счёт."
	if(!account.transferable)
		return payer ? "Ваш счёт заблокирован." : "Счёт получателя заблокирован."
	if(payer && account.state == ACCOUNT_FROZEN)
		return "Ваш счёт заморожен."
	return null

/// Все неспящие личные счета с этим именем владельца, без учёта регистра.
/datum/controller/subsystem/economy/proc/find_accounts_by_name(name)
	. = list()
	if(!istext(name))
		return
	name = lowertext(trim(name))
	if(!length(name))
		return
	for(var/datum/bank_account/account as anything in bank_accounts)
		if(account.state != ACCOUNT_DORMANT && is_personal_account(account) && lowertext(account.account_holder) == name)
			. += account

/// Счёт по имени, только если он один: при тёзках null, чтобы деньги не ушли не тому.
/datum/controller/subsystem/economy/proc/find_account_by_name(name)
	var/list/found = find_accounts_by_name(name)
	return length(found) == 1 ? found[1] : null

/// Проверка личного платежа; null - можно, иначе текст отказа для игрока.
/datum/controller/subsystem/economy/proc/check_personal_payment(datum/bank_account/source, datum/bank_account/target, amount)
	. = personal_account_problem(source, TRUE) || personal_account_problem(target, FALSE)
	if(.)
		return
	if(source == target)
		return "Нельзя переводить самому себе."
	if(!isnum(amount) || round(amount) < 1)
		return "Неверная сумма."
	if(round(amount) > settings.transfer_max)
		return "Сумма выше лимита: не больше [settings.transfer_max] кр. за раз."
	if(!COOLDOWN_FINISHED(source, personal_payment_cooldown))
		return "Слишком часто, следующий платёж можно через: [DisplayTimeText(COOLDOWN_TIMELEFT(source, personal_payment_cooldown), 1)]."
	if(!source.has_money(round(amount)))
		return "Недостаточно средств: на счёте [source.account_balance] кр."
	return null

/datum/controller/subsystem/economy/proc/personal_payment(datum/bank_account/source, datum/bank_account/target, amount, reason, mob/user, memo)
	. = check_personal_payment(source, target, amount)
	if(.)
		return
	if(!move(source, target, amount, reason, user, memo))
		return "Платёж отклонён."
	COOLDOWN_START(source, personal_payment_cooldown, settings.transfer_cooldown_seconds SECONDS)
	return null

/// Личный перевод без налога. Возвращает null или текст отказа.
/datum/controller/subsystem/economy/proc/send_transfer(datum/bank_account/source, datum/bank_account/target, amount, mob/user, memo)
	if(istext(memo))
		memo = copytext_char(trim(sanitize(memo)), 1, ECON_TRANSFER_MEMO_MAX + 1)
	. = personal_payment(source, target, amount, ECON_TRANSFER, user, length(memo) ? "Перевод: [memo]" : null)
	if(.)
		return
	target.bank_card_talk("Поступил перевод [round(amount)] кр. от [source.account_holder].", balloon = "перевод +[round(amount)] кр")

/// Чаевые без налога. Возвращает null или текст отказа.
/datum/controller/subsystem/economy/proc/send_tip(datum/bank_account/source, datum/bank_account/target, amount, mob/user)
	. = personal_payment(source, target, amount, ECON_TIP, user, "Чаевые от [source?.account_holder]")
	if(.)
		return
	target.bank_card_talk("Чаевые: +[round(amount)] кр. от [source.account_holder].", balloon = "чаевые +[round(amount)] кр")

#undef ECON_CARD_BALLOON_COOLDOWN
