/*******************************\
|		  Slot Machines		  	|
|	  Original code by Glloyd	|
|	  Tgstation port by Miauw	|
|	  TGUI rewrite	by Pingvas	|
\*******************************/

#define SPIN_PRICE_MIN 5
#define SPIN_PRICE_MAX 100
#define SMALL_PRIZE_BASE 50
#define BIG_PRIZE_BASE 150
#define SPIN_TIME 50 //As always, deciseconds.
#define REEL_DEACTIVATE_DELAY 7
#define SYMBOL_SEVEN "seven"
#define MAX_HISTORY 5
#define BONUS_CHANCE 1 // percent chance to trigger bonus on 2-match
#define SYMBOL_WILD "wild"
#define SYMBOL_SCATTER "scatter"
#define SCATTER_WIN_BASE 5
/// Возврат игроку при множителе выигрышей 1 на 1, 2 и 3 линиях: замер в игре на 300 тыс. вращений каждой, 3 сида (тест economy_slots/base_return); выигрыши бесплатных вращений входят, их ставки и джекпот - нет
GLOBAL_LIST_INIT(slot_paytable_base_return, list(0.71, 0.95, 1.23))
GLOBAL_LIST_INIT(slot_bet_options, list(5, 10, 25, 50, 100))
/// Выигрыши рассчитаны на эту долю банка: остаток копится и покрывает разброс
#define SLOT_BANK_FILL 0.95
/// Джекпот - столько семёрок или джокеров в центральном ряду
#define SLOT_JACKPOT_SEVENS 4
/// Джокеров среди них не больше этого: иначе джекпот срывался раз в ~4400 вращений и не успевал накопиться
#define SLOT_JACKPOT_WILDS_MAX 1

/obj/machinery/computer/slot_machine
	name = "slot machine"
	desc = "Игровой автомат. Принимает голочипы и деньги с ID-карты; часть каждой ставки забирает NT, остальное идёт в банк выигрышей и общий джекпот автоматов сектора."
	icon = 'icons/obj/kazino.dmi'
	icon_state = "mahins"
	icon_keyboard = null
	density = TRUE
	use_power = IDLE_POWER_USE
	idle_power_usage = 50
	circuit = /obj/item/circuitboard/computer/slot_machine
	light_color = LIGHT_COLOR_BROWN
	unique_icon = TRUE
	/// Банк обычных выигрышей: копится из доли ставок, выигрыш не больше банка
	var/prize_bank = 0
	/// Дробные части доли NT и джекпота, ещё не учтённые
	var/house_remainder = 0
	var/plays = 0
	var/working = FALSE
	var/balance = 0 //How much money is in the machine, ready to be CONSUMED.
	var/jackpots = 0
	var/list/reels = list(list("", "", "") = 0, list("", "", "") = 0, list("", "", "") = 0, list("", "", "") = 0, list("", "", "") = 0)
	var/list/symbols = list(SYMBOL_SEVEN = 1, "cherry" = 3, "banana" = 3, "strawberry" = 3, "grape" = 3, "diamond" = 3, "star" = 3, "watermelon" = 3, SYMBOL_WILD = 1, SYMBOL_SCATTER = 1)
	var/result_message = ""
	var/result_type = "" // "jackpot", "win", "small", "bonus", "lose"
	/// Currently selected bet amount
	var/bet_amount = 5
	/// Ставка, по которой считается выигрыш текущего вращения
	var/spin_bet = 5
	/// Ставка, при которой выиграны бесплатные вращения: по ней они и играются
	var/free_spin_bet = 5
	/// Bonus multiplier applied to current spin (1 = normal)
	var/bonus_multiplier = 1
	/// Whether a bonus round is active
	var/bonus_active = FALSE
	/// Win streak counter
	var/win_streak = 0
	/// Total winnings for current session (per-user, reset on refund)
	var/session_winnings = 0
	/// History of last N spin results
	var/list/spin_history = list()
	/// Auto-spin enabled
	var/auto_spin = FALSE
	/// Auto-spin remaining count
	var/auto_spin_remaining = 0
	/// Whether player can gamble current winnings
	var/gamble_available = FALSE
	/// Amount available for gambling
	var/gamble_amount = 0
	/// Near-miss detected
	var/near_miss = FALSE
	/// Near-miss message
	var/near_miss_message = ""
	/// Show confetti animation for big wins
	var/show_confetti = FALSE
	/// Number of active paylines (computed from bet)
	var/active_lines = 1
	/// Which payline produced the win (0 = none, 1-5)
	var/winning_line = 0
	/// Free spins remaining (actual free auto-spins)
	var/free_spins_remaining = 0
	/// Consecutive losses counter (for excitement mechanic)
	var/loss_streak = 0
	/// How many reels have stopped during current/last spin (for polosa overlays)
	var/stopped_reels = 0
	/// Whether to show the Win overlay (blinks on win)
	var/show_win_overlay = FALSE

