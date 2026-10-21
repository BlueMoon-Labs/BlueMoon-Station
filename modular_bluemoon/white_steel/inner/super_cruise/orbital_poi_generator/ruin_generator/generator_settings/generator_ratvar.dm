/datum/generator_settings/ratvar
	probability = 2
	floor_break_prob = 8
	structure_damage_prob = 6
	signal_name = "Окультный сигнал"

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
		null = 50,
		/obj/effect/clockwork/sigil/transgression = 2,
		/obj/structure/destructible/clockwork/wall_gear/displaced = 1,
		/mob/living/simple_animal/hostile/clockwork/marauder = 2,
		/obj/structure/destructible/clockwork/ocular_warden = 2,
		/obj/structure/destructible/clockwork/powered/mania_motor = 2,
		/obj/structure/destructible/clockwork/heralds_beacon = 1,
		/mob/living/simple_animal/hostile/clockcultistmelee = 3,
		/mob/living/simple_animal/hostile/clockcultistranged = 2,
		/mob/living/simple_animal/hostile/clockwork/clocktank = 0.5,
		/mob/living/simple_animal/hostile/boss/clockcultistboss = 0.25,
	)
	. += get_broken_stuff()
	for(var/trash in subtypesof(/obj/item/trash))
		.[trash] = 0.33
	//WHITE-STEEL PORT: детали Ратвара (stock_parts с rating = 6) — редко, 5% (0.05) от общего
	//веса мусора на появление любой из них.
	var/list/ratvar_parts = list()
	for(var/obj/item/stock_parts/part as() in subtypesof(/obj/item/stock_parts))
		if(initial(part.rating) != 6)
			continue
		//Вортекс-батарейку в спавн деталей не кладём.
		if(ispath(part, /obj/item/stock_parts/cell))
			continue
		ratvar_parts += part
	if(length(ratvar_parts))
		var/total_weight = 0
		for(var/key in .)
			total_weight += .[key]
		var/per_part = total_weight * 0.05 / length(ratvar_parts)
		for(var/part in ratvar_parts)
			.[part] = per_part

	var/matrigrass_weight = 0
	for(var/trash_key in .)
		matrigrass_weight += .[trash_key]
	if(matrigrass_weight > 0)
		.[/obj/item/seeds/matrigrass] = matrigrass_weight * 1.025 / 249

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
