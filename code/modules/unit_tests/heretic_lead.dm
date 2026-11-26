/// Пуля экипажа, которую дальше ведёт её собственный process(), как в игре.
/datum/unit_test/proc/heretic_lead_test_bullet(mob/living/shooter, atom/target, projectile_type = /obj/item/projectile/bullet, damage = 5)
	var/obj/item/projectile/projectile = new projectile_type(get_turf(shooter))
	projectile.firer = shooter
	projectile.fired_from = shooter
	projectile.damage = damage
	projectile.preparePixelProjectile(target, shooter)
	return projectile

/datum/unit_test/proc/heretic_lead_test_fly(obj/item/projectile/projectile, seconds = 1)
	for(var/step in 1 to 20)
		if(QDELETED(projectile))
			return
		projectile.process(seconds / 20)

/// Выстрел по соседней цели попадает в упор сразу, дальняя пуля долетает своим ходом.
/datum/unit_test/proc/heretic_lead_test_shot(mob/living/shooter, mob/living/target, projectile_type = /obj/item/projectile/bullet, damage = 5)
	var/obj/item/projectile/projectile = heretic_lead_test_bullet(shooter, target, projectile_type, damage)
	projectile.fire(null, target)
	heretic_lead_test_fly(projectile)
	return projectile

/datum/unit_test/proc/heretic_lead_test_spot(dx, dy)
	return locate(run_loc_floor_bottom_left.x + dx, run_loc_floor_bottom_left.y + dy, run_loc_floor_bottom_left.z)

/datum/unit_test/proc/heretic_lead_test_wait(datum/callback/condition, max_wait = 3 SECONDS, description = "условие Свинца")
	var/list/budget = new_wait_budget(max_wait, description)
	while(!condition.Invoke())
		if(!wait_budget_tick(budget))
			return FALSE
	return TRUE

/datum/unit_test/proc/heretic_lead_test_crew(turf/spot, role)
	var/mob/living/carbon/human/crew = allocate(/mob/living/carbon/human, spot)
	crew.mind_initialize()
	if(role)
		crew.mind.assigned_role = role
	return crew

/proc/heretic_lead_test_brute_at_least(mob/living/victim, amount)
	return victim.getBruteLoss() >= amount

/// Пули и дробь в еретика и рядом с ним дают Свинец; лазеры, свои и частые попадания - нет.
/datum/unit_test/heretic_lead_bullets_feed/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_LEAD)
	var/mob/living/carbon/human/user = heretic.owner.current
	user.forceMove(heretic_lead_test_spot(2, 1))
	var/datum/eldritch_knowledge/base_lead/lead = heretic.get_knowledge(/datum/eldritch_knowledge/base_lead)
	TEST_ASSERT_EQUAL(lead.combat_resource, 2, "Свинец начинается с двух.")
	TEST_ASSERT_EQUAL(lead.combat_resource_max, HERETIC_LEAD_CAPACITY, "В барабане шесть камор.")
	var/mob/living/carbon/human/gunner = allocate(/mob/living/carbon/human, heretic_lead_test_spot(0, 0))
	var/obj/item/projectile/laser = heretic_lead_test_bullet(gunner, heretic_lead_test_spot(5, 0), /obj/item/projectile/beam/laser)
	laser.fire()
	heretic_lead_test_fly(laser)
	TEST_ASSERT_EQUAL(lead.combat_resource, 2, "Лазер мимо Свинца не даёт.")
	var/obj/item/projectile/miss = heretic_lead_test_bullet(gunner, heretic_lead_test_spot(5, 0))
	miss.fire()
	heretic_lead_test_fly(miss)
	TEST_ASSERT_EQUAL(lead.combat_resource, 3, "Пуля в клетке от еретика даёт единицу.")
	TEST_ASSERT_EQUAL(user.getBruteLoss(), 0, "Пуля мимо не ранит.")
	gunner.forceMove(get_step(user, WEST))
	heretic_lead_test_shot(gunner, user)
	TEST_ASSERT(user.getBruteLoss() > 0, "Пуля в упор попадает.")
	TEST_ASSERT_EQUAL(lead.combat_resource, 3, "Чаще раза в 2 секунды пули Свинца не дают.")
	COOLDOWN_RESET(lead, whiz_harvest)
	heretic_lead_test_shot(gunner, user, /obj/item/projectile/beam/laser)
	TEST_ASSERT_EQUAL(lead.combat_resource, 3, "Лазер в упор Свинца не даёт.")
	heretic_lead_test_shot(gunner, user)
	TEST_ASSERT_EQUAL(lead.combat_resource, 4, "Попавшая пуля даёт единицу.")
	COOLDOWN_RESET(lead, whiz_harvest)
	var/datum/antagonist/heretic/ally = allocate_heretic(get_step(user, EAST))
	heretic_lead_test_shot(ally.owner.current, user)
	TEST_ASSERT_EQUAL(lead.combat_resource, 4, "Пуля союзника-еретика Свинец не кормит.")
	var/mob/living/carbon/human/foe = allocate(/mob/living/carbon/human, get_step(user, NORTH))
	var/brute_before = foe.getBruteLoss()
	var/obj/item/melee/sickly_blade/lead/blade = allocate(/obj/item/melee/sickly_blade/lead, get_turf(user))
	user.put_in_active_hand(blade)
	blade.attack(foe, user)
	TEST_ASSERT(foe.getBruteLoss() > brute_before, "Штык ранит врага.")
	TEST_ASSERT_EQUAL(lead.combat_resource, 5, "Удар клинком даёт единицу.")
	blade.attack(foe, user)
	TEST_ASSERT_EQUAL(lead.combat_resource, 6,"Каждый удар клинком даёт единицу, без отката.")
	blade.attack(foe, user)
	TEST_ASSERT(lead.combat_resource == 6 && lead.bandolier == 1, "Сверх полного барабана Свинец ложится в патронташ.")

/// Хватка в «Помощи» впитывает до трёх гильз с клетки и не тратит их, когда барабан полон.
/datum/unit_test/heretic_lead_casings/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_LEAD)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_lead/lead = heretic.get_knowledge(/datum/eldritch_knowledge/base_lead)
	lead.combat_resource = 1
	var/turf/spot = get_step(user, EAST)
	var/list/obj/item/ammo_casing/casings = list()
	for(var/index in 1 to 4)
		casings += allocate(/obj/item/ammo_casing/c38, spot)
	var/obj/item/melee/touch_attack/mansus_fist/fist = allocate(/obj/item/melee/touch_attack/mansus_fist)
	var/charges_before = fist.charges
	user.a_intent = INTENT_HARM
	fist.afterattack(casings[1], user, TRUE)
	TEST_ASSERT(!QDELETED(casings[1]) && fist.charges == charges_before, "Вне «Помощи» Хватка гильзы не трогает и заряд не тратит.")
	user.a_intent = INTENT_HELP
	fist.afterattack(casings[1], user, TRUE)
	var/left = 0
	for(var/obj/item/ammo_casing/casing in spot)
		left++
	TEST_ASSERT_EQUAL(left, 1, "С клетки за раз уходят три гильзы.")
	TEST_ASSERT_EQUAL(lead.combat_resource, 1 + HERETIC_LEAD_CASINGS_PER_GRASP, "Каждая гильза даёт единицу Свинца.")
	lead.combat_resource = lead.combat_resource_max
	TEST_ASSERT(lead.absorb_casings(user, spot) && lead.bandolier == 1, "С полным барабаном гильза ложится в патронташ.")
	allocate(/obj/item/ammo_casing/c38, spot)
	lead.bandolier = HERETIC_LEAD_BANDOLIER
	TEST_ASSERT(!lead.absorb_casings(user, spot), "Полные барабан и патронташ гильзы не берут.")
	TEST_ASSERT(findtext(lead.grasp_failure_reason, "полны"), "Отказ называет полные барабан и патронташ.")
	lead.bandolier = 0
	lead.combat_resource = 0
	var/obj/item/ammo_casing/energy/charge = allocate(/obj/item/ammo_casing/energy, get_step(user, NORTH))
	TEST_ASSERT(!lead.absorb_casings(user, get_turf(charge)), "Заряд энергооружия - не гильза.")
	TEST_ASSERT(!QDELETED(charge), "Заряд остаётся лежать.")

/// Палец-ствол: Хватка издали тратит заряд на дробину без оглушения, у места удара звякает гильза; в «Помощи», дальше дальности и по союзнику - отказ без траты.
/datum/unit_test/heretic_lead_finger_gun/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_LEAD)
	var/mob/living/carbon/human/user = heretic.owner.current
	user.forceMove(heretic_lead_test_spot(0, 2))
	var/datum/eldritch_knowledge/base_lead/lead = heretic.get_knowledge(/datum/eldritch_knowledge/base_lead)
	var/mob/living/carbon/human/victim = heretic_lead_test_crew(heretic_lead_test_spot(4, 2))
	var/lead_before = lead.combat_resource
	var/obj/item/melee/touch_attack/mansus_fist/fist = allocate(/obj/item/melee/touch_attack/mansus_fist)
	var/charges_before = fist.charges
	user.a_intent = INTENT_HELP
	fist.afterattack(victim, user, FALSE)
	TEST_ASSERT(!QDELETED(fist) && fist.charges == charges_before, "В «Помощи» Хватка издали не стреляет и заряд не тратит.")
	TEST_ASSERT_NULL(locate(/obj/item/projectile/bullet/heretic_lead_pellet) in range(5, user), "В «Помощи» дробины нет.")
	user.a_intent = INTENT_HARM
	var/obj/item/melee/touch_attack/mansus_fist/refused = allocate(/obj/item/melee/touch_attack/mansus_fist)
	var/mob/living/carbon/human/far = heretic_lead_test_crew(heretic_lead_test_spot(HERETIC_LEAD_FINGER_RANGE + 1, 2))
	refused.afterattack(far, user, FALSE)
	TEST_ASSERT(!QDELETED(refused) && refused.charges == charges_before, "Цель дальше [HERETIC_LEAD_FINGER_RANGE] клеток - отказ без траты заряда.")
	TEST_ASSERT(findtext(lead.lead_failure, "[HERETIC_LEAD_FINGER_RANGE] клеток"), "Отказ называет дальность: [lead.lead_failure]")
	fist.afterattack(victim, user, FALSE)
	TEST_ASSERT(QDELETED(fist) || fist.charges < charges_before, "Выстрел тратит заряд Хватки.")
	var/obj/item/projectile/bullet/heretic_lead_pellet/pellet = locate() in range(5, user)
	TEST_ASSERT_NOTNULL(pellet, "Палец-ствол выпускает дробину.")
	TEST_ASSERT(heretic_lead_ballistic(pellet) && !pellet.homing_target && pellet.firer == user, "Дробина - обычная пуля стрелка без доворота.")
	heretic_lead_test_fly(pellet)
	TEST_ASSERT(victim.getBruteLoss() >= HERETIC_LEAD_FINGER_DAMAGE - 1, "Дробина бьёт на [HERETIC_LEAD_FINGER_DAMAGE] ушибов: [victim.getBruteLoss()]")
	TEST_ASSERT(!victim.IsStun() && !victim.IsKnockdown() && !victim.IsParalyzed(), "Дробина не оглушает и не валит.")
	TEST_ASSERT_EQUAL(lead.combat_resource, lead_before, "Выстрел пальцем Свинца не тратит и не даёт.")
	var/obj/item/ammo_casing/heretic_lead/casing = locate() in range(1, victim)
	TEST_ASSERT_NOTNULL(casing, "У места удара звякает гильза.")
	var/datum/antagonist/heretic/ally = allocate_heretic(heretic_lead_test_spot(2, 4))
	TEST_ASSERT(findtext(lead.finger_block_reason(user, ally.owner.current), "союзник"), "По союзнику Мансуса Палец-ствол не стреляет.")
	ADD_TRAIT(user, TRAIT_PACIFISM, TRAIT_GENERIC)
	TEST_ASSERT(findtext(lead.finger_block_reason(user, victim), "ранить"), "Пацифист пальцем не стреляет.")
	REMOVE_TRAIT(user, TRAIT_PACIFISM, TRAIT_GENERIC)
	victim.forceMove(get_step(user, EAST))
	var/obj/item/melee/touch_attack/mansus_fist/close = allocate(/obj/item/melee/touch_attack/mansus_fist)
	close.afterattack(victim, user, TRUE)
	TEST_ASSERT_NULL(locate(/obj/item/projectile/bullet/heretic_lead_pellet) in range(5, user), "Вблизи Хватка не стреляет.")
	TEST_ASSERT_EQUAL(lead.combat_resource, lead_before + 1, "Вблизи Хватка по врагу работает как обычно и даёт Свинец.")

/// Свои гильзы и возврат: Шестизарядник роняет гильзу, каждое попадание в живого врага возвращает единицу, в союзника - нет; свои гильзы Хватка впитывает.
/datum/unit_test/heretic_lead_own_casings_and_refund/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_LEAD)
	var/mob/living/carbon/human/user = heretic.owner.current
	user.forceMove(heretic_lead_test_spot(0, 2))
	var/datum/eldritch_knowledge/base_lead/lead = heretic.get_knowledge(/datum/eldritch_knowledge/base_lead)
	var/obj/item/heretic_path_relic/lead_revolver/revolver = heretic_lead_test_revolver(heretic, user)
	var/mob/living/carbon/human/victim = heretic_lead_test_crew(heretic_lead_test_spot(4, 2))
	lead.combat_resource = 2
	var/obj/item/projectile/shot = revolver.fire_at(victim, user)
	TEST_ASSERT(istype(shot), "Шестизарядник стреляет.")
	TEST_ASSERT_NOTNULL(locate(/obj/item/ammo_casing/heretic_lead) in get_turf(user), "Из барабана выпадает стреляная гильза.")
	TEST_ASSERT_EQUAL(lead.combat_resource, 1, "Выстрел стоит единицу.")
	heretic_lead_test_fly(shot)
	TEST_ASSERT(victim.getBruteLoss() > 0, "Пуля попала.")
	TEST_ASSERT_EQUAL(lead.combat_resource, 2, "Попадание в живого врага возвращает единицу.")
	COOLDOWN_RESET(revolver, shot_cooldown)
	shot = revolver.fire_at(victim, user)
	heretic_lead_test_fly(shot)
	TEST_ASSERT_EQUAL(lead.combat_resource, 2, "Возврат за каждое попадание, без отката.")
	COOLDOWN_RESET(revolver, shot_cooldown)
	var/datum/antagonist/heretic/ally = allocate_heretic(heretic_lead_test_spot(4, 4))
	shot = revolver.fire_at(ally.owner.current, user)
	heretic_lead_test_fly(shot)
	TEST_ASSERT_EQUAL(lead.combat_resource, 1, "Попадание в союзника Свинец не возвращает.")
	var/dropped = 0
	for(var/obj/item/ammo_casing/heretic_lead/own in get_turf(user))
		dropped++
	TEST_ASSERT_EQUAL(dropped, 3, "Каждый выстрел роняет гильзу.")
	var/obj/item/ammo_casing/heretic_lead/casing = locate() in get_turf(user)
	user.a_intent = INTENT_HELP
	var/obj/item/melee/touch_attack/mansus_fist/fist = allocate(/obj/item/melee/touch_attack/mansus_fist)
	fist.afterattack(casing, user, TRUE)
	TEST_ASSERT_EQUAL(lead.combat_resource, 1 + HERETIC_LEAD_CASINGS_PER_GRASP, "Свои гильзы Хватка впитывает, как чужие.")
	TEST_ASSERT(QDELETED(casing), "Своя гильза растаяла.")

/// Переплавка: секунда Хватки в «Помощи»; листы, прутья и патроны магазина дают Свинец, магазин заодно заговорён; заряд цел; мало металла, полный барабан и сдвиг - отказ.
/datum/unit_test/heretic_lead_smelt/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_LEAD)
	var/mob/living/carbon/human/user = heretic.owner.current
	user.forceMove(heretic_lead_test_spot(2, 2))
	var/datum/eldritch_knowledge/base_lead/lead = heretic.get_knowledge(/datum/eldritch_knowledge/base_lead)
	lead.combat_resource = 0
	var/obj/item/melee/touch_attack/mansus_fist/fist = allocate(/obj/item/melee/touch_attack/mansus_fist)
	var/charges_before = fist.charges
	user.a_intent = INTENT_HELP
	var/obj/item/stack/sheet/metal/short = allocate(/obj/item/stack/sheet/metal, get_step(user, NORTH), HERETIC_LEAD_SMELT_SHEETS - 1)
	fist.afterattack(short, user, TRUE)
	TEST_ASSERT(findtext(lead.grasp_failure_reason, "[HERETIC_LEAD_SMELT_SHEETS] листов"), "Меньше нормы железо не плавится: [lead.grasp_failure_reason]")
	TEST_ASSERT(short.amount == HERETIC_LEAD_SMELT_SHEETS - 1 && lead.combat_resource == 0, "Отказ железо не трогает.")
	var/obj/item/stack/sheet/metal/sheets = allocate(/obj/item/stack/sheet/metal, get_step(user, EAST), HERETIC_LEAD_SMELT_SHEETS + 2)
	user.a_intent = INTENT_HARM
	fist.afterattack(sheets, user, TRUE)
	TEST_ASSERT(sheets.amount == HERETIC_LEAD_SMELT_SHEETS + 2 && lead.combat_resource == 0, "Вне «Помощи» Хватка металл не плавит.")
	user.a_intent = INTENT_HELP
	INVOKE_ASYNC(fist, TYPE_PROC_REF(/obj/item, afterattack), sheets, user, TRUE)
	TEST_ASSERT_NOTNULL(locate(/obj/effect/temp_visual/heretic_lead/smelt) in get_turf(sheets), "Переплавку видно: металл дымит.")
	TEST_ASSERT_EQUAL(lead.combat_resource, 0, "Переплавка идёт не мгновенно.")
	TEST_ASSERT(wait_for_var(lead, NAMEOF(lead, combat_resource), 1, HERETIC_LEAD_SMELT_TIME + 2 SECONDS), "[HERETIC_LEAD_SMELT_SHEETS] листов железа дают единицу Свинца.")
	TEST_ASSERT_EQUAL(sheets.amount, 2, "Уходят ровно [HERETIC_LEAD_SMELT_SHEETS] листов.")
	TEST_ASSERT(!QDELETED(fist) && fist.charges == charges_before, "Переплавка заряд Хватки не тратит.")
	var/obj/item/stack/rods/rods = allocate(/obj/item/stack/rods, get_step(user, WEST), HERETIC_LEAD_SMELT_RODS)
	fist.afterattack(rods, user, TRUE)
	TEST_ASSERT(QDELETED(rods) && lead.combat_resource == 2, "[HERETIC_LEAD_SMELT_RODS] прутьев дают единицу Свинца.")
	var/obj/item/ammo_box/magazine/m10mm/magazine = allocate(/obj/item/ammo_box/magazine/m10mm, get_step(user, SOUTH))
	var/rounds = magazine.ammo_count()
	fist.afterattack(magazine, user, TRUE)
	TEST_ASSERT_EQUAL(lead.combat_resource, 2 + HERETIC_LEAD_SMELT_MAGAZINE_LEAD, "Патроны магазина дают [HERETIC_LEAD_SMELT_MAGAZINE_LEAD] Свинца.")
	TEST_ASSERT_EQUAL(magazine.ammo_count(), rounds - HERETIC_LEAD_SMELT_ROUNDS, "Из магазина уходят [HERETIC_LEAD_SMELT_ROUNDS] патрона.")
	var/datum/component/heretic_lead_curse/curse = magazine.GetComponent(/datum/component/heretic_lead_curse)
	TEST_ASSERT(curse?.crafted && (curse in lead.curses), "Переплавленный магазин заодно заговорён.")
	lead.combat_resource = 0
	var/obj/item/stack/sheet/metal/moved = allocate(/obj/item/stack/sheet/metal, get_step(user, NORTHEAST), HERETIC_LEAD_SMELT_SHEETS)
	INVOKE_ASYNC(fist, TYPE_PROC_REF(/obj/item, afterattack), moved, user, TRUE)
	user.forceMove(heretic_lead_test_spot(0, 0))
	TEST_ASSERT(wait_for_var(fist, NAMEOF(fist, grasp_in_progress), FALSE, HERETIC_LEAD_SMELT_TIME + 2 SECONDS), "Прерванная переплавка отпускает Хватку.")
	TEST_ASSERT(moved.amount == HERETIC_LEAD_SMELT_SHEETS && lead.combat_resource == 0, "Шаг в сторону прерывает переплавку.")
	user.forceMove(heretic_lead_test_spot(2, 2))
	lead.combat_resource = lead.combat_resource_max
	lead.bandolier = HERETIC_LEAD_BANDOLIER
	fist.afterattack(moved, user, TRUE)
	TEST_ASSERT(findtext(lead.grasp_failure_reason, "полны") && moved.amount == HERETIC_LEAD_SMELT_SHEETS, "Полные барабан и патронташ не плавят.")
	var/obj/item/ammo_box/magazine/m10mm/spare = allocate(/obj/item/ammo_box/magazine/m10mm, get_step(user, SOUTHWEST))
	var/spare_rounds = spare.ammo_count()
	fist.afterattack(spare, user, TRUE)
	TEST_ASSERT(spare.GetComponent(/datum/component/heretic_lead_curse) && spare.ammo_count() == spare_rounds, "С полными барабаном и патронташем Хватка магазин только заговаривает.")

/// Тлеющий запас: после затишья Свинец сам прибывает по единице до трёх по таймеру; бой, предел и смерть его держат.
/datum/unit_test/heretic_lead_reserve/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_LEAD)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_lead/lead = heretic.get_knowledge(/datum/eldritch_knowledge/base_lead)
	TEST_ASSERT(lead.spend_combat_resource(lead.combat_resource), "Барабан опустошён.")
	TEST_ASSERT_NOTNULL(lead.reserve_timer, "Ниже трёх Свинца Тлеющий запас ждёт по таймеру.")
	lead.last_combat_at = world.time - HERETIC_LEAD_RESERVE_CALM - 1
	TEST_ASSERT(lead.reserve_tick(), "После затишья Свинец прибывает сам.")
	TEST_ASSERT_EQUAL(lead.combat_resource, 1, "Тлеющий запас даёт единицу.")
	TEST_ASSERT(lead.reserve_timer && timeleft(lead.reserve_timer) > HERETIC_LEAD_RESERVE_PERIOD - 1 SECONDS, "Следующая единица - через [HERETIC_LEAD_RESERVE_PERIOD / (1 SECONDS)] секунд.")
	user.apply_damage(5, BRUTE)
	TEST_ASSERT(world.time - lead.last_combat_at < 1, "Полученный урон - это бой.")
	TEST_ASSERT(!lead.reserve_tick() && lead.combat_resource == 1, "В бою Свинец сам не прибывает.")
	TEST_ASSERT(lead.reserve_timer && timeleft(lead.reserve_timer) > HERETIC_LEAD_RESERVE_CALM - 1 SECONDS, "После боя запас ждёт [HERETIC_LEAD_RESERVE_CALM / (1 SECONDS)] секунд затишья.")
	lead.last_combat_at = -INFINITY
	var/mob/living/carbon/human/foe = allocate(/mob/living/carbon/human, get_step(user, NORTH))
	var/obj/item/melee/sickly_blade/lead/blade = allocate(/obj/item/melee/sickly_blade/lead, get_turf(user))
	user.put_in_active_hand(blade)
	blade.attack(foe, user)
	TEST_ASSERT(world.time - lead.last_combat_at < 1, "Удар по врагу - тоже бой.")
	lead.last_combat_at = -INFINITY
	lead.combat_resource = HERETIC_LEAD_RESERVE_CAP
	TEST_ASSERT(!lead.reserve_tick() && lead.combat_resource == HERETIC_LEAD_RESERVE_CAP, "Выше [HERETIC_LEAD_RESERVE_CAP] Свинец сам не копится.")
	TEST_ASSERT_NULL(lead.reserve_timer, "С полным запасом таймер не крутится.")
	lead.combat_resource = 0
	user.death()
	TEST_ASSERT(user.stat == DEAD, "Еретик мёртв.")
	TEST_ASSERT(!lead.reserve_tick() && lead.combat_resource == 0, "Мёртвому Свинец сам не копится.")
	TEST_ASSERT_NOTNULL(lead.reserve_timer, "Мёртвый ждёт запаса по таймеру, а не каждый тик.")
	lead.on_body_lose(user)
	TEST_ASSERT_NULL(lead.reserve_timer, "Смена тела гасит таймер запаса.")

/// Заговор Хваткой: две осечки экипажа с заклиниванием, дело пути, затем обычный выстрел; еретик стреляет спокойно.
/datum/unit_test/heretic_lead_curse_misfire/Run()
	allocated += new /datum/heretic_test_station_level(run_loc_floor_bottom_left.z)
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_LEAD)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_lead/lead = heretic.get_knowledge(/datum/eldritch_knowledge/base_lead)
	var/obj/item/gun/ballistic/automatic/pistol/gun = allocate(/obj/item/gun/ballistic/automatic/pistol, heretic_lead_test_spot(1, 0))
	var/obj/item/melee/touch_attack/mansus_fist/fist = allocate(/obj/item/melee/touch_attack/mansus_fist)
	user.a_intent = INTENT_HELP
	fist.afterattack(gun, user, TRUE)
	var/datum/component/heretic_lead_curse/curse = gun.GetComponent(/datum/component/heretic_lead_curse)
	TEST_ASSERT_NOTNULL(curse, "Хватка в «Помощи» заговаривает пистолет на полу.")
	TEST_ASSERT(curse.crafted && (curse in lead.curses), "Заговор Хваткой занимает слот ремесла.")
	TEST_ASSERT_EQUAL(curse.charges, HERETIC_LEAD_CURSE_CHARGES, "Заговор держит две осечки.")
	var/mob/living/carbon/human/crew = heretic_lead_test_crew(heretic_lead_test_spot(1, 1))
	var/mob/living/carbon/human/detective = heretic_lead_test_crew(heretic_lead_test_spot(2, 0), "Detective")
	TEST_ASSERT(!findtext(jointext(gun.examine(crew), " "), "патина"), "Обычный член экипажа патины не замечает.")
	TEST_ASSERT(findtext(jointext(gun.examine(detective), " "), "патина"), "Детектив вблизи видит свинцовую патину.")
	TEST_ASSERT(crew.put_in_hands(gun), "Член экипажа берёт пистолет.")
	heretic_test_area(get_turf(crew), /area/cargo/storage)
	var/ammo = gun.get_ammo()
	var/turf/aim = heretic_lead_test_spot(1, 5)
	gun.process_fire(aim, crew)
	TEST_ASSERT_EQUAL(gun.get_ammo(), ammo, "Осечка не тратит патрон.")
	TEST_ASSERT_EQUAL(curse.charges, 1, "Осечка тратит заряд заговора.")
	TEST_ASSERT(world.time < curse.jam_until, "После осечки ствол заклинило.")
	TEST_ASSERT_EQUAL(heretic.deed.progress, 1, "Осечка в руках экипажа на станции продвигает дело.")
	gun.process_fire(aim, crew)
	TEST_ASSERT_EQUAL(gun.get_ammo(), ammo, "Заклинивший ствол не стреляет.")
	TEST_ASSERT_EQUAL(curse.charges, 1, "Заклинивание не тратит вторую осечку.")
	TEST_ASSERT(heretic_lead_test_wait(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(heretic_lead_test_time_passed), curse.jam_until), 3 SECONDS, "заклинивание"), "Заклинивание проходит.")
	gun.process_fire(aim, crew)
	TEST_ASSERT_EQUAL(gun.get_ammo(), ammo, "Вторая осечка тоже без выстрела.")
	TEST_ASSERT(curse.spent && !(curse in lead.curses), "После второй осечки заговор освобождает слот.")
	TEST_ASSERT(wait_for_qdeleted(curse, 4 SECONDS), "Отработавший заговор уходит после заклинивания.")
	gun.process_fire(aim, crew)
	TEST_ASSERT_EQUAL(gun.get_ammo(), ammo - 1, "Без заговора пистолет стреляет.")
	var/obj/item/gun/ballistic/automatic/pistol/own = allocate(/obj/item/gun/ballistic/automatic/pistol, get_turf(user))
	var/datum/component/heretic_lead_curse/own_curse = lead.place_curse(user, own)
	user.put_in_hands(own)
	var/own_ammo = own.get_ammo()
	own.process_fire(aim, user)
	TEST_ASSERT_EQUAL(own.get_ammo(), own_ammo - 1, "Из заговорённого оружия еретик стреляет как обычно.")
	TEST_ASSERT_EQUAL(own_curse.charges, HERETIC_LEAD_CURSE_CHARGES, "Выстрел еретика заговор не тратит.")

