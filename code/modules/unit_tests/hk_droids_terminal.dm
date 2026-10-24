/// HK-47 на шасси HK с винтовкой: капсулы открываются сразу, опрос призраков отвечает списком теста.
/datum/antagonist/hk47/contract_fixture/upgrade_test
	var/list/test_candidates = list()

/datum/antagonist/hk47/contract_fixture/upgrade_test/Destroy()
	test_candidates.Cut()
	sent_pods.Cut()
	return ..()

/datum/antagonist/hk47/contract_fixture/upgrade_test/send_pod(obj/structure/closet/supplypod/pod, turf/landing)
	sent_pods += pod
	pod.forceMove(landing)
	pod.open_pod(pod, forced = TRUE)

/datum/antagonist/hk47/contract_fixture/upgrade_test/poll_ghost_servant()
	return test_candidates.Copy()

/datum/unit_test/proc/allocate_hk47_droid()
	var/mob/living/carbon/human/droid = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	droid.set_species(/datum/species/ipc/hk/hk47)
	droid.real_name = HK47_NAME
	droid.name = HK47_NAME
	droid.equipOutfit(/datum/outfit/hk47)
	droid.set_nutrition(NUTRITION_LEVEL_FED)
	droid.mind_initialize()
	allocated += droid.mind
	var/datum/antagonist/hk47/contract_fixture/upgrade_test/hunter = new
	droid.mind.add_antag_datum(hunter)
	return hunter

/datum/unit_test/proc/hk47_take_rifle(mob/living/carbon/human/droid)
	var/obj/item/gun/energy/hk_rifle/rifle = droid.back
	droid.temporarilyRemoveItemFromInventory(rifle, TRUE)
	droid.put_in_active_hand(rifle)
	return rifle

/// Покупка списывает очки, без очков не проходит, разовое улучшение второй раз не продаётся.
/datum/unit_test/hk47_upgrade_purchase

/datum/unit_test/hk47_upgrade_purchase/Run()
	var/datum/antagonist/hk47/contract_fixture/upgrade_test/hunter = allocate_hk47_droid()
	var/datum/hk47_upgrade/plates = GLOB.hk47_upgrades["plates"]
	TEST_ASSERT(!hunter.buy_upgrade("plates"), "bought without points")
	TEST_ASSERT(findtext(plates.refusal(hunter), "очк"), "the refusal names the missing points: [plates.refusal(hunter)]")
	hunter.points = 3
	TEST_ASSERT(hunter.buy_upgrade("plates"), "plates bought")
	TEST_ASSERT_EQUAL(hunter.points, 3 - plates.cost, "the price is deducted")
	TEST_ASSERT_EQUAL(hunter.upgrades["plates"], 1, "the purchase is recorded")
	TEST_ASSERT(!hunter.buy_upgrade("plates"), "a one-time upgrade sold twice")
	TEST_ASSERT_EQUAL(hunter.points, 3 - plates.cost, "a refused purchase costs nothing")
	TEST_ASSERT(!hunter.buy_upgrade("no_such_upgrade"), "an unknown upgrade is not sold")
	var/datum/hk47_upgrade/ghost = GLOB.hk47_upgrades["ghost_servant"]
	TEST_ASSERT_EQUAL(ghost.cost, 2, "the ghost HK-50 costs two points")
	hunter.contracts_done = HK47_GHOST_SERVANT_MIN_CONTRACTS
	TEST_ASSERT(hunter.buy_upgrade("ghost_servant"), "the ghost HK-50 is ordered")
	TEST_ASSERT_EQUAL(hunter.points, 3 - plates.cost, "nobody answered: the points are refunded")
	TEST_ASSERT(!hunter.upgrades["ghost_servant"], "a refunded order can be placed again")

/// Пара NPC HK-50 прилетает капсулой к HK; вторая не покупается, пока жива первая.
/datum/unit_test/hk47_upgrade_servant_pair

