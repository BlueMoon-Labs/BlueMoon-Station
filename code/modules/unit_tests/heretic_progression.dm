/// Побочная награда оплачивает эксперименты, но не позволяет обходить основную линию.
/datum/unit_test/heretic_side_knowledge_budget/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	heretic.knowledge_points = 0
	heretic.side_knowledge_points = 2
	TEST_ASSERT(heretic.research_knowledge(/datum/eldritch_knowledge/base_ash, user), "Начальный обет остаётся бесплатным.")
	TEST_ASSERT(!heretic.research_knowledge(/datum/eldritch_knowledge/ashen_grasp, user), "Побочные очки не оплачивают основную ступень.")
	TEST_ASSERT(!heretic.research_knowledge(/datum/eldritch_knowledge/armor, user), "Побочные очки не обходят требование ступени.")
	TEST_ASSERT(heretic.research_knowledge(/datum/eldritch_knowledge/spell/silence, user), "Побочное знание доступно при нулевом основном балансе.")
	TEST_ASSERT_EQUAL(heretic.side_knowledge_points, 1, "Стоимость списывается с побочного баланса.")
	TEST_ASSERT_EQUAL(heretic.knowledge_points, 0, "Основной баланс не уходит в минус.")
	TEST_ASSERT(!heretic.research_knowledge(/datum/eldritch_knowledge/spell/silence, user), "Повторная покупка запрещена.")
	TEST_ASSERT_EQUAL(heretic.side_knowledge_points, 1, "Отказ не расходует остаток.")
	heretic.path_stage = 2
	heretic.knowledge_points = 3
	var/datum/eldritch_knowledge/armor/armor_type = /datum/eldritch_knowledge/armor
	TEST_ASSERT(heretic.research_knowledge(armor_type, user), "Общую стоимость можно оплатить двумя балансами.")
	TEST_ASSERT_EQUAL(heretic.side_knowledge_points, 0, "Побочные очки расходуются первыми.")
	TEST_ASSERT_EQUAL(heretic.knowledge_points, 4 - initial(armor_type.cost), "Общие знания покрывают только остаток стоимости.")
	var/obj/item/forbidden_book/book = allocate(/obj/item/forbidden_book, user)
	var/list/data = book.ui_data(user)
	TEST_ASSERT_EQUAL(data["side_points"], heretic.side_knowledge_points, "Кодекс передаёт отдельный баланс.")

/datum/unit_test/heretic_ascension_objective/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.forge_primary_objectives()
	var/datum/objective/ascend_ecult/ascension = locate() in heretic.objectives
	TEST_ASSERT(ascension, "Вознесение явно присутствует среди целей роли.")
	TEST_ASSERT(!ascension.check_completion(), "Начальная цель вознесения не выполнена.")
	heretic.total_sacrifices = HERETIC_ASCENSION_SACRIFICES
	TEST_ASSERT(!ascension.check_completion(), "Количество душ не заменяет финальный обряд.")
	heretic.ascended = TRUE
	TEST_ASSERT(ascension.check_completion(), "Завершённый финал выполняет цель.")

