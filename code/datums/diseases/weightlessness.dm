/datum/disease/weightlessness
	name = "Localized Weightloss Malfunction"
	max_stages = 4
	spread_text = "При контакте"
	spread_flags = DISEASE_SPREAD_BLOOD | DISEASE_SPREAD_CONTACT_SKIN | DISEASE_SPREAD_CONTACT_FLUIDS
	cure_text = "Жидкая тёмная материя"
	cures = list(/datum/reagent/liquid_dark_matter)
	agent = "Sub-quantum DNA Repulsion"
	viable_mobtypes = list(/mob/living/carbon/human)
	disease_flags = CAN_CARRY|CAN_RESIST|CURABLE
	permeability_mod = 0.5
	cure_chance = 4
	desc = "Эта болезнь приводит к низкоуровневой перезаписи биоэлектрической подписи пациента, заставляя его отвергать явление \"веса\". Употребление жидкой тёмной материи стабилизирует поле."
	severity = DISEASE_SEVERITY_MEDIUM
	infectable_biotypes = MOB_ORGANIC


/datum/disease/weightlessness/stage_act()
	. = ..()
	if(!.)
		return

	switch(stage)
		if(1)
			if(prob(1))
				to_chat(affected_mob, span_danger("Вы почти теряете равновесие на секунду."))
		if(2)
			if(prob(3) && !HAS_TRAIT_FROM(affected_mob, TRAIT_MOVE_FLOATING, NO_GRAVITY_TRAIT))
				to_chat(affected_mob, span_danger("Вы чувствуете, как отрываетесь от земли."))
				affected_mob.reagents.add_reagent(/datum/reagent/gravitum, 1)

		if(4)
			if(prob(3))
				to_chat(affected_mob, span_danger("Вас тошнит, мир начинает двигаться вокруг вас."))
				affected_mob.Dizzy(30)
			if(prob(8) && !HAS_TRAIT_FROM(affected_mob, TRAIT_MOVE_FLOATING, NO_GRAVITY_TRAIT))
				to_chat(affected_mob, span_danger("Вы внезапно отрываетесь от земли."))
				affected_mob.reagents.add_reagent(/datum/reagent/gravitum, 5)

/datum/disease/weightlessness/cure(add_resistance)
	. = ..()
	affected_mob.vomit(95, FALSE, TRUE, 1, TRUE, purge_ratio = 0.4)
	to_chat(affected_mob, span_danger("Вы падаете на пол, когда тело перестаёт отвергать гравитацию."))
