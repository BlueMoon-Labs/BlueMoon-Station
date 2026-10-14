/datum/unit_test/proc/ascend_ash_fixture(turf/location)
	var/datum/antagonist/heretic/heretic = allocate_heretic(location || get_step(get_step(run_loc_floor_bottom_left, NORTHEAST), NORTHEAST))
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/final_eldritch/ash_final/finale = allocate(/datum/eldritch_knowledge/final_eldritch/ash_final)
	heretic.researched_knowledge[finale.type] = finale
	heretic.ascended = TRUE
	finale.finished = TRUE
	finale.on_body_gain(user)
	return list("user" = user, "heretic" = heretic, "finale" = finale)

/// Сухой Пепельный владыка горит, оставляет огненный след, который поджигает врагов, и лечится в огне.
/datum/unit_test/heretic_ash_lord_trail/Run()
	var/list/fixture = ascend_ash_fixture()
	var/mob/living/carbon/human/user = fixture["user"]
	var/datum/component/heretic_ash_lord/lord = user.GetComponent(/datum/component/heretic_ash_lord)
	TEST_ASSERT_NOTNULL(lord, "Вознесение Пепла даёт аспект Пепельного владыки.")
	TEST_ASSERT(lord.aura in user.vis_contents, "Сухой владыка объят видимым пламенем.")
	var/turf/start = get_turf(user)
	user.forceMove(get_step(user, EAST))
	var/obj/effect/heretic_combat_zone/ash/lord_trail/trail = locate() in start
	TEST_ASSERT_NOTNULL(trail, "Шаг оставляет огненный след на покинутой клетке.")
	TEST_ASSERT(abs(trail.expires_at - world.time - HERETIC_ASH_TRAIL_DURATION) < 1, "След живёт четыре секунды.")
	TEST_ASSERT_NULL(locate(/obj/effect/abstract/turf_fire) in start, "След не создаёт атмосферный огонь.")
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, start)
	trail.process()
	TEST_ASSERT(victim.on_fire, "След поджигает врага на своей клетке.")
	user.adjustFireLoss(20)
	user.adjustBruteLoss(20)
	var/burn_before = user.getFireLoss()
	var/brute_before = user.getBruteLoss()
	lord.on_life(user)
	TEST_ASSERT(abs(burn_before - user.getFireLoss() - HERETIC_ASH_LORD_HEAL) < DAMAGE_PRECISION, "Пламя лечит владыке три ожога за тик жизни.")
	TEST_ASSERT(abs(brute_before - user.getBruteLoss()) < DAMAGE_PRECISION, "Пламя не лечит ушибы.")

/// Мокрый владыка гаснет: без следа, без лечения и без видимого пламени, после высыхания всё возвращается.
/datum/unit_test/heretic_ash_lord_wet/Run()
	var/list/fixture = ascend_ash_fixture()
	var/mob/living/carbon/human/user = fixture["user"]
	var/datum/component/heretic_ash_lord/lord = user.GetComponent(/datum/component/heretic_ash_lord)
	user.fire_stacks = -5
	var/turf/start = get_turf(user)
	user.forceMove(get_step(user, EAST))
	TEST_ASSERT_NULL(locate(/obj/effect/heretic_combat_zone/ash/lord_trail) in start, "Мокрый владыка не оставляет следа.")
	user.adjustFireLoss(20)
	var/burn_before = user.getFireLoss()
	lord.on_life(user)
	TEST_ASSERT(abs(burn_before - user.getFireLoss()) < DAMAGE_PRECISION, "Мокрого владыку пламя не лечит.")
	TEST_ASSERT(!(lord.aura in user.vis_contents), "Вода гасит видимое пламя.")
	user.fire_stacks = 0
	lord.on_life(user)
	TEST_ASSERT(!(lord.aura in user.vis_contents), "Намокание держится и после высыхания.")
	lord.wet_until = world.time
	lord.on_life(user)
	TEST_ASSERT(lord.aura in user.vis_contents, "Высохший владыка снова горит.")
	TEST_ASSERT(burn_before - user.getFireLoss() > 0, "Высохший владыка снова лечится.")

/// Смерть снимает аспект Пепельного владыки, оживление возвращает.
/datum/unit_test/heretic_ash_lord_death/Run()
	var/list/fixture = ascend_ash_fixture()
	var/mob/living/carbon/human/user = fixture["user"]
	var/datum/antagonist/heretic/heretic = fixture["heretic"]
	var/datum/eldritch_knowledge/final_eldritch/ash_final/finale = fixture["finale"]
	var/datum/component/heretic_ash_lord/lord = user.GetComponent(/datum/component/heretic_ash_lord)
	var/obj/effect/aura = lord.aura
	user.death()
	heretic.handle_death(user)
	TEST_ASSERT_NULL(user.GetComponent(/datum/component/heretic_ash_lord), "Смерть снимает аспект.")
	TEST_ASSERT(!(aura in user.vis_contents), "Смерть гасит пламя на теле.")
	var/turf/start = get_turf(user)
	user.forceMove(get_step(user, EAST))
	TEST_ASSERT_NULL(locate(/obj/effect/heretic_combat_zone/ash/lord_trail) in start, "Мёртвое тело не оставляет следа.")
	user.revive(full_heal = TRUE)
	finale.on_life(user)
	TEST_ASSERT_NOTNULL(user.GetComponent(/datum/component/heretic_ash_lord), "Оживление возвращает аспект.")

/// Заклинания вознесения Пепла: каскад на десять клеток, клятва раз в две минуты.
/datum/unit_test/heretic_ash_ascension_spells/Run()
	var/list/fixture = ascend_ash_fixture()
	var/datum/eldritch_knowledge/final_eldritch/ash_final/finale = fixture["finale"]
	var/obj/effect/proc_holder/spell/aoe_turf/fire_cascade/big/cascade = locate() in finale.ascension_spell_instances
	var/obj/effect/proc_holder/spell/targeted/fire_sworn/sworn = locate() in finale.ascension_spell_instances
	TEST_ASSERT_EQUAL(cascade?.range, HERETIC_ASH_CASCADE_RANGE, "Каскад вознесения бьёт на десять клеток, дальше обычного.")
	var/obj/effect/proc_holder/spell/aoe_turf/fire_cascade/base_cascade = /obj/effect/proc_holder/spell/aoe_turf/fire_cascade
	TEST_ASSERT(cascade?.range > initial(base_cascade.range), "Каскад вознесения больше обычного.")
	TEST_ASSERT_EQUAL(sworn?.charge_max, HERETIC_ASH_FIRE_SWORN_COOLDOWN, "Клятва огня перезаряжается две минуты.")
	TEST_ASSERT_EQUAL(sworn?.duration, HERETIC_ASH_FIRE_SWORN_DURATION, "Кольцо Клятвы огня держится минуту.")
	var/duration_text = "[HERETIC_ASH_FIRE_SWORN_DURATION / (1 SECONDS)] секунд"
	var/cooldown_text = "[HERETIC_ASH_FIRE_SWORN_COOLDOWN / (1 MINUTES)] минуты"
	TEST_ASSERT(findtext(sworn?.desc, duration_text) && findtext(sworn?.desc, cooldown_text), "Кнопка Клятвы огня называет срок и перезарядку цифрами: [sworn?.desc]")
	TEST_ASSERT(findtext(jointext(finale.details, " "), "Клятва огня: [duration_text] кольцо огня жжёт врагов рядом, перезарядка [cooldown_text]."), "Вознесение называет срок и перезарядку клятвы теми же цифрами.")

