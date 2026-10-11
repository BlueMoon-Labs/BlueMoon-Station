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

/// Заряд Длани покровителя гаснет о святой арбуз в руке, как прочая магия еретика.
/datum/unit_test/heretic_rust_bolt_anti_magic/Run()
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/obj/item/projectile/magic/spell/rust_wave/bolt = allocate(/obj/item/projectile/magic/spell/rust_wave, run_loc_floor_top_right)
	TEST_ASSERT_NOTEQUAL(bolt.prehit_pierce(victim), PROJECTILE_DELETE_WITHOUT_HITTING, "Без защиты заряд попадает.")
	var/obj/item/reagent_containers/food/snacks/grown/holymelon/melon = allocate(/obj/item/reagent_containers/food/snacks/grown/holymelon)
	TEST_ASSERT(victim.put_in_active_hand(melon), "Жертва берёт святой арбуз.")
	TEST_ASSERT_EQUAL(bolt.prehit_pierce(victim), PROJECTILE_DELETE_WITHOUT_HITTING, "Святой арбуз в руке гасит заряд.")

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

/datum/unit_test/proc/rust_roots_fixture(list/out)
	var/turf/start = run_loc_floor_bottom_left
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_RUST)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/rust_roots)
	var/datum/eldritch_knowledge/base_rust/rust = heretic.get_knowledge(/datum/eldritch_knowledge/base_rust)
	var/turf/spot = locate(start.x + 2, start.y + 2, start.z)
	spot = spot.ChangeTurf(/turf/open/floor/plating/rust)
	var/mob/living/carbon/human/victim = allocate_hunt_victim(heretic, spot)
	out["heretic"] = heretic
	out["rust"] = rust
	out["spot"] = spot
	out["victim"] = victim
	out["hearth"] = oldpath_door_zone(rust, /obj/effect/heretic_combat_zone/rust, spot, heretic.owner.current)

/datum/unit_test/proc/await_rust_roots(mob/living/victim)
	var/list/budget = new_wait_budget(3 SECONDS, "ржавые корни на [victim]")
	while(!victim.has_status_effect(/datum/status_effect/heretic_rust_roots))
		if(!wait_budget_tick(budget))
			break
	return victim.has_status_effect(/datum/status_effect/heretic_rust_roots)

