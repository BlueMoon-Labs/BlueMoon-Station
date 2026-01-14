/obj/item/reagent_containers/pill/patch
	name = "chemical patch"
	desc = "Пластырь-повязка с препаратами для применения тактильным способом."
	icon = 'icons/obj/chemical.dmi'
	icon_state = "bandaid"
	item_state = "patch1" //bandaid replaced by BM
	possible_transfer_amounts = list()
	volume = 40
	apply_type = PATCH
	apply_method = "apply"
	self_delay = 30		// three seconds
	dissolvable = FALSE

/obj/item/reagent_containers/pill/patch/attack(mob/living/L, mob/user)
	if(ishuman(L))
		var/obj/item/bodypart/affecting = L.get_bodypart(check_zone(user.zone_selected))
		if(!affecting)
			to_chat(user, "<span class='warning'>Конечность отсутствует!</span>")
			return
		if(!L.can_inject(user, TRUE, user.zone_selected, FALSE, TRUE)) //stopped by clothing, not by species immunity.
			return
		if(!affecting.is_organic_limb())
			to_chat(user, "<span class='notice'>Пластырь не подействует на роботизированные конечности!</span>")
		else if(!affecting.is_organic_limb(FALSE))
			to_chat(user, "<span class='notice'>Пластырь не подействует на биомеханические конечности!</span>")
			return
	..()

/obj/item/reagent_containers/pill/patch/attempt_feed(mob/living/M, mob/living/user) // Я в ахуе с этих костылей, у них пластыри это пилюли
	if(!canconsume(M, user))
		return FALSE

	if(M == user)
		M.visible_message("<span class='notice'>[user] attempts to [apply_method] [src].</span>")
		if(self_delay)
			if(!do_mob(user, M, self_delay))
				return FALSE
		to_chat(M, "<span class='notice'>You [apply_method] [src].</span>")
	else
		M.visible_message("<span class='danger'>[user] attempts to force [M] to [apply_method] [src].</span>", \
							"<span class='userdanger'>[user] attempts to force [M] to [apply_method] [src].</span>")
		if(!do_mob(user, M))
			return FALSE
		M.visible_message("<span class='danger'>[user] forces [M] to [apply_method] [src].</span>", \
							"<span class='userdanger'>[user] forces [M] to [apply_method] [src].</span>")

	log_combat(user, M, "patched", reagents.log_list())
	if(reagents.total_volume)
		if(ishuman(M))
			var/mob/living/carbon/human/H = M
			var/obj/item/bodypart/affecting = H.get_bodypart(check_zone(user.zone_selected))
			reagents.reaction(M, apply_type, affected_bodypart = affecting)
			reagents.trans_to(M, reagents.total_volume, log = TRUE)
		else
			reagents.reaction(M, apply_type)
			reagents.trans_to(M, reagents.total_volume, log = TRUE)
	qdel(src)
	return TRUE

/obj/item/reagent_containers/pill/patch/canconsume(mob/eater, mob/user)
	if(!iscarbon(eater))
		return FALSE
	return TRUE // Masks were stopping people from "eating" patches. Thanks, inheritance.

/obj/item/reagent_containers/pill/patch/styptic
	name = "brute patch"
	desc = "Порошковый пластырь. Помогает при ушибах."
	list_reagents = list(/datum/reagent/medicine/styptic_powder = 20)
	icon_state = "patch2" //bandaid_brute replaced by BM

/obj/item/reagent_containers/pill/patch/silver_sulf
	name = "burn patch"
	desc = "Сульфатдиазиновый пластырь. Помогает при ожогах."
	list_reagents = list(/datum/reagent/medicine/silver_sulfadiazine = 20)
	icon_state = "patch3" //bandaid_burn replaced by BM

/obj/item/reagent_containers/pill/patch/get_belt_overlay()
	return mutable_appearance('icons/obj/clothing/belt_overlays.dmi', "pouch")
