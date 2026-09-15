/// Контузия требует двух попаданий одной последовательности, допускает уклонение и блокируется антимагией.
/datum/unit_test/heretic_echo_review_dissonance/Run()
	var/turf/center = get_step(get_step(run_loc_floor_bottom_left, NORTHEAST), NORTHEAST)
	var/datum/antagonist/heretic/heretic = allocate_heretic(center)
	heretic.selected_path = PATH_ECHO
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_echo)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/echo_refrain)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_echo/echo = heretic.get_knowledge(/datum/eldritch_knowledge/base_echo)
	var/turf/target = get_step(center, EAST)
	var/mob/living/staying = allocate(/mob/living/carbon/human, target)
	var/mob/living/dodging = allocate(/mob/living/carbon/human, target)
	var/mob/living/protected = allocate(/mob/living/carbon/human, target)
	TEST_ASSERT(echo.refrain(user, target), "Припев выпускает первый такт сразу.")
	TEST_ASSERT(!HAS_TRAIT(staying, TRAIT_MOBILITY_NOUSE), "Первое попадание не блокирует оружие.")
	dodging.forceMove(get_step(center, SOUTHWEST))
	var/datum/component/anti_magic/protection = protected.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5)
	var/datum/heretic_echo_attack/attack = echo.attacks[1]
	attack.resolve()
	TEST_ASSERT(HAS_TRAIT(staying, TRAIT_MOBILITY_NOUSE), "Попадание повторного такта вызывает контузию.")
	TEST_ASSERT(!HAS_TRAIT(dodging, TRAIT_MOBILITY_NOUSE), "Уход с отмеченного пола защищает от контузии.")
	TEST_ASSERT(!HAS_TRAIT(protected, TRAIT_MOBILITY_NOUSE), "Антимагия блокирует и повтор, и контузию.")
	TEST_ASSERT_EQUAL(protection.charges, 4, "Повтор тратит один заряд антимагии на весь эффект.")
	var/datum/status_effect/heretic_echo_dissonance/dissonance = staying.has_status_effect(/datum/status_effect/heretic_echo_dissonance)
	dissonance.duration = world.time + 1 SECONDS
	var/old_expiry = dissonance.duration
	TEST_ASSERT(echo.refrain(user, target), "Следующая последовательность может задеть уже контуженную цель.")
	attack = echo.attacks[1]
	attack.resolve()
	TEST_ASSERT_EQUAL(dissonance.duration, old_expiry, "Новый повтор не продлевает действующую контузию.")
	TEST_ASSERT(wait_for_qdeleted(dissonance, max_wait = 5 SECONDS), "Контузия действительно заканчивается по таймеру.")
	TEST_ASSERT(!HAS_TRAIT(staying, TRAIT_MOBILITY_NOUSE), "Истечение эффекта возвращает возможность атаковать.")
	TEST_ASSERT_EQUAL(length(echo.dissonances), 0, "Завершённый эффект удаляется из знания.")

/// Первые такты разных волн не вызывают контузию, а смена тела снимает только собственный запрет применения предметов.
/datum/unit_test/heretic_echo_review_sequence_cleanup/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_ECHO
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_echo)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/echo_refrain)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_echo/echo = heretic.get_knowledge(/datum/eldritch_knowledge/base_echo)
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	for(var/iteration in 1 to 2)
		TEST_ASSERT(echo.release(user), "Ресурса хватает на первый такт новой волны.")
		var/datum/heretic_echo_attack/attack = echo.attacks[1]
		qdel(attack)
	TEST_ASSERT(!HAS_TRAIT(victim, TRAIT_MOBILITY_NOUSE), "Два первых такта разных волн не считаются последовательностью.")
	TEST_ASSERT(echo.refrain(user, get_turf(victim)), "Припев подготавливает повтор.")
	var/datum/heretic_echo_attack/attack = echo.attacks[1]
	attack.resolve()
	var/datum/status_effect/heretic_echo_dissonance/dissonance = victim.has_status_effect(/datum/status_effect/heretic_echo_dissonance)
	TEST_ASSERT_NOTNULL(dissonance, "Последовательность оставляет контузию.")
	ADD_TRAIT(victim, TRAIT_MOBILITY_NOUSE, "unrelated_nouse")
	echo.on_body_lose(user)
	TEST_ASSERT(QDELETED(dissonance), "Потеря тела немедленно удаляет контузию.")
	TEST_ASSERT(HAS_TRAIT(victim, TRAIT_MOBILITY_NOUSE), "Очистка не снимает чужой запрет применения предметов.")
	REMOVE_TRAIT(victim, TRAIT_MOBILITY_NOUSE, "unrelated_nouse")
	TEST_ASSERT(!HAS_TRAIT(victim, TRAIT_MOBILITY_NOUSE), "Собственного источника запрета предметов больше нет.")

