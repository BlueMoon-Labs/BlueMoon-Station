#define STOMP_DELAY 8 // 0.8 секунд

/datum/element/mob_holder/micro/proc/mob_try_alt_action(mob/living/carbon/source, mob/living/carbon/user)
	SIGNAL_HANDLER_DOES_SLEEP // alt-click реализованы через COMSIG_ALT_CLICK

	switch(user.a_intent)
		if(INTENT_GRAB)
			mob_try_pickup_micro(source, user)
		if(INTENT_DISARM)
			mob_try_pin_micro(source, user)
		if(INTENT_HARM)
			mob_try_stomp_micro(source, user)

/*
Наступание на кого-либо в дизарме
*/

/datum/element/mob_holder/micro/proc/mob_try_pin_micro(mob/living/carbon/target, mob/living/carbon/user)
	if(!basic_step_on_checks(target, user))
		return FALSE // игроку выдаются причины провала внутри функции

	log_combat(user, target, "stepped on", addition="[user.a_intent] trample")

	user.now_pushing = 0
	user.micro_move_to_target_turf(target)
	user.sizediffStamLoss(target)
	user.add_movespeed_modifier(/datum/movespeed_modifier/stomp, TRUE) //Full stop
	addtimer(CALLBACK(user, TYPE_PROC_REF(/mob, remove_movespeed_modifier), "STEPPY", TRUE), 3) //0.3 seconds
	if(iscarbon(user))
		if(istype(user) && user.dna.features["taur"] == "Naga" || user.dna.features["taur"] == "Tentacle")
			target.visible_message("<span class='danger'>[user] carefully rolls their tail over [target]!</span>", "<span class='danger'>[user]'s huge tail rolls over you!</span>")
		else
			target.visible_message("<span class='danger'>[user] carefully steps on [target]!</span>", "<span class='danger'>[user] steps onto you with force!</span>")
		return TRUE

/*
Наступание на кого-либо в харме
*/

/datum/element/mob_holder/micro/proc/mob_try_stomp_micro(mob/living/carbon/target, mob/living/carbon/user)
	if(!basic_step_on_checks(target, user))
		return FALSE // игроку выдаются причины провала внутри функции

	log_combat(user, target, "stepped on", addition="[user.a_intent] trample")

	user.now_pushing = 0
	user.micro_move_to_target_turf(target)
	user.sizediffStamLoss(target)
	user.sizediffBruteloss(target)
	playsound(user.loc, 'sound/misc/splort.ogg', 50, 1)
	user.add_movespeed_modifier(/datum/movespeed_modifier/stomp, TRUE)
	addtimer(CALLBACK(user, TYPE_PROC_REF(/mob, remove_movespeed_modifier), "STEPPY", TRUE), 3) //0.3 second
	if(iscarbon(user))
		if(HAS_TRAIT(user, TRAIT_NAGA_ANATOMY) || (istype(user) && (user.dna.features["taur"] == "Naga" || user.dna.features["taur"] == "Tentacle")))
			target.visible_message(span_danger("[user] придавливает [target] хвостом!"), span_userdanger("[user] безжалостно придавливает вас хвостом!"))
		else
			target.visible_message("<span class='danger'>[user] slams their foot down on [target], crushing them!</span>", "<span class='userdanger'>[user] crushes you under their foot!</span>")
		return TRUE

/*
Базовые проверки для наступания на кого-то
*/

/datum/element/mob_holder/micro/proc/basic_step_on_checks(mob/living/carbon/target, mob/living/carbon/user)
	if(user.buckled)
		to_chat(user, span_warning("Я не могу наступить на [target], пока я пристегнут[target.ru_a()]!"))
		return FALSE

	if(target.buckled)
		to_chat(user, span_warning("Я не могу наступить на [target], пока [target.gender == G_FEMALE ? "она" : "он"] пристегнут[target.ru_a()]!"))
		return FALSE

	var/turf/target_turf = target.loc
	if(target_turf.is_blocked_turf(TRUE, user))
		to_chat(user, span_warning("Что-то мешает мне наступить на [target]!"))
		return FALSE

	if(!CHECK_MOBILITY(user, MOBILITY_MOVE))
		to_chat(user, span_warning("Я не могу двигаться!"))
		return FALSE
	if(!user.get_num_supporting_limbs())
		to_chat(user, span_warning("Для этого нужна действующая нога или опорный хвост."))
		return FALSE

	if(!user.CheckActionCooldown(CLICK_CD_MELEE))
		return FALSE

	user.DelayNextAction(CLICK_CD_MELEE)

	if(!do_mob(user, target, STOMP_DELAY))
		return FALSE
	if(!user.get_num_supporting_limbs())
		return FALSE

	if(!(COMPARE_SIZES(user, target) >= 1.6))
		to_chat(user, span_warning("Разницы в росте недостаточно, чтобы раздавить!"))
		return FALSE

	if(user.mob_weight < MOB_WEIGHT_NORMAL && get_size(user) > 1 && get_size(target) > 0.6) //Лёгкие большие персонажи не могут навредить кому-либо больше 60
		to_chat(user, span_warning("Я вешу слишком мало, чтобы наступить на [target]!"))
		return FALSE

	if(target.mind?.martial_art?.id && target.mind.martial_art.can_use(target)) // нельзя давить тех, кто обучен и может применять боевые искусства
	// У людей по умолчанию есть плейсходерное боевое искусство, но у него нет ID. Потому проверка на него, т.к. любое другое ID изменяет
		if(target.a_intent != INTENT_HELP)
			user.now_pushing = 0
			user.micro_move_to_target_turf(target)
			log_combat(user, target, "failed (martial art) to step on", addition="[user.a_intent] trample")
			target.visible_message(\
				span_danger("[target] уворачивается от попытки [user] наступить на не[target.gender == MALE ? "го" : "ё"]!"),\
				span_danger("Вы уворачиваетесь от попытки [user] наступить на вас благодаря своему боевому искусству!"),
				vision_distance = 3,
				target = user, target_message = span_danger("[target] умело уворачивается от вашей попытки наступить на него!"))
			playsound(user.loc, 'sound/weapons/punchmiss.ogg', 25, 1, -1)
			return FALSE

	return TRUE

#undef STOMP_DELAY
