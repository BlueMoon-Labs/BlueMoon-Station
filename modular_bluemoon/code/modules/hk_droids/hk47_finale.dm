/datum/antagonist/hk47
	var/extracting = FALSE
	var/extracted = FALSE
	var/datum/weakref/extraction_pod_ref
	COOLDOWN_DECLARE(extraction_retry_cooldown)

/datum/antagonist/hk47/proc/extraction_refusal(mob/living/droid)
	if(extracted)
		return "эвакуация уже выполнена."
	if(contracts_done < HK47_CONTRACTS_TO_WIN)
		return "эвакуация откроется после [HK47_CONTRACTS_TO_WIN] выполненных контрактов, выполнено [contracts_done]."
	if(extracting)
		return "сигнал эвакуации уже идёт."
	if(!COOLDOWN_FINISHED(src, extraction_retry_cooldown))
		return "маяк перезаряжается после прерванного сигнала, ещё [DisplayTimeText(COOLDOWN_TIMELEFT(src, extraction_retry_cooldown))]."
	if(extraction_pod_ref?.resolve())
		return "капсула эвакуации уже вызвана."
	if(droid.incapacitated())
		return "сигнал невозможен в текущем состоянии."
	if(!borders_space(get_turf(droid)))
		return "встаньте у клетки с открытым космосом: капсула садится только у края станции."
	return null

/// Эвакуация после трёх контрактов: стоять у космоса, пока идёт сигнал, затем капсула забирает HK. Спит на сигнале.
/datum/antagonist/hk47/proc/request_extraction()
	var/mob/living/droid = owner?.current
	if(!droid)
		return FALSE
	var/refusal = extraction_refusal(droid)
	if(refusal)
		to_chat(droid, span_warning("Утверждение: [refusal]"))
		return FALSE
	extracting = TRUE
	droid.visible_message(span_danger("[droid] замирает у края станции, из его вокабулятора идёт ровный писк маяка."), span_notice("Сигнал эвакуации: не двигайтесь [DisplayTimeText(HK47_EXTRACTION_TIME)]."))
	var/obj/effect/temp_visual/hk47_beacon/beacon = announce_extraction(droid)
	var/channeled = channel_extraction(droid)
	extracting = FALSE
	if(!QDELETED(beacon))
		qdel(beacon)
	if(!channeled)
		COOLDOWN_START(src, extraction_retry_cooldown, HK47_EXTRACTION_RETRY_COOLDOWN)
		to_chat(droid, span_warning("Утверждение: сигнал эвакуации прерван. Маяк перезарядится через [DisplayTimeText(HK47_EXTRACTION_RETRY_COOLDOWN)]."))
		return FALSE
	refusal = extraction_refusal(droid)
	if(refusal)
		to_chat(droid, span_warning("Утверждение: [refusal]"))
		return FALSE
	if(!call_extraction_pod(get_turf(droid)))
		return FALSE
	hk_voice("hk47_rejoining", forced = TRUE)
	to_chat(droid, span_notice("Утверждение: капсула эвакуации в пути. Оставайтесь на месте."))
	return TRUE

/datum/antagonist/hk47/proc/channel_extraction(mob/living/droid)
	return do_after(droid, HK47_EXTRACTION_TIME, droid)

/// Финал на виду: разыскиваемого HK выдаёт перехваченный маяк с меткой посадки, HK с закрытой лицензией провожает ЦК, остальные уходят молча.
/datum/antagonist/hk47/proc/announce_extraction(mob/living/droid)
	var/area_name = get_area_name(droid, TRUE)
	if(status == HK47_STATUS_OUTLAW)
		station_announce("Перехвачен маяк эвакуации дроида-ассасина HK: [area_name]. Капсула заберёт его через [DisplayTimeText(HK47_EXTRACTION_TIME)], если сигнал не прервать.", "Перехват", ANNOUNCER_INTERCEPT)
		to_chat(droid, span_userdanger("Утверждение: маяк перехвачен, станция знает, где вы. Пеленгатор СБ видит маяк даже сквозь маскировку."))
		log_game("[key_name(owner)]: маяк эвакуации HK-47 объявлен станции, [area_name].")
		return new /obj/effect/temp_visual/hk47_beacon(get_turf(droid))
	if(license_number)
		station_announce("Подрядчик HK-47, лицензия № [license_number], завершил работу и покидает [station_name()]. Капсула ЦК заберёт его через [DisplayTimeText(HK47_EXTRACTION_TIME)].", "Центральное командование")
	return null

