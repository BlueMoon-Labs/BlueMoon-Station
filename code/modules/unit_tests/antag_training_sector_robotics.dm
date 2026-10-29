/// Киборг, собранный на полигоне из мозга учебной цели, не связан с ИИ станции, не наследует её законы и не виден её камерам.
/datum/unit_test/antag_training_sector_robotics/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон должен подготовиться.")
	var/datum/antag_training_arena/arena = session.arena
	var/datum/antag_training_sector/sector = arena.sectors["robotics"]
	TEST_ASSERT_NOTNULL(sector, "Арена знает сектор робототехники.")
	TEST_ASSERT(sector.load(), "Сектор загружается.")
	var/mob/living/carbon/human/ai_donor = allocate(/mob/living/carbon/human)
	var/mob/living/silicon/ai/station_ai = allocate(/mob/living/silicon/ai, run_loc_floor_bottom_left, null, ai_donor)
	var/list/frames = list()
	for(var/obj/item/robot_suit/prebuilt/training/frame in sector.sector_area)
		frames += frame
	TEST_ASSERT_EQUAL(length(frames), 2, "В секторе две учебные рамы киборга.")
	var/obj/item/robot_suit/prebuilt/training/suit = frames[1]
	var/obj/item/robot_suit/prebuilt/training/shell_suit = frames[2]
	var/turf/bench = sector.spawn_turf()
	var/mob/living/user = session.current_body
	user.forceMove(bench)
	suit.forceMove(bench)
	shell_suit.forceMove(bench)

	var/shells_before = length(GLOB.available_ai_shells)
	var/obj/item/borg/upgrade/ai/shell_board = new(bench)
	user.put_in_hands(shell_board)
	shell_suit.attackby(shell_board, user)
	TEST_ASSERT(isturf(shell_suit.loc) && !QDELETED(shell_board), "Учебная рама не становится оболочкой ИИ.")
	TEST_ASSERT_EQUAL(length(GLOB.available_ai_shells), shells_before, "Оболочек ИИ не прибавилось.")
	qdel(shell_board)

	var/mob/living/carbon/human/donor = arena.spawn_creature("human", "robotics")
	TEST_ASSERT_NOTNULL(donor, "В секторе создаётся учебная цель.")
	var/datum/mind/donor_mind = donor.mind
	donor_mind.add_antag_datum(/datum/antagonist/cult/neutered/traitor)
	var/obj/item/mmi/mmi = new(bench)
	var/obj/item/organ/brain/brain = donor.getorganslot(ORGAN_SLOT_BRAIN)
	brain.Remove()
	TEST_ASSERT_EQUAL(brain.brainmob?.mind, donor_mind, "Разум учебной цели переходит в извлечённый мозг.")
	user.put_in_hands(brain)
	mmi.attackby(brain, user)
	TEST_ASSERT_NOTNULL(mmi.brainmob, "MMI принимает мозг учебной цели.")
	user.put_in_hands(mmi)
	suit.attackby(mmi, user)
	var/mob/living/silicon/robot/borg = suit.loc
	TEST_ASSERT(istype(borg), "Из учебной рамы собран киборг.")
	TEST_ASSERT_EQUAL(borg.mind, donor_mind, "Киборгом управляет разум учебной цели.")
	TEST_ASSERT_NULL(borg.connected_ai, "Киборг не связан с ИИ станции.")
	TEST_ASSERT(!(borg in station_ai.connected_robots), "ИИ станции не получил киборга.")
	TEST_ASSERT(!borg.lawupdate, "Законы не синхронизируются.")
	TEST_ASSERT_NOTNULL(borg.laws, "У учебного киборга есть законы.")
	TEST_ASSERT(borg.scrambledcodes, "Консоли роботов станции не видят киборга.")
	TEST_ASSERT(!borg.builtInCamera || (length(borg.builtInCamera.network) == 1 && borg.builtInCamera.network[1] == "training"), "Камера киборга вне сети станции.")
	TEST_ASSERT_NULL(borg.aiPDA, "У учебного киборга нет PDA в мессенджере станции.")
	TEST_ASSERT(!(locate(/obj/item/modular_computer/pda) in borg.GetAllContents()), "PDA не спрятан внутри киборга.")
	TEST_ASSERT(!(borg in GLOB.available_ai_shells), "Киборг не стал оболочкой ИИ.")
	TEST_ASSERT(!borg.binarycheck(), "Учебный киборг не слышит двоичный канал станции.")
	TEST_ASSERT_NOTNULL(donor_mind.has_antag_datum(/datum/antagonist/cult), "Роли владельца мозга не снимаются.")
	TEST_ASSERT_NOTNULL(donor_mind.has_antag_datum(/datum/antagonist/ghost_role/antag_training), "Учебная цель остаётся гостевой ролью.")
	borg.wires.pulse(WIRE_AI)
	TEST_ASSERT_NULL(borg.connected_ai, "Импульс по проводу ИИ не подключает учебного киборга к станции.")
	donor_mind.remove_antag_datum(/datum/antagonist/cult)

