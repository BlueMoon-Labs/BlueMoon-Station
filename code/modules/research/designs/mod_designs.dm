//MODsuit construction

/datum/design/mod_shell
	name = "MOD Shell"
	desc = "A 'Nakamura Engineering' designed shell for a Modular Suit."
	id = "mod_shell"
	build_type = MECHFAB
	materials = list(/datum/material/iron = 10000, /datum/material/plasma = 5000)
	construction_time = 25 SECONDS
	build_path = /obj/item/mod/construction/shell
	category = list("MODsuit Chassis")

/datum/design/mod_helmet
	name = "MOD Helmet"
	desc = "A 'Nakamura Engineering' designed helmet for a Modular Suit."
	id = "mod_helmet"
	build_type = MECHFAB
	materials = list(/datum/material/iron = 5000)
	construction_time = 10 SECONDS
	build_path = /obj/item/mod/construction/helmet
	category = list("MODsuit Chassis")

/datum/design/mod_chestplate
	name = "MOD Chestplate"
	desc = "A 'Nakamura Engineering' designed chestplate for a Modular Suit."
	id = "mod_chestplate"
	build_type = MECHFAB
	materials = list(/datum/material/iron = 5000)
	construction_time = 10 SECONDS
	build_path = /obj/item/mod/construction/chestplate
	category = list("MODsuit Chassis")

/datum/design/mod_gauntlets
	name = "MOD Gauntlets"
	desc = "'Nakamura Engineering' designed gauntlets for a Modular Suit."
	id = "mod_gauntlets"
	build_type = MECHFAB
	materials = list(/datum/material/iron = 5000)
	construction_time = 10 SECONDS
	build_path = /obj/item/mod/construction/gauntlets
	category = list("MODsuit Chassis")

/datum/design/mod_boots
	name = "MOD Boots"
	desc = "'Nakamura Engineering' designed boots for a Modular Suit."
	id = "mod_boots"
	build_type = MECHFAB
	materials = list(/datum/material/iron = 5000)
	construction_time = 10 SECONDS
	build_path = /obj/item/mod/construction/boots
	category = list("MODsuit Chassis")

/datum/design/mod_plating
	name = "MOD External Plating"
	desc = "External plating for a MODsuit."
	id = "mod_plating_standard"
	build_type = PROTOLATHE | MECHFAB
	materials = list(/datum/material/iron = 6000, /datum/material/glass = 3000, /datum/material/plasma = 1000)
	construction_time = 15 SECONDS
	build_path = /obj/item/mod/construction/armor
	category = list("MODsuit Chassis", "MODsuit Designs")
	departmental_flags = DEPARTMENTAL_FLAG_ALL
	research_icon = 'modular_bluemoon/icons/obj/clothing/modsuit/mod_construction.dmi'
	research_icon_state = "standard-plating"

/datum/design/mod_plating/New()
	. = ..()
	var/obj/item/mod/construction/armor/armor_type = build_path
	var/datum/mod_theme/theme = GLOB.mod_themes[initial(armor_type.theme)]
	desc = "External plating for a MODsuit. [theme.desc]"

/datum/design/mod_plating/engineering
	name = "MOD Engineering Plating"
	id = "mod_plating_engineering"
	build_path = /obj/item/mod/construction/armor/engineering
	materials = list(/datum/material/iron = 6000, /datum/material/gold = 2000, /datum/material/glass = 1000, /datum/material/plasma = 1000)
	departmental_flags = DEPARTMENTAL_FLAG_ENGINEERING
	research_icon_state = "engineering-plating"

/datum/design/mod_plating/atmospheric
	name = "MOD Atmospheric Plating"
	id = "mod_plating_atmospheric"
	build_path = /obj/item/mod/construction/armor/atmospheric
	materials = list(/datum/material/iron = 6000, /datum/material/titanium = 2000, /datum/material/glass = 1000, /datum/material/plasma = 1000)
	departmental_flags = DEPARTMENTAL_FLAG_ENGINEERING
	research_icon_state = "atmospheric-plating"

/datum/design/mod_plating/mining
	name = "MOD Mining Plating"
	id = "mod_plating_mining"
	build_path = /obj/item/mod/construction/armor/mining
	materials = list(/datum/material/iron = 6000, /datum/material/titanium = 2000, /datum/material/glass = 1000, /datum/material/plasma = 1000)
	departmental_flags = DEPARTMENTAL_FLAG_CARGO
	research_icon_state = "mining-plating"