/obj/machinery/computer/slot_machine/Initialize(mapload)
	. = ..()
	INVOKE_ASYNC(src, PROC_REF(toggle_reel_spin), TRUE)//The reels won't spin unless we activate them

	var/list/reel = reels[1]
	for(var/i = 0, i < reel.len, i++) //Populate the reels.
		randomize_reels()

	INVOKE_ASYNC(src, PROC_REF(toggle_reel_spin), FALSE)

/obj/machinery/computer/slot_machine/Destroy()
	if(balance)
		give_payout(balance)
	var/pools = round(prize_bank)
	if(pools > 0)
		SSeconomy.move(SSeconomy.cash_account, null, pools, ECON_GAMBLING, memo = "Банк разобранного игрового автомата")
	prize_bank = 0
	return ..()

/obj/machinery/computer/slot_machine/examine(mob/user)
	. = ..()
	var/datum/economy_settings/settings = SSeconomy.settings
	. += span_notice("С каждой платной ставки [settings.slot_house_edge]% забирает NT, [settings.slot_jackpot_share]% идёт в общий джекпот автоматов сектора, [slot_bank_share()]% - в банк выигрышей. Выигрыш не больше банка. Джекпот одинаков на всех автоматах, переходит в следующую смену и не бывает меньше [settings.slot_jackpot_floor] кр.")
	. += span_notice("Сейчас в банке [round(prize_bank)] кр., джекпот сектора [SSmarket.slot_jackpot_payout()] кр. Внести с карты можно до [SSeconomy.settings.slot_card_deposit_max] кр. за раз.")

/obj/machinery/computer/slot_machine/proc/slot_bank_share()
	return 100 - SSeconomy.settings.slot_house_edge - SSeconomy.settings.slot_jackpot_share

/// Множитель таблицы выигрышей: средний возврат игроку - доля банка за вычетом запаса.
/obj/machinery/computer/slot_machine/proc/prize_scale(bet = bet_amount)
	var/base = GLOB.slot_paytable_base_return[clamp(get_active_lines(bet), 1, length(GLOB.slot_paytable_base_return))]
	return slot_bank_share() / 100 * SLOT_BANK_FILL / base

/// Делит платную ставку: доля NT сгорает, доля джекпота и банк остаются в автомате наличными.
/obj/machinery/computer/slot_machine/proc/take_bet(amount, mob/user)
	var/datum/economy_settings/settings = SSeconomy.settings
	var/jackpot_part = amount * settings.slot_jackpot_share / 100
	var/exact_house = amount * settings.slot_house_edge / 100 + house_remainder
	var/house = min(round(exact_house), round(amount - jackpot_part))
	house_remainder = exact_house - house
	if(house > 0)
		SSeconomy.move(SSeconomy.cash_account, null, house, ECON_GAMBLING, user, "Доля NT со ставки")
	SSmarket.add_slot_jackpot(jackpot_part)
	prize_bank += amount - house - jackpot_part

