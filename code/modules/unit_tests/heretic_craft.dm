/datum/unit_test/proc/capture_immunity(mob/living/victim, capture_id)
	for(var/datum/status_effect/heretic_capture_immunity/immunity as anything in victim.has_status_effect_list(/datum/status_effect/heretic_capture_immunity))
		if(immunity.capture_id == capture_id)
			return immunity
	return null

/datum/eldritch_knowledge/craft_removal_probe
	name = "Проверочное ремесло"
	var/removed_count = 0
	var/atom/last_crafted
	var/last_craft_id
	var/qdel_crafted = FALSE

/datum/eldritch_knowledge/craft_removal_probe/on_craft_removed(atom/crafted, craft_id)
	removed_count++
	last_crafted = crafted
	last_craft_id = craft_id
	if(qdel_crafted && !QDELETED(crafted))
		qdel(crafted)

/datum/eldritch_knowledge/craft_removal_probe/Destroy()
	last_crafted = null
	return ..()

/// Ремесло показывает улику экипажу и метку владельцу, нулевой жезл и удаление объекта снимают его и сообщают знанию.
/datum/unit_test/heretic_craft_component/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/craft_removal_probe/knowledge = allocate(/datum/eldritch_knowledge/craft_removal_probe)
	heretic.researched_knowledge[knowledge.type] = knowledge
	var/mob/living/carbon/human/crew = allocate(/mob/living/carbon/human, get_step(user, EAST))
	var/obj/structure/window/fulltile/window = allocate(/obj/structure/window/fulltile, get_step(crew, NORTH))
	var/overlays_before = length(window.overlays)
	var/mutable_appearance/marking = mutable_appearance('modular_bluemoon/icons/obj/heretic_alerts.dmi', "sigil_blade")
	var/datum/component/heretic_craft/craft = window.AddComponent(/datum/component/heretic_craft, knowledge, "probe_pane", "В стекле отражается не эта комната.", marking)
	TEST_ASSERT_NOTNULL(craft, "Компонент ремесла встаёт на окно.")
	TEST_ASSERT_EQUAL(heretic_craft_on(window, "probe_pane"), craft, "Ремесло находится по своему идентификатору.")
	TEST_ASSERT_NULL(heretic_craft_on(window, "other_pane"), "Чужой идентификатор ремесла не совпадает.")
	TEST_ASSERT_EQUAL(length(window.overlays), overlays_before + 1, "Метка ремесла легла на окно.")
	var/crew_view = jointext(window.examine(crew), " ")
	TEST_ASSERT(findtext(crew_view, "не эта комната"), "Экипаж видит улику при осмотре.")
	TEST_ASSERT(!findtext(crew_view, "Ваше ремесло"), "Экипажу не показывается строка владельца.")
	TEST_ASSERT(findtext(jointext(window.examine(user), " "), "Ваше ремесло"), "Владелец узнаёт своё ремесло.")
	TEST_ASSERT_EQUAL(window.AddComponent(/datum/component/heretic_craft, knowledge, "probe_pane", "Другая улика.", marking), craft, "Повторное ремесло не заменяет первое.")
	TEST_ASSERT_EQUAL(knowledge.removed_count, 0, "Отброшенный дубль не снимает ремесло.")
	TEST_ASSERT_EQUAL(length(window.overlays), overlays_before + 1, "Дубль не трогает метку.")
	var/obj/item/nullrod/rod = allocate(/obj/item/nullrod, crew)
	crew.put_in_hands(rod)
	rod.melee_attack_chain(crew, window)
	TEST_ASSERT_NULL(heretic_craft_on(window, "probe_pane"), "Нулевой жезл снимает ремесло.")
	TEST_ASSERT_EQUAL(knowledge.removed_count, 1, "Знание узнаёт о снятом ремесле.")
	TEST_ASSERT_EQUAL(knowledge.last_crafted, window, "Знанию передаётся объект ремесла.")
	TEST_ASSERT_EQUAL(knowledge.last_craft_id, "probe_pane", "Знанию передаётся идентификатор ремесла.")
	TEST_ASSERT_EQUAL(length(window.overlays), overlays_before, "Метка снята вместе с ремеслом.")
	TEST_ASSERT_EQUAL(window.obj_integrity, window.max_integrity, "Жезл снимает ремесло вместо удара по окну.")
	window.AddComponent(/datum/component/heretic_craft, knowledge, "probe_pane", "В стекле отражается не эта комната.")
	qdel(window)
	TEST_ASSERT_EQUAL(knowledge.removed_count, 2, "Удаление объекта тоже сообщает знанию.")

