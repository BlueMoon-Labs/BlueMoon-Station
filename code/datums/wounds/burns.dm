

// TODO: well, a lot really, but specifically I want to add potential fusing of clothing/equipment on the affected area, and limb infections, though those may go in body part code
/datum/wound/burn
	a_or_from = "from"
	wound_type = WOUND_BURN
	processes = TRUE
	sound_effect = 'sound/effects/wounds/sizzle1.ogg'
	wound_flags = (FLESH_WOUND | ACCEPTS_GAUZE)

	treatable_by = list(/obj/item/stack/medical/ointment, /obj/item/stack/medical/mesh) // sterilizer and alcohol will require reagent treatments, coming soon

		// Flesh damage vars
	/// How much damage to our flesh we currently have. Once both this and infestation reach 0, the wound is considered healed
	var/flesh_damage = 5
	/// Our current counter for how much flesh regeneration we have stacked from regenerative mesh/synthflesh/whatever, decrements each tick and lowers flesh_damage
	var/flesh_healing = 0

		// Infestation vars (only for severe and critical)
	/// How quickly infection breeds on this burn if we don't have disinfectant
	var/infestation_rate = 0
	/// Our current level of infection
	var/infestation = 0
	/// Our current level of sanitization/anti-infection, from disinfectants/alcohol/UV lights. While positive, totally pauses and slowly reverses infestation effects each tick
	var/sanitization = 0

	/// Once we reach infestation beyond WOUND_INFESTATION_SEPSIS, we get this many warnings before the limb is completely paralyzed (you'd have to ignore a really bad burn for a really long time for this to happen)
	var/strikes_to_lose_limb = 3


/datum/wound/burn/handle_process()
	. = ..()
	if(strikes_to_lose_limb == 0)
		victim.adjustToxLoss(0.5)
		if(prob(1))
			victim.visible_message("<span class='danger'>Инфекция на [limb.ru_name_v] персонажа [victim] тошнотворно пузырится!</span>", "<span class='warning'>Вы чувствуете, как инфекция на вашей - [limb.ru_name_v] пульсирует и распространяется по вашим тканям!</span>")
		return

	if(victim.reagents)
		if(victim.reagents.has_reagent(/datum/reagent/medicine/spaceacillin))
			sanitization += 0.9
		if(victim.reagents.has_reagent(/datum/reagent/space_cleaner/sterilizine/))
			sanitization += 0.9
		if(victim.reagents.has_reagent(/datum/reagent/medicine/mine_salve))
			sanitization += 0.3
			flesh_healing += 0.5

	if(limb.current_gauze)
		limb.seep_gauze(WOUND_BURN_SANITIZATION_RATE)

	if(flesh_healing > 0)
		var/bandage_factor = (limb.current_gauze ? limb.current_gauze.splint_factor : 1)
		flesh_damage = max(0, flesh_damage - 1)
		flesh_healing = max(0, flesh_healing - bandage_factor) // good bandages multiply the length of flesh healing

	// here's the check to see if we're cleared up
	if((flesh_damage <= 0) && (infestation <= 1))
		to_chat(victim, "<span class='green'>Вы удалили инфекцию, что находилась на [limb.ru_name_v]!</span>")
		qdel(src)
		return

	// sanitization is checked after the clearing check but before the rest, because we freeze the effects of infection while we have sanitization
	if(sanitization > 0)
		var/bandage_factor = (limb.current_gauze ? limb.current_gauze.splint_factor : 1)
		infestation = max(0, infestation - WOUND_BURN_SANITIZATION_RATE)
		sanitization = max(0, sanitization - (WOUND_BURN_SANITIZATION_RATE * bandage_factor))
		return

	infestation += infestation_rate

	switch(infestation)
		if(0 to WOUND_INFECTION_MODERATE)
		if(WOUND_INFECTION_MODERATE to WOUND_INFECTION_SEVERE)
			if(prob(30))
				victim.adjustToxLoss(0.2)
				if(prob(6))
					to_chat(victim, "<span class='warning'>Ваша [limb.ru_name] сочится гноем и волдырями...</span>")
		if(WOUND_INFECTION_SEVERE to WOUND_INFECTION_CRITICAL)
			if(!disabling && prob(2))
				to_chat(victim, "<span class='warning'><b>Ваша [limb.ru_name] парализуется, пока вы пытаетесь бороться с инфекцией!</b></span>")
				disabling = TRUE
			else if(disabling && prob(8))
				to_chat(victim, "<span class='notice'>Ваша [limb.ru_name] все ещё в ужасном состоянии, хоть вы и вернули контроль над ней!</span>")
				disabling = FALSE
			else if(prob(20))
				victim.adjustToxLoss(0.5)
		if(WOUND_INFECTION_CRITICAL to WOUND_INFECTION_SEPTIC)
			if(!disabling && prob(3))
				to_chat(victim, "<span class='warning'><b>[limb.ru_name] внезапно теряет всякую чувствительность из-за гноящейся инфекции!</b></span>")
				disabling = TRUE
			else if(disabling && prob(3))
				to_chat(victim, "<span class='notice'>Ваша [limb.ru_name] едва снова ощущается. Вам придется напрячься, чтобы сохранить моторику!</span>")
				disabling = FALSE
			else if(prob(1))
				to_chat(victim, "<span class='warning'>Вы задумаетесь о жизни без вашей конечности...</span>")
				victim.adjustToxLoss(0.75)
			else if(prob(4))
				victim.adjustToxLoss(1)
		if(WOUND_INFECTION_SEPTIC to INFINITY)
			if(prob(infestation))
				switch(strikes_to_lose_limb)
					if(3 to INFINITY)
						to_chat(victim, "<span class='deadsay'>Кожа на вашей [limb.ru_name_v] буквально сползает, вы чувствуете себя ужасно!</span>")
					if(2)
						to_chat(victim, "<span class='deadsay'><b>Инфекция на вашей [limb.ru_name_v] обильно сочится, это отвратительно!</b></span>")
					if(1)
						to_chat(victim, "<span class='deadsay'><b>Ваша [limb.ru_name] целиком захвачена инфекций!</b></span>")
					if(0)
						to_chat(victim, "<span class='deadsay'><b>Последние нервные окончания на вашей [limb.ru_name_v] - затухают, инфекция целиком парализует сустав.</b></span>")
						threshold_penalty = 120 // piss easy to destroy
						var/datum/brain_trauma/severe/paralysis/sepsis = new (limb.body_zone)
						victim.gain_trauma(sepsis)
				strikes_to_lose_limb--

