/datum/round_event/ghost_role/hk47/test_empty_poll
	var/refunded = FALSE
	var/turf/test_landing

/datum/round_event/ghost_role/hk47/test_empty_poll/pick_landing_turf()
	return test_landing

/datum/round_event/ghost_role/hk47/test_empty_poll/get_candidates(jobban, gametypecheck, be_special)
	return list()

/datum/round_event/ghost_role/hk47/test_empty_poll/refund_failed_spawn(reason)
	refunded = TRUE

/// Событие HK-47 проходит требования директора к гост-событиям, роль включается в префах.
/datum/unit_test/hk47_event_director_contract

/datum/unit_test/hk47_event_director_contract/Run()
	var/datum/round_event_control/hk47/control = allocate(/datum/round_event_control/hk47)
	TEST_ASSERT_EQUAL(control.severity, DIRECTOR_SEVERITY_GHOST, "ghost severity")
	TEST_ASSERT(control.cost > 0 && control.intensity > 0, "cost and intensity")
	TEST_ASSERT_EQUAL(control.director_ghost_preference, ROLE_HK47, "preference")
	TEST_ASSERT_EQUAL(control.director_ghost_jobban, ROLE_HK47, "jobban")
	TEST_ASSERT(locate(/datum/round_event_control/hk47) in SSdirector.actions, "director knows the event")
	var/datum/preferences/prefs = new
	prefs.be_special = list()
	var/accepted = prefs.set_antag_preference(ROLE_HK47, ANTAG_PRIORITY_HIGH)
	qdel(prefs)
	TEST_ASSERT(accepted, "role selectable in prefs")

/datum/round_event/ghost_role/hk47/test_launch
	var/legend = HK47_STATUS_COVERT
	var/crash = FALSE

/datum/round_event/ghost_role/hk47/test_launch/roll_legend()
	return legend

/datum/round_event/ghost_role/hk47/test_launch/roll_crash()
	return crash

/// Тайная легенда сажает HK-47 капсулой: шасси, винтовка, роль; голос прибытия звучит при выходе на палубу, а не в пустоте до посадки.
/datum/unit_test/hk47_launch_capsule

/datum/unit_test/hk47_launch_capsule/Run()
	var/datum/round_event/ghost_role/hk47/test_launch/event = allocate(/datum/round_event/ghost_role/hk47/test_launch, FALSE)
	SSdirector.running -= event
	var/mob/living/carbon/human/droid = event.launch_hk47(null, run_loc_floor_bottom_left)
	var/obj/effect/pod_landingzone/zone = locate() in run_loc_floor_bottom_left
	if(zone)
		allocated += list(zone.helper, zone)
	allocated += list(droid.loc, droid, droid.mind)
	TEST_ASSERT(is_species(droid, /datum/species/ipc/hk/hk47), "HK-47 species")
	TEST_ASSERT_EQUAL(droid.real_name, HK47_NAME, "HK-47 name")
	TEST_ASSERT(istype(droid.back, /obj/item/gun/energy/hk_rifle), "rifle on the back")
	var/datum/component/hk_loyalty/loyalty = droid.GetComponent(/datum/component/hk_loyalty)
	TEST_ASSERT_NOTNULL(loyalty, "loyalty block")
	TEST_ASSERT_NULL(loyalty.get_master(), "no master on arrival")
	var/datum/antagonist/hk47/antag = droid.mind.has_antag_datum(/datum/antagonist/hk47)
	TEST_ASSERT_NOTNULL(antag, "HK-47 antagonist")
	TEST_ASSERT_EQUAL(antag.status, HK47_STATUS_COVERT, "the fixed covert legend")
	TEST_ASSERT_EQUAL(length(antag.objectives), 2, "contracts + extract objectives")
	TEST_ASSERT_EQUAL(droid.mind.assigned_role, ROLE_HK47, "assigned role")
	TEST_ASSERT_EQUAL(droid.mind.special_role, ROLE_HK47, "special role")
	TEST_ASSERT(istype(droid.loc, /obj/structure/closet/supplypod/hk47/covert), "HK-47 rides inside the covert capsule")
	TEST_ASSERT_NOTNULL(zone, "capsule targets the landing turf")
	TEST_ASSERT_EQUAL(zone.pod, droid.loc, "the landing zone carries HK-47's capsule")
	TEST_ASSERT_NULL(zone.helper, "no landing marker for a covert capsule")
	TEST_ASSERT(!zone.alpha && !zone.light_range, "the landing zone neither shows nor glows")
	TEST_ASSERT_NULL(antag.last_voice, "nothing is heard before landing")
	TEST_ASSERT(COOLDOWN_FINISHED(antag, voice_cooldown), "a greeting in nullspace does not spend the voice cooldown")
	droid.forceMove(run_loc_floor_top_right)
	TEST_ASSERT_EQUAL(antag.last_voice, "hk47_activate", "the arrival line plays when HK-47 steps onto the deck")
	antag.last_voice = null
	droid.forceMove(run_loc_floor_bottom_left)
	TEST_ASSERT_NULL(antag.last_voice, "the arrival line plays once")

