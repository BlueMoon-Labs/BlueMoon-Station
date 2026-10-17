/// Боёк винтовки HK не даёт выстрелить обычному человеку и пропускает HK-47.
/datum/unit_test/hk_rifle_pin

/datum/unit_test/hk_rifle_pin/Run()
	var/obj/item/gun/energy/hk_rifle/rifle = allocate(/obj/item/gun/energy/hk_rifle)
	var/full_charge = rifle.cell.charge
	TEST_ASSERT_EQUAL(full_charge, HK_RIFLE_SHOTS * HK_RIFLE_SHOT_COST, "Винтовка HK заряжена не на [HK_RIFLE_SHOTS] выстрелов")

	var/mob/living/carbon/human/crewman = allocate(/mob/living/carbon/human)
	crewman.put_in_hands(rifle)
	rifle.afterattack(run_loc_floor_top_right, crewman, FALSE)
	TEST_ASSERT_EQUAL(rifle.cell.charge, full_charge, "Обычный человек выстрелил из винтовки HK")
	crewman.dropItemToGround(rifle)

	var/mob/living/carbon/human/droid = allocate(/mob/living/carbon/human)
	droid.set_species(/datum/species/ipc/hk/hk47)
	droid.mind_initialize()
	allocated += droid.mind
	droid.put_in_hands(rifle)
	rifle.afterattack(run_loc_floor_top_right, droid, FALSE)
	TEST_ASSERT_EQUAL(rifle.cell.charge, full_charge - HK_RIFLE_SHOT_COST, "HK не выстрелил из своей винтовки")

/// Боёк HK не извлекается инструментами, и осмотр винтовки не обещает обратного.
/datum/unit_test/hk_rifle_pin_fixed

/datum/unit_test/hk_rifle_pin_fixed/Run()
	var/obj/item/gun/energy/hk_rifle/rifle = allocate(/obj/item/gun/energy/hk_rifle)
	var/obj/item/firing_pin/hk/pin = rifle.pin
	var/mob/living/carbon/human/crewman = allocate(/mob/living/carbon/human)
	var/obj/item/screwdriver/screwdriver = allocate(/obj/item/screwdriver)
	crewman.put_in_hands(rifle)
	rifle.screwdriver_act(crewman, screwdriver)
	TEST_ASSERT_EQUAL(rifle.pin, pin, "Боёк HK извлечён отвёрткой")
	var/obj/item/firing_pin/clown/clown_pin = allocate(/obj/item/firing_pin/clown)
	clown_pin.afterattack(rifle, crewman, TRUE)
	TEST_ASSERT_EQUAL(rifle.pin, pin, "Боёк HK заменён бойком с force_replace")
	var/examine_text = jointext(rifle.examine(crewman), "\n")
	TEST_ASSERT(!findtext(examine_text, "<b>инструментов</b>"), "Осмотр обещает извлечь боёк HK инструментами")
	TEST_ASSERT(findtext(examine_text, "не извлечь"), "Осмотр не говорит, что боёк HK не извлекается")

/// Винтовка подзаряжается раз в HK_RIFLE_RECHARGE_TIME только в руках HK и только из его заряда выше порога.
/datum/unit_test/hk_rifle_recharge

/datum/unit_test/hk_rifle_recharge/Run()
	var/obj/item/gun/energy/hk_rifle/rifle = allocate(/obj/item/gun/energy/hk_rifle)
	TEST_ASSERT(!(rifle.datum_flags & DF_ISPROCESSING), "Полная винтовка HK тикает в SSobj")
	rifle.cell.use(rifle.cell.charge)
	TEST_ASSERT(!(rifle.datum_flags & DF_ISPROCESSING), "Разряженная винтовка HK на полу встала на подзарядку")

	var/mob/living/carbon/human/crewman = allocate(/mob/living/carbon/human)
	crewman.put_in_hands(rifle)
	TEST_ASSERT(!(rifle.datum_flags & DF_ISPROCESSING), "Винтовка HK в руках человека встала на подзарядку")
	crewman.set_nutrition(NUTRITION_LEVEL_WELL_FED)
	rifle.hk_recharge_tick()
	TEST_ASSERT_EQUAL(rifle.cell.charge, 0, "Винтовка HK подзарядилась от обычного человека")
	TEST_ASSERT_EQUAL(crewman.nutrition, NUTRITION_LEVEL_WELL_FED, "Винтовка HK съела сытость обычного человека")
	crewman.dropItemToGround(rifle)

	var/mob/living/carbon/human/droid = allocate(/mob/living/carbon/human)
	droid.set_species(/datum/species/ipc/hk/hk47)
	droid.mind_initialize()
	allocated += droid.mind
	droid.put_in_hands(rifle)
	TEST_ASSERT(rifle.datum_flags & DF_ISPROCESSING, "Разряженная винтовка в руках HK-47 не встала на подзарядку")
	droid.set_nutrition(HK_RIFLE_MIN_NUTRITION + HK_RIFLE_NUTRITION_PER_SHOT)
	var/half_period = HK_RIFLE_RECHARGE_TIME / (2 SECONDS)
	rifle.process(half_period)
	TEST_ASSERT_EQUAL(rifle.cell.charge, 0, "Винтовка HK подзарядилась раньше срока")
	rifle.process(half_period)
	TEST_ASSERT_EQUAL(rifle.cell.charge, HK_RIFLE_SHOT_COST, "HK не восстановил один выстрел за [HK_RIFLE_RECHARGE_TIME / (1 SECONDS)] с")
	TEST_ASSERT_EQUAL(droid.nutrition, HK_RIFLE_MIN_NUTRITION, "Выстрел не оплачен зарядом HK")
	TEST_ASSERT(rifle.chambered, "Подзаряженная винтовка HK не дослала выстрел")

	rifle.hk_recharge_tick()
	TEST_ASSERT_EQUAL(rifle.cell.charge, HK_RIFLE_SHOT_COST, "Винтовка HK посадила заряд дроида ниже порога")
	TEST_ASSERT_EQUAL(droid.nutrition, HK_RIFLE_MIN_NUTRITION, "Заряд HK ушёл ниже порога")

	droid.dropItemToGround(rifle)
	TEST_ASSERT_EQUAL(rifle.process(half_period), PROCESS_KILL, "Винтовка HK на полу не снялась с подзарядки")
	droid.put_in_hands(rifle)
	rifle.cell.give(rifle.cell.maxcharge)
	TEST_ASSERT_EQUAL(rifle.process(half_period), PROCESS_KILL, "Полная винтовка HK не снялась с подзарядки")

