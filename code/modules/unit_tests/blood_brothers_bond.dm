/// Ступень 0: Шёпот и Клятва крови выданы, Чутьё ведёт брата
/datum/unit_test/blood_brothers_tier_zero

/datum/unit_test/blood_brothers_tier_zero/Run()
	var/datum/team/brother_team/team = allocate_brother_team(src)
	var/datum/mind/first = team.members[1]
	var/datum/antagonist/brother/brother = first.has_antag_datum(/datum/antagonist/brother)
	var/datum/action/cooldown/blood_bond/whisper/whisper = brother.bond_actions[/datum/action/cooldown/blood_bond/whisper]
	TEST_ASSERT_NOTNULL(whisper, "Шёпот выдан")
	TEST_ASSERT_NOTNULL(brother.bond_actions[/datum/action/cooldown/blood_bond/recruit], "Клятва крови выдана")
	TEST_ASSERT_EQUAL(whisper.owner, first.current, "Кнопка Шёпота у тела брата")
	TEST_ASSERT_EQUAL(whisper.brother, brother, "Шёпот знает своего брата")
	brother.update_sense()
	TEST_ASSERT_NOTNULL(first.current.has_status_effect(/datum/status_effect/brother_sense), "Чутьё ведёт брата")

/// Майндшилд гасит способности и HUD, снятие возвращает
/datum/unit_test/blood_brothers_mindshield_mutes

/datum/unit_test/blood_brothers_mindshield_mutes/Run()
	var/datum/team/brother_team/team = allocate_brother_team(src)
	var/datum/mind/first = team.members[1]
	var/datum/antagonist/brother/brother = first.has_antag_datum(/datum/antagonist/brother)
	var/datum/action/cooldown/blood_bond/whisper/whisper = brother.bond_actions[/datum/action/cooldown/blood_bond/whisper]
	TEST_ASSERT_NOTNULL(whisper, "Шёпот выдан")
	TEST_ASSERT(whisper.IsAvailable(silent = TRUE), "Шёпот доступен")
	ADD_TRAIT(first.current, TRAIT_MINDSHIELD, "test")
	TEST_ASSERT(!whisper.IsAvailable(silent = TRUE), "Майндшилд гасит Шёпот")
	TEST_ASSERT(!whisper.Trigger(), "Нажатие под майндшилдом не срабатывает")
	TEST_ASSERT_EQUAL(brother.brother_state(), BROTHER_STATE_MUTED, "Состояние - заглушён")
	TEST_ASSERT_EQUAL(first.antag_hud_icon_state, "blood_brother_muted", "HUD - заглушён")
	REMOVE_TRAIT(first.current, TRAIT_MINDSHIELD, "test")
	TEST_ASSERT(whisper.IsAvailable(silent = TRUE), "Снятие майндшилда возвращает связь")

/// Клятва третьего: запреты и лимит
/datum/unit_test/blood_brothers_recruit_rules

/datum/unit_test/blood_brothers_recruit_rules/Run()
	var/datum/team/brother_team/team = allocate_brother_team(src)
	var/datum/mind/recruiter = team.members[1]
	var/datum/mind/candidate = allocate_brother_mind(src)
	var/turf/beside = get_step(recruiter.current, EAST)
	candidate.current.forceMove(beside)
	TEST_ASSERT(istext(team.can_recruit(recruiter, candidate.current)), "Без клиента не вербуется")
	candidate.current.mock_client = new /datum/client_interface()
	TEST_ASSERT_EQUAL(team.can_recruit(recruiter, candidate.current), TRUE, "Соседа без ролей можно позвать")
	candidate.current.forceMove(get_step(beside, EAST))
	TEST_ASSERT(istext(team.can_recruit(recruiter, candidate.current)), "Через клетку не вербуется")
	candidate.current.forceMove(beside)
	ADD_TRAIT(candidate.current, TRAIT_MINDSHIELD, "test")
	TEST_ASSERT(istext(team.can_recruit(recruiter, candidate.current)), "Майндшилд не вербуется")
	REMOVE_TRAIT(candidate.current, TRAIT_MINDSHIELD, "test")
	ADD_TRAIT(recruiter.current, TRAIT_MINDSHIELD, "test")
	TEST_ASSERT(istext(team.can_recruit(recruiter, candidate.current)), "Заглушённый брат не вербует")
	REMOVE_TRAIT(recruiter.current, TRAIT_MINDSHIELD, "test")
	ADD_TRAIT(candidate.current, TRAIT_NO_MIDROUND_ANTAG, "test")
	TEST_ASSERT(istext(team.can_recruit(recruiter, candidate.current)), "Гостевая роль не вербуется")
	REMOVE_TRAIT(candidate.current, TRAIT_NO_MIDROUND_ANTAG, "test")
	var/datum/preferences/prefs = new
	allocated += prefs
	prefs.toggles |= NO_ANTAG
	candidate.current.mock_client.prefs = prefs
	TEST_ASSERT(istext(team.can_recruit(recruiter, candidate.current)), "С выключенными антагами не вербуется")
	prefs.toggles &= ~NO_ANTAG
	TEST_ASSERT_EQUAL(team.can_recruit(recruiter, candidate.current), TRUE, "Включённые антаги снова пускают")
	candidate.assigned_role = "Security Officer"
	TEST_ASSERT(istext(team.can_recruit(recruiter, candidate.current)), "СБ не вербуется")
	candidate.assigned_role = "Assistant"
	TEST_ASSERT(team.recruit(candidate), "Третий принят")
	TEST_ASSERT_EQUAL(length(team.members), 3, "В команде трое")
	TEST_ASSERT(team.third_oath_used, "Слот третьего потрачен")
	var/datum/antagonist/brother/third = candidate.has_antag_datum(/datum/antagonist/brother)
	TEST_ASSERT_NOTNULL(third, "Третий получил датум")
	TEST_ASSERT_EQUAL(third.team, team, "Третий в той же команде")
	TEST_ASSERT_NOTNULL(third.bond_actions[/datum/action/cooldown/blood_bond/whisper], "Третий получил способности ступени")
	var/datum/mind/fourth = allocate_brother_mind(src)
	fourth.current.mock_client = new /datum/client_interface()
	fourth.current.forceMove(get_step(recruiter.current, NORTH))
	TEST_ASSERT(istext(team.can_recruit(recruiter, fourth.current)), "Четвёртого не бывает")
	TEST_ASSERT_EQUAL(team.recruit_team_refusal(recruiter), "братьев уже [BROTHER_TEAM_MAX_SIZE]", "Причина команды видна до перебора соседей")
	candidate.current.mock_client = null
	fourth.current.mock_client = null

