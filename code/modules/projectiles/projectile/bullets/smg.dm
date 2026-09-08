/* /obj/item/projectile/bullet/c45
	name = ".45 bullet"
	damage = 30
	armour_penetration = BULLET_BR3
	wound_bonus = 15
	bare_wound_bonus = 20
	wound_falloff_tile = -10 */ // уже есть в другом файле

/obj/item/projectile/bullet/c45_cleaning
	name = ".45 bullet"
	damage = 45
	armour_penetration = BULLET_BR7
	sharpness = SHARP_EDGED

/obj/item/projectile/bullet/c45_cleaning/on_hit(atom/target, blocked = FALSE)
	. = ..()
	var/turf/T = get_turf(target)
	SEND_SIGNAL(T, COMSIG_COMPONENT_CLEAN_ACT, CLEAN_WEAK)
	for(var/A in T)
		if(is_cleanable(A))
			qdel(A)
		else if(isitem(A))
			var/obj/item/cleaned_item = A
			SEND_SIGNAL(cleaned_item, COMSIG_COMPONENT_CLEAN_ACT, CLEAN_WEAK)
			cleaned_item.clean_blood()
			if(ismob(cleaned_item.loc))
				var/mob/M = cleaned_item.loc
				M.regenerate_icons()
		else if(ishuman(A))
			var/mob/living/carbon/human/cleaned_human = A
			if(cleaned_human.lying)
				if(cleaned_human.head)
					SEND_SIGNAL(cleaned_human.head, COMSIG_COMPONENT_CLEAN_ACT, CLEAN_WEAK)
					cleaned_human.head.clean_blood()
					cleaned_human.update_inv_head()
				if(cleaned_human.wear_suit)
					SEND_SIGNAL(cleaned_human.wear_suit, COMSIG_COMPONENT_CLEAN_ACT, CLEAN_WEAK)
					cleaned_human.wear_suit.clean_blood()
					cleaned_human.update_inv_wear_suit()
				else if(cleaned_human.w_uniform)
					SEND_SIGNAL(cleaned_human.w_uniform, COMSIG_COMPONENT_CLEAN_ACT, CLEAN_WEAK)
					cleaned_human.w_uniform.clean_blood()
					cleaned_human.update_inv_w_uniform()
				//skyrat edit
				else if(cleaned_human.w_underwear)
					SEND_SIGNAL(cleaned_human.w_underwear, COMSIG_COMPONENT_CLEAN_ACT, CLEAN_WEAK)
					cleaned_human.w_underwear.clean_blood()
					cleaned_human.update_inv_w_underwear()
				else if(cleaned_human.w_socks)
					SEND_SIGNAL(cleaned_human.w_socks, COMSIG_COMPONENT_CLEAN_ACT, CLEAN_WEAK)
					cleaned_human.w_socks.clean_blood()
					cleaned_human.update_inv_w_socks()
				else if(cleaned_human.w_shirt)
					SEND_SIGNAL(cleaned_human.w_shirt, COMSIG_COMPONENT_CLEAN_ACT, CLEAN_WEAK)
					cleaned_human.w_shirt.clean_blood()
					cleaned_human.update_inv_w_shirt()
				else if(cleaned_human.wrists)
					SEND_SIGNAL(cleaned_human.wrists, COMSIG_COMPONENT_CLEAN_ACT, CLEAN_WEAK)
					cleaned_human.wrists.clean_blood()
					cleaned_human.update_inv_wrists()
				//
				if(cleaned_human.shoes)
					SEND_SIGNAL(cleaned_human.shoes, COMSIG_COMPONENT_CLEAN_ACT, CLEAN_WEAK)
					cleaned_human.shoes.clean_blood()
					cleaned_human.update_inv_shoes()
				SEND_SIGNAL(cleaned_human, COMSIG_COMPONENT_CLEAN_ACT, CLEAN_WEAK)
				cleaned_human.clean_blood()
				cleaned_human.wash_cream()
				cleaned_human.regenerate_icons()

/obj/item/projectile/bullet/c46x30mm
	name = "4.6x30mm bullet"
	damage = 16.5
	armour_penetration = BULLET_BR4
	wound_bonus = 15
	bare_wound_bonus = 10
	embed_falloff_tile = -1

/obj/item/projectile/bullet/c46x30mm_ap
	name = "4.6x30mm armor-piercing bullet"
	damage = 15
	armour_penetration = BULLET_BR8
	wound_bonus = -2
	embedding = null

/obj/item/projectile/bullet/incendiary/c46x30mm
	name = "4.6x30mm incendiary bullet"
	damage = 15.5
	armour_penetration = BULLET_BR5
	fire_stacks = 1
