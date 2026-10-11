/datum/unit_test/proc/flesh_latch_heretic()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_FLESH)
	heretic.gain_knowledge(/datum/eldritch_knowledge/flesh_grasp)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/touch_of_madness)
	return heretic

/datum/unit_test/proc/await_flesh_latch(mob/living/victim, max_wait = 2 SECONDS)
	var/list/budget = new_wait_budget(max_wait, "хватка слуги на [victim]")
	while(!victim.has_status_effect(/datum/status_effect/heretic_flesh_latch))
		if(!wait_budget_tick(budget))
			break
	return victim.has_status_effect(/datum/status_effect/heretic_flesh_latch)

/datum/unit_test/proc/flesh_clear_immunity(mob/living/victim)
	for(var/datum/status_effect/heretic_capture_immunity/immunity as anything in victim.has_status_effect_list(/datum/status_effect/heretic_capture_immunity))
		qdel(immunity)

/datum/unit_test/proc/flesh_touch(obj/effect/proc_holder/spell/targeted/touch/mad_touch/spell, mob/living/user, mob/living/victim)
	spell.charge_counter = 0
	spell.ChargeHand(user)
	spell.attached_hand.afterattack(victim, user, TRUE)

/datum/unit_test/proc/flesh_rune_reserve(obj/effect/eldritch/rune, atom/movable/ingredient)
	GLOB.heretic_ritual_reservations[ingredient] = rune
	rune.reserved_atoms += ingredient
	rune.reserved_locations[ingredient] = ingredient.loc

/// Захват Плоти приходит на третьей ступени Касанием безумия, девятая ступень просит две души, у хватки своя защёлка.
/datum/unit_test/heretic_flesh_path_order/Run()
	var/datum/heretic_path/path = GLOB.heretic_paths[PATH_FLESH]
	var/capture_stage = 0
	for(var/stage in 1 to length(path.knowledge))
		var/datum/eldritch_knowledge/knowledge = path.knowledge[stage]
		if(initial(knowledge.role) == HERETIC_ROLE_CAPTURE)
			capture_stage = stage
	TEST_ASSERT(capture_stage >= 2 && capture_stage <= 4, "Захват Плоти на 2-4 ступени, а не на [capture_stage].")
	TEST_ASSERT_EQUAL(path.knowledge[capture_stage], /datum/eldritch_knowledge/spell/touch_of_madness, "Захват - Касание безумия.")
	var/datum/eldritch_knowledge/ninth = path.knowledge[9]
	TEST_ASSERT_EQUAL(initial(ninth.sacs_needed), HERETIC_PENULTIMATE_SACRIFICES, "Девятая ступень просит две души.")
	var/obj/effect/proc_holder/spell/targeted/touch/mad_touch/madness = /obj/effect/proc_holder/spell/targeted/touch/mad_touch
	TEST_ASSERT_EQUAL(initial(madness.charge_max), HERETIC_FLESH_MADNESS_COOLDOWN, "Касание перезаряжается как захват.")
	TEST_ASSERT_EQUAL(GLOB.heretic_capture_latch_sounds[HERETIC_FLESH_CAPTURE], 'modular_bluemoon/sound/heretic/capture/flesh_latch.ogg', "У хватки слуги своя защёлка.")

