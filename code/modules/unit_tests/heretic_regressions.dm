/// Контакт культа оставляет здоровому еретику возможность ответить, сохраняя антимагию и обычные цели.
/datum/unit_test/heretic_cult_stun_counterplay/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/carbon/human/victim = heretic.owner.current
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, get_step(victim, EAST))
	var/datum/mind/mind = allocate_mind()
	mind.current = user
	user.mind = mind
	var/datum/antagonist/cult/cult = allocate(/datum/antagonist/cult)
	cult.owner = mind
	mind.antag_datums = list(cult)
	var/obj/item/melee/blood_magic/stun/hand = allocate(/obj/item/melee/blood_magic/stun)
	hand.afterattack(victim, user, TRUE)
	TEST_ASSERT(QDELETED(hand), "Попадание расходует подготовленную руку.")
	TEST_ASSERT(victim.getStaminaLoss() > 0 && victim.getStaminaLoss() < 50, "Одно попадание истощает, но не отправляет здорового еретика в глубокий stamina-crit.")
	TEST_ASSERT(victim.IsStun() && victim.IsKnockdown(), "Стан временно мешает двигаться и действовать.")
	var/datum/status_effect/incapacitating/stun/stun = victim.IsStun()
	TEST_ASSERT(wait_for_qdeleted(stun, 1.5 SECONDS), "Короткое оглушение заканчивается.")
	TEST_ASSERT(CHECK_MOBILITY(victim, MOBILITY_MOVE | MOBILITY_USE), "Еретик может ползти и применять предметы.")
	var/datum/status_effect/incapacitating/knockdown/fall = victim.IsKnockdown()
	TEST_ASSERT(wait_for_qdeleted(fall, 3 SECONDS), "Еретик снова может встать.")
	victim.setStaminaLoss(0)
	var/datum/component/anti_magic/protection = victim.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 2)
	hand = allocate(/obj/item/melee/blood_magic/stun)
	hand.afterattack(victim, user, TRUE)
	TEST_ASSERT_EQUAL(victim.getStaminaLoss(), 0, "Антимагия по-прежнему блокирует эффект.")
	TEST_ASSERT(!victim.IsStun() && !victim.IsKnockdown(), "Защищённая цель не получает контроль.")
	TEST_ASSERT_EQUAL(protection.charges, 1, "Антимагия расходует один заряд.")
	var/mob/living/carbon/human/ordinary = allocate(/mob/living/carbon/human, get_step(user, EAST))
	hand = allocate(/obj/item/melee/blood_magic/stun)
	hand.afterattack(ordinary, user, TRUE)
	TEST_ASSERT(ordinary.getStaminaLoss() >= 100, "Стан по обычной цели сохраняет прежнюю силу.")

/// Хватка прерывает действия, затем оставляет короткое падение; антимагия блокирует оба эффекта.
/datum/unit_test/heretic_mansus_grasp_knockdown/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	var/mob/living/carbon/human/reference = allocate(/mob/living/carbon/human, get_step(user, NORTH))
	victim.stamina_buffer = 25
	reference.adjustStaminaLoss(60)
	var/obj/item/melee/touch_attack/mansus_fist/fist = allocate(/obj/item/melee/touch_attack/mansus_fist)
	fist.afterattack(victim, user, TRUE)
	TEST_ASSERT(abs(victim.getBruteLoss() - 10) <= DAMAGE_PRECISION, "Хватка наносит десять ушибов.")
	TEST_ASSERT(abs(victim.getStaminaLoss() - reference.getStaminaLoss()) <= DAMAGE_PRECISION, "Хватка наносит обычный урон выносливости, несмотря на полный буфер.")
	TEST_ASSERT_EQUAL(victim.stamina_buffer, 25, "Урон хватки не списывается из синей обводки выносливости.")
	TEST_ASSERT(victim.AmountKnockdown() > 1.9 SECONDS, "Хватка устанавливает двухсекундное падение.")
	TEST_ASSERT(victim.AmountStun() > 0.9 SECONDS, "Хватка оглушает на одну секунду.")
	TEST_ASSERT(!CHECK_MOBILITY(victim, MOBILITY_MOVE | MOBILITY_USE), "Попавшая хватка прерывает движение и применение оружия.")
	var/datum/status_effect/incapacitating/stun/stun = victim.IsStun()
	TEST_ASSERT(wait_for_qdeleted(stun, 1.5 SECONDS), "Оглушение заканчивается раньше падения.")
	TEST_ASSERT(victim.IsKnockdown(), "После оглушения ещё нельзя встать.")
	victim.set_resting(FALSE, TRUE)
	victim.update_mobility()
	TEST_ASSERT(!CHECK_MOBILITY(victim, MOBILITY_STAND), "Попытка встать не отменяет действие хватки.")
	TEST_ASSERT(CHECK_MOBILITY(victim, MOBILITY_MOVE | MOBILITY_USE), "Цель сохраняет возможность ползти и пользоваться предметами.")
	var/datum/status_effect/incapacitating/knockdown/fall = victim.IsKnockdown()
	TEST_ASSERT(wait_for_qdeleted(fall, 3 SECONDS), "Двухсекундное падение заканчивается.")
	victim.set_resting(FALSE, TRUE)
	victim.update_mobility()
	TEST_ASSERT(CHECK_MOBILITY(victim, MOBILITY_STAND), "После окончания эффекта цель может встать.")
	var/datum/component/anti_magic/protection = victim.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5)
	fist = allocate(/obj/item/melee/touch_attack/mansus_fist)
	fist.afterattack(victim, user, TRUE)
	TEST_ASSERT(!victim.IsKnockdown(), "Антимагия блокирует падение от хватки.")
	TEST_ASSERT(!victim.IsStun(), "Антимагия блокирует оглушение от хватки.")
	TEST_ASSERT_EQUAL(protection.charges, 4, "Защита расходует один заряд на хватку.")

/// Ржавчина разрушает шлюзы с базовым знанием, сохраняя неразрушимые двери и ограничения других путей.
/datum/unit_test/heretic_rust_grasp_doors/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	var/obj/machinery/door/airlock/door = allocate(/obj/machinery/door/airlock, get_step(user, EAST))
	var/obj/item/melee/touch_attack/mansus_fist/fist = allocate(/obj/item/melee/touch_attack/mansus_fist)
	fist.afterattack(door, user, TRUE)
	TEST_ASSERT_EQUAL(door.obj_integrity, door.max_integrity, "Обычная хватка не разрушает дверь без Пути Ржавчины.")
	TEST_ASSERT(!QDELETED(fist), "Неподходящая цель не расходует хватку.")
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_rust)
	fist.afterattack(door, user, TRUE)
	TEST_ASSERT(QDELETED(door), "Базовая Ржавчина разрушает обычный шлюз за одно касание.")
	TEST_ASSERT(QDELETED(fist), "Разрушение шлюза расходует хватку.")
	var/obj/machinery/door/airlock/protected = allocate(/obj/machinery/door/airlock, get_step(user, NORTH))
	protected.resistance_flags |= INDESTRUCTIBLE
	fist = allocate(/obj/item/melee/touch_attack/mansus_fist)
	fist.afterattack(protected, user, TRUE)
	TEST_ASSERT(!QDELETED(protected) && protected.obj_integrity == protected.max_integrity, "Неразрушимый шлюз сохраняется.")
	TEST_ASSERT(!QDELETED(fist), "Неразрушимая цель не расходует хватку.")

/// Стены ржавеют до покупки улучшения; улучшенная хватка обрушает обычную стену сразу.
/datum/unit_test/heretic_rust_grasp_walls/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_rust)
	var/datum/eldritch_knowledge/base_rust/rust = heretic.get_knowledge(/datum/eldritch_knowledge/base_rust)
	rust.combat_resource = 0
	var/turf/place = get_step(user, EAST)
	var/target_x = place.x
	var/target_y = place.y
	var/target_z = place.z
	place = place.ChangeTurf(/turf/closed/wall)
	var/obj/item/melee/touch_attack/mansus_fist/fist = allocate(/obj/item/melee/touch_attack/mansus_fist)
	fist.afterattack(place, user, TRUE)
	place = locate(target_x, target_y, target_z)
	TEST_ASSERT(istype(place, /turf/closed/wall/rust), "Первая базовая хватка ржавит стену без отдельного знания.")
	TEST_ASSERT_EQUAL(rust.combat_resource, 1, "Новая поверхность даёт один нарост.")
	fist = allocate(/obj/item/melee/touch_attack/mansus_fist)
	fist.afterattack(place, user, TRUE)
	place = locate(target_x, target_y, target_z)
	TEST_ASSERT(isopenturf(place), "Второе касание обрушает обычную стену.")
	TEST_ASSERT_EQUAL(rust.combat_resource, 1, "Повторное касание не выдаёт ещё один нарост.")
	heretic.gain_knowledge(/datum/eldritch_knowledge/rust_fist)
	place = place.ChangeTurf(/turf/closed/wall)
	COOLDOWN_RESET(rust, resource_harvest)
	fist = allocate(/obj/item/melee/touch_attack/mansus_fist)
	fist.afterattack(place, user, TRUE)
	place = locate(target_x, target_y, target_z)
	TEST_ASSERT(isopenturf(place), "Улучшенная хватка обрушает обычную стену одним касанием.")
	TEST_ASSERT_EQUAL(rust.combat_resource, 2, "Ускоренное разрушение даёт ровно один нарост.")
	TEST_ASSERT(QDELETED(fist), "Мгновенное разрушение всё равно расходует хватку.")

/// Второе очко Ржавчины открывает активное распространение территории до метки и регенерации.
/datum/unit_test/heretic_rust_early_conversion/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	heretic.knowledge_points = 2
	var/datum/heretic_path/path = GLOB.heretic_paths[PATH_RUST]
	for(var/stage in 1 to 3)
		TEST_ASSERT(heretic.research_knowledge(path.knowledge[stage], user), "Первые ступени доступны без подношений.")
	TEST_ASSERT_EQUAL(heretic.knowledge_points, 0, "Первые ступени укладываются в два очка.")
	TEST_ASSERT(locate(/obj/effect/proc_holder/spell/aoe_turf/rust_conversion) in user.mind.spell_list, "Выброс ржавчины выдан до покупки метки и пассивного лечения.")

