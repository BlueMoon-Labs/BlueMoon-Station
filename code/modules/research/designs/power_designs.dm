////////////////////////////////////////
//////////////////Power/////////////////
////////////////////////////////////////

/datum/design/basic_cell
	name = "Basic Power Cell"
	desc = "A basic power cell that holds 1 MJ of energy."
	id = "basic_cell"
	build_type = PROTOLATHE | AUTOLATHE |MECHFAB
	materials = list(/datum/material/iron = 700, /datum/material/glass = 50)
	construction_time=100
	build_path = /obj/item/stock_parts/cell/empty
	category = list("Misc","Stock Parts","Machinery","initial")
	departmental_flags = DEPARTMENTAL_FLAG_ALL

/datum/design/high_cell
	name = "High-Capacity Power Cell"
	desc = "A power cell that holds 10 MJ of energy."
	id = "high_cell"
	build_type = PROTOLATHE | AUTOLATHE | MECHFAB
	materials = list(/datum/material/iron = 700, /datum/material/glass = 60)
	construction_time=100
	build_path = /obj/item/stock_parts/cell/high/empty
	category = list("Misc","Stock Parts")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE | DEPARTMENTAL_FLAG_ENGINEERING | DEPARTMENTAL_FLAG_MEDICAL | DEPARTMENTAL_FLAG_SECURITY

/datum/design/super_cell
	name = "Super-Capacity Power Cell"
	desc = "A power cell that holds 20 MJ of energy."
	id = "super_cell"
	build_type = PROTOLATHE | MECHFAB
	materials = list(/datum/material/iron = 700, /datum/material/glass = 70)
	construction_time=100
	build_path = /obj/item/stock_parts/cell/super/empty
	category = list("Misc","Stock Parts")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE | DEPARTMENTAL_FLAG_ENGINEERING | DEPARTMENTAL_FLAG_MEDICAL | DEPARTMENTAL_FLAG_SECURITY

/datum/design/hyper_cell
	name = "Hyper-Capacity Power Cell"
	desc = "A power cell that holds 30 MJ of energy."
	id = "hyper_cell"
	build_type = PROTOLATHE | MECHFAB
	materials = list(/datum/material/iron = 700, /datum/material/gold = 150, /datum/material/silver = 150, /datum/material/glass = 80)
	construction_time=100
	build_path = /obj/item/stock_parts/cell/hyper/empty
	category = list("Misc","Stock Parts")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE | DEPARTMENTAL_FLAG_ENGINEERING | DEPARTMENTAL_FLAG_MEDICAL | DEPARTMENTAL_FLAG_SECURITY

/datum/design/bluespace_cell
	name = "Bluespace Power Cell"
	desc = "A power cell that holds 40 MJ of energy."
	id = "bluespace_cell"
	build_type = PROTOLATHE | MECHFAB
	materials = list(/datum/material/iron = 800, /datum/material/gold = 120, /datum/material/glass = 160, /datum/material/diamond = 160, /datum/material/titanium = 300, /datum/material/bluespace = 100)
	construction_time=100
	build_path = /obj/item/stock_parts/cell/bluespace/empty
	category = list("Misc","Stock Parts")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE | DEPARTMENTAL_FLAG_ENGINEERING | DEPARTMENTAL_FLAG_MEDICAL | DEPARTMENTAL_FLAG_SECURITY

/datum/design/bluespace_cell_reactor
	name = "Bluespace Reactor P. Cell (DANGER: Radioactive)"
	desc = "A power cell that holds 10 MJ of energy."
	id = "bluespace_cell_reactor"
	build_type = PROTOLATHE // BLUEMOON CHANGE требует реагент, потому кроме как в протолате не скрафтить
	materials = list(/datum/material/iron = 1200, /datum/material/gold = 260, /datum/material/glass = 360, /datum/material/diamond = 560, /datum/material/titanium = 600, /datum/material/bluespace = 1200, /datum/material/uranium = 2600)
	reagents_list = list(/datum/reagent/bluespace = 10) // BLUEMOON ADD балансное
	construction_time=100
	build_path = /obj/item/stock_parts/cell/bluespacereactor
	category = list("Misc","Stock Parts")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE | DEPARTMENTAL_FLAG_ENGINEERING | DEPARTMENTAL_FLAG_MEDICAL | DEPARTMENTAL_FLAG_SECURITY

/datum/design/vortex_cell
	name = "Vortex Power Cell"
	desc = "A power cell that holds 60 MJ of energy and slowly recharge itself."
	id = "vortex_cell"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 800, /datum/material/gold = 120, /datum/material/glass = 160, /datum/material/diamond = 160, /datum/material/titanium = 300, /datum/material/bluespace = 300)
	construction_time=180
	build_path = /obj/item/stock_parts/cell/vortex/empty
	reagents_list = list(/datum/reagent/liquid_dark_matter = 5, /datum/reagent/bluespace = 5, /datum/reagent/teslium/energized_jelly = 10)
	category = list("Stock Parts")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE | DEPARTMENTAL_FLAG_ENGINEERING | DEPARTMENTAL_FLAG_MEDICAL | DEPARTMENTAL_FLAG_SECURITY

/datum/design/inducer
	name = "Engineer Inducer"
	desc = "The NT-75 Electromagnetic Power Inducer can wirelessly induce electric charge in an object, allowing you to recharge power cells without having to remove them."
	id = "inducer"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 6000, /datum/material/glass = 3000)
	build_path = /obj/item/inducer/dry
	category = list("Tool Designs")
	departmental_flags = DEPARTMENTAL_FLAG_ENGINEERING

/datum/design/inducer/sci
	name = "Science Inducer"
	desc = "The NT-75 Electromagnetic Power Inducer can wirelessly induce electric charge in an object, allowing you to recharge power cells without having to remove them."
	id = "inducer_sci"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 3000, /datum/material/glass = 1000)
	build_path = /obj/item/inducer/sci
	category = list("Tool Designs")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

/datum/design/inducer/syndie
	name = "Syndie Inducer"
	desc = "The Gorlex-7051 Electromagnetic Power Inducer can wirelessly induce electric charge in an object, allowing you to recharge power cells without having to remove them more faster than standart NT Inducers."
	id = "inducer_syn"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 10000, /datum/material/glass = 8000, /datum/material/silver = 1500)
	build_path = /obj/item/inducer/syndicate/dry
	category = list("Tool Designs")
	departmental_flags = DEPARTMENTAL_FLAG_ENGINEERING

/datum/design/inducercombat
	name = "Combat Ready Inducer"
	desc = "The improved NT-8475 Electromagnetic Power Inducer can this one has been SCIENCED to allow for combat. It still comes printed with SCIENCED colors!"
	id = "combatinducer"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 13000, /datum/material/glass = 10000,  /datum/material/silver = 1500,  /datum/material/gold = 1250, /datum/material/diamond = 500, /datum/material/titanium = 1200)
	build_path = /obj/item/inducer/sci/combat/dry
	category = list("Tool Designs")
	departmental_flags = DEPARTMENTAL_FLAG_SECURITY
	min_security_level = SEC_LEVEL_RED

/datum/design/board/pacman
	name = "Machine Design (PACMAN-type Generator Board)"
	desc = "The circuit board that for a PACMAN-type portable generator."
	id = "pacman"
	build_path = /obj/item/circuitboard/machine/pacman
	category = list("Engineering Machinery")
	departmental_flags = DEPARTMENTAL_FLAG_ENGINEERING

/datum/design/board/pacman/super
	name = "Machine Design (SUPERPACMAN-type Generator Board)"
	desc = "The circuit board that for a SUPERPACMAN-type portable generator."
	id = "superpacman"
	build_path = /obj/item/circuitboard/machine/pacman/super

/datum/design/board/pacman/mrs
	name = "Machine Design (MRSPACMAN-type Generator Board)"
	desc = "The circuit board that for a MRSPACMAN-type portable generator."
	id = "mrspacman"
	build_path = /obj/item/circuitboard/machine/pacman/mrs
