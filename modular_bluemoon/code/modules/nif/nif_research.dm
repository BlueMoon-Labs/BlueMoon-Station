/datum/design/nifsoft_remover
	name = "Lopland 'Wrangler' NIF-Cutter"
	desc = "A small device that lets the user remove NIFSofts from a NIF user."
	id = "nifsoft_remover"
	build_type = PROTOLATHE
	build_path = /obj/item/nifsoft_remover
	materials = list(
		/datum/material/iron = SMALL_MATERIAL_AMOUNT,
		/datum/material/silver = HALF_SHEET_MATERIAL_AMOUNT,
		/datum/material/uranium = HALF_SHEET_MATERIAL_AMOUNT,
	)
	category = list("Tool Designs")
	departmental_flags = DEPARTMENTAL_FLAG_SECURITY

/datum/design/nifsoft_money_sense
	name = "Automatic Appraisal NIFSoft"
	desc = "A NIFSoft datadisk containing the Automatic Appraisal NIFsoft."
	id = "nifsoft_money_sense"
	build_type = PROTOLATHE
	build_path = /obj/item/disk/nifsoft_uploader/money_sense
	materials = list(
		/datum/material/iron = SHEET_MATERIAL_AMOUNT,
		/datum/material/silver = HALF_SHEET_MATERIAL_AMOUNT,
		/datum/material/plastic = SHEET_MATERIAL_AMOUNT,
	)
	category = list("Tool Designs")
	departmental_flags = DEPARTMENTAL_FLAG_CARGO

/datum/design/nifsoft_hud
	build_type = PROTOLATHE
	materials = list(
		/datum/material/iron = SHEET_MATERIAL_AMOUNT,
		/datum/material/silver = HALF_SHEET_MATERIAL_AMOUNT,
		/datum/material/plastic = SHEET_MATERIAL_AMOUNT,
	)
	category = list("Equipment")

/datum/design/nifsoft_hud/medical
	name = "Medical HUD NIFSoft"
	desc = "A NIFSoft datadisk containing the Medical HUD NIFsoft."
	id = "nifsoft_hud_medical"
	build_path = /obj/item/disk/nifsoft_uploader/med_hud
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL

/datum/design/nifsoft_hud/security
	name = "Security HUD NIFSoft"
	desc = "A NIFSoft datadisk containing the Security HUD NIFsoft."
	id = "nifsoft_hud_security"
	build_path = /obj/item/disk/nifsoft_uploader/sec_hud
	departmental_flags = DEPARTMENTAL_FLAG_SECURITY

/datum/design/nifsoft_hud/cargo
	name = "Permit HUD NIFSoft"
	desc = "A NIFSoft datadisk containing the Permit HUD NIFsoft."
	id = "nifsoft_hud_cargo"
	build_path = /obj/item/disk/nifsoft_uploader/permit_hud
	departmental_flags = DEPARTMENTAL_FLAG_CARGO

/datum/design/nifsoft_hud/diagnostic
	name = "Diagnostic HUD NIFSoft"
	desc = "A NIFSoft datadisk containing the Diagnostic HUD NIFsoft."
	id = "nifsoft_hud_diagnostic"
	build_path = /obj/item/disk/nifsoft_uploader/diag_hud
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

/datum/design/nifsoft_hud/science
	name = "Science HUD NIFSoft"
	desc = "A NIFSoft datadisk containing the Science HUD NIFsoft."
	id = "nifsoft_hud_science"
	build_path = /obj/item/disk/nifsoft_uploader/sci_hud
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE | DEPARTMENTAL_FLAG_SERVICE | DEPARTMENTAL_FLAG_MEDICAL

/datum/design/nifsoft_hud/meson
	name = "Meson HUD NIFSoft"
	desc = "A NIFSoft datadisk containing the Meson HUD NIFsoft."
	id = "nifsoft_hud_meson"
	build_path = /obj/item/disk/nifsoft_uploader/meson_hud
	departmental_flags = DEPARTMENTAL_FLAG_CARGO | DEPARTMENTAL_FLAG_ENGINEERING

/datum/design/nif_hud_kit
	name = "NIF HUD Retrofitter"
	desc = "A kit that modifies select glasses to display HUDs for NIFs."
	id = "nifsoft_hud_kit"
	build_type = PROTOLATHE
	departmental_flags = DEPARTMENTAL_FLAG_CARGO | DEPARTMENTAL_FLAG_MEDICAL | DEPARTMENTAL_FLAG_SERVICE | DEPARTMENTAL_FLAG_SCIENCE | DEPARTMENTAL_FLAG_ENGINEERING | DEPARTMENTAL_FLAG_SECURITY
	materials = list(
		/datum/material/iron = SHEET_MATERIAL_AMOUNT * 2,
		/datum/material/glass = SHEET_MATERIAL_AMOUNT * 2,
		/datum/material/plastic = SHEET_MATERIAL_AMOUNT,
	)
	category = list("Equipment")
	build_path = /obj/item/nif_hud_adapter

// Add NIFs to alien surgery node
/datum/techweb_node/alien_surgery/New()
	design_ids += list(
		"nifsoft_hypno_brainwash",
		"nifsoft_storage_concealment",
		"nifsoft_rapid_disrobe",
		"nifsoft_gfluid",
	)
	return ..()

// Design for brainwash NIFSoft
/datum/design/nifsoft_hud/nifsoft_hypno_brainwash
	name = "Mesmer Eye NIFSoft"
	desc = "A NIFSoft datadisk containing the experimental Mesmer Eye NIFsoft."
	id = "nifsoft_hypno_brainwash"
	build_path = /obj/item/disk/nifsoft_uploader/dorms/hypnosis/brainwashing

// Design for storage concealment NIFSoft
/datum/design/nifsoft_hud/nifsoft_storage_concealment
	name = "Storage Concealment NIFSoft"
	desc = "A NIFSoft datadisk containing the Storage Concealment NIFsoft."
	id = "nifsoft_storage_concealment"
	build_path = /obj/item/disk/nifsoft_uploader/nif_hide_backpack_disk

// Design for rapid disrobe NIFSoft
/datum/design/nifsoft_hud/nifsoft_rapid_disrobe
	name = "Emergency Clothing Disruption NIFSoft"
	desc = "A NIFSoft datadisk containing the Emergency Clothing Disruption NIFsoft."
	id = "nifsoft_rapid_disrobe"
	build_path = /obj/item/disk/nifsoft_uploader/dorms/nif_disrobe_disk

// Design for genital fluid NIFSoft
/datum/design/nifsoft_hud/nifsoft_gfluid
	name = "Genital Fluid Inducer NIFSoft"
	desc = "A NIFSoft datadisk containing the Genital Fluid Inducer NIFsoft."
	id = "nifsoft_gfluid"
	build_path = /obj/item/disk/nifsoft_uploader/dorms/nif_gfluid_disk

