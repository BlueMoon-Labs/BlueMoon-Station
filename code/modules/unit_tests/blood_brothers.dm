/proc/allocate_brother_mind(datum/unit_test/test, role = "Assistant")
	var/mob/living/carbon/human/body = test.allocate(/mob/living/carbon/human)
	body.mind_initialize()
	body.mind.assigned_role = role
	return body.mind

/proc/allocate_brother_team(datum/unit_test/test, size = BROTHER_TEAM_START_SIZE)
	var/datum/team/brother_team/team = new
	test.allocated += team
	for(var/member_number in 1 to size)
		var/datum/mind/member = allocate_brother_mind(test)
		var/datum/antagonist/brother/brother = new
		brother.silent = TRUE
		member.add_antag_datum(brother, team)
	return team

/// Пара: оба в команде, особая роль, HUD-значок, шрам
/datum/unit_test/blood_brothers_pair

/datum/unit_test/blood_brothers_pair/Run()
	var/datum/team/brother_team/team = allocate_brother_team(src)
	TEST_ASSERT_EQUAL(length(team.members), 2, "В паре два брата")
	for(var/datum/mind/member as anything in team.members)
		var/datum/antagonist/brother/brother = member.has_antag_datum(/datum/antagonist/brother)
		TEST_ASSERT_NOTNULL(brother, "Брат получил датум")
		TEST_ASSERT_EQUAL(brother.team, team, "Датум знает свою команду")
		TEST_ASSERT_EQUAL(member.special_role, ROLE_BROTHER, "Особая роль выставлена")
		TEST_ASSERT_EQUAL(member.antag_hud_icon_state, "blood_brother", "HUD-значок братьев")
		TEST_ASSERT(HAS_TRAIT(member.current, TRAIT_BLOOD_OATH_SCAR), "Шрам клятвы на теле")
		TEST_ASSERT_EQUAL(brother.brother_state(), BROTHER_STATE_OK, "Здоровый брат - цел")

/// HUD показывает братьев только своей команде
/datum/unit_test/blood_brothers_hud_isolated

/datum/unit_test/blood_brothers_hud_isolated/Run()
	var/datum/team/brother_team/first = allocate_brother_team(src)
	var/datum/team/brother_team/second = allocate_brother_team(src)
	var/datum/atom_hud/antag/brother/hud = GLOB.huds[ANTAG_HUD_BROTHER]
	TEST_ASSERT(istype(hud), "Худ братьев - свой тип")
	var/datum/mind/first_a = first.members[1]
	var/datum/mind/first_b = first.members[2]
	var/datum/mind/second_a = second.members[1]
	TEST_ASSERT(first_b.current in hud.hudatoms, "Брат носит значок худа")
	TEST_ASSERT(hud.hudusers[first_a.current], "Брат смотрит худ братьев")
	TEST_ASSERT(hud.should_show_to(first_a.current, first_b.current), "Брат видит своего брата")
	TEST_ASSERT(!hud.should_show_to(first_a.current, second_a.current), "Чужая команда не видна")
	var/mob/living/carbon/human/stranger = allocate(/mob/living/carbon/human)
	stranger.mind_initialize()
	TEST_ASSERT(!hud.should_show_to(stranger, first_a.current), "Экипаж не видит братьев")

/// Снятие датума убирает роль, шрам и HUD
/datum/unit_test/blood_brothers_removal

/datum/unit_test/blood_brothers_removal/Run()
	var/datum/team/brother_team/team = allocate_brother_team(src)
	var/datum/mind/member = team.members[1]
	member.remove_antag_datum(/datum/antagonist/brother)
	TEST_ASSERT_NULL(member.has_antag_datum(/datum/antagonist/brother), "Датум снят")
	TEST_ASSERT(!(member in team.members), "Ушёл из команды")
	TEST_ASSERT_NULL(member.special_role, "Особая роль снята")
	TEST_ASSERT(!HAS_TRAIT(member.current, TRAIT_BLOOD_OATH_SCAR), "Шрама нет")
	TEST_ASSERT_NULL(member.antag_hud_icon_state, "HUD-значок снят")
	var/datum/atom_hud/antag/brother/hud = GLOB.huds[ANTAG_HUD_BROTHER]
	TEST_ASSERT(!(member.current in hud.hudatoms), "Значок ушёл из худа")