/// /proc для CALLBACK ожидания: мировое время дошло до отметки.
/proc/heretic_lead_test_time_passed(mark)
	return world.time >= mark

/// Нулевой жезл и святая вода снимают заговор, пятый вытесняет старейший, магазин передаёт заговор оружию.
/datum/unit_test/heretic_lead_curse_counterplay/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_LEAD)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_lead/lead = heretic.get_knowledge(/datum/eldritch_knowledge/base_lead)
	var/mob/living/carbon/human/crew = heretic_lead_test_crew(get_step(user, NORTH))
	var/obj/item/gun/ballistic/automatic/pistol/rodded = allocate(/obj/item/gun/ballistic/automatic/pistol, get_step(user, EAST))
	var/datum/component/heretic_lead_curse/curse = lead.place_curse(user, rodded)
	var/obj/item/nullrod/rod = allocate(/obj/item/nullrod)
	rodded.attackby(rod, crew)
	TEST_ASSERT(QDELETED(curse) && !rodded.GetComponent(/datum/component/heretic_lead_curse), "Нулевой жезл снимает заговор.")
	TEST_ASSERT(!(curse in lead.curses), "Снятый заговор освобождает слот.")
	var/obj/item/gun/ballistic/automatic/pistol/washed = allocate(/obj/item/gun/ballistic/automatic/pistol, get_step(user, EAST))
	curse = lead.place_curse(user, washed)
	var/datum/reagents/holy = new(10)
	holy.add_reagent(/datum/reagent/water/holywater, 10)
	holy.reaction(washed, TOUCH)
	qdel(holy)
	TEST_ASSERT(QDELETED(curse), "Святая вода снимает заговор.")
	var/list/obj/item/ammo_box/magazine/m10mm/magazines = list()
	for(var/index in 1 to HERETIC_LEAD_CURSE_LIMIT + 1)
		var/obj/item/ammo_box/magazine/m10mm/magazine = allocate(/obj/item/ammo_box/magazine/m10mm, get_step(user, EAST))
		magazines += magazine
		lead.place_curse(user, magazine)
	TEST_ASSERT_EQUAL(length(lead.curses), HERETIC_LEAD_CURSE_LIMIT, "Держатся четыре заговора.")
	var/obj/item/ammo_box/magazine/m10mm/oldest = magazines[1]
	TEST_ASSERT_NULL(oldest.GetComponent(/datum/component/heretic_lead_curse), "Пятый заговор вытесняет старейший.")
	var/obj/item/ammo_box/magazine/m10mm/loaded = magazines[length(magazines)]
	var/obj/item/gun/ballistic/automatic/pistol/receiver = allocate(/obj/item/gun/ballistic/automatic/pistol, get_turf(crew))
	var/obj/item/ammo_box/magazine/old_magazine = receiver.magazine
	receiver.magazine = null
	qdel(old_magazine)
	crew.put_in_hands(receiver)
	crew.put_in_hands(loaded)
	loaded.melee_attack_chain(crew, receiver)
	TEST_ASSERT_EQUAL(receiver.magazine, loaded, "Магазин вставлен в пистолет.")
	TEST_ASSERT_NOTNULL(receiver.GetComponent(/datum/component/heretic_lead_curse), "Заговорённый магазин передаёт заговор пистолету.")
	TEST_ASSERT_NULL(loaded.GetComponent(/datum/component/heretic_lead_curse), "На магазине заговора больше нет.")
	TEST_ASSERT_EQUAL(length(lead.curses), HERETIC_LEAD_CURSE_LIMIT, "Переход заговора не меняет число слотов.")
	var/obj/structure/closet/crate/crate = allocate(/obj/structure/closet/crate, get_step(user, SOUTH))
	var/obj/item/gun/ballistic/automatic/pistol/stored = allocate(/obj/item/gun/ballistic/automatic/pistol, crate)
	TEST_ASSERT_EQUAL(lead.curse_candidate(crate, user), stored, "Хватка по ящику находит оружие внутри.")
	heretic.clear_heretic()
	TEST_ASSERT_NULL(receiver.GetComponent(/datum/component/heretic_lead_curse), "Снятая роль снимает и заговоры.")

/// Сглаз ствола клинит оружие стрелка один раз, не занимает слот ремесла и не берёт лазеры и защищённых.
/datum/unit_test/heretic_lead_hex/Run()
	allocated += new /datum/heretic_test_station_level(run_loc_floor_bottom_left.z)
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_LEAD)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_lead/lead = heretic.get_knowledge(/datum/eldritch_knowledge/base_lead)
	TEST_ASSERT(istype(lead.combat_power, /obj/effect/proc_holder/spell/pointed/heretic_lead/hex), "Сила запаса - Сглаз ствола.")
	var/mob/living/carbon/human/shooter = heretic_lead_test_crew(heretic_lead_test_spot(3, 0))
	var/obj/item/gun/energy/laser/laser = allocate(/obj/item/gun/energy/laser, get_turf(shooter))
	shooter.put_in_hands(laser)
	TEST_ASSERT(findtext(lead.hex_block_reason(user, shooter), "боевого огнестрела"), "Лазер сглазу не поддаётся.")
	var/obj/item/gun/ballistic/automatic/pistol/gun = allocate(/obj/item/gun/ballistic/automatic/pistol, get_turf(shooter))
	shooter.dropItemToGround(laser)
	shooter.put_in_hands(gun)
	TEST_ASSERT(lead.hex(user, shooter), "Сглаз берёт пистолет в руках стрелка.")
	TEST_ASSERT_EQUAL(lead.combat_resource, 1, "Сглаз стоит единицу Свинца.")
	var/datum/component/heretic_lead_curse/curse = gun.GetComponent(/datum/component/heretic_lead_curse)
	TEST_ASSERT(curse && !curse.crafted && curse.charges == 1, "Сглаз - одна осечка не ремеслом.")
	TEST_ASSERT(!(curse in lead.curses), "Сглаз не занимает слот заговоров.")
	TEST_ASSERT_NOTNULL(curse.expire_timer, "Сглаз выдыхается сам.")
	var/ammo = gun.get_ammo()
	gun.process_fire(heretic_lead_test_spot(3, 5), shooter)
	TEST_ASSERT_EQUAL(gun.get_ammo(), ammo, "Сглаженный пистолет даёт осечку.")
	TEST_ASSERT_EQUAL(heretic.deed.progress, 0, "Осечка от Сглаза дело пути не двигает.")
	var/mob/living/carbon/human/warded = heretic_lead_test_crew(heretic_lead_test_spot(4, 0))
	var/obj/item/gun/ballistic/automatic/pistol/warded_gun = allocate(/obj/item/gun/ballistic/automatic/pistol, get_turf(warded))
	warded.put_in_hands(warded_gun)
	warded.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5)
	TEST_ASSERT(!lead.hex(user, warded), "Защита от магии отводит сглаз.")
	TEST_ASSERT_NULL(warded_gun.GetComponent(/datum/component/heretic_lead_curse), "Защищённое оружие не заговорено.")
	TEST_ASSERT_EQUAL(lead.combat_resource, 1, "Отведённый сглаз Свинца не тратит.")
	var/obj/effect/proc_holder/spell/pointed/heretic_lead/hex/spell = lead.combat_power
	spell.charge_counter = 0
	spell.cast(list(warded), user)
	TEST_ASSERT_NULL(warded_gun.GetComponent(/datum/component/heretic_lead_curse), "Отведённый сглаз из кнопки оружие не трогает.")
	TEST_ASSERT_EQUAL(spell.charge_counter, 0, "Отведённый защитой сглаз перезарядку не возвращает: заряды защиты не снять очередью.")
	TEST_ASSERT_EQUAL(lead.combat_resource, 1, "Отведённый из кнопки сглаз Свинца не тратит.")
	var/mob/living/carbon/human/cursed_shooter = heretic_lead_test_crew(heretic_lead_test_spot(1, 3))
	var/obj/item/gun/ballistic/automatic/pistol/cursed_gun = allocate(/obj/item/gun/ballistic/automatic/pistol, get_turf(cursed_shooter))
	lead.place_curse(user, cursed_gun)
	cursed_shooter.put_in_hands(cursed_gun)
	TEST_ASSERT(findtext(lead.hex_block_reason(user, cursed_shooter), "уже заговорено"), "Отказ по заговорённому Хваткой оружию называет причину.")

/// Пуля с именем: тяжесть, падение, захват и дверь в изнанку; чужого она не узнаёт, святая вода снимает тяжесть.
/datum/unit_test/heretic_lead_named_capture/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_LEAD)
	var/mob/living/carbon/human/user = heretic.owner.current
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/lead_named)
	var/datum/eldritch_knowledge/base_lead/lead = heretic.get_knowledge(/datum/eldritch_knowledge/base_lead)
	var/mob/living/carbon/human/victim = heretic_lead_test_crew(heretic_lead_test_spot(3, 0))
	lead.combat_resource = HERETIC_LEAD_NAMED_COST - 1
	TEST_ASSERT(findtext(lead.named_block_reason(user, victim), "[HERETIC_LEAD_NAMED_COST] Свинца"), "Без [HERETIC_LEAD_NAMED_COST] Свинца пули нет.")
	lead.combat_resource = HERETIC_LEAD_NAMED_COST
	var/obj/item/projectile/heretic_lead_named/bullet = lead.fire_named(user, victim)
	TEST_ASSERT(istype(bullet), "Пуля с именем вылетает.")
	TEST_ASSERT_EQUAL(bullet.homing_turn_speed, HERETIC_LEAD_NAMED_TURN, "Пуля с именем доворачивает со своей скоростью.")
	TEST_ASSERT_EQUAL(lead.combat_resource, 0, "Пуля с именем стоит [HERETIC_LEAD_NAMED_COST] Свинца.")
	heretic_lead_test_fly(bullet, 2)
	var/datum/status_effect/heretic_lead_heavy/heavy = victim.has_status_effect(/datum/status_effect/heretic_lead_heavy)
	TEST_ASSERT_NOTNULL(heavy, "Попавшая пуля вешает тяжесть.")
	TEST_ASSERT(!heavy.fallen && !victim.IsKnockdown(), "Первые шесть секунд цель ещё на ногах.")
	TEST_ASSERT(HAS_TRAIT(victim, TRAIT_HERETIC_CAPTURE_HOLD), "Тяжесть держит как захват.")
	TEST_ASSERT(victim.getBruteLoss() <= 5, "Пуля с именем почти не ранит.")
	TEST_ASSERT(lead.impact_fresh(), "Удар пули ставит точку Рикошета.")
	TEST_ASSERT(wait_for_var(heavy, NAMEOF(heavy, fallen), TRUE, HERETIC_LEAD_HEAVY_TIME + 2 SECONDS), "Через шесть секунд цель падает.")
	TEST_ASSERT(victim.IsKnockdown(), "Упавшая цель лежит.")
	TEST_ASSERT(!lead.door_holds(user, victim), "Издалека дверь в изнанку не открыта.")
	victim.forceMove(get_step(user, EAST))
	heretic.set_hunt_target(victim.mind)
	TEST_ASSERT(lead.door_holds(user, victim), "Упавшая под тяжестью цель рядом - дверь в изнанку.")
	TEST_ASSERT(islist(lead.pocket_door(user, victim)), "Сердце предлагает увести цель в свинец.")
	victim.reagents.add_reagent(/datum/reagent/water/holywater, 5)
	TEST_ASSERT(wait_for_qdeleted(heavy, 2 SECONDS), "Святая вода в крови снимает тяжесть.")
	TEST_ASSERT(!victim.IsKnockdown() && !HAS_TRAIT(victim, TRAIT_HERETIC_CAPTURE_HOLD), "Снятая тяжесть отпускает цель.")
	lead.combat_resource = HERETIC_LEAD_NAMED_COST
	TEST_ASSERT(findtext(lead.named_block_reason(user, victim), "приходит в себя"), "После захвата цель какое-то время невосприимчива.")

/// Заслонивший телом получает пылинку свинца, а цель охоты под Пристрелкой падает сразу.
/datum/unit_test/heretic_lead_named_block_and_zeroed/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_LEAD)
	var/mob/living/carbon/human/user = heretic.owner.current
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/lead_named)
	var/datum/eldritch_knowledge/base_lead/lead = heretic.get_knowledge(/datum/eldritch_knowledge/base_lead)
	var/mob/living/carbon/human/victim = heretic_lead_test_crew(heretic_lead_test_spot(4, 0))
	var/mob/living/carbon/human/guard = heretic_lead_test_crew(heretic_lead_test_spot(2, 0))
	lead.combat_resource = HERETIC_LEAD_NAMED_COST
	heretic_lead_test_fly(lead.fire_named(user, victim), 2)
	TEST_ASSERT_NULL(guard.has_status_effect(/datum/status_effect/heretic_lead_heavy), "Заслонившего пуля не узнаёт.")
	TEST_ASSERT_NULL(victim.has_status_effect(/datum/status_effect/heretic_lead_heavy), "Заслонённая цель цела.")
	guard.forceMove(heretic_lead_test_spot(2, 3))
	heretic.set_hunt_target(victim.mind)
	victim.apply_status_effect(/datum/status_effect/heretic_lead_zeroed, lead)
	TEST_ASSERT(lead.zeroed_by_me(victim), "Пристрелка записана за еретиком.")
	lead.combat_resource = HERETIC_LEAD_NAMED_COST
	heretic_lead_test_fly(lead.fire_named(user, victim), 2)
	var/datum/status_effect/heretic_lead_heavy/heavy = victim.has_status_effect(/datum/status_effect/heretic_lead_heavy)
	TEST_ASSERT(heavy?.fallen && victim.IsKnockdown(), "Цель охоты под Пристрелкой падает сразу.")
	if(heavy.linked_alert)
		TEST_ASSERT(findtext(heavy.linked_alert.desc, "сразу"), "Значок мгновенного падения не обещает шесть секунд на ногах: [heavy.linked_alert.desc]")

/// Пуля с именем, долетевшая до цели, пока стрелок оглушён, осыпается и возвращает Свинец.
/datum/unit_test/heretic_lead_named_fizzle/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_LEAD)
	var/mob/living/carbon/human/user = heretic.owner.current
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/lead_named)
	var/datum/eldritch_knowledge/base_lead/lead = heretic.get_knowledge(/datum/eldritch_knowledge/base_lead)
	var/mob/living/carbon/human/victim = heretic_lead_test_crew(heretic_lead_test_spot(3, 0))
	lead.combat_resource = HERETIC_LEAD_NAMED_COST
	var/obj/item/projectile/heretic_lead_named/bullet = lead.fire_named(user, victim)
	TEST_ASSERT(istype(bullet), "Пуля с именем вылетает.")
	user.Stun(5 SECONDS)
	heretic_lead_test_fly(bullet, 2)
	TEST_ASSERT(QDELETED(bullet), "Пуля долетела.")
	TEST_ASSERT_NULL(victim.has_status_effect(/datum/status_effect/heretic_lead_heavy), "Без стрелка в сознании пуля тяжести не вешает.")
	TEST_ASSERT_EQUAL(lead.combat_resource, HERETIC_LEAD_NAMED_COST, "Осыпавшаяся пуля возвращает Свинец.")
	user.SetStun(0)

/// Отдача отбрасывает и берёт на Пристрелку, к которой доворачивает пуля Шестизарядника.
/datum/unit_test/heretic_lead_recoil_and_revolver/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_LEAD)
	var/mob/living/carbon/human/user = heretic.owner.current
	heretic.gain_knowledge(/datum/eldritch_knowledge/lead_grasp)
	heretic.gain_knowledge(/datum/eldritch_knowledge/lead_relic)
	var/datum/eldritch_knowledge/base_lead/lead = heretic.get_knowledge(/datum/eldritch_knowledge/base_lead)
	var/mob/living/carbon/human/victim = heretic_lead_test_crew(get_step(user, EAST))
	var/obj/item/melee/touch_attack/mansus_fist/fist = allocate(/obj/item/melee/touch_attack/mansus_fist)
	fist.afterattack(victim, user, TRUE)
	TEST_ASSERT(lead.zeroed_by_me(victim), "Отдача вешает Пристрелку.")
	TEST_ASSERT(heretic_lead_test_wait(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(heretic_lead_test_far_enough), user, victim, HERETIC_LEAD_RECOIL_DISTANCE), 3 SECONDS, "отдача"), "Отдача отбрасывает на две клетки.")
	var/obj/item/projectile/bullet/heretic_lead/probe = allocate(/obj/item/projectile/bullet/heretic_lead, get_turf(user))
	probe.firer = user
	probe.preparePixelProjectile(victim, user)
	TEST_ASSERT_EQUAL(lead.assist_aim(probe), victim, "Пристрелка доворачивает пулю к цели на линии.")
	TEST_ASSERT_EQUAL(probe.homing_turn_speed, HERETIC_LEAD_ASSIST_TURN, "Пристрелка доворачивает мягко, а не со скоростью по умолчанию.")
	var/datum/eldritch_knowledge/lead_relic/recipe = heretic.get_knowledge(/datum/eldritch_knowledge/lead_relic)
	TEST_ASSERT(recipe.on_finished_recipe(user, list(), get_turf(user)), "Обряд создаёт Шестизарядник.")
	var/obj/item/heretic_path_relic/lead_revolver/revolver = recipe.new_path_relic_ref.resolve()
	allocated += revolver
	TEST_ASSERT(!recipe.new_path_relic_available(), "Шестизарядник один.")
	user.put_in_hands(revolver)
	lead.combat_resource = 0
	TEST_ASSERT(!revolver.fire_at(heretic_lead_test_spot(5, 0), user), "Без Свинца барабан щёлкает вхолостую.")
	lead.combat_resource = 2
	COOLDOWN_RESET(revolver, shot_cooldown)
	var/turf/wall = heretic_lead_test_spot(6, 0)
	TEST_ASSERT(iswallturf(wall), "Справа от пола стена.")
	var/obj/item/projectile/bullet/heretic_lead/shot = revolver.fire_at(wall, user)
	TEST_ASSERT(istype(shot), "Шестизарядник стреляет Свинцом.")
	TEST_ASSERT_EQUAL(lead.combat_resource, 1, "Выстрел стоит единицу.")
	heretic_lead_test_fly(shot)
	TEST_ASSERT(lead.impact_fresh(), "Удар пули запоминается для Рикошета.")
	var/mob/living/carbon/human/thief = heretic_lead_test_crew(heretic_lead_test_spot(0, 3))
	user.dropItemToGround(revolver)
	revolver.forceMove(get_turf(thief))
	thief.put_in_hands(revolver)
	COOLDOWN_RESET(revolver, shot_cooldown)
	revolver.fire_at(heretic_lead_test_spot(4, 3), thief)
	TEST_ASSERT_EQUAL(round(thief.getBruteLoss(), 1), HERETIC_LEAD_REVOLVER_DAMAGE, "Не-еретик получает пулю в ногу.")
	TEST_ASSERT(!thief.is_holding(revolver), "Не-еретик роняет револьвер.")

/proc/heretic_lead_test_far_enough(atom/first, atom/second, distance)
	return get_dist(first, second) >= distance

/// Рикошет уводит к свежему месту удара своей пули и оставляет пороховой дым; без точки - отказ с причиной.
/datum/unit_test/heretic_lead_ricochet/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_LEAD)
	var/mob/living/carbon/human/user = heretic.owner.current
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/lead_ricochet)
	var/datum/eldritch_knowledge/base_lead/lead = heretic.get_knowledge(/datum/eldritch_knowledge/base_lead)
	TEST_ASSERT(findtext(lead.ricochet_block_reason(user), "Некуда"), "Без удара пули Рикошету некуда вести.")
	var/turf/origin = get_turf(user)
	var/turf/point = heretic_lead_test_spot(4, 2)
	lead.record_impact(point)
	TEST_ASSERT(lead.ricochet(user), "Рикошет уводит к месту удара.")
	TEST_ASSERT_EQUAL(get_turf(user), point, "Еретик стоит на месте удара пули.")
	TEST_ASSERT_EQUAL(lead.combat_resource, 1, "Рикошет стоит единицу.")
	var/obj/effect/temp_visual/heretic_lead/smoke/smoke = locate() in origin
	TEST_ASSERT(smoke?.opacity, "На месте ухода стоит непрозрачный пороховой дым.")
	TEST_ASSERT(findtext(lead.ricochet_block_reason(user), "Некуда"), "Точка расходуется.")
	lead.record_impact(origin)
	lead.impact_at = world.time - HERETIC_LEAD_RICOCHET_MEMORY - 1
	TEST_ASSERT(!lead.ricochet(user), "Старая точка не годится.")
	TEST_ASSERT_EQUAL(lead.combat_resource, 1, "Отказ Свинца не тратит.")
	var/mob/living/carbon/human/bystander = allocate(/mob/living/carbon/human, origin)
	lead.record_impact(origin)
	TEST_ASSERT(lead.ricochet(user), "Рикошет к подстреленному ведёт рядом с ним.")
	TEST_ASSERT(get_turf(user) != origin && get_dist(user, bystander) <= 1, "Еретик оказывается рядом с тем, кто стоит в точке.")

/// Ловля пули: пули в окне не ранят и дают Свинец, лазер проходит.
/datum/unit_test/heretic_lead_catch/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_LEAD)
	var/mob/living/carbon/human/user = heretic.owner.current
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/lead_catch)
	var/datum/eldritch_knowledge/base_lead/lead = heretic.get_knowledge(/datum/eldritch_knowledge/base_lead)
	var/datum/eldritch_knowledge/spell/lead_catch/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/spell/lead_catch)
	var/mob/living/carbon/human/gunner = allocate(/mob/living/carbon/human, get_step(user, EAST))
	knowledge.granted_spell.cast(list(user), user)
	TEST_ASSERT_NOTNULL(user.has_status_effect(/datum/status_effect/heretic_lead_catch), "Ловля пули открывает окно.")
	heretic_lead_test_shot(gunner, user, damage = 20)
	heretic_lead_test_shot(gunner, user, damage = 20)
	TEST_ASSERT_EQUAL(user.getBruteLoss(), 0, "Пойманные пули не ранят.")
	TEST_ASSERT_EQUAL(lead.combat_resource, 4, "Каждая пойманная пуля даёт единицу.")
	heretic_lead_test_shot(gunner, user, /obj/item/projectile/beam/laser, 20)
	TEST_ASSERT(user.getFireLoss() > 0, "Лазер не ловится.")

/// Ловля пули и Рикошет работают в агрессивной чужой хватке, как обещают их описания; оглушение до вознесения глушит путь.
/datum/unit_test/heretic_lead_grabbed/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_LEAD)
	var/mob/living/carbon/human/user = heretic.owner.current
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/lead_catch)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/lead_ricochet)
	var/datum/eldritch_knowledge/base_lead/lead = heretic.get_knowledge(/datum/eldritch_knowledge/base_lead)
	var/datum/eldritch_knowledge/spell/lead_catch/catching = heretic.get_knowledge(/datum/eldritch_knowledge/spell/lead_catch)
	var/datum/eldritch_knowledge/spell/lead_ricochet/ricochet = heretic.get_knowledge(/datum/eldritch_knowledge/spell/lead_ricochet)
	var/mob/living/carbon/human/grabber = heretic_lead_test_crew(get_step(user, NORTH))
	grabber.start_pulling(user)
	grabber.setGrabState(GRAB_AGGRESSIVE)
	TEST_ASSERT(user.incapacitated(), "Агрессивный захват сковывает еретика.")
	var/obj/effect/proc_holder/spell/catch_spell = catching.granted_spell
	TEST_ASSERT(catch_spell.can_cast(user, FALSE, TRUE), "Ловля пули доступна в чужой хватке: [catch_spell.heretic_failure_reason]")
	catch_spell.cast(list(user), user)
	TEST_ASSERT_NOTNULL(user.has_status_effect(/datum/status_effect/heretic_lead_catch), "Ловля пули в хватке открывает окно.")
	lead.record_impact(heretic_lead_test_spot(4, 2))
	var/obj/effect/proc_holder/spell/ricochet_spell = ricochet.granted_spell
	TEST_ASSERT(ricochet_spell.can_cast(user, FALSE, TRUE), "Рикошет доступен в чужой хватке: [ricochet_spell.heretic_failure_reason]")
	TEST_ASSERT(lead.ricochet(user), "Рикошет уводит из хватки: [lead.lead_failure]")
	TEST_ASSERT_EQUAL(get_turf(user), heretic_lead_test_spot(4, 2), "Еретик ушёл к месту удара пули.")
	user.Stun(5 SECONDS)
	TEST_ASSERT(!lead.can_use(user, TRUE), "До вознесения оглушение глушит путь.")
	user.SetStun(0)

/// Игрушки и поролон не дают ни Свинца, ни заговора, ни сглаза, ни выстрела на слух.
/datum/unit_test/heretic_lead_toys/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_LEAD)
	var/mob/living/carbon/human/user = heretic.owner.current
	user.forceMove(heretic_lead_test_spot(2, 1))
	var/datum/eldritch_knowledge/base_lead/lead = heretic.get_knowledge(/datum/eldritch_knowledge/base_lead)
	lead.combat_resource = 0
	var/turf/pile = get_step(user, EAST)
	var/obj/item/ammo_casing/caseless/foam_dart/dart = allocate(/obj/item/ammo_casing/caseless/foam_dart, pile)
	TEST_ASSERT(!lead.absorb_casings(user, dart), "Поролоновый дротик - не гильза.")
	TEST_ASSERT(!QDELETED(dart) && lead.combat_resource == 0, "Дротик лежит, Свинца не прибавилось.")
	allocate(/obj/item/ammo_casing/c38, pile)
	TEST_ASSERT(lead.absorb_casings(user, pile), "Боевая гильза рядом с дротиком впитывается.")
	TEST_ASSERT(!QDELETED(dart) && lead.combat_resource == 1, "С клетки ушла только боевая гильза.")
	var/obj/item/gun/ballistic/automatic/toy/pistol/unrestricted/toy = allocate(/obj/item/gun/ballistic/automatic/toy/pistol/unrestricted, get_step(user, NORTH))
	var/obj/item/ammo_box/foambox/box = allocate(/obj/item/ammo_box/foambox, get_step(user, NORTH))
	TEST_ASSERT(!heretic_lead_curseable(toy) && !heretic_lead_curseable(box), "Игрушки заговор не берёт.")
	TEST_ASSERT(heretic_lead_curseable(allocate(/obj/item/gun/ballistic/automatic/pistol)) && heretic_lead_curseable(allocate(/obj/item/ammo_box/magazine/m10mm)), "Боевой пистолет и магазин к нему заговор берёт.")
	var/obj/item/melee/touch_attack/mansus_fist/fist = allocate(/obj/item/melee/touch_attack/mansus_fist)
	user.a_intent = INTENT_HELP
	fist.afterattack(toy, user, TRUE)
	TEST_ASSERT_NULL(toy.GetComponent(/datum/component/heretic_lead_curse), "Хватка игрушку не заговаривает.")
	var/mob/living/carbon/human/kid = heretic_lead_test_crew(heretic_lead_test_spot(4, 3))
	kid.put_in_hands(toy)
	TEST_ASSERT(findtext(lead.hex_block_reason(user, kid), "игрушки"), "Сглаз игрушку не берёт.")
	var/mob/living/carbon/human/gunner = allocate(/mob/living/carbon/human, heretic_lead_test_spot(0, 0))
	var/obj/item/projectile/foam = heretic_lead_test_bullet(gunner, heretic_lead_test_spot(5, 0), /obj/item/projectile/bullet/reusable/foam_dart)
	foam.nodamage = FALSE
	foam.fire()
	heretic_lead_test_fly(foam)
	TEST_ASSERT_EQUAL(lead.combat_resource, 1, "Дротик с ручкой мимо еретика Свинца не даёт.")

