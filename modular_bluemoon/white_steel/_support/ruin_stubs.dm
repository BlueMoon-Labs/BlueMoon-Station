//WHITE-STEEL PORT - заглушки отсутствующих в bluemoon типов руин

/obj/structure/destructible/clockwork/trap/delay
	name = "Ratvar delaying trap"

/obj/structure/destructible/clockwork/trap/flipper
	name = "Ratvar flipping trap"

/obj/structure/destructible/clockwork/gear_base
	name = "gear base"
	density = TRUE

/obj/structure/destructible/clockwork/gear_base/interdiction_lens
	name = "interdiction lens"

// ===== Area stubs (_maps/RuinGeneration/*.dmm reference these) =====

/area/ruin/unpowered
	always_unpowered = FALSE

/area/ruin/space/has_grav/powered/telepadovo
	name = "Telepadovo"

/area/ruin/space/has_grav/austation
	name = "Austation"

/area/ruin/space/has_grav/austation/med
	name = "Austation: Medbay"

/area/ruin/space/has_grav/austation/vault
	name = "Austation: Vault"

/area/ruin/space/has_grav/austation/rnd
	name = "Austation: Research"

/area/ruin/space/has_grav/austation/xeno
	name = "Austation: Xeno"

/area/ruin/space/has_grav/austation/station
	name = "Austation: Station"

/area/ruin/space/has_grav/austation/eng
	name = "Austation: Engineering"

/area/ruin/space/has_grav/austation/maint
	name = "Austation: Maintenance"

// ===== Turf stubs (missing from bluemoon, referenced by RuinGeneration maps) =====

/turf/open/floor/partyhard
	name = "ancient floor"
	baseturfs = /turf/open/openspace

/turf/open/floor/partyhard/steel
	base_icon_state = "p"
	icon_state = "p-1"
	var/max_random_states = 4

/turf/open/floor/partyhard/steel/Initialize(mapload)
	. = ..()
	if(max_random_states)
		icon_state = "[base_icon_state]-[rand(1, max_random_states)]"

/turf/open/floor/resin
	name = "resin floor"
	desc = "Мягкий, но в то же время весьма крепкий."
	bullet_bounce_sound = null
	footstep = FOOTSTEP_CARPET
	barefootstep = FOOTSTEP_CARPET_BAREFOOT
	clawfootstep = FOOTSTEP_CARPET_BAREFOOT
	heavyfootstep = FOOTSTEP_GENERIC_HEAVY

/turf/open/floor/plasteel/catwalk_floor
	name = "catwalk"
	icon = 'modular_bluemoon/icons/turf/floors/catwalk_plating.dmi'
	icon_state = "maint_below"
	baseturfs = /turf/open/floor/plating
	footstep = FOOTSTEP_CATWALK
	barefootstep = FOOTSTEP_CATWALK
	clawfootstep = FOOTSTEP_CATWALK
	heavyfootstep = FOOTSTEP_CATWALK

//WHITE-STEEL PORT: у старого стаба icon_state был "catwalk_below" - такого кадра в .dmi нет,
//из-за чего рисовалась первая (яркая) картинка. Теперь как у настоящего /turf/open/floor/catwalk_floor:
//нижний слой maint_below + решётка maint_above сверху.
/turf/open/floor/plasteel/catwalk_floor/Initialize(mapload)
	. = ..()
	var/image/catwalk_overlay = new()
	catwalk_overlay.icon = icon
	catwalk_overlay.icon_state = "maint_above"
	SET_PLANE_EXPLICIT(catwalk_overlay, FLOOR_PLANE, src)
	catwalk_overlay.layer = CATWALK_LAYER
	add_overlay(catwalk_overlay)

/turf/open/floor/plasteel/durasteel
	name = "durasteel floor"

/turf/open/floor/plasteel/monofloor
	icon_state = "monofloor"
	base_icon_state = "monofloor"

/turf/open/floor/plasteel/monofloor/dark
	icon_state = "monodarkfull"
	base_icon_state = "monodarkfull"

/turf/open/floor/plating/asteroid/no_generation

/turf/closed/wall/partyhard
	name = "wall"
	desc = "Очень крепкая."