/// Внесение с ID-карты в руке или на поясе: деньги со счёта уходят в наличные автомата.
/obj/machinery/computer/slot_machine/proc/card_deposit(mob/living/user, amount)
	if(!isliving(user) || !isnum(amount))
		return FALSE
	amount = round(amount)
	if(amount < 1 || amount > SSeconomy.settings.slot_card_deposit_max)
		to_chat(user, span_warning("Внести можно от 1 до [SSeconomy.settings.slot_card_deposit_max] кр. за раз."))
		return FALSE
	var/obj/item/card/id/card = user.get_idcard(TRUE)
	var/datum/bank_account/account = card?.registered_account
	var/problem = SSeconomy.personal_account_problem(account, TRUE)
	if(!problem && (account.being_dumped || world.time < account.withdrawDelay))
		problem = "Счёт недоступен: идёт техобслуживание банка."
	if(problem)
		to_chat(user, span_warning(problem))
		return FALSE
	if(!account.has_money(amount))
		to_chat(user, span_warning("На счёте [account.account_balance] кр."))
		return FALSE
	if(!SSeconomy.move(account, SSeconomy.cash_account, amount, ECON_CASH_OUT, user, "Игровой автомат"))
		return FALSE
	balance += amount
	playsound(src, 'modular_bluemoon/sound/machines/slot-machine/money.ogg', 50, TRUE)
	return TRUE

/obj/machinery/computer/slot_machine/update_icon_state()
	if(machine_stat & BROKEN)
		icon_state = "mahinsb"
	else
		icon_state = "mahins"

/obj/machinery/computer/slot_machine/update_overlays()
	. = ..()
	if(machine_stat & (NOPOWER|BROKEN))
		return
	. += mutable_appearance('icons/obj/kazino.dmi', "pole")
	if(working)
		. += mutable_appearance('icons/obj/kazino.dmi', "knopka_start_on")
		. += mutable_appearance('icons/obj/kazino.dmi', "prokrut")
	else
		. += mutable_appearance('icons/obj/kazino.dmi', "knopka_start")
	for(var/i = 1, i <= min(stopped_reels, 5), i++)
		. += mutable_appearance('icons/obj/kazino.dmi', "[i]_polosa")
	if(show_win_overlay)
		. += mutable_appearance('icons/obj/kazino.dmi', "Win")

/obj/machinery/computer/slot_machine/attackby(obj/item/I, mob/living/user, params)
	if(istype(I, /obj/item/coin))
		to_chat(user, span_warning("Автомат принимает только голочипы и деньги с ID-карты."))
	else if(istype(I, /obj/item/card/id))
		to_chat(user, span_notice("Внести деньги с карты можно в окне автомата."))
	else if(istype(I, /obj/item/holochip))
		var/obj/item/holochip/H = I
		if(!user.temporarilyRemoveItemFromInventory(H))
			return
		to_chat(user, span_notice("Вы вставляете в автомат голочип на [H.credits] кр."))
		playsound(src, 'modular_bluemoon/sound/machines/slot-machine/money.ogg', 50, TRUE)
		balance += H.credits
		qdel(H)
	else
		return ..()

/obj/machinery/computer/slot_machine/emag_act()
	. = ..()
	if(obj_flags & EMAGGED)
		return
	log_admin("[key_name(usr)] emagged [src] at [AREACOORD(src)]")
	obj_flags |= EMAGGED
	var/datum/effect_system/spark_spread/spark_system = new /datum/effect_system/spark_spread()
	spark_system.set_up(4, 0, src.loc)
	spark_system.start()
	playsound(src, "sparks", 50, TRUE)

/obj/machinery/computer/slot_machine/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "SlotMachine", name)
		ui.open()
		ui.set_autoupdate(TRUE)

