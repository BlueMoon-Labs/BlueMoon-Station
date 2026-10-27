/// HK-47 на тестовом z: экипаж, машины и стиль заданий задаются тестом, у тестовых мобов нет клиентов.
/datum/antagonist/hk47/contract_fixture
	silent = TRUE
	var/list/test_crew = list()
	var/list/test_machines = list()
	var/test_style = ANTAG_OBJECTIVE_STYLE_NORMAL
	var/datum/hk_contract/called_extraction
	var/crew_count = 0
	var/mob/living/warned_body
	var/warning_text
	var/test_brig = FALSE
	var/list/test_relics = list()
	/// Тела без игрока: SSD для counts_as_player.
	var/list/test_ssd = list()
	/// Свидетелей нет: соседние по клетке тестовые мобы не раскрывают работу.
	var/test_blind = FALSE
	var/list/sent_pods = list()

/datum/antagonist/hk47/contract_fixture/Destroy()
	test_crew.Cut()
	test_machines.Cut()
	test_relics.Cut()
	test_ssd.Cut()
	for(var/obj/structure/closet/supplypod/pod as anything in sent_pods)
		if(!QDELETED(pod))
			qdel(pod)
	sent_pods.Cut()
	called_extraction = null
	warned_body = null
	return ..()

/datum/antagonist/hk47/contract_fixture/send_pod(obj/structure/closet/supplypod/pod, turf/landing)
	sent_pods += pod

/datum/antagonist/hk47/contract_fixture/relic_pool()
	return test_relics.Copy()

/datum/antagonist/hk47/contract_fixture/crew_minds()
	return test_crew.Copy()

/datum/antagonist/hk47/contract_fixture/counts_as_player(mob/living/someone)
	return !isnull(someone?.mind) && !(someone in test_ssd)

/datum/antagonist/hk47/contract_fixture/in_contract_zone(atom/thing)
	return !isnull(get_turf(thing))

/datum/antagonist/hk47/contract_fixture/sabotage_pool()
	return test_machines.Copy()

/datum/antagonist/hk47/contract_fixture/hunt_pool()
	return test_crew.Copy()

/datum/antagonist/hk47/contract_fixture/in_brig(atom/thing)
	return test_brig

/datum/antagonist/hk47/contract_fixture/deliver_hunt_warning(mob/living/body, text)
	warned_body = body
	warning_text = text

/datum/antagonist/hk47/contract_fixture/witness_pool(turf/center)
	if(test_blind)
		return list()
	return SSspatial_grid.orthogonal_range_search(center, SPATIAL_GRID_CONTENTS_TYPE_AI_TARGETS, HK47_WITNESS_RANGE)

/datum/antagonist/hk47/contract_fixture/objective_style()
	return test_style

/datum/antagonist/hk47/contract_fixture/channel_scan(mob/living/droid, atom/target)
	return TRUE

/datum/antagonist/hk47/contract_fixture/start_capture_extraction(datum/hk_contract/contract, mob/living/carbon/human/victim)
	called_extraction = contract
	return TRUE

/datum/antagonist/hk47/contract_fixture/proc/add_crew(datum/unit_test/test, role = "Assistant", level = ANTAG_OPT_IN_ROUND_REMOVE, turf/location)
	var/mob/living/carbon/human/body = test.allocate(/mob/living/carbon/human, location || test.run_loc_floor_top_right)
	body.real_name = "HK test crew [++crew_count]"
	body.name = body.real_name
	var/datum/mind/crew_mind = test.allocate_mind()
	crew_mind.name = body.real_name
	crew_mind.assigned_role = role
	crew_mind.antag_opt_in_level = level
	crew_mind.current = body
	body.mind = crew_mind
	test_crew += crew_mind
	return crew_mind

/datum/antagonist/hk47/contract_fixture/proc/add_offer(task_type, datum/target, modifier_type)
	var/datum/hk_contract/contract = make_contract(HK_CLIENT_PRIVATE, task_type, modifier_type, target)
	offers += contract
	return contract

/datum/unit_test/proc/allocate_hk47_hunter()
	var/mob/living/carbon/human/droid = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	droid.real_name = HK47_NAME
	droid.mind_initialize()
	allocated += droid.mind
	var/datum/antagonist/hk47/contract_fixture/hunter = new
	droid.mind.add_antag_datum(hunter)
	return hunter

/datum/unit_test/proc/mark_hk47_antag(datum/mind/marked)
	var/datum/antagonist/mark = new
	allocated += mark
	mark.owner = marked
	marked.antag_datums = list(mark)

/datum/antagonist/hk47/contract_fixture/suspect_pool(turf/center)
	return SSspatial_grid.orthogonal_range_search(center, SPATIAL_GRID_CONTENTS_TYPE_AI_TARGETS, HK47_IDENTIFY_RANGE)

/// Кража: засчитывается ID-карта цели или печать главы её отдела в руке HK, чужая карта - нет.
/datum/unit_test/hk47_theft_loot

/datum/unit_test/hk47_theft_loot/Run()
	var/datum/antagonist/hk47/contract_fixture/hunter = allocate_hk47_hunter()
	var/mob/living/carbon/human/droid = hunter.owner.current
	var/datum/mind/target = hunter.add_crew(src, "Station Engineer", ANTAG_OPT_IN_TEMPORARY)
	TEST_ASSERT(hunter.accept(hunter.add_offer(/datum/hk_contract_task/theft, target)), "theft accepted")
	var/obj/item/card/id/stranger_card = allocate(/obj/item/card/id, get_turf(droid))
	stranger_card.registered_name = "HK test stranger"
	droid.put_in_active_hand(stranger_card)
	TEST_ASSERT(!hunter.try_scan(), "someone else's card is not the loot")
	var/obj/item/card/id/card = allocate(/obj/item/card/id, get_turf(droid))
	card.registered_name = target.current.real_name
	droid.put_in_inactive_hand(card)
	TEST_ASSERT(hunter.try_scan(), "the target's card in hand closes the theft")
	TEST_ASSERT(QDELETED(card), "the card goes to the client")
	var/datum/mind/second = hunter.add_crew(src, "Station Engineer", ANTAG_OPT_IN_TEMPORARY)
	TEST_ASSERT(hunter.accept(hunter.add_offer(/datum/hk_contract_task/theft, second)), "second theft accepted")
	droid.dropItemToGround(stranger_card)
	var/obj/item/stamp/ce/stamp = allocate(/obj/item/stamp/ce, get_turf(droid))
	droid.put_in_active_hand(stamp)
	TEST_ASSERT(hunter.try_scan(), "the stamp of the target's department head closes the theft")
	TEST_ASSERT_EQUAL(hunter.contracts_done, 2, "both thefts counted")

/// Кража ценности: цель - фирменная вещь отдела, целеуказатель ведёт к ней, засчитывается вещь в руке; корпорация доплачивает капсулой снаряжения.
/datum/unit_test/hk47_theft_relic

/datum/unit_test/hk47_theft_relic/Run()
	var/datum/antagonist/hk47/contract_fixture/hunter = allocate_hk47_hunter()
	var/mob/living/carbon/human/droid = hunter.owner.current
	var/datum/hk_contract_task/relic_task = GLOB.hk_contract_tasks[/datum/hk_contract_task/theft/relic]
	TEST_ASSERT_NULL(relic_task.pick_target(hunter), "no relics, no relic theft")
	var/obj/item/hand_tele/relic = allocate(/obj/item/hand_tele, run_loc_floor_top_right)
	var/obj/item/bikehorn/junk = allocate(/obj/item/bikehorn, run_loc_floor_top_right)
	hunter.test_relics += list(relic, junk)
	TEST_ASSERT_EQUAL(relic_task.pick_target(hunter), relic, "only listed department items are relics")
	var/datum/hk_contract/contract = hunter.make_contract(HK_CLIENT_CORP, /datum/hk_contract_task/theft/relic)
	TEST_ASSERT(hunter.accept(contract), "relic theft accepted")
	TEST_ASSERT_EQUAL(contract.tracked_atom(), relic, "the tracker leads to the item")
	TEST_ASSERT(!hunter.try_scan(), "the relic has to be in hand")
	droid.put_in_active_hand(relic)
	TEST_ASSERT(hunter.try_scan(), "the relic in hand closes the theft")
	TEST_ASSERT(QDELETED(relic), "the relic goes to the client")
	TEST_ASSERT_EQUAL(length(hunter.sent_pods), 1, "the corporation pays partly in equipment")

/// «Срочно»: бонус только за выполнение в срок после принятия.
/datum/unit_test/hk47_modifier_urgent

/datum/unit_test/hk47_modifier_urgent/Run()
	var/datum/antagonist/hk47/contract_fixture/hunter = allocate_hk47_hunter()
	var/mob/living/droid = hunter.owner.current
	var/datum/mind/fast = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_KILL)
	var/datum/mind/slow = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_KILL)
	var/datum/hk_contract/quick = hunter.add_offer(/datum/hk_contract_task/kill, fast, /datum/hk_contract_modifier/urgent)
	hunter.accept(quick)
	fast.current.death()
	fast.current.forceMove(get_step(droid, EAST))
	TEST_ASSERT(hunter.try_scan(), "the quick kill is scanned")
	TEST_ASSERT_EQUAL(hunter.points, quick.task.points + HK47_MODIFIER_POINTS, "in time - with the bonus")
	var/points_before = hunter.points
	var/datum/hk_contract/late = hunter.add_offer(/datum/hk_contract_task/kill, slow, /datum/hk_contract_modifier/urgent)
	hunter.accept(late)
	late.accepted_at = world.time - HK47_URGENT_TIME - 1
	slow.current.death()
	slow.current.forceMove(get_step(droid, NORTH))
	TEST_ASSERT(hunter.try_scan(slow.current), "the late kill is scanned")
	TEST_ASSERT_EQUAL(hunter.points - points_before, late.task.points, "late - without the bonus")

/// Захват: труп капсула не принимает и контракт не засчитывает; капсула, пропавшая без груза, позволяет вызвать новую.
/datum/unit_test/hk47_capture_corpse