/datum/design/mod_plating/medical
	name = "MOD Medical Plating"
	id = "mod_plating_medical"
	build_path = /obj/item/mod/construction/armor/medical
	materials = list(/datum/material/iron = 6000, /datum/material/silver = 2000, /datum/material/glass = 1000, /datum/material/plasma = 1000)
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL
	research_icon_state = "medical-plating"

/datum/design/mod_plating/security
	name = "MOD Security Plating"
	id = "mod_plating_security"
	build_path = /obj/item/mod/construction/armor/security
	materials = list(/datum/material/iron = 6000, /datum/material/uranium = 2000, /datum/material/glass = 1000, /datum/material/plasma = 1000)
	departmental_flags = DEPARTMENTAL_FLAG_SECURITY
	research_icon_state = "security-plating"

/datum/design/mod_plating/cosmohonk
	name = "MOD Cosmohonk Plating"
	id = "mod_plating_cosmohonk"
	build_path = /obj/item/mod/construction/armor/cosmohonk
	materials = list(/datum/material/iron = 6000, /datum/material/bananium = 2000, /datum/material/glass = 1000, /datum/material/plasma = 1000)
	departmental_flags = DEPARTMENTAL_FLAG_SERVICE
	research_icon_state = "cosmohonk-plating"

/datum/design/mod_plating/cargo_worker
	name = "MOD Cargo Plating"
	id = "mod_plating_cargo_worker"
	build_path = /obj/item/mod/construction/armor/cargo_worker
	materials = list(/datum/material/iron = 6000, /datum/material/titanium = 2000, /datum/material/glass = 1000, /datum/material/plasma = 1000)
	departmental_flags = DEPARTMENTAL_FLAG_CARGO
	research_icon_state = "loader-plating"

/datum/design/mod_paint_kit
	name = "MOD Paint Kit"
	desc = "A paint kit for Modular Suits."
	id = "mod_paint_kit"
	build_type = MECHFAB
	materials = list(/datum/material/iron = 1000, /datum/material/plastic = 500)
	construction_time = 5 SECONDS
	build_path = /obj/item/mod/paint
	category = list("MODsuit Modules", "MODsuit Designs")

//MODsuit modules

/datum/design/module
	name = "MOD Module"
	build_type = PROTOLATHE | MECHFAB
	construction_time = 1 SECONDS
	materials = list(/datum/material/iron = 1000, /datum/material/glass = 1000)
	build_path = /obj/item/mod/module
	category = list("MODsuit Modules", "MODsuit Designs")
	departmental_flags = DEPARTMENTAL_FLAG_ALL

/datum/design/module/New()
	. = ..()
	var/obj/item/mod/module/module = build_path
	desc = "[initial(module.desc)] It uses [initial(module.complexity)] complexity."

/datum/design/module/mod_longfall
	name = "Longfall Module"
	id = "mod_longfall"
	materials = list(/datum/material/iron = 1000)
	build_path = /obj/item/mod/module/longfall

/datum/design/module/mod_storage
	name = "Storage Module"
	id = "mod_storage"
	materials = list(/datum/material/iron = 2500, /datum/material/glass = 500)
	build_path = /obj/item/mod/module/storage

/datum/design/module/mod_storage/extended
	name = "Extended Storage Module"
	id = "mod_storage_extended"
	construction_time = 5 SECONDS
	materials = list(/datum/material/iron = 15000, /datum/material/glass = 500, /datum/material/silver = 1000, /datum/material/diamond = 100)
	build_path = /obj/item/mod/module/storage/extended

/datum/design/module/mod_armor
	name = "MOD Armor module"
	id = "mod_armor"
	construction_time = 5 SECONDS
	materials = list(/datum/material/iron = 15000, /datum/material/glass = 500, /datum/material/titanium = 1000, /datum/material/diamond = 100)
	build_path = /obj/item/mod/module/armor

/datum/design/module/pai_module
	name = "PAI module connector"
	id = "pai_module"
	materials = list(/datum/material/iron = 2500, /datum/material/glass = 500)
	build_path = /obj/item/mod/module/pai

