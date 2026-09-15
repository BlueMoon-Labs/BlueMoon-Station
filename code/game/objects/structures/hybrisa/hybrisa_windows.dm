// Hybrisa windows - ported from CMSS13, simplified for TG
// TG window system differs from CM; these are simplified stubs that preserve appearance



// TG compatibility for Hybrisa windows
/obj/structure/window
    var/window_frame
    var/not_damageable = FALSE
    var/not_deconstructable = FALSE

 // Window frames - stubs
/obj/structure/window_frame
    name = "window frame"
    icon = 'icons/obj/smooth_structures/window.dmi'
    icon_state = "frame"

/obj/structure/window_frame/hybrisa
    icon = 'icons/turf/walls/hybrisa_colony_window.dmi'
/obj/structure/window_frame/hybrisa/colony
    icon_state = "frame"
/obj/structure/window_frame/hybrisa/colony/reinforced
    icon_state = "rframe"
/obj/structure/window_frame/hybrisa/research
    icon = 'icons/turf/walls/hybrisaresearchbrown_windows.dmi'
/obj/structure/window_frame/hybrisa/research/reinforced
    icon_state = "rframe"
/obj/structure/window_frame/hybrisa/marshalls
    icon = 'icons/turf/walls/hybrisa_marshalls_windows.dmi'
/obj/structure/window_frame/hybrisa/marshalls/reinforced
    icon_state = "rframe"
/obj/structure/window_frame/hybrisa/colony/hospital
    icon = 'icons/turf/walls/hybrisa_hospital_colonywindows.dmi'
/obj/structure/window_frame/hybrisa/colony/hospital/reinforced
    icon_state = "rframe"
/obj/structure/window_frame/hybrisa/colony/office
    icon = 'icons/turf/walls/hybrisa_offices_windows.dmi'
/obj/structure/window_frame/hybrisa/colony/office/reinforced
    icon_state = "rframe"
/obj/structure/window_frame/hybrisa/colony/engineering
    icon = 'icons/turf/walls/hybrisa_engineering_windows.dmi'
/obj/structure/window_frame/hybrisa/colony/engineering/reinforced
    icon_state = "rframe"
/obj/structure/window_frame/hybrisa/spaceport
    icon = 'icons/turf/walls/hybrisa_spaceport_windows.dmi'
/obj/structure/window_frame/hybrisa/spaceport/reinforced
    icon_state = "rframe"
/obj/structure/window_frame/hybrisa/colony/engineering/hull
    icon_state = "hullframe"
/obj/structure/window_frame/hybrisa/spaceport/cell
    icon_state = "cellframe"
/obj/structure/window_frame/almayer
    icon = 'icons/obj/smooth_structures/window.dmi'
/obj/structure/window_frame/colony
    icon = 'icons/obj/smooth_structures/window.dmi'
/obj/structure/window_frame/colony/reinforced
    icon_state = "rframe"
/obj/structure/window_frame/corsat
    icon = 'icons/turf/walls/windows_corsat.dmi'
/obj/structure/window_frame/corsat/research
    icon_state = "researchframe"
/obj/structure/window_frame/corsat/security
    icon_state = "secframe"
/obj/structure/window_frame/bunker
    icon = 'icons/turf/walls/bunker.dmi'
/obj/structure/window_frame/bunker/reinforced
    icon_state = "rframe"
/obj/structure/window_frame/strata
    icon = 'icons/turf/walls/strata_windows.dmi'
/obj/structure/window_frame/strata/reinforced
    icon_state = "rframe"
/obj/structure/window_frame/lv_colony
    icon = 'icons/turf/walls/lv_colony_windows.dmi'
/obj/structure/window_frame/prison
    icon = 'icons/obj/smooth_structures/window.dmi'
/obj/structure/window_frame/prison/reinforced

/obj/structure/window_frame/upp
    name = "window frame"
/obj/structure/window_frame/upp/green
    icon = 'icons/turf/walls/hybrisa_colony_window.dmi'