/datum/unit_test/hk47_capture_corpse/Run()
	var/datum/antagonist/hk47/contract_fixture/hunter = allocate_hk47_hunter()
	var/mob/living/droid = hunter.owner.current
	var/datum/mind/target = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_TEMPORARY, get_step(droid, EAST))
	var/mob/living/carbon/human/victim = target.current
	var/datum/hk_contract/contract = hunter.add_offer(/datum/hk_contract_task/capture, target)
	hunter.accept(contract)
	victim.Paralyze(10 SECONDS)
	TEST_ASSERT(hunter.try_capture(victim), "the capsule is called")
	victim.death()
	TEST_ASSERT(!hunter.capture_loaded(contract, victim), "a corpse does not complete the capture")
	TEST_ASSERT_EQUAL(hunter.active_contract, contract, "the contract stays active")
	var/datum/ransom_extraction/hk47/extraction = allocate(/datum/ransom_extraction/hk47)
	extraction.hunter_ref = WEAKREF(hunter)
	extraction.contract_ref = WEAKREF(contract)
	extraction.victim_ref = WEAKREF(victim)
	var/obj/structure/closet/pod = allocate(/obj/structure/closet, get_step(droid, NORTH))
	extraction.enter_extraction_pod(pod, victim)
	TEST_ASSERT(!extraction.loaded, "the capsule refuses a corpse")
	TEST_ASSERT_EQUAL(hunter.contracts_done, 0, "no capture for a corpse")
	TEST_ASSERT(contract.capture_called, "the capsule keeps waiting")
	extraction.on_pod_deleted(pod)
	TEST_ASSERT(!contract.capture_called, "a capsule lost without cargo lets HK call a new one")

/// Цель без игрока: убийство снимает контракт без очков, захват не принимается.
/datum/unit_test/hk47_ssd_target

/datum/unit_test/hk47_ssd_target/Run()
	var/datum/antagonist/hk47/contract_fixture/hunter = allocate_hk47_hunter()
	var/mob/living/droid = hunter.owner.current
	var/datum/mind/sleeper = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_KILL)
	var/datum/hk_contract/contract = hunter.add_offer(/datum/hk_contract_task/kill, sleeper)
	hunter.accept(contract)
	hunter.test_ssd += sleeper.current
	TEST_ASSERT(contract.target_unavailable_reason(), "an SSD target is unavailable")
	sleeper.current.death()
	TEST_ASSERT_NULL(hunter.active_contract, "killing an SSD target drops the contract")
	TEST_ASSERT_EQUAL(hunter.points, 0, "no points for an SSD kill")
	TEST_ASSERT_EQUAL(hunter.contracts_done, 0, "an SSD kill is not a completion")
	var/list/entry = hunter.contract_history[length(hunter.contract_history)]
	TEST_ASSERT_EQUAL(entry["outcome"], HK_CONTRACT_DROPPED, "the journal shows a drop")
	var/datum/mind/napper = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_TEMPORARY, get_step(droid, EAST))
	hunter.accept(hunter.add_offer(/datum/hk_contract_task/capture, napper))
	napper.current.Paralyze(10 SECONDS)
	hunter.test_ssd += napper.current
	TEST_ASSERT(!hunter.try_capture(napper.current), "an SSD target is not captured")
	TEST_ASSERT_NULL(hunter.called_extraction, "no capsule for an SSD target")

/// Цель захвата больше не в человеческом теле: контракт недоступен и снимается бесплатно.
/datum/unit_test/hk47_capture_needs_human

/datum/unit_test/hk47_capture_needs_human/Run()
	var/datum/antagonist/hk47/contract_fixture/hunter = allocate_hk47_hunter()
	var/datum/mind/target = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_TEMPORARY)
	var/datum/hk_contract/contract = hunter.add_offer(/datum/hk_contract_task/capture, target)
	hunter.accept(contract)
	var/mob/living/carbon/human/old_body = target.current
	var/mob/living/carbon/monkey/monkey = allocate(/mob/living/carbon/monkey, run_loc_floor_top_right)
	old_body.mind = null
	monkey.mind = target
	target.current = monkey
	TEST_ASSERT(findtext(contract.target_unavailable_reason(), "человеческом"), "a capture target outside a human body is unavailable")
	TEST_ASSERT(hunter.reroll(FALSE), "the contract is dropped for free")
	TEST_ASSERT_NULL(hunter.active_contract, "no active contract")
	TEST_ASSERT(COOLDOWN_FINISHED(hunter, reroll_cooldown), "no refusal cooldown")
	monkey.mind = null
	old_body.mind = target
	target.current = old_body

/// Согласие сверяется при принятии: отказавшаяся цель не принимается, охота пересчитывает, можно ли убивать.
/datum/unit_test/hk47_accept_rechecks_consent

/datum/unit_test/hk47_accept_rechecks_consent/Run()
	var/datum/antagonist/hk47/contract_fixture/hunter = allocate_hk47_hunter()
	var/datum/mind/shy = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_KILL)
	var/datum/hk_contract/offer = hunter.add_offer(/datum/hk_contract_task/kill, shy)
	shy.antag_opt_in_level = ANTAG_OPT_IN_TEMPORARY
	TEST_ASSERT(offer.offer_unavailable_reason(), "the offer shows the changed consent")
	TEST_ASSERT(!hunter.accept(offer), "a kill on a target that withdrew consent is refused")
	var/datum/mind/runner = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_KILL)
	mark_hk47_antag(runner)
	runner.hk47_kill_time = world.time
	var/datum/hk_contract/hunt = hunter.make_contract(HK_CLIENT_SYNDICATE, /datum/hk_contract_task/hunt, null, runner)
	TEST_ASSERT(hunt.lethal, "the hunt was offered as a kill")
	runner.antag_opt_in_level = ANTAG_OPT_IN_TEMPORARY
	TEST_ASSERT(hunter.accept(hunt), "the hunt is still on")
	TEST_ASSERT(!hunt.lethal, "the hunt became capture only")

/// Бесплатно меняются только недоступные предложения; отказ от всех ждёт кулдауна.
/datum/unit_test/hk47_replace_unavailable_offers

/datum/unit_test/hk47_replace_unavailable_offers/Run()
	var/datum/antagonist/hk47/contract_fixture/hunter = allocate_hk47_hunter()
	var/datum/mind/first = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_KILL)
	var/datum/mind/second = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_KILL)
	var/datum/mind/runaway = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_KILL)
	hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_KILL)
	var/datum/hk_contract/kept = hunter.add_offer(/datum/hk_contract_task/kill, first)
	var/datum/hk_contract/also_kept = hunter.add_offer(/datum/hk_contract_task/kill, second)
	var/datum/hk_contract/gone = hunter.add_offer(/datum/hk_contract_task/kill, runaway)
	TEST_ASSERT(!hunter.reroll(FALSE), "nothing to replace while every offer is available")
	runaway.current.moveToNullspace()
	TEST_ASSERT(hunter.reroll(FALSE), "the unavailable offer is replaced for free")
	TEST_ASSERT(QDELETED(gone), "the unavailable offer is gone")
	TEST_ASSERT((kept in hunter.offers) && (also_kept in hunter.offers), "available offers stay")
	TEST_ASSERT_EQUAL(length(hunter.offers), HK47_CONTRACT_OFFERS, "a new offer takes its place")
	TEST_ASSERT(COOLDOWN_FINISHED(hunter, reroll_cooldown), "a free replacement does not start the cooldown")
	TEST_ASSERT(hunter.reroll(TRUE), "refusing everything is voluntary")
	TEST_ASSERT(QDELETED(kept), "refusing everything drops every offer")
	TEST_ASSERT(!COOLDOWN_FINISHED(hunter, reroll_cooldown), "and starts the cooldown")

/// Цель выполненного контракта второй раз не предлагается.
/datum/unit_test/hk47_completed_target_excluded

/datum/unit_test/hk47_completed_target_excluded/Run()
	var/datum/antagonist/hk47/contract_fixture/hunter = allocate_hk47_hunter()
	var/datum/mind/head = hunter.add_crew(src, "Captain", ANTAG_OPT_IN_ROUND_REMOVE)
	var/datum/hk_contract_task/capture = GLOB.hk_contract_tasks[/datum/hk_contract_task/capture]
	TEST_ASSERT_EQUAL(capture.pick_target(hunter), head, "the head is a capture target")
	var/datum/hk_contract/contract = hunter.add_offer(/datum/hk_contract_task/capture, head)
	hunter.accept(contract)
	TEST_ASSERT(hunter.complete(contract), "the capture is done")
	TEST_ASSERT_NULL(capture.pick_target(hunter), "a completed target is not offered again")
	for(var/attempt in 1 to 5)
		for(var/datum/hk_contract/offer as anything in hunter.generate_offers())
			TEST_ASSERT_NOTEQUAL(offer.get_target(), head, "the same head was offered again")

/// Доставка в бриг засчитывается, только если цель привёл сам HK.
/datum/unit_test/hk47_brig_delivery_needs_hk

/datum/unit_test/hk47_brig_delivery_needs_hk/Run()
	var/datum/antagonist/hk47/contract_fixture/hunter = allocate_hk47_hunter()
	var/mob/living/droid = hunter.owner.current
	var/datum/mind/target = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_KILL, get_step(droid, EAST))
	mark_hk47_antag(target)
	target.hk47_kill_time = world.time
	var/datum/hk_contract/contract = hunter.make_contract(HK_CLIENT_CENTCOM, /datum/hk_contract_task/hunt)
	hunter.accept(contract)
	TEST_ASSERT(hunter.try_identify(target.current), "the target is identified")
	hunter.test_brig = TRUE
	target.current.Paralyze(10 SECONDS)
	var/turf/droid_spot = get_turf(droid)
	droid.moveToNullspace()
	TEST_ASSERT(!contract.check_brig_delivery(), "a target brought in without HK does not count")
	droid.forceMove(droid_spot)
	TEST_ASSERT(contract.check_brig_delivery(), "HK next to the target delivers it")

/// Сверка сигнатуры - только с видимым подозреваемым: за укрытием и в стелсе терминал его не показывает и не сверяет.
/datum/unit_test/hk47_identify_needs_sight

/datum/unit_test/hk47_identify_needs_sight/Run()
	var/datum/antagonist/hk47/contract_fixture/hunter = allocate_hk47_hunter()
	var/mob/living/droid = hunter.owner.current
	var/datum/mind/target = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_KILL, locate(droid.x + 2, droid.y, droid.z))
	mark_hk47_antag(target)
	target.hk47_kill_time = world.time
	hunter.accept(hunter.make_contract(HK_CLIENT_SYNDICATE, /datum/hk_contract_task/hunt, null, target))
	var/obj/structure/closet/blocker = allocate(/obj/structure/closet, locate(droid.x + 1, droid.y, droid.z))
	blocker.set_opacity(TRUE)
	TEST_ASSERT(!length(hunter.terminal.suspects(droid)), "the terminal does not list a suspect behind cover")
	TEST_ASSERT(!hunter.try_identify(target.current), "a suspect behind cover is not identified")
	TEST_ASSERT(COOLDOWN_FINISHED(hunter, identify_cooldown), "an unseen suspect does not cost the pause")
	blocker.set_opacity(FALSE)
	target.current.alpha = 0
	TEST_ASSERT(!length(hunter.terminal.suspects(droid)), "the terminal does not list a cloaked suspect")
	TEST_ASSERT(!hunter.try_identify(target.current), "a cloaked suspect is not identified")
	target.current.alpha = 255
	TEST_ASSERT_EQUAL(length(hunter.terminal.suspects(droid)), 1, "a visible suspect is listed")
	TEST_ASSERT(hunter.try_identify(target.current), "a visible suspect is identified")

