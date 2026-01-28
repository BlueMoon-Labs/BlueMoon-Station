/datum/techweb_node/syndicate_augments
	id = "syndicate_augments"
	display_name = "Syndicate-grade Augmentations"
	description = "Experimental schemes of syndicate augmentations reverse-engineered by NT RnD department."
	prereq_ids = list("syndicate_basic")
	design_ids = list("ci-mantis", "ci-scanner", "ci-pumpextreme", "ci-binolenses")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 5000)

/datum/techweb_node/syndicate_healing_augs
	id = "syndicate_augments_healing"
	display_name = "Revitilizer-line Augmentations"
	description = "Brand-new healing augmentations, developed earlier by Syndicate RnD department."
	prereq_ids = list("syndicate_augments")
	design_ids = list("ci-healerext", "ci-healerint","ci-cortex")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 2500)

/datum/techweb_node/cyberneticbrainbanks
	id = "cyberneticbrainbanks"
	display_name = "Cybernetic Data Chips"
	description = "Additional memory banks for humanoid creatures to enforce additional learning capabilities."
	prereq_ids = list("adv_cyber_implants")
	design_ids = list("chip-medical", "chip-robotic","chip-engi")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 7500)

/datum/techweb_node/basicxenoorgans
	id = "basicxenoorgans"
	display_name = "Basic Xenochimeric Fleshcrafting"
	description = "Experimental xenochimeric designs for organs."
	prereq_ids = list("exp_surgery")
	design_ids = list("alientongue", "neurotoxin", "plasmavessel", "alientongue_alt", "neurotoxin_alt", "plasmavessel_alt")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 20000)

/datum/techweb_node/advxenoorgans
	id = "advxenoorgans"
	display_name = "Advanced Xenochimeric Fleshcrafting"
	description = "Advanced xenochimeric designs for organs."
	prereq_ids = list("basicxenoorgans")
	design_ids = list("hivenode", "eggsac", "acidgland", "resinspinner", "hivenode_alt", "eggsac_alt", "acidgland_alt", "resinspinner_alt")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 25000) //This one allows you to make your own hives. So yes, expect this to happen only in Extended.

//BIOAEGIS MODULE, THese *WILL* require high-spending, but providing huge buffs.

/datum/techweb_node/bioaegis1 //Very basic organs, barely an improvement.
	id = "bioaegis1"
	display_name = "Bio-Organic Theory"
	description = "It was known that with certain technology it was possible to replicate flesh, or even improve it - but as NanoTrasen department declared, it was barely legal."
	prereq_ids = list("adv_biotech")
	design_ids = list("bioaegisboard", "hearttier1", "livertier1", "lungstier1")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 12500) //Шо то на зарубежном было. Убрал этот ваш гейтвей для реализации механа НЕ ТОЛЬКО в режим экстендет

/datum/techweb_node/bioaegis2 //Better versions. Faster-better-stronger.
	id = "bioaegis2"
	display_name = "Advanced Organic Designs"
	description = "Research regarding printing of organs was somewhat improved, and it allows us to utilize more-or-less certain future about fleshcrafting."
	prereq_ids = list("bioaegis1")
	design_ids = list("hearttier2", "livertier2", "lungstier2")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 10000)

/datum/techweb_node/bioaegis3 //High-end versions. Bigger-better-stronger than ever before! https://youtu.be/3b_NCIhbL0s?si=tTxX9Eob_36BxGix
	id = "bioaegis3"
	display_name = "Superior Organic Designs"
	description = "After extensive research, it is possible to create the most perfect of organic designs to ever exist. Science department is yet so close to perfection."
	prereq_ids = list("bioaegis2")
	design_ids = list("hearttier3", "livertier3", "lungstier3")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 15000)

/datum/techweb_node/bioaegis_special //Specific for species/quirks with issues.
	id = "bioaegis_special"
	display_name = "Specialized Organic Designs"
	description = "During research it was known that we can alter some capabilities of certain species to improve their ability to survive in hostile environment."
	prereq_ids = list("bioaegis2")
	design_ids = list("adaptiveeyes", "thermalaegiseyes", "darkveilorgan", "optisiaorgan", "babyloncords")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 10000)

datum/techweb_node/bioaegis_danger //Dangerous ones, that might kill you.
	id = "bioaegis_danger"
	display_name = "Experimental Organic Designs"
	description = "Some evil scientist decided to fuck around and did find out."
	prereq_ids = list("bioaegis3")
	design_ids = list("neuralderanger", "bodyoverload")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 10000)
