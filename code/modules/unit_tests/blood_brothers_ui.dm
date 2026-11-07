/proc/blood_brothers_ui_entry(list/entries, name)
	for(var/list/entry as anything in entries)
		if(entry["name"] == name)
			return entry
	return null

/proc/blood_brothers_ui_window(datum/unit_test/test, datum/antagonist/brother/brother)
	var/datum/tgui/window = test.allocate(/datum/tgui, brother.owner.current, brother, "AntagInfoBloodBrother")
	window.status = UI_INTERACTIVE
	return window

/// Заглушённый не чувствует братьев и не голосует; у заглушённого брата нет направления
/datum/unit_test/blood_brothers_ui_muted

/datum/unit_test/blood_brothers_ui_muted/Run()
	var/datum/antag_opt_in_test_world/world_state = blood_brothers_oath_world()
	var/datum/team/brother_team/team = allocate_brother_team(src)
	world_state.set_crew(team.members + antag_opt_in_crew(ANTAG_OPT_IN_ROUND_REMOVE))
	team.offer_oaths()
	var/datum/mind/first = team.members[1]
	var/datum/mind/second = team.members[2]
	var/datum/antagonist/brother/first_brother = first.has_antag_datum(/datum/antagonist/brother)
	var/datum/antagonist/brother/second_brother = second.has_antag_datum(/datum/antagonist/brother)
	second.current.forceMove(get_step(first.current, EAST))
	var/list/own_entry = blood_brothers_ui_entry(first_brother.ui_data(first.current)["brother_states"], first.name)
	TEST_ASSERT(own_entry["self"], "Своя строка помечена")
	TEST_ASSERT_NULL(own_entry["direction"], "У себя направления нет")
	var/obj/item/implant/mindshield/shield = new(first.current)
	TEST_ASSERT(shield.implant(first.current, null, TRUE), "Майндшилд поставлен")
	var/list/seen = blood_brothers_ui_entry(first_brother.ui_data(first.current)["brother_states"], second.name)
	TEST_ASSERT_EQUAL(seen["state"], BROTHER_STATE_MUTED, "Заглушённый не чувствует, что с братом")
	TEST_ASSERT_NULL(seen["direction"], "Заглушённый не чувствует, где брат")
	TEST_ASSERT(!seen["self"], "Чужая строка не своя")
	var/list/seen_by_second = blood_brothers_ui_entry(second_brother.ui_data(second.current)["brother_states"], first.name)
	TEST_ASSERT_EQUAL(seen_by_second["state"], BROTHER_STATE_MUTED, "Брат видит заглушённого")
	TEST_ASSERT_NULL(seen_by_second["direction"], "У заглушённого брата направления нет")
	var/datum/blood_oath/choice = team.offered[1]
	first_brother.ui_act("propose", list("key" = choice.key), blood_brothers_ui_window(src, first_brother))
	TEST_ASSERT_NULL(team.proposed, "Заглушённый не предлагает клятву из окна")
	TEST_ASSERT(second_brother.ui_act("propose", list("key" = choice.key), blood_brothers_ui_window(src, second_brother)), "Брат предлагает")
	first_brother.ui_act("sign", list(), blood_brothers_ui_window(src, first_brother))
	TEST_ASSERT(!(first in team.signed), "Заглушённый не подписывает из окна")

/// Тексты клятв уходят статикой, в данных только ключи и печати; финал и неподписавшие видны
/datum/unit_test/blood_brothers_ui_static_texts

