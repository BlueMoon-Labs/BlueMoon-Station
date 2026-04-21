/obj/effect/turf_decal/tile
	name = "tile decal"
	icon_state = "tile_corner"
	layer = TURF_PLATING_DECAL_LAYER
	alpha = 110

/obj/effect/turf_decal/tile/Initialize()
	if(SSevents.holidays)
		if (SSevents.holidays[APRIL_FOOLS])
			color = "#[random_short_color()]"
		else
			// Ассоциативный список: в цикле — ключи (имена), датум — holidays[key].
			for(var/holiday_key in SSevents.holidays)
				var/datum/holiday/active_holiday = SSevents.holidays[holiday_key]
				if(!istype(active_holiday, /datum/holiday/lgbt))
					continue
				var/datum/holiday/lgbt/L = active_holiday
				color = L.get_floor_tile_color(src)

				// It looks garish at different alphas, and it's not possible to get a
				// consistent color palette without this.
				alpha = 60	//LGBT_ALPHA
	return ..()

/obj/effect/turf_decal/tile/random/Initialize(mapload)
	color = "#[random_short_color()]"
	. = ..()

#define HELPER(Type, Color, Alpha)																			\
	/obj/effect/turf_decal/tile/##Type {color = Color;	alpha = Alpha}										\
	/obj/effect/turf_decal/tile/##Type/opposingcorners {icon_state = "tile_opposing_corners"}				\
	/obj/effect/turf_decal/tile/##Type/half {icon_state = "tile_half"}										\
	/obj/effect/turf_decal/tile/##Type/half/contrasted {icon_state = "tile_half_contrasted"}				\
	/obj/effect/turf_decal/tile/##Type/anticorner {icon_state = "tile_anticorner"}							\
	/obj/effect/turf_decal/tile/##Type/anticorner/contrasted {icon_state = "tile_anticorner_contrasted"}	\
	/obj/effect/turf_decal/tile/##Type/fourcorners {icon_state = "tile_fourcorners"}						\
	/obj/effect/turf_decal/tile/##Type/full {icon_state = "tile_full"}										\
	/obj/effect/turf_decal/tile/##Type/diagonal_centre {icon_state = "diagonal_centre"}						\
	/obj/effect/turf_decal/tile/##Type/diagonal_edge {icon_state = "diagonal_edge"}							\

HELPER(blue,"#52B4E9", 110)
HELPER(dark_blue,"#486091", 110)
HELPER(green,"#9FED58", 110)
HELPER(dark_green,"#439C1E", 110)
HELPER(yellow,"#EFB341", 110)
HELPER(red,"#DE3A3A", 110)
HELPER(dark_red,"#B11111", 110)
HELPER(bar,"#791500", 130)
HELPER(purple,"#D381C9", 110)
HELPER(brown,"#A46106", 110)
HELPER(neutral,"#D4D4D4", 50)
HELPER(dark,"#0e0f0f", 110)
HELPER(random,"#E300FF", 110)

#undef HELPER

/obj/effect/turf_decal/trimline
	layer = TURF_PLATING_DECAL_LAYER
	alpha = 110
	icon_state = "trimline_box"

#define HELPER(Type, Color, Alpha)																		\
	/obj/effect/turf_decal/trimline/##Type {color = Color;	alpha = Alpha}								\
	/obj/effect/turf_decal/trimline/##Type/line {icon_state = "trimline"}								\
	/obj/effect/turf_decal/trimline/##Type/corner {icon_state = "trimline_corner"}						\
	/obj/effect/turf_decal/trimline/##Type/end {icon_state = "trimline_end"}							\
	/obj/effect/turf_decal/trimline/##Type/arrow_cw {icon_state = "trimline_arrow_cw"}					\
	/obj/effect/turf_decal/trimline/##Type/arrow_ccw {icon_state = "trimline_arrow_ccw"}				\
	/obj/effect/turf_decal/trimline/##Type/warning {icon_state = "trimline_warn"}						\
	/obj/effect/turf_decal/trimline/##Type/mid_joiner {icon_state = "trimline_mid"}						\
	/obj/effect/turf_decal/trimline/##Type/filled {icon_state = "trimline_box_fill"}					\
	/obj/effect/turf_decal/trimline/##Type/filled/line {icon_state = "trimline_fill"}					\
	/obj/effect/turf_decal/trimline/##Type/filled/corner {icon_state = "trimline_corner_fill"}			\
	/obj/effect/turf_decal/trimline/##Type/filled/end {icon_state = "trimline_end_fill"}				\
	/obj/effect/turf_decal/trimline/##Type/filled/arrow_cw {icon_state = "trimline_arrow_cw_fill"}		\
	/obj/effect/turf_decal/trimline/##Type/filled/arrow_ccw {icon_state = "trimline_arrow_ccw_fill"}	\
	/obj/effect/turf_decal/trimline/##Type/filled/warning {icon_state = "trimline_warn_fill"}			\
	/obj/effect/turf_decal/trimline/##Type/filled/mid_joiner {icon_state = "trimline_mid_fill"}			\
	/obj/effect/turf_decal/trimline/##Type/filled/shrink_cw {icon_state = "trimline_shrink_cw"}			\
	/obj/effect/turf_decal/trimline/##Type/filled/shrink_ccw {icon_state = "trimline_shrink_ccw"}		\

HELPER(white,"#FFFFFF", 110)
HELPER(red,"#DE3A3A", 110)
HELPER(dark_red,"#B11111", 110)
HELPER(green,"#9FED58", 110)
HELPER(dark_green,"#439C1E", 110)
HELPER(blue,"#52B4E9", 110)
HELPER(dark_blue,"#486091", 110)
HELPER(yellow,"#EFB341", 110)
HELPER(purple,"#D381C9", 110)
HELPER(brown,"#A46106", 110)
HELPER(neutral,"#D4D4D4", 50)
HELPER(dark,"#0e0f0f", 110)

#undef HELPER
