/// Предмет в руке обряду не важен: смена руки и подобранная посторонняя вещь его не срывают, а поднятый компонент срывает.
/datum/unit_test/heretic_ritual_hand_swap/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/turf/center = get_step(run_loc_floor_bottom_left, NORTHEAST)
	user.forceMove(center)
	var/obj/effect/eldritch/rune = allocate(/obj/effect/eldritch/big, center)
	allocate(/obj/item/pen, center)
	var/obj/item/kitchen/knife/spare = allocate(/obj/item/kitchen/knife, center)
	var/datum/eldritch_knowledge/recipe = allocate(/datum/eldritch_knowledge)
	recipe.required_atoms = list(/obj/item/pen)
	recipe.result_atoms = list(/obj/item/stack/sheet/metal)
	recipe.ritual_time = 1 SECONDS
	heretic.researched_knowledge[recipe.type] = recipe
	addtimer(CALLBACK(user, TYPE_PROC_REF(/mob, swap_hand)), 0.3 SECONDS)
	addtimer(CALLBACK(user, TYPE_PROC_REF(/mob, put_in_active_hand), spare), 0.5 SECONDS)
	TEST_ASSERT(rune.do_ritual(user, recipe), "Смена руки и вещь в ней не срывают обряд: [rune.ritual_interrupt_reason]")
	TEST_ASSERT_EQUAL(user.get_active_held_item(), spare, "Подобранный нож остался в руке.")

	allocate(/obj/item/pen, center)
	addtimer(CALLBACK(src, PROC_REF(grab_reserved), user, rune), 0.3 SECONDS)
	TEST_ASSERT(!rune.do_ritual(user, recipe), "Поднятый компонент срывает обряд.")
	TEST_ASSERT(findtext(rune.ritual_interrupt_reason, "Компонент"), "Срыв называет компонент: [rune.ritual_interrupt_reason]")
	for(var/obj/item/stack/sheet/metal/made in center)
		allocated += made

/datum/unit_test/heretic_ritual_hand_swap/proc/grab_reserved(mob/living/user, obj/effect/eldritch/rune)
	for(var/obj/item/pen/ingredient in rune.reserved_atoms)
		user.put_in_hands(ingredient)
		return

/// Предел клинков общий для всех путей: при трёх клинках на себе четвёртый не создаётся, иначе новый рассыпает старейший не при еретике.
/datum/unit_test/heretic_blade_limit_all_paths/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_ash/ash = allocate(/datum/eldritch_knowledge/base_ash)
	heretic.researched_knowledge[ash.type] = ash
	var/turf/forge = get_step(user, EAST)
	var/list/blades = list()
	for(var/index in 1 to HERETIC_BLADE_LIMIT)
		TEST_ASSERT(ash.on_finished_recipe(user, list(), forge), "Клинок Пепла номер [index] создаётся.")
		var/obj/item/melee/sickly_blade/ash/blade = locate() in forge
		TEST_ASSERT_NOTNULL(blade, "Клинок [index] лежит у руны.")
		allocated += blade
		blade.forceMove(user)
		blades += blade
	TEST_ASSERT(!ash.on_finished_recipe(user, list(), forge), "Четвёртый клинок Пепла не создаётся, пока все при еретике.")
	TEST_ASSERT_NULL(locate(/obj/item/melee/sickly_blade/ash) in forge, "Отказ не оставляет лишнего клинка.")
	TEST_ASSERT(findtext(ash.finish_failure_reason, "предел"), "Отказ называет предел: [ash.finish_failure_reason]")
	var/obj/effect/eldritch/rune = allocate(/obj/effect/eldritch/big, get_turf(user))
	var/obj/item/kitchen/knife/knife = allocate(/obj/item/kitchen/knife, get_turf(user))
	allocate(/obj/item/match, get_turf(user))
	TEST_ASSERT(!rune.do_ritual(user, ash), "Руна отклоняет четвёртый клинок Пепла.")
	TEST_ASSERT(!QDELETED(knife), "Отказ не расходует нож.")
	TEST_ASSERT(findtext(rune.recipe_failure_reason(ash, user), "предел связанных"), "Руна объясняет предел клинков.")
	var/obj/item/melee/sickly_blade/ash/dropped = blades[1]
	dropped.forceMove(get_step(user, NORTH))
	TEST_ASSERT(ash.on_finished_recipe(user, list(), forge), "Уроненный клинок не держит место.")
	TEST_ASSERT(QDELETED(dropped), "Новый клинок рассыпает уроненный.")
	for(var/obj/item/melee/sickly_blade/ash/kept as anything in blades.Copy(2))
		TEST_ASSERT(!QDELETED(kept), "Клинки при еретике целы.")
	allocated += locate(/obj/item/melee/sickly_blade/ash) in forge

/// Между побегами клинком проходит не меньше 30 секунд.
/datum/unit_test/heretic_blade_escape_long_cooldown/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/obj/item/melee/sickly_blade/escape_fixture/blade = allocate(/obj/item/melee/sickly_blade/escape_fixture)
	blade.drop_during_search = FALSE
	blade.destination = get_step(user, EAST)
	user.put_in_hands(blade)
	blade.attack_self(user)
	TEST_ASSERT(QDELETED(blade), "Побег расходует клинок.")
	TEST_ASSERT(heretic.owner.heretic_escape_ready_at - world.time >= HERETIC_BLADE_ESCAPE_COOLDOWN - 1, "Следующий побег не раньше чем через 30 секунд: [heretic.owner.heretic_escape_ready_at - world.time] дс.")

/// Явление после вознесения: оглушения не проходят, урон слабее, завеса видна; по окончании и при смерти всё возвращается.
/datum/unit_test/heretic_ascension_emergence/Run()
	var/mob/living/carbon/human/plain = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	plain.apply_status_effect(/datum/status_effect/heretic_emergence)
	TEST_ASSERT(!plain.has_status_effect(/datum/status_effect/heretic_emergence), "Без вознесения явления нет.")
	TEST_ASSERT_EQUAL(plain.physiology.heretic_stamina_mod, 1, "Отказ явления не трогает выносливость.")
	var/list/found = list()
	var/datum/antagonist/heretic/heretic = allocate_ascended_heretic(found)
	var/datum/eldritch_knowledge/final_eldritch/knowledge = found[1]
	var/mob/living/carbon/human/body = heretic.owner.current
	var/original_stamina_mod = body.physiology.heretic_stamina_mod
	knowledge.on_body_gain(body)
	body.Knockdown(50)
	TEST_ASSERT(body.IsKnockdown(), "До явления вознёсшегося можно сбить.")
	var/datum/status_effect/heretic_emergence/emergence = body.apply_status_effect(/datum/status_effect/heretic_emergence)
	TEST_ASSERT_NOTNULL(emergence, "Вознёсшийся входит в явление.")
	TEST_ASSERT(!body.IsKnockdown(), "Явление снимает уже наложенное сбивание.")
	body.Paralyze(100)
	body.Knockdown(100)
	body.Stun(100)
	body.Immobilize(100)
	body.Unconscious(100)
	TEST_ASSERT(!body.IsParalyzed() && !body.IsKnockdown() && !body.IsStun() && !body.IsImmobilized() && !body.IsUnconscious(), "В явлении оглушения не действуют.")
	body.apply_damage(40, BRUTE)
	var/expected = 40 * HERETIC_ASCENDED_DAMAGE_MOD * HERETIC_ASCENDED_EMERGENCE_DAMAGE_MOD
	TEST_ASSERT(abs(body.getBruteLoss() - expected) < 0.01, "Урон в явлении ослаблен: [body.getBruteLoss()] вместо [expected].")
	TEST_ASSERT(abs(body.physiology.heretic_stamina_mod - original_stamina_mod * HERETIC_ASCENDED_STAMINA_MOD * HERETIC_ASCENDED_EMERGENCE_DAMAGE_MOD) < 0.001, "Выносливость в явлении тоже защищена.")
	TEST_ASSERT_NOTNULL(body.get_filter("heretic_emergence"), "Завесу видно контуром.")
	TEST_ASSERT(findtext(emergence.examine_text, "завеса"), "Осмотр объясняет завесу экипажу.")
	qdel(emergence)
	TEST_ASSERT_EQUAL(body.physiology.heretic_ascension_mod, HERETIC_ASCENDED_DAMAGE_MOD, "После явления остаётся обычная защита вознесения.")
	TEST_ASSERT(abs(body.physiology.heretic_stamina_mod - original_stamina_mod * HERETIC_ASCENDED_STAMINA_MOD) < 0.001, "После явления выносливость как у вознёсшегося.")
	TEST_ASSERT_NULL(body.get_filter("heretic_emergence"), "Завеса снята.")
	body.Paralyze(100)
	TEST_ASSERT(body.AmountParalyzed() >= 20 && body.AmountParalyzed() <= 30, "После явления паралич снова лишь укорочен: [body.AmountParalyzed()].")
	body.SetParalyzed(0)

	body.apply_status_effect(/datum/status_effect/heretic_emergence)
	body.death()
	heretic.handle_death(body)
	TEST_ASSERT(!body.has_status_effect(/datum/status_effect/heretic_emergence), "Смерть обрывает явление.")
	TEST_ASSERT_EQUAL(body.physiology.heretic_ascension_mod, 1, "Смерть снимает всю защиту.")
	TEST_ASSERT(abs(body.physiology.heretic_stamina_mod - original_stamina_mod) < 0.001, "Смерть возвращает исходный урон выносливости.")
	TEST_ASSERT_NULL(body.get_filter("heretic_emergence"), "Смерть снимает завесу.")

