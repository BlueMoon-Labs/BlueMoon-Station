#define DIONA_ROOTS_EQUIP_FAIL "Ваши корни не позволяют вам надеть это."

/obj/item/clothing/suit/space/hardsuit/mob_can_equip(mob/living/M, mob/living/equipper, slot, disable_warning = FALSE, bypass_equip_delay_self = FALSE, clothing_check = FALSE, list/return_warning)
	if(isdiona(M))
		to_chat(M, span_warning(DIONA_ROOTS_EQUIP_FAIL))
		return FALSE
	return ..()

/obj/item/clothing/head/helmet/space/hardsuit/mob_can_equip(mob/living/M, mob/living/equipper, slot, disable_warning = FALSE, bypass_equip_delay_self = FALSE, clothing_check = FALSE, list/return_warning)
	if(isdiona(M))
		to_chat(M, span_warning(DIONA_ROOTS_EQUIP_FAIL))
		return FALSE
	return ..()

#undef DIONA_ROOTS_EQUIP_FAIL
