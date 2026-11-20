/mob/living/simple_animal/hostile/alien
	loot = list(/obj/effect/mob_spawn/alien/corpse/humanoid/hunter)
	del_on_death = TRUE

/mob/living/simple_animal/hostile/alien/drone
	loot = list(/obj/effect/mob_spawn/alien/corpse/humanoid/drone)

/mob/living/simple_animal/hostile/alien/sentinel
	loot = list(/obj/effect/mob_spawn/alien/corpse/humanoid/sentinel)

/mob/living/simple_animal/hostile/alien/queen
	loot = list(/obj/effect/mob_spawn/alien/corpse/humanoid/queen)

/mob/living/simple_animal/hostile/alien/maid
	loot = list(/obj/effect/mob_spawn/alien/corpse/humanoid/drone,
				/obj/item/clothing/head/maid,
				/obj/item/clothing/under/costume/maid)

//WHITE-STEEL: на миссиях авангарда ксеноморфы оставляют гиб, а не труп.
/mob/living/simple_animal/hostile/alien/vanguard
	loot = list(/obj/effect/gibspawner/xeno)

/mob/living/simple_animal/hostile/alien/drone/vanguard
	loot = list(/obj/effect/gibspawner/xeno)

/mob/living/simple_animal/hostile/alien/sentinel/vanguard
	loot = list(/obj/effect/gibspawner/xeno)
