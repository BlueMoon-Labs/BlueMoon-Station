/turf/closed/wall
	icon = 'modular_bluemoon/icons/turf/walls/wall.dmi'
	icon_state = "wall-0"
	base_icon_state = "wall"
	smooth = SMOOTH_FALSE
	smoothing_flags = SMOOTH_BITMASK | SMOOTH_OBJ
	smoothing_groups = SMOOTH_GROUP_WALLS + SMOOTH_GROUP_CLOSED_TURFS
	canSmoothWith = SMOOTH_GROUP_AIRLOCK + SMOOTH_GROUP_WINDOW_FULLTILE + SMOOTH_GROUP_WALLS + SMOOTH_GROUP_CLOSED_TURFS

/turf/closed/wall/update_icon_state()
	if(smoothing_flags & USES_SMOOTHING)
		if(smoothing_flags & SMOOTH_DIAGONAL_CORNERS)
			set_smoothed_icon_state(smoothing_junction)
		else
			icon_state = "[base_icon_state]-[smoothing_junction]"
		return ..()
	return ..()

/turf/closed/wall/rust
	icon = 'modular_bluemoon/icons/turf/walls/wall.dmi'
	canSmoothWith = SMOOTH_GROUP_AIRLOCK + SMOOTH_GROUP_WINDOW_FULLTILE + SMOOTH_GROUP_WALLS + SMOOTH_GROUP_CLOSED_TURFS

/turf/closed/wall/r_wall
	icon = 'modular_bluemoon/icons/turf/walls/reinforced_wall.dmi'
	icon_state = "reinforced_wall-0"
	base_icon_state = "reinforced_wall"
	smooth = SMOOTH_FALSE
	smoothing_flags = SMOOTH_BITMASK | SMOOTH_OBJ
	smoothing_groups = SMOOTH_GROUP_WALLS + SMOOTH_GROUP_CLOSED_TURFS
	canSmoothWith = SMOOTH_GROUP_AIRLOCK + SMOOTH_GROUP_WINDOW_FULLTILE + SMOOTH_GROUP_WALLS + SMOOTH_GROUP_CLOSED_TURFS
	var/base_decon_state = "r_wall"

/turf/closed/wall/r_wall/rust
	icon = 'modular_bluemoon/icons/turf/walls/reinforced_wall.dmi'
	canSmoothWith = SMOOTH_GROUP_AIRLOCK + SMOOTH_GROUP_WINDOW_FULLTILE + SMOOTH_GROUP_WALLS + SMOOTH_GROUP_CLOSED_TURFS

/turf/closed/wall/mineral
	smooth = SMOOTH_FALSE
	smoothing_flags = SMOOTH_BITMASK | SMOOTH_OBJ
	smoothing_groups = SMOOTH_GROUP_WALLS + SMOOTH_GROUP_CLOSED_TURFS
	canSmoothWith = SMOOTH_GROUP_AIRLOCK + SMOOTH_GROUP_WINDOW_FULLTILE + SMOOTH_GROUP_WALLS + SMOOTH_GROUP_CLOSED_TURFS

/turf/closed/wall/material
	icon = 'modular_bluemoon/icons/turf/walls/material_wall.dmi'
	icon_state = "material_wall-0"
	base_icon_state = "material_wall"
	canSmoothWith = SMOOTH_GROUP_AIRLOCK + SMOOTH_GROUP_WINDOW_FULLTILE + SMOOTH_GROUP_WALLS + SMOOTH_GROUP_CLOSED_TURFS + SMOOTH_GROUP_MATERIAL_WALLS

/turf/closed/wall/mineral/gold
	icon = 'modular_bluemoon/icons/turf/walls/gold_wall.dmi'
	icon_state = "gold_wall-0"
	base_icon_state = "gold_wall"
	smoothing_groups = SMOOTH_GROUP_GOLD_WALLS + SMOOTH_GROUP_WALLS + SMOOTH_GROUP_CLOSED_TURFS
	canSmoothWith = SMOOTH_GROUP_AIRLOCK + SMOOTH_GROUP_WINDOW_FULLTILE + SMOOTH_GROUP_GOLD_WALLS + SMOOTH_GROUP_WALLS

