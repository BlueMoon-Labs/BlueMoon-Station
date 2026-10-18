/datum/antagonist/hk47/contract_fixture
	var/list/test_announcements = list()
	var/list/test_vip_messages = list()
	var/test_space = FALSE
	/// Пеленгатор, который проверяется посреди сигнала эвакуации.
	var/datum/weakref/test_tracker_ref
	var/test_tracker_locked = FALSE
	var/test_beacon_shown = FALSE
	var/test_channel_result = TRUE

/datum/antagonist/hk47/contract_fixture/station_announce(text, title, sound)
	test_announcements += "[title] [text]"

/datum/antagonist/hk47/contract_fixture/notify_vip(mob/living/vip, text)
	test_vip_messages += "[vip.real_name]: [text]"

/datum/antagonist/hk47/contract_fixture/deliver_to_brig(atom/movable/cargo)
	cargo.forceMove(get_turf(owner.current))

/datum/antagonist/hk47/contract_fixture/borders_space(turf/spot)
	return test_space

/datum/antagonist/hk47/contract_fixture/channel_extraction(mob/living/droid)
	var/obj/item/pinpointer/hk47/tracker = test_tracker_ref?.resolve()
	test_tracker_locked = tracker && tracker.signal_source() == droid
	test_beacon_shown = !isnull(locate(/obj/effect/temp_visual/hk47_beacon) in get_turf(droid))
	return test_channel_result

/datum/antagonist/hk47/contract_fixture/call_extraction_pod(turf/landing)
	return make_extraction_pod()

/datum/unit_test/proc/allocate_hk47_records(datum/antagonist/hk47/antag)
	if(antag.record_id)
		allocated += list(GLOB.data_core.general_by_id[antag.record_id], GLOB.data_core.security_by_id[antag.record_id])

/datum/unit_test/proc/allocate_hk47_onlooker(mob/living/droid)
	var/mob/living/carbon/human/onlooker = allocate(/mob/living/carbon/human, locate(droid.x + 2, droid.y, droid.z))
	onlooker.mind_initialize()
	allocated += onlooker.mind
	return onlooker

/// Попадание снарядом, как у настоящего выстрела: стрелок и оружие, из которого он вылетел.
/datum/unit_test/proc/hk47_shoot(mob/living/shooter, mob/living/victim, atom/fired_from, damage = 0)
	var/obj/item/projectile/beam/laser/shot = allocate(/obj/item/projectile/beam/laser, get_turf(shooter))
	shot.firer = shooter
	shot.fired_from = fired_from || shooter
	shot.starting = get_turf(shooter)
	shot.damage = damage
	shot.nodamage = !damage
	victim.bullet_act(shot, BODY_ZONE_CHEST)

/datum/unit_test/proc/hk47_bring_near_death(mob/living/victim, margin = 10)
	victim.adjustOxyLoss(victim.maxHealth - HEALTH_THRESHOLD_DEAD - margin)

/// Тайная легенда: грязный первый контракт, станции ничего не объявлено, ни карты, ни записи в базе СБ.
/datum/unit_test/hk47_legend_covert

/datum/unit_test/hk47_legend_covert/Run()
	var/datum/antagonist/hk47/contract_fixture/hunter = allocate_hk47_hunter()
	var/mob/living/carbon/human/droid = hunter.owner.current
	droid.set_species(/datum/species/ipc/hk/hk47)
	hunter.add_crew(src, "Assistant")
	TEST_ASSERT_EQUAL(hunter.assign_legend(HK47_STATUS_COVERT), HK47_STATUS_COVERT, "covert legend")
	TEST_ASSERT_EQUAL(hunter.status, HK47_STATUS_COVERT, "covert status")
	TEST_ASSERT_NOTNULL(hunter.active_contract, "the first contract is accepted before landing")
	TEST_ASSERT(hunter.contract_is_dirty(hunter.active_contract), "a covert HK starts with dirty work")
	TEST_ASSERT(!length(hunter.test_announcements), "the station is told nothing")
	TEST_ASSERT(!istype(droid.wear_id, /obj/item/card/id/hk47_license), "no license")
	TEST_ASSERT_NULL(hunter.record_id, "no security record")
	TEST_ASSERT_EQUAL(hunter.points, HK47_COVERT_ADVANCE_POINTS, "the client pays an advance for the first module")

/// Лицензия ЦК: охота на засветившегося антага, объявление без имени цели, карта с номером и запись в базе СБ.
/datum/unit_test/hk47_legend_licensed

/datum/unit_test/hk47_legend_licensed/Run()
	var/datum/antagonist/hk47/contract_fixture/hunter = allocate_hk47_hunter()
	var/mob/living/carbon/human/droid = hunter.owner.current
	droid.set_species(/datum/species/ipc/hk/hk47)
	var/datum/mind/traitor = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_KILL)
	mark_hk47_antag(traitor)
	traitor.hk47_kill_time = world.time
	TEST_ASSERT_EQUAL(hunter.assign_legend(HK47_STATUS_LICENSED), HK47_STATUS_LICENSED, "licensed legend")
	allocate_hk47_records(hunter)
	var/datum/hk_contract/contract = hunter.active_contract
	TEST_ASSERT_EQUAL(contract?.client_id, HK_CLIENT_CENTCOM, "CentCom pays for the first contract")
	TEST_ASSERT(contract.is_hunt(), "CentCom hunts the exposed antagonist")
	TEST_ASSERT(!hunter.contract_is_dirty(contract), "CentCom work is clean")
	TEST_ASSERT_EQUAL(length(hunter.test_announcements), 1, "one CentCom announcement")
	var/announcement = hunter.test_announcements[1]
	TEST_ASSERT(!findtext(announcement, traitor.current.real_name), "the announcement hides the target")
	var/obj/item/card/id/hk47_license/license = droid.wear_id
	TEST_ASSERT(istype(license) && !istype(license, /obj/item/card/id/hk47_license/bodyguard), "CentCom license in the ID slot")
	TEST_ASSERT(findtext(announcement, license.license_number), "the announcement gives the license number")
	TEST_ASSERT(findtext(jointext(license.examine(droid), " "), "действительна"), "a fresh license is valid")
	TEST_ASSERT(!findtext(jointext(license.examine(droid), " "), "счёт") && !findtext(jointext(license.examine(droid), " "), "аккаунт"), "the license says nothing about bank accounts")
	var/datum/data/record/record = GLOB.data_core.security_by_id[hunter.record_id]
	TEST_ASSERT_NOTNULL(record, "security record")
	TEST_ASSERT_EQUAL(record.fields["name"], droid.real_name, "the record is filed under the droid name")
	TEST_ASSERT(findtext(record.fields["notes"], license.license_number), "the record carries the license number")
	TEST_ASSERT_EQUAL(record.fields["criminal"], SEC_RECORD_STATUS_NONE, "a licensed HK is not wanted")
	TEST_ASSERT_EQUAL(hunter.points, 0, "a license is the cover, no advance")