/// Охрана засчитывается, только если HK провёл рядом с подопечным нужную долю срока.
/datum/unit_test/hk47_protect_presence

/datum/unit_test/hk47_protect_presence/Run()
	var/datum/antagonist/hk47/contract_fixture/hunter = allocate_hk47_hunter()
	var/mob/living/droid = hunter.owner.current
	var/datum/mind/lonely = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_NOT_TARGET)
	var/datum/mind/guarded = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_NOT_TARGET)
	var/datum/hk_contract/absent = hunter.add_offer(/datum/hk_contract_task/protect, lonely)
	hunter.accept(absent)
	TEST_ASSERT(absent.protect_sample_timer, "presence is sampled on a timer")
	var/turf/droid_spot = get_turf(droid)
	droid.moveToNullspace()
	for(var/sample in 1 to 3)
		absent.sample_protection()
	droid.forceMove(droid_spot)
	absent.sample_protection()
	TEST_ASSERT_EQUAL(absent.presence_percent(), 25, "presence is the share of samples near the VIP")
	absent.protect_time_up()
	TEST_ASSERT_EQUAL(hunter.contracts_done, 0, "a guard who stayed away is not paid")
	TEST_ASSERT_NULL(hunter.active_contract, "the absent guard fails")
	var/datum/hk_contract/present = hunter.add_offer(/datum/hk_contract_task/protect, guarded)
	hunter.accept(present)
	present.sample_protection()
	present.sample_protection()
	present.protect_time_up()
	TEST_ASSERT_EQUAL(hunter.contracts_done, 1, "a guard who stayed near is paid")

/// Середина охраны: конкурент шлёт пару враждебных HK-50, оба предупреждены; конец охраны их отзывает. Подопечный без согласия на убийство их целью не становится.
/datum/unit_test/hk47_protect_rivals

/datum/unit_test/hk47_protect_rivals/Run()
	var/datum/antagonist/hk47/contract_fixture/hunter = allocate_hk47_hunter()
	var/mob/living/droid = hunter.owner.current
	var/datum/mind/vip = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_NOT_TARGET)
	var/datum/hk_contract/guard = hunter.add_offer(/datum/hk_contract_task/protect, vip)
	hunter.accept(guard)
	TEST_ASSERT(guard.rival_timer, "the rival strike is scheduled")
	TEST_ASSERT(guard.send_rivals(), "the rival capsule is sent")
	TEST_ASSERT(findtext(hunter.test_vip_messages[length(hunter.test_vip_messages)], "телохранител"), "the VIP is told the rivals want the bodyguard")
	var/list/rivals = land_hk47_rivals(hunter, guard, vip.current)
	TEST_ASSERT_EQUAL(length(rivals), HK50_SERVANT_PAIR_SIZE, "a pair of HK-50 lands")
	for(var/mob/living/simple_animal/hostile/hk50/rival as anything in rivals)
		var/datum/component/hk50_rival/hired = rival.GetComponent(/datum/component/hk50_rival)
		TEST_ASSERT_EQUAL(hired?.mark_ref?.resolve(), droid, "a VIP who is not a kill target is never the mark: the rivals hunt HK-47")
		TEST_ASSERT(!hunter.is_hk_side(rival), "the rival HK-50 is not on HK-47's side")
	guard.protect_time_up()
	TEST_ASSERT_EQUAL(hunter.contracts_done, 1, "the VIP survived")
	for(var/mob/living/rival as anything in rivals)
		TEST_ASSERT(QDELETED(rival), "the rivals leave when the guard ends")

	var/datum/mind/bold = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_KILL)
	var/datum/hk_contract/risky = hunter.add_offer(/datum/hk_contract_task/protect, bold)
	hunter.accept(risky)
	var/turf/droid_spot = get_turf(droid)
	droid.moveToNullspace()
	TEST_ASSERT(!risky.send_rivals(), "no rivals while HK-47 is away from the VIP")
	TEST_ASSERT(risky.rival_timer, "the strike waits for HK-47 to come back")
	droid.forceMove(droid_spot)
	TEST_ASSERT(risky.send_rivals(), "HK-47 is back, the rivals are sent")
	TEST_ASSERT(findtext(hunter.test_vip_messages[length(hunter.test_vip_messages)], "за вами"), "the VIP is warned")
	rivals = land_hk47_rivals(hunter, risky, bold.current)
	for(var/mob/living/simple_animal/hostile/hk50/rival as anything in rivals)
		var/datum/component/hk50_rival/hired = rival.GetComponent(/datum/component/hk50_rival)
		TEST_ASSERT_EQUAL(hired?.mark_ref?.resolve(), bold.current, "a VIP who agreed to be a kill target is the mark")
		TEST_ASSERT(!rival.faction_check_mob(bold.current), "the rival HK-50 is hostile to the VIP")
	hunter.reroll(TRUE)

/datum/unit_test/proc/land_hk47_rivals(datum/antagonist/hk47/contract_fixture/hunter, datum/hk_contract/guard, mob/living/vip)
	var/obj/structure/closet/supplypod/hk47/reinforcement/pod = hunter.sent_pods[length(hunter.sent_pods)]
	pod.forceMove(get_step(vip, WEST))
	pod.open_pod(pod, forced = TRUE)
	. = list()
	for(var/datum/weakref/rival_ref as anything in guard.rival_refs)
		. += rival_ref.resolve()
	allocated += .

/// Заказчик - ось выбора: Синдикат доплачивает очком, корпорация - снаряжением, ЦК снимает розыск после отзыва лицензии или закрывает раскрытие.
/datum/unit_test/hk47_client_perks

/datum/unit_test/hk47_client_perks/Run()
	var/datum/antagonist/hk47/contract_fixture/hunter = allocate_hk47_hunter()
	var/mob/living/carbon/human/droid = hunter.owner.current
	var/datum/mind/victim = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_KILL)
	var/datum/mind/head = hunter.add_crew(src, "Captain", ANTAG_OPT_IN_NOT_TARGET)
	var/datum/mind/prisoner = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_TEMPORARY)
	hunter.test_blind = TRUE
	var/datum/hk_contract/syndicate = hunter.make_contract(HK_CLIENT_SYNDICATE, /datum/hk_contract_task/kill, null, victim)
	TEST_ASSERT_EQUAL(syndicate.points(), syndicate.task.points + HK47_SYNDICATE_BONUS_POINTS, "the syndicate pays a bonus point")
	hunter.accept(syndicate)
	hunter.complete(syndicate)
	TEST_ASSERT_EQUAL(hunter.points, 1 + HK47_SYNDICATE_BONUS_POINTS, "the bonus is paid")
	hunter.accept(hunter.make_contract(HK_CLIENT_CORP, /datum/hk_contract_task/capture, null, prisoner))
	hunter.complete(hunter.active_contract)
	TEST_ASSERT_EQUAL(length(hunter.sent_pods), 1, "the corporation sends an equipment capsule")
	var/obj/structure/closet/supplypod/hk47/reinforcement/pod = hunter.sent_pods[1]
	var/turf/landing = get_step(droid, NORTH)
	pod.forceMove(landing)
	pod.open_pod(pod, forced = TRUE)
	var/obj/item/reward
	for(var/obj/item/thing in landing)
		if(is_type_in_list(thing, HK47_CORP_REWARD_ITEMS))
			reward = thing
	allocated += reward
	TEST_ASSERT_NOTNULL(reward, "the capsule brings equipment")
	hunter.escalate()
	allocate_hk47_records(hunter)
	var/datum/data/record/record = GLOB.data_core.security_by_id[hunter.record_id]
	TEST_ASSERT_EQUAL(hunter.status, HK47_STATUS_OUTLAW, "the reveal outlaws HK")
	hunter.accept(hunter.make_contract(HK_CLIENT_CENTCOM, /datum/hk_contract_task/protect/head, null, head))
	hunter.complete(hunter.active_contract)
	TEST_ASSERT_EQUAL(hunter.reveals, 0, "CentCom closes one reveal")
	TEST_ASSERT_NOTEQUAL(hunter.status, HK47_STATUS_OUTLAW, "with no open cases HK is no longer an outlaw")
	TEST_ASSERT_EQUAL(record.fields["criminal"], SEC_RECORD_STATUS_NONE, "the arrest goes with the last case")
	var/obj/item/card/id/hk47_license/license = hunter.issue_license(/obj/item/card/id/hk47_license)
	allocated += license
	hunter.status = HK47_STATUS_LICENSED
	hunter.revoke_license(prisoner.current)
	TEST_ASSERT(license.revoked, "the license is revoked")
	TEST_ASSERT_EQUAL(record.fields["criminal"], SEC_RECORD_STATUS_ARREST, "the revocation orders the arrest")
	hunter.accept(hunter.make_contract(HK_CLIENT_CENTCOM, /datum/hk_contract_task/protect/head, null, head))
	hunter.complete(hunter.active_contract)
	TEST_ASSERT(!license.revoked && license.expired, "CentCom closes the license without the revocation")
	TEST_ASSERT_EQUAL(hunter.status, HK47_STATUS_EXPIRED, "the HK is no longer an outlaw")
	TEST_ASSERT_EQUAL(record.fields["criminal"], SEC_RECORD_STATUS_NONE, "the arrest is lifted")

/// Журнал хранит настоящее имя цели, и отчёт раунда называет неопознанную цель охоты.
/datum/unit_test/hk47_history_names_hidden_target

/datum/unit_test/hk47_history_names_hidden_target/Run()
	var/datum/antagonist/hk47/contract_fixture/hunter = allocate_hk47_hunter()
	var/datum/mind/runner = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_KILL)
	mark_hk47_antag(runner)
	runner.hk47_kill_time = world.time
	var/datum/hk_contract/hunt = hunter.make_contract(HK_CLIENT_SYNDICATE, /datum/hk_contract_task/hunt, null, runner)
	hunter.accept(hunt)
	var/hidden_name = runner.current.real_name
	TEST_ASSERT(!findtext(hunt.describe(), hidden_name), "the hunt hides the name")
	hunter.reroll(TRUE)
	var/list/entry = hunter.contract_history[length(hunter.contract_history)]
	TEST_ASSERT_EQUAL(entry["target_name"], hidden_name, "the journal keeps the real name")
	TEST_ASSERT(findtext(jointext(hunter.roundend_details(), " "), "(цель: [hidden_name])"), "the round report names the hidden target")