/// Ржавые корни: отказ стоящей цели, цели вне очага и не на ржавчине; секунду корни ползут, затем до 10 секунд держат готовую неподвижную цель; лом рвёт их за 2 секунды, потом цель невосприимчива.
/datum/unit_test/heretic_rust_roots_capture/Run()
	var/list/fixture = list()
	rust_roots_fixture(fixture)
	var/datum/antagonist/heretic/heretic = fixture["heretic"]
	var/datum/eldritch_knowledge/base_rust/rust = fixture["rust"]
	var/turf/spot = fixture["spot"]
	var/mob/living/carbon/human/victim = fixture["victim"]
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/spell/rust_roots/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/spell/rust_roots)
	TEST_ASSERT(istype(knowledge.granted_spell, /obj/effect/proc_holder/spell/pointed/rust_roots), "Знание выдаёт заклинание корней.")
	TEST_ASSERT(findtext(rust.roots_block_reason(user, victim), "сбитую"), "Стоящая цель не врастает.")
	victim.DefaultCombatKnockdown(5 SECONDS, override_stamdmg = 0)
	var/turf/bare = get_step(spot, NORTH)
	victim.forceMove(bare)
	TEST_ASSERT(findtext(rust.roots_block_reason(user, victim), "ржавого пола"), "Нержавый пол корней не даёт.")
	victim.forceMove(spot)
	QDEL_NULL(rust.combat_zone)
	TEST_ASSERT(findtext(rust.roots_block_reason(user, victim), "очага"), "Без очага корни не растут.")
	oldpath_door_zone(rust, /obj/effect/heretic_combat_zone/rust, spot, user)
	TEST_ASSERT_NULL(rust.roots_block_reason(user, victim), "Сбитая цель на ржавчине своего очага подходит.")
	TEST_ASSERT(rust.start_roots(user, victim), "Корни начинают расти.")
	TEST_ASSERT_NULL(victim.has_status_effect(/datum/status_effect/heretic_rust_roots), "Секунду корни только ползут.")
	TEST_ASSERT_NOTNULL(locate(/obj/effect/temp_visual/heretic_rust_roots_sprout) in spot, "Ползущие корни видно заранее.")
	var/datum/status_effect/heretic_rust_roots/roots = await_rust_roots(victim)
	TEST_ASSERT_NOTNULL(roots, "Через секунду цель врастает в пол.")
	var/remaining = roots.duration - world.time
	TEST_ASSERT(remaining < HERETIC_RUST_ROOTS_DURATION + 1 && remaining > HERETIC_RUST_ROOTS_DURATION - 1 SECONDS, "Корни держат 10 секунд: осталось [remaining] дс.")
	TEST_ASSERT(victim.IsParalyzed(), "Вросшая цель не действует.")
	TEST_ASSERT(victim.anchored, "Вросшую цель не сдвинуть.")
	TEST_ASSERT(HAS_TRAIT(victim, TRAIT_HERETIC_CAPTURE_HOLD), "Корни - захват по общему каркасу.")
	TEST_ASSERT(heretic.hunt_target_ready(victim), "Вросшая цель готова к обряду.")
	var/obj/effect/abstract/heretic_vfx_attached/visual = roots.roots_visual
	TEST_ASSERT(visual && (visual in victim.vis_contents), "Корни видны на ногах цели.")
	TEST_ASSERT(visual.vis_flags & VIS_INHERIT_DIR, "Корни поворачиваются вместе с целью.")
	TEST_ASSERT(visual.icon_state in icon_states(visual.icon), "Стейт роста корней есть в листе.")
	TEST_ASSERT("rust_roots" in icon_states(visual.icon), "Стейт удержания корней есть в листе.")
	var/mob/living/carbon/human/crew = allocate(/mob/living/carbon/human, get_step(spot, EAST))
	crew.start_pulling(victim)
	TEST_ASSERT(crew.pulling != victim, "Экипаж не утащит вросшую цель.")
	var/obj/item/crowbar/crowbar = allocate(/obj/item/crowbar)
	crew.put_in_hands(crowbar)
	TEST_ASSERT(roots.pry(crew, crowbar), "Лом рвёт корни за 2 секунды.")
	TEST_ASSERT(QDELETED(roots), "Корни сорваны.")
	TEST_ASSERT(!victim.IsParalyzed(), "Освобождённая цель снова действует.")
	TEST_ASSERT(!victim.anchored, "Освобождённую цель снова можно сдвинуть.")
	TEST_ASSERT(!HAS_TRAIT(victim, TRAIT_HERETIC_CAPTURE_HOLD), "Захват снят.")
	TEST_ASSERT(findtext(heretic_capture_block_reason(user, victim, HERETIC_RUST_CAPTURE), "приходит в себя"), "После корней цель невосприимчива к ним.")
	TEST_ASSERT(!length(rust.roots), "Знание забывает сорванные корни.")

/// Пленника корней сердце уводит из любой клетки того же очага, без корней - только вплотную; с клетки вне очага увода нет, перенос цели снимает корни.
/datum/unit_test/heretic_rust_roots_door/Run()
	var/list/fixture = list()
	rust_roots_fixture(fixture)
	var/datum/antagonist/heretic/heretic = fixture["heretic"]
	var/datum/eldritch_knowledge/base_rust/rust = fixture["rust"]
	var/turf/spot = fixture["spot"]
	var/mob/living/carbon/human/victim = fixture["victim"]
	var/obj/effect/heretic_combat_zone/rust/hearth = fixture["hearth"]
	var/mob/living/carbon/human/user = heretic.owner.current
	var/turf/far_rust = locate(spot.x, spot.y + 2, spot.z)
	far_rust = far_rust.ChangeTurf(/turf/open/floor/plating/rust)
	hearth.refresh_boundary(block(locate(spot.x - 2, spot.y - 2, spot.z), locate(spot.x + 2, spot.y + 2, spot.z)))
	TEST_ASSERT(far_rust in hearth.field_turfs, "Дальняя ржавая клетка в границе очага.")
	user.forceMove(far_rust)
	victim.DefaultCombatKnockdown(5 SECONDS, override_stamdmg = 0)
	TEST_ASSERT_NULL(rust.pocket_door(user, victim), "Без корней очаг уводит только вплотную.")
	var/datum/status_effect/heretic_rust_roots/roots = victim.apply_status_effect(/datum/status_effect/heretic_rust_roots, rust, hearth)
	TEST_ASSERT_NOTNULL(roots, "Цель вросла.")
	var/list/door = rust.pocket_door(user, victim)
	TEST_ASSERT_NOTNULL(door, "Пленника корней уводят из любой клетки очага.")
	TEST_ASSERT(door["remote"], "Дверь корней открывается сжатым сердцем издалека.")
	TEST_ASSERT_EQUAL(door["time"], HERETIC_POCKET_PULL_TIME, "Увод занимает 1 секунду.")
	var/datum/callback/check = door["check"]
	user.forceMove(locate(spot.x + 2, spot.y + 2, spot.z))
	TEST_ASSERT(!check.Invoke(), "С клетки вне очага увод срывается.")
	TEST_ASSERT_NULL(rust.pocket_door(user, victim), "Вне очага двери нет.")
	user.forceMove(far_rust)
	TEST_ASSERT(check.Invoke(), "С клетки очага увод держится.")
	victim.forceMove(get_step(spot, WEST))
	TEST_ASSERT(QDELETED(roots), "Сдвинутая с клетки цель выходит из корней.")