/datum/design/module/harness
	name = "MOD harness system"
	id = "mod_harness_system"
	construction_time = 10 SECONDS
	materials = list(/datum/material/iron = 15000, /datum/material/silver = 5000, /datum/material/diamond = 15000)
	build_path = /obj/item/mod/module/backpack_harness
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

/datum/design/module/mod_visor_medhud
	name = "Medical Visor Module"
	id = "mod_visor_medhud"
	materials = list(/datum/material/silver = 500, /datum/material/glass = 1000)
	build_path = /obj/item/mod/module/visor/medhud
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL

/datum/design/module/mod_visor_diaghud
	name = "Diagnostic Visor Module"
	id = "mod_visor_diaghud"
	materials = list(/datum/material/gold = 500, /datum/material/glass = 1000)
	build_path = /obj/item/mod/module/visor/diaghud
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

/datum/design/module/mod_visor_sechud
	name = "Security Visor Module"
	id = "mod_visor_sechud"
	materials = list(/datum/material/titanium = 500, /datum/material/glass = 1000)
	build_path = /obj/item/mod/module/visor/sechud
	departmental_flags = DEPARTMENTAL_FLAG_SECURITY

/datum/design/module/mod_visor_meson
	name = "Meson Visor Module"
	id = "mod_visor_meson"
	materials = list(/datum/material/uranium = 500, /datum/material/glass = 1000)
	build_path = /obj/item/mod/module/visor/meson
	departmental_flags = DEPARTMENTAL_FLAG_ENGINEERING

/datum/design/module/mod_visor_welding
	name = "Welding Protection Module"
	id = "mod_welding"
	materials = list(/datum/material/iron = 500, /datum/material/glass = 1000)
	build_path = /obj/item/mod/module/welding
	departmental_flags = DEPARTMENTAL_FLAG_ENGINEERING

/datum/design/module/mod_t_ray
	name = "T-Ray Scanner Module"
	id = "mod_t_ray"
	materials = list(/datum/material/iron = 500, /datum/material/glass = 1000)
	build_path = /obj/item/mod/module/t_ray
	departmental_flags = DEPARTMENTAL_FLAG_ENGINEERING

/datum/design/module/mod_health_analyzer
	name = "Health Analyzer Module"
	id = "mod_health_analyzer"
	materials = list(/datum/material/iron = 500, /datum/material/glass = 1000)
	build_path = /obj/item/mod/module/health_analyzer
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL

/datum/design/module/mod_stealth
	name = "Cloak Module"
	id = "mod_stealth"
	materials = list(/datum/material/iron = 1000, /datum/material/bluespace = 500)
	build_path = /obj/item/mod/module/stealth
	departmental_flags = DEPARTMENTAL_FLAG_SECURITY

/datum/design/module/mod_jetpack
	name = "Ion Jetpack Module"
	id = "mod_jetpack"
	materials = list(/datum/material/iron = 1500, /datum/material/plasma = 1000)
	build_path = /obj/item/mod/module/jetpack
	departmental_flags = DEPARTMENTAL_FLAG_ENGINEERING

/datum/design/module/advanced_mod_jetpack
	name = "Advanced Ion Jetpack Module"
	id = "adv_mod_jet"
	materials = list(/datum/material/iron = 5000, /datum/material/plasma = 3500, /datum/material/plastic = 1000)
	build_path = /obj/item/mod/module/jetpack/advanced
	departmental_flags = DEPARTMENTAL_FLAG_ENGINEERING

/datum/design/module/mod_magboot
	name = "Magnetic Stabilizator Module"
	id = "mod_magboot"
	materials = list(/datum/material/iron = 1000, /datum/material/gold = 500)
	build_path = /obj/item/mod/module/magboot
	departmental_flags = DEPARTMENTAL_FLAG_ENGINEERING

/datum/design/module/mod_mag_harness
	name = "Magnetic Harness Module"
	id = "mod_mag_harness"
	materials = list(/datum/material/iron = 1500, /datum/material/silver = 500)
	build_path = /obj/item/mod/module/magnetic_harness
	departmental_flags = DEPARTMENTAL_FLAG_SECURITY

/datum/design/module/mod_tether
	name = "Emergency Tether Module"
	id = "mod_tether"
	materials = list(/datum/material/iron = 1000, /datum/material/silver = 500)
	build_path = /obj/item/mod/module/tether
	departmental_flags = DEPARTMENTAL_FLAG_ENGINEERING

