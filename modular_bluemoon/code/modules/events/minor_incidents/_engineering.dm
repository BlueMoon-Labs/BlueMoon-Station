/// Визуальная пристройка к атому через vis_contents: следует за носителем и исчезает вместе с ним.
/obj/effect/minor_incident_overlay
	icon = null
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	appearance_flags = RESET_COLOR|RESET_ALPHA|PIXEL_SCALE
	layer = FLOAT_LAYER
	plane = FLOAT_PLANE
	var/atom/movable/host
	/// Через сколько пристройка снимается сама; null - пока её не уберёт владелец.
	var/lifetime
	var/particle_type

/obj/effect/minor_incident_overlay/Initialize(mapload, atom/movable/new_host)
	. = ..()
	if(QDELETED(new_host))
		return INITIALIZE_HINT_QDEL
	host = new_host
	host.vis_contents += src
	RegisterSignal(host, COMSIG_PARENT_QDELETING, PROC_REF(on_host_deleted))
	if(particle_type)
		particles = new particle_type
	if(lifetime)
		addtimer(CALLBACK(src, PROC_REF(expire)), lifetime)

/obj/effect/minor_incident_overlay/proc/expire()
	qdel(src)

/obj/effect/minor_incident_overlay/proc/on_host_deleted(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/obj/effect/minor_incident_overlay/Destroy()
	if(host)
		host.vis_contents -= src
		UnregisterSignal(host, COMSIG_PARENT_QDELETING)
		host = null
	particles = null
	return ..()
