/// Шрам виден при осмотре без перчаток, скрыт перчатками и не виден на руках КПБ
/datum/unit_test/blood_brothers_scar_examine

/datum/unit_test/blood_brothers_scar_examine/Run()
	var/datum/team/brother_team/team = allocate_brother_team(src)
	var/datum/mind/member = team.members[1]
	var/mob/living/carbon/human/brother_body = member.current
	var/mob/living/carbon/human/viewer = allocate(/mob/living/carbon/human)
	TEST_ASSERT(findtext(jointext(brother_body.examine(viewer), ""), "шрам от глубокого пореза"), "Шрам виден")
	TEST_ASSERT(!findtext(jointext(viewer.examine(brother_body), ""), "шрам от глубокого пореза"), "У обычного человека шрама нет")
	var/obj/item/clothing/gloves/color/black/gloves = allocate(/obj/item/clothing/gloves/color/black)
	brother_body.equip_to_slot_or_del(gloves, ITEM_SLOT_GLOVES)
	TEST_ASSERT(!findtext(jointext(brother_body.examine(viewer), ""), "шрам от глубокого пореза"), "Перчатки скрывают шрам")
	var/datum/mind/ipc_member = team.members[2]
	var/mob/living/carbon/human/ipc_body = ipc_member.current
	ipc_body.set_species(/datum/species/ipc)
	TEST_ASSERT(!findtext(jointext(ipc_body.examine(viewer), ""), "шрам от глубокого пореза"), "На руке КПБ шрама не видно")

/// Анализатор здоровья показывает рубец и под перчатками
/datum/unit_test/blood_brothers_scar_analyzer

/datum/unit_test/blood_brothers_scar_analyzer/Run()
	var/datum/team/brother_team/team = allocate_brother_team(src)
	var/datum/mind/member = team.members[1]
	var/mob/living/carbon/human/brother_body = member.current
	var/mob/living/carbon/human/doctor = allocate(/mob/living/carbon/human)
	var/obj/item/healthanalyzer/analyzer = allocate(/obj/item/healthanalyzer)
	doctor.put_in_active_hand(analyzer)
	var/obj/item/clothing/gloves/color/black/gloves = allocate(/obj/item/clothing/gloves/color/black)
	brother_body.equip_to_slot_or_del(gloves, ITEM_SLOT_GLOVES)
	analyzer.attack(brother_body, doctor)
	TEST_ASSERT(findtext(analyzer.last_msg, "Рубец на ладони"), "Анализатор видит рубец под перчатками")
	analyzer.attack(doctor, doctor)
	TEST_ASSERT(!findtext(analyzer.last_msg, "Рубец на ладони"), "У обычного человека рубца нет")

/// Обряд священника разрывает клятву только у обездвиженного брата
/datum/unit_test/blood_brothers_rite_severs

/datum/unit_test/blood_brothers_rite_severs/Run()
	var/datum/team/brother_team/team = allocate_brother_team(src)
	var/datum/mind/member = team.members[1]
	var/mob/living/carbon/human/brother_body = member.current
	var/mob/living/carbon/human/chaplain = allocate(/mob/living/carbon/human)
	chaplain.mind_initialize()
	chaplain.mind.isholy = TRUE
	TEST_ASSERT(!brother_sever_rite(chaplain, brother_body, instant = TRUE), "Свободного брата обряд не берёт")
	brother_body.Paralyze(10 SECONDS)
	chaplain.mind.isholy = FALSE
	TEST_ASSERT(!brother_sever_rite(chaplain, brother_body, instant = TRUE), "Обряд не для мирян")
	chaplain.mind.isholy = TRUE
	TEST_ASSERT(brother_sever_rite(chaplain, brother_body, instant = TRUE), "Обряд прошёл")
	TEST_ASSERT_NULL(member.has_antag_datum(/datum/antagonist/brother), "Клятва разорвана")
	TEST_ASSERT(member in team.severed_minds, "Разорванный запомнен")
	TEST_ASSERT_EQUAL(team.severed_kinds[member], BROTHER_SEVER_RITE, "Разрыв записан как обряд")
	TEST_ASSERT(!HAS_TRAIT(brother_body, TRAIT_BLOOD_OATH_SCAR), "Шрам ушёл вместе с клятвой")
	var/mob/living/carbon/human/viewer = allocate(/mob/living/carbon/human)
	TEST_ASSERT(!findtext(jointext(brother_body.examine(viewer), ""), "шрам от глубокого пореза"), "Осмотр больше не видит шрама")
	TEST_ASSERT(!brother_sever_rite(chaplain, brother_body, instant = TRUE), "Разорванную клятву второй раз не рвут")