/datum/design/module/mod_mouthhole
	name = "Eating Apparatus Module"
	id = "mod_mouthhole"
	materials = list(/datum/material/iron = 1500)
	build_path = /obj/item/mod/module/mouthhole

/datum/design/module/mod_rad_protection
	name = "Radiation Protection Module"
	id = "mod_rad_protection"
	materials = list(/datum/material/iron = 1000, /datum/material/uranium = 1000)
	build_path = /obj/item/mod/module/rad_protection
	departmental_flags = DEPARTMENTAL_FLAG_ENGINEERING

/datum/design/module/mod_emp_shield
	name = "EMP Shield Module"
	id = "mod_emp_shield"
	materials = list(/datum/material/iron = 1000, /datum/material/plasma = 1000)
	build_path = /obj/item/mod/module/emp_shield
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

/datum/design/module/mod_flashlight
	name = "Flashlight Module"
	id = "mod_flashlight"
	materials = list(/datum/material/iron = 500, /datum/material/glass = 1000)
	build_path = /obj/item/mod/module/flashlight

/datum/design/module/mod_reagent_scanner
	name = "Reagent Scanner Module"
	id = "mod_reagent_scanner"
	materials = list(/datum/material/glass = 1000)
	build_path = /obj/item/mod/module/reagent_scanner
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL | DEPARTMENTAL_FLAG_SCIENCE

/datum/design/module/mod_gps
	name = "Internal GPS Module"
	id = "mod_gps"
	materials = list(/datum/material/iron = 500, /datum/material/glass = 500)
	build_path = /obj/item/mod/module/gps
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE | DEPARTMENTAL_FLAG_ENGINEERING | DEPARTMENTAL_FLAG_CARGO

/datum/design/module/mod_constructor
	name = "Fast Build and Blueprints Module"
	id = "mod_constructor"
	materials = list(/datum/material/iron = 1000, /datum/material/titanium = 500)
	build_path = /obj/item/mod/module/constructor/lesser
	departmental_flags = DEPARTMENTAL_FLAG_ENGINEERING

/datum/design/module/mod_quick_carry
	name = "Quick Carry Module"
	id = "mod_quick_carry"
	materials = list(/datum/material/iron = 1000, /datum/material/titanium = 500)
	build_path = /obj/item/mod/module/quick_carry
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL

/datum/design/module/mod_bikehorn
	name = "Bike Horn Module"
	id = "mod_bikehorn"
	materials = list(/datum/material/plastic = 500, /datum/material/iron = 500)
	build_path = /obj/item/mod/module/bikehorn
	departmental_flags = DEPARTMENTAL_FLAG_SERVICE

/datum/design/module/mod_microwave_beam
	name = "Microwave Beam Module"
	id = "mod_microwave_beam"
	materials = list(/datum/material/iron = 1000, /datum/material/uranium = 500)
	build_path = /obj/item/mod/module/microwave_beam
	departmental_flags = DEPARTMENTAL_FLAG_SERVICE

/datum/design/module/mod_clamp
	name = "Crate Clamp Module"
	id = "mod_clamp"
	materials = list(/datum/material/iron = 2000)
	build_path = /obj/item/mod/module/clamp
	departmental_flags = DEPARTMENTAL_FLAG_CARGO

/datum/design/module/mod_drill
	name = "Drill Module"
	id = "mod_drill"
	materials = list(/datum/material/silver = 1000, /datum/material/iron = 2000)
	build_path = /obj/item/mod/module/drill
	departmental_flags = DEPARTMENTAL_FLAG_CARGO

/datum/design/module/mod_loader_clamp
	name = "Loader Clamp Module"
	id = "mod_loader_clamp"
	build_path = /obj/item/mod/module/clamp/loader
	departmental_flags = DEPARTMENTAL_FLAG_CARGO

/datum/design/module/mod_magnet
	name = "Magnet Module"
	id = "mod_magnet"
	build_path = /obj/item/mod/module/magnet
	departmental_flags = DEPARTMENTAL_FLAG_CARGO

/datum/design/module/mod_selfcleaner
	name = "Self-cleaning Module"
	id = "mod_selfcleaner"
	build_path = /obj/item/mod/module/selfcleaner
	departmental_flags = DEPARTMENTAL_FLAG_SERVICE

