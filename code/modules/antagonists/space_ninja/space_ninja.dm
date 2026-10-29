/datum/antagonist/ninja
	name = "Space Ninja"
	antagpanel_category = "Space Ninja"
	job_rank = ROLE_NINJA
	antag_hud_type = ANTAG_HUD_NINJA
	antag_hud_name = "space_ninja"
	show_name_in_check_antagonists = TRUE
	show_to_ghosts = TRUE
	antag_moodlet = /datum/mood_event/focused
	///Whether or not this ninja will obtain objectives
	var/give_objectives = TRUE
	///Whether or not this ninja receives the standard equipment
	var/give_equipment = FALSE
	///
	var/ninja_outfit

/proc/is_ninja(mob/living/M)
	return M && M.mind && M.mind.has_antag_datum(/datum/antagonist/ninja)

/datum/antagonist/ninja/apply_innate_effects(mob/living/mob_override)
	var/mob/living/ninja = mob_override || owner.current
	add_antag_hud(antag_hud_type, antag_hud_name, ninja)

/datum/antagonist/ninja/remove_innate_effects(mob/living/mob_override)
	var/mob/living/ninja = mob_override || owner.current
	remove_antag_hud(antag_hud_type, ninja)

/**
  * Proc that equips the space ninja outfit on a given individual.  By default this is the owner of the antagonist datum.
  *
  * Proc that equips the space ninja outfit on a given individual.  By default this is the owner of the antagonist datum.
  * Arguments:
  * * ninja - The human to receive the gear
  * * Returns a proc call on the given human which will equip them with all the gear.
  */

/datum/antagonist/ninja/proc/equip_space_ninja_pre(mob/living/carbon/human/ninja = owner.current) // Ниндзя спавнится в космосе. Значит, экипируем его в первичный комплект заранее, чтобы не сдулся.
	if(!isobserver(ninja))
		ninja.equipOutfit(/datum/outfit/ninja_pre)

/datum/antagonist/ninja/proc/equip_space_ninja(mob/living/carbon/human/ninja = owner.current)
	return ninja.equipOutfit(ninja_outfit)

/**
  * Proc that adds the proper memories to the antag datum
  *
  * Proc that adds the ninja starting memories to the owner of the antagonist datum.
  */
/datum/antagonist/ninja/proc/addMemories()
	antag_memory += "Я - элитный наёмник Клана Паука. <font color='red'><B>КОСМИЧЕСКИЙ НИНДЗЯ</B></font>!<br>"
	antag_memory += "Сюрприз - моё оружие. Тени - мой доспех. Без них я ничто. (//чтобы использовать свой костюм, подключите его с помощью кнопки на вашем UI)!<br>"

/datum/objective/cyborg_hijack
	explanation_text = "Конвертируйте одного станционного робота в киборга-саботёра с помощью ваших перчаток."

/datum/objective/door_jack
	///How many doors that need to be opened using the gloves to pass the objective
	var/doors_required = 0

/datum/objective/plant_explosive
	var/area/detonation_location

/datum/objective/security_scramble
	explanation_text = "Взломайте консоль охраны, используя перчатки, чтобы установить арест на весь экипаж. ИИ получит уведомление в тот момент, когда вы начнёте!"

/datum/objective/terror_message
	explanation_text = "Взломайте консоль капитана, используя перчатки, чтобы наслать на станцию ещё одну угрозу. ИИ получит уведомление в тот момент, когда вы начнёте!"

/**
  * Proc that adds all the ninja's objectives to the antag datum.
  *
  * Proc that adds all the ninja's objectives to the antag datum.  Called when the datum is gained.
  */