/// Крушение: голос прибытия звучит, когда болид падает и HK-47 оказывается среди обломков.
/datum/unit_test/hk47_launch_crash

/datum/unit_test/hk47_launch_crash/Run()
	var/datum/round_event/ghost_role/hk47/test_launch/event = allocate(/datum/round_event/ghost_role/hk47/test_launch, FALSE)
	SSdirector.running -= event
	event.crash = TRUE
	var/mob/living/carbon/human/droid = event.launch_hk47(null, run_loc_floor_bottom_left)
	allocated += list(droid, droid.mind)
	var/datum/antagonist/hk47/antag = droid.mind.has_antag_datum(/datum/antagonist/hk47)
	var/obj/effect/temp_visual/hk47_crash_fall/fall = locate() in run_loc_floor_bottom_left
	TEST_ASSERT_NOTNULL(fall, "the wreck is falling")
	TEST_ASSERT_NULL(antag.last_voice, "silent while falling")
	qdel(fall)
	TEST_ASSERT_EQUAL(get_turf(droid), run_loc_floor_bottom_left, "HK-47 lands at the crash site")
	TEST_ASSERT_EQUAL(antag.last_voice, "hk47_activate", "the arrival line plays at the impact")

/// Без желающих гостов HK-47 не создаётся и бюджет директора возвращается; без техтоннелей - ошибка карты.
/datum/unit_test/hk47_spawn_needs_candidate

/datum/unit_test/hk47_spawn_needs_candidate/Run()
	var/datum/round_event/ghost_role/hk47/test_empty_poll/event = allocate(/datum/round_event/ghost_role/hk47/test_empty_poll, FALSE)
	SSdirector.running -= event
	event.test_landing = run_loc_floor_bottom_left
	event.try_spawning()
	TEST_ASSERT_EQUAL(event.status, NOT_ENOUGH_PLAYERS, "empty poll")
	TEST_ASSERT(event.refunded, "empty poll refunds the director")
	TEST_ASSERT(!length(event.spawned_mobs), "no droid without a player")
	TEST_ASSERT_NULL(locate(/obj/effect/pod_landingzone) in run_loc_floor_bottom_left, "no capsule without a player")
	event.test_landing = null
	event.refunded = FALSE
	event.try_spawning()
	TEST_ASSERT_EQUAL(event.status, MAP_ERROR, "no maintenance to land in")
	TEST_ASSERT(event.refunded, "map error refunds the director")

/// Контракты засчитываются частично и видны процентом в отчёте раунда; эвакуация сама не засчитывается.
/datum/unit_test/hk47_objectives

/datum/unit_test/hk47_objectives/Run()
	var/mob/living/carbon/human/droid = allocate(/mob/living/carbon/human)
	droid.mind_initialize()
	allocated += droid.mind
	var/datum/antagonist/hk47/antag = droid.mind.add_antag_datum(/datum/antagonist/hk47)
	var/datum/objective/hk47_contracts/contracts = locate() in antag.objectives
	var/datum/objective/hk47_extract/extract = locate() in antag.objectives
	TEST_ASSERT_NOTNULL(contracts, "contracts objective")
	TEST_ASSERT_NOTNULL(extract, "extract objective")
	TEST_ASSERT_EQUAL(contracts.check_completion(), 0, "no contracts done")
	antag.contracts_done = 1
	TEST_ASSERT_EQUAL(contracts.check_completion(), 1 / HK47_CONTRACTS_TO_WIN, "one contract is a partial success")
	TEST_ASSERT(findtext(antag.roundend_report(), "[round(100 / HK47_CONTRACTS_TO_WIN)]%"), "partial success shown as percent")
	antag.contracts_done = HK47_CONTRACTS_TO_WIN + 1
	TEST_ASSERT_EQUAL(contracts.check_completion(), 1, "completion capped at full success")
	TEST_ASSERT(!extract.check_completion(), "extraction is not done by itself")
	antag.award(2)
	antag.award(1)
	TEST_ASSERT_EQUAL(antag.points, 3, "award adds points")

