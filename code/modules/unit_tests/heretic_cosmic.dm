/// Одиночная вспышка расходует только выбранную звезду, сохраняя преграды, срок жизни и повреждения других.
/datum/unit_test/heretic_cosmic_selective_flare/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	heretic.selected_path = PATH_COSMIC
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_cosmic)
	heretic.gain_knowledge(/datum/eldritch_knowledge/cosmic_expansion)
	heretic.gain_knowledge(/datum/eldritch_knowledge/cosmic_resonance)
	var/datum/eldritch_knowledge/base_cosmic/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/base_cosmic)
	var/datum/eldritch_knowledge/cosmic_resonance/recipe = heretic.get_knowledge(/datum/eldritch_knowledge/cosmic_resonance)
	TEST_ASSERT(recipe.on_finished_recipe(user, list(), get_turf(user)), "Создаётся астролябия для вспышки.")
	var/obj/item/heretic_path_relic/astrolabe/astrolabe = recipe.new_path_relic_ref.resolve()
	allocated += astrolabe
	user.put_in_hands(astrolabe)
	astrolabe.alignment_time = 0
	var/turf/origin = get_turf(user)
	var/turf/center = get_step(get_step(origin, EAST), EAST)
	knowledge.add_star(origin, user)
	knowledge.add_star(center, user)
	knowledge.add_star(get_step(get_step(center, EAST), EAST), user)
	var/obj/structure/heretic_star/selected = knowledge.stars[2]
	var/obj/structure/heretic_star/retained = knowledge.stars[3]
	retained.take_damage(10, BRUTE, MELEE)
	var/retained_integrity = retained.obj_integrity
	var/retained_expiry = retained.star_expires_at
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(center, NORTHEAST))
	var/mob/living/shielded = allocate(/mob/living/carbon/human, get_step(get_step(center, NORTH), NORTH))
	var/obj/barrier = allocate(/obj, get_step(center, NORTH))
	barrier.density = TRUE
	var/datum/antagonist/heretic/stranger = allocate_heretic(get_step(origin, NORTH))
	TEST_ASSERT(!astrolabe.flare(stranger.owner.current, selected), "Чужой разум не запускает вспышку астролябии.")
	var/turf/old_place = get_turf(selected)
	selected.forceMove(get_step(old_place, SOUTH))
	TEST_ASSERT(!astrolabe.can_flare(user, selected, old_place), "Сдвинутая после предупреждения звезда отменяет вспышку.")
	selected.forceMove(old_place)
	var/burn_before = victim.getFireLoss()
	var/shielded_before = shielded.getFireLoss()
	TEST_ASSERT(astrolabe.flare(user, selected), "Свою видимую звезду можно погасить вспышкой.")
	TEST_ASSERT(abs(victim.getFireLoss() - burn_before - 30) < DAMAGE_PRECISION, "Вспышка наносит тридцать ожогов возле выбранной звезды.")
	TEST_ASSERT_EQUAL(shielded.getFireLoss(), shielded_before, "Плотная преграда закрывает от вспышки.")
	TEST_ASSERT(QDELETED(selected), "Вспышка расходует выбранную звезду.")
	TEST_ASSERT_EQUAL(length(knowledge.stars), 2, "Другие две звезды сохраняются.")
	TEST_ASSERT_EQUAL(retained.obj_integrity, retained_integrity, "Сохранившаяся звезда не чинится.")
	TEST_ASSERT_EQUAL(retained.star_expires_at, retained_expiry, "Сохранившаяся звезда не обновляет срок жизни.")
	TEST_ASSERT(!astrolabe.realign(user), "Вспышка расходует общий откат с поворотом.")
	TEST_ASSERT(!astrolabe.flare(user, retained), "Откат не позволяет сразу взорвать другую звезду.")
	TEST_ASSERT(!knowledge.flare_star(user, selected, center, list(center)), "Удалённая звезда не запускает отложенную вспышку.")
	knowledge.on_body_lose(user)
	TEST_ASSERT_EQUAL(length(knowledge.stars), 0, "Потеря тела удаляет оставшиеся звёзды.")

/// Звёзды ограничены знанием пути; удаление вершины и смена тела убирают нити.
/datum/unit_test/heretic_cosmic_constellation/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	heretic.selected_path = PATH_COSMIC
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_cosmic)
	var/datum/eldritch_knowledge/base_cosmic/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/base_cosmic)
	var/turf/first = run_loc_floor_bottom_left
	var/turf/second = get_step(get_step(first, EAST), EAST)
	var/turf/third = get_step(get_step(second, NORTH), NORTH)
	TEST_ASSERT(knowledge.add_star(first, user), "Первая звезда должна зажечься на свободном полу.")
	user.forceMove(second)
	TEST_ASSERT(knowledge.add_star(second, user), "Вторая звезда соединяется с первой.")
	TEST_ASSERT(length(knowledge.threads) > 0 && length(knowledge.beams) > 0, "У двух звёзд есть игровая нить и видимый луч.")
	var/datum/beam/original_beam = knowledge.beams[1]
	var/list/original_threads = knowledge.threads.Copy()
	var/list/original_segments = original_beam.elements.Copy()
	knowledge.rebuild_threads()
	TEST_ASSERT_EQUAL(knowledge.beams[1], original_beam, "Неизменная связь сохраняет свой луч.")
	TEST_ASSERT_EQUAL(length(original_segments & original_beam.elements), length(original_segments), "Неизменный луч сохраняет все видимые сегменты.")
	TEST_ASSERT_EQUAL(length(original_threads & knowledge.threads), length(original_threads), "Неизменная связь сохраняет игровые нити.")
	user.forceMove(third)
	TEST_ASSERT(!knowledge.add_star(third, user), "Без третьей точки лимит равен двум.")
	heretic.gain_knowledge(/datum/eldritch_knowledge/cosmic_expansion)
	TEST_ASSERT(knowledge.add_star(third, user), "Изучение третьей точки расширяет созвездие.")
	TEST_ASSERT_EQUAL(length(knowledge.stars), 3, "Созвездие содержит три вершины.")
	TEST_ASSERT_EQUAL(length(knowledge.beams), 3, "Три вершины образуют замкнутый треугольник.")
	TEST_ASSERT(original_beam in knowledge.beams, "Новая вершина не пересоздаёт неизменную сторону созвездия.")
	var/obj/structure/heretic_star/removed = knowledge.stars[2]
	qdel(removed)
	TEST_ASSERT_EQUAL(length(knowledge.stars), 2, "Разбитая звезда удаляется из списка.")
	for(var/obj/effect/heretic_star_thread/thread as anything in knowledge.threads)
		TEST_ASSERT(thread.start != removed && thread.end != removed, "Нити не сохраняют ссылку на разрушенную вершину.")
	knowledge.on_body_lose(user)
	TEST_ASSERT_EQUAL(length(knowledge.stars), 0, "При смене тела не остаются звёзды.")
	TEST_ASSERT_EQUAL(length(knowledge.threads), 0, "При смене тела не остаются игровые нити.")
	TEST_ASSERT_EQUAL(length(knowledge.beams), 0, "При смене тела не остаются лучи.")

/// Стена между звёздами не пропускает нить, а занятая точка не принимает телепортацию.
/datum/unit_test/heretic_cosmic_obstacles/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	heretic.selected_path = PATH_COSMIC
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_cosmic)
	var/datum/eldritch_knowledge/base_cosmic/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/base_cosmic)
	var/turf/first = run_loc_floor_bottom_left
	var/turf/middle = get_step(first, EAST)
	var/turf/last = get_step(middle, EAST)
	knowledge.add_star(first, user)
	user.forceMove(last)
	middle = middle.ChangeTurf(/turf/closed/wall)
	TEST_ASSERT(knowledge.add_star(last, user), "Стена не мешает зажечь отдельную звезду.")
	TEST_ASSERT_EQUAL(length(knowledge.threads), 0, "Стена между вершинами не пропускает нить.")
	middle.ChangeTurf(/turf/open/floor/plasteel)
	knowledge.rebuild_threads()
	TEST_ASSERT(length(knowledge.threads), "После открытия пути звёзды соединяются.")
	var/obj/structure/heretic_star/destination = knowledge.stars[2]
	user.forceMove(first)
	var/obj/structure/closet/crate/crate = allocate(/obj/structure/closet/crate, last)
	TEST_ASSERT(!knowledge.travel(user, destination), "Нельзя переместиться внутрь плотного препятствия.")
	qdel(crate)
	var/datum/antagonist/heretic/stranger = allocate_heretic(get_step(first, NORTH))
	TEST_ASSERT(!knowledge.travel(stranger.owner.current, destination), "Чужое созвездие не принимает другого еретика.")
	TEST_ASSERT(knowledge.travel(user, destination), "Свободная звезда принимает своего владельца.")
	TEST_ASSERT_EQUAL(get_turf(user), last, "Путешествие заканчивается у выбранной звезды.")