/// Завершённый обряд вознесения сразу открывает явление.
/datum/unit_test/heretic_ascension_ritual_emergence/Run()
	allocate(/datum/heretic_test_station_level, run_loc_floor_bottom_left.z)
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.ascension_notice_sent = TRUE
	var/mob/living/user = heretic.owner.current
	heretic.selected_path = PATH_BLADE
	heretic.total_sacrifices = HERETIC_ASCENSION_SACRIFICES
	var/obj/effect/eldritch/rune = allocate(/obj/effect/eldritch/big, run_loc_floor_bottom_left)
	var/datum/eldritch_knowledge/final_eldritch/blade_final/final_knowledge = allocate(/datum/eldritch_knowledge/final_eldritch/blade_final)
	final_knowledge.ritual_time = 0
	heretic.researched_knowledge[final_knowledge.type] = final_knowledge
	for(var/body_index in 1 to HERETIC_ASCENSION_BODIES)
		var/mob/living/carbon/human/body = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
		body.last_mind = allocate_mind()
		body.stat = DEAD
	TEST_ASSERT(rune.do_ritual(user, final_knowledge), "Обряд вознесения завершается.")
	TEST_ASSERT(user.has_status_effect(/datum/status_effect/heretic_emergence), "Вознёсшийся сразу входит в явление.")

