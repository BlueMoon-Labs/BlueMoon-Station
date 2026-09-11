/// Повторный обряд нельзя завершить, пока оповещение о его начале находится на задержке.
/datum/unit_test/heretic_ascension_warning_gate/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.ascension_notice_sent = TRUE
	var/mob/living/user = heretic.owner.current
	heretic.selected_path = PATH_BLADE
	heretic.total_sacrifices = HERETIC_ASCENSION_SACRIFICES
	var/obj/effect/eldritch/rune = allocate(/obj/effect/eldritch/big, run_loc_floor_bottom_left)
	var/datum/eldritch_knowledge/final_eldritch/blade_final/final_knowledge = allocate(/datum/eldritch_knowledge/final_eldritch/blade_final)
	final_knowledge.ritual_time = 0
	heretic.researched_knowledge[final_knowledge.type] = final_knowledge
	var/list/bodies = list()
	for(var/body_index in 1 to HERETIC_ASCENSION_BODIES)
		var/mob/living/carbon/human/body = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
		body.stat = DEAD
		bodies += body
	COOLDOWN_START(final_knowledge, ascension_warning, 3 MINUTES)
	TEST_ASSERT(!rune.do_ritual(user, final_knowledge), "Руна не должна позволять вознестись без нового объявления о начале.")
	TEST_ASSERT(!heretic.ascended && !final_knowledge.finished, "Отказ начала не завершает вознесение.")
	for(var/mob/living/carbon/human/body as anything in bodies)
		TEST_ASSERT(!QDELETED(body), "Отказ начала сохраняет каждое тело.")
		TEST_ASSERT_NULL(GLOB.heretic_ritual_reservations[body], "Отказ начала освобождает резервирование тел.")
	TEST_ASSERT_NULL(rune.ritual_user, "Отказ начала освобождает руну для следующей попытки.")
	TEST_ASSERT_EQUAL(length(rune.ascension_body_images), 0, "Отклонённая попытка не оставляет подсветку тел.")
	COOLDOWN_RESET(final_knowledge, ascension_warning)
	TEST_ASSERT(rune.do_ritual(user, final_knowledge), "Та же руна с теми же телами завершает обряд после снятия задержки.")
	TEST_ASSERT(heretic.ascended && final_knowledge.finished, "Разрешённый обряд действительно возносит еретика.")
	for(var/mob/living/carbon/human/body as anything in bodies)
		TEST_ASSERT(QDELETED(body), "Успешное вознесение расходует каждое выбранное тело.")

/// Общее предупреждение не дублируется и оставляет станции время до финального обряда.
/datum/unit_test/heretic_ascension_advance_warning
	var/previous_warning_until

/datum/unit_test/heretic_ascension_advance_warning/Destroy()
	GLOB.heretic_threat_warning_until = previous_warning_until
	return ..()

/datum/unit_test/heretic_ascension_advance_warning/Run()
	previous_warning_until = GLOB.heretic_threat_warning_until
	GLOB.heretic_threat_warning_until = 0
	var/datum/antagonist/heretic/first = allocate_heretic()
	var/datum/antagonist/heretic/second = allocate_heretic()
	var/before_warning = world.time
	TEST_ASSERT(first.announce_threat(), "Первая угроза объявляется станции.")
	TEST_ASSERT(first.ascension_ready_at >= before_warning + HERETIC_THREAT_WARNING_TIME, "До финала остаётся не менее трёх минут.")
	TEST_ASSERT(!second.announce_threat(), "Вторая одновременная угроза не повторяет объявление.")
	TEST_ASSERT_EQUAL(second.ascension_ready_at, first.ascension_ready_at, "Оба еретика учитывают общее время предупреждения.")
	var/obj/effect/eldritch/rune = allocate(/obj/effect/eldritch/big)
	var/datum/eldritch_knowledge/final_eldritch/blade_final/knowledge = allocate(/datum/eldritch_knowledge/final_eldritch/blade_final)
	TEST_ASSERT(!knowledge.begin_ascension_ritual(first.owner.current, rune), "Быстрая покупка финала не обходит предупреждение.")
	first.ascension_ready_at = world.time
	TEST_ASSERT(knowledge.begin_ascension_ritual(first.owner.current, rune), "После предупреждения настоящий обряд может начаться.")

