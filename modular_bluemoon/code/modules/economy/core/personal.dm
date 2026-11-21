#define ECON_CARD_BALLOON_COOLDOWN (2 SECONDS)

/datum/bank_account
	COOLDOWN_DECLARE(personal_payment_cooldown)

/mob
	/// Вид всплывашки карты ("зарплата", "чаевые"...) -> world.time, с которого её снова можно показать
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

/// Строка осмотра своей карты или КПК: где тратить деньги. Только владельцу счёта, который может платить и за смену ещё ничего не купил в магазине или каталоге; иначе null.
/proc/econ_wallet_examine_hint(datum/bank_account/account, mob/user)
	if(!account || account.shop_used || account != econ_account_of(user) || SSeconomy.personal_account_problem(account, TRUE))
		return null
	if(account.offstation)
		return span_notice("Потратить деньги - Кошелёк на КПК, блок «Куда потратить»: заплатить человеку рядом или попросить у него оплату, магазин - себе только на станции, в подарок всегда.")
	return span_notice("Потратить деньги - Кошелёк на КПК, блок «Куда потратить» на первом экране: магазин с доставкой капсулой, заплатить человеку рядом или попросить у него оплату, заказ из каталога.")

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

/datum/controller/subsystem/economy/proc/personal_payment(datum/bank_account/source, datum/bank_account/target, amount, reason, mob/user, memo, list/history_names)
	. = check_personal_payment(source, target, amount)
	if(.)
		return
	if(!move(source, target, amount, reason, user, memo, history_names = history_names))
		return "Платёж отклонён."
	COOLDOWN_START(source, personal_payment_cooldown, settings.transfer_cooldown_seconds SECONDS)
	return null

/// Текст игрока к деньгам (комментарий, гравировка, кличка): обрезка по сырому тексту до max_length. Возвращает list(очищенный текст или null, отказ или null, сырой обрезанный текст); пустой текст - list("", null, "").
/proc/econ_player_text(mob/user, text, max_length)
	if(isnum(text))
		text = "[text]"
	if(!istext(text))
		return list("", null, "")
	text = trim(copytext_char(trim(text), 1, max_length + 1))
	if(!length(text))
		return list("", null, "")
	if(econ_ic_muted(user))
		return list(null, "Вам запрещено говорить в IC, поэтому свой текст не добавить.", text)
	if(CHAT_FILTER_CHECK(text))
		return list(null, "В тексте есть запрещённые слова.", text)
	return list(sanitize(text), null, text)

/// Личный перевод без налога; payer_name и payee_name - имена с ID-карт сторон для оплаты рядом: получатель видит payer_name, а истории обеих сторон - имена с карт без номеров счетов; memo_checked - комментарий уже проверен и очищен. Возвращает null или текст отказа.
/datum/controller/subsystem/economy/proc/send_transfer(datum/bank_account/source, datum/bank_account/target, amount, mob/user, memo, payer_name, payee_name, memo_checked = FALSE)
	if(!memo_checked)
		var/list/memo_result = econ_player_text(user, memo, ECON_TRANSFER_MEMO_MAX)
		if(memo_result[2])
			return memo_result[2]
		memo = memo_result[1]
	var/list/history_names = (payer_name || payee_name) ? list(payer_name || source?.account_holder, payee_name || target?.account_holder) : null
	. = personal_payment(source, target, amount, ECON_TRANSFER, user, length(memo) ? "Перевод: [memo]" : null, history_names)
	if(.)
		return
	if(length(memo))
		log_econ("[key_name(user)]: перевод [round(amount)] кр. [source.account_holder] -> [target.account_holder] с комментарием \"[memo]\"")
		log_game("[key_name(user)] перевёл [round(amount)] кр. [target.account_holder] с комментарием \"[memo]\"")
	target.bank_card_talk("Поступил перевод [round(amount)] кр. от [payer_name || source.account_holder][length(memo) ? ": [memo]" : ""].", balloon = "перевод +[round(amount)] кр")

