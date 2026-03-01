/////////////////////////////////////////
////////////Medical Tools////////////////
/////////////////////////////////////////

/datum/design/mmi
	name = "Man-Machine Interface"
	desc = "The Warrior's bland acronym, MMI, obscures the true horror of this monstrosity."
	id = "mmi"
	build_type = PROTOLATHE | MECHFAB
	materials = list(/datum/material/iron = 1000, /datum/material/glass = 500)
	construction_time = 75
	build_path = /obj/item/mmi
	category = list("Misc","Medical Designs")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL | DEPARTMENTAL_FLAG_SCIENCE

/datum/design/posibrain
	name = "Positronic Brain"
	desc = "The latest in Artificial Intelligences."
	id = "mmi_posi"
	build_type = PROTOLATHE | MECHFAB
	materials = list(/datum/material/iron = 1700, /datum/material/glass = 1350, /datum/material/gold = 500) //Gold, because SWAG.
	construction_time = 75
	build_path = /obj/item/mmi/posibrain
	category = list("Misc", "Medical Designs")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL | DEPARTMENTAL_FLAG_SCIENCE

/datum/design/bluespacebeaker
	name = "Bluespace Beaker"
	desc = "A bluespace beaker, powered by experimental bluespace technology and Element Cuban combined with the Compound Pete. Can hold up to 300 units."
	id = "bluespacebeaker"
	build_type = PROTOLATHE
	materials = list(/datum/material/glass = 3000, /datum/material/plasma = 3000, /datum/material/diamond = 250, /datum/material/bluespace = 250)
	build_path = /obj/item/reagent_containers/glass/beaker/bluespace
	category = list("Medical Designs")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL | DEPARTMENTAL_FLAG_SCIENCE | DEPARTMENTAL_FLAG_SERVICE | DEPARTMENTAL_FLAG_ENGINEERING

/datum/design/ultimatebeaker
	name = "Ultimate Beaker"
	desc = "An ultimate beaker, made by extrapolating on bluespace technology with dark matter combined. Can hold up to 900 units."
	id = "ultimatebeaker"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 3000,
					/datum/material/glass = 3000,
					/datum/material/plasma = 3000,
					/datum/material/diamond = 500,
					/datum/material/bluespace = 500)
	build_path = /obj/item/reagent_containers/glass/beaker/ultimate
	reagents_list = list(/datum/reagent/liquid_dark_matter = 10)
	category = list("Medical Designs")
	lathe_time_factor = 0.8
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL | DEPARTMENTAL_FLAG_SCIENCE | DEPARTMENTAL_FLAG_SERVICE

/datum/design/noreactbeaker
	name = "Cryostasis Beaker"
	desc = "A cryostasis beaker that allows for chemical storage without reactions. Can hold up to 50 units."
	id = "splitbeaker"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 3000)
	build_path = /obj/item/reagent_containers/glass/beaker/noreact
	category = list("Medical Designs")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL | DEPARTMENTAL_FLAG_SCIENCE

/datum/design/xlarge_beaker
	name = "X-large Beaker"
	id = "xlarge_beaker"
	build_type = PROTOLATHE
	materials = list(/datum/material/glass = 2500, /datum/material/plastic = 3000)
	build_path = /obj/item/reagent_containers/glass/beaker/plastic
	category = list("Medical Designs")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL | DEPARTMENTAL_FLAG_SCIENCE | DEPARTMENTAL_FLAG_ENGINEERING

/datum/design/meta_beaker
	name = "Metamaterial Beaker"
	id = "meta_beaker"
	build_type = PROTOLATHE
	materials = list(/datum/material/glass = 2500, /datum/material/plastic = 3000, /datum/material/gold = 1000, /datum/material/titanium = 1000)
	build_path = /obj/item/reagent_containers/glass/beaker/meta
	category = list("Medical Designs")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL | DEPARTMENTAL_FLAG_SCIENCE

/datum/design/bluespacesyringe
	name = "Bluespace Syringe"
	desc = "An advanced syringe that can hold 60 units of chemicals"
	id = "bluespacesyringe"
	build_type = PROTOLATHE
	materials = list(/datum/material/glass = 2000, /datum/material/plasma = 1000, /datum/material/diamond = 1000, /datum/material/bluespace = 500)
	build_path = /obj/item/reagent_containers/syringe/bluespace
	category = list("Medical Designs")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL | DEPARTMENTAL_FLAG_SCIENCE