/// Отказ вознесения объясняет, какие тела годятся, где их взять и сколько подходящих уже у руны.
/datum/unit_test/heretic_ascension_body_hint/Run()
	allocate(/datum/heretic_test_station_level, run_loc_floor_bottom_left.z)
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	heretic.selected_path = PATH_BLADE
	heretic.total_sacrifices = HERETIC_ASCENSION_SACRIFICES
	var/obj/effect/eldritch/rune = allocate(/obj/effect/eldritch/big, run_loc_floor_bottom_left)
	var/datum/eldritch_knowledge/final_eldritch/blade_final/finale = allocate(/datum/eldritch_knowledge/final_eldritch/blade_final)
	heretic.researched_knowledge[finale.type] = finale
	for(var/body_index in 1 to HERETIC_ASCENSION_BODIES - 1)
		var/mob/living/carbon/human/body = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
		body.last_mind = allocate_mind()
		body.stat = DEAD
	var/mob/living/carbon/human/empty = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	empty.stat = DEAD
	var/reason = rune.recipe_failure_reason(finale, user)
	TEST_ASSERT(findtext(reason, "морг"), "Отказ подсказывает искать тела в морге: [reason]")
	TEST_ASSERT(findtext(reason, "управлял игрок"), "Отказ называет, какие тела годятся: [reason]")
	TEST_ASSERT(findtext(reason, "подходящих тел: [HERETIC_ASCENSION_BODIES - 1]"), "Отказ считает подходящие тела у руны: [reason]")
	TEST_ASSERT(findtext(reason, "неподходящих: 1"), "Отказ считает неподходящие тела: [reason]")

/// Клетка, удалившая пришедший эмиттер частиц, не ломает его отпускание.
/datum/unit_test/heretic_vfx_release_eaten/Run()
	var/mob/living/carbon/human/host = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/obj/effect/abstract/heretic_particle_holder/holder = heretic_vfx_attach_particles(host, /particles/heretic_ascension/rust/dust, FALSE)
	TEST_ASSERT_NOTNULL(holder, "Эмиттер прикреплён.")
	RegisterSignal(run_loc_floor_bottom_left, COMSIG_ATOM_ENTERED, PROC_REF(eat_holder))
	heretic_vfx_release_particles(host, holder)
	UnregisterSignal(run_loc_floor_bottom_left, COMSIG_ATOM_ENTERED)
	TEST_ASSERT(QDELETED(holder), "Съеденный на входе эмиттер удалён.")

/datum/unit_test/heretic_vfx_release_eaten/proc/eat_holder(datum/source, atom/movable/arrived)
	SIGNAL_HANDLER
	if(istype(arrived, /obj/effect/abstract/heretic_particle_holder))
		qdel(arrived)

/// Список клинков ленивый: рассыпанный последний клинок обнуляет его, и знание Клинка удаляется без рантайма.
/datum/unit_test/heretic_blade_list_lazy/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_blade/knowledge = new
	TEST_ASSERT_NULL(knowledge.created_blades, "Пустой список клинков - null.")
	var/obj/item/melee/sickly_blade/duelist/blade = allocate(/obj/item/melee/sickly_blade/duelist, get_step(user, NORTH))
	knowledge.track_blade(blade, user)
	TEST_ASSERT_EQUAL(LAZYLEN(knowledge.created_blades), 1, "Клинок записан.")
	knowledge.crumble_blade(blade)
	TEST_ASSERT_NULL(knowledge.created_blades, "Рассыпанный последний клинок обнуляет список.")
	qdel(knowledge)
	TEST_ASSERT(QDELETED(knowledge), "Знание Клинка удаляется с пустым списком.")

/// Предел клинков проверяется весь обряд: поднятый уроненный клинок срывает начатый обряд сразу, а не в конце.
/datum/unit_test/heretic_ritual_blade_limit_recheck/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_ash/ash = allocate(/datum/eldritch_knowledge/base_ash)
	heretic.researched_knowledge[ash.type] = ash
	var/turf/forge = get_step(user, EAST)
	var/list/blades = list()
	for(var/index in 1 to HERETIC_BLADE_LIMIT)
		TEST_ASSERT(ash.on_finished_recipe(user, list(), forge), "Клинок Пепла номер [index] создаётся.")
		var/obj/item/melee/sickly_blade/ash/blade = locate() in forge
		allocated += blade
		blade.forceMove(user)
		blades += blade
	var/obj/item/melee/sickly_blade/ash/dropped = blades[1]
	dropped.forceMove(get_step(get_step(user, NORTH), NORTH))
	var/obj/effect/eldritch/rune = allocate(/obj/effect/eldritch/big, get_turf(user))
	allocate(/obj/item/kitchen/knife, get_turf(user))
	allocate(/obj/item/match, get_turf(user))
	ash.ritual_time = 3 SECONDS
	addtimer(CALLBACK(dropped, TYPE_PROC_REF(/atom/movable, forceMove), user), 0.5 SECONDS)
	var/started = world.time
	TEST_ASSERT(!rune.do_ritual(user, ash), "Обряд, ради которого пришлось бы рассыпать клинок при себе, не завершается.")
	TEST_ASSERT(findtext(rune.ritual_interrupt_reason, "предел"), "Срыв называет предел клинков: [rune.ritual_interrupt_reason]")
	TEST_ASSERT(world.time - started < ash.ritual_time, "Обряд срывается сразу, а не в конце: [world.time - started] дс.")