/// Чаевые без налога. Возвращает null или текст отказа.
/datum/controller/subsystem/economy/proc/send_tip(datum/bank_account/source, datum/bank_account/target, amount, mob/user)
	. = personal_payment(source, target, amount, ECON_TIP, user, "Чаевые от [source?.account_holder]")
	if(.)
		return
	target.bank_card_talk("Чаевые: +[round(amount)] кр. от [source.account_holder].", balloon = "чаевые +[round(amount)] кр")

GLOBAL_LIST_EMPTY(econ_pay_requests)
GLOBAL_VAR_INIT(econ_pay_request_serial, 0)

/datum/bank_account
	COOLDOWN_DECLARE(pay_request_cooldown)
	/// REF счёта -> world.time, с которого этот счёт снова может просить у него оплату
	var/list/pay_request_pair_ready
	/// REF счетов, чьи запросы оплаты этот счёт заглушил
	var/list/pay_request_muted

/// Запрос оплаты у человека рядом: ждёт в Кошельке плательщика, пока тот оплатит или отклонит, не дольше ECON_PAY_REQUEST_TTL.
/datum/econ_pay_request
	var/id
	var/datum/weakref/requester_ref
	/// Имя просителя с его ID-карты
	var/requester_name
	var/datum/weakref/payer_ref
	/// Имя плательщика с его ID-карты, как его видел проситель
	var/payer_name
	var/amount
	/// За что просят, уже очищенное
	var/reason

/datum/econ_pay_request/New(datum/bank_account/requester, requester_name, datum/bank_account/payer, payer_name, amount, reason)
	id = ++GLOB.econ_pay_request_serial
	requester_ref = WEAKREF(requester)
	src.requester_name = requester_name
	payer_ref = WEAKREF(payer)
	src.payer_name = payer_name
	src.amount = amount
	src.reason = reason
	GLOB.econ_pay_requests += src
	addtimer(CALLBACK(src, PROC_REF(expire)), ECON_PAY_REQUEST_TTL)

/datum/econ_pay_request/Destroy()
	GLOB.econ_pay_requests -= src
	return ..()

/datum/econ_pay_request/proc/expire()
	var/datum/bank_account/requester = requester_ref.resolve()
	var/datum/bank_account/payer = payer_ref.resolve()
	log_econ("Запрос оплаты #[id] [amount] кр. от [requester?.account_holder] к [payer?.account_holder] истёк без ответа")
	qdel(src)

/// Запросы оплаты, которые ждут ответа account.
/proc/econ_pay_requests_for(datum/bank_account/account)
	. = list()
	if(!account)
		return
	for(var/datum/econ_pay_request/request as anything in GLOB.econ_pay_requests)
		if(request.payer_ref.resolve() == account)
			. += request

