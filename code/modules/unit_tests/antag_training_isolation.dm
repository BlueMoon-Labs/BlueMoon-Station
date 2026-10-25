/// Пока тест держит список, deadchat_broadcast складывает сюда свои сообщения.
GLOBAL_LIST(unit_test_deadchat_messages)

/// Датум тела полигона не виден обходам GLOB.antagonists и дедчату, датум тела станции виден как раньше; смена тела переносит датум между списками.
/datum/unit_test/antag_training_unlisted_antagonists/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон готов.")
	var/mob/living/carbon/human/dummy = session.arena.spawn_target()
	TEST_ASSERT_NOTNULL(dummy, "Манекен встал.")
	GLOB.unit_test_deadchat_messages = list()
	brainwash(dummy, "Учебная директива")
	var/arena_deadchat = length(GLOB.unit_test_deadchat_messages)
	var/datum/antagonist/arena_washed = dummy.mind.has_antag_datum(/datum/antagonist/brainwashed)
	TEST_ASSERT_NOTNULL(arena_washed, "Манекен промыт.")
	TEST_ASSERT(!(arena_washed in GLOB.antagonists), "Промывка манекена не попадает в итоги раунда.")
	TEST_ASSERT(!(dummy.mind in get_antag_minds(/datum/antagonist)), "Обходы get_antag_minds() не видят манекен.")
	TEST_ASSERT(!(session.avatar_mind in get_antag_minds(/datum/antagonist)), "Обходы get_antag_minds() не видят участника.")
	TEST_ASSERT_EQUAL(arena_deadchat, 0, "Промывка на полигоне не пишет в дедчат.")

	var/mob/living/carbon/human/crewman = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	crewman.mind_initialize()
	var/datum/mind/soul = crewman.mind
	allocated += soul
	GLOB.unit_test_deadchat_messages = list()
	brainwash(crewman, "Директива станции")
	var/station_deadchat = length(GLOB.unit_test_deadchat_messages)
	GLOB.unit_test_deadchat_messages = null
	var/datum/antagonist/station_washed = soul.has_antag_datum(/datum/antagonist/brainwashed)
	TEST_ASSERT(station_washed in GLOB.antagonists, "Промывка на станции в итогах раунда.")
	TEST_ASSERT(soul in get_antag_minds(/datum/antagonist/brainwashed), "get_antag_minds() видит промытого на станции.")
	TEST_ASSERT_EQUAL(station_deadchat, 1, "Промывка на станции пишет в дедчат.")

	var/mob/living/carbon/human/vessel = new(session.arena.zones["melee"]["target"])
	crewman.mind = null
	soul.set_current(null)
	soul.transfer_to(vessel)
	TEST_ASSERT_EQUAL(soul.current, vessel, "Разум перешёл в тело полигона.")
	TEST_ASSERT(!(station_washed in GLOB.antagonists), "В теле полигона датум снят с GLOB.antagonists.")
	vessel.mind = null
	soul.set_current(null)
	soul.transfer_to(crewman)
	TEST_ASSERT_EQUAL(soul.current, crewman, "Разум вернулся в тело станции.")
	TEST_ASSERT(station_washed in GLOB.antagonists, "В теле станции датум снова в GLOB.antagonists.")
	qdel(vessel)

/datum/unit_test/antag_training_unlisted_antagonists/Destroy()
	GLOB.unit_test_deadchat_messages = null
	return ..()

/// Взрыв на полигоне не пишет статистику раунда, взрыв вне полигона пишет.
/datum/unit_test/antag_training_explosion_stats/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон готов.")
	var/turf/arena_spot = session.arena.zones["melee"]["target"]
	var/recorded = explosion_records()
	var/datum/explosion/arena_blast = explosion(arena_spot, 0, 0, 0, 0)
	wait_for_qdeleted(arena_blast, 5 SECONDS)
	TEST_ASSERT(!isnull(arena_blast?.started_at), "Взрыв на полигоне сработал.")
	TEST_ASSERT_EQUAL(explosion_records(), recorded, "Взрыв на полигоне не попадает в статистику.")
	var/datum/explosion/station_blast = explosion(run_loc_floor_bottom_left, 0, 0, 0, 0)
	wait_for_qdeleted(station_blast, 5 SECONDS)
	TEST_ASSERT_EQUAL(explosion_records(), recorded + 1, "Взрыв вне полигона попадает в статистику.")

/datum/unit_test/antag_training_explosion_stats/proc/explosion_records()
	for(var/datum/feedback_variable/feedback as anything in SSblackbox.feedback)
		if(feedback.key == "explosion")
			var/list/data = feedback.json["data"]
			return length(data)
	return 0