/// Владелец, удаляющий объект в on_craft_removed, не вызывает повторного Destroy ни через жезл, ни через qdel объекта.
/datum/unit_test/heretic_craft_owner_deletes_parent/Run()
	var/datum/eldritch_knowledge/craft_removal_probe/knowledge = allocate(/datum/eldritch_knowledge/craft_removal_probe)
	knowledge.qdel_crafted = TRUE
	var/mob/living/carbon/human/crew = allocate(/mob/living/carbon/human)
	var/obj/structure/window/fulltile/window = allocate(/obj/structure/window/fulltile, get_step(crew, EAST))
	window.AddComponent(/datum/component/heretic_craft, knowledge, "probe_pane", "В стекле отражается не эта комната.")
	var/obj/item/nullrod/rod = allocate(/obj/item/nullrod, crew)
	crew.put_in_hands(rod)
	rod.melee_attack_chain(crew, window)
	TEST_ASSERT(QDELETED(window), "Владелец удалил объект после снятия ремесла жезлом.")
	TEST_ASSERT_EQUAL(knowledge.removed_count, 1, "Снятие жезлом сообщает знанию один раз.")
	var/obj/structure/window/fulltile/second = allocate(/obj/structure/window/fulltile, get_step(crew, NORTH))
	second.AddComponent(/datum/component/heretic_craft, knowledge, "probe_pane", "В стекле отражается не эта комната.")
	qdel(second)
	TEST_ASSERT_EQUAL(knowledge.removed_count, 2, "Удаление объекта сообщает знанию один раз.")

/// Захват отказывает без живой цели, скованному еретику, цели под антимагией и цели, недавно освобождённой из того же захвата.
/datum/unit_test/heretic_capture_rules/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	TEST_ASSERT_NULL(heretic_capture_block_reason(user, victim, "glass"), "Свободная живая цель доступна для захвата.")
	var/datum/status_effect/heretic_capture_immunity/immunity = heretic_capture_release(victim, "glass")
	TEST_ASSERT_NOTNULL(immunity, "Выход из захвата даёт невосприимчивость.")
	TEST_ASSERT(abs(immunity.duration - world.time - HERETIC_CAPTURE_IMMUNITY) < 1, "Невосприимчивость длится [HERETIC_CAPTURE_IMMUNITY / (1 SECONDS)] с.")
	var/reason = heretic_capture_block_reason(user, victim, "glass")
	TEST_ASSERT(findtext(reason, "приходит в себя"), "Тот же захват отклонён невосприимчивостью.")
	TEST_ASSERT(findtext(reason, "осталось [HERETIC_CAPTURE_IMMUNITY / (1 SECONDS)] с"), "Отказ называет полный срок: [reason]")
	TEST_ASSERT(!findtext(heretic_capture_block_reason(user, victim, "sand"), "приходит в себя"), "Минута невосприимчивости касается только своего захвата.")
	TEST_ASSERT_EQUAL(heretic_capture_release(victim, "glass"), immunity, "Повторный выход продлевает прежнюю невосприимчивость.")
	var/same_capture = 0
	for(var/datum/status_effect/heretic_capture_immunity/each as anything in victim.has_status_effect_list(/datum/status_effect/heretic_capture_immunity))
		if(each.capture_id == "glass")
			same_capture++
	TEST_ASSERT_EQUAL(same_capture, 1, "Невосприимчивость к одному захвату не копится.")
	for(var/datum/status_effect/heretic_capture_immunity/each as anything in victim.has_status_effect_list(/datum/status_effect/heretic_capture_immunity))
		each.duration = world.time
	TEST_ASSERT_NULL(heretic_capture_block_reason(user, victim, "glass"), "Истёкшая невосприимчивость не держит.")
	for(var/datum/status_effect/heretic_capture_immunity/each as anything in victim.has_status_effect_list(/datum/status_effect/heretic_capture_immunity))
		qdel(each)
	var/datum/component/anti_magic/protection = victim.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5)
	TEST_ASSERT(findtext(heretic_capture_block_reason(user, victim, "glass"), "защищена от магии"), "Антимагия цели срывает захват.")
	TEST_ASSERT_EQUAL(protection.charges, 5, "Проверка захвата не тратит заряды антимагии.")
	qdel(protection)
	user.handcuffed = allocate(/obj/item/restraints/handcuffs, user)
	user.update_handcuffed()
	TEST_ASSERT(findtext(heretic_capture_block_reason(user, victim, "glass"), "наручниках"), "Скованный еретик не захватывает.")
	user.uncuff()
	TEST_ASSERT_NULL(heretic_capture_block_reason(user, victim, "glass"), "Снятые наручники возвращают захват.")
	TEST_ASSERT(findtext(heretic_capture_block_reason(user, user, "glass"), "Себя"), "Себя захватить нельзя.")
	var/datum/antagonist/heretic/other = allocate_heretic(get_step(user, NORTH))
	TEST_ASSERT(findtext(heretic_capture_block_reason(user, other.owner.current, "glass"), "своих"), "Другого еретика захватить нельзя.")
	var/mob/living/carbon/human/servant_body = allocate(/mob/living/carbon/human, get_step(user, NORTHEAST))
	var/datum/mind/servant_mind = allocate_mind()
	servant_mind.current = servant_body
	servant_body.mind = servant_mind
	var/datum/antagonist/heretic_monster/servant = allocate(/datum/antagonist/heretic_monster)
	servant.owner = servant_mind
	servant.silent = TRUE
	servant_mind.antag_datums = list(servant)
	TEST_ASSERT(findtext(heretic_capture_block_reason(user, servant_body, "glass"), "своих"), "Порождение Мансуса захватить нельзя.")
	victim.death()
	TEST_ASSERT(findtext(heretic_capture_block_reason(user, victim, "glass"), "живых"), "Мёртвое тело захватить нельзя.")
	TEST_ASSERT(findtext(heretic_capture_block_reason(user, null, "glass"), "некого"), "Без цели захват отклонён.")