/obj/structure/window_frame/upp/grey
    icon = 'icons/turf/walls/hybrisa_colony_window.dmi'
/obj/structure/window_frame/abyssal
    name = "window frame"
/obj/structure/window_frame/abyssal/standard
    icon = 'icons/turf/walls/hybrisa_colony_window.dmi'
/obj/structure/window_frame/abyssal/standard/reinforced
    icon = 'icons/turf/walls/hybrisa_colony_window.dmi'
/obj/structure/window_frame/abyssal/blue
    icon = 'icons/turf/walls/hybrisa_colony_window.dmi'
/obj/structure/window_frame/abyssal/blue/reinforced
    icon = 'icons/turf/walls/hybrisa_colony_window.dmi'

    icon_state = "rframe"

// Hybrisa Windows

// Colony
/obj/structure/window/framed/hybrisa/colony
	name = "window"
	icon = 'icons/turf/walls/hybrisa_colony_window.dmi'
	icon_state = "strata_window0"
	desc = "A glass window inside a wall frame."
	max_integrity = 40
	window_frame = /obj/structure/window_frame/hybrisa/colony

/obj/structure/window/framed/hybrisa/colony/reinforced
	name = "reinforced window"
	icon_state = "strata_window0"
	desc = "A glass window. Light refracts incorrectly when looking through. It looks rather strong. Might take a few good hits to shatter it."
	max_integrity = 100
	reinf = TRUE
	window_frame = /obj/structure/window_frame/hybrisa/colony/reinforced

/obj/structure/window/framed/hybrisa/colony/hull
	icon_state = "strata_window0"
	desc = "A glass window. Something tells you this one is somehow indestructible."
	not_damageable = TRUE
	not_deconstructable = TRUE
	unslashable = TRUE
	unacidable = TRUE
	max_integrity = 1000000

/obj/structure/window/framed/hybrisa/colony/hull/blastdoor
	name = "hull window"
	desc = "A glass window with a special rod matrix inside a wall frame. This one has an automatic shutter system to prevent any flooding breach."
	max_integrity = 200
	//icon_state = "rwindow0_debug"
	not_damageable = FALSE
	unslashable = FALSE
	unacidable = FALSE

// Research
/obj/structure/window/framed/hybrisa/research
	name = "window"
	icon = 'icons/turf/walls/hybrisaresearchbrown_windows.dmi'
	icon_state = "strata_window0"
	desc = "A glass window inside a wall frame."
	max_integrity = 40
	window_frame = /obj/structure/window_frame/hybrisa/research

/obj/structure/window/framed/hybrisa/research/reinforced
	name = "reinforced window"
	icon_state = "strata_window0"
	desc = "A glass window. Light refracts incorrectly when looking through. It looks rather strong. Might take a few good hits to shatter it."
	max_integrity = 100
	reinf = TRUE
	window_frame = /obj/structure/window_frame/hybrisa/research/reinforced

/obj/structure/window/framed/hybrisa/research/hull
	icon_state = "strata_window0"
	desc = "A glass window. Something tells you this one is somehow indestructible."
	not_damageable = TRUE
	not_deconstructable = TRUE
	unslashable = TRUE
	unacidable = TRUE
	max_integrity = 1000000

// Marshalls

/obj/structure/window/framed/hybrisa/marshalls
	name = "window"
	icon = 'icons/turf/walls/hybrisa_marshalls_windows.dmi'
	icon_state = "prison_window0"
	window_frame = /obj/structure/window_frame/hybrisa/marshalls
/obj/structure/window/framed/hybrisa/marshalls/reinforced
	name = "reinforced window"
	desc = "A glass window with a special rod matrix inside a wall frame. It looks rather strong. Might take a few good hits to shatter it."
	max_integrity = 100
	reinf = TRUE
	icon_state = "prison_rwindow0"
	window_frame = /obj/structure/window_frame/hybrisa/marshalls/reinforced