/// Голосовая строка: неизвестный ключ молчит, повтор за кулдаун глушится, принудительная играет.
/datum/unit_test/hk47_voice_cooldown

/datum/unit_test/hk47_voice_cooldown/Run()
	var/mob/living/carbon/human/droid = allocate(/mob/living/carbon/human)
	droid.mind_initialize()
	allocated += droid.mind
	var/datum/antagonist/hk47/antag = droid.mind.add_antag_datum(/datum/antagonist/hk47)
	COOLDOWN_RESET(antag, voice_cooldown)
	antag.voice_lines["hk47_unit_test"] = 'sound/machines/ping.ogg'
	var/unknown = antag.hk_voice("hk47_unit_test_missing")
	var/first = antag.hk_voice("hk47_unit_test")
	var/repeated = antag.hk_voice("hk47_unit_test")
	var/forced = antag.hk_voice("hk47_unit_test", forced = TRUE)
	antag.voice_lines -= "hk47_unit_test"
	TEST_ASSERT(!unknown, "unknown key stays silent")
	TEST_ASSERT(first, "first line plays")
	TEST_ASSERT(!repeated, "repeat within the cooldown is skipped")
	TEST_ASSERT(forced, "forced line ignores the cooldown")

/datum/unit_test/proc/allocate_plain_hk47(turf/location)
	var/mob/living/carbon/human/droid = allocate(/mob/living/carbon/human, location || run_loc_floor_bottom_left)
	droid.set_species(/datum/species/ipc/hk/hk47)
	droid.real_name = HK47_NAME
	droid.name = HK47_NAME
	droid.mind_initialize()
	allocated += droid.mind
	return droid.mind.add_antag_datum(/datum/antagonist/hk47)

/// Модули шасси дорожают по порядку установки, пара HK-50 - с каждым вызовом, HK-50 с разумом открывается после двух контрактов.
/datum/unit_test/hk47_upgrade_price_curve

/datum/unit_test/hk47_upgrade_price_curve/Run()
	var/datum/antagonist/hk47/hunter = allocate_plain_hk47()
	var/list/module_prices = HK47_MODULE_PRICES
	var/list/modules = list("plates", "thrusters", "self_repair", "disguise")
	for(var/index in 1 to length(modules))
		var/datum/hk47_upgrade/upgrade = GLOB.hk47_upgrades[modules[index]]
		TEST_ASSERT_EQUAL(upgrade.price(hunter), module_prices[index], "module #[index] costs [module_prices[index]]")
		hunter.points = module_prices[index]
		TEST_ASSERT(hunter.buy_upgrade(modules[index]), "module #[index] is bought for its price")
		TEST_ASSERT_EQUAL(hunter.points, 0, "module #[index] takes exactly its price")
	var/datum/hk47_upgrade/sniper = GLOB.hk47_upgrades["sniper"]
	TEST_ASSERT_EQUAL(sniper.price(hunter), module_prices[5], "the fifth module")
	TEST_ASSERT(findtext(sniper.specs(), "ДАЛЕЕ [module_prices[length(module_prices)]]"), "the terminal text shows the price curve")

	var/datum/hk47_upgrade/servants = GLOB.hk47_upgrades["servants"]
	var/list/servant_prices = HK47_SERVANT_PRICES
	TEST_ASSERT_EQUAL(servants.price(hunter), servant_prices[1], "the first pair")
	hunter.upgrades["servants"] = 1
	TEST_ASSERT_EQUAL(servants.price(hunter), servant_prices[2], "the second pair costs more")
	hunter.upgrades["servants"] = 10
	TEST_ASSERT_EQUAL(servants.price(hunter), servant_prices[length(servant_prices)], "the price stops at the top of the curve")
	hunter.upgrades["servants"] = 2
	hunter.points = 0
	hunter.refund_upgrade(servants)
	TEST_ASSERT_EQUAL(hunter.points, servant_prices[2], "a refund returns what the last call cost")

	var/datum/hk47_upgrade/ghost = GLOB.hk47_upgrades["ghost_servant"]
	hunter.points = 10
	TEST_ASSERT(findtext(ghost.refusal(hunter), "[HK47_GHOST_SERVANT_MIN_CONTRACTS]"), "the ghost HK-50 is locked before the contracts: [ghost.refusal(hunter)]")
	hunter.contracts_done = HK47_GHOST_SERVANT_MIN_CONTRACTS
	TEST_ASSERT_NULL(ghost.refusal(hunter), "the ghost HK-50 opens after [HK47_GHOST_SERVANT_MIN_CONTRACTS] contracts")

