/// Подпись объявлений культа раунда: размер культа и призыв.
#define ANTAG_TRAINING_CULT_NEWS list("Отдел Работы с Реальностью")

/datum/unit_test/proc/antag_training_cult_dummies_near(atom/center, mob/living/except)
	. = list()
	for(var/mob/living/carbon/human/helper in range(1, center))
		var/datum/antagonist/cult/training/cultist = helper.mind?.has_antag_datum(/datum/antagonist/cult/training)
		if(helper != except && cultist?.practice_dummy)
			. += helper

/// Программа выдаёт учебного культиста с учебным кинжалом и металлом в учебном культе вне команд и списков раунда; «Рунный металл» возвращает потерянный кинжал, «Заряды крови» пополняют заклинания и кровь.
/datum/unit_test/antag_training_cult_setup/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/antag/cult)
	TEST_ASSERT(session.prepare(), "Полигон готовит культиста.")
	var/datum/antag_training_program/antag/cult/program = session.program
	var/mob/living/carbon/human/body = session.current_body
	var/datum/antagonist/cult/training/cultist = program.role(session)
	TEST_ASSERT(istype(cultist), "Кукла получает учебного культиста.")
	var/datum/team/cult/training/team = cultist.cult_team
	TEST_ASSERT(istype(team) && (body.mind in team.members), "Культист в учебном культе.")
	TEST_ASSERT(!(team in GLOB.antagonist_teams), "Учебный культ не в списке команд раунда.")
	TEST_ASSERT(!(body.mind in SSticker.mode.cult), "Учебный культист не в списке культа режима.")
	TEST_ASSERT_NULL(locate(/datum/objective/sacrifice) in team.objectives, "У учебного культа нет цели-члена экипажа.")
	var/datum/action/innate/cult/mastervote/vote = cultist.vote
	TEST_ASSERT(!(vote in body.actions), "Выборов главы культа на полигоне нет.")
	var/obj/item/melee/cultblade/dagger/training/dagger = locate() in body.GetAllContents()
	TEST_ASSERT_NOTNULL(dagger, "Учебный кинжал у культиста.")
	TEST_ASSERT_NOTNULL(locate(/obj/item/stack/sheet/runed_metal) in body.GetAllContents(), "Рунный металл у культиста.")
	var/list/data = session.ui_data(body)
	for(var/option in program.options)
		TEST_ASSERT(length(data["option_hints"][option]), "У кнопки «[option]» есть подсказка.")

	var/datum/tgui/console = allocate(/datum/tgui, body, session, "AntagTraining")
	qdel(dagger)
	session.next_supply_at = 0
	antag_training_console_act(session, console, "program_option", list("option" = "Рунный металл"))
	var/obj/item/melee/cultblade/dagger/training/replacement = locate() in body.GetAllContents()
	TEST_ASSERT(replacement && replacement != dagger, "Потерянный учебный кинжал выдаётся заново.")

	var/datum/action/innate/cult/blood_spell/manipulation/rites = new(body)
	rites.Grant(body, cultist.magic)
	cultist.magic.spells += rites
	rites.charges = 0
	body.blood_volume = BLOOD_VOLUME_BAD
	antag_training_console_act(session, console, "program_option", list("option" = "Заряды крови"))
	TEST_ASSERT(rites.charges > initial(rites.charges), "«Заряды крови» наполняют Blood Rites сверх начальных зарядов.")
	TEST_ASSERT(body.blood_volume >= BLOOD_VOLUME_NORMAL * body.blood_ratio, "«Заряды крови» восполняют кровь.")

	qdel(session)
	TEST_ASSERT(wait_for_qdeleted(cultist, 1 MINUTES), "Выход снимает роль культиста.")
	TEST_ASSERT(QDELETED(team), "Учебный культ без участников снимается.")

/// Учебный и настоящий культы не смешиваются: культист раунда не вступает в учебный культ, обращённый и подчинённый на полигоне - не в настоящий, учебных рун нет в каталоге настоящего кинжала, жертва не трогает GLOB.sacrificed и не делает камня, причастие не переходит между полигоном и станцией, настоящий кинжал и проклятия на полигоне не работают.
/datum/unit_test/antag_training_cult_isolation
	var/list/added_players = list()
	var/list/saved_rune_types
	var/datum/mind/station_mind
	var/datum/team/cult/station_team

