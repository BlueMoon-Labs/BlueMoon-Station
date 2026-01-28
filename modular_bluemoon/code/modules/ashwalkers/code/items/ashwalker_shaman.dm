//ASH STAFF
/obj/item/ash_staff
	name = "staff of the ashlands"
	desc = "Суковатая и искривленная ветвь, пропитанная какой-то древней силой."
	icon_state = "staffofstorms"
	item_state = "staffofstorms"
	lefthand_file = 'icons/mob/inhands/weapons/staves_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/staves_righthand.dmi'
	icon = 'icons/obj/guns/magic.dmi'
	slot_flags = ITEM_SLOT_BACK
	w_class = WEIGHT_CLASS_BULKY
	force = 25
	damtype = BURN
	resistance_flags = LAVA_PROOF | FIRE_PROOF | ACID_PROOF
	hitsound = 'sound/weapons/sear.ogg'
	var/turf_type = /turf/open/lava/smooth
	var/transform_string = "lava"
	var/reset_turf_type = /turf/open/floor/plating/asteroid/basalt
	var/reset_string = "basalt"
	var/create_cooldown = 100
	var/create_delay = 30
	var/reset_cooldown = 50
	var/timer = 0
	var/static/list/banned_turfs = typecacheof(list(/turf/open/space/transit, /turf/closed))

/obj/item/lava_staff/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	. = ..()
	INVOKE_ASYNC(src, PROC_REF(attempt_lava_shaman), target, user, proximity_flag, click_parameters)

/obj/item/lava_staff/proc/attempt_lava_shaman(atom/target, mob/user, proximity_flag, click_parameters)
	if(timer > world.time)
		return

	if(is_type_in_typecache(target, banned_turfs))
		return

	if(target in view(user.client.view, get_turf(user)))

		var/turf/open/T = get_turf(target)
		if(!istype(T))
			return
		if(!istype(T, turf_type))
			var/obj/effect/temp_visual/lavastaff/L = new /obj/effect/temp_visual/lavastaff(T)
			L.alpha = 0
			animate(L, alpha = 255, time = create_delay)
			user.visible_message("<span class='danger'>[user] points [src] at [T]!</span>")
			timer = world.time + create_delay + 1
			if(do_after(user, create_delay, target = T))
				var/old_name = T.name
				if(T.TerraformTurf(turf_type, flags = CHANGETURF_INHERIT_AIR))
					user.visible_message("<span class='danger'>[user] turns \the [old_name] into [transform_string]!</span>")
					message_admins("[ADMIN_LOOKUPFLW(user)] fired the lava staff at [ADMIN_VERBOSEJMP(T)]")
					log_game("[key_name(user)] fired the lava staff at [AREACOORD(T)].")
					timer = world.time + create_cooldown
					playsound(T,'sound/magic/fireball.ogg', 200, 1)
			else
				timer = world.time
			qdel(L)
		else
			var/old_name = T.name
			if(T.TerraformTurf(reset_turf_type, flags = CHANGETURF_INHERIT_AIR))
				user.visible_message("<span class='danger'>[user] turns \the [old_name] into [reset_string]!</span>")
				timer = world.time + reset_cooldown
				playsound(T,'sound/magic/fireball.ogg', 200, 1)

/obj/effect/temp_visual/lavastaff
	icon_state = "lavastaff_warn"
	duration = 50
/obj/item/cursed_dagger
	name = "cursed ash dagger"
	desc = "Тупой кинжал, который, кажется, заставляет дрожать тени рядом с ним."
	icon = 'icons/obj/weapons/sword.dmi'
	icon_state = "crysknife"

/obj/item/cursed_dagger/examine(mob/user)
	. = ..()
	. += span_notice("Используется на тендриле. Визуально изменит тендрил, чтобы показать, был ли он проклят или нет.")

/obj/item/tendril_seed
	name = "tendril seed"
	desc = "Ужасная мясистая масса, пульсирующая темной энергией."
	icon = 'modular_bluemoon/code/modules/ashwalkers/icons/ashwalker_tools.dmi'
	icon_state = "tendril_seed"

