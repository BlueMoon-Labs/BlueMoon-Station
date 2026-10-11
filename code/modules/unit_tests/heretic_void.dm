/datum/unit_test/proc/ascend_void_fixture()
	var/datum/antagonist/heretic/heretic = allocate_heretic(get_step(get_step(run_loc_floor_bottom_left, NORTHEAST), NORTHEAST))
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/final_eldritch/void_final/finale = allocate(/datum/eldritch_knowledge/final_eldritch/void_final)
	heretic.researched_knowledge[finale.type] = finale
	heretic.ascended = TRUE
	finale.finished = TRUE
	finale.on_body_gain(user)
	var/mob/living/carbon/human/attacker = allocate(/mob/living/carbon/human, get_step(get_step(user, EAST), EAST))
	return list("user" = user, "heretic" = heretic, "finale" = finale, "attacker" = attacker)

/datum/unit_test/proc/void_test_bullet(mob/living/attacker)
	var/obj/item/projectile/bullet/bullet = allocate(/obj/item/projectile/bullet, get_turf(attacker))
	bullet.damage = 20
	bullet.firer = attacker
	bullet.starting = get_turf(attacker)
	bullet.setAngle(270)
	return bullet

/// Буря вознесения Пустоты разворачивает снаряд назад веером, не отклонённый снаряд ранит.
/datum/unit_test/heretic_void_storm_deflect/Run()
	var/list/fixture = ascend_void_fixture()
	var/mob/living/carbon/human/user = fixture["user"]
	var/mob/living/attacker = fixture["attacker"]
	var/datum/component/heretic_void_storm/aspect = user.GetComponent(/datum/component/heretic_void_storm)
	TEST_ASSERT_NOTNULL(aspect, "Вознесение Пустоты даёт безвоздушную бурю.")
	TEST_ASSERT_EQUAL(aspect.deflect_chance, HERETIC_VOID_DEFLECT_CHANCE, "Шанс отклонения по умолчанию - тридцать процентов.")
	aspect.deflect_chance = 100
	var/obj/item/projectile/bullet/bullet = void_test_bullet(attacker)
	TEST_ASSERT_EQUAL(user.bullet_act(bullet, BODY_ZONE_CHEST), BULLET_ACT_FORCE_PIERCE, "Отклонённый снаряд летит дальше.")
	TEST_ASSERT_EQUAL(user.getBruteLoss(), 0, "Отклонённый снаряд не ранит.")
	var/turn = SIMPLIFY_DEGREES(bullet.Angle - 270)
	TEST_ASSERT(turn >= 120 && turn <= 240, "Снаряд уходит назад веером, поворот [turn].")
	TEST_ASSERT(bullet.ignore_source_check, "Отклонённый снаряд может попасть в стрелка.")
	aspect.deflect_chance = 0
	var/obj/item/projectile/bullet/second = void_test_bullet(attacker)
	TEST_ASSERT_NOTEQUAL(user.bullet_act(second, BODY_ZONE_CHEST), BULLET_ACT_FORCE_PIERCE, "Без удачного броска снаряд не отклоняется.")
	TEST_ASSERT(user.getBruteLoss() > 0, "Не отклонённый снаряд ранит.")

/// Огонь или перегрев глушат бурю: снаряды не отклоняются, аура не сковывает, погода не действует.
/datum/unit_test/heretic_void_storm_heat/Run()
	var/list/fixture = ascend_void_fixture()
	var/mob/living/carbon/human/user = fixture["user"]
	var/mob/living/attacker = fixture["attacker"]
	var/datum/eldritch_knowledge/final_eldritch/void_final/finale = fixture["finale"]
	var/datum/component/heretic_void_storm/aspect = user.GetComponent(/datum/component/heretic_void_storm)
	aspect.deflect_chance = 100
	user.on_fire = TRUE
	TEST_ASSERT_NOTEQUAL(user.bullet_act(void_test_bullet(attacker), BODY_ZONE_CHEST), BULLET_ACT_FORCE_PIERCE, "Горящий еретик не отклоняет снаряды.")
	user.on_fire = FALSE
	user.bodytemperature = BODYTEMP_NORMAL + HERETIC_VOID_HEAT_MARGIN + 10
	TEST_ASSERT_NOTEQUAL(user.bullet_act(void_test_bullet(attacker), BODY_ZONE_CHEST), BULLET_ACT_FORCE_PIERCE, "Перегретый еретик не отклоняет снаряды.")
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, get_step(user, NORTH))
	finale.on_life(user)
	TEST_ASSERT(!victim.has_status_effect(/datum/status_effect/heretic_void_chill), "Перегретая аура не сковывает.")
	TEST_ASSERT_NOTNULL(finale.storm, "Буря следует за еретиком и в тепле.")
	TEST_ASSERT(finale.storm.suppressed, "Тепло глушит погоду бури.")
	TEST_ASSERT(!finale.storm.can_weather_act(victim), "Заглушённая буря не действует на экипаж.")
	user.bodytemperature = BODYTEMP_NORMAL
	finale.on_life(user)
	TEST_ASSERT(victim.has_status_effect(/datum/status_effect/heretic_void_chill), "Остывшая аура снова сковывает.")
	TEST_ASSERT(!finale.storm.suppressed, "Остывшая буря снова действует.")
	TEST_ASSERT_EQUAL(user.bullet_act(void_test_bullet(attacker), BODY_ZONE_CHEST), BULLET_ACT_FORCE_PIERCE, "Остывший еретик снова отклоняет снаряды.")
	finale.stop_storm()

