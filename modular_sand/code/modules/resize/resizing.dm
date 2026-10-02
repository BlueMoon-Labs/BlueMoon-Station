//handle the big steppy, except nice
/mob/living/proc/handle_micro_bump_helping(mob/living/target)
	if(ishuman(src))
		var/mob/living/carbon/human/user = src

		if(target.pulledby == user)
			return FALSE

		//Micro is on a table.
		if(locate(/obj/structure/table) in target.loc)
			return TRUE

		//Both small.
		if(get_size(user) <= RESIZE_A_TINYMICRO && get_size(target) <= RESIZE_A_TINYMICRO)
			now_pushing = 0
			//user.forceMove(target.loc) BLUEMOON REMOVAL - пересено в micro_move_to_target_turf
			micro_move_to_target_turf(target) // BLUEMOON ADD
			return TRUE

		//Doing messages
		if(COMPARE_SIZES(user, target) >= 1.9) //if the initiator is twice the size of the micro // BLUEMOON EDIT - было >= 2
			// BLUEMOON ADD START - небольшие персонажи мешают крупному тянуть за собой кого-либо
			if(pulling)
				if(COMPARE_SIZES(user, target) < 2.2) // Разница слишком велика, чтобы мешать тянуть
					if(!(world.time % 3))
						to_chat(src, span_warning("[target] слишком высокий - его нужно раздавить, чтобы протащить [pulling]."))
					return TRUE
			// BLUEMOON ADD END
			now_pushing = 0

			//user.forceMove(target.loc) BLUEMOON REMOVAL - пересено в micro_move_to_target_turf
			micro_move_to_target_turf(target) // BLUEMOON ADD

			//Smaller person being stepped on
			if(iscarbon(src))
				if(istype(user) && user.dna.features["taur"] == "Naga" || user.dna.features["taur"] == "Tentacle")
					target.visible_message("<span class='notice'>[src] carefully slithers around [target].</span>", "<span class='notice'>[src]'s huge tail slithers besides you.</span>")
				else
					target.visible_message("<span class='notice'>[src] carefully steps over [target].</span>", "<span class='notice'>[src] steps over you carefully.</span>")
				return TRUE

		//Smaller person stepping under a larger person
		if(COMPARE_SIZES(target, user) >= 1.85 && target.a_intent == INTENT_HELP) // BLUEMOON EDIT - добавлена проверка на интент и изменена проверка на размер, было >= 2
			//user.forceMove(target.loc) BLUEMOON REMOVAL - пересено в micro_move_to_target_turf
			micro_move_to_target_turf(target) // BLUEMOON ADD
			now_pushing = 0
			micro_step_under(target)
			return TRUE