/// Скованный или отключённый HK не покупает модули и не вызывает подкрепление: очки остаются на счету.
/datum/unit_test/hk47_upgrade_refused_when_restrained

/datum/unit_test/hk47_upgrade_refused_when_restrained/Run()
	var/datum/antagonist/hk47/hunter = allocate_plain_hk47()
	var/mob/living/carbon/human/droid = hunter.owner.current
	var/datum/hk47_upgrade/servants = GLOB.hk47_upgrades["servants"]
	hunter.points = 5
	var/obj/item/restraints/handcuffs/cuffs = allocate(/obj/item/restraints/handcuffs)
	droid.handcuffed = cuffs
	cuffs.forceMove(droid)
	droid.update_handcuffed()
	TEST_ASSERT(!hunter.buy_upgrade("servants"), "no HK-50 pair in handcuffs")
	TEST_ASSERT(!hunter.buy_upgrade("ghost_servant"), "no ghost HK-50 in handcuffs")
	TEST_ASSERT(findtext(servants.refusal(hunter), "обездвижено"), "the refusal explains the restraints: [servants.refusal(hunter)]")
	TEST_ASSERT_EQUAL(hunter.points, 5, "refused orders cost nothing")
	droid.handcuffed = null
	droid.update_handcuffed()
	droid.Paralyze(HK_EMP_HEAVY_STUN, ignore_canstun = TRUE)
	TEST_ASSERT(!hunter.buy_upgrade("plates"), "no modules while the chassis is knocked out")
	droid.SetParalyzed(0)
	TEST_ASSERT(hunter.buy_upgrade("plates"), "free again, the terminal sells")

/// Луч прицела снайпера дотягивается до края дальности прицела, а не гаснет после 10 клеток.
/datum/unit_test/hk47_sniper_beam_range

/datum/unit_test/hk47_sniper_beam_range/Run()
	var/mob/living/carbon/human/droid = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/obj/item/gun/energy/hk_rifle/rifle = allocate(/obj/item/gun/energy/hk_rifle)
	var/turf/far = locate(droid.x + HK47_SNIPER_AIM_RANGE, droid.y, droid.z)
	TEST_ASSERT_NOTNULL(far, "a turf at the edge of the aim range")
	var/datum/beam/beam = rifle.aim_beam(droid, far)
	TEST_ASSERT(!QDELETED(beam), "the aim beam holds at [HK47_SNIPER_AIM_RANGE] tiles")
	TEST_ASSERT(length(beam.elements), "the beam is drawn all the way")
	qdel(beam)

/// Маскировка прячет карту лицензии и розыск на СБ-HUD, снятие возвращает их и не трогает чужую маску имени и голос.
/datum/unit_test/hk47_disguise_hides_identity

/datum/unit_test/hk47_disguise_hides_identity/Run()
	var/datum/antagonist/hk47/hunter = allocate_plain_hk47()
	var/mob/living/carbon/human/droid = hunter.owner.current
	var/obj/item/card/id/hk47_license/license = hunter.issue_license(/obj/item/card/id/hk47_license)
	allocated += license
	hunter.file_security_record("Лицензированный подрядчик ЦК", "")
	allocate_hk47_records(hunter)
	hunter.note_security_record("Тест.", SEC_RECORD_STATUS_ARREST)
	var/image/wanted = droid.hud_list[WANTED_HUD]
	TEST_ASSERT_EQUAL(droid.wear_id, license, "the license sits in the ID slot")
	TEST_ASSERT_EQUAL(wanted.icon_state, "hudwanted", "the security HUD shows the arrest")
	var/datum/component/hk47_disguise/disguise = droid.AddComponent(/datum/component/hk47_disguise)
	TEST_ASSERT(disguise.enable(), "disguise on")
	TEST_ASSERT_NULL(droid.wear_id, "the license is stowed in the chassis")
	TEST_ASSERT_NULL(license.loc, "nobody can see or take the stowed license")
	TEST_ASSERT_NULL(wanted.icon_state, "the security HUD does not know the protocol droid")
	disguise.drop()
	TEST_ASSERT_EQUAL(droid.wear_id, license, "the license is back in the ID slot")
	TEST_ASSERT_EQUAL(wanted.icon_state, "hudwanted", "the arrest shows again")

	TEST_ASSERT(disguise.enable(), "disguise on again")
	droid.name_override = "чужая маска"
	droid.SetSpecialVoice("чужой голос")
	disguise.drop()
	TEST_ASSERT_EQUAL(droid.name_override, "чужая маска", "someone else's name mask stays")
	TEST_ASSERT_EQUAL(droid.GetSpecialVoice(), "чужой голос", "someone else's voice stays")
	droid.name_override = null
	droid.UnsetSpecialVoice()

