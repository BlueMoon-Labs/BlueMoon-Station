/// Яд вдовы ужаса держит зрение размытым, пока он в крови, а после выведения размытие сходит само.
/datum/unit_test/terror_venom_blur_wears_off

/datum/unit_test/terror_venom_blur_wears_off/Run()
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	victim.reagents.add_reagent(/datum/reagent/terror_black_toxin, 33)
	var/datum/reagent/terror_black_toxin/venom = victim.reagents.has_reagent(/datum/reagent/terror_black_toxin)
	TEST_ASSERT_NOTNULL(venom, "Предпосылка: яд вдовы попал в кровь.")
	for(var/tick in 1 to 30)
		venom.on_mob_life(victim)
		victim.handle_traits()
	TEST_ASSERT(victim.eye_blurry > 0, "Яд вдовы не размывает зрение.")
	TEST_ASSERT(victim.eye_blurry <= BLUR_TICKS(TERROR_VENOM_BLUR_LIGHT), "Размытие от одного укуса копится тик за тиком: [victim.eye_blurry] тиков.")

	victim.reagents.del_reagent(/datum/reagent/terror_black_toxin)
	for(var/tick in 1 to BLUR_TICKS(TERROR_VENOM_BLUR_HEAVY))
		victim.handle_traits()
	TEST_ASSERT_EQUAL(victim.eye_blurry, 0, "Размытие не сходит после выведения яда.")

/// Укусы и паутина лекаря ужаса не копят размытие выше потолка, и у синтетика тоже.
/datum/unit_test/terror_healer_blur_capped

/datum/unit_test/terror_healer_blur_capped/Run()
	var/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/healer/healer = allocate(/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/healer, run_loc_floor_bottom_left)
	var/obj/structure/spider/terrorweb/green/web = allocate(/obj/structure/spider/terrorweb/green, run_loc_floor_top_right)
	for(var/robotic in list(FALSE, TRUE))
		var/label = robotic ? "синтетик" : "органик"
		var/mob/living/carbon/human/bitten = allocate(/mob/living/carbon/human, get_step(healer, EAST))
		if(robotic)
			ADD_TRAIT(bitten, TRAIT_ROBOTIC_ORGANISM, TRAIT_GENERIC)
		for(var/bite in 1 to 10)
			healer.spider_specialattack(bitten, TRUE)
		TEST_ASSERT(bitten.eye_blurry > 0, "[label]: укус лекаря не размывает зрение.")
		TEST_ASSERT(bitten.eye_blurry <= BLUR_TICKS(TERROR_HEALER_BLUR_CAP), "[label]: десять укусов лекаря копят [bitten.eye_blurry] тиков размытия.")

		var/mob/living/carbon/human/tangled = allocate(/mob/living/carbon/human, get_step(web, WEST))
		if(robotic)
			ADD_TRAIT(tangled, TRAIT_ROBOTIC_ORGANISM, TRAIT_GENERIC)
		for(var/touch in 1 to 10)
			web.web_special_ability(tangled)
		TEST_ASSERT(tangled.eye_blurry > 0, "[label]: слизистая паутина не размывает зрение.")
		TEST_ASSERT(tangled.eye_blurry <= BLUR_TICKS(TERROR_WEB_BLUR_CAP), "[label]: паутина копит [tangled.eye_blurry] тиков размытия.")

/// Новые глаза и ремонт глаз снимают размытие от пауков и у органика, и у синтетика.
/datum/unit_test/terror_blur_cured_by_eyes

/datum/unit_test/terror_blur_cured_by_eyes/Run()
	var/mob/living/carbon/human/surgeon = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	for(var/robotic in list(FALSE, TRUE))
		var/label = robotic ? "синтетик" : "органик"
		var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
		if(robotic)
			ADD_TRAIT(patient, TRAIT_ROBOTIC_ORGANISM, TRAIT_GENERIC)
		patient.set_blurriness(BLUR_TICKS(TERROR_HEALER_BLUR_CAP) * 10)
		var/obj/item/organ/eyes/old_eyes = patient.getorganslot(ORGAN_SLOT_EYES)
		TEST_ASSERT_NOTNULL(old_eyes, "Предпосылка: у пациента есть глаза.")
		old_eyes.Remove()
		qdel(old_eyes)
		var/eyes_type = robotic ? /obj/item/organ/eyes/robotic : /obj/item/organ/eyes
		var/obj/item/organ/eyes/fresh_eyes = new eyes_type()
		fresh_eyes.Insert(patient)
		TEST_ASSERT_EQUAL(patient.eye_blurry, 0, "[label]: пересаженные глаза видят размыто.")

		patient.set_blurriness(BLUR_TICKS(TERROR_HEALER_BLUR_CAP) * 10)
		var/datum/surgery_step/repair = robotic ? new /datum/surgery_step/fix_cameras : new /datum/surgery_step/fix_eyes
		repair.success(surgeon, patient, BODY_ZONE_PRECISE_EYES, null, null)
		qdel(repair)
		TEST_ASSERT(patient.eye_blurry < BLUR_TICKS(TERROR_HEALER_BLUR_CAP), "[label]: ремонт глаз оставил [patient.eye_blurry] тиков размытия.")

