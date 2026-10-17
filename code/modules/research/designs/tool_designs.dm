/////////////////////////////////////////
/////////////////Tools///////////////////
/////////////////////////////////////////

/datum/design/rcd_upgrade/frames
	name = "RCD frames designs upgrade"
	desc = "Adds the computer frame and machine frame to the RCD."
	id = "rcd_upgrade_frames"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 5000, /datum/material/glass = 2500, /datum/material/silver = 1500, /datum/material/titanium = 2000)
	build_path = /obj/item/rcd_upgrade/frames
	category = list("Tool Designs")
	departmental_flags = DEPARTMENTAL_FLAG_ENGINEERING

/datum/design/rcd_upgrade/simple_circuits
	name = "RCD simple circuits designs upgrade"
	desc = "Adds the simple circuits to the RCD."
	id = "rcd_upgrade_simple_circuits"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 5000, /datum/material/glass = 2500, /datum/material/silver = 1500, /datum/material/titanium = 2000)
	build_path = /obj/item/rcd_upgrade/simple_circuits
	category = list("Tool Designs")
	departmental_flags = DEPARTMENTAL_FLAG_ENGINEERING

/datum/design/rcd_loaded
	name = "Rapid Construction Device"
	desc = "A tool that can construct and deconstruct walls, airlocks and floors on the fly."
	id = "rcd_loaded"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 36000)  // costs more than what it did in the autolathe, this one comes loaded.
	build_path = /obj/item/construction/rcd/loaded
	category = list("Tool Designs")
	departmental_flags =  DEPARTMENTAL_FLAG_ENGINEERING

/datum/design/rpd
	name = "Rapid Pipe Dispenser"
	desc = "A tool that can construct and deconstruct pipes on the fly."
	id = "rpd"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 75000, /datum/material/glass = 37500)
	build_path = /obj/item/pipe_dispenser
	category = list("Tool Designs")
	departmental_flags =  DEPARTMENTAL_FLAG_ENGINEERING

/datum/design/shuttlecreator
	name = "Rapid Shuttle Designator"
	desc = "An advanced device capable of defining areas for use in the creation of shuttles"
	id = "shuttle_creator"
	build_path = /obj/item/shuttle_creator
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 8000, /datum/material/titanium = 5000, /datum/material/bluespace = 5000)
	category = list("Tool Designs")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE | DEPARTMENTAL_FLAG_ENGINEERING

/datum/design/handdrill
	name = "Hand Drill"
	desc = "A small electric hand drill with an interchangeable screwdriver and bolt bit"
	id = "handdrill"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 3500, /datum/material/silver = 1500, /datum/material/titanium = 2500)
	build_path = /obj/item/screwdriver/power
	category = list("Tool Designs")
	departmental_flags = DEPARTMENTAL_FLAG_ENGINEERING

/datum/design/jawsoflife
	name = "Jaws of Life"
	desc = "A small, compact Jaws of Life with an interchangeable pry jaws and cutting jaws"
	id = "jawsoflife" // added one more requirment since the Jaws of Life are a bit OP
	build_path = /obj/item/crowbar/power
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 4500, /datum/material/silver = 2500, /datum/material/titanium = 3500)
	category = list("Tool Designs")
	departmental_flags = DEPARTMENTAL_FLAG_ENGINEERING

/datum/design/bolter_wrench
	name = "Bolter Wrench"
	desc = "A wrench that can unbolt airlocks regardless of power status."
	id = "bolter_wrench"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 5000)
	build_path = /obj/item/wrench/bolter
	category = list("Tool Designs")
	departmental_flags = DEPARTMENTAL_FLAG_ENGINEERING

//BLUEMOON ADD START - переношу с ТГ Т2 инструменты для учёных
/datum/design/handdrillsci
	name = "Science Hand Drill"
	desc = "This one sports a nifty science paintjob, but is otherwise normal."
	id = "handdrillsci"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 2000, /datum/material/silver = 1000, /datum/material/titanium = 1500)
	build_path = /obj/item/screwdriver/power/science
	category = list("Tool Designs")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

/datum/design/jawsoflifesci
	name = "Hybrid cutters"
	desc = "Quite similar to the jaws of life, this tool combines the utility of a crowbar and a set of wirecutters without the hydraulic force required to pry open doors."
	id = "jawsoflifesci"
	build_path = /obj/item/crowbar/power/science
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 3000, /datum/material/silver = 2000, /datum/material/titanium = 1500)
	category = list("Tool Designs")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE


/datum/design/exwelder
	name = "Experimental Welding Tool"
	desc = "An experimental welder capable of self-fuel generation."
	id = "exwelder"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 1000, /datum/material/glass = 500, /datum/material/plasma = 1500, /datum/material/uranium = 200)
	build_path = /obj/item/weldingtool/experimental
	category = list("Tool Designs")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE | DEPARTMENTAL_FLAG_ENGINEERING

