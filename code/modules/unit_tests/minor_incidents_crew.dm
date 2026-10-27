/// Отсек, которого нет ни на одной карте: целей для preflight нет.
/area/minor_crew_test_void
	name = "Minor Crew Test Void"

/// Отсек СБ, которого нет на картах: датчик побега отличает его от коридора.
/area/security/minor_crew_test_cell
	name = "Minor Crew Test Cell"

/area/mine/laborcamp/minor_crew_test_camp
	name = "Minor Crew Test Labor Camp"

/// Лаборатория и её подотсек, которых нет на картах.
/area/minor_crew_test_lab
	name = "Minor Crew Test Lab"

/area/minor_crew_test_lab/annex
	name = "Minor Crew Test Lab Annex"

/datum/round_event/ghost_role/prisoner_transfer/test_empty_poll
	var/refunded = FALSE
	var/turf/test_landing

/datum/round_event/ghost_role/prisoner_transfer/test_empty_poll/get_landing_turfs()
	return test_landing ? list(test_landing) : list()

/datum/round_event/ghost_role/prisoner_transfer/test_empty_poll/get_candidates(jobban, gametypecheck, be_special)
	return list()

/datum/round_event/ghost_role/prisoner_transfer/test_empty_poll/refund_failed_spawn(reason)
	refunded = TRUE

/// Тестовый мир не на станционном z: под стражей ли заключённый, задаёт тест.
/datum/round_event/ghost_role/prisoner_transfer/test_custody
	var/custody = FALSE

/datum/round_event/ghost_role/prisoner_transfer/test_custody/in_custody(mob/living/prisoner)
	return custody && prisoner && prisoner.stat != DEAD

/// В тестах нет клиентов: любой ударивший моб считается игроком.
/mob/living/simple_animal/sanitary_drone/test_any_attacker

/mob/living/simple_animal/sanitary_drone/test_any_attacker/is_player_attacker(mob/attacker)
	return ismob(attacker) && attacker != src

/// Происшествия экипажа: заключённый, обезьяны, санитарный дрон и потерянный питомец.
/datum/unit_test/minor_incidents_crew
	var/list/filed_record_names = list()
	var/list/turf/borrowed_turfs = list()

/datum/unit_test/minor_incidents_crew/Run()
	var/area/home_area = get_area(run_loc_floor_bottom_left)
	check_prisoner_transfer()
	for(var/turf/borrowed as anything in borrowed_turfs)
		home_area.contents.Add(borrowed)
	check_prisoner_internals()
	check_lab_monkeys()
	check_monkey_temperaments()
	check_sanitary_inspection()
	check_lost_pet()
	check_lost_pet_lure()
	for(var/record_name in filed_record_names)
		GLOB.data_core.remove_records_by_name(record_name)

/datum/unit_test/minor_incidents_crew/proc/make_event(event_path)
	var/datum/round_event/event = allocate(event_path, FALSE)
	SSdirector.running -= event
	return event

/datum/unit_test/minor_incidents_crew/proc/paper_text(obj/item/paper/sheet)
	var/list/texts = list()
	for(var/datum/paper_input/input as anything in sheet.raw_text_inputs)
		texts += input.raw_text
	return jointext(texts, "")

/datum/unit_test/minor_incidents_crew/proc/department_balance(account_id)
	var/datum/bank_account/department/account = SSeconomy.get_dep_account(account_id)
	TEST_ASSERT_NOTNULL(account, "Нужен бюджет отдела [account_id]")
	return account.account_balance

/// Человек с надетой ID-картой и счётом на ней.
/datum/unit_test/minor_incidents_crew/proc/make_payee(turf/spot, card_name)
	var/mob/living/carbon/human/person = allocate(/mob/living/carbon/human, spot)
	var/datum/bank_account/account = allocate(/datum/bank_account, card_name, null)
	var/obj/item/card/id/card = allocate(/obj/item/card/id)
	card.registered_account = account
	card.registered_name = card_name
	person.equip_to_slot(card, ITEM_SLOT_ID)
	return person

/datum/unit_test/minor_incidents_crew/proc/personal_balance(mob/living/carbon/human/person)
	var/datum/bank_account/account = person.get_bank_account()
	return account?.account_balance