/// Библия стирает круг с идущим обрядом за HERETIC_RUNE_BIBLE_ERASE_TIME, а пустой круг - сразу; нулевой жезл стирает сразу всегда.
/datum/unit_test/heretic_rune_bible_erase/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/turf/center = get_step(run_loc_floor_bottom_left, NORTHEAST)
	user.forceMove(center)
	var/mob/living/carbon/human/crew = allocate(/mob/living/carbon/human, get_step(center, EAST))
	var/obj/item/storage/book/bible/bible = allocate(/obj/item/storage/book/bible, crew)
	var/obj/item/nullrod/rod = allocate(/obj/item/nullrod, crew)
	crew.put_in_hands(bible)
	allocate(/obj/item/pen, center)
	var/datum/eldritch_knowledge/recipe = allocate(/datum/eldritch_knowledge)
	recipe.required_atoms = list(/obj/item/pen)
	recipe.result_atoms = list(/obj/item/stack/sheet/metal)
	recipe.ritual_time = 10 SECONDS
	heretic.researched_knowledge[recipe.type] = recipe

	var/obj/effect/eldritch/rune = allocate(/obj/effect/eldritch/big, center)
	INVOKE_ASYNC(rune, TYPE_PROC_REF(/obj/effect/eldritch, do_ritual), user, recipe)
	TEST_ASSERT(rune.ritual_user == user, "Обряд идёт.")
	var/started = world.time
	bible.melee_attack_chain(crew, rune)
	TEST_ASSERT(QDELETED(rune), "Библия стирает круг с идущим обрядом.")
	TEST_ASSERT(world.time - started >= HERETIC_RUNE_BIBLE_ERASE_TIME - 1, "Круг с обрядом Библия стирает не сразу: [world.time - started] дс.")

	var/obj/effect/eldritch/idle = allocate(/obj/effect/eldritch/big, center)
	started = world.time
	bible.melee_attack_chain(crew, idle)
	TEST_ASSERT(QDELETED(idle) && world.time == started, "Пустой круг Библия стирает сразу.")

	crew.dropItemToGround(bible)
	crew.put_in_hands(rod)
	var/obj/effect/eldritch/busy = allocate(/obj/effect/eldritch/big, center)
	INVOKE_ASYNC(busy, TYPE_PROC_REF(/obj/effect/eldritch, do_ritual), user, recipe)
	TEST_ASSERT(busy.ritual_user == user, "Второй обряд идёт.")
	started = world.time
	rod.melee_attack_chain(crew, busy)
	TEST_ASSERT(QDELETED(busy) && world.time == started, "Нулевой жезл стирает круг с обрядом сразу.")