/// Удаление нацеленного заклинания освобождает обе ссылки тела после потери клиента.
/datum/unit_test/heretic_targeted_spell_deletion/Run()
	for(var/spell_type in list(/obj/effect/proc_holder/spell/pointed/heretic_lunge, /obj/effect/proc_holder/spell/self/cosmic/manifest))
		var/datum/antagonist/heretic/heretic = allocate_heretic()
		var/mob/living/user = heretic.owner.current
		var/obj/effect/proc_holder/spell/spell = allocate(spell_type)
		heretic.owner.AddSpell(spell)
		user.ranged_ability = spell
		user.click_intercept = spell
		spell.ranged_ability_user = user
		spell.active = TRUE
		TEST_ASSERT_NULL(user.client, "Тело осталось без клиента перед удалением заклинания.")
		qdel(spell)
		TEST_ASSERT_NULL(user.ranged_ability, "Удалённое заклинание не остаётся выбранной способностью тела.")
		TEST_ASSERT_NULL(user.click_intercept, "Удалённое заклинание перестаёт перехватывать щелчки.")
		TEST_ASSERT_NULL(spell.ranged_ability_user, "Удалённое заклинание отпускает прежнего владельца.")
		TEST_ASSERT(!spell.active, "Прицел удалённого заклинания выключен.")
		TEST_ASSERT(!(spell in heretic.owner.spell_list), "Mind освобождает удалённое заклинание.")

/// Пересадка еретика снимает старый прицел и выдаёт новому телу готовое заклинание.
/datum/unit_test/heretic_targeted_spell_transfer/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/old_body = heretic.owner.current
	heretic.apply_innate_effects(old_body)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/blade_lunge)
	var/datum/eldritch_knowledge/spell/blade_lunge/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/spell/blade_lunge)
	var/obj/effect/proc_holder/spell/old_spell = knowledge.granted_spell
	old_body.ranged_ability = old_spell
	old_body.click_intercept = old_spell
	old_spell.ranged_ability_user = old_body
	old_spell.active = TRUE
	var/mob/living/new_body = allocate(/mob/living/carbon/human, get_step(old_body, EAST))
	heretic.owner.transfer_to(new_body)
	TEST_ASSERT(QDELETED(old_spell), "Смена тела удаляет прежний экземпляр выпада.")
	TEST_ASSERT_NULL(old_body.ranged_ability, "Старое тело не сохраняет удалённый выпад.")
	TEST_ASSERT_NULL(old_body.click_intercept, "Старое тело не сохраняет перехват щелчков.")
	TEST_ASSERT_NULL(old_spell.ranged_ability_user, "Прежний выпад отпускает старое тело.")
	TEST_ASSERT(knowledge.granted_spell && knowledge.granted_spell != old_spell, "Новому телу выдан отдельный экземпляр выпада.")
	TEST_ASSERT(!knowledge.granted_spell.active, "Новый выпад не наследует включённый прицел.")
	TEST_ASSERT_EQUAL(knowledge.granted_spell.charge_counter, knowledge.granted_spell.charge_max, "Новый выпад готов к применению.")

/// Снятие старого прицела сохраняет заменившую его способность и чужой перехват щелчков.
/datum/unit_test/heretic_targeted_spell_replacement/Run()
	var/mob/living/user = allocate(/mob/living/carbon/human)
	var/obj/effect/proc_holder/spell/pointed/heretic_lunge/old_spell = allocate(/obj/effect/proc_holder/spell/pointed/heretic_lunge)
	var/obj/effect/proc_holder/spell/self/cosmic/manifest/replacement = allocate(/obj/effect/proc_holder/spell/self/cosmic/manifest)
	user.ranged_ability = replacement
	user.click_intercept = old_spell
	old_spell.ranged_ability_user = user
	old_spell.active = TRUE
	replacement.ranged_ability_user = user
	replacement.active = TRUE
	old_spell.remove_ranged_ability()
	TEST_ASSERT_EQUAL(user.ranged_ability, replacement, "Запоздалая очистка сохраняет выбранную новую способность.")
	TEST_ASSERT_NULL(user.click_intercept, "Оставшийся старый перехват щелчков снимается отдельно.")
	TEST_ASSERT_NULL(old_spell.ranged_ability_user, "Старое заклинание отпускает владельца после замены.")
	TEST_ASSERT(!old_spell.active && replacement.active, "Выключается только старый прицел.")
	user.ranged_ability = old_spell
	user.click_intercept = replacement
	old_spell.ranged_ability_user = user
	old_spell.active = TRUE
	old_spell.remove_ranged_ability()
	TEST_ASSERT_NULL(user.ranged_ability, "Старый указатель способности снимается независимо от нового перехвата.")
	TEST_ASSERT_EQUAL(user.click_intercept, replacement, "Чужой перехват щелчков сохраняется.")
	replacement.remove_ranged_ability()
	TEST_ASSERT_NULL(user.click_intercept, "Отмена без клиента освобождает последний перехват.")
	old_spell.active = TRUE
	old_spell.remove_ranged_ability()
	TEST_ASSERT(!old_spell.active, "Отмена без владельца тоже выключает прицел.")

/// Боевые посохи учитывают защиту капюшона при настоящем ударе в голову.
/datum/unit_test/heretic_staff_armor/Run()
	for(var/staff_type in list(/obj/item/staff/bostaff, /obj/item/staff/bostaff/chaplain))
		var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
		var/mob/living/carbon/human/unarmored = allocate(/mob/living/carbon/human, get_step(user, EAST))
		var/mob/living/carbon/human/armored = allocate(/mob/living/carbon/human, get_step(user, NORTH))
		var/obj/item/clothing/suit/hooded/cultrobes/eldritch/robes = allocate(/obj/item/clothing/suit/hooded/cultrobes/eldritch)
		TEST_ASSERT(armored.equip_to_slot_if_possible(robes, ITEM_SLOT_OCLOTHING), "Мантия надета.")
		robes.ToggleHood()
		TEST_ASSERT_EQUAL(armored.head, robes.hood, "Капюшон закрывает голову.")
		var/obj/item/staff/bostaff/staff = allocate(staff_type)
		staff.wound_bonus = CANT_WOUND
		TEST_ASSERT(user.put_in_active_hand(staff), "Посох взят в руку.")
		var/datum/component/two_handed/two_handed = staff.GetComponent(/datum/component/two_handed)
		two_handed.wield(user)
		TEST_ASSERT(staff.wielded, "Посох удерживается двумя руками.")
		user.a_intent = INTENT_HARM
		user.zone_selected = BODY_ZONE_HEAD
		unarmored.dna.species.spec_attacked_by(staff, user, unarmored.get_bodypart(BODY_ZONE_HEAD), INTENT_HARM, unarmored)
		armored.dna.species.spec_attacked_by(staff, user, armored.get_bodypart(BODY_ZONE_HEAD), INTENT_HARM, armored)
		var/unarmored_damage = unarmored.getBruteLoss()
		var/armored_damage = armored.getBruteLoss()
		TEST_ASSERT(unarmored_damage > 0 && armored_damage > 0, "Оба удара дошли до цели.")
		TEST_ASSERT(armored_damage < unarmored_damage * 0.5, "Капюшон уменьшает урон посоха, а не пробивается полностью.")

/// Защита служебных ролей действует на все способы назначения еретика.
/datum/unit_test/heretic_dynamic_role_protection
	var/previous_protection

/datum/unit_test/heretic_dynamic_role_protection/Destroy()
	CONFIG_SET(flag/protect_roles_from_antagonist, previous_protection)
	return ..()

/datum/unit_test/heretic_dynamic_role_protection/Run()
	previous_protection = CONFIG_GET(flag/protect_roles_from_antagonist)
	for(var/protection_enabled in list(FALSE, TRUE))
		CONFIG_SET(flag/protect_roles_from_antagonist, protection_enabled)
		for(var/ruleset_type in list(/datum/dynamic_ruleset/roundstart/heretics, /datum/dynamic_ruleset/midround/crew_conversion/heretic, /datum/dynamic_ruleset/latejoin/heretic_smuggler))
			var/datum/dynamic_ruleset/ruleset = allocate(ruleset_type)
			SSdirector.apply_role_protection(ruleset)
			TEST_ASSERT_EQUAL(("Vanguard Operative" in ruleset.restricted_roles), protection_enabled, "Назначение [ruleset.type] учитывает настройку защиты оперативников.")
			TEST_ASSERT(!("Scientist" in ruleset.restricted_roles), "Защита оперативников не запрещает обычную профессию экипажа.")

/// Ранняя хватка запускает горение и сбор угольков, сохраняя перезарядку и защиту от магии.
/datum/unit_test/heretic_ash_grasp_ignition/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_ash)
	heretic.gain_knowledge(/datum/eldritch_knowledge/ashen_grasp)
	var/datum/eldritch_knowledge/base_ash/path = heretic.get_knowledge(/datum/eldritch_knowledge/base_ash)
	var/datum/eldritch_knowledge/ashen_grasp/grasp = heretic.get_knowledge(/datum/eldritch_knowledge/ashen_grasp)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	path.combat_resource = 0
	TEST_ASSERT(grasp.on_mansus_grasp(victim, user, TRUE), "Хватка действует на негорящего врага.")
	TEST_ASSERT(victim.on_fire, "Власть Пепла сама поджигает цель.")
	TEST_ASSERT_EQUAL(path.combat_resource, 1, "Первый поджог даёт уголёк для Угасания.")
	grasp.on_mansus_grasp(victim, user, TRUE)
	TEST_ASSERT_EQUAL(path.combat_resource, 1, "Повторное попадание не обходит перезарядку угольков.")
	victim.ExtinguishMob()
	COOLDOWN_RESET(grasp, resource_harvest)
	ADD_TRAIT(victim, TRAIT_NOFIRE, TRAIT_GENERIC)
	grasp.on_mansus_grasp(victim, user, TRUE)
	TEST_ASSERT(!victim.on_fire, "Огнестойкую цель нельзя поджечь хваткой.")
	TEST_ASSERT_EQUAL(path.combat_resource, 1, "Негорящая цель не даёт уголёк.")
	REMOVE_TRAIT(victim, TRAIT_NOFIRE, TRAIT_GENERIC)
	var/datum/component/anti_magic/protection = victim.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5)
	COOLDOWN_RESET(grasp, resource_harvest)
	TEST_ASSERT(!grasp.on_mansus_grasp(victim, user, TRUE), "Антимагия блокирует хватку.")
	TEST_ASSERT(!victim.on_fire, "Антимагия защищает от поджога.")
	TEST_ASSERT_EQUAL(path.combat_resource, 1, "Защищённая цель не даёт уголёк.")
	TEST_ASSERT_EQUAL(protection.charges, 4, "Хватка расходует один заряд защиты.")
	qdel(protection)
	grasp.on_mansus_grasp(victim, user, TRUE)
	TEST_ASSERT(victim.on_fire, "После снятия защиты цель снова можно поджечь.")
	TEST_ASSERT_EQUAL(path.combat_resource, 2, "После перезарядки можно получить следующий уголёк.")

