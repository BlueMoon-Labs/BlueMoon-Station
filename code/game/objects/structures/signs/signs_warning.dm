/obj/structure/sign/warning
	name = "\improper WARNING"
	desc = "A warning sign."
	icon_state = "securearea"

/obj/structure/sign/warning/securearea
	name = "\improper SECURE AREA"
	desc = "A warning sign which reads 'SECURE AREA'."
	is_editable = TRUE
	sign_change_name = "Secure Area"

/obj/structure/sign/warning/docking
	name = "\improper KEEP CLEAR: DOCKING AREA"
	desc = "A warning sign which reads 'KEEP CLEAR OF DOCKING AREA'."

/obj/structure/sign/warning/biohazard
	name = "\improper BIOHAZARD"
	desc = "A warning sign which reads 'BIOHAZARD'."
	icon_state = "bio"
	is_editable = TRUE
	sign_change_name = "Biohazard"

/obj/structure/sign/warning/electricshock
	name = "\improper HIGH VOLTAGE"
	desc = "A warning sign which reads 'HIGH VOLTAGE'."
	icon_state = "shock"
	is_editable = TRUE
	sign_change_name = "High Voltage"

/obj/structure/sign/warning/vacuum
	name = "\improper HARD VACUUM AHEAD"
	desc = "A warning sign which reads 'HARD VACUUM AHEAD'."
	icon_state = "space"
	is_editable = TRUE
	sign_change_name = "Hard Vacuum Ahead"

/obj/structure/sign/warning/vacuum/external
	name = "\improper EXTERNAL AIRLOCK"
	desc = "A warning sign which reads 'EXTERNAL AIRLOCK'."
	layer = MOB_LAYER
	is_editable = FALSE //имя досталось бы от родителя и затёрло бы его запись в реестре

/obj/structure/sign/warning/deathsposal
	name = "\improper DISPOSAL: LEADS TO SPACE"
	desc = "A warning sign which reads 'DISPOSAL: LEADS TO SPACE'."
	icon_state = "deathsposal"
	is_editable = TRUE
	sign_change_name = "Disposal: Leads To Space"

/obj/structure/sign/warning/pods
	name = "\improper ESCAPE PODS"
	desc = "A warning sign which reads 'ESCAPE PODS'."
	icon_state = "pods"

/obj/structure/sign/warning/fire
	name = "\improper DANGER: FIRE"
	desc = "A warning sign which reads 'DANGER: FIRE'."
	icon_state = "fire"
	is_editable = TRUE
	sign_change_name = "Danger: Fire"

/obj/structure/sign/warning/nosmoking
	name = "\improper NO SMOKING"
	desc = "A warning sign which reads 'NO SMOKING'."
	icon_state = "nosmoking2"

/obj/structure/sign/warning/nosmoking/circle
	icon_state = "nosmoking"
	is_editable = TRUE
	sign_change_name = "No Smoking"

/obj/structure/sign/warning/radiation
	name = "\improper HAZARDOUS RADIATION"
	desc = "A warning sign alerting the user of potential radiation hazards."
	icon_state = "radiation"
	is_editable = TRUE
	sign_change_name = "Radiation"

/obj/structure/sign/warning/radiation/rad_area
	name = "\improper RADIOACTIVE AREA"
	desc = "A warning sign which reads 'RADIOACTIVE AREA'."
	is_editable = FALSE //имя досталось бы от родителя и затёрло бы его запись в реестре

/obj/structure/sign/warning/xeno_mining
	name = "\improper DANGEROUS ALIEN LIFE"
	desc = "A sign that warns would-be travellers of hostile alien life in the vicinity."
	icon = 'icons/obj/mining.dmi'
	icon_state = "xeno_warning"

/obj/structure/sign/warning/enginesafety
	name = "\improper ENGINEERING SAFETY"
	desc = "A sign detailing the various safety protocols when working on-site to ensure a safe shift."
	icon_state = "safety"

/obj/structure/sign/warning/explosives
	name = "\improper HIGH EXPLOSIVES sign"
	desc = "A warning sign which reads 'HIGH EXPLOSIVES'."
	icon_state = "explosives"