/// Пересечение нитей не оглушает союзников и не складывает урон от пересекающихся линий.
/datum/unit_test/heretic_cosmic_thread_and_collapse/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	heretic.selected_path = PATH_COSMIC
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_cosmic)
	var/datum/eldritch_knowledge/base_cosmic/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/base_cosmic)
	knowledge.add_star(run_loc_floor_bottom_left, user)
	var/turf/second = get_step(get_step(run_loc_floor_bottom_left, EAST), EAST)
	user.forceMove(second)
	knowledge.add_star(second, user)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, EAST))
	TEST_ASSERT(!knowledge.cross_thread(user), "Нить пропускает своего владельца.")
	TEST_ASSERT(knowledge.cross_thread(victim), "Враждебное пересечение активирует нить.")
	var/stamina_after = victim.getStaminaLoss()
	TEST_ASSERT(stamina_after > 0, "Нить наносит урон выносливости.")
	TEST_ASSERT(!knowledge.cross_thread(victim), "Пересекающиеся нити не дают повторный эффект в тот же момент.")
	TEST_ASSERT_EQUAL(victim.getStaminaLoss(), stamina_after, "Короткая защита от повторного срабатывания сохраняет выносливость.")
	var/burn_before = victim.getFireLoss()
	TEST_ASSERT(knowledge.pulse(user, collapse = TRUE), "Подготовленное созвездие можно обрушить.")
	TEST_ASSERT(abs(victim.getFireLoss() - burn_before - 45) < DAMAGE_PRECISION, "Даже возле двух звёзд цель получает один удар схлопывания.")
	TEST_ASSERT_EQUAL(length(knowledge.stars), 0, "Схлопывание расходует все звёзды.")
	TEST_ASSERT_EQUAL(length(knowledge.threads), 0, "Схлопывание убирает ловушки.")

/// Притяжение замедляет цель без удара нитей по пути, но не защищает от них потом; снятие эффекта сохраняет чужое замедление.
/datum/unit_test/heretic_cosmic_tether/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_cosmic)
	var/datum/eldritch_knowledge/base_cosmic/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/base_cosmic)
	TEST_ASSERT(knowledge.add_star(get_turf(user), user), "Первая звезда должна создаться.")
	var/turf/middle = get_step(user, EAST)
	user.forceMove(get_step(middle, EAST))
	TEST_ASSERT(knowledge.add_star(get_turf(user), user), "Вторая звезда должна создаться.")
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(middle, NORTH))
	victim.add_movespeed_modifier(/datum/movespeed_modifier/heretic_moon_opening)
	var/original_slowdown = victim.cached_multiplicative_slowdown
	TEST_ASSERT(knowledge.pulse(user), "Пульс созвездия должен сработать.")
	TEST_ASSERT(victim.has_movespeed_modifier(/datum/movespeed_modifier/cosmic_tether), "Притяжение оставляет действующее замедление.")
	TEST_ASSERT(victim.cached_multiplicative_slowdown > original_slowdown, "Притяжение действительно увеличивает задержку движения.")
	TEST_ASSERT_EQUAL(victim.getStaminaLoss(), 25, "Перемещение пульсом через нить не складывает два удара.")
	var/datum/status_effect/cosmic_tether/tether = victim.has_status_effect(/datum/status_effect/cosmic_tether)
	tether.duration = world.time + 1 SECONDS
	knowledge.pulse(user)
	TEST_ASSERT_EQUAL(tether.duration, world.time + 3 SECONDS, "Новый пульс обновляет длительность притяжения до трёх секунд.")
	TEST_ASSERT_EQUAL(length(victim.has_status_effect_list(/datum/status_effect/cosmic_tether)), 1, "Пульс обновляет один эффект, не складывая замедления.")
	TEST_ASSERT(knowledge.cross_thread(victim), "Замедление пульсом не защищает от удара нити.")
	var/datum/component/anti_magic/protection = victim.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5)
	TEST_ASSERT(!knowledge.cross_thread(victim), "Сразу после удара нить не активируется повторно.")
	TEST_ASSERT_EQUAL(protection.charges, 5, "Неактивная нить не расходует заряды антимагии.")
	victim.remove_status_effect(/datum/status_effect/cosmic_tether)
	TEST_ASSERT(!victim.has_movespeed_modifier(/datum/movespeed_modifier/cosmic_tether), "После снятия притяжения его замедление исчезает.")
	TEST_ASSERT(victim.has_movespeed_modifier(/datum/movespeed_modifier/heretic_moon_opening), "Чужое замедление сохраняется.")
	victim.remove_status_effect(/datum/status_effect/cosmic_thread_cooldown)
	TEST_ASSERT(!knowledge.cross_thread(victim), "Антимагия защищает от следующего пересечения.")
	TEST_ASSERT_EQUAL(protection.charges, 5, "Пересечение постоянной нити не расходует заряды защиты.")
	qdel(protection)
	TEST_ASSERT(knowledge.cross_thread(victim), "После снятия защиты нить снова срабатывает.")
	TEST_ASSERT(victim.has_movespeed_modifier(/datum/movespeed_modifier/cosmic_tether), "Само пересечение тоже замедляет цель.")

/// Одно схлопывание расходует один заряд защиты даже рядом с двумя звёздами.
/datum/unit_test/heretic_cosmic_antimagic_overlap/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	heretic.selected_path = PATH_COSMIC
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_cosmic)
	var/datum/eldritch_knowledge/base_cosmic/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/base_cosmic)
	TEST_ASSERT(knowledge.add_star(run_loc_floor_bottom_left, user), "Первая звезда должна создаться.")
	var/turf/second = get_step(get_step(user, EAST), EAST)
	user.forceMove(second)
	TEST_ASSERT(knowledge.add_star(second, user), "Вторая звезда должна создаться.")
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, EAST))
	var/datum/component/anti_magic/protection = victim.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5)
	TEST_ASSERT(knowledge.pulse(user, collapse = TRUE), "Подготовленное созвездие схлопывается.")
	TEST_ASSERT_EQUAL(protection.charges, 4, "Одна цель тратит один заряд на всё схлопывание.")
	TEST_ASSERT_EQUAL(victim.getFireLoss(), 0, "Антимагия блокирует весь удар созвездия.")

/// Астролябия перемещает существующие звёзды и не восстанавливает их прочность.
/datum/unit_test/heretic_cosmic_astrolabe/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	heretic.selected_path = PATH_COSMIC
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_cosmic)
	heretic.gain_knowledge(/datum/eldritch_knowledge/cosmic_resonance)
	var/datum/eldritch_knowledge/base_cosmic/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/base_cosmic)
	var/datum/eldritch_knowledge/cosmic_resonance/recipe = heretic.get_knowledge(/datum/eldritch_knowledge/cosmic_resonance)
	var/turf/center = get_step(get_step(get_step(get_step(run_loc_floor_bottom_left, EAST), EAST), NORTH), NORTH)
	var/turf/east = get_step(get_step(center, EAST), EAST)
	var/turf/south = get_step(get_step(center, SOUTH), SOUTH)
	user.forceMove(center)
	TEST_ASSERT(knowledge.add_star(center, user), "Центральная звезда должна создаться.")
	user.forceMove(east)
	TEST_ASSERT(knowledge.add_star(east, user), "Вторая звезда должна создаться.")
	user.forceMove(center)
	var/obj/structure/heretic_star/rotated = knowledge.stars[2]
	var/original_expiry = rotated.star_expires_at
	rotated.obj_integrity = 25
	TEST_ASSERT(recipe.on_finished_recipe(user, list(), center), "Обряд должен создать астролябию.")
	var/obj/item/heretic_path_relic/astrolabe/astrolabe = recipe.new_path_relic_ref.resolve()
	allocated += astrolabe
	user.put_in_hands(astrolabe)
	astrolabe.alignment_time = 0
	var/obj/blocker = allocate(/obj, south)
	blocker.density = TRUE
	TEST_ASSERT(!astrolabe.realign(user), "Препятствие на месте звезды запрещает весь поворот.")
	TEST_ASSERT_EQUAL(get_turf(rotated), east, "Неудачный поворот оставляет исходное созвездие целым.")
	qdel(blocker)
	TEST_ASSERT(astrolabe.realign(user), "Свободное пространство позволяет повернуть созвездие.")
	TEST_ASSERT_EQUAL(get_turf(rotated), south, "Восточная звезда поворачивается на юг вокруг центральной.")
	TEST_ASSERT_EQUAL(rotated.obj_integrity, 25, "Поворот не лечит повреждённую звезду.")
	TEST_ASSERT_EQUAL(rotated.star_expires_at, original_expiry, "Поворот не продлевает жизнь звезды.")
	TEST_ASSERT_EQUAL(length(knowledge.stars), 2, "Астролябия не создаёт новые звёзды.")
	TEST_ASSERT(length(knowledge.threads) > 0, "После поворота игровые нити перестраиваются.")
	TEST_ASSERT(!astrolabe.realign(user), "Повторный поворот ограничен перезарядкой.")

/// Предупреждение не проходит через преграды, а изменение звёзд отменяет старый замысел.
/datum/unit_test/heretic_cosmic_telegraph_snapshot/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	heretic.selected_path = PATH_COSMIC
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_cosmic)
	var/datum/eldritch_knowledge/base_cosmic/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/base_cosmic)
	var/turf/center = get_step(get_step(run_loc_floor_bottom_left, EAST), NORTH)
	user.forceMove(center)
	knowledge.add_star(center, user)
	var/turf/blocked = get_step(center, EAST)
	var/obj/blocker = allocate(/obj, blocked)
	blocker.density = TRUE
	var/list/warned = knowledge.collapse_turfs(user)
	TEST_ASSERT(center in warned, "Клетка звезды входит в предупреждённую область.")
	TEST_ASSERT(!(blocked in warned), "Плотная преграда не подсвечивается как достижимая для схлопывания.")
	var/mob/living/victim = allocate(/mob/living/carbon/human, blocked)
	qdel(blocker)
	TEST_ASSERT(knowledge.pulse(user, collapse = TRUE, telegraphed_turfs = warned), "После открытия прохода схлопывание всё ещё может завершиться.")
	TEST_ASSERT_EQUAL(victim.getFireLoss(), 0, "Открытый во время подготовки проход не добавляет непредупреждённые клетки к взрыву.")
	knowledge.add_star(center, user)
	var/list/snapshot = list()
	var/obj/structure/heretic_star/star = knowledge.stars[1]
	snapshot[star] = get_turf(star)
	TEST_ASSERT(knowledge.stars_unchanged(snapshot), "Неизменное созвездие сохраняет подготовку.")
	star.forceMove(get_step(center, NORTH))
	TEST_ASSERT(!knowledge.stars_unchanged(snapshot), "Перемещение звезды запрещает удар за пределами старого предупреждения.")
	qdel(star)
	TEST_ASSERT(!knowledge.stars_unchanged(snapshot), "Разрушение звезды прерывает подготовленное схлопывание.")

