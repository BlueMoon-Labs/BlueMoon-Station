/obj/item/clothing/head/helmet/space/ervos
	name = "ERVOS helmet"
	desc = "Emergency Rescue VOid Suit helmet"
	icon_state = "ervos"
	item_state = "ervos_head"
	flags_inv = null // нацепил аквариум на голову и довольный
	repairable_by = /obj/item/stack/sheet/glass
	mutantrace_variation = NONE
	icon = 'modular_bluemoon/icons/obj/clothing/head/ervos.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/head/ervos.dmi'
	lefthand_file = 'modular_bluemoon/icons/mob/inhands/clothing_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/mob/inhands/clothing_righthand.dmi'
	armor = list(MELEE = 0, BULLET = 0, LASER = 0,ENERGY = 0, BOMB = 0, BIO = 100, RAD = 0, FIRE = 0, ACID = 0, WOUND = 0)

/obj/item/clothing/suit/space/ervos
	name = "ERVOS"
	desc = "Emergency Rescue VOid Suit"
	icon_state = "ervos"
	item_state = "ervos"
	repairable_by = /obj/item/stack/sticky_tape
	icon = 'modular_bluemoon/icons/obj/clothing/suits/ervos.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/suits/ervos.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/icons/mob/clothing/suits/armor_digi.dmi'
	lefthand_file = 'modular_bluemoon/icons/mob/inhands/clothing_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/mob/inhands/clothing_righthand.dmi'
	armor = list(MELEE = 0, BULLET = 0, LASER = 0,ENERGY = 0, BOMB = 0, BIO = 100, RAD = 0, FIRE = 0, ACID = 0, WOUND = 0)
	slowdown = 2

/obj/item/clothing/suit/space/ervos/equipped()
	..()
	START_PROCESSING(SSobj, src)

/obj/item/clothing/suit/space/ervos/dropped()
	..()
	STOP_PROCESSING(SSobj, src)

/obj/item/clothing/suit/space/ervos/process()
	if(!isspaceturf(get_turf(src)))
		return
	if(!(clothing_flags & STOPSPRESSUREDAMAGE))
		return

	var/integrity_check = obj_integrity // увы у take_damage нет ретёрнов чтобы сделать это лучше (а я не хочу рисковать всё сломать)
	take_damage(25, sound_effect = FALSE)
	playsound(src, 'sound/misc/tear_apart.ogg', 15, 1)
	if(integrity_check > obj_integrity)
		if(integrity_check == max_integrity) // Впервые получаем урон
			visible_message(span_warning("[src] начинает надрываться от космического давления."))
		else if(prob(25))
			visible_message(span_warning("Надрывы на [src] становятся всё заметнее из-за космического давления."))

/obj/item/clothing/suit/space/ervos/obj_break(damage_flag)
	. = ..()
	clothing_flags &= ~STOPSPRESSUREDAMAGE

/obj/item/clothing/suit/space/ervos/repair(mob/user, params)
	. = ..()
	clothing_flags |= STOPSPRESSUREDAMAGE
