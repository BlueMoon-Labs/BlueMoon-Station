/*
	Cuts
*/

/datum/wound/slash
	sound_effect = 'sound/weapons/slice.ogg'
	processes = TRUE
	wound_type = WOUND_SLASH
	treatable_by = list(/obj/item/stack/medical/suture)
	treatable_by_grabbed = list(/obj/item/gun/energy/laser)
	treatable_tool = TOOL_CAUTERY
	base_treat_time = 3 SECONDS
	wound_flags = (FLESH_WOUND | ACCEPTS_GAUZE)

	/// How much blood we start losing when this wound is first applied
	var/initial_flow
	/// When we have less than this amount of flow, either from treatment or clotting, we demote to a lower cut or are healed of the wound
	var/minimum_flow
	/// How fast our blood flow will naturally decrease per tick, not only do larger cuts bleed more faster, they clot slower
	var/clot_rate

	/// Once the blood flow drops below minimum_flow, we demote it to this type of wound. If there's none, we're all better
	var/demotes_to

	/// How much staunching per type (cautery, suturing, bandaging) you can have before that type is no longer effective for this cut NOT IMPLEMENTED
	var/max_per_type
	/// The maximum flow we've had so far
	var/highest_flow

	/// A bad system I'm using to track the worst scar we earned (since we can demote, we want the biggest our wound has been, not what it was when it was cured (probably moderate))
	var/datum/scar/highest_scar

/datum/wound/slash/wound_injury(datum/wound/slash/old_wound = null)
	blood_flow = initial_flow
	if(old_wound)
		blood_flow = max(old_wound.blood_flow, initial_flow)
		if(old_wound.severity > severity && old_wound.highest_scar)
			set_highest_scar(old_wound.highest_scar)
			old_wound.clear_highest_scar()

	if(!highest_scar)
		var/datum/scar/new_scar = new
		set_highest_scar(new_scar)
		new_scar.generate(limb, src, add_to_scars=FALSE)

/datum/wound/slash/proc/set_highest_scar(datum/scar/new_scar)
	if(highest_scar)
		UnregisterSignal(highest_scar, COMSIG_PARENT_QDELETING)
	if(new_scar)
		RegisterSignal(new_scar, COMSIG_PARENT_QDELETING, PROC_REF(clear_highest_scar))
	highest_scar = new_scar

/datum/wound/slash/proc/clear_highest_scar(datum/source)
	SIGNAL_HANDLER
	set_highest_scar(null)

/datum/wound/slash/remove_wound(ignore_limb, replaced)
	if(!replaced && highest_scar)
		already_scarred = TRUE
		highest_scar.lazy_attach(limb)
	return ..()

/datum/wound/slash/get_examine_description(mob/user)
	if(!limb.current_gauze)
		return ..()

	var/list/msg = list("Порезы на [victim.ru_ego()] [limb.ru_name_v] перебинтованы")
	// how much life we have left in these bandages
	switch(limb.current_gauze.absorption_capacity)
		if(0 to 1.25)
			msg += "изношенные "
		if(1.25 to 2.75)
			msg += "поношенные "
		if(2.75 to 4)
			msg += "покрытые кровью "
		if(4 to INFINITY)
			msg += "чистые "
	msg += "[limb.current_gauze.name]!"

	return "<B>[msg.Join()]</B>"

/datum/wound/slash/receive_damage(wounding_type, wounding_dmg, wound_bonus)
	if(victim.stat != DEAD && wounding_type == WOUND_SLASH) // can't stab dead bodies to make it bleed faster this way
		blood_flow += 0.05 * wounding_dmg

/datum/wound/slash/drag_bleed_amount()
	// say we have 3 severe cuts with 3 blood flow each, pretty reasonable
	// compare with being at 100 brute damage before, where you bled (brute/100 * 2), = 2 blood per tile
	var/bleed_amt = min(blood_flow * 0.1, 1) // 3 * 3 * 0.1 = 0.9 blood total, less than before! the share here is .3 blood of course.

	if(limb.current_gauze) // gauze stops all bleeding from dragging on this limb, but wears the gauze out quicker
		limb.seep_gauze(bleed_amt * 0.33)
		return

	return bleed_amt

