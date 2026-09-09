/obj/item/stock_parts/cell/vortex
	name = "vortex power cell"
	desc = "A rechargeable transdimensional power cell."
	icon = 'modular_sand/icons/obj/power.dmi'
	icon_state = "vortexcell"
	maxcharge = 60000
	custom_materials = list(/datum/material/glass=600)
	chargerate = 1500 //Recharges slowly.
	self_recharge = 1
	rating = 6

/obj/item/stock_parts/cell/vortex/empty
	start_charged = FALSE
