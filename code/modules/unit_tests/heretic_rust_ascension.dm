/datum/unit_test/proc/ascend_rust_fixture(turf/location)
	var/datum/antagonist/heretic/heretic = allocate_heretic(location || get_step(run_loc_floor_bottom_left, NORTHEAST))
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/final_eldritch/rust_final/finale = allocate(/datum/eldritch_knowledge/final_eldritch/rust_final)
	heretic.researched_knowledge[finale.type] = finale
	heretic.ascended = TRUE
	finale.finished = TRUE
	finale.on_body_gain(user)
	finale.plant_ascension_heart(get_turf(user), user)
	STOP_PROCESSING(SSprocessing, finale.spread)
	return list("user" = user, "heretic" = heretic, "finale" = finale)

/// Обряд вознесения Ржавчины сажает сердце на руну, а над космосом - у ног еретика.
/datum/unit_test/heretic_rust_ascension_heart/Run()
	var/turf/rune_turf = get_step(run_loc_floor_bottom_left, NORTHEAST)
	var/datum/antagonist/heretic/heretic = allocate_heretic(rune_turf)
	heretic.ascension_notice_sent = TRUE
	var/mob/living/user = heretic.owner.current
	heretic.selected_path = PATH_RUST
	heretic.total_sacrifices = HERETIC_ASCENSION_SACRIFICES
	var/obj/effect/eldritch/rune = allocate(/obj/effect/eldritch/big, rune_turf)
	var/datum/eldritch_knowledge/final_eldritch/rust_final/finale = allocate(/datum/eldritch_knowledge/final_eldritch/rust_final)
	finale.ritual_time = 0
	heretic.researched_knowledge[finale.type] = finale
	for(var/body_index in 1 to HERETIC_ASCENSION_BODIES)
		var/mob/living/carbon/human/body = allocate(/mob/living/carbon/human, rune_turf)
		body.last_mind = allocate_mind()
		body.stat = DEAD
	TEST_ASSERT(rune.do_ritual(user, finale), "Обряд вознесения Ржавчины завершается.")
	var/obj/structure/heretic_rust_ascension_heart/heart = finale.ascension_heart
	TEST_ASSERT_NOTNULL(heart, "Вознесение сажает ржавое сердце.")
	allocated += heart
	TEST_ASSERT_EQUAL(heart.loc, rune_turf, "Сердце растёт на клетке руны.")
	TEST_ASSERT_EQUAL(heart.max_integrity, HERETIC_RUST_HEART_INTEGRITY, "У сердца 300 прочности.")
	TEST_ASSERT_NOTNULL(finale.spread, "Живое сердце запускает расползание ржавчины.")
	STOP_PROCESSING(SSprocessing, finale.spread)
	var/turf/space = get_step(run_loc_floor_top_right, NORTH)
	var/original_type = space.type
	space = space.ChangeTurf(/turf/open/space)
	qdel(heart)
	finale.plant_ascension_heart(space, user)
	TEST_ASSERT_NOTNULL(finale.ascension_heart, "Сердце сажается и без подходящей руны.")
	TEST_ASSERT_EQUAL(finale.ascension_heart.loc, get_turf(user), "Над космосом сердце растёт у ног еретика.")
	space.ChangeTurf(original_type)

/// Разбитое сердце навсегда останавливает расползание, лечение и сбережение сил на ржавом полу.
/datum/unit_test/heretic_rust_ascension_heart_loss/Run()
	var/list/fixture = ascend_rust_fixture()
	var/mob/living/carbon/human/user = fixture["user"]
	var/datum/eldritch_knowledge/final_eldritch/rust_final/finale = fixture["finale"]
	var/datum/rust_spread/spread = finale.spread
	var/turf/floor = get_turf(user)
	floor.rust_heretic_act()
	finale.on_life(user)
	user.adjustBruteLoss(20)
	var/brute_before = user.getBruteLoss()
	finale.on_life(user)
	TEST_ASSERT(user.getBruteLoss() < brute_before, "Живое сердце даёт лечение на ржавом полу.")
	qdel(finale.ascension_heart)
	TEST_ASSERT(QDELETED(spread), "Разбитое сердце останавливает расползание.")
	TEST_ASSERT_NULL(finale.spread, "Знание освобождает остановленное расползание.")
	brute_before = user.getBruteLoss()
	finale.on_life(user)
	TEST_ASSERT(abs(user.getBruteLoss() - brute_before) < DAMAGE_PRECISION, "Без сердца ржавый пол не лечит.")
	TEST_ASSERT_NULL(finale.spread, "Без сердца расползание не возобновляется.")
	finale.on_body_lose(user)
	finale.on_body_gain(user)
	TEST_ASSERT_NULL(finale.spread, "Смена тела не возвращает расползание без сердца.")