/// Корни рвут нулевой жезл, «растолкать» и гибель очага; ушедшая на телеграфе цель возвращает перезарядку.
/datum/unit_test/heretic_rust_roots_counters/Run()
	var/list/fixture = list()
	rust_roots_fixture(fixture)
	var/datum/antagonist/heretic/heretic = fixture["heretic"]
	var/datum/eldritch_knowledge/base_rust/rust = fixture["rust"]
	var/turf/spot = fixture["spot"]
	var/mob/living/carbon/human/victim = fixture["victim"]
	var/obj/effect/heretic_combat_zone/rust/hearth = fixture["hearth"]
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/status_effect/heretic_rust_roots/roots = victim.apply_status_effect(/datum/status_effect/heretic_rust_roots, rust, hearth)
	var/mob/living/carbon/human/crew = allocate(/mob/living/carbon/human, get_step(spot, EAST))
	var/obj/item/nullrod/rod = allocate(/obj/item/nullrod)
	crew.put_in_hands(rod)
	rod.melee_attack_chain(crew, victim)
	TEST_ASSERT(QDELETED(roots), "Нулевой жезл рассыпает корни.")
	TEST_ASSERT_EQUAL(victim.getBruteLoss(), 0, "Жезл не бьёт пленника.")
	victim.remove_status_effect(/datum/status_effect/heretic_capture_immunity)
	roots = victim.apply_status_effect(/datum/status_effect/heretic_rust_roots, rust, hearth)
	SEND_SIGNAL(victim, COMSIG_LIVING_HERETIC_CAPTURE_SHAKEN, crew)
	TEST_ASSERT(QDELETED(roots), "Растолкать - значит сорвать корни.")
	roots = victim.apply_status_effect(/datum/status_effect/heretic_rust_roots, rust, hearth)
	qdel(hearth)
	TEST_ASSERT(QDELETED(roots), "Угасший очаг отпускает пленника.")
	hearth = oldpath_door_zone(rust, /obj/effect/heretic_combat_zone/rust, spot, user)
	roots = victim.apply_status_effect(/datum/status_effect/heretic_rust_roots, rust, hearth)
	rust.on_death(user)
	TEST_ASSERT(QDELETED(roots), "Смерть еретика обрывает корни.")
	victim.remove_status_effect(/datum/status_effect/heretic_capture_immunity)
	var/datum/eldritch_knowledge/spell/rust_roots/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/spell/rust_roots)
	var/obj/effect/proc_holder/spell/pointed/rust_roots/spell = knowledge.granted_spell
	victim.DefaultCombatKnockdown(5 SECONDS, override_stamdmg = 0)
	spell.charge_counter = 0
	spell.recharging = TRUE
	TEST_ASSERT(rust.start_roots(user, victim), "Корни ползут к цели.")
	victim.forceMove(get_step(spot, NORTH))
	var/list/budget = new_wait_budget(3 SECONDS, "возврат перезарядки корней")
	while(spell.charge_counter < spell.charge_max)
		if(!wait_budget_tick(budget))
			break
	TEST_ASSERT(spell.charge_counter >= spell.charge_max, "Ушедшая с клетки цель возвращает перезарядку корней.")
	TEST_ASSERT_NULL(victim.has_status_effect(/datum/status_effect/heretic_rust_roots), "Ушедшая цель не врастает.")
	TEST_ASSERT(isfile(GLOB.heretic_capture_latch_sounds[HERETIC_RUST_CAPTURE]), "У корней свой звук защёлкивания.")
	TEST_ASSERT_EQUAL(heretic_fx_capture_path(victim, HERETIC_RUST_CAPTURE), PATH_RUST, "Метка захвата корней относится к Ржавчине.")

