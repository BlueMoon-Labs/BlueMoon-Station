/// ИИ слуги не берёт прохожих и хозяина, берёт указанную хозяином цель, а обидчиков хозяина и слуги запоминает.
/datum/unit_test/hk50_servant_targets

/datum/unit_test/hk50_servant_targets/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/mob/living/simple_animal/hostile/hk50/servant = allocate(/mob/living/simple_animal/hostile/hk50, origin)
	var/mob/living/carbon/human/master = allocate(/mob/living/carbon/human, locate(origin.x + 1, origin.y + 1, origin.z))
	var/mob/living/carbon/human/bystander = allocate(/mob/living/carbon/human, locate(origin.x + 3, origin.y, origin.z))
	var/mob/living/carbon/human/marked = allocate(/mob/living/carbon/human, locate(origin.x + 3, origin.y + 3, origin.z))
	var/mob/living/carbon/human/shooter = allocate(/mob/living/carbon/human, locate(origin.x, origin.y + 4, origin.z))
	var/mob/living/carbon/human/puncher = allocate(/mob/living/carbon/human, locate(origin.x + 1, origin.y, origin.z))
	servant.AddComponent(/datum/component/hk50_servant, master)
	var/datum/ai_controller/controller = servant.ai_controller
	TEST_ASSERT_NOTNULL(controller, "У слуги HK-50 нет ИИ-контроллера")
	var/datum/ai_behavior/find_potential_targets/finder = GET_AI_BEHAVIOR(/datum/ai_behavior/find_potential_targets)

	TEST_ASSERT(!servant.CanAttack(bystander), "Слуга готов напасть на прохожего")
	TEST_ASSERT(!servant.CanAttack(master), "Слуга готов напасть на хозяина")
	finder.perform(0.5, controller, BB_AI_CURRENT_TARGET, BB_AI_TARGETING_STRATEGY, BB_AI_TARGET_HIDING_LOCATION)
	TEST_ASSERT_NULL(controller.blackboard[BB_AI_CURRENT_TARGET], "ИИ слуги взял цель без приказа и без нападения")

	SEND_SIGNAL(master, COMSIG_LIVING_ATTACKER_SET, bystander)
	TEST_ASSERT(servant.CanAttack(bystander), "Напавший на хозяина не стал целью слуги")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_CURRENT_TARGET], bystander, "ИИ слуги не взялся за напавшего на хозяина")

	master.a_intent = INTENT_HELP
	master.pointed(marked)
	TEST_ASSERT(!servant.CanAttack(marked), "Жест вне боевого интента стал приказом")
	master.a_intent = INTENT_HARM
	master.pointed(marked)
	finder.perform(0.5, controller, BB_AI_CURRENT_TARGET, BB_AI_TARGETING_STRATEGY, BB_AI_TARGET_HIDING_LOCATION)
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_CURRENT_TARGET], marked, "ИИ слуги не взял цель, указанную хозяином")
	TEST_ASSERT_EQUAL(servant.target, marked, "Цель ИИ не дошла до моба слуги")

	var/obj/item/projectile/beam/laser/shot = allocate(/obj/item/projectile/beam/laser, get_turf(shooter))
	shot.firer = shooter
	master.bullet_act(shot, BODY_ZONE_CHEST)
	TEST_ASSERT(servant.CanAttack(shooter), "Стрелявший в хозяина не стал целью слуги")
	puncher.a_intent = INTENT_HARM
	servant.attack_hand(puncher)
	TEST_ASSERT(servant.CanAttack(puncher), "Ударивший слугу не стал его целью")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_CURRENT_TARGET], marked, "Слуга бросил приказ ради обидчика")

	var/obj/item/projectile/beam/laser/stray = allocate(/obj/item/projectile/beam/laser, get_turf(master))
	stray.firer = master
	servant.bullet_act(stray)
	TEST_ASSERT(!servant.CanAttack(master), "Случайный выстрел хозяина сделал его целью слуги")

	marked.death()
	finder.perform(0.5, controller, BB_AI_CURRENT_TARGET, BB_AI_TARGETING_STRATEGY, BB_AI_TARGET_HIDING_LOCATION)
	var/atom/next_target = controller.blackboard[BB_AI_CURRENT_TARGET]
	TEST_ASSERT(next_target in list(bystander, shooter, puncher), "После гибели указанной цели слуга не взялся за обидчиков (цель: [next_target])")

/// Слуга не стреляет сквозь хозяина и прохожих.
/datum/unit_test/hk50_servant_fire_lane