/// Майндшилд заглушает значок и состояние брата, снятие возвращает
/datum/unit_test/blood_brothers_mindshield_hud

/datum/unit_test/blood_brothers_mindshield_hud/Run()
	var/datum/team/brother_team/team = allocate_brother_team(src)
	var/datum/mind/member = team.members[1]
	var/datum/antagonist/brother/brother = member.has_antag_datum(/datum/antagonist/brother)
	var/obj/item/implant/mindshield/implant = allocate(/obj/item/implant/mindshield)
	TEST_ASSERT(implant.implant(member.current, null, TRUE), "Майндшилд вживлён")
	TEST_ASSERT(brother.is_muted(), "Майндшилд заглушает связь")
	TEST_ASSERT_EQUAL(brother.brother_state(), BROTHER_STATE_MUTED, "Состояние - заглушён")
	TEST_ASSERT_EQUAL(member.antag_hud_icon_state, "blood_brother_muted", "HUD - заглушён")
	qdel(implant)
	TEST_ASSERT(!brother.is_muted(), "Без майндшилда связь вернулась")
	TEST_ASSERT_EQUAL(member.antag_hud_icon_state, "blood_brother", "HUD снова обычный")

/// Разрыв клятвы снимает датум, закрывает повторную вербовку и открывает замену
/datum/unit_test/blood_brothers_sever

/datum/unit_test/blood_brothers_sever/Run()
	var/datum/team/brother_team/team = allocate_brother_team(src)
	var/datum/mind/stayer = team.members[1]
	var/datum/mind/severed = team.members[2]
	var/datum/antagonist/brother/severed_brother = severed.has_antag_datum(/datum/antagonist/brother)
	var/list/admin_commands = severed_brother.get_admin_commands()
	var/datum/callback/sever_command = admin_commands["Разорвать клятву"]
	sever_command.Invoke(allocate(/mob/living/carbon/human))
	TEST_ASSERT_NOTNULL(locate(/obj/effect/temp_visual/blood_brothers/sever_snap) in get_turf(severed.current), "Над разорванным лопается нить")
	TEST_ASSERT_NULL(severed.has_antag_datum(/datum/antagonist/brother), "Разорванный потерял датум")
	TEST_ASSERT(severed in team.severed_minds, "Разорванный запомнен")
	TEST_ASSERT(severed in team.departed_minds, "Разрыв считается уходом")
	TEST_ASSERT(team.replacement_available, "Оставшемуся открыта внеочередная клятва")
	TEST_ASSERT(!team.abandoned, "Команда не брошена, пока брат на месте")
	TEST_ASSERT_EQUAL(length(team.living_brothers()), 1, "Живой брат один")
	TEST_ASSERT_EQUAL(team.living_brothers()[1], stayer.current, "Живой брат - оставшийся")
	team.sever(stayer, "тест")
	TEST_ASSERT(team.abandoned, "Без братьев команда брошена")

/// Ступень связи ограничена и сообщает о смене
/datum/unit_test/blood_brothers_bond_tier

/datum/unit_test/blood_brothers_bond_tier/Run()
	var/datum/team/brother_team/team = allocate_brother_team(src)
	TEST_ASSERT(team.set_bond_tier(BLOOD_BOND_TIER_MAX + 5), "Ступень поднялась")
	TEST_ASSERT_EQUAL(team.bond_tier, BLOOD_BOND_TIER_MAX, "Ступень не выше предельной")
	TEST_ASSERT(!team.set_bond_tier(BLOOD_BOND_TIER_MAX), "Та же ступень ничего не меняет")
	TEST_ASSERT(team.set_bond_tier(-1), "Ступень опустилась")
	TEST_ASSERT_EQUAL(team.bond_tier, 0, "Ступень не ниже нуля")

/// Раундстарт-рулсет собирает пары
/datum/unit_test/blood_brothers_roundstart_ruleset

