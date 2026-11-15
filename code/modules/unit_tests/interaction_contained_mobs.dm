/// Моб в сумке в руке и pAI в MOD взаимодействуют, шлют subtler и выбирают цель subtler от тайла носителя, не дальше и не сквозь окно.
/datum/unit_test/interaction_contained_mobs

/datum/interaction/contained_reach_test
	simple_message = "USER тычется в TARGET."
	interaction_flags = INTERACTION_FLAG_ADJACENT

/datum/interaction/contained_reach_test/evaluate_user(mob/living/user, silent, apply_cooldown)
	return TRUE

/datum/interaction/contained_reach_test/evaluate_target(mob/living/user, mob/living/target, silent)
	return TRUE

/datum/unit_test/interaction_contained_mobs/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/turf/near_turf = get_step(origin, EAST)
	var/turf/far_turf = get_step(near_turf, EAST)
	var/mob/living/carbon/human/carrier = allocate(/mob/living/carbon/human, origin)
	var/mob/living/interaction_privacy_probe/near = allocate(/mob/living/interaction_privacy_probe, near_turf)
	var/mob/living/interaction_privacy_probe/far = allocate(/mob/living/interaction_privacy_probe, far_turf)
	near.audiovisual_redirect = near
	far.audiovisual_redirect = far
	near.become_hearing_sensitive(TRAIT_SOURCE_UNIT_TESTS)
	far.become_hearing_sensitive(TRAIT_SOURCE_UNIT_TESTS)

	var/obj/item/storage/backpack/bag = allocate(/obj/item/storage/backpack)
	TEST_ASSERT(carrier.put_in_hands(bag), "Сумка должна попасть в руку.")
	var/mob/living/simple_animal/mouse/mouse = allocate(/mob/living/simple_animal/mouse)
	mouse.forceMove(bag)

	var/obj/item/mod/control/mod = allocate(/obj/item/mod/control)
	mod.forceMove(carrier)
	var/mob/living/silicon/pai/pai = allocate(/mob/living/silicon/pai, origin)
	allocated += pai.card
	pai.forceMove(mod)

	var/datum/interaction/interaction = allocate(/datum/interaction/contained_reach_test)
	var/datum/emote/sound/human/subtler_target/target_emote = locate() in GLOB.emote_list["subtler_target"]
	TEST_ASSERT_NOTNULL(target_emote, "Эмоут subtler_target зарегистрирован.")
	for(var/mob/living/contained as anything in list(mouse, pai))
		var/label = "[contained.type]"
		TEST_ASSERT(interaction.do_action(contained, near, apply_cooldown = FALSE), "[label]: из контейнера можно взаимодействовать с соседом.")
		TEST_ASSERT(interaction.do_action(near, contained, apply_cooldown = FALSE), "[label]: сосед может взаимодействовать с тем, кого несут.")
		TEST_ASSERT(interaction.do_action(contained, carrier, apply_cooldown = FALSE), "[label]: можно взаимодействовать с тем, кто несёт.")
		TEST_ASSERT(interaction.do_action(carrier, contained, apply_cooldown = FALSE), "[label]: носитель может взаимодействовать с тем, кого несёт.")
		TEST_ASSERT(!interaction.do_action(contained, far, apply_cooldown = FALSE), "[label]: через тайл взаимодействие не достаёт.")

		near.received_messages.Cut()
		far.received_messages.Cut()
		contained.emote("subtler", message = "шевелит усами")
		TEST_ASSERT_EQUAL(length(near.received_messages), 1, "[label]: subtler из контейнера видят на соседнем тайле.")
		TEST_ASSERT_EQUAL(length(far.received_messages), 0, "[label]: subtler из контейнера не виден через тайл.")

		var/list/targets = target_emote.get_possible_targets(contained, 1)
		TEST_ASSERT(near in targets, "[label]: subtler_target из контейнера предлагает соседа.")
		TEST_ASSERT(carrier in targets, "[label]: subtler_target из контейнера предлагает носителя.")
		TEST_ASSERT(!(far in targets), "[label]: subtler_target не предлагает тех, кто дальше дистанции.")
		TEST_ASSERT(!(contained in targets), "[label]: subtler_target не предлагает самого себя.")

	var/obj/structure/window/pane = allocate(/obj/structure/window, origin)
	pane.setDir(EAST)
	TEST_ASSERT(!interaction.do_action(carrier, near, apply_cooldown = FALSE), "Сквозь окно стоящий на полу не достаёт.")
	TEST_ASSERT(!interaction.do_action(mouse, near, apply_cooldown = FALSE), "Сквозь окно не достаёт и тот, кого несут.")
	qdel(pane)

	var/obj/structure/closet/closet = allocate(/obj/structure/closet, origin)
	var/mob/living/simple_animal/mouse/locked = allocate(/mob/living/simple_animal/mouse)
	locked.forceMove(closet)
	TEST_ASSERT(!interaction.do_action(locked, near, apply_cooldown = FALSE), "Из закрытого шкафа взаимодействие не достаёт.")

	allocate(/obj/structure/table, get_step(origin, NORTH))
	near.received_messages.Cut()
	far.received_messages.Cut()
	mouse.emote("subtler_table", message = "стучит хвостом")
	TEST_ASSERT_EQUAL(length(near.received_messages), 1, "subtler_table из сумки находит стол рядом с носителем.")
	TEST_ASSERT_EQUAL(length(far.received_messages), 0, "subtler_table не виден тем, кто не у стола.")
	TEST_ASSERT(!findtext(interaction_reach_refusal(mouse, far), "выберись"), "Из сумки отказ говорит про расстояние, а не про выход.")
	TEST_ASSERT(findtext(interaction_reach_refusal(locked, near), "выберись"), "Из шкафа отказ просит сначала выбраться.")

