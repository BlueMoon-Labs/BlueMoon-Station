/turf/open/floor/plating/asteroid/moon
	name = "lunar surface"
	icon = 'modular_bluemoon/icons/turf/moon.dmi'
	icon_state = "moon"
	base_icon_state = "moon"
	floor_variance = 40
	baseturfs = /turf/open/floor/plating/asteroid/moon
	turf_type = /turf/open/floor/plating/asteroid/moon

/turf/open/floor/plating/asteroid/moon/airless
	initial_gas_mix = AIRLESS_ATMOS
	baseturfs = /turf/open/floor/plating/asteroid/moon/airless
	turf_type = /turf/open/floor/plating/asteroid/moon/airless

/turf/closed/mineral/random/stationside/moon
	baseturfs = /turf/open/floor/plating/asteroid/moon/airless
	turf_type = /turf/open/floor/plating/asteroid/moon/airless

/obj/effect/turf_decal/lunar_sand
	name = "dusty floor"
	icon = 'modular_bluemoon/icons/turf/moon.dmi'
	icon_state = "moonsandfloor"

/obj/effect/turf_decal/lunar_sand/plating
	name = "dusty plating"
	icon_state = "moonsandplating"
