/// Все пути получают личные улучшения с проверкой цены, уровня и доступности.
/datum/unit_test/heretic_passives/Run()
	for(var/path_id in GLOB.heretic_paths)
		var/datum/heretic_path/path = GLOB.heretic_paths[path_id]
		var/datum/antagonist/heretic/heretic = allocate_heretic()
		var/mob/living/user = heretic.owner.current
		heretic.selected_path = path_id
		heretic.path_stage = 8
		heretic.knowledge_points = 1
		heretic.side_knowledge_points = 2
		var/passive_count = 0
		for(var/knowledge_type in path.knowledge)
			var/datum/eldritch_knowledge/prototype = allocate(knowledge_type)
			if(!length(prototype.passive_values))
				continue
			passive_count++
			TEST_ASSERT(!heretic.upgrade_passive(knowledge_type, user, 1), "Неизученная пассивка недоступна.")
			heretic.gain_knowledge(knowledge_type)
			var/datum/eldritch_knowledge/knowledge = heretic.get_knowledge(knowledge_type)
			TEST_ASSERT(heretic.upgrade_passive(knowledge_type, user, 1), "Первое улучшение доступно на пути [path_id].")
			TEST_ASSERT_EQUAL(heretic.side_knowledge_points, 1, "Побочные очки расходуются первыми.")
			TEST_ASSERT_EQUAL(heretic.knowledge_points, 1, "Обычные очки сохраняются при достаточном побочном балансе.")
			TEST_ASSERT(!heretic.upgrade_passive(knowledge_type, user, 1), "Повторный запрос старого уровня отклоняется.")
			TEST_ASSERT_EQUAL(knowledge.passive_level, 2, "Повторный клик не покупает третий уровень.")
			TEST_ASSERT(heretic.upgrade_passive(knowledge_type, user, 2), "Второе улучшение оплачивается из двух балансов.")
			TEST_ASSERT_EQUAL(heretic.knowledge_points + heretic.side_knowledge_points, 0, "Два улучшения стоят суммарно три очка.")
			TEST_ASSERT_EQUAL(knowledge.passive_level, 3, "Пассивка достигает третьего уровня.")
			TEST_ASSERT_EQUAL(prototype.passive_level, 1, "Чужие экземпляры знаний не улучшаются.")
			TEST_ASSERT(!heretic.upgrade_passive(knowledge_type, user, 3), "Выше максимума улучшать нельзя.")
			TEST_ASSERT_EQUAL(heretic.path_stage, 8, "Улучшение не продвигает по основному пути.")
		TEST_ASSERT_EQUAL(passive_count, 1, "У каждого пути есть одна прокачиваемая пассивка.")

/// Неверный владелец, чужой путь и нехватка очков не меняют прогресс.
/datum/unit_test/heretic_passives/restrictions/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/datum/antagonist/heretic/other = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	heretic.selected_path = PATH_VOID
	heretic.knowledge_points = 0
	heretic.gain_knowledge(/datum/eldritch_knowledge/void_grasp)
	heretic.gain_knowledge(/datum/eldritch_knowledge/ash_blade_upgrade)
	TEST_ASSERT(!heretic.upgrade_passive(/datum/eldritch_knowledge/void_grasp, user, 1), "Нулевого баланса недостаточно.")
	heretic.knowledge_points = 10
	TEST_ASSERT(!heretic.upgrade_passive(/datum/eldritch_knowledge/ash_blade_upgrade, user, 1), "Знание чужого пути не улучшается.")
	TEST_ASSERT(!heretic.upgrade_passive(/datum/eldritch_knowledge/void_grasp, other.owner.current, 1), "Чужое тело не может покупать улучшения.")
	TEST_ASSERT(!heretic.upgrade_passive(/obj/item, user, 1), "Посторонний путь типа отклоняется.")
	TEST_ASSERT(!heretic.upgrade_passive(null, user, 1), "Пустой идентификатор отклоняется.")
	user.Stun(1 SECONDS)
	TEST_ASSERT(!heretic.upgrade_passive(/datum/eldritch_knowledge/void_grasp, user, 1), "Оглушённый игрок не покупает улучшения.")
	user.SetStun(0)
	heretic.role_removed = TRUE
	TEST_ASSERT(!heretic.upgrade_passive(/datum/eldritch_knowledge/void_grasp, user, 1), "Удалённая роль не покупает улучшения.")
	TEST_ASSERT_EQUAL(heretic.knowledge_points, 10, "Отказы не списывают очки.")

