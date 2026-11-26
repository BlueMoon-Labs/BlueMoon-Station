/// Длань покровителя замирает закрытый мех на время, не травит пилота и не держит тот же мех подряд.
/datum/unit_test/heretic_patron_bolt_jams_mech/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/turf/mech_turf = locate(run_loc_floor_bottom_left.x + 2, run_loc_floor_bottom_left.y + 2, run_loc_floor_bottom_left.z)
	var/obj/vehicle/sealed/mecha/combat/gygax/mech = allocate(/obj/vehicle/sealed/mecha/combat/gygax, mech_turf)
	var/mob/living/carbon/human/pilot = allocate(/mob/living/carbon/human, mech_turf)
	pilot.forceMove(mech)
	mech.add_occupant(pilot)
	mech.setDir(NORTH)
	var/obj/item/projectile/magic/spell/rust_wave/bolt = allocate(/obj/item/projectile/magic/spell/rust_wave, run_loc_floor_top_right)
	bolt.firer = user
	mech.bullet_act(bolt)
	TEST_ASSERT(mech.completely_disabled, "Заряд Длани обездвиживает закрытый мех.")
	TEST_ASSERT(mech.heretic_patron_jammed, "Мех помечен как обездвиженный Дланью.")
	TEST_ASSERT_EQUAL(pilot.getToxLoss(), 0, "Пилот закрытого меха не отравлен.")
	TEST_ASSERT(!mech.vehicle_move(EAST), "Обездвиженный мех не поворачивается и не ходит.")
	TEST_ASSERT_EQUAL(mech.dir, NORTH, "Направление меха не меняется.")
	mech.heretic_patron_unjam()
	TEST_ASSERT(!mech.completely_disabled, "После обездвиживания мех снова слушается.")
	TEST_ASSERT(mech.vehicle_move(EAST), "Оттаявший мех поворачивается.")
	var/obj/item/projectile/magic/spell/rust_wave/second = allocate(/obj/item/projectile/magic/spell/rust_wave, run_loc_floor_top_right)
	second.firer = user
	mech.bullet_act(second)
	TEST_ASSERT(!mech.completely_disabled, "Тот же мех не застывает снова раньше отката.")
	mech.heretic_patron_jam_ready_at = 0
	TEST_ASSERT(mech.heretic_patron_jam(user), "После отката мех снова можно обездвижить.")
	mech.heretic_patron_unjam()
	mech.remove_occupant(pilot)
	pilot.forceMove(mech_turf)

/// Длань не снимает чужую остановку меха и не держит меха с еретиком внутри.
/datum/unit_test/heretic_patron_bolt_respects_other_stops/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/obj/vehicle/sealed/mecha/combat/gygax/frozen = allocate(/obj/vehicle/sealed/mecha/combat/gygax, run_loc_floor_top_right)
	frozen.completely_disabled = TRUE
	TEST_ASSERT(!frozen.heretic_patron_jam(user), "Уже остановленный мех Длань не трогает.")
	frozen.heretic_patron_unjam()
	TEST_ASSERT(frozen.completely_disabled, "Чужая остановка меха не снимается Дланью.")
	frozen.completely_disabled = FALSE
	var/obj/vehicle/sealed/mecha/combat/gygax/allied = allocate(/obj/vehicle/sealed/mecha/combat/gygax, run_loc_floor_top_right)
	var/datum/antagonist/heretic/ally = allocate_heretic(run_loc_floor_top_right)
	var/mob/living/carbon/human/ally_body = ally.owner.current
	ally_body.forceMove(allied)
	allied.add_occupant(ally_body)
	TEST_ASSERT(!allied.heretic_patron_jam(user), "Мех с еретиком внутри Длань не останавливает.")
	allied.remove_occupant(ally_body)
	ally_body.forceMove(run_loc_floor_top_right)

