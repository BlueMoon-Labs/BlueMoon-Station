/datum/disease/weightlessness
	name = "Localized Weightloss Malfunction"
	max_stages = 4
	spread_text = "On Contact"
	spread_flags = DISEASE_SPREAD_BLOOD | DISEASE_SPREAD_CONTACT_SKIN | DISEASE_SPREAD_CONTACT_FLUIDS
	cure_text = "Liquid dark matter"
	cures = list(/datum/reagent/liquid_dark_matter)
	agent = "Sub-quantum DNA Repulsion"
	viable_mobtypes = list(/mob/living/carbon/human)
	disease_flags = CAN_CARRY|CAN_RESIST|CURABLE
	permeability_mod = 0.5
	cure_chance = 4
	desc = "This disease results in a low level rewrite of the patient's bioelectric signature, causing them to reject the phenomena of \"weight\". Ingestion of liquid dark matter tends to stabilize the field."
	severity = DISEASE_SEVERITY_MEDIUM
	infectable_biotypes = MOB_ORGANIC


/datum/disease/weightlessness/stage_act()
	. = ..()
	if(!.)
		return

	switch(stage)
		if(1)
			if(prob(1))
				to_chat(affected_mob, span_danger("You almost lose your balance for a second."))
		if(2)
			if(prob(3) && !HAS_TRAIT_FROM(affected_mob, TRAIT_MOVE_FLOATING, NO_GRAVITY_TRAIT))
				to_chat(affected_mob, span_danger("You feel yourself lift off the ground."))
				affected_mob.reagents.add_reagent(/datum/reagent/gravitum, 1)

		if(4)
			if(prob(3))
				to_chat(affected_mob, span_danger("You feel sick as the world starts moving around you."))
				affected_mob.Dizzy(30)
			if(prob(8) && !HAS_TRAIT_FROM(affected_mob, TRAIT_MOVE_FLOATING, NO_GRAVITY_TRAIT))
				to_chat(affected_mob, span_danger("You suddenly lift off the ground."))
				affected_mob.reagents.add_reagent(/datum/reagent/gravitum, 5)

/datum/disease/weightlessness/cure(add_resistance)
	. = ..()
	affected_mob.vomit(95, FALSE, TRUE, 1, TRUE, purge_ratio = 0.4)
	to_chat(affected_mob, span_danger("You fall to the floor as your body stops rejecting gravity."))
