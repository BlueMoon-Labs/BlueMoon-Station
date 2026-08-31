/**
 * Adds a fullscreen overlay
 *
 * @params
 * - category - string - must exist. will overwrite any other screen in this category. defaults to type.
 * - type - the typepath of the screen
 * - severity - severity - different screen objects have differing severities
 */
/mob/proc/overlay_fullscreen(category, type, severity)
	ASSERT(type)
	if(!category)
		category = type
	var/atom/movable/screen/fullscreen/screen = fullscreens[category]
	if (!screen || screen.type != type)
		// needs to be recreated
		clear_fullscreen(category, 0)
		fullscreens[category] = screen = new type
	// Ранний возврат, когда обновлять нечего. Он есть у апстрима и был потерян при переносе:
	// без него update_damage_hud() гонит тело этого прока ШЕСТЬ раз за вызов (critvision,
	// crit, oxy, brute, synthcorrupt, кровопотеря), то есть на каждом updatehealth() каждого
	// раненого моба - а это тик Life() плюс любое применение урона и любой тик реагента.
	// Именно это сделало SetSeverity() горячим проком: подтип synthcorrupt заводил там
	// эмиттер /particles на 960x960, и клиент набирал сотни мегабайт за минуту.
	//
	// От апстримовой версии условие отличается отсутствием ветки "!severity": у нас
	// SetSeverity() - это не присваивание, а снятие эффекта на нулевой тяжести (тот же
	// synthcorrupt убирает там холдер), и пропускать вызов с нулём нельзя.
	//
	// Флаг hidden_from_client снимает ранний возврат ровно на один вызов после
	// hide_fullscreens(): экран снят с client.screen, но остался в fullscreens, и без этой
	// оговорки повторный overlay_fullscreen() с той же тяжестью уходил бы возвратом, а
	// оверлей не всплыл бы уже никогда.
	else if(severity == screen.severity && !screen.hidden_from_client && (!client || screen.screen_loc != "CENTER-7,CENTER-7" || screen.view_current == client.view))
		return screen
	screen.SetSeverity(severity)
	if(client)
		if(screen.ShouldShow(src))
			screen.SetView(client.view)
			// |=, а не +=: client.screen - обычный список, и += клал бы один и тот же экранный
			// объект повторно. Соседний reload_fullscreen() уже делает |=.
			client.screen |= screen
		// Пишем только когда флаг реально стоит: запись в переменную инстанса занимает слот
		// у BYOND навсегда, а через этот путь проходит каждый апдейт худа урона.
		if(screen.hidden_from_client)
			screen.hidden_from_client = FALSE
	return screen

/**
 * Wipes a fullscreen of a certain category
 *
 * Second argument is for animation delay.
 */
/mob/proc/clear_fullscreen(category, animated = 10)
	if(!fullscreens)
		return
	var/atom/movable/screen/fullscreen/screen = fullscreens[category]
	fullscreens -= category
	if(!screen)
		return
	if(animated > 0)
		animate(screen, alpha = 0, time = animated)
		addtimer(CALLBACK(src, PROC_REF(_remove_fullscreen_direct), screen), animated, TIMER_CLIENT_TIME)
	else
		screen.screen_loc = null
		if(client)
			client.screen -= screen
		qdel(screen)

/mob/proc/_remove_fullscreen_direct(atom/movable/screen/fullscreen/screen)
	screen.screen_loc = null
	if(client)
		client.screen -= screen
	qdel(screen)

/**
 * Wipes all fullscreens
 */
/mob/proc/wipe_fullscreens()
	for(var/category in fullscreens)
		clear_fullscreen(category)

/**
 * Removes fullscreens from client but not the mob
 */
/mob/proc/hide_fullscreens()
	if(!client)
		return
	for(var/category in fullscreens)
		var/atom/movable/screen/fullscreen/screen = fullscreens[category]
		client.screen -= screen
		screen.hidden_from_client = TRUE

/**
 * Ensures all fullscreens are on client.
 */
/mob/proc/reload_fullscreen()
	if(client)
		var/atom/movable/screen/fullscreen/screen
		for(var/category in fullscreens)
			screen = fullscreens[category]
			if(screen.ShouldShow(src))
				screen.SetView(client.view)
				client.screen |= screen
			else
				client.screen -= screen
			// Состояние клиента снова согласовано с fullscreens - ранний возврат в
			// overlay_fullscreen() опять законен.
			if(screen.hidden_from_client)
				screen.hidden_from_client = FALSE

