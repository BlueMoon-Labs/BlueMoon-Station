#define TRANSFORM_TRAITS list(TRAIT_RESISTLOWPRESSURE, TRAIT_RESISTHIGHPRESSURE, TRAIT_RESISTHEAT, TRAIT_RESISTCOLD)
#define SUIT_TRANSFORMATION_DURATION (1.2 SECONDS)

/obj/item/organ/brain/protean
	name = "protean core"
	desc = "An advanced positronic brain, typically found in the core of a protean."
	icon = PROTEAN_ORGAN_SPRITE
	icon_state = "posi1"
	zone = BODY_ZONE_CHEST
	organ_flags = ORGAN_SYNTHETIC | ORGAN_NANOMACHINE
	status = ORGAN_ROBOTIC

	var/dead = FALSE
	var/transform_cycle = 0
	var/mob/living/carbon/transform_user
	var/obj/item/mod/control/pre_equipped/protean/transform_suit
	var/user_invisibility
	var/suit_invisibility
	var/transform_delay = 5 SECONDS
	var/transform_animation = 1.2 SECONDS
	var/rebuild_time = 30 SECONDS
	var/rebuilding = FALSE

	var/revive_timer_id

	var/retreat_timer_id

	var/list/limb_cache
	COOLDOWN_DECLARE(message_cooldown)
	COOLDOWN_DECLARE(refactory_cooldown)
	COOLDOWN_DECLARE(orchestrator_cooldown)

/obj/item/organ/brain/protean/Destroy(force)
	end_transform()
	set_transform_traits(FALSE)
	deltimer(revive_timer_id)
	deltimer(retreat_timer_id)
	limb_cache = null
	return ..()

/obj/item/organ/brain/protean/Insert(mob/living/carbon/receiver, special = FALSE, no_id_transfer = FALSE, drop_if_replaced = TRUE)
	. = ..()
	if(owner != receiver)
		return
	if(!isprotean(receiver))
		addtimer(CALLBACK(src, PROC_REF(reject_from_body), receiver), 1 SECONDS)
		return
	receiver.SetStun(0)
	RegisterSignal(receiver, COMSIG_LIVING_DEATH, PROC_REF(on_owner_death))
	RegisterSignal(receiver, COMSIG_MOVABLE_MOVED, PROC_REF(on_owner_moved))
	RegisterSignal(receiver, COMSIG_PROTEAN_LIMB_ATTACHED, PROC_REF(on_limb_attached))
	RegisterSignal(receiver, COMSIG_MOB_GHOSTIZE, PROC_REF(on_owner_dnr))
	cache_limbs(receiver)
	var/obj/item/mod/control/pre_equipped/protean/suit = get_protean_modsuit(receiver)
	if(suit && receiver.loc == suit)
		receiver.Stun(INFINITY, ignore_canstun = TRUE)
		set_transform_traits(TRUE)
		on_owner_moved(receiver)

	if(receiver.stat == DEAD && !dead)
		retreat_timer_id = addtimer(CALLBACK(src, PROC_REF(emergency_retreat)), 0, TIMER_STOPPABLE)

/obj/item/organ/brain/protean/Remove(special = FALSE, no_id_transfer = FALSE)
	end_transform()
	rebuilding = FALSE
	var/mob/living/carbon/brain_owner = owner
	var/obj/item/mod/control/pre_equipped/protean/suit = get_protean_modsuit(brain_owner)
	suit?.stop_servo()
	set_transform_traits(FALSE)
	if(istype(brain_owner?.loc, /obj/item/mod/control/pre_equipped/protean))
		UnregisterSignal(brain_owner.loc, COMSIG_MOVABLE_MOVED)
	deltimer(revive_timer_id)
	deltimer(retreat_timer_id)
	revive_timer_id = null
	retreat_timer_id = null
	. = ..()
	if(!brain_owner)
		return
	if(istype(brain_owner.remote_control, /obj/item/mod/control/pre_equipped/protean))
		brain_owner.remote_control = null
	if(isprotean(brain_owner) && !QDELING(brain_owner) && !special)
		brain_owner.Stun(INFINITY, ignore_canstun = TRUE)
	UnregisterSignal(brain_owner, list(COMSIG_LIVING_DEATH, COMSIG_MOVABLE_MOVED, COMSIG_PROTEAN_LIMB_ATTACHED, COMSIG_MOB_GHOSTIZE))

