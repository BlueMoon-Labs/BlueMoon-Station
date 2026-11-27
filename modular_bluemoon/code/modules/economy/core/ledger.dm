/datum/economy_ledger
	var/minted = 0
	var/burned = 0
	/// reason -> сумма за раунд
	var/list/by_reason = list()
	var/list/minted_by_reason = list()
	var/list/burned_by_reason = list()
	/// Последние ECON_SNAPSHOT_MAX снимков: time, minted, burned, in_accounts, cash
	var/list/snapshots = list()
	var/last_minted = 0
	var/last_burned = 0
	/// Деньги бюджетов станционных отделов: эмиссия в бюджеты, сожжённое из них, ушедшее из них на счета и пришедшее со счетов
	var/department_minted = 0
	var/department_burned = 0
	var/department_paid_out = 0
	var/department_received = 0
	/// id отдела -> list("in", "out", "burned", "returned", "purchases", "purchase_amount") для панели калибровки; стартовый бюджет в "in" не входит
	var/list/department_flows = list()
	/// Бюджеты аванпостов (Deep Space, Тарков): id -> list("in", "spent", "burned"); их эмиссия отдельно от станционной
	var/list/outpost_flows = list()
	var/outpost_minted = 0
	var/list/outpost_minted_by_reason = list()
	/// id аванпоста -> reason -> его эмиссия, для строки итога смены
	var/list/outpost_minted_by_id = list()
	var/summary_logged = FALSE
	/// Дела аудита за смену: закрытые с возвратом считаются по closed_refunded, сколько вернули пострадавшим - в audit_refunded
	var/audit_opened = 0
	var/audit_closed_refunded = 0
	var/audit_refunded = 0
	var/audit_closed_dismissed = 0

/datum/bank_account
	/// Подъёмные смены: от них панель считает рост личных денег
	var/starting_funds = 0

/datum/bank_account/department
	/// Части защиты, ушедшие последним расходом бюджета: list(сумма, тик истечения)
	var/list/department_shield_spent = list()

/datum/supply_order
	/// Части защиты, потраченные предоплатой: отмена заказа возвращает их с прежними сроками
	var/list/shield_entries = list()

/datum/economy_ledger/proc/record(datum/bank_account/source, datum/bank_account/target, amount, reason)
	by_reason[reason] += amount
	if(!source)
		minted += amount
		minted_by_reason[reason] += amount
	if(!target)
		burned += amount
		burned_by_reason[reason] += amount
	if(reason == ECON_STARTING_FUNDS && target)
		target.starting_funds += amount
	record_outposts(source, target, amount, reason)
	var/from_budget = econ_is_station_budget(source)
	var/to_budget = econ_is_station_budget(target)
	var/datum/bank_account/department/payer_budget = from_budget ? source : null
	var/datum/bank_account/department/payee_budget = to_budget ? target : null
	if(payer_budget && reason != ECON_BUDGET_RETURN)
		payer_budget.department_shield_spent = payer_budget.department.consume_shield(amount)
	if(payee_budget && (reason in GLOB.econ_cap_shielded_reasons) && (!payer_budget || payer_budget.department_id == ACCOUNT_CMD))
		payee_budget.department.add_shield(amount)
	if(from_budget && to_budget)
		department_flow(payer_budget.department_id)["out"] += amount
		department_flow(payee_budget.department_id)["in"] += amount
		return
	if(!from_budget && !to_budget)
		return
	if(to_budget && !source && reason == ECON_REFUND)
		department_flow(payee_budget.department_id)["burned"] -= amount
		department_burned -= amount
		return
	var/datum/bank_account/department/station_budget = to_budget ? target : source
	var/list/flow = department_flow(station_budget.department_id)
	if(to_budget)
		flow["in"] += amount
		if(source)
			department_received += amount
		else
			department_minted += amount
		return
	if(target)
		flow["out"] += amount
		department_paid_out += amount
		return
	department_burned += amount
	flow["burned"] += amount
	if(reason == ECON_BUDGET_RETURN)
		flow["returned"] += amount
	if(reason == ECON_IMPORT)
		flow["purchases"] += 1
		flow["purchase_amount"] += amount

/datum/economy_ledger/proc/record_outposts(datum/bank_account/source, datum/bank_account/target, amount, reason)
	if(econ_is_outpost_budget(target))
		outpost_flow(target.department_id)["in"] += amount
		if(!source)
			outpost_minted += amount
			outpost_minted_by_reason[reason] += amount
			var/list/by_outpost = outpost_minted_by_id[target.department_id]
			if(!by_outpost)
				by_outpost = list()
				outpost_minted_by_id[target.department_id] = by_outpost
			by_outpost[reason] += amount
	if(econ_is_outpost_budget(source))
		outpost_flow(source.department_id)[target ? "spent" : "burned"] += amount