/datum/unit_test/blood_brothers_roundstart_ruleset/Run()
	var/datum/game_mode/dynamic/mode = allocate(/datum/game_mode/dynamic)
	var/datum/dynamic_ruleset/roundstart/traitorbro/rule = allocate(/datum/dynamic_ruleset/roundstart/traitorbro)
	rule.mode = mode
	TEST_ASSERT(!(ROUNDTYPE_DYNAMIC_TEAMBASED in rule.required_round_type), "В тимбазе братьев на старте нет")
	for(var/candidate_number in 1 to 4)
		var/datum/mind/candidate = allocate_brother_mind(src)
		rule.candidates += candidate.current
	TEST_ASSERT(rule.pre_execute(20), "Рулсет набрал пары")
	TEST_ASSERT(rule.execute(), "Рулсет выполнен")
	TEST_ASSERT(length(rule.pre_brother_teams) >= 1, "Есть команда")
	for(var/datum/team/brother_team/team as anything in rule.pre_brother_teams)
		allocated += team
		TEST_ASSERT_EQUAL(length(team.members), BROTHER_TEAM_START_SIZE, "Команда - пара")
		TEST_ASSERT(team.started, "Команда запущена")
		TEST_ASSERT(team.datum_flags & DF_ISPROCESSING, "Запущенная команда следит за братьями")
		for(var/datum/mind/member as anything in team.members)
			TEST_ASSERT(member.has_antag_datum(/datum/antagonist/brother), "Член команды получил датум")

/// Мидраунд берёт двоих в сознании без майндшилда
/datum/unit_test/blood_brothers_midround_ruleset

/datum/unit_test/blood_brothers_midround_ruleset/Run()
	var/datum/dynamic_ruleset/midround/crew_conversion/blood_brothers/rule = allocate(/datum/dynamic_ruleset/midround/crew_conversion/blood_brothers)
	rule.mode = allocate(/datum/game_mode/dynamic)
	var/datum/mind/first = allocate_brother_mind(src)
	var/datum/mind/second = allocate_brother_mind(src)
	var/datum/mind/shielded = allocate_brother_mind(src)
	ADD_TRAIT(shielded.current, TRAIT_MINDSHIELD, "test")
	TEST_ASSERT(!rule.can_convert(shielded.current), "Майндшилд не пробуждается")
	first.current.mock_client = new /datum/client_interface()
	second.current.mock_client = new /datum/client_interface()
	rule.living_players = list(first.current, second.current)
	var/executed = rule.execute()
	first.current.mock_client = null
	second.current.mock_client = null
	TEST_ASSERT(executed, "Пробуждение выполнено")
	var/datum/antagonist/brother/first_brother = first.has_antag_datum(/datum/antagonist/brother)
	var/datum/antagonist/brother/second_brother = second.has_antag_datum(/datum/antagonist/brother)
	TEST_ASSERT_NOTNULL(first_brother, "Первый стал братом")
	TEST_ASSERT_NOTNULL(second_brother, "Второй стал братом")
	allocated += first_brother.team
	TEST_ASSERT_EQUAL(first_brother.team, second_brother.team, "Оба в одной команде")
	TEST_ASSERT(first in rule.assigned, "Директор видит выданную роль")

/// Хелпер различает антагов по белому списку: мягкий флаг не спасает, своё братство и валентинки не в счёт
/datum/unit_test/blood_brothers_antagonist_check

/datum/unit_test/blood_brothers_antagonist_check/Run()
	var/datum/mind/crew = allocate_brother_mind(src)
	TEST_ASSERT(!brother_mind_is_antagonist(crew), "Экипаж не антаг")
	var/datum/antagonist/custom/soft_role = new
	soft_role.silent = TRUE
	crew.add_antag_datum(soft_role)
	TEST_ASSERT(brother_mind_is_antagonist(crew), "Мягкая роль - тоже антаг")
	var/datum/mind/ghoul = allocate_brother_mind(src)
	var/datum/antagonist/heretic_monster/ghoul/ghoul_datum = new
	ghoul_datum.silent = TRUE
	ghoul.add_antag_datum(ghoul_datum)
	var/ghoul_is_antagonist = brother_mind_is_antagonist(ghoul)
	ghoul.remove_antag_datum(/datum/antagonist/heretic_monster/ghoul)
	TEST_ASSERT(ghoul_is_antagonist, "Гуль еретика - антаг")
	var/datum/team/brother_team/own = allocate_brother_team(src)
	var/datum/team/brother_team/other = allocate_brother_team(src)
	var/datum/mind/own_member = own.members[1]
	TEST_ASSERT(!brother_mind_is_antagonist(own_member, own), "Своё братство не в счёт")
	TEST_ASSERT(brother_mind_is_antagonist(own_member, other), "Чужой брат - антаг")
	var/datum/mind/traitor = allocate_brother_mind(src)
	var/datum/antagonist/traitor/traitor_datum = new
	traitor_datum.silent = TRUE
	traitor_datum.give_objectives = FALSE
	traitor_datum.should_equip = FALSE
	traitor.add_antag_datum(traitor_datum)
	var/is_antagonist = brother_mind_is_antagonist(traitor)
	traitor.remove_antag_datum(/datum/antagonist/traitor)
	crew.remove_antag_datum(/datum/antagonist/custom)
	TEST_ASSERT(is_antagonist, "Предатель - антаг")
	var/datum/mind/sweetheart = allocate_brother_mind(src)
	var/datum/antagonist/valentine/valentine_datum = new
	valentine_datum.silent = TRUE
	valentine_datum.date = allocate_brother_mind(src)
	sweetheart.add_antag_datum(valentine_datum)
	var/valentine_is_antagonist = brother_mind_is_antagonist(sweetheart)
	sweetheart.remove_antag_datum(/datum/antagonist/valentine)
	TEST_ASSERT(!valentine_is_antagonist, "Валентинка - не антаг")

