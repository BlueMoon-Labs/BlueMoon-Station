/obj/item/gun/syringe
	name = "syringe gun"
	desc = "Пружинное ружьё для шприцов, обычно используемое против строптивых пациентов на безопасной дистанции."
	icon_state = "syringegun"
	item_state = "syringegun"
	w_class = WEIGHT_CLASS_NORMAL
	recoil = 0.1
	throw_speed = 3
	throw_range = 7
	force = 4
	inaccuracy_modifier = 0.25
	custom_materials = list(/datum/material/iron=2000)
	clumsy_check = 0
	fire_sound = 'sound/items/syringeproj.ogg'
	var/list/syringes = list()
	var/max_syringes = 1

/obj/item/gun/syringe/Initialize(mapload)
	. = ..()
	chambered = new /obj/item/ammo_casing/syringegun(src)

/obj/item/gun/syringe/recharge_newshot()
	if(!syringes.len)
		return
	chambered.newshot()

/obj/item/gun/syringe/can_shoot()
	return syringes.len

/obj/item/gun/syringe/process_chamber()
	if(chambered && !chambered.BB) //we just fired
		recharge_newshot()

/obj/item/gun/syringe/examine(mob/user)
	. = ..()
	. += "Может удерживать максимум [max_syringes] шт. шприцов. Внутри находится [syringes.len] шт. шприцов."

/obj/item/gun/syringe/attack_self(mob/living/user)
	if(!syringes.len)
		to_chat(user, "<span class='warning'>[src] пуст!</span>")
		return FALSE

	var/obj/item/reagent_containers/syringe/S = syringes[syringes.len]

	if(!S)
		return FALSE
	S.forceMove(user.loc)

	syringes.Remove(S)
	to_chat(user, "<span class='notice'>Вы вытащили [S] из \the [src].</span>")

	return TRUE

/obj/item/gun/syringe/attackby(obj/item/A, mob/user, params, show_msg = TRUE)
	if(istype(A, /obj/item/reagent_containers/syringe))
		if(syringes.len < max_syringes)
			if(!user.transferItemToLoc(A, src))
				return FALSE
			to_chat(user, "<span class='notice'>Вы зарядили [A] внутрь \the [src].</span>")
			syringes += A
			recharge_newshot()
			return TRUE
		else
			to_chat(user, "<span class='warning'>[src] не уместит больше шприцов!</span>")
	return FALSE

/obj/item/gun/syringe/rapidsyringe
	name = "rapid syringe gun"
	desc = "Модификация шприцевого ружья с револьверным цилиндром для хранения до шести шприцов."
	icon_state = "rapidsyringegun"
	max_syringes = 6

/obj/item/gun/syringe/syndicate
	name = "dart pistol"
	desc = "Небольшое вторичное оружие на пружине, функционально идентичное шприцевому ружью."
	icon_state = "syringe_pistol"
	item_state = "gun" //Smaller inhand
	w_class = WEIGHT_CLASS_SMALL
	force = 2 //Also very weak because it's smaller
	suppressed = TRUE //Softer fire sound
	can_unsuppress = FALSE //Permanently silenced

/obj/item/gun/syringe/dna
	name = "modified syringe gun"
	desc = "Шприцевое ружьё, модифицированное для вмещения ДНК-инъекторов вместо нормальных шприцов."

/obj/item/gun/syringe/dna/Initialize(mapload)
	. = ..()
	chambered = new /obj/item/ammo_casing/dnainjector(src)

/obj/item/gun/syringe/dna/attackby(obj/item/A, mob/user, params, show_msg = TRUE)
	if(istype(A, /obj/item/dnainjector))
		var/obj/item/dnainjector/D = A
		if(D.used)
			to_chat(user, "<span class='warning'>Инжектор использован</span>")
			return
		if(syringes.len < max_syringes)
			if(!user.transferItemToLoc(D, src))
				return FALSE
			to_chat(user, "<span class='notice'>Вы зарядили \the [D] внутрь \the [src].</span>")
			syringes += D
			recharge_newshot()
			return TRUE
		else
			to_chat(user, "<span class='warning'>[src] не удержит больше инжекторов!</span>")
	return FALSE

/obj/item/gun/syringe/dart
	name = "dart gun"
	desc = "Пневматическое ружьё для стрельбы медицинскими дротиками, вмещающими препараты. Для пациентов вне зоны досягаемости."
	icon_state = "dartgun"
	item_state = "dartgun"
	custom_materials = list(/datum/material/iron=2000, /datum/material/glass=500)
	suppressed = TRUE //Softer fire sound
	can_unsuppress = FALSE

/obj/item/gun/syringe/dart/Initialize(mapload)
	. = ..()
	chambered = new /obj/item/ammo_casing/syringegun/dart(src)

/obj/item/gun/syringe/dart/attackby(obj/item/A, mob/user, params, show_msg = TRUE)
	if(istype(A, /obj/item/reagent_containers/syringe/dart))
		..()
	else
		to_chat(user, "<span class='notice'>Вы не можете зарядить [A] внутрь \the [src]!</span>")
		return FALSE

/obj/item/gun/syringe/dart/rapiddart
	name = "Repeating dart gun"
	icon_state = "rapiddartgun"
	item_state = "syringegun"

/obj/item/gun/syringe/dart/rapiddart/CheckParts(list/parts_list)
	var/obj/item/reagent_containers/glass/beaker/B = locate(/obj/item/reagent_containers/glass/beaker) in parts_list

	if(istype(B, /obj/item/reagent_containers/glass/beaker/large))
		desc = "[initial(desc)] Была модифицирована камера давления, используя [B], увеличиая максимальную ёмкость шприцов до [max_syringes]."
		max_syringes = 2
		return
	else if(istype(B, /obj/item/reagent_containers/glass/beaker/plastic))
		desc = "[initial(desc)] Была модифицирована камера давления, используя [B], увеличиая максимальную ёмкость шприцов до [max_syringes]."
		max_syringes = 3
		return
	else if(istype(B, /obj/item/reagent_containers/glass/beaker/meta))
		desc = "[initial(desc)] Была модифицирована камера давления, используя [B], увеличиая максимальную ёмкость шприцов до [max_syringes]."
		max_syringes = 4
		return
	else if(istype(B, /obj/item/reagent_containers/glass/beaker/bluespace))
		desc = "[initial(desc)] Была модифицирована камера давления, используя [B], увеличиая максимальную ёмкость шприцов до [max_syringes]."
		max_syringes = 6
		return
	else
		max_syringes = 1
		desc = "[initial(desc)] К ружью прикрепили [B], но не похоже, что это что-то даёт."
	..()

/obj/item/gun/syringe/blowgun
	name = "blowgun"
	desc = "Может запускать шприцы на короткие дистанции..."
	icon_state = "blowgun"
	item_state = "syringegun"
	fire_sound = 'sound/items/syringeproj.ogg'

/obj/item/gun/syringe/blowgun/process_fire(atom/target, mob/living/user, message = TRUE, params = null, zone_override = "", bonus_spread = 0, stam_cost = 0)
	visible_message("<span class='danger'>[user] начинает целиться из духовой трубки!</span>")
	if(do_after(user, 25, target = src))
		user.adjustStaminaLoss(20)
		user.adjustOxyLoss(20)
		..()