/// Библия в руке священника начинает обряд над лежащим братом, вставший брат его срывает
/datum/unit_test/blood_brothers_rite_bible

/datum/unit_test/blood_brothers_rite_bible/Run()
	var/datum/team/brother_team/team = allocate_brother_team(src)
	var/datum/mind/member = team.members[1]
	var/mob/living/carbon/human/brother_body = member.current
	var/mob/living/carbon/human/chaplain = allocate(/mob/living/carbon/human)
	chaplain.mind_initialize()
	chaplain.mind.isholy = TRUE
	var/obj/item/storage/book/bible/bible = allocate(/obj/item/storage/book/bible)
	chaplain.put_in_active_hand(bible)
	TEST_ASSERT(findtext(jointext(bible.examine(chaplain), ""), "шрам кровной клятвы"), "Священник знает про обряд из описания книги")
	TEST_ASSERT(!findtext(jointext(bible.examine(brother_body), ""), "шрам кровной клятвы"), "Мирянину книга про обряд не говорит")
	bible.attack(brother_body, chaplain)
	TEST_ASSERT(!LAZYFIND(chaplain.do_afters, brother_body), "Над стоящим братом обряд не начинается")
	brother_body.Paralyze(10 SECONDS)
	bible.attack(brother_body, chaplain)
	TEST_ASSERT(LAZYFIND(chaplain.do_afters, brother_body), "Библия начала обряд над лежащим братом")
	brother_body.SetParalyzed(0)
	brother_body.set_resting(FALSE)
	TEST_ASSERT_EQUAL(brother_body.body_position, STANDING_UP, "Брат поднялся")
	for(var/tick in 1 to 20)
		if(!LAZYFIND(chaplain.do_afters, brother_body))
			break
		sleep(world.tick_lag)
	TEST_ASSERT(!LAZYFIND(chaplain.do_afters, brother_body), "Вставший брат срывает обряд")
	TEST_ASSERT_NOTNULL(member.has_antag_datum(/datum/antagonist/brother), "Сорванный обряд клятву не рвёт")

/// Операция иссечения шрама доступна только на брате и разрывает клятву
/datum/unit_test/blood_brothers_surgery_severs

/datum/unit_test/blood_brothers_surgery_severs/Run()
	var/datum/team/brother_team/team = allocate_brother_team(src)
	var/datum/mind/member = team.members[1]
	var/mob/living/carbon/human/brother_body = member.current
	var/mob/living/carbon/human/surgeon = allocate(/mob/living/carbon/human)
	surgeon.mind_initialize()
	var/datum/surgery/blood_oath_scar/listed = locate(/datum/surgery/blood_oath_scar) in GLOB.surgeries_list
	TEST_ASSERT_NOTNULL(listed, "Операция есть в списке хирургии")
	TEST_ASSERT(listed.can_start(surgeon, brother_body), "Операцию можно начать на брате")
	TEST_ASSERT(!listed.can_start(surgeon, surgeon), "Без шрама операции нет")
	var/datum/surgery/blood_oath_scar/surgery = new(brother_body, BODY_ZONE_R_ARM, brother_body.get_bodypart(BODY_ZONE_R_ARM))
	allocated += surgery
	var/obj/item/scalpel/scalpel = allocate(/obj/item/scalpel)
	var/datum/surgery_step/excise_oath_scar/excise = new
	excise.success(surgeon, brother_body, BODY_ZONE_R_ARM, scalpel, surgery)
	TEST_ASSERT_NULL(member.has_antag_datum(/datum/antagonist/brother), "Операция разорвала клятву")
	TEST_ASSERT(member in team.severed_minds, "Разорванный запомнен")
	TEST_ASSERT_EQUAL(team.severed_kinds[member], BROTHER_SEVER_SURGERY, "Разрыв записан как операция")
	TEST_ASSERT(!listed.can_start(surgeon, brother_body), "Иссечённый шрам второй операции не даёт")
	excise.success(surgeon, brother_body, BODY_ZONE_R_ARM, scalpel, surgery)
	TEST_ASSERT_EQUAL(length(team.severed_minds), 1, "Повторное иссечение ничего не рвёт")
	qdel(excise)

