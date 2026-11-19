/datum/economy_department
	var/id
	var/name
	/// Как бюджет называется в тексте, со строчной: "бюджет снабжения"
	var/budget_name
	/// Доступ ID, дающий права главы
	var/list/head_access = list()
	var/datum/bank_account/department/account
	/// Активные контракты (D8)
	var/list/contracts = list()
	/// Заявки на закупку (D9)
	var/list/requests = list()
	/// Долг перед NT (штрафы)
	var/owed = 0
	/// Последние WORK_LOG_MAX оплаченных работ: time, type, amount, performer
	var/list/work_log = list()
	/// Доля кассира в оплате на кассе, проценты; остальное - в бюджет отдела
	var/register_cashier_share
	/// Разовые поступления под защитой от возврата: list(сумма, номер тика, когда защита кончится)
	var/list/shield = list()
	/// Пак, на который копит глава, и до какого world.time его цена не считается излишком; 0 - бюджет ещё не набрал цену, срок не идёт
	var/datum/supply_pack/saving_goal
	/// Номер отряда в GLOB.payed_ert, на который копит снабжение вместо пака; 0 - нет
	var/saving_goal_ert = 0
	var/saving_goal_until = 0
	/// Когда глава поставил цель: не набранная за saving_goal_collect_minutes снимается
	var/saving_goal_set_at = 0
	/// До этого world.time новую цель не поставить
	var/saving_goal_cooldown_until = 0
	var/saving_goal_cache
	var/saving_goal_cache_tick = -1
	COOLDOWN_DECLARE(return_notice_cooldown)

/datum/economy_department/New()
	register_cashier_share = SSeconomy.settings.register_cashier_share_default
	account = new /datum/bank_account/department(id, start_budget())
	account.department = src

/datum/economy_department/Destroy()
	if(account?.department == src)
		account.department = null
	account = null
	return ..()

/// Русское имя счёта для текстов: бюджет отдела, бюджет внестанционной фракции или имя владельца личного счёта.
/proc/econ_budget_name(datum/bank_account/account)
	var/static/list/offstation = list(ACCOUNT_TAR = "бюджет Тарков Индастриз", ACCOUNT_DS = "бюджет Deep Space")
	var/datum/bank_account/department/budget = account
	if(!istype(budget))
		return account?.account_holder
	return budget.department?.budget_name || offstation[budget.department_id] || budget.account_holder

/datum/economy_department/proc/start_budget()
	return SSeconomy.settings.department_start_budget

/// Сотрудники всех отделов за один проход по счетам: id отдела -> on_shift, owed_wages (без внестанционных), payroll, owed_to_staff. Процы отдела берут её аргументом stats, без него собирают только для себя через only_department.
/proc/econ_staff_stats(only_department)
	. = list()
	var/list/wages = SSeconomy.settings.wages
	for(var/datum/bank_account/member as anything in SSeconomy.bank_accounts)
		var/department_id = member.department_id
		if(!department_id || (only_department && department_id != only_department))
			continue
		var/list/stats = .[department_id]
		if(!stats)
			stats = list("on_shift" = 0, "owed_wages" = 0, "payroll" = 0, "owed_to_staff" = 0)
			.[department_id] = stats
		if(member.state == ACCOUNT_ACTIVE)
			stats["on_shift"]++
		if(!member.offstation)
			stats["owed_wages"] += member.owed_wages
		stats["owed_to_staff"] += member.owed_wages
		if(member.state == ACCOUNT_DORMANT)
			continue
		stats["owed_to_staff"] += member.wage_amount()
		if(member.pay_grade)
			stats["payroll"] += wages[member.pay_grade] || 0

/datum/economy_department/proc/staff_stat(list/stats, key)
	var/list/all_stats = stats || econ_staff_stats(id)
	var/list/mine = all_stats[id]
	return mine ? mine[key] : 0

/datum/economy_department/proc/staff_on_shift(list/stats)
	return staff_stat(stats, "on_shift")

/// Оклады сотрудников на смене за одну выплату, без надбавок глав.
/datum/economy_department/proc/base_payroll(list/stats)
	return staff_stat(stats, "payroll")

/// Наибольший грант за тик; catalog_packs - уже собранный каталог отдела, чтобы не собирать его заново.
/datum/economy_department/proc/grant_amount(list/catalog_packs, list/stats)
	var/datum/economy_settings/settings = SSeconomy.settings
	. = round(base_payroll(stats) * settings.grant_payroll_share / 100 / settings.payroll_interval_ticks)
	if(length(isnull(catalog_packs) ? catalog() : catalog_packs))
		. += settings.grant_base

