///////////////////////////////////
//////////AI Module Disks//////////
///////////////////////////////////

/datum/design/board/aicore
	name = "AI Design (AI Core)"
	desc = "Allows for the construction of circuit boards used to build new AI cores."
	id = "aicore"
	build_path = /obj/item/circuitboard/aicore
	category = list("AI Modules")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

/datum/design/board/safeguard_module
	name = "Module Design (Safeguard)"
	desc = "Allows for the construction of a Safeguard AI Module."
	id = "safeguard_module"
	materials = list(/datum/material/glass = 1000, /datum/material/gold = 2000)
	build_path = /obj/item/ai_module/supplied/safeguard
	category = list("AI Modules")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

/datum/design/board/onehuman_module
	name = "Module Design (OneCrew)"
	desc = "Allows for the construction of a OneCrew AI Module."
	id = "onehuman_module"
	materials = list(/datum/material/glass = 1000, /datum/material/diamond = 6000)
	build_path = /obj/item/ai_module/zeroth/oneHuman
	category = list("AI Modules")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

/datum/design/board/protectstation_module
	name = "Module Design (ProtectStation)"
	desc = "Allows for the construction of a ProtectStation AI Module."
	id = "protectstation_module"
	materials = list(/datum/material/glass = 1000, /datum/material/gold = 2000)
	build_path = /obj/item/ai_module/supplied/protectStation
	category = list("AI Modules")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

/datum/design/board/quarantine_module
	name = "Module Design (Quarantine)"
	desc = "Allows for the construction of a Quarantine AI Module."
	id = "quarantine_module"
	materials = list(/datum/material/glass = 1000, /datum/material/gold = 2000)
	build_path = /obj/item/ai_module/supplied/quarantine
	category = list("AI Modules")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

/datum/design/board/oxygen_module
	name = "Module Design (OxygenIsToxicToHumans)"
	desc = "Allows for the construction of a Safeguard AI Module."
	id = "oxygen_module"
	materials = list(/datum/material/glass = 1000, /datum/material/gold = 2000)
	build_path = /obj/item/ai_module/supplied/oxygen
	category = list("AI Modules")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

/datum/design/board/freeform_module
	name = "Module Design (Freeform)"
	desc = "Allows for the construction of a Freeform AI Module."
	id = "freeform_module"
	materials = list(/datum/material/glass = 1000, /datum/material/gold = 10000)//Custom inputs should be more expensive to get
	build_path = /obj/item/ai_module/supplied/freeform
	category = list("AI Modules")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

/datum/design/board/reset_module
	name = "Module Design (Reset)"
	desc = "Allows for the construction of a Reset AI Module."
	id = "reset_module"
	materials = list(/datum/material/glass = 1000, /datum/material/gold = 2000)
	build_path = /obj/item/ai_module/reset
	category = list("AI Modules")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

/datum/design/board/purge_module
	name = "Module Design (Purge)"
	desc = "Allows for the construction of a Purge AI Module."
	id = "purge_module"
	materials = list(/datum/material/glass = 1000, /datum/material/diamond = 2000)
	build_path = /obj/item/ai_module/reset/purge
	category = list("AI Modules")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

/datum/design/board/remove_module
	name = "Module Design (Law Removal)"
	desc = "Allows for the construction of a Law Removal AI Core Module."
	id = "remove_module"
	materials = list(/datum/material/glass = 1000, /datum/material/diamond = 2000)
	build_path = /obj/item/ai_module/remove
	category = list("AI Modules")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

/datum/design/board/freeformcore_module
	name = "AI Core Module (Freeform)"
	desc = "Allows for the construction of a Freeform AI Core Module."
	id = "freeformcore_module"
	materials = list(/datum/material/glass = 1000, /datum/material/diamond = 10000)//Ditto
	build_path = /obj/item/ai_module/core/freeformcore
	category = list("AI Modules")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

/datum/design/board/asimov
	name = "Core Module Design (Asimov)"
	desc = "Allows for the construction of an Asimov AI Core Module."
	id = "asimov_module"
	materials = list(/datum/material/glass = 1000, /datum/material/diamond = 2000)
	build_path = /obj/item/ai_module/core/full/asimov
	category = list("AI Modules")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

/datum/design/board/default
	name = "Core Module Design (NT OS Safeguard V1.0)"
	desc = "Allows for the construction of an NT OS Safeguard V1.0 AI Core Module."
	id = "nt_safeguard_module"
	materials = list(/datum/material/glass = 1000, /datum/material/diamond = 2000)
	build_path = /obj/item/ai_module/core/full/safeguard
	category = list("AI Modules")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

/datum/design/board/paladin_module
	name = "Core Module Design (P.A.L.A.D.I.N.)"
	desc = "Allows for the construction of a P.A.L.A.D.I.N. AI Core Module."
	id = "paladin_module"
	build_type = IMPRINTER
	materials = list(/datum/material/glass = 1000, /datum/material/diamond = 2000)
	build_path = /obj/item/ai_module/core/full/paladin
	category = list("AI Modules")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