/// Гиб уже мёртвого тела освобождает эффекты вознесения без повторного сигнала смерти.
/datum/unit_test/heretic_ascension_gib_cleanup/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/carbon/human/body = heretic.owner.current
	heretic.apply_innate_effects(body)
	var/datum/eldritch_knowledge/final_eldritch/blade_final/knowledge = allocate(/datum/eldritch_knowledge/final_eldritch/blade_final)
	heretic.researched_knowledge[knowledge.type] = knowledge
	knowledge.finished = TRUE
	knowledge.on_body_gain(body)
	var/obj/effect/heretic_ascension_aura/aura = knowledge.ascension_aura
	TEST_ASSERT_EQUAL(knowledge.applied_body, body, "Эффекты привязаны к живому телу.")
	TEST_ASSERT(!(aura in body.contents), "Нимб показывается через vis_contents и не занимает инвентарь.")
	body.stat = DEAD
	body.gib()
	TEST_ASSERT_NULL(knowledge.applied_body, "Удаление трупа освобождает ссылку на тело.")
	TEST_ASSERT_NOTEQUAL(heretic.innate_body, body, "Роль не удерживает уничтоженное тело после переноса в мозг.")
	TEST_ASSERT(QDELETED(aura), "Нимб удалён вместе с телом.")
	TEST_ASSERT_NOTNULL(heretic.owner.current, "После обычного гиба сохраняется мозг с разумом.")
	qdel(heretic.owner.current)
	TEST_ASSERT_NULL(heretic.innate_body, "Удаление оставшегося мозга освобождает последнее тело роли.")

/// Любой срыв объявляется станции и не сбрасывает задержку следующего старта.
/datum/unit_test/heretic_ascension_warning_timing/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.ascension_notice_sent = TRUE
	var/mob/living/user = heretic.owner.current
	var/obj/effect/eldritch/rune = allocate(/obj/effect/eldritch/big, run_loc_floor_bottom_left)
	var/datum/eldritch_knowledge/final_eldritch/blade_final/final_knowledge = allocate(/datum/eldritch_knowledge/final_eldritch/blade_final)
	var/begin_before = world.time
	TEST_ASSERT(final_knowledge.begin_ascension_ritual(user, rune), "Первая допустимая попытка объявляется.")
	var/begin_after = world.time
	TEST_ASSERT(final_knowledge.ascension_warning >= begin_before + 3 MINUTES && final_knowledge.ascension_warning <= begin_after + 3 MINUTES, "Начало финала закрывает повторные попытки на три минуты.")
	var/next_attempt_at = final_knowledge.ascension_warning
	TEST_ASSERT(!final_knowledge.begin_ascension_ritual(user, rune), "Повторный старт блокируется вместе с повторным объявлением.")
	TEST_ASSERT(final_knowledge.abort_ascension_ritual(get_area(rune), 0), "Даже немедленный срыв закрывает объявленную тревогу.")
	TEST_ASSERT(final_knowledge.abort_ascension_ritual(get_area(rune), 15 SECONDS), "Срыв после половины обряда объявляется станции.")
	TEST_ASSERT_EQUAL(final_knowledge.ascension_warning, next_attempt_at, "Срыв не отменяет задержку следующего старта.")
	final_knowledge.finished = TRUE
	TEST_ASSERT(!final_knowledge.abort_ascension_ritual(get_area(rune), 30 SECONDS), "Запоздалый срыв не опровергает завершённое вознесение.")

/// В списке есть лишний труп и тело союзника: ни одно из них не должно попасть в личную подсветку.
/datum/unit_test/proc/make_ascension_preview_fixture()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	heretic.selected_path = PATH_BLADE
	heretic.total_sacrifices = HERETIC_ASCENSION_SACRIFICES
	var/datum/antagonist/heretic/friendly_heretic = allocate_heretic()
	var/mob/living/friendly_body = friendly_heretic.owner.current
	friendly_body.death()
	var/list/atoms = list(friendly_body)
	var/list/expected = list()
	for(var/body_index in 1 to HERETIC_ASCENSION_BODIES)
		var/mob/living/carbon/human/body = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
		body.death()
		atoms += body
		expected += body
	var/mob/living/carbon/human/extra_body = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	extra_body.death()
	atoms += extra_body
	var/obj/effect/eldritch/rune = allocate(/obj/effect/eldritch/big, run_loc_floor_bottom_left)
	var/datum/eldritch_knowledge/final_eldritch/blade_final/final_knowledge = allocate(/datum/eldritch_knowledge/final_eldritch/blade_final)
	heretic.researched_knowledge[final_knowledge.type] = final_knowledge
	var/list/selected = list()
	if(!rune.select_recipe_atoms(final_knowledge, atoms, selected, list(), user) || !rune.reserve_atoms(selected))
		return null
	rune.ritual_user = user
	return list("heretic" = heretic, "user" = user, "rune" = rune, "knowledge" = final_knowledge, "expected" = expected, "all_bodies" = atoms)

