/// Числа баланса экономики. Секция "settings" из economy.json перекрывает дефолты.
/datum/economy_settings
	var/payroll_interval_ticks = 2
	var/list/wages = list(
		PAY_GRADE_ASSISTANT = 50,
		PAY_GRADE_MINIMAL = 100,
		PAY_GRADE_EASY = 150,
		PAY_GRADE_MEDIUM = 200,
		PAY_GRADE_HARD = 250,
		PAY_GRADE_COMMAND = 300,
	)
	var/wage_floor = 30
	var/owed_wages_cap_paychecks = 6
	var/starting_paychecks = 3
	var/department_start_budget = 5000
	var/treasury_start_budget = 20000
	/// Базовая часть гранта: только отделам, которым есть что заказать в каталоге
	var/grant_base = 150
	/// Грант за тик в процентах окладов сотрудников на смене (без надбавок) за то же время
	var/grant_payroll_share = 100
	var/tax_default = 10
	var/tax_max = 30
	/// Какая доля налога уходит NT (сгорает), проценты; остальное - в казну
	var/tax_nt_share = 75
	/// Порог бюджета отдела в окладах сотрудников на смене за выплату, но не ниже стартового бюджета; с излишка сверх порога, долгов и следующей зарплаты NT забирает budget_cap_return_share процентов за тик
	var/budget_cap_paydays = 5
	var/budget_cap_return_share = 80
	/// Цель калибровки для панели: какую долю оставшихся у отделов денег они сжигают, проценты
	var/department_sink_target_min = 60
	var/department_sink_target_max = 80
	/// Сколько тиков разовые поступления (переводы из казны, события, доля контрактов) не считаются излишком
	var/budget_cap_grace_ticks = 3
	/// Сколько минут цена выбранного главой пака не считается излишком
	var/saving_goal_minutes = 30
	/// Через сколько минут после истечения или снятия цели без заказа можно поставить новую
	var/saving_goal_cooldown_minutes = 30
	var/max_wage_bonus = 50
	var/dormant_after_minutes = 10
	var/state_rich_per_capita = 7500
	var/state_poor_per_capita = 1250
	var/vend_wholesale_share = 50
	/// Сколько процентов цены премиум-позиции автомата сгорает, остальное - отделу-владельцу
	var/vend_premium_sink_share = 90
	/// Слот-машина: процент каждой платной ставки, который сгорает, и процент, который копится в джекпот; остальное - в банк выигрышей автомата
	var/slot_house_edge = 10
	/// Наибольший взнос в слот-машину с ID-карты за раз
	var/slot_card_deposit_max = 1000
	var/slot_jackpot_share = 5
	/// Джекпот автоматов сектора не меньше этого: недостающее доплачивает NT
	var/slot_jackpot_floor = 500
	/// Лотерея: цена билета, сколько билетов в одни руки, сколько минут идёт продажа, доля NT с продаж в процентах
	var/lottery_ticket_price = 100
	var/lottery_tickets_per_account = 10
	var/lottery_sale_minutes = 20
	var/lottery_house_share = 30
	/// Доля кассира в оплате на кассе по умолчанию, проценты
	var/register_cashier_share_default = 50
	var/cargo_handling_fee = 12
	var/auto_approve_limit = 2000
	/// Через сколько минут без ответа заявка до auto_approve_limit одобряется сама, даже если одобрить есть кому; 0 - не одобрять
	var/auto_approve_wait_minutes = 10
	/// Перерыв между автоодобренными заявками одного сотрудника
	var/auto_approve_cooldown_minutes = 10
	/// Сколько заявок одного сотрудника может ждать решения одновременно
	var/request_pending_per_requester = 3
	/// Сколько запросов в казну одного отдела может ждать решения одновременно
	var/treasury_requests_pending_per_department = 2
	/// Наибольшая сумма одного запроса в казну
	var/treasury_request_max = 5000
	/// Сколько счетов без владельца в экипаже казна может держать открытыми
	var/treasury_unowned_accounts_max = 30
	var/work_personal_share = 10
	var/work_personal_cap_hour = 1500
	var/work_subject_cooldown_minutes = 10
	var/power_export_max_kw = 2000
	var/power_export_step_kw = 50
	var/power_export_credits_per_mj = 3
	/// Суммарная оплачиваемая мощность всех узлов экспорта за цикл
	var/power_export_station_cap_kw = 3000
	/// Потолок множителя сложности блюда (видов ингредиентов рецепта)
	var/dish_complexity_max = 5
	var/dish_of_the_day_mult = 2
	/// Оплачиваемых уборок одного уборщика за тик экономики
	var/cleaning_cap_per_tick = 30
	/// Сколько NT платит СБ за ТК стоимости изъятой контрабанды
	var/contraband_value_per_tc = 150
	/// Цена изъятия контрабанды без цены в аплинке
	var/contraband_value_default = 300
	/// Сколько NT платит СБ за изъятия за час, сверх - улики ждут следующего часа
	var/contraband_cap_hour = 6000
	/// Наибольшая судебная пошлина, которую назначает магистрат
	var/court_fee_max = 3000
	/// Шанс таможенного досмотра отгружаемого ящика, проценты; надбавки - во время инспекции Sol и при красном коде и выше
	var/customs_chance = 15
	var/customs_chance_inspection = 20
	var/customs_chance_alert = 10
	/// Штраф снабжению за изъятую таможней контрабанду, проценты её оценки
	var/customs_fine_share = 50
	/// Цена одного очка техвеба в гранте на исследования
	/// Цена очка гранта: потолок за час стоит как средний пак каталога, а очко дороже оплаты узла за него (5 кр. на 1000 очков), чтобы грант не окупался
	var/research_grant_price_per_point = 0.2
	/// Сколько очков гранта наука покупает за час
	var/research_grant_cap_hour = 10000
	/// Контрактов NT на доске каждого отдела
	var/contracts_per_department = 3
	/// Невзятые контракты сменяются раз в столько тиков экономики
	var/contract_rotation_ticks = 4
	var/contract_urgent_chance = 20
	var/contract_urgent_minutes = 15
	/// Множитель награды срочного контракта
	var/contract_urgent_mult = 1.5
	/// Процент награды контракта, который получает взявший его
	var/contract_performer_share = 30
	/// Контракт деятельности платит такую долю цены своих работ по прайсу (сверх оплаты самих работ); срочный - ещё в contract_urgent_mult раз
	var/contract_work_mult = 0.5
	/// Спред биржи в процентах: покупка дороже цены, продажа дешевле
	var/stock_spread = 1
	/// Комиссия биржи в процентах от суммы сделки, уходит в сток
	var/stock_fee = 2
	/// Наибольшая стоимость позиции по одной компании на личном счёте
	var/stock_position_cap = 10000
	/// Во сколько раз лимит позиции казны выше личного
	var/stock_treasury_cap_mult = 5
	var/stock_trade_cooldown_seconds = 30
	/// Наибольшая сумма одного личного перевода или чаевых
	var/transfer_max = 50000
	/// Перерыв между личными переводами и чаевыми с одного счёта
	var/transfer_cooldown_seconds = 5
	var/stall_rent_fee = 500
	var/stall_rent_minutes = 60
	/// Сколько скиммеры снимают с одного счёта за минуту, вместе
	var/skim_rate = 300
	var/skimmer_slots = 3
	/// Сколько премий и переводов из бюджета одному человеку за audit_siphon_minutes помечается аудитом
	var/audit_bonus_threshold = 1000
	var/audit_siphon_minutes = 30
	/// Столько личных переводов одному получателю за audit_structuring_minutes - дробление
	var/audit_structuring_count = 5
	var/audit_structuring_minutes = 5
	/// Окно и глубина следа денег
	var/audit_trace_minutes = 30
	var/audit_trace_depth = 3
	/// Доля возврата по делу аудита, которая уходит отделу безопасности сбором с получателя
	var/audit_case_fee_percent = 10
	/// Чистые сделки счёта в сторону события компании на столько кредитов - инсайд: у настоящих событий после постановки в очередь, у фальшивок за audit_insider_window_minutes до выхода
	var/audit_insider_threshold = 2000
	var/audit_insider_window_minutes = 5
	/// Через столько минут NT опровергает фальшивый пресс-релиз и возвращает цену
	var/press_release_refute_minutes = 5
	/// Не чаще одного фальшивого пресс-релиза в секторе за столько минут
	var/press_release_cooldown_minutes = 60
	/// Шанс, что задание предателя без убийства будет экономическим, проценты
	var/traitor_econ_objective_chance = 20
	/// Грант NT бедной станции доводит деньги до порога бедности, но не меньше min и не больше max
	var/event_grant_min = 2000
	var/event_grant_max = 15000
	/// Выкуп пиратам: не меньше min и такая доля казны, проценты
	var/event_ransom_min = 25000
	var/event_ransom_share = 80
	var/event_embargo_minutes = 20
	/// Обвал рынка опускает тренды всех товаров на столько процентов
	var/event_crash_trend_drop = 20
	var/event_boom_goods = 2
	var/event_shortage_mult = 2
	/// Сколько сдвигов рынка цена товара держится на уровне дефицита
	var/event_shortage_shifts = 3
	/// WORK_* -> цена единицы работы для бюджета отдела
	var/list/work_prices = list(
		WORK_MED_DISCHARGE_LIGHT = 60,
		WORK_MED_DISCHARGE_HEAVY = 150,
		WORK_MED_DISCHARGE_CRIT = 300,
		WORK_MED_REVIVE = 400,
		WORK_MED_SURGERY = 200,
		WORK_ENG_POWER_EXPORT = 1,
		WORK_ENG_INTEGRITY = 2,
		WORK_SCI_NODE = 5,
		WORK_SCI_SLIME_DISCOVERY = 10,
		WORK_SCI_ARTIFACT = 1,
		WORK_MINING_ORE = 2,
		WORK_SRV_DISH = 40,
		WORK_SRV_DRINK = 30,
		WORK_SRV_NEW_PLANT = 150,
		WORK_SRV_CLEANING = 6,
		WORK_SEC_CONTRABAND = 1,
	)
	/// Весь распарсенный JSON: секции рынка читает SSmarket.
	var/list/raw