/// Ржавый пол при живом сердце вдвое снижает урон выносливости, уход и смерть возвращают множитель точно.
/datum/unit_test/heretic_rust_ascension_stamina/Run()
	var/list/fixture = ascend_rust_fixture()
	var/mob/living/carbon/human/user = fixture["user"]
	var/datum/eldritch_knowledge/final_eldritch/rust_final/finale = fixture["finale"]
	var/base_mod = user.physiology.heretic_stamina_mod
	var/turf/rust = get_step(user, EAST)
	rust = rust.rust_heretic_act()
	user.forceMove(rust)
	TEST_ASSERT_EQUAL(user.physiology.heretic_stamina_mod, base_mod * HERETIC_RUST_ASCENDED_STAMINA_MOD, "Шаг на ржавчину вдвое снижает урон выносливости.")
	user.forceMove(get_step(rust, NORTH))
	TEST_ASSERT_EQUAL(user.physiology.heretic_stamina_mod, base_mod, "Уход с ржавчины возвращает множитель.")
	user.forceMove(rust)
	qdel(finale.ascension_heart)
	TEST_ASSERT_EQUAL(user.physiology.heretic_stamina_mod, base_mod, "Разбитое сердце снимает сбережение сил.")
	user.forceMove(get_step(rust, NORTH))
	user.forceMove(rust)
	TEST_ASSERT_EQUAL(user.physiology.heretic_stamina_mod, base_mod, "Без сердца ржавчина больше не бережёт силы.")
	var/list/second = ascend_rust_fixture(rust)
	var/mob/living/carbon/human/other = second["user"]
	var/datum/eldritch_knowledge/final_eldritch/rust_final/other_finale = second["finale"]
	other_finale.on_life(other)
	TEST_ASSERT_EQUAL(other.physiology.heretic_stamina_mod, HERETIC_ASCENDED_STAMINA_MOD * HERETIC_RUST_ASCENDED_STAMINA_MOD, "Второй вознесённый на ржавчине получает оба множителя.")
	other_finale.on_body_lose(other)
	TEST_ASSERT_EQUAL(other.physiology.heretic_stamina_mod, 1, "Потеря тела точно возвращает исходный множитель.")

