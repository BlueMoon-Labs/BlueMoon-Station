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
#define JACKPOT 10000
#define SPIN_TIME 50 //As always, deciseconds.
#define REEL_DEACTIVATE_DELAY 7
#define SYMBOL_SEVEN "seven"
#define HOLOCHIP 1
#define COIN 2
#define MAX_HISTORY 5
#define BONUS_CHANCE 2 // percent chance to trigger bonus on 2-match
#define SYMBOL_WILD "wild"
#define SYMBOL_SCATTER "scatter"
#define SCATTER_WIN_BASE 10

/obj/machinery/computer/slot_machine
	name = "slot machine"
	desc = "Gambling for the antisocial."
	icon = 'icons/obj/economy.dmi'
	icon_state = "slots1"
	icon_keyboard = null
	density = TRUE
	use_power = IDLE_POWER_USE
	idle_power_usage = 50
	circuit = /obj/item/circuitboard/computer/slot_machine
	light_color = LIGHT_COLOR_BROWN
	unique_icon = TRUE
	var/money = 3000 //How much money it has CONSUMED
	var/plays = 0
	var/working = FALSE
	var/balance = 0 //How much money is in the machine, ready to be CONSUMED.
	var/jackpots = 0
	var/paymode = HOLOCHIP //toggles between HOLOCHIP/COIN, defined above
	var/cointype = /obj/item/coin/iron //default cointype
	var/list/reels = list(list("", "", "") = 0, list("", "", "") = 0, list("", "", "") = 0, list("", "", "") = 0, list("", "", "") = 0)
	var/list/symbols = list(SYMBOL_SEVEN = 1, "cherry" = 3, "banana" = 3, "strawberry" = 3, "grape" = 3, "diamond" = 3, "star" = 3, "watermelon" = 3, SYMBOL_WILD = 1, SYMBOL_SCATTER = 1)
	var/result_message = ""
	var/result_type = "" // "jackpot", "win", "small", "bonus", "lose"
	/// Currently selected bet amount
	var/bet_amount = 5
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

/obj/machinery/computer/slot_machine/Initialize(mapload)
	. = ..()
	jackpots = rand(1, 4) //false hope
	plays = rand(75, 200)

	INVOKE_ASYNC(src, PROC_REF(toggle_reel_spin), TRUE)//The reels won't spin unless we activate them

	var/list/reel = reels[1]
	for(var/i = 0, i < reel.len, i++) //Populate the reels.
		randomize_reels()

	INVOKE_ASYNC(src, PROC_REF(toggle_reel_spin), FALSE)

/obj/machinery/computer/slot_machine/Destroy()
	if(balance)
		give_payout(balance)
	return ..()

/obj/machinery/computer/slot_machine/process(delta_time)
	. = ..() //Sanity checks.
	if(!.)
		return .

	money += round(delta_time / 2) //SPESSH MAJICKS

/obj/machinery/computer/slot_machine/update_icon_state()
	if(machine_stat & NOPOWER)
		icon_state = "slots0"

	else if(machine_stat & BROKEN)
		icon_state = "slotsb"

	else if(working)
		icon_state = "slots2"

	else
		icon_state = "slots1"

