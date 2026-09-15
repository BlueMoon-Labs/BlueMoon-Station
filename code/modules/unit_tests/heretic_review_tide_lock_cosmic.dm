/// Гарпун сохраняет намокание и возвращает силы только после настоящего попадания с выдержанным интервалом.
/datum/unit_test/heretic_review_tide_harpoon_cycle/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_TIDE
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_tide)
	heretic.gain_knowledge(/datum/eldritch_knowledge/tide_upgrade)
	var/mob/living/user = heretic.owner.current
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	var/datum/eldritch_knowledge/base_tide/tide = heretic.get_knowledge(/datum/eldritch_knowledge/base_tide)
	var/obj/item/melee/sickly_blade/tide/blade = allocate(/obj/item/melee/sickly_blade/tide)
	tide.combat_resource = 0
	user.adjustStaminaLoss(40)
	tide.soak(victim)
	blade.afterattack(victim, user, TRUE, null)
	TEST_ASSERT(victim.has_status_effect(/datum/status_effect/heretic_drenched), "afterattack без ранения сохраняет намокание.")
	TEST_ASSERT_EQUAL(tide.combat_resource, 0, "afterattack не извлекает давление.")
	user.a_intent = INTENT_HARM
	blade.attack(victim, user)
	TEST_ASSERT(victim.has_status_effect(/datum/status_effect/heretic_drenched), "Настоящий удар сохраняет намокание противника.")
	TEST_ASSERT_EQUAL(tide.combat_resource, 2, "Один удар даёт обычное давление и ещё единицу из воды.")
	TEST_ASSERT(abs(user.getStaminaLoss() - 30) <= DAMAGE_PRECISION, "Гарпун восстанавливает десять выносливости.")
	tide.soak(victim)
	var/damage_before = victim.getBruteLoss()
	blade.attack(victim, user)
	TEST_ASSERT(victim.has_status_effect(/datum/status_effect/heretic_drenched), "Удар во время перезарядки не тратит новое намокание.")
	TEST_ASSERT_EQUAL(tide.combat_resource, 2, "Повторный удар не обходит интервалы сбора.")
	TEST_ASSERT(abs(user.getStaminaLoss() - 30) <= DAMAGE_PRECISION, "Повторный удар не восстанавливает выносливость.")
	TEST_ASSERT(victim.getBruteLoss() - damage_before >= blade.force + 5 - DAMAGE_PRECISION, "Обычный бонус мокрого удара сохраняется во время перезарядки восстановления.")

/// Чужая вода и антимагия не питают гарпун, неудачная попытка не расходует намокание.
/datum/unit_test/heretic_review_tide_harpoon_ownership/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_TIDE
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_tide)
	heretic.gain_knowledge(/datum/eldritch_knowledge/tide_upgrade)
	var/mob/living/user = heretic.owner.current
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	var/datum/eldritch_knowledge/base_tide/tide = heretic.get_knowledge(/datum/eldritch_knowledge/base_tide)
	var/datum/eldritch_knowledge/tide_upgrade/upgrade = heretic.get_knowledge(/datum/eldritch_knowledge/tide_upgrade)
	var/datum/antagonist/heretic/other = allocate_heretic(get_step(user, NORTH))
	other.selected_path = PATH_TIDE
	other.gain_knowledge(/datum/eldritch_knowledge/base_tide)
	var/datum/eldritch_knowledge/base_tide/other_tide = other.get_knowledge(/datum/eldritch_knowledge/base_tide)
	tide.combat_resource = 0
	other_tide.soak(victim)
	upgrade.on_eldritch_blade(victim, user, TRUE, null)
	TEST_ASSERT_EQUAL(tide.combat_resource, 0, "Чужое намокание не даёт давление.")
	TEST_ASSERT(victim.has_status_effect(/datum/status_effect/heretic_drenched), "Чужое намокание сохраняется.")
	TEST_ASSERT(abs(victim.getBruteLoss() - 5) <= DAMAGE_PRECISION, "Чужая вода сохраняет обычный бонус мокрого удара.")
	tide.soak(victim)
	var/datum/component/anti_magic/protection = victim.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5)
	upgrade.on_eldritch_blade(victim, user, TRUE, null)
	TEST_ASSERT_EQUAL(tide.combat_resource, 0, "Антимагия запрещает извлечение давления.")
	TEST_ASSERT(victim.has_status_effect(/datum/status_effect/heretic_drenched), "Защита сохраняет намокание.")
	TEST_ASSERT_EQUAL(protection.charges, 5, "Добавочный эффект клинка не расходует второй заряд защиты.")
	qdel(protection)
	upgrade.on_eldritch_blade(victim, user, TRUE, null)
	TEST_ASSERT_EQUAL(tide.combat_resource, 1, "Отклонённые попытки не запускают интервал восстановления.")
	TEST_ASSERT(abs(victim.getBruteLoss() - 10) <= DAMAGE_PRECISION, "Удар по своей воде добавляет прежние пять ушибов.")

