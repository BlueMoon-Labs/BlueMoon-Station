/datum/generator_settings/ratvar
	probability = 2
	floor_break_prob = 8
	structure_damage_prob = 6

/datum/generator_settings/ratvar/get_floortrash()
	. = list(
		/obj/effect/decal/cleanable/dirt = 6,
		/obj/effect/decal/cleanable/blood/old = 3,
		/obj/effect/decal/cleanable/oil = 2,
		/obj/effect/decal/cleanable/robot_debris/old = 1,
		/obj/effect/decal/cleanable/vomit/old = 4,
		/obj/effect/decal/cleanable/blood/gibs/old = 1,
		/obj/effect/decal/cleanable/greenglow = 1,
		/obj/effect/spawner/lootdrop/maintenance = 3,
		null = 70,
		//WHITE-STEEL PORT: ловушки Ратвара (битые заглушки с desc "Ты не должен этого видеть")
		//полностью убраны из спавна - оставлены только руны.
		/obj/effect/clockwork/sigil/transgression = 2,
		/obj/structure/destructible/clockwork/wall_gear/displaced = 10,
		//WHITE-STEEL PORT: вместо ловушек спавним настоящих врагов-культистов Ратвара (было мало врагов).
		/mob/living/simple_animal/hostile/clockcultistmelee = 4,
		/mob/living/simple_animal/hostile/clockcultistranged = 3,
		/mob/living/simple_animal/hostile/clockwork/clocktank = 2,
		/mob/living/simple_animal/hostile/boss/clockcultistboss = 1,
	)
	. += get_broken_stuff()
	for(var/trash in subtypesof(/obj/item/trash))
		.[trash] = 1

/datum/generator_settings/ratvar/get_directional_walltrash()
	return list(
		/obj/machinery/light/broken = 4,
		/obj/machinery/light/small = 1,
		null = 75,
	)

/datum/generator_settings/ratvar/get_non_directional_walltrash()
	return list(
		/obj/item/radio/intercom = 2,
		/obj/structure/sign/poster/random = 1,
		/obj/machinery/newscaster = 2,
		/obj/structure/extinguisher_cabinet = 3,
		null = 30
	)
