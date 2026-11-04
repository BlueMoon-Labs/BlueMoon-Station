#define SKIM_WINDOW (1 MINUTES)
#define SKIM_LOG_TIME 1
#define SKIM_LOG_AMOUNT 2

/datum/bank_account
	/// Откачки скиммеров с этого счёта за последнюю минуту: list(world.time, сумма), общие для всех скиммеров
	var/list/skim_log

/obj/item/card_skimmer
	name = "card reader"
	desc = "Плоский считыватель для бесконтактных платежей."
	icon = 'icons/obj/economy/items.dmi'
	icon_state = "skimmer"
	item_state = "skimmer"
	lefthand_file = 'icons/mob/inhands/economy_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/economy_righthand.dmi'
	w_class = WEIGHT_CLASS_TINY
	/// Weakref на скопированные счета, старший первый
	var/list/stolen = list()
	var/last_target_number
	/// Ответ на последнее действие в окне
	var/message = ""

/obj/item/card_skimmer/examine(mob/user)
	. = ..()
	if(!user.mind?.has_antag_datum(/datum/antagonist/traitor) && !user.mind?.has_antag_datum(/datum/antagonist/overthrow))
		return
	. += span_notice("Это скиммер. Приложите его к ID-карте или к человеку с картой: за [DisplayTimeText(ECON_SKIMMER_DO_AFTER)] рядом он незаметно копирует доступ к чужому личному счёту, в конце раздаётся тихий щелчок, слышный только рядом. Помнит до [SSeconomy.settings.skimmer_slots] счетов, новый вытесняет самый старый.")
	. += span_notice("В руке - перевод со скопированного счёта на любой личный счёт: не больше [SSeconomy.settings.skim_rate] кр. с одного счёта за любую минуту. Каждое списание попадает в финансовый аудит как «неопознанное устройство» вместе со счётом, куда ушли деньги, и видно владельцу в истории операций: имя получателя скрывает только анонимный счёт.")
	. += span_notice("Скопировано счетов: [length(stolen)]. Пока в памяти есть счета, на корпусе мигает диод - его видят все, но у считывателя платежей это обычный индикатор.")

/obj/item/card_skimmer/update_icon_state()
	icon_state = length(stolen) ? "skimmer_loaded" : "skimmer"
	return ..()

/// Счёт самого держателя: у человека - по account_id, а не по карте в руках, где может оказаться чужая.
/obj/item/card_skimmer/proc/own_account(mob/user)
	if(ishuman(user))
		var/mob/living/carbon/human/person = user
		return SSeconomy.find_account(person.account_id)
	return econ_account_of(user)

/// Почему с карты нельзя скопировать счёт; null - можно.
/obj/item/card_skimmer/proc/skim_problem(obj/item/card/id/card, mob/user)
	var/datum/bank_account/account = card?.registered_account
	if(!account)
		return "На карте нет банковского счёта."
	if(user && own_account(user) == account)
		return "Это ваш собственный счёт."
	if(!SSeconomy.is_personal_account(account) || account.service_account)
		return "Бюджеты, служебные и заблокированные счета скиммер не берёт."
	for(var/datum/weakref/ref as anything in stolen)
		if(ref.resolve() == account)
			return "Этот счёт уже скопирован."
	return null

/obj/item/card_skimmer/proc/skim_card(obj/item/card/id/card, mob/user)
	if(skim_problem(card, user))
		return FALSE
	var/datum/bank_account/account = card.registered_account
	while(length(stolen) >= SSeconomy.settings.skimmer_slots)
		stolen.Cut(1, 2)
	stolen += WEAKREF(account)
	update_appearance()
	log_econ("[key_name(user)] скопировал скиммером доступ к счёту [account.account_holder] №[account.account_id]")
	return TRUE

/// Карта, которую скиммер считывает за do_after: на человеке или у существа на руках.
/obj/item/card_skimmer/proc/timed_card(atom/target)
	if(ishuman(target))
		var/mob/living/carbon/human/person = target
		return person.get_idcard(FALSE)
	if(istype(target, /obj/item/clothing/head/mob_holder))
		var/obj/item/holder = target
		return holder.GetID()

