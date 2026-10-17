/// Посвящение: ушедший до клятвы брат финал не держит, но уйти должны трое живых
/datum/unit_test/blood_brothers_oath_initiation_departed/Run()
	var/datum/antag_opt_in_test_world/world_state = blood_brothers_oath_world()
	var/datum/team/brother_team/team = allocate_brother_team(src)
	var/datum/mind/replacement = blood_brothers_target(ANTAG_OPT_IN_NOT_TARGET)
	var/datum/mind/third = blood_brothers_target(ANTAG_OPT_IN_NOT_TARGET)
	world_state.set_crew(team.members + replacement + third)
	var/datum/mind/first = team.members[1]
	var/datum/mind/gone = team.members[2]
	team.handle_departure(gone, BROTHER_DEPARTURE_CRYO)
	var/datum/blood_oath/initiation/oath = new
	TEST_ASSERT(oath.available(team), "Посвящение доступно после ухода брата")
	TEST_ASSERT(oath.prepare(team), "Посвящение готово")
	team.swear_oath(oath)
	TEST_ASSERT(team.recruit(replacement), "Замена принята")
	TEST_ASSERT(team.recruit(third), "Третий принят")
	for(var/datum/mind/member as anything in list(first, replacement, third))
		member.force_escaped = TRUE
	TEST_ASSERT(oath.finale_extra_complete(), "Трое живых ушли вместе, ушедший до клятвы не мешает")
	replacement.current.death()
	TEST_ASSERT(!oath.finale_extra_complete(), "Живых ушло двое - Посвящение не исполнено")

/// Цель ушла до первой печати: клятва подбирается заново с тем же обетом
/datum/unit_test/blood_brothers_oath_target_remade/Run()
	var/datum/antag_opt_in_test_world/world_state = blood_brothers_oath_world()
	var/datum/team/brother_team/team = allocate_brother_team(src)
	var/list/datum/mind/crew = list()
	for(var/crew_number in 1 to 3)
		crew += blood_brothers_target(ANTAG_OPT_IN_ROUND_REMOVE)
	world_state.set_crew(team.members + crew)
	GLOB.round_type = ROUNDTYPE_DYNAMIC_LIGHT
	var/datum/blood_oath/vendetta/oath = new
	TEST_ASSERT(oath.prepare(team), "Месть готова")
	oath.vow_type = /datum/blood_vow/shoulder
	team.swear_oath(oath)
	var/datum/blood_vow/vow = team.vow
	var/datum/mind/ghosted = oath.target_mind
	ghosted.current.mock_client = null
	oath.on_team_tick()
	TEST_ASSERT_EQUAL(team.oath, oath, "Без игрока совсем недолго - цель та же")
	oath.target_away_since -= BROTHER_GHOST_GRACE
	team.process()
	var/datum/blood_oath/vendetta/remade = team.oath
	TEST_ASSERT(QDELETED(oath), "Старая клятва снята")
	TEST_ASSERT(istype(remade), "Клятва та же - Месть")
	TEST_ASSERT_NOTEQUAL(remade.target_mind, ghosted, "Тело без игрока дольше грации - новая цель")
	TEST_ASSERT(remade.target_mind in crew, "Новая цель из экипажа")
	TEST_ASSERT_EQUAL(team.vow, vow, "Обет остался")
	TEST_ASSERT(findtext(remade.story, remade.target_mind.name), "История о новой цели")
	var/datum/mind/vanished = remade.target_mind
	vanished.current.moveToNullspace()
	remade.on_team_tick()
	var/datum/blood_oath/vendetta/last = team.oath
	TEST_ASSERT(QDELETED(remade), "Цель без тела - клятва снова подобрана")
	TEST_ASSERT(!(last.target_mind in list(ghosted, vanished)), "Ушедшие цели не выбраны")
	last.target_mind.current.death()
	last.on_team_tick()
	TEST_ASSERT_EQUAL(team.oath, last, "Труп - не уход")

