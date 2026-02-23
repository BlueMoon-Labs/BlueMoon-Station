/obj/structure/chair/sybian
	name = "sybian"
	desc = "It provides vibration."
	icon = 'modular_bluemoon/icons/obj/structures/lewd_devices.dmi'
	icon_state = "sybian"
	anchored = TRUE
	var/mode = "normal"
	var/intencity
	var/on = 0
	item_chair = null // нельзя брать в руки
	flags_1 = NODECONSTRUCT_1

/obj/structure/chair/sybian/New()
	..()
	add_overlay(mutable_appearance('modular_bluemoon/icons/obj/structures/lewd_devices.dmi', "sybian_over", MOB_LAYER + 1))

/obj/structure/chair/sybian/verb/change_mode()
	set name = "Change mode"
	set category = "Object"
	set src in oview(1)

	var/input = input(usr,"Change intensity mode") as null|anything in list("low", "normal", "high")
	if(input)
		mode = input
		if(mode == "low")
			intencity = 6
		if(mode == "normal")
			intencity = 12
		if(mode == "high")
			intencity = 18

/obj/structure/chair/sybian/verb/toggle()
	set name = "Toggle vibration"
	set category = "Object"
	set src in oview(1)
	on = !on
	spawn()
		while(on)
			if(activate_after(src, 5))
				vibrate()
	if(on)
		to_chat(usr, "[src] вкл.")
	else
		to_chat(usr, "[src] выкл.")

/obj/structure/chair/sybian/proc/vibrate()
	if(!on)
		return

	if(has_buckled_mobs())
		for(var/m in buckled_mobs)
			var/mob/living/carbon/human/M = m
			M.handle_post_sex(intencity, null, src)
			M.client?.plug13.send_emote(pick(PLUG13_EMOTE_GROIN, PLUG13_EMOTE_ANUS), min(intencity * 5, 100), PLUG13_DURATION_NORMAL)
			switch(mode)
				if("low")
					playsound(loc, "modular_bluemoon/sound/items/lewd/toys/devicevibrator[rand(1, 3)].ogg", 30, 1)
					to_chat(M, span_love(pick("Я чувствую слабую вибрацию между ног!", "Оно слабо стимулирует мои гениталии!")))
				if("normal")
					playsound(loc, "modular_bluemoon/sound/items/lewd/toys/magicwand[rand(1, 2)].ogg", 30, 1)
					to_chat(M, span_love(pick("Я чувствую вибрацию между ног!", "Оно вибрирует мои гениталии!")))
				if("high")
					to_chat(M, span_userdanger(pick("Сильная вибрация между ног сводит меня с ума!", "Вы чувствуете мучительное удовольствие от сильной стимуляции гениталий!")))
					playsound(loc, "modular_bluemoon/sound/items/lewd/toys/magicwand3.ogg", 30, 1)
					M.Jitter(3)
					M.Stun(3)
					if(prob(50))
						M.emote("moan")

/obj/structure/chair/sybian/attackby(obj/item/used_item, mob/user, params)
	if(used_item.tool_behaviour == TOOL_WRENCH)
		to_chat(user, "<span class='notice'>You begin to [anchored ? "unwrench" : "wrench"] [src].</span>")
		if(used_item.use_tool(src, user, 20, volume=30))
			to_chat(user, "<span class='notice'>You successfully [anchored ? "unwrench" : "wrench"] [src].</span>")
			setAnchored(!anchored)
	else if(istype(used_item, /obj/item/screwdriver))
		to_chat(user, span_notice("You unscrew the frame and begin to deconstruct it..."))
		playsound(loc, "'sound/items/screwdriver.ogg'", 30, 1)
		if(used_item.use_tool(src, user, 8 SECONDS, volume = 50))
			to_chat(user, span_notice("You disassemble it."))
			new /obj/item/sybian_kit (src.loc)
			qdel(src)
	else
		return ..()

/obj/item/sybian_kit
	name = "sybian construction kit"
	desc = "Construction requires a screwdriver. Put it on the ground first!"
	icon = 'modular_bluemoon/icons/obj/structures/lewd_devices.dmi'
	icon_state = "kit"
	throwforce = 0
	var/unwrapped = 0
	w_class = WEIGHT_CLASS_HUGE

/obj/item/sybian_kit/attackby(obj/item/used_item, mob/user, params) //constructing a bed here.
	add_fingerprint(user)
	if(istype(used_item, /obj/item/screwdriver))
		if (!(item_flags & IN_INVENTORY) && !(item_flags & IN_STORAGE))
			to_chat(user, span_notice("You screw the frame to the floor and begin to construct it..."))
			playsound(loc, "'sound/items/screwdriver.ogg'", 30, 1)
			if(used_item.use_tool(src, user, 8 SECONDS, volume = 50))
				to_chat(user, span_notice("You assemble it."))
				new /obj/structure/chair/sybian (src.loc)
				qdel(src)
			return
	else
		return ..()