/datum/economy_ledger/proc/outpost_flow(id)
	var/list/flow = outpost_flows[id]
	if(!flow)
		flow = list("in" = 0, "spent" = 0, "burned" = 0)
		outpost_flows[id] = flow
	return flow

/datum/economy_ledger/proc/department_flow(id)
	var/list/flow = department_flows[id]
	if(!flow)
		flow = list("in" = 0, "out" = 0, "burned" = 0, "returned" = 0, "purchases" = 0, "purchase_amount" = 0)
		department_flows[id] = flow
	return flow

/// Доля стоков отделов; без with_return возврат излишка не входит ни в стоки, ни в оставшиеся деньги, без with_command казна не считается.
/datum/economy_ledger/proc/department_share_of(with_return = TRUE, with_command = TRUE)
	var/kept = 0
	var/burned_sum = 0
	for(var/id in department_flows)
		if(!with_command && id == ACCOUNT_CMD)
			continue
		var/list/flow = department_flows[id]
		kept += flow["in"] - flow["out"]
		burned_sum += flow["burned"]
		if(!with_return)
			kept -= flow["returned"]
			burned_sum -= flow["returned"]
	return kept > 0 ? burned_sum / kept : 0

/// Доля сожжённого из денег, оставшихся у отделов: (эмиссия в бюджеты + пришедшее со счетов - выплаченное на счета). Цель - department_sink_target_min..max из настроек.
/datum/economy_ledger/proc/department_sink_share()
	var/kept = department_minted + department_received - department_paid_out
	return kept > 0 ? department_burned / kept : 0

/proc/econ_reason_totals_text(list/totals)
	var/list/sorted = sortTim(totals.Copy(), GLOBAL_PROC_REF(cmp_numeric_dsc), associative = TRUE)
	var/list/parts = list()
	for(var/reason in sorted)
		if(sorted[reason])
			parts += "[reason] [num2text(sorted[reason], 12)]"
	return jointext(parts, ", ")

/// Строки итога смены для econ.log: по ним сверяется калибровка, панель калибровки на проде никто не открывает.
/datum/economy_ledger/proc/round_summary()
	. = list()
	. += "Итог смены: эмиссия [num2text(minted, 12)] кр. ([econ_reason_totals_text(minted_by_reason)]), сток [num2text(burned, 12)] кр. ([econ_reason_totals_text(burned_by_reason)])"
	. += "Итог смены: эмиссия станции [num2text(minted - outpost_minted, 12)] кр., аванпостов [num2text(outpost_minted, 12)] кр.[outpost_minted ? " ([econ_reason_totals_text(outpost_minted_by_reason)])" : ""]"
	. += "Итог смены: сток отделов [round(department_sink_share() * 100)]%, без возврата излишка [round(department_share_of(FALSE, TRUE) * 100)]%, на счетах [num2text(SSeconomy.total_money(), 12)] кр."
	var/list/parts = list()
	for(var/id in department_flows)
		var/list/flow = department_flows[id]
		var/datum/bank_account/budget = SSeconomy.get_dep_account(id)
		parts += "[id] [num2text(flow["in"], 12)]/[num2text(flow["out"], 12)]/[num2text(flow["burned"], 12)]/[num2text(flow["returned"], 12)]/[num2text(budget ? budget.account_balance : 0, 12)]"
	if(length(parts))
		. += "Итог смены по отделам (пришло за смену/выдано на счета и в другие отделы/сожжено/из него возврат излишка/остаток; стартовый бюджет в пришедшее не входит): [jointext(parts, ", ")]"
	parts = list()
	for(var/datum/bank_account/department/outpost as anything in SSeconomy.generated_accounts)
		if(!econ_is_outpost_budget(outpost))
			continue
		var/list/flow = outpost_flows[outpost.department_id] || list("in" = 0, "spent" = 0, "burned" = 0)
		var/list/reasons = outpost_minted_by_id[outpost.department_id]
		parts += "[outpost.department_id] [num2text(flow["in"], 12)]/[num2text(flow["spent"], 12)]/[num2text(flow["burned"], 12)]/[num2text(outpost.account_balance, 12)][length(reasons) ? " ([econ_reason_totals_text(reasons)])" : ""]"
	if(length(parts))
		. += "Итог смены по аванпостам (пришло/потрачено/сожжено/остаток): [jointext(parts, ", ")]"
	var/open_count = 0
	var/open_amount = 0
	for(var/datum/econ_audit_flag/flag as anything in SSeconomy.audit_flags)
		if(!flag.closed)
			open_count++
			open_amount += flag.amount
	. += "Аудит за смену: открыто дел [audit_opened], закрыто возвратом [audit_closed_refunded] (возвращено [num2text(audit_refunded, ECON_TEXT_DIGITS)] кр.), закрыто без возврата [audit_closed_dismissed], осталось открытыми [open_count] на [num2text(open_amount, ECON_TEXT_DIGITS)] кр."