/// Цель стала антагонистом после печати: замену ищут раз в BROTHER_TARGET_RETRY_INTERVAL, скреплённое остаётся, остальные шаги - на новую цель
/datum/unit_test/blood_brothers_oath_target_retarget/Run()
	var/datum/antag_opt_in_test_world/world_state = blood_brothers_oath_world()
	var/datum/team/brother_team/team = allocate_brother_team(src)
	var/datum/mind/first_target = blood_brothers_target(ANTAG_OPT_IN_ROUND_REMOVE)
	world_state.set_crew(team.members + first_target)
	GLOB.round_type = ROUNDTYPE_DYNAMIC_LIGHT
	var/datum/blood_oath/vendetta/oath = new
	TEST_ASSERT(oath.prepare(team), "Месть готова")
	oath.vow_type = /datum/blood_vow/shadow
	team.swear_oath(oath)
	var/datum/mind/first = team.members[1]
	var/obj/item/card/id/card = allocate(/obj/item/card/id)
	card.registered_name = first_target.name
	first.current.put_in_hands(card)
	TEST_ASSERT(team.try_seal(first) == TRUE, "Первый шаг скреплён")
	var/datum/blood_oath_step/sealed_step = oath.steps[1]
	var/datum/blood_oath_step/old_arrest = oath.steps[2]
	var/datum/team/brother_team/other_team = allocate_brother_team(src)
	var/datum/antagonist/brother/turncoat = new
	turncoat.silent = TRUE
	first_target.add_antag_datum(turncoat, other_team)
	oath.on_team_tick()
	TEST_ASSERT_EQUAL(team.oath, oath, "Замены нет - клятва на месте")
	TEST_ASSERT(oath.target_lost, "Братьям сказали, что замены нет")
	var/datum/mind/second_target = blood_brothers_target(ANTAG_OPT_IN_ROUND_REMOVE)
	world_state.set_crew(team.members + first_target + second_target)
	team.next_sense_at = 0
	team.process()
	TEST_ASSERT_EQUAL(oath.target_mind, first_target, "Замену ищут не на каждом тике")
	oath.next_target_search_at = world.time
	team.next_sense_at = 0
	team.process()
	TEST_ASSERT_EQUAL(team.oath, oath, "С печатью клятва та же")
	TEST_ASSERT_EQUAL(oath.target_mind, second_target, "Цель-антагонист заменена")
	TEST_ASSERT_EQUAL(oath.steps[1], sealed_step, "Скреплённый шаг остался")
	TEST_ASSERT(sealed_step.sealed, "И остался скреплённым")
	TEST_ASSERT(oath.steps[2] != old_arrest && QDELETED(old_arrest), "Нескреплённый шаг пересобран")
	var/datum/blood_oath_step/new_arrest = oath.steps[2]
	TEST_ASSERT(findtext(new_arrest.name, second_target.name), "Шаг назван по новой цели: [new_arrest.name]")
	TEST_ASSERT_EQUAL(new_arrest.oath, oath, "Новый шаг привязан к клятве")
	TEST_ASSERT_EQUAL(team.bond_tier, 1, "Печать не потеряна")

/// Цель отпала к подписи: ручная подпись снимает предложение, таймер подбирает заново
/datum/unit_test/blood_brothers_oath_signing_lost_target/Run()
	var/datum/antag_opt_in_test_world/world_state = blood_brothers_oath_world()
	var/datum/team/brother_team/team = allocate_brother_team(src)
	var/datum/mind/doomed = blood_brothers_target(ANTAG_OPT_IN_ROUND_REMOVE)
	var/datum/mind/spare = blood_brothers_target(ANTAG_OPT_IN_ROUND_REMOVE)
	world_state.set_crew(team.members + doomed)
	GLOB.round_type = ROUNDTYPE_DYNAMIC_LIGHT
	var/datum/mind/first = team.members[1]
	var/datum/mind/second = team.members[2]
	var/datum/antagonist/brother/first_brother = first.has_antag_datum(/datum/antagonist/brother)
	var/datum/antagonist/brother/second_brother = second.has_antag_datum(/datum/antagonist/brother)
	var/datum/blood_oath/vendetta/oath = new
	TEST_ASSERT(oath.prepare(team), "Месть готова")
	team.offered += oath
	var/datum/tgui/first_ui = allocate(/datum/tgui, first.current, first_brother, "AntagInfoBloodBrother")
	first_ui.status = UI_INTERACTIVE
	var/datum/tgui/second_ui = allocate(/datum/tgui, second.current, second_brother, "AntagInfoBloodBrother")
	second_ui.status = UI_INTERACTIVE
	TEST_ASSERT(first_brother.ui_act("propose", list("key" = oath.key), first_ui), "Месть предложена")
	world_state.set_crew(team.members + doomed + spare)
	doomed.current.moveToNullspace()
	TEST_ASSERT(!second_brother.ui_act("sign", list(), second_ui), "Подпись отпавшей клятвы не проходит")
	TEST_ASSERT_NULL(team.oath, "Клятва не дана с подменённой целью")
	TEST_ASSERT(QDELETED(oath), "Отпавшее предложение снято")
	TEST_ASSERT_NULL(team.proposed, "Предложения больше нет")
	TEST_ASSERT(length(team.offered), "Взамен предложены новые клятвы")
	doomed.current.forceMove(run_loc_floor_bottom_left)
	var/datum/blood_oath/vendetta/late = new
	TEST_ASSERT(late.prepare(team), "Вторая Месть готова")
	team.offered.Insert(1, late)
	TEST_ASSERT(team.propose_oath(first, late.key), "Вторая Месть предложена")
	var/datum/mind/late_target = late.target_mind
	late_target.current.moveToNullspace()
	team.oath_timeout()
	TEST_ASSERT_EQUAL(team.oath, late, "По таймеру клятва подобрана заново")
	TEST_ASSERT_NOTEQUAL(late.target_mind, late_target, "И цель у неё новая")