/datum/unit_test/blood_brothers_ui_static_texts/Run()
	var/datum/antag_opt_in_test_world/world_state = blood_brothers_oath_world()
	var/datum/team/brother_team/team = allocate_brother_team(src)
	world_state.set_crew(team.members + antag_opt_in_crew(ANTAG_OPT_IN_ROUND_REMOVE))
	team.offer_oaths()
	var/datum/mind/first = team.members[1]
	var/datum/mind/second = team.members[2]
	var/datum/antagonist/brother/first_brother = first.has_antag_datum(/datum/antagonist/brother)
	var/datum/antagonist/brother/second_brother = second.has_antag_datum(/datum/antagonist/brother)
	var/list/static_data = first_brother.ui_static_data(first.current)
	var/list/offer_texts = static_data["offer_texts"]
	TEST_ASSERT_EQUAL(length(offer_texts), length(team.offered), "Тексты всех предложений в статике")
	var/list/first_texts = offer_texts[1]
	TEST_ASSERT(istext(first_texts["story"]), "История клятвы в статике")
	TEST_ASSERT(findtext(first_texts["finale"], "всем живым братьям - до ЦК, без наручников"), "Финал в статике: [first_texts["finale"]]")
	var/datum/blood_oath/choice = team.offered[1]
	var/list/data = first_brother.ui_data(first.current)
	var/list/offered_keys = data["offered"]
	TEST_ASSERT_EQUAL(offered_keys[1], choice.key, "В данных выбора только ключи")
	TEST_ASSERT(first_brother.ui_act("propose", list("key" = choice.key), blood_brothers_ui_window(src, first_brother)), "Предложение из окна")
	data = first_brother.ui_data(first.current)
	TEST_ASSERT(second.name in data["unsigned"], "Окно называет, чьей подписи ждём")
	TEST_ASSERT(!(first.name in data["unsigned"]), "Предложивший уже подписал")
	TEST_ASSERT(second_brother.ui_act("sign", list(), blood_brothers_ui_window(src, second_brother)), "Подпись из окна")
	static_data = first_brother.ui_static_data(first.current)
	var/list/oath_texts = static_data["oath_texts"]
	TEST_ASSERT_EQUAL(oath_texts["name"], choice.name, "Данная клятва в статике")
	TEST_ASSERT_EQUAL(length(oath_texts["steps"]), length(choice.steps), "Тексты шагов в статике")
	data = first_brother.ui_data(first.current)
	var/list/progress = data["oath"]
	TEST_ASSERT_NULL(progress["story"], "Истории в данных каждого тика нет")
	var/list/first_step = progress["steps"][1]
	TEST_ASSERT_NULL(first_step["desc"], "Описания шагов в данных каждого тика нет")
	TEST_ASSERT(istext(first_step["condition"]), "Условие текущего шага - в данных")
	TEST_ASSERT_NULL(data["finale_check"], "До третьей печати проверки финала нет")

/// Разорванный брат остаётся в шапке с типом разрыва; крит отличается от сна
/datum/unit_test/blood_brothers_ui_brother_states

/datum/unit_test/blood_brothers_ui_brother_states/Run()
	var/datum/team/brother_team/team = allocate_brother_team(src, 3)
	var/datum/mind/first = team.members[1]
	var/datum/mind/second = team.members[2]
	var/datum/mind/third = team.members[3]
	var/datum/antagonist/brother/first_brother = first.has_antag_datum(/datum/antagonist/brother)
	team.sever(third, "тест", BROTHER_SEVER_RITE)
	var/list/states = first_brother.ui_data(first.current)["brother_states"]
	var/list/severed_entry = blood_brothers_ui_entry(states, third.name)
	TEST_ASSERT_NOTNULL(severed_entry, "Разорванный остался в шапке")
	TEST_ASSERT_EQUAL(severed_entry["state"], BROTHER_STATE_SEVERED, "Состояние - клятва разорвана")
	TEST_ASSERT(findtext(severed_entry["state_text"], "клятву разорвали: обряд"), "Подпись называет обряд: [severed_entry["state_text"]]")
	TEST_ASSERT_NULL(severed_entry["direction"], "У разорванного направления нет")
	var/list/static_brothers = first_brother.ui_static_data(first.current)["brothers"]
	TEST_ASSERT(blood_brothers_ui_entry(static_brothers, first.name)["self"], "Своё имя помечено в статике")
	var/mob/living/carbon/human/second_body = second.current
	second_body.SetSleeping(10 SECONDS)
	var/list/sleeping_entry = blood_brothers_ui_entry(first_brother.ui_data(first.current)["brother_states"], second.name)
	TEST_ASSERT_EQUAL(sleeping_entry["state"], BROTHER_STATE_CRIT, "Спящий без сознания")
	TEST_ASSERT(!sleeping_entry["critical"], "Сон - не крит")
	second_body.SetSleeping(0)
	second_body.adjustBruteLoss(second_body.maxHealth + 20, forced = TRUE)
	second_body.updatehealth()
	var/list/crit_entry = blood_brothers_ui_entry(first_brother.ui_data(first.current)["brother_states"], second.name)
	TEST_ASSERT(crit_entry["critical"], "Настоящий крит отмечен")
	TEST_ASSERT(findtext(crit_entry["state_text"], "без сознания"), "Состояние словами из игры: [crit_entry["state_text"]]")