/// Договор ускоряет без должников, сохраняет предел долга и удаляет ускорение вместе со знанием.
/datum/unit_test/heretic_blood_review_rush/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_BLOOD
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_blood)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_blood/blood = heretic.get_knowledge(/datum/eldritch_knowledge/base_blood)
	TEST_ASSERT(!blood.pact(user), "Неизученный Договор недоступен.")
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/blood_pact)
	TEST_ASSERT(blood.pact(user), "Договор работает без должников.")
	TEST_ASSERT(abs(user.getBruteLoss() - 10) <= DAMAGE_PRECISION, "Самостоятельный рывок оплачивается десятью ушибами.")
	TEST_ASSERT_EQUAL(blood.combat_resource, 0, "Ускорение не создаёт долг без должника.")
	TEST_ASSERT(user.has_movespeed_modifier(/datum/movespeed_modifier/heretic_blood_rush), "Договор действительно ускоряет движение.")
	var/datum/status_effect/heretic_blood_rush/rush = blood.blood_rush
	TEST_ASSERT(wait_for_qdeleted(rush, max_wait = 8 SECONDS), "Ускорение заканчивается по таймеру.")
	TEST_ASSERT_NULL(blood.blood_rush, "Истечение не оставляет ссылку на удалённый эффект.")
	TEST_ASSERT(!user.has_movespeed_modifier(/datum/movespeed_modifier/heretic_blood_rush), "Скорость возвращается к обычной.")
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	TEST_ASSERT(blood.release(user, victim), "Цель принимает связь.")
	var/datum/status_effect/heretic_blood_seal/seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	blood.add_debt(seal, blood.debt_cap)
	var/previous_debt = seal.debt
	TEST_ASSERT(blood.pact(user), "Полная связь не запрещает оплаченный рывок.")
	TEST_ASSERT_EQUAL(seal.debt, previous_debt, "Рывок не переполняет долг.")
	rush = blood.blood_rush
	TEST_ASSERT(blood.pact(user), "Повторное применение обновляет ускорение.")
	TEST_ASSERT_EQUAL(blood.blood_rush, rush, "Обновление сохраняет ссылку на действующий эффект.")
	var/datum/eldritch_knowledge/spell/blood_pact/pact = heretic.get_knowledge(/datum/eldritch_knowledge/spell/blood_pact)
	pact.on_body_lose(user)
	TEST_ASSERT_NULL(blood.blood_rush, "Потеря знания немедленно удаляет ускорение.")
	TEST_ASSERT(!user.has_movespeed_modifier(/datum/movespeed_modifier/heretic_blood_rush), "Потеря знания удаляет изменение скорости.")
	user.setToxLoss(user.getToxLoss() + user.health - 34, forced = TRUE)
	TEST_ASSERT(abs(user.health - 34) <= DAMAGE_PRECISION, "Владелец остаётся в сознании, но не может безопасно оплатить ещё десять ушибов.")
	var/damage_before = user.getBruteLoss()
	TEST_ASSERT(!blood.pact(user), "Опасная для жизни плата не разрешает ускорение.")
	TEST_ASSERT_EQUAL(user.getBruteLoss(), damage_before, "Отказ сохраняет здоровье.")
	TEST_ASSERT_NULL(blood.blood_rush, "Отказ не выдаёт бесплатное ускорение.")

