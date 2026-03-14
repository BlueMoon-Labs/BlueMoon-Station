//BIOAEGIS MODULE
/datum/design/board/bioaegis
	name = "Machine Design (BioAegis)"
	desc = "Allows for the construction of circuit boards for experimental printing technology."
	id = "bioaegisboard"
	build_path = /obj/item/circuitboard/machine/protolathe/bioaegis
	category = list("Production Machinery")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE | DEPARTMENTAL_FLAG_MEDICAL

/datum/design/bioaegis
	build_type = BIOAEGIS
	construction_time = 150

//Xenomorphic organs in bio-organic printer. Cheaper since this machine is *designed* to work with flesh specifically.
/datum/design/bioaegis/xeno
	reagents_list = list(/datum/reagent/consumable/organicprecursor/xenochimeric = 100)
	materials = list (/datum/material/plasma = 5000)
	category = list("Xenochimeric Designs")
	min_security_level = SEC_LEVEL_RED

/datum/design/bioaegis/xeno/plasmavessel
	name = "Plasma Vessel"
	id = "plasmavessel_alt"
	desc = "A design for xenochimeric plasma vessel."
	build_path = /obj/item/organ/alien/plasmavessel/large/queen

/datum/design/bioaegis/xeno/resinspinner
	name = "Resin Spinner"
	id = "resinspinner_alt"
	desc = "A design for xenochimeric resin spinner."
	build_path = /obj/item/organ/alien/resinspinner

/datum/design/bioaegis/xeno/acidgland
	name = "Acid Gland"
	id = "acidgland_alt"
	desc = "A design for xenochimeric acid gland."
	build_path = /obj/item/organ/alien/acid

/datum/design/bioaegis/xeno/neurotoxingland
	name = "Neurotoxin Gland"
	id = "neurotoxin_alt"
	desc = "A design for xenochimeric neurotoxin gland."
	build_path = /obj/item/organ/alien/neurotoxin
	reagents_list = list(/datum/reagent/consumable/organicprecursor/xenochimeric = 125)

/datum/design/bioaegis/xeno/eggsac
	name = "Egg Sac"
	id = "eggsac_alt"
	desc = "A design for xenochimeric egg sac."
	build_path = /obj/item/organ/alien/eggsac

/datum/design/bioaegis/xeno/hivenode
	name = "Hive node"
	id = "hivenode_alt"
	desc = "A design for xenochimeric hive node."
	build_path = /obj/item/organ/alien/hivenode

/datum/design/bioaegis/xeno/alientongue
	name = "Alien Tongue"
	id = "alientongue_alt"
	desc = "A design for xenochimeric alien tongue."
	build_path = /obj/item/organ/tongue/alien

//THEY ARE SORTED WITHIN NODES, OTHERWISE I SHIT HARD//
/datum/design/bioaegis/organs
	reagents_list = list(/datum/reagent/consumable/organicprecursor/bionanites = 200)
	materials = list (/datum/material/plasma = 30000)

//TIER1
/datum/design/bioaegis/organs/t1
	category = list("Baseline Designs")

/datum/design/bioaegis/organs/t1/heart
	name = "improved heart"
	id = "hearttier1"
	desc = "A design for biological organ." //Nobody *even* looks at it, and i will take a shortcut.
	build_path = /obj/item/organ/heart/bioaegis/t1

/datum/design/bioaegis/organs/t1/liver
	name = "improved liver"
	id = "livertier1"
	desc = "A design for biological organ."
	build_path = /obj/item/organ/liver/bioaegis/t1

/datum/design/bioaegis/organs/t1/lungs
	name = "improved lungs"
	id = "lungstier1"
	desc = "A design for biological organ."
	build_path = /obj/item/organ/lungs/bioaegis/t1

//TIER2
/datum/design/bioaegis/organs/t2
	category = list("Advanced Designs")

/datum/design/bioaegis/organs/t2/heart
	name = "changed heart"
	id = "hearttier2"
	desc = "A design for biological organ."
	build_path = /obj/item/organ/heart/bioaegis/t2

/datum/design/bioaegis/organs/t2/liver
	name = "changed liver"
	id = "livertier2"
	desc = "A design for biological organ."
	build_path = /obj/item/organ/liver/bioaegis/t2

/datum/design/bioaegis/organs/t2/lungs
	name = "changed lungs"
	id = "lungstier2"
	desc = "A design for biological organ."
	build_path = /obj/item/organ/lungs/bioaegis/t2

//TIER3
/datum/design/bioaegis/organs/t3
	reagents_list = list(/datum/reagent/consumable/organicprecursor/advbionanites = 150)
	category = list("Experimental Designs")
	min_security_level = SEC_LEVEL_AMBER

/datum/design/bioaegis/organs/t3/heart
	name = "exalted heart"
	id = "hearttier3"
	desc = "A design for biological organ."
	build_path = /obj/item/organ/heart/bioaegis/t3

/datum/design/bioaegis/organs/t3/liver
	name = "exalted liver"
	id = "livertier3"
	desc = "A design for biological organ."
	build_path = /obj/item/organ/liver/bioaegis/t3

/datum/design/bioaegis/organs/t3/lungs
	name = "exalted lungs"
	id = "lungstier3"
	desc = "A design for biological organ."
	build_path = /obj/item/organ/lungs/bioaegis/t3

//SPECIALIZED
/datum/design/bioaegis/organs/misc
	reagents_list = list(/datum/reagent/consumable/organicprecursor/advbionanites = 50)
	materials = list (/datum/material/plasma = 15000)
	category = list("Species-specific Designs")

/datum/design/bioaegis/organs/misc/darkveil
	name = "Darkveil ossmodula"
	id = "darkveilorgan"
	desc = "A design for biological organ."
	build_path = /obj/item/organ/darkveil

/datum/design/bioaegis/organs/misc/optisia
	name = "Optisia ossmodula"
	id = "optisiaorgan"
	desc = "A design for biological organ."
	build_path = /obj/item/organ/optisia

/datum/design/bioaegis/organs/misc/vocalbabylon
	name = "Babylon's Vocal Cords"
	id = "babyloncords"
	desc = "A design for biological organ."
	build_path = /obj/item/organ/vocal_cords/babyloncords


/datum/design/bioaegis/organs/misc/highcost
	reagents_list = list(/datum/reagent/consumable/organicprecursor/advbionanites = 150)

/datum/design/bioaegis/organs/misc/highcost/adaptiveeyes
	name = "Adaptive eyes"
	id = "adaptiveeyes"
	desc = "A design for biological organ."
	build_path = /obj/item/organ/eyes/night_vision/aegis

/datum/design/bioaegis/organs/misc/highcost/thermalaegiseyes
	name = "Thermographic eyes"
	id = "thermalaegiseyes"
	desc = "A design for biological organ."
	build_path = /obj/item/organ/eyes/thermalaegis
	min_security_level = SEC_LEVEL_RED

// Dangerous for user
/datum/design/bioaegis/organs/misc/dangerous
	reagents_list = list(/datum/reagent/consumable/organicprecursor/advbionanites = 150)
	category = list("Dangerous Designs")
	min_security_level = SEC_LEVEL_RED

/datum/design/bioaegis/organs/misc/dangerous/bodyoverload
	name = "Optimia ossmodula"
	id = "bodyoverload"
	desc = "A design for biological organ."
	build_path = /obj/item/organ/bodyoverload

/datum/design/bioaegis/organs/misc/dangerous/neuralderanger
	name = "Nemedia ossmodula"
	id = "neuralderanger"
	desc = "A design for biological organ."
	build_path = /obj/item/organ/neuralderanger

