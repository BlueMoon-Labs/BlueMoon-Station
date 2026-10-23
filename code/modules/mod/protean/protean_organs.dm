/obj/item/organ/heart/protean
	name = "orchestrator module"
	desc = "A small computer, designed for highly parallel workloads."
	icon = PROTEAN_ORGAN_SPRITE
	icon_state = "orchestrator"
	status = ORGAN_ROBOTIC
	organ_flags = ORGAN_SYNTHETIC | ORGAN_NANOMACHINE

/obj/item/organ/eyes/protean
	name = "imaging nanites"
	icon_state = "cybernetic_eyeballs"
	maxHealth = STANDARD_ORGAN_THRESHOLD
	status = ORGAN_ROBOTIC
	custom_materials = list(/datum/material/iron = HALF_SHEET_MATERIAL_AMOUNT, /datum/material/glass = HALF_SHEET_MATERIAL_AMOUNT)
	desc = "Nanites designed to collect visual data from the surrounding world."
	organ_flags = ORGAN_SYNTHETIC | ORGAN_NANOMACHINE

/obj/item/organ/liver/protean
	name = "reagent catalyst"
	icon_state = "liver-c"
	status = ORGAN_ROBOTIC
	filterToxins = FALSE
	custom_materials = list(/datum/material/iron = HALF_SHEET_MATERIAL_AMOUNT, /datum/material/glass = HALF_SHEET_MATERIAL_AMOUNT)
	desc = "A nanite harvester that processes chemicals and distributes them to the nanite swarm."
	organ_flags = ORGAN_SYNTHETIC | ORGAN_NANOMACHINE | ORGAN_UNREMOVABLE

/obj/item/organ/liver/protean/Initialize(mapload)
	. = ..()
	add_atom_colour(COLOR_GRAY, FIXED_COLOUR_PRIORITY)

/obj/item/organ/ears/protean
	name = "sensory nanites"
	icon_state = "ears-c"
	status = ORGAN_ROBOTIC
	damage_multiplier = 1.2
	desc = "Nanites designed to collect audio feedback from the surrounding world."
	organ_flags = ORGAN_SYNTHETIC | ORGAN_NANOMACHINE

/obj/item/organ/ears/protean/Initialize(mapload)
	. = ..()
	add_atom_colour(COLOR_GRAY, FIXED_COLOUR_PRIORITY)

/obj/item/organ/tongue/cybernetic/protean
	name = "protean audio fabricator"
	desc = "Millions of nanites vibrate in harmony to create the sound you hear."
	organ_flags = ORGAN_SYNTHETIC | ORGAN_NANOMACHINE

/obj/item/organ/tongue/cybernetic/protean/Initialize(mapload)
	. = ..()
	add_atom_colour(COLOR_GRAY, FIXED_COLOUR_PRIORITY)

/obj/item/organ/stomach/protean
	name = "refactory"
	desc = "An extremely fragile factory used to recycle materials and create more nanite mass. Needed to repair a collapsed Protean; it can be installed through the suit's maintenance panel or as an organ."
	icon = PROTEAN_ORGAN_SPRITE
	icon_state = "refactory"
	status = ORGAN_ROBOTIC
	organ_flags = ORGAN_SYNTHETIC | ORGAN_NANOMACHINE
	var/metal_max = 10
	var/metal = 10
	var/metabolism_modifier = 1
	var/feeding_time = 1 SECONDS
	COOLDOWN_DECLARE(starving_message)
	COOLDOWN_DECLARE(damage_delay)

/obj/item/organ/stomach/protean/Initialize(mapload)
	. = ..()
	metal = rand(10 / 2, 10)

/obj/item/organ/stomach/protean/Insert(mob/living/carbon/receiver, special = FALSE, drop_if_replaced = TRUE)
	. = ..()
	if(owner != receiver)
		return
	ADD_TRAIT(receiver, TRAIT_NOHUNGER, REF(src))

/obj/item/organ/stomach/protean/Remove(special = FALSE)
	if(owner)
		REMOVE_TRAIT(owner, TRAIT_NOHUNGER, REF(src))
		owner.remove_movespeed_modifier(/datum/movespeed_modifier/protean_starvation)
	return ..()

