/*
	Pierce
*/

/datum/wound/pierce
	sound_effect = 'sound/weapons/slice.ogg'
	processes = TRUE
	wound_type = WOUND_PIERCE
	treatable_by = list(/obj/item/stack/medical/suture)
	treatable_tool = TOOL_CAUTERY
	base_treat_time = 3 SECONDS
	wound_flags = (FLESH_WOUND | ACCEPTS_GAUZE)

	/// How much blood we start losing when this wound is first applied
	var/initial_flow
	/// If gauzed, what percent of the internal bleeding actually clots of the total absorption rate
	var/gauzed_clot_rate

	/// When hit on this bodypart, we have this chance of losing some blood + the incoming damage
	var/internal_bleeding_chance
	/// If we let off blood when hit, the max blood lost is this * the incoming damage
	var/internal_bleeding_coefficient

	/// If we deal lung traumas, when is the next one due?
	var/next_trauma_cycle

	/// How long do we wait for the next lung stroke?
	var/trauma_cycle_cooldown = 1.3 MINUTES

/datum/wound/pierce/apply_wound(obj/item/bodypart/L, silent, datum/wound/old_wound, smited)
	. = ..()
	if(L.body_zone == BODY_ZONE_CHEST && (severity == WOUND_SEVERITY_SEVERE || severity == WOUND_SEVERITY_CRITICAL))
		if(!HAS_TRAIT(victim, TRAIT_ROBOTIC_ORGANISM)) // BLUEMOON ADD
			ru_name = "Пробитие лёгкого"
			ru_name_r = "пробития лёгкого"
			occur_text = "раскалывается, приводя к обильному кашлю"
			examine_desc = "имеет углубленную выемку, из которой выходит воздух"

/datum/wound/pierce/wound_injury(datum/wound/old_wound)
	if(limb.body_zone == BODY_ZONE_CHEST && (severity == WOUND_SEVERITY_SEVERE || severity == WOUND_SEVERITY_CRITICAL))
		if(!HAS_TRAIT(victim, TRAIT_ROBOTIC_ORGANISM)) // BLUEMOON ADD
			processes = TRUE
			victim.adjustOxyLoss(15)
			victim.adjustOrganLoss(ORGAN_SLOT_LUNGS,15)
			victim.emote("cough")
			next_trauma_cycle = world.time + (rand(100-20, 100+20) * 0.01 * trauma_cycle_cooldown)

	blood_flow = initial_flow

/datum/wound/pierce/receive_damage(wounding_type, wounding_dmg, wound_bonus)
	if(victim.stat == DEAD || wounding_dmg < 5)
		return
	if(victim.blood_volume && prob(internal_bleeding_chance + wounding_dmg))
		if(limb.current_gauze && limb.current_gauze.splint_factor)
			wounding_dmg *= (1 - limb.current_gauze.splint_factor)
		var/blood_bled = rand(1, wounding_dmg * internal_bleeding_coefficient) // 12 brute toolbox can cause up to 15/18/21 bloodloss on mod/sev/crit
		switch(blood_bled)
			if(1 to 6)
				victim.bleed(blood_bled, TRUE)
			if(7 to 13)
				victim.visible_message("<span class='smalldanger'>Капли [HAS_TRAIT(victim, TRAIT_ROBOTIC_ORGANISM) ? "чёрной жидкости" : "крови"] стекают по [limb.ru_name_v] персонажа [victim].</span>", "<span class='danger'>Вы откашливаете немного [HAS_TRAIT(victim, TRAIT_ROBOTIC_ORGANISM) ? "чёрной жидкости для защиты внутренних систем" : "крови"].</span>", vision_distance=COMBAT_MESSAGE_RANGE)
				victim.bleed(blood_bled, TRUE)
			if(14 to 19)
				victim.visible_message("<span class='smalldanger'>Небольшая струя [HAS_TRAIT(victim, TRAIT_ROBOTIC_ORGANISM) ? "чёрной жидкости" : "крови"] стекает по [limb.ru_name_v] - персонажа [victim]!</span>", "<span class='danger'>Вы откашливаете сгусток [HAS_TRAIT(victim, TRAIT_ROBOTIC_ORGANISM) ? "чёрной жидкости" : "крови"]!</span>", vision_distance=COMBAT_MESSAGE_RANGE)
				if(ishuman(victim))
					var/mob/living/carbon/human/H = victim
					new /obj/effect/temp_visual/dir_setting/bloodsplatter(victim.loc, victim.dir, H.dna.species.exotic_blood_color)
				else
					new /obj/effect/temp_visual/dir_setting/bloodsplatter(victim.loc, victim.dir)
				victim.bleed(blood_bled)
			if(20 to INFINITY)
				victim.visible_message("<span class='danger'>Струя [HAS_TRAIT(victim, TRAIT_ROBOTIC_ORGANISM) ? "чёрной жидкости" : "крови"] обильно течёт по [limb.ru_name_v] персонажа [victim]!</span>", "<span class='danger'><b>Вы обильно кашляете [HAS_TRAIT(victim, TRAIT_ROBOTIC_ORGANISM) ? "чёрной жидкостью" : "кровью"]!</b></span>", vision_distance=COMBAT_MESSAGE_RANGE)
				victim.bleed(blood_bled)
				if(ishuman(victim))
					var/mob/living/carbon/human/H = victim
					new /obj/effect/temp_visual/dir_setting/bloodsplatter(victim.loc, victim.dir, H.dna.species.exotic_blood_color)
				else
					new /obj/effect/temp_visual/dir_setting/bloodsplatter(victim.loc, victim.dir)
				victim.add_splatter_floor(get_step(victim.loc, victim.dir))

