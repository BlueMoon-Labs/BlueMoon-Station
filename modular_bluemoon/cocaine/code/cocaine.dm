/datum/chemical_reaction/powder_cocaine
	name = "Powder Cocaine"
	id = "powder_cocaine"
	is_cold_recipe = TRUE
	required_reagents = list(/datum/reagent/drug/cocaine = 10)
	required_temp = 250
	mix_message = "The solution freezes into a powder!"
	mob_react = FALSE

/datum/chemical_reaction/powder_cocaine/on_reaction(datum/reagents/holder, multiplier)
	var/location = get_turf(holder.my_atom)
	for(var/i = 1, i <= multiplier, i++)
		new /obj/item/reagent_containers/cocaine(location)

/datum/chemical_reaction/freebase_cocaine
	name = "Freebase Cocaine"
	id = "freebase_cocaine"
	required_reagents = list(/datum/reagent/drug/cocaine = 10, /datum/reagent/water = 5, /datum/reagent/ash = 10)
	required_temp = 480
	mob_react = FALSE

/datum/chemical_reaction/freebase_cocaine/on_reaction(datum/reagents/holder, multiplier)
	var/location = get_turf(holder.my_atom)
	for(var/i = 1, i <= multiplier, i++)
		new /obj/item/reagent_containers/crack(location)

/datum/reagent/drug/cocaine
	name = "cocaine"
	description = "A powerful stimulant extracted from coca leaves. Reduces stun times, but causes drowsiness and severe brain damage if overdosed."
	color = "#ffffff"
	overdose_threshold = 20
	addiction_threshold = 10
	pH = 9
	taste_description = "bitterness"

/datum/reagent/drug/cocaine/on_mob_metabolize(mob/living/containing_mob)
	. = ..()
	containing_mob.add_movespeed_modifier(/datum/movespeed_modifier/reagent/stimulants)
	ADD_TRAIT(containing_mob, TRAIT_BATON_RESISTANCE, type)
	ADD_TRAIT(containing_mob, TRAIT_TASED_RESISTANCE, type)
	ADD_TRAIT(containing_mob, TRAIT_DISABLER_RESISTANCE, type)

/datum/reagent/drug/cocaine/on_mob_end_metabolize(mob/living/containing_mob)
	. = ..()
	containing_mob.remove_movespeed_modifier(/datum/movespeed_modifier/reagent/stimulants)
	REMOVE_TRAIT(containing_mob, TRAIT_BATON_RESISTANCE, type)
	REMOVE_TRAIT(containing_mob, TRAIT_TASED_RESISTANCE, type)
	REMOVE_TRAIT(containing_mob, TRAIT_DISABLER_RESISTANCE, type)

/datum/reagent/drug/cocaine/on_mob_life(mob/living/carbon/affected_mob, delta_time, times_fired)
	. = ..()
	if(DT_PROB(2.5, delta_time))
		var/high_message = pick("You feel jittery.", "You feel like you gotta go fast.", "You feel like you need to step it up.")
		to_chat(affected_mob, span_notice("[high_message]"))
	SEND_SIGNAL(affected_mob, COMSIG_ADD_MOOD_EVENT, "zoinked", /datum/mood_event/stimulant_heavy, name)
	affected_mob.AdjustStun(-1.5 SECONDS * delta_time)
	affected_mob.AdjustKnockdown(-1.5 SECONDS * delta_time)
	affected_mob.AdjustUnconscious(-1.5 SECONDS * delta_time)
	affected_mob.AdjustImmobilized(-1.5 SECONDS * delta_time)
	affected_mob.AdjustParalyzed(-1.5 SECONDS * delta_time)
	affected_mob.adjustStaminaLoss(-2 * REM * delta_time, 0)
	if(DT_PROB(2.5, delta_time))
		affected_mob.emote("shiver")

/datum/reagent/drug/cocaine/overdose_start(mob/living/affected_mob, metabolization_ratio)
	to_chat(affected_mob, span_userdanger("Your heart beats is beating so fast, it hurts..."))

/datum/reagent/drug/cocaine/overdose_process(mob/living/affected_mob, delta_time, times_fired)
	. = ..()
	affected_mob.adjustToxLoss(1 * REM * delta_time, 0)
	affected_mob.adjustOrganLoss(ORGAN_SLOT_HEART, (rand(10, 20) / 10) * REM * delta_time)
	affected_mob.Jitter(5)
	if(DT_PROB(2.5, delta_time))
		affected_mob.emote(pick("twitch","drool"))
	if(!HAS_TRAIT(affected_mob, TRAIT_FLOORED))
		if(DT_PROB(1.5, delta_time))
			affected_mob.visible_message(span_danger("[affected_mob] collapses onto the floor!"))
			affected_mob.Paralyze(135, TRUE)
			affected_mob.drop_all_held_items()

/datum/reagent/drug/cocaine/addiction_act_stage1(mob/living/M)
	M.Jitter(5)
	if(prob(20))
		M.emote(pick("twitch","drool"))
	..()

/datum/reagent/drug/cocaine/addiction_act_stage2(mob/living/M)
	M.Jitter(10)
	M.Dizzy(10)
	if(prob(30))
		M.emote(pick("twitch","drool","moan"))
	..()

/datum/reagent/drug/cocaine/addiction_act_stage3(mob/living/M)
	M.Jitter(15)
	M.Dizzy(15)
	M.adjustStaminaLoss(5, 0)
	if(prob(40))
		M.emote(pick("twitch","drool","moan"))
	..()

/datum/reagent/drug/cocaine/addiction_act_stage4(mob/living/M)
	M.Jitter(20)
	M.Dizzy(20)
	M.adjustToxLoss(5, 0)
	M.adjustOrganLoss(ORGAN_SLOT_BRAIN, rand(1, 3))
	if(prob(50))
		M.emote(pick("twitch","drool","moan","collapse"))
	..()

/datum/reagent/drug/cocaine/freebase_cocaine
	name = "freebase cocaine"
	description = "A smokable form of cocaine."
	color = "#f0e6bb"

/datum/reagent/drug/cocaine/powder_cocaine
	name = "powder cocaine"
	description = "The powder form of cocaine."
	color = "#ffffff"
