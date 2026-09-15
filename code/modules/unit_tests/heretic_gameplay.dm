/// Магическое лечение восстанавливает протезы и соблюдает общий бюджет и запрет лечения.
/datum/unit_test/heretic_gameplay/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	user.set_species(/datum/species/android)
	user.adjustBruteLoss(12)
	user.adjustFireLoss(20)
	TEST_ASSERT(abs(heretic_heal_pool(user, 22) - 22) < 0.1, "Бюджет распределяется между ушибами и ожогами синтетика.")
	TEST_ASSERT(abs(user.getBruteLoss()) < 0.1, "Протезы восстанавливают ушибы.")
	TEST_ASSERT(abs(user.getFireLoss() - 10) < 0.1, "Остаток бюджета восстанавливает ожоги.")
	ADD_TRAIT(user, TRAIT_NONATURALHEAL, REF(src))
	TEST_ASSERT_EQUAL(heretic_heal_pool(user, 20), 0, "Магия не обходит запрет обычного лечения.")
	TEST_ASSERT(abs(user.getFireLoss() - 10) < 0.1, "Запрещённое лечение не меняет повреждения.")
	REMOVE_TRAIT(user, TRAIT_NONATURALHEAL, REF(src))
	TEST_ASSERT(abs(heretic_heal_pool(user, 20) - 10) < 0.1, "Возвращается фактическое, а не запрошенное лечение.")

/// Коррозия сохраняет обычный бюджет и не лечит слизней или синтетиков.
/datum/unit_test/heretic_gameplay/corrosion/Run()
	var/mob/living/carbon/human/organic = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/synthetic = allocate(/mob/living/carbon/human)
	synthetic.set_species(/datum/species/android)
	var/mob/living/carbon/human/jelly = allocate(/mob/living/carbon/human)
	jelly.set_species(/datum/species/jelly)
	jelly.setToxLoss(5, forced = TRUE)
	var/mob/living/silicon/robot/borg = allocate(/mob/living/silicon/robot)
	for(var/mob/living/victim as anything in list(organic, synthetic, jelly, borg))
		heretic_corrosion(victim, 15)
		TEST_ASSERT(abs(victim.getFireLoss() - 5) < 0.1, "Коррозия наносит пять прямых ожогов [victim.type].")
	TEST_ASSERT(abs(organic.getToxLoss() - 10) < 0.1, "Органика получает оставшиеся десять урона отравлением.")
	TEST_ASSERT(abs(synthetic.getToxLoss() - 10) < 0.1, "Синтетик получает оставшиеся десять урона системам.")
	TEST_ASSERT_EQUAL(jelly.getToxLoss(), 5, "Слизень не получает лечебный токсин.")

/// Урон ржавого пола ограничен на всё тело и прекращается при появлении антимагии.
/datum/unit_test/heretic_gameplay/rusted_floor/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	user.set_species(/datum/species/android)
	var/datum/status_effect/rust_corruption/rust = user.apply_status_effect(/datum/status_effect/rust_corruption)
	rust.tick()
	TEST_ASSERT(abs(user.getBruteLoss() - 10) < 0.1, "Шесть протезов делят десять урона, а не получают по десять каждый.")
	TEST_ASSERT(abs(user.getFireLoss() + user.getToxLoss() - 4) < 0.1, "Общий бюджет коррозии пола составляет четыре единицы.")
	user.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5)
	var/damage = user.getBruteLoss() + user.getFireLoss() + user.getToxLoss()
	rust.tick()
	TEST_ASSERT(QDELETED(rust), "Полученная на месте антимагия снимает коррозию.")
	TEST_ASSERT_EQUAL(user.getBruteLoss() + user.getFireLoss() + user.getToxLoss(), damage, "Снятый эффект больше не повреждает тело.")