/obj/item/organ/brain/protean/proc/on_owner_dnr(mob/living/source, can_reenter)
	SIGNAL_HANDLER
	if(can_reenter)
		return
	var/obj/item/mod/control/pre_equipped/protean/suit = get_protean_modsuit(source)
	suit?.set_distress_signal(FALSE)

/obj/item/organ/brain/protean/proc/reject_from_body(mob/living/carbon/body)
	if(isnull(owner) || owner != body)
		return
	Remove()
	forceMove(get_turf(body))
	to_chat(body, span_danger("The nanomachine core is incompatible with your body!"))
	balloon_alert_to_viewers("rejected!", vision_distance = 1)

/obj/item/organ/brain/protean/var/static/list/cached_visual_vars = list(
	"base_bp_icon", "species_id", "no_update", "species_color", "body_gender",
	"body_markings_list", "markings_color", "use_digitigrade", "digitigrade_type"
)

/obj/item/organ/brain/protean/proc/cache_limbs(mob/living/carbon/target)
	LAZYINITLIST(limb_cache)
	for(var/obj/item/bodypart/limb as anything in target.bodyparts)
		limb_cache[limb.body_zone] = snapshot_limb(limb)

/obj/item/organ/brain/protean/proc/on_limb_attached(mob/living/carbon/source, obj/item/bodypart/new_limb, special)
	SIGNAL_HANDLER
	LAZYINITLIST(limb_cache)
	limb_cache[new_limb.body_zone] = snapshot_limb(new_limb)

/obj/item/organ/brain/protean/proc/snapshot_limb(obj/item/bodypart/limb)
	var/list/data = list("type" = limb.type)
	for(var/visual_var in cached_visual_vars)
		var/list/value = limb.vars[visual_var]
		data[visual_var] = islist(value) ? value.Copy() : value
	return data

/obj/item/organ/brain/protean/proc/on_owner_death(mob/living/source, gibbed)
	SIGNAL_HANDLER
	var/obj/item/mod/control/pre_equipped/protean/suit = get_protean_modsuit(source)
	suit?.stop_servo()

	if(dead || !owner || retreat_timer_id)
		return

	retreat_timer_id = addtimer(CALLBACK(src, PROC_REF(emergency_retreat)), 0, TIMER_STOPPABLE)

/obj/item/organ/brain/protean/proc/emergency_retreat()
	set waitfor = FALSE
	retreat_timer_id = null
	if(dead || !owner)
		return
	var/obj/item/mod/control/pre_equipped/protean/suit = get_protean_modsuit(owner)
	if(!suit)
		return
	end_transform()
	var/datum/species/protean/species = owner.dna?.species
	var/datum/action/innate/ability/slime_blobform/protean/puddle = locate() in species?.form_abilities
	puddle?.reset_form()
	dead = TRUE

	var/mob/living/carbon/body = owner
	var/old_visibility = body.invisibility
	set_transform_traits(TRUE)
	owner.remove_status_effect(/datum/status_effect/protean_low_power_mode/low_power)
	var/moved = retreat_into_suit(body, suit)
	suit.set_distress_signal(can_repair())
	if(moved)
		sleep(SUIT_TRANSFORMATION_DURATION)
	if(QDELETED(src) || owner != body || QDELETED(suit) || body.loc != suit)
		if(!QDELETED(body))
			body.invisibility = old_visibility
		return
	body.invisibility = old_visibility
	if(IS_CHANGELING(owner))
		to_chat(owner, span_red("Something anomalous surges through your nanomass, pulling you back together..."))
		revive_timer()
	else
		qdel(owner.getorganslot(ORGAN_SLOT_STOMACH))
		to_chat(owner, span_red("Your fragile refactory withers away with your mass reduced to scraps. Someone will have to help you."))

