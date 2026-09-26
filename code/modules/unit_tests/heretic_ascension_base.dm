/datum/unit_test/proc/allocate_ascended_heretic(list/out_knowledge)
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_BLADE
	var/datum/eldritch_knowledge/final_eldritch/blade_final/knowledge = allocate(/datum/eldritch_knowledge/final_eldritch/blade_final)
	heretic.researched_knowledge[knowledge.type] = knowledge
	knowledge.finished = TRUE
	out_knowledge += knowledge
	return heretic

/// Общая база вознесения выдаёт стойкость и полностью снимает её, повторные вызовы ничего не удваивают.
/datum/unit_test/heretic_ascended_base_apply/Run()
	var/list/found = list()
	var/datum/antagonist/heretic/heretic = allocate_ascended_heretic(found)
	var/datum/eldritch_knowledge/final_eldritch/knowledge = found[1]
	var/mob/living/carbon/human/body = heretic.owner.current
	var/original_max_health = body.maxHealth
	var/original_stamina_mod = body.physiology.heretic_stamina_mod
	knowledge.on_body_gain(body)
	knowledge.on_body_gain(body)
	TEST_ASSERT_EQUAL(body.maxHealth, HERETIC_ASCENDED_MAX_HEALTH, "Вознесённый получает 150 здоровья.")
	TEST_ASSERT_EQUAL(body.physiology.heretic_ascension_mod, HERETIC_ASCENDED_DAMAGE_MOD, "Вознесённый получает общую защиту от ран.")
	TEST_ASSERT(abs(body.physiology.heretic_stamina_mod - original_stamina_mod * HERETIC_ASCENDED_STAMINA_MOD) < 0.001, "Урон выносливости снижен один раз.")
	TEST_ASSERT(HAS_TRAIT(body, TRAIT_NOSOFTCRIT), "Вознесённый дерётся до хардкрита.")
	TEST_ASSERT(HAS_TRAIT(body, TRAIT_NOBREATH) && HAS_TRAIT(body, TRAIT_RESISTLOWPRESSURE) && HAS_TRAIT(body, TRAIT_RESISTCOLD), "Выживание в космосе приходит от общей базы.")
	TEST_ASSERT(body.has_status_effect(/datum/status_effect/heretic_ascended), "Тело несёт эффект вознесения.")
	knowledge.on_body_lose(body)
	knowledge.on_body_lose(body)
	TEST_ASSERT_EQUAL(body.maxHealth, original_max_health, "Снятие возвращает прежний предел здоровья.")
	TEST_ASSERT(abs(body.physiology.heretic_stamina_mod - original_stamina_mod) < 0.001, "Снятие возвращает прежний урон выносливости.")
	TEST_ASSERT_EQUAL(body.physiology.heretic_ascension_mod, 1, "Снятие убирает защиту от ран.")
	TEST_ASSERT(!HAS_TRAIT(body, TRAIT_NOSOFTCRIT), "Снятие возвращает софткрит.")
	TEST_ASSERT(!HAS_TRAIT(body, TRAIT_HERETIC_ASCENDED), "Снятие убирает метку вознесённого.")
	TEST_ASSERT(!body.has_status_effect(/datum/status_effect/heretic_ascended), "Эффект вознесения снят.")

/// Снятие вознесения убирает только добавленное здоровье и не сбивает чужие изменения предела.
/datum/unit_test/heretic_ascended_max_health_outside_change/Run()
	var/list/found = list()
	var/datum/antagonist/heretic/heretic = allocate_ascended_heretic(found)
	var/datum/eldritch_knowledge/final_eldritch/knowledge = found[1]
	var/mob/living/carbon/human/body = heretic.owner.current
	var/original_max_health = body.maxHealth
	knowledge.on_body_gain(body)
	body.setMaxHealth(body.maxHealth + 10)
	knowledge.on_body_lose(body)
	TEST_ASSERT_EQUAL(body.maxHealth, original_max_health + 10, "Прибавка, полученная во время вознесения, сохраняется.")
	body.setMaxHealth(body.maxHealth - 10)
	TEST_ASSERT_EQUAL(body.maxHealth, original_max_health, "После снятия прибавки предел возвращается к исходному.")
	knowledge.on_body_gain(body)
	body.maxHealth *= 1.5
	knowledge.on_body_lose(body)
	body.maxHealth /= 1.5
	TEST_ASSERT(body.maxHealth >= original_max_health, "Халк во время вознесения не урезает здоровье после обоих снятий: [body.maxHealth].")
	body.setMaxHealth(original_max_health)
	knowledge.on_body_gain(body)
	body.setMaxHealth(original_max_health / 2)
	knowledge.on_body_lose(body)
	TEST_ASSERT_EQUAL(body.maxHealth, original_max_health / 2, "Предел, заданный заново во время вознесения, не уменьшается ещё раз.")

