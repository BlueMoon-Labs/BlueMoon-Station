/////////////////////////////////////////
//////////Cybernetic Implants////////////
/////////////////////////////////////////
/datum/design/cyberimp_welding
	name = "Welding Shield Eyes"
	desc = "These reactive micro-shields will protect you from welders and flashes without obscuring your vision."
	id = "ci-welding"
	build_type = PROTOLATHE | MECHFAB
	construction_time = 40
	materials = list(/datum/material/iron = 600, /datum/material/glass = 400)
	build_path = /obj/item/organ/eyes/robotic/shield
	category = list("Cybernetics", "Organs")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL | DEPARTMENTAL_FLAG_ENGINEERING

/datum/design/cyberimp_gloweyes
	name = "Luminescent Eyes"
	desc = "A pair of cybernetic eyes that can emit multicolored light"
	id = "ci-gloweyes"
	build_type = PROTOLATHE | MECHFAB
	construction_time = 40
	materials = list(/datum/material/iron = 600, /datum/material/glass = 1000)
	build_path = /obj/item/organ/eyes/robotic/glow
	category = list("Cybernetics", "Organs")
	departmental_flags = DEPARTMENTAL_FLAG_ALL

// Derivative of glow eyes
/datum/design/cyberimp_gloweyes/cyberimp_hypnoeyes
	name = "Mesmer Eyes"
	desc = "Cybernetic eyes with integrated memetic sub-systems."
	id = "ci-hypnoeyes"
	build_path = /obj/item/organ/eyes/robotic/hypno

///datum/design/cyberimp_xray
//	name = "X-ray Eyes"
//	desc = "These cybernetic eyes will give you X-ray vision. Blinking is futile."
//	id = "ci-xray"
//	build_type = PROTOLATHE | MECHFAB
//	construction_time = 60
//	materials = list(/datum/material/iron = 600, /datum/material/glass = 600, /datum/material/silver = 600, /datum/material/gold = 600, /datum/material/plasma = 1000, /datum/material/uranium = 1000, /datum/material/diamond = 1000, /datum/material/bluespace = 1000)
//	build_path = /obj/item/organ/eyes/robotic/xray
//	category = list("Cybernetics", "Organs")
//	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL | DEPARTMENTAL_FLAG_SECURITY

/datum/design/cyberimp_thermals
	name = "Thermal Eyes"
	desc = "These cybernetic eyes will give you Thermal vision. Vertical slit pupil included."
	id = "ci-thermals"
	build_type = PROTOLATHE | MECHFAB
	construction_time = 60
	materials = list(/datum/material/iron = 600, /datum/material/glass = 600, /datum/material/silver = 600, /datum/material/gold = 600, /datum/material/plasma = 1000, /datum/material/diamond = 2000)
	build_path = /obj/item/organ/eyes/robotic/thermals
	category = list("Cybernetics", "Organs")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL | DEPARTMENTAL_FLAG_SECURITY
	min_security_level = SEC_LEVEL_RED

/////////////////////
//Cybernetic organs//
/////////////////////

/datum/design/cybernetic_liver
	name = "Basic Cybernetic Liver"
	desc = "A basic cybernetic liver."
	id = "cybernetic_liver"
	build_type = PROTOLATHE | MECHFAB
	construction_time = 40
	materials = list(/datum/material/iron = 500, /datum/material/glass = 500)
	build_path = /obj/item/organ/liver/cybernetic
	category = list("Cybernetics", "Organs")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL

/datum/design/cybernetic_liver/tier2
	name = "Cybernetic Liver"
	desc = "A cybernetic liver."
	id = "cybernetic_liver_tier2"
	materials = list(/datum/material/iron = 500, /datum/material/glass = 500)
	build_path = /obj/item/organ/liver/cybernetic/tier2

/datum/design/cybernetic_liver/tier3
	name = "Upgraded Cybernetic Liver"
	desc = "An upgraded cybernetic liver."
	id = "cybernetic_liver_tier3"
	construction_time = 50
	materials = list(/datum/material/iron = 500, /datum/material/glass = 500, /datum/material/silver = 600, /datum/material/gold = 600, /datum/material/plasma = 1000, /datum/material/diamond = 2000)
	build_path = /obj/item/organ/liver/cybernetic/tier3