/// Пепел и Плоть сохраняют прямой урон по негорящему бескровному телу.
/datum/unit_test/heretic_gameplay/blade_compatibility/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human)
	victim.set_species(/datum/species/android)
	var/datum/eldritch_knowledge/ash_blade_upgrade/ash = allocate(/datum/eldritch_knowledge/ash_blade_upgrade)
	ash.passive_level = 3
	ash.on_eldritch_blade(victim, user, TRUE)
	TEST_ASSERT(!victim.on_fire, "Невоспламеняемость сохраняется.")
	TEST_ASSERT(abs(victim.getFireLoss() - 6) < 0.1, "Усиленный Пепел наносит шесть прямых ожогов.")
	var/datum/eldritch_knowledge/flesh_blade_upgrade/flesh = allocate(/datum/eldritch_knowledge/flesh_blade_upgrade)
	flesh.passive_level = 3
	flesh.on_eldritch_blade(victim, user, TRUE)
	TEST_ASSERT(abs(victim.getBruteLoss() - 4) < 0.1, "Усиленная Плоть наносит четыре ушиба бескровной цели.")

/// Пустота восстанавливает один резерв в тепле и расходует подготовленную скованность для усиленной хватки.
/datum/unit_test/heretic_gameplay/void_reserve/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_void)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_void/path = heretic.get_knowledge(/datum/eldritch_knowledge/base_void)
	path.combat_resource = 0
	path.on_life(user)
	TEST_ASSERT_EQUAL(path.combat_resource, 1, "Тёплый пол не запирает путь без осколков.")
	COOLDOWN_RESET(path, resource_harvest)
	path.on_life(user)
	TEST_ASSERT_EQUAL(path.combat_resource, 1, "В тепле резерв не растёт выше одного.")
	var/datum/eldritch_knowledge/void_grasp/grasp = allocate(/datum/eldritch_knowledge/void_grasp)
	grasp.passive_level = 3
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human)
	grasp.on_mansus_grasp(victim, user, TRUE)
	TEST_ASSERT_EQUAL(victim.getFireLoss(), 0, "Первая хватка только подготавливает цель.")
	grasp.on_mansus_grasp(victim, user, TRUE)
	TEST_ASSERT(abs(victim.getFireLoss() - 10) < 0.1, "Повторная хватка наносит десять ожогов независимо от температуры.")

/// Кадильница забирает только собственный след и действительно прекращает его работу.
/datum/unit_test/heretic_gameplay/ash_trail/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_ash)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/path = heretic.get_knowledge(/datum/eldritch_knowledge/base_ash)
	var/obj/item/heretic_relic/censer/censer = allocate(/obj/item/heretic_relic/censer)
	user.put_in_hands(censer)
	var/obj/effect/heretic_combat_zone/ash/trail = allocate(/obj/effect/heretic_combat_zone/ash, get_turf(user), user.mind)
	TEST_ASSERT(!censer.capture_trail(user, trail), "Несвязанный след не становится топливом.")
	path.combat_zone = trail
	path.track_combat_effect(trail)
	TEST_ASSERT(censer.capture_trail(user, trail), "Свой след можно пожертвовать.")
	TEST_ASSERT(QDELETED(trail), "Собранная область прекращает гореть.")
	TEST_ASSERT_NULL(path.combat_zone, "Знание освобождает ссылку на след.")
	TEST_ASSERT_EQUAL(censer.stored_fire, 1, "Один след даёт ровно один заряд пламени.")
	TEST_ASSERT(!censer.capture_trail(user, trail), "Удалённый след нельзя собрать повторно.")

/// Разрыв сердца расходует лечащую область, соблюдает владение и защищает союзников.
/datum/unit_test/heretic_gameplay/rust_heart/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_rust)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/path = heretic.get_knowledge(/datum/eldritch_knowledge/base_rust)
	var/obj/structure/heretic_rust_heart/heart = allocate(/obj/structure/heretic_rust_heart, get_turf(user), user.mind, path)
	var/obj/effect/heretic_combat_zone/zone = heart.zone
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	zone.field_turfs = list(get_turf(user), get_turf(victim))
	TEST_ASSERT(!heart.burst(victim), "Посторонний не взрывает чужое сердце.")
	TEST_ASSERT(heart.burst(user), "Хозяин может пожертвовать сердцем.")
	TEST_ASSERT(abs(victim.getFireLoss() + victim.getToxLoss() - 18) < 0.1, "Разрыв наносит восемнадцать коррозии.")
	TEST_ASSERT_EQUAL(user.getFireLoss() + user.getToxLoss(), 0, "Хозяин не попадает под свой разрыв.")
	TEST_ASSERT(QDELETED(heart) && QDELETED(zone), "После разрыва нет ни сердца, ни лечащего поля.")