/// Смерть снимает бурю вместе с отклонением.
/datum/unit_test/heretic_void_storm_death/Run()
	var/list/fixture = ascend_void_fixture()
	var/mob/living/carbon/human/user = fixture["user"]
	var/datum/antagonist/heretic/heretic = fixture["heretic"]
	user.death()
	heretic.handle_death(user)
	TEST_ASSERT_NULL(user.GetComponent(/datum/component/heretic_void_storm), "Смерть снимает бурю.")

/// Отклонённый снаряд всегда покрывается инеем; рябь и иней в воздухе - только при зрителях, у точки попадания, и гаснут сами.
/datum/unit_test/heretic_void_deflect_visuals/Run()
	var/list/fixture = ascend_void_fixture()
	var/mob/living/carbon/human/user = fixture["user"]
	var/mob/living/attacker = fixture["attacker"]
	var/datum/component/heretic_void_storm/aspect = user.GetComponent(/datum/component/heretic_void_storm)
	aspect.deflect_chance = 100
	var/turf/place = get_turf(user)
	var/list/before = list_vfx_bursts(place)
	var/obj/item/projectile/bullet/bullet = void_test_bullet(attacker)
	TEST_ASSERT_EQUAL(user.bullet_act(bullet, BODY_ZONE_CHEST), BULLET_ACT_FORCE_PIERCE, "Снаряд отклонён.")
	TEST_ASSERT_NOTNULL(bullet.get_filter(HERETIC_VFX_PULSE_FILTER), "Отклонённый снаряд покрывается инеем.")
	TEST_ASSERT_NULL(locate(/obj/effect/temp_visual/heretic_vfx/shockwave) in place, "Без зрителей рябь не создаётся.")
	TEST_ASSERT_NULL(find_vfx_burst(place, /particles/heretic_ascension/void/frost, before), "Без зрителей иней в воздух не сыплется.")
	aspect.show_deflect(user, bullet.Angle)
	var/obj/effect/temp_visual/heretic_vfx/shockwave/ripple = locate() in place
	TEST_ASSERT_NOTNULL(ripple, "Отклонение рябит пространством.")
	TEST_ASSERT(ripple.pixel_x > (world.icon_size - 256) / 2, "Рябь встаёт на стороне попадания.")
	var/obj/effect/temp_visual/heretic_vfx/burst/frost = find_vfx_burst(place, /particles/heretic_ascension/void/frost, before)
	TEST_ASSERT_NOTNULL(frost, "С отклонённого снаряда сыплется иней.")
	TEST_ASSERT(wait_for_qdeleted(ripple), "Рябь гаснет.")
	TEST_ASSERT(wait_for_qdeleted(frost), "Иней оседает, эмиттер удаляется.")
	TEST_ASSERT_NULL(bullet.get_filter(HERETIC_VFX_PULSE_FILTER), "Иней на снаряде тает.")

/// Снег кружит вокруг вознесённого, жар его глушит, смерть отпускает последние снежинки.
/datum/unit_test/heretic_void_storm_motes/Run()
	var/list/fixture = ascend_void_fixture()
	var/mob/living/carbon/human/user = fixture["user"]
	var/datum/antagonist/heretic/heretic = fixture["heretic"]
	var/datum/component/heretic_void_storm/aspect = user.GetComponent(/datum/component/heretic_void_storm)
	var/obj/effect/abstract/heretic_particle_holder/motes = aspect.motes
	TEST_ASSERT(motes in user.vis_contents, "Вокруг вознесённого кружит снег.")
	TEST_ASSERT(motes.particles.spawning > 0, "Буря сыплет снегом.")
	user.bodytemperature = BODYTEMP_NORMAL + HERETIC_VOID_HEAT_MARGIN + 10
	aspect.update_motes()
	TEST_ASSERT_EQUAL(motes.particles.spawning, 0, "Жар глушит снег бури.")
	user.bodytemperature = BODYTEMP_NORMAL
	aspect.update_motes()
	TEST_ASSERT(motes.particles.spawning > 0, "Остывшая буря снова сыплет снегом.")
	var/turf/place = get_turf(user)
	user.death()
	heretic.handle_death(user)
	TEST_ASSERT(!(motes in user.vis_contents), "Смерть снимает снег с тела.")
	TEST_ASSERT_EQUAL(motes.loc, place, "Последние снежинки оседают на месте тела.")
	TEST_ASSERT(wait_for_qdeleted(motes, 4 SECONDS), "Снег бури тает.")

