#define DUMPTIME 3000
/// Сколько последних операций (/datum/transaction) держит счёт: столько показывают кошелёк и распечатка.
#define BANK_TRANSACTION_HISTORY_MAX 20

/datum/bank_account
	var/account_holder = "Rusty Venture"
	var/account_balance = 0
	/// Regulatory fines may overdraw an account; normal purchases still require funds.
	var/allow_debt = FALSE
	var/datum/job/account_job
	var/list/bank_cards = list()
	var/add_to_accounts = TRUE
	/// Счёт гост-роли или внешней команды: станционные механики вроде Crab-17 его не трогают
	var/offstation = FALSE
	var/transferable = TRUE
	var/account_id
	/// ACCOUNT_* отдела, к которому приписан владелец (у бюджета - сам отдел)
	var/department_id
	var/state = ACCOUNT_ACTIVE
	var/being_dumped = FALSE //pink levels are rising
	var/withdrawDelay = 0
	///List with a transaction history for the wallet app
	var/list/transaction_history = list()

/datum/bank_account/proc/add_transaction(purpose, amount, target_name = "System", source_terminal = "ID Card")
	if(!transaction_history)
		transaction_history = list()

	var/datum/transaction/T = new
	T.date = time2text(world.timeofday, "DD-MM-YYYY")
	T.time = time2text(world.timeofday, "hh:mm:ss")
	T.target_name = target_name
	T.purpose = purpose
	T.amount = amount
	T.source_terminal = source_terminal

	transaction_history += T
	trim_transaction_history()

/datum/bank_account/New(newname, job)
	account_holder = newname
	account_job = job
	SSeconomy.register_account(src)
	if(add_to_accounts)
		SSeconomy.bank_accounts += src

/datum/bank_account/Destroy()
	if(account_balance > 0)
		SSeconomy.move(src, null, account_balance, ECON_ACCOUNT_CLOSED)
	else if(account_balance < 0)
		SSeconomy.move(null, src, -account_balance, ECON_ACCOUNT_CLOSED)
	SSeconomy.unregister_account(src)
	SSeconomy.bank_accounts -= src
	transaction_history.Cut()
	return ..()

/// Сменить номер счёта, сохранив реестр SSeconomy.accounts_by_number в согласии.
/datum/bank_account/proc/set_account_number(number)
	SSeconomy.unregister_account(src)
	account_id = number
	SSeconomy.register_account(src)

/datum/bank_account/vv_edit_var(var_name, var_value, massedit) // just so you don't have to do it manually
	var/old_id = account_id
	var/old_balance = account_balance
	if(var_name == NAMEOF(src, account_balance) && isnum(var_value))
		var_value = round(var_value)
	. = ..(var_name, var_value, massedit)
	switch(var_name)
		if(NAMEOF(src, account_id))
			SSeconomy.unregister_account(src, old_id)
			SSeconomy.register_account(src)
		if(NAMEOF(src, add_to_accounts))
			if(add_to_accounts)
				SSeconomy.bank_accounts |= src
			else
				SSeconomy.bank_accounts -= src
		if(NAMEOF(src, account_balance))
			if(!isnum(old_balance) || !isnum(account_balance))
				return
			var/delta = account_balance - old_balance
			if(!delta)
				return
			SSeconomy.record_move(delta < 0 ? src : null, delta > 0 ? src : null, abs(delta), ECON_ADMIN, usr, log_tag = "VV")

/datum/bank_account/proc/dumpeet()
	being_dumped = TRUE
	withdrawDelay = world.time + DUMPTIME

/datum/bank_account/proc/has_money(amt)
	return account_balance >= amt