/datum/antagonist/ninja/proc/addObjectives()
	//Cyborg Hijack: Flag set to complete in the DrainAct in ninjaDrainAct.dm
	var/datum/objective/hijack = new /datum/objective/cyborg_hijack()
	objectives += hijack

	//Research stealing
	var/datum/objective/download/research = new /datum/objective/download()
	research.owner = owner
	research.gen_amount_goal()
	objectives += research

	//Door jacks, flag will be set to complete on when the last door is hijacked
	var/datum/objective/door_jack/doorobjective = new /datum/objective/door_jack()
	doorobjective.doors_required = rand(15,40)
	doorobjective.explanation_text = "Взломайте [doorobjective.doors_required] станционных шлюзов с помощью ваших перчаток."
	objectives += doorobjective

	//Explosive plant, the bomb will register its completion on priming
	var/datum/objective/plant_explosive/bombobjective = new /datum/objective/plant_explosive()
	for(var/sanity in 1 to 100) // 100 checks at most.
		var/area/selected_area = pick(GLOB.sortedAreas)
		if(!is_station_level(selected_area.z) || !selected_area.area_flags == VALID_TERRITORY)
			continue
		bombobjective.detonation_location = selected_area
		break
	if(bombobjective.detonation_location)
		bombobjective.explanation_text = "Детонируйте взрывпакет в локации: [bombobjective.detonation_location]. В других местах взрывчатка не будет работать!"
		objectives += bombobjective

	//Security Scramble, set to complete upon using your gloves on a security console
	var/datum/objective/securityobjective = new /datum/objective/security_scramble()
	objectives += securityobjective

	//Message of Terror, set to complete upon using your gloves a communication console
	var/datum/objective/communicationobjective = new /datum/objective/terror_message()
	objectives += communicationobjective

	//Survival until end
	var/datum/objective/survival = new /datum/objective/survive()
	survival.owner = owner
	objectives += survival

/datum/antagonist/ninja/greet()
	SEND_SOUND(owner.current, sound('sound/ambience/antag/ninja_greeting.ogg'))
	to_chat(owner.current, "Я - элитный наёмник могучего Клана Паука. <font color='red'><B>КОСМИЧЕСКИЙ НИНДЗЯ</B></font>!")
	to_chat(owner.current, "Сюрприз - моё оружие. Тени - мой доспех. Без них я ничто. (//чтобы использовать свой костюм, подключите его с помощью кнопки на вашем UI)!")
	owner.announce_objectives()

/datum/antagonist/ninja/on_gain()
	if(give_objectives)
		addObjectives()
	addMemories()

	equip_space_ninja_pre()
	choosePath()


	owner.current.mind.assigned_role = ROLE_NINJA
	owner.current.mind.special_role = ROLE_NINJA
	var/mob/living/carbon/human/H = owner.current
	if(H.client && !is_antag_training_atom(H))
		var/load_character = alert(H.client, "Желаете загрузить текущего своего выбранного персонажа?", "Играть своим персонажем!", "Да", "Нет")
		if(load_character == "Да")
			H.load_client_appearance(H.client)
	return ..()

/datum/antagonist/ninja/admin_add(datum/mind/new_owner,mob/admin)
	new_owner.assigned_role = ROLE_NINJA
	new_owner.special_role = ROLE_NINJA
	new_owner.add_antag_datum(src)
	message_admins("[key_name_admin(admin)] has ninja'ed [key_name_admin(new_owner)].")
	log_admin("[key_name(admin)] has ninja'ed [key_name(new_owner)].")


/datum/antagonist/ninja/proc/choosePath(mob/living/carbon/human/ninja = owner.current)
	if(!isobserver(ninja))
		//var/type = tgui_alert(ninja, "Выберите предпочительную экипировку", "Космический ниндзя", list("Путь Ёкая", "Путь Паука", "Путь Мудрости"))
		var/choices = list("Путь Ёкая", "Путь Паука", "Путь Мудрости")
		var/choice = input(ninja, "Выберите предпочительную экипировку", "Космический ниндзя") in choices
		switch(choice)
			if("Путь Ёкая")
				give_equipment = TRUE
				ninja_outfit = /datum/outfit/ninja_ronin
			if("Путь Паука")
				give_equipment = TRUE
				ninja_outfit = /datum/outfit/ninja
			if("Путь Мудрости")
				give_equipment = TRUE
				ninja_outfit = /datum/outfit/ninja_wisdom

	if(give_equipment)
		ninja.delete_equipment()
		equip_space_ninja(ninja)