/// Возвращение без старого тела восстанавливает знания, а снятие роли без тела освобождает заклинания.
/datum/unit_test/heretic_bodyless_recovery/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/datum/mind/soul = heretic.owner
	var/mob/living/old_body = soul.current
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/basic)
	heretic.gain_knowledge(/datum/eldritch_knowledge/cold_snap)
	heretic.gain_knowledge(/datum/eldritch_knowledge/flame_immunity)
	var/datum/eldritch_knowledge/spell/basic/grasp = heretic.get_knowledge(/datum/eldritch_knowledge/spell/basic)
	var/obj/effect/proc_holder/spell/old_grasp = grasp.granted_spell
	old_body.mind = null
	soul.current = null
	qdel(old_body)
	var/mob/living/new_body = allocate(/mob/living/carbon/human)
	soul.transfer_to(new_body, TRUE)
	TEST_ASSERT_EQUAL(soul.current, new_body, "Перенос завершился в новом теле.")
	TEST_ASSERT(HAS_TRAIT(new_body, TRAIT_NOBREATH) && HAS_TRAIT(new_body, TRAIT_RESISTCOLD) && HAS_TRAIT(new_body, TRAIT_NOFIRE), "Новое тело получило пассивы Пустоты и Пепла.")
	TEST_ASSERT(QDELETED(old_grasp) && !QDELETED(grasp.granted_spell), "Заклинание заменено при переносе без старого тела.")
	var/obj/effect/proc_holder/spell/new_grasp = grasp.granted_spell
	new_body.mind = null
	soul.current = null
	qdel(new_body)
	heretic.clear_heretic()
	TEST_ASSERT(heretic.role_removed && QDELETED(new_grasp), "Снятие бестелесной роли завершает очистку знаний.")

/// Проверки защиты не расходуют зарядов, а атаки учитывают обычную и психическую антимагию.
/datum/unit_test/heretic_legacy_antimagic/Run()
	var/mob/living/victim = allocate(/mob/living/carbon/human)
	var/datum/component/anti_magic/protection = victim.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5)
	TEST_ASSERT(victim.anti_magic_check(), "Старый вызов продолжает блокировать магию.")
	TEST_ASSERT_EQUAL(protection.charges, 5, "Старый вызов не начал расходовать заряды.")
	TEST_ASSERT(!heretic_can_affect(null, victim, chargecost = 0), "Проба еретика видит защиту.")
	TEST_ASSERT_EQUAL(protection.charges, 5, "Проба не расходует заряды.")
	TEST_ASSERT(!heretic_can_affect(null, victim), "Атака еретика блокируется.")
	TEST_ASSERT_EQUAL(protection.charges, 4, "Атака еретика расходует один заряд.")
	qdel(protection)
	var/obj/item/clothing/head/foilhat/hat = allocate(/obj/item/clothing/head/foilhat)
	var/mob/living/carbon/human/human = victim
	TEST_ASSERT(human.equip_to_slot_if_possible(hat, ITEM_SLOT_HEAD), "Шапочка надета на голову.")
	TEST_ASSERT(!heretic_can_affect(null, victim, chargecost = 0), "Шапочка блокирует психическую магию еретика.")
	var/datum/component/anti_magic/psychic = hat.GetComponent(/datum/component/anti_magic)
	TEST_ASSERT_EQUAL(psychic.charges, 6, "Проверка не расходует заряд шапочки.")
	TEST_ASSERT(!heretic_can_affect(null, victim), "Атака также блокируется шапочкой.")
	TEST_ASSERT_EQUAL(psychic.charges, 5, "Настоящая атака расходует один заряд шапочки.")

/// Промах клинка, недоступный сдвиг и повторное касание нити не расходуют защиту.
/datum/unit_test/heretic_combat_probe_charges/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	var/datum/component/anti_magic/protection = victim.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5)
	var/obj/item/melee/sickly_blade/void/blade = allocate(/obj/item/melee/sickly_blade/void)
	user.a_intent = INTENT_HARM
	blade.force = 0
	blade.attack(victim, user)
	TEST_ASSERT_EQUAL(protection.charges, 5, "Удар без урона не расходует защиту от эффектов клинка.")
	blade.force = 22
	blade.attack(victim, user)
	TEST_ASSERT_EQUAL(protection.charges, 4, "Реальное ранение расходует один заряд на блокирование эффектов.")
	var/datum/eldritch_knowledge/void_blade_upgrade/blink = allocate(/datum/eldritch_knowledge/void_blade_upgrade)
	COOLDOWN_START(blink, blink_cooldown, 8 SECONDS)
	blink.on_ranged_attack_eldritch_blade(victim, user)
	TEST_ASSERT_EQUAL(protection.charges, 4, "Сдвиг на перезарядке не расходует защиту.")
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_cosmic)
	var/datum/eldritch_knowledge/base_cosmic/cosmic = heretic.get_knowledge(/datum/eldritch_knowledge/base_cosmic)
	for(var/crossing in 1 to 3)
		TEST_ASSERT(!cosmic.cross_thread(victim), "Защита блокирует нить созвездия.")
	TEST_ASSERT_EQUAL(protection.charges, 4, "Повторные касания нити не расходуют защиту.")
	var/obj/item/heretic_relic/censer/censer = allocate(/obj/item/heretic_relic/censer)
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_ash)
	user.put_in_hands(censer)
	var/datum/component/anti_magic/user_protection = user.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5)
	for(var/check_index in 1 to 3)
		TEST_ASSERT_NULL(censer.get_path(user), "Антимагия не позволяет воспользоваться реликвией.")
	TEST_ASSERT_EQUAL(user_protection.charges, 5, "Проверка реликвии не расходует защиту владельца.")
	qdel(user_protection)
	censer.stored_fire = censer.max_fire
	victim.adjust_fire_stacks(2)
	victim.IgniteMob()
	TEST_ASSERT(!censer.capture_fire(user, victim), "Полная кадильница не забирает пламя.")
	TEST_ASSERT_EQUAL(protection.charges, 4, "Полная кадильница не расходует защиту цели.")
	user.dropItemToGround(censer)
	var/obj/item/heretic_relic/suture_needle/needle = allocate(/obj/item/heretic_relic/suture_needle)
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_flesh)
	user.put_in_hands(needle)
	TEST_ASSERT(!needle.can_mend(user, victim), "Проверка иглы отклоняет защищённую цель.")
	TEST_ASSERT_EQUAL(protection.charges, 4, "Проверка иглы не расходует защиту цели.")

/// Перекрывающиеся потоки одного заклинания проверяют антимагию один раз.
/datum/unit_test/heretic_fire_line_shared_protection/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(heretic.owner.current, EAST))
	var/datum/component/anti_magic/protection = victim.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5)
	var/obj/effect/proc_holder/spell/pointed/nightwatchers_rite/spell = allocate(/obj/effect/proc_holder/spell/pointed/nightwatchers_rite)
	var/list/magic_checks = list()
	for(var/stream in 1 to 5)
		spell.fire_line(heretic.owner.current, list(get_turf(victim)), magic_checks)
	TEST_ASSERT_EQUAL(protection.charges, 4, "Пять потоков одного каста расходуют один заряд.")
	TEST_ASSERT_EQUAL(victim.getFireLoss(), 0, "Защита действует на все потоки каста.")

/// Истощённые тела не принимаются ни до обращения, ни после снятия роли слуги.
/datum/unit_test/heretic_flesh_exhausted_body/Run()
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human)
	TEST_ASSERT_NULL(heretic_conversion_block_reason(victim), "Обычное тело допускает обращение.")
	victim.become_husk("test_burn")
	TEST_ASSERT(heretic_conversion_block_reason(victim), "Обгоревшее тело не подходит для полного восстановления через обращение.")
	victim.cure_husk(list("test_burn"))
	var/datum/mind/soul = new
	allocated += soul
	soul.current = victim
	victim.mind = soul
	var/datum/antagonist/heretic_monster/ghoul/servant = allocate(/datum/antagonist/heretic_monster/ghoul)
	servant.owner = soul
	soul.antag_datums = list(servant)
	servant.silent = TRUE
	servant.health_cap = 50
	servant.apply_innate_effects(victim)
	servant.remove_innate_effects(victim)
	TEST_ASSERT(!HAS_TRAIT(victim, TRAIT_HUSK), "Снятие роли убирает принадлежащий ей внешний эффект.")
	TEST_ASSERT(heretic_conversion_block_reason(victim), "Снятие роли не позволяет повторно использовать ту же плоть.")

/// Отказ шкафа восстанавливает замок и сохраняет запас ключей.
/datum/unit_test/heretic_lock_failed_opening/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_lock)
	var/datum/eldritch_knowledge/base_lock/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/base_lock)
	var/obj/structure/closet/closet = allocate(/obj/structure/closet, get_step(user, EAST))
	closet.locked = TRUE
	var/mob/living/blocker = allocate(/mob/living/carbon/human, get_turf(closet))
	blocker.anchored = TRUE
	var/resource_before = knowledge.combat_resource
	TEST_ASSERT(!knowledge.open_lock(closet, user, TRUE), "Тяжёлый моб мешает открыть шкаф.")
	TEST_ASSERT(closet.locked && !closet.opened, "Отказ оставляет шкаф закрытым и запертым.")
	TEST_ASSERT_EQUAL(knowledge.combat_resource, resource_before, "Отказ не даёт ключ.")
	TEST_ASSERT(COOLDOWN_FINISHED(knowledge, resource_harvest), "Отказ не начинает перезарядку добычи ключа.")
	qdel(blocker)
	TEST_ASSERT(knowledge.open_lock(closet, user, TRUE), "После удаления препятствия шкаф открывается.")
	TEST_ASSERT(!closet.locked && closet.opened, "Успешное открытие снимает замок.")