/datum/design/module/mod_orebag
	name = "Ore Bag Module"
	id = "mod_orebag"
	materials = list(/datum/material/iron = 1500)
	build_path = /obj/item/mod/module/orebag
	departmental_flags = DEPARTMENTAL_FLAG_CARGO

/datum/design/module/mod_dna_lock
	name = "DNA Lock Module"
	id = "mod_dna_lock"
	materials = list(/datum/material/diamond = 500, /datum/material/glass = 1000)
	build_path = /obj/item/mod/module/dna_lock

/datum/design/module/mister_atmos
	name = "Resin Mister Module"
	id = "mod_mister_atmos"
	materials = list(/datum/material/glass = 1000, /datum/material/titanium = 1500)
	build_path = /obj/item/mod/module/mister/atmos
	departmental_flags = DEPARTMENTAL_FLAG_ENGINEERING

/datum/design/module/mod_holster
	name = "Holster Module"
	id = "mod_holster"
	materials = list(/datum/material/iron = 1500, /datum/material/glass = 500)
	build_path = /obj/item/mod/module/holster
	departmental_flags = DEPARTMENTAL_FLAG_SECURITY

/datum/design/module/on_stational_shield
	name = "LEEXP VER-I EnergyShield Module"
	id = "mod_energy_shield"
	materials = list(/datum/material/iron = 2500, /datum/material/glass = 2000, /datum/material/uranium = 2000)
	build_path = /obj/item/mod/module/energy_shield
	departmental_flags = DEPARTMENTAL_FLAG_SECURITY

/datum/design/module/surgicalprocessor
	name = "Surgical Processor Module"
	id = "mod_surgicalprocessor"
	materials = list(/datum/material/titanium = 250, /datum/material/glass = 1000, /datum/material/silver = 1500)
	build_path = /obj/item/mod/module/surgical_processor
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL

/datum/design/module/defibrillator
	name = "Defibrillator Module"
	id = "mod_defib"
	materials = list(/datum/material/titanium = 250, /datum/material/diamond = 1000, /datum/material/silver = 1500)
	build_path = /obj/item/mod/module/defibrillator
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL

//MODsuit anomalock modules
/datum/design/module/mod_antigrav
	name = "Anti-Gravity Module"
	id = "mod_antigrav"
	materials = list(/datum/material/iron = 2500, /datum/material/glass = 2000, /datum/material/uranium = 2000)
	build_path = /obj/item/mod/module/anomaly_locked/antigrav
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

/datum/design/module/mod_teleporter
	name = "Teleporter Module"
	id = "mod_teleporter"
	materials = list(/datum/material/iron = 2500, /datum/material/glass = 2000, /datum/material/bluespace = 2000)
	build_path = /obj/item/mod/module/anomaly_locked/teleporter
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

// BLUEMOON ADD START - новые (старые) модули для модсьюта
/datum/design/module/mod_advanced_springlock
	name = "Electronic exoskeleton module"
	id = "mod_springlock_advanced"
	materials = list(/datum/material/iron = 9500, /datum/material/titanium = 4000, /datum/material/glass = 2000, /datum/material/bluespace = 1000)
	build_path = /obj/item/mod/module/springlock/advanced
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

/datum/design/module/mod_advanced_emp_shield
	name = "Advanced EMP shield module"
	id = "mod_emp_shield_advanced"
	materials = list(/datum/material/iron = 1500, /datum/material/uranium = 2000, /datum/material/diamond = 2000, /datum/material/bluespace = 2000)
	build_path = /obj/item/mod/module/emp_shield/advanced
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

/datum/design/module/power_plasma
	name = "MOD Plasma powergen Module"
	id = "mod_plasmagen"
	build_path = /obj/item/mod/module/power/plasma
	materials = list(/datum/material/glass = 1000, /datum/material/titanium = 1500)
	departmental_flags = DEPARTMENTAL_FLAG_CARGO

/datum/design/module/power_uranium
	name = "MOD Uranium powergen Module"
	id = "mod_urangen"
	build_path = /obj/item/mod/module/power/uranium
	materials = list(/datum/material/glass = 1000, /datum/material/titanium = 1500)
	departmental_flags = DEPARTMENTAL_FLAG_ENGINEERING