/datum/wound/slash/handle_process()
	if(victim.stat == DEAD)
		blood_flow -= max(clot_rate, WOUND_SLASH_DEAD_CLOT_MIN)
		if(blood_flow < minimum_flow)
			if(demotes_to)
				replace_wound(demotes_to)
				return
			qdel(src)
			return

	blood_flow = min(blood_flow, WOUND_SLASH_MAX_BLOODFLOW)

	if(victim.reagents?.has_reagent(/datum/reagent/toxin/heparin))
		blood_flow += 0.5 // old herapin used to just add +2 bleed stacks per tick, this adds 0.5 bleed flow to all open cuts which is probably even stronger as long as you can cut them first

	if(limb.current_gauze)
		if(clot_rate > 0)
			blood_flow -= clot_rate
		blood_flow -= limb.current_gauze.absorption_rate
		limb.seep_gauze(limb.current_gauze.absorption_rate)
	else
		blood_flow -= clot_rate

	if(blood_flow > highest_flow)
		highest_flow = blood_flow

	if(blood_flow < minimum_flow)
		if(demotes_to)
			replace_wound(demotes_to)
		else
			to_chat(victim, "<span class='green'>Ваша [limb.ru_name] перестала истекать [HAS_TRAIT(victim, TRAIT_ROBOTIC_ORGANISM) ? "гидравлической жидкость" : "кровью"] из-за порезов!</span>") // BLUEMOON EDIT - добавлена проверка для роботов
			qdel(src)


/datum/wound/slash/on_stasis()
	if(blood_flow >= minimum_flow)
		return
	if(demotes_to)
		replace_wound(demotes_to)
		return
	qdel(src)

/* BEWARE, THE BELOW NONSENSE IS MADNESS. bones.dm looks more like what I have in mind and is sufficiently clean, don't pay attention to this messiness */

/datum/wound/slash/check_grab_treatments(obj/item/I, mob/user)
	if(istype(I, /obj/item/gun/energy/laser))
		return TRUE

/datum/wound/slash/treat(obj/item/I, mob/user)
	if(!victim.can_inject())
		to_chat(user, span_danger("Одежда на теле [victim] не позволяет применить [I]!</span>"))
		return
	if(istype(I, /obj/item/gun/energy/laser))
		las_cauterize(I, user)
	else if(I.tool_behaviour == TOOL_CAUTERY || I.get_temperature() > 300)
		tool_cauterize(I, user)
	else if(istype(I, /obj/item/stack/medical/suture))
		suture(I, user)

/datum/wound/slash/try_handling(mob/living/carbon/human/user)
	if(user.pulling != victim || user.zone_selected != limb.body_zone || user.a_intent == INTENT_GRAB)
		return FALSE

	if(!iscatperson(user))
		return FALSE

	lick_wounds(user)
	return TRUE

