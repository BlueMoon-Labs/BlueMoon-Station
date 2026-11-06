/// Синт, съевший зомби-порошок, не падает в вечную мнимую смерть; у органика она снимается вместе с порошком и админским лечением.
/datum/unit_test/zombiepowder_fakedeath_ends

/datum/unit_test/zombiepowder_fakedeath_ends/Run()
	var/mob/living/carbon/human/synth = allocate(/mob/living/carbon/human)
	ADD_TRAIT(synth, TRAIT_ROBOTIC_ORGANISM, TRAIT_GENERIC)
	feed_zombiepowder(synth)
	TEST_ASSERT(!HAS_TRAIT(synth, TRAIT_FAKEDEATH), "Порошок не усваивается синтом, но уложил его в мнимую смерть.")

	var/mob/living/carbon/human/eater = allocate(/mob/living/carbon/human)
	feed_zombiepowder(eater)
	TEST_ASSERT(HAS_TRAIT(eater, TRAIT_FAKEDEATH), "Предпосылка: проглоченный порошок укладывает органика.")
	eater.reagents.del_reagent(/datum/reagent/toxin/zombiepowder)
	TEST_ASSERT(!HAS_TRAIT(eater, TRAIT_FAKEDEATH), "Порошок выведен до усвоения, а мнимая смерть осталась.")

	feed_zombiepowder(eater)
	eater.revive(full_heal = TRUE, admin_revive = TRUE)
	TEST_ASSERT(!HAS_TRAIT(eater, TRAIT_FAKEDEATH), "Админское лечение не снимает мнимую смерть от порошка.")
	TEST_ASSERT(!HAS_TRAIT(eater, TRAIT_DEATHCOMA), "Админское лечение не выводит из комы порошка.")

/datum/unit_test/zombiepowder_fakedeath_ends/proc/feed_zombiepowder(mob/living/carbon/human/target)
	var/datum/reagents/food = new(10)
	food.add_reagent(/datum/reagent/toxin/zombiepowder, 10)
	food.reaction(target, INGEST)
	food.trans_to(target, 10)
	qdel(food)

/// Броня священника и прочие наследники риотки не получают её хвост и не прячут свой; рескины и тавр-спрайты риотки им не достаются.
/datum/unit_test/riot_descendants_keep_own_look

/datum/unit_test/riot_descendants_keep_own_look/Run()
	for(var/armor_type in typesof(/obj/item/clothing/suit/armor/riot/chaplain) + typesof(/obj/item/clothing/suit/armor/riot/knight))
		var/obj/item/clothing/suit/armor/armor = allocate(armor_type)
		TEST_ASSERT_EQUAL(armor.tail_state, "", "[armor_type] рисует хвост риотки.")
		TEST_ASSERT(!(armor.flags_inv & HIDETAIL), "[armor_type] прячет хвост владельца.")
		TEST_ASSERT(!length(armor.unique_reskin), "[armor_type] перекрашивается в риотку.")

	var/list/taur_states = icon_states('modular_bluemoon/icons/mob/clothing/taur_custom_clothing.dmi')
	for(var/armor_type in typesof(/obj/item/clothing/suit/armor/riot) + typesof(/obj/item/clothing/suit/armor/bulletproof))
		var/obj/item/clothing/suit/armor/armor = allocate(armor_type)
		for(var/suffix in armor.taur_types_icon_whitelist)
			TEST_ASSERT("[armor.icon_state][suffix]" in taur_states, "[armor_type] на тавре ищет несуществующий спрайт [armor.icon_state][suffix].")

/// КПК гостей Призрачного Кафе не видны в списке мессенджеров станции.
/datum/unit_test/ghost_cafe_pda_hidden_from_station

/datum/unit_test/ghost_cafe_pda_hidden_from_station/Run()
	var/obj/item/modular_computer/pda/station_pda = allocate(/obj/item/modular_computer/pda)
	station_pda.imprint_id("Station Crew", "Assistant")
	var/datum/computer_file/program/messenger/station_messenger = locate() in station_pda.get_all_files()

	var/mob/living/carbon/human/guest = allocate_minded_human()
	guest.mind.add_antag_datum(/datum/antagonist/ghost_role/ghost_cafe)
	var/obj/item/modular_computer/pda/cafe_pda = allocate(/obj/item/modular_computer/pda)
	cafe_pda.imprint_id("Cafe Guest", "Cyborg")
	guest.put_in_hands(cafe_pda)
	var/datum/computer_file/program/messenger/cafe_messenger = locate() in cafe_pda.get_all_files()

	var/obj/item/modular_computer/pda/neighbour_pda = allocate(/obj/item/modular_computer/pda)
	neighbour_pda.imprint_id("Station Neighbour", "Cyborg")
	var/datum/computer_file/program/messenger/neighbour_messenger = locate() in neighbour_pda.get_all_files()

	GLOB.pda_messenger_directory_time = -1
	var/list/station_sees = station_messenger.get_messengers()
	TEST_ASSERT(REF(neighbour_messenger) in station_sees, "Предпосылка: станционный КПК видит соседа.")
	TEST_ASSERT(!(REF(cafe_messenger) in station_sees), "Станционный КПК видит КПК гостя Призрачного Кафе.")
	TEST_ASSERT(!(cafe_pda in get_viewable_pdas()), "КПК гостя Призрачного Кафе виден ИИ.")