/// Касание сбивает цель, гуль в 3 клетках прыгает к ней и держит 10 секунд: цель обездвижена, экипаж её не утащит, сердце уводит её издалека; нулевой жезл рвёт жилы, после - невосприимчивость.
/datum/unit_test/heretic_flesh_latch/Run()
	allocated += new /datum/heretic_test_station_level(run_loc_floor_bottom_left.z)
	var/datum/antagonist/heretic/heretic = flesh_latch_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_flesh/flesh = heretic.get_knowledge(/datum/eldritch_knowledge/base_flesh)
	var/datum/eldritch_knowledge/flesh_grasp/grasp = heretic.get_knowledge(/datum/eldritch_knowledge/flesh_grasp)
	var/datum/eldritch_knowledge/spell/touch_of_madness/madness = heretic.get_knowledge(/datum/eldritch_knowledge/spell/touch_of_madness)
	var/turf/spot = get_step(user, EAST)
	var/mob/living/carbon/human/victim = allocate_hunt_victim(heretic, spot)
	var/mob/living/carbon/human/ghoul = oldpath_servant(heretic, grasp, /datum/antagonist/heretic_monster/ghoul, locate(spot.x + HERETIC_FLESH_LATCH_REACH, spot.y, spot.z))
	flesh_touch(madness.granted_spell, user, victim)
	TEST_ASSERT(victim.IsKnockdown(), "Касание сбивает цель.")
	TEST_ASSERT_NULL(victim.has_status_effect(/datum/status_effect/heretic_flesh_latch), "Пока жилы летят, цель ещё не держат.")
	var/datum/status_effect/heretic_flesh_latch/latch = await_flesh_latch(victim)
	TEST_ASSERT_NOTNULL(latch, "Гуль в 3 клетках вцепляется в сбитую цель.")
	TEST_ASSERT_EQUAL(latch.servant, ghoul, "Держит именно гуль.")
	TEST_ASSERT(get_dist(ghoul, victim) <= 1, "Гуль прыгнул к цели.")
	var/remaining = latch.duration - world.time
	TEST_ASSERT(remaining < HERETIC_FLESH_LATCH_DURATION + 1 && remaining > HERETIC_FLESH_LATCH_DURATION - 1 SECONDS, "Хватка держит 10 секунд: осталось [remaining] дс.")
	TEST_ASSERT(victim.IsParalyzed(), "Удержанная цель не двигается.")
	TEST_ASSERT(HAS_TRAIT(victim, TRAIT_HERETIC_CAPTURE_HOLD), "Хватка слуги - захват: цель можно растолкать.")
	TEST_ASSERT_EQUAL(victim.heretic_capture_mark?.path_id, PATH_FLESH, "Метка захвата в чернилах Плоти.")
	TEST_ASSERT(latch.binding in victim.vis_contents, "Жилы видны на цели.")
	TEST_ASSERT(latch.sinew, "Жила тянется от слуги к цели.")
	TEST_ASSERT(heretic.hunt_target_ready(victim), "Удержанная цель готова к обряду.")
	user.forceMove(locate(spot.x, spot.y + 4, spot.z))
	TEST_ASSERT_NOTNULL(flesh.pocket_door(user, victim), "Слуга держит, и сердце уводит цель издалека.")
	var/mob/living/carbon/human/crew = allocate(/mob/living/carbon/human, get_step(spot, NORTH))
	crew.start_pulling(victim)
	TEST_ASSERT(crew.pulling != victim, "Удержанную цель экипаж не утащит.")
	var/obj/item/nullrod/rod = allocate(/obj/item/nullrod)
	crew.put_in_hands(rod)
	var/obj/effect/abstract/heretic_vfx_attached/binding = latch.binding
	rod.melee_attack_chain(crew, victim)
	TEST_ASSERT(QDELETED(latch), "Нулевой жезл рвёт жилы.")
	TEST_ASSERT(!victim.IsParalyzed(), "Освобождённая цель снова может двигаться.")
	TEST_ASSERT_EQUAL(victim.getBruteLoss(), 0, "Жезл не бьёт удержанную цель.")
	TEST_ASSERT_NOTNULL(locate(/obj/effect/temp_visual/heretic_flesh_tear) in get_turf(victim), "Порванные жилы видны.")
	TEST_ASSERT(wait_for_qdeleted(binding), "Жилы снимаются с цели.")
	TEST_ASSERT(findtext(heretic_capture_block_reason(user, victim, HERETIC_FLESH_CAPTURE), "приходит в себя"), "После хватки цель к ней невосприимчива.")

