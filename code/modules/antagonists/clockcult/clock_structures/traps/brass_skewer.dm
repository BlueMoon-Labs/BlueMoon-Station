//Non-servants standing over this will get spikes through the feet, immobilizing them until they're freed.
/obj/structure/destructible/clockwork/trap/brass_skewer
	name = "brass skewer"
	desc = "Смертоносный латунный шип, искусно спрятанный в полу. Вы думаете, что будете в безопасности, если обезвредите то, что должно привести его в действие."
	clockwork_desc = "Варварское, но, несомненно, эффективное оружие: копье, пронзающее грудь. Оно обездвиживает любого, кому не повезло наступить на него, и удерживает на месте до тех пор, пока не подоспеет помощь."
	icon_state = "brass_skewer"
	break_message = "<span class='warning'>Шип ломается пополам!</span>"
	max_integrity = 40
	density = FALSE
	can_buckle = TRUE
	buckle_prevents_pull = TRUE
	buckle_lying = FALSE
	var/wiggle_wiggle
	var/mutable_appearance/impale_overlay //This is applied to any mob impaled so that they visibly have the skewer coming through their chest

/obj/structure/destructible/clockwork/trap/brass_skewer/Initialize(mapload)
	. = ..()
	START_PROCESSING(SSfastprocess, src)

/obj/structure/destructible/clockwork/trap/brass_skewer/Destroy()
	STOP_PROCESSING(SSfastprocess, src)
	if(buckled_mobs && LAZYLEN(buckled_mobs))
		var/mob/living/L = buckled_mobs[1]
		if(iscarbon(L))
			L.DefaultCombatKnockdown(100)
			L.visible_message("<span class='warning'>[L] ранен, так как шип разлетелся на куски, не покидая [L.ru_ego()] тела.</span>")
			L.adjustBruteLoss(15)
		unbuckle_mob(L)
	return ..()

/obj/structure/destructible/clockwork/trap/brass_skewer/process()
	if(density)
		if(buckled_mobs && LAZYLEN(buckled_mobs))
			var/mob/living/spitroast = buckled_mobs[1]
			spitroast.adjustBruteLoss(0.1)

/obj/structure/destructible/clockwork/trap/attackby(obj/item/I, mob/living/user, params)
	if(buckled_mobs && (user in buckled_mobs))
		to_chat(user, "<span class='warning'>Вы не можете дотянуться!</span>")
		return
	..()

/obj/structure/destructible/clockwork/trap/brass_skewer/bullet_act(obj/item/projectile/P)
	if(buckled_mobs && LAZYLEN(buckled_mobs))
		var/mob/living/L = buckled_mobs[1]
		return L.bullet_act(P)
	return ..()

/obj/structure/destructible/clockwork/trap/brass_skewer/activate()
	if(density)
		return
	var/mob/living/squirrel = locate() in get_turf(src)
	if(squirrel)
		if(iscyborg(squirrel))
			if(!squirrel.stat)
				squirrel.visible_message("<span class='boldwarning'>Из земли вырывается массивный латунный шип, пробивает корпус [squirrel] и разлетается на куски!</span>", \
				"<span class='userdanger'>Массивный латунный шип пробивает ваше шасси и превращается в осколки внутри корпуса!</span>")
				squirrel.adjustBruteLoss(50)
				squirrel.Stun(20)
				addtimer(CALLBACK(src, PROC_REF(take_damage), max_integrity), 1)
		else
			squirrel.visible_message("<span class='boldwarning'>Из земли вырывается массивный латунный шип и пронзает [squirrel]!</span>", \
			"<span class='userdanger'>Массивный латунный шип пронзает вашу грудь, подбрасывая вас в воздух!</span>")
			squirrel.emote("realagony")
			playsound(squirrel, 'sound/effects/splat.ogg', 50, TRUE)
			playsound(squirrel, 'sound/misc/desceration-03.ogg', 50, TRUE)
			squirrel.apply_damage(20, BRUTE, BODY_ZONE_CHEST)
		mouse_opacity = MOUSE_OPACITY_OPAQUE //So players can interact with the tile it's on to pull them off
		buckle_mob(squirrel, TRUE)
	else
		var/obj/vehicle/sealed/mecha/M = locate() in get_turf(src)
		if(M)
			M.take_damage(50,BRUTE,MELEE)
			M.visible_message("<span class='danger'>Из земли вырывается массивный латунный шип, пронзает [M] и разбивает ловушку вдребезги!</span>")
			addtimer(CALLBACK(src, PROC_REF(take_damage), max_integrity), 1)
		else
			visible_message("<span class='danger'>Из земли вырывается огромный латунный шип!</span>")

	playsound(src, 'sound/machines/clockcult/brass_skewer.ogg', 75, FALSE)
	icon_state = "[initial(icon_state)]_extended"
	density = TRUE //Skewers are one-use only
	desc = "Зловещий латунный шип, торчащий из земли, словно стала[pick("гм", "кт")]ит. От одного взгляда на него становится не по себе." //is stalagmite the ground one? or the ceiling one? who can ever remember?

/obj/structure/destructible/clockwork/trap/brass_skewer/user_buckle_mob(check_loc)
	return

/obj/structure/destructible/clockwork/trap/brass_skewer/post_buckle_mob(mob/living/L)
	if(L in buckled_mobs)
		L.pixel_y = 3
		impale_overlay = mutable_appearance('icons/obj/clockwork_objects.dmi', "brass_skewer_pokeybit", ABOVE_MOB_LAYER)
		add_overlay(impale_overlay)
	else
		L.pixel_y = initial(L.pixel_y)
		L.cut_overlay(impale_overlay)

/obj/structure/destructible/clockwork/trap/brass_skewer/user_unbuckle_mob(mob/living/skewee, mob/living/user)
	if(user == skewee)
		if(wiggle_wiggle)
			return
		user.visible_message("<span class='warning'>[user] начинает сползать с [src]!</span>", \
		"<span class='danger'>Вы начинаете в мучениях высвобождаться из [src]...</span>")
		wiggle_wiggle = TRUE
		if(!do_after(user, 3 SECONDS, target = user))
			user.visible_message("<span class='warning'>[user] соскальзывает обратно на [src]!</span>")
			user.emote("realagony")
			user.apply_damage(10, BRUTE, BODY_ZONE_CHEST)
			playsound(user, 'sound/misc/desceration-03.ogg', 50, TRUE)
			wiggle_wiggle = FALSE
			return
		wiggle_wiggle = FALSE
	else
		user.visible_message("<span class='danger'>[user] начинает осторожно снимать [skewee] с [src]...</span>", \
		"<span class='danger'>Вы начинаете осторожно снимать [skewee] с [src]...</span>")
		if(!do_after(user, 60, target = skewee))
			skewee.visible_message("<span class='warning'>[skewee] болезненно соскальзывает обратно на [src].</span>")
			if(skewee.stat >= UNCONSCIOUS)
				return //by ratvar, no more spamming my deadchat, holy fuck
			skewee.emote("realagony")
			return
	skewee.visible_message("<span class='danger'>[skewee] с чавкающим хлюпаньем высвобождается из [src]!</span>", \
	"<span class='boldannounce'>Вы высвобождаетесь из [src]!</span>")
	skewee.DefaultCombatKnockdown(30)
	playsound(skewee, 'sound/misc/desceration-03.ogg', 50, TRUE)
	unbuckle_mob(skewee)