/// Тексты осмотра для чужих глаз ставят SUBJECTPRONOUN только в именительный падеж: его заменяет «Он» или «Она».
/datum/unit_test/heretic_examine_pronouns/Run()
	var/regex/oblique = regex("(^|\\s|>)(На|на|Над|над|Вокруг|вокруг|У|у|От|от|К|к|С|с|Со|со|При|при|Под|под|По|по|За|за|Для|для|Перед|перед|горла|Ноги|ноги|оглушить|несут)\\s+SUBJECTPRONOUN")
	for(var/datum/status_effect/effect_type as anything in subtypesof(/datum/status_effect))
		var/text = initial(effect_type.examine_text)
		if(!text)
			continue
		TEST_ASSERT(!findtext(text, "SUBJECTOBJECT"), "SUBJECTOBJECT ничем не заменяется: [effect_type]")
		TEST_ASSERT(!oblique.Find(text), "SUBJECTPRONOUN в косвенном падеже: [effect_type]: [text]")

/// До вознесения оглушение глушит приём; вознёсшегося не глушит, но держат наручники, сон и стазис.
/datum/unit_test/heretic_ascended_ignores_stun/proc/check_stun(datum/antagonist/heretic/heretic, mob/living/carbon/human/user, datum/callback/ready, label)
	TEST_ASSERT(ready.Invoke(), "[label]: без оглушения приём доступен.")
	user.Paralyze(10 SECONDS)
	TEST_ASSERT(!ready.Invoke(), "[label]: до вознесения оглушение глушит приём.")
	heretic.ascended = TRUE
	TEST_ASSERT(ready.Invoke(), "[label]: вознёсшегося оглушение не глушит.")
	user.SetParalyzed(0)
	user.handcuffed = allocate(/obj/item/restraints/handcuffs, user)
	user.update_handcuffed()
	TEST_ASSERT(!ready.Invoke(), "[label]: вознёсшегося держат наручники.")
	user.uncuff()
	user.SetSleeping(10 SECONDS)
	TEST_ASSERT(!ready.Invoke(), "[label]: вознёсшегося держит сон.")
	user.SetSleeping(0)
	user.apply_status_effect(/datum/status_effect/grouped/stasis, TRAIT_SOURCE_UNIT_TESTS)
	TEST_ASSERT(!ready.Invoke(), "[label]: вознёсшегося держит стазис.")
	user.remove_status_effect(/datum/status_effect/grouped/stasis, TRAIT_SOURCE_UNIT_TESTS)
	TEST_ASSERT(ready.Invoke(), "[label]: снятые путы возвращают приём.")
	heretic.ascended = FALSE

/// Оглушение посреди обряда сердцем срывает его до вознесения, но не у вознёсшегося; наручники держат обоих.
/datum/unit_test/heretic_hunt_claim/stunned_heart_rite/Run()
	test_level = SSmapping.get_level(run_loc_floor_bottom_left.z)
	previous_traits = test_level.traits
	test_level.traits = previous_traits.Copy()
	test_level.traits[ZTRAIT_STATION] = TRUE
	var/list/previous_sacrificed = GLOB.heretic_sacrificed_minds.Copy()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/datum/mind/user_mind = allocate_mind()
	user_mind.current = user
	user.mind = user_mind
	var/datum/antagonist/heretic/ritual_fixture/heretic = allocate(/datum/antagonist/heretic/ritual_fixture)
	heretic.owner = user_mind
	heretic.silent = TRUE
	user_mind.antag_datums = list(heretic)
	heretic.test_return_turf = run_loc_floor_top_right
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/basic)
	var/obj/item/living_heart/heart = allocate(/obj/item/living_heart, run_loc_floor_bottom_left)
	TEST_ASSERT(heart.bind(user_mind), "Сердце привязано к еретику.")
	var/mob/living/carbon/human/victim = allocate_victim(get_step(run_loc_floor_bottom_left, EAST))
	victim.handcuffed = allocate(/obj/item/restraints/handcuffs, victim)
	victim.update_handcuffed()
	heretic.set_hunt_target(victim.mind)

	TEST_ASSERT(!rite_under(heretic, user, victim, heart, FALSE), "До вознесения оглушение срывает обряд сердцем.")
	TEST_ASSERT(!rite_under(heretic, user, victim, heart, TRUE), "До вознесения наручники срывают обряд сердцем.")
	heretic.ascended = TRUE
	user.Paralyze(5 SECONDS)
	user.handcuffed = allocate(/obj/item/restraints/handcuffs, user)
	user.update_handcuffed()
	TEST_ASSERT(findtext(heretic_incapacitated_reason(user), "связали"), "Вознёсшемуся отказ называет наручники, а не оглушение.")
	user.uncuff()
	user.SetParalyzed(0)
	TEST_ASSERT(!rite_under(heretic, user, victim, heart, TRUE), "Вознёсшегося наручники держат.")
	TEST_ASSERT_EQUAL(heretic.total_sacrifices, 0, "Сорванные обряды не засчитаны.")
	TEST_ASSERT(rite_under(heretic, user, victim, heart, FALSE), "Вознёсшийся доводит обряд сердцем под оглушением.")
	TEST_ASSERT_EQUAL(heretic.total_sacrifices, 1, "Обряд под оглушением засчитан.")
	var/datum/heretic_mansus_visit/visit = GLOB.heretic_mansus_visits[victim.mind]
	if(visit)
		allocated += visit
		visit.finish()
	GLOB.heretic_sacrificed_minds = previous_sacrificed

