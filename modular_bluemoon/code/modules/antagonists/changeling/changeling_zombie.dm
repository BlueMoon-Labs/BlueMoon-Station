/// Absorb husks + zombie outbreak (adapted from SPLURT modular_zubbers/changeling_zombies).

/proc/can_become_changeling_zombie(atom/parent)
	if(!ishuman(parent))
		return FALSE
	var/mob/living/carbon/human/host = parent
	if(IS_CHANGELING(host))
		return FALSE
	if(!host.dna)
		return FALSE
	if(HAS_TRAIT(host, TRAIT_GENELESS))
		return FALSE
	return TRUE

/proc/try_changeling_zombie_infection(mob/living/carbon/human/host)
	if(!can_become_changeling_zombie(host))
		return
	host.AddComponent(/datum/component/changeling_zombie_infection)

/datum/antagonist/changeling_zombie
	name = "Changeling Mutant"
	show_in_antagpanel = TRUE
	antagpanel_category = "Changeling"
	roundend_category = "changelings"

/datum/objective/changeling_zombie_infect
	explanation_text = "Infect at least 5 humanoids with your blades."
	var/required_infections = 5
	var/total_infections = 0

/datum/objective/changeling_zombie_infect/update_explanation_text()
	explanation_text = "Infect at least [required_infections] humanoids with your blades."

/datum/objective/changeling_zombie_infect/check_completion()
	return total_infections >= required_infections

/datum/component/changeling_zombie_infection
	var/zombified = FALSE
	var/can_cure = FALSE
	var/was_changeling_husked = FALSE
	var/list/obj/item/melee/arm_blade/changeling_zombie/arm_blades = list()
	var/obj/item/clothing/suit/armor/changeling/weak/armor
	var/obj/item/clothing/head/helmet/changeling/weak/armor_head
	var/list/bodypart_zones_to_regenerate = list()
	COOLDOWN_DECLARE(limb_regen_cooldown)
	COOLDOWN_DECLARE(transformation_grace_period)
	var/datum/objective/changeling_zombie_infect/infect_objective
	var/infection_timestamp = 0
	var/spaceacillin_resistance = 0

/datum/component/changeling_zombie_infection/Initialize()
	. = ..()
	if(!can_become_changeling_zombie(parent))
		return COMPONENT_INCOMPATIBLE
	infection_timestamp = world.time
	if(HAS_TRAIT_FROM(parent, TRAIT_HUSK, CHANGELING_DRAIN))
		COOLDOWN_START(src, transformation_grace_period, 30 SECONDS)
		was_changeling_husked = TRUE
	if(ishuman(parent))
		var/mob/living/carbon/human/host = parent
		host.ForceContractDisease(new /datum/disease/changeling_virus)
	START_PROCESSING(SSobj, src)

/datum/component/changeling_zombie_infection/UnregisterFromParent()
	STOP_PROCESSING(SSobj, src)
	return ..()

/datum/component/changeling_zombie_infection/Destroy(force, silent)
	if(parent)
		var/mob/living/carbon/human/host = parent
		if(istype(host))
			for(var/datum/disease/changeling_virus/virus_entry in host.diseases)
				virus_entry.cure(FALSE)
			REMOVE_TRAITS_IN(host, TRAIT_CHANGELING_ZOMBIE)
			host.mind?.remove_antag_datum(/datum/antagonist/changeling_zombie)
			if(zombified)
				UnregisterSignal(host, COMSIG_MOB_DEATH)
				UnregisterSignal(host, COMSIG_CARBON_REMOVE_LIMB)
				UnregisterSignal(host, COMSIG_CARBON_ATTACH_LIMB)
				UnregisterSignal(host, COMSIG_MOB_SAY)
	QDEL_LIST(arm_blades)
	QDEL_NULL(armor)
	QDEL_NULL(armor_head)
	zombified = FALSE
	return ..()