/// Уровень и усиленное охлаждение сохраняются после переноса в новое тело и смены книги.
/datum/unit_test/heretic_passives/transfer/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/old_body = heretic.owner.current
	heretic.apply_innate_effects(old_body)
	heretic.selected_path = PATH_VOID
	heretic.gain_knowledge(/datum/eldritch_knowledge/void_grasp)
	heretic.knowledge_points = 3
	TEST_ASSERT(heretic.upgrade_passive(/datum/eldritch_knowledge/void_grasp, old_body, 1), "Второй уровень приобретён.")
	var/obj/item/forbidden_book/book = allocate(/obj/item/forbidden_book)
	var/list/before = book.ui_data(old_body)
	qdel(book)
	var/mob/living/carbon/human/new_body = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	heretic.owner.transfer_to(new_body)
	var/obj/item/forbidden_book/replacement = allocate(/obj/item/forbidden_book)
	var/list/after = replacement.ui_data(new_body)
	TEST_ASSERT_EQUAL(json_encode(before["passive_upgrades"]), json_encode(after["passive_upgrades"]), "Новая книга и тело видят прежний уровень.")
	TEST_ASSERT(heretic.upgrade_passive(/datum/eldritch_knowledge/void_grasp, new_body, 2), "Новое тело может продолжить прокачку.")
	var/datum/eldritch_knowledge/void_grasp/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/void_grasp)
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human)
	var/temperature = target.bodytemperature
	TEST_ASSERT(knowledge.on_mansus_grasp(target, new_body, TRUE), "Улучшенная хватка применяется.")
	TEST_ASSERT_EQUAL(target.bodytemperature, temperature - 50, "Третий уровень охлаждает на 50 градусов.")

/// Поджог, кровотечение, лечение и восстановление после парирования используют приобретённый уровень.
/datum/unit_test/heretic_passives/combat/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human)
	var/datum/eldritch_knowledge/ash_blade_upgrade/ash = allocate(/datum/eldritch_knowledge/ash_blade_upgrade)
	ash.passive_level = 3
	ash.on_eldritch_blade(target, user, TRUE)
	TEST_ASSERT_EQUAL(target.fire_stacks, 3, "Третий уровень даёт три заряда горения.")
	var/datum/eldritch_knowledge/flesh_blade_upgrade/flesh = allocate(/datum/eldritch_knowledge/flesh_blade_upgrade)
	flesh.passive_level = 3
	flesh.on_eldritch_blade(target, user, TRUE)
	var/bleeding = 0
	for(var/obj/item/bodypart/limb as anything in target.bodyparts)
		bleeding += limb.generic_bleedstacks
	TEST_ASSERT_EQUAL(bleeding, 4, "Третий уровень даёт четыре заряда кровотечения.")
	var/turf/rust = run_loc_floor_bottom_left.ChangeTurf(/turf/open/floor/plating/rust)
	user.forceMove(rust)
	user.adjustBruteLoss(20)
	user.adjustFireLoss(20)
	user.adjustToxLoss(10)
	user.adjustStaminaLoss(30)
	var/datum/eldritch_knowledge/rust_regen/regen = allocate(/datum/eldritch_knowledge/rust_regen)
	regen.passive_level = 3
	regen.on_life(user)
	TEST_ASSERT_EQUAL(user.getBruteLoss(), 17, "Ржавая поступь лечит три ушиба.")
	TEST_ASSERT_EQUAL(user.getFireLoss(), 17, "Ржавая поступь лечит три ожога.")
	TEST_ASSERT_EQUAL(user.getToxLoss(), 8.5, "Ржавая поступь лечит полторы единицы отравления.")
	TEST_ASSERT_EQUAL(user.getStaminaLoss(), 24, "Ржавая поступь лечит шесть выносливости.")
	user.forceMove(run_loc_floor_top_right)
	regen.on_life(user)
	TEST_ASSERT_EQUAL(user.getBruteLoss(), 17, "Улучшение не даёт лечение вне ржавчины.")
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_blade)
	heretic.gain_knowledge(/datum/eldritch_knowledge/blade_guard)
	var/datum/eldritch_knowledge/blade_guard/guard = heretic.get_knowledge(/datum/eldritch_knowledge/blade_guard)
	guard.passive_level = 3
	var/datum/eldritch_knowledge/base_blade/blade = heretic.get_knowledge(/datum/eldritch_knowledge/base_blade)
	blade.record_parry(user, target)
	TEST_ASSERT_EQUAL(user.getStaminaLoss(), 4, "Парирование восстанавливает двадцать выносливости.")

