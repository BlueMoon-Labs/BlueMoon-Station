/datum/unit_test/proc/hk47_extend_spike(datum/antagonist/hk47/hunter)
	var/mob/living/carbon/human/droid = hunter.owner.current
	var/datum/action/innate/hk47_spike/button = locate() in droid.actions
	button?.Trigger()
	var/obj/item/hk47_spike/spike = locate() in droid.held_items
	if(spike)
		spike.hack_time = 1
		spike.card_time = 1
		spike.skim_time = 1
	return spike

/// Шасси HK-47 получает меньше урона выносливости, чем человек, а ЭМИ отключает его на полный срок.
/datum/unit_test/hk47_stamina_resistance

/datum/unit_test/hk47_stamina_resistance/Run()
	var/mob/living/carbon/human/droid = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	droid.set_species(/datum/species/ipc/hk/hk47)
	var/mob/living/carbon/human/person = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	droid.apply_damage(30, STAMINA, BODY_ZONE_CHEST)
	person.apply_damage(30, STAMINA, BODY_ZONE_CHEST)
	var/expected = 30 * (100 - HK_ARMOR) / 100 * HK47_STAMINA_MOD
	TEST_ASSERT(abs(droid.getStaminaLoss() - expected) < 0.1, "HK-47 takes [droid.getStaminaLoss()] stamina, expected [expected]")
	TEST_ASSERT(abs(person.getStaminaLoss() - 30) < 0.1, "a human takes the full hit: [person.getStaminaLoss()]")
	droid.emp_act(HK_EMP_HEAVY_SEVERITY)
	TEST_ASSERT(droid.AmountParalyzed() >= HK_EMP_HEAVY_STUN - 2, "EMP still drops HK-47 for the full window: [droid.AmountParalyzed()]")
	droid.set_species(/datum/species/human)
	TEST_ASSERT(abs(droid.physiology.stamina_mod - 1) < 0.01, "losing the chassis restores stamina")

/// Взломщик шлюзов: щуп выдвигается кнопкой, болты держат, щупом по запертому шлюзу дверь открывается за заряд.
/datum/unit_test/hk47_spike_door_hack

/datum/unit_test/hk47_spike_door_hack/Run()
	var/datum/antagonist/hk47/contract_fixture/upgrade_test/hunter = allocate_hk47_droid()
	var/mob/living/carbon/human/droid = hunter.owner.current
	var/obj/machinery/door/airlock/security/door = allocate(/obj/machinery/door/airlock/security, locate(droid.x + 1, droid.y, droid.z))
	door.req_access = list(ACCESS_SECURITY)
	TEST_ASSERT(!door.allowed(droid), "the security door is shut to HK-47")
	TEST_ASSERT_NULL(locate(/datum/action/innate/hk47_spike) in droid.actions, "no spike before the module")
	hunter.points = 10
	TEST_ASSERT(hunter.buy_upgrade("door_hack"), "the door hack module is bought")
	var/obj/item/hk47_spike/spike = hk47_extend_spike(hunter)
	TEST_ASSERT_NOTNULL(spike, "the button extends the spike into a hand")
	door.locked = TRUE
	TEST_ASSERT(!hunter.spike_door(door, spike), "bolts hold against the spike")
	door.locked = FALSE
	var/charge_before = droid.nutrition
	spike.melee_attack_chain(droid, door)
	var/obj/effect/temp_visual/hk47_hack/hack_lights = locate() in get_turf(door)
	TEST_ASSERT_NOTNULL(hack_lights, "the spike lights up the door panel while hacking")
	for(var/tick in 1 to 30)
		if(!door.density)
			break
		sleep(1)
	TEST_ASSERT(!door.density, "the spike opens the airlock")
	TEST_ASSERT(QDELETED(hack_lights), "the panel lights go out with the hack")
	TEST_ASSERT(findtext(jointext(door.examine(droid), " "), "HK"), "the scorched panel gives the hack away on examine")
	TEST_ASSERT(droid.nutrition <= charge_before - HK47_SPIKE_HACK_NUTRITION, "the hack costs charge")
	var/datum/action/innate/hk47_spike/button = locate() in droid.actions
	button.Trigger()
	TEST_ASSERT(QDELETED(spike), "the button retracts the spike")

