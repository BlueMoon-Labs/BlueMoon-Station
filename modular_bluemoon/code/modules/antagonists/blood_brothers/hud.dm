/datum/atom_hud/antag/brother

/datum/atom_hud/antag/brother/should_show_to(mob/viewer, atom/movable/target)
	if(isobserver(viewer))
		return TRUE
	if(!viewer?.mind || !ismob(target))
		return FALSE
	var/mob/target_mob = target
	if(!target_mob.mind)
		return FALSE
	var/datum/antagonist/brother/target_brother = target_mob.mind.has_antag_datum(/datum/antagonist/brother)
	if(!target_brother)
		return FALSE
	var/datum/antagonist/brother/viewer_brother = viewer.mind.has_antag_datum(/datum/antagonist/brother)
	return viewer_brother?.team == target_brother.team && !viewer_brother.is_muted()

/// Глушение меняет, что брат видит: показанные значки снимаются и выдаются заново
/datum/atom_hud/antag/brother/proc/refresh_viewer(mob/viewer)
	if(!viewer?.client || !hudusers[viewer] || queued_to_see[viewer])
		return
	var/list/shown = list()
	collect_hud_images_for(viewer, shown, check_visibility = FALSE, z_group = HUD_Z_GROUP_ANY)
	remove_hud_images(viewer, shown)
	push_all_atoms_to_user(viewer)
