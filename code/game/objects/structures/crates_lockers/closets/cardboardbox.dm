#define SNAKE_SPAM_TICKS 600 //how long between cardboard box openings that trigger the '!'
/obj/structure/closet/cardboard
	name = "large cardboard box"
	desc = "Просто коробка..."
	icon = 'modular_bluemoon/icons/obj/cardboardbox.dmi'
	icon_state = "cardboard"
	has_door_icon = FALSE
	mob_storage_capacity = 1
	resistance_flags = FLAMMABLE
	max_integrity = 70
	integrity_failure = 0
	can_weld_shut = 0
	cutting_tool = TOOL_WIRECUTTER
	open_sound = "rustle"
	material_drop = /obj/item/stack/sheet/cardboard
	delivery_icon = "deliverybox"
	anchorable = FALSE
	door_anim_time = 0 // no animation
	open_sound = 'sound/items/handling/cardboardbox_drop.ogg'
	close_sound = 'sound/items/handling/cardboardbox_drop.ogg'
	var/move_speed_multiplier = 1
	var/move_delay = FALSE
	var/egged = 0
	var/use_mob_movespeed = FALSE //Citadel adds snowflake box handling
	can_buckle = FALSE
	buckle_lying = FALSE
	max_buckled_mobs = 1
	buckle_prevents_pull = FALSE
	var/mutable_appearance/front
	var/can_sit_inside = TRUE	//в агентской коробке нельзя сидеть внутри и выглядывать из неё

/obj/structure/closet/cardboard/Initialize(mapload)
	. = ..()
	/*if(opened)
		can_buckle = TRUE
	else
		can_buckle = FALSE*/
	if(can_sit_inside)
		front = GetFront()
		front.layer = ABOVE_MOB_LAYER
		var/datum/component/riding/D = LoadComponent(/datum/component/riding)	//теперь коробка это ТС и требует регистрации в ГИБДД
		D.set_vehicle_dir_layer(SOUTH, OBJ_LAYER)
		D.set_vehicle_dir_layer(NORTH, OBJ_LAYER)
		D.set_vehicle_dir_layer(EAST, OBJ_LAYER)
		D.set_vehicle_dir_layer(WEST, OBJ_LAYER)
		D.vehicle_move_delay = 4

/obj/structure/closet/cardboard/examine(mob/user)
	. = ..()
	if(opened && can_sit_inside)
		if(!has_buckled_mobs())
			. += span_notice("Перетащите себя на коробку, чтобы залезть.")
		else
			. += span_notice("Внутри находится <b>[buckled_mobs[1]]</b>.")
			. += span_notice("Alt-click, чтобы излечь существо наружу.")

/obj/structure/closet/cardboard/proc/GetFront()
	return mutable_appearance(icon, "cardboard_front")

/obj/structure/closet/cardboard/proc/update_front()
	if(has_buckled_mobs())
		add_overlay(front)
	else
		cut_overlay(front)

/obj/structure/closet/cardboard/post_buckle_mob(mob/living/M)
	. = ..()
	update_front()
	sitting_inside(M)
	//add_overlay(front)


/obj/structure/closet/cardboard/proc/sitting_inside(mob/living/M)
	for(M in buckled_mobs)
		if(iscatperson(M))
			to_chat(M, span_notice("На удивление, здесь довольно уютно..."))
		while(iscatperson(M) && M.buckled && opened)
			SEND_SIGNAL(M, COMSIG_ADD_MOOD_EVENT, "hide_in_box", /datum/mood_event/hide_in_box)
			if(prob(50))
				to_chat(M, span_notice(pick("Меня не достанут, если я тут спрячусь.","Наверное, я выгляжу глупо, но мне всё равно.","Вот бы меня кто-нибудь погладил...")))
			sleep(30 SECONDS)

/obj/structure/closet/cardboard/post_unbuckle_mob(mob/living/M)
	. = ..()
	update_front()
	//cut_overlay(front)

/obj/structure/closet/cardboard/relaymove(mob/living/user, direction)
	if(can_sit_inside)
		if(move_delay || !CHECK_MOBILITY(user, MOBILITY_MOVE) || !isturf(loc) || !has_gravity(loc))
			return
		if(opened && !has_buckled_mobs())
			return
		var/datum/component/riding/riding_datum = GetComponent(/datum/component/riding)
		riding_datum.handle_ride(user, direction)
	else
		if(opened || move_delay || !CHECK_MOBILITY(user, MOBILITY_MOVE) || !isturf(loc) || !has_gravity(loc))
			return
		move_delay = TRUE
		var/oldloc = loc
		step(src, direction)
		user.setDir(direction)
		if(oldloc != loc)
			addtimer(CALLBACK(src, PROC_REF(ResetMoveDelay)), (use_mob_movespeed ? user.movement_delay() : CONFIG_GET(number/movedelay/walk_delay)) * move_speed_multiplier)
		else
			ResetMoveDelay()