/datum/component/changeling_zombie_infection/process(seconds_per_tick)
	var/mob/living/carbon/human/host = parent
	if(zombified)
		if(host.getBruteLoss() > 0)
			host.adjustBruteLoss(-min(CHANGELING_ZOMBIE_PASSIVE_HEALING * seconds_per_tick, host.getBruteLoss()))
		if(host.getFireLoss() > 0)
			host.adjustFireLoss(-min(CHANGELING_ZOMBIE_PASSIVE_HEALING * seconds_per_tick, host.getFireLoss()))
		if(host.getToxLoss() > 0)
			host.adjustToxLoss(-min(CHANGELING_ZOMBIE_PASSIVE_HEALING * seconds_per_tick, host.getToxLoss()))
		if(host.blood_volume <= BLOOD_VOLUME_NORMAL)
			host.blood_volume += 5
		if(length(bodypart_zones_to_regenerate) && COOLDOWN_FINISHED(src, limb_regen_cooldown))
			var/selected_zone = pick_n_take(bodypart_zones_to_regenerate)
			if(host.regenerate_limb(selected_zone))
				host.visible_message("<span class='danger'>[host]'s flesh writhes as a limb reforms!</span>", "<span class='userdanger'>You regenerate a limb!</span>")
				playsound(host, 'sound/effects/splat.ogg', 40, TRUE)
	else if(spaceacillin_resistance < 100 && host.reagents?.has_reagent(/datum/reagent/medicine/spaceacillin))
		var/current_toxin_damage = host.getToxLoss()
		if(can_cure || current_toxin_damage > CHANGELING_ZOMBIE_TOXINS_THRESHOLD_TO_CURE * 0.5 + spaceacillin_resistance)
			qdel(src)
			return
		spaceacillin_resistance += seconds_per_tick
	else
		var/current_toxin_damage = host.getToxLoss()
		if(can_cure && current_toxin_damage <= 5)
			qdel(src)
			return
		else if(COOLDOWN_FINISHED(src, transformation_grace_period))
			if(current_toxin_damage >= CHANGELING_ZOMBIE_TOXINS_THRESHOLD_TO_TRANSFORM && host.stat == DEAD)
				make_zombie()
				can_cure = FALSE
			else
				var/damage_multiplier = max(1, (world.time - infection_timestamp) / (1 MINUTES))
				if(can_cure)
					damage_multiplier = min(2, damage_multiplier)
				if(host.stat == DEAD)
					host.adjustToxLoss(round(CHANGELING_ZOMBIE_TOXINS_PER_SECOND_DEAD * seconds_per_tick * damage_multiplier, 0.1))
				else
					if(!can_cure && current_toxin_damage >= CHANGELING_ZOMBIE_TOXINS_THRESHOLD_TO_CURE)
						can_cure = TRUE
						host.visible_message("<span class='danger'>[host]'s flesh hardens — purge toxins now or lose them forever!</span>", "<span class='userdanger'>Your body convulses violently...</span>")
					host.adjustToxLoss(round(CHANGELING_ZOMBIE_TOXINS_PER_SECOND_LIVING * seconds_per_tick * damage_multiplier, 0.1))
				if(SPT_PROB(4, seconds_per_tick) && current_toxin_damage > CHANGELING_ZOMBIE_TOXINS_THRESHOLD_TO_CURE)
					host.adjustBruteLoss(3)
					host.emote("scream")

/datum/component/changeling_zombie_infection/proc/make_zombie()
	if(zombified)
		return FALSE
	var/mob/living/carbon/human/host = parent
	host.grab_ghost()
	zombified = TRUE
	host.cure_husk(CHANGELING_DRAIN)
	to_chat(host, "<span class='notice'>Something awful stitches your corpse back together.</span>")
	ADD_TRAIT(host, TRAIT_CHUNKYFINGERS, TRAIT_CHANGELING_ZOMBIE)
	ADD_TRAIT(host, TRAIT_RESISTCOLD, TRAIT_CHANGELING_ZOMBIE)
	ADD_TRAIT(host, TRAIT_RESISTLOWPRESSURE, TRAIT_CHANGELING_ZOMBIE)
	ADD_TRAIT(host, TRAIT_NOHUNGER, TRAIT_CHANGELING_ZOMBIE)
	ADD_TRAIT(host, TRAIT_NOBREATH, TRAIT_CHANGELING_ZOMBIE)
	ADD_TRAIT(host, TRAIT_THERMAL_VISION, TRAIT_CHANGELING_ZOMBIE)
	ADD_TRAIT(host, TRAIT_NODISMEMBER, TRAIT_CHANGELING_ZOMBIE)
	ADD_TRAIT(host, TRAIT_FAKEDEATH, TRAIT_CHANGELING_ZOMBIE)
	host.cure_all_traumas(TRAUMA_RESILIENCE_MAGIC)
	host.revive(TRUE, TRUE)
	host.do_jitter_animation(100)
	host.drop_all_held_items()
	for(var/hand_index in 1 to length(host.held_items))
		generate_armblade(host, hand_index)
	if(host.wear_suit)
		host.temporarilyRemoveItemFromInventory(host.wear_suit, TRUE)
	armor = new(host.loc)
	armor_head = new(host.loc)
	ADD_TRAIT(armor, TRAIT_NODROP, TRAIT_CHANGELING_ZOMBIE)
	ADD_TRAIT(armor_head, TRAIT_NODROP, TRAIT_CHANGELING_ZOMBIE)
	// The armor can be destroyed externally (integrity damage), leaving a dangling ref
	// on the component for the rest of the round - same wiring as arm_blades above.
	RegisterSignal(armor, COMSIG_PARENT_QDELETING, PROC_REF(on_armor_delete))
	RegisterSignal(armor_head, COMSIG_PARENT_QDELETING, PROC_REF(on_armor_delete))
	host.equip_to_slot_if_possible(armor, ITEM_SLOT_OCLOTHING, TRUE, TRUE, TRUE)
	host.equip_to_slot_if_possible(armor_head, ITEM_SLOT_HEAD, TRUE, TRUE, TRUE)
	host.SetKnockdown(0)
	host.setStaminaLoss(0)
	host.set_resting(FALSE)
	RegisterSignal(host, COMSIG_MOB_DEATH, PROC_REF(on_owner_died))
	RegisterSignal(host, COMSIG_CARBON_REMOVE_LIMB, PROC_REF(on_remove_limb))
	RegisterSignal(host, COMSIG_CARBON_ATTACH_LIMB, PROC_REF(on_gain_limb))
	RegisterSignal(host, COMSIG_MOB_SAY, PROC_REF(handle_speech))
	if(host.mind)
		var/datum/antagonist/changeling_zombie/antag = host.mind.add_antag_datum(/datum/antagonist/changeling_zombie)
		var/datum/objective/changeling_zombie_infect/objec = new
		objec.owner = host.mind
		antag.objectives += objec
		infect_objective = objec
	return TRUE