/// Ржавая формация встаёт только из ржавого пола, отбрасывает и роняет врага, пропускает еретика и разбирается ломом за 2 секунды.
/datum/unit_test/heretic_rust_formation/Run()
	var/turf/start = run_loc_floor_bottom_left
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_RUST)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/rust_formation)
	var/datum/eldritch_knowledge/spell/rust_formation/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/spell/rust_formation)
	TEST_ASSERT(istype(knowledge.granted_spell, /obj/effect/proc_holder/spell/pointed/rust_formation), "Знание выдаёт Ржавую формацию.")
	var/mob/living/carbon/human/user = heretic.owner.current
	var/turf/place = locate(start.x + 2, start.y, start.z)
	TEST_ASSERT(findtext(heretic_rust_formation_block_reason(user, place), "ржавого пола"), "Обычный пол стену не даёт.")
	place = place.ChangeTurf(/turf/open/floor/plating/rust)
	var/mob/living/carbon/human/crew = allocate(/mob/living/carbon/human, place)
	TEST_ASSERT_NULL(heretic_rust_formation_block_reason(user, place), "Ржавый пол в двух клетках подходит.")
	var/obj/structure/heretic_rust_formation/wall = heretic_rust_raise_formation(user, place)
	TEST_ASSERT(istype(wall) && wall.loc == place, "Из пола встаёт глыба.")
	TEST_ASSERT(wall.density && wall.opacity, "Глыба плотная и закрывает обзор.")
	TEST_ASSERT(crew.loc != place && get_dist(crew, place) == 1, "Врага отбрасывает на соседнюю клетку.")
	TEST_ASSERT(crew.IsKnockdown(), "Отброшенный враг падает.")
	TEST_ASSERT_EQUAL(crew.getBruteLoss(), HERETIC_RUST_FORMATION_DAMAGE, "Глыба бьёт на 10 ушибов.")
	TEST_ASSERT(wall.CanPass(user, place), "Еретик проходит сквозь свою стену.")
	TEST_ASSERT(!wall.CanPass(crew, place), "Экипаж сквозь стену не пройдёт.")
	TEST_ASSERT(findtext(heretic_rust_formation_block_reason(user, place), "занимает"), "Вторая стена на ту же клетку не встаёт.")
	for(var/state in list("rust_formation", "rust_formation_rise", "rust_formation_fall"))
		TEST_ASSERT(state in icon_states(wall.icon), "Стейт [state] есть в листе.")
	var/obj/item/crowbar/crowbar = allocate(/obj/item/crowbar)
	crew.SetKnockdown(0)
	crew.put_in_hands(crowbar)
	TEST_ASSERT(wall.pry(crew, crowbar), "Лом разбирает глыбу за 2 секунды.")
	TEST_ASSERT(QDELETED(wall), "Глыба разобрана.")
	TEST_ASSERT_NOTNULL(locate(/obj/effect/temp_visual/heretic_rust_formation_fall) in place, "Глыба осыпается видимой трухой.")

/// Ржавый пол показывает разъедаемому алерт и пыль у ног, сход с пола снимает и то, и другое.
/datum/unit_test/heretic_rust_floor_feedback/Run()
	var/turf/open/floor/floor = run_loc_floor_bottom_left
	floor = floor.rust_heretic_act()
	var/turf/clean = get_step(floor, EAST)
	var/mob/living/carbon/human/crew = allocate(/mob/living/carbon/human, clean)
	crew.forceMove(floor)
	var/datum/status_effect/rust_corruption/corrosion = crew.has_status_effect(/datum/status_effect/rust_corruption)
	TEST_ASSERT_NOTNULL(corrosion, "Ржавый пол разъедает чужака.")
	TEST_ASSERT(istype(corrosion.linked_alert, /atom/movable/screen/alert/status_effect/heretic_rust_corrosion), "Экипаж видит алерт ржавого пола.")
	TEST_ASSERT(corrosion.linked_alert.icon_state in icon_states(corrosion.linked_alert.icon), "Значок алерта есть в листе.")
	var/obj/effect/abstract/heretic_particle_holder/dust = corrosion.dust
	TEST_ASSERT(dust && (dust in crew.vis_contents), "У ног разъедаемого поднимается ржавая пыль.")
	crew.forceMove(clean)
	TEST_ASSERT_NULL(crew.has_status_effect(/datum/status_effect/rust_corruption), "Сход с пола снимает разъедание.")
	TEST_ASSERT(!(dust in crew.vis_contents), "Пыль остаётся на месте и гаснет.")
	TEST_ASSERT_NULL(crew.alerts["rust_turf_effects"], "Алерт снят.")