/// Живая рука берёт обычное иссечение шрама, руки КПБ и протезы - механическое
/datum/unit_test/blood_brothers_scar_surgery_limb_types
	var/list/saved_surgeries

/datum/unit_test/blood_brothers_scar_surgery_limb_types/Destroy()
	if(saved_surgeries)
		GLOB.surgeries_list = saved_surgeries
		saved_surgeries = null
	return ..()

/datum/unit_test/blood_brothers_scar_surgery_limb_types/Run()
	var/datum/team/brother_team/team = allocate_brother_team(src)
	var/datum/mind/organic_member = team.members[1]
	var/datum/mind/ipc_member = team.members[2]
	var/mob/living/carbon/human/organic_body = organic_member.current
	var/mob/living/carbon/human/ipc_body = ipc_member.current
	ipc_body.set_species(/datum/species/ipc)
	var/obj/item/bodypart/ipc_arm = ipc_body.get_bodypart(BODY_ZONE_R_ARM)
	TEST_ASSERT_EQUAL(ipc_arm.status, BODYPART_HYBRID, "Руки КПБ гибридные")
	TEST_ASSERT(HAS_TRAIT(ipc_body, TRAIT_BLOOD_OATH_SCAR), "Шрам на КПБ остался")
	var/mob/living/carbon/human/stranger_ipc = allocate(/mob/living/carbon/human/species/ipc)
	for(var/mob/living/carbon/human/patient as anything in list(organic_body, ipc_body, stranger_ipc))
		patient.Paralyze(30 SECONDS)
		TEST_ASSERT(patient.lying, "Пациент лежит")
	var/mob/living/carbon/human/surgeon = allocate(/mob/living/carbon/human)
	surgeon.mind_initialize()
	surgeon.zone_selected = BODY_ZONE_R_ARM
	var/obj/item/surgical_drapes/drapes = allocate(/obj/item/surgical_drapes)
	surgeon.put_in_active_hand(drapes)
	var/datum/surgery/organic_surgery
	var/datum/surgery/mechanic_surgery
	for(var/datum/surgery/listed as anything in GLOB.surgeries_list)
		if(listed.type == /datum/surgery/blood_oath_scar)
			organic_surgery = listed
		else if(listed.type == /datum/surgery/blood_oath_scar/mechanic)
			mechanic_surgery = listed
	TEST_ASSERT_NOTNULL(organic_surgery, "Обычное иссечение в списке хирургии")
	TEST_ASSERT_NOTNULL(mechanic_surgery, "Механическое иссечение в списке хирургии")
	saved_surgeries = GLOB.surgeries_list
	GLOB.surgeries_list = list(organic_surgery)
	TEST_ASSERT(attempt_initiate_surgery(drapes, organic_body, surgeon), "Обычное иссечение предлагается на живой руке")
	TEST_ASSERT(!attempt_initiate_surgery(drapes, ipc_body, surgeon), "Обычное иссечение не берёт руку КПБ")
	GLOB.surgeries_list = list(mechanic_surgery)
	TEST_ASSERT(!attempt_initiate_surgery(drapes, organic_body, surgeon), "Механическое иссечение не берёт живую руку")
	TEST_ASSERT(attempt_initiate_surgery(drapes, ipc_body, surgeon), "Механическое иссечение берёт гибридную руку КПБ")
	TEST_ASSERT(!attempt_initiate_surgery(drapes, stranger_ipc, surgeon), "Без шрама операции нет и у КПБ")
	var/obj/item/bodypart/organic_arm = organic_body.get_bodypart(BODY_ZONE_R_ARM)
	organic_arm.change_bodypart_status(BODYPART_ROBOTIC)
	TEST_ASSERT(attempt_initiate_surgery(drapes, organic_body, surgeon), "Механическое иссечение берёт протез")
	GLOB.surgeries_list = saved_surgeries
	saved_surgeries = null

