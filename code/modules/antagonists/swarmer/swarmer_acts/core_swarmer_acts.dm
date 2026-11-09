/obj/structure/swarmer/swarmer_act(mob/living/simple_animal/hostile/swarmer/user)
	if(team && team != user.team)
		return SWARMER_ACT_IMPOSSIBLE | SWARMER_ACT_IMPOSSIBLE_REASON_TEAM
	switch(user.a_intent)
		if(INTENT_HELP)
			swarmer_help_act(user)
		if(INTENT_DISARM)
			swarmer_disarm_act(user)
		if(INTENT_GRAB)
			swarmer_grab_act(user)
		if(INTENT_HARM)
			swarmer_harm_act(user)

	return SWARMER_ACT_IMPOSSIBLE | SWARMER_ACT_IMPOSSIBLE_REASON_OVERRIDE

/obj/machinery/porta_turret/swarmer/swarmer_act(mob/living/simple_animal/hostile/swarmer/user)
	if(team && team != user.team)
		return SWARMER_ACT_IMPOSSIBLE | SWARMER_ACT_IMPOSSIBLE_REASON_TEAM
	switch(user.a_intent)
		if(INTENT_HELP)
			swarmer_help_act(user)
		if(INTENT_DISARM)
			swarmer_disarm_act(user)
		if(INTENT_GRAB)
			swarmer_grab_act(user)
		if(INTENT_HARM)
			swarmer_harm_act(user)

	return SWARMER_ACT_IMPOSSIBLE | SWARMER_ACT_IMPOSSIBLE_REASON_OVERRIDE

/obj/item/food/swarmer_act(mob/living/simple_animal/hostile/swarmer/user)
	user.send_organic_processer_signal(src, SWARMER_SEND_ORGANIC_DELAY)
	return SWARMER_ACT_IMPOSSIBLE | SWARMER_ACT_IMPOSSIBLE_REASON_OVERRIDE

/obj/item/grown/swarmer_act(mob/living/simple_animal/hostile/swarmer/user)
	user.send_organic_processer_signal(src, SWARMER_SEND_ORGANIC_DELAY)
	return SWARMER_ACT_IMPOSSIBLE | SWARMER_ACT_IMPOSSIBLE_REASON_OVERRIDE

/obj/item/seeds/swarmer_act(mob/living/simple_animal/hostile/swarmer/user)
	user.send_organic_processer_signal(src, SWARMER_SEND_ORGANIC_DELAY)
	return SWARMER_ACT_IMPOSSIBLE | SWARMER_ACT_IMPOSSIBLE_REASON_OVERRIDE

/obj/machinery/hydroponics/swarmer_act(mob/living/simple_animal/hostile/swarmer/user)
	if(!myseed)
		return SWARMER_ACT_POSSIBLE | SWARMER_ACT_POSSIBLE_ACTION_DISMANTLE

	user.balloon_alert(user, "отправка растения...")
	if(!do_after(user, SWARMER_SEND_ORGANIC_DELAY, src))
		balloon_alert(user, "сбито!")
		return SWARMER_ACT_IMPOSSIBLE | SWARMER_ACT_IMPOSSIBLE_REASON_OVERRIDE

	age = 0
	plant_health = 0
	if(harvest)
		harvest = FALSE
	QDEL_NULL(myseed)
	update_icon()

	user.send_organic_processer_signal()
	return SWARMER_ACT_IMPOSSIBLE | SWARMER_ACT_IMPOSSIBLE_REASON_OVERRIDE

/obj/item/reagent_containers/swarmer_act(mob/living/simple_animal/hostile/swarmer/user)
	if(!reagents?.total_volume)
		return SWARMER_ACT_POSSIBLE | SWARMER_ACT_POSSIBLE_ACTION_CONSUME
	user.send_organic_processer_signal(src, SWARMER_SEND_ORGANIC_DELAY)
	return SWARMER_ACT_IMPOSSIBLE | SWARMER_ACT_IMPOSSIBLE_REASON_OVERRIDE
