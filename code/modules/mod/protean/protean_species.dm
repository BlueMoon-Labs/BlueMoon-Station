/datum/species/protean
	parent_type = /datum/species/mammal
	name = "Protean"
	id = SPECIES_PROTEAN
	limbs_id = SPECIES_MAMMAL
	species_category = SPECIES_CATEGORY_ROBOT
	siemens_coeff = 1.5
	exotic_bloodtype = "FE"
	exotic_blood = /datum/reagent/iron
	exotic_blood_color = BLOOD_COLOR_IRON
	meat = /obj/item/stack/sheet/metal
	mutant_brain = /obj/item/organ/brain/protean
	mutant_heart = /obj/item/organ/heart/protean
	mutantstomach = /obj/item/organ/stomach/protean
	mutantlungs = null
	mutantappendix = null
	mutantliver = /obj/item/organ/liver/protean
	mutanteyes = /obj/item/organ/eyes/protean
	mutantears = /obj/item/organ/ears/protean
	mutanttongue = /obj/item/organ/tongue/cybernetic/protean
	inherent_biotypes = MOB_ROBOTIC | MOB_HUMANOID
	inherent_traits = list(TRAIT_NOBREATH, TRAIT_NOHUNGER, TRAIT_NOTHIRST, TRAIT_STABLEHEART, TRAIT_LIMBATTACHMENT,
		TRAIT_GENELESS, TRAIT_TOXIMMUNE, TRAIT_NEVER_WOUNDED, TRAIT_VIRUSIMMUNE, TRAIT_RADIMMUNE,
		TRAIT_EASYDISMEMBER, TRAIT_NODEATH, TRAIT_NO_PROCESS_FOOD, TRAIT_ROBOTIC_ORGANISM, TRAIT_SUPERMATTER_MADNESS_IMMUNE, TRAIT_RDS_SUPPRESSED)
	var/list/abilities = list()
	var/list/form_abilities = list()
	var/datum/action/protean/busy_action
	var/static/list/protean_verbs = list(
		/mob/living/carbon/proc/protean_ui,
		/mob/living/carbon/proc/protean_heal,
		/mob/living/carbon/proc/protean_lock,
		/mob/living/carbon/proc/protean_transform,
		/mob/living/carbon/proc/protean_low_power,
		/mob/living/carbon/proc/protean_remove_suit,
		/mob/living/carbon/proc/protean_remove_plating)
	var/static/list/replacement_organs = list(
		ORGAN_SLOT_HEART = /obj/item/organ/heart/protean,
		ORGAN_SLOT_STOMACH = /obj/item/organ/stomach/protean,
		ORGAN_SLOT_BRAIN = /obj/item/organ/brain/protean,
		ORGAN_SLOT_EYES = /obj/item/organ/eyes/protean)

/datum/species/protean/on_species_gain(mob/living/carbon/human/human, datum/species/old_species, pref_load)
	. = ..()
	for(var/obj/item/bodypart/limb in human.bodyparts)
		limb.AddComponent(/datum/component/protean_limb)
	equip_modsuit(human)
	RegisterSignal(human, COMSIG_PROTEAN_ORGAN_INSERTED, PROC_REF(on_organ_inserted))
	RegisterSignal(human, COMSIG_PROTEAN_LIMB_ATTACHED, PROC_REF(on_limb_attached))
	add_verb(human, protean_verbs)
	grant_abilities(human)
	grant_forms(human)

/datum/species/protean/on_species_loss(mob/living/carbon/human/human, datum/species/new_species, pref_load)
	UnregisterSignal(human, list(COMSIG_PROTEAN_ORGAN_INSERTED, COMSIG_PROTEAN_LIMB_ATTACHED))
	remove_verb(human, protean_verbs)
	clear_abilities()
	clear_forms()
	human.remove_status_effect(/datum/status_effect/protean_low_power_mode/low_power)
	human.remove_status_effect(/datum/status_effect/protean_low_power_mode/reform)
	human.remove_movespeed_modifier(/datum/movespeed_modifier/protean_slowdown)
	human.remove_movespeed_modifier(/datum/movespeed_modifier/protean_starvation)
	if(human.remote_control == get_protean_modsuit(human))
		human.remote_control = null
	var/obj/item/organ/brain/protean/brain = human.getorganslot(ORGAN_SLOT_BRAIN)
	if(istype(brain))
		brain.set_transform_traits(FALSE)
	var/obj/item/mod/control/pre_equipped/protean/suit = get_protean_modsuit(human)
	if(suit)
		if(human.loc == suit)
			human.forceMove(get_turf(suit))
			human.SetStun(0)
		suit.unassimilate_modsuit(human, TRUE)
		suit.drop_suit()
		qdel(suit)
	for(var/obj/item/bodypart/limb in human.bodyparts)
		qdel(limb.GetComponent(/datum/component/protean_limb))
	return ..()