/// Из переноски, слипера борга и MMI наружу не дотянуться, как из шкафа, даже если контейнер стоит рядом.
/datum/unit_test/interaction_contained_blocked

/datum/unit_test/interaction_contained_blocked/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/turf/near_turf = get_step(origin, EAST)
	var/mob/living/interaction_privacy_probe/near = allocate(/mob/living/interaction_privacy_probe, near_turf)
	var/datum/interaction/interaction = allocate(/datum/interaction/contained_reach_test)

	var/obj/item/pet_carrier/locked_carrier = allocate(/obj/item/pet_carrier, origin)
	locked_carrier.open = FALSE
	locked_carrier.locked = TRUE
	var/obj/item/pet_carrier/open_carrier = allocate(/obj/item/pet_carrier, origin)
	var/list/containers = list(locked_carrier, open_carrier, allocate(/obj/item/dogborg/sleeper, origin), allocate(/obj/item/mmi, origin))
	for(var/obj/item/container as anything in containers)
		var/mob/living/simple_animal/mouse/inside = allocate(/mob/living/simple_animal/mouse)
		if(istype(container, /obj/item/pet_carrier))
			var/obj/item/pet_carrier/pet_carrier = container
			pet_carrier.add_occupant(inside)
		else
			inside.forceMove(container)
		var/label = "[container.type][container == locked_carrier ? " (заперта)" : ""]"
		TEST_ASSERT(inside.loc == container, "[label]: мышь внутри.")
		TEST_ASSERT(!interaction.do_action(inside, near, apply_cooldown = FALSE), "[label]: изнутри наружу не достать.")
		TEST_ASSERT(!interaction.do_action(near, inside, apply_cooldown = FALSE), "[label]: снаружи до сидящего внутри не достать.")
		TEST_ASSERT(findtext(interaction_reach_refusal(inside, near), "выберись"), "[label]: отказ просит сначала выбраться.")

/datum/interaction/contained_reach_test/carrier_walks_away
	var/mob/living/walker
	var/turf/walk_destination

/datum/interaction/contained_reach_test/carrier_walks_away/special_check(mob/living/user, mob/living/target, is_hidden)
	walker.forceMove(walk_destination)
	return TRUE

/// Досягаемость перепроверяется после ожидания в special_check: носитель ушёл - действие не проходит.
/datum/unit_test/interaction_contained_reach_after_wait