/// Отказ закрывает повторную клятву на время, согласие принимает в братство
/datum/unit_test/blood_brothers_recruit_answer

/datum/unit_test/blood_brothers_recruit_answer/Run()
	var/datum/team/brother_team/team = allocate_brother_team(src)
	var/datum/mind/recruiter = team.members[1]
	var/datum/antagonist/brother/brother = recruiter.has_antag_datum(/datum/antagonist/brother)
	var/datum/action/cooldown/blood_bond/recruit/action = brother.bond_actions[/datum/action/cooldown/blood_bond/recruit]
	TEST_ASSERT_NOTNULL(action, "Клятва крови выдана")
	TEST_ASSERT(!action.Trigger(), "Рядом только брат - звать некого")
	TEST_ASSERT_EQUAL(action.next_use_time, 0, "Пустое нажатие не тратит перезарядку")
	var/datum/mind/candidate = allocate_brother_mind(src)
	candidate.current.forceMove(get_step(recruiter.current, EAST))
	candidate.current.mock_client = new /datum/client_interface()
	TEST_ASSERT(!action.answer_offer(candidate.current, "Отказаться"), "Отказ не принимает")
	TEST_ASSERT_NULL(candidate.has_antag_datum(/datum/antagonist/brother), "Отказавшийся не брат")
	TEST_ASSERT(istext(team.can_recruit(recruiter, candidate.current)), "Сразу после отказа не зовут снова")
	TEST_ASSERT(!team.third_oath_used, "Отказ не тратит слот")
	team.recruit_refusals[candidate] = world.time - BROTHER_RECRUIT_REFUSAL_COOLDOWN
	TEST_ASSERT_EQUAL(team.can_recruit(recruiter, candidate.current), TRUE, "После перерыва зовут снова")
	TEST_ASSERT(action.answer_offer(candidate.current, "Принять"), "Согласие принимает")
	TEST_ASSERT_NOTNULL(candidate.has_antag_datum(/datum/antagonist/brother), "Согласившийся стал братом")
	TEST_ASSERT(team.third_oath_used, "Слот третьего потрачен")
	candidate.current.mock_client = null

/// Уход в крио открывает одну внеочередную клятву
/datum/unit_test/blood_brothers_departure_replacement

/datum/unit_test/blood_brothers_departure_replacement/Run()
	var/datum/team/brother_team/team = allocate_brother_team(src)
	var/datum/mind/stayer = team.members[1]
	var/datum/mind/leaver = team.members[2]
	team.third_oath_used = TRUE
	leaver.current.moveToNullspace()
	team.check_departures()
	TEST_ASSERT(leaver in team.departed_minds, "Уход замечен")
	TEST_ASSERT(team.replacement_available, "Открыта внеочередная клятва")
	var/datum/mind/candidate = allocate_brother_mind(src)
	candidate.current.mock_client = new /datum/client_interface()
	candidate.current.forceMove(get_step(stayer.current, EAST))
	TEST_ASSERT_EQUAL(team.can_recruit(stayer, candidate.current), TRUE, "Замена при потраченном слоте третьего")
	TEST_ASSERT(team.recruit(candidate), "Замена принята")
	TEST_ASSERT(team.replacement_used, "Замена потрачена")
	TEST_ASSERT(!team.replacement_available, "Второй замены нет")
	var/datum/mind/another = allocate_brother_mind(src)
	another.current.mock_client = new /datum/client_interface()
	another.current.forceMove(get_step(stayer.current, NORTH))
	TEST_ASSERT(istext(team.can_recruit(stayer, another.current)), "Слоты кончились")
	candidate.current.mock_client = null
	another.current.mock_client = null

/// Чутьё: по алерту на каждого брата, состояние и направление; разрыв убирает
/datum/unit_test/blood_brothers_sense

/datum/unit_test/blood_brothers_sense/Run()
	var/datum/team/brother_team/team = allocate_brother_team(src, 3)
	var/datum/mind/first = team.members[1]
	var/datum/mind/second = team.members[2]
	var/datum/mind/third = team.members[3]
	var/datum/antagonist/brother/brother = first.has_antag_datum(/datum/antagonist/brother)
	var/turf/start = get_turf(first.current)
	second.current.forceMove(locate(start.x + 3, start.y, start.z))
	team.process()
	var/list/senses = first.current.has_status_effect_list(/datum/status_effect/brother_sense)
	TEST_ASSERT_EQUAL(length(senses), 2, "Алерт на каждого брата")
	var/datum/status_effect/brother_sense/second_sense
	for(var/datum/status_effect/brother_sense/sense as anything in senses)
		TEST_ASSERT_NOTNULL(sense.linked_alert, "У Чутья есть алерт")
		if(sense.tracked == second)
			second_sense = sense
	TEST_ASSERT_NOTNULL(second_sense, "Чутьё ведёт второго брата")
	var/datum/status_effect/brother_sense/first_sense = senses[1]
	var/datum/status_effect/brother_sense/last_sense = senses[2]
	TEST_ASSERT_NOTEQUAL(first_sense.linked_alert, last_sense.linked_alert, "У каждого брата свой алерт")
	TEST_ASSERT_EQUAL(second_sense.linked_alert.dir, EAST, "Стрелка смотрит на брата")
	TEST_ASSERT_EQUAL(second_sense.linked_alert.icon_state, "sense_close", "Близкий брат - короткая нить")
	TEST_ASSERT(findtext(second_sense.linked_alert.desc, "восток"), "Направление словами: [second_sense.linked_alert.desc]")
	TEST_ASSERT(findtext(second_sense.linked_alert.desc, "в порядке"), "Состояние словами: [second_sense.linked_alert.desc]")
	ADD_TRAIT(second.current, TRAIT_MINDSHIELD, "test")
	TEST_ASSERT(findtext(second_sense.linked_alert.desc, "заглушена"), "Майндшилд брата виден сразу: [second_sense.linked_alert.desc]")
	TEST_ASSERT_EQUAL(second_sense.linked_alert.icon_state, "muted", "Заглушённый брат - зажатая нить")
	REMOVE_TRAIT(second.current, TRAIT_MINDSHIELD, "test")
	ADD_TRAIT(first.current, TRAIT_MINDSHIELD, "test")
	TEST_ASSERT(!findtext(second_sense.linked_alert.desc, "восток"), "Заглушённый не чувствует, где брат")
	TEST_ASSERT_EQUAL(second_sense.linked_alert.icon_state, "muted", "Своя связь заглушена - зажатая нить")
	REMOVE_TRAIT(first.current, TRAIT_MINDSHIELD, "test")
	second.current.forceMove(get_step(first.current, NORTH))
	second_sense.refresh()
	TEST_ASSERT_EQUAL(second_sense.linked_alert.icon_state, "sense_direct", "Брат вплотную - капля на месте")
	TEST_ASSERT_EQUAL(brother.brother_state(), BROTHER_STATE_OK, "Брат снова в порядке")
	team.sever(third, "тест")
	TEST_ASSERT_NULL(third.current.has_status_effect(/datum/status_effect/brother_sense), "Разорванный больше не чувствует братьев")
	team.next_sense_at = 0
	team.process()
	senses = first.current.has_status_effect_list(/datum/status_effect/brother_sense)
	TEST_ASSERT_EQUAL(length(senses), 1, "Разорванного Чутьё не ведёт")