/// Проклятие резервирует предметы с отпечатками на руне, но не соседние вещи.
/datum/unit_test/heretic_curse_fingerprint_anchors/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human)
	var/obj/item/melee/sickly_blade/blade = allocate(/obj/item/melee/sickly_blade, get_step(user, WEST))
	var/obj/item/radio/headset/headset = allocate(/obj/item/radio/headset)
	var/obj/item/pen/ingredient = allocate(/obj/item/pen)
	blade.fingerprints = list()
	blade.fingerprints[md5(user.dna.uni_identity)] = TRUE
	headset.fingerprints = list()
	headset.fingerprints[md5(victim.dna.uni_identity)] = TRUE
	var/datum/eldritch_knowledge/curse/curse = allocate(/datum/eldritch_knowledge/curse)
	curse.required_atoms = list(/obj/item/pen)
	heretic.researched_knowledge[curse.type] = curse
	var/obj/effect/eldritch/rune = allocate(/obj/effect/eldritch/big)
	var/list/selected = list()
	TEST_ASSERT(rune.select_recipe_atoms(curse, list(blade, headset, ingredient), selected, list(), user), "Предмет жертвы найден после собственного клинка.")
	TEST_ASSERT(curse.fingerprints[md5(victim.dna.uni_identity)], "Объединённый список содержит отпечатки жертвы.")
	TEST_ASSERT(rune.reserve_atoms(selected), "Якоря резервируются вместе с компонентом.")
	rune.ritual_user = user
	TEST_ASSERT(rune.ritual_valid(user, curse), "Повторная проверка сохраняет якоря и отпечатки.")
	TEST_ASSERT(!(blade in selected), "Соседний клинок не стал якорем проклятия.")
	blade.forceMove(user)
	TEST_ASSERT(rune.ritual_valid(user, curse), "Поднятие соседней вещи не прерывает обряд.")
	headset.forceMove(get_step(get_turf(headset), EAST))
	TEST_ASSERT(!rune.ritual_valid(user, curse), "Перенос якоря прерывает обряд.")
	rune.release_atoms()
	curse.cleanup_atoms(selected)
	TEST_ASSERT(!QDELETED(blade) && !QDELETED(headset), "Якоря с отпечатками не расходуются.")
	TEST_ASSERT(QDELETED(ingredient), "Компонент рецепта расходуется.")

/// Смена и сброс текущей цели сохраняют историю разных душ даже с одинаковыми именами.
/datum/unit_test/heretic_hunt_assignment_history/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/datum/antagonist/heretic/first = allocate_heretic()
	var/datum/antagonist/heretic/second = allocate_heretic()
	first.owner.current.real_name = "Тестовая цель"
	second.owner.current.real_name = "Тестовая цель"
	heretic.set_hunt_target(first.owner)
	heretic.set_hunt_target(second.owner)
	heretic.set_hunt_target(first.owner)
	heretic.set_hunt_target(null)
	TEST_ASSERT_EQUAL(length(heretic.sac_targetted), 2, "История различает души и не дублирует повторное назначение.")
	TEST_ASSERT(findtext(heretic.roundend_report(), "Тестовая цель"), "Раундэнд показывает имена из истории после сброса цели.")
	TEST_ASSERT(!findtext(heretic.antag_panel(), "Тестовая цель"), "Панель текущей охоты не выдаёт историю за активную цель.")

/// Занятая клетка владельца не срывает затмение: без места копия не появляется, а свободная соседняя клетка её принимает.
/datum/unit_test/heretic_moon_eclipse_failed_placement/Run()
	var/mob/living/user = make_moon_heretic(run_loc_floor_bottom_left)
	var/datum/eldritch_knowledge/base_moon/knowledge = get_heretic_moon(user)
	TEST_ASSERT(knowledge.create_reflection(user, get_step(user, EAST)), "Первая копия создана.")
	TEST_ASSERT(knowledge.create_reflection(user, get_step(user, NORTH)), "Вторая копия создана.")
	var/list/mob/living/simple_animal/hostile/illusion/heretic_moon/original_reflections = knowledge.reflections.Copy()
	allocate(/obj/machinery/door/airlock, get_turf(user))
	TEST_ASSERT(!knowledge.valid_reflection_turf(get_turf(user), user), "Закрытый шлюз блокирует место для отражения.")
	var/list/obj/structure/fillers = list()
	for(var/direction in GLOB.alldirs)
		var/turf/neighbour = get_step(user, direction)
		if(locate(/mob/living/simple_animal/hostile/illusion/heretic_moon) in neighbour)
			continue
		var/obj/structure/filler = allocate(/obj/structure, neighbour)
		filler.density = TRUE
		fillers += filler
	var/mob/living/victim = allocate(/mob/living/carbon/human, locate(user.x + 2, user.y + 2, user.z))
	var/obj/effect/proc_holder/spell/self/heretic_moon/eclipse/spell = allocate(/obj/effect/proc_holder/spell/self/heretic_moon/eclipse)
	spell.charge_counter = 0
	spell.cast(list(user), user)
	TEST_ASSERT_EQUAL(spell.charge_counter, 0, "Нехватка места для копии не отменяет затмение.")
	TEST_ASSERT(victim.confused > 0, "Затмение путает врага и без новой копии.")
	TEST_ASSERT(user.has_status_effect(/datum/status_effect/heretic_moon_shroud), "Владелец скрывается и без новой копии.")
	TEST_ASSERT_EQUAL(length(knowledge.reflections), 2, "Без места новая копия не появляется.")
	TEST_ASSERT_EQUAL(length(knowledge.reflections & original_reflections), 2, "Без новой копии старые отражения не удаляются.")
	var/obj/structure/freed = fillers[1]
	var/turf/free_turf = get_turf(freed)
	qdel(freed)
	spell.charge_counter = 0
	spell.cast(list(user), user)
	TEST_ASSERT_EQUAL(spell.charge_counter, 0, "Успешное затмение расходует перезарядку.")
	TEST_ASSERT(locate(/mob/living/simple_animal/hostile/illusion/heretic_moon) in free_turf, "Копия встаёт на свободную соседнюю клетку.")
	TEST_ASSERT_EQUAL(length(knowledge.reflections), knowledge.reflection_limit(), "Замена на пределе сохраняет число копий.")
	TEST_ASSERT(QDELETED(original_reflections[1]), "После создания новой копии удаляется самая старая.")

/// Мелкие животные не получают метку и не дают ресурс после удара клинком.
/datum/unit_test/heretic_small_animal_marks/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_ash)
	heretic.gain_knowledge(/datum/eldritch_knowledge/ash_mark)
	var/datum/eldritch_knowledge/base_ash/path = heretic.get_knowledge(/datum/eldritch_knowledge/base_ash)
	var/datum/eldritch_knowledge/mark = heretic.get_knowledge(/datum/eldritch_knowledge/ash_mark)
	var/mob/living/simple_animal/mouse/mouse = allocate(/mob/living/simple_animal/mouse)
	var/obj/item/melee/sickly_blade/ash/blade = allocate(/obj/item/melee/sickly_blade/ash)
	path.combat_resource = 0
	mark.on_mansus_grasp(mouse, user, TRUE)
	TEST_ASSERT(!mouse.has_status_effect(/datum/status_effect/eldritch/ash), "Хватка не ставит метку на мышь.")
	user.a_intent = INTENT_HARM
	blade.attack(mouse, user)
	TEST_ASSERT_EQUAL(path.combat_resource, 0, "Удар по мыши не даёт уголёк.")

/// Сброс боевого искусства не снимает вознесение и не оставляет уязвимость после его удаления.
/datum/unit_test/heretic_ascension_martial_reset/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/final_eldritch/knowledge = allocate(/datum/eldritch_knowledge/final_eldritch)
	knowledge.finished = TRUE
	knowledge.on_body_gain(user)
	var/datum/martial_art/the_sleeping_carp/carp = allocate(/datum/martial_art/the_sleeping_carp)
	TEST_ASSERT(carp.teach(user), "Боевой стиль изучен после вознесения.")
	carp.remove(user)
	user.apply_damage(20, BRUTE, BODY_ZONE_CHEST, wound_bonus = CANT_WOUND)
	user.apply_damage(20, BURN, BODY_ZONE_CHEST, wound_bonus = CANT_WOUND)
	TEST_ASSERT(abs(user.getBruteLoss() - 20 * HERETIC_ASCENDED_DAMAGE_MOD) < 0.01, "Снятие стиля сохраняет защиту от ушибов.")
	TEST_ASSERT(abs(user.getFireLoss() - 20 * HERETIC_ASCENDED_DAMAGE_MOD) < 0.01, "Снятие стиля сохраняет защиту от ожогов.")
	var/stamina_before = user.getStaminaLoss()
	user.apply_damage(20, STAMINA, BODY_ZONE_CHEST)
	TEST_ASSERT(abs(user.getStaminaLoss() - stamina_before - 20 * HERETIC_ASCENDED_STAMINA_MOD) < 0.01, "Снятие стиля сохраняет защиту выносливости: [user.getStaminaLoss() - stamina_before].")
	knowledge.on_body_lose(user)
	var/brute_before = user.getBruteLoss()
	var/burn_before = user.getFireLoss()
	stamina_before = user.getStaminaLoss()
	user.apply_damage(20, BRUTE, BODY_ZONE_CHEST, wound_bonus = CANT_WOUND)
	user.apply_damage(20, BURN, BODY_ZONE_CHEST, wound_bonus = CANT_WOUND)
	user.apply_damage(20, STAMINA, BODY_ZONE_CHEST)
	TEST_ASSERT(abs(user.getBruteLoss() - brute_before - 20) < 0.01, "Снятие вознесения не оставляет множитель 1 / 0.75.")
	TEST_ASSERT(abs(user.getFireLoss() - burn_before - 20) < 0.01, "Ожоги также возвращаются к обычному урону.")
	TEST_ASSERT(abs(user.getStaminaLoss() - stamina_before - 20) < 0.01, "Выносливость после снятия вознесения получает обычный урон: [user.getStaminaLoss() - stamina_before].")