/// Модуль B.O.R.I.S. не превращает учебного киборга в оболочку ИИ станции.
/datum/unit_test/antag_training_sector_robotics_shell/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон должен подготовиться.")
	var/datum/antag_training_sector/sector = session.arena.sectors["robotics"]
	TEST_ASSERT(sector.load(), "Сектор загружается.")
	var/mob/living/user = session.current_body
	var/mob/living/silicon/robot/borg = assemble_training_borg(session.arena, sector, user)
	TEST_ASSERT(istype(borg), "Учебный киборг собран.")
	var/obj/item/crowbar/crowbar = new(get_turf(user))
	borg.crowbar_act(user, crowbar)
	TEST_ASSERT(borg.opened, "Крышка учебного киборга открывается.")
	var/shells_before = length(GLOB.available_ai_shells)
	var/obj/item/borg/upgrade/ai/board = new(get_turf(user))
	user.put_in_hands(board)
	borg.attackby(board, user)
	TEST_ASSERT(!(board in borg.upgrades) && board.loc != borg, "Учебный киборг не принимает модуль оболочки.")
	board.action(borg, user)
	TEST_ASSERT(!borg.shell, "Учебный киборг не становится оболочкой ИИ.")
	TEST_ASSERT_EQUAL(length(GLOB.available_ai_shells), shells_before, "Оболочек ИИ не прибавилось.")

/// Учебный киборг с разумом не попадает в итоговый отчёт о силиконах станции.
/datum/unit_test/antag_training_sector_robotics_report/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон должен подготовиться.")
	var/datum/antag_training_sector/sector = session.arena.sectors["robotics"]
	TEST_ASSERT(sector.load(), "Сектор загружается.")
	var/mob/living/silicon/robot/borg = assemble_training_borg(session.arena, sector, session.current_body)
	TEST_ASSERT(istype(borg) && borg.mind, "Учебный киборг с разумом собран.")
	borg.name = "Учебный киборг отчёта"
	var/mob/living/silicon/robot/station_borg = allocate(/mob/living/silicon/robot, run_loc_floor_bottom_left)
	station_borg.mind_initialize()
	allocated += station_borg.mind
	station_borg.name = "Станционный киборг отчёта"
	var/report = SSticker.law_report()
	TEST_ASSERT(findtext(report, station_borg.name), "Станционный киборг с разумом есть в отчёте силиконов.")
	TEST_ASSERT(!findtext(report, borg.name), "Учебного киборга нет в отчёте силиконов.")

/// Киборг из мозга учебной цели, собранный на первой учебной раме сектора.
/datum/unit_test/proc/assemble_training_borg(datum/antag_training_arena/arena, datum/antag_training_sector/sector, mob/living/user)
	var/obj/item/robot_suit/prebuilt/training/suit = locate() in sector.sector_area
	var/turf/bench = sector.spawn_turf()
	user.forceMove(bench)
	suit.forceMove(bench)
	suit.panel_locked = FALSE
	var/mob/living/carbon/human/donor = arena.spawn_creature("human", "robotics")
	var/obj/item/mmi/mmi = new(bench)
	var/obj/item/organ/brain/brain = donor.getorganslot(ORGAN_SLOT_BRAIN)
	brain.Remove()
	user.put_in_hands(brain)
	mmi.attackby(brain, user)
	user.put_in_hands(mmi)
	suit.attackby(mmi, user)
	return suit.loc

