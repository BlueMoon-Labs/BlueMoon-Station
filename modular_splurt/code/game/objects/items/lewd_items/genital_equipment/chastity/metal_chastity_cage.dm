/obj/item/genital_equipment/chastity_cage/metal
	name = "metal chastity cage"
	icon_state = "metal_cage"

	break_time = 40 SECONDS
	break_require = TOOL_WELDER

	var/mutable_appearance/skin_overlay
	var/skin_overlay_layer = -(GENITALS_FRONT_LAYER - 0.01)

/obj/item/genital_equipment/chastity_cage/metal/item_inserted(datum/source, obj/item/organ/genital/G, mob/user)
	. = ..() // Call the parent proc
	var/mob/living/carbon/human/H = G.owner

	var/cock_taur = H?.dna?.features["cock_taur"]
	skin_overlay = mutable_appearance(mob_overlay_icon, "worn_[icon_state]_[cage_sprite][cock_taur ? "_taur" : ""]_skin", skin_overlay_layer)
	skin_overlay.color = G.color

	skin_overlay = apply_overlay(G, skin_overlay)

/obj/item/genital_equipment/chastity_cage/metal/mob_update_genitals(datum/source)
	updt_overlay(source, skin_overlay)
	. = ..()

/obj/item/genital_equipment/chastity_cage/metal/item_removed(datum/source, obj/item/organ/genital/G, mob/user)
	. = ..()
	if(!.)
		return
	var/mob/living/carbon/human/H = G.owner
	if(!H)
		return
	H.cut_overlay(skin_overlay)

