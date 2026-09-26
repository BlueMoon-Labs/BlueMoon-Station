/// Ржавчина принимает обычные покрытия и сохраняет их атмосферу.
/datum/unit_test/heretic_rust_floor_materials/Run()
	var/turf/open/floor/floor = run_loc_floor_bottom_left
	for(var/floor_type in list(/turf/open/floor/plasteel, /turf/open/floor/plating, /turf/open/floor/wood, /turf/open/floor/engine, /turf/open/floor/mineral/titanium, /turf/open/floor/mineral/plastitanium/red))
		floor = floor.ChangeTurf(floor_type)
		floor.air.temperature = 350
		var/pressure_before = floor.air.return_pressure()
		floor = floor.rust_heretic_act()
		TEST_ASSERT(istype(floor, /turf/open/floor/plating/rust), "[floor_type] превращается в ржавый пол.")
		TEST_ASSERT(abs(floor.air.temperature - 350) < 0.01, "Ржавчина сохраняет температуру газа.")
		TEST_ASSERT(abs(floor.air.return_pressure() - pressure_before) < 0.01, "Ржавчина сохраняет давление газа.")
		floor.rust_heretic_act()
		TEST_ASSERT(istype(floor, /turf/open/floor/plating/rust), "Повторное воздействие не разрушает ржавый пол.")

/// Устойчивые покрытия и космос не меняются под действием ржавчины.
/datum/unit_test/heretic_rust_floor_exclusions/Run()
	var/turf/surface = run_loc_floor_bottom_left
	for(var/surface_type in list(/turf/open/floor/grass, /turf/open/floor/mineral/diamond, /turf/open/floor/plasteel/elevated, /turf/open/floor/plasteel/lowered, /turf/open/floor/engine/hull, /turf/open/floor/engine/cult, /turf/open/space, /turf/closed/indestructible))
		surface = surface.ChangeTurf(surface_type)
		surface.rust_heretic_act()
		TEST_ASSERT_EQUAL(surface.type, surface_type, "Защищённая поверхность [surface_type] не меняется.")

/// Хватка на пластитаниуме выдаёт нарост и прогресс дела только за новую поверхность.
/datum/unit_test/heretic_rust_plastitanium_deed/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_RUST)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_rust/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/base_rust)
	knowledge.combat_resource = 0
	var/turf/surface = get_step(user, EAST)
	surface = surface.ChangeTurf(/turf/open/floor/mineral/plastitanium)
	TEST_ASSERT(knowledge.on_mansus_grasp(surface, user, TRUE), "Хватка воздействует на пластитаниум.")
	TEST_ASSERT(istype(surface, /turf/open/floor/plating/rust), "На месте покрытия остаётся ржавый пол.")
	TEST_ASSERT_EQUAL(knowledge.combat_resource, 2, "Новая поверхность даёт нарост за ржавчину и за прогресс дела.")
	TEST_ASSERT_EQUAL(heretic.deed.progress, 1, "Новый отдел продвигает дело.")
	COOLDOWN_RESET(knowledge, resource_harvest)
	COOLDOWN_RESET(heretic.deed, progress_cooldown)
	knowledge.on_mansus_grasp(surface, user, TRUE)
	TEST_ASSERT_EQUAL(knowledge.combat_resource, 2, "Повторное касание не производит ресурс.")
	TEST_ASSERT_EQUAL(heretic.deed.progress, 1, "Повторное касание не продвигает дело.")
	var/turf/another_surface = get_step(user, NORTH)
	another_surface = another_surface.ChangeTurf(/turf/open/floor/mineral/plastitanium)
	knowledge.on_mansus_grasp(another_surface, user, TRUE)
	TEST_ASSERT_EQUAL(knowledge.combat_resource, 3, "Ещё одна поверхность в том же отделе даёт только нарост за ржавчину.")
	TEST_ASSERT_EQUAL(heretic.deed.progress, 1, "В том же отделе дело повторно не засчитывается.")

