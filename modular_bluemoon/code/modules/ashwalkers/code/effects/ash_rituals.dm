/datum/ash_ritual/summon_staff
	name = "Summon Ash Staff"
	desc = "Призывайте посох, наполненный силой тендрила. Требуется разрешение материнского тендрила."
	required_components = list(
		"north" = /obj/item/stack/sheet/mineral/wood,
		"south" =  /obj/item/organ/regenerative_core/legion,
	)
	consumed_components = list(
		/obj/item/stack/sheet/mineral/wood,
		/obj/item/organ/regenerative_core/legion,
	)
	ritual_success_items = list(
		/obj/item/ash_staff,
	)

/datum/ash_ritual/summon_necklace
	name = "Summon Draconic Necklace"
	desc = "Призывает ожерелье, которое наделяет владельца знанием нашего языка."
	required_components = list(
		"north" = /obj/item/stack/sheet/bone,
		"south" =  /obj/item/organ/regenerative_core/legion,
		"east" = /obj/item/stack/sheet/sinew,
		"west" = /obj/item/stack/sheet/sinew,
	)
	consumed_components = list(
		/obj/item/stack/sheet/bone,
		/obj/item/organ/regenerative_core/legion,
		/obj/item/stack/sheet/sinew,
	)
	ritual_success_items = list(
		/obj/item/clothing/neck/necklace/ashwalker,
	)

/datum/ash_ritual/summon_cursed_knife
	name = "Summon Cursed Ash Knife"
	desc = "Призывает нож, который накладывает проклятие слежения на ничего не подозревающих шахтеров, уничтожающих наши помеченные щупальца."
	required_components = list(
		"north" =  /obj/item/organ/regenerative_core/legion,
		"south" = /obj/item/kitchen/knife/combat/bone,
		"east" = /obj/item/stack/sheet/bone,
		"west" = /obj/item/stack/sheet/sinew,
	)
	consumed_components = list(
		/obj/item/organ/regenerative_core/legion,
		/obj/item/kitchen/knife/combat/bone,
		/obj/item/stack/sheet/bone,
		/obj/item/stack/sheet/sinew,
	)
	ritual_success_items = list(
		/obj/item/cursed_dagger,
	)

/datum/ash_ritual/summon_cursed_carver
	name = "Summon Cursed Ash Carver"
	desc = "Призывает оружие, которое имитирует инструменты вторгшегося, позволяя нам собирать трофеи с охоты."
	required_components = list(
		"north" =  /obj/item/organ/regenerative_core/legion,
		"south" = /obj/item/cursed_dagger,
		"east" = /obj/item/stack/sheet/bone,
		"west" = /obj/item/stack/sheet/sinew,
	)
	consumed_components = list(
		/obj/item/organ/regenerative_core/legion,
		/obj/item/cursed_dagger,
		/obj/item/stack/sheet/bone,
		/obj/item/stack/sheet/sinew,
	)
	ritual_success_items = list(
		/obj/item/kinetic_crusher/cursed,
	)

/datum/ash_ritual/summon_tendril_seed
	name = "Summon Tendril Seed"
	desc = "Призывает семя, которое при использовании в руке вызывает появление тендрил в вашем местоположении."
	required_components = list(
		"north" =  /obj/item/organ/regenerative_core/legion,
		"south" = /obj/item/cursed_dagger,
		"east" = /obj/item/crusher_trophy/goliath_tentacle,
		"west" = /obj/item/crusher_trophy/watcher_wing,
	)
	consumed_components = list(
		/obj/item/organ/regenerative_core/legion,
		/obj/item/cursed_dagger,
		/obj/item/crusher_trophy/goliath_tentacle,
		/obj/item/crusher_trophy/watcher_wing,
	)
	ritual_success_items = list(
		/obj/item/tendril_seed,
	)

/datum/ash_ritual/incite_megafauna
	name = "Incite Megafauna"
	desc = "Вызывает ужасный, невообразимый звук, который вызовет новую мегафауну из под земли планеты."
	required_components = list(
		"north" = /mob/living/carbon/human,
		"south" = /obj/item/tendril_seed,
		"east" = /mob/living/carbon/human,
		"west" = /mob/living/carbon/human,
	)
	consumed_components = list(
		/mob/living/carbon/human,
		/obj/item/tendril_seed,
	)

/datum/ash_ritual/incite_megafauna/ritual_success(obj/effect/ash_rune/success_rune) // непонятно почему не работает, проверьте
	. = ..()
	for(var/mob/select_mob in GLOB.player_list)
		if(select_mob.z != success_rune.z)
			continue

		to_chat(select_mob, span_userdanger("Планета трепещет... появилось еще одно чудовище!"))
		flash_color(select_mob, flash_color = "#FF0000", flash_time = 3 SECONDS)

	var/megafauna_choice = pick(
    		/mob/living/simple_animal/hostile/megafauna/blood_drunk_miner,
    		/mob/living/simple_animal/hostile/megafauna/dragon,
    		/mob/living/simple_animal/hostile/megafauna/hierophant,
			)
	var/turf/spawn_turf = locate(rand(1,255), rand(1,255), success_rune.z)

	var/anti_endless = 0
	while(anti_endless < 100)
		spawn_turf = locate(rand(1,255), rand(1,255), success_rune.z)
		anti_endless++

	new /obj/effect/particle_effect/sparks(spawn_turf)
	addtimer(CALLBACK(src, PROC_REF(spawn_megafauna), megafauna_choice, spawn_turf), 3 SECONDS)

