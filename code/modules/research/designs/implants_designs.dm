/////////////////////////////////////////
//////////Cybernetic Implants////////////
/////////////////////////////////////////
/datum/design/cyberimp_breather
	name = "Breathing Tube Implant"
	desc = "This simple implant adds an internals connector to your back, allowing you to use internals without a mask and protecting you from being choked."
	id = "ci-breather"
	build_type = PROTOLATHE | MECHFAB
	construction_time = 35
	materials = list(/datum/material/iron = 600, /datum/material/glass = 250)
	build_path = /obj/item/organ/cyberimp/mouth/breathing_tube
	category = list("Implants")
	departmental_flags = DEPARTMENTAL_FLAG_ALL

/datum/design/cyberimp_claws
	name = "Claws implant"
	desc = "Набор из двух пар острых когтей, созданных из лёгких сплавов. Когда хочешь стать тем самым героем из старых фильмов."
	id = "ci_claws"
	build_type = PROTOLATHE | MECHFAB
	construction_time = 40
	materials = list(/datum/material/iron = 6000, /datum/material/titanium = 4000, /datum/material/glass = 1000)
	build_path = /obj/item/organ/cyberimp/arm/razor_claws
	category = list("Implants")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL | DEPARTMENTAL_FLAG_SECURITY

/datum/design/cyberimp_surgical
	name = "Surgical Arm Implant"
	desc = "A set of surgical tools hidden behind a concealed panel on the user's arm."
	id = "ci-surgery"
	build_type = PROTOLATHE | MECHFAB
	materials = list (/datum/material/iron = 2500, /datum/material/glass = 1500, /datum/material/silver = 1500)
	construction_time = 200
	build_path = /obj/item/organ/cyberimp/arm/surgery
	category = list("Implants")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL

/datum/design/cyberimp_toolset
	name = "Toolset Arm Implant"
	desc = "A stripped-down version of engineering cyborg toolset, designed to be installed on subject's arm."
	id = "ci-toolset"
	build_type = PROTOLATHE | MECHFAB
	materials = list (/datum/material/iron = 2500, /datum/material/glass = 1500, /datum/material/silver = 1500)
	construction_time = 200
	build_path = /obj/item/organ/cyberimp/arm/toolset
	category = list("Implants")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL | DEPARTMENTAL_FLAG_ENGINEERING

/datum/design/cyberimp_surgical_advanced
	name = "Advanced Surgical Arm Implant"
	desc = "A very advanced version of the regular surgical implant, has alien stuff!"
	id = "ci-surgery-adv"
	build_type = PROTOLATHE | MECHFAB
	materials = list (/datum/material/iron = 7500, /datum/material/glass = 4500, /datum/material/silver = 4500)
	construction_time = 200
	build_path = /obj/item/organ/cyberimp/arm/surgery/advanced
	category = list("Implants")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL

/datum/design/cyberimp_toolset_advanced
	name = "Advanced Toolset Arm Implant"
	desc = "A very advanced version of the regular toolset implant, has alien stuff!"
	id = "ci-toolset-adv"
	build_type = PROTOLATHE | MECHFAB
	materials = list (/datum/material/iron = 7500, /datum/material/glass = 4500, /datum/material/silver = 4500)
	construction_time = 200
	build_path = /obj/item/organ/cyberimp/arm/toolset/advanced
	category = list("Implants")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL | DEPARTMENTAL_FLAG_ENGINEERING

/datum/design/cyberimp_shield
	name = "Riot shieldimplant"
	desc = "An implanted riot shield, designed to be installed on subject's arm."
	id = "ci-shield"
	build_type = PROTOLATHE
	materials = list (/datum/material/iron = 8500, /datum/material/glass = 8500, /datum/material/silver = 1800, /datum/material/titanium = 600)
	construction_time = 200
	build_path = /obj/item/organ/cyberimp/arm/shield
	category = list("Implants")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL | DEPARTMENTAL_FLAG_SECURITY
	min_security_level = SEC_LEVEL_BLUE

/datum/design/cyberimp_chem
	name = "Chemical Sequencer Implant"
	desc = "This implant can inject limited list of basic reagents into your blood."
	id = "ci-chemseq"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 600, /datum/material/glass = 600, /datum/material/silver = 500, /datum/material/gold = 1000)
	construction_time = 120
	build_path = /obj/item/organ/cyberimp/chest/chem_implant
	category = list("Implants")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL | DEPARTMENTAL_FLAG_SECURITY
	min_security_level = SEC_LEVEL_AMBER