/// Учебный экзофаб работает на своих материалах без силоса и не печатает маячки мехов, управление ИИ и станционные рамы.
/datum/unit_test/antag_training_sector_robotics_fabricator/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон должен подготовиться.")
	var/datum/antag_training_sector/sector = session.arena.sectors["robotics"]
	TEST_ASSERT(sector.load(), "Сектор загружается.")
	var/obj/machinery/mecha_part_fabricator/offstation/training/fabricator = locate() in sector.sector_area
	TEST_ASSERT_NOTNULL(fabricator, "В секторе есть учебный экзофаб.")
	TEST_ASSERT_NULL(fabricator.rmat.silo, "Экзофаб не подключён к силосу.")
	var/datum/component/material_container/materials = fabricator.rmat.mat_container
	TEST_ASSERT_EQUAL(materials.get_material_amount(/datum/material/iron), 50 * MINERAL_MATERIAL_AMOUNT, "Металл загружен.")
	TEST_ASSERT_EQUAL(materials.get_material_amount(/datum/material/plasma), 50 * MINERAL_MATERIAL_AMOUNT, "Плазма загружена.")
	TEST_ASSERT_EQUAL(materials.get_material_amount(/datum/material/diamond), 10 * MINERAL_MATERIAL_AMOUNT, "Алмазы загружены.")
	TEST_ASSERT(fabricator.stored_research.researched_designs["ripley_chassis"], "Каркас Рипли печатается.")
	for(var/design_id in fabricator.stored_research.researched_designs)
		var/datum/design/design = SSresearch.techweb_design_by_id(design_id)
		TEST_ASSERT(!ispath(design.build_path, /obj/item/mecha_parts/mecha_tracking) && !ispath(design.build_path, /obj/item/borg/upgrade/ai) && design.build_path != /obj/item/robot_suit, "Экзофаб не печатает маячки, управление ИИ и станционные рамы: [design_id].")

/obj/item/robot_suit/prebuilt/without_client_check

/obj/item/robot_suit/prebuilt/without_client_check/mind_ready(mob/living/brain/brain_mob, mob/user)
	return !!brain_mob.mind

/// Обычная рама по-прежнему подключает киборга к ИИ станции, даёт камеру и PDA и снимает культ.
/datum/unit_test/robot_suit_station_link/Run()
	var/mob/living/carbon/human/ai_donor = allocate(/mob/living/carbon/human)
	var/mob/living/silicon/ai/station_ai = allocate(/mob/living/silicon/ai, run_loc_floor_bottom_left, null, ai_donor)
	var/obj/item/robot_suit/prebuilt/without_client_check/suit = allocate(/obj/item/robot_suit/prebuilt/without_client_check, run_loc_floor_bottom_left)
	suit.forced_ai = station_ai
	var/mob/living/carbon/human/donor = allocate_minded_human()
	var/datum/mind/donor_mind = donor.mind
	donor_mind.add_antag_datum(/datum/antagonist/cult/neutered/traitor)
	var/mob/living/carbon/human/roboticist = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/obj/item/mmi/mmi = allocate(/obj/item/mmi, run_loc_floor_bottom_left)
	var/obj/item/organ/brain/brain = donor.getorganslot(ORGAN_SLOT_BRAIN)
	brain.Remove()
	roboticist.put_in_hands(brain)
	mmi.attackby(brain, roboticist)
	roboticist.put_in_hands(mmi)
	suit.attackby(mmi, roboticist)
	var/mob/living/silicon/robot/borg = suit.loc
	TEST_ASSERT(istype(borg), "Из рамы собран киборг.")
	allocated += borg
	TEST_ASSERT_EQUAL(borg.type, /mob/living/silicon/robot, "Обычная рама собирает станционного киборга.")
	TEST_ASSERT_EQUAL(borg.mind, donor_mind, "Разум перешёл в киборга.")
	TEST_ASSERT_EQUAL(borg.connected_ai, station_ai, "Киборг подключён к ИИ станции.")
	TEST_ASSERT(borg in station_ai.connected_robots, "ИИ станции видит киборга.")
	TEST_ASSERT(borg.lawupdate, "Законы синхронизируются с ИИ.")
	TEST_ASSERT(borg.builtInCamera && ("ss13" in borg.builtInCamera.network), "Камера киборга в сети станции.")
	TEST_ASSERT_NOTNULL(borg.aiPDA, "У киборга есть PDA.")
	TEST_ASSERT_NULL(donor_mind.has_antag_datum(/datum/antagonist/cult), "Культ снимается при сборке киборга.")