/// Мишень гнёт пули экипажа в меченого, а не в еретика; лазеры и свои пули не гнутся; клинок взрывает метку Прострелом.
/datum/unit_test/heretic_lead_mark/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_LEAD)
	var/mob/living/carbon/human/user = heretic.owner.current
	heretic.gain_knowledge(/datum/eldritch_knowledge/lead_mark)
	var/datum/eldritch_knowledge/base_lead/lead = heretic.get_knowledge(/datum/eldritch_knowledge/base_lead)
	var/mob/living/carbon/human/marked = heretic_lead_test_crew(heretic_lead_test_spot(3, 2))
	marked.apply_status_effect(/datum/status_effect/eldritch/lead, lead)
	TEST_ASSERT_NOTNULL(marked.has_status_effect(/datum/status_effect/eldritch/lead), "Мишень встаёт на цель.")
	var/mob/living/carbon/human/gunner = allocate(/mob/living/carbon/human, heretic_lead_test_spot(5, 0))
	var/obj/item/projectile/laser = heretic_lead_test_bullet(gunner, user, /obj/item/projectile/beam/laser)
	laser.fire()
	TEST_ASSERT(laser.homing_target != marked, "Лазер не гнётся.")
	heretic_lead_test_fly(laser)
	var/obj/item/projectile/shot = heretic_lead_test_bullet(gunner, user)
	shot.fire()
	heretic_lead_test_fly(shot, 0.05)
	TEST_ASSERT_EQUAL(shot.homing_target, marked, "Пуля экипажа рядом с меченым сворачивает в него.")
	TEST_ASSERT_EQUAL(shot.homing_turn_speed, HERETIC_LEAD_MARK_TURN, "Мишень гнёт пулю круто.")
	TEST_ASSERT_EQUAL(shot.original, marked, "Согнутая пуля метит прямо в меченого.")
	heretic_lead_test_fly(shot)
	TEST_ASSERT(marked.getBruteLoss() > 0, "Свернувшая пуля попадает в меченого.")
	TEST_ASSERT_EQUAL(user.getBruteLoss(), 0, "В еретика пуля так и не пришла.")
	var/obj/item/projectile/own = heretic_lead_test_bullet(user, gunner)
	own.fire()
	heretic_lead_test_fly(own, 0.2)
	TEST_ASSERT(QDELETED(own) || own.homing_target != marked, "Пуля еретика не гнётся.")
	marked.forceMove(get_step(user, NORTH))
	var/brute_before = marked.getBruteLoss()
	var/obj/item/melee/sickly_blade/lead/blade = allocate(/obj/item/melee/sickly_blade/lead, get_turf(user))
	user.put_in_active_hand(blade)
	blade.attack(marked, user)
	TEST_ASSERT(marked.getBruteLoss() >= brute_before + HERETIC_LEAD_MARK_DAMAGE, "Прострел добавляет [HERETIC_LEAD_MARK_DAMAGE] ушибов.")
	TEST_ASSERT(marked.IsKnockdown(), "Прострел валит меченого.")
	TEST_ASSERT_NULL(marked.has_status_effect(/datum/status_effect/eldritch/lead), "Метка взорвана.")

/// Согнутая Мишенью пуля находит и лежачего меченого, а не кружит над ним.
/datum/unit_test/heretic_lead_mark_prone/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_LEAD)
	var/mob/living/carbon/human/user = heretic.owner.current
	heretic.gain_knowledge(/datum/eldritch_knowledge/lead_mark)
	var/datum/eldritch_knowledge/base_lead/lead = heretic.get_knowledge(/datum/eldritch_knowledge/base_lead)
	var/mob/living/carbon/human/marked = heretic_lead_test_crew(heretic_lead_test_spot(3, 2))
	marked.apply_status_effect(/datum/status_effect/eldritch/lead, lead)
	marked.set_resting(TRUE, TRUE)
	TEST_ASSERT(!marked.density, "Меченый лежит.")
	var/mob/living/carbon/human/gunner = allocate(/mob/living/carbon/human, heretic_lead_test_spot(5, 0))
	var/obj/item/projectile/shot = heretic_lead_test_bullet(gunner, user)
	shot.fire()
	heretic_lead_test_fly(shot)
	TEST_ASSERT(marked.getBruteLoss() > 0, "Согнутая пуля попадает в лежачего меченого.")
	TEST_ASSERT_EQUAL(user.getBruteLoss(), 0, "В еретика пуля не пришла.")

/// Пуля без стрелка, залетевшая к меченому, сворачивает в него и пишется в лог меченого без ошибки.
/datum/unit_test/heretic_lead_mark_no_firer/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_LEAD)
	heretic.gain_knowledge(/datum/eldritch_knowledge/lead_mark)
	var/datum/eldritch_knowledge/base_lead/lead = heretic.get_knowledge(/datum/eldritch_knowledge/base_lead)
	var/mob/living/carbon/human/marked = heretic_lead_test_crew(heretic_lead_test_spot(3, 2))
	var/datum/status_effect/eldritch/lead/mark = marked.apply_status_effect(/datum/status_effect/eldritch/lead, lead)
	TEST_ASSERT_NOTNULL(mark, "Мишень встаёт на цель.")
	var/obj/item/projectile/bullet/shot = allocate(/obj/item/projectile/bullet, heretic_lead_test_spot(3, 0))
	shot.damage = 5
	shot.fired = TRUE
	shot.firer = null
	mark.on_entered(get_turf(shot), shot)
	TEST_ASSERT(HAS_TRAIT(shot, "heretic_lead_bent"), "Пуля без стрелка тоже сворачивает в меченого.")

/// Слух стрелка показывает стрелку к выстрелу из огнестрела на этаже, лазер не слышен, повтор того же стрелка - одна стрелка.
/datum/unit_test/heretic_lead_ear/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_LEAD)
	var/mob/living/carbon/human/user = heretic.owner.current
	heretic.gain_knowledge(/datum/eldritch_knowledge/lead_ear)
	var/datum/eldritch_knowledge/lead_ear/ear = heretic.get_knowledge(/datum/eldritch_knowledge/lead_ear)
	TEST_ASSERT_EQUAL(ear.hearing_range(), 30, "Слух стрелка берёт 30 клеток.")
	var/mob/living/carbon/human/crew = heretic_lead_test_crew(heretic_lead_test_spot(4, 4))
	var/obj/item/gun/energy/laser/laser = allocate(/obj/item/gun/energy/laser, get_turf(crew))
	crew.put_in_hands(laser)
	laser.process_fire(heretic_lead_test_spot(4, 0), crew)
	TEST_ASSERT_EQUAL(length(ear.arrows), 0, "Лазер это ухо не слышит.")
	crew.dropItemToGround(laser)
	var/obj/item/gun/ballistic/automatic/pistol/gun = allocate(/obj/item/gun/ballistic/automatic/pistol, get_turf(crew))
	crew.put_in_hands(gun)
	gun.process_fire(heretic_lead_test_spot(4, 0), crew)
	TEST_ASSERT_EQUAL(length(ear.arrows), 1, "Выстрел из огнестрела даёт стрелку.")
	var/atom/movable/screen/heretic_lead_ear/arrow = ear.arrows[1]
	TEST_ASSERT_EQUAL(arrow.ear, ear, "Стрелка принадлежит слуху еретика.")
	gun.fire_delay = 0
	gun.last_fire = 0
	gun.process_fire(heretic_lead_test_spot(4, 0), crew)
	TEST_ASSERT_EQUAL(length(ear.arrows), 1, "Повтор того же стрелка за секунду новой стрелки не даёт.")
	TEST_ASSERT_NULL(arrow.vars["hud"], "Стрелка не принимает знание за свой HUD.")
	var/mob/living/carbon/human/kid = heretic_lead_test_crew(heretic_lead_test_spot(0, 4))
	var/obj/item/gun/ballistic/automatic/toy/pistol/unrestricted/toy = allocate(/obj/item/gun/ballistic/automatic/toy/pistol/unrestricted, get_turf(kid))
	kid.put_in_hands(toy)
	var/toy_ammo = toy.get_ammo()
	toy.process_fire(heretic_lead_test_spot(4, 4), kid)
	TEST_ASSERT(toy.get_ammo() < toy_ammo, "Игрушечный пистолет выстрелил.")
	TEST_ASSERT_EQUAL(length(ear.arrows), 1, "Игрушечный выстрел это ухо не слышит.")
	ear.on_body_lose(user)
	TEST_ASSERT(QDELETED(arrow) && !length(ear.arrows), "Смена тела гасит стрелки.")
	var/mob/living/carbon/human/spare = allocate(/mob/living/carbon/human, heretic_lead_test_spot(2, 2))
	ear.on_body_gain(spare)
	TEST_ASSERT_EQUAL(ear.listener, spare, "Слух следует за телом.")
	qdel(spare)
	TEST_ASSERT_NULL(ear.listener, "Удалённое тело отпускает слух.")

/// Свинцовый дождь бьёт подсвеченный круг через полторы секунды; ушедший из круга и сам еретик целы.
/datum/unit_test/heretic_lead_rain/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_LEAD)
	var/mob/living/carbon/human/user = heretic.owner.current
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/lead_rain)
	var/datum/eldritch_knowledge/base_lead/lead = heretic.get_knowledge(/datum/eldritch_knowledge/base_lead)
	var/turf/center = heretic_lead_test_spot(3, 2)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, center)
	var/mob/living/carbon/human/edge = allocate(/mob/living/carbon/human, heretic_lead_test_spot(4, 3))
	var/mob/living/carbon/human/outside = allocate(/mob/living/carbon/human, heretic_lead_test_spot(0, 4))
	TEST_ASSERT(lead.rain(user, center), "Дождь вызван.")
	TEST_ASSERT_EQUAL(lead.combat_resource, 0, "Дождь стоит два Свинца.")
	TEST_ASSERT_NOTNULL(locate(/obj/effect/temp_visual/heretic_lead/rain_marker) in center, "Круг подсвечен заранее.")
	TEST_ASSERT_EQUAL(victim.getBruteLoss(), 0, "До удара урона нет.")
	TEST_ASSERT(heretic_lead_test_wait(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(heretic_lead_test_brute_at_least), victim, HERETIC_LEAD_RAIN_DAMAGE), 4 SECONDS, "свинцовый дождь"), "Свинец падает на круг.")
	TEST_ASSERT(edge.getBruteLoss() >= HERETIC_LEAD_RAIN_DAMAGE, "Дождь бьёт весь круг радиусом 2.")
	TEST_ASSERT_NOTNULL(victim.has_status_effect(/datum/status_effect/heretic_lead_slowed), "Дождь замедляет.")
	TEST_ASSERT_EQUAL(outside.getBruteLoss(), 0, "Вне круга урона нет.")
	TEST_ASSERT_EQUAL(user.getBruteLoss(), 0, "Еретика свой дождь не бьёт.")

/// Смена тела снимает тяжесть, Пристрелку и точку Рикошета, заговоры остаются; Тугое ухо и тексты берут числа из дефайнов.
/datum/unit_test/heretic_lead_lifecycle_and_texts/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_LEAD)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_lead/lead = heretic.get_knowledge(/datum/eldritch_knowledge/base_lead)
	var/mob/living/carbon/human/victim = heretic_lead_test_crew(get_step(user, EAST))
	victim.apply_status_effect(/datum/status_effect/heretic_lead_zeroed, lead)
	var/obj/item/gun/ballistic/automatic/pistol/gun = allocate(/obj/item/gun/ballistic/automatic/pistol, get_turf(user))
	var/datum/component/heretic_lead_curse/curse = lead.place_curse(user, gun)
	lead.record_impact(get_turf(victim))
	var/mob/living/carbon/human/new_body = allocate(/mob/living/carbon/human, heretic_lead_test_spot(4, 4))
	heretic.owner.transfer_to(new_body)
	TEST_ASSERT_EQUAL(lead.lead_body, new_body, "Свинец следует за разумом.")
	TEST_ASSERT_NULL(victim.has_status_effect(/datum/status_effect/heretic_lead_zeroed), "Смена тела снимает Пристрелку.")
	TEST_ASSERT(!lead.impact_fresh(), "Смена тела стирает точку Рикошета.")
	TEST_ASSERT(!QDELETED(curse) && (curse in lead.curses), "Заговоры переживают смену тела.")
	TEST_ASSERT(istype(lead.innate, /datum/heretic_innate/lead), "Врождённая черта Свинца - Тугое ухо.")
	var/datum/heretic_path/path = GLOB.heretic_paths[PATH_LEAD]
	var/list/numbers = list(
		/datum/eldritch_knowledge/base_lead = list("[HERETIC_LEAD_CURSE_LIMIT] заговоров", "[HERETIC_LEAD_CASINGS_PER_GRASP] штук", "по живой цели в [HERETIC_LEAD_FINGER_RANGE] клетках", "дробина на [HERETIC_LEAD_FINGER_DAMAGE] ушибов", "[HERETIC_LEAD_SMELT_SHEETS] листов железа или [HERETIC_LEAD_SMELT_RODS] прутьев", "[HERETIC_LEAD_SMELT_ROUNDS] патрона магазина - [HERETIC_LEAD_SMELT_MAGAZINE_LEAD]", "копится до [HERETIC_LEAD_RESERVE_CAP]"),
		/datum/eldritch_knowledge/spell/lead_named = list("[HERETIC_LEAD_NAMED_RANGE] клет", "[HERETIC_LEAD_HEAVY_BREAK_RANGE] клеток"),
		/datum/eldritch_knowledge/lead_mark = list("[HERETIC_LEAD_MARK_DAMAGE] ушибов", "[HERETIC_LEAD_MARK_BEND_RANGE] клетках"),
		/datum/eldritch_knowledge/lead_relic = list("[HERETIC_LEAD_REVOLVER_DAMAGE] ушибов", "ещё [HERETIC_LEAD_KILL_LEAD] Свинца", "за [HERETIC_LEAD_RELOAD_TIME / (1 SECONDS)] секунду дозаряжает"),
		/datum/eldritch_knowledge/spell/lead_ricochet = list("[HERETIC_LEAD_RICOCHET_RANGE] клеток", "[HERETIC_LEAD_SMOKE_TIME / (1 SECONDS)] секунды"),
		/datum/eldritch_knowledge/spell/lead_rain = list("[HERETIC_LEAD_RAIN_DAMAGE] ушибов", "[HERETIC_LEAD_RAIN_SLOW_TIME / (1 SECONDS)] секунды"),
	)
	for(var/knowledge_type in numbers)
		var/datum/eldritch_knowledge/knowledge = allocate(knowledge_type)
		for(var/fragment in numbers[knowledge_type])
			TEST_ASSERT(findtext(knowledge.desc, fragment), "[knowledge_type]: в описании есть «[fragment]».")
	TEST_ASSERT(findtext(path.capture_summary, "[HERETIC_LEAD_NAMED_COST] Свинца"), "Шапка захвата называет цену Пули с именем.")
	var/rules = jointext(lead.resource_rules, " ")
	for(var/fragment in list("[HERETIC_LEAD_RESERVE_CALM / (1 SECONDS)] секунд не получали", "раз в [HERETIC_LEAD_RESERVE_PERIOD / (1 SECONDS)] секунд, но не больше [HERETIC_LEAD_RESERVE_CAP]", "а убитый им человек - ещё [HERETIC_LEAD_KILL_LEAD]", "ложится на пояс, до [HERETIC_LEAD_BANDOLIER]", "за [HERETIC_LEAD_RELOAD_TIME / (1 SECONDS)] секунду дозаряжается", "в вашу сторону в [HERETIC_LEAD_UNDER_FIRE_RANGE] клетках", "от стрелка раз в [HERETIC_LEAD_UNDER_FIRE_COOLDOWN / (1 SECONDS)] секунду", "за [HERETIC_LEAD_SMELT_TIME / (1 SECONDS)] секунду", "Пуля с именем - [HERETIC_LEAD_NAMED_COST]", "дождь - [HERETIC_LEAD_RAIN_COST]"))
		TEST_ASSERT(findtext(rules, fragment), "Правила Свинца называют «[fragment]».")
	var/obj/item/heretic_path_relic/lead_revolver/revolver = /obj/item/heretic_path_relic/lead_revolver
	TEST_ASSERT(findtext(initial(revolver.desc), "бьёт на [HERETIC_LEAD_REVOLVER_DAMAGE] ушибов") && findtext(initial(revolver.desc), "оставляет [HERETIC_LEAD_BUTT_DAMAGE] ушибов") && HERETIC_LEAD_KILL_LEAD == 3, "Осмотр револьвера называет урон, удар рукоятью и «ещё три» за убийство.")
	var/datum/eldritch_knowledge/final_eldritch/lead_final/finale = allocate(/datum/eldritch_knowledge/final_eldritch/lead_final)
	finale.finished = TRUE
	finale.on_body_gain(new_body)
	TEST_ASSERT(lead.ascension_active, "Вознесение включает накопление Свинца.")
	lead.combat_resource = 0
	lead.on_life(new_body)
	TEST_ASSERT_EQUAL(lead.combat_resource, 1, "Вознёсшийся сам копит Свинец.")
	lead.on_life(new_body)
	TEST_ASSERT_EQUAL(lead.combat_resource, 1, "Свинец копится не чаще раза в 5 секунд.")
	finale.on_body_lose(new_body)
	TEST_ASSERT(!lead.ascension_active, "Снятое вознесение больше не копит Свинец.")

/// Числа в описаниях заклинаний пути совпадают с дефайнами и перезарядками.
/datum/unit_test/heretic_lead_spell_texts/Run()
	var/list/expected = list(
		/obj/effect/proc_holder/spell/pointed/heretic_lead/hex = list("[HERETIC_LEAD_HEX_RANGE] клеток", "[HERETIC_LEAD_HEX_TIME / (1 SECONDS)] секунд", "на [HERETIC_LEAD_JAM_TIME / (1 SECONDS)] секунды"),
		/obj/effect/proc_holder/spell/pointed/heretic_lead/named = list("За [HERETIC_LEAD_NAMED_COST] Свинца", "[HERETIC_LEAD_NAMED_RANGE] клеток", "[HERETIC_LEAD_HEAVY_TIME / (1 SECONDS)] секунд тяжелит", "на [HERETIC_LEAD_FALL_TIME / (1 SECONDS)] секунды", "за [HERETIC_CAPTURE_SHAKE_TIME / (1 SECONDS)] секунды", "дальше [HERETIC_LEAD_HEAVY_BREAK_RANGE] клеток"),
		/obj/effect/proc_holder/spell/pointed/heretic_lead/rain = list("За [HERETIC_LEAD_RAIN_COST] Свинца", "радиусом [HERETIC_LEAD_RAIN_RADIUS] клетки", "[HERETIC_LEAD_RAIN_RANGE] клеток", "[HERETIC_LEAD_RAIN_DAMAGE] ушибов", "на [HERETIC_LEAD_RAIN_SLOW_TIME / (1 SECONDS)] секунды"),
		/obj/effect/proc_holder/spell/self/heretic_lead/catch_bullet = list("в чужой хватке"),
		/obj/effect/proc_holder/spell/self/heretic_lead/ricochet = list("[HERETIC_LEAD_RICOCHET_MEMORY / (1 SECONDS)] секунд", "[HERETIC_LEAD_RICOCHET_RANGE] клеток", "[HERETIC_LEAD_SMOKE_TIME / (1 SECONDS)] секунды", "чужой хватки"),
	)
	for(var/spell_type in expected)
		var/obj/effect/proc_holder/spell/spell = spell_type
		var/desc = initial(spell.desc)
		for(var/fragment in expected[spell_type] + "Перезарядка [initial(spell.charge_max) / (1 SECONDS)] секунд")
			TEST_ASSERT(findtext(desc, fragment), "[spell_type]: в описании есть «[fragment]».")
	var/obj/effect/proc_holder/spell/pointed/heretic_lead/rain/rain = /obj/effect/proc_holder/spell/pointed/heretic_lead/rain
	TEST_ASSERT(findtext(initial(rain.desc), "Через 1,5 секунды") && HERETIC_LEAD_RAIN_DELAY == 1.5 SECONDS, "Дождь называет задержку удара.")
	var/obj/effect/proc_holder/spell/self/heretic_lead/catch_bullet/catching = /obj/effect/proc_holder/spell/self/heretic_lead/catch_bullet
	TEST_ASSERT(findtext(initial(catching.desc), "На 1,5 секунды") && HERETIC_LEAD_CATCH_TIME == 1.5 SECONDS, "Ловля пули называет своё окно.")

/// Вознёсшийся еретик Свинца в своём теле, с изученным финалом и его заклинаниями.
/datum/unit_test/proc/heretic_lead_ascended()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_LEAD)
	var/mob/living/carbon/human/user = heretic.owner.current
	heretic.gain_knowledge(/datum/eldritch_knowledge/final_eldritch/lead_final)
	var/datum/eldritch_knowledge/final_eldritch/lead_final/finale = heretic.get_knowledge(/datum/eldritch_knowledge/final_eldritch/lead_final)
	heretic.ascended = TRUE
	finale.finished = TRUE
	finale.on_body_gain(user)
	return list("heretic" = heretic, "user" = user, "lead" = heretic.get_knowledge(/datum/eldritch_knowledge/base_lead), "finale" = finale)

/// Три осечки в трёх разных общих местах станции: на них встанут тигли.
/datum/unit_test/proc/heretic_lead_test_misfires(datum/eldritch_knowledge/base_lead/lead)
	var/list/turf/spots = list(heretic_lead_test_spot(4, 4), heretic_lead_test_spot(0, 4), heretic_lead_test_spot(4, 0))
	var/list/area_types = list(/area/hallway/primary/fore, /area/hallway/primary/aft, /area/commons/lounge)
	for(var/index in 1 to length(spots))
		heretic_test_area(spots[index], area_types[index])
		lead.record_misfire_spot(spots[index])
	return spots

/datum/unit_test/proc/heretic_lead_test_douse(obj/structure/heretic_lead_crucible/crucible)
	var/datum/reagents/water = new(30)
	water.add_reagent(/datum/reagent/water, 30)
	water.reaction(crucible, TOUCH)
	qdel(water)

/// Литейные тигли встают на местах осечек; пока горит тигель, Шестизарядник стреляет даром; вода, жезл и оружие гасят их, последний снимает «На выстрел».
/datum/unit_test/heretic_lead_crucibles/Run()
	allocated += new /datum/heretic_test_station_level(run_loc_floor_bottom_left.z)
	var/list/fixture = heretic_lead_ascended()
	var/mob/living/carbon/human/user = fixture["user"]
	var/datum/antagonist/heretic/heretic = fixture["heretic"]
	var/datum/eldritch_knowledge/base_lead/lead = fixture["lead"]
	var/datum/eldritch_knowledge/final_eldritch/lead_final/finale = fixture["finale"]
	var/list/turf/spots = heretic_lead_test_misfires(lead)
	TEST_ASSERT(finale.raise_crucibles(user), "Вознесение ставит Литейные тигли.")
	TEST_ASSERT_EQUAL(length(finale.crucibles), HERETIC_LEAD_CRUCIBLES, "Встают три тигля.")
	for(var/obj/structure/heretic_lead_crucible/crucible as anything in finale.crucibles)
		TEST_ASSERT(get_turf(crucible) in spots, "Тигель стоит на месте осечки.")
		TEST_ASSERT(crucible.density && crucible.lit, "Тигель горит и загораживает клетку.")
	TEST_ASSERT(!finale.raise_crucibles(user), "Тигли встают один раз за вознесение.")
	TEST_ASSERT_NOTNULL(user.alerts[HERETIC_LEAD_CRUCIBLE_ALERT], "Вознёсшийся видит значок тиглей.")
	TEST_ASSERT(findtext(lead.combat_resource_state(), "тиглей горит: [HERETIC_LEAD_CRUCIBLES]"), "Панель ресурса считает тигли.")
	heretic.gain_knowledge(/datum/eldritch_knowledge/lead_relic)
	var/datum/eldritch_knowledge/lead_relic/recipe = heretic.get_knowledge(/datum/eldritch_knowledge/lead_relic)
	TEST_ASSERT(recipe.on_finished_recipe(user, list(), get_turf(user)), "Обряд создаёт Шестизарядник.")
	var/obj/item/heretic_path_relic/lead_revolver/revolver = recipe.new_path_relic_ref.resolve()
	allocated += revolver
	user.put_in_hands(revolver)
	lead.combat_resource = 0
	TEST_ASSERT(istype(revolver.fire_at(heretic_lead_test_spot(2, 4), user), /obj/item/projectile), "Пока горит тигель, Шестизарядник стреляет без Свинца.")
	TEST_ASSERT_EQUAL(lead.combat_resource, 0, "Выстрел у тигля Свинца не тратит.")
	var/obj/structure/heretic_lead_crucible/doused = finale.crucibles[1]
	var/mob/living/carbon/human/crew = heretic_lead_test_crew(heretic_lead_test_spot(2, 2))
	TEST_ASSERT(findtext(jointext(doused.examine(crew), " "), "струй"), "Осмотр называет, сколько струй осталось.")
	heretic_lead_test_douse(doused)
	heretic_lead_test_douse(doused)
	TEST_ASSERT(doused.lit && doused.douses == 1, "Брызги одной струи считаются за одну.")
	for(var/index in 2 to HERETIC_LEAD_CRUCIBLE_DOUSES)
		COOLDOWN_RESET(doused, douse_gap)
		heretic_lead_test_douse(doused)
	TEST_ASSERT(!doused.lit && doused.icon_state == "lead_crucible_cold", "Три струи остужают тигель.")
	TEST_ASSERT_EQUAL(finale.lit_crucibles(), HERETIC_LEAD_CRUCIBLES - 1, "Остывший тигель уходит из счёта.")
	var/obj/structure/heretic_lead_crucible/rodded = finale.crucibles[2]
	var/obj/item/nullrod/rod = allocate(/obj/item/nullrod)
	crew.put_in_hands(rod)
	rod.melee_attack_chain(crew, rodded)
	TEST_ASSERT(!QDELETED(rodded), "Один удар жезлом тигель не раскалывает.")
	rod.melee_attack_chain(crew, rodded)
	TEST_ASSERT(QDELETED(rodded), "Второй удар жезлом раскалывает тигель.")
	TEST_ASSERT(locate(/obj/effect/proc_holder/spell/self/heretic_lead/to_shot) in finale.ascension_spell_instances, "Пока тигель горит, «На выстрел» на месте.")
	var/obj/structure/heretic_lead_crucible/last = finale.crucibles[2]
	last.take_damage(HERETIC_LEAD_CRUCIBLE_INTEGRITY, BRUTE, MELEE, FALSE)
	TEST_ASSERT(QDELETED(last), "Оружие разбивает тигель.")
	TEST_ASSERT(finale.crucibles_spent, "Последний погасший тигель кончает их силу.")
	TEST_ASSERT_NULL(locate(/obj/effect/proc_holder/spell/self/heretic_lead/to_shot) in finale.ascension_spell_instances, "Без тиглей «На выстрел» пропадает.")
	TEST_ASSERT(!(/obj/effect/proc_holder/spell/self/heretic_lead/to_shot in finale.ascension_spells), "«На выстрел» не вернётся с новым телом.")
	TEST_ASSERT_NULL(user.alerts[HERETIC_LEAD_CRUCIBLE_ALERT], "Значок тиглей гаснет.")
	TEST_ASSERT(findtext(finale.to_shot_block_reason(user), "погасли"), "Без тиглей на выстрел не уйти.")
	COOLDOWN_RESET(revolver, shot_cooldown)
	TEST_ASSERT(!revolver.fire_at(heretic_lead_test_spot(2, 4), user), "Без тиглей пустой барабан снова щёлкает.")

/// Тигли встают только в общих местах станции: осечка в закрытом отсеке или на шаттле ставит тигель в ближайшем коридоре, и станции называют отсек.
/datum/unit_test/heretic_lead_crucibles_public/Run()
	allocated += new /datum/heretic_test_station_level(run_loc_floor_bottom_left.z)
	var/list/fixture = heretic_lead_ascended()
	var/mob/living/carbon/human/user = fixture["user"]
	var/datum/eldritch_knowledge/base_lead/lead = fixture["lead"]
	var/datum/eldritch_knowledge/final_eldritch/lead_final/finale = fixture["finale"]
	var/turf/armory = heretic_lead_test_spot(4, 4)
	var/turf/hall = heretic_lead_test_spot(2, 4)
	var/turf/docked = heretic_lead_test_spot(0, 0)
	var/turf/aft = heretic_lead_test_spot(0, 2)
	var/turf/lounge = heretic_lead_test_spot(4, 0)
	heretic_test_area(armory, /area/ai_monitored/security/armory)
	heretic_test_area(hall, /area/hallway/primary/fore)
	heretic_test_area(docked, /area/shuttle/escape)
	heretic_test_area(aft, /area/hallway/primary/aft)
	heretic_test_area(lounge, /area/commons/lounge)
	lead.record_misfire_spot(lounge)
	lead.record_misfire_spot(docked)
	lead.record_misfire_spot(armory)
	var/list/spots = finale.crucible_spots(user, lead)
	TEST_ASSERT(!(armory in spots) && !(docked in spots), "Ни в оружейной, ни на шаттле тигля нет.")
	TEST_ASSERT((hall in spots) && (aft in spots) && (lounge in spots), "Тигли встают в ближайших общих местах.")
	TEST_ASSERT(findtext(spots[hall], get_area_name(armory, TRUE)), "Станции называют отсек осечки: [spots[hall]]")
	TEST_ASSERT_EQUAL(spots[lounge], get_area_name(lounge, TRUE), "Тигель на месте осечки зовётся по своему месту.")
	var/turf/bar = heretic_lead_test_spot(2, 0)
	var/turf/vacant = heretic_lead_test_spot(3, 0)
	heretic_test_area(bar, /area/service/bar)
	heretic_test_area(vacant, /area/commons/vacant_room)
	TEST_ASSERT(finale.crucible_spot_valid(bar, FALSE), "Бар - общий отсек и для тигля, как у других путей.")
	TEST_ASSERT(!finale.crucible_spot_valid(vacant, FALSE), "Пустующая каюта тигля не принимает.")