/turf/closed/wall/mineral/silver
	icon = 'modular_bluemoon/icons/turf/walls/silver_wall.dmi'
	icon_state = "silver_wall-0"
	base_icon_state = "silver_wall"
	smoothing_groups = SMOOTH_GROUP_SILVER_WALLS + SMOOTH_GROUP_WALLS + SMOOTH_GROUP_CLOSED_TURFS
	canSmoothWith = SMOOTH_GROUP_AIRLOCK + SMOOTH_GROUP_WINDOW_FULLTILE + SMOOTH_GROUP_SILVER_WALLS + SMOOTH_GROUP_WALLS

/turf/closed/wall/mineral/diamond
	icon = 'modular_bluemoon/icons/turf/walls/diamond_wall.dmi'
	icon_state = "diamond_wall-0"
	base_icon_state = "diamond_wall"
	smoothing_groups = SMOOTH_GROUP_DIAMOND_WALLS + SMOOTH_GROUP_WALLS + SMOOTH_GROUP_CLOSED_TURFS
	canSmoothWith = SMOOTH_GROUP_AIRLOCK + SMOOTH_GROUP_WINDOW_FULLTILE + SMOOTH_GROUP_DIAMOND_WALLS + SMOOTH_GROUP_WALLS

/turf/closed/wall/mineral/bananium
	icon = 'modular_bluemoon/icons/turf/walls/bananium_wall.dmi'
	icon_state = "bananium_wall-0"
	base_icon_state = "bananium_wall"
	smoothing_groups = SMOOTH_GROUP_BANANIUM_WALLS + SMOOTH_GROUP_WALLS + SMOOTH_GROUP_CLOSED_TURFS
	canSmoothWith = SMOOTH_GROUP_AIRLOCK + SMOOTH_GROUP_WINDOW_FULLTILE + SMOOTH_GROUP_BANANIUM_WALLS + SMOOTH_GROUP_WALLS

/turf/closed/wall/mineral/uranium
	icon = 'modular_bluemoon/icons/turf/walls/uranium_wall.dmi'
	icon_state = "uranium_wall-0"
	base_icon_state = "uranium_wall"
	smoothing_groups = SMOOTH_GROUP_URANIUM_WALLS + SMOOTH_GROUP_WALLS + SMOOTH_GROUP_CLOSED_TURFS
	canSmoothWith = SMOOTH_GROUP_AIRLOCK + SMOOTH_GROUP_WINDOW_FULLTILE + SMOOTH_GROUP_URANIUM_WALLS + SMOOTH_GROUP_WALLS

/turf/closed/wall/mineral/plasma
	icon = 'modular_bluemoon/icons/turf/walls/plasma_wall.dmi'
	icon_state = "plasma_wall-0"
	base_icon_state = "plasma_wall"
	smoothing_groups = SMOOTH_GROUP_PLASMA_WALLS + SMOOTH_GROUP_WALLS + SMOOTH_GROUP_CLOSED_TURFS
	canSmoothWith = SMOOTH_GROUP_AIRLOCK + SMOOTH_GROUP_WINDOW_FULLTILE + SMOOTH_GROUP_PLASMA_WALLS + SMOOTH_GROUP_WALLS

/turf/closed/wall/mineral/iron
	icon = 'modular_bluemoon/icons/turf/walls/iron_wall.dmi'
	icon_state = "iron_wall-0"
	base_icon_state = "iron_wall"
	smoothing_groups = SMOOTH_GROUP_IRON_WALLS + SMOOTH_GROUP_WALLS + SMOOTH_GROUP_CLOSED_TURFS
	canSmoothWith = SMOOTH_GROUP_AIRLOCK + SMOOTH_GROUP_WINDOW_FULLTILE + SMOOTH_GROUP_IRON_WALLS + SMOOTH_GROUP_WALLS

/turf/closed/wall/mineral/sandstone
	icon = 'modular_bluemoon/icons/turf/walls/sandstone_wall.dmi'
	icon_state = "sandstone_wall-0"
	base_icon_state = "sandstone_wall"
	smoothing_groups = SMOOTH_GROUP_SANDSTONE_WALLS + SMOOTH_GROUP_WALLS + SMOOTH_GROUP_CLOSED_TURFS
	canSmoothWith = SMOOTH_GROUP_AIRLOCK + SMOOTH_GROUP_WINDOW_FULLTILE + SMOOTH_GROUP_SANDSTONE_WALLS + SMOOTH_GROUP_WALLS

