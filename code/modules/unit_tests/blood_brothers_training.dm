/// Тренировка братьев: аватар и болванчик - учебные братья, кнопки пульта действуют на болванчика, выход всё убирает
/datum/unit_test/blood_brothers_training

/datum/unit_test/blood_brothers_training/Run()
	var/datum/director_signals/before = allocate(/datum/director_signals)
	before.update()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/blood_brother)
	TEST_ASSERT(session.prepare(), "Полигон готов")
	var/mob/living/carbon/human/avatar = session.avatar
	var/datum/antagonist/brother/training/brother = avatar.mind.has_antag_datum(/datum/antagonist/brother/training)
	TEST_ASSERT_NOTNULL(brother, "Аватар - брат")
	var/datum/team/brother_team/training/team = brother.team
	TEST_ASSERT(istype(team) && team.training, "Команда учебная")
	TEST_ASSERT_EQUAL(length(team.members), 2, "Есть болванчик-брат")
	var/datum/mind/dummy_mind = team.members[2]
	var/mob/living/carbon/human/dummy = dummy_mind.current
	TEST_ASSERT_NOTNULL(dummy_mind.has_antag_datum(/datum/antagonist/brother/training), "Болванчик - учебный брат")
	TEST_ASSERT(dummy.Adjacent(avatar), "Болванчик стоит рядом с аватаром")
	TEST_ASSERT_NULL(team.roundend_report(), "Учебной команды нет в итогах раунда")
	TEST_ASSERT(!brother.show_in_roundend && !brother.show_in_check_antagonists && brother.soft_antag && !brother.threat, "Учебный брат не в итогах, не в списке антагонистов и без угрозы")
	var/datum/director_signals/after = allocate(/datum/director_signals)
	after.update()
	TEST_ASSERT_EQUAL(after.living_antags, before.living_antags, "Директор не считает учебных братьев")
	team.next_sense_at = 0
	team.process()
	var/datum/status_effect/brother_sense/sense = avatar.has_status_effect(/datum/status_effect/brother_sense)
	TEST_ASSERT_EQUAL(sense?.tracked, dummy_mind, "Чутьё ведёт болванчика")
	var/datum/antag_training_program/blood_brother/program = session.program
	var/list/data = session.ui_data(avatar)
	for(var/option in program.options)
		TEST_ASSERT(length(data["option_hints"][option]), "У кнопки «[option]» есть подсказка")
	program.handle_choice(session, avatar, "Поднять связь")
	TEST_ASSERT_EQUAL(team.bond_tier, 1, "Ступень поднялась")
	program.handle_choice(session, avatar, "Ранить брата")
	TEST_ASSERT(abs(dummy.getBruteLoss() - BROTHER_TRAINING_INJURY) < 0.1, "Болванчик ранен: [dummy.getBruteLoss()]")
	var/datum/antagonist/brother/dummy_brother = dummy_mind.has_antag_datum(/datum/antagonist/brother)
	TEST_ASSERT_EQUAL(dummy_brother.brother_state(), BROTHER_STATE_HURT, "Чутьё видит раненого брата")
	var/datum/action/cooldown/blood_bond/blood_for_blood/transfusion = brother.bond_actions[/datum/action/cooldown/blood_bond/blood_for_blood]
	TEST_ASSERT(transfusion.Trigger(), "Кровь за кровь отдаётся болванчику")
	TEST_ASSERT(dummy.getBruteLoss() < BROTHER_TRAINING_INJURY, "Кровь затянула часть ран болванчика")
	program.handle_choice(session, avatar, "Поднять связь")
	program.handle_choice(session, avatar, "Связать брата")
	TEST_ASSERT(dummy.handcuffed, "Болванчик в наручниках")
	team.next_sense_at = 0
	team.process()
	TEST_ASSERT_NOTNULL(avatar.has_status_effect(/datum/status_effect/brother_fury), "Наручники болванчика будят Ярость")
	program.handle_choice(session, avatar, "Связать брата")
	TEST_ASSERT(!dummy.handcuffed, "Наручники сняты")
	program.handle_choice(session, avatar, "Убить и оживить брата")
	TEST_ASSERT_EQUAL(dummy.stat, DEAD, "Болванчик погиб")
	TEST_ASSERT_NOTNULL(avatar.alerts["brother_fallen"], "Аватар чувствует смерть брата")
	program.handle_choice(session, avatar, "Убить и оживить брата")
	TEST_ASSERT_NOTEQUAL(dummy.stat, DEAD, "Болванчик ожил")
	TEST_ASSERT_NULL(avatar.alerts["brother_fallen"], "Оживление снимает горе")
	program.handle_choice(session, avatar, "Майндшилд на себя / снять")
	TEST_ASSERT(brother.is_muted(), "Майндшилд глушит связь")
	program.handle_choice(session, avatar, "Майндшилд на себя / снять")
	TEST_ASSERT(!brother.is_muted(), "Снятый майндшилд возвращает связь")
	TEST_ASSERT(!length(avatar.implants), "Имплант удалён")
	program.handle_choice(session, avatar, "Обряд разрыва на болванчике")
	TEST_ASSERT_NULL(dummy_mind.has_antag_datum(/datum/antagonist/brother), "Обряд разорвал клятву болванчика")
	TEST_ASSERT(dummy_mind in team.severed_minds, "Разрыв запомнен")
	TEST_ASSERT(team.replacement_available, "Место брата можно отдать")
	var/mob/living/carbon/human/outsider = allocate(/mob/living/carbon/human, get_step(avatar, WEST))
	outsider.mind_initialize()
	TEST_ASSERT(istext(team.can_recruit(avatar.mind, outsider)), "Человека не из учебных целей не позвать")
	var/mob/living/carbon/human/third = session.arena.spawn_creature("human", "laboratory", FALSE, session)
	third.forceMove(get_step(avatar, NORTH))
	var/datum/action/cooldown/blood_bond/recruit/recruit = brother.bond_actions[/datum/action/cooldown/blood_bond/recruit]
	TEST_ASSERT(recruit.Trigger(), "Клятва крови зовёт учебную цель")
	TEST_ASSERT_NOTNULL(third.mind.has_antag_datum(/datum/antagonist/brother/training), "Учебная цель стала учебным братом")
	TEST_ASSERT_NULL(outsider.mind.has_antag_datum(/datum/antagonist/brother), "Посторонний не стал братом")
	var/datum/antag_training_arena/arena = session.arena
	qdel(session)
	TEST_ASSERT(wait_for_qdeleted(arena, 1 MINUTES), "Выход единственного участника закрывает полигон")
	TEST_ASSERT(QDELETED(team), "Выход удаляет команду")
	TEST_ASSERT(!(team in GLOB.antagonist_teams), "Команды нет в списке команд")
	TEST_ASSERT(QDELETED(dummy) && QDELETED(dummy_mind), "Выход удаляет болванчика")

