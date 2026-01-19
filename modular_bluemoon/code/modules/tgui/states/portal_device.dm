/*!
 * BLUEMOON ADD: Portal device TGUI state
 * Allows portal device UI to work when the device is inserted in a genital
 */

GLOBAL_DATUM_INIT(portal_device_state, /datum/ui_state/portal_device_state, new)

/datum/ui_state/portal_device_state/can_use_topic(src_object, mob/user)
	// Standard check (in hands, nearby, etc.)
	. = user.default_can_use_topic(src_object)
	if(. >= UI_INTERACTIVE)
		return .

	// Cast to datum to access GetComponent
	var/datum/D = src_object
	if(!istype(D))
		return .

	// Additional check: item is inside a genital owned by the user
	// Return UI_INTERACTIVE directly, not shared_ui_interaction()
	// because shared_ui_interaction can return UI_UPDATE if MOBILITY_UI flag is missing
	var/datum/component/genital_equipment/equipment = D.GetComponent(/datum/component/genital_equipment)
	if(equipment?.holder_genital?.owner == user)
		// Only check basic conditions (consciousness, client presence)
		if(!user.client)
			return UI_CLOSE
		if(user.stat)
			return UI_DISABLED
		if(user.incapacitated())
			return UI_UPDATE
		return UI_INTERACTIVE  // Full access for owner

	// For worn panties (as underwear or mask)
	if(istype(src_object, /obj/item/clothing/underwear/briefs/panties/portalpanties))
		var/obj/item/clothing/underwear/briefs/panties/portalpanties/PP = src_object
		if(ishuman(PP.loc))
			var/mob/living/carbon/human/H = PP.loc
			if(H == user && (PP.current_equipped_slot & (ITEM_SLOT_UNDERWEAR | ITEM_SLOT_MASK)))
				if(!user.client)
					return UI_CLOSE
				if(user.stat)
					return UI_DISABLED
				if(user.incapacitated())
					return UI_UPDATE
				return UI_INTERACTIVE

	return .