/// Пелена гасит 4 выстрела, картечь одного выстрела тратит один заряд, свои снаряды не гасит.
/datum/unit_test/heretic_veil_absorbs_shots/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/mob/living/carbon/human/shooter = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/mansus_veil)
	var/datum/eldritch_knowledge/spell/mansus_veil/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/spell/mansus_veil)
	var/obj/effect/proc_holder/spell/self/mansus_veil/veil_spell = knowledge?.granted_spell
	TEST_ASSERT(istype(veil_spell), "Знание выдаёт заклинание Пелены.")
	TEST_ASSERT(veil_spell.cast(list(user), user), "Пелена накладывается.")
	var/datum/status_effect/heretic_veil/veil = user.has_status_effect(/datum/status_effect/heretic_veil)
	TEST_ASSERT(veil, "На еретике висит Пелена.")
	TEST_ASSERT(!veil_spell.can_cast(user, TRUE, TRUE), "Вторую Пелену поверх первой не наложить.")

	var/obj/item/projectile/beam/laser/laser = allocate(/obj/item/projectile/beam/laser, run_loc_floor_top_right)
	laser.firer = shooter
	TEST_ASSERT_EQUAL(user.bullet_act(laser, BODY_ZONE_CHEST), BULLET_ACT_BLOCK, "Лазер гасится пеленой.")
	TEST_ASSERT_EQUAL(user.getFireLoss(), 0, "Погашенный лазер не обжигает.")
	TEST_ASSERT_EQUAL(veil.charges, HERETIC_VEIL_CHARGES - 1, "Выстрел тратит заряд.")

	veil.last_shot_time = -1
	for(var/pellet_index in 1 to 3)
		var/obj/item/projectile/bullet/pellet/shotgun_buckshot/pellet = allocate(/obj/item/projectile/bullet/pellet/shotgun_buckshot, run_loc_floor_top_right)
		pellet.firer = shooter
		user.bullet_act(pellet, BODY_ZONE_CHEST)
	TEST_ASSERT_EQUAL(user.getBruteLoss(), 0, "Дробины одного выстрела гасятся.")
	TEST_ASSERT_EQUAL(veil.charges, HERETIC_VEIL_CHARGES - 2, "Картечь одного выстрела тратит один заряд.")

	veil.last_shot_time = -1
	var/obj/item/projectile/bullet/dart/syringe/dart = allocate(/obj/item/projectile/bullet/dart/syringe, run_loc_floor_top_right)
	dart.firer = shooter
	dart.reagents.add_reagent(/datum/reagent/toxin, 10)
	user.bullet_act(dart, BODY_ZONE_CHEST)
	TEST_ASSERT(!user.reagents.has_reagent(/datum/reagent/toxin), "Шприц из погашенного дротика не впрыскивает яд.")

	var/datum/antagonist/heretic/ally = allocate_heretic(run_loc_floor_top_right)
	var/obj/item/projectile/beam/laser/friendly = allocate(/obj/item/projectile/beam/laser, run_loc_floor_top_right)
	friendly.firer = ally.owner.current
	user.bullet_act(friendly, BODY_ZONE_CHEST)
	TEST_ASSERT(user.getFireLoss() > 0, "Снаряд союзного еретика пелена пропускает.")
	TEST_ASSERT_EQUAL(veil.charges, HERETIC_VEIL_CHARGES - 3, "Союзный снаряд не тратит заряд.")

	veil.last_shot_time = -1
	var/obj/item/projectile/beam/laser/last = allocate(/obj/item/projectile/beam/laser, run_loc_floor_top_right)
	last.firer = shooter
	TEST_ASSERT_EQUAL(user.bullet_act(last, BODY_ZONE_CHEST), BULLET_ACT_BLOCK, "Четвёртый выстрел гасится.")
	TEST_ASSERT_EQUAL(veil.duration, world.time, "Без зарядов пелена спадает на следующем тике.")
	veil.last_shot_time = -1
	var/burn_before = user.getFireLoss()
	var/obj/item/projectile/beam/laser/through = allocate(/obj/item/projectile/beam/laser, run_loc_floor_top_right)
	through.firer = shooter
	user.bullet_act(through, BODY_ZONE_CHEST)
	TEST_ASSERT(user.getFireLoss() > burn_before, "Пятый выстрел проходит.")
	user.remove_status_effect(/datum/status_effect/heretic_veil)
	TEST_ASSERT(!user.get_filter(HERETIC_VEIL_FILTER), "Снятая пелена убирает дымку.")

