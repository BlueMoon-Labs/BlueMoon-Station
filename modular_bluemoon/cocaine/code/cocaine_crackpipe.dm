/obj/item/clothing/mask/cigarette/pipe/crackpipe
	name = "crack pipe"
	desc = "A slick, glass pipe made for smoking one thing: crack."
	icon = 'modular_bluemoon/cocaine/icons/crack.dmi'
	mob_overlay_icon = 'modular_bluemoon/cocaine/icons/mask.dmi'
	icon_state = "glass_pipeoff"
	icon_on = "glass_pipeon"
	icon_off = "glass_pipeoff"
	chem_volume = 20
	custom_materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 5.05, /datum/material/glass = SHEET_MATERIAL_AMOUNT * 1.05)

/obj/item/clothing/mask/cigarette/pipe/crackpipe/process()
	smoketime--
	if(smoketime < 1)
		new /obj/effect/decal/cleanable/ash(get_turf(src))
		if(ismob(loc))
			var/mob/living/smoking_mob = loc
			to_chat(smoking_mob, span_notice("Your [name] goes out."))
			smoking_mob.update_inv_wear_mask()
		wasted()
		return
	open_flame()
	if(reagents?.total_volume)
		handle_reagents()
	try_smoke_flavor_emote()

/obj/item/clothing/mask/cigarette/pipe/crackpipe/attackby(obj/item/attacking_item, mob/user, list/modifiers, list/attack_modifiers)
	if(istype(attacking_item, /obj/item/reagent_containers/crack))
		if(!packeditem)
			to_chat(user, span_notice("You stuff [attacking_item] into [src]."))
			smoketime = 2 * 60
			packeditem = 1
			name = "[attacking_item.name]-packed [initial(name)]"
			if(attacking_item.reagents)
				attacking_item.reagents.trans_to(src, attacking_item.reagents.total_volume, log = "crack pipe: stuff")
			qdel(attacking_item)
		else
			to_chat(user, span_warning("It is already packed!"))
	else
		var/lighting_text = attacking_item.ignition_effect(src, user)
		if(lighting_text)
			if(smoketime > 0)
				light(lighting_text)
			else
				to_chat(user, span_warning("There is nothing to smoke!"))
		else
			return ..()

/datum/crafting_recipe/crackpipe
	name = "Crack pipe"
	result = /obj/item/clothing/mask/cigarette/pipe/crackpipe
	reqs = list(/obj/item/stack/cable_coil = 5,
				/obj/item/shard = 1,
				/obj/item/stack/rods = 10)
	parts = list(/obj/item/shard = 1)
	time = 20
	category = CAT_CHEMISTRY
