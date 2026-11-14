/datum/quirk/masked_mook
	name = "Синдром Бейна"
	desc = "По какой-то причине вам... не по себе без противогаза на лице."
	gain_text = span_danger("Вы начинаете чувствовать себя нехорошо без противогаза.")
	lose_text = span_notice("У вас больше нет нужды в ношении противогаза.")
	value = -1
	mood_quirk = TRUE
	flavor_quirk = TRUE
	medical_record_text = "Пациент чувствует себя более безопасно при ношении противогаза."
	processing_quirk = TRUE

/datum/quirk/masked_mook/on_process()
	var/mob/living/carbon/human/H = quirk_holder
	var/obj/item/clothing/mask/gas/gasmask = H.get_item_by_slot(ITEM_SLOT_MASK)
	if(istype(gasmask))
		SEND_SIGNAL(quirk_holder, COMSIG_ADD_MOOD_EVENT, QMOOD_MASKED_MOOK, /datum/mood_event/masked_mook)
	else
		SEND_SIGNAL(quirk_holder, COMSIG_ADD_MOOD_EVENT, QMOOD_MASKED_MOOK, /datum/mood_event/masked_mook_incomplete)

/datum/quirk/masked_mook/on_spawn()
	. = ..()
	if(!spawn_items)
		return
	var/mob/living/carbon/human/H = quirk_holder
	var/obj/item/clothing/mask/gas/cosmetic/gasmask = new(get_turf(quirk_holder)) // Uses a custom gas mask
	H.equip_to_slot_if_possible(gasmask, ITEM_SLOT_MASK) // If character have a loadout mask, the custom one will not overwrite it but instead will be dropped on floor
	H.regenerate_icons()