/// Анализатор пишет о рубце, только если хотя бы одна рука живая
/datum/unit_test/blood_brothers_scar_analyzer_robotic

/datum/unit_test/blood_brothers_scar_analyzer_robotic/Run()
	var/datum/team/brother_team/team = allocate_brother_team(src)
	var/datum/mind/ipc_member = team.members[1]
	var/datum/mind/prosthetic_member = team.members[2]
	var/mob/living/carbon/human/ipc_body = ipc_member.current
	var/mob/living/carbon/human/prosthetic_body = prosthetic_member.current
	ipc_body.set_species(/datum/species/ipc)
	var/mob/living/carbon/human/doctor = allocate(/mob/living/carbon/human)
	var/obj/item/healthanalyzer/analyzer = allocate(/obj/item/healthanalyzer)
	doctor.put_in_active_hand(analyzer)
	analyzer.attack(ipc_body, doctor)
	TEST_ASSERT(!findtext(analyzer.last_msg, "Рубец на ладони"), "У КПБ анализатор о ладони молчит")
	TEST_ASSERT(!findtext(analyzer.last_msg, "манипулятор"), "О манипуляторе анализатор тоже молчит")
	var/obj/item/bodypart/right_arm = prosthetic_body.get_bodypart(BODY_ZONE_R_ARM)
	right_arm.change_bodypart_status(BODYPART_ROBOTIC)
	analyzer.attack(prosthetic_body, doctor)
	TEST_ASSERT(findtext(analyzer.last_msg, "Рубец на ладони"), "С одной живой рукой рубец виден")
	var/obj/item/bodypart/left_arm = prosthetic_body.get_bodypart(BODY_ZONE_L_ARM)
	left_arm.change_bodypart_status(BODYPART_ROBOTIC)
	analyzer.attack(prosthetic_body, doctor)
	TEST_ASSERT(!findtext(analyzer.last_msg, "Рубец на ладони"), "С двумя протезами рубца не видно")

/// Пока над братом читают обряд, незаглушённые братья чувствуют, где это; сорванный обряд гасит тревогу
/datum/unit_test/blood_brothers_rite_alarm