/turf/closed/wall/mineral/snow
	icon = 'modular_bluemoon/icons/turf/walls/snow_wall.dmi'
	icon_state = "snow_wall-0"
	base_icon_state = "snow_wall"
	smoothing_groups = SMOOTH_GROUP_SNOW_WALLS + SMOOTH_GROUP_WALLS + SMOOTH_GROUP_CLOSED_TURFS
	canSmoothWith = SMOOTH_GROUP_SNOW_WALLS + SMOOTH_GROUP_AIRLOCK + SMOOTH_GROUP_WINDOW_FULLTILE + SMOOTH_GROUP_WALLS

/turf/closed/wall/mineral/wood
	icon = 'modular_bluemoon/icons/turf/walls/wood_wall.dmi'
	icon_state = "wood_wall-0"
	base_icon_state = "wood_wall"
	smoothing_groups = SMOOTH_GROUP_WOOD_WALLS + SMOOTH_GROUP_WALLS + SMOOTH_GROUP_CLOSED_TURFS
	canSmoothWith = SMOOTH_GROUP_AIRLOCK + SMOOTH_GROUP_WINDOW_FULLTILE + SMOOTH_GROUP_WOOD_WALLS + SMOOTH_GROUP_WALLS

/turf/closed/wall/mineral/wood/nonmetal
	smoothing_groups = SMOOTH_GROUP_WOOD_WALLS + SMOOTH_GROUP_WALLS + SMOOTH_GROUP_CLOSED_TURFS
	canSmoothWith = SMOOTH_GROUP_AIRLOCK + SMOOTH_GROUP_WINDOW_FULLTILE + SMOOTH_GROUP_WOOD_WALLS + SMOOTH_GROUP_WALLS

/turf/closed/wall/mineral/titanium
	icon = 'modular_bluemoon/icons/turf/walls/shuttle_wall.dmi'
	icon_state = "shuttle_wall-0"
	base_icon_state = "shuttle_wall"
	smooth = SMOOTH_FALSE
	smoothing_flags = SMOOTH_BITMASK | SMOOTH_OBJ | SMOOTH_DIAGONAL_CORNERS
	smoothing_groups = SMOOTH_GROUP_TITANIUM_WALLS + SMOOTH_GROUP_SHUTTLE_PARTS
	canSmoothWith = SMOOTH_GROUP_SHUTTLE_PARTS + SMOOTH_GROUP_AIRLOCK + SMOOTH_GROUP_TITANIUM_WALLS + SMOOTH_GROUP_WINDOW_FULLTILE_SHUTTLE

/turf/closed/wall/mineral/titanium/nodiagonal
	smooth = SMOOTH_FALSE
	smoothing_flags = SMOOTH_BITMASK | SMOOTH_OBJ
	icon_state = "shuttle_wall-0"

/turf/closed/wall/mineral/titanium/nosmooth
	smooth = SMOOTH_FALSE
	smoothing_flags = NONE

/turf/closed/wall/mineral/titanium/overspace
	smooth = SMOOTH_FALSE

/turf/closed/wall/mineral/titanium/interior
	smooth = SMOOTH_FALSE

/turf/closed/wall/mineral/plastitanium
	icon = 'modular_bluemoon/icons/turf/walls/plastitanium_wall.dmi'
	icon_state = "plastitanium_wall-0"
	base_icon_state = "plastitanium_wall"
	smooth = SMOOTH_FALSE
	smoothing_flags = SMOOTH_BITMASK | SMOOTH_OBJ | SMOOTH_DIAGONAL_CORNERS
	smoothing_groups = SMOOTH_GROUP_PLASTITANIUM_WALLS + SMOOTH_GROUP_WALLS + SMOOTH_GROUP_CLOSED_TURFS
	canSmoothWith = SMOOTH_GROUP_SHUTTLE_PARTS + SMOOTH_GROUP_AIRLOCK + SMOOTH_GROUP_WINDOW_FULLTILE_PLASTITANIUM + SMOOTH_GROUP_WINDOW_FULLTILE + SMOOTH_GROUP_PLASTITANIUM_WALLS + SMOOTH_GROUP_WALLS + SMOOTH_GROUP_CLOSED_TURFS

/turf/closed/wall/mineral/plastitanium/nodiagonal
	smooth = SMOOTH_FALSE
	smoothing_flags = SMOOTH_BITMASK | SMOOTH_OBJ
	icon_state = "plastitanium_wall-0"

/turf/closed/wall/mineral/plastitanium/nosmooth
	smooth = SMOOTH_FALSE
	smoothing_flags = NONE