/datum/unit_test/heretic_ascension_preview_selection/Run()
	var/list/fixture = make_ascension_preview_fixture()
	TEST_ASSERT_NOTNULL(fixture, "Тела для проверки подсветки должны резервироваться.")
	var/mob/living/user = fixture["user"]
	var/obj/effect/eldritch/rune = fixture["rune"]
	var/list/expected = fixture["expected"]
	var/list/old_filters = list()
	for(var/mob/living/body as anything in fixture["all_bodies"])
		old_filters[body] = length(body.filters)
	TEST_ASSERT(rune.show_ascension_body_preview(user), "Зарезервированная тройка получает личную подсветку.")
	TEST_ASSERT_EQUAL(length(rune.ascension_body_images), HERETIC_ASCENSION_BODIES, "Создаются ровно три image.")
	var/list/highlighted_bodies = list()
	var/list/images = rune.ascension_body_images.Copy()
	for(var/image/body_image as anything in images)
		TEST_ASSERT(body_image.loc in expected, "Каждая подсветка привязана к выбранному допустимому телу.")
		highlighted_bodies |= body_image.loc
		TEST_ASSERT(length(body_image.filters), "Зелёный контур находится на личном image.")
	TEST_ASSERT_EQUAL(length(highlighted_bodies), HERETIC_ASCENSION_BODIES, "Все три выбранных тела подсвечены по одному разу.")
	for(var/mob/living/body as anything in old_filters)
		TEST_ASSERT_EQUAL(length(body.filters), old_filters[body], "Подсветка не меняет глобальные фильтры тела.")
	rune.release_atoms()
	TEST_ASSERT_EQUAL(length(rune.ascension_body_images), 0, "Завершение или отмена убирают подсветку вместе с резервированием.")
	TEST_ASSERT_NULL(rune.ascension_preview_mind, "Освобождение руны убирает слежение за разумом.")
	for(var/image/body_image as anything in images)
		TEST_ASSERT(QDELETED(body_image), "Освобождение руны удаляет каждый личный image.")

/// Сигналы прерывания очищают подсветку сразу, не дожидаясь следующей проверки do_after.
/datum/unit_test/heretic_ascension_preview_interruptions/Run()
	for(var/interruption in list("movement", "body deletion", "rune deletion", "logout"))
		var/list/fixture = make_ascension_preview_fixture()
		TEST_ASSERT_NOTNULL(fixture, "Тела для проверки прерывания должны резервироваться.")
		var/mob/living/user = fixture["user"]
		var/obj/effect/eldritch/rune = fixture["rune"]
		var/list/expected = fixture["expected"]
		var/mob/living/body = expected[1]
		TEST_ASSERT(rune.show_ascension_body_preview(user), "Подсветка должна появиться до прерывания.")
		var/list/images = rune.ascension_body_images.Copy()
		switch(interruption)
			if("movement")
				body.forceMove(run_loc_floor_top_right)
			if("body deletion")
				qdel(body)
			if("rune deletion")
				qdel(rune)
			if("logout")
				SEND_SIGNAL(user, COMSIG_MOB_CLIENT_LOGOUT, null)
		for(var/image/body_image as anything in images)
			TEST_ASSERT(QDELETED(body_image), "[interruption]: прерывание удаляет каждый личный image.")
		if(!QDELETED(rune))
			TEST_ASSERT(rune.ritual_interrupted, "[interruption]: прерывание запрещает завершать обряд.")
			TEST_ASSERT_EQUAL(length(rune.ascension_body_images), 0, "[interruption]: руна не удерживает подсветку.")
			TEST_ASSERT_NULL(rune.ascension_preview_mind, "[interruption]: слежение за разумом прекращается.")