/// Скан трупа выжигает метку, которую видно при осмотре вплотную.
/datum/unit_test/hk47_scan_mark

/datum/unit_test/hk47_scan_mark/Run()
	var/datum/antagonist/hk47/contract_fixture/hunter = allocate_hk47_hunter()
	var/mob/living/droid = hunter.owner.current
	var/datum/mind/target = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_KILL)
	var/mob/living/carbon/human/victim = target.current
	hunter.accept(hunter.add_offer(/datum/hk_contract_task/kill, target))
	TEST_ASSERT(!findtext(jointext(victim.examine(droid), " "), "сканера дроида серии HK"), "no mark before the scan")
	victim.death()
	victim.forceMove(get_step(droid, EAST))
	TEST_ASSERT(hunter.try_scan(victim), "the corpse is scanned")
	TEST_ASSERT(findtext(jointext(victim.examine(droid), " "), "сканера дроида серии HK"), "a close look finds the scanner mark")
	victim.forceMove(locate(droid.x + 3, droid.y, droid.z))
	TEST_ASSERT(!findtext(jointext(victim.examine(droid), " "), "сканера дроида серии HK"), "the mark is not seen from afar")

/// Саботаж выбирает и новые машины: консоль связи и СМЕС на станции - тоже цели.
/datum/unit_test/hk47_sabotage_kinds

/datum/unit_test/hk47_sabotage_kinds/Run()
	var/datum/antagonist/hk47/contract_fixture/hunter = allocate_hk47_hunter()
	var/obj/machinery/computer/communications/console = allocate(/obj/machinery/computer/communications, run_loc_floor_top_right)
	hunter.test_machines += console
	var/datum/hk_contract_task/sabotage = GLOB.hk_contract_tasks[/datum/hk_contract_task/sabotage]
	TEST_ASSERT_EQUAL(sabotage.pick_target(hunter), console, "the communications console is a sabotage target")
	var/datum/hk_contract/contract = hunter.add_offer(/datum/hk_contract_task/sabotage, console)
	hunter.accept(contract)
	console.obj_break()
	TEST_ASSERT_EQUAL(hunter.contracts_done, 1, "breaking the console counts")

/// Кандидаты: уровень согласия по задаче, без гост-ролей, мёртвых, самого HK и его слуг; командование и СБ впереди.
/datum/unit_test/hk47_target_filter

/datum/unit_test/hk47_target_filter/Run()
	var/datum/antagonist/hk47/contract_fixture/hunter = allocate_hk47_hunter()
	hunter.test_crew += hunter.owner
	var/datum/mind/assistant = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_KILL)
	var/datum/mind/officer = hunter.add_crew(src, "Security Officer", ANTAG_OPT_IN_NOT_TARGET)
	var/datum/mind/captain = hunter.add_crew(src, "Captain")
	var/datum/mind/shy = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_TEMPORARY)
	var/datum/mind/refuser = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_NOT_TARGET)
	var/datum/mind/corpse = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_KILL)
	corpse.current.death()
	var/datum/mind/ghost_role = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_KILL)
	ADD_TRAIT(ghost_role.current, TRAIT_NO_MIDROUND_ANTAG, TRAIT_GENERIC)
	var/datum/mind/servant = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_KILL)
	servant.current.AddComponent(/datum/component/hk_loyalty, hunter.owner)
	var/list/killable = hunter.target_candidates(ANTAG_OPT_IN_KILL)
	TEST_ASSERT_EQUAL(length(killable), 3, "only the living crew that agreed to be killed")
	TEST_ASSERT_EQUAL(killable[1], captain, "command goes first")
	TEST_ASSERT_EQUAL(killable[2], officer, "security goes second, its job raises the consent level")
	TEST_ASSERT_EQUAL(killable[3], assistant, "the rest go last")
	var/list/temporary = hunter.target_candidates(ANTAG_OPT_IN_TEMPORARY)
	TEST_ASSERT(shy in temporary, "temporary consent is enough for non-lethal tasks")
	TEST_ASSERT(!(shy in killable), "temporary consent is not enough for kills")
	TEST_ASSERT(!(refuser in temporary), "not a target of non-lethal tasks either")
	var/list/anyone = hunter.target_candidates(ANTAG_OPT_IN_NOT_TARGET)
	TEST_ASSERT(refuser in anyone, "protection needs no consent")
	TEST_ASSERT(!(hunter.owner in anyone), "HK-47 never targets itself")
	TEST_ASSERT(!(servant in anyone), "HK-47 never targets its servants")
	TEST_ASSERT(!(corpse in anyone), "the dead are not offered")
	TEST_ASSERT(!(ghost_role in anyone), "ghost roles are not offered")

/// ЦК не предлагается без засветившегося антага; с ним охота находит антага; три предложения - три разные цели.
/datum/unit_test/hk47_cc_needs_antag

/datum/unit_test/hk47_cc_needs_antag/Run()
	var/datum/antagonist/hk47/contract_fixture/hunter = allocate_hk47_hunter()
	var/datum/mind/traitor = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_KILL)
	for(var/index in 1 to 4)
		hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_KILL)
	TEST_ASSERT(!hunter.client_available(HK_CLIENT_CENTCOM), "no antagonist, no CentCom")
	for(var/attempt in 1 to 10)
		var/list/offers = hunter.generate_offers()
		TEST_ASSERT_EQUAL(length(offers), HK47_CONTRACT_OFFERS, "three offers")
		var/list/targets = list()
		for(var/datum/hk_contract/offer as anything in offers)
			TEST_ASSERT_NOTEQUAL(offer.client_id, HK_CLIENT_CENTCOM, "CentCom offered without an antagonist")
			targets |= offer.get_target()
		TEST_ASSERT_EQUAL(length(targets), HK47_CONTRACT_OFFERS, "every offer has its own target")
	mark_hk47_antag(traitor)
	TEST_ASSERT(!hunter.client_available(HK_CLIENT_CENTCOM), "a quiet antagonist does not open CentCom")
	traitor.hk47_kill_time = world.time
	TEST_ASSERT(hunter.client_available(HK_CLIENT_CENTCOM), "an exposed antagonist opens CentCom")
	var/datum/hk_contract_task/hunt = GLOB.hk_contract_tasks[/datum/hk_contract_task/hunt]
	TEST_ASSERT_EQUAL(hunt.pick_target(hunter), traitor, "the hunt targets the antagonist")
	TEST_ASSERT(/datum/hk_contract_task/hunt in hunter.task_weights(HK_CLIENT_SYNDICATE), "the syndicate orders hunts too")
	TEST_ASSERT(/datum/hk_contract_task/hunt in hunter.task_weights(HK_CLIENT_PRIVATE), "private clients order hunts too")

/// Ликвидация засчитывается сканом трупа цели рядом и не отменяется оживлением.
/datum/unit_test/hk47_kill_scan

/datum/unit_test/hk47_kill_scan/Run()
	var/datum/antagonist/hk47/contract_fixture/hunter = allocate_hk47_hunter()
	var/mob/living/droid = hunter.owner.current
	var/datum/mind/target = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_KILL)
	var/mob/living/carbon/human/victim = target.current
	var/datum/hk_contract/contract = hunter.add_offer(/datum/hk_contract_task/kill, target)
	TEST_ASSERT(hunter.accept(contract), "contract accepted")
	TEST_ASSERT_EQUAL(hunter.active_contract, contract, "contract is active")
	TEST_ASSERT(!length(hunter.offers), "other offers are dropped")
	TEST_ASSERT(!hunter.try_scan(victim), "a living target is not scanned")
	victim.death()
	TEST_ASSERT(!hunter.try_scan(victim), "the corpse has to be adjacent")
	victim.forceMove(get_step(droid, EAST))
	TEST_ASSERT(hunter.try_scan(), "the scan finds the adjacent corpse by itself")
	TEST_ASSERT_EQUAL(hunter.contracts_done, 1, "kill counted")
	TEST_ASSERT_EQUAL(hunter.points, contract.task.points, "kill points awarded")
	TEST_ASSERT_NULL(hunter.active_contract, "no active contract after the kill")
	victim.revive(full_heal = TRUE, admin_revive = TRUE)
	TEST_ASSERT_EQUAL(hunter.contracts_done, 1, "revival does not undo the contract")
	var/datum/objective/hk47_contracts/objective = locate() in hunter.objectives
	TEST_ASSERT_EQUAL(objective.check_completion(), 1 / HK47_CONTRACTS_TO_WIN, "the contract counts for the objective")

/// «Без свидетелей» ломается от игрока в радиусе с видимостью и держится без него; слуги HK не свидетели.
/datum/unit_test/hk47_modifier_no_witnesses

/datum/unit_test/hk47_modifier_no_witnesses/Run()
	var/datum/antagonist/hk47/contract_fixture/hunter = allocate_hk47_hunter()
	var/mob/living/droid = hunter.owner.current
	var/datum/mind/target = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_KILL)
	var/datum/hk_contract/contract = hunter.add_offer(/datum/hk_contract_task/kill, target, /datum/hk_contract_modifier/no_witnesses)
	hunter.accept(contract)
	var/turf/near = locate(droid.x + 2, droid.y, droid.z)
	var/mob/living/carbon/human/onlooker = allocate(/mob/living/carbon/human, near)
	onlooker.mind_initialize()
	allocated += onlooker.mind
	var/mob/living/carbon/human/servant = allocate(/mob/living/carbon/human, locate(droid.x, droid.y + 2, droid.z))
	servant.mind_initialize()
	allocated += servant.mind
	servant.AddComponent(/datum/component/hk_loyalty, hunter.owner)
	var/list/seen_by = hunter.witnesses(contract)
	TEST_ASSERT_EQUAL(length(seen_by), 1, "one witness: servants and the target do not count")
	TEST_ASSERT(onlooker in seen_by, "the onlooker in sight is a witness")
	TEST_ASSERT(!contract.modifier.holds(contract), "a witness breaks the modifier")
	var/obj/structure/closet/blocker = allocate(/obj/structure/closet, locate(droid.x + 1, droid.y, droid.z))
	blocker.set_opacity(TRUE)
	TEST_ASSERT(contract.modifier.holds(contract), "a witness behind cover sees nothing")
	blocker.set_opacity(FALSE)
	onlooker.moveToNullspace()
	var/mob/living/carbon/human/victim = target.current
	victim.death()
	victim.forceMove(get_step(droid, EAST))
	TEST_ASSERT(hunter.try_scan(victim), "kill scanned")
	TEST_ASSERT_EQUAL(hunter.points, contract.task.points + HK47_MODIFIER_POINTS, "the modifier pays when nobody else sees")