/// Повторное погашение обычного огня восстанавливает уголёк после задержки даже без нового дела.
/datum/unit_test/heretic_gameplay/ash_flame_harvest/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_ASH
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_ash)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_ash/path = heretic.get_knowledge(/datum/eldritch_knowledge/base_ash)
	var/obj/item/lighter/lighter = allocate(/obj/item/lighter, get_turf(user))
	lighter.set_lit(TRUE)
	TEST_ASSERT(path.on_mansus_grasp(lighter, user, TRUE), "Хватка гасит огонь.")
	path.combat_resource = 0
	COOLDOWN_RESET(path, resource_harvest)
	lighter.set_lit(TRUE)
	TEST_ASSERT(path.on_mansus_grasp(lighter, user, TRUE), "Можно погасить огонь на уже использованной клетке.")
	TEST_ASSERT_EQUAL(path.combat_resource, 1, "Огонь даёт уголёк без повторного дела.")
	lighter.set_lit(TRUE)
	path.on_mansus_grasp(lighter, user, TRUE)
	TEST_ASSERT_EQUAL(path.combat_resource, 1, "Повторный клик не обходит задержку добычи.")

/// Сифон лечит синтетика, но не создаёт переливаемую кровь из бескровной жертвы.
/datum/unit_test/heretic_gameplay/siphon/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	victim.set_species(/datum/species/android)
	var/obj/effect/proc_holder/spell/pointed/blood_siphon/spell = allocate(/obj/effect/proc_holder/spell/pointed/blood_siphon)
	user.blood_volume = BLOOD_VOLUME_NORMAL - 40
	user.integrating_blood = 0
	user.adjustBruteLoss(30)
	spell.cast(list(victim), user)
	TEST_ASSERT_EQUAL(user.integrating_blood, 0, "Бескровная цель не создаёт кровь для усвоения.")
	TEST_ASSERT(abs(user.getBruteLoss() - 10) < 0.1, "Прямое лечение не зависит от наличия крови у жертвы.")
	user.set_species(/datum/species/android)
	user.adjustBruteLoss(30)
	var/before = user.getBruteLoss()
	spell.cast(list(victim), user)
	TEST_ASSERT(abs(user.getBruteLoss() - before + 20) < 0.1, "Сифон восстанавливает и роботизированные конечности владельца.")

/// Ползун требует изученного ритуала и биомассы, занимает общий слот и удаляется вместе со знанием.
/datum/unit_test/heretic_gameplay/fleshling/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_FLESH
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_flesh)
	var/mob/living/user = heretic.owner.current
	user.a_intent = INTENT_DISARM
	var/datum/eldritch_knowledge/base_flesh/path = heretic.get_knowledge(/datum/eldritch_knowledge/base_flesh)
	var/obj/item/organ/organ = allocate(/obj/item/organ/heart, get_turf(user))
	TEST_ASSERT(!path.grow_fleshling(user, organ), "До Незавершённого ритуала ползун недоступен.")
	heretic.gain_knowledge(/datum/eldritch_knowledge/flesh_ghoul)
	path.combat_resource = 1
	TEST_ASSERT(!path.grow_fleshling(user, organ), "Одна биомасса не оплачивает призыв.")
	TEST_ASSERT(!QDELETED(organ), "Отказ сохраняет орган.")
	path.combat_resource = 2
	TEST_ASSERT(path.on_mansus_grasp(organ, user, TRUE), "Хватка на разоружении создаёт ползуна.")
	TEST_ASSERT(QDELETED(organ), "Призыв расходует орган.")
	TEST_ASSERT_EQUAL(path.combat_resource, 0, "Призыв стоит две биомассы.")
	var/mob/living/simple_animal/heretic_fleshling/crawler = path.fleshling
	TEST_ASSERT_NOTNULL(crawler, "Ползун появляется без призрака.")
	TEST_ASSERT_EQUAL(length(path.flesh_servants), 1, "Ползун учтён в общей свите.")
	for(var/index in 1 to 3)
		var/datum/antagonist/heretic_monster/servant = allocate(/datum/antagonist/heretic_monster)
		var/datum/mind/servant_mind = allocate_mind()
		var/mob/living/body = allocate(/mob/living/carbon/human)
		servant_mind.current = body
		body.mind = servant_mind
		servant.set_master(heretic)
		servant_mind.add_antag_datum(servant)
		path.track_flesh_servant(servant)
	TEST_ASSERT(!heretic.can_add_servant(), "Ползун вместе с тремя слугами заполняет общий предел четырёх.")
	path.combat_resource = 2
	var/obj/item/organ/second = allocate(/obj/item/organ/heart, get_turf(user))
	TEST_ASSERT(!path.grow_fleshling(user, second), "Второго ползуна одновременно призвать нельзя.")
	heretic.gain_knowledge(/datum/eldritch_knowledge/flesh_grasp)
	var/datum/eldritch_knowledge/flesh_grasp/grasp = heretic.get_knowledge(/datum/eldritch_knowledge/flesh_grasp)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	grasp.granted_spell.cast(list(victim), user)
	TEST_ASSERT_EQUAL(crawler.prey_ref?.resolve(), victim, "Живой шов действительно назначает ползуну врага.")
	var/stitch_damage = victim.getBruteLoss()
	TEST_ASSERT(stitch_damage > 0, "Шов нанёс первый урон.")
	crawler.process()
	TEST_ASSERT(victim.getBruteLoss() > stitch_damage, "Ползун добавляет собственную атаку по указанному швом врагу.")
	var/damage = victim.getBruteLoss()
	crawler.process()
	TEST_ASSERT_EQUAL(victim.getBruteLoss(), damage, "Повторная обработка не обходит задержку удара.")
	qdel(path)
	TEST_ASSERT(QDELETED(crawler), "Удаление знания сразу удаляет ползуна.")

