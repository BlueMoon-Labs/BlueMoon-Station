/obj/item/organ/heart/cybernetic/anomalock
	name = "voltaic combat cyberheart"
	desc = "A cutting-edge cyberheart, originally designed for Nanotrasen killsquad usage but later declassified for normal research. Voltaic technology allows the heart to keep the body upright in dire circumstances, alongside redirecting anomalous flux energy to fully shield the user from shocks and electro-magnetic pulses. Requires a refined Flux core as a power source."
	icon = 'modular_bluemoon/icons/obj/anomalock_heart.dmi'
	icon_state = "anomalock_heart"

	COOLDOWN_DECLARE(survival_cooldown)
	///Cooldown for the activation of the organ
	var/survival_cooldown_time = 5 MINUTES
	///The lightning effect on our mob when the implant is active
	var/mutable_appearance/lightning_overlay
	///how long the lightning lasts
	var/lightning_timer

	//---- Anomaly core variables:
	///The core item the organ runs off.
	var/obj/item/assembly/signaler/anomaly/core
	///Accepted types of anomaly cores.
	var/required_anomaly = /obj/item/assembly/signaler/anomaly/flux
	///If the core is removable once socketed.
	var/core_removable = TRUE

/obj/item/organ/heart/cybernetic/anomalock/Destroy()
	QDEL_NULL(core)
	return ..()

/obj/item/organ/heart/cybernetic/anomalock/Insert(mob/living/carbon/organ_mob, special, drop_if_replaced)
	. = ..()
	if(!. || !core || !organ_mob)
		return
	add_lightning_overlay(30 SECONDS)
	playsound(organ_mob, 'sound/magic/lightning_chargeup.ogg', 40)
	organ_mob.AddElement(/datum/element/empprotection, EMP_PROTECT_SELF|EMP_PROTECT_CONTENTS)
	RegisterSignal(organ_mob, COMSIG_ATOM_EMP_ACT, PROC_REF(on_emp_act))
	ADD_TRAIT(organ_mob, TRAIT_SHOCKIMMUNE, REF(src))

/obj/item/organ/heart/cybernetic/anomalock/Remove(special)
	var/mob/living/carbon/former_owner = owner
	. = ..()
	// Защиту снимаем всегда, даже если ядро уже вынули: иначе сигнал, элемент
	// и трейт остаются на владельце после извлечения импланта.
	if(former_owner && !QDELETED(former_owner))
		UnregisterSignal(former_owner, COMSIG_ATOM_EMP_ACT)
		former_owner.RemoveElement(/datum/element/empprotection, EMP_PROTECT_SELF|EMP_PROTECT_CONTENTS)
		REMOVE_TRAIT(former_owner, TRAIT_SHOCKIMMUNE, REF(src))
		if(lightning_overlay)
			former_owner.cut_overlay(lightning_overlay)
			lightning_overlay = null
	if(!core)
		return
	if(former_owner && !QDELETED(former_owner))
		tesla_zap(former_owner, 20, 2.5e5)

/obj/item/organ/heart/cybernetic/anomalock/attack(mob/living/target_mob, mob/living/user, attackchain_flags = NONE, damage_multiplier = 1)
	if(target_mob != user || !iscarbon(target_mob) || !core)
		return ..()
	if(user.do_afters && (user in user.do_afters))
		return ..()

	user.balloon_alert(user, "this will hurt...")
	to_chat(user, span_userdanger("Black cyberveins tear your skin apart, pulling the heart into your ribcage. This feels unwise.."))
	if(!do_after(user, 5 SECONDS, target = user))
		return ..()
	playsound(target_mob, 'sound/weapons/slice.ogg', 100, TRUE)
	user.temporarilyRemoveItemFromInventory(src, TRUE)
	Insert(user)
	user.apply_damage(100, BRUTE, BODY_ZONE_CHEST)
	user.emote("scream")
	return TRUE

/obj/item/organ/heart/cybernetic/anomalock/attack_self(mob/user)
	. = ..()
	if(.)
		return
	if(core)
		return attack(user, user)

/obj/item/organ/heart/cybernetic/anomalock/proc/on_emp_act(datum/source, severity)
	SIGNAL_HANDLER
	add_lightning_overlay(10 SECONDS)

/obj/item/organ/heart/cybernetic/anomalock/proc/add_lightning_overlay(time_to_last = 10 SECONDS)
	if(!owner)
		return
	if(lightning_overlay)
		lightning_timer = addtimer(CALLBACK(src, PROC_REF(clear_lightning_overlay)), time_to_last, (TIMER_UNIQUE|TIMER_OVERRIDE))
		return
	lightning_overlay = mutable_appearance(icon = 'modular_bluemoon/icons/effects/anomalock_lightning.dmi', icon_state = "lightning")
	owner.add_overlay(lightning_overlay)
	lightning_timer = addtimer(CALLBACK(src, PROC_REF(clear_lightning_overlay)), time_to_last, (TIMER_UNIQUE|TIMER_OVERRIDE))

/obj/item/organ/heart/cybernetic/anomalock/proc/clear_lightning_overlay()
	if(owner && lightning_overlay)
		owner.cut_overlay(lightning_overlay)
	lightning_overlay = null

