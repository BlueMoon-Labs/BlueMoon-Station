/// Приказ ожидания сохраняет перехват и срок жизни, а новая погоня отменяет только собственную паузу.
/datum/unit_test/heretic_moon_mirror_orders/Run()
	var/mob/living/user = make_moon_heretic(run_loc_floor_bottom_left)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_moon/knowledge = get_heretic_moon(user)
	var/datum/eldritch_knowledge/moon_shroud/recipe = allocate(/datum/eldritch_knowledge/moon_shroud)
	heretic.researched_knowledge[recipe.type] = recipe
	TEST_ASSERT(recipe.on_finished_recipe(user, list(), get_turf(user)), "Создаётся зеркало для приказов.")
	var/obj/item/heretic_path_relic/silver_mirror/mirror = recipe.new_path_relic_ref.resolve()
	allocated += mirror
	user.put_in_hands(mirror)
	var/mob/living/simple_animal/hostile/illusion/heretic_moon/reflection = knowledge.create_reflection(user, get_step(user, EAST))
	TEST_ASSERT_NOTNULL(reflection, "Создаётся отражение для приказов.")
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, NORTHEAST))
	var/expiry_before = reflection.reflection_expires_at
	user.a_intent = INTENT_HELP
	mirror.afterattack(reflection, user, TRUE)
	TEST_ASSERT(reflection.holding_position, "Выбор на помощи оставляет копию ждать.")
	TEST_ASSERT(!reflection.ai_controller.able_to_run, "Ожидание останавливает контроллер движения.")
	knowledge.direct_reflections(victim)
	TEST_ASSERT_NULL(reflection.target, "Клинок не перезаписывает явный приказ ожидания.")
	TEST_ASSERT(!reflection.AttackingTarget(), "Ожидающая копия не атакует сама.")
	TEST_ASSERT(!mirror.pursue(user, user), "Приказ погони не принимает союзную цель.")
	TEST_ASSERT(reflection.holding_position, "Недопустимый приказ не отменяет ожидание.")
	var/mob/living/stranger = make_moon_heretic(get_step(user, NORTH))
	TEST_ASSERT(!mirror.pursue(stranger, victim), "Чужой разум не командует зеркалом.")
	ADD_TRAIT(reflection, TRAIT_AI_PAUSED, "moon-orders-test")
	TEST_ASSERT(mirror.pursue(user, victim), "Явная цель возвращает выбранную копию к погоне.")
	TEST_ASSERT(!reflection.holding_position, "Погоня отменяет ожидание.")
	TEST_ASSERT(HAS_TRAIT_FROM(reflection, TRAIT_AI_PAUSED, "moon-orders-test"), "Приказ сохраняет чужую причину паузы.")
	TEST_ASSERT(!reflection.ai_controller.able_to_run, "Оставшаяся чужая пауза сохраняет остановку контроллера.")
	TEST_ASSERT_EQUAL(reflection.ai_controller.blackboard[BB_AI_CURRENT_TARGET], victim, "Новая цель передана контроллеру.")
	REMOVE_TRAIT(reflection, TRAIT_AI_PAUSED, "moon-orders-test")
	TEST_ASSERT(reflection.ai_controller.able_to_run, "Снятие последней причины паузы возобновляет контроллер.")
	TEST_ASSERT_EQUAL(reflection.reflection_expires_at, expiry_before, "Приказы не продлевают жизнь копии.")
	reflection.hold_position(TRUE)
	TEST_ASSERT(knowledge.intercept_projectile(user, TRUE, null, 20, "снаряд", ATTACK_TYPE_PROJECTILE, 0, victim) & BLOCK_SUCCESS, "Ожидание сохраняет перехват соседней копией.")
	TEST_ASSERT(QDELETED(reflection), "Перехват по-прежнему уничтожает ожидающую копию.")
	TEST_ASSERT(!mirror.pursue(user, victim), "Разрушенной копией больше нельзя командовать.")

/// Утрата знания зеркала отпускает копии и сохраняет чужие причины остановки.
/datum/unit_test/heretic_moon_mirror_orders/cleanup/Run()
	var/mob/living/user = make_moon_heretic(run_loc_floor_bottom_left)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_moon/knowledge = get_heretic_moon(user)
	var/datum/eldritch_knowledge/moon_shroud/shroud = allocate(/datum/eldritch_knowledge/moon_shroud)
	heretic.researched_knowledge[shroud.type] = shroud
	shroud.on_body_gain(user)
	var/mob/living/simple_animal/hostile/illusion/heretic_moon/first = knowledge.create_reflection(user, get_step(user, EAST))
	var/mob/living/simple_animal/hostile/illusion/heretic_moon/second = knowledge.create_reflection(user, get_step(user, NORTH))
	TEST_ASSERT(first && second, "Создаются две копии для проверки очистки.")
	first.hold_position(TRUE)
	second.hold_position(TRUE)
	shroud.on_body_lose(user)
	TEST_ASSERT(!first.holding_position && !second.holding_position, "Потеря тела знанием зеркала отменяет его приказы ожидания.")
	shroud.on_body_gain(user)
	first.hold_position(TRUE)
	second.hold_position(TRUE)
	ADD_TRAIT(first, TRAIT_AI_PAUSED, "moon-shroud-cleanup-test")
	var/first_expiry = first.reflection_expires_at
	var/second_expiry = second.reflection_expires_at
	user.apply_status_effect(/datum/status_effect/heretic_moon_shroud, 5 SECONDS)
	TEST_ASSERT(user.has_status_effect(/datum/status_effect/heretic_moon_shroud), "Перед удалением знания действует покров.")
	user.mind.antag_datums -= heretic
	qdel(shroud)
	TEST_ASSERT(!first.holding_position && !second.holding_position, "Destroy отпускает копии после отсоединения роли от mind.")
	TEST_ASSERT(HAS_TRAIT_FROM(first, TRAIT_AI_PAUSED, "moon-shroud-cleanup-test"), "Чужая причина остановки первой копии остаётся.")
	TEST_ASSERT(!HAS_TRAIT_FROM(first, TRAIT_AI_PAUSED, REF(first)), "Приказ зеркала больше не удерживает первую копию.")
	TEST_ASSERT(!HAS_TRAIT(second, TRAIT_AI_PAUSED) && second.ai_controller.able_to_run, "Вторая копия снова может двигаться.")
	TEST_ASSERT(!knowledge.shrouded && !user.has_status_effect(/datum/status_effect/heretic_moon_shroud), "Удаление знания снимает и покров прежнего тела.")
	TEST_ASSERT_EQUAL(length(knowledge.reflections), 2, "Очистка режима не разрушает отражения.")
	TEST_ASSERT_EQUAL(first.reflection_expires_at, first_expiry, "Срок первой копии не меняется.")
	TEST_ASSERT_EQUAL(second.reflection_expires_at, second_expiry, "Срок второй копии не меняется.")
	user.mind.antag_datums += heretic
	REMOVE_TRAIT(first, TRAIT_AI_PAUSED, "moon-shroud-cleanup-test")

/// Фикстура регистрирует только владельца знаний: разломы, цели охоты и экипировка здесь не нужны.
/datum/unit_test/proc/make_moon_heretic(turf/location)
	var/mob/living/carbon/human/body = allocate(/mob/living/carbon/human, location)
	body.mind_initialize()
	var/datum/antagonist/heretic/heretic = allocate(/datum/antagonist/heretic)
	heretic.owner = body.mind
	heretic.role_removed = TRUE
	heretic.silent = TRUE
	LAZYADD(body.mind.antag_datums, heretic)
	var/datum/eldritch_knowledge/base_moon/knowledge = allocate(/datum/eldritch_knowledge/base_moon)
	heretic.researched_knowledge[knowledge.type] = knowledge
	knowledge.on_body_gain(body)
	return body

/datum/unit_test/heretic_moon_limits/Run()
	var/mob/living/user = make_moon_heretic(run_loc_floor_bottom_left)
	var/datum/eldritch_knowledge/base_moon/knowledge = get_heretic_moon(user)
	var/turf/first_turf = get_step(user, EAST)
	var/turf/second_turf = get_step(user, NORTH)
	var/turf/third_turf = get_step(user, NORTHEAST)
	var/mob/living/simple_animal/hostile/illusion/heretic_moon/first = knowledge.create_reflection(user, first_turf)
	var/mob/living/simple_animal/hostile/illusion/heretic_moon/second = knowledge.create_reflection(user, second_turf)
	TEST_ASSERT(first && second, "Два отражения должны создаваться на свободном полу.")
	TEST_ASSERT_NULL(knowledge.create_reflection(user, third_turf), "Начальный предел не должен разрешать третье отражение.")
	TEST_ASSERT_EQUAL(length(knowledge.reflections), 2, "Отказ создания не должен менять список отражений.")
	first.adjustBruteLoss(first.maxHealth)
	TEST_ASSERT(QDELETED(first), "Отражение должно разрушаться обычным уроном.")
	TEST_ASSERT_EQUAL(length(knowledge.reflections), 1, "Разбитое отражение должно освобождать место в списке.")
	knowledge.upgraded = TRUE
	TEST_ASSERT_EQUAL(knowledge.reflection_limit(), 3, "Улучшение должно давать три отражения.")
	knowledge.ascension_active = TRUE
	TEST_ASSERT_EQUAL(knowledge.reflection_limit(), 5, "Вознесение должно давать пять отражений.")
	knowledge.clear_reflections()
	TEST_ASSERT(QDELETED(second), "Очистка должна удалять оставшиеся отражения.")
	TEST_ASSERT_EQUAL(length(knowledge.reflections), 0, "После очистки список должен быть пуст.")