/// «Несчастный случай»: смерть без попадания HK за 30 с засчитывается, с попаданием - нет.
/datum/unit_test/hk47_modifier_accident

/datum/unit_test/hk47_modifier_accident/Run()
	var/datum/antagonist/hk47/contract_fixture/hunter = allocate_hk47_hunter()
	var/mob/living/droid = hunter.owner.current
	var/datum/mind/lucky = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_KILL)
	var/datum/mind/shot = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_KILL)
	var/datum/hk_contract/accident = hunter.add_offer(/datum/hk_contract_task/kill, lucky, /datum/hk_contract_modifier/accident)
	hunter.accept(accident)
	var/mob/living/carbon/human/victim = lucky.current
	victim.death()
	victim.forceMove(get_step(droid, EAST))
	TEST_ASSERT(hunter.try_scan(victim), "accidental death scanned")
	TEST_ASSERT_EQUAL(hunter.points, accident.task.points + HK47_MODIFIER_POINTS, "a death without HK hits is an accident")
	var/points_before = hunter.points
	var/datum/hk_contract/murder = hunter.add_offer(/datum/hk_contract_task/kill, shot, /datum/hk_contract_modifier/accident)
	hunter.accept(murder)
	victim = shot.current
	victim.forceMove(get_step(droid, NORTH))
	var/obj/item/projectile/bullet/bullet = allocate(/obj/item/projectile/bullet, get_turf(droid))
	bullet.damage = 0
	bullet.nodamage = TRUE
	bullet.firer = droid
	bullet.starting = get_turf(droid)
	victim.bullet_act(bullet, BODY_ZONE_CHEST)
	victim.death()
	TEST_ASSERT(hunter.try_scan(victim), "shot target scanned")
	TEST_ASSERT_EQUAL(hunter.points - points_before, murder.task.points, "a death right after an HK hit is no accident")

/// Охрана: VIP жив к таймеру - выполнено, погиб - провал.
/datum/unit_test/hk47_protect

/datum/unit_test/hk47_protect/Run()
	var/datum/antagonist/hk47/contract_fixture/hunter = allocate_hk47_hunter()
	var/datum/mind/survivor = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_NOT_TARGET)
	var/datum/mind/doomed = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_NOT_TARGET)
	var/datum/hk_contract/guard = hunter.add_offer(/datum/hk_contract_task/protect, survivor)
	TEST_ASSERT(hunter.accept(guard), "protection accepted")
	TEST_ASSERT(guard.protect_timer, "protection runs on a timer")
	guard.protect_time_up()
	TEST_ASSERT_EQUAL(hunter.contracts_done, 1, "the VIP survived")
	TEST_ASSERT_EQUAL(hunter.points, guard.task.points, "protection points awarded")
	var/datum/hk_contract/failed = hunter.add_offer(/datum/hk_contract_task/protect, doomed)
	hunter.accept(failed)
	doomed.current.death()
	TEST_ASSERT_NULL(hunter.active_contract, "the VIP death ends the contract")
	TEST_ASSERT_EQUAL(hunter.contracts_done, 1, "a dead VIP is a failure")
	TEST_ASSERT_EQUAL(hunter.points, guard.task.points, "no points for a dead VIP")

/// Саботаж: уничтожение назначенной машины засчитывает контракт.
/datum/unit_test/hk47_sabotage

/datum/unit_test/hk47_sabotage/Run()
	var/datum/antagonist/hk47/contract_fixture/hunter = allocate_hk47_hunter()
	var/datum/hk_contract_task/sabotage = GLOB.hk_contract_tasks[/datum/hk_contract_task/sabotage]
	TEST_ASSERT(!sabotage.is_available(hunter), "no machines, no sabotage")
	var/obj/machinery/computer/upload/ai/console = allocate(/obj/machinery/computer/upload/ai, run_loc_floor_top_right)
	var/obj/machinery/computer/upload/borg/spare = allocate(/obj/machinery/computer/upload/borg, run_loc_floor_bottom_left)
	hunter.test_machines += list(console, spare)
	TEST_ASSERT(sabotage.is_available(hunter), "an upload console is a sabotage target")
	var/datum/hk_contract/broken = hunter.add_offer(/datum/hk_contract_task/sabotage, console)
	hunter.accept(broken)
	console.obj_break()
	TEST_ASSERT_EQUAL(hunter.contracts_done, 1, "breaking the machine counts")
	TEST_ASSERT(!(console in hunter.sabotage_targets()), "a broken machine is no longer a target")
	var/datum/hk_contract/destroyed = hunter.add_offer(/datum/hk_contract_task/sabotage, spare)
	hunter.accept(destroyed)
	qdel(spare)
	TEST_ASSERT_EQUAL(hunter.contracts_done, 2, "destroying the machine counts")
	TEST_ASSERT_EQUAL(hunter.points, sabotage.points * 2, "sabotage points awarded")

/// Добровольный отказ даёт кулдаун 3 минуты, недоступная цель - бесплатный перевыбор.
/datum/unit_test/hk47_reroll_rules

/datum/unit_test/hk47_reroll_rules/Run()
	var/datum/antagonist/hk47/contract_fixture/hunter = allocate_hk47_hunter()
	var/datum/mind/first = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_KILL)
	var/datum/mind/second = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_KILL)
	hunter.accept(hunter.add_offer(/datum/hk_contract_task/kill, first))
	TEST_ASSERT(!hunter.reroll(FALSE), "an available target is not rerolled for free")
	TEST_ASSERT(hunter.reroll(TRUE), "voluntary refusal")
	TEST_ASSERT_NULL(hunter.active_contract, "refusal drops the contract")
	TEST_ASSERT_EQUAL(round(COOLDOWN_TIMELEFT(hunter, reroll_cooldown), 1), HK47_REROLL_COOLDOWN, "refusal starts the cooldown")
	TEST_ASSERT(length(hunter.offers), "refusal brings new offers")
	var/datum/hk_contract/next = hunter.add_offer(/datum/hk_contract_task/kill, second)
	hunter.accept(next)
	TEST_ASSERT(!hunter.reroll(TRUE), "second refusal waits for the cooldown")
	TEST_ASSERT_EQUAL(hunter.active_contract, next, "the contract stays")
	second.current.moveToNullspace()
	TEST_ASSERT(next.target_unavailable_reason(), "a target that left the station is unavailable")
	TEST_ASSERT(hunter.reroll(FALSE), "an unavailable target is rerolled for free")
	TEST_ASSERT_NULL(hunter.active_contract, "the unavailable contract is dropped")
	TEST_ASSERT_EQUAL(round(COOLDOWN_TIMELEFT(hunter, reroll_cooldown), 1), HK47_REROLL_COOLDOWN, "a free reroll does not touch the cooldown")
	TEST_ASSERT_EQUAL(hunter.contracts_done, 0, "rerolls are not completions")

/// Стиль «Без убийств» убирает ликвидацию и охоту-убийство, «Больше убийств» поднимает вес ликвидации.
/datum/unit_test/hk47_quiet_style_no_kills

/datum/unit_test/hk47_quiet_style_no_kills/Run()
	var/datum/antagonist/hk47/contract_fixture/hunter = allocate_hk47_hunter()
	var/datum/mind/traitor = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_KILL)
	mark_hk47_antag(traitor)
	traitor.hk47_kill_time = world.time
	for(var/index in 1 to 3)
		hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_KILL)
	var/kill_type = /datum/hk_contract_task/kill
	var/list/normal = hunter.task_weights(HK_CLIENT_SYNDICATE)
	TEST_ASSERT(normal[kill_type], "the syndicate orders kills")
	hunter.test_style = ANTAG_OBJECTIVE_STYLE_VIOLENT
	var/list/violent = hunter.task_weights(HK_CLIENT_SYNDICATE)
	TEST_ASSERT_EQUAL(violent[kill_type], round(normal[kill_type] * ANTAG_OBJECTIVE_VIOLENT_KILL_MULT), "more kills style raises the kill weight")
	hunter.test_style = ANTAG_OBJECTIVE_STYLE_QUIET
	TEST_ASSERT(!(kill_type in hunter.task_weights(HK_CLIENT_SYNDICATE)), "no kills style removes the kill task")
	for(var/attempt in 1 to 15)
		for(var/datum/hk_contract/offer as anything in hunter.generate_offers())
			TEST_ASSERT(!istype(offer.task, /datum/hk_contract_task/kill), "no kills style offered a kill")
			TEST_ASSERT(!offer.lethal, "no kills style offered a lethal hunt")

/// Согласие по задаче: цель «без убийства» получает захват, кражу и охоту-захват, но не ликвидацию и не охоту-убийство.
/datum/unit_test/hk47_consent_per_task

/datum/unit_test/hk47_consent_per_task/Run()
	var/datum/antagonist/hk47/contract_fixture/hunter = allocate_hk47_hunter()
	var/datum/mind/shy = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_TEMPORARY)
	mark_hk47_antag(shy)
	shy.hk47_kill_time = world.time
	var/datum/hk_contract_task/capture = GLOB.hk_contract_tasks[/datum/hk_contract_task/capture]
	var/datum/hk_contract_task/theft = GLOB.hk_contract_tasks[/datum/hk_contract_task/theft]
	var/datum/hk_contract_task/kill = GLOB.hk_contract_tasks[/datum/hk_contract_task/kill]
	var/datum/hk_contract_task/hunt = GLOB.hk_contract_tasks[/datum/hk_contract_task/hunt]
	TEST_ASSERT_EQUAL(capture.pick_target(hunter), shy, "capture needs only temporary consent")
	TEST_ASSERT_EQUAL(theft.pick_target(hunter), shy, "theft needs only temporary consent")
	TEST_ASSERT_NULL(kill.pick_target(hunter), "a kill needs kill consent")
	TEST_ASSERT_EQUAL(hunt.pick_target(hunter), shy, "a hunt needs only temporary consent")
	var/datum/hk_contract/shy_hunt = hunter.make_contract(HK_CLIENT_SYNDICATE, /datum/hk_contract_task/hunt)
	TEST_ASSERT(!shy_hunt.lethal, "a hunt on temporary consent is capture only")
	var/datum/mind/bold = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_KILL)
	mark_hk47_antag(bold)
	bold.hk47_kill_time = world.time
	var/datum/hk_contract/syndicate_hunt = hunter.make_contract(HK_CLIENT_SYNDICATE, /datum/hk_contract_task/hunt, null, bold)
	var/datum/hk_contract/centcom_hunt = hunter.make_contract(HK_CLIENT_CENTCOM, /datum/hk_contract_task/hunt, null, bold)
	TEST_ASSERT(syndicate_hunt.lethal, "the syndicate hunt may kill with kill consent")
	TEST_ASSERT(!centcom_hunt.lethal, "the CentCom hunt is detention")

