//miner exclusives
/datum/uplink_item/role_restricted/crusher
	name = "Harmful Crusher"
	desc = "Кинетический крашер, способный наносить урон сложным и мелким формам жизни. На расстоянии выглядит как обычный крашер."
	item = /obj/item/kinetic_crusher/harm
	cost = 15
	limited_stock = 1
	restricted_roles = list("Shaft Miner", "Quartermaster")

/datum/uplink_item/role_restricted/pka_tenmm
	name = "10mm Proto-Kinetic Accelerator"
	desc = "Акселератор, заряженный патронами 10мм. Принимает обычные модификации PKA, не имеет штрафа от давления и на расстоянии выглядит как обычный акселератор."
	item = /obj/item/gun/energy/kinetic_accelerator/tenmm
	cost = 15
	limited_stock = 1
	restricted_roles = list("Shaft Miner", "Quartermaster")

/datum/uplink_item/role_restricted/pka_nopenalty
	name = "On-station Proto-Kinetic Accelerator"
	desc = "Акселератор, не получающий штрафов от повышения давления."
	item = /obj/item/gun/energy/kinetic_accelerator/nopenalty
	cost = 15
	limited_stock = 1
	restricted_roles = list("Shaft Miner", "Quartermaster")