/// Отражение показывает худы оригинала, а не свои.
/datum/unit_test/heretic_moon_hud_mirror/Run()
	var/mob/living/carbon/human/user = make_moon_heretic(run_loc_floor_bottom_left)
	var/datum/eldritch_knowledge/base_moon/knowledge = get_heretic_moon(user)
	user.sec_hud_set_ID()
	user.adjustBruteLoss(40)
	var/mob/living/simple_animal/hostile/illusion/heretic_moon/reflection = knowledge.create_reflection(user, get_step(user, EAST))
	TEST_ASSERT_NOTNULL(reflection, "Отражение должно создаваться на свободном полу.")
	var/datum/atom_hud/security_hud = GLOB.huds[DATA_HUD_SECURITY_ADVANCED]
	TEST_ASSERT(reflection in security_hud.hudatoms, "Отражение должно быть видно в худе охраны.")
	var/image/user_id = user.hud_list[ID_HUD]
	var/image/reflection_id = reflection.hud_list[ID_HUD]
	TEST_ASSERT_EQUAL(user_id.icon_state, "hudno_id", "Оригинал без карты должен иметь значок отсутствия ID.")
	TEST_ASSERT_EQUAL(reflection_id.icon_state, user_id.icon_state, "Значок ID отражения должен совпадать с оригиналом.")
	var/image/user_health = user.hud_list[HEALTH_HUD]
	var/image/reflection_health = reflection.hud_list[HEALTH_HUD]
	TEST_ASSERT_NOTEQUAL(user_health.icon_state, "hud", "Раненый оригинал должен иметь неполную полоску здоровья.")
	TEST_ASSERT_EQUAL(reflection_health.icon_state, user_health.icon_state, "Полоска здоровья отражения должна совпадать с оригиналом.")
	reflection.adjustBruteLoss(5)
	TEST_ASSERT_EQUAL(reflection_health.icon_state, user_health.icon_state, "Урон по отражению не должен менять его полоску здоровья.")

/datum/unit_test/heretic_moon_exchange/Run()
	var/mob/living/user = make_moon_heretic(run_loc_floor_bottom_left)
	var/datum/eldritch_knowledge/base_moon/knowledge = get_heretic_moon(user)
	var/turf/origin = get_turf(user)
	var/turf/destination = get_step(user, EAST)
	var/mob/living/simple_animal/hostile/illusion/heretic_moon/reflection = knowledge.create_reflection(user, destination)
	TEST_ASSERT_NOTNULL(reflection, "Отражение для обмена не создано.")
	var/obj/structure/blocker = allocate(/obj/structure, destination)
	blocker.density = TRUE
	TEST_ASSERT(!knowledge.exchange(user, reflection), "Плотное препятствие должно блокировать обмен.")
	TEST_ASSERT_EQUAL(get_turf(user), origin, "Неудачный обмен не должен перемещать игрока.")
	blocker.forceMove(null)
	qdel(blocker)
	var/obj/container = allocate(/obj, destination)
	reflection.forceMove(container)
	TEST_ASSERT(!knowledge.exchange(user, reflection), "Нельзя обмениваться с двойником внутри контейнера.")
	reflection.forceMove(destination)
	ADD_TRAIT(user, TRAIT_NO_TELEPORT, "moon-test")
	TEST_ASSERT(!knowledge.exchange(user, reflection), "Запрет телепортации должен блокировать обмен.")
	REMOVE_TRAIT(user, TRAIT_NO_TELEPORT, "moon-test")
	TEST_ASSERT(knowledge.exchange(user, reflection), "Свободные соседние клетки должны разрешать обмен.")
	TEST_ASSERT_EQUAL(get_turf(user), destination, "Игрок должен оказаться на месте отражения.")
	TEST_ASSERT_EQUAL(get_turf(reflection), origin, "Отражение должно занять прежнее место игрока.")
	var/mob/living/other_user = make_moon_heretic(get_step(destination, NORTH))
	TEST_ASSERT(!knowledge.exchange(other_user, reflection), "Другой игрок не должен использовать чужое отражение.")
	var/datum/eldritch_knowledge/base_moon/other_knowledge = get_heretic_moon(other_user)
	TEST_ASSERT(!other_knowledge.exchange(other_user, reflection), "Чужое отражение не должно приниматься другим знанием Луны.")

/datum/unit_test/heretic_moon_cleanup/Run()
	var/mob/living/user = make_moon_heretic(run_loc_floor_bottom_left)
	var/datum/eldritch_knowledge/base_moon/knowledge = get_heretic_moon(user)
	var/mob/living/simple_animal/hostile/illusion/heretic_moon/reflection = knowledge.create_reflection(user, get_step(user, EAST))
	var/obj/effect/proc_holder/spell/pointed/heretic_moon/create/granted = knowledge.reflection_spell
	var/obj/effect/proc_holder/spell/pointed/heretic_moon/create/unrelated = allocate(/obj/effect/proc_holder/spell/pointed/heretic_moon/create)
	user.mind.AddSpell(unrelated)
	user.alpha = 150
	user.add_filter("moon-test-independent", 1, list("type" = "outline", "size" = 1, "color" = "#ffffff"))
	var/datum/status_effect/heretic_moon_shroud/shroud = user.apply_status_effect(/datum/status_effect/heretic_moon_shroud)
	TEST_ASSERT_NOTNULL(shroud, "Лунный покров должен применяться.")
	TEST_ASSERT_NOTNULL(user.get_filter(shroud.filter_name), "Покров должен создавать собственный фильтр.")
	var/old_filter_name = shroud.filter_name
	shroud = user.apply_status_effect(/datum/status_effect/heretic_moon_shroud, 1 SECONDS)
	TEST_ASSERT_NULL(user.get_filter(old_filter_name), "Повторное применение покрова должно убирать фильтр предыдущего экземпляра.")
	TEST_ASSERT_NOTNULL(user.get_filter(shroud.filter_name), "Новый экземпляр покрова должен иметь свой фильтр.")
	knowledge.on_body_lose(user)
	TEST_ASSERT(QDELETED(reflection), "При смене тела отражения старого тела должны исчезать.")
	TEST_ASSERT(QDELETED(granted), "Выданное знанием заклинание должно удаляться.")
	TEST_ASSERT(!QDELETED(unrelated), "Другое заклинание того же типа должно сохраняться.")
	TEST_ASSERT_EQUAL(user.alpha, 150, "Снятие покрова не должно переписывать исходную прозрачность.")
	TEST_ASSERT_NOTNULL(user.get_filter("moon-test-independent"), "Снятие покрова не должно удалять чужой фильтр.")
	TEST_ASSERT(!user.has_status_effect(/datum/status_effect/heretic_moon_shroud), "Снятие знаний должно убирать лунный покров.")
	TEST_ASSERT_NULL(knowledge.moon_body, "Ссылка на прежнее тело должна очищаться.")

/datum/unit_test/heretic_moon_expiry/Run()
	var/mob/living/user = make_moon_heretic(run_loc_floor_bottom_left)
	var/datum/eldritch_knowledge/base_moon/knowledge = get_heretic_moon(user)
	var/mob/living/simple_animal/hostile/illusion/heretic_moon/reflection = allocate(/mob/living/simple_animal/hostile/illusion/heretic_moon, get_step(user, EAST), knowledge, user, 1)
	knowledge.reflections += reflection
	TEST_ASSERT(wait_for_qdeleted(reflection), "Отражение должно исчезать по истечении своего времени жизни.")
	TEST_ASSERT_EQUAL(length(knowledge.reflections), 0, "Истёкшее отражение должно освобождать место для нового.")

/// Копии вознесённого носят его нимб и поворачивают его сами, покров приглушает нимб подлинника.
/datum/unit_test/heretic_moon_ascension_aura/Run()
	var/mob/living/user = make_moon_heretic(run_loc_floor_bottom_left)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_moon/knowledge = get_heretic_moon(user)
	var/mob/living/simple_animal/hostile/illusion/heretic_moon/early = knowledge.create_reflection(user, get_step(user, EAST))
	TEST_ASSERT_NOTNULL(early, "Создаётся копия до вознесения.")
	TEST_ASSERT_NULL(early.aura_back, "До вознесения у копии нет нимба.")
	var/datum/eldritch_knowledge/final_eldritch/moon_final/final_knowledge = allocate(/datum/eldritch_knowledge/final_eldritch/moon_final)
	heretic.researched_knowledge[final_knowledge.type] = final_knowledge
	final_knowledge.finished = TRUE
	final_knowledge.on_body_gain(user)
	TEST_ASSERT((early.aura_back in early.vis_contents) && (early.aura_front in early.vis_contents), "Вознесение сразу проявляет нимб на живой копии.")
	var/mob/living/simple_animal/hostile/illusion/heretic_moon/late = knowledge.create_reflection(user, get_step(user, NORTH))
	TEST_ASSERT_NOTNULL(late?.aura_back, "Новая копия появляется с нимбом.")
	TEST_ASSERT_EQUAL(late.aura_back.icon_state, final_knowledge.ascension_aura.icon_state, "Задний слой копии совпадает с нимбом подлинника.")
	TEST_ASSERT_EQUAL(late.aura_front.icon_state, final_knowledge.ascension_aura_front.icon_state, "Передний слой копии совпадает с нимбом подлинника.")
	TEST_ASSERT_EQUAL(length(late.aura_back.overlays), length(final_knowledge.ascension_aura.overlays), "Копия светится в темноте так же, как подлинник.")
	late.sync_appearance()
	var/aura_layers = 0
	for(var/obj/effect/heretic_ascension_aura/aura in late.vis_contents)
		aura_layers++
	TEST_ASSERT_EQUAL(aura_layers, 2, "Повторная сверка не заводит второй нимб.")
	late.setDir(EAST)
	user.setDir(WEST)
	TEST_ASSERT(late.aura_back.mirrored != final_knowledge.ascension_aura.mirrored, "Нимб копии поворачивается вместе с копией, а не с подлинником.")
	user.apply_status_effect(/datum/status_effect/heretic_moon_shroud, 5 SECONDS)
	TEST_ASSERT(final_knowledge.ascension_aura.alpha < 255 && final_knowledge.ascension_aura_front.alpha < 255, "Покров приглушает нимб подлинника вместе с телом.")
	TEST_ASSERT_EQUAL(late.aura_back.alpha, 255, "Нимб копии покров не трогает.")
	user.remove_status_effect(/datum/status_effect/heretic_moon_shroud)
	TEST_ASSERT_EQUAL(final_knowledge.ascension_aura.alpha, 255, "Снятие покрова возвращает нимб.")
	var/obj/effect/heretic_ascension_aura/copied = late.aura_back
	final_knowledge.on_body_lose(user)
	TEST_ASSERT(QDELETED(copied) && !late.aura_back && !early.aura_back, "Потеря вознесения снимает нимб с копий.")
	TEST_ASSERT(!(copied in late.vis_contents), "Копия освобождает старый нимб.")
	final_knowledge.on_body_gain(user)
	copied = early.aura_back
	TEST_ASSERT_NOTNULL(copied, "Повторное вознесение возвращает нимб копиям.")
	qdel(early)
	TEST_ASSERT(QDELETED(copied), "Разбитая копия уносит свой нимб.")

