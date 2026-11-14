/// Бинарный канал не связывает полигон со станцией: учебный предатель с ключом и станционные синтетики не слышат друг друга, станционные слышат друг друга.
/datum/unit_test/antag_training_binary_isolated
	var/list/added_players = list()

/datum/unit_test/antag_training_binary_isolated/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/antag/traitor)
	TEST_ASSERT(session.prepare(), "Полигон готовит предателя.")
	var/datum/antag_training_program/antag/traitor/program = session.program
	var/mob/living/carbon/human/trainee = session.current_body
	var/datum/antagonist/traitor/training/role = program.role(session)
	role.training_implant.ui_action_click()
	var/datum/uplink_item/binary_item = antag_training_uplink_entry(role.uplink, /datum/uplink_item/device_tools/binary)
	TEST_ASSERT_NOTNULL(binary_item, "Binary Translator Key продаётся в учебном аплинке.")
	antag_training_uplink_buy(role.uplink, trainee, binary_item)
	var/obj/item/encryptionkey/binary/key = locate() in trainee.held_items
	TEST_ASSERT_NOTNULL(key, "Ключ куплен и лежит в руке.")
	var/obj/item/radio/headset/headset = allocate(/obj/item/radio/headset, get_turf(trainee))
	key.melee_attack_chain(trainee, headset)
	TEST_ASSERT(headset.translate_binary, "Ключ вставлен в гарнитуру.")
	if(trainee.ears)
		trainee.dropItemToGround(trainee.ears, TRUE)
	TEST_ASSERT(trainee.equip_to_slot_if_possible(headset, ITEM_SLOT_EARS_LEFT), "Гарнитура с ключом надета.")
	TEST_ASSERT(trainee.binarycheck(), "Учебный предатель с ключом в бинарном канале.")

	var/mob/living/carbon/human/donor = allocate(/mob/living/carbon/human)
	var/mob/living/silicon/ai/station_ai = allocate(/mob/living/silicon/ai, run_loc_floor_bottom_left, null, donor)
	var/mob/living/silicon/robot/station_borg = allocate(/mob/living/silicon/robot, run_loc_floor_bottom_left)
	var/mob/dead/observer/ghost = allocate(/mob/dead/observer, run_loc_floor_bottom_left)
	added_players = list(trainee, station_ai, station_borg, ghost) - GLOB.player_list
	GLOB.player_list += added_players
	GLOB.unit_test_chat_capture = list()

	trainee.say("[MODE_TOKEN_BINARY] binary-arena-probe")
	TEST_ASSERT(heard(trainee, "binary-arena-probe"), "Учебный предатель слышит себя в бинарном канале.")
	TEST_ASSERT(!heard(station_ai, "binary-arena-probe"), "ИИ станции не слышит бинарный канал полигона.")
	TEST_ASSERT(!heard(station_borg, "binary-arena-probe"), "Киборг станции не слышит бинарный канал полигона.")
	TEST_ASSERT(!heard(ghost, "binary-arena-probe"), "Наблюдатель станции не слышит бинарный канал полигона.")

	station_borg.say("[MODE_TOKEN_BINARY] binary-station-probe")
	TEST_ASSERT(heard(station_ai, "binary-station-probe"), "Станционные синтетики слышат друг друга.")
	TEST_ASSERT(heard(station_borg, "binary-station-probe"), "Киборг станции слышит себя.")
	TEST_ASSERT(!heard(trainee, "binary-station-probe"), "Учебный предатель не слышит бинарный канал станции.")

/datum/unit_test/antag_training_binary_isolated/proc/heard(mob/listener, marker)
	for(var/list/entry as anything in GLOB.unit_test_chat_capture)
		var/target = entry[1]
		if((target == listener || (islist(target) && (listener in target))) && findtext(entry[2], marker))
			return TRUE
	return FALSE

/datum/unit_test/antag_training_binary_isolated/Destroy()
	GLOB.unit_test_chat_capture = null
	GLOB.player_list -= added_players
	added_players.Cut()
	return ..()
