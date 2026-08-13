/datum/ambition_objective
	var/datum/mind/owner = null			//владелец амбиции
	var/completed = 0					//завершение амбиции для конца раунда
	var/description = "Пустая амбиция ((перешлите это разработчику))"
	var/chance_generic_ambition = 40	//шанс выпадения ОБЩЕЙ амбиции
	var/chance_other_departament_ambition = 30	//шанс выпадения амбиции чужого департамента

/datum/ambition_objective/New(datum/mind/new_owner)
	owner = new_owner
	owner.ambition_objectives += src

/datum/ambition_objective/proc/get_random_ambition()
	var/result

	//Шанс выпадения общей амбиции или амбиции отдела
	if(prob(chance_generic_ambition))
		result = pick_list("ambitions/generic.json", "Common")
	else
		result = get_job_departament_ambition()
		if (!result)
			result = pick_list("ambitions/generic.json", "Common")

	return ambition_code(result)

/datum/ambition_objective/proc/get_job_departament_ambition()
	var/result

	//Шанс выпадения общей роли из отдела
	var/job = owner.assigned_role
	if(prob(chance_generic_ambition))
		job = "Common"

	//Проверяем работы не в позициях и вынесенные в отдельный файл
	switch(owner.assigned_role)
		if(LAWYER)
			return pick_list("ambitions/law.json", job)

		if(BRDIGEOFF)
			return pick_list("ambitions/representative.json", job)

	//Сначала выдаем амбиции силиконам, чтобы они не получили общих амбиций
	if(owner.assigned_role in GLOB.nonhuman_positions)
		return pick_list("ambitions/nonhuman.json", owner.assigned_role)

	//Проверяем работы вынесенные в позиции
	if(owner.assigned_role in (GLOB.civilian_positions))
		return pick_list("ambitions/generic.json", "Common")

	if(owner.assigned_role in GLOB.command_positions)
		//шанс получить за главу работу одного из своих отделов
		if (prob(chance_other_departament_ambition))
			switch(owner.assigned_role)
				if(HOP)
					if (prob(50))
						job = pick(GLOB.civilian_positions)
						result = pick_list("ambitions/support.json", job)
					else
						job = pick(GLOB.supply_positions)
						result = pick_list("ambitions/supply.json", job)
				if(HOS)
					job = pick(GLOB.security_positions)
					result = pick_list("ambitions/security.json", job)
				if(CHIEF)
					job = pick(GLOB.engineering_positions)
					result = pick_list("ambitions/engineering.json", job)
				if(RD_JF)
					job = pick(GLOB.science_positions)
					result = pick_list("ambitions/science.json", job)
				if(CMO_JF)
					job = pick(GLOB.medical_positions)
					result = pick_list("ambitions/medical.json", job)
		if (!result)
			result = pick_list("ambitions/command.json", job)
		return result

	if(owner.assigned_role in (GLOB.civilian_positions))
		return pick_list("ambitions/support.json", job)

	if(owner.assigned_role in GLOB.law_positions)
		return pick_list("ambitions/security.json", job)

	if(owner.assigned_role in GLOB.engineering_positions)
		return pick_list("ambitions/engineering.json", job)

	if(owner.assigned_role in GLOB.medical_positions)
		return pick_list("ambitions/medical.json", job)

	if(owner.assigned_role in GLOB.science_positions)
		return pick_list("ambitions/science.json", job)

	if(owner.assigned_role in GLOB.supply_positions)
		if(owner.assigned_role == MINER)
			return pick_list("ambitions/supply.json", "Common")
		return pick_list("ambitions/supply.json", job)

	if(owner.assigned_role in (GLOB.security_positions))
		if(owner.assigned_role == BRIGDOC && (prob(chance_other_departament_ambition)))	//шанс что бригмедик возьмёт амбицию мед. отдела.
			job = pick(GLOB.medical_positions)
			return pick_list("ambitions/medical.json", job)
		return pick_list("ambitions/security.json", job)

	return result

/datum/ambition_objective/proc/ambition_code(text)
	var/list/choose_list = list()		//список повторов рандома у амбиции !(Приготовлю сегодня ПИВО и ПИВО)

	var/list/random_codes = list(
		"random_crew",
		"random_departament",
		"random_departament_crew",
		"random_pet",
		"random_food",
		"random_drink",
		"random_holiday"
	)

	var/list/items = splittext(text, "\[")
	text = ""
	for(var/item in items)
		for (var/code in random_codes)
			var/choosen = random_choose(code, choose_list)
			choose_list.Add(choosen)
			item = replacetextEx_char(item, "[code]\]", choosen)
		text += item

	return uppertext(copytext_char(text, 1, 2)) + copytext_char(text, 2)	//переводим первым символ в верхний регистр

//выдача рандома, проверка на повторы
/datum/ambition_objective/proc/random_choose(list_for_pick, list/choose_list)
	if(list_for_pick == "random_crew")
		var/list/candidates = list()
		for(var/mob/M in GLOB.player_list)
			if(!M?.mind || QDELETED(M))
				continue
			if(isnewplayer(M))
				continue
			if(M.mind == owner)
				continue
			var/crew_name = M.real_name
			if(!crew_name)
				continue
			candidates |= crew_name
		if(!length(candidates))
			return pick("Gandalf the Grey",
		"Gandalf the White",
		"Monty Python and the Holy Grail's Black Knight",
		"Benito Mussolini",
		"the Blue Meanie",
		"Cowboy Curtis",
		"Jambi the Genie",
		"Robocop",
		"the Terminator",
		"Captain Kirk",
		"Darth Vader",
		"Lo-pan",
		"Superman",
		"every single Power Ranger",
		"Bill S. Preston",
		"Theodore Logan",
		"Spock",
		"The Rock",
		"Doc Ock",
		"Hulk Hogan")
		var/chosen = pick(candidates)
		var/failsafe = 0
		while(choose_list && (chosen in choose_list) && length(candidates) > 1 && failsafe < 20)
			chosen = pick(candidates)
			failsafe++
		return chosen

	var/picked = pick_list("ambitions/randoms.json", list_for_pick)

	//избавляемся от повтора
	var/failsafe = 0
	while(choose_list && (picked in choose_list))
		picked = pick_list("ambitions/randoms.json", list_for_pick)
		if(failsafe > 10)
			break
		failsafe++

	return picked