/// Кнопки, алерты, эффекты и HUD братьев берут свои состояния из своих DMI
/datum/unit_test/blood_brothers_icons_exist

/datum/unit_test/blood_brothers_icons_exist/Run()
	var/actions_file = 'modular_bluemoon/icons/mob/blood_brothers/actions.dmi'
	var/list/action_states = icon_states(actions_file)
	var/list/effect_states = icon_states('modular_bluemoon/icons/effects/blood_brothers.dmi')
	TEST_ASSERT("bg_blood_bond" in action_states, "Нет фона кнопок")
	for(var/datum/action/cooldown/blood_bond/action_type as anything in subtypesof(/datum/action/cooldown/blood_bond))
		TEST_ASSERT_EQUAL("[initial(action_type.icon_icon)]", "[actions_file]", "[action_type]: значок не из набора братьев")
		TEST_ASSERT_EQUAL("[initial(action_type.button_icon)]", "[actions_file]", "[action_type]: фон не из набора братьев")
		TEST_ASSERT_EQUAL(initial(action_type.background_icon_state), "bg_blood_bond", "[action_type]: чужой фон кнопки")
		var/state = initial(action_type.button_icon_state)
		if(state)
			TEST_ASSERT(state in action_states, "[action_type]: нет состояния [state]")
		var/beam_state = initial(action_type.beam_state)
		if(beam_state)
			TEST_ASSERT(beam_state in effect_states, "[action_type]: нет луча [beam_state]")
	var/alerts_file = 'modular_bluemoon/icons/mob/blood_brothers/alerts.dmi'
	var/list/alert_states = icon_states(alerts_file)
	for(var/atom/movable/screen/alert/alert_type as anything in list(/atom/movable/screen/alert/status_effect/brother_sense, /atom/movable/screen/alert/status_effect/brother_fury, /atom/movable/screen/alert/brother_fallen))
		TEST_ASSERT_EQUAL("[initial(alert_type.icon)]", "[alerts_file]", "[alert_type]: алерт не из набора братьев")
		TEST_ASSERT(initial(alert_type.icon_state) in alert_states, "[alert_type]: нет состояния [initial(alert_type.icon_state)]")
	for(var/state in list("muted", "sense_direct", "sense_close", "sense_medium", "sense_far", "sense_null", "sense_up", "sense_down"))
		TEST_ASSERT(state in alert_states, "Алерты: нет состояния [state]")
	for(var/obj/effect/temp_visual/blood_brothers/visual_type as anything in subtypesof(/obj/effect/temp_visual/blood_brothers))
		TEST_ASSERT(initial(visual_type.icon_state) in effect_states, "[visual_type]: нет состояния [initial(visual_type.icon_state)]")
	for(var/state in list("brother_sign_1", "brother_sign_draw", "seal_flash", "fury_aura"))
		TEST_ASSERT(state in effect_states, "Эффекты: нет состояния [state]")
	var/list/hud_states = icon_states('icons/mob/hud.dmi')
	TEST_ASSERT("blood_brother" in hud_states, "Нет HUD-значка")
	TEST_ASSERT("blood_brother_muted" in hud_states, "Нет HUD-значка заглушённого")

/// Окно получает набор PNG фактуры под теми же именами, что ищет TSX
/datum/unit_test/blood_brothers_ui_assets

