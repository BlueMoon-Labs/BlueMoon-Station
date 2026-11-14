/obj/item/clothing/neck
	is_edible = 1

/obj/item/clothing/neck/stethoscope
	is_edible = 2

/obj/item/clothing/neck/petcollar/locked/security
	name = "security collar"
	desc = "For when you need to show everyone who your pet belongs to."
	icon = 'modular_splurt/icons/obj/clothing/neck.dmi'
	icon_state = "seccollar"
	poly_states = 0
	is_edible = 0

/obj/item/clothing/neck/petcollar/spike
	name = "Spiked Pet Collar"
	desc = "A collar with spikes that look as sharp as your teeth. Doesn't seem very good for neck cuddles."
	icon = 'modular_splurt/icons/obj/clothing/neck/collars.dmi'
	mob_overlay_icon = 'modular_splurt/icons/mob/clothing/neck.dmi'
	icon_state = "collar_spik"
	poly_states = 0
	is_edible = 0

/obj/item/clothing/neck/petcollar/locked/spike
	name = "Spiked Pet Collar"
	desc = "A collar with spikes that look as sharp as your teeth. Doesn't seem very good for neck cuddles."
	icon = 'modular_splurt/icons/obj/clothing/neck/collars.dmi'
	mob_overlay_icon = 'modular_splurt/icons/mob/clothing/neck.dmi'
	icon_state = "collar_spik"
	poly_states = 0

/obj/item/clothing/neck/petcollar/holo
	name = "Holo-collar"
	desc = "An expensive holo-collar for the modern day pet."
	icon = 'modular_splurt/icons/obj/clothing/neck/collars.dmi'
	mob_overlay_icon = 'modular_splurt/icons/mob/clothing/neck.dmi'
	icon_state = "collar_holo"
	poly_colors = list("#33FFFF")

/obj/item/clothing/neck/petcollar/locked/holo
	name = "Holo-collar"
	desc = "An expensive holo-collar for the modern day pet."
	icon = 'modular_splurt/icons/obj/clothing/neck/collars.dmi'
	mob_overlay_icon = 'modular_splurt/icons/mob/clothing/neck.dmi'
	icon_state = "collar_holo"
	poly_colors = list("#33FFFF")
	is_edible = 0

/obj/item/clothing/neck/petcollar/casino
	name = "Casino Collar"
	desc = "A fancy collar whose neon hue neatly changes with time. Once probably used to mark living prizes, but it only seems to be a cool item now."
	icon = 'modular_splurt/icons/obj/clothing/neck/collars.dmi'
	mob_overlay_icon = 'modular_splurt/icons/mob/clothing/neck.dmi'
	icon_state = "casinoslave"
	poly_states = 0

/obj/item/clothing/neck/petcollar/locked/casino
	name = "Casino Collar"
	desc = "A fancy collar whose neon hue neatly changes with time. Once probably used to mark living prizes."
	icon = 'modular_splurt/icons/obj/clothing/neck/collars.dmi'
	mob_overlay_icon = 'modular_splurt/icons/mob/clothing/neck.dmi'
	icon_state = "casinoslave_available"
	poly_states = 0
	is_edible = 0

/obj/item/clothing/neck/petcollar/locked/casino/attackby(obj/item/K, mob/user, params)
	. = ..()
	if(lock)
		icon_state = "casinoslave_owned"
	else
		icon_state = "casinoslave_available"

/obj/item/clothing/neck/petcollar/handmade
	name = "handmade collar"
	desc = "A collar made out of pliable material."
	icon = 'modular_splurt/icons/obj/clothing/neck/collars.dmi'
	mob_overlay_icon = 'modular_splurt/icons/mob/clothing/neck.dmi'
	icon_state = "collar_handmade"
	poly_states = 0

/obj/item/clothing/neck/petcollar/poly
	name = "pet collar (poly)"
	icon = 'modular_splurt/icons/obj/clothing/neck/collars.dmi'
	mob_overlay_icon = 'modular_splurt/icons/mob/clothing/neck.dmi'
	icon_state = "petcollar"
	poly_states = 2
	poly_colors = list("#00bb70", "#FFC600")

/obj/item/clothing/neck/cloak/altpolychromic
	name = "polychromic cloak alt"
	icon = 'modular_splurt/icons/obj/clothing/neck.dmi'
	mob_overlay_icon = 'modular_splurt/icons/mob/clothing/neck.dmi'
	icon_state = "poly_cloak"
	var/poly_colors = list("#FFFFFF", "#808080")

/obj/item/clothing/neck/cloak/altpolychromic/ComponentInitialize()
	. = ..()
	AddElement(/datum/element/polychromic, poly_colors, 2)

// BLUEMOON ADD - шарф из меха шейдкина (портировано из S.P.L.U.R.T-tg)
/obj/item/clothing/neck/scarf/shadekin
	name = "shadekin fur scarf"
	desc = "Неэтичный шарф, сшитый из мягкого меха и податливых шкур шейдкинов. Нелегален почти во всех областях обжитого космоса, но всё равно высоко ценится элитами и пиратами."
	icon = 'modular_splurt/icons/obj/clothing/neck/shadekin_scarf.dmi'
	mob_overlay_icon = 'modular_splurt/icons/mob/clothing/neck/shadekin_scarf.dmi'
	icon_state = "scarf_unethical"
