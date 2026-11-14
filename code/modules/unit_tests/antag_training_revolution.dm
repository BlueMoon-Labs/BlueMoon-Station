/// Фразы объявлений революции раунда: подавление мятежа и победа.
#define ANTAG_TRAINING_REVOLUTION_NEWS list("мятеж", "повышенного риска")

/// Новости станции с фразами объявления программы: посторонние новости мира за время теста не считаются.
/datum/unit_test/proc/antag_training_news_count(list/phrases)
	. = 0
	for(var/datum/news/feed_channel/channel as anything in GLOB.news_network.network_channels)
		for(var/datum/news/feed_message/message as anything in channel.messages)
			for(var/phrase in phrases)
				if(findtext(message.body, phrase))
					.++
					break

/// Программа выдаёт учебного главу революции со вспышкой и своей командой вне команд раунда; «Починить вспышку» чинит перегоревшую и выдаёт потерянную.
/datum/unit_test/antag_training_revolution_setup/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/antag/revolution)
	TEST_ASSERT(session.prepare(), "Полигон готовит главу революции.")
	var/datum/antag_training_program/antag/revolution/program = session.program
	var/mob/living/carbon/human/body = session.current_body
	var/datum/antagonist/rev/head/training/leader = program.role(session)
	TEST_ASSERT(istype(leader), "Кукла получает учебного главу революции.")
	var/obj/item/assembly/flash/flash = leader.flash_ref?.resolve()
	TEST_ASSERT(istype(flash) && body.contains_atom(flash), "Вспышка у главы.")
	TEST_ASSERT_NULL(locate(/obj/item/blackmarket_uplink) in body.GetAllContents(), "Аплинк чёрного рынка на полигоне не выдаётся.")
	var/datum/team/revolution/training/team = leader.get_team()
	TEST_ASSERT(istype(team) && (body.mind in team.members), "Глава в учебной команде.")
	TEST_ASSERT(!(team in GLOB.antagonist_teams) && isnull(leader.rev_team), "Учебная команда не в списке команд раунда, скан голов раунда её не видит.")
	var/list/data = session.ui_data(body)
	for(var/option in program.options)
		TEST_ASSERT(length(data["option_hints"][option]), "У кнопки «[option]» есть подсказка.")

	var/datum/tgui/console = allocate(/datum/tgui, body, session, "AntagTraining")
	flash.crit_fail = TRUE
	flash.times_used = 5
	antag_training_console_act(session, console, "program_option", list("option" = "Починить вспышку"))
	TEST_ASSERT(!flash.crit_fail && !flash.times_used, "«Починить вспышку» чинит перегоревшую вспышку.")
	qdel(flash)
	antag_training_console_act(session, console, "program_option", list("option" = "Починить вспышку"))
	var/obj/item/assembly/flash/replacement = leader.flash_ref?.resolve()
	TEST_ASSERT(istype(replacement) && replacement != flash && body.contains_atom(replacement), "Потерянная вспышка выдаётся заново.")

