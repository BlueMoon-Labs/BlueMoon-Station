/datum/ransom_extraction
	var/datum/syndicate_contract/linked_contract
	var/mob/living/carbon/human/forced_pirate_victim
	var/list/victim_belongings = list()
	var/ransom_credits = 0
	var/area/return_target_area
	var/force_victim_into_pod = FALSE
	var/datum/weakref/pirate_console
	var/pirate_gang_value = 0

/datum/ransom_extraction/Destroy()
	if(linked_contract?.active_ransom == src)
		linked_contract.active_ransom = null
	linked_contract = null
	forced_pirate_victim = null
	return ..()

/proc/pick_ransom_return_area()
	var/turf/turf_safe = get_safe_random_station_turf()
	if(turf_safe)
		return get_area(turf_safe)
	if(LAZYLEN(GLOB.the_station_areas))
		return pick(GLOB.the_station_areas)
	return null

/datum/ransom_extraction/proc/start_for_contract(datum/syndicate_contract/ccontract, turf/landing)
	if(!ccontract?.contract)
		return
	linked_contract = ccontract
	linked_contract.active_ransom = src
	forced_pirate_victim = null
	ransom_credits = ccontract.ransom
	return_target_area = ccontract.contract.dropoff
	force_victim_into_pod = FALSE
	launch_extraction(landing, ccontract.contract.target.current)

/datum/ransom_extraction/proc/start_for_pirate(mob/living/carbon/human/victim, turf/landing, station_ransom, gang_points, obj/machinery/computer/piratepad_control/console)
	if(QDELETED(victim))
		return
	linked_contract = null
	forced_pirate_victim = victim
	ransom_credits = station_ransom
	pirate_gang_value = gang_points
	if(console)
		pirate_console = WEAKREF(console)
	return_target_area = pick_ransom_return_area()
	force_victim_into_pod = TRUE
	launch_extraction(landing, victim)

/datum/ransom_extraction/proc/launch_extraction(turf/empty_pod_turf, mob/living/carbon/human/expected_victim)
	if(QDELETED(expected_victim) || !empty_pod_turf)
		return
	var/area/pod_storage_area = locate(/area/centcom/supplypod/podStorage) in GLOB.sortedAreas
	if(!pod_storage_area)
		return
	var/obj/structure/closet/supplypod/extractionpod/empty_pod = new(pick(get_area_turfs(pod_storage_area)))
	empty_pod.stay_after_drop = TRUE
	empty_pod.reversing = TRUE
	empty_pod.explosionSize = list(0, 0, 0, 1)
	empty_pod.leavingSound = 'sound/effects/podwoosh.ogg'
	RegisterSignal(empty_pod, COMSIG_ATOM_ENTERED, PROC_REF(enter_extraction_pod))
	new /obj/effect/pod_landingzone(empty_pod_turf, empty_pod)
	if(force_victim_into_pod)
		addtimer(CALLBACK(src, PROC_REF(force_pirate_victim), expected_victim, empty_pod), 1.5 SECONDS, TIMER_DELETE_ME)

/datum/ransom_extraction/proc/force_pirate_victim(mob/living/carbon/human/human_victim, obj/structure/closet/supplypod/extractionpod/extraction)
	if(QDELETED(human_victim) || QDELETED(extraction) || human_victim.stat == DEAD)
		return
	if(human_victim.buckled)
		human_victim.buckled.unbuckle_mob(human_victim, TRUE)
	human_victim.forceMove(extraction)

/datum/ransom_extraction/proc/enter_extraction_pod(atom/source, mob/living/entered)
	SIGNAL_HANDLER
	if(!istype(source, /obj/structure/closet/supplypod/extractionpod) || !isliving(entered))
		return
	if(!linked_contract && forced_pirate_victim && entered != forced_pirate_victim)
		return
	UnregisterSignal(source, COMSIG_ATOM_ENTERED)
	if(linked_contract)
		linked_contract.delegate_ransom_pod_entry(entered, source, src)
	else
		finalize_captured(entered, source)