/datum/unit_test/hk47_upgrade_servant_pair/Run()
	var/datum/antagonist/hk47/contract_fixture/upgrade_test/hunter = allocate_hk47_droid()
	var/mob/living/carbon/human/droid = hunter.owner.current
	hunter.points = 3
	TEST_ASSERT(hunter.buy_upgrade("servants"), "the pair is ordered")
	allocated += hunter.sent_pods
	var/list/pair = hk50_servants_of(droid)
	allocated += pair
	TEST_ASSERT_EQUAL(length(hunter.sent_pods), 1, "the pair comes in a capsule")
	TEST_ASSERT_EQUAL(length(pair), HK50_SERVANT_PAIR_SIZE, "the capsule brings a pair")
	var/mob/living/lead = pair[1]
	TEST_ASSERT(get_dist(lead, droid) <= 1, "the capsule lands next to HK-47")
	var/mob/living/wingman = pair[2]
	TEST_ASSERT(get_turf(lead) != get_turf(wingman), "the pair lands on two tiles, not stacked")
	TEST_ASSERT(get_turf(lead) != get_turf(droid) && get_turf(wingman) != get_turf(droid), "the pair leaves HK-47's tile free")
	TEST_ASSERT_EQUAL(hunter.points, 2, "the pair costs one point")
	TEST_ASSERT(!hunter.buy_upgrade("servants"), "a second pair while the first is alive")
	var/datum/hk47_upgrade/servants = GLOB.hk47_upgrades["servants"]
	TEST_ASSERT(findtext(servants.refusal(hunter), "HK-50"), "the refusal explains the active pair")
	for(var/mob/living/servant as anything in pair)
		servant.death()
	TEST_ASSERT(hunter.buy_upgrade("servants"), "a new pair after the old one is gone")
	allocated += hk50_servants_of(droid)
	TEST_ASSERT_EQUAL(hunter.upgrades["servants"], 2, "the pair is repeatable")

/// Бронеплиты добавляют 10 брони именно этому дроиду: урон падает по формуле брони вида.
/datum/unit_test/hk47_upgrade_plates

/datum/unit_test/hk47_upgrade_plates/Run()
	var/datum/antagonist/hk47/contract_fixture/upgrade_test/hunter = allocate_hk47_droid()
	var/mob/living/carbon/human/droid = hunter.owner.current
	var/mob/living/carbon/human/twin = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	twin.set_species(/datum/species/ipc/hk/hk47)
	hunter.points = 1
	TEST_ASSERT(hunter.buy_upgrade("plates"), "plates bought")
	TEST_ASSERT_EQUAL(twin.dna.species.armor, HK_ARMOR, "plates stay on the buyer")
	twin.apply_damage(20, BURN, BODY_ZONE_CHEST)
	droid.apply_damage(20, BURN, BODY_ZONE_CHEST)
	var/bare_hit = twin.getFireLoss()
	var/plated_hit = droid.getFireLoss()
	TEST_ASSERT(abs((bare_hit - plated_hit) - 20 * HK47_PLATES_ARMOR / 100) < 0.1, "plates take [HK47_PLATES_ARMOR]% off: bare [bare_hit], plated [plated_hit]")

/// Плиты видны на корпусе, маскировка прячет их на время, а броня остаётся.
/datum/unit_test/hk47_upgrade_plates_look

/datum/unit_test/hk47_upgrade_plates_look/Run()
	var/datum/antagonist/hk47/contract_fixture/upgrade_test/hunter = allocate_hk47_droid()
	var/mob/living/carbon/human/droid = hunter.owner.current
	hunter.points = 2
	TEST_ASSERT(hunter.buy_upgrade("plates"), "plates bought")
	TEST_ASSERT(plates_drawn(droid), "the plates show on the chassis")
	TEST_ASSERT(hunter.buy_upgrade("disguise"), "disguise bought")
	var/datum/component/hk47_disguise/disguise = droid.GetComponent(/datum/component/hk47_disguise)
	TEST_ASSERT(disguise.enable(), "disguise on")
	TEST_ASSERT(!plates_drawn(droid), "the disguise hides the plates")
	TEST_ASSERT_EQUAL(droid.dna.species.armor, HK_ARMOR + HK47_PLATES_ARMOR, "hidden plates still protect")
	disguise.drop()
	TEST_ASSERT(plates_drawn(droid), "the plates show again without the disguise")
	TEST_ASSERT_EQUAL(droid.dna.species.armor, HK_ARMOR + HK47_PLATES_ARMOR, "the armor is unchanged")

/datum/unit_test/hk47_upgrade_plates_look/proc/plates_drawn(mob/living/carbon/human/droid)
	for(var/mutable_appearance/overlay in droid.overlays_standing[BODY_LAYER])
		if(overlay.icon_state == "hk_plates")
			return TRUE
	return FALSE

/// Снайперский режим: прицел держится только при прямой видимости, выстрел стоит три заряда и уводит режим на перезарядку.
/datum/unit_test/hk47_upgrade_sniper

