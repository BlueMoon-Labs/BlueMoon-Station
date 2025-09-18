/datum/interaction/carry
	required_from_user = INTERACTION_REQUIRE_HANDS
	interaction_sound = 'sound/weapons/thudswoosh.ogg'

/datum/interaction/carry/evaluate_user(mob/living/user, silent, apply_cooldown)
	. = ..()
	if(!.)
		return
	if(!ishuman(user)) // /datum/component/riding/human разработан для хуманов, поэтому не буду проверять растяжимость хрупко работающих механик
		to_chat(user, span_warning("Тебе не получиться поднять это существо таким способом.")) // "я ограничен технологиями своего времени."
		return FALSE
	if(user.incapacitated())
		to_chat(user, span_warning("Ты сейчас не можешь это сделать."))
		return FALSE
	if(user.get_active_held_item())
		to_chat(user, span_warning("Нужна свобдная рука."))
		return FALSE

/datum/interaction/carry/evaluate_target(mob/living/user, mob/living/target, silent)
	. = ..()
	if(!.)
		return
	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		if(!is_type_in_typecache(target, H.can_ride_typecache))
			to_chat(H, span_warning("Тебе не получиться поднять это существо таким способом."))
			return FALSE
	if((target.mob_weight > MOB_WEIGHT_NORMAL) && !(user.mob_weight in list(MOB_WEIGHT_HEAVY, MOB_WEIGHT_HEAVY_SUPER)))
		to_chat(user, span_warning("[target] слишком много весит."))
		return FALSE

/datum/interaction/carry/special_check(mob/living/user, mob/living/target)
	. = ..()
	if(!.)
		return
	user.visible_message("[user] пытается поднять [target] к себе на руки...")
	if(!do_after(user, 3 SECONDS, target))
		return FALSE

/datum/interaction/carry/face_to_face
	description = "Нести на руках лицом к лицу."
	simple_message = "USER поднимает TARGET к себе на руки."

/datum/interaction/carry/face_to_face/do_action(mob/living/user, mob/living/target, apply_cooldown)
	. = ..()
	if(!.)
		return
	user.buckle_mob(target, TRUE, TRUE, 0, 1, 0, FALSE, "face_to_face")

/datum/interaction/carry/princess
	description = "Нести на руках как принцессу."
	simple_message = "USER поднимает TARGET к себе на руки в позе принцессы."

/datum/interaction/carry/princess/evaluate_user(mob/living/user, silent, apply_cooldown)
	. = ..()
	if(!.)
		return
	if(!(user.get_bodypart(BODY_ZONE_L_ARM) && user.get_bodypart(BODY_ZONE_R_ARM)) || user.get_active_held_item() || user.get_inactive_held_item())
		to_chat(user, span_warning("Одной свободной руки недостаточно для такого действия."))
		return FALSE

/datum/interaction/carry/princess/do_action(mob/living/user, mob/living/target, apply_cooldown)
	. = ..()
	if(!.)
		return
	user.buckle_mob(target, TRUE, TRUE, 90, 2, 0, FALSE, "princess")