/// Смена имени цели: тексты шагов по новому имени, ID-карта на старое имя годится
/datum/unit_test/blood_brothers_oath_target_renamed/Run()
	var/datum/antag_opt_in_test_world/world_state = blood_brothers_oath_world()
	var/datum/team/brother_team/team = allocate_brother_team(src)
	var/datum/mind/victim = blood_brothers_target(ANTAG_OPT_IN_ROUND_REMOVE)
	world_state.set_crew(team.members + victim)
	GLOB.round_type = ROUNDTYPE_DYNAMIC_LIGHT
	var/datum/blood_oath/vendetta/oath = new
	TEST_ASSERT(oath.prepare(team), "Месть готова")
	team.swear_oath(oath)
	var/old_name = victim.name
	var/datum/mind/first = team.members[1]
	var/obj/item/card/id/card = allocate(/obj/item/card/id)
	card.registered_name = old_name
	victim.current.fully_replace_character_name(old_name, "Новое Имя")
	TEST_ASSERT_EQUAL(victim.name, "Новое Имя", "Цель переименована")
	oath.on_team_tick()
	var/datum/blood_oath_step/arrest_step = oath.steps[2]
	TEST_ASSERT(findtext(arrest_step.name, "Новое Имя"), "Шаг называет новое имя: [arrest_step.name]")
	TEST_ASSERT(findtext(oath.story, "Новое Имя"), "История называет новое имя")
	first.current.put_in_hands(card)
	TEST_ASSERT(team.try_seal(first) == TRUE, "ID-карта на старое имя скрепляет шаг")

/// Ценности, которые братьям не достать, в клятвы не попадают; длинное имя ценности обрезано до первой фразы
/datum/unit_test/blood_brothers_oath_steal_pool/Run()
	blood_brothers_oath_world()
	var/datum/team/brother_team/team = allocate_brother_team(src)
	var/datum/objective_item/disk = allocate(/datum/objective_item/steal/nukedisc)
	var/datum/objective_item/ai_card = allocate(/datum/objective_item/steal/functionalai)
	GLOB.possible_items = list(disk, ai_card)
	TEST_ASSERT_NULL(brother_steal_pick(team), "Ни диск, ни ИИ в карте братьям не выпадают")
	var/datum/objective_item/blackbox = allocate(/datum/objective_item/steal/blackbox)
	GLOB.possible_items = list(disk, ai_card, blackbox)
	TEST_ASSERT_EQUAL(brother_steal_pick(team), blackbox, "Выпадает доступная ценность")
	TEST_ASSERT_EQUAL(brother_item_name(blackbox), "черный ящик из бортового устройства записи", "Имя ценности - первая фраза")