/datum/unit_test/hk47_upgrade_sniper/Run()
	var/datum/antagonist/hk47/contract_fixture/upgrade_test/hunter = allocate_hk47_droid()
	var/mob/living/carbon/human/droid = hunter.owner.current
	var/obj/item/gun/energy/hk_rifle/rifle = hk47_take_rifle(droid)
	hunter.points = 1
	TEST_ASSERT(hunter.buy_upgrade("sniper"), "sniper mode bought")
	TEST_ASSERT(rifle.sniper_unlocked, "the rifle is unlocked")
	TEST_ASSERT(!rifle.sniper_selected(), "the rifle stays in bolt mode until switched")
	rifle.attack_self(droid)
	TEST_ASSERT(rifle.sniper_selected(), "attack_self switches to the sniper mode")
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human, locate(droid.x + 3, droid.y, droid.z))
	TEST_ASSERT(rifle.sniper_aim_holds(droid, target), "the aim holds on a target in sight")
	var/obj/structure/closet/blocker = allocate(/obj/structure/closet, locate(droid.x + 1, droid.y, droid.z))
	blocker.set_opacity(TRUE)
	TEST_ASSERT(!rifle.sniper_aim_holds(droid, target), "the aim breaks when the target leaves the line of sight")
	blocker.set_opacity(FALSE)
	var/charge_before = rifle.cell.charge
	TEST_ASSERT(rifle.sniper_fire(target, droid), "the sniper shot fires")
	TEST_ASSERT_EQUAL(charge_before - rifle.cell.charge, HK47_SNIPER_SHOT_CHARGES * HK_RIFLE_SHOT_COST, "the sniper shot costs three charges")
	TEST_ASSERT(abs(COOLDOWN_TIMELEFT(rifle, sniper_cooldown) - HK47_SNIPER_COOLDOWN) < 0.1, "the mode goes on cooldown")
	TEST_ASSERT(!rifle.process_fire(target, droid), "no second sniper shot during the cooldown")
	TEST_ASSERT(!rifle.aiming, "the cooldown refuses before aiming")

/// Маскировка: имя и корпус HK-50, сигнал пеленгатору; выстрел её срывает, повтор - через 30 секунд.
/datum/unit_test/hk47_upgrade_disguise

/datum/unit_test/hk47_upgrade_disguise/Run()
	var/datum/antagonist/hk47/contract_fixture/upgrade_test/hunter = allocate_hk47_droid()
	var/mob/living/carbon/human/droid = hunter.owner.current
	var/obj/item/gun/energy/hk_rifle/rifle = hk47_take_rifle(droid)
	hunter.points = 1
	TEST_ASSERT(hunter.buy_upgrade("disguise"), "disguise bought")
	var/datum/component/hk47_disguise/disguise = droid.GetComponent(/datum/component/hk47_disguise)
	TEST_ASSERT_NOTNULL(disguise, "the disguise is installed")
	TEST_ASSERT(locate(/datum/action/innate/hk47_disguise) in droid.actions, "the disguise has a button")
	TEST_ASSERT(disguise.enable(), "disguise on")
	TEST_ASSERT_EQUAL(droid.name, HK47_DISGUISE_NAME, "the visible name is the protocol droid")
	TEST_ASSERT_EQUAL(droid.GetVoice(), HK47_DISGUISE_NAME, "the voice is the protocol droid")
	TEST_ASSERT(HAS_TRAIT(droid, TRAIT_HK47_DISGUISED), "the pinpointer can see the disguise")
	hunter.status = HK47_STATUS_OUTLAW
	var/obj/item/pinpointer/hk47/tracker = allocate(/obj/item/pinpointer/hk47, get_turf(droid), hunter)
	TEST_ASSERT_NULL(tracker.signal_source(), "the security tracker loses a disguised HK")
	TEST_ASSERT_EQUAL(droid.dna.species.mutant_bodyparts["limbs_id"], HK_MODEL_50, "the chassis looks like an HK-50")
	rifle.process_fire(get_step(droid, NORTH), droid)
	TEST_ASSERT(!disguise.active, "firing breaks the disguise")
	TEST_ASSERT_EQUAL(droid.name, HK47_NAME, "the real name is back")
	TEST_ASSERT(!HAS_TRAIT(droid, TRAIT_HK47_DISGUISED), "the pinpointer sees HK-47 again")
	TEST_ASSERT_EQUAL(tracker.signal_source(), droid, "the tracker locks on the wanted HK again")
	TEST_ASSERT_EQUAL(droid.dna.species.mutant_bodyparts["limbs_id"], HK_MODEL_47, "the HK-47 chassis is back")
	TEST_ASSERT(!disguise.enable(), "the disguise waits after being broken")
	TEST_ASSERT(abs(COOLDOWN_TIMELEFT(disguise, reenable_cooldown) - HK47_DISGUISE_COOLDOWN) < 0.1, "thirty seconds until the next disguise")
	COOLDOWN_RESET(disguise, reenable_cooldown)
	TEST_ASSERT(disguise.enable(), "the disguise comes back after the pause")
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, get_step(droid, EAST))
	victim.set_last_attacker(droid)
	TEST_ASSERT(!disguise.active, "an attack breaks the disguise")