/// Одна порция воды из огнетушителя гасит владыку на весь срок, хотя сама высыхает за тик жизни.
/datum/unit_test/heretic_ash_lord_extinguisher/Run()
	var/list/fixture = ascend_ash_fixture()
	var/mob/living/carbon/human/user = fixture["user"]
	var/datum/component/heretic_ash_lord/lord = user.GetComponent(/datum/component/heretic_ash_lord)
	var/datum/reagents/water = new(1)
	water.add_reagent(/datum/reagent/water, 1)
	water.reaction(user, TOUCH)
	qdel(water)
	TEST_ASSERT(user.fire_stacks < 0, "Вода из огнетушителя мочит владыку.")
	lord.on_life(user)
	TEST_ASSERT(abs(lord.wet_until - world.time - HERETIC_ASH_WET_DURATION) < 1, "Намокание длится семь секунд.")
	user.handle_fire()
	TEST_ASSERT_EQUAL(user.fire_stacks, 0, "Тик жизни высушивает запас огня.")
	user.adjustFireLoss(20)
	var/burn_before = user.getFireLoss()
	lord.on_life(user)
	TEST_ASSERT(!(lord.aura in user.vis_contents), "После тика жизни пламя всё ещё сбито.")
	TEST_ASSERT(abs(burn_before - user.getFireLoss()) < DAMAGE_PRECISION, "Мокрый владыка не лечится.")
	var/turf/start = get_turf(user)
	user.forceMove(get_step(user, EAST))
	TEST_ASSERT_NULL(locate(/obj/effect/heretic_combat_zone/ash/lord_trail) in start, "Мокрый владыка не оставляет следа.")
	lord.wet_until = world.time
	lord.on_life(user)
	TEST_ASSERT(lord.aura in user.vis_contents, "По истечении срока пламя разгорается снова.")
	TEST_ASSERT(burn_before - user.getFireLoss() > 0, "По истечении срока лечение возвращается.")

/// Кадильница забирает печать Угасания, даже если на той же клетке лежит след владыки.
/datum/unit_test/heretic_ash_censer_skips_lord_trail/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_ash)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/path = heretic.get_knowledge(/datum/eldritch_knowledge/base_ash)
	var/obj/item/heretic_relic/censer/censer = allocate(/obj/item/heretic_relic/censer)
	user.put_in_hands(censer)
	var/turf/place = get_step(user, EAST)
	var/obj/effect/heretic_combat_zone/ash/lord_trail/footprints = allocate(/obj/effect/heretic_combat_zone/ash/lord_trail, place, user.mind)
	var/obj/effect/heretic_combat_zone/ash/zone = allocate(/obj/effect/heretic_combat_zone/ash, place, user.mind)
	path.combat_zone = zone
	path.track_combat_effect(zone)
	censer.afterattack(place, user, TRUE)
	TEST_ASSERT(QDELETED(zone), "Кадильница забирает печать Угасания.")
	TEST_ASSERT(!QDELETED(footprints), "След владыки не принимается за печать.")
	TEST_ASSERT_NULL(footprints.zone_slowdown, "След владыки не создаёт модификатор замедления.")

/// Пламя владыки сыплет углями и дымом; вода гасит их с паром и опадающим огнём, высохшее пламя вспыхивает снова, смерть отпускает угли.
/datum/unit_test/heretic_ash_lord_visuals/Run()
	var/list/fixture = ascend_ash_fixture()
	var/mob/living/carbon/human/user = fixture["user"]
	var/datum/antagonist/heretic/heretic = fixture["heretic"]
	var/datum/component/heretic_ash_lord/lord = user.GetComponent(/datum/component/heretic_ash_lord)
	var/obj/effect/abstract/heretic_particle_holder/embers = lord.embers
	TEST_ASSERT(embers in user.vis_contents, "От горящего владыки взлетают угли.")
	TEST_ASSERT(lord.smoke in user.vis_contents, "Над пламенем владыки вьётся дым.")
	TEST_ASSERT(embers.particles.spawning > 0, "Сухое пламя сыплет углями.")
	var/turf/place = get_turf(user)
	var/list/before = list_vfx_bursts(place)
	user.fire_stacks = -5
	lord.update_flame()
	TEST_ASSERT_EQUAL(embers.particles.spawning, 0, "Сбитое пламя не сыплет углями.")
	var/obj/effect/temp_visual/heretic_ash_quench/dying = locate() in user.vis_contents
	TEST_ASSERT_NOTNULL(dying, "Сбитое пламя опадает к ногам, а не пропадает разом.")
	TEST_ASSERT_NOTNULL(find_vfx_burst(place, /particles/heretic_ascension/steam, before), "Вода на пламени поднимает пар.")
	TEST_ASSERT(wait_for_qdeleted(dying), "Опавшее пламя гаснет.")
	TEST_ASSERT(!(dying in user.vis_contents), "Погасшее пламя уходит с тела.")
	user.fire_stacks = 0
	lord.wet_until = world.time
	before = list_vfx_bursts(place)
	TEST_ASSERT(lord.update_flame(), "Высохший владыка снова горит.")
	TEST_ASSERT(embers.particles.spawning > 0, "Высохшее пламя снова сыплет углями.")
	var/obj/effect/temp_visual/heretic_vfx/burst/flare = find_vfx_burst(place, /particles/heretic_ascension/ash, before)
	TEST_ASSERT_NOTNULL(flare, "Пламя разгорается со вспышкой углей.")
	TEST_ASSERT(wait_for_qdeleted(flare), "Вспышка углей гаснет.")
	user.death()
	heretic.handle_death(user)
	TEST_ASSERT(!(embers in user.vis_contents), "Смерть снимает угли с тела.")
	TEST_ASSERT_EQUAL(embers.loc, place, "Последние угли догорают на месте тела.")
	TEST_ASSERT(wait_for_qdeleted(embers), "Отпущенные угли гаснут.")