/datum/unit_test/blood_brothers_rite_alarm/Run()
	var/datum/team/brother_team/team = allocate_brother_team(src, BROTHER_TEAM_MAX_SIZE)
	var/datum/mind/target_member = team.members[1]
	var/datum/mind/alarmed_member = team.members[2]
	var/datum/mind/muted_member = team.members[3]
	var/mob/living/carbon/human/target_body = target_member.current
	var/mob/living/carbon/human/alarmed_body = alarmed_member.current
	var/mob/living/carbon/human/muted_body = muted_member.current
	alarmed_body.forceMove(run_loc_floor_top_right)
	ADD_TRAIT(muted_body, TRAIT_MINDSHIELD, "test")
	var/mob/living/carbon/human/chaplain = allocate(/mob/living/carbon/human)
	chaplain.mind_initialize()
	chaplain.mind.isholy = TRUE
	var/obj/item/storage/book/bible/bible = allocate(/obj/item/storage/book/bible)
	chaplain.put_in_active_hand(bible)

	ADD_TRAIT(target_body, TRAIT_MINDSHIELD, "test")
	target_body.Paralyze(30 SECONDS)
	bible.attack(target_body, chaplain)
	TEST_ASSERT(LAZYFIND(chaplain.do_afters, target_body), "Обряд над заглушённым братом начался")
	TEST_ASSERT_NULL(alarmed_body.has_status_effect(/datum/status_effect/brother_sense/rite), "Заглушённого брата нить не выдаёт")
	if(!rite_interrupted(target_body, chaplain))
		return
	REMOVE_TRAIT(target_body, TRAIT_MINDSHIELD, "test")

	target_body.Paralyze(30 SECONDS)
	bible.attack(target_body, chaplain)
	TEST_ASSERT(LAZYFIND(chaplain.do_afters, target_body), "Обряд начался")
	var/datum/status_effect/brother_sense/rite/alarm = alarmed_body.has_status_effect(/datum/status_effect/brother_sense/rite)
	TEST_ASSERT_NOTNULL(alarm, "Брат чувствует обряд")
	TEST_ASSERT_EQUAL(alarm.tracked, target_member, "Тревога о том, над кем читают")
	TEST_ASSERT_EQUAL(alarm.linked_alert.name, "Нить натянулась", "Алерт назван")
	TEST_ASSERT(findtext(alarm.linked_alert.desc, "юго-запад"), "Направление к обряду словами: [alarm.linked_alert.desc]")
	TEST_ASSERT_NULL(muted_body.has_status_effect(/datum/status_effect/brother_sense/rite), "Заглушённый брат обряда не чувствует")
	TEST_ASSERT_NULL(target_body.has_status_effect(/datum/status_effect/brother_sense/rite), "Сам брат тревоги о себе не получает")
	for(var/datum/antagonist/brother/brother as anything in team.brother_antags())
		brother.update_sense()
	TEST_ASSERT_NOTNULL(alarmed_body.has_status_effect(/datum/status_effect/brother_sense), "Обычное Чутьё рядом с тревогой")
	TEST_ASSERT_EQUAL(alarmed_body.has_status_effect(/datum/status_effect/brother_sense/rite), alarm, "Чутьё не сбивает тревогу")
	if(!rite_interrupted(target_body, chaplain))
		return
	TEST_ASSERT_NULL(alarmed_body.has_status_effect(/datum/status_effect/brother_sense/rite), "Сорванный обряд гасит тревогу")
	TEST_ASSERT_NOTNULL(target_member.has_antag_datum(/datum/antagonist/brother), "Сорванный обряд клятву не рвёт")

/datum/unit_test/blood_brothers_rite_alarm/proc/rite_interrupted(mob/living/carbon/human/target_body, mob/living/chaplain)
	target_body.SetParalyzed(0)
	target_body.set_resting(FALSE)
	for(var/tick in 1 to 20)
		if(!LAZYFIND(chaplain.do_afters, target_body))
			break
		sleep(world.tick_lag)
	if(LAZYFIND(chaplain.do_afters, target_body))
		Fail("Вставший брат не сорвал обряд", __FILE__, __LINE__)
		return FALSE
	return TRUE

/// После обряда или операции на ладони 15 минут виден свежий ожог или шов, анализатор пишет, что рубец иссечён
/datum/unit_test/blood_brothers_fresh_seam

