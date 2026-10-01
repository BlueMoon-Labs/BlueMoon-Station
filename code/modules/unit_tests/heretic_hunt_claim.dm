/datum/antagonist/heretic/claim_fixture

/datum/antagonist/heretic/claim_fixture/claim_is_crew_player(mob/living/carbon/human/victim)
	return TRUE

/datum/unit_test/heretic_hunt_claim
	var/datum/space_level/test_level
	var/list/previous_traits

/datum/unit_test/heretic_hunt_claim/Destroy()
	if(test_level)
		test_level.traits = previous_traits
	return ..()

/datum/unit_test/heretic_hunt_claim/proc/allocate_victim(turf/location)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, location)
	var/datum/mind/soul = allocate_mind()
	soul.current = victim
	victim.mind = soul
	return victim

/// Касание сердцем делает поверженного новой целью, а падение цели в крит рядом оповещает еретика.
/datum/unit_test/heretic_hunt_claim/Run()
	test_level = SSmapping.get_level(run_loc_floor_bottom_left.z)
	previous_traits = test_level.traits
	test_level.traits = previous_traits.Copy()
	test_level.traits[ZTRAIT_STATION] = TRUE
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/datum/mind/user_mind = allocate_mind()
	user_mind.current = user
	user.mind = user_mind
	var/datum/antagonist/heretic/claim_fixture/heretic = allocate(/datum/antagonist/heretic/claim_fixture)
	heretic.owner = user_mind
	heretic.silent = TRUE
	user_mind.antag_datums = list(heretic)
	var/obj/item/living_heart/heart = allocate(/obj/item/living_heart, run_loc_floor_bottom_left)
	user.put_in_hands(heart)

	var/mob/living/carbon/human/victim = allocate_victim(get_step(run_loc_floor_bottom_left, EAST))
	heart.attack(victim, user)
	TEST_ASSERT_NULL(heretic.hunt_target, "Стоящего на ногах сердце не принимает.")
	victim.Paralyze(10 SECONDS)
	heart.attack(victim, user)
	TEST_ASSERT_EQUAL(heretic.hunt_target, victim.mind, "Обездвиженный член экипажа становится целью.")
	TEST_ASSERT(!COOLDOWN_FINISHED(heretic, hunt_refresh_cooldown), "Касание запускает перезарядку смены цели.")

	var/mob/living/carbon/human/second_victim = allocate_victim(get_step(run_loc_floor_bottom_left, NORTH))
	second_victim.Paralyze(10 SECONDS)
	heart.attack(second_victim, user)
	TEST_ASSERT_EQUAL(heretic.hunt_target, victim.mind, "До конца перезарядки цель не меняется.")
	COOLDOWN_RESET(heretic, hunt_refresh_cooldown)
	second_victim.death()
	heart.attack(second_victim, user)
	TEST_ASSERT_EQUAL(heretic.hunt_target, victim.mind, "Мёртвого сердце целью не делает.")

	TEST_ASSERT(COOLDOWN_FINISHED(heretic, hunt_downed_alert_cooldown), "Оповещения ещё не было.")
	victim.adjustBruteLoss(150)
	TEST_ASSERT(victim.stat >= SOFT_CRIT, "Ранения вводят цель в крит.")
	TEST_ASSERT(!COOLDOWN_FINISHED(heretic, hunt_downed_alert_cooldown), "Крит цели рядом оповещает еретика.")

	COOLDOWN_RESET(heretic, hunt_downed_alert_cooldown)
	victim.fully_heal()
	TEST_ASSERT_EQUAL(victim.stat, CONSCIOUS, "Лечение выводит цель из крита.")
	heretic.set_hunt_target(null)
	victim.adjustBruteLoss(150)
	TEST_ASSERT(COOLDOWN_FINISHED(heretic, hunt_downed_alert_cooldown), "Снятая цель больше не отслеживается.")

