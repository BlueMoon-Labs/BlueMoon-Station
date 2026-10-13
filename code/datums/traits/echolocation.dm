#define ECHO_CLOSED_EYES "echolocation_closed_eyes"
#define ECHO_COOLDOWN (3 SECONDS)
#define ECHO_WAVE_INTERVAL (0.35 SECONDS)
#define ECHO_TRAVEL_TIME (0.1 SECONDS)
#define ECHO_HOLD_TIME (0.6 SECONDS)
#define ECHO_FADE_TIME (1.4 SECONDS)
#define ECHO_MAX_VISUALS 1200
#define ECHO_MAX_EAR_DAMAGE 70
#define ECHO_TYPING_RANGE 6
#define ECHO_FLOOR_LAYER 1
#define ECHO_STRUCTURE_LAYER 2
#define ECHO_MOB_LAYER 3
#define ECHO_WAVE_LAYER 4
#define ECHO_SOUND_LAYER 5

/**
 * Personal acoustic snapshots never reveal names or track moving shapes.
 * Only ongoing typing indicators follow their audible source until input ends.
 */
/datum/quirk/echolocation
	name = "Эхолокация"
	desc = "При слепоте или с закрытыми глазами щелчки позволяют различать затухающие чёрно-белые силуэты существ, предметов на полу и окружающих конструкций. Провалы, лава и жидкая плазма отмечаются разными узорами со светлым контуром по краям. Двойной и тройной щелчки пальцами создают повторные волны. Без рабочих рук можно щёлкать языком, а без рабочего языка — челюстью. Шаги отмечаются кольцами, речь и набор текста — особым индикатором. Для эхолокации нужны слух и воздух. Оглушение, паралич, потеря сознания и повреждение ушей выше 70 отключают её. Стены, закрытые двери и окна задерживают волны."
	// Blindness grants four points. Keep the two-point difference covered by a test.
	value = 2
	gain_text = span_notice("Вы можете различать очертания окружающих объектов по отражённому звуку. Закройте глаза и издайте щелчок.")
	lose_text = span_notice("Вы больше не можете различать очертания окружающих объектов по эху.")
	medical_record_text = "Пациент использует эхолокацию для ориентации в пространстве."
	var/eyes_closed = FALSE
	var/next_echo = 0
	var/datum/action/echolocation_eyes/eye_action
	var/datum/action/echolocation_snap/snap_action
	var/list/echoes = list()
	/// Keep the recipient so logout/transfer can remove every private screen object.
	var/client/echo_client
	var/monitoring_echoes = FALSE

/datum/quirk/echolocation/add()
	eye_action = new(src)
	snap_action = new(src)
	RegisterSignal(quirk_holder, COMSIG_MOB_EMOTE, PROC_REF(on_emote))
	RegisterSignal(quirk_holder, COMSIG_MOB_SOUND_INDICATOR, PROC_REF(on_sound_indicator))
	RegisterSignal(quirk_holder, COMSIG_MOB_BLINDNESS_CHANGED, PROC_REF(on_state_changed))
	RegisterSignal(quirk_holder, COMSIG_MOB_STATCHANGE, PROC_REF(on_state_changed))
	RegisterSignal(quirk_holder, COMSIG_MOB_LOGIN, PROC_REF(on_state_changed))
	RegisterSignal(quirk_holder, COMSIG_MOVABLE_MOVED, PROC_REF(on_moved))
	RegisterSignal(quirk_holder, list(COMSIG_MOB_CLIENT_LOGOUT, COMSIG_MOB_RESET_PERSPECTIVE, COMSIG_MOB_CLIENT_CHANGE_VIEW), PROC_REF(on_view_changed))
	sync_actions()

/datum/quirk/echolocation/remove()
	clear_echoes()
	if(quirk_holder)
		UnregisterSignal(quirk_holder, list(COMSIG_MOB_EMOTE, COMSIG_MOB_SOUND_INDICATOR, COMSIG_MOB_BLINDNESS_CHANGED, COMSIG_MOB_STATCHANGE, COMSIG_MOB_LOGIN, COMSIG_MOVABLE_MOVED, COMSIG_MOB_CLIENT_LOGOUT, COMSIG_MOB_RESET_PERSPECTIVE, COMSIG_MOB_CLIENT_CHANGE_VIEW))
		quirk_holder.clear_fullscreen(ECHO_CLOSED_EYES, 0)
		if(eyes_closed)
			quirk_holder.cure_blind(ECHO_CLOSED_EYES)
	eyes_closed = FALSE
	QDEL_NULL(eye_action)
	QDEL_NULL(snap_action)