/// След владыки проходит весь цикл горения и заканчивается углями к концу своего срока.
/datum/unit_test/heretic_ash_trail_visuals/Run()
	var/list/fixture = ascend_ash_fixture()
	var/mob/living/carbon/human/user = fixture["user"]
	var/turf/start = get_turf(user)
	user.forceMove(get_step(user, EAST))
	var/obj/effect/heretic_combat_zone/ash/lord_trail/trail = locate() in start
	TEST_ASSERT_NOTNULL(trail, "Шаг оставляет след.")
	TEST_ASSERT_EQUAL(trail.icon_state, "ash_embers", "Цикл следа доживает углями.")
	TEST_ASSERT(length(trail.overlays), "Пламя и угли следа светятся в темноте.")
	var/expires_before = trail.expires_at
	user.forceMove(start)
	user.forceMove(get_step(start, EAST))
	TEST_ASSERT(trail.expires_at >= expires_before, "Повторный шаг заново разжигает след.")
	TEST_ASSERT(abs(trail.expires_at - world.time - HERETIC_ASH_TRAIL_DURATION) < 1, "Разожжённый след живёт свои четыре секунды.")

/// Каскад вознесения открывается маревом, волной, углями и тряской; обычный каскад - без них; урон прежний.
/datum/unit_test/heretic_ash_cascade_visuals/Run()
	var/turf/center = get_step(get_step(run_loc_floor_bottom_left, NORTHEAST), NORTHEAST)
	var/datum/antagonist/heretic/heretic = allocate_heretic(center)
	var/mob/living/user = heretic.owner.current
	var/obj/effect/proc_holder/spell/aoe_turf/fire_cascade/plain = allocate(/obj/effect/proc_holder/spell/aoe_turf/fire_cascade)
	plain.cascade_opening(center, user)
	TEST_ASSERT_NULL(locate(/obj/effect/temp_visual/heretic_vfx/shockwave) in center, "Обычный каскад обходится без волны.")
	var/obj/effect/proc_holder/spell/aoe_turf/fire_cascade/big/cascade = allocate(/obj/effect/proc_holder/spell/aoe_turf/fire_cascade/big)
	var/list/before = list_vfx_bursts(center)
	cascade.cascade_opening(center, user)
	var/obj/effect/temp_visual/heretic_vfx/shockwave/wave = locate() in center
	TEST_ASSERT_NOTNULL(wave, "От владыки расходится огненная волна.")
	var/obj/effect/temp_visual/heretic_vfx/burst/embers = find_vfx_burst(center, /particles/heretic_ascension/ash, before)
	TEST_ASSERT_NOTNULL(embers, "Каскад выбрасывает угли.")
	TEST_ASSERT_NOTNULL(user.get_filter("heretic_ash_shimmer"), "Над владыкой дрожит марево.")
	TEST_ASSERT(wait_for_qdeleted(wave), "Волна гаснет.")
	TEST_ASSERT(wait_for_qdeleted(embers), "Угли каскада гаснут.")
	TEST_ASSERT_NULL(user.get_filter("heretic_ash_shimmer"), "Марево снимается.")
	var/mob/living/victim = allocate(/mob/living/carbon/human, locate(center.x + 2, center.y, center.z))
	cascade.fire_cascade(user, 2)
	TEST_ASSERT(victim.getFireLoss() >= 15, "Каскад по-прежнему наносит 15 ожогов.")

/// Клятва огня кружит вокруг владыки кольцом огненных комет, которое гаснет с концом клятвы или смертью.
/datum/unit_test/heretic_fire_sworn_ring_visual/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	var/obj/effect/proc_holder/spell/targeted/fire_sworn/spell = allocate(/obj/effect/proc_holder/spell/targeted/fire_sworn)
	spell.cast(list(user), user)
	var/obj/effect/abstract/heretic_fire_ring/ring = spell.ring_visual
	TEST_ASSERT_NOTNULL(ring, "Клятва зажигает кольцо.")
	TEST_ASSERT(ring in user.vis_contents, "Кольцо кружит вокруг владыки.")
	TEST_ASSERT_EQUAL(length(ring.overlays), HERETIC_ASH_RING_MOTES * 2, "В кольце кометы огня, и каждая светится в темноте.")
	spell.remove()
	TEST_ASSERT_NULL(spell.ring_visual, "Конец клятвы отпускает кольцо.")
	TEST_ASSERT(wait_for_qdeleted(ring), "Кольцо гаснет после клятвы.")
	TEST_ASSERT(!(ring in user.vis_contents), "Погасшее кольцо уходит с тела.")
	spell.cast(list(user), user)
	ring = spell.ring_visual
	user.death()
	spell.process()
	TEST_ASSERT_NULL(spell.ring_visual, "Смерть гасит кольцо.")
	TEST_ASSERT(wait_for_qdeleted(ring), "Кольцо мёртвого владыки гаснет.")

/// Новые эффекты Пепла создаются без аргументов и удаляются без ошибок.
/datum/unit_test/heretic_ash_visual_types_create_and_destroy/Run()
	for(var/thing_type in list(/obj/effect/temp_visual/heretic_ash_quench, /obj/effect/abstract/heretic_fire_ring, /obj/effect/temp_visual/heretic_ash_flame, /obj/effect/temp_visual/heretic_ash_shroud_shatter, /obj/effect/heretic_ash_field_flame, /obj/effect/temp_visual/heretic_ash_arc, /obj/effect/decal/cleanable/heretic_trace/ash_print))
		var/atom/movable/thing = new thing_type(run_loc_floor_bottom_left)
		qdel(thing)
		TEST_ASSERT(QDELETED(thing), "[thing_type] удаляется без ошибок.")

/// Огонь каскада и клятвы, край печати и вспышка вознесения рисуются спрайтом, а не в карте освещения, и светятся в темноте.
/datum/unit_test/heretic_visuals_off_lighting_plane/Run()
	var/turf/place = run_loc_floor_bottom_left
	var/list/visuals = list(
		allocate(/obj/effect/temp_visual/heretic_ash_flame, place),
		allocate(/obj/effect/heretic_field_edge, place, list(place), "#ff8b3d"),
		allocate(/obj/effect/temp_visual/heretic_ascension_echo, place, PATH_ASH),
	)
	for(var/atom/movable/visual as anything in visuals)
		TEST_ASSERT_NOTEQUAL(visual.plane, LIGHTING_PLANE, "[visual.type] не лежит на плоскости освещения.")
		var/glowing = FALSE
		for(var/mutable_appearance/overlay as anything in visual.overlays)
			if(overlay.plane == EMISSIVE_PLANE)
				glowing = TRUE
		TEST_ASSERT(glowing, "[visual.type] светится в темноте.")

/datum/unit_test/proc/allocate_ash_marker(turf/location)
	var/datum/antagonist/heretic/heretic = allocate_heretic(location)
	heretic.selected_path = PATH_ASH
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_ash)
	heretic.gain_knowledge(/datum/eldritch_knowledge/ash_mark)
	return heretic

/datum/unit_test/proc/set_ash_burning_downed(mob/living/victim)
	victim.adjust_fire_stacks(5)
	victim.IgniteMob()
	victim.DefaultCombatKnockdown(5 SECONDS, override_stamdmg = 0)

