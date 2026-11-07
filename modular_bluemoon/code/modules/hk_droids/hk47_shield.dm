/// Длины разовых анимаций разворота и удара в hk47_gear.dmi.
#define HK47_SHIELD_UP_TIME (0.5 SECONDS)
#define HK47_SHIELD_FLASH_TIME (0.5 SECONDS)
#define HK47_SHIELD_FLASH_COOLDOWN (0.2 SECONDS)
/// С этого числа попаданий HK хвастается щитом, когда тот гаснет.
#define HK47_SHIELD_BRAG_HITS 3

/// Энергощит HK: короткий всплеск брони шасси по кнопке; ЭМИ гасит его сразу.
/datum/component/hk47_shield
	dupe_mode = COMPONENT_DUPE_UNIQUE
	var/active = FALSE
	var/duration = HK47_SHIELD_DURATION
	var/datum/action/innate/hk47_shield/button
	/// Шасси, которому добавлена броня: при смене вида снимать её нужно с него же.
	var/datum/weakref/chassis_ref
	var/mutable_appearance/bubble
	var/mutable_appearance/flash
	var/collapse_timer
	var/ready_timer
	/// Сколько попаданий щит принял за последний подъём: для лога и отчёта игроку.
	var/hits_taken = 0
	COOLDOWN_DECLARE(recharge)
	COOLDOWN_DECLARE(flash_cooldown)

/datum/component/hk47_shield/Initialize()
	if(!is_species(parent, /datum/species/ipc/hk))
		return COMPONENT_INCOMPATIBLE

/datum/component/hk47_shield/RegisterWithParent()
	button = new(src)
	button.Grant(parent)
	RegisterSignal(parent, COMSIG_ATOM_EMP_ACT, PROC_REF(on_emp))
	RegisterSignal(parent, COMSIG_LIVING_DEATH, PROC_REF(on_death))

/datum/component/hk47_shield/UnregisterFromParent()
	collapse(silent = TRUE)
	deltimer(ready_timer)
	ready_timer = null
	UnregisterSignal(parent, list(COMSIG_ATOM_EMP_ACT, COMSIG_LIVING_DEATH))
	QDEL_NULL(button)

/datum/component/hk47_shield/proc/raise()
	var/mob/living/carbon/human/droid = parent
	if(active || droid.stat != CONSCIOUS)
		return FALSE
	if(!COOLDOWN_FINISHED(src, recharge))
		droid.balloon_alert(droid, "щит заряжается: [DisplayTimeText(COOLDOWN_TIMELEFT(src, recharge))]")
		return FALSE
	if(droid.nutrition - HK47_SHIELD_NUTRITION < HK47_UPGRADE_MIN_NUTRITION)
		droid.balloon_alert(droid, "не хватает заряда")
		return FALSE
	var/datum/species/ipc/hk/chassis = droid.dna?.species
	if(!istype(chassis))
		return FALSE
	var/datum/component/hk47_disguise/disguise = droid.GetComponent(/datum/component/hk47_disguise)
	disguise?.drop(broken = TRUE)
	droid.adjust_nutrition(-HK47_SHIELD_NUTRITION)
	active = TRUE
	hits_taken = 0
	chassis.armor += HK47_SHIELD_ARMOR
	chassis_ref = WEAKREF(chassis)
	set_bubble("hk47_shield_up")
	addtimer(CALLBACK(src, PROC_REF(settle_bubble)), HK47_SHIELD_UP_TIME)
	RegisterSignal(droid, COMSIG_MOB_APPLY_DAMAGE, PROC_REF(on_hit))
	playsound(droid, 'modular_bluemoon/sound/hk_droids/hk47_shield_up.ogg', 50, FALSE)
	droid.visible_message(span_warning("Вокруг [droid] вспыхивает янтарный энергощит!"), ignored_mobs = droid)
	hk47_quip(droid, "shield_up")
	hk47_upgrade_voice(droid, "hk47_prejudice")
	droid.balloon_alert(droid, "щит на [DisplayTimeText(duration)]")
	collapse_timer = addtimer(CALLBACK(src, PROC_REF(collapse)), duration, TIMER_STOPPABLE)
	COOLDOWN_START(src, recharge, HK47_SHIELD_COOLDOWN)
	deltimer(ready_timer)
	ready_timer = addtimer(CALLBACK(src, PROC_REF(announce_ready)), HK47_SHIELD_COOLDOWN, TIMER_STOPPABLE)
	return TRUE

/datum/component/hk47_shield/proc/set_bubble(state)
	var/mob/living/droid = parent
	if(bubble)
		droid.cut_overlay(bubble)
	bubble = state ? mutable_appearance('modular_bluemoon/icons/obj/hk_droids/hk47_gear.dmi', state, ABOVE_MOB_LAYER) : null
	if(bubble)
		droid.add_overlay(bubble)