/obj/structure/window/framed/hybrisa/marshalls/cell
	name = "cell window"
	icon_state = "prison_cellwindow0"
	desc = "A glass window with a special rod matrix inside a wall frame."

// Hospital

/obj/structure/window/framed/hybrisa/colony/hospital
	name = "window"
	icon = 'icons/turf/walls/hybrisa_hospital_colonywindows.dmi'
	icon_state = "strata_window0"
	desc = "A glass window inside a wall frame."
	max_integrity = 40
	window_frame = /obj/structure/window_frame/hybrisa/colony/hospital

/obj/structure/window/framed/hybrisa/colony/hospital/reinforced
	name = "reinforced window"
	icon_state = "strata_window0"
	desc = "A glass window. Light refracts incorrectly when looking through. It looks rather strong. Might take a few good hits to shatter it."
	max_integrity = 100
	reinf = TRUE
	window_frame = /obj/structure/window_frame/hybrisa/colony/hospital/reinforced

/obj/structure/window/framed/hybrisa/colony/hospital/hull
	icon_state = "strata_window0"
	desc = "A glass window. Something tells you this one is somehow indestructible."
	not_damageable = TRUE
	not_deconstructable = TRUE
	unslashable = TRUE
	unacidable = TRUE
	max_integrity = 1000000

// Office

/obj/structure/window/framed/hybrisa/colony/office
	name = "window"
	icon = 'icons/turf/walls/hybrisa_offices_windows.dmi'
	icon_state = "strata_window0"
	desc = "A glass window inside a wall frame."
	max_integrity = 40
	window_frame = /obj/structure/window_frame/hybrisa/colony/office

/obj/structure/window/framed/hybrisa/colony/office/reinforced
	name = "reinforced window"
	icon_state = "strata_window0"
	desc = "A glass window. Light refracts incorrectly when looking through. It looks rather strong. Might take a few good hits to shatter it."
	max_integrity = 100
	reinf = TRUE
	window_frame = /obj/structure/window_frame/hybrisa/colony/office/reinforced

/obj/structure/window/framed/hybrisa/colony/office/hull
	icon_state = "strata_window0"
	desc = "A glass window. Something tells you this one is somehow indestructible."
	not_damageable = TRUE
	not_deconstructable = TRUE
	unslashable = TRUE
	unacidable = TRUE
	max_integrity = 1000000

// Engineering

/obj/structure/window/framed/hybrisa/colony/engineering
	name = "window"
	icon = 'icons/turf/walls/hybrisa_engineering_windows.dmi'
	icon_state = "strata_window0"
	desc = "A glass window inside a wall frame."
	max_integrity = 40
	window_frame = /obj/structure/window_frame/hybrisa/colony/engineering

/obj/structure/window/framed/hybrisa/colony/engineering/reinforced
	name = "reinforced window"
	icon_state = "strata_window0"
	desc = "A glass window. Light refracts incorrectly when looking through. It looks rather strong. Might take a few good hits to shatter it."
	max_integrity = 100
	reinf = TRUE
	window_frame = /obj/structure/window_frame/hybrisa/colony/engineering/reinforced

/obj/structure/window/framed/hybrisa/colony/engineering/hull
	icon_state = "strata_window0"
	desc = "A glass window. Something tells you this one is somehow indestructible."
	not_damageable = TRUE
	not_deconstructable = TRUE
	unslashable = TRUE
	unacidable = TRUE
	max_integrity = 1000000

// Space-Port

/obj/structure/window/framed/hybrisa/spaceport
	name = "window"
	icon = 'icons/turf/walls/hybrisa_spaceport_windows.dmi'
	icon_state = "prison_window0"
	window_frame = /obj/structure/window_frame/hybrisa/spaceport
/obj/structure/window/framed/hybrisa/spaceport/reinforced
	name = "reinforced window"
	desc = "A glass window with a special rod matrix inside a wall frame. It looks rather strong. Might take a few good hits to shatter it."
	max_integrity = 100
	reinf = TRUE
	icon_state = "prison_rwindow0"
	window_frame = /obj/structure/window_frame/hybrisa/spaceport/reinforced