/// Неподходящий пол сохраняет нарост, семя и ранее созданный очаг.
/datum/unit_test/heretic_rust_root_placement/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_RUST)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_rust/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/base_rust)
	var/obj/effect/proc_holder/spell/self/heretic_power/rust/power = knowledge.combat_power
	knowledge.combat_resource = 2
	power.cast(list(user), user)
	var/obj/effect/heretic_combat_zone/rust/zone = knowledge.combat_zone
	TEST_ASSERT(zone, "Подходящий пол принимает очаг.")
	STOP_PROCESSING(SSprocessing, zone)
	TEST_ASSERT_EQUAL(knowledge.combat_resource, 1, "Очаг расходует один нарост.")
	var/turf/floor = get_turf(user)
	floor.ChangeTurf(/turf/open/floor/grass)
	TEST_ASSERT(!power.can_cast(user, TRUE, TRUE), "Укоренение отклоняет неподходящий пол заранее.")
	power.cast(list(user), user)
	TEST_ASSERT_EQUAL(knowledge.combat_resource, 1, "Повторная проверка до расходования сохраняет нарост.")
	TEST_ASSERT_EQUAL(knowledge.combat_zone, zone, "Неудачная попытка не удаляет действующий очаг.")
	var/obj/item/heretic_relic/rust_seed/seed = allocate(/obj/item/heretic_relic/rust_seed)
	user.put_in_hands(seed)
	TEST_ASSERT(!seed.plant(user), "Семя не сажается в неподходящий пол.")
	TEST_ASSERT(!QDELETED(seed), "Неудачная посадка сохраняет семя.")
	TEST_ASSERT_EQUAL(knowledge.combat_resource, 1, "Неудачная посадка не расходует нарост.")

/// Граница очага совпадает с лечебными клетками и обновляется после замены пола.
/datum/unit_test/heretic_rust_field_and_healing/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_RUST)
	var/mob/living/user = heretic.owner.current
	var/turf/center = get_turf(user)
	center = center.ChangeTurf(/turf/open/floor/mineral/plastitanium)
	var/turf/metal = get_step(center, EAST)
	metal = metal.ChangeTurf(/turf/open/floor/mineral/titanium)
	var/turf/grass = get_step(center, NORTH)
	grass = grass.ChangeTurf(/turf/open/floor/grass)
	var/obj/effect/heretic_combat_zone/rust/zone = allocate(/obj/effect/heretic_combat_zone/rust, center, heretic.owner)
	STOP_PROCESSING(SSprocessing, zone)
	user.adjustBruteLoss(20)
	zone.tick_zone(user, list(center, metal, grass, user))
	TEST_ASSERT(istype(center, /turf/open/floor/plating/rust), "Очаг ржавит пол под хозяином.")
	TEST_ASSERT_EQUAL(grass.type, /turf/open/floor/grass, "Неподходящая клетка сохраняется.")
	TEST_ASSERT_EQUAL(length(zone.field_turfs), 2, "Граница охватывает только два ржавых пола.")
	TEST_ASSERT(!(grass in zone.field_turfs), "Трава не обещает лечение.")
	TEST_ASSERT(abs(user.getBruteLoss() - 17) < DAMAGE_PRECISION, "Хозяин получает обычное лечение очага.")
	for(var/obj/effect/heretic_field_edge/edge as anything in zone.boundary)
		TEST_ASSERT(edge.loc in zone.field_turfs, "Каждый край стоит на лечебной клетке.")
	center = center.ChangeTurf(/turf/open/floor/grass)
	zone.tick_zone(user, list(center, metal, grass, user))
	TEST_ASSERT(!(center in zone.field_turfs), "Заменённая поверхность исключается из границы.")
	TEST_ASSERT(abs(user.getBruteLoss() - 17) < DAMAGE_PRECISION, "На траве очаг больше не лечит.")
	center = center.ChangeTurf(/turf/open/floor/mineral/plastitanium)
	zone.tick_zone(user, list(center, metal, grass, user))
	TEST_ASSERT(istype(center, /turf/open/floor/plating/rust), "Очаг обрабатывает заново уложенное покрытие.")
	TEST_ASSERT(abs(user.getBruteLoss() - 14) < DAMAGE_PRECISION, "На восстановленном ржавом полу лечение возвращается.")

/// Индикатор различает пол и очаг, следует движению и очищается при смене тела.
/datum/unit_test/heretic_rust_healing_hud/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_RUST)
	var/mob/living/user = heretic.owner.current
	heretic.apply_innate_effects(user)
	var/datum/eldritch_knowledge/base_rust/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/base_rust)
	var/datum/heretic_innate/rust/innate = knowledge.innate
	innate.update_healing_alert()
	var/atom/movable/screen/alert/heretic_rust_healing/indicator = user.alerts["heretic_rust_healing"]
	TEST_ASSERT(indicator, "Выбранный путь показывает состояние лечения.")
	TEST_ASSERT_EQUAL(indicator.healing_state, "inactive", "Обычный пол не лечит.")
	var/turf/rust = get_step(user, EAST)
	rust = rust.rust_heretic_act()
	user.forceMove(rust)
	TEST_ASSERT_EQUAL(indicator.healing_state, "floor", "Перемещение сразу показывает лечение пола.")
	var/obj/effect/heretic_combat_zone/rust/zone = allocate(/obj/effect/heretic_combat_zone/rust, rust, heretic.owner)
	STOP_PROCESSING(SSprocessing, zone)
	knowledge.combat_zone = zone
	knowledge.track_combat_effect(zone)
	zone.tick_zone(user, list(rust, user))
	innate.update_healing_alert()
	TEST_ASSERT_EQUAL(indicator.healing_state, "grove", "Свой очаг усиливает лечение пола.")
	qdel(zone)
	innate.update_healing_alert()
	TEST_ASSERT_EQUAL(indicator.healing_state, "floor", "Удаление очага оставляет только лечение пола.")
	var/mob/living/carbon/human/new_body = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	heretic.owner.transfer_to(new_body, TRUE)
	TEST_ASSERT_NULL(user.alerts["heretic_rust_healing"], "Покинутое тело теряет индикатор.")
	innate.update_healing_alert()
	TEST_ASSERT(new_body.alerts["heretic_rust_healing"], "Новое тело получает собственное состояние.")
	heretic.clear_heretic()
	TEST_ASSERT_NULL(new_body.alerts["heretic_rust_healing"], "Снятие роли убирает индикатор.")