/// if a felinid is licking this cut to reduce bleeding
/datum/wound/slash/proc/lick_wounds(mob/living/carbon/human/user)
	if(INTERACTING_WITH(user, victim))
		to_chat(user, "<span class='warning'>Вы уже взаимодействуйте с персонажем [victim]!</span>")
		return

	if(user.is_mouth_covered())
		to_chat(user, "<span class='warning'>Ваш рот закрыт, вы не можете зализать раны персонажа [victim]!</span>")
		return

	if(!user.getorganslot(ORGAN_SLOT_TONGUE))
		to_chat(user, "<span class='warning'>Вы не можете зализывать раны, у вас нет языка!</span>") // f in chat
		return

	// transmission is one way patient -> felinid since google said cat saliva is antiseptic or whatever, and also because felinids are already risking getting beaten for this even without people suspecting they're spreading a deathvirus
	for(var/datum/disease/D in victim.diseases)
		user.ForceContractDisease(D)

	user.visible_message("<span class='notice'>[user] пытается зализать раны на [limb.ru_name_v] персонажа [victim].</span>", "<span class='notice'>Вы пытаетесь зализать раны на [limb.ru_name_v] персонажа [victim]....</span>", ignored_mobs=victim)
	to_chat(victim, "<span class='notice'>[user] пытается зализать раны на вашей конечности - [limb.ru_name].</span")
	if(!do_after(user, base_treat_time, target=victim, extra_checks = CALLBACK(src, PROC_REF(still_exists))))
		return

	// BLUEMOON ADD START - попытка зализать языком рану с маслом выглядит ужасно
	if(HAS_TRAIT(victim, TRAIT_ROBOTIC_ORGANISM) && !HAS_TRAIT(user, TRAIT_ROBOTIC_ORGANISM))
		user.visible_message("<span class='warning'>[user] резко отстраняется от [victim]!</span>", "<span class='notice'>Противная жидкость попадает на ваш язык. Похоже на сгоревшее масло, вы не можете это зализать!</span>", ignored_mobs=victim)
		return
	// BLUEMOON ADD END

	user.visible_message("<span class='notice'>[user] зализывает раны на [limb.ru_name_v] - персонажа [victim].</span>", "<span class='notice'>Вы зализываете некоторые раны на [limb.ru_name_v] персонажа [victim].</span>", ignored_mobs=victim)
	to_chat(victim, "<span class='green'>[user] зализывает раны на вашей [limb.ru_name_v]!</span")
	blood_flow -= 0.5
	if(isinsect(victim) || iscatperson(victim) || ismammal(victim) || isdwarf(victim) || ismonkey(victim)) // Yep you can lick monkeys.
		user.reagents.add_reagent(/datum/reagent/hairball, 2)

	else if(ishumanbasic(victim) || isflyperson(victim) || islizard(victim) || HAS_TRAIT(victim, TRAIT_DULLAHAN))
		user.reagents.add_reagent(/datum/reagent/hairball, 1)

	if(blood_flow > minimum_flow)
		try_handling(user)
	else if(demotes_to)
		to_chat(user, "<span class='green'>Вы успешно снижаете тяжесть порезов персонажа [victim].</span>")

/datum/wound/slash/on_xadone(power)
	. = ..()
	blood_flow -= 0.03 * power // i think it's like a minimum of 3 power, so .09 blood_flow reduction per tick is pretty good for 0 effort

/datum/wound/slash/on_synthflesh(power)
	. = ..()
	blood_flow -= 0.075 * power // 20u * 0.075 = -1.5 blood flow, pretty good for how little effort it is

/// If someone's putting a laser gun up to our cut to cauterize it
/datum/wound/slash/proc/las_cauterize(obj/item/gun/energy/laser/lasgun, mob/user)
	var/self_penalty_mult = (user == victim ? 1.25 : 1)
	user.visible_message("<span class='warning'>[user] пытается нацелить [lasgun] на рану на [limb.ru_name_v] персонажа [victim]....</span>", "<span class='userdanger'>Вы пытаетесь нацелить [lasgun] на рану на [user == victim ? "вашей конечности" : "конечности персонажа [victim]"]...</span>")
	if(!do_after(user, base_treat_time  * self_penalty_mult, target=victim, extra_checks = CALLBACK(src, PROC_REF(still_exists))))
		return
	var/damage = lasgun.chambered.BB.damage
	lasgun.chambered.BB.wound_bonus -= 30
	lasgun.chambered.BB.damage *= self_penalty_mult
	if(!lasgun.process_fire(victim, victim, TRUE, null, limb.body_zone))
		return
	if(!HAS_TRAIT(victim, TRAIT_ROBOTIC_ORGANISM)) // BLUEMOON ADD - роботы не кричат от боли
		victim.emote("scream")
	blood_flow -= damage / (5 * self_penalty_mult) // 20 / 5 = 4 bloodflow removed, p good
	victim.visible_message("<span class='warning'>Порезы на конечности персонажа [victim] затягиваются шрамами!</span>")