/// Двигатели включаются кнопкой, тратят заряд HK за клетку и глохнут у нижней границы заряда.
/datum/unit_test/hk47_upgrade_thrusters

/datum/unit_test/hk47_upgrade_thrusters/Run()
	var/datum/antagonist/hk47/contract_fixture/upgrade_test/hunter = allocate_hk47_droid()
	var/mob/living/carbon/human/droid = hunter.owner.current
	hunter.points = 1
	TEST_ASSERT(hunter.buy_upgrade("thrusters"), "thrusters bought")
	var/obj/item/organ/cyberimp/chest/thrusters/hk/engine = droid.getorganslot(ORGAN_SLOT_THRUSTERS)
	TEST_ASSERT(istype(engine), "the thrusters are in the chest")
	droid.set_nutrition(HK47_UPGRADE_MIN_NUTRITION + HK47_THRUSTER_NUTRITION_PER_TILE)
	engine.ui_action_click()
	TEST_ASSERT(engine.on, "the thrusters start with enough charge")
	TEST_ASSERT(engine.allow_thrust(0.01), "a tile of flight")
	TEST_ASSERT_EQUAL(droid.nutrition, HK47_UPGRADE_MIN_NUTRITION, "the tile cost HK charge")
	engine.last_thrust_time = -1
	TEST_ASSERT(!engine.allow_thrust(0.01), "no flight below the charge floor")
	TEST_ASSERT(!engine.on, "the thrusters shut down")
	TEST_ASSERT_EQUAL(droid.nutrition, HK47_UPGRADE_MIN_NUTRITION, "the floor is kept")

/// Самовосстановление чинит после паузы без урона, не под огнём и не выше 70% прочности.
/datum/unit_test/hk47_upgrade_self_repair

/datum/unit_test/hk47_upgrade_self_repair/Run()
	var/datum/antagonist/hk47/contract_fixture/upgrade_test/hunter = allocate_hk47_droid()
	var/mob/living/carbon/human/droid = hunter.owner.current
	hunter.points = 1
	TEST_ASSERT(hunter.buy_upgrade("self_repair"), "self-repair bought")
	var/datum/component/hk47_self_repair/repair = droid.GetComponent(/datum/component/hk47_self_repair)
	TEST_ASSERT_NOTNULL(repair, "self-repair installed")
	droid.apply_damage(60, BRUTE, BODY_ZONE_CHEST)
	droid.apply_damage(40, BURN, BODY_ZONE_CHEST)
	TEST_ASSERT(droid.health < droid.maxHealth * HK47_REPAIR_HEALTH_CAP, "the droid is badly damaged")
	var/health_before = droid.health
	TEST_ASSERT_EQUAL(repair.repair_tick(2), 0, "no repair right after damage")
	TEST_ASSERT_EQUAL(droid.health, health_before, "health unchanged under fire")
	repair.last_damage_time = world.time - HK47_REPAIR_DELAY
	var/brute_before = droid.getBruteLoss()
	var/burn_before = droid.getFireLoss()
	var/nutrition_before = droid.nutrition
	var/healed = repair.repair_tick(2)
	TEST_ASSERT(abs(healed - HK47_REPAIR_PER_SECOND * 2) < 0.01, "repair rate per second: healed [healed]")
	TEST_ASSERT(abs((brute_before - droid.getBruteLoss()) - (burn_before - droid.getFireLoss())) < 0.01, "brute and burn are repaired equally")
	TEST_ASSERT(abs(nutrition_before - droid.nutrition - healed * HK47_REPAIR_NUTRITION_PER_HP) < 0.01, "each HP costs charge")
	repair.repair_tick(1000)
	TEST_ASSERT(abs(droid.health - droid.maxHealth * HK47_REPAIR_HEALTH_CAP) < 0.1, "repair stops at the cap: [droid.health]")
	TEST_ASSERT_EQUAL(repair.repair_tick(2), 0, "no repair above the cap")
	droid.apply_damage(30, BRUTE, BODY_ZONE_CHEST)
	TEST_ASSERT_EQUAL(repair.repair_tick(2), 0, "new damage restarts the pause")