/obj/machinery/computer/slot_machine/ui_data(mob/user)
	var/list/data = list()
	data["money"] = SSmarket.slot_jackpot_payout()
	data["prize_bank"] = round(prize_bank)
	data["house_edge"] = SSeconomy.settings.slot_house_edge
	data["jackpot_share"] = SSeconomy.settings.slot_jackpot_share
	data["bank_share"] = slot_bank_share()
	data["deposit_max"] = SSeconomy.settings.slot_card_deposit_max
	var/bet_multiplier = bet_amount / SPIN_PRICE_MIN * prize_scale(bet_amount)
	data["prize_big"] = round(BIG_PRIZE_BASE * bet_multiplier)
	data["prize_small"] = round(SMALL_PRIZE_BASE * bet_multiplier)
	data["jackpot_sevens"] = SLOT_JACKPOT_SEVENS
	data["plays"] = plays
	data["jackpots"] = jackpots
	data["balance"] = balance
	data["working"] = working
	data["bet_amount"] = bet_amount
	data["bet_options"] = GLOB.slot_bet_options
	data["result_message"] = result_message
	data["result_type"] = result_type
	data["bonus_multiplier"] = bonus_multiplier
	data["bonus_active"] = bonus_active
	data["win_streak"] = win_streak
	data["session_winnings"] = session_winnings
	data["auto_spin"] = auto_spin
	data["auto_spin_remaining"] = auto_spin_remaining
	data["free_spins_remaining"] = free_spins_remaining
	data["loss_streak"] = loss_streak

	var/list/reel_data = list()
	for(var/list/reel in reels)
		var/list/reel_info = list()
		reel_info["symbols"] = reel.Copy()
		reel_info["stopped"] = !reels[reel]
		reel_data += list(reel_info)
	data["reels"] = reel_data

	data["spin_history"] = spin_history

	data["gamble_available"] = gamble_available
	data["gamble_amount"] = gamble_amount

	data["near_miss"] = near_miss
	data["near_miss_message"] = near_miss_message
	data["show_confetti"] = show_confetti
	data["active_lines"] = active_lines
	data["winning_line"] = winning_line

	return data

/obj/machinery/computer/slot_machine/ui_act(action, params)
	. = ..()
	if(.)
		return

	switch(action)
		if("spin")
			spin(usr)
			. = TRUE
		if("card_deposit")
			if(!working)
				card_deposit(usr, text2num("[params["amount"]]"))
			. = TRUE
		if("refund")
			if(balance > 0)
				give_payout(balance)
				balance = 0
				session_winnings = 0
				win_streak = 0
				loss_streak = 0
				auto_spin = FALSE
				auto_spin_remaining = 0
				free_spins_remaining = 0
			. = TRUE
		if("set_bet")
			var/new_bet = text2num("[params["amount"]]")
			if(!working && (new_bet in GLOB.slot_bet_options))
				bet_amount = new_bet
				active_lines = get_active_lines()
			. = TRUE
		if("auto_spin")
			if(!working)
				var/count = text2num(params["count"])
				if(count && count > 0 && count <= 50)
					auto_spin = TRUE
					auto_spin_remaining = count
					spin(usr)
				else
					auto_spin = FALSE
					auto_spin_remaining = 0
			. = TRUE
		if("stop_auto")
			auto_spin = FALSE
			auto_spin_remaining = 0
			. = TRUE
		if("gamble")
			if(gamble_available && gamble_amount > 0 && !working)
				var/choice = params["choice"]
				if(choice != "red" && choice != "black")
					return
				if(balance < gamble_amount)
					result_message = "Не хватает баланса для удвоения."
					result_type = "lose"
					gamble_available = FALSE
					gamble_amount = 0
					. = TRUE
					return
				if(prize_bank < gamble_amount)
					result_message = "Банк автомата не покроет удвоение."
					result_type = "lose"
					gamble_available = FALSE
					gamble_amount = 0
					. = TRUE
					return
				balance -= gamble_amount
				if(prob(25)) // 25% - strong house edge
					session_winnings += gamble_amount
					prize_bank -= gamble_amount
					gamble_amount *= 2
					balance += gamble_amount
					result_message = "Удвоение! Выигрыш: [gamble_amount] кр."
					result_type = "win"
					playsound(src, 'modular_bluemoon/sound/machines/slot-machine/money.ogg', 60, TRUE)
				else
					session_winnings -= gamble_amount
					prize_bank += gamble_amount
					result_message = "Удвоение не удалось: -[gamble_amount] кр."
					result_type = "lose"
					gamble_amount = 0
					gamble_available = FALSE
					win_streak = 0
			. = TRUE
		if("collect")
			gamble_available = FALSE
			gamble_amount = 0
			. = TRUE