/datum/unit_test/minor_incidents_crew/proc/check_prisoner_transfer()
	var/datum/round_event_control/prisoner_transfer/control = allocate(/datum/round_event_control/prisoner_transfer)
	control.landing_area_types = list(/area/minor_crew_test_void)
	TEST_ASSERT(!length(control.get_landing_turfs()), "Без брига капсуле некуда садиться")
	TEST_ASSERT(!control.director_preflight(), "Без брига событие должно отсеиваться до траты бюджета")

	var/datum/round_event/ghost_role/prisoner_transfer/test_empty_poll/empty = make_event(/datum/round_event/ghost_role/prisoner_transfer/test_empty_poll)
	empty.test_landing = run_loc_floor_bottom_left
	empty.try_spawning()
	TEST_ASSERT_EQUAL(empty.status, NOT_ENOUGH_PLAYERS, "Пустой опрос гостов не создаёт заключённого")
	TEST_ASSERT(empty.refunded, "Пустой опрос гостов должен возвращать бюджет директора")
	TEST_ASSERT(!length(empty.spawned_mobs), "Без желающих в мире не должно остаться тела заключённого")

	var/datum/round_event/ghost_role/prisoner_transfer/test_custody/event = make_event(/datum/round_event/ghost_role/prisoner_transfer/test_custody)
	event.control = control
	var/obj/structure/closet/crate/pod_stand_in = allocate(/obj/structure/closet/crate)
	var/mob/living/carbon/human/prisoner = allocate(/mob/living/carbon/human, pod_stand_in)
	prisoner.mind_initialize()
	event.prepare_prisoner(prisoner)
	event.register_prisoner(prisoner)
	TEST_ASSERT(istype(prisoner.w_uniform, /obj/item/clothing/under/rank/prisoner), "Заключённый прибывает в оранжевой робе")
	TEST_ASSERT(istype(prisoner.shoes, /obj/item/clothing/shoes/sneakers/orange), "Заключённый прибывает в тюремной обуви")
	TEST_ASSERT(prisoner.handcuffed, "Заключённый прибывает в наручниках")
	var/obj/item/card/id/prisoner/transfer/card = prisoner.wear_id
	TEST_ASSERT(istype(card), "У заключённого должна быть карта этапа")
	TEST_ASSERT_EQUAL(card.registered_name, "Transfer Prisoner #[event.prisoner_number]", "Карта выписана на номер этапа")
	TEST_ASSERT(!length(card.GetAccess()), "Карта заключённого не даёт доступа")
	var/obj/item/paper/prisoner_sentence/sentence = prisoner.l_store
	TEST_ASSERT(istype(sentence), "Приговор лежит в кармане")
	TEST_ASSERT(findtext(paper_text(sentence), event.crime), "В приговоре указана статья")
	TEST_ASSERT(prisoner.mind.is_ghost_role(), "Заключённый - гост-роль, а не член экипажа")
	TEST_ASSERT(prisoner.mind.assigned_role in GLOB.exp_specialmap[EXP_TYPE_SPECIAL], "Мидраунд-рулсеты отсеивают заключённого по роли")
	TEST_ASSERT(HAS_TRAIT(prisoner, TRAIT_NO_MIDROUND_ANTAG), "Заключённого не делают мидраунд-антагом")
	TEST_ASSERT(!is_effective_crew_mob(prisoner), "Директор не считает заключённого экипажем")

	filed_record_names += prisoner.real_name
	var/datum/data/record/security = event.file_security_record(prisoner)
	TEST_ASSERT_EQUAL(GLOB.data_core.security_by_name[prisoner.real_name], security, "Заключённый попадает в базу СБ")
	TEST_ASSERT_NOTNULL(GLOB.data_core.general_by_name[prisoner.real_name], "Консоль СБ находит общую запись заключённого")
	TEST_ASSERT_EQUAL(security.fields["criminal"], SEC_RECORD_STATUS_INCARCERATED, "В базе СБ заключённый числится отбывающим срок")
	var/list/convictions = security.fields["mi_crim"]
	var/datum/data/crime/conviction = length(convictions) ? convictions[1] : null
	TEST_ASSERT(conviction && findtext(conviction.crimeName, event.crime), "В записи СБ указана статья")
	TEST_ASSERT(findtext(conviction.crimeDetails, "[event.term / (1 MINUTES)] минут"), "В записи СБ указан срок")

	var/balance = department_balance(ACCOUNT_SEC)
	prisoner.forceMove(run_loc_floor_bottom_left)
	var/installment = department_balance(ACCOUNT_SEC) - balance
	TEST_ASSERT(installment > 0, "При приземлении СБ получает первую часть содержания")
	prisoner.forceMove(get_step(run_loc_floor_bottom_left, NORTH))
	TEST_ASSERT_EQUAL(department_balance(ACCOUNT_SEC), balance + installment, "Первая часть содержания платится один раз")

	var/area/corridor = get_area(run_loc_floor_bottom_left)
	var/area/cell = new /area/security/minor_crew_test_cell
	var/area/camp = new /area/mine/laborcamp/minor_crew_test_camp
	allocated += list(cell, camp)
	event.on_prisoner_area(prisoner, corridor)
	TEST_ASSERT(event.at_large, "Выход из отсеков СБ без конвоя - побег")
	event.on_prisoner_area(prisoner, cell)
	TEST_ASSERT(!event.at_large, "Возвращение в бриг снимает побег")
	check_prisoner_escort(event, prisoner, corridor, cell)
	check_prisoner_container(event, prisoner, cell)
	event.on_prisoner_area(prisoner, corridor)
	event.on_prisoner_area(prisoner, camp)
	TEST_ASSERT(!event.at_large, "Трудовой лагерь - тоже место заключения")
	var/datum/round_event/ghost_role/prisoner_transfer/plain = make_event(/datum/round_event/ghost_role/prisoner_transfer)
	var/turf/camp_spot = run_loc_floor_top_right
	borrowed_turfs += camp_spot
	camp.contents.Add(camp_spot)
	prisoner.forceMove(camp_spot)
	TEST_ASSERT(plain.in_custody(prisoner), "Заключённый в трудовом лагере к концу срока считается под стражей")
	prisoner.forceMove(run_loc_floor_bottom_left)

	var/list/saved_spawns = SSdirector.live_ghost_role_spawns
	SSdirector.live_ghost_role_spawns = list()
	check_prisoner_term(control, event, prisoner, installment)
	SSdirector.live_ghost_role_spawns = saved_spawns

	var/datum/round_event/ghost_role/prisoner_transfer/test_custody/escaped = make_event(/datum/round_event/ghost_role/prisoner_transfer/test_custody)
	escaped.prisoner_ref = WEAKREF(prisoner)
	balance = department_balance(ACCOUNT_SEC)
	escaped.serve_term()
	TEST_ASSERT_EQUAL(department_balance(ACCOUNT_SEC), balance, "Если к концу срока заключённого нет в бриге, второй части содержания нет")

