/datum/unit_test/proc/antag_training_kit_missing(mob/living/carbon/human/body, outfit_type)
	var/datum/outfit/kit = new outfit_type
	. = list()
	if(kit.uniform && body.w_uniform?.type != kit.uniform)
		. += "uniform"
	if(kit.suit && body.wear_suit?.type != kit.suit)
		. += "suit"
	if(kit.shoes && body.shoes?.type != kit.shoes)
		. += "shoes"
	if(kit.ears && body.ears?.type != kit.ears)
		. += "ears"
	if(kit.id && body.wear_id?.type != kit.id)
		. += "id"
	if(kit.r_hand && !(locate(kit.r_hand) in body.held_items))
		. += "r_hand"
	if(kit.l_hand && !(locate(kit.l_hand) in body.held_items))
		. += "l_hand"
	qdel(kit)

/datum/unit_test/proc/antag_training_crew_option(datum/antag_training_session/session, option)
	var/datum/tgui/ui = allocate(/datum/tgui, session.current_body, session, "AntagTraining")
	session.next_supply_at = 0
	antag_training_console_act(session, ui, "program_option", list("option" = option))

/// Каждая программа набора выдаёт учебную роль в снаряжении и облике спавнера, с учебной командой вне раунда, без целей и с приветствием о том, что корабль не воспроизводится.
/datum/unit_test/antag_training_crews_setup/Run()
	var/list/frequencies = list(
		/datum/antag_training_program/antag/crew/pirate = FREQ_PIRATE,
		/datum/antag_training_program/antag/crew/raider = FREQ_INTEQ,
		/datum/antag_training_program/antag/crew/vox = FREQ_PIRATE,
	)
	var/list/programs = list(
		/datum/antag_training_program/antag/crew/fugitive,
		/datum/antag_training_program/antag/crew/hunter,
		/datum/antag_training_program/antag/crew/pirate,
		/datum/antag_training_program/antag/crew/raider,
		/datum/antag_training_program/antag/crew/vox,
		/datum/antag_training_program/antag/crew/warmonger,
	)
	for(var/program_type in programs)
		var/teams_before = length(GLOB.antagonist_teams)
		var/datum/antag_training_session/session = allocate_training_session(program_type)
		TEST_ASSERT(session.prepare(), "[program_type]: полигон готов.")
		var/datum/antag_training_program/antag/crew/program = session.program
		var/mob/living/carbon/human/body = session.current_body
		var/datum/antagonist/role = program.role(session)
		TEST_ASSERT(istype(role, program.antag_type), "[program_type]: выдан учебный датум роли.")
		TEST_ASSERT(!(role in GLOB.antagonists), "[program_type]: роль не видна сканерам команд раунда.")
		TEST_ASSERT(!length(role.objectives), "[program_type]: у роли нет целей.")
		var/list/missing = antag_training_kit_missing(body, program.kits[program.choice])
		TEST_ASSERT(!length(missing), "[program_type]: на кукле снаряжение спавнера, не хватает: [jointext(missing, ", ")].")
		if(program.species_type)
			TEST_ASSERT_EQUAL(body.dna.species.type, program.species_type, "[program_type]: вид как у спавнера.")
		var/datum/team/team = role.get_team()
		TEST_ASSERT(istype(team, program.team_type) && team == program.team, "[program_type]: команда учебная и принадлежит программе.")
		TEST_ASSERT(!(team in GLOB.antagonist_teams), "[program_type]: учебной команды нет в списке команд раунда.")
		TEST_ASSERT(length(team.members) == 1 && (body.mind in team.members), "[program_type]: в команде только участник.")
		TEST_ASSERT(!length(team.objectives) && isnull(team.roundend_report()), "[program_type]: у команды нет целей и отчёта.")
		TEST_ASSERT_EQUAL(length(GLOB.antagonist_teams), teams_before, "[program_type]: команды раунда не меняются.")
		var/mob/living/carbon/human/outsider = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
		outsider.mind_initialize()
		allocated += outsider.mind
		var/round_type = role.parent_type
		var/datum/antagonist/round_role = outsider.mind.add_antag_datum(round_type)
		var/datum/team/round_team = round_role.get_team()
		TEST_ASSERT(round_team && round_team != team && (round_team in GLOB.antagonist_teams), "[program_type]: роль раунда вне арены собирает свою команду, а не вступает в учебную.")
		TEST_ASSERT(length(team.members) == 1, "[program_type]: в учебную команду никто не вступил.")
		var/list/round_objectives = round_role.objectives | round_team.objectives
		QDEL_LIST(round_objectives)
		outsider.mind.remove_antag_datum(round_type)
		qdel(round_team)
		var/list/data = session.ui_data(body)
		for(var/option in program.options)
			TEST_ASSERT(length(data["option_hints"][option]), "[program_type]: у кнопки «[option]» есть подсказка.")
		if(frequencies[program_type])
			var/obj/item/radio/headset/headset = body.ears
			TEST_ASSERT(istype(headset) && headset.frequency == frequencies[program_type] && headset.freqlock, "[program_type]: гарнитура экипажа закреплена на его частоте.")
			TEST_ASSERT(headset.can_receive(headset.frequency, body.z), "[program_type]: на полигоне гарнитура экипажа принимает свою частоту.")

		GLOB.unit_test_chat_capture = list()
		SEND_SIGNAL(body, COMSIG_MOB_CLIENT_LOGIN, null)
		var/briefed = FALSE
		for(var/list/entry as anything in GLOB.unit_test_chat_capture)
			if(entry[1] != body)
				continue
			TEST_ASSERT(!findtext(entry[2], "boldannounce"), "[program_type]: приветствие раунда не выводится.")
			if(findtext(entry[2], program.missing_text) && findtext(entry[2], program.role_text))
				briefed = TRUE
		GLOB.unit_test_chat_capture = null
		TEST_ASSERT(briefed, "[program_type]: приветствие описывает роль и говорит, что корабль не воспроизводится.")
		qdel(session)
		TEST_ASSERT(wait_for_qdeleted(team, 1 MINUTES), "[program_type]: команда снимается с сессией.")