/// Без засветившегося антага ЦК нанимает охрану главы; без главы и антага легенда сводится к тайной.
/datum/unit_test/hk47_legend_fallback

/datum/unit_test/hk47_legend_fallback/Run()
	var/datum/antagonist/hk47/contract_fixture/lonely = allocate_hk47_hunter()
	lonely.add_crew(src, "Assistant", ANTAG_OPT_IN_KILL)
	TEST_ASSERT_EQUAL(lonely.assign_legend(HK47_STATUS_LICENSED), HK47_STATUS_COVERT, "no antagonist and no head: no license")
	TEST_ASSERT(!length(lonely.test_announcements), "the fallback announces nothing")
	TEST_ASSERT_NULL(lonely.record_id, "the fallback files no record")
	var/datum/antagonist/hk47/contract_fixture/guard = allocate_hk47_hunter()
	var/datum/mind/captain = guard.add_crew(src, "Captain", ANTAG_OPT_IN_NOT_TARGET)
	TEST_ASSERT_EQUAL(guard.assign_legend(HK47_STATUS_LICENSED), HK47_STATUS_LICENSED, "a head keeps the license")
	allocate_hk47_records(guard)
	TEST_ASSERT(istype(guard.active_contract?.task, /datum/hk_contract_task/protect/head), "CentCom guards the head")
	TEST_ASSERT(!findtext(guard.test_announcements[1], captain.current.real_name), "the announcement hides the guarded head")

/// Телохранитель: охрана VIP, объявление без имени VIP, личное сообщение VIP, карта телохранителя и путь статуса в отчёте.
/datum/unit_test/hk47_legend_bodyguard

/datum/unit_test/hk47_legend_bodyguard/Run()
	var/datum/antagonist/hk47/contract_fixture/hunter = allocate_hk47_hunter()
	var/mob/living/carbon/human/droid = hunter.owner.current
	droid.set_species(/datum/species/ipc/hk/hk47)
	var/datum/mind/vip = hunter.add_crew(src, "Scientist", ANTAG_OPT_IN_NOT_TARGET)
	TEST_ASSERT_EQUAL(hunter.assign_legend(HK47_STATUS_BODYGUARD), HK47_STATUS_BODYGUARD, "bodyguard legend")
	allocate_hk47_records(hunter)
	TEST_ASSERT(istype(hunter.active_contract?.task, /datum/hk_contract_task/protect), "the first job is protection")
	TEST_ASSERT_EQUAL(hunter.active_contract.target_mind(), vip, "the VIP is the protected one")
	TEST_ASSERT_EQUAL(length(hunter.test_announcements), 1, "one registry announcement")
	TEST_ASSERT(!findtext(hunter.test_announcements[1], vip.current.real_name), "the announcement hides the VIP")
	TEST_ASSERT_EQUAL(length(hunter.test_vip_messages), 1, "the VIP is told in private")
	TEST_ASSERT_EQUAL(findtext(hunter.test_vip_messages[1], vip.current.real_name), 1, "the message goes to the VIP")
	TEST_ASSERT(findtext(hunter.test_vip_messages[1], HK47_NAME), "the message names the bodyguard")
	TEST_ASSERT(findtext(hunter.test_vip_messages[1], "поручиться"), "a bodyguard VIP may vouch for the licensed HK")
	TEST_ASSERT(istype(droid.wear_id, /obj/item/card/id/hk47_license/bodyguard), "bodyguard license")
	TEST_ASSERT_NOTNULL(GLOB.data_core.security_by_id[hunter.record_id], "security record")
	TEST_ASSERT(findtext(hunter.roundend_report(), hk47_status_name(HK47_STATUS_BODYGUARD)), "the report shows the legend")

/// Охраняемый обычного контракта охраны тоже получает одно личное сообщение, но за тайного HK поручиться не может.
/datum/unit_test/hk47_protect_vip_message

/datum/unit_test/hk47_protect_vip_message/Run()
	var/datum/antagonist/hk47/contract_fixture/hunter = allocate_hk47_hunter()
	var/datum/mind/vip = hunter.add_crew(src, "Scientist", ANTAG_OPT_IN_NOT_TARGET)
	TEST_ASSERT(hunter.accept(hunter.make_contract(HK_CLIENT_PRIVATE, /datum/hk_contract_task/protect, null, vip)), "protection accepted")
	TEST_ASSERT_EQUAL(length(hunter.test_vip_messages), 1, "the VIP is told once")
	var/message = hunter.test_vip_messages[1]
	TEST_ASSERT_EQUAL(findtext(message, vip.current.real_name), 1, "the message goes to the VIP")
	TEST_ASSERT(findtext(message, "Анонимный доброжелатель"), "the payer stays anonymous")
	TEST_ASSERT(!findtext(message, "поручиться"), "nobody vouches for a covert HK")

/// Грязный контракт без свидетелей станция не замечает; со свидетелями - объявление без имён, «вне закона» и арест в базе СБ.
/datum/unit_test/hk47_escalation_on_witnesses

/datum/unit_test/hk47_escalation_on_witnesses/Run()
	var/datum/antagonist/hk47/contract_fixture/hunter = allocate_hk47_hunter()
	var/mob/living/droid = hunter.owner.current
	var/datum/mind/quiet = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_KILL)
	hunter.accept(hunter.make_contract(HK_CLIENT_SYNDICATE, /datum/hk_contract_task/kill, null, quiet))
	TEST_ASSERT(hunter.complete(hunter.active_contract), "quiet kill done")
	TEST_ASSERT_EQUAL(hunter.reveals, 0, "an unseen dirty contract is not a reveal")
	TEST_ASSERT_EQUAL(hunter.status, HK47_STATUS_COVERT, "status kept")
	TEST_ASSERT(!length(hunter.test_announcements), "nothing announced")
	var/datum/mind/loud = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_KILL)
	allocate_hk47_onlooker(droid)
	hunter.accept(hunter.make_contract(HK_CLIENT_CORP, /datum/hk_contract_task/capture, null, loud))
	TEST_ASSERT(hunter.complete(hunter.active_contract), "seen capture done")
	allocate_hk47_records(hunter)
	TEST_ASSERT_EQUAL(hunter.reveals, 1, "a seen dirty contract is a reveal")
	TEST_ASSERT_EQUAL(hunter.status, HK47_STATUS_OUTLAW, "revealed HK is an outlaw")
	TEST_ASSERT_EQUAL(length(hunter.test_announcements), 1, "the intercept is announced")
	var/announcement = hunter.test_announcements[1]
	TEST_ASSERT(!findtext(announcement, quiet.current.real_name) && !findtext(announcement, loud.current.real_name), "the intercept names no targets")
	var/datum/data/record/record = GLOB.data_core.security_by_id[hunter.record_id]
	TEST_ASSERT_EQUAL(record?.fields["criminal"], SEC_RECORD_STATUS_ARREST, "security is told to arrest")

/// Раскрытие после истёкшей лицензии: «вне закона», карта «ОТОЗВАНА», арест в той же записи, путь статуса в отчёте.
/datum/unit_test/hk47_reveal_revokes_license