/// Внешнее изменение максимума здоровья не мешает снять ограничение слуги.
/datum/unit_test/heretic_servant_health_cap_change/Run()
	var/datum/antagonist/heretic/fixture = allocate_heretic()
	var/mob/living/body = fixture.owner.current
	var/datum/antagonist/heretic_monster/servant = allocate(/datum/antagonist/heretic_monster)
	servant.owner = fixture.owner
	fixture.owner.antag_datums += servant
	servant.health_cap = 50
	body.setMaxHealth(100)
	servant.apply_health_cap(body)
	body.setMaxHealth(60)
	servant.restore_health_cap(body)
	TEST_ASSERT_EQUAL(body.maxHealth, 100, "Частичное внешнее повышение не оставляет тело с урезанным максимумом.")
	servant.apply_health_cap(body)
	body.setMaxHealth(150)
	servant.restore_health_cap(body)
	TEST_ASSERT_EQUAL(body.maxHealth, 150, "Повышение сверх исходного максимума сохраняется.")
	TEST_ASSERT_EQUAL(servant.pre_conversion_max_health, 0, "Запас старого тела очищен для переноса роли.")

/// Отпущенный гуль не оставляет свою цель в общем списке целей.
/datum/unit_test/heretic_ghoul_release_objective/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_FLESH
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_flesh)
	heretic.gain_knowledge(/datum/eldritch_knowledge/flesh_grasp)
	var/datum/eldritch_knowledge/base_flesh/path = heretic.get_knowledge(/datum/eldritch_knowledge/base_flesh)
	var/datum/eldritch_knowledge/flesh_grasp/grasp = heretic.get_knowledge(/datum/eldritch_knowledge/flesh_grasp)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, get_step(heretic.owner.current, EAST))
	var/datum/mind/soul = allocate_mind()
	soul.current = victim
	victim.mind = soul
	victim.death()
	path.combat_resource = 1
	TEST_ASSERT(grasp.raise_ghoul(heretic.owner.current, victim), "Хватка поднимает гуля.")
	var/owned_objectives = 0
	for(var/datum/objective/objective in GLOB.objectives)
		if(objective.owner == soul)
			owned_objectives++
	TEST_ASSERT_EQUAL(owned_objectives, 1, "Гуль получает цель помогать хозяину.")
	grasp.release_flesh_servants()
	TEST_ASSERT_NULL(soul.has_antag_datum(/datum/antagonist/heretic_monster), "Отпущенный гуль теряет роль.")
	for(var/datum/objective/objective in GLOB.objectives)
		TEST_ASSERT(objective.owner != soul, "Цель отпущенного гуля не остаётся в общем списке целей.")

/// Мёртвое тело не получает расширенный предел лунных отражений.
/datum/unit_test/heretic_moon_dead_ascension/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_moon)
	var/datum/eldritch_knowledge/base_moon/moon = heretic.get_knowledge(/datum/eldritch_knowledge/base_moon)
	var/datum/eldritch_knowledge/final_eldritch/moon_final/final_knowledge = allocate(/datum/eldritch_knowledge/final_eldritch/moon_final)
	final_knowledge.finished = TRUE
	var/mob/living/user = heretic.owner.current
	user.stat = DEAD
	final_knowledge.on_body_gain(user)
	TEST_ASSERT_NULL(final_knowledge.applied_body, "Общий эффект не применился к мёртвому телу.")
	TEST_ASSERT(!moon.ascension_active, "Лунный предел тоже не применился.")

/// Картовая руна ужимается до тайла, ритуальная рисуется в родном размере 3x3 и центрируется на клетке.
/datum/unit_test/heretic_map_rune_scale/Run()
	var/obj/effect/eldritch/huge/map_rune = allocate(/obj/effect/eldritch/huge)
	var/obj/effect/eldritch/big/ritual_rune = allocate(/obj/effect/eldritch/big)
	var/matrix/map_transform = map_rune.transform
	var/matrix/ritual_transform = ritual_rune.transform
	TEST_ASSERT_EQUAL(map_transform.a, 1 / HERETIC_RUNE_SCALE, "Картовая руна ужата по горизонтали.")
	TEST_ASSERT_EQUAL(map_transform.e, 1 / HERETIC_RUNE_SCALE, "Картовая руна ужата по вертикали.")
	TEST_ASSERT_EQUAL(ritual_transform.a, 1, "Ритуальная руна не масштабируется.")
	TEST_ASSERT_EQUAL(ritual_rune.pixel_x, -32, "Спрайт 96x96 сдвинут на тайл влево.")
	TEST_ASSERT_EQUAL(ritual_rune.pixel_y, -32, "Спрайт 96x96 сдвинут на тайл вниз.")

/// Очаг возвращается к открывшимся клеткам и лечит владельца с нулевым жезлом.
/datum/unit_test/heretic_rust_reopened_field/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	var/obj/effect/heretic_combat_zone/rust/zone = allocate(/obj/effect/heretic_combat_zone/rust, get_turf(user), heretic.owner)
	STOP_PROCESSING(SSprocessing, zone)
	var/turf/first = get_turf(user)
	var/turf/hidden = get_step(user, EAST)
	var/turf/newly_visible = get_step(user, NORTH)
	zone.refresh_boundary(list(first, hidden))
	zone.refresh_boundary(list(first))
	zone.tick_zone(user, list(first, user))
	TEST_ASSERT(istype(first, /turf/open/floor/plating/rust), "Видимый пол покрывается ржавчиной.")
	TEST_ASSERT(!istype(hidden, /turf/open/floor/plating/rust), "Закрытый пол не затронут.")
	zone.refresh_boundary(list(first, hidden, newly_visible))
	zone.tick_zone(user, list(first, hidden, newly_visible, user))
	TEST_ASSERT(istype(hidden, /turf/open/floor/plating/rust), "Повторно открывшийся пол не потерян.")
	TEST_ASSERT(istype(newly_visible, /turf/open/floor/plating/rust), "Пол, закрытый при создании очага, тоже обрабатывается.")
	var/obj/item/nullrod/rod = allocate(/obj/item/nullrod)
	user.put_in_hands(rod)
	TEST_ASSERT(user.check_magic_resistance(chargecost = 0), "Владелец действительно защищён нулевым жезлом.")
	user.adjustBruteLoss(10)
	zone.tick_zone(user, list(first, hidden, newly_visible, user))
	TEST_ASSERT(abs(user.getBruteLoss() - 7) < 0.001, "Жезл не отключает лечение самого владельца.")

/// Удаление кодекса с открытым интерфейсом не оставляет ссылок и не требует harddel.
/datum/unit_test/heretic_log_cleanup/Run()
	var/book_ref = delete_book()
	sleep(2 SECONDS)
	var/datum/book = locate(book_ref)
	TEST_ASSERT(!book || !QDELING(book), "Кодекс не должен удерживаться после удаления.")

/datum/unit_test/heretic_log_cleanup/proc/delete_book()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	var/obj/item/forbidden_book/book = new(get_turf(user))
	user.put_in_hands(book)
	var/datum/tgui/heretic_book_test/ui = allocate(/datum/tgui/heretic_book_test, user, book, "ForbiddenLore", "Кодекс Рубцов")
	ui.window = allocate(/datum/tgui_window/heretic_book_test)
	ui.window.locked_by = ui
	ui.initialized = TRUE
	ui.status = UI_INTERACTIVE
	SStgui.on_open(ui)
	book.ui_interact(user, ui)
	heretic.clear_heretic()
	var/book_ref = text_ref(book)
	qdel(book)
	return book_ref

/// Сифон завершает лечение и перенос крови, когда на конечностях нет ран.
/datum/unit_test/heretic_blood_siphon_unwounded/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	var/obj/effect/proc_holder/spell/pointed/blood_siphon/spell = allocate(/obj/effect/proc_holder/spell/pointed/blood_siphon)
	user.adjustBruteLoss(30)
	user.blood_volume = BLOOD_VOLUME_NORMAL - 40
	user.integrating_blood = 0
	victim.blood_volume = BLOOD_VOLUME_NORMAL
	for(var/obj/item/bodypart/limb as anything in user.bodyparts)
		TEST_ASSERT_NULL(limb.wounds, "На здоровых конечностях список ран не создан.")
	spell.cast(list(victim), user)
	TEST_ASSERT(abs(user.getBruteLoss() - 10) <= DAMAGE_PRECISION, "Сифон лечит 20 ушибов.")
	TEST_ASSERT(abs(victim.getBruteLoss() - 20) <= DAMAGE_PRECISION, "Сифон наносит 20 ушибов.")
	TEST_ASSERT_EQUAL(user.integrating_blood, 20, "Отсутствие ран не прерывает получение крови для усвоения.")
	TEST_ASSERT_EQUAL(victim.blood_volume, BLOOD_VOLUME_NORMAL - 20, "Цель теряет перелитую кровь.")

/// Сработавшая руна освобождает место у ножа и собирается без harddel.
/datum/unit_test/heretic_spent_rune_cleanup/Run()
	var/obj/item/melee/rune_knife/knife = allocate(/obj/item/melee/rune_knife)
	var/rune_uid = trigger_rune(knife)
	var/list/wait_budget = new_wait_budget(5 SECONDS, "Удаление сработавшей руны")
	while(!isnull(locateUID(rune_uid)))
		// BYOND держит атомы последнего view() до следующего вызова, а свет искр зовёт его рядом с руной.
		pass(view(0, run_loc_floor_bottom_left))
		if(!wait_budget_tick(wait_budget))
			break
	TEST_ASSERT_EQUAL(length(knife.current_runes), 0, "Сработавшая руна освобождает лимит ножа после завершения эффекта.")
	var/datum/rune = locateUID(rune_uid)
	TEST_ASSERT(!rune || !QDELING(rune), "Нож не удерживает удалённую руну до следующего вырезания.")

