/datum/design/cybernetic_heart/anomalock
	name = "Voltaic Combat Cyberheart"
	desc = "A cutting-edge cyberheart, originally designed for Nanotrasen killsquad usage but later declassified for normal research. Voltaic technology allows the heart to keep the body upright in dire circumstances, alongside redirecting anomalous flux energy to fully shield the user from shocks and electro-magnetic pulses. Does nothing without a flux anomaly core."
	id = "cybernetic_heart_anomalock"
	construction_time = 50
	materials = list(
		/datum/material/iron = 500,
		/datum/material/glass = 500,
		/datum/material/titanium = 500,
		/datum/material/diamond = 100,
	)
	build_path = /obj/item/organ/heart/cybernetic/anomalock
	category = list("Cybernetics", "Organs")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL | DEPARTMENTAL_FLAG_SCIENCE
