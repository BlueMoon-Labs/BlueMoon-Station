/datum/controller/subsystem/market
	/// Джекпот игровых автоматов сектора из ставок этой смены: один на все автоматы, лежит наличными в обороте
	var/slot_jackpot = 0
	/// Часть джекпота, перенесённая с прошлых смен: при выплате NT выпускает её заново
	var/slot_jackpot_carried = 0

/// Сколько сейчас в джекпоте сектора, без гарантии NT.
/datum/controller/subsystem/market/proc/slot_jackpot_total()
	return round(slot_jackpot + slot_jackpot_carried)

/// Сколько получит сорвавший джекпот: накопленное, но не меньше гарантии NT.
/datum/controller/subsystem/market/proc/slot_jackpot_payout()
	return max(slot_jackpot_total(), SSeconomy.settings.slot_jackpot_floor)

/// Доля ставки в джекпот сектора.
/datum/controller/subsystem/market/proc/add_slot_jackpot(amount)
	if(amount > 0)
		slot_jackpot += amount

/// Выплата джекпота сектора: перенесённое с прошлых смен и доплату до гарантии NT выпускает в наличные; дробный остаток ставок остаётся в джекпоте. Возвращает выплату.
/datum/controller/subsystem/market/proc/pay_slot_jackpot(mob/user)
	var/payout = slot_jackpot_payout()
	var/backed = round(slot_jackpot)
	if(payout > backed)
		SSeconomy.move(null, SSeconomy.cash_account, payout - backed, ECON_GAMBLING_WIN, user, "Джекпот сектора")
	slot_jackpot -= backed
	slot_jackpot_carried = 0
	log_econ("Джекпот игровых автоматов сектора сорван[user ? " ([key_name(user)])" : ""]: [payout] кр., из ставок смены [backed] кр.")
	return payout

/// Где сорвали джекпот: новость сектора всегда, объявление ЦК - только от SLOT_JACKPOT_ANNOUNCE_MIN.
/datum/controller/subsystem/market/proc/announce_slot_jackpot(winner_name, area/where, amount)
	publish("[winner_name] срывает джекпот игровых автоматов сектора: [amount] кр.[where ? " ([where.name])" : ""]")
	if(amount >= SLOT_JACKPOT_ANNOUNCE_MIN)
		priority_announce("[winner_name] срывает джекпот игровых автоматов сектора в [where ? where.name : "неизвестном месте"]: [amount] кр.!")