/// Самовосстановление устраняет травмы по одной, тяжёлые первыми, за заряд и только после паузы без урона.
/datum/unit_test/hk47_self_repair_wounds

/datum/unit_test/hk47_self_repair_wounds/Run()
	var/datum/antagonist/hk47/contract_fixture/upgrade_test/hunter = allocate_hk47_droid()
	var/mob/living/carbon/human/droid = hunter.owner.current
	hunter.points = 1
	TEST_ASSERT(hunter.buy_upgrade("self_repair"), "self-repair bought")
	var/datum/component/hk47_self_repair/repair = droid.GetComponent(/datum/component/hk47_self_repair)
	var/datum/wound/blunt/moderate/dislocation = new
	dislocation.apply_wound(droid.get_bodypart(BODY_ZONE_L_ARM))
	var/datum/wound/blunt/severe/fracture = new
	fracture.apply_wound(droid.get_bodypart(BODY_ZONE_R_LEG))
	TEST_ASSERT_EQUAL(length(droid.all_wounds), 2, "two wounds applied")
	repair.last_damage_time = world.time
	TEST_ASSERT(!repair.repair_wounds(100), "no wound repair right after damage")
	repair.last_damage_time = world.time - HK47_REPAIR_DELAY
	var/nutrition_before = droid.nutrition
	var/severe_time = WOUND_SEVERITY_SEVERE * HK47_REPAIR_WOUND_TIME / (1 SECONDS)
	TEST_ASSERT(!repair.repair_wounds(severe_time - 1), "a severe wound takes its full time")
	TEST_ASSERT(repair.repair_wounds(1), "the severe wound is repaired")
	TEST_ASSERT(QDELETED(fracture), "the fracture goes first")
	TEST_ASSERT_EQUAL(length(droid.all_wounds), 1, "one wound left")
	TEST_ASSERT(abs(nutrition_before - droid.nutrition - WOUND_SEVERITY_SEVERE * HK47_REPAIR_WOUND_NUTRITION) < 0.01, "the repair costs charge per severity")
	droid.set_nutrition(HK47_UPGRADE_MIN_NUTRITION)
	TEST_ASSERT(!repair.repair_wounds(100), "no repair without charge")
	droid.set_nutrition(NUTRITION_LEVEL_WELL_FED)
	TEST_ASSERT(repair.repair_wounds(100), "the dislocation is repaired")
	TEST_ASSERT(!length(droid.all_wounds), "no wounds left")

/// Кнопки терминала доходят до контрактов и магазина: принять, отказаться, скан, захват, опознание, покупка.
/datum/unit_test/hk47_terminal_actions

