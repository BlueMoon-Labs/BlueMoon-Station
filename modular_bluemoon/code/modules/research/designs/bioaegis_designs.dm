//BIOAEGIS MODULE
/datum/design/board/bioaegis
	name = "Machine Design (BioAegis)"
	desc = "Allows for the construction of circuit boards for experimental printing technology."
	id = "bioaegisboard"
	build_path = /obj/item/circuitboard/machine/protolathe/bioaegis
	category = list("Research Machinery")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE | DEPARTMENTAL_FLAG_MEDICAL

//Xenomorphic organs in bio-organic printer. Cheaper since this machine is *designed* to work with flesh specifically.
/datum/design/plasmavessel_alt
	name = "Plasma Vessel"
	id = "plasmavessel_alt" //It is fine, since you can't access them anyway on usual protolathe.
	desc = "A design for xenochimeric plasma vessel."
	build_type = BIOAEGIS
	construction_time = 150
	reagents_list = list(/datum/reagent/consumable/organicprecursor/xenochimeric = 100)
	build_path = /obj/item/organ/alien/plasmavessel/large/queen
	category = list("Xenochimeric Designs")
	materials = list (/datum/material/plasma = 5000)
	min_security_level = SEC_LEVEL_RED

/datum/design/resinspinner_alt
	name = "Resin Spinner"
	id = "resinspinner_alt"
	desc = "A design for xenochimeric resin spinner."
	build_type = BIOAEGIS
	construction_time = 150
	reagents_list = list(/datum/reagent/consumable/organicprecursor/xenochimeric = 100)
	build_path = /obj/item/organ/alien/resinspinner
	category = list("Xenochimeric Designs")
	materials = list (/datum/material/plasma = 5000)
	min_security_level = SEC_LEVEL_RED

/datum/design/acidgland_alt
	name = "Acid Gland"
	id = "acidgland_alt"
	desc = "A design for xenochimeric acid gland."
	build_type = BIOAEGIS
	construction_time = 150
	reagents_list = list(/datum/reagent/consumable/organicprecursor/xenochimeric = 100)
	build_path = /obj/item/organ/alien/acid
	category = list("Xenochimeric Designs")
	materials = list (/datum/material/plasma = 5000)
	min_security_level = SEC_LEVEL_RED

/datum/design/neurotoxingland_alt
	name = "Neurotoxin Gland"
	id = "neurotoxin_alt"
	desc = "A design for xenochimeric neurotoxin gland."
	build_type = BIOAEGIS
	construction_time = 150
	reagents_list = list(/datum/reagent/consumable/organicprecursor/xenochimeric = 125)
	build_path = /obj/item/organ/alien/neurotoxin
	category = list("Xenochimeric Designs")
	materials = list (/datum/material/plasma = 5000)
	min_security_level = SEC_LEVEL_RED

/datum/design/eggsac_alt
	name = "Egg Sac"
	id = "eggsac_alt"
	desc = "A design for xenochimeric egg sac."
	build_type = BIOAEGIS
	construction_time = 150
	reagents_list = list(/datum/reagent/consumable/organicprecursor/xenochimeric = 100)
	build_path = /obj/item/organ/alien/eggsac
	category = list("Xenochimeric Designs")
	materials = list (/datum/material/plasma = 5000)
	min_security_level = SEC_LEVEL_RED

/datum/design/hivenode_alt
	name = "Hive node"
	id = "hivenode_alt"
	desc = "A design for xenochimeric hive node."
	build_type = BIOAEGIS
	construction_time = 150
	reagents_list = list(/datum/reagent/consumable/organicprecursor/xenochimeric = 100)
	build_path = /obj/item/organ/alien/hivenode
	category = list("Xenochimeric Designs")
	materials = list (/datum/material/plasma = 5000)
	min_security_level = SEC_LEVEL_RED