/// Начальное действие создаёт рабочую пару и переносит её без ручной очистки лимита.
/datum/unit_test/heretic_cosmic_manifest_pair/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	heretic.selected_path = PATH_COSMIC
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_cosmic)
	var/datum/eldritch_knowledge/base_cosmic/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/base_cosmic)
	var/turf/destination = get_step(get_step(get_step(user, EAST), EAST), EAST)
	TEST_ASSERT(knowledge.manifest(destination, user), "Звёзды можно поставить дистанционно одним действием.")
	TEST_ASSERT_EQUAL(length(knowledge.stars), 2, "Первое применение сразу создаёт две звезды.")
	TEST_ASSERT(length(knowledge.threads), "Пара сразу соединена действующей нитью.")
	var/obj/structure/heretic_star/oldest = knowledge.stars[1]
	var/obj/structure/heretic_star/remaining = knowledge.stars[2]
	TEST_ASSERT_EQUAL(get_turf(oldest), get_turf(user), "Первая звезда возникает под владельцем.")
	TEST_ASSERT_EQUAL(get_turf(remaining), destination, "Вторая звезда возникает в выбранном месте.")
	TEST_ASSERT(knowledge.manifest(get_step(destination, NORTH), user), "Полный лимит не запрещает новую постановку.")
	TEST_ASSERT(QDELETED(oldest), "Новая звезда заменяет старейшую.")
	TEST_ASSERT(remaining in knowledge.stars, "Более новая звезда сохраняется.")
	TEST_ASSERT_EQUAL(length(knowledge.stars), 2, "Замена соблюдает предел созвездия.")
	var/turf/blocked = get_step(user, NORTH)
	var/obj/barrier = allocate(/obj, blocked)
	barrier.density = TRUE
	TEST_ASSERT(!knowledge.manifest(blocked, user), "Плотное препятствие нельзя выбрать для новой звезды.")
	TEST_ASSERT_EQUAL(length(knowledge.stars), 2, "Неудачная постановка не уничтожает прежние звёзды.")

/// Зажигание принимает щелчки по существам, предметам и собственной звезде.
/datum/unit_test/heretic_cosmic_manifest_click_targets/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	heretic.selected_path = PATH_COSMIC
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_cosmic)
	var/datum/eldritch_knowledge/base_cosmic/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/base_cosmic)
	var/obj/effect/proc_holder/spell/self/cosmic/manifest/spell = knowledge.manifest_spell
	var/turf/destination = get_step(get_step(user, EAST), EAST)
	var/obj/item/pen/pen = allocate(/obj/item/pen, destination)
	TEST_ASSERT(spell.intercept_check(user, pen, TRUE), "Предмет на свободном полу принимается прицелом.")
	spell.cast(list(pen), user)
	TEST_ASSERT_EQUAL(length(knowledge.stars), 2, "Щелчок по предмету создаёт рабочую пару.")
	var/obj/structure/heretic_star/star = knowledge.stars[2]
	TEST_ASSERT_EQUAL(get_turf(star), destination, "Заклинание использует пол под предметом.")
	var/obj/blocker = allocate(/obj, destination)
	blocker.density = TRUE
	TEST_ASSERT(spell.intercept_check(user, star, TRUE), "Свою звезду можно погасить и после появления преграды на её клетке.")
	spell.cast(list(star), user)
	TEST_ASSERT(QDELETED(star), "Щелчок по звезде действительно гасит её.")
	knowledge.clear_stars()
	qdel(blocker)
	var/mob/living/victim = allocate(/mob/living/carbon/human, destination)
	TEST_ASSERT(spell.intercept_check(user, victim, TRUE), "Существо на свободном полу принимается прицелом.")
	spell.cast(list(victim), user)
	TEST_ASSERT_EQUAL(length(knowledge.stars), 2, "Щелчок по существу создаёт рабочую пару.")
	star = knowledge.stars[2]
	TEST_ASSERT_EQUAL(get_turf(star), destination, "Заклинание использует пол под существом.")
	knowledge.clear_stars()
	TEST_ASSERT(spell.intercept_check(user, user, TRUE), "Можно выбрать собственную клетку щелчком по себе.")
	spell.cast(list(user), user)
	TEST_ASSERT_EQUAL(length(knowledge.stars), 1, "На собственной клетке возникает одна звезда.")

/// Преграды не отменяют постановку на видимый свободный пол и не пропускают нити.
/datum/unit_test/heretic_cosmic_manifest_obstacles/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	heretic.selected_path = PATH_COSMIC
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_cosmic)
	var/datum/eldritch_knowledge/base_cosmic/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/base_cosmic)
	var/obj/effect/proc_holder/spell/self/cosmic/manifest/spell = knowledge.manifest_spell
	var/turf/destination = get_step(get_step(get_step(user, EAST), EAST), EAST)
	var/obj/blocker = allocate(/obj, get_turf(user))
	blocker.density = TRUE
	TEST_ASSERT(spell.intercept_check(user, destination, TRUE), "Преграда под владельцем не блокирует выбор свободной клетки.")
	spell.cast(list(destination), user)
	TEST_ASSERT_EQUAL(length(knowledge.stars), 1, "Без места под владельцем создаётся только выбранная звезда.")
	var/obj/structure/heretic_star/star = knowledge.stars[1]
	TEST_ASSERT_EQUAL(get_turf(star), destination, "Выбранная точка не смещается из-за преграды.")
	TEST_ASSERT_EQUAL(length(knowledge.threads), 0, "Одиночная звезда не создаёт нить через преграду.")
	knowledge.clear_stars()
	blocker.forceMove(get_step(user, EAST))
	TEST_ASSERT(spell.intercept_check(user, destination, TRUE), "Видимый пол за непроходимой прозрачной преградой принимается прицелом.")
	spell.cast(list(destination), user)
	TEST_ASSERT_EQUAL(length(knowledge.stars), 1, "За преградой создаётся самостоятельная звезда.")
	TEST_ASSERT_EQUAL(length(knowledge.threads), 0, "Нить не проходит через плотный объект.")
	star = knowledge.stars[1]
	TEST_ASSERT(!spell.intercept_check(user, blocker, TRUE), "Занятая преградой клетка не подходит для новой звезды.")
	spell.charge_counter = 0
	spell.cast(list(blocker), user)
	TEST_ASSERT_EQUAL(spell.charge_counter, spell.charge_max, "Неудачная постановка возвращает заряд.")
	TEST_ASSERT(star in knowledge.stars, "Неудачная постановка сохраняет прежнее созвездие.")
	blocker.forceMove(get_turf(user))
	var/turf/next_destination = get_step(destination, NORTH)
	TEST_ASSERT(knowledge.manifest(next_destination, user), "Существующую звезду можно дополнить при занятой клетке владельца.")
	TEST_ASSERT_EQUAL(length(knowledge.stars), 2, "Вторая постановка достраивает пару.")
	TEST_ASSERT(length(knowledge.threads), "Свободный отрезок между звёздами получает нить.")

/// Во время предупреждения схлопывания можно двигаться, сохраняя проверенную область удара.
/datum/unit_test/heretic_cosmic_mobile_collapse/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	heretic.selected_path = PATH_COSMIC
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_cosmic)
	var/datum/eldritch_knowledge/base_cosmic/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/base_cosmic)
	var/turf/destination = get_step(get_step(get_step(user, EAST), EAST), EAST)
	TEST_ASSERT(knowledge.manifest(destination, user), "Пара должна создаться до схлопывания.")
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(destination, NORTH))
	var/obj/effect/proc_holder/spell/self/cosmic/collapse/spell = allocate(/obj/effect/proc_holder/spell/self/cosmic/collapse)
	spell.cast(list(user), user)
	TEST_ASSERT(spell.collapse_pending, "Заклинание оставляет отложенный удар после предупреждения.")
	TEST_ASSERT_EQUAL(victim.getFireLoss(), 0, "Предупреждение не наносит мгновенный урон.")
	user.forceMove(get_step(user, NORTH))
	var/list/budget = new_wait_budget(3 SECONDS, "схлопывание должно завершиться после предупреждения")
	while(spell.collapse_pending)
		if(!wait_budget_tick(budget))
			break
	TEST_ASSERT(abs(victim.getFireLoss() - 45) < 0.001, "Перемещение владельца не отменяет схлопывание предупреждённой области.")
	TEST_ASSERT_EQUAL(length(knowledge.stars), 0, "Завершённое схлопывание расходует созвездие.")