/datum/unit_test/heretic_moon_reveal/Run()
	var/mob/living/user = make_moon_heretic(run_loc_floor_bottom_left)
	var/mob/living/other = allocate(/mob/living/carbon/human, get_step(user, EAST))
	var/datum/status_effect/heretic_moon_shroud/shroud = user.apply_status_effect(/datum/status_effect/heretic_moon_shroud)
	var/filter_name = shroud.filter_name
	user.attack_hand(other, INTENT_HELP)
	TEST_ASSERT(user.has_status_effect(/datum/status_effect/heretic_moon_shroud), "Чужое дружеское касание не должно считаться атакой владельца покрова.")
	user.UnarmedAttack(other, TRUE, INTENT_HARM)
	TEST_ASSERT(!user.has_status_effect(/datum/status_effect/heretic_moon_shroud), "Исходящий удар без оружия должен раскрывать владельца покрова.")
	TEST_ASSERT_NULL(user.get_filter(filter_name), "Раскрытие атакой должно удалять фильтр прозрачности.")

/datum/unit_test/heretic_moon_allies/Run()
	var/mob/living/user = make_moon_heretic(run_loc_floor_bottom_left)
	var/mob/living/ally = make_moon_heretic(get_step(user, NORTH))
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	var/datum/eldritch_knowledge/moon_mark/mark = allocate(/datum/eldritch_knowledge/moon_mark)
	TEST_ASSERT(!mark.on_mansus_grasp(ally, user, TRUE), "Метка Луны не должна действовать на другого еретика.")
	TEST_ASSERT(mark.on_mansus_grasp(victim, user, TRUE), "Метка Луны должна действовать на обычного противника.")
	var/datum/status_effect/eldritch/moon/effect = victim.has_status_effect(/datum/status_effect/eldritch/moon)
	TEST_ASSERT_NOTNULL(effect, "Хватка должна оставить лунную метку.")
	effect.on_effect()
	TEST_ASSERT(victim.confused > 0, "Активация метки должна дезориентировать жертву.")
	TEST_ASSERT_EQUAL(victim.getStaminaLoss(), 20, "Активация метки должна наносить урон выносливости.")
	TEST_ASSERT(victim.has_status_effect(/datum/status_effect/heretic_moon_opening), "Метка должна замедлять цель для атаки двойников.")
	TEST_ASSERT(!victim.has_status_effect(/datum/status_effect/eldritch/moon), "Активированная метка должна расходоваться.")

/// Лунный клинок наносит обычный урон и разбивает отражение вторым попаданием.
/datum/unit_test/heretic_moon_blade_damage/Run()
	var/mob/living/user = make_moon_heretic(run_loc_floor_bottom_left)
	var/datum/eldritch_knowledge/base_moon/knowledge = get_heretic_moon(user)
	var/obj/item/melee/sickly_blade/moon/blade = allocate(/obj/item/melee/sickly_blade/moon)
	user.put_in_hands(blade)
	user.a_intent = INTENT_HARM
	var/mob/living/simple_animal/hostile/illusion/heretic_moon/reflection = knowledge.create_reflection(user, get_step(user, EAST))
	TEST_ASSERT_NOTNULL(reflection, "Отражение для проверки удара должно создаться.")
	blade.attack(reflection, user)
	TEST_ASSERT(!QDELETED(reflection) && reflection.health < reflection.maxHealth, "Первое попадание ранит, но не разбивает отражение.")
	blade.attack(reflection, user)
	TEST_ASSERT(QDELETED(reflection), "Второе попадание лунным клинком разбивает отражение.")
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	blade.attack(victim, user)
	TEST_ASSERT(victim.getBruteLoss() > 0, "Лунный путь сохраняет обычный урон своего клинка.")

/// Ручное зеркало перемещает именно копию, сохраняя общий лимит и уязвимость к разрушению.
/datum/unit_test/heretic_moon_hand_mirror/Run()
	var/mob/living/user = make_moon_heretic(run_loc_floor_bottom_left)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_moon/knowledge = get_heretic_moon(user)
	var/datum/eldritch_knowledge/moon_shroud/recipe = allocate(/datum/eldritch_knowledge/moon_shroud)
	heretic.researched_knowledge[recipe.type] = recipe
	TEST_ASSERT(recipe.on_finished_recipe(user, list(), get_turf(user)), "Ритуал должен создать серебряное зеркало.")
	var/obj/item/heretic_path_relic/silver_mirror/mirror = recipe.new_path_relic_ref.resolve()
	allocated += mirror
	user.put_in_hands(mirror)
	mirror.focusing_time = 0
	var/turf/origin = get_turf(user)
	var/turf/destination = get_step(origin, NORTH)
	var/mob/living/simple_animal/hostile/illusion/heretic_moon/reflection = knowledge.create_reflection(user, get_step(origin, EAST))
	var/original_expiry = reflection.reflection_expires_at
	mirror.selected_reflection = WEAKREF(reflection)
	var/obj/container = allocate(/obj, get_turf(reflection))
	reflection.forceMove(container)
	TEST_ASSERT(!mirror.redirect(user, destination), "Зеркало не должно вытаскивать двойника из контейнера.")
	reflection.forceMove(get_turf(container))
	var/obj/barrier = allocate(/obj, destination)
	barrier.density = TRUE
	TEST_ASSERT(!mirror.redirect(user, destination), "Зеркало не переносит отражение в плотное препятствие.")
	qdel(barrier)
	TEST_ASSERT(mirror.redirect(user, destination), "Свободная видимая клетка позволяет переставить копию.")
	TEST_ASSERT_EQUAL(get_turf(user), origin, "Ручное зеркало не телепортирует самого владельца.")
	TEST_ASSERT_EQUAL(get_turf(reflection), destination, "Существующая копия занимает выбранную клетку.")
	TEST_ASSERT_EQUAL(reflection.reflection_expires_at, original_expiry, "Перестановка не продлевает жизнь отражения.")
	TEST_ASSERT(reflection.holding_position, "Переставленная копия ожидает на выбранной клетке.")
	TEST_ASSERT(!reflection.ai_controller.able_to_run, "Копия не уходит с подготовленного места обмена сама.")
	TEST_ASSERT_EQUAL(length(knowledge.reflections), 1, "Перестановка не размножает отражения.")
	TEST_ASSERT(!mirror.redirect(user, get_step(origin, EAST)), "Сразу после перестановки действует перезарядка.")
	mirror.relic_cooldown = 0
	qdel(reflection)
	TEST_ASSERT(!mirror.redirect(user, get_step(origin, EAST)), "Разрушенное отражение нельзя восстановить перестановкой.")
	qdel(recipe)
	TEST_ASSERT(!mirror.authorized(user), "Потеря знания делает уже созданное зеркало неактивным.")

/// Двойник сохраняет облик и экипировку владельца, но не копирует лунный покров.
/datum/unit_test/heretic_moon_appearance/Run()
	var/mob/living/carbon/human/user = make_moon_heretic(run_loc_floor_bottom_left)
	var/datum/eldritch_knowledge/base_moon/knowledge = get_heretic_moon(user)
	user.alpha = 210
	user.transform = matrix(1.2, 0, 0, 0, 1.2, 0)
	user.add_filter("moon-test-outline", 1, outline_filter(1, "#ff0000"))
	var/obj/item/clothing/head/helmet/helmet = allocate(/obj/item/clothing/head/helmet)
	user.equip_to_slot_if_possible(helmet, ITEM_SLOT_HEAD)
	var/mob/living/simple_animal/hostile/illusion/heretic_moon/reflection = knowledge.create_reflection(user, get_step(user, EAST))
	TEST_ASSERT_NOTNULL(reflection, "Двойник должен создаться.")
	TEST_ASSERT_EQUAL(reflection.name, user.name, "Имя не должно выдавать копию.")
	TEST_ASSERT_EQUAL(reflection.icon, user.icon, "Базовая иконка должна совпадать.")
	TEST_ASSERT_EQUAL(reflection.alpha, user.alpha, "Двойник не должен получать собственную прозрачность.")
	TEST_ASSERT_EQUAL(reflection.transform.a, user.transform.a, "Масштаб персонажа должен сохраняться.")
	TEST_ASSERT_EQUAL(length(reflection.overlays), length(user.overlays), "Все слои экипировки должны копироваться без лунных колец.")
	TEST_ASSERT_EQUAL(length(reflection.filters), length(user.filters), "Двойник не должен получать дополнительную обводку.")
	TEST_ASSERT_EQUAL(jointext(reflection.examine(user), "\n"), jointext(user.examine(user), "\n"), "Осмотр должен показывать тот же облик, а не описание подделки.")
	user.dropItemToGround(helmet)
	user.apply_status_effect(/datum/status_effect/heretic_moon_shroud)
	reflection.sync_appearance()
	TEST_ASSERT_EQUAL(length(reflection.overlays), length(user.overlays), "Изменение экипировки должно обновлять двойника.")
	TEST_ASSERT_EQUAL(length(reflection.filters), 1, "Копия сохраняет исходный фильтр без лунного покрова.")
	TEST_ASSERT_EQUAL(length(user.filters), 2, "Синхронизация копии не должна изменять фильтры владельца.")