/atom/movable/screen/fullscreen
	icon = 'icons/screen/fullscreen_15x15.dmi'
	icon_state = "default"
	screen_loc = "CENTER-7,CENTER-7"
	layer = FULLSCREEN_LAYER
	plane = FULLSCREEN_PLANE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	/// current view we're adapted to
	var/view_current
	/// min severity
	var/severity_min = 0
	/// max severity
	var/severity_max = INFINITY
	/// current severity
	var/severity = 0
	/// Экран снят с client.screen через hide_fullscreens() и ждёт возврата. Пока флаг стоит,
	/// overlay_fullscreen() не имеет права уходить ранним возвратом.
	var/hidden_from_client = FALSE
	/// show this while dead
	var/show_when_dead = FALSE

//Provides darkness to the back of the lighting plane
/atom/movable/screen/fullscreen/lighting_backdrop/lit
	invisibility = INVISIBILITY_LIGHTING
	layer = BACKGROUND_LAYER+21
	color = "#000"
	show_when_dead = TRUE

//Provides whiteness in case you don't see lights so everything is still visible
/atom/movable/screen/fullscreen/lighting_backdrop/unlit
	layer = BACKGROUND_LAYER+20
	show_when_dead = TRUE

/atom/movable/screen/fullscreen/proc/SetSeverity(severity)
	src.severity = clamp(severity, severity_min, severity_max)
	icon_state = "[initial(icon_state)][severity]"

/atom/movable/screen/fullscreen/proc/SetView(client_view)
	view_current = client_view

/atom/movable/screen/fullscreen/proc/ShouldShow(mob/M)
	if(!show_when_dead && M.stat == DEAD)
		return FALSE
	return TRUE

/atom/movable/screen/fullscreen/Destroy()
	SetSeverity(0)
	return ..()

/atom/movable/screen/fullscreen/scaled
	icon = 'icons/screen/fullscreen_15x15.dmi'
	screen_loc = "CENTER-7,CENTER-7"
	/// size of sprite in tiles
	var/size_x = 15
	/// size of sprite in tiles
	var/size_y = 15

/atom/movable/screen/fullscreen/scaled/SetView(client_view)
	if(view_current != client_view)
		var/list/actualview = getviewsize(client_view)
		view_current = client_view
		transform = matrix(actualview[1] / size_x, 0, 0, 0, actualview[2] / size_y, 0)
	return ..()

/atom/movable/screen/fullscreen/scaled/brute
	icon_state = "brutedamageoverlay"
	layer = UI_DAMAGE_LAYER
	plane = FULLSCREEN_PLANE

/atom/movable/screen/fullscreen/scaled/oxy
	icon_state = "oxydamageoverlay"
	layer = UI_DAMAGE_LAYER
	plane = FULLSCREEN_PLANE

/// Кривая непрозрачности оверлея: alpha = коэффициент * тяжесть^2. При потолке тяжести 6
/// даёт 360, то есть максимум упирается в потолок альфы, а не в саму кривую.
#define SYNTHCORRUPT_ALPHA_PER_SEVERITY_SQUARED 10
/// Потолок альфы BYOND.
#define SYNTHCORRUPT_ALPHA_MAX 255

/atom/movable/screen/fullscreen/scaled/synthcorrupt
	icon = 'icons/screen/fullscreen/synthcorrupt.dmi'
	icon_state = "synthcorrupt"
	layer = UI_DAMAGE_LAYER
	plane = GRAVITY_PULSE_PLANE
	vis_flags = VIS_INHERIT_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	severity_max = 6
	severity_min = 0
	var/obj/effect/synthcorrupt_particles_holder/holder

/**
 * ОДИН эмиттер на оверлей, а не по эмиттеру на вызов.
 *
 * overlay_fullscreen() ПЕРЕИСПОЛЬЗУЕТ уже созданный экранный объект (пересоздаёт его
 * только при смене типа) и зовёт SetSeverity() КАЖДЫЙ раз. А зовут его из
 * update_damage_hud() при любом ненулевом токсинном уроне, то есть на каждом обновлении
 * здоровья - раз в тик Life() у отравленного моба.
 *
 * Прежняя версия на каждый такой вызов делала new() и LAZYADD в vis_contents, затирая
 * ссылку holder и не убирая предыдущий холдер ниоткуда: ни из vis_contents, ни из
 * contents (loc холдера - сам экранный объект). Destroy() чистил только ПОСЛЕДНИЙ.
 * Каждый осиротевший холдер при этом остаётся живым эмиттером /particles на 960x960
 * с count до 300 - и рисует его клиент.
 *
 * Раунд 10129 (27.08.2026): 32-битный Dream Seeker набирал 2.4 ГБ за восемь минут и
 * падал около 3400 МБ, а перед падением рисовал чужие спрайты вместо штатных и
 * чёрно-белые квадраты вместо тайлов - это исчерпание адресного пространства клиента.
 * В чате раунда: "персонажи заменяются на любой рандомный спрайт чего-то".
 *
 * Гейт isrobotic() стоит в ShouldShow(), а тот вызывается ПОСЛЕ SetSeverity(), поэтому
 * холдеры копил любой отравленный карбон, а не только синтетик.
 */