/obj/machinery/computer/slot_machine/attackby(obj/item/I, mob/living/user, params)
	if(istype(I, /obj/item/coin))
		var/obj/item/coin/C = I
		if(paymode == COIN)
			if(prob(2))
				if(!user.transferItemToLoc(C, drop_location()))
					return
				C.throw_at(user, 3, 10)
				if(prob(10))
					balance = max(balance - bet_amount, 0)
				to_chat(user, "<span class='warning'>[src] spits your coin back out!</span>")

			else
				if(!user.temporarilyRemoveItemFromInventory(C))
					return
				to_chat(user, "<span class='notice'>You insert [C] into [src]'s slot!</span>")
				playsound(src, 'modular_bluemoon/sound/machines/slot-machine/money.ogg', 50, TRUE)
				balance += C.value
				qdel(C)
		else
			to_chat(user, "<span class='warning'>This machine is only accepting holochips!</span>")
	else if(istype(I, /obj/item/holochip))
		if(paymode == HOLOCHIP)
			var/obj/item/holochip/H = I
			if(!user.temporarilyRemoveItemFromInventory(H))
				return
			to_chat(user, "<span class='notice'>You insert [H.credits] holocredits into [src]'s slot!</span>")
			playsound(src, 'modular_bluemoon/sound/machines/slot-machine/money.ogg', 50, TRUE)
			balance += H.credits
			qdel(H)
		else
			to_chat(user, "<span class='warning'>This machine is only accepting coins!</span>")
	else if(I.tool_behaviour == TOOL_MULTITOOL)
		if(balance > 0)
			visible_message("<b>[src]</b> says, 'ERROR! Please empty the machine balance before altering paymode'") //Prevents converting coins into holocredits and vice versa
		else
			if(paymode == HOLOCHIP)
				paymode = COIN
				visible_message("<b>[src]</b> says, 'This machine now works with COINS!'")
			else
				paymode = HOLOCHIP
				visible_message("<b>[src]</b> says, 'This machine now works with HOLOCHIPS!'")
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
	data["money"] = money
	data["plays"] = plays
	data["jackpots"] = jackpots
	data["balance"] = balance
	data["working"] = working
	data["bet_amount"] = bet_amount
	data["result_message"] = result_message
	data["result_type"] = result_type
	data["paymode"] = paymode
	data["bonus_multiplier"] = bonus_multiplier
	data["bonus_active"] = bonus_active
	data["win_streak"] = win_streak
	data["session_winnings"] = session_winnings
	data["auto_spin"] = auto_spin
	data["auto_spin_remaining"] = auto_spin_remaining

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
		if("refund")
			if(balance > 0)
				give_payout(balance)
				balance = 0
				session_winnings = 0
				win_streak = 0
				auto_spin = FALSE
				auto_spin_remaining = 0
			. = TRUE
		if("set_bet")
			var/new_bet = text2num(params["amount"])
			if(new_bet && new_bet >= SPIN_PRICE_MIN && new_bet <= SPIN_PRICE_MAX)
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
					result_message = "Insufficient balance to gamble!"
					result_type = "lose"
					gamble_available = FALSE
					gamble_amount = 0
					. = TRUE
					return
				balance -= gamble_amount
				if(prob(25)) // 25% - strong house edge
					session_winnings += gamble_amount
					gamble_amount *= 2
					balance += gamble_amount
					result_message = "GAMBLE WIN! Prize: [gamble_amount] cr!"
					result_type = "win"
					playsound(src, 'modular_bluemoon/sound/machines/slot-machine/money.ogg', 60, TRUE)
				else
					session_winnings -= gamble_amount
					result_message = "GAMBLE LOST! -[gamble_amount] cr"
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
	money = max(rand(money - (200 * severity_ascending), money + (200 * severity_ascending)), 0)
	balance = max(rand(balance - (50 * severity_ascending), balance + (50 * severity_ascending)), 0)
	money -= max(0, give_payout(min(rand(-50, 100 * severity_ascending)), money)) //This starts at -50 because it shouldn't always dispense coins yo
	spin()

/obj/machinery/computer/slot_machine/proc/spin(mob/user)
	if(!can_spin(user))
		auto_spin = FALSE
		auto_spin_remaining = 0
		return

	var/the_name
	if(user)
		the_name = user.real_name
		visible_message("<span class='notice'>[user] pulls the lever and the slot machine starts spinning!</span>")
	else
		the_name = "Exaybachay"

	balance -= bet_amount
	money += bet_amount
	plays += 1
	working = TRUE
	result_message = ""
	result_type = ""
	bonus_multiplier = 1
	bonus_active = FALSE
	gamble_available = FALSE
	gamble_amount = 0
	near_miss = FALSE
	near_miss_message = ""
	show_confetti = FALSE
	active_lines = get_active_lines()
	winning_line = 0

	playsound(src, 'modular_bluemoon/sound/machines/slot-machine/wheel.ogg', 30, TRUE)
	toggle_reel_spin(1)
	update_icon()
	SStgui.update_uis(src)

	var/spin_loop = addtimer(CALLBACK(src, PROC_REF(do_spin)), 2, TIMER_LOOP|TIMER_STOPPABLE)

	addtimer(CALLBACK(src, PROC_REF(finish_spinning), spin_loop, user, the_name), SPIN_TIME - (REEL_DEACTIVATE_DELAY * reels.len))
	//WARNING: no sanity checking for user since it's not needed and would complicate things (machine should still spin even if user is gone), be wary of this if you're changing this code.

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
		to_chat(user, "<span class='warning'>The slot machine has no power!</span>")
		return FALSE
	if(machine_stat & BROKEN)
		to_chat(user, "<span class='warning'>The slot machine is broken!</span>")
		return FALSE
	if(working)
		to_chat(user, "<span class='warning'>You need to wait until the machine stops spinning before you can play again!</span>")
		return FALSE
	if(balance < bet_amount)
		to_chat(user, "<span class='warning'>Insufficient credits! You need at least [bet_amount] to play!</span>")
		return FALSE
	return TRUE