/datum/quirk/echolocation/transfer_mob(mob/living/to_mob)
	// The base transfer only changes quirk_holder; detach while the old body is known.
	remove()
	. = ..()
	add()

/datum/quirk/echolocation/proc/on_state_changed()
	SIGNAL_HANDLER
	sync_actions()
	if(!can_listen())
		clear_echoes(stop_monitoring = !should_monitor())

/datum/quirk/echolocation/proc/on_view_changed()
	SIGNAL_HANDLER
	clear_echoes(stop_monitoring = !should_monitor())

/datum/quirk/echolocation/proc/on_moved()
	SIGNAL_HANDLER
	if(!can_listen())
		clear_echoes(stop_monitoring = !should_monitor())
		return
	for(var/atom/movable/screen/echolocation_echo/echo as anything in echoes.Copy())
		if(echo.typist && !echo.refresh_typing())
			remove_echo(echo)
			continue
		if(!echo.update_position(quirk_holder))
			remove_echo(echo)

/datum/quirk/echolocation/proc/sync_actions()
	if(!quirk_holder || QDELETED(quirk_holder))
		return
	if(eyes_closed || !quirk_holder.is_blind())
		eye_action.name = eyes_closed ? "Открыть глаза" : "Закрыть глаза"
		eye_action.desc = eyes_closed ? "Откройте глаза — отголоски рассеются." : "Закройте глаза, чтобы сосредоточиться на отражённых звуках."
		eye_action.Grant(quirk_holder)
		eye_action.UpdateButtons()
	else if(eye_action.owner)
		eye_action.Remove(quirk_holder)
	if(quirk_holder.is_blind())
		// The ordinary blind mask has a small sight hole. Acoustic perception has
		// a completely black backdrop, including for a normally sighted listener.
		var/atom/movable/screen/fullscreen/blackout = quirk_holder.overlay_fullscreen(ECHO_CLOSED_EYES, /atom/movable/screen/fullscreen)
		blackout.icon = 'icons/effects/alphacolors.dmi'
		blackout.icon_state = "white"
		blackout.color = COLOR_BLACK
		blackout.screen_loc = "WEST,SOUTH to EAST,NORTH"
		blackout.plane = FULLSCREEN_PLANE
		blackout.layer = BLIND_LAYER
		snap_action.refresh_click_method()
		snap_action.Grant(quirk_holder)
		snap_action.UpdateButtons()
		if(should_monitor())
			start_monitoring()
	else
		quirk_holder.clear_fullscreen(ECHO_CLOSED_EYES, 0)
		if(snap_action.owner)
			snap_action.Remove(quirk_holder)

/datum/quirk/echolocation/proc/toggle_eyes()
	if(eyes_closed)
		eyes_closed = FALSE
		quirk_holder.cure_blind(ECHO_CLOSED_EYES)
		clear_echoes()
		to_chat(quirk_holder, span_notice("Вы открываете глаза."))
	else
		eyes_closed = TRUE
		quirk_holder.become_blind(ECHO_CLOSED_EYES)
		to_chat(quirk_holder, span_notice("Вы закрываете глаза и сосредотачиваетесь на окружающих звуках."))
	sync_actions()

/// Perception is tied to the body, never a camera, a container's exterior or a ghost.
/datum/quirk/echolocation/proc/can_listen()
	if(QDELETED(quirk_holder) || quirk_holder.stat != CONSCIOUS || !quirk_holder.is_blind() || quirk_holder.IsStun() || quirk_holder.IsParalyzed())
		return FALSE
	if(HAS_TRAIT(quirk_holder, TRAIT_DEAF) || !quirk_holder.can_hear() || !isturf(quirk_holder.loc))
		return FALSE
	if(iscarbon(quirk_holder))
		var/mob/living/carbon/carbon_holder = quirk_holder
		var/obj/item/organ/ears/ears = carbon_holder.getorganslot(ORGAN_SLOT_EARS)
		if(!ears || ears.damage > ECHO_MAX_EAR_DAMAGE)
			return FALSE
	if(quirk_holder.client && quirk_holder.client.eye != quirk_holder)
		return FALSE
	return carries_sound(quirk_holder.loc)

/datum/quirk/echolocation/proc/carries_sound(turf/where)
	if(!isopenturf(where))
		return FALSE
	var/datum/gas_mixture/air = where.return_air()
	return air && air.return_pressure() > SOUND_MINIMUM_PRESSURE

/// Classify the exposed turf, not baseturfs: water and constructed floors may cover chasms.
/datum/quirk/echolocation/proc/surface_hazard(turf/where)
	if(ischasm(where))
		return "chasm"
	// Liquid plasma inherits lava, so it must be checked first.
	if(istype(where, /turf/open/lava/plasma))
		return "plasma"
	if(islava(where))
		return "lava"
	return null

/// Trace the shoreline of each continuous hazard instead of drawing a floor grid through it.
/datum/quirk/echolocation/proc/hazard_edges(turf/where, kind)
	var/edges = NONE
	for(var/direction in GLOB.cardinals)
		if(surface_hazard(get_step(where, direction)) != kind)
			edges |= direction
	return edges

/datum/quirk/echolocation/proc/click_method()
	if(!iscarbon(quirk_holder))
		return "snap"
	var/mob/living/carbon/carbon_holder = quirk_holder
	if(!carbon_holder.restrained())
		for(var/obj/item/bodypart/hand as anything in carbon_holder.hand_bodyparts)
			if(hand && !hand.disabled && !hand.is_pseudopart)
				return "snap"
	var/obj/item/organ/tongue = carbon_holder.getorganslot(ORGAN_SLOT_TONGUE)
	if(tongue && !(tongue.organ_flags & ORGAN_FAILING))
		return "tongueclick"
	return "jawclick"

/datum/quirk/echolocation/proc/can_snap(method = null)
	if(!can_listen() || world.time < next_echo)
		return FALSE
	// The action selects a fallback; manually chosen emotes keep their own requirements.
	if(isnull(method))
		method = click_method()
	if(method == "tongueclick" || method == "jawclick")
		if(!iscarbon(quirk_holder))
			return FALSE
		var/mob/living/carbon/carbon_holder = quirk_holder
		if(method == "tongueclick")
			var/obj/item/organ/tongue = carbon_holder.getorganslot(ORGAN_SLOT_TONGUE)
			if(!tongue || (tongue.organ_flags & ORGAN_FAILING))
				return FALSE
		return carbon_holder.get_bodypart(BODY_ZONE_HEAD) && !carbon_holder.is_muzzled()
	if(!(method in list("snap", "snap2", "snap3")))
		return FALSE
	if(quirk_holder.restrained() || !CHECK_MOBILITY(quirk_holder, MOBILITY_USE))
		return FALSE
	for(var/hand_index in quirk_holder.get_empty_held_indexes())
		if(!quirk_holder.has_hand_for_held_index(hand_index))
			continue
		if(iscarbon(quirk_holder))
			var/mob/living/carbon/carbon_holder = quirk_holder
			var/obj/item/bodypart/hand = carbon_holder.hand_bodyparts[hand_index]
			if(!hand || hand.disabled || hand.is_pseudopart)
				continue
		return TRUE
	return FALSE

/datum/quirk/echolocation/proc/on_emote(datum/source, datum/emote/emote)
	SIGNAL_HANDLER
	var/pulses
	if(istype(emote, /datum/emote/sound/human/snap))
		pulses = 1
	else if(istype(emote, /datum/emote/sound/human/snap2))
		pulses = 2
	else if(istype(emote, /datum/emote/sound/human/snap3))
		pulses = 3
	else if(istype(emote, /datum/emote/sound/human/tongueclick) || istype(emote, /datum/emote/sound/human/jawclick))
		pulses = 1
	if(pulses && can_snap(emote.key))
		next_echo = world.time + ECHO_COOLDOWN
		pulse(pulses)
		snap_action.UpdateButtons()

/// Full tiles stop the wave; directional panes block their edge, not the whole tile.
/datum/quirk/echolocation/proc/blocks_echo(turf/where, direction)
	if(isclosedturf(where))
		return TRUE
	for(var/obj/obstacle in where)
		if(!obstacle.density)
			continue
		if(istype(obstacle, /obj/machinery/door))
			return TRUE
		if(istype(obstacle, /obj/structure/window))
			var/obj/structure/window/window = obstacle
			if(window.fulltile || window.dir == direction)
				return TRUE
	return FALSE

/// Negative distances mark reflecting boundaries. A later open edge may still reach them.
/datum/quirk/echolocation/proc/collect_echo_turfs(turf/origin, width, height)
	var/list/reached = list()
	reached[origin] = 0
	var/list/queue = list(origin)
	for(var/index in 1 to width * height)
		if(index > length(queue))
			break
		var/turf/current = queue[index]
		if(current != origin && (blocks_echo(current, NONE) || !carries_sound(current)))
			continue
		for(var/direction in GLOB.cardinals)
			if(blocks_echo(current, direction))
				continue
			var/turf/next = get_step(current, direction)
			if(!next || abs(next.x - origin.x) > (width - 1) / 2 || abs(next.y - origin.y) > (height - 1) / 2)
				continue
			if((next in reached) && reached[next] >= 0)
				continue
			if(blocks_echo(next, turn(direction, 180)) || !carries_sound(next))
				reached[next] = -(reached[current] + 1)
				continue
			reached[next] = reached[current] + 1
			queue += next
	return reached