/// Оглушения, сбивания с ног и обездвиживание действуют на вознесённого вчетверо короче.
/datum/unit_test/heretic_ascended_stun_scaling/Run()
	var/mob/living/carbon/human/plain = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	plain.Paralyze(100)
	TEST_ASSERT(abs(plain.AmountParalyzed() - 100) < 0.01, "Обычный человек парализуется на полный срок: [plain.AmountParalyzed()].")
	var/list/found = list()
	var/datum/antagonist/heretic/heretic = allocate_ascended_heretic(found)
	var/datum/eldritch_knowledge/final_eldritch/knowledge = found[1]
	var/mob/living/carbon/human/body = heretic.owner.current
	knowledge.on_body_gain(body)
	body.Paralyze(100)
	TEST_ASSERT(body.AmountParalyzed() >= 20 && body.AmountParalyzed() <= 30, "Паралич сокращён до четверти: [body.AmountParalyzed()].")
	body.Knockdown(100)
	TEST_ASSERT(body.AmountKnockdown() >= 20 && body.AmountKnockdown() <= 30, "Сбивание с ног сокращено до четверти: [body.AmountKnockdown()].")
	body.Immobilize(100)
	TEST_ASSERT(body.AmountImmobilized() >= 20 && body.AmountImmobilized() <= 30, "Обездвиживание сокращено до четверти: [body.AmountImmobilized()].")
	body.Stun(100)
	TEST_ASSERT(body.AmountStun() >= 20 && body.AmountStun() <= 30, "Оглушение сокращено до четверти: [body.AmountStun()].")
	body.SetParalyzed(0)
	TEST_ASSERT(!body.IsParalyzed(), "Снятие паралича не перехватывается.")

/// Стамкрит остаётся главным способом свалить вознесённого.
/datum/unit_test/heretic_ascended_stamcrit_reachable/Run()
	var/list/found = list()
	var/datum/antagonist/heretic/heretic = allocate_ascended_heretic(found)
	var/datum/eldritch_knowledge/final_eldritch/knowledge = found[1]
	var/mob/living/carbon/human/body = heretic.owner.current
	knowledge.on_body_gain(body)
	var/stamina_before = body.getStaminaLoss()
	body.apply_damage(30, STAMINA, BODY_ZONE_CHEST)
	var/delta = body.getStaminaLoss() - stamina_before
	TEST_ASSERT(abs(delta - 30 * HERETIC_ASCENDED_STAMINA_MOD) < 0.5, "Удар по выносливости ослаблен до 30%: [delta].")
	body.adjustStaminaLoss(500)
	TEST_ASSERT(IS_STAMCRIT(body), "Изматывание доводит вознесённого до стамкрита.")

/// Регенерация ждёт пять секунд без урона и лечит по 2 ушиба за тик.
/datum/unit_test/heretic_ascended_regen_delay/Run()
	var/list/found = list()
	var/datum/antagonist/heretic/heretic = allocate_ascended_heretic(found)
	var/datum/eldritch_knowledge/final_eldritch/knowledge = found[1]
	var/mob/living/carbon/human/body = heretic.owner.current
	knowledge.on_body_gain(body)
	var/datum/status_effect/heretic_ascended/effect = body.has_status_effect(/datum/status_effect/heretic_ascended)
	TEST_ASSERT_NOTNULL(effect, "Эффект вознесения выдан.")
	body.apply_damage(40, BRUTE, BODY_ZONE_CHEST, wound_bonus = CANT_WOUND)
	var/brute_hurt = body.getBruteLoss()
	TEST_ASSERT(brute_hurt > 0, "Удар оставил ушибы.")
	effect.tick()
	TEST_ASSERT_EQUAL(body.getBruteLoss(), brute_hurt, "Сразу после удара регенерации нет.")
	effect.last_damage_time = world.time - HERETIC_ASCENDED_REGEN_DELAY
	effect.tick()
	TEST_ASSERT(abs(body.getBruteLoss() - (brute_hurt - HERETIC_ASCENDED_REGEN)) < 0.01, "Через пять секунд без урона ушибы лечатся: [body.getBruteLoss()].")
	body.death()
	var/brute_dead = body.getBruteLoss()
	effect.last_damage_time = world.time - HERETIC_ASCENDED_REGEN_DELAY
	effect.tick()
	TEST_ASSERT_EQUAL(body.getBruteLoss(), brute_dead, "Мёртвое тело не регенерирует.")

/// Вознесённого отмечает трейт для быстрого разрыва наручников, смерть его снимает.
/datum/unit_test/heretic_ascended_cuffs/Run()
	var/list/found = list()
	var/datum/antagonist/heretic/heretic = allocate_ascended_heretic(found)
	var/datum/eldritch_knowledge/final_eldritch/knowledge = found[1]
	var/mob/living/carbon/human/body = heretic.owner.current
	knowledge.on_body_gain(body)
	TEST_ASSERT(HAS_TRAIT(body, TRAIT_HERETIC_ASCENDED), "Вознесённый рвёт наручники как халк.")
	body.death()
	heretic.handle_death(body)
	TEST_ASSERT(!HAS_TRAIT(body, TRAIT_HERETIC_ASCENDED), "Смерть снимает метку вознесённого.")