/// Последний такт: тишина на еретике, волна, иней и вспышка; урон прежний; печать крутится, переливается и гаснет к концу.
/datum/unit_test/heretic_last_waltz_visuals/Run()
	var/list/fixture = ascend_void_fixture()
	var/mob/living/carbon/human/user = fixture["user"]
	var/mob/living/carbon/human/victim = fixture["attacker"]
	var/turf/center = get_turf(user)
	var/obj/effect/proc_holder/spell/self/heretic_last_waltz/spell = allocate(/obj/effect/proc_holder/spell/self/heretic_last_waltz)
	var/list/before = list_vfx_bursts(center)
	var/burn_before = victim.getFireLoss()
	spell.cast(list(user), user)
	TEST_ASSERT(abs(victim.getFireLoss() - burn_before - spell.burst_damage) < DAMAGE_PRECISION, "Такт наносит прежние 30 холодовых ожогов.")
	TEST_ASSERT_NOTNULL(user.get_filter("heretic_waltz_silence"), "Перед тактом еретик выцветает тишиной.")
	var/obj/effect/temp_visual/heretic_vfx/shockwave/wave = locate() in center
	TEST_ASSERT_NOTNULL(wave, "Такт расходится волной искажения.")
	var/obj/effect/temp_visual/heretic_vfx/burst/snow = find_vfx_burst(center, /particles/heretic_ascension/void, before)
	TEST_ASSERT_NOTNULL(snow, "Такт взрывается инеем.")
	var/obj/effect/heretic_combat_zone/void/last_waltz/circle = spell.winter_circle
	TEST_ASSERT(length(circle.boundary), "У печати есть граница.")
	TEST_ASSERT_EQUAL(circle.boundary_color, heretic_path_ink(PATH_VOID), "Граница печати в чернилах пути.")
	TEST_ASSERT(wait_for_qdeleted(wave), "Волна такта гаснет.")
	TEST_ASSERT(wait_for_qdeleted(snow), "Иней такта оседает.")
	TEST_ASSERT_NULL(user.get_filter("heretic_waltz_silence"), "Тишина снимается с еретика.")
	var/list/old_edges = circle.boundary.Copy()
	for(var/obj/effect/heretic_field_edge/edge as anything in old_edges)
		edge.color = "#123456"
	circle.field_turfs -= circle.field_turfs[1]
	circle.refresh_boundary()
	var/reused_edges = 0
	for(var/obj/effect/heretic_field_edge/edge as anything in circle.boundary & old_edges)
		reused_edges++
		TEST_ASSERT_EQUAL(edge.color, "#123456", "Перестройка границы не гасит и не перекрашивает перенесённый край.")
	TEST_ASSERT(reused_edges, "Перестройка границы переносит старые края.")
	circle.spin_started_at = world.time - 2 SECONDS
	var/list/edges = circle.boundary.Copy()
	qdel(circle)
	var/obj/effect/temp_visual/heretic_waltz_fade/ghost = locate() in center
	TEST_ASSERT_NOTNULL(ghost, "Снятая раньше срока печать гаснет на месте.")
	var/matrix/turned = ghost.transform
	TEST_ASSERT(abs(turned.b) > 0.5, "Гаснущая печать продолжает поворот, а не встаёт в начальный угол.")
	for(var/obj/effect/heretic_field_edge/edge as anything in edges)
		TEST_ASSERT(!QDELETED(edge), "Граница снятой печати гаснет, а не пропадает разом.")
	for(var/obj/effect/heretic_field_edge/edge as anything in edges)
		TEST_ASSERT(wait_for_qdeleted(edge), "Погасшая граница удаляется.")
	TEST_ASSERT(wait_for_qdeleted(ghost), "Погасшая печать удаляется.")

/// Новые эффекты Пустоты создаются без аргументов и удаляются без ошибок.
/datum/unit_test/heretic_void_visual_types_create_and_destroy/Run()
	for(var/thing_type in list(/obj/effect/temp_visual/heretic_waltz_fade, /obj/effect/temp_visual/heretic_void_seal, /obj/effect/temp_visual/heretic_void_shatter, /obj/effect/temp_visual/heretic_void_swap, /obj/effect/temp_visual/heretic_void_gather, /obj/effect/temp_visual/heretic_void_push))
		var/atom/movable/thing = new thing_type(run_loc_floor_bottom_left)
		qdel(thing)
		TEST_ASSERT(QDELETED(thing), "[thing_type] удаляется без ошибок.")

/datum/unit_test/proc/void_prison_heretic()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_VOID)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/void_prison)
	return heretic

/datum/unit_test/proc/await_void_prison(mob/living/victim)
	var/list/budget = new_wait_budget(3 SECONDS, "ледяная темница на [victim]")
	while(!victim.has_status_effect(/datum/status_effect/heretic_void_prison))
		if(!wait_budget_tick(budget))
			break
	return victim.has_status_effect(/datum/status_effect/heretic_void_prison)