/datum/syndicate_contract/proc/delegate_ransom_pod_entry(mob/living/mob_entry, obj/structure/closet/supplypod/extractionpod/extraction_pod, datum/ransom_extraction/pipeline)
	if(!pipeline)
		return
	pipeline.finalize_captured(mob_entry, extraction_pod)

/datum/ransom_extraction/proc/finalize_captured(mob/living/entered, obj/structure/closet/supplypod/extractionpod/chosen_pod)
	var/datum/syndicate_contract/sc = linked_contract
	var/datum/antagonist/traitor/traitor_data = sc?.contract?.owner?.has_antag_datum(/datum/antagonist/traitor)
	var/contractor_success = FALSE

	if(ishuman(entered) && sc?.contract && (entered == sc.contract.target.current) && traitor_data)
		traitor_data.contractor_hub.contract_TC_to_redeem += sc.contract.payout
		traitor_data.contractor_hub.contracts_completed += 1
		if(entered.stat != DEAD)
			traitor_data.contractor_hub.contract_TC_to_redeem += sc.contract.payout_bonus
		sc.status = CONTRACT_STATUS_COMPLETE
		if(traitor_data.contractor_hub.current_contract == sc)
			traitor_data.contractor_hub.current_contract = null
		traitor_data.contractor_hub.contract_rep += 2
		contractor_success = TRUE
	else if(sc)
		sc.status = CONTRACT_STATUS_ABORTED
		if(traitor_data?.contractor_hub?.current_contract == sc)
			traitor_data.contractor_hub.current_contract = null

	if(iscarbon(entered))
		for(var/obj/item/worn in entered)
			if(ishuman(entered))
				var/mob/living/carbon/human/hu = entered
				if(worn == hu.w_uniform || worn == hu.shoes || worn == hu.w_underwear || worn == hu.w_socks || worn == hu.w_shirt)
					continue
			entered.transferItemToLoc(worn)
			victim_belongings += worn
	chosen_pod.startExitSequence(chosen_pod)
	if(ishuman(entered))
		var/mob/living/carbon/human/targ = entered
		targ.dna?.species.give_important_for_life(targ)
	INVOKE_ASYNC(src, PROC_REF(aftermath_capture), entered, sc, contractor_success)

