/obj/item/reagent_containers/syringe
	name = "syringe"
	desc = "Шприц. Может вмещать в себе до 15 u."
	icon = 'icons/obj/syringe.dmi'
	item_state = "syringe_0"
	lefthand_file = 'icons/mob/inhands/equipment/medical_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/medical_righthand.dmi'
	icon_state = "0"
	amount_per_transfer_from_this = 5
	possible_transfer_amounts = list()
	volume = 15
	var/mode = SYRINGE_DRAW
	var/busy = FALSE		// needed for delayed drawing of blood
	var/proj_piercing = 0 //does it pierce through thick clothes when shot with syringe gun
	var/show_filling = TRUE
	custom_materials = list(/datum/material/iron=10, /datum/material/glass=20)
	reagent_flags = TRANSPARENT
	custom_price = PRICE_CHEAP_AS_FREE
	sharpness = SHARP_POINTY

/obj/item/reagent_containers/syringe/Initialize(mapload)
	. = ..()
	if(list_reagents) //syringe starts in inject mode if its already got something inside
		mode = SYRINGE_INJECT
		update_icon()

/obj/item/reagent_containers/syringe/ComponentInitialize()
	. = ..()
	AddElement(/datum/element/update_icon_updates_onmob)

/obj/item/reagent_containers/syringe/on_reagent_change(changetype)
	update_icon()

/obj/item/reagent_containers/syringe/pickup(mob/user)
	..()
	update_icon()

/obj/item/reagent_containers/syringe/dropped(mob/user)
	..()
	update_icon()

/obj/item/reagent_containers/syringe/attack_self(mob/user)
	mode = !mode
	update_icon()

/obj/item/reagent_containers/syringe/on_attack_hand()
	. = ..()
	update_icon()

/obj/item/reagent_containers/syringe/attack_paw(mob/user)
	return attack_hand(user)

/obj/item/reagent_containers/syringe/attackby(obj/item/I, mob/user, params)
	return

/obj/item/reagent_containers/syringe/attack()
	return			// no bludgeoning.

/obj/item/reagent_containers/syringe/afterattack(atom/target, mob/user, proximity)
	. = ..()
	INVOKE_ASYNC(src, PROC_REF(attempt_inject), target, user, proximity)