/// Ледяная темница: отказ стоящей нескованной цели, дальней вне поля и под антимагией; скованная рядом или сбитая в своём поле цель за секунду вмерзает в шар - немая, неуязвимая, не истекает кровью, тянет её только еретик; нулевой жезл раскалывает шар, после - скованность и невосприимчивость.
/datum/unit_test/heretic_void_prison/Run()
	var/datum/antagonist/heretic/heretic = void_prison_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_void/void = heretic.get_knowledge(/datum/eldritch_knowledge/base_void)
	var/datum/eldritch_knowledge/spell/void_prison/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/spell/void_prison)
	TEST_ASSERT(istype(knowledge.granted_spell, /obj/effect/proc_holder/spell/pointed/heretic_void/prison), "Знание выдаёт Ледяную темницу.")
	TEST_ASSERT_EQUAL(knowledge.role, HERETIC_ROLE_CAPTURE, "Ледяная темница - захват пути.")
	TEST_ASSERT(HAS_TRAIT(user, TRAIT_RESISTCOLD) && HAS_TRAIT(user, TRAIT_NOBREATH), "Знание по-прежнему защищает от холода и удушья.")
	var/turf/victim_spot = get_step(user, EAST)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, victim_spot)
	void.combat_resource = 2
	TEST_ASSERT(!void.prison(user, victim), "Стоящую нескованную цель лёд не берёт.")
	TEST_ASSERT(findtext(void.void_failure, "скованн"), "Отказ называет условие: [void.void_failure]")
	var/mob/living/carbon/human/far = allocate(/mob/living/carbon/human, get_step(get_step(victim_spot, EAST), EAST))
	far.apply_status_effect(/datum/status_effect/heretic_void_chill)
	TEST_ASSERT(!void.prison(user, far), "Скованная цель вдали и вне своего поля не вмерзает.")
	victim.apply_status_effect(/datum/status_effect/heretic_void_chill)
	var/datum/component/anti_magic/protection = victim.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5)
	TEST_ASSERT(!void.prison(user, victim), "Антимагия отталкивает темницу.")
	TEST_ASSERT_EQUAL(protection.charges, 5, "Проверка не тратит заряды антимагии.")
	qdel(protection)
	TEST_ASSERT_EQUAL(void.combat_resource, 2, "Отказы не тратят осколки.")
	TEST_ASSERT(void.prison(user, victim), "Скованная цель рядом вмерзает.")
	TEST_ASSERT_EQUAL(void.combat_resource, 2 - HERETIC_VOID_PRISON_COST, "Темница стоит осколок.")
	TEST_ASSERT_NULL(victim.has_status_effect(/datum/status_effect/heretic_void_prison), "Секунду лёд только нарастает.")
	TEST_ASSERT_NOTNULL(locate(/obj/effect/temp_visual/heretic_void_seal) in victim_spot, "Нарастание льда видно заранее.")
	var/datum/status_effect/heretic_void_prison/prison = await_void_prison(victim)
	TEST_ASSERT_NOTNULL(prison, "После секунды цель вмерзает.")
	var/remaining = prison.duration - world.time
	TEST_ASSERT(remaining < HERETIC_VOID_PRISON_DURATION + 1 && remaining > HERETIC_VOID_PRISON_DURATION - 1 SECONDS, "Темница держит 10 секунд: осталось [remaining] дс.")
	TEST_ASSERT(victim.IsParalyzed(), "Вмёрзшая цель не действует.")
	TEST_ASSERT(HAS_TRAIT(victim, TRAIT_MUTE), "Вмёрзшая цель немая.")
	TEST_ASSERT(HAS_TRAIT(victim, TRAIT_HERETIC_CAPTURE_HOLD), "Темница - захват: её можно растолкать.")
	TEST_ASSERT_EQUAL(victim.heretic_capture_mark?.path_id, PATH_VOID, "Метка захвата в чернилах Пустоты.")
	TEST_ASSERT(heretic.hunt_target_ready(victim), "Вмёрзшая цель готова к обряду.")
	TEST_ASSERT(SEND_SIGNAL(victim, COMSIG_LIVING_LIFE, 1) & COMPONENT_INTERRUPT_LIFE_BIOLOGICAL, "Вмёрзшая цель не истекает кровью.")
	var/obj/effect/abstract/heretic_vfx_attached/ball = prison.ball
	TEST_ASSERT(ball in victim.vis_contents, "Шар виден на цели.")
	TEST_ASSERT(ball.appearance_flags & RESET_TRANSFORM, "Шар не ложится вместе с целью.")
	victim.adjustBruteLoss(40)
	victim.apply_damage(40, BURN)
	TEST_ASSERT_EQUAL(victim.getBruteLoss() + victim.getFireLoss(), 0, "Урон по вмёрзшей цели не проходит.")
	var/mob/living/carbon/human/crew = allocate(/mob/living/carbon/human, get_step(victim_spot, NORTH))
	crew.start_pulling(victim)
	TEST_ASSERT(crew.pulling != victim, "Вмёрзшую цель экипаж не утащит.")
	user.start_pulling(victim)
	TEST_ASSERT_EQUAL(user.pulling, victim, "Вмёрзшую цель тянет её еретик.")
	user.stop_pulling()
	var/obj/item/nullrod/rod = allocate(/obj/item/nullrod)
	crew.put_in_hands(rod)
	rod.melee_attack_chain(crew, victim)
	TEST_ASSERT(QDELETED(prison), "Нулевой жезл раскалывает темницу.")
	TEST_ASSERT(!victim.IsParalyzed(), "Освобождённая цель снова может двигаться.")
	TEST_ASSERT(!(victim.status_flags & GODMODE), "Освобождённая цель снова уязвима.")
	TEST_ASSERT(!HAS_TRAIT(victim, TRAIT_MUTE), "Освобождённая цель снова говорит.")
	TEST_ASSERT_EQUAL(victim.getBruteLoss(), 0, "Жезл не бьёт вмёрзшую цель.")
	TEST_ASSERT(victim.has_status_effect(/datum/status_effect/heretic_void_chill), "Холод держится и после шара.")
	TEST_ASSERT_NOTNULL(locate(/obj/effect/temp_visual/heretic_void_shatter) in victim_spot, "Шар раскалывается на месте.")
	TEST_ASSERT(wait_for_qdeleted(ball), "Шар снимается с цели.")
	TEST_ASSERT(findtext(heretic_capture_block_reason(user, victim, HERETIC_VOID_CAPTURE), "приходит в себя"), "После темницы цель невосприимчива к ней.")
	var/turf/field_spot = locate(user.x + 3, user.y, user.z)
	var/mob/living/carbon/human/fallen = allocate(/mob/living/carbon/human, field_spot)
	fallen.DefaultCombatKnockdown(5 SECONDS, override_stamdmg = 0)
	void.combat_resource = 2
	TEST_ASSERT(!void.prison(user, fallen), "Сбитая цель вдали без поля не вмерзает.")
	oldpath_door_zone(void, /obj/effect/heretic_combat_zone/void, field_spot, user)
	TEST_ASSERT(void.prison(user, fallen), "Сбитая цель в своём Зимнем пределе вмерзает издалека.")
	prison = await_void_prison(fallen)
	TEST_ASSERT_NOTNULL(prison, "Вторая цель вмёрзла.")
	knowledge.on_death(user)
	TEST_ASSERT(QDELETED(prison), "Смерть еретика раскалывает темницу.")