/// Конец срока: вторая часть содержания и снятие нагрузки директора.
/datum/unit_test/minor_incidents_crew/proc/check_prisoner_term(datum/round_event_control/prisoner_transfer/control, datum/round_event/ghost_role/prisoner_transfer/test_custody/event, mob/living/carbon/human/prisoner, installment)
	TEST_ASSERT(SSdirector.track_ghost_role_spawn(control, list(prisoner), log_execution = FALSE), "Заключённый переходит на живой трекинг директора")
	TEST_ASSERT(SSdirector.get_ghost_role_intensity(only_antag = FALSE) > 0, "Пока идёт срок, заключённый - нагрузка директора")
	event.custody = TRUE
	var/balance = department_balance(ACCOUNT_SEC)
	event.serve_term()
	TEST_ASSERT(event.term_over, "Срок закрывается")
	TEST_ASSERT_EQUAL(department_balance(ACCOUNT_SEC), balance + installment, "По окончании срока в бриге СБ получает вторую часть содержания")
	TEST_ASSERT_EQUAL(SSdirector.get_ghost_role_intensity(only_antag = FALSE), 0, "Отбывший срок заключённый не держит intensity директора")
	event.serve_term()
	TEST_ASSERT_EQUAL(department_balance(ACCOUNT_SEC), balance + installment, "Вторая часть содержания платится один раз")

/// Конвой - только сотрудник с доступом СБ: сообщник, который тянет заключённого, датчик не глушит.
/datum/unit_test/minor_incidents_crew/proc/check_prisoner_escort(datum/round_event/ghost_role/prisoner_transfer/event, mob/living/carbon/human/prisoner, area/corridor, area/cell)
	var/mob/living/carbon/human/accomplice = make_payee(get_step(prisoner, EAST), "Prisoner Accomplice")
	accomplice.start_pulling(prisoner)
	event.on_prisoner_area(prisoner, corridor)
	accomplice.stop_pulling()
	TEST_ASSERT(event.at_large, "Сообщник без доступа СБ - не конвой")
	event.on_prisoner_area(prisoner, cell)
	var/mob/living/carbon/human/guard = make_payee(get_step(prisoner, WEST), "Prisoner Guard")
	var/obj/item/card/id/guard_card = guard.wear_id
	guard_card.access = list(ACCESS_SECURITY)
	guard.start_pulling(prisoner)
	event.on_prisoner_area(prisoner, corridor)
	guard.stop_pulling()
	TEST_ASSERT(!event.at_large, "Под конвоем сотрудника СБ выход из брига - не побег")
	event.on_prisoner_area(prisoner, cell)

/// Заключённого, которого выносят из брига в шкафу, датчик ведёт по отсекам шкафа.
/datum/unit_test/minor_incidents_crew/proc/check_prisoner_container(datum/round_event/ghost_role/prisoner_transfer/event, mob/living/carbon/human/prisoner, area/cell)
	var/turf/cell_spot = run_loc_floor_top_right
	var/turf/corridor_spot = run_loc_floor_bottom_left
	borrowed_turfs += cell_spot
	cell.contents.Add(cell_spot)
	prisoner.forceMove(cell_spot)
	TEST_ASSERT(!event.at_large, "В камере заключённый под стражей")
	var/obj/structure/closet/locker = allocate(/obj/structure/closet, cell_spot)
	prisoner.forceMove(locker)
	locker.forceMove(corridor_spot)
	TEST_ASSERT(event.at_large, "Шкаф с заключённым, вынесенный из брига, не глушит датчик")
	locker.forceMove(cell_spot)
	TEST_ASSERT(!event.at_large, "Шкаф с заключённым вернули в бриг - побег снят")
	prisoner.forceMove(cell_spot)
	locker.forceMove(corridor_spot)
	TEST_ASSERT(!event.at_large, "Пустой шкаф, вынесенный из брига, датчик больше не трогает")
	prisoner.forceMove(locker)
	var/mob/living/carbon/human/guard = make_payee(get_step(corridor_spot, NORTH), "Locker Guard")
	var/obj/item/card/id/guard_card = guard.wear_id
	guard_card.access = list(ACCESS_SECURITY)
	guard.start_pulling(locker)
	TEST_ASSERT(event.escorted(prisoner), "Шкаф с заключённым везёт сотрудник СБ - это конвой")
	guard.stop_pulling()
	prisoner.forceMove(cell_spot)
	TEST_ASSERT(!length(event.watched_holders), "Выбравшись из шкафа, заключённый больше не привязан к нему")

/datum/unit_test/minor_incidents_crew/proc/check_prisoner_internals()
	var/datum/round_event/ghost_role/prisoner_transfer/event = make_event(/datum/round_event/ghost_role/prisoner_transfer)
	var/obj/structure/closet/crate/pod_stand_in = allocate(/obj/structure/closet/crate)
	var/mob/living/carbon/human/prisoner = allocate(/mob/living/carbon/human, pod_stand_in)
	prisoner.set_species(/datum/species/plasmaman)
	event.prepare_prisoner(prisoner)
	TEST_ASSERT(prisoner.handcuffed, "Плазмамен тоже прибывает в наручниках")
	var/obj/item/tank/breathing = prisoner.internal
	TEST_ASSERT_NOTNULL(breathing, "Плазмамен в наручниках продолжает дышать из баллона")
	TEST_ASSERT(breathing.loc == prisoner && !(breathing in prisoner.held_items), "Баллон убран из рук в слот и не падает от наручников")

