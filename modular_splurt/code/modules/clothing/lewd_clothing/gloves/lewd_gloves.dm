//latex gloves
/obj/item/clothing/gloves/latex_gloves
	name = "Latex gloves"
	desc = "Awesome looking gloves that are satisfying to the touch."
	icon_state = "latexgloves"
	item_state = "latexgloves"
	w_class = WEIGHT_CLASS_SMALL
	icon = 'modular_splurt/icons/obj/clothing/lewd_clothes/gloves/lewd_gloves.dmi'
	mob_overlay_icon = 'modular_splurt/icons/mob/clothing/lewd_clothing/gloves/lewd_gloves.dmi'

/obj/item/clothing/gloves/latex_gloves/Initialize()
	. = ..()
	AddComponent(/datum/component/latex_lockable, FALSE, list(
		"You rub your gloved fingers together as you search for some sort of escape.",
		"You can't find any leverage to remove these gloves!",
		"Your pointless clawing seems to only make things more skin tight",
	))