/datum/unit_test/antag_training_cult_isolation/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/antag/cult)
	TEST_ASSERT(session.prepare(), "Полигон готовит культиста.")
	var/datum/antag_training_session/convert_session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(convert_session.prepare(), "Второй участник входит на тот же полигон.")
	var/datum/antag_training_arena/arena = session.arena
	TEST_ASSERT_EQUAL(convert_session.arena, arena, "Участники на одном полигоне.")
	var/datum/antag_training_sector/station = arena.sectors["station"]
	TEST_ASSERT(wait_for_var(station, "state", ANTAG_TRAINING_SECTOR_READY, 30 SECONDS), "Станционный макет загружается.")
	var/datum/antag_training_program/antag/cult/program = session.program
	var/mob/living/carbon/human/body = session.current_body
	var/mob/living/carbon/human/convertee = convert_session.current_body
	var/datum/antagonist/cult/training/cultist = program.role(session)
	var/datum/team/cult/training/team = cultist.cult_team
	var/datum/tgui/console = allocate(/datum/tgui, body, session, "AntagTraining")

	var/mob/living/carbon/human/crew = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	crew.mind_initialize()
	allocated += crew.mind
	var/datum/antagonist/cult/station_cultist = new
	station_cultist.ignore_eligibility_checks = TRUE
	TEST_ASSERT(crew.mind.add_antag_datum(station_cultist), "Культист раунда выдан.")
	var/datum/team/cult/round_team = station_cultist.cult_team
	station_mind = crew.mind
	station_team = round_team
	allocated += round_team
	TEST_ASSERT(round_team && round_team != team && !(crew.mind in team.members), "Культист раунда без команды не вступает в учебный культ.")
	var/round_teams = length(GLOB.antagonist_teams)
	var/sacrificed_before = length(GLOB.sacrificed)

	var/turf/altar = station.spawn_turf()
	body.forceMove(altar)
	var/obj/item/melee/cultblade/dagger/training/dagger = locate() in body.GetAllContents()
	var/obj/effect/rune/convert/training/offer = dagger.scribe(body, /obj/effect/rune/convert/training)
	TEST_ASSERT(istype(offer) && get_turf(offer) == altar, "Учебный кинжал чертит руну Offer в макете.")
	convertee.forceMove(altar)
	antag_training_console_act(session, console, "program_option", list("option" = "Культисты для призыва"))
	var/list/helpers = antag_training_cult_dummies_near(offer, body)
	TEST_ASSERT_EQUAL(length(helpers), 2, "Вокруг культиста встают два учебных культиста.")
	offer.attack_hand(body)
	TEST_ASSERT(wait_for_var(offer, "rune_in_use", FALSE, 5 SECONDS), "Руна дочитана.")
	var/datum/antagonist/cult/converted = convertee.mind.has_antag_datum(/datum/antagonist/cult)
	TEST_ASSERT(istype(converted, /datum/antagonist/cult/training), "Offer обращает участника в учебного культиста.")
	TEST_ASSERT((convertee.mind in team.members) && !(convertee.mind in round_team.members), "Обращённый на полигоне - в учебном культе, не в настоящем.")
	TEST_ASSERT(!(convertee.mind in SSticker.mode.cult), "Обращённый не в списке культа режима.")
	TEST_ASSERT_EQUAL(length(GLOB.antagonist_teams), round_teams, "Обращение не создаёт команд раунда.")
	TEST_ASSERT_NOTNULL(locate(/obj/item/melee/cultblade/dagger/training) in altar, "Обращённый получает учебный кинжал.")
	for(var/obj/item/melee/cultblade/dagger/gift in altar)
		TEST_ASSERT(istype(gift, /obj/item/melee/cultblade/dagger/training), "Обращённому не выдаётся настоящий кинжал.")

	antag_training_console_act(session, console, "program_option", list("option" = "Цель для жертвы"))
	var/mob/living/carbon/human/victim = arena.targets[length(arena.targets)]
	TEST_ASSERT(!victim.client && !victim.mind.has_antag_datum(/datum/antagonist/cult), "Цель для жертвы - манекен без игрока.")
	victim.death()
	victim.forceMove(altar)
	offer.attack_hand(body)
	TEST_ASSERT(wait_for_var(team, "sacrifices", 1, 5 SECONDS), "Мёртвая цель на руне Offer приносится в жертву учебному культу.")
	TEST_ASSERT(HAS_TRAIT(victim, TRAIT_SACRIFICED), "Жертва помечена.")
	TEST_ASSERT_EQUAL(length(GLOB.sacrificed), sacrificed_before, "Учебная жертва не меняет GLOB.sacrificed.")
	TEST_ASSERT_NULL(locate(/obj/item/soulstone) in altar, "Учебная жертва не делает камня душ.")

	antag_training_console_act(session, console, "program_option", list("option" = "Цель для жертвы"))
	var/mob/living/carbon/human/soulless = arena.targets[length(arena.targets)]
	soulless.death()
	var/obj/item/soulstone/stone = new(get_turf(body))
	GLOB.unit_test_chat_capture = list()
	stone.attack(soulless, body)
	TEST_ASSERT(antag_training_heard(body, "камень душ зовёт") && !length(stone.contents), "Камень душ на полигоне не зовёт призраков в тень.")

	antag_training_console_act(session, console, "program_option", list("option" = "Цель для жертвы"))
	var/mob/living/carbon/human/servant = arena.targets[length(arena.targets)]
	servant.mind.enslave_mind_to_creator(body)
	var/datum/antagonist/cult/bound = servant.mind.has_antag_datum(/datum/antagonist/cult)
	TEST_ASSERT(istype(bound, /datum/antagonist/cult/training), "Подчинённый культистом на полигоне становится учебным культистом.")
	TEST_ASSERT(!(servant.mind in round_team.members) && (servant.mind in team.members), "Подчинённый на полигоне вступает в учебный культ, не в настоящий.")

	saved_rune_types = GLOB.rune_types
	GLOB.rune_types = null
	allocate(/obj/item/melee/cultblade/dagger, run_loc_floor_bottom_left)
	TEST_ASSERT(length(GLOB.rune_types), "Настоящий кинжал собирает каталог рун.")
	for(var/rune_name in GLOB.rune_types)
		var/obj/effect/rune/rune_type = GLOB.rune_types[rune_name]
		TEST_ASSERT(!initial(rune_type.antag_training_rune), "В каталоге настоящего кинжала нет учебной руны [rune_type].")
	TEST_ASSERT_EQUAL(GLOB.rune_types["Nar'Sie"], /obj/effect/rune/narsie, "Руна Нар'Си настоящего кинжала - настоящая.")
	TEST_ASSERT_EQUAL(GLOB.rune_types["Offer"], /obj/effect/rune/convert, "Руна Offer настоящего кинжала - настоящая.")

	GLOB.unit_test_chat_capture = list()
	var/turf/clear_floor = station.target_turf()
	body.forceMove(clear_floor)
	var/obj/item/melee/cultblade/dagger/round_dagger = new(clear_floor)
	round_dagger.attack_self(body)
	TEST_ASSERT(antag_training_heard(body, "только учебный ритуальный кинжал"), "Настоящий кинжал на полигоне рун не чертит.")
	TEST_ASSERT_NULL(locate(/obj/effect/rune) in clear_floor, "Настоящий кинжал ничего не начертил.")
	var/obj/item/shuttle_curse/shuttle_curse = new(clear_floor)
	shuttle_curse.attack_self(body)
	TEST_ASSERT(!QDELETED(shuttle_curse) && antag_training_heard(body, "эвакуационный шаттл"), "Проклятие шаттла на полигоне недоступно.")
	var/obj/item/station_curse/station_curse = new(clear_floor)
	station_curse.attack_self(body)
	TEST_ASSERT(!QDELETED(station_curse) && antag_training_heard(body, "бурю порталов"), "Проклятие станции на полигоне недоступно.")
	var/obj/item/flashlight/flare/culttorch/torch = new(clear_floor)
	torch.afterattack(round_dagger, body, TRUE)
	TEST_ASSERT(torch.charges == initial(torch.charges) && antag_training_heard(body, "факел передаёт"), "Факел пустоты на полигоне недоступен.")
	body.forceMove(arena.entry_turf)
	TEST_ASSERT_NULL(dagger.scribe(body, /obj/effect/rune/empower), "В безопасном центре руны не чертятся.")
	TEST_ASSERT(antag_training_heard(body, "безопасном центре"), "Отказ называет безопасный центр.")

	added_players = list(body, convertee, crew) - GLOB.player_list
	GLOB.player_list += added_players
	GLOB.unit_test_chat_capture = list()
	station_cultist.communion.cultist_commune(crew, "cult-station-probe")
	cultist.communion.cultist_commune(body, "cult-arena-probe")
	TEST_ASSERT(antag_training_heard(convertee, "cult-arena-probe"), "Обращённый слышит причастие своего полигона.")
	TEST_ASSERT(!antag_training_heard(crew, "cult-arena-probe"), "Культист станции не слышит учебное причастие.")
	TEST_ASSERT(antag_training_heard(crew, "cult-station-probe"), "Культист станции слышит причастие станции.")
	TEST_ASSERT(!antag_training_heard(body, "cult-station-probe") && !antag_training_heard(convertee, "cult-station-probe"), "Учебные культисты не слышат причастие станции.")