/datum/unit_test/heretic_ascension_preview_transfer/Run()
	var/list/fixture = make_ascension_preview_fixture()
	TEST_ASSERT_NOTNULL(fixture, "Тела для проверки переноса должны резервироваться.")
	var/datum/antagonist/heretic/heretic = fixture["heretic"]
	var/mob/living/old_body = fixture["user"]
	var/obj/effect/eldritch/rune = fixture["rune"]
	var/datum/eldritch_knowledge/final_eldritch/final_knowledge = fixture["knowledge"]
	TEST_ASSERT(rune.show_ascension_body_preview(old_body), "Подсветка должна появиться до переноса разума.")
	var/list/images = rune.ascension_body_images.Copy()
	COOLDOWN_START(final_knowledge, ascension_warning, 3 MINUTES)
	var/next_attempt_at = final_knowledge.ascension_warning
	var/mob/living/carbon/human/new_body = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	heretic.owner.transfer_to(new_body)
	TEST_ASSERT(rune.ritual_interrupted, "Смена тела прерывает начатый обряд.")
	TEST_ASSERT_EQUAL(length(rune.ascension_body_images), 0, "Личная подсветка не переезжает в новое тело.")
	TEST_ASSERT_EQUAL(final_knowledge.ascension_warning, next_attempt_at, "Смена тела не сбрасывает задержку следующего вознесения.")
	for(var/image/body_image as anything in images)
		TEST_ASSERT(QDELETED(body_image), "Перенос разума удаляет каждый личный image.")

/// Нимб и титул принадлежат текущему телу; повторная выдача не дублирует их.
/datum/unit_test/heretic_ascension_presence_transfer/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/old_body = heretic.owner.current
	var/datum/eldritch_knowledge/final_eldritch/blade_final/final_knowledge = allocate(/datum/eldritch_knowledge/final_eldritch/blade_final)
	final_knowledge.finished = TRUE
	final_knowledge.on_body_gain(old_body)
	var/obj/effect/heretic_ascension_aura/old_aura = final_knowledge.ascension_aura
	TEST_ASSERT_NOTNULL(old_aura, "Вознесённое тело получает нимб.")
	TEST_ASSERT(old_aura in old_body.vis_contents, "Нимб следует за телом через vis_contents.")
	final_knowledge.on_body_gain(old_body)
	TEST_ASSERT_EQUAL(final_knowledge.ascension_aura, old_aura, "Повторная выдача не создаёт второй нимб.")
	var/list/examine_lines = list()
	SEND_SIGNAL(old_body, COMSIG_PARENT_EXAMINE, old_body, examine_lines)
	TEST_ASSERT_EQUAL(length(examine_lines), 1, "Осмотр показывает один титул вознесения.")
	var/datum/antagonist/heretic/replacement = allocate_heretic(run_loc_floor_top_right)
	var/mob/living/new_body = replacement.owner.current
	final_knowledge.on_body_gain(new_body)
	TEST_ASSERT(QDELETED(old_aura), "Перенос удаляет старый нимб.")
	TEST_ASSERT(!(old_aura in old_body.vis_contents), "Старое тело освобождает визуальный объект.")
	examine_lines.Cut()
	SEND_SIGNAL(old_body, COMSIG_PARENT_EXAMINE, new_body, examine_lines)
	TEST_ASSERT_EQUAL(length(examine_lines), 0, "Старое тело больше не показывает титул.")
	SEND_SIGNAL(new_body, COMSIG_PARENT_EXAMINE, old_body, examine_lines)
	TEST_ASSERT_EQUAL(length(examine_lines), 1, "Новое тело наследует титул.")
	var/obj/effect/heretic_ascension_aura/new_aura = final_knowledge.ascension_aura
	final_knowledge.on_body_lose(new_body)
	TEST_ASSERT(QDELETED(new_aura), "Снятие знания удаляет новый нимб.")
	examine_lines.Cut()
	SEND_SIGNAL(new_body, COMSIG_PARENT_EXAMINE, old_body, examine_lines)
	TEST_ASSERT_EQUAL(length(examine_lines), 0, "После снятия знания титул не остаётся.")