/// Компромат не берёт заключённых; у должности без отдела чужого отдела нет
/datum/unit_test/blood_brothers_oath_compromat_targets/Run()
	var/datum/antag_opt_in_test_world/world_state = blood_brothers_oath_world()
	var/datum/team/brother_team/team = allocate_brother_team(src)
	world_state.set_crew(team.members + blood_brothers_target(ANTAG_OPT_IN_ROUND_REMOVE, "Prisoner"))
	heretic_test_area(blood_brothers_floor(3, 3), /area/command/heads_quarters/hop)
	var/datum/blood_oath/compromat/oath = allocate(/datum/blood_oath/compromat)
	TEST_ASSERT(!oath.prepare(team), "Заключённый целью Компромата не выпадает")
	var/datum/mind/first = team.members[1]
	var/mob/living/carbon/human/photographer = first.current
	var/turf/ward = get_step(photographer, NORTH)
	heretic_test_area(ward, /area/medical)
	var/mob/living/carbon/human/assistant = allocate(/mob/living/carbon/human, ward)
	assistant.mind_initialize()
	assistant.mind.assigned_role = "Assistant"
	var/obj/item/camera/camera = allocate(/obj/item/camera)
	camera.can_customise = FALSE
	photographer.put_in_hands(camera)
	camera.captureimage(get_turf(photographer), photographer, null, 1, 1)
	var/obj/item/photo/photo = locate() in photographer.held_items
	TEST_ASSERT_NOTNULL(photo, "Фото напечатано")
	allocated += photo
	var/list/assistant_state = photo.picture.subjects_seen[WEAKREF(assistant.mind)]
	TEST_ASSERT_NOTNULL(assistant_state, "Ассистент в кадре")
	TEST_ASSERT(!assistant_state["foreign_area"], "У ассистента нет своего отдела - и чужого тоже")

/// Заглушённый и ушедший брат шаттл не взламывает
/datum/unit_test/blood_brothers_oath_hijack_muted/Run()
	var/datum/antag_opt_in_test_world/world_state = blood_brothers_oath_world()
	var/datum/team/brother_team/team = allocate_brother_team(src)
	world_state.set_hard_round(src)
	var/datum/blood_oath/hijack/oath = new
	TEST_ASSERT(oath.prepare(team), "Угон готов")
	team.swear_oath(oath)
	var/datum/mind/first = team.members[1]
	var/datum/mind/second = team.members[2]
	TEST_ASSERT_EQUAL(first.get_hijack_speed(), BROTHER_HIJACK_SPEED, "Брат с клятвой Угона взламывает шаттл")
	var/obj/item/implant/mindshield/shield = allocate(/obj/item/implant/mindshield)
	TEST_ASSERT(shield.implant(first.current, null, TRUE), "Майндшилд встал")
	TEST_ASSERT_EQUAL(first.get_hijack_speed(), 0, "Заглушённый брат шаттл не взламывает")
	team.handle_departure(second, BROTHER_DEPARTURE_CRYO)
	TEST_ASSERT_EQUAL(second.get_hijack_speed(), 0, "Ушедший брат шаттл не взламывает")

/// На полигоне нет ни Разлада, ни Угона
/datum/unit_test/blood_brothers_oath_training_limits/Run()
	var/datum/antag_opt_in_test_world/world_state = blood_brothers_oath_world()
	var/datum/team/brother_team/team = allocate_brother_team(src)
	team.training = TRUE
	var/datum/blood_oath/discord/discord = allocate(/datum/blood_oath/discord)
	GLOB.round_type = ROUNDTYPE_DYNAMIC_MEDIUM
	TEST_ASSERT(!discord.available(team), "Учебной команде Разлад не предлагается")
	world_state.set_hard_round(src)
	var/datum/blood_oath/hijack/hijack = allocate(/datum/blood_oath/hijack)
	TEST_ASSERT(!hijack.available(team), "Учебной команде Угон не предлагается")
	TEST_ASSERT(!hijack.prepare(team), "Угон на полигоне не готовится")

/// Тексты шагов: ценности в винительном падеже, без Схрона, машины названы игровым именем
/datum/unit_test/blood_brothers_oath_texts/Run()
	var/datum/antag_opt_in_test_world/world_state = blood_brothers_oath_world()
	var/datum/team/brother_team/team = allocate_brother_team(src)
	world_state.set_crew(team.members + blood_brothers_target(ANTAG_OPT_IN_ROUND_REMOVE, "Scientist") + blood_brothers_target(ANTAG_OPT_IN_TEMPORARY, "Prisoner"))
	var/turf/office = blood_brothers_floor(3, 3)
	heretic_test_area(office, /area/command/heads_quarters/rd)
	world_state.set_hard_round(src)
	for(var/oath_type in list(/datum/blood_oath/heist, /datum/blood_oath/vendetta, /datum/blood_oath/liberation, /datum/blood_oath/blood_debt, /datum/blood_oath/exposure, /datum/blood_oath/compromat, /datum/blood_oath/hijack))
		var/datum/blood_oath/oath = allocate(oath_type)
		TEST_ASSERT(oath.prepare(team), "[oath_type] готова")
		for(var/datum/blood_oath_step/oath_step as anything in oath.steps)
			TEST_ASSERT(!findtextEx(oath_step.desc, "Схрон"), "[oath_type]: шаг не говорит о Схроне: [oath_step.desc]")
	var/datum/blood_oath/heist/heist = allocate(/datum/blood_oath/heist)
	heist.prepare(team)
	TEST_ASSERT(findtext(heist.story, "добудьте"), "История Добычи под винительный падеж: [heist.story]")
	var/datum/blood_oath_step/heist_item/item_step = heist.steps[1]
	TEST_ASSERT(findtext(item_step.desc, "Добудьте [item_step.item_name]"), "Шаг Добычи под винительный падеж: [item_step.desc]")
	var/machine_text = brother_discord_machine_text(GLOB.brother_discord_targets["инженерия"])
	TEST_ASSERT(findtext(machine_text, "power storage unit"), "Машина названа как в игре: [machine_text]")
	TEST_ASSERT(!findtext(machine_text, "СМЕС"), "Без самодельного сокращения")

