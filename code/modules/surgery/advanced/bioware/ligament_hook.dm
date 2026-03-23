/datum/surgery/advanced/bioware/ligament_hook
	name = "Ligament Hook"
	desc = "Хирургическая процедура, которая изменяет форму связок между туловищем и конечностями, позволяя прикреплять конечности вручную, если они оторваны. \
	Однако это ослабляет связки и облегчает их травматическое отсоединение."
	steps = list(/datum/surgery_step/incise,
				/datum/surgery_step/retract_skin,
				/datum/surgery_step/clamp_bleeders,
				/datum/surgery_step/incise,
				/datum/surgery_step/incise,
				/datum/surgery_step/reshape_ligaments,
				/datum/surgery_step/close)
	possible_locs = list(BODY_ZONE_CHEST)
	bioware_target = BIOWARE_LIGAMENTS
	icon_state = "surgery_arms"

/datum/surgery_step/reshape_ligaments
	name = "Изменить форму связок"
	accept_hand = TRUE
	time = 125

/datum/surgery_step/reshape_ligaments/preop(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	display_results(user, target, "<span class='notice'>You start reshaping [target]'s ligaments into a hook-like shape.</span>",
	"[user] starts reshaping [target]'s ligaments into a hook-like shape.",
	"[user] starts manipulating [target]'s ligaments.")

/datum/surgery_step/reshape_ligaments/success(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	display_results(user, target, "<span class='notice'>You finish reshaping [target]'s ligaments into a connective hook!</span>",
	"[user] finishes reshaping [target]'s ligaments into a connective hook!",
	"[user] finishes manipulating [target]'s ligaments!")
	new /datum/bioware/hooked_ligaments(target)
	return TRUE

/datum/bioware/hooked_ligaments
	name = "Hooked Ligaments"
	desc = "The ligaments and nerve endings that connect the torso to the limbs are formed into a hook-like shape, so limbs can be attached without requiring surgery, but are easier to sever."
	mod_type = BIOWARE_LIGAMENTS

/datum/bioware/hooked_ligaments/on_gain()
	..()
	ADD_TRAIT(owner, TRAIT_LIMBATTACHMENT, "ligament_hook")
	ADD_TRAIT(owner, TRAIT_EASYDISMEMBER, "ligament_hook")

/datum/bioware/hooked_ligaments/on_lose()
	..()
	REMOVE_TRAIT(owner, TRAIT_LIMBATTACHMENT, "ligament_hook")
	REMOVE_TRAIT(owner, TRAIT_EASYDISMEMBER, "ligament_hook")
