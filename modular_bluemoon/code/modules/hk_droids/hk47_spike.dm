/datum/antagonist/hk47
	/// Доступы, считанные щупом с чужих карт: list("label", "access"), старые первыми.
	var/list/access_profiles = list()

/// Кнопка щупа появляется с первым модулем, которому он нужен.
/datum/antagonist/hk47/proc/grant_spike(mob/living/body)
	if(!body || (locate(/datum/action/innate/hk47_spike) in body.actions))
		return
	var/datum/action/innate/hk47_spike/button = new(src)
	button.Grant(body)

/datum/antagonist/hk47/proc/revoke_spike(mob/living/body)
	if(!body)
		return
	for(var/datum/action/innate/hk47_spike/button in body.actions)
		qdel(button)
	for(var/obj/item/hk47_spike/spike in body.held_items)
		qdel(spike)

/datum/antagonist/hk47/proc/needs_spike()
	return upgrades["door_hack"] || upgrades["access_skimmer"]

/// Код техтоннелей и доступы считанных карт одной связкой.
/datum/antagonist/hk47/proc/chassis_access()
	var/list/access = list(ACCESS_MAINT_TUNNELS)
	for(var/list/profile as anything in access_profiles)
		access |= profile["access"]
	return access

/datum/antagonist/hk47/proc/spike_door_refusal(obj/machinery/door/door)
	if(!door.density)
		return "дверь уже открыта."
	if(door.welded)
		return "дверь заварена, щуп не берёт сварной шов."
	if(door.locked)
		return "дверь на болтах, щуп их не поднимет."
	return null

/// Взлом на месте: искры, треск и огни щупа в панели выдают HK, болты и сварка держат.
/datum/antagonist/hk47/proc/spike_door(obj/machinery/door/door, obj/item/hk47_spike/spike)
	var/mob/living/carbon/human/droid = owner?.current
	if(!droid)
		return FALSE
	if(!upgrades["door_hack"])
		to_chat(droid, span_warning("Утверждение: для взлома нужен модуль «Взломщик шлюзов»."))
		return FALSE
	var/reason = spike_door_refusal(door)
	if(reason)
		door.balloon_alert(droid, reason)
		playsound(door, 'modular_bluemoon/sound/hk_droids/hk47_hack_fail.ogg', 35, TRUE, SILENCED_SOUND_EXTRARANGE)
		return FALSE
	if(droid.nutrition - HK47_SPIKE_HACK_NUTRITION < HK47_UPGRADE_MIN_NUTRITION)
		droid.balloon_alert(droid, "не хватает заряда")
		return FALSE
	droid.visible_message(span_warning("[droid] вгоняет щуп в панель [door], из-под неё сыплются искры!"), ignored_mobs = droid)
	playsound(door, 'modular_bluemoon/sound/hk_droids/hk47_hack.ogg', 40, FALSE)
	hk_voice("hk47_unlock_begin")
	hk47_quip(droid, "hack_start")
	do_sparks(3, FALSE, door)
	var/obj/effect/temp_visual/hk47_hack/hack_lights = new(get_turf(door), spike.hack_time)
	var/hacked = do_after(droid, spike.hack_time, door) && spike_still_held(droid, spike)
	qdel(hack_lights)
	reason = hacked ? spike_door_refusal(door) : "взлом прерван"
	if(reason)
		spike_door_failed(door, reason)
		return FALSE
	droid.adjust_nutrition(-HK47_SPIKE_HACK_NUTRITION)
	do_sparks(3, FALSE, door)
	door.AddComponent(/datum/component/hk47_hack_trace)
	if(!door.open(2))
		spike_door_failed(door, "створки заклинило")
		return FALSE
	playsound(door, 'modular_bluemoon/sound/hk_droids/hk47_hack_done.ogg', 50, TRUE)
	door.balloon_alert(droid, "замок взломан")
	hk_voice("hk47_unlock_success")
	hk47_quip(droid, "hack_done")
	log_game("[key_name(droid)] взламывает щупом HK-47 [door] в [AREACOORD(door)].")
	return TRUE