/datum/economy_settings/proc/load(path = ECONOMY_CONFIG_PATH)
	. = list()
	if(!fexists(path))
		. += "нет файла [path]"
		return
	var/list/data
	try
		data = json_decode(file2text(path))
	catch(var/exception/error)
		. += "[path]: [error]"
		return
	if(!islist(data))
		. += "[path]: корень не объект"
		return
	raw = data
	var/list/section = data["settings"]
	if(!islist(section))
		return
	var/static/list/datum_vars
	if(!datum_vars)
		datum_vars = list()
		var/datum/bare = new
		for(var/var_name in bare.vars)
			datum_vars += var_name
		qdel(bare)
	for(var/key in section)
		if(ECON_CONFIG_COMMENT_KEY(key))
			continue
		if(!(key in vars) || (key in datum_vars) || key == "raw")
			. += "неизвестный ключ settings.[key]"
			continue
		var/value = section[key]
		var/current = vars[key]
		if(islist(current) != islist(value) || (isnum(current) && !isnum(value)))
			. += "неверный тип settings.[key]"
			continue
		if(key == "work_prices")
			. += merge_work_prices(value)
			continue
		var/problem = check_value(key, value)
		if(problem)
			. += "settings.[key]: [problem]"
			continue
		vars[key] = value
	if(skim_rate > transfer_max)
		. += "settings.skim_rate: больше transfer_max ([transfer_max])"
		skim_rate = min(initial(skim_rate), transfer_max)
	if(slot_house_edge + slot_jackpot_share > 100)
		. += "settings.slot_jackpot_share: вместе с slot_house_edge больше 100%"
		slot_jackpot_share = 100 - slot_house_edge
	if(event_grant_min > event_grant_max)
		. += "settings.event_grant_min: больше event_grant_max ([event_grant_max])"
		event_grant_min = event_grant_max