/// If someone is using either a cautery tool or something with heat to cauterize this cut
/datum/wound/slash/proc/tool_cauterize(obj/item/I, mob/user)
	var/self_penalty_mult = (user == victim ? 1.5 : 1)
	user.visible_message("<span class='danger'>[user] пытается прижечь раны на [limb.ru_name_v] персонажа [victim] с помощью [I]...</span>", "<span class='danger'>Вы пытаетесь прижечь рану [user == victim ? "своей конечности" : "конечности персонажа [victim]"] с помощью [I]...</span>")
	if(!do_after(user, base_treat_time * self_penalty_mult, target=victim, extra_checks = CALLBACK(src, PROC_REF(still_exists))))
		return

	user.visible_message("<span class='green'>[user] прижигает увечия персонажа [victim].</span>", "<span class='green'Вы прижагаете увечия персонажа [victim].</span>")
	if(!HAS_TRAIT(victim, TRAIT_ROBOTIC_ORGANISM)) // BLUEMOON ADD - роботы не кричат от боли
		limb.receive_damage(burn = 2 + severity, wound_bonus = CANT_WOUND)
		if(prob(30))
			victim.emote("scream")
	var/blood_cauterized = (0.6 / self_penalty_mult)
	blood_flow -= blood_cauterized

	if(blood_flow > minimum_flow)
		try_treating(I, user)
	else if(demotes_to)
		to_chat(user, "<span class='green'>Вы успешно снижаете тяжесть порезов [user == victim ? "на вашей [limb.ru_name_v]" : "на [limb.ru_name_v] персонажа [victim]"].</span>")

/// If someone is using a suture to close this cut
/datum/wound/slash/proc/suture(obj/item/stack/medical/suture/I, mob/user)
	// BLUEMOON ADD START - нитка и иголка не могут заштопать листы металла
	if(HAS_TRAIT(victim, TRAIT_ROBOTIC_ORGANISM))
		to_chat(user, "Это не поможет, это же робот!")
		return
	// BLUEMOON ADD END

	var/self_penalty_mult = (user == victim ? 1.4 : 1)
	user.visible_message("<span class='notice'>[user] пытается зашить увечия на [limb.ru_name_v] персонажа [victim] с помощью [I]...</span>", "<span class='notice'>Вы пытаетесь зашить [user == victim ? "увечия на вашей [limb.ru_name_v]" : "увечия на [limb.ru_name_v] персонажа [victim]"] с помощью [I]...</span>")

	if(!do_after(user, base_treat_time * self_penalty_mult, target=victim, extra_checks = CALLBACK(src, PROC_REF(still_exists))))
		return
	user.visible_message("<span class='green'>[user] зашивает увечия персонажа [victim].</span>", "<span class='green'>Вы зашиваете некоторые увечия [user == victim ? "на вашей конечности" : "на конечности персонажа [victim]"].</span>")
	var/blood_sutured = I.stop_bleeding / self_penalty_mult
	blood_flow -= blood_sutured
	limb.heal_damage(I.heal_brute, I.heal_burn)

	if(blood_flow > minimum_flow)
		try_treating(I, user)
	else if(demotes_to)
		to_chat(user, "<span class='green'>Вы успешно снижаете степерь порезов на [user == victim ? "вашей конечности" : "конечности персонажа [victim]"].</span>")


/datum/wound/slash/moderate
	name = "Rough Abrasion"
	ru_name = "Сильная царапина"
	ru_name_r = "сильных царапин"
	desc = "Кожа пациента сильно поцарапана, что привело к умеренной кровопотере."
	treat_text = "Наложение повязок или жгутов, с последующим питанием и отдыхом."
	examine_desc = "порезана"
	occur_text = "разрезается, что приводит к кровотечению"
	sound_effect = 'sound/effects/wounds/blood1.ogg'
	severity = WOUND_SEVERITY_MODERATE
	initial_flow = 1.4
	minimum_flow = 0.375
	max_per_type = 3
	clot_rate = 0.12
	threshold_minimum = 40
	threshold_penalty = 8
	status_effect_type = /datum/status_effect/wound/slash/moderate
	scar_keyword = "slashmoderate"