/turf/closed/wall/mineral/titanium/survival
	icon = 'modular_bluemoon/icons/turf/walls/survival_pod_walls.dmi'
	icon_state = "survival_pod_walls-0"
	base_icon_state = "survival_pod_walls"
	smooth = SMOOTH_FALSE
	smoothing_flags = SMOOTH_BITMASK | SMOOTH_OBJ | SMOOTH_DIAGONAL_CORNERS
	smoothing_groups = SMOOTH_GROUP_TITANIUM_WALLS + SMOOTH_GROUP_SHUTTLE_PARTS
	canSmoothWith = SMOOTH_GROUP_SHUTTLE_PARTS + SMOOTH_GROUP_AIRLOCK + SMOOTH_GROUP_WINDOW_FULLTILE_SHUTTLE + SMOOTH_GROUP_TITANIUM_WALLS

/turf/closed/wall/mineral/titanium/survival/nodiagonal
	smooth = SMOOTH_FALSE
	smoothing_flags = SMOOTH_BITMASK | SMOOTH_OBJ
	icon_state = "survival_pod_walls-0"

/turf/closed/wall/mineral/titanium/survival/pod
	smoothing_groups = SMOOTH_GROUP_SURVIVAL_TITANIUM_POD + SMOOTH_GROUP_TITANIUM_WALLS
	canSmoothWith = SMOOTH_GROUP_SURVIVAL_TITANIUM_POD + SMOOTH_GROUP_TITANIUM_WALLS + SMOOTH_GROUP_WINDOW_FULLTILE_SHUTTLE

/turf/closed/wall/mineral/abductor
	icon = 'modular_bluemoon/icons/turf/walls/abductor_wall.dmi'
	icon_state = "abductor_wall-0"
	base_icon_state = "abductor_wall"
	smoothing_groups = SMOOTH_GROUP_ABDUCTOR_WALLS + SMOOTH_GROUP_WALLS + SMOOTH_GROUP_CLOSED_TURFS
	canSmoothWith = SMOOTH_GROUP_AIRLOCK + SMOOTH_GROUP_WINDOW_FULLTILE + SMOOTH_GROUP_ABDUCTOR_WALLS + SMOOTH_GROUP_WALLS

/turf/closed/wall/mineral/cult
	icon = 'modular_bluemoon/icons/turf/walls/cult_wall.dmi'
	icon_state = "cult_wall-0"
	base_icon_state = "cult_wall"
	smooth = SMOOTH_FALSE
	smoothing_flags = SMOOTH_BITMASK | SMOOTH_OBJ
	smoothing_groups = SMOOTH_GROUP_CULT_WALLS + SMOOTH_GROUP_WALLS + SMOOTH_GROUP_CLOSED_TURFS
	canSmoothWith = SMOOTH_GROUP_AIRLOCK + SMOOTH_GROUP_WINDOW_FULLTILE + SMOOTH_GROUP_CULT_WALLS + SMOOTH_GROUP_WALLS + SMOOTH_GROUP_CLOSED_TURFS

/turf/closed/wall/clockwork
	icon = 'modular_bluemoon/icons/turf/walls/clockwork_wall.dmi'
	icon_state = "clockwork_wall-0"
	base_icon_state = "clockwork_wall"
	smooth = SMOOTH_FALSE
	smoothing_flags = SMOOTH_BITMASK | SMOOTH_OBJ
	smoothing_groups = SMOOTH_GROUP_CLOCKWORK_WALLS + SMOOTH_GROUP_WALLS + SMOOTH_GROUP_CLOSED_TURFS
	canSmoothWith = SMOOTH_GROUP_CLOCKWORK_WALLS + SMOOTH_GROUP_WALLS

/turf/closed/wall/r_wall/plastitanium
	icon = 'modular_bluemoon/icons/turf/walls/plastitanium_wall.dmi'
	icon_state = "plastitanium_wall-0"
	base_icon_state = "plastitanium_wall"
	smooth = SMOOTH_FALSE
	smoothing_flags = SMOOTH_BITMASK | SMOOTH_OBJ | SMOOTH_DIAGONAL_CORNERS
	smoothing_groups = SMOOTH_GROUP_PLASTITANIUM_WALLS + SMOOTH_GROUP_SHUTTLE_PARTS
	canSmoothWith = SMOOTH_GROUP_SHUTTLE_PARTS + SMOOTH_GROUP_AIRLOCK + SMOOTH_GROUP_WINDOW_FULLTILE_PLASTITANIUM + SMOOTH_GROUP_PLASTITANIUM_WALLS

