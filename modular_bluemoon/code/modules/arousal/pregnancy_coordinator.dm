// BlueMoon: one signal subscriber per pregnant carrier, independent egg components.
// The egg components keep their own stage, DNA, shell and hatch state.
/mob/living
	var/tmp/datum/pregnancy_coordinator/pregnancy_coordinator

/datum/pregnancy_coordinator
	var/mob/living/carrier
	var/list/datum/component/pregnancy/pregnancies = list()
	var/shared_revealed = FALSE
	var/late_mood_applied = FALSE
	var/breast_size_applied = 0

/datum/pregnancy_coordinator/New(mob/living/new_carrier)
	. = ..()
	if(!new_carrier || QDELETED(new_carrier))
		qdel(src)
		return
	carrier = new_carrier
	carrier.pregnancy_coordinator = src
	RegisterSignal(carrier, COMSIG_MOB_DEATH, PROC_REF(on_carrier_death))
	RegisterSignal(carrier, COMSIG_LIVING_BIOLOGICAL_LIFE, PROC_REF(on_life))
	RegisterSignal(carrier, COMSIG_HEALTH_SCAN, PROC_REF(on_scan))
	RegisterSignal(carrier, COMSIG_MOB_APPLY_DAMAGE, PROC_REF(on_damage))
	RegisterSignal(carrier, COMSIG_MOB_CLIMAX, PROC_REF(on_climax))
	RegisterSignal(carrier, COMSIG_PARENT_QDELETING, PROC_REF(on_carrier_deleted))

/datum/pregnancy_coordinator/Destroy()
	if(!QDELETED(carrier))
		UnregisterSignal(carrier, list(COMSIG_MOB_DEATH, COMSIG_LIVING_BIOLOGICAL_LIFE, COMSIG_HEALTH_SCAN, COMSIG_MOB_APPLY_DAMAGE, COMSIG_MOB_CLIMAX, COMSIG_PARENT_QDELETING))
		if(carrier.pregnancy_coordinator == src)
			carrier.pregnancy_coordinator = null
	for(var/datum/component/pregnancy/P as anything in pregnancies)
		if(!QDELETED(P) && P.coordinator == src)
			P.coordinator = null
	pregnancies.Cut()
	carrier = null
	return ..()

/datum/pregnancy_coordinator/proc/add_pregnancy(datum/component/pregnancy/P)
	if(QDELETED(P) || !carrier || (P in pregnancies))
		return
	var/was_empty = !length(pregnancies)
	pregnancies += P
	P.coordinator = src
	if(was_empty)
		P.generic_pragency_start()
	update_shared_effects()

/datum/pregnancy_coordinator/proc/remove_pregnancy(datum/component/pregnancy/P)
	if(!(P in pregnancies))
		return
	pregnancies -= P
	if(P.coordinator == src)
		P.coordinator = null
	if(length(pregnancies))
		update_shared_effects()
		return
	// Only the final embryo may end the pregnancy and reset estrous.
	if(carrier && !QDELETED(carrier))
		P.generic_pragency_end()
		// Release signals and pointer immediately: qdel itself is deferred.
		UnregisterSignal(carrier, list(COMSIG_MOB_DEATH, COMSIG_LIVING_BIOLOGICAL_LIFE, COMSIG_HEALTH_SCAN, COMSIG_MOB_APPLY_DAMAGE, COMSIG_MOB_CLIMAX, COMSIG_PARENT_QDELETING))
		if(carrier.pregnancy_coordinator == src)
			carrier.pregnancy_coordinator = null
	qdel(src)

/datum/pregnancy_coordinator/proc/update_shared_effects()
	if(QDELETED(carrier) || !length(pregnancies))
		return
	var/max_growth = 0
	var/any_revealed = FALSE
	var/any_late = FALSE
	for(var/datum/component/pregnancy/P as anything in pregnancies)
		if(QDELETED(P))
			continue
		max_growth = max(max_growth, P.added_size)
		if(P.stage >= 2)
			any_revealed = TRUE
		if(P.stage > 3 && P.oviposition)
			any_late = TRUE
	if(any_revealed && !shared_revealed)
		shared_revealed = TRUE
		carrier.apply_status_effect(/datum/status_effect/pregnancy)
		carrier.apply_status_effect(/datum/status_effect/lactation)
	if(any_late && !late_mood_applied && !HAS_TRAIT(carrier, TRAIT_COMMON_PREGNANCY))
		late_mood_applied = TRUE
		SEND_SIGNAL(carrier, COMSIG_ADD_MOOD_EVENT, "pregnancy", /datum/mood_event/pregnant_negative)
	else if(!any_late && late_mood_applied)
		late_mood_applied = FALSE
		SEND_SIGNAL(carrier, COMSIG_CLEAR_MOOD_EVENT, "pregnancy")
	update_breast_growth(max_growth)