/// Only exposed physical objects reflect a pulse; held and contained items do not.
/datum/quirk/echolocation/proc/can_echo_atom(atom/movable/thing, boundary = FALSE)
	if(!isturf(thing.loc) || thing.invisibility || thing.alpha <= 0)
		return FALSE
	if(!isliving(thing) && !isstructure(thing) && !ismachinery(thing) && !isitem(thing))
		return FALSE
	if(boundary && !istype(thing, /obj/machinery/door) && !istype(thing, /obj/structure/window))
		return FALSE
	return !isliving(thing) || !blocks_echo(thing.loc, NONE)

/datum/quirk/echolocation/proc/pulse(pulses)
	if(!quirk_holder.client || !can_listen())
		return
	// A fresh pulse replaces remembered shapes, not an ongoing conversation's bubble.
	for(var/atom/movable/screen/echolocation_echo/old_echo as anything in echoes.Copy())
		if(!old_echo.sound_kind)
			remove_echo(old_echo)
	var/turf/origin = quirk_holder.loc
	var/list/view_size = getviewsize(quirk_holder.client.view)
	var/list/reached = collect_echo_turfs(origin, view_size[1], view_size[2])
	var/max_radius = sqrt(((view_size[1] - 1) / 2) ** 2 + ((view_size[2] - 1) / 2) ** 2) + 1
	for(var/pulse_index in 1 to pulses)
		var/atom/movable/screen/echolocation_echo/wave = create_echo(origin)
		if(!wave)
			break
		wave.icon = wave_icon()
		wave.pixel_x = -48
		wave.pixel_y = -48
		wave.layer = ECHO_WAVE_LAYER
		wave.transform = matrix().Scale(0.05)
		var/delay = (pulse_index - 1) * ECHO_WAVE_INTERVAL
		var/travel_time = max_radius * ECHO_TRAVEL_TIME
		wave.expires = world.time + delay + travel_time
		animate(wave, alpha = 0, time = delay)
		animate(alpha = 180, time = 0)
		animate(transform = matrix().Scale(max_radius * world.icon_size / 60), alpha = 0, time = travel_time)
	for(var/turf/where as anything in reached)
		// Silence is an absence of information, never a fictitious floor over space.
		if(!isclosedturf(where) && !carries_sound(where))
			continue
		var/distance = sqrt((where.x - origin.x) ** 2 + (where.y - origin.y) ** 2)
		var/delay = distance * ECHO_TRAVEL_TIME
		var/atom/movable/screen/echolocation_echo/surface = create_echo(where)
		if(!surface)
			break
		var/brightness = surface.set_surface(where, src)
		surface.reverberate(delay, pulses, brightness)
		for(var/atom/movable/thing in where)
			// A closed container is a single shape; its contents are never traversed.
			if(!can_echo_atom(thing, reached[where] < 0))
				continue
			var/atom/movable/screen/echolocation_echo/shape = create_echo(where)
			if(!shape)
				break
			shape.set_shape(thing)
			shape.reverberate(delay, pulses, isliving(thing) ? 235 : 150)

/// Replaces the ordinary blind/FOV marker for this listener only, including typing.
/datum/quirk/echolocation/proc/on_sound_indicator(datum/source, atom/center, kind, direction, duration)
	SIGNAL_HANDLER
	if(!quirk_holder.is_blind())
		return NONE
	if(!quirk_holder.client || !can_listen() || (center == quirk_holder && kind != "typing"))
		return COMPONENT_SOUND_INDICATOR_HANDLED
	var/turf/origin = get_turf(center)
	if(!origin || !carries_sound(origin) || origin.z != quirk_holder.z)
		return COMPONENT_SOUND_INDICATOR_HANDLED
	var/list/view_size = getviewsize(quirk_holder.client.view)
	if(abs(origin.x - quirk_holder.x) > (view_size[1] - 1) / 2 || abs(origin.y - quirk_holder.y) > (view_size[2] - 1) / 2)
		return COMPONENT_SOUND_INDICATOR_HANDLED
	// A small cap also coalesces noisy crowds without an unbounded timer per sound.
	var/passive_count = 0
	for(var/atom/movable/screen/echolocation_echo/existing as anything in echoes)
		if(!existing.sound_kind)
			continue
		passive_count++
		// Different people can type on one tile and finish at different times.
		if(kind == "typing" ? existing.typist?.resolve() == center : (existing.sound_kind == kind && existing.world_x == origin.x && existing.world_y == origin.y))
			return COMPONENT_SOUND_INDICATOR_HANDLED
	if(passive_count >= 24)
		return COMPONENT_SOUND_INDICATOR_HANDLED
	var/atom/movable/screen/echolocation_echo/marker = create_echo(origin)
	if(!marker)
		return COMPONENT_SOUND_INDICATOR_HANDLED
	marker.sound_kind = kind
	marker.layer = ECHO_SOUND_LAYER
	if(kind == "typing" && ismob(center))
		marker.set_typist(center)
	else if(kind == "talk")
		marker.icon = 'icons/effects/echolocation_speech.png'
		marker.pixel_y = 22
		marker.expires = world.time + 1.5 SECONDS
		animate(marker, alpha = 230, time = 0.15 SECONDS)
		animate(pixel_y = 26, alpha = 180, time = 0.8 SECONDS)
		animate(alpha = 0, time = 0.55 SECONDS)
	else
		marker.icon = wave_icon()
		marker.pixel_x = -48
		marker.pixel_y = -48
		marker.transform = matrix().Scale(0.07)
		marker.expires = world.time + 1 SECONDS
		animate(marker, alpha = 180, time = 0.1 SECONDS)
		animate(transform = matrix().Scale(kind == "footstep" ? 0.28 : 0.45), alpha = 0, time = 0.9 SECONDS)
	return COMPONENT_SOUND_INDICATOR_HANDLED