/// Начинает считывание с target; TRUE, если do_after пошёл.
/obj/item/card_skimmer/proc/start_skim(atom/target, mob/user)
	var/obj/item/card/id/card = timed_card(target)
	if(!card?.registered_account)
		to_chat(user, span_warning("Не видно ID-карты со счётом: [target]."))
		return FALSE
	if(!warn_skim_problem(card, user))
		return FALSE
	INVOKE_ASYNC(src, PROC_REF(skim_timed), target, user)
	return TRUE

/obj/item/card_skimmer/proc/skim_timed(atom/target, mob/user)
	if(!do_after(user, ECON_SKIMMER_DO_AFTER, target))
		return
	report_skim(timed_card(target), user)

/// FALSE и сообщение, если счёт с карты не скопировать; о своём счёте молчит.
/obj/item/card_skimmer/proc/warn_skim_problem(obj/item/card/id/card, mob/user)
	var/problem = skim_problem(card, user)
	if(!problem)
		return TRUE
	if(!user || own_account(user) != card?.registered_account)
		to_chat(user, span_warning(problem))
	return FALSE

/obj/item/card_skimmer/proc/report_skim(obj/item/card/id/card, mob/user)
	if(!warn_skim_problem(card, user))
		return FALSE
	skim_card(card, user)
	playsound(src, 'sound/economy/skimmer_click.ogg', 15, TRUE, SILENCED_SOUND_EXTRARANGE)
	to_chat(user, span_notice("Доступ к счёту [card.registered_account.account_holder] скопирован."))
	return TRUE

/obj/item/card_skimmer/attack(mob/living/target, mob/living/user, attackchain_flags, damage_multiplier)
	if(!ishuman(target) || user.a_intent == INTENT_HARM || !econ_knows_crime_tools(user))
		return ..()
	start_skim(target, user)

/obj/item/card_skimmer/pre_attack(atom/target, mob/living/user, params, attackchain_flags, damage_multiplier)
	. = ..()
	if((. & STOP_ATTACK_PROC_CHAIN) || !isitem(target) || !econ_knows_crime_tools(user))
		return
	if(istype(target, /obj/item/clothing/head/mob_holder))
		if(start_skim(target, user))
			return . | STOP_ATTACK_PROC_CHAIN
		return
	var/obj/item/held = target
	var/obj/item/card/id/card = held.GetID()
	if(card && report_skim(card, user))
		return . | STOP_ATTACK_PROC_CHAIN

/obj/item/card_skimmer/attack_self(mob/user)
	. = ..()
	ui_interact(user)

/obj/item/card_skimmer/ui_state(mob/user)
	return GLOB.hands_state

/obj/item/card_skimmer/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		message = ""
		ui = new(user, src, "Skimmer", name)
		ui.open()

/obj/item/card_skimmer/ui_data(mob/user)
	if(!econ_knows_crime_tools(user))
		return list("knows" = FALSE)
	var/datum/economy_settings/settings = SSeconomy.settings
	var/list/accounts = list()
	for(var/datum/weakref/ref as anything in stolen)
		var/datum/bank_account/account = ref.resolve()
		var/state = "ok"
		if(!account || QDELETED(account) || !(account in SSeconomy.bank_accounts))
			state = "closed"
		else if(!account.transferable)
			state = "blocked"
		else if(account.state == ACCOUNT_FROZEN)
			state = "frozen"
		var/open = state != "closed"
		accounts += list(list(
			"ref" = REF(ref),
			"holder" = open ? account.account_holder : null,
			"number" = open ? account.account_id : null,
			"balance" = open ? account.account_balance : 0,
			"left" = open ? skim_left(account) : 0,
			"state" = state,
		))
	return list(
		"knows" = TRUE,
		"stolen" = accounts,
		"rate" = settings.skim_rate,
		"slots" = settings.skimmer_slots,
		"transfer_max" = settings.transfer_max,
		"last_target" = last_target_number,
		"message" = message,
	)