/obj/item/organ/brain/protean/proc/retreat_into_suit(mob/living/carbon/body, obj/item/mod/control/pre_equipped/protean/suit)
	if(body.loc == suit)
		return FALSE
	var/atom/current_loc = body.drop_location()
	body.visible_message(span_warning("[body] retreats into [suit]!"))
	body.ExtinguishMob()
	body.invisibility = INVISIBILITY_ABSTRACT
	new /obj/effect/temp_visual/protean_to_suit(current_loc, body.dir)
	REMOVE_TRAIT(suit, TRAIT_NODROP, PROTEAN_TRAIT)
	body.transferItemToLoc(suit, current_loc, force = TRUE)
	body.forceMove(suit)
	return TRUE

/obj/item/organ/brain/protean/on_life(seconds_per_tick, times_fired)
	. = ..()
	if(dead || !owner)
		return
	handle_refactory(owner.getorganslot(ORGAN_SLOT_STOMACH))
	handle_orchestrator(owner.getorganslot(ORGAN_SLOT_HEART))
	if(owner.health <= HEALTH_THRESHOLD_FULLCRIT && !dead)

		owner.death()

/obj/item/organ/brain/protean/proc/handle_refactory(obj/item/organ)
	var/obj/item/mod/control/pre_equipped/protean/suit = get_protean_modsuit(owner)
	if(owner.loc == suit)
		return
	if(isnull(organ) || !istype(organ, /obj/item/organ/stomach/protean))
		owner.adjustBruteLoss(PROTEAN_MISSING_STOMACH_DAMAGE, forced = TRUE, only_organic = FALSE)
		if(COOLDOWN_FINISHED(src, refactory_cooldown))
			to_chat(owner, span_warning("Your mass is slowly degrading without your refactory!"))
			COOLDOWN_START(src, refactory_cooldown, (30 SECONDS))

/obj/item/organ/brain/protean/proc/handle_orchestrator(obj/item/organ)
	var/obj/item/mod/control/pre_equipped/protean/suit = get_protean_modsuit(owner)
	if(owner.loc == suit)
		return
	if(!COOLDOWN_FINISHED(src, orchestrator_cooldown))
		return

	if(isnull(organ) || !istype(organ, /obj/item/organ/heart/protean))
		owner.Knockdown(1 SECONDS)
		owner.add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/protean_slowdown, multiplicative_slowdown = PROTEAN_STARVATION_SLOWDOWN)
		to_chat(owner, span_warning("You're struggling to walk without your orchestrator!"))
	else
		owner.remove_movespeed_modifier(/datum/movespeed_modifier/protean_slowdown)

	COOLDOWN_START(src, orchestrator_cooldown, (30 SECONDS))

/datum/movespeed_modifier/protean_slowdown
	variable = TRUE

/obj/item/organ/brain/protean/proc/go_into_suit(forced)
	set waitfor = FALSE
	var/mob/living/carbon/body = owner
	var/obj/item/mod/control/pre_equipped/protean/suit = get_protean_modsuit(body)
	if(!body || !suit || dead || body.loc == suit || !isturf(body.loc) || transform_user || rebuilding)
		return FALSE
	var/cycle = begin_transform(suit)
	if(!forced && !do_after(body, transform_delay))
		end_transform(cycle)
		return FALSE
	if(!is_transform_current(cycle))
		end_transform(cycle)
		return FALSE
	if(dead || !isturf(body.loc) || body.back != suit || body.incapacitated())
		end_transform(cycle)
		return FALSE
	body.visible_message(span_warning("[body] retreats into [suit]!"))
	body.ExtinguishMob()
	body.invisibility = INVISIBILITY_ABSTRACT
	new /obj/effect/temp_visual/protean_to_suit(body.loc, body.dir)
	body.Stun(INFINITY, ignore_canstun = TRUE)
	set_transform_traits(TRUE)
	body.remove_status_effect(/datum/status_effect/protean_low_power_mode/low_power)
	suit.drop_suit()
	body.forceMove(suit)
	sleep(transform_animation)
	if(!is_transform_current(cycle))
		end_transform(cycle)
		return FALSE
	end_transform(cycle)
	return TRUE

