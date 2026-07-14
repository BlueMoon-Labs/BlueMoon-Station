/turf/closed/mineral
	icon = 'modular_bluemoon/icons/turf/walls/smoothrocks.dmi'
	icon_state = "smoothrocks-0"
	luminosity = 0
	smooth = SMOOTH_FALSE
	smoothing_flags = SMOOTH_BITMASK | SMOOTH_BORDER
	smoothing_groups = SMOOTH_GROUP_CLOSED_TURFS + SMOOTH_GROUP_MINERAL_WALLS
	canSmoothWith = SMOOTH_GROUP_MINERAL_WALLS
	base_icon_state = "smoothrocks"

/turf/closed/mineral/random/high_chance

/turf/closed/mineral/random/low_chance

/turf/closed/mineral/random/labormineral

/turf/closed/mineral/random/snow
	icon = 'modular_bluemoon/icons/turf/walls/mountain_wall.dmi'
	icon_state = "mountainrock"
	base_icon_state = "mountain_wall"
	smooth = SMOOTH_FALSE
	smoothing_flags = SMOOTH_BITMASK | SMOOTH_BORDER
	canSmoothWith = SMOOTH_GROUP_CLOSED_TURFS

/turf/closed/mineral/random/snow/Change_Ore(ore_type, random = 0)
	. = ..()
	if(mineralType)
		icon = 'modular_bluemoon/icons/turf/walls/icerock_wall.dmi'
		icon_state = "icerock_wall-0"
		base_icon_state = "icerock_wall"
		smoothing_flags = SMOOTH_BITMASK | SMOOTH_BORDER
		canSmoothWith = SMOOTH_GROUP_CLOSED_TURFS
		smooth = SMOOTH_FALSE
		QUEUE_SMOOTH(src)

/turf/closed/mineral/random/labormineral/ice
	icon = 'modular_bluemoon/icons/turf/walls/mountain_wall.dmi'
	icon_state = "mountainrock"
	base_icon_state = "mountain_wall"
	smooth = SMOOTH_FALSE
	smoothing_flags = SMOOTH_BITMASK | SMOOTH_BORDER
	canSmoothWith = SMOOTH_GROUP_CLOSED_TURFS

/turf/closed/mineral/random/labormineral/ice/Change_Ore(ore_type, random = 0)
	. = ..()
	if(mineralType)
		icon = 'modular_bluemoon/icons/turf/walls/icerock_wall.dmi'
		icon_state = "icerock_wall-0"
		base_icon_state = "icerock_wall"
		smoothing_flags = SMOOTH_BITMASK | SMOOTH_BORDER
		canSmoothWith = SMOOTH_GROUP_CLOSED_TURFS
		smooth = SMOOTH_FALSE
		QUEUE_SMOOTH(src)

/turf/closed/mineral/iron/ice
	icon = 'modular_bluemoon/icons/turf/walls/icerock_wall.dmi'
	base_icon_state = "icerock_wall"
	smooth = SMOOTH_FALSE
	smoothing_flags = SMOOTH_BITMASK | SMOOTH_BORDER
	canSmoothWith = SMOOTH_GROUP_CLOSED_TURFS

/turf/closed/mineral/diamond/ice
	icon = 'modular_bluemoon/icons/turf/walls/icerock_wall.dmi'
	base_icon_state = "icerock_wall"
	smooth = SMOOTH_FALSE
	smoothing_flags = SMOOTH_BITMASK | SMOOTH_BORDER
	canSmoothWith = SMOOTH_GROUP_CLOSED_TURFS

/turf/closed/mineral/plasma/ice
	icon = 'modular_bluemoon/icons/turf/walls/icerock_wall.dmi'
	base_icon_state = "icerock_wall"
	smooth = SMOOTH_FALSE
	smoothing_flags = SMOOTH_BITMASK | SMOOTH_BORDER
	canSmoothWith = SMOOTH_GROUP_CLOSED_TURFS

/turf/closed/mineral/gibtonite/ice
	icon = 'modular_bluemoon/icons/turf/walls/icerock_wall.dmi'
	base_icon_state = "icerock_wall"
	smooth = SMOOTH_FALSE
	smoothing_flags = SMOOTH_BITMASK | SMOOTH_BORDER
	canSmoothWith = SMOOTH_GROUP_CLOSED_TURFS

/turf/closed/mineral/snowmountain
	icon = 'modular_bluemoon/icons/turf/walls/mountain_wall.dmi'
	icon_state = "mountainrock"
	base_icon_state = "mountain_wall"
	smooth = SMOOTH_FALSE
	smoothing_flags = SMOOTH_BITMASK | SMOOTH_BORDER
	canSmoothWith = SMOOTH_GROUP_CLOSED_TURFS

/turf/closed/mineral/snowmountain/cavern
	icon = 'modular_bluemoon/icons/turf/walls/icerock_wall.dmi'
	icon_state = "icerock"
	base_icon_state = "icerock_wall"
	smooth = SMOOTH_FALSE
	smoothing_flags = SMOOTH_BITMASK | SMOOTH_BORDER
	canSmoothWith = SMOOTH_GROUP_CLOSED_TURFS

/turf/closed/indestructible/rock
	icon = 'modular_bluemoon/icons/turf/walls/smoothrocks.dmi'
	icon_state = "smoothrocks-0"
	base_icon_state = "smoothrocks"
	smooth = SMOOTH_FALSE
	smoothing_flags = SMOOTH_BITMASK | SMOOTH_BORDER
	smoothing_groups = SMOOTH_GROUP_CLOSED_TURFS + SMOOTH_GROUP_MINERAL_WALLS
	canSmoothWith = SMOOTH_GROUP_MINERAL_WALLS

/turf/closed/indestructible/rock/snow
	icon = 'modular_bluemoon/icons/turf/walls/mountain_wall.dmi'
	icon_state = "mountain_wall-0"
	base_icon_state = "mountain_wall"
	smooth = SMOOTH_FALSE
	smoothing_flags = SMOOTH_BITMASK | SMOOTH_BORDER
	canSmoothWith = SMOOTH_GROUP_CLOSED_TURFS

/turf/closed/indestructible/rock/snow/ice
	icon = 'modular_bluemoon/icons/turf/walls/icerock_wall.dmi'
	icon_state = "icerock_wall-0"
	base_icon_state = "icerock_wall"
	smooth = SMOOTH_FALSE
	smoothing_flags = SMOOTH_BITMASK | SMOOTH_BORDER
	canSmoothWith = SMOOTH_GROUP_CLOSED_TURFS

/turf/closed/indestructible/rock/snow/ice/ore
	icon = 'modular_bluemoon/icons/turf/walls/icerock_wall.dmi'