/datum/design/cyberimp_janitor
	name = "Janitor Arm Implant"
	desc = "A set of janitor tools fitted into an arm implant, designed to be installed on subject's arm."
	id = "ci-janitor"
	build_type = PROTOLATHE | MECHFAB
	materials = list (/datum/material/iron = 3500, /datum/material/glass = 1500, /datum/material/silver = 1500)
	construction_time = 200
	build_path = /obj/item/organ/cyberimp/arm/janitor
	category = list("Implants")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL | DEPARTMENTAL_FLAG_SERVICE

/datum/design/cyberimp_service
	name = "Service Arm Implant"
	desc = "Everything a cook or barkeep needs in an arm implant, designed to be installed on subject's arm."
	id = "ci-service"
	build_type = PROTOLATHE | MECHFAB
	materials = list (/datum/material/iron = 3500, /datum/material/glass = 1500, /datum/material/silver = 1500)
	construction_time = 200
	build_path = /obj/item/organ/cyberimp/arm/service
	category = list("Implants")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL | DEPARTMENTAL_FLAG_SERVICE

/datum/design/cyberimp_medical_hud
	name = "Medical HUD Implant"
	desc = "These cybernetic eyes will display a medical HUD over everything you see. Wiggle eyes to control."
	id = "ci-medhud"
	build_type = PROTOLATHE | MECHFAB
	construction_time = 50
	materials = list(/datum/material/iron = 600, /datum/material/glass = 600, /datum/material/silver = 500, /datum/material/gold = 500)
	build_path = /obj/item/organ/cyberimp/eyes/hud/medical
	category = list("Implants")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL

/datum/design/cyberimp_security_hud
	name = "Security HUD Implant"
	desc = "These cybernetic eyes will display a security HUD over everything you see. Wiggle eyes to control."
	id = "ci-sechud"
	build_type = PROTOLATHE | MECHFAB
	construction_time = 50
	materials = list(/datum/material/iron = 600, /datum/material/glass = 600, /datum/material/silver = 750, /datum/material/gold = 750)
	build_path = /obj/item/organ/cyberimp/eyes/hud/security
	category = list("Implants")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL | DEPARTMENTAL_FLAG_SECURITY

/datum/design/cyberimp_diagnostic_hud
	name = "Diagnostic HUD Implant"
	desc = "These cybernetic eyes will display a diagnostic HUD over everything you see. Wiggle eyes to control."
	id = "ci-diaghud"
	build_type = PROTOLATHE | MECHFAB
	construction_time = 50
	materials = list(/datum/material/iron = 600, /datum/material/glass = 600, /datum/material/silver = 500, /datum/material/gold = 500)
	build_path = /obj/item/organ/cyberimp/eyes/hud/diagnostic
	category = list("Implants")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL

/datum/design/cyberimp_antidrop
	name = "Anti-Drop Implant"
	desc = "This cybernetic brain implant will allow you to force your hand muscles to contract, preventing item dropping. Twitch ear to toggle."
	id = "ci-antidrop"
	build_type = PROTOLATHE | MECHFAB
	construction_time = 60
	materials = list(/datum/material/iron = 600, /datum/material/glass = 600, /datum/material/silver = 400, /datum/material/gold = 400)
	build_path = /obj/item/organ/cyberimp/brain/anti_drop
	category = list("Implants")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL | DEPARTMENTAL_FLAG_SECURITY
	min_security_level = SEC_LEVEL_AMBER

/datum/design/cyberimp_antistun
	name = "CNS Rebooter Implant"
	desc = "This implant will automatically give you back control over your central nervous system, reducing downtime when stunned."
	id = "ci-antistun"
	build_type = PROTOLATHE | MECHFAB
	construction_time = 60
	materials = list(/datum/material/iron = 600, /datum/material/glass = 600, /datum/material/silver = 500, /datum/material/gold = 1000)
	build_path = /obj/item/organ/cyberimp/brain/anti_stun
	category = list("Implants")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL | DEPARTMENTAL_FLAG_SECURITY
	min_security_level = SEC_LEVEL_AMBER