/// Шёпот слышат братья команды; разорванный и заглушённый - нет; кандалы не мешают
/datum/unit_test/blood_brothers_whisper

/datum/unit_test/blood_brothers_whisper/Run()
	var/datum/team/brother_team/team = allocate_brother_team(src, 3)
	var/datum/mind/speaker = team.members[1]
	var/datum/mind/listener = team.members[2]
	var/datum/mind/severed = team.members[3]
	var/datum/antagonist/brother/brother = speaker.has_antag_datum(/datum/antagonist/brother)
	var/datum/action/cooldown/blood_bond/whisper/whisper = brother.bond_actions[/datum/action/cooldown/blood_bond/whisper]
	TEST_ASSERT_NOTNULL(whisper, "Шёпот выдан")
	var/list/window = brother.ui_data(speaker.current)
	var/pulse = window["bond_pulse"]
	TEST_ASSERT(isnum(pulse), "Окно получает счётчик капель")
	var/list/heard = whisper.send_whisper("проверка")
	TEST_ASSERT(listener.current in heard, "Брат слышит шёпот")
	TEST_ASSERT(severed.current in heard, "Третий слышит шёпот")
	window = brother.ui_data(speaker.current)
	TEST_ASSERT_EQUAL(window["bond_pulse"], pulse + 1, "Шёпот пускает каплю по нити окна")
	team.notify("проверка")
	window = brother.ui_data(speaker.current)
	TEST_ASSERT_EQUAL(window["bond_pulse"], pulse + 2, "Весть связи тоже пускает каплю")
	team.sever(severed, "тест")
	heard = whisper.send_whisper("проверка")
	TEST_ASSERT(!(severed.current in heard), "Разорванный не слышит")
	ADD_TRAIT(listener.current, TRAIT_MINDSHIELD, "test")
	heard = whisper.send_whisper("проверка")
	TEST_ASSERT(!(listener.current in heard), "Заглушённый не слышит")
	REMOVE_TRAIT(listener.current, TRAIT_MINDSHIELD, "test")
	var/mob/living/carbon/human/speaker_body = speaker.current
	speaker_body.handcuffed = allocate(/obj/item/restraints/handcuffs, speaker_body)
	speaker_body.update_handcuffed()
	speaker_body.update_mobility()
	TEST_ASSERT(whisper.IsAvailable(silent = TRUE), "В наручниках шептать можно")
	var/datum/action/cooldown/blood_bond/recruit/recruit = brother.bond_actions[/datum/action/cooldown/blood_bond/recruit]
	TEST_ASSERT(!recruit.IsAvailable(silent = TRUE), "В наручниках ладонь не надрезать")
	speaker_body.uncuff()
	team.cooldown_multiplier = 2
	TEST_ASSERT_EQUAL(whisper.bond_cooldown(), 2 * initial(whisper.cooldown_time), "Обет растягивает перезарядку")

/// Вкладка «Связь» собирается из типов способностей со всеми текстами
/datum/unit_test/blood_brothers_bond_ladder

/datum/unit_test/blood_brothers_bond_ladder/Run()
	var/datum/team/brother_team/team = allocate_brother_team(src)
	var/datum/mind/first = team.members[1]
	var/datum/antagonist/brother/brother = first.has_antag_datum(/datum/antagonist/brother)
	var/list/ladder = brother.bond_ladder_data()
	TEST_ASSERT_EQUAL(length(ladder), length(GLOB.blood_bond_tier_actions), "Ступень на каждый список способностей")
	var/list/zero = ladder[1]
	TEST_ASSERT_EQUAL(zero["tier"], 0, "Первая ступень - нулевая")
	var/list/by_name = list()
	for(var/list/ability as anything in zero["abilities"])
		by_name[ability["name"]] = ability
		TEST_ASSERT(length(ability["desc"]), "[ability["name"]]: есть описание")
		TEST_ASSERT(length(ability["how"]), "[ability["name"]]: есть «как»")
	var/datum/action/cooldown/blood_bond/whisper/whisper_type = /datum/action/cooldown/blood_bond/whisper
	var/list/whisper_entry = by_name[initial(whisper_type.name)]
	TEST_ASSERT_NOTNULL(whisper_entry, "Шёпот на нулевой ступени")
	TEST_ASSERT_EQUAL(whisper_entry["cooldown"], initial(whisper_type.cooldown_time) / (1 SECONDS), "Перезарядка в секундах")
	TEST_ASSERT(!whisper_entry["passive"], "Шёпот - кнопка")
	var/datum/blood_bond_passive/sense_type = /datum/blood_bond_passive/sense
	var/list/sense_entry = by_name[initial(sense_type.name)]
	TEST_ASSERT_NOTNULL(sense_entry, "Чутьё на нулевой ступени")
	TEST_ASSERT(sense_entry["passive"], "Чутьё - пассивка")
	var/datum/action/cooldown/blood_bond/whisper/action = brother.bond_actions[whisper_type]
	TEST_ASSERT_NOTNULL(action, "Шёпот выдан")
	TEST_ASSERT_EQUAL(action.desc, whisper_entry["desc"], "Кнопка и окно описывают Шёпот одинаково")
	for(var/datum/action/cooldown/blood_bond/action_type as anything in subtypesof(/datum/action/cooldown/blood_bond))
		if(action_type == /datum/action/cooldown/blood_bond/capstone)
			continue
		TEST_ASSERT(length(initial(action_type.desc)), "[action_type]: нет описания")
		TEST_ASSERT(length(initial(action_type.bond_how)), "[action_type]: нет «как применить»")
	var/datum/blood_oath/blood_brothers_capstone_test/sign_oath = new
	sign_oath.extra_actions = list(/datum/action/cooldown/blood_bond/brother_sign)
	team.swear_oath(sign_oath)
	TEST_ASSERT_EQUAL(team.oath, sign_oath, "Клятва со своей кнопкой принята")
	ladder = brother.bond_ladder_data()
	TEST_ASSERT_EQUAL(length(ladder), length(GLOB.blood_bond_tier_actions) + 1, "Клятва добавляет свой блок")
	var/list/oath_block = ladder[length(ladder)]
	TEST_ASSERT(findtext(oath_block["label"], sign_oath.name), "Блок назван по клятве: [oath_block["label"]]")
	TEST_ASSERT_EQUAL(oath_block["tier"], 0, "Кнопки клятвы открыты с самой клятвы")
	var/list/oath_abilities = oath_block["abilities"]
	var/list/sign_entry = oath_abilities[1]
	var/datum/action/cooldown/blood_bond/brother_sign/sign_type = /datum/action/cooldown/blood_bond/brother_sign
	TEST_ASSERT_EQUAL(sign_entry["name"], initial(sign_type.name), "Кнопка знака в окне")
	TEST_ASSERT(length(sign_entry["how"]), "У кнопки знака есть «как»")
	TEST_ASSERT_NOTNULL(brother.bond_actions[sign_type], "Кнопка знака выдана")