/// Пишет итог смены в econ.log один раз за раунд, после продажи непроданных акций: её комиссии входят в итог. Возвращает TRUE, если записал.
/proc/econ_log_round_summary()
	if(SSeconomy.ledger.summary_logged)
		return FALSE
	SSmarket.sell_off_shares()
	SSeconomy.ledger.summary_logged = TRUE
	SSeconomy.flush_audit_logs()
	for(var/line in SSeconomy.ledger.round_summary())
		log_econ(line)
	return TRUE

/proc/econ_is_station_budget(datum/bank_account/account)
	var/datum/bank_account/department/budget = account
	return istype(budget) && !!budget.department

/// Бюджет аванпоста (Deep Space, Тарков) - по id: у станционного бюджета отдел проставляется уже после стартового зачисления.
/proc/econ_is_outpost_budget(datum/bank_account/account)
	var/datum/bank_account/department/budget = account
	return istype(budget) && (budget.department_id in list(ACCOUNT_TAR, ACCOUNT_DS))

/datum/economy_ledger/proc/snapshot()
	var/cash = SSeconomy.cash_account?.account_balance || 0
	snapshots += list(list(
		"time" = world.time,
		"minted" = minted - last_minted,
		"burned" = burned - last_burned,
		"in_accounts" = SSeconomy.total_money() - cash,
		"cash" = cash,
	))
	last_minted = minted
	last_burned = burned
	if(length(snapshots) > ECON_SNAPSHOT_MAX)
		snapshots.Cut(1, 2)

/datum/controller/subsystem/economy/proc/move(datum/bank_account/source, datum/bank_account/target, amount, reason, mob/actor, memo, log_tag, list/history_names)
	if(isnull(amount))
		return FALSE
	if(!isnum(amount) || amount != amount || abs(amount) == INFINITY)
		stack_trace("SSeconomy.move: недопустимая сумма [amount] ([reason])")
		return FALSE
	if(amount <= 0)
		return FALSE
	if(amount >= ECON_MOVE_AMOUNT_MAX)
		log_econ("Отклонено: [num2text(amount, ECON_TEXT_DIGITS)] кр.: [econ_move_side(source, "эмиссия")] -> [econ_move_side(target, "сток")] ([reason]), сумма не ниже потолка [num2text(ECON_MOVE_AMOUNT_MAX, ECON_TEXT_DIGITS)] кр.[actor ? " by [key_name(actor)]" : ""]")
		return FALSE
	amount = round(amount)
	if(!amount || source == target || (!source && !target))
		return FALSE
	if(!istext(reason) || !GLOB.econ_reason_category[reason])
		stack_trace("SSeconomy.move: неизвестная причина [reason]")
		return FALSE
	if(source)
		if(source.state == ACCOUNT_FROZEN && !(reason in GLOB.econ_reasons_ignore_freeze))
			return FALSE
		if(source == cash_account && source.account_balance < amount)
			move(null, source, amount - source.account_balance, ECON_FOUND_CASH, actor)
		if(source.account_balance < amount && !source.allow_debt)
			return FALSE
		source.account_balance -= amount
	if(target)
		target.account_balance += amount
	record_move(source, target, amount, reason, actor, memo, log_tag, history_names)
	return TRUE

/proc/econ_move_side(datum/bank_account/account, none_text)
	return account ? account.account_holder : none_text

/// Сумма, которую SSeconomy.move примет: число больше нуля и меньше ECON_MOVE_AMOUNT_MAX.
/proc/econ_amount_valid(amount)
	return isnum(amount) && amount > 0 && amount < ECON_MOVE_AMOUNT_MAX