/datum/wound/burn/get_examine_description(mob/user)
	if(strikes_to_lose_limb <= 0)
		return "<span class='deadsay'><B>[victim.ru_ego(TRUE)] [limb.ru_name] отмерла целиком.</B></span>"

	var/list/condition = list("[victim.ru_ego(TRUE)] [limb.ru_name] [examine_desc]")
	if(limb.current_gauze)
		var/bandage_condition
		switch(limb.current_gauze.absorption_capacity)
			if(0 to 1.25)
				bandage_condition = "изношенным "
			if(1.25 to 2.75)
				bandage_condition = "потрёпанным "
			if(2.75 to 4)
				bandage_condition = "грязноватым "
			if(4 to INFINITY)
				bandage_condition = "чистым "

		condition += " покрыт [bandage_condition] [limb.current_gauze.name]"
	else
		switch(infestation)
			if(WOUND_INFECTION_MODERATE to WOUND_INFECTION_SEVERE)
				condition += ", <span class='deadsay'>с небольшими бесцветными пятнами вдоль вен!</span>"
			if(WOUND_INFECTION_SEVERE to WOUND_INFECTION_CRITICAL)
				condition += ", <span class='deadsay'>с темными пятнами, расходящимися под кожей!</span>"
			if(WOUND_INFECTION_CRITICAL to WOUND_INFECTION_SEPTIC)
				condition += ", <span class='deadsay'>с с гниющими пульсирующими прожилками!</span>"
			if(WOUND_INFECTION_SEPTIC to INFINITY)
				return "<span class='deadsay'><B>[victim.ru_ego(TRUE)] [limb.ru_name] представляет собой месиво из перегноя и костей, с которых сползает заражённая кожа!</B></span>"
			else
				condition += "!"

	return "<B>[condition.Join()]</B>"