/// После третьей печати окно показывает, кто уже на ЦК, кто в наручниках, а кто мёртв и не мешает
/datum/unit_test/blood_brothers_ui_finale_check

/datum/unit_test/blood_brothers_ui_finale_check/Run()
	blood_brothers_oath_world()
	var/datum/team/brother_team/team = allocate_brother_team(src, 3)
	var/datum/blood_oath/heist/oath = new
	TEST_ASSERT(oath.prepare(team), "Добыча готова")
	team.swear_oath(oath)
	for(var/datum/blood_oath_step/oath_step as anything in oath.steps)
		oath_step.sealed = TRUE
	var/datum/mind/first = team.members[1]
	var/datum/mind/second = team.members[2]
	var/datum/mind/third = team.members[3]
	var/datum/antagonist/brother/first_brother = first.has_antag_datum(/datum/antagonist/brother)
	var/mob/living/carbon/human/second_body = second.current
	second_body.handcuffed = allocate(/obj/item/restraints/handcuffs, second_body)
	second_body.update_handcuffed()
	third.current.death()
	var/list/check = first_brother.ui_data(first.current)["finale_check"]
	TEST_ASSERT_NOTNULL(check, "Проверка финала после всех печатей")
	var/list/rows = check["brothers"]
	TEST_ASSERT_EQUAL(blood_brothers_ui_entry(rows, first.name)["status"], "ещё на станции", "Живой брат на станции")
	TEST_ASSERT_EQUAL(blood_brothers_ui_entry(rows, second.name)["status"], "в наручниках", "Скованный брат мешает финалу")
	TEST_ASSERT_EQUAL(blood_brothers_ui_entry(rows, third.name)["status"], "не мешает", "Мёртвый финалу не мешает")
	second_body.uncuff()

/// Окно: имя кнопки, предыстория третьего, слоты клятвы, награда обета, шёпоты
/datum/unit_test/blood_brothers_ui_bond_details

/datum/unit_test/blood_brothers_ui_bond_details/Run()
	var/datum/team/brother_team/team = allocate_brother_team(src)
	var/datum/mind/first = team.members[1]
	var/datum/antagonist/brother/first_brother = first.has_antag_datum(/datum/antagonist/brother)
	TEST_ASSERT_EQUAL(first_brother.info_button?.name, "Кровная клятва", "Кнопка окна по-русски")
	var/list/static_data = first_brother.ui_static_data(first.current)
	TEST_ASSERT(static_data["backstory_owner"], "Основатель видит предысторию своей")
	var/flawless_percent = round((1 - BROTHER_FLAWLESS_COOLDOWN_MULT) * 100)
	TEST_ASSERT(findtext(jointext(static_data["rules"], " "), "на [flawless_percent]% короче"), "Награда обета в памятке совпадает с дефайном")
	var/list/data = first_brother.ui_data(first.current)
	TEST_ASSERT_EQUAL(data["recruit"]["slot"], "свободна", "Слот третьего свободен")
	TEST_ASSERT_EQUAL(data["cooldown_mult"], 1, "Перезарядки без награды")
	team.started = TRUE
	var/datum/mind/third = allocate_brother_mind(src)
	TEST_ASSERT(team.recruit(third), "Третий принят")
	var/datum/antagonist/brother/third_brother = third.has_antag_datum(/datum/antagonist/brother)
	TEST_ASSERT(!third_brother.ui_static_data(third.current)["backstory_owner"], "Третьему предыстория чужая")
	TEST_ASSERT_EQUAL(first_brother.ui_data(first.current)["recruit"]["slot"], "использована", "Слот третьего потрачен")
	var/datum/action/cooldown/blood_bond/recruit/recruit = first_brother.bond_actions[/datum/action/cooldown/blood_bond/recruit]
	var/atom/movable/screen/movable/action_button/button = allocate(/atom/movable/screen/movable/action_button)
	recruit.UpdateButton(button)
	TEST_ASSERT(findtext(button.desc, "использована"), "Подсказка кнопки называет слот: [button.desc]")
	third.current.moveToNullspace()
	team.check_departures()
	TEST_ASSERT_EQUAL(first_brother.ui_data(first.current)["recruit"]["slot"], "открыта замена", "Уход открывает замену")
	team.cooldown_multiplier = BROTHER_FLAWLESS_COOLDOWN_MULT
	TEST_ASSERT_EQUAL(first_brother.ui_data(first.current)["cooldown_mult"], BROTHER_FLAWLESS_COOLDOWN_MULT, "Окно знает множитель перезарядки")
	var/datum/action/cooldown/blood_bond/whisper/whisper = first_brother.bond_actions[/datum/action/cooldown/blood_bond/whisper]
	whisper.send_whisper("проверка")
	TEST_ASSERT_EQUAL(length(first_brother.ui_data(first.current)["whispers"]), 1, "Журнал шёпота в окне")
	ADD_TRAIT(first.current, TRAIT_MINDSHIELD, "test")
	TEST_ASSERT(!length(first_brother.ui_data(first.current)["whispers"]), "Заглушённый журнала не видит")
	REMOVE_TRAIT(first.current, TRAIT_MINDSHIELD, "test")