/// Снятие датума убирает кнопки связи и Чутьё с тела
/datum/unit_test/blood_brothers_bond_cleanup

/datum/unit_test/blood_brothers_bond_cleanup/Run()
	var/datum/team/brother_team/team = allocate_brother_team(src)
	var/datum/mind/member = team.members[1]
	var/datum/antagonist/brother/brother = member.has_antag_datum(/datum/antagonist/brother)
	brother.update_sense()
	TEST_ASSERT_NOTNULL(member.current.has_status_effect(/datum/status_effect/brother_sense), "Чутьё на теле")
	member.remove_antag_datum(/datum/antagonist/brother)
	TEST_ASSERT_NULL(member.current.has_status_effect(/datum/status_effect/brother_sense), "Чутьё снято")
	for(var/datum/action/action as anything in member.current.actions)
		TEST_ASSERT(!istype(action, /datum/action/cooldown/blood_bond), "Кнопка [action] снята")

/// Кровь за кровь: только брату рядом, донор теряет кровь, брат лечится сразу и за несколько секунд; ниже безопасного уровня и мёртвому нельзя
/datum/unit_test/blood_brothers_blood_for_blood
	var/list/given
	/// Луч связи посреди ожидания: состояние, начало, конец
	var/list/thread_seen

/datum/unit_test/blood_brothers_blood_for_blood/Run()
	var/datum/team/brother_team/team = allocate_brother_team(src)
	var/datum/mind/donor_mind = team.members[1]
	var/datum/mind/patient_mind = team.members[2]
	var/mob/living/carbon/human/donor = donor_mind.current
	var/mob/living/carbon/human/patient = patient_mind.current
	var/datum/antagonist/brother/brother = donor_mind.has_antag_datum(/datum/antagonist/brother)
	TEST_ASSERT_NULL(brother.bond_actions[/datum/action/cooldown/blood_bond/blood_for_blood], "До первой печати Крови за кровь нет")
	team.set_bond_tier(1)
	var/datum/action/cooldown/blood_bond/blood_for_blood/action = brother.bond_actions[/datum/action/cooldown/blood_bond/blood_for_blood]
	TEST_ASSERT_NOTNULL(action, "Ступень 1 даёт Кровь за кровь")
	var/turf/start = get_turf(donor)
	patient.forceMove(locate(start.x + 2, start.y, start.z))
	var/mob/living/carbon/human/stranger = allocate(/mob/living/carbon/human)
	stranger.forceMove(get_step(donor, NORTH))
	TEST_ASSERT(!action.Trigger(), "Рядом только чужой - отдавать некому")
	TEST_ASSERT_EQUAL(action.next_use_time, 0, "Пустое нажатие не тратит перезарядку")
	patient.forceMove(get_step(donor, EAST))
	patient.adjustBruteLoss(40)
	var/donor_blood = donor.blood_volume
	given = null
	RegisterSignal(team, COMSIG_BROTHER_BLOOD_GIVEN, PROC_REF(on_blood_given))
	thread_seen = null
	addtimer(CALLBACK(src, PROC_REF(spot_thread), action), BROTHER_TRANSFUSION_TIME / 2)
	var/triggered = action.Trigger()
	UnregisterSignal(team, COMSIG_BROTHER_BLOOD_GIVEN)
	TEST_ASSERT(triggered, "Передача прошла")
	TEST_ASSERT_NOTNULL(thread_seen, "Пока режется ладонь, тянется нить")
	TEST_ASSERT_EQUAL(thread_seen[1], "blood_thread", "Нить крови")
	TEST_ASSERT_EQUAL(thread_seen[2], donor, "Нить идёт от донора")
	TEST_ASSERT_EQUAL(thread_seen[3], patient, "Нить идёт к брату")
	TEST_ASSERT_NULL(action.bond_beam, "Кровь ушла - нить убрана")
	TEST_ASSERT_NOTNULL(locate(/obj/effect/temp_visual/blood_brothers/transfuse_drop) in get_turf(patient), "Капля падает на брата")
	TEST_ASSERT(abs(donor_blood - BROTHER_TRANSFUSION_AMOUNT - donor.blood_volume) < 1, "Донор отдал [BROTHER_TRANSFUSION_AMOUNT] крови: было [donor_blood], стало [donor.blood_volume]")
	var/instant_heal = BROTHER_TRANSFUSION_HEAL / (BROTHER_TRANSFUSION_TICKS + 1)
	TEST_ASSERT(abs(patient.getBruteLoss() - (40 - instant_heal)) < 0.1, "Часть ушибов уходит сразу: [patient.getBruteLoss()]")
	TEST_ASSERT_EQUAL(length(given), 2, "Команда узнала о переданной крови")
	TEST_ASSERT_EQUAL(given[1], donor, "В сигнале донор")
	TEST_ASSERT_EQUAL(given[2], patient, "В сигнале получатель")
	TEST_ASSERT(action.next_use_time > world.time, "Перезарядка пошла")
	TEST_ASSERT_NOTNULL(patient.has_status_effect(/datum/status_effect/brother_transfusion), "Остальное лечение идёт по тикам")
	for(var/wait in 1 to 100)
		if(!patient.has_status_effect(/datum/status_effect/brother_transfusion))
			break
		sleep(1)
	TEST_ASSERT_NULL(patient.has_status_effect(/datum/status_effect/brother_transfusion), "Переливание закончилось")
	TEST_ASSERT(abs(patient.getBruteLoss() - (40 - BROTHER_TRANSFUSION_HEAL)) < 0.1, "Всего вылечено [BROTHER_TRANSFUSION_HEAL] ушибов: осталось [patient.getBruteLoss()]")
	var/datum/antagonist/brother/patient_brother = patient_mind.has_antag_datum(/datum/antagonist/brother)
	var/datum/action/cooldown/blood_bond/blood_for_blood/patient_action = patient_brother.bond_actions[/datum/action/cooldown/blood_bond/blood_for_blood]
	var/patient_blood = patient.blood_volume
	TEST_ASSERT(!patient_action.Trigger(), "Получивший кровь не отдаёт свою сразу")
	TEST_ASSERT_EQUAL(patient.blood_volume, patient_blood, "Отказ получившего не забирает кровь")
	TEST_ASSERT(istext(patient_action.donor_refusal()), "У отказа есть причина для подсказки")
	patient.remove_status_effect(/datum/status_effect/brother_blood_received)
	TEST_ASSERT_NULL(patient_action.donor_refusal(), "Прижившаяся кровь больше не мешает")
	action.next_use_time = 0
	donor.blood_volume = BLOOD_VOLUME_SAFE
	TEST_ASSERT(!action.Trigger(), "Ниже безопасного уровня отдавать нельзя")
	TEST_ASSERT_EQUAL(donor.blood_volume, BLOOD_VOLUME_SAFE, "Отказ не забирает кровь")
	donor.blood_volume = BLOOD_VOLUME_NORMAL
	patient.death()
	TEST_ASSERT(!action.Trigger(), "Мёртвому кровь не поможет")
	var/datum/action/cooldown/blood_bond/blood_for_blood/action_type = /datum/action/cooldown/blood_bond/blood_for_blood
	TEST_ASSERT(findtext(initial(action_type.desc), "[round(BROTHER_TRANSFUSION_FRACTION * 100)]%"), "Доля крови в описании совпадает с дефайном")
	TEST_ASSERT(findtext(initial(action_type.desc), "[BROTHER_TRANSFUSION_HEAL] ушибов"), "Лечение в описании совпадает с дефайном")
	TEST_ASSERT(findtext(initial(action_type.bond_how), "[BROTHER_TRANSFUSION_TIME / (1 SECONDS)] секунды"), "Время в подсказке совпадает с дефайном")
	TEST_ASSERT(findtext(initial(action_type.desc), "нельзя отдавать [BROTHER_TRANSFUSION_RECEIVE_LOCK / (1 MINUTES)] минуты"), "Запрет после чужой крови в описании совпадает с дефайном")