/datum/unit_test/hk47_reveal_revokes_license/Run()
	var/datum/antagonist/hk47/contract_fixture/hunter = allocate_hk47_hunter()
	var/mob/living/carbon/human/droid = hunter.owner.current
	droid.set_species(/datum/species/ipc/hk/hk47)
	hunter.add_crew(src, "Captain", ANTAG_OPT_IN_NOT_TARGET)
	var/datum/mind/victim = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_KILL)
	hunter.assign_legend(HK47_STATUS_LICENSED)
	allocate_hk47_records(hunter)
	var/licensed_record = hunter.record_id
	hunter.complete(hunter.active_contract)
	allocate_hk47_onlooker(droid)
	hunter.accept(hunter.make_contract(HK_CLIENT_SYNDICATE, /datum/hk_contract_task/kill, null, victim))
	hunter.complete(hunter.active_contract)
	TEST_ASSERT_EQUAL(hunter.status, HK47_STATUS_OUTLAW, "the reveal outlaws an HK with an expired license")
	var/obj/item/card/id/hk47_license/license = droid.wear_id
	TEST_ASSERT(license.revoked, "the license is revoked")
	TEST_ASSERT(findtext(jointext(license.examine(droid), " "), "ОТОЗВАНА"), "the card shows the revocation")
	TEST_ASSERT_EQUAL(hunter.record_id, licensed_record, "the same record is marked")
	var/datum/data/record/record = GLOB.data_core.security_by_id[hunter.record_id]
	TEST_ASSERT_EQUAL(record.fields["criminal"], SEC_RECORD_STATUS_ARREST, "the record says arrest")
	var/expected_path = "[hk47_status_name(HK47_STATUS_LICENSED)] -> [hk47_status_name(HK47_STATUS_EXPIRED)] -> [hk47_status_name(HK47_STATUS_OUTLAW)]"
	TEST_ASSERT(findtext(hunter.roundend_report(), expected_path), "the report shows the status path")

/// Охрана и работа на ЦК не двигают эскалацию даже при свидетелях.
/datum/unit_test/hk47_clean_contracts_stay_quiet

/datum/unit_test/hk47_clean_contracts_stay_quiet/Run()
	var/datum/antagonist/hk47/contract_fixture/hunter = allocate_hk47_hunter()
	var/mob/living/droid = hunter.owner.current
	var/datum/mind/vip = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_NOT_TARGET)
	var/datum/mind/traitor = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_KILL)
	mark_hk47_antag(traitor)
	traitor.hk47_kill_time = world.time
	allocate_hk47_onlooker(droid)
	TEST_ASSERT(length(hunter.witnesses()), "the work is seen")
	hunter.accept(hunter.make_contract(HK_CLIENT_PRIVATE, /datum/hk_contract_task/protect, null, vip))
	hunter.complete(hunter.active_contract)
	hunter.accept(hunter.make_contract(HK_CLIENT_CENTCOM, /datum/hk_contract_task/hunt, null, traitor))
	hunter.complete(hunter.active_contract)
	TEST_ASSERT_EQUAL(hunter.contracts_done, 2, "both contracts done")
	TEST_ASSERT_EQUAL(hunter.reveals, 0, "clean work never reveals")
	TEST_ASSERT_EQUAL(hunter.status, HK47_STATUS_COVERT, "status kept")
	TEST_ASSERT(!length(hunter.test_announcements), "nothing announced")

/// Выстрел HK из своего оружия по члену экипажа и его смерть отзывают лицензию; цель контракта - нет. Имя погибшего знают HK и СБ, но не объявление.
/datum/unit_test/hk47_license_revoked_by_kill

/datum/unit_test/hk47_license_revoked_by_kill/Run()
	var/datum/antagonist/hk47/contract_fixture/hunter = allocate_hk47_hunter()
	var/mob/living/carbon/human/droid = hunter.owner.current
	droid.set_species(/datum/species/ipc/hk/hk47)
	var/datum/mind/traitor = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_KILL)
	mark_hk47_antag(traitor)
	traitor.hk47_kill_time = world.time
	var/datum/mind/bystander = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_KILL)
	hunter.assign_legend(HK47_STATUS_LICENSED)
	allocate_hk47_records(hunter)
	var/obj/item/gun/energy/laser/rifle = allocate(/obj/item/gun/energy/laser)
	droid.put_in_hands(rifle)
	hk47_shoot(droid, traitor.current, rifle)
	traitor.current.death()
	TEST_ASSERT_EQUAL(hunter.status, HK47_STATUS_LICENSED, "killing the contract target keeps the license")
	var/mob/living/carbon/human/victim = bystander.current
	hk47_bring_near_death(victim)
	hk47_shoot(droid, victim, rifle, 30)
	TEST_ASSERT_EQUAL(victim.stat, DEAD, "the shot kills the bystander")
	TEST_ASSERT_EQUAL(hunter.status, HK47_STATUS_OUTLAW, "a lethal HK shot at a bystander revokes the license")
	var/obj/item/card/id/hk47_license/license = droid.wear_id
	TEST_ASSERT(license.revoked, "the card is revoked")
	var/datum/data/record/record = GLOB.data_core.security_by_id[hunter.record_id]
	TEST_ASSERT_EQUAL(record?.fields["criminal"], SEC_RECORD_STATUS_ARREST, "the record says arrest")
	TEST_ASSERT(findtext(record.fields["notes"], victim.real_name), "security knows whose death revoked the license")
	TEST_ASSERT_EQUAL(length(hunter.test_announcements), 2, "the revocation is announced")
	TEST_ASSERT(!findtext(hunter.test_announcements[2], victim.real_name), "the revocation names no victim")
	TEST_ASSERT_EQUAL(hunter.reveals, 0, "a revocation is not a reveal")

/// Старый удар HK и чужое убийство, самооборона HK и охраняемого, убийство разыскиваемого лицензию не отзывают.
/datum/unit_test/hk47_license_kill_excuses

