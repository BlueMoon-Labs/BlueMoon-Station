/obj/structure/falsewall
	icon = 'modular_bluemoon/icons/turf/false_walls.dmi'
	fake_icon = 'modular_bluemoon/icons/turf/walls/wall.dmi'
	canSmoothWith = SMOOTH_GROUP_AIRLOCK + SMOOTH_GROUP_WINDOW_FULLTILE + SMOOTH_GROUP_WALLS

/obj/structure/falsewall/reinforced
	fake_icon = 'modular_bluemoon/icons/turf/walls/reinforced_wall.dmi'
	canSmoothWith = SMOOTH_GROUP_AIRLOCK + SMOOTH_GROUP_WINDOW_FULLTILE + SMOOTH_GROUP_WALLS

/obj/structure/falsewall/abductor
	fake_icon = 'modular_bluemoon/icons/turf/walls/abductor_wall.dmi'
	canSmoothWith = SMOOTH_GROUP_AIRLOCK + SMOOTH_GROUP_WINDOW_FULLTILE + SMOOTH_GROUP_ABDUCTOR_WALLS + SMOOTH_GROUP_WALLS

/obj/structure/falsewall/bananium
	fake_icon = 'modular_bluemoon/icons/turf/walls/bananium_wall.dmi'
	canSmoothWith = SMOOTH_GROUP_AIRLOCK + SMOOTH_GROUP_WINDOW_FULLTILE + SMOOTH_GROUP_BANANIUM_WALLS + SMOOTH_GROUP_WALLS

/obj/structure/falsewall/diamond
	fake_icon = 'modular_bluemoon/icons/turf/walls/diamond_wall.dmi'
	canSmoothWith = SMOOTH_GROUP_AIRLOCK + SMOOTH_GROUP_WINDOW_FULLTILE + SMOOTH_GROUP_DIAMOND_WALLS + SMOOTH_GROUP_WALLS

/obj/structure/falsewall/gold
	fake_icon = 'modular_bluemoon/icons/turf/walls/gold_wall.dmi'
	canSmoothWith = SMOOTH_GROUP_AIRLOCK + SMOOTH_GROUP_WINDOW_FULLTILE + SMOOTH_GROUP_GOLD_WALLS + SMOOTH_GROUP_WALLS

/obj/structure/falsewall/iron
	fake_icon = 'modular_bluemoon/icons/turf/walls/iron_wall.dmi'
	canSmoothWith = SMOOTH_GROUP_AIRLOCK + SMOOTH_GROUP_WINDOW_FULLTILE + SMOOTH_GROUP_IRON_WALLS + SMOOTH_GROUP_WALLS

/obj/structure/falsewall/plasma
	fake_icon = 'modular_bluemoon/icons/turf/walls/plasma_wall.dmi'
	canSmoothWith = SMOOTH_GROUP_AIRLOCK + SMOOTH_GROUP_WINDOW_FULLTILE + SMOOTH_GROUP_PLASMA_WALLS + SMOOTH_GROUP_WALLS

/obj/structure/falsewall/plastitanium
	fake_icon = 'modular_bluemoon/icons/turf/walls/plastitanium_wall.dmi'
	canSmoothWith = SMOOTH_GROUP_AIRLOCK + SMOOTH_GROUP_WINDOW_FULLTILE + SMOOTH_GROUP_PLASTITANIUM_WALLS + SMOOTH_GROUP_WALLS

/obj/structure/falsewall/sandstone
	fake_icon = 'modular_bluemoon/icons/turf/walls/sandstone_wall.dmi'
	canSmoothWith = SMOOTH_GROUP_AIRLOCK + SMOOTH_GROUP_WINDOW_FULLTILE + SMOOTH_GROUP_SANDSTONE_WALLS + SMOOTH_GROUP_WALLS

