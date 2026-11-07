#define EVIDENCE_VALUE_CACHE (30 SECONDS)
#define EVIDENCE_SOUND_COOLDOWN (1 SECONDS)

/obj/machinery/evidence_locker
	name = "evidence locker"
	desc = "Хранилище улик NT. Принимает от СБ только контрабанду и держит её до суда; переданная NT улика уходит со станции, а бюджет СБ получает награду."
	icon = 'icons/obj/machines/economy/evidence_locker.dmi'
	icon_state = "locker"
	density = TRUE
	req_access = list(ACCESS_SECURITY)
	circuit = /obj/item/circuitboard/machine/evidence_locker
	var/list/stored = list()
	/// Оценка улик для окна, пересчитывается не чаще EVIDENCE_VALUE_CACHE
	var/list/value_cache = list()
	COOLDOWN_DECLARE(value_cache_cooldown)
	COOLDOWN_DECLARE(sound_cooldown)

/obj/machinery/evidence_locker/update_icon_state()
	icon_state = (machine_stat & BROKEN) ? "locker_broken" : "locker"
	return ..()

/// Анимация хранилища всегда, звук отказа и приёма не чаще EVIDENCE_SOUND_COOLDOWN, звук передачи NT - всегда.
/obj/machinery/evidence_locker/proc/locker_feedback(animation, soundfile, vary = FALSE, always = FALSE)
	flick(animation, src)
	if(!always && !COOLDOWN_FINISHED(src, sound_cooldown))
		return
	COOLDOWN_START(src, sound_cooldown, EVIDENCE_SOUND_COOLDOWN)
	play_locker_sound(soundfile, vary)

/obj/machinery/evidence_locker/proc/play_locker_sound(soundfile, vary)
	playsound(src, soundfile, 40, vary)

/obj/machinery/evidence_locker/proc/deny(mob/user)
	to_chat(user, span_warning("Нет доступа."))
	locker_feedback("locker_locked", 'sound/economy/locker_clunk.ogg', TRUE)

/// Кредитов бюджету СБ за кредит оценки улики: цена работы из настроек и рынок контрабанды.
/proc/econ_evidence_rate()
	return (SSeconomy.settings.work_prices[WORK_SEC_CONTRABAND] || 0) * econ_sale_factor(COMMODITY_CONTRABAND)

/obj/machinery/evidence_locker/examine(mob/user)
	. = ..()
	var/datum/economy_settings/settings = SSeconomy.settings
	. += span_notice("Внутри улик: [length(stored)].")
	if(!pays_here())
		. += span_warning("Хранилище стоит вне станции: NT за переданные отсюда улики не платит.")
		return
	var/rate = econ_evidence_rate()
	. += span_notice("За переданную NT контрабанду бюджет СБ получает по текущему рынку контрабанды [round(settings.contraband_value_per_tc * rate)] кр. за каждый телекристалл её цены в аплинке Синдиката ([round(settings.contraband_value_default * rate)] кр., если цены нет). Офицер, передавший улику, получает премию [settings.work_personal_share]% от суммы; вместе с премией выплата не превышает нынешнюю цену предмета на чёрном рынке, а за купленное там или в автомате - [round(econ_import_resale_factor() * 100)]% уплаченного.")
	. += span_notice("Переданные NT улики и изъятое таможней уходят с рынка сектора: цены контрабанды и чёрного рынка растут.")
	. += span_notice("Предметы, которые экипаж получает и без Синдиката (фабрикаторы, карго, автоматы, призы, снаряжение должностей и лоадаут), контрабандой не считаются.")
	. += span_notice("За час NT оплачивает изъятий не больше чем на [settings.contraband_cap_hour] кр., в этом часе осталось [SSeconomy.contraband_cap_left()] кр. Улика, на которую не хватает остатка, ждёт в хранилище; улику дороже часового лимита NT оплачивает по нему.")

/obj/machinery/evidence_locker/attackby(obj/item/thing, mob/living/user, params)
	if(user.a_intent == INTENT_HARM)
		return ..()
	if(!econ_is_contraband(thing) && (thing.tool_behaviour || istype(thing, /obj/item/storage/part_replacer)))
		return ..()
	if(store(thing, user))
		return TRUE
	return ..()

/obj/machinery/evidence_locker/tool_act(mob/living/user, obj/item/tool, params)
	if(user.a_intent != INTENT_HARM && econ_is_contraband(tool))
		return NONE
	return ..()

/obj/machinery/evidence_locker/screwdriver_act(mob/living/user, obj/item/tool)
	if(!allowed(user))
		deny(user)
		return TRUE
	. = default_deconstruction_screwdriver(user, icon_state, icon_state, tool)
	update_appearance()

/obj/machinery/evidence_locker/crowbar_act(mob/living/user, obj/item/tool)
	return default_deconstruction_crowbar(tool)

/obj/machinery/evidence_locker/Exited(atom/movable/gone, atom/newloc)
	. = ..()
	stored -= gone
	value_cache -= gone

/obj/machinery/evidence_locker/proc/pays_here()
	var/turf/locker_turf = get_turf(src)
	return locker_turf && is_station_level(locker_turf.z)

