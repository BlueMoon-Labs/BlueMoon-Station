/// Z-уровни, доступные всем носителям anchor-импланта (общий «локальный сектор»).
GLOBAL_LIST_INIT(anchor_implant_allowed_z_levels, list())

/obj/item/implant/anchor
	name = "anchor implant"
	desc = "Prevents you from leaving local sector, guarded by you."
	removable = FALSE
	var/contributed_sector = FALSE

/obj/item/implant/anchor/get_data()
	var/dat = {"<b>Implant Specifications:</b><BR>
				<b>Name:</b> Employee Anchor Implant<BR>
				<b>Implant Details:</b> Prevents implanted from leaving local sector, guarded by you.<BR>"}
	return dat

/obj/item/implanter/anchor
	name = "Implanter (anchor)"
	imp_type = /obj/item/implant/anchor

/obj/item/implantcase/anchor
	name = "implant case - 'anchor'"
	desc = "A glass case containing an anchor implant."
	imp_type = /obj/item/implant/anchor

/obj/item/implant/anchor/proc/get_anchor_z_levels_for_turf(turf/spawn_turf)
	var/list/levels = list()
	levels += SSmapping.levels_by_trait(ZTRAIT_CENTCOM)
	levels += SSmapping.levels_by_all_trait(ZTRAITS_LAVALAND_JUNGLE)
	levels += SSmapping.levels_by_trait(ZTRAIT_RESERVED)
	if(GLOB.master_mode == "Extended")
		levels += SSmapping.levels_by_trait(ZTRAIT_STATION)
		levels += SSmapping.levels_by_all_trait(ZTRAITS_LAVALAND)
	var/spawn_z = spawn_turf?.z
	if(spawn_z)
		levels |= spawn_z
	var/area/spawn_area = spawn_turf ? get_area(spawn_turf) : null
	// BlueMoon off-station bases (DS-2, InteQ, etc.) share the station + deep space ruin z-levels of the local sector.
	if(istype(spawn_area, /area/ruin/space/has_grav/bluemoon))
		levels |= SSmapping.levels_by_trait(ZTRAIT_STATION)
		levels |= SSmapping.levels_by_trait(ZTRAIT_SPACE_RUINS)
	return levels

/obj/item/implant/anchor/proc/register_anchor_z_levels(list/new_levels)
	for(var/z in new_levels)
		if(z && !(z in GLOB.anchor_implant_allowed_z_levels))
			GLOB.anchor_implant_allowed_z_levels += z

/obj/item/implant/anchor/proc/ensure_sector_registered(mob/living/target)
	if(contributed_sector || !target)
		return
	var/turf/spawn_turf = get_turf(target)
	if(!spawn_turf)
		return
	contributed_sector = TRUE
	register_anchor_z_levels(get_anchor_z_levels_for_turf(spawn_turf))

/obj/item/implant/anchor/implant(mob/living/target, mob/user, silent, force)
	. = ..()
	if(!.)
		return FALSE
	ensure_sector_registered(imp_in || target)
	RegisterSignal(imp_in, COMSIG_LIVING_LIFE, PROC_REF(on_life))
	ADD_TRAIT(target, TRAIT_ANCHOR, "implant")
	target.sec_hud_set_implants()
	return TRUE

/obj/item/implant/anchor/proc/on_life(mob/living/owner)
	ensure_sector_registered(owner)
	var/turf/my_location = get_turf(owner)
	if(!my_location)
		return
	var/area/my_area = get_area(owner)
	if(istype(my_area, /area/ruin/space/has_grav/bluemoon) || istype(my_area, /area/shuttle/sbc_corvette) || istype(my_area, /area/shuttle/inteq))
		return
	if(SSmapping.level_trait(my_location.z, ZTRAIT_RESERVED))
		return
	if(my_location.z in GLOB.anchor_implant_allowed_z_levels)
		return
	to_chat(owner, "<span class='warning'>Больно!</span>")
	owner.adjustBruteLoss(5, FALSE)
	owner.adjustFireLoss(5, FALSE)
	owner.adjustOrganLoss(ORGAN_SLOT_BRAIN, 10)
	to_chat(owner, "<span class='warning'>Мне становится плохо при отдалении от своего родного сектора...</span>")