/datum/unit_test/minor_incidents_crew/proc/release(datum/round_event/lab_monkeys/event, area/lab, list/spots, matched_type)
	event.release_monkeys(lab, spots, matched_type)
	var/list/monkeys = list()
	for(var/datum/weakref/monkey_ref as anything in event.monkeys)
		var/mob/living/carbon/monkey/monkey = monkey_ref.resolve()
		monkeys += monkey
		allocated += monkey
	return monkeys

/datum/unit_test/minor_incidents_crew/proc/check_lab_monkeys()
	var/datum/round_event_control/lab_monkeys/control = allocate(/datum/round_event_control/lab_monkeys)
	control.home_area_types = list(/area/minor_crew_test_void)
	control.fallback_area_types = list(/area/minor_crew_test_void)
	TEST_ASSERT_NULL(control.find_home(), "Без генетики и науки обезьянам неоткуда сбегать")
	TEST_ASSERT(!control.director_preflight(), "Без лаборатории событие должно отсеиваться до траты бюджета")

	control.home_area_types = list(/area/minor_crew_test_lab)
	var/area/minor_crew_test_lab/annex/annex = new
	allocated += annex
	TEST_ASSERT_EQUAL(control.home_type_of(annex), /area/minor_crew_test_lab, "Дом обезьян - тип из списка, а не подотсек, где нашёлся пол")
	var/turf/home_spot = run_loc_floor_bottom_left
	var/area/corridor = get_area(home_spot)
	annex.contents.Add(home_spot)
	check_monkey_return(control, annex)
	corridor.contents.Add(home_spot)

/datum/unit_test/minor_incidents_crew/proc/check_monkey_return(datum/round_event_control/lab_monkeys/control, area/annex)
	var/turf/home_spot = run_loc_floor_bottom_left
	var/turf/outside = run_loc_floor_top_right
	var/datum/round_event/lab_monkeys/event = make_event(/datum/round_event/lab_monkeys)
	var/list/monkeys = release(event, annex, list(outside), control.home_type_of(annex))
	TEST_ASSERT_EQUAL(length(monkeys), 3, "Сбегают три обезьяны")
	TEST_ASSERT_EQUAL(event.department_account, ACCOUNT_SCI, "За научную лабораторию платят в бюджет науки")
	var/mob/living/carbon/monkey/first = monkeys[1]
	var/datum/component/lab_monkey_tag/tag = first.GetComponent(/datum/component/lab_monkey_tag)
	TEST_ASSERT_NOTNULL(tag, "На обезьяне бирка-ошейник")
	TEST_ASSERT("lab_tag" in icon_states(tag.tag_overlay.icon), "У бирки есть спрайт")
	var/examine_text = jointext(first.examine(first), "")
	TEST_ASSERT(findtext(examine_text, "LM-1"), "Бирка читается при осмотре")
	TEST_ASSERT(findtext(examine_text, "ID-карты"), "На бирке записан характер обезьяны")

	event.check_monkeys()
	TEST_ASSERT(!length(event.home_since) && !length(event.secured), "Обезьяна вне лаборатории не засчитывается")
	var/mob/living/carbon/human/courier = make_payee(get_step(home_spot, NORTH), "Monkey Courier")
	for(var/mob/living/carbon/monkey/monkey as anything in monkeys)
		monkey.forceMove(home_spot)
	courier.start_pulling(first)
	event.check_monkeys()
	courier.stop_pulling()
	TEST_ASSERT_EQUAL(length(event.home_since), 3, "Подотсек лаборатории засчитывается как дом")
	TEST_ASSERT_EQUAL(length(event.secured), 0, "Только что занесённую обезьяну не засчитывают сразу")
	var/balance = department_balance(ACCOUNT_SCI)
	var/courier_balance = personal_balance(courier)
	for(var/monkey_ref in event.home_since)
		event.home_since[monkey_ref] -= 1 MINUTES
	event.check_monkeys()
	TEST_ASSERT_EQUAL(length(event.secured), 3, "Удержанные дома обезьяны засчитываются")
	TEST_ASSERT(event.resolved, "Все три образца закрывают событие")
	var/reward = department_balance(ACCOUNT_SCI) - balance
	TEST_ASSERT(reward > 0, "За всех трёх отдел получает деньги")
	TEST_ASSERT(personal_balance(courier) > courier_balance, "Занёсший обезьяну домой получает личную благодарность")
	event.check_monkeys()
	event.end()
	TEST_ASSERT_EQUAL(department_balance(ACCOUNT_SCI), balance + reward, "Награда выдаётся один раз")
	for(var/mob/living/carbon/monkey/monkey as anything in monkeys)
		TEST_ASSERT(!QDELETED(monkey) && monkey.stat != DEAD, "После события обезьяны остаются обычными живыми обезьянами")

	var/datum/round_event/lab_monkeys/doomed = make_event(/datum/round_event/lab_monkeys)
	var/list/doomed_monkeys = release(doomed, annex, list(outside), control.home_type_of(annex))
	var/mob/living/carbon/monkey/saved = doomed_monkeys[1]
	saved.forceMove(home_spot)
	doomed.check_monkeys()
	for(var/monkey_ref in doomed.home_since)
		doomed.home_since[monkey_ref] -= 1 MINUTES
	doomed.check_monkeys()
	TEST_ASSERT_EQUAL(length(doomed.secured), 1, "Первую обезьяну засчитывают отдельно")
	saved.death()
	doomed.check_monkeys()
	TEST_ASSERT(!doomed.resolved, "Гибель уже засчитанной обезьяны не срывает событие")
	var/mob/living/carbon/monkey/victim = doomed_monkeys[2]
	victim.death()
	balance = department_balance(ACCOUNT_SCI)
	doomed.check_monkeys()
	TEST_ASSERT(doomed.resolved, "Гибель незасчитанного образца закрывает событие")
	TEST_ASSERT_EQUAL(department_balance(ACCOUNT_SCI), balance, "Убийство обезьяны лишает награды")

	var/datum/round_event/lab_monkeys/genetics = make_event(/datum/round_event/lab_monkeys)
	release(genetics, annex, list(outside), /area/medical/genetics)
	TEST_ASSERT_EQUAL(genetics.department_account, ACCOUNT_MED, "За генетику платят в бюджет медотдела")