/**
 * Called within an addtimer in the ritual success of "Incite Megafauna."
 * ARG: chosen_megafauna is the megafauna that will be spawned
 * ARG: spawning_turf is the turf that the megafauna will be spawned on
 */
/datum/ash_ritual/incite_megafauna/proc/spawn_megafauna(chosen_megafauna, turf/spawning_turf)
	new chosen_megafauna(spawning_turf)

/datum/ash_ritual/ash_ceremony
	name = "Ashen Age Ceremony"
	desc = "Те, кто участвуют в церемонии и готовы к ней, будут стареть, увеличивая свою ценность для рода."
	required_components = list(
		"north" = /mob/living/carbon/human,
		"south" = /obj/item/organ/regenerative_core/legion,
		"east" = /obj/item/stack/sheet/bone,
		"west" = /obj/item/stack/sheet/sinew,
	)
	consumed_components = list(
		/mob/living/carbon/human,
		/obj/item/organ/regenerative_core/legion,
		/obj/item/stack/sheet/bone,
		/obj/item/stack/sheet/sinew,
	)

/datum/ash_ritual/ash_ceremony/ritual_success(obj/effect/ash_rune/success_rune)
	. = ..()
	for(var/mob/living/carbon/human/human_target in range(2, get_turf(success_rune)))
		SEND_SIGNAL(human_target, COMSIG_RUNE_EVOLUTION)

/datum/ash_ritual/summon_lavaland_creature
	name = "Summon Lavaland Creature"
	desc = "Призывает случайного дикого монстра из другого региона космоса."
	required_components = list(
		"north" =  /obj/item/organ/regenerative_core/legion,
		"south" = /mob/living/simple_animal/hostile/asteroid/ice_whelp,
		"east" = /obj/item/stack/ore/bluespace_crystal,
		"west" = /obj/item/stack/ore/bluespace_crystal,
	)
	consumed_components = list(
		/obj/item/organ/regenerative_core/legion,
		/mob/living/simple_animal/hostile/asteroid/ice_whelp,
	)

/datum/ash_ritual/summon_lavaland_creature/ritual_success(obj/effect/ash_rune/success_rune)
	. = ..()
	var/mob_type = pick(
		/mob/living/simple_animal/hostile/asteroid/goliath,
		/mob/living/simple_animal/hostile/asteroid/hivelord/legion,
		/mob/living/simple_animal/hostile/asteroid/basilisk/watcher,
		/mob/living/simple_animal/hostile/asteroid/lobstrosity/lava,
		/mob/living/simple_animal/hostile/skeleton/plasmaminer,
		/mob/living/simple_animal/hostile/asteroid/imp,
		)
	new mob_type(success_rune.loc)

/datum/ash_ritual/summon_icemoon_creature
	name = "Summon Icemoon Creature"
	desc = "Призывает случайного дикого монстра из другого региона космоса."
	required_components = list(
		"north" =  /obj/item/organ/regenerative_core/legion,
		"south" = /obj/item/reagent_containers/food/snacks/grown/surik,
		"east" = /obj/item/stack/ore/bluespace_crystal,
		"west" = /obj/item/stack/ore/bluespace_crystal,
	)
	consumed_components = list(
		/obj/item/organ/regenerative_core/legion,
		/obj/item/reagent_containers/food/snacks/grown/surik,
	)

/datum/ash_ritual/summon_icemoon_creature/ritual_success(obj/effect/ash_rune/success_rune)
	. = ..()
	var/mob_type = pick(
    	/mob/living/simple_animal/hostile/asteroid/ice_demon,
    	/mob/living/simple_animal/hostile/asteroid/ice_whelp,
    	/mob/living/simple_animal/hostile/asteroid/lobstrosity,
    	/mob/living/simple_animal/hostile/asteroid/polarbear,
    	/mob/living/simple_animal/hostile/asteroid/wolf,
		)
	new mob_type(success_rune.loc)

/datum/ash_ritual/share_damage
	name = "Share Victim's Damage"
	desc = "Ущерб, нанесенный центральной жертве, будет распределен между остальными окружающими живыми родственниками."
	required_components = list(
		"north" = /obj/item/stack/sheet/bone,
		"south" = /obj/item/stack/sheet/sinew,
	)
	consumed_components = list(
		/obj/item/stack/sheet/bone,
		/obj/item/stack/sheet/sinew,
	)

/datum/ash_ritual/share_damage/ritual_success(obj/effect/ash_rune/success_rune)
	. = ..()

	var/mob/living/carbon/human/human_victim = locate() in get_turf(success_rune)
	if(!human_victim)
		return

	var/total_damage = human_victim.getBruteLoss() + human_victim.getFireLoss()
	var/divide_damage = 0
	var/list/valid_humans = list()

	for(var/mob/living/carbon/human/human_share in range(2, get_turf(success_rune)))
		if(human_share == human_victim)
			continue

		if(human_share.stat == DEAD)
			continue

		valid_humans += human_share
		divide_damage++

	var/singular_damage = total_damage / divide_damage

	for(var/mob/living/carbon/human/human_target in valid_humans)
		human_target.adjustBruteLoss(singular_damage)

	human_victim.heal_overall_damage(human_victim.getBruteLoss(), human_victim.getFireLoss())
