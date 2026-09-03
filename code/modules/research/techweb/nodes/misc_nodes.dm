
/////////////////////////data theory tech/////////////////////////
/datum/techweb_node/datatheory //Computer science
	id = "datatheory"
	display_name = "Data Theory"
	description = "Big Data, in space!"
	informing_radio_channels = list(RADIO_CHANNEL_SCIENCE)
	prereq_ids = list("base")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 2000)

/datum/techweb_node/adv_datatheory
	id = "adv_datatheory"
	display_name = "Advanced Data Theory"
	description = "Better insight into programming and data."
	informing_radio_channels = list(RADIO_CHANNEL_SCIENCE)
	prereq_ids = list("datatheory")
	design_ids = list("icprinter", "icupgadv", "icupgclo", "bounty_pad","bounty_pad_control", "encryptionkey_sec", "encryptionkey_eng", "encryptionkey_med", "encryptionkey_medsci", "encryptionkey_sci", "encryptionkey_cargo", "encryptionkey_mining", "encryptionkey_service")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 3000)

/////////////////////////plasma tech/////////////////////////
/datum/techweb_node/basic_plasma
	id = "basic_plasma"
	display_name = "Basic Plasma Research"
	description = "Research into the mysterious and dangerous substance, plasma."
	informing_radio_channels = list(RADIO_CHANNEL_SCIENCE)
	prereq_ids = list("engineering")
	design_ids = list("mech_generator")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 2000)

/datum/techweb_node/adv_plasma
	id = "adv_plasma"
	display_name = "Advanced Plasma Research"
	description = "Research on how to fully exploit the power of plasma."
	informing_radio_channels = list(RADIO_CHANNEL_SCIENCE)
	prereq_ids = list("basic_plasma")
	design_ids = list("mech_plasma_cutter")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 3000)

/////////////////////////EMP tech/////////////////////////
/datum/techweb_node/emp_basic //EMP tech for some reason
	id = "emp_basic"
	display_name = "Electromagnetic Theory"
	description = "Study into usage of frequencies in the electromagnetic spectrum."
	informing_radio_channels = list(RADIO_CHANNEL_SCIENCE, RADIO_CHANNEL_ENGINEERING)
	prereq_ids = list("base")
	design_ids = list("holosign", "holosignsec", "holosignengi", "holosignatmos",/* "holosignfirelock",*/ "inducer", "tray_goggles", "holopad","inducer_sci")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 2500)

/datum/techweb_node/emp_adv
	id = "emp_adv"
	display_name = "Advanced Electromagnetic Theory"
	description = "Determining whether reversing the polarity will actually help in a given situation."
	informing_radio_channels = list(RADIO_CHANNEL_SCIENCE, RADIO_CHANNEL_ENGINEERING)
	prereq_ids = list("emp_basic")
	design_ids = list("ultra_micro_laser")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 3000)

/////////////////////////Clown tech/////////////////////////
/datum/techweb_node/clown
	id = "clown"
	display_name = "Clown Technology"
	description = "Honk?!"
	informing_radio_channels = list(RADIO_CHANNEL_SERVICE)
	prereq_ids = list("base")
	design_ids = list("air_horn", "honker_main", "honker_peri", "honker_targ", "honk_chassis", "honk_head", "honk_torso", "honk_left_arm", "honk_right_arm",
	"honk_left_leg", "honk_right_leg", "mech_banana_mortar", "mech_mousetrap_mortar", "mech_honker", "mech_punching_face", "implant_trombone", "borg_transform_clown")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 2500)

////////////////////////Tape tech////////////////////////////
/datum/techweb_node/sticky_basic
	id = "sticky_basic"
	display_name = "Basic Sticky Technology"
	description = "The only thing left to do after researching this tech is to start printing out a bunch of 'kick me' signs."
	informing_radio_channels = list(RADIO_CHANNEL_SERVICE)
	prereq_ids = list("base")
	design_ids = list("sticky_tape")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 2500)
	starting_node = TRUE

// now a BEPIS locked thing
/datum/techweb_node/sticky_advanced
	id = "sticky_advanced"
	display_name = "Advanced Sticky Technology"
	description = "Taking a good joke too far? Nonsense!"
	informing_radio_channels = list(RADIO_CHANNEL_ENGINEERING)
	design_ids = list("super_sticky_tape", "pointy_tape")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 5000)
	hidden = TRUE
	experimental = TRUE
