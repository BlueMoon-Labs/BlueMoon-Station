/// ЭМИ жжёт и оглушает HK-50 по шкале severity, а оглушение останавливает его ИИ.
/datum/unit_test/hk50_emp

/datum/unit_test/hk50_emp/Run()
	var/mob/living/simple_animal/hostile/hk50/droid = allocate(/mob/living/simple_animal/hostile/hk50)
	droid.emp_act(HK50_EMP_HEAVY_SEVERITY)
	TEST_ASSERT_EQUAL(droid.health, droid.maxHealth - HK50_EMP_HEAVY_BURN, "Сильный ЭМИ нанёс HK-50 не тот ожог")
	TEST_ASSERT(droid.IsStun(), "Сильный ЭМИ не оглушил HK-50")
	TEST_ASSERT_EQUAL(round(droid.AmountStun(), 0.1), HK50_EMP_HEAVY_STUN, "Сильный ЭМИ оглушил HK-50 не на тот срок")
	TEST_ASSERT_NOTNULL(droid.ai_controller, "У HK-50 нет ИИ-контроллера")
	TEST_ASSERT(!droid.ai_controller.able_to_run, "ИИ оглушённого HK-50 продолжает действовать")

	var/mob/living/simple_animal/hostile/hk50/other = allocate(/mob/living/simple_animal/hostile/hk50)
	other.emp_act(HK50_EMP_HEAVY_SEVERITY - 1)
	TEST_ASSERT_EQUAL(other.health, other.maxHealth - HK50_EMP_LIGHT_BURN, "Слабый ЭМИ нанёс HK-50 не тот ожог")
	TEST_ASSERT_EQUAL(round(other.AmountStun(), 0.1), HK50_EMP_LIGHT_STUN, "Слабый ЭМИ оглушил HK-50 не на тот срок")

/// Гибель HK-50 оставляет лом и обломки, а не корпус, и не ранит стоящих рядом.
/datum/unit_test/hk50_death_scrap

/datum/unit_test/hk50_death_scrap/Run()
	var/mob/living/simple_animal/hostile/hk50/droid = allocate(/mob/living/simple_animal/hostile/hk50)
	var/mob/living/carbon/human/bystander = allocate(/mob/living/carbon/human)
	var/turf/spot = get_turf(droid)
	droid.death()
	TEST_ASSERT(QDELETED(droid), "Корпус HK-50 остался после гибели")
	TEST_ASSERT_NOTNULL(locate(/obj/effect/decal/cleanable/robot_debris/hk50) in spot, "После HK-50 не осталось обломков")
	TEST_ASSERT_NOTNULL(locate(/obj/item/stack/sheet/metal) in spot, "После HK-50 не остался металлолом")
	TEST_ASSERT_EQUAL(bystander.getBruteLoss() + bystander.getFireLoss(), 0, "Гибель HK-50 ранила стоящего рядом")

/// Глаза HK-50 светятся эмиссивом, пока он жив.
/datum/unit_test/hk50_eyes_glow

/datum/unit_test/hk50_eyes_glow/Run()
	var/mob/living/simple_animal/hostile/hk50/droid = allocate(/mob/living/simple_animal/hostile/hk50)
	TEST_ASSERT(hk50_has_eye_glow(droid.update_overlays()), "Глаза живого HK-50 не светятся")
	droid.del_on_death = FALSE
	droid.death()
	TEST_ASSERT(!hk50_has_eye_glow(droid.update_overlays()), "Глаза погибшего HK-50 светятся")

/datum/unit_test/hk50_eyes_glow/proc/hk50_has_eye_glow(list/overlays)
	for(var/mutable_appearance/overlay as anything in overlays)
		if(overlay.icon_state == "hk50_eyes" && PLANE_TO_TRUE(overlay.plane) == EMISSIVE_PLANE)
			return TRUE
	return FALSE

/// Реплики HK-50 идут не чаще кулдауна, кроме обязательных.
/datum/unit_test/hk50_line_cooldown

/datum/unit_test/hk50_line_cooldown/Run()
	var/mob/living/simple_animal/hostile/hk50/droid = allocate(/mob/living/simple_animal/hostile/hk50)
	TEST_ASSERT(droid.hk50_say("цель обнаружена."), "Первая реплика HK-50 не прозвучала")
	TEST_ASSERT(!droid.hk50_say("цель обнаружена."), "Реплика HK-50 прозвучала в кулдаун")
	TEST_ASSERT(droid.hk50_say("ошибка.", forced = TRUE), "Обязательная реплика HK-50 упёрлась в кулдаун")

/// Зелье разума не делает из HK-50 питомца, а речь у него русская.
/datum/unit_test/hk50_artificial

/datum/unit_test/hk50_artificial/Run()
	var/mob/living/simple_animal/hostile/hk50/droid = allocate(/mob/living/simple_animal/hostile/hk50)
	TEST_ASSERT_EQUAL(droid.sentience_type, SENTIENCE_ARTIFICIAL, "HK-50 - органика для зелья разума")
	TEST_ASSERT_EQUAL(droid.speak_emote[1], "констатирует", "HK-50 говорит не по-русски")

/// Фотоприёмники с обломков HK-50 выпадают с шансом, только у NPC, и это кибер-глаза со светофильтром.
/datum/unit_test/hk50_photoreceptors

