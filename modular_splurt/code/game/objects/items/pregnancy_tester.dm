/obj/item/pregnancytest
	name = "pregnancy test"
	desc = "A one time use small device, used to determine whether someone is pregnant or not."
	icon = 'modular_splurt/icons/obj/pregnancytest.dmi'
	throwforce= 0
	icon_state = "ptest"
	custom_price = PRICE_REALLY_CHEAP
	var/results
	w_class = WEIGHT_CLASS_TINY

/obj/item/pregnancytest/attack_self(mob/user)
	. = ..()
	if(QDELETED(src))
		return
	if(!isliving(user))
		return
	if(user.stat > CONSCIOUS)//unconscious or dead
		return

	test(user, user)

/obj/item/pregnancytest/examine(mob/user)
	. = ..()
	. += span_notice("[results ? "The display reads [results]" : "The display is empty, this tester is not yet used"].")

/obj/item/pregnancytest/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	. = ..()
	if(user.zone_selected != BODY_ZONE_PRECISE_GROIN)
		return
	if(!isliving(target))
		return
	var/mob/living/livingtar = target
	if(iscarbon(target))
		var/mob/living/carbon/cartar = target
		if(!cartar.is_groin_exposed())
			return

	test(livingtar, user)

/obj/item/pregnancytest/proc/test(mob/living/target, mob/user)
	if(results)
		to_chat(user, span_warning("This tester is already used!"))
		return

	var/obj/item/organ/container = target.getorganslot(ORGAN_SLOT_WOMB)

	results = "negative"

	if(container)
		for(var/obj/item/thing as anything in container.contents)
			if(thing?.GetComponent(/datum/component/pregnancy))
				results = "positive"
				break

	to_chat(user, span_notice("You use the tester."))

	icon_state = results
	name = "[results] pregnancy test"

	update_appearance()
