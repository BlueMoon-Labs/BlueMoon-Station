/datum/component/simple_bodycam
	dupe_mode = COMPONENT_DUPE_UNIQUE
	var/obj/machinery/camera/bodycam
	var/camera_update_time = 0.5 SECONDS

/datum/component/simple_bodycam/Initialize(
	camera_name = "bodycam",
	c_tag = capitalize(camera_name),
	network = "ss13",
	emp_proof = FALSE,
	camera_update_time = 0.5 SECONDS,
)
	if(!isliving(parent))
		return COMPONENT_INCOMPATIBLE

	src.camera_update_time = camera_update_time

	bodycam = new(parent)
	bodycam.network = list(network)
	bodycam.name = camera_name
	bodycam.c_tag = c_tag
	bodycam.internal_light = FALSE
	bodycam.use_power = NO_POWER_USE
	bodycam.view_range = 3
	bodycam.invisibility = INVISIBILITY_ABSTRACT
	bodycam.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	if(emp_proof)
		bodycam.AddElement(/datum/element/empprotection, EMP_PROTECT_SELF | EMP_PROTECT_WIRES | EMP_PROTECT_CONTENTS)

	RegisterSignal(parent, COMSIG_MOVABLE_MOVED, PROC_REF(update_cam))
	RegisterSignal(parent, COMSIG_ATOM_DIR_CHANGE, PROC_REF(rotate_cam))
	RegisterSignals(bodycam, list(COMSIG_QDELETING, COMSIG_MOVABLE_MOVED), PROC_REF(camera_gone))

	do_update_cam()

/datum/component/simple_bodycam/UnregisterFromParent()
	UnregisterSignal(parent, list(COMSIG_MOVABLE_MOVED, COMSIG_ATOM_DIR_CHANGE))

/datum/component/simple_bodycam/Destroy()
	if(QDELETED(bodycam))
		bodycam = null
	else
		QDEL_NULL(bodycam)
	return ..()

/datum/component/simple_bodycam/CheckDupeComponent(
	datum/component/simple_bodycam/new_bodycam,
	camera_name,
	c_tag,
	network = "ss13",
	emp_proof,
	camera_update_time,
)
	return (network in bodycam.network)

/datum/component/simple_bodycam/proc/update_cam(datum/source, atom/old_loc, ...)
	SIGNAL_HANDLER

	if(get_turf(old_loc) != get_turf(parent))
		do_update_cam()

/datum/component/simple_bodycam/proc/do_update_cam()
	GLOB.cameranet.updatePortableCamera(bodycam)

/datum/component/simple_bodycam/proc/rotate_cam(datum/source, old_dir, new_dir)
	SIGNAL_HANDLER

	bodycam.setDir(new_dir)

/datum/component/simple_bodycam/proc/camera_gone(datum/source)
	SIGNAL_HANDLER

	if(!QDELETED(src))
		qdel(src)