/// «Сменить клятву» на полигоне не предлагает клятв, недоступных учебной команде
/datum/unit_test/blood_brothers_ui_training_oaths

/datum/unit_test/blood_brothers_ui_training_oaths/Run()
	blood_brothers_oath_world()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/blood_brother)
	TEST_ASSERT(session.prepare(), "Полигон готов")
	var/datum/antag_training_program/blood_brother/program = session.program
	var/list/choices = list()
	var/list/named = program.oath_choices()
	for(var/oath_name in named)
		choices += named[oath_name]
	TEST_ASSERT(!(/datum/blood_oath/discord in choices), "Разлада на полигоне нет")
	TEST_ASSERT(!(/datum/blood_oath/hijack in choices), "Угона на полигоне нет")
	TEST_ASSERT(/datum/blood_oath/heist in choices, "Добыча на полигоне есть")
	TEST_ASSERT(/datum/blood_oath/liberation in choices, "Вызволение есть: цель программа создаст сама")

/// Итоги раунда: нить между именами, печати словами, финал, ушедшие и разорванные
/datum/unit_test/blood_brothers_ui_roundend

/datum/unit_test/blood_brothers_ui_roundend/Run()
	blood_brothers_oath_world()
	var/datum/team/brother_team/team = allocate_brother_team(src, 4)
	var/datum/blood_oath/heist/oath = new
	TEST_ASSERT(oath.prepare(team), "Добыча готова")
	team.swear_oath(oath)
	var/datum/mind/first = team.members[1]
	var/datum/mind/second = team.members[2]
	var/datum/mind/severed = team.members[3]
	var/datum/mind/departed = team.members[4]
	var/datum/blood_oath_step/heist_item/first_step = oath.steps[1]
	first.current.put_in_hands(allocate(first_step.item_type))
	TEST_ASSERT(team.try_seal(first) == TRUE, "Первая печать")
	team.sever(severed, "тест", BROTHER_SEVER_SURGERY)
	departed.current.moveToNullspace()
	team.check_departures()
	var/report = team.roundend_report()
	TEST_ASSERT(findtext(report, "<b>[first.name]</b> <span class='redtext'>[BROTHER_ROUNDEND_THREAD]</span> <b>[second.name]</b>"), "Целая нить между живыми братьями")
	TEST_ASSERT(findtext(report, "<span class='redtext'>[BROTHER_ROUNDEND_TORN]</span> <b>[departed.name]</b>"), "Нить к ушедшему порвана")
	TEST_ASSERT(findtext(report, "Первая печать"), "Печати словами")
	TEST_ASSERT(findtext(report, "скреплено ([first.name])"), "Кто скрепил")
	TEST_ASSERT(findtext(report, "Вторая печать"), "Нескреплённая печать названа")
	TEST_ASSERT(findtext(report, "Клятва [severed.name] разорвана операцией"), "Разорванный с причиной")
	TEST_ASSERT(findtext(report, "в крио"), "Ушедший с причиной")
	TEST_ASSERT(findtext(report, "всем живым братьям - до ЦК, без наручников"), "Финал назван")
	TEST_ASSERT(findtext(report, "Обет"), "Обет назван")
	TEST_ASSERT(findtext(report, "class='panel"), "Итоги в своей панели")