/// Коррозийный вал бьёт врагов в пяти клетках, не трогает дальних и союзников, рушит обычные стены, но не наружные.
/datum/unit_test/heretic_rust_ascension_wave/Run()
	var/turf/origin = get_step(run_loc_floor_bottom_left, WEST)
	var/list/fixture = ascend_rust_fixture(origin)
	var/mob/living/carbon/human/user = fixture["user"]
	var/datum/eldritch_knowledge/final_eldritch/rust_final/finale = fixture["finale"]
	var/obj/effect/proc_holder/spell/self/rust_corrosive_wave/wave = locate() in finale.ascension_spell_instances
	TEST_ASSERT_NOTNULL(wave, "Вознесение Ржавчины даёт Коррозийный вал.")
	TEST_ASSERT_EQUAL(wave.charge_max, HERETIC_RUST_WAVE_COOLDOWN, "Вал перезаряжается 40 секунд.")
	var/mob/living/carbon/human/near = allocate(/mob/living/carbon/human, locate(origin.x + HERETIC_RUST_WAVE_RANGE, origin.y, origin.z))
	var/mob/living/carbon/human/far = allocate(/mob/living/carbon/human, locate(origin.x + HERETIC_RUST_WAVE_RANGE + 1, origin.y, origin.z))
	var/datum/antagonist/heretic/ally_heretic = allocate_heretic(locate(origin.x + 2, origin.y, origin.z))
	var/mob/living/ally = ally_heretic.owner.current
	var/turf/plain_wall = locate(origin.x + 2, origin.y + 2, origin.z)
	plain_wall = plain_wall.ChangeTurf(/turf/closed/wall)
	var/turf/reinforced = locate(origin.x + 2, origin.y + 1, origin.z)
	reinforced = reinforced.ChangeTurf(/turf/closed/wall/r_wall)
	var/turf/floor = locate(origin.x + 3, origin.y, origin.z)
	var/turf/outer_wall = locate(origin.x + 3, origin.y - 1, origin.z)
	outer_wall = outer_wall.ChangeTurf(/turf/closed/wall)
	var/turf/void = locate(origin.x + 4, origin.y - 1, origin.z)
	var/void_type = void.type
	void = void.ChangeTurf(/turf/open/space)
	var/turf/hull = locate(origin.x + 1, origin.y - 1, origin.z)
	var/hull_type = hull.type
	hull = hull.ChangeTurf(/turf/closed/wall/mineral/titanium)
	var/turf/cordon = locate(origin.x - 1, origin.y, origin.z)
	var/turf/rusted_outer = locate(origin.x, origin.y - 2, origin.z)
	rusted_outer = rusted_outer.ChangeTurf(/turf/closed/wall/rust)
	TEST_ASSERT(wave.faces_void(rusted_outer), "Ржавая стена кордона граничит с космосом.")
	wave.cast(list(user), user)
	TEST_ASSERT(abs(near.getFireLoss() + near.getToxLoss() - HERETIC_RUST_WAVE_CORROSION) < DAMAGE_PRECISION, "Враг в пяти клетках получает 20 урона коррозией.")
	TEST_ASSERT_EQUAL(far.getFireLoss() + far.getToxLoss(), 0, "Враг в шести клетках не задет.")
	TEST_ASSERT_EQUAL(ally.getFireLoss() + ally.getToxLoss(), 0, "Еретик-союзник не задет.")
	TEST_ASSERT(!near.IsParalyzed() && !near.IsKnockdown(), "Вал не оглушает.")
	TEST_ASSERT(!iswallturf(locate(origin.x + 2, origin.y + 2, origin.z)), "Обычная стена рушится.")
	TEST_ASSERT(istype(locate(origin.x + 2, origin.y + 1, origin.z), /turf/closed/wall/r_wall), "Укреплённая стена устояла.")
	TEST_ASSERT(istype(locate(floor.x, floor.y, floor.z), /turf/open/floor/plating/rust), "Пол в радиусе ржавеет.")
	wave.cast(list(user), user)
	TEST_ASSERT(iswallturf(locate(outer_wall.x, outer_wall.y, outer_wall.z)), "Стена, за которой космос, устояла после двух волн.")
	TEST_ASSERT(istype(locate(rusted_outer.x, rusted_outer.y, rusted_outer.z), /turf/closed/wall/rust), "Ржавая стена у космоса не соскоблена.")
	TEST_ASSERT(iswallturf(locate(cordon.x, cordon.y, cordon.z)), "Кордон резервации не вскрыт.")
	TEST_ASSERT_EQUAL(hull.type, /turf/closed/wall/mineral/titanium, "Корпус шаттла не ржавеет.")
	void.ChangeTurf(void_type)
	hull.ChangeTurf(hull_type)
	rusted_outer.ChangeTurf(/turf/closed/wall)

/// Удаление живого вознесённого на ржавчине не падает на снятии множителей выносливости.
/datum/unit_test/heretic_rust_ascension_qdel_body/Run()
	var/list/fixture = ascend_rust_fixture()
	var/mob/living/carbon/human/user = fixture["user"]
	var/turf/floor = get_turf(user)
	floor.rust_heretic_act()
	var/datum/component/heretic_rust_ascension/aspect = user.GetComponent(/datum/component/heretic_rust_ascension)
	aspect.update_stamina()
	TEST_ASSERT(aspect.stamina_applied, "Вознесённый на ржавчине получает сбережение сил.")
	qdel(user)
	TEST_ASSERT(QDELETED(user), "Тело удалено без рантаймов.")

/// Сердце светится и роняет хлопья; удар даёт дрожь и горсть хлопьев без изменения урона; гибель - оседание, обвал хлопьев и тёмная вспышка.
/datum/unit_test/heretic_rust_heart_visuals/Run()
	var/list/fixture = ascend_rust_fixture()
	var/datum/eldritch_knowledge/final_eldritch/rust_final/finale = fixture["finale"]
	var/obj/structure/heretic_rust_ascension_heart/heart = finale.ascension_heart
	var/turf/place = get_turf(heart)
	TEST_ASSERT(length(heart.overlays), "Сердце светится в темноте.")
	var/obj/effect/abstract/heretic_particle_holder/flakes = heart.flakes
	TEST_ASSERT(flakes in heart.vis_contents, "С сердца осыпаются хлопья.")
	TEST_ASSERT(flakes.particles.spawning > 0, "Хлопья сыплются, пока сердце бьётся.")
	var/list/before = list_vfx_bursts(place)
	var/integrity = heart.obj_integrity
	var/dealt = heart.take_damage(40, BRUTE, MELEE)
	TEST_ASSERT(dealt > 0, "Удар ранит сердце.")
	TEST_ASSERT(abs(heart.obj_integrity - (integrity - dealt)) < DAMAGE_PRECISION, "Прочность падает ровно на нанесённый урон.")
	var/obj/effect/temp_visual/heretic_vfx/burst/wound = find_vfx_burst(place, /particles/heretic_ascension/rust/heart_wound, before)
	TEST_ASSERT_NOTNULL(wound, "Раненое сердце роняет горсть хлопьев.")
	TEST_ASSERT_NOTNULL(heart.get_filter(HERETIC_VFX_PULSE_FILTER), "Раненое сердце вздрагивает тёмным контуром.")
	before = list_vfx_bursts(place)
	qdel(heart)
	var/obj/effect/temp_visual/heretic_rust_heart_collapse/collapse = locate() in place
	TEST_ASSERT_NOTNULL(collapse, "Разбитое сердце оседает в пол.")
	var/obj/effect/temp_visual/heretic_vfx/burst/debris = find_vfx_burst(place, /particles/heretic_ascension/rust/collapse, before)
	TEST_ASSERT_NOTNULL(debris, "Разбитое сердце обваливается хлопьями.")
	TEST_ASSERT_NOTNULL(locate(/obj/effect/temp_visual/heretic_vfx/shockwave) in place, "Гибель сердца расходится тёмной волной.")
	TEST_ASSERT_EQUAL(flakes.loc, place, "Последние хлопья догорают на месте сердца.")
	TEST_ASSERT_EQUAL(flakes.particles.spawning, 0, "Разбитое сердце больше не роняет хлопьев.")
	for(var/datum/leftover as anything in list(wound, collapse, debris, flakes))
		TEST_ASSERT(wait_for_qdeleted(leftover, 3 SECONDS), "[leftover.type] гаснет сам.")