/// Хватку срывают оглушённый, скованный, оттащенный и убитый слуга, «растолкать», нулевой жезл по слуге и острое на «Помощи» за 2 секунды; удар на «Вреде» жилы не режет.
/datum/unit_test/heretic_flesh_latch_breaks/Run()
	var/datum/antagonist/heretic/heretic = flesh_latch_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_flesh/flesh = heretic.get_knowledge(/datum/eldritch_knowledge/base_flesh)
	var/datum/eldritch_knowledge/flesh_grasp/grasp = heretic.get_knowledge(/datum/eldritch_knowledge/flesh_grasp)
	var/turf/spot = get_step(user, EAST)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, spot)
	var/mob/living/carbon/human/ghoul = oldpath_servant(heretic, grasp, /datum/antagonist/heretic_monster/ghoul, get_step(spot, EAST))
	var/mob/living/carbon/human/crew = allocate(/mob/living/carbon/human, get_step(spot, NORTH))
	var/datum/status_effect/heretic_flesh_latch/latch = victim.apply_status_effect(/datum/status_effect/heretic_flesh_latch, flesh, user, ghoul)
	TEST_ASSERT_NOTNULL(latch, "Гуль держит цель.")
	TEST_ASSERT(latch in flesh.latches, "Знание помнит хватку.")
	ghoul.Paralyze(5 SECONDS)
	latch.tick()
	TEST_ASSERT(QDELETED(latch), "Оглушённый слуга разжимает хватку.")
	TEST_ASSERT(!(latch in flesh.latches), "Знание забывает снятую хватку.")
	ghoul.SetParalyzed(0)
	flesh_clear_immunity(victim)
	latch = victim.apply_status_effect(/datum/status_effect/heretic_flesh_latch, flesh, user, ghoul)
	oldpath_door_cuff(ghoul)
	latch.tick()
	TEST_ASSERT(QDELETED(latch), "Скованный слуга разжимает хватку.")
	ghoul.uncuff()
	flesh_clear_immunity(victim)
	latch = victim.apply_status_effect(/datum/status_effect/heretic_flesh_latch, flesh, user, ghoul)
	ghoul.forceMove(locate(spot.x + 2, spot.y, spot.z))
	TEST_ASSERT(QDELETED(latch), "Оттащенный слуга выпускает цель.")
	ghoul.forceMove(get_step(spot, EAST))
	flesh_clear_immunity(victim)
	latch = victim.apply_status_effect(/datum/status_effect/heretic_flesh_latch, flesh, user, ghoul)
	SEND_SIGNAL(victim, COMSIG_LIVING_HERETIC_CAPTURE_SHAKEN, crew)
	TEST_ASSERT(QDELETED(latch), "Растолканная цель выходит из хватки.")
	flesh_clear_immunity(victim)
	latch = victim.apply_status_effect(/datum/status_effect/heretic_flesh_latch, flesh, user, ghoul)
	var/obj/item/nullrod/rod = allocate(/obj/item/nullrod)
	crew.put_in_hands(rod)
	crew.forceMove(get_step(ghoul, NORTH))
	rod.melee_attack_chain(crew, ghoul)
	TEST_ASSERT(QDELETED(latch), "Нулевой жезл по слуге рвёт жилы.")
	crew.forceMove(get_step(spot, NORTH))
	crew.dropItemToGround(rod)
	flesh_clear_immunity(victim)
	latch = victim.apply_status_effect(/datum/status_effect/heretic_flesh_latch, flesh, user, ghoul)
	var/obj/item/kitchen/knife/knife = allocate(/obj/item/kitchen/knife)
	crew.put_in_hands(knife)
	crew.a_intent = INTENT_HARM
	knife.melee_attack_chain(crew, victim)
	TEST_ASSERT(!QDELETED(latch), "Удар ножом на «Вреде» жилы не режет.")
	victim.fully_heal()
	crew.a_intent = INTENT_HELP
	knife.melee_attack_chain(crew, victim)
	TEST_ASSERT(!QDELETED(latch), "Жилы режутся не сразу.")
	TEST_ASSERT(wait_for_qdeleted(latch, HERETIC_FLESH_LATCH_CUT_TIME + 1 SECONDS), "Нож на «Помощи» срезает жилы за 2 секунды.")
	TEST_ASSERT_EQUAL(victim.getBruteLoss(), 0, "Срезая жилы, цель не ранят.")
	flesh_clear_immunity(victim)
	latch = victim.apply_status_effect(/datum/status_effect/heretic_flesh_latch, flesh, user, ghoul)
	ghoul.death()
	TEST_ASSERT(QDELETED(latch), "Смерть слуги снимает хватку.")

/// Без слуги рядом касание только валит; слуга, сбитый пока жилы летят, не вцепляется, а касание возвращается через 10 секунд.
/datum/unit_test/heretic_flesh_latch_refund/Run()
	var/datum/antagonist/heretic/heretic = flesh_latch_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/flesh_grasp/grasp = heretic.get_knowledge(/datum/eldritch_knowledge/flesh_grasp)
	var/datum/eldritch_knowledge/spell/touch_of_madness/madness = heretic.get_knowledge(/datum/eldritch_knowledge/spell/touch_of_madness)
	var/obj/effect/proc_holder/spell/targeted/touch/mad_touch/spell = madness.granted_spell
	var/turf/spot = get_step(user, EAST)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, spot)
	flesh_touch(spell, user, victim)
	TEST_ASSERT(victim.IsKnockdown(), "Без слуги касание всё равно валит.")
	TEST_ASSERT(!HAS_TRAIT(victim, TRAIT_HERETIC_CAPTURE_HOLD), "Без слуги держать некому.")
	var/mob/living/carbon/human/ghoul = oldpath_servant(heretic, grasp, /datum/antagonist/heretic_monster/ghoul, locate(spot.x + 2, spot.y, spot.z))
	var/turf/ghoul_spot = get_turf(ghoul)
	flesh_touch(spell, user, victim)
	ghoul.Paralyze(5 SECONDS)
	var/list/budget = new_wait_budget(HERETIC_FLESH_LATCH_TELEGRAPH + 1 SECONDS, "возврат касания")
	while(spell.charge_counter < spell.charge_max - HERETIC_FLESH_LATCH_RETRY)
		if(!wait_budget_tick(budget))
			break
	TEST_ASSERT(spell.charge_counter >= spell.charge_max - HERETIC_FLESH_LATCH_RETRY, "Сорванная хватка возвращает касание через 10 секунд: [spell.charge_counter] из [spell.charge_max].")
	TEST_ASSERT(spell.charge_counter < spell.charge_max, "Касание возвращается не мгновенно.")
	TEST_ASSERT_NULL(victim.has_status_effect(/datum/status_effect/heretic_flesh_latch), "Сбитый слуга не вцепляется.")
	TEST_ASSERT_EQUAL(get_turf(ghoul), ghoul_spot, "Сбитый слуга не прыгает.")
	TEST_ASSERT_NULL(heretic_capture_block_reason(user, victim, HERETIC_FLESH_CAPTURE), "Несостоявшаяся хватка не даёт невосприимчивости.")