/datum/design/noreactsyringe
	name = "Cryo Syringe"
	desc = "An advanced syringe that stops reagents inside from reacting. It can hold up to 20 units."
	id = "noreactsyringe"
	build_type = PROTOLATHE
	materials = list(/datum/material/glass = 2000, /datum/material/gold = 1000)
	build_path = /obj/item/reagent_containers/syringe/noreact
	category = list("Medical Designs")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL | DEPARTMENTAL_FLAG_SCIENCE

/datum/design/piercesyringe
	name = "Piercing Syringe"
	desc = "A diamond-tipped syringe that pierces armor when launched at high velocity. It can hold up to 10 units."
	id = "piercesyringe"
	build_type = PROTOLATHE
	materials = list(/datum/material/glass = 2000, /datum/material/diamond = 1000)
	build_path = /obj/item/reagent_containers/syringe/piercing
	category = list("Medical Designs")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL

/datum/design/medicinalsmartdart
	name = "Medicinal Smartdart"
	desc = "A non-harmful dart that can administer medication from a range. Once it hits a patient using its smart nanofilter technology, only medicines contained within the dart are administered to the patient. Additonally, due to capillary action, injection of chemicals past the overdose limit is prevented."
	id = "medicinalsmartdart"
	build_type = PROTOLATHE
	materials = list(/datum/material/glass = 100, /datum/material/plastic = 100, /datum/material/iron = 100)
	build_path = /obj/item/reagent_containers/syringe/dart
	category = list("Ammo")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL

/datum/design/bluespacesmartdart
	name = "bluespace smartdart"
	desc = "A non-harmful dart that can administer medication from a range. Once it hits a patient using it's smart nanofilter technology only medicines contained within the dart are administered to the patient. Additonally, due to capillary action, injection of chemicals past the overdose limit is prevented. Has an extended volume capacity thanks to bluespace foam."
	id = "bluespacesmartdart"
	build_type = PROTOLATHE
	materials = list(/datum/material/glass = 250, /datum/material/plastic = 250, /datum/material/iron = 250, /datum/material/bluespace = 250)
	build_path = /obj/item/reagent_containers/syringe/dart/bluespace
	category = list("Ammo")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL

/datum/design/smartdartgun
	name = "dart gun"
	desc = "A compressed air gun, designed to fit medicinal darts for application of medicine for those patients just out of reach."
	id = "smartdartgun"
	build_type = PROTOLATHE
	materials = list(/datum/material/glass = 500, /datum/material/plastic = 1000, /datum/material/iron = 500)
	build_path = /obj/item/gun/syringe/dart
	category = list("Weapons")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL

/datum/design/smartdartrepeater
	name = "Smartdart Repeater"
	desc = "An experimental smartdart rifle. It can make its own smart darts and is loaded with a hypovial."
	id = "smartdartrepeater"
	build_type = PROTOLATHE
	materials = list(/datum/material/glass = 2000, /datum/material/plastic = 1000, /datum/material/iron = 2000,/datum/material/titanium = 1000 )
	build_path = /obj/item/gun/chem/smart
	category = list("Weapons")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL

/datum/design/plasmarefiller
	name = "Plasma-Man Jumpsuit Refill"
	desc = "A refill pack for the auto-extinguisher on Plasma-man suits."
	id = "plasmarefiller" //Why did this have no plasmatech
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 4000, /datum/material/plasma = 1000)
	build_path = /obj/item/extinguisher_refill
	category = list("Equipment")
	departmental_flags = DEPARTMENTAL_FLAG_ALL

/datum/design/crewpinpointer
	name = "Crew Pinpointer"
	desc = "Allows tracking of someone's location if their suit sensors are turned to tracking beacon."
	id = "crewpinpointer"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 3000, /datum/material/glass = 1500, /datum/material/gold = 200)
	build_path = /obj/item/pinpointer/crew
	category = list("Equipment")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL

/datum/design/telescopiciv
	name = "Telescopic IV Drip"
	desc = "An IV drip with an advanced infusion pump that can both drain blood into and inject liquids from attached containers. Blood packs are processed at an accelerated rate. This one is telescopic, and can be picked up and put down."
	id = "telescopiciv"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 5000, /datum/material/glass = 3500, /datum/material/silver = 1000)
	build_path = /obj/item/tele_iv
	category = list("Medical Designs")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL

/datum/design/healthanalyzer_advanced
	name = "Advanced Health Analyzer"
	desc = "A hand-held body scanner able to distinguish vital signs of the subject with high accuracy."
	id = "healthanalyzer_advanced"
	build_path = /obj/item/healthanalyzer/advanced
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 5000, /datum/material/glass = 2500, /datum/material/silver = 2000, /datum/material/gold = 1500)
	category = list("Tool Designs")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL | DEPARTMENTAL_FLAG_SCIENCE

/datum/design/genescanner
	name = "Genetic Sequence Analyzer"
	desc = "A handy hand-held analyzers for quickly determining mutations and collecting the full sequence."
	id = "genescanner"
	build_path = /obj/item/sequence_scanner
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 1000, /datum/material/glass = 500)
	category = list("Tool Designs")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL | DEPARTMENTAL_FLAG_SCIENCE

/datum/design/sensor_device
	name = "Handheld Crew Monitor"
	desc = "A miniature machine that tracks suit sensors across the station."
	id = "sensor_device"
	build_path = /obj/item/sensor_device
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 10000, /datum/material/glass = 5000, /datum/material/silver = 5000, /datum/material/gold = 3000)
	category = list("Equipment")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL

/datum/design/medspray
	name = "Medical Spray"
	desc = "A medical spray bottle, designed for precision application, with an unscrewable cap."
	id = "medspray"
	build_path = /obj/item/reagent_containers/medspray
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 2500, /datum/material/glass = 500)
	category = list("Medical Designs")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL

/datum/design/medicalkit
	name = "Empty Medkit"
	desc = "A plastic medical kit for storging medical items."
	id = "medicalkit"
	build_type = PROTOLATHE
	materials = list(/datum/material/plastic = 5000)
	build_path = /obj/item/storage/firstaid //So we dont spawn medical items in it
	category = list("Equipment")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL | DEPARTMENTAL_FLAG_SCIENCE

/datum/design/syrgerytools
	name = "Surgical tools case"
	desc = "A large plastic case for holding surgical tools or most other medical supplies you could imagine."
	id = "surgicalcase"
	build_type = PROTOLATHE
	materials = list(/datum/material/plastic = 15000)
	build_path = /obj/item/storage/backpack/duffelbag/med/surgery_empty //So we dont spawn medical items in it
	category = list("Equipment")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL

/datum/design/hypospraykit
	name = "Empty Hypospray Kit"
	desc = "A plastic medical kit for storing hyposprays and hypospray accessories."
	id = "hypokit"
	build_type = PROTOLATHE
	materials = list(/datum/material/plastic = 5000)
	build_path = /obj/item/storage/hypospraykit // let's not summon new hyposprays thanks
	category = list("Equipment")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL | DEPARTMENTAL_FLAG_SCIENCE

/datum/design/hypospray_mkii
	name = "Hypospray Mk. II"
	id = "hypospray_mkii"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 1600, /datum/material/glass = 1000)
	build_path = /obj/item/hypospray/mkii
	category = list("Tool Designs")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL

/datum/design/nanogel
	name = "Nanogel paste"
	id = "nanogel"
	build_type = PROTOLATHE | MECHFAB
	materials = list(/datum/material/iron = 800, /datum/material/titanium = 500, /datum/material/gold = 100, /datum/material/diamond = 20)
	build_path = /obj/item/stack/medical/nanogel/one
	category = list("Misc", "Medical Designs")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL | DEPARTMENTAL_FLAG_SCIENCE

/datum/design/blood_bag
	name = "Empty Blood Bag"
	desc = "A small sterilized plastic bag for blood."
	id = "blood_bag"
	build_path = /obj/item/reagent_containers/blood
	build_type = PROTOLATHE
	materials = list(/datum/material/glass = 1500, /datum/material/plastic = 3500)
	category = list("Medical Designs")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL

/datum/design/bsblood_bag
	name = "Empty Bluespace Blood Bag"
	desc = "A large sterilized plastic bag for blood."
	id = "bsblood_bag"
	build_path = /obj/item/reagent_containers/blood/bluespace
	build_type = PROTOLATHE
	materials = list(/datum/material/glass = 2500, /datum/material/plastic = 4500, /datum/material/bluespace = 250)
	category = list("Medical Designs")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL

/datum/design/chem_pack
	name = "Intravenous Medicine Bag"
	desc = "A plastic pressure bag for IV administration of drugs."
	id = "chem_pack"
	build_type = PROTOLATHE
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL
	materials = list(/datum/material/plastic = 1500)
	build_path = /obj/item/reagent_containers/chem_pack
	category = list("Medical Designs")

/datum/design/cloning_disk
	name = "Cloning Data Disk"
	desc = "Produce additional disks for storing genetic data."
	id = "cloning_disk"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 300, /datum/material/glass = 100, /datum/material/silver=50)
	build_path = /obj/item/disk/data
	category = list("Electronics")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL | DEPARTMENTAL_FLAG_SCIENCE

/datum/design/organbox
	name = "Empty Organ Box"
	desc = "A large cool box that can hold large amouts of medical tools or organs."
	id = "organbox"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 3000, /datum/material/glass = 1000, /datum/material/silver= 3500, /datum/material/gold = 3500, /datum/material/plastic = 5000)
	build_path = /obj/item/storage/belt/organbox
	category = list("Medical Designs")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL | DEPARTMENTAL_FLAG_SCIENCE

/datum/design/holobarrier_med
	name = "PENLITE holobarrier projector"
	desc = "PENLITE holobarriers, a device that halts individuals with malicious diseases."
	build_type = PROTOLATHE
	build_path = /obj/item/holosign_creator/medical
	materials = list(/datum/material/iron = 500, /datum/material/glass = 500, /datum/material/silver = 100) //a hint of silver since it can troll 2 antags (bad viros and sentient disease)
	id = "holobarrier_med"
	category = list("Equipment")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL

////////////////////////////////////////
//////////Body Bags/////////////////////
////////////////////////////////////////

/datum/design/bodybag
	name = "Body Bag"
	desc = "A normal body bag used for storage of dead crew."
	id = "bodybag"
	build_type = PROTOLATHE
	materials = list(/datum/material/plastic = 4000)
	build_path = /obj/item/bodybag
	category = list("Medical Designs")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL | DEPARTMENTAL_FLAG_SCIENCE

/datum/design/bluespacebodybag
	name = "Bluespace Body Bag"
	desc = "A bluespace body bag, powered by experimental bluespace technology. It can hold loads of bodies and the largest of creatures."
	id = "bluespacebodybag"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 3000, /datum/material/plasma = 2000, /datum/material/diamond = 500, /datum/material/bluespace = 500)
	build_path = /obj/item/bodybag/bluespace
	category = list("Medical Designs")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL | DEPARTMENTAL_FLAG_SCIENCE

/datum/design/containmentbodybag
	name = "Containment Body Bag"
	desc = "A containment body bag, heavy and radiation proof."
	id = "containmentbodybag"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 6000, /datum/material/plastic = 4000, /datum/material/titanium = 2000)
	build_path = /obj/item/bodybag/containment
	category = list("Medical Designs")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL | DEPARTMENTAL_FLAG_SCIENCE | DEPARTMENTAL_FLAG_ENGINEERING

////////////////////////////////////////
//////////Defibrillator Tech////////////
////////////////////////////////////////

/datum/design/defibrillator
	name = "Defibrillator"
	desc = "A portable defibrillator, used for resuscitating recently deceased crew."
	id = "defibrillator"
	build_type = PROTOLATHE
	build_path = /obj/item/defibrillator
	materials = list(/datum/material/iron = 8000, /datum/material/glass = 4000, /datum/material/silver = 3000, /datum/material/gold = 1500)
	category = list("Equipment")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL

/datum/design/defibrillator_mount
	name = "Defibrillator Wall Mount"
	desc = "An all-in-one mounted frame for holding defibrillators, complete with ID-locked clamps and recharging cables."
	id = "defibmount"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 2000, /datum/material/glass = 1000)
	build_path = /obj/item/wallframe/defib_mount
	category = list("Equipment")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL

/datum/design/defib_heal
	name = "Defibrillator Healing disk"
	desc = "An upgrade which increases the healing power of the defibrillator."
	id = "defib_heal"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 16000, /datum/material/glass = 18000, /datum/material/gold = 6000, /datum/material/silver = 6000)
	build_path = /obj/item/disk/medical/defib_heal
	construction_time = 10
	category = list("Equipment")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL

/datum/design/defib_shock
	name = "Defibrillator Anti-Shock Disk"
	desc = "A safety upgrade that guarantees only the patient will get shocked."
	id = "defib_shock"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 16000, /datum/material/glass = 18000, /datum/material/gold = 6000, /datum/material/silver = 6000)
	build_path = /obj/item/disk/medical/defib_shock
	construction_time = 10
	category = list("Equipment")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL

/datum/design/defib_decay
	name = "Defibrillator Body-Decay Extender Disk"
	desc = "An upgrade allowing the defibrillator to work on more decayed bodies."
	id = "defib_decay"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 16000, /datum/material/glass = 18000, /datum/material/gold = 16000, /datum/material/silver = 6000, /datum/material/titanium = 2000)
	build_path = /obj/item/disk/medical/defib_decay
	construction_time = 10
	category = list("Equipment")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL

/datum/design/defib_speed
	name = "Defibrillator Fast Charge Disk"
	desc = "An upgrade to the defibrillator's capacitors, which lets it charge faster."
	id = "defib_speed"
	build_type = PROTOLATHE
	build_path = /obj/item/disk/medical/defib_speed
	materials = list(/datum/material/iron = 16000, /datum/material/glass = 8000, /datum/material/gold = 26000, /datum/material/silver = 26000)
	construction_time = 10
	category = list("Equipment")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL

/datum/design/defibrillator_compact
	name = "Compact Defibrillator"
	desc = "A compact defibrillator that can be worn on a belt."
	id = "defibrillator_compact"
	build_type = PROTOLATHE
	build_path = /obj/item/defibrillator/compact
	materials = list(/datum/material/iron = 16000, /datum/material/glass = 8000, /datum/material/silver = 6000, /datum/material/gold = 3000)
	category = list("Equipment")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL

/datum/design/portable_chem_mixer
	name = "Portable Chemical Mixer"
	desc = "A portable device that dispenses and mixes chemicals. Reagents have to be supplied with beakers."
	id = "portable_chem_mixer"
	build_type = PROTOLATHE
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL
	materials = list(/datum/material/plastic = 5000, /datum/material/iron = 10000, /datum/material/glass = 3000)
	build_path = /obj/item/storage/portable_chem_mixer
	category = list("Equipment")

/////////////////////////////////////////
////////////     Plumbing      //////////
/////////////////////////////////////////

/datum/design/plumb_rcd
	name = "Plumbed Autoconstruction Device"
	desc = "A RCD for plumbing machines! Cannot make ducts."
	id = "plumb_rcd"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 20000, /datum/material/glass = 10000, /datum/material/plastic = 20000, /datum/material/titanium = 2000, /datum/material/diamond = 800, /datum/material/gold = 2000, /datum/material/silver = 2000)
	construction_time = 150
	build_path = /obj/item/construction/plumbing
	category = list("Misc","Equipment")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL | DEPARTMENTAL_FLAG_SERVICE

/datum/design/rplunger
    name = "Reinforced Plunger"
    desc = "A plunger designed for heavy duty clogs."
    id = "rplunger"
    build_type = PROTOLATHE
    materials = list(/datum/material/plasma = 1000, /datum/material/iron = 1000, /datum/material/glass = 1000)
    construction_time = 15
    build_path = /obj/item/plunger/reinforced
    category = list ("Misc","Equipment")
    departmental_flags = DEPARTMENTAL_FLAG_MEDICAL | DEPARTMENTAL_FLAG_CARGO | DEPARTMENTAL_FLAG_SERVICE

/datum/design/duct_print
	name = "Plumbing Ducts"
	desc = "Ducts for plumbing! Now lathed for efficiency."
	id = "duct_print"
	build_type = PROTOLATHE
	materials = list(/datum/material/plastic = 400)
	construction_time = 1
	build_path = /obj/item/stack/ducts
	category = list("Misc","Equipment")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL | DEPARTMENTAL_FLAG_SERVICE