/// Вал ржавит пол сразу, а видимая ржавчина расходится кольцом: прежний пол тает позже на дальних клетках.
/datum/unit_test/heretic_rust_wave_visuals/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/list/fixture = ascend_rust_fixture(origin)
	var/mob/living/carbon/human/user = fixture["user"]
	var/datum/eldritch_knowledge/final_eldritch/rust_final/finale = fixture["finale"]
	var/obj/effect/proc_holder/spell/self/rust_corrosive_wave/wave = locate() in finale.ascension_spell_instances
	var/turf/near = locate(origin.x + 1, origin.y, origin.z)
	var/turf/far = locate(origin.x + 3, origin.y, origin.z)
	var/far_state = far.icon_state
	wave.cast(list(user), user)
	near = locate(near.x, near.y, near.z)
	far = locate(far.x, far.y, far.z)
	TEST_ASSERT(istype(far, /turf/open/floor/plating/rust), "Пол ржавеет в момент вала, как и прежде.")
	var/obj/effect/temp_visual/heretic_rust_veil/veil = locate() in far
	TEST_ASSERT_NOTNULL(veil, "Прежний пол держится, пока до клетки не дойдёт волна.")
	TEST_ASSERT_EQUAL(veil.icon_state, far_state, "Покров повторяет прежний пол.")
	TEST_ASSERT_EQUAL(veil.mouse_opacity, MOUSE_OPACITY_TRANSPARENT, "Покров не мешает кликам.")
	TEST_ASSERT_NOTNULL(locate(/obj/effect/temp_visual/heretic_vfx/shockwave) in origin, "От еретика расходится волна ржавчины.")
	TEST_ASSERT_NULL(locate(/obj/effect/temp_visual/heretic_rust_creep) in far, "Дальняя клетка проедается не сразу.")
	var/list/budget = new_wait_budget(1 SECONDS, "ржавчина доходит до дальней клетки")
	while(!(locate(/obj/effect/temp_visual/heretic_rust_creep) in far))
		if(!wait_budget_tick(budget))
			break
	var/obj/effect/temp_visual/heretic_rust_creep/far_creep = locate() in far
	TEST_ASSERT_NOTNULL(far_creep, "Волна доходит до дальней клетки и проедает её.")
	TEST_ASSERT_NOTNULL(locate(/obj/effect/temp_visual/heretic_rust_creep) in near, "Ближняя клетка проедена раньше дальней.")
	TEST_ASSERT(wait_for_qdeleted(veil), "Прежний пол растворяется.")
	TEST_ASSERT(wait_for_qdeleted(far_creep), "Пятна ржавчины гаснут.")

/// Новые эффекты Ржавчины создаются без аргументов и удаляются без ошибок.
/datum/unit_test/heretic_rust_visual_types_create_and_destroy/Run()
	for(var/thing_type in list(/obj/effect/temp_visual/heretic_rust_heart_collapse, /obj/effect/temp_visual/heretic_rust_veil, /obj/effect/temp_visual/heretic_rust_creep))
		var/atom/movable/thing = new thing_type(run_loc_floor_bottom_left)
		qdel(thing)
		TEST_ASSERT(QDELETED(thing), "[thing_type] удаляется без ошибок.")