/datum/unit_test/blood_brothers_ui_assets/Run()
	var/datum/team/brother_team/team = allocate_brother_team(src)
	var/datum/mind/member = team.members[1]
	var/datum/antagonist/brother/brother = member.has_antag_datum(/datum/antagonist/brother)
	var/list/assets = brother.ui_assets(member.current)
	TEST_ASSERT_EQUAL(length(assets), 1, "Окно передаёт один набор ресурсов")
	var/datum/asset/simple/blood_brothers/window_assets = assets[1]
	TEST_ASSERT(istype(window_assets), "TGUI ожидает экземпляр набора ресурсов")
	var/list/mappings = window_assets.get_url_mappings()
	for(var/filename in list("blood_brothers_cloth.png", "blood_brothers_smear.png", "blood_brothers_seal_empty.png", "blood_brothers_seal_fresh.png", "blood_brothers_seal_smeared.png"))
		var/datum/asset_cache_item/texture = window_assets.assets[filename]
		TEST_ASSERT(istype(texture) && isfile(texture.resource), "[filename] - зарегистрированный ресурс")
		TEST_ASSERT(length(mappings[filename]), "TGUI получает адрес [filename]")

/// Майндшилд: заглушённый не видит братьев в худе, свои видят его заглушённым, весть о глушении и о возврате уходит один раз
/datum/unit_test/blood_brothers_mute_notice

/datum/unit_test/blood_brothers_mute_notice/Run()
	var/datum/team/brother_team/team = allocate_brother_team(src)
	var/datum/mind/shielded = team.members[1]
	var/datum/mind/other = team.members[2]
	var/datum/atom_hud/antag/brother/hud = GLOB.huds[ANTAG_HUD_BROTHER]
	var/pulse = team.bond_pulse
	ADD_TRAIT(shielded.current, TRAIT_MINDSHIELD, "test")
	ADD_TRAIT(shielded.current, TRAIT_MINDSHIELD, "test_second")
	TEST_ASSERT_EQUAL(team.bond_pulse, pulse + 1, "Братьям одна весть о глушении")
	TEST_ASSERT(!hud.should_show_to(shielded.current, other.current), "Заглушённый не видит брата в худе")
	TEST_ASSERT(hud.should_show_to(other.current, shielded.current), "Свои видят заглушённого")
	REMOVE_TRAIT(shielded.current, TRAIT_MINDSHIELD, "test")
	TEST_ASSERT_EQUAL(team.bond_pulse, pulse + 1, "Пока имплант стоит, вестей больше нет")
	REMOVE_TRAIT(shielded.current, TRAIT_MINDSHIELD, "test_second")
	TEST_ASSERT_EQUAL(team.bond_pulse, pulse + 2, "Снятие глушения - одна весть")
	TEST_ASSERT(hud.should_show_to(shielded.current, other.current), "Без глушения брат снова виден")

/// Тело-силикон глушит связь, как майндшилд
/datum/unit_test/blood_brothers_mute_silicon

/datum/unit_test/blood_brothers_mute_silicon/Run()
	var/datum/team/brother_team/team = allocate_brother_team(src)
	var/datum/mind/borged = team.members[1]
	var/datum/mind/other = team.members[2]
	var/datum/antagonist/brother/borged_brother = borged.has_antag_datum(/datum/antagonist/brother)
	var/datum/atom_hud/antag/brother/hud = GLOB.huds[ANTAG_HUD_BROTHER]
	var/mob/living/silicon/robot/borg = allocate(/mob/living/silicon/robot, run_loc_floor_bottom_left)
	borged.transfer_to(borg)
	TEST_ASSERT_EQUAL(borged.current, borg, "Разум брата в борге")
	TEST_ASSERT(borged_brother.is_muted(), "В теле без крови связь заглушена")
	TEST_ASSERT_EQUAL(borged_brother.brother_state(), BROTHER_STATE_MUTED, "Состояние - заглушён")
	TEST_ASSERT_EQUAL(borged.antag_hud_icon_state, "blood_brother_muted", "HUD - заглушён")
	TEST_ASSERT(!hud.should_show_to(borg, other.current), "Борг не видит брата в худе")
	var/datum/action/cooldown/blood_bond/whisper/whisper = borged_brother.bond_actions[/datum/action/cooldown/blood_bond/whisper]
	TEST_ASSERT(!whisper.IsAvailable(silent = TRUE), "Борг не шепчет")