/// Значок розыска, осмотр через SecHUD и ссылки медицинского HUD на полигоне не читают записи станции, на станции читают.
/datum/unit_test/antag_training_station_records/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон готов.")
	var/mob/living/carbon/human/participant = session.current_body
	participant.forceMove(session.arena.zones["melee"]["spawn"])
	var/mob/living/carbon/human/dummy = session.arena.spawn_target()
	var/mob/living/carbon/human/crewman = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/officer = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/wanted_name = dummy.real_name
	crewman.real_name = wanted_name
	crewman.name = wanted_name
	var/datum/data/record/security = allocate(/datum/data/record)
	security.fields["name"] = wanted_name
	security.fields["criminal"] = SEC_RECORD_STATUS_ARREST
	var/datum/data/record/general = allocate(/datum/data/record)
	general.fields["name"] = wanted_name
	general.fields["rank"] = "Учебная должность"
	GLOB.data_core.security_by_name[wanted_name] = security
	GLOB.data_core.general_by_name[wanted_name] = general
	for(var/mob/living/carbon/human/viewer as anything in list(participant, officer))
		if(viewer.glasses)
			qdel(viewer.glasses)
		viewer.equip_to_slot_or_del(new /obj/item/clothing/glasses/hud/security(viewer), ITEM_SLOT_EYES)

	crewman.sec_hud_set_security_status()
	dummy.sec_hud_set_security_status()
	var/image/station_icon = crewman.hud_list[WANTED_HUD]
	var/image/arena_icon = dummy.hud_list[WANTED_HUD]
	var/station_text = jointext(crewman.examine(officer), "\n")
	var/arena_text = jointext(dummy.examine(participant), "\n")
	GLOB.data_core.security_by_name -= wanted_name
	GLOB.data_core.general_by_name -= wanted_name

	general.fields["id"] = "antag_training_test_record"
	var/datum/data/record/medical = allocate(/datum/data/record)
	medical.fields["id"] = general.fields["id"]
	medical.fields["name"] = wanted_name
	medical.fields["b_type"] = "Учебная группа крови"
	GLOB.data_core.general += general
	GLOB.data_core.medical += medical
	for(var/mob/living/carbon/human/viewer as anything in list(participant, officer))
		qdel(viewer.glasses)
		var/obj/item/clothing/glasses/hud/health/medical_hud = new(viewer)
		medical_hud.hud_type = DATA_HUD_MEDICAL_BASIC
		viewer.equip_to_slot_or_del(medical_hud, ITEM_SLOT_EYES)
	GLOB.unit_test_chat_capture = list()
	var/list/medical_reads = list()
	for(var/list/topic as anything in list(list(officer, crewman), list(participant, dummy)))
		var/mob/living/carbon/human/viewer = topic[1]
		var/mob/living/carbon/human/perp = topic[2]
		usr = viewer
		for(var/branch in list("medrecord", "medrecordComment"))
			perp.Topic(null, list("[branch]" = "1"))
	for(var/list/entry as anything in GLOB.unit_test_chat_capture)
		if(findtext(entry[2], medical.fields["b_type"]) || findtext(entry[2], "No comment found"))
			medical_reads[entry[1]] += 1
	GLOB.unit_test_chat_capture = null
	GLOB.data_core.general -= general
	GLOB.data_core.medical -= medical
	TEST_ASSERT_EQUAL(medical_reads[officer], 2, "Ссылки медицинского HUD на станции читают медицинскую запись.")
	TEST_ASSERT(!medical_reads[participant], "Ссылки медицинского HUD на полигоне не читают записи станции.")

	TEST_ASSERT_EQUAL(station_icon.icon_state, "hudwanted", "На станции значок розыска берётся из записей.")
	TEST_ASSERT_NOTEQUAL(arena_icon.icon_state, "hudwanted", "На полигоне значок розыска не берётся из записей станции.")
	TEST_ASSERT(findtext(station_text, SEC_RECORD_STATUS_ARREST) && findtext(station_text, general.fields["rank"]), "Осмотр на станции показывает статус и должность из записей.")
	TEST_ASSERT(!findtext(arena_text, SEC_RECORD_STATUS_ARREST) && !findtext(arena_text, general.fields["rank"]), "Осмотр на полигоне не показывает записи станции.")

/datum/unit_test/antag_training_station_records/Destroy()
	GLOB.unit_test_chat_capture = null
	return ..()

/// Свободная клетка сама подходит под цель: free_spot() не сдвигает цель на соседнюю.
/datum/unit_test/antag_training_free_spot_center/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон готов.")
	var/datum/antag_training_arena/arena = session.arena
	var/list/bounds = arena.zones["pve"]["bounds"]
	var/turf/open/center
	for(var/turf/open/candidate in block(locate(bounds[1], bounds[3], arena.private_level.z_value), locate(bounds[2], bounds[4], arena.private_level.z_value)))
		if(!candidate.is_blocked_turf(exclude_mobs = FALSE) && !(locate(/mob/living) in candidate))
			center = candidate
			break
	TEST_ASSERT_NOTNULL(center, "В зоне есть свободная клетка.")
	TEST_ASSERT_EQUAL(arena.free_spot(center, bounds), center, "Свободная клетка center возвращается сама.")
