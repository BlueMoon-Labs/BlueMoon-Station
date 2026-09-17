/datum/unit_test/proc/prepare_heretic_stun_weapon(weapon_type, charge = null, enabled = TRUE)
	var/obj/item/weapon = allocate(weapon_type)
	if(istype(weapon, /obj/item/melee/baton))
		var/obj/item/melee/baton/baton = weapon
		baton.turned_on = enabled
	else if(istype(weapon, /obj/item/electrostaff))
		var/obj/item/electrostaff/staff = weapon
		staff.on = enabled
	else if(istype(weapon, /obj/item/melee/classic_baton))
		var/obj/item/melee/classic_baton/baton = weapon
		baton.on = enabled
	var/obj/item/stock_parts/cell/cell = weapon.get_cell()
	if(cell && !isnull(charge))
		cell.charge = charge
	return weapon

/datum/unit_test/proc/attack_with_heretic_stun_weapon(obj/item/weapon, mob/living/target, mob/living/attacker, shoving = TRUE)
	if(shoving && istype(weapon, /obj/item/melee/baton))
		var/obj/item/melee/baton/baton = weapon
		return baton.common_baton_melee(target, attacker, shoving = TRUE)
	return weapon.attack(target, attacker)

/// Парирование останавливает последовательные разряды и удары дубинками до исчерпания блоков.
/datum/unit_test/heretic_nonlethal_parry/Run()
	var/list/attacks = list(
		list(/obj/item/melee/baton/loaded, INTENT_DISARM),
		list(/obj/item/melee/baton/loaded, INTENT_DISARM, FALSE),
		list(/obj/item/melee/classic_baton, INTENT_DISARM),
		list(/obj/item/melee/classic_baton/telescopic, INTENT_DISARM),
		list(/obj/item/electrostaff, INTENT_DISARM),
		list(/obj/item/electrostaff, INTENT_HARM),
	)
	for(var/list/attack as anything in attacks)
		var/list/fixture = make_blade_fixture()
		var/mob/living/user = fixture["user"]
		var/mob/living/attacker = fixture["attacker"]
		var/datum/eldritch_knowledge/base_blade/knowledge = fixture["knowledge"]
		attacker.a_intent = attack[2]
		var/shoving = length(attack) < 3 || attack[3]
		var/obj/item/weapon = prepare_heretic_stun_weapon(attack[1])
		var/obj/item/stock_parts/cell/cell = weapon.get_cell()
		var/charge_before = cell?.charge
		TEST_ASSERT(knowledge.begin_parry(user), "Стойка доступна перед ударом [weapon.type].")
		var/datum/status_effect/heretic_parry/parry = knowledge.active_parry
		attack_with_heretic_stun_weapon(weapon, user, attacker, shoving)
		TEST_ASSERT_EQUAL(user.getStaminaLoss() + user.getBruteLoss() + user.getFireLoss(), 0, "Парирование останавливает урон [weapon.type], режим [attacker.a_intent].")
		TEST_ASSERT(!user.resting && !user.incapacitated(), "Полный блок предотвращает сбивание и оглушение.")
		TEST_ASSERT_EQUAL(parry.blocks_left, 2, "Удар расходует один блок.")
		TEST_ASSERT_EQUAL(knowledge.combat_resource, 1, "Успешный блок приносит один Темп.")
		TEST_ASSERT_EQUAL(cell?.charge, charge_before, "Полностью отражённый разряд не расходует батарею.")
		attack_with_heretic_stun_weapon(weapon, user, attacker, shoving)
		TEST_ASSERT_EQUAL(user.getStaminaLoss() + user.getBruteLoss() + user.getFireLoss(), 0, "Повторный удар блокируется без задержки.")
		TEST_ASSERT_EQUAL(parry.blocks_left, 1, "Повторный удар расходует следующий блок.")
		attack_with_heretic_stun_weapon(weapon, user, attacker, shoving)
		TEST_ASSERT_NULL(knowledge.active_parry, "Третий удар исчерпывает стойку.")
		TEST_ASSERT_EQUAL(user.getStaminaLoss() + user.getBruteLoss() + user.getFireLoss(), 0, "Последний блок также предотвращает урон.")
		attack_with_heretic_stun_weapon(weapon, user, attacker, shoving)
		TEST_ASSERT(user.getStaminaLoss() + user.getFireLoss() > 0, "После исчерпания блоков разряд действует.")