/// Плевок дрона ужаса - кислота: жжёт, режется кислотной бронёй и не замечает пулевой.
/datum/unit_test/terror_drone_spit_is_acid

/datum/unit_test/terror_drone_spit_is_acid/Run()
	var/mob/living/carbon/human/shooter = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	var/mob/living/carbon/human/bare = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/bulletproof = allocate(/mob/living/carbon/human, get_step(bare, EAST))
	var/mob/living/carbon/human/acidproof = allocate(/mob/living/carbon/human, get_step(bare, NORTH))
	dress_drone_spit_target(bulletproof, getArmor(bullet = 100))
	dress_drone_spit_target(acidproof, getArmor(acid = 50))

	for(var/mob/living/carbon/human/target as anything in list(bare, bulletproof, acidproof))
		var/obj/item/projectile/terrorspider/builder/spit = allocate(/obj/item/projectile/terrorspider/builder, get_turf(shooter))
		spit.firer = shooter
		spit.starting = get_turf(shooter)
		spit.setAngle(Get_Angle(get_turf(shooter), get_turf(target)))
		target.bullet_act(spit, BODY_ZONE_CHEST)

	TEST_ASSERT(bare.getFireLoss() > 0, "Плевок дрона не обжигает.")
	TEST_ASSERT_EQUAL(bare.getBruteLoss(), 0, "Плевок дрона бьёт как пуля.")
	TEST_ASSERT_EQUAL(bare.getToxLoss(), 0, "Плевок дрона травит вместо ожога.")
	TEST_ASSERT_EQUAL(bulletproof.getFireLoss(), bare.getFireLoss(), "Пулевая броня держит кислотный плевок.")
	TEST_ASSERT(acidproof.getFireLoss() < bare.getFireLoss(), "Кислотная броня не держит плевок дрона.")
	TEST_ASSERT(bare.IsSlowed(), "Плевок дрона не замедляет.")

/datum/unit_test/terror_drone_spit_is_acid/proc/dress_drone_spit_target(mob/living/carbon/human/target, datum/armor/armor)
	var/obj/item/clothing/suit/armor/vest/vest = allocate(/obj/item/clothing/suit/armor/vest)
	vest.armor = armor
	TEST_ASSERT(target.equip_to_slot_if_possible(vest, ITEM_SLOT_OCLOTHING), "Предпосылка: жилет надет.")

/// Кислотой режется только плевок дрона: остальные паучьи плевки бьют по пулевой броне, и окна от них бьются.
/datum/unit_test/terror_spit_armor_flags

/datum/unit_test/terror_spit_armor_flags/Run()
	for(var/obj/item/projectile/terrorspider/spit_type as anything in typesof(/obj/item/projectile/terrorspider))
		var/expected = ispath(spit_type, /obj/item/projectile/terrorspider/builder) ? ACID : BULLET
		TEST_ASSERT_EQUAL(initial(spit_type.flag), expected, "[spit_type] режется не той бронёй.")
	var/obj/item/projectile/terrorspider/queen/queen_spit_type = /obj/item/projectile/terrorspider/queen
	TEST_ASSERT_EQUAL(initial(queen_spit_type.damage_type), BURN, "Плевок королевы сменил тип урона.")

	var/obj/structure/window/window = allocate(/obj/structure/window, run_loc_floor_bottom_left)
	var/obj/item/projectile/terrorspider/queen/queen_spit = allocate(/obj/item/projectile/terrorspider/queen, run_loc_floor_top_right)
	window.bullet_act(queen_spit)
	TEST_ASSERT(QDELETED(window) || window.obj_integrity < window.max_integrity, "Окно не замечает плевка королевы.")

/// Плевок Императрицы - паучий снаряд: пролетает сквозь своих пауков и не ранит их.
/datum/unit_test/terror_empress_spit_spares_spiders

/datum/unit_test/terror_empress_spit_spares_spiders/Run()
	var/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/queen/empress/empress_type = /mob/living/simple_animal/hostile/retaliate/poison/terror_spider/queen/empress
	var/spit_type = initial(empress_type.projectiletype)
	TEST_ASSERT(ispath(spit_type, /obj/item/projectile/terrorspider/queen), "Императрица плюётся не паучьим снарядом: [spit_type].")
	var/obj/item/projectile/terrorspider/spit = allocate(spit_type, run_loc_floor_bottom_left)
	TEST_ASSERT_EQUAL(spit.damage, 90, "Плевок Императрицы потерял урон.")
	var/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/builder/ally = allocate(/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/builder, run_loc_floor_top_right)
	TEST_ASSERT(ally.CanPass(spit, get_turf(ally)), "Плевок Императрицы упирается в своего паука.")
	var/ally_health = ally.health
	spit.process_hit(get_turf(ally), ally)
	TEST_ASSERT_EQUAL(ally.health, ally_health, "Плевок Императрицы ранит своего паука.")
	TEST_ASSERT(QDELETED(spit), "Плевок Императрицы не гаснет о своего паука.")
