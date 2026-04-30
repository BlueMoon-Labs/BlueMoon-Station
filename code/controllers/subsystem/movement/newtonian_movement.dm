/// Movement subsystem for space drift / newtonian move loops. Keeps the same bucketing as SSmovement; separate from SSmovement so a mob can have normal movement and drift.
MOVEMENT_SUBSYSTEM_DEF(newtonian_movement)
	name = "Newtonian Movement"
	flags = SS_NO_INIT | SS_TICKER
	wait = 1
	runlevels = RUNLEVEL_GAME | RUNLEVEL_POSTGAME

/**
 * Run one drift move tick immediately, then re-queue (hides the old inertia_next_move pause).
 */
/datum/controller/subsystem/movement/newtonian_movement/proc/fire_moveloop(datum/move_loop/loop)
	if(QDELETED(loop) || !loop.moving)
		return
	// If not in the bucket, do nothing — processing without a matching dequeue can duplicate the loop or corrupt buckets.
	var/list/entries = buckets["[loop.timer]"]
	if(!length(entries) || !(loop in entries))
		return
	dequeue_loop(loop)
	loop.process()
	if(QDELETED(loop))
		return
	loop.timer = world.time + loop.delay
	queue_loop(loop)