/obj/machinery/computer/slot_machine/emp_act(severity)
	. = ..()
	if(machine_stat & (NOPOWER|BROKEN) || . & EMP_PROTECT_SELF)
		return
	if(prob(15 * severity))
		return
	if(prob(1)) // :^)
		obj_flags |= EMAGGED
	var/severity_ascending = 4 - severity
	var/spill = min(rand(0, 100 * severity_ascending), round(prize_bank))
	if(spill > 0)
		prize_bank -= spill
		give_payout(spill)
	spin()

/obj/machinery/computer/slot_machine/proc/spin(mob/user)
	if(!can_spin(user))
		auto_spin = FALSE
		auto_spin_remaining = 0
		return

	var/the_name
	if(user)
		the_name = user.real_name
		visible_message(span_notice("[user] дёргает рычаг, барабаны автомата закрутились!"))
	else
		the_name = "Exaybachay"

	charge_spin(user)
	working = TRUE
	reset_spin_state()

	playsound(src, 'modular_bluemoon/sound/machines/slot-machine/wheel.ogg', 30, TRUE)
	toggle_reel_spin(1)
	update_icon()
	SStgui.update_uis(src)

	var/spin_loop = addtimer(CALLBACK(src, PROC_REF(do_spin)), 2, TIMER_LOOP|TIMER_STOPPABLE)

	addtimer(CALLBACK(src, PROC_REF(finish_spinning), spin_loop, user, the_name), SPIN_TIME - (REEL_DEACTIVATE_DELAY * reels.len))
	//WARNING: no sanity checking for user since it's not needed and would complicate things (machine should still spin even if user is gone), be wary of this if you're changing this code.

/// Сброс итогов прошлого вращения: бонус, удвоение и сообщения не переходят в следующее.
/obj/machinery/computer/slot_machine/proc/reset_spin_state()
	result_message = ""
	result_type = ""
	bonus_multiplier = 1
	bonus_active = FALSE
	gamble_available = FALSE
	gamble_amount = 0
	near_miss = FALSE
	near_miss_message = ""
	show_confetti = FALSE
	active_lines = get_active_lines(spin_bet)
	winning_line = 0

/// Плата за вращение: бесплатное по ставке, на которой оно выиграно, или ставка с баланса.
/obj/machinery/computer/slot_machine/proc/charge_spin(mob/user)
	if(free_spins_remaining > 0)
		free_spins_remaining--
		spin_bet = free_spin_bet
	else
		spin_bet = bet_amount
		balance -= spin_bet
		take_bet(spin_bet, user)
	plays += 1

/obj/machinery/computer/slot_machine/proc/do_spin()
	randomize_reels()
	SStgui.update_uis(src)

/obj/machinery/computer/slot_machine/proc/finish_spinning(spin_loop, mob/user, the_name)
	toggle_reel_spin(0, REEL_DEACTIVATE_DELAY)
	working = FALSE
	deltimer(spin_loop)
	give_prizes(the_name, user)
	update_icon()
	SStgui.update_uis(src)
	// Free spins logic — trigger next free spin automatically
	if(free_spins_remaining > 0)
		addtimer(CALLBACK(src, PROC_REF(spin), user), 15)
		return
	// Auto-spin logic
	if(auto_spin && auto_spin_remaining > 0)
		auto_spin_remaining--
		if(auto_spin_remaining <= 0)
			auto_spin = FALSE
			auto_spin_remaining = 0
		else
			addtimer(CALLBACK(src, PROC_REF(spin), user), 15) // small delay between auto-spins

/obj/machinery/computer/slot_machine/proc/can_spin(mob/user)
	if(machine_stat & NOPOWER)
		to_chat(user, span_warning("У автомата нет питания."))
		return FALSE
	if(machine_stat & BROKEN)
		to_chat(user, span_warning("Автомат сломан."))
		return FALSE
	if(working)
		to_chat(user, span_warning("Дождитесь, пока барабаны остановятся."))
		return FALSE
	if(balance < bet_amount && free_spins_remaining <= 0)
		to_chat(user, span_warning("Не хватает баланса: ставка [bet_amount] кр."))
		return FALSE
	return TRUE

/obj/machinery/computer/slot_machine/proc/toggle_reel_spin(value, delay = 0) //value is 1 or 0 aka on or off
	if(value)
		stopped_reels = 0
	for(var/list/reel in reels)
		reels[reel] = value
		if(!value)
			stopped_reels++
			update_appearance(UPDATE_OVERLAYS)
		sleep(delay)

