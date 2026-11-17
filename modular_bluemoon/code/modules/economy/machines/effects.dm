/obj/effect/temp_visual/econ_coins
	name = "coins"
	icon = 'icons/obj/economy.dmi'
	icon_state = "coin_heads_flip"
	color = "#e8c15a"
	duration = 1 SECONDS
	randomdir = FALSE

/obj/effect/temp_visual/econ_coins/Initialize(mapload)
	. = ..()
	pixel_x = rand(-6, 6)
	transform = matrix() * 0.6
	animate(src, pixel_y = pixel_y + 16, time = duration, easing = SINE_EASING | EASE_OUT)
	animate(src, alpha = 0, time = duration / 2, delay = duration / 2, flags = ANIMATION_PARALLEL)