/datum/unit_test/minor_incidents_crew/proc/check_monkey_temperaments()
	var/turf/spot = run_loc_floor_bottom_left
	var/datum/round_event/lab_monkeys/event = make_event(/datum/round_event/lab_monkeys)
	var/list/monkeys = release(event, get_area(spot), list(spot), null)
	var/mob/living/carbon/monkey/thief = monkeys[1]
	var/mob/living/carbon/monkey/diver = monkeys[2]
	var/mob/living/carbon/monkey/skittish = monkeys[3]
	var/datum/component/lab_monkey_tag/thief_tag = thief.GetComponent(/datum/component/lab_monkey_tag)
	var/datum/component/lab_monkey_tag/diver_tag = diver.GetComponent(/datum/component/lab_monkey_tag)
	var/datum/component/lab_monkey_tag/skittish_tag = skittish.GetComponent(/datum/component/lab_monkey_tag)

	var/mob/living/carbon/human/mark = make_payee(get_step(spot, EAST), "Monkey Mark")
	TEST_ASSERT(thief_tag.act_out(), "LM-1 тянется к ID-карте человека рядом")
	var/mob/living/carbon/human/victim = thief_tag.snatch_victim?.resolve()
	TEST_ASSERT_NOTNULL(victim, "LM-1 выбирает, у кого сорвать карту")
	var/obj/item/card = victim.wear_id
	TEST_ASSERT_NOTNULL(card, "Карту срывают не сразу: есть шаг, чтобы отойти")
	TEST_ASSERT(thief_tag.act_out(), "LM-1 срывает карту шагом позже")
	TEST_ASSERT(card in thief.held_items, "Сорванная ID-карта у обезьяны в лапах")
	TEST_ASSERT_NULL(victim.wear_id, "Сорванной карты на человеке больше нет")

	var/obj/machinery/disposal/bin/bin = allocate(/obj/machinery/disposal/bin, get_step(spot, NORTH))
	TEST_ASSERT(diver_tag.act_out(), "LM-2 лезет в мусоропровод рядом")
	TEST_ASSERT(diver_tag.dive_timer, "LM-2 протискивается в мусоропровод не мгновенно")
	deltimer(diver_tag.dive_timer)
	TEST_ASSERT(diver_tag.finish_dive(bin), "LM-2 оказывается в мусоропроводе")
	TEST_ASSERT_EQUAL(diver.loc, bin, "LM-2 сидит внутри мусоропровода")

	TEST_ASSERT(skittish_tag.act_out(), "LM-3 убегает от человека рядом")
	TEST_ASSERT_NULL(skittish_tag.recent_handler(), "От человека без банана LM-3 только убегает")
	var/obj/item/reagent_containers/food/snacks/grown/banana/banana = allocate(/obj/item/reagent_containers/food/snacks/grown/banana)
	mark.put_in_hands(banana)
	TEST_ASSERT(skittish_tag.act_out(), "LM-3 идёт к человеку с бананом")
	TEST_ASSERT_EQUAL(skittish_tag.recent_handler(), mark, "Приманивший бананом считается тем, кто ведёт LM-3 домой")

/datum/unit_test/minor_incidents_crew/proc/sanitary_counts(blood = 0, vomit = 0, litter = 0, trash = 0)
	return list("blood" = blood, "vomit" = vomit, "litter" = litter, "trash" = trash)