/obj/structure/closet/cardboard/proc/ResetMoveDelay()
	move_delay = FALSE

/obj/structure/closet/cardboard/process()
	for(var/mob/living/carbon/H in contents)
		if(iscatperson(H))
			//to_chat(H, span_notice("You feel quite safe inside your box.</span>")
			SEND_SIGNAL(H, COMSIG_ADD_MOOD_EVENT, "hide_in_box", /datum/mood_event/hide_in_box)
			if(prob(10))
				H.emote("purr")
			if(prob(10))
				to_chat(H, span_notice(pick("Ах-х-~ Как уютно~", "Я бы мог[H.gender == FEMALE? "ла" : ""] уснуть тут, если бы хотел[H.ru_a()]...","Моё маленькое убежище от жестокого мира.","Я чувствую себя в безопасности.")))
			//sleep(8 SECONDS)

/obj/structure/closet/cardboard/open()
	if(opened || !can_open())
		return FALSE
	var/list/alerted = null
	if(egged < world.time)
		var/mob/living/Snake = null
		for(var/mob/living/L in src.contents)
			Snake = L
			break
		if(Snake)
			alerted = fov_viewers(world.view,src)
	STOP_PROCESSING(SSobj,src)
	if(can_sit_inside)
		can_buckle = TRUE
		for(var/mob/living/L in src.contents)
			buckle_mob(L)
	..()
	if(LAZYLEN(alerted))
		egged = world.time + SNAKE_SPAM_TICKS
		for(var/mob/living/L in alerted)
			if(!L.stat)
				if(!L.incapacitated(ignore_restraints = 1))
					L.face_atom(src)
				L.do_alert_animation(L)
		var/mob/living/carbon/C = buckled_mobs[1]
		if(iscatperson(C))
			C.emote(pick("nya","meow"))
		else
			playsound(loc, 'sound/machines/chime.ogg', 25, FALSE, -5)

/mob/living/proc/do_alert_animation(atom/A)
	var/image/I = image('icons/obj/closet.dmi', A, "cardboard_special", A.layer+1)
	flick_overlay_view(I, A, 8)
	I.alpha = 0
	animate(I, pixel_z = 32, alpha = 255, time = 5, easing = ELASTIC_EASING)

/obj/structure/closet/cardboard/close(mob/living/user)
	if(has_buckled_mobs())
		var/mob/living/L = buckled_mobs[1]
		unbuckle_mob(L)
	can_buckle = FALSE
	START_PROCESSING(SSobj,src)
	..()

/obj/structure/closet/cardboard/handle_lock_addition() //Whoever heard of a lockable cardboard box anyway
	return

/obj/structure/closet/cardboard/handle_lock_removal()
	return

/obj/structure/closet/cardboard/AltClick(mob/user)
	if(has_buckled_mobs())
		user_unbuckle_mob(buckled_mobs[1],user)
		return TRUE


/obj/structure/closet/cardboard/after_close(mob/living/toucher) //damn felinids in my box again!
	. = ..()
	for(var/mob/living/carbon/H in contents)
		if(iscatperson(H))
			to_chat(H, span_notice("Вы чувствуете себя в безопасности внутри своей коробки."))

/obj/structure/closet/cardboard/set_spooky_trap()	//boxes are for felinids, not for skeletonts
	return

/obj/structure/closet/cardboard/metal
	name = "large metal box"
	desc = "THE COWARDS! THE FOOLS!"
	icon_state = "metalbox"
	max_integrity = 500
	mob_storage_capacity = 5
	resistance_flags = NONE
	move_speed_multiplier = 2
	cutting_tool = TOOL_WELDER
	open_sound = 'sound/machines/click.ogg'
	close_sound = 'sound/machines/closet_close.ogg'
	material_drop = /obj/item/stack/sheet/plasteel

/obj/structure/closet/cardboard/metal/GetFront()
	return mutable_appearance(icon, "metalbox_front")

#undef SNAKE_SPAM_TICKS