/// Тепло - контрмера экипажа: горящая цель или пламя под ней растапливают шар сразу, сварка или зажигалка - за 2 секунды; растолкать тоже можно.
/datum/unit_test/heretic_void_prison_thaw/Run()
	var/datum/antagonist/heretic/heretic = void_prison_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_void/void = heretic.get_knowledge(/datum/eldritch_knowledge/base_void)
	var/turf/victim_spot = get_step(user, EAST)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, victim_spot)
	var/datum/status_effect/heretic_void_prison/prison = victim.apply_status_effect(/datum/status_effect/heretic_void_prison, void, user)
	TEST_ASSERT_NOTNULL(prison, "Цель вмёрзла.")
	victim.on_fire = TRUE
	prison.tick()
	TEST_ASSERT(QDELETED(prison), "Огонь на цели растапливает шар.")
	victim.on_fire = FALSE
	victim.remove_status_effect(/datum/status_effect/heretic_capture_immunity)
	prison = victim.apply_status_effect(/datum/status_effect/heretic_void_prison, void, user)
	var/mob/living/carbon/human/crew = allocate(/mob/living/carbon/human, get_step(victim_spot, NORTH))
	var/obj/item/weldingtool/welder = allocate(/obj/item/weldingtool)
	crew.put_in_hands(welder)
	TEST_ASSERT(!prison.thaw_source(welder), "Холодная сварка лёд не берёт.")
	welder.welding = TRUE
	welder.melee_attack_chain(crew, victim)
	TEST_ASSERT(!QDELETED(prison), "Лёд тает не сразу.")
	TEST_ASSERT(wait_for_qdeleted(prison, HERETIC_VOID_PRISON_THAW_TIME + 1 SECONDS), "Сварка за 2 секунды растапливает шар.")
	TEST_ASSERT_EQUAL(victim.getBruteLoss() + victim.getFireLoss(), 0, "Сварка по шару не жжёт цель.")
	welder.welding = FALSE
	victim.remove_status_effect(/datum/status_effect/heretic_capture_immunity)
	prison = victim.apply_status_effect(/datum/status_effect/heretic_void_prison, void, user)
	SEND_SIGNAL(victim, COMSIG_LIVING_HERETIC_CAPTURE_SHAKEN, crew)
	TEST_ASSERT(QDELETED(prison), "Растолканная цель выходит из шара.")

/// Сердце уводит цель охоты из своего ледяного шара в изнанку, только стоя рядом; изнанка забирает цель из шара.
/datum/unit_test/heretic_void_prison_door/Run()
	var/turf/start = run_loc_floor_bottom_left
	allocated += new /datum/heretic_test_station_level(start.z)
	var/datum/antagonist/heretic/heretic = void_prison_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_void/void = heretic.get_knowledge(/datum/eldritch_knowledge/base_void)
	var/turf/spot = get_step(start, EAST)
	var/mob/living/carbon/human/victim = allocate_hunt_victim(heretic, spot)
	TEST_ASSERT_NULL(void.pocket_door(user, victim), "Стоящую цель без поля и шара Пустота не уводит.")
	var/datum/status_effect/heretic_void_prison/prison = victim.apply_status_effect(/datum/status_effect/heretic_void_prison, void, user)
	var/list/door = void.pocket_door(user, victim)
	TEST_ASSERT_NOTNULL(door, "Цель в своём шаре уводится.")
	TEST_ASSERT_EQUAL(door["time"], HERETIC_POCKET_PULL_TIME, "Дверь шара открывается за 1 секунду.")
	user.forceMove(locate(start.x, start.y + 3, start.z))
	TEST_ASSERT_NULL(void.pocket_door(user, victim), "Издалека шар не дверь.")
	user.forceMove(start)
	TEST_ASSERT(heretic.pocket_pull(user, victim, spot, door["time"], door["check"], door["text"]), "Дверь шара уводит цель в изнанку.")
	TEST_ASSERT(heretic.pocket_holds(victim), "Цель в изнанке.")
	TEST_ASSERT(QDELETED(prison), "Изнанка забирает цель из шара.")
	heretic.pocket.collapse("проверка")