/// Тайный HK без карты: после снятия маскировки отметка розыска возвращается на СБ-HUD.
/datum/unit_test/hk47_disguise_hud_without_id

/datum/unit_test/hk47_disguise_hud_without_id/Run()
	var/datum/antagonist/hk47/hunter = allocate_plain_hk47()
	var/mob/living/carbon/human/droid = hunter.owner.current
	hunter.file_security_record("Дроид-ассасин серии HK", "")
	allocate_hk47_records(hunter)
	hunter.note_security_record("Тест.", SEC_RECORD_STATUS_ARREST)
	TEST_ASSERT_NULL(droid.wear_id, "a covert HK carries no card")
	var/image/wanted = droid.hud_list[WANTED_HUD]
	TEST_ASSERT_EQUAL(wanted.icon_state, "hudwanted", "the security HUD shows the arrest")
	var/datum/component/hk47_disguise/disguise = droid.AddComponent(/datum/component/hk47_disguise)
	TEST_ASSERT(disguise.enable(), "disguise on")
	TEST_ASSERT_NULL(wanted.icon_state, "the protocol droid is not wanted")
	disguise.drop()
	TEST_ASSERT_EQUAL(wanted.icon_state, "hudwanted", "the arrest shows again without a card to put back")

/// Отчёт раунда: журнал контрактов с заказчиком, целью, исходом и очками, модули и способ эвакуации; перепрошитый HK остаётся строкой с хозяином.
/datum/unit_test/hk47_roundend_log

/datum/unit_test/hk47_roundend_log/Run()
	var/datum/antagonist/hk47/hunter = allocate_plain_hk47()
	var/mob/living/carbon/human/droid = hunter.owner.current
	droid.AddComponent(/datum/component/hk_loyalty)
	hunter.contract_history += list(list("contract" = "Синдикат: ликвидация - Test Target (Assistant)", "outcome" = HK_CONTRACT_DONE, "task" = /datum/hk_contract_task/kill, "points" = 2, "killed" = TRUE))
	hunter.contract_history += list(list("contract" = "Частное лицо: охрана - Test VIP (Captain)", "outcome" = HK_CONTRACT_FAILED, "task" = /datum/hk_contract_task/protect, "points" = 0, "killed" = FALSE))
	hunter.upgrades["plates"] = 1
	hunter.upgrades["servants"] = 2
	var/report = hunter.roundend_report()
	TEST_ASSERT(findtext(report, "Синдикат: ликвидация - Test Target (Assistant): выполнен (очков: 2)"), "the done contract with client, target and points")
	TEST_ASSERT(findtext(report, "Частное лицо: охрана - Test VIP (Captain): провален"), "the failed contract")
	TEST_ASSERT(findtext(report, "Бронеплиты") && findtext(report, "Пара HK-50 x2"), "the bought modules")
	TEST_ASSERT(findtext(report, "Эвакуация: не эвакуировался"), "no evacuation yet")
	hunter.extracted = TRUE
	TEST_ASSERT(findtext(hunter.roundend_report(), "Эвакуация: капсулой"), "the capsule evacuation")
	hunter.extracted = FALSE

	var/mob/living/carbon/human/surgeon = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	surgeon.mind_initialize()
	allocated += surgeon.mind
	var/datum/component/hk_loyalty/loyalty = droid.GetComponent(/datum/component/hk_loyalty)
	loyalty.set_master(surgeon.mind)
	TEST_ASSERT_NULL(droid.mind.has_antag_datum(/datum/antagonist/hk47), "reprogramming removes the role")
	var/datum/team/hk47_record/record
	for(var/datum/team/hk47_record/candidate in GLOB.antagonist_teams)
		if(candidate.droid_mind_ref?.resolve() == droid.mind)
			record = candidate
	TEST_ASSERT_NOTNULL(record, "the reprogrammed HK-47 stays in the round report")
	allocated += record
	var/record_report = record.roundend_report()
	TEST_ASSERT(findtext(record_report, surgeon.mind.name), "the record names the new master")
	TEST_ASSERT(findtext(record_report, "Test Target"), "the record keeps the contract log")
	TEST_ASSERT(!length(record.members), "the record makes nobody a team antagonist")
