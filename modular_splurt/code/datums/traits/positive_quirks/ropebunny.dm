/datum/quirk/ropebunny
	name = "Верёвочный Кролик"
	desc = "Вы обучены искусно вязать верёвки любой формы. Вы можете создавать веревку из ткани, а из этой веревки - болы!"
	flavor_quirk = TRUE
	value = 2

/datum/quirk/ropebunny/add()
	. = ..()
	var/mob/living/carbon/human/H = quirk_holder
	if (!H)
		return
	var/datum/action/ropebunny/conversion/C = new
	C.Grant(H)

/datum/quirk/ropebunny/remove()
	var/mob/living/carbon/human/H = quirk_holder
	// BLUEMOON EDIT START - sanity check
	if(!H)
		return
	// BLUEMOON EDIT END
	var/datum/action/ropebunny/conversion/C = locate() in H.actions
	C?.Remove(H)
	. = ..()

/datum/action/ropebunny/conversion
	name = "Convert Bondage"
	desc = "Convert five cloth into bondage rope, or convert bondage ropes into bondage bolas."
	icon_icon = 'modular_splurt/icons/obj/clothing/masks.dmi'
	button_icon_state = "ballgag"

/datum/action/ropebunny/conversion/Trigger()
	.=..()
	var/mob/living/carbon/human/H = owner
	var/obj/item/I = H.get_active_held_item()

	if(istype(I,/obj/item/stack/sheet/cloth))
		var/obj/item/stack/sheet/cloth/C = I
		if(C.amount < 5)
			to_chat(H, span_warning("There is not enough cloth left to make more rope!"))
			return
		else
			C.amount -= 5
			new /obj/item/restraints/bondage_rope(H.loc)
			to_chat(H, span_warning("You successfully create a set of bondage ropes."))
			return
	if(istype(I,/obj/item/restraints/bondage_rope))
		new /obj/item/shibola(H.loc)
		to_chat(H, span_warning("You successfully create a shibari bola."))
		qdel(I)
		return
	else
		to_chat(H, span_warning("You must either be holding cloth or a bondage rope to use this ability!"))