/obj/item/organ/brain/protean/proc/on_owner_moved(mob/living/source, atom/old_loc, dir, forced, list/old_locs)
	SIGNAL_HANDLER
	if(istype(source.loc, /obj/item/mod/control/pre_equipped/protean))
		RegisterSignal(source.loc, COMSIG_MOVABLE_MOVED, PROC_REF(on_suit_moved), override = TRUE)
		on_suit_moved(source.loc)
		if(source.loc == get_protean_modsuit(source))
			source.remote_control = source.loc
	if(istype(old_loc, /obj/item/mod/control/pre_equipped/protean))
		var/obj/item/mod/control/pre_equipped/protean/old_suit = old_loc
		old_suit.stop_servo()
		UnregisterSignal(old_loc, COMSIG_MOVABLE_MOVED)
		if(source.remote_control == old_loc)
			source.remote_control = null
		if(!QDELETED(source) && source.loc != get_protean_modsuit(source))
			set_transform_traits(FALSE)
			source.SetStun(0)

/obj/item/organ/brain/protean/proc/on_suit_moved(obj/item/source, atom/old_loc, dir, forced, list/old_locs)
	SIGNAL_HANDLER
	if(isnull(owner?.client))
		return
	if(isturf(source.loc))
		owner.reset_perspective(source.loc)
	else
		owner.reset_perspective(source)

/obj/item/organ/brain/protean/proc/leave_modsuit()
	set waitfor = FALSE
	var/mob/living/carbon/body = owner
	var/obj/item/mod/control/pre_equipped/protean/suit = get_protean_modsuit(body)
	if(!body || !suit || body.loc != suit || transform_user || rebuilding)
		return FALSE
	if(dead || body.stat == DEAD)
		to_chat(body, span_warning("Your mass is destroyed. You are unable to leave."))
		return FALSE
	var/cycle = begin_transform(suit)
	if(!do_after(body, transform_delay, suit, IGNORE_INCAPACITATED, progress_loc = body))
		end_transform(cycle)
		return FALSE
	if(!is_transform_current(cycle))
		end_transform(cycle)
		return FALSE
	if(dead || body.loc != suit || !get_turf(suit))
		end_transform(cycle)
		return FALSE
	suit.drop_suit()
	var/datum/component/storage/storage = suit.loc?.GetComponent(/datum/component/storage)
	storage?.remove_from_storage(suit, get_turf(suit))
	suit.invisibility = INVISIBILITY_ABSTRACT
	new /obj/effect/temp_visual/protean_from_suit(get_turf(suit), body.dir)
	sleep(transform_animation)
	if(!is_transform_current(cycle))
		end_transform(cycle)
		return FALSE
	if(dead || body.loc != suit || !get_turf(suit))
		end_transform(cycle)
		return FALSE
	suit.drop_suit()
	if(body.remote_control == suit)
		body.remote_control = null
	body.forceMove(get_turf(suit))
	if(body.get_item_by_slot(ITEM_SLOT_BACK))
		body.dropItemToGround(body.get_item_by_slot(ITEM_SLOT_BACK), TRUE)
	body.equip_to_slot_if_possible(suit, ITEM_SLOT_BACK, disable_warning = TRUE)
	body.SetStun(0)
	set_transform_traits(FALSE)
	body.apply_status_effect(/datum/status_effect/protean_low_power_mode/reform)
	body.visible_message(span_warning("[body] reforms from [suit]!"))
	ADD_TRAIT(suit, TRAIT_NODROP, PROTEAN_TRAIT)
	end_transform(cycle)
	return TRUE