/// Собственные печати проводят удар и метку, сохраняя защиту чужих плотных преград на той же клетке.
/datum/unit_test/heretic_review_lock_conducted_bolt/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_lock)
	heretic.gain_knowledge(/datum/eldritch_knowledge/lock_mark)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_lock/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/base_lock)
	var/turf/middle = get_step(user, EAST)
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(middle, EAST))
	var/obj/structure/heretic_lock_seal/seal = knowledge.create_seal(middle, user)
	TEST_ASSERT_NOTNULL(seal, "Печать должна появиться между стрелком и целью.")
	var/obj/effect/proc_holder/spell/pointed/heretic_lock/bolt/spell = allocate(/obj/effect/proc_holder/spell/pointed/heretic_lock/bolt)
	TEST_ASSERT(spell.can_target(victim, user, TRUE), "Собственная печать проводит удар.")
	var/obj/structure/blocker = allocate(/obj/structure, middle)
	blocker.density = TRUE
	TEST_ASSERT(!spell.can_target(victim, user, TRUE), "Плотный объект на клетке своей печати сохраняет защиту.")
	qdel(blocker)
	var/datum/antagonist/heretic/other = allocate_heretic(get_step(user, NORTH))
	other.gain_knowledge(/datum/eldritch_knowledge/base_lock)
	var/datum/eldritch_knowledge/base_lock/other_knowledge = other.get_knowledge(/datum/eldritch_knowledge/base_lock)
	var/obj/structure/heretic_lock_seal/foreign = allocate(/obj/structure/heretic_lock_seal, middle, other_knowledge)
	other_knowledge.seals += foreign
	TEST_ASSERT(!spell.can_target(victim, user, TRUE), "Чужая печать на той же клетке тоже перекрывает удар.")
	qdel(foreign)
	var/keys_before = knowledge.combat_resource
	spell.cast(list(victim), user)
	TEST_ASSERT(abs(victim.getFireLoss() - 25) <= DAMAGE_PRECISION, "Проведение не увеличивает базовый урон заклинания.")
	TEST_ASSERT(victim.has_status_effect(/datum/status_effect/eldritch/lock), "Проведённый удар накладывает изученную метку.")
	TEST_ASSERT_EQUAL(knowledge.combat_resource, keys_before, "Само проведение не создаёт ключи.")
	TEST_ASSERT(!QDELETED(seal), "Проводящая печать остаётся преградой.")
	victim.remove_status_effect(/datum/status_effect/eldritch/lock)
	qdel(seal)
	spell.cast(list(victim), user)
	TEST_ASSERT(!victim.has_status_effect(/datum/status_effect/eldritch/lock), "Без печати обычный дальний удар не заменяет хватку.")