/datum/unit_test/hk47_license_kill_excuses/Run()
	var/datum/antagonist/hk47/contract_fixture/hunter = allocate_hk47_hunter()
	var/mob/living/carbon/human/droid = hunter.owner.current
	var/datum/mind/captain = hunter.add_crew(src, "Captain", ANTAG_OPT_IN_NOT_TARGET)
	var/datum/mind/grudge = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_KILL)
	var/datum/mind/other_killer = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_KILL)
	var/datum/mind/brawler = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_KILL)
	var/datum/mind/vip_attacker = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_KILL)
	var/datum/mind/wanted = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_KILL)
	hunter.assign_legend(HK47_STATUS_LICENSED)
	allocate_hk47_records(hunter)
	TEST_ASSERT_EQUAL(hunter.active_contract?.target_mind(), captain, "CentCom guards the captain")
	grudge.current.set_last_attacker(droid)
	TEST_ASSERT(hunter.recent_side_hit(grudge.current), "an HK punch is noted")
	hunter.side_hits[WEAKREF(grudge.current)] = world.time - HK47_HIT_MEMORY - 1
	grudge.current.set_last_attacker(other_killer.current)
	grudge.current.death()
	TEST_ASSERT_EQUAL(hunter.status, HK47_STATUS_LICENSED, "an old HK punch does not make someone else's kill HK's")
	droid.set_last_attacker(brawler.current)
	brawler.current.set_last_attacker(droid)
	brawler.current.death()
	TEST_ASSERT_EQUAL(hunter.status, HK47_STATUS_LICENSED, "killing someone who just attacked HK is self-defense")
	captain.current.set_last_attacker(vip_attacker.current)
	vip_attacker.current.set_last_attacker(droid)
	vip_attacker.current.death()
	TEST_ASSERT_EQUAL(hunter.status, HK47_STATUS_LICENSED, "killing someone who just attacked the guarded head is self-defense")
	var/datum/data/record/record = allocate(/datum/data/record)
	var/wanted_name = wanted.current.real_name
	record.fields["name"] = wanted_name
	record.fields["criminal"] = SEC_RECORD_STATUS_ARREST
	GLOB.data_core.security_by_name[wanted_name] = record
	wanted.current.set_last_attacker(droid)
	wanted.current.death()
	GLOB.data_core.security_by_name -= wanted_name
	TEST_ASSERT_EQUAL(hunter.status, HK47_STATUS_LICENSED, "killing a wanted crew member keeps the license")

/// Второе раскрытие: пеленгатор в бриг и приоритетный заказ на ядро; сигнал глушат маскировка и смерть, ядро выпадает из мёртвого HK.
/datum/unit_test/hk47_second_reveal

/datum/unit_test/hk47_second_reveal/Run()
	var/datum/antagonist/hk47/contract_fixture/hunter = allocate_hk47_hunter()
	var/mob/living/droid = hunter.owner.current
	var/list/bounties_before = GLOB.bounties_list.Copy()
	hunter.escalate()
	allocate_hk47_records(hunter)
	TEST_ASSERT_NULL(locate(/obj/item/pinpointer/hk47) in get_turf(droid), "no tracker after the first reveal")
	hunter.escalate()
	var/datum/bounty/item/hk47_core/bounty = locate() in GLOB.bounties_list
	GLOB.bounties_list = bounties_before
	TEST_ASSERT_NOTNULL(bounty, "cargo gets the core bounty")
	TEST_ASSERT(bounty.high_priority, "the core bounty is high priority")
	TEST_ASSERT_EQUAL(length(hunter.test_announcements), HK47_TRACKER_REVEAL, "both reveals are announced")
	var/obj/item/pinpointer/hk47/tracker = locate() in get_turf(droid)
	TEST_ASSERT_NOTNULL(tracker, "the tracker is delivered")
	TEST_ASSERT_EQUAL(tracker.signal_source(), droid, "the tracker locks on HK-47")
	ADD_TRAIT(droid, TRAIT_HK47_DISGUISED, TRAIT_GENERIC)
	TEST_ASSERT_NULL(tracker.signal_source(), "a masked signal is lost")
	TEST_ASSERT(findtext(jointext(tracker.examine(droid), " "), "потерян"), "examine says the signal is lost")
	REMOVE_TRAIT(droid, TRAIT_HK47_DISGUISED, TRAIT_GENERIC)
	droid.death()
	TEST_ASSERT_NULL(tracker.signal_source(), "a dead droid gives no signal")
	var/obj/item/hk47_core/core = locate() in get_turf(droid)
	TEST_ASSERT_NOTNULL(core, "the core drops from the dead droid")
	TEST_ASSERT(bounty.applies_to(core), "the bounty takes the core")

/// Эвакуация только после трёх контрактов и у клетки с космосом; посадка HK-47 в капсулу засчитывает цель.
/datum/unit_test/hk47_extraction

/datum/unit_test/hk47_extraction/Run()
	var/datum/antagonist/hk47/contract_fixture/hunter = allocate_hk47_hunter()
	var/mob/living/droid = hunter.owner.current
	var/datum/objective/hk47_extract/extract = locate() in hunter.objectives
	hunter.test_space = TRUE
	TEST_ASSERT(!hunter.request_extraction(), "no extraction before three contracts")
	hunter.contracts_done = HK47_CONTRACTS_TO_WIN
	hunter.test_space = FALSE
	TEST_ASSERT(!hunter.request_extraction(), "the capsule lands only next to open space")
	hunter.test_space = TRUE
	TEST_ASSERT(hunter.request_extraction(), "extraction called")
	TEST_ASSERT(!length(hunter.test_announcements), "a covert HK leaves quietly")
	TEST_ASSERT(!hunter.test_beacon_shown, "a covert HK shows no landing mark")
	var/obj/structure/closet/supplypod/hk47/extraction/pod = hunter.extraction_pod_ref?.resolve()
	TEST_ASSERT_NOTNULL(pod, "the capsule is on its way")
	allocated += pod
	TEST_ASSERT(!hunter.request_extraction(), "one capsule at a time")
	TEST_ASSERT(!extract.check_completion(), "not extracted before boarding")
	var/mob/living/carbon/human/stowaway = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	TEST_ASSERT(!pod.insertion_allowed(stowaway), "the capsule takes only HK-47")
	TEST_ASSERT(pod.insert(droid, pod), "HK-47 boards")
	TEST_ASSERT(extract.check_completion(), "boarding completes the extraction")
	TEST_ASSERT(hunter.owner.force_escaped, "the droid counts as escaped")
	pod.handleReturnAfterDeparting()
	var/turf/dock = get_turf(droid)
	TEST_ASSERT(istype(dock?.loc, /area/centcom/supplypod/podStorage), "the capsule docks in the CentCom pod bay with HK-47 inside, never in nullspace")
	droid.forceMove(run_loc_floor_bottom_left)

/// Перепрошивка снимает роль HK-47, гасит контракт и снимает розыск в базе СБ; хозяином остаётся перепрошивший.
/datum/unit_test/hk47_reprogram