/// Повторное касание продлевает фобию, а не добавляет вторую.
/datum/unit_test/heretic_flesh_madness_phobia/Run()
	var/datum/antagonist/heretic/heretic = flesh_latch_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/spell/touch_of_madness/madness = heretic.get_knowledge(/datum/eldritch_knowledge/spell/touch_of_madness)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	flesh_touch(madness.granted_spell, user, victim)
	flesh_touch(madness.granted_spell, user, victim)
	var/obj/item/organ/brain/brain = victim.getorganslot(ORGAN_SLOT_BRAIN)
	TEST_ASSERT_EQUAL(length(brain.traumas), 1, "Две фобии от двух касаний не копятся.")
	var/datum/status_effect/heretic_flesh_phobia/phobia = victim.has_status_effect(/datum/status_effect/heretic_flesh_phobia)
	TEST_ASSERT_NOTNULL(phobia, "Фобия держится как состояние.")
	qdel(phobia)
	TEST_ASSERT_EQUAL(length(brain.traumas), 0, "Конец состояния снимает фобию.")

/// Без отклика духов гуль встаёт пустым: тратит биомассу, бьётся в судорогах, идёт за хозяином, бьёт цель Живого шва и того, кто ранит хозяина.
/datum/unit_test/heretic_flesh_soulless_ghoul/Run()
	var/datum/antagonist/heretic/heretic = flesh_latch_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_flesh/flesh = heretic.get_knowledge(/datum/eldritch_knowledge/base_flesh)
	var/datum/eldritch_knowledge/flesh_grasp/grasp = heretic.get_knowledge(/datum/eldritch_knowledge/flesh_grasp)
	var/datum/eldritch_knowledge/flesh_grasp/ghost_poll_probe/probe = allocate(/datum/eldritch_knowledge/flesh_grasp/ghost_poll_probe)
	heretic.researched_knowledge[probe.type] = probe
	var/mob/living/carbon/human/corpse = allocate(/mob/living/carbon/human, get_step(user, EAST))
	corpse.death()
	flesh.combat_resource = 2
	TEST_ASSERT(probe.on_mansus_grasp(corpse, user, TRUE), "Хватка зовёт духов.")
	TEST_ASSERT(corpse.stat != DEAD, "Без отклика тело всё равно встаёт.")
	TEST_ASSERT_EQUAL(flesh.combat_resource, 1, "Пустой гуль стоит одну биомассу.")
	TEST_ASSERT_NOTNULL(corpse.mind?.has_antag_datum(/datum/antagonist/heretic_monster/ghoul), "Пустое тело - гуль еретика.")
	allocated += corpse.mind
	var/datum/component/heretic_flesh_puppet/puppet = corpse.GetComponent(/datum/component/heretic_flesh_puppet)
	TEST_ASSERT_NOTNULL(puppet, "Пустым гулем правит голод.")
	TEST_ASSERT_NOTNULL(locate(/obj/effect/temp_visual/heretic_flesh_husk/rise) in get_turf(corpse), "Подъём виден судорогой.")
	TEST_ASSERT(!COOLDOWN_FINISHED(probe, servant_poll_cooldown), "Пустой опрос ставит паузу перед следующим.")
	var/mob/living/carbon/human/second = allocate(/mob/living/carbon/human, get_step(user, NORTH))
	second.death()
	probe.last_poll_body = null
	TEST_ASSERT(probe.on_mansus_grasp(second, user, TRUE), "Пока духи молчат, тело встаёт сразу.")
	TEST_ASSERT_NULL(probe.last_poll_body, "Во время паузы духов не зовут.")
	TEST_ASSERT(second.stat != DEAD, "Второй пустой гуль поднят.")
	allocated += second.mind
	STOP_PROCESSING(SSfastprocess, puppet)
	var/datum/component/heretic_flesh_puppet/second_puppet = second.GetComponent(/datum/component/heretic_flesh_puppet)
	STOP_PROCESSING(SSfastprocess, second_puppet)
	var/list/examine_text = corpse.examine(user)
	TEST_ASSERT(findtext(jointext(examine_text, " "), "Пустой слуга"), "Хозяин видит, что слуга пустой.")
	corpse.forceMove(get_step(user, EAST))
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, locate(user.x + 3, user.y, user.z))
	grasp.granted_spell.cast(list(victim), user)
	TEST_ASSERT_EQUAL(puppet.prey_ref?.resolve(), victim, "Живой шов задаёт цель пустому слуге.")
	var/damage = victim.getBruteLoss()
	puppet.plan_path(victim)
	for(var/attempt in 1 to 12)
		COOLDOWN_RESET(puppet, step_cooldown)
		COOLDOWN_RESET(puppet, attack_cooldown)
		puppet.process()
		if(victim.getBruteLoss() > damage)
			break
	TEST_ASSERT(corpse.Adjacent(victim), "Пустой слуга дошёл до цели.")
	TEST_ASSERT(victim.getBruteLoss() > damage, "Пустой слуга бьёт цель шва.")
	puppet.prey_ref = null
	var/mob/living/carbon/human/attacker = allocate(/mob/living/carbon/human, get_step(user, SOUTH))
	puppet.process()
	SEND_SIGNAL(user, COMSIG_LIVING_ATTACKER_SET, attacker)
	TEST_ASSERT_EQUAL(puppet.prey_ref?.resolve(), attacker, "Пустой слуга бросается на того, кто ранит хозяина.")
	probe.release_flesh_servants()
	heretic.researched_knowledge -= probe.type
	puppet.process()
	TEST_ASSERT(QDELETED(puppet), "Потеря знания отпускает пустого слугу.")

