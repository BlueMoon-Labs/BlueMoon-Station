/datum/generator_settings/city
	probability = 7
	floor_break_prob = 12
	structure_damage_prob = 6

/datum/generator_settings/city/get_floortrash()
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
		/mob/living/simple_animal/hostile/zombie = 5,
		null = 110,
	)
	. += get_broken_stuff()
	for(var/trash in subtypesof(/obj/item/trash))
		.[trash] = 1

/datum/generator_settings/city/get_directional_walltrash()
	return list(
		/obj/machinery/light/built = 5,
		/obj/machinery/light = 1,
		/obj/machinery/light/broken = 4,
		/obj/machinery/light/small = 2,
		/obj/machinery/light/small/broken = 5,
		null = 75,
	)

/datum/generator_settings/city/get_non_directional_walltrash()
	return list(
		/obj/structure/sign/poster/random = 1,
		/obj/structure/sign/poster/ripped = 2,
		/obj/structure/extinguisher_cabinet = 3,
		null = 30
	)