/datum/unit_test/heretic_spent_rune_cleanup/proc/trigger_rune(obj/item/melee/rune_knife/knife)
	var/obj/structure/trap/eldritch/mad/rune = new(run_loc_floor_bottom_left)
	knife.track_rune(rune)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, EAST))
	rune.last_trigger = world.time - rune.time_between_triggers - 1 SECONDS
	var/rune_uid = rune.UID()
	rune.Crossed(victim)
	return rune_uid

/// Разрушение рун удаляет все три знака, несмотря на изменение списка во время удаления.
/datum/unit_test/heretic_rune_shatter_cleanup/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	var/obj/item/melee/rune_knife/knife = allocate(/obj/item/melee/rune_knife)
	knife.attack_hand(user)
	TEST_ASSERT(user.is_holding(knife), "Нож должен оказаться в руке после подбора.")
	knife.linked_action.Grant(user)
	var/list/runes = list()
	for(var/rune_type in list(/obj/structure/trap/eldritch/alert, /obj/structure/trap/eldritch/tentacle, /obj/structure/trap/eldritch/mad))
		var/obj/structure/trap/eldritch/rune = allocate(rune_type)
		rune.set_owner(user)
		knife.track_rune(rune)
		runes += rune
	TEST_ASSERT(knife.linked_action.Trigger(), "Владелец может активировать разрушение рун.")
	TEST_ASSERT_EQUAL(length(knife.current_runes), 0, "Разрушение освобождает весь лимит.")
	for(var/obj/structure/trap/eldritch/rune as anything in runes)
		TEST_ASSERT(QDELETED(rune), "Каждая привязанная руна уничтожена.")
		TEST_ASSERT_NULL(rune.owner, "Удалённая руна отпускает владельца.")

/// Уничтожение ножа убирает его руны и связь действия с предметом.
/datum/unit_test/heretic_rune_knife_cleanup/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	var/obj/item/melee/rune_knife/knife = allocate(/obj/item/melee/rune_knife)
	knife.attack_hand(user)
	TEST_ASSERT(user.is_holding(knife), "Нож должен оказаться в руке после подбора.")
	var/datum/action/innate/rune_shatter/action = knife.linked_action
	var/list/runes = list()
	for(var/rune_index in 1 to knife.max_rune_amt)
		var/obj/structure/trap/eldritch/rune = allocate(/obj/structure/trap/eldritch/tentacle)
		rune.set_owner(user)
		knife.track_rune(rune)
		runes += rune
	qdel(knife)
	TEST_ASSERT_EQUAL(length(knife.current_runes), 0, "Удалённый нож не удерживает руны.")
	TEST_ASSERT(QDELETED(action), "Действие уничтожено вместе с ножом.")
	TEST_ASSERT_NULL(action.target, "Удалённое действие отпускает нож.")
	for(var/obj/structure/trap/eldritch/rune as anything in runes)
		TEST_ASSERT(QDELETED(rune), "Руна не переживает поддерживающий её нож.")
/datum/eldritch_knowledge/mansus_grasp_suspend_test
	var/grasp_calls = 0
	var/grasp_finished = FALSE

/datum/eldritch_knowledge/mansus_grasp_suspend_test/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	grasp_calls++
	sleep(0.5 SECONDS)
	grasp_finished = TRUE
	return FALSE

/// Одна призванная рука наносит один удар и создаёт одну связь при повторном клике во время эффекта.
/datum/unit_test/heretic_mansus_grasp_reentry/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	var/datum/eldritch_knowledge/mansus_grasp_suspend_test/suspension = allocate(/datum/eldritch_knowledge/mansus_grasp_suspend_test)
	heretic.researched_knowledge[suspension.type] = suspension
	heretic.selected_path = PATH_BLOOD
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_blood)
	heretic.gain_knowledge(/datum/eldritch_knowledge/blood_grasp)
	var/obj/effect/proc_holder/spell/targeted/touch/mansus_grasp/spell = allocate(/obj/effect/proc_holder/spell/targeted/touch/mansus_grasp)
	TEST_ASSERT(spell.ChargeHand(user), "Заклинание создаёт настоящую привязанную руку.")
	spell.charge_counter = 0
	spell.recharging = FALSE
	var/obj/item/melee/touch_attack/mansus_fist/hand = spell.attached_hand
	INVOKE_ASYNC(hand, TYPE_PROC_REF(/obj/item/melee/touch_attack/mansus_fist, afterattack), victim, user, TRUE)
	TEST_ASSERT_EQUAL(suspension.grasp_calls, 1, "Первый удар дошёл до приостановленного эффекта.")
	INVOKE_ASYNC(hand, TYPE_PROC_REF(/obj/item/melee/touch_attack/mansus_fist, afterattack), victim, user, TRUE)
	TEST_ASSERT(abs(victim.getBruteLoss() - 10) <= DAMAGE_PRECISION, "Повторный клик не наносит второй урон.")
	TEST_ASSERT_EQUAL(victim.getStaminaLoss(), 60, "Выносливость поражается только один раз.")
	TEST_ASSERT_EQUAL(suspension.grasp_calls, 1, "Эффекты знаний не вызываются повторно.")
	TEST_ASSERT(wait_for_qdeleted(hand), "Первое применение завершается и расходует руку.")
	TEST_ASSERT_NULL(spell.attached_hand, "Заклинание отпускает использованную руку.")
	TEST_ASSERT(spell.recharging, "После удара начинается перезарядка.")
	var/datum/status_effect/heretic_blood_seal/seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	TEST_ASSERT_NOTNULL(seal, "Хватка создаёт настоящую кровную связь.")
	TEST_ASSERT_EQUAL(seal.debt, 10, "Повторный клик не добавляет долг поверх первой связи.")

/// Отмена или сброс приостановленной хватки сохраняет перезарядку и не затрагивает следующую руку.
/datum/unit_test/heretic_mansus_grasp_cancel_during_effect
	var/drop_while_casting = FALSE
	var/cancel_all_while_casting = FALSE

/datum/unit_test/heretic_mansus_grasp_cancel_during_effect/drop
	drop_while_casting = TRUE

/datum/unit_test/heretic_mansus_grasp_cancel_during_effect/cancel_all
	cancel_all_while_casting = TRUE

/datum/unit_test/heretic_mansus_grasp_cancel_during_effect/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	var/datum/eldritch_knowledge/mansus_grasp_suspend_test/suspension = allocate(/datum/eldritch_knowledge/mansus_grasp_suspend_test)
	heretic.researched_knowledge[suspension.type] = suspension
	heretic.selected_path = PATH_BLOOD
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_blood)
	heretic.gain_knowledge(/datum/eldritch_knowledge/blood_grasp)
	var/obj/effect/proc_holder/spell/targeted/touch/mansus_grasp/spell = allocate(/obj/effect/proc_holder/spell/targeted/touch/mansus_grasp)
	TEST_ASSERT(spell.ChargeHand(user), "Первая рука призвана.")
	var/obj/item/melee/touch_attack/mansus_fist/old_hand = spell.attached_hand
	INVOKE_ASYNC(old_hand, TYPE_PROC_REF(/obj/item/melee/touch_attack/mansus_fist, afterattack), victim, user, TRUE)
	TEST_ASSERT_EQUAL(suspension.grasp_calls, 1, "Эффект первого удара приостановлен.")
	if(drop_while_casting)
		user.dropItemToGround(old_hand)
	else if(cancel_all_while_casting)
		TEST_ASSERT(user.cancel_prepared_abilities(), "Общая отмена убирает приостановленную руку.")
	else
		TEST_ASSERT(spell.cancel_cast(user), "Игрок может убрать приостановленную руку.")
	TEST_ASSERT_EQUAL(spell.charge_counter, 0, "Отмена уже нанесённого удара не возвращает заряд.")
	TEST_ASSERT(spell.recharging, "Убранная после удара хватка перезаряжается.")
	TEST_ASSERT(!spell.charge_check(user, TRUE), "Повторный призыв ожидает перезарядку.")
	TEST_ASSERT(spell.ChargeHand(user), "Для проверки старого вызова создаётся следующая рука.")
	var/obj/item/melee/touch_attack/mansus_fist/new_hand = spell.attached_hand
	TEST_ASSERT(wait_for_var(suspension, "grasp_finished", TRUE, 2 SECONDS), "Старый эффект возобновился после отмены.")
	TEST_ASSERT(QDELETED(old_hand), "Старая рука удалена.")
	TEST_ASSERT(!QDELETED(new_hand) && spell.attached_hand == new_hand, "Завершение старого эффекта сохраняет новую руку.")
	TEST_ASSERT_NULL(victim.has_status_effect(/datum/status_effect/heretic_blood_seal), "Отменённая хватка не продолжает применять знания.")
	TEST_ASSERT_EQUAL(new_hand.charges, 1, "Новая рука сохраняет заряд.")
/// Отмена из сигнала завершения удара не вызывает повторное расходование удалённой руки.
/datum/unit_test/heretic_mansus_grasp_cancel_on_hit/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	var/obj/effect/proc_holder/spell/targeted/touch/mansus_grasp/spell = allocate(/obj/effect/proc_holder/spell/targeted/touch/mansus_grasp)
	TEST_ASSERT(spell.ChargeHand(user), "Рука призвана.")
	var/obj/item/melee/touch_attack/mansus_fist/hand = spell.attached_hand
	RegisterSignal(hand, COMSIG_ITEM_AFTERATTACK, PROC_REF(cancel_on_hit))
	hand.afterattack(victim, user, TRUE)
	TEST_ASSERT(QDELETED(hand), "Сигнал удаляет использованную руку.")
	TEST_ASSERT_NULL(spell.attached_hand, "У заклинания не осталось старой руки.")
	TEST_ASSERT_EQUAL(spell.charge_counter, 0, "Отмена на завершении удара сохраняет расход заряда.")
	TEST_ASSERT(spell.recharging, "Отмена на завершении удара запускает перезарядку.")
	TEST_ASSERT(abs(victim.getBruteLoss() - 10) <= DAMAGE_PRECISION, "Выполнен один удар хваткой.")

/datum/unit_test/heretic_mansus_grasp_cancel_on_hit/proc/cancel_on_hit(obj/item/melee/touch_attack/mansus_fist/hand, atom/target, mob/user)
	SIGNAL_HANDLER
	hand.attached_spell.cancel_cast(user)