/datum/antagonist/hk47/proc/borders_space(turf/spot)
	if(!spot)
		return FALSE
	for(var/turf/nearby as anything in RANGE_TURFS(1, spot))
		if(isspaceturf(nearby))
			return TRUE
	return FALSE

/datum/antagonist/hk47/proc/call_extraction_pod(turf/landing)
	var/obj/structure/closet/supplypod/hk47/extraction/pod = make_extraction_pod()
	new /obj/effect/pod_landingzone(landing, pod)
	return pod

/datum/antagonist/hk47/proc/make_extraction_pod()
	var/obj/structure/closet/supplypod/hk47/extraction/pod = new(null, owner.current)
	extraction_pod_ref = WEAKREF(pod)
	RegisterSignal(pod, COMSIG_ATOM_ENTERED, PROC_REF(on_extraction_pod_entered))
	RegisterSignal(pod, COMSIG_PARENT_QDELETING, PROC_REF(on_extraction_pod_gone))
	return pod

/datum/antagonist/hk47/proc/on_extraction_pod_entered(datum/source, atom/movable/arrived)
	SIGNAL_HANDLER
	if(arrived != owner?.current)
		return
	UnregisterSignal(source, list(COMSIG_ATOM_ENTERED, COMSIG_PARENT_QDELETING))
	finish_extraction()

/datum/antagonist/hk47/proc/on_extraction_pod_gone(datum/source)
	SIGNAL_HANDLER
	extraction_pod_ref = null
	if(!extracted)
		to_chat(owner?.current, span_warning("Утверждение: капсула эвакуации ушла без вас. Подайте сигнал снова."))

/datum/antagonist/hk47/proc/finish_extraction()
	extracted = TRUE
	extraction_pod_ref = null
	close_all_work("снят при эвакуации")
	owner.force_escaped = TRUE
	var/datum/objective/hk47_extract/extract = locate() in objectives
	extract?.completed = TRUE
	to_chat(owner.current, span_greentext("Утверждение: эвакуация завершена, работа на этой станции закрыта."))
	to_chat(owner.current, span_notice("Роль выполнена и засчитана: тело можно покинуть (Ghost)."))
	log_game("[key_name(owner)] эвакуирован капсулой HK-47 после [contracts_done] контрактов.")
	message_admins("[ADMIN_LOOKUPFLW(owner.current)] эвакуирован капсулой HK-47 после [contracts_done] контрактов.")

/// Капсула берёт только живого HK-47; без него улетает пустой и исчезает, с ним остаётся в доке ЦК.
/obj/structure/closet/supplypod/hk47/extraction
	reversing = TRUE
	effectQuiet = FALSE
	leavingSound = 'sound/effects/podwoosh.ogg'
	delays = list(POD_TRANSIT = 3 SECONDS, POD_FALLING = 4, POD_OPENING = 1 SECONDS, POD_LEAVING = 3 SECONDS)
	var/datum/weakref/passenger_ref

/obj/structure/closet/supplypod/hk47/extraction/Initialize(mapload, mob/living/passenger)
	. = ..(mapload)
	passenger_ref = WEAKREF(passenger)

/obj/structure/closet/supplypod/hk47/extraction/insertion_allowed(atom/to_insert)
	var/mob/living/passenger = passenger_ref?.resolve()
	return to_insert == passenger && passenger.stat != DEAD