// Накой фиг оно тут надо, если есть пламбер РЦД
/*
/datum/design/acclimator
	name = "Plumbing Acclimator"
	desc = "A heating and cooling device for pipes!"
	id = "acclimator"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 1000, /datum/material/glass = 500)
	construction_time = 15
	build_path = /obj/machinery/plumbing/acclimator
	category = list("Misc","Medical Designs")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL | DEPARTMENTAL_FLAG_SCIENCE

/datum/design/disposer
	name = "Plumbing Disposer"
	desc = "Using the power of Science, dissolves reagents into nothing (almost)."
	id = "disposer"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 500, /datum/material/glass = 100)
	construction_time = 15
	build_path = /obj/machinery/plumbing/disposer
	category = list("Misc","Medical Designs")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL | DEPARTMENTAL_FLAG_SCIENCE

/datum/design/plumb_filter
	name = "Plumbing Filter"
	desc = "Filters out chemicals by their NTDB ID."
	id = "plumb_filter"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 1000, /datum/material/glass = 500)
	construction_time = 15
	build_path = /obj/machinery/plumbing/filter
	category = list("Misc","Medical Designs")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL | DEPARTMENTAL_FLAG_SCIENCE

/datum/design/plumb_synth
	name = "Plumbing Synthesizer"
	desc = "Using standard mass-energy dynamic autoconverters, generates reagents from power and puts them in a pipe."
	id = "plumb_synth"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 5000, /datum/material/glass = 1000, /datum/material/plastic = 1000)
	construction_time = 15
	build_path = /obj/machinery/plumbing/synthesizer
	category = list("Misc","Medical Designs")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL | DEPARTMENTAL_FLAG_SCIENCE

/datum/design/plumb_grinder
	name = "Plumbing-Linked Autogrinder"
	desc = "Automatically extracts reagents from an item by grinding it. Think of the possibilities! Note: does not grind people."
	id = "plumb_grinder"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 2000, /datum/material/glass = 1500)
	construction_time = 15
	build_path = /obj/machinery/plumbing/grinder_chemical
	category = list("Misc","Medical Designs")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL | DEPARTMENTAL_FLAG_SCIENCE

/datum/design/reaction_chamber
	name = "Plumbing Reaction Chamber"
	desc = "You can set a list of allowed reagents and amounts. Once the chamber has these reagents, will let the products through."
	id = "reaction_chamber"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 1000, /datum/material/glass = 500)
	construction_time = 15
	build_path = /obj/machinery/plumbing/reaction_chamber
	category = list("Misc","Medical Designs")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL | DEPARTMENTAL_FLAG_SCIENCE

/datum/design/plumb_splitter
	name = "Plumbing Chemical Splitter"
	desc = "A splitter. Has 2 outputs. Can be configured to allow a certain amount through each side."
	id = "plumb_splitter"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 750, /datum/material/glass = 250)
	construction_time = 15
	build_path = /obj/machinery/plumbing/splitter
	category = list("Misc","Medical Designs")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL | DEPARTMENTAL_FLAG_SCIENCE

/datum/design/pill_press
	name = "Plumbing Automatic Pill Former"
	desc = "Automatically forms pills to the required parameters with piped reagents! A good replacement for those lazy, useless chemists."
	id = "pill_press"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 1000, /datum/material/glass = 500)
	construction_time = 15
	build_path = /obj/machinery/plumbing/pill_press
	category = list("Misc","Medical Designs")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL | DEPARTMENTAL_FLAG_SCIENCE

/datum/design/plumb_pump
	name = "Liquid Extraction Pump"
	desc = "Use it for extracting liquids from lavaland's geysers!"
	id = "plumb_pump"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 1000, /datum/material/glass = 500)
	construction_time = 15
	build_path = /obj/machinery/plumbing/liquid_pump
	category = list("Misc","Medical Designs")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL | DEPARTMENTAL_FLAG_SCIENCE

/datum/design/plumb_in
	name = "Plumbing Input Device"
	desc = "A big piped funnel for putting stuff in the pipe network."
	id = "plumb_in"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 400, /datum/material/glass = 400)
	construction_time = 15
	build_path = /obj/machinery/plumbing/input
	category = list("Misc","Medical Designs")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL | DEPARTMENTAL_FLAG_SCIENCE

/datum/design/plumb_out
	name = "Plumbing Output Device"
	desc = "A big piped funnel for taking stuff out of the pipe network."
	id = "plumb_out"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 400, /datum/material/glass = 400)
	construction_time = 15
	build_path = /obj/machinery/plumbing/output
	category = list("Misc","Medical Designs")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL | DEPARTMENTAL_FLAG_SCIENCE

/datum/design/plumb_tank
	name = "Plumbed Storage Tank"
	desc = "A tank for storing plumbed reagents."
	id = "plumb_tank"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 10000, /datum/material/glass = 10000, /datum/material/plastic = 4000)
	construction_time = 15
	build_path = /obj/machinery/plumbing/tank
	category = list("Misc","Medical Designs")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL | DEPARTMENTAL_FLAG_SCIENCE
*/
