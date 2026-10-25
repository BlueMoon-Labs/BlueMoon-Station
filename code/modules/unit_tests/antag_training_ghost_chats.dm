/// Улей учебного генокрада и дедчат о полигоне слышат только призраки на его z; улей ксеносов станции, дедчат о станции и речь призрака с полигона слышат все призраки.
/datum/unit_test/antag_training_ghost_hivemind
	var/list/added_players = list()

/datum/unit_test/antag_training_ghost_hivemind/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/antag/changeling)
	TEST_ASSERT(session.prepare(), "Полигон готовит генокрада.")
	var/datum/antag_training_program/antag/changeling/program = session.program
	var/mob/living/carbon/human/body = session.current_body
	var/datum/antagonist/changeling/training/role = program.role(session)
	var/datum/action/changeling/hivemind_comms/hive_type = /datum/action/changeling/hivemind_comms
	antag_training_ling_evolve(role, body, initial(hive_type.name))
	TEST_ASSERT(role.changeling_speak, "Учебный генокрад говорит в улей.")

	var/mob/dead/observer/arena_ghost = allocate(/mob/dead/observer, run_loc_floor_bottom_left)
	arena_ghost.forceMove(get_turf(body))
	var/mob/dead/observer/station_ghost = allocate(/mob/dead/observer, run_loc_floor_bottom_left)
	var/mob/living/carbon/alien/humanoid/drone/station_xeno = allocate(/mob/living/carbon/alien/humanoid/drone, run_loc_floor_bottom_left)
	TEST_ASSERT_EQUAL(arena_ghost.z, body.z, "Призрак стоит на полигоне.")
	added_players = list(body, arena_ghost, station_ghost, station_xeno) - GLOB.player_list
	GLOB.player_list += added_players
	GLOB.unit_test_chat_capture = list()

	body.say("[MODE_TOKEN_CHANGELING] ghost-hive-probe")
	TEST_ASSERT(antag_training_heard(arena_ghost, "ghost-hive-probe"), "Призрак на полигоне слышит учебный улей.")
	TEST_ASSERT(!antag_training_heard(station_ghost, "ghost-hive-probe"), "Призрак станции не слышит учебный улей.")

	station_xeno.say(":a ghost-xeno-probe")
	TEST_ASSERT(antag_training_heard(station_ghost, "ghost-xeno-probe"), "Призрак станции слышит улей ксеносов станции.")
	TEST_ASSERT(antag_training_heard(arena_ghost, "ghost-xeno-probe"), "Призрак на полигоне тоже слышит улей станции.")

	deadchat_broadcast(" ghost-arena-deadchat-probe", "<b>[body.real_name]</b>", follow_target = body, turf_target = get_turf(body), message_type = DEADCHAT_ANNOUNCEMENT)
	TEST_ASSERT(antag_training_heard(arena_ghost, "ghost-arena-deadchat-probe"), "Дедчат о полигоне видит призрак на полигоне.")
	TEST_ASSERT(!antag_training_heard(station_ghost, "ghost-arena-deadchat-probe"), "Дедчат о полигоне не видит призрак станции.")

	deadchat_broadcast(" ghost-station-deadchat-probe", "<b>[station_xeno.real_name]</b>", follow_target = station_xeno, turf_target = get_turf(station_xeno), message_type = DEADCHAT_ANNOUNCEMENT)
	TEST_ASSERT(antag_training_heard(station_ghost, "ghost-station-deadchat-probe") && antag_training_heard(arena_ghost, "ghost-station-deadchat-probe"), "Дедчат о станции видят все призраки.")

	arena_ghost.say("ghost-deadsay-probe")
	TEST_ASSERT(antag_training_heard(station_ghost, "ghost-deadsay-probe"), "Речь призрака с полигона в дедчате слышат призраки станции.")

/datum/unit_test/antag_training_ghost_hivemind/Destroy()
	GLOB.unit_test_chat_capture = null
	GLOB.player_list -= added_players
	added_players.Cut()
	return ..()

/// Причастие учебного культиста слышит призрак на полигоне и не слышит призрак станции.
/datum/unit_test/antag_training_ghost_cult
	var/list/added_players = list()

/datum/unit_test/antag_training_ghost_cult/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/antag/cult)
	TEST_ASSERT(session.prepare(), "Полигон готовит культиста.")
	var/datum/antag_training_program/antag/cult/program = session.program
	var/mob/living/carbon/human/body = session.current_body
	var/datum/antagonist/cult/training/cultist = program.role(session)
	TEST_ASSERT(istype(cultist), "Кукла получает учебного культиста.")

	var/mob/dead/observer/arena_ghost = allocate(/mob/dead/observer, run_loc_floor_bottom_left)
	arena_ghost.forceMove(get_turf(body))
	var/mob/dead/observer/station_ghost = allocate(/mob/dead/observer, run_loc_floor_bottom_left)
	added_players = list(body, arena_ghost, station_ghost) - GLOB.player_list
	GLOB.player_list += added_players
	GLOB.unit_test_chat_capture = list()

	cultist.communion.cultist_commune(body, "ghost-cult-probe")
	TEST_ASSERT(antag_training_heard(body, "ghost-cult-probe"), "Культист слышит своё причастие.")
	TEST_ASSERT(antag_training_heard(arena_ghost, "ghost-cult-probe"), "Призрак на полигоне слышит учебное причастие.")
	TEST_ASSERT(!antag_training_heard(station_ghost, "ghost-cult-probe"), "Призрак станции не слышит учебное причастие.")

/datum/unit_test/antag_training_ghost_cult/Destroy()
	GLOB.unit_test_chat_capture = null
	GLOB.player_list -= added_players
	added_players.Cut()
	return ..()

