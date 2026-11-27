/datum/disease/tuberculosis
	form = "Disease"
	name = "Fungal tuberculosis"
	max_stages = 5
	spread_text = "Воздушно-капельный"
	cure_text = "Спейсациллин и сальбутамол"
	cures = list(/datum/reagent/medicine/spaceacillin, /datum/reagent/medicine/salbutamol)
	agent = "Fungal Tubercle bacillus Cosmosis"
	viable_mobtypes = list(/mob/living/carbon/human)
	cure_chance = 5//like hell are you getting out of hell
	desc = "Редкий высокозаразный вирулентный вирус. Существует мало образцов, по слухам, выращиваемых и культивируемых тайными специалистами по биооружию. Вызывает лихорадку, кровавую рвоту, повреждение лёгких, потерю веса и усталость."
	required_organs = list(/obj/item/organ/lungs)
	severity = DISEASE_SEVERITY_BIOHAZARD
	bypasses_immunity = TRUE // TB primarily impacts the lungs; it's also bacterial or fungal in nature; viral immunity should do nothing.

/datum/disease/tuberculosis/stage_act() //it begins
	..()
	switch(stage)
		if(2)
			if(prob(2))
				affected_mob.emote("cough")
				to_chat(affected_mob, "<span class='danger'>У вас болит грудь.</span>")
			if(prob(2))
				to_chat(affected_mob, "<span class='danger'>Живот громко урчит!</span>")
			if(prob(5))
				to_chat(affected_mob, "<span class='danger'>Вы чувствуете холодный пот.</span>")
		if(4)
			if(prob(2))
				to_chat(affected_mob, "<span class='userdanger'>Вы видите всё вчетверо</span>")
				affected_mob.Dizzy(5)
			if(prob(2))
				to_chat(affected_mob, "<span class='danger'>Вы чувствуете острую боль в нижней части груди!</span>")
				affected_mob.adjustOxyLoss(5)
				affected_mob.emote("gasp")
			if(prob(10))
				to_chat(affected_mob, "<span class='danger'>Вы чувствуете, как воздух болезненно выходит из лёгких.</span>")
				affected_mob.adjustOxyLoss(25)
				affected_mob.emote("gasp")
		if(5)
			if(prob(2))
				to_chat(affected_mob, "<span class='userdanger'>[pick("Вы чувствуете, как сердце замедляется...", "Вы расслабляетесь и замедляете сердцебиение.")]</span>")
				affected_mob.adjustStaminaLoss(70)
			if(prob(10))
				affected_mob.adjustStaminaLoss(100)
				affected_mob.visible_message("<span class='warning'>[affected_mob] теряет сознание!</span>", "<span class='userdanger'>Вы сдаётесь и чувствуете покой...</span>")
				affected_mob.AdjustSleeping(100)
			if(prob(2))
				to_chat(affected_mob, "<span class='userdanger'>Вы чувствуете, как разум расслабляется и мысли уплывают!</span>")
				affected_mob.confused = min(100, affected_mob.confused + 8)
			if(prob(10))
				affected_mob.vomit(20)
			if(prob(3))
				to_chat(affected_mob, "<span class='warning'><i>[pick("Живот тихо урчит...", "Живот сжимается и обмякает, мышцы мертвы и безжизненны.", "Вы могли бы съесть карандаш")]</i></span>")
				affected_mob.overeatduration = max(affected_mob.overeatduration - 100, 0)
				affected_mob.adjust_nutrition(-100)
			if(prob(15))
				to_chat(affected_mob, "<span class='danger'>[pick("Вам неудобно жарко...", "Вам хочется расстегнуть комбинезон", "Вам хочется снять немного одежды...")]</span>")
				affected_mob.adjust_bodytemperature(40)
	return

