/datum/economy_department/civilian
	id = ACCOUNT_CIV
	name = "Гражданские"
	budget_name = "гражданский бюджет"
	head_access = list(ACCESS_HOP)

/datum/economy_department/civilian/spending_advice()
	return list("Из гражданского бюджета платятся оклады ассистентов, своего каталога у него нет: заказать нужное можно за личные деньги или заявкой снабжению.")