/datum/unit_test/hk47_terminal_actions/Run()
	var/datum/antagonist/hk47/contract_fixture/upgrade_test/hunter = allocate_hk47_droid()
	var/mob/living/carbon/human/droid = hunter.owner.current
	var/datum/hk_terminal/terminal = hunter.terminal
	TEST_ASSERT_NOTNULL(terminal, "the terminal is built in")
	TEST_ASSERT(locate(/datum/action/innate/hk_terminal) in droid.actions, "the terminal has a button")
	var/datum/tgui/ui = allocate(/datum/tgui, droid, terminal, "HKContractTerminal")
	ui.status = UI_INTERACTIVE
	var/datum/mind/victim = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_KILL)
	var/datum/mind/spare = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_KILL)
	var/datum/hk_contract/offer = hunter.add_offer(/datum/hk_contract_task/kill, victim)
	var/list/data = terminal.ui_data(droid)
	TEST_ASSERT_EQUAL(length(data["offers"]), 1, "the offer is shown")
	var/list/offers_shown = data["offers"]
	var/list/offer_entry = offers_shown[1]
	TEST_ASSERT_NULL(offer_entry["photo"], "photos never ride in the per-second data")
	var/list/static_data = terminal.ui_static_data(droid)
	var/list/photos = static_data["photos"]
	TEST_ASSERT(length(photos[offer_entry["id"]]), "a known target comes with a photo in the static data")
	terminal.ui_act("accept", list("ref" = REF(offer)), ui)
	TEST_ASSERT_EQUAL(hunter.active_contract, offer, "accept takes the offer")
	victim.current.death()
	victim.current.forceMove(get_step(droid, EAST))
	terminal.ui_act("scan", list(), ui)
	TEST_ASSERT_EQUAL(hunter.contracts_done, 1, "scan closes the kill")
	data = terminal.ui_data(droid)
	var/list/history = data["history"]
	var/list/entry = history[1]
	TEST_ASSERT(findtext(entry["comment"], "Комментарий:"), "the log carries an HK comment")
	hunter.accept(hunter.add_offer(/datum/hk_contract_task/kill, spare))
	terminal.ui_act("reroll", list(), ui)
	TEST_ASSERT_NULL(hunter.active_contract, "reroll refuses the contract")
	TEST_ASSERT(COOLDOWN_TIMELEFT(hunter, reroll_cooldown) > 0, "the refusal is voluntary")
	var/datum/mind/prisoner = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_TEMPORARY, get_step(droid, NORTH))
	hunter.accept(hunter.add_offer(/datum/hk_contract_task/capture, prisoner))
	prisoner.current.Paralyze(10 SECONDS)
	terminal.ui_act("capture", list(), ui)
	TEST_ASSERT_EQUAL(hunter.called_extraction, hunter.active_contract, "capture calls the capsule for the target")
	hunter.capture_loaded(hunter.active_contract, prisoner.current)
	data = terminal.ui_data(droid)
	var/list/tallies = data["tallies"]
	TEST_ASSERT_EQUAL(tallies["killed"], 1, "the journal counts the kill")
	TEST_ASSERT_EQUAL(tallies["captured"], 1, "the journal counts the capture")
	var/datum/mind/runner = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_KILL, locate(droid.x + 2, droid.y, droid.z))
	mark_hk47_antag(runner)
	runner.hk47_kill_time = world.time
	var/datum/hk_contract/hunt_offer = hunter.add_offer(/datum/hk_contract_task/hunt, runner)
	data = terminal.ui_data(droid)
	TEST_ASSERT(!findtext(json_encode(data["offers"]), runner.current.real_name), "a hunt offer never names the target")
	offers_shown = data["offers"]
	offer_entry = offers_shown[length(offers_shown)]
	static_data = terminal.ui_static_data(droid)
	photos = static_data["photos"]
	TEST_ASSERT(!(offer_entry["id"] in photos), "a hunt offer never shows the target")
	hunter.accept(hunt_offer)
	data = terminal.ui_data(droid)
	var/list/active = data["active"]
	var/list/active_dossier = active.Copy()
	active_dossier -= "suspects"
	TEST_ASSERT(!findtext(json_encode(active_dossier), runner.current.real_name), "the active hunt never names the target")
	static_data = terminal.ui_static_data(droid)
	photos = static_data["photos"]
	TEST_ASSERT(!(active["id"] in photos), "the active hunt never shows the target")
	TEST_ASSERT_NULL(active["radar"], "no radar blip for an unidentified target")
	terminal.ui_act("identify", list("ref" = REF(runner.current)), ui)
	TEST_ASSERT(hunter.active_contract.identified, "identify checks the suspect")
	hunter.points = 1
	terminal.ui_act("buy", list("id" = "plates"), ui)
	TEST_ASSERT_EQUAL(hunter.upgrades["plates"], 1, "buy reaches the shop")
	TEST_ASSERT_EQUAL(hunter.points, 0, "buy spends points")
	data = terminal.ui_data(droid)
	var/list/station = data["station"]
	TEST_ASSERT_EQUAL(station["status_name"], hk47_status_name(hunter.status), "the terminal shows the station status")
	TEST_ASSERT(!station["extraction_available"], "no extraction before three contracts")
	hunter.contracts_done = HK47_CONTRACTS_TO_WIN
	hunter.test_space = TRUE
	terminal.ui_act("extract", list(), ui)
	var/obj/structure/closet/supplypod/hk47/extraction/pod = hunter.extraction_pod_ref?.resolve()
	TEST_ASSERT_NOTNULL(pod, "extract reaches the extraction signal")
	allocated += pod

