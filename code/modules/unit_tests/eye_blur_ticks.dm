/// Укус ядовитого хедкраба размывает зрение на задуманные секунды, а не в двадцать раз дольше, и не копит выше потолка.
/datum/unit_test/poison_headcrab_bite_blur

/datum/unit_test/poison_headcrab_bite_blur/Run()
	var/mob/living/simple_animal/hostile/headcrab/poison/crab = allocate(/mob/living/simple_animal/hostile/headcrab/poison, run_loc_floor_bottom_left)
	crab.melee_damage_lower = 0
	crab.melee_damage_upper = 0
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, get_step(crab, EAST))
	crab.target = victim
	crab.AttackingTarget()
	TEST_ASSERT_EQUAL(victim.eye_blurry, BLUR_TICKS(crab.bite_blur), "Один укус хедкраба даёт не то размытие.")
	for(var/bite in 1 to 20)
		crab.AttackingTarget()
	TEST_ASSERT_EQUAL(victim.eye_blurry, BLUR_TICKS(crab.bite_blur_cap), "Укусы хедкраба копят размытие мимо потолка.")

/// Бумажный самолётик в глаз размывает зрение на задуманные секунды и не копит выше потолка.
/datum/unit_test/paperplane_eye_hit_blur

/datum/unit_test/paperplane_eye_hit_blur/Run()
	var/obj/item/paperplane/plane = allocate(/obj/item/paperplane, run_loc_floor_top_right)
	plane.hit_probability = 100
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	plane.throw_impact(victim)
	TEST_ASSERT_EQUAL(victim.eye_blurry, BLUR_TICKS(plane.impact_blur), "Попадание самолётиком в глаз даёт не то размытие.")
	for(var/hit in 1 to 10)
		plane.throw_impact(victim)
	TEST_ASSERT_EQUAL(victim.eye_blurry, BLUR_TICKS(plane.impact_blur_cap), "Самолётики копят размытие мимо потолка.")
