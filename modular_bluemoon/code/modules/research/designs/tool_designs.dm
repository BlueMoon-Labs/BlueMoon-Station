/////////////////////////////////////////////
//////////////Advanced Tools////////////////
///////////////////////////////////////////

/datum/design/advancedwrench
	name = "Advanced Wrench"
	desc = "An advanced wrench obtained through Abductor technology."
	id = "alien_wrench"
	build_path = /obj/item/wrench/advanced
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 10000, /datum/material/silver = 7500, /datum/material/plasma = 1000, /datum/material/titanium = 8000, /datum/material/diamond = 2000)
	category = list("Tool Designs")
	departmental_flags = DEPARTMENTAL_FLAG_ENGINEERING | DEPARTMENTAL_FLAG_SCIENCE

/datum/design/advancedwirecutters
	name = "Advanced Wirecutters"
	desc = "Advanced wirecutters obtained through Abductor technology."
	id = "alien_wirecutters"
	build_path = /obj/item/wirecutters/advanced
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 5000, /datum/material/silver = 5000, /datum/material/plasma = 7500, /datum/material/titanium = 13000, /datum/material/diamond = 2000)
	category = list("Tool Designs")
	departmental_flags = DEPARTMENTAL_FLAG_ENGINEERING | DEPARTMENTAL_FLAG_SCIENCE

/datum/design/advancedscrewdriver
	name = "Advanced Screwdriver"
	desc = "An advanced screwdriver obtained through Abductor technology."
	id = "alien_screwdriver"
	build_path = /obj/item/screwdriver/advanced
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 5000, /datum/material/silver = 5000, /datum/material/plasma = 1000, /datum/material/titanium = 8000, /datum/material/diamond = 10000)
	category = list("Tool Designs")
	departmental_flags = DEPARTMENTAL_FLAG_ENGINEERING | DEPARTMENTAL_FLAG_SCIENCE

/datum/design/advancedcrowbar
	name = "Advanced Crowbar"
	desc = "An advanced crowbar obtained through Abductor technology."
	id = "alien_crowbar"
	build_path = /obj/item/crowbar/advanced
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 15000, /datum/material/silver = 4000, /datum/material/plasma = 1000, /datum/material/titanium = 8000, /datum/material/diamond = 1300)
	category = list("Tool Designs")
	departmental_flags = DEPARTMENTAL_FLAG_ENGINEERING | DEPARTMENTAL_FLAG_SCIENCE

/datum/design/advancedwelder
	name = "Advanced Welding Tool"
	desc = "An advanced welding tool obtained through Abductor technology."
	id = "alien_welder"
	build_path = /obj/item/weldingtool/advanced
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 8000, /datum/material/silver = 5250, /datum/material/plasma = 12000, /datum/material/titanium = 8000, /datum/material/diamond = 2500)
	category = list("Tool Designs")
	departmental_flags = DEPARTMENTAL_FLAG_ENGINEERING | DEPARTMENTAL_FLAG_SCIENCE

/datum/design/advancedmultitool
	name = "Advanced Multitool"
	desc = "An advanced multitool obtained through Abductor technology."
	id = "alien_multitool"
	build_path = /obj/item/multitool/advanced
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 5000, /datum/material/gold = 10000, /datum/material/plasma = 5000, /datum/material/titanium = 8000, /datum/material/diamond = 5000)
	category = list("Tool Designs")
	departmental_flags = DEPARTMENTAL_FLAG_ENGINEERING

///////////////////////////
//T2 хирург. инструменты//
/////////////////////////

/datum/design/scalpel_upgraded
	name = "Vibration Scalpel"
	desc = "Вибрационный скальпель с улучшенными показателями остроты."
	id = "scalpel_upgraded"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 1500, /datum/material/glass = 1000, /datum/material/silver = 750, /datum/material/titanium = 750)
	build_path = /obj/item/scalpel/upgraded_t2
	category = list("Tool Designs")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL | DEPARTMENTAL_FLAG_SCIENCE

/datum/design/circularsaw_upgraded
	name = "Oscillating Surgical Saw"
	desc = "Вибрационная пила, абсолютно безопасная для пациента."
	id = "circularsaw_upgraded"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 2500, /datum/material/glass = 1500, /datum/material/titanium = 1000)
	build_path = /obj/item/circular_saw/upgraded_t2
	category = list("Tool Designs")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL | DEPARTMENTAL_FLAG_SCIENCE

/datum/design/retractor_upgraded
	name = "Titanium Retractor"
	desc = "Особо крепкие зажимы с пружиной из титана. Надёжность на новом уровне."
	id = "retractor_upgraded"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 1500, /datum/material/glass = 500, /datum/material/titanium = 750)
	build_path = /obj/item/retractor/upgraded_t2
	category = list("Tool Designs")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL | DEPARTMENTAL_FLAG_SCIENCE

/datum/design/hemostat_upgraded
	name = "Silvered Hemostat"
	desc = "Сделанный из серебра - абсолютно стерильные условия! "
	id = "hemostat_upgraded"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 1500, /datum/material/glass = 500, /datum/material/silver = 750)
	build_path = /obj/item/hemostat/upgraded_t2
	category = list("Tool Designs")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL | DEPARTMENTAL_FLAG_SCIENCE

/datum/design/cautery_upgraded
	name = "High Heat Cautery"
	desc = "Прижигатель с плазменным питанием: осторожно, особенно горячо."
	id = "cautery_upgraded"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 1500, /datum/material/glass = 500, /datum/material/plasma = 1000)
	build_path = /obj/item/cautery/upgraded_t2
	category = list("Tool Designs")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL | DEPARTMENTAL_FLAG_SCIENCE