/obj/machinery/computer/slot_machine/proc/do_win_blink()
	for(var/i = 0, i < 3, i++)
		show_win_overlay = TRUE
		update_appearance(UPDATE_OVERLAYS)
		sleep(4)
		show_win_overlay = FALSE
		update_appearance(UPDATE_OVERLAYS)
		sleep(4)

/obj/machinery/computer/slot_machine/proc/randomize_reels()

	for(var/reel in reels)
		if(reels[reel])
			reel[3] = reel[2]
			reel[2] = reel[1]
			reel[1] = pick(symbols)

/obj/machinery/computer/slot_machine/proc/give_prizes(usrname, mob/user)
	var/list/line_result = get_lines(spin_bet)
	var/linelength = line_result[1]
	winning_line = line_result[2]
	var/bet_multiplier = spin_bet / SPIN_PRICE_MIN * prize_scale(spin_bet)
	var/won_amount = 0

	near_miss = FALSE
	near_miss_message = ""
	show_confetti = FALSE
	gamble_available = FALSE
	gamble_amount = 0

	var/pair_count = check_pairs()
	var/effective_bonus_chance = BONUS_CHANCE
	if(loss_streak >= 5)
		effective_bonus_chance = min(BONUS_CHANCE + (loss_streak - 4) * 2, 15)
	if(pair_count >= 2 && linelength < 3 && prob(effective_bonus_chance))
		bonus_multiplier = pick(2, 2, 2, 3, 3, 5)
		bonus_active = TRUE
		playsound(src, 'modular_bluemoon/sound/machines/slot-machine/bonus.ogg', 60, TRUE)

	var/sevens = 0
	var/wilds = 0
	for(var/col = 1, col <= 5, col++)
		var/sym = reels[col][2]
		if(sym == SYMBOL_SEVEN || sym == SYMBOL_WILD)
			sevens++
		if(sym == SYMBOL_WILD)
			wilds++

	if(sevens >= SLOT_JACKPOT_SEVENS && wilds <= SLOT_JACKPOT_WILDS_MAX)
		winning_line = 1
		won_amount = SSmarket.pay_slot_jackpot(user)
		balance += won_amount
		playsound(src, 'modular_bluemoon/sound/machines/slot-machine/jackpot.ogg', 80, TRUE)
		visible_message("<b>[src]</b> объявляет: «ДЖЕКПОТ СЕКТОРА! Выигрыш [won_amount] кр.!»")
		SSmarket.announce_slot_jackpot(user ? user.real_name : usrname, get_area(src), won_amount)
		jackpots += 1
		result_message = "🎉 ДЖЕКПОТ! +[won_amount] кр.!"
		result_type = "jackpot"
		win_streak++
		loss_streak = 0
		session_winnings += won_amount
		show_confetti = TRUE

	else if(linelength == 5)
		won_amount = give_money(round(BIG_PRIZE_BASE * bet_multiplier * bonus_multiplier))
		playsound(src, 'modular_bluemoon/sound/machines/slot-machine/money.ogg', 60, TRUE)
		visible_message("<b>[src]</b> объявляет: «Крупный выигрыш: [won_amount] кр.!»")
		result_message = "КРУПНЫЙ ВЫИГРЫШ! +[won_amount] кр.!"
		if(bonus_active)
			result_message += " (бонус x[bonus_multiplier]!)"
		result_type = "win"
		win_streak++
		loss_streak = 0
		session_winnings += won_amount
		show_confetti = TRUE
		gamble_available = TRUE
		gamble_amount = won_amount

	else if(linelength == 4)
		won_amount = give_money(round(SMALL_PRIZE_BASE * bet_multiplier * bonus_multiplier))
		playsound(src, 'modular_bluemoon/sound/machines/slot-machine/money.ogg', 50, TRUE)
		visible_message("<b>[src]</b> объявляет: «Выигрыш: [won_amount] кр.!»")
		result_message = "Выигрыш! +[won_amount] кр.!"
		if(bonus_active)
			result_message += " (бонус x[bonus_multiplier]!)"
		result_type = "win"
		win_streak++
		loss_streak = 0
		session_winnings += won_amount
		gamble_available = TRUE
		gamble_amount = won_amount

	else if(linelength == 3)
		var/free_spins = rand(1, 3)
		if(bonus_active)
			free_spins = free_spins * bonus_multiplier
		if(free_spins_remaining <= 0)
			free_spin_bet = spin_bet
		free_spins_remaining += free_spins
		playsound(src, 'modular_bluemoon/sound/machines/slot-machine/bonus.ogg', 50, TRUE)
		to_chat(user, "<span class='notice'>Вы выиграли [free_spins] бесплатных вращений!</span>")
		result_message = "🎰 Бесплатных вращений: [free_spins]!"
		if(bonus_active)
			result_message += " (бонус x[bonus_multiplier]!)"
		result_type = "small"
		win_streak++
		loss_streak = 0

	else if(bonus_active)
		playsound(src, 'modular_bluemoon/sound/machines/slot-machine/bonus.ogg', 60, TRUE)
		won_amount = give_money(round(spin_bet * bonus_multiplier * prize_scale(spin_bet)))
		result_message = "БОНУС x[bonus_multiplier]! +[won_amount] кр.!"
		result_type = "bonus"
		win_streak++
		loss_streak = 0
		session_winnings += won_amount
		gamble_available = TRUE
		gamble_amount = won_amount

	else
		result_type = "lose"
		win_streak = 0
		loss_streak++
		if(loss_streak >= 5)
			result_message = "🔥 Автомат разогрет: [loss_streak] проигрышей подряд, шанс бонуса выше!"
		else
			result_message = "Не повезло. Ещё раз?"
		if(prob(1))
			playsound(src, 'modular_bluemoon/sound/machines/slot-machine/casino_fuck.ogg', 50, TRUE)

	var/scatter_count = count_scatters()
	if(scatter_count >= 3)
		var/scatter_win = give_money(round(SCATTER_WIN_BASE * bet_multiplier * scatter_count))
		won_amount += scatter_win
		if(result_type == "lose")
			result_message = "💫 Скаттер x[scatter_count]! +[scatter_win] кр.!"
			result_type = "win"
			win_streak++
		else
			result_message += " +💫[scatter_win] кр.!"
		session_winnings += scatter_win
		gamble_available = TRUE
		gamble_amount += scatter_win
		playsound(src, 'modular_bluemoon/sound/machines/slot-machine/bonus.ogg', 60, TRUE)

	if(result_type == "lose")
		var/seven_count = 0
		for(var/i = 1, i <= 5, i++)
			if(reels[i][2] == SYMBOL_SEVEN || reels[i][2] == SYMBOL_WILD)
				seven_count++
		if(seven_count == SLOT_JACKPOT_SEVENS - 1)
			near_miss = TRUE
			near_miss_message = "Почти! [seven_count] из [SLOT_JACKPOT_SEVENS] семёрок для джекпота!"
		else
			var/has_near = FALSE
			var/static/list/near_miss_paylines = list(\
				list(2, 2, 2, 2, 2),\
				list(1, 1, 1, 1, 1),\
				list(3, 3, 3, 3, 3),\
				list(1, 2, 3, 2, 1),\
				list(3, 2, 1, 2, 3)\
			)
			for(var/li = 1, li <= active_lines && !has_near, li++)
				var/list/pl = near_miss_paylines[li]
				var/s1 = reels[1][pl[1]]
				var/s2 = reels[2][pl[2]]
				var/s3 = reels[3][pl[3]]
				if(s1 == SYMBOL_SCATTER || s2 == SYMBOL_SCATTER)
					continue
				var/match1 = (s1 == SYMBOL_WILD) ? s2 : s1
				var/match2 = (s2 == SYMBOL_WILD) ? s1 : s2
				if(match1 == match2 || s1 == SYMBOL_WILD || s2 == SYMBOL_WILD)
					if(s3 != match1 && s3 != SYMBOL_WILD)
						has_near = TRUE
			if(has_near)
				near_miss = TRUE
				near_miss_message = "Почти! Не хватило одного символа..."

	var/list/history_entry = list()
	history_entry["result"] = result_type
	history_entry["message"] = result_message
	history_entry["bet"] = spin_bet
	history_entry["won"] = won_amount
	spin_history += list(history_entry)
	if(spin_history.len > MAX_HISTORY)
		spin_history.Cut(1, 2)
	if(result_type != "lose")
		INVOKE_ASYNC(src, PROC_REF(do_win_blink))

