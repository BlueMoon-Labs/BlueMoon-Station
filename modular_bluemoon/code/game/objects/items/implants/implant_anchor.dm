/obj/item/implant/anchor
	name = "anchor implant"
	desc = "Prevents you from leaving local sector, guarded by you."
	removable = FALSE
	var/list/allowed_z_levels


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

/obj/item/implant/anchor/implant(mob/living/target, mob/user, silent, force)
	. = ..()
	if(!.)
		return FALSE
	allowed_z_levels = list()
	allowed_z_levels += SSmapping.levels_by_trait(ZTRAIT_CENTCOM)
	allowed_z_levels += SSmapping.levels_by_all_trait(ZTRAITS_LAVALAND_JUNGLE)
	allowed_z_levels += SSmapping.levels_by_trait(ZTRAIT_RESERVED)
	if(GLOB.master_mode == "Extended")
		allowed_z_levels += SSmapping.levels_by_trait(ZTRAIT_STATION)
		allowed_z_levels += SSmapping.levels_by_all_trait(ZTRAITS_LAVALAND)
	var/turf/spawn_turf = get_turf(target)
	var/spawn_z = spawn_turf ? spawn_turf.z : target.z
	if(spawn_z && !(spawn_z in allowed_z_levels))
		allowed_z_levels += spawn_z

	RegisterSignal(imp_in, COMSIG_LIVING_LIFE, PROC_REF(on_life))
	ADD_TRAIT(target, TRAIT_ANCHOR, "implant")
	target.sec_hud_set_implants()
	return TRUE

/obj/item/implant/anchor/proc/on_life(mob/living/owner)
	var/turf/my_location = get_turf(owner)
	if(!my_location)
		return
	var/area/my_area = get_area(owner)
	if(istype(my_area, /area/shuttle/sbc_corvette))
		return
	if(SSmapping.level_trait(my_location.z, ZTRAIT_RESERVED))
		return
	if(my_location.z in allowed_z_levels)
		return
	to_chat(owner, "<span class='warning'>Больно!</span>")
	owner.adjustBruteLoss(5, FALSE)
	owner.adjustFireLoss(5, FALSE)
	owner.adjustOrganLoss(ORGAN_SLOT_BRAIN, 10)
	to_chat(owner, "<span class='warning'>Мне становится плохо при отдалении от своего родного сектора...</span>")
