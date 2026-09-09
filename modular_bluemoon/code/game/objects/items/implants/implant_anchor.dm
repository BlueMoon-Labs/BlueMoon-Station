/// Z-уровни, доступные всем носителям anchor-импланта (общий «локальный сектор»).
GLOBAL_LIST_INIT(anchor_implant_allowed_z_levels, list())

/obj/item/implant/anchor
	name = "anchor implant"
	desc = "A neural anchor fused into the cerebral cortex. Prevents the host from leaving their assigned sector."
	removable = FALSE
	activated = FALSE
	var/contributed_sector = FALSE
	var/obj/item/organ/brain/linked_brain

/// Passed to removed() when the implant must temporarily detach (species transform, etc.)
#define ANCHOR_IMPLANT_TEMP_REMOVE 1

/obj/item/implant/anchor/get_data()
	var/dat = {"<b>Implant Specifications:</b><BR>
				<b>Name:</b> Employee Anchor Implant (ЯКОРЬ / ANCHOR)<BR>
				<b>Implant Details:</b> Prevents implanted from leaving local sector, guarded by you.<BR>
				<b>Integration:</b> Permanently fused into the cerebral cortex. Surgical extraction is impossible.<BR>"}
	return dat

/obj/item/implanter/anchor
	name = "Implanter (anchor)"
	imp_type = /obj/item/implant/anchor

/obj/item/implantcase/anchor
	name = "implant case - 'anchor'"
	desc = "A glass case containing an anchor implant."
	imp_type = /obj/item/implant/anchor

/obj/item/implant/anchor/proc/anchor_relaxed_round()
	return GLOB.master_mode in list(ROUNDTYPE_EXTENDED, ROUNDTYPE_DYNAMIC_LIGHT)

/obj/item/implant/anchor/proc/get_anchor_z_levels_for_turf(turf/spawn_turf)
	var/list/levels = list()
	levels += SSmapping.levels_by_trait(ZTRAIT_CENTCOM)
	levels += SSmapping.levels_by_trait(ZTRAIT_PACT_SIEGE)
	levels += SSmapping.levels_by_all_trait(ZTRAITS_LAVALAND_JUNGLE)
	levels += SSmapping.levels_by_trait(ZTRAIT_RESERVED)
	if(anchor_relaxed_round())
		levels += SSmapping.levels_by_trait(ZTRAIT_STATION)
		levels += SSmapping.levels_by_all_trait(ZTRAITS_LAVALAND)
	var/spawn_z = spawn_turf?.z
	if(spawn_z)
		levels |= spawn_z
	var/area/spawn_area = spawn_turf ? get_area(spawn_turf) : null
	// BlueMoon off-station bases (DS-2, InteQ, etc.) share the station + deep space ruin z-levels of the local sector.
	if(istype(spawn_area, /area/ruin/space/has_grav/bluemoon) || istype(spawn_area, /area/InteQ_ship))
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

/obj/item/implant/anchor/proc/is_sector_location(mob/living/owner, turf/my_location, area/my_area)
	if(!my_location || !owner)
		return TRUE
	if(istype(my_area, /area/ruin/space/has_grav/bluemoon) || istype(my_area, /area/InteQ_ship) || istype(my_area, /area/shuttle/sbc_corvette) || istype(my_area, /area/shuttle/inteq))
		return TRUE
	if(SSmapping.level_trait(my_location.z, ZTRAIT_RESERVED))
		return TRUE
	if(anchor_relaxed_round())
		if(SSmapping.level_trait(my_location.z, ZTRAIT_STATION) || SSmapping.level_trait(my_location.z, ZTRAIT_CENTCOM) || is_pact_siege_level(my_location.z))
			return TRUE
	if(my_location.z in GLOB.anchor_implant_allowed_z_levels)
		return TRUE
	return FALSE

/obj/item/implant/anchor/proc/attach_to_brain(mob/living/target)
	detach_from_brain()
	if(!iscarbon(target))
		return
	var/obj/item/organ/brain/brain = target.getorganslot(ORGAN_SLOT_BRAIN)
	if(!brain)
		return
	linked_brain = brain
	RegisterSignal(linked_brain, COMSIG_ORGAN_REMOVED, PROC_REF(on_brain_removed))

/obj/item/implant/anchor/proc/detach_from_brain()
	if(!linked_brain)
		return
	UnregisterSignal(linked_brain, COMSIG_ORGAN_REMOVED)
	linked_brain = null

/obj/item/implant/anchor/proc/on_brain_removed(datum/source)
	SIGNAL_HANDLER
	if(QDELETED(imp_in))
		return
	to_chat(imp_in, span_userdanger("Острая боль в черепе — имплант Якорь врос в мозговую ткань и не отпускает..."))

/obj/item/implant/anchor/implant(mob/living/target, mob/user, silent, force)
	. = ..()
	if(!.)
		return FALSE
	ensure_sector_registered(imp_in || target)
	RegisterSignal(imp_in, COMSIG_LIVING_LIFE, PROC_REF(on_life))
	ADD_TRAIT(target, TRAIT_ANCHOR, "implant")
	target.sec_hud_set_implants()
	attach_to_brain(imp_in || target)
	if(!silent && iscarbon(target))
		to_chat(target, span_notice("Имплант врастает в мозг — извлечь его уже не получится."))
	return TRUE

/obj/item/implant/anchor/removed(mob/living/source, silent = FALSE, special = 0)
	if(special != ANCHOR_IMPLANT_TEMP_REMOVE && !QDELING(src))
		if(isliving(source) && usr)
			to_chat(usr, span_warning("[src] врос в мозг [source] — извлечь его невозможно."))
		return FALSE
	if(imp_in)
		UnregisterSignal(imp_in, COMSIG_LIVING_LIFE)
	detach_from_brain()
	REMOVE_TRAIT(source, TRAIT_ANCHOR, "implant")
	return ..()

/obj/item/implant/anchor/Destroy()
	if(imp_in)
		UnregisterSignal(imp_in, COMSIG_LIVING_LIFE)
	detach_from_brain()
	return ..()

/obj/item/implant/anchor/proc/on_life(datum/source, seconds_per_tick, times_fired)
	SIGNAL_HANDLER
	var/mob/living/owner = source
	if(QDELETED(owner) || owner.stat == DEAD)
		return

	var/turf/my_location = get_turf(owner)
	if(!my_location)
		return

	if(is_sector_location(owner, my_location, get_area(owner)))
		return

	to_chat(owner, span_warning("Больно!"))
	owner.adjustBruteLoss(5, FALSE)
	owner.adjustFireLoss(5, FALSE)
	owner.adjustOrganLoss(ORGAN_SLOT_BRAIN, 10)
	to_chat(owner, span_warning("Мне становится плохо при отдалении от своего родного сектора..."))