/// Смерть снимает пелену.
/datum/unit_test/heretic_veil_ends_on_death/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	TEST_ASSERT(user.apply_status_effect(/datum/status_effect/heretic_veil), "Пелена накладывается.")
	user.death()
	TEST_ASSERT(!user.has_status_effect(/datum/status_effect/heretic_veil), "Мёртвого пелена не укрывает.")
	var/datum/status_effect/heretic_veil/late = user.apply_status_effect(/datum/status_effect/heretic_veil)
	TEST_ASSERT(QDELETED(late), "На мёртвого пелену не наложить.")

/// Пелена и Длань доступны всем путям, а тексты называют числа из кода.
/datum/unit_test/heretic_side_ranged_texts/Run()
	TEST_ASSERT_EQUAL(GLOB.heretic_side_knowledge[/datum/eldritch_knowledge/spell/mansus_veil], GLOB.heretic_side_knowledge[/datum/eldritch_knowledge/spell/rust_wave], "Пелена открывается на той же ступени, что и Длань.")
	var/datum/eldritch_knowledge/spell/mansus_veil/veil_type = /datum/eldritch_knowledge/spell/mansus_veil
	var/datum/eldritch_knowledge/spell/rust_wave/patron_type = /datum/eldritch_knowledge/spell/rust_wave
	TEST_ASSERT(initial(veil_type.cost) >= initial(patron_type.cost), "Пелена не дешевле Длани.")
	var/obj/effect/proc_holder/spell/self/mansus_veil/veil = /obj/effect/proc_holder/spell/self/mansus_veil
	var/obj/effect/proc_holder/spell/aimed/rust_wave/patron = /obj/effect/proc_holder/spell/aimed/rust_wave
	var/jam = "[HERETIC_PATRON_MECH_JAM_TIME / (1 SECONDS)] секунды"
	var/list/facts = list(
		list(heretic_codex_text(veil_type), "[HERETIC_VEIL_DURATION / (1 SECONDS)] секунд", "до [HERETIC_VEIL_CHARGES] выстрелов", "Перезарядка [HERETIC_VEIL_COOLDOWN / (1 SECONDS)] секунд"),
		list(initial(veil.desc), "[HERETIC_VEIL_DURATION / (1 SECONDS)] секунд", "до [HERETIC_VEIL_CHARGES] выстрелов", "Перезарядка [initial(veil.charge_max) / (1 SECONDS)] секунд"),
		list(initial(veil.summary), "до [HERETIC_VEIL_CHARGES] выстрелов"),
		list(heretic_codex_text(patron_type), "мех замирает на [jam]", "через [HERETIC_PATRON_MECH_JAM_COOLDOWN / (1 SECONDS)] секунд"),
		list(initial(patron.desc), "на [jam] замирает"),
		list(initial(patron.summary), "мех замирает на [jam]"),
	)
	for(var/list/fact_line as anything in facts)
		for(var/index in 2 to length(fact_line))
			TEST_ASSERT(findtext(fact_line[1], fact_line[index]), "Текст называет «[fact_line[index]]»: [fact_line[1]]")
	TEST_ASSERT("mansus_veil" in icon_states(initial(veil.action_icon)), "У Пелены есть свой значок.")
	TEST_ASSERT("veil_absorb" in icon_states('modular_bluemoon/icons/obj/heretic_side_actions.dmi'), "У погашенного выстрела есть свой эффект.")