/datum/design/tricorder
	name = "Tricorder"
	desc = "Многофункциональное устройство, которое может выполнять огромный спектр задач."
	id = "tricorder"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 500, /datum/material/silver = 300, /datum/material/gold = 300)
	build_path = /obj/item/multitool/tricorder
	category = list("Tool Designs")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE | DEPARTMENTAL_FLAG_ENGINEERING

/datum/design/rld_mini
	name = "Mini Rapid Light Device (MRLD)"
	desc = "A tool that can portable and standing lighting orbs and glowsticks."
	id = "rld_mini"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 20000, /datum/material/glass = 10000, /datum/material/plastic = 8000, /datum/material/gold = 2000)
	build_path = /obj/item/construction/rld/mini
	category = list("Tool Designs")
	departmental_flags =  DEPARTMENTAL_FLAG_ENGINEERING | DEPARTMENTAL_FLAG_CARGO | DEPARTMENTAL_FLAG_SERVICE

/datum/design/ranged_analyzer
	name = "Long-range Analyzer"
	desc = "A new advanced atmospheric analyzer design, capable of performing scans at long range."
	id = "ranged_analyzer"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 400, /datum/material/glass = 1000, /datum/material/uranium = 800, /datum/material/gold = 200, /datum/material/diamond = 50)
	build_path = /obj/item/analyzer/ranged
	category = list("Tool Designs")
	departmental_flags =  DEPARTMENTAL_FLAG_SCIENCE | DEPARTMENTAL_FLAG_ENGINEERING

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

///////////////////////////////////////////////////
//////////////Alien advanced Tools////////////////
/////////////////////////////////////////////////

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

/datum/design/alienrcd
	name = "ARCD"
	desc = "Улучшенный РЦД работающий даже на расстоянии"
	id = "alien_rcd"
	build_path = /obj/item/construction/rcd/arcd
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 30000, /datum/material/silver = 4500, /datum/material/diamond = 6000, /datum/material/bluespace = 4000)
	category = list("Tool Designs")
	departmental_flags = DEPARTMENTAL_FLAG_ENGINEERING

/////////////////////////////////////////
/////////Alien Surgical Tools////////////
/////////////////////////////////////////

/datum/design/alienscalpel
	name = "Alien Scalpel"
	desc = "An advanced scalpel obtained through Abductor technology."
	id = "alien_scalpel"
	build_path = /obj/item/scalpel/alien
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 8000, /datum/material/silver = 5500, /datum/material/plasma = 4000, /datum/material/titanium = 8000)
	category = list("Tool Designs")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL

/datum/design/alienhemostat
	name = "Alien Hemostat"
	desc = "An advanced hemostat obtained through Abductor technology."
	id = "alien_hemostat"
	build_path = /obj/item/hemostat/alien
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 2000, /datum/material/silver = 9500, /datum/material/plasma = 6000, /datum/material/titanium = 1500, /datum/material/diamond = 1500)
	category = list("Tool Designs")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL

/datum/design/alienretractor
	name = "Alien Retractor"
	desc = "An advanced retractor obtained through Abductor technology."
	id = "alien_retractor"
	build_path = /obj/item/retractor/alien
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 3500, /datum/material/silver = 1500, /datum/material/plasma = 3000, /datum/material/titanium = 3250)
	category = list("Tool Designs")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL

/datum/design/aliensaw
	name = "Alien Circular Saw"
	desc = "An advanced surgical saw obtained through Abductor technology."
	id = "alien_saw"
	build_path = /obj/item/circular_saw/alien
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 10000, /datum/material/silver = 4000, /datum/material/plasma = 1000, /datum/material/titanium = 2500)
	category = list("Tool Designs")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL

/datum/design/aliendrill
	name = "Alien Drill"
	desc = "An advanced drill obtained through Abductor technology."
	id = "alien_drill"
	build_path = /obj/item/surgicaldrill/alien
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 8000, /datum/material/silver = 2500, /datum/material/plasma = 2000, /datum/material/titanium = 1500, /datum/material/diamond = 1500)
	category = list("Tool Designs")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL

/datum/design/aliencautery
	name = "Alien Cautery"
	desc = "An advanced cautery obtained through Abductor technology."
	id = "alien_cautery"
	build_path = /obj/item/cautery/alien
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 4000, /datum/material/silver = 1500, /datum/material/plasma = 8500, /datum/material/titanium = 4000)
	category = list("Tool Designs")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL

///////////////////////////////////////////////
/////////Alien Combi Surgical Tools////////////
///////////////////////////////////////////////

/datum/design/alien_combi_scalpel
	name = "Alien Combi Scalpel"
	desc = "An advanced combi scalpel and saw obtained through Abductor technology."
	id = "alien_combi_scalpel"
	build_path = /obj/item/scalpel/advanced/alien
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 18000, /datum/material/silver = 9500, /datum/material/plasma = 5000, /datum/material/titanium = 10500, /datum/material/diamond = 4000)
	category = list("Tool Designs")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL

/datum/design/alien_combi_retractor
	name = "Alien Combi Retractor"
	desc = "An advanced combi retractor and hemostat obtained through Abductor technology."
	id = "alien_combi_retractor"
	build_path = /obj/item/retractor/advanced/alien
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 5500, /datum/material/silver = 6000, /datum/material/plasma = 9000, /datum/material/titanium = 4750, /datum/material/diamond = 3500)
	category = list("Tool Designs")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL

/datum/design/alien_combi_drill
	name = "Alien Combi Drill"
	desc = "An advanced combi drill and cautery obtained through Abductor technology."
	id = "alien_combi_drill"
	build_path = /obj/item/surgicaldrill/advanced/alien
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 12000, /datum/material/silver = 12500, /datum/material/plasma = 7250, /datum/material/titanium = 5500, /datum/material/diamond = 2000)
	category = list("Tool Designs")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL

//////////////////////
//Adv. Surgery Tools//
//////////////////////

/datum/design/drapes
	name = "Surgical Drapes"
	desc = "A large surgery drape made of plastic."
	id = "drapes"
	build_type = PROTOLATHE | AUTOLATHE
	materials = list(/datum/material/plastic = 2500)
	build_path = /obj/item/surgical_drapes
	category = list("Initial", "Medical", "Tool Designs")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL | DEPARTMENTAL_FLAG_SCIENCE

/datum/design/drapes_adv
	name = "Smart Surgical Drapes"
	desc = "A smart set of drapes synced with the station's research network, allowing advanced surgeries without an operating computer."
	id = "drapes_adv"
	build_type = PROTOLATHE
	materials = list(/datum/material/plastic = 15000, /datum/material/silver = 2000, /datum/material/gold = 2000, /datum/material/diamond = 1000, /datum/material/bluespace = 1000)
	build_path = /obj/item/surgical_drapes/advanced
	category = list("Tool Designs")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL | DEPARTMENTAL_FLAG_SCIENCE

/datum/design/retractor_adv
	name = "Advanced Retractor"
	desc = "An almagation of rods and gears, able to function as both a surgical clamp and retractor. "
	id = "retractor_adv"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 500, /datum/material/glass = 500, /datum/material/silver = 1500, /datum/material/gold = 1000)
	build_path = /obj/item/retractor/advanced
	category = list("Tool Designs")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL

/datum/design/surgicaldrill_adv
	name = "Surgical Laser Drill"
	desc = "It projects a high power laser used for medical applications."
	id = "surgicaldrill_adv"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 2500, /datum/material/glass = 2500, /datum/material/silver = 6000, /datum/material/gold = 5500, /datum/material/diamond = 3500)
	build_path = /obj/item/surgicaldrill/advanced
	category = list("Tool Designs")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL

/datum/design/scalpel_adv
	name = "Laser Scalpel"
	desc = "An advanced scalpel which uses laser technology to cut."
	id = "scalpel_adv"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 1500, /datum/material/glass = 1500, /datum/material/silver = 4000, /datum/material/gold = 2500)
	build_path = /obj/item/scalpel/advanced
	category = list("Tool Designs")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL

/datum/design/robotic_processor
	name = "Robotic Processor"
	desc = "A device for scanning and initiating new synthetic parts to help fix problems even for unqualified personnel"
	id = "robotic_pr"
	build_type = PROTOLATHE
	build_path = /obj/item/robotic_processor
	materials = list(/datum/material/iron = 4500, /datum/material/glass = 4500, /datum/material/silver = 4500, /datum/material/gold = 2500, /datum/material/diamond = 1500)
	category = list("Tool Designs")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

// BLUEMOON Перенёс РПЕДы из parts в tools.
/datum/design/RPED
	name = "Rapid Part Exchange Device"
	desc = "\"Модуль механический специальный\" для хранения, сортировки и применения стандартизированных деталей."
	id = "rped"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 10000, /datum/material/glass = 5000) //hardcore
	build_path = /obj/item/storage/part_replacer
	category = list("Tool Designs")
	departmental_flags = DEPARTMENTAL_FLAG_ENGINEERING | DEPARTMENTAL_FLAG_SCIENCE

/datum/design/BS_RPED
	name = "Bluespace RPED"
	desc = "Усиленный блюспейс-технологиями, этот RPED может улучшать машинерию дистанционно, без необходимости отвинчивать её панель."
	id = "bs_rped"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 15000, /datum/material/glass = 5000, /datum/material/silver = 2500) //hardcore
	build_path = /obj/item/storage/part_replacer/bluespace
	category = list("Tool Designs")
	departmental_flags = DEPARTMENTAL_FLAG_ENGINEERING | DEPARTMENTAL_FLAG_SCIENCE

/datum/design/m_warp_beacon
	name = "Machine warp beacon"
	desc = "Устройство позволяющее телепортировать уже собранную машину, по сигнатуре платы, что в нее установили. Не подходит для машин, требующих сложных в производстве деталей."
	id = "m_warp_beacon"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = MINERAL_MATERIAL_AMOUNT*6, /datum/material/glass = MINERAL_MATERIAL_AMOUNT*5)
	build_path = /obj/item/warp_machine_beacon
	category = list("Equipment")
	departmental_flags = DEPARTMENTAL_FLAG_ALL