/// Ледяная темница срывается, если цель ушла с клетки, пока лёд нарастал: перезарядка и осколок возвращаются.
/datum/unit_test/heretic_void_prison_refund/Run()
	var/datum/antagonist/heretic/heretic = void_prison_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_void/void = heretic.get_knowledge(/datum/eldritch_knowledge/base_void)
	var/datum/eldritch_knowledge/spell/void_prison/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/spell/void_prison)
	var/obj/effect/proc_holder/spell/spell = knowledge.granted_spell
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	victim.apply_status_effect(/datum/status_effect/heretic_void_chill)
	void.combat_resource = 1
	spell.charge_counter = 0
	TEST_ASSERT(void.prison(user, victim), "Лёд начинает нарастать.")
	TEST_ASSERT_EQUAL(void.combat_resource, 0, "Осколок потрачен.")
	victim.forceMove(get_step(get_turf(victim), NORTH))
	var/list/budget = new_wait_budget(HERETIC_VOID_PRISON_TELEGRAPH + 1 SECONDS, "возврат осколка")
	while(void.combat_resource < 1)
		if(!wait_budget_tick(budget))
			break
	TEST_ASSERT_EQUAL(void.combat_resource, 1, "Сорванная темница возвращает осколок.")
	TEST_ASSERT_EQUAL(spell.charge_counter, spell.charge_max, "Сорванная темница возвращает перезарядку.")
	TEST_ASSERT_NULL(victim.has_status_effect(/datum/status_effect/heretic_void_prison), "Ушедшая цель не вмерзает.")

/// Хватка гасит лампу и покрывает её инеем: у неё для Пустоты зима - осколки как на холоде и лечение, лампа - выход из изнанки; замена лампы и нулевой жезл снимают иней, лишняя лампа растапливает самую старую.
/datum/unit_test/heretic_void_frost_lamps/Run()
	allocated += new /datum/heretic_test_station_level(run_loc_floor_bottom_left.z)
	var/datum/antagonist/heretic/heretic = void_prison_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_void/void = heretic.get_knowledge(/datum/eldritch_knowledge/base_void)
	var/datum/eldritch_knowledge/spell/void_prison/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/spell/void_prison)
	var/turf/open/floor/home = get_turf(user)
	var/turf/away = locate(home.x + 4, home.y + 4, home.z)
	TEST_ASSERT(home.GetTemperature() > T0C, "Воздух на полу тёплый.")
	TEST_ASSERT_NULL(void.pocket_exits(user), "Без инея своих выходов нет.")
	var/obj/machinery/light/lamp = allocate(/obj/machinery/light, get_step(home, EAST))
	lamp.status = LIGHT_OK
	lamp.on = TRUE
	TEST_ASSERT(void.on_mansus_grasp(lamp, user, TRUE, null), "Хватка гасит лампу.")
	TEST_ASSERT_NOTNULL(heretic_craft_on(lamp, HERETIC_VOID_FROST_CRAFT), "Лампа в инее.")
	TEST_ASSERT(void.frost_at(home), "Рядом с лампой для Пустоты зима.")
	TEST_ASSERT(!void.frost_at(away), "Дальше от лампы тепло.")
	user.forceMove(away)
	void.combat_resource = 2
	COOLDOWN_RESET(void, resource_harvest)
	void.on_life(user)
	TEST_ASSERT_EQUAL(void.combat_resource, 2, "В тепле осколков не больше двух.")
	user.forceMove(home)
	COOLDOWN_RESET(void, resource_harvest)
	void.on_life(user)
	TEST_ASSERT_EQUAL(void.combat_resource, 3, "У заиндевевшей лампы осколки копятся как на холоде.")
	user.adjustBruteLoss(10)
	knowledge.on_life(user)
	TEST_ASSERT(user.getBruteLoss() < 10, "У заиндевевшей лампы Пустота лечит.")
	var/list/exits = void.pocket_exits(user)
	TEST_ASSERT_EQUAL(length(exits), 1, "Заиндевевшая лампа - выход из изнанки.")
	TEST_ASSERT(findtext(exits[1], "Иней"), "Выход подписан инеем: [exits[1]]")
	lamp.drop_light_tube()
	TEST_ASSERT_NULL(heretic_craft_on(lamp, HERETIC_VOID_FROST_CRAFT), "Замена лампы снимает иней.")
	TEST_ASSERT(!void.frost_at(home), "Без инея у лампы снова тепло.")
	TEST_ASSERT_NULL(void.pocket_exits(user), "Растаявшая лампа больше не выход.")
	var/obj/machinery/light/second = allocate(/obj/machinery/light, get_step(home, EAST))
	second.status = LIGHT_OK
	second.on = TRUE
	void.on_mansus_grasp(second, user, TRUE, null)
	var/mob/living/carbon/human/crew = allocate(/mob/living/carbon/human, home)
	var/obj/item/nullrod/rod = allocate(/obj/item/nullrod)
	crew.put_in_hands(rod)
	rod.melee_attack_chain(crew, second)
	TEST_ASSERT_NULL(heretic_craft_on(second, HERETIC_VOID_FROST_CRAFT), "Нулевой жезл снимает иней.")
	var/list/lamps = list()
	for(var/index in 1 to HERETIC_VOID_FROST_LIMIT + 1)
		var/obj/machinery/light/extra = allocate(/obj/machinery/light, get_step(home, NORTH))
		extra.status = LIGHT_OK
		extra.on = TRUE
		void.on_mansus_grasp(extra, user, TRUE, null)
		lamps += extra
	TEST_ASSERT_NULL(heretic_craft_on(lamps[1], HERETIC_VOID_FROST_CRAFT), "Лишняя лампа растапливает самую старую.")
	TEST_ASSERT_EQUAL(length(void.frosted_lamps), HERETIC_VOID_FROST_LIMIT, "Инея не больше [HERETIC_VOID_FROST_LIMIT] ламп.")

