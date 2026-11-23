//The effect when you wrap a dead body in gift wrap
/obj/effect/spresent
	name = "strange present"
	desc = "It's a ... present?"
	icon = 'icons/obj/items_and_weapons.dmi'
	icon_state = "strangepresent"
	density = TRUE
	anchored = FALSE

/obj/effect/beam
	name = "beam"
	var/def_zone
	pass_flags = PASSTABLE

/obj/effect/beam/singularity_act()
	return

/obj/effect/beam/singularity_pull()
	return

/obj/effect/spawner
	name = "object spawner"

/obj/effect/list_container
	name = "list container"

/obj/effect/list_container/mobl
	name = "mobl"
	var/master = null

	var/list/container = list(  )

/obj/effect/overlay/thermite
	name = "thermite"
	desc = "Looks hot."
	icon = 'icons/effects/fire.dmi'
	icon_state = "2" //what?
	anchored = TRUE
	opacity = TRUE
	density = TRUE
	layer = FLY_LAYER

//Makes a tile fully lit no matter what
/obj/effect/fullbright
	icon = 'icons/effects/alphacolors.dmi'
	icon_state = "white"
	plane = LIGHTING_PLANE
	layer = LIGHTING_LAYER
	blend_mode = BLEND_ADD

/// Засветка турфа по смещению плоскости его этажа; индекс = смещение + 1.
GLOBAL_LIST_EMPTY(fullbright_turf_overlays)

/proc/fullbright_turf_overlay(turf/target)
	var/offset = GET_TURF_PLANE_OFFSET(target)
	var/list/cache = GLOB.fullbright_turf_overlays
	if(length(cache) <= offset)
		cache.len = offset + 1
	var/mutable_appearance/glow = cache[offset + 1]
	if(!glow)
		glow = mutable_appearance('icons/effects/alphacolors.dmi', "white", LIGHTING_LAYER, GET_NEW_PLANE(LIGHTING_PLANE, offset), blend_mode = BLEND_ADD)
		cache[offset + 1] = glow
	return glow

/obj/effect/abstract/marker
	name = "marker"
	icon = 'icons/effects/effects.dmi'
	anchored = TRUE
	icon_state = "wave3"
	layer = RIPPLE_LAYER

/obj/effect/abstract/marker/Initialize(mapload)
	. = ..()
	GLOB.all_abstract_markers += src

/obj/effect/abstract/marker/Destroy()
	GLOB.all_abstract_markers -= src
	. = ..()

/obj/effect/abstract/marker/at
	name = "active turf marker"


/obj/effect/dummy/lighting_obj
	name = "lighting fx obj"
	desc = "Tell a coder if you're seeing this."
	icon_state = "nothing"
	// Оверлейный свет: вспышки висят на движущихся мобах, корнер-систему не трогаем
	light_system = OVERLAY_LIGHT
	light_color = "#FFFFFF"
	light_range = MINIMUM_USEFUL_LIGHT_RANGE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	var/death_timer

/obj/effect/dummy/lighting_obj/Initialize(mapload, _color, _range, _power, _duration)
	. = ..()
	set_light_color(_color ? _color : light_color)
	set_light_range(isnull(_range) ? light_range : _range)
	set_light_power(isnull(_power) ? light_power : _power)
	if(_duration)
		death_timer = QDEL_IN_STOPPABLE(src, _duration)

// Совпадают ли текущие параметры света с запрошенными - для переиспользования
// объекта вместо new+qdel на каждый вызов (меска-вспышки всегда одним набором).
/obj/effect/dummy/lighting_obj/proc/light_params_match(_color, _range, _power)
	if(!isnull(_color) && light_color != _color)
		return FALSE
	if(!isnull(_range) && light_range != min(_range, LIGHT_RANGE_CAP_FOR(src)))
		return FALSE
	if(!isnull(_power) && light_power != _power)
		return FALSE
	return TRUE

