/datum/generator_settings/blob
	probability = 2
	floor_break_prob = 8
	structure_damage_prob = 6
	signal_name = "Сигнал био-угрозы"

/datum/generator_settings/blob/get_floortrash()
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
		/mob/living/simple_animal/hostile/blob/blobspore = 1.5,
		/mob/living/simple_animal/hostile/blob/blobbernaut/independent = 0.75,
		//WHITE-STEEL PORT: на сигнале био-угрозы мусора заметно больше — пустой вес снижен,
		//чтобы на каждый тайл чаще что-то спавнилось.
		null = 35,
	)
	. += get_broken_stuff()
	for(var/trash in subtypesof(/obj/item/trash))
		.[trash] = 0.33

/datum/generator_settings/blob/get_directional_walltrash()
	return list(
		/obj/machinery/light/built = 5,
		/obj/machinery/light = 1,
		/obj/machinery/light/broken = 4,
		/obj/machinery/light/small = 2,
		/obj/machinery/light/small/broken = 5,
		null = 75,
	)

/datum/generator_settings/blob/get_non_directional_walltrash()
	return list(
		/obj/item/radio/intercom = 1,
		/obj/structure/sign/poster/random = 1,
		/obj/structure/sign/poster/ripped = 2,
		/obj/machinery/newscaster = 1,
		/obj/structure/extinguisher_cabinet = 3,
		null = 30
	)
