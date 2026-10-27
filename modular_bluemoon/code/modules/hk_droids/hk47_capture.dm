/// Цель не сопротивляется: крит, наручники, истощение выносливости, оглушение, паралич или сон.
/proc/hk47_capture_ready(mob/living/victim)
	if(!isliving(victim) || victim.stat == DEAD)
		return FALSE
	if(victim.stat != CONSCIOUS)
		return TRUE
	var/mob/living/carbon/carbon_victim = victim
	if(istype(carbon_victim) && carbon_victim.handcuffed)
		return TRUE
	return IS_STAMCRIT(victim) || victim.IsStun() || victim.IsParalyzed() || victim.IsUnconscious() || victim.IsSleeping()

/// Капсула захвата HK-47: без выкупа с карго и с коротким возвратом цели. Цель держится слабой ссылкой.
/datum/ransom_extraction/hk47
	var/datum/weakref/hunter_ref
	var/datum/weakref/contract_ref
	var/datum/weakref/victim_ref
	var/datum/weakref/pod_ref
	var/loaded = FALSE
	var/recalled = FALSE
	var/recall_timer

/datum/ransom_extraction/hk47/Destroy()
	deltimer(recall_timer)
	return ..()

/datum/ransom_extraction/hk47/proc/start_for_hk47(datum/antagonist/hk47/hunter, datum/hk_contract/contract, mob/living/carbon/human/victim, turf/landing)
	if(QDELETED(victim) || !landing)
		return FALSE
	hunter_ref = WEAKREF(hunter)
	contract_ref = WEAKREF(contract)
	victim_ref = WEAKREF(victim)
	return_target_area = pick_ransom_return_area()
	return launch_extraction(landing, victim)

/datum/ransom_extraction/hk47/launch_extraction(turf/empty_pod_turf, mob/living/carbon/human/expected_victim)
	var/area/pod_storage_area = locate(/area/centcom/supplypod/podStorage) in GLOB.sortedAreas
	if(QDELETED(expected_victim) || !empty_pod_turf || !pod_storage_area)
		return FALSE
	var/obj/structure/closet/supplypod/extractionpod/pod = new(pick(get_area_turfs(pod_storage_area)))
	pod.stay_after_drop = TRUE
	pod.reversing = TRUE
	pod.explosionSize = list(0, 0, 0, 0)
	pod.leavingSound = 'sound/effects/podwoosh.ogg'
	pod_ref = WEAKREF(pod)
	RegisterSignal(pod, COMSIG_ATOM_ENTERED, PROC_REF(enter_extraction_pod))
	RegisterSignal(pod, COMSIG_PARENT_QDELETING, PROC_REF(on_pod_deleted))
	new /obj/effect/pod_landingzone(empty_pod_turf, pod)
	var/landing_delay = (pod.delays[POD_TRANSIT] + pod.delays[POD_FALLING] + pod.delays[POD_OPENING] + 5) * 0.1 SECONDS
	addtimer(CALLBACK(src, PROC_REF(force_pirate_victim), expected_victim, pod), landing_delay, TIMER_DELETE_ME)
	recall_timer = addtimer(CALLBACK(src, PROC_REF(recall_empty_pod)), landing_delay + HK47_CAPTURE_POD_WAIT, TIMER_STOPPABLE)
	return TRUE

/// Почему капсула не примет груз: контракт уже закрыт, цель мертва или без игрока; null - примет.
/datum/ransom_extraction/hk47/proc/cargo_refusal(mob/living/victim)
	var/datum/antagonist/hk47/hunter = hunter_ref?.resolve()
	var/datum/hk_contract/contract = contract_ref?.resolve()
	if(!hunter || !contract || contract != hunter.active_contract)
		return "контракт захвата закрыт, заказчик груз не примет."
	return hunter.capture_cargo_refusal(victim)

/datum/ransom_extraction/hk47/proc/notify_hunter(text)
	var/datum/antagonist/hk47/hunter = hunter_ref?.resolve()
	if(hunter?.owner?.current)
		to_chat(hunter.owner.current, span_warning("Утверждение: [text]"))