/// Заглушённый и бессознательный не голосуют, их подписи не ждут; в наручниках голосуют, но не скрепляют; повторное предложение не шумит
/datum/unit_test/blood_brothers_oath_vote_rules

/datum/unit_test/blood_brothers_oath_vote_rules/Run()
	var/datum/team/brother_team/team = allocate_brother_team(src, 3)
	var/datum/mind/first = team.members[1]
	var/datum/mind/second = team.members[2]
	var/datum/mind/shielded = team.members[3]
	var/datum/blood_oath/blood_brothers_capstone_test/offer = new
	team.offered += offer
	ADD_TRAIT(shielded.current, TRAIT_MINDSHIELD, "test")
	TEST_ASSERT(!blood_brothers_window_act(src, shielded, "propose", list("key" = offer.key)), "Заглушённый не предлагает")
	TEST_ASSERT_NULL(team.proposed, "Предложения нет")
	second.current.set_stat(UNCONSCIOUS)
	TEST_ASSERT(!blood_brothers_window_act(src, second, "propose", list("key" = offer.key)), "Без сознания не предлагают")
	second.current.set_stat(CONSCIOUS)
	var/mob/living/carbon/human/first_body = first.current
	first_body.handcuffed = allocate(/obj/item/restraints/handcuffs, first_body)
	first_body.update_handcuffed()
	TEST_ASSERT(blood_brothers_window_act(src, first, "propose", list("key" = offer.key)), "В наручниках голосовать можно")
	var/pulse = team.bond_pulse
	TEST_ASSERT(blood_brothers_window_act(src, first, "propose", list("key" = offer.key)), "Повторное предложение не ошибка")
	TEST_ASSERT_EQUAL(team.bond_pulse, pulse, "Повторное предложение не шлёт вестей")
	TEST_ASSERT_NULL(team.oath, "Ждём подписи второго")
	TEST_ASSERT(!blood_brothers_window_act(src, shielded, "sign", list()), "Заглушённый не подписывает")
	TEST_ASSERT(blood_brothers_window_act(src, second, "sign", list()), "Второй подписал")
	TEST_ASSERT_EQUAL(team.oath, offer, "Заглушённого не ждут")
	TEST_ASSERT(findtext(team.seal_refusal(first), "наручник"), "В наручниках печать не поставить: [team.seal_refusal(first)]")
	first_body.uncuff()
	second.current.set_stat(UNCONSCIOUS)
	TEST_ASSERT(findtext(team.seal_refusal(second), "сознани"), "Без сознания печать не поставить: [team.seal_refusal(second)]")
	second.current.set_stat(CONSCIOUS)

/// ui_act окна брата member через открытое им окно
/proc/blood_brothers_window_act(datum/unit_test/test, datum/mind/member, action, list/params)
	var/datum/antagonist/brother/brother = member.has_antag_datum(/datum/antagonist/brother)
	var/datum/tgui/window = test.allocate(/datum/tgui, member.current, brother, "AntagInfoBloodBrother")
	window.status = UI_INTERACTIVE
	return brother.ui_act(action, params, window)

/// Разорванного не зовёт другая команда и не берёт мидраунд; тип разрыва запомнен
/datum/unit_test/blood_brothers_severed_global

/datum/unit_test/blood_brothers_severed_global/Run()
	var/datum/team/brother_team/first_team = allocate_brother_team(src)
	var/datum/team/brother_team/second_team = allocate_brother_team(src)
	var/datum/mind/severed = first_team.members[1]
	first_team.sever(severed, "тест", BROTHER_SEVER_RITE)
	TEST_ASSERT_EQUAL(first_team.severed_kinds[severed], BROTHER_SEVER_RITE, "Тип разрыва запомнен")
	TEST_ASSERT(istext(second_team.recruit_role_ok(severed)), "Чужая команда не зовёт разорванного")
	var/datum/dynamic_ruleset/midround/crew_conversion/blood_brothers/rule = allocate(/datum/dynamic_ruleset/midround/crew_conversion/blood_brothers)
	TEST_ASSERT(!rule.can_convert(severed.current), "Мидраунд не будит разорванного")
	var/datum/mind/crew = allocate_brother_mind(src)
	TEST_ASSERT(rule.can_convert(crew.current), "Мидраунд будит обычный экипаж")