/// Захват: свободная цель не грузится, обездвиженная рядом - вызывает капсулу; погрузка засчитывает контракт.
/datum/unit_test/hk47_capture

/datum/unit_test/hk47_capture/Run()
	var/datum/antagonist/hk47/contract_fixture/hunter = allocate_hk47_hunter()
	var/mob/living/droid = hunter.owner.current
	var/datum/mind/target = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_TEMPORARY, get_step(droid, EAST))
	var/mob/living/carbon/human/victim = target.current
	var/datum/hk_contract/contract = hunter.add_offer(/datum/hk_contract_task/capture, target)
	hunter.accept(contract)
	TEST_ASSERT(!hunter.try_capture(victim), "a free target resists")
	victim.Paralyze(10 SECONDS)
	TEST_ASSERT(hunter.try_capture(victim), "a paralyzed target next to HK is captured")
	TEST_ASSERT_EQUAL(hunter.called_extraction, contract, "the capsule is called for this contract")
	TEST_ASSERT(!hunter.try_capture(victim), "one capsule per contract")
	TEST_ASSERT_EQUAL(hunter.contracts_done, 0, "the capture counts only when loaded")
	TEST_ASSERT(hunter.capture_loaded(contract, victim), "loading completes the contract")
	TEST_ASSERT_EQUAL(hunter.points, contract.task.points, "capture points awarded")

/// HK-47 видит уровни согласия, как остальные антаги, и теряет HUD вместе с ролью.
/datum/unit_test/hk47_consent_hud

/datum/unit_test/hk47_consent_hud/Run()
	var/datum/antagonist/hk47/contract_fixture/hunter = allocate_hk47_hunter()
	var/datum/mind/droid_mind = hunter.owner
	var/mob/living/droid = droid_mind.current
	var/datum/atom_hud/opt_in_hud = GLOB.huds[DATA_HUD_ANTAG_OPT_IN]
	TEST_ASSERT(droid in opt_in_hud.hudusers, "HK-47 sees consent levels")
	droid_mind.remove_antag_datum(/datum/antagonist/hk47/contract_fixture)
	TEST_ASSERT(!(droid in opt_in_hud.hudusers), "the HUD goes with the role")

/// Контракт без случайного выбора принимается сразу; выполнение шлёт сигнал со свидетелями даже без модификатора.
/datum/unit_test/hk47_completion_signal
	var/datum/hk_contract/completed
	var/completed_witnessed = FALSE

/datum/unit_test/hk47_completion_signal/Destroy()
	completed = null
	return ..()

/datum/unit_test/hk47_completion_signal/proc/on_completed(mob/living/source, datum/hk_contract/contract, witnessed)
	SIGNAL_HANDLER
	completed = contract
	completed_witnessed = witnessed

/datum/unit_test/hk47_completion_signal/Run()
	var/datum/antagonist/hk47/contract_fixture/hunter = allocate_hk47_hunter()
	var/mob/living/droid = hunter.owner.current
	var/datum/mind/target = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_KILL)
	var/datum/hk_contract/contract = hunter.make_contract(HK_CLIENT_SYNDICATE, /datum/hk_contract_task/kill)
	TEST_ASSERT_NOTNULL(contract, "a kill contract is made on request")
	TEST_ASSERT_EQUAL(contract.get_target(), target, "the target is picked by the usual rules")
	TEST_ASSERT_EQUAL(contract.client_id, HK_CLIENT_SYNDICATE, "the client is kept")
	TEST_ASSERT_NULL(contract.modifier, "no modifier unless asked")
	TEST_ASSERT_NULL(hunter.make_contract(HK_CLIENT_SYNDICATE, /datum/hk_contract_task/sabotage), "no target, no contract")
	TEST_ASSERT(hunter.accept(contract), "a made contract is accepted without being offered")
	var/mob/living/carbon/human/onlooker = allocate(/mob/living/carbon/human, locate(droid.x + 2, droid.y, droid.z))
	onlooker.mind_initialize()
	allocated += onlooker.mind
	RegisterSignal(droid, COMSIG_HK47_CONTRACT_COMPLETED, PROC_REF(on_completed))
	var/mob/living/carbon/human/victim = target.current
	victim.death()
	victim.forceMove(get_step(droid, EAST))
	TEST_ASSERT(hunter.try_scan(victim), "kill scanned")
	TEST_ASSERT_EQUAL(completed, contract, "the signal carries the contract")
	TEST_ASSERT(completed_witnessed, "the witness is reported without the no-witnesses modifier")

/// Охота не выдаёт тихого антага: засветиться можно убийством игрока или розыском СБ.
/datum/unit_test/hk47_hunt_exposure

/datum/unit_test/hk47_hunt_exposure/Run()
	var/datum/antagonist/hk47/contract_fixture/hunter = allocate_hk47_hunter()
	var/datum/hk_contract_task/hunt = GLOB.hk_contract_tasks[/datum/hk_contract_task/hunt]
	var/datum/mind/killer = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_KILL)
	mark_hk47_antag(killer)
	var/datum/mind/wanted = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_KILL)
	mark_hk47_antag(wanted)
	var/datum/mind/bystander = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_KILL)
	TEST_ASSERT(!length(hunt.candidate_targets(hunter)), "quiet antagonists are never hunted")
	for(var/attempt in 1 to 5)
		for(var/datum/hk_contract/offer as anything in hunter.generate_offers())
			TEST_ASSERT(!offer.is_hunt(), "a hunt was offered on a quiet antagonist")
	killer.current.ckey = "hk47huntkiller"
	killer.key = "hk47huntkiller"
	SSticker.minds += killer
	var/datum/mind/victim = hunter.add_crew(src, "Assistant")
	GLOB.hk47_kill_ledger.watch(victim.current)
	victim.current.set_last_attacker(killer.current)
	victim.current.death()
	SSticker.minds -= killer
	TEST_ASSERT(!isnull(killer.hk47_kill_time), "killing a player exposes the antagonist")
	var/datum/data/record/record = allocate(/datum/data/record)
	record.fields["name"] = wanted.current.real_name
	record.fields["criminal"] = SEC_RECORD_STATUS_ARREST
	GLOB.data_core.security_by_name[wanted.current.real_name] = record
	var/list/exposed = hunt.candidate_targets(hunter)
	TEST_ASSERT(killer in exposed, "the killer is hunted")
	TEST_ASSERT(wanted in exposed, "the wanted antagonist is hunted")
	TEST_ASSERT(!(bystander in exposed), "crew without an antagonist role is never hunted")

/// Имя цели охоты скрыто до опознания, ошибка ставит опознание на паузу, цель предупреждена, второй охоты на неё нет.
/datum/unit_test/hk47_hunt_identify

/datum/unit_test/hk47_hunt_identify/Run()
	var/datum/antagonist/hk47/contract_fixture/hunter = allocate_hk47_hunter()
	var/mob/living/droid = hunter.owner.current
	var/datum/mind/target = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_KILL, locate(droid.x + 3, droid.y, droid.z))
	mark_hk47_antag(target)
	target.hk47_kill_time = world.time
	target.hk47_kill_area = "Место убийства"
	var/datum/mind/decoy = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_KILL, get_step(droid, NORTH))
	var/target_name = target.current.real_name
	var/datum/hk_contract/contract = hunter.make_contract(HK_CLIENT_SYNDICATE, /datum/hk_contract_task/hunt)
	TEST_ASSERT_EQUAL(contract.get_target(), target, "the exposed antagonist is the hunt target")
	TEST_ASSERT(!findtext(contract.describe(), target_name), "the offer hides the name")
	TEST_ASSERT(hunter.accept(contract), "hunt accepted")
	TEST_ASSERT(!findtext(contract.describe(), target_name), "accepting does not reveal the name")
	TEST_ASSERT(!contract.trackable(), "no tracking before identification")
	TEST_ASSERT_EQUAL(hunter.warned_body, target.current, "the hunted antagonist is warned")
	TEST_ASSERT(findtext(hunter.warning_text, "HK"), "the warning speaks of an HK droid")
	TEST_ASSERT(!findtext(hunter.warning_text, contract.client_name()), "the warning names no client")
	TEST_ASSERT_EQUAL(contract.trace_area, "Место убийства", "the kill is the first trace")
	TEST_ASSERT(!hunter.try_identify(target.current), "three tiles is too far to identify")
	TEST_ASSERT(!hunter.try_identify(decoy.current), "a wrong suspect is not identified")
	TEST_ASSERT_EQUAL(round(COOLDOWN_TIMELEFT(hunter, identify_cooldown), 1), HK47_IDENTIFY_COOLDOWN, "a wrong suspect pauses identification")
	target.current.forceMove(locate(droid.x + 2, droid.y, droid.z))
	TEST_ASSERT(!hunter.try_identify(target.current), "identification waits for the pause")
	COOLDOWN_RESET(hunter, identify_cooldown)
	TEST_ASSERT(hunter.try_identify(target.current), "the target is identified within two tiles")
	TEST_ASSERT(findtext(contract.describe(), target_name), "identification reveals the name")
	TEST_ASSERT(contract.trackable(), "identification allows tracking")
	var/datum/hk_contract_task/hunt = GLOB.hk_contract_tasks[/datum/hk_contract_task/hunt]
	TEST_ASSERT(!(target in hunt.candidate_targets(hunter)), "the same antagonist is not hunted twice")

/// След охоты обновляется действиями цели, остывает через 10 минут; «рядом» - без направления.
/datum/unit_test/hk47_hunt_trace