/// Заглушённому окно не выдаёт чужого: финал только о себе, без капли по нити; шёпоты - только услышанные зрителем
/datum/unit_test/blood_brothers_ui_muted_leaks/Run()
	blood_brothers_oath_world()
	var/datum/team/brother_team/team = allocate_brother_team(src)
	var/datum/blood_oath/heist/oath = new
	TEST_ASSERT(oath.prepare(team), "Добыча готова")
	team.swear_oath(oath)
	for(var/datum/blood_oath_step/oath_step as anything in oath.steps)
		oath_step.sealed = TRUE
	var/datum/mind/first = team.members[1]
	var/datum/mind/second = team.members[2]
	var/datum/antagonist/brother/first_brother = first.has_antag_datum(/datum/antagonist/brother)
	var/datum/antagonist/brother/second_brother = second.has_antag_datum(/datum/antagonist/brother)
	var/datum/action/cooldown/blood_bond/whisper/whisper = second_brother.bond_actions[/datum/action/cooldown/blood_bond/whisper]
	whisper.send_whisper("до глушения")
	ADD_TRAIT(first.current, TRAIT_MINDSHIELD, "test")
	whisper.send_whisper("при глушении")
	var/list/muted_data = first_brother.ui_data(first.current)
	var/list/rows = muted_data["finale_check"]["brothers"]
	TEST_ASSERT_EQUAL(length(rows), 1, "Заглушённый видит в финале только себя")
	TEST_ASSERT_NOTNULL(blood_brothers_ui_entry(rows, first.name), "Своя строка финала на месте")
	TEST_ASSERT_NULL(muted_data["bond_pulse"], "Заглушённому капля по нити не приходит")
	REMOVE_TRAIT(first.current, TRAIT_MINDSHIELD, "test")
	var/list/heard = first_brother.ui_data(first.current)["whispers"]
	TEST_ASSERT_EQUAL(length(heard), 1, "В окне только услышанный шёпот")
	TEST_ASSERT_EQUAL(heard[1]["text"], "до глушения", "Шёпот до глушения на месте")
	TEST_ASSERT_NULL(heard[1]["heard"], "Список слышавших в окно не уходит")
	TEST_ASSERT_EQUAL(length(second_brother.ui_data(second.current)["whispers"]), 2, "Шептавший видит оба шёпота")
	team.started = TRUE
	var/datum/mind/third = allocate_brother_mind(src)
	TEST_ASSERT(team.recruit(third), "Третий принят")
	var/datum/antagonist/brother/third_brother = third.has_antag_datum(/datum/antagonist/brother)
	TEST_ASSERT(!length(third_brother.ui_data(third.current)["whispers"]), "Новый брат не видит переписку до себя")
	whisper.send_whisper("при третьем")
	TEST_ASSERT_EQUAL(length(third_brother.ui_data(third.current)["whispers"]), 1, "Новый брат видит шёпот после клятвы")

/datum/blood_oath_step/blood_brothers_seal_counter
	name = "Счётчик проверок"
	var/checks = 0

/datum/blood_oath_step/blood_brothers_seal_counter/can_seal(mob/living/sealer)
	checks++
	return "проверка"

/datum/blood_oath_step/blood_brothers_seal_counter/condition_text(mob/living/viewer, sealable)
	return "готово: [sealable_now(viewer, sealable) ? "да" : "нет"]"

/// Окно проверяет условие текущего шага один раз на обновление
/datum/unit_test/blood_brothers_ui_can_seal_once/Run()
	var/datum/team/brother_team/team = allocate_brother_team(src)
	var/datum/blood_oath/blood_brothers_capstone_test/oath = new
	var/datum/blood_oath_step/blood_brothers_seal_counter/counter = oath.add_step(new /datum/blood_oath_step/blood_brothers_seal_counter)
	team.swear_oath(oath)
	var/datum/mind/first = team.members[1]
	var/datum/antagonist/brother/first_brother = first.has_antag_datum(/datum/antagonist/brother)
	counter.checks = 0
	var/list/data = first_brother.ui_data(first.current)
	TEST_ASSERT_EQUAL(counter.checks, 1, "can_seal на одно обновление окна - один раз")
	TEST_ASSERT_EQUAL(data["can_seal"], "проверка", "Отказ шага дошёл до кнопки")
	TEST_ASSERT_EQUAL(data["oath"]["steps"][1]["condition"], "готово: нет", "Условие шага по тому же ответу")