/datum/design/cyberimp_robot_radshielding
	name = "ECC System Guard Implant"
	desc = "This implant can counteract the effects of harmful radiation in robots, effectively increasing their radiation tolerance significantly."
	id = "ci-robot-radshielding"
	build_type = PROTOLATHE | MECHFAB
	construction_time = 40
	materials = list(/datum/material/iron = 500, /datum/material/glass = 400, /datum/material/silver = 350, /datum/material/gold = 1000, /datum/material/diamond = 100)
	build_path = /obj/item/organ/cyberimp/brain/robot_radshielding
	category = list("IPC Organs", "Implants")
	departmental_flags = DEPARTMENTAL_FLAG_ALL

/datum/design/cyberimp_nutriment
	name = "Nutriment Pump Implant"
	desc = "This implant with synthesize and pump into your bloodstream a small amount of nutriment when you are starving."
	id = "ci-nutriment"
	build_type = PROTOLATHE | MECHFAB
	construction_time = 40
	materials = list(/datum/material/iron = 500, /datum/material/glass = 500, /datum/material/gold = 500)
	build_path = /obj/item/organ/cyberimp/chest/nutriment
	category = list("Implants")
	departmental_flags = DEPARTMENTAL_FLAG_ALL

/datum/design/cyberimp_nutriment_plus
	name = "Nutriment Pump Implant PLUS"
	desc = "This implant with synthesize and pump into your bloodstream a small amount of nutriment when you are hungry."
	id = "ci-nutrimentplus"
	build_type = PROTOLATHE | MECHFAB
	construction_time = 50
	materials = list(/datum/material/iron = 600, /datum/material/glass = 600, /datum/material/gold = 500, /datum/material/uranium = 750)
	build_path = /obj/item/organ/cyberimp/chest/nutriment/plus
	category = list("Implants")
	departmental_flags = DEPARTMENTAL_FLAG_ALL

/datum/design/cyberimp_reviver
	name = "Reviver Implant"
	desc = "This implant will attempt to revive you if you lose consciousness. For the faint of heart!"
	id = "ci-reviver"
	build_type = PROTOLATHE | MECHFAB
	construction_time = 60
	materials = list(/datum/material/iron = 800, /datum/material/glass = 800, /datum/material/gold = 300, /datum/material/uranium = 500)
	build_path = /obj/item/organ/cyberimp/chest/reviver
	category = list("Implants")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL | DEPARTMENTAL_FLAG_SECURITY
	min_security_level = SEC_LEVEL_AMBER

/datum/design/cyberimp_thrusters
	name = "Thrusters Set Implant"
	desc = "This implant will allow you to use gas from environment or your internals for propulsion in zero-gravity areas."
	id = "ci-thrusters"
	build_type = PROTOLATHE | MECHFAB
	construction_time = 80
	materials = list(/datum/material/iron = 4000, /datum/material/glass = 2000, /datum/material/silver = 1000, /datum/material/diamond = 1000)
	build_path = /obj/item/organ/cyberimp/chest/thrusters
	category = list("Implants")
	departmental_flags = DEPARTMENTAL_FLAG_ALL

/datum/design/cyberimp_mantis
	name = "Mantis Blade Implant"
	desc = "A long, sharp, mantis-like blade installed within the forearm, acting as a deadly self defense weapon."
	id = "ci-mantis"
	build_type = PROTOLATHE
	materials = list (/datum/material/iron = 3500, /datum/material/glass = 1500, /datum/material/silver = 1500)
	construction_time = 200
	build_path = /obj/item/organ/cyberimp/arm/mantis_blade
	category = list("Implants")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL | DEPARTMENTAL_FLAG_SECURITY
	min_security_level = SEC_LEVEL_AMBER

/datum/design/cyberimp_scanner
	name = "Internal Medical Analyzer"
	desc = "This implant interfaces with a host's body, sending detailed readouts of the vessel's condition on command via the mind."
	id = "ci-scanner"
	build_type = PROTOLATHE | MECHFAB
	construction_time = 40
	materials = list(/datum/material/iron = 5000, /datum/material/glass = 2500, /datum/material/silver = 2000, /datum/material/gold = 1500)
	build_path = /obj/item/organ/internal/cyberimp/chest/scanner
	category = list("Implants")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL | DEPARTMENTAL_FLAG_SCIENCE

/datum/design/cyberimphealerext
	name = "External Healing Implant"
	desc = "This implant will slowly mend localized damage that it can find. This version mends only brute and fire injures!"
	id = "ci-healerext"
	build_type = PROTOLATHE
	construction_time = 40
	materials = list(/datum/material/iron = 10000, /datum/material/glass = 10000, /datum/material/silver = 6000, /datum/material/gold = 6000, /datum/material/diamond = 6000)
	build_path = /obj/item/organ/cyberimp/chest/healer
	category = list("Implants")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL | DEPARTMENTAL_FLAG_SECURITY