/datum/unit_test/hk47_reprogram/Run()
	var/datum/antagonist/hk47/contract_fixture/hunter = allocate_hk47_hunter()
	var/mob/living/droid = hunter.owner.current
	var/datum/mind/droid_mind = hunter.owner
	var/datum/mind/target = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_KILL)
	var/datum/hk_contract/contract = hunter.make_contract(HK_CLIENT_SYNDICATE, /datum/hk_contract_task/kill, null, target)
	hunter.accept(contract)
	hunter.escalate()
	allocate_hk47_records(hunter)
	var/datum/data/record/record = GLOB.data_core.security_by_id[hunter.record_id]
	TEST_ASSERT_EQUAL(record?.fields["criminal"], SEC_RECORD_STATUS_ARREST, "the revealed HK is wanted")
	var/mob/living/carbon/human/surgeon = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	surgeon.mind_initialize()
	allocated += surgeon.mind
	var/datum/component/hk_loyalty/loyalty = droid.AddComponent(/datum/component/hk_loyalty)
	loyalty.set_master(surgeon.mind)
	TEST_ASSERT_NULL(droid_mind.has_antag_datum(/datum/antagonist/hk47), "reprogramming removes the role")
	TEST_ASSERT(QDELETED(contract), "the contract stops")
	TEST_ASSERT_NULL(droid_mind.special_role, "no special role left")
	TEST_ASSERT_EQUAL(loyalty.get_master(), surgeon.mind, "the surgeon is the new master")
	TEST_ASSERT_EQUAL(record.fields["criminal"], SEC_RECORD_STATUS_NONE, "reprogramming lifts the arrest order")
	var/datum/team/hk47_record/roundend_record
	for(var/datum/team/hk47_record/candidate in GLOB.antagonist_teams)
		if(candidate.droid_mind_ref?.resolve() == droid_mind)
			roundend_record = candidate
	TEST_ASSERT_NOTNULL(roundend_record, "the round report keeps the reprogrammed HK")
	allocated += roundend_record
	var/details = jointext(roundend_record.details, " ")
	TEST_ASSERT(findtext(details, "снят перепрошивкой"), "the open contract is closed by the reprogramming: [details]")
	TEST_ASSERT(!findtext(details, "не закрыт к концу смены"), "the report does not wait for the end of the shift")

/// Шасси HK-47 открывает шлюзы техтоннелей без карты, двери отделов - нет; после перепрошивки код доступа пропадает.
/datum/unit_test/hk47_tunnel_access

/datum/unit_test/hk47_tunnel_access/Run()
	var/datum/antagonist/hk47/contract_fixture/hunter = allocate_hk47_hunter()
	var/mob/living/droid = hunter.owner.current
	var/obj/machinery/door/airlock/maintenance/tunnel = allocate(/obj/machinery/door/airlock/maintenance, run_loc_floor_top_right)
	tunnel.req_access = list()
	tunnel.req_one_access = list(ACCESS_MAINT_TUNNELS, ACCESS_ENGINE)
	var/obj/machinery/door/airlock/security/brig = allocate(/obj/machinery/door/airlock/security, locate(run_loc_floor_top_right.x - 1, run_loc_floor_top_right.y, run_loc_floor_top_right.z))
	brig.req_access = list(ACCESS_SECURITY)
	brig.req_one_access = list()
	var/mob/living/carbon/human/stranger = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	TEST_ASSERT(!tunnel.allowed(stranger), "a maintenance airlock needs access")
	TEST_ASSERT(tunnel.allowed(droid), "HK-47 opens maintenance airlocks without a card")
	TEST_ASSERT(!brig.allowed(droid), "department doors stay shut")
	var/mob/living/carbon/human/surgeon = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	surgeon.mind_initialize()
	allocated += surgeon.mind
	var/datum/component/hk_loyalty/loyalty = droid.AddComponent(/datum/component/hk_loyalty)
	loyalty.set_master(surgeon.mind)
	TEST_ASSERT(!tunnel.allowed(droid), "the reprogrammed HK loses the tunnel code with the role")

/// Посылка везёт HK-47 в ящике внутри капсулы и открывается изнутри; крушение кладёт его на пол оглушённым, с обломками и без пробоины.
/datum/unit_test/hk47_arrival_methods

/datum/unit_test/hk47_arrival_methods/Run()
	var/datum/round_event/ghost_role/hk47/event = allocate(/datum/round_event/ghost_role/hk47, FALSE)
	SSdirector.running -= event
	var/mob/living/carbon/human/courier = event.create_hk47(null)
	allocated += courier
	var/obj/structure/closet/crate/hk47_parcel/parcel = event.arrive_parcel(courier, run_loc_floor_bottom_left, HK47_STATUS_LICENSED)
	var/obj/effect/pod_landingzone/zone = locate() in run_loc_floor_bottom_left
	if(zone)
		allocated += list(zone.helper, zone)
	allocated += list(parcel?.loc, parcel)
	TEST_ASSERT_EQUAL(courier.loc, parcel, "HK-47 rides inside the parcel")
	var/turf/transit_turf = get_turf(courier)
	TEST_ASSERT(istype(transit_turf?.loc, /area/centcom/supplypod/podStorage), "the parcel waits in the CentCom pod bay, never in nullspace")
	TEST_ASSERT(istype(parcel.loc, /obj/structure/closet/supplypod/hk47/official), "a CentCom parcel comes in an official capsule")
	TEST_ASSERT_EQUAL(zone?.pod, parcel.loc, "the capsule targets the landing turf")
	parcel.forceMove(locate(run_loc_floor_bottom_left.x + 1, run_loc_floor_bottom_left.y + 1, run_loc_floor_bottom_left.z))
	parcel.relaymove(courier, NORTH)
	TEST_ASSERT(parcel.opened, "HK-47 opens the parcel from inside")
	var/mob/living/carbon/human/crasher = event.create_hk47(null)
	allocated += crasher
	var/turf/site = run_loc_floor_top_right
	var/obj/effect/temp_visual/hk47_crash_fall/fall = event.arrive_crash(crasher, site)
	TEST_ASSERT_EQUAL(crasher.loc, fall, "HK-47 rides the falling wreck, not nullspace")
	var/obj/effect/temp_visual/hk47_crash_shadow/shadow = locate() in site
	TEST_ASSERT_NOTNULL(shadow, "a shadow marks the crash site")
	var/obj/effect/temp_visual/hk47_crash_trail/trail = locate() in site
	TEST_ASSERT_NOTNULL(trail, "the wreck leaves a smoke trail")
	TEST_ASSERT(trail.pixel_x != 0 && trail.pixel_z > 0, "the trail starts high and to the side: the wreck comes in at an angle")
	qdel(fall)
	TEST_ASSERT(QDELETED(shadow), "the shadow goes with the impact")
	TEST_ASSERT_EQUAL(crasher.loc, site, "the crash puts HK-47 on the floor")
	TEST_ASSERT(crasher.IsParalyzed(), "the crash stuns HK-47")
	TEST_ASSERT(isfloorturf(site), "the crash breaches nothing")
	TEST_ASSERT_NOTNULL(locate(/obj/effect/decal/cleanable/robot_debris) in site, "the crash leaves wreckage")

/// Лицензия телохранителя истекает с концом охраны: карта «ИСТЕКЛА», пометка в базе СБ без розыска, объявление без имени VIP; отзывать потом нечего.
/datum/unit_test/hk47_license_expires