/obj/item/organ/heart/cybernetic/anomalock/on_life(seconds, times_fired)
	. = ..()
	if(!core || !owner)
		return

	if(owner.blood_volume <= BLOOD_VOLUME_NORMAL)
		owner.blood_volume += 5 * seconds

	if(owner.health <= owner.crit_threshold)
		activate_survival(owner)

	if(times_fired % 10)
		return

	var/list/batteries = list()
	for(var/obj/item/stock_parts/cell/cell in owner.GetAllContents())
		if(cell.charge < cell.maxcharge)
			batteries += cell

	if(!length(batteries))
		return

	var/obj/item/stock_parts/cell/picked = pick(batteries)
	picked.give(picked.maxcharge * 0.1)

///Does a few things to try to help you live whatever you may be going through
/obj/item/organ/heart/cybernetic/anomalock/proc/activate_survival(mob/living/carbon/organ_owner)
	if(!COOLDOWN_FINISHED(src, survival_cooldown))
		return

	organ_owner.apply_status_effect(/datum/status_effect/voltaic_overdrive)
	add_lightning_overlay(30 SECONDS)
	COOLDOWN_START(src, survival_cooldown, survival_cooldown_time)
	addtimer(CALLBACK(src, PROC_REF(notify_cooldown), organ_owner), COOLDOWN_TIMELEFT(src, survival_cooldown))

///Alerts our owner that the organ is ready to do its thing again
/obj/item/organ/heart/cybernetic/anomalock/proc/notify_cooldown(mob/living/carbon/organ_owner)
	if(QDELETED(organ_owner))
		return
	balloon_alert(organ_owner, "your heart strengthens")
	playsound(organ_owner, 'sound/magic/lightning_chargeup.ogg', 40)

/obj/item/organ/heart/cybernetic/anomalock/attackby(obj/item/tool, mob/user, params)
	if(!istype(tool, required_anomaly))
		return ..()
	if(core)
		balloon_alert(user, "core already in!")
		return
	if(!user.transferItemToLoc(tool, src))
		return
	core = tool
	balloon_alert(user, "core installed")
	playsound(src, 'sound/machines/click.ogg', 30, TRUE)
	if(owner)
		ADD_TRAIT(owner, TRAIT_SHOCKIMMUNE, REF(src))
	update_icon_state()

/obj/item/organ/heart/cybernetic/anomalock/screwdriver_act(mob/living/user, obj/item/tool)
	. = ..()
	if(!core)
		balloon_alert(user, "no core!")
		return
	if(!core_removable)
		balloon_alert(user, "can't remove core!")
		return
	balloon_alert(user, "removing core...")
	if(!do_after(user, 3 SECONDS, target = src))
		balloon_alert(user, "interrupted!")
		return
	balloon_alert(user, "core removed")
	core.forceMove(drop_location())
	if(Adjacent(user) && !issilicon(user))
		user.put_in_hands(core)
	core = null
	if(owner)
		REMOVE_TRAIT(owner, TRAIT_SHOCKIMMUNE, REF(src))
	update_icon_state()

/obj/item/organ/heart/cybernetic/anomalock/update_icon_state()
	icon_state = initial(icon_state) + (core ? "-core" : "")

/obj/item/organ/heart/cybernetic/anomalock/prebuilt/Initialize(mapload)
	. = ..()
	core = new /obj/item/assembly/signaler/anomaly/flux(src)
	update_icon_state()

/datum/status_effect/voltaic_overdrive
	id = "voltaic_overdrive"
	duration = 30 SECONDS
	alert_type = /atom/movable/screen/alert/status_effect/anomalock_active

/datum/status_effect/voltaic_overdrive/tick()
	if(owner.health <= owner.crit_threshold)
		owner.heal_overall_damage(5, 5)
		owner.adjustOxyLoss(-5)
		owner.adjustToxLoss(-5)

/datum/status_effect/voltaic_overdrive/on_apply()
	. = ..()
	if(!owner)
		return
	owner.add_movespeed_mod_immunities(type, /datum/movespeed_modifier/damage_slowdown)
	owner.reagents.add_reagent(/datum/reagent/medicine/coagulant, 5)
	owner.add_filter("emp_shield", 2, outline_filter(1, "#639BFF"))
	to_chat(owner, span_userdanger("You feel a burst of energy! It's do or die!"))
	ADD_TRAIT(owner, TRAIT_NOSOFTCRIT, REF(src))
	ADD_TRAIT(owner, TRAIT_NOHARDCRIT, REF(src))
	ADD_TRAIT(owner, TRAIT_PAINKILLER, REF(src))

/datum/status_effect/voltaic_overdrive/on_remove()
	. = ..()
	if(!owner)
		return
	owner.remove_movespeed_mod_immunities(type, /datum/movespeed_modifier/damage_slowdown)
	owner.remove_filter("emp_shield")
	owner.balloon_alert(owner, "your heart weakens")
	REMOVE_TRAIT(owner, TRAIT_NOSOFTCRIT, REF(src))
	REMOVE_TRAIT(owner, TRAIT_NOHARDCRIT, REF(src))
	REMOVE_TRAIT(owner, TRAIT_PAINKILLER, REF(src))

/atom/movable/screen/alert/status_effect/anomalock_active
	name = "voltaic overdrive"
	icon = 'modular_bluemoon/icons/mob/anomalock_alert.dmi'
	icon_state = "anomalock_heart"
	desc = "Voltaic energy is flooding your muscles, keeping your body upright. You have 30 seconds before it falters!"