/obj/item/tendril_seed/examine(mob/user)
	. = ..()
	. += span_notice("Для посадки необходимо находиться на уровне добычи.")

/obj/item/tendril_seed/attack_self(mob/user, modifiers)
	. = ..()
	var/turf/src_turf = get_turf(src)
	if(!is_mining_level(src_turf.z))
		return
	if(!isliving(user))
		return
	var/mob/living/living_user = user
	to_chat(living_user, span_warning("Вы начинаете сжимать [src]..."))
	if(!do_after(living_user, 4 SECONDS, target = src))
		return
	to_chat(living_user, span_warning("[src] начинает ползти между пальцами вашей руки, поднимаясь по руке..."))
	living_user.adjustBruteLoss(35)
	if(!do_after(living_user, 4 SECONDS, target = src))
		return
	to_chat(living_user, span_warning("[src] обхватывает грудь и начинает сдавливать, вызывая странное покалывание..."))
	living_user.adjustBruteLoss(35)
	if(!do_after(living_user, 4 SECONDS, target = src))
		return
	to_chat(living_user, span_warning("[src] отскакивает от вас удовлетворенный и начинает грубо собираться!"))
	var/type = pick(/obj/structure/spawner/lavaland, /obj/structure/spawner/lavaland/goliath, /obj/structure/spawner/lavaland/legion)
	new type(user.loc)
	playsound(get_turf(src), 'sound/effects/magic/demon_attack1.ogg', 50, TRUE)
	qdel(src)
//DEFAULT NECK ITEMS OVERRIDE//
/obj/item/clothing/neck
	w_class = WEIGHT_CLASS_SMALL

//ASHWALKER TRANSLATOR NECKLACE//
#define LANGUAGE_TRANSLATOR "translator"
/obj/item/clothing/neck/necklace/ashwalker
	name = "ashen necklace"
	desc = "Ожерелье, изготовленное из пепла и связанное с Некрополисом через ядро Легиона. При ношении оно наделяет обитателей надземного мира неестественным пониманием языка рептилий, родного языка Лаваленда."
	icon = 'icons/obj/clothing/neck.dmi'
	icon_state = "ashnecklace"
	w_class = WEIGHT_CLASS_SMALL //allows this to fit inside of pockets.

/obj/item/clothing/neck/necklace/ashwalker/cursed
	name = "cursed ashen necklace"
	desc = "Ожерелье, изготовленное из пепла и связанное с Некрополем через ядро Легиона. При ношении оно наделяет обитателей надземного мира неестественным пониманием языка рептилий, родного языка Лаваленда. Не может быть снято!"

/obj/item/clothing/neck/necklace/ashwalker/cursed/Initialize(mapload)
	. = ..()
	ADD_TRAIT(src, TRAIT_NODROP, ABSTRACT_ITEM_TRAIT)

//uses code from the pirate hat.
/obj/item/clothing/neck/necklace/ashwalker/equipped(mob/user, slot)
	. = ..()
	if(!ishuman(user))
		return
	if(slot & ITEM_SLOT_NECK)
		user.grant_language(/datum/language/draconic, source = LANGUAGE_TRANSLATOR)
		to_chat(user, span_boldnotice("Надевая ожерелье, вы чувствуете, как коварная тень Некрополя проникает в ваши кости и саму вашу тень. Вы обнаруживаете, что обладаете неестественным знанием языка рептилий, но глаз амулета пристально смотрит на вас."))

/obj/item/clothing/neck/necklace/ashwalker/dropped(mob/user)
	. = ..()
	if(!ishuman(user))
		return
	var/mob/living/carbon/human/H = user
	if(H.get_item_by_slot(ITEM_SLOT_NECK) == src && !QDELETED(src)) //This can be called as a part of destroy
		user.remove_language(/datum/language/draconic, source = LANGUAGE_TRANSLATOR)
		to_chat(user, span_boldnotice("Вы чувствуете, как чужой разум Некрополиса теряет к вам интерес, когда вы снимаете ожерелье. Глаз закрывается, и ваш разум тоже, теряя связь с языком рептилий."))

//ASHWALKER TRANSLATOR NECKLACE END//

#undef LANGUAGE_TRANSLATOR
