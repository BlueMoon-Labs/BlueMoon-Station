GLOBAL_LIST_INIT(econ_reason_category, list(
	ECON_WAGE = ECON_CAT_WAGE,
	ECON_WAGE_FLOOR = ECON_CAT_WAGE,
	ECON_BONUS = ECON_CAT_WAGE,
	ECON_STARTING_FUNDS = ECON_CAT_GRANT,
	ECON_GRANT = ECON_CAT_GRANT,
	ECON_WORK = ECON_CAT_WORK,
	ECON_WORK_PREMIUM = ECON_CAT_WORK,
	ECON_CONTRACT = ECON_CAT_CONTRACT,
	ECON_EXPORT = ECON_CAT_TRADE,
	ECON_IMPORT = ECON_CAT_TRADE,
	ECON_HANDLING_FEE = ECON_CAT_TRADE,
	ECON_PRIVATE_ORDER = ECON_CAT_PURCHASE,
	ECON_VEND = ECON_CAT_PURCHASE,
	ECON_VEND_WHOLESALE = ECON_CAT_PURCHASE,
	ECON_PURCHASE = ECON_CAT_PURCHASE,
	ECON_REGISTER = ECON_CAT_PURCHASE,
	ECON_RENT = ECON_CAT_PURCHASE,
	ECON_GAMBLING = ECON_CAT_PURCHASE,
	ECON_GAMBLING_WIN = ECON_CAT_EVENT,
	ECON_LOTTERY = ECON_CAT_PURCHASE,
	ECON_LOTTERY_PRIZE = ECON_CAT_EVENT,
	ECON_LOTTERY_HOUSE = ECON_CAT_PURCHASE,
	ECON_AUCTION_BID = ECON_CAT_PURCHASE,
	ECON_AUCTION_REFUND = ECON_CAT_PURCHASE,
	ECON_AUCTION = ECON_CAT_PURCHASE,
	ECON_PERSONAL_CATALOG = ECON_CAT_PURCHASE,
	ECON_TIP = ECON_CAT_TIP,
	ECON_TAX = ECON_CAT_TAX,
	ECON_TAX_NT = ECON_CAT_TAX,
	ECON_BUDGET_RETURN = ECON_CAT_TAX,
	ECON_BUDGET_TRANSFER = ECON_CAT_TRANSFER,
	ECON_TRANSFER = ECON_CAT_TRANSFER,
	ECON_REFUND = ECON_CAT_TRANSFER,
	ECON_FINE = ECON_CAT_FINE,
	ECON_FINE_CUSTOMS = ECON_CAT_FINE,
	ECON_COURT_FEE = ECON_CAT_FINE,
	ECON_DEBT_PAYMENT = ECON_CAT_FINE,
	ECON_STOCK_BUY = ECON_CAT_STOCK,
	ECON_STOCK_SELL = ECON_CAT_STOCK,
	ECON_STOCK_FEE = ECON_CAT_STOCK,
	ECON_CASH_OUT = ECON_CAT_CASH,
	ECON_CASH_IN = ECON_CAT_CASH,
	ECON_BLACKMARKET = ECON_CAT_CRIME,
	ECON_SKIM = ECON_CAT_CRIME,
	ECON_ADMIN = ECON_CAT_ADMIN,
	ECON_EVENT = ECON_CAT_EVENT,
	ECON_EVENT_RANSOM = ECON_CAT_EVENT,
	ECON_ACCOUNT_CLOSED = ECON_CAT_ADMIN,
	ECON_MISC = ECON_CAT_MISC,
))

