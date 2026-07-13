/turf/closed/mineral
	icon = 'modular_bluemoon/icons/turf/walls/smoothrocks.dmi'
	icon_state = "smoothrocks-0"
	smooth = SMOOTH_FALSE
	smoothing_flags = SMOOTH_BITMASK | SMOOTH_BORDER
	smoothing_groups = SMOOTH_GROUP_CLOSED_TURFS + SMOOTH_GROUP_MINERAL_WALLS
	canSmoothWith = SMOOTH_GROUP_MINERAL_WALLS
	base_icon_state = "smoothrocks"
	plane = GAME_PLANE
	var/wall_icon_state = "rock"

/turf/closed/mineral/Initialize(mapload)
	var/matrix/M = new
	M.Translate(-4, -4)
	transform = M
	. = ..()
	var/static/list/mutable_appearance/wall_overlays = list()
	var/mutable_appearance/wall_overlay = wall_overlays[wall_icon_state]
	if(!wall_overlay)
		wall_overlay = mutable_appearance('icons/turf/mining.dmi', wall_icon_state, appearance_flags = RESET_TRANSFORM)
		wall_overlays[wall_icon_state] = wall_overlay
	wall_overlay.plane = MUTATE_PLANE(WALL_PLANE, src)
	overlays += wall_overlay

/turf/closed/mineral/random/high_chance
	wall_icon_state = "rock_highchance"

/turf/closed/mineral/random/low_chance
	wall_icon_state = "rock_lowchance"

/turf/closed/mineral/random/labormineral
	wall_icon_state = "rock_labor"

/turf/closed/mineral/random/snow
	icon = 'modular_bluemoon/icons/turf/walls/mountain_wall.dmi'
	icon_state = "mountainrock"
	base_icon_state = "mountain_wall"
	smooth = SMOOTH_FALSE
	smoothing_flags = SMOOTH_BITMASK | SMOOTH_BORDER
	canSmoothWith = SMOOTH_GROUP_CLOSED_TURFS
	wall_icon_state = "mountainrock"

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
	wall_icon_state = "mountainrock"

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
	wall_icon_state = "icerock_iron"

/turf/closed/mineral/diamond/ice
	icon = 'modular_bluemoon/icons/turf/walls/icerock_wall.dmi'
	base_icon_state = "icerock_wall"
	smooth = SMOOTH_FALSE
	smoothing_flags = SMOOTH_BITMASK | SMOOTH_BORDER
	canSmoothWith = SMOOTH_GROUP_CLOSED_TURFS
	wall_icon_state = "icerock_diamond"

/turf/closed/mineral/plasma/ice
	icon = 'modular_bluemoon/icons/turf/walls/icerock_wall.dmi'
	base_icon_state = "icerock_wall"
	smooth = SMOOTH_FALSE
	smoothing_flags = SMOOTH_BITMASK | SMOOTH_BORDER
	canSmoothWith = SMOOTH_GROUP_CLOSED_TURFS
	wall_icon_state = "icerock_plasma"

/turf/closed/mineral/gibtonite/ice
	icon = 'modular_bluemoon/icons/turf/walls/icerock_wall.dmi'
	base_icon_state = "icerock_wall"
	smooth = SMOOTH_FALSE
	smoothing_flags = SMOOTH_BITMASK | SMOOTH_BORDER
	canSmoothWith = SMOOTH_GROUP_CLOSED_TURFS
	wall_icon_state = "icerock_Gibtonite"

/turf/closed/mineral/snowmountain
	icon = 'modular_bluemoon/icons/turf/walls/mountain_wall.dmi'
	icon_state = "mountainrock"
	base_icon_state = "mountain_wall"
	smooth = SMOOTH_FALSE
	smoothing_flags = SMOOTH_BITMASK | SMOOTH_BORDER
	canSmoothWith = SMOOTH_GROUP_CLOSED_TURFS
	wall_icon_state = "mountainrock"

/turf/closed/mineral/snowmountain/cavern
	icon = 'modular_bluemoon/icons/turf/walls/icerock_wall.dmi'
	icon_state = "icerock"
	base_icon_state = "icerock_wall"
	smooth = SMOOTH_FALSE
	smoothing_flags = SMOOTH_BITMASK | SMOOTH_BORDER
	canSmoothWith = SMOOTH_GROUP_CLOSED_TURFS
	wall_icon_state = "icerock"
