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
	for(var/thing_type in list(/obj/effect/temp_visual/heretic_ash_quench, /obj/effect/abstract/heretic_fire_ring, /obj/effect/temp_visual/heretic_ash_flame))
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