/// Дробины одного выстрела, долетевшие в соседние тики, тратят один заряд; другой ствол в тот же тик и тот же ствол через тик - новые выстрелы.
/datum/unit_test/heretic_veil_volley_window/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/mob/living/carbon/human/shooter = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	var/obj/item/gun/ballistic/shotgun/first_gun = allocate(/obj/item/gun/ballistic/shotgun, run_loc_floor_top_right)
	var/obj/item/gun/ballistic/shotgun/second_gun = allocate(/obj/item/gun/ballistic/shotgun, run_loc_floor_top_right)
	var/datum/status_effect/heretic_veil/veil = user.apply_status_effect(/datum/status_effect/heretic_veil)
	TEST_ASSERT_NOTNULL(veil, "Пелена накладывается.")
	shoot_pellet(user, shooter, first_gun)
	TEST_ASSERT_EQUAL(veil.charges, HERETIC_VEIL_CHARGES - 1, "Первая дробина тратит заряд.")
	sleep(world.tick_lag)
	shoot_pellet(user, shooter, first_gun)
	TEST_ASSERT_EQUAL(veil.charges, HERETIC_VEIL_CHARGES - 1, "Дробина того же выстрела в соседнем тике заряд не тратит.")
	shoot_pellet(user, shooter, second_gun)
	TEST_ASSERT_EQUAL(veil.charges, HERETIC_VEIL_CHARGES - 2, "Выстрел из другого ствола в тот же тик - новый выстрел.")
	sleep(world.tick_lag * 2)
	shoot_pellet(user, shooter, second_gun)
	TEST_ASSERT_EQUAL(veil.charges, HERETIC_VEIL_CHARGES - 3, "Тот же ствол через тик - следующий выстрел очереди.")
	TEST_ASSERT_EQUAL(user.getBruteLoss(), 0, "Все дробины погашены.")

/datum/unit_test/heretic_veil_volley_window/proc/shoot_pellet(mob/living/target, mob/living/shooter, obj/item/gun/gun)
	var/obj/item/projectile/bullet/pellet/shotgun_buckshot/pellet = allocate(/obj/item/projectile/bullet/pellet/shotgun_buckshot, run_loc_floor_top_right)
	pellet.firer = shooter
	pellet.fired_from = gun
	target.bullet_act(pellet, BODY_ZONE_CHEST)

/// Выстрел, который уже погасила стойка Клинка, не тратит заряд Пелены.
/datum/unit_test/heretic_veil_skips_absorbed/Run()
	var/list/fixture = make_blade_fixture()
	var/mob/living/carbon/human/user = fixture["user"]
	var/mob/living/attacker = fixture["attacker"]
	var/datum/eldritch_knowledge/base_blade/knowledge = fixture["knowledge"]
	user.setDir(WEST)
	TEST_ASSERT(knowledge.begin_parry(user), "Стойка Клинка поднята раньше Пелены.")
	var/datum/status_effect/heretic_parry/parry = knowledge.active_parry
	var/blocks_before = parry.blocks_left
	var/datum/status_effect/heretic_veil/veil = user.apply_status_effect(/datum/status_effect/heretic_veil)
	TEST_ASSERT_NOTNULL(veil, "Пелена накладывается.")
	var/obj/item/projectile/beam/laser/laser = allocate(/obj/item/projectile/beam/laser, get_turf(attacker))
	laser.firer = attacker
	user.bullet_act(laser, BODY_ZONE_CHEST)
	TEST_ASSERT_EQUAL(user.getFireLoss(), 0, "Выстрел погашен.")
	TEST_ASSERT_EQUAL(parry.blocks_left, blocks_before - 1, "Выстрел приняла стойка.")
	TEST_ASSERT_EQUAL(veil.charges, HERETIC_VEIL_CHARGES, "Погашенный стойкой выстрел не тратит заряд Пелены.")