/datum/unit_test/blood_brothers_blood_for_blood/proc/on_blood_given(datum/source, mob/living/donor, mob/living/recipient)
	SIGNAL_HANDLER
	given = list(donor, recipient)

/datum/unit_test/blood_brothers_blood_for_blood/proc/spot_thread(datum/action/cooldown/blood_bond/action)
	var/datum/beam/thread = action.bond_beam
	if(thread)
		thread_seen = list(thread.icon_state, thread.origin, thread.target)

/// Смерть брата: настроение, алерт, слёзы и Ярость у выжившего без видимых со стороны признаков, заглушённый не чувствует; оживление, новое тело и уход снимают горе, разрыв даёт своё
/datum/unit_test/blood_brothers_grief

/datum/unit_test/blood_brothers_grief/Run()
	var/datum/team/brother_team/team = allocate_brother_team(src, 3)
	var/datum/mind/survivor = team.members[1]
	var/datum/mind/fallen = team.members[2]
	var/datum/mind/shielded = team.members[3]
	var/mob/living/carbon/human/survivor_body = survivor.current
	var/datum/component/mood/mood = survivor_body.GetComponent(/datum/component/mood) || survivor_body.AddComponent(/datum/component/mood)
	ADD_TRAIT(shielded.current, TRAIT_MINDSHIELD, "test")
	fallen.current.death()
	TEST_ASSERT_NOTNULL(mood.mood_events["brother_fallen"], "Настроение «Брат пал»")
	TEST_ASSERT_NOTNULL(survivor_body.alerts["brother_fallen"], "Алерт «Брат пал»")
	var/grief_timer = mood.mood_event_timers["brother_fallen"]
	TEST_ASSERT(grief_timer && abs(timeleft(grief_timer) - BROTHER_GRIEF_MOOD_TIME) < 1 SECONDS, "Горе проходит само через [DisplayTimeText(BROTHER_GRIEF_MOOD_TIME)]")
	var/atom/movable/screen/alert/fallen_alert = survivor_body.alerts["brother_fallen"]
	TEST_ASSERT(abs(fallen_alert.timeout - world.time - BROTHER_GRIEF_MOOD_TIME) < 1 SECONDS, "Алерт горя уходит вместе с настроением")
	TEST_ASSERT(!survivor_body.IsKnockdown(), "Горе не сбивает с ног")
	TEST_ASSERT(!survivor_body.jitteriness, "Горе не бросает в дрожь")
	TEST_ASSERT(survivor_body.eye_blurry >= BROTHER_GRIEF_BLUR, "Смерть брата застилает глаза")
	var/datum/status_effect/brother_fury/grief_fury = survivor_body.has_status_effect(/datum/status_effect/brother_fury)
	TEST_ASSERT_NOTNULL(grief_fury, "Смерть брата будит Ярость даже до второй ступени")
	TEST_ASSERT(!(shielded.current in blood_brothers_aura_viewers(grief_fury)), "Заглушённый брат ауры не видит")
	TEST_ASSERT_NULL(shielded.current.has_status_effect(/datum/status_effect/brother_fury), "Заглушённый не чувствует смерти")
	TEST_ASSERT_NULL(shielded.current.alerts["brother_fallen"], "Заглушённому нечего оплакивать")
	fallen.current.revive(full_heal = TRUE, admin_revive = TRUE)
	TEST_ASSERT_NULL(mood.mood_events["brother_fallen"], "Оживление снимает штраф")
	TEST_ASSERT_NULL(survivor_body.alerts["brother_fallen"], "Оживление снимает алерт")
	fallen.current.death()
	TEST_ASSERT_NOTNULL(mood.mood_events["brother_fallen"], "Вторая смерть снова бьёт")
	var/mob/living/carbon/human/new_body = allocate(/mob/living/carbon/human)
	fallen.transfer_to(new_body)
	team.next_sense_at = 0
	team.process()
	TEST_ASSERT_NULL(mood.mood_events["brother_fallen"], "Брат в новом теле - горе снято")
	fallen.current.death()
	TEST_ASSERT_NOTNULL(mood.mood_events["brother_fallen"], "Новое тело тоже можно потерять")
	fallen.current.moveToNullspace()
	team.check_departures()
	TEST_ASSERT_NULL(mood.mood_events["brother_fallen"], "Ушедшего не ждут")
	TEST_ASSERT_NULL(survivor_body.alerts["brother_fallen"], "Алерт ушедшего снят")
	team.sever(shielded, "тест")
	TEST_ASSERT_NOTNULL(mood.mood_events["brother_severed"], "Разрыв клятвы бьёт по оставшимся")