/// Касание обезвреженной цели сердцем проводит обряд без руны и возвращает сердце в руку.
/datum/unit_test/heretic_hunt_claim/heart_rite/Run()
	test_level = SSmapping.get_level(run_loc_floor_bottom_left.z)
	previous_traits = test_level.traits
	test_level.traits = previous_traits.Copy()
	test_level.traits[ZTRAIT_STATION] = TRUE
	var/list/previous_sacrificed = GLOB.heretic_sacrificed_minds.Copy()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/datum/mind/user_mind = allocate_mind()
	user_mind.current = user
	user.mind = user_mind
	var/datum/antagonist/heretic/ritual_fixture/heretic = allocate(/datum/antagonist/heretic/ritual_fixture)
	heretic.owner = user_mind
	heretic.silent = TRUE
	user_mind.antag_datums = list(heretic)
	heretic.test_return_turf = run_loc_floor_top_right
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/basic)
	var/obj/item/living_heart/heart = allocate(/obj/item/living_heart, run_loc_floor_bottom_left)
	TEST_ASSERT(heart.bind(user_mind), "Сердце привязано к еретику.")
	user.put_in_hands(heart)
	var/turf/rite_turf = get_step(run_loc_floor_bottom_left, EAST)
	var/mob/living/carbon/human/victim = allocate_victim(rite_turf)
	heretic.set_hunt_target(victim.mind)

	TEST_ASSERT(!heretic.begin_heart_rite(user, victim, heart), "Стоящую цель сердце не принимает.")
	TEST_ASSERT_EQUAL(heart.loc, user, "После отказа сердце остаётся в руке.")
	TEST_ASSERT_NULL(locate(/obj/effect/eldritch) in rite_turf, "Отказ не оставляет круга.")

	victim.handcuffed = allocate(/obj/item/restraints/handcuffs, victim)
	victim.update_handcuffed()
	var/points_before = heretic.knowledge_points
	TEST_ASSERT(heretic.begin_heart_rite(user, victim, heart), "Связанная цель принимается без начерченной руны.")
	TEST_ASSERT_EQUAL(heretic.total_sacrifices, 1, "Обряд сердцем засчитан как жертвоприношение.")
	TEST_ASSERT_EQUAL(heretic.knowledge_points, points_before + HERETIC_LIVE_SACRIFICE_KNOWLEDGE, "Награда та же, что на руне.")
	TEST_ASSERT_EQUAL(heart.loc, user, "Сердце возвращается в руку.")
	TEST_ASSERT_NULL(locate(/obj/effect/eldritch) in rite_turf, "Круг исчезает после обряда.")
	var/datum/heretic_mansus_visit/visit = GLOB.heretic_mansus_visits[victim.mind]
	TEST_ASSERT_NOTNULL(visit, "Жертва уходит в Мансус.")
	allocated += visit
	visit.finish()
	GLOB.heretic_sacrificed_minds = previous_sacrificed

/// Поиск цели сердцем предлагает ссылку на смену цели, а затянувшаяся охота один раз подсказывает сменить её.
/datum/unit_test/heretic_hunt_retarget_hint/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	var/obj/item/living_heart/heart = allocate(/obj/item/living_heart, get_turf(user))
	user.put_in_hands(heart)
	TEST_ASSERT(heart.bind(user.mind), "Сердце привязано к еретику.")
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	var/datum/mind/soul = allocate_mind()
	soul.current = victim
	victim.mind = soul
	heretic.set_hunt_target(soul)
	TEST_ASSERT(findtext(heretic.retarget_hint(heart), "retarget=1"), "Без перезарядки подсказка даёт ссылку на смену цели.")
	COOLDOWN_START(heretic, hunt_refresh_cooldown, HERETIC_HUNT_REFRESH_COOLDOWN)
	TEST_ASSERT(!findtext(heretic.retarget_hint(heart), "href"), "Во время перезарядки ссылки нет.")
	TEST_ASSERT(findtext(heretic.retarget_hint(heart), "через"), "Во время перезарядки подсказка называет срок.")
	heart.track(user, heretic)
	TEST_ASSERT(!heretic.hunt_stale_hinted, "Свежая охота не считается затянувшейся.")
	heretic.hunt_assigned_at = world.time - HERETIC_HUNT_STALE_TIME
	COOLDOWN_RESET(heart, track_cooldown)
	heart.track(user, heretic)
	TEST_ASSERT(heretic.hunt_stale_hinted, "Затянувшаяся охота подсказывает смену цели.")
	heretic.set_hunt_target(soul)
	TEST_ASSERT(!heretic.hunt_stale_hinted, "Новая цель сбрасывает подсказку.")
