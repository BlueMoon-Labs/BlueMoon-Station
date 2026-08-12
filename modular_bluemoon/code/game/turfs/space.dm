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
	// This 299 KiB DMM is deliberately loaded one minute into the round. Template
	// construction already parses it during mapping init, so keep that result instead
	// of repeating the expensive parse while clients are playing.
	keep_cached_map = TRUE

/datum/map_template/ruin/station/forgottenship/New()
	. = ..()
	// build_cache() is the second CPU-heavy text phase normally deferred until
	// load(). The cache is mode-independent (see build_cache()), so this one eager
	// build serves the +60s late load no matter what state SSatoms is in by then.
	cached_map?.build_cache()

/datum/map_template/ruin/station/forgottenship/load(turf/T, centered = FALSE, orientation = SOUTH, annihilate = default_annihilate, force_cache = FALSE, rotate_placement_to_orientation = FALSE)
	. = ..()
	// The retained parse exists to survive until this one late load. The landmark
	// makes exactly one attempt and qdels itself right after, so there is no retry
	// to keep the parse for: release it once the attempt is over whether or not
	// placement succeeded, or a failed load (say, the landmark ending up too close
	// to the world edge after a map edit) would strand the quarter-megabyte DMM
	// and its model cache for the rest of the round with no possible consumer.
	if(!force_cache)
		cached_map = null

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