/// quiet - без звука и мелким шрифтом, для частых сообщений вроде зарплаты.
/datum/bank_account/proc/bank_card_talk(message, force, talk_sound = 'sound/machines/twobeep.ogg', balloon, quiet = FALSE)
	if(!message || !bank_cards.len)
		return
	var/text_class = quiet ? "smallnotice" : "notice"
	for(var/obj/A in bank_cards)
		var/icon_source = A
		/*
		if(istype(A, /obj/item/card/id))
			var/obj/item/card/id/id_card = A
			if(id_card.uses_overlays)
				icon_source = id_card.get_cached_flat_icon()
		*/
		var/mob/card_holder = recursive_loc_check(A, /mob)
		if(ismob(card_holder)) //If on a mob
			if(!card_talk_reaches(card_holder, force))
				return

			if(!quiet)
				card_holder.playsound_local(get_turf(card_holder), talk_sound, 50, TRUE)
			if(card_holder.can_hear())
				to_chat(card_holder, "[icon2html(icon_source, card_holder)] <span class='[text_class]'>[message]</span>")
				card_balloon(card_holder, balloon, force)
		else if(isturf(A.loc)) //If on the ground
			for(var/mob/M in hearers(1,get_turf(A)))
				if(M.client && !(M.client.prefs.chat_toggles & CHAT_BANKCARD) && !force)
					return
				if(!quiet)
					playsound(A, talk_sound, 50, TRUE)
				A.audible_message("[icon2html(icon_source, hearers(A))] <span class='[text_class]'>[message]</span>", null, 1)
				break
		else
			for(var/mob/M in A.loc) //If inside a container with other mobs (e.g. locker)
				if(!M.client || (!(M.client.prefs.chat_toggles & CHAT_BANKCARD) && !force))
					return
				if(!quiet)
					M.playsound_local(get_turf(M), talk_sound, 50, TRUE)
				if(M.can_hear())
					to_chat(M, "[icon2html(icon_source, M)] <span class='[text_class]'>[message]</span>")

GLOBAL_LIST_INIT(department_account_names, list(
	ACCOUNT_CMD = ACCOUNT_CMD_NAME,
	ACCOUNT_CIV = ACCOUNT_CIV_NAME,
	ACCOUNT_ENG = ACCOUNT_ENG_NAME,
	ACCOUNT_SCI = ACCOUNT_SCI_NAME,
	ACCOUNT_MED = ACCOUNT_MED_NAME,
	ACCOUNT_SRV = ACCOUNT_SRV_NAME,
	ACCOUNT_CAR = ACCOUNT_CAR_NAME,
	ACCOUNT_SEC = ACCOUNT_SEC_NAME,
	ACCOUNT_TAR = ACCOUNT_TAR_NAME,
	ACCOUNT_DS = ACCOUNT_DS_NAME,
))

/datum/bank_account/department
	account_holder = "Guild Credit Agency"
	add_to_accounts = FALSE
	var/datum/economy_department/department

/datum/bank_account/department/New(dep_id, budget)
	department_id = dep_id
	..(GLOB.department_account_names[dep_id])
	SSeconomy.generated_accounts += src
	if(budget)
		credit(budget, ECON_STARTING_FUNDS)

/datum/bank_account/department/Destroy()
	SSeconomy.generated_accounts -= src
	if(department?.account == src)
		department.account = null
	department = null
	return ..()

/datum/bank_account/remote // Bank account not belonging to the local station
	add_to_accounts = FALSE

/datum/bank_account/remote/non_transferable
	transferable = FALSE

/**
 * Add log to transactions history. Deletes the oldest log when the history has more than BANK_TRANSACTION_HISTORY_MAX entries.
 * Main format: Category: Reason in Reason. Example: Vending: Machinery Using
 * Arguments:
 * * adjusted_money - How much was added, negative values removing cash.
 * * label - Текст операции для игрока, например "Покупка в автомате" или "Зарплата".
 * * counterparty - Вторая сторона операции.
 * * reason - Причина ECON_* из SSeconomy.move(), если операция прошла через журнал.
 * * counterparty_number - Номер счёта второй стороны, null для эмиссии и стока.
 */
/datum/bank_account/proc/add_log_to_history(adjusted_money, label, counterparty = "Nanotrasen", reason, counterparty_number)
	var/datum/transaction/T = new()
	T.date = GLOB.current_date_string
	T.time = STATION_TIME_TIMESTAMP("hh:mm:ss", world.time)
	T.target_name = counterparty
	T.purpose = label
	T.reason = reason
	T.counterparty_number = counterparty_number
	T.amount = adjusted_money          // уже со знаком
	T.source_terminal = "Account System"
	transaction_history += T
	trim_transaction_history()

/// Обрезает историю до BANK_TRANSACTION_HISTORY_MAX после добавления; зовут и add_log_to_history(), и add_transaction().
/// Вытесненные операции без qdel: на них ссылается только история, и refcount освобождает их сразу.
/datum/bank_account/proc/trim_transaction_history()
	while(length(transaction_history) > BANK_TRANSACTION_HISTORY_MAX)
		transaction_history.Cut(1, 2)

/datum/transaction
	var/target_name = ""
	var/purpose = ""
	var/amount = 0
	var/date = ""
	var/time = ""
	var/source_terminal = ""
	var/reason
	var/counterparty_number

#undef DUMPTIME
#undef BANK_TRANSACTION_HISTORY_MAX