/// Смерть вознёсшегося остужает тигли, снятие роли убирает их.
/datum/unit_test/heretic_lead_crucibles_lifecycle/Run()
	allocated += new /datum/heretic_test_station_level(run_loc_floor_bottom_left.z)
	var/list/fixture = heretic_lead_ascended()
	var/mob/living/carbon/human/user = fixture["user"]
	var/datum/antagonist/heretic/heretic = fixture["heretic"]
	var/datum/eldritch_knowledge/final_eldritch/lead_final/finale = fixture["finale"]
	heretic_lead_test_misfires(fixture["lead"])
	TEST_ASSERT(finale.raise_crucibles(user), "Тигли встают.")
	var/list/obj/structure/heretic_lead_crucible/crucibles = finale.crucibles.Copy()
	finale.on_death(user)
	TEST_ASSERT(finale.crucibles_spent && !finale.lit_crucibles(), "Со смертью вознёсшегося тигли остывают.")
	qdel(heretic)
	for(var/obj/structure/heretic_lead_crucible/crucible as anything in crucibles)
		TEST_ASSERT(QDELETED(crucible), "Снятие роли убирает тигли.")
	var/list/gibbed_fixture = heretic_lead_ascended()
	var/datum/eldritch_knowledge/final_eldritch/lead_final/gibbed_finale = gibbed_fixture["finale"]
	heretic_lead_test_misfires(gibbed_fixture["lead"])
	TEST_ASSERT(gibbed_finale.raise_crucibles(gibbed_fixture["user"]), "Тигли второго вознёсшегося встают.")
	qdel(gibbed_fixture["user"])
	TEST_ASSERT(wait_for_var(gibbed_finale, NAMEOF(gibbed_finale, crucibles_spent), TRUE), "Уничтоженное тело вознёсшегося гасит тигли.")
	TEST_ASSERT(!gibbed_finale.lit_crucibles(), "Ни один тигель не горит без вознёсшегося.")

/// «На выстрел» за секунду уводит к стрелку последнего выстрела из огнестрела; лазер не зовёт, старый выстрел не годится.
/datum/unit_test/heretic_lead_to_shot/Run()
	allocated += new /datum/heretic_test_station_level(run_loc_floor_bottom_left.z)
	var/list/fixture = heretic_lead_ascended()
	var/mob/living/carbon/human/user = fixture["user"]
	var/datum/eldritch_knowledge/final_eldritch/lead_final/finale = fixture["finale"]
	heretic_lead_test_misfires(fixture["lead"])
	TEST_ASSERT(finale.raise_crucibles(user), "Тигли встают.")
	var/obj/effect/proc_holder/spell/self/heretic_lead/to_shot/spell = locate() in finale.ascension_spell_instances
	TEST_ASSERT_NOTNULL(spell, "Вознёсшийся получает «На выстрел».")
	TEST_ASSERT(findtext(finale.to_shot_block_reason(user), "никто не стрелял"), "Без выстрела переноса нет.")
	var/turf/origin = get_turf(user)
	var/mob/living/carbon/human/crew = heretic_lead_test_crew(heretic_lead_test_spot(3, 2))
	var/obj/item/gun/energy/laser/laser = allocate(/obj/item/gun/energy/laser, get_turf(crew))
	crew.put_in_hands(laser)
	laser.process_fire(heretic_lead_test_spot(3, 4), crew)
	TEST_ASSERT(findtext(finale.to_shot_block_reason(user), "никто не стрелял"), "Лазер вознёсшегося не зовёт.")
	crew.dropItemToGround(laser)
	var/obj/item/gun/ballistic/automatic/toy/pistol/unrestricted/toy = allocate(/obj/item/gun/ballistic/automatic/toy/pistol/unrestricted, get_turf(crew))
	crew.put_in_hands(toy)
	toy.process_fire(heretic_lead_test_spot(3, 4), crew)
	TEST_ASSERT(findtext(finale.to_shot_block_reason(user), "никто не стрелял"), "Игрушечный выстрел вознёсшегося не зовёт.")
	crew.dropItemToGround(toy)
	var/obj/item/gun/ballistic/automatic/pistol/gun = allocate(/obj/item/gun/ballistic/automatic/pistol, get_turf(crew))
	crew.put_in_hands(gun)
	gun.process_fire(heretic_lead_test_spot(3, 4), crew)
	TEST_ASSERT_EQUAL(finale.last_shooter?.resolve(), crew, "Выстрел из огнестрела слышен.")
	TEST_ASSERT(spell.can_cast(user, FALSE, TRUE), "Есть свежий выстрел - перенос доступен: [finale.to_shot_block_reason(user)]")
	spell.cast(list(user), user)
	TEST_ASSERT(get_turf(user) != origin && get_dist(user, crew) <= 1, "Еретик стоит рядом со стрелком.")
	var/obj/effect/temp_visual/heretic_lead/smoke/smoke = locate() in origin
	TEST_ASSERT(smoke?.opacity, "На прежнем месте пороховой дым.")
	finale.last_shot_at = world.time - HERETIC_LEAD_SHOT_MEMORY - 1
	TEST_ASSERT(findtext(finale.to_shot_block_reason(user), "никто не стрелял"), "Выстрел старше пятнадцати секунд не зовёт.")

/// Последний залп берёт на прицел видимых врагов и через полторы секунды бьёт их; ушедшего за угол достаёт рикошет вполовину силы, укрытого со всех сторон - ничто; союзник цел.
/datum/unit_test/heretic_lead_final_volley/Run()
	var/list/fixture = heretic_lead_ascended()
	var/mob/living/carbon/human/user = fixture["user"]
	var/datum/eldritch_knowledge/final_eldritch/lead_final/finale = fixture["finale"]
	var/obj/effect/proc_holder/spell/self/heretic_lead/final_volley/spell = locate() in finale.ascension_spell_instances
	TEST_ASSERT_NOTNULL(spell, "Вознёсшийся получает Последний залп.")
	TEST_ASSERT(!finale.volley(user) && findtext(finale.volley_failure, "не видно врагов"), "Без целей залпа нет.")
	var/mob/living/carbon/human/near = heretic_lead_test_crew(heretic_lead_test_spot(3, 0))
	var/mob/living/carbon/human/hiding = heretic_lead_test_crew(heretic_lead_test_spot(0, 4))
	var/mob/living/carbon/human/boxed = heretic_lead_test_crew(heretic_lead_test_spot(3, 3))
	var/datum/antagonist/heretic/ally = allocate_heretic(heretic_lead_test_spot(-1, 0))
	TEST_ASSERT_EQUAL(length(finale.volley_targets(user)), 3, "Залп берёт всех врагов и не берёт союзника.")
	user.Stun(5 SECONDS)
	TEST_ASSERT(user.incapacitated(), "Вознёсшийся оглушён.")
	TEST_ASSERT(spell.can_cast(user, FALSE, TRUE), "Оглушение не глушит вознёсшегося: [spell.heretic_failure_reason]")
	spell.cast(list(user), user)
	user.SetStun(0)
	TEST_ASSERT(finale.volley_timer, "Линии прицела висят до выстрела.")
	TEST_ASSERT_EQUAL(near.getBruteLoss(), 0, "До выстрела урона нет.")
	allocate(/obj/structure/window/reinforced/fulltile, heretic_lead_test_spot(0, 2))
	for(var/direction in GLOB.alldirs)
		allocate(/obj/structure/window/reinforced/fulltile, get_step(boxed, direction))
	TEST_ASSERT(heretic_lead_test_wait(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(heretic_lead_test_brute_at_least), near, HERETIC_LEAD_VOLLEY_DAMAGE), 4 SECONDS, "Последний залп"), "Пуля залпа попадает в цель на линии.")
	TEST_ASSERT(heretic_lead_test_wait(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(heretic_lead_test_brute_at_least), hiding, round(HERETIC_LEAD_VOLLEY_DAMAGE / 2) - 1), 2 SECONDS, "рикошет залпа"), "Ушедшего за окно пуля достаёт рикошетом от стены.")
	TEST_ASSERT(hiding.getBruteLoss() < HERETIC_LEAD_VOLLEY_DAMAGE - 1, "Рикошет бьёт вполовину силы: [hiding.getBruteLoss()]")
	TEST_ASSERT_EQUAL(boxed.getBruteLoss(), 0, "Укрытого со всех сторон пуля не находит.")
	TEST_ASSERT_EQUAL(ally.owner.current.getBruteLoss(), 0, "Союзника залп не трогает.")

/// Урок Свинца проходит десять шагов настоящими действиями: гильзы, Палец-ствол, Переплавка, заговор, Пуля с именем, Ловля пули под огнём, Рикошет, выбор Школы, Тяжёлая пуля из барабана, Последний патрон.
/datum/unit_test/heretic_lead_lesson/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_LEAD)
	var/mob/living/carbon/human/user = heretic.owner.current
	user.forceMove(heretic_lead_test_spot(0, 2))
	var/datum/eldritch_knowledge/base_lead/lead = heretic.get_knowledge(/datum/eldritch_knowledge/base_lead)
	var/mob/living/carbon/human/target = heretic_lead_test_crew(heretic_lead_test_spot(2, 4))
	var/datum/heretic_lead_lesson/lesson = new(null, lead, user, target)
	allocated += lesson
	var/datum/eldritch_knowledge/spell/lead_catch/catching = heretic.get_knowledge(/datum/eldritch_knowledge/spell/lead_catch)
	TEST_ASSERT(catching && heretic.get_knowledge(/datum/eldritch_knowledge/lead_grasp) && heretic.get_knowledge(/datum/eldritch_knowledge/spell/lead_named) && heretic.get_knowledge(/datum/eldritch_knowledge/spell/lead_ricochet), "Урок открывает Отдачу, Пулю с именем, Ловлю пули и Рикошет.")
	var/obj/item/heretic_path_relic/lead_revolver/revolver = locate() in user.held_items
	TEST_ASSERT_NOTNULL(revolver, "Урок даёт Шестизарядник в руку.")
	allocated += revolver
	user.a_intent = INTENT_HELP
	var/obj/item/ammo_casing/casing = locate() in orange(1, user)
	TEST_ASSERT_NOTNULL(casing, "Урок кладёт гильзы рядом.")
	var/obj/item/melee/touch_attack/mansus_fist/fist = allocate(/obj/item/melee/touch_attack/mansus_fist)
	fist.afterattack(casing, user, TRUE)
	TEST_ASSERT_EQUAL(lesson.stage, 2, "Гильзы открывают Палец-ствол.")
	user.a_intent = INTENT_HARM
	fist = allocate(/obj/item/melee/touch_attack/mansus_fist)
	fist.afterattack(target, user, FALSE)
	var/obj/item/projectile/bullet/heretic_lead_pellet/pellet = locate() in range(HERETIC_LEAD_FINGER_RANGE, user)
	TEST_ASSERT_NOTNULL(pellet, "Палец-ствол стреляет в мишень.")
	heretic_lead_test_fly(pellet)
	TEST_ASSERT_EQUAL(lesson.stage, 3, "Дробина в мишени открывает Переплавку.")
	var/obj/item/stack/sheet/metal/sheets = locate() in orange(1, user)
	TEST_ASSERT_NOTNULL(sheets, "Урок кладёт железо рядом.")
	user.a_intent = INTENT_HELP
	fist = allocate(/obj/item/melee/touch_attack/mansus_fist)
	fist.afterattack(sheets, user, TRUE)
	TEST_ASSERT_EQUAL(lesson.stage, 4, "Переплавка открывает заговор.")
	var/obj/item/gun/ballistic/shotgun/rifle = locate() in orange(1, user)
	TEST_ASSERT_NOTNULL(rifle, "Урок кладёт ружьё рядом.")
	fist = allocate(/obj/item/melee/touch_attack/mansus_fist)
	fist.afterattack(rifle, user, TRUE)
	TEST_ASSERT_EQUAL(lesson.stage, 5, "Заговор открывает Пулю с именем.")
	TEST_ASSERT(lead.combat_resource >= HERETIC_LEAD_NAMED_COST, "На Пулю с именем хватает Свинца.")
	heretic_lead_test_fly(lead.fire_named(user, target), 2)
	TEST_ASSERT_EQUAL(lesson.stage, 6, "Пуля с именем открывает Ловлю пули.")
	var/mob/living/gunner = lesson.gunner_ref?.resolve()
	TEST_ASSERT_NOTNULL(gunner, "Выходит учебный стрелок.")
	TEST_ASSERT(lead.hex(user, gunner), "Сглаз ствола на учебного стрелка: [lead.lead_failure]")
	TEST_ASSERT_NULL(lesson.drill_shot(), "Сглаженный пистолет стрелка даёт осечку.")
	TEST_ASSERT_EQUAL(lesson.stage, 6, "Одного Сглаза шагу мало: нужна и Ловля.")
	catching.granted_spell.cast(list(user), user)
	var/brute_before = user.getBruteLoss()
	heretic_lead_test_fly(lesson.drill_shot())
	TEST_ASSERT_EQUAL(user.getBruteLoss(), brute_before, "Пойманная пуля стрелка не ранит.")
	TEST_ASSERT_EQUAL(lesson.stage, 7, "Ловля после Сглаза открывает Рикошет.")
	TEST_ASSERT(wait_for_qdeleted(gunner, 3 SECONDS), "Учебный стрелок уходит.")
	COOLDOWN_RESET(revolver, shot_cooldown)
	heretic_lead_test_fly(revolver.fire_at(heretic_lead_test_spot(6, 2), user))
	TEST_ASSERT(lead.ricochet(user), "Рикошет к удару своей пули: [lead.lead_failure]")
	TEST_ASSERT_EQUAL(lesson.stage, 8, "Рикошет открывает выбор Школы.")
	TEST_ASSERT_NOTNULL(locate(/obj/effect/proc_holder/spell/self/heretic_lead/school) in user.mind.spell_list, "На уроке есть кнопка «Школа стрельбы».")
	TEST_ASSERT(lead.choose_school(user, HERETIC_LEAD_SCHOOL_GUNSLINGER), "Учебная Школа: [lead.lead_failure]")
	TEST_ASSERT_EQUAL(lesson.stage, 9, "Школа открывает барабан.")
	TEST_ASSERT(revolver.select_chamber(user, 2), "Alt-клик ставит под курок Тяжёлую.")
	COOLDOWN_RESET(revolver, drum_turn)
	COOLDOWN_RESET(revolver, shot_cooldown)
	var/obj/item/projectile/heavy = revolver.fire_at(target, user)
	TEST_ASSERT(istype(heavy, /obj/item/projectile/bullet/heretic_lead/heavy), "Из Тяжёлой каморы летит Тяжёлая пуля.")
	heretic_lead_test_fly(heavy, 2)
	TEST_ASSERT_EQUAL(lesson.stage, 10, "Тяжёлая пуля в мишени открывает Последний патрон.")
	target.SetKnockdown(0)
	TEST_ASSERT_EQUAL(lead.combat_resource, lead.combat_resource_max, "Для Последнего патрона барабан полон.")
	COOLDOWN_RESET(revolver, shot_cooldown)
	TEST_ASSERT(heretic_lead_test_arm_sixth(revolver, user), "Alt-клик взводит Шестую камору.")
	TEST_ASSERT(revolver.fire_at(target, user), "Выстрел в мишень со взведённой Шестой - Последний патрон.")
	TEST_ASSERT(heretic_lead_test_wait(CALLBACK(lesson, TYPE_PROC_REF(/datum/heretic_lead_lesson, finished)), 3 SECONDS, "Последний патрон урока"), "Урок пройден.")
	TEST_ASSERT_EQUAL(length(lesson.steps()), 10, "В уроке десять шагов.")
	qdel(lesson)
	TEST_ASSERT(QDELETED(rifle), "Реквизит урока убирается вместе с ним.")

/// Числа в кодексе вознесения, заклинаниях и осмотре тигля совпадают с дефайнами.
/datum/unit_test/heretic_lead_ascension_texts/Run()
	var/datum/eldritch_knowledge/final_eldritch/lead_final/finale = allocate(/datum/eldritch_knowledge/final_eldritch/lead_final)
	var/details = jointext(finale.details, " ")
	for(var/fragment in list("Встают [HERETIC_LEAD_CRUCIBLES] Литейных", "к стрелку последнего выстрела за [HERETIC_LEAD_SHOT_MEMORY / (1 SECONDS)] секунд", "перезарядка [HERETIC_LEAD_TO_SHOT_COOLDOWN / (1 SECONDS)] секунд", "[HERETIC_LEAD_CRUCIBLE_DOUSES] струи", "([HERETIC_LEAD_CRUCIBLE_INTEGRITY] прочности)", "до [HERETIC_LEAD_VOLLEY_TARGETS] врагов в [HERETIC_LEAD_VOLLEY_RANGE] клетках", "пуля на [HERETIC_LEAD_VOLLEY_DAMAGE] ушибов", "перезарядка [HERETIC_LEAD_VOLLEY_COOLDOWN / (1 SECONDS)] секунд", "раз в [HERETIC_LEAD_ASCENDED_REGEN / (1 SECONDS)] секунд"))
		TEST_ASSERT(findtext(details, fragment), "Кодекс вознесения называет «[fragment]».")
	TEST_ASSERT(findtext(details, "1,5 секунды") && HERETIC_LEAD_VOLLEY_DELAY == 1.5 SECONDS, "Кодекс называет время линий прицела.")
	TEST_ASSERT(findtext(details, "за 1 секунду") && HERETIC_LEAD_TO_SHOT_TIME == 1 SECONDS, "Кодекс называет время переноса.")
	var/obj/effect/proc_holder/spell/self/heretic_lead/final_volley/volley = /obj/effect/proc_holder/spell/self/heretic_lead/final_volley
	var/volley_desc = initial(volley.desc)
	TEST_ASSERT(findtext(volley_desc, "до [HERETIC_LEAD_VOLLEY_TARGETS] видимых") && findtext(volley_desc, "[HERETIC_LEAD_VOLLEY_RANGE] клеток") && findtext(volley_desc, "[HERETIC_LEAD_VOLLEY_DAMAGE] ушибов") && findtext(volley_desc, "Перезарядка [HERETIC_LEAD_VOLLEY_COOLDOWN / (1 SECONDS)] секунд"), "Последний залп называет цели, дальность, урон и перезарядку.")
	var/obj/effect/proc_holder/spell/self/heretic_lead/to_shot/to_shot = /obj/effect/proc_holder/spell/self/heretic_lead/to_shot
	var/to_shot_desc = initial(to_shot.desc)
	TEST_ASSERT(findtext(to_shot_desc, "[HERETIC_LEAD_SHOT_MEMORY / (1 SECONDS)] секунд") && findtext(to_shot_desc, "Перезарядка [HERETIC_LEAD_TO_SHOT_COOLDOWN / (1 SECONDS)] секунд"), "«На выстрел» называет память выстрела и перезарядку.")
	var/obj/structure/heretic_lead_crucible/crucible = /obj/structure/heretic_lead_crucible
	TEST_ASSERT(findtext(initial(crucible.desc), "тремя струями") && HERETIC_LEAD_CRUCIBLE_DOUSES == 3, "Осмотр тигля называет число струй.")
	TEST_ASSERT(findtext(initial(crucible.desc), "за два удара"), "Осмотр тигля называет удары жезлом.")

/// Шестизарядник Свинца в руке еретика.
/datum/unit_test/proc/heretic_lead_test_revolver(datum/antagonist/heretic/heretic, mob/living/user)
	if(!heretic.get_knowledge(/datum/eldritch_knowledge/lead_relic))
		heretic.gain_knowledge(/datum/eldritch_knowledge/lead_relic)
	var/datum/eldritch_knowledge/lead_relic/recipe = heretic.get_knowledge(/datum/eldritch_knowledge/lead_relic)
	if(recipe.new_path_relic_available())
		recipe.on_finished_recipe(user, list(), get_turf(user))
	var/obj/item/heretic_path_relic/lead_revolver/revolver = recipe.new_path_relic_ref.resolve()
	allocated += revolver
	user.put_in_hands(revolver)
	return revolver

/// Шестая камора под курок, как выбором в радиальном меню, и револьвер готов к выстрелу.
/datum/unit_test/proc/heretic_lead_test_arm_sixth(obj/item/heretic_path_relic/lead_revolver/revolver, mob/living/user)
	var/datum/eldritch_knowledge/base_lead/lead = revolver.owner_lead(user)
	if(!revolver.select_chamber(user, HERETIC_LEAD_CAPACITY))
		return FALSE
	COOLDOWN_RESET(revolver, drum_turn)
	COOLDOWN_RESET(revolver, shot_cooldown)
	return lead.sixth_cocked()

/proc/heretic_lead_test_no_last_round(turf/center)
	return !(locate(/obj/item/projectile/bullet/heretic_lead/last_round) in range(7, center))

/proc/heretic_lead_test_near(atom/first, atom/second)
	return get_dist(first, second) <= 1 && get_turf(first) != get_turf(second)

/// Запах пороха: цель охоты и меченый, которые не видят еретика в 7 клетках, слышат щелчок; на виду - нет; повтор не сразу.
/datum/unit_test/heretic_lead_powder_scent/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_LEAD)
	var/mob/living/carbon/human/user = heretic.owner.current
	heretic.gain_knowledge(/datum/eldritch_knowledge/lead_mark)
	var/datum/eldritch_knowledge/base_lead/lead = heretic.get_knowledge(/datum/eldritch_knowledge/base_lead)
	var/mob/living/carbon/human/prey = heretic_lead_test_crew(heretic_lead_test_spot(4, 0))
	heretic.set_hunt_target(prey.mind)
	TEST_ASSERT(!length(lead.powder_scent()), "Цель охоты, которая видит еретика, щелчков не слышит.")
	allocate(/obj/structure/falsewall, heretic_lead_test_spot(2, 0))
	lead.on_life(user)
	TEST_ASSERT(!COOLDOWN_FINISHED(lead, powder_scent), "Цель охоты за стеной слышит щелчок курка.")
	TEST_ASSERT(!length(lead.powder_scent()), "Повтор не сразу.")
	COOLDOWN_RESET(lead, powder_scent)
	TEST_ASSERT(prey in lead.powder_scent(), "После паузы щелчок слышен снова.")
	COOLDOWN_RESET(lead, powder_scent)
	var/mob/living/carbon/human/marked = heretic_lead_test_crew(heretic_lead_test_spot(4, 4))
	var/mob/living/carbon/human/stranger = heretic_lead_test_crew(heretic_lead_test_spot(0, 4))
	marked.apply_status_effect(/datum/status_effect/eldritch/lead, lead)
	allocate(/obj/structure/falsewall, heretic_lead_test_spot(2, 2))
	allocate(/obj/structure/falsewall, heretic_lead_test_spot(0, 2))
	var/list/heard = lead.powder_scent()
	TEST_ASSERT((marked in heard) && (prey in heard), "Меченый тоже чует порох.")
	TEST_ASSERT(!(stranger in heard), "Посторонний за стеной ничего не слышит.")

/// Счёт камор: вблизи от еретика с 4 Свинца тянет порохом, с полным барабаном - щёлкает курок; издалека и с малым запасом не видно.
/datum/unit_test/heretic_lead_chamber_scent/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_LEAD)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_lead/lead = heretic.get_knowledge(/datum/eldritch_knowledge/base_lead)
	var/mob/living/carbon/human/crew = heretic_lead_test_crew(get_step(user, EAST))
	var/mob/living/carbon/human/far = heretic_lead_test_crew(heretic_lead_test_spot(4, 4))
	lead.combat_resource = HERETIC_LEAD_SCENT_SHOWN - 1
	TEST_ASSERT(!findtext(jointext(user.examine(crew), " "), "порохом"), "С малым запасом порохом не пахнет.")
	lead.combat_resource = HERETIC_LEAD_SCENT_SHOWN
	TEST_ASSERT(findtext(jointext(user.examine(crew), " "), "Тянет порохом"), "С 4 Свинца вблизи тянет порохом.")
	TEST_ASSERT(!findtext(jointext(user.examine(far), " "), "порохом"), "Издалека запаха не слышно.")
	lead.combat_resource = HERETIC_LEAD_CAPACITY
	TEST_ASSERT(findtext(jointext(user.examine(crew), " "), "барабан полон"), "Полный барабан выдаёт себя щелчком курка.")

/// Шестая камора: со Слухом стрелка полный барабан делает выстрел в человека Последним патроном - прицел, затем пуля сквозь двоих; лёгший цел, выронивший револьвер барабан не тратит.
/datum/unit_test/heretic_lead_last_round/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_LEAD)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_lead/lead = heretic.get_knowledge(/datum/eldritch_knowledge/base_lead)
	var/obj/item/heretic_path_relic/lead_revolver/revolver = heretic_lead_test_revolver(heretic, user)
	var/mob/living/carbon/human/first = heretic_lead_test_crew(heretic_lead_test_spot(2, 0))
	var/mob/living/carbon/human/second = heretic_lead_test_crew(heretic_lead_test_spot(3, 0))
	var/mob/living/carbon/human/third = heretic_lead_test_crew(heretic_lead_test_spot(4, 0))
	lead.combat_resource = HERETIC_LEAD_CAPACITY
	TEST_ASSERT(!lead.last_round_ready(), "Без Слуха стрелка Шестой каморы нет.")
	heretic.gain_knowledge(/datum/eldritch_knowledge/lead_ear)
	lead.combat_resource = HERETIC_LEAD_CAPACITY - 1
	var/obj/item/projectile/plain = revolver.fire_at(heretic_lead_test_spot(2, 4), user)
	TEST_ASSERT(plain?.type == /obj/item/projectile/bullet/heretic_lead, "Неполный барабан стреляет обычной пулей.")
	lead.combat_resource = HERETIC_LEAD_CAPACITY
	COOLDOWN_RESET(revolver, shot_cooldown)
	TEST_ASSERT(heretic_lead_test_arm_sixth(revolver, user), "Шестая камора взводится Alt-кликом.")
	TEST_ASSERT(revolver.fire_at(first, user) == TRUE, "Взведённая Шестая камора даёт Последний патрон.")
	TEST_ASSERT(revolver.aim_timer && revolver.aim_ref?.resolve() == first, "Цель взята на прицел.")
	TEST_ASSERT(findtext(lead.combat_resource_state(), "Шестая камора"), "Панель ресурса называет Шестую камору.")
	TEST_ASSERT_EQUAL(first.getBruteLoss(), 0, "До выстрела урона нет.")
	TEST_ASSERT_EQUAL(lead.combat_resource, HERETIC_LEAD_CAPACITY, "Барабан тратится только в миг выстрела.")
	COOLDOWN_RESET(revolver, shot_cooldown)
	TEST_ASSERT(!revolver.fire_at(third, user), "Пока курок взведён, второго выстрела нет.")
	TEST_ASSERT(heretic_lead_test_wait(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(heretic_lead_test_brute_at_least), second, HERETIC_LEAD_LAST_ROUND_DAMAGE - 1), 4 SECONDS, "Последний патрон"), "Последний патрон пробивает первого и попадает во второго.")
	TEST_ASSERT(first.getBruteLoss() >= HERETIC_LEAD_LAST_ROUND_DAMAGE - 1, "Первый на линии ранен.")
	TEST_ASSERT(first.IsKnockdown() && second.IsKnockdown(), "Последний патрон сбивает с ног.")
	TEST_ASSERT(heretic_lead_test_wait(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(heretic_lead_test_no_last_round), get_turf(user)), 2 SECONDS, "полёт Последнего патрона"), "Последний патрон долетел.")
	TEST_ASSERT_EQUAL(third.getBruteLoss(), 0, "Третьего на линии Последний патрон не достаёт.")
	TEST_ASSERT_EQUAL(lead.combat_resource, 0, "Последний патрон забирает весь барабан.")
	TEST_ASSERT(!revolver.aim_timer && !revolver.aim_dot, "Точка гаснет после выстрела.")
	var/mob/living/carbon/human/prone = heretic_lead_test_crew(heretic_lead_test_spot(0, 4))
	lead.combat_resource = HERETIC_LEAD_CAPACITY
	COOLDOWN_RESET(revolver, shot_cooldown)
	TEST_ASSERT(!lead.sixth_cocked(), "Ушедший Последний патрон снимает Шестую с курка.")
	TEST_ASSERT(heretic_lead_test_arm_sixth(revolver, user), "Шестая камора взводится снова.")
	TEST_ASSERT(revolver.fire_at(prone, user), "Последний патрон берёт новую цель.")
	prone.set_resting(TRUE, TRUE)
	TEST_ASSERT(wait_for_var(lead, NAMEOF(lead, combat_resource), 0, 3 SECONDS), "Последний патрон ушёл.")
	TEST_ASSERT(heretic_lead_test_wait(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(heretic_lead_test_no_last_round), get_turf(user)), 2 SECONDS, "полёт Последнего патрона"), "Последний патрон долетел.")
	TEST_ASSERT_EQUAL(prone.getBruteLoss(), 0, "Лёгшего Последний патрон не находит.")
	lead.combat_resource = HERETIC_LEAD_CAPACITY
	COOLDOWN_RESET(revolver, shot_cooldown)
	prone.set_resting(FALSE, TRUE)
	TEST_ASSERT(heretic_lead_test_arm_sixth(revolver, user), "Шестая камора взведена.")
	TEST_ASSERT(revolver.fire_at(prone, user), "Последний патрон взведён.")
	user.dropItemToGround(revolver)
	TEST_ASSERT(heretic_lead_test_wait(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(heretic_lead_test_var_null), revolver, NAMEOF(revolver, aim_timer)), 3 SECONDS, "срыв Последнего патрона"), "Взведённый курок спущен.")
	TEST_ASSERT_EQUAL(lead.combat_resource, HERETIC_LEAD_CAPACITY, "Выроненный револьвер барабан не тратит.")
	TEST_ASSERT_EQUAL(prone.getBruteLoss(), 0, "Сорванный Последний патрон никого не ранит.")