/// Смерть и перенос хозяина прекращают существование ползуна и освобождают место.
/datum/unit_test/heretic_gameplay/fleshling_transfer/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.apply_innate_effects(heretic.owner.current)
	heretic.selected_path = PATH_FLESH
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_flesh)
	heretic.gain_knowledge(/datum/eldritch_knowledge/flesh_ghoul)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_flesh/path = heretic.get_knowledge(/datum/eldritch_knowledge/base_flesh)
	var/obj/item/organ/organ = allocate(/obj/item/organ/heart, get_turf(user))
	TEST_ASSERT(path.grow_fleshling(user, organ), "Ползун создаётся.")
	var/mob/living/simple_animal/heretic_fleshling/crawler = path.fleshling
	var/mob/living/carbon/human/new_body = allocate(/mob/living/carbon/human, get_step(user, NORTH))
	heretic.owner.transfer_to(new_body)
	TEST_ASSERT(QDELETED(crawler), "Смена тела не оставляет автономного слугу старого тела.")
	TEST_ASSERT_NULL(path.fleshling, "Знание отпускает удалённого ползуна.")

/// Удаление ритуала сразу убирает ползуна и освобождает его место в свите.
/datum/unit_test/heretic_gameplay/fleshling_prerequisite/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_FLESH
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_flesh)
	heretic.gain_knowledge(/datum/eldritch_knowledge/flesh_ghoul)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_flesh/path = heretic.get_knowledge(/datum/eldritch_knowledge/base_flesh)
	var/obj/item/organ/organ = allocate(/obj/item/organ/heart, get_turf(user))
	TEST_ASSERT(path.grow_fleshling(user, organ), "Ползун создаётся после исследования ритуала.")
	var/mob/living/simple_animal/heretic_fleshling/crawler = path.fleshling
	qdel(heretic.get_knowledge(/datum/eldritch_knowledge/flesh_ghoul))
	TEST_ASSERT(QDELETED(crawler), "Удаление ритуала не оставляет слугу до конца его срока.")
	TEST_ASSERT_NULL(path.fleshling, "Базовое знание освобождает ссылку.")