/datum/unit_test/hk50_photoreceptors/Run()
	var/mob/living/simple_animal/hostile/hk50/lucky = allocate(/mob/living/simple_animal/hostile/hk50, run_loc_floor_bottom_left)
	lucky.photoreceptor_chance = 100
	lucky.death()
	var/obj/item/organ/eyes/robotic/hk50/eyes = locate() in run_loc_floor_bottom_left
	TEST_ASSERT_NOTNULL(eyes, "Уцелевшие фотоприёмники не выпали")
	allocated += eyes
	TEST_ASSERT_EQUAL(eyes.flash_protect, 1, "Фотоприёмники HK-50 не защищают от вспышек")

	var/turf/other_spot = run_loc_floor_top_right
	var/mob/living/simple_animal/hostile/hk50/unlucky = allocate(/mob/living/simple_animal/hostile/hk50, other_spot)
	unlucky.photoreceptor_chance = 0
	unlucky.death()
	TEST_ASSERT_NULL(locate(/obj/item/organ/eyes/robotic/hk50) in other_spot, "Фотоприёмники выпали без шанса")

	var/mob/living/carbon/human/master = allocate(/mob/living/carbon/human, other_spot)
	var/mob/living/simple_animal/hostile/hk50/servant = allocate(/mob/living/simple_animal/hostile/hk50, other_spot)
	servant.AddComponent(/datum/component/hk50_servant, master)
	servant.photoreceptor_chance = 100
	servant.death()
	TEST_ASSERT_NULL(locate(/obj/item/organ/eyes/robotic/hk50) in other_spot, "Слуга HK-47 оставил фотоприёмники")

/// HK-50 фабрики и её турели не трогают шасси серии HK, а слуга по приказу и учебный HK-50 стреляют и по ним.
/datum/unit_test/hk50_series_kinship

/datum/unit_test/hk50_series_kinship/Run()
	var/mob/living/simple_animal/hostile/hk50/factory_guard/guard = allocate(/mob/living/simple_animal/hostile/hk50/factory_guard)
	var/mob/living/carbon/human/stranger = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/kin = allocate(/mob/living/carbon/human)
	kin.set_species(/datum/species/ipc/hk/hk51)
	TEST_ASSERT(guard.CanAttack(stranger), "Страж фабрики не трогает чужака")
	TEST_ASSERT(!guard.CanAttack(kin), "Страж фабрики готов стрелять по шасси HK")
	var/mob/living/simple_animal/hostile/hk50/sparring = allocate(/mob/living/simple_animal/hostile/hk50)
	TEST_ASSERT(sparring.CanAttack(kin), "HK-50 вне фабрики щадит шасси HK - учебный бой с HK-47 сломан")

	var/obj/machinery/porta_turret/syndicate/energy/hk_factory/turret = allocate(/obj/machinery/porta_turret/syndicate/energy/hk_factory)
	TEST_ASSERT(turret.in_faction(kin), "Турель фабрики не считает шасси HK своим")
	TEST_ASSERT(!turret.in_faction(stranger), "Турель фабрики считает чужака своим")

	var/mob/living/carbon/human/master = allocate(/mob/living/carbon/human)
	var/mob/living/simple_animal/hostile/hk50/servant = allocate(/mob/living/simple_animal/hostile/hk50)
	servant.AddComponent(/datum/component/hk50_servant, master)
	master.a_intent = INTENT_HARM
	master.pointed(kin)
	TEST_ASSERT(servant.CanAttack(kin), "Слуга не выполняет приказ против HK-51")

/// Голос HK-50 молчит хором только на своём уровне: соседний уровень слышит своих.
/datum/unit_test/hk50_voice_per_level

/datum/unit_test/hk50_voice_per_level/Run()
	var/mob/living/simple_animal/hostile/hk50/droid = allocate(/mob/living/simple_animal/hostile/hk50)
	var/level = "[droid.z]"
	var/other_level = "[droid.z + 1]"
	GLOB.hk50_voice_quiet_until -= list(level, other_level)
	TEST_ASSERT(droid.hk50_voice("hk50_foolish"), "Первая строка HK-50 не прозвучала")
	TEST_ASSERT(GLOB.hk50_voice_quiet_until[level] > world.time, "Строка HK-50 не заглушила свой уровень")
	TEST_ASSERT_NULL(GLOB.hk50_voice_quiet_until[other_level], "Строка HK-50 заглушила чужой уровень")
	GLOB.hk50_voice_quiet_until -= level

/// Самоликвидация обходится без предсмертной строки, обычная гибель - с ней.
/datum/unit_test/hk50_silent_death

/datum/unit_test/hk50_silent_death/Run()
	var/mob/living/simple_animal/hostile/hk50/loud = allocate(/mob/living/simple_animal/hostile/hk50)
	loud.del_on_death = FALSE
	loud.next_line_time = 0
	loud.death()
	TEST_ASSERT(loud.next_line_time > 0, "Гибель HK-50 прошла без строки")

	var/mob/living/simple_animal/hostile/hk50/quiet = allocate(/mob/living/simple_animal/hostile/hk50)
	quiet.del_on_death = FALSE
	quiet.next_line_time = 0
	quiet.silent_death = TRUE
	quiet.death()
	TEST_ASSERT_EQUAL(quiet.next_line_time, 0, "Самоликвидированный HK-50 крикнул про фотоприёмники")
