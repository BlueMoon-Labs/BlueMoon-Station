/// Хватка Пепла гасит лежащую на полу свечу, оставляет след и засчитывает отдел один раз.
/datum/unit_test/heretic_deed_ash_extinguish/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_ASH)
	var/mob/living/user = heretic.owner.current
	var/datum/heretic_deed/deed = heretic.deed
	var/datum/eldritch_knowledge/base_ash/ash = heretic.get_knowledge(/datum/eldritch_knowledge/base_ash)
	var/turf/place = get_step(run_loc_floor_bottom_left, EAST)
	var/obj/item/candle/candle = allocate(/obj/item/candle, place)
	TEST_ASSERT(!ash.on_mansus_grasp(candle, user, TRUE, null), "Незажжённая свеча не тратит хватку.")
	candle.light()
	TEST_ASSERT(ash.on_mansus_grasp(candle, user, TRUE, null), "Хватка гасит зажжённую свечу.")
	TEST_ASSERT(!candle.lit, "Свеча погашена.")
	TEST_ASSERT_EQUAL(deed.progress, 1, "Погашенное пламя продвигает дело.")
	var/obj/effect/decal/cleanable/heretic_trace/trace = locate() in place
	TEST_ASSERT_NOTNULL(trace, "След остаётся на клетке свечи.")
	allocated += trace
	var/obj/item/candle/second = allocate(/obj/item/candle, get_step(place, EAST))
	second.light()
	COOLDOWN_RESET(deed, progress_cooldown)
	TEST_ASSERT(ash.on_mansus_grasp(second, user, TRUE, null), "Вторая свеча тоже гаснет.")
	TEST_ASSERT(!second.lit, "Вторая свеча погашена.")
	TEST_ASSERT_EQUAL(deed.progress, 1, "Тот же отдел не засчитывается повторно.")
	var/obj/item/candle/held = allocate(/obj/item/candle, user)
	held.light()
	COOLDOWN_RESET(deed, progress_cooldown)
	TEST_ASSERT(!ash.on_mansus_grasp(held, user, TRUE, null), "Свеча в руках не подходит.")
	TEST_ASSERT(held.lit, "Свеча в руках не гаснет.")

/// Хватка Ржавчины засчитывает отдел при первой новой поверхности и молчит на повторных.
/datum/unit_test/heretic_deed_rust_surface/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_RUST)
	var/mob/living/user = heretic.owner.current
	var/datum/heretic_deed/deed = heretic.deed
	heretic.gain_knowledge(/datum/eldritch_knowledge/rust_fist)
	var/datum/eldritch_knowledge/rust_fist/fist = heretic.get_knowledge(/datum/eldritch_knowledge/rust_fist)
	var/turf/first = get_step(run_loc_floor_bottom_left, EAST)
	var/turf/second = get_step(first, EAST)
	TEST_ASSERT(fist.on_mansus_grasp(first, user, TRUE, null), "Хватка покрывает пол ржавчиной.")
	TEST_ASSERT(is_heretic_rust_turf(locate(first.x, first.y, first.z)), "Пол стал ржавым.")
	TEST_ASSERT_EQUAL(deed.progress, 1, "Новая поверхность продвигает дело.")
	var/obj/effect/decal/cleanable/heretic_trace/trace = locate() in locate(first.x, first.y, first.z)
	TEST_ASSERT_NOTNULL(trace, "След остаётся на ржавой клетке.")
	allocated += trace
	COOLDOWN_RESET(deed, progress_cooldown)
	TEST_ASSERT(fist.on_mansus_grasp(second, user, TRUE, null), "Вторая поверхность тоже ржавеет.")
	TEST_ASSERT_EQUAL(deed.progress, 1, "Тот же отдел не засчитывается повторно.")

/// Хватка Плоти поглощает орган даже при полном запасе и считает каждый вид органа один раз.
/datum/unit_test/heretic_deed_flesh_harvest/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_FLESH)
	var/mob/living/user = heretic.owner.current
	var/datum/heretic_deed/deed = heretic.deed
	var/datum/eldritch_knowledge/base_flesh/flesh = heretic.get_knowledge(/datum/eldritch_knowledge/base_flesh)
	var/turf/place = get_step(run_loc_floor_bottom_left, EAST)
	flesh.combat_resource = flesh.combat_resource_max
	var/obj/item/organ/heart/heart = allocate(/obj/item/organ/heart, place)
	TEST_ASSERT(flesh.on_mansus_grasp(heart, user, TRUE, null), "Орган поглощается при полном запасе.")
	TEST_ASSERT(QDELETED(heart), "Поглощённый орган исчезает.")
	TEST_ASSERT_EQUAL(deed.progress, 1, "Первый вид органа продвигает дело.")
	var/obj/effect/decal/cleanable/heretic_trace/trace = locate() in place
	TEST_ASSERT_NOTNULL(trace, "След остаётся на клетке органа.")
	allocated += trace
	var/obj/item/organ/liver/liver = allocate(/obj/item/organ/liver, place)
	COOLDOWN_RESET(deed, progress_cooldown)
	TEST_ASSERT(flesh.on_mansus_grasp(liver, user, TRUE, null), "Второй орган поглощается.")
	TEST_ASSERT_EQUAL(deed.tier, 1, "Два вида органов закрывают первую ступень.")
	TEST_ASSERT_EQUAL(deed.progress, 0, "Прогресс обнуляется на новой ступени.")
	var/obj/item/organ/heart/second_heart = allocate(/obj/item/organ/heart, place)
	COOLDOWN_RESET(deed, progress_cooldown)
	TEST_ASSERT(flesh.on_mansus_grasp(second_heart, user, TRUE, null), "Повторный орган всё равно поглощается.")
	TEST_ASSERT_EQUAL(deed.tier, 1, "Повторный вид органа не продвигает ступень.")
	TEST_ASSERT_EQUAL(deed.progress, 0, "Повторный вид органа не продвигает прогресс.")