/// Своя стеклянная преграда пропускает луч, сохраняя плотность; чужая преграда останавливает свет.
/datum/unit_test/heretic_glass_review_cover/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_GLASS
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_glass)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/glass_barrier)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_glass/glass = heretic.get_knowledge(/datum/eldritch_knowledge/base_glass)
	var/turf/middle = get_step(user, EAST)
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(middle, EAST))
	var/obj/structure/heretic_glass_barrier/barrier = glass.create_barrier(user, middle)
	TEST_ASSERT_NOTNULL(barrier, "Укрытие создаётся между владельцем и целью.")
	TEST_ASSERT(barrier.density, "Укрытие по-прежнему перекрывает движение.")
	TEST_ASSERT(!glass.line_clear(user, victim), "Строительство не получает право проходить через укрытие.")
	TEST_ASSERT(glass.release(user, victim), "Владелец готовит луч сквозь укрытие.")
	var/datum/heretic_glass_attack/attack = glass.attacks[1]
	attack.resolve()
	TEST_ASSERT(abs(victim.getBruteLoss() - 30) <= DAMAGE_PRECISION, "Луч наносит базовый урон за собственным укрытием.")
	var/datum/antagonist/heretic/other_heretic = allocate_heretic(get_step(user, NORTH))
	other_heretic.selected_path = PATH_GLASS
	other_heretic.gain_knowledge(/datum/eldritch_knowledge/base_glass)
	var/datum/eldritch_knowledge/base_glass/other_glass = other_heretic.get_knowledge(/datum/eldritch_knowledge/base_glass)
	TEST_ASSERT(!other_glass.ray_tile_open(middle), "Чужой стекольщик не стреляет через это укрытие.")
	var/obj/obstacle = allocate(/obj, middle)
	obstacle.density = TRUE
	TEST_ASSERT(!glass.ray_tile_open(middle), "Другая плотная преграда на той же клетке продолжает блокировать луч.")

/obj/item/heretic_echo_review_probe
	force = 10
	var/ranged_uses = 0

/obj/item/heretic_echo_review_probe/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	. = ..()
	if(!proximity_flag)
		ranged_uses++

/// Контузия блокирует реальные цепочки атак, сохраняя движение, речь и предмет в руках.
/datum/unit_test/heretic_echo_review_item_control/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_ECHO
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_echo)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/echo_refrain)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_echo/echo = heretic.get_knowledge(/datum/eldritch_knowledge/base_echo)
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	var/mob/living/target = allocate(/mob/living/carbon/human, get_step(victim, EAST))
	var/obj/item/heretic_echo_review_probe/weapon = allocate(/obj/item/heretic_echo_review_probe)
	victim.put_in_hands(weapon)
	victim.a_intent = INTENT_HARM
	TEST_ASSERT(echo.refrain(user, get_turf(victim)), "Припев подготавливает боевую контузию.")
	var/datum/heretic_echo_attack/attack = echo.attacks[1]
	attack.resolve()
	var/datum/status_effect/heretic_echo_dissonance/effect = victim.has_status_effect(/datum/status_effect/heretic_echo_dissonance)
	TEST_ASSERT_NOTNULL(effect, "Два попадания накладывают контузию.")
	TEST_ASSERT(!CHECK_MOBILITY(victim, MOBILITY_USE), "Контузия сразу блокирует применение предметов.")
	TEST_ASSERT(CHECK_MOBILITY(victim, MOBILITY_MOVE | MOBILITY_STAND | MOBILITY_HOLD), "Движение, стойка и удержание предметов доступны.")
	TEST_ASSERT(weapon in victim.held_items, "Контузия не выбивает оружие.")
	TEST_ASSERT(!HAS_TRAIT(victim, TRAIT_MUTE), "Контузия не запрещает речь.")
	var/damage_before = target.getBruteLoss()
	weapon.melee_attack_chain(victim, target, null, NONE)
	weapon.ranged_attack_chain(victim, target, null)
	TEST_ASSERT_EQUAL(target.getBruteLoss(), damage_before, "Обычная цепочка ближней атаки блокируется.")
	TEST_ASSERT_EQUAL(weapon.ranged_uses, 0, "Обычная цепочка дальней атаки не доходит до применения предмета.")
	var/turf/old_place = get_turf(victim)
	step(victim, NORTH)
	TEST_ASSERT(get_turf(victim) != old_place, "Контуженная цель действительно может уйти шагом.")
	TEST_ASSERT(wait_for_qdeleted(effect, max_wait = 3 SECONDS), "Короткая контузия завершается по таймеру.")
	TEST_ASSERT(CHECK_MOBILITY(victim, MOBILITY_USE), "После контузии применение предметов восстанавливается.")
	weapon.melee_attack_chain(victim, target, null, NONE)
	weapon.ranged_attack_chain(victim, target, null)
	TEST_ASSERT(target.getBruteLoss() > damage_before, "После контузии ближняя атака действительно проходит.")
	TEST_ASSERT_EQUAL(weapon.ranged_uses, 1, "После контузии дальняя цепочка снова вызывает предмет.")