/// Прибытие расходует уже наложенную метку и вызывает обычное событие детонации ровно один раз.
/datum/unit_test/heretic_review_cosmic_arrival/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_COSMIC
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_cosmic)
	heretic.gain_knowledge(/datum/eldritch_knowledge/cosmic_mark)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_cosmic/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/base_cosmic)
	var/turf/origin = get_turf(user)
	var/turf/landing = get_step(get_step(get_step(origin, EAST), EAST), EAST)
	TEST_ASSERT(knowledge.add_star(origin, user), "Входная звезда должна создаться.")
	TEST_ASSERT(knowledge.add_star(landing, user), "Выходная звезда должна создаться.")
	var/obj/structure/heretic_star/destination = knowledge.stars[2]
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(landing, NORTH))
	TEST_ASSERT(knowledge.cross_thread(victim), "Нить должна наложить собственную метку.")
	var/damage_before = victim.getFireLoss()
	var/stamina_before = victim.getStaminaLoss()
	knowledge.combat_resource_name = "Проверка детонации"
	knowledge.combat_resource = 0
	var/obj/structure/blocker = allocate(/obj/structure, landing)
	blocker.density = TRUE
	TEST_ASSERT(!knowledge.travel(user, destination), "Заблокированный выход не принимает телепортацию.")
	TEST_ASSERT(victim.has_status_effect(/datum/status_effect/eldritch/cosmic), "Неудачный переход сохраняет метку.")
	qdel(blocker)
	TEST_ASSERT(knowledge.travel(user, destination), "Свободный выход принимает телепортацию.")
	TEST_ASSERT_EQUAL(get_turf(user), landing, "Еретик прибывает к выбранной звезде.")
	TEST_ASSERT(!victim.has_status_effect(/datum/status_effect/eldritch/cosmic), "Прибытие расходует метку.")
	TEST_ASSERT(abs(victim.getFireLoss() - damage_before - 10) <= DAMAGE_PRECISION, "Прибытие наносит обычные десять ожогов метки.")
	TEST_ASSERT(abs(victim.getStaminaLoss() - stamina_before - 15) <= DAMAGE_PRECISION, "Прибытие наносит обычные пятнадцать выносливости метки.")
	TEST_ASSERT_EQUAL(knowledge.combat_resource, 1, "Вызывается обычное событие детонации знания пути.")
	TEST_ASSERT(!knowledge.discharge_arrival(user, destination), "Расходованная метка не взрывается повторно.")
	TEST_ASSERT_EQUAL(knowledge.combat_resource, 1, "Повторная проверка не дублирует награду за метку.")

/// Чужие метки, расстояние, преграды и антимагия ограничивают взрыв у выходной звезды.
/datum/unit_test/heretic_review_cosmic_arrival_protection/Run()
	var/turf/center = get_step(get_step(run_loc_floor_bottom_left, EAST), NORTH)
	var/datum/antagonist/heretic/heretic = allocate_heretic(center)
	heretic.selected_path = PATH_COSMIC
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_cosmic)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_cosmic/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/base_cosmic)
	TEST_ASSERT(knowledge.add_star(center, user), "Звезда должна создаться.")
	var/obj/structure/heretic_star/destination = knowledge.stars[1]
	var/datum/antagonist/heretic/other = allocate_heretic(get_step(get_step(center, NORTH), NORTH))
	other.selected_path = PATH_COSMIC
	other.gain_knowledge(/datum/eldritch_knowledge/base_cosmic)
	var/datum/eldritch_knowledge/base_cosmic/other_knowledge = other.get_knowledge(/datum/eldritch_knowledge/base_cosmic)
	var/mob/living/foreign = allocate(/mob/living/carbon/human, get_step(center, NORTH))
	foreign.apply_status_effect(/datum/status_effect/eldritch/cosmic, other_knowledge)
	var/mob/living/protected = allocate(/mob/living/carbon/human, get_step(center, EAST))
	protected.apply_status_effect(/datum/status_effect/eldritch/cosmic, knowledge)
	var/datum/component/anti_magic/protection = protected.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5)
	var/mob/living/blocked = allocate(/mob/living/carbon/human, get_step(center, WEST))
	blocked.apply_status_effect(/datum/status_effect/eldritch/cosmic, knowledge)
	var/obj/structure/blocker = allocate(/obj/structure, get_turf(blocked))
	blocker.density = TRUE
	var/mob/living/distant = allocate(/mob/living/carbon/human, get_step(get_step(center, EAST), EAST))
	distant.apply_status_effect(/datum/status_effect/eldritch/cosmic, knowledge)
	TEST_ASSERT(!knowledge.discharge_arrival(user, destination), "Защищённые, чужие и удалённые метки не взрываются.")
	for(var/mob/living/victim as anything in list(foreign, protected, blocked, distant))
		TEST_ASSERT_EQUAL(victim.getFireLoss(), 0, "Отклонённая цель не получает урон.")
		TEST_ASSERT(victim.has_status_effect(/datum/status_effect/eldritch/cosmic), "Отклонённая цель сохраняет метку.")
	TEST_ASSERT_EQUAL(protection.charges, 4, "Проверка собственного отмеченного врага расходует один заряд антимагии.")
	knowledge.on_body_lose(user)
	TEST_ASSERT(!knowledge.discharge_arrival(user, destination), "Утрата тела прекращает действие прежнего созвездия.")