/datum/unit_test/antag_training_crews_setup/Destroy()
	GLOB.unit_test_chat_capture = null
	return ..()

/// Кнопка снаряжения в пульте перевыдаёт роль в той же команде с новым набором, не копя импланты, вид и стойкость прежнего.
/datum/unit_test/antag_training_crews_kits/Run()
	var/datum/antag_training_session/pirate_session = allocate_training_session(/datum/antag_training_program/antag/crew/pirate)
	TEST_ASSERT(pirate_session.prepare(), "Полигон готовит пирата.")
	var/datum/antag_training_program/antag/crew/pirate/pirate = pirate_session.program
	var/mob/living/carbon/human/body = pirate_session.current_body
	var/datum/antagonist/pirate/training/mate = pirate.role(pirate_session)
	var/datum/team/crew = mate.crew
	antag_training_crew_option(pirate_session, "Снаряжение: Капитан")
	var/datum/antagonist/pirate/training/captain = pirate.role(pirate_session)
	TEST_ASSERT(istype(captain) && captain != mate && captain.crew == crew, "Смена снаряжения перевыдаёт пирата в той же команде.")
	TEST_ASSERT(!length(antag_training_kit_missing(body, /datum/outfit/pirate/space/captain)), "На пирате снаряжение капитана.")
	TEST_ASSERT(istype(body.head, /obj/item/clothing/head/helmet/space/pirate) && !istype(body.head, /obj/item/clothing/head/helmet/space/pirate/bandana), "Шлем капитана вместо банданы.")
	TEST_ASSERT(HAS_TRAIT(body.wear_suit, TRAIT_NODROP) && !HAS_TRAIT(body.wear_id, TRAIT_NODROP), "Как у спавнера, снаряжение пирата не снимается, а карта снимается.")
	TEST_ASSERT_EQUAL(length(body.implants), 1, "Имплант допуска не копится при смене снаряжения.")

	var/datum/antag_training_session/fugitive_session = allocate_training_session(/datum/antag_training_program/antag/crew/fugitive)
	TEST_ASSERT(fugitive_session.prepare(), "Полигон готовит беглеца.")
	body = fugitive_session.current_body
	var/datum/antag_training_program/antag/crew/fugitive/fugitive = fugitive_session.program
	var/mob/dead/observer/observer = allocate(/mob/dead/observer, run_loc_floor_bottom_left)
	observer.real_name = "Crew Observer"
	observer.can_reenter_corpse = FALSE
	TEST_ASSERT(fugitive_session.connect(observer), "Призрак входит в беглеца.")
	TEST_ASSERT(findtext(body.real_name, "NTP #") && body.dna.real_name == body.real_name && fugitive.original_look["real_name"] != body.real_name, "Вход сохраняет номер заключённого вместо имени.")
	var/datum/data/record/crew_waldo = new
	crew_waldo.fields["name"] = "Waldo"
	GLOB.data_core.general_by_name["Waldo"] = crew_waldo
	var/original_gender = body.gender
	var/original_hair = body.hair_style
	antag_training_crew_option(fugitive_session, "Предыстория: Сбойный синтетик")
	var/datum/antagonist/fugitive/training/synth = body.mind.has_antag_datum(/datum/antagonist/fugitive/training)
	TEST_ASSERT_EQUAL(synth?.backstory, "synth", "Беглец получает выбранную предысторию.")
	TEST_ASSERT(istype(body.getorganslot(ORGAN_SLOT_EYES), /obj/item/organ/eyes/robotic/toggled/glow), "Сбойный синтетик получает светящиеся глаза.")
	antag_training_crew_option(fugitive_session, "Предыстория: Уолдо")
	TEST_ASSERT_EQUAL(body.real_name, "Waldo", "Уолдо получает имя Уолдо.")
	antag_training_crew_option(fugitive_session, "Предыстория: Культист Ялп Элора")
	TEST_ASSERT_EQUAL(body.real_name, observer.real_name, "Другая предыстория возвращает имя участника.")
	TEST_ASSERT(GLOB.data_core.general_by_name["Waldo"] == crew_waldo && crew_waldo.fields["name"] == "Waldo", "Запись экипажа с именем Уолдо не переименовывается.")
	GLOB.data_core.general_by_name -= "Waldo"
	qdel(crew_waldo)
	TEST_ASSERT(body.gender == original_gender && body.hair_style == original_hair, "Другая предыстория возвращает пол и причёску куклы.")
	TEST_ASSERT(!istype(body.getorganslot(ORGAN_SLOT_EYES), /obj/item/organ/eyes/robotic), "Другая предыстория возвращает обычные глаза.")

	var/datum/antag_training_session/hunter_session = allocate_training_session(/datum/antag_training_program/antag/crew/hunter)
	TEST_ASSERT(hunter_session.prepare(), "Полигон готовит охотника.")
	body = hunter_session.current_body
	var/original_species = body.dna.species.type
	antag_training_crew_option(hunter_session, "Отряд: Синтетик-охотник за головами")
	TEST_ASSERT(istype(body.dna.species, /datum/species/synth), "Синтетик-охотник получает вид синтетика.")
	var/datum/antagonist/fugitive_hunter/training/hunter = body.mind.has_antag_datum(/datum/antagonist/fugitive_hunter/training)
	TEST_ASSERT_EQUAL(hunter?.hunter_team?.backstory, "bounty hunters", "Команда охотников знает свою предысторию.")
	antag_training_crew_option(hunter_session, "Отряд: Космополиция")
	TEST_ASSERT_EQUAL(body.dna.species.type, original_species, "Другой отряд возвращает вид куклы.")
	TEST_ASSERT(!length(antag_training_kit_missing(body, /datum/outfit/spacepol)), "На охотнике снаряжение космополиции.")

	var/datum/antag_training_session/warmonger_session = allocate_training_session(/datum/antag_training_program/antag/crew/warmonger)
	TEST_ASSERT(warmonger_session.prepare(), "Полигон готовит вармонгера.")
	var/datum/antag_training_program/antag/crew/warmonger/warmonger = warmonger_session.program
	body = warmonger_session.current_body
	var/datum/species/skeleton/space/skeleton_type = warmonger.species_type
	var/warrior_brute = initial(skeleton_type.brutemod) / 2
	TEST_ASSERT(abs(body.dna.species.brutemod - warrior_brute) < 0.01, "Воин крепче обычного скелета, как у спавнера.")
	antag_training_crew_option(warmonger_session, "Снаряжение: Воин")
	TEST_ASSERT(abs(body.dna.species.brutemod - warrior_brute) < 0.01, "Повторная выдача не копит стойкость.")
	antag_training_crew_option(warmonger_session, "Снаряжение: Военачальник")
	TEST_ASSERT(body.dna.check_mutation(/datum/mutation/human/hulk/superhuman) && body.dna.check_mutation(GIGANTISM), "Военачальник получает силу халка и гигантизм.")
	var/warlord_brute = body.dna.species.brutemod
	TEST_ASSERT(warlord_brute < warrior_brute - 0.01, "Сила халка делает военачальника крепче воина.")
	antag_training_crew_option(warmonger_session, "Снаряжение: Военачальник")
	TEST_ASSERT(abs(body.dna.species.brutemod - warlord_brute) < 0.01, "Перевыдача военачальника не ослабляет его.")
	warmonger_session.heal_self()
	TEST_ASSERT(body.dna.check_mutation(GIGANTISM) && HAS_TRAIT(body, TRAIT_GIANT), "Восстановление на полигоне не снимает гигантизм военачальника.")
	antag_training_crew_option(warmonger_session, "Снаряжение: Воин")
	TEST_ASSERT_EQUAL(warmonger.choice, "warrior", "Военачальник становится воином.")
	TEST_ASSERT(!body.dna.check_mutation(/datum/mutation/human/hulk/superhuman) && !body.dna.check_mutation(GIGANTISM) && !HAS_TRAIT_FROM(body, TRAIT_STUNIMMUNE, TRAIT_HULK) && !HAS_TRAIT(body, TRAIT_GIANT), "Воин не сохраняет силу халка и гигантизм.")
	TEST_ASSERT(abs(body.dna.species.brutemod - warrior_brute) < 0.01, "Воин возвращает стойкость воина.")