/// Цены из JSON накладываются на дефолты по ключам, неуказанные работы сохраняют цену.
/datum/economy_settings/proc/merge_work_prices(list/value)
	. = list()
	var/list/merged = work_prices.Copy()
	for(var/work_type in value)
		if(!istext(work_type) || !(work_type in merged))
			. += "неизвестная работа settings.work_prices.[work_type]"
			continue
		var/price = value[work_type]
		if(!isnum(price) || price < 0)
			. += "settings.work_prices.[work_type]: нужно число не меньше 0"
			continue
		merged[work_type] = price
	work_prices = merged

/datum/economy_settings/proc/check_value(key, value)
	var/static/list/at_least_one = list("payroll_interval_ticks", "dormant_after_minutes", "work_subject_cooldown_minutes", "request_pending_per_requester", "treasury_requests_pending_per_department", "treasury_request_max", "power_export_step_kw", "dish_complexity_max", "dish_of_the_day_mult", "contracts_per_department", "contract_rotation_ticks", "contract_urgent_minutes", "contract_urgent_mult", "stock_position_cap", "stock_treasury_cap_mult", "transfer_max", "stall_rent_minutes", "skim_rate", "skimmer_slots", "audit_bonus_threshold", "audit_siphon_minutes", "audit_structuring_count", "audit_structuring_minutes", "audit_trace_minutes", "audit_trace_depth", "audit_insider_threshold", "audit_insider_window_minutes", "press_release_refute_minutes", "press_release_cooldown_minutes", "event_grant_min", "event_grant_max", "event_ransom_min", "event_embargo_minutes", "event_boom_goods", "event_shortage_mult", "event_shortage_shifts", "budget_cap_paydays", "saving_goal_minutes", "saving_goal_cooldown_minutes", "slot_card_deposit_max", "lottery_ticket_price", "lottery_tickets_per_account", "lottery_sale_minutes")
	var/static/list/percents = list("tax_default", "tax_max", "tax_nt_share", "department_sink_target_min", "department_sink_target_max", "budget_cap_return_share", "max_wage_bonus", "work_personal_share", "vend_wholesale_share", "vend_premium_sink_share", "slot_house_edge", "slot_jackpot_share", "lottery_house_share", "register_cashier_share_default", "cargo_handling_fee", "contract_urgent_chance", "contract_performer_share", "stock_spread", "stock_fee", "audit_case_fee_percent", "customs_chance", "customs_chance_inspection", "customs_chance_alert", "customs_fine_share", "traitor_econ_objective_chance", "event_ransom_share", "event_crash_trend_drop")
	if(key == "wages")
		for(var/grade in list(PAY_GRADE_ASSISTANT, PAY_GRADE_MINIMAL, PAY_GRADE_EASY, PAY_GRADE_MEDIUM, PAY_GRADE_HARD, PAY_GRADE_COMMAND))
			if(!isnum(value[grade]) || value[grade] < 0)
				return "грейд [grade] - нужно число не меньше 0"
		return
	if(!isnum(value))
		return
	if((key in at_least_one) && value < 1)
		return "меньше 1"
	if((key in percents) && (value < 0 || value > 100))
		return "вне 0..100"
	if(key == "research_grant_price_per_point" && value <= 0)
		return "нужно число больше 0"
	if(value < 0)
		return "меньше 0"