/datum/unit_test/hk47_license_expires/Run()
	var/datum/antagonist/hk47/contract_fixture/hunter = allocate_hk47_hunter()
	var/mob/living/carbon/human/droid = hunter.owner.current
	droid.set_species(/datum/species/ipc/hk/hk47)
	var/datum/mind/vip = hunter.add_crew(src, "Scientist", ANTAG_OPT_IN_NOT_TARGET)
	var/datum/mind/bystander = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_KILL)
	hunter.assign_legend(HK47_STATUS_BODYGUARD)
	allocate_hk47_records(hunter)
	hunter.active_contract.protect_time_up()
	TEST_ASSERT_EQUAL(hunter.status, HK47_STATUS_EXPIRED, "the license ends with the protection")
	TEST_ASSERT(!hunter.is_licensed(), "an expired license protects nothing")
	var/obj/item/card/id/hk47_license/license = droid.wear_id
	var/card_text = jointext(license.examine(droid), " ")
	TEST_ASSERT(findtext(card_text, "ИСТЕКЛА") && !findtext(card_text, "действительна"), "the card shows the expiry")
	var/datum/data/record/record = GLOB.data_core.security_by_id[hunter.record_id]
	TEST_ASSERT_EQUAL(record.fields["criminal"], SEC_RECORD_STATUS_NONE, "an expired license is not a crime")
	TEST_ASSERT(findtext(record.fields["notes"], "истекла"), "security sees the expiry")
	TEST_ASSERT_EQUAL(length(hunter.test_announcements), 2, "the registry announces the end of the contract")
	TEST_ASSERT(!findtext(hunter.test_announcements[2], vip.current.real_name), "the announcement hides the VIP")
	bystander.current.set_last_attacker(droid)
	bystander.current.death()
	TEST_ASSERT_EQUAL(hunter.status, HK47_STATUS_EXPIRED, "nothing left to revoke")
	var/expected_path = "[hk47_status_name(HK47_STATUS_BODYGUARD)] -> [hk47_status_name(HK47_STATUS_EXPIRED)]"
	TEST_ASSERT(findtext(hunter.roundend_report(), expected_path), "the report shows the expiry")
	var/datum/antagonist/hk47/contract_fixture/contractor = allocate_hk47_hunter()
	contractor.add_crew(src, "Captain", ANTAG_OPT_IN_NOT_TARGET)
	contractor.assign_legend(HK47_STATUS_LICENSED)
	allocate_hk47_records(contractor)
	contractor.fail(contractor.active_contract, "test")
	TEST_ASSERT_EQUAL(contractor.status, HK47_STATUS_EXPIRED, "a CentCom license lasts only as long as the CentCom contract")

/// Третье раскрытие: приказ на уничтожение в базе СБ и запертый ящик с ионной винтовкой и ЭМИ-гранатами в бриг.
/datum/unit_test/hk47_third_reveal

/datum/unit_test/hk47_third_reveal/Run()
	var/datum/antagonist/hk47/contract_fixture/hunter = allocate_hk47_hunter()
	var/mob/living/droid = hunter.owner.current
	var/list/bounties_before = GLOB.bounties_list.Copy()
	for(var/reveal in 1 to HK47_EXECUTE_REVEAL)
		hunter.escalate()
	GLOB.bounties_list = bounties_before
	allocate_hk47_records(hunter)
	var/obj/item/pinpointer/hk47/tracker = locate() in get_turf(droid)
	if(tracker)
		allocated += tracker
	var/obj/structure/closet/crate/secure/weapon/hk47_countermeasures/crate = locate() in get_turf(droid)
	TEST_ASSERT_NOTNULL(crate, "the countermeasures crate is delivered")
	allocated += crate.contents.Copy()
	allocated += crate
	TEST_ASSERT(crate.locked, "the crate is locked for security")
	TEST_ASSERT_NOTNULL(locate(/obj/item/gun/energy/ionrifle) in crate, "the crate holds an ion rifle")
	TEST_ASSERT_NOTNULL(locate(/obj/item/storage/box/emps) in crate, "the crate holds EMP grenades")
	var/datum/data/record/record = GLOB.data_core.security_by_id[hunter.record_id]
	TEST_ASSERT_EQUAL(record?.fields["criminal"], SEC_RECORD_STATUS_EXECUTE, "security is ordered to destroy HK")
	TEST_ASSERT_EQUAL(length(hunter.test_announcements), HK47_EXECUTE_REVEAL, "every reveal is announced")
	var/list/station = hunter.terminal_status_data()
	TEST_ASSERT_EQUAL(station["threat"], HK47_EXECUTE_REVEAL, "the terminal shows the last escalation step")
	TEST_ASSERT_EQUAL(station["threat_max"], HK47_EXECUTE_REVEAL, "the terminal scale ends at the last step")

/// Финал раскрытого HK: перехват маяка с отсеком, метка посадки и пеленгатор сквозь маскировку; после эвакуации новых предложений нет.
/datum/unit_test/hk47_extraction_scene

/datum/unit_test/hk47_extraction_scene/Run()
	var/datum/antagonist/hk47/contract_fixture/hunter = allocate_hk47_hunter()
	var/mob/living/droid = hunter.owner.current
	hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_KILL)
	var/list/bounties_before = GLOB.bounties_list.Copy()
	hunter.escalate()
	hunter.escalate()
	GLOB.bounties_list = bounties_before
	allocate_hk47_records(hunter)
	var/obj/item/pinpointer/hk47/tracker = locate() in get_turf(droid)
	TEST_ASSERT_NOTNULL(tracker, "the tracker is in the brig")
	allocated += tracker
	ADD_TRAIT(droid, TRAIT_HK47_DISGUISED, TRAIT_GENERIC)
	TEST_ASSERT_NULL(tracker.signal_source(), "a disguise hides HK before the finale")
	hunter.contracts_done = HK47_CONTRACTS_TO_WIN
	hunter.test_space = TRUE
	hunter.test_tracker_ref = WEAKREF(tracker)
	var/announced = length(hunter.test_announcements)
	TEST_ASSERT(hunter.request_extraction(), "extraction called")
	REMOVE_TRAIT(droid, TRAIT_HK47_DISGUISED, TRAIT_GENERIC)
	TEST_ASSERT(hunter.test_tracker_locked, "the tracker catches the beacon through the disguise")
	TEST_ASSERT(hunter.test_beacon_shown, "the landing mark is visible during the signal")
	TEST_ASSERT_NULL(locate(/obj/effect/temp_visual/hk47_beacon) in get_turf(droid), "the mark goes away with the signal")
	TEST_ASSERT_EQUAL(length(hunter.test_announcements), announced + 1, "the beacon is intercepted")
	TEST_ASSERT(findtext(hunter.test_announcements[length(hunter.test_announcements)], get_area_name(droid, TRUE)), "the intercept names the area")
	var/obj/structure/closet/supplypod/hk47/extraction/pod = hunter.extraction_pod_ref?.resolve()
	TEST_ASSERT_NOTNULL(pod, "the capsule is on its way")
	allocated += pod
	TEST_ASSERT(pod.insert(droid, pod), "HK-47 boards")
	TEST_ASSERT(hunter.extracted, "extraction done")
	TEST_ASSERT(!length(hunter.ensure_offers()), "no new offers after extraction")
	droid.forceMove(run_loc_floor_bottom_left)

/// HK, чья лицензия закончилась без раскрытий, уходит с объявлением ЦК, а не с перехватом.
/datum/unit_test/hk47_extraction_licensed_departure