/obj/item/organ/stomach/protean/on_life(seconds_per_tick = SSmobs.wait / (1 SECONDS), times_fired)
	if(!owner || owner.loc == get_protean_modsuit(owner))
		return
	. = ..()
	if(!isprotean(owner) || !owner.client || is_centcom_level(owner.z) || istype(get_area(owner), /area/centcom/holding))
		return
	handle_metabolism(seconds_per_tick)

/obj/item/organ/stomach/protean/proc/handle_metabolism(seconds_per_tick)
	if(metal <= PROTEAN_STOMACH_FALTERING)
		owner.adjustBruteLoss(PROTEAN_REGEN_AMOUNT, forced = TRUE, only_organic = FALSE)
		owner.add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/protean_starvation, multiplicative_slowdown = PROTEAN_STARVATION_SLOWDOWN)
		if(COOLDOWN_FINISHED(src, starving_message))
			to_chat(owner, span_warning("You are starving! You must find metal now!"))
			COOLDOWN_START(src, starving_message, PROTEAN_WARNING_TIME)
		return
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/protean_starvation)
	var/hunger = metabolism_modifier
	if(metal > PROTEAN_REGEN_THRESHOLD)
		hunger = regenerate_mass(seconds_per_tick, hunger)
	metal = max(0, metal - 10 / PROTEAN_METABOLISM_RATE * hunger * seconds_per_tick)

/obj/item/organ/stomach/protean/proc/regenerate_mass(seconds_per_tick, hunger)
	if(seconds_per_tick <= 0)
		return hunger
	hunger += PROTEAN_REGEN_COST * regenerate_damage()
	var/blood_amount = min(BLOOD_VOLUME_NORMAL - owner.blood_volume, PROTEAN_BLOOD_REGEN_RATE * seconds_per_tick)
	if(blood_amount > 0)
		owner.blood_volume += blood_amount
		hunger += PROTEAN_BLOOD_COST * blood_amount / (PROTEAN_BLOOD_REGEN_RATE * seconds_per_tick)
	return hunger

/obj/item/organ/stomach/protean/proc/regenerate_damage()
	var/factor = COOLDOWN_FINISHED(src, damage_delay) ? 1 : clamp(1 - COOLDOWN_TIMELEFT(src, damage_delay) / PROTEAN_REGEN_TIME, 0, 1)
	var/heal_amount = PROTEAN_REGEN_AMOUNT * factor
	if(heal_amount <= 0)
		return 0
	var/brute_before = owner.getBruteLoss()
	var/burn_before = owner.getFireLoss()
	var/corruption_before = owner.getToxLoss(TOX_SYSCORRUPT)
	if(brute_before > 0)
		owner.adjustBruteLoss(-heal_amount, updating_health = FALSE, forced = TRUE, only_organic = FALSE)
	if(burn_before > 0)
		owner.adjustFireLoss(-heal_amount, updating_health = FALSE, forced = TRUE, only_organic = FALSE)
	if(corruption_before > 0)
		owner.adjustToxLoss(-heal_amount, updating_health = FALSE, forced = TRUE, toxins_type = TOX_SYSCORRUPT)
	var/restored = max(brute_before - owner.getBruteLoss(), burn_before - owner.getFireLoss(), corruption_before - owner.getToxLoss(TOX_SYSCORRUPT))
	if(restored <= 0)
		return 0
	owner.updatehealth()
	return restored / PROTEAN_REGEN_AMOUNT

/obj/item/organ/stomach/protean/proc/on_damage(damage, damage_type, sharpness)
	if(damage <= 0)
		return
	COOLDOWN_START(src, damage_delay, PROTEAN_REGEN_TIME)
	if(damage_type != BRUTE || !sharpness || !owner || owner.stat == DEAD)
		return
	owner.blood_volume = max(0, owner.blood_volume - damage * PROTEAN_BLEED_FACTOR)
	if(damage >= PROTEAN_SPRAY_DAMAGE)
		owner.spray_blood(pick(GLOB.cardinals), clamp(round(damage / PROTEAN_SPRAY_DIVISOR), 1, PROTEAN_SPRAY_MAX))

