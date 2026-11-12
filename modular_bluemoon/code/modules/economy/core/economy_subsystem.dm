SUBSYSTEM_DEF(economy)
	name = "Economy"
	wait = 5 MINUTES
	init_order = INIT_ORDER_ECONOMY
	runlevels = RUNLEVEL_GAME
	var/datum/economy_settings/settings = new
	var/datum/economy_ledger/ledger = new
	/// "номер" -> любой счёт, включая бюджеты и системные
	var/list/accounts_by_number = list()
	/// Личные счета
	var/list/bank_accounts = list()
	/// Бюджеты (/datum/bank_account/department), включая TAR и DS
	var/list/generated_accounts = list()
	/// id -> /datum/economy_department
	var/list/departments = list()
	var/list/dep_cards = list()
	var/datum/bank_account/system/cash_account
	var/datum/bank_account/system/market_account
	/// Депозиты объявлений экипажа до расчёта
	var/datum/bank_account/system/escrow_account
	var/tax_rate = 0
	var/fire_count = 0
	var/economy_state = ECON_STATE_NORMAL
	/// Множитель цен события обвала рынка поверх индекса цен
	var/price_surge_mult = 1
	var/bounty_modifier = 1
	var/pack_price_modifier = 1
	/// Админский режим платных машин (sleeper, cryo, cloning)
	var/full_ancap = FALSE
	/// Доска контрактов выставлена (на старте раунда)
	var/contracts_started = FALSE

/datum/controller/subsystem/economy/Initialize(timeofday)
	GLOB.economy_config_errors = settings.load()
	for(var/error in GLOB.economy_config_errors)
		log_config("economy.json: [error]")
	tax_rate = min(settings.tax_default, settings.tax_max)
	cash_account = new("Наличные в обороте")
	market_account = new("Биржа сектора")
	escrow_account = new("Депозит объявлений")
	for(var/department_type in subtypesof(/datum/economy_department))
		var/datum/economy_department/department = new department_type
		departments[department.id] = department
	new /datum/bank_account/department(ACCOUNT_TAR, 0)
	new /datum/bank_account/department(ACCOUNT_DS, 0)
	SSticker.OnRoundstart(CALLBACK(src, PROC_REF(start_contracts)))
	SSticker.OnRoundend(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(econ_log_round_summary)))
	return ..()

/datum/controller/subsystem/economy/Recover()
	settings = SSeconomy.settings
	ledger = SSeconomy.ledger
	accounts_by_number = SSeconomy.accounts_by_number
	bank_accounts = SSeconomy.bank_accounts
	generated_accounts = SSeconomy.generated_accounts
	departments = SSeconomy.departments
	dep_cards = SSeconomy.dep_cards
	cash_account = SSeconomy.cash_account
	market_account = SSeconomy.market_account
	tax_rate = SSeconomy.tax_rate
	fire_count = SSeconomy.fire_count
	economy_state = SSeconomy.economy_state
	price_surge_mult = SSeconomy.price_surge_mult
	bounty_modifier = SSeconomy.bounty_modifier
	pack_price_modifier = SSeconomy.pack_price_modifier
	full_ancap = SSeconomy.full_ancap
	contracts_started = SSeconomy.contracts_started
	loose_contracts = SSeconomy.loose_contracts
	contract_demand = SSeconomy.contract_demand
	escrow_account = SSeconomy.escrow_account
	lottery = SSeconomy.lottery
	treasury_requests = SSeconomy.treasury_requests
	contraband_window_start = SSeconomy.contraband_window_start
	contraband_paid_in_window = SSeconomy.contraband_paid_in_window
	audit_flags = SSeconomy.audit_flags
	audit_flag_uid = SSeconomy.audit_flag_uid
	audit_flags_overflow_logged = SSeconomy.audit_flags_overflow_logged
	crypto_paid = SSeconomy.crypto_paid
	crypto_paid_tick = SSeconomy.crypto_paid_tick

/datum/controller/subsystem/economy/fire(resumed)
	fire_count++
	var/list/staff_stats = econ_staff_stats()
	for(var/id in departments)
		var/datum/economy_department/department = departments[id]
		department.grant(staff_stats)
		department.approve_stale_requests()
		department.on_economy_tick()
		department.settle_owed()
	if(contracts_started)
		recover_contract_demand()
		refresh_contracts()
	else
		start_contracts()
	if(!(fire_count % settings.payroll_interval_ticks))
		run_payroll()
	staff_stats = econ_staff_stats()
	for(var/id in departments)
		var/datum/economy_department/department = departments[id]
		department.return_excess(staff_stats)
	update_state()
	ledger.snapshot()

/datum/controller/subsystem/economy/proc/get_department(id)
	return departments[id]

/datum/controller/subsystem/economy/proc/get_dep_account(id)
	for(var/datum/bank_account/department/account as anything in generated_accounts)
		if(account.department_id == id)
			return account

/datum/controller/subsystem/economy/proc/price_index()
	return (SSmarket?.price_index || 1) * price_surge_mult

/datum/controller/subsystem/economy/proc/run_payroll()
	for(var/datum/bank_account/account as anything in bank_accounts)
		if(QDELETED(account))
			continue
		account.update_dormancy()
		account.payday()
		CHECK_TICK
	SSmarket?.pay_dividends()

/// Экипаж на смене с должностью и все деньги станции: счета без должности, спящие, внестанционные, анонимные, акции и снятые наличные тоже, чтобы бедность нельзя было изобразить.
/datum/controller/subsystem/economy/proc/state_totals()
	var/crew = 0
	var/money = cash_account ? cash_account.account_balance : 0
	for(var/datum/bank_account/account as anything in bank_accounts)
		if(QDELETED(account))
			continue
		if(account.state == ACCOUNT_ACTIVE && account.department_id && !account.offstation)
			crew++
		money += account.account_balance + (SSmarket ? SSmarket.portfolio_value(account) : 0)
	for(var/id in departments)
		var/datum/economy_department/department = departments[id]
		money += department.account.account_balance + (SSmarket ? SSmarket.portfolio_value(department.account) : 0)
	return list("crew" = crew, "money" = money)

/// Сколько не хватает деньгам станции до порога бедности.
/datum/controller/subsystem/economy/proc/poor_deficit()
	var/list/totals = state_totals()
	return settings.state_poor_per_capita * totals["crew"] - totals["money"]

/datum/controller/subsystem/economy/proc/update_state()
	var/list/totals = state_totals()
	var/crew = totals["crew"]
	var/money = totals["money"]
	var/per_capita = crew ? money / crew : 0
	if(per_capita >= settings.state_rich_per_capita)
		economy_state = ECON_STATE_RICH
	else if(crew && per_capita <= settings.state_poor_per_capita)
		economy_state = ECON_STATE_POOR
	else
		economy_state = ECON_STATE_NORMAL