/obj/structure/window/framed/hybrisa/spaceport/cell
	name = "window"
	icon_state = "prison_cellwindow0"
	desc = "A glass window with a special rod matrix inside a wall frame."
/obj/structure/window/framed/upp
	name = "military grade window"
	desc = "A glass window. Light refracts incorrectly when looking through. It looks rather strong. Might take a few good hits to shatter it."
	max_integrity = 100
	reinf = TRUE

/obj/structure/window/framed/upp/green
	icon = 'icons/turf/walls/upp_green_windows.dmi'
	icon_state = "uppwall_window0"
	window_frame = /obj/structure/window_frame/upp/green

/obj/structure/window/framed/upp/green/hull
	icon_state = "uppwall_window0"
	desc = "A glass window. Something tells you this one is somehow indestructible."
	not_damageable = TRUE
	not_deconstructable = TRUE
	unslashable = TRUE
	unacidable = TRUE
	max_integrity = 1000000

/obj/structure/window/framed/upp/grey
	icon = 'icons/turf/walls/upp_grey_windows.dmi'
	icon_state = "uppwall_window0"
	window_frame = /obj/structure/window_frame/upp/grey

/obj/structure/window/framed/upp/grey/hull
	icon_state = "uppwall_window0"
	desc = "A glass window. Something tells you this one is somehow indestructible."
	not_damageable = TRUE
	not_deconstructable = TRUE
	unslashable = TRUE
	unacidable = TRUE
	max_integrity = 1000000

// Abyssal Windows \\

// Standard

/obj/structure/window/framed/abyssal/standard
	name = "window"
	icon = 'icons/turf/walls/abyssal_windows_blank.dmi'
	icon_state = "prison_window0"
	desc = "A glass window inside a wall frame."
	max_integrity = 15
	window_frame = /obj/structure/window_frame/abyssal/standard

/obj/structure/window/framed/abyssal/standard/reinforced
	name = "reinforced window"
	icon_state = "prison_rwindow0"
	desc = "A glass window. Light refracts incorrectly when looking through. It looks rather strong. Might take a few good hits to shatter it."
	max_integrity = 100
	reinf = TRUE
	window_frame = /obj/structure/window_frame/abyssal/standard/reinforced

/obj/structure/window/framed/abyssal/standard/hull
	name = "hull window"
	icon_state = "prison_rwindow0"
	desc = "A glass window with a special rod matrix inside a wall frame. This one has an automatic shutter system to prevent any atmospheric breach."
	max_integrity = 200

/obj/structure/window/framed/abyssal/standard/cell
	name = "cell window"
	icon_state = "prison_cellwindow0"
	desc = "A glass window with a special rod matrix inside a wall frame."

// Blue

/obj/structure/window/framed/abyssal/blue
	name = "window"
	icon = 'icons/turf/walls/abyssal_windows_blue.dmi'
	icon_state = "prison_window0"
	desc = "A glass window inside a wall frame."
	max_integrity = 15
	window_frame = /obj/structure/window_frame/abyssal/blue

/obj/structure/window/framed/abyssal/blue/reinforced
	name = "reinforced window"
	icon_state = "prison_rwindow0"
	desc = "A glass window. Light refracts incorrectly when looking through. It looks rather strong. Might take a few good hits to shatter it."
	max_integrity = 100
	reinf = TRUE
	window_frame = /obj/structure/window_frame/abyssal/blue/reinforced

/obj/structure/window/framed/abyssal/blue/hull
	name = "hull window"
	icon_state = "prison_rwindow0"
	desc = "A glass window with a special rod matrix inside a wall frame. This one has an automatic shutter system to prevent any atmospheric breach."
	max_integrity = 200

/obj/structure/window/framed/abyssal/blue/cell
	name = "cell window"
	icon_state = "prison_cellwindow0"
	desc = "A glass window with a special rod matrix inside a wall frame."