/datum/wound/burn/get_scanner_description(mob/user)
	if(strikes_to_lose_limb == 0)
		var/oopsie = "Тип: [name]\nТяжесть: [severity_text()]"
		oopsie += "<div class='ml-3'>Степень инфекции: <span class='deadsay'>Полное заражение. Конечность утрачена. Немедленно ампутируйте или аугментируйте её.</span></div>"
		return oopsie

	. = ..()
	. += "<div class='ml-3'>"

	if(infestation <= sanitization && flesh_damage <= flesh_healing)
		. += "Дальнейшее лечение не требуется: Ожоги вскоре затянутся."
	else
		switch(infestation)
			if(WOUND_INFECTION_MODERATE to WOUND_INFECTION_SEVERE)
				. += "Степень инфекции: Умеренная\n"
			if(WOUND_INFECTION_SEVERE to WOUND_INFECTION_CRITICAL)
				. += "Степень инфекции: Тяжелая\n"
			if(WOUND_INFECTION_CRITICAL to WOUND_INFECTION_SEPTIC)
				. += "Степень инфекции: <span class='deadsay'>КРИТИЧЕСКАЯ</span>\n"
			if(WOUND_INFECTION_SEPTIC to INFINITY)
				. += "Степень инфекции: <span class='deadsay'>НЕМИНУЕМАЯ ПОТЕРЯ</span>\n"
		if(infestation > sanitization)
			. += "Удаление некротических тканей, антибиотики/антисептик, регенеративная сетка помогут избавиться от инфекции. Ультрафиолетовые пенлайты парамедиков также могут быть полезны.\n"

		if(flesh_damage > 0)
			. += "Обнаружены повреждения плоти: Нанесите мазь или регенеративную сетку для восстановления.\n"
	. += "</div>"

/*
	new burn common procs
*/

/// if someone is using ointment on our burns
/datum/wound/burn/proc/ointment(obj/item/stack/medical/ointment/I, mob/user)
	user.visible_message("<span class='notice'>[user] начинает применять [I] на конечности [victim]...</span>", "<span class='notice'>Вы начинаете применять [I] на [user == victim ? "вашей конечности" : "конечности персонажа [victim]"]...</span>")
	if(!do_after(user, (user == victim ? I.self_delay : I.other_delay), extra_checks = CALLBACK(src, PROC_REF(still_exists))))
		return

	limb.heal_damage(I.heal_brute, I.heal_burn)
	user.visible_message("<span class='green'>[user] применяет [I] на [victim].</span>", "<span class='green'>Вы применяете [I] на [user == victim ? "вашей конечности" : "конечности персонажа [victim]"].</span>")
	I.use(1)
	sanitization += I.sanitization
	flesh_healing += I.flesh_regeneration

	if((infestation <= 0 || sanitization >= infestation) && (flesh_damage <= 0 || flesh_healing > flesh_damage))
		to_chat(user, "<span class='notice'>Вы сделали всё, что можно было сделать с помощью с[I], теперь подождите, пока плоть на конечности персонажа [victim] восстановится.</span>")
	else
		try_treating(I, user)

/// if someone is using mesh on our burns
/datum/wound/burn/proc/mesh(obj/item/stack/medical/mesh/I, mob/user)
	user.visible_message("<span class='notice'>[user] пытается перевязать конечность - [limb.ru_name] - персонажа [victim] с помощью [I]...</span>", "<span class='notice'>Вы пытаетесь перевязать [user == victim ? "вашу [limb.ru_name]" : "конечность персонажа [victim]"] с помощью [I]...</span>")
	if(!do_after(user, (user == victim ? I.self_delay : I.other_delay), target=victim, extra_checks = CALLBACK(src, PROC_REF(still_exists))))
		return

	limb.heal_damage(I.heal_brute, I.heal_burn)
	user.visible_message("<span class='green'>[user] применяет [I] на [victim].</span>", "<span class='green'>Вы применяете [I] на [user == victim ? "вашу конечность." : "конечность персонажа [victim]"]</span>")
	I.use(1)
	sanitization += I.sanitization
	flesh_healing += I.flesh_regeneration

	if(sanitization >= infestation && flesh_healing > flesh_damage)
		to_chat(user, "<span class='notice'>Вы сделали всё, что возможно было сделать с помощью [I], теперь подождите, пока плоть на конечности персонажа [victim] восстановится.</span>")
	else
		try_treating(I, user)

/// Paramedic UV penlights
/datum/wound/burn/proc/uv(obj/item/flashlight/pen/paramedic/I, mob/user)
	if(!COOLDOWN_FINISHED(I, uv_cooldown))
		to_chat(user, "<span class='notice'>[I] ещё перезаряжается!</span>")
		return
	if(infestation <= 0 || infestation < sanitization)
		to_chat(user, "<span class='notice'>На конечности персонажа [victim] нет инфекции!</span>")
		return

	user.visible_message("<span class='notice'>[user] просвечивает ожоги персонажа [victim] с помощью [I].</span>", "<span class='notice'>Вы подсвечиваете ожоги [user == victim ? "на вашей конечности" : "конечности персонажа [victim]"] с помощью [I].</span>", vision_distance=COMBAT_MESSAGE_RANGE)
	sanitization += I.uv_power
	COOLDOWN_START(I, uv_cooldown, I.uv_cooldown_length)