/datum/unit_test/proc/await_ash_shroud(mob/living/victim)
	var/list/budget = new_wait_budget(3 SECONDS, "пепельный саван на [victim]")
	while(!victim.has_status_effect(/datum/status_effect/heretic_ash_shroud))
		if(!wait_budget_tick(budget))
			break
	return victim.has_status_effect(/datum/status_effect/heretic_ash_shroud)

/datum/unit_test/proc/douse_with_water(atom/target)
	var/datum/reagents/water = new(5)
	water.add_reagent(/datum/reagent/water, 5)
	water.reaction(target, TOUCH)
	qdel(water)

/// Взрыв Метки Пепла клинком запекает горящую сбитую цель в саван: телеграф, 10 секунд без движения и голоса, тянет только еретик; вода смывает, после - невосприимчивость.
/datum/unit_test/heretic_ash_shroud_capture/Run()
	var/datum/antagonist/heretic/heretic = allocate_ash_marker()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_ash/ash = heretic.get_knowledge(/datum/eldritch_knowledge/base_ash)
	var/datum/eldritch_knowledge/ash_mark/mark_knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/ash_mark)
	TEST_ASSERT_EQUAL(mark_knowledge.role, HERETIC_ROLE_CAPTURE, "Метка Пепла - захват пути.")
	var/turf/spot = get_step(user, EAST)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, spot)
	var/obj/item/melee/sickly_blade/ash/blade = allocate(/obj/item/melee/sickly_blade/ash)
	user.put_in_hands(blade)
	victim.apply_status_effect(/datum/status_effect/eldritch/ash)
	blade.attack(victim, user)
	TEST_ASSERT_NULL(victim.has_status_effect(/datum/status_effect/eldritch/ash), "Клинок взрывает метку.")
	TEST_ASSERT(COOLDOWN_FINISHED(ash, shroud_cooldown), "Взрыв по стоящей негорящей цели не тратит саван.")
	set_ash_burning_downed(victim)
	victim.apply_status_effect(/datum/status_effect/eldritch/ash)
	blade.attack(victim, user)
	TEST_ASSERT(!COOLDOWN_FINISHED(ash, shroud_cooldown), "Взрыв по горящей сбитой цели начинает саван и его перезарядку.")
	TEST_ASSERT_NULL(victim.has_status_effect(/datum/status_effect/heretic_ash_shroud), "Сначала огонь только оседает пеплом.")
	TEST_ASSERT_NOTNULL(locate(/obj/effect/abstract/heretic_vfx_attached/ash_crust) in victim.vis_contents, "Оседающий пепел виден на цели заранее.")
	var/datum/status_effect/heretic_ash_shroud/shroud = await_ash_shroud(victim)
	TEST_ASSERT_NOTNULL(shroud, "Через 0,8 секунды цель в саване.")
	var/remaining = shroud.duration - world.time
	TEST_ASSERT(remaining <= HERETIC_ASH_SHROUD_DURATION && remaining > HERETIC_ASH_SHROUD_DURATION - 1 SECONDS, "Саван держит 10 секунд: осталось [remaining] дс.")
	TEST_ASSERT(!victim.on_fire, "Огонь запёкся в корку.")
	TEST_ASSERT(victim.IsParalyzed(), "Цель в саване не двигается.")
	TEST_ASSERT(HAS_TRAIT_FROM(victim, TRAIT_MUTE, HERETIC_ASH_SHROUD_CAPTURE), "Цель в саване не может говорить.")
	TEST_ASSERT(HAS_TRAIT(victim, TRAIT_HERETIC_CAPTURE_HOLD), "Саван держит как захват.")
	TEST_ASSERT(heretic.hunt_target_ready(victim), "Цель в саване готова к обряду.")
	var/obj/effect/abstract/heretic_vfx_attached/ash_crust/crust = shroud.crust
	TEST_ASSERT(crust in victim.vis_contents, "Корка лежит на цели.")
	TEST_ASSERT(crust.vis_flags & VIS_INHERIT_DIR, "Корка поворачивается вместе с целью.")
	TEST_ASSERT(!(crust.appearance_flags & RESET_TRANSFORM), "Корка ложится вместе с целью.")
	TEST_ASSERT(length(crust.overlays), "Трещины корки светятся в темноте.")
	var/mob/living/carbon/human/crew = allocate(/mob/living/carbon/human, get_step(spot, NORTH))
	crew.start_pulling(victim)
	TEST_ASSERT(crew.pulling != victim, "Цель в саване экипаж не утащит.")
	user.start_pulling(victim)
	TEST_ASSERT_EQUAL(user.pulling, victim, "Цель в саване тянет её еретик.")
	user.stop_pulling()
	douse_with_water(victim)
	TEST_ASSERT(QDELETED(shroud), "Вода смывает саван.")
	TEST_ASSERT(QDELETED(crust), "Корка уходит с цели.")
	TEST_ASSERT(!victim.IsParalyzed(), "Смытая цель снова двигается.")
	TEST_ASSERT(!HAS_TRAIT(victim, TRAIT_MUTE), "Смытая цель снова говорит.")
	TEST_ASSERT_NULL(ash.shroud_on(victim), "Знание отпускает цель.")
	TEST_ASSERT_NOTNULL(locate(/obj/effect/temp_visual/heretic_ash_shroud_shatter) in spot, "Корка осыпается к ногам.")
	TEST_ASSERT(findtext(heretic_capture_block_reason(user, victim, HERETIC_ASH_SHROUD_CAPTURE), "приходит в себя"), "После савана цель к нему невосприимчива.")

/// Огонь, сбитый до запекания, срывает саван и возвращает перезарядку; стоящая и защищённая цели в саван не идут, второй саван ждёт перезарядки.
/datum/unit_test/heretic_ash_shroud_refund/Run()
	var/datum/antagonist/heretic/heretic = allocate_ash_marker()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_ash/ash = heretic.get_knowledge(/datum/eldritch_knowledge/base_ash)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	victim.adjust_fire_stacks(5)
	victim.IgniteMob()
	TEST_ASSERT(!ash.try_shroud(user, victim), "Стоящая горящая цель в саван не идёт.")
	victim.DefaultCombatKnockdown(5 SECONDS, override_stamdmg = 0)
	var/datum/component/anti_magic/protection = victim.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5)
	TEST_ASSERT(!ash.try_shroud(user, victim), "Защита от магии спасает от савана.")
	TEST_ASSERT(findtext(ash.shroud_failure, "защищена от магии"), "Отказ называет защиту: [ash.shroud_failure]")
	qdel(protection)
	TEST_ASSERT(COOLDOWN_FINISHED(ash, shroud_cooldown), "Отказ не тратит перезарядку.")
	TEST_ASSERT(ash.try_shroud(user, victim), "Сбитая горящая цель начинает запекаться.")
	victim.ExtinguishMob()
	TEST_ASSERT(wait_for_var(ash, NAMEOF(ash, shroud_cooldown), 0, 3 SECONDS), "Сбитый огонь возвращает перезарядку савана.")
	TEST_ASSERT_NULL(victim.has_status_effect(/datum/status_effect/heretic_ash_shroud), "Без огня саван не ложится.")
	TEST_ASSERT(findtext(ash.shroud_failure, "сбили"), "Отказ называет сбитый огонь: [ash.shroud_failure]")
	victim.adjust_fire_stacks(5)
	victim.IgniteMob()
	TEST_ASSERT(ash.try_shroud(user, victim), "Снова горящая цель запекается.")
	TEST_ASSERT_NOTNULL(await_ash_shroud(victim), "Саван лёг.")
	var/mob/living/carbon/human/second = allocate(/mob/living/carbon/human, get_step(user, NORTH))
	set_ash_burning_downed(second)
	TEST_ASSERT(!ash.try_shroud(user, second), "Второй саван ждёт перезарядки.")
	TEST_ASSERT(findtext(ash.shroud_failure, "не остыл"), "Отказ называет перезарядку: [ash.shroud_failure]")