/// requester (на его карте requester_name) просит payer (на карте payer_name) заплатить amount за reason. Возвращает list(отправлен ли, ответ игроку).
/proc/econ_request_payment(mob/living/user, datum/bank_account/requester, requester_name, datum/bank_account/payer, payer_name, amount, reason)
	var/problem = SSeconomy.personal_account_problem(requester, FALSE)
	if(problem)
		return list(FALSE, problem)
	if(requester == payer)
		return list(FALSE, "Нельзя просить оплату у самого себя.")
	if(istext(amount))
		amount = text2num(amount)
	var/amount_max = SSeconomy.settings.transfer_max
	if(!isnum(amount) || round(amount) < 1 || round(amount) > amount_max)
		return list(FALSE, "Просить можно от 1 до [amount_max] кр.")
	amount = round(amount)
	var/list/reason_result = econ_player_text(user, reason, ECON_TRANSFER_MEMO_MAX)
	if(reason_result[2])
		return list(FALSE, reason_result[2])
	reason = reason_result[1]
	if(!length(reason))
		return list(FALSE, "Напишите, за что просите оплату.")
	if(!COOLDOWN_FINISHED(requester, pay_request_cooldown))
		return list(FALSE, "Просить оплату можно не чаще раза в [DisplayTimeText(ECON_PAY_REQUEST_COOLDOWN)]: подождите ещё [DisplayTimeText(COOLDOWN_TIMELEFT(requester, pay_request_cooldown))].")
	var/pair_ready = LAZYACCESS(requester.pay_request_pair_ready, REF(payer))
	if(world.time < pair_ready)
		return list(FALSE, "У этого человека вы уже недавно просили оплату: подождите ещё [DisplayTimeText(pair_ready - world.time)].")
	if(REF(requester) in payer.pay_request_muted)
		return list(FALSE, "[payer_name] не принимает от вас запросы оплаты.")
	if(length(econ_pay_requests_for(payer)) >= ECON_PAY_REQUESTS_PER_PAYER)
		return list(FALSE, "У [payer_name] уже ждут ответа другие запросы оплаты, попросите чуть позже.")
	COOLDOWN_START(requester, pay_request_cooldown, ECON_PAY_REQUEST_COOLDOWN)
	LAZYSET(requester.pay_request_pair_ready, REF(payer), world.time + ECON_PAY_REQUEST_PAIR_COOLDOWN)
	var/datum/econ_pay_request/request = new(requester, requester_name, payer, payer_name, amount, reason)
	log_econ("[key_name(user)] запросил оплату #[request.id] [amount] кр. со счёта [payer.account_holder] ([payer.account_id]) на счёт [requester.account_holder] ([requester.account_id]) за \"[reason]\"")
	log_game("[key_name(user)] запросил у [payer.account_holder] [amount] кр. за \"[reason]\"")
	payer.bank_card_talk("[requester_name] просит [amount] кр. за «[reason]». Оплатить или отклонить - в Кошельке КПК, вкладка «Перевод».", balloon = "запрос оплаты [amount] кр")
	return list(TRUE, "Запрос на [amount] кр. отправлен: [payer_name] увидит его в своём Кошельке.")

/// Плательщик отвечает на запрос оплаты: answer - "pay", "decline" или "mute" (отклонить и больше не принимать запросы от этого человека). payer_name - имя с его ID-карты для просителя. Возвращает list(принят ли ответ, ответ игроку).
/proc/econ_answer_pay_request(mob/living/user, datum/bank_account/account, request_id, answer, payer_name)
	if(istext(request_id))
		request_id = text2num(request_id)
	var/datum/econ_pay_request/request
	for(var/datum/econ_pay_request/waiting as anything in econ_pay_requests_for(account))
		if(waiting.id == request_id)
			request = waiting
	if(!request)
		return list(FALSE, "Этого запроса уже нет: срок вышел.")
	var/datum/bank_account/requester = request.requester_ref.resolve()
	if(answer == "pay")
		var/error = SSeconomy.send_transfer(account, requester, request.amount, user, request.reason, payer_name || account.account_holder, request.requester_name, memo_checked = TRUE)
		if(error)
			return list(FALSE, error)
		log_econ("[key_name(user)] оплатил запрос #[request.id] [request.amount] кр. счёту [requester.account_holder] ([requester.account_id])")
		var/paid_text = "Оплачено [request.amount] кр. → [request.requester_name]."
		qdel(request)
		return list(TRUE, paid_text)
	if(answer != "decline" && answer != "mute")
		return list(FALSE, "Неизвестный ответ.")
	if(answer == "mute" && requester)
		LAZYOR(account.pay_request_muted, REF(requester))
		for(var/datum/econ_pay_request/other as anything in econ_pay_requests_for(account))
			if(other != request && other.requester_ref == request.requester_ref)
				qdel(other)
	log_econ("[key_name(user)] отклонил запрос оплаты #[request.id] [request.amount] кр. от [requester?.account_holder][answer == "mute" ? " и заглушил запросы от этого счёта" : ""]")
	requester?.bank_card_talk("[request.payer_name] отклоняет ваш запрос на [request.amount] кр. за «[request.reason]».")
	qdel(request)
	return list(TRUE, answer == "mute" ? "Запрос отклонён, больше этот человек просить оплату у вас не сможет." : "Запрос отклонён.")

#undef ECON_CARD_BALLOON_COOLDOWN