/obj/item/reagent_containers/syringe/proc/attempt_inject(atom/target, mob/user, proximity)
	if(busy)
		return
	if(!proximity)
		return
	if(!target.reagents)
		return

	var/mob/living/L
	if(isliving(target))
		L = target
		if(!L.can_inject(user, 1))
			return

	// chance of monkey retaliation
	if(ismonkey(target) && prob(MONKEY_SYRINGE_RETALIATION_PROB))
		var/mob/living/carbon/monkey/M
		M = target
		M.retaliate(user)

	switch(mode)
		if(SYRINGE_DRAW)

			if(reagents.total_volume >= reagents.maximum_volume)
				to_chat(user, "<span class='notice'>Шприц полон.</span>")
				return

			if(L) //living mob
				var/drawn_amount = reagents.maximum_volume - reagents.total_volume
				if(target != user)
					target.visible_message("<span class='danger'>[user] пытается взять образец крови у [target]!</span>", \
									"<span class='userdanger'>[user] пытается взять образец крови у [target]!</span>")
					busy = TRUE
					if(!do_mob(user, target, extra_checks=CALLBACK(L, TYPE_PROC_REF(/mob/living, can_inject),user,1)))
						busy = FALSE
						return
					if(reagents.total_volume >= reagents.maximum_volume)
						return
				busy = FALSE
				if(L.transfer_blood_to(src, drawn_amount))
					user.visible_message("[user] берёт образец крови у [L].")
				else
					to_chat(user, "<span class='warning'>Вы вообще не можете взять нисколько крови у [L]!</span>")

			else //if not mob
				if(!target.reagents.total_volume)
					to_chat(user, "<span class='warning'>Внутри [target] пусто!</span>")
					return

				if(!target.is_drawable())
					to_chat(user, "<span class='warning'>Вы не можете взять что-либо напрямую из [target]!</span>")
					return

				var/trans = target.reagents.trans_to(src, amount_per_transfer_from_this, log = TRUE) // transfer from, transfer to - who cares?

				to_chat(user, "<span class='notice'>Вы наполнили [src] на [trans] u раствора. Теперь внутри [reagents.total_volume] u.</span>")
			if (round(reagents.total_volume, 0.1) >= reagents.maximum_volume)
				mode=!mode
				update_icon()

		if(SYRINGE_INJECT)
			// Always log attemped injections for admins
			var/contained = reagents.log_list()
			log_combat(user, target, "attempted to inject", src, addition="which had [contained]")

			if(!reagents.total_volume)
				to_chat(user, "<span class='notice'>Внутри [src] пусто.</span>")
				return

			if(!L && !target.is_injectable()) //only checks on non-living mobs, due to how can_inject() handles
				to_chat(user, "<span class='warning'>Вы не можете влить что-либо напрямую в [target]!</span>")
				return

			if(target.reagents.total_volume >= target.reagents.maximum_volume)
				to_chat(user, "<span class='notice'>[target] is full.</span>")
				return

			if(L) //living mob
				if(!L.can_inject(user, TRUE))
					return
				if(L != user)
					L.visible_message("<span class='danger'>[user] пытается сделать инъекцию [L]!</span>", \
											"<span class='userdanger'>[user] пытается сделать инъекцию [L]!</span>")
					if(!do_mob(user, L, extra_checks=CALLBACK(L, TYPE_PROC_REF(/mob/living, can_inject),user,1)))
						return
					if(!reagents.total_volume)
						return
					if(L.reagents.total_volume >= L.reagents.maximum_volume)
						return
					L.visible_message("<span class='danger'>[user] сделал[user.ru_a()] инъекцию [L] шприцом!", \
									"<span class='userdanger'>[user] сделал[user.ru_a()] инъекцию [L] шприцо!</span>")

				if(L != user)
					log_combat(user, L, "injected", src, addition="which had [contained]")
				else
					L.log_message("injected themselves ([contained]) with [src.name]", LOG_ATTACK, color="orange")
			var/fraction = min(amount_per_transfer_from_this/reagents.total_volume, 1)
			reagents.reaction(L, INJECT, fraction)
			reagents.trans_to(target, amount_per_transfer_from_this, log = TRUE)
			to_chat(user, "<span class='notice'>Вы вкололи [amount_per_transfer_from_this] u раствора. В шприце осталось [reagents.total_volume] u.</span>")
			if (reagents.total_volume <= 0 && mode==SYRINGE_INJECT)
				mode = SYRINGE_DRAW
				update_icon()

/obj/item/reagent_containers/syringe/update_icon_state()
	var/rounded_vol = get_rounded_vol()
	icon_state = "[rounded_vol]"
	item_state = "syringe_[rounded_vol]"

/obj/item/reagent_containers/syringe/update_overlays()
	. = ..()
	if(show_filling)
		var/rounded_vol = get_rounded_vol()
		if(reagents && reagents.total_volume)
			. += mutable_appearance('icons/obj/reagentfillings.dmi', "syringe[rounded_vol]", color = mix_color_from_reagents(reagents.reagent_list))
	if(ismob(loc))
		var/injoverlay
		switch(mode)
			if (SYRINGE_DRAW)
				injoverlay = "draw"
			if (SYRINGE_INJECT)
				injoverlay = "inject"
		. += injoverlay

///Used by update_icon() and update_overlays()
/obj/item/reagent_containers/syringe/proc/get_rounded_vol()
	if(reagents && reagents.total_volume)
		return clamp(round((reagents.total_volume / volume * 15),5), 1, 15)
	else
		return FALSE

/obj/item/reagent_containers/syringe/epinephrine
	name = "syringe (epinephrine)"
	desc = "Содержит эпинефрин - для стабилизации пациентов."
	list_reagents = list(/datum/reagent/medicine/epinephrine = 15)