/// Тренировка братьев: клятва даётся одной подписью, смена клятвы берёт цель с полигона, вещь для шага скрепляется, удалённые цели отпускаются
/datum/unit_test/blood_brothers_training_oath

/datum/unit_test/blood_brothers_training_oath/Run()
	var/datum/antag_opt_in_test_world/world_state = blood_brothers_oath_world()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/blood_brother)
	TEST_ASSERT(session.prepare(), "Полигон готов")
	var/datum/mind/station_mind = antag_opt_in_crew(ANTAG_OPT_IN_ROUND_REMOVE)
	world_state.set_crew(list(station_mind))
	var/mob/living/carbon/human/avatar = session.avatar
	var/datum/antagonist/brother/training/brother = avatar.mind.has_antag_datum(/datum/antagonist/brother/training)
	var/datum/team/brother_team/training/team = brother.team
	TEST_ASSERT(length(team.offered), "Клятвы предложены")
	var/datum/blood_oath/choice = team.offered[1]
	var/datum/tgui/avatar_ui = allocate(/datum/tgui, avatar, brother, "AntagInfoBloodBrother")
	avatar_ui.status = UI_INTERACTIVE
	TEST_ASSERT(brother.ui_act("propose", list("key" = choice.key), avatar_ui), "Предложение из окна")
	TEST_ASSERT_EQUAL(team.oath, choice, "Болванчик не мешает: клятва дана одной подписью")
	var/datum/antag_training_program/blood_brother/program = session.program
	TEST_ASSERT(program.change_oath(avatar, /datum/blood_oath/heist), "Клятва сменена на Добычу")
	var/datum/blood_oath_step/heist_item/loot_step = team.oath.steps[1]
	program.handle_choice(session, avatar, "Ценность для текущего шага")
	TEST_ASSERT_NOTNULL(avatar.is_holding_item_of_type(loot_step.item_type), "Выдана ценность первого шага")
	TEST_ASSERT(brother.ui_act("seal", list(), avatar_ui), "Скрепление из окна")
	TEST_ASSERT(loot_step.sealed, "Шаг скреплён выданной ценностью")
	TEST_ASSERT(program.change_oath(avatar, /datum/blood_oath/vendetta), "Клятва сменена на Месть")
	var/datum/mind/target_mind = team.oath.target_mind
	TEST_ASSERT(target_mind in session.arena.target_minds, "Цель Мести - учебная цель полигона, а не экипаж")
	TEST_ASSERT_NOTEQUAL(target_mind, station_mind, "Экипаж станции целью не стал")
	session.next_supply_at = 0
	program.handle_choice(session, avatar, "Ценность для текущего шага")
	var/obj/item/card/id/card = avatar.is_holding_item_of_type(/obj/item/card/id)
	TEST_ASSERT_EQUAL(card?.registered_name, target_mind.name, "Выдана ID-карта на имя цели")
	TEST_ASSERT(brother.ui_act("seal", list(), avatar_ui), "Скрепление из окна")
	TEST_ASSERT_EQUAL(team.bond_tier, 2, "Две печати - две ступени")
	var/mob/living/carbon/human/target_body = target_mind.current
	QDEL_NULL(target_body.mind)
	qdel(target_body)
	TEST_ASSERT_NULL(team.oath, "Удалённая цель снимает клятву")
	TEST_ASSERT_NULL(team.training_target, "Команда отпускает удалённую цель")
	TEST_ASSERT(program.change_oath(avatar, /datum/blood_oath/liberation), "Вызволению нашлась учебная цель")
	TEST_ASSERT(team.oath.target_mind in session.arena.target_minds, "Цель Вызволения - учебная цель полигона")
	var/datum/mind/dummy_mind = team.members[2]
	var/mob/living/carbon/human/dummy = dummy_mind.current
	QDEL_NULL(dummy.mind)
	qdel(dummy)
	TEST_ASSERT(!(dummy_mind in team.members) && !(dummy_mind in team.departed_minds), "Команда отпускает удалённого болванчика")
	TEST_ASSERT_NULL(avatar.has_status_effect(/datum/status_effect/brother_sense), "Чутьё не держит удалённого брата")