/obj/structure/falsewall/titanium
	fake_icon = 'modular_bluemoon/icons/turf/walls/shuttle_wall.dmi'
	smoothing_groups = SMOOTH_GROUP_TITANIUM_WALLS + SMOOTH_GROUP_SHUTTLE_PARTS
	canSmoothWith = SMOOTH_GROUP_SHUTTLE_PARTS + SMOOTH_GROUP_AIRLOCK + SMOOTH_GROUP_TITANIUM_WALLS + SMOOTH_GROUP_WINDOW_FULLTILE_SHUTTLE

/obj/structure/falsewall/silver
	fake_icon = 'modular_bluemoon/icons/turf/walls/silver_wall.dmi'
	canSmoothWith = SMOOTH_GROUP_AIRLOCK + SMOOTH_GROUP_WINDOW_FULLTILE + SMOOTH_GROUP_SILVER_WALLS + SMOOTH_GROUP_WALLS

/obj/structure/falsewall/uranium
	fake_icon = 'modular_bluemoon/icons/turf/walls/uranium_wall.dmi'
	canSmoothWith = SMOOTH_GROUP_AIRLOCK + SMOOTH_GROUP_WINDOW_FULLTILE + SMOOTH_GROUP_URANIUM_WALLS + SMOOTH_GROUP_WALLS

/obj/structure/falsewall/wood
	fake_icon = 'modular_bluemoon/icons/turf/walls/wood_wall.dmi'
	canSmoothWith = SMOOTH_GROUP_AIRLOCK + SMOOTH_GROUP_WINDOW_FULLTILE + SMOOTH_GROUP_WOOD_WALLS + SMOOTH_GROUP_WALLS

/obj/structure/falsewall/brass
	fake_icon = 'modular_bluemoon/icons/turf/walls/clockwork_wall.dmi'
	smoothing_groups = SMOOTH_GROUP_CLOCKWORK_WALLS + SMOOTH_GROUP_WALLS
	canSmoothWith = SMOOTH_GROUP_CLOCKWORK_WALLS + SMOOTH_GROUP_WALLS

/obj/structure/falsewall/wood/shadow
	fake_icon = 'modular_splurt/icons/turf/walls/wall_shadow.dmi'
	canSmoothWith = SMOOTH_GROUP_WOOD_WALLS + SMOOTH_GROUP_WALLS

/obj/structure/falsewall/wood/mushroom
	fake_icon = 'modular_splurt/icons/turf/walls/wall_shadow.dmi'
	canSmoothWith = SMOOTH_GROUP_WOOD_WALLS + SMOOTH_GROUP_WALLS

/obj/structure/girder
	icon = 'modular_bluemoon/icons/obj/smooth_structures/girder.dmi'
	base_icon_state = "girder"
	icon_state = "girder-0"
	smooth = SMOOTH_FALSE
	smoothing_flags = SMOOTH_BITMASK | SMOOTH_OBJ
	smoothing_groups = SMOOTH_GROUP_GIRDER
	canSmoothWith = SMOOTH_GROUP_GIRDER + SMOOTH_GROUP_WALLS + SMOOTH_GROUP_CLOSED_TURFS

/obj/structure/girder/update_icon_state()
	if(smoothing_flags & USES_SMOOTHING)
		icon_state = "[base_icon_state]-[smoothing_junction]"
		return ..()
	return ..()

/obj/structure/girder/update_overlays(updates = ALL)
	. = ..()
	if(smoothing_flags & USES_SMOOTHING)
		QUEUE_SMOOTH(src)

/obj/structure/girder/reinforced
	icon = 'icons/obj/smooth_structures/reinforced_girder.dmi'
	base_icon_state = "reinforced"
	icon_state = "reinforced-0"
	smoothing_flags = SMOOTH_BITMASK | SMOOTH_OBJ

/obj/structure/girder/displaced
	icon_state = "displaced"
	smooth = SMOOTH_FALSE
	smoothing_flags = NONE
	smoothing_groups = NONE
	canSmoothWith = null

/obj/structure/girder/reinforced/displaced
	icon = 'icons/obj/smooth_structures/reinforced_girder.dmi'
	icon_state = "displaced"
	smooth = SMOOTH_FALSE
	smoothing_flags = NONE
	smoothing_groups = NONE
	canSmoothWith = null