/proc/blood_brothers_aura_viewers(datum/status_effect/brother_fury/fury)
	. = list()
	for(var/datum/weakref/viewer_ref as anything in fury?.aura_viewers)
		. += viewer_ref.resolve()

/proc/blood_brothers_has_overlay(atom/thing, state)
	for(var/mutable_appearance/overlay as anything in thing.overlays)
		if(overlay.icon_state == state)
			return TRUE
	return FALSE

/// Ярость не будят первое наблюдение за братом и добровольный сон; обморок после окна сна будит
/datum/unit_test/blood_brothers_fury_false_alarms

/datum/unit_test/blood_brothers_fury_false_alarms/Run()
	var/datum/team/brother_team/team = allocate_brother_team(src)
	var/datum/mind/first = team.members[1]
	var/datum/mind/second = team.members[2]
	var/mob/living/carbon/human/watcher = first.current
	var/mob/living/carbon/human/sleeper = second.current
	team.set_bond_tier(BROTHER_FURY_TIER)
	sleeper.handcuffed = allocate(/obj/item/restraints/handcuffs, sleeper)
	sleeper.update_handcuffed()
	team.next_sense_at = 0
	team.process()
	TEST_ASSERT_NULL(watcher.has_status_effect(/datum/status_effect/brother_fury), "Первый взгляд на скованного брата - не переход")
	sleeper.uncuff()
	team.next_sense_at = 0
	team.process()
	sleeper.emote("faint", intentional = TRUE)
	TEST_ASSERT(sleeper.voluntary_sleep_until > world.time, "Предпосылка: брат уснул сам")
	TEST_ASSERT_EQUAL(sleeper.stat, UNCONSCIOUS, "Предпосылка: спящий без сознания")
	team.next_sense_at = 0
	team.process()
	TEST_ASSERT_NULL(watcher.has_status_effect(/datum/status_effect/brother_fury), "Добровольный сон Ярость не будит")
	sleeper.voluntary_sleep_until = 0
	team.next_sense_at = 0
	team.process()
	TEST_ASSERT_NOTNULL(watcher.has_status_effect(/datum/status_effect/brother_fury), "Беспамятство после окна сна будит Ярость")

/// Ярость: наручники брата будят её только со второй ступени, держит перезарядку, меняет оглушение и выносливость и возвращает их
/datum/unit_test/blood_brothers_fury_cooldown

/datum/unit_test/blood_brothers_fury_cooldown/Run()
	var/datum/team/brother_team/team = allocate_brother_team(src)
	var/datum/mind/first = team.members[1]
	var/datum/mind/second = team.members[2]
	var/mob/living/carbon/human/furious = first.current
	var/mob/living/carbon/human/cuffed = second.current
	team.set_bond_tier(BROTHER_FURY_TIER - 1)
	cuffed.handcuffed = allocate(/obj/item/restraints/handcuffs, cuffed)
	cuffed.update_handcuffed()
	team.next_sense_at = 0
	team.process()
	TEST_ASSERT_NULL(furious.has_status_effect(/datum/status_effect/brother_fury), "До второй ступени наручники Ярость не будят")
	cuffed.uncuff()
	team.next_sense_at = 0
	team.process()
	team.set_bond_tier(BROTHER_FURY_TIER)
	var/stun_mod = furious.physiology.stun_mod
	var/stamina_mod = furious.physiology.stamina_mod
	cuffed.handcuffed = allocate(/obj/item/restraints/handcuffs, cuffed)
	cuffed.update_handcuffed()
	team.next_sense_at = 0
	team.process()
	TEST_ASSERT_NOTNULL(furious.has_status_effect(/datum/status_effect/brother_fury), "Наручники брата будят Ярость")
	TEST_ASSERT_NULL(cuffed.has_status_effect(/datum/status_effect/brother_fury), "Скованному Ярость не достаётся")
	var/datum/antagonist/brother/furious_brother = first.has_antag_datum(/datum/antagonist/brother)
	furious_brother.update_sense()
	var/datum/status_effect/brother_sense/sense = furious.has_status_effect(/datum/status_effect/brother_sense)
	TEST_ASSERT(findtext(sense.linked_alert.desc, "Зона: [get_area_name(cuffed, TRUE)]"), "Под Яростью Чутьё называет зону брата")
	TEST_ASSERT(abs(furious.physiology.stun_mod - stun_mod * BROTHER_FURY_RESIST_MULT) < 0.01, "Ярость укорачивает оглушение")
	TEST_ASSERT(abs(furious.physiology.stamina_mod - stamina_mod * BROTHER_FURY_RESIST_MULT) < 0.01, "Ярость бережёт выносливость")
	TEST_ASSERT(furious.has_movespeed_modifier(/datum/movespeed_modifier/brother_fury), "Ярость ускоряет")
	var/datum/status_effect/brother_fury/fury = furious.has_status_effect(/datum/status_effect/brother_fury)
	var/image/aura = fury.aura
	TEST_ASSERT(!blood_brothers_has_overlay(furious, "fury_aura"), "Аура не оверлей: посторонние её не видят")
	TEST_ASSERT_EQUAL(aura?.loc, furious, "Аура горит под яростным")
	TEST_ASSERT(aura.appearance_flags & RESET_TRANSFORM, "Аура не поворачивается вместе с лежащим")
	TEST_ASSERT(aura.appearance_flags & KEEP_APART, "Аура не сливается с телом")
	var/list/aura_viewers = blood_brothers_aura_viewers(fury)
	TEST_ASSERT((furious in aura_viewers) && (cuffed in aura_viewers), "Ауру видят сам яростный и его брат")
	TEST_ASSERT_EQUAL(length(aura_viewers), 2, "Кроме братьев ауру никто не видит")
	furious.remove_status_effect(/datum/status_effect/brother_fury)
	TEST_ASSERT_NULL(aura.loc, "Аура погасла")
	TEST_ASSERT(abs(furious.physiology.stun_mod - stun_mod) < 0.01, "Оглушение вернулось")
	TEST_ASSERT(abs(furious.physiology.stamina_mod - stamina_mod) < 0.01, "Выносливость вернулась")
	TEST_ASSERT(!furious.has_movespeed_modifier(/datum/movespeed_modifier/brother_fury), "Ускорение снято")
	cuffed.uncuff()
	team.next_sense_at = 0
	team.process()
	cuffed.handcuffed = allocate(/obj/item/restraints/handcuffs, cuffed)
	cuffed.update_handcuffed()
	team.next_sense_at = 0
	team.process()
	TEST_ASSERT_NULL(furious.has_status_effect(/datum/status_effect/brother_fury), "Перезарядка держит")
	var/list/passives = GLOB.blood_bond_tier_passives["[BROTHER_FURY_TIER]"]
	TEST_ASSERT(/datum/blood_bond_passive/fury in passives, "Окно показывает Ярость на той ступени, с которой она работает")
	var/datum/blood_bond_passive/fury/fury_type = /datum/blood_bond_passive/fury
	TEST_ASSERT_EQUAL(initial(fury_type.cooldown_time), BROTHER_FURY_COOLDOWN, "Окно показывает перезарядку Ярости")
	TEST_ASSERT(findtext(initial(fury_type.desc), "[BROTHER_FURY_DURATION / (1 SECONDS)] секунд"), "Длительность в описании совпадает с дефайном")