// BLUEMOON ADD START
/datum/wound/slash/moderate/apply_wound(obj/item/bodypart/L, silent, datum/wound/old_wound, smited)
	if(istype(L) && L.is_robotic_limb())
		ru_name = "Прорезь обшивки"
		ru_name_r = "прорези обшивки"
		desc = "В обшивке заметный порез, приводящий к умеренной потери жидкостей."
		treat_text = "Сварить обшивку сваркой."
		examine_desc = "прорезана"
		occur_text = "надрывается, образуя прорезь в обшивке, из которой течёт чёрная жижа"
		clot_rate = 0
		wound_flags = FLESH_WOUND
		treatable_tool = TOOL_WELDER

	return ..()
// BLUEMOON ADD END

/datum/wound/slash/severe
	name = "Open Laceration"
	ru_name = "Рваная рана"
	ru_name_r = "рваной раны"
	desc = "Кожа на конечности пациента повреждена и вскрыта, что привело к обильному кровотечению."
	treat_text = "Немедленное наложение жгутов или чистых повязок, мониторинг состояния пациента."
	examine_desc = "сильно изрезана"
	occur_text = "широко раскрывается, что приводит к венозному кровотечению"
	sound_effect = 'sound/effects/wounds/blood2.ogg'
	severity = WOUND_SEVERITY_SEVERE
	initial_flow = 1.8
	minimum_flow = 1.75
	clot_rate = 0.07
	max_per_type = 4
	threshold_minimum = 65
	threshold_penalty = 15
	demotes_to = /datum/wound/slash/moderate
	status_effect_type = /datum/status_effect/wound/slash/severe
	scar_keyword = "slashsevere"

// BLUEMOON ADD START

/datum/wound/slash/severe/apply_wound(obj/item/bodypart/L, silent, datum/wound/old_wound, smited)
	if(istype(L) && L.is_robotic_limb())
		ru_name = "Надорванная Обшивка"
		ru_name_r = "надорванная обшивки"
		desc = "В обшивке рваное вскрытие, что приводит к обильной потери жидкостей."
		treat_text = "Сварить обшивку сваркой."
		examine_desc = "сильно надорвана"
		occur_text = "надрывается от удара, расплёскивая чёрную жижу вокруг"
		clot_rate = 0
		wound_flags = FLESH_WOUND
		treatable_tool = TOOL_WELDER

	return ..()
// BLUEMOON ADD END

/datum/wound/slash/critical
	name = "Weeping Avulsion"
	ru_name = "Разрыв сухожилия"
	ru_name_r = "разрыва сухожилия"
	desc = "У пациента наблюдается серьезное повреждение кожного покрова. Отсутствие медицинской помощи приведет к смерти в результате сильнейшей кровопотери."
	treat_text = "Немедленная перевязка, хирургическое вмешательство с наложением швов и прижиганием увечия, переливание крови."
	examine_desc = "разрезана до костей, кровь брызжет вокруг"
	occur_text = "разрывается, разбрызгивая кровь"
	sound_effect = 'sound/effects/wounds/blood3.ogg'
	severity = WOUND_SEVERITY_CRITICAL
	initial_flow = 2.85
	minimum_flow = 2.5
	clot_rate = -0.05 // critical cuts actively get worse instead of better
	max_per_type = 5
	threshold_minimum = 100
	threshold_penalty = 25
	demotes_to = /datum/wound/slash/severe
	status_effect_type = /datum/status_effect/wound/slash/critical
	scar_keyword = "slashcritical"
	wound_flags = (FLESH_WOUND | ACCEPTS_GAUZE | MANGLES_FLESH)

// BLUEMOON ADD START
/datum/wound/slash/critical/apply_wound(obj/item/bodypart/L, silent, datum/wound/old_wound, smited)
	if(istype(L) && L.is_robotic_limb())
		ru_name = "Разрыв Обшивки"
		ru_name_r = "разрыва обшивки"
		desc = "Обшивка разована. Платформа быстро теряет жидкости, требуется немедленный ремонт."
		treat_text = "Сварить разрез сваркой и пополнить запасы гидравлической жидкости."
		examine_desc = "разорвана до внутренностей, искриться"
		occur_text = "разрывается, показывая провада в снопах искр и разбрызгивая чёрную жижу под напором"
		clot_rate = 0
		wound_flags = (FLESH_WOUND | MANGLES_FLESH)
		treatable_tool = TOOL_WELDER

	return ..()
// BLUEMOON ADD END
