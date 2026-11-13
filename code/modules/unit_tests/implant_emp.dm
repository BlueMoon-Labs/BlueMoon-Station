/// ЭМИ по имплантам рук: урон конечности, выбивание предметов и выстрел ручной пушки.
/datum/unit_test/implant_emp_arms/Run()
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/obj/item/organ/cyberimp/arm/toolset/implant = allocate(/obj/item/organ/cyberimp/arm/toolset)
	implant.Insert(patient)

	// Обычный имплант занимает одну руку: кладём предмет именно в неё.
	var/obj/item/pen/held = allocate(/obj/item/pen)
	TEST_ASSERT(patient.put_in_hand(held, implant.zone == BODY_ZONE_R_ARM ? 2 : 1), "Не удалось положить предмет в руку с имплантом")
	var/obj/item/bodypart/right_arm = patient.get_bodypart(BODY_ZONE_R_ARM)
	var/obj/item/bodypart/left_arm = patient.get_bodypart(BODY_ZONE_L_ARM)
	var/right_burn_before = right_arm.burn_dam
	var/left_burn_before = left_arm.burn_dam

	implant.emp_act(80)

	TEST_ASSERT(right_arm.burn_dam > right_burn_before, "ЭМИ должен прожигать руку с имплантом")
	TEST_ASSERT_EQUAL(left_arm.burn_dam, left_burn_before, "Однорукий имплант не должен бить по второй руке")
	TEST_ASSERT_NULL(patient.get_item_for_held_index(implant.zone == BODY_ZONE_R_ARM ? 2 : 1), "ЭМИ должен выбить предмет из руки с имплантом")
	TEST_ASSERT(isturf(held.loc), "Выбитый предмет должен лежать на полу")

	// Двуручный имплант бьёт по обеим рукам и выбивает предметы из обеих.
	var/mob/living/carbon/human/dual_patient = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, EAST))
	var/obj/item/organ/cyberimp/arm/mantis_blade/dual = allocate(/obj/item/organ/cyberimp/arm/mantis_blade)
	dual.Insert(dual_patient)
	var/obj/item/pen/left_held = allocate(/obj/item/pen)
	var/obj/item/pen/right_held = allocate(/obj/item/pen)
	TEST_ASSERT(dual_patient.put_in_hand(left_held, 1), "Не удалось положить предмет в левую руку")
	TEST_ASSERT(dual_patient.put_in_hand(right_held, 2), "Не удалось положить предмет в правую руку")
	var/obj/item/bodypart/dual_right = dual_patient.get_bodypart(BODY_ZONE_R_ARM)
	var/obj/item/bodypart/dual_left = dual_patient.get_bodypart(BODY_ZONE_L_ARM)

	dual.emp_act(80)

	TEST_ASSERT(dual_right.burn_dam > 0, "Двуручный имплант должен бить по правой руке")
	TEST_ASSERT(dual_left.burn_dam > 0, "Двуручный имплант должен бить по левой руке")
	TEST_ASSERT_NULL(dual_patient.get_item_for_held_index(1), "ЭМИ должен выбить предмет из левой руки")
	TEST_ASSERT_NULL(dual_patient.get_item_for_held_index(2), "ЭМИ должен выбить предмет из правой руки")

	// Ручная пушка от перегрузки стреляет себе под ноги.
	var/mob/living/carbon/human/gunner = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, WEST))
	var/obj/item/organ/cyberimp/arm/handgun/cannon = allocate(/obj/item/organ/cyberimp/arm/handgun)
	cannon.Insert(gunner)
	var/obj/item/gun/energy/implanthandgun/gun = locate() in cannon.contents
	TEST_ASSERT_NOTNULL(gun, "В импланте ручной пушки нет самой пушки")
	TEST_ASSERT(gun.ready_to_fire, "Пушка должна быть заряжена перед ЭМИ")

	cannon.emp_act(80)
	sleep(0.2 SECONDS)

	TEST_ASSERT(!gun.ready_to_fire, "ЭМИ должен заставить ручную пушку выстрелить")

/// ЭМИ по имплантам ног: урон обеим ногам, дезориентация и самоактивация способностей.
/datum/unit_test/implant_emp_legs/Run()
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/obj/item/organ/cyberimp/leg/tendons/implant = allocate(/obj/item/organ/cyberimp/leg/tendons)
	implant.Insert(patient)
	var/obj/item/bodypart/right_leg = patient.get_bodypart(BODY_ZONE_R_LEG)
	var/obj/item/bodypart/left_leg = patient.get_bodypart(BODY_ZONE_L_LEG)

	implant.emp_act(80)

	TEST_ASSERT(right_leg.burn_dam > 0, "ЭМИ должен бить по правой ноге")
	TEST_ASSERT(left_leg.burn_dam > 0, "ЭМИ должен бить по левой ноге")
	TEST_ASSERT(patient.get_confusion() > 0, "ЭМИ должен дезориентировать носителя")
	TEST_ASSERT(HAS_TRAIT(patient, TRAIT_JUMPING), "Перегруженные сухожилия должны сами запустить прыжок")

	// Гидравлические лодыжки от импульса срабатывают сами и уходят на перезарядку.
	var/mob/living/carbon/human/ankle_patient = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, EAST))
	var/obj/item/organ/cyberimp/leg/ankles/ankles = allocate(/obj/item/organ/cyberimp/leg/ankles)
	ankles.Insert(ankle_patient)
	TEST_ASSERT_EQUAL(ankles.recharging_time, 0, "Лодыжки не должны быть на перезарядке до ЭМИ")

	ankles.emp_act(80)

	TEST_ASSERT(ankles.recharging_time > world.time, "Перегруженные лодыжки должны сами совершить рывок")

