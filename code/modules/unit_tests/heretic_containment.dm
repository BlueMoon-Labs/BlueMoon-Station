/// Наручники и щит разума глушат способности еретика; вознесение и "Разум за завесой" снимают действие щита.
/datum/unit_test/heretic_containment_magic/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/obj/effect/proc_holder/spell/targeted/touch/mansus_grasp/grasp = allocate(/obj/effect/proc_holder/spell/targeted/touch/mansus_grasp)
	heretic.owner.AddSpell(grasp)
	TEST_ASSERT(grasp.can_cast(user, TRUE, TRUE), "Свободный еретик колдует.")
	user.handcuffed = allocate(/obj/item/restraints/handcuffs, user)
	user.update_handcuffed()
	TEST_ASSERT(!grasp.can_cast(user, TRUE, TRUE), "В наручниках магия Мансуса недоступна.")
	TEST_ASSERT(findtext(grasp.heretic_failure_reason, "наручниках"), "Отказ называет наручники.")
	user.uncuff()
	TEST_ASSERT(grasp.can_cast(user, TRUE, TRUE), "Снятые наручники возвращают магию.")
	var/obj/effect/proc_holder/spell/targeted/ethereal_jaunt/shift/ash/ash_passage = allocate(/obj/effect/proc_holder/spell/targeted/ethereal_jaunt/shift/ash)
	heretic.owner.AddSpell(ash_passage)
	TEST_ASSERT(ash_passage.can_cast(user, TRUE, TRUE), "Пепельный переход доступен свободному еретику.")
	user.handcuffed = allocate(/obj/item/restraints/handcuffs, user)
	user.update_handcuffed()
	TEST_ASSERT(!ash_passage.can_cast(user, TRUE, TRUE), "Пепельный переход недоступен в наручниках.")
	user.uncuff()
	var/obj/item/implant/mindshield/shield = allocate(/obj/item/implant/mindshield)
	TEST_ASSERT(shield.implant(user, null, TRUE), "Щит вводится без оператора.")
	TEST_ASSERT(!grasp.can_cast(user, TRUE, TRUE), "Щит разума глушит магию.")
	TEST_ASSERT(heretic_containment_reason(user), "Щит разума мешает и побегу клинком.")
	ADD_TRAIT(user, TRAIT_HERETIC_ASCENDED, TRAIT_GENERIC)
	TEST_ASSERT(grasp.can_cast(user, TRUE, TRUE), "Вознёсшегося щит не держит.")
	REMOVE_TRAIT(user, TRAIT_HERETIC_ASCENDED, TRAIT_GENERIC)
	heretic.gain_knowledge(/datum/eldritch_knowledge/unshielded_mind)
	TEST_ASSERT(grasp.can_cast(user, TRUE, TRUE), "Разум за завесой снимает действие щита.")
	user.handcuffed = allocate(/obj/item/restraints/handcuffs, user)
	user.update_handcuffed()
	TEST_ASSERT(!grasp.can_cast(user, TRUE, TRUE), "Разум за завесой не спасает от наручников.")
	user.uncuff()

/// Еретик не может сам ввести себе щит разума.
/datum/unit_test/heretic_mindshield_self_implant/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/obj/item/implant/mindshield/shield = allocate(/obj/item/implant/mindshield)
	TEST_ASSERT(!shield.implant(user, user), "Самостоятельный ввод отклонён.")
	TEST_ASSERT(!HAS_TRAIT(user, TRAIT_MINDSHIELD), "Щит не встал.")
	var/mob/living/carbon/human/crew = allocate(/mob/living/carbon/human)
	var/datum/mind/crew_mind = allocate_mind()
	crew_mind.current = crew
	crew.mind = crew_mind
	var/obj/item/implant/mindshield/crew_shield = allocate(/obj/item/implant/mindshield)
	TEST_ASSERT(crew_shield.implant(crew, crew, TRUE), "Обычный член экипажа вводит щит себе как раньше.")

/// Между побегами клинком проходит перезарядка, наручники и щит побег запрещают.
/datum/unit_test/heretic_blade_escape_cooldown/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/obj/item/melee/sickly_blade/escape_fixture/first = allocate(/obj/item/melee/sickly_blade/escape_fixture)
	first.drop_during_search = FALSE
	first.destination = get_step(user, EAST)
	user.put_in_hands(first)
	first.attack_self(user)
	TEST_ASSERT(QDELETED(first), "Первый побег расходует клинок.")
	var/obj/item/melee/sickly_blade/escape_fixture/second = allocate(/obj/item/melee/sickly_blade/escape_fixture)
	second.drop_during_search = FALSE
	second.destination = get_step(get_turf(user), EAST)
	user.put_in_hands(second)
	second.attack_self(user)
	TEST_ASSERT(!QDELETED(second), "Повторный побег сразу после первого отклонён.")
	TEST_ASSERT_EQUAL(second.search_count, 0, "Отказ по перезарядке не ищет место.")
	heretic.owner.heretic_escape_ready_at = world.time - 1
	user.handcuffed = allocate(/obj/item/restraints/handcuffs, user)
	user.update_handcuffed()
	second.attack_self(user)
	TEST_ASSERT_EQUAL(second.search_count, 0, "Скованный еретик не разбивает клинок.")
	user.uncuff()
	user.put_in_hands(second)
	var/turf/destination = get_step(get_turf(user), EAST)
	second.destination = destination
	second.attack_self(user)
	TEST_ASSERT(QDELETED(second), "После перезарядки побег снова работает.")