/// Сброс контактной руки без usr и отмена с числом вместо пользователя безопасно освобождают руку.
/datum/unit_test/heretic_touch_cancel_without_user/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	for(var/spell_type in list(/obj/effect/proc_holder/spell/targeted/touch/mansus_grasp, /obj/effect/proc_holder/spell/targeted/touch/disintegrate))
		var/obj/effect/proc_holder/spell/targeted/touch/spell = allocate(spell_type)
		for(var/has_owner in list(FALSE, TRUE))
			if(has_owner)
				spell.action.Grant(user)
			for(var/drop_hand in list(FALSE, TRUE))
				TEST_ASSERT(spell.ChargeHand(user), "Контактная рука подготовлена.")
				spell.charge_counter = 0
				var/obj/item/melee/touch_attack/hand = spell.attached_hand
				if(drop_hand)
					user.drop_all_held_items()
				else
					TEST_ASSERT(spell.cancel_cast(0), "Отмена принимает отсутствие моба-пользователя.")
				TEST_ASSERT(QDELETED(hand), "Подготовленная рука удалена.")
				TEST_ASSERT_NULL(spell.attached_hand, "Заклинание не удерживает удалённую руку.")
				TEST_ASSERT_EQUAL(spell.charge_counter, spell.charge_max, "Неиспользованный заряд возвращён.")
		qdel(spell)
	var/obj/effect/proc_holder/spell/targeted/touch/mansus_grasp/grasp = allocate(/obj/effect/proc_holder/spell/targeted/touch/mansus_grasp)
	TEST_ASSERT(grasp.ChargeHand(user), "Подготовлена рука для начатого удара.")
	var/obj/item/melee/touch_attack/mansus_fist/active_hand = grasp.attached_hand
	active_hand.grasp_in_progress = TRUE
	TEST_ASSERT(grasp.cancel_cast(0), "Начатая Хватка тоже отменяется без пользователя.")
	TEST_ASSERT(QDELETED(active_hand) && isnull(grasp.attached_hand), "Начатая рука удалена.")
	TEST_ASSERT_EQUAL(grasp.charge_counter, 0, "Начатый удар не возвращает заряд.")
	TEST_ASSERT(grasp.recharging, "Начатый удар запускает перезарядку.")

/// Переключение контактных способностей освобождает руку и сохраняет клинок и неиспользованный заряд.
/datum/unit_test/heretic_prepared_touch_switch/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/obj/item/melee/sickly_blade/blade = allocate(/obj/item/melee/sickly_blade)
	TEST_ASSERT(user.put_in_hands(blade), "Клинок занимает одну руку.")
	var/obj/effect/proc_holder/spell/targeted/touch/previous
	for(var/spell_type in list(/obj/effect/proc_holder/spell/targeted/touch/mansus_grasp, /obj/effect/proc_holder/spell/targeted/touch/mad_touch, /obj/effect/proc_holder/spell/targeted/touch/grasp_of_decay, /obj/effect/proc_holder/spell/targeted/touch/mansus_grasp))
		var/obj/effect/proc_holder/spell/targeted/touch/spell = allocate(spell_type)
		var/obj/item/melee/touch_attack/old_hand = previous?.attached_hand
		TEST_ASSERT(spell.ChargeHand(user), "Следующая способность заменяет предыдущую при занятой клинком руке.")
		spell.charge_counter = 0
		TEST_ASSERT(user.is_holding(blade) && user.is_holding(spell.attached_hand), "В руках остаются клинок и только выбранная способность.")
		if(previous)
			TEST_ASSERT(QDELETED(old_hand), "Предыдущая рука удалена.")
			TEST_ASSERT_NULL(previous.attached_hand, "Предыдущее заклинание отпустило руку.")
			TEST_ASSERT_EQUAL(previous.charge_counter, previous.charge_max, "Неиспользованный заряд возвращён.")
		previous = spell
	TEST_ASSERT(user.cancel_prepared_abilities(), "Общая отмена убирает подготовленную способность.")
	TEST_ASSERT(user.is_holding(blade), "Отмена не выбрасывает клинок.")
	TEST_ASSERT(!user.cancel_prepared_abilities(), "После отмены обычное выбрасывание снова доступно.")

/// Контактная способность снимает прицеливание, а общая отмена освобождает перехватчик кликов.
/datum/unit_test/heretic_prepared_target_cancel/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/obj/effect/proc_holder/spell/pointed/blood_siphon/ranged_spell = allocate(/obj/effect/proc_holder/spell/pointed/blood_siphon)
	var/obj/effect/proc_holder/spell/targeted/touch/mansus_grasp/touch_spell = allocate(/obj/effect/proc_holder/spell/targeted/touch/mansus_grasp)
	user.ranged_ability = ranged_spell
	user.click_intercept = ranged_spell
	ranged_spell.ranged_ability_user = user
	ranged_spell.active = TRUE
	TEST_ASSERT(touch_spell.ChargeHand(user), "Хватка выбирается поверх прицеливания.")
	TEST_ASSERT_NULL(user.ranged_ability, "Хватка снимает выбранную дальнюю способность.")
	TEST_ASSERT_NULL(user.click_intercept, "Клики снова доходят до предмета в руке.")
	TEST_ASSERT(!ranged_spell.active, "Предыдущая кнопка больше не подсвечена.")
	TEST_ASSERT_EQUAL(ranged_spell.charge_counter, ranged_spell.charge_max, "Отмена прицеливания не расходует заряд.")
	user.cancel_prepared_abilities(ranged_spell)
	TEST_ASSERT_NULL(touch_spell.attached_hand, "Подготовка прицеливания освобождает контактную руку.")
	user.ranged_ability = ranged_spell
	user.click_intercept = ranged_spell
	ranged_spell.ranged_ability_user = user
	ranged_spell.active = TRUE
	var/obj/item/melee/sickly_blade/blade = allocate(/obj/item/melee/sickly_blade)
	TEST_ASSERT(user.put_in_hands(blade), "После смены способности можно взять клинок.")
	TEST_ASSERT(user.cancel_prepared_abilities(), "Общая отмена снимает прицеливание.")
	TEST_ASSERT_NULL(user.click_intercept, "Прицеливание не блокирует последующие клики.")
	TEST_ASSERT(user.is_holding(blade), "Клинок сохранён при отмене прицеливания.")

/// Активация контактной руки отменяет заклинание; другие роли сохраняют независимые руки.
/datum/unit_test/heretic_prepared_inhand_cancel/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/obj/effect/proc_holder/spell/targeted/touch/mansus_grasp/spell = allocate(/obj/effect/proc_holder/spell/targeted/touch/mansus_grasp)
	TEST_ASSERT(spell.ChargeHand(user), "Хватка подготовлена.")
	spell.charge_counter = 0
	spell.attached_hand.attack_self(user)
	TEST_ASSERT_NULL(spell.attached_hand, "Активация предмета освобождает руку.")
	TEST_ASSERT_EQUAL(spell.charge_counter, spell.charge_max, "Отмена до удара сохраняет заряд.")
	var/mob/living/carbon/human/other = allocate(/mob/living/carbon/human)
	var/obj/effect/proc_holder/spell/targeted/touch/first = allocate(/obj/effect/proc_holder/spell/targeted/touch/disintegrate)
	var/obj/effect/proc_holder/spell/targeted/touch/second = allocate(/obj/effect/proc_holder/spell/targeted/touch/flesh_to_stone)
	TEST_ASSERT(first.ChargeHand(other) && second.ChargeHand(other), "У другой роли по-прежнему допустимы две контактные руки.")
	TEST_ASSERT(other.is_holding(first.attached_hand) && other.is_holding(second.attached_hand), "Переключение еретика не меняет другие роли.")
	TEST_ASSERT(!other.cancel_prepared_abilities(), "Общая отмена еретика не действует на другую роль.")

/// Хоткей Хватки соблюдает состояние и перезарядку и повторным нажатием освобождает руку.
/datum/unit_test/heretic_ability_hotkey_activation/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/basic)
	var/datum/eldritch_knowledge/spell/basic/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/spell/basic)
	var/obj/effect/proc_holder/spell/targeted/touch/mansus_grasp/spell = knowledge.granted_spell
	TEST_ASSERT(user.activate_ability_hotkey(1), "Первый слот вызывает Хватку через общий обработчик роли.")
	TEST_ASSERT(user.is_holding(spell.attached_hand), "Хоткей создаёт контактную руку.")
	TEST_ASSERT(user.activate_ability_hotkey(1), "Повторное нажатие отменяет Хватку.")
	TEST_ASSERT_NULL(spell.attached_hand, "Повторное нажатие освобождает руку.")
	TEST_ASSERT_EQUAL(spell.charge_counter, spell.charge_max, "Отмена до удара возвращает заряд.")
	user.Paralyze(5 SECONDS)
	user.activate_ability_hotkey(1)
	TEST_ASSERT_NULL(spell.attached_hand, "Оглушённый еретик не подготавливает способность хоткеем.")
	user.SetParalyzed(0)
	spell.charge_counter = 0
	user.activate_ability_hotkey(1)
	TEST_ASSERT_NULL(spell.attached_hand, "Хоткей не обходит перезарядку.")
	TEST_ASSERT_EQUAL(spell.charge_counter, 0, "Отказ не восстанавливает потраченный заряд.")
	spell.charge_counter = spell.charge_max
	heretic.role_removed = TRUE
	TEST_ASSERT(!user.activate_ability_hotkey(1), "Потерянная роль не даёт применять хоткеи.")
	TEST_ASSERT_NULL(spell.attached_hand, "После потери роли рука не создаётся.")

