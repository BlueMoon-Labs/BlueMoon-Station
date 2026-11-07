/datum/unit_test/interactions/Run()
	SSinteractions = new()
	SSinteractions.prepare_interactions()
	if(!SSinteractions.interactions || !length(SSinteractions.interactions))
		Fail("make_interactions() was called but SSinteractions.interactions is empty.")
	for(var/interaction_type in SSinteractions.interactions)
		var/datum/interaction/interaction = SSinteractions.interactions[interaction_type]
		if(!interaction.description)
			Fail("Basetype [interaction.type] located within SSinteractions.interactions")
		if(interaction.required_from_user_exposed && interaction.required_from_user_unexposed)
			if(interaction.required_from_user_exposed != interaction.required_from_user_unexposed)
				Fail("Interaction [interaction.description]([interaction.type]) has non-matching requirements for user exposed and unexposed, this is unsupported!")
		if(interaction.required_from_target_exposed && interaction.required_from_target_unexposed)
			if(interaction.required_from_target_exposed != interaction.required_from_target_unexposed)
				Fail("Interaction [interaction.description]([interaction.type]) has non-matching requirements for target exposed and unexposed, this is unsupported!")
	return

/mob/living/interaction_privacy_probe
	lighting_alpha = LIGHTING_PLANE_ALPHA_MOSTLY_INVISIBLE
	var/list/received_messages = list()
	var/mob/living/interaction_privacy_probe/relay_recipient

/mob/living/interaction_privacy_probe/show_message(msg, type, alt_msg, alt_type)
	received_messages += msg

/mob/living/interaction_privacy_probe/get_unconsenting(extreme, list/ignored_mobs, unholy, unholy_hard)
	return ignored_mobs

/datum/interaction/privacy_test
	simple_message = "USER машет рукой TARGET."
	interaction_sound = 'sound/effects/snap.ogg'
	interaction_flags = NONE

/datum/interaction/privacy_test/evaluate_user(mob/living/user, silent, apply_cooldown)
	return TRUE

/datum/interaction/privacy_test/evaluate_target(mob/living/user, mob/living/target, silent)
	return TRUE

/datum/interaction/custom/privacy_test/check_requirements(mob/living/user, mob/living/target, silent)
	return TRUE

/datum/component/interaction_menu_granter/privacy_test/Initialize(...)
	return

/datum/unit_test/interaction_privacy/proc/relay_hearing(mob/living/interaction_privacy_probe/source, list/processing_list, list/hearers)
	SIGNAL_HANDLER
	hearers |= source.relay_recipient