/datum/unit_test/hk50_servant_fire_lane/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/mob/living/simple_animal/hostile/hk50/servant = allocate(/mob/living/simple_animal/hostile/hk50, origin)
	var/mob/living/carbon/human/master = allocate(/mob/living/carbon/human, locate(origin.x + 2, origin.y, origin.z))
	var/mob/living/carbon/human/marked = allocate(/mob/living/carbon/human, locate(origin.x + 4, origin.y, origin.z))
	servant.AddComponent(/datum/component/hk50_servant, master)
	master.a_intent = INTENT_HARM
	master.pointed(marked)
	TEST_ASSERT(servant.CanAttack(marked), "Указанная цель недоступна слуге")
	TEST_ASSERT(servant.CheckRangedFireLane(marked), "Слуга стреляет сквозь хозяина")

	master.forceMove(locate(origin.x + 2, origin.y + 2, origin.z))
	TEST_ASSERT(!servant.CheckRangedFireLane(marked), "Хозяин вне линии огня всё ещё мешает стрелять")

	allocate(/mob/living/carbon/human, locate(origin.x + 2, origin.y, origin.z))
	TEST_ASSERT(servant.CheckRangedFireLane(marked), "Слуга стреляет сквозь прохожего")

/// Слуга без цели идёт за хозяином, а рядом с хозяином стоит.
/datum/unit_test/hk50_servant_follow

/datum/unit_test/hk50_servant_follow/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/mob/living/simple_animal/hostile/hk50/servant = allocate(/mob/living/simple_animal/hostile/hk50, origin)
	var/mob/living/carbon/human/master = allocate(/mob/living/carbon/human, locate(origin.x + 4, origin.y + 4, origin.z))
	servant.AddComponent(/datum/component/hk50_servant, master)
	var/datum/ai_controller/controller = servant.ai_controller

	controller.SelectBehaviors(0.5)
	TEST_ASSERT_EQUAL(controller.current_movement_target, master, "Слуга не пошёл за ушедшим хозяином")

	master.forceMove(locate(origin.x + HK50_SERVANT_FOLLOW_DISTANCE, origin.y, origin.z))
	controller.SelectBehaviors(0.5)
	TEST_ASSERT(controller.current_movement_target != master, "Слуга идёт к хозяину, который и так рядом")

/// Пара одна на хозяина и гибнет без взрыва после отсчёта: с хозяином, при его удалении и перепрошивке, по сроку службы.
/datum/unit_test/hk50_servant_lifecycle

/datum/unit_test/hk50_servant_lifecycle/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/mob/living/carbon/human/master = allocate(/mob/living/carbon/human, origin)
	master.mind_initialize()
	allocated += master.mind
	var/list/pair = hk50_summon_servant_pair(master, origin)
	allocated += pair
	TEST_ASSERT_EQUAL(length(pair), HK50_SERVANT_PAIR_SIZE, "Вызов не дал пару слуг")
	var/mob/living/simple_animal/hostile/hk50/lead = pair[1]
	var/datum/component/hk_loyalty/loyalty = lead.GetComponent(/datum/component/hk_loyalty)
	TEST_ASSERT_EQUAL(loyalty?.get_master(), master.mind, "Блок лояльности слуги не указывает на хозяина")
	TEST_ASSERT_EQUAL(length(hk50_servants_of(master)), HK50_SERVANT_PAIR_SIZE, "Слуги не числятся за хозяином")
	TEST_ASSERT_NULL(hk50_summon_servant_pair(master, origin), "Хозяин вызвал вторую пару при живой первой")

	var/mob/living/carbon/human/reprogrammed_master = allocate(/mob/living/carbon/human, origin)
	var/mob/living/simple_animal/hostile/hk50/reprogrammed_servant = allocate(/mob/living/simple_animal/hostile/hk50, origin)
	reprogrammed_servant.AddComponent(/datum/component/hk50_servant, reprogrammed_master)
	var/mob/living/carbon/human/deleted_master = allocate(/mob/living/carbon/human, origin)
	var/mob/living/simple_animal/hostile/hk50/orphan = allocate(/mob/living/simple_animal/hostile/hk50, origin)
	orphan.AddComponent(/datum/component/hk50_servant, deleted_master)
	var/mob/living/carbon/human/patient_master = allocate(/mob/living/carbon/human, origin)
	var/mob/living/simple_animal/hostile/hk50/expiring = allocate(/mob/living/simple_animal/hostile/hk50, origin)
	expiring.AddComponent(/datum/component/hk50_servant, patient_master, 1)
	var/mob/living/carbon/human/witness = allocate(/mob/living/carbon/human, locate(origin.x + 1, origin.y, origin.z))
	for(var/mob/living/doomed_master as anything in list(master, reprogrammed_master, deleted_master))
		SEND_SIGNAL(doomed_master, COMSIG_LIVING_ATTACKER_SET, witness)

	master.death()
	SEND_SIGNAL(reprogrammed_master, COMSIG_HK_MASTER_CHANGED, null, null)
	qdel(deleted_master)
	var/list/doomed = pair + list(reprogrammed_servant, orphan, expiring)
	for(var/mob/living/simple_animal/hostile/hk50/servant as anything in pair + list(reprogrammed_servant, orphan))
		TEST_ASSERT(!QDELETED(servant) && servant.stat != DEAD, "Слуга погиб без обратного отсчёта")
		TEST_ASSERT(!servant.CanAttack(witness), "Слуга на отсчёте продолжает бить обидчика хозяина")

	var/deadline = world.time + HK50_SERVANT_SELF_DESTRUCT_DELAY + 10 SECONDS
	while(world.time < deadline && count_alive(doomed))
		sleep(world.tick_lag)
	TEST_ASSERT_EQUAL(count_alive(doomed), 0, "Слуги не самоуничтожились")
	TEST_ASSERT_EQUAL(witness.getBruteLoss() + witness.getFireLoss(), 0, "Самоуничтожение слуг ранило стоящего рядом")
	TEST_ASSERT(isfloorturf(origin), "Самоуничтожение слуг разрушило пол")

	var/list/second_pair = hk50_summon_servant_pair(patient_master, origin)
	allocated += second_pair
	TEST_ASSERT_EQUAL(length(second_pair), HK50_SERVANT_PAIR_SIZE, "После истечения пары хозяин не может вызвать новую")

