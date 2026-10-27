/obj/effect/proc_holder/spell/targeted/summon_contract/training/probe
	var/picked

/obj/effect/proc_holder/spell/targeted/summon_contract/training/probe/choose_contract(mob/user)
	return picked

/datum/unit_test/proc/antag_training_devil_soul(datum/antag_training_session/session, datum/tgui/console)
	antag_training_console_act(session, console, "program_option", list("option" = "Душа учебной цели"))

/// Программа дьявола выдаёт учебного дьявола вне списка дьяволов раунда, контракт для практики и призыв контрактов без престижа и друга; снятая роль следов не оставляет.
/datum/unit_test/antag_training_devil_setup/Run()
	var/list/known_devils = GLOB.allDevils.Copy()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/antag/devil)
	TEST_ASSERT(session.prepare(), "Полигон готовит дьявола.")
	var/datum/antag_training_program/antag/devil/program = session.program
	var/mob/living/carbon/human/body = session.current_body
	var/datum/antagonist/devil/training/devil = program.role(session)
	TEST_ASSERT(istype(devil), "Кукла получает учебного дьявола.")
	TEST_ASSERT(length(devil.truename) && !devil.ascendable, "У дьявола есть истинное имя, возвышения нет.")
	TEST_ASSERT_EQUAL(length(GLOB.allDevils), length(known_devils), "Список дьяволов раунда не растёт.")
	TEST_ASSERT(GLOB.allDevils[lowertext(devil.truename)] != devil, "Истинное имя учебного дьявола не записано в раунд.")
	var/report = devil.true_name_report()
	TEST_ASSERT(findtext(report, devil.truename) && findtext(report, GLOB.lawlorify[LAW][devil.bane]) && findtext(report, GLOB.lawlorify[LAW][devil.banish]), "«Истинное имя» называет имя и слабости.")
	var/list/data = session.ui_data(body)
	for(var/option in program.options)
		TEST_ASSERT(length(data["option_hints"][option]), "У кнопки «[option]» есть подсказка.")

	var/datum/tgui/console = allocate(/datum/tgui, body, session, "AntagTraining")
	antag_training_console_act(session, console, "program_option", list("option" = "Контракт для практики"))
	var/obj/item/paper/contract/infernal/power/practice = locate() in body.held_items
	TEST_ASSERT_NOTNULL(practice, "Контракт для практики в руках.")
	TEST_ASSERT(practice.owner == body.mind && (practice.target in session.arena.target_minds), "Контракт - от дьявола на учебную цель.")
	TEST_ASSERT(session.arena.owns_area(get_area(practice)), "Контракт на полигоне.")

	var/obj/effect/proc_holder/spell/targeted/summon_contract/training/summon = locate() in body.mind.spell_list
	TEST_ASSERT_NOTNULL(summon, "Дьявол призывает контракты учебным заклинанием.")
	for(var/obj/effect/proc_holder/spell/targeted/summon_contract/spell in body.mind.spell_list)
		TEST_ASSERT(istype(spell, /obj/effect/proc_holder/spell/targeted/summon_contract/training), "Обычного призыва контрактов нет.")
	var/mob/living/carbon/human/signer = practice.target.current
	var/obj/effect/proc_holder/spell/targeted/summon_contract/training/probe/probe = new
	allocated += probe
	probe.picked = "Prestige"
	probe.perform(list(signer), TRUE, body)
	TEST_ASSERT_NULL(locate(/obj/item/paper/contract/infernal) in signer.held_items, "Контракт на престиж на полигоне не призывается.")
	TEST_ASSERT_EQUAL(probe.charge_counter, probe.charge_max, "Отказ не тратит заряд.")
	probe.picked = "Power"
	probe.perform(list(signer), TRUE, body)
	var/obj/item/paper/contract/infernal/power/summoned = locate() in signer.held_items
	TEST_ASSERT(summoned && summoned.owner == body.mind && summoned.target == signer.mind, "Контракт на силу призывается в руки цели.")

	qdel(session)
	TEST_ASSERT(wait_for_qdeleted(devil, 1 MINUTES), "Роль снимается с сессией.")
	TEST_ASSERT_EQUAL(length(GLOB.allDevils), length(known_devils), "После снятия записи дьявола нет.")

/// Кнопка «Душа учебной цели» даёт по душе от каждого нового манекена, на трёх душах кукла становится кровавым ящером, а смерть воскрешает её в центре полигона ценой душ без нового тела.
/datum/unit_test/antag_training_devil_souls/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/antag/devil)
	TEST_ASSERT(session.prepare(), "Полигон готовит дьявола.")
	var/datum/antag_training_program/antag/devil/program = session.program
	var/mob/living/carbon/human/body = session.current_body
	var/datum/antagonist/devil/training/devil = program.role(session)
	var/datum/tgui/console = allocate(/datum/tgui, body, session, "AntagTraining")
	var/list/donors = list()
	for(var/count in 1 to BLOOD_THRESHOLD)
		antag_training_devil_soul(session, console)
		TEST_ASSERT_EQUAL(length(devil.soulsOwned), count, "Каждое нажатие даёт одну душу.")
		var/datum/mind/soul = devil.soulsOwned[count]
		TEST_ASSERT((soul in session.arena.target_minds) && !(soul.current in donors), "Душа - от нового учебного манекена.")
		TEST_ASSERT_EQUAL(soul.soulOwner, devil.owner, "Душа манекена принадлежит дьяволу.")
		donors += soul.current
	TEST_ASSERT(wait_for_var(devil, "form", BLOOD_LIZARD, 15 SECONDS), "На трёх душах дьявол становится кровавым ящером.")
	TEST_ASSERT(istype(body.dna.species, /datum/species/lizard), "Кукла - ящер.")

	var/humans = length(GLOB.human_list)
	body.forceMove(session.arena.zones["melee"]["spawn"])
	body.death()
	TEST_ASSERT_EQUAL(body.stat, DEAD, "Кукла умерла на боевой площадке.")
	TEST_ASSERT(wait_for_var(body, "stat", CONSCIOUS, 20 SECONDS), "Дьявол воскресает.")
	TEST_ASSERT_EQUAL(devil.reviveNumber, LOSS_PER_DEATH, "Воскрешение стоит душ.")
	TEST_ASSERT_EQUAL(get_turf(body), session.arena.entry_turf, "Дьявол воскресает в центре полигона.")
	TEST_ASSERT_EQUAL(devil.owner.current, body, "Дьявол остаётся в своём теле.")
	TEST_ASSERT_EQUAL(length(GLOB.human_list), humans, "Нового тела не появилось.")
	TEST_ASSERT_EQUAL(devil.form, BASIC_DEVIL, "Без запаса душ ящер становится человеком.")

