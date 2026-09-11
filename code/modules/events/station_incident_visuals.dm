/// Небольшие локальные эффекты. Частицы рисует клиент; сервер не создаёт предмет на каждую пылинку.
/particles/incident_dust
	width = 64
	height = 48
	count = 18
	spawning = 3
	lifespan = 8
	fade = 5
	color = "#bbae9b"
	scale = generator("num", 1, 2)
	grow = 0.15
	position = generator("box", list(-10, -8, 0), list(10, -4, 0))
	velocity = generator("vector", list(-1, 0, 0), list(1, 0.6, 0))

/particles/incident_confetti
	width = 64
	height = 64
	count = 28
	spawning = 4
	lifespan = 12
	fade = 5
	color = "#f4cd69"
	scale = list(2, 1)
	spin = generator("num", -12, 12)
	position = generator("box", list(-6, 4, 0), list(6, 8, 0))
	velocity = generator("vector", list(-1.5, 1, 0), list(1.5, 2.5, 0))
	gravity = list(0, -0.2, 0)

/particles/incident_sprouts
	width = 48
	height = 48
	count = 16
	spawning = 2
	lifespan = 12
	fade = 6
	color = "#9cce63"
	scale = list(1, 3)
	spin = generator("num", -4, 4)
	position = generator("box", list(-9, 0, 0), list(9, 5, 0))
	velocity = generator("vector", list(-0.4, 0.4, 0), list(0.4, 0.8, 0))

/particles/incident_pollen
	width = 96
	height = 96
	count = 32
	spawning = 1
	lifespan = 25
	fade = 12
	fadein = 3
	color = "#edd675"
	scale = generator("num", 1, 2)
	position = generator("box", list(-9, 4, 0), list(9, 12, 0))
	velocity = generator("vector", list(-0.7, 0.3, 0), list(0.7, 1, 0))
	drift = generator("vector", list(-0.04, 0, 0), list(0.04, 0.02, 0))

/obj/effect/temp_visual/incident_particles
	icon = null
	randomdir = FALSE
	duration = 2 SECONDS
	var/particle_type = /particles/incident_dust

/obj/effect/temp_visual/incident_particles/Initialize(mapload)
	. = ..()
	particles = new particle_type

/obj/effect/temp_visual/incident_particles/Destroy()
	particles = null
	return ..()

/obj/effect/temp_visual/incident_particles/confetti
	particle_type = /particles/incident_confetti

/obj/effect/temp_visual/incident_particles/sprouts
	particle_type = /particles/incident_sprouts

/// Бумажный силуэт разлетается над копиром; реальные бланки остаются обычными предметами.
/obj/effect/temp_visual/incident_paper
	icon = 'icons/obj/bureaucracy.dmi'
	icon_state = "paper"
	randomdir = FALSE
	duration = 1.2 SECONDS
	pixel_y = 8

/obj/effect/temp_visual/incident_paper/Initialize(mapload)
	. = ..()
	var/matrix/start_transform = matrix()
	start_transform.Scale(0.65)
	start_transform.Turn(rand(-20, 20))
	transform = start_transform
	var/matrix/end_transform = matrix()
	end_transform.Scale(0.65)
	end_transform.Turn(rand(-80, 80))
	animate(src, pixel_x = rand(-20, 20), pixel_y = rand(-8, 18), alpha = 0, transform = end_transform, time = duration)

/obj/effect/temp_visual/incident_short_circuit
	icon = 'icons/effects/effects.dmi'
	icon_state = "sparks"
	randomdir = FALSE
	duration = 0.8 SECONDS

/obj/effect/temp_visual/incident_terminal_static
	icon = 'icons/effects/effects.dmi'
	icon_state = "static"
	randomdir = FALSE
	duration = 0.6 SECONDS
	pixel_y = 8
	alpha = 180

/obj/effect/temp_visual/incident_terminal_static/Initialize(mapload)
	. = ..()
	transform = matrix().Scale(0.55, 0.4)
	animate(src, alpha = 0, time = duration)

/// Облачко привязано к растению через vis_contents и не зависит от его собственного update_icon().
/obj/effect/incident_pollen_cloud
	icon = null
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	appearance_flags = RESET_COLOR|RESET_ALPHA|PIXEL_SCALE
	layer = FLOAT_LAYER
	plane = FLOAT_PLANE
	var/datum/weakref/source_ref

/obj/effect/incident_pollen_cloud/Initialize(mapload, obj/machinery/hydroponics/source)
	. = ..()
	if(QDELETED(source))
		return INITIALIZE_HINT_QDEL
	source_ref = WEAKREF(source)
	particles = new /particles/incident_pollen
	source.vis_contents += src
	RegisterSignal(source, COMSIG_PARENT_QDELETING, PROC_REF(on_source_deleted))

/obj/effect/incident_pollen_cloud/proc/on_source_deleted()
	SIGNAL_HANDLER
	qdel(src)

/obj/effect/incident_pollen_cloud/Destroy()
	var/obj/machinery/hydroponics/source = source_ref?.resolve()
	if(source)
		source.vis_contents -= src
		UnregisterSignal(source, COMSIG_PARENT_QDELETING)
	source_ref = null
	particles = null
	return ..()