/// Последний патрон своим ходом: первая цель в 3 клетках, вторая через пустую клетку за ней - обе ранены и сбиты.
/datum/unit_test/heretic_lead_last_round_pierce/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_LEAD)
	var/mob/living/carbon/human/user = heretic.owner.current
	user.forceMove(heretic_lead_test_spot(0, 2))
	heretic.gain_knowledge(/datum/eldritch_knowledge/lead_ear)
	var/datum/eldritch_knowledge/base_lead/lead = heretic.get_knowledge(/datum/eldritch_knowledge/base_lead)
	var/obj/item/heretic_path_relic/lead_revolver/revolver = heretic_lead_test_revolver(heretic, user)
	var/mob/living/carbon/human/first = heretic_lead_test_crew(heretic_lead_test_spot(3, 2))
	var/mob/living/carbon/human/second = heretic_lead_test_crew(heretic_lead_test_spot(5, 2))
	first.setDir(WEST)
	second.setDir(WEST)
	lead.combat_resource = HERETIC_LEAD_CAPACITY
	TEST_ASSERT(heretic_lead_test_arm_sixth(revolver, user), "Шестая камора взведена.")
	TEST_ASSERT(revolver.fire_at(first, user) == TRUE, "Взведённая Шестая камора даёт Последний патрон.")
	TEST_ASSERT(wait_for_var(lead, NAMEOF(lead, combat_resource), 0, 3 SECONDS), "Последний патрон ушёл.")
	TEST_ASSERT(heretic_lead_test_wait(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(heretic_lead_test_no_last_round), get_turf(user)), 2 SECONDS, "полёт Последнего патрона"), "Последний патрон долетел.")
	TEST_ASSERT(first.getBruteLoss() >= HERETIC_LEAD_LAST_ROUND_DAMAGE - 1, "Первый на линии ранен: [first.getBruteLoss()].")
	TEST_ASSERT(second.getBruteLoss() >= HERETIC_LEAD_LAST_ROUND_DAMAGE - 1, "Второй за пустой клеткой тоже ранен: [second.getBruteLoss()].")
	TEST_ASSERT(first.IsKnockdown() && second.IsKnockdown(), "Обоих сбивает с ног.")

/proc/heretic_lead_test_var_null(datum/thing, var_name)
	return isnull(thing.vars[var_name])

/// Осечка заговорённого оружия одним стрелком из пистолета в его руке.
/datum/unit_test/proc/heretic_lead_test_misfire(datum/eldritch_knowledge/base_lead/lead, mob/living/user, mob/living/carbon/human/shooter)
	var/obj/item/gun/ballistic/automatic/pistol/gun = allocate(/obj/item/gun/ballistic/automatic/pistol, get_turf(shooter))
	lead.place_curse(user, gun)
	shooter.put_in_hands(gun)
	gun.process_fire(heretic_lead_test_spot(1, 5), shooter)
	return gun

/// Ствол обращается: третья осечка у одного живого игрока разворачивает пистолет ему в ногу; стрелок без игрока в теле цел.
/datum/unit_test/heretic_lead_gun_turns/Run()
	allocated += new /datum/heretic_test_station_level(run_loc_floor_bottom_left.z)
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_LEAD)
	var/mob/living/carbon/human/user = heretic.owner.current
	heretic.gain_knowledge(/datum/eldritch_knowledge/lead_grasp)
	var/datum/eldritch_knowledge/base_lead/lead = heretic.get_knowledge(/datum/eldritch_knowledge/base_lead)
	var/mob/living/carbon/human/sleeper = heretic_lead_test_crew(heretic_lead_test_spot(1, 3))
	for(var/index in 1 to HERETIC_LEAD_TURN_MISFIRES)
		var/obj/item/gun/gun = heretic_lead_test_misfire(lead, user, sleeper)
		sleeper.dropItemToGround(gun)
	TEST_ASSERT_EQUAL(sleeper.getBruteLoss(), 0, "Без игрока в теле ствол не обращается.")
	var/mob/living/carbon/human/crew = heretic_lead_test_crew(heretic_lead_test_spot(3, 3))
	crew.mock_client = new /datum/client_interface
	for(var/index in 1 to HERETIC_LEAD_TURN_MISFIRES - 1)
		var/obj/item/gun/gun = heretic_lead_test_misfire(lead, user, crew)
		crew.dropItemToGround(gun)
	TEST_ASSERT_EQUAL(crew.getBruteLoss(), 0, "Первые две осечки ствол не обращают.")
	var/obj/item/gun/turned = heretic_lead_test_misfire(lead, user, crew)
	var/obj/item/bodypart/chest = crew.get_bodypart(BODY_ZONE_CHEST)
	var/obj/item/bodypart/head = crew.get_bodypart(BODY_ZONE_HEAD)
	TEST_ASSERT(crew.getBruteLoss() > 0, "Третья осечка - пуля в ногу.")
	TEST_ASSERT(chest.brute_dam == 0 && head.brute_dam == 0, "Обратившийся ствол бьёт в ногу, не в голову и не в грудь.")
	TEST_ASSERT(!crew.is_holding(turned), "Обратившийся ствол выпадает из рук.")
	crew.mock_client = null

/// Мёртвый стрелок: пистолет павшего рядом человека встаёт призрачным стволом и дважды стреляет по живым; лазер не встаёт, раз в минуту, ствол сбивают выстрелом.
/datum/unit_test/heretic_lead_dead_gunner/Run()
	allocated += new /datum/heretic_test_station_level(run_loc_floor_bottom_left.z)
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_LEAD)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_lead/lead = heretic.get_knowledge(/datum/eldritch_knowledge/base_lead)
	var/mob/living/carbon/human/early = heretic_lead_test_crew(heretic_lead_test_spot(2, 0))
	early.put_in_hands(allocate(/obj/item/gun/ballistic/automatic/pistol))
	early.death()
	TEST_ASSERT_NULL(locate(/obj/structure/heretic_lead_phantom_gun) in get_turf(early), "До Свинцового дождя павшие стрелки не встают.")
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/lead_rain)
	var/mob/living/carbon/human/lasered = heretic_lead_test_crew(heretic_lead_test_spot(2, 1))
	lasered.put_in_hands(allocate(/obj/item/gun/energy/laser))
	lasered.death()
	TEST_ASSERT_NULL(locate(/obj/structure/heretic_lead_phantom_gun) in get_turf(lasered), "Лазер павшего не встаёт.")
	var/mob/living/carbon/human/gunner = heretic_lead_test_crew(heretic_lead_test_spot(3, 0))
	gunner.put_in_hands(allocate(/obj/item/gun/ballistic/automatic/pistol))
	var/mob/living/carbon/human/witness = heretic_lead_test_crew(heretic_lead_test_spot(3, 4))
	gunner.death()
	var/obj/structure/heretic_lead_phantom_gun/phantom = locate() in get_turf(gunner)
	TEST_ASSERT_NOTNULL(phantom, "Пистолет павшего встаёт призрачным стволом.")
	TEST_ASSERT(!phantom.density, "Призрачный ствол не загораживает проход.")
	TEST_ASSERT_EQUAL(witness.getBruteLoss(), 0, "Первую секунду ствол только целится.")
	TEST_ASSERT(heretic_lead_test_wait(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(heretic_lead_test_brute_at_least), witness, HERETIC_LEAD_PHANTOM_DAMAGE * HERETIC_LEAD_PHANTOM_SHOTS - 1), 6 SECONDS, "призрачный ствол"), "Ствол дважды стреляет по живому.")
	TEST_ASSERT(witness.getBruteLoss() < HERETIC_LEAD_PHANTOM_DAMAGE * (HERETIC_LEAD_PHANTOM_SHOTS + 1) - 1, "Выстрелов не больше двух.")
	TEST_ASSERT_EQUAL(user.getBruteLoss(), 0, "Еретика призрачный ствол не трогает.")
	TEST_ASSERT(wait_for_qdeleted(phantom, 2 SECONDS), "Отстреляв, ствол падает.")
	var/mob/living/carbon/human/second = heretic_lead_test_crew(heretic_lead_test_spot(1, 1))
	second.put_in_hands(allocate(/obj/item/gun/ballistic/automatic/pistol))
	second.death()
	TEST_ASSERT_NULL(locate(/obj/structure/heretic_lead_phantom_gun) in get_turf(second), "Второй ствол не раньше чем через минуту.")
	COOLDOWN_RESET(lead, phantom_cooldown)
	var/mob/living/carbon/human/third = heretic_lead_test_crew(heretic_lead_test_spot(1, 2))
	third.put_in_hands(allocate(/obj/item/gun/ballistic/automatic/pistol))
	third.death()
	phantom = locate() in get_turf(third)
	TEST_ASSERT_NOTNULL(phantom, "После паузы ствол встаёт снова.")
	var/obj/item/projectile/laser = heretic_lead_test_bullet(witness, phantom, /obj/item/projectile/beam/laser, 20)
	laser.fire()
	heretic_lead_test_fly(laser)
	TEST_ASSERT(QDELETED(phantom), "Выстрел в призрачный ствол сбивает его.")

/// Охота на звук: с трёх душ без своей пули Рикошет ведёт к чужому выстрелу - столб дыма, секунда, перенос; затем отдых три минуты.
/datum/unit_test/heretic_lead_sound_hunt/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_LEAD)
	var/mob/living/carbon/human/user = heretic.owner.current
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/lead_ricochet)
	var/datum/eldritch_knowledge/base_lead/lead = heretic.get_knowledge(/datum/eldritch_knowledge/base_lead)
	var/mob/living/carbon/human/crew = heretic_lead_test_crew(heretic_lead_test_spot(4, 3))
	var/obj/item/gun/ballistic/automatic/pistol/gun = allocate(/obj/item/gun/ballistic/automatic/pistol, get_turf(crew))
	crew.put_in_hands(gun)
	var/turf/shot_spot = get_turf(crew)
	gun.process_fire(heretic_lead_test_spot(4, 5), crew)
	heretic.total_sacrifices = HERETIC_LEAD_SOUND_HUNT_SACRIFICES - 1
	var/reason = lead.ricochet_block_reason(user)
	TEST_ASSERT(findtext(reason, "Некуда") && !findtext(reason, "Охота"), "До третьей души Рикошет на звук не ведёт: [reason]")
	heretic.total_sacrifices = HERETIC_LEAD_SOUND_HUNT_SACRIFICES
	TEST_ASSERT_NULL(lead.ricochet_block_reason(user), "С третьей души Рикошет слышит чужой выстрел.")
	var/turf/origin = get_turf(user)
	var/datum/eldritch_knowledge/spell/lead_ricochet/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/spell/lead_ricochet)
	INVOKE_ASYNC(knowledge.granted_spell, TYPE_PROC_REF(/obj/effect/proc_holder/spell, cast), list(user), user)
	TEST_ASSERT_NOTNULL(locate(/obj/effect/temp_visual/heretic_lead/powder_pillar) in range(1, shot_spot), "У места выстрела встаёт столб порохового дыма.")
	TEST_ASSERT_EQUAL(get_turf(user), origin, "Первую секунду еретик стоит на месте.")
	TEST_ASSERT(heretic_lead_test_wait(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(heretic_lead_test_near), user, shot_spot), 3 SECONDS, "охота на звук"), "Еретик выходит у места выстрела: [lead.lead_failure]")
	TEST_ASSERT_EQUAL(lead.combat_resource, 1, "Охота на звук стоит единицу Свинца.")
	var/obj/effect/temp_visual/heretic_lead/smoke/smoke = locate() in origin
	TEST_ASSERT(smoke?.opacity, "На месте ухода пороховой дым.")
	gun.fire_delay = 0
	gun.last_fire = 0
	gun.process_fire(heretic_lead_test_spot(4, 5), crew)
	user.forceMove(origin)
	reason = lead.ricochet_block_reason(user)
	TEST_ASSERT(findtext(reason, "отдыхает"), "Охота на звук отдыхает три минуты: [reason]")

/// Мишень помнит: на цели охоты метка держится 25 секунд, убитый меченый человек даёт 2 Свинца; труп без разума - ничего.
/datum/unit_test/heretic_lead_mark_memory/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_LEAD)
	var/mob/living/carbon/human/user = heretic.owner.current
	heretic.gain_knowledge(/datum/eldritch_knowledge/lead_mark)
	var/datum/eldritch_knowledge/base_lead/lead = heretic.get_knowledge(/datum/eldritch_knowledge/base_lead)
	var/mob/living/carbon/human/prey = heretic_lead_test_crew(heretic_lead_test_spot(3, 0))
	heretic.set_hunt_target(prey.mind)
	var/obj/item/melee/touch_attack/mansus_fist/fist = allocate(/obj/item/melee/touch_attack/mansus_fist)
	prey.forceMove(get_step(user, EAST))
	fist.afterattack(prey, user, TRUE)
	var/datum/status_effect/eldritch/lead/hunted = prey.has_status_effect(/datum/status_effect/eldritch/lead)
	TEST_ASSERT_NOTNULL(hunted, "Хватка ставит Мишень на цель охоты.")
	TEST_ASSERT(abs(hunted.duration - world.time - HERETIC_LEAD_MARK_HUNT_TIME) < 1, "На цели охоты Мишень держится 25 секунд.")
	TEST_ASSERT(findtext(hunted.linked_alert?.desc, "[HERETIC_LEAD_MARK_HUNT_TIME / (1 SECONDS)] секунд"), "Значок метки называет её срок.")
	var/mob/living/carbon/human/other = heretic_lead_test_crew(heretic_lead_test_spot(0, 3))
	other.apply_status_effect(/datum/status_effect/eldritch/lead, lead)
	var/datum/status_effect/eldritch/lead/plain = other.has_status_effect(/datum/status_effect/eldritch/lead)
	TEST_ASSERT(abs(plain.duration - world.time - 15 SECONDS) < 1, "На прочих Мишень держится обычные 15 секунд.")
	lead.combat_resource = 0
	other.death()
	TEST_ASSERT_EQUAL(lead.combat_resource, HERETIC_LEAD_MARK_KILL_LEAD, "Убитая Мишень даёт два Свинца.")
	TEST_ASSERT(QDELETED(plain), "Метка уходит с трупа.")
	var/mob/living/carbon/human/mindless = allocate(/mob/living/carbon/human, heretic_lead_test_spot(4, 4))
	mindless.apply_status_effect(/datum/status_effect/eldritch/lead, lead)
	mindless.death()
	TEST_ASSERT_EQUAL(lead.combat_resource, HERETIC_LEAD_MARK_KILL_LEAD, "Тело без разума Свинца не даёт.")

/// Барабан вознесения: раз в минуту, пока горят тигли; третий удар даёт 2 Свинца и Шестую камору даром; без тиглей молчит.
/datum/unit_test/heretic_lead_drum/Run()
	allocated += new /datum/heretic_test_station_level(run_loc_floor_bottom_left.z)
	var/list/fixture = heretic_lead_ascended()
	var/mob/living/carbon/human/user = fixture["user"]
	var/datum/antagonist/heretic/heretic = fixture["heretic"]
	var/datum/eldritch_knowledge/base_lead/lead = fixture["lead"]
	var/datum/eldritch_knowledge/final_eldritch/lead_final/finale = fixture["finale"]
	heretic.gain_knowledge(/datum/eldritch_knowledge/lead_ear)
	heretic_lead_test_misfires(lead)
	TEST_ASSERT(finale.raise_crucibles(user), "Тигли встают.")
	TEST_ASSERT(finale.drum_timer, "Пока горят тигли, барабан отбивает отсчёт.")
	lead.combat_resource = 0
	finale.drum_beat()
	finale.drum_beat()
	TEST_ASSERT(!lead.free_last_round && lead.combat_resource == 0, "Первые два удара - только отсчёт.")
	finale.drum_beat()
	TEST_ASSERT(lead.combat_resource >= HERETIC_LEAD_DRUM_LEAD, "Третий удар даёт два Свинца.")
	TEST_ASSERT(lead.free_last_round && lead.last_round_ready(), "Третий удар дарит Шестую камору.")
	var/before = lead.combat_resource
	var/obj/item/heretic_path_relic/lead_revolver/revolver = heretic_lead_test_revolver(heretic, user)
	var/mob/living/carbon/human/crew = heretic_lead_test_crew(heretic_lead_test_spot(3, 1))
	TEST_ASSERT(!lead.sixth_cocked(), "Подаренная камора сама не взводится.")
	TEST_ASSERT(heretic_lead_test_arm_sixth(revolver, user), "Подаренную Шестую камору взводят без полного барабана.")
	TEST_ASSERT(revolver.fire_at(crew, user) == TRUE, "Подаренная камора даёт Последний патрон без полного барабана.")
	TEST_ASSERT(heretic_lead_test_wait(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(heretic_lead_test_brute_at_least), crew, HERETIC_LEAD_LAST_ROUND_DAMAGE - 1), 4 SECONDS, "Последний патрон барабана"), "Подаренный Последний патрон попадает.")
	TEST_ASSERT(!lead.free_last_round && lead.combat_resource >= before, "Подаренная камора не трогает барабан.")
	for(var/obj/structure/heretic_lead_crucible/crucible as anything in finale.crucibles.Copy())
		crucible.take_damage(HERETIC_LEAD_CRUCIBLE_INTEGRITY, BRUTE, MELEE, FALSE)
	TEST_ASSERT_NULL(finale.drum_timer, "Погасшие тигли глушат барабан.")
	TEST_ASSERT(!finale.drum_beat(), "Без тиглей барабан молчит.")

/// Числа новых приёмов в кодексе и описаниях совпадают с дефайнами.
/datum/unit_test/heretic_lead_menace_texts/Run()
	var/list/numbers = list(
		/datum/eldritch_knowledge/base_lead = list("в [HERETIC_LEAD_SCENT_RANGE] клетках", "с [HERETIC_LEAD_SCENT_SHOWN] Свинца"),
		/datum/eldritch_knowledge/lead_grasp = list("Третья за раунд осечка"),
		/datum/eldritch_knowledge/lead_mark = list("[HERETIC_LEAD_MARK_HUNT_TIME / (1 SECONDS)] секунд", "даёт вам [HERETIC_LEAD_MARK_KILL_LEAD] Свинца"),
		/datum/eldritch_knowledge/spell/lead_ricochet = list("С [HERETIC_LEAD_SOUND_HUNT_SACRIFICES] душ", "раз в [HERETIC_LEAD_SOUND_HUNT_COOLDOWN / (1 MINUTES)] минуты", "в [HERETIC_LEAD_RICOCHET_RANGE] клетках"),
		/datum/eldritch_knowledge/lead_ear = list("пуля на [HERETIC_LEAD_LAST_ROUND_DAMAGE] ушибов", "до [HERETIC_LEAD_LAST_ROUND_TARGETS] целей", "валит на [HERETIC_LEAD_LAST_ROUND_KNOCKDOWN / (1 SECONDS)] секунды"),
		/datum/eldritch_knowledge/spell/lead_rain = list("в [HERETIC_LEAD_PHANTOM_RADIUS] клетках", "на [HERETIC_LEAD_PHANTOM_TIME / (1 SECONDS)] секунд", "[HERETIC_LEAD_PHANTOM_SHOTS] раза", "[HERETIC_LEAD_PHANTOM_DAMAGE] ушибов", "после [HERETIC_LEAD_PHANTOM_AIM / (1 SECONDS)] секунды"),
		/datum/eldritch_knowledge/final_eldritch/lead_final = list("каждый [HERETIC_LEAD_DRUM_BEATS]-й удар - [HERETIC_LEAD_DRUM_LEAD] Свинца", "вполовину силы"),
	)
	for(var/knowledge_type in numbers)
		var/datum/eldritch_knowledge/knowledge = allocate(knowledge_type)
		for(var/fragment in numbers[knowledge_type])
			TEST_ASSERT(findtext(knowledge.desc, fragment), "[knowledge_type]: в описании есть «[fragment]».")
	TEST_ASSERT(HERETIC_LEAD_TURN_MISFIRES == 3 && HERETIC_LEAD_DRUM_PERIOD == 1 MINUTES && HERETIC_LEAD_LAST_ROUND_AIM == 1.5 SECONDS, "Слова «третья», «раз в минуту» и «1,5 секунды» в текстах держатся дефайнов.")
	var/obj/item/heretic_path_relic/lead_revolver/revolver = /obj/item/heretic_path_relic/lead_revolver
	TEST_ASSERT(findtext(initial(revolver.desc), "1,5 секунды") && findtext(initial(revolver.desc), "[HERETIC_LEAD_LAST_ROUND_DAMAGE] ушибов"), "Осмотр револьвера описывает Последний патрон.")
	var/obj/effect/proc_holder/spell/self/heretic_lead/ricochet/ricochet = /obj/effect/proc_holder/spell/self/heretic_lead/ricochet
	TEST_ASSERT(findtext(initial(ricochet.desc), "С [HERETIC_LEAD_SOUND_HUNT_SACRIFICES] принятых душ") && findtext(initial(ricochet.desc), "раз в [HERETIC_LEAD_SOUND_HUNT_COOLDOWN / (1 MINUTES)] минуты"), "Рикошет описывает Охоту на звук.")
	var/obj/effect/proc_holder/spell/self/heretic_lead/final_volley/volley = /obj/effect/proc_holder/spell/self/heretic_lead/final_volley
	TEST_ASSERT(findtext(initial(volley.desc), "рикошетом"), "Последний залп описывает рикошет.")

/proc/heretic_lead_test_charged(datum/eldritch_knowledge/base_lead/lead)
	var/list/positions = list()
	for(var/position in 1 to HERETIC_LEAD_CAPACITY)
		if(lead.chamber_charged(position))
			positions += position
	return jointext(positions, ",")

/proc/heretic_lead_test_drum_states(datum/eldritch_knowledge/base_lead/lead)
	var/list/states = list()
	for(var/mutable_appearance/layer as anything in lead.drum_overlays)
		states += layer.icon_state
	return states

/// Камора под курок и выстрел из неё, как после выбора в радиальном меню.
/datum/unit_test/proc/heretic_lead_test_round(obj/item/heretic_path_relic/lead_revolver/revolver, datum/eldritch_knowledge/base_lead/lead, mob/living/user, atom/target, position)
	lead.combat_resource = max(lead.combat_resource, 2)
	revolver.select_chamber(user, position)
	COOLDOWN_RESET(revolver, drum_turn)
	COOLDOWN_RESET(revolver, shot_cooldown)
	var/obj/item/projectile/bullet = revolver.fire_at(target, user)
	heretic_lead_test_fly(bullet, 2)
	return bullet

/// Свинец - заряженные каморы подряд от курка: выстрел тратит камору под курком, способности гасят последнюю, новый Свинец заряжает следующую; закрытая камора бьёт Свинцовой; значок рисует каморы и курок.
/datum/unit_test/heretic_lead_drum_model/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_LEAD)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_lead/lead = heretic.get_knowledge(/datum/eldritch_knowledge/base_lead)
	var/obj/item/heretic_path_relic/lead_revolver/revolver = heretic_lead_test_revolver(heretic, user)
	TEST_ASSERT_EQUAL(lead.chamber_round(1), /obj/item/projectile/bullet/heretic_lead, "Первая камора - Свинцовая.")
	TEST_ASSERT_EQUAL(lead.chamber_round(2), /obj/item/projectile/bullet/heretic_lead/heavy, "Тяжёлая камора открыта вместе с реликвией.")
	TEST_ASSERT_EQUAL(lead.chamber_round(4), /obj/item/projectile/bullet/heretic_lead, "Пороховая камора до Ловли пули бьёт Свинцовой.")
	TEST_ASSERT(!lead.turn_drum(4), "Закрытую камору под курок не поставить.")
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/lead_catch)
	TEST_ASSERT_EQUAL(lead.chamber_round(4), /obj/item/projectile/bullet/heretic_lead/powder, "Ловля пули открывает Пороховую камору.")
	TEST_ASSERT((4 in lead.open_chambers()) && !(5 in lead.open_chambers()), "Открыты только изученные каморы.")
	lead.drum_hammer = 1
	lead.combat_resource = 3
	TEST_ASSERT_EQUAL(heretic_lead_test_charged(lead), "1,2,3", "Три Свинца - три каморы подряд от курка.")
	var/obj/item/projectile/shot = revolver.fire_at(heretic_lead_test_spot(5, 0), user)
	TEST_ASSERT(shot?.type == /obj/item/projectile/bullet/heretic_lead, "Выстрел идёт из каморы под курком.")
	heretic_lead_test_fly(shot)
	TEST_ASSERT_EQUAL(lead.drum_hammer, 2, "После выстрела под курком следующая камора.")
	TEST_ASSERT_EQUAL(heretic_lead_test_charged(lead), "2,3", "Выстрел гасит камору под курком.")
	TEST_ASSERT(lead.spend_combat_resource(), "Способность тратит Свинец.")
	TEST_ASSERT_EQUAL(heretic_lead_test_charged(lead), "2", "Способность гасит последнюю заряженную камору, а не ту, что под курком.")
	lead.gain_combat_resource(3)
	TEST_ASSERT_EQUAL(heretic_lead_test_charged(lead), "2,3,4,5", "Новый Свинец заряжает каморы за последней.")
	lead.drum_hammer = 5
	lead.combat_resource = 3
	TEST_ASSERT_EQUAL(heretic_lead_test_charged(lead), "1,2,5", "Каморы заряжаются по кругу.")
	lead.combat_resource = HERETIC_LEAD_CAPACITY
	TEST_ASSERT_EQUAL(heretic_lead_test_charged(lead), "1,2,3,4,5,6", "Полный барабан - все шесть камор.")
	TEST_ASSERT(!lead.sixth_cocked(), "Без Слуха стрелка Шестая камора не Последний патрон.")
	var/atom/movable/screen/alert/heretic_resource/indicator = lead.update_drum_hud()
	TEST_ASSERT_NOTNULL(indicator, "Барабан рисуется на значке запаса.")
	var/list/states = heretic_lead_test_drum_states(lead)
	TEST_ASSERT(("drum" in states) && ("round6" in states) && ("next5" in states) && !("round6_last" in states), "Значок показывает все шесть камор и курок на пятой: [jointext(states, ", ")].")
	TEST_ASSERT(length(indicator.overlays) >= length(lead.drum_overlays), "Каморы лежат на значке оверлеями.")
	heretic.gain_knowledge(/datum/eldritch_knowledge/lead_ear)
	TEST_ASSERT(!lead.sixth_cocked(), "Со Слухом стрелка полный барабан сам Шестую камору не взводит.")
	states = heretic_lead_test_drum_states(lead)
	TEST_ASSERT(("round6_last" in states) && ("next5" in states), "Изученное знание сразу перекрашивает барабан: [jointext(states, ", ")].")
	TEST_ASSERT(lead.turn_drum(HERETIC_LEAD_CAPACITY) && lead.sixth_cocked(), "Выбор Шестой каморы взводит Последний патрон.")
	states = heretic_lead_test_drum_states(lead)
	TEST_ASSERT("next6" in states, "Взведённая Шестая видна на значке: [jointext(states, ", ")].")
	heretic.total_sacrifices = 10
	TEST_ASSERT_EQUAL(lead.sacrifice_penetration(), HERETIC_LEAD_SACRIFICE_PENETRATION_CAP, "Пробитие за души упирается в потолок.")
	heretic.total_sacrifices = 2
	lead.combat_resource = 2
	COOLDOWN_RESET(revolver, shot_cooldown)
	var/obj/item/projectile/bullet/heretic_lead/pierced = revolver.fire_at(heretic_lead_test_spot(5, 4), user)
	var/obj/item/projectile/bullet/heretic_lead/sample = pierced.type
	TEST_ASSERT_EQUAL(pierced.armour_penetration, initial(sample.armour_penetration) + 2 * HERETIC_LEAD_SACRIFICE_PENETRATION, "Каждая принятая душа добавляет пуле пробития.")
	heretic_lead_test_fly(pierced)

