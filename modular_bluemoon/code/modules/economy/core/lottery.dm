/datum/controller/subsystem/economy
	var/datum/econ_lottery/lottery

/// Открывает продажу билетов; вторая лотерея, пока идёт первая, не начинается.
/datum/controller/subsystem/economy/proc/start_lottery()
	if(lottery)
		return null
	lottery = new
	return lottery

/// Розыгрыш секторальной лотереи: билеты продаются с личных счетов, банк держит свой системный счёт, NT забирает долю, остальное - победителю.
/datum/econ_lottery
	var/datum/bank_account/system/pool
	var/ticket_price
	var/house_share
	var/tickets_per_account
	var/ends_at
	/// "номер счёта" -> билетов
	var/list/tickets = list()
	var/draw_timer

/datum/econ_lottery/New()
	var/datum/economy_settings/settings = SSeconomy.settings
	ticket_price = settings.lottery_ticket_price
	house_share = settings.lottery_house_share
	tickets_per_account = settings.lottery_tickets_per_account
	ends_at = world.time + settings.lottery_sale_minutes MINUTES
	pool = new("Лотерея сектора")
	draw_timer = addtimer(CALLBACK(src, PROC_REF(draw)), settings.lottery_sale_minutes MINUTES, TIMER_STOPPABLE)
	var/text = "Открыта продажа билетов секторальной лотереи: [ticket_price] кр. за билет, до [tickets_per_account] билетов на счёт, в приложении \"Кошелёк\" КПК. Розыгрыш через [settings.lottery_sale_minutes] мин.: [100 - house_share]% выручки получает владелец выигравшего билета, [house_share]% забирает NT."
	SSmarket.publish(text)
	minor_announce(text, "Лотерея сектора")

/datum/econ_lottery/Destroy()
	deltimer(draw_timer)
	refund_tickets()
	QDEL_NULL(pool)
	if(SSeconomy.lottery == src)
		SSeconomy.lottery = null
	return ..()

/datum/econ_lottery/proc/sold()
	. = 0
	for(var/number in tickets)
		. += tickets[number]

/datum/econ_lottery/proc/prize_now()
	return pool.account_balance - round(pool.account_balance * house_share / 100)

/// Покупка count билетов с личного счёта; null или текст отказа.
/datum/econ_lottery/proc/buy(datum/bank_account/account, count, mob/user)
	if(world.time >= ends_at)
		return "Продажа билетов закрыта."
	. = SSeconomy.personal_account_problem(account, TRUE)
	if(.)
		return
	if(!isnum(count) || round(count) < 1)
		return "Неверное число билетов."
	count = round(count)
	var/have = tickets["[account.account_id]"] || 0
	if(have + count > tickets_per_account)
		return "Не больше [tickets_per_account] билетов на счёт, у вас уже [have]."
	var/cost = count * ticket_price
	if(!account.has_money(cost))
		return "Недостаточно средств: нужно [cost] кр."
	if(!SSeconomy.move(account, pool, cost, ECON_LOTTERY, user, "Лотерейные билеты: [count]"))
		return "Платёж отклонён."
	tickets["[account.account_id]"] = have + count
	return null

/// Лотерея снята до розыгрыша: проданные билеты возвращаются владельцам.
/datum/econ_lottery/proc/refund_tickets()
	for(var/number in tickets)
		var/datum/bank_account/account = SSeconomy.find_account(text2num(number))
		var/amount = min(tickets[number] * ticket_price, pool?.account_balance)
		if(account && !QDELETED(account) && amount > 0)
			SSeconomy.move(pool, account, amount, ECON_REFUND, memo = "Возврат лотерейных билетов")
	tickets.Cut()

/datum/econ_lottery/proc/draw()
	var/list/weights = list()
	for(var/number in tickets)
		var/datum/bank_account/account = SSeconomy.find_account(text2num(number))
		if(account && !QDELETED(account) && account.state != ACCOUNT_DORMANT)
			weights[account] = tickets[number]
	var/total = pool.account_balance
	if(!length(tickets) || total <= 0)
		SSmarket.publish("Розыгрыш секторальной лотереи не состоялся: билетов не продано.")
		qdel(src)
		return
	if(!length(weights))
		SSeconomy.move(pool, null, total, ECON_LOTTERY_HOUSE, memo = "Лотерея без победителя")
		SSmarket.publish("Розыгрыш секторальной лотереи не состоялся: владельцев билетов нет на смене, банк [total] кр. уходит NT.")
		tickets.Cut()
		qdel(src)
		return
	var/datum/bank_account/winner = pickweight(weights)
	var/cut = round(total * house_share / 100)
	if(cut > 0)
		SSeconomy.move(pool, null, cut, ECON_LOTTERY_HOUSE, memo = "Доля NT с лотереи")
	var/prize = pool.account_balance
	SSeconomy.move(pool, winner, prize, ECON_LOTTERY_PRIZE, memo = "Выигрыш в лотерею сектора")
	winner.bank_card_talk("Ваш билет выиграл в лотерее сектора: +[prize] кр.!")
	var/text = "Розыгрыш секторальной лотереи завершён: продано [sold()] билетов, выигрыш [prize] кр. получает [winner.account_holder]. Доля NT - [cut] кр."
	SSmarket.publish(text)
	minor_announce(text, "Лотерея сектора")
	log_econ("Лотерея: победитель [winner.account_holder] (№[winner.account_id]), выигрыш [prize] кр., доля NT [cut] кр., билетов [sold()]")
	tickets.Cut()
	qdel(src)

/datum/econ_lottery/proc/ui_entry(datum/bank_account/account)
	return list(
		"price" = ticket_price,
		"house_share" = house_share,
		"per_account" = tickets_per_account,
		"sold" = sold(),
		"prize" = prize_now(),
		"minutes_left" = max(CEILING((ends_at - world.time) / (1 MINUTES), 1), 0),
		"mine" = account ? (tickets["[account.account_id]"] || 0) : 0,
	)
