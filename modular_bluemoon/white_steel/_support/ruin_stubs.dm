//WHITE-STEEL PORT - заглушки отсутствующих в bluemoon типов руин

/obj/structure/destructible/clockwork/trap/delay
	name = "задерживающая ловушка Ратвара"

/obj/structure/destructible/clockwork/trap/flipper
	name = "переворачивающая ловушка Ратвара"

/obj/structure/destructible/clockwork/gear_base
	name = "шестерённая база"
	density = TRUE

/obj/structure/destructible/clockwork/gear_base/interdiction_lens
	name = "линза интердикции"

// ===== Area stubs (_maps/RuinGeneration/*.dmm reference these) =====

/area/ruin/unpowered
	always_unpowered = FALSE

/area/ruin/space/has_grav/powered/telepadovo
	name = "Телепадово"

/area/ruin/space/has_grav/austation
	name = "Аутизм"

/area/ruin/space/has_grav/austation/med
	name = "Аутизм: Медбей"

/area/ruin/space/has_grav/austation/vault
	name = "Аутизм: Хранилище"

/area/ruin/space/has_grav/austation/rnd
	name = "Аутизм: Исследования"

/area/ruin/space/has_grav/austation/xeno
	name = "Аутизм: Ксено"

/area/ruin/space/has_grav/austation/station
	name = "Аутизм: Станция"

/area/ruin/space/has_grav/austation/eng
	name = "Аутизм: Инженерный"

/area/ruin/space/has_grav/austation/maint
	name = "Аутизм: Техи"

// ===== Turf stubs (missing from bluemoon, referenced by RuinGeneration maps) =====

/turf/open/floor/partyhard
	name = "древний пол"
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
	name = "резиновый пол"
	desc = "Мягкий, но в то же время весьма крепкий."
	bullet_bounce_sound = null
	footstep = FOOTSTEP_CARPET
	barefootstep = FOOTSTEP_CARPET_BAREFOOT
	clawfootstep = FOOTSTEP_CARPET_BAREFOOT
	heavyfootstep = FOOTSTEP_GENERIC_HEAVY

/turf/open/floor/plasteel/catwalk_floor
	name = "настил"
	icon = 'icons/turf/floors/catwalk_plating.dmi'
	icon_state = "catwalk_below"
	baseturfs = /turf/open/floor/plating
	footstep = FOOTSTEP_CATWALK
	barefootstep = FOOTSTEP_CATWALK
	clawfootstep = FOOTSTEP_CATWALK
	heavyfootstep = FOOTSTEP_CATWALK

/turf/open/floor/plasteel/durasteel
	name = "дюрасталевый пол"

/turf/open/floor/plasteel/monofloor
	icon_state = "monofloor"
	base_icon_state = "monofloor"

/turf/open/floor/plasteel/monofloor/dark
	icon_state = "monodarkfull"
	base_icon_state = "monodarkfull"

/turf/open/floor/plating/asteroid/no_generation

/turf/closed/wall/partyhard
	name = "стена"
	desc = "Очень крепкая."