/datum/design/cyberimphealerint
	name = "Internal Healing Implant"
	desc = "This implant will slowly mend localized damage that it can find. This version filters out toxins, as well as considers any lack of oxygen in the bloodstream! "
	id = "ci-healerint"
	build_type = PROTOLATHE | MECHFAB
	construction_time = 40
	materials = list(/datum/material/iron = 10000, /datum/material/glass = 10000, /datum/material/silver = 6000, /datum/material/gold = 6000, /datum/material/diamond = 6000)
	build_path = /obj/item/organ/cyberimp/chest/healertoxoxy
	category = list("Implants")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL | DEPARTMENTAL_FLAG_SCIENCE

/datum/design/cyberimphealercortex
	name = "Revitalizing Cortex Implant"
	desc = "This attachable to the torso cortex optimizes the body's processes in order to preserve the body. Provides overall basic mending."
	id = "ci-cortex"
	build_type = PROTOLATHE
	construction_time = 40
	materials = list(/datum/material/iron = 10000, /datum/material/glass = 10000, /datum/material/silver = 6000, /datum/material/gold = 6000, /datum/material/diamond = 6000, /datum/material/bluespace = 6000)
	build_path = /obj/item/organ/cyberimp/chest/revitilzer
	category = list("Implants")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL | DEPARTMENTAL_FLAG_SECURITY

/datum/design/cyberimp_nutrimentpumpextreme
	name = "Nutriment pump implant EXTREME"
	desc = "This implant will synthesize and pump into your bloodstream a small amount of nutriment when you are hungry. This version of the pump also provides a proper water supply."
	id = "ci-pumpextreme"
	build_type = PROTOLATHE | MECHFAB
	construction_time = 40
	materials = list(/datum/material/iron = 5000, /datum/material/glass = 5000, /datum/material/silver = 5000, /datum/material/gold = 5000)
	build_path = /obj/item/organ/cyberimp/chest/nutrimentextreme
	category = list("Implants")
	departmental_flags = DEPARTMENTAL_FLAG_ALL

/datum/design/binolenses
	name = "Binocular Lenses Implant"
	desc = "A pair of binocular lenses, that can be attached to the eyes!"
	id = "ci-binolenses"
	build_type = PROTOLATHE | MECHFAB
	construction_time = 40
	materials = list(/datum/material/iron = 5000, /datum/material/glass = 6000, /datum/material/silver = 2000, /datum/material/diamond = 2000)
	build_path = /obj/item/organ/cyberimp/arm/lenses
	category = list("Implants")
	departmental_flags = DEPARTMENTAL_FLAG_ALL

//DATA CHIP. Expensive stuff for good chips.
/datum/design/medicalbrainchip
	name = "Advanced Medical Data Chip"
	desc = "Special implant that was designed to help field operators with medical care for their fallen brethren. Allows advanced surgical procedures outside of the sterile conditions."
	id = "chip-medical"
	build_type = PROTOLATHE
	construction_time = 100
	materials = list(/datum/material/iron = 30000, /datum/material/glass = 30000, /datum/material/silver = 6000, /datum/material/gold = 6000, /datum/material/diamond = 6000, /datum/material/bluespace = 6000)
	build_path = /obj/item/organ/cyberimp/brainchip/medical
	category = list("Implants")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL

/datum/design/engibrainchip
	name = "Advanced Electrical Data Chip"
	desc = "Special implant that was designed to provide a quick learning for field engineers and inadept electricians."
	id = "chip-engi"
	build_type = PROTOLATHE
	construction_time = 100
	materials = list(/datum/material/iron = 30000, /datum/material/glass = 30000, /datum/material/silver = 6000, /datum/material/gold = 6000, /datum/material/diamond = 6000, /datum/material/bluespace = 6000)
	build_path = /obj/item/organ/cyberimp/brainchip/engi
	category = list("Implants")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL | DEPARTMENTAL_FLAG_ENGINEERING