/// До этой суммы NT доливает бюджет грантом: порог, долги и следующая зарплата сотрудникам и цель накопления. Выше неё грант ушёл бы возвратом излишка.
/datum/economy_department/proc/grant_level(list/stats)
	if(!stats)
		stats = econ_staff_stats(id)
	return budget_threshold(stats) + owed_to_staff(stats) + saving_goal_amount()

/// Грант на ближайшем тике: недостающее до grant_level, не больше grant_amount.
/datum/economy_department/proc/grant_due(list/catalog_packs, list/stats)
	if(!stats)
		stats = econ_staff_stats(id)
	return clamp(grant_level(stats) - account.account_balance, 0, grant_amount(catalog_packs, stats))

/// Ниже этого порог бюджета не опускается, сколько бы сотрудников ни было на смене.
/datum/economy_department/proc/budget_floor()
	return max(start_budget(), SSeconomy.settings.budget_cap_floor)

/// Выше этой суммы бюджет каждый тик возвращает NT долю излишка.
/datum/economy_department/proc/budget_threshold(list/stats)
	return max(base_payroll(stats) * SSeconomy.settings.budget_cap_paydays, budget_floor())

/// Долг отдела перед своими сотрудниками и их следующая зарплата: их излишек не съедает.
/datum/economy_department/proc/owed_to_staff(list/stats)
	return staff_stat(stats, "owed_to_staff")

/// Красный код и выше: NT не забирает излишек бюджетов, чтобы отделам было на что восстанавливать станцию.
/proc/econ_emergency_active()
	return GLOB.security_level >= SEC_LEVEL_RED

/// Сколько вернётся NT на ближайшем тике: доля излишка над порогом; долги и следующая зарплата сотрудникам, долг NT, разовые поступления и цель накопления не трогаются. При ЧС - ничего.
/datum/economy_department/proc/budget_return_due(list/stats)
	if(!stats)
		stats = econ_staff_stats(id)
	var/goal = saving_goal_amount()
	if(econ_emergency_active())
		return 0
	var/excess = account.account_balance - budget_threshold(stats) - owed_to_staff(stats) - owed - shielded() - goal
	if(excess <= 0)
		return 0
	return round(excess * SSeconomy.settings.budget_cap_return_share / 100)

/datum/economy_department/proc/return_excess(list/stats)
	if(!stats)
		stats = econ_staff_stats(id)
	var/amount = budget_return_due(stats)
	if(amount <= 0 || !account.debit(amount, ECON_BUDGET_RETURN, memo = "Возврат излишка сверх [budget_threshold(stats)] кр."))
		return
	if(COOLDOWN_FINISHED(src, return_notice_cooldown))
		COOLDOWN_START(src, return_notice_cooldown, ECON_BUDGET_RETURN_NOTICE_COOLDOWN)
		account.bank_card_talk("[capitalize(budget_name)] выше порога [budget_threshold(stats)] кр.: NT забрал [amount] кр. излишка. Потратьте его на закупки или назначьте цель накопления[saving_goal_scope()] в \"Бюджете отдела\".")

/// Отменённая закупка не считается ни закупкой, ни стоком отдела.
/datum/economy_department/proc/ledger_cancel_purchase(amount)
	var/datum/economy_ledger/ledger = SSeconomy.ledger
	var/list/flow = ledger.department_flow(id)
	flow["purchases"] = max(flow["purchases"] - 1, 0)
	flow["purchase_amount"] -= amount

/// Разовое поступление не считается излишком budget_cap_grace_ticks тиков.
/datum/economy_department/proc/add_shield(amount)
	shield += list(list(amount, SSeconomy.fire_count + SSeconomy.settings.budget_cap_grace_ticks))

/// Живая защита, не больше баланса.
/datum/economy_department/proc/shielded()
	. = 0
	for(var/list/entry as anything in shield.Copy())
		if(entry[2] <= SSeconomy.fire_count)
			shield -= list(entry)
			continue
		. += entry[1]
	. = clamp(., 0, max(account.account_balance, 0))

/// Расход из бюджета тратит живую защиту первым; возвращает потраченные части записей с их сроками.
/datum/economy_department/proc/consume_shield(amount)
	. = list()
	shielded()
	for(var/list/entry as anything in shield.Copy())
		if(amount <= 0)
			return
		var/used = min(entry[1], amount)
		entry[1] -= used
		amount -= used
		. += list(list(used, entry[2]))
		if(entry[1] <= 0)
			shield -= list(entry)