/obj/item/organ/brain/protean/proc/replace_limbs()
	var/mob/living/carbon/body = owner
	var/obj/item/mod/control/pre_equipped/protean/suit = get_protean_modsuit(body)
	var/obj/item/organ/stomach/protean/stomach = body?.getorganslot(ORGAN_SLOT_STOMACH)
	if(!body || !suit || body.loc != suit || dead || rebuilding || transform_user)
		return FALSE
	if(!istype(stomach) || stomach.metal < PROTEAN_REBUILD_COST)
		to_chat(body, span_warning("Not enough metal to heal body!"))
		return FALSE
	rebuilding = TRUE
	var/cycle = transform_cycle
	var/ready = do_after(body, rebuild_time, suit, IGNORE_INCAPACITATED, progress_loc = body)
	if(cycle != transform_cycle)
		return FALSE
	rebuilding = FALSE
	if(!ready || QDELETED(src) || owner != body || QDELETED(suit) || get_protean_modsuit(body) != suit || body.loc != suit || dead)
		return FALSE
	if(QDELETED(stomach) || body.getorganslot(ORGAN_SLOT_STOMACH) != stomach || stomach.metal < PROTEAN_REBUILD_COST)
		return FALSE
	stomach.metal -= PROTEAN_REBUILD_COST
	rebuild_limbs(body)
	rebuild_organs(body)
	return TRUE

/obj/item/organ/brain/protean/proc/rebuild_limbs(mob/living/carbon/body)
	for(var/obj/item/bodypart/existing as anything in body.bodyparts)
		existing.heal_damage(existing.brute_dam, existing.burn_dam)
	for(var/zone in limb_cache)
		if(body.get_bodypart(zone))
			continue
		var/list/cached = limb_cache[zone]
		var/limb_type = cached["type"]
		if(!ispath(limb_type))
			continue
		var/obj/item/bodypart/new_limb = new limb_type()
		for(var/visual_var in cached_visual_vars)
			var/list/value = cached[visual_var]
			new_limb.vars[visual_var] = islist(value) ? value.Copy() : value
		new_limb.attach_limb(body, special = TRUE)
		if(new_limb.owner != body)
			qdel(new_limb)
			continue
		new_limb.update_limb(TRUE)
	body.update_body(TRUE)
	body.update_body_parts()

/obj/item/organ/brain/protean/proc/rebuild_organs(mob/living/carbon/body)
	var/static/list/organ_types = list(
		ORGAN_SLOT_EYES = /obj/item/organ/eyes/protean,
		ORGAN_SLOT_TONGUE = /obj/item/organ/tongue/cybernetic/protean,
		ORGAN_SLOT_EARS = /obj/item/organ/ears/protean,
		ORGAN_SLOT_LIVER = /obj/item/organ/liver/protean)
	for(var/slot in organ_types)
		var/obj/item/organ/organ = body.getorganslot(slot)
		if(!organ)
			var/organ_type = organ_types[slot]
			organ = new organ_type()
			organ.Insert(body, special = TRUE)
			continue
		if(organ.organ_flags & ORGAN_NANOMACHINE)
			organ.setOrganDamage(0)

/obj/item/organ/brain/protean/proc/revive()
	revive_timer_id = null
	if(!owner || !can_repair() || !istype(owner.getorganslot(ORGAN_SLOT_STOMACH), /obj/item/organ/stomach/protean))
		return
	dead = FALSE
	playsound(owner, 'sound/machines/ping.ogg', 30)
	to_chat(owner, span_warning("You have regained all your mass!"))
	var/obj/item/mod/control/pre_equipped/protean/suit = get_protean_modsuit(owner)
	suit?.set_distress_signal(FALSE)

	if(owner.stat == DEAD)
		owner.revive(full_heal = TRUE)
	owner.fully_heal()

	if(istype(owner.loc, /obj/item/mod/control/pre_equipped/protean))
		owner.Stun(INFINITY, ignore_canstun = TRUE)