/// Брат в VR-капсуле не уходит: его тело держит связь через аватар
/datum/unit_test/blood_brothers_departure_vr

/datum/unit_test/blood_brothers_departure_vr/Run()
	var/datum/team/brother_team/team = allocate_brother_team(src)
	var/datum/mind/dreamer = team.members[1]
	var/mob/living/carbon/human/body = dreamer.current
	var/mob/living/carbon/human/avatar = allocate(/mob/living/carbon/human)
	avatar.mind_initialize()
	var/datum/component/virtual_reality/session = avatar.AddComponent(/datum/component/virtual_reality)
	body.key = "BloodBrotherDreamer"
	TEST_ASSERT(session.connect(body), "Брат лёг в капсулу")
	TEST_ASSERT(!body.key && avatar.key, "Игрок ушёл в аватар")
	avatar.mock_client = new /datum/client_interface()
	team.check_departures()
	team.ghost_since[dreamer] = world.time - BROTHER_GHOST_GRACE
	team.check_departures()
	TEST_ASSERT(!(dreamer in team.departed_minds), "VR - не уход")
	session.quit()
	avatar.mock_client = null
	body.key = null

/// Брат на полигоне не уходит, пока сеанс помнит его разум с правом вернуться
/datum/unit_test/blood_brothers_departure_training

/datum/unit_test/blood_brothers_departure_training/Run()
	var/datum/team/brother_team/team = allocate_brother_team(src)
	var/datum/mind/trainee = team.members[1]
	var/mob/dead/observer/ghost = allocate(/mob/dead/observer, run_loc_floor_bottom_left, trainee.current)
	ghost.can_reenter_corpse = TRUE
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон готов")
	var/datum/antag_training_arena/arena = session.arena
	TEST_ASSERT(session.connect(ghost), "Призрак брата вошёл на полигон")
	// Logout призрака, ушедшего в куклу, удаляет его; без клиента Logout не зовётся
	qdel(ghost)
	session.current_body.mock_client = new /datum/client_interface()
	team.check_departures()
	team.ghost_since[trainee] = world.time - BROTHER_GHOST_GRACE
	team.check_departures()
	TEST_ASSERT(!(trainee in team.departed_minds), "Полигон - не уход")
	session.current_body.mock_client = null
	var/mob/dead/observer/returned = session.finish()
	allocated += returned
	TEST_ASSERT(wait_for_qdeleted(arena, 1 MINUTES), "Полигон убран")

/// Брат с ключом без клиента уходит после своей грации; вернувшийся занимает место, в полной команде клятва его отпускает, а отпущенного можно принять снова
/datum/unit_test/blood_brothers_departure_ssd