/datum/unit_test/hk50_servant_lifecycle/proc/count_alive(list/servants)
	. = 0
	for(var/mob/living/servant as anything in servants)
		if(!QDELETED(servant) && servant.stat != DEAD)
			.++

/// Жест хозяина на себя или на слугу снимает приказ, а обидчики хозяина остаются целями.
/datum/unit_test/hk50_servant_cancel_order

/datum/unit_test/hk50_servant_cancel_order/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/mob/living/carbon/human/master = allocate(/mob/living/carbon/human, origin)
	var/mob/living/carbon/human/marked = allocate(/mob/living/carbon/human, locate(origin.x + 3, origin.y, origin.z))
	var/mob/living/carbon/human/attacker = allocate(/mob/living/carbon/human, locate(origin.x, origin.y + 3, origin.z))
	var/mob/living/simple_animal/hostile/hk50/servant = allocate(/mob/living/simple_animal/hostile/hk50, locate(origin.x + 1, origin.y, origin.z))
	var/mob/living/simple_animal/hostile/hk50/partner = allocate(/mob/living/simple_animal/hostile/hk50, locate(origin.x + 1, origin.y + 1, origin.z))
	servant.AddComponent(/datum/component/hk50_servant, master)
	partner.AddComponent(/datum/component/hk50_servant, master)
	SEND_SIGNAL(master, COMSIG_LIVING_ATTACKER_SET, attacker)
	master.a_intent = INTENT_HARM
	master.pointed(marked)
	TEST_ASSERT(servant.CanAttack(marked), "Приказ не принят")

	master.a_intent = INTENT_HELP
	master.pointed(master)
	TEST_ASSERT(!servant.CanAttack(marked), "Жест на себя не снял приказ")
	TEST_ASSERT(servant.CanAttack(attacker), "Отмена приказа простила обидчика хозяина")

	master.a_intent = INTENT_HARM
	master.pointed(marked)
	master.pointed(partner)
	TEST_ASSERT(!servant.CanAttack(marked), "Жест на слугу не снял приказ")
	TEST_ASSERT(!partner.CanAttack(marked), "Жест на слугу не снял приказ у самого слуги")

/// Хозяин ушёл на другой уровень - слуга прилетает к нему на двигателях, а на том же уровне и на ЦК остаётся на месте.
/datum/unit_test/hk50_servant_catch_up

/datum/unit_test/hk50_servant_catch_up/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/mob/living/carbon/human/master = allocate(/mob/living/carbon/human, origin)
	var/mob/living/simple_animal/hostile/hk50/servant = allocate(/mob/living/simple_animal/hostile/hk50, locate(origin.x + 2, origin.y, origin.z))
	var/datum/component/hk50_servant/servitude = servant.AddComponent(/datum/component/hk50_servant, master)
	TEST_ASSERT(!servitude.catch_up(), "Слуга улетел, хотя хозяин на его уровне")

	var/turf/elsewhere
	var/turf/centcom_spot
	for(var/obj/effect/landmark/spot as anything in GLOB.landmarks_list)
		var/turf/candidate = get_turf(spot)
		if(!candidate || candidate.z == origin.z)
			continue
		if(!elsewhere && is_station_level(candidate.z))
			elsewhere = candidate
		if(!centcom_spot && is_centcom_level(candidate.z))
			centcom_spot = candidate
	TEST_ASSERT_NOTNULL(elsewhere, "Нет турфа станции")
	TEST_ASSERT_NOTNULL(centcom_spot, "Нет турфа ЦК")
	master.forceMove(centcom_spot)
	TEST_ASSERT(!servitude.catch_up(), "Слуга улетел за хозяином на ЦК")
	TEST_ASSERT_EQUAL(servant.z, origin.z, "Слуга покинул свой уровень вслед за хозяином на ЦК")
	master.forceMove(elsewhere)
	TEST_ASSERT_NOTNULL(servitude.catch_up_timer, "Уход хозяина на другой уровень не завёл таймер погони")
	TEST_ASSERT(servitude.catch_up(), "Слуга не полетел за хозяином")
	TEST_ASSERT_EQUAL(servant.z, master.z, "Слуга не на уровне хозяина")
	TEST_ASSERT(get_dist(servant, master) <= 1, "Слуга приземлился не рядом с хозяином")