/datum/component/hk47_shield/proc/settle_bubble()
	if(active)
		set_bubble("hk47_shield")

/// Попадание по поднятому щиту: вспышка и треск поля, не чаще раза в пару десятых секунды.
/datum/component/hk47_shield/proc/on_hit(datum/source, damage, damagetype)
	SIGNAL_HANDLER
	if(!active || damage <= 0 || (damagetype != BRUTE && damagetype != BURN))
		return
	hits_taken++
	if(!COOLDOWN_FINISHED(src, flash_cooldown))
		return
	COOLDOWN_START(src, flash_cooldown, HK47_SHIELD_FLASH_COOLDOWN)
	var/mob/living/droid = parent
	if(!flash)
		flash = mutable_appearance('modular_bluemoon/icons/obj/hk_droids/hk47_gear.dmi', "hk47_shield_hit", ABOVE_MOB_LAYER)
		droid.add_overlay(flash)
	addtimer(CALLBACK(src, PROC_REF(clear_flash)), HK47_SHIELD_FLASH_TIME, TIMER_UNIQUE | TIMER_OVERRIDE)
	var/static/list/hit_sounds = list(
		'modular_bluemoon/sound/hk_droids/hk47_shield_hit_1.ogg',
		'modular_bluemoon/sound/hk_droids/hk47_shield_hit_2.ogg',
		'modular_bluemoon/sound/hk_droids/hk47_shield_hit_3.ogg',
	)
	playsound(droid, pick(hit_sounds), 45, TRUE)

/datum/component/hk47_shield/proc/clear_flash()
	if(!flash)
		return
	var/mob/living/droid = parent
	droid.cut_overlay(flash)
	flash = null

/// broken - щит сорван ЭМИ, а не погас сам.
/datum/component/hk47_shield/proc/collapse(silent = FALSE, broken = FALSE)
	if(!active)
		return FALSE
	active = FALSE
	deltimer(collapse_timer)
	collapse_timer = null
	var/datum/species/ipc/hk/chassis = chassis_ref?.resolve()
	if(chassis)
		chassis.armor -= HK47_SHIELD_ARMOR
	chassis_ref = null
	var/mob/living/droid = parent
	UnregisterSignal(droid, COMSIG_MOB_APPLY_DAMAGE)
	set_bubble(null)
	clear_flash()
	if(silent)
		return TRUE
	if(broken)
		do_sparks(4, FALSE, droid)
		playsound(droid, 'modular_bluemoon/sound/hk_droids/hk47_shield_break.ogg', 55, FALSE)
		droid.visible_message(span_danger("Энергощит вокруг [droid] срывается с треском!"), ignored_mobs = droid)
		hk47_quip(droid, "shield_break")
	else
		playsound(droid, 'modular_bluemoon/sound/hk_droids/hk47_shield_down.ogg', 45, FALSE)
		droid.visible_message(span_notice("Энергощит вокруг [droid] гаснет."), ignored_mobs = droid)
		if(hits_taken >= HK47_SHIELD_BRAG_HITS)
			hk47_quip(droid, "shield_held", hits_taken)
		droid.balloon_alert(droid, "щит погас, повтор через [DisplayTimeText(COOLDOWN_TIMELEFT(src, recharge))]")
	return TRUE

/datum/component/hk47_shield/proc/announce_ready()
	ready_timer = null
	var/mob/living/droid = parent
	if(droid.stat == DEAD)
		return
	droid.playsound_local(get_turf(droid), 'modular_bluemoon/sound/hk_droids/hk47_shield_ready.ogg', 40, FALSE)
	droid.balloon_alert(droid, "щит заряжен")

/datum/component/hk47_shield/proc/on_emp(datum/source, severity)
	SIGNAL_HANDLER
	collapse(broken = TRUE)

/datum/component/hk47_shield/proc/on_death(datum/source)
	SIGNAL_HANDLER
	collapse()

/datum/action/innate/hk47_shield
	name = "HK Energy Shield"
	desc = "Поднять энергощит: броня шасси выше, пока он держится. Стоит заряда, перезаряжается, видно всем, срывает маскировку; ЭМИ гасит щит сразу."
	icon_icon = 'modular_bluemoon/icons/obj/hk_droids/hk47_gear.dmi'
	button_icon_state = "hk47_shield"
	background_icon_state = "bg_tech"

/datum/action/innate/hk47_shield/Activate()
	var/datum/component/hk47_shield/shield = target
	shield.raise()

#undef HK47_SHIELD_UP_TIME
#undef HK47_SHIELD_FLASH_TIME
#undef HK47_SHIELD_FLASH_COOLDOWN
#undef HK47_SHIELD_BRAG_HITS