/// Саван рассеивают нулевой жезл, удар от 5 урона, «растолкать» и смерть еретика; лёгкий тычок его не трогает.
/datum/unit_test/heretic_ash_shroud_countermeasures/Run()
	var/datum/antagonist/heretic/heretic = allocate_ash_marker()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_ash/ash = heretic.get_knowledge(/datum/eldritch_knowledge/base_ash)
	var/turf/start = get_turf(user)
	var/mob/living/carbon/human/crew = allocate(/mob/living/carbon/human, get_step(start, NORTH))
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, get_step(start, EAST))
	var/datum/status_effect/heretic_ash_shroud/shroud = victim.apply_status_effect(/datum/status_effect/heretic_ash_shroud, ash, user)
	TEST_ASSERT_NOTNULL(shroud, "Саван лёг.")
	victim.apply_damage(HERETIC_ASH_SHROUD_CRACK_DAMAGE - 3, BRUTE)
	TEST_ASSERT(!QDELETED(shroud), "Лёгкий тычок корку не колет.")
	var/obj/item/nullrod/rod = allocate(/obj/item/nullrod)
	crew.put_in_hands(rod)
	var/brute_before = victim.getBruteLoss()
	rod.melee_attack_chain(crew, victim)
	TEST_ASSERT(QDELETED(shroud), "Нулевой жезл рассеивает саван.")
	TEST_ASSERT(abs(victim.getBruteLoss() - brute_before) < DAMAGE_PRECISION, "Жезл не бьёт цель в саване.")
	victim = allocate(/mob/living/carbon/human, locate(start.x + 2, start.y, start.z))
	shroud = victim.apply_status_effect(/datum/status_effect/heretic_ash_shroud, ash, user)
	victim.apply_damage(HERETIC_ASH_SHROUD_CRACK_DAMAGE * 2, BRUTE)
	TEST_ASSERT(QDELETED(shroud), "Удар раскалывает корку.")
	victim = allocate(/mob/living/carbon/human, locate(start.x + 3, start.y, start.z))
	shroud = victim.apply_status_effect(/datum/status_effect/heretic_ash_shroud, ash, user)
	SEND_SIGNAL(victim, COMSIG_LIVING_HERETIC_CAPTURE_SHAKEN, crew)
	TEST_ASSERT(QDELETED(shroud), "Растолканная цель выходит из савана.")
	victim = allocate(/mob/living/carbon/human, locate(start.x + 4, start.y, start.z))
	shroud = victim.apply_status_effect(/datum/status_effect/heretic_ash_shroud, ash, user)
	ash.on_death(user)
	TEST_ASSERT(QDELETED(shroud), "Смерть еретика обрывает саван.")
	TEST_ASSERT(!length(ash.shrouds), "Знание не держит обрывков савана.")

/// Пока саван цел, сердце уводит цель охоты в изнанку из 3 клеток, если её видно; дальше дверь не держит.
/datum/unit_test/heretic_ash_shroud_door/Run()
	var/turf/start = run_loc_floor_bottom_left
	allocated += new /datum/heretic_test_station_level(start.z)
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_ASH)
	heretic.gain_knowledge(/datum/eldritch_knowledge/ash_mark)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_ash/ash = heretic.get_knowledge(/datum/eldritch_knowledge/base_ash)
	var/turf/spot = locate(start.x + HERETIC_ASH_SHROUD_DOOR_RANGE, start.y, start.z)
	var/mob/living/carbon/human/victim = allocate_hunt_victim(heretic, spot)
	TEST_ASSERT_NULL(ash.pocket_door(user, victim), "Без савана и огня дверь закрыта.")
	var/datum/status_effect/heretic_ash_shroud/shroud = victim.apply_status_effect(/datum/status_effect/heretic_ash_shroud, ash, user)
	var/list/door = ash.pocket_door(user, victim)
	TEST_ASSERT_NOTNULL(door, "Цель в саване уводится из 3 клеток.")
	TEST_ASSERT(door["remote"], "Дверь савана предлагает и сжатое сердце.")
	var/datum/callback/check = door["check"]
	victim.forceMove(locate(start.x + HERETIC_ASH_SHROUD_DOOR_RANGE + 1, start.y, start.z))
	TEST_ASSERT(!check.Invoke(), "Дальше 3 клеток дверь не держит.")
	victim.forceMove(spot)
	TEST_ASSERT(check.Invoke(), "Цель снова в 3 клетках.")
	TEST_ASSERT(heretic.pocket_pull(user, victim, spot, door["time"], door["check"], door["text"]), "Дверь савана уводит цель в изнанку.")
	TEST_ASSERT(heretic.pocket_holds(victim), "Цель в изнанке.")
	TEST_ASSERT(QDELETED(shroud), "В изнанке саван осыпается, цель держит переход.")
	heretic.pocket.collapse("проверка")