/// Выбор каморы ставит её под курок за полсекунды; прокрутка Ctrl-кликом - случайная открытая камора с удачей и откатом; выбранная при полном барабане камора снимает Последний патрон, Шестая возвращает его.
/datum/unit_test/heretic_lead_drum_select_spin/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_LEAD)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_lead/lead = heretic.get_knowledge(/datum/eldritch_knowledge/base_lead)
	var/obj/item/heretic_path_relic/lead_revolver/revolver = heretic_lead_test_revolver(heretic, user)
	for(var/knowledge_type in list(/datum/eldritch_knowledge/lead_mark, /datum/eldritch_knowledge/spell/lead_catch, /datum/eldritch_knowledge/spell/lead_ricochet, /datum/eldritch_knowledge/lead_ear))
		heretic.gain_knowledge(knowledge_type)
	TEST_ASSERT_EQUAL(length(lead.open_chambers()), 5, "Все пять камор кольца открыты.")
	var/mob/living/carbon/human/victim = heretic_lead_test_crew(heretic_lead_test_spot(3, 0))
	lead.combat_resource = 3
	TEST_ASSERT(revolver.select_chamber(user, 4), "Камора выбирается.")
	TEST_ASSERT_EQUAL(lead.drum_hammer, 4, "Под курком выбранная камора.")
	COOLDOWN_RESET(revolver, shot_cooldown)
	TEST_ASSERT(!revolver.fire_at(victim, user), "Пока барабан проворачивается, выстрела нет.")
	TEST_ASSERT_EQUAL(lead.combat_resource, 3, "Несостоявшийся выстрел Свинец не тратит.")
	COOLDOWN_RESET(revolver, drum_turn)
	COOLDOWN_RESET(revolver, shot_cooldown)
	var/obj/item/projectile/powder = revolver.fire_at(victim, user)
	TEST_ASSERT(istype(powder, /obj/item/projectile/bullet/heretic_lead/powder), "Из выбранной каморы летит её пуля.")
	heretic_lead_test_fly(powder)
	victim.ExtinguishMob()
	var/before = lead.drum_hammer
	revolver.CtrlClick(user)
	TEST_ASSERT(lead.drum_lucky && lead.drum_hammer != before && (lead.drum_hammer in lead.open_chambers()), "Прокрутка ставит под курок другую открытую камору на удачу.")
	TEST_ASSERT(!COOLDOWN_FINISHED(revolver, drum_spin), "У прокрутки есть откат.")
	var/spun = lead.drum_hammer
	revolver.CtrlClick(user)
	TEST_ASSERT_EQUAL(lead.drum_hammer, spun, "Барабан не крутится чаще раза в [HERETIC_LEAD_SPIN_COOLDOWN / (1 SECONDS)] секунд.")
	COOLDOWN_RESET(revolver, drum_turn)
	COOLDOWN_RESET(revolver, shot_cooldown)
	lead.combat_resource = 3
	var/obj/item/projectile/bullet/heretic_lead/lucky = revolver.fire_at(heretic_lead_test_spot(5, 4), user)
	TEST_ASSERT(istype(lucky), "Выпавшая камора стреляет.")
	var/obj/item/projectile/bullet/heretic_lead/sample = lucky.type
	TEST_ASSERT(abs(lucky.damage - initial(sample.damage) * (100 + HERETIC_LEAD_LUCK_BONUS) / 100) < 0.1, "Выпавшая на прокрутке пуля бьёт на [HERETIC_LEAD_LUCK_BONUS]% сильнее: [lucky.damage].")
	TEST_ASSERT(!lead.drum_lucky, "Удача уходит с выстрелом.")
	heretic_lead_test_fly(lucky)
	lead.combat_resource = HERETIC_LEAD_CAPACITY
	TEST_ASSERT(!lead.sixth_cocked(), "Полный барабан сам Шестую камору не взводит.")
	TEST_ASSERT(revolver.select_chamber(user, HERETIC_LEAD_CAPACITY) && lead.sixth_cocked(), "Выбор Шестой каморы взводит Последний патрон.")
	TEST_ASSERT(revolver.select_chamber(user, 2), "При полном барабане можно выбрать камору кольца.")
	TEST_ASSERT(!lead.sixth_cocked(), "Выбранная камора снимает Шестую с курка.")
	COOLDOWN_RESET(revolver, drum_turn)
	COOLDOWN_RESET(revolver, shot_cooldown)
	victim.SetKnockdown(0)
	var/obj/item/projectile/heavy = revolver.fire_at(victim, user)
	TEST_ASSERT(istype(heavy, /obj/item/projectile/bullet/heretic_lead/heavy), "Выстрел в человека идёт из выбранной каморы, а не Последним патроном.")
	heretic_lead_test_fly(heavy)
	lead.combat_resource = HERETIC_LEAD_CAPACITY
	TEST_ASSERT(!lead.sixth_cocked(), "Снятая Шестая не возвращается сама с полным барабаном.")
	TEST_ASSERT(revolver.select_chamber(user, HERETIC_LEAD_CAPACITY) && lead.sixth_cocked(), "Выбор Шестой каморы возвращает Последний патрон.")
	TEST_ASSERT(revolver.select_chamber(user, 3) && !lead.sixth_cocked(), "Камора кольца снимает Шестую.")

/// Рода пуль: Тяжёлая валит сквозь броню, но одну цель не чаще раза в 6 секунд; Меченая вешает Мишень; Пороховая поджигает и обжигает сквозь броню; Звонкая отскакивает в соседа от цели и от стены; после вознесения первая камора Бронебойная.
/datum/unit_test/heretic_lead_round_kinds/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_LEAD)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_lead/lead = heretic.get_knowledge(/datum/eldritch_knowledge/base_lead)
	var/obj/item/heretic_path_relic/lead_revolver/revolver = heretic_lead_test_revolver(heretic, user)
	for(var/knowledge_type in list(/datum/eldritch_knowledge/lead_mark, /datum/eldritch_knowledge/spell/lead_catch, /datum/eldritch_knowledge/spell/lead_ricochet))
		heretic.gain_knowledge(knowledge_type)
	var/mob/living/carbon/human/first = heretic_lead_test_crew(heretic_lead_test_spot(0, 2))
	var/mob/living/carbon/human/second = heretic_lead_test_crew(heretic_lead_test_spot(2, 2))
	var/mob/living/carbon/human/third = heretic_lead_test_crew(heretic_lead_test_spot(4, 0))
	var/mob/living/carbon/human/fourth = heretic_lead_test_crew(heretic_lead_test_spot(4, 2))
	heretic_lead_test_round(revolver, lead, user, first, 2)
	TEST_ASSERT(first.IsKnockdown(), "Тяжёлая пуля валит с ног.")
	first.SetKnockdown(0)
	heretic_lead_test_round(revolver, lead, user, first, 2)
	TEST_ASSERT(first.getBruteLoss() > HERETIC_LEAD_ROUND_DAMAGE && !first.IsKnockdown(), "Вторая Тяжёлая пуля ранит, но не валит ту же цель раньше [HERETIC_LEAD_HEAVY_REPEAT / (1 SECONDS)] секунд.")
	heretic_lead_test_round(revolver, lead, user, first, 3)
	TEST_ASSERT(first.has_status_effect(/datum/status_effect/eldritch/lead), "Меченая пуля вешает Мишень.")
	heretic_lead_test_round(revolver, lead, user, second, 4)
	TEST_ASSERT(second.on_fire && second.getFireLoss() >= HERETIC_LEAD_POWDER_BURN, "Пороховая пуля поджигает и обжигает: [second.getFireLoss()].")
	second.ExtinguishMob()
	heretic_lead_test_round(revolver, lead, user, third, 5)
	TEST_ASSERT(third.getBruteLoss() > 0, "Звонкая пуля попала.")
	TEST_ASSERT(heretic_lead_test_wait(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(heretic_lead_test_brute_at_least), fourth, 1), 3 SECONDS, "рикошет Звонкой"), "Звонкая пуля отскакивает в соседа.")
	TEST_ASSERT(fourth.getBruteLoss() <= HERETIC_LEAD_RING_DAMAGE + 1, "Рикошет бьёт ближайшего слабее самой пули: [fourth.getBruteLoss()].")
	third.forceMove(heretic_lead_test_spot(0, 5))
	fourth.forceMove(heretic_lead_test_spot(1, 5))
	var/mob/living/carbon/human/fifth = heretic_lead_test_crew(heretic_lead_test_spot(5, 3))
	heretic_lead_test_round(revolver, lead, user, heretic_lead_test_spot(6, 0), 5)
	TEST_ASSERT(heretic_lead_test_wait(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(heretic_lead_test_brute_at_least), fifth, 1), 3 SECONDS, "рикошет от стены"), "Звонкая пуля отскакивает от стены к врагу за углом.")
	heretic.gain_knowledge(/datum/eldritch_knowledge/final_eldritch/lead_final)
	var/datum/eldritch_knowledge/final_eldritch/lead_final/finale = heretic.get_knowledge(/datum/eldritch_knowledge/final_eldritch/lead_final)
	finale.finished = TRUE
	TEST_ASSERT_EQUAL(lead.chamber_round(1), /obj/item/projectile/bullet/heretic_lead/piercing, "После вознесения первая камора Бронебойная.")
	var/obj/item/projectile/bullet/heretic_lead/piercing = heretic_lead_test_round(revolver, lead, user, heretic_lead_test_spot(5, 5), 1)
	TEST_ASSERT(piercing?.armour_penetration >= HERETIC_LEAD_PIERCING_PENETRATION, "Бронебойная пуля пробивает глубже Свинцовой.")

/// В голову стоящему пуля бьёт на 30% сильнее и звенит в ушах 2 секунды; лежачему - без прибавки.
/datum/unit_test/heretic_lead_headshot/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_LEAD)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_lead/lead = heretic.get_knowledge(/datum/eldritch_knowledge/base_lead)
	var/obj/item/heretic_path_relic/lead_revolver/revolver = heretic_lead_test_revolver(heretic, user)
	var/mob/living/carbon/human/standing = heretic_lead_test_crew(get_step(user, EAST))
	var/mob/living/carbon/human/lying = heretic_lead_test_crew(get_step(user, NORTH))
	user.zone_selected = BODY_ZONE_HEAD
	heretic_lead_test_round(revolver, lead, user, standing, 1)
	var/expected = HERETIC_LEAD_REVOLVER_DAMAGE * (100 + HERETIC_LEAD_HEADSHOT_BONUS) / 100
	TEST_ASSERT(abs(standing.getBruteLoss() - expected) < 1, "Пуля в голову стоящему: [standing.getBruteLoss()] вместо [expected].")
	TEST_ASSERT(standing.has_status_effect(/datum/status_effect/heretic_lead_ringing) && HAS_TRAIT(standing, TRAIT_DEAF), "После пули в голову звенит в ушах.")
	lying.set_resting(TRUE, TRUE)
	TEST_ASSERT(lying.lying, "Цель лежит.")
	heretic_lead_test_round(revolver, lead, user, lying, 1)
	TEST_ASSERT(abs(lying.getBruteLoss() - HERETIC_LEAD_REVOLVER_DAMAGE) < 1, "Лежачему в голову без прибавки: [lying.getBruteLoss()].")
	TEST_ASSERT_NULL(lying.has_status_effect(/datum/status_effect/heretic_lead_ringing), "Лежачему не звенит.")
	TEST_ASSERT(heretic_lead_test_wait(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(heretic_lead_test_hears), standing), HERETIC_LEAD_HEADSHOT_RING + 2 SECONDS, "звон в ушах"), "Звон проходит.")

/proc/heretic_lead_test_hears(mob/living/victim)
	return !HAS_TRAIT(victim, TRAIT_DEAF)

/// Прицельный выстрел: «Использовать в руке» включает стиль, щелчок - секунда красной линии без траты Свинца, затем пуля на 50% сильнее; сдвинувшийся стрелок прицел срывает.
/datum/unit_test/heretic_lead_aimed_shot/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_LEAD)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_lead/lead = heretic.get_knowledge(/datum/eldritch_knowledge/base_lead)
	var/obj/item/heretic_path_relic/lead_revolver/revolver = heretic_lead_test_revolver(heretic, user)
	var/mob/living/carbon/human/victim = heretic_lead_test_crew(heretic_lead_test_spot(3, 0))
	revolver.attack_self(user)
	TEST_ASSERT_EQUAL(lead.drum_style, HERETIC_LEAD_STYLE_AIMED, "Использование в руке включает прицельный выстрел.")
	lead.combat_resource = 2
	TEST_ASSERT(revolver.fire_at(victim, user) == TRUE, "Щелчок берёт цель на прицел.")
	TEST_ASSERT(revolver.focus_timer && lead.combat_resource == 2 && victim.getBruteLoss() == 0, "До конца прицеливания ни выстрела, ни траты.")
	var/expected = HERETIC_LEAD_REVOLVER_DAMAGE * (100 + HERETIC_LEAD_AIM_BONUS) / 100
	TEST_ASSERT(heretic_lead_test_wait(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(heretic_lead_test_brute_at_least), victim, expected - 1), HERETIC_LEAD_AIM_TIME + 2 SECONDS, "прицельный выстрел"), "Прицельная пуля бьёт на [HERETIC_LEAD_AIM_BONUS]% сильнее: [victim.getBruteLoss()].")
	var/brute = victim.getBruteLoss()
	var/resource = lead.combat_resource
	COOLDOWN_RESET(revolver, shot_cooldown)
	TEST_ASSERT(revolver.fire_at(victim, user) == TRUE, "Второй прицел.")
	user.forceMove(heretic_lead_test_spot(0, 1))
	TEST_ASSERT(heretic_lead_test_wait(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(heretic_lead_test_var_null), revolver, NAMEOF(revolver, focus_timer)), HERETIC_LEAD_AIM_TIME + 2 SECONDS, "срыв прицела"), "Прицел отработал.")
	TEST_ASSERT(victim.getBruteLoss() == brute && lead.combat_resource == resource, "Сдвинувшийся стрелок срывает прицел, Свинец цел.")

/// Веер: щелчок курка, затем за секунду уходят все заряженные каморы по 75% урона; потом 3 секунды без выстрелов, стиль снова обычный; пустой барабан веера не даёт.
/datum/unit_test/heretic_lead_fan/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_LEAD)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_lead/lead = heretic.get_knowledge(/datum/eldritch_knowledge/base_lead)
	var/obj/item/heretic_path_relic/lead_revolver/revolver = heretic_lead_test_revolver(heretic, user)
	var/mob/living/carbon/human/victim = heretic_lead_test_crew(get_step(user, EAST))
	revolver.attack_self(user)
	revolver.attack_self(user)
	TEST_ASSERT_EQUAL(lead.drum_style, HERETIC_LEAD_STYLE_FAN, "Второе использование в руке включает веер.")
	lead.combat_resource = 3
	var/started = world.time
	TEST_ASSERT(revolver.fire_at(victim, user), "Веер начинается.")
	TEST_ASSERT(revolver.fan_timer && lead.combat_resource == 3, "До щелчка курка пуль нет.")
	TEST_ASSERT(heretic_lead_test_wait(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(heretic_lead_test_var_null), revolver, NAMEOF(revolver, fan_timer)), 3 SECONDS, "веер"), "Веер закончился.")
	var/elapsed = world.time - started
	TEST_ASSERT(elapsed <= HERETIC_LEAD_FAN_TELEGRAPH + HERETIC_LEAD_FAN_TIME + 0.5 SECONDS, "Веер укладывается в секунду после щелчка: [elapsed] дс.")
	var/casings = 0
	for(var/obj/item/ammo_casing/heretic_lead/casing in get_turf(user))
		casings++
	TEST_ASSERT_EQUAL(casings, 3, "Веер выпускает все три заряженные каморы.")
	var/expected = (HERETIC_LEAD_REVOLVER_DAMAGE * 2 + HERETIC_LEAD_ROUND_DAMAGE) * HERETIC_LEAD_FAN_DAMAGE / 100
	TEST_ASSERT(victim.getBruteLoss() >= expected - 1 && victim.getBruteLoss() < expected * 100 / HERETIC_LEAD_FAN_DAMAGE, "Вблизи все пули веера в цели по [HERETIC_LEAD_FAN_DAMAGE]% урона (раны чуть прибавляют): [victim.getBruteLoss()] при [expected].")
	TEST_ASSERT_EQUAL(lead.drum_style, HERETIC_LEAD_STYLE_PLAIN, "После веера стиль снова обычный.")
	lead.combat_resource = 2
	COOLDOWN_RESET(revolver, shot_cooldown)
	TEST_ASSERT(!revolver.fire_at(victim, user) && lead.combat_resource == 2, "После веера [HERETIC_LEAD_FAN_LOCKOUT / (1 SECONDS)] секунды без выстрелов.")
	COOLDOWN_RESET(revolver, fan_lockout)
	COOLDOWN_RESET(revolver, shot_cooldown)
	lead.drum_style = HERETIC_LEAD_STYLE_FAN
	lead.combat_resource = 0
	TEST_ASSERT(!revolver.fire_at(victim, user) && !revolver.fan_timer, "Пустой барабан веера не даёт.")

/// Выроненный или уничтоженный револьвер обрывает прицел и веер: таймеров и выстрелов после этого нет.
/datum/unit_test/heretic_lead_drum_cleanup/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_LEAD)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_lead/lead = heretic.get_knowledge(/datum/eldritch_knowledge/base_lead)
	var/obj/item/heretic_path_relic/lead_revolver/revolver = heretic_lead_test_revolver(heretic, user)
	var/mob/living/carbon/human/victim = heretic_lead_test_crew(heretic_lead_test_spot(3, 0))
	lead.drum_style = HERETIC_LEAD_STYLE_AIMED
	lead.combat_resource = 3
	TEST_ASSERT(revolver.fire_at(victim, user) == TRUE, "Прицел взят.")
	user.dropItemToGround(revolver)
	TEST_ASSERT(!revolver.focus_timer && !revolver.focus_beam, "Выроненный револьвер обрывает прицел.")
	user.put_in_hands(revolver)
	lead.drum_style = HERETIC_LEAD_STYLE_FAN
	COOLDOWN_RESET(revolver, shot_cooldown)
	TEST_ASSERT(revolver.fire_at(victim, user), "Веер начат.")
	qdel(revolver)
	TEST_ASSERT(!revolver.fan_timer, "Уничтоженный револьвер обрывает веер.")
	TEST_ASSERT(heretic_lead_test_wait(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(heretic_lead_test_time_passed), world.time + HERETIC_LEAD_FAN_TELEGRAPH + HERETIC_LEAD_FAN_TIME), 3 SECONDS, "веер после уничтожения"), "Время веера прошло.")
	TEST_ASSERT(lead.combat_resource == 3 && victim.getBruteLoss() == 0, "После уничтожения веер не стреляет.")

/// Попадания до крита по стоящему вплотную бойцу ОБР; Свинец перед каждым выстрелом свежий, без полного барабана.
/datum/unit_test/proc/heretic_lead_test_hits_to_crit(obj/item/heretic_path_relic/lead_revolver/revolver, datum/eldritch_knowledge/base_lead/lead, mob/living/user, mob/living/carbon/human/ert, position, aimed)
	for(var/hit in 1 to 20)
		lead.combat_resource = 3
		lead.turn_drum(position)
		heretic_lead_test_fly(revolver.shoot_round(ert, user, null, lead, aimed = aimed))
		if(ert.health <= HEALTH_THRESHOLD_CRIT)
			return hit
	return 21

/// Тяжёлая броня ОБР (скафандр красной тревоги СБ): Свинцовая пуля доводит до крита за 4-5 попаданий, прицельная за 2-3, Бронебойная не хуже, принятые души ускоряют.
/datum/unit_test/heretic_lead_ert_armor/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_LEAD)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_lead/lead = heretic.get_knowledge(/datum/eldritch_knowledge/base_lead)
	var/obj/item/heretic_path_relic/lead_revolver/revolver = heretic_lead_test_revolver(heretic, user)
	user.zone_selected = BODY_ZONE_CHEST
	var/list/spots = list(get_step(user, EAST), get_step(user, NORTH), get_step(user, NORTHEAST), get_step(user, WEST))
	var/list/erts = list()
	for(var/turf/spot as anything in spots)
		var/mob/living/carbon/human/ert = allocate(/mob/living/carbon/human, spot)
		ert.equip_to_slot_or_del(new /obj/item/clothing/suit/space/hardsuit/ert/alert/sec(ert), ITEM_SLOT_OCLOTHING)
		TEST_ASSERT(istype(ert.wear_suit, /obj/item/clothing/suit/space/hardsuit/ert/alert/sec) && ert.brc_mitigation >= 20, "Боец в скафандре красной тревоги.")
		erts += ert
	var/plain = heretic_lead_test_hits_to_crit(revolver, lead, user, erts[1], 1, FALSE)
	var/aimed = heretic_lead_test_hits_to_crit(revolver, lead, user, erts[2], 1, TRUE)
	heretic.total_sacrifices = HERETIC_LEAD_SACRIFICE_PENETRATION_CAP / HERETIC_LEAD_SACRIFICE_PENETRATION
	var/aimed_souls = heretic_lead_test_hits_to_crit(revolver, lead, user, erts[3], 1, TRUE)
	heretic.total_sacrifices = 0
	heretic.gain_knowledge(/datum/eldritch_knowledge/final_eldritch/lead_final)
	var/datum/eldritch_knowledge/final_eldritch/lead_final/finale = heretic.get_knowledge(/datum/eldritch_knowledge/final_eldritch/lead_final)
	finale.finished = TRUE
	var/piercing = heretic_lead_test_hits_to_crit(revolver, lead, user, erts[4], 1, FALSE)
	log_test("\tОБР красной тревоги, попаданий до крита: Свинцовая [plain], прицельная [aimed], прицельная с душами [aimed_souls], Бронебойная [piercing]")
	TEST_ASSERT(plain >= 4 && plain <= 5, "Обычная Свинцовая валит ОБР за 4-5 попаданий: [plain].")
	TEST_ASSERT(aimed >= 2 && aimed <= 3 && aimed < plain, "Прицельная Свинцовая валит ОБР за 2-3 попадания: [aimed].")
	TEST_ASSERT(piercing >= 2 && piercing <= plain, "Бронебойная берёт ОБР не хуже Свинцовой: [piercing].")
	TEST_ASSERT(aimed_souls <= aimed, "Души прибавляют пробития: [aimed_souls] против [aimed].")

/// Числа барабана в кодексе, осмотре револьвера и уроке совпадают с дефайнами.
/datum/unit_test/heretic_lead_drum_texts/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_LEAD)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/obj/item/heretic_path_relic/lead_revolver/revolver = heretic_lead_test_revolver(heretic, user)
	var/knockdown = replacetext("[HERETIC_LEAD_HEAVY_KNOCKDOWN / (1 SECONDS)]", ".", ",")
	var/list/numbers = list(
		/datum/eldritch_knowledge/lead_relic = list("Свинцовая: [HERETIC_LEAD_REVOLVER_DAMAGE] ушибов", "Тяжёлая: [HERETIC_LEAD_ROUND_DAMAGE] и валит на [knockdown] секунды", "камору за [replacetext("[HERETIC_LEAD_DRUM_TURN / (1 SECONDS)]", ".", ",")] секунды", "раз в [HERETIC_LEAD_SPIN_COOLDOWN / (1 SECONDS)] секунд", "на [HERETIC_LEAD_LUCK_BONUS]% сильнее", "+[HERETIC_LEAD_AIM_BONUS]% урона", "+[HERETIC_LEAD_HEADSHOT_BONUS]% урона", "+[HERETIC_LEAD_SACRIFICE_PENETRATION] пробития всем пулям, до [HERETIC_LEAD_SACRIFICE_PENETRATION_CAP]", "пробитие [HERETIC_LEAD_REVOLVER_PENETRATION]", "удар рукоятью: [HERETIC_LEAD_BUTT_DAMAGE] ушибов, замедление на [HERETIC_LEAD_BUTT_SLOW / (1 SECONDS)] секунды"),
		/datum/eldritch_knowledge/lead_mark = list("пуля на [HERETIC_LEAD_ROUND_DAMAGE] ушибов вешает Мишень"),
		/datum/eldritch_knowledge/spell/lead_catch = list("Пороховая камора: [HERETIC_LEAD_POWDER_DAMAGE] ушибов", "ещё [HERETIC_LEAD_POWDER_BURN] ожогов"),
		/datum/eldritch_knowledge/spell/lead_ricochet = list("Звонкая камора: [HERETIC_LEAD_ROUND_DAMAGE] ушибов", "рикошет на [HERETIC_LEAD_RING_DAMAGE]", "в [HERETIC_LEAD_RING_RANGE] клетках"),
		/datum/eldritch_knowledge/final_eldritch/lead_final = list("Свинцовая камора - Бронебойная"),
	)
	for(var/knowledge_type in numbers)
		var/datum/eldritch_knowledge/knowledge = allocate(knowledge_type)
		for(var/fragment in numbers[knowledge_type])
			TEST_ASSERT(findtext(knowledge.desc, fragment), "[knowledge_type]: в описании есть «[fragment]».")
	TEST_ASSERT(HERETIC_LEAD_AIM_TIME == 1 SECONDS && HERETIC_LEAD_FAN_TIME == 1 SECONDS, "Слова «секунда без движения» и «за секунду» держатся дефайнов.")
	var/examined = jointext(revolver.examine(user), " ")
	for(var/fragment in list("на [HERETIC_LEAD_LUCK_BONUS]% сильнее", "раз в [HERETIC_LEAD_SPIN_COOLDOWN / (1 SECONDS)] секунд", "Тяжёлая [HERETIC_LEAD_ROUND_DAMAGE] и валит на [knockdown] секунды", "Пороховая [HERETIC_LEAD_POWDER_DAMAGE]", "рикошет на [HERETIC_LEAD_RING_DAMAGE] в соседа в [HERETIC_LEAD_RING_RANGE] клетках", "Под курком: Свинцовая", "удар рукоятью: [HERETIC_LEAD_BUTT_DAMAGE] ушибов", "Патронташ: 0 из [HERETIC_LEAD_BANDOLIER]"))
		TEST_ASSERT(findtext(examined, fragment), "Осмотр револьвера хозяином называет «[fragment]».")
	var/mob/living/carbon/human/stranger = heretic_lead_test_crew(get_step(user, EAST))
	TEST_ASSERT(!findtext(jointext(revolver.examine(stranger), " "), "Под курком"), "Чужому осмотр барабан не раскрывает.")

/proc/heretic_lead_test_belt_text(datum/eldritch_knowledge/base_lead/lead)
	for(var/mutable_appearance/layer as anything in lead.drum_overlays)
		if(layer.maptext)
			return layer.maptext
	return ""