/// Души до порога архидьявола делают куклу истинным дьяволом на полигоне, но вознесения, затемнения космоса и вызова шаттла нет; истинный дьявол и его учебные грешники, в том числе на другом участнике, снимаются с сессией.
/datum/unit_test/antag_training_devil_no_ascension/Run()
	var/shuttle_mode = SSshuttle.emergency?.mode
	var/ascended = SSticker.mode?.devil_ascended
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/antag/devil)
	TEST_ASSERT(session.prepare(), "Полигон готовит дьявола.")
	var/datum/antag_training_program/antag/devil/program = session.program
	var/mob/living/carbon/human/body = session.current_body
	var/datum/antagonist/devil/training/devil = program.role(session)
	var/datum/tgui/console = allocate(/datum/tgui, body, session, "AntagTraining")
	for(var/count in 1 to ARCH_THRESHOLD)
		antag_training_devil_soul(session, console)
		if(count == BLOOD_THRESHOLD)
			TEST_ASSERT(wait_for_var(devil, "form", BLOOD_LIZARD, 15 SECONDS), "На трёх душах - кровавый ящер.")
		if(count == TRUE_THRESHOLD)
			TEST_ASSERT(wait_for_var(devil, "form", TRUE_DEVIL, 15 SECONDS), "На семи душах - истинный дьявол.")
	TEST_ASSERT_EQUAL(length(devil.soulsOwned), ARCH_THRESHOLD, "Душ хватает на архидьявола.")
	var/mob/living/carbon/true_devil/devil_form = devil.owner.current
	TEST_ASSERT(istype(devil_form), "Кукла - истинный дьявол.")
	TEST_ASSERT_EQUAL(session.current_body, devil_form, "Полигон ведёт новое тело.")
	TEST_ASSERT(session.arena.owns_area(get_area(devil_form)), "Истинный дьявол на полигоне.")
	TEST_ASSERT(devil.form == TRUE_DEVIL && !devil_form.ascended, "Архидьявола нет.")
	TEST_ASSERT_EQUAL(SSshuttle.emergency?.mode, shuttle_mode, "Эвакуация не вызвана.")
	TEST_ASSERT_EQUAL(SSticker.mode?.devil_ascended, ascended, "Счётчик вознесений раунда не растёт.")
	var/obj/effect/proc_holder/spell/targeted/sintouch/training/sintouch = locate() in devil.owner.spell_list
	TEST_ASSERT_NOTNULL(sintouch, "Истинный дьявол касается греха учебным заклинанием.")
	var/datum/mind/sinner = devil.soulsOwned[ARCH_THRESHOLD]
	var/datum/antag_training_session/second = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(second.prepare(session.arena), "Второй участник входит на ту же арену.")
	var/round_sinners = length(get_antag_minds(/datum/antagonist/sintouched))
	sintouch.perform(list(sinner.current, second.current_body), TRUE, devil_form)
	TEST_ASSERT_EQUAL(length(get_antag_minds(/datum/antagonist/sintouched)), round_sinners, "Учебные грешники не засчитываются целям дьяволов раунда.")
	var/datum/antagonist/sintouched/touched = sinner.has_antag_datum(/datum/antagonist/sintouched)
	TEST_ASSERT(istype(touched, /datum/antagonist/sintouched/training) && !touched.show_in_roundend && touched.threat() == 0, "Касание греха на полигоне - учебное, вне отчёта и угрозы раунда.")
	var/datum/antagonist/sintouched/participant_sin = second.avatar_mind.has_antag_datum(/datum/antagonist/sintouched)
	TEST_ASSERT((touched in devil.sinners) && (participant_sin in devil.sinners), "Дьявол ведёт выданных им грешников, в том числе другого участника.")
	qdel(session)
	TEST_ASSERT(wait_for_qdeleted(devil_form, 1 MINUTES) && wait_for_qdeleted(body, 1 MINUTES), "Истинный дьявол и прежнее тело убираются с сессией.")
	TEST_ASSERT(QDELETED(participant_sin) && !second.avatar_mind.has_antag_datum(/datum/antagonist/sintouched), "Грех другого участника снимается с концом сессии дьявола.")
	qdel(second)
	wait_for_closing_training_arenas()
	pass(view(0, run_loc_floor_bottom_left))