/datum/component/changeling_zombie_infection/proc/generate_armblade(mob/living/carbon/human/host, hand_index)
	var/obj/item/melee/arm_blade/changeling_zombie/arm_blade = new(host.loc)
	arm_blade.infect_chance = was_changeling_husked ? CHANGELING_ZOMBIE_INFECT_CHANCE_LESSER : CHANGELING_ZOMBIE_INFECT_CHANCE
	ADD_TRAIT(arm_blade, TRAIT_NODROP, TRAIT_CHANGELING_ZOMBIE)
	RegisterSignal(arm_blade, COMSIG_PARENT_QDELETING, PROC_REF(on_armblade_delete))
	host.put_in_hand(arm_blade, hand_index, forced = TRUE)
	arm_blades += arm_blade

/datum/component/changeling_zombie_infection/proc/on_owner_died(datum/source, gibbed)
	SIGNAL_HANDLER
	if(zombified)
		qdel(src)

/datum/component/changeling_zombie_infection/proc/on_remove_limb(datum/source, obj/item/bodypart/removed_limb, special, dismembered)
	SIGNAL_HANDLER
	if(removed_limb.body_zone == BODY_ZONE_HEAD || removed_limb.body_zone == BODY_ZONE_CHEST)
		return
	bodypart_zones_to_regenerate += removed_limb.body_zone
	COOLDOWN_START(src, limb_regen_cooldown, CHANGELING_ZOMBIE_LIMB_REGEN_TIME)

/datum/component/changeling_zombie_infection/proc/on_armblade_delete(datum/source)
	SIGNAL_HANDLER
	arm_blades -= source

/datum/component/changeling_zombie_infection/proc/on_armor_delete(datum/source)
	SIGNAL_HANDLER
	if(source == armor)
		armor = null
	if(source == armor_head)
		armor_head = null

/datum/component/changeling_zombie_infection/proc/on_gain_limb(datum/source, obj/item/bodypart/gained, special)
	SIGNAL_HANDLER
	if(!gained.held_index)
		return
	var/mob/living/carbon/human/host = parent
	generate_armblade(host, gained.held_index)
	COOLDOWN_START(src, limb_regen_cooldown, CHANGELING_ZOMBIE_LIMB_REGEN_TIME)

/datum/component/changeling_zombie_infection/proc/handle_speech(datum/source, list/speech_args)
	SIGNAL_HANDLER
	speech_args[SPEECH_SPANS] |= SPAN_ITALICS

/obj/item/melee/arm_blade/changeling_zombie
	name = "warped arm blade"
	desc = "Misgrown bone and tendon — still hungry."
	force = 21
	var/infect_chance = 100
	COOLDOWN_DECLARE(sound_cooldown)
	COOLDOWN_DECLARE(infection_cooldown)

/obj/item/melee/arm_blade/changeling_zombie/attack(mob/living/target_mob, mob/living/user)
	. = ..()
	if(COOLDOWN_FINISHED(src, sound_cooldown) && prob(40))
		playsound(src, pick('sound/hallucinations/growl1.ogg', 'sound/hallucinations/growl2.ogg'), 45, TRUE)
		COOLDOWN_START(src, sound_cooldown, 3 SECONDS)
	if(target_mob.stat == DEAD || !user || !ishuman(target_mob))
		return
	if(!prob(infect_chance) || !COOLDOWN_FINISHED(src, infection_cooldown))
		return
	COOLDOWN_START(src, infection_cooldown, CHANGELING_ZOMBIE_REINFECT_DELAY)
	if(!can_become_changeling_zombie(target_mob))
		return
	var/mob/living/carbon/human/V = target_mob
	if(V.GetComponent(/datum/component/changeling_zombie_infection))
		return
	V.AddComponent(/datum/component/changeling_zombie_infection)
	user.visible_message("<span class='danger'>[V]'s wounds froth — infection takes hold!</span>")
	var/datum/component/changeling_zombie_infection/us = user.GetComponent(/datum/component/changeling_zombie_infection)
	if(us?.infect_objective)
		us.infect_objective.total_infections += 1

/obj/item/clothing/suit/armor/changeling/weak
	armor = list(MELEE = 35, BULLET = 30, LASER = 15, ENERGY = 20, BOMB = 5, BIO = 4, RAD = 0, FIRE = 100, ACID = 100)

/obj/item/clothing/head/helmet/changeling/weak
	armor = list(MELEE = 35, BULLET = 30, LASER = 15, ENERGY = 20, BOMB = 5, BIO = 4, RAD = 0, FIRE = 100, ACID = 100)
