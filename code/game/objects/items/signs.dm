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

/obj/item/picket_sign/proc/retext(obj/item/W, mob/user)
	if(istype(W, /obj/item/pen))
		if(!user.can_write(W))
			to_chat(user, "<span class='notice'>You scribble illegibly on [src]!</span>")
			return
	var/txt = stripped_input(user, "What would you like to write on the sign?", "Sign Label", null , 30)
	if(txt && user.canUseTopic(src, BE_CLOSE))
		label = txt
		name = "[label] sign"
		desc =	"It reads: [label]"

/obj/item/picket_sign/attackby(obj/item/W, mob/user, params)
	if(istype(W, /obj/item/pen) || istype(W, /obj/item/toy/crayon))
		retext(user)
	else
		return ..()

/obj/item/picket_sign/attack_self(mob/user)
	if(!isliving(user))
		return ..()

	if(!COOLDOWN_FINISHED(src, picket_sign_cooldown))
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