/// Ржавая поступь: на ржавчине урон выносливости слабее, второй уровень закрывает раны, третий заживляет органы и отращивает конечность.
/datum/unit_test/heretic_rust_regen_behaviors/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_RUST)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/original_mod = user.physiology.heretic_stamina_mod
	heretic.gain_knowledge(/datum/eldritch_knowledge/rust_regen)
	var/datum/eldritch_knowledge/rust_regen/regen = heretic.get_knowledge(/datum/eldritch_knowledge/rust_regen)
	TEST_ASSERT(abs(user.physiology.heretic_stamina_mod - original_mod) < 0.001, "Вне ржавчины урон выносливости прежний.")
	var/turf/rust = get_step(user, EAST)
	rust = rust.ChangeTurf(/turf/open/floor/plating/rust)
	var/turf/plain = get_turf(user)
	user.forceMove(rust)
	TEST_ASSERT(abs(user.physiology.heretic_stamina_mod - original_mod * HERETIC_RUST_FOOTING_STAMINA_MOD) < 0.001, "На ржавчине урон выносливости слабее.")
	user.forceMove(plain)
	TEST_ASSERT(abs(user.physiology.heretic_stamina_mod - original_mod) < 0.001, "Сход с ржавчины возвращает урон выносливости.")
	user.forceMove(rust)
	regen.passive_level = 2
	var/obj/item/bodypart/arm = user.get_bodypart(BODY_ZONE_L_ARM)
	var/datum/wound/slash/moderate/wound = new
	wound.apply_wound(arm)
	arm.generic_bleedstacks = 5
	regen.on_life(user)
	TEST_ASSERT(!(wound in arm.wounds), "Второй уровень закрывает рану.")
	TEST_ASSERT_EQUAL(arm.generic_bleedstacks, 0, "Второй уровень останавливает кровотечение.")
	regen.passive_level = 3
	var/obj/item/organ/liver/liver = user.getorganslot(ORGAN_SLOT_LIVER)
	liver.applyOrganDamage(10)
	var/obj/item/bodypart/leg = user.get_bodypart(BODY_ZONE_R_LEG)
	leg.drop_limb()
	qdel(leg)
	regen.on_life(user)
	TEST_ASSERT(liver.damage < 10, "Третий уровень заживляет органы.")
	TEST_ASSERT_NOTNULL(user.get_bodypart(BODY_ZONE_R_LEG), "Третий уровень отращивает конечность.")
	regen.on_body_lose(user)
	TEST_ASSERT(abs(user.physiology.heretic_stamina_mod - original_mod) < 0.001, "Покинутое тело не сохраняет защиту выносливости.")