/// Считыватель доступа: копия с карты и с человека рядом, вытеснение старого профиля; доступ работает в маскировке и уходит с перепрошивкой.
/datum/unit_test/hk47_spike_skim

/datum/unit_test/hk47_spike_skim/Run()
	var/datum/antagonist/hk47/contract_fixture/upgrade_test/hunter = allocate_hk47_droid()
	var/mob/living/carbon/human/droid = hunter.owner.current
	hunter.points = 20
	TEST_ASSERT(hunter.buy_upgrade("door_hack"), "the door hack module is bought")
	var/obj/item/hk47_spike/spike = hk47_extend_spike(hunter)
	var/obj/item/card/id/engineer_card = allocate(/obj/item/card/id, get_turf(droid))
	engineer_card.registered_name = "HK test engineer"
	engineer_card.assignment = "Station Engineer"
	engineer_card.access = list(ACCESS_ENGINE)
	TEST_ASSERT(!hunter.spike_skim(engineer_card, spike), "copying access needs the skimmer")
	TEST_ASSERT(hunter.buy_upgrade("access_skimmer"), "the skimmer is bought")
	var/buttons = 0
	for(var/datum/action/innate/hk47_spike/button in droid.actions)
		buttons++
	TEST_ASSERT_EQUAL(buttons, 1, "both modules share one spike button")
	var/obj/machinery/door/airlock/engineering/engine_door = allocate(/obj/machinery/door/airlock/engineering, locate(droid.x, droid.y + 1, droid.z))
	engine_door.req_access = list(ACCESS_ENGINE)
	var/obj/machinery/door/airlock/security/brig_door = allocate(/obj/machinery/door/airlock/security, locate(droid.x, droid.y + 2, droid.z))
	brig_door.req_access = list(ACCESS_SECURITY)
	TEST_ASSERT(!engine_door.allowed(droid), "no engineering access yet")
	spike.melee_attack_chain(droid, engineer_card)
	for(var/tick in 1 to 30)
		if(length(hunter.access_profiles))
			break
		sleep(1)
	TEST_ASSERT(engine_door.allowed(droid), "the copied card opens its doors")
	var/mob/living/carbon/human/officer = allocate(/mob/living/carbon/human, locate(droid.x + 1, droid.y, droid.z))
	var/obj/item/clothing/under/color/grey/uniform = allocate(/obj/item/clothing/under/color/grey, get_turf(officer))
	officer.equip_to_slot_if_possible(uniform, ITEM_SLOT_ICLOTHING, disable_warning = TRUE)
	var/obj/item/card/id/officer_card = allocate(/obj/item/card/id, get_turf(officer))
	officer_card.registered_name = "HK test officer"
	officer_card.access = list(ACCESS_SECURITY)
	TEST_ASSERT(officer.equip_to_slot_if_possible(officer_card, ITEM_SLOT_ID, disable_warning = TRUE), "the officer wears the card")
	spike.melee_attack_chain(droid, officer)
	for(var/second_tick in 1 to 30)
		if(length(hunter.access_profiles) == 2)
			break
		sleep(1)
	TEST_ASSERT(brig_door.allowed(droid), "access skimmed off a person opens the brig")
	TEST_ASSERT_EQUAL(officer.wear_id, officer_card, "the officer keeps the card")
	var/datum/hk47_upgrade/skimmer = GLOB.hk47_upgrades["access_skimmer"]
	TEST_ASSERT(findtext(skimmer.status_text(hunter), "HK test officer"), "the terminal lists the stored profiles")
	for(var/extra in 1 to HK47_ACCESS_PROFILES - 1)
		var/obj/item/card/id/extra_card = allocate(/obj/item/card/id, get_turf(droid))
		extra_card.registered_name = "HK test clerk [extra]"
		extra_card.access = list(ACCESS_LIBRARY)
		hunter.store_access_profile(extra_card)
	TEST_ASSERT_EQUAL(length(hunter.access_profiles), HK47_ACCESS_PROFILES, "the memory holds a fixed number of profiles")
	TEST_ASSERT(!engine_door.allowed(droid), "the oldest profile is pushed out")
	var/datum/component/hk47_disguise/disguise = droid.AddComponent(/datum/component/hk47_disguise)
	TEST_ASSERT(disguise.enable(), "disguised")
	TEST_ASSERT(brig_door.allowed(droid), "stored access works in disguise")
	disguise.drop(silent = TRUE)
	var/mob/living/carbon/human/surgeon = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	surgeon.mind_initialize()
	allocated += surgeon.mind
	var/datum/component/hk_loyalty/loyalty = droid.AddComponent(/datum/component/hk_loyalty)
	loyalty.set_master(surgeon.mind)
	TEST_ASSERT(!brig_door.allowed(droid), "the reprogrammed HK loses the stored access")
	TEST_ASSERT_NULL(locate(/datum/action/innate/hk47_spike) in droid.actions, "and the spike")