/// Почему банк не зачислил наличные; money_name - имя предмета, а не сам предмет, иначе выйдет "the space cash".
/proc/econ_cash_refusal_text(money_name, amount)
	if(econ_amount_valid(amount))
		return "Банк не принял [money_name]."
	return "Банк не принял [money_name]: таких сумм наличными не бывает, это подделка или сбой. Деньги остались у вас."

/// Внесение наличных items из "Наличных в обороте" на target (null - сток) по reason. Строка econ.log с составом - если часть суммы выпущена как found_cash, если среди внесённого от ECON_CASH_IN_LOG_MIN кр. не со снятия со счёта или если банк отказал из-за суммы.
/datum/controller/subsystem/economy/proc/cash_in(list/items, datum/bank_account/target, amount, mob/user, memo, log_tag, reason = ECON_CASH_IN)
	var/list/note = econ_cash_note(items)
	var/found = cash_shortfall(amount)
	if(!move(cash_account, target, amount, reason, user, memo, log_tag))
		if(!isnull(amount) && amount != 0 && !econ_amount_valid(amount))
			log_econ("Отклонено внесение наличных: [num2text(amount, ECON_TEXT_DIGITS)] кр. на [econ_move_side(target, "сток")][user ? " by [key_name(user)]" : ""], сейчас [STATION_TIME_TIMESTAMP("hh:mm:ss", world.time)] по станции. Вносили: [note["text"]]")
		return FALSE
	note_cash_in(note, amount, econ_move_side(target, "сток"), user, found)
	return TRUE

/// Сколько из amount наличными "Наличные в обороте" не покрывают: столько move выпустит как found_cash.
/datum/controller/subsystem/economy/proc/cash_shortfall(amount)
	if(!econ_amount_valid(amount))
		return 0
	return max(round(amount) - cash_account.account_balance, 0)

/// Строка econ.log о внесённых наличных по составу note из econ_cash_note: found - выпущено как found_cash, uncovered - не покрыто оборотом, но ещё не выпущено (деньги остались в автомате). Без них - только если не со снятия со счёта от ECON_CASH_IN_LOG_MIN кр. из самой внесённой amount: чип на 5000 кр., оплативший 25 кр., строки не пишет.
/datum/controller/subsystem/economy/proc/note_cash_in(list/note, amount, where, mob/user, found = 0, uncovered = 0)
	var/unbacked = min(note["unbacked"], round(amount))
	if(found <= 0 && uncovered <= 0 && unbacked < ECON_CASH_IN_LOG_MIN)
		return
	var/sum = num2text(round(amount), ECON_TEXT_DIGITS)
	var/head = "Наличные не со снятия со счёта: [num2text(unbacked, ECON_TEXT_DIGITS)] кр. из внесённых [sum] кр."
	if(found > 0)
		head = "Найденные наличные: [num2text(found, ECON_TEXT_DIGITS)] кр. из внесённых [sum] кр."
	else if(uncovered > 0)
		head = "Наличные сверх оборота: [num2text(uncovered, ECON_TEXT_DIGITS)] кр. из внесённых [sum] кр."
	log_econ("[head] на [where][user ? " by [key_name(user)]" : ""], сейчас [STATION_TIME_TIMESTAMP("hh:mm:ss", world.time)] по станции. Вносили: [note["text"]]")

/// Состав наличных для econ.log, пока предметы живы: list("text" - пачки и голочипы с происхождением первыми, остальное - тип и сумма; "unbacked" - сумма не со снятия со счёта).
/proc/econ_cash_note(list/items)
	var/list/parts = list()
	var/list/others = list()
	var/unbacked = 0
	for(var/obj/item/money as anything in items)
		var/value = money.get_item_credit_value()
		if(!econ_cash_withdrawn(money))
			unbacked += value
		var/obj/item/stack/spacecash/bills = money
		var/obj/item/holochip/chip = money
		if(istype(bills))
			parts += "[bills.type] x[bills.amount] по [num2text(bills.value, ECON_TEXT_DIGITS)] кр. ([bills.origin || "происхождение не записано"])"
		else if(istype(chip))
			parts += "[chip.type] на [num2text(chip.credits, ECON_TEXT_DIGITS)] кр. ([chip.origin || "происхождение не записано"])"
		else
			others += "[money.type] на [num2text(value, ECON_TEXT_DIGITS)] кр."
	parts += others
	var/shown = 8
	if(length(parts) > shown)
		var/hidden = length(parts) - shown
		parts.Cut(shown + 1)
		parts += "и ещё [hidden] предм."
	return list("text" = jointext(parts, "; "), "unbacked" = unbacked)