/// Двойники делят интервал физического урона и выносливости, учитывая броню и союзников.
/datum/unit_test/heretic_moon_pressure/Run()
	var/mob/living/user = make_moon_heretic(run_loc_floor_bottom_left)
	var/datum/eldritch_knowledge/base_moon/knowledge = get_heretic_moon(user)
	var/mob/living/simple_animal/hostile/illusion/heretic_moon/first = knowledge.create_reflection(user, get_step(user, EAST))
	var/mob/living/simple_animal/hostile/illusion/heretic_moon/second = knowledge.create_reflection(user, get_step(user, NORTH))
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, NORTHEAST))
	knowledge.direct_reflections(victim)
	TEST_ASSERT_NOTNULL(first.ai_controller, "У двойника должен быть контроллер движения и атак.")
	TEST_ASSERT_EQUAL(first.ai_controller.blackboard[BB_AI_CURRENT_TARGET], victim, "Команда должна передавать цель контроллеру.")
	TEST_ASSERT(first.AttackingTarget(), "Соседняя цель должна принимать удар копии.")
	TEST_ASSERT_EQUAL(victim.getBruteLoss(), 5, "Начальное отражение наносит 5 физического урона.")
	TEST_ASSERT_EQUAL(victim.getStaminaLoss(), 18, "Начальное отражение наносит 18 урона выносливости.")
	second.AttackingTarget()
	TEST_ASSERT_EQUAL(victim.getBruteLoss(), 5, "Вторая копия не должна складывать физический урон в общем интервале.")
	TEST_ASSERT_EQUAL(victim.getStaminaLoss(), 18, "Вторая копия не должна обходить общий интервал.")
	victim.remove_status_effect(/datum/status_effect/heretic_moon_pressure)
	knowledge.upgraded = TRUE
	second.AttackingTarget()
	TEST_ASSERT_EQUAL(victim.getBruteLoss(), 13, "Улучшение увеличивает физический урон до 8.")
	TEST_ASSERT_EQUAL(victim.getStaminaLoss(), 42, "Улучшение увеличивает ложный удар до 24.")
	victim.remove_status_effect(/datum/status_effect/heretic_moon_pressure)
	knowledge.ascension_active = TRUE
	first.AttackingTarget()
	TEST_ASSERT_EQUAL(victim.getBruteLoss(), 23, "Вознесение увеличивает физический урон до 10.")
	TEST_ASSERT_EQUAL(victim.getStaminaLoss(), 72, "Вознесение увеличивает ложный удар до 30.")
	var/obj/item/clothing/suit/armor/vest/armor = allocate(/obj/item/clothing/suit/armor/vest)
	armor.armor = armor.armor.setRating(melee = 100)
	TEST_ASSERT(victim.equip_to_slot_if_possible(armor, ITEM_SLOT_OCLOTHING), "Жертва надевает бронежилет.")
	TEST_ASSERT_EQUAL(victim.run_armor_check(victim.get_bodypart(BODY_ZONE_CHEST), MELEE, silent = TRUE), 100, "Бронежилет даёт полную защиту груди.")
	victim.remove_status_effect(/datum/status_effect/heretic_moon_pressure)
	first.AttackingTarget()
	TEST_ASSERT_EQUAL(victim.getBruteLoss(), 23, "Полная защита от ближнего боя поглощает физический урон копии.")
	TEST_ASSERT_EQUAL(victim.getStaminaLoss(), 102, "Броня не меняет прежний урон выносливости.")
	TEST_ASSERT(!first.CanAttack(user), "Двойник не должен атаковать владельца.")
	TEST_ASSERT(!first.CanAttack(second), "Двойники не должны атаковать друг друга.")
	var/mob/living/ally = make_moon_heretic(get_step(victim, NORTH))
	TEST_ASSERT(!first.CanAttack(ally), "Другой еретик должен оставаться союзником.")
	var/obj/structure/closet/closet = allocate(/obj/structure/closet, get_turf(victim))
	victim.forceMove(closet)
	TEST_ASSERT(!first.AttackingTarget(), "Ложный удар не должен доставать цель внутри шкафа.")

/// Копии повторяют произнесённую речь с голосом, языком и дальностью владельца.
/datum/unit_test/heretic_moon_speech
	var/list/speeches = list()
	var/speech_count = 0

/datum/unit_test/heretic_moon_speech/Run()
	var/mob/living/carbon/human/user = make_moon_heretic(run_loc_floor_bottom_left)
	var/datum/eldritch_knowledge/base_moon/knowledge = get_heretic_moon(user)
	var/mob/living/simple_animal/hostile/illusion/heretic_moon/first = knowledge.create_reflection(user, get_step(user, EAST))
	var/mob/living/simple_animal/hostile/illusion/heretic_moon/second = knowledge.create_reflection(user, get_step(user, NORTH))
	TEST_ASSERT(first && second, "Создаются две копии для передачи речи.")
	RegisterSignal(first, COMSIG_LIVING_SEND_SPEECH, PROC_REF(record_speech))
	RegisterSignal(second, COMSIG_LIVING_SEND_SPEECH, PROC_REF(record_speech))
	user.SetSpecialVoice("Чужое имя")
	user.say("Проверка отражения.", language = /datum/language/common, ignore_spam = TRUE)
	TEST_ASSERT_EQUAL(speech_count, 2, "Одна фраза повторяется каждой копией ровно один раз.")
	var/list/spoken = speeches[first]
	TEST_ASSERT_EQUAL(spoken["message"], user.last_words, "Копия повторяет обработанный текст владельца.")
	TEST_ASSERT_EQUAL(spoken["source"], first, "Речь исходит от копии, а не от владельца.")
	TEST_ASSERT_EQUAL(spoken["language"], /datum/language/common, "Язык сообщения сохраняется.")
	TEST_ASSERT_EQUAL(first.GetVoice(), user.GetVoice(), "Изменённый голос не выдаёт оригинал.")
	TEST_ASSERT_EQUAL(first.get_alt_name(), user.get_alt_name(), "Подпись замаскированного имени совпадает.")
	TEST_ASSERT_EQUAL(first.say_mod("Проверка?", null), user.say_mod("Проверка?", null), "Манера речи копии совпадает с владельцем.")
	user.whisper("Тихая проверка.", language = /datum/language/common, ignore_spam = TRUE)
	TEST_ASSERT_EQUAL(speech_count, 4, "Шёпот также повторяется обеими копиями.")
	spoken = speeches[second]
	TEST_ASSERT_EQUAL(spoken["mode"], MODE_WHISPER, "Копия сохраняет режим шёпота.")
	TEST_ASSERT_EQUAL(spoken["range"], 1, "Шёпот копии не становится обычной речью.")
	TEST_ASSERT(SPAN_WHISPER in spoken["spans"], "Стиль шёпота сохраняется.")
	ADD_TRAIT(user, TRAIT_MUTE, "moon-speech-test")
	user.say("Несказанная фраза.", language = /datum/language/common, ignore_spam = TRUE)
	TEST_ASSERT_EQUAL(speech_count, 4, "Немота владельца не позволяет говорить через копии.")
	user.say("Привет!", language = /datum/language/signlanguage, ignore_spam = TRUE)
	TEST_ASSERT_EQUAL(speech_count, 6, "Жестовый язык передаётся и при немоте.")
	spoken = speeches[first]
	TEST_ASSERT_EQUAL(spoken["language"], /datum/language/signlanguage, "Жесты не превращаются в звуковую речь.")
	REMOVE_TRAIT(user, TRAIT_MUTE, "moon-speech-test")
	user.say(":p Проверка канала.", ignore_spam = TRUE)
	TEST_ASSERT_EQUAL(speech_count, 6, "Сообщение служебного канала не произносится копиями.")
	qdel(first)
	user.say("Осталось одно отражение.", language = /datum/language/common, ignore_spam = TRUE)
	TEST_ASSERT_EQUAL(speech_count, 7, "Удалённая копия больше не повторяет речь.")
	knowledge.on_body_lose(user)
	user.say("Отражений больше нет.", language = /datum/language/common, ignore_spam = TRUE)
	TEST_ASSERT_EQUAL(speech_count, 7, "Потеря тела прекращает передачу речи.")
	TEST_ASSERT(QDELETED(second), "Потеря тела удаляет оставшуюся копию.")

/datum/unit_test/heretic_moon_speech/proc/record_speech(mob/living/source, message, message_range, atom/movable/speech_source, bubble_type, list/spans, datum/language/message_language, message_mode)
	SIGNAL_HANDLER
	speech_count++
	speeches[source] = list("message" = message, "source" = speech_source, "range" = message_range, "language" = message_language, "mode" = message_mode, "spans" = spans?.Copy())

/datum/unit_test/heretic_moon_speech/Destroy()
	speeches = null
	return ..()

/// Шествие заменяет полный набор отражений и оставляет двойника на прежнем месте владельца.
/datum/unit_test/heretic_moon_mirage/Run()
	var/mob/living/user = make_moon_heretic(run_loc_floor_bottom_left)
	var/datum/eldritch_knowledge/base_moon/knowledge = get_heretic_moon(user)
	knowledge.upgraded = TRUE
	var/mob/living/simple_animal/hostile/illusion/heretic_moon/old = knowledge.create_reflection(user, get_step(user, EAST))
	knowledge.create_reflection(user, get_step(user, NORTH))
	knowledge.create_reflection(user, get_step(user, NORTHEAST))
	var/turf/origin = get_turf(user)
	TEST_ASSERT(knowledge.create_mirages(user), "Шествие должно работать при полном наборе отражений.")
	TEST_ASSERT(QDELETED(old), "Старые отражения должны заменяться.")
	TEST_ASSERT_EQUAL(length(knowledge.reflections), 3, "Шествие должно использовать улучшенный предел.")
	TEST_ASSERT_NOTEQUAL(get_turf(user), origin, "Шествие должно менять позицию владельца.")
	TEST_ASSERT(locate(/mob/living/simple_animal/hostile/illusion/heretic_moon) in origin, "На прежнем месте должна оставаться копия.")
	ADD_TRAIT(user, TRAIT_NO_TELEPORT, "moon-test")
	origin = get_turf(user)
	TEST_ASSERT(knowledge.create_mirages(user), "Запрет телепортации не должен запрещать создание двойников.")
	TEST_ASSERT_EQUAL(get_turf(user), origin, "Шествие должно соблюдать запрет телепортации.")
	REMOVE_TRAIT(user, TRAIT_NO_TELEPORT, "moon-test")

