// Лёхавеб неразрушаемые стенки
/turf/closed/indestructible/riveted/lfwb
	name = "wall"
	desc = "A metal wall."
	icon = 'modular_bluemoon/icons/turf/walls/metalic_wall.dmi'
	icon_state = "metalic"

// Пещерные неразрушаемые стенки
/turf/closed/indestructible/riveted/lfwb/cave
	name = "cave wall"
	desc = "Не очень гладкая стена из камня."
	icon = 'modular_bluemoon/icons/turf/walls/cave_wall.dmi'
	icon_state = "cave"

// Стенки космической станции
/turf/closed/indestructible/riveted/lfwb/leviathan
	name = "metal wall"
	desc = "A wall made of old steel."
	icon = 'modular_bluemoon/icons/turf/walls/leviathan_wall.dmi'
	icon_state = "leviathan"

// Стенки станции душеломов
/turf/closed/indestructible/riveted/lfwb/soulbreaker
	name = "hive wall"
	desc = "A metal wall."
	icon = 'modular_bluemoon/icons/turf/walls/soulbreaker_wall.dmi'
	icon_state = "soulbreaker"

// Окошко душеломов
/turf/closed/indestructible/riveted/lfwb/soulbreaker/fakeglass
	name = "window"
	desc = "Стекло выглядит очень крепким."
	icon = 'modular_bluemoon/icons/turf/walls/soulbreaker_fakewindow_wall.dmi'
	icon_state = "window"
	opacity = 0
	pass_flags_self = PASSCLOSEDTURF | PASSGLASS

/turf/closed/indestructible/fakeglass/Initialize(mapload)
	. = ..()
	underlays += mutable_appearance('icons/turf/floors.dmi', "plating") //add the plating underlay, below the grille