/// Парализующий режим: выбирается винтовкой в руке, бьёт только по выносливости, истощённая цель готова к захвату.
/datum/unit_test/hk47_stun_bolts

/datum/unit_test/hk47_stun_bolts/Run()
	var/datum/antagonist/hk47/contract_fixture/upgrade_test/hunter = allocate_hk47_droid()
	var/mob/living/carbon/human/droid = hunter.owner.current
	var/obj/item/gun/energy/hk_rifle/rifle = hk47_take_rifle(droid)
	hunter.points = 10
	TEST_ASSERT(hunter.buy_upgrade("stun_bolts"), "stun bolts bought")
	TEST_ASSERT(!rifle.stun_selected(), "the rifle stays on blaster bolts after the purchase")
	rifle.attack_self(droid)
	TEST_ASSERT(rifle.stun_selected(), "the stun mode is picked in hand")
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	var/obj/item/ammo_casing/energy/casing = rifle.ammo_type[rifle.current_firemode_index]
	var/obj/item/projectile/bolt = allocate(casing.projectile_type, get_turf(droid))
	TEST_ASSERT_EQUAL(bolt.icon_state, "hk47_stun_bolt", "the stun bolt has its own look")
	bolt.firer = droid
	bolt.fired_from = rifle
	bolt.starting = get_turf(droid)
	target.bullet_act(bolt, BODY_ZONE_CHEST)
	TEST_ASSERT(abs(target.getStaminaLoss() - HK47_STUN_BOLT_STAMINA) < 0.1, "the bolt hits stamina: [target.getStaminaLoss()]")
	TEST_ASSERT(!target.getBruteLoss() && !target.getFireLoss(), "the bolt leaves no wounds")
	TEST_ASSERT(!hk47_capture_ready(target), "one bolt does not floor a person")
	for(var/shot in 1 to round(STAMINA_CRIT / HK47_STUN_BOLT_STAMINA) + 1)
		var/obj/item/projectile/follow_up = allocate(casing.projectile_type, get_turf(droid))
		follow_up.firer = droid
		follow_up.fired_from = rifle
		follow_up.starting = get_turf(droid)
		target.bullet_act(follow_up, BODY_ZONE_CHEST)
	TEST_ASSERT(IS_STAMCRIT(target), "enough bolts exhaust the target")
	TEST_ASSERT(hk47_capture_ready(target), "an exhausted target is ready for capture")
	TEST_ASSERT(hk47_recalls(hunter.stun_noted, target, 30 SECONDS), "HK-47 is told the target is down")
	rifle.attack_self(droid)
	TEST_ASSERT(!rifle.stun_selected(), "the modes cycle back to blaster bolts")

/// Энергощит: кнопка поднимает броню шасси и срывает маскировку, ЭМИ гасит щит, повтор - только после перезарядки.
/datum/unit_test/hk47_energy_shield