/// Без отклика пророк встаёт пустым у руны; во время паузы духов не зовут, даже если кто-то готов откликнуться.
/datum/unit_test/heretic_flesh_soulless_summon/Run()
	var/datum/antagonist/heretic/heretic = flesh_latch_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/summon/raw_prophet/ghost_poll_probe/probe = allocate(/datum/eldritch_knowledge/summon/raw_prophet/ghost_poll_probe)
	heretic.researched_knowledge[probe.type] = probe
	var/turf/rune_turf = get_step(user, EAST)
	var/obj/effect/eldritch/rune = allocate(/obj/effect/eldritch, rune_turf)
	var/obj/item/paper/ingredient = allocate(/obj/item/paper, rune_turf)
	flesh_rune_reserve(rune, ingredient)
	TEST_ASSERT_NULL(probe.recipe_block_reason(user), "Пауза духов не запрещает обряд.")
	TEST_ASSERT(probe.on_finished_recipe(user, list(ingredient), rune_turf), "Без отклика пророк встаёт пустым.")
	var/mob/living/simple_animal/hostile/eldritch/raw_prophet/prophet = locate() in rune_turf
	TEST_ASSERT_NOTNULL(prophet, "Пророк стоит у руны.")
	allocated += prophet
	TEST_ASSERT_NULL(prophet.key, "У пустого пророка нет игрока.")
	TEST_ASSERT_NOTNULL(prophet.GetComponent(/datum/component/heretic_flesh_puppet), "Пустым пророком правит голод.")
	TEST_ASSERT_EQUAL(prophet.AIStatus, AI_OFF, "Свой ИИ пророка не включается.")
	TEST_ASSERT_EQUAL(length(probe.flesh_servants), 1, "Пустой пророк в свите.")
	TEST_ASSERT(!COOLDOWN_FINISHED(probe, servant_poll_cooldown), "Пустой опрос ставит паузу.")
	probe.poll_result = list(user)
	TEST_ASSERT(probe.on_finished_recipe(user, list(ingredient), rune_turf), "Во время паузы второй пророк тоже встаёт.")
	var/mob/living/simple_animal/hostile/eldritch/raw_prophet/second
	for(var/mob/living/simple_animal/hostile/eldritch/raw_prophet/candidate in rune_turf)
		if(candidate != prophet)
			second = candidate
	TEST_ASSERT_NOTNULL(second, "Второй пророк стоит у руны.")
	allocated += second
	TEST_ASSERT_NOTNULL(second.GetComponent(/datum/component/heretic_flesh_puppet), "Во время паузы духов не зовут: пророк пустой.")
	heretic.researched_knowledge -= probe.type