/datum/quirk/echolocation/proc/create_echo(turf/origin)
	if(!quirk_holder.client || length(echoes) >= ECHO_MAX_VISUALS)
		return
	var/atom/movable/screen/echolocation_echo/echo = new
	echo.world_x = origin.x
	echo.world_y = origin.y
	echo.world_z = origin.z
	echo.update_position(quirk_holder)
	echoes += echo
	echo_client = quirk_holder.client
	echo_client.screen += echo
	start_monitoring()
	return echo

/datum/quirk/echolocation/proc/start_monitoring()
	if(monitoring_echoes)
		return
	monitoring_echoes = TRUE
	START_PROCESSING(SSfastprocess, src)

/datum/quirk/echolocation/proc/should_monitor()
	return !QDELETED(quirk_holder) && quirk_holder.client && quirk_holder.is_blind() && quirk_holder.stat == CONSCIOUS

/datum/quirk/echolocation/process()
	if(QDELETED(quirk_holder))
		clear_echoes()
		return
	snap_action.refresh_click_method()
	snap_action.UpdateButtons(status_only = TRUE)
	// Monitor conscious blind clients, including ear healing and surgery which have
	// no consistent mob-level signal. Only active typing markers need a hearing check.
	if(!should_monitor() || !can_listen() || (echo_client && echo_client != quirk_holder.client))
		clear_echoes(stop_monitoring = !should_monitor())
		return
	var/list/audible_typists
	for(var/atom/movable/screen/echolocation_echo/echo as anything in echoes.Copy())
		if(world.time >= echo.expires)
			remove_echo(echo)
			continue
		if(!echo.typist)
			continue
		var/mob/typing_mob = echo.refresh_typing()
		if(!typing_mob || !carries_sound(typing_mob.loc) || !echo.update_position(quirk_holder))
			remove_echo(echo)
			continue
		if(typing_mob == quirk_holder)
			continue
		// At most one native hearing query per listener, and none while nobody types.
		if(isnull(audible_typists))
			audible_typists = hearers(ECHO_TYPING_RANGE, quirk_holder)
		if(!(typing_mob in audible_typists))
			remove_echo(echo)

/datum/quirk/echolocation/proc/remove_echo(atom/movable/screen/echolocation_echo/echo)
	echo_client?.screen -= echo
	echoes -= echo
	qdel(echo)

/datum/quirk/echolocation/proc/clear_echoes(stop_monitoring = TRUE)
	if(stop_monitoring && monitoring_echoes)
		STOP_PROCESSING(SSfastprocess, src)
		monitoring_echoes = FALSE
	if(echo_client)
		echo_client.screen -= echoes
	echo_client = null
	QDEL_LIST(echoes)

/// Procedural rings stay crisp at any view size, without another sprite-sheet family.
/datum/quirk/echolocation/proc/wave_icon()
	var/static/icon/ring
	if(!ring)
		ring = icon('icons/turf/floors.dmi', "floor")
		ring.Scale(128, 128)
		ring.DrawBox(rgb(0, 0, 0, 0), 1, 1, 128, 128)
		for(var/pixel_x in 1 to 128)
			for(var/pixel_y in 1 to 128)
				var/radius = sqrt((pixel_x - 64.5) ** 2 + (pixel_y - 64.5) ** 2)
				var/opacity = max(0, 1 - abs(radius - 60) / 1.5, (1 - abs(radius - 55) / 2) * 0.25)
				if(opacity > 0)
					ring.DrawBox(rgb(255, 255, 255, round(opacity * 255)), pixel_x, pixel_y)
	return ring