/// Улучшение звёзд сохраняет повреждения старых и усиливает вновь созданные.
/datum/unit_test/heretic_passives/stars/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	heretic.selected_path = PATH_COSMIC
	heretic.knowledge_points = 3
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_cosmic)
	heretic.gain_knowledge(/datum/eldritch_knowledge/cosmic_resonance)
	var/datum/eldritch_knowledge/base_cosmic/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/base_cosmic)
	TEST_ASSERT(knowledge.add_star(get_turf(user), user), "Звезда создана.")
	var/obj/structure/heretic_star/first = knowledge.stars[1]
	first.obj_integrity -= 20
	TEST_ASSERT(heretic.upgrade_passive(/datum/eldritch_knowledge/cosmic_resonance, user, 1), "Пассивка звёзд улучшена.")
	TEST_ASSERT_EQUAL(first.max_integrity, 85, "Предел старой звезды увеличен.")
	TEST_ASSERT_EQUAL(first.obj_integrity, 65, "Полученный урон сохраняется.")
	TEST_ASSERT(heretic.upgrade_passive(/datum/eldritch_knowledge/cosmic_resonance, user, 2), "Третий уровень звёзд приобретён.")
	user.forceMove(get_step(user, EAST))
	TEST_ASSERT(knowledge.add_star(get_turf(user), user), "Новая звезда создана после улучшения.")
	var/obj/structure/heretic_star/second = knowledge.stars[2]
	TEST_ASSERT_EQUAL(second.max_integrity, 100, "Новая звезда получает повышенную прочность.")
	TEST_ASSERT_EQUAL(second.obj_integrity, 100, "Новая звезда не повреждена.")

/// Продление жизни отражений применяется к новым копиям, не обновляя таймер существующих.
/datum/unit_test/heretic_passives/reflections/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	heretic.selected_path = PATH_MOON
	heretic.knowledge_points = 3
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_moon)
	heretic.gain_knowledge(/datum/eldritch_knowledge/moon_shroud)
	var/datum/eldritch_knowledge/base_moon/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/base_moon)
	var/mob/living/simple_animal/hostile/illusion/heretic_moon/first = knowledge.create_reflection(user, get_step(user, EAST))
	TEST_ASSERT(first, "Первое отражение создано.")
	var/first_expiry = first.reflection_expires_at
	TEST_ASSERT_EQUAL(first_expiry, world.time + 60 SECONDS, "Первый уровень даёт минуту жизни.")
	TEST_ASSERT(heretic.upgrade_passive(/datum/eldritch_knowledge/moon_shroud, user, 1), "Второй уровень покрова приобретён.")
	TEST_ASSERT(heretic.upgrade_passive(/datum/eldritch_knowledge/moon_shroud, user, 2), "Третий уровень покрова приобретён.")
	var/mob/living/simple_animal/hostile/illusion/heretic_moon/second = knowledge.create_reflection(user, get_step(user, NORTH))
	TEST_ASSERT(second, "Второе отражение создано.")
	TEST_ASSERT_EQUAL(second.reflection_expires_at, world.time + 90 SECONDS, "Третий уровень даёт полторы минуты жизни.")
	TEST_ASSERT_EQUAL(first.reflection_expires_at, first_expiry, "Срок старого отражения не продлевается.")
