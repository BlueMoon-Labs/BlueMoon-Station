// Kvass barrel
/obj/structure/reagent_dispensers/kvass_barrel
	name = "kvass barrel"
	desc = "A yellow-green barrel full of kvass."
	icon = 'modular_bluemoon/icons/obj/reagent_dispensers.dmi'
	icon_state = "kvassbarrel"
	reagent_id = /datum/reagent/consumable/kvass

/obj/structure/reagent_dispensers/proc/do_jitter_animation(jitteriness = 10)
	if(anchored)
		return
	var/amplitude = min(4, (jitteriness/100) + 1)
	var/pixel_x_diff = rand(-amplitude, amplitude)
	var/pixel_y_diff = rand(-amplitude/3, amplitude/3)
	var/final_pixel_x = pixel_x
	var/final_pixel_y = pixel_y
	animate(src, pixel_x = pixel_x_diff, pixel_y = pixel_y_diff , time = 2, loop = 6, flags = ANIMATION_PARALLEL | ANIMATION_RELATIVE)
	animate(pixel_x = final_pixel_x , pixel_y = final_pixel_y , time = 2)