GLOBAL_LIST_INIT(econ_reason_names, list(
	ECON_WAGE = "Зарплата",
	ECON_WAGE_FLOOR = "Гарантированный минимум NT",
	ECON_BONUS = "Премия",
	ECON_STARTING_FUNDS = "Подъёмные",
	ECON_GRANT = "Грант NT",
	ECON_WORK = "Оплата работы",
	ECON_WORK_PREMIUM = "Премия за работу",
	ECON_CONTRACT = "Контракт NT",
	ECON_EXPORT = "Экспорт",
	ECON_IMPORT = "Импорт",
	ECON_HANDLING_FEE = "Сбор карго",
	ECON_PRIVATE_ORDER = "Частный заказ",
	ECON_VEND = "Покупка в автомате",
	ECON_VEND_WHOLESALE = "Себестоимость автомата",
	ECON_PURCHASE = "Покупка",
	ECON_REGISTER = "Оплата на кассе",
	ECON_RENT = "Аренда прилавка",
	ECON_GAMBLING = "Ставка",
	ECON_GAMBLING_WIN = "Выигрыш",
	ECON_LOTTERY = "Лотерейный билет",
	ECON_LOTTERY_PRIZE = "Выигрыш в лотерею",
	ECON_LOTTERY_HOUSE = "Доля NT с лотереи",
	ECON_AUCTION_BID = "Ставка на аукционе",
	ECON_AUCTION_REFUND = "Возврат ставки аукциона",
	ECON_AUCTION = "Лот аукциона",
	ECON_PERSONAL_CATALOG = "Личный каталог",
	ECON_TIP = "Чаевые",
	ECON_TAX = "Налог",
	ECON_TAX_NT = "Доля NT с налога",
	ECON_BUDGET_RETURN = "Возврат излишков бюджета NT",
	ECON_BUDGET_TRANSFER = "Перевод между бюджетами",
	ECON_TRANSFER = "Перевод",
	ECON_REFUND = "Возврат средств",
	ECON_FINE = "Штраф",
	ECON_FINE_CUSTOMS = "Таможенный штраф",
	ECON_COURT_FEE = "Судебная пошлина",
	ECON_DEBT_PAYMENT = "Погашение долга",
	ECON_STOCK_BUY = "Покупка акций",
	ECON_STOCK_SELL = "Продажа акций",
	ECON_STOCK_FEE = "Комиссия биржи",
	ECON_CASH_OUT = "Снятие наличных",
	ECON_CASH_IN = "Внесение наличных",
	ECON_BLACKMARKET = "Чёрный рынок",
	ECON_SKIM = "Перевод с неопознанного устройства",
	ECON_ADMIN = "Корректировка NT",
	ECON_EVENT = "Событие сектора",
	ECON_EVENT_RANSOM = "Выкуп",
	ECON_ACCOUNT_CLOSED = "Закрытие счёта",
	ECON_MISC = "Прочее",
))

/// Разовые поступления в бюджет, которые budget_cap_grace_ticks тиков не считаются излишком; отмена заказа возвращает потраченную им защиту отдельно
GLOBAL_LIST_INIT(econ_cap_shielded_reasons, list(ECON_BUDGET_TRANSFER, ECON_EVENT, ECON_CONTRACT))

GLOBAL_LIST_INIT(econ_taxable_categories, list(ECON_CAT_WAGE, ECON_CAT_WORK, ECON_CAT_CONTRACT))

/// Причины, по которым деньги уходят и с замороженного счёта.
GLOBAL_LIST_INIT(econ_reasons_ignore_freeze, list(ECON_REFUND, ECON_ADMIN, ECON_TAX, ECON_TAX_NT, ECON_ACCOUNT_CLOSED, ECON_DEBT_PAYMENT, ECON_BUDGET_RETURN))

/proc/econ_reason_name(reason)
	return GLOB.econ_reason_names[reason] || reason

/// «в 2 раза», «в 5 раз», «в 1.5 раза»
/proc/econ_times_text(multiplier)
	return "в [multiplier] [ru_plural(multiplier, "раз", "раза", "раз")]"

/// Грейды оклада от младшего к старшему и их названия для игрока.
GLOBAL_LIST_INIT(econ_pay_grade_names, list(
	PAY_GRADE_ASSISTANT = "ассистент",
	PAY_GRADE_MINIMAL = "минимальный",
	PAY_GRADE_EASY = "лёгкий",
	PAY_GRADE_MEDIUM = "средний",
	PAY_GRADE_HARD = "тяжёлый",
	PAY_GRADE_COMMAND = "командный",
))

/proc/econ_pay_grade(paycheck)
	switch(paycheck)
		if(PAYCHECK_COMMAND to INFINITY)
			return PAY_GRADE_COMMAND
		if(PAYCHECK_HARD to PAYCHECK_COMMAND)
			return PAY_GRADE_HARD
		if(PAYCHECK_MEDIUM to PAYCHECK_HARD)
			return PAY_GRADE_MEDIUM
		if(PAYCHECK_EASY to PAYCHECK_MEDIUM)
			return PAY_GRADE_EASY
		if(PAYCHECK_MINIMAL to PAYCHECK_EASY)
			return PAY_GRADE_MINIMAL
	return PAY_GRADE_ASSISTANT
