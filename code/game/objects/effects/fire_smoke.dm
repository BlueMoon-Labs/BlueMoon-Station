// Fire smoke: particle emitters that follow a burning atom.
// The holder lives in the host's vis_contents (same pattern as
// /obj/effect/abstract/heretic_particle_holder) so particles render at the
// host's position without the holder having a loc of its own.

/particles/smoke
	icon = 'icons/effects/particles/smoke.dmi'
	icon_state = list("smoke_1" = 1, "smoke_2" = 1, "smoke_3" = 2)
	width = 100
	height = 100
	count = 1000
	spawning = 4
	lifespan = 1.5 SECONDS
	fade = 1 SECONDS
	velocity = list(0, 0.4, 0)
	position = list(6, 0, 0)
	drift = generator("box", list(-0.2, -0.2, 0), list(0.2, 0.2, 0))
	friction = 0.2
	gravity = list(0, 0.95)
	grow = 0.05

/particles/smoke/burning
	position = list(0, 0, 0)

/// Weaker smoke for small heat sources like a warming gun barrel.
/particles/smoke/burning/small
	spawning = 1
	scale = list(0.8, 0.8)
	velocity = list(0, 0.4, 0)

/atom/movable
	var/obj/effect/abstract/fire_smoke_holder/fire_smoke_holder

/// Attaches a smoke emitter to this atom. Idempotent: returns the existing holder if present.
/atom/movable/proc/attach_fire_smoke(particles_type = /particles/smoke/burning)
	if(fire_smoke_holder && !QDELETED(fire_smoke_holder))
		return fire_smoke_holder
	if(QDELETED(src))
		return null
	var/obj/effect/abstract/fire_smoke_holder/holder = new(null, particles_type, src)
	if(QDELETED(holder))
		return null
	add_vis_on_floor(holder)
	fire_smoke_holder = holder
	return holder

/atom/movable/proc/remove_fire_smoke()
	if(fire_smoke_holder && !QDELETED(fire_smoke_holder))
		fire_smoke_holder.detach()
	fire_smoke_holder = null

/obj/effect/abstract/fire_smoke_holder
	icon = null
	layer = FLOAT_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	appearance_flags = RESET_COLOR | RESET_TRANSFORM | PIXEL_SCALE
	vis_flags = VIS_INHERIT_PLANE
	var/atom/movable/host

/obj/effect/abstract/fire_smoke_holder/Initialize(mapload, particles_type = /particles/smoke/burning, atom/movable/h = null)
	. = ..()
	if(!ispath(particles_type, /particles) || QDELETED(h))
		return INITIALIZE_HINT_QDEL
	particles = new particles_type
	host = h
	RegisterSignal(host, COMSIG_PARENT_QDELETING, PROC_REF(on_host_qdeleted))

/obj/effect/abstract/fire_smoke_holder/proc/on_host_qdeleted(datum/source, forced)
	SIGNAL_HANDLER
	qdel(src)

/obj/effect/abstract/fire_smoke_holder/proc/detach()
	if(host && !QDELETED(host))
		UnregisterSignal(host, COMSIG_PARENT_QDELETING)
		host.vis_contents -= src
	host = null
	particles = null
	qdel(src)

/obj/effect/abstract/fire_smoke_holder/Destroy()
	if(host && !QDELETED(host))
		UnregisterSignal(host, COMSIG_PARENT_QDELETING)
		host.vis_contents -= src
	particles = null
	return ..()