/datum/unit_test/hk47_energy_shield/Run()
	var/datum/antagonist/hk47/contract_fixture/upgrade_test/hunter = allocate_hk47_droid()
	var/mob/living/carbon/human/droid = hunter.owner.current
	var/datum/species/ipc/hk/chassis = droid.dna.species
	var/armor_before = chassis.armor
	hunter.points = 10
	TEST_ASSERT(hunter.buy_upgrade("shield"), "the shield is bought")
	var/datum/action/innate/hk47_shield/button = locate() in droid.actions
	TEST_ASSERT_NOTNULL(button, "the shield button comes with the module")
	var/datum/component/hk47_disguise/disguise = droid.AddComponent(/datum/component/hk47_disguise)
	disguise.enable()
	button.Trigger()
	var/datum/component/hk47_shield/shield = droid.GetComponent(/datum/component/hk47_shield)
	TEST_ASSERT(shield.active, "the shield is up")
	TEST_ASSERT_EQUAL(chassis.armor, armor_before + HK47_SHIELD_ARMOR, "the shield adds armor")
	TEST_ASSERT(!disguise.active, "a glowing shield gives the disguise away")
	TEST_ASSERT_EQUAL(shield.bubble?.icon_state, "hk47_shield_up", "the shield unfolds first")
	TEST_ASSERT_NOTNULL(shield.ready_timer, "the droid will hear when the shield recharges")
	droid.apply_damage(10, BRUTE, BODY_ZONE_CHEST)
	TEST_ASSERT_NOTNULL(shield.flash, "a hit flashes the shield")
	TEST_ASSERT_EQUAL(shield.hits_taken, 1, "the shield counts the hits it took")
	TEST_ASSERT(findtext(hk47_quip(droid, "shield_held", 4), "4"), "HK-47 brags with the real hit count")
	var/mob/living/carbon/human/bystander = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	TEST_ASSERT_NULL(hk47_quip(bystander, "shield_up"), "only HK-47 hears its inner voice")
	droid.emp_act(HK_EMP_HEAVY_SEVERITY)
	TEST_ASSERT(!shield.active, "EMP collapses the shield")
	TEST_ASSERT(isnull(shield.bubble) && isnull(shield.flash), "the shield leaves no overlay behind")
	TEST_ASSERT_EQUAL(chassis.armor, armor_before, "the armor returns to normal")
	droid.SetParalyzed(0)
	button.Trigger()
	TEST_ASSERT(!shield.active, "the shield waits for its recharge")

/// Ремкомплекты: покупка выдаёт наборы, набор чинит шасси HK поровну и расходуется, человека и отключённого HK не чинит.
/datum/unit_test/hk47_repair_kit

/datum/unit_test/hk47_repair_kit/Run()
	var/datum/antagonist/hk47/contract_fixture/upgrade_test/hunter = allocate_hk47_droid()
	var/mob/living/carbon/human/droid = hunter.owner.current
	hunter.points = 10
	TEST_ASSERT(hunter.buy_upgrade("repair_kits"), "repair kits bought")
	var/list/kits = list()
	for(var/obj/item/hk47_repair_kit/kit in droid.held_items)
		kits += kit
	TEST_ASSERT_EQUAL(length(kits), HK47_REPAIR_KITS_PER_ORDER, "one order hands over the kits")
	allocated += kits
	var/obj/item/hk47_repair_kit/kit = kits[1]
	kit.repair_time = 1
	droid.take_overall_damage(30, 30)
	var/damage_before = droid.getBruteLoss() + droid.getFireLoss()
	kit.attack_self(droid)
	TEST_ASSERT(abs(droid.getBruteLoss() + droid.getFireLoss() - (damage_before - HK47_REPAIR_KIT_HEAL)) < 0.5, "the kit repairs [HK47_REPAIR_KIT_HEAL]")
	TEST_ASSERT(abs(droid.getBruteLoss() - droid.getFireLoss()) < 0.5, "brute and burn are patched evenly")
	TEST_ASSERT(QDELETED(kit), "the kit is used up")
	var/obj/item/hk47_repair_kit/spare = kits[2]
	spare.repair_time = 1
	var/mob/living/carbon/human/person = allocate(/mob/living/carbon/human, locate(droid.x + 1, droid.y, droid.z))
	person.take_overall_damage(20, 0)
	TEST_ASSERT(!spare.repair(person, droid), "the kit fits only HK chassis")
	droid.death()
	TEST_ASSERT(!spare.repair(droid, droid), "the kit does not restart a dead chassis")
	TEST_ASSERT(!QDELETED(spare), "a refused repair keeps the kit")