//Stepping on disarm intent -- TO DO, OPTIMIZE ALL OF THIS SHIT
/mob/living/proc/handle_micro_bump_other(mob/living/target)
	ASSERT(isliving(target))
	if(ishuman(src))
		var/mob/living/carbon/human/user = src

		if(target.pulledby == user)
			return FALSE

	//If on a table, don't
		if(locate(/obj/structure/table) in target.loc)
			return TRUE

	//Both small
		if(get_size(user) <= RESIZE_A_TINYMICRO && get_size(target) <= RESIZE_A_TINYMICRO)
			now_pushing = 0
			//user.forceMove(target.loc) BLUEMOON REMOVAL - пересено в micro_move_to_target_turf
			micro_move_to_target_turf(target) // BLUEMOON ADD
			return TRUE

		if(COMPARE_SIZES(user, target) >= 1.6) // BLUEMOON CHANGES
			// BLUEMOON ADD START
			var/can_harm = TRUE
			if(user.mob_weight < MOB_WEIGHT_NORMAL && get_size(user) > 1 && get_size(target) > 0.6) //Лёгкие большие персонажи не могут навредить кому-либо больше 60%
				can_harm = FALSE
			if(target.mind?.martial_art?.id && target.mind.martial_art.can_use(target) && can_harm) // нельзя давить тех, кто обучен и может применять боевые искусства
			// У людей по умолчанию есть плейсходерное боевое искусство, но у него нет ID. Потому проверка на него, т.к. любое другое ID изменяет
				if(target.a_intent != INTENT_HELP)
					now_pushing = 0
					micro_move_to_target_turf(target)
					log_combat(user, target, "failed (martial art) to step on", addition="[user.a_intent] trample")
					target.visible_message(\
						span_danger("[target] уворачивается от попытки [src] наступить на не[target.gender == MALE ? "го" : "ё"]!"),\
						span_danger("Вы уворачиваетесь от попытки [src] наступить на вас благодаря своему боевому искусству!"),
						vision_distance = 3,
						target = user, target_message = span_danger("[target] умело уворачивается от вашей попытки наступить на него!"))
					playsound(loc, 'sound/weapons/punchmiss.ogg', 25, 1, -1)
					return TRUE
			// BLUEMOON ADD END

			log_combat(user, target, "stepped on", addition="[user.a_intent] trample")
			if(user.a_intent == "disarm" && CHECK_MOBILITY(user, MOBILITY_MOVE) && !user.buckled && can_harm)
				now_pushing = 0
				//user.forceMove(target.loc) BLUEMOON REMOVAL - пересено в micro_move_to_target_turf
				micro_move_to_target_turf(target) // BLUEMOON ADD
				user.sizediffStamLoss(target)
				user.add_movespeed_modifier(/datum/movespeed_modifier/stomp, TRUE) //Full stop
				addtimer(CALLBACK(user, TYPE_PROC_REF(/mob, remove_movespeed_modifier), MOVESPEED_ID_STOMP, TRUE), 3) //0.3 seconds
				if(iscarbon(user))
					if(istype(user) && user.dna.features["taur"] == "Naga" || user.dna.features["taur"] == "Tentacle")
						target.visible_message("<span class='danger'>[src] carefully rolls their tail over [target]!</span>", "<span class='danger'>[src]'s huge tail rolls over you!</span>")
					else
						target.visible_message("<span class='danger'>[src] carefully steps on [target]!</span>", "<span class='danger'>[src] steps onto you with force!</span>")
					return TRUE

			if(user.a_intent == "harm" && CHECK_MOBILITY(user, MOBILITY_MOVE) && !user.buckled && can_harm)
				now_pushing = 0
				//user.forceMove(target.loc) BLUEMOON REMOVAL - пересено в micro_move_to_target_turf
				micro_move_to_target_turf(target) // BLUEMOON ADD
				user.sizediffStamLoss(target)
				user.sizediffBruteloss(target)
				playsound(loc, 'sound/misc/splort.ogg', 50, 1)
				user.add_movespeed_modifier(/datum/movespeed_modifier/stomp, TRUE)
				addtimer(CALLBACK(user, TYPE_PROC_REF(/mob, remove_movespeed_modifier), MOVESPEED_ID_STOMP, TRUE), 10) //1 second
				//user.Stun(20)
				// BLUEMOON ADDITION START - тяжёлые персонажи наносят больше урона и на дольше станят, но сами получают стан
				switch(user.mob_weight)
					if(MOB_WEIGHT_HEAVY_SUPER)
						user.Immobilize(1 SECONDS)
					if(MOB_WEIGHT_HEAVY)
						user.Immobilize(0.5 SECONDS)
				// BLUEMOON ADDITION END
				if(iscarbon(user))
					if(istype(user) && (user.dna.features["taur"] == "Naga" || user.dna.features["taur"] == "Tentacle"))
						target.visible_message("<span class='danger'>[src] mows down [target] under their tail!</span>", "<span class='userdanger'>[src] plows their tail over you mercilessly!</span>")
					else
						target.visible_message("<span class='danger'>[src] slams their foot down on [target], crushing them!</span>", "<span class='userdanger'>[src] crushes you under their foot!</span>")
					return TRUE

			if(user.a_intent == "grab" && CHECK_MOBILITY(user, MOBILITY_MOVE) && !user.buckled && can_harm)
				now_pushing = 0
				//user.forceMove(target.loc) BLUEMOON REMOVAL - пересено в micro_move_to_target_turf
				micro_move_to_target_turf(target) // BLUEMOON ADD
				user.sizediffStamLoss(target)
				user.sizediffStun(target)
				user.add_movespeed_modifier(/datum/movespeed_modifier/stomp, TRUE)
				addtimer(CALLBACK(user, TYPE_PROC_REF(/mob, remove_movespeed_modifier), MOVESPEED_ID_STOMP, TRUE), 7)//About 3/4th a second
				if(iscarbon(user))
					var/feetCover = (user.wear_suit && (user.wear_suit.body_parts_covered & FEET)) || (user.w_uniform && (user.w_uniform.body_parts_covered & FEET) || (user.shoes && (user.shoes.body_parts_covered & FEET)))
					if(feetCover)
						if(user?.dna?.features["taur"] == "Naga" || user?.dna?.features["taur"] == "Tentacle")
							target.visible_message("<span class='danger'>[src] pins [target] under their tail!</span>", "<span class='danger'>[src] pins you beneath their tail!</span>")
						else
							target.visible_message("<span class='danger'>[src] pins [target] helplessly underfoot!</span>", "<span class='danger'>[src] pins you underfoot!</span>")
						return TRUE
					else
						if(user?.dna?.features["taur"] == "Naga" || user?.dna?.features["taur"] == "Tentacle")
							target.visible_message("<span class='danger'>[user] snatches up [target] underneath their tail!</span>", "<span class='userdanger'>[src]'s tail winds around you and snatches you in its coils!</span>")
							//target.mob_pickup_micro_feet(user)
							SEND_SIGNAL(target, COMSIG_MICRO_PICKUP_FEET, user)
						else
							target.visible_message("<span class='danger'>[user] stomps down on [target], curling their toes and picking them up!</span>", "<span class='userdanger'>[src]'s toes pin you down and curl around you, picking you up!</span>")
							//target.mob_pickup_micro_feet(user)
							SEND_SIGNAL(target, COMSIG_MICRO_PICKUP_FEET, user)
						return TRUE

		if(COMPARE_SIZES(target, user) >= 1.85 && target.a_intent == INTENT_HELP) // BLUEMOON EDIT - добавлена проверка на интент и изменена проверка на размер, было >= 2
			//user.forceMove(target.loc) BLUEMOON REMOVAL - пересено в micro_move_to_target_turf
			micro_move_to_target_turf(target) // BLUEMOON ADD
			now_pushing = 0
			micro_step_under(target)
			return TRUE