/// Погашенная на полу свеча оставляет тлеющий отпечаток вместо медальона: выход из изнанки, угли на нём копятся раз в 5 секунд; швабра и нулевой жезл стирают, лишний и старый отпечаток остывает.
/datum/unit_test/heretic_ash_ember_prints/Run()
	var/turf/start = run_loc_floor_bottom_left
	allocated += new /datum/heretic_test_station_level(start.z)
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_ASH)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_ash/ash = heretic.get_knowledge(/datum/eldritch_knowledge/base_ash)
	var/turf/place = get_step(start, EAST)
	var/obj/item/candle/candle = allocate(/obj/item/candle, place)
	candle.light()
	TEST_ASSERT(ash.on_mansus_grasp(candle, user, TRUE, null), "Хватка гасит свечу на полу.")
	var/obj/effect/decal/cleanable/heretic_trace/ash_print/print = locate() in place
	TEST_ASSERT_NOTNULL(print, "Погашенный огонь оставляет тлеющий отпечаток.")
	for(var/obj/effect/decal/cleanable/heretic_trace/trace in place)
		TEST_ASSERT_EQUAL(trace, print, "Отпечаток заменяет медальон дела.")
	TEST_ASSERT(print.smouldering, "Отпечаток тлеет.")
	TEST_ASSERT(print in ash.ember_prints, "Знание помнит отпечаток.")
	TEST_ASSERT_NOTNULL(heretic_craft_on(print, HERETIC_ASH_PRINT_CRAFT), "Отпечаток - ремесло пути.")
	TEST_ASSERT(length(print.overlays), "Угли отпечатка светятся в темноте.")
	var/list/exits = ash.pocket_exits(user)
	TEST_ASSERT_EQUAL(length(exits), 1, "Отпечаток - выход из изнанки.")
	TEST_ASSERT_EQUAL(exits[exits[1]], place, "Выход ведёт на отпечаток.")
	ash.combat_resource = 0
	user.forceMove(place)
	COOLDOWN_RESET(ash, print_harvest)
	ash.on_life(user)
	TEST_ASSERT_EQUAL(ash.combat_resource, 1, "На своём отпечатке угли раздуваются.")
	ash.on_life(user)
	TEST_ASSERT_EQUAL(ash.combat_resource, 1, "Не чаще раза в 5 секунд.")
	user.forceMove(start)
	COOLDOWN_RESET(ash, print_harvest)
	ash.on_life(user)
	TEST_ASSERT_EQUAL(ash.combat_resource, 1, "Вне отпечатка угли не копятся.")
	var/mob/living/carbon/human/crew = allocate(/mob/living/carbon/human, get_step(place, NORTH))
	var/obj/item/mop/mop = allocate(/obj/item/mop)
	mop.reagents.add_reagent(/datum/reagent/water, 10)
	mop.clean(place, crew)
	TEST_ASSERT(QDELETED(print), "Швабра стирает отпечаток.")
	TEST_ASSERT(!length(ash.ember_prints), "Стёртый отпечаток уходит из знания.")
	TEST_ASSERT_NULL(ash.pocket_exits(user), "Без отпечатков своих выходов нет.")
	print = ash.leave_print(place)
	TEST_ASSERT_NOTNULL(print, "Отпечаток снова тлеет.")
	var/obj/item/nullrod/rod = allocate(/obj/item/nullrod)
	crew.put_in_hands(rod)
	rod.melee_attack_chain(crew, print)
	TEST_ASSERT(QDELETED(print), "Нулевой жезл рассеивает отпечаток.")
	TEST_ASSERT(!length(ash.ember_prints), "Рассеянный отпечаток уходит из знания.")
	var/list/prints = list()
	for(var/index in 0 to HERETIC_ASH_PRINT_LIMIT)
		var/obj/effect/decal/cleanable/heretic_trace/ash_print/fresh = ash.leave_print(locate(start.x + index, start.y + 2, start.z))
		allocated += fresh
		prints += fresh
	TEST_ASSERT_EQUAL(length(ash.ember_prints), HERETIC_ASH_PRINT_LIMIT, "Тлеет не больше 4 отпечатков.")
	var/obj/effect/decal/cleanable/heretic_trace/ash_print/oldest = prints[1]
	TEST_ASSERT(!QDELETED(oldest) && !oldest.smouldering, "Лишний отпечаток остужает самый старый, след остаётся.")
	TEST_ASSERT_EQUAL(oldest.icon_state, "ember_print_cold", "Остывший отпечаток выглядит холодным.")
	TEST_ASSERT_NULL(heretic_craft_on(oldest, HERETIC_ASH_PRINT_CRAFT), "Остывший отпечаток - уже не ремесло.")
	var/obj/effect/decal/cleanable/heretic_trace/ash_print/newest = prints[length(prints)]
	TEST_ASSERT(abs(timeleft(newest.cool_timer) - HERETIC_ASH_PRINT_LIFETIME) < 1 SECONDS, "Отпечаток тлеет 10 минут.")
	newest.cool_down()
	TEST_ASSERT(!(newest in ash.ember_prints), "Остывший отпечаток - не выход.")

/// Свой огонь засчитывается в дело и оставляет отпечаток один раз за раунд; огонь станции идёт в дело в каждом новом отделе.
/datum/unit_test/heretic_ash_own_flame_once/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_ASH)
	var/mob/living/carbon/human/user = heretic.owner.current
	user.ckey = "ashownflametester"
	var/datum/heretic_deed/deed = heretic.deed
	var/datum/eldritch_knowledge/base_ash/ash = heretic.get_knowledge(/datum/eldritch_knowledge/base_ash)
	var/turf/first = get_step(user, EAST)
	var/obj/item/lighter/lighter = allocate(/obj/item/lighter, first)
	lighter.set_lit(TRUE)
	lighter.fingerprintslast = user.ckey
	TEST_ASSERT(ash.on_mansus_grasp(lighter, user, TRUE, null), "Хватка гасит свою зажигалку.")
	TEST_ASSERT_EQUAL(deed.progress, 1, "Первый свой огонь идёт в дело.")
	TEST_ASSERT_NOTNULL(locate(/obj/effect/decal/cleanable/heretic_trace/ash_print) in first, "Первый свой огонь оставляет отпечаток.")
	deed.counted_keys.Cut()
	COOLDOWN_RESET(deed, progress_cooldown)
	var/turf/second = get_step(user, NORTH)
	lighter.forceMove(second)
	lighter.set_lit(TRUE)
	lighter.fingerprintslast = user.ckey
	ash.combat_resource = 0
	COOLDOWN_RESET(ash, resource_harvest)
	TEST_ASSERT(ash.on_mansus_grasp(lighter, user, TRUE, null), "Свой огонь снова гаснет ради уголька.")
	TEST_ASSERT_EQUAL(ash.combat_resource, 1, "Свой огонь по-прежнему даёт уголёк.")
	TEST_ASSERT_EQUAL(deed.progress, 1, "Второй раз свой огонь в дело не идёт.")
	TEST_ASSERT_NULL(locate(/obj/effect/decal/cleanable/heretic_trace/ash_print) in second, "Второй раз свой огонь отпечатка не оставляет.")
	var/obj/item/candle/candle = allocate(/obj/item/candle, second)
	candle.light()
	candle.fingerprintslast = "ashstrangerkey"
	TEST_ASSERT(ash.on_mansus_grasp(candle, user, TRUE, null), "Хватка гасит свечу станции.")
	TEST_ASSERT_EQUAL(deed.tier, 1, "Огонь станции идёт в дело.")
	TEST_ASSERT_NOTNULL(locate(/obj/effect/decal/cleanable/heretic_trace/ash_print) in second, "Огонь станции оставляет отпечаток.")

