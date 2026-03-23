/datum/design/roller_normal
	name = "Roller bed"
	desc = "A collapsed roller bed that can be carried around."
	id = "normal_roller_bed"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 4000)
	build_path = /obj/item/roller
	category = list("Equipment")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL|DEPARTMENTAL_FLAG_SECURITY

/datum/design/roller_heavy
	name = "Heavy roller bed"
	desc = "A collapsed roller bed that can be carried around. Can be used to move heavy spacemens and spacevulfs."
	id = "heavy_roller_bed"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 8000)
	build_path = /obj/item/roller/heavy
	category = list("Equipment")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL|DEPARTMENTAL_FLAG_SECURITY

/datum/design/roller_stasis
	name = "Stasis roller bed"
	desc = "A collapsed roller bed with a stasis function that can be carried around."
	id = "stasis_roller_bed"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 4000, /datum/material/glass = 400, /datum/material/silver = 2000)
	build_path = /obj/item/roller/stasis
	category = list("Equipment")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL|DEPARTMENTAL_FLAG_SECURITY

/datum/techweb_node/base/New()
	var/extra_designs = list(
		"heavy_roller_bed",
		"normal_roller_bed"
	)
	LAZYADD(design_ids, extra_designs)
	. = ..()

/datum/design/blast_control
	name = "Blast Door Controller"
	id = "blast_control"
	build_type = AUTOLATHE | PROTOLATHE
	materials = list(/datum/material/iron = 50, /datum/material/glass = 50)
	build_path = /obj/item/assembly/control
	category = list("initial", "Electronics")
	departmental_flags = DEPARTMENTAL_FLAG_ENGINEERING

/datum/design/janicart_uprgade_omni
	name = "(janicart) vacuum + floor buffer Upgrade"
	desc = "A dual upgrade that can be attached to vehicular janicarts."
	id = "omni_janicart"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 6000, /datum/material/glass = 400, /datum/material/silver = 500)
	build_path = /obj/item/janicart_upgrade/omni
	category = list("Equipment")
	departmental_flags = DEPARTMENTAL_FLAG_SERVICE

/datum/design/adv_mop_uprgade_cleaner
	name = "(advanced mop) cleaner modification"
	desc = "Upgrade for advanced mop"
	id = "adv_mop_cleaner"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 8000, /datum/material/glass = 1500, /datum/material/silver = 2000, /datum/material/gold = 2000, /datum/material/diamond = 2000)
	build_path = /obj/item/advanced_mop_upgrade/cleaner
	category = list("Equipment")
	departmental_flags = DEPARTMENTAL_FLAG_SERVICE

/datum/design/adv_mop_uprgade_charge
	name = "(advanced mop) charge modification"
	desc = "Upgrade for advanced mop"
	id = "adv_mop_charge"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 2000, /datum/material/silver = 1000, /datum/material/gold = 1000)
	build_path = /obj/item/advanced_mop_upgrade/charge_rate
	category = list("Equipment")
	departmental_flags = DEPARTMENTAL_FLAG_SERVICE

/datum/design/adv_mop_uprgade_light
	name = "(advanced mop) light modification"
	desc = "Upgrade for advanced mop"
	id = "adv_mop_light"
	build_type = PROTOLATHE
	materials = list(/datum/material/glass = 5000)
	build_path = /obj/item/advanced_mop_upgrade/light
	category = list("Equipment")
	departmental_flags = DEPARTMENTAL_FLAG_SERVICE

/datum/design/adv_mop_uprgade_capacity
	name = "(advanced mop) capacity modification"
	desc = "Upgrade for advanced mop"
	id = "adv_mop_capacity"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 10000, /datum/material/glass = 5000)
	build_path = /obj/item/advanced_mop_upgrade/capacity
	category = list("Equipment")
	departmental_flags = DEPARTMENTAL_FLAG_SERVICE

/datum/design/adv_mop_uprgade_reach
	name = "(advanced mop) reach modification"
	desc = "Upgrade for advanced mop"
	id = "adv_mop_reach"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 6000, /datum/material/glass = 400, /datum/material/silver = 500)
	build_path = /obj/item/advanced_mop_upgrade/reach
	category = list("Equipment")
	departmental_flags = DEPARTMENTAL_FLAG_SERVICE