/datum/design/alientongue_alt
	name = "Alien Tongue"
	id = "alientongue_alt"
	desc = "A design for xenochimeric alien tongue."
	build_type = BIOAEGIS
	construction_time = 150
	reagents_list = list(/datum/reagent/consumable/organicprecursor/xenochimeric = 100)
	build_path = /obj/item/organ/tongue/alien
	category = list("Xenochimeric Designs")
	materials = list (/datum/material/plasma = 5000)
	min_security_level = SEC_LEVEL_RED

//THEY ARE SORTED WITHIN NODES, OTHERWISE I SHIT HARD//
//TIER1
/datum/design/hearttier1
	name = "improved heart"
	id = "hearttier1"
	desc = "A design for biological organ." //Nobody *even* looks at it, and i will take a shortcut.
	build_type = BIOAEGIS
	construction_time = 150
	reagents_list = list(/datum/reagent/consumable/organicprecursor/bionanites = 200)
	build_path = /obj/item/organ/heart/tier1
	category = list("Baseline Designs")
	materials = list (/datum/material/plasma = 30000)

/datum/design/livertier1
	name = "improved liver"
	id = "livertier1"
	desc = "A design for biological organ."
	build_type = BIOAEGIS
	construction_time = 150
	reagents_list = list(/datum/reagent/consumable/organicprecursor/bionanites = 200)
	build_path = /obj/item/organ/liver/tier1
	category = list("Baseline Designs")
	materials = list (/datum/material/plasma = 30000)

/datum/design/lungstier1
	name = "improved lungs"
	id = "lungstier1"
	desc = "A design for biological organ."
	build_type = BIOAEGIS
	construction_time = 150
	reagents_list = list(/datum/reagent/consumable/organicprecursor/bionanites = 200)
	build_path = /obj/item/organ/lungs/tier1
	category = list("Baseline Designs")
	materials = list (/datum/material/plasma = 30000)

//TIER2
/datum/design/hearttier2
	name = "changed heart"
	id = "hearttier2"
	desc = "A design for biological organ."
	build_type = BIOAEGIS
	construction_time = 150
	reagents_list = list(/datum/reagent/consumable/organicprecursor/bionanites = 200)
	build_path = /obj/item/organ/heart/tier2
	category = list("Advanced Designs")
	materials = list (/datum/material/plasma = 30000)
	min_security_level = SEC_LEVEL_BLUE

/datum/design/lungstier2
	name = "changed lungs"
	id = "lungstier2"
	desc = "A design for biological organ."
	build_type = BIOAEGIS
	construction_time = 150
	reagents_list = list(/datum/reagent/consumable/organicprecursor/bionanites = 200)
	build_path = /obj/item/organ/lungs/tier2
	category = list("Advanced Designs")
	materials = list (/datum/material/plasma = 30000)
	min_security_level = SEC_LEVEL_BLUE

/datum/design/livertier2
	name = "changed liver"
	id = "livertier2"
	desc = "A design for biological organ."
	build_type = BIOAEGIS
	construction_time = 150
	reagents_list = list(/datum/reagent/consumable/organicprecursor/bionanites = 200)
	build_path = /obj/item/organ/liver/tier2
	category = list("Advanced Designs")
	materials = list (/datum/material/plasma = 30000)
	min_security_level = SEC_LEVEL_BLUE

//TIER3
/datum/design/livertier3
	name = "exalted liver"
	id = "livertier3"
	desc = "A design for biological organ."
	build_type = BIOAEGIS
	construction_time = 150
	reagents_list = list(/datum/reagent/consumable/organicprecursor/advbionanites = 150)
	build_path = /obj/item/organ/liver/tier3
	category = list("Experimental Designs")
	materials = list (/datum/material/plasma = 30000)
	min_security_level = SEC_LEVEL_AMBER

/datum/design/lungstier3
	name = "exalted lungs"
	id = "lungstier3"
	desc = "A design for biological organ."
	build_type = BIOAEGIS
	construction_time = 150
	reagents_list = list(/datum/reagent/consumable/organicprecursor/advbionanites = 150)
	build_path = /obj/item/organ/lungs/tier3
	category = list("Experimental Designs")
	materials = list (/datum/material/plasma = 30000)
	min_security_level = SEC_LEVEL_AMBER