/datum/unit_test/blood_brothers_fresh_seam/Run()
	var/datum/team/brother_team/rite_team = allocate_brother_team(src)
	var/datum/mind/rite_member = rite_team.members[1]
	var/mob/living/carbon/human/rite_body = rite_member.current
	var/mob/living/carbon/human/chaplain = allocate(/mob/living/carbon/human)
	chaplain.mind_initialize()
	chaplain.mind.isholy = TRUE
	var/mob/living/carbon/human/viewer = allocate(/mob/living/carbon/human)
	var/obj/item/healthanalyzer/analyzer = allocate(/obj/item/healthanalyzer)
	viewer.put_in_active_hand(analyzer)
	rite_body.Paralyze(10 SECONDS)
	TEST_ASSERT(brother_sever_rite(chaplain, rite_body, instant = TRUE), "Обряд прошёл")
	TEST_ASSERT(findtext(jointext(rite_body.examine(viewer), ""), "ладони - свежий ожог"), "После обряда на ладони свежий ожог")
	analyzer.attack(rite_body, viewer)
	TEST_ASSERT(findtext(analyzer.last_msg, "Рубец на ладони иссечён, на его месте свежий ожог"), "Анализатор видит иссечённый рубец: [analyzer.last_msg]")
	var/obj/item/clothing/gloves/color/black/gloves = allocate(/obj/item/clothing/gloves/color/black)
	rite_body.equip_to_slot_or_del(gloves, ITEM_SLOT_GLOVES)
	TEST_ASSERT(!findtext(jointext(rite_body.examine(viewer), ""), "свежий ожог"), "Перчатки скрывают ожог")

	var/datum/team/brother_team/surgery_team = allocate_brother_team(src)
	var/datum/mind/surgery_member = surgery_team.members[1]
	var/mob/living/carbon/human/surgery_body = surgery_member.current
	var/mob/living/carbon/human/surgeon = allocate(/mob/living/carbon/human)
	surgeon.mind_initialize()
	var/datum/surgery/blood_oath_scar/surgery = new(surgery_body, BODY_ZONE_R_ARM, surgery_body.get_bodypart(BODY_ZONE_R_ARM))
	allocated += surgery
	var/obj/item/scalpel/scalpel = allocate(/obj/item/scalpel)
	var/datum/surgery_step/excise_oath_scar/excise = new
	excise.success(surgeon, surgery_body, BODY_ZONE_R_ARM, scalpel, surgery)
	qdel(excise)
	TEST_ASSERT(findtext(jointext(surgery_body.examine(viewer), ""), "ладони - свежий шов"), "После операции на ладони свежий шов")
	var/datum/component/blood_oath_seam/seam = surgery_body.GetComponent(/datum/component/blood_oath_seam)
	TEST_ASSERT_NOTNULL(seam, "След на теле")
	var/datum/timedevent/heal_timer = SStimer.timer_id_dict[seam.heal_timer]
	TEST_ASSERT_NOTNULL(heal_timer, "След заживает по таймеру")
	TEST_ASSERT(abs(heal_timer.timeToRun - world.time - BROTHER_FRESH_SEAM_DURATION) < 1 SECONDS, "Заживает через 15 минут")
	heal_timer.callBack.Invoke()
	TEST_ASSERT_NULL(surgery_body.GetComponent(/datum/component/blood_oath_seam), "След зажил")
	TEST_ASSERT(!findtext(jointext(surgery_body.examine(viewer), ""), "свежий шов"), "Заживший шов не виден")
	analyzer.attack(surgery_body, viewer)
	TEST_ASSERT(!findtext(analyzer.last_msg, "Рубец на ладони"), "Анализатор о зажившем рубце молчит")

	var/datum/team/brother_team/ipc_team = allocate_brother_team(src)
	var/datum/mind/ipc_member = ipc_team.members[1]
	var/mob/living/carbon/human/ipc_body = ipc_member.current
	ipc_body.set_species(/datum/species/ipc)
	var/datum/surgery/blood_oath_scar/mechanic/mechanic_surgery = new(ipc_body, BODY_ZONE_R_ARM, ipc_body.get_bodypart(BODY_ZONE_R_ARM))
	allocated += mechanic_surgery
	excise = new
	excise.success(surgeon, ipc_body, BODY_ZONE_R_ARM, scalpel, mechanic_surgery)
	qdel(excise)
	TEST_ASSERT_NULL(ipc_member.has_antag_datum(/datum/antagonist/brother), "Механическая операция разорвала клятву")
	TEST_ASSERT(!findtext(jointext(ipc_body.examine(viewer), ""), "свежий шов"), "На руке КПБ шва не видно")
	analyzer.attack(ipc_body, viewer)
	TEST_ASSERT(!findtext(analyzer.last_msg, "Рубец на ладони"), "У КПБ анализатор о ладони молчит")