/datum/unit_test/hk47_extraction_licensed_departure/Run()
	var/datum/antagonist/hk47/contract_fixture/hunter = allocate_hk47_hunter()
	var/mob/living/carbon/human/droid = hunter.owner.current
	droid.set_species(/datum/species/ipc/hk/hk47)
	hunter.add_crew(src, "Captain", ANTAG_OPT_IN_NOT_TARGET)
	hunter.assign_legend(HK47_STATUS_LICENSED)
	allocate_hk47_records(hunter)
	hunter.complete(hunter.active_contract)
	hunter.contracts_done = HK47_CONTRACTS_TO_WIN
	hunter.test_space = TRUE
	var/announced = length(hunter.test_announcements)
	TEST_ASSERT(hunter.request_extraction(), "extraction called")
	allocated += hunter.extraction_pod_ref?.resolve()
	TEST_ASSERT_EQUAL(length(hunter.test_announcements), announced + 1, "CentCom announces the departure")
	var/departure = hunter.test_announcements[length(hunter.test_announcements)]
	TEST_ASSERT(findtext(departure, hunter.license_number) && findtext(departure, "покидает"), "the departure names the license")
	TEST_ASSERT(!hunter.test_beacon_shown, "a lawful departure needs no landing mark")

/// После трёх контрактов каждый новый грязный контракт раскрывает HK и без свидетелей.
/datum/unit_test/hk47_dirty_after_win

/datum/unit_test/hk47_dirty_after_win/Run()
	var/datum/antagonist/hk47/contract_fixture/hunter = allocate_hk47_hunter()
	var/datum/mind/quiet = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_KILL)
	hunter.contracts_done = HK47_CONTRACTS_TO_WIN
	hunter.accept(hunter.make_contract(HK_CLIENT_SYNDICATE, /datum/hk_contract_task/kill, null, quiet))
	TEST_ASSERT(hunter.complete(hunter.active_contract), "fourth contract done")
	TEST_ASSERT_EQUAL(hunter.reveals, 1, "dirty work after the third contract is noticed without witnesses")

/datum/unit_test/proc/count_hk47_deliveries(turf/spot, path)
	. = 0
	for(var/atom/movable/delivery as anything in spot)
		if(istype(delivery, path))
			.++

/datum/unit_test/proc/allocate_hk47_deliveries(turf/spot)
	for(var/obj/structure/closet/crate/secure/weapon/hk47_countermeasures/crate in spot)
		allocated |= crate.contents
		allocated |= crate
	for(var/obj/item/pinpointer/hk47/tracker in spot)
		allocated |= tracker

/// Прерванный сигнал эвакуации ставит маяк на перезарядку: повторный сигнал сразу не подаётся и станции не объявляется.
/datum/unit_test/hk47_extraction_interrupt_cooldown

/datum/unit_test/hk47_extraction_interrupt_cooldown/Run()
	var/datum/antagonist/hk47/contract_fixture/hunter = allocate_hk47_hunter()
	hunter.escalate()
	allocate_hk47_records(hunter)
	hunter.contracts_done = HK47_CONTRACTS_TO_WIN
	hunter.test_space = TRUE
	hunter.test_channel_result = FALSE
	var/announced = length(hunter.test_announcements)
	TEST_ASSERT(!hunter.request_extraction(), "the signal is interrupted")
	TEST_ASSERT_EQUAL(length(hunter.test_announcements), announced + 1, "the interrupted beacon was intercepted once")
	TEST_ASSERT(!hunter.request_extraction(), "the beacon recharges after an interrupted signal")
	TEST_ASSERT_EQUAL(length(hunter.test_announcements), announced + 1, "a refused signal announces nothing")
	var/list/station = hunter.terminal_status_data()
	TEST_ASSERT(findtext(station["extraction_reason"], "перезаряжается"), "the terminal explains the pause: [station["extraction_reason"]]")
	COOLDOWN_RESET(hunter, extraction_retry_cooldown)
	hunter.test_channel_result = TRUE
	TEST_ASSERT(hunter.request_extraction(), "after the recharge the signal goes through")
	allocated += hunter.extraction_pod_ref?.resolve()

/// Телохранитель с лицензией застрелил своего подопечного: лицензию отзывают, HK вне закона, охрана провалена.
/datum/unit_test/hk47_bodyguard_kills_vip

/datum/unit_test/hk47_bodyguard_kills_vip/Run()
	var/datum/antagonist/hk47/contract_fixture/hunter = allocate_hk47_hunter()
	var/mob/living/carbon/human/droid = hunter.owner.current
	droid.set_species(/datum/species/ipc/hk/hk47)
	var/datum/mind/vip = hunter.add_crew(src, "Scientist", ANTAG_OPT_IN_NOT_TARGET)
	TEST_ASSERT_EQUAL(hunter.assign_legend(HK47_STATUS_BODYGUARD), HK47_STATUS_BODYGUARD, "bodyguard legend")
	allocate_hk47_records(hunter)
	var/obj/item/gun/energy/laser/rifle = allocate(/obj/item/gun/energy/laser)
	droid.put_in_hands(rifle)
	var/mob/living/carbon/human/vip_body = vip.current
	hk47_bring_near_death(vip_body)
	hk47_shoot(droid, vip_body, rifle, 30)
	TEST_ASSERT_EQUAL(vip_body.stat, DEAD, "the shot kills the VIP")
	TEST_ASSERT_EQUAL(hunter.status, HK47_STATUS_OUTLAW, "a bodyguard who kills the VIP loses the license")
	var/obj/item/card/id/hk47_license/license = droid.wear_id
	TEST_ASSERT(license.revoked, "the card is revoked, not expired")
	var/datum/data/record/record = GLOB.data_core.security_by_id[hunter.record_id]
	TEST_ASSERT_EQUAL(record?.fields["criminal"], SEC_RECORD_STATUS_ARREST, "security is told to arrest")
	var/list/entry = hunter.contract_history[length(hunter.contract_history)]
	TEST_ASSERT_EQUAL(entry["outcome"], HK_CONTRACT_FAILED, "the protection failed")

/// Повторные раскрытия после прощения ЦК поднимают приказ снова, но пеленгатор и ящик с ионным оружием приходят по одному разу; без открытых дел пеленгатор молчит.
/datum/unit_test/hk47_pardon_keeps_deliveries_once