/// Ползун учитывает обездвиживание, запрет действий и контейнеры обеих сторон.
/datum/unit_test/heretic_gameplay/fleshling_restraints/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic(get_step(run_loc_floor_bottom_left, NORTHEAST))
	heretic.selected_path = PATH_FLESH
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_flesh)
	heretic.gain_knowledge(/datum/eldritch_knowledge/flesh_ghoul)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_flesh/path = heretic.get_knowledge(/datum/eldritch_knowledge/base_flesh)
	var/obj/item/organ/organ = allocate(/obj/item/organ/heart, get_turf(user))
	TEST_ASSERT(path.grow_fleshling(user, organ), "Создан ползун для проверки ограничений.")
	var/mob/living/simple_animal/heretic_fleshling/crawler = path.fleshling
	STOP_PROCESSING(SSfastprocess, crawler)
	var/turf/origin = get_turf(crawler)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, get_step(get_step(user, EAST), EAST))
	TEST_ASSERT(crawler.command_prey(user, victim), "Дальняя цель назначена.")
	crawler.movement_path = list(get_step(crawler, EAST))
	var/original_mobility = crawler.mobility_flags
	crawler.mobility_flags &= ~MOBILITY_MOVE
	crawler.process()
	TEST_ASSERT_EQUAL(get_turf(crawler), origin, "Обездвиженный ползун не шагает по готовому пути.")
	crawler.mobility_flags = original_mobility & ~MOBILITY_USE
	victim.forceMove(get_step(crawler, EAST))
	crawler.process()
	TEST_ASSERT_EQUAL(victim.getBruteLoss(), 0, "Запрет действий останавливает укус соседней цели.")
	crawler.mobility_flags = original_mobility
	var/obj/structure/closet/closet = allocate(/obj/structure/closet, origin)
	crawler.forceMove(closet)
	crawler.process()
	TEST_ASSERT_EQUAL(crawler.loc, closet, "Обработка не вытаскивает ползуна из шкафа.")
	TEST_ASSERT_EQUAL(victim.getBruteLoss(), 0, "Ползун не атакует из шкафа.")
	crawler.forceMove(origin)
	victim.forceMove(closet)
	TEST_ASSERT(!crawler.command_prey(user, victim), "Нельзя назначить цель внутри шкафа.")
	crawler.process()
	TEST_ASSERT_NULL(crawler.prey_ref, "Уход назначенной цели в шкаф отменяет преследование.")
	TEST_ASSERT_EQUAL(victim.getBruteLoss(), 0, "Содержимое шкафа не получает урон через соседство.")

/// Ограниченный маршрут обходит угол и не позволяет шагать чаще установленной задержки.
/datum/unit_test/heretic_gameplay/fleshling_follow_path/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic(get_step(run_loc_floor_bottom_left, NORTHEAST))
	heretic.selected_path = PATH_FLESH
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_flesh)
	heretic.gain_knowledge(/datum/eldritch_knowledge/flesh_ghoul)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_flesh/path = heretic.get_knowledge(/datum/eldritch_knowledge/base_flesh)
	var/obj/item/organ/organ = allocate(/obj/item/organ/heart, get_turf(user))
	TEST_ASSERT(path.grow_fleshling(user, organ), "Ползун создан перед поворотом маршрута.")
	var/mob/living/simple_animal/heretic_fleshling/crawler = path.fleshling
	STOP_PROCESSING(SSfastprocess, crawler)
	var/obj/blocker = allocate(/obj, get_step(user, EAST))
	blocker.density = TRUE
	blocker.opacity = TRUE
	user.forceMove(get_step(get_step(get_step(get_step(user, EAST), EAST), EAST), EAST))
	TEST_ASSERT(!can_see(crawler, user, 9), "Прямую видимость хозяина перекрывает угол.")
	crawler.plan_path(user)
	TEST_ASSERT(length(crawler.movement_path), "Поиск находит обход препятствия.")
	COOLDOWN_START(crawler, path_cooldown, 1 SECONDS)
	var/turf/origin = get_turf(crawler)
	crawler.process()
	var/turf/first_step = get_turf(crawler)
	TEST_ASSERT(first_step != origin && first_step != get_turf(blocker), "Ползун обходит препятствие обычным шагом.")
	crawler.process()
	TEST_ASSERT_EQUAL(get_turf(crawler), first_step, "Частая обработка не ускоряет второй шаг.")
	for(var/index in 1 to 12)
		COOLDOWN_RESET(crawler, step_cooldown)
		crawler.process()
	TEST_ASSERT(crawler.Adjacent(user), "Ползун возвращается к хозяину по найденному обходу.")