/atom/movable/screen/fullscreen/scaled/synthcorrupt/SetSeverity(severity)
	var/new_severity = clamp(severity, severity_min, severity_max)
	src.alpha = clamp(SYNTHCORRUPT_ALPHA_PER_SEVERITY_SQUARED * new_severity ** 2, 0, SYNTHCORRUPT_ALPHA_MAX)
	// Тот же уровень при живом холдере - работы нет. Именно этот путь и был горячим:
	// урон стоит на месте, а хендлер здоровья дёргается каждый тик.
	if(src.severity == new_severity && !QDELETED(holder))
		return
	src.severity = new_severity
	if(holder)
		LAZYREMOVE(vis_contents, holder)
		QDEL_NULL(holder)
	// Нулевая тяжесть - это alpha 0, эмиттер под ней всё равно не виден.
	if(!new_severity)
		return
	// Тяжесть берём КЛАМПНУТУЮ: count и spawning считаются от неё, и сырой аргумент
	// выше severity_max раздул бы эмиттер мимо потолка.
	holder = new(src, new_severity)
	LAZYADD(vis_contents, holder)

#undef SYNTHCORRUPT_ALPHA_PER_SEVERITY_SQUARED
#undef SYNTHCORRUPT_ALPHA_MAX

/atom/movable/screen/fullscreen/scaled/synthcorrupt/Destroy()
	if(holder)
		LAZYREMOVE(vis_contents, holder)
		QDEL_NULL(holder)
	return ..()

/obj/effect/synthcorrupt_particles_holder
	alpha = 255
	plane = FIELD_OF_VISION_LAYER
	appearance_flags = PIXEL_SCALE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	vis_flags = VIS_INHERIT_LAYER

/obj/effect/synthcorrupt_particles_holder/New(loc, severity)
	. = ..()
	var/particles/synthcorrupt_particles/particle = new
	particle.spawning = severity * 10
	particle.count = severity * 50
	particles = particle

/particles/synthcorrupt_particles
	icon = 'icons/screen/particle.dmi'
	icon_state = "synthcorrupt"
	width = 960
	height = 960
	count = 300
	spawning = 30
	lifespan = 1
	fade = 1
	// Границы списком, а не vector(): в типовом дефолте SpacemanDMM считает vector()
	// неконстантным вызовом и валит линтер, а generator("box", ...) читает список
	// ровно так же. Остальные пять generator("box") в кодбазе тоже на списках.
	position = generator("box", list(-480, -480), list(480, 480))

/atom/movable/screen/fullscreen/scaled/synthcorrupt/ShouldShow(mob/M)
	if(!..())
		return FALSE

	if(!isrobotic(M))
		return FALSE

	return TRUE

/atom/movable/screen/fullscreen/scaled/bloodloss
	icon_state = "passage"
	layer = UI_DAMAGE_LAYER
	plane = FULLSCREEN_PLANE
	severity_max = 10

/atom/movable/screen/fullscreen/scaled/bloodloss/ShouldShow(mob/M)
	if(!..())
		return FALSE

	if(isrobotic(M))
		return FALSE

	return TRUE

/atom/movable/screen/fullscreen/scaled/crit
	icon_state = "passage"
	layer = CRIT_LAYER
	plane = FULLSCREEN_PLANE

/atom/movable/screen/fullscreen/scaled/crit/vision
	icon_state = "oxydamageoverlay"
	layer = BLIND_LAYER

/atom/movable/screen/fullscreen/scaled/blind
	icon = 'icons/screen/fullscreen/blind.dmi'
	icon_state = "blackimageoverlay"
	layer = BLIND_LAYER
	plane = FULLSCREEN_PLANE