/datum/quirk/echolocation/proc/floor_icon()
	var/static/icon/grid
	if(!grid)
		grid = icon('icons/turf/floors.dmi', "floor")
		grid.DrawBox(rgb(0, 0, 0, 0), 1, 1, 32, 32)
		grid.DrawBox(COLOR_WHITE, 1, 1, 32, 1)
		grid.DrawBox(COLOR_WHITE, 1, 1, 1, 32)
	return grid

/// Three monochrome textures, cached for the sixteen possible shoreline masks.
/datum/quirk/echolocation/proc/hazard_icon(kind, edges = NONE)
	var/static/list/hazard_icons = list()
	var/cache_key = "[kind]-[edges]"
	if(hazard_icons[cache_key])
		return hazard_icons[cache_key]
	var/icon/texture = icon('icons/turf/floors.dmi', "floor")
	texture.DrawBox(rgb(0, 0, 0, 0), 1, 1, 32, 32)
	switch(kind)
		if("chasm")
			// Downward chevrons suggest depth while leaving the pit's interior dark.
			for(var/top in list(13, 23))
				for(var/offset in 0 to 6)
					texture.DrawBox(rgb(255, 255, 255, 175), 10 + offset, top - offset)
					texture.DrawBox(rgb(255, 255, 255, 175), 22 - offset, top - offset)
		if("lava")
			// Continuous ripples remain recognizable without the lava's original red glow.
			for(var/row in list(6, 16, 26))
				for(var/column in 1 to 32)
					texture.DrawBox(rgb(255, 255, 255, 190), column, row + round(2 * sin(column * 22.5)))
		if("plasma")
			// Separated bubbles distinguish chilled plasma from the lava's long ripples.
			for(var/list/bubble as anything in list(list(10, 11, 4), list(24, 23, 3)))
				var/radius = bubble[3]
				for(var/offset_x in -radius to radius)
					for(var/offset_y in -radius to radius)
						if(abs(sqrt(offset_x ** 2 + offset_y ** 2) - radius) < 0.6)
							texture.DrawBox(rgb(255, 255, 255, 210), bubble[1] + offset_x, bubble[2] + offset_y)
	if(edges & NORTH)
		texture.DrawBox(COLOR_WHITE, 1, 32, 32, 32)
	if(edges & SOUTH)
		texture.DrawBox(COLOR_WHITE, 1, 1, 32, 1)
	if(edges & EAST)
		texture.DrawBox(COLOR_WHITE, 32, 1, 32, 32)
	if(edges & WEST)
		texture.DrawBox(COLOR_WHITE, 1, 1, 1, 32)
	hazard_icons[cache_key] = texture
	return texture

/atom/movable/screen/echolocation_echo
	name = "эхо"
	icon = null
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	plane = FOV_VISUAL_PLANE
	appearance_flags = APPEARANCE_UI | KEEP_TOGETHER
	alpha = 0
	var/world_x
	var/world_y
	var/world_z
	var/expires = 0
	var/sound_kind
	/// Weak so a typing bubble cannot keep a deleted body alive.
	var/datum/weakref/typist

/atom/movable/screen/echolocation_echo/proc/set_typist(mob/source)
	typist = WEAKREF(source)
	sound_kind = "typing"
	icon = 'icons/effects/echolocation_speech.png'
	pixel_y = 22
	alpha = 210
	expires = INFINITY
	animate(src, alpha = 245, pixel_y = 24, time = 0.6 SECONDS, loop = -1)
	animate(alpha = 175, pixel_y = 22, time = 0.6 SECONDS)

/// Input completion, cancellation, timeout, death and deletion all end the marker.
/atom/movable/screen/echolocation_echo/proc/refresh_typing()
	var/mob/source = typist?.resolve()
	if(!source?.typing_indicator_current || !isturf(source.loc))
		return null
	world_x = source.x
	world_y = source.y
	world_z = source.z
	return source

/atom/movable/screen/echolocation_echo/proc/update_position(mob/listener)
	if(listener.z != world_z || !listener.client)
		return FALSE
	var/offset_x = world_x - listener.x
	var/offset_y = world_y - listener.y
	var/list/view_size = getviewsize(listener.client.view)
	if(abs(offset_x) > (view_size[1] - 1) / 2 || abs(offset_y) > (view_size[2] - 1) / 2)
		return FALSE
	screen_loc = "CENTER[offset_x >= 0 ? "+" : ""][offset_x],CENTER[offset_y >= 0 ? "+" : ""][offset_y]"
	return TRUE

