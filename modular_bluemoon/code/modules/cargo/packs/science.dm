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

/datum/supply_pack/science/nif_autosurgeon
	name = "Nanite Implant Framework (Standard Type)"
	desc = "Автохирург с имплантом класса Standard Type - калиброванный Nanite Implant Framework, который связывается с носителем и запускает нейро-интерфейс нанитов. Перед применением требуется завершить калибровку."
	cost = 5000
	access = ACCESS_TOX
	contains = list(/obj/item/autosurgeon/nif)
	crate_name = "nanite implant framework"
	crate_type = /obj/structure/closet/crate/secure/science