/// Щелчок выбирает только свою звезду и не тратит заряд при заблокированном выходе.
/datum/unit_test/heretic_starwalk_targeting/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	heretic.selected_path = PATH_COSMIC
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_cosmic)
	var/datum/eldritch_knowledge/base_cosmic/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/base_cosmic)
	var/turf/origin = get_turf(user)
	var/turf/destination = get_step(get_step(origin, EAST), EAST)
	knowledge.add_star(origin, user)
	user.forceMove(destination)
	knowledge.add_star(destination, user)
	user.forceMove(origin)
	var/obj/structure/heretic_star/star = knowledge.stars[2]
	var/obj/effect/proc_holder/spell/self/cosmic/step/spell = allocate(/obj/effect/proc_holder/spell/self/cosmic/step)
	TEST_ASSERT(istype(spell, /obj/effect/proc_holder/spell/pointed), "Дорога использует выбор на карте.")
	TEST_ASSERT(spell.can_target(star, user, TRUE), "Своя звезда доступна для прицеливания.")
	var/obj/structure/heretic_star/foreign_star = allocate(/obj/structure/heretic_star, get_step(origin, NORTH))
	TEST_ASSERT(!spell.can_target(foreign_star, user, TRUE), "Чужая звезда не даёт бесплатного перемещения.")
	var/obj/structure/closet/crate/blocker = allocate(/obj/structure/closet/crate, destination)
	spell.charge_counter = 0
	spell.cast(list(star), user)
	TEST_ASSERT_EQUAL(get_turf(user), origin, "Закрытая точка оставляет еретика на месте.")
	TEST_ASSERT_EQUAL(spell.charge_counter, spell.charge_max, "Неудачное перемещение возвращает заряд.")
	qdel(blocker)
	spell.cast(list(star), user)
	TEST_ASSERT_EQUAL(get_turf(user), destination, "Свободная выбранная точка принимает путешественника.")

/datum/unit_test/heretic_rift_warning/Run()
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/obj/effect/broken_illusion/rift = allocate(/obj/effect/broken_illusion, run_loc_floor_bottom_left)
	TEST_ASSERT(rift.touch_mansus(victim), "Первое прикосновение вызывает предупреждение.")
	TEST_ASSERT_EQUAL(victim.getBruteLoss(), 0, "Предупреждение не наносит ран.")
	TEST_ASSERT(victim.has_status_effect(/datum/status_effect/heretic_rift_exposure), "Опасность повторного прикосновения имеет видимый статус.")
	TEST_ASSERT(rift.touch_mansus(victim, TRUE), "Телекинез не обходит предупреждение.")
	TEST_ASSERT_EQUAL(victim.getBruteLoss(), 20, "Повторное прикосновение ранит.")
	victim.remove_status_effect(/datum/status_effect/heretic_rift_exposure)
	rift.touch_mansus(victim)
	TEST_ASSERT_EQUAL(victim.getBruteLoss(), 20, "После окончания воздействия разлом снова предупреждает.")

/// Повреждение экипировки ограничено и не уничтожает вещи с содержимым.
/datum/unit_test/heretic_rust_equipment/Run()
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/obj/item/storage/backpack/bag = allocate(/obj/item/storage/backpack, victim)
	victim.put_in_hands(bag)
	var/integrity_before = bag.obj_integrity
	var/datum/status_effect/eldritch/rust/mark = victim.apply_status_effect(/datum/status_effect/eldritch/rust)
	mark.on_effect()
	TEST_ASSERT(bag.obj_integrity < integrity_before, "Метка повреждает предмет в руке.")
	bag.obj_integrity = 1
	mark = victim.apply_status_effect(/datum/status_effect/eldritch/rust)
	mark.on_effect()
	TEST_ASSERT(!QDELETED(bag), "Метка не уничтожает уже повреждённую сумку.")
	TEST_ASSERT_EQUAL(bag.obj_integrity, 1, "Метка не лечит и не добивает слабый предмет.")

/// Наложенные домены делят один эффект экрана, удаление последнего его снимает.
/datum/unit_test/heretic_domain_presence_cleanup/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	var/obj/effect/domain_expansion/first = allocate(/obj/effect/domain_expansion, get_turf(user), 2, 20 SECONDS, list(user), FALSE)
	var/obj/effect/domain_expansion/second = allocate(/obj/effect/domain_expansion, get_turf(user), 2, 20 SECONDS, list(user), FALSE)
	first.tick_zone(user)
	first.tick_zone(user)
	second.tick_zone(user)
	var/datum/status_effect/heretic_domain/presence = victim.has_status_effect(/datum/status_effect/heretic_domain)
	TEST_ASSERT(presence, "Жертва видит воздействие домена.")
	TEST_ASSERT_EQUAL(length(presence.domains), 2, "Повторные тики не размножают источники.")
	TEST_ASSERT(!user.has_status_effect(/datum/status_effect/heretic_domain), "Хозяин не получает враждебное воздействие.")
	qdel(first)
	TEST_ASSERT(!QDELETED(presence), "Оставшийся домен сохраняет эффект.")
	qdel(second)
	TEST_ASSERT(QDELETED(presence), "Последний удалённый домен снимает эффект.")
	TEST_ASSERT(!(locate(/datum/client_colour/heretic_domain) in victim.client_colours), "Покраска экрана не остаётся после домена.")