/// Буря Пустоты, оболочка Воска и щит костюма делят выстрел: кто погасил его первым, тот и платит, остальные не тратят заряды.
/datum/unit_test/heretic_block_absorbed_shared/Run()
	var/datum/antagonist/heretic/void_heretic = allocate_heretic()
	var/mob/living/carbon/human/void_user = void_heretic.owner.current
	var/mob/living/carbon/human/shooter = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	var/datum/component/heretic_void_storm/storm = void_user.AddComponent(/datum/component/heretic_void_storm)
	storm.deflect_chance = 100
	var/datum/component/shielded/late_shield = void_user.AddComponent(/datum/component/shielded, 3, 3, 0)
	var/obj/item/projectile/beam/laser/laser = allocate(/obj/item/projectile/beam/laser, run_loc_floor_top_right)
	laser.firer = shooter
	void_user.bullet_act(laser, BODY_ZONE_CHEST)
	TEST_ASSERT_EQUAL(void_user.getFireLoss(), 0, "Буря разворачивает выстрел.")
	TEST_ASSERT_EQUAL(late_shield.charges, 3, "Развёрнутый бурей выстрел не тратит заряд щита.")

	var/datum/antagonist/heretic/shield_heretic = allocate_heretic(get_step(run_loc_floor_bottom_left, NORTH))
	var/mob/living/carbon/human/shield_user = shield_heretic.owner.current
	var/datum/component/shielded/early_shield = shield_user.AddComponent(/datum/component/shielded, 3, 3, 0)
	var/datum/component/heretic_void_storm/late_storm = shield_user.AddComponent(/datum/component/heretic_void_storm)
	late_storm.deflect_chance = 100
	var/obj/item/projectile/beam/laser/second_laser = allocate(/obj/item/projectile/beam/laser, run_loc_floor_top_right)
	second_laser.firer = shooter
	second_laser.setAngle(45)
	shield_user.bullet_act(second_laser, BODY_ZONE_CHEST)
	TEST_ASSERT_EQUAL(early_shield.charges, 2, "Щит гасит выстрел и тратит заряд.")
	TEST_ASSERT_EQUAL(second_laser.Angle, 45, "Погашенный щитом выстрел буря не разворачивает.")

	var/datum/antagonist/heretic/wax_heretic = allocate_heretic(get_step(run_loc_floor_bottom_left, EAST))
	wax_heretic.selected_path = PATH_WAX
	wax_heretic.gain_knowledge(/datum/eldritch_knowledge/base_wax)
	wax_heretic.gain_knowledge(/datum/eldritch_knowledge/spell/wax_shell)
	var/mob/living/carbon/human/wax_user = wax_heretic.owner.current
	var/datum/eldritch_knowledge/base_wax/wax = wax_heretic.get_knowledge(/datum/eldritch_knowledge/base_wax)
	TEST_ASSERT(wax.raise_shell(wax_user), "Оболочка Воска поднята.")
	var/datum/status_effect/heretic_wax/shell/shell = wax_user.has_status_effect(/datum/status_effect/heretic_wax/shell)
	var/datum/component/shielded/wax_shield = wax_user.AddComponent(/datum/component/shielded, 3, 3, 0)
	var/obj/item/kitchen/knife/weapon = allocate(/obj/item/kitchen/knife)
	TEST_ASSERT(wax_user.mob_run_block(weapon, 30, "удар", ATTACK_TYPE_MELEE, 0, shooter, BODY_ZONE_CHEST, list()) & BLOCK_SUCCESS, "Оболочка целиком принимает удар.")
	TEST_ASSERT_EQUAL(wax_shield.charges, 3, "Принятый оболочкой удар не тратит заряд щита.")
	TEST_ASSERT(shell.capacity < 20, "Остаток оболочки меньше следующего удара.")
	wax_user.mob_run_block(weapon, 50, "удар", ATTACK_TYPE_MELEE, 0, shooter, BODY_ZONE_CHEST, list())
	TEST_ASSERT_EQUAL(wax_shield.charges, 2, "Удар, который оболочка приняла лишь отчасти, щит гасит своим зарядом.")