/datum/wound/burn/treat(obj/item/I, mob/user)
	if(!victim.can_inject())
		to_chat(user, span_danger("Одежда на теле [victim] не позволяет применить [I]!</span>"))
		return
	if(istype(I, /obj/item/stack/medical/ointment))
		ointment(I, user)
	else if(istype(I, /obj/item/stack/medical/mesh))
		mesh(I, user)
	else if(istype(I, /obj/item/flashlight/pen/paramedic))
		uv(I, user)

// people complained about burns not healing on stasis beds, so in addition to checking if it's cured, they also get the special ability to very slowly heal on stasis beds if they have the healing effects stored
/datum/wound/burn/on_stasis()
	. = ..()
	if(flesh_healing > 0)
		flesh_damage = max(0, flesh_damage - 0.2)
	if((flesh_damage <= 0) && (infestation <= 1))
		to_chat(victim, "<span class='green'>Ваша [limb.ru_name] была очищена от ожогов!</span>")
		qdel(src)
		return
	if(sanitization > 0)
		infestation = max(0, infestation - WOUND_BURN_SANITIZATION_RATE * 0.2)

/datum/wound/burn/on_synthflesh(amount)
	flesh_healing += amount * 0.5 // 20u patch will heal 10 flesh standard

// we don't even care about first degree burns, straight to second
/datum/wound/burn/moderate
	name = "Second Degree Burns"
	ru_name = "Ожоги второй степени"
	ru_name_r = "ожогов второй степени"
	desc = "Пациент получил легкие ожоги, что привело к ослаблению целостности конечности и ощущению жжения."
	treat_text = "Нанести мазь или регенерирующую сетку на поврежденную область."
	examine_desc = "сильно обгорела и покрылась волдырями"
	occur_text = "шипит от образующихся красных ожоговых пятен"
	severity = WOUND_SEVERITY_MODERATE
	damage_mulitplier_penalty = 1.1
	threshold_minimum = 40
	threshold_penalty = 8 // burns cause significant decrease in limb integrity compared to other wounds
	status_effect_type = /datum/status_effect/wound/burn/moderate
	flesh_damage = 5
	scar_keyword = "burnmoderate"

/datum/wound/burn/severe
	name = "Third Degree Burns"
	ru_name = "Ожоги третьей степени"
	ru_name_r = "ожогов третьей степени"
	desc = "Пациент страдает от серьезных ожогов, ведущих к отмиранию тканей и ухудшению моторики."
	treat_text = "Немедленная дезинфекция и удаление некротической кожи с последующими обработкой мазью и перевязкой."
	examine_desc = "выглядит обугленной, с красными вкраплениями"
	occur_text = "быстро обугливается, обнажая потрескавшуюся кожу и плоть"
	severity = WOUND_SEVERITY_SEVERE
	damage_mulitplier_penalty = 1.2
	threshold_minimum = 75
	threshold_penalty = 10
	status_effect_type = /datum/status_effect/wound/burn/severe
	treatable_by = list(/obj/item/flashlight/pen/paramedic, /obj/item/stack/medical/ointment, /obj/item/stack/medical/mesh)
	infestation_rate = 0.05 // appx 13 minutes to reach sepsis without any treatment
	flesh_damage = 12.5
	scar_keyword = "burnsevere"

/datum/wound/burn/critical
	name = "Catastrophic Burns"
	ru_name = "Ожоги четвертой степени"
	ru_name_r = "ожогов четвертой степени"
	desc = "Наблюдается практически полная потеря тканей и значительное обгорание костей и мышц пациента. Конечность может стать нефункциональной целиком."
	treat_text = "Немедленное хирургическое вмешательство. Удаление некроза, нанесение препаратов для восстановления тканей. Перевязывание конечности."
	examine_desc = "представляет собой месиво из костей, расплавленного жира и обугленных тканей"
	occur_text = "испаряется, пока плоть, кости и жир сплавливаются в одну жуткую массу"
	severity = WOUND_SEVERITY_CRITICAL
	damage_mulitplier_penalty = 1.5
	sound_effect = 'sound/effects/wounds/sizzle2.ogg'
	threshold_minimum = 130
	threshold_penalty = 15
	status_effect_type = /datum/status_effect/wound/burn/critical
	treatable_by = list(/obj/item/flashlight/pen/paramedic, /obj/item/stack/medical/ointment, /obj/item/stack/medical/mesh)
	infestation_rate = 0.15 // appx 4.33 minutes to reach sepsis without any treatment
	flesh_damage = 20
	scar_keyword = "burncritical"