/datum/unit_test/hk47_hunt_trace/Run()
	var/datum/antagonist/hk47/contract_fixture/hunter = allocate_hk47_hunter()
	var/mob/living/droid = hunter.owner.current
	var/datum/mind/target = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_KILL)
	mark_hk47_antag(target)
	target.hk47_kill_time = world.time
	target.current.ckey = "hk47tracetarget"
	target.key = "hk47tracetarget"
	var/datum/hk_contract/contract = hunter.make_contract(HK_CLIENT_PRIVATE, /datum/hk_contract_task/hunt)
	hunter.accept(contract)
	contract.trace_time = world.time - HK47_TRACE_COLD_TIME - 1
	TEST_ASSERT(contract.trace_cold(), "an old trace is cold")
	var/datum/mind/victim = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_NOT_TARGET, run_loc_floor_bottom_left)
	GLOB.hk47_kill_ledger.watch(victim.current)
	victim.current.set_last_attacker(target.current)
	TEST_ASSERT(!contract.trace_cold(), "an attack by the target leaves a fresh trace")
	TEST_ASSERT_EQUAL(contract.trace_area, get_area_name(target.current, TRUE), "the trace points to where the target attacked")
	contract.trace_time = world.time - HK47_TRACE_COLD_TIME - 1
	victim.current.death()
	TEST_ASSERT(!contract.trace_cold(), "a death caused by the target refreshes the trace")
	TEST_ASSERT(contract.target_near(), "the target within five tiles is near")
	target.current.forceMove(locate(droid.x + 6, droid.y, droid.z))
	TEST_ASSERT(!contract.target_near(), "six tiles away is not near")
	var/obj/item/gun/energy/laser/gun = allocate(/obj/item/gun/energy/laser)
	target.current.put_in_hands(gun)
	gun.cell.charge = 0
	gun.chambered = null
	contract.trace_time = world.time - HK47_TRACE_COLD_TIME - 1
	gun.process_fire(droid, target.current)
	TEST_ASSERT(!contract.trace_cold(), "pulling the trigger leaves a fresh trace")

/// Охота ЦК - задержание: опознанную обездвиженную цель засчитывает и камера брига.
/datum/unit_test/hk47_hunt_brig_delivery

/datum/unit_test/hk47_hunt_brig_delivery/Run()
	var/datum/antagonist/hk47/contract_fixture/hunter = allocate_hk47_hunter()
	var/mob/living/droid = hunter.owner.current
	var/datum/mind/target = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_KILL, get_step(droid, EAST))
	mark_hk47_antag(target)
	target.hk47_kill_time = world.time
	var/datum/hk_contract/contract = hunter.make_contract(HK_CLIENT_CENTCOM, /datum/hk_contract_task/hunt)
	hunter.accept(contract)
	hunter.test_brig = TRUE
	TEST_ASSERT(!contract.check_brig_delivery(), "an unidentified target does not count in the brig")
	hunter.try_identify(target.current)
	TEST_ASSERT_EQUAL(hunter.contracts_done, 0, "a free target in the brig is not detained")
	target.current.Paralyze(10 SECONDS)
	TEST_ASSERT(contract.check_brig_delivery(), "a restrained target in the brig is detained")
	TEST_ASSERT_EQUAL(hunter.contracts_done, 1, "detention completes the hunt")

/// «Без лишних жертв» видит убийства слуг: выстрел NPC HK-50 и удар HK-50 с разумом.
/datum/unit_test/hk47_servant_collateral

/datum/unit_test/hk47_servant_collateral/Run()
	var/datum/antagonist/hk47/contract_fixture/hunter = allocate_hk47_hunter()
	var/mob/living/droid = hunter.owner.current
	var/datum/mind/target = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_KILL)
	var/datum/mind/shot = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_KILL)
	var/datum/mind/struck = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_KILL)
	var/datum/hk_contract/contract = hunter.add_offer(/datum/hk_contract_task/kill, target, /datum/hk_contract_modifier/no_collateral)
	hunter.accept(contract)
	var/mob/living/simple_animal/hostile/hk50/servant = allocate(/mob/living/simple_animal/hostile/hk50, get_step(droid, NORTH))
	servant.AddComponent(/datum/component/hk50_servant, droid)
	hk47_shoot(servant, shot.current)
	shot.current.death()
	TEST_ASSERT(contract.collateral, "a kill by an NPC servant is collateral")
	contract.collateral = FALSE
	var/mob/living/carbon/human/ghost = hunter.create_ghost_servant(get_step(droid, SOUTH), null)
	allocated += list(ghost, ghost.mind)
	struck.current.set_last_attacker(ghost)
	struck.current.death()
	TEST_ASSERT(contract.collateral, "a kill by a ghost servant is collateral")
	TEST_ASSERT(!contract.modifier.holds(contract), "servant kills break the modifier")

/// Попадание из оружия, из которого стрелял HK, засчитывается стороне HK только с HK или слугой на спуске.
/datum/unit_test/hk47_gun_hit_checks_firer

/datum/unit_test/hk47_gun_hit_checks_firer/Run()
	var/datum/antagonist/hk47/contract_fixture/hunter = allocate_hk47_hunter()
	var/mob/living/carbon/human/droid = hunter.owner.current
	var/datum/mind/target = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_KILL)
	var/datum/mind/thief = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_KILL)
	var/datum/mind/bystander = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_KILL)
	var/datum/hk_contract/contract = hunter.add_offer(/datum/hk_contract_task/kill, target, /datum/hk_contract_modifier/no_collateral)
	hunter.accept(contract)
	var/obj/item/gun/energy/laser/rifle = allocate(/obj/item/gun/energy/laser)
	droid.put_in_hands(rifle)
	droid.dropItemToGround(rifle)
	thief.current.put_in_hands(rifle)
	hk47_shoot(thief.current, bystander.current, rifle)
	TEST_ASSERT(!hunter.recent_side_hit(bystander.current), "someone else's shot from HK's gun is not HK's")
	bystander.current.death()
	TEST_ASSERT(!contract.collateral, "someone else's kill is not collateral")
	hk47_shoot(droid, thief.current, rifle)
	TEST_ASSERT(hunter.recent_side_hit(thief.current), "HK's own shot from the same gun counts")

/// Свидетель удара и смерти цели раскрывает HK, даже если скан идёт в пустой комнате; бонуса «без свидетелей» нет.
/datum/unit_test/hk47_witness_at_kill

/datum/unit_test/hk47_witness_at_kill/Run()
	var/datum/antagonist/hk47/contract_fixture/hunter = allocate_hk47_hunter()
	var/mob/living/droid = hunter.owner.current
	var/datum/mind/target = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_KILL, get_step(droid, EAST))
	var/datum/hk_contract/contract = hunter.make_contract(HK_CLIENT_SYNDICATE, /datum/hk_contract_task/kill, /datum/hk_contract_modifier/no_witnesses, target)
	hunter.accept(contract)
	var/mob/living/carbon/human/onlooker = allocate_hk47_onlooker(droid)
	target.current.set_last_attacker(droid)
	target.current.death()
	onlooker.moveToNullspace()
	TEST_ASSERT(!length(hunter.witnesses(contract)), "nobody sees the scan")
	TEST_ASSERT(hunter.try_scan(target.current), "kill scanned")
	TEST_ASSERT_EQUAL(hunter.reveals, 1, "a kill seen when it happened reveals HK")
	TEST_ASSERT_EQUAL(hunter.points, contract.task.points + contract.client_bonus(), "no bonus for a seen kill")

/// Свидетель взятия ID цели раскрывает HK, даже если скан идёт без него.
/datum/unit_test/hk47_witness_at_theft

/datum/unit_test/hk47_witness_at_theft/Run()
	var/datum/antagonist/hk47/contract_fixture/hunter = allocate_hk47_hunter()
	var/mob/living/carbon/human/droid = hunter.owner.current
	var/datum/mind/target = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_TEMPORARY)
	hunter.accept(hunter.make_contract(HK_CLIENT_CORP, /datum/hk_contract_task/theft, null, target))
	var/obj/item/card/id/card = allocate(/obj/item/card/id)
	card.registered_name = target.current.real_name
	var/mob/living/carbon/human/onlooker = allocate_hk47_onlooker(droid)
	droid.put_in_hands(card)
	onlooker.moveToNullspace()
	TEST_ASSERT(hunter.try_scan(), "the ID is scanned")
	TEST_ASSERT_EQUAL(hunter.reveals, 1, "taking the ID in sight of a witness reveals HK")

/// Журнал убийств охоты: смерть засчитывается и стрелку, но удар старше HK47_HIT_MEMORY убийцей не делает.
/datum/unit_test/hk47_kill_ledger_attribution

/datum/unit_test/hk47_kill_ledger_attribution/Run()
	var/datum/antagonist/hk47/contract_fixture/hunter = allocate_hk47_hunter()
	var/datum/mind/shooter = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_KILL)
	mark_hk47_antag(shooter)
	shooter.current.ckey = "hk47ledgershooter"
	shooter.key = "hk47ledgershooter"
	var/datum/mind/puncher = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_KILL)
	mark_hk47_antag(puncher)
	puncher.current.ckey = "hk47ledgerpuncher"
	puncher.key = "hk47ledgerpuncher"
	SSticker.minds += list(shooter, puncher)
	var/datum/mind/shot = hunter.add_crew(src, "Assistant")
	var/datum/mind/punched = hunter.add_crew(src, "Assistant")
	GLOB.hk47_kill_ledger.watch(shot.current)
	GLOB.hk47_kill_ledger.watch(punched.current)
	hk47_shoot(shooter.current, shot.current)
	shot.current.death()
	punched.current.set_last_attacker(puncher.current)
	punched.current.hk47_attack_time = world.time - HK47_HIT_MEMORY - 1
	punched.current.death()
	SSticker.minds -= list(shooter, puncher)
	TEST_ASSERT(!isnull(shooter.hk47_kill_time), "a shot kill exposes the antagonist")
	TEST_ASSERT_NULL(puncher.hk47_kill_time, "an old punch does not make the death a kill")

/// Свидетель вызова капсулы раскрывает HK, даже если при погрузке рядом никого.
/datum/unit_test/hk47_witness_at_capture_call

/datum/unit_test/hk47_witness_at_capture_call/Run()
	var/datum/antagonist/hk47/contract_fixture/hunter = allocate_hk47_hunter()
	var/mob/living/droid = hunter.owner.current
	var/datum/mind/target = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_TEMPORARY, get_step(droid, EAST))
	var/datum/hk_contract/contract = hunter.make_contract(HK_CLIENT_CORP, /datum/hk_contract_task/capture, null, target)
	hunter.accept(contract)
	target.current.Paralyze(10 SECONDS)
	var/mob/living/carbon/human/onlooker = allocate_hk47_onlooker(droid)
	TEST_ASSERT(hunter.try_capture(target.current), "the capsule is called in sight of a witness")
	onlooker.moveToNullspace()
	TEST_ASSERT(hunter.capture_loaded(contract, target.current), "the target is loaded with nobody around")
	TEST_ASSERT_EQUAL(hunter.reveals, 1, "the witnessed call reveals HK")