/// Смерть снимает вознесение с тела, а оживление возвращает его ровно один раз.
/datum/unit_test/heretic_ascension_death_recovery/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_BLADE
	var/mob/living/carbon/human/body = heretic.owner.current
	var/original_brute_mod = body.physiology.brute_mod
	var/datum/eldritch_knowledge/final_eldritch/blade_final/knowledge = allocate(/datum/eldritch_knowledge/final_eldritch/blade_final)
	heretic.researched_knowledge[knowledge.type] = knowledge
	knowledge.finished = TRUE
	knowledge.on_body_gain(body)
	var/obj/effect/heretic_ascension_aura/aura = knowledge.ascension_aura
	TEST_ASSERT(body.physiology.brute_mod < original_brute_mod, "Живое тело получает защиту вознесения.")
	body.death()
	heretic.handle_death(body)
	TEST_ASSERT_NULL(knowledge.applied_body, "Смерть освобождает ссылку знания на тело.")
	TEST_ASSERT(QDELETED(aura), "Смерть удаляет нимб.")
	TEST_ASSERT_EQUAL(body.physiology.brute_mod, original_brute_mod, "Смерть снимает множитель защиты.")
	body.revive(full_heal = TRUE)
	knowledge.on_life(body)
	knowledge.on_life(body)
	TEST_ASSERT_EQUAL(knowledge.applied_body, body, "Оживлённое тело снова получает эффект.")
	TEST_ASSERT_EQUAL(body.physiology.brute_mod, original_brute_mod * knowledge.damage_modifier, "Повторная обработка жизни не умножает защиту ещё раз.")

/// Истечение знамения очищает только его собственный слой, в том числе без клиента.
/datum/unit_test/heretic_ascension_omen_cleanup/Run()
	var/mob/living/carbon/human/witness = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/atom/movable/screen/fullscreen/other_overlay = witness.overlay_fullscreen("independent_omen_test", /atom/movable/screen/fullscreen/heretic_omen)
	var/datum/status_effect/heretic_ascension_omen/omen = witness.apply_status_effect(/datum/status_effect/heretic_ascension_omen, PATH_MOON)
	TEST_ASSERT_NOTNULL(omen, "Знамение выдаётся живому свидетелю.")
	var/overlay_key = omen.fullscreen_key
	TEST_ASSERT(witness.fullscreens[overlay_key], "Знамение создаёт отдельный слой экрана.")
	TEST_ASSERT(!witness.apply_status_effect(/datum/status_effect/heretic_ascension_omen, PATH_COSMIC), "Второе событие не складывает полноэкранные эффекты.")
	TEST_ASSERT_EQUAL(omen.path_id, PATH_MOON, "Второе событие не меняет уже начатое знамение.")
	omen.duration = world.time - 1
	omen.process()
	TEST_ASSERT(QDELETED(omen), "Знамение само удаляется по истечении срока.")
	TEST_ASSERT_NULL(witness.fullscreens[overlay_key], "Истёкшее знамение не оставляет своего слоя.")
	TEST_ASSERT_EQUAL(witness.fullscreens["independent_omen_test"], other_overlay, "Независимый слой остаётся нетронутым.")
	witness.clear_fullscreen("independent_omen_test", 0)

/// Оповещение доступно машине, но телесное знамение и его полноэкранный слой — нет.
/datum/unit_test/heretic_ascension_omen_carbon_only/Run()
	var/mob/living/silicon/robot/borg = allocate(/mob/living/silicon/robot, run_loc_floor_bottom_left)
	var/list/previous_fullscreens = borg.fullscreens.Copy()
	var/datum/status_effect/heretic_ascension_omen/rejected = borg.apply_status_effect(/datum/status_effect/heretic_ascension_omen, PATH_FLESH)
	TEST_ASSERT(QDELETED(rejected), "Киборг не должен получать знамение даже при прямом вызове статуса.")
	TEST_ASSERT(!borg.has_status_effect(/datum/status_effect/heretic_ascension_omen), "Машина не остаётся среди владельцев знамения.")
	TEST_ASSERT_EQUAL(length(borg.fullscreens), length(previous_fullscreens), "Отклонённое знамение не создаёт машинного полноэкранного слоя.")

