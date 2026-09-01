/datum/reagent/consumable/semen/on_mob_add(mob/living/carbon/M)
	. = ..()

	// Check for D4C quirk
	if(HAS_TRAIT(M,TRAIT_DUMB_CUM) && !istype(src, /datum/reagent/consumable/semen/femcum))
		// Define quirk entry
		var/datum/quirk/dumb4cum/quirk_target = locate() in M.roundstart_quirks

		// Remove reset timer
		quirk_target.uncrave()

/datum/reagent/consumable/ethanol/cum_in_a_hot_tub/semen/on_mob_add(mob/living/carbon/M)
	. = ..()

	// Check for D4C quirk
	if(HAS_TRAIT(M,TRAIT_DUMB_CUM))
		// Define quirk entry
		var/datum/quirk/dumb4cum/quirk_target = locate() in M.roundstart_quirks

		// Remove reset timer
		quirk_target.uncrave(FALSE) //diluted, so no "wow effect".

//incubus and succubus additions below
/datum/reagent/consumable/semen/on_mob_life(mob/living/carbon/M)
	. = ..()
	if(HAS_TRAIT(M,TRAIT_SUCCUBUS))
		M.adjust_nutrition(1)

/datum/reagent/consumable/ethanol/cum_in_a_hot_tub/semen/on_mob_life(mob/living/carbon/M)
	. = ..()
	if(HAS_TRAIT(M,TRAIT_SUCCUBUS))
		M.adjust_nutrition(0.5)

/datum/reagent/consumable/milk/on_mob_life(mob/living/carbon/M)
	. = ..()
	if(HAS_TRAIT(M,TRAIT_INCUBUS))
		M.adjust_nutrition(1.5)

/datum/reagent/blood/reaction_mob(mob/living/carbon/M, method=TOUCH, reac_volume, affected_bodypart)
	. = ..()
	// Check if ingested
	if(method != INGEST)
		return

	// Check if blood data exists
	if(!data)
		// Log warning and return
		log_game("[M] attempted to ingest blood that had no data!")
		return

	// Check for Bloodfledge quirk
	if(HAS_TRAIT(M,TRAIT_BLOODFLEDGE))
		// Check for own blood
		if(data["donor"] == WEAKREF(M))
			// Warn user and return
			to_chat(M, span_warning("You gain no nourishment from the familiar blood..."))
			return

		// Add nutrition reagent
		// Reduced to 50%
		M.reagents.add_reagent(/datum/reagent/consumable/notriment, reac_volume*0.5)

/datum/reagent/water/holywater/on_mob_add(mob/living/carbon/M)
	. = ..()

	// Check for Hallowed.
	if(HAS_TRAIT(M,TRAIT_HALLOWED))
		// Add positive mood.
		SEND_SIGNAL(M, COMSIG_ADD_MOOD_EVENT, "fav_food", /datum/mood_event/favorite_food)

/datum/reagent/water/holywater/on_mob_life(mob/living/carbon/M)
	// Return normally.
	. = ..()

	// Makes holy water disgusting and hungering for bloodfledges
	// Directly antithetic to the effects of blood
	if(HAS_TRAIT(M,TRAIT_BLOODFLEDGE))
		M.adjust_disgust(2)
		M.adjust_nutrition(-6)

	// Cursed blood effect moved here
	if(HAS_TRAIT(M, TRAIT_CURSED_BLOOD))
		// Wait for stuttering, to match old effect
		if(!M.stuttering)
			return

		// Escape clause: 12% chance to continue
		if(!prob(12))
			return

		// Character speaks nonsense
		M.say(pick("Somebody help me...","Unshackle me please...","Anybody... I've had enough of this dream...","The night blocks all sight...","Oh, somebody, please..."), forced = "holy water")

		// Escape clause: 10% chance to continue
		if(!prob(10))
			return

		// Character has a seisure
		M.visible_message("<span class='danger'>[M] падает в припадке!</span>", "<span class='userdanger'>У вас начался припадок!</span>")
		M.Unconscious(120)
		to_chat(M, "<span class='cultlarge'>[pick("The moon is close. It will be a long hunt tonight.", "Ludwig, why have you forsaken me?", \
		"The night is near its end...", "Fear the blood...")]</span>")

		// Apply damage
		M.adjustToxLoss(1, 0)
		M.adjustFireLoss(1, 0)

		// Escape clause: 25% chance to continue
		if(!prob(25))
			return

		// Spontaneous combustion
		M.IgniteMob()

// This is used by 'alternative food' quirks
// It should not be used for any other purpose
/datum/reagent/consumable/notriment
	name = "Strange Nutriment"
	description = "An exotic form of nutriment produced by unusual digestive systems."
	reagent_state = SOLID
	nutriment_factor = 5					// From 4
	metabolization_rate = 1					// From 0.4
	max_nutrition = NUTRITION_LEVEL_FAT		// From INFINITY
	color = "#66552f" // rgb: 102, 85, 47

/datum/reagent/consumable/notriment/reaction_mob(mob/living/carbon/M, method=TOUCH, reac_volume, affected_bodypart)
	// Check if mob can process food
	if(!HAS_TRAIT(M, TRAIT_NO_PROCESS_FOOD))
		// Warn user
		to_chat(M, span_warning("Your body is incapable of processing the Strange Nutriment!"))

		// Remove reagent
		M.reagents.remove_reagent(/datum/reagent/consumable/notriment/, reac_volume)

		// Ignore this mob
		return

	// Return normally
	. = ..()

/datum/reagent/consumable/notriment/on_mob_life(mob/living/carbon/M)
	. = ..()

	// Add nutrition
	M.adjust_nutrition(nutriment_factor, max_nutrition)

/datum/reagent/consumable/ethanol/vodka/on_mob_add(mob/living/carbon/M)
	. = ..()

	// Check for Hallowed.
	if(HAS_TRAIT(M,TRAIT_RUSSIAN))
		// Add positive mood.
		SEND_SIGNAL(M, COMSIG_ADD_MOOD_EVENT, "fav_food", /datum/mood_event/favorite_food/russian)

/datum/reagent/consumable/ethanol/vodka/on_mob_life(mob/living/carbon/M)
	. = ..()
	//Makes holy water generally good for Hallowed users.
	//Holy water is tough to get in comparison to other medicine anyways.
	if(HAS_TRAIT(M,TRAIT_RUSSIAN))
		// Reduce disgust.
		M.adjust_disgust(-3)

/datum/reagent/consumable/ethanol/vodka/on_mob_metabolize(mob/living/L)
	. = ..()

	var/mob/living/carbon/human/M = L
	if(HAS_TRAIT(M,TRAIT_RUSSIAN))
		M.mob_light(_color = LIGHT_COLOR_HOLY_MAGIC, _range = 2, _duration = 100)
		var/mutable_appearance/forbearance = mutable_appearance('icons/effects/genetics.dmi', "servitude", -MUTATIONS_LAYER)
		M.add_overlay(forbearance)

		M.gain_trauma(/datum/brain_trauma/special/godwoken, TRAUMA_RESILIENCE_ABSOLUTE)

/datum/reagent/consumable/ethanol/vodka/on_mob_end_metabolize(mob/living/L)
	. = ..()

	var/mob/living/carbon/human/M = L
	if(HAS_TRAIT(L, TRAIT_RUSSIAN))
		var/mutable_appearance/forbearance = mutable_appearance('icons/effects/genetics.dmi', "servitude", -MUTATIONS_LAYER)
		M.cut_overlay(forbearance)

		M.cure_trauma_type(/datum/brain_trauma/special/godwoken, TRAUMA_RESILIENCE_ABSOLUTE)
