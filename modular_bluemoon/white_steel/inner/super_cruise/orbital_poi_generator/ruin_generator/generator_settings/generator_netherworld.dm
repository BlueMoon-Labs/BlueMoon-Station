/datum/generator_settings/netherworld
	probability = 1
	floor_break_prob = 30
	structure_damage_prob = 40
	signal_name = "Сигнал преисподней"

/datum/generator_settings/netherworld/get_floortrash()
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
		/mob/living/simple_animal/hostile/netherworld/blankbody = 1.5,
		/mob/living/simple_animal/hostile/netherworld/migo = 1.5,
		/obj/structure/spawner/nether = 0.3,
		/obj/structure/destructible/cult/pylon = 2,
		/obj/structure/destructible/cult/forge = 1,
		/obj/effect/rune/blood_boil = 1,
		/obj/effect/rune/empower = 1,
		null = 120,
	)
	. += get_broken_stuff()
	for(var/trash in subtypesof(/obj/item/trash))
		.[trash] = 0.33
	//WHITE-STEEL PORT: на сигналах преисподней изредка попадаются книги заклинаний
	//(/obj/item/book/granter/spell, кроме базового родителя и мета-книги /random) — 0.25%
	//(0.0025) от общего веса мусора на появление любой из книг.
	var/list/spell_books = list()
	for(var/obj/item/book/granter/spell/book as() in subtypesof(/obj/item/book/granter/spell))
		if(ispath(book, /obj/item/book/granter/spell/random))
			continue
		spell_books += book
	if(length(spell_books))
		var/total_weight = 0
		for(var/key in .)
			total_weight += .[key]
		var/per_book = total_weight * 0.0025 / length(spell_books)
		for(var/book in spell_books)
			.[book] = per_book

/datum/generator_settings/netherworld/get_directional_walltrash()
	return list(
		/obj/machinery/light/built = 5,
		/obj/machinery/light = 1,
		/obj/machinery/light/broken = 4,
		/obj/machinery/light/small = 2,
		/obj/machinery/light/small/broken = 5,
		null = 75,
	)

/datum/generator_settings/netherworld/get_non_directional_walltrash()
	return list(
		/obj/item/radio/intercom = 1,
		/obj/structure/sign/poster/random = 1,
		/obj/structure/sign/poster/ripped = 2,
		/obj/machinery/newscaster = 1,
		/obj/structure/extinguisher_cabinet = 3,
		null = 30
	)