/datum/design/cybernetic_heart
	name = "Basic Cybernetic Heart"
	desc = "A basic cybernetic heart."
	id = "cybernetic_heart"
	build_type = PROTOLATHE | MECHFAB
	construction_time = 40
	materials = list(/datum/material/iron = 500, /datum/material/glass = 500)
	build_path = /obj/item/organ/heart/cybernetic
	category = list("Cybernetics", "Organs")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL

/datum/design/cybernetic_heart/tier2
	name = "Cybernetic Heart"
	desc = "A cybernetic heart."
	id = "cybernetic_heart_tier2"
	materials = list(/datum/material/iron = 500, /datum/material/glass = 500)
	build_path = /obj/item/organ/heart/cybernetic/tier2

/datum/design/cybernetic_heart/tier3
	name = "Upgraded Cybernetic Heart"
	desc = "An upgraded cybernetic heart."
	id = "cybernetic_heart_tier3"
	construction_time = 50
	materials = list(/datum/material/iron = 500, /datum/material/glass = 500, /datum/material/silver = 600, /datum/material/gold = 600, /datum/material/plasma = 1000, /datum/material/diamond = 2000)
	build_path = /obj/item/organ/heart/cybernetic/tier3

/datum/design/cybernetic_lungs
	name = "Basic Cybernetic Lungs"
	desc = "A basic pair of cybernetic lungs."
	id = "cybernetic_lungs"
	build_type = PROTOLATHE | MECHFAB
	construction_time = 40
	materials = list(/datum/material/iron = 500, /datum/material/glass = 500)
	build_path = /obj/item/organ/lungs/cybernetic
	category = list("Cybernetics", "Organs")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL

/datum/design/cybernetic_lungs/tier2
	name = "Cybernetic Lungs"
	desc = "A pair of cybernetic lungs."
	id = "cybernetic_lungs_tier2"
	materials = list(/datum/material/iron = 500, /datum/material/glass = 500)
	build_path = /obj/item/organ/lungs/cybernetic/tier2

/datum/design/cybernetic_lungs/tier3
	name = "Upgraded Cybernetic Lungs"
	desc = "A pair of upgraded cybernetic lungs."
	id = "cybernetic_lungs_tier3"
	construction_time = 50
	materials = list(/datum/material/iron = 500, /datum/material/glass = 500, /datum/material/silver = 600, /datum/material/gold = 600, /datum/material/plasma = 1000, /datum/material/diamond = 2000)
	build_path = /obj/item/organ/lungs/cybernetic/tier3

/datum/design/cybernetic_stomach
	name = "Basic Cybernetic Stomach"
	desc = "A basic cybernetic stomach."
	id = "cybernetic_stomach"
	build_type = PROTOLATHE | MECHFAB
	construction_time = 40
	materials = list(/datum/material/iron = 500, /datum/material/glass = 500)
	build_path = /obj/item/organ/stomach/cybernetic
	category = list("Cybernetics", "Organs")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL

/datum/design/cybernetic_stomach/tier2
	name = "Cybernetic Stomach"
	desc = "A cybernetic stomach."
	id = "cybernetic_stomach_tier2"
	materials = list(/datum/material/iron = 500, /datum/material/glass = 500)
	build_path = /obj/item/organ/stomach/cybernetic/tier2

/datum/design/cybernetic_stomach/tier3
	name = "Upgraded Cybernetic Stomach"
	desc = "An upgraded cybernetic stomach."
	id = "cybernetic_stomach_tier3"
	construction_time = 50
	materials = list(/datum/material/iron = 500, /datum/material/glass = 500, /datum/material/silver = 600, /datum/material/gold = 600, /datum/material/plasma = 1000, /datum/material/diamond = 2000)
	build_path = /obj/item/organ/stomach/cybernetic/tier3

/datum/design/cybernetic_tongue
	name = "Cybernetic tongue"
	desc = "A fancy cybernetic tongue."
	id = "cybernetic_tongue"
	build_type = PROTOLATHE | MECHFAB
	materials = list(/datum/material/iron = 500, /datum/material/glass = 500)
	build_path = /obj/item/organ/tongue/cybernetic
	category = list("Cybernetics", "Organs")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL

/datum/design/cybernetic_ears
	name = "Cybernetic Ears"
	desc = "A pair of cybernetic ears."
	id = "cybernetic_ears"
	build_type = PROTOLATHE | MECHFAB
	construction_time = 30
	materials = list(/datum/material/iron = 250, /datum/material/glass = 400)
	build_path = /obj/item/organ/ears/cybernetic
	category = list("Cybernetics", "Organs")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL

/datum/design/cybernetic_ears_u
	name = "Upgraded Cybernetic Ears"
	desc = "A pair of upgraded cybernetic ears."
	id = "cybernetic_ears_u"
	build_type = PROTOLATHE | MECHFAB
	construction_time = 40
	materials = list(/datum/material/iron = 500, /datum/material/glass = 500, /datum/material/silver = 500)
	build_path = /obj/item/organ/ears/cybernetic/upgraded
	category = list("Cybernetics", "Organs")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL

/////////////////////
/////Synth Organs////
/////////////////////

/datum/design/ipc_stomach
	name = "IPC cell"
	desc = "Effectively the robot equivalent of a stomach, handling power storage."
	id = "ipc_stomach"
	build_type = PROTOLATHE | MECHFAB
	construction_time = 40
	materials = list(/datum/material/iron = 1000, /datum/material/glass = 300, /datum/material/silver = 500, /datum/material/gold = 400)
	build_path = /obj/item/organ/stomach/ipc
	category = list("Misc", "Organs")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL

/////////////////////////////////////////
////////////Medical Prosthetics//////////
/////////////////////////////////////////

/datum/design/basic_l_arm
	name = "Surplus prosthetic left arm"
	desc = "Basic outdated and fragile prosthetic left arm."
	id = "basic_l_arm"
	build_type = PROTOLATHE | MECHFAB
	materials = list(/datum/material/iron = 5000, /datum/material/glass = 2500)
	construction_time = 20
	build_path = /obj/item/bodypart/l_arm/robot/surplus
	category = list("Prosthetics", "Organs")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL

/datum/design/basic_r_arm
	name = "Surplus prosthetic right arm"
	desc = "Basic outdated and fragile prosthetic left arm."
	id = "basic_r_arm"
	build_type = PROTOLATHE | MECHFAB
	materials = list(/datum/material/iron = 5000, /datum/material/glass = 2500)
	construction_time = 20
	build_path = /obj/item/bodypart/r_arm/robot/surplus
	category = list("Prosthetics", "Organs")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL

/datum/design/basic_l_leg
	name = "Surplus prosthetic left leg"
	desc = "Basic outdated and fragile prosthetic left leg."
	id = "basic_l_leg"
	build_type = PROTOLATHE | MECHFAB
	materials = list(/datum/material/iron = 5000, /datum/material/glass = 2500)
	construction_time = 20
	build_path = /obj/item/bodypart/l_leg/robot/surplus
	category = list("Prosthetics", "Organs")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL

/datum/design/basic_r_leg
	name = "Surplus prosthetic right leg"
	desc = "Basic outdated and fragile prosthetic right leg."
	id = "basic_r_leg"
	build_type = PROTOLATHE | MECHFAB
	materials = list(/datum/material/iron = 5000, /datum/material/glass = 2500)
	construction_time = 20
	build_path = /obj/item/bodypart/r_leg/robot/surplus
	category = list("Prosthetics", "Organs")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL

/datum/design/adv_r_leg
	name = "Advanced prosthetic right leg"
	desc = "A renforced prosthetic right leg."
	id = "adv_r_leg"
	build_type = PROTOLATHE | MECHFAB
	materials = list(/datum/material/iron = 6000, /datum/material/glass = 3500, /datum/material/gold = 500, /datum/material/titanium = 800)
	construction_time = 40
	build_path = /obj/item/bodypart/r_leg/robot/surplus_upgraded
	category = list("Prosthetics", "Organs")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL

/datum/design/adv_l_leg
	name = "Advanced prosthetic left leg"
	desc = "A renforced prosthetic left leg."
	id = "adv_l_leg"
	build_type = PROTOLATHE | MECHFAB
	materials = list(/datum/material/iron = 6000, /datum/material/glass = 3500, /datum/material/gold = 500, /datum/material/titanium = 800)
	construction_time = 40
	build_path = /obj/item/bodypart/l_leg/robot/surplus_upgraded
	category = list("Prosthetics", "Organs")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL

/datum/design/adv_l_arm
	name = "Advanced prosthetic left arm"
	desc = "A renforced prosthetic left arm."
	id = "adv_l_arm"
	build_type = PROTOLATHE | MECHFAB
	materials = list(/datum/material/iron = 6000, /datum/material/glass = 3500, /datum/material/gold = 500, /datum/material/titanium = 800)
	construction_time = 40
	build_path = /obj/item/bodypart/l_arm/robot/surplus_upgraded
	category = list("Prosthetics", "Organs")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL

/datum/design/adv_r_arm
	name = "Advanced prosthetic right arm"
	desc = "A renforced prosthetic right arm."
	id = "adv_r_arm"
	build_type = PROTOLATHE | MECHFAB
	materials = list(/datum/material/iron = 6000, /datum/material/glass = 3500, /datum/material/gold = 500, /datum/material/titanium = 800)
	construction_time = 40
	build_path = /obj/item/bodypart/r_arm/robot/surplus_upgraded
	category = list("Prosthetics", "Organs")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL


/////////////////////////////////////////
//////////////Organic Designs////////////
/////////////////////////////////////////
//Xeno organs for hand-made hives and stuff//
/datum/design/plasmavessel
	name = "Plasma Vessel"
	id = "plasmavessel"
	desc = "A design for xenochimeric plasma vessel."
	build_type = PROTOLATHE
	construction_time = 150
	reagents_list = list(/datum/reagent/consumable/organicprecursor/xenochimeric = 200)
	build_path = /obj/item/organ/alien/plasmavessel/large/queen
	category = list("Organic Designs")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE
	materials = list (/datum/material/glass = 30000, /datum/material/plasma = 10000)
	min_security_level = SEC_LEVEL_RED

/datum/design/resinspinner
	name = "Resin Spinner"
	id = "resinspinner"
	desc = "A design for xenochimeric resin spinner."
	build_type = PROTOLATHE
	construction_time = 150
	reagents_list = list(/datum/reagent/consumable/organicprecursor/xenochimeric = 200)
	build_path = /obj/item/organ/alien/resinspinner
	category = list("Organic Designs")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE
	materials = list (/datum/material/glass = 30000, /datum/material/plasma = 10000)
	min_security_level = SEC_LEVEL_RED

/datum/design/acidgland
	name = "Acid Gland"
	id = "acidgland"
	desc = "A design for xenochimeric acid gland."
	build_type = PROTOLATHE
	construction_time = 150
	reagents_list = list(/datum/reagent/consumable/organicprecursor/xenochimeric = 200)
	build_path = /obj/item/organ/alien/acid
	category = list("Organic Designs")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE
	materials = list (/datum/material/glass = 30000, /datum/material/plasma = 10000)
	min_security_level = SEC_LEVEL_RED

/datum/design/neurotoxingland
	name = "Neurotoxin Gland"
	id = "neurotoxin"
	desc = "A design for xenochimeric neurotoxin gland."
	build_type = PROTOLATHE
	construction_time = 150
	reagents_list = list(/datum/reagent/consumable/organicprecursor/xenochimeric = 200)
	build_path = /obj/item/organ/alien/neurotoxin
	category = list("Organic Designs")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE
	materials = list (/datum/material/glass = 30000, /datum/material/plasma = 10000)
	min_security_level = SEC_LEVEL_RED

/datum/design/eggsac
	name = "Egg Sac"
	id = "eggsac"
	desc = "A design for xenochimeric egg sac."
	build_type = PROTOLATHE
	construction_time = 150
	reagents_list = list(/datum/reagent/consumable/organicprecursor/xenochimeric = 200)
	build_path = /obj/item/organ/alien/eggsac
	category = list("Organic Designs")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE
	materials = list (/datum/material/glass = 30000, /datum/material/plasma = 10000)
	min_security_level = SEC_LEVEL_RED

/datum/design/hivenode
	name = "Hive node"
	id = "hivenode"
	desc = "A design for xenochimeric hive node."
	build_type = PROTOLATHE
	construction_time = 150
	reagents_list = list(/datum/reagent/consumable/organicprecursor/xenochimeric = 200)
	build_path = /obj/item/organ/alien/hivenode
	category = list("Organic Designs")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE
	materials = list (/datum/material/glass = 30000, /datum/material/plasma = 10000)
	min_security_level = SEC_LEVEL_RED

/datum/design/alientongue
	name = "Alien Tongue"
	id = "alientongue"
	desc = "A design for xenochimeric alien tongue."
	build_type = PROTOLATHE
	construction_time = 150
	reagents_list = list(/datum/reagent/consumable/organicprecursor/xenochimeric = 200)
	build_path = /obj/item/organ/tongue/alien
	category = list("Organic Designs")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE
	materials = list (/datum/material/glass = 30000, /datum/material/plasma = 10000)
	min_security_level = SEC_LEVEL_RED
