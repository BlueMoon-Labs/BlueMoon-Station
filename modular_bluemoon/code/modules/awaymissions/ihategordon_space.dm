// Фейк-космос для ihategordon и похожих миссий: наследует /turf/open/floor/fakespace,
// а НЕ /turf/open/space - isspaceturf() не срабатывает, поэтому работают обычные
// гравитация, шаги и SSair-атмосфера без единого лишнего процесса.
// Космический вид дают параллакс по z-level'ам (ниже) и иконка space.dmi.
// /lit добавляет density = 1: на тайл нельзя встать, но воздух и гравитация
// остаются обычными.
// ВНИМАНИЕ: light_* здесь не задаём - тайл ставится тысячами на карту, и
// per-turf источники света положат динамическое освещение. Если нужно свечение -
// отдельный источник (прожектор/объект), а не подсветка каждого тайла.
/turf/open/floor/fakespace/lit
	name = "void floor"
	desc = "A stretch of open space - or so it seems. There is air and gravity here."
	density = 1

GLOBAL_VAR_INIT(ihategordon_zlevels, alist())

/proc/ihategordon_void_z(z)
	if(!GLOB.ihategordon_zlevels)
		return FALSE
	return GLOB.ihategordon_zlevels["[z]"]

/datum/map_template/on_map_loaded(z, list/bounds)
	. = ..()
	if(findtext(src.mappath || "", "ihategordon"))
		for(var/zz in z to z + max(src.zdepth, 1) - 1)
			GLOB.ihategordon_zlevels["[zz]"] = TRUE

/atom/movable/screen/parallax_layer/ihategordon
	icon = 'modular_bluemoon/icons/effects/mesaparallax.dmi'

/atom/movable/screen/parallax_layer/ihategordon/layer_1
	icon_state = "layer1"
	speed = 0.6
	layer = 1
	parallax_intensity = PARALLAX_LOW
	layer_mode = PARALLAX_MODE_TILED

/atom/movable/screen/parallax_layer/ihategordon/layer_2
	icon_state = "layer2"
	speed = 1
	layer = 2
	parallax_intensity = PARALLAX_MED
	layer_mode = PARALLAX_MODE_TILED

/atom/movable/screen/parallax_layer/ihategordon/layer_3
	icon_state = "layer3"
	speed = 1.4
	layer = 3
	parallax_intensity = PARALLAX_HIGH
	layer_mode = PARALLAX_MODE_STATIC
	center_x = 3872
	center_y = 6848
	environment_flags = PARALLAX_ENV_SPACE_RUINS

/atom/movable/screen/parallax_layer/ihategordon/random/space_gas
	icon_state = "space_gas"
	blend_mode = BLEND_OVERLAY
	speed = 2
	layer = 3
	parallax_intensity = PARALLAX_INSANE
	layer_mode = PARALLAX_MODE_TILED
	palette_tinted = TRUE

/datum/parallax_profile/ihategordon
	id = "ihategordon"
	name = "Ihategordon Void"
	environment_flags = PARALLAX_ENV_SPACE_RUINS
	base_layers = list(
		/atom/movable/screen/parallax_layer/ihategordon/layer_1,
		/atom/movable/screen/parallax_layer/ihategordon/layer_2,
		/atom/movable/screen/parallax_layer/ihategordon/layer_3,
	)
	variant_sets = list(
		list(70, /atom/movable/screen/parallax_layer/ihategordon/random/space_gas),
		list(30),
	)
	palette = list(COLOR_TEAL, COLOR_GREEN, COLOR_YELLOW, COLOR_CYAN, COLOR_ORANGE, COLOR_PURPLE)
	min_quality = PARALLAX_LOW
	weight = 0
	source = "BlueMoon Station - Mesa Mission"

/datum/controller/subsystem/parallax/proc/check_ihategordon_z(z)
	return ihategordon_void_z(z)

/datum/controller/subsystem/parallax/pick_profile_for_z(z)
	. = ..()

	if(check_ihategordon_z(z))
		var/datum/parallax_profile/ihategordon/ihategordon_profile = resolve_profile("ihategordon")
		if(ihategordon_profile)
			return ihategordon_profile
