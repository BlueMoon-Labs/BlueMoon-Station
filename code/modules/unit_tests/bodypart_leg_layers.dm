/// Передняя половина ноги рисуется поверх груди, задняя - под ней: низ груди не наезжает на ноги.
/datum/unit_test/bodypart_leg_layers

/datum/unit_test/bodypart_leg_layers/Run()
	var/mob/living/carbon/human/moth = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	moth.set_species(/datum/species/insect)
	moth.dna.species.mutant_bodyparts["limbs_id"] = "moth"
	moth.update_body_parts()
	check_leg_layers(moth, "moth")

	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	human.update_body_parts()
	check_leg_layers(human, "human")

/datum/unit_test/bodypart_leg_layers/proc/check_leg_layers(mob/living/carbon/human/body, limbs_id)
	var/image/chest
	var/image/leg_front
	var/image/leg_behind
	for(var/image/limb as anything in body.overlays_standing[BODYPARTS_LAYER])
		var/state = limb.icon_state
		if(!state || !findtext(state, "[limbs_id]_", 1, length(limbs_id) + 2))
			continue
		if(findtext(state, "_chest_"))
			chest = limb
		else if(findtext(state, "_l_leg") && findtext(state, "_front"))
			leg_front = limb
		else if(findtext(state, "_l_leg") && findtext(state, "_behind"))
			leg_behind = limb
	TEST_ASSERT_NOTNULL(chest, "[limbs_id]: в наборе конечностей нет груди")
	TEST_ASSERT_NOTNULL(leg_front, "[limbs_id]: в наборе конечностей нет передней половины левой ноги")
	TEST_ASSERT_NOTNULL(leg_behind, "[limbs_id]: в наборе конечностей нет задней половины левой ноги")
	TEST_ASSERT(leg_front.layer > chest.layer, "[limbs_id]: грудь ([chest.layer]) рисуется поверх передней половины ноги ([leg_front.layer])")
	TEST_ASSERT(leg_behind.layer < chest.layer, "[limbs_id]: задняя половина ноги ([leg_behind.layer]) рисуется поверх груди ([chest.layer])")