/datum/unit_test/blood_brothers_departure_ssd/Run()
	var/datum/team/brother_team/team = allocate_brother_team(src)
	var/datum/mind/sleeper = team.members[1]
	var/datum/mind/stayer = team.members[2]
	var/mob/living/carbon/human/body = sleeper.current
	var/datum/antagonist/brother/sleeper_brother = sleeper.has_antag_datum(/datum/antagonist/brother)
	var/datum/action/cooldown/blood_bond/whisper/whisper = sleeper_brother.bond_actions[/datum/action/cooldown/blood_bond/whisper]
	body.key = "BloodBrotherSleeper"
	team.check_departures()
	team.ghost_since[sleeper] = world.time - BROTHER_GHOST_GRACE
	team.check_departures()
	TEST_ASSERT(!(sleeper in team.departed_minds), "Десять минут без клиента - ещё не уход")
	team.ghost_since[sleeper] = world.time - BROTHER_SSD_GRACE
	team.check_departures()
	TEST_ASSERT(sleeper in team.departed_minds, "Пятнадцать минут без клиента - уход")
	TEST_ASSERT_EQUAL(team.departed_reasons[sleeper], BROTHER_DEPARTURE_SSD, "Причина ухода записана")
	TEST_ASSERT(team.replacement_available, "Открыта замена")
	TEST_ASSERT(!whisper.IsAvailable(silent = TRUE), "Ушедший не шепчет")
	body.mock_client = new /datum/client_interface()
	team.next_sense_at = 0
	team.process()
	TEST_ASSERT(!(sleeper in team.departed_minds), "Переподключившийся вернулся")
	TEST_ASSERT_NULL(team.departed_reasons[sleeper], "Причина ухода снята")
	TEST_ASSERT(!team.replacement_available, "Место снова занято - замены нет")
	TEST_ASSERT(whisper.IsAvailable(silent = TRUE), "Вернувшийся снова шепчет")
	body.mock_client = null
	team.check_departures()
	team.ghost_since[sleeper] = world.time - BROTHER_SSD_GRACE
	team.check_departures()
	TEST_ASSERT(sleeper in team.departed_minds, "Снова ушёл")
	for(var/newcomer_number in 1 to 2)
		var/datum/mind/newcomer = allocate_brother_mind(src)
		TEST_ASSERT(team.recruit(newcomer), "Новый брат [newcomer_number] принят")
	TEST_ASSERT_EQUAL(length(team.members - team.departed_minds), BROTHER_TEAM_MAX_SIZE, "Команда полна")
	body.mock_client = new /datum/client_interface()
	team.next_sense_at = 0
	team.process()
	body.mock_client = null
	body.key = null
	TEST_ASSERT_NULL(sleeper.has_antag_datum(/datum/antagonist/brother), "В полной команде клятва отпускает вернувшегося")
	TEST_ASSERT(!(sleeper in team.severed_minds) && !HAS_TRAIT(sleeper, TRAIT_BLOOD_OATH_SEVERED), "Отпущенный не разрывал клятву")
	TEST_ASSERT(stayer in team.members, "Оставшийся на месте")
	TEST_ASSERT(!(sleeper in team.departed_minds), "Отпущенный не числится ушедшим")
	var/datum/mind/leaver = team.members[length(team.members)]
	leaver.current.moveToNullspace()
	team.check_departures()
	TEST_ASSERT(team.recruit(sleeper), "Отпущенного снова принимает клятва")
	TEST_ASSERT(sleeper in team.members - team.departed_minds, "Принятый снова активен")
	TEST_ASSERT_NULL(team.departed_reasons[sleeper], "У принятого нет причины ухода")

/// Удалённое тело при призраке с правом вернуться - уход после грации; крио - уход сразу
/datum/unit_test/blood_brothers_departure_deleted

/datum/unit_test/blood_brothers_departure_deleted/Run()
	var/datum/team/brother_team/team = allocate_brother_team(src, 3)
	var/datum/mind/gibbed = team.members[1]
	var/datum/mind/frozen = team.members[2]
	var/mob/living/carbon/human/gibbed_body = gibbed.current
	gibbed_body.key = "BloodBrotherGibbed"
	qdel(gibbed_body)
	var/mob/dead/observer/ghost = gibbed.get_ghost()
	TEST_ASSERT_NOTNULL(ghost, "Удалённое тело оставило призрака с правом вернуться")
	team.check_departures()
	TEST_ASSERT(!(gibbed in team.departed_minds), "Призрак может вернуться - уход не сразу")
	team.ghost_since[gibbed] = world.time - BROTHER_GHOST_GRACE
	team.check_departures()
	TEST_ASSERT(gibbed in team.departed_minds, "Грация кончилась - ушёл")
	TEST_ASSERT_EQUAL(team.departed_reasons[gibbed], BROTHER_DEPARTURE_DELETED, "Причина - удалённое тело")
	ghost.key = null
	qdel(ghost)
	cryoMob(frozen.current, null, null, FALSE, "cryo pod")
	team.check_departures()
	TEST_ASSERT(frozen in team.departed_minds, "Крио - уход сразу")
	TEST_ASSERT_EQUAL(team.departed_reasons[frozen], BROTHER_DEPARTURE_CRYO, "Причина - крио")

/// Шёпот пишется в журнал команды, журнал держит последние записи
/datum/unit_test/blood_brothers_whisper_log

/datum/unit_test/blood_brothers_whisper_log/Run()
	var/datum/team/brother_team/team = allocate_brother_team(src)
	var/datum/mind/speaker = team.members[1]
	var/datum/antagonist/brother/brother = speaker.has_antag_datum(/datum/antagonist/brother)
	var/datum/action/cooldown/blood_bond/whisper/whisper = brother.bond_actions[/datum/action/cooldown/blood_bond/whisper]
	whisper.send_whisper("первая &amp; весть")
	var/list/entry = team.whisper_log[1]
	TEST_ASSERT_EQUAL(entry["name"], speaker.current.real_name, "В журнале имя")
	TEST_ASSERT_EQUAL(entry["text"], "первая & весть", "В журнале текст без html-кодов")
	TEST_ASSERT(istext(entry["time"]), "В журнале время")
	for(var/message_number in 1 to BROTHER_WHISPER_LOG_SIZE)
		whisper.send_whisper("весть [message_number]")
	TEST_ASSERT_EQUAL(length(team.whisper_log), BROTHER_WHISPER_LOG_SIZE, "Журнал не растёт дальше предела")
	var/list/last_entry = team.whisper_log[BROTHER_WHISPER_LOG_SIZE]
	TEST_ASSERT_EQUAL(last_entry["text"], "весть [BROTHER_WHISPER_LOG_SIZE]", "Последняя запись - в конце")

/// Тело из крио удалено очередью раньше проверки команды - это всё равно уход в крио, и итоги помнят род ушедшего
/datum/unit_test/blood_brothers_departure_cryo_queue/Run()
	var/datum/team/brother_team/team = allocate_brother_team(src)
	var/datum/mind/frozen = team.members[1]
	var/mob/living/carbon/human/body = frozen.current
	body.gender = FEMALE
	cryoMob(body, null, null, FALSE, "cryo pod")
	var/saved_scan = SSauto_cryo.next_scan
	SSauto_cryo.next_scan = INFINITY
	for(var/drain_round in 1 to 100)
		if(QDELETED(body))
			break
		SSauto_cryo.fire()
	SSauto_cryo.next_scan = saved_scan
	TEST_ASSERT(QDELETED(body), "Очередь крио удалила тело")
	team.check_departures()
	TEST_ASSERT(frozen in team.departed_minds, "Ушедший в крио ушёл")
	TEST_ASSERT_EQUAL(team.departed_reasons[frozen], BROTHER_DEPARTURE_CRYO, "Причина - крио, а не пропавшее тело")
	TEST_ASSERT(findtext(team.roundend_departure_mark(frozen), "ушла в крио"), "Итоги помнят род ушедшей: [team.roundend_departure_mark(frozen)]")