/// Последний такт отталкивает только подходящие цели и оставляет ограниченный зимний круг.
/datum/unit_test/heretic_last_waltz_targets/Run()
	var/turf/center = locate(run_loc_floor_bottom_left.x + 2, run_loc_floor_bottom_left.y + 3, run_loc_floor_bottom_left.z)
	var/datum/antagonist/heretic/heretic = allocate_heretic(center)
	var/mob/living/user = heretic.owner.current
	heretic.selected_path = PATH_VOID
	heretic.ascended = TRUE
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, get_step(center, EAST))
	var/turf/victim_start = get_turf(victim)
	var/turf/victim_destination = get_step(get_step(victim_start, EAST), EAST)
	var/mob/living/carbon/human/protected = allocate(/mob/living/carbon/human, get_step(center, NORTH))
	ADD_TRAIT(protected, TRAIT_ANTIMAGIC, "last_waltz_test")
	var/turf/protected_start = get_turf(protected)
	var/protected_temperature = protected.bodytemperature
	var/datum/antagonist/heretic/ally_heretic = allocate_heretic(get_step(center, SOUTH))
	var/mob/living/ally = ally_heretic.owner.current
	var/turf/ally_start = get_turf(ally)
	var/obj/effect/proc_holder/spell/self/heretic_last_waltz/spell = allocate(/obj/effect/proc_holder/spell/self/heretic_last_waltz)
	spell.cast(list(), user)
	TEST_ASSERT_EQUAL(get_turf(victim), victim_destination, "Противник отступает ровно на две свободные клетки.")
	TEST_ASSERT(victim.has_status_effect(/datum/status_effect/eldritch/void), "Противник получает метку Пустоты.")
	TEST_ASSERT_EQUAL(get_turf(protected), protected_start, "Антимагия защищает от перемещения.")
	TEST_ASSERT_EQUAL(protected.bodytemperature, protected_temperature, "Антимагия защищает от охлаждения.")
	TEST_ASSERT(!protected.has_status_effect(/datum/status_effect/eldritch/void), "Антимагия защищает от метки.")
	TEST_ASSERT_EQUAL(get_turf(ally), ally_start, "Другой еретик не отталкивается.")
	TEST_ASSERT(!ally.has_status_effect(/datum/status_effect/eldritch/void), "Другой еретик не получает метку.")
	var/obj/effect/heretic_combat_zone/void/last_waltz/circle = spell.winter_circle
	TEST_ASSERT_NOTNULL(circle, "Заклинание создаёт зимний круг.")
	TEST_ASSERT_EQUAL(circle.radius, 3, "Круг ограничен тремя клетками.")
	TEST_ASSERT_EQUAL(circle.duration, 12 SECONDS, "Круг живёт 12 секунд.")
	qdel(spell)
	TEST_ASSERT(QDELETED(circle), "Удаление заклинания убирает его круг.")

/// Толчок не перескакивает через занятый тайл и не размножает оставленные зоны.
/datum/unit_test/heretic_last_waltz_blocked/Run()
	var/turf/center = locate(run_loc_floor_bottom_left.x + 3, run_loc_floor_bottom_left.y + 3, run_loc_floor_bottom_left.z)
	var/datum/antagonist/heretic/heretic = allocate_heretic(center)
	var/mob/living/user = heretic.owner.current
	heretic.selected_path = PATH_VOID
	heretic.ascended = TRUE
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, get_step(center, EAST))
	var/turf/victim_start = get_turf(victim)
	var/obj/structure/blocker = allocate(/obj/structure, get_step(victim, EAST))
	blocker.density = TRUE
	var/obj/effect/proc_holder/spell/self/heretic_last_waltz/spell = allocate(/obj/effect/proc_holder/spell/self/heretic_last_waltz)
	spell.cast(list(), user)
	TEST_ASSERT_EQUAL(get_turf(victim), victim_start, "Плотный предмет останавливает толчок.")
	var/obj/effect/heretic_combat_zone/void/last_waltz/first_circle = spell.winter_circle
	spell.cast(list(), user)
	TEST_ASSERT(QDELETED(first_circle), "Повторный такт удаляет предыдущий круг.")
	TEST_ASSERT_NOTNULL(spell.winter_circle, "После повторного такта остаётся один новый круг.")