/obj/item/reagent_containers/syringe/charcoal
	name = "syringe (charcoal)"
	desc = "Содержит активированный уголь."
	list_reagents = list(/datum/reagent/medicine/charcoal = 15)

/obj/item/reagent_containers/syringe/antiviral
	name = "syringe (spaceacillin)"
	desc = "Содержит антипатогенные агенты."
	list_reagents = list(/datum/reagent/medicine/spaceacillin = 15)

/obj/item/reagent_containers/syringe/bioterror
	name = "bioterror syringe"
	desc = "Содержит смесь препаратов-паралитиков."
	list_reagents = list(/datum/reagent/consumable/ethanol/neurotoxin = 5, /datum/reagent/toxin/mutetoxin = 5, /datum/reagent/toxin/sodium_thiopental = 5)

/obj/item/reagent_containers/syringe/stimulants
	name = "Stimpack"
	desc = "Содержит стимулянты."
	amount_per_transfer_from_this = 50
	volume = 50
	list_reagents = list(/datum/reagent/medicine/stimulants = 50)

/obj/item/reagent_containers/syringe/contraband
	name = "unlabeled syringe"
	desc = "Шприц с какой-то неизвестным коктейлем препаратов."

/obj/item/reagent_containers/syringe/contraband/space_drugs
	list_reagents = list(/datum/reagent/drug/space_drugs = 15)

/obj/item/reagent_containers/syringe/contraband/krokodil
	list_reagents = list(/datum/reagent/drug/krokodil = 15)

/obj/item/reagent_containers/syringe/contraband/crank
	list_reagents = list(/datum/reagent/drug/crank = 15)

/obj/item/reagent_containers/syringe/contraband/methamphetamine
	list_reagents = list(/datum/reagent/drug/methamphetamine = 15)

/obj/item/reagent_containers/syringe/contraband/bath_salts
	list_reagents = list(/datum/reagent/drug/bath_salts = 15)

/obj/item/reagent_containers/syringe/contraband/fentanyl
	list_reagents = list(/datum/reagent/toxin/fentanyl = 15)

/obj/item/reagent_containers/syringe/contraband/morphine
	list_reagents = list(/datum/reagent/medicine/morphine = 15)

/obj/item/reagent_containers/syringe/calomel
	name = "syringe (calomel)"
	desc = "Содержит каломель."
	list_reagents = list(/datum/reagent/medicine/calomel = 15)

/obj/item/reagent_containers/syringe/plasma
	name = "syringe (plasma)"
	desc = "Содержит жидкую плазму."
	list_reagents = list(/datum/reagent/toxin/plasma = 15)

/obj/item/reagent_containers/syringe/lethal
	name = "lethal injection syringe"
	desc = "Шприц для смертельных инъекций. Может вмещать до 50 u."
	amount_per_transfer_from_this = 50
	volume = 50

/obj/item/reagent_containers/syringe/lethal/choral
	list_reagents = list(/datum/reagent/toxin/chloralhydrate = 50)

/obj/item/reagent_containers/syringe/lethal/execution
	list_reagents = list(/datum/reagent/toxin/amatoxin = 15, /datum/reagent/toxin/formaldehyde = 15, /datum/reagent/toxin/cyanide = 10, /datum/reagent/toxin/acid/fluacid = 10) //Citadel edit, changing out plasma from lethals

/obj/item/reagent_containers/syringe/mulligan
	name = "Mulligan"
	desc = "Шприц дл полной смены личности пользователя."
	amount_per_transfer_from_this = 1
	volume = 1
	list_reagents = list(/datum/reagent/mulligan = 1)

/obj/item/reagent_containers/syringe/gluttony
	name = "Gluttony's Blessing"
	desc = "Шприц из каких-то лихих мест. Возможно, будет мудрым отложить его в сторону."
	amount_per_transfer_from_this = 1
	volume = 1
	list_reagents = list(/datum/reagent/gluttonytoxin = 1)

