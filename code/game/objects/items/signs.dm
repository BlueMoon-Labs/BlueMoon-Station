/// Сколько символов влезает на плакат.
#define PICKET_SIGN_LABEL_MAX_LEN 30

/obj/item/picket_sign
	icon_state = "picket"
	name = "blank picket sign"
	desc = "It's blank."
	force = 5
	w_class = WEIGHT_CLASS_BULKY
	attack_verb = list("bashed","smacked")
	resistance_flags = FLAMMABLE

	var/label = ""
	COOLDOWN_DECLARE(picket_sign_cooldown)

/obj/item/picket_sign/cyborg
	name = "metallic nano-sign"
	desc = "A high tech picket sign used by silicons that can reprogram its surface at will. Probably hurts to get hit by, too."
	force = 13
	resistance_flags = NONE
	actions_types = list(/datum/action/item_action/nano_picket_sign)

/obj/item/picket_sign/examine(mob/user)
	. = ..()
	. += span_notice("Надпись меняется ручкой или мелком. Пустая надпись стирает плакат.")

/// Пишет на плакате [new_label]. Пустая строка возвращает плакат к чистому виду.
/obj/item/picket_sign/proc/set_label(new_label)
	label = new_label || ""
	if(label)
		name = "[label] sign"
		desc = "It reads: [label]"
	else
		name = initial(name)
		desc = initial(desc)

/**
 * Спрашивает у [user] новую надпись и наносит её.
 *
 * [writing_implement] задан, когда пишут предметом - тогда работает проверка грамотности
 * и самого инструмента. Нано-плакат силикон перепрограммирует без инструмента вообще.
 */
/obj/item/picket_sign/proc/retext(mob/user, obj/item/writing_implement)
	set waitfor = FALSE

	if(!user?.client) //диалог показывать некому
		return
	if(writing_implement && !user.can_write(writing_implement))
		return

	var/new_label = tgui_input_text(user, "Что написать на плакате?", "Надпись на плакате", label, PICKET_SIGN_LABEL_MAX_LEN, encode = TRUE)
	if(isnull(new_label) || !user.canUseTopic(src, BE_CLOSE))
		return

	set_label(new_label)

/obj/item/picket_sign/attackby(obj/item/attacking_item, mob/user, params)
	if(!istype(attacking_item, /obj/item/pen) && !istype(attacking_item, /obj/item/toy/crayon))
		return ..()
	retext(user, attacking_item)
	// Иначе следом отработает afterattack инструмента: ручка откроет своё окно
	// переименования по UNIQUE_RENAME, мелок нарисует поверх плаката граффити.
	return STOP_ATTACK_PROC_CHAIN

/obj/item/picket_sign/ui_action_click(mob/user, actiontype)
	if(istype(actiontype, /datum/action/item_action/nano_picket_sign))
		retext(user)
		return
	return ..()

/obj/item/picket_sign/attack_self(mob/user)
	if(!isliving(user))
		return ..()

	if(!COOLDOWN_FINISHED(src, picket_sign_cooldown))
		balloon_alert(user, "плакат ещё опущен")
		return

	COOLDOWN_START(src, picket_sign_cooldown, 5 SECONDS)

	if(label)
		user.emote("me", message = "размахивает плакатом с надписью \"[label]\".")
		user.say(label)
		user.balloon_alert_to_viewers("[label]")
	else
		user.emote("me", message = "размахивает пустым плакатом.")
		user.balloon_alert_to_viewers("пустой плакат")

	var/direction = prob(50) ? -1 : 1
	if(NSCOMPONENT(user.dir))
		animate(user, pixel_w = (1 * direction), time = 0.1 SECONDS, easing = SINE_EASING, flags = ANIMATION_RELATIVE|ANIMATION_PARALLEL)
		animate(pixel_w = (-2 * direction), time = 0.1 SECONDS, easing = SINE_EASING, flags = ANIMATION_RELATIVE)
		animate(pixel_w = (2 * direction), time = 0.1 SECONDS, easing = SINE_EASING, flags = ANIMATION_RELATIVE)
		animate(pixel_w = (-2 * direction), time = 0.1 SECONDS, easing = SINE_EASING, flags = ANIMATION_RELATIVE)
		animate(pixel_w = (1 * direction), time = 0.1 SECONDS, easing = SINE_EASING, flags = ANIMATION_RELATIVE)
	else
		animate(user, pixel_z = (1 * direction), time = 0.1 SECONDS, easing = SINE_EASING, flags = ANIMATION_RELATIVE|ANIMATION_PARALLEL)
		animate(pixel_z = (-2 * direction), time = 0.1 SECONDS, easing = SINE_EASING, flags = ANIMATION_RELATIVE)
		animate(pixel_z = (2 * direction), time = 0.1 SECONDS, easing = SINE_EASING, flags = ANIMATION_RELATIVE)
		animate(pixel_z = (-2 * direction), time = 0.1 SECONDS, easing = SINE_EASING, flags = ANIMATION_RELATIVE)
		animate(pixel_z = (1 * direction), time = 0.1 SECONDS, easing = SINE_EASING, flags = ANIMATION_RELATIVE)

	user.changeNext_move(CLICK_CD_MELEE)

#undef PICKET_SIGN_LABEL_MAX_LEN