#define ECON_CASH_ORIGIN_SEP " + "
#define ECON_CASH_ORIGIN_MORE "другие пачки"
#define ECON_CASH_WITHDRAWN_MARK "снято со счёта"
#define ECON_CASH_PASS_ON_MONEY ", деньги - "

/// Голочип целиком снят со счёта: такие при внесении не пишутся строкой о наличных не со снятия.
/proc/econ_cash_withdrawn(obj/item/money)
	var/obj/item/holochip/chip = money
	return istype(chip) && chip.withdrawn

/// Начало происхождения денег, снятых со счёта account.
/proc/econ_cash_withdrawn_origin(datum/bank_account/account, mob/user)
	return "[ECON_CASH_WITHDRAWN_MARK] [account?.account_holder] №[account?.account_id][user ? " by [key_name(user)]" : ""]"

/// Помечает голочип, только что снятый со счёта account.
/proc/econ_cash_mark_withdrawn(obj/item/holochip/chip, datum/bank_account/account, mob/user)
	if(!chip)
		return
	chip.withdrawn = TRUE
	chip.origin = econ_cash_origin_cap("[econ_cash_withdrawn_origin(account, user)], [chip.origin]")

/proc/econ_cash_origin_of(obj/item/money)
	var/obj/item/stack/spacecash/bills = money
	var/obj/item/holochip/chip = money
	if(istype(bills))
		return bills.origin
	if(istype(chip))
		return chip.origin

/// Голочип из ранее внесённых денег (сдача, вывод из аплинка): пометка снятия и происхождение - от них, how - откуда выдан. Деньги, уже выданные тем же how, второй раз не вкладываются: круг ввода и вывода не растит строку.
/proc/econ_cash_pass_on(obj/item/holochip/chip, from_origin, from_withdrawn, how)
	if(!chip)
		return
	chip.withdrawn = !!from_withdrawn
	var/money = from_origin || "происхождение не записано"
	if(findtext(money, "[how] ") == 1)
		var/inner = findtext(money, ECON_CASH_PASS_ON_MONEY)
		if(inner)
			money = copytext(money, inner + length(ECON_CASH_PASS_ON_MONEY))
	chip.origin = econ_cash_origin_cap("[how] [chip.origin][ECON_CASH_PASS_ON_MONEY][money]")

/// Происхождение пачки наличных: станционное время, где появилась, какой прок какого типа её создал и usr. Зовётся из Initialize самой пачки.
/proc/econ_cash_origin(atom/movable/thing, mapload)
	var/when = STATION_TIME_TIMESTAMP("hh:mm:ss", world.time)
	if(mapload)
		return "[when] на карте при загрузке ([get_area_name(thing)])"
	var/creator = ""
	var/callee/frame = caller
	for(var/depth in 1 to 10)
		if(!frame)
			break
		if(frame.src != thing && frame.src != SSatoms)
			var/datum/maker = isdatum(frame.src) ? frame.src : null
			creator = ", создал [frame.proc][maker ? " ([maker.type])" : ""]"
			break
		frame = frame.caller
	if(usr)
		creator += ", usr [key_name(usr)]"
	if(!thing.loc)
		return "[when] вне карты[creator]"
	var/where = "в [thing.loc.name]"
	var/mob/holder = get(thing.loc, /mob)
	if(holder)
		where = "у [key_name(holder)]"
	else if(isturf(thing.loc))
		where = "на полу"
	return "[when] [where] ([get_area_name(thing) || "вне зон"])[creator]"

/// Происхождение не длиннее ECON_CASH_ORIGIN_MAX символов.
/proc/econ_cash_origin_cap(origin)
	if(length_char(origin) <= ECON_CASH_ORIGIN_MAX)
		return origin
	var/tail = "[ECON_CASH_ORIGIN_SEP][ECON_CASH_ORIGIN_MORE]"
	return "[copytext_char(origin, 1, ECON_CASH_ORIGIN_MAX - length_char(tail) + 1)][tail]"

/// Часть происхождения - деньги, снятые со счёта: при слиянии они идут после остальных и первыми уходят при переполнении.
/proc/econ_cash_origin_withdrawn_part(part)
	return findtext(part, ECON_CASH_WITHDRAWN_MARK) == 1 || findtext(part, "[ECON_CASH_PASS_ON_MONEY][ECON_CASH_WITHDRAWN_MARK]")