/datum/unit_test/minor_incidents_crew/proc/check_sanitary_inspection()
	var/datum/round_event_control/sanitary_inspection/control = allocate(/datum/round_event_control/sanitary_inspection)
	control.inspected_area_types = list(/area/minor_crew_test_void)
	TEST_ASSERT(!length(control.get_route()), "Без медбея дрону некуда лететь")
	TEST_ASSERT(!control.director_preflight(), "Без медбея событие должно отсеиваться до траты бюджета")

	var/area/ward = get_area(run_loc_floor_bottom_left)
	var/mob/living/simple_animal/sanitary_drone/inspector = allocate(/mob/living/simple_animal/sanitary_drone, run_loc_floor_bottom_left)
	TEST_ASSERT("drone" in icon_states(inspector.icon), "У дрона есть спрайт")
	TEST_ASSERT("drone_scan" in icon_states(inspector.icon), "У дрона есть анимация сканирования")
	var/obj/effect/temp_visual/sanitary_mark/mark_type = /obj/effect/temp_visual/sanitary_mark
	TEST_ASSERT("dirt_mark" in icon_states(initial(mark_type.icon)), "У отметки грязи есть спрайт")
	TEST_ASSERT(ACCESS_SURGERY in inspector.access_card?.access, "Дрон пролетает через двери медбея")
	for(var/turf/open/floor in ward)
		for(var/atom/movable/thing as anything in floor)
			if(inspector.dirt_category(thing))
				qdel(thing)
	var/list/clean = inspector.count_dirt(ward)
	TEST_ASSERT_EQUAL(clean["blood"] + clean["vomit"] + clean["litter"] + clean["trash"], 0, "Убранный отсек чист")
	var/turf/start = run_loc_floor_bottom_left
	allocate(/obj/effect/decal/cleanable/blood, start)
	allocate(/obj/effect/decal/cleanable/vomit, get_step(start, NORTH))
	allocate(/obj/effect/decal/cleanable/dirt, get_step(start, EAST))
	allocate(/obj/item/trash/chips, get_step(start, NORTHEAST))
	var/list/dirty_turfs = list()
	var/list/counts = inspector.count_dirt(ward, dirty_turfs)
	TEST_ASSERT_EQUAL(counts["blood"], 1, "Дрон считает кровь")
	TEST_ASSERT_EQUAL(counts["vomit"], 1, "Дрон считает рвоту")
	TEST_ASSERT_EQUAL(counts["litter"], 1, "Дрон считает грязь")
	TEST_ASSERT_EQUAL(counts["trash"], 1, "Дрон считает мусор на полу")
	TEST_ASSERT_EQUAL(length(dirty_turfs), 4, "Каждая грязная клетка получает отметку")
	TEST_ASSERT_EQUAL(inspector.area_points(counts), 5, "Рвота весит два балла, остальное по одному")
	inspector.inspect_area(ward)
	TEST_ASSERT_EQUAL(length(inspector.findings), 1, "Осмотренный отсек попадает в акт")

	var/mob/living/carbon/human/janitor = make_payee(get_step(start, EAST), "Test Janitor")
	janitor.mind_initialize()
	janitor.mind.assigned_role = "Janitor"
	inspector.findings = list(list("Приёмная", sanitary_counts(blood = 1)), list("Палата", sanitary_counts()))
	var/balance = department_balance(ACCOUNT_MED)
	var/janitor_balance = personal_balance(janitor)
	inspector.finish_inspection()
	var/reward = department_balance(ACCOUNT_MED) - balance
	TEST_ASSERT(reward > 0, "Оценка 5 по среднему на отсек даёт премию медотделу")
	TEST_ASSERT(personal_balance(janitor) > janitor_balance, "За пятёрку уборщик получает личную премию")
	inspector.finish_inspection()
	TEST_ASSERT_EQUAL(department_balance(ACCOUNT_MED), balance + reward, "Премия выдаётся один раз")
	var/obj/item/paper/sanitary_report/report = locate() in start
	TEST_ASSERT_NOTNULL(report, "Дрон оставляет акт в медбее")
	allocated += report
	TEST_ASSERT(findtext(paper_text(report), "Оценка"), "В акте есть оценка")

	var/turf/tolerable_spot = get_step(run_loc_floor_top_right, SOUTH)
	var/mob/living/simple_animal/sanitary_drone/tolerable = allocate(/mob/living/simple_animal/sanitary_drone, tolerable_spot)
	tolerable.findings = list(list("Хирургия", sanitary_counts(blood = 1, litter = 1)))
	balance = department_balance(ACCOUNT_MED)
	tolerable.finish_inspection()
	TEST_ASSERT_EQUAL(department_balance(ACCOUNT_MED) - balance, reward / 2, "Оценка 4 приносит половину премии")
	allocated += locate(/obj/item/paper/sanitary_report) in tolerable_spot

	var/turf/dirty_spot = run_loc_floor_top_right
	var/mob/living/simple_animal/sanitary_drone/strict = allocate(/mob/living/simple_animal/sanitary_drone, dirty_spot)
	strict.findings = list(list("Хирургия", sanitary_counts(blood = 12, vomit = 3, litter = 4, trash = 2)))
	balance = department_balance(ACCOUNT_MED)
	strict.finish_inspection()
	TEST_ASSERT_EQUAL(department_balance(ACCOUNT_MED), balance, "Грязный медбей остаётся без премии")
	var/obj/item/paper/sanitary_report/bad_report = locate() in dirty_spot
	TEST_ASSERT_NOTNULL(bad_report, "Грязный медбей тоже получает акт")
	allocated += bad_report
	TEST_ASSERT(findtext(paper_text(bad_report), "не начисляется"), "Акт объясняет, почему премии нет")

	check_sanitary_aggression(ward)