/// Номер слота по REF() его weakref: окно шлёт ссылку, слоты сдвигаются при вытеснении.
/obj/item/card_skimmer/proc/stolen_index(ref_text)
	if(!istext(ref_text))
		return 0
	for(var/index in 1 to length(stolen))
		if(REF(stolen[index]) == ref_text)
			return index
	return 0

/obj/item/card_skimmer/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	var/mob/user = usr
	if(!econ_knows_crime_tools(user))
		return FALSE
	var/index = stolen_index(params["ref"])
	if(!index)
		message = "Этого счёта уже нет в памяти скиммера."
		return TRUE
	switch(action)
		if("siphon")
			var/target_number = econ_ui_number(params["target"])
			var/amount = econ_ui_number(params["amount"])
			var/problem = siphon(index, target_number, amount, user)
			if(problem)
				message = problem
				return TRUE
			last_target_number = target_number
			message = "Переведено [round(amount)] кр. на счёт №[target_number]."
			return TRUE
		if("forget")
			var/datum/weakref/ref = stolen[index]
			var/datum/bank_account/account = ref.resolve()
			log_game("[key_name(user)] стёр из скиммера счёт [account ? "[account.account_holder] №[account.account_id]" : "(закрыт)"]")
			stolen.Cut(index, index + 1)
			update_appearance()
			message = "Счёт стёрт из памяти скиммера."
			return TRUE
	return FALSE

/// Сколько ещё можно снять со счёта скиммерами в скользящем минутном окне.
/obj/item/card_skimmer/proc/skim_left(datum/bank_account/account)
	var/since = world.time - SKIM_WINDOW
	var/spent = 0
	for(var/list/entry as anything in account.skim_log)
		if(entry[SKIM_LOG_TIME] > since)
			spent += entry[SKIM_LOG_AMOUNT]
	return max(SSeconomy.settings.skim_rate - spent, 0)

/// Перевод со скопированного счёта index на счёт target_number. null - прошло, иначе текст отказа.
/obj/item/card_skimmer/proc/siphon(index, target_number, amount, mob/user)
	if(!isnum(index) || index < 1 || index > length(stolen))
		return "Нет такого счёта."
	var/datum/weakref/ref = stolen[index]
	var/datum/bank_account/victim = ref.resolve()
	if(!victim || QDELETED(victim) || !(victim in SSeconomy.bank_accounts))
		return "Счёт закрыт."
	if(!victim.transferable)
		return "Счёт заблокирован."
	if(victim.state == ACCOUNT_FROZEN)
		return "Счёт заморожен финансовым аудитом."
	if(!isnum(amount) || round(amount) < 1)
		return "Неверная сумма."
	amount = round(amount)
	if(amount > SSeconomy.settings.transfer_max)
		return "Сумма выше лимита: не больше [SSeconomy.settings.transfer_max] кр. за раз."
	if(amount > skim_left(victim))
		return "Не больше [SSeconomy.settings.skim_rate] кр. в минуту с одного счёта: сейчас можно ещё [skim_left(victim)] кр."
	var/datum/bank_account/target = SSeconomy.find_account(target_number)
	if(!target)
		return "Счёт получателя не найден."
	. = SSeconomy.personal_account_problem(target, FALSE)
	if(.)
		return
	if(target == victim)
		return "Нельзя переводить на тот же счёт."
	if(!victim.has_money(amount))
		return "Недостаточно средств: на счёте [victim.account_balance] кр."
	if(!SSeconomy.move(victim, target, amount, ECON_SKIM, user))
		return "Платёж отклонён."
	var/since = world.time - SKIM_WINDOW
	for(var/list/entry as anything in victim.skim_log)
		if(entry[SKIM_LOG_TIME] <= since)
			victim.skim_log -= list(entry)
	LAZYADD(victim.skim_log, list(list(world.time, amount)))
	return null

#undef SKIM_LOG_AMOUNT
#undef SKIM_LOG_TIME
#undef SKIM_WINDOW
