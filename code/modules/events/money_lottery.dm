/// Взнос "за верификацию" из скам-варианта заметки
#define MONEY_LOTTERY_SCAM_FEE 500

/// Секторальная лотерея (порт идеи Baystation): ньюскастеры печатают итоги розыгрыша.
/// В половине случаев джекпот падает на настоящий счёт кого-то из экипажа - деньги
/// зачисляются мгновенно. Иначе печатается скам-заметка про "вышлите взнос за повторную
/// верификацию выигрыша". Чистый амбиент: газета, слухи и один внезапно богатый ассистент.
/datum/round_event_control/money_lottery
	name = "Money Lottery"
	typepath = /datum/round_event/money_lottery
	weight = 20
	max_occurrences = 2
	earliest_start = 15 MINUTES
	alert_observers = FALSE
	category = EVENT_CATEGORY_BUREAUCRATIC
	// Экономические события (лотерея, обвал рынка, страховка, ошибка отгрузки) в одном
	// семействе: общий фолл-офф, чтобы раунд не превращался в биржевую сводку.
	family = "economy"
	disruption = DIRECTOR_DISRUPTION_AMBIENT // газетная заметка никому не мешает
	description = "Newscasters print lottery results: a real crew account wins, or a scam asks for a processing fee."

/datum/round_event/money_lottery
	fakeable = FALSE

/datum/round_event/money_lottery/start()
	var/prize = pick(2000, 5000, 10000, 25000, 50000)
	var/list/datum/bank_account/candidates = list()
	for(var/datum/bank_account/account as anything in SSeconomy.bank_accounts)
		if(!account.account_holder)
			continue
		candidates += account
	var/body
	if(length(candidates) && prob(50))
		var/datum/bank_account/winner = pick(candidates)
		winner.adjust_money(prize, "Джекпот секторальной лотереи")
		body = "Еженедельный розыгрыш секторальной лотереи завершён! Обладателем джекпота в [prize] кредитов становится [winner.account_holder]! Средства уже зачислены на счёт победителя. Поздравляем и напоминаем: удача любит настойчивых."
	else
		body = "Еженедельный розыгрыш секторальной лотереи завершён! Обладателем джекпота в [prize] кредитов становится [random_unique_name(pick(MALE, FEMALE))]! К сожалению, победитель не подтвердил банковские реквизиты в отведённый срок. Если вы считаете, что это ваш билет - вышлите регистрационный взнос в [MONEY_LOTTERY_SCAM_FEE] кредитов на счёт лотерейной комиссии для повторной верификации."
	GLOB.news_network.SubmitArticle(body, "Лотерейная Комиссия Сектора", "Станционные Объявления")

#undef MONEY_LOTTERY_SCAM_FEE