/// Патронташ: Свинец сверх барабана ложится на пояс до 6, способности добирают из него, опустевший барабан за секунду дозаряжается, значок показывает запас, смерть обнуляет.
/datum/unit_test/heretic_lead_bandolier/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_LEAD)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_lead/lead = heretic.get_knowledge(/datum/eldritch_knowledge/base_lead)
	var/obj/item/heretic_path_relic/lead_revolver/revolver = heretic_lead_test_revolver(heretic, user)
	lead.combat_resource = HERETIC_LEAD_CAPACITY - 1
	lead.gain_combat_resource(3)
	TEST_ASSERT(lead.combat_resource == HERETIC_LEAD_CAPACITY && lead.bandolier == 2, "Сверх полного барабана Свинец ложится в патронташ: [lead.combat_resource]+[lead.bandolier].")
	lead.gain_combat_resource(HERETIC_LEAD_BANDOLIER)
	TEST_ASSERT_EQUAL(lead.bandolier, HERETIC_LEAD_BANDOLIER, "Патронташ держит не больше [HERETIC_LEAD_BANDOLIER].")
	TEST_ASSERT(findtext(heretic_lead_test_belt_text(lead), "+[HERETIC_LEAD_BANDOLIER]"), "Значок запаса показывает патронташ.")
	TEST_ASSERT(findtext(lead.combat_resource_state(), "Патронташ: [HERETIC_LEAD_BANDOLIER] из [HERETIC_LEAD_BANDOLIER]"), "Описание значка называет патронташ.")
	lead.combat_resource = 1
	lead.bandolier = 3
	TEST_ASSERT(lead.spend_combat_resource(HERETIC_LEAD_NAMED_COST), "Способность добирает недостающий Свинец из патронташа.")
	TEST_ASSERT(lead.combat_resource == 0 && lead.bandolier == 2, "Списано из барабана и патронташа: [lead.combat_resource]+[lead.bandolier].")
	TEST_ASSERT_NOTNULL(lead.reload_timer, "Опустевший барабан начинает дозарядку.")
	TEST_ASSERT(findtext(lead.combat_resource_state(), "дозаряжается"), "Описание значка показывает дозарядку.")
	COOLDOWN_RESET(revolver, shot_cooldown)
	TEST_ASSERT(!revolver.fire_at(heretic_lead_test_spot(4, 4), user) && lead.bandolier == 2, "Во время дозарядки выстрела нет.")
	var/started = world.time
	TEST_ASSERT(heretic_lead_test_wait(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(heretic_lead_test_var_null), lead, NAMEOF(lead, reload_timer)), HERETIC_LEAD_RELOAD_TIME + 2 SECONDS, "дозарядка"), "Дозарядка закончилась.")
	TEST_ASSERT(world.time - started <= HERETIC_LEAD_RELOAD_TIME + 0.5 SECONDS, "Дозарядка идёт [HERETIC_LEAD_RELOAD_TIME / (1 SECONDS)] секунду: [world.time - started] дс.")
	TEST_ASSERT(lead.combat_resource == 2 && lead.bandolier == 0, "Патронташ ушёл в барабан: [lead.combat_resource]+[lead.bandolier].")
	TEST_ASSERT_EQUAL(heretic_lead_test_belt_text(lead), "", "Пустой патронташ на значке не виден.")
	lead.bandolier = 4
	user.death()
	heretic.handle_death(user)
	TEST_ASSERT(lead.combat_resource == 0 && lead.bandolier == 0, "Смерть обнуляет барабан и патронташ: [lead.combat_resource]+[lead.bandolier].")

/// Под огнём: выстрел из огнестрела в сторону еретика кладёт единицу в патронташ, от одного стрелка не чаще раза в секунду; мимо и лазер - нет.
/datum/unit_test/heretic_lead_under_fire/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_LEAD)
	var/mob/living/carbon/human/user = heretic.owner.current
	user.forceMove(heretic_lead_test_spot(4, 2))
	var/datum/eldritch_knowledge/base_lead/lead = heretic.get_knowledge(/datum/eldritch_knowledge/base_lead)
	var/mob/living/carbon/human/gunner = heretic_lead_test_crew(heretic_lead_test_spot(0, 2))
	var/obj/item/gun/ballistic/automatic/pistol/pistol = allocate(/obj/item/gun/ballistic/automatic/pistol, get_turf(gunner))
	gunner.put_in_hands(pistol)
	pistol.fire_delay = 0
	pistol.process_fire(heretic_lead_test_spot(0, 5), gunner)
	TEST_ASSERT_EQUAL(lead.bandolier, 0, "Выстрел в сторону от еретика патронташ не пополняет.")
	pistol.last_fire = 0
	pistol.process_fire(heretic_lead_test_spot(2, 2), gunner)
	TEST_ASSERT_EQUAL(lead.bandolier, 1, "Выстрел в сторону еретика кладёт единицу в патронташ, даже мимо.")
	pistol.last_fire = 0
	pistol.process_fire(user, gunner)
	TEST_ASSERT_EQUAL(lead.bandolier, 1, "Один стрелок пополняет патронташ не чаще раза в [HERETIC_LEAD_UNDER_FIRE_COOLDOWN / (1 SECONDS)] секунду.")
	var/mob/living/carbon/human/second = heretic_lead_test_crew(heretic_lead_test_spot(4, 0))
	var/obj/item/gun/energy/laser/laser = allocate(/obj/item/gun/energy/laser, get_turf(second))
	second.put_in_hands(laser)
	laser.process_fire(user, second)
	TEST_ASSERT_EQUAL(lead.bandolier, 1, "Лазер патронташ не пополняет.")
	second.dropItemToGround(laser)
	var/obj/item/gun/ballistic/automatic/pistol/other = allocate(/obj/item/gun/ballistic/automatic/pistol, get_turf(second))
	second.put_in_hands(other)
	other.process_fire(user, second)
	TEST_ASSERT_EQUAL(lead.bandolier, 2, "Каждый стрелок пополняет патронташ сам.")
	TEST_ASSERT(heretic_lead_test_wait(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(heretic_lead_test_time_passed), world.time + HERETIC_LEAD_UNDER_FIRE_COOLDOWN), HERETIC_LEAD_UNDER_FIRE_COOLDOWN + 1 SECONDS, "пауза стрелка"), "Прошла секунда.")
	pistol.last_fire = 0
	pistol.process_fire(user, gunner)
	TEST_ASSERT_EQUAL(lead.bandolier, 3, "Через секунду тот же стрелок пополняет патронташ снова.")

/// Удар рукоятью в «Вреде» вплотную: 20 ушибов, сбитый шаг и единица Свинца, не чаще раза в секунду; убийство из Шестизарядника - ещё три Свинца, труп - ничего.
/datum/unit_test/heretic_lead_pistol_whip/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_LEAD)
	var/mob/living/carbon/human/user = heretic.owner.current
	user.forceMove(heretic_lead_test_spot(0, 2))
	var/datum/eldritch_knowledge/base_lead/lead = heretic.get_knowledge(/datum/eldritch_knowledge/base_lead)
	var/obj/item/heretic_path_relic/lead_revolver/revolver = heretic_lead_test_revolver(heretic, user)
	var/mob/living/carbon/human/victim = heretic_lead_test_crew(get_step(user, EAST))
	lead.combat_resource = 2
	user.a_intent = INTENT_HARM
	revolver.melee_attack_chain(user, victim)
	TEST_ASSERT(abs(victim.getBruteLoss() - HERETIC_LEAD_BUTT_DAMAGE) < 1, "Рукоять бьёт на [HERETIC_LEAD_BUTT_DAMAGE] ушибов: [victim.getBruteLoss()].")
	TEST_ASSERT_NOTNULL(victim.has_status_effect(/datum/status_effect/heretic_lead_slowed/butt), "Удар рукоятью сбивает шаг.")
	TEST_ASSERT_EQUAL(lead.combat_resource, 3, "Удар рукоятью даёт единицу Свинца.")
	TEST_ASSERT_NULL(locate(/obj/item/ammo_casing/heretic_lead) in get_turf(user), "Вплотную во «Вреде» Шестизарядник бьёт, а не стреляет.")
	revolver.attack(victim, user)
	TEST_ASSERT(abs(victim.getBruteLoss() - HERETIC_LEAD_BUTT_DAMAGE) < 1 && lead.combat_resource == 3, "Удар рукоятью не чаще раза в [HERETIC_LEAD_BUTT_COOLDOWN / (1 SECONDS)] секунду.")
	var/mob/living/carbon/human/doomed = heretic_lead_test_crew(heretic_lead_test_spot(0, 4))
	doomed.setOxyLoss(170)
	TEST_ASSERT(doomed.stat != DEAD, "Цель ещё жива.")
	lead.combat_resource = 1
	COOLDOWN_RESET(revolver, shot_cooldown)
	heretic_lead_test_fly(revolver.fire_at(doomed, user), 2)
	TEST_ASSERT(doomed.stat == DEAD, "Пуля добила цель: здоровье [doomed.health].")
	TEST_ASSERT_EQUAL(lead.combat_resource, 1 + HERETIC_LEAD_KILL_LEAD, "Убийство из Шестизарядника - единица возврата и ещё [HERETIC_LEAD_KILL_LEAD].")
	COOLDOWN_RESET(revolver, shot_cooldown)
	heretic_lead_test_fly(revolver.fire_at(doomed, user), 2)
	TEST_ASSERT_EQUAL(lead.combat_resource, HERETIC_LEAD_KILL_LEAD, "Выстрел в труп Свинец не возвращает.")

/// Еретик Свинца с Мишенью и выбранной Школой.
/datum/unit_test/proc/heretic_lead_test_school(school_id, turf/spot)
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_LEAD)
	var/mob/living/carbon/human/user = heretic.owner.current
	if(spot)
		user.forceMove(spot)
	heretic.gain_knowledge(/datum/eldritch_knowledge/lead_mark)
	var/datum/eldritch_knowledge/base_lead/lead = heretic.get_knowledge(/datum/eldritch_knowledge/base_lead)
	if(school_id && !lead.choose_school(user, school_id))
		TEST_FAIL("Школа [school_id] не выбрана: [lead.lead_failure]")
	return lead

/datum/unit_test/proc/heretic_lead_test_armed(turf/spot)
	var/mob/living/carbon/human/crew = heretic_lead_test_crew(spot)
	var/obj/item/gun/ballistic/automatic/pistol/gun = allocate(/obj/item/gun/ballistic/automatic/pistol, spot)
	crew.put_in_hands(gun)
	return crew

/// Школа стрельбы: кнопка с четвёртой ступени, выбор раз и до сброса пути, приём Школы на кнопке и после смены тела, осмотр и описание значка называют Школу.
/datum/unit_test/heretic_lead_school_choice/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_LEAD)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_lead/lead = heretic.get_knowledge(/datum/eldritch_knowledge/base_lead)
	var/mob/living/carbon/human/witness = heretic_lead_test_crew(get_step(user, EAST))
	TEST_ASSERT(findtext(lead.school_block_reason(user), "четвёртой"), "До четвёртой ступени Школы нет.")
	TEST_ASSERT(!lead.choose_school(user, HERETIC_LEAD_SCHOOL_HUNTER), "Без Мишени Школу не выбрать.")
	heretic.gain_knowledge(/datum/eldritch_knowledge/lead_mark)
	TEST_ASSERT_NOTNULL(locate(/obj/effect/proc_holder/spell/self/heretic_lead/school) in user.mind.spell_list, "Мишень даёт кнопку «Школа стрельбы».")
	TEST_ASSERT(findtext(lead.combat_resource_state(), "ещё не выбрана"), "Описание значка напоминает о выборе.")
	TEST_ASSERT(!lead.choose_school(user, "none"), "Неизвестную Школу не выбрать.")
	TEST_ASSERT(lead.choose_school(user, HERETIC_LEAD_SCHOOL_GUNSLINGER), "Школа Стрелка: [lead.lead_failure]")
	TEST_ASSERT_EQUAL(lead.school, HERETIC_LEAD_SCHOOL_GUNSLINGER, "Школа выбрана.")
	TEST_ASSERT_NULL(locate(/obj/effect/proc_holder/spell/self/heretic_lead/school) in user.mind.spell_list, "Кнопка выбора уходит после выбора.")
	TEST_ASSERT_NOTNULL(locate(/obj/effect/proc_holder/spell/self/heretic_lead/standoff) in user.mind.spell_list, "Стрелок получает кнопку «Мгновение».")
	TEST_ASSERT(findtext(lead.combat_resource_state(), "Школа: Стрелок"), "Описание значка называет Школу.")
	lead.combat_resource = HERETIC_LEAD_SCENT_SHOWN
	var/datum/heretic_lead_school/gunslinger = GLOB.heretic_lead_schools[HERETIC_LEAD_SCHOOL_GUNSLINGER]
	TEST_ASSERT(findtext(jointext(user.examine(witness), " "), gunslinger.scent_line), "Запах пороха с оттенком Школы виден вблизи.")
	TEST_ASSERT(!lead.choose_school(user, HERETIC_LEAD_SCHOOL_CANNONEER) && findtext(lead.lead_failure, "сбросом пути"), "Школа необратима до сброса пути.")
	TEST_ASSERT(findtext(lead.tripwire_block_reason(user, get_step(user, NORTH)), "Охотника") && findtext(lead.charge_block_reason(user, get_step(user, NORTH)), "Канонира"), "Чужие приёмы Стрелку недоступны.")
	var/mob/living/carbon/human/new_body = allocate(/mob/living/carbon/human, heretic_lead_test_spot(4, 4))
	heretic.owner.transfer_to(new_body)
	TEST_ASSERT_NOTNULL(locate(/obj/effect/proc_holder/spell/self/heretic_lead/standoff) in new_body.mind.spell_list, "Приём Школы переходит в новое тело.")
	TEST_ASSERT_NULL(locate(/obj/effect/proc_holder/spell/self/heretic_lead/school) in new_body.mind.spell_list, "Кнопка выбора не возвращается.")
	heretic.release_path(new_body)
	TEST_ASSERT(QDELETED(lead), "Сброс пути снимает знание со Школой.")
	TEST_ASSERT(heretic.research_knowledge(/datum/eldritch_knowledge/base_lead, new_body), "Путь выбирается заново.")
	var/datum/eldritch_knowledge/base_lead/fresh = heretic.get_knowledge(/datum/eldritch_knowledge/base_lead)
	TEST_ASSERT(fresh && isnull(fresh.school), "После сброса Школы нет.")
	TEST_ASSERT_NULL(locate(/obj/effect/proc_holder/spell/self/heretic_lead/standoff) in new_body.mind.spell_list, "Сброс снимает приём Школы.")

/// У каждой Школы нарисованы кнопка выбора, кнопка приёма и трассер, есть звук выбора; трассер ложится на пулю, а дым красится.
/datum/unit_test/heretic_lead_school_sheets/Run()
	var/list/actions = icon_states('modular_bluemoon/icons/obj/heretic_actions.dmi')
	var/list/effects = icon_states(HERETIC_LEAD_SCHOOLS_FX_ICON)
	TEST_ASSERT("lead_school" in actions, "Кнопка «Школа стрельбы» нарисована.")
	for(var/school_id in GLOB.heretic_lead_schools)
		var/datum/heretic_lead_school/school = GLOB.heretic_lead_schools[school_id]
		var/obj/effect/proc_holder/spell/spell = school.spell_type
		TEST_ASSERT(school.choice_state in actions, "[school.name]: кнопка выбора нарисована.")
		TEST_ASSERT(initial(spell.action_icon_state) in actions, "[school.name]: кнопка приёма нарисована.")
		TEST_ASSERT(school.tracer_state in effects, "[school.name]: трассер нарисован.")
		TEST_ASSERT(length(GLOB.heretic_lead_sounds["school_[school_id]"]), "[school.name]: есть звук выбора.")
	for(var/state in list("lead_tripwire", "lead_tripwire_seen", "lead_pop", "lead_standoff_ring", "lead_slow_bullet", "lead_powder_charge", "lead_powder_charge_armed"))
		TEST_ASSERT(state in effects, "Эффект [state] нарисован.")
	var/datum/eldritch_knowledge/base_lead/lead = heretic_lead_test_school(HERETIC_LEAD_SCHOOL_HUNTER)
	var/obj/item/projectile/bullet/heretic_lead/probe = allocate(/obj/item/projectile/bullet/heretic_lead, run_loc_floor_bottom_left)
	var/mutable_appearance/tracer = lead.school_tracer(probe)
	TEST_ASSERT(tracer?.icon_state == "lead_tracer_hunter" && (tracer.appearance_flags & RESET_COLOR), "Пуля Охотника несёт бледный трассер своего цвета.")
	var/datum/heretic_lead_school/hunter = GLOB.heretic_lead_schools[HERETIC_LEAD_SCHOOL_HUNTER]
	TEST_ASSERT_EQUAL(lead.smoke_tint(), hunter.smoke_color, "Дым Охотника своего цвета.")

/// Стрелок: каждый вооружённый враг на виду, до 4, ускоряет шаг и выстрелы; безоружный и спрятанный за стеной не в счёт.
/datum/unit_test/heretic_lead_gunslinger_crowd/Run()
	var/datum/eldritch_knowledge/base_lead/lead = heretic_lead_test_school(HERETIC_LEAD_SCHOOL_GUNSLINGER, heretic_lead_test_spot(2, 0))
	var/mob/living/carbon/human/user = lead.lead_body
	var/datum/antagonist/heretic/heretic = lead.owner_heretic()
	var/obj/item/heretic_path_relic/lead_revolver/revolver = heretic_lead_test_revolver(heretic, user)
	var/mob/living/carbon/human/first = heretic_lead_test_armed(heretic_lead_test_spot(0, 2))
	heretic_lead_test_armed(heretic_lead_test_spot(4, 2))
	heretic_lead_test_crew(heretic_lead_test_spot(2, 2))
	allocate(/obj/structure/falsewall, heretic_lead_test_spot(2, 3))
	heretic_lead_test_armed(heretic_lead_test_spot(2, 4))
	lead.on_life(user)
	TEST_ASSERT_EQUAL(lead.crowd, 2, "Стрелок считает вооружённых на виду, без безоружного и спрятанного за стеной.")
	TEST_ASSERT(user.has_movespeed_modifier(/datum/movespeed_modifier/heretic_lead_crowd), "Толпа ускоряет шаг Стрелка.")
	TEST_ASSERT(findtext(lead.combat_resource_state(), "Вооружённых врагов на виду: 2"), "Описание значка называет толпу.")
	lead.combat_resource = 2
	revolver.fire_at(heretic_lead_test_spot(4, 4), user)
	var/expected = CLICK_CD_RANGE * (100 - 2 * HERETIC_LEAD_CROWD_RATE) / 100
	TEST_ASSERT(abs(COOLDOWN_TIMELEFT(revolver, shot_cooldown) - expected) < 0.6, "Два ствола ускоряют выстрел на [2 * HERETIC_LEAD_CROWD_RATE]%: [COOLDOWN_TIMELEFT(revolver, shot_cooldown)] против [expected].")
	var/list/row = list()
	for(var/dx in 0 to 4)
		row += heretic_lead_test_armed(heretic_lead_test_spot(dx, -1))
	lead.on_life(user)
	TEST_ASSERT_EQUAL(lead.crowd, HERETIC_LEAD_CROWD_CAP, "Толпа злит Стрелка не больше чем на [HERETIC_LEAD_CROWD_CAP] стволов.")
	for(var/obj/item/gun/gun in first.held_items)
		first.dropItemToGround(gun)
	QDEL_LIST(row)
	lead.on_life(user)
	TEST_ASSERT_EQUAL(lead.crowd, 1, "Опущенный ствол и ушедшие из счёта выбывают.")
	lead.on_body_lose(user)
	TEST_ASSERT(!user.has_movespeed_modifier(/datum/movespeed_modifier/heretic_lead_crowd), "Смена тела снимает ускорение толпы.")

/// Мгновение: три разных стрелка за 3 секунды - кольцо, чужие пули рядом вдвое медленнее, 3 мгновенных прицельных выстрела, откат 60 секунд; кнопка работает против трёх стволов на виду.
/datum/unit_test/heretic_lead_standoff/Run()
	var/datum/eldritch_knowledge/base_lead/lead = heretic_lead_test_school(HERETIC_LEAD_SCHOOL_GUNSLINGER, heretic_lead_test_spot(4, 2))
	var/mob/living/carbon/human/user = lead.lead_body
	var/datum/antagonist/heretic/heretic = lead.owner_heretic()
	var/obj/item/heretic_path_relic/lead_revolver/revolver = heretic_lead_test_revolver(heretic, user)
	var/obj/effect/proc_holder/spell/self/heretic_lead/standoff/button = locate() in user.mind.spell_list
	TEST_ASSERT_NOTNULL(button, "У Стрелка есть кнопка «Мгновение».")
	TEST_ASSERT(findtext(lead.standoff_block_reason(user), "хотя бы [HERETIC_LEAD_STANDOFF_SHOOTERS] вооружённых"), "Без трёх стволов кнопка называет условие.")
	var/list/gunners = list()
	for(var/dy in list(0, 2, 4))
		gunners += heretic_lead_test_crew(heretic_lead_test_spot(0, dy))
	heretic_lead_test_shot(gunners[1], user)
	heretic_lead_test_shot(gunners[2], user)
	TEST_ASSERT_NULL(user.has_status_effect(/datum/status_effect/heretic_lead_standoff), "Два стрелка - ещё не дуэль.")
	heretic_lead_test_shot(gunners[3], user)
	var/datum/status_effect/heretic_lead_standoff/standoff = user.has_status_effect(/datum/status_effect/heretic_lead_standoff)
	TEST_ASSERT_NOTNULL(standoff, "Три разных стрелка за [HERETIC_LEAD_STANDOFF_WINDOW / (1 SECONDS)] секунды начинают Мгновение.")
	TEST_ASSERT(standoff?.ring, "Под ногами кольцо Мгновения.")
	TEST_ASSERT(!COOLDOWN_FINISHED(lead, standoff_cooldown) && button.charge_counter < button.charge_max, "Мгновение уходит на откат, кнопка показывает его.")
	TEST_ASSERT_EQUAL(lead.standoff_shots, HERETIC_LEAD_STANDOFF_SHOTS, "Мгновение даёт [HERETIC_LEAD_STANDOFF_SHOTS] мгновенных выстрела.")
	var/mob/living/carbon/human/late = heretic_lead_test_crew(heretic_lead_test_spot(-1, 1))
	var/obj/item/projectile/slow = heretic_lead_test_bullet(late, user)
	slow.fire()
	var/full_speed = slow.pixels_per_second
	for(var/step in 1 to 8)
		if(QDELETED(slow) || HAS_TRAIT(slow, "heretic_lead_slowed_bullet"))
			break
		slow.process(0.05)
	TEST_ASSERT(!QDELETED(slow) && HAS_TRAIT(slow, "heretic_lead_slowed_bullet"), "Чужая пуля в [HERETIC_LEAD_STANDOFF_RANGE] клетках вязнет.")
	TEST_ASSERT(abs(slow.pixels_per_second - full_speed * HERETIC_LEAD_STANDOFF_SLOW / 100) < 0.1, "Пуля летит вдвое медленнее: [slow.pixels_per_second] из [full_speed].")
	user.remove_status_effect(/datum/status_effect/heretic_lead_standoff)
	TEST_ASSERT(abs(slow.pixels_per_second - full_speed) < 0.1 && !HAS_TRAIT(slow, "heretic_lead_slowed_bullet"), "Конец Мгновения возвращает пуле скорость.")
	qdel(slow)
	var/mob/living/carbon/human/victim = gunners[2]
	lead.combat_resource = 3
	lead.turn_drum(1)
	COOLDOWN_RESET(revolver, shot_cooldown)
	var/obj/item/projectile/bullet/heretic_lead/fast = revolver.fire_at(victim, user)
	TEST_ASSERT(istype(fast) && !revolver.focus_timer, "Мгновенный выстрел уходит сразу, без прицеливания.")
	TEST_ASSERT(abs(fast?.damage - HERETIC_LEAD_REVOLVER_DAMAGE * (100 + HERETIC_LEAD_AIM_BONUS) / 100) < 0.1, "Мгновенный выстрел бьёт как прицельный: [fast?.damage].")
	TEST_ASSERT_EQUAL(lead.standoff_shots, HERETIC_LEAD_STANDOFF_SHOTS - 1, "Мгновенных выстрелов стало меньше.")
	heretic_lead_test_fly(fast)
	for(var/mob/living/carbon/human/gunner as anything in gunners)
		heretic_lead_test_shot(gunner, user)
	TEST_ASSERT_NULL(user.has_status_effect(/datum/status_effect/heretic_lead_standoff), "На откате новой дуэли нет.")
	COOLDOWN_RESET(lead, standoff_cooldown)
	for(var/mob/living/carbon/human/gunner as anything in gunners)
		var/obj/item/gun/ballistic/automatic/pistol/gun = allocate(/obj/item/gun/ballistic/automatic/pistol, get_turf(gunner))
		gunner.put_in_hands(gun)
	button.charge_counter = button.charge_max
	button.cast(list(user), user)
	TEST_ASSERT_NOTNULL(user.has_status_effect(/datum/status_effect/heretic_lead_standoff), "Против трёх стволов на виду кнопка начинает Мгновение.")

/// Три стрелка в 5 клетках стреляют в Стрелка из-за спин своих: пули до него не долетают, но выстрелы в его сторону начинают Мгновение; выстрел в сторону - нет.
/datum/unit_test/heretic_lead_standoff_volley/Run()
	var/datum/eldritch_knowledge/base_lead/lead = heretic_lead_test_school(HERETIC_LEAD_SCHOOL_GUNSLINGER, heretic_lead_test_spot(0, 2))
	var/mob/living/carbon/human/user = lead.lead_body
	var/list/gunners = list()
	for(var/dy in list(1, 2, 3))
		gunners += heretic_lead_test_armed(heretic_lead_test_spot(5, dy))
		heretic_lead_test_crew(heretic_lead_test_spot(2, dy))
	var/mob/living/carbon/human/away = gunners[3]
	var/obj/item/gun/away_gun = locate() in away.held_items
	away_gun.process_fire(heretic_lead_test_spot(5, 5), gunners[3])
	TEST_ASSERT(!length(lead.duel_shooters), "Выстрел не в сторону Стрелка в счёт дуэли не идёт.")
	for(var/mob/living/carbon/human/gunner as anything in gunners)
		var/obj/item/gun/gun = locate() in gunner.held_items
		gun.process_fire(user, gunner)
		sleep(0.4 SECONDS)
	TEST_ASSERT_NOTNULL(user.has_status_effect(/datum/status_effect/heretic_lead_standoff), "Три стрелка в [HERETIC_LEAD_UNDER_FIRE_RANGE] клетках за [HERETIC_LEAD_STANDOFF_WINDOW / (1 SECONDS)] секунды начинают Мгновение: засчитано [length(lead.duel_shooters)].")
	TEST_ASSERT_EQUAL(user.getBruteLoss(), 0, "Пули легли в спины своих, до Стрелка не долетев.")

/// Свои выстрелы Стрелка в Мгновении и Ловле пули: летят с полной скоростью, ранят цель и не ловятся.
/datum/unit_test/heretic_lead_standoff_own_shots/Run()
	var/datum/eldritch_knowledge/base_lead/lead = heretic_lead_test_school(HERETIC_LEAD_SCHOOL_GUNSLINGER, heretic_lead_test_spot(0, 2))
	var/mob/living/carbon/human/user = lead.lead_body
	var/datum/antagonist/heretic/heretic = lead.owner_heretic()
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/lead_catch)
	var/obj/item/heretic_path_relic/lead_revolver/revolver = heretic_lead_test_revolver(heretic, user)
	var/mob/living/carbon/human/victim = heretic_lead_test_crew(heretic_lead_test_spot(4, 2))
	TEST_ASSERT(lead.start_standoff(user, FALSE), "Мгновение: [lead.lead_failure]")
	var/datum/eldritch_knowledge/spell/lead_catch/catching = heretic.get_knowledge(/datum/eldritch_knowledge/spell/lead_catch)
	catching.granted_spell.cast(list(user), user)
	var/datum/status_effect/heretic_lead_catch/window = user.has_status_effect(/datum/status_effect/heretic_lead_catch)
	TEST_ASSERT_NOTNULL(window, "Ловля пули открыта.")
	lead.combat_resource = 3
	COOLDOWN_RESET(revolver, shot_cooldown)
	var/obj/item/projectile/bullet/heretic_lead/shot = revolver.fire_at(victim, user)
	TEST_ASSERT(istype(shot), "В Ловле и Мгновении Шестизарядник стреляет.")
	var/full_speed = shot.pixels_per_second
	TEST_ASSERT(heretic_lead_test_wait(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(heretic_lead_test_brute_at_least), victim, 1), 2 SECONDS, "свой выстрел в Мгновении"), "Свой выстрел долетает до цели.")
	TEST_ASSERT(QDELETED(shot) || (shot.pixels_per_second == full_speed && !HAS_TRAIT(shot, "heretic_lead_slowed_bullet")), "Своя пуля не вязнет в кольце.")
	var/brute_before = victim.getBruteLoss()
	var/obj/item/projectile/pellet = lead.finger_gun(user, victim)
	TEST_ASSERT_NOTNULL(pellet, "Палец-ствол стреляет: [lead.lead_failure]")
	TEST_ASSERT(heretic_lead_test_wait(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(heretic_lead_test_brute_at_least), victim, brute_before + 1), 2 SECONDS, "дробина в Мгновении"), "Дробина долетает до цели.")
	TEST_ASSERT_EQUAL(window.caught, 0, "Ловля не ест свои пули.")