/datum/unit_test/antag_training_cult_isolation/Destroy()
	station_mind?.remove_antag_datum(/datum/antagonist/cult)
	for(var/datum/objective/objective as anything in GLOB.objectives.Copy())
		if(station_team && objective.team == station_team)
			qdel(objective)
	station_mind = null
	station_team = null
	GLOB.unit_test_chat_capture = null
	GLOB.player_list -= added_players
	added_players.Cut()
	if(saved_rune_types)
		GLOB.rune_types = saved_rune_types
	return ..()

/// Руна Нар'Си чертится только после жертвы и только в ритуальном зале макета, без объявления; призыв с учебными культистами - эффект и сообщение пульта без сингулярности, объявлений, тревоги и блока шаттла; Revive и Teleport работают в пределах полигона.
/datum/unit_test/antag_training_cult_summon/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/antag/cult)
	TEST_ASSERT(session.prepare(), "Полигон готовит культиста.")
	var/datum/antag_training_sector/station = session.arena.sectors["station"]
	TEST_ASSERT(wait_for_var(station, "state", ANTAG_TRAINING_SECTOR_READY, 30 SECONDS), "Станционный макет загружается.")
	var/datum/antag_training_program/antag/cult/program = session.program
	var/mob/living/carbon/human/body = session.current_body
	var/datum/antagonist/cult/training/cultist = program.role(session)
	var/datum/team/cult/training/team = cultist.cult_team
	var/datum/tgui/console = allocate(/datum/tgui, body, session, "AntagTraining")
	var/obj/item/melee/cultblade/dagger/training/dagger = locate() in body.GetAllContents()
	var/turf/hall = station.landmark_turf("ritual")
	var/turf/altar = station.spawn_turf()
	var/turf/corridor = station.target_turf()
	GLOB.unit_test_chat_capture = list()
	GLOB.unit_test_admin_messages = list()
	var/news_before = antag_training_news_count(ANTAG_TRAINING_CULT_NEWS)
	var/security_before = GLOB.security_level
	var/hostile_before = length(SSshuttle.hostileEnvironments)

	body.forceMove(hall)
	var/atom/movable/screen/alert/bloodsense/sense = body.alerts["bloodsense"]
	TEST_ASSERT_NOTNULL(sense, "У культиста есть кровавое чутьё.")
	sense.process()
	TEST_ASSERT(findtext(sense.desc, "ритуальный зал"), "Кровавое чутьё называет ритуальный зал, а не область макета.")
	TEST_ASSERT_NULL(dagger.scribe(body, /obj/effect/rune/narsie/training), "Без жертвы руна Нар'Си не чертится.")
	TEST_ASSERT(antag_training_heard(body, "Сначала принесите учебную жертву"), "Отказ объясняет, что нужна жертва.")

	body.forceMove(altar)
	var/obj/effect/rune/convert/training/offer = dagger.scribe(body, /obj/effect/rune/convert/training)
	antag_training_console_act(session, console, "program_option", list("option" = "Цель для жертвы"))
	var/mob/living/carbon/human/victim = session.arena.targets[length(session.arena.targets)]
	victim.death()
	victim.forceMove(altar)
	offer.attack_hand(body)
	TEST_ASSERT(wait_for_var(team, "sacrifices", 1, 5 SECONDS), "Жертва принесена.")

	body.forceMove(corridor)
	TEST_ASSERT_NULL(dagger.scribe(body, /obj/effect/rune/narsie/training), "Вне ритуального зала руна Нар'Си не чертится.")
	TEST_ASSERT(antag_training_heard(body, "ритуальном зале"), "Отказ называет ритуальный зал.")

	body.forceMove(hall)
	var/obj/effect/rune/narsie/training/narsie_rune = dagger.scribe(body, /obj/effect/rune/narsie/training)
	TEST_ASSERT(istype(narsie_rune) && get_turf(narsie_rune) == hall, "Руна Нар'Си чертится в ритуальном зале.")
	TEST_ASSERT(!(narsie_rune in GLOB.poi_list), "Учебной руны нет среди мест для призраков.")
	TEST_ASSERT_EQUAL(antag_training_news_count(ANTAG_TRAINING_CULT_NEWS), news_before, "Начертание учебной руны не объявляют станции.")

	narsie_rune.attack_hand(body)
	TEST_ASSERT(!team.summon_objective.completed && !QDELETED(narsie_rune), "Одного культиста для призыва мало.")
	antag_training_console_act(session, console, "program_option", list("option" = "Культисты для призыва"))
	TEST_ASSERT_EQUAL(length(antag_training_cult_dummies_near(narsie_rune, body)), 2, "Учебные культисты встают у руны Нар'Си.")
	narsie_rune.attack_hand(body)
	TEST_ASSERT(wait_for_var(team.summon_objective, "completed", TRUE, 5 SECONDS), "Призыв выполняет учебную цель.")
	TEST_ASSERT(wait_for_qdeleted(narsie_rune, 5 SECONDS), "Прочитанная руна исчезает: призыв можно повторить.")
	TEST_ASSERT_NOTNULL(locate(/obj/effect/temp_visual/antag_training_narsie) in hall, "Призыв показывает учебного Нар'Си в зале.")
	TEST_ASSERT(findtext("[session.last_feedback]", "Учебный призыв Нар'Си выполнен"), "Пульт сообщает об учебном призыве.")
	TEST_ASSERT(isnull(GLOB.cult_narsie) && !(locate(/obj/singularity/narsie) in GLOB.poi_list), "Сингулярности Нар'Си нет.")
	TEST_ASSERT_EQUAL(antag_training_news_count(ANTAG_TRAINING_CULT_NEWS), news_before, "Призыв не объявляют станции.")
	TEST_ASSERT_EQUAL(GLOB.security_level, security_before, "Призыв не меняет уровень тревоги.")
	TEST_ASSERT_EQUAL(length(SSshuttle.hostileEnvironments), hostile_before, "Призыв не держит эвакуационный шаттл.")
	TEST_ASSERT(!length(GLOB.unit_test_admin_messages), "Учебный культ не пишет администраторам.")
	TEST_ASSERT(!team.summon_objective.check_completion(), "Раунд учебный призыв не засчитывает.")

	body.forceMove(corridor)
	var/obj/effect/rune/antag_training_revive/revive_rune = dagger.scribe(body, /obj/effect/rune/antag_training_revive)
	TEST_ASSERT(istype(revive_rune), "Учебный кинжал чертит руну Revive.")
	var/list/summoners = antag_training_cult_dummies_near(hall, body)
	var/mob/living/carbon/human/fallen = summoners[1]
	fallen.death()
	fallen.forceMove(corridor)
	revive_rune.attack_hand(body)
	TEST_ASSERT(wait_for_var(fallen, "stat", CONSCIOUS, 5 SECONDS) && team.revives == 1, "Revive поднимает мёртвого учебного культиста без игрока.")
	TEST_ASSERT(isnull(fallen.client) && isnull(fallen.key), "Воскрешённый манекен не отдан призраку.")
	fallen.death()
	revive_rune.attack_hand(body)
	TEST_ASSERT(fallen.stat == DEAD && team.revives == 1, "Второе воскрешение после одной жертвы не проходит.")

	body.forceMove(hall)
	var/obj/effect/rune/teleport/training/hall_gate = dagger.scribe(body, /obj/effect/rune/teleport/training, "alpha")
	var/turf/office = station.landmark_turf("head_office")
	body.forceMove(office)
	var/obj/effect/rune/teleport/training/office_gate = dagger.scribe(body, /obj/effect/rune/teleport/training, "beta")
	TEST_ASSERT(istype(hall_gate) && istype(office_gate) && !(office_gate in GLOB.teleport_runes), "Учебные руны Teleport чертятся и не попадают в список станции.")
	var/obj/item/paper/parcel = new(office)
	office_gate.attack_hand(body)
	TEST_ASSERT(wait_for_var(parcel, "loc", hall, 5 SECONDS) && get_turf(body) == hall, "Teleport переносит участника и вещь к другой руне полигона.")

