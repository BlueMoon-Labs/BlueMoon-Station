/obj/item/stock_parts/cell/bluespacereactor
	name = "bluespace reactor power cell"
	desc = "A self charging transdimensional power cell, houses a miniature reactor within its bluespace power pocket. Suffers in terms of capacity as a result and radiates while working."
	icon_state = "bsreactorcell"
	maxcharge = 10000
	custom_materials = list(/datum/material/glass=600)
	chargerate = 200
	rating = 5
	self_recharge = 1
	cell_is_radioactive = TRUE
	rad_strength = 50