/// Хватка на «Разоружении» за 2 секунды вынимает из трупа один орган, кроме мозга; вскрытое тело второй раз не открыть, и экипаж это видит.
/datum/unit_test/heretic_flesh_excise/Run()
	var/datum/antagonist/heretic/heretic = flesh_latch_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_flesh/flesh = heretic.get_knowledge(/datum/eldritch_knowledge/base_flesh)
	var/datum/eldritch_knowledge/flesh_grasp/grasp = heretic.get_knowledge(/datum/eldritch_knowledge/flesh_grasp)
	var/turf/spot = get_step(user, EAST)
	var/mob/living/carbon/human/corpse = allocate(/mob/living/carbon/human, spot)
	corpse.death()
	user.a_intent = INTENT_DISARM
	flesh.combat_resource = 2
	TEST_ASSERT(!grasp.on_mansus_grasp(corpse, user, TRUE), "На «Разоружении» хватка не поднимает гуля.")
	var/organs_before = length(corpse.internal_organs)
	var/started = world.time
	TEST_ASSERT(flesh.on_mansus_grasp(corpse, user, TRUE), "Хватка на «Разоружении» вскрывает труп.")
	TEST_ASSERT(world.time - started >= HERETIC_FLESH_EXCISE_TIME - 1, "Вскрытие занимает 2 секунды.")
	TEST_ASSERT_EQUAL(length(corpse.internal_organs), organs_before - 1, "Из трупа вынут ровно один орган.")
	var/obj/item/organ/taken = locate() in spot
	TEST_ASSERT_NOTNULL(taken, "Орган лежит на полу.")
	allocated += taken
	TEST_ASSERT(!(taken.organ_flags & ORGAN_VITAL), "Мозг хватка не трогает.")
	TEST_ASSERT_NOTNULL(corpse.getorganslot(ORGAN_SLOT_BRAIN), "Мозг остаётся в теле.")
	TEST_ASSERT_EQUAL(flesh.combat_resource, 2, "Вскрытие не тратит биомассу.")
	TEST_ASSERT(findtext(jointext(corpse.examine(allocate(/mob/living/carbon/human, run_loc_floor_top_right)), " "), "стянуты живыми жилами"), "Экипаж видит вскрытое тело.")
	TEST_ASSERT(!flesh.on_mansus_grasp(corpse, user, TRUE), "Второй раз тело не вскрыть.")
	TEST_ASSERT(findtext(flesh.grasp_failure_reason, "уже вскрыто"), "Отказ объясняет причину: [flesh.grasp_failure_reason]")
	var/mob/living/carbon/human/living = allocate(/mob/living/carbon/human, get_step(user, NORTH))
	var/living_organs = length(living.internal_organs)
	TEST_ASSERT(!flesh.on_mansus_grasp(living, user, TRUE), "Живого хватка не вскрывает.")
	TEST_ASSERT_EQUAL(length(living.internal_organs), living_organs, "У живого органы на месте.")

/// Иссекающая сталь срезает лоскут биомассы только со сбитой или удержанной цели и не чаще раза в 20 секунд.
/datum/unit_test/heretic_flesh_flay/Run()
	var/datum/antagonist/heretic/heretic = flesh_latch_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	heretic.gain_knowledge(/datum/eldritch_knowledge/flesh_blade_upgrade)
	var/datum/eldritch_knowledge/base_flesh/flesh = heretic.get_knowledge(/datum/eldritch_knowledge/base_flesh)
	var/datum/eldritch_knowledge/flesh_grasp/grasp = heretic.get_knowledge(/datum/eldritch_knowledge/flesh_grasp)
	var/datum/eldritch_knowledge/flesh_blade_upgrade/steel = heretic.get_knowledge(/datum/eldritch_knowledge/flesh_blade_upgrade)
	var/turf/spot = get_step(user, EAST)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, spot)
	flesh.combat_resource = 0
	steel.on_eldritch_blade(victim, user, TRUE)
	TEST_ASSERT_EQUAL(flesh.combat_resource, 0, "Со стоящей цели лоскут не срезать.")
	TEST_ASSERT(victim.getBruteLoss() > 0, "Клинок по-прежнему добавляет ушибы.")
	victim.Knockdown(5 SECONDS)
	steel.on_eldritch_blade(victim, user, TRUE)
	TEST_ASSERT_EQUAL(flesh.combat_resource, 1, "Со сбитой цели клинок срезает лоскут биомассы.")
	steel.on_eldritch_blade(victim, user, TRUE)
	TEST_ASSERT_EQUAL(flesh.combat_resource, 1, "Второй лоскут - не раньше чем через 20 секунд.")
	COOLDOWN_RESET(steel, flay_cooldown)
	victim.SetKnockdown(0)
	var/mob/living/carbon/human/ghoul = oldpath_servant(heretic, grasp, /datum/antagonist/heretic_monster/ghoul, get_step(spot, EAST))
	victim.apply_status_effect(/datum/status_effect/heretic_flesh_latch, flesh, user, ghoul)
	steel.on_eldritch_blade(victim, user, TRUE)
	TEST_ASSERT_EQUAL(flesh.combat_resource, 2, "С удержанной слугой цели лоскут тоже срезается.")

/// Ползун сшивается видимо и с собственным телом; Живой шов, Сшивание, метка и хватка слуги рисуются своими стейтами.
/datum/unit_test/heretic_flesh_visuals/Run()
	var/datum/antagonist/heretic/heretic = flesh_latch_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_flesh/flesh = heretic.get_knowledge(/datum/eldritch_knowledge/base_flesh)
	flesh.combat_resource = flesh.combat_resource_max
	var/turf/spot = get_step(user, EAST)
	var/obj/item/organ/heart/organ = allocate(/obj/item/organ/heart, spot)
	TEST_ASSERT(flesh.grow_fleshling(user, organ), "Ползун сшит.")
	var/mob/living/simple_animal/heretic_fleshling/crawler = flesh.fleshling
	allocated += crawler
	STOP_PROCESSING(SSfastprocess, crawler)
	TEST_ASSERT_NOTNULL(locate(/obj/effect/temp_visual/heretic_flesh_knit) in spot, "Сшивание ползуна видно.")
	TEST_ASSERT_EQUAL(crawler.icon, 'modular_bluemoon/icons/mob/heretic_flesh_mobs.dmi', "У ползуна своё тело, а не пророк.")
	TEST_ASSERT(crawler.icon_state in icon_states(crawler.icon), "Стейт ползуна нарисован.")
	var/list/fx_states = icon_states('modular_bluemoon/icons/obj/heretic_flesh_fx.dmi')
	for(var/state in list("tendon", "flesh_mark", "latch_bind", "flesh_stitch", "madness_flash", "flesh_shift_unravel", "flesh_shift_knit"))
		TEST_ASSERT(state in fx_states, "Стейт [state] нарисован.")
	var/list/large_states = icon_states('modular_bluemoon/icons/obj/heretic_flesh_effects.dmi')
	for(var/state in list("crawler_knit", "crawler_unravel", "latch_tear", "flesh_rupture"))
		TEST_ASSERT(state in large_states, "Стейт [state] нарисован.")
	var/datum/status_effect/eldritch/flesh/mark = /datum/status_effect/eldritch/flesh
	TEST_ASSERT_EQUAL(initial(mark.effect_sprite_icon), 'modular_bluemoon/icons/obj/heretic_flesh_fx.dmi', "Метка Плоти рисуется своим сердцем.")
	var/obj/effect/proc_holder/spell/pointed/heretic_flesh_stitch/stitch = /obj/effect/proc_holder/spell/pointed/heretic_flesh_stitch
	var/obj/effect/proc_holder/spell/self/heretic_power/flesh/mend = /obj/effect/proc_holder/spell/self/heretic_power/flesh
	TEST_ASSERT(initial(stitch.action_icon_state) != initial(mend.action_icon_state), "У Живого шва и Сшивания разные значки.")
	qdel(crawler)
	TEST_ASSERT_NOTNULL(locate(/obj/effect/temp_visual/heretic_flesh_unravel) in spot, "Распад ползуна виден.")

/// Хватка Плоти звучит своим набором влажных хватов, а не раной tg.
/datum/unit_test/heretic_flesh_grasp_sounds/Run()
	var/datum/eldritch_knowledge/base_flesh/flesh = allocate(/datum/eldritch_knowledge/base_flesh)
	TEST_ASSERT_EQUAL(flesh.grasp_sound, HERETIC_FLESH_GRASP_SFX, "Хватка Плоти берёт звук из набора.")
	var/datum/sound_effect/grasp = GLOB.sfx_datum_by_key[HERETIC_FLESH_GRASP_SFX]
	TEST_ASSERT_NOTNULL(grasp, "Набор хватки Плоти зарегистрирован.")
	TEST_ASSERT(length(grasp?.file_paths) >= 2, "В наборе несколько хватов.")
	var/list/seen = list()
	for(var/sound_file in grasp?.file_paths)
		TEST_ASSERT(findtext("[sound_file]", "modular_bluemoon/sound/heretic/flesh_grasp") == 1, "[sound_file] - свой хват Плоти.")
		TEST_ASSERT(!seen["[sound_file]"], "[sound_file] не повторяется в наборе.")
		seen["[sound_file]"] = TRUE