/// Месть: цель умерла после клятвы, тело уничтожено - цель не меняется, третья печать скрепляется
/datum/unit_test/blood_brothers_oath_vendetta_kill_body_gone/Run()
	var/datum/antag_opt_in_test_world/world_state = blood_brothers_oath_world()
	var/datum/team/brother_team/team = allocate_brother_team(src)
	var/datum/mind/victim = blood_brothers_target(ANTAG_OPT_IN_KILL)
	var/datum/mind/spare = blood_brothers_target(ANTAG_OPT_IN_KILL)
	world_state.set_crew(team.members + victim)
	world_state.set_hard_round(src)
	var/datum/blood_oath/vendetta/oath = new
	TEST_ASSERT(oath.prepare(team), "Месть готова")
	team.swear_oath(oath)
	TEST_ASSERT(istype(oath.steps[3], /datum/blood_oath_step/vendetta_kill), "Шаг 3 - убийство")
	for(var/step_index in 1 to 2)
		var/datum/blood_oath_step/done_step = oath.steps[step_index]
		done_step.sealed = TRUE
	world_state.set_crew(team.members + victim + spare)
	var/mob/living/carbon/human/victim_body = victim.current
	victim_body.death()
	qdel(victim_body)
	team.next_sense_at = 0
	team.process()
	TEST_ASSERT_EQUAL(team.oath, oath, "Клятва та же")
	TEST_ASSERT_EQUAL(oath.target_mind, victim, "Убитую цель без тела не меняют")
	var/datum/mind/first = team.members[1]
	TEST_ASSERT(team.try_seal(first) == TRUE, "Смерть цели скрепляет шаг, хоть тела уже нет")

/// Цель Мести в VR-капсуле не уходит: её игрок в аватаре
/datum/unit_test/blood_brothers_oath_target_vr/Run()
	var/datum/antag_opt_in_test_world/world_state = blood_brothers_oath_world()
	var/datum/team/brother_team/team = allocate_brother_team(src)
	var/datum/mind/dreamer = blood_brothers_target(ANTAG_OPT_IN_ROUND_REMOVE)
	var/datum/mind/spare = blood_brothers_target(ANTAG_OPT_IN_ROUND_REMOVE)
	world_state.set_crew(team.members + dreamer)
	GLOB.round_type = ROUNDTYPE_DYNAMIC_LIGHT
	var/datum/blood_oath/vendetta/oath = new
	TEST_ASSERT(oath.prepare(team), "Месть готова")
	team.swear_oath(oath)
	world_state.set_crew(team.members + dreamer + spare)
	var/mob/living/carbon/human/body = dreamer.current
	var/mob/living/carbon/human/avatar = allocate(/mob/living/carbon/human)
	avatar.mind_initialize()
	var/datum/component/virtual_reality/session = avatar.AddComponent(/datum/component/virtual_reality)
	body.mock_client = null
	body.key = "BloodBrotherVRTarget"
	TEST_ASSERT(session.connect(body), "Цель легла в капсулу")
	TEST_ASSERT(!body.key && avatar.key, "Игрок цели ушёл в аватар")
	avatar.mock_client = new /datum/client_interface()
	oath.on_team_tick()
	oath.target_away_since = world.time - BROTHER_GHOST_GRACE - 1
	oath.on_team_tick()
	TEST_ASSERT_EQUAL(team.oath, oath, "Клятва та же")
	TEST_ASSERT_EQUAL(oath.target_mind, dreamer, "Цель в VR - не уход")
	session.quit()
	avatar.mock_client = null
	body.key = null