/datum/antagonist/hk50_servant/test_fixture/poll_replacement(mob/living/body)
	return list()

/// HK-50 с разумом: лазер в руке, канал HK с HK-47 без HTML и без бессознательных, при уходе игрока без замены корпус самоуничтожается, а HK-47 получает очки назад без повторной покупки.
/datum/unit_test/hk50_ghost_servant

/datum/unit_test/hk50_ghost_servant/Run()
	var/datum/antagonist/hk47/contract_fixture/hunter = allocate_hk47_hunter()
	var/mob/living/carbon/human/master = hunter.owner.current
	var/mob/living/carbon/human/servant = hunter.create_ghost_servant(run_loc_floor_top_right, null)
	allocated += list(servant, servant.mind)
	TEST_ASSERT_NOTNULL(locate(/obj/item/organ/cyberimp/arm/gun/laser/hk50) in servant.internal_organs, "У HK-50 с разумом нет лазера в руке")
	var/datum/action/innate/hk_link/servant_link = locate() in servant.actions
	var/datum/action/innate/hk_link/master_link = locate() in master.actions
	TEST_ASSERT_NOTNULL(servant_link, "У HK-50 нет канала HK")
	TEST_ASSERT_NOTNULL(master_link, "У HK-47 нет канала HK")
	TEST_ASSERT(master in servant_link.listeners(), "Канал HK-50 не слышит HK-47")
	TEST_ASSERT(servant in master_link.listeners(), "Канал HK-47 не слышит HK-50")
	var/line = master_link.hk_link_send(master, "<b>проверка</b> канала")
	TEST_ASSERT(istext(line), "Сообщение по каналу HK не ушло")
	TEST_ASSERT(!findtext(line, "<b>проверка"), "Канал HK пропустил сырой HTML: [line]")
	master.set_stat(UNCONSCIOUS)
	var/unconscious_line = master_link.hk_link_send(master, "без сознания")
	master.set_stat(CONSCIOUS)
	TEST_ASSERT(!unconscious_line, "HK-47 без сознания говорит по каналу HK")

	var/datum/antagonist/hk50_servant/servitude = servant.mind.has_antag_datum(/datum/antagonist/hk50_servant)
	SEND_SIGNAL(servant, COMSIG_MOB_LOGOUT)
	TEST_ASSERT_NOTNULL(servitude.away_timer, "Уход игрока не завёл таймер замены")
	SEND_SIGNAL(servant, COMSIG_MOB_LOGIN)
	TEST_ASSERT_NULL(servitude.away_timer, "Возвращение игрока не сняло таймер замены")

	var/mob/living/carbon/human/abandoned = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	abandoned.set_species(/datum/species/ipc/hk/hk50)
	abandoned.mind_initialize()
	allocated += abandoned.mind
	var/datum/antagonist/hk50_servant/test_fixture/fixture = new
	fixture.hunter_ref = WEAKREF(hunter)
	abandoned.mind.add_antag_datum(fixture)
	var/datum/hk47_upgrade/ghost_upgrade = GLOB.hk47_upgrades["ghost_servant"]
	hunter.upgrades[ghost_upgrade.id] = 1
	var/points_before = hunter.points
	TEST_ASSERT(!fixture.replace_player(abandoned, hunter), "Без замены HK-50 остался в строю")
	TEST_ASSERT_EQUAL(hunter.points, points_before + ghost_upgrade.price(hunter), "HK-47 не получил очки за брошенного HK-50")
	TEST_ASSERT(QDELETED(abandoned) || abandoned.stat == DEAD, "Брошенный корпус HK-50 не самоуничтожился")
	TEST_ASSERT_EQUAL(hunter.upgrades[ghost_upgrade.id], 1, "Возврат очков за ушедшего игрока снял разовую покупку")
	TEST_ASSERT_NOTNULL(ghost_upgrade.refusal(hunter), "После возврата HK-50 с разумом можно купить снова")
