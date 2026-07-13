SUBSYSTEM_DEF(economy)
	name = "Economy"
	wait = 5 MINUTES
	init_order = INIT_ORDER_ECONOMY
	runlevels = RUNLEVEL_GAME
	var/roundstart_paychecks = 10
	var/budget_pool = 70000
	var/list/department_accounts = list(ACCOUNT_CIV = ACCOUNT_CIV_NAME,
										ACCOUNT_ENG = ACCOUNT_ENG_NAME,
										ACCOUNT_SCI = ACCOUNT_SCI_NAME,
										ACCOUNT_MED = ACCOUNT_MED_NAME,
										ACCOUNT_SRV = ACCOUNT_SRV_NAME,
										ACCOUNT_CAR = ACCOUNT_CAR_NAME,
										ACCOUNT_SEC = ACCOUNT_SEC_NAME)
	var/list/generated_accounts = list()
	/// A var that collects the total amount of credits owned in player accounts on station, reset and recounted on fire()
	var/station_total = 0
	/// A var that tracks how much money is expected to be on station at a given time. If less than station_total prices go up in vendors.
	var/station_target = 1
	/// A passively increasing buffer to help alliviate inflation later into the shift, but to a lesser degree.
	var/station_target_buffer = 0
	/// A var that displays the result of inflation_value for easier debugging and tracking.
	var/inflation_value = 1
	/// Множитель цен от события Market Crash: 1 в обычное время, выше во время обвала.
	/// Применяется поверх штатной инфляции в inflation_value().
	var/price_surge_mult = 1
	/// Contains the message to send to newscasters about earnings, updated on price_update()
	var/civ_bounty_tracker = 0
	var/full_ancap = FALSE // Enables extra money charges for things that normally would be free, such as sleepers/cryo/cloning.
							//Take care when enabling, as players will NOT respond well if the economy is set up for low cash flows.
	var/alive_humans_bounty = 100
	var/crew_safety_bounty = 1500
	var/monster_bounty = 150
	var/mood_bounty = 100
	var/techweb_bounty = 5
	var/list/bank_accounts_by_id = list()
	var/slime_bounty = list("grey" = 5,
							// tier 1
							"orange" = 10,
							"metal" = 10,
							"blue" = 10,
							"purple" = 10,
							// tier 2
							"dark purple" = 50,
							"dark blue" = 50,
							"green" = 50,
							"silver" = 50,
							"gold" = 50,
							"yellow" = 50,
							"red" = 50,
							"pink" = 50,
							// tier 3
							"cerulean" = 75,
							"sepia" = 75,
							"bluespace" = 75,
							"pyrite" = 75,
							"light pink" = 75,
							"oil" = 75,
							"adamantine" = 75,
							// tier 4
							"rainbow" = 100)
	var/list/bank_accounts = list() //List of normal accounts (not department accounts)
	var/list/dep_cards = list()
	///The modifier multiplied to the value of bounties paid out.
	var/bounty_modifier = 1
	/// Contains the message to send to newscasters about price inflation and earnings, updated on price_update()
	var/earning_report
	///The modifier multiplied to the value of cargo pack prices.
	var/pack_price_modifier = 1
	// var/market_crashing = FALSE

	/// Total value of exported materials.
	var/export_total = 0
	/// Total value of imported goods.
	var/import_total = 0

/datum/controller/subsystem/economy/Initialize(timeofday)
	var/budget_to_hand_out = round(budget_pool / department_accounts.len)
	for(var/A in department_accounts)
		new /datum/bank_account/department(A, budget_to_hand_out)
	return ..()

/datum/controller/subsystem/economy/Recover()
	generated_accounts = SSeconomy.generated_accounts
	bank_accounts_by_id = SSeconomy.bank_accounts_by_id
	dep_cards = SSeconomy.dep_cards

