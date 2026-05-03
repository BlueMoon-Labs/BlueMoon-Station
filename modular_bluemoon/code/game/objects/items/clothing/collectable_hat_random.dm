/obj/item/clothing/head/collectable/random_metashop
	name = "коллекционная шляпа (случайная)"
	desc = "Заказ из метамагазина: при выдаче превращается в одну из коллекционных шляп серии."
	icon_state = "petehat"

/obj/item/clothing/head/collectable/random_metashop/Initialize(mapload)
	. = ..()
	var/list/options = subtypesof(/obj/item/clothing/head/collectable)
	options -= type
	if(!length(options))
		return INITIALIZE_HINT_QDEL
	var/picked = pick(options)
	var/obj/item/clothing/head/collectable/actual = new picked(loc)
	transfer_fingerprints_to(actual)
	qdel(src)
	return INITIALIZE_HINT_QDEL
