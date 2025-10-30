/datum/component/phase_shift
	dupe_mode = COMPONENT_DUPE_UNIQUE

/datum/component/phase_shift/Initialize()
	if(!isatom(parent))
		return COMPONENT_INCOMPATIBLE
	if(!SEND_SIGNAL(parent, COMSIG_CHECK_CAN_EXIST_IN_PHASE_SHIFT))
		return

	var/mob/atom_parent = parent
	atom_parent.layer = PHASE_SHIFT_FILTER_LAYER + 0.1
	atom_parent.invisibility = INVISIBILITY_SHADEKIN
	atom_parent.see_invisible = SEE_INVISIBILITY_SHADEKIN
	atom_parent.movement_type = (PHASING | FLYING)
	atom_parent.alpha = 90