/// Вспышка разбитой копии бьёт врагов в двух клетках, но не срабатывает при обычной очистке.
/datum/unit_test/heretic_moon_refraction/Run()
	var/mob/living/user = make_moon_heretic(run_loc_floor_bottom_left)
	var/datum/eldritch_knowledge/base_moon/knowledge = get_heretic_moon(user)
	knowledge.refracting = TRUE
	var/mob/living/simple_animal/hostile/illusion/heretic_moon/reflection = knowledge.create_reflection(user, get_step(user, EAST))
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, NORTHEAST))
	var/mob/living/distant = allocate(/mob/living/carbon/human, locate(user.x + 3, user.y, user.z))
	var/mob/living/outside = allocate(/mob/living/carbon/human, locate(user.x + 4, user.y + 1, user.z))
	for(var/mob/living/target as anything in list(victim, distant, outside))
		target.apply_status_effect(/datum/status_effect/heretic_moon_pressure)
	reflection.adjustBruteLoss(reflection.maxHealth)
	TEST_ASSERT(QDELETED(reflection), "Урон должен разбивать копию.")
	TEST_ASSERT_EQUAL(victim.getStaminaLoss(), 25, "Разбитая копия должна изматывать ближайшего врага.")
	TEST_ASSERT_EQUAL(distant.getStaminaLoss(), 25, "Вспышка достаёт врага в двух клетках от копии.")
	TEST_ASSERT_EQUAL(outside.getStaminaLoss(), 0, "Враг в трёх клетках от копии остаётся вне вспышки.")
	TEST_ASSERT_EQUAL(user.getStaminaLoss(), 0, "Вспышка не должна изматывать владельца.")
	victim.remove_status_effect(/datum/status_effect/heretic_moon_pressure)
	knowledge.create_reflection(user, get_step(user, EAST))
	knowledge.clear_reflections()
	TEST_ASSERT_EQUAL(victim.getStaminaLoss(), 25, "Очистка не должна наносить урон вспышкой.")

/// Затмение действует вокруг двойников и оставляет видимую копию под покровом владельца.
/datum/unit_test/heretic_moon_eclipse/Run()
	var/mob/living/user = make_moon_heretic(run_loc_floor_bottom_left)
	var/datum/eldritch_knowledge/base_moon/knowledge = get_heretic_moon(user)
	var/turf/far_turf = get_step(get_step(get_step(user, EAST), EAST), EAST)
	var/mob/living/simple_animal/hostile/illusion/heretic_moon/reflection = knowledge.create_reflection(user, far_turf)
	TEST_ASSERT_NOTNULL(reflection, "Удалённое отражение должно создаться.")
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(far_turf, NORTH))
	var/obj/effect/proc_holder/spell/self/heretic_moon/eclipse/spell = allocate(/obj/effect/proc_holder/spell/self/heretic_moon/eclipse)
	spell.cast(list(user), user)
	TEST_ASSERT(victim.confused > 0, "Вспышка двойника должна доставать врага дальше двух клеток от владельца.")
	var/datum/status_effect/heretic_moon_shroud/shroud = user.has_status_effect(/datum/status_effect/heretic_moon_shroud)
	TEST_ASSERT_NOTNULL(shroud, "Затмение должно скрывать владельца.")
	var/mob/living/simple_animal/hostile/illusion/heretic_moon/decoy = locate() in get_turf(user)
	TEST_ASSERT_NOTNULL(decoy, "На месте владельца должен появиться двойник.")
	decoy.sync_appearance()
	TEST_ASSERT_EQUAL(length(decoy.filters), length(user.filters) - 1, "Оставленный двойник не должен исчезать вместе с владельцем.")

/// Контроллер самостоятельно подводит двойника к врагу и наносит оба вида урона.
/datum/unit_test/heretic_moon_pursuit
	var/mob/living/carbon/human/caster

/datum/unit_test/heretic_moon_pursuit/Run()
	caster = make_moon_heretic(run_loc_floor_bottom_left)
	caster.put_in_hands(allocate(/obj/item/melee/sickly_blade/moon))
	register_fake_player(caster, get_turf(caster))
	var/datum/eldritch_knowledge/base_moon/knowledge = get_heretic_moon(caster)
	var/mob/living/simple_animal/hostile/illusion/heretic_moon/reflection = knowledge.create_reflection(caster, get_step(caster, NORTH))
	var/turf/destination = locate(caster.x + 3, caster.y + 1, caster.z)
	var/mob/living/victim = allocate(/mob/living/carbon/human, destination)
	var/turf/origin = get_turf(reflection)
	var/list/budget = new_wait_budget(10 SECONDS, "двойник должен подойти и атаковать")
	while(!victim.getStaminaLoss())
		if(!wait_budget_tick(budget))
			break
	TEST_ASSERT_NOTEQUAL(get_turf(reflection), origin, "Двойник должен самостоятельно двигаться к врагу.")
	TEST_ASSERT(victim.getStaminaLoss() > 0, "Контроллер должен проводить ложные атаки.")
	TEST_ASSERT(victim.getBruteLoss() > 0, "Автономные атаки должны наносить физический урон.")
	var/obj/item/projectile/bullet = allocate(/obj/item/projectile, destination)
	bullet.damage = 20
	bullet.firer = victim
	bullet.starting = destination
	reflection.bullet_act(bullet)
	TEST_ASSERT(!QDELETED(reflection), "Один снаряд в 20 урона не разбивает двойника.")
	reflection.bullet_act(bullet)
	TEST_ASSERT(QDELETED(reflection), "Второе попадание снаряда разбивает двойника.")

/datum/unit_test/heretic_moon_pursuit/Destroy()
	if(caster)
		unregister_fake_player(caster)
	caster = null
	return ..()

/// Соседняя копия принимает снаряд и расходуется; серия обходит задержку защиты.
/datum/unit_test/heretic_moon_projectile_interception/Run()
	var/mob/living/user = make_moon_heretic(run_loc_floor_bottom_left)
	var/datum/eldritch_knowledge/base_moon/knowledge = get_heretic_moon(user)
	var/mob/living/simple_animal/hostile/illusion/heretic_moon/first = knowledge.create_reflection(user, get_step(user, EAST))
	var/mob/living/simple_animal/hostile/illusion/heretic_moon/second = knowledge.create_reflection(user, get_step(user, NORTH))
	var/mob/living/attacker = allocate(/mob/living/carbon/human, get_step(get_step(get_step(user, EAST), EAST), EAST))
	attacker.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5)
	var/obj/item/projectile/bullet = allocate(/obj/item/projectile, get_turf(attacker))
	bullet.damage = 20
	bullet.firer = attacker
	bullet.starting = get_turf(attacker)
	TEST_ASSERT(!(user.do_run_block(FALSE, bullet, 20, "снаряд", ATTACK_TYPE_PROJECTILE, 0, attacker) & BLOCK_SUCCESS), "Предварительная проверка не жертвует копией.")
	TEST_ASSERT_EQUAL(length(knowledge.reflections), 2, "Проверка оставляет обе копии на месте.")
	TEST_ASSERT_EQUAL(user.bullet_act(bullet, BODY_ZONE_CHEST), BULLET_ACT_BLOCK, "Копия принимает настоящий снаряд от стрелка с антимагией.")
	TEST_ASSERT(QDELETED(first), "Перехват уничтожает одну соседнюю копию.")
	TEST_ASSERT_EQUAL(user.getBruteLoss(), 0, "Перехваченный снаряд не ранит владельца.")
	TEST_ASSERT(!QDELETED(second), "Один снаряд не расходует обе копии.")
	TEST_ASSERT(!(user.do_run_block(TRUE, bullet, 20, "очередь", ATTACK_TYPE_PROJECTILE, 0, attacker) & BLOCK_SUCCESS), "Следующий снаряд проходит до восстановления защиты.")
	knowledge.next_interception = world.time - 1
	TEST_ASSERT(user.do_run_block(TRUE, bullet, 20, "снаряд турели", ATTACK_TYPE_PROJECTILE, 0, null) & BLOCK_SUCCESS, "Перехват работает без живого стрелка.")
	TEST_ASSERT(QDELETED(second), "Повторный перехват расходует оставшуюся копию.")
	TEST_ASSERT_EQUAL(length(knowledge.reflections), 0, "Израсходованные копии освобождают лимит.")
	knowledge.on_body_lose(user)
	TEST_ASSERT(!(user.do_run_block(TRUE, bullet, 20, "снаряд", ATTACK_TYPE_PROJECTILE, 0, attacker) & BLOCK_SUCCESS), "Смена тела удаляет обработчик перехвата.")

/// Создание быстро даёт пару копий и позволяет заменить старейшую при полном лимите.
/datum/unit_test/heretic_moon_create_pair/Run()
	var/mob/living/user = make_moon_heretic(run_loc_floor_bottom_left)
	var/datum/eldritch_knowledge/base_moon/knowledge = get_heretic_moon(user)
	var/obj/effect/proc_holder/spell/pointed/heretic_moon/create/spell = knowledge.reflection_spell
	spell.cast(list(get_step(user, EAST)), user)
	TEST_ASSERT_EQUAL(length(knowledge.reflections), 2, "Одно применение создаёт атакующую и защитную копии.")
	var/mob/living/simple_animal/hostile/illusion/heretic_moon/oldest = knowledge.reflections[1]
	TEST_ASSERT(locate(/mob/living/simple_animal/hostile/illusion/heretic_moon) in get_turf(user), "Защитная копия появляется на месте владельца.")
	spell.cast(list(get_step(user, NORTH)), user)
	TEST_ASSERT(QDELETED(oldest), "Новая копия заменяет старейшую без ручного удаления.")
	TEST_ASSERT_EQUAL(length(knowledge.reflections), 2, "Замена сохраняет предел копий.")

/// Затмение сразу после «Лунного отражения» срабатывает, хотя копия уже стоит под владельцем.
/datum/unit_test/heretic_moon_eclipse_after_reflection/Run()
	var/mob/living/user = make_moon_heretic(run_loc_floor_bottom_left)
	var/datum/eldritch_knowledge/base_moon/knowledge = get_heretic_moon(user)
	var/obj/effect/proc_holder/spell/pointed/heretic_moon/create/create_spell = knowledge.reflection_spell
	create_spell.cast(list(get_step(get_step(user, EAST), EAST)), user)
	TEST_ASSERT(locate(/mob/living/simple_animal/hostile/illusion/heretic_moon) in get_turf(user), "Отражение оставляет копию под владельцем.")
	var/list/before = knowledge.reflections.Copy()
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, NORTH))
	var/obj/effect/proc_holder/spell/self/heretic_moon/eclipse/spell = allocate(/obj/effect/proc_holder/spell/self/heretic_moon/eclipse)
	spell.charge_counter = 0
	spell.cast(list(user), user)
	TEST_ASSERT_EQUAL(spell.charge_counter, 0, "Копия под ногами не отменяет затмение.")
	TEST_ASSERT(victim.confused > 0, "Затмение путает врага рядом.")
	TEST_ASSERT(user.has_status_effect(/datum/status_effect/heretic_moon_shroud), "Затмение скрывает владельца.")
	TEST_ASSERT(locate(/mob/living/simple_animal/hostile/illusion/heretic_moon) in get_turf(user), "На месте владельца остаётся копия.")
	TEST_ASSERT_EQUAL(length(knowledge.reflections & before), 2, "Готовая приманка под ногами не вытесняет другие копии.")

