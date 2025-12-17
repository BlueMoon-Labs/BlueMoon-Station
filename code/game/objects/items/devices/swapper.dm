//ported from TG, credit to XDTM
/obj/item/swapper
	name = "quantum spin inverter"
	desc = "Экспериментальное устройство для смены локации двух сущностей путём подмены значения спина их частиц. Должно быть соединено с другим таким же устройством."
	icon = 'icons/obj/device.dmi'
	icon_state = "swapper"
	item_state = "electronic"
	w_class = WEIGHT_CLASS_SMALL
	item_flags = NOBLUDGEON
	lefthand_file = 'icons/mob/inhands/misc/devices_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/devices_righthand.dmi'

	var/cooldown = 300
	var/next_use = 0
	var/obj/item/swapper/linked_swapper

	var/emped = 0
	verb_say = "states" //BLUEMOON ADD

/obj/item/swapper/Destroy()
	if(linked_swapper)
		linked_swapper.linked_swapper = null //*inception music*
		linked_swapper.update_appearance()
		linked_swapper = null
	return ..()

/obj/item/swapper/update_icon_state()
	icon_state = "swapper[linked_swapper ? "-linked" : null]"
	return ..()

/obj/item/swapper/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/swapper))
		var/obj/item/swapper/other_swapper = I
		if(other_swapper.linked_swapper)
			to_chat(user, span_warning("[other_swapper] уже квантово связан. Разорвите текущую связь, чтобы создать новую."))
			return
		if(linked_swapper)
			to_chat(user, span_warning("[src] уже квантово связан. Разорвите текущую связь, чтобы создать новую."))
			return
		to_chat(user, span_notice("Вы установили квантовую связь между двумя устройствами."))
		linked_swapper = other_swapper
		other_swapper.linked_swapper = src
		update_appearance()
		linked_swapper.update_appearance()
	else
		return ..()

/obj/item/swapper/attack_self(mob/living/user)
	if(emped)
		var/datum/effect_system/spark_spread/sparks = new /datum/effect_system/spark_spread
		sparks.set_up(2, 0, get_turf(src))
		sparks.start()
		if(prob(10)) // Чтобы не спамили
			do_teleport(user, get_turf(user), 3, channel = TELEPORT_CHANNEL_QUANTUM)
			user.electrocute_act(5, src, flags = SHOCK_ILLUSION)
			to_chat(user, span_warning("[src] начало искриться и ударило вас током, вырываясь из рук!"))
			forceMove(drop_location())
		to_chat(user, span_warning("[src] не работает должным образом."))
		return
	if(world.time < next_use)
		to_chat(user, span_warning("[src] все ещё перезаряжается."))
		return
	if(QDELETED(linked_swapper))
		to_chat(user, span_warning("[src] не связан с другим устройством."))
		return
	playsound(src, 'sound/weapons/flash.ogg', 25, TRUE)
	to_chat(user, span_notice("Вы активировали [src]."))
	playsound(linked_swapper, 'sound/weapons/flash.ogg', 25, TRUE)
	if(ismob(linked_swapper.loc))
		var/mob/holder = linked_swapper.loc
		to_chat(holder, span_notice("[linked_swapper] жужжит."))
	next_use = world.time + cooldown //only the one used goes on cooldown
	addtimer(CALLBACK(src, PROC_REF(swap), user), 25)

/obj/item/swapper/examine(mob/user)
	. = ..()
	if(world.time < next_use)
		. += span_warning("Время до перезарядки: [DisplayTimeText(next_use - world.time)].")
	if(linked_swapper)
		. += span_notice("<b>Связано.</b> Alt-Click по устройству для разрыва текущей квантовой связи.")
	else
		. += span_notice("<b>Не связано.</b> Используйте на другом инвертере для установки квантвовой связи.")
	if(emped)
		. += span_red("<b>Выглядит странно.</b>")

/obj/item/swapper/AltClick(mob/living/user)
	if(!user.canUseTopic(src, BE_CLOSE, NO_DEXTERY,, FALSE, !iscyborg(user))) //someone mispelled dexterity
		return
	//BLUEMOON ADD ха-ха отвязка только после того, как инвертер перезарядится
	if(!linked_swapper)
		return
	if(world.time < next_use || world.time < linked_swapper.next_use)
		say("Разрыв квантовой связи невозможен. Одно из устройств перезаряжается.")
		return
	//BLUEMOON ADD END
	to_chat(user, span_notice("Вы разорвали квантовую связь."))
	if(!QDELETED(linked_swapper))
		linked_swapper.linked_swapper = null
		linked_swapper.update_appearance()
		linked_swapper = null
	update_appearance()

/obj/item/swapper/emp_act(severity)
	. = ..()
	if (!(. & EMP_PROTECT_SELF) && linked_swapper)
		if(prob(90))
			emped = clamp(emped + 1, 0, 1) // Значение никогда не будет выше 1, ниже 0
			flick_overlay_view(image('modular_bluemoon/icons/obj/device.dmi', src, icon_state = "swapper_emped"), src, (2*severity))
			spawn(2 * severity)
				emped -= 1
		else if(prob(15))
			swap()
			sleep(8)
			swap()
		else if(prob(10))
			linked_swapper.linked_swapper = null
			linked_swapper.update_appearance()
			linked_swapper = null
			emped = 0

//Gets the topmost teleportable container
/obj/item/swapper/proc/get_teleportable_container()
	var/atom/movable/teleportable = src
	while(ismovable(teleportable.loc))
		var/atom/movable/AM = teleportable.loc
		if(AM.anchored)
			break
		if(isliving(AM))
			var/mob/living/L = AM
			if(L.buckled)
				if(L.buckled.anchored)
					break
				else
					var/obj/buckled_obj = L.buckled
					buckled_obj.unbuckle_mob(L)
		teleportable = AM
	return teleportable

/obj/item/swapper/proc/swap(mob/user)
	if(QDELETED(linked_swapper) || world.time < linked_swapper.cooldown)
		return

	var/atom/movable/A = get_teleportable_container()
	var/atom/movable/B = linked_swapper.get_teleportable_container()
	var/target_A = A.drop_location()
	var/target_B = B.drop_location()

	//TODO: add a sound effect or visual effect
	if(do_teleport(A, target_B, channel = TELEPORT_CHANNEL_QUANTUM))
		do_teleport(B, target_A, channel = TELEPORT_CHANNEL_QUANTUM)
		if(ismob(B))
			var/mob/M = B
			to_chat(M, span_warning("[linked_swapper] активируется и вы обнаруживаете себя в другом месте."))