/datum/species/protean/proc/equip_modsuit(mob/living/carbon/human/human)
	var/obj/item/mod/control/pre_equipped/protean/suit = get_protean_modsuit(human)
	if(!suit)
		suit = new(human.drop_location())
		set_protean_modsuit(human, suit)
	var/obj/item/mod/core/protean/core = suit.core
	core.set_linked_protean(human)
	var/obj/item/backpack = human.get_item_by_slot(ITEM_SLOT_BACK)
	if(backpack && backpack != suit)
		human.dropItemToGround(backpack, TRUE)
	return human.equip_to_slot_if_possible(suit, ITEM_SLOT_BACK, disable_warning = TRUE)

/datum/species/protean/proc/on_limb_attached(mob/living/carbon/human/human, obj/item/bodypart/limb)
	SIGNAL_HANDLER
	limb.AddComponent(/datum/component/protean_limb)

/datum/species/protean/proc/on_organ_inserted(mob/living/carbon/human/human, obj/item/organ/organ, special)
	SIGNAL_HANDLER
	if(!replacement_organs[organ.slot] || organ.organ_flags & (ORGAN_SYNTHETIC | ORGAN_NANOMACHINE | ORGAN_UNREMOVABLE))
		return
	addtimer(CALLBACK(src, PROC_REF(assimilate_organ), human, organ), special ? 0 : 1 SECONDS)

/datum/species/protean/proc/assimilate_organ(mob/living/carbon/human/human, obj/item/organ/organ)
	if(QDELETED(human) || human.dna.species != src || QDELETED(organ) || organ.owner != human || organ.organ_flags & (ORGAN_SYNTHETIC | ORGAN_NANOMACHINE | ORGAN_UNREMOVABLE))
		return
	var/organ_type = replacement_organs[organ.slot]
	var/obj/item/organ/replacement = new organ_type()
	replacement.Insert(human, special = TRUE, drop_if_replaced = FALSE)
	to_chat(human, span_notice("Your nanomass assimilates the foreign organ."))

/datum/species/protean/apply_damage(damage, damagetype = BRUTE, def_zone, blocked, mob/living/carbon/human/H, forced = FALSE, spread_damage = FALSE, wound_bonus = 0, bare_wound_bonus = 0, sharpness = SHARP_NONE, can_dismember = TRUE)
	if(!forced && H.loc == get_protean_modsuit(H))
		return FALSE
	. = ..()
	if(!.)
		return
	var/obj/item/organ/stomach/protean/stomach = H.getorganslot(ORGAN_SLOT_STOMACH)
	if(istype(stomach))
		stomach.on_damage(damage, damagetype, sharpness)

/datum/species/protean/proc/handle_item(mob/living/carbon/human/target, obj/item/item, mob/living/user)
	if(user.a_intent == INTENT_HARM)
		return FALSE
	var/obj/item/organ/stomach/protean/stomach = target.getorganslot(ORGAN_SLOT_STOMACH)
	if(istype(stomach) && istype(item, /obj/item/stack) && stomach.get_resource_nutrition(item))
		return stomach.eat_resource(item, user)
	if(istype(item, /obj/item/weldingtool) || istype(item, /obj/item/stack/cable_coil))
		to_chat(user, span_warning("Nanomachine limbs cannot be repaired with [item]."))
		return TRUE
	return FALSE

/mob/living/carbon/human/protean/Initialize(mapload)
	. = ..()
	set_species(/datum/species/protean)

GLOBAL_LIST_EMPTY(protean_listeners)

/datum/species/protean/proc/grant_abilities(mob/living/carbon/human/human)
	clear_abilities()
	for(var/ability_type in subtypesof(/datum/action/protean))
		var/datum/action/protean/ability = new ability_type(src)
		abilities += ability
		ability.Grant(human)
	START_PROCESSING(SSobj, src)

/datum/species/protean/proc/clear_abilities()
	STOP_PROCESSING(SSobj, src)
	busy_action = null
	QDEL_LIST(abilities)

/datum/species/protean/proc/update_buttons()
	for(var/datum/action/ability as anything in abilities + form_abilities)
		ability.UpdateButtons(status_only = TRUE)

/datum/species/protean/process(delta_time)
	update_buttons()

/datum/species/protean/Destroy()
	clear_abilities()
	clear_forms()
	return ..()