/// Копии выдерживают 30 урона, 40 с «Третьим силуэтом» и 50 после вознесения.
/datum/unit_test/heretic_moon_durability/Run()
	var/mob/living/user = make_moon_heretic(run_loc_floor_bottom_left)
	var/datum/eldritch_knowledge/base_moon/knowledge = get_heretic_moon(user)
	var/mob/living/simple_animal/hostile/illusion/heretic_moon/basic = knowledge.create_reflection(user, get_step(user, EAST))
	TEST_ASSERT_EQUAL(basic.maxHealth, 30, "Обычная копия выдерживает 30 урона.")
	basic.adjustBruteLoss(20)
	TEST_ASSERT(!QDELETED(basic), "Удар в 20 урона не разбивает копию.")
	knowledge.upgraded = TRUE
	var/mob/living/simple_animal/hostile/illusion/heretic_moon/upgraded = knowledge.create_reflection(user, get_step(user, NORTH))
	TEST_ASSERT_EQUAL(upgraded.maxHealth, 40, "Третий силуэт повышает прочность копий до 40.")
	knowledge.ascension_active = TRUE
	var/mob/living/simple_animal/hostile/illusion/heretic_moon/ascended = knowledge.create_reflection(user, get_step(user, NORTHEAST))
	TEST_ASSERT_EQUAL(ascended.maxHealth, 50, "Вознесение повышает прочность копий до 50.")
	TEST_ASSERT_EQUAL(ascended.health, 50, "Новая копия появляется целой.")

/// Лунный маскарад изматывает видимых врагов и подсылает к каждому временную копию вне предела.
/datum/unit_test/heretic_moon_masquerade/Run()
	var/mob/living/user = make_moon_heretic(locate(run_loc_floor_bottom_left.x - 1, run_loc_floor_bottom_left.y - 1, run_loc_floor_bottom_left.z))
	var/datum/eldritch_knowledge/base_moon/knowledge = get_heretic_moon(user)
	knowledge.ascension_active = TRUE
	var/obj/effect/proc_holder/spell/self/heretic_moon/masquerade/spell = allocate(/obj/effect/proc_holder/spell/self/heretic_moon/masquerade)
	spell.charge_counter = 0
	spell.cast(list(user), user)
	TEST_ASSERT_EQUAL(spell.charge_counter, spell.charge_max, "Без врагов маскарад возвращает перезарядку.")
	var/mob/living/simple_animal/hostile/illusion/heretic_moon/regular = knowledge.create_reflection(user, get_step(user, EAST))
	var/regular_expiry = regular.reflection_expires_at
	var/mob/living/first = allocate(/mob/living/carbon/human, locate(user.x + 3, user.y + 1, user.z))
	var/mob/living/second = allocate(/mob/living/carbon/human, locate(user.x + 6, user.y + 6, user.z))
	var/mob/living/ally = make_moon_heretic(locate(user.x + 4, user.y + 4, user.z))
	spell.charge_counter = 0
	spell.cast(list(user), user)
	TEST_ASSERT_EQUAL(spell.charge_counter, 0, "Маскарад с целями расходует перезарядку.")
	for(var/mob/living/victim as anything in list(first, second))
		TEST_ASSERT_EQUAL(victim.getStaminaLoss(), 30, "Каждый видимый враг получает 30 урона выносливости.")
		TEST_ASSERT(victim.confused >= 3, "Каждый видимый враг путается.")
		var/mob/living/simple_animal/hostile/illusion/heretic_moon/shade
		for(var/mob/living/simple_animal/hostile/illusion/heretic_moon/candidate as anything in knowledge.temporary_reflections)
			if(candidate.target == victim)
				shade = candidate
		TEST_ASSERT_NOTNULL(shade, "К каждому врагу приходит своя временная копия.")
		TEST_ASSERT(get_dist(shade, victim) <= 1, "Временная копия встаёт рядом с целью.")
		TEST_ASSERT(shade.CanAttack(victim), "Временная копия достаёт свою цель и дальше пяти клеток от владельца.")
		TEST_ASSERT_EQUAL(shade.reflection_expires_at, world.time + 10 SECONDS, "Временная копия живёт 10 секунд.")
	TEST_ASSERT_EQUAL(ally.getStaminaLoss(), 0, "Маскарад не трогает союзного еретика.")
	TEST_ASSERT_EQUAL(length(knowledge.temporary_reflections), 2, "Временных копий ровно по одной на цель.")
	TEST_ASSERT_EQUAL(length(knowledge.reflections), 1, "Временные копии не входят в предел отражений.")
	TEST_ASSERT(!QDELETED(regular) && regular.reflection_expires_at == regular_expiry, "Обычная копия остаётся нетронутой.")
	knowledge.clear_reflections()
	TEST_ASSERT_EQUAL(length(knowledge.temporary_reflections), 0, "Очистка убирает и временные копии.")

/// Маскарад задевает не больше пяти ближайших врагов.
/datum/unit_test/heretic_moon_masquerade_cap/Run()
	var/mob/living/user = make_moon_heretic(run_loc_floor_bottom_left)
	var/datum/eldritch_knowledge/base_moon/knowledge = get_heretic_moon(user)
	var/list/mob/living/victims = list()
	for(var/list/offset as anything in list(list(1, 1), list(2, 0), list(0, 3), list(3, 3), list(4, 2)))
		victims += allocate(/mob/living/carbon/human, locate(user.x + offset[1], user.y + offset[2], user.z))
	var/mob/living/farthest = allocate(/mob/living/carbon/human, locate(user.x + 5, user.y + 5, user.z))
	var/obj/effect/proc_holder/spell/self/heretic_moon/masquerade/spell = allocate(/obj/effect/proc_holder/spell/self/heretic_moon/masquerade)
	spell.cast(list(user), user)
	for(var/mob/living/victim as anything in victims)
		TEST_ASSERT_EQUAL(victim.getStaminaLoss(), 30, "Пять ближайших врагов попадают под маскарад.")
	TEST_ASSERT_EQUAL(farthest.getStaminaLoss(), 0, "Шестой, самый дальний враг остаётся вне маскарада.")
	TEST_ASSERT_EQUAL(length(knowledge.temporary_reflections), 5, "Временных копий не больше пяти.")

/// Вознесение Луны выдаёт маскарад, а потеря тела его забирает.
/datum/unit_test/heretic_moon_masquerade_grant/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_moon)
	var/datum/eldritch_knowledge/final_eldritch/moon_final/final_knowledge = allocate(/datum/eldritch_knowledge/final_eldritch/moon_final)
	final_knowledge.finished = TRUE
	final_knowledge.on_body_gain(user)
	TEST_ASSERT(locate(/obj/effect/proc_holder/spell/self/heretic_moon/masquerade) in user.mind.spell_list, "Вознесение выдаёт «Лунный маскарад».")
	final_knowledge.on_body_lose(user)
	TEST_ASSERT(!(locate(/obj/effect/proc_holder/spell/self/heretic_moon/masquerade) in user.mind.spell_list), "Потеря тела забирает маскарад.")

/datum/unit_test/proc/ascend_moon_fixture()
	var/datum/antagonist/heretic/heretic = allocate_heretic(run_loc_floor_bottom_left)
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_moon)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/final_eldritch/moon_final/finale = allocate(/datum/eldritch_knowledge/final_eldritch/moon_final)
	heretic.researched_knowledge[finale.type] = finale
	heretic.ascended = TRUE
	finale.finished = TRUE
	finale.on_body_gain(user)
	return list("user" = user, "heretic" = heretic, "finale" = finale, "knowledge" = get_heretic_moon(user))

/// Вознёсшийся перехватывает снаряды копиями в двух клетках без задержки, потеря тела снимает аспект.
/datum/unit_test/heretic_moon_ascended_interception/Run()
	var/list/fixture = ascend_moon_fixture()
	var/mob/living/carbon/human/user = fixture["user"]
	var/datum/eldritch_knowledge/base_moon/knowledge = fixture["knowledge"]
	var/datum/eldritch_knowledge/final_eldritch/moon_final/finale = fixture["finale"]
	TEST_ASSERT(knowledge.ascension_active, "Вознесение включает аспект пути.")
	TEST_ASSERT_NOTNULL(user.GetComponent(/datum/component/heretic_moon_circus), "Вознесение Луны даёт цирк отражений.")
	var/mob/living/simple_animal/hostile/illusion/heretic_moon/first = knowledge.create_reflection(user, get_step(get_step(user, EAST), EAST))
	var/mob/living/simple_animal/hostile/illusion/heretic_moon/second = knowledge.create_reflection(user, get_step(get_step(user, NORTH), NORTH))
	TEST_ASSERT(first && second, "Копии встают в двух клетках от владельца.")
	var/mob/living/attacker = allocate(/mob/living/carbon/human, get_step(user, NORTHEAST))
	var/obj/item/projectile/bullet = allocate(/obj/item/projectile, get_turf(attacker))
	bullet.damage = 20
	bullet.firer = attacker
	TEST_ASSERT(user.do_run_block(TRUE, bullet, 20, "снаряд", ATTACK_TYPE_PROJECTILE, 0, attacker) & BLOCK_SUCCESS, "Копия в двух клетках перехватывает снаряд.")
	TEST_ASSERT(user.do_run_block(TRUE, bullet, 20, "очередь", ATTACK_TYPE_PROJECTILE, 0, attacker) & BLOCK_SUCCESS, "Второй снаряд перехватывается сразу, без задержки.")
	TEST_ASSERT(QDELETED(first) && QDELETED(second), "Каждый перехват расходует копию.")
	finale.on_body_lose(user)
	TEST_ASSERT(!knowledge.ascension_active, "Потеря тела снимает аспект.")
	TEST_ASSERT_NULL(user.GetComponent(/datum/component/heretic_moon_circus), "Потеря тела снимает цирк отражений.")

/// Лунатик после маскарада 12 секунд стреляет с добавочным разбросом.
/datum/unit_test/heretic_moon_lunatic_spread
	var/last_spread

/datum/unit_test/heretic_moon_lunatic_spread/proc/record_spread(mob/living/source, atom/target, params, zone_override, bonus_spread, stam_cost)
	SIGNAL_HANDLER
	last_spread = bonus_spread