/datum/controller/subsystem/economy/fire(resumed = 0)
	eng_payout()  // Payout based on nothing. What will replace it? Surplus power, powered APC's, air alarms? Who knows.
	sci_payout() // Payout based on slimes.
	secmedsrv_payout() // Payout based on crew safety, health, and mood.
	civ_payout() // Payout based on ??? Profit
	car_payout() // Cargo's natural gain in the cash moneys.
	var/temporary_total = 0
	station_total = 0
	station_target_buffer += STATION_TARGET_BUFFER
	for(var/account in bank_accounts)
		var/datum/bank_account/bank_account = account
		bank_account.payday(1)

	for(var/account in bank_accounts_by_id)
		var/datum/bank_account/bank_account = bank_accounts_by_id[account]
		if(bank_account?.account_job && !ispath(bank_account.account_job))
			temporary_total += (bank_account.account_job.paycheck * STARTING_PAYCHECKS)
		station_total += bank_account.account_balance
	station_target = max(round(temporary_total / max(bank_accounts_by_id.len * 2, 1)) + station_target_buffer, 1)

	// if(!market_crashing)
		// price_update()

/datum/controller/subsystem/economy/proc/get_dep_account(dep_id)
	for(var/datum/bank_account/department/D in generated_accounts)
		if(D.department_id == dep_id)
			return D

/datum/controller/subsystem/economy/proc/eng_payout()
	var/engineering_cash = 3000
	var/datum/bank_account/D = get_dep_account(ACCOUNT_ENG)
	if(D)
		D.adjust_money(engineering_cash)


/datum/controller/subsystem/economy/proc/car_payout()
	var/cargo_cash = 500
	var/datum/bank_account/D = get_dep_account(ACCOUNT_CAR)
	if(D)
		D.adjust_money(cargo_cash)

/datum/controller/subsystem/economy/proc/secmedsrv_payout()
	var/crew
	var/alive_crew
	var/dead_monsters
	var/cash_to_grant
	for(var/mob/m in GLOB.mob_list)
		if(isnewplayer(m))
			continue
		if(m.mind)
			if(isbrain(m) || iscameramob(m))
				continue
			if(ishuman(m))
				var/mob/living/carbon/human/H = m
				crew++
				if(H.stat != DEAD)
					alive_crew++
					var/datum/component/mood/mood = H.GetComponent(/datum/component/mood)
					var/medical_cash = (H.health / H.maxHealth) * alive_humans_bounty
					if(mood)
						var/datum/bank_account/D = get_dep_account(ACCOUNT_SRV)
						if(D)
							var/mood_dosh = (mood.mood_level / 9) * mood_bounty
							D.adjust_money(mood_dosh)
						medical_cash *= (mood.sanity / 100)

					var/datum/bank_account/D = get_dep_account(ACCOUNT_MED)
					if(D)
						D.adjust_money(medical_cash)
		if(ishostile(m))
			var/mob/living/simple_animal/hostile/H = m
			if(H.stat == DEAD && (H.z in SSmapping.levels_by_trait(ZTRAIT_STATION)))
				dead_monsters++
		CHECK_TICK
	var/living_ratio = alive_crew / crew
	cash_to_grant = (crew_safety_bounty * living_ratio) + (monster_bounty * dead_monsters)
	var/datum/bank_account/D = get_dep_account(ACCOUNT_SEC)
	if(D)
		D.adjust_money(min(cash_to_grant*3, MAX_GRANT_SECMEDSRV))

/datum/controller/subsystem/economy/proc/sci_payout()
	var/science_bounty = 0
	for(var/mob/living/simple_animal/slime/S in GLOB.mob_list)
		if(S.stat == DEAD)
			continue
		science_bounty += slime_bounty[S.colour]
	var/datum/bank_account/D = get_dep_account(ACCOUNT_SCI)
	if(D)
		D.adjust_money(min(science_bounty, MAX_GRANT_SCI))

/datum/controller/subsystem/economy/proc/civ_payout()
	var/civ_cash = (rand(1,5) * 500)
	var/datum/bank_account/D = get_dep_account(ACCOUNT_CIV)
	if(D)
		D.adjust_money(min(civ_cash, MAX_GRANT_CIV))

/**
 * Proc that returns a value meant to shift inflation values in vendors, based on how much money exists on the station.
 *
 * If crew are somehow aquiring far too much money, this value will dynamically cause vendables across the station to skyrocket in price until some money is spent.
 * Additionally, civilain bounties will cost less, and cargo goodies will increase in price as well.
 * The goal here is that if you want to spend money, you'll have to get it, and the most efficient method is typically from other players.
 **/
/datum/controller/subsystem/economy/proc/inflation_value()
	if(!bank_accounts_by_id.len)
		return price_surge_mult
	inflation_value = max(round(((station_total / bank_accounts_by_id.len) / station_target), 0.1), 1.0) * price_surge_mult
	return inflation_value