/obj/item/organ/stomach/protean/proc/get_resource_nutrition(obj/item/stack/resource)
	if(!istype(resource) || QDELETED(resource) || resource.is_cyborg || resource.get_amount() <= 0)
		return 0
	if(length(resource.mats_per_unit))
		var/nutrition = 0
		for(var/material_type in resource.mats_per_unit)
			var/datum/material/material = SSmaterials.GetMaterialRef(material_type)
			nutrition += max(0, resource.mats_per_unit[material_type]) / MINERAL_MATERIAL_AMOUNT * get_material_nutrition(material)
		return nutrition
	if(resource.material_type)
		return get_material_nutrition(SSmaterials.GetMaterialRef(resource.material_type))
	if(!istype(resource, /obj/item/stack/sheet) && !istype(resource, /obj/item/stack/ore))
		return 0
	for(var/key in SSmaterials.materials)
		var/datum/material/material = SSmaterials.materials[key]
		if(ispath(material.sheet_type) && istype(resource, material.sheet_type))
			return get_material_nutrition(material)
	return PROTEAN_RESOURCE_FALLBACK_NUTRITION

/obj/item/organ/stomach/protean/proc/get_material_nutrition(datum/material/material)
	if(!material || material.value_per_unit <= 0)
		return PROTEAN_RESOURCE_BASE_NUTRITION
	var/datum/material/iron/iron = SSmaterials.GetMaterialRef(/datum/material/iron)
	return sqrt(material.value_per_unit / iron.value_per_unit) * PROTEAN_RESOURCE_BASE_NUTRITION

/obj/item/organ/stomach/protean/proc/eat_resource(obj/item/stack/resource, mob/living/user)
	if(!get_resource_nutrition(resource))
		return FALSE
	if(metal >= metal_max)
		to_chat(user, span_warning("Your material storage is full!"))
		return TRUE
	var/mob/living/carbon/body = owner
	if(!do_after(user, feeding_time, body) || QDELETED(src) || QDELETED(resource) || !body || owner != body || !user.is_holding(resource) || !user.Adjacent(body))
		return TRUE
	var/nutrition = min(get_resource_nutrition(resource), metal_max - metal)
	if(nutrition <= 0 || !resource.use(1))
		return TRUE
	metal += nutrition
	if(user != owner)
		owner.adjustBruteLoss(-PROTEAN_FEED_HEAL * nutrition, forced = TRUE, only_organic = FALSE)
	to_chat(owner, span_notice("Your refactory processes the material, restoring [round(nutrition, PROTEAN_RESOURCE_PRECISION)] mass. Reserve: [round(metal, PROTEAN_RESOURCE_PRECISION)]/[metal_max]."))
	return TRUE

/datum/movespeed_modifier/protean_starvation
	variable = TRUE


/obj/item/organ/eyes/protean/emp_act(severity)
	. = ..()
	if(!owner || . & EMP_PROTECT_SELF)
		return
	applyOrganDamage(get_protean_emp_damage(severity))

/obj/item/organ/liver/protean/emp_act(severity)
	. = ..()
	if(!owner || . & EMP_PROTECT_SELF)
		return
	applyOrganDamage(get_protean_emp_damage(severity))

/obj/item/organ/ears/protean/emp_act(severity)
	. = ..()
	if(!owner || . & EMP_PROTECT_SELF)
		return
	applyOrganDamage(get_protean_emp_damage(severity))

/proc/get_protean_emp_damage(severity)
	return severity >= PROTEAN_EMP_THRESHOLD ? PROTEAN_EMP_HEAVY_DAMAGE : PROTEAN_EMP_LIGHT_DAMAGE

/obj/item/organ/eyes/ipc/protean
	parent_type = /obj/item/organ/eyes/protean

/obj/item/organ/liver/ipc/protean
	parent_type = /obj/item/organ/liver/protean

/obj/item/organ/ears/cybernetic/protean
	parent_type = /obj/item/organ/ears/protean