/// Преграда до последней звезды не гасит созвездие: новая звезда тянет нить к более старой или встаёт отдельно.
/datum/unit_test/heretic_cosmic_blocked_link/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	heretic.selected_path = PATH_COSMIC
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_cosmic)
	heretic.gain_knowledge(/datum/eldritch_knowledge/cosmic_expansion)
	var/datum/eldritch_knowledge/base_cosmic/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/base_cosmic)
	var/turf/origin = run_loc_floor_bottom_left
	TEST_ASSERT(knowledge.manifest(locate(origin.x + 2, origin.y, origin.z), user), "Первая пара ставится одним применением.")
	var/obj/structure/heretic_star/first = knowledge.stars[1]
	var/obj/structure/heretic_star/second = knowledge.stars[2]
	var/obj/barrier = allocate(/obj, locate(origin.x + 1, origin.y + 1, origin.z))
	barrier.density = TRUE
	TEST_ASSERT(knowledge.manifest(locate(origin.x, origin.y + 2, origin.z), user), "Звезду можно поставить за преградой от последней.")
	TEST_ASSERT(!QDELETED(first) && !QDELETED(second), "Преграда до последней звезды не гасит созвездие.")
	TEST_ASSERT_EQUAL(length(knowledge.stars), 3, "Новая звезда добавляется к созвездию.")
	var/turf/link_turf = locate(origin.x, origin.y + 1, origin.z)
	TEST_ASSERT(locate(/obj/effect/heretic_star_thread) in link_turf, "Новая звезда соединяется с более старой по свободной прямой.")
	TEST_ASSERT(!(locate(/obj/effect/heretic_star_thread) in get_turf(barrier)), "Нить не проходит через преграду.")
	var/obj/structure/heretic_star/third = knowledge.stars[3]
	for(var/list/offset as anything in list(list(3, 3), list(3, 4), list(4, 3)))
		var/obj/wall_piece = allocate(/obj, locate(origin.x + offset[1], origin.y + offset[2], origin.z))
		wall_piece.density = TRUE
	TEST_ASSERT(knowledge.manifest(locate(origin.x + 4, origin.y + 4, origin.z), user), "Звезду без свободной прямой к остальным можно поставить отдельно.")
	TEST_ASSERT(QDELETED(first), "Полное созвездие по-прежнему вытесняет старейшую звезду.")
	TEST_ASSERT(!QDELETED(second) && !QDELETED(third), "Отдельная звезда не гасит остальные.")
	TEST_ASSERT_EQUAL(length(knowledge.stars), 3, "Отдельная звезда занимает место в созвездии.")

/// Пульс без своих звёзд в семи клетках не срабатывает и не уходит на перезарядку.
/datum/unit_test/heretic_cosmic_pulse_out_of_range/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	heretic.selected_path = PATH_COSMIC
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_cosmic)
	var/datum/eldritch_knowledge/base_cosmic/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/base_cosmic)
	var/turf/origin = get_turf(user)
	TEST_ASSERT(knowledge.add_star(origin, user), "Звезда создана.")
	var/far_x = origin.x + 12 <= world.maxx ? origin.x + 12 : origin.x - 12
	user.forceMove(locate(far_x, origin.y, origin.z))
	var/obj/effect/proc_holder/spell/self/cosmic/pulse/spell = allocate(/obj/effect/proc_holder/spell/self/cosmic/pulse)
	spell.charge_counter = 0
	spell.cast(list(user), user)
	TEST_ASSERT_EQUAL(spell.charge_counter, spell.charge_max, "Пульс без звёзд рядом возвращает перезарядку.")
	TEST_ASSERT(spell.heretic_failure_reason, "Владелец узнаёт, почему пульс не сработал.")
	user.forceMove(origin)
	spell.charge_counter = 0
	spell.cast(list(user), user)
	TEST_ASSERT_EQUAL(spell.charge_counter, 0, "Звезда рядом позволяет пульсу сработать.")

/// Сорванное схлопывание сообщает причину, возвращает перезарядку и сохраняет звёзды.
/datum/unit_test/heretic_cosmic_collapse_cancelled/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	heretic.selected_path = PATH_COSMIC
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_cosmic)
	var/datum/eldritch_knowledge/base_cosmic/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/base_cosmic)
	var/turf/destination = get_step(get_step(get_step(user, EAST), EAST), EAST)
	TEST_ASSERT(knowledge.manifest(destination, user), "Пара создана.")
	var/obj/effect/proc_holder/spell/self/cosmic/collapse/spell = allocate(/obj/effect/proc_holder/spell/self/cosmic/collapse)
	spell.charge_counter = 0
	spell.cast(list(user), user)
	TEST_ASSERT(spell.collapse_pending, "Схлопывание ждёт конца предупреждения.")
	qdel(knowledge.stars[2])
	var/list/budget = new_wait_budget(3 SECONDS, "сорванное схлопывание должно завершиться")
	while(spell.collapse_pending)
		if(!wait_budget_tick(budget))
			break
	TEST_ASSERT_EQUAL(spell.charge_counter, spell.charge_max, "Разбитая звезда возвращает перезарядку схлопывания.")
	TEST_ASSERT(spell.heretic_failure_reason, "Владелец узнаёт о срыве схлопывания.")
	TEST_ASSERT_EQUAL(length(knowledge.stars), 1, "Сорванное схлопывание не расходует оставшуюся звезду.")
	TEST_ASSERT(knowledge.manifest(destination, user), "Созвездие можно восстановить.")
	spell.heretic_failure_reason = null
	spell.charge_counter = 0
	spell.cast(list(user), user)
	user.Stun(5 SECONDS)
	budget = new_wait_budget(3 SECONDS, "схлопывание под оглушением должно завершиться")
	while(spell.collapse_pending)
		if(!wait_budget_tick(budget))
			break
	TEST_ASSERT_EQUAL(spell.charge_counter, spell.charge_max, "Оглушение во время предупреждения возвращает перезарядку.")
	TEST_ASSERT(spell.heretic_failure_reason, "Оглушённый владелец узнаёт о срыве схлопывания.")
	TEST_ASSERT_EQUAL(length(knowledge.stars), 2, "Сорванное схлопывание сохраняет созвездие.")

/// Замедление хваткой не защищает от нити: защиту даёт только удар самой нити.
/datum/unit_test/heretic_cosmic_thread_after_grasp/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	heretic.selected_path = PATH_COSMIC
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_cosmic)
	heretic.gain_knowledge(/datum/eldritch_knowledge/cosmic_grasp)
	var/datum/eldritch_knowledge/base_cosmic/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/base_cosmic)
	var/datum/eldritch_knowledge/cosmic_grasp/grasp = heretic.get_knowledge(/datum/eldritch_knowledge/cosmic_grasp)
	var/turf/origin = run_loc_floor_bottom_left
	TEST_ASSERT(knowledge.add_star(origin, user), "Первая звезда создана.")
	var/turf/second = locate(origin.x + 2, origin.y, origin.z)
	user.forceMove(second)
	TEST_ASSERT(knowledge.add_star(second, user), "Вторая звезда создана.")
	user.forceMove(locate(origin.x + 4, origin.y + 4, origin.z))
	var/mob/living/victim = allocate(/mob/living/carbon/human, locate(origin.x + 1, origin.y + 2, origin.z))
	TEST_ASSERT(grasp.on_mansus_grasp(victim, user, TRUE), "Хватка действует на врага.")
	TEST_ASSERT(victim.has_status_effect(/datum/status_effect/cosmic_tether), "Хватка замедляет врага.")
	var/turf/above_thread = locate(origin.x + 1, origin.y + 1, origin.z)
	victim.forceMove(above_thread)
	var/stamina_before = victim.getStaminaLoss()
	TEST_ASSERT(victim.Move(get_step(above_thread, SOUTH), SOUTH), "Враг шагает на нить.")
	TEST_ASSERT_EQUAL(victim.getStaminaLoss(), stamina_before + 25, "Замедленный хваткой враг получает удар нити.")
	TEST_ASSERT(!knowledge.cross_thread(victim), "Сразу после удара нить не ранит повторно.")

/// Враг, под которым появилась нить, получает удар без пересечения.
/datum/unit_test/heretic_cosmic_thread_standing/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	heretic.selected_path = PATH_COSMIC
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_cosmic)
	var/datum/eldritch_knowledge/base_cosmic/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/base_cosmic)
	var/turf/origin = run_loc_floor_bottom_left
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(origin, EAST))
	TEST_ASSERT(knowledge.add_star(origin, user), "Первая звезда создана.")
	var/turf/second = locate(origin.x + 2, origin.y, origin.z)
	user.forceMove(second)
	TEST_ASSERT(knowledge.add_star(second, user), "Вторая звезда создана.")
	var/turf/victim_turf = get_turf(victim)
	TEST_ASSERT(locate(/obj/effect/heretic_star_thread) in victim_turf, "Нить проходит под врагом.")
	TEST_ASSERT_EQUAL(victim.getStaminaLoss(), 0, "Появление нити не считается пересечением.")
	var/list/budget = new_wait_budget(3 SECONDS, "нить должна задеть врага, стоящего на ней")
	while(!victim.getStaminaLoss())
		if(!wait_budget_tick(budget))
			break
	TEST_ASSERT(victim.getStaminaLoss() > 0, "Нить задевает врага, который стоит на ней.")

/// Вознесённый Космос не нуждается в воздухе и не боится вакуума и холода.
/datum/unit_test/heretic_cosmic_ascension_space/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/final_eldritch/cosmic_final/final_knowledge = allocate(/datum/eldritch_knowledge/final_eldritch/cosmic_final)
	final_knowledge.finished = TRUE
	final_knowledge.on_body_gain(user)
	for(var/trait in list(TRAIT_NOBREATH, TRAIT_RESISTLOWPRESSURE, TRAIT_RESISTHIGHPRESSURE, TRAIT_RESISTCOLD, TRAIT_SPACEWALK))
		TEST_ASSERT(HAS_TRAIT(user, trait), "Вознесение Космоса даёт черту [trait].")
	final_knowledge.on_body_lose(user)
	for(var/trait in list(TRAIT_NOBREATH, TRAIT_RESISTLOWPRESSURE, TRAIT_RESISTHIGHPRESSURE, TRAIT_RESISTCOLD, TRAIT_SPACEWALK))
		TEST_ASSERT(!HAS_TRAIT(user, trait), "Потеря тела снимает черту [trait].")