/// Очаг без медальона: в центре свой нарост, новые клетки проедает ржавчина, а метка, хватка и звуки пути - свои.
/datum/unit_test/heretic_rust_own_assets/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_RUST)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/turf/center = get_turf(user)
	var/turf/metal = get_step(center, EAST)
	metal = metal.ChangeTurf(/turf/open/floor/plasteel)
	var/obj/effect/heretic_combat_zone/rust/zone = allocate(/obj/effect/heretic_combat_zone/rust, center, heretic.owner)
	STOP_PROCESSING(SSprocessing, zone)
	TEST_ASSERT(zone.icon_state in icon_states(zone.icon), "У очага свой живой нарост.")
	TEST_ASSERT_EQUAL(zone.alpha, 255, "Нарост не полупрозрачный.")
	zone.tick_zone(user, list(center, metal, user))
	metal = get_step(center, EAST)
	TEST_ASSERT(istype(metal, /turf/open/floor/plating/rust), "Очаг ржавит соседний пол.")
	TEST_ASSERT_NOTNULL(locate(/obj/effect/temp_visual/heretic_rust_creep) in metal, "Новую клетку проедает ржавчина, а не медальон.")
	var/obj/effect/temp_visual/heretic_oldpath/rust/bloom = allocate(/obj/effect/temp_visual/heretic_oldpath/rust, center)
	TEST_ASSERT(bloom.icon_state in icon_states(bloom.icon), "Вспышка ржавчины есть в листе.")
	var/datum/eldritch_knowledge/base_rust/rust = heretic.get_knowledge(/datum/eldritch_knowledge/base_rust)
	TEST_ASSERT(rust.grasp_sound in GLOB.heretic_rust_grasp_sounds, "Хватка звучит своим скрежетом.")
	rust.on_mansus_grasp(center, user, FALSE)
	TEST_ASSERT(rust.grasp_sound in GLOB.heretic_rust_grasp_sounds, "Следующая хватка берёт звук из набора.")
	var/obj/item/melee/touch_attack/grasp_of_decay/hand = allocate(/obj/item/melee/touch_attack/grasp_of_decay)
	TEST_ASSERT(hand.icon_state in icon_states(hand.icon), "У Хватки распада своя рука.")
	TEST_ASSERT(hand.icon_state != "mansus_grasp", "Рука распада не повторяет Хватку Мансуса.")
	TEST_ASSERT(hand.item_state in icon_states(hand.lefthand_file), "Рука распада видна в левой руке.")
	TEST_ASSERT(hand.item_state in icon_states(hand.righthand_file), "Рука распада видна в правой руке.")
	for(var/spell_type in list(/obj/effect/proc_holder/spell/targeted/touch/grasp_of_decay, /obj/effect/proc_holder/spell/pointed/rust_roots, /obj/effect/proc_holder/spell/pointed/rust_formation))
		var/obj/effect/proc_holder/spell/spell = spell_type
		TEST_ASSERT(initial(spell.action_icon_state) in icon_states(initial(spell.action_icon)), "У [spell_type] свой значок.")
	TEST_ASSERT(initial(hand.icon_state) != "mansus_grasp", "Значок распада свой.")
	var/obj/effect/proc_holder/spell/targeted/touch/grasp_of_decay/decay = /obj/effect/proc_holder/spell/targeted/touch/grasp_of_decay
	TEST_ASSERT(initial(decay.action_icon_state) != "mansus_grasp", "Кнопка распада не повторяет Хватку Мансуса.")