/// Выключенное и разряженное оружие не расходует стойку и не даёт Темп.
/datum/unit_test/heretic_nonlethal_inert/Run()
	for(var/weapon_type in list(/obj/item/melee/baton/loaded, /obj/item/electrostaff))
		var/list/fixture = make_blade_fixture()
		var/mob/living/user = fixture["user"]
		var/mob/living/attacker = fixture["attacker"]
		var/datum/eldritch_knowledge/base_blade/knowledge = fixture["knowledge"]
		attacker.a_intent = INTENT_DISARM
		TEST_ASSERT(knowledge.begin_parry(user), "Стойка доступна.")
		var/datum/status_effect/heretic_parry/parry = knowledge.active_parry
		var/obj/item/off_weapon = prepare_heretic_stun_weapon(weapon_type, enabled = FALSE)
		attack_with_heretic_stun_weapon(off_weapon, user, attacker)
		var/obj/item/empty_weapon = prepare_heretic_stun_weapon(weapon_type, charge = 0)
		attack_with_heretic_stun_weapon(empty_weapon, user, attacker)
		var/list/preview = list(BLOCK_CONTEXT_DAMAGE = 35, BLOCK_CONTEXT_DAMAGE_TYPE = STAMINA)
		user.do_run_block(FALSE, empty_weapon, 0, "разряд", ATTACK_TYPE_MELEE, 0, attacker, null, preview)
		user.mob_run_block(off_weapon, 0, "касание", ATTACK_TYPE_MELEE, 0, attacker, null, list())
		TEST_ASSERT_EQUAL(user.getStaminaLoss(), 0, "Неактивное оружие не наносит урон выносливости.")
		TEST_ASSERT_EQUAL(parry.blocks_left, 3, "Неактивные удары и предпросмотр сохраняют все блоки.")
		TEST_ASSERT_EQUAL(knowledge.combat_resource, 0, "Неактивные удары не создают Темп.")
		TEST_ASSERT(!user.has_status_effect(STATUS_EFFECT_ELECTROSTAFF), "Разряженный посох не замедляет цель в обход стойки.")