/datum/unit_test/minor_incidents_crew/proc/check_sanitary_aggression(area/ward)
	var/turf/attack_spot = get_step(run_loc_floor_top_right, WEST)
	var/mob/living/carbon/human/attacker = allocate(/mob/living/carbon/human, get_step(attack_spot, SOUTH))
	var/obj/item/crowbar/crowbar = allocate(/obj/item/crowbar)
	var/mob/living/simple_animal/sanitary_drone/plain = allocate(/mob/living/simple_animal/sanitary_drone, attack_spot)
	plain.attacked_by(crowbar, attacker)
	TEST_ASSERT(!plain.aggression, "Удар моба без игрока не считается нападением на инспектора")

	var/mob/living/simple_animal/sanitary_drone/test_any_attacker/victim = allocate(/mob/living/simple_animal/sanitary_drone/test_any_attacker, attack_spot)
	victim.begin_inspection(list(ward))
	TEST_ASSERT(victim.stop_timer, "Начатая проверка ведёт дрона по маршруту")
	victim.adjustBruteLoss(5)
	TEST_ASSERT(!victim.aggression && !victim.finished, "Урон без нападающего не срывает и не портит проверку")
	victim.attacked_by(crowbar, attacker)
	TEST_ASSERT(victim.aggression && !victim.finished, "Удар игрока записывается, но облёт продолжается")
	victim.findings = list(list("Приёмная", sanitary_counts()))
	var/balance = department_balance(ACCOUNT_MED)
	victim.finish_inspection()
	var/reward = department_balance(ACCOUNT_MED) - balance
	TEST_ASSERT(reward > 0 && victim.reward_paid == reward, "Чистый медбей после нападения получает премию за четвёрку")
	var/obj/item/paper/sanitary_report/aggression_report = locate() in attack_spot
	TEST_ASSERT_NOTNULL(aggression_report, "Акт печатается и после нападения")
	allocated += aggression_report
	TEST_ASSERT(findtext(paper_text(aggression_report), "нападение"), "Акт фиксирует нападение на инспектора")

	var/turf/flight_spot = get_step(run_loc_floor_bottom_left, NORTHEAST)
	var/mob/living/simple_animal/sanitary_drone/flyer = allocate(/mob/living/simple_animal/sanitary_drone, flight_spot)
	flyer.route = list(ward)
	flyer.stop_index = 1
	flyer.travel_to(run_loc_floor_top_right)
	TEST_ASSERT(istype(SSmove_manager.processing_on(flyer, SSmovement), /datum/move_loop/has_target/jps), "Между отсеками дрон летит по пути через двери, а не прыгает")
	flyer.on_enter_area(flyer, ward)
	TEST_ASSERT(flyer.stop_timer, "Влетев в отсек маршрута, дрон готовится к осмотру")
	flyer.arrive()
	TEST_ASSERT_NULL(SSmove_manager.processing_on(flyer, SSmovement), "Над отсеком дрон зависает")
	TEST_ASSERT_EQUAL(length(flyer.findings), 1, "Долетевший дрон осматривает отсек")

	var/turf/wreck_spot = get_step(attack_spot, WEST)
	var/mob/living/simple_animal/sanitary_drone/wreck = allocate(/mob/living/simple_animal/sanitary_drone, wreck_spot)
	wreck.findings = list(list("Приёмная", sanitary_counts()))
	balance = department_balance(ACCOUNT_MED)
	wreck.death()
	TEST_ASSERT_EQUAL(department_balance(ACCOUNT_MED), balance, "Уничтоженный дрон премию не выдаёт")
	var/obj/item/paper/sanitary_report/wreck_report = locate() in wreck_spot
	TEST_ASSERT_NOTNULL(wreck_report, "Уничтоженный дрон оставляет акт о прерванной проверке")
	allocated += wreck_report
	TEST_ASSERT(findtext(paper_text(wreck_report), "прервана"), "Акт объясняет, что проверка прервана")

/datum/unit_test/minor_incidents_crew/proc/check_lost_pet()
	var/datum/round_event_control/lost_pet/control = allocate(/datum/round_event_control/lost_pet)
	control.hideout_area_types = list(/area/minor_crew_test_void)
	control.stray_home_types = list(/area/minor_crew_test_void)
	TEST_ASSERT(!control.director_preflight(), "Без техтоннелей питомцу негде потеряться")

	var/area/home = get_area(run_loc_floor_bottom_left)
	var/turf/hideout = run_loc_floor_top_right
	var/mob/living/simple_animal/pet/fox/Renault/renault = allocate(/mob/living/simple_animal/pet/fox/Renault, run_loc_floor_bottom_left)
	var/mob/living/simple_animal/pet/cat/moro/donor_pet = allocate(/mob/living/simple_animal/pet/cat/moro, run_loc_floor_bottom_left)
	TEST_ASSERT(control.is_station_pet(renault), "Renault - станционный питомец")
	TEST_ASSERT(!control.is_station_pet(donor_pet), "Донатный питомец из маяка не теряется")

	var/datum/round_event/lost_pet/event = make_event(/datum/round_event/lost_pet)
	event.lose_pet(renault, home, hideout, list(/area/command/heads_quarters/hop, "Head of Personnel", "отдел кадров"))
	TEST_ASSERT_EQUAL(renault.loc, hideout, "Питомец оказывается в техтоннелях")
	TEST_ASSERT_EQUAL(event.head_title, "Head of Personnel", "Событие знает главу отдела питомца")

	var/obj/item/paper/lost_pet_flyer/flyer = allocate(/obj/item/paper/lost_pet_flyer, run_loc_floor_bottom_left)
	flyer.describe(renault, home.name, 150)
	TEST_ASSERT("flyer" in icon_states(flyer.icon), "У листовки есть спрайт")
	TEST_ASSERT(flyer.pet_photo in flyer.update_overlays(), "На листовке фотография питомца")
	TEST_ASSERT(findtext(paper_text(flyer), renault.name), "На листовке кличка питомца")
	TEST_ASSERT(findtext(paper_text(flyer), "погладить"), "Листовка объясняет, как увести питомца за собой")

	var/mob/living/carbon/human/courier = make_payee(get_step(hideout, WEST), "Pet Courier")
	TEST_ASSERT_EQUAL(minor_crew_public_name(courier), "Pet Courier", "В объявлении имя с ID-карты, а не настоящее имя")
	var/mob/living/carbon/human/head = allocate(/mob/living/carbon/human)
	head.mind_initialize()
	head.mind.assigned_role = "Head of Personnel"
	var/datum/component/mood/mood = head.GetComponent(/datum/component/mood) || head.AddComponent(/datum/component/mood)

	event.home_type = /area/minor_crew_test_void
	event.next_ping = world.time
	courier.start_pulling(renault)
	event.check_return()
	TEST_ASSERT(!event.resolved, "Вне дома питомец не засчитывается")
	TEST_ASSERT_EQUAL(event.last_handler?.resolve(), courier, "Событие запоминает, кто тащит питомца")
	TEST_ASSERT(event.next_ping > world.time, "Датчик ошейника назначает следующую отметку")
	courier.stop_pulling()
	event.home_type = home.type
	var/balance = personal_balance(courier)
	event.check_return()
	TEST_ASSERT(event.resolved, "Питомец дома - событие закрыто")
	var/reward = personal_balance(courier) - balance
	TEST_ASSERT(reward > 0, "Приведший получает вознаграждение, даже если отпустил питомца у порога")
	event.check_return()
	event.end()
	TEST_ASSERT_EQUAL(personal_balance(courier), balance + reward, "Вознаграждение выдаётся один раз")
	TEST_ASSERT(istype(mood.mood_events["lost_pet_returned"], /datum/mood_event/lost_pet_returned), "Глава отдела радуется возвращению питомца")
	TEST_ASSERT(!QDELETED(renault), "Питомец остаётся в мире")

	var/datum/round_event/lost_pet/stray_event = make_event(/datum/round_event/lost_pet)
	var/mob/living/simple_animal/pet/stray = stray_event.make_stray(hideout, home, list(/area/medical, "Chief Medical Officer", "медицинский отдел"))
	allocated += stray
	TEST_ASSERT(istype(stray.pcollar, /obj/item/clothing/neck/petcollar/lost_pet), "Потерявшийся щенок или котёнок носит ошейник отдела")
	TEST_ASSERT(findtext(stray.pcollar.desc, "медицинский отдел"), "На ошейнике написано, чей это питомец")
	stray_event.lose_pet(stray, home, hideout, null)
	stray_event.home_type = home.type
	balance = personal_balance(courier)
	stray_event.check_return()
	TEST_ASSERT(stray_event.resolved, "Питомец, пришедший домой сам, закрывает событие")
	TEST_ASSERT_EQUAL(personal_balance(courier), balance, "Прохожий рядом, который питомца не вёл, вознаграждения не получает")

	var/datum/round_event/lost_pet/doomed_event = make_event(/datum/round_event/lost_pet)
	var/mob/living/simple_animal/pet/doomed = doomed_event.make_stray(hideout, home, null)
	allocated += doomed
	doomed_event.lose_pet(doomed, home, hideout, null)
	doomed_event.home_type = home.type
	doomed.death()
	doomed_event.check_return()
	TEST_ASSERT(doomed_event.resolved, "Гибель питомца закрывает событие")
	TEST_ASSERT_EQUAL(personal_balance(courier), balance, "За мёртвого питомца вознаграждения нет")