/// Начинает обряд сердцем и тут же оглушает или сковывает исполнителя; TRUE, если жертва засчитана.
/datum/unit_test/heretic_hunt_claim/stunned_heart_rite/proc/rite_under(datum/antagonist/heretic/heretic, mob/living/carbon/human/user, mob/living/carbon/human/victim, obj/item/living_heart/heart, cuffs)
	user.put_in_hands(heart)
	var/sacrifices = heretic.total_sacrifices
	INVOKE_ASYNC(heretic, TYPE_PROC_REF(/datum/antagonist/heretic, begin_heart_rite), user, victim, heart)
	var/obj/effect/eldritch/big/heart_rite/circle = locate() in get_turf(victim)
	TEST_ASSERT_NOTNULL(circle, "Под целью проступил круг.")
	if(cuffs)
		user.handcuffed = allocate(/obj/item/restraints/handcuffs, user)
		user.update_handcuffed()
	else
		user.Paralyze(heretic.heart_rite_time(victim) + 5 SECONDS)
	wait_for_qdeleted(circle, heretic.heart_rite_time(victim) + 3 SECONDS)
	. = heretic.total_sacrifices > sacrifices
	var/heart_kept = heart.loc == user || heart.loc == get_turf(user)
	if(cuffs)
		user.uncuff()
	user.SetParalyzed(0)
	TEST_ASSERT(heart_kept, "[cuffs ? "Связанному" : "Оглушённому"] еретику сердце ложится в руку или под ноги, а не остаётся под целью: [heart.loc].")

/// Эффект, который не смог лечь, не возвращается вызывающему.
/datum/unit_test/heretic_status_effect_failed_apply/Run()
	var/mob/living/carbon/human/dummy = allocate(/mob/living/carbon/human)
	TEST_ASSERT_NULL(dummy.apply_status_effect(/datum/status_effect/heretic_emergence), "Явление без вознесения не ложится и не возвращается.")
	TEST_ASSERT_NULL(dummy.has_status_effect(/datum/status_effect/heretic_emergence), "На теле нет явления.")
	TEST_ASSERT_NOTNULL(dummy.apply_status_effect(/datum/status_effect/robotic_emp), "Единственный эффект ложится.")
	var/datum/status_effect/repeated_unique = dummy.apply_status_effect(/datum/status_effect/robotic_emp)
	TEST_ASSERT(isnull(repeated_unique) && QDELETED(repeated_unique), "Повтор единственного эффекта возвращает null, а не 0.")
	TEST_ASSERT_NOTNULL(dummy.apply_status_effect(/datum/status_effect/duskndawn), "Обновляемый эффект ложится.")
	TEST_ASSERT_NULL(dummy.apply_status_effect(/datum/status_effect/duskndawn), "Повтор обновляемого эффекта возвращает null.")