/datum/antagonist/hk47/proc/spike_door_failed(obj/machinery/door/door, reason)
	playsound(door, 'modular_bluemoon/sound/hk_droids/hk47_hack_fail.ogg', 45, TRUE)
	if(owner?.current)
		door.balloon_alert(owner.current, reason)
	hk_voice("hk47_unlock_failed")
	hk47_quip(owner?.current, "hack_fail")

/// Карта человека считывается, пока он стоит вплотную; скан и звук видит и слышит только HK.
/datum/antagonist/hk47/proc/spike_skim(atom/target, obj/item/hk47_spike/spike)
	var/mob/living/carbon/human/droid = owner?.current
	if(!droid)
		return FALSE
	if(!upgrades["access_skimmer"])
		to_chat(droid, span_warning("Утверждение: для копии доступа нужен модуль «Считыватель доступа»."))
		return FALSE
	var/obj/item/card/id/card = skim_card_of(target)
	if(!card)
		target.balloon_alert(droid, "ID-карты нет")
		return FALSE
	var/delay = ishuman(target) ? spike.skim_time : spike.card_time
	var/client/viewer = droid.client
	var/image/scan = image('modular_bluemoon/icons/obj/hk_droids/hk47_gear.dmi', target, "hk47_skim", ABOVE_MOB_LAYER)
	viewer?.images += scan
	droid.playsound_local(get_turf(droid), 'modular_bluemoon/sound/hk_droids/hk47_skim.ogg', 40, FALSE)
	hk_voice("hk47_scan")
	var/skimmed = do_after(droid, delay, target) && spike_still_held(droid, spike) && skim_card_of(target) == card
	viewer?.images -= scan
	if(!skimmed)
		target.balloon_alert(droid, "считывание сорвано")
		return FALSE
	store_access_profile(card)
	droid.playsound_local(get_turf(droid), 'modular_bluemoon/sound/hk_droids/hk47_skim_done.ogg', 40, FALSE)
	target.balloon_alert(droid, "доступ записан")
	hk47_quip(droid, "skim_done")
	return TRUE

/// Роль и щуп в руке после ожидания: перепрошивка посреди взлома убирает и то, и другое.
/datum/antagonist/hk47/proc/spike_still_held(mob/living/droid, obj/item/hk47_spike/spike)
	return !QDELETED(src) && owner?.current == droid && !QDELETED(spike) && spike.loc == droid

/datum/antagonist/hk47/proc/skim_card_of(atom/target)
	if(ishuman(target))
		var/mob/living/carbon/human/victim = target
		return victim.wear_id?.GetID()
	if(isitem(target))
		var/obj/item/thing = target
		return thing.GetID()
	return null

/datum/antagonist/hk47/proc/store_access_profile(obj/item/card/id/card)
	var/label = "[card.registered_name || "без имени"][card.assignment ? " ([card.assignment])" : ""]"
	for(var/list/profile as anything in access_profiles)
		if(profile["label"] == label)
			access_profiles -= list(profile)
			break
	var/list/access = card.GetAccess()
	access_profiles += list(list("label" = label, "access" = access.Copy()))
	while(length(access_profiles) > HK47_ACCESS_PROFILES)
		access_profiles.Cut(1, 2)
	to_chat(owner.current, span_notice("Утверждение: доступ [label] записан в память шасси. Профилей: [length(access_profiles)] из [HK47_ACCESS_PROFILES]."))
	log_game("[key_name(owner)] копирует щупом HK-47 доступ карты [label].")

/datum/action/innate/hk47_spike
	name = "HK Security Spike"
	desc = "Выдвинуть щуп в свободную руку или убрать его. Щупом по шлюзу или стеклянной двери - взлом (модуль «Взломщик шлюзов»), по ID-карте или по человеку вплотную - копия доступа (модуль «Считыватель доступа»)."
	icon_icon = 'modular_bluemoon/icons/obj/hk_droids/hk47_gear.dmi'
	button_icon_state = "hk47_spike"
	background_icon_state = "bg_tech"

