/obj/item/restraints/handcuffs/armbinder
	name = "Leather Armbinder"
	desc = "Кожаный чехол со шнуровкой и двумя пряжками. Удерживает обе руки за спиной."
	icon = 'modular_splurt/icons/obj/lewd_items/armbinder.dmi'
	icon_state = "armbinder_black"
	item_state = "armbinder_black"
	lefthand_file = 'modular_splurt/icons/mob/inhands/lewd_items/armbinder_lefthand.dmi'
	righthand_file = 'modular_splurt/icons/mob/inhands/lewd_items/armbinder_righthand.dmi'
	mob_overlay_icon = 'modular_splurt/icons/mob/clothing/lewd_clothing/armbinder_worn.dmi'
	handcuff_worn_layer = GENITALS_FRONT_LAYER + 0.5
	unique_reskin = list(
		"Классический" = list(
			RESKIN_ICON_STATE = "armbinder",
			RESKIN_ITEM_STATE = "armbinder",
		),
	)
	gender = NEUTER
	custom_materials = null
	demoralize_criminals = FALSE
	cuffsound = 'modular_splurt/sound/lewd/rope.ogg'

/obj/item/restraints/handcuffs/armbinder/attack(mob/living/carbon/C, mob/living/user)
	if(!ishuman(C))
		to_chat(user, span_warning("Этот чехол рассчитан на руки гуманоида."))
		return
	return ..()

/obj/item/restraints/handcuffs/armbinder/apply_cuffs(mob/living/carbon/target, mob/user, var/dispense = 0)
	if(!ishuman(target) || !target.canBeHandcuffed())
		return
	return ..()

/obj/item/restraints/handcuffs/armbinder/reskin_obj(mob/user)
	. = ..()
	if(!ismob(loc))
		return
	var/mob/holder = loc
	if(holder.get_held_index_of_item(src))
		holder.update_inv_hands()
	else if(holder.get_item_by_slot(ITEM_SLOT_HANDCUFFED) == src)
		holder.update_inv_handcuffed()