/// Смерть снимает расширенное созвездие и усиленные нити, оживление возвращает их.
/datum/unit_test/heretic_cosmic_ascension_death_recovery/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_COSMIC
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_cosmic)
	heretic.gain_knowledge(/datum/eldritch_knowledge/final_eldritch/cosmic_final)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_cosmic/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/base_cosmic)
	var/datum/eldritch_knowledge/final_eldritch/cosmic_final/finale = heretic.get_knowledge(/datum/eldritch_knowledge/final_eldritch/cosmic_final)
	heretic.ascended = TRUE
	finale.finished = TRUE
	finale.on_body_gain(user)
	TEST_ASSERT_EQUAL(knowledge.star_limit(), 5, "Вознесение расширяет созвездие до пяти звёзд.")
	user.death()
	heretic.handle_death(user)
	TEST_ASSERT_EQUAL(knowledge.star_limit(), 2, "Смерть возвращает обычный предел созвездия.")
	user.revive(full_heal = TRUE)
	finale.on_life(user)
	TEST_ASSERT_EQUAL(knowledge.star_limit(), 5, "Оживление возвращает пять звёзд.")
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	TEST_ASSERT(knowledge.cross_thread(victim), "Нить задевает врага оживлённого вознесённого.")
	TEST_ASSERT(abs(victim.getFireLoss() - 20) <= DAMAGE_PRECISION, "Нить вознесённого снова жжёт на 20.")

/datum/unit_test/proc/ascend_cosmic_fixture(turf/location)
	var/datum/antagonist/heretic/heretic = allocate_heretic(location)
	var/mob/living/carbon/human/user = heretic.owner.current
	heretic.selected_path = PATH_COSMIC
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_cosmic)
	heretic.gain_knowledge(/datum/eldritch_knowledge/final_eldritch/cosmic_final)
	var/datum/eldritch_knowledge/final_eldritch/cosmic_final/finale = heretic.get_knowledge(/datum/eldritch_knowledge/final_eldritch/cosmic_final)
	heretic.ascended = TRUE
	finale.finished = TRUE
	finale.on_body_gain(user)
	var/obj/effect/proc_holder/spell/self/cosmic/stargazer/spell = locate() in finale.ascension_spell_instances
	return list("user" = user, "heretic" = heretic, "finale" = finale, "cosmic" = heretic.get_knowledge(/datum/eldritch_knowledge/base_cosmic), "spell" = spell)

/datum/unit_test/proc/summon_test_stargazer(list/fixture)
	var/mob/living/carbon/human/user = fixture["user"]
	var/datum/eldritch_knowledge/final_eldritch/cosmic_final/finale = fixture["finale"]
	var/obj/effect/proc_holder/spell/self/cosmic/stargazer/spell = fixture["spell"]
	spell.cast(list(user), user)
	var/mob/living/simple_animal/heretic_stargazer/gazer = finale.stargazer
	if(gazer)
		allocated += gazer
		STOP_PROCESSING(SSprocessing, gazer)
	return gazer

/// Звездочёт призывается один, второй призыв отказывает, пока первый жив.
/datum/unit_test/heretic_cosmic_stargazer_summon/Run()
	var/list/fixture = ascend_cosmic_fixture()
	var/mob/living/carbon/human/user = fixture["user"]
	var/datum/eldritch_knowledge/final_eldritch/cosmic_final/finale = fixture["finale"]
	var/obj/effect/proc_holder/spell/self/cosmic/stargazer/spell = fixture["spell"]
	TEST_ASSERT_NOTNULL(spell, "Вознесение Космоса выдаёт Звездочёта.")
	TEST_ASSERT_EQUAL(length(finale.ascension_spells), 1, "Звездочёт - единственный ульт Космоса.")
	TEST_ASSERT(spell.can_cast(user, FALSE, TRUE), "Призыв доступен сразу после вознесения.")
	spell.Trigger(user)
	var/mob/living/simple_animal/heretic_stargazer/gazer = finale.stargazer
	TEST_ASSERT_NOTNULL(gazer, "Призыв создаёт Звездочёта.")
	allocated += gazer
	STOP_PROCESSING(SSprocessing, gazer)
	TEST_ASSERT_EQUAL(spell.charge_counter, spell.charge_max, "Полный цикл применения не запускает перезарядку, пока Звездочёт жив.")
	TEST_ASSERT(!spell.recharging, "Перезарядка не тикает, пока Звездочёт жив.")
	TEST_ASSERT(get_dist(gazer, user) <= 1, "Звездочёт появляется рядом с героем.")
	TEST_ASSERT_EQUAL(gazer.maxHealth, HERETIC_STARGAZER_HEALTH, "У Звездочёта 400 здоровья.")
	TEST_ASSERT_EQUAL(gazer.health, HERETIC_STARGAZER_HEALTH, "Звездочёт появляется целым.")
	TEST_ASSERT(IS_HERETIC_MONSTER(gazer), "Звездочёт числится слугой Мансуса.")
	TEST_ASSERT("heretics" in gazer.faction, "Звездочёт делит фракцию с еретиком и его слугами.")
	TEST_ASSERT(HAS_TRAIT(gazer, TRAIT_SPACEWALK), "Звездочёта не сносит в космосе.")
	TEST_ASSERT(!spell.can_cast(user, FALSE, TRUE), "Пока Звездочёт жив, второй призыв недоступен.")
	spell.cast(list(user), user)
	var/count = 0
	for(var/mob/living/simple_animal/heretic_stargazer/candidate in range(3, user))
		count++
	TEST_ASSERT_EQUAL(count, 1, "Повторный призыв не создаёт второго Звездочёта.")
	TEST_ASSERT_EQUAL(finale.stargazer, gazer, "Прежний Звездочёт остаётся на месте.")

/// Луч бьёт ближайшего врага на открытой линии на 20 ожогов и проходит сквозь союзников Мансуса.
/datum/unit_test/heretic_cosmic_stargazer_beam/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/list/fixture = ascend_cosmic_fixture(get_step(origin, WEST))
	var/mob/living/carbon/human/user = fixture["user"]
	var/mob/living/simple_animal/heretic_stargazer/gazer = summon_test_stargazer(fixture)
	TEST_ASSERT_NOTNULL(gazer, "Призыв создаёт Звездочёта.")
	gazer.forceMove(origin)
	var/turf/east = origin
	for(var/step in 1 to 4)
		east = get_step(east, EAST)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, east)
	var/mob/living/carbon/human/servant_body = allocate(/mob/living/carbon/human, get_step(get_step(origin, EAST), EAST))
	var/datum/mind/servant_mind = allocate_mind()
	servant_mind.current = servant_body
	servant_body.mind = servant_mind
	var/datum/antagonist/heretic_monster/servant = allocate(/datum/antagonist/heretic_monster)
	servant.owner = servant_mind
	servant.silent = TRUE
	servant_mind.antag_datums = list(servant)
	var/turf/north = get_step(get_step(get_step(origin, NORTH), NORTH), NORTH)
	var/mob/living/carbon/human/hidden = allocate(/mob/living/carbon/human, north)
	var/obj/barrier = allocate(/obj, get_step(get_step(origin, NORTH), NORTH))
	barrier.density = TRUE
	TEST_ASSERT_EQUAL(gazer.pick_target(user), victim, "Звездочёт выбирает ближайшего врага на открытой линии, а не героя, слугу или врага за преградой.")
	TEST_ASSERT(gazer.try_fire(user), "Звездочёт стреляет по врагу в семи клетках.")
	var/list/budget = new_wait_budget(2 SECONDS, "луч Звездочёта должен долететь до врага")
	while(victim.getFireLoss() < HERETIC_STARGAZER_BEAM_DAMAGE)
		if(!wait_budget_tick(budget))
			break
	TEST_ASSERT(abs(victim.getFireLoss() - HERETIC_STARGAZER_BEAM_DAMAGE) < DAMAGE_PRECISION, "Луч наносит врагу 20 ожогов.")
	TEST_ASSERT_EQUAL(servant_body.getFireLoss(), 0, "Луч проходит сквозь слугу Мансуса на линии.")
	TEST_ASSERT_EQUAL(user.getFireLoss(), 0, "Луч не задевает героя.")
	TEST_ASSERT_EQUAL(hidden.getFireLoss(), 0, "Враг за преградой не получает урона.")
	TEST_ASSERT(!gazer.try_fire(user), "Следующий луч готов только через 3 секунды.")
	qdel(victim)
	qdel(hidden)
	TEST_ASSERT_NULL(gazer.pick_target(user), "Рядом одни союзники: Звездочёту некого бить.")

/// Гибель Звездочёта оставляет угасающее тело и запускает перезарядку призыва в 3 минуты.
/datum/unit_test/heretic_cosmic_stargazer_death_cooldown/Run()
	var/list/fixture = ascend_cosmic_fixture()
	var/mob/living/carbon/human/user = fixture["user"]
	var/datum/eldritch_knowledge/final_eldritch/cosmic_final/finale = fixture["finale"]
	var/obj/effect/proc_holder/spell/self/cosmic/stargazer/spell = fixture["spell"]
	var/mob/living/simple_animal/heretic_stargazer/gazer = summon_test_stargazer(fixture)
	TEST_ASSERT_NOTNULL(gazer, "Призыв создаёт Звездочёта.")
	TEST_ASSERT_EQUAL(spell.charge_max, HERETIC_STARGAZER_COOLDOWN, "Перезарядка призыва - 3 минуты.")
	TEST_ASSERT_EQUAL(spell.charge_counter, spell.charge_max, "Пока Звездочёт жив, перезарядка не тикает.")
	gazer.adjustBruteLoss(HERETIC_STARGAZER_HEALTH * 2)
	TEST_ASSERT_EQUAL(gazer.stat, DEAD, "Звездочёт гибнет от урона.")
	TEST_ASSERT_NULL(finale.stargazer, "Погибший Звездочёт больше не считается живым.")
	TEST_ASSERT(!QDELETED(gazer), "Тело Звездочёта сначала угасает на месте.")
	TEST_ASSERT_EQUAL(gazer.icon_state, "stargazer_dead", "Погибший Звездочёт показывает спрайт смерти.")
	TEST_ASSERT(spell.charge_max - spell.charge_counter >= HERETIC_STARGAZER_COOLDOWN - 1 SECONDS, "Гибель запускает перезарядку в 3 минуты.")
	TEST_ASSERT(!spell.can_cast(user, FALSE, TRUE), "Во время перезарядки призвать нового нельзя.")
	var/list/budget = new_wait_budget(3 SECONDS, "тело Звездочёта должно угаснуть")
	while(!QDELETED(gazer))
		if(!wait_budget_tick(budget))
			break
	TEST_ASSERT(QDELETED(gazer), "Угасшее тело исчезает.")
	spell.charge_counter = spell.charge_max
	TEST_ASSERT(spell.can_cast(user, FALSE, TRUE), "После перезарядки можно призвать нового.")