/// Вознёсшийся восполняет кровь даже сразу после ранения.
/datum/unit_test/heretic_ascended_blood_regen/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/datum/status_effect/heretic_ascended/ascended = user.apply_status_effect(/datum/status_effect/heretic_ascended)
	user.blood_volume = BLOOD_VOLUME_BAD
	ascended.last_damage_time = world.time
	ascended.tick()
	TEST_ASSERT_EQUAL(user.blood_volume, BLOOD_VOLUME_BAD + HERETIC_ASCENDED_BLOOD_REGEN, "Кровь восполняется и в бою.")
	user.blood_volume = BLOOD_VOLUME_NORMAL - 1
	ascended.tick()
	TEST_ASSERT_EQUAL(user.blood_volume, BLOOD_VOLUME_NORMAL, "Восполнение не выходит за норму.")

/// Финальный обряд запрещён в зоне космоса станционных уровней; резервация тестов не считается.
/datum/unit_test/heretic_ascension_open_space/Run()
	TEST_ASSERT(!heretic_ascension_in_open_space(run_loc_floor_bottom_left), "Резервные уровни не считаются открытым космосом.")
	var/list/station_levels = SSmapping.levels_by_trait(ZTRAIT_STATION)
	TEST_ASSERT(length(station_levels), "Есть станционный уровень.")
	var/turf/station_space = locate(1, 1, station_levels[1])
	TEST_ASSERT(istype(get_area(station_space), /area/space), "Угол станционного уровня лежит в зоне космоса.")
	TEST_ASSERT(heretic_ascension_in_open_space(station_space), "Зона космоса станции запрещает обряд независимо от воздуха.")

/// Добровольно лёгшая или уснувшая цель не считается поверженной, настоящий крит и сбивание с ног считаются.
/datum/unit_test/heretic_hunt_voluntary_rest/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human)
	victim.set_resting(TRUE, silent = TRUE)
	TEST_ASSERT_EQUAL(victim.body_position, LYING_DOWN, "Цель легла сама.")
	TEST_ASSERT(!heretic.hunt_target_ready(victim), "Добровольно лёгшая цель не подходит.")
	victim.set_resting(FALSE, silent = TRUE)
	victim.SetSleeping(10 SECONDS)
	TEST_ASSERT(!heretic.hunt_target_ready(victim), "Уснувшая цель без ранений не подходит.")
	victim.SetSleeping(0)
	victim.adjustBruteLoss(150)
	TEST_ASSERT(victim.stat >= SOFT_CRIT, "Раны довели цель до крита.")
	TEST_ASSERT(heretic.hunt_target_ready(victim), "Цель в крите подходит.")
	victim.fully_heal()
	victim.DefaultCombatKnockdown(2 SECONDS, override_stamdmg = 0)
	TEST_ASSERT(heretic.hunt_target_ready(victim), "Сбитая с ног цель подходит.")

/// Для вознесения годится только труп, которым управлял игрок; учебному еретику хватает пустых тел полигона.
/datum/unit_test/heretic_ascension_body_soul/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	var/mob/living/carbon/human/empty_body = allocate(/mob/living/carbon/human)
	empty_body.death()
	TEST_ASSERT(!heretic_ascension_body_valid(empty_body, user), "Тело без души (очеловеченная мартышка) не подходит.")
	var/mob/living/carbon/human/crew_body = allocate(/mob/living/carbon/human)
	crew_body.last_mind = allocate_mind()
	crew_body.death()
	TEST_ASSERT(heretic_ascension_body_valid(crew_body, user), "Труп бывшего игрока подходит.")
	heretic.simulated = TRUE
	TEST_ASSERT(heretic_ascension_body_valid(empty_body, user), "Учебному еретику подходят пустые тела полигона.")

/// В выборе целей охоты есть глава и сотрудник СБ, если они на станции.
/datum/unit_test/heretic_hunt_choice_roles
	var/list/previous_records
	var/list/previous_traits
	var/datum/space_level/test_level

/datum/unit_test/heretic_hunt_choice_roles/Destroy()
	if(previous_records)
		GLOB.data_core.locked = previous_records
	if(previous_traits)
		test_level.traits = previous_traits
	return ..()

/datum/unit_test/heretic_hunt_choice_roles/Run()
	previous_records = GLOB.data_core.locked
	GLOB.data_core.locked = list()
	test_level = SSmapping.get_level(run_loc_floor_bottom_left.z)
	previous_traits = test_level.traits
	test_level.traits = previous_traits.Copy()
	test_level.traits[ZTRAIT_STATION] = TRUE
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/datum/mind/user_mind = allocate_mind()
	user_mind.current = user
	user.mind = user_mind
	var/datum/antagonist/heretic/hunt_selection_fixture/heretic = allocate(/datum/antagonist/heretic/hunt_selection_fixture)
	heretic.owner = user_mind
	heretic.silent = TRUE
	user_mind.antag_datums = list(heretic)
	var/list/roles = list("Assistant", "Assistant", "Assistant", "Assistant", "Captain", "Security Officer")
	for(var/role in roles)
		var/mob/living/carbon/human/candidate_body = allocate(/mob/living/carbon/human)
		var/datum/mind/candidate = allocate_mind()
		candidate.current = candidate_body
		candidate.assigned_role = role
		candidate_body.mind = candidate
		var/datum/data/record/record = allocate(/datum/data/record)
		record.fields["mindref"] = candidate
		GLOB.data_core.locked += record
	heretic.prepare_hunt_choices()
	TEST_ASSERT_EQUAL(length(heretic.hunt_candidates), 3, "Предложены три цели.")
	TEST_ASSERT(heretic.hunt_candidates_include_role(GLOB.command_positions), "Среди целей есть глава.")
	TEST_ASSERT(heretic.hunt_candidates_include_role(GLOB.security_positions), "Среди целей есть сотрудник СБ.")