/// Ступени Ржавчины: корни - захват на четвёртой ступени, формация - уход, имена знаний совпадают с кнопками, тексты называют числа из кода.
/datum/unit_test/heretic_rust_codex_layout/Run()
	var/datum/heretic_path/path = GLOB.heretic_paths[PATH_RUST]
	TEST_ASSERT_EQUAL(path.knowledge[4], /datum/eldritch_knowledge/spell/rust_roots, "Захват корнями на четвёртой ступени.")
	var/datum/eldritch_knowledge/spell/rust_roots/roots = allocate(/datum/eldritch_knowledge/spell/rust_roots)
	TEST_ASSERT_EQUAL(roots.role, HERETIC_ROLE_CAPTURE, "Корни - захват пути.")
	var/datum/eldritch_knowledge/spell/rust_formation/formation = allocate(/datum/eldritch_knowledge/spell/rust_formation)
	TEST_ASSERT_EQUAL(formation.role, HERETIC_ROLE_ESCAPE, "Формация - уход пути.")
	for(var/knowledge_type in list(/datum/eldritch_knowledge/spell/area_conversion, /datum/eldritch_knowledge/spell/rust_wave, /datum/eldritch_knowledge/spell/rust_roots, /datum/eldritch_knowledge/spell/rust_formation))
		var/datum/eldritch_knowledge/spell/knowledge = allocate(knowledge_type)
		var/obj/effect/proc_holder/spell/spell = knowledge.spell_to_add
		TEST_ASSERT_EQUAL(knowledge.name, initial(spell.name), "Знание [knowledge_type] называется как его кнопка.")
	var/list/facts = list(
		list(roots.desc, "в [HERETIC_RUST_ROOTS_RANGE] клетках", "[HERETIC_RUST_ROOTS_DURATION / (1 SECONDS)] секунд", "за [HERETIC_RUST_PRY_TIME / (1 SECONDS)] секунды", "Перезарядка [HERETIC_RUST_ROOTS_COOLDOWN / (1 SECONDS)] секунд"),
		list(formation.desc, "в [HERETIC_RUST_FORMATION_RANGE] клетках", "стоит [HERETIC_RUST_FORMATION_LIFETIME / (1 SECONDS)] секунд", "[HERETIC_RUST_FORMATION_DAMAGE] ушибов", "Перезарядка [HERETIC_RUST_FORMATION_COOLDOWN / (1 SECONDS)] секунд"),
		list(path.capture_summary, "в изнанку", "[HERETIC_RUST_ROOTS_DURATION / (1 SECONDS)] секунд", "из любой клетки очага"),
		list(heretic_codex_text(/datum/eldritch_knowledge/base_rust), "[HERETIC_RUST_FLOOR_CORROSION] урона коррозией в секунду"),
		list(heretic_codex_text(/datum/eldritch_knowledge/rust_mark), "[HERETIC_RUST_BLADE_CORROSION] урона коррозией"),
		list(heretic_codex_text(/datum/eldritch_knowledge/rust_regen), "[round((1 - HERETIC_RUST_FOOTING_STAMINA_MOD) * 100)]%", "раз в [HERETIC_RUST_MEND_WOUND_INTERVAL / (1 SECONDS)] секунд", "раз в [HERETIC_RUST_MEND_LIMB_INTERVAL / (1 SECONDS)] секунд"),
	)
	for(var/list/fact_line as anything in facts)
		for(var/index in 2 to length(fact_line))
			TEST_ASSERT(findtext(fact_line[1], fact_line[index]), "Текст называет «[fact_line[index]]»: [fact_line[1]]")
	var/datum/heretic_innate/rust/innate = allocate(/datum/heretic_innate/rust)
	TEST_ASSERT(!findtext(innate.desc, "не отравляет"), "Врождённая черта не обещает безвредный пол.")
	TEST_ASSERT(findtext(innate.desc, "[HERETIC_RUST_FLOOR_CORROSION] урона коррозией"), "Врождённая черта называет урон пола.")

/// Облако, Длань и семя звучат своими звуками, разрастание - корнями, а не телеграфом захвата; снесённая хваткой ржавая стена обваливается со звуком.
/datum/unit_test/heretic_rust_sound_meanings/Run()
	var/own_root = "modular_bluemoon/sound/heretic/"
	var/obj/effect/proc_holder/spell/cone/staggered/entropic_plume/plume = /obj/effect/proc_holder/spell/cone/staggered/entropic_plume
	var/obj/effect/proc_holder/spell/aimed/rust_wave/patron = /obj/effect/proc_holder/spell/aimed/rust_wave
	var/obj/item/projectile/magic/spell/rust_wave/bolt = /obj/item/projectile/magic/spell/rust_wave
	var/list/own = list("облако" = initial(plume.sound), "выстрел Длани" = initial(patron.sound), "попадание Длани" = initial(bolt.hitsound))
	var/list/seen = list()
	for(var/event in own)
		var/sound_file = "[own[event]]"
		TEST_ASSERT(findtext(sound_file, own_root) == 1, "[event] звучит своим файлом, а не [sound_file].")
		TEST_ASSERT(!seen[sound_file], "[event] и [seen[sound_file]] звучат одним файлом.")
		seen[sound_file] = event
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_RUST)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/mob/living/heretic_sound_listener/ear = allocate_sound_listener(get_turf(user))
	var/obj/effect/proc_holder/spell/aoe_turf/rust_conversion/growth = allocate(/obj/effect/proc_holder/spell/aoe_turf/rust_conversion)
	growth.cast(list(), user)
	var/list/roots = list()
	for(var/sound_file in GLOB.heretic_rust_root_sounds)
		roots += "[sound_file]"
	TEST_ASSERT(length(ear.heard & roots), "Буйное разрастание звучит корнями.")
	TEST_ASSERT(!("[file('modular_bluemoon/sound/heretic/rust_roots.ogg')]" in ear.heard), "Разрастание не повторяет телеграф Ржавых корней.")
	ear.heard.Cut()
	var/datum/eldritch_knowledge/base_rust/rust = heretic.get_knowledge(/datum/eldritch_knowledge/base_rust)
	var/turf/wall = get_step(user, NORTH)
	wall = wall.ChangeTurf(/turf/closed/wall/rust)
	rust.on_mansus_grasp(wall, user, TRUE)
	TEST_ASSERT(!iswallturf(get_step(user, NORTH)), "Хватка сносит ржавую стену.")
	TEST_ASSERT("[HERETIC_RUST_COLLAPSE_SOUND]" in ear.heard, "Снесённая стена обваливается со звуком.")