/// Погибший или рассыпавшийся Звездочёт не оставляет слуги-призрака в списке антагонистов.
/datum/unit_test/heretic_cosmic_stargazer_no_phantom_servant/Run()
	var/list/fixture = ascend_cosmic_fixture()
	var/obj/effect/proc_holder/spell/self/cosmic/stargazer/spell = fixture["spell"]
	var/mob/living/simple_animal/heretic_stargazer/gazer = summon_test_stargazer(fixture)
	TEST_ASSERT_NOTNULL(gazer, "Призыв создаёт Звездочёта.")
	var/datum/mind/gazer_mind = gazer.mind
	var/datum/antagonist/heretic_monster/servant = gazer_mind?.has_antag_datum(/datum/antagonist/heretic_monster)
	TEST_ASSERT_NOTNULL(servant, "Звездочёт числится слугой.")
	gazer.adjustBruteLoss(HERETIC_STARGAZER_HEALTH * 2)
	TEST_ASSERT(!(servant in GLOB.antagonists), "Погибший Звездочёт не остаётся слугой в итогах раунда.")
	for(var/datum/objective/objective in GLOB.objectives)
		TEST_ASSERT(objective.owner != gazer_mind, "Цель погибшего Звездочёта не остаётся в общем списке целей.")
	spell.charge_counter = spell.charge_max
	gazer = summon_test_stargazer(fixture)
	TEST_ASSERT_NOTNULL(gazer, "Призывается новый Звездочёт.")
	gazer_mind = gazer.mind
	servant = gazer_mind?.has_antag_datum(/datum/antagonist/heretic_monster)
	gazer.dissolve()
	TEST_ASSERT(!(servant in GLOB.antagonists), "Рассыпавшийся Звездочёт не остаётся слугой в итогах раунда.")
	TEST_ASSERT(!(gazer_mind in SSticker.minds), "Разум без игрока не остаётся от рассыпавшегося Звездочёта.")
	for(var/datum/objective/objective in GLOB.objectives)
		TEST_ASSERT(objective.owner != gazer_mind, "Цель рассыпавшегося Звездочёта не держит удалённый разум.")

/// Смерть героя и потеря тела уносят Звездочёта и запускают перезарядку призыва.
/datum/unit_test/heretic_cosmic_stargazer_removed_with_body/Run()
	var/list/fixture = ascend_cosmic_fixture()
	var/mob/living/carbon/human/user = fixture["user"]
	var/datum/antagonist/heretic/heretic = fixture["heretic"]
	var/datum/eldritch_knowledge/final_eldritch/cosmic_final/finale = fixture["finale"]
	var/mob/living/simple_animal/heretic_stargazer/gazer = summon_test_stargazer(fixture)
	TEST_ASSERT_NOTNULL(gazer, "Призыв создаёт Звездочёта.")
	user.death()
	heretic.handle_death(user)
	TEST_ASSERT(QDELETED(gazer), "Смерть героя уносит Звездочёта.")
	TEST_ASSERT_NULL(finale.stargazer, "После смерти героя Звездочёта нет.")
	TEST_ASSERT(finale.ascension_spell_ready_at[/obj/effect/proc_holder/spell/self/cosmic/stargazer] >= world.time + HERETIC_STARGAZER_COOLDOWN - 1 SECONDS, "Смерть героя запускает перезарядку призыва.")
	user.revive(full_heal = TRUE)
	finale.on_life(user)
	var/obj/effect/proc_holder/spell/self/cosmic/stargazer/spell = locate() in finale.ascension_spell_instances
	TEST_ASSERT_NOTNULL(spell, "Оживление возвращает Звездочёта.")
	TEST_ASSERT(!spell.can_cast(user, FALSE, TRUE), "После оживления призыв ждёт перезарядку.")
	spell.charge_counter = spell.charge_max
	fixture["spell"] = spell
	var/mob/living/simple_animal/heretic_stargazer/second = summon_test_stargazer(fixture)
	TEST_ASSERT_NOTNULL(second, "После перезарядки призывается новый Звездочёт.")
	finale.on_body_lose(user)
	TEST_ASSERT(QDELETED(second), "Потеря тела уносит Звездочёта.")

/// Вознесённый оставляет звезду за каждые 4 секунды движения, без стоянок и не больше пяти звёзд.
/datum/unit_test/heretic_cosmic_wake/Run()
	var/list/fixture = ascend_cosmic_fixture()
	var/mob/living/carbon/human/user = fixture["user"]
	var/datum/eldritch_knowledge/final_eldritch/cosmic_final/finale = fixture["finale"]
	var/datum/eldritch_knowledge/base_cosmic/cosmic = fixture["cosmic"]
	var/datum/component/heretic_cosmic_wake/wake = user.GetComponent(/datum/component/heretic_cosmic_wake)
	TEST_ASSERT_NOTNULL(wake, "Вознесение Космоса даёт звёздный след.")
	var/steps_per_star = HERETIC_COSMIC_WAKE_INTERVAL / HERETIC_COSMIC_WAKE_STEP_GAP
	for(var/step in 1 to steps_per_star - 1)
		wake.last_step_time = world.time - HERETIC_COSMIC_WAKE_STEP_GAP
		TEST_ASSERT(user.Move(get_step(user, EAST), EAST), "Герой шагает на восток.")
	TEST_ASSERT_EQUAL(length(cosmic.stars), 0, "Меньше 4 секунд движения звезды не дают.")
	wake.last_step_time = world.time - HERETIC_COSMIC_WAKE_STEP_GAP
	TEST_ASSERT(user.Move(get_step(user, NORTH), NORTH), "Герой шагает на север.")
	TEST_ASSERT_EQUAL(length(cosmic.stars), 1, "4 секунды движения зажигают звезду.")
	var/obj/structure/heretic_star/first = cosmic.stars[1]
	TEST_ASSERT_EQUAL(first.loc, user.loc, "Звезда загорается под героем.")
	for(var/step in 1 to steps_per_star)
		wake.last_step_time = world.time - 10 SECONDS
		TEST_ASSERT(user.Move(get_step(user, NORTH), NORTH), "Герой делает шаг после стоянки.")
	TEST_ASSERT_EQUAL(length(cosmic.stars), 1, "Стоянки между шагами не копят движение.")
	var/turf/corner = run_loc_floor_top_right
	cosmic.add_star(corner, user)
	cosmic.add_star(get_step(corner, WEST), user)
	cosmic.add_star(get_step(get_step(corner, WEST), WEST), user)
	cosmic.add_star(get_step(corner, SOUTH), user)
	TEST_ASSERT_EQUAL(length(cosmic.stars), cosmic.star_limit(), "Созвездие заполнено до пяти звёзд.")
	for(var/step in 1 to steps_per_star)
		wake.last_step_time = world.time - HERETIC_COSMIC_WAKE_STEP_GAP
		TEST_ASSERT(user.Move(get_step(user, WEST), WEST), "Герой шагает на запад.")
	TEST_ASSERT_EQUAL(length(cosmic.stars), cosmic.star_limit(), "След не превышает пяти звёзд.")
	TEST_ASSERT(QDELETED(first), "Новая звезда следа заменяет старейшую.")
	var/obj/structure/heretic_star/newest = cosmic.stars[length(cosmic.stars)]
	TEST_ASSERT_EQUAL(newest.loc, user.loc, "Последняя звезда горит под героем.")
	finale.on_body_lose(user)
	TEST_ASSERT_NULL(user.GetComponent(/datum/component/heretic_cosmic_wake), "Потеря тела гасит звёздный след.")

