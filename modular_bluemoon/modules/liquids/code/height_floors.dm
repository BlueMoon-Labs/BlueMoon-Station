/obj/item/stack/tile/plasteel/elevated
	name = "elevated floor tile"
	singular_name = "elevated floor tile"
	turf_type = /turf/open/floor/plasteel/elevated

/obj/item/stack/tile/plasteel/lowered
	name = "lowered floor tile"
	singular_name = "lowered floor tile"
	turf_type = /turf/open/floor/plasteel/lowered

/obj/item/stack/tile/plasteel/pool
	name = "pool floor tile"
	singular_name = "pool floor tile"
	turf_type = /turf/open/floor/plasteel/pool
	tile_reskin_types = list(
		/obj/item/stack/tile/plasteel/pool,
		/obj/item/stack/tile/plasteel/pool/cobble,
		/obj/item/stack/tile/plasteel/pool/cobble/side,
		/obj/item/stack/tile/plasteel/pool/cobble/corner
	)

/obj/item/stack/tile/plasteel/pool/cobble
	name = "cobblestone pool floor tile"
	singular_name = "cobblestone pool floor tile"
	turf_type = /turf/open/floor/plasteel/pool/cobble

/obj/item/stack/tile/plasteel/pool/cobble/side
	name = "cobblestone side pool floor tile"
	singular_name = "cobblestone side pool floor tile"
	turf_type = /turf/open/floor/plasteel/pool/cobble/side

/obj/item/stack/tile/plasteel/pool/cobble/corner
	name = "cobblestone corner pool floor tile"
	singular_name = "cobblestone corner pool floor tile"
	turf_type = /turf/open/floor/plasteel/pool/cobble/corner

/turf/open/floor/plasteel/pool
	name = "pool floor"
	floor_tile = /obj/item/stack/tile/plasteel/pool
	icon = 'modular_bluemoon/modules/liquids/icons/turf/pool_tile.dmi'
	base_icon_state = "pool_tile"
	icon_state = "pool_tile"
	liquid_height = -30
	turf_height = -30

/turf/open/floor/plasteel/pool/rust_heretic_act()
	return

/turf/open/floor/plasteel/pool/cobble
	name = "cobblestone pool floor"
	icon = 'modular_bluemoon/modules/liquids/icons/turf/floor.dmi'
	base_icon_state = "cobble"
	icon_state = "cobble"
	footstep = FOOTSTEP_FLOOR
	barefootstep = FOOTSTEP_HARD_BAREFOOT
	clawfootstep = FOOTSTEP_HARD_CLAW
	heavyfootstep = FOOTSTEP_GENERIC_HEAVY

/turf/open/floor/plasteel/pool/cobble/side
	base_icon_state = "cobble_side"
	icon_state = "cobble_side"

/turf/open/floor/plasteel/pool/cobble/corner
	base_icon_state = "cobble_corner"
	icon_state = "cobble_corner"

/turf/open/floor/plasteel/elevated
	name = "elevated floor"
	floor_tile = /obj/item/stack/tile/plasteel/elevated
	icon = 'modular_bluemoon/modules/liquids/icons/turf/elevated_plasteel.dmi'
	icon_state = "elevated_plasteel-0"
	base_icon_state = "elevated_plasteel-0"
	liquid_height = 30
	turf_height = 30

/turf/open/floor/plasteel/elevated/rust_heretic_act()
	return

/turf/open/floor/plasteel/lowered
	name = "lowered floor"
	floor_tile = /obj/item/stack/tile/plasteel/lowered
	icon = 'modular_bluemoon/modules/liquids/icons/turf/lowered_plasteel.dmi'
	icon_state = "lowered_plasteel-0"
	base_icon_state = "lowered_plasteel-0"
	liquid_height = -30
	turf_height = -30

/turf/open/floor/plasteel/lowered/rust_heretic_act()
	return
