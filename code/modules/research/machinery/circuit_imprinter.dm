/obj/machinery/rnd/production/circuit_imprinter
	name = "Circuit Imprinter"
	desc = "Производит электронные платы для сбора машинерии."
	icon_state = "circuit_imprinter"
	circuit = /obj/item/circuitboard/machine/circuit_imprinter
	categories = list(
							"Computer Boards",
							"Teleportation Machinery",
							"Subspace Telecomms",
							"Research Machinery",
							"Medical Machinery",
							"Engineering Machinery",
							"Production Machinery",
							"Shuttle Machinery",
							"Hydroponics Machinery",
							"Culinary Machinery",
							"Computer Parts",
							"Cargo Machinery",
							"Misc. Machinery",
								)
	production_animation = "circuit_imprinter_ani"
	allowed_buildtypes = IMPRINTER

/obj/machinery/rnd/production/circuit_imprinter/disconnect_console()
	linked_console.linked_imprinter = null
	..()

/obj/machinery/rnd/production/circuit_imprinter/AfterMaterialInsert() //doesnt use have an animation like lathes do
	return

/////// BLUEMOON ADD хакнутый принтер для печатки вещей, требующих код, в любом месте.
/obj/machinery/rnd/production/circuit_imprinter/hacked
	name = "hacked imprinter"
	desc = "Производит электронные платы для сбора машинерии. Конкретно этот тип принтеров запрещён к использованию во многих корпорациях с делением власти между множеством отделов.."
	circuit = /obj/item/circuitboard/machine/circuit_imprinter/hacked
	requires_console = 0
	obj_flags = CAN_BE_HIT | EMAGGED
	categories = list(
							"AI Modules",
							"Computer Boards",
							"Teleportation Machinery",
							"Medical Machinery",
							"Engineering Machinery",
							"Exosuit Modules",
							"Hydroponics Machinery",
							"Subspace Telecomms",
							"Research Machinery",
							"Computer Parts",
							"Shuttle Machinery",
							"Production Machinery",
							"Cargo Machinery",
							"Culinary Machinery",
							"Misc. Machinery",
								)
