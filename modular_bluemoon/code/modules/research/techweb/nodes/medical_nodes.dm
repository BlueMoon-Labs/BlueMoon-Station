/datum/techweb_node/syndicate_augments
	id = "syndicate_augments"
	display_name = "Syndicate-grade Augmentations"
	description = "Экспериментальные схемы синдикатских аугментаций, реконструированные отделом НИОКР NT."
	informing_radio_channels = list(RADIO_CHANNEL_SECURITY, RADIO_CHANNEL_MEDICAL, RADIO_CHANNEL_SCIENCE)
	prereq_ids = list("syndicate_basic")
	design_ids = list("ci-mantis", "ci-mantis-hack", "ci-scanner", "ci-pumpextreme", "ci-subdermal-armor", "ci-reinforced-skeleton")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 5000)

/datum/techweb_node/syndicate_healing_augs
	id = "syndicate_augments_healing"
	display_name = "Revitilizer-line Augmentations"
	description = "Новейшие лечебные аугментации, разработанные ранее отделом НИОКР Синдиката."
	informing_radio_channels = list(RADIO_CHANNEL_SECURITY, RADIO_CHANNEL_MEDICAL)
	prereq_ids = list("syndicate_augments")
	design_ids = list("ci-healerext", "ci-healerint","ci-cortex")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 2500)

/datum/techweb_node/cyberneticbrainbanks
	id = "cyberneticbrainbanks"
	display_name = "Cybernetic Data Chips"
	description = "Дополнительные банки памяти для гуманоидных существ, расширяющие способности к обучению."
	informing_radio_channels = list(RADIO_CHANNEL_SCIENCE, RADIO_CHANNEL_MEDICAL)
	prereq_ids = list("adv_cyber_implants")
	design_ids = list("chip-medical", "chip-robotic","chip-engi")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 7500)

/datum/techweb_node/basicxenoorgans
	id = "basicxenoorgans"
	display_name = "Basic Xenochimeric Fleshcrafting"
	description = "Экспериментальные конструкции ксенорганов."
	informing_radio_channels = list(RADIO_CHANNEL_SCIENCE)
	prereq_ids = list("exp_surgery")
	design_ids = list("alientongue", "neurotoxin", "plasmavessel", "alientongue_alt", "neurotoxin_alt", "plasmavessel_alt")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 20000)

/datum/techweb_node/advxenoorgans
	id = "advxenoorgans"
	display_name = "Advanced Xenochimeric Fleshcrafting"
	description = "Продвинутые конструкции ксенорганов."
	informing_radio_channels = list(RADIO_CHANNEL_SCIENCE)
	prereq_ids = list("basicxenoorgans")
	design_ids = list("hivenode", "eggsac", "acidgland", "resinspinner", "hivenode_alt", "eggsac_alt", "acidgland_alt", "resinspinner_alt")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 25000) //This one allows you to make your own hives. So yes, expect this to happen only in Extended.

//BIOAEGIS MODULE, THese *WILL* require high-spending, but providing huge buffs.

/datum/techweb_node/bioaegis1 //Very basic organs, barely an improvement.
	id = "bioaegis1"
	display_name = "Bio-Organic Theory"
	description = "Было известно, что с определённой технологией можно воспроизводить плоть и даже улучшать её — но, как заявил отдел NanoTrasen, это едва законно."
	informing_radio_channels = list(RADIO_CHANNEL_SCIENCE)
	prereq_ids = list("adv_biotech")
	design_ids = list("bioaegisboard", "hearttier1", "livertier1", "lungstier1")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 12500) //Шо то на зарубежном было. Убрал этот ваш гейтвей для реализации механа НЕ ТОЛЬКО в режим экстендет

/datum/techweb_node/bioaegis2 //Better versions. Faster-better-stronger.
	id = "bioaegis2"
	display_name = "Advanced Organic Designs"
	description = "Исследования по печати органов несколько продвинулись и позволяют с той или иной степенью уверенности говорить о будущем выращивания плоти."
	informing_radio_channels = list(RADIO_CHANNEL_SCIENCE)
	prereq_ids = list("bioaegis1")
	design_ids = list("hearttier2", "livertier2", "lungstier2")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 10000)

/datum/techweb_node/bioaegis3 //High-end versions. Bigger-better-stronger than ever before! https://youtu.be/3b_NCIhbL0s?si=tTxX9Eob_36BxGix
	id = "bioaegis3"
	display_name = "Superior Organic Designs"
	description = "После обширных исследований стало возможным создать самые совершенные органические конструкции из когда-либо существовавших. Научному отделу ещё немного до совершенства."
	informing_radio_channels = list(RADIO_CHANNEL_SCIENCE)
	prereq_ids = list("bioaegis2")
	design_ids = list("hearttier3", "livertier3", "lungstier3")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 15000)

/datum/techweb_node/bioaegis_special //Specific for species/quirks with issues.
	id = "bioaegis_special"
	display_name = "Specialized Organic Designs"
	description = "В ходе исследований выяснилось, что мы можем изменить некоторые способности определённых видов, чтобы улучшить их выживаемость во враждебной среде."
	informing_radio_channels = list(RADIO_CHANNEL_SCIENCE)
	prereq_ids = list("bioaegis2")
	design_ids = list("adaptiveeyes", "thermalaegiseyes", "darkveilorgan", "optisiaorgan", "babyloncords")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 10000)

/datum/techweb_node/bioaegis_danger //Dangerous ones, that might kill you.
	id = "bioaegis_danger"
	display_name = "Experimental Organic Designs"
	description = "Один злой учёный решил поиграть с огнём — и выяснил, что будет."
	informing_radio_channels = list(RADIO_CHANNEL_SCIENCE)
	prereq_ids = list("bioaegis3")
	design_ids = list("neuralderanger", "bodyoverload")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 10000)

/////////////////// Инструменты ///////////////////
/datum/techweb_node/upgraded_surgerytools
	id = "upgraded_surgerytools"
	display_name = "Upgraded Surgery Tools"
	description = "Улучшенные базовые инструменты, использующие вибрационные и плазменные технологии."
	informing_radio_channels = list(RADIO_CHANNEL_SCIENCE, RADIO_CHANNEL_MEDICAL)
	prereq_ids = list("basic_tools", "adv_biotech")
	design_ids = list("scalpel_upgraded", "circularsaw_upgraded", "retractor_upgraded", "hemostat_upgraded", "cautery_upgraded", "surgical_tape")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 1250)