/// Угасание зажигает огонь на каждой клетке поля вместо медальона; вода гасит его целиком, след владыки огня поля не рисует.
/datum/unit_test/heretic_ash_field_fire/Run()
	var/turf/center = get_step(get_step(run_loc_floor_bottom_left, NORTHEAST), NORTHEAST)
	var/datum/antagonist/heretic/heretic = allocate_heretic(center)
	var/obj/effect/heretic_combat_zone/ash/zone = allocate(/obj/effect/heretic_combat_zone/ash, center, heretic.owner)
	STOP_PROCESSING(SSprocessing, zone)
	TEST_ASSERT_NULL(zone.icon, "Поле не рисует медальон.")
	TEST_ASSERT(length(zone.field_turfs), "У поля есть клетки.")
	TEST_ASSERT_EQUAL(length(zone.field_flames), length(zone.field_turfs), "Огонь горит на каждой клетке поля.")
	var/list/flames = list()
	for(var/turf/place as anything in zone.field_turfs)
		var/obj/effect/heretic_ash_field_flame/flame = zone.field_flames[place]
		TEST_ASSERT_EQUAL(flame?.loc, place, "Язык огня стоит на своей клетке.")
		TEST_ASSERT(length(flame?.overlays), "Огонь светится в темноте.")
		flames += flame
	var/obj/effect/heretic_ash_field_flame/core = zone.field_flames[center]
	TEST_ASSERT_EQUAL(core?.flame_state, "ash_flame", "В центре огонь выше.")
	douse_with_water(zone)
	TEST_ASSERT(QDELETED(zone), "Вода гасит огонь Угасания.")
	for(var/obj/effect/heretic_ash_field_flame/flame as anything in flames)
		TEST_ASSERT(flame.going_out, "Каждый язык огня гаснет.")
		TEST_ASSERT(wait_for_qdeleted(flame), "Погасший огонь уходит.")
	var/obj/effect/heretic_combat_zone/ash/lord_trail/trail = allocate(/obj/effect/heretic_combat_zone/ash/lord_trail, center, heretic.owner)
	STOP_PROCESSING(SSprocessing, trail)
	TEST_ASSERT(!length(trail.field_flames), "След владыки горит сам и огня поля не рисует.")

/// Метка Пепла перескакивает на соседа видимой искрой; Возрождение тянет огненную нить от каждой горящей жертвы.
/datum/unit_test/heretic_ash_mark_arc_and_drain/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/turf/first_spot = get_step(user, EAST)
	var/turf/second_spot = get_step(first_spot, EAST)
	var/mob/living/carbon/human/first = allocate(/mob/living/carbon/human, first_spot)
	var/mob/living/carbon/human/second = allocate(/mob/living/carbon/human, second_spot)
	first.apply_status_effect(/datum/status_effect/eldritch/ash, 5)
	var/datum/status_effect/eldritch/ash/mark = first.has_status_effect(/datum/status_effect/eldritch/ash)
	mark.on_effect()
	TEST_ASSERT_NOTNULL(second.has_status_effect(/datum/status_effect/eldritch/ash), "Метка перескочила на соседа.")
	var/obj/effect/temp_visual/heretic_ash_arc/arc = locate() in first_spot
	TEST_ASSERT_NOTNULL(arc, "Перескок виден искрой-дугой.")
	TEST_ASSERT(length(arc?.overlays), "Дуга светится в темноте.")
	TEST_ASSERT(wait_for_qdeleted(arc), "Дуга гаснет.")
	second.remove_status_effect(/datum/status_effect/eldritch/ash)
	var/obj/effect/proc_holder/spell/targeted/fiery_rebirth/rebirth = allocate(/obj/effect/proc_holder/spell/targeted/fiery_rebirth)
	for(var/mob/living/carbon/human/victim as anything in list(first, second))
		victim.adjust_fire_stacks(5)
		victim.IgniteMob()
	rebirth.cast(list(user), user)
	TEST_ASSERT_NOTNULL(locate(/obj/effect/ebeam) in first_spot, "От первой горящей жертвы к еретику тянется нить.")
	TEST_ASSERT_NOTNULL(locate(/obj/effect/ebeam) in second_spot, "От второй горящей жертвы тоже.")

/// Звуки Пепла: три хватки набором, вход и выход перехода, метка, возрождение, обряд, своя защёлка, запекание и осыпание савана, разжигание и клятва огня; все файлы разные.
/datum/unit_test/heretic_ash_sounds/Run()
	var/datum/sound_effect/grasp = GLOB.sfx_datum_by_key[HERETIC_ASH_GRASP_SFX]
	TEST_ASSERT_NOTNULL(grasp, "Хватка Пепла звучит набором.")
	TEST_ASSERT_EQUAL(length(grasp?.file_paths), 3, "В наборе хватки три варианта.")
	var/datum/eldritch_knowledge/base_ash/ash = allocate(/datum/eldritch_knowledge/base_ash)
	TEST_ASSERT_EQUAL(ash.grasp_sound, HERETIC_ASH_GRASP_SFX, "Хватка Пепла берёт звук из набора.")
	var/datum/status_effect/eldritch/ash/mark = /datum/status_effect/eldritch/ash
	var/latch = heretic_fx_latch_sound(HERETIC_ASH_SHROUD_CAPTURE)
	var/list/sounds = grasp?.file_paths + list('modular_bluemoon/sound/heretic/ash_shift_in.ogg', 'modular_bluemoon/sound/heretic/ash_shift_out.ogg', initial(mark.detonation_sound), 'modular_bluemoon/sound/heretic/ash_rebirth.ogg', 'modular_bluemoon/sound/heretic/ash_rite.ogg', latch, 'modular_bluemoon/sound/heretic/ash_crumble.ogg', 'modular_bluemoon/sound/heretic/ash_burst.ogg', HERETIC_ASH_REKINDLE_SOUND, HERETIC_ASH_OATH_SOUND, HERETIC_ASH_BAKE_SOUND)
	var/list/seen = list()
	for(var/sound_file in sounds)
		TEST_ASSERT(isfile(sound_file), "[sound_file] - звуковой файл.")
		TEST_ASSERT(!seen["[sound_file]"], "[sound_file] не повторяет другой звук Пепла.")
		seen["[sound_file]"] = TRUE
	for(var/capture_id in GLOB.heretic_capture_latch_sounds)
		if(capture_id != HERETIC_ASH_SHROUD_CAPTURE)
			TEST_ASSERT_NOTEQUAL("[GLOB.heretic_capture_latch_sounds[capture_id]]", "[latch]", "Защёлка савана не звучит как [capture_id].")

