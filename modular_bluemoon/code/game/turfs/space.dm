//Tarkov.
/datum/map_template/ruin/space/tarkoff
	name = "Port Tarkov"
	prefix = "_maps/RandomRuins/SpaceRuins/BlueMoon/"
	allow_duplicates = FALSE
	id = "tarkoff-base"

/datum/map_template/ruin/space/tarkoff/New()
	var/num = rand(0, 3)
	switch(num)
		if(0)
			suffix = "defcon5.dmm"
		if(1)
			suffix = "defcon4.dmm"
		if(2)
			suffix = "defcon3.dmm"
		if(3)
			suffix = "defcon2.dmm"
	. = ..()

//DS2.
/datum/map_template/ruin/space/deepspacetwo
	name = "Deep Space Two"
	prefix = "_maps/RandomRuins/SpaceRuins/BlueMoon/"
	suffix = "space_syndicate_base.dmm"
	allow_duplicates = FALSE
	always_place = TRUE
	id = "ds2-base"

/datum/map_template/ruin/station/forgottenship
	name = "SCSBC-12"
	description = "InteQ хотели бы напомнить своим сотрудникам, что любой линейный крейсер будет обслуживаться соответствующим образом, как и экипаж."
	prefix = "_maps/RandomRuins/SpaceRuins/BlueMoon/"
	suffix = "forgotten_ship.dmm"
	allow_duplicates = FALSE
	always_place = FALSE
	cost = 1000
	id = "forgottenship"

/datum/map_template/ruin/station/forgottenship/sol
	name = "SCSBC-13"
	description = "SolFed хотели бы напомнить своим сотрудникам, что любой линейный крейсер будет обслуживаться соответствующим образом, как и экипаж."
	prefix = "_maps/RandomRuins/SpaceRuins/BlueMoon/"
	suffix = "sol_ship.dmm"
	allow_duplicates = FALSE
	always_place = FALSE
	cost = 1000
	id = "forgottenship_sol"

/datum/map_template/ruin/space/forgottenship/nothing
	name = "SCSBC-14"
	description = "Nobody хотели бы напомнить своим сотрудникам, что любой линейный крейсер будет обслуживаться соответствующим образом, как и экипаж."
	prefix = "_maps/RandomRuins/SpaceRuins/BlueMoon/"
	suffix = "nothing_ship.dmm"
	allow_duplicates = FALSE
	always_place = TRUE
	id = "forgottenship_nothing"

/datum/map_template/ruin/space/abductorcrush
	name = "Crushed Abductor Ship"
	description = "Похоже, греи-похитители в этот раз не учли, что их цели похищения вполне способны дать отпор... И даже отследить неприятеля."
	prefix = "_maps/RandomRuins/SpaceRuins/BlueMoon/"
	suffix = "abductor_crushed.dmm"
	allow_duplicates = FALSE
	always_place = TRUE
	id = "abductorcrush"

/datum/map_template/ruin/space/allamericandiner
	name = "Space Cafe"
	description = "Космическое кафе. Ничего необычного"
	prefix = "_maps/RandomRuins/SpaceRuins/BlueMoon/"
	suffix = "allamericandiner.dmm"
	allow_duplicates = FALSE
	always_place = TRUE
	id = "allamericandiner"

/datum/map_template/ruin/space/anomaly_research
	name = "Anomaly Reserch"
	description = "Здесь изучали что то аномальное."
	prefix = "_maps/RandomRuins/SpaceRuins/BlueMoon/"
	suffix = "anomaly_research.dmm"
	allow_duplicates = FALSE
	always_place = TRUE
	id = "anomaly_research"

/datum/map_template/ruin/space/atmosasteroidruin
	name = "Atmo Asteroid"
	description = "Сварите темной материи. Чт?."
	prefix = "_maps/RandomRuins/SpaceRuins/BlueMoon/"
	suffix = "atmosasteroidruin.dmm"
	allow_duplicates = FALSE
	always_place = TRUE
	id = "atmosasteroidruin"

/datum/map_template/ruin/space/commsbuoy_nt
	name = "Comsboy"
	description = "Обнаружена незаонная трансляция фурри комиксов."
	prefix = "_maps/RandomRuins/SpaceRuins/BlueMoon/"
	suffix = "commsbuoy_nt.dmm"
	allow_duplicates = FALSE
	always_place = TRUE
	id = "commsbuoy_nt"

/datum/map_template/ruin/space/dangerous_research
	name = "Dangerous Research"
	description = "Мне кажеться здесь изучали что то плохое."
	prefix = "_maps/RandomRuins/SpaceRuins/BlueMoon/"
	suffix = "dangerous_research.dmm"
	allow_duplicates = FALSE
	always_place = TRUE
	id = "dangerous_research"

/datum/map_template/ruin/space/hilbertresearchfacility
	name = "Hilbertresearchfacility"
	description = "Was?."
	prefix = "_maps/RandomRuins/SpaceRuins/BlueMoon/"
	suffix = "hilbertresearchfacility.dmm"
	allow_duplicates = FALSE
	always_place = TRUE
	id = "hilbertresearchfacility"

/datum/map_template/ruin/space/Lutertenship
	name = "Lutertenship"
	description = "Мы вольные торговцы. Определенно."
	prefix = "_maps/RandomRuins/SpaceRuins/BlueMoon/"
	suffix = "Lutertenship.dmm"
	allow_duplicates = FALSE
	always_place = TRUE
	id = "Lutertenship"

/datum/map_template/ruin/space/piratefort
	name = "Piratefort"
	description = "Вы кто такие? Мы вас не звали. Идите нахуй."
	prefix = "_maps/RandomRuins/SpaceRuins/BlueMoon/"
	suffix = "piratefort.dmm"
	allow_duplicates = FALSE
	always_place = TRUE
	id = "piratefort"

/datum/map_template/ruin/space/whiteshipruin_box
	name = "Whiteshipruin Box"
	description = "Я не помню что тут."
	prefix = "_maps/RandomRuins/SpaceRuins/BlueMoon/"
	suffix = "whiteshipruin_box.dmm"
	allow_duplicates = FALSE
	always_place = TRUE
	id = "whiteshipruin_box"