/atom/movable/screen/fullscreen/scaled/curse
	icon = 'icons/screen/fullscreen/curse.dmi'
	icon_state = "curse"
	layer = CURSE_LAYER
	plane = FULLSCREEN_PLANE

/atom/movable/screen/fullscreen/scaled/impaired
	icon_state = "impairedoverlay"

/atom/movable/screen/fullscreen/scaled/emergency_meeting
	icon = 'icons/screen/fullscreen/emergency_meeting.dmi'
	icon_state = "emergency_meeting"
	show_when_dead = TRUE
	layer = CURSE_LAYER
	plane = SPLASHSCREEN_PLANE

/atom/movable/screen/fullscreen/tiled/blurry
	icon = 'icons/mob/screen_gen.dmi'
	screen_loc = "WEST,SOUTH to EAST,NORTH"
	icon_state = "cloudy"

/atom/movable/screen/fullscreen/tiled/flash
	icon = 'icons/mob/screen_gen.dmi'
	screen_loc = "WEST,SOUTH to EAST,NORTH"
	icon_state = "flash"

/atom/movable/screen/fullscreen/flash
	icon = 'icons/mob/screen_gen.dmi'
	screen_loc = "WEST,SOUTH to EAST,NORTH"
	icon_state = "flash"
	layer = FLASH_LAYER

/atom/movable/screen/fullscreen/flash/infernal
	color = "#CC4400"
	alpha = 200
	blend_mode = BLEND_OVERLAY

/atom/movable/screen/fullscreen/flash/infernal/SetSeverity(severity)
	src.severity = severity
	icon_state = initial(icon_state)

/atom/movable/screen/fullscreen/tiled/flash/static
	icon = 'icons/mob/screen_gen.dmi'
	screen_loc = "WEST,SOUTH to EAST,NORTH"
	icon_state = "noise"

/atom/movable/screen/fullscreen/tiled/high
	icon = 'icons/mob/screen_gen.dmi'
	screen_loc = "WEST,SOUTH to EAST,NORTH"
	icon_state = "druggy"

/atom/movable/screen/fullscreen/tiled/color_vision
	icon = 'icons/mob/screen_gen.dmi'
	screen_loc = "WEST,SOUTH to EAST,NORTH"
	icon_state = "flash"
	alpha = 80

/atom/movable/screen/fullscreen/tiled/color_vision/green
	color = "#00ff00"

/atom/movable/screen/fullscreen/tiled/color_vision/red
	color = "#ff0000"

/atom/movable/screen/fullscreen/tiled/color_vision/blue
	color = "#0000ff"

/atom/movable/screen/fullscreen/tiled/cinematic_backdrop
	icon = 'icons/mob/screen_gen.dmi'
	screen_loc = "WEST,SOUTH to EAST,NORTH"
	icon_state = "flash"
	plane = SPLASHSCREEN_PLANE
	layer = SPLASHSCREEN_LAYER - 1
	color = "#000000"
	show_when_dead = TRUE

/atom/movable/screen/fullscreen/special/lighting_backdrop
	icon = 'icons/mob/screen_gen.dmi'
	icon_state = "flash"
	transform = matrix(200, 0, 0, 0, 200, 0)
	plane = LIGHTING_PLANE
	blend_mode = BLEND_OVERLAY
	show_when_dead = TRUE

//Provides darkness to the back of the lighting plane
/atom/movable/screen/fullscreen/special/lighting_backdrop/lit
	invisibility = INVISIBILITY_LIGHTING
	layer = BACKGROUND_LAYER+21
	color = "#000"
	show_when_dead = TRUE

//Provides whiteness in case you don't see lights so everything is still visible
/atom/movable/screen/fullscreen/special/lighting_backdrop/unlit
	layer = BACKGROUND_LAYER+20
	show_when_dead = TRUE

/atom/movable/screen/fullscreen/special/see_through_darkness
	icon_state = "nightvision"
	plane = LIGHTING_PLANE
	layer = LIGHTING_LAYER
	blend_mode = BLEND_ADD
	show_when_dead = TRUE

/atom/movable/screen/fullscreen/bluespace_sparkle
	icon = 'icons/effects/effects.dmi'
	screen_loc = "WEST,SOUTH to EAST,NORTH"
	icon_state = "shieldsparkles"
	layer = FLASH_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	show_when_dead = TRUE

/atom/movable/screen/fullscreen/scaled/depression
	icon = 'icons/screen/fullscreen/depression.dmi'
	icon_state = "depression"
	layer = FLASH_LAYER
	plane = FULLSCREEN_PLANE
	blend_mode = 3