/datum/wound/pierce/handle_process()
	. = ..()
	if(limb.body_zone == BODY_ZONE_CHEST && (severity == WOUND_SEVERITY_SEVERE || severity == WOUND_SEVERITY_CRITICAL) && world.time > next_trauma_cycle)
		next_trauma_cycle = world.time + (rand(100-20, 100+20) * 0.01 * trauma_cycle_cooldown)
		if(!HAS_TRAIT(victim, TRAIT_ROBOTIC_ORGANISM)) // BLUEMOON ADD
			victim.adjustOxyLoss(20)
			victim.emote("gasp")

	blood_flow = min(blood_flow, WOUND_SLASH_MAX_BLOODFLOW)

	if(!HAS_TRAIT(victim, TRAIT_ROBOTIC_ORGANISM))
		if(victim.bodytemperature < (BODYTEMP_NORMAL -  10))
			blood_flow -= 0.2
			if(prob(5))
				to_chat(victim, "<span class='notice'>Вы чувствуете, как [lowertext(name)] в вашей [limb.ru_name_v] застывает за счёт холода!</span>")

	if(victim.reagents?.has_reagent(/datum/reagent/toxin/heparin))
		blood_flow += 0.5 // old herapin used to just add +2 bleed stacks per tick, this adds 0.5 bleed flow to all open cuts which is probably even stronger as long as you can cut them first

	if(limb.current_gauze)
		blood_flow -= limb.current_gauze.absorption_rate * gauzed_clot_rate
		limb.current_gauze.absorption_capacity -= limb.current_gauze.absorption_rate

	if(blood_flow <= 0)
		qdel(src)

/datum/wound/pierce/on_stasis()
	. = ..()
	if(blood_flow <= 0)
		qdel(src)

/datum/wound/pierce/treat(obj/item/I, mob/user)
	if(!victim.can_inject())
		to_chat(user, span_danger("Одежда на теле [victim] не позволяет применить [I]!</span>"))
		return
	if(istype(I, /obj/item/stack/medical/suture))
		suture(I, user)
	else if(I.tool_behaviour == TOOL_CAUTERY || I.get_temperature() > 300)
		tool_cauterize(I, user)

/datum/wound/pierce/on_xadone(power)
	. = ..()
	blood_flow -= 0.03 * power // i think it's like a minimum of 3 power, so .09 blood_flow reduction per tick is pretty good for 0 effort

/datum/wound/pierce/on_synthflesh(power)
	. = ..()
	blood_flow -= 0.05 * power // 20u * 0.05 = -1 blood flow, less than with slashes but still good considering smaller bleed rates

