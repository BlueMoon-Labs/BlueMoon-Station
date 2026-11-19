
/////////////////////////weaponry tech/////////////////////////
/datum/techweb_node/weaponry
	id = "weaponry"
	display_name = "Weapon Development Technology"
	description = "Наши исследователи научились превращать в оружие практически что угодно."
	informing_radio_channels = list(RADIO_CHANNEL_SECURITY)
	prereq_ids = list("sec_basic", "engineering") // BLUEMOON ADD sec_basic for order consistency
	design_ids = list("pin_testing", "tele_shield", "lasercarbine")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 7500)

/datum/techweb_node/adv_weaponry
	id = "adv_weaponry"
	display_name = "Advanced Weapon Development Technology"
	description = "Наше оружие уже нарушает законы реальности."
	informing_radio_channels = list(RADIO_CHANNEL_SECURITY)
	prereq_ids = list("adv_engi", "weaponry")
	design_ids = list("pin_loyalty", "laser_shield", "bullet_shield", "ammoworkbench_disk_lethal", "blueshield_mag")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 9500)

/datum/techweb_node/electric_weapons
	id = "electronic_weapons"
	display_name = "Electric Weapons"
	description = "Оружие, использующее электрические технологии"
	informing_radio_channels = list(RADIO_CHANNEL_SECURITY)
	prereq_ids = list("weaponry", "adv_power"  , "emp_basic")
	design_ids = list("stunrevolver", "stunshell",  "ioncarbine")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 3500)

/datum/techweb_node/radioactive_weapons
	id = "radioactive_weapons"
	display_name = "Radioactive Weaponry"
	description = "Оружие, использующее радиоактивные технологии."
	informing_radio_channels = list(RADIO_CHANNEL_SECURITY)
	prereq_ids = list("adv_engi", "adv_weaponry")
	design_ids = list("nuclear_gun")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 2500)

/datum/techweb_node/magnetic_weapons
	id = "magnetic_weapons"
	display_name = "Magnetic Weapons"
	description = "Оружие, использующее магнитные технологии"
	informing_radio_channels = list(RADIO_CHANNEL_SECURITY)
	prereq_ids = list("weaponry", "adv_weaponry", "emp_adv")
	design_ids = list("magrifle", "magpistol", "mag_magrifle", "mag_magrifle_nl", "mag_magpistol", "mag_magpistol_nl")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 2500)

/datum/techweb_node/medical_weapons
	id = "medical_weapons"
	display_name = "Medical Weaponry"
	description = "Оружие, использующее медицинские технологии."
	informing_radio_channels = list(RADIO_CHANNEL_MEDICAL)
	prereq_ids = list("adv_biotech", "adv_weaponry")
	design_ids = list("rapidsyringe", "shotgundartcryostatis","smartdartrepeater")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 2000)

/datum/techweb_node/beam_weapons
	id = "beam_weapons"
	display_name = "Beam Weaponry"
	description = "Различное базовое лучевое оружие"
	informing_radio_channels = list(RADIO_CHANNEL_SECURITY)
	prereq_ids = list("adv_weaponry")
	design_ids = list("temp_gun", "xray_laser")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 2500)

/datum/techweb_node/adv_beam_weapons
	id = "adv_beam_weapons"
	display_name = "Advanced Beam Weaponry"
	description = "Различное продвинутое лучевое оружие"
	informing_radio_channels = list(RADIO_CHANNEL_SECURITY)
	prereq_ids = list("beam_weapons")
	design_ids = list("beamrifle")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 3250) // Sniper

/datum/techweb_node/explosive_weapons
	id = "explosive_weapons"
	display_name = "Explosive & Pyrotechnical Weaponry"
	description = "Если лёгкие варианты не помогают."
	informing_radio_channels = list(RADIO_CHANNEL_SCIENCE, RADIO_CHANNEL_MEDICAL)
	prereq_ids = list("adv_weaponry")
	design_ids = list("large_Grenade", "pyro_Grenade", "adv_Grenade")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 2750)

/datum/techweb_node/ballistic_weapons
	id = "ballistic_weapons"
	display_name = "Ballistic Weaponry"
	description = "Это не исследование... Это реверс-инжиниринг!"
	informing_radio_channels = list(RADIO_CHANNEL_SECURITY)
	prereq_ids = list("weaponry")
	design_ids = list("mag_oldsmg", "mag_oldsmg_ap", "mag_oldsmg_ic", "mag_oldsmg_rubber", "mag_oldsmg_tx")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 2750)

/datum/techweb_node/exotic_ammo
	id = "exotic_ammo"
	display_name = "Exotic Ammunition"
	description = "Они не поймут, что их вдарило."
	informing_radio_channels = list(RADIO_CHANNEL_SECURITY)
	prereq_ids = list("weaponry", "ballistic_weapons")
	design_ids = list("techshotshell", "c38_hotshot", "c38_iceblox", "enlarged_rubber")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 3500)

/datum/techweb_node/gravity_gun
	id = "gravity_gun"
	display_name = "One-point Bluespace-gravitational Manipulator"
	description = "Красивое название для гравитационной пушки."
	informing_radio_channels = list(RADIO_CHANNEL_SCIENCE)
	prereq_ids = list("adv_weaponry", "adv_bluespace")
	design_ids = list("gravitygun", "mech_gravcatapult")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 2500)

/datum/techweb_node/mil_beam_weapons
	id = "mil_beam_weapons"
	display_name = "Military Beam Weaponry"
	description = "Ориентированная на военные нужды лазерная система вооружения"
	informing_radio_channels = list(RADIO_CHANNEL_SECURITY)
	prereq_ids = list("beam_weapons")
	design_ids = list("immolator")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 15000) // Immolator

/datum/techweb_node/speedloaders
	id = "speedloaders"
	display_name = "Special speedloaders for special situations"
	description = "Чувствуешь себя удачливым, панк?"
	informing_radio_channels = list(RADIO_CHANNEL_SECURITY)
	prereq_ids = list("weaponry", "ballistic_weapons")
	design_ids = list("41_dumdum", "41_incendiary", "41_magnum", "41_fmj", "41_ion", "41_ric", "41_rat")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 3500)

/datum/techweb_node/revolver_conversions
	id = "revolver_conversions"
	display_name = "Desperate situations call for desperate measures"
	description = "Тёмные времена требуют грубой ярости. Когда мир трескается, ты не плачешь — ты свариваешь осколки и заставляешь железо кричать."
	informing_radio_channels = list(RADIO_CHANNEL_SECURITY)
	prereq_ids = list("weaponry", "adv_weaponry")
	design_ids = list("dies_irae", "liturgy", "anathema", "Mea_culpa", "Misericordia")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 10000)
