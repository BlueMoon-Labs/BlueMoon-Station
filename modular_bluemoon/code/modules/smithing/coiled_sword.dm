/obj/item/smithing/coiled_sword
	name = "raw coiled sword"
	icon = 'modular_bluemoon/icons/obj/smith/coiled_sword.dmi'
	icon_state = "coiled_raw"
	resistance_flags = LAVA_PROOF | FIRE_PROOF
	finishingitem = /obj/item/stack/ore/glass/basalt
	finalitem = /obj/item/melee/smith/coiled_sword
	var/heated_in_lava = FALSE

/obj/item/smithing/coiled_sword/examine(mob/user)
	. = ..()
	if(!heated_in_lava)
		. += "Этот клинок выглядит практически завершенным, однако лишь кипящая лава позволит раскрыть его истинный потенциал."
	else
		. += "Этот клинок готов к финальному штриху - покрыванию вулканическим пеплом."

/obj/item/smithing/coiled_sword/attackby(obj/item/I, mob/user)
	if(istype(I, finishingitem))
		if(!heated_in_lava)
			to_chat(user, "Прежде чем покрывать витой меч вулканическим пеплом, его требуется окунуть в кипящую лаву. Только она поможет ракрыть его потенциал.")
			return
		else
			var/obj/item/stack/ore/glass/basalt/B = I
			if(B.get_amount() > 1)
				B.split_stack(user, (B.get_amount() - 1)) // will use 1
			. = ..()
	else
		. = ..()

/obj/item/smithing/coiled_sword/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	. = ..()
	if(islava(target) && proximity_flag)
		visible_message("[user] погружает лезвие витого меча в кипящую лаву...")
		if(do_after(user, 10 SECONDS, target, IGNORE_HELD_ITEM))
			visible_message("... и вынимает - лезвие излучает томную пылающую ауру.")
			heated_in_lava = TRUE
			add_overlay(mutable_appearance('modular_bluemoon/icons/obj/smith/coiled_sword.dmi', "coiled_flame"))
		else
			visible_message("... но вынимает его слишком рано и клинок заметно тускнеет.")
			quality -= 2

/obj/item/smithing/coiled_sword/startfinish()
	var/obj/item/melee/smith/coiled_sword/finalforreal = new /obj/item/melee/smith/coiled_sword(src)
	finalforreal.quality = quality
	finalforreal.force += quality/2
	finalforreal.flame_power = max(1, (finalforreal.flame_power + quality/2)) // 1 to 6+
	finalitem = finalforreal
	..()

/obj/item/melee/smith/coiled_sword
	name = "coiled sword"
	icon = 'modular_bluemoon/icons/obj/smith/coiled_sword.dmi'
	icon_state = "coiled"
	overlay_state = "coiled_flame"
	resistance_flags = LAVA_PROOF | FIRE_PROOF
	item_flags = NEEDS_PERMIT
	sharpness = SHARP_EDGED
	light_power = 0.5
	light_color = LIGHT_COLOR_FIRE
	var/flame_power = 1

/obj/item/melee/smith/coiled_sword/Initialize(mapload)
	. = ..()
	set_light(2)

/obj/item/melee/smith/coiled_sword/examine(mob/user)
	. = ..()
	. += "Вонзи этот томно тлеющий витой меч в горстку вулканического пепла, чтобы пробудить его [span_engradio("<i>особенность</i>")]."

/obj/item/melee/smith/coiled_sword/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	. = ..()
	if(proximity_flag)
		if(istype(target, /obj/item/stack/ore/glass/basalt))
			if(!isturf(target.loc))
				to_chat(user, span_danger("Пепел должен быть на полу."))
				return
			var/obj/item/stack/ore/glass/basalt/B = target
			var/bonfire_place = get_turf(target)
			if(B.use(10))
				if(user.temporarilyRemoveItemFromInventory(src))
					visible_message("<i>[user] вонзает витой меч в вулканический пепел.</i>")
					step_to(B, user) // to prevent melting extra ash
					new /obj/structure/bonfire/prelit/ash(bonfire_place, src)
					playsound(bonfire_place, 'modular_bluemoon/sound/effects/bonfire_lit.ogg', 100, FALSE)
				else
					to_chat(user, span_danger("По какой-то причине ты не смог воткнуть меч."))
			else
				to_chat(user, span_danger("Слишком мало пепла."))
		else if(iscarbon(target)) // sadly, simple animals don't burn
			var/mob/living/carbon/C = target
			C.adjust_fire_stacks(flame_power)
			C.IgniteMob()
