/turf/open/floor/plating/cobblestone
	name = "cobblestone"
	icon = 'modular_citadel/code/modules/festive/cobblestone.dmi'
	icon_state = "unsmooth"
	base_icon_state = "unsmooth"
	smooth = SMOOTH_MORE | SMOOTH_BORDER
	canSmoothWith = list(/turf/open/floor/plating/cobblestone)

/turf/open/floor/plating/cobblestone/alleyway
	name = "alleyway bricks"
	icon = 'modular_citadel/code/modules/festive/alleywaybricks.dmi'
	canSmoothWith = list(/turf/open/floor/plating/cobblestone/alleyway)

/turf/open/floor/plating/cobblestone/sidewalk
	name = "sidewalk"
	icon = 'modular_citadel/code/modules/festive/sidewalk.dmi'
	canSmoothWith = list(/turf/open/floor/plating/cobblestone/sidewalk)

/turf/open/indestructible/ironsand
	gender = PLURAL
	name = "iron sand"
	icon_state = "ironsand1"
	base_icon_state = "ironsand1"
	desc = "Like sand, but even more <i>metal</i>."
	baseturfs = /turf/open/indestructible/ironsand
	footstep = FOOTSTEP_SAND
	barefootstep = FOOTSTEP_SAND
	clawfootstep = FOOTSTEP_SAND
	heavyfootstep = FOOTSTEP_GENERIC_HEAVY

/turf/open/indestructible/ironsand/Initialize(mapload)
	. = ..()
	icon_state = "ironsand[rand(1,15)]"

/turf/closed/mineral/black_mesa
	turf_type = /turf/open/floor/plating/ironsand
	baseturfs = /turf/open/floor/plating/ironsand
	initial_gas_mix = OPENTURF_DEFAULT_ATMOS
