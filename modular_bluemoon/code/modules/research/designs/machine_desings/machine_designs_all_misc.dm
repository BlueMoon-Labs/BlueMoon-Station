/datum/design/board/pdapainter
	name = "Machine Design (PDA painter Board)"
	desc = "The circuit board for an PDA painter."
	id = "pdapainter"
	build_path = /obj/item/circuitboard/machine/pdapainter
	category = list ("Misc. Machinery")
	departmental_flags = DEPARTMENTAL_FLAG_SERVICE

/datum/design/board/aug_manipulator
	name = "Machine Design (Augment manipulator Board)"
	desc = "The circuit board for a augment manipulator."
	id = "aug_manipulator"
	build_path = /obj/item/circuitboard/machine/aug_manipulator
	category = list ("Misc. Machinery")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

// Дизайн для фабрикатора платы генератора жидкостей
/datum/design/board/robo_liquid_generator
	name = "Machine Design (RoboLiquid Generator)"
	desc = "Allows for the construction of circuit boards used to build a RoboLiquid Generator."
	id = "roboliq"
	build_path = /obj/item/circuitboard/machine/robo_liquid_generator
	category = list("Production Machinery")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

// Дизайн верстака для патрон
/datum/design/board/ammo_workbench
	name = "Machine Design (Ammunitions Workbench)"
	desc = "A machine, somewhat akin to a lathe, made specifically for manufacturing ammunition. It has a slot for ammunition containers, like magazines or stripper clips."
	id = "ammo_workbench"
	build_path = /obj/item/circuitboard/machine/ammo_workbench
	category = list("Misc. Machinery")
	departmental_flags = DEPARTMENTAL_FLAG_SECURITY


// Дизайны Авангарда
/datum/design/board/contrabandpadterminal
	name = "Computer Design (Contraband exchange terminal)"
	desc = "A console for exchanging contraband for bounty points."
	id = "contrabandpadterminal"
	build_path = /obj/item/circuitboard/computer/contrabandpad
	category = list("Misc. Machinery")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

/datum/design/board/contrabandpad
	name = "Machine Design (Contraband exchange pad)"
	desc = "A machine designed to send contraband to CentCom for processing."
	id = "contrabandpad"
	build_path = /obj/item/circuitboard/machine/contrabandpad
	category = list("Misc. Machinery")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE


/datum/design/board/boyntyvend
	name = "Machine Design (Bounty Vend)"
	desc = "A secure terminal for requisitioning specialized contraband equipment using bounty points."
	id = "bountyvend"
	build_path = /obj/item/circuitboard/machine/bountyvend
	category = list("Misc. Machinery")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE
