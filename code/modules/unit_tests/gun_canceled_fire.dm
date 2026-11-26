/// Отменённый выстрел (заговор Свинца) не оставляет в патроннике разогнанную пулю и не даёт последствий выстрела.
/datum/unit_test/gun_canceled_fire
	var/list/fired_types = list()

/datum/unit_test/gun_canceled_fire/proc/cancel_fire(obj/item/gun/source, mob/living/user, atom/target)
	SIGNAL_HANDLER
	return COMPONENT_CANCEL_GUN_FIRE

/datum/unit_test/gun_canceled_fire/proc/on_gun_fired(datum/source, obj/item/gun/gun, mob/living/user, atom/target, projectile_type)
	SIGNAL_HANDLER
	fired_types += projectile_type

/datum/unit_test/gun_canceled_fire/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, EAST))
	var/obj/item/gun/ballistic/automatic/pistol/gun = allocate(/obj/item/gun/ballistic/automatic/pistol)
	TEST_ASSERT(user.put_in_hands(gun), "Стрелок берёт пистолет.")
	var/obj/item/projectile/shot = gun.chambered?.BB
	TEST_ASSERT_NOTNULL(shot, "В патроннике есть пуля.")
	var/base_damage = shot.damage
	var/base_wound_bonus = shot.wound_bonus
	RegisterSignal(gun, COMSIG_GUN_TRY_FIRE, PROC_REF(cancel_fire))
	RegisterSignal(SSdcs, COMSIG_GLOB_GUN_FIRED, PROC_REF(on_gun_fired))

	var/execution = gun.handle_suicide(user, target, null, TRUE)
	TEST_ASSERT(!execution, "Отменённый выстрел в голову не считается выстрелом.")
	TEST_ASSERT_EQUAL(gun.chambered?.BB, shot, "Пуля осталась в патроннике.")
	TEST_ASSERT_EQUAL(shot.damage, base_damage, "Отменённый выстрел в голову не оставляет пуле десятикратный урон.")
	gun.handle_suicide(user, target, null, TRUE)
	TEST_ASSERT_EQUAL(shot.damage, base_damage, "Вторая отмена тоже не разгоняет пулю.")
	TEST_ASSERT_EQUAL(shot.wound_bonus, base_wound_bonus, "Ранящая сила пули не меняется.")
	TEST_ASSERT(!gun.blow_up(user), "Отменённый самопроизвольный выстрел не прерывает распил.")

	var/obj/item/organ/brain/brain = user.getorganslot(ORGAN_SLOT_BRAIN)
	gun.suicide_act(user)
	TEST_ASSERT_EQUAL(user.getorganslot(ORGAN_SLOT_BRAIN), brain, "Без выстрела мозг остаётся на месте.")
	TEST_ASSERT_EQUAL(length(fired_types), 0, "Отменённые выстрелы не слышны как выстрелы.")

	UnregisterSignal(gun, COMSIG_GUN_TRY_FIRE)
	var/fired_type = shot.type
	TEST_ASSERT(gun.handle_suicide(user, target, null, TRUE), "Без отмены выстрел в голову проходит.")
	TEST_ASSERT(gun.chambered?.BB != shot, "Выстреленная пуля покинула патронник.")
	TEST_ASSERT_EQUAL(length(fired_types), 1, "Выстрел слышен один раз.")
	TEST_ASSERT_EQUAL(fired_types[1], fired_type, "Сигнал выстрела называет тип пули.")
	UnregisterSignal(SSdcs, COMSIG_GLOB_GUN_FIRED)

/// Переопределённый выстрел отдаёт результат родителя: револьвер детектива стреляет в голову, а не оставляет стрелка давиться.
/datum/unit_test/gun_override_fire_result/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, EAST))
	var/obj/item/gun/ballistic/revolver/detective/gun = allocate(/obj/item/gun/ballistic/revolver/detective)
	TEST_ASSERT(user.put_in_hands(gun), "Стрелок берёт револьвер детектива.")
	TEST_ASSERT_NOTNULL(gun.chambered?.BB, "Под бойком есть пуля.")
	TEST_ASSERT(gun.handle_suicide(user, target, null, TRUE), "Выстрел в голову из револьвера детектива засчитан.")

	var/mob/living/carbon/human/suicider = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, NORTH))
	var/obj/item/gun/ballistic/revolver/detective/own_gun = allocate(/obj/item/gun/ballistic/revolver/detective)
	TEST_ASSERT(suicider.put_in_hands(own_gun), "Второй стрелок берёт свой револьвер.")
	TEST_ASSERT_EQUAL(own_gun.suicide_act(suicider), BRUTELOSS, "Выстрел в рот считается выстрелом, а не удушьем.")