/datum/unit_test/interaction_privacy/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/turf/near_turf = get_step(origin, EAST)
	var/turf/far_turf = get_step(near_turf, EAST)
	var/mob/living/interaction_privacy_probe/user = allocate(/mob/living/interaction_privacy_probe, origin)
	var/mob/living/interaction_privacy_probe/target = allocate(/mob/living/interaction_privacy_probe, origin)
	var/mob/living/interaction_privacy_probe/near = allocate(/mob/living/interaction_privacy_probe, near_turf)
	var/mob/living/interaction_privacy_probe/far = allocate(/mob/living/interaction_privacy_probe, far_turf)
	near.audiovisual_redirect = user
	far.audiovisual_redirect = user
	near.become_hearing_sensitive(TRAIT_SOURCE_UNIT_TESTS)
	far.become_hearing_sensitive(TRAIT_SOURCE_UNIT_TESTS)
	near.relay_recipient = far
	RegisterSignal(near, COMSIG_ATOM_HEARER_IN_VIEW, PROC_REF(relay_hearing))
	var/mob/living/heretic_sound_listener/near_ear = allocate_sound_listener(near_turf)
	var/mob/living/heretic_sound_listener/far_ear = allocate_sound_listener(far_turf)

	var/datum/interaction/interaction = allocate(/datum/interaction/privacy_test)
	TEST_ASSERT(interaction.do_action(user, target, apply_cooldown = FALSE, is_hidden = TRUE), "Скрытая интеракция должна выполняться.")
	TEST_ASSERT_EQUAL(length(near.received_messages), 1, "На соседнем тайле виден текст скрытой интеракции.")
	TEST_ASSERT_EQUAL(length(far.received_messages), 0, "В двух тайлах скрытая интеракция не видна.")
	TEST_ASSERT_EQUAL(length(near_ear.heard), 1, "На соседнем тайле слышен звук скрытой интеракции.")
	TEST_ASSERT_EQUAL(length(far_ear.heard), 0, "В двух тайлах скрытая интеракция не слышна.")

	TEST_ASSERT(interaction.do_action(user, target, apply_cooldown = FALSE), "Обычная интеракция должна выполняться.")
	TEST_ASSERT_EQUAL(length(far.received_messages), 1, "Обычный текст виден в двух тайлах.")
	TEST_ASSERT_EQUAL(length(far_ear.heard), 1, "Обычный звук слышен в двух тайлах.")

	var/reaction_sound_range = SOUND_RANGE + INTERACTION_SOUND_EXTRARANGE(TRUE, 0)
	var/list/relayed_hearers = get_hearers_in_view(reaction_sound_range, origin)
	TEST_ASSERT(far in relayed_hearers, "Обычная рассылка может дойти до дальнего наблюдателя через ретранслятор.")
	var/list/reaction_hearers = get_hearers_in_view(reaction_sound_range, origin, include_relays = FALSE)
	TEST_ASSERT(near in reaction_hearers, "Скрытые звуки реакций доходят до соседнего тайла.")
	TEST_ASSERT(!(far in reaction_hearers), "Радиус звуков скрытых реакций исключает второй тайл.")

	var/datum/interaction/custom/interaction_custom = allocate(/datum/interaction/custom/privacy_test)
	interaction_custom.name = "Проверка скрытой интеракции"
	interaction_custom.message = "USER машет рукой TARGET."
	interaction_custom.arousal_level = CUSTOM_AROUSAL_LIGHT
	interaction_custom.partner_arousal_level = CUSTOM_AROUSAL_LIGHT
	interaction_custom.self_orgasm = TRUE
	interaction_custom.partner_orgasm = TRUE
	interaction_custom.custom_interaction_key = "privacy_test"
	var/datum/component/interaction_menu_granter/granter = user.AddComponent(/datum/component/interaction_menu_granter/privacy_test)
	granter.currently_active_interaction = interaction_custom
	granter.auto_interaction_target = target

	for(var/is_hidden in list(TRUE, FALSE))
		near.received_messages.Cut()
		far.received_messages.Cut()
		user.set_lust(user.get_climax_threshold() + 5)
		target.set_lust(target.get_climax_threshold() + 5)
		granter.hidden_interactions[interaction_custom.custom_interaction_key] = is_hidden
		granter.next_interaction_time = world.time - 1
		granter.process(1)
		TEST_ASSERT_EQUAL(granter.currently_active_interaction, interaction_custom, "Автопроигрывание кастомной интеракции продолжает работать.")
		TEST_ASSERT_EQUAL(user.get_lust(), 0, "Оргазм инициатора сбрасывает возбуждение.")
		TEST_ASSERT_EQUAL(target.get_lust(), 0, "Оргазм партнёра сбрасывает возбуждение.")
		TEST_ASSERT_EQUAL(length(near.received_messages), 5, "Рядом видны текст интеракции, оба стона и оба оргазма.")
		TEST_ASSERT_EQUAL(length(far.received_messages), is_hidden ? 0 : 5, "За пределами одного тайла видны только открытые интеракции и реакции.")
		for(var/message in near.received_messages)
			var/has_prefix = FALSE
			for(var/prefix in GLOB.hidden_interaction_additional)
				if(findtext(message, prefix))
					has_prefix = TRUE
					break
			TEST_ASSERT_EQUAL(has_prefix, is_hidden, "Приписка из общего списка есть только у скрытых сообщений.")

	UnregisterSignal(near, COMSIG_ATOM_HEARER_IN_VIEW)