/// Боёк закрепляется за разумом первого HK-47: HK-51 и чужой разум в шасси HK-47 не стреляют, перепрошивка винтовку не отнимает.
/datum/unit_test/hk_rifle_pin_owner

/datum/unit_test/hk_rifle_pin_owner/Run()
	var/obj/item/gun/energy/hk_rifle/rifle = allocate(/obj/item/gun/energy/hk_rifle)
	var/mob/living/carbon/human/hk51 = allocate_minded_human()
	hk51.set_species(/datum/species/ipc/hk/hk51)
	TEST_ASSERT(!rifle.handle_pins(hk51), "Винтовка HK-47 стреляет у HK-51")

	var/mob/living/carbon/human/hk47 = allocate_minded_human()
	hk47.set_species(/datum/species/ipc/hk/hk47)
	hk47.put_in_hands(rifle)
	TEST_ASSERT(rifle.handle_pins(hk47), "HK-47 не стреляет из своей винтовки")
	var/mob/living/carbon/human/surgeon = allocate_minded_human()
	var/datum/component/hk_loyalty/loyalty = hk47.AddComponent(/datum/component/hk_loyalty)
	loyalty.set_master(surgeon.mind)
	TEST_ASSERT(rifle.handle_pins(hk47), "Перепрошитый HK-47 потерял свою винтовку")

	var/mob/living/carbon/human/impostor = allocate_minded_human()
	impostor.set_species(/datum/species/ipc/hk/hk47)
	TEST_ASSERT(!rifle.handle_pins(impostor), "Чужой разум в шасси HK-47 стреляет из закреплённой винтовки")
	hk47.dropItemToGround(rifle)
	impostor.put_in_hands(rifle)
	TEST_ASSERT_NULL(rifle.hk_holder(), "Чужой HK-47 подзаряжает закреплённую винтовку")

/// Винтовка HK-47 из события закреплена за его разумом сразу после активации, до первого выстрела.
/datum/unit_test/hk_rifle_pin_claimed_on_enlist

/datum/unit_test/hk_rifle_pin_claimed_on_enlist/Run()
	var/datum/round_event/ghost_role/hk47/event = allocate(/datum/round_event/ghost_role/hk47, FALSE)
	SSdirector.running -= event
	var/mob/living/carbon/human/droid = event.create_hk47(run_loc_floor_bottom_left)
	allocated += droid
	event.enlist_hk47(droid, null)
	allocated += droid.mind
	var/obj/item/gun/energy/hk_rifle/rifle = droid.back
	var/obj/item/firing_pin/hk/hk_pin = rifle.pin
	TEST_ASSERT_EQUAL(hk_pin.owner_mind_ref?.resolve(), droid.mind, "the pin belongs to HK-47 before it ever fires")
	var/mob/living/carbon/human/impostor = allocate_minded_human()
	impostor.set_species(/datum/species/ipc/hk/hk47)
	TEST_ASSERT(!rifle.handle_pins(impostor), "another mind in an HK-47 chassis cannot claim the rifle")

/// Винтовку HK не вставить ни в турель, ни в эмиттер, ни в оружейную схему; обычный лазер в турель встаёт.
/datum/unit_test/hk_rifle_no_mounts

/datum/unit_test/hk_rifle_no_mounts/Run()
	var/mob/living/carbon/human/engineer = allocate(/mob/living/carbon/human)
	var/obj/item/gun/energy/hk_rifle/rifle = allocate(/obj/item/gun/energy/hk_rifle)
	engineer.put_in_hands(rifle)

	var/obj/machinery/porta_turret_construct/turret_frame = allocate(/obj/machinery/porta_turret_construct)
	turret_frame.build_step = PTURRET_INTERNAL_ARMOUR_ON
	turret_frame.attackby(rifle, engineer)
	TEST_ASSERT_NULL(turret_frame.installed_gun, "Винтовка HK встала в турель")
	TEST_ASSERT_EQUAL(rifle.loc, engineer, "Винтовка HK ушла из рук в турель")

	var/obj/machinery/power/emitter/emitter = allocate(/obj/machinery/power/emitter)
	emitter.integrate(rifle, engineer)
	TEST_ASSERT_NULL(emitter.gun, "Винтовка HK встала в эмиттер")

	var/obj/item/integrated_circuit/weaponized/weapon_firing/circuit = allocate(/obj/item/integrated_circuit/weaponized/weapon_firing)
	circuit.attackby(rifle, engineer)
	TEST_ASSERT_NULL(circuit.installed_gun, "Винтовка HK встала в оружейную схему")

	engineer.dropItemToGround(rifle)
	var/obj/item/gun/energy/laser/laser = allocate(/obj/item/gun/energy/laser)
	engineer.put_in_hands(laser)
	turret_frame.attackby(laser, engineer)
	TEST_ASSERT_EQUAL(turret_frame.installed_gun, laser, "Обычный лазер не встал в турель: проверка турели ничего не доказывает")