/// Оболочка поглощает фактический урон с учётом заряда, размера и режима оружия.
/datum/unit_test/heretic_nonlethal_wax/Run()
	var/list/attacks = list(
		list(/obj/item/melee/baton/loaded, STAMINA, 35, null, 1),
		list(/obj/item/melee/baton/loaded, STAMINA, 17.5, 375, 1),
		list(/obj/item/melee/baton/loaded, STAMINA, 17.5, null, 2),
		list(/obj/item/melee/classic_baton, STAMINA, 30, null, 1),
		list(/obj/item/melee/classic_baton, STAMINA, 15, null, 2),
		list(/obj/item/electrostaff, STAMINA, 50, null, 1),
		list(/obj/item/electrostaff, STAMINA, 25, 166.5, 1),
		list(/obj/item/electrostaff, BURN, 20, null, 1),
		list(/obj/item/electrostaff, BURN, 18, 360, 1),
	)
	for(var/list/attack as anything in attacks)
		for(var/budget in list(0, 10, 60))
			var/datum/antagonist/heretic/heretic = allocate_heretic()
			heretic.selected_path = PATH_WAX
			heretic.gain_knowledge(/datum/eldritch_knowledge/base_wax)
			heretic.gain_knowledge(/datum/eldritch_knowledge/spell/wax_shell)
			var/mob/living/carbon/human/user = heretic.owner.current
			user.dna.features["body_size"] = attack[5]
			if(attack[5] > 1)
				user.mob_weight = MOB_WEIGHT_HEAVY_SUPER
			var/datum/eldritch_knowledge/base_wax/wax = heretic.get_knowledge(/datum/eldritch_knowledge/base_wax)
			var/mob/living/attacker = allocate(/mob/living/carbon/human, get_step(user, EAST))
			attacker.mind = allocate_mind()
			attacker.mind.current = attacker
			attacker.a_intent = attack[2] == BURN ? INTENT_HARM : INTENT_DISARM
			TEST_ASSERT(wax.raise_shell(user), "Оболочка доступна перед атакой.")
			var/datum/status_effect/heretic_wax/shell/shell = user.has_status_effect(/datum/status_effect/heretic_wax/shell)
			shell.capacity = budget
			var/obj/item/weapon = prepare_heretic_stun_weapon(attack[1], attack[4])
			attack_with_heretic_stun_weapon(weapon, user, attacker)
			var/expected_damage = max(0, attack[3] - budget)
			var/actual_damage = attack[2] == BURN ? user.getFireLoss() : user.getStaminaLoss()
			TEST_ASSERT(abs(actual_damage - expected_damage) <= DAMAGE_PRECISION, "[weapon.type]: при запасе [budget] проходит [expected_damage], получено [actual_damage].")
			TEST_ASSERT_EQUAL(shell.capacity, max(0, budget - attack[3]), "Оболочка расходует только фактический урон.")
			TEST_ASSERT_EQUAL(shell.absorbed_hostile, attack[2] == BURN ? min(budget, attack[3]) : 0, "Запас лечения создаётся только из поглощённых ожогов.")
			if(budget >= attack[3])
				TEST_ASSERT(!user.resting && !user.incapacitated(), "Полный блок останавливает сбивание и оглушение.")
				if(istype(weapon, /obj/item/electrostaff))
					var/obj/item/electrostaff/staff = weapon
					TEST_ASSERT(!user.has_status_effect(staff.stun_status_effect), "Полный блок предотвращает замедление электропосохом.")
			qdel(shell)

/// Выключенные разряды и заряд ниже порога дубинки не расходуют оболочку.
/datum/unit_test/heretic_nonlethal_wax_inert/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_WAX
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_wax)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/wax_shell)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_wax/wax = heretic.get_knowledge(/datum/eldritch_knowledge/base_wax)
	var/mob/living/attacker = allocate(/mob/living/carbon/human, get_step(user, EAST))
	attacker.a_intent = INTENT_DISARM
	TEST_ASSERT(wax.raise_shell(user), "Оболочка доступна.")
	var/datum/status_effect/heretic_wax/shell/shell = user.has_status_effect(/datum/status_effect/heretic_wax/shell)
	for(var/weapon_type in list(/obj/item/melee/baton/loaded, /obj/item/electrostaff))
		var/obj/item/off_weapon = prepare_heretic_stun_weapon(weapon_type, enabled = FALSE)
		attack_with_heretic_stun_weapon(off_weapon, user, attacker)
		var/obj/item/empty_weapon = prepare_heretic_stun_weapon(weapon_type, charge = 0)
		attack_with_heretic_stun_weapon(empty_weapon, user, attacker)
	var/obj/item/weak_baton = prepare_heretic_stun_weapon(/obj/item/melee/baton/loaded, charge = 1)
	attack_with_heretic_stun_weapon(weak_baton, user, attacker)
	TEST_ASSERT_EQUAL(user.getStaminaLoss(), 0, "Неактивные разряды не наносят урон.")
	TEST_ASSERT_EQUAL(shell.capacity, 45, "Неактивные разряды сохраняют оболочку.")
	TEST_ASSERT_EQUAL(shell.absorbed_hostile, 0, "Неактивные разряды не создают лечения.")
	TEST_ASSERT(!user.has_status_effect(STATUS_EFFECT_ELECTROSTAFF), "Разряженный посох не замедляет цель в обход оболочки.")
