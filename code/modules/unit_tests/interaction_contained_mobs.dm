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