/// Учебные главы встают в кабинете макета и не считаются главами раунда; вспышка обращает учебную цель без игрока, а глав - нет; голова раунда в учебную команду не вступает; смерть глав - победа в пульте без объявлений.
/datum/unit_test/antag_training_revolution_conversion/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/antag/revolution)
	TEST_ASSERT(session.prepare(), "Полигон готовит главу революции.")
	var/datum/antag_training_arena/arena = session.arena
	var/datum/antag_training_sector/station = arena.sectors["station"]
	TEST_ASSERT(wait_for_var(station, "state", ANTAG_TRAINING_SECTOR_READY, 30 SECONDS), "Станционный макет загружается.")
	var/datum/antag_training_program/antag/revolution/program = session.program
	var/mob/living/carbon/human/body = session.current_body
	var/datum/antagonist/rev/head/training/leader = program.role(session)
	var/datum/team/revolution/training/team = leader.training_team
	var/datum/tgui/console = allocate(/datum/tgui, body, session, "AntagTraining")
	var/news_before = antag_training_news_count(ANTAG_TRAINING_REVOLUTION_NEWS)
	var/mode_result_before = SSticker.mode_result
	var/news_report_before = SSticker.news_report

	antag_training_console_act(session, console, "program_option", list("option" = "Главы станции"))
	TEST_ASSERT_EQUAL(length(team.objectives), 2, "Кнопка ставит двух учебных глав.")
	var/turf/office = station.landmark_turf("head_office")
	var/list/heads = list()
	for(var/datum/objective/antag_training/mutiny/mutiny in team.objectives)
		var/mob/living/carbon/human/head = mutiny.head
		heads[head.mind.assigned_role] = head
		TEST_ASSERT(mutiny.target == head.mind && (head.mind in arena.target_minds), "[head.real_name] - учебная цель.")
		TEST_ASSERT(get_dist(head, office) <= ANTAG_TRAINING_SPAWN_RADIUS && arena.inside_bounds(get_turf(head), station.bounds), "[head.real_name] стоит в кабинете главы макета.")
		TEST_ASSERT(mutiny in leader.objectives, "Цель мятежа против [head.real_name] у главы.")
	var/mob/living/carbon/human/captain = heads["Captain"]
	var/mob/living/carbon/human/security_head = heads["Head of Security"]
	TEST_ASSERT(captain && security_head, "Учебные главы - капитан и глава СБ.")
	TEST_ASSERT(!(captain.mind in SSjob.get_all_heads()) && !(captain.mind in SSjob.get_living_heads()), "Учебный капитан не считается главой раунда.")
	TEST_ASSERT(!(security_head.mind in SSjob.get_all_sec()) && !(security_head.mind in SSjob.get_living_sec()), "Учебный глава СБ не считается охраной раунда.")

	var/mob/living/carbon/human/station_leader = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	station_leader.mind_initialize()
	allocated += station_leader.mind
	var/datum/antagonist/rev/head/round_head = station_leader.mind.add_antag_datum(/datum/antagonist/rev/head)
	var/datum/team/revolution/round_team = round_head?.rev_team
	allocated += round_team
	TEST_ASSERT(round_team && round_team != team && !(station_leader.mind in team.members), "Голова революции раунда без команды не вступает в учебную.")
	for(var/datum/objective/mutiny/round_mutiny in round_team.objectives)
		TEST_ASSERT(round_mutiny.target != captain.mind && round_mutiny.target != security_head.mind, "Революция раунда не охотится на учебных глав.")

	antag_training_console_act(session, console, "program_option", list("option" = "Цель для обращения"))
	var/mob/living/carbon/human/recruit = arena.targets[length(arena.targets)]
	TEST_ASSERT(recruit != captain && recruit != security_head && isnull(recruit.client), "Цель для обращения - учебная цель без игрока.")
	var/obj/item/assembly/flash/flash = leader.flash_ref?.resolve()
	flash.burnout_resistance = 100
	flash.attack(recruit, body)
	var/datum/antagonist/rev/rebel = recruit.mind.has_antag_datum(/datum/antagonist/rev)
	TEST_ASSERT(istype(rebel, /datum/antagonist/rev/training), "Вспышка обращает учебную цель без игрока в учебного революционера.")
	TEST_ASSERT((recruit.mind in team.members) && rebel.get_team() == team, "Обращённый - в учебной команде.")
	TEST_ASSERT(!length(team.objectives - rebel.objectives), "Обращённый получает цели учебного мятежа.")
	flash.attack(captain, body)
	TEST_ASSERT_NULL(captain.mind.has_antag_datum(/datum/antagonist/rev), "Учебного капитана вспышка не обращает.")

	antag_training_console_act(session, console, "program_option", list("option" = "Цель для обращения"))
	var/mob/living/carbon/human/second_recruit = arena.targets[length(arena.targets)]
	var/obj/item/assembly/flash/memorizer/memorizer = allocate(/obj/item/assembly/flash/memorizer, get_turf(body))
	memorizer.burnout_resistance = 100
	memorizer.attack(second_recruit, body)
	TEST_ASSERT(istype(second_recruit.mind.has_antag_datum(/datum/antagonist/rev), /datum/antagonist/rev/training), "Мемораайзер обращает учебную цель тем же путём.")

	var/mob/living/carbon/human/bystander = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	bystander.mind_initialize()
	allocated += bystander.mind
	var/obj/item/assembly/flash/handheld/round_flash = allocate(/obj/item/assembly/flash/handheld, run_loc_floor_bottom_left)
	round_flash.burnout_resistance = 100
	round_flash.attack(bystander, station_leader)
	TEST_ASSERT_NULL(bystander.mind.has_antag_datum(/datum/antagonist/rev), "Вне полигона вспышка по-прежнему не обращает тело без игрока.")
	TEST_ASSERT(!rebel.add_revolutionary(bystander.mind, FALSE) && !bystander.mind.has_antag_datum(/datum/antagonist/rev), "Учебный революционер никого не обращает.")

	captain.death()
	TEST_ASSERT(!team.victorious && !findtext("[session.last_feedback]", "Учебная революция победила"), "Пока жив глава СБ, победы нет.")
	security_head.death()
	TEST_ASSERT(team.victorious, "Смерть обеих учебных глав - победа учебной революции.")
	TEST_ASSERT(findtext(session.ui_data(body)["last_feedback"], "Учебная революция победила"), "Пульт сообщает о победе учебной революции.")
	TEST_ASSERT_EQUAL(antag_training_news_count(ANTAG_TRAINING_REVOLUTION_NEWS), news_before, "Победа не публикует объявлений.")
	TEST_ASSERT(SSticker.mode_result == mode_result_before && SSticker.news_report == news_report_before, "Победа не меняет итог раунда.")

	antag_training_console_act(session, console, "program_option", list("option" = "Главы станции"))
	TEST_ASSERT(!team.victorious && length(team.objectives) == 2, "Новая расстановка глав сбрасывает победу.")
	var/datum/objective/antag_training/mutiny/first_mutiny = team.objectives[1]
	var/datum/objective/antag_training/mutiny/second_mutiny = team.objectives[2]
	first_mutiny.head.death()
	TEST_ASSERT(!team.victorious, "Пока вторая глава жива, победы нет.")
	antag_training_console_act(session, console, "target_delete", list("id" = REF(second_mutiny.head)))
	TEST_ASSERT(team.victorious && length(team.objectives) == 1, "Убранная через «Цели» глава не мешает победе над оставшейся мёртвой.")

	qdel(session)
	TEST_ASSERT(wait_for_qdeleted(leader, 1 MINUTES), "Выход снимает роль главы.")
	TEST_ASSERT(QDELETED(team) && QDELETED(rebel), "Учебная команда и обращённые снимаются вместе с главой.")

#undef ANTAG_TRAINING_REVOLUTION_NEWS