/// ЭМИ по подкожной броне: защита пропадает, а вместо неё появляется обратная уязвимость.
/datum/unit_test/implant_emp_subdermal_armor/Run()
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human)
	var/baseline_melee = patient.physiology.armor.melee
	var/baseline_bullet = patient.physiology.armor.bullet
	var/baseline_laser = patient.physiology.armor.laser
	var/baseline_brc = patient.brc_mitigation

	var/obj/item/organ/cyberimp/chest/subdermal_armor/implant = allocate(/obj/item/organ/cyberimp/chest/subdermal_armor)
	implant.emp_disabled_time = 1
	implant.Insert(patient)
	TEST_ASSERT_EQUAL(patient.physiology.armor.melee, baseline_melee + implant.melee_armor_bonus, "Имплант не выдал защиту")

	implant.emp_act(80)

	TEST_ASSERT_EQUAL(patient.physiology.armor.melee, baseline_melee - implant.melee_armor_bonus, "ЭМИ должен заменить защиту обратной уязвимостью")
	TEST_ASSERT_EQUAL(patient.physiology.armor.bullet, baseline_bullet - implant.bullet_armor_bonus, "Уязвимость к пулям должна быть обратной бонусу")
	TEST_ASSERT_EQUAL(patient.physiology.armor.laser, baseline_laser - implant.laser_armor_bonus, "Уязвимость к лазерам должна быть обратной бонусу")
	TEST_ASSERT_EQUAL(patient.brc_mitigation, baseline_brc - implant.brc_mitigation_bonus, "BRC-защита должна стать отрицательной")

	sleep(0.3 SECONDS)
	TEST_ASSERT_EQUAL(patient.physiology.armor.melee, baseline_melee + implant.melee_armor_bonus, "После перезагрузки защита должна вернуться")
	TEST_ASSERT_EQUAL(patient.brc_mitigation, baseline_brc + implant.brc_mitigation_bonus, "После перезагрузки BRC-защита должна вернуться")

	implant.Remove()
	TEST_ASSERT_EQUAL(patient.physiology.armor.melee, baseline_melee, "Снятие импланта должно вернуть исходную защиту")
	TEST_ASSERT_EQUAL(patient.brc_mitigation, baseline_brc, "Снятие импланта должно вернуть исходный BRC")

/// ЭМИ по усиленному скелету: теряется бонус и сверху накладывается штраф в 25 макс. ХП.
/datum/unit_test/implant_emp_reinforced_skeleton/Run()
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human)
	var/baseline_max_health = patient.maxHealth

	var/obj/item/organ/cyberimp/chest/reinforced_skeleton/implant = allocate(/obj/item/organ/cyberimp/chest/reinforced_skeleton)
	implant.emp_disabled_time = 1
	implant.Insert(patient)
	TEST_ASSERT_EQUAL(patient.maxHealth, baseline_max_health + implant.health_bonus, "Имплант не выдал добавочное здоровье")

	implant.emp_act(80)

	TEST_ASSERT_EQUAL(patient.maxHealth, baseline_max_health - implant.emp_health_penalty, "ЭМИ должен убрать бонус и добавить штраф в 25 ХП")

	sleep(0.3 SECONDS)
	TEST_ASSERT_EQUAL(patient.maxHealth, baseline_max_health + implant.health_bonus, "После перезарядки бонус должен вернуться")

	implant.Remove()
	TEST_ASSERT_EQUAL(patient.maxHealth, baseline_max_health, "Снятие импланта должно вернуть исходный максимум ХП")

/// ЭМИ по берсерку: четверть мозга, сброс заряда, остановка режима и защита до перезарядки.
/datum/unit_test/implant_emp_berserker/Run()
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human)
	var/obj/item/organ/cyberimp/brain/berserker/implant = allocate(/obj/item/organ/cyberimp/brain/berserker)
	implant.Insert(patient)
	implant.activate_berserk()
	TEST_ASSERT(implant.active, "Берсерк должен был активироваться")

	var/obj/item/organ/brain/brain = patient.getorganslot(ORGAN_SLOT_BRAIN)
	TEST_ASSERT_NOTNULL(brain, "У пациента нет мозга")

	implant.emp_act(80)

	TEST_ASSERT_EQUAL(patient.getOrganLoss(ORGAN_SLOT_BRAIN), brain.maxHealth * 0.25, "ЭМИ должен нанести 25% урона по мозгу")
	TEST_ASSERT(!implant.active, "ЭМИ должен завершить активный берсерк")
	TEST_ASSERT(implant.cooldown_end >= world.time + implant.cooldown_time, "ЭМИ должен полностью сбросить заряд берсерка")
	TEST_ASSERT(implant.emp_shielded, "После ЭМИ имплант должен получить защиту до перезарядки")

	// Повторный ЭМИ по защищённому импланту не должен снова бить по мозгу.
	var/brain_damage_after_first = patient.getOrganLoss(ORGAN_SLOT_BRAIN)
	TEST_ASSERT(implant.emp_act(80) & EMP_PROTECT_SELF, "Защищённый берсерк должен сообщать о защите от ЭМИ")
	TEST_ASSERT_EQUAL(patient.getOrganLoss(ORGAN_SLOT_BRAIN), brain_damage_after_first, "Защита должна блокировать повторный урон по мозгу")

	implant.Remove()
	TEST_ASSERT(!implant.emp_shielded, "При извлечении защита от ЭМИ должна сниматься")