/// Настоящие беглецы вне арены не вступают в учебную команду и наоборот, а итоги беглецов и охотников раунда не считают учебного беглеца.
/datum/unit_test/antag_training_crews_fugitive_round/Run()
	var/teams_before = length(GLOB.antagonist_teams)
	var/mob/living/carbon/human/first_runner = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	first_runner.mind_initialize()
	allocated += first_runner.mind
	var/datum/antagonist/fugitive/first = first_runner.mind.add_antag_datum(/datum/antagonist/fugitive)
	var/datum/team/fugitive/round_team = first.fugitive_team
	TEST_ASSERT_NOTNULL(round_team, "Беглец раунда без команды создаёт свою.")

	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/antag/crew/fugitive)
	TEST_ASSERT(session.prepare(), "Полигон готовит беглеца.")
	var/datum/antagonist/fugitive/training/trainee = session.current_body.mind.has_antag_datum(/datum/antagonist/fugitive/training)
	TEST_ASSERT(trainee && trainee.fugitive_team != round_team, "Учебный беглец не вступает в команду беглецов раунда.")
	TEST_ASSERT(!(trainee.owner in round_team.members), "В команде раунда нет учебного беглеца.")

	var/mob/living/carbon/human/second_runner = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	second_runner.mind_initialize()
	allocated += second_runner.mind
	var/datum/antagonist/fugitive/second = second_runner.mind.add_antag_datum(/datum/antagonist/fugitive)
	TEST_ASSERT_EQUAL(second.fugitive_team, round_team, "Новый беглец раунда вступает в команду раунда, а не в учебную.")
	TEST_ASSERT(length(trainee.fugitive_team.members) == 1 && (trainee.owner in trainee.fugitive_team.members), "В учебной команде только участник.")

	var/datum/team/fugitive_hunters/hunters = new
	var/list/results = hunters.assemble_fugitive_results()
	var/list/counted = results[1]
	TEST_ASSERT(length(counted) == 2 && (first in counted) && (second in counted), "Итог охотников раунда считает только беглецов раунда.")
	TEST_ASSERT(findtext(round_team.roundend_report(), "<B>2</B>"), "Отчёт беглецов раунда не считает учебного.")
	qdel(hunters)
	var/list/round_objectives = first.objectives | second.objectives
	QDEL_LIST(round_objectives)
	first_runner.mind.remove_antag_datum(/datum/antagonist/fugitive)
	second_runner.mind.remove_antag_datum(/datum/antagonist/fugitive)
	qdel(round_team)
	qdel(session)
	TEST_ASSERT_EQUAL(length(GLOB.antagonist_teams), teams_before, "Команды раунда вернулись к прежним.")