/// Целеуказатель: стрелка и полоса дальности на том же уровне, цель на своей клетке - на нулевой дистанции; неопознанная цель охоты - только след.
/datum/unit_test/hk47_tracker

/datum/unit_test/hk47_tracker/Run()
	var/datum/antagonist/hk47/contract_fixture/upgrade_test/hunter = allocate_hk47_droid()
	var/mob/living/carbon/human/droid = hunter.owner.current
	var/datum/status_effect/hk47_tracker/tracker = droid.has_status_effect(/datum/status_effect/hk47_tracker)
	TEST_ASSERT_NOTNULL(tracker, "HK-47 carries the tracker")
	tracker.update_pointer()
	TEST_ASSERT_EQUAL(tracker.pointer, "pinonnull", "no contract, no arrow")
	var/datum/mind/victim = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_KILL, locate(droid.x + 3, droid.y, droid.z))
	hunter.accept(hunter.add_offer(/datum/hk_contract_task/kill, victim))
	tracker.update_pointer()
	TEST_ASSERT_EQUAL(tracker.pointer, "pinonclose", "a near target")
	TEST_ASSERT_EQUAL(tracker.linked_alert.dir, EAST, "the arrow points to the target")
	TEST_ASSERT(findtext(tracker.linked_alert.desc, victim.current.real_name), "the alert names the target")
	var/list/reading = hunter.active_contract.radar_reading(droid)
	TEST_ASSERT_EQUAL(reading["band"], "near", "the radar band")
	TEST_ASSERT_EQUAL(reading["angle"], 90, "the radar blip is east")
	victim.current.forceMove(get_turf(droid))
	reading = hunter.active_contract.radar_reading(droid)
	TEST_ASSERT_EQUAL(reading["distance"], 0, "a target on the same tile is at zero distance")
	TEST_ASSERT_NULL(reading["direction"], "a target on the same tile has no direction")
	tracker.update_pointer()
	TEST_ASSERT_EQUAL(tracker.pointer, "pinondirect", "the arrow shows a target right here")
	victim.current.moveToNullspace()
	tracker.update_pointer()
	TEST_ASSERT_EQUAL(tracker.pointer, "pinonnull", "no arrow to another level")
	hunter.reroll(FALSE)
	var/datum/mind/runner = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_KILL, locate(droid.x + 4, droid.y, droid.z))
	mark_hk47_antag(runner)
	runner.hk47_kill_time = world.time
	runner.hk47_kill_area = "Место убийства"
	hunter.accept(hunter.make_contract(HK_CLIENT_SYNDICATE, /datum/hk_contract_task/hunt, null, runner))
	tracker.update_pointer()
	TEST_ASSERT_EQUAL(tracker.pointer, "pinonnull", "no arrow to an unidentified target")
	TEST_ASSERT(findtext(tracker.linked_alert.desc, "Место убийства"), "the trace is shown")
	TEST_ASSERT(findtext(tracker.linked_alert.desc, "Сигнатура рядом"), "a near signature is reported")
	TEST_ASSERT(!findtext(tracker.linked_alert.desc, runner.current.real_name), "the name stays hidden")

/// Снимок цели делается один раз на контракт и живёт только в static data; ушедшее досье уносит снимок с собой.
/datum/unit_test/hk47_terminal_photos

/datum/unit_test/hk47_terminal_photos/Run()
	var/datum/antagonist/hk47/contract_fixture/upgrade_test/hunter = allocate_hk47_droid()
	var/mob/living/carbon/human/droid = hunter.owner.current
	var/datum/hk_terminal/terminal = hunter.terminal
	var/datum/mind/target = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_KILL)
	var/datum/hk_contract/offer = hunter.add_offer(/datum/hk_contract_task/kill, target)
	var/list/static_data = terminal.ui_static_data(droid)
	var/list/photos = static_data["photos"]
	var/photo = photos["[offer.id]"]
	TEST_ASSERT(length(photo), "the photo is taken")
	TEST_ASSERT_EQUAL(terminal.sent_photos_key, "[offer.id]", "the terminal remembers which photos it sent")
	offer.photo = "retaken"
	static_data = terminal.ui_static_data(droid)
	photos = static_data["photos"]
	TEST_ASSERT_EQUAL(photos["[offer.id]"], "retaken", "the photo is not retaken for the same contract")
	hunter.offers -= offer
	qdel(offer)
	static_data = terminal.ui_static_data(droid)
	photos = static_data["photos"]
	TEST_ASSERT(!length(photos), "a gone dossier takes its photo with it")

