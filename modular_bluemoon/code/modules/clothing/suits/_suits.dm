/obj/item/clothing/suit/apron/chef/AltClick()
	. = ..()
	body_parts_covered = body_parts_covered ? NONE : CHEST|GROIN
	to_chat(usr, "<span class='notice'>Your [src] is [body_parts_covered ? "now covering your chest and groin" : "no longer covering anything"].</span>")
	return TRUE
