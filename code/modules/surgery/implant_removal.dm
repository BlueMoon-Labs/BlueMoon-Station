/datum/surgery/implant_removal
	name = "Implant removal"
	steps = list(/datum/surgery_step/incise, /datum/surgery_step/clamp_bleeders, /datum/surgery_step/retract_skin, /datum/surgery_step/extract_implant, /datum/surgery_step/close)
	target_mobtypes = list(/mob/living/carbon/human, /mob/living/carbon/monkey)
	possible_locs = list(BODY_ZONE_CHEST)
	is_healing = FALSE // BLUEMOON ADD
	icon = 'icons/obj/syringe.dmi'
	icon_state = "implantcase-0"
	radial_priority = SURGERY_RADIAL_PRIORITY_OTHER_FIRST

//extract implant
/datum/surgery_step/extract_implant
	name = "Изъять Импланты"
	implements = list(TOOL_HEMOSTAT = 100, TOOL_CROWBAR = 65)
	repeatable = TRUE
	time = 64
	success_sound = 'sound/surgery/hemostat1.ogg'
	var/obj/item/implant/I = null

/datum/surgery_step/extract_implant/preop(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	var/implants = list()
	for(var/obj/item/O in target.implants)
		implants[O.name] = O
	I = show_radial_menu(user, target, implants, require_near = TRUE, tooltips = TRUE)
	if(I && user && target && user.Adjacent(target) && user.get_active_held_item() == tool)
		I = implants[I]
		if(!I)
			return -1
		display_results(user, target, "<span class='notice'>You begin to extract [I] from [target]'s [target_zone]...</span>",
			"[user] begins to extract [I] from [target]'s [target_zone].",
			"[user] begins to extract something from [target]'s [target_zone].")
	else
		I = null
		return -1

/datum/surgery_step/extract_implant/success(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	if(I)
		if(I.removable)
			display_results(user, target, "<span class='notice'>You successfully remove [I] from [target]'s [target_zone].</span>",
				"[user] successfully removes [I] from [target]'s [target_zone]!",
				"[user] successfully removes something from [target]'s [target_zone]!")
			I.removed(target)

			var/obj/item/implantcase/case
			for(var/obj/item/implantcase/ic in user.held_items)
				case = ic
				break
			if(!case)
				case = locate(/obj/item/implantcase) in get_turf(target)
			if(case && !case.imp)
				case.imp = I
				I.forceMove(case)
				case.update_icon()
				display_results(user, target, "<span class='notice'>You place [I] into [case].</span>",
					"[user] places [I] into [case]!",
					"[user] places it into [case]!")
			else
				qdel(I)
		else // BLUEMOON add
			to_chat(user, "<span class='warning'>[I]`s protective systems prevent removing from [target]'s [target_zone].</span>")


	else
		to_chat(user, "<span class='warning'>You can't find anything in [target]'s [target_zone]!</span>")
	return TRUE

/datum/surgery/implant_removal/mechanic
	name = "implant removal"
	requires_bodypart_type = BODYPART_ROBOTIC
	steps = list(
		/datum/surgery_step/mechanic_open,
		/datum/surgery_step/open_hatch,
		/datum/surgery_step/mechanic_unwrench,
		/datum/surgery_step/extract_implant,
		/datum/surgery_step/mechanic_wrench,
		/datum/surgery_step/mechanic_close)
