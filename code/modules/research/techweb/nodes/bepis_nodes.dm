////////////////////////B.E.P.I.S. Locked Techs////////////////////////

/datum/techweb_node/light_apps
	id = "light_apps"
	display_name = "Illumination Applications"
	description = "Применение технологий освещения и зрения, которые изначально не считались коммерчески жизнеспособными."
	informing_radio_channels = list(RADIO_CHANNEL_ENGINEERING, RADIO_CHANNEL_SCIENCE, RADIO_CHANNEL_SERVICE)
	prereq_ids = list("base")
	design_ids = list("bright_helmet", "rld_mini")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 2500)
	hidden = TRUE
	experimental = TRUE

/datum/techweb_node/aus_security
	id = "aus_security"
	display_name = "Australicus Security Protocols"
	description = "Говорят, что охрана в секторе Австраликус строгая, поэтому мы кое-что позаимствовали у их оснащения. К счастью, в нашем секторе нет и следа этих «медведей-падальщиков»."
	informing_radio_channels = list(RADIO_CHANNEL_SECURITY)
	prereq_ids = list("base")
	design_ids = list("pin_explorer", "stun_boomerang")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 2500)
	hidden = TRUE
	experimental = TRUE

/datum/techweb_node/spec_eng
	id = "spec_eng"
	display_name = "Specialized Engineering"
	description = "Общепринятая мудрость сочла эти инженерные изделия «технически» безопасными, но слишком опасными, чтобы их традиционно одобрять."
	informing_radio_channels = list(RADIO_CHANNEL_ENGINEERING)
	prereq_ids = list("base")
	design_ids = list("lava_rods", "eng_gloves")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 2500)
	hidden = TRUE
	experimental = TRUE

/datum/techweb_node/bepis_miscellaneous
	id = "bepis_miscellaneous"
	display_name = "Miscellaneous B.E.P.I.S. Technology"
	description = "Набор брошенных технологий, которые могли никогда не увидеть свет."
	informing_radio_channels = list(RADIO_CHANNEL_SERVICE, RADIO_CHANNEL_SCIENCE)
	prereq_ids = list("base")
	design_ids = list("rolling_table","mauna_mug")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 2500)
	hidden = TRUE
	experimental = TRUE

/datum/techweb_node/nanite_replication_protocols
	id = "nanite_replication_protocols"
	display_name = "Nanite Replication Protocols"
	description = "Продвинутые модели поведения, позволяющие нанитам использовать определённые обстоятельства для более быстрого размножения."
	informing_radio_channels = list(RADIO_CHANNEL_SCIENCE)
	prereq_ids = list("nanite_smart")
	design_ids = list("kickstart_nanites","factory_nanites","offline_nanites","synergy_nanites")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 5000)
	hidden = TRUE
	experimental = TRUE

/datum/techweb_node/nanite_storage_protocols
	id = "nanite_storage_protocols"
	display_name = "Nanite Storage Protocols"
	description = "Продвинутые модели поведения, позволяющие нанитам увеличивать максимальный объём с переменными затратами."
	informing_radio_channels = list(RADIO_CHANNEL_SCIENCE)
	prereq_ids = list("nanite_smart")
	design_ids = list("hive_nanites", "zip_nanites", "free_range_nanites", "unsafe_storage_nanites")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 5000)
	hidden = TRUE
	experimental = TRUE

/datum/techweb_node/interrogation
	id = "interrogation"
	display_name = "Enhanced Interrogation Technology"
	description = "Перекрёстно сверив несколько рассекреченных документов прошлых диктаторских режимов, мы смогли разработать невероятно эффективное устройство для допроса. \
	Этические вопросы о потере свободной воли всё ещё могут быть актуальны согласно галактическому праву."
	informing_radio_channels = list(RADIO_CHANNEL_SECURITY)
	prereq_ids = list("base")
	design_ids = list("hypnochair")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 3500)
	hidden = TRUE
	experimental = TRUE

/datum/techweb_node/tackle_advanced
	id = "tackle_advanced"
	display_name = "Advanced Grapple Technology"
	description = "Nanotrasen хотел бы напомнить своим исследователям, что «обнимашки» с коллегами никогда не являются допустимыми, а дальнейшие «научные эксперименты» на эту тему \
	больше не будут приниматься в наших научных журналах."
	informing_radio_channels = list(RADIO_CHANNEL_SECURITY)
	design_ids = list("tackle_dolphin", "tackle_rocket")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 2500)
	hidden = TRUE
	experimental = TRUE

/datum/techweb_node/sticky_advanced
	id = "sticky_advanced"
	display_name = "Advanced Sticky Technology"
	description = "Зашли слишком далеко в шутке? Ерунда!"
	informing_radio_channels = list(RADIO_CHANNEL_ENGINEERING)
	design_ids = list("super_sticky_tape", "pointy_tape")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 2500)
	hidden = TRUE
	experimental = TRUE

/datum/techweb_node/mod_experimental
	id = "mod_experimental"
	display_name = "Experimental Modular Suits"
	description = "Экспериментальные механизмы для модульных костюмов."
	design_ids = list("mod_joint_torsion", "mod_disposal", "mod_recycler", "mod_shooting")
	hidden = TRUE
	experimental = TRUE
