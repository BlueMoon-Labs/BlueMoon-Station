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
	var/atom/movable/thing = new /obj/effect/temp_visual/heretic_waltz_fade(run_loc_floor_bottom_left)
	qdel(thing)
	TEST_ASSERT(QDELETED(thing), "Угасание печати удаляется без ошибок.")
