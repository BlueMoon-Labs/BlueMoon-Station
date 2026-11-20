
/////////////////////////robotics tech/////////////////////////
/datum/techweb_node/robotics
	id = "robotics"
	display_name = "Basic Robotics Research"
	description = "Программируемые машины, которые делают нашу жизнь ленивее."
	informing_radio_channels = list(RADIO_CHANNEL_SCIENCE)
	prereq_ids = list("base")
	design_ids = list("paicard", "drone_shell")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 2000)

/datum/techweb_node/mmi
	id = "mmi"
	starting_node = TRUE
	display_name = "Man Machine Interface"
	description = "Устройство с лёгким налётом Франкенштейна, позволяющее человеческому мозгу напрямую взаимодействовать с программными API."
	informing_radio_channels = list(RADIO_CHANNEL_SCIENCE)
	design_ids = list("mmi")

/datum/techweb_node/cyborg
	id = "cyborg"
	starting_node = TRUE
	display_name = "Cyborg Construction"
	description = "Разумные роботы с предустановленными модулями инструментов и программируемыми законами."
	informing_radio_channels = list(RADIO_CHANNEL_SCIENCE)
	design_ids = list(/*"robocontrol", */"sflash", "borg_suit", "borg_head", "borg_chest", "borg_r_arm", "borg_l_arm", "borg_r_leg", "borg_l_leg", /*"borgupload",*/ /*BlueMoon edit*/
	"cyborgrecharger", "borg_upgrade_restart", "borg_upgrade_rename")

/datum/techweb_node/adv_robotics
	id = "adv_robotics"
	display_name = "Advanced Robotics Research"
	description = "Он даже может мыть посуду!"
	informing_radio_channels = list(RADIO_CHANNEL_SCIENCE)
	prereq_ids = list("robotics")
	design_ids = list("borg_upgrade_diamonddrill", "borg_upgrade_advancedmop", "borg_upgrade_advcutter", "nanogel", "robotic_pr")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 3000)

/datum/techweb_node/neural_programming
	id = "neural_programming"
	display_name = "Neural Programming"
	description = "Изучение сетей вычислительных блоков, подражающих нашему мозгу."
	informing_radio_channels = list(RADIO_CHANNEL_SCIENCE, RADIO_CHANNEL_MEDICAL)
	prereq_ids = list("biotech", "datatheory")
	design_ids = list("Implanter", "implantcase", "impant_radio", "implant_chem", "implant_tracking", "locator", "c38_trac", "implant_gfluid", "implant_slave", "implant_hide_backpack")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 2500)

/datum/techweb_node/posibrain
	id = "posibrain"
	display_name = "Positronic Brain"
	description = "Практическое применение нейротехнологий, позволяющее создавать автономные блоки ИИ на основе особых металлических кубов с проводящими и вычислительными схемами."
	informing_radio_channels = list(RADIO_CHANNEL_SCIENCE)
	prereq_ids = list("neural_programming")
	design_ids = list("mmi_posi", "ipc_constructor", "ipc_head_chassis", "ipc_torso_chassis")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 2500)

/datum/techweb_node/cyborg_upg_util
	id = "cyborg_upg_util"
	display_name = "Cyborg Upgrades: Utility"
	description = "Улучшения служебного оснащения киборгов."
	informing_radio_channels = list(RADIO_CHANNEL_SCIENCE)
	prereq_ids = list("engineering", "robotics")
	design_ids = list("borg_upgrade_lavaproof", "borg_upgrade_thrusters", "borg_upgrade_selfrepair", "borg_upgrade_expand", "borg_upgrade_rped", "borg_upgrade_broomer")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 2000)

/datum/techweb_node/cyborg_upg_med
	id = "cyborg_upg_med"
	display_name = "Cyborg Upgrades: Medical"
	description = "Медицинские улучшения для киборгов."
	informing_radio_channels = list(RADIO_CHANNEL_SCIENCE)
	prereq_ids = list("adv_biotech", "robotics")
	design_ids = list("borg_upgrade_advhealth", "borg_upgrade_piercinghypospray", "borg_upgrade_highstrengthsynthesiser", "borg_upgrade_expandedsynthesiser", "borg_upgrade_pinpointer", "borg_upgrade_surgicalprocessor")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 2000)

/datum/techweb_node/cyborg_upg_combat
	id = "cyborg_upg_combat"
	display_name = "Cyborg Upgrades: Combat"
	description = "Военные улучшения для киборгов."
	informing_radio_channels = list(RADIO_CHANNEL_SCIENCE)
	prereq_ids = list("adv_robotics", "adv_engi" , "weaponry")
	design_ids = list("borg_upgrade_vtec", "borg_upgrade_disablercooler")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 5000)

/datum/techweb_node/ai
	id = "ai"
	display_name = "Artificial Intelligence"
	description = "Исследования блоков ИИ."
	informing_radio_channels = list(RADIO_CHANNEL_SCIENCE)
	prereq_ids = list("robotics", "posibrain")
	design_ids = list("aifixer", "aicore", "safeguard_module", "onehuman_module", "protectstation_module", "quarantine_module", "oxygen_module", "freeform_module",
	"reset_module", "purge_module", "remove_module", "freeformcore_module", "asimov_module", "asimovpp_module", "gentleman_module", "maintain_module", "drone_module", "hippocratic_module", "robocop_module",
	"reporter_module", "liveandletlive_module", "balance_module", "hulkamania_module", "nt_safeguard_module", "paladin_module", "tyrant_module", "corporate_module",
	"default_module", "borg_ai_control", "mecha_tracking_ai_control", /*"aiupload",*/ "intellicard", "slut_module", "shebang_module", "milker_module", "vore_pred_module")/*BlueMoon edit*/
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 2500)

// (ADD) Pe4henika bluemoon -- start
// MARK: JukeBox module
/datum/techweb_node/cyborg_upg_jukebox
	id = "cyborg_upg_jukebox"
	display_name = "Cyborg Upgrades: Jukebox"
	description = "Позволяет киборгам транслировать музыку, используя внутренние аудиосистемы."
	informing_radio_channels = list(RADIO_CHANNEL_SCIENCE)
	prereq_ids = list("adv_biotech", "robotics")
	design_ids = list("borg_upgrade_jukebox")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 5000)
	hidden = TRUE

/datum/techweb_node/cyborg_upg_jukebox/New()
	..()
	boost_item_paths = list(/obj/item/jukebox)
/datum/techweb_node/link_ai
	id = "link_ai"
	display_name = "Advanced AI connectivity"
	description = "Технологии нейроинтерфейсов"
	informing_radio_channels = list(RADIO_CHANNEL_SCIENCE, RADIO_CHANNEL_MEDICAL)
	prereq_ids = list("ai", "combat_cyber_implants")
	design_ids = list("ai_link_implant")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 7500)
// (ADD) Pe4henika bluemoon -- end