/datum/unit_test/antag_training_crews_pirate_radio
	var/list/hearings = list()

/// Гарнитура учебного пирата не слышит пиратов раунда, а они не слышат её.
/datum/unit_test/antag_training_crews_pirate_radio/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/antag/crew/pirate)
	TEST_ASSERT(session.prepare(), "Полигон готовит пирата.")
	var/mob/living/carbon/human/trainee = session.current_body
	var/mob/living/carbon/human/raider = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/partner = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	for(var/mob/living/carbon/human/listener as anything in list(raider, partner))
		var/obj/item/radio/headset/pirate/headset = allocate(/obj/item/radio/headset/pirate, get_turf(listener))
		headset.set_frequency(FREQ_PIRATE)
		TEST_ASSERT(listener.equip_to_slot_if_possible(headset, ITEM_SLOT_EARS_LEFT), "Пират раунда надевает гарнитуру пиратов.")
	for(var/mob/listener as anything in list(trainee, raider, partner))
		RegisterSignal(listener, COMSIG_MOVABLE_HEAR, PROC_REF(on_hear))
	raider.say("; pirate-station-probe")
	TEST_ASSERT(heard(partner, "pirate-station-probe"), "Пираты раунда слышат друг друга.")
	TEST_ASSERT(!heard(trainee, "pirate-station-probe"), "Гарнитура учебного пирата не слышит пиратов раунда.")
	trainee.say("; pirate-arena-probe")
	TEST_ASSERT(!heard(raider, "pirate-arena-probe") && !heard(partner, "pirate-arena-probe"), "Пираты раунда не слышат учебного пирата.")

/datum/unit_test/antag_training_crews_pirate_radio/proc/on_hear(mob/source, list/hearing_args)
	SIGNAL_HANDLER
	hearings += list(list(source, hearing_args[HEARING_RAW_MESSAGE]))

/datum/unit_test/antag_training_crews_pirate_radio/proc/heard(mob/listener, marker)
	for(var/list/entry as anything in hearings)
		if(entry[1] == listener && findtext(entry[2], marker))
			return TRUE
	return FALSE