/datum/blood_oath/blood_brothers_admin_test
	name = "Проверка смены"
	key = "admin_test"
	var/prepares_left = 1

/datum/blood_oath/blood_brothers_admin_test/prepare(datum/team/brother_team/for_team)
	. = ..()
	if(prepares_left-- <= 0)
		return FALSE

/datum/blood_oath/blood_brothers_admin_test/revalidate()
	return FALSE

/// Админ-команды: шаг переключается со ступенью, без венца Схрон высыпается, смена клятвы держит старую при отказе и сохраняет обет, снятие роли рвёт клятву, слоты открывают замену
/datum/unit_test/blood_brothers_admin_commands

/datum/unit_test/blood_brothers_admin_commands/Run()
	var/mob/living/carbon/human/admin = allocate(/mob/living/carbon/human)
	var/datum/team/brother_team/team = allocate_brother_team(src, 3)
	var/datum/mind/first = team.members[1]
	var/datum/mind/third = team.members[3]
	var/datum/antagonist/brother/brother = first.has_antag_datum(/datum/antagonist/brother)
	var/datum/blood_oath/blood_brothers_capstone_test/oath = new
	oath.capstone_type = /datum/action/cooldown/blood_bond/capstone/stash
	for(var/step_number in 1 to BLOOD_BOND_TIER_MAX)
		oath.add_step(new /datum/blood_oath_step)
	team.swear_oath(oath)
	for(var/step_index in 1 to BLOOD_BOND_TIER_MAX)
		TEST_ASSERT(brother.admin_flip_step(admin, step_index), "Шаг [step_index] скреплён")
	TEST_ASSERT_EQUAL(team.bond_tier, BLOOD_BOND_TIER_MAX, "Ступень - по числу печатей")
	TEST_ASSERT(team.has_stash_capstone(), "Венец Схрона выдан")
	team.open_stash(first.current)
	var/obj/item/pen/stashed = allocate(/obj/item/pen)
	stashed.forceMove(team.stash)
	TEST_ASSERT(brother.admin_flip_step(admin, BLOOD_BOND_TIER_MAX), "Третья печать снята")
	var/datum/blood_oath_step/last_step = oath.steps[BLOOD_BOND_TIER_MAX]
	TEST_ASSERT(!last_step.sealed, "Шаг снова не скреплён")
	TEST_ASSERT_EQUAL(team.bond_tier, BLOOD_BOND_TIER_MAX - 1, "Ступень опустилась")
	TEST_ASSERT_NULL(team.stash, "Без венца Схрон высыпан")
	TEST_ASSERT_EQUAL(get_turf(stashed), get_turf(first.current), "Вещь легла под ноги открывавшему")
	TEST_ASSERT(!brother.admin_apply_oath(admin, /datum/blood_oath/blood_brothers_admin_test), "Клятва без целей при подписи не принята")
	TEST_ASSERT_EQUAL(team.oath, oath, "Прежняя клятва осталась")
	TEST_ASSERT(!QDELETED(oath), "Прежняя клятва цела")
	var/datum/blood_vow/kept_vow = team.vow
	kept_vow.break_vow("проверка")
	TEST_ASSERT(brother.admin_apply_oath(admin, /datum/blood_oath/blood_brothers_capstone_test), "Новая клятва принята")
	TEST_ASSERT_NOTEQUAL(team.oath, oath, "Клятва сменилась")
	TEST_ASSERT_EQUAL(team.vow, kept_vow, "Обет пережил смену клятвы")
	TEST_ASSERT(kept_vow.broken && !QDELETED(kept_vow), "Нарушенный обет остался нарушенным")
	TEST_ASSERT(QDELETED(oath), "Прежняя клятва снята после принятия новой")
	var/datum/antagonist/brother/third_brother = third.has_antag_datum(/datum/antagonist/brother)
	team.replacement_used = TRUE
	third_brother.admin_remove(admin)
	TEST_ASSERT_NULL(third.has_antag_datum(/datum/antagonist/brother), "Снятие роли снимает датум")
	TEST_ASSERT(third in team.severed_minds, "Снятие роли рвёт клятву")
	TEST_ASSERT_EQUAL(team.severed_kinds[third], BROTHER_SEVER_ADMIN, "Разрыв помечен как админский")
	TEST_ASSERT(!team.replacement_available, "Потраченная замена не открылась")
	brother.admin_restore_slots(admin)
	TEST_ASSERT(team.replacement_available, "Вернуть слоты - замена открыта, раз есть ушедший")
	TEST_ASSERT(!team.third_oath_used && !team.replacement_used, "Слоты вернулись")

