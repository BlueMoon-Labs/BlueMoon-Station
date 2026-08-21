/// Marks someone as swimming. While swimming in deep pool water, a living mob
/// slowly tires out (stamina drain) and drowns if it can't keep its head above
/// the water - when prone, stunned or exhausted.
/datum/element/swimming
	element_flags = ELEMENT_DETACH

/datum/element/swimming/Attach(datum/target)
	if((. = ..()) == ELEMENT_INCOMPATIBLE)
		return
	if(!isliving(target))
		return ELEMENT_INCOMPATIBLE
	RegisterSignal(target, COMSIG_MOVABLE_MOVED, PROC_REF(check_valid))
	ADD_TRAIT(target, TRAIT_SWIMMING, TRAIT_SWIMMING)		//seriously there's only one way to get this
	var/mob/living/L = target
	L.apply_status_effect(/datum/status_effect/swimming)

/datum/element/swimming/Detach(datum/target)
	. = ..()
	UnregisterSignal(target, COMSIG_MOVABLE_MOVED)
	REMOVE_TRAIT(target, TRAIT_SWIMMING, TRAIT_SWIMMING)
	if(isliving(target))
		var/mob/living/L = target
		L.remove_status_effect(/datum/status_effect/swimming)

/datum/element/swimming/proc/check_valid(datum/source)
	var/mob/living/L = source
	if(!istype(L.loc, /turf/open/pool))
		source.RemoveElement(/datum/element/swimming)

/// Swimming physics for pool occupants: swimming tires you out, and once you
/// can't keep your head above the water you start drowning.
/datum/status_effect/swimming
	id = "swimming"
	alert_type = null
	duration = -1
	status_type = STATUS_EFFECT_UNIQUE
	tick_interval = 5 SECONDS
	/// Stamina drained every tick while the owner is in the pool.
	var/stamina_per_interval = 5
	/// Oxygen damage dealt every tick while the owner is drowning.
	var/oxygen_per_interval = 2
	/// Chance each tick to force a breath loss (gasp) while drowning.
	var/drowning_process_probability = 20

/datum/status_effect/swimming/tick()
	var/turf/T = get_turf(owner)
	if(!istype(T, /turf/open/pool) || !T.liquids)
		qdel(src)
		return
	if(owner.buckled)
		return
	if(owner.movement_type & (FLYING|FLOATING))
		return
	// Swimming tires you out.
	owner.adjustStaminaLoss(stamina_per_interval)
	// You can breathe while standing up with your head above the water.
	if(owner.mob_size >= MOB_SIZE_HUMAN && owner.body_position == STANDING_UP)
		return
	if(HAS_TRAIT(owner, TRAIT_NOBREATH))
		return
	if(iscarbon(owner))
		var/mob/living/carbon/C = owner
		if(C.internal)
			return
		var/obj/item/clothing/mask/wear_mask = C.get_item_by_slot(ITEM_SLOT_MASK)
		if(wear_mask && wear_mask.flags_cover & MASKCOVERSMOUTH)
			return
	// You're underwater and can't breathe: drown.
	owner.adjustOxyLoss(oxygen_per_interval)
	if(prob(drowning_process_probability))
		owner.losebreath += oxygen_per_interval
		owner.emote("cough")