/// Показ оставшихся секунд не сдвигается от дробного шума world.time.
/datum/unit_test/heretic_capture_seconds_left/Run()
	var/list/drifted = list()
	for(var/step in 0 to 599)
		// Дробный world.time за час раунда: после 42 с сумма с 60 с в float32 теряет младшие разряды.
		var/now = 50.78 + step * 61.3
		var/shown = heretic_capture_seconds_left(now + HERETIC_CAPTURE_IMMUNITY, now)
		if(shown != HERETIC_CAPTURE_IMMUNITY / (1 SECONDS))
			drifted += "[num2text(now, 9)] -> [shown]"
	TEST_ASSERT_EQUAL(length(drifted), 0, "Полный срок показывается ровно при любом дробном world.time: [jointext(drifted.Copy(1, min(length(drifted), 3) + 1), ", ")].")
	TEST_ASSERT_EQUAL(heretic_capture_seconds_left(world.time + 0.4 SECONDS), 1, "Остаток меньше секунды показывается как одна секунда.")
	TEST_ASSERT_EQUAL(heretic_capture_seconds_left(world.time + 12.5 SECONDS), 13, "Неполная секунда округляется вверх.")

/// Выход из захвата на 15 секунд закрывает цель и для других захватов, а срок от пробуждения сдвигает обе невосприимчивости.
/datum/unit_test/heretic_capture_shared_floor/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	heretic_capture_release(victim, "glass")
	var/reason = heretic_capture_block_reason(user, victim, "sand")
	TEST_ASSERT(findtext(reason, "другого захвата"), "Другой захват сразу после выхода отклонён: [reason]")
	TEST_ASSERT(findtext(reason, "осталось [HERETIC_CAPTURE_SHARED_IMMUNITY / (1 SECONDS)] с"), "Отказ называет срок общей передышки: [reason]")
	reason = heretic_capture_block_reason(user, victim, "glass")
	TEST_ASSERT(findtext(reason, "осталось [HERETIC_CAPTURE_IMMUNITY / (1 SECONDS)] с"), "Тот же захват по-прежнему ждёт минуту: [reason]")
	for(var/datum/status_effect/heretic_capture_immunity/immunity as anything in victim.has_status_effect_list(/datum/status_effect/heretic_capture_immunity))
		if(immunity.capture_id != "glass")
			immunity.duration = world.time
	TEST_ASSERT_NULL(heretic_capture_block_reason(user, victim, "sand"), "После общей передышки другой захват доступен.")
	TEST_ASSERT(findtext(heretic_capture_block_reason(user, victim, "glass"), "приходит в себя"), "Минута к тому же захвату ещё идёт.")
	var/mob/living/carbon/human/sleeper = allocate(/mob/living/carbon/human, get_step(user, NORTH))
	var/datum/status_effect/heretic_capture_immunity/woken = heretic_capture_release(sleeper, "echo", HERETIC_ECHO_LULLABY_SLEEP)
	TEST_ASSERT(abs(woken.duration - world.time - HERETIC_ECHO_LULLABY_SLEEP - HERETIC_CAPTURE_IMMUNITY) < 1, "Минута отсчитывается от пробуждения: [woken.duration - world.time] дс.")
	reason = heretic_capture_block_reason(user, sleeper, "sand")
	TEST_ASSERT(findtext(reason, "осталось [(HERETIC_ECHO_LULLABY_SLEEP + HERETIC_CAPTURE_SHARED_IMMUNITY) / (1 SECONDS)] с"), "Общая передышка тоже отсчитывается от пробуждения: [reason]")

