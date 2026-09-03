/obj/effect/temp_visual/telegraphing
	icon = 'icons/mob/telegraphing/telegraph_holographic.dmi'
	icon_state = "target_box"
	layer = BELOW_MOB_LAYER
	plane = GAME_PLANE
	light_range = 1
	duration = 2 SECONDS

/obj/effect/temp_visual/telegraphing/vending_machine_tilt
	duration = 1 SECONDS

/obj/effect/temp_visual/telegraphing/thunderbolt
	icon = 'icons/mob/telegraphing/telegraph.dmi'
	icon_state = "target_circle"
	duration = 2 SECONDS

/obj/effect/temp_visual/telegraphing/lift_travel

/obj/effect/temp_visual/telegraphing/lift_travel/Initialize(mapload, duration)
	src.duration = duration
	return ..()

///Прицеливание перед тяжёлым залпом: окно, за которое можно уйти за укрытие.
/obj/effect/temp_visual/telegraphing/ranged_burst
	icon = 'icons/mob/telegraphing/telegraph.dmi'
	icon_state = "target_circle"
	duration = 0.6 SECONDS

/obj/effect/temp_visual/telegraphing/ranged_burst/Initialize(mapload, telegraph_duration)
	if(telegraph_duration)
		duration = telegraph_duration
	return ..()
