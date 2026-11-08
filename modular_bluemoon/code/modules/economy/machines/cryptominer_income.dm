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
	. = clamp(settings.crypto_cap_per_tick - crypto_paid[key], 0, amount)
	if(.)
		crypto_paid[key] += .

/// Зачисление дохода майнера: в бюджет отдела целиком, на личный счёт - с налогом. Возвращает зачисленное до налога.
/datum/controller/subsystem/economy/proc/pay_crypto(datum/bank_account/account, amount, obj/machinery/miner)
	var/allowed = crypto_allowance(account, amount)
	if(!allowed)
		return 0
	if(istype(account, /datum/bank_account/department))
		return account.credit(allowed, ECON_CRYPTO, memo = "Криптомайнинг") ? allowed : 0
	return pay_personal(null, account, allowed, ECON_CRYPTO, memo = "Криптомайнинг") ? allowed : 0

/// Строка осмотра майнера о потолке дохода.
/proc/econ_crypto_cap_text()
	return "Все майнеры вместе зачисляют на один счёт не больше [SSeconomy.settings.crypto_cap_per_tick] кр. за [round(SSeconomy.wait / (1 MINUTES), 1)] мин., остальное намайненное сгорает. С дохода на личный счёт удерживается налог."
