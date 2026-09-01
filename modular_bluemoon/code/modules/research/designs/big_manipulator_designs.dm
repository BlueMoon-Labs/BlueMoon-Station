// Big Manipulator designs

/datum/design/board/big_manipulator
	name = "Machine Design (Big Manipulator Board)"
	desc = "The circuit board for a big manipulator."
	id = "big_manipulator"
	build_path = /obj/item/circuitboard/machine/big_manipulator
	category = list("Engineering Machinery")
	departmental_flags = DEPARTMENTAL_FLAG_ALL

/datum/design/manipulator_task_disk
	name = "Machine Design (Manipulator Task Disk)"
	desc = "A floppy disk for storing big manipulator task programs."
	id = "manipulator_task_disk"
	build_type = PROTOLATHE | IMPRINTER
	materials = list(/datum/material/glass = 500, /datum/material/iron = 200)
	build_path = /obj/item/disk/manipulator
	category = list("Engineering Machinery")
	departmental_flags = DEPARTMENTAL_FLAG_ALL