/datum/unit_test/heretic_capture_shake
	var/shake_done = FALSE
	var/shake_result

/datum/unit_test/heretic_capture_shake/proc/shake_async(mob/living/helper, mob/living/victim)
	shake_result = heretic_capture_shake(helper, victim)
	shake_done = TRUE

/datum/unit_test/heretic_capture_shake/proc/await_shake_end(mob/living/helper, mob/living/victim)
	var/list/budget = new_wait_budget(HERETIC_CAPTURE_SHAKE_TIME * 2, "конец попытки растолкать")
	while(LAZYFIND(helper.do_afters, victim))
		if(!wait_budget_tick(budget))
			break

/// Сон от захвата клик «Помощи» не укорачивает, а стоящую цель «Помощь» трогает как обычно; свой клик цели проходит; растолкать - 2 секунды, их рвут шаг и удар другого существа по помогающему, но не его собственные раны; еретик цель не расталкивает; у одновременных снов свой источник метки.
/datum/unit_test/heretic_capture_shake/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/pocket_exit_probe/probe = allocate(/datum/eldritch_knowledge/pocket_exit_probe)
	var/turf/spot = get_step(user, EAST)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, spot)
	var/mob/living/carbon/human/helper = allocate(/mob/living/carbon/human, get_step(spot, NORTH))
	var/mob/living/carbon/human/brawler = allocate(/mob/living/carbon/human, get_step(spot, SOUTH))

	heretic_capture_hold(victim, "probe")
	TEST_ASSERT_EQUAL(SEND_SIGNAL(victim, COMSIG_CARBON_PRE_MISC_HELP, victim) & COMPONENT_BLOCK_MISC_HELP, 0, "Свой клик цели проходит.")
	TEST_ASSERT(!LAZYFIND(victim.do_afters, victim), "Цель сама себя не расталкивает.")
	TEST_ASSERT_EQUAL(SEND_SIGNAL(victim, COMSIG_CARBON_PRE_MISC_HELP, helper) & COMPONENT_BLOCK_MISC_HELP, 0, "Стоящей цели «Помощь» ничего не укорачивает и проходит.")
	TEST_ASSERT(LAZYFIND(helper.do_afters, victim), "Клик по стоящей цели всё равно начинает расталкивать.")
	helper.forceMove(get_step(helper, EAST))
	await_shake_end(helper, victim)
	heretic_capture_unhold(victim, "probe")
	helper.forceMove(get_step(spot, NORTH))

	victim.Sleeping(10 SECONDS)
	var/datum/status_effect/heretic_capture_knockout/knockout = heretic_capture_knock_out(victim, probe, "probe", 10 SECONDS)
	var/datum/status_effect/heretic_capture_knockout/twin = heretic_capture_knock_out(victim, probe, "probe", 10 SECONDS)
	TEST_ASSERT(HAS_TRAIT(victim, TRAIT_HERETIC_CAPTURE_HOLD), "Сон захвата держит цель.")
	TEST_ASSERT(probe.knocked_out_by_capture(victim), "Знание узнаёт свой сон.")
	qdel(twin)
	TEST_ASSERT(HAS_TRAIT(victim, TRAIT_HERETIC_CAPTURE_HOLD), "Конец одного сна не снимает метку другого.")

	var/sleep_left = victim.AmountSleeping()
	victim.help_shake_act(helper)
	TEST_ASSERT(victim.AmountSleeping() >= sleep_left - 1, "Клик «Помощи» не укорачивает сон: [victim.AmountSleeping()] из [sleep_left] дс.")
	TEST_ASSERT(LAZYFIND(helper.do_afters, victim), "Клик начинает расталкивать.")
	helper.forceMove(get_step(helper, EAST))
	await_shake_end(helper, victim)
	TEST_ASSERT(victim.IsSleeping() && !QDELETED(knockout), "Шаг помогающего срывает попытку.")
	helper.forceMove(get_step(spot, NORTH))

	INVOKE_ASYNC(src, PROC_REF(shake_async), helper, victim)
	helper.set_last_attacker(brawler)
	helper.apply_damage(5, BRUTE)
	TEST_ASSERT(wait_for_var(src, NAMEOF(src, shake_done), TRUE, HERETIC_CAPTURE_SHAKE_TIME * 2), "Попытка под ударом заканчивается.")
	TEST_ASSERT(!shake_result, "Удар другого существа по помогающему срывает попытку.")
	TEST_ASSERT(victim.IsSleeping() && !QDELETED(knockout), "Сорванная попытка не будит цель.")

	victim.help_shake_act(user)
	TEST_ASSERT(!LAZYFIND(user.do_afters, victim), "Еретик свою цель не расталкивает.")

	shake_done = FALSE
	var/started = world.time
	INVOKE_ASYNC(src, PROC_REF(shake_async), helper, victim)
	helper.apply_damage(5, BRUTE)
	TEST_ASSERT(wait_for_var(src, NAMEOF(src, shake_done), TRUE, HERETIC_CAPTURE_SHAKE_TIME * 2), "Попытка растолкать заканчивается.")
	TEST_ASSERT(shake_result, "Собственные раны помогающего попытку не срывают.")
	TEST_ASSERT(world.time - started >= HERETIC_CAPTURE_SHAKE_TIME - 1, "Растолкать - [HERETIC_CAPTURE_SHAKE_TIME / (1 SECONDS)] с: [world.time - started] дс.")
	TEST_ASSERT(!victim.IsSleeping(), "Растолканная цель просыпается.")
	TEST_ASSERT(QDELETED(knockout), "Сон захвата снят.")
	TEST_ASSERT(!HAS_TRAIT(victim, TRAIT_HERETIC_CAPTURE_HOLD), "Цель больше не держит захват.")

/// Начало обряда снимает сон захвата вместе с меткой удержания.
/datum/unit_test/heretic_capture_knockout_sacrifice/Run()
	var/datum/eldritch_knowledge/pocket_exit_probe/probe = allocate(/datum/eldritch_knowledge/pocket_exit_probe)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	victim.Sleeping(10 SECONDS)
	var/datum/status_effect/heretic_capture_knockout/knockout = heretic_capture_knock_out(victim, probe, "probe", 10 SECONDS)
	TEST_ASSERT(HAS_TRAIT(victim, TRAIT_HERETIC_CAPTURE_HOLD), "Сон захвата держит цель.")
	SEND_SIGNAL(victim, COMSIG_LIVING_HERETIC_SACRIFICE_STARTING)
	TEST_ASSERT(QDELETED(knockout), "Начало обряда снимает сон захвата.")
	TEST_ASSERT(!HAS_TRAIT(victim, TRAIT_HERETIC_CAPTURE_HOLD), "Метка захвата снята вместе с ним.")