/datum/unit_test/heretic_moon_lunatic_spread/Run()
	var/list/fixture = ascend_moon_fixture()
	var/mob/living/carbon/human/user = fixture["user"]
	var/datum/eldritch_knowledge/base_moon/knowledge = fixture["knowledge"]
	var/mob/living/carbon/human/shooter = allocate(/mob/living/carbon/human, get_step(get_step(user, EAST), EAST))
	var/obj/item/gun/ballistic/automatic/c20r/unrestricted/gun = allocate(/obj/item/gun/ballistic/automatic/c20r/unrestricted, get_turf(shooter))
	TEST_ASSERT(shooter.put_in_active_hand(gun), "Стрелок держит заряженное оружие.")
	gun.burst_size = 1
	RegisterSignal(shooter, COMSIG_LIVING_GUN_PROCESS_FIRE, PROC_REF(record_spread))
	var/turf/target = get_step(get_step(shooter, EAST), EAST)
	gun.last_fire = world.time - gun.fire_delay - 1
	gun.process_fire(target, shooter)
	TEST_ASSERT_EQUAL(last_spread, 0, "Без маскарада разброса нет.")
	knowledge.masquerade_strike(user, shooter)
	var/datum/status_effect/heretic_lunatic/lunatic = shooter.has_status_effect(/datum/status_effect/heretic_lunatic)
	TEST_ASSERT_NOTNULL(lunatic, "Маскарад делает цель лунатиком.")
	TEST_ASSERT_EQUAL(lunatic.duration, world.time + HERETIC_MOON_LUNATIC_DURATION, "Лунатик длится 12 секунд.")
	TEST_ASSERT(shooter.confused > 0, "Лунатик путается.")
	gun.last_fire = world.time - gun.fire_delay - 1
	gun.process_fire(target, shooter)
	TEST_ASSERT_EQUAL(last_spread, HERETIC_MOON_LUNATIC_SPREAD, "Выстрел лунатика получает разброс 30.")
	shooter.remove_status_effect(/datum/status_effect/heretic_lunatic)
	TEST_ASSERT(!HAS_TRAIT(shooter, TRAIT_HERETIC_LUNATIC), "Конец эффекта возвращает меткость.")
	UnregisterSignal(shooter, COMSIG_LIVING_GUN_PROCESS_FIRE)

/// Вспышка в трёх клетках разбивает ближние копии и ослепляет вознёсшегося, дальняя вспышка безвредна.
/datum/unit_test/heretic_moon_flash_weakness/Run()
	var/list/fixture = ascend_moon_fixture()
	var/mob/living/carbon/human/user = fixture["user"]
	var/datum/eldritch_knowledge/base_moon/knowledge = fixture["knowledge"]
	var/mob/living/simple_animal/hostile/illusion/heretic_moon/near = knowledge.create_reflection(user, get_step(user, EAST))
	var/mob/living/simple_animal/hostile/illusion/heretic_moon/far = knowledge.create_reflection(user, locate(user.x + 4, user.y, user.z))
	TEST_ASSERT(near && far, "Копии стоят рядом и в четырёх клетках.")
	var/obj/item/assembly/flash/handheld/distant = allocate(/obj/item/assembly/flash/handheld, locate(user.x, user.y + 5, user.z))
	TEST_ASSERT(distant.try_use_flash(), "Дальняя вспышка срабатывает.")
	TEST_ASSERT(!QDELETED(near), "Вспышка дальше трёх клеток не трогает копии.")
	TEST_ASSERT_EQUAL(user.eye_blind, 0, "Дальняя вспышка не ослепляет.")
	var/obj/item/assembly/flash/handheld/flash = allocate(/obj/item/assembly/flash/handheld, locate(user.x, user.y + 2, user.z))
	TEST_ASSERT(flash.try_use_flash(), "Ближняя вспышка срабатывает.")
	TEST_ASSERT(QDELETED(near), "Вспышка разбивает копию в трёх клетках от владельца.")
	TEST_ASSERT(!QDELETED(far), "Копия дальше трёх клеток уцелела.")
	TEST_ASSERT(user.eye_blind > 0, "Вспышка ослепляет вознёсшегося.")

/// Копия за окном не перехватывает снаряд, а окно на клетке героя закрывает только свою сторону.
/datum/unit_test/heretic_moon_intercept_line/Run()
	var/list/fixture = ascend_moon_fixture()
	var/mob/living/carbon/human/user = fixture["user"]
	var/datum/eldritch_knowledge/base_moon/knowledge = fixture["knowledge"]
	var/turf/start = get_turf(user)
	var/obj/structure/window/fulltile/pane = allocate(/obj/structure/window/fulltile, locate(start.x + 1, start.y, start.z))
	var/mob/living/simple_animal/hostile/illusion/heretic_moon/hidden = knowledge.create_reflection(user, locate(start.x + 2, start.y, start.z))
	TEST_ASSERT_NOTNULL(hidden, "Копия встаёт за окном в двух клетках.")
	var/mob/living/attacker = allocate(/mob/living/carbon/human, locate(start.x, start.y + 2, start.z))
	var/obj/item/projectile/bullet = allocate(/obj/item/projectile, get_turf(attacker))
	bullet.damage = 20
	bullet.firer = attacker
	TEST_ASSERT(!(user.do_run_block(TRUE, bullet, 20, "снаряд", ATTACK_TYPE_PROJECTILE, 0, attacker) & BLOCK_SUCCESS), "Копия за окном не перехватывает снаряд.")
	TEST_ASSERT(!QDELETED(hidden), "Копия за окном цела.")
	qdel(pane)
	var/obj/structure/window/own_pane = allocate(/obj/structure/window, start)
	own_pane.setDir(EAST)
	TEST_ASSERT(!(user.do_run_block(TRUE, bullet, 20, "снаряд", ATTACK_TYPE_PROJECTILE, 0, attacker) & BLOCK_SUCCESS), "Окно на клетке героя со стороны копии закрывает перехват.")
	TEST_ASSERT(!QDELETED(hidden), "Копия за окном героя цела.")
	own_pane.setDir(WEST)
	TEST_ASSERT(user.do_run_block(TRUE, bullet, 20, "снаряд", ATTACK_TYPE_PROJECTILE, 0, attacker) & BLOCK_SUCCESS, "Окно на другой стороне клетки героя не мешает перехвату.")
	TEST_ASSERT(QDELETED(hidden), "Перехват расходует копию.")

/// Своя вспышка вознёсшейся Луны не разбивает её копии и не слепит её.
/datum/unit_test/heretic_moon_own_flash/Run()
	var/list/fixture = ascend_moon_fixture()
	var/mob/living/carbon/human/user = fixture["user"]
	var/datum/eldritch_knowledge/base_moon/knowledge = fixture["knowledge"]
	var/mob/living/simple_animal/hostile/illusion/heretic_moon/near = knowledge.create_reflection(user, get_step(user, EAST))
	TEST_ASSERT_NOTNULL(near, "Копия стоит рядом.")
	var/obj/item/assembly/flash/handheld/flash = allocate(/obj/item/assembly/flash/handheld, get_turf(user))
	TEST_ASSERT(user.put_in_active_hand(flash), "Еретик держит флешер.")
	flash.attack_self(user)
	TEST_ASSERT(!QDELETED(near), "Своя вспышка не разбивает копию.")
	TEST_ASSERT_EQUAL(user.eye_blind, 0, "Своя вспышка не слепит.")
	var/mob/living/carbon/human/crew = allocate(/mob/living/carbon/human, locate(user.x, user.y + 2, user.z))
	var/obj/item/assembly/flash/handheld/crew_flash = allocate(/obj/item/assembly/flash/handheld, get_turf(crew))
	TEST_ASSERT(crew.put_in_active_hand(crew_flash), "Экипаж держит флешер.")
	crew_flash.attack_self(crew)
	TEST_ASSERT(QDELETED(near), "Чужая вспышка из рук разбивает копию.")
	TEST_ASSERT(user.eye_blind > 0, "Чужая вспышка слепит.")

/// Флешер в кармане вознёсшейся Луны, сработавший от ЭМИ, считается чужой вспышкой.
/datum/unit_test/heretic_moon_emp_flash/Run()
	var/list/fixture = ascend_moon_fixture()
	var/mob/living/carbon/human/user = fixture["user"]
	var/datum/eldritch_knowledge/base_moon/knowledge = fixture["knowledge"]
	var/mob/living/simple_animal/hostile/illusion/heretic_moon/near = knowledge.create_reflection(user, get_step(user, EAST))
	TEST_ASSERT_NOTNULL(near, "Копия стоит рядом.")
	var/obj/item/assembly/flash/handheld/flash = allocate(/obj/item/assembly/flash/handheld, user)
	flash.emp_act(1)
	TEST_ASSERT(QDELETED(near), "Флешер, сработавший в кармане от ЭМИ, разбивает копию.")

/// Убитая копия вспыхивает серебром и разлетается осколками зеркала; копия, разбитая чужой вспышкой, - так же.
/datum/unit_test/heretic_moon_shatter_visuals/Run()
	var/list/fixture = ascend_moon_fixture()
	var/mob/living/carbon/human/user = fixture["user"]
	var/datum/eldritch_knowledge/base_moon/knowledge = fixture["knowledge"]
	var/mob/living/simple_animal/hostile/illusion/heretic_moon/killed = knowledge.create_reflection(user, get_step(user, EAST))
	TEST_ASSERT_NOTNULL(killed, "Копия встаёт рядом.")
	var/turf/killed_place = get_turf(killed)
	var/list/before = list_vfx_bursts(killed_place)
	killed.death()
	TEST_ASSERT(QDELETED(killed), "Убитая копия исчезает.")
	var/obj/effect/temp_visual/heretic_moon_shatter/flash = locate() in killed_place
	TEST_ASSERT_NOTNULL(flash, "Убитая копия вспыхивает серебром.")
	TEST_ASSERT(flash.mouse_opacity == MOUSE_OPACITY_TRANSPARENT, "Вспышка не мешает кликам.")
	var/obj/effect/temp_visual/heretic_vfx/burst/shards = find_vfx_burst(killed_place, /particles/heretic_ascension/moon/shards, before)
	TEST_ASSERT_NOTNULL(shards, "Убитая копия разлетается осколками зеркала.")
	TEST_ASSERT_NULL(locate(/obj/effect/temp_visual/heretic_grasp/moon) in killed_place, "Поверх осколков не ложится бледный след исчезновения.")
	var/mob/living/simple_animal/hostile/illusion/heretic_moon/flashed = knowledge.create_reflection(user, get_step(user, NORTH))
	TEST_ASSERT_NOTNULL(flashed, "Вторая копия встаёт рядом.")
	var/turf/flashed_place = get_turf(flashed)
	var/list/flashed_before = list_vfx_bursts(flashed_place)
	var/obj/item/assembly/flash/handheld/flasher = allocate(/obj/item/assembly/flash/handheld, locate(user.x, user.y + 2, user.z))
	TEST_ASSERT(flasher.try_use_flash(), "Чужая вспышка срабатывает.")
	TEST_ASSERT(QDELETED(flashed), "Вспышка разбивает копию.")
	TEST_ASSERT_NOTNULL(locate(/obj/effect/temp_visual/heretic_moon_shatter) in flashed_place, "Разбитая вспышкой копия вспыхивает серебром.")
	var/obj/effect/temp_visual/heretic_vfx/burst/flashed_shards = find_vfx_burst(flashed_place, /particles/heretic_ascension/moon/shards, flashed_before)
	TEST_ASSERT_NOTNULL(flashed_shards, "Разбитая вспышкой копия разлетается осколками.")
	TEST_ASSERT(wait_for_qdeleted(flash), "Серебряная вспышка гаснет.")
	TEST_ASSERT(wait_for_qdeleted(shards), "Осколки оседают, эмиттер удаляется.")
	TEST_ASSERT(wait_for_qdeleted(flashed_shards), "Осколки второй копии оседают.")

