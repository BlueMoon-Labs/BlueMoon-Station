///Поддерживает плоский compatibility-реестр и дешёвые z-бакеты AI-целей.
/datum/component/hostile_machine_registry
	var/registered_z

/datum/component/hostile_machine_registry/Initialize()
	if(!ismovable(parent))
		return COMPONENT_INCOMPATIBLE

/datum/component/hostile_machine_registry/RegisterWithParent()
	. = ..()
	GLOB.hostile_machines |= parent
	var/turf/parent_turf = get_turf(parent)
	update_z_registration(parent_turf?.z)
	RegisterSignal(parent, COMSIG_MOVABLE_Z_CHANGED, PROC_REF(on_z_changed))
	RegisterSignal(parent, COMSIG_MOVABLE_ENTERED_NULLSPACE, PROC_REF(on_z_changed))

/datum/component/hostile_machine_registry/UnregisterFromParent()
	GLOB.hostile_machines -= parent
	update_z_registration(null)
	UnregisterSignal(parent, list(COMSIG_MOVABLE_Z_CHANGED, COMSIG_MOVABLE_ENTERED_NULLSPACE))
	return ..()

/datum/component/hostile_machine_registry/proc/on_z_changed(atom/movable/source, old_z, new_z)
	SIGNAL_HANDLER
	if(isturf(new_z))
		var/turf/new_turf = new_z
		new_z = new_turf.z
	update_z_registration(new_z)

/datum/component/hostile_machine_registry/proc/update_z_registration(new_z)
	if(registered_z && registered_z <= length(GLOB.hostile_machines_by_zlevel))
		GLOB.hostile_machines_by_zlevel[registered_z] -= parent
	registered_z = new_z
	if(!registered_z)
		return
	while(length(GLOB.hostile_machines_by_zlevel) < registered_z)
		GLOB.hostile_machines_by_zlevel.len++
		GLOB.hostile_machines_by_zlevel[GLOB.hostile_machines_by_zlevel.len] = list()
	GLOB.hostile_machines_by_zlevel[registered_z] |= parent
