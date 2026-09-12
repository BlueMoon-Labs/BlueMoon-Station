/obj/item/anomaly_neutralizer
	name = "anomaly neutralizer"
	desc = "Одноразовое устройство для захвата и стабилизации аномальных образований."
	icon = 'icons/obj/device.dmi'
	icon_state = "neutralyzer"
	item_state = "electronic"
	lefthand_file = 'icons/mob/inhands/misc/devices_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/devices_righthand.dmi'
	w_class = WEIGHT_CLASS_SMALL
	slot_flags = ITEM_SLOT_BELT
	item_flags = NOBLUDGEON

/obj/item/anomaly_neutralizer/afterattack(atom/target, mob/user, proximity)
	..()
	if(!proximity || !target)
		return
	if(istype(target, /obj/effect/anomaly))
		var/obj/effect/anomaly/A = target
		to_chat(user, span_notice("Электроника устройства поджаривается в процессе нейтрализации [A]!"))
		A.anomalyNeutralize(FALSE)
		qdel(src)