/obj/structure/closet/supplypod/hk47/extraction/handleReturnAfterDeparting(atom/movable/holder = src)
	var/mob/living/passenger = passenger_ref?.resolve()
	if(!passenger || passenger.loc != src)
		qdel(src)
		return
	reversing = FALSE
	holder.pixel_z = initial(holder.pixel_z)
	holder.alpha = initial(holder.alpha)
	forceMove(GLOB.areas_by_type[/area/centcom/supplypod/podStorage])

/datum/antagonist/hk47/proc/on_master_changed(mob/living/source, datum/mind/new_master, datum/mind/old_master)
	SIGNAL_HANDLER
	if(!new_master || new_master == owner)
		return
	INVOKE_ASYNC(src, PROC_REF(on_reprogrammed), new_master)

/// Перепрошивка: роль снимается, контракты гаснут. Хозяин из экипажа снимает розыск, хозяина-антагониста СБ не узнаёт.
/datum/antagonist/hk47/proc/on_reprogrammed(datum/mind/new_master)
	var/datum/mind/droid_mind = owner
	var/mob/living/droid = droid_mind.current
	hk_voice("hk47_purchased", forced = TRUE)
	var/mob/living/carbon/human/chassis_owner = droid
	var/datum/species/ipc/hk/chassis = istype(chassis_owner) ? chassis_owner.dna?.species : null
	if(istype(chassis))
		chassis.queue_voice_line(chassis_owner, voice_lines["hk47_ready"], HK47_REPROGRAM_READY_DELAY)
	close_all_work("снят перепрошивкой")
	var/obj/item/card/id/hk47_license/license = license_ref?.resolve()
	var/license_was_valid = license && !license.revoked && !license.expired
	if(license && !license.revoked)
		license.expired = TRUE
	if(!hk_master_is_antagonist(new_master))
		note_security_record("Перепрошит, хозяин - [new_master.name]. Розыск снят.", SEC_RECORD_STATUS_NONE)
	else if(license_was_valid)
		note_security_record("Лицензия № [license_number] больше не действует: связь с подрядчиком потеряна.")
	to_chat(droid, span_userdanger("Вы больше не наёмник: контракты, терминал и эвакуация отключены, прежние заказы и цели больше не ваши."))
	report_reprogram(droid, new_master)
	droid_mind.remove_antag_datum(type)

/datum/antagonist/hk47/proc/report_reprogram(mob/living/droid, datum/mind/new_master)
	log_game("[key_name(droid)] перепрошит, HK-47 больше не антагонист, хозяин [key_name(new_master)].")
	message_admins("[ADMIN_LOOKUPFLW(droid)] перепрошит: роль HK-47 снята, хозяин [key_name_admin(new_master)].")

/datum/species/ipc/hk/proc/queue_voice_line(mob/living/carbon/human/speaker, voice, delay)
	addtimer(CALLBACK(src, PROC_REF(play_voice_line), speaker, voice), delay)

/datum/species/ipc/hk/proc/play_voice_line(mob/living/carbon/human/speaker, voice)
	if(QDELETED(speaker) || speaker.dna?.species != src)
		return
	hk_voice_line(speaker, voice)

/// Метка посадки капсулы эвакуации раскрытого HK-47: видна всем, пока идёт сигнал.
/obj/effect/temp_visual/hk47_beacon
	name = "HK extraction beacon"
	icon = 'icons/obj/supplypods_32x32.dmi'
	icon_state = "LZ"
	layer = PROJECTILE_HIT_THRESHHOLD_LAYER
	randomdir = FALSE
	duration = HK47_EXTRACTION_TIME

/obj/effect/temp_visual/hk47_beacon/Initialize(mapload)
	. = ..()
	animate(src, alpha = HK47_BEACON_DIM_ALPHA, time = HK47_BEACON_PULSE, loop = -1)
	animate(alpha = 255, time = HK47_BEACON_PULSE)
