/datum/controller/subsystem/economy
	/// Номер счёта -> сколько криптомайнеры зачислили на него за текущий тик экономики
	var/list/crypto_paid = list()
	/// Тик экономики, к которому относится crypto_paid
	var/crypto_paid_tick = -1

/// Сколько из amount майнеры ещё могут зачислить на счёт в этом тике; сразу записывает это как зачисленное.
/datum/controller/subsystem/economy/proc/crypto_allowance(datum/bank_account/account, amount)
	if(!account || amount <= 0)
		return 0
	if(crypto_paid_tick != fire_count)
		crypto_paid = list()
		crypto_paid_tick = fire_count
	var/key = "[account.account_id]"
	. = clamp(crypto_cap_for(account) - crypto_paid[key], 0, amount)
	if(.)
		crypto_paid[key] += .

/// Потолок майнинга за тик на счёт: бюджеты Deep Space и Таркова живут майнингом и экспортом без грантов станции, им потолок выше.
/datum/controller/subsystem/economy/proc/crypto_cap_for(datum/bank_account/account)
	var/datum/bank_account/department/budget = account
	if(istype(budget) && (budget.department_id in list(ACCOUNT_DS, ACCOUNT_TAR)))
		return settings.crypto_cap_offstation_per_tick
	return settings.crypto_cap_per_tick

/// Зачисление дохода майнера: в бюджет отдела целиком, на личный счёт - с налогом. Возвращает зачисленное до налога.
/datum/controller/subsystem/economy/proc/pay_crypto(datum/bank_account/account, amount, obj/machinery/miner)
	if(round_over())
		return 0
	var/allowed = crypto_allowance(account, amount)
	if(!allowed)
		return 0
	if(istype(account, /datum/bank_account/department))
		return account.credit(allowed, ECON_CRYPTO, memo = "Криптомайнинг") ? allowed : 0
	return pay_personal(null, account, allowed, ECON_CRYPTO, memo = "Криптомайнинг") ? allowed : 0

/// Строка осмотра майнера о потолке дохода.
/proc/econ_crypto_cap_text()
	return "Все майнеры вместе зачисляют на один счёт не больше [SSeconomy.settings.crypto_cap_per_tick] кр. за [round(SSeconomy.wait / (1 MINUTES), 1)] мин. (на бюджет Deep Space или Таркова - [SSeconomy.settings.crypto_cap_offstation_per_tick] кр.), остальное намайненное сгорает. С дохода на личный счёт удерживается налог."