/// Над зимним полем идёт снег; снятое поле перестаёт его сыпать, эмиттер удаляется.
/datum/unit_test/heretic_void_zone_snowfall/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/obj/effect/heretic_combat_zone/void/zone = allocate(/obj/effect/heretic_combat_zone/void, run_loc_floor_bottom_left, heretic.owner)
	STOP_PROCESSING(SSprocessing, zone)
	var/obj/effect/abstract/heretic_particle_holder/snow = zone.snowfall
	TEST_ASSERT(snow in zone.vis_contents, "Над Зимним пределом идёт снег.")
	TEST_ASSERT(snow.particles.spawning > 0, "Снег сыплется.")
	qdel(zone)
	TEST_ASSERT_EQUAL(snow.particles.spawning, 0, "Снятое поле перестаёт сыпать снег.")
	TEST_ASSERT(wait_for_qdeleted(snow, 4 SECONDS), "Снег оседает, эмиттер удаляется.")

/// Скованность видна: на ногах человека проступает иней, он поворачивается и ложится вместе с телом, со снятием тает.
/datum/unit_test/heretic_void_chill_frost/Run()
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/datum/status_effect/heretic_void_chill/chill = victim.apply_status_effect(/datum/status_effect/heretic_void_chill)
	var/obj/effect/abstract/heretic_vfx_attached/frost = chill.frost
	TEST_ASSERT(frost in victim.vis_contents, "Иней на ногах скованного.")
	TEST_ASSERT(frost.vis_flags & VIS_INHERIT_DIR, "Иней поворачивается вместе с телом.")
	TEST_ASSERT(!(frost.appearance_flags & RESET_TRANSFORM), "Иней ложится вместе с телом.")
	TEST_ASSERT(frost.icon_state in icon_states(frost.icon), "Стейт инея есть в листе.")
	victim.apply_status_effect(/datum/status_effect/heretic_void_chill)
	TEST_ASSERT_EQUAL(chill.frost, frost, "Обновление скованности не рисует второй иней.")
	victim.remove_status_effect(/datum/status_effect/heretic_void_chill)
	TEST_ASSERT(wait_for_qdeleted(frost), "Иней тает со снятием скованности.")

/// Обмен и такт рисуют свои эффекты Пустоты, канал домена - своё схлопывание, а не заглушки tg; кнопки Пустоты есть в листах и не повторяют друг друга.
/datum/unit_test/heretic_void_own_visuals/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	var/turf/user_start = get_turf(user)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	var/turf/victim_start = get_turf(victim)
	var/obj/effect/proc_holder/spell/pointed/boogie_woogie/swap = allocate(/obj/effect/proc_holder/spell/pointed/boogie_woogie)
	swap.cast(list(victim), user)
	TEST_ASSERT_NOTNULL(locate(/obj/effect/temp_visual/heretic_void_swap) in user_start, "Обмен оставляет свой след на прежнем месте еретика.")
	TEST_ASSERT_NOTNULL(locate(/obj/effect/temp_visual/heretic_void_swap) in victim_start, "Обмен оставляет свой след на прежнем месте цели.")
	TEST_ASSERT_NULL(locate(/obj/effect/temp_visual/voidswap) in user_start, "Заглушки tg больше нет.")
	var/obj/effect/proc_holder/spell/aoe_turf/domain_expansion/domain = allocate(/obj/effect/proc_holder/spell/aoe_turf/domain_expansion)
	INVOKE_ASYNC(domain, TYPE_PROC_REF(/obj/effect/proc_holder/spell, cast), list(), user)
	var/obj/effect/temp_visual/heretic_void_gather/gather = locate() in get_turf(user)
	TEST_ASSERT_NOTNULL(gather, "Сосредоточение домена стягивает пустоту к еретику.")
	user.forceMove(user_start)
	TEST_ASSERT(wait_for_qdeleted(gather, 3 SECONDS), "Сорванное сосредоточение рассеивается.")
	TEST_ASSERT_NULL(domain.active_domain, "Сорванное сосредоточение не создаёт домен.")
	var/list/fixture = ascend_void_fixture()
	var/mob/living/carbon/human/dancer = fixture["user"]
	var/mob/living/carbon/human/partner = fixture["attacker"]
	var/turf/partner_start = get_turf(partner)
	var/obj/effect/proc_holder/spell/self/heretic_last_waltz/waltz = allocate(/obj/effect/proc_holder/spell/self/heretic_last_waltz)
	waltz.cast(list(dancer), dancer)
	TEST_ASSERT_NOTNULL(locate(/obj/effect/temp_visual/heretic_void_push) in partner_start, "Такт отбрасывает врага своим порывом инея.")
	TEST_ASSERT_NULL(locate(/obj/effect/temp_visual/voidpush) in partner_start, "Старого tg-толчка больше нет.")
	var/list/seen = list()
	for(var/spell_type in list(/obj/effect/proc_holder/spell/pointed/void_blink, /obj/effect/proc_holder/spell/targeted/void_pull, /obj/effect/proc_holder/spell/pointed/boogie_woogie, /obj/effect/proc_holder/spell/aoe_turf/domain_expansion, /obj/effect/proc_holder/spell/pointed/heretic_void/prison, /obj/effect/proc_holder/spell/self/heretic_power/void, /obj/effect/proc_holder/spell/self/heretic_last_waltz))
		var/obj/effect/proc_holder/spell/spell = spell_type
		var/button = "[initial(spell.action_icon)]:[initial(spell.action_icon_state)]"
		TEST_ASSERT(initial(spell.action_icon_state) in icon_states(initial(spell.action_icon)), "Кнопка [spell_type] есть в листе: [button]")
		TEST_ASSERT(!seen[button], "[spell_type] и [seen[button]] показывают одну кнопку [button].")
		seen[button] = spell_type
	var/atom/movable/screen/alert/status_effect/heretic_void_prison/alert = /atom/movable/screen/alert/status_effect/heretic_void_prison
	TEST_ASSERT(initial(alert.icon_state) in icon_states(initial(alert.icon)), "Значок темницы есть в листе.")