/// Поглощённая Хватка расходует одну защиту и руку, не нанося урон и метку.
/datum/unit_test/heretic_grasp_blocked_result/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_RUST)
	var/mob/living/user = heretic.owner.current
	heretic.gain_knowledge(/datum/eldritch_knowledge/rust_mark)
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	var/datum/component/anti_magic/protection = victim.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5)
	var/obj/effect/proc_holder/spell/targeted/touch/mansus_grasp/spell = allocate(/obj/effect/proc_holder/spell/targeted/touch/mansus_grasp)
	TEST_ASSERT(spell.ChargeHand(user), "Хватка создаёт привязанную руку.")
	var/obj/item/melee/touch_attack/mansus_fist/hand = spell.attached_hand
	hand.afterattack(victim, user, TRUE)
	TEST_ASSERT(QDELETED(hand), "Антимагия расходует хватку.")
	TEST_ASSERT_EQUAL(protection.charges, 4, "Расходуется один заряд антимагии.")
	TEST_ASSERT_EQUAL(victim.getBruteLoss(), 0, "Защита блокирует ушибы.")
	TEST_ASSERT_EQUAL(victim.getStaminaLoss(), 0, "Защита блокирует урон выносливости.")
	TEST_ASSERT(!victim.has_status_effect(/datum/status_effect/eldritch/rust), "Защита блокирует метку.")

/// Мерзкая хватка ржавит поддающиеся полы 3×3 вокруг врага и не трогает клетки дальше.
/datum/unit_test/heretic_rust_vile_grasp_area/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	heretic.gain_knowledge(/datum/eldritch_knowledge/rust_fist_upgrade)
	var/datum/eldritch_knowledge/rust_fist_upgrade/vile = heretic.get_knowledge(/datum/eldritch_knowledge/rust_fist_upgrade)
	var/turf/center = locate(run_loc_floor_bottom_left.x + 2, run_loc_floor_bottom_left.y + 2, run_loc_floor_bottom_left.z)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, center)
	var/turf/grass = get_step(center, NORTH)
	grass = grass.ChangeTurf(/turf/open/floor/grass)
	var/turf/outside = locate(center.x + 2, center.y, center.z)
	TEST_ASSERT(vile.on_mansus_grasp(victim, user, TRUE, null), "Хватка действует на врага.")
	var/rusted = 0
	for(var/turf/tile as anything in RANGE_TURFS(1, center))
		if(istype(tile, /turf/open/floor/plating/rust))
			rusted++
	TEST_ASSERT_EQUAL(rusted, 8, "Ржавеют все восемь поддающихся клеток 3×3.")
	TEST_ASSERT_EQUAL(grass.type, /turf/open/floor/grass, "Трава не ржавеет.")
	TEST_ASSERT(!istype(outside, /turf/open/floor/plating/rust), "Клетка за пределами 3×3 не ржавеет.")
	var/turf/far_floor = run_loc_floor_top_right
	var/mob/living/carbon/human/protected = allocate(/mob/living/carbon/human, far_floor)
	protected.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5)
	TEST_ASSERT(!vile.on_mansus_grasp(protected, user, TRUE, null), "Антимагия отражает хватку.")
	TEST_ASSERT(!istype(far_floor, /turf/open/floor/plating/rust), "Под защищённым врагом пол не ржавеет.")

/// Каждый вариант руны ржавчины есть в DMI, иначе руна невидима.
/datum/unit_test/heretic_rust_rune_states/Run()
	var/obj/effect/temp_visual/glowing_rune/rune = allocate(/obj/effect/temp_visual/glowing_rune)
	var/list/states = icon_states(rune.icon)
	for(var/i in 1 to rune.rune_variants)
		TEST_ASSERT("small_rune_[i]" in states, "Стейт small_rune_[i] существует.")
	TEST_ASSERT(rune.icon_state in states, "Выбранный стейт руны существует.")