/// If someone is using a suture to close this cut
/datum/wound/pierce/proc/suture(obj/item/stack/medical/suture/I, mob/user)
	// BLUEMOON ADD START - нитка и иголка не могут заштопать листы металла
	if(HAS_TRAIT(victim, TRAIT_ROBOTIC_ORGANISM))
		to_chat(user, "Это не поможет, это же робот!")
		return
	// BLUEMOON ADD END
	var/self_penalty_mult = (user == victim ? 1.4 : 1)
	user.visible_message("<span class='notice'>[user] пытается зашить увечия на [limb.ru_name_v] персонажа [victim] с помощью [I]...</span>", "<span class='notice'>Вы начинаете зашивать [user == victim ? "свои увечия" : "увечия персонажа [victim]"] с помощью [I]...</span>")
	if(!do_after(user, base_treat_time * self_penalty_mult, target=victim, extra_checks = CALLBACK(src, PROC_REF(still_exists))))
		return
	user.visible_message("<span class='green'>[user] зашивает увечия персонажа [victim].</span>", "<span class='green'>Вы зашиваете увечия на [user == victim ? "своей конечности" : "конечности персонажа [victim]"].</span>")
	var/blood_sutured = I.stop_bleeding / self_penalty_mult * 0.5
	blood_flow -= blood_sutured
	limb.heal_damage(I.heal_brute, I.heal_burn)

	if(blood_flow > 0)
		try_treating(I, user)
	else
		to_chat(user, "<span class='green'>Вы успешно закрываете отверстие на [user == victim ? "своей конечности" : "конечности персонажа [victim]"].</span>")

/// If someone is using either a cautery tool or something with heat to cauterize this pierce
/datum/wound/pierce/proc/tool_cauterize(obj/item/I, mob/user)
	var/self_penalty_mult = (user == victim ? 1.5 : 1)
	user.visible_message("<span class='danger'>[user] пытается прижечь увечие на [limb.ru_name_v] персонажа [victim] с помощью [I]...</span>", "<span class='danger'>Вы пытаетесь прижечь [user == victim ? "свою конечность" : "конечность персонажа [victim]"] с помощью [I]...</span>")
	if(!do_after(user, base_treat_time * self_penalty_mult, target=victim, extra_checks = CALLBACK(src, PROC_REF(still_exists))))
		return

	user.visible_message("<span class='green'>[user] прижигает увечия персонажа [victim].</span>", "<span class='green'>Вы прижигаете увечия персонажа [victim].</span>")
	if(!HAS_TRAIT(victim, TRAIT_ROBOTIC_ORGANISM)) // BLUEMOON ADD - роботы не кричат от боли
		limb.receive_damage(burn = 2 + severity, wound_bonus = CANT_WOUND)
		if(prob(30))
			victim.emote("scream")
	var/blood_cauterized = (0.6 / self_penalty_mult) * 0.5
	blood_flow -= blood_cauterized

	if(blood_flow > 0)
		try_treating(I, user)

/datum/wound/pierce/moderate
	name = "Minor Breakage"
	ru_name = "Малая колотая рана"
	ru_name_r = "малой колотой раны"
	desc = "Кожа пациента повреждена, что привело к небольшому кровотечению."
	treat_text = "Перевязать поврежденную кожу или наложить холодный компресс." // space is cold in ss13, so it's like an ice pack!
	examine_desc = "имеет небольшое отверстие, из которого течёт струйка крови"
	occur_text = "извергает тонкую струйку крови"
	sound_effect = 'sound/effects/wounds/pierce1.ogg'
	severity = WOUND_SEVERITY_MODERATE
	initial_flow = 1.4
	gauzed_clot_rate = 0.8
	internal_bleeding_chance = 45
	internal_bleeding_coefficient = 1.1
	threshold_minimum = 40
	threshold_penalty = 8
	status_effect_type = /datum/status_effect/wound/pierce/moderate
	scar_keyword = "piercemoderate"