/// Захват Пустоты защёлкивается своим звуком; хватка, Зимний предел, обмен, домен и такт звучат своими звуками, а не отражением бури и сдвигом.
/datum/unit_test/heretic_void_sounds/Run()
	var/latch = heretic_fx_latch_sound(HERETIC_VOID_CAPTURE)
	TEST_ASSERT(isfile(latch), "У темницы есть звук защёлкивания.")
	for(var/capture_id in GLOB.heretic_capture_latch_sounds)
		if(capture_id != HERETIC_VOID_CAPTURE)
			TEST_ASSERT_NOTEQUAL("[GLOB.heretic_capture_latch_sounds[capture_id]]", "[latch]", "Темница и [capture_id] защёлкиваются разными звуками.")
	var/list/borrowed = list("[file("modular_bluemoon/sound/heretic/void_deflect1.ogg")]", "[file("modular_bluemoon/sound/heretic/void_deflect2.ogg")]", "[file("sound/magic/voidblink.ogg")]")
	var/datum/eldritch_knowledge/base_void/void = allocate(/datum/eldritch_knowledge/base_void)
	var/list/own = list(void.grasp_sound, HERETIC_VOID_EDGE_SOUND, HERETIC_VOID_APPLAUSE_SOUND, HERETIC_VOID_DOMAIN_SOUND, HERETIC_VOID_WALTZ_SOUND)
	for(var/sound_file in own)
		TEST_ASSERT(isfile(sound_file), "Звук Пустоты [sound_file] - файл.")
		TEST_ASSERT(!("[sound_file]" in borrowed), "[sound_file] не заимствует звук бури или сдвига.")

/// Рывок Ищущего клинка виден и слышен: провал у прежнего места, выход у цели и звук сдвига в обеих точках.
/datum/unit_test/heretic_void_seeking_blade_feedback/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_void)
	heretic.gain_knowledge(/datum/eldritch_knowledge/void_blade_upgrade)
	var/turf/origin = get_turf(user)
	var/mob/living/victim = allocate(/mob/living/carbon/human, locate(origin.x + 3, origin.y + 1, origin.z))
	var/mob/living/heretic_sound_listener/ear = allocate_sound_listener(origin)
	var/obj/item/melee/sickly_blade/void/blade = allocate(/obj/item/melee/sickly_blade/void)
	user.put_in_active_hand(blade)
	user.a_intent = INTENT_HARM
	victim.apply_status_effect(/datum/status_effect/eldritch/void)
	blade.ranged_attack_chain(user, victim)
	TEST_ASSERT(user.Adjacent(victim), "Клинок переносит к меченой цели.")
	TEST_ASSERT_NOTNULL(locate(/obj/effect/temp_visual/voidin) in origin, "На прежнем месте остаётся провал пустоты.")
	TEST_ASSERT_NOTNULL(locate(/obj/effect/temp_visual/voidout) in get_turf(user), "У цели пустота раскрывается.")
	TEST_ASSERT("[file('sound/magic/voidblink.ogg')]" in ear.heard, "Сдвиг слышен на прежнем месте.")

/// Притяжение пустоты звучит своим звуком с верхним слоем, а не прежним тихим гулом.
/datum/unit_test/heretic_void_pull_sound/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	var/mob/living/heretic_sound_listener/ear = allocate_sound_listener(get_turf(user))
	var/obj/effect/proc_holder/spell/targeted/void_pull/pull = allocate(/obj/effect/proc_holder/spell/targeted/void_pull)
	pull.cast(list(user), user)
	TEST_ASSERT("[HERETIC_VOID_PULL_SOUND]" in ear.heard, "Притяжение звучит своим звуком.")
	TEST_ASSERT(!("[file('sound/magic/voidpull.ogg')]" in ear.heard), "Прежний гул без верхнего слоя не играет.")