/// Лунатик несёт мерцающее лунное око и серебряный ореол, иногда двоится; конец эффекта гасит око и ореол.
/datum/unit_test/heretic_moon_lunatic_visuals/Run()
	var/list/fixture = ascend_moon_fixture()
	var/mob/living/carbon/human/user = fixture["user"]
	var/datum/eldritch_knowledge/base_moon/knowledge = fixture["knowledge"]
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, get_step(get_step(user, EAST), EAST))
	var/turf/place = get_turf(victim)
	knowledge.masquerade_strike(user, victim)
	TEST_ASSERT_EQUAL(victim.getStaminaLoss(), 30, "Маскарад по-прежнему наносит 30 урона выносливости.")
	TEST_ASSERT_NOTNULL(locate(/obj/effect/temp_visual/heretic_moon_mirror) in place, "Цель маскарада двоится серебряным отражением.")
	var/datum/status_effect/heretic_lunatic/lunatic = victim.has_status_effect(/datum/status_effect/heretic_lunatic)
	TEST_ASSERT_NOTNULL(lunatic, "Цель становится лунатиком.")
	var/obj/effect/abstract/heretic_vfx_attached/eye = lunatic.eye
	TEST_ASSERT_NOTNULL(eye, "Над лунатиком открывается лунное око.")
	TEST_ASSERT(eye in victim.vis_contents, "Око держится на лунатике.")
	TEST_ASSERT_EQUAL(eye.icon_state, "moon_eye", "Око рисуется своим стейтом.")
	TEST_ASSERT(eye.pixel_y > 0, "Око висит над головой.")
	TEST_ASSERT(eye.mouse_opacity == MOUSE_OPACITY_TRANSPARENT, "Око не мешает кликам.")
	TEST_ASSERT(eye.glow in eye.vis_contents, "Око светится в темноте.")
	TEST_ASSERT(!(eye.appearance_flags & RESET_ALPHA), "Око гаснет вместе с прозрачным лунатиком.")
	TEST_ASSERT(eye.appearance_flags & RESET_TRANSFORM, "Око не ложится вместе с телом.")
	TEST_ASSERT_NOTNULL(victim.get_filter(HERETIC_MOON_LUNATIC_HALO), "Лунатика окружает серебряный ореол.")
	var/list/ghosts_before = list()
	for(var/obj/effect/temp_visual/heretic_moon_mirror/ghost in place)
		ghosts_before += ghost
	for(var/tick in 1 to 20)
		lunatic.tick()
	for(var/obj/effect/temp_visual/heretic_moon_mirror/ghost in place)
		TEST_ASSERT(ghost in ghosts_before, "Без зрителей лунатик не двоится.")
	var/obj/effect/temp_visual/heretic_moon_mirror/double = lunatic.jitter()
	TEST_ASSERT_NOTNULL(double, "Лунатик двоится.")
	TEST_ASSERT(!(double in ghosts_before) && double.loc == place, "Двойник мелькает на клетке лунатика.")
	TEST_ASSERT(double.mouse_opacity == MOUSE_OPACITY_TRANSPARENT, "Двойник не мешает кликам.")
	victim.remove_status_effect(/datum/status_effect/heretic_lunatic)
	TEST_ASSERT(!HAS_TRAIT(victim, TRAIT_HERETIC_LUNATIC), "Конец эффекта возвращает меткость.")
	TEST_ASSERT_NULL(victim.get_filter(HERETIC_MOON_LUNATIC_HALO), "Ореол гаснет вместе с эффектом.")
	TEST_ASSERT(!QDELETED(eye) && eye.fading, "Око закрывается плавно, а не пропадает рывком.")
	TEST_ASSERT(wait_for_qdeleted(eye), "Око исчезает.")
	TEST_ASSERT(!(eye in victim.vis_contents), "Исчезнувшее око снимается с лунатика.")
	TEST_ASSERT(wait_for_qdeleted(double), "Двойник гаснет.")

/// Маскарад: отражения отскакивают от героя, серебряная волна, вспышка и частицы; цели получают прежний урон.
/datum/unit_test/heretic_moon_masquerade_visuals/Run()
	var/list/fixture = ascend_moon_fixture()
	var/mob/living/carbon/human/user = fixture["user"]
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, locate(user.x + 3, user.y + 1, user.z))
	var/turf/center = get_turf(user)
	var/list/before = list_vfx_bursts(center)
	user.render_target = "heretic_moon_masquerade_test"
	var/obj/effect/proc_holder/spell/self/heretic_moon/masquerade/spell = allocate(/obj/effect/proc_holder/spell/self/heretic_moon/masquerade)
	spell.cast(list(user), user)
	user.render_target = null
	TEST_ASSERT_EQUAL(victim.getStaminaLoss(), 30, "Маскарад наносит прежние 30 урона выносливости.")
	TEST_ASSERT(victim.confused >= 3, "Маскарад по-прежнему путает цель.")
	var/list/ghosts = list()
	for(var/obj/effect/temp_visual/heretic_moon_mirror/ghost in center)
		ghosts += ghost
	TEST_ASSERT_EQUAL(length(ghosts), 2, "Два отражения отскакивают от героя.")
	for(var/obj/effect/temp_visual/heretic_moon_mirror/ghost as anything in ghosts)
		TEST_ASSERT_NULL(ghost.render_target, "Отражение не забирает цель отрисовки героя.")
	var/obj/effect/temp_visual/heretic_vfx/shockwave/wave = locate() in center
	TEST_ASSERT_NOTNULL(wave, "От героя расходится серебряная волна.")
	var/obj/effect/temp_visual/heretic_vfx/burst/motes = find_vfx_burst(center, /particles/heretic_ascension/moon, before)
	TEST_ASSERT_NOTNULL(motes, "Маскарад рассыпает лунные блики.")
	TEST_ASSERT_NULL(locate(/obj/effect/temp_visual/heretic_spell/moon) in center, "Старое плоское кольцо заменено волной.")
	TEST_ASSERT(wait_for_qdeleted(wave), "Волна гаснет.")
	for(var/obj/effect/temp_visual/heretic_moon_mirror/ghost as anything in ghosts)
		TEST_ASSERT(wait_for_qdeleted(ghost), "Отражения героя гаснут.")
	TEST_ASSERT(wait_for_qdeleted(motes), "Блики оседают.")

/// Копии вознёсшейся Луны мерцают серебром, потеря вознесения гасит мерцание, а разбитая копия отпускает блики.
/datum/unit_test/heretic_moon_shimmer/Run()
	var/list/fixture = ascend_moon_fixture()
	var/mob/living/carbon/human/user = fixture["user"]
	var/datum/eldritch_knowledge/base_moon/knowledge = fixture["knowledge"]
	var/datum/eldritch_knowledge/final_eldritch/moon_final/finale = fixture["finale"]
	var/mob/living/simple_animal/hostile/illusion/heretic_moon/reflection = knowledge.create_reflection(user, get_step(user, EAST))
	var/obj/effect/abstract/heretic_particle_holder/shimmer = reflection.shimmer
	TEST_ASSERT_NOTNULL(shimmer, "Копия вознёсшейся мерцает.")
	TEST_ASSERT(shimmer in reflection.vis_contents, "Блики держатся на копии.")
	TEST_ASSERT(shimmer.particles.count <= 4, "Мерцание скупое.")
	TEST_ASSERT(!(shimmer.appearance_flags & RESET_ALPHA), "Мерцание гаснет вместе с прозрачной копией.")
	finale.on_body_lose(user)
	TEST_ASSERT_NULL(reflection.shimmer, "Потеря вознесения гасит мерцание.")
	TEST_ASSERT(!(shimmer in reflection.vis_contents), "Блики снимаются с копии.")
	TEST_ASSERT(wait_for_qdeleted(shimmer), "Последние блики догорают.")
	knowledge.ascension_active = TRUE
	reflection.sync_ascension_aura()
	var/obj/effect/abstract/heretic_particle_holder/second = reflection.shimmer
	TEST_ASSERT_NOTNULL(second, "Вернувшееся вознесение снова зажигает мерцание.")
	var/turf/place = get_turf(reflection)
	qdel(reflection)
	TEST_ASSERT_EQUAL(second.loc, place, "Удалённая копия оставляет последние блики на своём месте.")
	TEST_ASSERT(wait_for_qdeleted(second), "Блики удалённой копии догорают.")

/datum/unit_test/heretic_moon_visual_types_create_and_destroy/Run()
	for(var/thing_type in list(/obj/effect/temp_visual/heretic_moon_mirror, /obj/effect/temp_visual/heretic_moon_shatter, /obj/effect/abstract/heretic_vfx_attached))
		var/atom/movable/thing = new thing_type(run_loc_floor_bottom_left)
		qdel(thing)
		TEST_ASSERT(QDELETED(thing), "[thing_type] удаляется без ошибок.")