/// Эвакуированный HK больше не работает: активный контракт снят, предложений нет, новый контракт не принимается.
/datum/unit_test/hk47_no_contracts_after_extraction

/datum/unit_test/hk47_no_contracts_after_extraction/Run()
	var/datum/antagonist/hk47/contract_fixture/hunter = allocate_hk47_hunter()
	var/datum/mind/target = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_KILL)
	var/datum/mind/spare = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_NOT_TARGET)
	var/datum/mind/other = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_KILL)
	var/datum/hk_contract/contract = hunter.make_contract(HK_CLIENT_SYNDICATE, /datum/hk_contract_task/kill, null, target)
	hunter.accept(contract)
	hunter.add_offer(/datum/hk_contract_task/kill, other)
	hunter.contracts_done = HK47_CONTRACTS_TO_WIN
	hunter.finish_extraction()
	TEST_ASSERT_NULL(hunter.active_contract, "the active contract is closed by the extraction")
	TEST_ASSERT(QDELETED(contract), "the closed contract is gone")
	TEST_ASSERT(!length(hunter.offers), "no offers after the extraction")
	var/list/entry = hunter.contract_history[length(hunter.contract_history)]
	TEST_ASSERT_EQUAL(entry["outcome"], HK_CONTRACT_DROPPED, "the journal shows the closed contract")
	TEST_ASSERT(findtext(jointext(hunter.roundend_details(), " "), "снят при эвакуации"), "the round report says why the contract closed")
	var/datum/hk_contract/protect = hunter.make_contract(HK_CLIENT_CENTCOM, /datum/hk_contract_task/protect/head, null, spare)
	TEST_ASSERT(!hunter.accept(protect), "an extracted HK takes no contracts")
	qdel(protect)
	TEST_ASSERT(!length(hunter.generate_offers()), "an extracted HK gets no offers")

/// Капсула захвата не берёт цель, если контракт уже закрыт.
/datum/unit_test/hk47_capture_pod_needs_open_contract

/datum/unit_test/hk47_capture_pod_needs_open_contract/Run()
	var/datum/antagonist/hk47/contract_fixture/hunter = allocate_hk47_hunter()
	var/mob/living/droid = hunter.owner.current
	var/datum/mind/target = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_TEMPORARY, get_step(droid, EAST))
	var/mob/living/carbon/human/victim = target.current
	var/datum/hk_contract/contract = hunter.add_offer(/datum/hk_contract_task/capture, target)
	hunter.accept(contract)
	victim.Paralyze(10 SECONDS)
	TEST_ASSERT(hunter.try_capture(victim), "the capsule is called")
	var/datum/ransom_extraction/hk47/extraction = allocate(/datum/ransom_extraction/hk47)
	extraction.hunter_ref = WEAKREF(hunter)
	extraction.contract_ref = WEAKREF(contract)
	extraction.victim_ref = WEAKREF(victim)
	TEST_ASSERT(hunter.reroll(TRUE), "HK refuses the contract after the call")
	var/obj/structure/closet/pod = allocate(/obj/structure/closet, get_step(droid, NORTH))
	extraction.enter_extraction_pod(pod, victim)
	TEST_ASSERT(!extraction.loaded, "the capsule does not take a target of a closed contract")
	TEST_ASSERT_EQUAL(hunter.contracts_done, 0, "nothing is counted")

/// Неопознанная цель охоты недоступна без подробностей: терминал не выдаёт, что с ней случилось.
/datum/unit_test/hk47_hidden_hunt_reason

/datum/unit_test/hk47_hidden_hunt_reason/Run()
	var/datum/antagonist/hk47/contract_fixture/hunter = allocate_hk47_hunter()
	var/datum/mind/runner = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_KILL)
	mark_hk47_antag(runner)
	runner.hk47_kill_time = world.time
	var/datum/hk_contract/hunt = hunter.make_contract(HK_CLIENT_SYNDICATE, /datum/hk_contract_task/hunt, null, runner)
	hunter.accept(hunt)
	runner.current.moveToNullspace()
	var/real_reason = hunt.target_unavailable_reason()
	TEST_ASSERT(findtext(real_reason, "станци"), "the target left the station")
	var/list/entry = hunter.terminal.contract_data(hunt)
	TEST_ASSERT(entry["unavailable"], "the terminal shows the hunt as unavailable")
	TEST_ASSERT_NOTEQUAL(entry["unavailable"], real_reason, "the terminal hides why the hidden target is gone")

/// «Несчастный случай» снимается при принятии, если охота перестала быть убийством.
/datum/unit_test/hk47_accident_needs_lethal_hunt

/datum/unit_test/hk47_accident_needs_lethal_hunt/Run()
	var/datum/antagonist/hk47/contract_fixture/hunter = allocate_hk47_hunter()
	var/datum/mind/runner = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_KILL)
	mark_hk47_antag(runner)
	runner.hk47_kill_time = world.time
	var/datum/hk_contract/hunt = hunter.make_contract(HK_CLIENT_SYNDICATE, /datum/hk_contract_task/hunt, /datum/hk_contract_modifier/accident, runner)
	TEST_ASSERT(hunt.lethal && hunt.modifier, "a lethal hunt with the accident condition")
	runner.antag_opt_in_level = ANTAG_OPT_IN_TEMPORARY
	TEST_ASSERT(hunter.accept(hunt), "the hunt is accepted as capture only")
	TEST_ASSERT(!hunt.lethal, "the hunt is no longer lethal")
	TEST_ASSERT_NULL(hunt.modifier, "an accident needs a kill, the condition is dropped")
	TEST_ASSERT_EQUAL(hunt.points(), hunt.task.points + hunt.client_bonus(), "no bonus is promised")

/// Цель охоты, переставшая быть антагонистом, снимается без штрафа.
/datum/unit_test/hk47_hunt_target_deconverted

/datum/unit_test/hk47_hunt_target_deconverted/Run()
	var/datum/antagonist/hk47/contract_fixture/hunter = allocate_hk47_hunter()
	var/datum/mind/runner = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_KILL)
	mark_hk47_antag(runner)
	runner.hk47_kill_time = world.time
	var/datum/hk_contract/hunt = hunter.make_contract(HK_CLIENT_SYNDICATE, /datum/hk_contract_task/hunt, null, runner)
	hunter.accept(hunt)
	TEST_ASSERT_NULL(hunt.target_unavailable_reason(), "an antagonist target is available")
	runner.antag_datums = list()
	TEST_ASSERT(findtext(hunt.target_unavailable_reason(), "антагонист"), "a deconverted target is not hunted")
	TEST_ASSERT(hunter.reroll(FALSE), "the hunt is dropped for free")
	TEST_ASSERT(COOLDOWN_FINISHED(hunter, reroll_cooldown), "no refusal cooldown")

/// Кража ценности засчитывает другой экземпляр, даже если оригинал уничтожен.
/datum/unit_test/hk47_relic_copy_after_original_lost

/datum/unit_test/hk47_relic_copy_after_original_lost/Run()
	var/datum/antagonist/hk47/contract_fixture/hunter = allocate_hk47_hunter()
	var/mob/living/carbon/human/droid = hunter.owner.current
	var/obj/item/hand_tele/relic = allocate(/obj/item/hand_tele, run_loc_floor_top_right)
	hunter.test_relics += relic
	var/datum/hk_contract/contract = hunter.make_contract(HK_CLIENT_CORP, /datum/hk_contract_task/theft/relic)
	TEST_ASSERT(hunter.accept(contract), "relic theft accepted")
	qdel(relic)
	TEST_ASSERT(contract.target_unavailable_reason(), "the original is destroyed and HK holds no copy")
	var/obj/item/hand_tele/copy = allocate(/obj/item/hand_tele, get_turf(droid))
	droid.put_in_active_hand(copy)
	TEST_ASSERT_NULL(contract.target_unavailable_reason(), "a copy in hand keeps the contract going")
	TEST_ASSERT(hunter.try_scan(), "the copy closes the theft")
	TEST_ASSERT_EQUAL(hunter.contracts_done, 1, "the theft counts")

/// Подопечный ушёл со станции к концу охраны: контракт снят без штрафа, а не провален.
/datum/unit_test/hk47_protect_vip_left

/datum/unit_test/hk47_protect_vip_left/Run()
	var/datum/antagonist/hk47/contract_fixture/hunter = allocate_hk47_hunter()
	var/datum/mind/vip = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_NOT_TARGET)
	var/datum/hk_contract/guard = hunter.add_offer(/datum/hk_contract_task/protect, vip)
	hunter.accept(guard)
	vip.current.moveToNullspace()
	guard.protect_time_up()
	TEST_ASSERT_NULL(hunter.active_contract, "the protection is over")
	var/list/entry = hunter.contract_history[length(hunter.contract_history)]
	TEST_ASSERT_EQUAL(entry["outcome"], HK_CONTRACT_DROPPED, "a VIP who left the station is a free drop, not a failure")

/// Поиск ценностей по миру идёт таймером: подбор предложений его не ждёт, а обновлённый кэш находит вещь.
/datum/unit_test/hk47_relic_cache_async

/datum/unit_test/hk47_relic_cache_async/Run()
	var/datum/antagonist/hk47/hunter = allocate_plain_hk47()
	var/obj/item/hand_tele/relic = allocate(/obj/item/hand_tele, run_loc_floor_top_right)
	TEST_ASSERT(!(relic in hunter.relic_pool()), "the pool does not walk the world on the spot")
	TEST_ASSERT(hunter.relic_refresh_queued, "a refresh is queued instead")
	hunter.refresh_relic_cache()
	TEST_ASSERT(!hunter.relic_refresh_queued, "the refresh is done")
	TEST_ASSERT(relic in hunter.relic_pool(), "the refreshed cache finds the relic")

/// Погибшая цель захвата недоступна: контракт снимается без штрафа.
/datum/unit_test/hk47_capture_target_died

/datum/unit_test/hk47_capture_target_died/Run()
	var/datum/antagonist/hk47/contract_fixture/hunter = allocate_hk47_hunter()
	var/datum/mind/target = hunter.add_crew(src, "Assistant", ANTAG_OPT_IN_TEMPORARY)
	var/datum/hk_contract/contract = hunter.add_offer(/datum/hk_contract_task/capture, target)
	hunter.accept(contract)
	target.current.death()
	TEST_ASSERT(contract.target_unavailable_reason(), "a dead capture target is unavailable")
	TEST_ASSERT(hunter.reroll(FALSE), "the capture is dropped for free")
	TEST_ASSERT_NULL(hunter.active_contract, "no active contract")
	TEST_ASSERT(COOLDOWN_FINISHED(hunter, reroll_cooldown), "no refusal cooldown")
