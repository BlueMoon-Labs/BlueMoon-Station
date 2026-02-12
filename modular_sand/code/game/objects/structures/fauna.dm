/obj/item/kirbyplants/brass
	name = "cog plant" //cog plant my beloved
	desc = "An odd looking plant that has a spinning gear, does it resemble a sunflower?"
	icon = 'modular_sand/icons/obj/flora/plants.dmi'
	icon_state = "plant-01"

/obj/item/kirbyplants/plasma
	name = "plasma plant"
	desc = "A pretty plant, it seems safe, considering what it's made of."
	icon = 'modular_sand/icons/obj/flora/plants.dmi'
	icon_state = "plant-02"

///obj/item/kirbyplants/diamond
//	name = "diamond plant"
//	desc = "Shining diamond plant that doesnt even glow."
//	icon = 'modular_nostra/icons/obj/flora/plants.dmi'
//	icon_state = "plant-03"
// not used cause requires lots of respriting which im lazy to do now

/obj/item/kirbyplants/hedge
	name = "Hedge"
	desc = "A large bushy hedge."
	icon = 'icons/obj/smooth_structures/hedge.dmi'
	icon_state = "hedge"

/obj/structure/hedge
	name = "Hedge"
	desc = "A large bushy hedge."
	icon = 'icons/obj/smooth_structures/hedge.dmi'
	icon_state = "hedge"
	smooth = SMOOTH_TRUE
	canSmoothWith = list(/obj/structure/hedge)
	anchored = TRUE
	max_integrity = 80