/// Слуги Плоти проходят сквозь стены клубком жил: свой переход, свои рисунки и звуки, без пепла.
/datum/unit_test/heretic_flesh_servant_shift/Run()
	for(var/servant_type in list(/mob/living/simple_animal/hostile/eldritch/raw_prophet, /mob/living/simple_animal/hostile/eldritch/stalker))
		var/mob/living/simple_animal/hostile/eldritch/servant = allocate(servant_type, run_loc_floor_bottom_left)
		var/flesh_shift = FALSE
		for(var/spell_type in servant.spells_to_add)
			TEST_ASSERT(!ispath(spell_type, /obj/effect/proc_holder/spell/targeted/ethereal_jaunt/shift/ash), "[servant_type] не ходит пеплом.")
			if(ispath(spell_type, /obj/effect/proc_holder/spell/targeted/ethereal_jaunt/shift/flesh))
				flesh_shift = TRUE
		TEST_ASSERT(flesh_shift, "[servant_type] проходит сквозь стены клубком жил.")
	var/obj/effect/proc_holder/spell/targeted/ethereal_jaunt/shift/flesh/shift = allocate(/obj/effect/proc_holder/spell/targeted/ethereal_jaunt/shift/flesh)
	TEST_ASSERT_EQUAL(shift.action_icon_state, "flesh_shift", "Кнопка перехода слуг - своя, не пепельная.")
	for(var/visual_type in list(shift.jaunt_in_type, shift.jaunt_out_type))
		TEST_ASSERT(ispath(visual_type, /obj/effect/temp_visual/dir_setting/flesh_shift), "[visual_type] - рисунок Плоти.")
		var/obj/effect/temp_visual/visual = visual_type
		TEST_ASSERT(initial(visual.icon_state) in icon_states(initial(visual.icon)), "[visual_type] нарисован.")
	var/mob/living/carbon/human/walker = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/mob/living/heretic_sound_listener/ear = allocate_sound_listener(get_turf(walker))
	shift.play_sound("enter", walker)
	shift.play_sound("exit", walker)
	TEST_ASSERT("[file('modular_bluemoon/sound/heretic/flesh_shift_unravel.ogg')]" in ear.heard, "Распад слуги слышен.")
	TEST_ASSERT("[file('modular_bluemoon/sound/heretic/flesh_shift_knit.ogg')]" in ear.heard, "Сшивание слуги слышно.")
	for(var/ash_sound in list("[file('modular_bluemoon/sound/heretic/ash_shift_in.ogg')]", "[file('modular_bluemoon/sound/heretic/ash_shift_out.ogg')]"))
		TEST_ASSERT(!(ash_sound in ear.heard), "Переход слуги не звучит пеплом.")

/// Над головой жертвы Касания безумия вспыхивает пурпурный надлом и гаснет.
/datum/unit_test/heretic_flesh_madness_flash/Run()
	var/datum/antagonist/heretic/heretic = flesh_latch_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/spell/touch_of_madness/madness = heretic.get_knowledge(/datum/eldritch_knowledge/spell/touch_of_madness)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	flesh_touch(madness.granted_spell, user, victim)
	var/obj/effect/abstract/heretic_vfx_attached/flash
	for(var/obj/effect/abstract/heretic_vfx_attached/visual in victim.vis_contents)
		if(visual.icon_state == "madness_flash")
			flash = visual
	TEST_ASSERT_NOTNULL(flash, "Над жертвой вспыхивает надлом безумия.")
	TEST_ASSERT(flash?.icon_state in icon_states(flash?.icon), "Надлом нарисован.")
	TEST_ASSERT(flash?.pixel_y > 0, "Надлом висит над головой.")
	TEST_ASSERT(wait_for_qdeleted(flash, 2 SECONDS), "Надлом гаснет.")

/// Тело лопается при сбросе облика и выплёвывается при возврате со своими звуками, слышными вокруг.
/datum/unit_test/heretic_flesh_shed_sounds/Run()
	var/turf/place = run_loc_floor_bottom_left
	var/mob/living/heretic_sound_listener/ear = allocate_sound_listener(place)
	var/mob/living/simple_animal/hostile/eldritch/armsy/prime/head = allocate(/mob/living/simple_animal/hostile/eldritch/armsy/prime, place, FALSE)
	heretic_flesh_shed_fx(head, null)
	TEST_ASSERT("[file('modular_bluemoon/sound/heretic/flesh_shed.ogg')]" in ear.heard, "Разрыв тела слышен вокруг.")
	var/mob/living/carbon/human/body = allocate(/mob/living/carbon/human, place)
	heretic_flesh_expel_fx(body, list())
	TEST_ASSERT("[file('modular_bluemoon/sound/heretic/flesh_expel.ogg')]" in ear.heard, "Выплюнутое тело слышно вокруг.")