/datum/unit_test/hk47_pardon_keeps_deliveries_once/Run()
	var/datum/antagonist/hk47/contract_fixture/hunter = allocate_hk47_hunter()
	var/mob/living/droid = hunter.owner.current
	var/turf/brig = get_turf(droid)
	var/list/bounties_before = GLOB.bounties_list.Copy()
	for(var/reveal in 1 to HK47_EXECUTE_REVEAL)
		hunter.escalate()
	allocate_hk47_records(hunter)
	allocate_hk47_deliveries(brig)
	var/datum/data/record/record = GLOB.data_core.security_by_id[hunter.record_id]
	TEST_ASSERT_EQUAL(record.fields["criminal"], SEC_RECORD_STATUS_EXECUTE, "three reveals - execute")
	TEST_ASSERT(hunter.centcom_pardon(), "CentCom closes a reveal")
	TEST_ASSERT_EQUAL(hunter.reveals, HK47_EXECUTE_REVEAL - 1, "one case closed")
	TEST_ASSERT_EQUAL(record.fields["criminal"], SEC_RECORD_STATUS_ARREST, "the execute order follows the open cases")
	var/announced = length(hunter.test_announcements)
	hunter.escalate()
	GLOB.bounties_list = bounties_before
	allocate_hk47_deliveries(brig)
	TEST_ASSERT_EQUAL(record.fields["criminal"], SEC_RECORD_STATUS_EXECUTE, "a new reveal brings the execute order back")
	TEST_ASSERT_EQUAL(length(hunter.test_announcements), announced + 1, "the station hears the order again")
	TEST_ASSERT_EQUAL(count_hk47_deliveries(brig, /obj/structure/closet/crate/secure/weapon/hk47_countermeasures), 1, "one countermeasures crate per shift")
	TEST_ASSERT_EQUAL(count_hk47_deliveries(brig, /obj/item/pinpointer/hk47), 1, "one tracker per shift")
	var/obj/item/pinpointer/hk47/tracker = locate() in brig
	TEST_ASSERT_EQUAL(tracker.signal_source(), droid, "the tracker follows a wanted HK")
	for(var/pardon in 1 to HK47_EXECUTE_REVEAL)
		hunter.centcom_pardon()
	TEST_ASSERT_EQUAL(hunter.reveals, 0, "every case closed")
	TEST_ASSERT_EQUAL(hunter.status, HK47_STATUS_PARDONED, "no open cases - no outlaw")
	TEST_ASSERT(findtext(hunter.status_path_text(), hk47_status_name(HK47_STATUS_PARDONED)), "the report shows the pardon")
	TEST_ASSERT_EQUAL(record.fields["criminal"], SEC_RECORD_STATUS_NONE, "no open cases - no arrest")
	TEST_ASSERT_NULL(tracker.signal_source(), "the tracker goes quiet once the wanted status is lifted")
	hunter.escalate()
	TEST_ASSERT_EQUAL(hunter.status, HK47_STATUS_OUTLAW, "a new reveal outlaws HK again")
	TEST_ASSERT_EQUAL(record.fields["criminal"], SEC_RECORD_STATUS_ARREST, "and the arrest order is back")

/// Истёкшая лицензия и раскрытие: прощение ЦК снимает розыск целиком, а следующее раскрытие снова объявляет HK вне закона.
/datum/unit_test/hk47_pardon_after_expired_license

/datum/unit_test/hk47_pardon_after_expired_license/Run()
	var/datum/antagonist/hk47/contract_fixture/hunter = allocate_hk47_hunter()
	var/mob/living/carbon/human/droid = hunter.owner.current
	droid.set_species(/datum/species/ipc/hk/hk47)
	hunter.add_crew(src, "Captain", ANTAG_OPT_IN_NOT_TARGET)
	hunter.assign_legend(HK47_STATUS_LICENSED)
	allocate_hk47_records(hunter)
	hunter.complete(hunter.active_contract)
	TEST_ASSERT_EQUAL(hunter.status, HK47_STATUS_EXPIRED, "the license expired with its contract")
	hunter.escalate()
	TEST_ASSERT_EQUAL(hunter.status, HK47_STATUS_OUTLAW, "the reveal outlaws HK")
	TEST_ASSERT(hunter.centcom_pardon(), "CentCom closes the case")
	TEST_ASSERT_EQUAL(hunter.reveals, 0, "the reveal is closed")
	TEST_ASSERT_EQUAL(hunter.status, HK47_STATUS_EXPIRED, "the license is closed, nothing else is open")
	var/obj/item/card/id/hk47_license/license = droid.wear_id
	TEST_ASSERT(!license.revoked && license.expired, "the card shows a closed license")
	var/datum/data/record/record = GLOB.data_core.security_by_id[hunter.record_id]
	TEST_ASSERT_EQUAL(record.fields["criminal"], SEC_RECORD_STATUS_NONE, "no arrest")
	hunter.escalate()
	TEST_ASSERT_EQUAL(hunter.status, HK47_STATUS_OUTLAW, "the next reveal outlaws HK again")
	TEST_ASSERT_EQUAL(record.fields["criminal"], SEC_RECORD_STATUS_ARREST, "and orders the arrest again")
	TEST_ASSERT_NULL(locate(/obj/item/pinpointer/hk47) in get_turf(droid), "one open case does not bring the tracker")

/// Отозванную лицензию ЦК закрывает по своему делу, даже если СБ уже уничтожила карту.
/datum/unit_test/hk47_pardon_without_card

/datum/unit_test/hk47_pardon_without_card/Run()
	var/datum/antagonist/hk47/contract_fixture/hunter = allocate_hk47_hunter()
	var/mob/living/carbon/human/droid = hunter.owner.current
	droid.set_species(/datum/species/ipc/hk/hk47)
	hunter.add_crew(src, "Captain", ANTAG_OPT_IN_NOT_TARGET)
	var/datum/mind/victim = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_KILL)
	hunter.assign_legend(HK47_STATUS_LICENSED)
	allocate_hk47_records(hunter)
	hunter.revoke_license(victim.current)
	TEST_ASSERT_EQUAL(hunter.status, HK47_STATUS_OUTLAW, "the license is revoked")
	qdel(droid.wear_id)
	TEST_ASSERT(hunter.centcom_pardon(), "CentCom closes the revocation without the card")
	TEST_ASSERT_NOTEQUAL(hunter.status, HK47_STATUS_OUTLAW, "the wanted status is lifted")
	var/datum/data/record/record = GLOB.data_core.security_by_id[hunter.record_id]
	TEST_ASSERT_EQUAL(record.fields["criminal"], SEC_RECORD_STATUS_NONE, "the arrest is lifted")

/// Перепрошитый антагонистом HK для СБ остаётся в розыске, а имя хозяина в базу не попадает.
/datum/unit_test/hk47_reprogram_by_antagonist

/datum/unit_test/hk47_reprogram_by_antagonist/Run()
	var/datum/antagonist/hk47/contract_fixture/hunter = allocate_hk47_hunter()
	var/mob/living/droid = hunter.owner.current
	var/datum/mind/droid_mind = hunter.owner
	hunter.escalate()
	allocate_hk47_records(hunter)
	var/datum/data/record/record = GLOB.data_core.security_by_id[hunter.record_id]
	var/mob/living/carbon/human/traitor = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	traitor.mind_initialize()
	allocated += traitor.mind
	mark_hk47_antag(traitor.mind)
	var/datum/component/hk_loyalty/loyalty = droid.AddComponent(/datum/component/hk_loyalty)
	loyalty.set_master(traitor.mind)
	TEST_ASSERT_NULL(droid_mind.has_antag_datum(/datum/antagonist/hk47), "reprogramming removes the role")
	TEST_ASSERT_EQUAL(record.fields["criminal"], SEC_RECORD_STATUS_ARREST, "an antagonist's HK stays wanted")
	TEST_ASSERT(!findtext(record.fields["notes"], traitor.mind.name), "security never learns the antagonist master")
