/obj/item/hk47_repair_kit
	name = "HK droid repair kit"
	desc = "Набор полевого ремонта для шасси серии HK: заплаты брони, проводка и баллончик хладагента. Чинит дроида HK, пока тот стоит на месте, и расходуется целиком."
	icon = 'modular_bluemoon/icons/obj/hk_droids/hk47_gear.dmi'
	icon_state = "hk47_repair_kit"
	item_state = "hk47_repair_kit"
	lefthand_file = 'modular_bluemoon/icons/obj/hk_droids/hk47_gear_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/obj/hk_droids/hk47_gear_righthand.dmi'
	w_class = WEIGHT_CLASS_SMALL
	var/repair_time = HK47_REPAIR_KIT_TIME

/obj/item/hk47_repair_kit/examine(mob/user)
	. = ..()
	. += span_notice("Восстанавливает [HK47_REPAIR_KIT_HEAL] прочности поровну механике и ожогам за [DisplayTimeText(repair_time)] без движения. Использовать в руке - на себе, ударом - на другом дроиде HK. Отключённое шасси не перезапускает.")

/obj/item/hk47_repair_kit/attack_self(mob/living/user)
	repair(user, user)

/obj/item/hk47_repair_kit/attack(mob/living/target, mob/living/user)
	if(!is_species(target, /datum/species/ipc/hk))
		return ..()
	repair(target, user)

/obj/item/hk47_repair_kit/proc/repair_refusal(mob/living/carbon/human/patient)
	if(!is_species(patient, /datum/species/ipc/hk))
		return "набор подходит только к шасси HK."
	if(patient.stat == DEAD)
		return "шасси отключено, набор его не перезапустит."
	if(!patient.getBruteLoss() && !patient.getFireLoss())
		return "ремонт не нужен."
	return null

/obj/item/hk47_repair_kit/proc/repair(mob/living/carbon/human/patient, mob/living/user)
	var/reason = repair_refusal(patient)
	if(reason)
		patient.balloon_alert(user, reason)
		return FALSE
	user.visible_message(span_notice("[user] латает корпус [patient] из ремкомплекта."), span_notice("Ремонт [patient == user ? "шасси" : "[patient]"]..."))
	playsound(patient, 'modular_bluemoon/sound/hk_droids/hk47_repair.ogg', 45, FALSE)
	if(!do_after(user, repair_time, patient))
		patient.balloon_alert(user, "ремонт прерван")
		return FALSE
	reason = repair_refusal(patient)
	if(reason)
		to_chat(user, span_warning("Утверждение: [reason]"))
		return FALSE
	var/burn = patient.getFireLoss()
	var/brute = patient.getBruteLoss()
	var/burn_heal = min(burn, HK47_REPAIR_KIT_HEAL / 2)
	var/brute_heal = min(brute, HK47_REPAIR_KIT_HEAL - burn_heal)
	burn_heal = min(burn, HK47_REPAIR_KIT_HEAL - brute_heal)
	patient.heal_overall_damage(brute_heal, burn_heal, 0, FALSE, FALSE)
	do_sparks(2, FALSE, patient)
	patient.visible_message(span_notice("Корпус [patient] залатан."))
	patient.balloon_alert(user, "+[round(brute_heal + burn_heal)] прочности")
	if(patient == user)
		hk47_quip(user, "repair_done")
		hk47_upgrade_voice(user, "hk47_crude")
	qdel(src)
	return TRUE