/// Контузия уважает защиты Daze и прекращается при удалении источника из обработчика сигнала.
/datum/unit_test/heretic_echo_review_control_guards
	var/datum/antagonist/heretic/role_to_remove

/datum/unit_test/heretic_echo_review_control_guards/proc/block_daze(datum/source)
	SIGNAL_HANDLER
	return COMPONENT_NO_STUN

/datum/unit_test/heretic_echo_review_control_guards/proc/remove_source(datum/source)
	SIGNAL_HANDLER
	var/datum/antagonist/heretic/role = role_to_remove
	role_to_remove = null
	qdel(role)

/datum/unit_test/heretic_echo_review_control_guards/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_ECHO
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_echo)
	var/datum/eldritch_knowledge/base_echo/echo = heretic.get_knowledge(/datum/eldritch_knowledge/base_echo)
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(heretic.owner.current, EAST))
	ADD_TRAIT(victim, TRAIT_MOBILITY_NOUSE, "unrelated_nouse")
	ADD_TRAIT(victim, TRAIT_STUNIMMUNE, "review_protection")
	victim.apply_status_effect(/datum/status_effect/heretic_echo_dissonance, echo)
	TEST_ASSERT(!victim.has_status_effect(/datum/status_effect/heretic_echo_dissonance), "Иммунитет к оглушению блокирует контузию.")
	TEST_ASSERT(HAS_TRAIT(victim, TRAIT_MOBILITY_NOUSE), "Ранний отказ не снимает чужой запрет применения предметов.")
	REMOVE_TRAIT(victim, TRAIT_STUNIMMUNE, "review_protection")
	REMOVE_TRAIT(victim, TRAIT_MOBILITY_NOUSE, "unrelated_nouse")
	var/old_flags = victim.status_flags
	victim.status_flags &= ~CANKNOCKDOWN
	victim.apply_status_effect(/datum/status_effect/heretic_echo_dissonance, echo)
	TEST_ASSERT(!victim.has_status_effect(/datum/status_effect/heretic_echo_dissonance), "Отсутствие CANKNOCKDOWN блокирует контузию.")
	victim.status_flags = old_flags
	victim.add_stun_absorption("review_protection", 1 MINUTES, 1)
	victim.apply_status_effect(/datum/status_effect/heretic_echo_dissonance, echo)
	TEST_ASSERT(!victim.has_status_effect(/datum/status_effect/heretic_echo_dissonance), "Поглощение оглушения блокирует контузию.")
	TEST_ASSERT_EQUAL(victim.stun_absorption["review_protection"]["stuns_absorbed"], 1.5 SECONDS, "Поглощение учитывает настоящую длительность контузии.")
	victim.stun_absorption -= "review_protection"
	RegisterSignal(victim, COMSIG_LIVING_STATUS_DAZE, PROC_REF(block_daze))
	victim.apply_status_effect(/datum/status_effect/heretic_echo_dissonance, echo)
	TEST_ASSERT(!victim.has_status_effect(/datum/status_effect/heretic_echo_dissonance), "Компонент может запретить контузию через сигнал Daze.")
	UnregisterSignal(victim, COMSIG_LIVING_STATUS_DAZE)
	TEST_ASSERT_EQUAL(length(echo.dissonances), 0, "Отклонённые эффекты не остаются в знании.")
	for(var/source_signal in list(COMSIG_LIVING_STATUS_DAZE, SIGNAL_TRAIT(TRAIT_MOBILITY_NOUSE)))
		var/datum/antagonist/heretic/other = allocate_heretic()
		other.selected_path = PATH_ECHO
		other.gain_knowledge(/datum/eldritch_knowledge/base_echo)
		var/datum/eldritch_knowledge/base_echo/other_echo = other.get_knowledge(/datum/eldritch_knowledge/base_echo)
		role_to_remove = other
		RegisterSignal(victim, source_signal, PROC_REF(remove_source))
		victim.apply_status_effect(/datum/status_effect/heretic_echo_dissonance, other_echo)
		UnregisterSignal(victim, source_signal)
		TEST_ASSERT(QDELETED(other), "Обработчик сигнала действительно удаляет источник.")
		TEST_ASSERT(!victim.has_status_effect(/datum/status_effect/heretic_echo_dissonance), "Удаление источника во время применения не оставляет эффект.")
		TEST_ASSERT(!HAS_TRAIT(victim, TRAIT_MOBILITY_NOUSE), "Удаление источника из сигнала не оставляет запрет применения предметов.")