/datum/design/module/power_diamond
	name = "MOD Diamond powergen Module"
	id = "mod_diamondgen"
	build_path = /obj/item/mod/module/power/diamond
	materials = list(/datum/material/glass = 1000, /datum/material/titanium = 1500)
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

/datum/design/module/power_bananium
	name = "MOD Bananium powergen Module"
	id = "mod_bananagen"
	build_path = /obj/item/mod/module/power/bananium
	materials = list(/datum/material/glass = 1000, /datum/material/titanium = 1500)
	departmental_flags = DEPARTMENTAL_FLAG_SERVICE

/datum/design/module/power_tesla
	name = "MOD Tesla powergen Module"
	id = "mod_teslagen"
	build_path = /obj/item/mod/module/power/tesla
	materials = list(/datum/material/titanium = 250, /datum/material/glass = 1000, /datum/material/silver = 1500)
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

// BLUEMOON ADD END

/datum/design/modlink_scryer
	name = "MODlink Scryer"
	desc = "Носимый голографический терминал MODlink."
	id = "modlink_scryer"
	build_type = PROTOLATHE | MECHFAB
	materials = list(/datum/material/iron = 1000, /datum/material/glass = 1000)
	construction_time = 1 SECONDS
	build_path = /obj/item/clothing/neck/link_scryer/loaded
	category = list("MODsuit Modules", "MODsuit Designs")
	departmental_flags = DEPARTMENTAL_FLAG_ALL

/datum/design/module/mod_thermal_regulator
	name = "Thermal Regulator Module"
	id = "mod_thermal_regulator"
	materials = list(/datum/material/iron = 500, /datum/material/glass = 1000)
	build_path = /obj/item/mod/module/thermal_regulator

/datum/design/module/mod_injector
	name = "Injector Module"
	id = "mod_injector"
	materials = list(/datum/material/iron = 1000, /datum/material/diamond = 500)
	build_path = /obj/item/mod/module/injector
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL

/datum/design/module/mod_glove_translator
	name = "Glove Translator Module"
	id = "mod_sign_radio"
	materials = list(/datum/material/iron = 750, /datum/material/glass = 500)
	build_path = /obj/item/mod/module/signlang_radio

/datum/design/module/joint_torsion
	name = "Joint Torsion Ratchet Module"
	id = "mod_joint_torsion"
	materials = list(/datum/material/iron = 1000, /datum/material/gold = 250, /datum/material/titanium = 100)
	build_path = /obj/item/mod/module/joint_torsion

/datum/design/module/statusreadout
	name = "Status Readout Module"
	id = "mod_statusreadout"
	materials = list(/datum/material/iron = 750, /datum/material/glass = 500, /datum/material/titanium = 250)
	build_path = /obj/item/mod/module/status_readout
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL

/datum/design/module/mod_head_protection
	name = "Safety-First Head Protection Module"
	id = "mod_safety"
	materials = list(/datum/material/iron = 1000, /datum/material/glass = 1000)
	build_path = /obj/item/mod/module/headprotector

/datum/design/module/mod_plasma_stabilizer
	name = "Plasma Stabilizer Module"
	id = "mod_plasma"
	materials = list(/datum/material/plasma = 1000, /datum/material/glass = 1000)
	build_path = /obj/item/mod/module/plasma_stabilizer

/datum/design/module/mod_organizer
	name = "Organizer Module"
	id = "mod_organizer"
	materials = list(/datum/material/iron = 1000, /datum/material/glass = 1000)
	build_path = /obj/item/mod/module/organizer
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL

/datum/design/module/threadripper
	name = "Thread Ripper Module"
	id = "mod_threadripper"
	materials = list(/datum/material/titanium = 500, /datum/material/plastic = 1000, /datum/material/silver = 1500)
	build_path = /obj/item/mod/module/thread_ripper
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL

/datum/design/module/disposal
	name = "Disposal Connector Module"
	id = "mod_disposal"
	materials = list(/datum/material/iron = 2500, /datum/material/titanium = 1000)
	build_path = /obj/item/mod/module/disposal_connector

/datum/design/module/recycler
	name = "Recycler Module"
	id = "mod_recycler"
	materials = list(/datum/material/iron = MINERAL_MATERIAL_AMOUNT, /datum/material/glass = 1000, /datum/material/plastic = 400)
	build_path = /obj/item/mod/module/recycler

