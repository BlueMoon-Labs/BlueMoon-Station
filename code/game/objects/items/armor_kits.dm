// Armor kits! Reinforcing uniforms to maintain fashion and also armor capabilities.

/obj/item/armorkit
	name = "debug armor kit"
	desc = "Basetype for armor kits. Message your hot local admins if you aren't one."
	icon = 'icons/obj/clothing/reinf_kits.dmi'
	w_class = WEIGHT_CLASS_SMALL
	icon_state = "durathread_kit" // shoutout to my guy Toriate for being good at sprites tho
	var/kit_slot_flag = ITEM_SLOT_ICLOTHING	// Only items with no clothing flags but this one can receive this armorkit. Reinforced clothing will also inherit this variable's contents.
	var/obj/item/clothing/parent_armor_type = /obj/item/clothing/under/misc/durathread	// Path of the parent armor we're copiyng stats from
	var/kit_prefix = "armored"	// Used for prefix and name changing. For "aegis armor kit" it should be "aegis"

// This is an amalgamation of newer BlueMoon armor kit's, and older durathread kit's afterattack procedures
// It should be universal for all armor kits, replacing cursed copy-pasted overrides
/obj/item/armorkit/afterattack(obj/item/target, mob/user, proximity_flag, click_parameters)
	if(!istype(target, /obj/item/clothing))
		return
	var/obj/item/clothing/C = target

	if(!(C.slot_flags & kit_slot_flag))
		to_chat(user, span_danger("You cannot modify [C] with this reinforcement kit."))
		return
	if(istype(C, /obj/item/clothing/suit/space) || istype(C, /obj/item/clothing/suit/armor) || istype(C, /obj/item/clothing/suit/toggle/captains_parade))
		to_chat(user, span_danger("You cannot modify [C], as it already has armor or is a part of special equipment."))
		return

	// Following checks are specific to jumpsuits, jumpskirts and other stuff with that clothing slot.
	// If and when someone decides to add more such specific checks for other types, i recommend changing it to switch(kit_slot_flag)
	if(kit_slot_flag == ITEM_SLOT_ICLOTHING && istype(C, /obj/item/clothing/under))
		var/obj/item/clothing/under/J = C
		if(J.damaged_clothes)
			to_chat(user,"<span class='warning'>You should repair the damage done to [C] first.</span>")
			return
		if(LAZYLEN(J.attached_accessories))
			to_chat(user,"<span class='warning'>Kind of hard to sew around [J.attached_accessories.Join(", ")].</span>")
			return

	if(C.reinforced)
		to_chat(user,"<span class='warning'>[C] had already been reinforced with an armor kit.</span>")
		return

	if(ishuman(C.loc))
		if(!(C.current_equipped_slot & kit_slot_flag))	// Check if the user is wearing item somewhere where he won't be wear it after reinforcement finishes
			to_chat(user, "<span class='warning'>You cannot reinforce [C], while wearing it on your [slot_to_string(C.current_equipped_slot)].</span>")
			return	// Prevents people from bypassing clothing slot lock by equipping it in advance.

	var/obj/item/clothing/P = new parent_armor_type(src)
	C.set_armor(P.armor)
	C.body_parts_covered = P.body_parts_covered
	C.cold_protection = P.cold_protection
	C.heat_protection = P.heat_protection
	C.resistance_flags = P.resistance_flags
	C.clothing_flags = P.clothing_flags
	C.min_cold_protection_temperature = P.min_cold_protection_temperature
	C.max_heat_protection_temperature = P.max_heat_protection_temperature
	C.allowed = P.allowed

	user.visible_message("<span class = 'notice'>[user] reinforces [C] with [src].</span>", \
	"<span class = 'notice'>You reinforce [C] with [src], making it as protective as a [P.name].</span>")
	qdel(P)
	C.name = "[kit_prefix] [C.name]"
	C.upgrade_prefix = "[kit_prefix]"
	C.on_reinforcement(kit_slot_flag)	// Handles cross-slot and slot-changing clothing, no more rampart headgear stacking
	qdel(src)
	return

/obj/item/armorkit/durathread
	name = "durathread jumpsuit reinforcement kit"
	desc = "A glorified sewing kit with durathread sheets, thread, and a titanium needle, for reinforcing jumpsuits and uniforms."
	kit_prefix = "durathread"

/obj/item/armorkit/durathread/vest
	name = "durathread armor kit"
	desc = "A glorified sewing kit with durathread sheets, thread, and a titanium needle. This one is for outer clothing."
	parent_armor_type = /obj/item/clothing/suit/armor/vest/durathread
	kit_slot_flag = ITEM_SLOT_OCLOTHING
	kit_prefix = "durathread"

/obj/item/armorkit/durathread/helmet
	name = "durathread headgear kit"
	desc = "A glorified sewing kit with durathread sheets, thread, and a titanium needle. This one is for headgear."
	parent_armor_type = /obj/item/clothing/head/helmet/durathread
	kit_slot_flag = ITEM_SLOT_HEAD
	kit_prefix = "durathread"
