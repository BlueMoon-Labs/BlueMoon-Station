/// Тесты переиспользуемых элементов мобов (порт tgstation: death_drops, pet_bonus,
/// relay_attackers + ai_retaliate). Проверяют сигнальные цепочки на живых мобах.

/// death_drops: моб с элементом умирает - лут появляется на турфе.
/datum/unit_test/element_death_drops

/datum/unit_test/element_death_drops/Run()
	// Обычная смерть: лут на турфе, ассоциативный счётчик работает
	var/mob/living/simple_animal/subject = allocate(/mob/living/simple_animal)
	subject.AddElement(/datum/element/death_drops, list(/obj/item/pen = 2))
	subject.death()
	var/pens_found = 0
	for(var/obj/item/pen/dropped in run_loc_floor_bottom_left)
		pens_found++
	TEST_ASSERT_EQUAL(pens_found, 2, "death_drops не заспавнил лут по счётчику: ожидалось 2 ручки, найдено [pens_found]")

	// no_gib_drops: при гибе лут не спавнится
	var/mob/living/simple_animal/gibbed_subject = allocate(/mob/living/simple_animal, run_loc_floor_top_right)
	gibbed_subject.AddElement(/datum/element/death_drops, list(/obj/item/flashlight), TRUE)
	gibbed_subject.death(TRUE)
	var/obj/item/flashlight/gib_loot = locate() in run_loc_floor_top_right
	TEST_ASSERT_NULL(gib_loot, "death_drops с no_gib_drops заспавнил лут при гибе")

/// pet_bonus: help-клик по питомцу - счастливая эмоция, сердечко и мудлет гладящему.
/datum/unit_test/element_pet_bonus
	var/emotes_seen = 0
	var/pets_seen = 0
	var/moodlets_seen = 0

/datum/unit_test/element_pet_bonus/Run()
	var/mob/living/simple_animal/pet = allocate(/mob/living/simple_animal)
	var/mob/living/carbon/human/petter = allocate(/mob/living/carbon/human)
	pet.AddElement(/datum/element/pet_bonus, "радостно виляет хвостом!", EMOTE_VISIBLE)
	RegisterSignal(pet, COMSIG_MOB_EMOTE, PROC_REF(count_emote))
	RegisterSignal(pet, COMSIG_ANIMAL_PET, PROC_REF(count_pet))
	RegisterSignal(petter, COMSIG_ADD_MOOD_EVENT, PROC_REF(count_moodlet))

	petter.a_intent = INTENT_HELP
	pet.attack_hand(petter)
	// эффекты поглаживания отложены элементом на addtimer: ждём проход SStimer,
	// а не фиксированные два деци - под нагрузкой раннера колбэк в них не влезал
	wait_for_var(src, NAMEOF(src, pets_seen), 1)
	TEST_ASSERT_EQUAL(pets_seen, 1, "pet_bonus не отправил COMSIG_ANIMAL_PET при help-клике")
	TEST_ASSERT_EQUAL(emotes_seen, 1, "pet_bonus не заставил питомца сделать счастливую эмоцию")
	TEST_ASSERT_EQUAL(moodlets_seen, 1, "pet_bonus не выдал мудлет гладящему")
	var/obj/effect/temp_visual/heart/heart = locate() in get_turf(pet)
	TEST_ASSERT_NOTNULL(heart, "pet_bonus не заспавнил сердечко над питомцем")

	// Харм-интент бонуса давать не должен
	petter.a_intent = INTENT_HARM
	pet.attack_hand(petter)
	sleep(2)
	TEST_ASSERT_EQUAL(pets_seen, 1, "pet_bonus сработал на харм-интент")

/datum/unit_test/element_pet_bonus/proc/count_emote(datum/source)
	SIGNAL_HANDLER
	emotes_seen++

/datum/unit_test/element_pet_bonus/proc/count_pet(datum/source)
	SIGNAL_HANDLER
	pets_seen++

/datum/unit_test/element_pet_bonus/proc/count_moodlet(datum/source)
	SIGNAL_HANDLER
	moodlets_seen++

/// relay_attackers + ai_retaliate: удар по мобу - единый сигнал атаки
/// и атакующий в blackboard-реестре обидчиков.
/datum/unit_test/element_ai_retaliate
	var/attacks_relayed = 0
	var/last_attack_flags

/datum/unit_test/element_ai_retaliate/Run()
	var/mob/living/simple_animal/victim = allocate(/mob/living/simple_animal)
	var/mob/living/carbon/human/attacker = allocate(/mob/living/carbon/human)
	victim.AddElement(/datum/element/ai_retaliate)
	var/datum/ai_controller/controller = allocate(/datum/ai_controller, victim)
	RegisterSignal(victim, COMSIG_ATOM_WAS_ATTACKED, PROC_REF(count_attack))

	// Безоружный удар в харм-интенте релеится как урон
	attacker.a_intent = INTENT_HARM
	victim.attack_hand(attacker)
	TEST_ASSERT_EQUAL(attacks_relayed, 1, "relay_attackers не срелеил безоружный харм-удар")
	TEST_ASSERT(last_attack_flags & ATTACKER_DAMAGING_ATTACK, "харм-удар рукой не помечен как наносящий урон")

	// Help-интент атакой не считается
	attacker.a_intent = INTENT_HELP
	victim.attack_hand(attacker)
	TEST_ASSERT_EQUAL(attacks_relayed, 1, "relay_attackers посчитал help-клик атакой")

	// Обидчик попал в blackboard-реестр ai_retaliate
	var/list/enemies = controller.blackboard[BB_BASIC_MOB_RETALIATE_LIST]
	TEST_ASSERT(islist(enemies), "ai_retaliate не создал реестр обидчиков в blackboard")
	TEST_ASSERT(enemies[attacker], "ai_retaliate не записал атакующего в реестр обидчиков")

	// Удар предметом с force тоже релеится
	var/obj/item/kitchen/knife/weapon = allocate(/obj/item/kitchen/knife)
	attacker.a_intent = INTENT_HARM
	victim.attackby(weapon, attacker, null)
	TEST_ASSERT_EQUAL(attacks_relayed, 2, "relay_attackers не срелеил удар предметом с force")

/datum/unit_test/element_ai_retaliate/proc/count_attack(datum/source, atom/attacker, attack_flags)
	SIGNAL_HANDLER
	attacks_relayed++
	last_attack_flags = attack_flags