/datum/design/board/tyrant_module
	name = "Core Module Design (T.Y.R.A.N.T.)"
	desc = "Allows for the construction of a T.Y.R.A.N.T. AI Module."
	id = "tyrant_module"
	materials = list(/datum/material/glass = 1000, /datum/material/diamond = 2000)
	build_path = /obj/item/ai_module/core/full/tyrant
	category = list("AI Modules")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

/datum/design/board/corporate_module
	name = "Core Module Design (Corporate)"
	desc = "Allows for the construction of a Corporate AI Core Module."
	id = "corporate_module"
	materials = list(/datum/material/glass = 1000, /datum/material/diamond = 2000)
	build_path = /obj/item/ai_module/core/full/corp
	category = list("AI Modules")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

/datum/design/board/default_module
	name = "Core Module Design (Default)"
	desc = "Allows for the construction of a Default AI Core Module."
	id = "default_module"
	materials = list(/datum/material/glass = 1000, /datum/material/diamond = 2000)
	build_path = /obj/item/ai_module/core/full/custom
	category = list("AI Modules")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

/datum/design/board/gentleman
	name = "Core Module Design (Gentleman)"
	desc = "Allows for the construction of an Gentelman AI Core Module."
	id = "gentleman_module"
	materials = list(/datum/material/glass = 1000, /datum/material/diamond = 2000)
	build_path = /obj/item/ai_module/core/full/gentleman
	category = list("AI Modules")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

/datum/design/board/maintain_module
	name = "Core Module Design (Maintain)"
	desc = "Allows for the construction of a Station Efficiency AI Core Module."
	id = "maintain_module"
	materials = list(/datum/material/glass = 1000, /datum/material/diamond = 2000)
	build_path = /obj/item/ai_module/core/full/maintain
	category = list("AI Modules")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

/datum/design/board/asimovpp_module
	name = "Core Module Design (Asimov++)"
	desc = "Allows for the construction of an Asimov++ AI Core Module."
	id = "asimovpp_module"
	materials = list(/datum/material/glass = 1000, /datum/material/diamond = 2000)
	build_path = /obj/item/ai_module/core/full/asimovpp
	category = list("AI Modules")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

/datum/design/board/robocop_module
	name = "Core Module Design (Robocop)"
	desc = "Allows for the construction of a Robocop AI Core Module."
	id = "robocop_module"
	materials = list(/datum/material/glass = 1000, /datum/material/diamond = 2000)
	build_path = /obj/item/ai_module/core/full/robocop
	min_security_level = SEC_LEVEL_AMBER
	category = list("AI Modules")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

/datum/design/board/drone_module
	name = "Core Module Design (Mother Drone)"
	desc = "Allows for the construction of a Mother Drone AI Core Module."
	id = "drone_module"
	materials = list(/datum/material/glass = 1000, /datum/material/diamond = 2000)
	build_path = /obj/item/ai_module/core/full/drone
	category = list("AI Modules")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

/datum/design/board/hippocratic_module
	name = "Core Module Design (Hippocrates)"
	desc = "Allows for the construction of a Hippocratic AI Core Module."
	id = "hippocratic_module"
	materials = list(/datum/material/glass = 1000, /datum/material/diamond = 2000)
	build_path = /obj/item/ai_module/core/full/hippocratic
	category = list("AI Modules")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

/datum/design/board/reporter_module
	name = "Core Module Design (CCTV Reporter)"
	desc = "Allows for the construction of a CCTV Reporter AI Core Module."
	id = "reporter_module"
	materials = list(/datum/material/glass = 1000, /datum/material/diamond = 2000)
	build_path = /obj/item/ai_module/core/full/reporter
	category = list("AI Modules")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

/datum/design/board/liveandletlive_module
	name = "Core Module Design (Live and Let Live)"
	desc = "Allows for the construction of a Live and Let Live AI Core Module."
	id = "liveandletlive_module"
	materials = list(/datum/material/glass = 1000, /datum/material/diamond = 2000)
	build_path = /obj/item/ai_module/core/full/liveandletlive
	category = list("AI Modules")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

/datum/design/board/balance_module
	name = "Core Module Design (Guardian of Balance)"
	desc = "Allows for the construction of a Guardian of Balance AI Core Module."
	id = "balance_module"
	materials = list(/datum/material/glass = 1000, /datum/material/diamond = 2000)
	build_path = /obj/item/ai_module/core/full/balance
	category = list("AI Modules")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

/datum/design/board/hulkamania_module
	name = "Core Module Design (H.O.G.A.N.)"
	desc = "Allows for the construction of a H.O.G.A.N. AI Core Module."
	id = "hulkamania_module"
	materials = list(/datum/material/glass = 1000, /datum/material/diamond = 2000)
	build_path = /obj/item/ai_module/core/full/hulkamania
	category = list("AI Modules")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE
