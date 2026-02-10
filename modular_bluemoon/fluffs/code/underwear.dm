/obj/item/clothing/underwear/briefs/bongepop
	name = "Bongepop Boxers"
	desc = "Потешные боксеры, выполненные в стиле одноименного Банч Попа, сидят идеально вокруг мужских и женских попий."
	icon_state = "boxers_sponge"

/////////////// Трусы крутые ваще жесть. Не скрывают попу при ношении, при этом спрайт не кушается ////////////////
/obj/item/clothing/underwear/briefs/panties/lizared/exposed
	name = "Стринги Millie Secret"
	desc = "Труселя. Пахнут твороженым сыром."
	alternate_worn_layer = SOCKS_LAYER

/obj/item/clothing/underwear/briefs/panties/lizared/exposed/equipped(mob/living/carbon/human/user, slot)
	. = ..()
	if(slot != ITEM_SLOT_UNDERWEAR || !ishuman(user))
		return
	RegisterSignal(user, COMSIG_MOB_ITEM_EQUIPPED, PROC_REF(on_clothing_changed))
	RegisterSignal(user, COMSIG_MOB_UNEQUIPPED_ITEM, PROC_REF(on_clothing_changed))
	update_butt_visibility(user)

/obj/item/clothing/underwear/briefs/panties/lizared/exposed/dropped(mob/living/carbon/human/user)
	if(ishuman(user))
		UnregisterSignal(user, list(COMSIG_MOB_ITEM_EQUIPPED, COMSIG_MOB_UNEQUIPPED_ITEM))
		var/obj/item/organ/genital/butt/booty = user.getorganslot(ORGAN_SLOT_BUTT)
		if(booty)
			booty.genital_flags &= ~GENITAL_THROUGH_CLOTHES
			user.update_genitals()
	return ..()

/obj/item/clothing/underwear/briefs/panties/lizared/exposed/proc/on_clothing_changed(mob/living/carbon/human/user)
	SIGNAL_HANDLER
	addtimer(CALLBACK(src, PROC_REF(update_butt_visibility), user), 1)

/obj/item/clothing/underwear/briefs/panties/lizared/exposed/proc/update_butt_visibility(mob/living/carbon/human/user)
	if(QDELETED(user) || QDELETED(src) || user.w_underwear != src)
		return
	var/obj/item/organ/genital/butt/booty = user.getorganslot(ORGAN_SLOT_BUTT)
	if(!booty || (booty.genital_flags & GENITAL_HIDDEN))
		return
	var/groin_covered = FALSE
	for(var/obj/item/I in user.get_equipped_items())
		if(I == src)
			continue
		if(I.body_parts_covered & GROIN)
			groin_covered = TRUE
			break
	if(!groin_covered)
		booty.genital_flags |= GENITAL_THROUGH_CLOTHES
		user.update_genitals()
		var/list/exposed = user.overlays_standing[GENITALS_EXPOSED_LAYER]
		if(islist(exposed))
			user.remove_overlay(GENITALS_EXPOSED_LAYER)
			for(var/mutable_appearance/MA in exposed)
				MA.layer = -UNDERWEAR_LAYER
			user.overlays_standing[GENITALS_EXPOSED_LAYER] = exposed
			user.apply_overlay(GENITALS_EXPOSED_LAYER)
	else
		booty.genital_flags &= ~GENITAL_THROUGH_CLOTHES
		user.update_genitals()

////////////////////////////////////////////////////