/obj/machinery/computer/slot_machine/proc/check_pairs()
	var/list/counts = list()
	var/wild_count = 0
	for(var/i = 1, i <= 5, i++)
		var/sym = reels[i][2]
		if(sym == SYMBOL_WILD)
			wild_count++
			continue
		if(sym == SYMBOL_SCATTER)
			continue
		if(sym in counts)
			counts[sym]++
		else
			counts[sym] = 1
	var/best = 0
	for(var/sym in counts)
		var/total = counts[sym] + wild_count
		if(total > best)
			best = total
	if(!counts.len && wild_count)
		best = wild_count
	return best

/obj/machinery/computer/slot_machine/proc/count_scatters()
	var/count = 0
	for(var/col = 1, col <= 5, col++)
		for(var/row = 1, row <= 3, row++)
			if(reels[col][row] == SYMBOL_SCATTER)
				count++
				break
	return count

/obj/machinery/computer/slot_machine/proc/get_active_lines(bet = bet_amount)
	if(bet >= 25)
		return 3
	if(bet >= 10)
		return 2
	return 1

/obj/machinery/computer/slot_machine/proc/get_lines(bet = bet_amount)
	var/static/list/payline_defs = list(\
		list(2, 2, 2, 2, 2),\
		list(1, 1, 1, 1, 1),\
		list(3, 3, 3, 3, 3),\
		list(1, 2, 3, 2, 1),\
		list(3, 2, 1, 2, 3)\
	)
	var/num_lines = get_active_lines(bet)
	var/best = 0
	var/best_line = 0
	for(var/line_idx = 1, line_idx <= num_lines, line_idx++)
		var/list/payline = payline_defs[line_idx]
		var/list/line_syms = list()
		for(var/col = 1, col <= 5, col++)
			line_syms += reels[col][payline[col]]
		// Matches must start from the leftmost reel
		var/target_sym = null
		var/run = 0
		for(var/pos = 1, pos <= 5, pos++)
			var/sym = line_syms[pos]
			if(sym == SYMBOL_SCATTER)
				break
			if(sym == SYMBOL_WILD)
				run++
				continue
			if(!target_sym)
				target_sym = sym
				run++
			else if(sym == target_sym)
				run++
			else
				break
		if(run >= 3 && run > best)
			best = run
			best_line = line_idx
	return list(best, best_line)