/datum/design/module/mod_waddle
	name = "Waddle Module"
	id = "mod_waddle"
	materials = list(/datum/material/plastic = 1000, /datum/material/iron = 1000)
	build_path = /obj/item/mod/module/waddle
	departmental_flags = DEPARTMENTAL_FLAG_SERVICE

/datum/design/module/mod_sonar
	name = "Active Sonar Module"
	id = "mod_sonar"
	materials = list(/datum/material/titanium = 250, /datum/material/glass = 1000, /datum/material/gold = 500, /datum/material/uranium = 250)
	build_path = /obj/item/mod/module/active_sonar
	departmental_flags = DEPARTMENTAL_FLAG_SECURITY

/datum/design/module/patienttransport
	name = "Patient Transport Module"
	id = "mod_patienttransport"
	materials = list(/datum/material/iron = 1000, /datum/material/bluespace = 1000)
	build_path = /obj/item/mod/module/criminalcapture/patienttransport
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL

/datum/design/module/criminalcapture
	name = "Criminal Capture Module"
	id = "mod_criminalcapture"
	materials = list(/datum/material/iron = 1000, /datum/material/bluespace = 1000)
	build_path = /obj/item/mod/module/criminalcapture
	departmental_flags = DEPARTMENTAL_FLAG_SECURITY

/datum/design/module/projectile_dampener
	name = "Projectile Dampener Module"
	id = "mod_projectile_dampener"
	materials = list(/datum/material/iron = 1000, /datum/material/bluespace = 500)
	build_path = /obj/item/mod/module/projectile_dampener
	departmental_flags = DEPARTMENTAL_FLAG_SECURITY

/datum/design/module/mister_janitor
	name = "Cleaning Mister Module"
	id = "mod_mister_janitor"
	materials = list(/datum/material/glass = 1000, /datum/material/titanium = 1000)
	build_path = /obj/item/mod/module/mister/cleaner
	departmental_flags = DEPARTMENTAL_FLAG_SERVICE

/datum/design/module/shooting_assistant
	name = "Shooting Assistant Module"
	id = "mod_shooting"
	materials = list(/datum/material/iron = 2000, /datum/material/silver = 200, /datum/material/gold = 100, /datum/material/diamond = 100)
	build_path = /obj/item/mod/module/shooting_assistant
	departmental_flags = DEPARTMENTAL_FLAG_SECURITY

/datum/design/module/pathfinder
	name = "Pathfinder Module"
	id = "mod_pathfinder"
	materials = list(/datum/material/uranium = MINERAL_MATERIAL_AMOUNT / 2, /datum/material/iron = MINERAL_MATERIAL_AMOUNT / 2)
	build_path = /obj/item/mod/module/pathfinder
	departmental_flags = DEPARTMENTAL_FLAG_SECURITY

/datum/design/module/mind_transfer
	name = "Mind Transference Module"
	id = "mod_mind_transfer"
	materials = list(/datum/material/iron = HALF_SHEET_MATERIAL_AMOUNT, /datum/material/diamond = SMALL_MATERIAL_AMOUNT * 5)
	build_path = /obj/item/mod/module/mind_swap

/datum/design/module/circuit
	name = "MOD Circuit Adapter Module"
	id = "mod_circuit_adapter"
	materials = list(/datum/material/glass = SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/mod/module/circuit

/datum/design/module/mirage
	name = "Mirage Grenade Dispenser Module"
	id = "mod_mirage_grenade"
	materials = list(/datum/material/iron = MINERAL_MATERIAL_AMOUNT / 2, /datum/material/bluespace = MINERAL_MATERIAL_AMOUNT / 2)
	build_path = /obj/item/mod/module/dispenser/mirage
	departmental_flags = DEPARTMENTAL_FLAG_SECURITY

/datum/design/module/mod_kinesis
	name = "Kinesis Module"
	id = "mod_kinesis"
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 1.25, /datum/material/glass = SHEET_MATERIAL_AMOUNT, /datum/material/uranium = HALF_SHEET_MATERIAL_AMOUNT, /datum/material/bluespace = HALF_SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/mod/module/anomaly_locked/kinesis
	departmental_flags = DEPARTMENTAL_FLAG_ENGINEERING