/datum/design/hearttier3
	name = "exalted heart"
	id = "hearttier3"
	desc = "A design for biological organ."
	build_type = BIOAEGIS
	construction_time = 150
	reagents_list = list(/datum/reagent/consumable/organicprecursor/advbionanites = 150)
	build_path = /obj/item/organ/heart/tier3
	category = list("Experimental Designs")
	materials = list (/datum/material/plasma = 30000)
	min_security_level = SEC_LEVEL_AMBER

//SPECIALIZED
/datum/design/darkveilorgan
	name = "Darkveil ossmodula"
	id = "darkveilorgan"
	desc = "A design for biological organ."
	build_type = BIOAEGIS
	construction_time = 150
	reagents_list = list(/datum/reagent/consumable/organicprecursor/advbionanites = 50)
	build_path = /obj/item/organ/darkveil
	category = list("Species-specific Designs")
	materials = list (/datum/material/plasma = 15000)

/datum/design/optisiaorgan
	name = "Optisia ossmodula"
	id = "optisiaorgan"
	desc = "A design for biological organ."
	build_type = BIOAEGIS
	construction_time = 150
	reagents_list = list(/datum/reagent/consumable/organicprecursor/advbionanites = 50)
	build_path = /obj/item/organ/optisia
	category = list("Species-specific Designs")
	materials = list (/datum/material/plasma = 15000)

/datum/design/adaptiveeyes
	name = "Adaptive eyes"
	id = "adaptiveeyes"
	desc = "A design for biological organ."
	build_type = BIOAEGIS
	construction_time = 150
	reagents_list = list(/datum/reagent/consumable/organicprecursor/bionanites = 150)
	build_path = /obj/item/organ/eyes/night_vision/aegis
	category = list("Species-specific Designs")
	materials = list (/datum/material/plasma = 15000)

/datum/design/thermalaegiseyes
	name = "Thermographic eyes"
	id = "thermalaegiseyes"
	desc = "A design for biological organ."
	build_type = BIOAEGIS
	construction_time = 150
	reagents_list = list(/datum/reagent/consumable/organicprecursor/advbionanites = 150)
	build_path = /obj/item/organ/eyes/thermalaegis
	category = list("Species-specific Designs")
	min_security_level = SEC_LEVEL_RED
	materials = list (/datum/material/plasma = 15000)

/datum/design/bodyoverload
	name = "Optimia ossmodula"
	id = "bodyoverload"
	desc = "A design for biological organ."
	build_type = BIOAEGIS
	construction_time = 150
	reagents_list = list(/datum/reagent/consumable/organicprecursor/advbionanites = 150)
	build_path = /obj/item/organ/bodyoverload
	category = list("Dangerous Designs")
	min_security_level = SEC_LEVEL_RED
	materials = list (/datum/material/plasma = 15000)

/datum/design/neuralderanger
	name = "Nemedia ossmodula"
	id = "neuralderanger"
	desc = "A design for biological organ."
	build_type = BIOAEGIS
	construction_time = 150
	reagents_list = list(/datum/reagent/consumable/organicprecursor/advbionanites = 150)
	build_path = /obj/item/organ/neuralderanger
	category = list("Dangerous Designs")
	min_security_level = SEC_LEVEL_RED
	materials = list (/datum/material/plasma = 15000)

/datum/design/vocalbabylon
	name = "Babylon's Vocal Cords"
	id = "babyloncords"
	desc = "A design for biological organ."
	build_type = BIOAEGIS
	construction_time = 150
	reagents_list = list(/datum/reagent/consumable/organicprecursor/advbionanites = 50)
	build_path = /obj/item/organ/vocal_cords/babyloncords
	category = list("Species-specific Designs")
	materials = list (/datum/material/plasma = 15000)
