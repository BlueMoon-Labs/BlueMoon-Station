/// Extra examine text shown on select NIF items, such as the Cerulean Icons.
/obj/item
	/// Extra flavor text that gets appended to the examine of the item. Can be null.
	var/special_desc

/obj/item/examine(mob/user)
	. = ..()
	if(special_desc)
		. += span_blue("[special_desc]")
