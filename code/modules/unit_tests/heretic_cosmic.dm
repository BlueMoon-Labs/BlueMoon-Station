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

/// Закрытое пространство блокирует связь, а занятая точка не принимает телепортацию.
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
	TEST_ASSERT(!knowledge.add_star(last, user), "Стена между вершинами не позволяет проложить созвездие.")
	middle.ChangeTurf(/turf/open/floor/plasteel)
	TEST_ASSERT(knowledge.add_star(last, user), "После открытия пути звезда создаётся.")
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
	TEST_ASSERT_EQUAL(victim.getFireLoss(), burn_before + 35, "Даже возле двух звёзд цель получает один удар схлопывания.")
	TEST_ASSERT_EQUAL(length(knowledge.stars), 0, "Схлопывание расходует все звёзды.")
	TEST_ASSERT_EQUAL(length(knowledge.threads), 0, "Схлопывание убирает ловушки.")

/// Притяжение замедляет цель без повторного удара нитей, а снятие эффекта сохраняет чужое замедление.
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
	TEST_ASSERT_EQUAL(victim.getStaminaLoss(), 20, "Перемещение пульсом через нить не складывает два удара.")
	var/datum/status_effect/cosmic_tether/tether = victim.has_status_effect(/datum/status_effect/cosmic_tether)
	tether.duration = world.time + 1 SECONDS
	knowledge.pulse(user)
	TEST_ASSERT_EQUAL(tether.duration, world.time + 3 SECONDS, "Новый пульс обновляет длительность притяжения до трёх секунд.")
	TEST_ASSERT_EQUAL(length(victim.has_status_effect_list(/datum/status_effect/cosmic_tether)), 1, "Пульс обновляет один эффект, не складывая замедления.")
	var/datum/component/anti_magic/protection = victim.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5)
	TEST_ASSERT(!knowledge.cross_thread(victim), "Во время замедления нить не активируется повторно.")
	TEST_ASSERT_EQUAL(protection.charges, 5, "Неактивная нить не расходует заряды антимагии.")
	victim.remove_status_effect(/datum/status_effect/cosmic_tether)
	TEST_ASSERT(!victim.has_movespeed_modifier(/datum/movespeed_modifier/cosmic_tether), "После снятия притяжения его замедление исчезает.")
	TEST_ASSERT(victim.has_movespeed_modifier(/datum/movespeed_modifier/heretic_moon_opening), "Чужое замедление сохраняется.")
	TEST_ASSERT(!knowledge.cross_thread(victim), "Антимагия защищает от следующего пересечения.")
	TEST_ASSERT_EQUAL(protection.charges, 4, "Действующая нить расходует один заряд защиты.")
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