/datum/unit_test/interaction_contained_reach_after_wait/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/turf/near_turf = get_step(origin, EAST)
	var/turf/away_turf = get_step(get_step(near_turf, EAST), EAST)
	var/mob/living/carbon/human/carrier = allocate(/mob/living/carbon/human, origin)
	var/mob/living/interaction_privacy_probe/near = allocate(/mob/living/interaction_privacy_probe, near_turf)
	var/obj/item/storage/backpack/bag = allocate(/obj/item/storage/backpack)
	TEST_ASSERT(carrier.put_in_hands(bag), "Сумка должна попасть в руку.")
	var/mob/living/simple_animal/mouse/mouse = allocate(/mob/living/simple_animal/mouse)
	mouse.forceMove(bag)

	var/datum/interaction/contained_reach_test/carrier_walks_away/interaction = allocate(/datum/interaction/contained_reach_test/carrier_walks_away)
	interaction.walker = carrier
	interaction.walk_destination = origin
	TEST_ASSERT(interaction.do_action(mouse, near, apply_cooldown = FALSE), "Пока носитель рядом, действие проходит.")
	interaction.walk_destination = away_turf
	TEST_ASSERT(!interaction.do_action(mouse, near, apply_cooldown = FALSE), "Носитель ушёл за время ожидания - действие не проходит.")
	interaction.walker = null
	interaction.walk_destination = null

/// «Нести на руках» не работает ни из контейнера, ни на того, кто внутри контейнера.
/datum/unit_test/interaction_carry_contained

/datum/unit_test/interaction_carry_contained/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/turf/near_turf = get_step(origin, EAST)
	var/mob/living/carbon/human/lifter = allocate(/mob/living/carbon/human, origin)
	var/mob/living/carbon/human/carrier = allocate(/mob/living/carbon/human, near_turf)
	var/mob/living/carbon/human/lifted = allocate(/mob/living/carbon/human, near_turf)
	var/obj/item/storage/backpack/bag = allocate(/obj/item/storage/backpack)
	TEST_ASSERT(carrier.put_in_hands(bag), "Сумка должна попасть в руку.")
	var/datum/interaction/carry/face_to_face/carry = allocate(/datum/interaction/carry/face_to_face)
	if(SSinteractions.is_blacklisted(lifter))
		SSinteractions.prepare_blacklisted_mobs()

	TEST_ASSERT(carry.evaluate_user(lifter, silent = TRUE, apply_cooldown = FALSE), "С пола поднять можно.")
	TEST_ASSERT(carry.evaluate_target(lifter, lifted, silent = TRUE), "Стоящего на полу поднять можно.")

	lifted.forceMove(bag)
	TEST_ASSERT(!carry.evaluate_target(lifter, lifted, silent = TRUE), "Сидящего в сумке на руки не поднять.")
	TEST_ASSERT(!carry.do_action(lifter, lifted, apply_cooldown = FALSE), "Действие на сидящего в сумке не проходит.")
	TEST_ASSERT(lifted.loc == bag && !lifted.buckled, "Сидящий в сумке остаётся в ней.")

	lifted.forceMove(near_turf)
	lifter.forceMove(bag)
	TEST_ASSERT(!carry.evaluate_user(lifter, silent = TRUE, apply_cooldown = FALSE), "Из сумки никого не поднять.")
	TEST_ASSERT(!carry.do_action(lifter, lifted, apply_cooldown = FALSE), "Действие из сумки не проходит.")
	TEST_ASSERT(isturf(lifted.loc) && !lifted.buckled, "Цель не затягивает в сумку.")

/// Интим-сообщение из сумки не видят отказавшиеся рядом, в том числе сидящие в чужой сумке.
/datum/unit_test/interaction_contained_consent