/// Hazards are brighter than ordinary floor edges, below objects and people on top.
/atom/movable/screen/echolocation_echo/proc/set_surface(turf/observed, datum/quirk/echolocation/sense)
	if(isclosedturf(observed))
		set_shape(observed)
		return 165
	var/kind = sense.surface_hazard(observed)
	icon = kind ? sense.hazard_icon(kind, sense.hazard_edges(observed, kind)) : sense.floor_icon()
	layer = ECHO_FLOOR_LAYER
	return kind ? 180 : 45

/atom/movable/screen/echolocation_echo/proc/set_shape(atom/observed)
	// Mutable overlays can inherit their host's direction; freeze both at capture time.
	setDir(observed.dir)
	var/mutable_appearance/source_shape = new(observed.appearance)
	if(ismob(observed))
		var/mob/observed_mob = observed
		// The live acoustic bubble replaces the normal typing overlay, including in snapshots.
		source_shape.overlays -= observed_mob.typing_indicator_current
	var/image/shape = copy_shape_appearance(source_shape, base_shape = TRUE)
	shape.dir = observed.dir
	shape.appearance_flags |= KEEP_TOGETHER
	shape.plane = FLOAT_PLANE
	shape.layer = FLOAT_LAYER
	shape.maptext = null
	shape.filters = null
	overlays += shape
	// Filter the neutral host after the copied object's own tint has been composed.
	color = null
	filters = list(filter(type = "color", color = list(0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,1, 0.6,0.6,0.6,0)), filter(type = "outline", size = 1, color = COLOR_WHITE))
	layer = isliving(observed) ? ECHO_MOB_LAYER : ECHO_STRUCTURE_LAYER

/// Copy physical layers into the monochrome group without turning lighting masks into solid shapes.
/atom/movable/screen/echolocation_echo/proc/copy_shape_appearance(image/source_appearance, base_shape = FALSE)
	if(!base_shape)
		// Check the original plane before rehoming it. The fixture's ordinary bulb overlay stays.
		// LIGHTING_PLANE also names ABOVE_LIGHTING_PLANE here, so it cannot identify light-only layers.
		switch(source_appearance.plane)
			if(FLOOR_LIGHTING_LAMPS_PLANE, FLOOR_LIGHTING_LAMPS_SELFGLOW, FLOOR_LIGHTING_LAMPS_GLARE, LIGHTING_LAMPS_PLANE, LIGHTING_LAMPS_SELFGLOW, LIGHTING_EXPOSURE_PLANE, LIGHTING_LAMPS_GLARE, EMISSIVE_PLANE, EMISSIVE_BLOCKER_PLANE, O_LIGHTING_VISUAL_PLANE)
				return null
	// Images preserve explicitly directed child layers; mutable overlays can reset their dir.
	var/image/shape = image(source_appearance)
	shape.dir = source_appearance.dir
	shape.plane = FLOAT_PLANE
	shape.appearance_flags &= ~KEEP_APART
	if(length(shape.overlays))
		var/list/copied_overlays = list()
		for(var/child_appearance as anything in shape.overlays)
			var/image/child_shape = copy_shape_appearance(child_appearance)
			if(child_shape)
				copied_overlays += child_shape
		shape.overlays = copied_overlays
	if(length(shape.underlays))
		var/list/copied_underlays = list()
		for(var/child_appearance as anything in shape.underlays)
			var/image/child_shape = copy_shape_appearance(child_appearance)
			if(child_shape)
				copied_underlays += child_shape
		shape.underlays = copied_underlays
	return shape

/atom/movable/screen/echolocation_echo/proc/reverberate(delay, pulses, brightness)
	var/repeat_time = (pulses - 1) * ECHO_WAVE_INTERVAL
	expires = world.time + delay + repeat_time + 0.1 SECONDS + ECHO_HOLD_TIME + ECHO_FADE_TIME
	animate(src, alpha = 0, time = delay)
	for(var/pulse_index in 1 to pulses)
		animate(alpha = brightness, time = 0.1 SECONDS)
		if(pulse_index < pulses)
			animate(alpha = round(brightness * 0.45), time = ECHO_WAVE_INTERVAL - 0.1 SECONDS)
	animate(alpha = round(brightness * 0.7), time = ECHO_HOLD_TIME)
	animate(alpha = 0, time = ECHO_FADE_TIME)

/datum/action/echolocation_eyes
	name = "Закрыть глаза"
	icon_icon = 'icons/mob/actions/close_eyes.png'
	check_flags = AB_CHECK_CONSCIOUS
	required_mobility_flags = NONE