// BLUEMOON ADD START
/datum/wound/pierce/moderate/apply_wound(obj/item/bodypart/L, silent, datum/wound/old_wound, smited)
	if(istype(L) && L.is_robotic_limb())
		ru_name = "Малая Пробоина Обшивки"
		ru_name_r = "малой пробоины обшивки"
		desc = "Обшивка повреждена, что приводит к малой потери жидкостей"
		treat_text = "Сварить поврежденную область сваркой."
		examine_desc = "покрыто маленькими отверстиями, из которых течёт чёрная жижа"
		occur_text = "начинает истекать чёрной жижей"
		treatable_tool = TOOL_WELDER

	return ..()
// BLUEMOON ADD END

/datum/wound/pierce/severe
	name = "Open Puncture"
	ru_name = "Колотая рана"
	ru_name_r = "колотой раны"
	desc = "Patient's internal tissue is penetrated, causing sizeable internal bleeding and reduced limb stability."
	treat_text = "Перекрыть поврежденные участки с помощью жгута или прижигателя. В неординарных ситуациях поможет и воздействие космического вакуума вкупе с сильным холодом."
	examine_desc = "пробита насквозь, а отверстие проглядывается через остатки кожи"
	occur_text = "выплескивает струю крови, обнажая сквозную рану"
	sound_effect = 'sound/effects/wounds/pierce2.ogg'
	severity = WOUND_SEVERITY_SEVERE
	initial_flow = 1.8
	gauzed_clot_rate = 0.6
	internal_bleeding_chance = 65
	internal_bleeding_coefficient = 1.3
	threshold_minimum = 65
	threshold_penalty = 15
	status_effect_type = /datum/status_effect/wound/pierce/severe
	scar_keyword = "piercesevere"

// BLUEMOON ADD START
/datum/wound/pierce/severe/apply_wound(obj/item/bodypart/L, silent, datum/wound/old_wound, smited)
	if(istype(L) && L.is_robotic_limb())
		name = "Open Puncture"
		ru_name = "Пробоина Обшивки"
		ru_name_r = "пробоины обшивки"
		desc = "Сквозная рана вызывает умеренную потерю жидкостей."
		treat_text = "Заварить поврежденную область сваркой."
		examine_desc = "пробита насквозь, чёрная жидкость вытекает."
		occur_text = "выплескивает струю чёрной жижи, обнажая сквозную пробоину"
		treatable_tool = TOOL_WELDER

	return ..()
// BLUEMOON ADD END

/datum/wound/pierce/critical
	name = "Ruptured Cavity"
	ru_name = "Разрыв тканей"
	ru_name_r = "разрыва тканей"
	desc = "Ткани и кровеносная система пациента повреждены. Это привело к обильному внутреннему кровотечению."
	treat_text = "Хирургическое вмешательство с последующим переливанием крови."
	examine_desc = "буквально разорвана и едва удерживается обнаженными костями"
	occur_text = "разрывается, разбрасывая вокруг обломки костей и плоти"
	sound_effect = 'sound/effects/wounds/pierce3.ogg'
	severity = WOUND_SEVERITY_CRITICAL
	initial_flow = 2.75
	gauzed_clot_rate = 0.4
	internal_bleeding_chance = 80
	internal_bleeding_coefficient = 1.6
	threshold_minimum = 95
	threshold_penalty = 20
	status_effect_type = /datum/status_effect/wound/pierce/critical
	scar_keyword = "piercecritical"
	wound_flags = (FLESH_WOUND | ACCEPTS_GAUZE | MANGLES_FLESH)

// BLUEMOON ADD START
/datum/wound/pierce/critical/apply_wound(obj/item/bodypart/L, silent, datum/wound/old_wound, smited)
	if(istype(L) && L.is_robotic_limb())
		ru_name = "Прорванная Обшивка"
		ru_name_r = "прорванная обшивка"
		desc = "обшивка и трубы гидравлической жидкости пробиты, это приводит к обильной потери жидкостей."
		treat_text = "Заварить поврежденную часть, заменить гидравлическую жидкость"
		examine_desc = "буквально разорвана и едва удерживается обнаженными приводами"
		occur_text = "разрывается со всплеском чёрной жижи, разбрасывая вокруг обломки обшивки и приводов"
		wound_flags = (FLESH_WOUND | MANGLES_FLESH)
		treatable_tool = TOOL_WELDER

	return ..()
// BLUEMOON ADD END
