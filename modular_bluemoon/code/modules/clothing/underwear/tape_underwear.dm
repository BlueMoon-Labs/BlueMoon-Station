/obj/item/clothing/underwear/shirt/adjustable/toggle/black_tape
	name = "Black Sticky Tape Top"
	desc = "Идеальна для закрытия протечек."
	icon = 'modular_bluemoon/icons/obj/clothing/tape_underwear.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/tape_underwear.dmi'
	icon_state = "tape_breasts"
	togglename = "wearing style"
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON

/obj/item/clothing/underwear/shirt/adjustable/toggle/black_tape/equipped(mob/user, slot)
	. = ..()
	if(slot == ITEM_SLOT_SHIRT && ishuman(user))
		var/mob/living/carbon/human/H = user
		H.handle_post_sex(5, null, H)

/obj/item/clothing/underwear/shirt/adjustable/toggle/black_tape/dropped(mob/user)
	var/was_shirt = (current_equipped_slot == ITEM_SLOT_SHIRT)
	. = ..()
	if(was_shirt && ishuman(user))
		var/mob/living/carbon/human/H = user
		playsound(loc, 'sound/items/poster_ripped.ogg', 20, 1)
		H.handle_post_sex(5, null, H)
		H.moan()

/obj/item/clothing/underwear/briefs/black_tape
	name = "Black Sticky Tape Groin"
	desc = "Идеальна для закрытия протечек."
	icon = 'modular_bluemoon/icons/obj/clothing/tape_underwear.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/tape_underwear.dmi'
	icon_state = "tape_groin"
	body_parts_covered = 0 //thicc thigs and ass must not be hidden.
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON

/obj/item/clothing/underwear/briefs/black_tape/update_icon_state()
	. = ..()
	if(current_equipped_slot == ITEM_SLOT_UNDERWEAR && istype(loc, /mob/living/carbon/human))
		var/mob/living/carbon/human/H = loc
		icon_state = "[initial(icon_state)][H.has_penis() ? "_buldge" : ""]"
		H.update_inv_w_underwear()
	else
		icon_state = "[initial(icon_state)]"

/obj/item/clothing/underwear/briefs/black_tape/equipped(mob/user, slot)
	. = ..()
	if(slot == ITEM_SLOT_UNDERWEAR)
		update_icon()
		var/mob/living/carbon/human/H = user
		H.handle_post_sex(5, null, H)
		//Imitating genital coverage. Thigs and ass will still be visible. Exactly what we need.
		var/obj/item/organ/genital/penis/P = H.getorganslot(ORGAN_SLOT_PENIS)
		P?.toggle_visibility(GEN_VISIBLE_NEVER) //How 100+ penis can be hidden with a piece of tape? Bluespace anomaly. Like all other underwear.
		var/obj/item/organ/genital/testicles/T = H.getorganslot(ORGAN_SLOT_TESTICLES)
		T?.toggle_visibility(GEN_VISIBLE_NEVER)
		var/obj/item/organ/genital/vagina/V = H.getorganslot(ORGAN_SLOT_VAGINA)
		V?.toggle_visibility(GEN_VISIBLE_NEVER)
		var/obj/item/organ/genital/anus/A = H.getorganslot(ORGAN_SLOT_ANUS)
		A?.toggle_visibility(GEN_VISIBLE_NEVER)

/obj/item/clothing/underwear/briefs/black_tape/dropped(mob/user)
	. = ..()
	if(current_equipped_slot == ITEM_SLOT_UNDERWEAR)
		update_icon()
		var/mob/living/carbon/human/H = user
		playsound(loc, 'sound/items/poster_ripped.ogg', 20, 1)
		H.handle_post_sex(5, null, H)
		H.moan()
		//Uncovering things.
		var/obj/item/organ/genital/penis/P = H.getorganslot(ORGAN_SLOT_PENIS)
		P?.toggle_visibility(GEN_VISIBLE_NO_UNDIES)
		var/obj/item/organ/genital/testicles/T = H.getorganslot(ORGAN_SLOT_TESTICLES)
		T?.toggle_visibility(GEN_VISIBLE_NO_UNDIES)
		var/obj/item/organ/genital/vagina/V = H.getorganslot(ORGAN_SLOT_VAGINA)
		V?.toggle_visibility(GEN_VISIBLE_NO_UNDIES)
		var/obj/item/organ/genital/anus/A = H.getorganslot(ORGAN_SLOT_ANUS)
		A?.toggle_visibility(GEN_VISIBLE_NO_UNDIES)