/// Возвращает защиту, потраченную отменённым заказом, с прежними сроками.
/datum/economy_department/proc/restore_shield(list/entries)
	for(var/list/entry as anything in entries)
		if(entry[2] > SSeconomy.fire_count)
			shield += list(entry.Copy())

/// Минуты, на которые ещё действует защита разовых поступлений, и её сумма.
/datum/economy_department/proc/shield_minutes()
	var/last = 0
	for(var/list/entry as anything in shield)
		last = max(last, entry[2])
	return max(last - SSeconomy.fire_count, 0) * round(SSeconomy.wait / (1 MINUTES), 1)

/// Сумма цели накопления; цена пересчитывается раз в тик экономики. Пока бюджет не набрал цену, срок на заказ не идёт, но набрать её надо за saving_goal_collect_minutes; набрал - saving_goal_minutes на заказ. Истёкшая цель снимается с перерывом.
/datum/economy_department/proc/saving_goal_amount()
	if(!saving_goal && !saving_goal_ert)
		return 0
	if(saving_goal_until && world.time >= saving_goal_until)
		lapse_saving_goal(saving_goal_until)
		return 0
	if(!saving_goal_valid())
		clear_saving_goal(ordered = TRUE)
		return 0
	if(saving_goal_cache_tick != SSeconomy.fire_count || isnull(saving_goal_cache))
		saving_goal_cache = saving_goal_price()
		saving_goal_cache_tick = SSeconomy.fire_count
	if(saving_goal_until)
		return saving_goal_cache
	if(world.time >= saving_goal_collect_deadline())
		lapse_uncollected_goal()
		return 0
	if(account.account_balance >= saving_goal_cache)
		var/minutes = SSeconomy.settings.saving_goal_minutes
		saving_goal_until = world.time + minutes MINUTES
		account.bank_card_talk("[capitalize(budget_name)] набрал цель накопления \"[saving_goal_name()]\": [saving_goal_order_hint(minutes)], потом её цена снова станет излишком.")
		saving_goal_reached(minutes)
	return saving_goal_cache

/// До этого world.time бюджет должен набрать цену цели.
/datum/economy_department/proc/saving_goal_collect_deadline()
	return saving_goal_set_at + SSeconomy.settings.saving_goal_collect_minutes MINUTES

/// Бюджет не набрал цену цели вовремя: цель снимается как истёкшая, с перерывом.
/datum/economy_department/proc/lapse_uncollected_goal()
	var/collect_minutes = SSeconomy.settings.saving_goal_collect_minutes
	var/goal_name = saving_goal_name()
	log_econ("Цель накопления [name] \"[goal_name]\" не набрана за [collect_minutes] мин. и снята")
	lapse_saving_goal(saving_goal_collect_deadline())
	account.bank_card_talk("[capitalize(budget_name)] не набрал цель накопления \"[goal_name]\" за [collect_minutes] мин.: цель снята, новую можно поставить через [saving_goal_cooldown_minutes()] мин.")

/// Как распорядиться набранной целью за minutes минут: для сообщений карты и окна бюджета.
/datum/economy_department/proc/saving_goal_order_hint(minutes)
	return "закажите её за [minutes] мин."

/// Бюджет только что набрал цену цели.
/datum/economy_department/proc/saving_goal_reached(minutes)
	return

/// Цена пака-цели, но не выше самого дорогого пака каталога в наличии.
/datum/economy_department/proc/saving_goal_price()
	var/top = 0
	var/list/packs = catalog()
	var/list/offers = SSmarket.best_offers(packs)
	for(var/datum/supply_pack/pack as anything in packs)
		var/list/offer = offers[pack]
		if(offer)
			top = max(top, offer[2])
		else if(!econ_pack_traded(pack))
			top = max(top, pack.market_cost())
	return min(round(econ_pack_price(saving_goal)), top)

/// На что копить можно: пак каталога отдела.
/datum/economy_department/proc/can_save_for(datum/supply_pack/pack)
	return pack && (pack in catalog())

/// Цель всё ещё есть что купить; иначе снимается без перерыва.
/datum/economy_department/proc/saving_goal_valid()
	return TRUE

/// Уточнение для подсказок, на что ещё отдел может копить.
/datum/economy_department/proc/saving_goal_scope()
	return ""

/datum/economy_department/proc/saving_goal_name()
	if(saving_goal_ert)
		var/list/ert = econ_payed_ert(saving_goal_ert)
		return ert?["name"]
	return saving_goal?.name

