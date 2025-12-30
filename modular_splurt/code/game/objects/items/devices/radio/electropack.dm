#define MIN_BOUGHT_TIME 20 // минуты
#define MAX_BOUGHT_TIME 20 // минуты

/obj/item/electropack/shockcollar/security
	name = "security shock collar"
	desc = "A reinforced security collar. It has two electrodes that press against the neck, for disobedient pets."
	icon = 'modular_splurt/icons/obj/clothing/neck/cit_neck.dmi'
	mob_overlay_icon = 'modular_splurt/icons/mob/clothing/neck.dmi'
	icon_state = "shockseccollar"
	item_state = "shockseccollar"

/obj/item/electropack/Topic(href, href_list)
	var/mob/living/carbon/C = usr
	if(usr.stat || usr.restrained() || C.back == src)
		return

	if(!usr.canUseTopic(src, BE_CLOSE))
		usr << browse(null, "window=radio")
		onclose(usr, "radio")
		return

	if(href_list["set"])
		if(href_list["set"] == "freq")
			var/new_freq = input(usr, "Input a new receiving frequency", "Electropack Frequency", format_frequency(frequency)) as num|null
			if(!usr.canUseTopic(src, BE_CLOSE))
				return
			new_freq = unformat_frequency(new_freq)
			new_freq = sanitize_frequency(new_freq, TRUE)
			set_frequency(new_freq)

		if(href_list["set"] == "code")
			var/new_code = input(usr, "Input a new receiving code", "Electropack Code", code) as num|null
			if(!usr.canUseTopic(src, BE_CLOSE))
				return
			new_code = round(new_code)
			new_code = clamp(new_code, 1, 100)
			code = new_code

		if(href_list["set"] == "power")
			if(!usr.canUseTopic(src, BE_CLOSE))
				return
			on = !(on)
			icon_state = "electropack[on]"

	if(usr)
		attack_self(usr)

	return

/obj/item/electropack/shockcollar/slave
	name = "slave collar"
	desc = "A reinforced metal collar. This one has a shock element and tracker installed."

	var/price // The ransom amount
	var/bought = FALSE // Has the station paid the ransom
	var/station_rank
	var/nextPriceChange // Last time the price was changed
	var/nextRansomChange // Last time the ransom was paid / cancelled
	var/nextRecruitChance = INFINITY // Next time the slave can get the option to join the slavers
	var/nextboughtChance = 0 // Next time the station can bought slave
	shockStrength = 400
	shockCooldown = 20 SECONDS
	code = -1
	frequency = -1
	verb_say = "states"

/obj/item/electropack/shockcollar/slave/Initialize()
	GLOB.tracked_slaves += src
	. = ..()

/obj/item/electropack/shockcollar/slave/Destroy()
	visible_message("<span class='notice'>The [src] detaches from [src.loc]'s neck.</span>", \
		"<span class='notice'>The [src] detaches from your neck.</span>")
	playsound(get_turf(src.loc), 'sound/machines/terminal_eject_disc.ogg', 50, 1)

	GLOB.tracked_slaves -= src
	. = ..()

/obj/item/electropack/shockcollar/slave/mob_can_equip(mob/living/M, mob/living/equipper, slot, disable_warning, bypass_equip_delay_self, clothing_check, list/return_warning)
	if(!M)
		return ..()

	var/datum/antagonist/slaver/S = locate(/datum/antagonist/slaver) in M?.mind.antag_datums
	if(S) // Слейвер
		return FALSE

	// Надевает сам на себя
	if(!equipper)
		//Раз сам на себя надевает, префы не проверяем
		if(!do_after(M, 3 SECONDS, M)) // Защита от миссклика по кнопке одеть
			return FALSE
		else
			return ..()
	else
		// Проверяем префы
		if(M?.client?.prefs.nonconpref == "No" || M?.client?.prefs.erppref == "No")
			src.say("Операция отклонена. Цель помечена как неприкосновенная.")
			playsound(src, 'sound/machines/buzz-sigh.ogg', 80, FALSE)
			return FALSE
		else
			return ..()

// Don't let user change frequency.
/obj/item/electropack/shockcollar/slave/attack_self(mob/living/user)
	return

// Once equipped, do not let anyone take it off
/obj/item/electropack/shockcollar/slave/equipped(mob/user, slot)
	. = ..()

	if(isliving(user))
		var/mob/living/M = user
		if(slot == ITEM_SLOT_NECK)
			playsound(get_turf(M), 'sound/machines/triple_beep.ogg', 50, 1)
			ADD_TRAIT(src, TRAIT_NODROP, CLOTHING_TRAIT)

			var/max_ransom = SLAVER_RANSOM_STANDARD
			var/max_ransom_percent = SLAVER_RANSOM_STANDARD_PERCENT
			var/automatic_ransom = GLOB.slavers_ransom_values[M.job]
			if(automatic_ransom)
				max_ransom = automatic_ransom["maxPrice"]
				max_ransom_percent = automatic_ransom["percent"]

			station_rank = M.job

			var/datum/bank_account/bank = SSeconomy.get_dep_account(ACCOUNT_CAR)
			if(!bank)
				setPrice(max_ransom)
			setPrice(max(1, min(max_ransom, bank.account_balance*max_ransom_percent)))

/obj/item/electropack/shockcollar/slave/proc/setPrice(newPrice)
	var/mob/living/M = loc

	var/slaveJobText = ""
	if (station_rank)
		slaveJobText = " ([station_rank])"

	var/is_extended = GLOB.master_mode == ROUNDTYPE_EXTENDED
	var/announceMessage = "Мы позаимствовали у вас [M.real_name][slaveJobText] на добровольно-принудительный отпуск. \
	Отправьте нам [newPrice] кредитов и мы вернём вашего сотрудника в течении пятнадцати минут! Вам же... нужны работники?"

	if(price) // If price has already been set once, we are just changing it
		announceMessage = "Сумма выкупа за [M.real_name] [newPrice > price ? "увеличилась" : "уменьшилась"] до [newPrice] кредитов."
	else
		nextboughtChance = is_extended ? world.time + (rand(MIN_BOUGHT_TIME, MAX_BOUGHT_TIME) MINUTES) : 0 // В эксту во избежание моментальных выкупов, ставим задержку
		nextRecruitChance = (nextboughtChance ? nextboughtChance : world.time) + 5 MINUTES // Our first time setting the price, now we begin the countdown for when this slave can be recruited

	price = round(newPrice)
	nextPriceChange = world.time + 5 MINUTES // Cannot be changed again for 5 minutes
	priority_announce(announceMessage, sender_override = GLOB.slavers_team_name)

/obj/item/electropack/shockcollar/slave/proc/setBought(isBought)
	bought = isBought
	nextRansomChange = world.time + 5 MINUTES // Cannot be changed again for 5 minutes

#undef MIN_BOUGHT_TIME
#undef MAX_BOUGHT_TIME
