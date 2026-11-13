/obj/structure/closet/secure_closet
	name = "secure locker"
	desc = "Шкаф-хранилище с ID замком."
	locked = TRUE
	icon_state = "secure"
	max_integrity = 250
	armor_type = /datum/armor/crate_secure_and_secure_closet
	secure = TRUE
	var/melee_min_damage = 20

/obj/structure/closet/secure_closet/run_obj_armor(damage_amount, damage_type, damage_flag = 0, attack_dir)
	if(damage_flag == MELEE && damage_amount < melee_min_damage)
		return FALSE
	. = ..()

// Exists to work around the minimum 700 cr price for goodies / small items / materials
/obj/structure/closet/secure_closet/cargo
	name = "cargo locker"
	icon_state = "cargo"
	desc = "A sturdier card-locked storage unit used for bulky shipments."
	max_integrity = 500 // Same as crates.
	melee_min_damage = 25 // Idem.

/obj/structure/closet/secure_closet/cargo/owned
	name = "private cargo locker"
	desc = "A locker designed to only open for who purchased its contents."
	///Account of the person buying the crate if private purchasing.
	var/datum/bank_account/buyer_account
	///Department of the person buying the crate if buying via the NIRN app.
	var/datum/bank_account/department/department_account
	///Is the secure crate opened or closed?
	var/privacy_lock = TRUE
	///Is the crate being bought by a person, or a budget card?
	var/department_purchase = FALSE

/obj/structure/closet/secure_closet/cargo/owned/examine(mob/user)
	. = ..()
	. += span_notice("Заперт именным замком: откроет только ID-карта того, на чей счёт заказ, - покупателя или получателя подарка.")

/obj/structure/closet/secure_closet/cargo/owned/Initialize(mapload, datum/bank_account/_buyer_account)
	. = ..()
	buyer_account = _buyer_account
	if(istype(buyer_account, /datum/bank_account/department))
		department_purchase = TRUE
		department_account = buyer_account

/obj/structure/closet/secure_closet/cargo/owned/togglelock(mob/living/user, silent)
	if(privacy_lock)
		if(!broken)
			var/obj/item/card/id/id_card = user.get_idcard(TRUE)
			if(id_card)
				if(id_card.registered_account)
					if(id_card.registered_account == buyer_account || (department_purchase && (id_card.registered_account?.account_job?.paycheck_department) == (department_account.department_id)))
						if(iscarbon(user))
							add_fingerprint(user)
						locked = !locked
						user.visible_message(span_notice("[user] отпирает именной замок [src]."), span_notice("Вы отпираете именной замок [src]."))
						privacy_lock = FALSE
						update_icon()
					else if(!silent)
						to_chat(user, span_warning("[src] заперт на счёт [buyer_account?.account_holder || "другого человека"]: ваша карта его не откроет."))
				else if(!silent)
					to_chat(user, span_warning("К вашей ID-карте не привязан банковский счёт."))
			else if(!silent)
				to_chat(user, span_warning("Нужна ID-карта: возьмите её в руку или наденьте."))
		else if(!silent)
			to_chat(user, span_warning("Замок [src] сломан."))
	else ..()