/datum/pregnancy_coordinator/proc/update_breast_growth(target_size)
	if(!ishuman(carrier) || !carrier.client?.prefs?.pregnancy_breast_growth)
		return
	var/mob/living/carbon/human/H = carrier
	var/obj/item/organ/genital/breasts/current = H.getorganslot(ORGAN_SLOT_BREASTS)
	if(!current || QDELETED(current))
		return
	// Already-applied stage growth is not retroactively granted to a
	// replaced organ. Reinsertions must not duplicate the same stage bonus.
	if(target_size > breast_size_applied)
		current.modify_size(target_size - breast_size_applied)
		breast_size_applied = target_size

/datum/pregnancy_coordinator/proc/on_life(datum/source, seconds)
	SIGNAL_HANDLER
	if(QDELETED(carrier))
		return
	// Snapshot protects iteration when an egg is moved, laid or destroyed.
	for(var/datum/component/pregnancy/P as anything in pregnancies.Copy())
		if(!QDELETED(P) && P.carrier == carrier)
			P.handle_life(seconds)
	update_shared_effects()

/datum/pregnancy_coordinator/proc/on_climax(datum/source, datum/reagents/senders_cum, atom/target, obj/item/organ/genital/sender, obj/item/organ/genital/receiver, spill)
	SIGNAL_HANDLER
	var/list/datum/component/pregnancy/ready = list()
	for(var/datum/component/pregnancy/P as anything in pregnancies)
		if(QDELETED(P) || P.carrier != carrier || !P.oviposition || P.stage < 2)
			continue
		if(isgenital(P.container))
			var/obj/item/organ/genital/stuff = P.container
			if(stuff != sender && stuff.linked_organ != sender)
				continue
		ready += P
	if(length(ready))
		var/datum/component/pregnancy/chosen = pick(ready)
		return chosen.on_climax(source, senders_cum, target, sender, receiver, spill)

/datum/pregnancy_coordinator/proc/on_scan(datum/source, mob/user)
	SIGNAL_HANDLER
	if(length(pregnancies))
		to_chat(user, span_notice("<b>Обнаружена беременность!</b>"))

/datum/pregnancy_coordinator/proc/on_damage(datum/source, damage, damagetype, def_zone)
	SIGNAL_HANDLER
	if(def_zone != BODY_ZONE_PRECISE_GROIN || damagetype != BRUTE || damage <= 5 || !prob(40) || !length(pregnancies))
		return
	var/datum/component/pregnancy/P = pick(pregnancies)
	if(!QDELETED(P))
		P.fetus_mortus()

/datum/pregnancy_coordinator/proc/on_carrier_death()
	SIGNAL_HANDLER
	var/list/copy = pregnancies.Copy()
	if(!length(copy))
		return
	var/datum/component/pregnancy/first = copy[1]
	if(!QDELETED(first))
		first.fetus_mortus()
	for(var/i = 2, i <= length(copy), i++)
		var/datum/component/pregnancy/P = copy[i]
		if(!QDELETED(P))
			qdel(P)

/datum/pregnancy_coordinator/proc/on_carrier_deleted()
	SIGNAL_HANDLER
	qdel(src)

// Common pregnancy retains independent embryos but provides a birth verb
// instead of waiting forever for an egg-laying path forbidden by its own quirk.
/mob/living/carbon/human/verb/bluemoon_give_birth()
	set name = "Give Birth"
	set category = "IC"
	if(!HAS_TRAIT(src, TRAIT_COMMON_PREGNANCY) || !pregnancy_coordinator)
		return
	var/list/datum/component/pregnancy/ready = list()
	for(var/datum/component/pregnancy/P as anything in pregnancy_coordinator.pregnancies)
		if(!QDELETED(P) && P.stage >= P.max_stage && P.oviposition)
			ready += P
	if(!length(ready))
		to_chat(src, span_notice("Беременность ещё не достигла срока родов."))
		return
	var/datum/component/pregnancy/chosen = pick(ready)
	if(!COOLDOWN_FINISHED(chosen, hatch_request_cooldown))
		return
	to_chat(src, span_notice("Вы готовитесь к родам."))
	INVOKE_ASYNC(chosen, TYPE_PROC_REF(/datum/component/pregnancy, hatch), null, null, src, null)