/mob/living/proc/macro_step_around(mob/living/target)
	if(ishuman(src))
		var/mob/living/carbon/human/validmob = src
		if(validmob?.dna?.features["taur"] == "Naga" || validmob?.dna?.features["taur"] == "Tentacle")
			visible_message("<span class='notice'>[validmob] carefully slithers around [target].</span>", "<span class='notice'>You carefully slither around [target].</span>")
		else
			visible_message("<span class='notice'>[validmob] carefully steps around [target].</span>", "<span class='notice'>You carefully steps around [target].</span>")

//smaller person stepping under another person... TO DO, fix and allow special interactions with naga legs to be seen
/mob/living/proc/micro_step_under(mob/living/target)
	if(ishuman(src))
		var/mob/living/carbon/human/validmob = src
		if(validmob?.dna?.features["taur"] == "Naga" || validmob?.dna?.features["taur"] == "Tentacle")
			visible_message("<span class='notice'>[validmob] bounds over [target]'s tail.</span>", "<span class='notice'>You jump over [target]'s thick tail.</span>")
		else
			visible_message("<span class='notice'>[validmob] runs between [target]'s legs.</span>", "<span class='notice'>You run between [target]'s legs.</span>")

//Proc for scaling stamina damage on size difference
/mob/living/carbon/proc/sizediffStamLoss(mob/living/carbon/target)
	var/S = COMPARE_SIZES(src, target) * 5 //macro divided by micro, times 25 // BLUEMOON CHANGES - было 25, стало 5
	// BLUEMOON ADDITION AHEAD
	if(src.mob_weight < MOB_WEIGHT_NORMAL && get_size(src) > 1) //лёгкие большие персонажи считаются по размеру за 1
		S = abs((1 / get_size(target))) * 5
	//изменение конечного результата от веса персонажа
	S *= (1 + ((src.mob_weight - MOB_WEIGHT_NORMAL) * 0.5))
	target.apply_damage(S, STAMINA, BODY_ZONE_CHEST) // дополнительный урон по стамине за нерф опрокидывания на пол, т.к. чрезвычайно сильное в оригинале
	target.Dizzy(5)
	// BLUEMOON ADDITION END
	target.Knockdown(S/2) //final result in stamina knockdown // BLUEMOON CHANGES


//Proc for scaling stuns on size difference (for grab intent)
/mob/living/carbon/proc/sizediffStun(mob/living/carbon/target)
	var/T = COMPARE_SIZES(src, target) * 2 //Macro divided by micro, times 2
	// BLUEMOON ADDITION AHEAD
	if(src.mob_weight < MOB_WEIGHT_NORMAL && get_size(src) > 1) //лёгкие большие персонажи считаются по размеру за 1
		T = abs((1 / get_size(target))) * 2
	//изменение конечного результата от веса персонажа
	T *= (1 + ((src.mob_weight - MOB_WEIGHT_NORMAL) * 0.5))
	// BLUEMOON ADDITION END
	target.Stun(T)

//Proc for scaling brute damage on size difference
/mob/living/carbon/proc/sizediffBruteloss(mob/living/carbon/target)
	var/B = COMPARE_SIZES(src, target) * 3 //macro divided by micro, times 3

	// BLUEMOON ADDITION AHEAD
	if(src.mob_weight < MOB_WEIGHT_NORMAL && get_size(src) > 1) //лёгкие большие персонажи считаются по размеру за 1
		B = abs((1 / get_size(target))) * 3

	// усиление конечного результата за вес выше среднего
	B *= max(1, src.mob_weight - MOB_WEIGHT_NORMAL)

	// Сверхтяжёлые персонажи размером 200% и выше наносят огромный урон при наступании
	if(src.mob_weight == MOB_WEIGHT_HEAVY_SUPER && get_size(src) >= 2)
		B *= 5 * (get_size(src) / 2)

	// BLUEMOON ADDITION END

	target.adjustBruteLoss(B) //final result in brute loss

//Proc for instantly grabbing valid size difference. Code optimizations soon(TM)
/*
/mob/living/proc/sizeinteractioncheck(mob/living/target)
	if(abs(get_effective_size()/target.get_effective_size())>=2.0 && get_effective_size()>target.get_effective_size())
		return FALSE
	else
		return TRUE
*/
//Clothes coming off at different sizes, and health/speed/stam changes as well