/datum/action/echolocation_eyes/ApplyIcon(atom/movable/screen/movable/action_button/current_button, force = FALSE)
	current_button.cut_overlays()
	current_button.add_overlay(mutable_appearance(icon_icon))

/datum/action/echolocation_eyes/Trigger(trigger_flags)
	if(!..())
		return FALSE
	var/datum/quirk/echolocation/sense = target
	sense.toggle_eyes()
	return TRUE

/datum/action/echolocation_snap
	name = "Щёлкнуть пальцами"
	desc = "Издайте щелчок, чтобы увидеть волну эха. Перезарядка: 3 секунды. Работает при слепоте или закрытых глазах; необходимы слух и воздух. Если руки связаны или не работают, кнопка переключается на язык, а если нет и рабочего языка — на челюсть. Для *tongueclick нужен рабочий язык; *jawclick не требует рук или языка. Оглушение и повреждение ушей выше 70 отключают эхолокацию. Для щелчка пальцами нужна свободная рабочая рука, для щелчка ртом — голова и свободный рот."
	icon_icon = 'icons/mob/actions/snap_fingers.png'
	check_flags = AB_CHECK_CONSCIOUS
	required_mobility_flags = NONE
	var/current_method

/datum/action/echolocation_snap/proc/refresh_click_method()
	var/datum/quirk/echolocation/sense = target
	var/new_method = sense.click_method()
	if(new_method == current_method)
		return
	current_method = new_method
	switch(current_method)
		if("snap")
			name = "Щёлкнуть пальцами"
			icon_icon = 'icons/mob/actions/snap_fingers.png'
		if("tongueclick")
			name = "Щёлкнуть языком"
			icon_icon = 'icons/mob/actions/click_tongue.png'
		if("jawclick")
			name = "Щёлкнуть челюстью"
			icon_icon = 'icons/mob/actions/click_jaw.png'
	UpdateButtons()

/datum/action/echolocation_snap/ApplyIcon(atom/movable/screen/movable/action_button/current_button, force = FALSE)
	current_button.cut_overlays()
	current_button.add_overlay(mutable_appearance(icon_icon))

/datum/action/echolocation_snap/IsAvailable(silent = FALSE)
	if(!..())
		return FALSE
	var/datum/quirk/echolocation/sense = target
	return sense.can_snap() && owner.nextsoundemote < world.time

/datum/action/echolocation_snap/Trigger(trigger_flags)
	if(!..())
		return FALSE
	refresh_click_method()
	return owner.emote(current_method, intentional = TRUE)

/datum/emote/sound/human/tongueclick
	name = "Щёлкнуть языком"
	key = "tongueclick"
	key_third_person = "tongueclicks"
	message = "щёлкает языком."
	emote_type = EMOTE_AUDIBLE
	sound = 'modular_bluemoon/sound/voice/barks/centipede_click.ogg'
	emote_pitch_variance = FALSE

/datum/emote/sound/human/tongueclick/can_run_emote(mob/user, status_check = TRUE, intentional = FALSE)
	if(!..() || !iscarbon(user) || user.is_muzzled())
		return FALSE
	var/mob/living/carbon/carbon_user = user
	var/obj/item/organ/tongue = carbon_user.getorganslot(ORGAN_SLOT_TONGUE)
	return tongue && !(tongue.organ_flags & ORGAN_FAILING) && carbon_user.get_bodypart(BODY_ZONE_HEAD)

/datum/emote/sound/human/jawclick
	name = "Щёлкнуть челюстью"
	key = "jawclick"
	key_third_person = "jawclicks"
	message = "щёлкает челюстью."
	emote_type = EMOTE_AUDIBLE
	sound = 'modular_bluemoon/sound/emotes/centipede_clack1.ogg'
	emote_pitch_variance = FALSE

/datum/emote/sound/human/jawclick/can_run_emote(mob/user, status_check = TRUE, intentional = FALSE)
	if(!..() || !iscarbon(user) || user.is_muzzled())
		return FALSE
	var/mob/living/carbon/carbon_user = user
	return !!carbon_user.get_bodypart(BODY_ZONE_HEAD)

#undef ECHO_CLOSED_EYES
#undef ECHO_COOLDOWN
#undef ECHO_WAVE_INTERVAL
#undef ECHO_TRAVEL_TIME
#undef ECHO_HOLD_TIME
#undef ECHO_FADE_TIME
#undef ECHO_MAX_VISUALS
#undef ECHO_MAX_EAR_DAMAGE
#undef ECHO_TYPING_RANGE
#undef ECHO_FLOOR_LAYER
#undef ECHO_STRUCTURE_LAYER
#undef ECHO_MOB_LAYER
#undef ECHO_WAVE_LAYER
#undef ECHO_SOUND_LAYER
