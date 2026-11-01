/datum/component/protean_limb
	dupe_mode = COMPONENT_DUPE_UNIQUE
	var/dissolve_timer
	var/damage_timer
	var/datum/weakref/suit_ref
	var/old_health
	var/list/old_descriptions
	var/old_status

/datum/component/protean_limb/Initialize()
	if(!isbodypart(parent))
		return COMPONENT_INCOMPATIBLE
	var/obj/item/bodypart/limb = parent
	old_health = limb.max_damage
	old_status = limb.status
	limb.status = BODYPART_HYBRID
	var/list/descriptions = list(
		"light_brute_msg" = "слегка деформирована",
		"medium_brute_msg" = "заметно деформирована",
		"heavy_brute_msg" = "сильно деформирована",
		"light_burn_msg" = "слегка опалена",
		"medium_burn_msg" = "заметно опалена",
		"heavy_burn_msg" = "сильно опалена")
	old_descriptions = list()
	for(var/key in descriptions)
		old_descriptions[key] = limb.vars[key]
		limb.vars[key] = descriptions[key]
	switch(limb.body_zone)
		if(BODY_ZONE_HEAD)
			limb.max_damage = 120
		if(BODY_ZONE_CHEST)
			limb.max_damage = 250
		else
			limb.max_damage = 40

/datum/component/protean_limb/RegisterWithParent()
	RegisterSignal(parent, COMSIG_PROTEAN_LIMB_DAMAGE, PROC_REF(on_damage))
	RegisterSignal(parent, COMSIG_PROTEAN_LIMB_REMOVED, PROC_REF(on_removed))
	RegisterSignal(parent, COMSIG_PROTEAN_LIMB_OWNER, PROC_REF(on_attached))

/datum/component/protean_limb/UnregisterFromParent()
	UnregisterSignal(parent, list(COMSIG_PROTEAN_LIMB_DAMAGE, COMSIG_PROTEAN_LIMB_REMOVED, COMSIG_PROTEAN_LIMB_OWNER))

/datum/component/protean_limb/Destroy()
	deltimer(dissolve_timer)
	deltimer(damage_timer)
	suit_ref = null
	var/obj/item/bodypart/limb = parent
	if(!QDELING(limb))
		limb.max_damage = old_health
		limb.status = old_status
		for(var/key in old_descriptions)
			limb.vars[key] = old_descriptions[key]
	old_descriptions = null
	return ..()

/datum/component/protean_limb/proc/on_damage(obj/item/bodypart/limb)
	SIGNAL_HANDLER
	if(limb.get_damage() < limb.max_damage || damage_timer)
		return
	damage_timer = addtimer(CALLBACK(src, PROC_REF(break_limb)), 0, TIMER_STOPPABLE)

/datum/component/protean_limb/proc/break_limb()
	damage_timer = null
	var/obj/item/bodypart/limb = parent
	if(limb.owner && limb.get_damage() >= limb.max_damage)
		limb.dismember()

/datum/component/protean_limb/proc/on_removed(obj/item/bodypart/limb, special)
	SIGNAL_HANDLER
	if(special || dissolve_timer)
		return
	dissolve_timer = addtimer(CALLBACK(src, PROC_REF(dissolve)), PROTEAN_LIMB_TIME, TIMER_STOPPABLE)

/datum/component/protean_limb/proc/on_attached(obj/item/bodypart/limb)
	SIGNAL_HANDLER
	deltimer(dissolve_timer)
	dissolve_timer = null
	if(limb.owner && !isprotean(limb.owner))
		qdel(src)

/datum/component/protean_limb/proc/dissolve()
	dissolve_timer = null
	var/obj/item/bodypart/limb = parent
	if(limb.owner)
		return
	var/turf/ground = get_turf(limb)
	if(ground)
		playsound(ground, 'sound/effects/wounds/sizzle2.ogg', PROTEAN_EFFECT_VOLUME, TRUE)
		var/obj/effect/decal/cleanable/blood/blood = new(ground)
		blood.add_atom_colour(BLOOD_COLOR_IRON, FIXED_COLOUR_PRIORITY)
	qdel(limb)

/datum/component/protean_limb/proc/get_suit()
	return suit_ref?.resolve()

/datum/component/protean_limb/proc/set_suit(obj/item/mod/control/pre_equipped/protean/suit)
	suit_ref = suit ? WEAKREF(suit) : null

/proc/get_protean_modsuit(mob/living/carbon/target)
	var/obj/item/bodypart/chest = target?.get_bodypart(BODY_ZONE_CHEST)
	var/datum/component/protean_limb/component = chest?.GetComponent(/datum/component/protean_limb)
	return component?.get_suit()

/proc/set_protean_modsuit(mob/living/carbon/target, obj/item/mod/control/pre_equipped/protean/suit)
	var/obj/item/bodypart/chest = target?.get_bodypart(BODY_ZONE_CHEST)
	var/datum/component/protean_limb/component = chest?.GetComponent(/datum/component/protean_limb)
	component?.set_suit(suit)