/obj/item/organ/brain/protean/proc/revive_timer()
	if(revive_timer_id || !owner || !dead || !can_repair() || !istype(owner.getorganslot(ORGAN_SLOT_STOMACH), /obj/item/organ/stomach/protean))
		return
	balloon_alert_to_viewers("repairing")
	if(IS_CHANGELING(owner))
		revive_timer_id = addtimer(CALLBACK(src, PROC_REF(revive)), PROTEAN_CHANGELING_REPAIR_TIME, TIMER_STOPPABLE)
	else
		revive_timer_id = addtimer(CALLBACK(src, PROC_REF(revive)), PROTEAN_REPAIR_TIME, TIMER_STOPPABLE)

/obj/effect/temp_visual/protean_to_suit
	name = "to_suit"
	icon = PROTEAN_ORGAN_SPRITE
	icon_state = "to_puddle"
	duration = SUIT_TRANSFORMATION_DURATION

/obj/effect/temp_visual/protean_from_suit
	name = "from_suit"
	icon = PROTEAN_ORGAN_SPRITE
	icon_state = "from_puddle"
	duration = SUIT_TRANSFORMATION_DURATION

/obj/item/organ/brain/protean/emp_act(severity)
	. = ..()
	if(. & EMP_PROTECT_SELF)
		return
	if(!owner || owner.stat == DEAD)
		return
	switch(severity)
		if(PROTEAN_EMP_THRESHOLD to INFINITY)
			to_chat(owner, span_boldwarning("Your core nanites [pick("buzz erratically", "surge chaotically")]!"))
			owner.set_drugginess(max(owner.druggy, 40 SECONDS))
		else
			to_chat(owner, span_warning("Your core nanites feel [pick("fuzzy", "unruly", "sluggish")]."))
			owner.set_drugginess(max(owner.druggy, 20 SECONDS))

/obj/item/organ/brain/protean/proc/set_transform_traits(enabled)
	if(!owner)
		return
	if(enabled)
		GLOB.protean_listeners |= owner
	else
		GLOB.protean_listeners -= owner
	for(var/trait in TRANSFORM_TRAITS)
		if(enabled)
			ADD_TRAIT(owner, trait, PROTEAN_TRAIT)
		else
			REMOVE_TRAIT(owner, trait, PROTEAN_TRAIT)

/obj/item/organ/brain/protean/proc/can_repair()
	if(!owner || owner.suiciding)
		return FALSE
	var/mob/dead/observer/ghost = owner.get_ghost(TRUE)
	return !ghost || ghost.can_reenter_corpse

#undef TRANSFORM_TRAITS
#undef SUIT_TRANSFORMATION_DURATION

/obj/item/organ/brain/protean/proc/begin_transform(obj/item/mod/control/pre_equipped/protean/suit)
	transform_cycle++
	transform_user = owner
	transform_suit = suit
	user_invisibility = owner.invisibility
	suit_invisibility = suit.invisibility
	RegisterSignal(suit, COMSIG_PARENT_QDELETING, PROC_REF(on_transform_suit_deleted))
	return transform_cycle

/obj/item/organ/brain/protean/proc/is_transform_current(cycle)
	return cycle == transform_cycle && !QDELETED(src) && !QDELETED(owner) && owner == transform_user && !QDELETED(transform_suit) && get_protean_modsuit(owner) == transform_suit

/obj/item/organ/brain/protean/proc/end_transform(cycle)
	if(!isnull(cycle) && cycle != transform_cycle)
		return
	transform_cycle++
	if(transform_user)
		transform_user.invisibility = user_invisibility
	if(transform_suit)
		UnregisterSignal(transform_suit, COMSIG_PARENT_QDELETING)
		transform_suit.invisibility = suit_invisibility
	transform_user = null
	transform_suit = null

/obj/item/organ/brain/protean/proc/on_transform_suit_deleted(datum/source)
	SIGNAL_HANDLER
	end_transform()