/turf/closed/wall/r_wall/plastitanium/nodiagonal
	smooth = SMOOTH_FALSE
	smoothing_flags = SMOOTH_BITMASK | SMOOTH_OBJ
	icon_state = "plastitanium_wall-0"

/turf/closed/wall/r_wall/plastitanium/overspace
	icon = 'icons/turf/walls/misc_wall.dmi'
	icon_state = "plastitanium_overspace"
	smooth = SMOOTH_FALSE
	smoothing_flags = NONE
	fixed_underlay = list("space" = TRUE)

/turf/closed/wall/r_wall/plastitanium/syndicate
	smoothing_groups = SMOOTH_GROUP_PLASTITANIUM_WALLS + SMOOTH_GROUP_SYNDICATE_WALLS + SMOOTH_GROUP_SHUTTLE_PARTS
	canSmoothWith = SMOOTH_GROUP_SHUTTLE_PARTS + SMOOTH_GROUP_AIRLOCK + SMOOTH_GROUP_WINDOW_FULLTILE_PLASTITANIUM + SMOOTH_GROUP_PLASTITANIUM_WALLS + SMOOTH_GROUP_SYNDICATE_WALLS

/turf/closed/wall/r_wall/plastitanium/syndicate/nodiagonal
	smooth = SMOOTH_FALSE
	smoothing_flags = SMOOTH_BITMASK | SMOOTH_OBJ
	icon_state = "plastitanium_wall-0"

/turf/closed/wall/r_wall/plastitanium/syndicate/overspace
	icon = 'icons/turf/walls/misc_wall.dmi'
	icon_state = "plastitanium_overspace"
	smooth = SMOOTH_FALSE
	smoothing_flags = NONE
	fixed_underlay = list("space" = TRUE)

/turf/closed/wall/r_wall/syndicate
	icon = 'modular_bluemoon/icons/turf/walls/plastitanium_wall.dmi'
	icon_state = "plastitanium_wall-0"
	base_icon_state = "plastitanium_wall"
	smooth = SMOOTH_FALSE
	smoothing_flags = SMOOTH_BITMASK | SMOOTH_OBJ | SMOOTH_DIAGONAL_CORNERS
	smoothing_groups = SMOOTH_GROUP_PLASTITANIUM_WALLS + SMOOTH_GROUP_SYNDICATE_WALLS + SMOOTH_GROUP_SHUTTLE_PARTS
	canSmoothWith = SMOOTH_GROUP_SHUTTLE_PARTS + SMOOTH_GROUP_AIRLOCK + SMOOTH_GROUP_WINDOW_FULLTILE_PLASTITANIUM + SMOOTH_GROUP_PLASTITANIUM_WALLS + SMOOTH_GROUP_SYNDICATE_WALLS

/turf/closed/wall/r_wall/syndicate/nodiagonal
	smooth = SMOOTH_FALSE
	smoothing_flags = SMOOTH_BITMASK | SMOOTH_OBJ
	icon_state = "plastitanium_wall-0"

/turf/closed/wall/r_wall/syndicate/nosmooth
	icon = 'icons/turf/shuttle.dmi'
	icon_state = "wall"
	smooth = SMOOTH_FALSE
	smoothing_flags = NONE

/turf/closed/wall/r_wall/syndicate/overspace
	icon = 'icons/turf/walls/misc_wall.dmi'
	icon_state = "plastitanium_overspace"
	smooth = SMOOTH_FALSE
	smoothing_flags = NONE
	fixed_underlay = list("space" = TRUE)

/turf/closed/wall/r_wall/syndicate/pirate
	smoothing_groups = SMOOTH_GROUP_PLASTITANIUM_WALLS + SMOOTH_GROUP_SYNDICATE_WALLS + SMOOTH_GROUP_SHUTTLE_PARTS
	canSmoothWith = SMOOTH_GROUP_SHUTTLE_PARTS + SMOOTH_GROUP_AIRLOCK + SMOOTH_GROUP_WINDOW_FULLTILE_PLASTITANIUM + SMOOTH_GROUP_PLASTITANIUM_WALLS + SMOOTH_GROUP_SYNDICATE_WALLS

/turf/closed/wall/r_wall/syndicate/pirate/nodiagonal
	smooth = SMOOTH_FALSE
	smoothing_flags = SMOOTH_BITMASK | SMOOTH_OBJ
	icon_state = "plastitanium_wall-0"

/turf/closed/wall/r_wall/syndicate/pirate/nosmooth
	icon = 'icons/turf/shuttle.dmi'
	icon_state = "wall"
	smooth = SMOOTH_FALSE
	smoothing_flags = NONE