/// Происхождение слитой пачки: части обеих строк без повторов, не со снятия со счёта первыми, длина ограничена.
/proc/econ_cash_origin_join(origin, added)
	if(!origin)
		return econ_cash_origin_cap(added)
	if(!added || origin == added)
		return origin
	var/list/parts = list()
	var/list/withdrawn = list()
	var/cut = FALSE
	for(var/part in splittext(origin, ECON_CASH_ORIGIN_SEP) + splittext(added, ECON_CASH_ORIGIN_SEP))
		if(part == ECON_CASH_ORIGIN_MORE)
			cut = TRUE
		else if(!(part in parts) && !(part in withdrawn))
			if(econ_cash_origin_withdrawn_part(part))
				withdrawn += part
			else
				parts += part
	parts += withdrawn
	var/room = ECON_CASH_ORIGIN_MAX - length_char("[ECON_CASH_ORIGIN_SEP][ECON_CASH_ORIGIN_MORE]")
	if(length_char(jointext(parts, ECON_CASH_ORIGIN_SEP)) > ECON_CASH_ORIGIN_MAX)
		cut = TRUE
		while(length(parts) > 1 && length_char(jointext(parts, ECON_CASH_ORIGIN_SEP)) > room)
			parts.Cut(length(parts))
	var/joined = jointext(parts, ECON_CASH_ORIGIN_SEP)
	return econ_cash_origin_cap(cut ? "[joined][ECON_CASH_ORIGIN_SEP][ECON_CASH_ORIGIN_MORE]" : joined)

#undef ECON_CASH_ORIGIN_SEP
#undef ECON_CASH_ORIGIN_MORE
#undef ECON_CASH_WITHDRAWN_MARK
#undef ECON_CASH_PASS_ON_MONEY

/// Учёт уже совершённого движения: журнал, истории счетов, сигнал и лог. log_tag - пометка только для лога; history_names - list(плательщик, получатель): имена с ID-карт для историй сторон вместо владельцев счетов, без номеров. Журнал, аудит и лог - по настоящим счетам.
/datum/controller/subsystem/economy/proc/record_move(datum/bank_account/source, datum/bank_account/target, amount, reason, mob/actor, memo, log_tag, list/history_names)
	ledger.record(source, target, amount, reason)
	var/label = memo || econ_reason_name(reason)
	var/source_shown = history_names ? history_names[1] : (source ? source.account_holder : "Nanotrasen")
	var/target_shown = history_names ? history_names[2] : (target ? target.account_holder : "Nanotrasen")
	source?.add_log_to_history(-amount, label, target_shown, reason, history_names ? null : target?.account_id)
	target?.add_log_to_history(amount, label, source_shown, reason, history_names ? null : source?.account_id)
	audit_move(source, target, amount, reason, actor)
	if(reason == ECON_PERSONAL_CATALOG && source)
		source.shop_used = TRUE
	SEND_SIGNAL(src, COMSIG_ECONOMY_MOVED, source, target, amount, reason, actor)
	log_econ("[num2text(amount, ECON_TEXT_DIGITS)] кр.: [econ_move_side(source, "эмиссия")] -> [econ_move_side(target, "сток")] ([reason][log_tag ? ", [log_tag]" : ""])[actor ? " by [key_name(actor)]" : ""]")

/datum/controller/subsystem/economy/proc/find_account(number)
	return accounts_by_number["[number]"]

/datum/controller/subsystem/economy/proc/total_money()
	. = 0
	for(var/number in accounts_by_number)
		var/datum/bank_account/account = accounts_by_number[number]
		. += account.account_balance

/datum/controller/subsystem/economy/proc/register_account(datum/bank_account/account)
	if(account.account_id && !accounts_by_number["[account.account_id]"])
		accounts_by_number["[account.account_id]"] = account
		return
	for(var/attempt in 1 to 1000)
		var/number = rand(111111, 999999)
		if(accounts_by_number["[number]"])
			continue
		account.account_id = number
		accounts_by_number["[number]"] = account
		return
	CRASH("SSeconomy: не нашлось свободного номера счёта")

/datum/controller/subsystem/economy/proc/unregister_account(datum/bank_account/account, number)
	if(isnull(number))
		number = account.account_id
	if(accounts_by_number["[number]"] == account)
		accounts_by_number -= "[number]"

/datum/bank_account/proc/credit(amount, reason, mob/actor, memo)
	return SSeconomy.move(null, src, amount, reason, actor, memo)

/datum/bank_account/proc/debit(amount, reason, mob/actor, memo)
	return SSeconomy.move(src, null, amount, reason, actor, memo)