/// Призрак на полигоне и призрак станции с включённой перепиской КПК в настройках.
/datum/unit_test/proc/antag_training_ghost_listeners(turf/arena_floor)
	. = list()
	for(var/turf/spot as anything in list(arena_floor, run_loc_floor_bottom_left))
		var/mob/dead/observer/ghost = allocate(/mob/dead/observer, run_loc_floor_bottom_left)
		ghost.forceMove(spot)
		var/datum/client_interface/mock = new
		mock.prefs = new /datum/preferences
		allocated += mock.prefs
		mock.prefs.chat_toggles |= CHAT_GHOSTPDA
		ghost.mock_client = mock
		. += ghost

/datum/unit_test/proc/antag_training_ghost_listeners_done(list/ghosts)
	for(var/mob/dead/observer/ghost as anything in ghosts)
		ghost.mock_client = null
	GLOB.unit_test_chat_capture = null

/// Переписку КПК полигона видит призрак на полигоне и не видит призрак станции.
/datum/unit_test/antag_training_ghost_pda
	var/list/ghosts = list()

/datum/unit_test/antag_training_ghost_pda/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	session.role = antag_training_role("crew:Security Officer")
	TEST_ASSERT(session.prepare(), "Полигон готовит офицера.")
	var/mob/living/carbon/human/officer = session.current_body
	var/turf/arena_floor = session.arena.zones["melee"]["spawn"]
	var/obj/item/modular_computer/pda/arena_pda = locate() in officer.GetAllContents()
	TEST_ASSERT_NOTNULL(arena_pda, "У офицера полигона есть КПК.")
	var/obj/item/card/id/officer_card = allocate(/obj/item/card/id, arena_floor)
	officer_card.registered_name = officer.real_name
	arena_pda.InsertID(officer_card)
	var/obj/item/modular_computer/pda/peer_pda = allocate(/obj/item/modular_computer/pda, arena_floor)
	var/obj/item/card/id/peer_card = allocate(/obj/item/card/id, arena_floor)
	peer_card.registered_name = "Training Peer"
	peer_pda.InsertID(peer_card)
	var/datum/computer_file/program/messenger/arena_messenger = locate() in arena_pda.get_all_files()
	var/datum/computer_file/program/messenger/peer_messenger = locate() in peer_pda.get_all_files()
	officer.drop_all_held_items()
	officer.put_in_hands(arena_pda)

	ghosts = antag_training_ghost_listeners(arena_floor)
	var/mob/dead/observer/arena_ghost = ghosts[1]
	var/mob/dead/observer/station_ghost = ghosts[2]
	GLOB.unit_test_chat_capture = list()
	var/saved_debug = SSnetworks.ntnet_debug_global_signal
	SSnetworks.ntnet_debug_global_signal = TRUE
	var/sent = arena_messenger.send_message(officer, "ghost-pda-probe", list(peer_messenger))
	SSnetworks.ntnet_debug_global_signal = saved_debug
	TEST_ASSERT(sent, "Сообщение между КПК полигона отправляется.")
	var/datum/pda_chat/peer_chat = peer_messenger.find_chat_by_recipient(REF(arena_messenger))
	TEST_ASSERT(peer_chat && length(peer_chat.messages), "Сообщение доходит до КПК полигона.")
	TEST_ASSERT(antag_training_heard(arena_ghost, "ghost-pda-probe"), "Призрак на полигоне видит переписку КПК полигона.")
	TEST_ASSERT(!antag_training_heard(station_ghost, "ghost-pda-probe"), "Призрак станции не видит переписку КПК полигона.")

/datum/unit_test/antag_training_ghost_pda/Destroy()
	antag_training_ghost_listeners_done(ghosts)
	ghosts.Cut()
	return ..()

/// Телепатию слаймолюдей с полигона слышит призрак на полигоне и не слышит призрак станции.
/datum/unit_test/antag_training_ghost_slime
	var/list/ghosts = list()

/datum/unit_test/antag_training_ghost_slime/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон готовится.")
	var/turf/arena_floor = session.arena.zones["melee"]["spawn"]
	var/mob/living/carbon/human/stargazer = allocate(/mob/living/carbon/human, arena_floor)
	stargazer.set_species(/datum/species/jelly/stargazer)
	var/datum/species/jelly/stargazer/species = stargazer.dna.species
	TEST_ASSERT(istype(species), "Слаймолюд - звездочёт.")
	var/mob/living/carbon/human/listener = allocate(/mob/living/carbon/human, get_step(arena_floor, EAST))

	ghosts = antag_training_ghost_listeners(arena_floor)
	var/mob/dead/observer/arena_ghost = ghosts[1]
	var/mob/dead/observer/station_ghost = ghosts[2]
	GLOB.unit_test_chat_capture = list()
	var/datum/action/innate/linked_speech/link_speech = species.linked_actions[1]
	link_speech.send_linked_message(stargazer, "ghost-slime-link-probe")
	species.project_thought.send_thought(stargazer, listener, "ghost-slime-thought-probe")
	TEST_ASSERT(antag_training_heard(arena_ghost, "ghost-slime-link-probe"), "Призрак на полигоне слышит слаймовую связь полигона.")
	TEST_ASSERT(!antag_training_heard(station_ghost, "ghost-slime-link-probe"), "Призрак станции не слышит слаймовую связь полигона.")
	TEST_ASSERT(antag_training_heard(arena_ghost, "ghost-slime-thought-probe"), "Призрак на полигоне слышит мысль слаймолюда полигона.")
	TEST_ASSERT(!antag_training_heard(station_ghost, "ghost-slime-thought-probe"), "Призрак станции не слышит мысль слаймолюда полигона.")

/datum/unit_test/antag_training_ghost_slime/Destroy()
	antag_training_ghost_listeners_done(ghosts)
	ghosts.Cut()
	return ..()
