#define TRAIT_SOURCE_SUICIDE_BELT "suicide_belt_charge"
/*
 * /proc/explosion() tuning for the martyr belt — see code/datums/explosion.dm.
 * Radius values are tiles from epicenter unless noted; raise/lower together for weaker/stronger blasts.
 */
/// Epicenter tier: devastation_range (max hull/item damage tier).
#define SUICIDE_BELT_EX_DEVASTATION_RANGE 2
/// Next ring: heavy_impact_range (strong ex_act tier).
#define SUICIDE_BELT_EX_HEAVY_RANGE 8
/// Outer pressure wave: light_impact_range (weaker structural damage tier).
#define SUICIDE_BELT_EX_LIGHT_RANGE 16
/// Flash bang propagation: flash_range (mobs/screens).
#define SUICIDE_BELT_EX_FLASH_RANGE 14
/// Fire halo: flame_range named argument (tiles igniting / plasma fire spread input to explosion datum).
#define SUICIDE_BELT_EX_FLAME_RANGE 14

/datum/action/item_action/suicide_belt_trigger
	name = "Activate suicide belt"

/obj/item/suicide_belt
	name = "\improper suicide martyr belt"
	desc = "A wide belt wired with synced charges. Activation starts a countdown and cannot be undone."
	icon = 'icons/obj/grenade.dmi'
	icon_state = "syndicate"
	w_class = WEIGHT_CLASS_NORMAL
	slot_flags = ITEM_SLOT_BELT
	var/countdown_time = 5 SECONDS
	var/arming = FALSE
	actions_types = list(/datum/action/item_action/suicide_belt_trigger)

/obj/item/suicide_belt/ui_action_click(mob/user)
	attack_self(user)

/obj/item/suicide_belt/examine(mob/user)
	. = ..()
	. += span_warning("Use the action button on your HUD while it is worn, or activate while holding it.")

/obj/item/suicide_belt/proc/worn_or_held_correctly(mob/living/user)
	if(!ishuman(user) || user.stat != CONSCIOUS)
		return FALSE
	var/mob/living/carbon/human/H = user
	return (H.belt == src || H.is_holding(src))

/obj/item/suicide_belt/attack_self(mob/user)
	if(arming || !user || QDELING(src))
		return
	if(!worn_or_held_correctly(user))
		to_chat(user, span_warning("You need to wear this on your belt slot or hold it in your hands."))
		return
	if(tgui_alert(user, "Arm the explosives? [countdown_time/10] seconds until detonation. There is NO cancel!", "Martyr Belt", list("DETONATE", "Abort")) != "DETONATE")
		return
	arming = TRUE
	INVOKE_ASYNC(src, PROC_REF(countdown_explode), user)

/obj/item/suicide_belt/proc/countdown_explode(mob/user)
	set waitfor = FALSE
	if(QDELETED(src) || QDELETED(user) || QDELING(src))
		arming = FALSE
		return
	var/mob/living/carbon/human/H = user
	if(!ishuman(H) || H.stat != CONSCIOUS || !worn_or_held_correctly(H))
		arming = FALSE
		return

	ADD_TRAIT(H, TRAIT_NODROP, TRAIT_SOURCE_SUICIDE_BELT)
	ADD_TRAIT(H, TRAIT_NO_STRIP, TRAIT_SOURCE_SUICIDE_BELT)

	var/turf/belt_turf = get_turf(H)
	H.visible_message(span_danger("[H] fiddles frantically at their belt!"), span_userdanger("You've armed the martyr belt!"))
	message_admins("[ADMIN_LOOKUPFLW(H)] armed a martyr suicide belt at [ADMIN_VERBOSEJMP(belt_turf)].")

	playsound(belt_turf, 'modular_bluemoon/sound/effects/terrorist_countdown.ogg', 110, FALSE, MEDIUM_RANGE_SOUND_EXTRARANGE)
	sleep(countdown_time)

	REMOVE_TRAIT(H, TRAIT_NODROP, TRAIT_SOURCE_SUICIDE_BELT)
	REMOVE_TRAIT(H, TRAIT_NO_STRIP, TRAIT_SOURCE_SUICIDE_BELT)

	if(QDELETED(H) || QDELETED(src) || QDELING(src))
		arming = FALSE
		return

	if(H.stat == DEAD)
		arming = FALSE
		return

	if(H.belt != src && !H.is_holding(src))
		H.visible_message(span_notice("[H]'s suicide belt chirps abortively — they're no longer carrying it safely."))
		arming = FALSE
		return

	var/turf/T = get_turf(H)
	explosion(T, SUICIDE_BELT_EX_DEVASTATION_RANGE, SUICIDE_BELT_EX_HEAVY_RANGE, SUICIDE_BELT_EX_LIGHT_RANGE, SUICIDE_BELT_EX_FLASH_RANGE, flame_range = SUICIDE_BELT_EX_FLAME_RANGE)
	H.gib(TRUE, TRUE)
	qdel(src)