/obj/item/reagent_containers/syringe/bluespace
	name = "bluespace syringe"
	desc = "Продвинутый шприц, способный вмещать до 60 u веществ."
	amount_per_transfer_from_this = 20
	volume = 60

/obj/item/reagent_containers/syringe/noreact
	name = "cryo syringe"
	desc = "Прдвинутый шпирц, останавливающий реакции препаратов внутри. Может вмещать до 20 u."
	volume = 20
	reagent_flags = TRANSPARENT | NO_REACT

/obj/item/reagent_containers/syringe/piercing
	name = "piercing syringe"
	desc = "Шприц с алмазным накончеником, способный пробить слои брони, если летит на высокой скорости. Может вмещать до 10 u."
	volume = 10
	proj_piercing = 1

/obj/item/reagent_containers/syringe/get_belt_overlay()
	return mutable_appearance('icons/obj/clothing/belt_overlays.dmi', "pouch")

/obj/item/reagent_containers/syringe/dart
	name = "medicinal smartdart"
	desc = "Безвредный дротик для введения медикаментов на расстоянии. Уколов пациента, смарт-нанофильтер введёт только лекарства внутри дротика. Вдобавок к этому, из-за капиллярного эффекта, инъекции не превысят пациенту порог дозировки препарата."
	volume = 20
	amount_per_transfer_from_this = 20
	icon_state = "empty"
	item_state = "syringe_empty"
	show_filling = FALSE
	var/emptrig = FALSE

/obj/item/reagent_containers/syringe/dart/afterattack(atom/target, mob/user , proximity)

	if(busy)
		return
	if(!proximity)
		return
	if(!target.reagents)
		return

	var/mob/living/L
	if(isliving(target))
		L = target
		if(!L.can_inject(user, 1))
			return

	switch(mode)
		if(SYRINGE_DRAW)

			if(reagents.total_volume >= reagents.maximum_volume)
				to_chat(user, "<span class='notice'>Дротик наполнен!</span>")
				return

			if(L) //living mob
				to_chat(user, "<span class='warning'>Вы не можете брать кровь дротиком!</span>")
				return

			else //if not mob
				if(!target.reagents.total_volume)
					to_chat(user, "<span class='warning'>Внутри [target] пусто!</span>")
					return

				if(!target.is_drawable())
					to_chat(user, "<span class='warning'>Вы не можете взять что-либо напрямую из [target]!</span>")
					return

				var/trans = target.reagents.trans_to(src, amount_per_transfer_from_this)

				to_chat(user, "<span class='notice'>Вы обмакнули [src] в [trans] u раствора. Теперь внутри содержится [reagents.total_volume] u.</span>")
			if (round(reagents.total_volume,1) >= reagents.maximum_volume)
				mode=!mode
				update_icon()

		if(SYRINGE_INJECT)
			src.visible_message("<span class='danger'>Смартдарт даёт разражённый \"буп\"! Он полностью наполнен; подстрелите им кого-нибудь!</span>")

/obj/item/reagent_containers/syringe/dart/attack_self(mob/user)
	return

/obj/item/reagent_containers/syringe/dart/update_icon_state()
	var/empty_full = "empty"
	if(round(reagents.total_volume, 1) == reagents.maximum_volume)
		empty_full = "full"
		mode = SYRINGE_INJECT
	icon_state = "[empty_full]"
	item_state = "syringe_[empty_full]"

/obj/item/reagent_containers/syringe/dart/emp_act(severity)
	emptrig = TRUE
	..()

/obj/item/reagent_containers/syringe/dart/bluespace
	name = "bluespace smartdart"
	desc = "Безвредный дротик для введения медикаментов на расстоянии. Уколов пациента, смарт-нанофильтер введёт только лекарства внутри дротика. Вдобавок к этому, из-за капиллярного эффекта, инъекции не превысят пациенту порог дозировки препарата. Вмещает большие объёмы благодаря блюспейс-пене."
	amount_per_transfer_from_this = 50
	volume = 50