/// Основатель видит общую предысторию; принятый позже - чью клятву он принял, без ушедших и чужой предыстории
/datum/unit_test/blood_brothers_greeting

/datum/unit_test/blood_brothers_greeting/Run()
	var/datum/team/brother_team/team = allocate_brother_team(src)
	var/datum/mind/founder = team.members[1]
	var/datum/mind/leaver = team.members[2]
	var/datum/antagonist/brother/founder_brother = founder.has_antag_datum(/datum/antagonist/brother)
	var/list/founder_lines = founder_brother.greeting_lines()
	var/founder_text = founder_lines.Join("<br>")
	TEST_ASSERT(findtext(founder_text, team.backstory), "Основатель видит предысторию")
	TEST_ASSERT(findtext(founder_text, leaver.name), "Основатель видит брата")
	TEST_ASSERT(findtext(founder_text, "«Кровная клятва»"), "Окно названо по-новому")
	team.started = TRUE
	leaver.current.moveToNullspace()
	team.check_departures()
	var/datum/mind/recruit = allocate_brother_mind(src)
	TEST_ASSERT(team.recruit(recruit), "Новый брат принят")
	var/datum/antagonist/brother/recruit_brother = recruit.has_antag_datum(/datum/antagonist/brother)
	var/list/recruit_lines = recruit_brother.greeting_lines()
	var/recruit_text = recruit_lines.Join("<br>")
	TEST_ASSERT(findtext(recruit_text, "Вы приняли клятву брата [founder.name]"), "Принятый видит, чью клятву принял: [recruit_text]")
	TEST_ASSERT(!findtext(recruit_text, leaver.name), "Ушедший в приветствии не назван")
	TEST_ASSERT(!findtext(recruit_text, team.backstory), "Чужая предыстория не своя")

/// Миграция сейва включает братьев тем, у кого включена другая антаг-роль, и не трогает остальных.
/datum/unit_test/blood_brothers_savefile_migration_enables_role

/datum/unit_test/blood_brothers_savefile_migration_enables_role/Run()
	var/datum/preferences/antag_player = new
	antag_player.be_special = list(ROLE_TRAITOR = ANTAG_PRIORITY_LOW)
	antag_player.update_preferences(85, null)
	TEST_ASSERT_EQUAL(antag_player.be_special[ROLE_BROTHER], ANTAG_PRIORITY_HIGH, "enabled for an antag player")
	TEST_ASSERT_EQUAL(antag_player.be_special[ROLE_TRAITOR], ANTAG_PRIORITY_LOW, "other roles untouched")

	var/datum/preferences/low_brother_player = new
	low_brother_player.be_special = list(ROLE_BROTHER = ANTAG_PRIORITY_LOW)
	low_brother_player.update_preferences(85, null)
	TEST_ASSERT_EQUAL(low_brother_player.be_special[ROLE_BROTHER], ANTAG_PRIORITY_LOW, "chosen priority kept")

	var/datum/preferences/no_antag_player = new
	no_antag_player.be_special = list(ROLE_TRAITOR = ANTAG_PRIORITY_HIGH)
	no_antag_player.toggles |= NO_ANTAG
	no_antag_player.update_preferences(85, null)
	TEST_ASSERT(!(ROLE_BROTHER in no_antag_player.be_special), "NO_ANTAG player untouched")

	var/datum/preferences/empty_player = new
	empty_player.be_special = list()
	empty_player.update_preferences(85, null)
	TEST_ASSERT(!(ROLE_BROTHER in empty_player.be_special), "player without antag roles untouched")

	var/datum/preferences/opted_out_player = new
	opted_out_player.be_special = list(ROLE_TRAITOR = ANTAG_PRIORITY_HIGH)
	opted_out_player.update_preferences(86, null)
	TEST_ASSERT(!(ROLE_BROTHER in opted_out_player.be_special), "already migrated save untouched")

	qdel(antag_player)
	qdel(low_brother_player)
	qdel(no_antag_player)
	qdel(empty_player)
	qdel(opted_out_player)
