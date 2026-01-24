/obj/item/reagent_containers/medspray
	name = "medical spray"
	desc = "Медицинский спрей для точечного применения, с неснимаемым колпачком."
	icon = 'icons/obj/chemical.dmi'
	icon_state = "medspray"
	item_state = "spraycan"
	lefthand_file = 'icons/mob/inhands/equipment/hydroponics_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/hydroponics_righthand.dmi'
	item_flags = NOBLUDGEON
	obj_flags = UNIQUE_RENAME
	reagent_flags = OPENCONTAINER
	slot_flags = ITEM_SLOT_BELT
	throwforce = 0
	w_class = WEIGHT_CLASS_SMALL
	throw_speed = 3
	throw_range = 7
	amount_per_transfer_from_this = 10
	volume = 60
	var/can_fill_from_container = TRUE
	var/apply_type = PATCH
	var/apply_method = "спрей"
	var/self_delay = 1.5 SECONDS
	var/other_delay = 1 SECONDS
	var/squirt_mode = FALSE
	var/squirt_amount = 5

/obj/item/reagent_containers/medspray/attack_self(mob/user)
	squirt_mode = !squirt_mode
	if(squirt_mode)
		amount_per_transfer_from_this = squirt_amount
	else
		amount_per_transfer_from_this = initial(amount_per_transfer_from_this)
	to_chat(user, "<span class='notice'>Теперь вы будете наносить содержимое спрея в виде [squirt_mode ? "лёгкого пшика":"пролжительной струи"]. Будет использоваться [amount_per_transfer_from_this] u за раз.</span>")

/obj/item/reagent_containers/medspray/attack(mob/living/L, mob/user, def_zone)
	INVOKE_ASYNC(src, PROC_REF(attempt_spray), L, user, def_zone)		// this is shitcode because the params for attack aren't even right but i'm not in the mood to refactor right now.

/obj/item/reagent_containers/medspray/proc/attempt_spray(mob/living/L, mob/user, def_zone)
	if(!reagents || !reagents.total_volume)
		to_chat(user, "<span class='warning'>Внутри [src] пусто!</span>")
		return

	var/obj/item/bodypart/affecting = L.get_bodypart(check_zone(user.zone_selected))
	if(ishuman(L))
		if(!affecting)
			to_chat(user, "<span class='warning'>Конечность отсутствует!</span>")
			return
		if(!L.can_inject(user, TRUE, user.zone_selected, FALSE, TRUE)) //stopped by clothing, like patches
			return
		if(!affecting.is_organic_limb())
			to_chat(user, "<span class='notice'>Спрей не сработает на роботические конечности!</span>")
			return
		else if(!affecting.is_organic_limb(FALSE))
			to_chat(user, "<span class='notice'>Биомеханические конечности невозможно обслужить спреем!</span>")

	if(L == user)
		L.visible_message("<span class='notice'>[user] пытается применить [apply_method] [src] на себя.</span>")
		if(self_delay)
			if(!do_mob(user, L, self_delay))
				return
			if(!reagents || !reagents.total_volume)
				return
		to_chat(L, "<span class='notice'>Вы нанесли [apply_method] на себя при помощи [src].</span>")

	else
		log_combat(user, L, "attempted to apply", src, reagents.log_list())
		L.visible_message("<span class='danger'>[user] пытается нанести [apply_method] на [L].</span>", \
							"<span class='userdanger'>[user] пытается нанести [apply_method] на вас!</span>")
		if(!do_mob(user, L, other_delay))
			return
		if(!reagents || !reagents.total_volume)
			return
		L.visible_message("<span class='danger'>[user] наносит [apply_method] на [L] при помощи [src].</span>", \
							"<span class='userdanger'>[user] наносит [apply_method] на вас при помощи [src].</span>")

	if(!reagents || !reagents.total_volume)
		return

	else
		log_combat(user, L, "applied", src, reagents.log_list())
		playsound(src, 'sound/effects/spray2.ogg', 50, 1, -6)
		var/fraction = min(amount_per_transfer_from_this/reagents.total_volume, 1)
		reagents.reaction(L, apply_type, fraction, affected_bodypart = affecting)
		reagents.trans_to(L, amount_per_transfer_from_this, log = TRUE)
	return

/obj/item/reagent_containers/medspray/styptic
	name = "medical spray (styptic powder)"
	desc = "Медицинский спрей для точечных применений. Видна розовая этикетка с названием препарата: \"Чесоточный порошок\". Пригоден для лечения порезов и ушибов."
	icon_state = "brutespray"
	list_reagents = list(/datum/reagent/medicine/styptic_powder = 60)

/obj/item/reagent_containers/medspray/silver_sulf
	name = "medical spray (silver sulfadiazine)"
	desc = "Медицинский спрей для точечных применений. Видна жёлтая этикетка с названием препарата: \"Серебряный сульфатдиазин\". Пригоден для лечения ожогов."
	icon_state = "burnspray"
	list_reagents = list(/datum/reagent/medicine/silver_sulfadiazine = 60)

/obj/item/reagent_containers/medspray/synthflesh
	name = "medical spray (synthflesh)"
	desc = "Медицинский спрей для точечных применений. Внутри содержится синтплоть, средство лечения любых физических ранений."
	icon_state = "synthspray"
	list_reagents = list(/datum/reagent/medicine/synthflesh = 120)

/obj/item/reagent_containers/medspray/sterilizine
	name = "sterilizer spray"
	desc = "Медицинский спрей для с нетоксичным стерилизатором-антисептиком. Незаменим для подготовки операции."
	list_reagents = list(/datum/reagent/space_cleaner/sterilizine = 60)

/obj/item/reagent_containers/medspray/synthtissue
	name = "Synthtissue young culture spray"
	desc = "SМедицинский спрей с колонией синттканей. Необходим для операций прививания синтплоти."
	list_reagents = list(/datum/reagent/synthtissue = 60)