/// Все пути используют одни слоты в книге и хоткеях, а новые знания не сдвигают старые номера.
/datum/unit_test/heretic_ability_hotkey_catalog/Run()
	var/obj/item/forbidden_book/book = allocate(/obj/item/forbidden_book)
	for(var/path_id in GLOB.heretic_paths)
		var/datum/antagonist/heretic/heretic = allocate_heretic()
		var/mob/living/user = heretic.owner.current
		var/datum/heretic_path/path = GLOB.heretic_paths[path_id]
		heretic.gain_knowledge(/datum/eldritch_knowledge/spell/basic)
		TEST_ASSERT(heretic.research_knowledge(path.knowledge[1], user), "Путь [path_id] выбран.")
		var/list/abilities = book.combat_ability_data(heretic)
		TEST_ASSERT_EQUAL(length(abilities), 2, "У пути [path_id] есть Хватка и основная способность.")
		TEST_ASSERT_EQUAL(heretic.ability_hotkey_types[1], /obj/effect/proc_holder/spell/targeted/touch/mansus_grasp, "Первый слот всегда занят Хваткой.")
		for(var/list/ability as anything in abilities)
			TEST_ASSERT(findtext(ability["usage"], "Горячая клавиша:"), "Книга показывает назначение способности [path_id].")
		var/list/old_slots = heretic.ability_hotkey_types.Copy()
		heretic.gain_knowledge(/datum/eldritch_knowledge/spell/summon/book)
		book.combat_ability_data(heretic)
		TEST_ASSERT_EQUAL(length(heretic.ability_hotkey_types), length(old_slots), "Призыв книги не занимает боевой слот.")
		for(var/knowledge_type in path.knowledge)
			heretic.gain_knowledge(knowledge_type)
		book.combat_ability_data(heretic)
		for(var/slot in 1 to length(old_slots))
			TEST_ASSERT_EQUAL(heretic.ability_hotkey_types[slot], old_slots[slot], "Изучение пути не сдвигает слот [slot].")
		var/datum/eldritch_knowledge/base_knowledge = heretic.get_knowledge(path.knowledge[1])
		base_knowledge.on_body_lose(user)
		TEST_ASSERT(!user.activate_ability_hotkey(2), "Удалённая основная способность не вызывается из старого слота.")
	for(var/slot in 1 to ABILITY_HOTKEY_SLOTS)
		var/datum/keybinding/living/ability_slot/binding = GLOB.keybindings_by_name["ability_slot_[slot]"]
		TEST_ASSERT(istype(binding) && binding.ability_slot == slot, "Слот [slot] зарегистрирован в настройках клавиш.")
		TEST_ASSERT("Alt[slot % ABILITY_HOTKEY_SLOTS]" in binding.hotkey_keys, "Слот [slot] имеет заявленное сочетание по умолчанию.")

/// Подготовка Хватки выключает бросок, и следующий клик действительно поражает цель.
/datum/unit_test/heretic_prepared_throw_click/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	var/obj/effect/proc_holder/spell/targeted/touch/mansus_grasp/spell = allocate(/obj/effect/proc_holder/spell/targeted/touch/mansus_grasp)
	user.throw_mode_on()
	TEST_ASSERT(user.throw_mode, "Перед подготовкой включён бросок.")
	TEST_ASSERT(spell.ChargeHand(user), "Хватка подготавливается при включённом броске.")
	TEST_ASSERT(!user.throw_mode, "Подготовка выключила режим броска.")
	spell.charge_counter = 0
	user.ClickOn(victim, "left=1")
	TEST_ASSERT(abs(victim.getBruteLoss() - 10) <= DAMAGE_PRECISION, "Клик наносит урон Хваткой вместо попытки бросить абстрактный предмет.")
	TEST_ASSERT_NULL(spell.attached_hand, "Клик расходует Хватку.")
	TEST_ASSERT(spell.recharging, "После попадания начинается перезарядка.")

/// Включение броска отменяет подготовку без потери оружия; обратный выбор выключает бросок.
/datum/unit_test/heretic_prepared_throw_switch/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/obj/item/melee/sickly_blade/blade = allocate(/obj/item/melee/sickly_blade)
	TEST_ASSERT(user.put_in_hands(blade), "Клинок находится в руке.")
	var/obj/effect/proc_holder/spell/targeted/touch/mansus_grasp/touch_spell = allocate(/obj/effect/proc_holder/spell/targeted/touch/mansus_grasp)
	TEST_ASSERT(touch_spell.ChargeHand(user), "Хватка занимает свободную руку.")
	touch_spell.charge_counter = 0
	user.throw_mode_on()
	TEST_ASSERT(user.throw_mode && user.is_holding(blade), "Режим броска включён, клинок остаётся в руке.")
	TEST_ASSERT_NULL(touch_spell.attached_hand, "Бросок снял подготовленную Хватку.")
	TEST_ASSERT_EQUAL(touch_spell.charge_counter, touch_spell.charge_max, "Неиспользованная Хватка сохраняет заряд.")
	var/obj/effect/proc_holder/spell/pointed/blood_siphon/ranged_spell = allocate(/obj/effect/proc_holder/spell/pointed/blood_siphon)
	user.prepare_ability(ranged_spell)
	TEST_ASSERT(!user.throw_mode, "Подготовка прицеливания также выключает бросок.")
	user.ranged_ability = ranged_spell
	user.click_intercept = ranged_spell
	ranged_spell.ranged_ability_user = user
	ranged_spell.active = TRUE
	user.throw_mode_on()
	TEST_ASSERT(user.throw_mode, "Из прицеливания можно перейти к броску.")
	TEST_ASSERT_NULL(user.ranged_ability, "Бросок снимает прицельную способность.")
	TEST_ASSERT_NULL(user.click_intercept, "Следующий бросок не перехватывается заклинанием.")
	TEST_ASSERT(!ranged_spell.active && user.is_holding(blade), "Кнопка погашена, оружие сохранено.")
	var/mob/living/carbon/human/other = allocate(/mob/living/carbon/human)
	other.throw_mode_on()
	other.prepare_ability(ranged_spell)
	TEST_ASSERT(other.throw_mode, "У других ролей режим броска не изменяется.")

/// Памятка и книга показывают назначенные клавиши, включая независимые сочетания и снятые назначения.
/datum/unit_test/heretic_ability_hotkey_help/Run()
	var/datum/preferences/navigation_test/preferences = allocate(/datum/preferences/navigation_test)
	preferences.key_bindings = list("F2" = list("ability_slot_1"), "CtrlShiftQ" = list("cancel_ability"), "G" = list("drop_item"))
	preferences.modless_key_bindings = list()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/basic)
	var/obj/item/forbidden_book/book = allocate(/obj/item/forbidden_book)
	var/list/abilities = book.combat_ability_data(heretic, preferences)
	var/list/grasp = abilities[1]
	TEST_ASSERT_EQUAL(grasp["hotkey"], "F2", "Книга показывает переназначенную клавишу Хватки.")
	var/help = heretic.format_ability_hotkey_help(preferences)
	TEST_ASSERT(findtext(help, "F2") && findtext(help, "Ctrl+Shift+Q") && findtext(help, "G"), "Стартовая памятка использует текущие клавиши применения и отмены.")
	TEST_ASSERT(!findtext(help, "Alt+1"), "Стандартная клавиша не подменяет действующее назначение.")
	preferences.key_bindings = list("Unbound" = list("ability_slot_1"))
	abilities = book.combat_ability_data(heretic, preferences)
	grasp = abilities[1]
	TEST_ASSERT_EQUAL(grasp["hotkey"], "Не назначена", "Снятое назначение видно в книге.")
	preferences.modless_key_bindings["F3"] = "ability_slot_1"
	abilities = book.combat_ability_data(heretic, preferences)
	grasp = abilities[1]
	TEST_ASSERT_EQUAL(grasp["hotkey"], "F3", "Независимая клавиша тоже показывается.")
	preferences.key_bindings["AltCtrlShift4"] = list("ability_slot_1")
	var/datum/keybinding/binding = GLOB.keybindings_by_name["ability_slot_1"]
	TEST_ASSERT_EQUAL(binding.format_keys(preferences), "Alt+Ctrl+Shift+4 / F3", "Несколько назначений перечислены с разделёнными модификаторами.")

/// Подсказка кнопки дополняет исходный текст и не накапливает подписи при повторном наведении.
/datum/unit_test/heretic_ability_hotkey_tooltip/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/basic)
	var/datum/eldritch_knowledge/spell/basic/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/spell/basic)
	var/datum/action/action = knowledge.granted_spell.action
	var/original_desc = action.desc
	var/tooltip = action.format_tooltip(user, "Описание кнопки")
	TEST_ASSERT(findtext(tooltip, "Описание кнопки") && findtext(tooltip, "Alt+1"), "Подсказка сохраняет описание и показывает клавишу.")
	TEST_ASSERT(findtext(tooltip, "Alt+Q") && findtext(tooltip, "Отмена подготовки"), "Отмена объясняется прямо на кнопке.")
	TEST_ASSERT_EQUAL(action.format_tooltip(user, "Описание кнопки"), tooltip, "Повторное наведение не дублирует подсказку.")
	TEST_ASSERT_EQUAL(action.desc, original_desc, "Исходное описание действия не изменилось.")
	var/mob/living/other = allocate(/mob/living/carbon/human)
	TEST_ASSERT_EQUAL(action.format_tooltip(other, "Чужая кнопка"), "Чужая кнопка", "Наблюдатель не получает подсказку чужих назначений.")
	var/datum/action/ordinary = allocate(/datum/action)
	TEST_ASSERT_EQUAL(ordinary.format_tooltip(user, "Обычная кнопка"), "Обычная кнопка", "Другие действия сохраняют прежний текст.")

/// Новый еретик не появляется под эвак и сверх одного на двадцать живых.
/datum/unit_test/heretic_injection_pacing/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	TEST_ASSERT(heretic_injection_block_reason(HERETIC_CREW_PER_HERETIC - 1), "Живой еретик закрывает второго на малом онлайне.")
	TEST_ASSERT_NULL(heretic_injection_block_reason(HERETIC_CREW_PER_HERETIC * 2), "Двойной онлайн допускает второго.")
	heretic.owner.current.death()
	TEST_ASSERT_NULL(heretic_injection_block_reason(HERETIC_CREW_PER_HERETIC - 1), "Погибший еретик не занимает место.")
	if(!SSshuttle.emergency)
		return
	var/original_mode = SSshuttle.emergency.mode
	SSshuttle.emergency.mode = SHUTTLE_CALL
	var/evac_reason = heretic_injection_block_reason(HERETIC_CREW_PER_HERETIC * 2)
	SSshuttle.emergency.mode = original_mode
	TEST_ASSERT(evac_reason, "Вызванный шаттл закрывает появление еретика.")