/datum/action/innate/hk47_spike/Activate()
	var/mob/living/carbon/human/droid = owner
	var/obj/item/hk47_spike/spike = locate() in droid.held_items
	if(spike)
		qdel(spike)
		playsound(droid, 'modular_bluemoon/sound/hk_droids/hk47_spike_retract.ogg', 35, TRUE, SILENCED_SOUND_EXTRARANGE)
		droid.balloon_alert(droid, "щуп убран")
		return
	spike = new(droid)
	if(!droid.put_in_hands(spike))
		qdel(spike)
		droid.balloon_alert(droid, "руки заняты")
		return
	playsound(droid, 'modular_bluemoon/sound/hk_droids/hk47_spike_extend.ogg', 35, TRUE, SILENCED_SOUND_EXTRARANGE)
	droid.balloon_alert(droid, "щуп выдвинут")

/obj/item/hk47_spike
	name = "HK security spike"
	desc = "Выдвижной щуп-дешифратор из запястья HK-47: вскрывает замки шлюзов и считывает ID-карты мешков с мясом."
	icon = 'modular_bluemoon/icons/obj/hk_droids/hk47_gear.dmi'
	icon_state = "hk47_spike"
	item_state = "hk47_spike"
	lefthand_file = 'modular_bluemoon/icons/obj/hk_droids/hk47_gear_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/obj/hk_droids/hk47_gear_righthand.dmi'
	item_flags = DROPDEL
	w_class = WEIGHT_CLASS_SMALL
	var/hack_time = HK47_SPIKE_HACK_TIME
	var/card_time = HK47_SPIKE_CARD_TIME
	var/skim_time = HK47_SPIKE_SKIM_TIME

/obj/item/hk47_spike/Initialize(mapload)
	. = ..()
	ADD_TRAIT(src, TRAIT_NODROP, HAND_REPLACEMENT_TRAIT)

/obj/item/hk47_spike/pre_attack(atom/target, mob/living/user, params, attackchain_flags, damage_multiplier)
	var/datum/antagonist/hk47/hunter = user.mind?.has_antag_datum(/datum/antagonist/hk47)
	if(!hunter)
		return ..()
	if(istype(target, /obj/machinery/door/airlock) || istype(target, /obj/machinery/door/window))
		INVOKE_ASYNC(hunter, TYPE_PROC_REF(/datum/antagonist/hk47, spike_door), target, src)
		return STOP_ATTACK_PROC_CHAIN
	if(ishuman(target) || isitem(target))
		INVOKE_ASYNC(hunter, TYPE_PROC_REF(/datum/antagonist/hk47, spike_skim), target, src)
		return STOP_ATTACK_PROC_CHAIN
	return ..()

/// Огни щупа в панели двери на время взлома.
/obj/effect/temp_visual/hk47_hack
	icon = 'modular_bluemoon/icons/obj/hk_droids/hk47_gear.dmi'
	icon_state = "hk47_hack"
	layer = ABOVE_MOB_LAYER
	randomdir = FALSE

/obj/effect/temp_visual/hk47_hack/Initialize(mapload, lifetime)
	if(lifetime)
		duration = lifetime
	return ..()

/// След взлома щупом: оплавленная панель на двери видна при осмотре, пока не остынет.
/datum/component/hk47_hack_trace
	dupe_mode = COMPONENT_DUPE_UNIQUE
	var/mutable_appearance/scorch
	var/expire_timer

/datum/component/hk47_hack_trace/Initialize()
	if(!istype(parent, /obj/machinery/door))
		return COMPONENT_INCOMPATIBLE
	expire_timer = addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(qdel), src), HK47_HACK_TRACE_TIME, TIMER_STOPPABLE)

/datum/component/hk47_hack_trace/RegisterWithParent()
	var/obj/machinery/door/door = parent
	scorch = mutable_appearance('modular_bluemoon/icons/obj/hk_droids/hk47_gear.dmi', "hk47_hack_scorch", door.layer + 0.01)
	door.add_overlay(scorch)
	RegisterSignal(door, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine))

/datum/component/hk47_hack_trace/UnregisterFromParent()
	var/obj/machinery/door/door = parent
	door.cut_overlay(scorch)
	scorch = null
	UnregisterSignal(door, COMSIG_PARENT_EXAMINE)

/datum/component/hk47_hack_trace/Destroy(force, silent)
	deltimer(expire_timer)
	return ..()

/datum/component/hk47_hack_trace/proc/on_examine(datum/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	examine_list += span_warning("Панель доступа разворочена: замок оплавлен узким щупом, вокруг янтарная окалина. Так вскрывают двери дроиды-ассасины серии HK.")
