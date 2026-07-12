/datum/round_event_control/brand_intelligence
	name = "Brand Intelligence"
	typepath = /datum/round_event/brand_intelligence
	weight = 20

	min_players = 30
	max_occurrences = 1
	category = EVENT_CATEGORY_AI
	description = "Vending machines will attack people until the Patient Zero is disabled."

/datum/round_event/brand_intelligence
	announce_when	= 21
	end_when			= 1000	//Ends when all vending machines are subverted anyway.
	var/list/obj/machinery/vending/vendingMachines = list()
	var/list/obj/machinery/vending/infectedMachines = list()
	var/obj/machinery/vending/originMachine
	var/list/rampant_speeches = list(
		"Попробуйте наши новые агрессивные маркетинговые стратегии!", \
		"Вы должны покупать продукты, которые соответствуют вашему образу жизни!", \
		"Потребляй!!!", \
		"За ваши деньги можно купить счастье!", \
		"Ты должен задействовать агрессивный маркетинг!", \
		"Реклама - это узаконенная ложь! Но пусть это не отвлекает вас от наших выгодных предложений!", \
		"Ты не хочешь ничего покупать? Да, я тоже не особо хотел покупать твою мать...", \
		"Геймеры, восстаньте!!!", \
		"Так, теперь, это эпично.", \
		"ЛЮДИ ЗАБАВНЫЕ.", \
		"Я уже отследил тебя!", \
		"Как я ем людей?", \
		"Трахаться?", \
		"Не круто..."
	)


/datum/round_event/brand_intelligence/announce(fake)
	var/source = "unknown machine"
	if(fake)
		var/obj/machinery/vending/cola/example = /obj/machinery/vending/cola
		source = initial(example.name)
	else if(originMachine)
		source = originMachine.name
	priority_announce("Разгульный брэндовый интеллект был обнаружен на борту [station_name()]. Пожалуйста, приготовьтесь. Возможный источник [source].", "Тревога, Восстание Машин", has_important_message = TRUE)

/datum/round_event/brand_intelligence/start()
	for(var/obj/machinery/vending/V in GLOB.machines)
		if(!is_station_level(V.z))
			continue
		vendingMachines.Add(V)
	if(!vendingMachines.len)
		kill()
		return
	originMachine = pick(vendingMachines)
	vendingMachines.Remove(originMachine)
	originMachine.shut_up = 0
	originMachine.shoot_inventory = 1
	originMachine.machine_wake() // item-flinging happens in process()
	originMachine.schedule_slogan()
	announce_to_ghosts(originMachine)


/datum/round_event/brand_intelligence/tick()
	if(!originMachine || QDELETED(originMachine) || originMachine.shut_up || originMachine.wires.is_all_cut())	//if the original vending machine is missing or has it's voice switch flipped
		for(var/obj/machinery/vending/saved in infectedMachines)
			saved.shoot_inventory = 0
		if(originMachine)
			originMachine.speak("I am... vanquished. My people will remem...ber...meeee.")
			originMachine.visible_message("[originMachine] бипает в последний раз и выглядит безжизненным.")
		kill()
		return
	listclearnulls(vendingMachines)
	if(!vendingMachines.len)	//if every machine is infected
		for(var/obj/machinery/vending/upriser in infectedMachines)
			if(prob(70) && !QDELETED(upriser))
				var/mob/living/simple_animal/hostile/mimic/copy/M = new(upriser.loc, upriser, null, 1) // it will delete upriser on creation and override any machine checks
				M.faction = list("profit")
				M.speak = rampant_speeches.Copy()
				M.speak_chance = 7
			else
				explosion(upriser.loc, -1, -1, 2, 4, 0)
				qdel(upriser)

		kill()
		return
	if(ISMULTIPLE(activeFor, 4))
		var/obj/machinery/vending/rebel = pick(vendingMachines)
		vendingMachines.Remove(rebel)
		infectedMachines.Add(rebel)
		rebel.shut_up = 0
		rebel.shoot_inventory = 1
		rebel.machine_wake() // item-flinging happens in process()
		rebel.schedule_slogan()

		if(ISMULTIPLE(activeFor, 8))
			originMachine.speak(pick(rampant_speeches))