/obj/machinery/evidence_locker/proc/store(obj/item/thing, mob/living/user)
	if(!allowed(user))
		deny(user)
		return FALSE
	if(!GLOB.econ_contraband_built)
		to_chat(user, span_warning("[src] ещё сверяет каталог NT, попробуйте позже."))
		return FALSE
	if(!econ_is_contraband(thing))
		to_chat(user, span_warning("[src] принимает только контрабанду."))
		return FALSE
	if(!user.transferItemToLoc(thing, src))
		return FALSE
	stored += thing
	locker_feedback("locker_accept", 'sound/economy/locker_confirm.ogg')
	to_chat(user, span_notice("[thing] помещён в хранилище улик."))
	log_game("[key_name(user)] поместил [thing] ([thing.type]) в хранилище улик в [AREACOORD(src)]")
	return TRUE

/// Выплата бюджету СБ за улику: оценка по цене работы, не больше часового лимита NT.
/obj/machinery/evidence_locker/proc/payout_for(obj/item/thing)
	var/price = SSeconomy.settings.work_prices[WORK_SEC_CONTRABAND] || 0
	return min(round(econ_contraband_value(thing) * price), SSeconomy.settings.contraband_cap_hour)

/// Передаёт улику NT: предмет уничтожается, СБ получает оплату работы. Возвращает выплату отделу.
/obj/machinery/evidence_locker/proc/hand_over(obj/item/thing, mob/living/user)
	if(!(thing in stored) || !allowed(user))
		return 0
	if(!pays_here())
		to_chat(user, span_warning("Вне станции NT улики не принимает."))
		return 0
	var/payout = payout_for(thing)
	var/cap_left = SSeconomy.contraband_cap_left()
	if(payout > cap_left)
		to_chat(user, span_warning("NT оплатит эту улику в [payout] кр., а лимита на оплату изъятий в этом часе осталось [cap_left] кр.: улика остаётся в хранилище."))
		return 0
	var/price = SSeconomy.settings.work_prices[WORK_SEC_CONTRABAND]
	log_game("[key_name(user)] передал NT улику [thing] ([thing.type]) из хранилища в [AREACOORD(src)], выплата [payout] кр.")
	stored -= thing
	econ_release_non_contraband(thing, drop_location())
	qdel(thing)
	locker_feedback("locker_handover", 'sound/economy/locker_clunk.ogg', TRUE, TRUE)
	if(payout <= 0)
		return 0
	. = SSeconomy.record_work(ACCOUNT_SEC, WORK_SEC_CONTRABAND, payout / price, user, memo = "Изъятие передано NT")
	SSeconomy.note_contraband_paid(.)
	SSmarket.note_seizure(.)

/obj/machinery/evidence_locker/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "EvidenceLocker", name)
		ui.open()

/obj/machinery/evidence_locker/ui_data(mob/user)
	var/datum/economy_settings/settings = SSeconomy.settings
	var/rate = econ_evidence_rate()
	var/can_use = allowed(user)
	var/list/items = list()
	if(can_use)
		if(COOLDOWN_FINISHED(src, value_cache_cooldown))
			COOLDOWN_START(src, value_cache_cooldown, EVIDENCE_VALUE_CACHE)
			value_cache.Cut()
		for(var/obj/item/thing as anything in stored)
			if(isnull(value_cache[thing]))
				value_cache[thing] = payout_for(thing)
			items += list(list("ref" = REF(thing), "name" = thing.name, "value" = value_cache[thing]))
	return list(
		"can_use" = can_use,
		"pays_here" = pays_here(),
		"catalog_ready" = GLOB.econ_contraband_built,
		"count" = length(stored),
		"items" = items,
		"per_tc" = round(settings.contraband_value_per_tc * rate),
		"default_value" = round(settings.contraband_value_default * rate),
		"premium_percent" = settings.work_personal_share,
		"resale_percent" = round(econ_import_resale_factor() * 100),
		"cap_hour" = settings.contraband_cap_hour,
		"cap_left" = SSeconomy.contraband_cap_left(),
	)

/obj/machinery/evidence_locker/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	var/mob/living/user = usr
	if(!isliving(user) || !istext(params["ref"]))
		return FALSE
	var/obj/item/thing = locate(params["ref"]) in stored
	if(!thing)
		return TRUE
	if(!allowed(user))
		deny(user)
		return TRUE
	switch(action)
		if("hand_over")
			var/thing_name = thing.name
			var/paid = hand_over(thing, user)
			if(QDELETED(thing))
				to_chat(user, span_notice("[thing_name]: улика передана NT, бюджет СБ получил [paid] кр."))
			return TRUE
		if("eject")
			eject(thing, user)
			return TRUE
	return FALSE

/// Возвращает улику из хранилища в руки сотруднику СБ.
/obj/machinery/evidence_locker/proc/eject(obj/item/thing, mob/living/user)
	if(!(thing in stored) || !allowed(user))
		return FALSE
	thing.forceMove(drop_location())
	user.put_in_hands(thing)
	log_game("[key_name(user)] забрал [thing] ([thing.type]) из хранилища улик в [AREACOORD(src)]")
	return TRUE

/obj/item/circuitboard/machine/evidence_locker
	name = "Evidence Locker (Machine Board)"
	icon_state = "security"
	build_path = /obj/machinery/evidence_locker
	req_components = list(/obj/item/stock_parts/matter_bin = 2)

#undef EVIDENCE_SOUND_COOLDOWN
#undef EVIDENCE_VALUE_CACHE
