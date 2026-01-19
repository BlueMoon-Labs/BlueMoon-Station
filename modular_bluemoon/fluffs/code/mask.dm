/obj/item/clothing/mask/magickitsune/equipped(mob/user, slot)
	. = ..()
	for(var/mob/living/M in get_hearers_in_view(4, user))
		if(!pickupsound)
			return
		if(!ishuman(user))
			return
		if(slot == ITEM_SLOT_MASK)
			if(!firstpickup)
				SEND_SOUND(M, sound('sound/magic/Smoke.ogg', volume = 50))
			else
				firstpickup = FALSE
				SEND_SOUND(M, sound('sound/magic/Smoke.ogg', volume = 50))
	return

/datum/component/fluff
	var/message_equip = "Kitsune magic appears!"
	var/message_drop = "Kitsune magic dissapears!"

/datum/component/fluff/Initialize(message_equip="Kitsune magic appears!", message_drop="Kitsune magic dissapears!", playsound_equip="/sound/magic/ForceWall.ogg", playsound_drop="/sound/magic/ForceWall.ogg")
	if(isitem(parent))
		RegisterSignal(parent, COMSIG_ITEM_EQUIPPED, PROC_REF(on_equip))
		RegisterSignal(parent, COMSIG_ITEM_DROPPED, PROC_REF(on_drop))
	else
		return COMPONENT_INCOMPATIBLE

/datum/component/fluff/proc/on_equip(datum/source, mob/equipper, slot)
	equipper.visible_message("<span class='warning'> [message_equip]</span>")

/datum/component/fluff/proc/on_drop(datum/source, mob/user)
	user.visible_message("<span class='warning'> [message_drop]</span>")

/obj/item/clothing/mask/paper/underhair
	name = "The paper mask"
	alternate_worn_layer = BACK_LAYER

/obj/item/clothing/mask/gas/syndicate/cool_version/mihana_mask
	name = "Andromeda Mask"
	desc = "A close-fitting tactical mask that can be connected to an air supply."
	icon_state = "mihana_mask"

/obj/item/clothing/mask/gas/srt_mask
	name = "SRT Balaclava with Eye patch"
	desc = "Ordinary Balaclava with non-ordinary Eyepatch. It's is an optoelectronic device invented by Unknown Syndicate company. The Device appeared similar to a plastic eye patch, with text of the device name and serial number printed on the front, with a small camera lens positioned below. It can detect in body temperature, heart rate and sweat secretion to calculate a subject's physical and emotional state. "
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/mask.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/mask.dmi'
	icon_state = "srt_mask"
	item_state = "srt_mask"

/obj/item/clothing/mask/gas/syndicate/hahun_mask/eo95_mask
	name = "EO-95 mask"
	desc = "A mask with ariral design, emits  a strange purple particles around it, allow the user to breath more cleaner air, \
			that would be safer for it's owner because of anatomy of arirals."
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/mask.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/mask.dmi'
	icon_state = "eo-95_mask"

/obj/item/clothing/mask/hair_module
	name = "Hair Module"
	desc = "Этот модуль крепится к голове СПУ. В дополнение к косметическим функциям, в этот модуль встроены датчики."
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/mask.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/mask.dmi'
	icon_state = "hair_module_mask"
	item_state = "hair_module_mask"
	body_parts_covered = NONE

/obj/item/clothing/mask/breath/gestapo
	name = "Truth Enforcer mask"
	desc = "Filter their thoughts"
	icon_state = "gestapo_mask"
	item_state = "gestapo_mask"
	icon = 'modular_bluemoon/icons/obj/clothing/masks.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/masks.dmi'
	lefthand_file = 'modular_bluemoon/icons/mob/inhands/clothing_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/mob/inhands/clothing_righthand.dmi'
