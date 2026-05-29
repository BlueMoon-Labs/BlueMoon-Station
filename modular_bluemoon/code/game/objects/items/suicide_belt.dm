#define SUICIDE_BELT_TRAIT "suicide_belt"
/*
 * /proc/explosion() tuning for the martyr belt — see code/datums/explosion.dm.
 * Radius values are tiles from epicenter unless noted; raise/lower together for weaker/stronger blasts.
 */
/// Epicenter tier: devastation_range (max hull/item damage tier).
#define SUICIDE_BELT_EX_DEVASTATION_RANGE 3
/// Next ring: heavy_impact_range (strong ex_act tier).
#define SUICIDE_BELT_EX_HEAVY_RANGE 8
/// Outer pressure wave: light_impact_range (weaker structural damage tier).
#define SUICIDE_BELT_EX_LIGHT_RANGE 12
/// Flash bang propagation: flash_range (mobs/screens).
#define SUICIDE_BELT_EX_FLASH_RANGE 20
/// Fire halo: flame_range named argument (tiles igniting / plasma fire spread input to explosion datum).
#define SUICIDE_BELT_EX_FLAME_RANGE 16

/datum/action/item_action/suicide_belt_trigger
	name = "Активировать пояс смертника"

/obj/item/suicide_belt
	name = "\improper Suicide Martyr Belt"
	desc = "Широкий пояс, оплетённый синхронизированными зарядами. Активация запускает обратный отсчёт, который нельзя отменить."
	icon = 'icons/obj/clothing/belts.dmi'
	mob_overlay_icon = 'icons/mob/clothing/belt.dmi'
	lefthand_file = 'icons/mob/inhands/equipment/belt_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/belt_righthand.dmi'
	icon_state = "boom_vest"
	item_state = "boom_vest"
	w_class = WEIGHT_CLASS_NORMAL
	slot_flags = ITEM_SLOT_BELT | ITEM_SLOT_BACK
	var/countdown_time = 5 SECONDS
	var/arming = FALSE
	actions_types = list(/datum/action/item_action/suicide_belt_trigger)

/obj/item/suicide_belt/equipped(mob/user, slot)
	. = ..()
	if(slot == ITEM_SLOT_BELT || slot == ITEM_SLOT_BACK)
		ADD_TRAIT(src, TRAIT_NODROP, SUICIDE_BELT_TRAIT)

/obj/item/suicide_belt/ui_action_click(mob/user)
	attack_self(user)

/obj/item/suicide_belt/examine(mob/user)
	. = ..()
	if(HAS_TRAIT_FROM(src, TRAIT_NODROP, SUICIDE_BELT_TRAIT))
		. += span_warning("Пояс сидит намертво - снять невозможно.")

/obj/item/suicide_belt/proc/worn_correctly(mob/living/user)
	if(!ishuman(user) || user.stat != CONSCIOUS)
		return FALSE
	var/mob/living/carbon/human/H = user
	return (H.belt == src) || (H.back == src.loc)

/obj/item/suicide_belt/attack_self(mob/user)
	if(arming || !user || QDELING(src))
		return
	if(!worn_correctly(user))
		to_chat(user, span_warning("Наденьте Пояс Смертника в слот 'пояс' или 'рюкзак'."))
		return
	// if(tgui_alert(user, "Взвести заряды? До взрыва [countdown_time/10] секунд. Отмены НЕТ!", "Пояс смертника", list("ВЗОРВАТЬ", "Отмена")) != "ВЗОРВАТЬ")
	// 	return
	arming = TRUE
	INVOKE_ASYNC(src, PROC_REF(countdown_explode), user)

/obj/item/suicide_belt/proc/countdown_explode(mob/user)
	set waitfor = FALSE
	if(QDELETED(src) || QDELETED(user) || QDELING(src))
		arming = FALSE
		return
	var/mob/living/carbon/human/H = user
	if(!ishuman(H) || H.stat != CONSCIOUS || !worn_correctly(H))
		arming = FALSE
		return

	var/turf/belt_turf = get_turf(H)
	H.visible_message(span_danger("[H] лихорадочно ковыряется у пояса!"), span_userdanger("Вы активировали пояс смертника!"))
	H.balloon_alert_to_viewers("ОН СЕЙЧАС ВЗОРВЁТСЯ!")
	message_admins("[ADMIN_LOOKUPFLW(H)] armed a martyr suicide belt at [ADMIN_VERBOSEJMP(belt_turf)].")

	playsound(belt_turf, 'modular_bluemoon/sound/effects/terrorist_countdown.ogg', 110, FALSE, MEDIUM_RANGE_SOUND_EXTRARANGE)
	sleep(countdown_time)

	if(QDELETED(H) || QDELETED(src) || QDELING(src))
		arming = FALSE
		return

	if(H.stat == DEAD)
		arming = FALSE
		return

	if(!worn_correctly(H))
		H.visible_message(span_notice("Пояс смертника у [H] тихо пискнул и оборвал отсчёт - пояс больше не на месте."))
		arming = FALSE
		return

	var/turf/T = get_turf(H)
	explosion(T, SUICIDE_BELT_EX_DEVASTATION_RANGE, SUICIDE_BELT_EX_HEAVY_RANGE, SUICIDE_BELT_EX_LIGHT_RANGE, SUICIDE_BELT_EX_FLASH_RANGE, flame_range = SUICIDE_BELT_EX_FLAME_RANGE)
	H.gib(TRUE, TRUE)
	qdel(src)