/obj/machinery/computer/slot_machine/proc/toggle_reel_spin(value, delay = 0) //value is 1 or 0 aka on or off
	for(var/list/reel in reels)
		reels[reel] = value
		sleep(delay)

/obj/machinery/computer/slot_machine/proc/randomize_reels()

	for(var/reel in reels)
		if(reels[reel])
			reel[3] = reel[2]
			reel[2] = reel[1]
			reel[1] = pick(symbols)

/obj/machinery/computer/slot_machine/proc/give_prizes(usrname, mob/user)
	var/list/line_result = get_lines()
	var/linelength = line_result[1]
	winning_line = line_result[2]
	var/bet_multiplier = bet_amount / SPIN_PRICE_MIN
	var/won_amount = 0

	near_miss = FALSE
	near_miss_message = ""
	show_confetti = FALSE
	gamble_available = FALSE
	gamble_amount = 0

	var/pair_count = check_pairs()
	if(pair_count >= 2 && linelength < 3 && prob(BONUS_CHANCE))
		bonus_multiplier = pick(2, 2, 2, 3, 3, 5)
		bonus_active = TRUE
		playsound(src, 'modular_bluemoon/sound/machines/slot-machine/bonus.ogg', 60, TRUE)

	var/jackpot_match = TRUE
	for(var/col = 1, col <= 5, col++)
		var/sym = reels[col][2]
		if(sym != SYMBOL_SEVEN && sym != SYMBOL_WILD)
			jackpot_match = FALSE
			break

	if(jackpot_match)
		winning_line = 1
		won_amount = money
		playsound(src, 'modular_bluemoon/sound/machines/slot-machine/jackpot.ogg', 80, TRUE)
		visible_message("<b>[src]</b> says, 'JACKPOT! You win [won_amount] credits!'")
		priority_announce("Congratulations to [user ? user.real_name : usrname] for winning the jackpot at the slot machine in [get_area(src)]!")
		jackpots += 1
		balance += money
		money = 0
		result_message = "🎉 MEGA JACKPOT! 7-7-7-7-7! +" + "[won_amount] cr!"
		result_type = "jackpot"
		win_streak++
		session_winnings += won_amount
		show_confetti = TRUE

	else if(linelength == 5)
		won_amount = round(BIG_PRIZE_BASE * bet_multiplier * bonus_multiplier)
		playsound(src, 'modular_bluemoon/sound/machines/slot-machine/money.ogg', 60, TRUE)
		visible_message("<b>[src]</b> says, 'Big Winner! You win [won_amount] credits!'")
		result_message = "BIG WINNER! +[won_amount] cr!"
		if(bonus_active)
			result_message += " (x[bonus_multiplier] BONUS!)"
		result_type = "win"
		win_streak++
		session_winnings += won_amount
		show_confetti = TRUE
		gamble_available = TRUE
		gamble_amount = won_amount
		give_money(won_amount)

	else if(linelength == 4)
		won_amount = round(SMALL_PRIZE_BASE * bet_multiplier * bonus_multiplier)
		playsound(src, 'modular_bluemoon/sound/machines/slot-machine/money.ogg', 50, TRUE)
		visible_message("<b>[src]</b> says, 'Winner! You win [won_amount] credits!'")
		result_message = "Winner! +[won_amount] cr!"
		if(bonus_active)
			result_message += " (x[bonus_multiplier] BONUS!)"
		result_type = "win"
		win_streak++
		session_winnings += won_amount
		gamble_available = TRUE
		gamble_amount = won_amount
		give_money(won_amount)

	else if(linelength == 3)
		var/free_spins = 1
		if(bonus_active)
			free_spins = free_spins * bonus_multiplier
		playsound(src, 'modular_bluemoon/sound/machines/slot-machine/bonus.ogg', 50, TRUE)
		to_chat(user, "<span class='notice'>You win [free_spins] free games!</span>")
		var/free_credits = bet_amount * free_spins
		balance += free_credits
		result_message = "[free_spins] Free Spins!"
		if(bonus_active)
			result_message += " (x[bonus_multiplier] BONUS!)"
		result_type = "small"
		win_streak++
		session_winnings += free_credits

	else if(bonus_active)
		playsound(src, 'modular_bluemoon/sound/machines/slot-machine/bonus.ogg', 60, TRUE)
		won_amount = round(bet_amount * bonus_multiplier)
		result_message = "BONUS x[bonus_multiplier]! +[won_amount] cr!"
		result_type = "bonus"
		win_streak++
		session_winnings += won_amount
		gamble_available = TRUE
		gamble_amount = won_amount
		give_money(won_amount)

	else
		result_message = "No luck... Try again!"
		result_type = "lose"
		win_streak = 0
		if(prob(1))
			playsound(src, 'modular_bluemoon/sound/machines/slot-machine/casino_fuck.ogg', 50, TRUE)

	var/scatter_count = count_scatters()
	if(scatter_count >= 3)
		var/scatter_win = round(SCATTER_WIN_BASE * bet_multiplier * scatter_count)
		won_amount += scatter_win
		if(result_type == "lose")
			result_message = "💫 SCATTER x[scatter_count]! +[scatter_win] cr!"
			result_type = "win"
			win_streak++
		else
			result_message += " +💫[scatter_win]!"
		session_winnings += scatter_win
		give_money(scatter_win)
		gamble_available = TRUE
		gamble_amount += scatter_win
		playsound(src, 'modular_bluemoon/sound/machines/slot-machine/bonus.ogg', 60, TRUE)

	if(result_type == "lose")
		var/seven_count = 0
		for(var/i = 1, i <= 5, i++)
			if(reels[i][2] == SYMBOL_SEVEN || reels[i][2] == SYMBOL_WILD)
				seven_count++
		if(seven_count >= 3)
			near_miss = TRUE
			near_miss_message = "SO CLOSE! [seven_count]/5 sevens!"
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
				near_miss_message = "Almost! One more symbol..."

	var/list/history_entry = list()
	history_entry["result"] = result_type
	history_entry["message"] = result_message
	history_entry["bet"] = bet_amount
	history_entry["won"] = won_amount
	spin_history += list(history_entry)
	if(spin_history.len > MAX_HISTORY)
		spin_history.Cut(1, 2)

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