/datum/ransom_extraction/proc/aftermath_capture(mob/living/mob_captured, datum/syndicate_contract/contract, contractor_success)
	addtimer(CALLBACK(src, PROC_REF(return_ransom_victim), mob_captured), 4 MINUTES)
	if(mob_captured.stat != DEAD)
		mob_captured.reagents.add_reagent(/datum/reagent/medicine/regen_jelly, 20)
		mob_captured.flash_act()
		mob_captured.confused += 10
		mob_captured.blur_eyes(5)
		to_chat(mob_captured, "<span class='warning'>Вам не по себе...</span>")
		sleep(6 SECONDS)
		to_chat(mob_captured, "<span class='warning'>С этой капсуле с вами что-то сделали...</span>")
		mob_captured.Dizzy(35)
		sleep(6.5 SECONDS)
		to_chat(mob_captured, "<span class='warning'>В висках стучит... кажется, череп вот-вот треснет!</span>")
		mob_captured.flash_act()
		mob_captured.confused += 20
		mob_captured.blur_eyes(3)
		sleep(3 SECONDS)
		to_chat(mob_captured, "<span class='warning'>Виски набухли...</span>")
		sleep(10 SECONDS)
		mob_captured.flash_act()
		mob_captured.Unconscious(20 SECONDS)
		to_chat(mob_captured, "<span class='reallybig hypnophrase'>В голове отзывается тысяча голосов... <i>\"В твоей памяти хранилось много ценного — \
			благодарим за доступ. Срок твоей пользы истёк, тебя выкупят обратно на станцию. Мы всегда получаем свои кредиты — \
			осталось дождаться доставки...\"</i></span>")
		mob_captured.blur_eyes(10)
		mob_captured.Dizzy(15)
		mob_captured.confused += 20
	var/datum/bank_account/cargo = SSeconomy.get_dep_account(ACCOUNT_CAR)
	var/pay_points = (cargo && (cargo?.account_balance)) ? min(cargo.account_balance, ransom_credits) : 0
	if(cargo)
		cargo.adjust_money(min(pay_points, ransom_credits))
	priority_announce("Один из членов экипажа был захвачен корпорацией конкурентов - нам пришлось заплатить выкуп, чтобы вернуть его обратно. \
		Согласно нашей политике, мы взяли часть средств со счетов станции, чтобы компенсировать расходы.", null, "attention", null, "Отдел Защиты Активов Nanotrasen")
	sleep(3 SECONDS)
	if(contractor_success && contract)
		var/mob/living/carbon/human/human_c
		var/obj/item/card/id/id_card
		if(ishuman(contract.contract?.owner?.current))
			human_c = contract.contract.owner.current
			id_card = human_c.get_idcard(TRUE)
		if(id_card?.registered_account)
			id_card.registered_account.adjust_money(pay_points * 0.35)
			id_card.registered_account.bank_card_talk("Выкуп проведён, агент. Ваша доля зачислена. Текущий баланс: \
			[id_card.registered_account.account_balance] кр.", TRUE)
	var/obj/machinery/computer/piratepad_control/ppc = pirate_console?.resolve()
	if(ppc && pirate_gang_value)
		ppc.points += pirate_gang_value
	pirate_gang_value = 0
	pirate_console = null

/datum/ransom_extraction/proc/return_ransom_victim(mob/living/returning)
	if(QDELETED(returning))
		return
	var/list/landing_turfs = list()
	var/area/scan = linked_contract?.contract?.dropoff || return_target_area
	if(istype(scan))
		for(var/turf/foot in scan.contents)
			if(!isspaceturf(foot) && !isclosedturf(foot) && !is_blocked_turf(foot))
				landing_turfs += foot
	if(landing_turfs.len)
		var/turf/picked = pick(landing_turfs)
		var/area/pod_store = locate(/area/centcom/supplypod/podStorage) in GLOB.sortedAreas
		var/obj/structure/closet/supplypod/returner = new(pick(get_area_turfs(pod_store)))
		returner.bluespace = TRUE
		returner.explosionSize = list(0, 0, 0, 0)
		returner.style = STYLE_SYNDICATE
		do_sparks(8, FALSE, returning)
		returning.visible_message("<span class='notice'>[returning] внезапно исчезает...</span>")
		for(var/obj/item/held in returning)
			if(ishuman(returning))
				var/mob/living/carbon/human/ret_h = returning
				if(held == ret_h.w_uniform || held == ret_h.shoes || held == ret_h.w_underwear || held == ret_h.w_socks || held == ret_h.w_shirt)
					continue
			returning.dropItemToGround(held)
		for(var/obj/item/stow in victim_belongings)
			stow.forceMove(returner)
		returning.forceMove(returner)
		returning.flash_act()
		returning.blur_eyes(30)
		returning.Dizzy(35)
		returning.confused += 20
		new /obj/effect/pod_landingzone(picked, returner)
		victim_belongings = list()
	else
		to_chat(returning, "<span class='reallybig hypnophrase'>В голове шепчет хор голосов... <i>\"Похоже, ваша станция больше не примет капсулу возврата... \
			Вам суждено остаться здесь.\"</i></span>")
		if(iscarbon(returning))
			var/mob/living/carbon/retc = returning
			if(retc.can_heartattack())
				retc.set_heartattack(TRUE)
	var/datum/syndicate_contract/clearing = linked_contract
	if(clearing?.active_ransom == src)
		clearing.active_ransom = null
	linked_contract = null
	forced_pirate_victim = null
	qdel(src)
