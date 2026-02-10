/**
 * Ионные частицы для события Aurora Caelus
 * Комменты для примера, нигде в коде не используется, так что эаэа.
 * https://www.byond.com/docs/ref/info.html#/%7Bnotes%7D/particles
 * https://www.byond.com/docs/ref/info.html#/%7Bnotes%7D/generators
 * https://www.byond.com/docs/ref/info.html#/proc/generator
 * Сверху документация на все это.
 */


/particles/aurora_ions
	icon = 'modular_bluemoon/icons/misc/ion.dmi'
	icon_state = "ion"
	width = 640			// ширина области генерации (пикселей) — покрывает весь экран
	height = 480		// высота области генерации
	count = 50			// макс. количество частиц одновременно
	spawning = 5		// новых частиц в тик
	lifespan = 40		// время жизни (в тиках, ~4 секунды)
	fade = 20			// время затухания (плавное исчезновение)
	fadein = 10			// время появления (плавное возникновение)
	grow = -0.01		// небольшое уменьшение со временем
	scale = generator("num", 0.4, 1.2)
	position = generator("box", list(-300, -230, 0), list(300, 230, 0)) // случайная позиция по всей области
	velocity = generator("vector", list(-0.5, 0.3, 0), list(0.5, 1.2, 0)) // медленный дрейф вверх с небольшим разбросом
	drift = generator("vector", list(-0.1, 0, 0), list(0.1, 0, 0)) // лёгкий горизонтальный дрейф
	color = "#A2FFC7"	// начальный цвет

/atom/movable/screen/aurora_ion_overlay
	icon = 'modular_bluemoon/icons/misc/ion.dmi'
	icon_state = "ion"
	alpha = 0
	screen_loc = "CENTER,CENTER"
	plane = PLANE_SPACE_PARALLAX
	blend_mode = BLEND_ADD
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	appearance_flags = PIXEL_SCALE | RESET_TRANSFORM

/atom/movable/screen/aurora_ion_overlay/Initialize(mapload)
	. = ..()
	particles = new /particles/aurora_ions

/atom/movable/screen/aurora_ion_overlay/Destroy()
	QDEL_NULL(particles)
	return ..()

/atom/movable/screen/aurora_ion_overlay/proc/fade_in(time = 30)
	animate(src, alpha = 180, time = time)

/atom/movable/screen/aurora_ion_overlay/proc/fade_out(time = 50)
	if(particles)
		particles.spawning = 0
	animate(src, alpha = 0, time = time)

/atom/movable/screen/aurora_ion_overlay/proc/update_ion_color(new_color)
	if(particles)
		particles.color = new_color

