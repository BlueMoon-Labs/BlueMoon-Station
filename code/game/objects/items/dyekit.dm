/obj/item/dyespray
	name = "hair dye spray"
	desc = "A spray to dye your hair any gradients you'd like."
	icon = 'icons/obj/dyespray.dmi'
	icon_state = "dyespray"
	w_class = WEIGHT_CLASS_SMALL

/obj/item/dyespray/attack_self(mob/user)
	dye(user)

/obj/item/dyespray/pre_attack(atom/target, mob/living/user, params, attackchain_flags, damage_multiplier)
	. = ..()
	if((. & STOP_ATTACK_PROC_CHAIN) || !ishuman(target))
		return
	dye(target, user)
	return . | STOP_ATTACK_PROC_CHAIN

/**
 * Applies a gradient and a gradient color to a mob.
 *
 * Arguments:
 * * target - The mob who we will apply the gradient and gradient color to.
 */

/obj/item/dyespray/proc/dye(mob/target, mob/user = usr)
	if(!ishuman(target) || !user?.client)
		return
	var/mob/living/carbon/human/human_target = target
	if(!can_dye_target(user, human_target))
		return
	open_live_hair_style_picker(user, human_target, src, list("grad"), CALLBACK(src, PROC_REF(apply_hair_gradient), user, human_target))

/obj/item/dyespray/proc/apply_hair_gradient(mob/user, mob/living/carbon/human/human_target, new_grad_style, tab, new_grad_color)
	if(!can_dye_target(user, human_target))
		return FALSE

	to_chat(human_target, span_notice("You start applying the hair dye..."))
	if(!do_after(user, 3 SECONDS, target = human_target) || !can_dye_target(user, human_target))
		return FALSE
	human_target.grad_style = new_grad_style
	human_target.grad_color = new_grad_color
	playsound(src, 'sound/effects/spray.ogg', 5, TRUE, 5)
	human_target.update_hair()
	return TRUE

/obj/item/dyespray/proc/can_dye_target(mob/user, mob/living/carbon/human/human_target)
	if(QDELETED(src) || QDELETED(user) || QDELETED(human_target))
		return FALSE
	return user.canUseTopic(src, BE_CLOSE, FALSE, NO_TK) && user.canUseTopic(human_target, BE_CLOSE, FALSE, NO_TK)
