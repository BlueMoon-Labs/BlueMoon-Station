/// Живой шов работает без биомассы и снимает только своё замедление.
/datum/unit_test/heretic_flesh_stitch_attack/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_FLESH
	var/mob/living/user = heretic.owner.current
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_flesh)
	heretic.gain_knowledge(/datum/eldritch_knowledge/flesh_grasp)
	var/datum/eldritch_knowledge/base_flesh/path = heretic.get_knowledge(/datum/eldritch_knowledge/base_flesh)
	var/datum/eldritch_knowledge/flesh_grasp/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/flesh_grasp)
	var/obj/effect/proc_holder/spell/pointed/heretic_flesh_stitch/stitch = knowledge.granted_spell
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	path.combat_resource = 0
	stitch.cast(list(victim), user)
	TEST_ASSERT(abs(victim.getBruteLoss() - 15) <= DAMAGE_PRECISION, "Даже без биомассы шов наносит 15 ушибов.")
	TEST_ASSERT(victim.has_movespeed_modifier(/datum/movespeed_modifier/heretic_flesh_stitch), "Попадание даёт действующее замедление.")
	TEST_ASSERT_EQUAL(path.combat_resource, 0, "Удар не расходует и не производит биомассу.")
	victim.apply_status_effect(/datum/status_effect/heretic_moon_opening)
	victim.remove_status_effect(/datum/status_effect/heretic_flesh_stitch)
	TEST_ASSERT(!victim.has_movespeed_modifier(/datum/movespeed_modifier/heretic_flesh_stitch), "Снятый шов больше не замедляет.")
	TEST_ASSERT(victim.has_movespeed_modifier(/datum/movespeed_modifier/heretic_moon_opening), "Чужое замедление сохраняется.")

/// Живой шов учитывает препятствия, дальность, антимагию и принадлежность знания.
/datum/unit_test/heretic_flesh_stitch_boundaries/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_FLESH
	var/mob/living/user = heretic.owner.current
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_flesh)
	heretic.gain_knowledge(/datum/eldritch_knowledge/flesh_grasp)
	var/datum/eldritch_knowledge/flesh_grasp/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/flesh_grasp)
	var/obj/effect/proc_holder/spell/pointed/heretic_flesh_stitch/stitch = knowledge.granted_spell
	var/turf/middle = get_step(user, EAST)
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(middle, EAST))
	var/obj/structure/closet/blocker = allocate(/obj/structure/closet, middle)
	stitch.charge_counter = 0
	stitch.cast(list(victim), user)
	TEST_ASSERT_EQUAL(victim.getBruteLoss(), 0, "Плотное препятствие останавливает шов.")
	TEST_ASSERT_EQUAL(stitch.charge_counter, stitch.charge_max, "Недоступная цель возвращает перезарядку.")
	qdel(blocker)
	TEST_ASSERT(stitch.can_target(victim, user, TRUE), "После удаления препятствия цель доступна.")
	var/datum/component/anti_magic/protection = victim.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5)
	stitch.cast(list(victim), user)
	TEST_ASSERT_EQUAL(victim.getBruteLoss(), 0, "Антимагия блокирует повреждение.")
	TEST_ASSERT(!victim.has_status_effect(/datum/status_effect/heretic_flesh_stitch), "Антимагия блокирует замедление.")
	TEST_ASSERT_EQUAL(protection.charges, 5, "Отказ в выборе защищённой цели не расходует заряды.")
	qdel(protection)
	heretic.role_removed = TRUE
	TEST_ASSERT(!stitch.can_target(victim, user, TRUE), "Снятая роль не может использовать оставшееся заклинание.")
	heretic.role_removed = FALSE
	heretic.selected_path = PATH_ASH
	TEST_ASSERT(!stitch.can_target(victim, user, TRUE), "Чужой выбранный путь не разрешает шов.")
	heretic.selected_path = PATH_FLESH
	user.Paralyze(1 SECONDS)
	TEST_ASSERT(!stitch.can_target(victim, user, TRUE), "Парализованный хозяин не может выполнить шов прямым вызовом.")
	user.SetParalyzed(0)
	var/datum/antagonist/heretic/other = allocate_heretic(get_step(user, NORTH))
	TEST_ASSERT(!stitch.can_target(victim, other.owner.current, TRUE), "Нельзя использовать чужое заклинание без знания.")
	TEST_ASSERT(!stitch.can_target(other.owner.current, user, TRUE), "Другой еретик не становится вражеской целью.")
	victim.forceMove(get_step(user, NORTHEAST))
	var/obj/structure/closet/east_blocker = allocate(/obj/structure/closet, get_step(user, EAST))
	var/obj/structure/closet/north_blocker = allocate(/obj/structure/closet, get_step(user, NORTH))
	TEST_ASSERT(!stitch.can_target(victim, user, TRUE), "Сухожилие не проходит по диагонали между закрытыми преградами.")
	qdel(east_blocker)
	qdel(north_blocker)
	TEST_ASSERT(stitch.can_target(victim, user, TRUE), "Свободная диагональ доступна.")
	var/turf/distant = locate(user.x + stitch.range + 1, user.y, user.z)
	victim.forceMove(distant)
	TEST_ASSERT(!stitch.can_target(victim, user, TRUE), "За пределами пяти клеток шов не действует.")

