/datum/supply_pack/science/serverfloors
	name = "Server floor tiles (x4)"
	desc = "Серверное покрытие с необходимой инфраструктурой, сопсобная обеспечить максимально эффективную работу серверов отдела НИО."
	cost = 2500
	access = ACCESS_TOX
	contains = list(/obj/item/stack/tile/circuit,
					/obj/item/stack/tile/circuit,
					/obj/item/stack/tile/circuit,
					/obj/item/stack/tile/circuit)
	crate_name = "circuit floor tiles"
	crate_type = /obj/structure/closet/crate/secure/science
