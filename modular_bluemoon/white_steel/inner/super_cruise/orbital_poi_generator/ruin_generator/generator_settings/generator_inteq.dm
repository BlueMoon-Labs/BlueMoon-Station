/datum/generator_settings/inteq
	probability = 6
	floor_break_prob = 8
	structure_damage_prob = 10

/datum/generator_settings/inteq/get_floortrash()
	. = list(
		/obj/effect/decal/cleanable/dirt = 6,
		/obj/effect/decal/cleanable/blood/old = 3,
		/obj/effect/decal/cleanable/oil = 2,
		/obj/effect/decal/cleanable/robot_debris/old = 1,
		/obj/effect/decal/cleanable/vomit/old = 4,
		/obj/effect/decal/cleanable/blood/gibs/old = 1,
		/obj/effect/decal/cleanable/greenglow = 1,
		/obj/effect/spawner/lootdrop/glowstick = 4,
		/obj/effect/spawner/lootdrop/maintenance = 3,
		/mob/living/simple_animal/hostile/inteq/ranged/smg = 2,
		/mob/living/simple_animal/hostile/inteq/ranged/shotgun = 1,
		/mob/living/simple_animal/hostile/inteq/melee = 2,
		/mob/living/simple_animal/hostile/inteq/melee/sword = 1,
		/obj/effect/mob_spawn/human/corpse/inteq_dead = 2,
		/obj/item/storage/fancy/cigarettes/cigpack_inteq = 2,
		/obj/item/storage/box/inteq_box = 1,
		/obj/item/storage/box/inteq_box/inteq_clothes = 1,
		/obj/item/documents/inteq = 1,
		/obj/item/folder/inteq = 1,
		/obj/item/clothing/under/inteq = 1,
		/obj/item/storage/toolbox/inteq = 1,
		/obj/item/gun/ballistic/revolver/inteq = 0.1,
		null = 110,
	)
	. += get_broken_stuff()
	for(var/trash in subtypesof(/obj/item/trash))
		.[trash] = 1

/datum/generator_settings/inteq/get_directional_walltrash()
	return list(
		/obj/machinery/light/built = 4,
		/obj/machinery/light = 1,
		/obj/machinery/light/broken = 3,
		/obj/machinery/light/small = 2,
		/obj/machinery/light/small/broken = 2,
		/obj/structure/sign/poster/contraband/inteq/random = 1,
		null = 100,
	)

/datum/generator_settings/inteq/get_non_directional_walltrash()
	return list(
		/obj/item/radio/intercom = 1,
		/obj/structure/sign/flag/inteq = 2,
		/obj/structure/sign/poster/contraband/inteq/inteq_recruitment = 1,
		/obj/structure/sign/poster/contraband/inteq/inteq_better_dead = 1,
		/obj/machinery/airalarm/inteq = 2,
		/obj/structure/extinguisher_cabinet = 2,
		null = 30,
	)