/// Погладивший или угостивший уводит потерявшегося питомца за собой.
/datum/unit_test/minor_incidents_crew/proc/check_lost_pet_lure()
	var/turf/hideout = run_loc_floor_top_right
	var/mob/living/simple_animal/pet/fox/Renault/renault = allocate(/mob/living/simple_animal/pet/fox/Renault, hideout)
	var/datum/round_event/lost_pet/event = make_event(/datum/round_event/lost_pet)
	event.lose_pet(renault, get_area(run_loc_floor_bottom_left), hideout, null)
	event.home_type = /area/minor_crew_test_void
	var/mob/living/carbon/human/finder = allocate(/mob/living/carbon/human, get_step(hideout, WEST))
	finder.a_intent = INTENT_HELP
	renault.attack_hand(finder)
	var/datum/component/lost_pet_follow/follow = renault.GetComponent(/datum/component/lost_pet_follow)
	TEST_ASSERT_NOTNULL(follow, "Погладивший уводит питомца за собой")
	TEST_ASSERT(!renault.wander, "Ведомый питомец не бродит сам по себе")
	TEST_ASSERT_NOTNULL(SSmove_manager.processing_on(renault, SSmovement), "Питомец идёт следом за погладившим")
	event.check_return()
	TEST_ASSERT_EQUAL(event.last_handler?.resolve(), finder, "Тот, за кем идёт питомец, считается приведшим")
	qdel(follow)
	TEST_ASSERT(renault.wander, "Отпущенный питомец снова бродит сам")

	var/obj/item/reagent_containers/food/snacks/cookie/cookie = allocate(/obj/item/reagent_containers/food/snacks/cookie)
	finder.put_in_hands(cookie)
	renault.attackby(cookie, finder)
	TEST_ASSERT(QDELETED(cookie), "Угощение съедено")
	TEST_ASSERT_NOTNULL(renault.GetComponent(/datum/component/lost_pet_follow), "Угостивший тоже уводит питомца за собой")
	event.end()
	TEST_ASSERT_NULL(renault.GetComponent(/datum/component/lost_pet_follow), "После события питомец больше не ходит следом")

	var/mob/living/simple_animal/pet/fox/Renault/possessed = allocate(/mob/living/simple_animal/pet/fox/Renault, hideout)
	var/datum/round_event/lost_pet/possessed_event = make_event(/datum/round_event/lost_pet)
	possessed_event.lose_pet(possessed, get_area(run_loc_floor_bottom_left), hideout, null)
	possessed.attack_hand(finder)
	SEND_SIGNAL(possessed, COMSIG_MOB_CLIENT_LOGIN, null)
	TEST_ASSERT_NULL(possessed.GetComponent(/datum/component/lost_pet_follow), "Питомец, которым стал управлять игрок, перестаёт ходить следом")
	possessed.mind_initialize()
	possessed.attack_hand(finder)
	TEST_ASSERT_NULL(possessed.GetComponent(/datum/component/lost_pet_follow), "Питомца под управлением игрока лаской не увести")
	var/obj/item/reagent_containers/food/snacks/cookie/second_cookie = allocate(/obj/item/reagent_containers/food/snacks/cookie)
	finder.put_in_hands(second_cookie)
	possessed.attackby(second_cookie, finder)
	TEST_ASSERT_NULL(possessed.GetComponent(/datum/component/lost_pet_follow), "Питомца под управлением игрока угощением не увести")
	possessed_event.end()
