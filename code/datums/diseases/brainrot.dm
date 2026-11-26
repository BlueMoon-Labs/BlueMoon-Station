/datum/disease/brainrot
	name = "Brainrot"
	max_stages = 4
	spread_text = "При контакте"
	spread_flags = DISEASE_SPREAD_BLOOD | DISEASE_SPREAD_CONTACT_SKIN | DISEASE_SPREAD_CONTACT_FLUIDS
	cure_text = "Маннитол"
	cures = list(/datum/reagent/medicine/mannitol)
	agent = "Cryptococcus Cosmosis"
	viable_mobtypes = list(/mob/living/carbon/human)
	cure_chance = 15//higher chance to cure, since two reagents are required
	desc = "Эта болезнь разрушает клетки мозга, вызывая мозговую лихорадку, некроз мозга и общую интоксикацию."
	required_organs = list(/obj/item/organ/brain)
	severity = DISEASE_SEVERITY_HARMFUL

/datum/disease/brainrot/stage_act() //Removed toxloss because damaging diseases are pretty horrible. Last round it killed the entire station because the cure didn't work -- Urist -ACTUALLY Removed rather than commented out, I don't see it returning - RR
	..()

	switch(stage)
		if(2)
			if(prob(2))
				affected_mob.emote("blink")
			if(prob(2))
				affected_mob.emote("yawn")
			if(prob(2))
				to_chat(affected_mob, "<span class='danger'>Вы не чувствуете себя собой.</span>")
			if(prob(5))
				affected_mob.adjustOrganLoss(ORGAN_SLOT_BRAIN, 1, 170)
				affected_mob.updatehealth()
		if(3)
			if(prob(2))
				affected_mob.emote("stare")
			if(prob(2))
				affected_mob.emote("drool")
			if(prob(10))
				affected_mob.adjustOrganLoss(ORGAN_SLOT_BRAIN, 2, 170)
				affected_mob.updatehealth()
				if(prob(2))
					to_chat(affected_mob, "<span class='danger'>Вы пытаетесь вспомнить что-то важное... но не можете.</span>")

		if(4)
			if(prob(2))
				affected_mob.emote("stare")
			if(prob(2))
				affected_mob.emote("drool")
			if(prob(15))
				affected_mob.adjustOrganLoss(ORGAN_SLOT_BRAIN, 3, 170)
				affected_mob.updatehealth()
				if(prob(2))
					to_chat(affected_mob, "<span class='danger'>Странный звон заполняет голову, унося все мысли.</span>")
			if(prob(3))
				to_chat(affected_mob, "<span class='danger'>Вы теряете сознание...</span>")
				affected_mob.visible_message("<span class='warning'>[affected_mob] внезапно падает</span>")
				affected_mob.Unconscious(rand(100,200))
				if(prob(1))
					affected_mob.emote("snore")
			if(prob(15))
				affected_mob.stuttering += 3

	return