/datum/unit_test/antag_training_cult_summon/Destroy()
	GLOB.unit_test_chat_capture = null
	GLOB.unit_test_admin_messages = null
	return ..()

/// Учебные культисты полигона не входят в счёт культа раунда: его глаза не загораются и объявления о размере культа нет.
/datum/unit_test/antag_training_cult_round_size
	var/list/added_players = list()
	var/datum/mind/station_mind
	var/datum/team/cult/station_team

/datum/unit_test/antag_training_cult_round_size/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/antag/cult)
	TEST_ASSERT(session.prepare(), "Полигон готовит культиста.")
	var/datum/antag_training_sector/station = session.arena.sectors["station"]
	TEST_ASSERT(wait_for_var(station, "state", ANTAG_TRAINING_SECTOR_READY, 30 SECONDS), "Станционный макет загружается.")
	var/mob/living/carbon/human/body = session.current_body
	body.forceMove(station.spawn_turf())
	var/datum/tgui/console = allocate(/datum/tgui, body, session, "AntagTraining")
	antag_training_console_act(session, console, "program_option", list("option" = "Культисты для призыва"))
	var/list/arena_cultists = antag_training_cult_dummies_near(body, body) + body
	TEST_ASSERT_EQUAL(length(arena_cultists), 3, "На полигоне трое учебных культистов.")

	var/mob/living/carbon/human/crew = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	crew.mind_initialize()
	allocated += crew.mind
	var/datum/antagonist/cult/station_cultist = new
	station_cultist.ignore_eligibility_checks = TRUE
	TEST_ASSERT(crew.mind.add_antag_datum(station_cultist), "Культист раунда выдан.")
	station_mind = crew.mind
	station_team = station_cultist.cult_team
	allocated += station_team
	var/list/players = arena_cultists + crew
	for(var/bystander_index in 1 to 12)
		players += allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	added_players = players - GLOB.player_list
	GLOB.player_list += added_players
	var/news_before = antag_training_news_count(ANTAG_TRAINING_CULT_NEWS)
	station_team.check_size()
	TEST_ASSERT(!station_team.cult_risen && !station_team.cult_ascendent, "Учебные культисты не поднимают культ раунда.")
	TEST_ASSERT_EQUAL(antag_training_news_count(ANTAG_TRAINING_CULT_NEWS), news_before, "Объявления о размере культа нет.")

/datum/unit_test/antag_training_cult_round_size/Destroy()
	station_mind?.remove_antag_datum(/datum/antagonist/cult)
	for(var/datum/objective/objective as anything in GLOB.objectives.Copy())
		if(station_team && objective.team == station_team)
			qdel(objective)
	station_mind = null
	station_team = null
	GLOB.player_list -= added_players
	added_players.Cut()
	return ..()

#undef ANTAG_TRAINING_CULT_NEWS
