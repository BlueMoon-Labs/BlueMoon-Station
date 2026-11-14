/turf/swarmer_act(mob/living/simple_animal/hostile/swarmer/user)
	return SWARMER_ACT_IMPOSSIBLE

/turf/closed/wall/swarmer_act(mob/living/simple_animal/hostile/swarmer/user)
	return SWARMER_ACT_POSSIBLE | SWARMER_ACT_POSSIBLE_ACTION_DAMAGE

/turf/closed/mineral/swarmer_act(mob/living/simple_animal/hostile/swarmer/user)
	return SWARMER_ACT_POSSIBLE | SWARMER_ACT_POSSIBLE_ACTION_DESTROY

/turf/open/floor/swarmer_act(mob/living/simple_animal/hostile/swarmer/user)
	return SWARMER_ACT_IMPOSSIBLE | SWARMER_ACT_IMPOSSIBLE_REASON_DEFAULT

/turf/open/space/swarmer_act(mob/living/simple_animal/hostile/swarmer/user)
	user.construct_catwalk(src)
	return SWARMER_ACT_IMPOSSIBLE | SWARMER_ACT_IMPOSSIBLE_REASON_OVERRIDE

/turf/open/openspace/swarmer_act(mob/living/simple_animal/hostile/swarmer/user)
	user.construct_catwalk(src)
	return SWARMER_ACT_IMPOSSIBLE | SWARMER_ACT_IMPOSSIBLE_REASON_OVERRIDE

/turf/open/lava/swarmer_act(mob/living/simple_animal/hostile/swarmer/user)

	user.construct_catwalk(src)
	return SWARMER_ACT_IMPOSSIBLE | SWARMER_ACT_IMPOSSIBLE_REASON_OVERRIDE

/turf/open/chasm/swarmer_act(mob/living/simple_animal/hostile/swarmer/user)

	user.construct_catwalk(src)
	return SWARMER_ACT_IMPOSSIBLE | SWARMER_ACT_IMPOSSIBLE_REASON_OVERRIDE