/turf/closed/wall/r_wall/syndicate/pirate/overspace
	icon = 'icons/turf/walls/misc_wall.dmi'
	icon_state = "plastitanium_overspace"
	smooth = SMOOTH_FALSE
	smoothing_flags = NONE
	fixed_underlay = list("space" = TRUE)

/turf/closed/indestructible/reinforced
	icon = 'modular_bluemoon/icons/turf/walls/reinforced_wall.dmi'
	icon_state = "reinforced_wall-0"
	base_icon_state = "reinforced_wall"
	smooth = SMOOTH_FALSE
	smoothing_flags = SMOOTH_BITMASK | SMOOTH_OBJ
	smoothing_groups = SMOOTH_GROUP_WALLS + SMOOTH_GROUP_CLOSED_TURFS
	canSmoothWith = SMOOTH_GROUP_AIRLOCK + SMOOTH_GROUP_WINDOW_FULLTILE + SMOOTH_GROUP_WALLS + SMOOTH_GROUP_CLOSED_TURFS

/turf/closed/indestructible/wood
	icon = 'modular_bluemoon/icons/turf/walls/wood_wall.dmi'
	icon_state = "wood_wall-0"
	base_icon_state = "wood_wall"
	smooth = SMOOTH_FALSE
	smoothing_flags = SMOOTH_BITMASK | SMOOTH_OBJ
	smoothing_groups = SMOOTH_GROUP_WOOD_WALLS
	canSmoothWith = SMOOTH_GROUP_AIRLOCK + SMOOTH_GROUP_WINDOW_FULLTILE + SMOOTH_GROUP_WOOD_WALLS

/turf/closed/indestructible/sandstone
	icon = 'modular_bluemoon/icons/turf/walls/sandstone_wall.dmi'
	icon_state = "sandstone_wall-0"
	base_icon_state = "sandstone_wall"
	smoothing_groups = SMOOTH_GROUP_SANDSTONE_WALLS + SMOOTH_GROUP_WALLS + SMOOTH_GROUP_CLOSED_TURFS
	canSmoothWith = SMOOTH_GROUP_AIRLOCK + SMOOTH_GROUP_WINDOW_FULLTILE + SMOOTH_GROUP_SANDSTONE_WALLS + SMOOTH_GROUP_WALLS

/turf/closed/indestructible/alien
	icon = 'modular_bluemoon/icons/turf/walls/abductor_wall.dmi'
	icon_state = "abductor_wall-0"
	base_icon_state = "abductor_wall"
	canSmoothWith = SMOOTH_GROUP_AIRLOCK + SMOOTH_GROUP_WINDOW_FULLTILE + SMOOTH_GROUP_ABDUCTOR_WALLS + SMOOTH_GROUP_WALLS

/turf/closed/indestructible/titanium
	icon = 'modular_bluemoon/icons/turf/walls/shuttle_wall.dmi'
	icon_state = "shuttle_wall-0"
	base_icon_state = "shuttle_wall"
	smoothing_groups = SMOOTH_GROUP_TITANIUM_WALLS + SMOOTH_GROUP_SHUTTLE_PARTS
	canSmoothWith = SMOOTH_GROUP_SHUTTLE_PARTS + SMOOTH_GROUP_AIRLOCK + SMOOTH_GROUP_TITANIUM_WALLS + SMOOTH_GROUP_WINDOW_FULLTILE_SHUTTLE

/turf/closed/indestructible/syndicate
	icon = 'modular_bluemoon/icons/turf/walls/plastitanium_wall.dmi'
	icon_state = "plastitanium_wall-0"
	base_icon_state = "plastitanium_wall"
	smooth = SMOOTH_FALSE
	smoothing_flags = SMOOTH_BITMASK | SMOOTH_OBJ | SMOOTH_DIAGONAL_CORNERS
	smoothing_groups = SMOOTH_GROUP_PLASTITANIUM_WALLS + SMOOTH_GROUP_SYNDICATE_WALLS + SMOOTH_GROUP_SHUTTLE_PARTS
	canSmoothWith = SMOOTH_GROUP_SHUTTLE_PARTS + SMOOTH_GROUP_AIRLOCK + SMOOTH_GROUP_WINDOW_FULLTILE_PLASTITANIUM + SMOOTH_GROUP_PLASTITANIUM_WALLS + SMOOTH_GROUP_SYNDICATE_WALLS