/// Разрыв очага семени звучит взрывом коррозии без обвала, очаг семени выглядит не так, как сердце вознесения.
/datum/unit_test/heretic_rust_seed_burst/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_rust)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/path = heretic.get_knowledge(/datum/eldritch_knowledge/base_rust)
	var/mob/living/heretic_sound_listener/ear = allocate_sound_listener(get_turf(user))
	var/obj/structure/heretic_rust_heart/heart = allocate(/obj/structure/heretic_rust_heart, get_turf(user), user.mind, path)
	var/obj/structure/heretic_rust_ascension_heart/ascension = /obj/structure/heretic_rust_ascension_heart
	TEST_ASSERT(heart.icon_state in icon_states(heart.icon), "Очаг семени нарисован.")
	TEST_ASSERT("[heart.icon]:[heart.icon_state]" != "[initial(ascension.icon)]:[initial(ascension.icon_state)]", "Очаг семени не повторяет сердце вознесения.")
	ear.heard.Cut()
	TEST_ASSERT(heart.burst(user), "Хозяин разрывает очаг.")
	TEST_ASSERT("[HERETIC_RUST_SEED_BURST_SOUND]" in ear.heard, "Разрыв очага звучит взрывом коррозии.")
	TEST_ASSERT(!("[HERETIC_RUST_COLLAPSE_SOUND]" in ear.heard), "Разрыв не звучит тихим обвалом.")

/// Корни отпускают со звуком: освобождение слышно, а не только видно по частицам.
/datum/unit_test/heretic_rust_roots_release_sound/Run()
	var/list/fixture = list()
	rust_roots_fixture(fixture)
	var/datum/antagonist/heretic/heretic = fixture["heretic"]
	var/datum/eldritch_knowledge/base_rust/rust = fixture["rust"]
	var/mob/living/carbon/human/victim = fixture["victim"]
	var/mob/living/carbon/human/user = heretic.owner.current
	victim.DefaultCombatKnockdown(5 SECONDS, override_stamdmg = 0)
	TEST_ASSERT(rust.start_roots(user, victim), "Корни начинают расти.")
	var/datum/status_effect/heretic_rust_roots/roots = await_rust_roots(victim)
	TEST_ASSERT_NOTNULL(roots, "Цель врастает в пол.")
	var/mob/living/heretic_sound_listener/ear = allocate_sound_listener(get_turf(victim))
	qdel(roots)
	TEST_ASSERT("[HERETIC_RUST_ROOTS_RELEASE_SOUND]" in ear.heard, "Корни отпускают со звуком.")

/datum/unit_test/proc/count_plume_swirls(atom/target)
	. = 0
	for(var/image/overlay as anything in target.overlays)
		if(overlay.icon_state == "plume_swirl")
			.++

/// Ржавая пыль Энтропийного облака кружит над головой весь срок амока, а не только пока цель слепа.
/datum/unit_test/heretic_rust_plume_swirl/Run()
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	victim.apply_status_effect(STATUS_EFFECT_AMOK)
	victim.apply_status_effect(STATUS_EFFECT_CLOUDSTRUCK, 1 SECONDS)
	TEST_ASSERT_EQUAL(count_plume_swirls(victim), 1, "Над головой кружит одна пыль.")
	victim.remove_status_effect(STATUS_EFFECT_CLOUDSTRUCK)
	TEST_ASSERT(!HAS_TRAIT_FROM(victim, TRAIT_BLIND, "cloudstruck"), "Слепота проходит.")
	TEST_ASSERT_EQUAL(count_plume_swirls(victim), 1, "Пыль кружит, пока длится амок.")
	victim.remove_status_effect(STATUS_EFFECT_AMOK)
	TEST_ASSERT_EQUAL(count_plume_swirls(victim), 0, "С концом амока пыль оседает.")