/// Выигрыш из банка автомата, не больше банка; возвращает выплаченное.
/obj/machinery/computer/slot_machine/proc/give_money(amount)
	var/paid = clamp(round(amount), 0, round(prize_bank))
	prize_bank -= paid
	balance += paid
	if(paid < amount)
		visible_message(span_warning("[src] пищит: в банке выигрышей не хватило денег, выплачено [paid] из [round(amount)] кр."))
	return paid

/obj/machinery/computer/slot_machine/proc/give_payout(amount)
	if(amount <= 0)
		return
	var/obj/item/holochip/chip = new(loc, amount)
	if(obj_flags & EMAGGED)
		var/mob/living/target = locate() in range(2, src)
		if(target)
			chip.throw_at(target, 3, 10)

#undef SYMBOL_SEVEN
#undef SPIN_TIME
#undef BIG_PRIZE_BASE
#undef SMALL_PRIZE_BASE
#undef SPIN_PRICE_MIN
#undef SPIN_PRICE_MAX
#undef SLOT_BANK_FILL
#undef SLOT_JACKPOT_SEVENS
#undef SLOT_JACKPOT_WILDS_MAX
#undef MAX_HISTORY
#undef BONUS_CHANCE
#undef SYMBOL_WILD
#undef SYMBOL_SCATTER
#undef SCATTER_WIN_BASE