/obj/machinery/computer/slot_machine/proc/get_active_lines()
	if(bet_amount >= 25)
		return 3
	if(bet_amount >= 10)
		return 2
	return 1

/obj/machinery/computer/slot_machine/proc/get_lines()
	var/static/list/payline_defs = list(\
		list(2, 2, 2, 2, 2),\
		list(1, 1, 1, 1, 1),\
		list(3, 3, 3, 3, 3),\
		list(1, 2, 3, 2, 1),\
		list(3, 2, 1, 2, 3)\
	)
	var/num_lines = get_active_lines()
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

/obj/machinery/computer/slot_machine/proc/give_money(amount)
	money = max(0, money - amount)
	balance += amount

/obj/machinery/computer/slot_machine/proc/give_payout(amount)
	if(paymode == HOLOCHIP)
		cointype = /obj/item/holochip
	else
		cointype = obj_flags & EMAGGED ? /obj/item/coin/iron : /obj/item/coin/silver

	if(!(obj_flags & EMAGGED))
		amount = dispense(amount, cointype, null, 0)

	else
		var/mob/living/target = locate() in range(2, src)

		amount = dispense(amount, cointype, target, 1)

	return amount

/obj/machinery/computer/slot_machine/proc/dispense(amount = 0, cointype = /obj/item/coin/silver, mob/living/target, throwit = 0)
	if(paymode == HOLOCHIP)
		var/obj/item/holochip/H = new /obj/item/holochip(loc,amount)

		if(throwit && target)
			H.throw_at(target, 3, 10)
	else
		var/value = GLOB.coin_values[cointype]
		if(value <= 0)
			CRASH("Coin value of zero, refusing to payout in dispenser")
		while(amount >= value)
			var/obj/item/coin/C = new cointype(loc) //DOUBLE THE PAIN
			amount -= value
			if(throwit && target)
				C.throw_at(target, 3, 10)
			else
				random_step(C, 2, 40)

	return amount

#undef SYMBOL_SEVEN
#undef SPIN_TIME
#undef JACKPOT
#undef BIG_PRIZE_BASE
#undef SMALL_PRIZE_BASE
#undef SPIN_PRICE_MIN
#undef SPIN_PRICE_MAX
#undef HOLOCHIP
#undef COIN
#undef MAX_HISTORY
#undef BONUS_CHANCE
#undef SYMBOL_WILD
#undef SYMBOL_SCATTER
#undef SCATTER_WIN_BASE
