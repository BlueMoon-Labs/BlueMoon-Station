//WHITE-STEEL: ксеноморфы после смерти оставляют гиб, а не труп.
/mob/living/simple_animal/hostile/alien
	loot = list(/obj/effect/gibspawner/xeno)
	del_on_death = TRUE

/mob/living/simple_animal/hostile/alien/drone
	loot = list(/obj/effect/gibspawner/xeno)

/mob/living/simple_animal/hostile/alien/sentinel
	loot = list(/obj/effect/gibspawner/xeno)

/mob/living/simple_animal/hostile/alien/queen
	loot = list(/obj/effect/gibspawner/xeno)

/mob/living/simple_animal/hostile/alien/maid
	loot = list(/obj/effect/gibspawner/xeno,
				/obj/item/clothing/head/maid,
				/obj/item/clothing/under/costume/maid)