/// Цель, которую успели оттащить или которая очнулась, капсула сама не заберёт: её заталкивают внутрь руками.
/datum/ransom_extraction/hk47/force_pirate_victim(mob/living/carbon/human/human_victim, obj/structure/closet/supplypod/extractionpod/extraction)
	if(QDELETED(human_victim) || QDELETED(extraction))
		return
	var/refusal = cargo_refusal(human_victim)
	if(refusal)
		notify_hunter("[refusal] Капсула ждёт [DisplayTimeText(HK47_CAPTURE_POD_WAIT)] и улетит пустой.")
		return
	if(get_dist(human_victim, extraction) > 1 || !hk47_capture_ready(human_victim))
		notify_hunter("цель не у капсулы. Обездвижьте её и перетащите мышью на капсулу - так её затолкают внутрь.")
		return
	return ..()

/// Груз принимается только от цели ещё открытого контракта, живой и с игроком; иначе цель выпадает обратно, капсула ждёт дальше.
/datum/ransom_extraction/hk47/enter_extraction_pod(atom/source, mob/living/entered)
	if(!isliving(entered) || entered != victim_ref?.resolve())
		return
	var/refusal = cargo_refusal(entered)
	if(refusal)
		notify_hunter(refusal)
		addtimer(CALLBACK(src, PROC_REF(eject_refused), entered, source), 0, TIMER_DELETE_ME)
		return
	loaded = TRUE
	deltimer(recall_timer)
	recall_timer = null
	UnregisterSignal(source, COMSIG_ATOM_ENTERED)
	INVOKE_ASYNC(src, PROC_REF(finalize_captured), entered, source)

/datum/ransom_extraction/hk47/proc/eject_refused(mob/living/refused, obj/structure/closet/supplypod/extractionpod/pod)
	if(!QDELETED(refused) && !QDELETED(pod) && refused.loc == pod)
		refused.forceMove(pod.drop_location())

/datum/ransom_extraction/hk47/proc/recall_empty_pod()
	recall_timer = null
	var/obj/structure/closet/supplypod/extractionpod/pod = pod_ref?.resolve()
	if(loaded || !pod)
		return
	recalled = TRUE
	pod.reversing = FALSE
	pod.startExitSequence(pod)

/datum/ransom_extraction/hk47/proc/on_pod_deleted(datum/source)
	SIGNAL_HANDLER
	deltimer(recall_timer)
	recall_timer = null
	if(loaded)
		return
	var/datum/antagonist/hk47/hunter = hunter_ref?.resolve()
	hunter?.capture_pod_lost(contract_ref?.resolve(), recalled ? "капсула захвата не дождалась цели и улетела пустой." : "капсулу захвата разбили.")

/datum/ransom_extraction/hk47/finalize_captured(mob/living/entered, obj/structure/closet/supplypod/extractionpod/chosen_pod)
	var/datum/antagonist/hk47/hunter = hunter_ref?.resolve()
	var/datum/hk_contract/contract = contract_ref?.resolve()
	. = ..()
	hunter?.capture_loaded(contract, entered)

/datum/ransom_extraction/hk47/aftermath_capture(mob/living/mob_captured, datum/syndicate_contract/contract, contractor_success)
	addtimer(CALLBACK(src, PROC_REF(return_ransom_victim), mob_captured), HK47_CAPTURE_RETURN_TIME)
	if(mob_captured.stat == DEAD)
		return
	mob_captured.reagents?.add_reagent(/datum/reagent/medicine/regen_jelly, 20)
	mob_captured.flash_act()
	mob_captured.confused += 10
	to_chat(mob_captured, span_warning("Капсула уносит вас со станции. Чьи-то механические пальцы обшаривают карманы, ровный голос задаёт вопросы."))
	to_chat(mob_captured, span_notice("Заказчик дроида получил что хотел. Через [DisplayTimeText(HK47_CAPTURE_RETURN_TIME)] капсула вернёт вас на станцию."))