/// Выход из наложенных доменов сразу снимает только те эффекты, чья граница пересечена.
/datum/unit_test/heretic_domain_exit/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	var/turf/center = get_step(get_step(user, EAST), NORTH)
	var/mob/living/victim = allocate(/mob/living/carbon/human, center)
	var/obj/effect/domain_expansion/small = allocate(/obj/effect/domain_expansion, center, 1, 20 SECONDS, list(user), FALSE)
	var/obj/effect/domain_expansion/large = allocate(/obj/effect/domain_expansion, center, 2, 20 SECONDS, list(user), FALSE)
	small.tick_zone(user)
	large.tick_zone(user)
	var/datum/status_effect/heretic_domain/presence = victim.has_status_effect(/datum/status_effect/heretic_domain)
	TEST_ASSERT_NOTNULL(presence, "Перекрытие доменов должно наложить эффект присутствия.")
	victim.forceMove(get_step(get_step(center, EAST), EAST))
	TEST_ASSERT(!victim.has_movespeed_modifier(REF(small)), "Выход из малого домена сразу освобождает его замедление.")
	TEST_ASSERT(victim.has_movespeed_modifier(REF(large)), "Большой домен продолжает замедлять цель внутри.")
	TEST_ASSERT_EQUAL(length(presence.domains), 1, "Присутствие остаётся только от большого домена.")
	victim.forceMove(run_loc_floor_top_right)
	TEST_ASSERT(!victim.has_movespeed_modifier(REF(large)), "Выход из последнего домена снимает замедление без тика.")
	TEST_ASSERT(QDELETED(presence), "Выход снимает последнее присутствие без тика.")
	TEST_ASSERT(!(locate(/datum/client_colour/heretic_domain) in victim.client_colours), "После выхода экран сразу освобождается от окраски домена.")

/// Призывы разных знаний учитывают общий предел свиты одного еретика.
/datum/unit_test/heretic_shared_servant_limit/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_FLESH
	var/datum/eldritch_knowledge/first = allocate(/datum/eldritch_knowledge/flesh_grasp)
	var/datum/eldritch_knowledge/second = allocate(/datum/eldritch_knowledge/summon/ashy)
	heretic.researched_knowledge[first.type] = first
	heretic.researched_knowledge[second.type] = second
	TEST_ASSERT(heretic.can_add_servant(), "Пустая свита принимает слугу.")
	for(var/index in 1 to 4)
		var/datum/mind/servant_mind = new
		allocated += servant_mind
		var/mob/living/carbon/human/servant_body = allocate(/mob/living/carbon/human)
		servant_mind.current = servant_body
		servant_body.mind = servant_mind
		var/datum/antagonist/heretic_monster/servant = allocate(/datum/antagonist/heretic_monster)
		servant.owner = servant_mind
		servant.silent = TRUE
		servant_mind.antag_datums = list(servant)
		if(index <= 2)
			first.track_flesh_servant(servant)
		else
			second.track_flesh_servant(servant)
	TEST_ASSERT(!heretic.can_add_servant(), "Два знания не обходят общий предел четырёх слуг.")
	heretic.ascended = TRUE
	TEST_ASSERT(heretic.can_add_servant(), "Вознесённая Плоть расширяет свиту.")
	heretic.selected_path = PATH_ASH
	TEST_ASSERT(!heretic.can_add_servant(), "Вознесение другого пути не увеличивает предел Плоти.")
	qdel(first.flesh_servants[1])
	TEST_ASSERT(heretic.can_add_servant(), "Удаление слуги освобождает место независимо от знания.")