// Перевзводит таймер жизни уже живущего объекта. Параметры не трогает -
// вызывается только после light_params_match().
/obj/effect/dummy/lighting_obj/proc/refresh_lifetime(_duration)
	if(death_timer)
		deltimer(death_timer)
		death_timer = null
	if(_duration)
		death_timer = QDEL_IN_STOPPABLE(src, _duration)

/obj/effect/dummy/lighting_obj/moblight
	name = "mob lighting fx"

	/// Персистентный режим (частые короткие вспышки - меска-мускулфлеш):
	/// объект не самоудаляется, живёт на держателе и гаснет анимацией альфы
	/// маски - atom+компонент+сигналы создаются один раз на моба, а не на патрон.
	var/persistent = FALSE
	var/datum/component/overlay_lighting/light_comp
	var/mob/living/light_holder
	var/hold_timer

/obj/effect/dummy/lighting_obj/moblight/Initialize(mapload, _color, _range, _power, _duration)
	. = ..()
	if(!ismob(loc))
		return INITIALIZE_HINT_QDEL

// Включает персистентный режим: снимает авто-удаление, вешается на смерть и
// удаление держателя, гасит маску - дальше видимостью рулит pulse_flash().
/obj/effect/dummy/lighting_obj/moblight/proc/make_persistent(mob/living/holder)
	persistent = TRUE
	if(death_timer)
		deltimer(death_timer)
		death_timer = null
	light_holder = holder
	light_comp = GetComponent(/datum/component/overlay_lighting)
	if(light_comp && light_comp.visible_mask)
		light_comp.visible_mask.alpha = 0
	RegisterSignal(holder, COMSIG_MOB_DEATH, PROC_REF(on_holder_gone))
	RegisterSignal(holder, COMSIG_PARENT_QDELETING, PROC_REF(on_holder_gone))

// Вспышка без пересоздания объекта: маска загорается на пике, а затухание
// запускается один раз - когда стрельба стихла на hold-таймаут. На автоматике
// свет держится на пике всё время огня, после прекращения гаснет плавно.
/obj/effect/dummy/lighting_obj/moblight/proc/pulse_flash(_duration = FLASH_LIGHT_DURATION)
	var/datum/component/overlay_lighting/comp = light_comp
	if(!comp || QDELETED(comp.parent) || !comp.visible_mask)
		return
	comp.visible_mask.alpha = comp.set_alpha > 0 ? comp.set_alpha : OVERLAY_LIGHT_MASK_ALPHA_CAP
	var/hold_time = max((_duration || FLASH_LIGHT_DURATION) * 4, 6)
	if(hold_timer)
		deltimer(hold_timer)
	hold_timer = addtimer(CALLBACK(src, PROC_REF(start_flash_decay)), hold_time, TIMER_STOPPABLE)

/obj/effect/dummy/lighting_obj/moblight/proc/start_flash_decay()
	hold_timer = null
	var/datum/component/overlay_lighting/comp = light_comp
	if(comp && !QDELETED(comp.parent) && comp.visible_mask)
		animate(comp.visible_mask, alpha = 0, time = 8)

// Подтягивает параметры света при повторном использовании под другой вызов;
// set_* сами отсекают совпадающие значения, так что на каждый выстрел это no-op.
/obj/effect/dummy/lighting_obj/moblight/proc/sync_light_params(_color, _range, _power)
	if(!isnull(_color))
		set_light_color(_color)
	if(!isnull(_range))
		set_light_range(_range)
	if(!isnull(_power))
		set_light_power(_power)

/obj/effect/dummy/lighting_obj/moblight/proc/on_holder_gone()
	SIGNAL_HANDLER
	qdel(src)

/obj/effect/dummy/lighting_obj/moblight/Destroy()
	if(hold_timer)
		deltimer(hold_timer)
	if(light_holder && !QDELETED(light_holder))
		UnregisterSignal(light_holder, list(COMSIG_MOB_DEATH, COMSIG_PARENT_QDELETING))
	. = ..()