/datum/unit_test/interaction_contained_consent/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/turf/near_turf = get_step(origin, EAST)
	var/mob/living/carbon/human/carrier = allocate(/mob/living/carbon/human, origin)
	var/obj/item/storage/backpack/bag = allocate(/obj/item/storage/backpack)
	TEST_ASSERT(carrier.put_in_hands(bag), "Сумка должна попасть в руку.")
	var/mob/living/simple_animal/mouse/actor = allocate(/mob/living/simple_animal/mouse)
	actor.forceMove(bag)

	var/mob/living/interaction_privacy_probe/near = allocate(/mob/living/interaction_privacy_probe, near_turf)
	var/obj/item/storage/backpack/near_bag = allocate(/obj/item/storage/backpack, near_turf)
	var/mob/living/interaction_privacy_probe/nested = allocate(/mob/living/interaction_privacy_probe)
	nested.forceMove(near_bag)
	for(var/mob/living/interaction_privacy_probe/observer as anything in list(near, nested))
		observer.audiovisual_redirect = observer
		observer.become_hearing_sensitive(TRAIT_SOURCE_UNIT_TESTS)

	actor.visible_message("контрольное сообщение", vision_distance = DEFAULT_MESSAGE_RANGE)
	TEST_ASSERT_EQUAL(length(near.received_messages), 1, "Обычное сообщение из сумки видно рядом.")
	TEST_ASSERT_EQUAL(length(nested.received_messages), 1, "Обычное сообщение из сумки видно и в соседней сумке.")

	near.received_messages.Cut()
	nested.received_messages.Cut()
	var/list/unconsenting = actor.get_unconsenting()
	TEST_ASSERT(near in unconsenting, "Наблюдатель без согласия рядом попадает в отказавшихся.")
	TEST_ASSERT(nested in unconsenting, "Наблюдатель без согласия в соседней сумке попадает в отказавшихся.")
	actor.visible_message("интимное сообщение", vision_distance = DEFAULT_MESSAGE_RANGE, ignored_mobs = unconsenting)
	TEST_ASSERT_EQUAL(length(near.received_messages), 0, "Отказавшийся рядом не видит интимное сообщение из сумки.")
	TEST_ASSERT_EQUAL(length(nested.received_messages), 0, "Отказавшийся в соседней сумке не видит интимное сообщение.")
	TEST_ASSERT(near in actor.get_unconsenting(unholy = TRUE), "Для unholy-звуков отказавшиеся собираются так же.")
	for(var/mob/living/interaction_privacy_probe/observer as anything in list(near, nested))
		observer.lose_hearing_sensitivity(TRAIT_SOURCE_UNIT_TESTS)

/// subtler_table из сумки видит сам отправитель и сидящие в сумках у стола.
/datum/unit_test/interaction_contained_subtler

/datum/unit_test/interaction_contained_subtler/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/turf/near_turf = get_step(origin, EAST)
	allocate(/obj/structure/table, get_step(origin, NORTH))
	var/obj/item/storage/backpack/floor_bag = allocate(/obj/item/storage/backpack, origin)
	var/mob/living/interaction_privacy_probe/sender = allocate(/mob/living/interaction_privacy_probe)
	sender.forceMove(floor_bag)
	var/mob/living/interaction_privacy_probe/near = allocate(/mob/living/interaction_privacy_probe, near_turf)
	var/obj/item/storage/backpack/near_bag = allocate(/obj/item/storage/backpack)
	near_bag.forceMove(near)
	var/mob/living/interaction_privacy_probe/nested = allocate(/mob/living/interaction_privacy_probe)
	nested.forceMove(near_bag)

	sender.emote("subtler_table", message = "стучит по столу")
	TEST_ASSERT_EQUAL(length(sender.received_messages), 1, "Отправитель из сумки видит своё subtler_table.")
	TEST_ASSERT_EQUAL(length(near.received_messages), 1, "subtler_table видит стоящий у стола.")
	TEST_ASSERT_EQUAL(length(nested.received_messages), 1, "subtler_table видит и сидящий в сумке у стоящего у стола.")

/// Цели subtler_target из сумки находятся и в темноте.
/datum/unit_test/interaction_contained_subtler_dark

/datum/unit_test/interaction_contained_subtler_dark/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/turf/dark_turf = get_step(get_step(get_step(origin, EAST), EAST), EAST)
	var/obj/item/storage/backpack/floor_bag = allocate(/obj/item/storage/backpack, origin)
	var/mob/living/interaction_privacy_probe/sender = allocate(/mob/living/interaction_privacy_probe)
	sender.forceMove(floor_bag)
	var/datum/emote/sound/human/subtler_target/target_emote = locate() in GLOB.emote_list["subtler_target"]
	TEST_ASSERT_NOTNULL(target_emote, "Эмоут subtler_target зарегистрирован.")
	var/mob/living/interaction_privacy_probe/in_dark = allocate(/mob/living/interaction_privacy_probe, dark_turf)
	var/area/test_area = get_area(dark_turf)
	var/old_area_luminosity = test_area.luminosity
	var/old_turf_luminosity = dark_turf.luminosity
	test_area.luminosity = 0
	dark_turf.luminosity = 0
	var/list/targets = target_emote.get_possible_targets(sender, 5)
	test_area.luminosity = old_area_luminosity
	dark_turf.luminosity = old_turf_luminosity
	TEST_ASSERT(in_dark in targets, "subtler_target из сумки предлагает того, кто стоит в темноте.")
	TEST_ASSERT(!(sender in targets), "subtler_target не предлагает самого себя.")