/// Окно слушает только самого HK, покупка проверяет id, недоступное предложение помечено и меняется бесплатно.
/datum/unit_test/hk47_terminal_guards

/datum/unit_test/hk47_terminal_guards/Run()
	var/datum/antagonist/hk47/contract_fixture/upgrade_test/hunter = allocate_hk47_droid()
	var/mob/living/carbon/human/droid = hunter.owner.current
	var/datum/hk_terminal/terminal = hunter.terminal
	var/mob/living/carbon/human/stranger = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	var/datum/tgui/stranger_ui = allocate(/datum/tgui, stranger, terminal, "HKContractTerminal")
	stranger_ui.status = UI_INTERACTIVE
	var/datum/tgui/ui = allocate(/datum/tgui, droid, terminal, "HKContractTerminal")
	ui.status = UI_INTERACTIVE
	var/datum/mind/target = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_KILL)
	var/datum/mind/runaway = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_KILL)
	hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_KILL)
	var/datum/hk_contract/offer = hunter.add_offer(/datum/hk_contract_task/kill, target)
	var/datum/hk_contract/gone = hunter.add_offer(/datum/hk_contract_task/kill, runaway)
	terminal.ui_act("accept", list("ref" = REF(offer)), stranger_ui)
	TEST_ASSERT_NULL(hunter.active_contract, "a stranger's window does not accept contracts")
	hunter.points = 5
	terminal.ui_act("buy", list("id" = 1), ui)
	TEST_ASSERT_EQUAL(hunter.points, 5, "a non-text module id buys nothing")
	var/list/data = terminal.ui_data(droid)
	var/list/upgrades_shown = data["upgrades"]
	for(var/list/upgrade_entry as anything in upgrades_shown)
		var/datum/hk47_upgrade/upgrade = GLOB.hk47_upgrades[upgrade_entry["id"]]
		TEST_ASSERT_EQUAL(upgrade_entry["cost"], upgrade.price(hunter), "the module shows the price of the next purchase")
	runaway.current.moveToNullspace()
	data = terminal.ui_data(droid)
	var/list/offers_shown = data["offers"]
	var/list/gone_entry = offers_shown[2]
	TEST_ASSERT(length(gone_entry["unavailable"]), "the unavailable offer is marked")
	var/list/offer_entry = offers_shown[1]
	TEST_ASSERT_NULL(offer_entry["unavailable"], "an available offer is not marked")
	TEST_ASSERT(offer_entry["client_flavor"], "the dossier shows the client")
	terminal.ui_act("replace", list(), ui)
	TEST_ASSERT(QDELETED(gone), "replace swaps the unavailable offer")
	TEST_ASSERT(offer in hunter.offers, "replace keeps the available offer")
	TEST_ASSERT(COOLDOWN_FINISHED(hunter, reroll_cooldown), "replace is free")

/// HK-50 с разумом: тело HK-50 с целью служить; гибель хозяина меняет цель на выживание.
/datum/unit_test/hk47_ghost_servant

/datum/unit_test/hk47_ghost_servant/Run()
	var/datum/antagonist/hk47/contract_fixture/upgrade_test/hunter = allocate_hk47_droid()
	var/mob/living/carbon/human/droid = hunter.owner.current
	var/mob/living/carbon/human/servant = hunter.create_ghost_servant(run_loc_floor_top_right, null)
	allocated += list(servant, servant.mind)
	TEST_ASSERT(is_species(servant, /datum/species/ipc/hk/hk50), "an HK-50 chassis")
	var/datum/antagonist/hk50_servant/servitude = servant.mind.has_antag_datum(/datum/antagonist/hk50_servant)
	TEST_ASSERT_NOTNULL(servitude, "the servant role")
	TEST_ASSERT(locate(/datum/objective/hk50_serve) in servitude.objectives, "the servant serves HK-47")
	TEST_ASSERT(hunter.is_hk_side(servant), "the servant is on HK-47's side")
	TEST_ASSERT_EQUAL(servant.mind.enslaved_to, droid, "the servant is bound to HK-47")
	droid.death()
	TEST_ASSERT(!(locate(/datum/objective/hk50_serve) in servitude.objectives), "nobody left to serve")
	TEST_ASSERT(locate(/datum/objective/escape/hk50) in servitude.objectives, "the servant survives and escapes")