/// Звёзды следа не срывают схлопывание: во время предупреждения след ждёт, после удара снова горит.
/datum/unit_test/heretic_cosmic_wake_keeps_collapse/Run()
	var/list/fixture = ascend_cosmic_fixture()
	var/mob/living/carbon/human/user = fixture["user"]
	var/datum/eldritch_knowledge/base_cosmic/cosmic = fixture["cosmic"]
	var/datum/component/heretic_cosmic_wake/wake = user.GetComponent(/datum/component/heretic_cosmic_wake)
	var/turf/star_place = get_step(get_step(get_step(user, EAST), EAST), EAST)
	TEST_ASSERT(cosmic.add_star(star_place, user), "Звезда для схлопывания зажигается.")
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, get_step(star_place, NORTH))
	var/obj/effect/proc_holder/spell/self/cosmic/collapse/spell = allocate(/obj/effect/proc_holder/spell/self/cosmic/collapse)
	spell.cast(list(user), user)
	TEST_ASSERT(spell.collapse_pending, "Схлопывание ждёт удара после предупреждения.")
	var/steps_per_star = HERETIC_COSMIC_WAKE_INTERVAL / HERETIC_COSMIC_WAKE_STEP_GAP
	for(var/step in 1 to steps_per_star)
		wake.last_step_time = world.time - HERETIC_COSMIC_WAKE_STEP_GAP
		TEST_ASSERT(user.Move(get_step(user, NORTH), NORTH), "Герой идёт во время предупреждения.")
	TEST_ASSERT_EQUAL(length(cosmic.stars), 1, "Во время предупреждения след не зажигает звёзд.")
	var/scheduled_strike = cosmic.collapse_pending_until
	for(var/late in list(0, 5))
		cosmic.collapse_pending_until = world.time - late
		TEST_ASSERT(!cosmic.can_trail_star(user), "На тике удара и при опоздании таймера след ждёт, пока схлопывание не сработает.")
		wake.last_step_time = world.time - HERETIC_COSMIC_WAKE_STEP_GAP
		TEST_ASSERT(user.Move(get_step(user, EAST), EAST), "Герой шагает на тике удара.")
		TEST_ASSERT_EQUAL(length(cosmic.stars), 1, "Шаг на тике удара не зажигает звезду до схлопывания.")
	cosmic.collapse_pending_until = scheduled_strike
	var/list/budget = new_wait_budget(3 SECONDS, "схлопывание должно ударить после предупреждения")
	while(spell.collapse_pending)
		TEST_ASSERT(!cosmic.can_trail_star(user), "Пока схлопывание ждёт удара, след не зажигает звёзд.")
		if(!wait_budget_tick(budget))
			break
	TEST_ASSERT(abs(victim.getFireLoss() - 45) < DAMAGE_PRECISION, "Схлопывание срабатывает, хотя герой шёл через предупреждение.")
	TEST_ASSERT_EQUAL(length(cosmic.stars), 0, "Схлопывание расходует созвездие.")
	wake.last_step_time = world.time - HERETIC_COSMIC_WAKE_STEP_GAP
	TEST_ASSERT(user.Move(get_step(user, EAST), EAST), "Герой шагает после удара.")
	TEST_ASSERT_EQUAL(length(cosmic.stars), 1, "После удара накопленное движение сразу зажигает звезду.")

/// Луч летит на семь клеток по кругу: угол квадрата range() ему недоступен, ближняя диагональ - да.
/datum/unit_test/heretic_cosmic_stargazer_diagonal_range/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/turf/gazer_place = locate(origin.x - 1, origin.y - 1, origin.z)
	var/list/fixture = ascend_cosmic_fixture(locate(origin.x + 5, origin.y - 1, origin.z))
	var/mob/living/carbon/human/user = fixture["user"]
	var/mob/living/simple_animal/heretic_stargazer/gazer = summon_test_stargazer(fixture)
	TEST_ASSERT_NOTNULL(gazer, "Призыв создаёт Звездочёта.")
	gazer.forceMove(gazer_place)
	var/mob/living/carbon/human/far = allocate(/mob/living/carbon/human, locate(origin.x + 5, origin.y + 5, origin.z))
	TEST_ASSERT(get_dist(gazer, far) <= HERETIC_STARGAZER_RANGE && get_dist_euclidian(gazer, far) > HERETIC_STARGAZER_RANGE, "Дальний враг стоит в углу квадрата, за пределом круга.")
	TEST_ASSERT_NULL(gazer.pick_target(user), "Враг за семью клетками по прямой не выбирается целью.")
	var/mob/living/carbon/human/near = allocate(/mob/living/carbon/human, locate(origin.x + 3, origin.y + 3, origin.z))
	TEST_ASSERT_EQUAL(gazer.pick_target(user), near, "Враг на диагонали в пределах семи клеток выбирается целью.")
	TEST_ASSERT(gazer.try_fire(user), "Звездочёт стреляет по диагонали.")
	var/list/budget = new_wait_budget(2 SECONDS, "луч по диагонали должен долететь")
	while(near.getFireLoss() < HERETIC_STARGAZER_BEAM_DAMAGE)
		if(!wait_budget_tick(budget))
			break
	TEST_ASSERT(abs(near.getFireLoss() - HERETIC_STARGAZER_BEAM_DAMAGE) < DAMAGE_PRECISION, "Луч по диагонали наносит 20 ожогов.")
	TEST_ASSERT_EQUAL(far.getFireLoss(), 0, "Дальний враг за целью не задет.")

/// Звездочёт держится рядом: вблизи стоит, на средней дистанции идёт, дальше 12 клеток или с другого уровня переносится к герою.
/datum/unit_test/heretic_cosmic_stargazer_keeps_up/Run()
	var/list/fixture = ascend_cosmic_fixture()
	var/mob/living/carbon/human/user = fixture["user"]
	var/mob/living/simple_animal/heretic_stargazer/gazer = summon_test_stargazer(fixture)
	TEST_ASSERT_NOTNULL(gazer, "Призыв создаёт Звездочёта.")
	var/turf/home = get_turf(user)
	gazer.forceMove(locate(home.x + 4, home.y, home.z))
	gazer.keep_up(user)
	TEST_ASSERT_NOTNULL(SSmove_manager.processing_on(gazer, SSmovement), "На средней дистанции Звездочёт летит к герою.")
	gazer.forceMove(get_step(home, EAST))
	gazer.keep_up(user)
	TEST_ASSERT_NULL(SSmove_manager.processing_on(gazer, SSmovement), "Рядом с героем Звездочёт останавливается.")
	var/far_x = home.x + 15 <= world.maxx ? home.x + 15 : home.x - 15
	var/turf/far = locate(far_x, home.y, home.z)
	TEST_ASSERT_NOTNULL(far, "Есть клетка дальше двенадцати от героя.")
	gazer.forceMove(far)
	gazer.keep_up(user)
	TEST_ASSERT_EQUAL(get_turf(gazer), home, "Отставший дальше двенадцати клеток Звездочёт переносится к герою.")
	var/turf/elsewhere = locate(round(world.maxx / 2), round(world.maxy / 2), home.z == 1 ? 2 : 1)
	gazer.forceMove(elsewhere)
	TEST_ASSERT_NOTEQUAL(gazer.z, home.z, "Звездочёт унесён на другой уровень.")
	gazer.keep_up(user)
	TEST_ASSERT_EQUAL(get_turf(gazer), home, "С другого уровня Звездочёт переносится к герою.")

/// Призыв Звездочёта: за ним раскрывается разрыв, звёзды сходятся к его телу, он проступает из лучей, волна и вспышка; сам Звездочёт тот же.
/datum/unit_test/heretic_cosmic_stargazer_arrival_visuals/Run()
	var/list/fixture = ascend_cosmic_fixture()
	var/mob/living/carbon/human/user = fixture["user"]
	var/mob/living/simple_animal/heretic_stargazer/gazer = summon_test_stargazer(fixture)
	TEST_ASSERT_NOTNULL(gazer, "Призыв создаёт Звездочёта.")
	var/turf/place = get_turf(gazer)
	var/obj/effect/temp_visual/heretic_stargazer_rift/rift = locate() in place
	TEST_ASSERT_NOTNULL(rift, "За Звездочётом раскрывается разрыв.")
	TEST_ASSERT(rift.layer < gazer.layer, "Разрыв лежит позади Звездочёта.")
	TEST_ASSERT(length(rift.overlays), "Разрыв виден в темноте.")
	TEST_ASSERT(rift.mouse_opacity == MOUSE_OPACITY_TRANSPARENT, "Разрыв не мешает кликам.")
	var/obj/effect/temp_visual/heretic_vfx/converge/stars = locate() in place
	TEST_ASSERT_NOTNULL(stars, "Звёзды стягиваются к Звездочёту.")
	TEST_ASSERT(stars.pixel_y > 0, "Звёзды сходятся к телу, а не к полу.")
	TEST_ASSERT_NOTNULL(locate(/obj/effect/temp_visual/heretic_vfx/shockwave) in place, "Призыв расходится волной.")
	TEST_ASSERT_NOTNULL(gazer.get_filter(HERETIC_VFX_RAYS_FILTER), "Звездочёт проступает из лучей.")
	TEST_ASSERT_NOTNULL(user.get_filter(HERETIC_VFX_PULSE_FILTER), "Призывающий вспыхивает контуром.")
	TEST_ASSERT_EQUAL(gazer.health, HERETIC_STARGAZER_HEALTH, "Звездочёт появляется целым, как раньше.")
	TEST_ASSERT(get_dist(gazer, user) <= 1, "Звездочёт появляется рядом с героем, как раньше.")
	TEST_ASSERT(wait_for_qdeleted(rift), "Разрыв затягивается.")
	TEST_ASSERT(wait_for_qdeleted(stars), "Звёзды долетают и гаснут.")
	var/list/budget = new_wait_budget(2 SECONDS, "лучи призыва должны погаснуть")
	while(gazer.get_filter(HERETIC_VFX_RAYS_FILTER))
		if(!wait_budget_tick(budget))
			break
	TEST_ASSERT_NULL(gazer.get_filter(HERETIC_VFX_RAYS_FILTER), "Лучи призыва снимаются.")