/// Знание и его заклинание называются одинаково, тексты называют числа савана и отпечатков, все стейты Пепла есть в листе.
/datum/unit_test/heretic_ash_texts_and_states/Run()
	for(var/knowledge_type in list(/datum/eldritch_knowledge/spell/nightwatchers_rite, /datum/eldritch_knowledge/spell/cleave))
		var/datum/eldritch_knowledge/spell/knowledge = allocate(knowledge_type)
		var/obj/effect/proc_holder/spell/spell_type = knowledge.spell_to_add
		TEST_ASSERT_EQUAL(knowledge.name, initial(spell_type.name), "[knowledge_type] называется как своё заклинание.")
	var/datum/eldritch_knowledge/ash_mark/mark = allocate(/datum/eldritch_knowledge/ash_mark)
	var/mark_text = jointext(mark.details, " ")
	TEST_ASSERT(findtext(mark_text, "[HERETIC_ASH_SHROUD_DURATION / (1 SECONDS)] секунд цель в саване"), "Метка называет срок савана.")
	TEST_ASSERT(findtext(mark_text, "Перезарядка савана [HERETIC_ASH_SHROUD_COOLDOWN / (1 SECONDS)] секунд"), "Метка называет перезарядку савана.")
	TEST_ASSERT(findtext(mark_text, "из [HERETIC_ASH_SHROUD_DOOR_RANGE] клеток"), "Метка называет дальность двери.")
	var/datum/eldritch_knowledge/base_ash/ash = allocate(/datum/eldritch_knowledge/base_ash)
	var/base_text = jointext(ash.details, " ")
	TEST_ASSERT(findtext(base_text, "на [HERETIC_ASH_PRINT_LIFETIME / (1 MINUTES)] минут"), "Ремесло называет срок отпечатка.")
	TEST_ASSERT(findtext(base_text, "раз в [HERETIC_ASH_PRINT_HARVEST / (1 SECONDS)] секунд"), "Ремесло называет ритм углей.")
	TEST_ASSERT(findtext(base_text, "до [HERETIC_ASH_PRINT_LIMIT] отпечатков"), "Ремесло называет предел отпечатков.")
	var/datum/heretic_path/path = GLOB.heretic_paths[PATH_ASH]
	TEST_ASSERT(findtext(path.capture_summary, "саван"), "Захват пути - саван.")
	TEST_ASSERT(findtext(path.escape_summary, "отпечат"), "Уход называет отпечатки.")
	var/list/states = icon_states('modular_bluemoon/icons/obj/heretic_ash_fx.dmi')
	for(var/state in list("shroud_crust", "shroud_crust_glow", "shroud_forming", "shroud_forming_glow", "shroud_shatter", "ember_print", "ember_print_glow", "ember_print_cold", "ash_arc", "ash_arc_glow", "ash_drain"))
		TEST_ASSERT(state in states, "Стейт [state] есть в heretic_ash_fx.dmi.")

/mob/living/heretic_sound_listener
	var/list/heard = list()

/mob/living/heretic_sound_listener/playsound_local(turf/turf_source, soundin, vol, vary, frequency, falloff_exponent, channel, pressure_affected, sound/S, max_distance, falloff_distance, distance_multiplier, envwet, envdry, virtual_hearer, source_pressure, list/source_echo)
	heard += "[soundin]"

/datum/unit_test/proc/allocate_sound_listener(turf/location)
	var/mob/living/heretic_sound_listener/listener = allocate(/mob/living/heretic_sound_listener, location)
	listener.enable_client_mobs_in_contents()
	return listener

/// Каскад звучит вспышкой огня вместо сварки и один раз, Угасание - разжиганием, а не атакой, клятва зажигает кольцо со звуком, саван запекается своим звуком.
/datum/unit_test/heretic_ash_sound_meanings/Run()
	var/datum/antagonist/heretic/heretic = allocate_ash_marker()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/mob/living/heretic_sound_listener/ear = allocate_sound_listener(get_turf(user))
	var/burst = "[file('modular_bluemoon/sound/heretic/ash_burst.ogg')]"
	var/obj/effect/proc_holder/spell/aoe_turf/fire_cascade/plain = allocate(/obj/effect/proc_holder/spell/aoe_turf/fire_cascade)
	plain.cascade_opening(get_turf(user), user)
	TEST_ASSERT(burst in ear.heard, "Каскад Пепельного духа открывается огненной вспышкой.")
	TEST_ASSERT(!("[file('sound/items/welder.ogg')]" in ear.heard), "Каскад не звучит сваркой.")
	ear.heard.Cut()
	var/obj/effect/proc_holder/spell/aoe_turf/fire_cascade/big/cascade = allocate(/obj/effect/proc_holder/spell/aoe_turf/fire_cascade/big)
	cascade.cascade_opening(get_turf(user), user)
	var/bursts = 0
	for(var/sound_file in ear.heard)
		if(sound_file == burst)
			bursts++
	TEST_ASSERT_EQUAL(bursts, 1, "Каскад вознесения звучит одной вспышкой.")
	ear.heard.Cut()
	var/datum/eldritch_knowledge/base_ash/ash = heretic.get_knowledge(/datum/eldritch_knowledge/base_ash)
	var/obj/effect/proc_holder/spell/self/heretic_power/ash/ember = allocate(/obj/effect/proc_holder/spell/self/heretic_power/ash)
	ember.activate_power(user, ash)
	TEST_ASSERT("[HERETIC_ASH_REKINDLE_SOUND]" in ear.heard, "Угасание звучит разжиганием.")
	TEST_ASSERT(!(burst in ear.heard), "Лечение Угасанием не звучит атакой каскада.")
	ear.heard.Cut()
	var/obj/effect/proc_holder/spell/targeted/fire_sworn/oath = allocate(/obj/effect/proc_holder/spell/targeted/fire_sworn)
	oath.cast(list(user), user)
	TEST_ASSERT("[HERETIC_ASH_OATH_SOUND]" in ear.heard, "Кольцо Клятвы огня разгорается со звуком.")
	oath.remove()
	ear.heard.Cut()
	var/turf/spot = get_step(get_step(user, EAST), EAST)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, spot)
	set_ash_burning_downed(victim)
	TEST_ASSERT(ash.try_shroud(user, victim), "Саван ложится на горящую сбитую цель.")
	TEST_ASSERT("[HERETIC_ASH_BAKE_SOUND]" in ear.heard, "Саван запекается своим звуком.")
	TEST_ASSERT(!("[file('sound/effects/extinguish.ogg')]" in ear.heard), "Запекание не звучит как залитый огонь.")

/// Поток Обряда ночного дозора рисуется пепельным огнём на каждой клетке, без tg-пламени.
/datum/unit_test/heretic_ash_rite_flames/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/turf/first = get_step(user, EAST)
	var/turf/second = get_step(first, EAST)
	var/obj/effect/proc_holder/spell/pointed/nightwatchers_rite/rite = allocate(/obj/effect/proc_holder/spell/pointed/nightwatchers_rite)
	rite.fire_line(user, list(first, second))
	for(var/turf/lane as anything in list(first, second))
		TEST_ASSERT_NOTNULL(locate(/obj/effect/temp_visual/heretic_ash_flame) in lane, "Клетка потока горит пепельным огнём.")
		TEST_ASSERT_NULL(locate(/obj/effect/hotspot) in lane, "Поток не рисуется tg-пламенем.")
