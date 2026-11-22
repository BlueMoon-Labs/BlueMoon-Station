/datum/economy_department/security
	id = ACCOUNT_SEC
	name = "Служба безопасности"
	budget_name = "бюджет службы безопасности"
	head_access = list(ACCESS_HOS)

/datum/economy_department/security/spending_advice()
	return list(
		"Броня, шлемы и наручники расходуются в каждой стычке: восполняйте их до тревоги, а не во время.",
		"Хранилище улик передаёт изъятую контрабанду NT, и за неё платят отделу.",
		"На оружейный ящик дороже бюджета ставьте цель накопления: NT дольёт её излишками других отделов. Недостающее можно попросить и из казны.",
	)

/datum/economy_department/security/situational_needs()
	. = list()
	if(GLOB.security_level >= SEC_LEVEL_RED)
		.[/datum/supply_pack/security/armor] = "Красный код: броня на всех"
		.[/datum/supply_pack/security/helmets] = "Красный код: шлемы на всех"

/datum/economy_department/security/everyday_needs()
	return list(
		/datum/supply_pack/security/supplies = "Наручники и вспышки на смену",
		/datum/supply_pack/security/armor = "Запасная броня",
		/datum/supply_pack/department/security_evidence = "Хранилище улик: за изъятую контрабанду платят отделу",
	)