/// Спасение расходует биомассу, лечит своего слугу и перемещает его обычными шагами.
/datum/unit_test/heretic_flesh_stitch_rescue/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_FLESH
	var/mob/living/user = heretic.owner.current
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_flesh)
	heretic.gain_knowledge(/datum/eldritch_knowledge/flesh_grasp)
	var/datum/eldritch_knowledge/base_flesh/path = heretic.get_knowledge(/datum/eldritch_knowledge/base_flesh)
	var/datum/eldritch_knowledge/flesh_grasp/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/flesh_grasp)
	var/obj/effect/proc_holder/spell/pointed/heretic_flesh_stitch/stitch = knowledge.granted_spell
	var/turf/destination = locate(user.x + 3, user.y, user.z)
	var/mob/living/body = allocate(/mob/living/carbon/human, destination)
	var/datum/mind/soul = allocate_mind()
	soul.current = body
	body.mind = soul
	var/datum/antagonist/heretic_monster/monster = allocate(/datum/antagonist/heretic_monster)
	monster.owner = soul
	monster.master = heretic
	soul.antag_datums = list(monster)
	body.adjustBruteLoss(30)
	body.adjustFireLoss(30)
	path.combat_resource = 1
	stitch.cast(list(body), user)
	TEST_ASSERT_EQUAL(path.combat_resource, 0, "Спасение стоит одну биомассу.")
	TEST_ASSERT(abs(body.getBruteLoss() - 15) <= DAMAGE_PRECISION && abs(body.getFireLoss() - 15) <= DAMAGE_PRECISION, "Шов восстанавливает по 15 ушибов и ожогов.")
	TEST_ASSERT_EQUAL(get_dist(body, user), 1, "Шов подтягивает слугу ровно на два шага.")
	TEST_ASSERT(!body.has_status_effect(/datum/status_effect/heretic_flesh_stitch), "Свой слуга не получает замедление.")
	body.forceMove(destination)
	stitch.cast(list(body), user)
	TEST_ASSERT_EQUAL(get_turf(body), destination, "Без биомассы слуга остаётся на месте.")
	TEST_ASSERT(abs(body.getBruteLoss() - 15) <= DAMAGE_PRECISION, "Без биомассы нет бесплатного лечения.")
	path.combat_resource = 1
	body.anchored = TRUE
	stitch.cast(list(body), user)
	TEST_ASSERT_EQUAL(get_turf(body), destination, "Закреплённый слуга лечится без перемещения.")
	TEST_ASSERT(abs(body.getBruteLoss()) <= DAMAGE_PRECISION, "Закрепление не мешает лечению.")
	path.combat_resource = 1
	TEST_ASSERT(!stitch.can_target(body, user, TRUE), "Полностью здоровый неподвижный слуга не расходует биомассу впустую.")
	body.anchored = FALSE
	var/datum/component/anti_magic/protection = body.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5)
	stitch.cast(list(body), user)
	TEST_ASSERT_EQUAL(path.combat_resource, 1, "Защита своего слуги не расходует биомассу.")
	TEST_ASSERT_EQUAL(get_turf(body), destination, "Антимагия запрещает подтягивание своего слуги.")
	TEST_ASSERT_EQUAL(protection.charges, 5, "Неудачная помощь не расходует защиту своего слуги.")
	qdel(protection)
	var/datum/antagonist/heretic/other = allocate_heretic(get_step(user, NORTH))
	monster.master = other
	path.combat_resource = 1
	TEST_ASSERT(!stitch.can_target(body, user, TRUE), "Чужого слугу нельзя ни перетянуть, ни ранить.")
	body.stat = DEAD
	monster.master = heretic
	TEST_ASSERT(!stitch.can_target(body, user, TRUE), "Шов не поднимает мёртвую свиту.")

/// Заклинание Живого шва заменяется при смене тела и удаляется вместе со знанием.
/datum/unit_test/heretic_flesh_stitch_lifecycle/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_FLESH
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_flesh)
	heretic.gain_knowledge(/datum/eldritch_knowledge/flesh_grasp)
	var/datum/eldritch_knowledge/flesh_grasp/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/flesh_grasp)
	var/obj/effect/proc_holder/spell/old_spell = knowledge.granted_spell
	TEST_ASSERT_NOTNULL(old_spell, "Изучение Хватки Плоти выдаёт Живой шов.")
	var/mob/living/new_body = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, NORTH))
	heretic.owner.transfer_to(new_body)
	TEST_ASSERT(QDELETED(old_spell), "Смена тела удаляет старый экземпляр заклинания.")
	TEST_ASSERT(!QDELETED(knowledge.granted_spell), "Новое тело получает действующее заклинание.")
	var/obj/effect/proc_holder/spell/new_spell = knowledge.granted_spell
	qdel(knowledge)
	TEST_ASSERT(QDELETED(new_spell), "Удаление знания отзывает заклинание.")