/// Серия Стрелка: попадания Шестизарядника по трём разным людям за 6 секунд дают ещё 2 Свинца; без Школы - нет.
/datum/unit_test/heretic_lead_spree/Run()
	var/datum/eldritch_knowledge/base_lead/lead = heretic_lead_test_school(null, heretic_lead_test_spot(0, 2))
	var/mob/living/carbon/human/user = lead.lead_body
	var/datum/antagonist/heretic/heretic = lead.owner_heretic()
	var/obj/item/heretic_path_relic/lead_revolver/revolver = heretic_lead_test_revolver(heretic, user)
	var/list/targets = list(heretic_lead_test_crew(heretic_lead_test_spot(3, 2)), heretic_lead_test_crew(heretic_lead_test_spot(0, 4)), heretic_lead_test_crew(heretic_lead_test_spot(0, 0)))
	lead.combat_resource = 3
	for(var/mob/living/carbon/human/target as anything in targets)
		lead.turn_drum(1)
		COOLDOWN_RESET(revolver, shot_cooldown)
		heretic_lead_test_fly(revolver.fire_at(target, user))
	TEST_ASSERT_EQUAL(lead.combat_resource, 3, "Без Школы три попадания - только возврат.")
	TEST_ASSERT(lead.choose_school(user, HERETIC_LEAD_SCHOOL_GUNSLINGER), "Школа Стрелка: [lead.lead_failure]")
	for(var/mob/living/carbon/human/target as anything in targets)
		lead.turn_drum(1)
		COOLDOWN_RESET(revolver, shot_cooldown)
		heretic_lead_test_fly(revolver.fire_at(target, user))
	TEST_ASSERT_EQUAL(lead.combat_resource, 3 + HERETIC_LEAD_SPREE_LEAD, "Серия по трём людям даёт ещё [HERETIC_LEAD_SPREE_LEAD] Свинца.")

/// Охотник: прицел быстрее и дальше, Мишень дольше и видна сквозь стены перекрестием на экране.
/datum/unit_test/heretic_lead_hunter/Run()
	var/datum/eldritch_knowledge/base_lead/lead = heretic_lead_test_school(HERETIC_LEAD_SCHOOL_HUNTER, heretic_lead_test_spot(0, 2))
	var/mob/living/carbon/human/user = lead.lead_body
	var/datum/antagonist/heretic/heretic = lead.owner_heretic()
	var/obj/item/heretic_path_relic/lead_revolver/revolver = heretic_lead_test_revolver(heretic, user)
	var/mob/living/carbon/human/victim = heretic_lead_test_crew(heretic_lead_test_spot(4, 2))
	TEST_ASSERT_EQUAL(lead.aim_range(), HERETIC_LEAD_HUNTER_AIM_RANGE, "Охотник целится в [HERETIC_LEAD_HUNTER_AIM_RANGE] клетках.")
	lead.drum_style = HERETIC_LEAD_STYLE_AIMED
	lead.combat_resource = 2
	var/started = world.time
	TEST_ASSERT(revolver.fire_at(victim, user) == TRUE, "Охотник берёт цель на прицел.")
	TEST_ASSERT(heretic_lead_test_wait(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(heretic_lead_test_var_null), revolver, NAMEOF(revolver, focus_timer)), 2 SECONDS, "прицел Охотника"), "Прицел Охотника сошёлся.")
	TEST_ASSERT(world.time - started < HERETIC_LEAD_AIM_TIME, "Прицел Охотника быстрее обычного: [world.time - started] дс.")
	TEST_ASSERT(heretic_lead_test_wait(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(heretic_lead_test_brute_at_least), victim, 1), 2 SECONDS, "прицельная пуля Охотника"), "Прицельная пуля Охотника попала.")
	victim.apply_status_effect(/datum/status_effect/eldritch/lead, lead)
	var/datum/status_effect/eldritch/lead/mark = victim.has_status_effect(/datum/status_effect/eldritch/lead)
	var/datum/status_effect/eldritch/lead/sample = /datum/status_effect/eldritch/lead
	TEST_ASSERT(abs(mark.duration - world.time - (initial(sample.duration) + HERETIC_LEAD_HUNTER_MARK_BONUS)) < 1, "Мишень Охотника держится на [HERETIC_LEAD_HUNTER_MARK_BONUS / (1 SECONDS)] секунд дольше.")
	lead.on_life(user)
	TEST_ASSERT_EQUAL(length(lead.sights), 0, "Видимого меченого отдельным перекрестием не дублируют.")
	allocate(/obj/structure/falsewall, heretic_lead_test_spot(2, 2))
	lead.on_life(user)
	TEST_ASSERT_EQUAL(length(lead.sights), 1, "Меченого за стеной Охотник видит перекрестием сквозь стену.")
	var/atom/movable/screen/heretic_lead_sight/sight = lead.sights[1]
	TEST_ASSERT_EQUAL(sight.screen_loc, "CENTER+4,CENTER+0", "Перекрестие стоит в клетке экрана, где меченый.")
	lead.on_body_lose(user)
	TEST_ASSERT(QDELETED(sight) && !length(lead.sights), "Смена тела гасит перекрестия.")

/// Растяжка Охотника: за единицу Свинца до 3 проволок, видна осмотром клетки и сканером, задевший получает пулю из стены и Мишень, кусачки режут, хозяин проходит, смерть снимает.
/datum/unit_test/heretic_lead_tripwire/Run()
	var/datum/eldritch_knowledge/base_lead/lead = heretic_lead_test_school(HERETIC_LEAD_SCHOOL_HUNTER, heretic_lead_test_spot(2, 2))
	var/mob/living/carbon/human/user = lead.lead_body
	var/datum/antagonist/heretic/heretic = lead.owner_heretic()
	TEST_ASSERT_NOTNULL(locate(/obj/effect/proc_holder/spell/pointed/heretic_lead/tripwire) in user.mind.spell_list, "У Охотника есть кнопка «Растяжка».")
	TEST_ASSERT(findtext(lead.tripwire_block_reason(user, heretic_lead_test_spot(4, 4)), "соседней"), "Растяжку не натянуть издали.")
	lead.combat_resource = HERETIC_LEAD_CAPACITY
	var/obj/structure/heretic_lead_tripwire/oldest = lead.place_tripwire(user, heretic_lead_test_spot(1, 1))
	TEST_ASSERT_NOTNULL(oldest, "Растяжка натянута: [lead.lead_failure]")
	TEST_ASSERT_EQUAL(lead.combat_resource, HERETIC_LEAD_CAPACITY - HERETIC_LEAD_TRAP_COST, "Растяжка стоит [HERETIC_LEAD_TRAP_COST] Свинца.")
	TEST_ASSERT(oldest.invisibility == INVISIBILITY_MAXIMUM && oldest.level == 1, "Проволоку не видно глазом, но её находит Т-сканер.")
	TEST_ASSERT(oldest.glint?.icon_state == "lead_tripwire" && !oldest.glint.invisibility, "Над полом остаётся едва заметный блик.")
	TEST_ASSERT(findtext(lead.tripwire_block_reason(user, heretic_lead_test_spot(1, 1)), "уже"), "Две растяжки на одну клетку не ставятся.")
	var/obj/structure/heretic_lead_tripwire/cut_wire = lead.place_tripwire(user, heretic_lead_test_spot(1, 3))
	var/obj/structure/heretic_lead_tripwire/trap = lead.place_tripwire(user, heretic_lead_test_spot(2, 3))
	var/obj/structure/heretic_lead_tripwire/spare = lead.place_tripwire(user, heretic_lead_test_spot(3, 3))
	TEST_ASSERT(QDELETED(oldest) && length(lead.tripwires) == HERETIC_LEAD_TRIPWIRE_LIMIT, "Растяжек не больше [HERETIC_LEAD_TRIPWIRE_LIMIT], новая снимает самую старую.")
	TEST_ASSERT(findtext(lead.combat_resource_state(), "Растяжек: [HERETIC_LEAD_TRIPWIRE_LIMIT] из [HERETIC_LEAD_TRIPWIRE_LIMIT]"), "Описание значка считает растяжки.")
	var/mob/living/carbon/human/near = heretic_lead_test_crew(heretic_lead_test_spot(4, 4))
	var/mob/living/carbon/human/far = heretic_lead_test_crew(heretic_lead_test_spot(-1, -1))
	var/turf/wired = heretic_lead_test_spot(3, 3)
	TEST_ASSERT(findtext(jointext(wired.examine(near), " "), "растяжка"), "Осмотр клетки вблизи находит растяжку.")
	TEST_ASSERT(!findtext(jointext(wired.examine(far), " "), "растяжка"), "Издалека растяжку не разглядеть.")
	user.forceMove(heretic_lead_test_spot(2, 3))
	TEST_ASSERT(trap.armed, "Хозяин свою растяжку не задевает.")
	user.forceMove(heretic_lead_test_spot(2, 2))
	var/mob/living/carbon/human/victim = heretic_lead_test_crew(heretic_lead_test_spot(2, 4))
	victim.forceMove(heretic_lead_test_spot(2, 3))
	TEST_ASSERT(!trap.armed && victim.getBruteLoss() == 0, "Щелчок проволоки - выстрел не сразу.")
	TEST_ASSERT(heretic_lead_test_wait(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(heretic_lead_test_brute_at_least), victim, HERETIC_LEAD_TRIPWIRE_DAMAGE - 1), 3 SECONDS, "пуля растяжки"), "Задевший растяжку получает пулю из стены: [victim.getBruteLoss()].")
	TEST_ASSERT(victim.has_status_effect(/datum/status_effect/eldritch/lead), "Пуля растяжки вешает Мишень.")
	TEST_ASSERT(QDELETED(trap), "Сработавшая растяжка исчезает.")
	var/mob/living/carbon/human/sapper = heretic_lead_test_crew(heretic_lead_test_spot(0, 3))
	var/obj/item/wirecutters/cutters = allocate(/obj/item/wirecutters, get_turf(sapper))
	sapper.put_in_hands(cutters)
	var/turf/cut_spot = heretic_lead_test_spot(1, 3)
	cut_spot.attackby(cutters, sapper)
	TEST_ASSERT(wait_for_qdeleted(cut_wire, HERETIC_LEAD_TRIPWIRE_CUT_TIME + 2 SECONDS), "Кусачки режут растяжку.")
	TEST_ASSERT_EQUAL(sapper.getBruteLoss(), 0, "Перерезанная растяжка не стреляет.")
	user.death()
	heretic.handle_death(user)
	TEST_ASSERT(QDELETED(spare) && !length(lead.tripwires), "Смерть хозяина снимает растяжки.")

/// Канонир: дождь шире и за единицу, веер выпускает ещё 2 пули сверх камор без траты Свинца, Пороховая пуля хлопает и валит соседа.
/datum/unit_test/heretic_lead_cannoneer/Run()
	var/datum/eldritch_knowledge/base_lead/lead = heretic_lead_test_school(null, heretic_lead_test_spot(0, 2))
	var/mob/living/carbon/human/user = lead.lead_body
	var/datum/antagonist/heretic/heretic = lead.owner_heretic()
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/lead_rain)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/lead_catch)
	var/turf/center = heretic_lead_test_spot(2, 2)
	var/plain_field = length(lead.rain_turfs(center))
	TEST_ASSERT(lead.choose_school(user, HERETIC_LEAD_SCHOOL_CANNONEER), "Школа Канонира: [lead.lead_failure]")
	TEST_ASSERT(length(lead.rain_turfs(center)) > plain_field, "Дождь Канонира шире: [length(lead.rain_turfs(center))] клеток против [plain_field].")
	lead.combat_resource = HERETIC_LEAD_CANNON_RAIN_COST
	TEST_ASSERT(lead.rain(user, center) && lead.combat_resource == 0, "Дождь Канонира стоит [HERETIC_LEAD_CANNON_RAIN_COST] Свинца: [lead.lead_failure]")
	var/obj/item/heretic_path_relic/lead_revolver/revolver = heretic_lead_test_revolver(heretic, user)
	lead.drum_style = HERETIC_LEAD_STYLE_FAN
	lead.combat_resource = 1
	TEST_ASSERT(revolver.fire_at(heretic_lead_test_spot(0, 5), user), "Веер Канонира начинается.")
	TEST_ASSERT(heretic_lead_test_wait(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(heretic_lead_test_var_null), revolver, NAMEOF(revolver, fan_timer)), 3 SECONDS, "веер Канонира"), "Веер закончился.")
	var/casings = 0
	for(var/obj/item/ammo_casing/heretic_lead/casing in get_turf(user))
		casings++
	TEST_ASSERT_EQUAL(casings, 1 + HERETIC_LEAD_CANNON_FAN_EXTRA, "Веер Канонира выпускает ещё [HERETIC_LEAD_CANNON_FAN_EXTRA] пули сверх заряженных камор.")
	TEST_ASSERT_EQUAL(lead.combat_resource, 0, "Лишние пули веера Свинец не тратят.")
	COOLDOWN_RESET(revolver, fan_lockout)
	lead.drum_style = HERETIC_LEAD_STYLE_PLAIN
	var/mob/living/carbon/human/victim = heretic_lead_test_crew(heretic_lead_test_spot(3, 2))
	var/mob/living/carbon/human/neighbor = heretic_lead_test_crew(heretic_lead_test_spot(3, 3))
	heretic_lead_test_round(revolver, lead, user, victim, 4)
	TEST_ASSERT(victim.on_fire, "Пороховая пуля поджигает цель.")
	TEST_ASSERT(neighbor.IsKnockdown(), "Хлопок Пороховой пули Канонира сбивает с ног соседа.")
	TEST_ASSERT(!user.IsKnockdown(), "Хозяина хлопок не трогает.")

/// Пороховая закладка Канонира: до 2 закладок, наступивший слышит щелчок, через полсекунды хлопок валит и поджигает всех в 1 клетке; выстрел подрывает, вода и руки обезвреживают.
/datum/unit_test/heretic_lead_powder_charge/Run()
	var/datum/eldritch_knowledge/base_lead/lead = heretic_lead_test_school(HERETIC_LEAD_SCHOOL_CANNONEER, heretic_lead_test_spot(0, 2))
	var/mob/living/carbon/human/user = lead.lead_body
	var/datum/antagonist/heretic/heretic = lead.owner_heretic()
	TEST_ASSERT_NOTNULL(locate(/obj/effect/proc_holder/spell/pointed/heretic_lead/powder_charge) in user.mind.spell_list, "У Канонира есть кнопка «Пороховая закладка».")
	lead.combat_resource = HERETIC_LEAD_CAPACITY
	var/obj/structure/heretic_lead_charge/first = lead.place_charge(user, heretic_lead_test_spot(1, 2))
	TEST_ASSERT(first && lead.combat_resource == HERETIC_LEAD_CAPACITY - HERETIC_LEAD_TRAP_COST, "Закладка стоит [HERETIC_LEAD_TRAP_COST] Свинца: [lead.lead_failure]")
	var/obj/structure/heretic_lead_charge/stepped = lead.place_charge(user, heretic_lead_test_spot(1, 3))
	var/obj/structure/heretic_lead_charge/wet = lead.place_charge(user, heretic_lead_test_spot(1, 1))
	TEST_ASSERT(QDELETED(first) && length(lead.charges) == HERETIC_LEAD_CHARGE_LIMIT, "Закладок не больше [HERETIC_LEAD_CHARGE_LIMIT], новая снимает самую старую.")
	var/mob/living/carbon/human/walker = heretic_lead_test_crew(heretic_lead_test_spot(2, 4))
	var/mob/living/carbon/human/beside = heretic_lead_test_crew(heretic_lead_test_spot(2, 3))
	walker.forceMove(heretic_lead_test_spot(1, 3))
	TEST_ASSERT(stepped.icon_state == "lead_powder_charge_armed" && !walker.IsKnockdown(), "Наступивший слышит щелчок, хлопок не сразу.")
	TEST_ASSERT(wait_for_qdeleted(stepped, HERETIC_LEAD_CHARGE_DELAY + 2 SECONDS), "Закладка хлопнула.")
	TEST_ASSERT(walker.IsKnockdown() && walker.on_fire && beside.IsKnockdown() && beside.on_fire, "Хлопок валит и поджигает всех в клетке вокруг.")
	TEST_ASSERT(!user.IsKnockdown() && !user.on_fire, "Хозяина свой хлопок не трогает.")
	var/mob/living/carbon/human/bystander = heretic_lead_test_crew(heretic_lead_test_spot(2, 1))
	dusk_reagent_splash(wet, /datum/reagent/water)
	TEST_ASSERT(wait_for_qdeleted(wet, 1 SECONDS), "Вода гасит закладку.")
	TEST_ASSERT(!bystander.IsKnockdown() && !bystander.on_fire, "Залитая закладка не хлопает.")
	var/obj/structure/heretic_lead_charge/picked = lead.place_charge(user, heretic_lead_test_spot(0, 1))
	var/mob/living/carbon/human/picker = heretic_lead_test_crew(heretic_lead_test_spot(0, 0))
	INVOKE_ASYNC(picked, TYPE_PROC_REF(/atom, attack_hand), picker)
	TEST_ASSERT(!QDELETED(picked), "Собрать закладку - не мгновенно.")
	TEST_ASSERT(wait_for_qdeleted(picked, HERETIC_LEAD_CHARGE_DEFUSE_TIME + 2 SECONDS), "Руками закладку собирают за [HERETIC_LEAD_CHARGE_DEFUSE_TIME / (1 SECONDS)] секунды.")
	TEST_ASSERT(!picker.IsKnockdown(), "Собранная закладка не хлопает.")
	var/obj/structure/heretic_lead_charge/shot = lead.place_charge(user, heretic_lead_test_spot(1, 2))
	var/mob/living/carbon/human/target_side = heretic_lead_test_crew(heretic_lead_test_spot(2, 2))
	var/obj/item/heretic_path_relic/lead_revolver/revolver = heretic_lead_test_revolver(heretic, user)
	lead.combat_resource = 2
	heretic_lead_test_fly(revolver.fire_at(shot, user))
	TEST_ASSERT(wait_for_qdeleted(shot, 1 SECONDS), "Выстрел подрывает закладку.")
	TEST_ASSERT(target_side.IsKnockdown(), "Подорванная выстрелом закладка валит стоящих рядом.")
	var/obj/structure/heretic_lead_charge/left = lead.place_charge(user, heretic_lead_test_spot(0, 3))
	user.death()
	heretic.handle_death(user)
	TEST_ASSERT(QDELETED(left) && !length(lead.charges), "Смерть хозяина снимает закладки.")

/// Урок не ждёт выбора Школы, если она уже выбрана.
/datum/unit_test/heretic_lead_lesson_school_chosen/Run()
	var/datum/eldritch_knowledge/base_lead/lead = heretic_lead_test_school(HERETIC_LEAD_SCHOOL_HUNTER, heretic_lead_test_spot(0, 2))
	var/mob/living/carbon/human/target = heretic_lead_test_crew(heretic_lead_test_spot(2, 4))
	var/datum/heretic_lead_lesson/lesson = new(null, lead, lead.lead_body, target)
	allocated += lesson
	lesson.set_stage(8)
	TEST_ASSERT(heretic_lead_test_wait(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(heretic_dusk_test_stage_past), lesson, 8), 2 SECONDS, "шаг Школы"), "Выбранная Школа засчитывает шаг сам.")

/// Числа Школ в кодексе, кнопках и заклинаниях совпадают с дефайнами.
/datum/unit_test/heretic_lead_school_texts/Run()
	var/list/expected = list(
		/obj/effect/proc_holder/spell/self/heretic_lead/school = list("в [HERETIC_LEAD_CROWD_RANGE] клетках, до [HERETIC_LEAD_CROWD_CAP]", "на [HERETIC_LEAD_CROWD_RATE]% выстрелы", "за [HERETIC_LEAD_STANDOFF_WINDOW / (1 SECONDS)] секунды в вас выстрелят [HERETIC_LEAD_STANDOFF_SHOOTERS] разных стрелка в [HERETIC_LEAD_UNDER_FIRE_RANGE] клетках", "[HERETIC_LEAD_STANDOFF_TIME / (1 SECONDS)] секунды чужие пули", "[HERETIC_LEAD_STANDOFF_SHOTS] следующих выстрела", "раз в [HERETIC_LEAD_STANDOFF_COOLDOWN / (1 SECONDS)] секунд", "по [HERETIC_LEAD_SPREE_TARGETS] разным людям за [HERETIC_LEAD_SPREE_WINDOW / (1 SECONDS)] секунд дают ещё [HERETIC_LEAD_SPREE_LEAD] Свинца", "в [HERETIC_LEAD_HUNTER_AIM_RANGE] клетках", "на [HERETIC_LEAD_HUNTER_MARK_BONUS / (1 SECONDS)] секунд дольше", "до [HERETIC_LEAD_TRIPWIRE_LIMIT] проволок", "радиусом [HERETIC_LEAD_CANNON_RAIN_RADIUS] за единицу", "на [HERETIC_LEAD_CANNON_FAN_EXTRA] пули длиннее", "до [HERETIC_LEAD_CHARGE_LIMIT] горстей"),
		/obj/effect/proc_holder/spell/self/heretic_lead/standoff = list("хотя бы [HERETIC_LEAD_STANDOFF_SHOOTERS] вооружённых", "за [HERETIC_LEAD_STANDOFF_WINDOW / (1 SECONDS)] секунды в вас выстрелят [HERETIC_LEAD_STANDOFF_SHOOTERS] разных стрелка в [HERETIC_LEAD_UNDER_FIRE_RANGE] клетках", "[HERETIC_LEAD_STANDOFF_TIME / (1 SECONDS)] секунды чужие пули в [HERETIC_LEAD_STANDOFF_RANGE] клетках", "[HERETIC_LEAD_STANDOFF_SHOTS] следующих выстрела Шестизарядника за [HERETIC_LEAD_STANDOFF_SHOTS_TIME / (1 SECONDS)] секунд"),
		/obj/effect/proc_holder/spell/pointed/heretic_lead/tripwire = list("до [HERETIC_LEAD_TRIPWIRE_LIMIT] растяжек", "на [HERETIC_LEAD_TRIPWIRE_DAMAGE] ушибов", "в [HERETIC_LEAD_TRIPWIRE_WALL_RANGE] клетках"),
		/obj/effect/proc_holder/spell/pointed/heretic_lead/powder_charge = list("до [HERETIC_LEAD_CHARGE_LIMIT] закладок", "за [HERETIC_LEAD_CHARGE_DEFUSE_TIME / (1 SECONDS)] секунды"),
		/obj/effect/proc_holder/spell/pointed/heretic_lead/rain = list("радиусом [HERETIC_LEAD_CANNON_RAIN_RADIUS] клетки"),
	)
	for(var/spell_type in expected)
		var/obj/effect/proc_holder/spell/spell = spell_type
		var/desc = initial(spell.desc)
		for(var/fragment in expected[spell_type])
			TEST_ASSERT(findtext(desc, fragment), "[spell_type]: в описании есть «[fragment]».")
	for(var/spell_type in list(/obj/effect/proc_holder/spell/self/heretic_lead/standoff, /obj/effect/proc_holder/spell/pointed/heretic_lead/tripwire, /obj/effect/proc_holder/spell/pointed/heretic_lead/powder_charge))
		var/obj/effect/proc_holder/spell/spell = spell_type
		TEST_ASSERT(findtext(initial(spell.desc), "Перезарядка [initial(spell.charge_max) / (1 SECONDS)] секунд"), "[spell_type] называет перезарядку.")
	TEST_ASSERT(HERETIC_LEAD_HUNTER_AIM_TIME == 0.6 SECONDS && HERETIC_LEAD_TRIPWIRE_DELAY == 0.3 SECONDS && HERETIC_LEAD_CHARGE_DELAY == 0.5 SECONDS && HERETIC_LEAD_POP_KNOCKDOWN == 1.5 SECONDS && HERETIC_LEAD_TRIPWIRE_CUT_TIME == 1 SECONDS && HERETIC_LEAD_TRAP_COST == 1, "Слова «0,6», «0,3», «0,5», «1,5 секунды», «за секунду» и «за единицу» держатся дефайнов.")
	var/datum/eldritch_knowledge/lead_mark/mark = allocate(/datum/eldritch_knowledge/lead_mark)
	for(var/fragment in list("до [HERETIC_LEAD_CROWD_CAP]", "[HERETIC_LEAD_STANDOFF_SHOOTERS] стрелка за [HERETIC_LEAD_STANDOFF_WINDOW / (1 SECONDS)] секунды", "в [HERETIC_LEAD_HUNTER_AIM_RANGE] клетках", "на [HERETIC_LEAD_HUNTER_MARK_BONUS / (1 SECONDS)] секунд дольше", "радиусом [HERETIC_LEAD_CANNON_RAIN_RADIUS] за единицу", "на [HERETIC_LEAD_CANNON_FAN_EXTRA] пули"))
		TEST_ASSERT(findtext(mark.desc, fragment), "Кодекс Мишени называет «[fragment]».")
	var/datum/heretic_path/path = GLOB.heretic_paths[PATH_LEAD]
	TEST_ASSERT(findtext(path.combat_practice, "«Школа стрельбы»"), "Боевой совет полигона называет выбор Школы.")

/// Новые вещи Школ создаются и удаляются начисто: растяжка с бликом и закладка отпускают знание, перекрестие - экран.
/datum/unit_test/heretic_lead_school_atoms/Run()
	var/datum/eldritch_knowledge/base_lead/hunter = heretic_lead_test_school(HERETIC_LEAD_SCHOOL_HUNTER, heretic_lead_test_spot(1, 1))
	hunter.combat_resource = HERETIC_LEAD_CAPACITY
	var/obj/structure/heretic_lead_tripwire/wire = hunter.place_tripwire(hunter.lead_body, heretic_lead_test_spot(1, 2))
	var/obj/effect/heretic_lead_tripwire_glint/glint = wire.glint
	var/turf/wired = get_turf(wire)
	qdel(wire)
	TEST_ASSERT(QDELETED(glint) && !length(hunter.tripwires), "Удалённая растяжка забирает блик и выходит из списка.")
	var/mob/living/carbon/human/viewer = heretic_lead_test_crew(heretic_lead_test_spot(1, 3))
	TEST_ASSERT(!findtext(jointext(wired.examine(viewer), " "), "растяжка"), "Удалённая растяжка отпускает клетку.")
	var/atom/movable/screen/heretic_lead_sight/sight = new(null, hunter, viewer)
	hunter.sights += sight
	qdel(sight)
	TEST_ASSERT(!length(hunter.sights), "Перекрестие выходит из списка при удалении.")
	var/datum/eldritch_knowledge/base_lead/cannoneer = heretic_lead_test_school(HERETIC_LEAD_SCHOOL_CANNONEER, heretic_lead_test_spot(3, 1))
	cannoneer.combat_resource = HERETIC_LEAD_CAPACITY
	var/obj/structure/heretic_lead_charge/charge = cannoneer.place_charge(cannoneer.lead_body, heretic_lead_test_spot(3, 2))
	qdel(charge)
	TEST_ASSERT(!length(cannoneer.charges), "Удалённая закладка выходит из списка.")
	var/obj/effect/temp_visual/heretic_lead/pop/pop = new(heretic_lead_test_spot(2, 2))
	qdel(pop)
	TEST_ASSERT(QDELETED(pop), "Хлопок удаляется.")