/// Звезда в руке копит свет и вспыхивает выстрелом, вдоль луча вспыхивает сердцевина, в цели взрываются звёзды; урон и перезарядка прежние.
/datum/unit_test/heretic_cosmic_stargazer_beam_visuals/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/list/fixture = ascend_cosmic_fixture(get_step(origin, WEST))
	var/mob/living/carbon/human/user = fixture["user"]
	var/mob/living/simple_animal/heretic_stargazer/gazer = summon_test_stargazer(fixture)
	TEST_ASSERT_NOTNULL(gazer, "Призыв создаёт Звездочёта.")
	gazer.forceMove(origin)
	COOLDOWN_START(gazer, beam_cooldown, 0.5 SECONDS)
	TEST_ASSERT(!gazer.plan_charge(), "Без зрителей заряд не готовится.")
	TEST_ASSERT_NULL(gazer.charge_timer, "Без зрителей таймер заряда не заводится.")
	gazer.start_charge()
	var/obj/effect/abstract/heretic_vfx_attached/charge = gazer.hand_glow
	TEST_ASSERT_NOTNULL(charge, "Звезда в руке копит свет.")
	TEST_ASSERT(charge in gazer.vis_contents, "Заряд висит на самом Звездочёте.")
	TEST_ASSERT(charge.pixel_y > world.icon_size, "Заряд горит в поднятой руке, а не у ног.")
	TEST_ASSERT(charge.glow in charge.vis_contents, "Заряд виден в темноте.")
	COOLDOWN_RESET(gazer, beam_cooldown)
	var/turf/east = origin
	for(var/step in 1 to 4)
		east = get_step(east, EAST)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, east)
	TEST_ASSERT(gazer.try_fire(user), "Звездочёт стреляет, как раньше.")
	TEST_ASSERT_NULL(gazer.hand_glow, "Выстрел расходует накопленный свет.")
	TEST_ASSERT(charge.fading, "Звезда в руке вспыхивает и гаснет.")
	var/list/budget = new_wait_budget(2 SECONDS, "луч Звездочёта должен долететь до врага")
	while(victim.getFireLoss() < HERETIC_STARGAZER_BEAM_DAMAGE)
		if(!wait_budget_tick(budget))
			break
	TEST_ASSERT(abs(victim.getFireLoss() - HERETIC_STARGAZER_BEAM_DAMAGE) < DAMAGE_PRECISION, "Луч наносит 20 ожогов, как раньше.")
	TEST_ASSERT(!gazer.try_fire(user), "Следующий луч через 3 секунды, как раньше.")
	var/obj/effect/temp_visual/heretic_vfx/thread/core = locate() in origin
	TEST_ASSERT_NOTNULL(core, "Вдоль луча вспыхивает яркая сердцевина.")
	TEST_ASSERT(core.settled, "Сердцевина сразу вспыхивает и уходит в цель.")
	TEST_ASSERT_EQUAL(round(core.angle), round(Get_Angle(origin, east)), "Сердцевина смотрит на цель.")
	TEST_ASSERT_NOTNULL(find_vfx_burst(east, /particles/heretic_ascension/cosmic/impact, list()), "В цели взрываются звёзды.")
	TEST_ASSERT(wait_for_qdeleted(charge), "Вспыхнувшая звезда удаляется.")
	TEST_ASSERT(wait_for_qdeleted(core), "Сердцевина луча гаснет.")
	gazer.start_charge()
	var/obj/effect/abstract/heretic_vfx_attached/unused = gazer.hand_glow
	TEST_ASSERT_NOTNULL(unused, "Новый заряд копится.")
	TEST_ASSERT(wait_for_qdeleted(unused), "Невыпущенный заряд гаснет сам.")
	TEST_ASSERT_NULL(gazer.hand_glow, "Погасший заряд не держится за Звездочётом.")

/// Гибель Звездочёта: он сжимается в точку и рассыпается звёздами с волной; рассыпание по приказу и отрыв поводка оставляют осыпающийся снимок.
/datum/unit_test/heretic_cosmic_stargazer_collapse_visuals/Run()
	var/list/fixture = ascend_cosmic_fixture()
	var/mob/living/carbon/human/user = fixture["user"]
	var/obj/effect/proc_holder/spell/self/cosmic/stargazer/spell = fixture["spell"]
	var/mob/living/simple_animal/heretic_stargazer/gazer = summon_test_stargazer(fixture)
	TEST_ASSERT_NOTNULL(gazer, "Призыв создаёт Звездочёта.")
	var/turf/place = get_turf(gazer)
	gazer.start_charge()
	var/obj/effect/abstract/heretic_vfx_attached/charge = gazer.hand_glow
	var/list/before = list_vfx_bursts(place)
	var/list/waves_before = list()
	for(var/obj/effect/temp_visual/heretic_vfx/shockwave/wave in place)
		waves_before += wave
	gazer.adjustBruteLoss(HERETIC_STARGAZER_HEALTH * 2)
	TEST_ASSERT_EQUAL(gazer.stat, DEAD, "Звездочёт гибнет от урона, как раньше.")
	var/obj/effect/temp_visual/heretic_vfx/burst/scatter = find_vfx_burst(place, /particles/heretic_ascension/cosmic/scatter, before)
	TEST_ASSERT_NOTNULL(scatter, "Погибший рассыпается звёздами.")
	TEST_ASSERT(scatter.pixel_y > 0, "Звёзды осыпаются со всего роста, а не с пола.")
	var/obj/effect/temp_visual/heretic_vfx/shockwave/death_wave
	for(var/obj/effect/temp_visual/heretic_vfx/shockwave/wave in place)
		if(!(wave in waves_before))
			death_wave = wave
	TEST_ASSERT_NOTNULL(death_wave, "Гибель расходится волной.")
	TEST_ASSERT(QDELETED(charge) && !gazer.hand_glow, "Гибель гасит звезду в руке.")
	TEST_ASSERT(!QDELETED(gazer), "Тело сначала сжимается на месте, как раньше.")
	TEST_ASSERT(wait_for_qdeleted(gazer, 3 SECONDS), "Сжавшееся тело исчезает, как раньше.")
	spell.charge_counter = spell.charge_max
	gazer = summon_test_stargazer(fixture)
	TEST_ASSERT_NOTNULL(gazer, "Призывается новый Звездочёт.")
	place = get_turf(gazer)
	var/turf/far = locate(place.x + 15 <= world.maxx ? place.x + 15 : place.x - 15, place.y, place.z)
	gazer.forceMove(far)
	gazer.keep_up(user)
	TEST_ASSERT_EQUAL(get_turf(gazer), get_turf(user), "Отставший переносится к герою, как раньше.")
	var/obj/effect/temp_visual/heretic_stargazer_remnant/left_behind = locate() in far
	TEST_ASSERT_NOTNULL(left_behind, "На старом месте Звездочёт осыпается звёздами, а не пропадает.")
	TEST_ASSERT(left_behind.mouse_opacity == MOUSE_OPACITY_TRANSPARENT, "Осыпающийся снимок не мешает кликам.")
	place = get_turf(gazer)
	gazer.dissolve()
	TEST_ASSERT(QDELETED(gazer), "Рассыпание убирает Звездочёта, как раньше.")
	var/obj/effect/temp_visual/heretic_stargazer_remnant/remnant = locate() in place
	TEST_ASSERT_NOTNULL(remnant, "Рассыпавшийся оставляет осыпающийся снимок.")
	TEST_ASSERT(remnant.glow in remnant.vis_contents, "Снимок виден в темноте.")
	TEST_ASSERT(wait_for_qdeleted(left_behind), "Снимок у старого места гаснет.")
	TEST_ASSERT(wait_for_qdeleted(remnant, 3 SECONDS), "Снимок рассыпавшегося гаснет.")

/// Звезда следа загорается бликом, если рядом есть зрители; звезда из заклинания - без него.
/datum/unit_test/heretic_cosmic_trail_twinkle/Run()
	var/list/fixture = ascend_cosmic_fixture()
	var/mob/living/carbon/human/user = fixture["user"]
	var/datum/eldritch_knowledge/base_cosmic/cosmic = fixture["cosmic"]
	var/turf/place = get_turf(user)
	TEST_ASSERT(cosmic.trail_star(user), "След зажигает звезду, как раньше.")
	TEST_ASSERT_EQUAL(length(cosmic.stars), 1, "След даёт одну звезду, как раньше.")
	TEST_ASSERT_NULL(locate(/obj/effect/temp_visual/heretic_cosmic_twinkle) in place, "Без зрителей рядом блик следа не рисуется.")
	var/obj/effect/temp_visual/heretic_cosmic_twinkle/twinkle = heretic_cosmic_twinkle(place)
	TEST_ASSERT_NOTNULL(twinkle, "Звезда следа загорается бликом.")
	TEST_ASSERT(length(twinkle.overlays), "Блик виден в темноте.")
	var/turf/other = locate(place.x + 2, place.y, place.z)
	TEST_ASSERT(cosmic.add_star(other, user), "Звезда ставится заклинанием, как раньше.")
	TEST_ASSERT_NULL(locate(/obj/effect/temp_visual/heretic_cosmic_twinkle) in other, "Обычная звезда без блика следа.")
	TEST_ASSERT(wait_for_qdeleted(twinkle), "Блик гаснет.")

/// Новые космические эффекты создаются без аргументов и удаляются без ошибок; снимок Звездочёта не уносит чужих фильтров.
/datum/unit_test/heretic_cosmic_visual_types_create_and_destroy/Run()
	for(var/thing_type in list(/obj/effect/temp_visual/heretic_stargazer_rift, /obj/effect/temp_visual/heretic_stargazer_remnant, /obj/effect/temp_visual/heretic_cosmic_twinkle))
		qdel(new thing_type(run_loc_floor_bottom_left))
	var/obj/item/pen/model = allocate(/obj/item/pen, run_loc_floor_bottom_left)
	model.add_filter("heretic_test_outline", 1, outline_filter(1, COLOR_WHITE))
	var/obj/effect/temp_visual/heretic_stargazer_remnant/remnant = new(run_loc_floor_bottom_left, model.appearance)
	TEST_ASSERT(!length(remnant.filters), "Снимок не повторяет контуры и лучи образца.")
	var/obj/effect/abstract/heretic_vfx_glow/glow = remnant.glow
	qdel(remnant)
	TEST_ASSERT(QDELETED(glow), "Снятый снимок уносит своё свечение.")