/// Цель снята без заказа: новую можно поставить через saving_goal_cooldown_minutes.
/datum/economy_department/proc/lapse_saving_goal(since = world.time)
	saving_goal = null
	saving_goal_ert = 0
	saving_goal_until = 0
	saving_goal_cache = null
	saving_goal_cooldown_until = max(saving_goal_cooldown_until, since + SSeconomy.settings.saving_goal_cooldown_minutes MINUTES)

/datum/economy_department/proc/saving_goal_cooldown_minutes()
	return max(CEILING((saving_goal_cooldown_until - world.time) / (1 MINUTES), 1), 0)

/// Новую цель можно ставить: глава, нет перерыва и не стоит неистёкшая цель.
/datum/economy_department/proc/can_start_saving_goal(mob/living/user)
	return can_manage(user) && world.time >= saving_goal_cooldown_until && !((saving_goal || saving_goal_ert) && (!saving_goal_until || world.time < saving_goal_until))

/datum/economy_department/proc/set_saving_goal(datum/supply_pack/pack, mob/living/user)
	if(!can_start_saving_goal(user) || !can_save_for(pack))
		return FALSE
	saving_goal = pack
	saving_goal_ert = 0
	saving_goal_until = 0
	saving_goal_set_at = world.time
	saving_goal_cache = null
	log_econ("[key_name(user)] назначил цель накопления [name]: [pack.name]")
	return TRUE

/// Снятие главой - с перерывом, как истечение; ordered - пак заказан, перерыва нет.
/datum/economy_department/proc/clear_saving_goal(mob/living/user, ordered = FALSE)
	if(user && !can_manage(user))
		return FALSE
	if(!saving_goal && !saving_goal_ert)
		return TRUE
	if(ordered)
		saving_goal = null
		saving_goal_ert = 0
		saving_goal_until = 0
		saving_goal_cache = null
	else
		lapse_saving_goal()
	return TRUE

/// Пак куплен за бюджет мимо заказа отдела (отгрузка снабжения, экспресс-консоль): цель на него снимается без перерыва.
/datum/economy_department/proc/goal_bought(datum/supply_pack/pack)
	if(pack && pack == saving_goal)
		clear_saving_goal(ordered = TRUE)

/proc/econ_budget_goal_bought(datum/bank_account/department/account, datum/supply_pack/pack)
	if(istype(account))
		account.department?.goal_bought(pack)

/// Снят заказ, закрывший цель: цель возвращается с прежним сроком; поставленная на её место живёт не дольше него.
/datum/economy_department/proc/restore_saving_goal(datum/supply_pack/pack, until, ert_id = 0)
	if(saving_goal || saving_goal_ert)
		if(!saving_goal_until || until < saving_goal_until)
			saving_goal_until = until
	else
		saving_goal = pack
		saving_goal_ert = ert_id
		saving_goal_until = until
	saving_goal_cache = null
	if(world.time >= saving_goal_until)
		lapse_saving_goal(saving_goal_until)

/datum/economy_department/proc/grant(list/stats)
	var/amount = grant_due(null, stats)
	if(amount > 0)
		account.credit(amount, ECON_GRANT)

/datum/economy_department/proc/on_economy_tick()
	return

/// Имя для журналов и заявок отдела: по ID-карте, как на кассе и в снабжении, а не настоящее имя под маской.
/proc/econ_public_name(mob/user)
	if(ishuman(user))
		var/mob/living/carbon/human/human_user = user
		return human_user.get_authentification_name("Неизвестный")
	return user ? user.name : ""

/datum/economy_department/proc/note_work(work_type, amount, mob/performer)
	work_log += list(list(
		"time" = STATION_TIME_TIMESTAMP("hh:mm:ss", world.time),
		"type" = econ_work_name(work_type),
		"amount" = amount,
		"performer" = econ_public_name(performer),
	))
	if(length(work_log) > WORK_LOG_MAX)
		work_log.Cut(1, length(work_log) - WORK_LOG_MAX + 1)

/datum/economy_department/proc/set_register_share(percent, mob/living/user)
	if(!can_manage(user) || !isnum(percent))
		return FALSE
	register_cashier_share = clamp(round(percent), 0, 100)
	log_econ("[key_name(user)] выставил долю кассира [register_cashier_share]% для касс отдела [name]")
	return TRUE

/datum/economy_department/proc/add_owed(amount)
	owed += max(round(amount), 0)

/datum/economy_department/proc/settle_owed()
	if(owed <= 0)
		return
	var/payment = min(owed, max(account.account_balance, 0))
	if(payment && account.debit(payment, ECON_DEBT_PAYMENT))
		owed -= payment