/datum/design/roboticalbrainchip
	name = "Advanced Robotical Data Chip"
	desc = "Special implant that was designed to provide a quick learning for inadept roboticians and on-field crew."
	id = "chip-robotic"
	build_type = PROTOLATHE
	construction_time = 100
	materials = list(/datum/material/iron = 30000, /datum/material/glass = 30000, /datum/material/silver = 6000, /datum/material/gold = 6000, /datum/material/diamond = 6000, /datum/material/bluespace = 6000)
	build_path = /obj/item/organ/cyberimp/brainchip/robotic
	category = list("Implants")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL | DEPARTMENTAL_FLAG_SCIENCE

/////////////////////////////////////////
////////////Regular Implants/////////////
/////////////////////////////////////////

/datum/design/implanter
	name = "Implanter"
	desc = "A sterile automatic implant injector."
	id = "Implanter"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 600, /datum/material/glass = 200)
	build_path = /obj/item/implanter
	category = list("Implants")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL | DEPARTMENTAL_FLAG_SCIENCE | DEPARTMENTAL_FLAG_SECURITY

/datum/design/implantcase
	name = "Implant Case"
	desc = "A glass case for containing an implant."
	id = "implantcase"
	build_type = PROTOLATHE
	materials = list(/datum/material/glass = 500)
	build_path = /obj/item/implantcase
	category = list("Implants")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL | DEPARTMENTAL_FLAG_SCIENCE | DEPARTMENTAL_FLAG_SECURITY

/datum/design/implant_sadtrombone
	name = "Sad Trombone Implant Case"
	desc = "Makes death amusing."
	id = "implant_trombone"
	build_type = PROTOLATHE
	materials = list(/datum/material/glass = 500, /datum/material/bananium = 500)
	build_path = /obj/item/implantcase/sad_trombone
	category = list("Implants")
	departmental_flags = DEPARTMENTAL_FLAG_ALL		//if you get bananium you get the sad trombones.

/datum/design/implant_chem
	name = "Chemical Implant Case"
	desc = "A glass case containing an implant."
	id = "implant_chem"
	build_type = PROTOLATHE
	materials = list(/datum/material/glass = 700)
	build_path = /obj/item/implantcase/chem
	category = list("Implants")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL | DEPARTMENTAL_FLAG_SECURITY

/datum/design/implant_tracking
	name = "Tracking Implant Case"
	desc = "A glass case containing an implant."
	id = "implant_tracking"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 500, /datum/material/glass = 500)
	build_path = /obj/item/implantcase/track
	category = list("Implants")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL | DEPARTMENTAL_FLAG_SECURITY

/datum/design/implant_slave
	name = "Slave Implant Case"
	desc = "A glass case containing an implant."
	id = "implant_slave"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 500, /datum/material/glass = 500)
	build_path = /obj/item/implantcase/slave
	category = list("Implants")
	departmental_flags = DEPARTMENTAL_FLAG_SECURITY

/datum/design/implant_gfluid
	name = "Genital Fluid Implant Case"
	desc = "A glass case containing an implant"
	id = "implant_gfluid"
	build_type = PROTOLATHE
	materials = list(/datum/material/glass = 500)
	build_path = /obj/item/implantcase/genital_fluid
	category = list("Implants")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE | DEPARTMENTAL_FLAG_MEDICAL

/datum/design/implant_hide_backpack
	name = "Storage Concealment Implant Case"
	desc = "A glass case containing an implant"
	id = "implant_hide_backpack"
	build_type = PROTOLATHE
	materials = list(/datum/material/glass = 500)
	build_path = /obj/item/implantcase/hide_backpack
	category = list("Implants")
	departmental_flags = DEPARTMENTAL_FLAG_ALL

/datum/design/board/implantradio
	name = "Radio Implant Case"
	desc = "A glass case containing an implant"
	id = "impant_radio"
	build_path = /obj/item/implantcase/radio
	category = list("Implants")
	departmental_flags = DEPARTMENTAL_FLAG_ALL

/////////////////////
/////Synth Organs////
/////////////////////

/datum/design/cyberimp_power_cord
	name = "IPC power cord"
	desc = "A implant for Robots designed to siphon power from APCs to recharge their own cell."
	id = "ci-power-cord"
	build_type = PROTOLATHE | MECHFAB
	construction_time = 75
	materials = list(/datum/material/iron = 4000, /datum/material/glass = 1500, /datum/material/silver = 1200, /datum/material/gold = 1600, /datum/material/plasma = 1000)
	build_path = /obj/item/organ/cyberimp/arm/power_cord
	category = list("IPC Organs", "Implants")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL
