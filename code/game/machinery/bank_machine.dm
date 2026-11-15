/obj/machinery/computer/bank_machine
	name = "bank machine"
	idle_sleeps = FALSE // own periodic work in process(); must not doze off via the parent typing-indicator path
	desc = "Хранилище бюджета снабжения. Наличные и голочипы, вложенные в него, зачисляются в бюджет снабжения. Его можно и выкачать в голочипы, но хранилище при этом поднимает тревогу по общей частоте."
	icon = 'icons/obj/computer.dmi'
	icon_state = "computer"
	icon_screen = "vault"
	icon_keyboard = "security_key"
	idle_power_usage = 100

	var/siphoning = FALSE
	var/next_warning = 0
	var/obj/item/radio/radio
	var/radio_channel = RADIO_CHANNEL_COMMON
	var/minimum_time_between_warnings = 400
	var/syphoning_credits = 0

/obj/machinery/computer/bank_machine/Initialize(mapload)
	. = ..()
	radio = new(src)
	radio.subspace_transmission = TRUE
	radio.canhear_range = 0
	radio.recalculateChannels()

/obj/machinery/computer/bank_machine/Destroy()
	QDEL_NULL(radio)
	. = ..()

/obj/machinery/computer/bank_machine/attackby(obj/item/I, mob/user)
	var/value = 0
	if(istype(I, /obj/item/stack/spacecash))
		var/obj/item/stack/spacecash/C = I
		value = C.value * C.amount
	else if(istype(I, /obj/item/holochip))
		var/obj/item/holochip/H = I
		value = H.credits
	if(value)
		var/datum/bank_account/D = SSeconomy.get_dep_account(ACCOUNT_CAR)
		if(D && SSeconomy.move(SSeconomy.cash_account, D, value, ECON_CASH_IN, user))
			to_chat(user, span_notice("Вы вкладываете [I]. В бюджете снабжения теперь [D.account_balance] кр."))
		qdel(I)
		return
	return ..()

/obj/machinery/computer/bank_machine/process()
	..()
	if(siphoning)
		if (machine_stat & (BROKEN|NOPOWER))
			say("Нет питания. Выкачка остановлена.")
			end_syphon()
		var/datum/bank_account/D = SSeconomy.get_dep_account(ACCOUNT_CAR)
		if(!D.has_money(200))
			say("Бюджет снабжения пуст. Выкачка остановлена.")
			end_syphon()
			return

		playsound(src, 'sound/items/poster_being_created.ogg', 100, TRUE)
		if(!SSeconomy.move(D, SSeconomy.cash_account, 200, ECON_CASH_OUT))
			say("Бюджет снабжения пуст. Выкачка остановлена.")
			end_syphon()
			return
		syphoning_credits += 200
		if(next_warning < world.time && prob(15))
			var/area/A = get_area(loc)
			var/message = "Несанкционированная выкачка кредитов из хранилища: [A.map_name]!"
			radio.talk_into(src, message, radio_channel)
			next_warning = world.time + minimum_time_between_warnings

/obj/machinery/computer/bank_machine/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "BankMachine", name)
		ui.open()

/obj/machinery/computer/bank_machine/ui_data(mob/user)
	var/list/data = list()
	var/datum/bank_account/D = SSeconomy.get_dep_account(ACCOUNT_CAR)

	if(D)
		data["current_balance"] = D.account_balance
	else
		data["current_balance"] = 0
	data["siphoning"] = siphoning
	data["station_name"] = station_name()

	return data

/obj/machinery/computer/bank_machine/ui_act(action, params)
	if(..())
		return

	switch(action)
		if("siphon")
			say("Начата выкачка бюджета снабжения!")
			siphoning = TRUE
			. = TRUE
		if("halt")
			say("Выкачка бюджета снабжения остановлена.")
			end_syphon()
			. = TRUE

/obj/machinery/computer/bank_machine/proc/end_syphon()
	siphoning = FALSE
	new /obj/item/holochip(drop_location(), syphoning_credits) //get the loot
	syphoning_credits = 0
